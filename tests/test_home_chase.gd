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
		always = always and bool(mm.chase_active) and not bool(mm.tofu_quest_active) 			and String(mm.chase_kind) in ["sweeper", "bolt", "both"]
	_check(always, "La Neteja always gets a chase, and it replaces Tofu")
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
