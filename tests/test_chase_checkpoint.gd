extends SceneTree

# Fair chase continuation (systems/home_chase.gd, systems/chase_checkpoint.gd)
# on real main scenes. Leaving the destination captures the destination
# checkpoint before the warning; the warning and a fixed head start hold the
# machine; the later dumpster jam, and only it, is the midpoint checkpoint,
# and never while a catch is under way or anyone is at the kill line.
# Any loss on the home leg with a checkpoint held offers "continue" on the
# end card's restart action, which restores the latest checkpoint's exact
# values in place: the destination repeats the warning and head start, the
# midpoint holds the machine at its jam through a safe countdown and then
# lets it go at once. Nothing is paid twice, nothing banked before the
# checkpoint is lost, and capture or restore never touches the save.
# START AGAIN, the walk select and any reload clear the checkpoint; an
# ordinary walk and the autowalk bot are unchanged; --at-home starts the
# home leg through a callable seam. The continue tests then run real frames
# of main to show the walk goes on from there.

var HomeChase: GDScript
var Checkpoint: GDScript
var Flow: GDScript
var Mood: GDScript
var game: Node

var checks := 0
var failures: Array[String] = []
var reloads := 0


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	# deferred so the autoloads are registered before main.gd is compiled
	call_deferred("_run")


func _fresh_main(level: String) -> Node2D:
	game.level_id = level
	var main: Node2D = load("res://main.tscn").instantiate()
	root.add_child(main)
	if not main.is_node_ready():
		await main.ready
	main.auto_walk = false
	main.tutorial_mode = false
	main.started = true
	main.frozen = false
	return main


func _drop(main: Node2D) -> void:
	Checkpoint.capture_hook = Callable()
	main.queue_free()
	await process_frame


# Stand the pair just south of the gate, as walking back out of the
# destination leaves them, and let _progress turn them for home.
func _leave_destination(m: Node2D) -> void:
	m.phase = "freedom"
	m.dog.global_position = Vector2(m.walk_cx + 20.0, m.GATE_Y + 60.0)
	m.human.global_position = Vector2(m.walk_cx - 20.0, m.GATE_Y + 100.0)
	m.leash.resnap()
	m._progress(0.0)


# Keep the pair far south of the machine and tick the chase until its phase
# is `want` (or give up).
func _tick_until(m: Node2D, want: String, step := 0.05, limit := 400) -> float:
	var t := 0.0
	for i in range(limit):
		if String(m.chase_phase) == want:
			return t
		HomeChase.tick(m, step)
		t += step
	return -1.0


func _safe(m: Node2D) -> void:
	var sw: Node2D = m.chase_sweeper
	m.dog.global_position = Vector2(m.walk_cx, sw.front_y + 900.0)
	m.human.global_position = Vector2(m.walk_cx, sw.front_y + 950.0)


# Run the machine over your human and play out the catch beat to the card.
func _get_caught(m: Node2D) -> void:
	var sw: Node2D = m.chase_sweeper
	m.human.global_position = Vector2(m.walk_cx, sw.front_y - 5.0)
	m.dog.global_position = Vector2(m.walk_cx, sw.front_y + 400.0)
	HomeChase.tick(m, 0.0)
	HomeChase.tick(m, HomeChase.CATCH_BEAT * 2.0)


func _press(m: Node2D, action: String) -> void:
	Input.action_press(action)
	if m.started and m.paused:
		Flow.tick_pause(m)
	elif m.started and m.frozen:
		Flow.tick_end(m)
	Input.action_release(action)


func _verbs(m: Node2D) -> Array:
	var out: Array = []
	for p: Array in Flow.prompts(m):
		out.append([String(p[0]), String(p[1])])
	return out


func _has_verb(m: Node2D, action: String, verb: String) -> bool:
	for p: Array in _verbs(m):
		if p[0] == action and p[1] == verb:
			return true
	return false


func _later_jam(sw: Node2D) -> Vector2:
	var later := Vector2(0.0, -INF)
	for j: Vector2 in sw.jams:
		if j.y > later.y:
			later = j
	return later


# Real frames of main after a continue: count the frames until the phase
# leaves `held`, watching that the pair and the rope stay put together, that
# nobody is caught, and (while held) that the machine does not move. Returns
# the held seconds and what it saw.
func _run_held(m: Node2D, held: Array, limit_secs: float) -> Dictionary:
	var sw: Node2D = m.chase_sweeper
	var dt := 1.0 / float(Engine.physics_ticks_per_second)
	var out := {"secs": 0.0, "stable": true, "caught": false, "moved": false, "why": ""}
	var fy: float = sw.front_y
	var pd: Vector2 = m.dog.global_position
	var ph: Vector2 = m.human.global_position
	for i in range(int(limit_secs / dt)):
		await physics_frame
		if not held.has(String(m.chase_phase)):
			break
		out["secs"] = float(out["secs"]) + dt
		_watch(m, pd, ph, out)
		pd = m.dog.global_position
		ph = m.human.global_position
		if not is_equal_approx(float(sw.front_y), fy):
			out["moved"] = true
	return out


# Then real frames of the chase itself: the machine should be moving and
# nobody caught yet.
func _run_chase(m: Node2D, frames: int) -> Dictionary:
	var sw: Node2D = m.chase_sweeper
	var out := {"stable": true, "caught": false, "start": float(sw.front_y), "end": 0.0, "why": ""}
	var pd: Vector2 = m.dog.global_position
	var ph: Vector2 = m.human.global_position
	for i in range(frames):
		await physics_frame
		_watch(m, pd, ph, out)
		pd = m.dog.global_position
		ph = m.human.global_position
	out["end"] = float(sw.front_y)
	return out


func _watch(m: Node2D, pd: Vector2, ph: Vector2, out: Dictionary) -> void:
	var d: Vector2 = m.dog.global_position
	var h: Vector2 = m.human.global_position
	var rope: float = m.leash.used_length()
	var ok: bool = is_finite(d.x) and is_finite(d.y) and is_finite(h.x) and is_finite(h.y) \
		and d.distance_to(pd) < 30.0 and h.distance_to(ph) < 30.0 \
		and d.distance_to(h) < float(m.leash_len) * 1.3 + 20.0 \
		and is_finite(rope) and rope < float(m.leash_len) * 1.6 + 20.0
	if not ok and bool(out["stable"]):
		out["stable"] = false
		out["why"] = "dog %s (was %s), human %s (was %s), rope %.0f of %.0f" % [d, pd, h, ph, rope, float(m.leash_len)]
	if m.chase_catch_t > 0.0 or m.frozen:
		out["caught"] = true


func _scared(m: Node2D) -> float:
	return float(m.mood.charge.get(Mood.M.SCARED, 0.0))


func _save_state() -> String:
	return var_to_str([game.records, game.total_bones, game.total_stars(), game.walks_lost])


# A different value of the same kind, so restoring it is visible.
func _mutate(v: Variant) -> Variant:
	match typeof(v):
		TYPE_BOOL:
			return not v
		TYPE_INT:
			return int(v) + 7
		TYPE_FLOAT:
			return float(v) + 0.37 if is_finite(float(v)) else 123.0
		TYPE_VECTOR2:
			var p: Vector2 = v
			return p + Vector2(13.0, 7.0) if is_finite(p.x) and is_finite(p.y) else Vector2(11.0, 3.0)
		TYPE_STRING:
			return String(v) + "x"
		TYPE_DICTIONARY:
			var d: Dictionary = (v as Dictionary).duplicate(true)
			d["__probe"] = true
			return d
		TYPE_ARRAY:
			var a: Array = (v as Array).duplicate(true)
			if not a.is_empty() and a[0] is Dictionary:
				(a[0] as Dictionary)["__probe"] = true
			elif a.is_typed() and a.get_typed_builtin() == TYPE_VECTOR2:
				a.append(Vector2(1.0, 2.0))
			elif a.is_typed() and a.get_typed_builtin() == TYPE_FLOAT:
				a.append(1.5)
			elif a.is_typed() and a.get_typed_builtin() == TYPE_STRING:
				a.append("PROBE")
			elif a.is_typed() and a.get_typed_builtin() == TYPE_DICTIONARY:
				a.append({"__probe": true})
			elif not a.is_typed():
				a.append(1)
			return a
	return v


func _run() -> void:
	HomeChase = load("res://systems/home_chase.gd")
	Checkpoint = load("res://systems/chase_checkpoint.gd")
	Flow = load("res://hud/menu_flow.gd")
	Mood = load("res://systems/mood.gd")
	game = root.get_node("Game")
	game.persist = false
	root.get_node("Sfx").muted = true
	Flow.reload_hook = func() -> void: reloads += 1

	await _test_ordinary_walk()
	await _test_destination_and_head_start()
	await _test_midpoint_and_exact_restore()
	await _test_midpoint_guards()
	await _test_no_duplicates_and_destination_continue()
	await _test_real_frames_midpoint()
	await _test_real_frames_destination()
	await _test_restart_paths_clear()
	await _test_autowalk()
	await _test_at_home()

	Flow.reload_hook = Callable()
	game.quick_start = false
	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("CHASE CHECKPOINT OK")
		quit(0)
	else:
		print("CHASE CHECKPOINT FAIL")
		quit(1)


# --- an ordinary walk has no checkpoint, no phases and no continue ---------
func _test_ordinary_walk() -> void:
	var m := await _fresh_main("street")
	m.chase_active = false
	_leave_destination(m)
	_check(String(m.phase) == "home", "street: leaving the destination heads home")
	_check(m.chase_sweeper == null and String(m.chase_phase) == "", "street: no chase and no chase phase")
	_check(m.chase_checkpoint.is_empty(), "street: no checkpoint is captured")
	m._death("OFF THE EDGE\n\nShe went over.", "edge")
	_check(not HomeChase.can_continue(m), "street: a loss cannot continue")
	_check(_has_verb(m, "restart", "try again") and not _has_verb(m, "restart", "continue"),
		"street: the end card still offers try again (%s)" % str(_verbs(m)))
	await _drop(m)


# --- the destination checkpoint, the warning and the head start -----------
func _test_destination_and_head_start() -> void:
	var m := await _fresh_main("neteja")
	_check(bool(m.chase_active), "La Neteja rolls its chase")
	var prof: Dictionary = HomeChase.profile_for("neteja")
	var warning := String(prof.get("warning", ""))
	var seen := {"called": false, "warned": true, "phase": "?"}
	Checkpoint.capture_hook = func(snap: Dictionary) -> void:
		if String(snap.get("id", "")) != "destination":
			return
		seen["called"] = true
		var said := false
		for l: Dictionary in m.feed.lines:
			said = said or String(l["text"]) == warning
		seen["warned"] = said
		seen["phase"] = String(m.chase_phase)
	_check(String(m.chase_phase) == "", "outbound: no chase phase before the destination")
	_check(m.chase_sweeper == null and m.chase_checkpoint.is_empty(), "outbound: no threat, no checkpoint")
	_leave_destination(m)
	_check(bool(seen["called"]), "leaving the destination captures the destination checkpoint")
	_check(not bool(seen["warned"]) and String(seen["phase"]) != "warning",
		"the checkpoint is captured before the warning is given")
	_check(String(m.chase_checkpoint.get("id", "")) == "destination", "the latest checkpoint is the destination")
	_check(String(m.chase_phase) == "warning", "then the warning is up (phase %s)" % m.chase_phase)
	var warned := false
	for l: Dictionary in m.feed.lines:
		warned = warned or String(l["text"]) == warning
	_check(warned, "the profile's warning is shouted")

	# warning and head start: the machine cannot advance, catch, or scare
	var sw: Node2D = m.chase_sweeper
	var y0: float = sw.front_y
	m.mood.reset()
	m.mood.charge[Mood.M.SCARED] = 0.5
	m.dog.global_position = Vector2(m.walk_cx, sw.front_y + 30.0)
	m.human.global_position = Vector2(m.walk_cx, sw.front_y - 5.0)
	HomeChase.tick(m, 0.1)
	_check(m.chase_catch_t <= 0.0 and not m.frozen, "no catch during the warning, even under the brooms")
	m._tick_mood(0.2)
	var after := _scared(m)
	_check(after < 0.5 and after > 0.0, "a held machine adds no fear and existing fear decays (%.3f)" % after)
	_safe(m)
	var to_head := _tick_until(m, "head_start", 0.05)
	_check(to_head >= 0.0 and absf(to_head + 0.1 - HomeChase.WARNING_SECS) < 0.11,
		"the warning lasts its fixed time (%.2f)" % (to_head + 0.1))
	_check(is_equal_approx(float(sw.front_y), y0), "the machine has not moved during the warning")
	_check(HomeChase.banner(m) != "", "the head start has a banner")
	m.human.global_position = Vector2(m.walk_cx, sw.front_y - 5.0)
	HomeChase.tick(m, 0.1)
	_check(m.chase_catch_t <= 0.0 and not m.frozen, "no catch during the head start")
	_safe(m)
	var to_chase := _tick_until(m, "chase", 0.05)
	_check(to_chase >= 0.0 and absf(to_chase + 0.1 - HomeChase.HEAD_START_SECS) < 0.11,
		"the head start lasts its fixed time (%.2f)" % (to_chase + 0.1))
	_check(is_equal_approx(float(sw.front_y), y0), "the machine has not moved during the head start")
	HomeChase.tick(m, 0.2)
	_check(float(sw.front_y) > y0, "once the chase runs the machine advances")

	# SCARED follows distance only while it advances
	m.mood.reset()
	sw.jams.clear()
	m.dog.global_position = Vector2(m.walk_cx, sw.front_y + 120.0)
	m.human.global_position = Vector2(m.walk_cx, sw.front_y + 160.0)
	m._tick_mood(0.2)
	var near := _scared(m)
	m.mood.reset()
	m.dog.global_position = Vector2(m.walk_cx, sw.front_y + 850.0)
	m.human.global_position = Vector2(m.walk_cx, sw.front_y + 890.0)
	m._tick_mood(0.2)
	var far := _scared(m)
	_check(near > far and far >= 0.0, "an advancing machine scares more up close (%.3f near, %.3f far)" % [near, far])
	m.mood.reset()
	m.mood.charge[Mood.M.SCARED] = 0.5
	sw.jam_t = 1.0
	m.dog.global_position = Vector2(m.walk_cx, sw.front_y + 60.0)
	m._tick_mood(0.2)
	_check(_scared(m) < 0.5 and _scared(m) > 0.0,
		"a jammed machine adds no fear up close, and fear decays naturally (%.3f)" % _scared(m))
	await _drop(m)


# --- the midpoint is the later jam, and continue restores it exactly -------
func _test_midpoint_and_exact_restore() -> void:
	var m := await _fresh_main("neteja")
	_leave_destination(m)
	_safe(m)
	_tick_until(m, "chase")
	var sw: Node2D = m.chase_sweeper
	_check(sw.jams.size() == 2, "both jams are ahead of the machine (%d)" % sw.jams.size())
	var first: Vector2 = sw.jams[0]
	var later: Vector2 = sw.jams[1]
	for j: Vector2 in sw.jams:
		if j.y < first.y:
			first = j
		if j.y > later.y:
			later = j
	_check(absf(later.y - (-1900.0)) < 100.0, "the later jam is the dumpster near y -1900 (%.0f)" % later.y)
	# the first jam is a respite, not a checkpoint
	sw.front_y = first.y - 2.0
	m.dog.global_position = Vector2(m.walk_cx, first.y + 600.0)
	m.human.global_position = Vector2(m.walk_cx, first.y + 650.0)
	HomeChase.tick(m, 0.1)
	_check(sw.jammed(), "the first dumpster jams the machine")
	_check(String(m.chase_checkpoint.get("id", "")) == "destination", "the first jam is not a checkpoint")
	# a body crossing the later jam's depth is not the checkpoint either
	sw.jam_t = 0.0
	m.dog.global_position = Vector2(m.walk_cx, later.y - 40.0)
	HomeChase.tick(m, 0.05)
	m.dog.global_position = Vector2(m.walk_cx, later.y + 40.0)
	HomeChase.tick(m, 0.05)
	_check(String(m.chase_checkpoint.get("id", "")) == "destination", "crossing y -1900 is not the checkpoint")
	# the machine reaching and being held by the later jam is
	sw.jam_t = 0.0
	sw.front_y = later.y - 2.0
	m.dog.global_position = Vector2(m.walk_cx, later.y + 500.0)
	m.human.global_position = Vector2(m.walk_cx, later.y + 550.0)
	var save_pre := _save_state()
	HomeChase.tick(m, 0.1)
	_check(sw.jammed(), "the later dumpster jams the machine")
	_check(String(m.chase_checkpoint.get("id", "")) == "midpoint", "being held by the later jam captures the midpoint")
	_check(_save_state() == save_pre, "capturing the midpoint writes nothing to the save")
	var snap: Dictionary = m.chase_checkpoint.duplicate(true)
	var secs: Dictionary = snap.get("sections", {})
	_check(float((secs.get("sweeper", {}) as Dictionary).get("jam_t", 0.0)) > 0.0, "the midpoint holds the machine jammed")

	# the schema covers every category the spec lists
	var need := [
		["dog", "energy"], ["main", "pee"], ["main", "poop_state"], ["main", "squat_progress"],
		["main", "urge_timer"], ["main", "bag_pending"], ["main", "marks"], ["main", "mark_progress"],
		["dog", "global_position"], ["dog", "velocity"], ["human", "global_position"], ["human", "velocity"],
		["main", "leash_len"], ["main", "phone_hp"], ["main", "bones"],
		["combo", "links"], ["combo", "points"], ["combo", "timer"], ["combo", "names"],
		["combo", "best_mult"], ["combo", "run_style"], ["main", "run_goals_hit"],
		["main", "kebabs_eaten"], ["main", "dogs_greeted"], ["main", "sniffs_done"],
		["main", "kebabs"], ["main", "hydrants"], ["main", "npc_marks"], ["main", "prize_taken"],
		["main", "chase_min_gap"], ["main", "chase_shave_armed"],
		["main", "teeter_cd"], ["main", "grind_cd"], ["main", "vault_cd"],
		["sweeper", "front_y"], ["sweeper", "jams"], ["sweeper", "jam_t"],
	]
	for nk: Array in need:
		_check((secs.get(nk[0], {}) as Dictionary).has(nk[1]), "the snapshot holds %s.%s" % [nk[0], nk[1]])

	# change every captured value, then lose the walk to the machine
	var fields := 0
	var changed := 0
	for section: String in secs:
		var obj: Object = Checkpoint.target(m, section)
		for key: String in secs[section]:
			obj.set(key, _mutate(obj.get(key)))
			fields += 1
			if var_to_str(obj.get(key)) != var_to_str(secs[section][key]):
				changed += 1
			else:
				print("  not changed by the probe: %s.%s" % [section, key])
	_check(fields > 60 and changed == fields, "every captured value is changed before the loss (%d of %d)" % [changed, fields])
	m.mood.charge[Mood.M.SCARED] = 0.8
	# and a stunt in progress of every kind, which a continue must not carry
	m.teeter.begin()
	m.grind.begin()
	m.grind_rail = 0
	m.vault_t = 0.5
	m.vault_arc = 1.0
	var elapsed_before: float = m.elapsed
	var new_before: int = m.run_goals_new
	_get_caught(m)
	_check(m.frozen and Flow.screen(m) == "notice", "the machine catching your human ends on the card")
	_check(HomeChase.can_continue(m), "a chase loss with a checkpoint can continue")
	_check(_has_verb(m, "restart", "continue") and not _has_verb(m, "restart", "try again"),
		"the retry action reads continue (%s)" % str(_verbs(m)))
	var save_lost := _save_state()
	reloads = 0
	_press(m, "restart")
	_check(reloads == 0, "continue restores in place, without a reload")
	_check(not m.frozen and Flow.screen(m) == "walking", "continue puts the walk back in play (%s)" % Flow.screen(m))
	_check(_save_state() == save_lost, "restoring writes nothing to the save")
	var exact := true
	for section: String in secs:
		var obj: Object = Checkpoint.target(m, section)
		for key: String in secs[section]:
			var ok := var_to_str(obj.get(key)) == var_to_str(secs[section][key])
			if not ok:
				print("  not restored: %s.%s is %s, was %s" % [section, key, var_to_str(obj.get(key)), var_to_str(secs[section][key])])
			exact = exact and ok
	_check(exact, "every captured value is restored exactly")
	_check(m.chase_sweeper == sw and sw.z_index == 0, "the same machine is back behind the pair")
	_check(m.chase_catch_t <= 0.0 and String(m.chase_catch_msg) == "", "the catch is cleared")
	_check(not m.teeter.active and not m.grind.active and m.grind_rail == -1
		and m.vault_t == 0.0 and m.vault_arc == 0.0, "no teeter, grind or pole swing is carried into the continue")
	_check(m.elapsed >= elapsed_before, "the walk's clock is not wound back (%.2f, %.2f)" % [m.elapsed, elapsed_before])
	_check(m.run_goals_new == new_before, "goals ticked for good stay counted")
	_check(absf(_scared(m) - 0.8) < 0.001, "continuing does not clear the fear she had")
	_check(String(m.chase_checkpoint.get("id", "")) == "midpoint", "the midpoint stays the latest checkpoint")

	# the safe countdown: held at the jam, no catch, no new fear
	_check(String(m.chase_phase) == "hold", "a midpoint continue starts the safe countdown (%s)" % m.chase_phase)
	var fy: float = sw.front_y
	var jt: float = sw.jam_t
	_check(HomeChase.banner(m).contains(str(int(ceil(HomeChase.HOLD_SECS)))), "the countdown shows on the banner ('%s')" % HomeChase.banner(m))
	m.human.global_position = Vector2(m.walk_cx, sw.front_y - 5.0)
	HomeChase.tick(m, 0.5)
	_check(m.chase_catch_t <= 0.0 and not m.frozen, "no catch during the countdown")
	_check(is_equal_approx(float(sw.front_y), fy) and is_equal_approx(float(sw.jam_t), jt),
		"the machine stays held at its jam during the countdown")
	_check(sw.jammed(), "and still reads as stuck on it")
	m._tick_mood(0.3)
	_check(_scared(m) < 0.8 and _scared(m) > 0.0, "the countdown adds no fear; it decays naturally (%.3f)" % _scared(m))
	_safe(m)
	var to_chase := _tick_until(m, "chase", 0.05)
	_check(to_chase >= 0.0 and absf(to_chase + 0.5 - HomeChase.HOLD_SECS) < 0.11,
		"the countdown lasts its fixed time (%.2f)" % (to_chase + 0.5))
	# the countdown was the whole of the respite: no jam time is left over
	_check(float(sw.jam_t) == 0.0 and not sw.jammed(), "at zero the machine is free at once (jam_t %.2f)" % sw.jam_t)
	HomeChase.tick(m, 0.2)
	_check(float(sw.front_y) > fy, "and the next frame it is rolling (%.1f, from %.1f)" % [sw.front_y, fy])
	await _drop(m)


# --- the midpoint is never taken from a catch, or with anyone swept --------
func _test_midpoint_guards() -> void:
	# a catch beat rolling on over the jam
	var m := await _fresh_main("neteja")
	_leave_destination(m)
	_safe(m)
	_tick_until(m, "chase")
	var sw: Node2D = m.chase_sweeper
	var later := _later_jam(sw)
	var dest := var_to_str(m.chase_checkpoint)
	var only: Array[Vector2] = [later]
	sw.jams = only
	sw.front_y = later.y - 40.0
	m.human.global_position = Vector2(m.walk_cx, sw.front_y - 5.0)
	m.dog.global_position = Vector2(m.walk_cx, later.y + 500.0)
	HomeChase.tick(m, 0.0)
	_check(m.chase_catch_t > 0.0, "guard setup: the catch beat has begun")
	m.human.global_position = Vector2(m.walk_cx, later.y + 550.0)
	sw.front_y = later.y - 2.0
	HomeChase.tick(m, 0.1)
	_check(sw.jammed() and sw.jam_at == later, "the catch beat rolls onto the later jam")
	_check(var_to_str(m.chase_checkpoint) == dest, "a jam during the catch beat takes no midpoint; the destination stands")
	await _drop(m)

	# your human, then the dog, at or behind the kill line as it jams
	for who: String in ["human", "dog"]:
		m = await _fresh_main("neteja")
		_leave_destination(m)
		_safe(m)
		_tick_until(m, "chase")
		sw = m.chase_sweeper
		later = _later_jam(sw)
		dest = var_to_str(m.chase_checkpoint)
		only = [later]
		sw.jams = only
		sw.front_y = later.y - 2.0
		var behind := Vector2(m.walk_cx, later.y - 10.0)
		var clear := Vector2(m.walk_cx, later.y + 500.0)
		m.human.global_position = behind if who == "human" else clear
		m.dog.global_position = behind if who == "dog" else clear + Vector2(0.0, 40.0)
		HomeChase.tick(m, 0.1)
		_check(sw.jammed() and sw.jam_at == later, "%s behind: the machine jams on the later dumpster" % who)
		_check(var_to_str(m.chase_checkpoint) == dest,
			"%s behind the kill line: no midpoint, the destination checkpoint stands" % who)
		await _drop(m)


# --- nothing paid twice, nothing banked lost; the destination continue -----
func _test_no_duplicates_and_destination_continue() -> void:
	var m := await _fresh_main("neteja")
	m.chase_active = true
	var k0: Dictionary = m.kebabs[0]
	var k1: Dictionary = m.kebabs[1]
	m.dog.global_position = k0.pos
	m.dog.velocity = Vector2.ZERO
	m._pickups(0.016)
	_check(bool(k0.eaten) and m.kebabs_eaten == 1, "a snack eaten on the way out")
	m.dogs_greeted = 3
	m._check_goals()
	_check(m.run_goals_hit.has("hi"), "a goal paid on the way out")
	var save_pre := _save_state()
	_leave_destination(m)
	_check(_save_state() == save_pre, "capturing the destination writes nothing to the save")
	var snap: Dictionary = m.chase_checkpoint.duplicate(true)
	var bones0: int = int(snap.sections.main.bones)
	_check(bones0 == m.bones, "the checkpoint holds the bones as they stood")
	# after the checkpoint: another snack, a goal it completes, a close shave
	m.dog.global_position = k1.pos
	m._pickups(0.016)
	m._check_goals()
	_check(bool(k1.eaten) and m.run_goals_hit.has("snack"), "after it: a second snack and the snack goal")
	_safe(m)
	_tick_until(m, "chase")
	var sw: Node2D = m.chase_sweeper
	var keep_jams: Array[Vector2] = sw.jams.duplicate()
	sw.jams.clear()
	sw.speed = 0.0
	var paid: int = m.bones
	m.human.global_position.y = sw.front_y + HomeChase.CLOSE_SHAVE_GAP * 0.5
	m.dog.global_position.y = m.human.global_position.y + 40.0
	HomeChase.tick(m, 0.0)
	m.human.global_position.y = sw.front_y + HomeChase.CLOSE_SHAVE_CLEAR + 20.0
	m.dog.global_position.y = m.human.global_position.y + 40.0
	HomeChase.tick(m, 0.0)
	_check(m.bones == paid + HomeChase.CLOSE_SHAVE_BONES, "after it: a close shave pays")
	sw.jams = keep_jams
	_get_caught(m)
	_check(_has_verb(m, "restart", "continue"), "the destination checkpoint offers continue")
	var save_lost := _save_state()
	_press(m, "restart")
	_check(_save_state() == save_lost, "continuing from the destination writes nothing to the save")
	_check(m.bones == bones0, "the bones are the checkpoint's, not added to (%d, want %d)" % [m.bones, bones0])
	_check(bool(m.kebabs[0].eaten) and not bool(m.kebabs[1].eaten) and m.kebabs_eaten == 1,
		"the snack eaten before stays eaten; the one after is back")
	_check(m.run_goals_hit.has("hi") and not m.run_goals_hit.has("snack"), "the goal paid before stays paid; the one after is open")
	_check(not bool(m.chase_shave_armed), "the close shave is not carried over")
	# walking the same ground again pays each thing exactly once
	m.dog.global_position = m.kebabs[0].pos
	m._pickups(0.016)
	_check(m.bones == bones0 and m.kebabs_eaten == 1, "the snack eaten before the checkpoint pays nothing again")
	m.dog.global_position = m.kebabs[1].pos
	m._pickups(0.016)
	m._check_goals()
	m._check_goals()
	_check(m.bones == bones0 + 1 + 5 and m.kebabs_eaten == 2,
		"the snack and its goal pay once more, once (%d, want %d)" % [m.bones, bones0 + 6])
	# the destination continue repeats the warning and the full head start
	_check(String(m.chase_phase) == "warning", "a destination continue repeats the warning (%s)" % m.chase_phase)
	_check(is_equal_approx(float(sw.front_y), float(snap.sections.sweeper.front_y)) and sw.jams.size() == 2,
		"the machine is back where it started, both jams ahead")
	var y0: float = sw.front_y
	_safe(m)
	var to_head := _tick_until(m, "head_start", 0.05)
	var to_chase := _tick_until(m, "chase", 0.05)
	_check(to_head >= 0.0 and to_chase >= 0.0 and absf(to_chase + 0.05 - HomeChase.HEAD_START_SECS) < 0.11,
		"and the full head start (%.2f)" % to_chase)
	_check(is_equal_approx(float(sw.front_y), y0), "the machine held through both")
	await _drop(m)


# --- after a midpoint continue, real frames of main -------------------------
func _test_real_frames_midpoint() -> void:
	var m := await _fresh_main("neteja")
	_leave_destination(m)
	_safe(m)
	_tick_until(m, "chase")
	var sw: Node2D = m.chase_sweeper
	var later := _later_jam(sw)
	# set up the later jam directly, the pair well clear and the rope laid
	var only: Array[Vector2] = [later]
	sw.jams = only
	sw.front_y = later.y - 2.0
	m.dog.global_position = Vector2(m.walk_cx + 10.0, later.y + 520.0)
	m.human.global_position = Vector2(m.walk_cx - 10.0, later.y + 600.0)
	m.dog.velocity = Vector2.ZERO
	m.human.velocity = Vector2.ZERO
	m.leash.resnap()
	HomeChase.tick(m, 0.05)
	_check(String(m.chase_checkpoint.get("id", "")) == "midpoint", "frames: the midpoint is taken")
	var d0: Vector2 = m.dog.global_position
	var h0: Vector2 = m.human.global_position
	var fy: float = sw.front_y
	_get_caught(m)
	_press(m, "restart")
	_check(String(m.chase_phase) == "hold", "frames: the midpoint continue holds (%s)" % m.chase_phase)
	var held := await _run_held(m, ["hold"], HomeChase.HOLD_SECS + 1.0)
	_check(m.dog.global_position.y > fy and d0.distance_to(m.dog.global_position) < 400.0
		and h0.distance_to(m.human.global_position) < 400.0, "frames: the pair carried on from where the checkpoint had them")
	_check(bool(held["stable"]), "frames: pair and rope hold together through the countdown %s" % String(held["why"]))
	_check(not bool(held["caught"]), "frames: nobody is caught in the countdown")
	_check(not bool(held["moved"]), "frames: the machine does not move in the countdown")
	_check(absf(float(held["secs"]) - HomeChase.HOLD_SECS) < 0.1,
		"frames: the countdown runs its time and lets go (%.2f s)" % float(held["secs"]))
	_check(String(m.chase_phase) == "chase" and float(sw.jam_t) == 0.0,
		"frames: then the chase is on, the machine already free (jam_t %.2f)" % sw.jam_t)
	var run := await _run_chase(m, 60)
	_check(float(run["end"]) > float(run["start"]) + 20.0,
		"frames: and it rolls straight away (%.0f to %.0f)" % [float(run["start"]), float(run["end"])])
	_check(bool(run["stable"]) and not bool(run["caught"]), "frames: no catch right after the countdown %s" % String(run["why"]))
	await _drop(m)


# --- after a destination continue, real frames of main ----------------------
func _test_real_frames_destination() -> void:
	var m := await _fresh_main("neteja")
	_leave_destination(m)
	var sw: Node2D = m.chase_sweeper
	var fy: float = sw.front_y
	_safe(m)
	_tick_until(m, "chase")
	_get_caught(m)
	_press(m, "restart")
	_check(String(m.chase_phase) == "warning", "frames: the destination continue warns (%s)" % m.chase_phase)
	var held := await _run_held(m, ["warning", "head_start"], HomeChase.WARNING_SECS + HomeChase.HEAD_START_SECS + 1.0)
	_check(bool(held["stable"]), "frames: pair and rope hold together through the head start %s" % String(held["why"]))
	_check(not bool(held["caught"]) and not bool(held["moved"]) and is_equal_approx(float(sw.front_y), fy),
		"frames: no catch and no machine through the warning and head start")
	_check(absf(float(held["secs"]) - HomeChase.WARNING_SECS - HomeChase.HEAD_START_SECS) < 0.1,
		"frames: the warning and the full head start run their time (%.2f s)" % float(held["secs"]))
	var run := await _run_chase(m, 60)
	_check(float(run["end"]) > float(run["start"]) + 20.0, "frames: then the machine runs")
	_check(bool(run["stable"]) and not bool(run["caught"]), "frames: and nobody is caught at once %s" % String(run["why"]))
	await _drop(m)


# --- explicit restarts and leaving the walk clear the checkpoint -----------
func _test_restart_paths_clear() -> void:
	# START AGAIN from the pause menu
	var m := await _fresh_main("neteja")
	_leave_destination(m)
	_check(not m.chase_checkpoint.is_empty(), "a checkpoint is held on the home leg")
	reloads = 0
	game.quick_start = false
	Flow.open_pause(m)
	Flow.open_confirm(m, "restart")
	Flow.confirm_accept(m)
	_check(reloads == 1 and game.quick_start, "START AGAIN starts the walk from scratch")
	_check(m.chase_checkpoint.is_empty() and not HomeChase.can_continue(m), "START AGAIN clears the checkpoint")
	game.quick_start = false
	await _drop(m)

	# the walk select from the end card
	m = await _fresh_main("neteja")
	_leave_destination(m)
	_safe(m)
	_tick_until(m, "chase")
	_get_caught(m)
	reloads = 0
	_press(m, "bark")
	_check(reloads == 1 and m.chase_checkpoint.is_empty(), "the walk select clears the checkpoint")
	_check(game.menu_step == 1, "and opens the walk select")
	game.menu_step = 0
	await _drop(m)

	# any loss on the home leg continues from the checkpoint, not just the
	# machine's: the phone, and a hazard
	for cause: String in ["phone", "manhole"]:
		m = await _fresh_main("neteja")
		_leave_destination(m)
		var hp: int = m.phone_hp
		var at: Vector2 = m.dog.global_position
		m.phone_hp = 0 if cause == "phone" else hp
		m.dog.global_position = at + Vector2(0.0, 300.0)
		m._death("LOST\n\nIt went wrong.", cause)
		_check(HomeChase.can_continue(m), "%s loss on the home leg can continue" % cause)
		_check(_has_verb(m, "restart", "continue") and not _has_verb(m, "restart", "try again"),
			"%s loss: the retry reads continue (%s)" % [cause, str(_verbs(m))])
		reloads = 0
		game.quick_start = false
		_press(m, "restart")
		_check(reloads == 0 and not game.quick_start and not m.frozen,
			"%s loss: continue restores in place" % cause)
		_check(m.phone_hp == hp and m.dog.global_position.distance_to(at) < 1.0,
			"%s loss: the checkpoint's phone and place are back" % cause)
		_check(String(m.chase_phase) == "warning" and String(m.chase_checkpoint.get("id", "")) == "destination",
			"%s loss: from the destination, the warning again" % cause)
		var run := await _run_held(m, ["warning", "head_start"], 1.0)
		_check(bool(run["stable"]) and not bool(run["caught"]) and not m.frozen,
			"%s loss: the walk goes on for real frames afterwards %s" % [cause, String(run["why"])])
		await _drop(m)

	# no checkpoint (a loss on the way out) is the old try again
	m = await _fresh_main("neteja")
	m._death("OFF THE EDGE\n\nShe went over.", "edge")
	_check(not HomeChase.can_continue(m) and _has_verb(m, "restart", "try again"), "no checkpoint: try again")
	reloads = 0
	_press(m, "restart")
	_check(reloads == 1, "and it reloads the walk")
	game.quick_start = false
	await _drop(m)

	# any reload (another walk, the tutorial) drops it
	m = await _fresh_main("neteja")
	_leave_destination(m)
	# by name: on the script object, reload() is GDScript's own
	Flow.call("reload", m)
	_check(m.chase_checkpoint.is_empty(), "every reload clears the checkpoint")
	await _drop(m)


# --- the attract/CI bot -----------------------------------------------------
func _test_autowalk() -> void:
	var m := await _fresh_main("neteja")
	m.auto_walk = true
	_leave_destination(m)
	_safe(m)
	_tick_until(m, "chase")
	var sw: Node2D = m.chase_sweeper
	m.human.global_position = Vector2(m.walk_cx, sw.front_y - 5.0)
	HomeChase.tick(m, 0.1)
	HomeChase.tick(m, HomeChase.CATCH_BEAT * 2.0)
	_check(m.chase_catch_t <= 0.0 and not m.frozen, "the autowalk bot is still never swept")
	_check(not HomeChase.can_continue(m), "and has nothing to continue")
	await _drop(m)


# --- --at-home, through its callable seam -----------------------------------
func _test_at_home() -> void:
	var m := await _fresh_main("neteja")
	m.started = false
	m.frozen = true
	var locked: bool = not game.is_unlocked("neteja")
	# persistence on, pointed at a scratch file, so the hook has to turn it off
	var keep_path: String = game.save_path
	var scratch := "user://test_chase_checkpoint.cfg"
	game.save_path = scratch
	game.persist = true
	var save_before := _save_state()
	m.start_at_home()
	_check(not bool(game.persist), "--at-home never writes the save")
	game.persist = false
	game.save_path = keep_path
	DirAccess.remove_absolute(ProjectSettings.globalize_path(scratch))
	_check(m.started and not m.frozen, "--at-home starts the walk%s" % (" past the star gate" if locked else ""))
	_check(String(m.phase) == "home" and m.dog.global_position.y > m.GATE_Y, "already turned for home, south of the gate")
	_check(String(m.chase_checkpoint.get("id", "")) == "destination", "with the destination checkpoint")
	_check(String(m.chase_phase) == "warning", "and the normal warning (%s)" % m.chase_phase)
	_check(_save_state() == save_before, "starting there changes nothing in the save")
	await _drop(m)
