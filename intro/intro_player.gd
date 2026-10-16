class_name IntroPlayer
extends CanvasLayer

# Plays the intro ("Walkies?", intro/scene_walkies.gd) over the title screen
# when the game is launched, once per session, then fades into the title.
# Any key, click, tap or pad button skips it, except the volume keys, which
# belong to the system. It only plays on a plain launch:
# never headless, and never with command-line arguments (screenshots, the
# autowalk, tests and every dev flag pass some), so nothing automated ever
# waits on it. Scene units are 1280x720, fitted to the window; the scene's own
# camera moves within that.

const SCENE := preload("res://intro/scene_walkies.gd")
const END_AT := 14.4          # after the tow has left the frame
const FADE_OUT := 0.45
# the sound cues: [time, sound, pitch, volume dB]
const CUES := [
	[3.12, "intro_hook", 1.0, -10.0],
	[3.34, "intro_paws", 1.0, -12.0],
	[5.30, "intro_loop", 1.0, -10.0],
	[6.92, "intro_tap", 1.0, -12.0],
	[7.65, "intro_sigh", 1.0, -14.0],
	[9.22, "bark", 1.0, -3.0],
	[9.30, "intro_taut", 1.0, -8.0],
	[9.44, "intro_door", 1.0, -8.0],
]

var main: Node
var t := 0.0
var stage: Stage
var done_t := -1.0
var cued := 0
var skipped := false


class Stage:
	extends Node2D
	var t := 0.0
	var scene: GDScript

	func _draw() -> void:
		var col := Color(0.62, 0.80, 0.92) if t >= SCENE.TITLE_AT else Color(0.86, 0.78, 0.66)
		draw_rect(Rect2(-4000, -4000, 9280, 8720), col)
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
	# a hitch (the first frame, a window drag) holds the film, never skips it
	t += minf(delta, 0.1)
	Sfx.film_clock(t)
	while cued < CUES.size() and t >= float(CUES[cued][0]):
		var c: Array = CUES[cued]
		Sfx.play(String(c[1]), float(c[2]), float(c[3]))
		cued += 1
	if done_t < 0.0 and t >= END_AT:
		done_t = t
	if done_t >= 0.0 and bool(main.get("intro_playing")):
		main.set("intro_playing", false)
		Sfx.handoff(skipped, FADE_OUT)
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
	if not skips(event):
		return
	get_viewport().set_input_as_handled()
	if done_t < 0.0 and t > 0.25:
		skipped = true
		cued = CUES.size()
		done_t = t


# a press that ends the film. Volume keys are the system's, so they pass through.
static func skips(event: InputEvent) -> bool:
	if event is InputEventKey:
		var key := event as InputEventKey
		if not key.pressed or key.echo:
			return false
		if _volume_key(key.keycode) or _volume_key(key.physical_keycode):
			return false
		return true
	return (event is InputEventMouseButton and event.pressed) \
		or (event is InputEventScreenTouch and event.pressed) \
		or (event is InputEventJoypadButton and event.pressed)


static func _volume_key(code: Key) -> bool:
	return code == KEY_VOLUMEUP or code == KEY_VOLUMEDOWN or code == KEY_VOLUMEMUTE
