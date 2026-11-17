extends SceneTree

# A whirl as it is played, frame by frame: your human is stopped beside a real
# pole on an open walk, the dog runs round the pole (winding the leash on at
# his end) with real input, then pulls away holding the zoomies until he has
# whirled and been flung, or bailed. Prints what happened and when (arming,
# the commit, the turns, the release or the bail, the fling's speed) and,
# with --out, saves every --every'th frame for a sequence or a GIF
# (tools/frames_to_gif.py). Deterministic at a fixed frame rate.
#
#   godot --path . --rendering-method gl_compatibility --fixed-fps 60 \
#     --resolution 960x600 --script res://tools/whirl_capture.gd -- \
#     [--level=park] [--out=DIR] [--every=2] [--turns=1.6] [--zoom=2]

var m: Node2D
var out := ""
var every := 2
var frame := 0
var shots := 0


func _initialize() -> void:
	call_deferred("_run")


func _arg(name: String, def: String) -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--" + name + "="):
			return a.substr(name.length() + 3)
	return def


func _run() -> void:
	out = _arg("out", "")
	every = int(_arg("every", "2"))
	if out != "":
		DirAccess.make_dir_recursive_absolute(out)
	var game = root.get_node("Game")
	game.persist = false
	game.level_id = _arg("level", "park")
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	for k in range(3):
		await physics_frame
	m._skip_title()
	await physics_frame
	# a real pole in the open, near the start, with room all round it
	var pole := _open_pole(m.dog.global_position + Vector2(0.0, -500.0))
	if pole.x == INF:
		print("WHIRL no open pole")
		quit(1)
		return
	m.human.global_position = pole + Vector2(-44.0, 10.0)
	m.dog.global_position = pole + Vector2(-60.0, 50.0)
	m.leash.resnap()
	m.dog.energy = 1.0
	# the camera held on the pole (main's --shot-cam), zoomed in
	m.shot_cam = pole
	if m.cam != null:
		m.cam.zoom = Vector2.ONE * float(_arg("zoom", "2"))
	var turns := float(_arg("turns", "1.6"))
	print("WHIRL pole %s" % str(pole.round()))
	# wind: run round the pole, the leash catching it beside him
	var a0: float = (m.dog.global_position - pole).angle()
	var swept := 0.0
	var prev := a0
	var t := 0.0
	m.human.halt(6.0)
	while swept < turns * TAU and t < 6.0:
		var r: Vector2 = m.dog.global_position - pole
		var tan := r.orthogonal().normalized()
		var want := (tan + r.normalized() * clampf((70.0 - r.length()) / 40.0, -1.0, 1.0)).normalized()
		_press(want, false)
		await _frame()
		var a: float = (m.dog.global_position - pole).angle()
		swept += absf(wrapf(a - prev, -PI, PI))
		prev = a
		t += 1.0 / 60.0
	print("WHIRL wound %.2f turns in %.2fs, rope winding %.2f, his end %.2f" % [swept / TAU, t,
		float(m.leash.winding()) / TAU, float(m.leash.human_end_winding()) / TAU])
	# pull away, zoomies held, until it has played out
	var state := ""
	var t0 := t
	var whirl_t := -1.0
	var after := 0.0
	while t < 14.0:
		var away: Vector2 = (m.dog.global_position - pole).normalized()
		_press(away, true)
		await _frame()
		t += 1.0 / 60.0
		var s: String = _state()
		if s != state:
			print("WHIRL %.2fs %s (omega %.1f, r %.0f, unwound %.2f of %.2f turns)" % [t - t0, s,
				float(m.human.whirl_omega), float(m.human.whirl_r), float(m.human.whirl_unwound) / TAU,
				float(m.human.whirl_turns) / TAU])
			if s == "whirl":
				whirl_t = t
			if state == "whirl":
				print("WHIRL orbit lasted %.2fs, fling speed %.0f" % [t - whirl_t, m.human.velocity.length()])
			state = s
		if whirl_t >= 0.0 and s != "whirl":
			after += 1.0 / 60.0
			if after > 1.2:
				break
	_press(Vector2.ZERO, false)
	print("WHIRL done flings=%d frames=%d" % [int(m.flings_done), shots])
	quit(0)


func _state() -> String:
	if m.human.is_whirling():
		return "whirl"
	if float(m.whirl_arm) > 0.0:
		return "arming"
	if bool(m.human.whirl_bailed) or m.human.state == m.human.HState.STUMBLE:
		return "stumble"
	return "walk"


func _open_pole(near: Vector2) -> Vector2:
	var best := Vector2(INF, INF)
	var kinds: PackedInt32Array = m.leash.kinds()
	for i in range(m.leash.poles.size()):
		if kinds[i] != m.leash.K_POLE:
			continue
		var p: Vector2 = m.leash.poles[i]
		var clear := true
		for q: Vector2 in m.leash.poles:
			if q != p and q.distance_to(p) < 150.0:
				clear = false
				break
		for r: Rect2 in m.solid_rects:
			if r.grow(120.0).has_point(p):
				clear = false
				break
		if clear and (best.x == INF or p.distance_to(near) < best.distance_to(near)):
			best = p
	return best


func _frame() -> void:
	await physics_frame
	frame += 1
	if out != "" and frame % every == 0 and DisplayServer.get_name() != "headless":
		await process_frame
		root.get_viewport().get_texture().get_image().save_png("%s/f%04d.png" % [out, shots])
		shots += 1


func _press(v: Vector2, turbo: bool) -> void:
	_hold("move_right", maxf(v.x, 0.0))
	_hold("move_left", maxf(-v.x, 0.0))
	_hold("move_down", maxf(v.y, 0.0))
	_hold("move_up", maxf(-v.y, 0.0))
	if turbo:
		Input.action_press("turbo")
	else:
		Input.action_release("turbo")


func _hold(a: String, s: float) -> void:
	if s > 0.05:
		Input.action_press(a, s)
	else:
		Input.action_release(a)
