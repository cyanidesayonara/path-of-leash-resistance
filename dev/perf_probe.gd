extends Node

# --perf[=SECONDS]: play the walk with the autowalk bot for SECONDS of real
# time (default 60), recording every frame, then print a PERF summary and quit.
# See tools/perf_sweep.sh.
#
# What it records per frame: real frame time (wall clock between frames, the
# number a player feels), the engine's own process and physics script time,
# the world draw (main._draw_world, via --drawcost's timer), node count and
# draw calls. Each frame also notes what else happened in it - an edge/verge
# layer redraw, slow motion, how many riders and walkers were out - so a spike
# can be matched to its cause instead of guessed at.
#
# Timings are only meaningful on real hardware with vsync off. Software GL in
# CI is fine for comparing two builds, not for absolute numbers.

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


func setup(m: Node2D, seconds: float) -> void:
	main = m
	secs = seconds


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# run after main every frame, so the draw timer has already been read
	process_priority = 1000
	main._draw_cost_on = true


func _process(_delta: float) -> void:
	_frames += 1
	var now := Time.get_ticks_usec()
	if _frames == 2:
		main._skip_title()
		_t_start = now
		_t_last = now
		_edge_y = float(main._edge_drawn_y)
		return
	if _frames < 2:
		return
	var row := {
		"t": float(now - _t_start) / 1.0e6,
		"frame_ms": float(now - _t_last) / 1000.0,
		"proc_ms": Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
		"phys_ms": Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
		"draw_ms": float(main.last_draw_us) / 1000.0,
		"nodes": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		"calls": int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		"edge_redraw": float(main._edge_drawn_y) != _edge_y,
		"slowmo": Engine.time_scale < 1.0,
		"riders": get_tree().get_node_count_in_group("bikes"),
		"walkers": get_tree().get_node_count_in_group("pairs") + get_tree().get_node_count_in_group("freedogs"),
	}
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
	print("PERF level=%s size=%dx%d secs=%.1f frames=%d fps=%.1f frame_p50=%.2f p95=%.2f p99=%.2f max=%.2f over16=%.1f%% over33=%d proc_p50=%.2f proc_p95=%.2f phys_p50=%.2f phys_p95=%.2f draw_p50=%.2f draw_p95=%.2f draw_max=%.2f nodes_max=%d calls_p50=%d calls_max=%d warmup_max=%.2f" % [
		main.lvl, int(vs.x), int(vs.y), total_s, ft.size(), (ft.size() / total_s) if total_s > 0.0 else 0.0,
		_pct(ft, 0.5), _pct(ft, 0.95), _pct(ft, 0.99), _pct(ft, 1.0),
		100.0 * over16 / maxf(1.0, ft.size()), over33,
		_pct(_col(_rows, "proc_ms"), 0.5), _pct(_col(_rows, "proc_ms"), 0.95),
		_pct(_col(_rows, "phys_ms"), 0.5), _pct(_col(_rows, "phys_ms"), 0.95),
		_pct(draws, 0.5), _pct(draws, 0.95), _pct(draws, 1.0),
		int(_pct(_col(_rows, "nodes"), 1.0)),
		int(_pct(_col(_rows, "calls"), 0.5)), int(_pct(_col(_rows, "calls"), 1.0)),
		_pct(_col(_warm, "frame_ms"), 1.0)])
	var worst := _rows.duplicate()
	worst.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.frame_ms) > float(b.frame_ms))
	for i in range(mini(TOP_SPIKES, worst.size())):
		var r: Dictionary = worst[i]
		print("PERF spike t=%.2f frame=%.2fms proc=%.2f phys=%.2f draw=%.2f nodes=%d calls=%d edge_redraw=%s slowmo=%s riders=%d walkers=%d" % [
			r.t, r.frame_ms, r.proc_ms, r.phys_ms, r.draw_ms, r.nodes, r.calls,
			r.edge_redraw, r.slowmo, r.riders, r.walkers])
