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
# Public kind names: contact_kind and slip_for() are read by main.gd and
# pinned by tests, so they stay Strings.
const KIND_POLE := "pole"
const KIND_FURNITURE := "furniture"
const KIND_DYNAMIC := "dynamic"
# Internal codes. The solver runs ITER * (N-1) * near-obstacle times per rope
# per frame, and it must not touch a String or a Dictionary in there.
const K_POLE := 0
const K_FURNITURE := 1
const K_DYNAMIC := 2

var pts: Array[Vector2] = []
var prev: Array[Vector2] = []
var dog: Node2D
var human: Node2D
var poles: Array[Vector2] = []
var rest_len := 260.0
var taut := false
var contacts := 0
var static_contacts := 0
var dynamic_contacts := 0
# the pole the rope is caught on nearest the DOG end, which is the one she
# can vault around (see main.gd/_tick_vault). INF when the rope is running
# free. Only STATIC contacts populate this - dynamic leash points must not
# share pole-only vault/shield semantics.
var contact_pole := Vector2(INF, INF)
var contact_kind := ""
var contact_static := false
# nearest dynamic snag (another leash) for tangle presentation. INF when free.
var contact_dynamic := Vector2(INF, INF)
var detached := false
var near_poles: Array[Vector2] = []
# authored furniture wrap centres (tables/chairs/parasols/bins). Same
# collision as poles, but typed so slip and contact metadata can differ.
var furniture_poles: Array[Vector2] = []
# poles typed once and cached, parallel to `poles`. Recovering a pole's kind by
# scanning furniture_poles with a distance match EVERY frame cost more than the
# collision it fed, and matching identity by proximity was fragile besides.
var pole_kinds := PackedInt32Array()
var _kinds_stamp := -1
# scratch reused every tick, so a frame allocates nothing
var _obs_pos := PackedVector2Array()
var _obs_kind := PackedInt32Array()
var _touch := PackedInt32Array()
var _start: Array[Vector2] = []
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
	return _slip_code(stretch_ratio, _code_for(kind))


func _code_for(kind: String) -> int:
	if kind == KIND_FURNITURE:
		return K_FURNITURE
	if kind == KIND_DYNAMIC:
		return K_DYNAMIC
	return K_POLE


func _name_for(code: int) -> String:
	if code == K_FURNITURE:
		return KIND_FURNITURE
	if code == K_DYNAMIC:
		return KIND_DYNAMIC
	return KIND_POLE


func _slip_code(stretch_ratio: float, code: int) -> float:
	# POLES KEEP THE ORIGINAL CURVE, deliberately. The soft-lock this hardening
	# pass fixes was terrace FURNITURE refusing to free under a
	# collision-constrained pull. Pole grip is a different thing: it is what
	# holds a wrap for the vault, what accumulates winding, and what decides
	# whether the fling gets right of way - so putting poles on the steep ramp
	# changed three mechanics to fix a fourth (at 10% stretch a pole went from
	# 0.23 slip to 0.72). Nothing in the suite asked for it: every "approaches
	# free slip at the cap" assertion is about furniture and dynamic contacts.
	if code == K_POLE:
		return clampf(0.15 + (stretch_ratio - 1.0) * 0.8, STATIC_SLIP_MIN, 1.0)
	# Furniture and another walker's rope ramp to free slip by STRETCH_CAP, so
	# a snag can always work itself loose inside the geometry cap.
	var amin := FURNITURE_SLIP_MIN if code == K_FURNITURE else DYNAMIC_SLIP_MIN
	var t := clampf((stretch_ratio - 1.0) / (STRETCH_CAP - 1.0), 0.0, 1.0)
	return lerpf(amin, 1.0, t)


func _ensure_pole_kinds() -> void:
	# Rebuilt only when the pole list or the furniture list changes size, which
	# is what main.gd does at build time (trees and the FUR-GONETA are appended
	# after setup). Two int compares per tick in the steady state.
	if pole_kinds.size() == poles.size() and _kinds_stamp == furniture_poles.size():
		return
	pole_kinds.resize(poles.size())
	for i in range(poles.size()):
		var code := K_POLE
		for f in furniture_poles:
			if f.distance_squared_to(poles[i]) < 0.25:
				code = K_FURNITURE
				break
		pole_kinds[i] = code
	_kinds_stamp = furniture_poles.size()


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
	# reused rather than duplicated: this runs on every rope, every frame
	if _start.size() != N:
		_start.resize(N)
	for i in range(N):
		_start[i] = pts[i]
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
	# Near obstacles as two packed arrays rather than an array of dictionaries:
	# a dictionary per near obstacle per rope per frame was pure allocation
	# churn, and the solver read its fields from inside the innermost loop.
	near_poles.clear()
	_obs_pos.clear()
	_obs_kind.clear()
	_ensure_pole_kinds()
	for pi in range(poles.size()):
		var npl: Vector2 = poles[pi]
		if npl.x > rl - 40.0 and npl.x < rr + 40.0 and npl.y > rt - 40.0 and npl.y < rb + 40.0:
			near_poles.append(npl)
			_obs_pos.append(npl)
			_obs_kind.append(pole_kinds[pi])
	for dob in dynamic_obstacles:
		if dob.x > rl - 40.0 and dob.x < rr + 40.0 and dob.y > rt - 40.0 and dob.y < rb + 40.0:
			near_poles.append(dob)
			_obs_pos.append(dob)
			_obs_kind.append(K_DYNAMIC)
	var obs_n := _obs_pos.size()
	# which obstacle each rope point ended up against: -1 for none. An int per
	# point, allocated once, replaces a Dictionary of Dictionaries per frame.
	if _touch.size() != N:
		_touch.resize(N)
	for i in range(N):
		_touch[i] = -1
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
		if obs_n == 0:
			continue
		for i in range(N - 1):
			for oi in range(obs_n):
				var pl: Vector2 = _obs_pos[oi]
				var cp := _closest_on_segment(pts[i], pts[i + 1], pl)
				var dp := cp - pl
				var l := dp.length()
				if l < POLE_PAD and l > 0.001:
					var push := dp / l * (POLE_PAD - l)
					if i > 0:
						pts[i] += push
						_touch[i] = oi
					if i + 1 < N - 1:
						pts[i + 1] += push
						_touch[i + 1] = oi
	contacts = 0
	static_contacts = 0
	dynamic_contacts = 0
	# static contact closest to the dog end owns contact_pole (vault etc.)
	contact_pole = Vector2(INF, INF)
	contact_kind = ""
	contact_static = false
	contact_dynamic = Vector2(INF, INF)
	# the slip a contact gets depends only on this tick's stretch and the kind,
	# so it is resolved three times per tick rather than once per contact
	var free := free_slip_t > 0.0
	var slip_pole := 1.0 if free else _slip_code(stretch_ratio, K_POLE)
	var slip_furn := 1.0 if free else _slip_code(stretch_ratio, K_FURNITURE)
	var slip_dyn := 1.0 if free else _slip_code(stretch_ratio, K_DYNAMIC)
	for i in range(N):
		var oi := _touch[i]
		if oi < 0:
			continue
		contacts += 1
		var code := _obs_kind[oi]
		var pl2: Vector2 = _obs_pos[oi]
		if code == K_DYNAMIC:
			dynamic_contacts += 1
			if contact_dynamic.x >= INF:
				contact_dynamic = pl2      # nearest the dog end: i ascends
		else:
			static_contacts += 1
			if not contact_static:
				contact_pole = pl2
				contact_kind = _name_for(code)
				contact_static = true
		var slip := slip_dyn
		if code == K_POLE:
			slip = slip_pole
		elif code == K_FURNITURE:
			slip = slip_furn
		var r0: Vector2 = _start[i] - pl2
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
	# cinches visibly thinner and hotter when taut. A dynamic leash snag
	# warms the strap so the tangle reads separately from a pole wrap.
	var body := Color(0.72, 0.28, 0.22) if taut else Color(0.55, 0.27, 0.23)
	if dynamic_contacts > 0:
		body = Color(0.88, 0.42, 0.18) if taut else Color(0.72, 0.38, 0.22)
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
	if contact_dynamic.x < INF:
		var cp := to_local(contact_dynamic)
		draw_circle(cp + Vector2(1.2, 1.8), 5.2, Color(0.05, 0.04, 0.06, 0.28))
		draw_circle(cp, 4.6, Color(0.95, 0.55, 0.22, 0.85 if taut else 0.65))
		draw_circle(cp, 2.0, Color(1.0, 0.85, 0.55, 0.9))
	# the handle loop in the owner's fist
	var hp := to_local(_hand_pos())
	draw_circle(hp + Vector2(1.5, 2.0), 4.6, Color(0.05, 0.04, 0.06, 0.25))
	draw_circle(hp, 4.4, body.darkened(0.45))
	draw_circle(hp, 2.4, body.lightened(0.1))
