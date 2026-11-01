extends Node

# --perf[=SECONDS]: play the walk with the autowalk bot for SECONDS of real
# time (default 60), recording every frame, then print a PERF summary and quit.
# See tools/perf_sweep.sh.
#
# What it records per frame: real frame time (wall clock between frames, the
# number a player feels - the one to compare builds by), the world draw
# (main._draw_world, via --drawcost's timer), node count and draw calls, and
# Godot's TIME_PROCESS / TIME_PHYSICS_PROCESS monitors. Those monitors are NOT
# per-frame cost here: headless they read 12.5ms and 6ms while whole frames
# took 2.8ms. They are printed as mon_proc/mon_phys for reference only.
# Each frame also notes what else happened in it - an edge/verge layer
# redraw, slow motion, how many riders and walkers were out - so a spike can
# be matched to its cause instead of guessed at.
#
# Also printed: main's physics step split by subsystem (wall-clock marks, see
# main._prof). Diagnostics, which change gameplay: --perf-disable=a.gd,b.gd
# switches off those scripts' physics, --perf-disable-process=... their
# process and per-frame redraw, so the difference shows what they cost.
# --perf-hide=... hides those scripts' nodes, so the drop in draw calls (a
# windowed run; headless draws nothing) shows what they cost to render.
# --perf-no-grade switches off the full-screen grade pass (GPU fill).
# --perf-scripts times where each frame goes: the physics steps, the process
# pass and the draw pass by wall clock, and each script's _draw from the gaps
# between the nodes' draw signals (Godot emits a node's draw signal just
# before calling its _draw, and redraws run back to back). It changes no
# gameplay; the signal hooks cost a little, so compare it only with itself.
#
# To compare CPU cost between builds, run headless with --fixed-fps 60 and
# read frame_p50. For real frame times (rendering included) run windowed with
# vsync off, the window in front and nothing else busy: Windows throttles a
# background game window to 30 fps. Software GL in CI only compares builds.

const WARMUP_SECS := 2.0       # first-use shader compiles land here; reported apart
const SPIKE_MS := 33.4         # a frame slower than 30 fps
const TOP_SPIKES := 8

var main: Node2D
var secs := 60.0
var _frames := 0
var _t_start := 0
var _t_last := 0
var _edge_y := 0.0
var _rows: Array[Dictionary] = []
var _warm: Array[Dictionary] = []
var _disable: PackedStringArray = []
var _disable_proc: PackedStringArray = []
var _hide: PackedStringArray = []
# main.prof_us as of the previous frame, so each frame's own split is known
var _prof_last := {}
# --perf-scripts: phase totals and each script's _draw, in usec over the run
var _scripts := false
var _phase_us := {"physics": 0, "process": 0, "draw": 0}
var _draw_us := {}
var _draw_n := {}
var _phys_t := 0
var _proc_t := 0
var _draw_t0 := 0
var _mark_t := 0
var _mark_key := ""


# starts the clock on a phase: runs before every other node in it
class PhaseMark extends Node:
	var probe: Node
	func _process(_d: float) -> void:
		probe._proc_t = Time.get_ticks_usec()
	func _physics_process(_d: float) -> void:
		probe._phys_t = Time.get_ticks_usec()


func setup(m: Node2D, seconds: float) -> void:
	main = m
	secs = seconds
	# --perf-disable=a.gd,b.gd switches off those scripts' physics, so the
	# drop in physics time shows what that kind of entity costs. Diagnostic
	# only: it changes gameplay, so never compare it with a normal run's
	# behaviour.
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--perf-disable="):
			_disable = arg.substr(15).split(",")
			print("PERF diagnostic: physics disabled for %s" % ", ".join(_disable))
		elif arg.begins_with("--perf-disable-process="):
			_disable_proc = arg.substr(23).split(",")
			print("PERF diagnostic: process (and its per-frame redraw) disabled for %s" % ", ".join(_disable_proc))
		elif arg == "--perf-no-grade":
			# the full-screen grade pass (hud/grade.gdshader) is GPU fill work
			# that the renderer's CPU timings never see; switching it off shows
			# what it costs in frame time
			if main.grade_rect != null:
				main.grade_rect.visible = false
			print("PERF diagnostic: grade pass off")
		elif arg == "--perf-scripts":
			_scripts = true
			print("PERF diagnostic: timing phases and each script's _draw")
		elif arg.begins_with("--perf-hide="):
			_hide = arg.substr(12).split(",")
			print("PERF diagnostic: hidden %s" % ", ".join(_hide))


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# run after main every frame, so the draw timer has already been read
	process_priority = 1000
	main._draw_cost_on = true
	main._prof_on = true
	# the renderer's own CPU time (building and submitting draw calls) and GPU
	# time per frame. Unlike frame time these do not stretch when Windows
	# throttles a background window, so draw-call work can be compared in any
	# windowed run. Both read 0 headless.
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
	if _scripts:
		var mark := PhaseMark.new()
		mark.probe = self
		mark.process_mode = Node.PROCESS_MODE_ALWAYS
		mark.process_priority = -1000
		mark.process_physics_priority = -1000
		add_child(mark)
		process_physics_priority = 1000
		set_physics_process(true)
		get_tree().node_added.connect(_watch_draw)
		_watch_tree(get_tree().root)
		RenderingServer.frame_pre_draw.connect(_end_draw)
	else:
		set_physics_process(false)


func _physics_process(_delta: float) -> void:
	if _phys_t > 0:
		_phase_us.physics += Time.get_ticks_usec() - _phys_t


func _watch_tree(n: Node) -> void:
	_watch_draw(n)
	for c in n.get_children():
		_watch_tree(c)


func _watch_draw(n: Node) -> void:
	var sc: Script = n.get_script()
	if n is CanvasItem and sc != null and n.has_method("_draw"):
		n.draw.connect(_on_draw.bind(sc.resource_path.get_file()))


func _on_draw(key: String) -> void:
	var now := Time.get_ticks_usec()
	if _mark_key != "":
		_draw_us[_mark_key] = int(_draw_us.get(_mark_key, 0)) + now - _mark_t
	else:
		_draw_t0 = now
	_draw_n[key] = int(_draw_n.get(key, 0)) + 1
	_mark_t = now
	_mark_key = key


# the last redraw ends where rendering starts
func _end_draw() -> void:
	if _mark_key == "":
		return
	var now := Time.get_ticks_usec()
	_draw_us[_mark_key] = int(_draw_us.get(_mark_key, 0)) + now - _mark_t
	_phase_us.draw += now - _draw_t0
	_mark_key = ""


func _process(_delta: float) -> void:
	_frames += 1
	var now := Time.get_ticks_usec()
	if _scripts and _proc_t > 0:
		_phase_us.process += now - _proc_t
	if _frames == 2:
		main._skip_title()
		_t_start = now
		_t_last = now
		_edge_y = float(main._edge_drawn_y)
		return
	if _frames < 2:
		return
	if (not _disable.is_empty() or not _disable_proc.is_empty() or not _hide.is_empty()) and _frames % 15 == 0:
		_apply_disable(main)
	var row := {
		"t": float(now - _t_start) / 1.0e6,
		"frame_ms": float(now - _t_last) / 1000.0,
		"proc_ms": Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
		"phys_ms": Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
		"draw_ms": float(main.last_draw_us) / 1000.0,
		"nodes": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		"calls": int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		"rcpu_ms": RenderingServer.viewport_get_measured_render_time_cpu(get_viewport().get_viewport_rid()),
		"rgpu_ms": RenderingServer.viewport_get_measured_render_time_gpu(get_viewport().get_viewport_rid()),
		"edge_redraw": float(main._edge_drawn_y) != _edge_y,
		"slowmo": Engine.time_scale < 1.0,
		"riders": get_tree().get_node_count_in_group("bikes"),
		"walkers": get_tree().get_node_count_in_group("pairs") + get_tree().get_node_count_in_group("freedogs"),
	}
	# this frame's physics-step split, kept as its three biggest parts so a
	# spike says which subsystem it was (a physics frame, or the gap between)
	var parts := []
	for k: String in main.prof_us.keys():
		var d := int(main.prof_us[k]) - int(_prof_last.get(k, 0))
		if d > 0:
			parts.append([d, k])
	_prof_last = main.prof_us.duplicate()
	parts.sort_custom(func(a: Array, b: Array) -> bool: return int(a[0]) > int(b[0]))
	var top := []
	for i in range(mini(3, parts.size())):
		top.append("%s=%.1f" % [parts[i][1], float(parts[i][0]) / 1000.0])
	row["phys_top"] = ",".join(top) if not top.is_empty() else "-"
	_t_last = now
	_edge_y = float(main._edge_drawn_y)
	# a zero means no world draw this frame (the world redraws at ~30fps)
	main.last_draw_us = 0
	if row.t < WARMUP_SECS:
		_warm.append(row)
	else:
		_rows.append(row)
	if row.t >= secs or main.finished:
		_report()
		get_tree().quit()
		set_process(false)


func _pct(values: Array, p: float) -> float:
	if values.is_empty():
		return 0.0
	var v := values.duplicate()
	v.sort()
	return float(v[clampi(int(round(p * (v.size() - 1))), 0, v.size() - 1)])


func _col(rows: Array[Dictionary], key: String, skip_zero := false) -> Array:
	var out := []
	for r in rows:
		var x: float = float(r[key])
		if skip_zero and x <= 0.0:
			continue
		out.append(x)
	return out


func _report() -> void:
	var vs := get_viewport().get_visible_rect().size
	var ft := _col(_rows, "frame_ms")
	var over16 := 0
	var over33 := 0
	for x in ft:
		over16 += 1 if float(x) > 16.7 else 0
		over33 += 1 if float(x) > SPIKE_MS else 0
	var total_s := 0.0
	for x in ft:
		total_s += float(x) / 1000.0
	var draws := _col(_rows, "draw_ms", true)
	print("PERF level=%s size=%dx%d secs=%.1f frames=%d fps=%.1f frame_p50=%.2f p95=%.2f p99=%.2f max=%.2f over16=%.1f%% over33=%d mon_proc_p50=%.2f mon_proc_p95=%.2f mon_phys_p50=%.2f mon_phys_p95=%.2f draw_p50=%.2f draw_p95=%.2f draw_max=%.2f nodes_max=%d calls_p50=%d calls_max=%d render_cpu_p50=%.2f render_cpu_p95=%.2f render_gpu_p50=%.2f render_gpu_p95=%.2f warmup_max=%.2f" % [
		main.lvl, int(vs.x), int(vs.y), total_s, ft.size(), (ft.size() / total_s) if total_s > 0.0 else 0.0,
		_pct(ft, 0.5), _pct(ft, 0.95), _pct(ft, 0.99), _pct(ft, 1.0),
		100.0 * over16 / maxf(1.0, ft.size()), over33,
		_pct(_col(_rows, "proc_ms"), 0.5), _pct(_col(_rows, "proc_ms"), 0.95),
		_pct(_col(_rows, "phys_ms"), 0.5), _pct(_col(_rows, "phys_ms"), 0.95),
		_pct(draws, 0.5), _pct(draws, 0.95), _pct(draws, 1.0),
		int(_pct(_col(_rows, "nodes"), 1.0)),
		int(_pct(_col(_rows, "calls"), 0.5)), int(_pct(_col(_rows, "calls"), 1.0)),
		_pct(_col(_rows, "rcpu_ms"), 0.5), _pct(_col(_rows, "rcpu_ms"), 0.95),
		_pct(_col(_rows, "rgpu_ms"), 0.5), _pct(_col(_rows, "rgpu_ms"), 0.95),
		_pct(_col(_warm, "frame_ms"), 1.0)])
	# where main's physics step goes, per subsystem, averaged over every frame
	var frames := maxf(1.0, float(_rows.size() + _warm.size()))
	var keys: Array = main.prof_us.keys()
	keys.sort_custom(func(a: String, b: String) -> bool: return int(main.prof_us[a]) > int(main.prof_us[b]))
	var total := 0.0
	for k: String in keys:
		total += float(main.prof_us[k])
	print("PERF physics-step total=%.2fms per frame (the engine's physics monitor also counts the entities' own physics)" % (total / frames / 1000.0))
	for k: String in keys:
		print("PERF physics-step %-20s %.3fms" % [k, float(main.prof_us[k]) / frames / 1000.0])
	if _scripts:
		_report_scripts(frames, total_s * 1000.0 / maxf(1.0, ft.size()))
	var worst := _rows.duplicate()
	worst.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.frame_ms) > float(b.frame_ms))
	for i in range(mini(TOP_SPIKES, worst.size())):
		var r: Dictionary = worst[i]
		print("PERF spike t=%.2f frame=%.2fms mon_proc=%.2f mon_phys=%.2f draw=%.2f nodes=%d calls=%d edge_redraw=%s slowmo=%s riders=%d walkers=%d physics_top=%s" % [
			r.t, r.frame_ms, r.proc_ms, r.phys_ms, r.draw_ms, r.nodes, r.calls,
			r.edge_redraw, r.slowmo, r.riders, r.walkers, r.phys_top])


func _report_scripts(frames: float, frame_ms: float) -> void:
	var ph := []
	for k: String in ["physics", "process", "draw"]:
		ph.append("%s=%.2f" % [k, float(_phase_us[k]) / frames / 1000.0])
	print("PERF phases per frame (ms): frame=%.2f %s (the rest is rendering, audio and the engine)" % [frame_ms, " ".join(ph)])
	var keys: Array = _draw_us.keys()
	keys.sort_custom(func(a: String, b: String) -> bool: return int(_draw_us[a]) > int(_draw_us[b]))
	for k: String in keys:
		print("PERF draw %-22s %.3fms per frame  %.1f redraws per frame  %.3fms each" % [k,
			float(_draw_us[k]) / frames / 1000.0, float(_draw_n[k]) / frames,
			float(_draw_us[k]) / maxf(1.0, float(_draw_n[k])) / 1000.0])


func _apply_disable(n: Node) -> void:
	for c in n.get_children():
		var sc: Script = c.get_script()
		if sc != null and sc.resource_path.get_file() in _disable:
			c.set_physics_process(false)
		if sc != null and sc.resource_path.get_file() in _disable_proc:
			c.set_process(false)
		if sc != null and sc.resource_path.get_file() in _hide and c is CanvasItem:
			c.visible = false
		_apply_disable(c)
