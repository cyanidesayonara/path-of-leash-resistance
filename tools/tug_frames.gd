extends SceneTree

# Photographs a tug-of-war frame by frame, played with real input, so the
# rope toy, the other dog's rhythm and the meter can be judged in motion:
#   godot --path . --rendering-method gl_compatibility --script res://tools/tug_frames.gd -- OUTDIR [level] [every_n_frames] [style]
# style: "timed" (dig in through the heave, pull in the rest; the default),
# "away" (pull the whole time) or "stand". Each frame is a crop round the
# pair. Join with tools/frames_to_gif.py.

const CROP := Vector2i(420, 300)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var out_dir: String = args[0] if args.size() > 0 else "user://tug_frames"
	var lv: String = args[1] if args.size() > 1 else "park"
	var every := int(args[2]) if args.size() > 2 else 4
	var style: String = args[3] if args.size() > 3 else "timed"
	DirAccess.make_dir_recursive_absolute(out_dir)
	Engine.physics_ticks_per_second = 60
	Engine.max_fps = 60
	var game: Node = root.get_node("Game")
	game.persist = false
	root.get_node("Sfx").muted = true
	game.level_id = lv
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	for k in range(3):
		await physics_frame
	m._skip_title()
	m.dog.global_position = Vector2(640.0, m.GATE_Y - 300.0)
	m.human.global_position = Vector2(640.0, m.GATE_Y - 60.0)
	m.leash.resnap()
	m._enter_freedom()
	await physics_frame
	var fd: Node2D = m.tug_dog
	if fd == null:
		print("tug_frames: no rope dog on %s" % lv)
		quit(1)
		return
	for toy in [m.ball, m.npc_ball]:
		if is_instance_valid(toy):
			toy.global_position = Vector2(-5000.0, -5000.0)
	fd.global_position = Vector2(560.0, m.GATE_Y - 250.0)
	fd.face = Vector2.RIGHT
	m.dog.facing = Vector2.LEFT
	m.dog.global_position = fd.rope_end() - m.dog.facing * 22.0
	m.freedom_games_tick(1.0 / 60.0)
	if m.tug == null:
		print("tug_frames: the tug did not start")
		quit(1)
		return
	var n := 0
	var f := 0
	var result := ""
	while f < 60 * 18:
		var tug: RopeTug = m.tug
		var dig := style == "timed" and tug != null and tug.phase != RopeTug.P.REST
		var pull := style == "away" or (style == "timed" and not dig)
		if pull:
			Input.action_press("move_right")
		else:
			Input.action_release("move_right")
		if dig:
			Input.action_press("plant")
		else:
			Input.action_release("plant")
		m.cam.global_position = (m.dog.global_position + fd.global_position) * 0.5
		await RenderingServer.frame_post_draw
		if f % every == 0:
			var img := root.get_viewport().get_texture().get_image()
			var mid: Vector2 = (m.dog.global_position + fd.global_position) * 0.5
			var at: Vector2 = root.get_viewport().get_canvas_transform() * mid
			var crop := Rect2i(int(at.x) - CROP.x / 2, int(at.y) - CROP.y / 2, CROP.x, CROP.y)
			crop = crop.intersection(Rect2i(Vector2i.ZERO, img.get_size()))
			img.get_region(crop).save_png("%s/f%04d.png" % [out_dir, n])
			n += 1
		f += 1
		if m.tug == null:
			result = "over"
			# a few frames of the aftermath
			if f > 0 and n > 0 and m.rope_carry_t < 2.6:
				break
	Input.action_release("move_right")
	Input.action_release("plant")
	print("tug_frames: %s %s, %d frames, %s, tugs won %d -> %s" % [lv, style, n, result, m.tugs_won, out_dir])
	quit(0)
