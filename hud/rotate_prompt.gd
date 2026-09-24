extends CanvasLayer

# The game is laid out for a landscape window. In portrait the 1280x720
# reference squeezes into the short axis: the world renders at about a third of
# its size, the HUD is unreadable, and the camera shows the empty street behind
# the start line (#5). Nothing sensible can be laid out that way, so a portrait
# window gets this instead: a full-screen prompt to turn the phone (or widen
# the window), with the game paused until it is landscape again.
#
# iOS Safari has no orientation lock, so a phone held upright is a real case,
# not an edge case. Where the browser does offer a lock (Android Chrome, and
# only in fullscreen) it is requested too; it fails silently everywhere else.

const LAYER := 120            # above the HUD, the panels and the dim
const BG := Color(0.1, 0.12, 0.11, 0.96)
const INK := Color(0.96, 0.93, 0.84)

var _paused_it := false
var _root: Control
var _title: Label
var _sub: Label
var _phone: Control


class PhoneGlyph:
	extends Control
	# a phone outline tipping from upright to sideways, on a loop
	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var c := size * 0.5
		var h := minf(size.x, size.y) * 0.8
		var w := h * 0.52
		# drawing-only animation: the wall clock is fine here
		var t := fmod(AnimClock.msec() / 1000.0, 2.4)
		var k := clampf((t - 0.6) / 0.8, 0.0, 1.0)
		k = k * k * (3.0 - 2.0 * k)
		draw_set_transform(c, -PI * 0.5 * k)
		var r := Rect2(Vector2(-w, -h) * 0.5, Vector2(w, h))
		draw_rect(r, INK, false, h * 0.06)
		draw_circle(Vector2(0.0, h * 0.38), h * 0.035, INK)
		draw_set_transform(Vector2.ZERO)


func _ready() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(bg)
	_phone = PhoneGlyph.new()
	_root.add_child(_phone)
	_title = _label(1.0)
	_sub = _label(0.66)
	_sub.modulate.a = 0.75
	var touch := DisplayServer.is_touchscreen_available()
	_title.text = "Turn your phone sideways" if touch else "Make the window wider"
	_sub.text = "The walk waits for you."
	get_viewport().size_changed.connect(_refresh)
	_refresh()


func _label(scale: float) -> Label:
	var l := Label.new()
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_color_override("font_color", INK)
	l.set_meta("scale", scale)
	_root.add_child(l)
	return l


func is_portrait() -> bool:
	var vs := get_viewport().get_visible_rect().size
	return vs.y > vs.x


func _refresh() -> void:
	var portrait := is_portrait()
	visible = portrait
	# --shot photographs the prompt instead of being paused by it: the capture
	# counts frames in main.gd, which a paused tree would stop
	var capture := "--shot" in OS.get_cmdline_user_args()
	# pause only what this prompt paused, so it never un-pauses anything else
	if portrait and not capture and not get_tree().paused:
		get_tree().paused = true
		_paused_it = true
	elif not portrait and _paused_it:
		get_tree().paused = false
		_paused_it = false
	if portrait:
		_layout()
		if OS.has_feature("web"):
			JavaScriptBridge.eval(
				"if (screen.orientation && screen.orientation.lock) screen.orientation.lock('landscape').catch(function(){});",
				true)


func _layout() -> void:
	# sized off the live viewport: under the "expand" stretch a portrait phone
	# sees a very tall logical canvas, so fixed pixel sizes would come out tiny
	var vs := get_viewport().get_visible_rect().size
	var unit := vs.x / 10.0
	var glyph := unit * 3.2
	_phone.size = Vector2(glyph, glyph)
	_phone.position = Vector2((vs.x - glyph) * 0.5, vs.y * 0.5 - glyph * 1.1)
	var y := vs.y * 0.5 + unit * 0.3
	for l: Label in [_title, _sub]:
		var fs := int(unit * 0.62 * float(l.get_meta("scale")))
		l.add_theme_font_size_override("font_size", fs)
		l.position = Vector2(unit * 0.5, y)
		l.size = Vector2(vs.x - unit, fs * 3.0)
		y += fs * 2.6
