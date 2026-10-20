extends SceneTree

# The home-leg chase (systems/home_chase.gd) on a real main scene: a chase
# starts with the right machine and speed for its kind, reaching the owner or
# the dog ends the walk with that kind's message after the catch beat, the
# attract/CI bot is never swept, and the tutorial never rolls a chase. Since
# #20 the chase lives on La Neteja only: it never rolls elsewhere, always
# does there, and the other walks draw exactly the random numbers they did.
#
# The autowalk runs in ci.yml cannot reach the "caught" branch (the bot is
# unsweepable by design) and an idle soak ends before the home leg, so this is
# the only thing that exercises it.

# loaded in _run, not preloaded: the module refers to the Game autoload, which
# does not exist yet while this test script is being compiled
var HomeChase: GDScript

var checks := 0
var failures: Array[String] = []


class BoundaryThreat extends Node2D:
	var front_y := -20.0
	var shallow_y := 35.0

	func threat_boundary() -> float:
		return shallow_y


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	# deferred so the autoloads are registered before main.gd is compiled
	call_deferred("_run")


func _fresh_main() -> Node2D:
	var main: Node2D = load("res://main.tscn").instantiate()
	root.add_child(main)
	if not main.is_node_ready():
		await main.ready
	return main


func _drop(main: Node2D) -> void:
	main.queue_free()
	await process_frame


# Put the sweeper's front edge just past one body and well short of the other,
# tick once, and report the game-over text (empty if the walk carries on).
func _catch(main: Node2D, catch_human: bool) -> String:
	var sw: Node2D = main.chase_sweeper
	var y := 0.0
	if catch_human:
		y = main.human.global_position.y + 5.0
		main.dog.global_position.y = y + 400.0
	else:
		y = main.dog.global_position.y + 5.0
		main.human.global_position.y = y + 400.0
	sw.front_y = y
	main.frozen = false
	main.msg_label.text = ""
	main.chase_catch_t = 0.0
	sw.z_index = 0
	HomeChase.tick(main, 0.0)
	if main.auto_walk:
		return main.msg_label.text if main.frozen else ""
	# the catch beat: caught, but the card waits while the machine rolls over
	_check(not main.frozen and main.chase_catch_t > 0.0, "a catch starts the beat, not the card")
	_check(int(sw.z_index) > 0, "the machine comes to the front to roll over them")
	HomeChase.tick(main, HomeChase.CATCH_BEAT * 0.5)
	_check(not main.frozen, "half way through the beat the card is still waiting")
	HomeChase.tick(main, HomeChase.CATCH_BEAT)
	return main.msg_label.text if main.frozen else ""


# the random number after two draws from this seed: what follows a roll that
# came up under 0.25, which drew a second number for the kind
func randf_from_two_ahead(sd: int) -> float:
	seed(sd)
	randf()
	randf()
	return randf()


func _run() -> void:
	HomeChase = load("res://systems/home_chase.gd")
	for kind: String in ["sweeper", "bolt", "both"]:
		var main := await _fresh_main()
		main.auto_walk = false
		main.chase_active = true
		main.chase_kind = kind
		HomeChase.begin(main)
		# past the warning and the head start (tests/test_chase_checkpoint.gd)
		HomeChase.release(main)
		var sw: Node2D = main.chase_sweeper
		_check(sw != null and sw.get_parent() == main, "%s: begin() adds the machine to the scene" % kind)
		if sw == null:
			await _drop(main)
			continue
		# behind the living: it must never draw over the human or the leash
		_check(int(sw.z_index) == 0 and sw.get_index() < main.dog.get_index() and sw.get_index() < main.human.get_index(),
			"%s: the machine draws behind the dog and the human" % kind)
		# the closest approach is tracked for the "outrun" goal
		sw.front_y = main.dog.global_position.y - 300.0
		main.human.global_position.y = main.dog.global_position.y + 50.0
		main.auto_walk = true
		HomeChase.tick(main, 0.0)
		main.auto_walk = false
		_check(absf(float(main.chase_min_gap) - float(sw.gap_to(main.dog.global_position))) < 0.5,
			"%s: the chase remembers how close it came (%.0f)" % [kind, float(main.chase_min_gap)])
		var want_speed: float = {"sweeper": HomeChase.CHASE_SPEED, "bolt": HomeChase.CHASE_SPEED_BOLT,
			"both": HomeChase.CHASE_SPEED_BOTH}[kind]
		_check(is_equal_approx(float(sw.speed), want_speed), "%s: runs at %.0f (is %.0f)" % [kind, want_speed, float(sw.speed)])
		_check(bool(main.human.panic) == (kind != "sweeper"), "%s: the owner panics only when something is chasing them" % kind)
		var human_msg := await _catch(main, true)
		var dog_msg := await _catch(main, false)
		if kind == "sweeper":
			_check(human_msg.begins_with("THE SWEEPER GOT YOUR HUMAN"), "sweeper reaching the owner ends the walk (got '%s')" % human_msg.get_slice("\n", 0))
			_check(dog_msg.begins_with("YOU WENT INTO THE BRUSHES"), "sweeper reaching the dog ends the walk (got '%s')" % dog_msg.get_slice("\n", 0))
		else:
			_check(human_msg.begins_with("THEY GOT YOUR HUMAN"), "%s reaching the owner ends the walk (got '%s')" % [kind, human_msg.get_slice("\n", 0)])
			_check(dog_msg.begins_with("NOBODY WAITED FOR YOU"), "%s reaching the dog ends the walk (got '%s')" % [kind, dog_msg.get_slice("\n", 0)])
		# the attract/CI bot carries an unsweepable dog
		main.auto_walk = true
		_check(await _catch(main, true) == "", "%s: the autowalk bot is never swept" % kind)
		await _drop(main)

	# the profile begin() runs is held on main, and its copy is what a catch
	# reads: a custom profile's text survives into tick, even on a walk whose
	# own profile says something else
	var pf := await _fresh_main()
	pf.auto_walk = false
	pf.lvl = "neteja"
	pf.chase_active = true
	pf.chase_kind = "sweeper"
	_check(pf.get("chase_profile") is Dictionary and pf.get("chase_profile").is_empty(),
		"no profile is held before the chase begins")
	var custom := {"id": "probe", "script": "res://entities/sweeper.gd", "kind": "sweeper", "speed": 140.0,
		"warning": "PROBE", "caught_human": "PROBE HUMAN\n\nsecond line", "caught_dog": "PROBE DOG\n\nsecond line",
		"bands": []}
	HomeChase.begin(pf, custom)
	HomeChase.release(pf)
	_check(pf.get("chase_profile") is Dictionary and String(pf.get("chase_profile").get("id", "")) == "probe",
		"begin() holds the profile it was given")
	var probe_human := await _catch(pf, true)
	var probe_dog := await _catch(pf, false)
	_check(probe_human.get_slice("\n", 0) == "PROBE HUMAN", "a caught human reads the held profile's copy (got '%s')" % probe_human.get_slice("\n", 0))
	_check(probe_dog.get_slice("\n", 0) == "PROBE DOG", "a caught dog reads the held profile's copy (got '%s')" % probe_dog.get_slice("\n", 0))
	await _drop(pf)
	# with no profile handed in, the walk's own is held
	var own := await _fresh_main()
	own.auto_walk = false
	own.lvl = "neteja"
	own.chase_active = true
	own.chase_kind = "sweeper"
	HomeChase.begin(own)
	_check(own.get("chase_profile") is Dictionary and String(own.get("chase_profile").get("id", "")) == "neteja",
		"begin() holds La Neteja's own profile by default")
	await _drop(own)

	# the chase level's set pieces, on a sweeper chase
	var cm := await _fresh_main()
	cm.auto_walk = false
	cm.frozen = false
	cm.chase_active = true
	cm.chase_kind = "sweeper"
	var dy: float = cm.dog.global_position.y
	cm.chase_jams = [Vector2(800.0, dy - 2000.0), Vector2(800.0, dy + 400.0)] as Array[Vector2]
	HomeChase.begin(cm)
	HomeChase.release(cm)
	var csw: Node2D = cm.chase_sweeper
	_check(csw.jams.size() == 1 and csw.jams[0].y > csw.front_y,
		"only the dumpsters still ahead of the machine can jam it (%d)" % csw.jams.size())
	csw.jams.clear()
	csw.speed = 0.0
	# CLOSE SHAVE: the brooms within a whisker of the rearmost, then clear
	cm.human.global_position.y = dy - 50.0
	var bones0: int = cm.bones
	csw.front_y = cm.human.global_position.y - HomeChase.CLOSE_SHAVE_GAP * 0.5
	HomeChase.tick(cm, 0.0)
	_check(cm.chase_shave_armed and cm.bones == bones0, "within a whisker arms a close shave, pays nothing yet")
	csw.front_y = cm.human.global_position.y - HomeChase.CLOSE_SHAVE_CLEAR - 20.0
	HomeChase.tick(cm, 0.0)
	_check(not cm.chase_shave_armed and cm.bones == bones0 + HomeChase.CLOSE_SHAVE_BONES,
		"getting clear again is a close shave (+%d bones)" % (cm.bones - bones0))
	# the camera leans back just far enough to get the machine in shot
	var view_half: float = cm.get_viewport_rect().size.y * 0.5 / float(cm.cam.zoom.y)
	var cam_y: float = (cm.dog.global_position.y + cm.human.global_position.y) * 0.5 \
		+ HomeChase.CAMERA_PAIR_OFFSET_Y
	csw.front_y = cam_y - view_half + HomeChase.LEAN_SHOW - 50.0
	for i in range(60):
		HomeChase.tick(cm, 0.1)
	_check(absf(float(cm.chase_lean) - 50.0) < 2.0, "leans 50 to show a machine 50 out of shot (%.1f)" % float(cm.chase_lean))
	csw.front_y = cam_y - view_half - 600.0
	for i in range(60):
		HomeChase.tick(cm, 0.1)
	_check(float(cm.chase_lean) < 1.0, "does not lean for a machine far out of reach (%.1f)" % float(cm.chase_lean))
	# The selected camera curve is the production target. It is bounded by
	# rendered runway, not a desktop world-unit guess.
	var final_dog_y := 100.0
	var final_human_y := 40.0
	var final_cam_y: float = (final_dog_y + final_human_y) * 0.5 \
		+ HomeChase.CAMERA_PAIR_OFFSET_Y
	var front_y: float = final_cam_y - 360.0 + HomeChase.LEAN_SHOW - 50.0
	var target: float = HomeChase.camera_target(
		front_y, final_dog_y, final_human_y, 720.0, 1.0)
	_check(absf(target - 50.0) < 0.01,
		"the production curve leans enough to hold its deeper threat line (%.1f)" % target)
	# Real canvas-height / camera-zoom pairs from desktop, a forced 844x390
	# phone frame, and a forced 390x844 portrait frame. The first two fixtures
	# deliberately request more lean than their cap permits.
	for fixture: Array in [
		[720.0, 1.28, true],
		[500.0, 1.28 / 1.44, true],
		[1910.0, 1.28 / 1.45, false],
	]:
		var viewport_h: float = fixture[0]
		var zoom: float = fixture[1]
		var should_cap: bool = fixture[2]
		var dog_y := 100.0
		var human_y := 40.0
		var base_cam_y: float = (dog_y + human_y) * 0.5 + HomeChase.CAMERA_PAIR_OFFSET_Y
		var fixture_half := viewport_h * 0.5 / zoom
		var requested := 150.0
		var boundary_y: float = base_cam_y - fixture_half + HomeChase.LEAN_SHOW - requested
		target = HomeChase.camera_target(boundary_y, dog_y, human_y, viewport_h, zoom)
		var target_cam_y: float = base_cam_y - target
		var runway_px: float = (target_cam_y + fixture_half - maxf(dog_y, human_y)) * zoom
		var reserved_px: float = HomeChase.CAMERA_RUNWAY_PX \
			+ HomeChase.CAMERA_SHAKE_WORLD * zoom
		_check(runway_px >= reserved_px - 0.01,
			"the camera reserves moving runway at %.0fpx / %.3f zoom (%.1f)" % [viewport_h, zoom, runway_px])
		_check((target < requested - 0.01) == should_cap,
			"the runway cap engages only where needed at %.0fpx / %.3f zoom (%.1f)" % [viewport_h, zoom, target])
	cm.chase_lean = 100.0
	cm.dog.global_position.y = 100.0
	cm.human.global_position.y = -100.0
	csw.front_y = -50.0
	HomeChase._lean(cm, csw, 0.01)
	var live_cap: float = HomeChase.camera_runway_cap(
		float(cm.dog.global_position.y), float(cm.human.global_position.y),
		float(cm.get_viewport_rect().size.y), float(cm.cam.zoom.y))
	_check(float(cm.chase_lean) <= live_cap + 0.01,
		"an old eased lean is clamped immediately when the pair opens (%.1f <= %.1f)"
			% [float(cm.chase_lean), live_cap])
	var turbo_zoom: float = 1.28 / 1.44
	var turbo_speed: float = 561.0
	var turbo_cap: float = HomeChase.camera_runway_cap(
		100.0, 40.0, 500.0, turbo_zoom, turbo_speed, 6.0)
	var turbo_base_cam: float = 70.0 + HomeChase.CAMERA_PAIR_OFFSET_Y
	var turbo_runway_px: float = (turbo_base_cam - turbo_cap
		+ 250.0 / turbo_zoom - 100.0) * turbo_zoom
	var turbo_reserve_px: float = HomeChase.CAMERA_RUNWAY_PX \
		+ (HomeChase.CAMERA_SHAKE_WORLD + turbo_speed / 6.0) * turbo_zoom
	_check(turbo_cap < 0.0 and turbo_runway_px >= turbo_reserve_px - 0.01,
		"turbo framing leads the smoothed camera enough to retain 110px (cap %.1f, %.1fpx)"
			% [turbo_cap, turbo_runway_px])
	csw.front_y = -123.0
	_check(is_equal_approx(csw.threat_boundary(), -123.0),
		"the sweeper explicitly exposes its brushes as the authored boundary")
	_check(is_equal_approx(HomeChase.threat_boundary(csw), -123.0),
		"the chase reads the sweeper's authored boundary")
	var flood_probe := BoundaryThreat.new()
	_check(is_equal_approx(HomeChase.threat_boundary(flood_probe), flood_probe.shallow_y),
		"a future threat can expose its own shallow visible boundary")
	flood_probe.free()
	var actual_h: float = cm.get_viewport_rect().size.y
	var actual_zoom: float = float(cm.cam.zoom.y)
	var rendered_top: float = cm.cam.get_screen_center_position().y - actual_h * 0.5 / actual_zoom
	_check(not HomeChase.threat_visible(cm, rendered_top + 47.9 / actual_zoom),
		"a threat boundary 47.9 rendered px below the top is not visible enough")
	_check(HomeChase.threat_visible(cm, rendered_top + 48.0 / actual_zoom),
		"a threat boundary 48 rendered px below the top is visible")
	# junk the brooms flung knocks the dog over if it hits her
	var junk: Node2D = Node2D.new()
	junk.set_script(load("res://entities/cone.gd"))
	cm.add_child(junk)
	junk.setup(cm, cm.dog, cm.human, "crate")
	junk.global_position = cm.dog.global_position + Vector2(0.0, -10.0)
	junk.vel = Vector2(0.0, 400.0)
	junk.flung_t = 1.0
	cm.dog.tumble_t = 0.0
	junk._physics_process(1.0 / 60.0)
	_check(float(cm.dog.tumble_t) > 0.0, "flung junk knocks the dog over")
	await _drop(cm)

	# the chase lives on La Neteja: never elsewhere, always there. And the
	# other walks draw exactly the random numbers the old roll drew (one, and
	# a second when it came up under 0.25), so seeded walks replay unchanged.
	var mm := await _fresh_main()
	mm.auto_walk = false
	mm.tutorial_mode = false
	var same_draws := true
	var never_elsewhere := true
	for sd in range(60):
		mm.lvl = "street"
		seed(sd)
		var first := randf()
		var expect_next := randf() if first >= 0.25 else randf_from_two_ahead(sd)
		seed(sd)
		HomeChase.roll(mm)
		never_elsewhere = never_elsewhere and not bool(mm.chase_active)
		same_draws = same_draws and is_equal_approx(randf(), expect_next)
	_check(never_elsewhere, "no chase ever rolls on another walk")
	_check(same_draws, "other walks draw the same random numbers as before")
	var always := true
	for sd in range(20):
		mm.lvl = "neteja"
		mm.tofu_quest_active = true
		seed(sd)
		HomeChase.roll(mm)
		always = always and bool(mm.chase_active) and not bool(mm.tofu_quest_active) \
			and String(mm.chase_kind) == "sweeper"
	_check(always, "La Neteja always gets the sweeper chase, and it replaces Tofu")
	await _drop(mm)

	# the way out of a chase walk is not the chase: no dread before the machine
	# is on the road (it used to build SCARED from the first step)
	var calm := await _fresh_main()
	calm.chase_active = true
	calm.chase_sweeper = null
	calm.mood.reset()
	for i in range(10):
		calm._tick_mood(0.5)
	_check(float(calm.mood.charge.get(calm.mood.M.SCARED, 0.0)) <= 0.001,
		"no dread on the way out, before the machine exists (charge %.2f)" % float(calm.mood.charge.get(calm.mood.M.SCARED, 0.0)))
	await _drop(calm)

	# Even on the live chase phase, fear waits until the brushes have entered
	# far enough into the actual rendered viewport.
	var fear := await _fresh_main()
	fear.auto_walk = false
	fear.started = true
	fear.chase_active = true
	fear.chase_kind = "sweeper"
	HomeChase.begin(fear)
	HomeChase.release(fear)
	fear.mood.reset()
	var fear_sw: Node2D = fear.chase_sweeper
	fear_sw.speed = 0.0
	var fear_h: float = fear.get_viewport_rect().size.y
	var fear_zoom: float = float(fear.cam.zoom.y)
	var fear_top: float = fear.cam.get_screen_center_position().y - fear_h * 0.5 / fear_zoom
	fear_sw.front_y = fear_top + 47.0 / fear_zoom
	fear._tick_mood(0.2)
	var hidden_charge: float = float(fear.mood.charge.get(fear.mood.M.SCARED, 0.0))
	fear_sw.front_y = fear_top + 49.0 / fear_zoom
	fear._tick_mood(0.2)
	var visible_charge: float = float(fear.mood.charge.get(fear.mood.M.SCARED, 0.0))
	_check(hidden_charge <= 0.001,
		"fear charge stays zero before the threat is visible enough (%.3f)" % hidden_charge)
	_check(visible_charge > hidden_charge,
		"fear charge increases once the threat is visible enough (%.3f)" % visible_charge)
	await _drop(fear)

	# the tutorial is calm by construction: no chase, whatever the dice say
	var tut := await _fresh_main()
	tut.tutorial_mode = true
	HomeChase.roll(tut)
	_check(not tut.chase_active, "the tutorial never rolls a chase")
	await _drop(tut)

	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("HOME CHASE OK")
		quit(0)
	else:
		print("HOME CHASE FAIL")
		quit(1)
