extends Control

# Title-screen ambience: a tiny Millie trots endlessly across the bottom
# of the screen towing a tiny phone-absorbed owner. Hidden once the real
# walk begins.

var t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _process(delta: float) -> void:
	if not visible:
		return
	t += delta
	queue_redraw()


func _draw() -> void:
	var mx := fposmod(t * 95.0, 1560.0) - 140.0
	var base := Vector2(mx, 596.0)
	var fur := Color(0.14, 0.13, 0.14)
	var gait := sin(t * 10.0)
	# the owner, towed, phone first
	var op := base + Vector2(-96, -6)
	draw_circle(op + Vector2(-4, 16 + gait * 2.0), 4.0, Color(0.25, 0.27, 0.32))
	draw_circle(op + Vector2(4, 16 - gait * 2.0), 4.0, Color(0.25, 0.27, 0.32))
	draw_circle(op, 12.0, Color(0.35, 0.42, 0.55))
	draw_circle(op + Vector2(6, -10), 6.5, Color(0.85, 0.72, 0.58))
	draw_rect(Rect2(op.x + 16, op.y - 20, 6, 10), Color(0.15, 0.17, 0.2))
	draw_rect(Rect2(op.x + 17, op.y - 19, 4, 7), Color(0.7, 0.85, 1.0, 0.8))
	# the leash, sagging honestly
	var a := op + Vector2(12, -4)
	var b := base + Vector2(-16, -4)
	var midp := (a + b) / 2.0 + Vector2(0, 9.0 + sin(t * 3.0) * 2.5)
	var pts_l := PackedVector2Array()
	for i in range(9):
		var u := i / 8.0
		pts_l.append(a.lerp(midp, u).lerp(midp.lerp(b, u), u))
	draw_polyline(pts_l, Color(0.72, 0.28, 0.24), 2.5)
	# Millie, at speed, wiggling
	var hip := base + Vector2(-9, gait * 1.6)
	var head := base + Vector2(12, -3)
	draw_line(hip + hip.direction_to(base) * 2.0, base + Vector2(6, 0), fur, 8.0)
	draw_circle(hip, 6.0, fur)
	draw_circle(base + Vector2(6, 0), 5.5, fur)
	draw_line(hip, hip + Vector2(-9, -4 + gait * 2.0), Color(0.08, 0.08, 0.09), 3.0)
	draw_circle(head, 4.5, fur)
	draw_line(head, head + Vector2(7, 1), fur, 3.5)
	draw_circle(head + Vector2(8, 1), 1.6, Color(0.05, 0.05, 0.06))
	draw_line(head + Vector2(-1, -3), head + Vector2(-4, -8), Color(0.08, 0.08, 0.09), 3.0)
	draw_rect(Rect2(base.x - 2, base.y - 7, 9, 5), Color(0.72, 0.16, 0.14))
	draw_circle(base + Vector2(9, 8 + gait * 2.5), 2.2, Color(0.78, 0.76, 0.73))
	draw_circle(base + Vector2(1, 8 - gait * 2.5), 2.2, Color(0.78, 0.76, 0.73))
	draw_circle(hip + Vector2(-2, 8 - gait * 2.0), 2.2, Color(0.78, 0.76, 0.73))
	draw_circle(hip + Vector2(-8, 8 + gait * 2.0), 2.2, Color(0.78, 0.76, 0.73))
