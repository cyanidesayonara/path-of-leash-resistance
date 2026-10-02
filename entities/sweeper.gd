extends Node2D

# The devourer for the chase legs (homage to Crash Bandicoot's boulder
# runs and, ultimately, Indiana Jones). A street sweeper careens south
# down the corridor, eating the path behind it. On average it is SLOWER
# than a hustling, pulling dog but FASTER than the owner's phone-zombie
# dawdle - so it never scares the oblivious owner, and it is on YOU to drag
# the dead weight south ahead of the brushes. Stop to sniff around and the
# gap closes. Its leading (south) edge is the kill line.
#
# THE BOULDER. It lurches rather than cruising (SURGE, which averages out
# to the base speed), and once it has dropped far enough back to leave the
# screen it guns it (CATCH_UP) until it looms at the top edge again: the
# threat is something you watch bearing down, not a rumble behind the
# camera. It only ever goes faster than its lurch for being FAR away.
#
# THE RESPITES. Where the level marks one (jams), a broom snags a dumpster
# at the kerb and the machine stalls for JAM_SECS - the breather the Crash
# runs are built around, and the one safe moment to stop for dog business.
#
# DRAWING IT AS A MACHINE. A normal compact road sweeper: the cab at the
# front, the hopper behind, and a gutter broom on a swing arm at each front
# corner. The kill line still spans the whole corridor (otherwise the chase
# is a dodge, not a run), so the brooms out at the kerbs and the spray
# between them are what visibly sweeps it. The body careens about inside
# the street and the arms reach to keep the brooms on the kerbs.
#
# Everything here obeys the one light (main.LIGHT), like every other object
# in the game: the machine throws a real shadow south-east, ahead of itself
# and toward the player.
#
# Local space: the kill line is y = 0 and the machine sits at NEGATIVE y
# (north, behind the line). It advances by moving its own origin south.
# The body is drawn in its own frame, centred, with +y its nose, and turned
# by the heading it is swerving at.

const BODY_HALF := 80.0
const CAB_HALF := 72.0
const BODY_HALF_LEN := 128.0
# where the body's centre sits behind the kill line
const BODY_Y := -176.0
const BROOM_R := 34.0
const BROOM_Y := -30.0
# furthest a broom's arm reaches out past the side of the body, and how
# gradually it swings in round something parked at the kerb
const ARM_REACH := 160.0
const BLOCK_EASE := 40.0
# careening: a spring toward a wobbling target that leans at the dog
const SWERVE_K := 6.0
const SWERVE_DAMP := 3.0
const SWERVE_TRACK := 0.5
# the most the body turns off straight while it swerves (radians)
const HEADING_MAX := 0.26
# lurching, either side of the base speed
const SURGE := 0.22
# gunning it once it is this far behind the pair, up to CATCH_UP faster
# over CATCH_UP_RAMP more
const CATCH_UP_GAP := 420.0
const CATCH_UP_RAMP := 300.0
const CATCH_UP := 0.8
# a broom snagging a dumpster
const JAM_SECS := 2.2
# loose junk the brooms reach is flung down the street, this far
const FLING_MIN := 240.0
const FLING_MAX := 420.0

var main: Node2D
var speed := 140.0  # the base speed; cur_speed is this lurching
var cur_speed := 140.0
var front_y := 0.0  # the leading (south) edge in world space - the kill line
var cx := 640.0
var half := 520.0
var rumble := 0.0
var kind := "sweeper"  # "sweeper" (slow), "bolt" (fast), "both" (emergency)
var sway := 0.0  # the body's offset from the centre line
var sway_v := 0.0
var heading := 0.0
# world-space points where a broom snags: x says which kerb, y is where the
# kill line is when it does. Each one fires once.
var jams: Array[Vector2] = []
var jam_t := 0.0
var jam_side := 0.0
# world-space rects parked at the kerbs, which the brooms swing in round
# (except a dumpster still waiting to jam one)
var kerb_blocks: Array[Rect2] = []
# set for one tick when a jam starts or ends, for home_chase to announce
var jammed_now := false
var freed_now := false
# the machine's own dice, so flinging junk never moves the walk's seeded
# random sequence
var _rng := RandomNumberGenerator.new()


func setup(m: Node2D, start_front_y: float, corridor_cx: float, corridor_half: float, sweeper_speed: float) -> void:
	main = m
	front_y = start_front_y
	cx = corridor_cx
	half = corridor_half
	speed = sweeper_speed
	cur_speed = sweeper_speed
	_rng.seed = 0x5EE9


# gap: how far ahead the rearmost of the pair is (negative leaves it at its
# lurch). aim: the dog's offset from the centre line, which it swerves at.
func advance(delta: float, gap := -1.0, aim := 0.0) -> void:
	rumble += delta
	jammed_now = false
	freed_now = false
	if jam_t > 0.0:
		jam_t -= delta
		cur_speed = 0.0
		if jam_t <= 0.0:
			freed_now = true
		return
	var lurch := sin(rumble * 0.9) * 0.6 + sin(rumble * 2.3 + 1.0) * 0.4
	var mult := 1.0 + SURGE * lurch
	if gap >= 0.0:
		mult += CATCH_UP * clampf((gap - CATCH_UP_GAP) / CATCH_UP_RAMP, 0.0, 1.0)
	cur_speed = speed * mult
	front_y += cur_speed * delta
	_swerve(delta, aim)
	for i in range(jams.size()):
		if front_y >= jams[i].y:
			jam_side = signf(jams[i].x - cx)
			jams.remove_at(i)
			jam_t = JAM_SECS
			jammed_now = true
			break


func _swerve(delta: float, aim: float) -> void:
	var room := maxf(half - BODY_HALF - 14.0, 0.0)
	var wobble := sin(rumble * 1.3) * 0.7 + sin(rumble * 0.47 + 2.0) * 0.3
	var want := lerpf(wobble * room, clampf(aim, -room, room), SWERVE_TRACK)
	sway_v += ((want - sway) * SWERVE_K - sway_v * SWERVE_DAMP) * delta
	sway = clampf(sway + sway_v * delta, -room, room)
	heading = clampf(atan2(sway_v, maxf(cur_speed, 60.0)), -HEADING_MAX, HEADING_MAX)


func jammed() -> bool:
	return jam_t > 0.0


func caught(p: Vector2) -> bool:
	# a body is swept once the leading edge has reached it (it is now
	# north of / inside the brushes)
	return p.y <= front_y


func gap_to(p: Vector2) -> float:
	# how much runway is left before this body is caught (negative = gone)
	return p.y - front_y


# The brooms reach loose junk on the kill line: the first time, it is flung
# down the street toward the pair; anything that comes back under them is
# sucked into the hopper. Returns how many were flung.
func sweep_junk(junk: Array) -> int:
	var flung := 0
	for c in junk:
		if not is_instance_valid(c):
			continue
		var p: Vector2 = c.global_position
		if p.y > front_y + 6.0 or p.y < front_y - 70.0:
			continue
		if int(c.swept) > 0:
			c.queue_free()
			continue
		var k: Dictionary = c.KINDS[c.kind]
		var reach := _rng.randf_range(FLING_MIN, FLING_MAX)
		# the brooms sweep inward, toward the middle of the machine
		var across := clampf((p.x - (cx + sway)) / maxf(half, 1.0), -1.0, 1.0)
		var dir := Vector2(-across * 0.5 + _rng.randf_range(-0.2, 0.2), 1.0).normalized()
		c.vel = dir * sqrt(2.0 * float(k.drag) * reach)
		c.spin = _rng.randf_range(-12.0, 12.0)
		c.swept = 1
		c.flung_t = 1.4
		flung += 1
	return flung


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


# a rounded rectangle as one polygon, corners in three steps
static func _rr(r: Rect2, rad: float) -> PackedVector2Array:
	var cs := [Vector2(r.end.x - rad, r.position.y + rad), Vector2(r.end.x - rad, r.end.y - rad),
		Vector2(r.position.x + rad, r.end.y - rad), Vector2(r.position.x + rad, r.position.y + rad)]
	var pts := PackedVector2Array()
	for ci in range(4):
		for s in range(4):
			pts.append(cs[ci] + Vector2.from_angle(-PI * 0.5 + float(ci) * PI * 0.5 + float(s) * PI / 6.0) * rad)
	return pts


# a rectangle of size sz centred on c, turned by a
static func _box(c: Vector2, sz: Vector2, a: float) -> PackedVector2Array:
	var hx := Vector2.from_angle(a) * sz.x * 0.5
	var hy := Vector2.from_angle(a + PI * 0.5) * sz.y * 0.5
	return PackedVector2Array([c - hx - hy, c + hx - hy, c + hx + hy, c - hx + hy])


func _draw() -> void:
	var b := ShapeBatch.new(self)
	var full := half * 2.0
	var pal := _palette()
	var steel := Color(0.21, 0.22, 0.25)
	var steel_lit := Color(0.40, 0.41, 0.45)
	var stuck := jam_t > 0.0
	# it shudders against the dumpster while stuck, and idles otherwise
	var jig := Vector2(sin(rumble * 61.0), cos(rumble * 47.0)) * (3.0 if stuck else 0.8)
	var body_at := Vector2(sway, BODY_Y) + jig
	var body_xf := Transform2D(-heading, body_at)

	# --- the road it has already been over --------------------------------
	# ground-up and oil-dark, and deliberately featureless: the eye should
	# read it as "no longer a place you can be", not as more pavement
	b.draw_rect(Rect2(-half, -1600.0, full, 1600.0), Color(0.09, 0.09, 0.11, 0.95))
	# freshly scoured strip right behind the brooms, still wet
	b.draw_rect(Rect2(-half, -74.0, full, 74.0), Color(0.15, 0.16, 0.19, 0.92))
	# swirl marks drifting back up the wake
	for i in range(16):
		var gx := -half + fmod(float(i) * 137.0 + rumble * 40.0, full)
		var gy := -70.0 - fmod(float(i) * 90.0 + rumble * 30.0, 430.0)
		b.draw_circle(Vector2(gx, gy), 3.0, Color(0.32, 0.30, 0.25, 0.30))

	# --- the shadow -------------------------------------------------------
	# thrown ahead of the machine and toward the player, which is what makes
	# it read as a tall solid object bearing down rather than a flat sprite
	if main != null:
		main.cast_shadow(b, body_at + Vector2(0.0, 70.0), BODY_HALF, 80.0, 0.30)

	# --- the spray: the kill line made visible, kerb to kerb --------------
	# a real sweeper wets the road ahead of its brooms to lay the dust
	b.draw_rect(Rect2(-half, -16.0, full, 16.0), Color(0.72, 0.84, 0.95, 0.18))
	var n_mist := int(full / 16.0)
	for i in range(n_mist):
		var mx := -half + 8.0 + float(i) * 16.0
		var ph := fmod(rumble * 2.6 + float(i) * 0.37, 1.0)
		b.draw_circle(Vector2(mx, -4.0 - ph * 22.0), 2.0 + ph * 4.5, Color(0.93, 0.97, 1.0, 0.50 * (1.0 - ph)))

	# --- the broom arms and brooms, out at the kerbs ----------------------
	for s: float in [-1.0, 1.0]:
		var anchor: Vector2 = body_xf * Vector2(s * (CAB_HALF - 8.0), BODY_HALF_LEN - 22.0)
		# a snagged broom stays out where the dumpster stopped it, dead still
		var snagged := stuck and s == jam_side
		var bx := s * (half - BROOM_R - 4.0) if snagged else _broom_x(s)
		if absf(bx - anchor.x) > ARM_REACH:
			bx = anchor.x + s * ARM_REACH
		var broom := Vector2(bx, BROOM_Y)
		# painted like the machine, or against the dark of the wake it is lost
		var elbow := anchor.lerp(broom, 0.5) + Vector2(0.0, -18.0)
		b.draw_line(anchor, elbow, pal.dark, 12.0)
		b.draw_line(elbow, broom, pal.dark, 12.0)
		b.draw_line(anchor, elbow, pal.body, 7.0)
		b.draw_line(elbow, broom, pal.body, 7.0)
		b.draw_line(anchor + Vector2(-1.5, -2.0), elbow + Vector2(-1.5, -2.0), pal.lit, 2.0)
		b.draw_line(elbow + Vector2(-1.5, -2.0), broom + Vector2(-1.5, -2.0), pal.lit, 2.0)
		# the hydraulic ram that swings it
		b.draw_line(anchor + Vector2(0.0, -24.0), elbow, steel_lit, 4.0)
		b.draw_circle(anchor, 8.0, steel)
		b.draw_circle(elbow, 7.0, steel)
		b.draw_circle(elbow, 3.5, steel_lit)
		# the broom: a disc of bristles, spinning inward
		b.draw_circle(broom, BROOM_R, Color(0.16, 0.16, 0.18))
		var spin := 0.0 if snagged else -s * rumble * 9.0
		for bi in range(14):
			var a := spin + float(bi) * TAU / 14.0
			b.draw_line(broom, broom + Vector2.from_angle(a) * BROOM_R, Color(0.80, 0.72, 0.34), 3.0)
		b.draw_circle(broom, 11.0, Color(0.30, 0.31, 0.34))
		b.draw_circle(broom + Vector2(-3.0, -3.0), 6.0, Color(0.44, 0.45, 0.48))
		if snagged:
			# sparks off the dumpster it is grinding against, spraying back
			# and in off its end
			for i in range(8):
				var ph := fmod(rumble * 5.0 + float(i) * 0.31, 1.0)
				var sp := broom + Vector2(-s * ph * 40.0 + sin(float(i) * 2.1) * 14.0 * ph, BROOM_R - ph * 46.0)
				b.draw_circle(sp, 2.6 * (1.0 - ph), Color(1.0, 0.86, 0.36, 1.0 - ph))
		else:
			# grit thrown inward off the bristles
			for i in range(6):
				var ph := fmod(rumble * 2.2 + float(i) * 0.37 + (0.5 if s > 0.0 else 0.0), 1.0)
				var gp := broom + Vector2(-s * ph * 70.0, -sin(ph * PI) * 26.0)
				b.draw_circle(gp, 2.6 * (1.0 - ph), Color(0.72, 0.66, 0.48, 0.7 * (1.0 - ph)))

	# --- the machine body, in its own swerving frame ----------------------
	b.draw_set_transform(body_at, -heading)
	_draw_body(b, pal, stuck)
	b.draw_set_transform(Vector2.ZERO)

	# A wash of beacon light on the road it is about to take. Full corridor
	# width and faded in bands rather than one polygon: the first version was
	# a trapezoid from the cab to the kerbs, and its two straight edges read
	# as hard triangular wedges lying on the road instead of as light.
	var glow: float = 0.055 + 0.025 * sin(rumble * 6.0)
	for i in range(5):
		var f := float(i) / 4.0
		b.draw_rect(Rect2(-half, -6.0 + f * 46.0, full, 12.0),
			Color(1.0, 0.80, 0.30, glow * (1.0 - f)))
	b.flush()


# Where the broom on side s (-1 west, 1 east) sits across the street, in
# local x: out at the kerb, swung in round anything parked there. The swing
# ramps over BLOCK_EASE either side of the thing, so it reads as the arm
# pulling in as the machine comes up on it rather than a jump.
func _broom_x(s: float) -> float:
	var bx := s * (half - BROOM_R - 4.0)
	var off := Vector2(cx, front_y)
	for r: Rect2 in kerb_blocks:
		var lr := Rect2(r.position - off, r.size)
		if signf(lr.get_center().x) != s:
			continue
		if _waits_to_jam(r):
			continue
		var dy := maxf(maxf(lr.position.y - BROOM_Y, BROOM_Y - lr.end.y), 0.0)
		var f := 1.0 - clampf((dy - BROOM_R) / BLOCK_EASE, 0.0, 1.0)
		if f <= 0.0:
			continue
		var inner := (lr.position.x - BROOM_R - 4.0) if s > 0.0 else (lr.end.x + BROOM_R + 4.0)
		if (inner - bx) * s < 0.0:
			bx = lerpf(bx, inner, f)
	return bx


func _waits_to_jam(r: Rect2) -> bool:
	for j: Vector2 in jams:
		if j.x > r.position.x and j.x < r.end.x and absf(j.y - r.position.y) < 10.0:
			return true
	return false


# The body in its own frame: centred, nose (+y) south.
func _draw_body(b: ShapeBatch, pal: Dictionary, stuck: bool) -> void:
	var L := BODY_HALF_LEN
	var sheen: Color = pal.lit
	var steer := clampf(-heading * 1.8, -0.5, 0.5)

	# --- wheels, peeking out under the sides ------------------------------
	for w: Array in [[L - 58.0, steer], [-L + 42.0, 0.0]]:
		for s: float in [-1.0, 1.0]:
			var wc := Vector2(s * (BODY_HALF - 2.0), float(w[0]))
			b.draw_colored_polygon(_box(wc, Vector2(20.0, 40.0), float(w[1])), Color(0.10, 0.10, 0.12))
			b.draw_colored_polygon(_box(wc, Vector2(10.0, 30.0), float(w[1])), Color(0.22, 0.22, 0.25))

	# --- the hopper -------------------------------------------------------
	var hop := Rect2(-BODY_HALF, -L, BODY_HALF * 2.0, L * 2.0 - 104.0)
	b.draw_colored_polygon(_rr(hop, 16.0), pal.dark)
	b.draw_colored_polygon(_rr(hop.grow_individual(-7.0, 0.0, -7.0, -6.0), 12.0), pal.body)
	# a soft plasticine sheen on the lit corner
	b.draw_colored_polygon(_rr(Rect2(-BODY_HALF + 14.0, -L + 8.0, BODY_HALF * 0.85, 70.0), 12.0),
		Color(sheen.r, sheen.g, sheen.b, 0.45))
	# the lid, hinged at the back, and its seams and rivets
	b.draw_line(Vector2(-BODY_HALF + 12.0, -L + 26.0), Vector2(BODY_HALF - 12.0, -L + 26.0), Color(0, 0, 0, 0.22), 2.0)
	for sy: float in [-L + 70.0, -L + 112.0]:
		b.draw_line(Vector2(-BODY_HALF + 12.0, sy), Vector2(BODY_HALF - 12.0, sy), Color(0, 0, 0, 0.18), 2.0)
		b.draw_line(Vector2(-BODY_HALF + 12.0, sy + 2.0), Vector2(BODY_HALF - 12.0, sy + 2.0), Color(1, 1, 1, 0.10), 1.0)
		for rx in range(5):
			var rv := Vector2(-BODY_HALF + 20.0 + float(rx) * (BODY_HALF * 2.0 - 40.0) / 4.0, sy - 5.0)
			b.draw_circle(rv, 2.2, (pal.dark as Color))
			b.draw_circle(rv + Vector2(-0.6, -0.6), 1.2, (pal.lit as Color))
	# the water tank's filler cap and the hose coiled on the flank
	b.draw_circle(Vector2(-BODY_HALF * 0.45, -L + 90.0), 9.0, Color(0.20, 0.20, 0.22))
	b.draw_circle(Vector2(-BODY_HALF * 0.45, -L + 90.0), 5.0, Color(0.44, 0.45, 0.48))
	b.draw_circle(Vector2(BODY_HALF * 0.42, -L + 132.0), 15.0, Color(0.14, 0.30, 0.18))
	b.draw_circle(Vector2(BODY_HALF * 0.42, -L + 132.0), 8.0, (pal.body as Color))
	# reflective chevrons on the tail, for the traffic behind it
	for i in range(5):
		var x0 := -BODY_HALF + 14.0 + float(i) * (BODY_HALF * 2.0 - 28.0) / 5.0
		b.draw_colored_polygon(PackedVector2Array([
			Vector2(x0, -L + 2.0), Vector2(x0 + 12.0, -L + 2.0),
			Vector2(x0 + 20.0, -L + 12.0), Vector2(x0 + 8.0, -L + 12.0),
		]), Color(0.90, 0.16, 0.12) if i % 2 == 0 else (pal.trim as Color))
	# exhaust stack on the front corner of the hopper, puffing harder as it guns it
	var ex := Vector2(BODY_HALF - 18.0, L - 118.0)
	b.draw_circle(ex, 7.0, Color(0.26, 0.26, 0.29))
	var puff := clampf(cur_speed / maxf(speed, 1.0), 0.4, 1.8)
	if stuck:
		puff = 1.8
	for i in range(4):
		var pf := fmod(rumble * (0.8 + 0.6 * puff) + float(i) * 0.25, 1.0)
		b.draw_circle(ex + Vector2(4.0, -pf * 50.0 * puff), 4.0 + pf * 8.0 * puff,
			Color(0.42, 0.42, 0.44, 0.24 * (1.0 - pf)))

	# --- the cab, at the front --------------------------------------------
	var cab := Rect2(-CAB_HALF, L - 112.0, CAB_HALF * 2.0, 112.0)
	b.draw_colored_polygon(_rr(cab, 20.0), pal.dark)
	b.draw_colored_polygon(_rr(cab.grow_individual(-6.0, -4.0, -6.0, -7.0), 16.0), pal.body)
	# the roof, catching the light on its north-west corner
	b.draw_colored_polygon(_rr(Rect2(-CAB_HALF + 12.0, L - 104.0, CAB_HALF * 2.0 - 24.0, 52.0), 12.0), pal.lit)
	b.draw_colored_polygon(_rr(Rect2(-CAB_HALF + 16.0, L - 100.0, CAB_HALF * 0.9, 24.0), 10.0),
		Color(1.0, 1.0, 1.0, 0.16))
	# Windscreen, at the SOUTH end of the cab: it drives south, so the glass
	# and the driver behind it face down the road at you.
	var glass := Rect2(-CAB_HALF + 12.0, L - 46.0, CAB_HALF * 2.0 - 24.0, 32.0)
	b.draw_colored_polygon(_rr(glass, 8.0), Color(0.12, 0.16, 0.20))
	b.draw_rect(Rect2(glass.position.x + 6.0, glass.position.y + 2.0, glass.size.x - 12.0, 7.0),
		Color(0.42, 0.54, 0.62, 0.7))
	# the driver, in hi-vis, seen through it: Spain drives on the right, so
	# the seat is on the machine's left, which is east as it comes at you
	b.draw_circle(Vector2(24.0, L - 30.0), 10.0, Color(0.96, 0.62, 0.12))
	b.draw_circle(Vector2(24.0, L - 32.0), 6.5, Color(0.78, 0.58, 0.44))
	b.draw_circle(Vector2(24.0, L - 34.0), 5.0, Color(0.20, 0.30, 0.50))
	# a wiper, because the small wrong-looking details are what give a drawn
	# object away as a box with a window painted on it
	b.draw_line(Vector2(-30.0, L - 16.0), Vector2(0.0, L - 36.0), Color(0.10, 0.10, 0.12), 2.5)
	# wing mirrors, out where a driver would actually need them
	for s: float in [-1.0, 1.0]:
		b.draw_colored_polygon(_box(Vector2(s * (CAB_HALF + 9.0), L - 40.0), Vector2(14.0, 9.0), 0.0),
			Color(0.14, 0.14, 0.16))
	# the spray bar on the front bumper, its nozzles feeding the mist
	b.draw_rect(Rect2(-CAB_HALF + 6.0, L - 6.0, CAB_HALF * 2.0 - 12.0, 7.0), Color(0.30, 0.31, 0.34))
	for i in range(7):
		b.draw_circle(Vector2(-CAB_HALF + 16.0 + float(i) * (CAB_HALF * 2.0 - 32.0) / 6.0, L + 1.0), 2.4,
			Color(0.70, 0.84, 0.95))

	# --- beacons ----------------------------------------------------------
	# a bar across the back of the cab roof: amber strobes for the sweeper,
	# blue-and-red for the emergency variant. They alternate, which reads as
	# urgency at a glance, and go frantic while it is stuck.
	var by := L - 108.0
	b.draw_rect(Rect2(-44.0, by - 5.0, 88.0, 10.0), Color(0.12, 0.12, 0.14))
	var on := fmod(rumble, 0.2 if stuck else 0.5) < (0.1 if stuck else 0.25)
	if kind == "both":
		b.draw_circle(Vector2(-32.0, by), 7.0, Color(1.0, 0.24, 0.20) if on else Color(0.34, 0.08, 0.07))
		b.draw_circle(Vector2(32.0, by), 7.0, Color(0.32, 0.46, 1.0) if not on else Color(0.09, 0.13, 0.34))
	else:
		for bx: float in [-32.0, 32.0]:
			var lit: bool = on if bx < 0.0 else not on
			b.draw_circle(Vector2(bx, by), 7.0, Color(1.0, 0.78, 0.16) if lit else Color(0.38, 0.28, 0.06))
			if lit:
				b.draw_circle(Vector2(bx, by), 15.0, Color(1.0, 0.80, 0.25, 0.18))
	if stuck:
		# steam off the hopper while it strains
		for i in range(5):
			var pf := fmod(rumble * 1.4 + float(i) * 0.2, 1.0)
			b.draw_circle(Vector2(-20.0 + float(i) * 10.0, -L + 40.0 - pf * 60.0), 6.0 + pf * 14.0,
				Color(0.92, 0.92, 0.94, 0.30 * (1.0 - pf)))
