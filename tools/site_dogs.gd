extends SceneTree

# Renders a side-on portrait of every dog in Game.DOG_KEYS for the website:
# each one standing, head up, tail going, drawn by the films' own dog
# (IntroKit.millie) at 2x and scaled down, on a transparent background.
#   godot --rendering-method gl_compatibility --path . --script res://tools/site_dogs.gd -- OUTDIR [width]
# Writes OUTDIR/dog-<id>.png. tools/site_media.sh runs it.

const SS := 2
const W := 480
const H := 320
# where her feet stand in the frame, and her size in it
const FEET := Vector2(W * 0.5, H * 0.86)
const SCALE := 1.5


class Stage:
	extends Node2D

	func _draw() -> void:
		IntroKit.millie(self, FEET, SCALE, 1.0, Vector2.ONE,
			{"head_up": 0.35, "ear": 0.4, "tail": 0.45, "mouth": 0.25, "reach": 0.1, "push": -0.1}, FEET.y)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var out_dir: String = args[0] if args.size() > 0 else "user://dogs"
	var width := int(args[1]) if args.size() > 1 else 360
	DirAccess.make_dir_recursive_absolute(out_dir)
	var game := root.get_node("/root/Game")
	var vp := SubViewport.new()
	vp.size = Vector2i(W * SS, H * SS)
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var st := Stage.new()
	st.scale = Vector2(SS, SS)
	vp.add_child(st)
	for id: String in game.DOG_KEYS:
		game.set("dog", id)
		st.queue_redraw()
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var img := vp.get_texture().get_image()
		img.resize(width, width * H / W, Image.INTERPOLATE_LANCZOS)
		img.save_png("%s/dog-%s.png" % [out_dir, id])
	print("site_dogs: %d dogs -> %s" % [game.DOG_KEYS.size(), out_dir])
	quit(0)
