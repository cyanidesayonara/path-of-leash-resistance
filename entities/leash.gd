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
# Tension eases in over the first 5% of stretch instead of switching on at
# rest length; both the tug force and the strap's look read the same amount.
const TAUT_ONSET_END := 1.05
# Interior velocity damping on a rope that touches nothing, scaled by the
# taut amount, so a stretched rope settles instead of swinging on and on.
const TAUT_DAMP := 0.1
# The pull tangent is the chord over this many segments, so one displaced
# point next to the end cannot steer it; a contact within them falls back to
# the first segment alone.
const TANGENT_RUN := 3
# The human end's own geometry: the last WHIRL_TAIL points, which is exactly
# the window human_end_winding() measures. The whirl's direction is decided by
# stepping the hand WHIRL_PROBE_STEP radians each way round the pole and
# keeping the step that leaves her end less wound (main.gd/_apply_leash).
# Only corners beside the pole count as its coil - WHIRL_COIL_REACH at the
# least, and as far out as her hand when the rope has it further (see
# unwind_bias). Rope points held against a pole sit POLE_PAD out from it.
const WHIRL_TAIL := 9
const WHIRL_PROBE_STEP := 0.08
const WHIRL_COIL_REACH := 2.0 * POLE_PAD
# turning below this is no turning at all, so a tie is a tie every time
const WIND_EPS := 1.0e-6
# how close a point has to be to a listed pole to BE that pole (px squared)
const POLE_MATCH_SQ := 1.0
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
# the static contact nearest the HUMAN end, and what it is: the thing the
# owner is actually wound on, which is what a whirl orbits
var human_contact_pole := Vector2(INF, INF)
var human_contact_is_pole := false
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


# 0 at rest length, 1 from TAUT_ONSET_END on, smooth in between.
func taut_amount(stretch_ratio: float) -> float:
	return smoothstep(1.0, TAUT_ONSET_END, stretch_ratio)


# The spring force main.gd applies for `excess_px` of stretch past rest_len:
# eased in through the onset band, the full spring_k * excess beyond it.
func tension_force(excess_px: float, spring_k: float) -> float:
	if excess_px <= 0.0:
		return 0.0
	var ratio := (rest_len + excess_px) / maxf(rest_len, 1.0)
	return spring_k * excess_px * taut_amount(ratio)


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
	pts.resize(N)
	prev.resize(N)
	for i in range(N):
		var p := d.global_position.lerp(h.global_position, float(i) / (N - 1))
		pts[i] = p
		prev[i] = p


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
	# The ends do not move during the solve, so they are read once, not per
	# iteration (both are property reads through the engine).
	var dog_end := dog.global_position
	var hand_end := _hand_pos()
	# Obstacles further than this from a segment's bounding box cannot touch it.
	# The margin is POLE_PAD plus slack, so the reject never skips a contact the
	# exact test below would have found.
	var reach := POLE_PAD + 1.0
	for _iter in range(ITER):
		pts[0] = dog_end
		pts[N - 1] = hand_end
		# a carries pts[i] from the previous step, so each point is read once
		var a: Vector2 = pts[0]
		for i in range(N - 1):
			var b: Vector2 = pts[i + 1]
			var d := b - a
			var dist := d.length()
			if dist < 0.001:
				a = b
				continue
			# stiff against stretch, loose against compression so slack
			# rope drapes instead of contracting into a straight line
			var k := 0.9 if dist > seg else 0.05
			var corr := d * ((dist - seg) / dist) * 0.5 * k
			if i > 0:
				pts[i] = a + corr
			if i + 1 < N - 1:
				b -= corr
				pts[i + 1] = b
			a = b
		# segment-vs-circle collision: point-only checks tunnel when
		# stretched segments straddle the pole between two points.
		if obs_n == 0:
			continue
		for i in range(N - 1):
			var sa: Vector2 = pts[i]
			var sb: Vector2 = pts[i + 1]
			for oi in range(obs_n):
				var pl: Vector2 = _obs_pos[oi]
				if pl.x + reach < minf(sa.x, sb.x) or pl.x - reach > maxf(sa.x, sb.x) 						or pl.y + reach < minf(sa.y, sb.y) or pl.y - reach > maxf(sa.y, sb.y):
					continue
				# _closest_on_segment, inlined: this is the solver's innermost loop
				var cp := sa
				var ab := sb - sa
				var l2 := ab.length_squared()
				if l2 >= 0.0001:
					cp = sa + ab * clampf((pl - sa).dot(ab) / l2, 0.0, 1.0)
				var dp := cp - pl
				var l := dp.length()
				if l < POLE_PAD and l > 0.001:
					var push := dp / l * (POLE_PAD - l)
					if i > 0:
						sa += push
						pts[i] = sa
						_touch[i] = oi
					if i + 1 < N - 1:
						sb += push
						pts[i + 1] = sb
						_touch[i + 1] = oi
	contacts = 0
	static_contacts = 0
	dynamic_contacts = 0
	# static contact closest to the dog end owns contact_pole (vault etc.)
	contact_pole = Vector2(INF, INF)
	contact_kind = ""
	human_contact_pole = Vector2(INF, INF)
	human_contact_is_pole = false
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
			# i ascends from the dog, so the last one wins: nearest the human
			human_contact_pole = pl2
			human_contact_is_pole = code == K_POLE
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
	# A taut rope touching nothing settles instead of swinging: its interior
	# momentum is damped. A rope on anything keeps all its momentum, which is
	# what winds a coil and slides it off.
	var damp := TAUT_DAMP * taut_amount(stretch_ratio)
	if damp > 0.0 and contacts == 0:
		for i in range(1, N - 1):
			prev[i] = prev[i].lerp(pts[i], damp)
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


# winding() counted only where the rope touches something static: turning
# round another walker's rope is a tangle, not a pole, and must not borrow
# the pole's pulley
func static_winding() -> float:
	var total := 0.0
	if _touch.size() < N:
		return 0.0
	for i in range(1, N - 1):
		var oi := _touch[i]
		if oi < 0 or _obs_kind[oi] == K_DYNAMIC:
			continue
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


# The human end's last WHIRL_TAIL points, oldest first: the only geometry the
# whirl's direction choice is allowed to look at. Same window
# human_end_winding() measures.
func human_tail() -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in range(maxi(0, N - WHIRL_TAIL), N):
		out.append(pts[i])
	return out


# How far out from a pole the coil an orbit round it could take off reaches:
# that coil lies between the pole and her hand, so the gap out to her hand is
# the measure, plus the pad rope points are held off the pole at. A taut rope's
# corners sit most of that way out, which is why this is not a fixed small
# radius; what it must still exclude is whatever the rope is wound round
# somewhere else, and that is poles away, not hand-lengths. Reads its argument
# only, so the boundary can be pinned without a rope.
func coil_reach_for(hand_gap: float) -> float:
	return maxf(WHIRL_COIL_REACH, hand_gap + POLE_PAD)


# The coil at `pole` her end is standing in, in radians. ONE measure over one
# window: the whirl's direction and its turn budget both come from here, so an
# orbit cannot be sent one way and sized by something wound the other.
func coil_winding(pole: Vector2) -> float:
	var tail := human_tail()
	if tail.size() == 0:
		return 0.0
	return pole_winding(tail, pole, coil_reach_for(tail[tail.size() - 1].distance_to(pole)))


# the same coil in whole turns: what an orbit round this pole has to take off
func coil_turns(pole: Vector2) -> float:
	return absf(coil_winding(pole)) / TAU


# Which way round `pole` unwinds the human end: positive for anticlockwise.
func unwind_bias(pole: Vector2) -> float:
	return unwind_bias_of(coil_winding(pole), WHIRL_PROBE_STEP)


# The two below read their arguments and nothing else, so the whirl's
# direction choice can be pinned without a rope (tests/test_whirl_guided.gd).

# The tail's signed turning about `pole`, in radians: the corners of the coil
# it is wound in, which is the only part of her end an orbit round THIS pole
# can take off. A long straight run out to the hand therefore cannot outvote
# the coil, and neither can a coil wound round something else further along.
# Nothing beside the pole, or corners beside it that cancel, is no coil here
# and reads as exactly 0.0 - never the whole tail's turning, which is the
# measure this function exists to avoid. Its callers settle their own ties.
func pole_winding(p: PackedVector2Array, pole: Vector2, reach := WHIRL_COIL_REACH) -> float:
	var near := 0.0
	for i in range(1, p.size() - 1):
		if p[i].distance_squared_to(pole) >= reach * reach:
			continue
		var a := p[i] - p[i - 1]
		var b := p[i + 1] - p[i]
		if a.length_squared() <= 0.01 or b.length_squared() <= 0.01:
			continue
		near += a.angle_to(b)
	return 0.0 if absf(near) < WIND_EPS else near


# How much less wound the owner's end would be if her hand took a tiny step
# anticlockwise round the pole rather than clockwise. An orbit step of `step`
# radians round the pole adds exactly that much turning to the rope where it
# is wound, so the two candidates leave the local winding at w + step and
# w - step, and the one with less of it is the way that unwinds. Positive
# commits anticlockwise; a tail wound neither way reads exactly zero, so the
# tie always goes the same way.
#
# Probing by displacing the hand POINT and re-measuring does not work: that
# reads the kink beside the hand, whose sign has nothing to do with which way
# the coil goes. On a rope the dog had wound it picked the winding-UP way.
func unwind_bias_of(local_winding: float, step: float) -> float:
	var bias := absf(local_winding - step) - absf(local_winding + step)
	return 0.0 if absf(bias) < WIND_EPS else bias


# Is `p` still a real pole in this level - the only thing a whirl may orbit?
# Furniture unwinds nothing (La Rambla's terrace once held an owner in a
# whirl-stumble loop for two minutes) and neither does a point that is in no
# list at all.
func is_real_pole(p: Vector2) -> bool:
	if not (is_finite(p.x) and is_finite(p.y)):
		return false
	_ensure_pole_kinds()
	for i in range(poles.size()):
		if pole_kinds[i] == K_POLE and poles[i].distance_squared_to(p) < POLE_MATCH_SQ:
			return true
	return false


func dog_pull_dir() -> Vector2:
	return _end_tangent(0, 1)


func human_pull_dir() -> Vector2:
	return _end_tangent(N - 1, -1)


# The chord from an end over TANGENT_RUN segments: the sum of those segments,
# so each is weighted by its length. A contact anywhere in that run means the
# rope is on something right by the end, and the pull is the first segment
# alone, as it always was: wraps, vaults and flings aim along it.
func _end_tangent(end: int, step: int) -> Vector2:
	var j := end + step * TANGENT_RUN
	if _touch.size() == N:
		for k in range(1, TANGENT_RUN + 1):
			if _touch[end + step * k] >= 0:
				j = end + step
				break
	var d := pts[j] - pts[end]
	if d.length() <= 0.001:
		d = pts[end + step] - pts[end]
	return d.normalized() if d.length() > 0.001 else Vector2.ZERO


# the stand-in canvas for this node's drawing, made fresh each _draw
var _b: ShapeBatch
# Draw buffers, all 2N-1 samples long, sized once and overwritten by index
# every frame: this runs on every rope on screen, so it must not reallocate.
const VIS_N := 2 * N - 1
var _vis := PackedVector2Array()
var _loc := PackedVector2Array()
var _shade := PackedVector2Array()
var _hi := PackedVector2Array()


# The rope as drawn, in global coordinates: always VIS_N samples, every solver
# point exactly at the even ones and between each pair a Catmull-Rom midpoint
# so slack curves flow. A segment ending on a contact keeps its chord
# midpoint, and so does one whose curve would bring the strap inside POLE_PAD
# of an obstacle, so the drawn rope never cuts across what the solver
# wrapped it round.
func visible_path() -> PackedVector2Array:
	if _vis.size() != VIS_N:
		_vis.resize(VIS_N)
	var has_touch := _touch.size() == N
	var obs_n := _obs_pos.size() if has_touch else 0
	var reach := POLE_PAD + 1.0
	for i in range(N - 1):
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		_vis[2 * i] = a
		var chord := (a + b) * 0.5
		_vis[2 * i + 1] = chord
		if has_touch and (_touch[i] >= 0 or _touch[i + 1] >= 0):
			continue
		var ta: Vector2 = pts[mini(i + 1, N - 1)] - pts[maxi(i - 1, 0)]
		var tb: Vector2 = pts[mini(i + 2, N - 1)] - pts[i]
		var mid := chord + (ta - tb) * 0.0625
		var clear := true
		for oi in range(obs_n):
			var pl: Vector2 = _obs_pos[oi]
			if pl.x + reach < minf(minf(a.x, b.x), mid.x) or pl.x - reach > maxf(maxf(a.x, b.x), mid.x) \
					or pl.y + reach < minf(minf(a.y, b.y), mid.y) or pl.y - reach > maxf(maxf(a.y, b.y), mid.y):
				continue
			if _closest_on_segment(a, mid, pl).distance_to(pl) < POLE_PAD \
					or _closest_on_segment(mid, b, pl).distance_to(pl) < POLE_PAD:
				clear = false
				break
		if clear:
			_vis[2 * i + 1] = mid
	_vis[VIS_N - 1] = pts[N - 1]
	return _vis


func _draw() -> void:
	# every draw call goes through a ShapeBatch standing in for the canvas: runs
	# of shapes become one draw call, same pixels (systems/shape_batch.gd)
	_b = ShapeBatch.new(self)
	_draw_shapes()
	_b.flush()


func _draw_shapes() -> void:
	var path := visible_path()
	var n := path.size()
	if _loc.size() != n:
		_loc.resize(n)
		_shade.resize(n)
		_hi.resize(n)
	for i in range(n):
		var p := to_local(path[i])
		_loc[i] = p
		_shade[i] = p + Vector2(2.0, 3.0)
		_hi[i] = p + Vector2(0.0, -0.9)
	# a flat 3px line reads as a debug gizmo. Four passes make it read as
	# webbing: a dropped shadow, a dark edge, the body, and a lit top edge
	# running slightly above the core like light off a strap - plus it
	# cinches thinner and hotter as it comes taut. A dynamic leash snag
	# warms the strap so the tangle reads separately from a pole wrap.
	var tight := taut_amount(used_length() / maxf(rest_len, 1.0))
	var body := Color(0.55, 0.27, 0.23).lerp(Color(0.72, 0.28, 0.22), tight)
	if dynamic_contacts > 0:
		body = Color(0.72, 0.38, 0.22).lerp(Color(0.88, 0.42, 0.18), tight)
	var wide := lerpf(4.2, 3.4, tight)
	_b.draw_polyline(_shade, Color(0.05, 0.04, 0.06, 0.22), wide)
	_b.draw_polyline(_loc, body.darkened(0.35), wide)
	_b.draw_polyline(_loc, body, wide * 0.6)
	_b.draw_polyline(_hi, body.lightened(0.34), wide * 0.24)
	if contact_dynamic.x < INF:
		var cp := to_local(contact_dynamic)
		_b.draw_circle(cp + Vector2(1.2, 1.8), 5.2, Color(0.05, 0.04, 0.06, 0.28))
		_b.draw_circle(cp, 4.6, Color(0.95, 0.55, 0.22, lerpf(0.65, 0.85, tight)))
		_b.draw_circle(cp, 2.0, Color(1.0, 0.85, 0.55, 0.9))
	# the handle loop in the owner's fist
	var hp := to_local(_hand_pos())
	_b.draw_circle(hp + Vector2(1.5, 2.0), 4.6, Color(0.05, 0.04, 0.06, 0.25))
	_b.draw_circle(hp, 4.4, body.darkened(0.45))
	_b.draw_circle(hp, 2.4, body.lightened(0.1))
