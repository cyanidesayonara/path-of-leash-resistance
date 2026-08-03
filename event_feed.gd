extends Control

# ONE PLACE WHERE THE GAME TELLS YOU THINGS.
#
# Before this, a single moment could announce itself three times in three
# different parts of the screen. Taking a call put a speech bubble over the
# owner, a floating line over the dog, and a status line under the vitals card
# in the top-left corner - all saying the same thing, none of them obviously
# the one to read. Meanwhile every other announcement in the game was a world
# float fired at the dog's own position, so two events landing together drew
# straight on top of each other and neither could be read.
#
# The split that fixes it is between two kinds of feedback that were being
# treated as one:
#
#   POINT-OF-IMPACT NUMBERS stay in the world, at the thing they refer to.
#   "boop! +4" belongs on the cat; "snack +1" belongs on the kebab. Its
#   position IS its meaning, and it never collides with anything for long
#   because it is tied to a specific object. Those keep using float_text.
#
#   ANNOUNCEMENTS come here. Anything about the state of the walk - a mood
#   arriving, the owner stopping dead, a trick landing, a chase starting - is
#   about the dog rather than about a place, so it has no business being drawn
#   at a world position at all. Queued, one at a time, always in the same spot.
#
# Two slots, and never more:
#
#   THE BANNER is the one-line answer to "what is going on right now" - the
#   thing that is true until it stops being true. A slack countdown, a chase,
#   what this leg of the walk wants from you. It replaces the old status line.
#
#   THE FEED is up to two transient lines under it. They QUEUE rather than
#   overlap, which is the whole point: a vault landing at the same moment a
#   mood arrives now reads as two lines in order instead of one illegible pile.
#
# Placed centre-screen and a little low, because the camera keeps the dog near
# the middle: close to where the eyes already are, and always the same place,
# so it can be found by glancing rather than by hunting.

# HOW IT LOOKS: Crash and Tony Hawk, which is what this game is aiming at
# everywhere else. Those games shout at you in big blocky capitals with a
# heavy dark outline, and they get away with it over any background precisely
# because of the outline - no panel, no box, no translucent strip, just letters
# thick enough to read at a glance while you are busy doing something else.
#
# So: all caps, big, outlined rather than backed, and each line lands with a
# short scale punch so it registers in peripheral vision. The first version of
# this used 19px text on a faint dark strip and read like a subtitle, which is
# the opposite of the tone.

enum Tone { PLAIN, GOOD, BAD, LOUD }

const SHOW_S := 2.4          # how long a transient line lives
const FADE_S := 0.55         # ...and how much of that it spends fading
const MAX_LINES := 2         # more than this is a wall of text, not a signal
const GAP := 44.0
# the shout and the standing instruction, which should not be the same weight:
# a banner is on screen for twenty seconds and must not dominate the picture
const SIZE_SAY := 34
const SIZE_BANNER := 23
const OUTLINE_SAY := 10
const OUTLINE_BANNER := 7
# the punch: a line arrives slightly oversized and settles, over this long
const PUNCH_S := 0.13
const PUNCH := 1.28

const TONE_COL := {
	Tone.PLAIN: Color(0.94, 0.92, 0.86),
	Tone.GOOD: Color(0.78, 1.00, 0.80),
	Tone.BAD: Color(1.00, 0.70, 0.62),
	Tone.LOUD: Color(1.00, 0.88, 0.46),
}

var main: Node2D
var banner := ""
var banner_col := Color(1.0, 0.92, 0.72)
# newest last; each is {"text": String, "tone": int, "t": float}
var lines: Array[Dictionary] = []


func setup(m: Node2D) -> void:
	main = m


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


func say(text: String, tone: int = Tone.PLAIN) -> void:
	if text == "":
		return
	# the same line twice running is a stutter, not news - refresh it instead
	if not lines.is_empty():
		var last: Dictionary = lines[lines.size() - 1]
		if String(last["text"]) == text:
			last["t"] = 0.0
			return
	lines.append({"text": text, "tone": tone, "t": 0.0})
	while lines.size() > MAX_LINES:
		lines.remove_at(0)
	queue_redraw()


func set_banner(text: String, col: Color = Color(1.0, 0.92, 0.72)) -> void:
	if text == banner:
		return
	banner = text
	banner_col = col
	queue_redraw()


func _process(delta: float) -> void:
	if lines.is_empty():
		return
	var i := lines.size() - 1
	while i >= 0:
		var l: Dictionary = lines[i]
		l["t"] = float(l["t"]) + delta
		if float(l["t"]) >= SHOW_S:
			lines.remove_at(i)
		i -= 1
	queue_redraw()


func _draw() -> void:
	if banner == "" and lines.is_empty():
		return
	var f := ThemeDB.fallback_font
	var vs := get_viewport_rect().size
	# a little below the middle: the camera holds the dog near the centre, so
	# this sits just under her without covering her
	var y: float = vs.y * 0.63
	if banner != "":
		# gently pulsing, so a standing instruction reads as live rather than
		# as something painted on
		var a: float = 0.82 + 0.18 * sin(Time.get_ticks_msec() / 240.0)
		_line(f, vs.x, y, banner, SIZE_BANNER, OUTLINE_BANNER,
			Color(banner_col.r, banner_col.g, banner_col.b, a), 1.0)
		y += GAP * 0.7
	for l: Dictionary in lines:
		var t := float(l["t"])
		var fade: float = 1.0 if t < SHOW_S - FADE_S else clampf((SHOW_S - t) / FADE_S, 0.0, 1.0)
		# and rising slightly as it goes, which is what makes a queue read as
		# a queue rather than as text swapping in place
		var rise: float = minf(t, SHOW_S) * 7.0
		# the punch: oversized for a moment as it lands, then settles
		var punch: float = 1.0
		if t < PUNCH_S:
			punch = lerpf(PUNCH, 1.0, t / PUNCH_S)
		var col: Color = TONE_COL.get(int(l["tone"]), TONE_COL[Tone.PLAIN])
		_line(f, vs.x, y - rise, String(l["text"]), SIZE_SAY, OUTLINE_SAY,
			Color(col.r, col.g, col.b, fade), punch)
		y += GAP


func _line(f: Font, w: float, y: float, text: String, size: int, outline: int,
		col: Color, punch: float) -> void:
	# Capitals with a heavy dark outline and no panel behind them. The outline
	# is what makes this legible over pale paving and black tarmac alike, and
	# it is why none of this needs a box drawn under it.
	var up := text.to_upper()
	var tw: float = f.get_string_size(up, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	# Never let a line run the full width of the screen. Big type only shouts
	# if it is short; a sentence set at 34px reaches both edges and stops
	# reading as a shout at all. Copy should be kept short, and this is the
	# backstop for when it is not - shrink to fit rather than spill.
	var room: float = w * 0.78
	while tw > room and size > 15:
		size -= 2
		outline = maxi(4, outline - 1)
		tw = f.get_string_size(up, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var cx := w * 0.5
	var shade := Color(0.04, 0.03, 0.06, col.a)
	if punch != 1.0:
		# scaled about the middle of the line, so a punch grows outward from
		# the centre rather than shoving the text sideways
		draw_set_transform(Vector2(cx, y), 0.0, Vector2(punch, punch))
		var at := Vector2(-tw * 0.5, 0.0)
		f.draw_string_outline(get_canvas_item(), at, up, HORIZONTAL_ALIGNMENT_LEFT, -1,
			size, outline, shade)
		f.draw_string(get_canvas_item(), at, up, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	var pos := Vector2(cx - tw * 0.5, y)
	f.draw_string_outline(get_canvas_item(), pos, up, HORIZONTAL_ALIGNMENT_LEFT, -1,
		size, outline, shade)
	f.draw_string(get_canvas_item(), pos, up, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
