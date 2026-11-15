extends SceneTree

# Films a run of El Barri's agility course frame by frame: the dog is moved
# along the chalk racing line at a trot (sitting the count on the table), the
# camera on her, so the course's guidance and feedback can be judged in motion:
#   godot --path . --rendering-method gl_compatibility --script res://tools/agility_frames.gd -- OUTDIR [every_n_frames] [speed]
# Join with tools/frames_to_gif.py.

const CROP := Vector2i(640, 300)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var out_dir: String = args[0] if args.size() > 0 else "user://agility_frames"
	var every := int(args[1]) if args.size() > 1 else 4
	var speed := float(args[2]) if args.size() > 2 else 260.0
	DirAccess.make_dir_recursive_absolute(out_dir)
	Engine.physics_ticks_per_second = 60
	Engine.max_fps = 60
	var game: Node = root.get_node("Game")
	game.persist = false
	root.get_node("Sfx").muted = true
	game.level_id = "barri"
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
	var ag: AgilityCourse = m.agility
	if m.tug_dog != null:
		m.tug_dog.global_position = Vector2(140.0, m.freedom_lo + 40.0)
	var x := ag.x0 - 80.0
	m.dog.global_position = Vector2(x, ag.ly)
	m.agility_prev = m.dog.global_position
	var n := 0
	var f := 0
	var sit := 0.0
	var table_x := INF
	for p: Dictionary in ag.parts:
		if int(p["kind"]) == AgilityCourse.E.TABLE:
			table_x = float(p["x"])
	while x < ag.x1 + 60.0 and f < 60 * 30:
		if sit > 0.0:
			sit -= 1.0 / 60.0
			m.dog.planted = true
		else:
			m.dog.planted = false
			var nx := x + speed / 60.0
			if x < table_x and nx >= table_x:
				nx = table_x
				sit = AgilityCourse.TABLE_S + 0.15
			x = nx
		var pos := Vector2(x, ag.line_y(x))
		m.dog.facing = (pos - m.dog.global_position).normalized() if pos.distance_to(m.dog.global_position) > 0.1 else m.dog.facing
		m.dog.global_position = pos
		m.freedom_games_tick(1.0 / 60.0)
		m.cam.global_position = Vector2((ag.x0 + ag.x1) * 0.5, ag.ly)
		await RenderingServer.frame_post_draw
		if f % every == 0:
			var img := root.get_viewport().get_texture().get_image()
			var at: Vector2 = root.get_viewport().get_canvas_transform() * Vector2((ag.x0 + ag.x1) * 0.5, ag.ly)
			var crop := Rect2i(int(at.x) - CROP.x / 2, int(at.y) - CROP.y / 2, CROP.x, CROP.y)
			crop = crop.intersection(Rect2i(Vector2i.ZERO, img.get_size()))
			if crop.size.x > 0 and crop.size.y > 0:
				img.get_region(crop).save_png("%s/f%04d.png" % [out_dir, n])
				n += 1
		f += 1
	m.dog.planted = false
	print("agility_frames: %d frames, runs %d, best %.1f -> %s" % [n, m.agility_runs, float(game.agility_best), out_dir])
	quit(0)
