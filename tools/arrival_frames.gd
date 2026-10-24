extends SceneTree

# Photographs a walk's arrival (systems/arrival.gd) frame by frame, so the
# walk in through the door can be judged like a film rather than in one shot:
#   godot --path . --rendering-method gl_compatibility --script res://tools/arrival_frames.gd -- LEVEL OUTDIR [every_n_frames]
# The pair are put just past the arrival line (Arrival.line_y), both standing, and the arrival
# runs in real frames at a fixed 60 fps. Each frame is a full-resolution
# crop round the door. Join with tools/frames_to_gif.py.

const Arrival := preload("res://systems/arrival.gd")
const CROP := Vector2i(360, 300)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var lv: String = args[0] if args.size() > 0 else "barri"
	var out_dir: String = args[1] if args.size() > 1 else "user://arrival_frames"
	var every := int(args[2]) if args.size() > 2 else 4
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
	m._skip_title()
	for i in range(10):
		await physics_frame
	m.started = true
	m.phase = "home"
	m.frozen = false
	m.finished = false
	m.auto_walk = false
	var y := Arrival.line_y(m)
	m.dog.velocity = Vector2.ZERO
	m.human.velocity = Vector2.ZERO
	m.dog.global_position = Vector2(m.walk_cx + 20.0, y + 6.0)
	m.human.global_position = Vector2(m.walk_cx - 30.0, y + 4.0)
	m.leash.resnap()
	# let the camera settle on them before the line is judged
	for i in range(40):
		m.dog.global_position = Vector2(m.walk_cx + 20.0, y - 30.0)
		m.human.global_position = Vector2(m.walk_cx - 30.0, y - 40.0)
		await physics_frame
	m.dog.global_position = Vector2(m.walk_cx + 20.0, y + 6.0)
	m.human.global_position = Vector2(m.walk_cx - 30.0, y + 4.0)
	var n := 0
	var f := 0
	while true:
		await RenderingServer.frame_post_draw
		if f % every == 0:
			# a close crop round the door, at full resolution, so the steps read
			var img := root.get_viewport().get_texture().get_image()
			var at: Vector2 = root.get_viewport().get_canvas_transform() * Arrival.aperture(m).get_center()
			var crop := Rect2i(int(at.x) - CROP.x / 2, int(at.y) - CROP.y + 60, CROP.x, CROP.y)
			crop = crop.intersection(Rect2i(Vector2i.ZERO, img.get_size()))
			img = img.get_region(crop)
			img.save_png("%s/f%04d.png" % [out_dir, n])
			n += 1
		f += 1
		if m.finished or f > 60 * int(ceil(Arrival.DURATION + 1.0)):
			break
	print("arrival_frames: %s, %d frames -> %s" % [lv, n, out_dir])
	quit(0)
