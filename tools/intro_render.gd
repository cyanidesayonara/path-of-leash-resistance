extends SceneTree

# Renders an intro scene to numbered PNG frames, stepping time exactly (not in
# real time), at 2x and scaled down so edges are smooth:
#   godot --rendering-method gl_compatibility --path . --script res://tools/intro_render.gd -- walkies OUTDIR [fps] [width]
# Scenes: walkies, rooftops, titlefight. Join the frames into a clip with
# tools/frames_to_gif.py.

const SS := 2
const SCENES := {
	"walkies": "res://intro/scene_walkies.gd",
	"rooftops": "res://intro/scene_rooftops.gd",
	"titlefight": "res://intro/scene_titlefight.gd",
}


class Stage:
	extends Node2D
	var scene: GDScript
	var t := 0.0

	func _draw() -> void:
		scene.draw(self, t)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var name: String = args[0] if args.size() > 0 else "walkies"
	var out_dir: String = args[1] if args.size() > 1 else "user://intro_frames"
	var fps := float(args[2]) if args.size() > 2 else 15.0
	var width := int(args[3]) if args.size() > 3 else 640
	DirAccess.make_dir_recursive_absolute(out_dir)
	var vp := SubViewport.new()
	vp.size = Vector2i(1280 * SS, 720 * SS)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var st := Stage.new()
	st.scene = load(SCENES[name])
	st.scale = Vector2(SS, SS)
	vp.add_child(st)
	var n := int(ceil(float(st.scene.LENGTH) * fps))
	for i in range(n):
		st.t = float(i) / fps
		# the scene's camera, if it has one: [centre, zoom] in scene units
		var cam: Array = st.scene.camera(st.t)
		var z: float = cam[1]
		st.scale = Vector2(SS * z, SS * z)
		st.position = (Vector2(640, 360) - (cam[0] as Vector2) * z) * SS
		st.queue_redraw()
		await RenderingServer.frame_post_draw
		var img := vp.get_texture().get_image()
		img.resize(width, width * 9 / 16, Image.INTERPOLATE_LANCZOS)
		img.save_png("%s/f%04d.png" % [out_dir, i])
	print("intro_render: %s, %d frames at %d fps -> %s" % [name, n, int(fps), out_dir])
	quit(0)
