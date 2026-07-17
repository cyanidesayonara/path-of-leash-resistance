extends Node2D

# The devourer for the chase legs (homage to Crash Bandicoot's boulder
# runs and, ultimately, Indiana Jones). A street sweeper grinds south
# down the corridor, eating the path behind it. It is SLOWER than a
# hustling, pulling dog but FASTER than the owner's phone-zombie dawdle -
# so it never scares the oblivious owner, and it is on YOU to drag the
# dead weight south ahead of the brushes. Stop to sniff around and the
# gap closes. Its leading (south) edge is the kill line.

var main: Node2D
var speed := 140.0
var front_y := 0.0  # the leading (south) edge in world space - the kill line
var cx := 640.0
var half := 520.0
var rumble := 0.0
var kind := "sweeper"  # "sweeper" (slow) or "bolt" (fast) - changes the look


func setup(m: Node2D, start_front_y: float, corridor_cx: float, corridor_half: float, sweeper_speed: float) -> void:
	main = m
	front_y = start_front_y
	cx = corridor_cx
	half = corridor_half
	speed = sweeper_speed


func advance(delta: float) -> void:
	front_y += speed * delta
	rumble += delta


func caught(p: Vector2) -> bool:
	# a body is swept once the leading edge has reached it (it is now
	# north of / inside the brushes)
	return p.y <= front_y


func gap_to(p: Vector2) -> float:
	# how much runway is left before this body is caught (negative = gone)
	return p.y - front_y


func _draw() -> void:
	# everything north of the kill line is chewed-up road; the machine
	# sits astride the line with its brushes on the seam
	var chewed := Color(0.12, 0.12, 0.14, 0.9)
	draw_rect(Rect2(-half, -1600.0, half * 2.0, 1600.0), chewed)
	# grit and swirl marks in the wake
	for i in range(9):
		var gx := -half + fmod(i * 137.0 + rumble * 40.0, half * 2.0)
		var gy := -40.0 - fmod(i * 90.0 + rumble * 30.0, 300.0)
		draw_circle(Vector2(gx, gy), 3.0, Color(0.25, 0.24, 0.2, 0.6))
	# the body spanning the road: an orange sweeper, or a red bruiser of a
	# truck for the fast "bolt" chase
	var body := Color(0.7, 0.14, 0.12) if kind == "bolt" else Color(0.86, 0.52, 0.12)
	var trim := Color(0.95, 0.3, 0.25) if kind == "bolt" else Color(1, 0.72, 0.2)
	draw_rect(Rect2(-half + 40.0, -8.0, half * 2.0 - 80.0, 118.0), body)
	draw_rect(Rect2(-half + 40.0, -8.0, half * 2.0 - 80.0, 20.0), trim)
	# cab
	draw_rect(Rect2(-70.0, 20.0, 140.0, 72.0), Color(0.72, 0.42, 0.1))
	draw_rect(Rect2(-50.0, 34.0, 100.0, 30.0), Color(0.6, 0.75, 0.85, 0.85))
	# the two spinning brushes right on the kill line
	var spin := rumble * 9.0
	for sx in [-half * 0.55, half * 0.55]:
		draw_circle(Vector2(sx, 0.0), 46.0, Color(0.3, 0.3, 0.32))
		for b in range(10):
			var a := spin + b * TAU / 10.0
			draw_line(Vector2(sx, 0.0), Vector2(sx, 0.0) + Vector2.from_angle(a) * 46.0, Color(0.85, 0.8, 0.4), 3.0)
	# a hazard beacon
	draw_circle(Vector2(0.0, 14.0), 7.0, Color(1.0, 0.85, 0.2) if fmod(rumble, 0.6) < 0.3 else Color(0.7, 0.5, 0.1))
