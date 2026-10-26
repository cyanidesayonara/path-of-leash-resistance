extends Node2D

# The ground she FEELS, laid over the ground that is drawn: a dot every STEP px
# coloured by main.surface_at(), over whatever the camera sees. Added by
# `--shot --surface-map` (tools/surface_map.sh), so a drawn surface that
# handles as something else shows at a glance. With `dump` it draws nothing
# and prints one `SURF screen_x screen_y surface` line per point on the frame
# the shot is taken, for tools/surface_check.py to hold against the clean
# picture. Tooling only.

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
var dump := false
var _printed := false


func _process(_delta: float) -> void:
	if dump:
		if not _printed and int(m._shot_frames) >= int(m._shot_at):
			_printed = true
			_print_points()
		return
	queue_redraw()


func _points() -> Array:
	var cam: Camera2D = m.cam
	var half := get_viewport_rect().size * 0.5 / cam.zoom
	var c := cam.get_screen_center_position()
	var out := []
	var x := floorf((c.x - half.x) / STEP) * STEP
	while x < c.x + half.x:
		var y := floorf((c.y - half.y) / STEP) * STEP
		while y < c.y + half.y:
			out.append(Vector2(x, y))
			y += STEP
		x += STEP
	return out


func _print_points() -> void:
	var cam: Camera2D = m.cam
	var c := cam.get_screen_center_position()
	var vs := get_viewport_rect().size
	var lines := PackedStringArray()
	for p: Vector2 in _points():
		var sp: Vector2 = (p - c) * cam.zoom + vs * 0.5
		lines.append("SURF %d %d %d" % [roundi(sp.x), roundi(sp.y), int(m.surface_at(p))])
	print("\n".join(lines))


func _draw() -> void:
	if m == null or dump:
		return
	for p: Vector2 in _points():
		draw_circle(p, 4.5, Color(0, 0, 0, 0.7))
		draw_circle(p, 3.2, COLS.get(int(m.surface_at(p)), Color.WHITE))
