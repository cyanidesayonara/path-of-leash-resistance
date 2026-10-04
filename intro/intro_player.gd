class_name IntroPlayer
extends CanvasLayer

# Plays the intro ("Walkies?", intro/scene_walkies.gd) over the title screen
# when the game is launched, once per session, then fades into the title.
# Any key, click, tap or pad button skips it. It only plays on a plain launch:
# never headless, and never with command-line arguments (screenshots, the
# autowalk, tests and every dev flag pass some), so nothing automated ever
# waits on it. Scene units are 1280x720, fitted to the window; the scene's own
# camera moves within that.

const SCENE := preload("res://intro/scene_walkies.gd")
const END_AT := 14.4          # after the tow has left the frame
const FADE_OUT := 0.45
# the sound cues: [time, sound, pitch, volume dB]
const CUES := [
	[3.12, "pickup", 0.8, -8.0],     # the leash off its hook
	[5.3, "ui", 0.7, -6.0],          # the loop on their knee
	[6.92, "tangle", 1.3, -10.0],    # the nose against the phone
	[7.65, "hiss", 0.6, -15.0],      # the sigh
	[9.22, "bark", 1.0, -3.0],       # the YANK
	[9.3, "fling", 0.9, -4.0],
	[9.5, "crack", 0.7, -6.0],       # the door
	[10.65, "star", 1.0, -6.0],      # the title lands
]

var main: Node
var t := 0.0
var stage: Stage
var done_t := -1.0
var cued := 0


class Stage:
	extends Node2D
	var t := 0.0
	var scene: GDScript

	func _draw() -> void:
		# whatever the window's shape, warm ground beyond the scene's edges
		draw_rect(Rect2(-4000, -4000, 9280, 8720), Color(0.98, 0.86, 0.62))
		scene.draw(self, t)


static func should_play(m: Node) -> bool:
	if m.get_node("/root/Game").get("intro_seen"):
		return false
	if DisplayServer.get_name() == "headless":
		return false
	return OS.get_cmdline_user_args().is_empty()


static func play(m: Node) -> void:
	m.get_node("/root/Game").set("intro_seen", true)
	var ip := IntroPlayer.new()
	ip.main = m
	m.add_child(ip)


func _ready() -> void:
	layer = 100
	stage = Stage.new()
	stage.scene = SCENE
	add_child(stage)
	main.set("intro_playing", true)


func _process(delta: float) -> void:
	t += delta
	while cued < CUES.size() and t >= float(CUES[cued][0]):
		var c: Array = CUES[cued]
		Sfx.play(String(c[1]), float(c[2]), float(c[3]))
		cued += 1
	if done_t < 0.0 and t >= END_AT:
		done_t = t
	# the title takes over as the film fades, so it is not frozen under it
	if done_t >= 0.0:
		main.set("intro_playing", false)
	_place()
	stage.t = minf(t, END_AT)
	stage.queue_redraw()
	if done_t >= 0.0:
		var f := clampf((t - done_t) / FADE_OUT, 0.0, 1.0)
		stage.modulate.a = 1.0 - f
		if f >= 1.0:
			queue_free()


func _place() -> void:
	var vs := get_viewport().get_visible_rect().size
	var k := minf(vs.x / 1280.0, vs.y / 720.0)
	var cam: Array = SCENE.camera(minf(t, END_AT))
	var z: float = cam[1]
	stage.scale = Vector2(k * z, k * z)
	stage.position = vs * 0.5 - (cam[0] as Vector2) * k * z


func _input(event: InputEvent) -> void:
	var press: bool = (event is InputEventKey and event.pressed and not event.echo) \
		or (event is InputEventMouseButton and event.pressed) \
		or (event is InputEventScreenTouch and event.pressed) \
		or (event is InputEventJoypadButton and event.pressed)
	if press:
		get_viewport().set_input_as_handled()
		if done_t < 0.0 and t > 0.25:
			done_t = t
