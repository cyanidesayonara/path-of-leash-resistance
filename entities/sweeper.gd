extends Node2D

# The devourer for the chase legs (homage to Crash Bandicoot's boulder
# runs and, ultimately, Indiana Jones). A street sweeper grinds south
# down the corridor, eating the path behind it. It is SLOWER than a
# hustling, pulling dog but FASTER than the owner's phone-zombie dawdle -
# so it never scares the oblivious owner, and it is on YOU to drag the
# dead weight south ahead of the brushes. Stop to sniff around and the
# gap closes. Its leading (south) edge is the kill line.
#
# DRAWING IT AS A MACHINE. The kill line has to span the whole corridor or
# the chase would just be a dodge, but a road-wide slab of rectangles reads
# as a wall rather than as something driving at you - which is exactly what
# the first version looked like. The fix is how real road plant is actually
# built: a WIDE plated brush head, spanning the carriageway, hung off a
# NARROWER machine with a cab. One vehicle, wide at the business end, and
# the eye reads the cab as the thing that is chasing it.
#
# Everything here obeys the one light (main.LIGHT), like every other object
# in the game: the machine throws a real shadow south-east, ahead of itself
# and toward the player, which is most of what sells it as a solid object
# with height rather than a decal sliding down the road.
#
# Local space: the kill line is y = 0 and the machine sits at NEGATIVE y
# (north, behind the line). It advances by moving its own origin south.

# the machine proper, either side of the centre line. The brush head is
# wider - it reaches out to the kerbs on both sides.
const BODY_HALF := 138.0
const CAB_HALF := 104.0

var main: Node2D
var speed := 140.0
var front_y := 0.0  # the leading (south) edge in world space - the kill line
var cx := 640.0
var half := 520.0
var rumble := 0.0
var kind := "sweeper"  # "sweeper" (slow), "bolt" (fast), "both" (emergency)


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


func _palette() -> Dictionary:
	# municipal orange by default; the fast variant is a red truck and the
	# "both" emergency is a fire engine
	match kind:
		"bolt":
			return {
				"body": Color(0.68, 0.13, 0.11), "lit": Color(0.84, 0.24, 0.18),
				"dark": Color(0.42, 0.07, 0.06), "trim": Color(0.93, 0.90, 0.86),
			}
		"both":
			return {
				"body": Color(0.72, 0.09, 0.07), "lit": Color(0.90, 0.20, 0.14),
				"dark": Color(0.44, 0.05, 0.05), "trim": Color(0.95, 0.93, 0.90),
			}
		_:
			return {
				"body": Color(0.86, 0.47, 0.09), "lit": Color(0.98, 0.63, 0.18),
				"dark": Color(0.52, 0.26, 0.05), "trim": Color(0.95, 0.86, 0.62),
			}


func _draw() -> void:
	var full := half * 2.0
	var pal := _palette()
	var steel := Color(0.21, 0.22, 0.25)
	var steel_lit := Color(0.34, 0.35, 0.39)

	# --- the road it has already been over --------------------------------
	# ground-up and oil-dark, and deliberately featureless: the eye should
	# read it as "no longer a place you can be", not as more pavement
	draw_rect(Rect2(-half, -1600.0, full, 1600.0), Color(0.09, 0.09, 0.11, 0.95))
	# freshly scoured strip right behind the head, still wet
	draw_rect(Rect2(-half, -74.0, full, 74.0), Color(0.15, 0.15, 0.17, 0.92))
	# swirl marks drifting back up the wake
	for i in range(16):
		var gx := -half + fmod(float(i) * 137.0 + rumble * 40.0, full)
		var gy := -70.0 - fmod(float(i) * 90.0 + rumble * 30.0, 430.0)
		draw_circle(Vector2(gx, gy), 3.0, Color(0.32, 0.30, 0.25, 0.30))

	# --- the shadow -------------------------------------------------------
	# thrown ahead of the machine and toward the player, which is what makes
	# it read as a tall solid object bearing down rather than a flat sprite
	if main != null:
		main.cast_shadow(self, Vector2(0.0, -70.0), BODY_HALF, 92.0, 0.30)

	# --- the wide brush head, spanning the carriageway --------------------
	# a heavy steel beam on the kill line itself, so what kills you is
	# visibly the thing doing the sweeping
	draw_rect(Rect2(-half, -46.0, full, 46.0), steel)
	draw_rect(Rect2(-half, -46.0, full, 7.0), steel_lit)   # top edge catches light
	# hazard chevrons across the blade: the universal "do not be here"
	var stripe := 34.0
	var n := int(full / stripe) + 2
	for i in range(n):
		var x0 := -half + float(i) * stripe
		if i % 2 == 0:
			continue
		draw_colored_polygon(
			PackedVector2Array([
				Vector2(x0, -39.0), Vector2(x0 + stripe * 0.5, -39.0),
				Vector2(x0 + stripe * 0.5 - 14.0, -8.0), Vector2(x0 - 14.0, -8.0),
			]), Color(0.96, 0.78, 0.12))
	# the lower lip, in shadow
	draw_rect(Rect2(-half, -10.0, full, 10.0), Color(0.12, 0.12, 0.14))

	# --- the two brushes, right on the kill line --------------------------
	var spin := rumble * 9.0
	for sx: float in [-half * 0.62, half * 0.62]:
		var at := Vector2(sx, -4.0)
		draw_circle(at, 50.0, Color(0.16, 0.16, 0.18))
		for b in range(14):
			var a := spin + float(b) * TAU / 14.0
			draw_line(at, at + Vector2.from_angle(a) * 50.0, Color(0.80, 0.72, 0.34), 3.5)
		draw_circle(at, 15.0, Color(0.30, 0.31, 0.34))
		draw_circle(at + Vector2(-4.0, -4.0), 8.0, Color(0.44, 0.45, 0.48))
	# grit thrown out sideways by the brushes
	for i in range(12):
		var ph := fmod(rumble * 2.2 + float(i) * 0.37, 1.0)
		var side: float = -1.0 if i % 2 == 0 else 1.0
		var gx2: float = side * (half * 0.62 + ph * 120.0)
		var gy2: float = -6.0 - sin(ph * PI) * 34.0
		draw_circle(Vector2(gx2, gy2), 2.6 * (1.0 - ph), Color(0.72, 0.66, 0.48, 0.7 * (1.0 - ph)))

	# --- the machine body -------------------------------------------------
	# sides first, so the lit top plate sits proud of them
	draw_rect(Rect2(-BODY_HALF, -186.0, BODY_HALF * 2.0, 146.0), pal.dark)
	draw_rect(Rect2(-BODY_HALF + 9.0, -186.0, BODY_HALF * 2.0 - 18.0, 138.0), pal.body)
	# the hopper's lit upper-left face, following the one light
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-BODY_HALF + 9.0, -186.0), Vector2(BODY_HALF - 9.0, -186.0),
			Vector2(BODY_HALF - 26.0, -170.0), Vector2(-BODY_HALF + 26.0, -170.0),
		]), pal.lit)
	# panel seams, so a big flat flank is not one dead colour
	for sy: float in [-160.0, -128.0, -96.0]:
		draw_line(Vector2(-BODY_HALF + 12.0, sy), Vector2(BODY_HALF - 12.0, sy),
			Color(0, 0, 0, 0.18), 2.0)
	# the intake maw under the hopper: a dark slot that is doing the eating
	draw_rect(Rect2(-BODY_HALF + 30.0, -60.0, BODY_HALF * 2.0 - 60.0, 22.0), Color(0.06, 0.06, 0.07))
	for i in range(9):
		var tx := -BODY_HALF + 40.0 + float(i) * (BODY_HALF * 2.0 - 80.0) / 8.0
		draw_line(Vector2(tx, -58.0), Vector2(tx, -40.0), Color(0.30, 0.30, 0.33), 2.5)

	# --- wheels -----------------------------------------------------------
	for wy: float in [-166.0, -74.0]:
		for wx: float in [-BODY_HALF - 6.0, BODY_HALF - 16.0]:
			draw_rect(Rect2(wx, wy, 22.0, 40.0), Color(0.10, 0.10, 0.12))
			draw_rect(Rect2(wx + 4.0, wy + 6.0, 14.0, 28.0), Color(0.22, 0.22, 0.25))

	# --- the cab ----------------------------------------------------------
	draw_rect(Rect2(-CAB_HALF, -272.0, CAB_HALF * 2.0, 92.0), pal.dark)
	draw_rect(Rect2(-CAB_HALF + 7.0, -272.0, CAB_HALF * 2.0 - 14.0, 84.0), pal.body)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-CAB_HALF + 7.0, -272.0), Vector2(CAB_HALF - 7.0, -272.0),
			Vector2(CAB_HALF - 20.0, -258.0), Vector2(-CAB_HALF + 20.0, -258.0),
		]), pal.lit)
	# Windscreen, at the SOUTH end of the cab: this thing drives south, so the
	# glass and the driver behind it face down the road at you. Putting it at
	# the north end made the machine look like it was reversing after you.
	draw_rect(Rect2(-CAB_HALF + 18.0, -212.0, CAB_HALF * 2.0 - 36.0, 30.0), Color(0.12, 0.16, 0.20))
	# the top edge catches the light, like every other upright here
	draw_rect(Rect2(-CAB_HALF + 18.0, -212.0, CAB_HALF * 2.0 - 36.0, 10.0), Color(0.42, 0.54, 0.62, 0.75))
	# a wiper, because it is the small wrong-looking details that give a
	# drawn object away as a box with a window painted on it
	draw_line(Vector2(-24.0, -184.0), Vector2(6.0, -200.0), Color(0.10, 0.10, 0.12), 2.5)
	# wing mirrors, out where a driver would actually need them
	for mx: float in [-CAB_HALF - 12.0, CAB_HALF - 2.0]:
		draw_rect(Rect2(mx, -214.0, 14.0, 9.0), Color(0.14, 0.14, 0.16))
	# exhaust stack, with the heat coming off it
	draw_rect(Rect2(CAB_HALF - 34.0, -292.0, 13.0, 26.0), Color(0.26, 0.26, 0.29))
	for i in range(3):
		var pf := fmod(rumble * 0.8 + float(i) * 0.33, 1.0)
		draw_circle(Vector2(CAB_HALF - 27.0, -294.0 - pf * 40.0), 5.0 + pf * 9.0,
			Color(0.42, 0.42, 0.44, 0.26 * (1.0 - pf)))

	# --- beacons ----------------------------------------------------------
	# amber strobes on the cab roof for the sweeper, blue-and-red for the
	# emergency variant. They alternate, which reads as urgency at a glance
	var on := fmod(rumble, 0.5) < 0.25
	if kind == "both":
		draw_circle(Vector2(-46.0, -282.0), 8.0,
			Color(1.0, 0.24, 0.20) if on else Color(0.34, 0.08, 0.07))
		draw_circle(Vector2(46.0, -282.0), 8.0,
			Color(0.32, 0.46, 1.0) if not on else Color(0.09, 0.13, 0.34))
	else:
		for bx: float in [-46.0, 46.0]:
			var lit: bool = on if bx < 0.0 else not on
			draw_circle(Vector2(bx, -282.0), 8.0,
				Color(1.0, 0.78, 0.16) if lit else Color(0.38, 0.28, 0.06))
			if lit:
				draw_circle(Vector2(bx, -282.0), 16.0, Color(1.0, 0.80, 0.25, 0.18))
	# A wash of beacon light on the road it is about to take. Full corridor
	# width and faded in bands rather than one polygon: the first version was
	# a trapezoid from the cab to the kerbs, and its two straight edges read
	# as hard triangular wedges lying on the road instead of as light.
	var glow: float = 0.055 + 0.025 * sin(rumble * 6.0)
	for i in range(5):
		var f := float(i) / 4.0
		draw_rect(Rect2(-half, -6.0 + f * 46.0, full, 12.0),
			Color(1.0, 0.80, 0.30, glow * (1.0 - f)))
