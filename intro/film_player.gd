class_name FilmPlayer
extends CanvasLayer

# Plays a story film over a walk: the telegraph to run, just before a chase
# walk's threat strikes (systems/home_chase.gd, begin). The walk is frozen
# under it and handed straight back when it ends or is skipped, then the
# chase's own warning and head start run as before. Every play is the full
# film; any key, click, tap or pad button skips it, as the intro.
#
# A film scene is a static script like the intro's: LENGTH, camera(t) ->
# [centre, zoom] and draw(canvas, t) in 1280x720 scene units, a BG colour
# for the margins a wide or tall window shows, and CUES, [time, sound,
# pitch, dB]. It never plays headless, for the autowalk, in a screenshot
# run (--shot...), or with --no-films; --films plays it in any of those
# that still draws.

const FADE_IN := 0.3
const FADE_OUT := 0.35

var main: Node
var scene: GDScript
var on_done := Callable()
var t := 0.0
var done_t := -1.0
var cued := 0
var stage: Stage
var hint: IntroPlayer.SkipHint
var froze := false


class Stage:
	extends Node2D
	var t := 0.0
	var scene: GDScript

	func _draw() -> void:
		draw_rect(Rect2(-4000, -4000, 9280, 8720), scene.BG)
		scene.draw(self, t)


static func should_play(m: Node, args: PackedStringArray = OS.get_cmdline_user_args()) -> bool:
	if "--films" in args:
		return true
	if "--no-films" in args or bool(m.get("auto_walk")):
		return false
	if DisplayServer.get_name() == "headless":
		return false
	for a in args:
		if a.begins_with("--shot"):
			return false
	return true


static func play(m: Node, film: GDScript, done: Callable = Callable()) -> FilmPlayer:
	var fp := FilmPlayer.new()
	fp.main = m
	fp.scene = film
	fp.on_done = done
	m.add_child(fp)
	return fp


func _ready() -> void:
	layer = 90
	stage = Stage.new()
	stage.scene = scene
	add_child(stage)
	hint = IntroPlayer.SkipHint.new()
	add_child(hint)
	main.set("film_playing", true)
	if not bool(main.get("frozen")):
		main.set("frozen", true)
		froze = true
	_place()


func _process(delta: float) -> void:
	# a hitch (a window drag) holds the film, never skips it
	t += minf(delta, 0.1)
	var cues: Array = scene.CUES
	while cued < cues.size() and t >= float(cues[cued][0]):
		var c: Array = cues[cued]
		Sfx.play(String(c[1]), float(c[2]), float(c[3]))
		cued += 1
	if done_t < 0.0 and t >= float(scene.LENGTH):
		_finish()
	_place()
	stage.t = minf(t, float(scene.LENGTH))
	stage.queue_redraw()
	hint.t = t
	hint.queue_redraw()
	var a := Anim.span(t, 0.0, FADE_IN)
	if done_t >= 0.0:
		var f := clampf((t - done_t) / FADE_OUT, 0.0, 1.0)
		a *= 1.0 - f
		hint.gone = minf(1.0, f * 2.0)
		if f >= 1.0:
			queue_free()
	stage.modulate.a = a


# the walk comes back as the film fades: the warning is said over the fade
func _finish() -> void:
	done_t = t
	cued = (scene.CUES as Array).size()
	main.set("film_playing", false)
	if froze and not bool(main.get("paused")):
		main.set("frozen", false)
	if on_done.is_valid():
		on_done.call()


func _place() -> void:
	var vs := get_viewport().get_visible_rect().size
	var k := minf(vs.x / 1280.0, vs.y / 720.0)
	var cam: Array = scene.camera(minf(t, float(scene.LENGTH)))
	var z: float = cam[1]
	stage.scale = Vector2(k * z, k * z)
	stage.position = vs * 0.5 - (cam[0] as Vector2) * k * z


func _input(event: InputEvent) -> void:
	Prompts.note(event)
	if done_t >= 0.0 or not IntroPlayer.skips(event):
		return
	get_viewport().set_input_as_handled()
	if t > 0.25:
		_finish()
