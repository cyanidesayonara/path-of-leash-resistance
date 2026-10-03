extends SceneTree

# The guided whirl (entities/human.gd WHIRL, armed in main.gd/_apply_leash).
# The orbit is the cartoon, but it must be a COMMITTED one. What this pins,
# beyond the pole choice and tighten-in that tests/test_whirl.gd already
# covers:
#   - the direction is chosen once, from the rope's own human-end geometry,
#     by a pure probe a test can ask directly;
#   - nothing reverses an orbit after the owner starts moving (arming read
#     local winding while the mid-orbit guard read the WHOLE rope, so she
#     could orbit one way and launch on the opposite tangent);
#   - signed progress completes the initial wound-turn budget once, and is
#     never reset;
#   - the ordinary release is the tangent itself, and only a launch forced by
#     the extra-arc cap is allowed to lean toward the dog;
#   - the launch is dogward even when the ideal tangent never arrives (the
#     forced release used to skip the aim entirely), never fires against the
#     way she was going round, and gives up on being a fling at all rather
#     than throwing her away from the dog;
#   - a timeout, a pole that stopped being a pole, or a pole that ran away
#     end the orbit in a controlled stumble - not a full-speed fling, and
#     never a snap across the level - and main.gd keeps shielding her on the
#     frame the orbit ends, which happens inside her own tick();
#   - while she is whirling, the tug of war cannot move her at all.

const DT := 1.0 / 60.0
const TAIL_PTS := 9
const PROBE := 0.08
# the implementation's own bounds, repeated so this test fails if they move
const EXTRA_ARC := 0.6 * TAU
const BLEND_MAX := PI / 3.0
const BAIL_SPEED := 260.0
const LOSE_R := 140.0
const ORBIT_R := 30.0
const COIL_REACH := 26.0
const STRETCH_CAP := 1.15
const AIM_COS := 0.5
const TURNS_MIN := 0.6
const TURNS_MAX := 4.0
# the rope's own point count, so a posed rope is the length of a real one
const PTS := 24
# the reach boundary fixture: her hand, an arc inside the reach her hand
# implies, and an arc outside it
const HAND_GAP := 30.0
const IN_R := 39.0
const OUT_R := 50.0
# and an arc out beyond the reach a hand at twice that gap implies
const FAR_ARC := 90.0
# how far off a pole the solver holds rope points, so the two-coil fixture can
# put her coil just inside that and be certain of a contact
const PAD := 13.0
# the two-coil fixture's radii: hers hugging her pole, and a tighter one further
# off that therefore turns harder per point, the other way
const FAR_R := 6.0
# An authored arc's radius, far enough inside the reach its own hand implies
# (that reach is the radius plus a pad) that no corner is near the boundary.
const ARC_R := 30.0
# Nine points leave seven corners, and no corner can read more than half a turn:
# a turn is the same angle whichever way round it is measured, so half a turn is
# where the two answers meet. That ceiling is the window's, not the rope's.
const CEILING_TURNS := 7.0 * PI / TAU
# radians, over seven accumulated corners: float slack, nothing more
const TOL_RAD := 1.0e-4

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	_probe_picks_the_unwinding_way()
	_the_coil_here_outvotes_the_rest_of_the_tail()
	_the_reach_is_the_gap_out_to_her_hand()
	_a_coil_is_worth_what_it_sweeps()
	_a_coil_somewhere_else_is_not_this_poles()
	_probe_agrees_with_a_real_rope()
	_the_probe_follows_her_end_not_the_whole_rope()
	_only_real_poles_can_be_orbited()
	call_deferred("_run")


# The two readings main's arming composes, composed the same way here: the coil
# at a pole in turns, and which way round that coil unwinds. The rope offers the
# signed coil and the probe; putting them together is the caller's business.
func _turns_at(l: Node2D, pole: Vector2) -> float:
	return absf(float(l.coil_winding(pole))) / TAU


func _bias_at(l: Node2D, pole: Vector2) -> float:
	return float(l.unwind_bias_of(l.coil_winding(pole)))


func _bare_leash() -> Node2D:
	var l: Node2D = Node2D.new()
	l.set_script(load("res://entities/leash.gd"))
	return l


# nine points on a circle round the pole: a tail wound one way
func _coil(pole: Vector2, sense: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for k in range(TAIL_PTS):
		out.append(pole + Vector2(20.0, 0.0).rotated(sense * 0.5 * float(k)))
	return out


# a tail running straight out from the pole: wound neither way
func _spoke(pole: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	for k in range(TAIL_PTS):
		out.append(pole + Vector2(0.0, -20.0 - 7.0 * float(k)))
	return out


# the whole tail's turning, which is the measure the probe must NOT use
func _tail_turning(p: PackedVector2Array) -> float:
	var total := 0.0
	for i in range(1, p.size() - 1):
		var a := p[i] - p[i - 1]
		var b := p[i + 1] - p[i]
		if a.length_squared() > 0.01 and b.length_squared() > 0.01:
			total += a.angle_to(b)
	return total


# A tail wound `sense` round `pole`, with a bigger coil the OTHER way further
# along it - the rest of the rope, on its way to a second post. The two
# measures disagree on purpose: only the corners beside this pole are the coil
# an orbit round this pole could take off.
func _coil_plus_far_coil(pole: Vector2, sense: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	var far := pole + Vector2(-360.0, 0.0)
	# a longer, tighter coil the other way, a long way off
	for k in range(10):
		out.append(far + Vector2(18.0, 0.0).rotated(-sense * 1.0 * float(k)))
	# then four points beside the pole, wound `sense`
	for k in range(4):
		out.append(pole + Vector2(13.0, 0.0).rotated(sense * 0.5 * float(k)))
	return out


# A tail that turns a great deal, none of it beside `pole`: the two corners
# that ARE beside it are equal and opposite by construction, so the coil here
# cancels exactly. Built from direction steps, so the cancellation is exact
# rather than approximately so.
func _cancelling_tail(pole: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	var far := pole + Vector2(-340.0, 0.0)
	var d := Vector2(26.0, 0.0)
	var p := far
	out.append(p)
	for k in range(3):
		d = d.rotated(1.9)
		p += d
		out.append(p)
	var step := Vector2(40.0, 0.0)
	var p1 := pole + Vector2(-14.0, -14.0)
	var d1 := step.rotated(0.9)
	out.append(p1 - step)
	out.append(p1)
	out.append(p1 + d1)
	out.append(p1 + d1 + step)
	out.append(p1 + d1 + step + step)
	return out


# The measure is the coil AT this pole. Independent geometry: a tail wound one
# way beside the pole and harder the other way further along, so the tail's
# own total turning has the opposite sign. The probe must follow the near
# corners, because they are the only turning an orbit round this pole unwinds.
func _the_coil_here_outvotes_the_rest_of_the_tail() -> void:
	var l := _bare_leash()
	var pole := Vector2(-220.0, 410.0)
	if not (l.has_method("unwind_bias_of") and l.has_method("pole_winding")):
		_check(false, "the rope exposes a pure unwind probe (pole_winding/unwind_bias_of)")
		l.queue_free()
		return
	for sense: float in [1.0, -1.0]:
		var tail := _coil_plus_far_coil(pole, sense)
		var all := _tail_turning(tail)
		var near: float = l.pole_winding(tail, pole)
		# the geometry really does disagree with itself, or this proves nothing
		_check(signf(all) == -sense and absf(all) > 1.0,
			"the far coil outweighs the near one in the tail's own total (%.3f rad)" % all)
		_check(signf(near) == sense and absf(near) > 0.5,
			"but the measure reads the coil beside the pole (%.3f rad)" % near)
		var bias: float = l.unwind_bias_of(near, PROBE)
		_check(signf(bias) == -sense,
			"so the probe unwinds THAT coil (bias %.4f)" % bias)
		_check(signf(bias) != signf(l.unwind_bias_of(all, PROBE)),
			"and sends her the opposite way to the tail's total (%.4f)" % l.unwind_bias_of(all, PROBE))
		var dir := 1.0 if bias >= 0.0 else -1.0
		_check(absf(near + dir * PROBE) < absf(near),
			"the committed step leaves less of the coil here (%.4f from %.4f)"
				% [absf(near + dir * PROBE), absf(near)])
	l.queue_free()


# the turning at the corners from `from_i` to `to_i` of a tail: the test's own
# expectation, taken by index rather than by distance, so it cannot drift along
# with whatever the implementation decides "beside the pole" means
func _turning_at(p: Array[Vector2], from_i: int, to_i: int) -> float:
	var total := 0.0
	for i in range(from_i, to_i + 1):
		var a := p[i] - p[i - 1]
		var b := p[i + 1] - p[i]
		if a.length_squared() > 0.01 and b.length_squared() > 0.01:
			total += a.angle_to(b)
	return total


# A tail of two arcs round `pole` turning opposite ways: four points at OUT_R,
# four at IN_R, and her hand HAND_GAP out. Corners 1..3 are the far arc's,
# 4..7 the near one's.
func _two_arc_tail(pole: Vector2, sense: float) -> Array[Vector2]:
	var tail: Array[Vector2] = []
	for k in range(4):
		tail.append(pole + Vector2(OUT_R, 0.0).rotated(-sense * (2.0 + 0.55 * float(k))))
	for k in range(4):
		tail.append(pole + Vector2(IN_R, 0.0).rotated(sense * (0.3 + 0.55 * float(k))))
	tail.append(pole + Vector2(HAND_GAP, 0.0).rotated(sense * 2.5))
	return tail


# a real rope posed around a crafted tail: the earlier points parked far enough
# away that nothing about them can reach the measure
func _posed_tail(pole: Vector2, tail: Array[Vector2]) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for k in range(PTS - tail.size()):
		out.append(pole + Vector2(-900.0 - 12.0 * float(k), 0.0))
	out.append_array(tail)
	return out


# The reach is computed, not fixed, so its boundary needs pinning on both sides:
# a coil just inside the gap out to her hand is hers to unwind, and an arc
# further out than that is the rope on its way somewhere else. The distances are
# absolute on purpose - a test that placed them FROM the computed reach would
# follow the margin wherever it went and prove nothing about it.
func _the_reach_is_the_gap_out_to_her_hand() -> void:
	var l := _bare_leash()
	if not (l.has_method("coil_reach_for") and l.has_method("coil_winding")):
		_check(false, "the rope can say how far out the coil at a pole reaches, and what it is")
		l.queue_free()
		return
	var pole := Vector2(120.0, -80.0)
	var reach: float = l.coil_reach_for(HAND_GAP)
	_check(reach > HAND_GAP + 3.0 and reach < OUT_R - 3.0,
		"the reach runs past her hand and stops short of the arc beyond it (%.1f px, hand %.0f, far arc %.0f)"
			% [reach, HAND_GAP, OUT_R])
	_check(l.coil_reach_for(0.0) >= COIL_REACH,
		"a hand against the pole still has the coil beside it to read (%.1f px)" % l.coil_reach_for(0.0))
	_check(l.coil_reach_for(HAND_GAP) == reach, "and the reach is the same answer every time")
	# A second gap, well clear of the floor, pins the rate as well as the one
	# point: a hand twice as far out reaches exactly that much further, so a
	# reach that grew faster or slower than her arm would be caught even where
	# it happened to land inside the window above.
	var far_reach: float = l.coil_reach_for(2.0 * HAND_GAP)
	_check(absf(far_reach - reach - HAND_GAP) < 0.001,
		"a hand %.0f px further out reaches %.0f px further (%.1f px against %.1f)"
			% [HAND_GAP, HAND_GAP, far_reach, reach])
	_check(far_reach > 2.0 * HAND_GAP + 3.0 and far_reach < FAR_ARC - 3.0,
		"and from there it still clears her hand and stops short of an arc %.0f px out (%.1f px)"
			% [FAR_ARC, far_reach])
	for sense: float in [1.0, -1.0]:
		var tail := _two_arc_tail(pole, sense)
		var inside := _turning_at(tail, 4, 7)
		var outside := _turning_at(tail, 1, 3)
		_check(tail[7].distance_to(pole) < reach and tail[3].distance_to(pole) > reach,
			"the near arc is inside the reach and the far one is outside it")
		_check(signf(inside) == sense and absf(inside) > 1.0,
			"the near arc turns her way (%.3f rad)" % inside)
		_check(signf(outside) == -sense and absf(outside) > 1.0,
			"and the far one turns the other way, by enough to be noticed (%.3f rad)" % outside)
		l.pts = _posed_tail(pole, tail)
		var got: float = l.coil_winding(pole)
		_check(absf(got - inside) < 0.001,
			"the coil at the pole is the near arc and nothing else (%.3f rad, near %.3f, far %.3f)"
				% [got, inside, outside])
		_check(absf(got - (inside + outside)) > 1.0,
			"and plainly not both arcs (%.3f rad, both would be %.3f)" % [got, inside + outside])
		_check(signf(_bias_at(l, pole)) == -sense, "so the probe unwinds the near arc")
	l.queue_free()


# An ideal circular arc round `pole`: `n` points on a circle of radius `r`,
# `step` radians apart. Each chord of a circular arc lies at the angle of the
# arc's midpoint between its ends, so consecutive chords differ by exactly the
# angular step, and a polyline of n points has n - 2 corners to turn at. The
# arc's turning is therefore (n - 2) * step - authored geometry, worked out from
# the circle, with no reference to how anything measures it.
func _arc_tail(pole: Vector2, r: float, step: float, n: int) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for k in range(n):
		out.append(pole + Vector2(r, 0.0).rotated(step * float(k)))
	return out


# The coil's SIZE is what the orbit's length is now taken from, so the measure
# owes an answer in radians, not just a way round. Authored arcs of known sweep,
# at several sizes and both ways, every point of them well inside the reach its
# own hand implies.
func _a_coil_is_worth_what_it_sweeps() -> void:
	var l := _bare_leash()
	var pole := Vector2(-40.0, 210.0)
	for sense: float in [1.0, -1.0]:
		for step: float in [0.25, 0.6, 0.9, 1.5, 2.4, 3.0]:
			var tail := _arc_tail(pole, ARC_R, sense * step, TAIL_PTS)
			l.pts = _posed_tail(pole, tail)
			var want := float(TAIL_PTS - 2) * step
			var got: float = l.coil_winding(pole)
			_check(absf(absf(got) - want) < TOL_RAD and signf(got) == sense,
				"an arc of %d corners stepped %.2f turns %.4f rad (measured %.4f)"
					% [TAIL_PTS - 2, step, want, got])
			_check(absf(_turns_at(l, pole) - want / TAU) < TOL_RAD,
				"which is %.4f turns of orbit to take off (measured %.4f)"
					% [want / TAU, _turns_at(l, pole)])
			_check(_turns_at(l, pole) <= CEILING_TURNS + TOL_RAD,
				"and never more than the window can hold (%.4f turns)" % CEILING_TURNS)
	# The window's ceiling, stated outright: seven corners, and no corner can
	# read past half a turn. Beyond it a coil is not merely clipped, it is
	# misread - an arc of four turns over nine points steps more than half a
	# turn at a time, which is the same as stepping the shortfall backwards, and
	# reads as three turns the OTHER way. No rope reaches it: a coil that tight
	# needs its points closer together than the pole is wide, and the solver
	# holds them off the pole by the pad. It is the small end of this range that
	# a real coil lives at, which is why the budget saturates long before the
	# four-turn clamp in start_whirl can ever bind.
	var alias := _arc_tail(pole, ARC_R, 4.0 * TAU / float(TAIL_PTS - 2), TAIL_PTS)
	l.pts = _posed_tail(pole, alias)
	_check(absf(float(l.coil_winding(pole)) + 3.0 * TAU) < TOL_RAD,
		"a coil of four turns over nine points reads as three the other way (%.4f rad)"
			% float(l.coil_winding(pole)))
	_check(absf(_turns_at(l, pole) - 3.0) < TOL_RAD,
		"so its size is misread too, and still inside the ceiling (%.4f turns)"
			% _turns_at(l, pole))
	l.queue_free()


# A coil somewhere else is not this pole's, and neither is one that cancels:
# both are no opinion at all. The whole tail's turning is the measure this
# exists to avoid, so it must never stand in for a missing one.
func _a_coil_somewhere_else_is_not_this_poles() -> void:
	var l := _bare_leash()
	var pole := Vector2(90.0, -140.0)
	if not (l.has_method("unwind_bias_of") and l.has_method("pole_winding")):
		_check(false, "the rope exposes a pure unwind probe (pole_winding/unwind_bias_of)")
		l.queue_free()
		return
	var elsewhere := _coil(pole + Vector2(-340.0, 0.0), 1.0)
	var all := _tail_turning(elsewhere)
	_check(absf(all) > 1.0, "a tail wound hard round a DIFFERENT post turns a lot (%.3f rad)" % all)
	var far: float = l.pole_winding(elsewhere, pole)
	_check(far == 0.0, "but this pole reads none of it (%.7f rad)" % far)
	_check(l.unwind_bias_of(far, PROBE) == 0.0, "so the probe has no opinion here")
	var mixed := _cancelling_tail(pole)
	var mixed_all := _tail_turning(mixed)
	# the premise, in distances: two corners beside the pole, nothing else
	_check(mixed[5].distance_to(pole) < COIL_REACH and mixed[6].distance_to(pole) < COIL_REACH,
		"the two cancelling corners really are beside the pole")
	_check(mixed[4].distance_to(pole) > COIL_REACH and mixed[7].distance_to(pole) > COIL_REACH,
		"and their neighbours are not")
	_check(absf(mixed_all) > 1.0,
		"a tail whose corners beside the pole cancel can still turn a lot elsewhere (%.3f rad)" % mixed_all)
	var cancelled: float = l.pole_winding(mixed, pole)
	_check(absf(cancelled) < 1.0e-5,
		"and the coil here reads as nothing (%.9f rad)" % cancelled)
	_check(absf(cancelled) < absf(mixed_all) * 0.01,
		"never the tail's own total (%.9f of %.3f)" % [cancelled, mixed_all])
	_check(l.unwind_bias_of(cancelled, PROBE) == 0.0, "which is no opinion either")
	l.queue_free()


# the whirl's direction comes from a tiny virtual step each way round the
# pole, measured against the rope's human-end geometry alone
func _probe_picks_the_unwinding_way() -> void:
	var l := _bare_leash()
	var pole := Vector2(140.0, -60.0)
	if not (l.has_method("unwind_bias_of") and l.has_method("pole_winding")):
		_check(false, "the rope exposes a pure unwind probe (pole_winding/unwind_bias_of)")
		return
	for sense: float in [1.0, -1.0]:
		var coil := _coil(pole, sense)
		var w: float = l.pole_winding(coil, pole)
		_check(signf(w) == sense, "the coil's own turning reads its way round (%.3f rad)" % w)
		var bias: float = l.unwind_bias_of(w, PROBE)
		_check(signf(bias) == -sense,
			"a tail wound %s unwinds the other way (bias %.4f)" % ["anticlockwise" if sense > 0.0 else "clockwise", bias])
		# and the committed step really is the one that leaves less winding
		var dir := 1.0 if bias >= 0.0 else -1.0
		_check(absf(w + dir * PROBE) < absf(w) and absf(w + dir * PROBE) < absf(w - dir * PROBE),
			"the committed step reduces the local winding (%.4f from %.4f, other way %.4f)"
				% [absf(w + dir * PROBE), absf(w), absf(w - dir * PROBE)])
		_check(l.unwind_bias_of(w, PROBE) == bias, "the probe is deterministic")
	# a tail wound neither way has no opinion, and the tie commits anticlockwise
	var w0: float = l.pole_winding(_spoke(pole), pole)
	var bias0: float = l.unwind_bias_of(w0, PROBE)
	_check(absf(bias0) < 1.0e-5, "a tail wound neither way reads as no bias (%.7f)" % bias0)
	_check(bias0 >= 0.0, "and the tie commits anticlockwise")
	l.queue_free()


# the probe must read the same window the rope's own human_end_winding() does,
# and agree with it on a cleanly wound rope
func _probe_agrees_with_a_real_rope() -> void:
	var leash := _bare_leash()
	var dog := Node2D.new()
	var human := Node2D.new()
	root.add_child(dog)
	root.add_child(human)
	root.add_child(leash)
	var near := Vector2.ZERO
	human.global_position = Vector2(-40.0, 30.0)
	dog.global_position = Vector2(-60.0, -40.0)
	var poles: Array[Vector2] = [near]
	leash.setup(dog, human, poles, 260.0)
	for i in range(540):
		var a := deg_to_rad(float(i))
		dog.global_position = near + Vector2(-40.0, 0.0).rotated(-a)
		leash.tick(DT)
	if not (leash.has_method("human_tail") and leash.has_method("unwind_bias_of")
			and leash.has_method("pole_winding")):
		_check(false, "the rope exposes its human-end tail and the probe over it")
	else:
		var tail: PackedVector2Array = leash.human_tail()
		var n: int = leash.pts.size()
		_check(tail.size() == TAIL_PTS, "the human-end tail is the last %d points (%d)" % [TAIL_PTS, tail.size()])
		_check(tail[tail.size() - 1] == leash.pts[n - 1] and tail[0] == leash.pts[n - TAIL_PTS],
			"and it is exactly the rope's own last %d points" % TAIL_PTS)
		var pole: Vector2 = leash.human_contact_pole
		var bias: float = _bias_at(leash, pole)
		# and it must pick the way that really does unwind this rope: walk the
		# hand round the pole each way, free-slipping as a whirl does, and see
		# which way takes turns off the rope. winding() is the measure, because
		# it is the one arming hands the orbit as its budget.
		var pts0: Array[Vector2] = leash.pts.duplicate()
		var prev0: Array[Vector2] = leash.prev.duplicate()
		var hp: Vector2 = human.global_position
		var acw := _unwind_by(leash, human, pole, 1.0, pts0, prev0, hp)
		var cw := _unwind_by(leash, human, pole, -1.0, pts0, prev0, hp)
		var want := 1.0 if acw > cw else -1.0
		# an oracle that cannot tell the two ways apart has nothing to say, so
		# it may not be read as a verdict
		_check(absf(acw - cw) > 0.02,
			"the two ways round really do differ on this rope (%.3f vs %.3f turns)" % [acw, cw])
		_check(bias != 0.0 and signf(bias) == want,
			"the probe picks the way that really unwinds the rope (bias %.4f, anticlockwise took off %.3f turns, clockwise %.3f)"
				% [bias, acw, cw])
	leash.queue_free()
	dog.queue_free()
	human.queue_free()


# Walk the hand round the pole the way a whirl would - same radius, rope
# free-slipping - and report how many turns that took off the rope.
func _unwind_by(leash: Node2D, human: Node2D, pole: Vector2, dir: float,
		pts0: Array[Vector2], prev0: Array[Vector2], hp: Vector2) -> float:
	leash.pts = pts0.duplicate()
	leash.prev = prev0.duplicate()
	human.global_position = hp
	var before := absf(float(leash.winding()))
	var r := hp.distance_to(pole)
	var a0 := (hp - pole).angle()
	for i in range(90):
		leash.free_slip_t = 0.7
		human.global_position = pole + Vector2.from_angle(a0 + dir * 0.05 * float(i + 1)) * r
		leash.tick(DT)
	return before - absf(float(leash.winding()))


# Two posts, wound opposite ways: her end round one, the dog's end harder
# round the other, so the WHOLE rope's winding reads the opposite way to the
# coil she is actually standing in. The orbit is hers, so the probe must
# follow her coil - this is the failure the old mid-orbit guard was built on.
func _the_probe_follows_her_end_not_the_whole_rope() -> void:
	for sense: float in [1.0, -1.0]:
		var leash := _bare_leash()
		var dog := Node2D.new()
		var human := Node2D.new()
		root.add_child(dog)
		root.add_child(human)
		root.add_child(leash)
		var hers := Vector2.ZERO
		var his := Vector2(0.0, -420.0)
		var poles: Array[Vector2] = [hers, his]
		leash.setup(dog, human, poles, 900.0)
		# Posed rather than wound by circling the ends: a rope stretched thin
		# enough to wind both ends hard is also one that is slipping at both,
		# and what it settles into is nobody's idea of a fixture. This is the
		# shape, laid out point by point - his end coiled hard one way round
		# his post, hers coiled the other way round hers.
		var n: int = leash.pts.size()
		var posed: Array[Vector2] = []
		for k in range(10):
			posed.append(his + Vector2(16.0, 0.0).rotated(-sense * 0.9 * float(k)))
		var run := n - 19
		for k in range(run):
			posed.append(his.lerp(hers, 0.25 + 0.6 * float(k) / float(maxi(run - 1, 1))))
		for k in range(TAIL_PTS):
			posed.append(hers + Vector2(13.0, 0.0).rotated(sense * 0.45 * float(k)))
		_check(posed.size() == n, "the posed rope is the rope's own length (%d of %d)" % [posed.size(), n])
		leash.pts = posed
		leash.prev = posed.duplicate()
		dog.global_position = posed[0]
		human.global_position = posed[n - 1] - Vector2(9.0, -16.0)
		if not (leash.has_method("unwind_bias_of") and leash.has_method("pole_winding")
				and leash.has_method("human_tail")):
			_check(false, "the rope exposes its human-end tail and the probe over it")
		else:
			var tail: PackedVector2Array = leash.human_tail()
			var local: float = leash.pole_winding(tail, hers)
			var global_w: float = leash.winding()
			# the test's own premise, checked before anything is concluded
			_check(absf(local) > 1.0 and absf(global_w) > 0.35
					and signf(local) == -signf(global_w),
				"her coil and the whole rope's winding disagree (local %.3f rad, rope %.3f turns)"
					% [local, global_w])
			var bias: float = _bias_at(leash, hers)
			_check(bias != 0.0 and signf(bias) == -signf(local),
				"the probe unwinds the coil she is standing in (bias %.4f, coil %.3f rad)" % [bias, local])
			_check(signf(bias) != -signf(global_w),
				"not the one the whole rope's winding would have picked (%+.0f)" % -signf(global_w))
			# and walking her hand round really does take her coil off that way
			var pts0: Array[Vector2] = leash.pts.duplicate()
			var prev0: Array[Vector2] = leash.prev.duplicate()
			var hp: Vector2 = human.global_position
			var acw := _uncoil_by(leash, human, hers, 1.0, pts0, prev0, hp)
			var cw := _uncoil_by(leash, human, hers, -1.0, pts0, prev0, hp)
			_check(absf(acw - cw) > 0.02,
				"the two ways round her post really do differ (%.3f vs %.3f rad)" % [acw, cw])
			_check(signf(bias) == (1.0 if acw > cw else -1.0),
				"which is the way the probe chose (bias %.4f, anticlockwise took off %.3f rad, clockwise %.3f)"
					% [bias, acw, cw])
		leash.queue_free()
		dog.queue_free()
		human.queue_free()


# Walk the hand round `pole` the way a whirl would and report how much of HER
# coil at that pole it took off - the local question, which is the one the
# probe answers when the far end of the rope is wound somewhere else.
func _uncoil_by(leash: Node2D, human: Node2D, pole: Vector2, dir: float,
		pts0: Array[Vector2], prev0: Array[Vector2], hp: Vector2) -> float:
	leash.pts = pts0.duplicate()
	leash.prev = prev0.duplicate()
	human.global_position = hp
	var before := absf(float(leash.pole_winding(leash.human_tail(), pole)))
	var r := hp.distance_to(pole)
	var a0 := (hp - pole).angle()
	for i in range(90):
		leash.free_slip_t = 0.7
		human.global_position = pole + Vector2.from_angle(a0 + dir * 0.05 * float(i + 1)) * r
		leash.tick(DT)
	return before - absf(float(leash.pole_winding(leash.human_tail(), pole)))


# a whirl may only orbit a real pole: furniture and anything that is not in
# the pole list at all unwind nothing (La Rambla's terrace loop)
func _only_real_poles_can_be_orbited() -> void:
	var l := _bare_leash()
	var post := Vector2(0.0, 0.0)
	var table := Vector2(100.0, 0.0)
	var poles: Array[Vector2] = [post, table]
	var furn: Array[Vector2] = [table]
	l.poles = poles
	l.furniture_poles = furn
	if not l.has_method("is_real_pole"):
		_check(false, "the rope can say whether a point is still a real pole")
	else:
		_check(l.is_real_pole(post), "a pole in the list is a real pole")
		_check(not l.is_real_pole(table), "a cafe table is not")
		_check(not l.is_real_pole(Vector2(50.0, 0.0)), "nor is a point that is in no list")
		_check(not l.is_real_pole(Vector2(INF, INF)), "nor is nowhere")
	l.queue_free()


func _run() -> void:
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	_arming_is_wired_to_the_probe(m)
	_the_budget_is_her_coil_too(m)
	_the_budget_is_the_whole_window(m)
	_a_contested_coil_is_worth_only_its_net(m)
	_a_cancelling_window_is_worth_nothing(m)
	_an_exact_tie_keeps_her_going_round(m)
	_a_window_that_dies_leaves_nothing_behind(m)
	_the_budget_keeps_its_bounds(m)
	_a_tie_keeps_her_going_the_way_she_is(m)
	_direction_is_committed(m)
	_the_tug_cannot_move_a_whirling_owner(m)
	_release_aims_at_the_dog(m)
	_the_ordinary_release_is_the_tangent_itself(m)
	_missed_tangent_still_throws_dogward(m)
	_no_dogward_fling_means_no_fling(m)
	_a_fling_with_nowhere_to_go_is_a_stagger(m)
	_release_never_fires_away_from_the_dog(m)
	_pull_drives_spin_up_and_release(m)
	_timeout_stumbles_under_control(m)
	_a_pole_that_runs_away_does_not_drag_her(m)
	_a_bail_in_her_tick_is_still_a_whirl_to_main(m)
	_the_way_out_always_leaves_the_rope_slipping(m)
	_a_bail_off_the_leash_does_not_leak(m)
	_a_fling_off_the_leash_is_still_paid_for(m)
	_main_abandons_an_orbit_round_a_non_pole(m)
	_a_nowhere_pole_is_refused(m)
	m.queue_free()
	await process_frame
	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_whirl_guided: OK")
		quit(0)
	else:
		quit(1)


# put the rope on one pole only, so the test's geometry is the whole story
func _one_pole(m: Node2D, pole: Vector2) -> void:
	var poles: Array[Vector2] = [pole]
	var furn: Array[Vector2] = []
	m.leash.poles = poles
	m.leash.furniture_poles = furn


# Wind the rope on a pole at her elbow and leave it far too short for where
# the ends are: a wound, overstretched rope round a real pole, which is the
# whole arming condition and also the state the tug must not be allowed to
# touch while she orbits. Callers restore m.leash_len.
func _taut_orbit(m: Node2D, pole: Vector2, turns := 2.0) -> void:
	var h: CharacterBody2D = m.human
	var d: Node2D = m.dog
	var leash: Node2D = m.leash
	_one_pole(m, pole)
	h.global_position = pole + Vector2(-46.0, 0.0)
	d.global_position = pole + Vector2(-40.0, 0.0)
	leash.resnap()
	for i in range(540):
		var a := deg_to_rad(float(i))
		d.global_position = pole + Vector2(-40.0, 0.0).rotated(-a)
		leash.tick(DT)
	m.leash_len = maxf(float(leash.used_length()) - 160.0, 40.0)
	h.velocity = Vector2(0.0, -120.0)
	h.start_whirl(pole, 1.0, turns)


# WIRING, not correctness: that main's arming hands the orbit the direction
# the rope's own probe asked for, over the window it asked across. Whether the
# probe is RIGHT is settled by the pure tests and the rope oracle above - this
# one only proves nothing else gets to decide. Nothing moves during the window,
# so the probe's sign is sampled every frame and must be the same one
# throughout; a sum of same-signed frames is that sign.
func _arming_is_wired_to_the_probe(m: Node2D) -> void:
	var h: CharacterBody2D = m.human
	var d: Node2D = m.dog
	var leash: Node2D = m.leash
	var pole: Vector2 = h.global_position + Vector2(300.0, 0.0)
	_one_pole(m, pole)
	h.global_position = pole + Vector2(-46.0, 0.0)
	d.global_position = pole + Vector2(-40.0, 0.0)
	leash.resnap()
	for i in range(540):
		var a := deg_to_rad(float(i))
		d.global_position = pole + Vector2(-40.0, 0.0).rotated(-a)
		leash.tick(DT)
	_check(leash.human_contact_is_pole and leash.human_contact_pole.distance_to(pole) < 1.0,
		"the owner's end is wound on the test pole")
	# the owner's reel takes up the slack: now the wound rope is taut
	var was_len: float = m.leash_len
	m.leash_len = float(leash.used_length()) - 20.0
	var early := false
	var frames := 0
	var want := 0.0
	var wavered := false
	while not h.is_whirling() and frames < 40:
		var s := signf(_bias_at(leash, pole))
		if s != 0.0:
			if want == 0.0:
				want = s
			elif s != want:
				wavered = true
		m._apply_leash(DT)
		frames += 1
		if h.is_whirling() and frames < 12:
			early = true
	_check(h.is_whirling(), "a taut wound rope round a pole arms an orbit (%d frames)" % frames)
	_check(not early, "but never before the arming window is out (%d frames)" % frames)
	_check(h.whirl_pole.distance_to(pole) < 1.0, "round the pole the rope is wound on")
	_check(want != 0.0 and not wavered,
		"the probe asked for the same way every frame of the window (%+.0f)" % want)
	_check(h.whirl_dir == want, "and that is the way the orbit committed to (%+.0f)" % want)
	m.leash_len = was_len
	h.bail_whirl()
	m._apply_leash(DT)


# Pose the game's own rope: her coil round the post at her elbow one way, and a
# tighter loop the other way where the rope has doubled back on itself up the
# way. The whole rope's winding is then the wrong SIGN and the wrong SIZE for
# the coil she is standing in, so both halves of the arming decision - which way,
# and how far - have to come from hers, or an orbit sized by the whole rope keeps
# going after her coil is spent and winds it up again the other way.
func _two_coil_rope(m: Node2D, hers: Vector2, sense: float, coil_mul := 1.0) -> void:
	var leash: Node2D = m.leash
	var poles: Array[Vector2] = [hers]
	var furn: Array[Vector2] = []
	leash.poles = poles
	leash.furniture_poles = furn
	# Every chord is the rope's own segment length, so the pose is a rope at
	# rest rather than a shape the solver has to fight: a coil's radius is then
	# what sets how hard it turns, and the two coils can be given different
	# amounts of winding without either being stretched.
	var seg: float = float(leash.rest_len) / float(PTS - 1)
	var r_hers := maxf(PAD - 1.0, seg * 0.55)
	var r_far := maxf(FAR_R, seg * 0.55)
	# coil_mul winds her coil tighter or looser than the rest at the same radius,
	# which is how a fixture can change the size of her coil while it arms
	var step_hers := 2.0 * asin(minf(seg / (2.0 * r_hers), 1.0)) * coil_mul
	var step_far := 2.0 * asin(minf(seg / (2.0 * r_far), 1.0))
	var far_c := hers + Vector2(0.0, -6.5 * seg - r_far - r_hers)
	var posed: Array[Vector2] = []
	# the rope doubled back on itself up the way: turning the whole rope's
	# winding counts and an orbit at her pole cannot take off
	for k in range(10):
		posed.append(far_c + Vector2(r_far, 0.0).rotated(-sense * step_far * float(k)))
	var coil: Array[Vector2] = []
	for k in range(TAIL_PTS):
		coil.append(hers + Vector2(r_hers, 0.0).rotated(sense * step_hers * float(k)))
	var run := PTS - 10 - TAIL_PTS
	for k in range(run):
		posed.append(posed[9].lerp(coil[0], float(k + 1) / float(run + 1)))
	posed.append_array(coil)
	leash.pts = posed
	leash.prev = posed.duplicate()
	m.dog.global_position = posed[0]
	m.human.global_position = posed[PTS - 1] - Vector2(9.0, -16.0)


func _the_budget_is_her_coil_too(m: Node2D) -> void:
	var h: CharacterBody2D = m.human
	var leash: Node2D = m.leash
	if not leash.has_method("coil_winding"):
		_check(false, "the rope can say how many turns the coil at a pole is worth")
		return
	for sense: float in [1.0, -1.0]:
		var was_len: float = m.leash_len
		var hers: Vector2 = h.global_position + Vector2(200.0, 0.0)
		h.rotation = 0.0
		h.velocity = Vector2.ZERO
		_two_coil_rope(m, hers, sense)
		m.leash_len = maxf(float(leash.used_length()) - 60.0, 40.0)
		# one frame first, so the measures below are the ones main's arming
		# reads: the pose as the solver leaves it, not as it was built
		m._apply_leash(DT)
		var local: float = leash.coil_winding(hers)
		var turns: float = _turns_at(leash, hers)
		var rope: float = leash.winding()
		# the premise: the two measures disagree both ways round, and by enough
		# that a budget taken from the wrong one is a different orbit
		_check(signf(local) == -signf(rope) and absf(turns - absf(rope)) > 0.25,
			"her coil and the whole rope disagree on way and size (coil %.2f turns, rope %.2f)"
				% [turns, absf(rope)])
		# Re-posed before each frame: the fixture is the geometry, not whatever
		# a dozen frames of solving a hand-built rope makes of it. main's own
		# arming runs for real on it.
		var frames := 0
		while not h.is_whirling() and frames < 40:
			_two_coil_rope(m, hers, sense)
			m._apply_leash(DT)
			frames += 1
		_check(h.is_whirling(), "a rope wound at both ends still arms an orbit (%d frames)" % frames)
		if h.is_whirling():
			_check(h.whirl_pole.distance_to(hers) < 1.0,
				"round the pole she is actually standing in, %s" % str(h.whirl_pole))
			_check(h.whirl_dir == -signf(local),
				"round her coil's way (%+.0f, coil %.2f rad)" % [float(h.whirl_dir), local])
			var want := clampf(turns, TURNS_MIN, TURNS_MAX) * TAU
			_check(absf(float(h.whirl_turns) - want) < 0.05,
				"for as many turns as HER coil is worth (%.2f rad, wanted %.2f)" % [float(h.whirl_turns), want])
			var wrong := clampf(absf(rope), TURNS_MIN, TURNS_MAX) * TAU
			_check(absf(float(h.whirl_turns) - wrong) > 0.5,
				"not as many as the whole rope's winding (%.2f rad)" % wrong)
		m.leash_len = was_len
		h.bail_whirl()
		m._apply_leash(DT)


# One window, not one frame. The direction is summed over the whole quarter
# second of arming so a single noisy frame cannot decide it, and the size has to
# be read the same way or the orbit's length is still a coin toss - whatever her
# coil happened to be on the frame the window filled up. The fixture winds her
# coil a little looser every frame: deterministic, the same every run, and never
# twice the same, so an average over the window is a different number from the
# last frame's and the two cannot be confused.
func _the_budget_is_the_whole_window(m: Node2D) -> void:
	var h: CharacterBody2D = m.human
	var leash: Node2D = m.leash
	var was_len: float = m.leash_len
	var runs: Array[float] = []
	var seen: Array[float] = []
	for attempt in range(2):
		var hers: Vector2 = h.global_position + Vector2(200.0, 0.0)
		h.rotation = 0.0
		h.velocity = Vector2.ZERO
		_two_coil_rope(m, hers, 1.0)
		m.leash_len = maxf(float(leash.used_length()) - 60.0, 40.0)
		seen = []
		var arm_was := 0.0
		var frames := 0
		while not h.is_whirling() and frames < 40:
			_two_coil_rope(m, hers, 1.0, 1.0 - 0.02 * float(frames))
			m._apply_leash(DT)
			# the frames main counted: the ones its own window grew on, and the
			# one it armed on (which resets the window as it fires)
			var arm_now: float = m.whirl_arm
			if arm_now > arm_was or h.is_whirling():
				seen.append(_turns_at(leash, hers))
			arm_was = arm_now
			frames += 1
		_check(h.is_whirling(), "a coil that changes while it arms still arms (%d frames)" % frames)
		if h.is_whirling():
			runs.append(float(h.whirl_turns))
		m.leash_len = was_len
		h.bail_whirl()
		m._apply_leash(DT)
	if seen.size() < 2 or runs.size() < 2:
		return
	var mean := 0.0
	for v: float in seen:
		mean += v
	mean /= float(seen.size())
	var last: float = seen[seen.size() - 1]
	var first: float = seen[0]
	_check(seen.size() >= 10, "the window is many frames of coil, not one (%d)" % seen.size())
	_check(absf(first - last) > 0.1,
		"and her coil really does change across it (%.3f turns to %.3f)" % [first, last])
	_check(absf(runs[0] - clampf(mean, TURNS_MIN, TURNS_MAX) * TAU) < 0.002,
		"the orbit is as long as the coil averaged over the window (%.3f rad, wanted %.3f)"
			% [runs[0], clampf(mean, TURNS_MIN, TURNS_MAX) * TAU])
	_check(absf(runs[0] - clampf(last, TURNS_MIN, TURNS_MAX) * TAU) > 0.1,
		"not as long as the frame it happened to arm on (%.3f rad)"
			% [clampf(last, TURNS_MIN, TURNS_MAX) * TAU])
	# The second run is the same fixture from a slightly different standing
	# start, so this is the average being stable, not the rope being bit-exact.
	_check(absf(runs[0] - runs[1]) < 0.001,
		"and the same coil armed twice gives the same orbit (%.6f, %.6f)" % [runs[0], runs[1]])


# Drive main's own arming on the two-coil rope with one authored sense per frame,
# and hand back the coil main read on each frame it counted - signed, which is
# what a contested window turns on.
func _arm_through(m: Node2D, hers: Vector2, senses: Array[float]) -> Array[float]:
	var h: CharacterBody2D = m.human
	var leash: Node2D = m.leash
	var seen: Array[float] = []
	var arm_was := 0.0
	var frames := 0
	while not h.is_whirling() and frames < 60:
		_two_coil_rope(m, hers, senses[frames % senses.size()])
		m._apply_leash(DT)
		# the frames main counted: the ones its own window grew on, and the one
		# it armed on, which resets the window as it fires
		var arm_now: float = m.whirl_arm
		if arm_now > arm_was or h.is_whirling():
			seen.append(float(leash.coil_winding(hers)))
		arm_was = arm_now
		frames += 1
	return seen


# A window where her coil keeps changing its mind. Summing which WAY each frame
# votes while averaging how MUCH each frame was wound reads a contested coil as a
# busy one: three frames one way and two the other would send her round for as
# long as a coil that was wound hard one way the whole time. One signed average
# settles both halves - the net is what an orbit can actually take off, and a
# coil that nearly cancels is worth nearly nothing.
func _a_contested_coil_is_worth_only_its_net(m: Node2D) -> void:
	var h: CharacterBody2D = m.human
	var leash: Node2D = m.leash
	var was_len: float = m.leash_len
	for majority: float in [1.0, -1.0]:
		for split: Array in [[3, 2], [4, 1]]:
			var senses: Array[float] = []
			for k in range(int(split[0])):
				senses.append(majority)
			for k in range(int(split[1])):
				senses.append(-majority)
			var hers: Vector2 = h.global_position + Vector2(200.0, 0.0)
			h.rotation = 0.0
			h.velocity = Vector2.ZERO
			_two_coil_rope(m, hers, majority)
			m.leash_len = maxf(float(leash.used_length()) - 60.0, 40.0)
			var seen := _arm_through(m, hers, senses)
			var tag := "%d of every %d her way" % [int(split[0]), int(split[0]) + int(split[1])]
			_check(h.is_whirling(), "a coil that changes its mind still arms (%s)" % tag)
			if h.is_whirling() and seen.size() > 2:
				var net := 0.0
				var gross := 0.0
				var hers_way := 0
				for v: float in seen:
					net += v
					gross += absf(v)
					if signf(v) == majority:
						hers_way += 1
				net /= float(seen.size())
				gross /= float(seen.size())
				var want := clampf(absf(net) / TAU, TURNS_MIN, TURNS_MAX) * TAU
				var busy := clampf(gross / TAU, TURNS_MIN, TURNS_MAX) * TAU
				_check(hers_way > seen.size() - hers_way and hers_way < seen.size(),
					"the window really was contested (%d of %d, %s)" % [hers_way, seen.size(), tag])
				_check(absf(want - busy) > 0.3,
					"and what it netted is not what it was busy doing (%.2f rad against %.2f)"
						% [want, busy])
				_check(h.whirl_dir == -signf(net),
					"she goes the way the net coil unwinds (%+.0f, net %.2f rad)"
						% [float(h.whirl_dir), net])
				_check(absf(float(h.whirl_turns) - want) < 0.002,
					"for as long as the net coil is worth (%.2f rad, wanted %.2f)"
						% [float(h.whirl_turns), want])
				_check(absf(float(h.whirl_turns) - busy) > 0.3,
					"not as long as all that winding added up (%.2f rad)" % busy)
			m.leash_len = was_len
			h.bail_whirl()
			m._apply_leash(DT)


# A coil that spends the window arguing with itself: half the frames each way.
# There is next to nothing left to take off, so there is next to no orbit - the
# shortest one there is - however hard the rope was working while it argued.
func _a_cancelling_window_is_worth_nothing(m: Node2D) -> void:
	var h: CharacterBody2D = m.human
	var leash: Node2D = m.leash
	var was_len: float = m.leash_len
	for first: float in [1.0, -1.0]:
		var hers: Vector2 = h.global_position + Vector2(200.0, 0.0)
		h.rotation = 0.0
		h.velocity = Vector2.ZERO
		_two_coil_rope(m, hers, first)
		m.leash_len = maxf(float(leash.used_length()) - 60.0, 40.0)
		var seen := _arm_through(m, hers, [first, -first] as Array[float])
		_check(h.is_whirling(), "a coil that cancels itself still arms")
		if h.is_whirling() and seen.size() > 2:
			var net := 0.0
			var gross := 0.0
			for v: float in seen:
				net += v
				gross += absf(v)
			net /= float(seen.size())
			gross /= float(seen.size())
			_check(absf(net) < 0.25 * gross,
				"the window all but cancels (net %.2f rad against %.2f of winding)" % [net, gross])
			_check(absf(float(h.whirl_turns) - TURNS_MIN * TAU) < 0.001,
				"so she gets the shortest orbit there is (%.3f rad)" % float(h.whirl_turns))
			_check(float(h.whirl_turns) < clampf(gross / TAU, TURNS_MIN, TURNS_MAX) * TAU - 0.3,
				"and not the long one all that winding would have bought (%.2f rad)"
					% (clampf(gross / TAU, TURNS_MIN, TURNS_MAX) * TAU))
		m.leash_len = was_len
		h.bail_whirl()
		m._apply_leash(DT)


# A window that cancels to EXACTLY nothing cannot be built out of a solved rope -
# two mirrored frames of it never agree to the last bit - so the tie is pinned
# where main decides, with the window's average handed in as the zero it would be.
# Nothing to read is no reason to pick a side out of the air: she keeps going the
# way she is already travelling round the post, for the shortest orbit there is.
func _an_exact_tie_keeps_her_going_round(m: Node2D) -> void:
	var h: CharacterBody2D = m.human
	if not m.has_method("_commit_whirl"):
		_check(false, "main decides the way round and how far in one place")
		return
	var pole: Vector2 = h.global_position + Vector2(60.0, 0.0)
	_one_pole(m, pole)
	for sense: float in [1.0, -1.0]:
		h.global_position = pole + Vector2(-46.0, 0.0)
		var radial: Vector2 = h.global_position - pole
		h.velocity = radial.normalized().rotated(sense * PI / 2.0) * 180.0
		m._commit_whirl(pole, 0.0)
		_check(h.is_whirling(), "an exact tie still starts an orbit")
		_check(h.whirl_dir == sense,
			"the way she was already travelling round it (%+.0f, wanted %+.0f)"
				% [float(h.whirl_dir), sense])
		_check(absf(float(h.whirl_turns) - TURNS_MIN * TAU) < 0.001,
			"for the shortest orbit there is (%.3f rad)" % float(h.whirl_turns))
		h.bail_whirl()
		m._apply_leash(DT)


# The whole rope in a heap on one spot, dog and owner standing on it: there is no
# tangent at either end to pull along. The solver will not hold any less
# degenerate version of this - coincident points next to a rope that has length
# get nudged apart, and the nudge amplifies - so a heap is what the guard is for.
func _no_tangent_rope(m: Node2D, at: Vector2) -> void:
	var leash: Node2D = m.leash
	var poles: Array[Vector2] = []
	var furn: Array[Vector2] = []
	leash.poles = poles
	leash.furniture_poles = furn
	var posed: Array[Vector2] = []
	for k in range(PTS):
		posed.append(at)
	leash.pts = posed
	leash.prev = posed.duplicate()
	m.dog.global_position = at
	m.human.global_position = at - Vector2(9.0, -16.0)


# A window that never finished must leave nothing behind it. The rings she is
# telegraphed with come straight off the timer, and a vault is refused outright
# while one is up, so a window left standing by a tug that went home early would
# both draw rings for an orbit that is not coming and quietly cost her the vault.
# Both of the tug's early ways out therefore drop it on their way.
func _a_window_that_dies_leaves_nothing_behind(m: Node2D) -> void:
	var h: CharacterBody2D = m.human
	var leash: Node2D = m.leash
	if not ("whirl_coil_acc" in m):
		_check(false, "main adds her coil up over the arming window as one signed measure")
		return
	for way: String in ["off the leash", "no pull in the rope"]:
		var was_len: float = m.leash_len
		var hers: Vector2 = h.global_position + Vector2(200.0, 0.0)
		h.rotation = 0.0
		h.velocity = Vector2.ZERO
		_two_coil_rope(m, hers, 1.0)
		m.leash_len = maxf(float(leash.used_length()) - 60.0, 40.0)
		for i in range(6):
			_two_coil_rope(m, hers, 1.0)
			m._apply_leash(DT)
		_check(m.whirl_arm > 0.0 and float(m.whirl_arm_amount()) > 0.0,
			"a window part way up, with its rings drawn (%s: %.3f)" % [way, float(m.whirl_arm)])
		if way == "off the leash":
			leash.detached = true
			m._apply_leash(DT)
			leash.detached = false
		else:
			_no_tangent_rope(m, h.global_position + Vector2(240.0, 0.0))
			# A heap of rope is nothing like taut, so only a reel shorter than
			# nothing gets it past the guard above this one. That is the honest
			# shape of this branch: it is the last line of defence, not a state
			# the walk arrives in.
			m.leash_len = -1.0
			m._apply_leash(DT)
			_check(leash.human_pull_dir() == Vector2.ZERO and float(leash.used_length()) == 0.0,
				"the rope really has no pull in it, and length is not why")
		_check(float(m.whirl_arm) == 0.0, "the timer is dropped (%s)" % way)
		_check(float(m.whirl_coil_acc) == 0.0 and int(m.whirl_arm_n) == 0,
			"and so is the coil it had added up (%s: %.3f over %d)"
				% [way, float(m.whirl_coil_acc), int(m.whirl_arm_n)])
		_check(float(m.whirl_arm_amount()) == 0.0,
			"so nothing is telegraphed for an orbit that is not coming (%s)" % way)
		m.leash_len = was_len


# the budget is still bounded: a coil of nothing is worth a turn and a bit, and
# no coil is worth more than four turns of orbit
func _the_budget_keeps_its_bounds(m: Node2D) -> void:
	var h: CharacterBody2D = m.human
	var pole: Vector2 = h.global_position + Vector2(60.0, 0.0)
	_one_pole(m, pole)
	for pair: Array in [[0.0, TURNS_MIN], [0.01, TURNS_MIN], [99.0, TURNS_MAX], [2.0, 2.0]]:
		h.global_position = pole + Vector2(-46.0, 0.0)
		h.velocity = Vector2(0.0, -120.0)
		h.start_whirl(pole, 1.0, float(pair[0]))
		_check(absf(float(h.whirl_turns) - float(pair[1]) * TAU) < 0.001,
			"a budget of %.2f turns orbits %.2f (%.2f rad)" % [float(pair[0]), float(pair[1]),
				float(h.whirl_turns)])
		h.bail_whirl()
	m._apply_leash(DT)


# Nothing to read is no reason to pick a direction out of the air: a probe
# with no opinion at all leaves her going the way she is already going round
# the pole.
func _a_tie_keeps_her_going_the_way_she_is(m: Node2D) -> void:
	var h: CharacterBody2D = m.human
	if not h.has_method("orbit_sense"):
		_check(false, "the owner can say which way she is already going round a pole")
		return
	_check(h.orbit_sense(Vector2(30.0, 0.0), Vector2(0.0, 40.0)) == 1.0,
		"travelling anticlockwise reads anticlockwise")
	_check(h.orbit_sense(Vector2(30.0, 0.0), Vector2(0.0, -40.0)) == -1.0,
		"and clockwise, clockwise")
	_check(h.orbit_sense(Vector2(0.0, -30.0), Vector2(40.0, 0.0)) == 1.0,
		"wherever round the pole she is")
	_check(h.orbit_sense(Vector2(30.0, 0.0), Vector2.ZERO) == 1.0,
		"standing still is a tie of its own, settled the same way every time")
	_check(h.orbit_sense(Vector2(30.0, 0.0), Vector2(-40.0, 0.0)) == 1.0,
		"as is walking straight at it")


# While she is whirling her motion is the orbit's alone: main's raw tension,
# its separation damping and its geometry cap must not move her by a pixel,
# however far past its length the rope is.
func _the_tug_cannot_move_a_whirling_owner(m: Node2D) -> void:
	var h: CharacterBody2D = m.human
	var leash: Node2D = m.leash
	var was_len: float = m.leash_len
	var pole: Vector2 = h.global_position + Vector2(300.0, 0.0)
	_taut_orbit(m, pole)
	_check(h.is_whirling(), "she is whirling")
	var excess := float(leash.used_length()) - float(m.leash_len)
	var cap := float(m.leash_len) * (STRETCH_CAP - 1.0)
	_check(excess > cap,
		"on a rope stretched past the geometry cap (%.0f px over, cap %.0f)" % [excess, cap])
	var moved := 0.0
	var pushed := 0.0
	var frames := 0
	while h.is_whirling() and frames < 20:
		h.tick(DT)
		frames += 1
		if not h.is_whirling():
			break
		var orbit: Vector2 = h.whirl_pole + Vector2.from_angle(float(h.whirl_angle)) * float(h.whirl_r)
		var v0: Vector2 = h.velocity
		m._apply_leash(DT)
		moved = maxf(moved, h.global_position.distance_to(orbit))
		pushed = maxf(pushed, (h.velocity - v0).length())
	_check(frames > 10, "for frames on end (%d)" % frames)
	_check(moved < 0.001, "and the tug never moves her off the orbit (%.4f px)" % moved)
	_check(pushed < 0.001, "nor adds a thing to her velocity (%.4f px/s)" % pushed)
	m.leash_len = was_len
	h.bail_whirl()
	m._apply_leash(DT)


# Wind the rope hard at the DOG's end, then whirl the owner. Whole-rope
# winding is what the old mid-orbit guard watched: it must no longer be able
# to reverse an orbit in flight or reset its progress.
func _direction_is_committed(m: Node2D) -> void:
	var h: CharacterBody2D = m.human
	var d: Node2D = m.dog
	var leash: Node2D = m.leash
	var pole: Vector2 = h.global_position + Vector2(300.0, 0.0)
	_one_pole(m, pole)
	h.global_position = pole + Vector2(-46.0, 0.0)
	d.global_position = pole + Vector2(-40.0, 0.0)
	leash.resnap()
	for i in range(540):
		var a := deg_to_rad(float(i))
		d.global_position = pole + Vector2(-40.0, 0.0).rotated(-a)
		leash.tick(DT)
	_check(absf(float(leash.winding())) > 0.35,
		"the test rope really is wound (%.2f turns)" % absf(float(leash.winding())))
	h.velocity = Vector2(0.0, -120.0)
	h.start_whirl(pole, 1.0, 2.0)
	_check(h.is_whirling(), "the owner is whirling")
	var dir0: float = h.whirl_dir
	var ang0: float = h.whirl_angle
	var ang: float = ang0
	var budget := 2.0 * TAU
	var best := 0.0
	var turned := false
	var went_back := false
	var slipped := true
	var frames := 0
	while h.is_whirling() and frames < 900:
		h.tick(DT)
		m._apply_leash(DT)
		frames += 1
		if h.is_whirling():
			if h.whirl_dir != dir0:
				turned = true
			if float(h.whirl_unwound) < best - 1.0e-6:
				went_back = true
			best = maxf(best, float(h.whirl_unwound))
			ang = float(h.whirl_angle)
			if float(leash.free_slip_t) <= 0.0:
				slipped = false
	_check(not turned, "the committed direction survives the whole orbit")
	_check(not went_back, "and signed progress is never reset")
	_check(not h.has_method("flip_whirl"), "nothing can reverse an orbit in flight")
	# every radian of progress was swept the one way she committed to
	_check(signf(ang - ang0) == dir0 and absf(ang - ang0) >= best - 0.05,
		"the whole arc is swept in the committed direction (%.2f rad of %.2f)" % [ang - ang0, best])
	_check(best >= budget - 0.05, "the wound-turn budget is completed (%.2f of %.2f rad)" % [best, budget])
	_check(best <= budget + EXTRA_ARC + 0.5,
		"and the arc past it is bounded (%.2f, cap %.2f)" % [best, budget + EXTRA_ARC])
	_check(slipped, "the rope free-slips for every frame of the orbit")
	_check(frames < 900, "the orbit ends")


# the ordinary release: the tangent, once it has swept toward the dog
func _release_aims_at_the_dog(m: Node2D) -> void:
	var h: CharacterBody2D = m.human
	var d: Node2D = m.dog
	var pole: Vector2 = h.global_position + Vector2(60.0, 0.0)
	_one_pole(m, pole)
	d.global_position = pole + Vector2(0.0, -260.0)
	h.velocity = Vector2(0.0, -120.0)
	h.start_whirl(pole, 1.0, 0.6)
	var frames := 0
	while h.is_whirling() and frames < 600:
		h.tick(DT)
		frames += 1
	_check(not h.is_whirling(), "the orbit releases")
	var radial: Vector2 = h.global_position - pole
	var v: Vector2 = h.velocity
	_check(v.length() > 1.0 and v.length() < 2000.0, "at a finite speed (%.0f px/s)" % v.length())
	_check(signf(radial.cross(v)) == h.whirl_dir, "the launch keeps the way she was going round")
	var to_dog: Vector2 = (d.global_position - h.global_position).normalized()
	_check(v.normalized().dot(to_dog) > 0.25,
		"and goes dogward (dot %.2f)" % v.normalized().dot(to_dog))
	var across := absf(radial.normalized().cross(v.normalized()))
	_check(across > 0.45, "never straight out along the radius (tangential %.2f)" % across)


# The ordinary release has nothing left to decide: the orbit waited for the
# tangent to point at the dog, so the tangent IS the launch. Leaning is for
# the launch the extra-arc cap forces, and for nothing else.
func _the_ordinary_release_is_the_tangent_itself(m: Node2D) -> void:
	var h: CharacterBody2D = m.human
	var d: Node2D = m.dog
	var pole: Vector2 = h.global_position + Vector2(60.0, 0.0)
	_one_pole(m, pole)
	for away: Vector2 in [Vector2(0.0, -300.0), Vector2(260.0, 120.0), Vector2(-180.0, -240.0)]:
		d.global_position = pole + away
		h.global_position = pole + Vector2(-46.0, 0.0)
		h.velocity = Vector2(0.0, -120.0)
		h.start_whirl(pole, 1.0, 0.6)
		var frames := 0
		while h.is_whirling() and frames < 900:
			h.tick(DT)
			frames += 1
		_check(not h.is_whirling(), "the orbit releases with the dog at %s" % away)
		_check(h.just_flung, "as a fling")
		var radial: Vector2 = h.global_position - pole
		var tangent: Vector2 = radial.normalized().rotated(float(h.whirl_dir) * PI / 2.0)
		var off := absf(tangent.angle_to(h.velocity))
		_check(off < 0.001, "exactly along the tangent (%.4f rad off, dog at %s)" % [off, away])
		h.just_flung = false


# At the cap the lean is bounded, so a dog sitting behind the way she is going
# cannot be thrown at. That is a stagger, not a fling: a launch that still
# points away from the dog would be worse than no fling at all.
func _no_dogward_fling_means_no_fling(m: Node2D) -> void:
	var h: CharacterBody2D = m.human
	if not h.has_method("whirl_can_fling"):
		_check(false, "the owner can say whether a dogward fling exists at the cap")
		return
	var radial := Vector2(ORBIT_R, 0.0)
	for spin: float in [1.0, -1.0]:
		var tangent: Vector2 = radial.normalized().rotated(spin * PI / 2.0)
		_check(h.whirl_fling_dir(radial, spin, Vector2.ZERO, 0.0) == tangent,
			"with nothing to aim at the launch is the tangent (spin %+.0f)" % spin)
		_check(h.whirl_can_fling(radial, spin, tangent),
			"a dog straight along the tangent can be flung at")
		_check(h.whirl_can_fling(radial, spin, tangent.rotated(1.3)),
			"and one well off it, within reach of the lean")
		_check(h.whirl_can_fling(radial, spin, tangent.rotated(-1.3)), "either way off it")
		# 165 degrees off the tangent: the cap leaves 105 degrees, still away
		_check(not h.whirl_can_fling(radial, spin, tangent.rotated(deg_to_rad(165.0))),
			"a dog behind the way she is going cannot be (spin %+.0f)" % spin)
		_check(not h.whirl_can_fling(radial, spin, -tangent), "nor one straight behind her")
		_check(h.whirl_can_fling(radial, spin, Vector2.ZERO),
			"and a dog with no direction at all is no reason to refuse")


# Adversarial dog placements, not only the dog at the pole: inside the orbit,
# on it, behind her and far out, all the way round. However each one comes out,
# the orbit must end, and it must never throw her away from the dog or back
# against the way she was going.
func _release_never_fires_away_from_the_dog(m: Node2D) -> void:
	var h: CharacterBody2D = m.human
	var d: Node2D = m.dog
	var pole: Vector2 = h.global_position + Vector2(60.0, 0.0)
	_one_pole(m, pole)
	var cases := 0
	var ended := 0
	var reversed := 0
	var over_lean := 0
	var wild := 0
	var flung := 0
	var dogward := 0
	var in_cone := 0
	var worst := 1.0
	for k in range(12):
		for dist: float in [0.0, 6.0, 18.0, 29.0, 44.0, 150.0]:
			cases += 1
			d.global_position = pole + Vector2(dist, 0.0).rotated(TAU * float(k) / 12.0)
			h.global_position = pole + Vector2(-46.0, 0.0)
			h.velocity = Vector2(0.0, -120.0)
			h.just_flung = false
			h.start_whirl(pole, 1.0, 0.6)
			var spin: float = h.whirl_dir
			var frames := 0
			while h.is_whirling() and frames < 1200:
				h.tick(DT)
				frames += 1
			if h.is_whirling():
				continue
			ended += 1
			var radial: Vector2 = h.global_position - pole
			var tangent: Vector2 = radial.normalized().rotated(spin * PI / 2.0)
			var v: Vector2 = h.velocity
			if signf(radial.cross(v)) != spin:
				reversed += 1
			if absf(tangent.angle_to(v)) > BLEND_MAX + 0.001:
				over_lean += 1
			if h.just_flung:
				flung += 1
				var to_dog: Vector2 = d.global_position - h.global_position
				if to_dog.length() > 0.001:
					var dot := v.normalized().dot(to_dog.normalized())
					worst = minf(worst, dot)
					if dot > 0.0:
						dogward += 1
					if dot >= AIM_COS - 0.01:
						in_cone += 1
				else:
					dogward += 1
					in_cone += 1
			elif v.length() > BAIL_SPEED + 1.0:
				wild += 1
	_check(ended == cases, "every orbit ends, wherever the dog is (%d of %d)" % [ended, cases])
	# A stagger is a legitimate way out, so this does not demand that every case
	# flings - but with a dog that stays put the tangent comes round to it, and
	# all but a stray case should be a fling that lands inside the release cone,
	# not merely somewhere on the dogward side of the circle.
	_check(flung >= cases - 2, "all but a stray one are flings (%d of %d)" % [flung, cases])
	_check(dogward == flung, "every fling goes dogward (%d of %d)" % [dogward, flung])
	_check(in_cone >= flung - 2,
		"all but a stray one inside the release cone (%d of %d, worst dot %.3f)" % [in_cone, flung, worst])
	_check(reversed == 0, "none of them launches against the way she went (%d)" % reversed)
	_check(over_lean == 0, "none leans past the cap (%d)" % over_lean)
	_check(worst > 0.0, "and none away from the dog (worst dot %.3f)" % worst)
	_check(wild == 0, "the ones that give up leave at a controlled speed (%d wild)" % wild)
	h.just_flung = false


# The same rule in the state machine, with the geometry forced: the budget
# spent, and the dog sitting straight back along the way she came. Every dog
# placement in the sweep above comes out as a fling, so this is the only way to
# stand the refusal up in the orbit itself.
func _a_fling_with_nowhere_to_go_is_a_stagger(m: Node2D) -> void:
	var h: CharacterBody2D = m.human
	var d: Node2D = m.dog
	var pole: Vector2 = h.global_position + Vector2(60.0, 0.0)
	_one_pole(m, pole)
	h.global_position = pole + Vector2(-46.0, 0.0)
	h.velocity = Vector2(0.0, -120.0)
	h.just_flung = false
	h.start_whirl(pole, 1.0, 0.6)
	for i in range(10):
		h.tick(DT)
	_check(h.is_whirling(), "she is mid-orbit")
	var radial: Vector2 = h.global_position - pole
	var tangent: Vector2 = radial.normalized().rotated(float(h.whirl_dir) * PI / 2.0)
	# straight back down the tangent: no lean the cap allows can reach it
	d.global_position = h.global_position - tangent * 18.0
	h.whirl_unwound = float(h.whirl_turns) + EXTRA_ARC
	var before: Vector2 = h.global_position
	var spin: float = h.whirl_dir
	h.tick(DT)
	_check(not h.is_whirling(), "the orbit ends when its budget and its arc are both spent")
	_check(not h.just_flung, "but not as a fling, because there is no dogward one to be had")
	_check(h.get("whirl_bailed") == true, "she staggers out instead")
	var sp := h.velocity.length()
	_check(sp > 1.0 and sp <= BAIL_SPEED + 1.0, "at a controlled speed (%.0f px/s)" % sp)
	_check(before.distance_to(h.global_position) < 40.0,
		"from where the orbit had her (%.1f px)" % before.distance_to(h.global_position))
	_check(signf((h.global_position - pole).cross(h.velocity)) == spin,
		"along the way she was going round")
	h.just_flung = false


# The ideal tangent can never arrive when the dog is at the pole: the owner
# still has to be thrown toward her, by leaning the tangent over - never far
# enough to reverse the orbit.
func _missed_tangent_still_throws_dogward(m: Node2D) -> void:
	var h: CharacterBody2D = m.human
	var d: Node2D = m.dog
	var pole: Vector2 = h.global_position + Vector2(60.0, 0.0)
	_one_pole(m, pole)
	d.global_position = pole + Vector2(2.0, 0.0)
	h.velocity = Vector2(0.0, -120.0)
	h.start_whirl(pole, 1.0, 0.6)
	var budget := 0.6 * TAU
	var frames := 0
	while h.is_whirling() and frames < 900:
		h.tick(DT)
		frames += 1
	_check(not h.is_whirling(), "an orbit whose tangent never lines up still releases")
	_check(float(h.whirl_unwound) <= budget + EXTRA_ARC + 0.5,
		"after a bounded extra arc (%.2f, cap %.2f)" % [float(h.whirl_unwound), budget + EXTRA_ARC])
	var radial: Vector2 = h.global_position - pole
	var v: Vector2 = h.velocity
	var tangent: Vector2 = radial.normalized().rotated(float(h.whirl_dir) * PI / 2.0)
	var to_dog: Vector2 = (d.global_position - h.global_position).normalized()
	_check(v.normalized().dot(to_dog) > 0.25,
		"and throws her dogward anyway (dot %.2f)" % v.normalized().dot(to_dog))
	_check(absf(tangent.angle_to(v)) <= BLEND_MAX + 0.02,
		"by leaning the tangent over at most %.0f degrees (%.0f)" % [rad_to_deg(BLEND_MAX), rad_to_deg(absf(tangent.angle_to(v)))])
	_check(signf(radial.cross(v)) == h.whirl_dir, "which never reverses the orbit")


# the leash as a pulley: a harder pull spins the orbit up faster and throws
# her further
func _pull_drives_spin_up_and_release(m: Node2D) -> void:
	var h: CharacterBody2D = m.human
	var pole: Vector2 = h.global_position + Vector2(60.0, 0.0)
	_one_pole(m, pole)
	var start: Vector2 = pole + Vector2(-46.0, 0.0)
	var omega: Array[float] = []
	var speed: Array[float] = []
	for pull: float in [0.0, 1500.0]:
		h.global_position = start
		h.velocity = Vector2(0.0, -120.0)
		h.start_whirl(pole, 1.0, 4.0)
		for i in range(12):
			h.whirl_pull = pull
			h.tick(DT)
		omega.append(float(h.whirl_omega))
		h.release_whirl()
		speed.append(h.velocity.length())
	_check(omega[1] >= omega[0] * 1.25,
		"a hard pull spins the orbit up faster (%.1f vs %.1f rad/s)" % [omega[1], omega[0]])
	_check(speed[1] >= speed[0] * 1.2,
		"and throws her harder (%.0f vs %.0f px/s)" % [speed[1], speed[0]])
	_check(speed[0] > 1.0, "a pull-less orbit still throws her (%.0f px/s)" % speed[0])


# the safety net: a whirl that outlives its timer staggers out of the orbit
func _timeout_stumbles_under_control(m: Node2D) -> void:
	var h: CharacterBody2D = m.human
	var pole: Vector2 = h.global_position + Vector2(60.0, 0.0)
	_one_pole(m, pole)
	h.velocity = Vector2(0.0, -120.0)
	h.start_whirl(pole, 1.0, 4.0)
	for i in range(10):
		h.tick(DT)
	var before: Vector2 = h.global_position
	var radial: Vector2 = before - pole
	var spin: float = h.whirl_dir
	h.just_flung = false
	h.state_t = 0.0
	h.tick(DT)
	_check(not h.is_whirling(), "a timed-out orbit ends")
	_check(before.distance_to(h.global_position) < 0.5,
		"where she was standing (%.2f px)" % before.distance_to(h.global_position))
	var sp := h.velocity.length()
	_check(sp > 1.0 and sp <= BAIL_SPEED + 1.0, "at a controlled speed (%.0f px/s)" % sp)
	_check(not h.just_flung, "and it is not a fling")
	_check(signf(radial.cross(h.velocity)) == spin, "she staggers along the tangent she was on")
	_check(h.get("whirl_bailed") == true, "main is told to keep the rope slipping")


# lost contact: the thing she was wound on is no longer where the orbit is
func _a_pole_that_runs_away_does_not_drag_her(m: Node2D) -> void:
	var h: CharacterBody2D = m.human
	var pole: Vector2 = h.global_position + Vector2(60.0, 0.0)
	_one_pole(m, pole)
	h.velocity = Vector2(0.0, -120.0)
	h.start_whirl(pole, 1.0, 4.0)
	for i in range(10):
		h.tick(DT)
	var before: Vector2 = h.global_position
	var radial: Vector2 = before - pole
	var spin: float = h.whirl_dir
	h.just_flung = false
	h.whirl_pole = before + Vector2(LOSE_R + 260.0, 0.0)
	h.tick(DT)
	_check(not h.is_whirling(), "an orbit whose pole is gone ends")
	_check(before.distance_to(h.global_position) < 0.5,
		"and never snaps her across the level (%.1f px)" % before.distance_to(h.global_position))
	var sp := h.velocity.length()
	_check(sp > 1.0 and sp <= BAIL_SPEED + 1.0, "at a controlled speed (%.0f px/s)" % sp)
	_check(not h.just_flung, "and it is not a fling")
	_check(signf(radial.cross(h.velocity)) == spin, "along the tangent she was on")


# An orbit ends inside her OWN tick, which main.gd runs before the tug of war.
# The frame she leaves on is therefore still the orbit's: raw tension, the
# separation damping and the geometry cap must all skip her on it, or the way
# out gets exactly the yank the whirl had been shielding her from.
func _a_bail_in_her_tick_is_still_a_whirl_to_main(m: Node2D) -> void:
	var h: CharacterBody2D = m.human
	var leash: Node2D = m.leash
	for how: String in ["out of time", "pole gone"]:
		var was_len: float = m.leash_len
		var pole: Vector2 = h.global_position + Vector2(300.0, 0.0)
		_taut_orbit(m, pole, 4.0)
		for i in range(10):
			h.tick(DT)
		_check(h.is_whirling(), "%s: she is whirling" % how)
		var excess := float(leash.used_length()) - float(m.leash_len)
		_check(excess > float(m.leash_len) * (STRETCH_CAP - 1.0),
			"%s: on a rope stretched past the geometry cap (%.0f px over)" % [how, excess])
		h.just_flung = false
		leash.free_slip_t = 0.0
		var spin: float = h.whirl_dir
		var radial: Vector2 = h.global_position - pole
		if how == "out of time":
			h.state_t = 0.0
		else:
			h.whirl_pole = h.global_position + Vector2(LOSE_R + 260.0, 0.0)
		h.tick(DT)
		_check(not h.is_whirling(), "%s: the orbit ends inside her own tick" % how)
		_check(h.get("whirl_bailed") == true, "%s: and says so" % how)
		var p0: Vector2 = h.global_position
		var v0: Vector2 = h.velocity
		m._apply_leash(DT)
		_check(p0.distance_to(h.global_position) < 0.01,
			"%s: the tug cannot snap her on that frame (%.2f px)" % [how, p0.distance_to(h.global_position)])
		_check((h.velocity - v0).length() < 0.01,
			"%s: nor change the tangent she left on (%.1f px/s of it)" % [how, (h.velocity - v0).length()])
		var sp := h.velocity.length()
		_check(sp > 1.0 and sp <= BAIL_SPEED + 1.0,
			"%s: she leaves at a controlled speed (%.0f px/s)" % [how, sp])
		_check(not h.just_flung, "%s: and it is not a fling" % how)
		_check(signf(radial.cross(h.velocity)) == spin, "%s: along the tangent she was on" % how)
		_check(float(leash.free_slip_t) > 0.0,
			"%s: the rope keeps slipping while she staggers clear" % how)
		_check(h.get("whirl_bailed") == false, "%s: and the flag is consumed, not left to leak" % how)
		m.leash_len = was_len


# Every way out of an orbit leaves the rope slipping: a coil that grips the
# moment she stops orbiting arrests the fling, or trips the stagger.
func _the_way_out_always_leaves_the_rope_slipping(m: Node2D) -> void:
	var h: CharacterBody2D = m.human
	var leash: Node2D = m.leash
	for how: String in ["is flung", "runs out of time", "loses its pole"]:
		var was_len: float = m.leash_len
		var pole: Vector2 = h.global_position + Vector2(300.0, 0.0)
		_taut_orbit(m, pole, 4.0)
		for i in range(8):
			h.tick(DT)
		leash.free_slip_t = 0.0
		h.just_flung = false
		match how:
			"is flung":
				h.release_whirl()
			"runs out of time":
				h.state_t = 0.0
				h.tick(DT)
			_:
				h.whirl_pole = h.global_position + Vector2(LOSE_R + 260.0, 0.0)
				h.tick(DT)
		_check(not h.is_whirling(), "an orbit that %s is over" % how)
		m._apply_leash(DT)
		_check(float(leash.free_slip_t) > 0.0,
			"and the rope is still slipping after it (%s, %.2f s)" % [how, float(leash.free_slip_t)])
		_check(h.get("whirl_bailed") == false, "with nothing left over to leak (%s)" % how)
		m.leash_len = was_len
	h.just_flung = false


# The abandoned-orbit flag is a one-shot, and the tug has frames it leaves
# early - a slack rope, no leash at all. It has to be consumed on those too, or
# it survives into a frame where she is not whirling and shields her from a
# tug she should feel.
func _a_bail_off_the_leash_does_not_leak(m: Node2D) -> void:
	var h: CharacterBody2D = m.human
	var leash: Node2D = m.leash
	var pole: Vector2 = h.global_position + Vector2(60.0, 0.0)
	_one_pole(m, pole)
	h.velocity = Vector2(0.0, -120.0)
	h.start_whirl(pole, 1.0, 4.0)
	for i in range(8):
		h.tick(DT)
	h.state_t = 0.0
	h.tick(DT)
	_check(h.get("whirl_bailed") == true, "an abandoned orbit sets the flag")
	leash.detached = true
	m._apply_leash(DT)
	leash.detached = false
	_check(h.get("whirl_bailed") == false,
		"which is consumed even with the leash off, so it cannot leak into a later frame")


# The fling's one-shot has the same shape as the abandoned orbit's, and the same
# frames to survive: a fling is paid for on the frame it happens, including the
# frames the tug leaves early. Off the leash there is no rope to keep slipping,
# but the flag must still die and the fling must still count.
func _a_fling_off_the_leash_is_still_paid_for(m: Node2D) -> void:
	var h: CharacterBody2D = m.human
	var leash: Node2D = m.leash
	var pole: Vector2 = h.global_position + Vector2(60.0, 0.0)
	_one_pole(m, pole)
	h.global_position = pole + Vector2(-46.0, 0.0)
	h.velocity = Vector2(0.0, -120.0)
	h.just_flung = false
	h.start_whirl(pole, 1.0, 0.6)
	for i in range(6):
		h.tick(DT)
	h.release_whirl()
	_check(h.just_flung, "a release asks to be paid for")
	var before: int = int(m.flings_done)
	leash.detached = true
	leash.free_slip_t = 0.0
	m._apply_leash(DT)
	leash.detached = false
	_check(not h.just_flung, "which is consumed even with the leash off")
	_check(int(m.flings_done) == before + 1, "and the fling still counted (%d)" % int(m.flings_done))
	_check(float(leash.free_slip_t) == 0.0, "with no rope asked to keep slipping")


# main owns the frame order, so main is what notices the orbit pole stopped
# being a pole at all
func _main_abandons_an_orbit_round_a_non_pole(m: Node2D) -> void:
	var h: CharacterBody2D = m.human
	var leash: Node2D = m.leash
	for what: String in ["nothing at all", "a cafe table"]:
		var pole: Vector2 = h.global_position + Vector2(300.0, 0.0)
		_one_pole(m, pole)
		h.global_position = pole + Vector2(-46.0, 0.0)
		# let the rope settle where the ends now are: this test moves them by
		# hand, and a rope that has not seen the move yet reads as hugely
		# overstretched, which is a spike of the test's own making
		for i in range(40):
			leash.tick(DT)
		var orbit: Vector2 = h.global_position + Vector2(0.0, -50.0)
		if what == "a cafe table":
			# in the pole list, so the rope winds on it, but furniture: the
			# terrace on La Rambla, which held an owner in a whirl-stumble
			# loop for two minutes because orbiting it unwinds nothing
			var furn: Array[Vector2] = [orbit]
			var both: Array[Vector2] = [pole, orbit]
			leash.poles = both
			leash.furniture_poles = furn
			_check(not leash.is_real_pole(orbit), "the table is in the rope's poles but is not one")
		h.velocity = Vector2(0.0, -120.0)
		h.start_whirl(orbit, 1.0, 2.0)
		for i in range(6):
			h.tick(DT)
		var before: Vector2 = h.global_position
		h.just_flung = false
		m._apply_leash(DT)
		_check(not h.is_whirling(), "an orbit round %s is abandoned" % what)
		_check(before.distance_to(h.global_position) < 0.5,
			"without a snap (%s, %.1f px)" % [what, before.distance_to(h.global_position)])
		_check(not h.just_flung, "and without a fling (%s)" % what)
		_check(float(leash.free_slip_t) > 0.0,
			"the rope keeps slipping while she staggers clear (%s)" % what)


# arming already refuses a pole it could not find; the state machine must
# refuse one too, rather than orbiting a NaN
func _a_nowhere_pole_is_refused(m: Node2D) -> void:
	var h: CharacterBody2D = m.human
	h.velocity = Vector2(0.0, -120.0)
	var before: Vector2 = h.global_position
	h.start_whirl(Vector2(INF, INF), 1.0, 2.0)
	_check(not h.is_whirling(), "a whirl round nowhere never starts")
	h.tick(DT)
	_check(is_finite(h.global_position.x) and is_finite(h.global_position.y),
		"and the owner stays somewhere real")
	_check(before.distance_to(h.global_position) < 20.0, "roughly where she was")
