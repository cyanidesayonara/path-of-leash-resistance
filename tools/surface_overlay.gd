extends Node2D

# The ground she FEELS, laid over the ground that is drawn: a dot every STEP px
# coloured by main.surface_at(), over whatever the camera sees. Added by
# `--shot --surface-map` (tools/surface_map.sh), so a drawn surface that
# handles as something else shows at a glance. Tooling only.

const Surfaces := preload("res://world/surfaces.gd")
const STEP := 24.0
const COLS := {
	Surfaces.S.PAVEMENT: Color(0.55, 0.55, 0.58),
	Surfaces.S.GRASS: Color(0.10, 0.80, 0.20),
	Surfaces.S.SAND: Color(1.00, 0.85, 0.10),
	Surfaces.S.MUD: Color(0.50, 0.25, 0.05),
	Surfaces.S.WATER: Color(0.10, 0.40, 1.00),
	Surfaces.S.TILE: Color(1.00, 0.10, 0.90),
}

var m: Node2D


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if m == null:
		return
	var cam: Camera2D = m.cam
	var half := get_viewport_rect().size * 0.5 / cam.zoom
	var c := cam.get_screen_center_position()
	var x := floorf((c.x - half.x) / STEP) * STEP
	while x < c.x + half.x:
		var y := floorf((c.y - half.y) / STEP) * STEP
		while y < c.y + half.y:
			var s: int = m.surface_at(Vector2(x, y))
			draw_circle(Vector2(x, y), 4.5, Color(0, 0, 0, 0.7))
			draw_circle(Vector2(x, y), 3.2, COLS.get(s, Color.WHITE))
			y += STEP
		x += STEP
