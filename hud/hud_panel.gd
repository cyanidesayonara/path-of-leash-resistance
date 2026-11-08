extends Control

# The whole left-side HUD as one quiet card. Every row says what it is: the
# phone's lives, then her pee and, right under it in the same yellow, the
# spots it has marked (the one idea: pee is what marks a spot), then the
# zoomies, with the bones banked top right. It used to be glyphs
# alone (three pips, two upright tubes, five rings), and nobody could tell
# which was which. The world is chaotic on purpose; the overlay is not.

const Icons := preload("res://hud/ui_icons.gd")
const Kit := preload("res://hud/ui_kit.gd")

const CARD_W := 214.0
const PAD := 10.0
# the rows, top to bottom: each value is the row's top
const ROW_PHONE := 8.0
const ROW_TANK := 36.0
const ROW_MARKS := 54.0
const ROW_ZOOM := 72.0
# rows that show only while they matter (nature calling, a mood) stack under
# the zoomies from here, and the card grows by a row for each
const ROW_EXTRA := 90.0
const POOP_COL := Color(0.70, 0.48, 0.28)
const ROW_H := 18.0
const CARD_H := ROW_ZOOM + ROW_H + 6.0
# the label column, then the column every bar and the mark dots start at
const LABEL_X := 28.0
const BAR_X := 90.0
const BAR_H := 8.0
const LABEL_PX := 11
const LABEL_COL := Color(0.80, 0.78, 0.72)
const TANK_COL := Color(0.94, 0.82, 0.25)
const ZOOM_COL := Color(0.35, 0.88, 0.45)

# what a lesson can point at, and the outline drawn round it
const POINT_RECTS := {
	"phone": Rect2(4, ROW_PHONE - 4.0, 104, 28),
	"tank": Rect2(4, ROW_TANK - 2.0, CARD_W - 8.0, ROW_H),
	"zoomies": Rect2(4, ROW_ZOOM - 2.0, CARD_W - 8.0, ROW_H),
}

var main: Node2D
var sb: StyleBoxFlat


func setup(m: Node2D) -> void:
	main = m


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.09, 0.10, 0.42)
	sb.set_corner_radius_all(10)


# Under a menu (the dim is up: pause, settings, a walk card) the card fades
# out, so the menu is the only thing on screen; it fades back on resume.
const DIM_FADE := 6.0


func _process(delta: float) -> void:
	# THAT'S THE BASICS points at the phone pips, so the card stays for it
	var under_menu: bool = main != null and main.dim != null and main.dim.visible \
		and String(main.confirm_id) != "basics"
	modulate.a = move_toward(modulate.a, 0.0 if under_menu else 1.0, delta * DIM_FADE)
	if visible:
		queue_redraw()


# the stand-in canvas for this node's drawing, made fresh each _draw
var _b: ShapeBatch


func _draw() -> void:
	# every draw call goes through a ShapeBatch standing in for the canvas: runs
	# of shapes become one draw call, same pixels (systems/shape_batch.gd)
	_b = ShapeBatch.new(self)
	_draw_shapes()
	_b.flush()


# The rows that show only while they matter: "poop" while nature calls (its
# bar is the time she can hold it), "mood" while a mood lasts.
func extra_rows() -> Array[String]:
	var out: Array[String] = []
	if main == null:
		return out
	if int(main.poop_state) in [1, 3, 4]:
		out.append("poop")
	if main.mood != null and String(main.mood.badge()) != "":
		out.append("mood")
	return out


func card_h() -> float:
	return CARD_H + ROW_H * float(extra_rows().size())


func _label(text: String, x: float, row: float, col := LABEL_COL) -> void:
	_b.draw_string(Kit.display(), Vector2(x, row + 11.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_PX, col)


# a horizontal meter from BAR_X to the card's right padding
func _bar(row: float, frac: float, col: Color) -> void:
	var r := Rect2(BAR_X, row + 3.0, CARD_W - PAD - BAR_X, BAR_H)
	_b.draw_rect(r, Color(0.04, 0.05, 0.06, 0.70))
	var w := r.size.x * clampf(frac, 0.0, 1.0)
	if w > 1.0:
		_b.draw_rect(Rect2(r.position, Vector2(w, r.size.y)), col)
		# a sheen along the top third, so the fill reads as liquid, not paint
		_b.draw_rect(Rect2(r.position, Vector2(w, 2.0)), Color(1, 1, 1, 0.22))
	_b.draw_rect(r, Color(1, 1, 1, 0.30), false, 1.0)


func _draw_shapes() -> void:
	var h := card_h()
	_b.draw_style_box(sb, Rect2(0, 0, CARD_W, h))
	var t := AnimClock.msec()

	# the phone's three lives, and what they are
	for i in range(3):
		var on: bool = i < main.phone_hp
		Icons.draw_phone_pip(_b, Vector2(PAD + i * 15, ROW_PHONE), 20.0, on)
	var phone_col := LABEL_COL if main.phone_hp > 1 else Color(1.0, 0.52, 0.42)
	_label("PHONE", 58.0, ROW_PHONE + 4.0, phone_col)

	# the bones banked, right-aligned to the card's padding
	var bones_s := str(main.bones)
	var bw := Kit.text_w(Kit.display(), bones_s, 18)
	_b.draw_string(Kit.display(), Vector2(CARD_W - PAD - bw, ROW_PHONE + 18.0), bones_s,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.95, 0.94, 0.90))
	Icons.draw_bone(_b, Vector2(CARD_W - PAD - bw - 14.0, ROW_PHONE + 11.0), 11.0, Color(0.93, 0.90, 0.83))

	# her pee (yellow): full, the bar pulses (the banner says what to do)
	var full: bool = main.pee >= 0.999
	var tcol := TANK_COL
	if full and fmod(t / 350.0, 2.0) < 1.0:
		tcol = Color(1.0, 0.94, 0.45)
	Icons.draw_droplet(_b, Vector2(PAD + 7.0, ROW_TANK + 7.5), 13.0, TANK_COL)
	_label("PEE", LABEL_X, ROW_TANK)
	_bar(ROW_TANK, main.pee, tcol)

	# the zoomies (green), gold while a golden bone lasts
	var ecol := ZOOM_COL
	if float(main.golden_t) > 0.0:
		ecol = Color(1.0, 0.80, 0.30).lerp(Color(1.0, 0.95, 0.60), 0.5 + 0.5 * sin(t / 90.0))
	elif main.dog.turbo_active and fmod(t / 120.0, 2.0) < 1.0:
		ecol = Color(0.65, 1.0, 0.75)
	Icons.draw_bolt(_b, Vector2(PAD + 7.0, ROW_ZOOM + 7.5), 13.0, ecol)
	_label("ZOOMIES", LABEL_X, ROW_ZOOM)
	_bar(ROW_ZOOM, main.dog.energy, ecol)

	# the spots her pee has marked, five drops in the pee's yellow filling in
	# under its bar; the drop glyph at the label column is hollow, a spot
	var made: int = mini(main.marks.size(), 5)
	_label("MARKED", LABEL_X, ROW_MARKS)
	for i in range(5):
		var p := Vector2(BAR_X + 6.0 + i * 16.0, ROW_MARKS + 8.0)
		if i < made:
			Icons.draw_droplet(_b, p, 11.0, TANK_COL)
		else:
			Icons.draw_droplet(_b, p, 11.0, Color(1, 1, 1, 0.22))
	_b.draw_arc(Vector2(PAD + 7.0, ROW_MARKS + 8.0), 4.5, 0, TAU, 14, TANK_COL, 1.4)

	# the streak, on the marked row's free end
	if main.streak > 1:
		var st := "x%d STREAK" % main.streak
		var sw := Kit.text_w(Kit.display(), st, 10) + 10.0
		var sr := Rect2(CARD_W - PAD - sw, ROW_MARKS, sw, 15.0)
		_b.draw_rect(sr, Color(0.18, 0.50, 0.32, 0.55))
		_b.draw_rect(sr, Color(0.40, 0.85, 0.55, 0.75), false, 1.0)
		_b.draw_string(Kit.display(), Vector2(sr.position.x + 5.0, sr.position.y + 11.0), st,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.80, 1.0, 0.84))

	# the meter a lesson is about, outlined and pulsing while it is up; the
	# phone's pips while THAT'S THE BASICS names them
	var point := "phone" if String(main.confirm_id) == "basics" else String(main.hud_point)
	if POINT_RECTS.has(point):
		var a := 0.55 + 0.45 * sin(t / 160.0)
		_b.draw_rect(POINT_RECTS[point], Color(0.98, 0.80, 0.38, a), false, 2.5)

	var extra := extra_rows()
	for i in range(extra.size()):
		var row := ROW_EXTRA + ROW_H * float(i)
		match extra[i]:
			"poop":
				# nature calls: the bar is the time left to choose a spot. The
				# last ten seconds, and the warning after them, pulse red.
				var left: float = float(main.urge_timer) / float(main.POOP_URGE_S) if int(main.poop_state) == 1 else 0.0
				var pcol := POOP_COL
				if left < 10.0 / float(main.POOP_URGE_S) and fmod(t / 250.0, 2.0) < 1.0:
					pcol = Color(1.0, 0.45, 0.35)
				var c := Vector2(PAD + 7.0, row + 9.0)
				_b.draw_circle(c + Vector2(0.0, 2.0), 5.0, POOP_COL.darkened(0.2))
				_b.draw_circle(c + Vector2(0.0, -1.5), 3.8, POOP_COL)
				_b.draw_circle(c + Vector2(0.5, -4.5), 2.4, POOP_COL.lightened(0.12))
				_label("POOP", LABEL_X, row, pcol)
				_bar(row, left, pcol)
			"mood":
				# a mood you cannot cancel has to be a mood you can see going
				var badge: String = main.mood.badge()
				var mi: float = clampf(main.mood.intensity, 0.0, 1.0)
				var tint: Color = main.mood.tint()
				_b.draw_circle(Vector2(PAD + 7.0, row + 8.0), 4.5, tint)
				_label(badge, LABEL_X, row, Color(tint.r, tint.g, tint.b, 0.65 + 0.35 * mi))
				_bar(row, mi, Color(tint.r, tint.g, tint.b, 0.85))
