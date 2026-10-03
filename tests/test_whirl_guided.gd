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
	_a_coil_somewhere_else_is_not_this_poles()
	_probe_agrees_with_a_real_rope()
	_the_probe_follows_her_end_not_the_whole_rope()
	_only_real_poles_can_be_orbited()
	call_deferred("_run")


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
	if not (leash.has_method("human_tail") and leash.has_method("unwind_bias")
			and leash.has_method("pole_winding")):
		_check(false, "the rope exposes its human-end tail and the probe over it")
	else:
		var tail: PackedVector2Array = leash.human_tail()
		var n: int = leash.pts.size()
		_check(tail.size() == TAIL_PTS, "the human-end tail is the last %d points (%d)" % [TAIL_PTS, tail.size()])
		_check(tail[tail.size() - 1] == leash.pts[n - 1] and tail[0] == leash.pts[n - TAIL_PTS],
			"and it is exactly the rope's own last %d points" % TAIL_PTS)
		var pole: Vector2 = leash.human_contact_pole
		var bias: float = leash.unwind_bias(pole)
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
		if not (leash.has_method("unwind_bias") and leash.has_method("pole_winding")
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
			var bias: float = leash.unwind_bias(hers)
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
		var s := signf(float(leash.unwind_bias(pole)))
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
					worst = minf(worst, v.normalized().dot(to_dog.normalized()))
			elif v.length() > BAIL_SPEED + 1.0:
				wild += 1
	_check(ended == cases, "every orbit ends, wherever the dog is (%d of %d)" % [ended, cases])
	_check(flung > 0, "most of them as flings (%d of %d)" % [flung, cases])
	_check(reversed == 0, "none of them launches against the way she went (%d)" % reversed)
	_check(over_lean == 0, "none leans past the cap (%d)" % over_lean)
	_check(worst > 0.0, "no fling ever throws her away from the dog (worst dot %.3f)" % worst)
	_check(wild == 0, "and the ones that give up leave at a controlled speed (%d wild)" % wild)
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
