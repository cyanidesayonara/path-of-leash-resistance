class_name EpilogueStage
extends Node2D

# Displays the "Back on the Sofa" epilogue cutscene (intro/scene_home.gd)
# behind the results card at the end of each successful walk.
#
# Skippable with any key, tap, or gamepad button.

const Scene := preload("res://intro/scene_home.gd")
const Kit := preload("res://hud/ui_kit.gd")

const CUES: Array = [
	[0.2, "intro_door", 1.0, -8.0],
	[2.4, "ui", 1.25, -10.0],
	[4.0, "intro_sigh", 1.0, -12.0],
	[5.3, "intro_paws", 1.2, -14.0],
]

var main: Node2D
var t := 0.0
var skipped := false
var cued := 0


func setup(m: Node2D) -> void:
	main = m
	visible = false


func reset() -> void:
	t = 0.0
	skipped = false
	cued = 0
	visible = true
	if DisplayServer.get_name() == "headless" or (main != null and bool(main.get("auto_walk"))):
		skip()


func skip() -> void:
	skipped = true
	t = maxf(t, 6.2)
	cued = CUES.size()
	if main != null and main.results_card != null:
		main.results_card.modulate.a = 1.0
		main.results_card.visible = true
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or skipped:
		return
	if (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed):
		skip()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not visible:
		return
	t += minf(delta, 0.1)
	while cued < CUES.size() and t >= float(CUES[cued][0]):
		var c: Array = CUES[cued]
		Sfx.play(String(c[1]), float(c[2]), float(c[3]))
		cued += 1
	_place()
	if main != null and main.results_card != null and main.results_card.visible:
		if skipped:
			main.results_card.modulate.a = 1.0
		else:
			main.results_card.modulate.a = clampf((t - 1.8) / 0.6, 0.0, 1.0)
	queue_redraw()


func _place() -> void:
	var vs := get_viewport_rect().size
	var k := minf(vs.x / 1280.0, vs.y / 720.0)
	var cam: Array = Scene.camera(minf(t, Scene.LENGTH))
	var z: float = cam[1]
	scale = Vector2(k * z, k * z)
	position = vs * 0.5 - (cam[0] as Vector2) * k * z


func _draw() -> void:
	if not visible:
		return
	draw_rect(Rect2(-4000, -4000, 9280, 8720), Color(0.86, 0.78, 0.66))
	Scene.draw(self, minf(t, Scene.LENGTH))
	# Skip hint in bottom-right corner while scene plays before results card appears
	if not skipped and t > 0.4 and t < 2.2:
		var vs := get_viewport_rect().size
		var a := clampf((t - 0.4) / 0.4, 0.0, 1.0) * clampf((2.2 - t) / 0.4, 0.0, 1.0)
		var label := Prompts.key("intro_skip")
		var word := "skip"
		var px := 15
		var cap_w := Kit.keycap_w(label, px)
		var word_w := Kit.text_w(Kit.display(), word, px)
		var w := cap_w + 8.0 + word_w
		var at := Vector2(vs.x - 30.0 - w, vs.y - 36.0)
		# Transform from screen coordinates into local stage space
		var inv := get_global_transform().affine_inverse()
		var lat := inv.basis_xform(at) + inv.origin
		draw_set_transform(lat, 0.0, Vector2.ONE / scale)
		draw_rect(Rect2(-10, -8, w + 20, 32), Color(0.06, 0.06, 0.08, 0.55 * a))
		Kit.keycap(self, Vector2.ZERO, label, px, 24.0, a)
		draw_string(Kit.display(), Vector2(cap_w + 8.0, 17.0), word, HORIZONTAL_ALIGNMENT_LEFT, -1, px,
			Color(Kit.INK.r, Kit.INK.g, Kit.INK.b, a))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
