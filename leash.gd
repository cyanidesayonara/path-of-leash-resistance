extends Node2D

# The leash IS the verlet rope. The visible rope is also the gameplay
# constraint: it wraps poles by colliding with them, winds up, unwinds,
# and slides off under tension like a real rope. There is no separate
# wrap bookkeeping to fall out of sync with what the player sees.
#
# main.gd sets rest_len (the human's retractable reel), calls tick() once
# per physics frame, then reads used_length() vs rest_len for tension and
# dog_pull_dir()/human_pull_dir() (the rope's end tangents) for force
# directions - which is why a wound-up human gets flung in an arc: the
# pull follows the rope around the pole.

const N := 24
const ITER := 11
const POLE_PAD := 13.0
const FRICTION := 0.5
# Stick-slip tuning. The geometry hard-cap is 1.15x; sustained tension
# against static snags must be able to approach free slip inside that cap,
# while intentional single-pole wraps still grip near rest length.
const STRETCH_CAP := 1.15
const STATIC_SLIP_MIN := 0.15
const FURNITURE_SLIP_MIN := 0.35
const DYNAMIC_SLIP_MIN := 0.40
const KIND_POLE := "pole"
const KIND_FURNITURE := "furniture"
const KIND_DYNAMIC := "dynamic"

var pts: Array[Vector2] = []
var prev: Array[Vector2] = []
var dog: Node2D
var human: Node2D
var poles: Array[Vector2] = []
var rest_len := 260.0
var taut := false
var contacts := 0
# the pole the rope is caught on nearest the DOG end, which is the one she
# can vault around (see main.gd/_tick_vault). INF when the rope is running
# free. Only STATIC contacts populate this - dynamic leash points must not
# share pole-only vault/shield semantics.
var contact_pole := Vector2(INF, INF)
var contact_kind := ""
var contact_static := false
var detached := false
var near_poles: Array[Vector2] = []
# authored furniture wrap centres (tables/chairs/parasols/bins). Same
# collision as poles, but typed so slip and contact metadata can differ.
var furniture_poles: Array[Vector2] = []
# points contributed by ANOTHER leash this frame: the rope drapes over
# them, with dynamic slip, without claiming contact_pole
var dynamic_obstacles: Array[Vector2] = []
# while > 0 the rope slides freely on poles (no stick): set during a whirl
# so the choreographed unwind can never be arrested by rope grip
var free_slip_t := 0.0
# the player's leash draws every frame (hero element); NPC-pair leashes
# only need ~30fps, halving their line-heavy rope draw on the web build
var hero := false


func slip_for(stretch_ratio: float, kind: String) -> float:
	# Linear ramp from the kind's grip floor at rest length to free slip
	# at STRETCH_CAP. Furniture starts looser than poles so terrace snags
	# can free under collision-constrained pulls; dynamic leash contacts
	# start looser still so a tangle does not lock like a pole.
	var amin := STATIC_SLIP_MIN
	if kind == KIND_FURNITURE:
		amin = FURNITURE_SLIP_MIN
	elif kind == KIND_DYNAMIC:
		amin = DYNAMIC_SLIP_MIN
	var t := clampf((stretch_ratio - 1.0) / (STRETCH_CAP - 1.0), 0.0, 1.0)
	return lerpf(amin, 1.0, t)


func _kind_at(pos: Vector2) -> String:
	for f in furniture_poles:
		if f.distance_squared_to(pos) < 0.25:
			return KIND_FURNITURE
	return KIND_POLE


func setup(d: Node2D, h: Node2D, pole_list: Array[Vector2], max_len: float) -> void:
	dog = d
	human = h
	poles = pole_list
	rest_len = max_len
	for i in range(N):
		var p := d.global_position.lerp(h.global_position, float(i) / (N - 1))
		pts.append(p)
		prev.append(p)


func _hand_pos() -> Vector2:
	return human.global_position + Vector2(9, -16).rotated(human.rotation)


func resnap() -> void:
	# lay the rope fresh in a straight line from dog to hand, so
	# re-clipping the leash after the off-leash romp doesn't snap
	var a := dog.global_position
	var b := _hand_pos()
	for i in range(N):
		pts[i] = a.lerp(b, float(i) / (N - 1))
		prev[i] = pts[i]


func tick(delta: float) -> void:
	var seg := rest_len / (N - 1)
	free_slip_t = maxf(0.0, free_slip_t - delta)
	# stick-slip: grip at low tension (coils hold, winding accumulates),
	# approach free slip by STRETCH_CAP (rope slides off instead of
	# locking forever against furniture/static snags)
	var stretch_ratio := used_length() / maxf(rest_len, 1.0)
	for i in range(1, N - 1):
		var vel := (pts[i] - prev[i]) * 0.94
		prev[i] = pts[i]
		pts[i] += vel
	var start := pts.duplicate()
	# touched[i] -> {pos, kind, is_static}
	var touched := {}
	# only obstacles near the rope's bounding box matter this frame; the
	# box MUST cover every rope point, not just the endpoints - a partial
	# wind puts both endpoints on one side of the pole, and an
	# endpoint-only box excluded it (the slipping-off regression).
	var rl := pts[0].x
	var rr := pts[0].x
	var rt := pts[0].y
	var rb := pts[0].y
	for rp in pts:
		rl = minf(rl, rp.x)
		rr = maxf(rr, rp.x)
		rt = minf(rt, rp.y)
		rb = maxf(rb, rp.y)
	near_poles.clear()
	var near_obs: Array[Dictionary] = []
	for npl in poles:
		if npl.x > rl - 40.0 and npl.x < rr + 40.0 and npl.y > rt - 40.0 and npl.y < rb + 40.0:
			near_poles.append(npl)
			var kind := _kind_at(npl)
			near_obs.append({"pos": npl, "kind": kind, "is_static": true})
	for dob in dynamic_obstacles:
		if dob.x > rl - 40.0 and dob.x < rr + 40.0 and dob.y > rt - 40.0 and dob.y < rb + 40.0:
			near_poles.append(dob)
			near_obs.append({"pos": dob, "kind": KIND_DYNAMIC, "is_static": false})
	for _iter in range(ITER):
		pts[0] = dog.global_position
		pts[N - 1] = _hand_pos()
		for i in range(N - 1):
			var d := pts[i + 1] - pts[i]
			var dist := d.length()
			if dist < 0.001:
				continue
			# stiff against stretch, loose against compression so slack
			# rope drapes instead of contracting into a straight line
			var k := 0.9 if dist > seg else 0.05
			var corr := d * ((dist - seg) / dist) * 0.5 * k
			if i > 0:
				pts[i] += corr
			if i + 1 < N - 1:
				pts[i + 1] -= corr
		# segment-vs-circle collision: point-only checks tunnel when
		# stretched segments straddle the pole between two points.
		if near_obs.is_empty():
			continue
		for i in range(N - 1):
			for obs in near_obs:
				var pl: Vector2 = obs.pos
				var cp := _closest_on_segment(pts[i], pts[i + 1], pl)
				var dp := cp - pl
				var l := dp.length()
				if l < POLE_PAD and l > 0.001:
					var push := dp / l * (POLE_PAD - l)
					if i > 0:
						pts[i] += push
						touched[i] = obs
					if i + 1 < N - 1:
						pts[i + 1] += push
						touched[i + 1] = obs
	contacts = touched.size()
	# static contact closest to the dog end owns contact_pole (vault etc.)
	contact_pole = Vector2(INF, INF)
	contact_kind = ""
	contact_static = false
	var best_i := 1 << 30
	for i in touched:
		var obs: Dictionary = touched[i]
		if not bool(obs.is_static):
			continue
		if int(i) < best_i:
			best_i = int(i)
			contact_pole = obs.pos
			contact_kind = String(obs.kind)
			contact_static = true
	# apply stick-slip per contact kind
	for i in touched:
		var obs2: Dictionary = touched[i]
		var pl2: Vector2 = obs2.pos
		var slip := 1.0 if free_slip_t > 0.0 else slip_for(stretch_ratio, String(obs2.kind))
		var r0: Vector2 = start[i] - pl2
		var r1: Vector2 = pts[i] - pl2
		if r0.length_squared() > 0.001 and r1.length_squared() > 0.001:
			var da := wrapf(r1.angle() - r0.angle(), -PI, PI)
			pts[i] = pl2 + Vector2.from_angle(r0.angle() + da * slip) * r1.length()
		prev[i] = prev[i].lerp(pts[i], FRICTION)
	if hero or Engine.get_physics_frames() % 2 == 0:
		queue_redraw()


func _closest_on_segment(a: Vector2, b: Vector2, c: Vector2) -> Vector2:
	var ab := b - a
	var l2 := ab.length_squared()
	if l2 < 0.0001:
		return a
	var t := clampf((c - a).dot(ab) / l2, 0.0, 1.0)
	return a + ab * t


func used_length() -> float:
	# actual polyline length: wrapping a pole consumes rope, so this is
	# the gameplay length (compare against rest_len)
	var total := 0.0
	for i in range(N - 1):
		total += pts[i].distance_to(pts[i + 1])
	return total


func winding() -> float:
	# net signed turning of the rope in full turns: a coil around a pole
	# reads as +/-N turns, while gentle slack curves mostly cancel out
	var total := 0.0
	for i in range(1, N - 1):
		var a := pts[i] - pts[i - 1]
		var b := pts[i + 1] - pts[i]
		if a.length_squared() > 0.01 and b.length_squared() > 0.01:
			total += a.angle_to(b)
	return total / TAU


func human_end_winding() -> float:
	# signed turning (radians) of the last few segments at the human end:
	# tells whether the HUMAN is the wound-up one, and which way unwinds
	var total := 0.0
	for i in range(maxi(1, N - 8), N - 1):
		var a := pts[i] - pts[i - 1]
		var b := pts[i + 1] - pts[i]
		if a.length_squared() > 0.01 and b.length_squared() > 0.01:
			total += a.angle_to(b)
	return total


func dog_pull_dir() -> Vector2:
	var d := pts[1] - pts[0]
	return d.normalized() if d.length() > 0.001 else Vector2.ZERO


func human_pull_dir() -> Vector2:
	var d := pts[N - 2] - pts[N - 1]
	return d.normalized() if d.length() > 0.001 else Vector2.ZERO


func _draw() -> void:
	var arr := PackedVector2Array()
	for p in pts:
		arr.append(to_local(p))
	# a flat 3px line reads as a debug gizmo. Three passes make it read as
	# webbing: a dropped shadow, a dark body, and a lit top edge - plus it
	# cinches visibly thinner and hotter when taut.
	var body := Color(0.72, 0.28, 0.22) if taut else Color(0.55, 0.27, 0.23)
	var wide := 3.4 if taut else 4.2
	var shade := PackedVector2Array()
	for p in arr:
		shade.append(p + Vector2(2.0, 3.0))
	draw_polyline(shade, Color(0.05, 0.04, 0.06, 0.22), wide)
	draw_polyline(arr, body.darkened(0.35), wide)
	draw_polyline(arr, body, wide * 0.6)
	# the highlight runs slightly above the core, like light off a strap
	var hi := PackedVector2Array()
	for p in arr:
		hi.append(p + Vector2(0.0, -0.9))
	draw_polyline(hi, body.lightened(0.34), wide * 0.24)
	# the handle loop in the owner's fist
	var hp := to_local(_hand_pos())
	draw_circle(hp + Vector2(1.5, 2.0), 4.6, Color(0.05, 0.04, 0.06, 0.25))
	draw_circle(hp, 4.4, body.darkened(0.45))
	draw_circle(hp, 2.4, body.lightened(0.1))
