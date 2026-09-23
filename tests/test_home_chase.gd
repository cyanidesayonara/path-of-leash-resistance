extends SceneTree

# The home-leg chase (systems/home_chase.gd) on a real main scene: a chase
# starts with the right machine and speed for its kind, reaching the owner or
# the dog ends the walk with that kind's message, the attract/CI bot is never
# swept, and the tutorial never rolls a chase.
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
	HomeChase.tick(main, 0.0)
	return main.msg_label.text if main.frozen else ""


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
