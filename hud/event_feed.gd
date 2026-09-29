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

# WHERE EACH KIND OF MESSAGE GOES (2026-09-30). Every message used to be the
# same outlined capitals in the middle of the screen, so a goal, a mood, the
# owner stopping and a trick all read alike and stacked up in one place. Now
# each kind has a place and a look of its own:
#
#   the BANNER    what is true right now, as a pill at the top centre, and
#                 the owner's news (flash) takes it over for a moment
#   TOASTS        a goal lands by the goal list, top right; a mood arrives by
#                 the vitals, top left, in the mood's own colour
#   CARDS         a tutorial lesson and a bystander's dare are cards under
#                 the banner (their Labels on main hold the text)
#   SHOUTS        only what she just DID, or something that needs her now:
#                 big heavy capitals just under the dog, as before
#
# and the world's own voices (speech, sounds, scores) are drawn where they
# happen, by world/pops_layer.gd.

enum Tone { PLAIN, GOOD, BAD, LOUD }

const Kit := preload("res://hud/ui_kit.gd")
const Icons := preload("res://hud/ui_icons.gd")

const BANNER_Y := 42.0
const BANNER_PX := 17
const FLASH_S := 2.6
const TOAST_S := 3.0
const TOAST_W := 300.0
const MAX_TOASTS := 2

const SHOW_S := 2.4          # how long a transient line lives
const FADE_S := 0.55         # ...and how much of that it spends fading
const MAX_LINES := 2         # more than this is a wall of text, not a signal
# the shout and the standing instruction, which should not be the same weight:
# a banner is on screen for twenty seconds and must not dominate the picture
const SIZE_SAY := 34
const SIZE_BANNER := 23
const OUTLINE_SAY := 10
const OUTLINE_BANNER := 7
# the punch: a line arrives slightly oversized and settles, over this long
const PUNCH_S := 0.13
const PUNCH := 1.28
# how far a feed line drifts up over its life, in px per second
const RISE := 7.0
# Every line owns a slot tall enough for everything it will ever do - its
# capitals and outline at the biggest punch, and at the top of its rise - so
# a rising or punching line can never climb into the one above (#59: the feed
# used to sit 31px under the banner and rose into it). The text is always
# capitals, so a line's ink reaches CAP_H * size above the baseline and
# DESC_H * size below it (commas, Q, J), plus half its outline either way.
const CAP_H := 0.73
const DESC_H := 0.10
const SLOT_MARGIN := 4.0

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
# the owner's news, holding the banner for a moment
var flash_text := ""
var flash_t := 0.0
# {"side": "goal"|"mood", "title", "text", "col", "t"}
var toasts: Array[Dictionary] = []


func setup(m: Node2D) -> void:
	main = m


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


func say(text: String, tone: int = Tone.PLAIN) -> void:
	if text == "":
		return
	# the same line twice running is a stutter, not news - refresh it instead;
	# and the score for a shout already up ("POLE SWING!" then "POLE SWING!
	# 14") lands in that line rather than stacking a second copy under it
	var head := text.get_slice("!", 0)
	for l: Dictionary in lines:
		var lt := String(l["text"])
		if lt == text or (text.contains("!") and lt.contains("!") and lt.get_slice("!", 0) == head):
			l["text"] = text
			l["tone"] = tone
			l["t"] = 0.0
			queue_redraw()
			return
	lines.append({"text": text, "tone": tone, "t": 0.0})
	while lines.size() > MAX_LINES:
		lines.remove_at(0)
	queue_redraw()


# The owner's news ("HE'S TEXTING! HE'S NOT LOOKING") is about the walk
# right now, so it takes the banner for a moment rather than shouting.
func flash(text: String) -> void:
	flash_text = text
	flash_t = FLASH_S
	queue_redraw()


func toast(side: String, title: String, text: String, col: Color) -> void:
	toasts.append({"side": side, "title": title, "text": text, "col": col, "t": 0.0})
	var n := 0
	for i in range(toasts.size() - 1, -1, -1):
		if String(toasts[i].side) == side:
			n += 1
			if n > MAX_TOASTS:
				toasts.remove_at(i)
	queue_redraw()


func set_banner(text: String, col: Color = Color(1.0, 0.92, 0.72)) -> void:
	if text == banner:
		return
	banner = text
	banner_col = col
	queue_redraw()


func _process(delta: float) -> void:
	flash_t = maxf(0.0, flash_t - delta)
	for i in range(toasts.size() - 1, -1, -1):
		toasts[i].t = float(toasts[i].t) + delta
		if float(toasts[i].t) > TOAST_S:
			toasts.remove_at(i)
	if not toasts.is_empty() or flash_t > 0.0 or _cards_up():
		queue_redraw()
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


func _cards_up() -> bool:
	return main != null and ((main.tut_label != null and main.tut_label.visible)
		or (main.challenge_l != null and main.challenge_l.visible))


func _draw() -> void:
	var vs := get_viewport_rect().size
	_draw_toasts(vs)
	_draw_cards(vs)
	var f := Kit.display()
	for e: Dictionary in layout(vs):
		if bool(e.get("pill", false)):
			_pill(vs, float(e["y"]), String(e["text"]), e["col"])
		else:
			_line(f, vs.x, float(e["y"]), String(e["text"]), int(e["size"]), int(e["outline"]),
				e["col"], float(e["punch"]))


func _pill(vs: Vector2, y: float, text: String, col: Color) -> void:
	# the standing instruction: one pill, top centre, the tone as a dot
	var f := Kit.display()
	var up := text.to_upper()
	var tw := Kit.text_w(f, up, BANNER_PX)
	var r := Rect2(vs.x * 0.5 - tw * 0.5 - 30.0, y - 22.0, tw + 50.0, 32.0)
	draw_rect(Rect2(r.position + Vector2(0, 3), r.size), Color(0, 0, 0, 0.25 * col.a))
	draw_rect(r, Color(0.07, 0.075, 0.09, 0.82 * col.a))
	draw_circle(Vector2(r.position.x + 16.0, y - 6.0), 5.0, Color(col.r, col.g, col.b, col.a))
	draw_string(f, Vector2(r.position.x + 30.0, y), up, HORIZONTAL_ALIGNMENT_LEFT, -1, BANNER_PX,
		Color(col.r, col.g, col.b, col.a))


func _draw_toasts(vs: Vector2) -> void:
	var by_side := {"goal": 0, "mood": 0}
	for tst: Dictionary in toasts:
		var side := String(tst.side)
		var t: float = tst.t
		var slide: float = clampf(t / 0.18, 0.0, 1.0)
		var a: float = clampf((TOAST_S - t) / 0.5, 0.0, 1.0)
		var col: Color = tst.col
		var i: int = by_side[side]
		by_side[side] = i + 1
		var x: float
		var y: float
		if side == "goal":
			var gr := Rect2(vs.x - 290.0, 8.0, 280.0, 40.0)
			if main != null and main.goals_card != null:
				gr = main.goals_card.get_rect()
			x = vs.x - 8.0 - TOAST_W + (1.0 - slide) * 60.0
			y = gr.end.y + 8.0 + float(i) * 58.0
		else:
			x = 16.0 - (1.0 - slide) * 60.0
			y = 112.0 + float(i) * 58.0
		var r := Rect2(x, y, TOAST_W, 50.0)
		draw_rect(Rect2(r.position + Vector2(0, 3), r.size), Color(0, 0, 0, 0.25 * a))
		draw_rect(r, Color(0.07, 0.075, 0.09, 0.9 * a))
		draw_rect(Rect2(r.position, Vector2(4.0, r.size.y)), Color(col.r, col.g, col.b, a))
		var tx := r.position.x + 16.0
		if side == "goal":
			Icons.draw_check(self, Vector2(tx, r.position.y + 10.0), 14.0, Icons.Check.DONE_NOW)
			tx += 24.0
		draw_string(Kit.display(), Vector2(tx, r.position.y + 22.0), String(tst.title), HORIZONTAL_ALIGNMENT_LEFT,
			-1, 15, Color(col.r, col.g, col.b, a))
		draw_string(Kit.body(), Vector2(r.position.x + 16.0, r.position.y + 41.0), String(tst.text),
			HORIZONTAL_ALIGNMENT_LEFT, TOAST_W - 28.0, 14, Color(0.92, 0.90, 0.85, a))


func _draw_cards(vs: Vector2) -> void:
	# a tutorial lesson and a dare, as cards under the banner. The Labels on
	# main keep the text and whether each is up; they are never drawn.
	if main == null:
		return
	var y := BANNER_Y + 24.0
	if main.tut_label != null and main.tut_label.visible:
		var title := String(main.tut_label.text)
		var hint := String(main.tut_hint.text)
		var w := clampf(maxf(Kit.text_w(Kit.display(), title, 22), Kit.text_w(Kit.body(), hint, 16)) + 60.0, 360.0, vs.x - 80.0)
		var r := Rect2(vs.x * 0.5 - w * 0.5, y, w, 70.0)
		var glow: Color = main.tut_label.modulate
		Kit.card(self, r, Color(0.52, 0.80, 0.98).lerp(Color(0.6, 1.0, 0.65), 1.0 - glow.b), 12)
		Kit.heading(self, Vector2(r.position.x, r.position.y + 32.0), title, 22, Kit.INK, HORIZONTAL_ALIGNMENT_CENTER, w)
		draw_string(Kit.body(), Vector2(r.position.x, r.position.y + 56.0), hint, HORIZONTAL_ALIGNMENT_CENTER, w, 16,
			Kit.INK_SOFT)
		y += 80.0
	if main.challenge_l != null and main.challenge_l.visible and main.challenge != null:
		var ch: Node = main.challenge
		var col: Color = main.challenge_l.modulate
		var title := "DARE: %d TRICKS" % int(ch.target)
		var w := 300.0
		var r := Rect2(vs.x * 0.5 - w * 0.5, y, w, 58.0)
		Kit.card(self, r, col, 12)
		Kit.heading(self, Vector2(r.position.x + 18.0, r.position.y + 28.0), title, 18, col)
		draw_string(Kit.display(), Vector2(r.position.x, r.position.y + 28.0), "%d / %d" % [int(ch.count), int(ch.target)],
			HORIZONTAL_ALIGNMENT_RIGHT, w - 18.0, 18, Kit.INK)
		Icons.draw_meter(self, Vector2(r.position.x + 18.0, r.position.y + 40.0), w - 36.0, 7.0, float(ch.fraction()), col)


# Where every visible line goes this frame, banner first: text, size, outline,
# colour, baseline y and punch scale. _draw paints exactly this, and
# tests/test_event_feed.gd holds it to never letting two lines' ink meet.
func layout(vs: Vector2) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	# a little below the middle: the camera holds the dog near the centre, so
	# this sits just under her without covering her
	var y: float = vs.y * 0.63
	# the lowest ink drawn so far; the next slot starts under it
	var floor_y: float = -INF
	var shown := flash_text if flash_t > 0.0 else banner
	if shown != "":
		# at the top, out of the middle: what is true right now, not news.
		# Gently pulsing, so it reads as live rather than painted on.
		var a: float = 0.82 + 0.18 * sin(AnimClock.msec() / 240.0)
		var bc: Color = Color(1.0, 0.86, 0.5) if flash_t > 0.0 else banner_col
		out.append({"text": shown, "size": BANNER_PX, "outline": 0,
			"col": Color(bc.r, bc.g, bc.b, a), "y": BANNER_Y, "punch": 1.0,
			"rise": 0.0, "pill": true})
	for l: Dictionary in lines:
		var t := float(l["t"])
		if floor_y > -INF:
			y = floor_y + SLOT_MARGIN + slot_above(SIZE_SAY, OUTLINE_SAY)
		var fade: float = 1.0 if t < SHOW_S - FADE_S else clampf((SHOW_S - t) / FADE_S, 0.0, 1.0)
		# and rising slightly as it goes, which is what makes a queue read as
		# a queue rather than as text swapping in place
		var rise: float = minf(t, SHOW_S) * RISE
		# the punch: oversized for a moment as it lands, then settles
		var punch: float = 1.0
		if t < PUNCH_S:
			punch = lerpf(PUNCH, 1.0, t / PUNCH_S)
		var col: Color = TONE_COL.get(int(l["tone"]), TONE_COL[Tone.PLAIN])
		out.append({"text": String(l["text"]), "size": SIZE_SAY, "outline": OUTLINE_SAY,
			"col": Color(col.r, col.g, col.b, fade), "y": y - rise, "punch": punch,
			"rise": rise})
		# the slot's floor is the line at rest (no rise) at its biggest punch
		floor_y = y + ink_below(SIZE_SAY, OUTLINE_SAY, PUNCH)
	return out


# how far a line's ink reaches above and below its baseline at a punch scale
func ink_above(size: int, outline: int, punch: float) -> float:
	return (CAP_H * size + outline * 0.5) * punch


func ink_below(size: int, outline: int, punch: float) -> float:
	return (DESC_H * size + outline * 0.5) * punch


# the room a feed line needs above its resting baseline over its whole life:
# the bigger of landing oversized and having risen to the top
func slot_above(size: int, outline: int) -> float:
	return maxf(ink_above(size, outline, PUNCH), ink_above(size, outline, 1.0) + SHOW_S * RISE)


# Never let a line run the full width of the screen. Big type only shouts if
# it is short; a sentence set at 34px reaches both edges and stops reading as
# a shout at all. Copy should be kept short, and this is the backstop for when
# it is not - shrink to fit rather than spill. Returns [size, outline, width].
func _fit(f: Font, w: float, up: String, size: int, outline: int) -> Array:
	var tw: float = f.get_string_size(up, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var room: float = w * 0.78
	while tw > room and size > 15:
		size -= 2
		outline = maxi(4, outline - 1)
		tw = f.get_string_size(up, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	return [size, outline, tw]


# Where the feed's ink is on screen right now, one rect per line: what world
# labels keep clear of (main.float_text, #66). Empty when the feed is empty.
func ink_rects(vs: Vector2) -> Array[Rect2]:
	var out: Array[Rect2] = []
	var f := Kit.display()
	for e: Dictionary in layout(vs):
		var fit := _fit(f, vs.x, String(e["text"]).to_upper(), int(e["size"]), int(e["outline"]))
		var p := float(e["punch"])
		var y := float(e["y"])
		var half_w := (float(fit[2]) * 0.5 + int(fit[1]) * 0.5) * p
		var top := y - ink_above(int(fit[0]), int(fit[1]), p)
		var bottom := y + ink_below(int(fit[0]), int(fit[1]), p)
		out.append(Rect2(vs.x * 0.5 - half_w, top, half_w * 2.0, bottom - top))
	return out


func _line(f: Font, w: float, y: float, text: String, size: int, outline: int,
		col: Color, punch: float) -> void:
	# Capitals with a heavy dark outline and no panel behind them. The outline
	# is what makes this legible over pale paving and black tarmac alike, and
	# it is why none of this needs a box drawn under it.
	var up := text.to_upper()
	var fit := _fit(f, w, up, size, outline)
	size = fit[0]
	outline = fit[1]
	var tw: float = fit[2]
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
