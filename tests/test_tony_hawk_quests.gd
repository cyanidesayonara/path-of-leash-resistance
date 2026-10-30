extends SceneTree

# Regression tests for Tony Hawk quests:
# 1. Spell L-E-A-S-H on every walk (universal S-K-A-T-E homage)
# 2. Hidden secret jamón per walk (find the hidden jamón)
# 3. Optional beat-the-clock completion under par time (no walk timer)

var _failures := 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		print("FAIL: %s" % msg)
		_failures += 1


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	print("--- Running test_tony_hawk_quests ---")
	var Goals: GDScript = load("res://systems/goals.gd")
	var TonyHawk: GDScript = load("res://systems/tony_hawk.gd")

	# 1. Verify words and goals for all 24 campaign walks
	var all_walks: Array = [
		"barri", "street", "park", "beach", "rain", "market",
		"oldtown", "trail", "station", "besos", "site", "spook",
		"scrap", "guell", "neteja", "montjuic", "partit", "port",
		"reial", "vet", "tibidabo", "aigues", "horta", "llevant",
	]

	for lvl: String in all_walks:
		var w: String = TonyHawk.word_for(lvl)
		_check(w == "LEASH", "walk '%s' word must be LEASH (got '%s')" % [lvl, w])

		var par: int = TonyHawk.clock_target_for(lvl)
		_check(par >= 60 and par <= 120, "walk '%s' par time %d must be between 60s and 120s" % [lvl, par])

		var jamon_pos: Vector2 = TonyHawk.jamon_pos_for(lvl)
		_check(jamon_pos.x < INF and jamon_pos.y < -500.0, "walk '%s' secret jamon pos must be authored down the walk" % lvl)

		var ids: Array = Goals.LEVEL_GOAL_IDS.get(lvl, [])
		_check(ids.size() <= 15, "walk '%s' must not exceed 15 goals (has %d)" % [lvl, ids.size()])
		_check("spell" in ids, "walk '%s' must include 'spell' goal" % lvl)
		_check("jamon" in ids, "walk '%s' must include 'jamon' goal" % lvl)
		_check("clock" in ids, "walk '%s' must include 'clock' goal" % lvl)

	# 2. Level instance verification on 'barri'
	var main_scene: PackedScene = load("res://main.tscn")
	var m: Node2D = main_scene.instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready

	_check(m.spell_word == "LEASH", "barri level sets spell_word to LEASH (got '%s')" % m.spell_word)
	_check(m.word_letters.size() == 5, "barri spawns exactly 5 word letters (got %d)" % m.word_letters.size())
	_check(m.clock_target == 75, "barri sets clock_target to 75s (got %d)" % m.clock_target)
	_check(m.jamon_pos.x < INF, "barri sets secret jamon position")
	_check(not m.jamon_found, "secret jamon starts uncollected")
	_check(m.word_letters_collected == 0, "letters start uncollected")

	# Check that letters and secret jamon do not intersect solid obstacles
	for l: Dictionary in m.word_letters:
		var lpos: Vector2 = l.pos
		for r: Rect2 in m.solid_rects:
			_check(not r.grow(4.0).has_point(lpos), "letter '%s' at %s must not intersect solid rect %s" % [String(l.letter), lpos, r])

	for r: Rect2 in m.solid_rects:
		_check(not r.grow(4.0).has_point(m.jamon_pos), "secret jamon at %s must not intersect solid rect %s" % [m.jamon_pos, r])

	# 3. Simulate picking up letters
	var first_letter: Dictionary = m.word_letters[0]
	m.dog.global_position = first_letter.pos
	TonyHawk.tick(m, 0.016)
	_check(first_letter.collected == true, "dog at letter pos collects the letter")
	_check(m.word_letters_collected == 1, "collected count increments to 1")

	# Collect remaining letters
	for i in range(1, m.word_letters.size()):
		var l: Dictionary = m.word_letters[i]
		m.dog.global_position = l.pos
		TonyHawk.tick(m, 0.016)

	_check(m.word_letters_collected == 5, "all 5 letters collected")
	_check(m.run_goals_hit.has("spell"), "spell goal credited after collecting all letters")

	# 4. Simulate secret jamon collection
	m.dog.global_position = m.jamon_pos
	TonyHawk.tick(m, 0.016)
	_check(m.jamon_found == true, "dog at secret jamon pos finds the jamon")
	_check(m.run_goals_hit.has("jamon"), "jamon goal credited after finding the secret jamon")

	# 5. Beat-the-clock logic
	m.dog.global_position = Vector2(640.0, m.HOME_Y + 50.0)
	m.human.global_position = Vector2(640.0, m.HOME_Y + 50.0)
	m.elapsed = 60.0 # Under 75s target
	Goals.finish_walk(m)
	_check(m.finished, "walk finishes")
	_check(m.run_goals_hit.has("clock"), "clock goal credited when finishing under target time")

	# Cleanup m
	m.queue_free()

	# 6. Test clock failure when finishing over par time
	var m2: Node2D = main_scene.instantiate()
	root.add_child(m2)
	if not m2.is_node_ready():
		await m2.ready

	m2.dog.global_position = Vector2(640.0, m2.HOME_Y + 50.0)
	m2.human.global_position = Vector2(640.0, m2.HOME_Y + 50.0)
	m2.elapsed = 120.0 # Over 75s target
	Goals.finish_walk(m2)
	_check(not m2.run_goals_hit.has("clock"), "clock goal NOT credited when finishing over par time")
	m2.queue_free()

	if _failures == 0:
		print("test_tony_hawk_quests: OK")
		quit(0)
	else:
		print("test_tony_hawk_quests: %d FAILURES" % _failures)
		quit(1)
