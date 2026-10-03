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
#   - the launch is dogward even when the ideal tangent never arrives (the
#     forced release used to skip the aim entirely), and never fires against
#     the way she was going round;
#   - a timeout, a pole that stopped being a pole, or a pole that ran away
#     end the orbit in a controlled stumble - not a full-speed fling, and
#     never a snap across the level.

const DT := 1.0 / 60.0
const TAIL_PTS := 9
const PROBE := 0.08
# the implementation's own bounds, repeated so this test fails if they move
const EXTRA_ARC := 0.6 * TAU
const BLEND_MAX := PI / 3.0
const BAIL_SPEED := 260.0
const LOSE_R := 140.0

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	_probe_picks_the_unwinding_way()
	_probe_agrees_with_a_real_rope()
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
	_arming_commits_the_probed_direction(m)
	_direction_is_committed(m)
	_release_aims_at_the_dog(m)
	_missed_tangent_still_throws_dogward(m)
	_pull_drives_spin_up_and_release(m)
	_timeout_stumbles_under_control(m)
	_a_pole_that_runs_away_does_not_drag_her(m)
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


# Arming for real, through main's own frame: a wound rope that goes taut
# round a pole at the owner's elbow starts an orbit after the window, and the
# direction it starts in is the one the rope's probe asked for.
func _arming_commits_the_probed_direction(m: Node2D) -> void:
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
	var want := 1.0 if float(leash.unwind_bias(pole)) >= 0.0 else -1.0
	# the owner's reel takes up the slack: now the wound rope is taut, which
	# is the whole arming condition
	var was_len: float = m.leash_len
	m.leash_len = float(leash.used_length()) - 20.0
	var early := false
	var frames := 0
	while not h.is_whirling() and frames < 40:
		m._apply_leash(DT)
		frames += 1
		if h.is_whirling() and frames < 12:
			early = true
	_check(h.is_whirling(), "a taut wound rope round a pole arms an orbit (%d frames)" % frames)
	_check(not early, "but never before the arming window is out (%d frames)" % frames)
	_check(h.whirl_pole.distance_to(pole) < 1.0, "round the pole the rope is wound on")
	_check(h.whirl_dir == want, "the way the rope's own probe asked for (%+.0f)" % want)
	m.leash_len = was_len
	h.bail_whirl()


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


# main owns the frame order, so main is what notices the orbit pole stopped
# being a pole at all
func _main_abandons_an_orbit_round_a_non_pole(m: Node2D) -> void:
	var h: CharacterBody2D = m.human
	var leash: Node2D = m.leash
	var pole: Vector2 = h.global_position + Vector2(300.0, 0.0)
	_one_pole(m, pole)
	h.global_position = pole + Vector2(-46.0, 0.0)
	# let the rope settle where the ends now are: this test moves them by
	# hand, and a rope that has not seen the move yet reads as hugely
	# overstretched, which is a spike of the test's own making
	for i in range(40):
		leash.tick(DT)
	var nothing: Vector2 = h.global_position + Vector2(0.0, -50.0)
	h.velocity = Vector2(0.0, -120.0)
	h.start_whirl(nothing, 1.0, 2.0)
	for i in range(6):
		h.tick(DT)
	var before: Vector2 = h.global_position
	h.just_flung = false
	m._apply_leash(DT)
	_check(not h.is_whirling(), "an orbit round something that is not a pole is abandoned")
	_check(before.distance_to(h.global_position) < 0.5,
		"without a snap (%.1f px)" % before.distance_to(h.global_position))
	_check(not h.just_flung, "and without a fling")
	_check(float(leash.free_slip_t) > 0.0, "the rope keeps slipping while she staggers clear")


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
