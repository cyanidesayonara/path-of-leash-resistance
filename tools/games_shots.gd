extends SceneTree

# Photographs the off-leash games at their moments, without playing: Millie
# over a jump, inside the tunnel's run-in, a tug in progress, a frisbee in
# the air. Needs a renderer:
#   godot --rendering-method gl_compatibility --path . --script res://tools/games_shots.gd -- OUTDIR [level]

var out_dir := "user://"


func _initialize() -> void:
	call_deferred("_run")


func _shot(m: Node2D, name: String, cam: Vector2) -> void:
	m.cam.global_position = cam
	for i in range(3):
		await process_frame
	var img := root.get_viewport().get_texture().get_image()
	img.save_png("%s/games-%s.png" % [out_dir, name])
	print("games_shots: ", name)


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	var lvl: String = args[1] if args.size() > 1 else "park"
	var game = root.get_node("Game")
	game.persist = false
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
	m.frozen = true
	var ag: AgilityCourse = m.agility
	# over the first jump
	var jx: float = ag.parts[0]["x"]
	m.dog.global_position = Vector2(jx, ag.ly)
	m.dog.facing = Vector2.RIGHT
	m.dog.hop = 15.0
	await _shot(m, "%s-jump" % lvl, Vector2(jx + 150.0, ag.ly + 60.0))
	m.dog.hop = 0.0
	# weaving
	var wx: float = ag.parts[2]["x"]
	m.dog.global_position = Vector2(wx, ag.ly + 16.0)
	await _shot(m, "%s-weave" % lvl, Vector2(wx + 100.0, ag.ly + 60.0))
	# a tug
	var fd: Node2D = m.tug_dog
	if fd != null:
		fd.global_position = Vector2(560.0, m.GATE_Y - 260.0)
		fd.face = Vector2.RIGHT
		fd.state = fd.S.TUG
		fd.lean = 1.0
		m.dog.global_position = Vector2(606.0 + 22.0, m.GATE_Y - 258.0)
		m.dog.facing = Vector2.LEFT
		m.tug = RopeTug.new(m.dog.global_position, fd.global_position)
		m._update_hud()
		await _shot(m, "%s-tug" % lvl, Vector2(600.0, m.GATE_Y - 260.0))
		m.tug = null
		fd.state = fd.S.OFFER
		await _shot(m, "%s-offer" % lvl, Vector2(600.0, m.GATE_Y - 260.0))
	# the frisbee, high
	m.frozen = false
	m.romp_done = true
	if is_instance_valid(m.ball):
		m.ball.queue_free()
	m.freedom_games_tick(1.0 / 60.0)
	m.frozen = true
	if is_instance_valid(m.frisbee):
		var f: Node2D = m.frisbee
		f.state = f.State.FLYING
		f.global_position = Vector2(700.0, m.GATE_Y - 330.0)
		f.h = 40.0
		f.queue_redraw()
		m.dog.global_position = Vector2(660.0, m.GATE_Y - 300.0)
		m.dog.facing = Vector2(0.8, -0.6).normalized()
		await _shot(m, "%s-frisbee" % lvl, Vector2(680.0, m.GATE_Y - 300.0))
	quit(0)
