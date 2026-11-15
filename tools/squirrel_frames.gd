extends SceneTree

# Films the woodland clearing's squirrel game frame by frame: the dog runs at
# the squirrel, it bolts up a tree, she barks under it, it rustles and leaps,
# she follows and barks again; the camera on the action, so the game's
# telegraphs and feedback can be judged in motion:
#   godot --path . --rendering-method gl_compatibility --script res://tools/squirrel_frames.gd -- OUTDIR [every_n_frames] [level]
# Join with tools/frames_to_gif.py.

const CROP := Vector2i(720, 405)
const DT := 1.0 / 60.0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var out_dir: String = args[0] if args.size() > 0 else "user://squirrel_frames"
	var every := int(args[1]) if args.size() > 1 else 4
	var lvl: String = args[2] if args.size() > 2 else "trail"
	DirAccess.make_dir_recursive_absolute(out_dir)
	Engine.physics_ticks_per_second = 60
	Engine.max_fps = 60
	var game: Node = root.get_node("Game")
	game.persist = false
	root.get_node("Sfx").muted = true
	game.level_id = lvl
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
	var sg = m.squirrel_game
	if sg == null:
		print("squirrel_frames: %s has no squirrel game" % lvl)
		quit(1)
		return
	var S = sg.S
	m.dog.global_position = Vector2(640.0, m.GATE_Y - 120.0)
	m.cam.position_smoothing_enabled = false
	var n := 0
	var f := 0
	var barked_at := Vector2(INF, INF)
	var bark_cd := 0.0
	var leaps_seen := 0
	while f < 60 * 22 and not (leaps_seen >= 2 and int(sg.state) == S.GONE):
		var target: Vector2 = m.dog.global_position
		match int(sg.state):
			S.FORAGE, S.BOLT, S.CLIMB:
				target = sg.pos
			S.TREED, S.RUSTLE:
				target = sg.tree + (m.dog.global_position - sg.tree).normalized() * 50.0
			S.LEAP:
				target = sg.tree
		var d: Vector2 = target - m.dog.global_position
		var spd := 320.0 if int(sg.state) == S.BOLT or int(sg.state) == S.LEAP else 220.0
		if d.length() > 2.0:
			m.dog.facing = d.normalized()
			m.dog.global_position += d.normalized() * minf(d.length(), spd * DT)
		# bark under the tree, a beat apart
		bark_cd -= DT
		if sg.up_a_tree() and m.dog.global_position.distance_to(sg.tree) < sg.TRUNK_R and bark_cd <= 0.0:
			m.on_bark(m.dog.global_position)
			bark_cd = 0.9
		if int(sg.state) == S.LEAP and barked_at != sg.tree:
			barked_at = sg.tree
			leaps_seen += 1
		var focus: Vector2 = sg.pos if sg.pos.x < INF else m.dog.global_position
		m.shot_cam = m.dog.global_position.lerp(focus, 0.45)
		m.cam.position = m.shot_cam
		await RenderingServer.frame_post_draw
		if f % every == 0:
			var img := root.get_viewport().get_texture().get_image()
			var c := img.get_size() / 2
			var crop := Rect2i(c.x - CROP.x / 2, c.y - CROP.y / 2, CROP.x, CROP.y).intersection(Rect2i(Vector2i.ZERO, img.get_size()))
			img.get_region(crop).save_png("%s/f%04d.png" % [out_dir, n])
			n += 1
		f += 1
	print("squirrel_frames: %d frames, treed %d, round %d -> %s" % [n, sg.treed_total, sg.round, out_dir])
	quit(0)
