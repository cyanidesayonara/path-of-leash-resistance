extends Control

# The whole left-side HUD as one quiet card: phone pips, bones, the
# tube, mark dots, and a status line. The world is chaotic on purpose;
# the overlay is not.

var main: Node2D
var sb: StyleBoxFlat


func setup(m: Node2D) -> void:
	main = m


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.09, 0.1, 0.32)
	sb.set_corner_radius_all(10)


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()


func _draw() -> void:
	var f := ThemeDB.fallback_font
	draw_style_box(sb, Rect2(0, 0, 196, 92))
	# phone pips: the phone's three lives
	for i in range(3):
		var r := Rect2(14 + i * 21, 12, 14, 24)
		draw_rect(r, Color(0.16, 0.18, 0.22))
		var on: bool = i < main.phone_hp
		draw_rect(r.grow(-2.5), Color(0.7, 0.85, 1.0, 0.9) if on else Color(0.3, 0.32, 0.36))
	# the bone count
	var bx := Vector2(104, 24)
	draw_line(bx + Vector2(-7, 0), bx + Vector2(7, 0), Color(0.92, 0.9, 0.84), 4.0)
	for c in [Vector2(-8, -3), Vector2(-8, 3), Vector2(8, -3), Vector2(8, 3)]:
		draw_circle(bx + c, 3.0, Color(0.92, 0.9, 0.84))
	draw_string(f, Vector2(120, 31), str(main.bones), HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color(0.95, 0.94, 0.9))
	if main.streak > 1:
		draw_string(f, Vector2(120, 48), "streak x%d" % main.streak, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.7, 1.0, 0.75))
	# the tube
	var tr := Rect2(16, 44, 12, 38)
	draw_rect(tr, Color(1, 1, 1, 0.12))
	var lh: float = 34.0 * clampf(main.pee, 0.0, 1.0)
	if lh > 2.0:
		var col := Color(0.93, 0.83, 0.25, 0.9)
		if main.pee >= 0.999 and fmod(Time.get_ticks_msec() / 400.0, 2.0) < 1.0:
			col = Color(1.0, 0.92, 0.35)
		draw_rect(Rect2(17, 46 + 34.0 - lh, 10, lh), col)
	draw_rect(tr, Color(1, 1, 1, 0.5), false, 1.5)
	# mark dots: territory progress
	for i in range(5):
		var p := Vector2(52 + i * 17, 64)
		if i < mini(main.marks.size(), 5):
			draw_circle(p, 5.0, Color(0.95, 0.88, 0.5, 0.9))
		draw_arc(p, 5.0, 0, TAU, 12, Color(1, 1, 1, 0.4), 1.2)
	# status line, gently pulsing beneath the card
	var status: String = main.hud_status
	if status != "":
		var a := 0.75 + 0.25 * sin(Time.get_ticks_msec() / 220.0)
		draw_string(f, Vector2(4, 114), status, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(1, 0.92, 0.7, a))
