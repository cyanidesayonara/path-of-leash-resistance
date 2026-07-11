extends Control

# HUD widget: a vertical test tube of yellowish liquid. main.gd sets
# `level` (0..1); flashes when full.

var level := 1.0
var flash := 0.0


func _process(delta: float) -> void:
	flash += delta
	queue_redraw()


func _draw() -> void:
	var w := 16.0
	var h := 84.0
	draw_rect(Rect2(0, 0, w, h), Color(1, 1, 1, 0.1))
	var lh := h * clampf(level, 0.0, 1.0)
	var col := Color(0.93, 0.83, 0.25, 0.85)
	if level >= 0.999 and fmod(flash, 0.8) < 0.4:
		col = Color(1.0, 0.92, 0.35, 1.0)
	if lh > 3.0:
		draw_rect(Rect2(1.5, h - lh + 1.5, w - 3.0, lh - 3.0), col)
	draw_rect(Rect2(0, 0, w, h), Color(1, 1, 1, 0.5), false, 2.0)
	for i in range(1, 4):
		var y := h * i / 4.0
		draw_line(Vector2(w - 5, y), Vector2(w, y), Color(1, 1, 1, 0.4), 1.0)
