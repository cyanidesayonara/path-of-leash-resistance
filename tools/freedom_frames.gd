extends SceneTree

# Films a walk's off-leash space with its games running, the dog parked where
# you put her, so a game's look (the pigeons landing, the waves) can be judged
# in motion without playing:
#   godot --path . --rendering-method gl_compatibility --script res://tools/freedom_frames.gd -- OUTDIR LEVEL X,Y SECONDS [every_n_frames]
# The camera is on the dog. Join with tools/frames_to_gif.py.

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var out_dir: String = args[0]
	var lv: String = args[1]
	var xy := String(args[2]).split(",")
	var secs := float(args[3])
	var every := int(args[4]) if args.size() > 4 else 6
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
	# X,Y counts from the gate: Y is up the space from it
	var at := Vector2(float(xy[0]), m.GATE_Y - float(xy[1]))
	var n := 0
	for f in range(int(secs * 60.0)):
		m.dog.global_position = at
		m.dog.velocity = Vector2.ZERO
		m.cam.global_position = at
		await RenderingServer.frame_post_draw
		if f % every == 0:
			root.get_viewport().get_texture().get_image().save_png("%s/f%04d.png" % [out_dir, n])
			n += 1
	print("freedom_frames: %s, %d frames -> %s" % [lv, n, out_dir])
	quit(0)
