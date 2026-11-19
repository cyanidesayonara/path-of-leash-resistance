extends SceneTree

# One dog's idle quirk, rendered frame by frame, and her bark as a WAV:
#
#   godot --rendering-method gl_compatibility --path . --script res://tools/dog_quirk_capture.gd -- DOG OUTDIR
#   python tools/frames_to_gif.py OUTDIR/frames DOG.gif 30
#
# She stands on plain paving in the wardrobe's pose, facing right, from a
# moment before her first quirk to just after it. The animation runs on the
# frame clock, so the frames are the quirk at its real speed whatever the
# machine.

const FPS := 30
const LEAD := 0.3
const TAIL := 0.4


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var dog_key: String = args[0] if args.size() > 0 else "millie"
	var out_dir: String = args[1] if args.size() > 1 else "user://dog_quirk"
	var game: Node = root.get_node("Game")
	var sfx: Node = root.get_node("Sfx")
	game.set("dog", dog_key)
	DirAccess.make_dir_recursive_absolute(out_dir + "/frames")
	var bark: AudioStreamWAV = sfx.lib[game.dog_bark(dog_key)]
	bark.save_to_wav("%s/%s-bark.wav" % [out_dir, dog_key])
	AnimClock.frame_clock = true
	var vp := SubViewport.new()
	vp.size = Vector2i(360, 240)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.transparent_bg = false
	root.add_child(vp)
	var bg := ColorRect.new()
	bg.color = Color(0.56, 0.55, 0.52)
	bg.size = Vector2(vp.size)
	vp.add_child(bg)
	var dog_script: GDScript = load("res://entities/dog.gd")
	var dog: CharacterBody2D = CharacterBody2D.new()
	dog.set_script(dog_script)
	dog.preview_mode = true
	dog.position = Vector2(170, 124)
	dog.scale = Vector2(4.0, 4.0)
	dog.facing = Vector2.RIGHT
	dog.hip_dir = Vector2.LEFT
	vp.add_child(dog)
	await process_frame
	var first := float(dog_script.QUIRK_FIRST)
	dog._still_since = AnimClock.msec() - int((first - LEAD) * 1000.0)
	dog._still_known = true
	var frames := int((LEAD + float(dog_script.QUIRK_LEN) + TAIL) * 60.0)
	var saved := 0
	for i in range(frames):
		await RenderingServer.frame_post_draw
		if i % (60 / FPS) == 0:
			vp.get_texture().get_image().save_png("%s/frames/f%04d.png" % [out_dir, saved])
			saved += 1
	print("dog_quirk_capture: %s (%s), %d frames at %d fps -> %s" % [dog_key, game.dog_quirk(dog_key), saved, FPS, out_dir])
	quit(0)
