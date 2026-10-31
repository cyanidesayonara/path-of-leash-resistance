extends SceneTree

# Regression tests for Tony Hawk quests:
# 1. Spell L-E-A-S-H on every walk (universal S-K-A-T-E homage)
# 2. Hidden secret pernil per walk (Catalan/dog holy grail)
# 3. Optional beat-the-clock completion under par time (walk has its own clock)

var _failures := 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		print("FAIL: %s" % msg)
		_failures += 1


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	print("--- Running test_tony_hawk_quests ---")
	var game = root.get_node("Game")
	game.persist = false
	game.records = {}
	var sfx = root.get_node_or_null("Sfx")
	if sfx != null:
		sfx.muted = true

	var Goals: GDScript = load("res://systems/goals.gd")
	var TonyHawk: GDScript = load("res://systems/tony_hawk.gd")

	# 1. Verify words and goals for every campaign walk
	var all_walks: Array = Array(game.LEVELS)
	_check(all_walks.size() >= 27, "every walk is checked (%d)" % all_walks.size())

	var main_scene: PackedScene = load("res://main.tscn")

	for lvl: String in all_walks:
		var w: String = TonyHawk.word_for(lvl)
		_check(w == "LEASH", "walk '%s' word must be LEASH (got '%s')" % [lvl, w])

		var par: int = TonyHawk.clock_target_for(lvl)
		_check(par >= 150 and par <= 210, "walk '%s' par time %d must be between 150s and 210s" % [lvl, par])

		var jamon_pos: Vector2 = TonyHawk.jamon_pos_for(lvl)
		_check(jamon_pos.x < INF and jamon_pos.y < -500.0, "walk '%s' secret pernil pos must be authored down the walk" % lvl)

		var ids: Array = Goals.LEVEL_GOAL_IDS.get(lvl, [])
		_check(ids.size() == 15, "walk '%s' must have exactly 15 goals (has %d)" % [lvl, ids.size()])
		_check("spell" in ids, "walk '%s' must include 'spell' goal" % lvl)
		_check("jamon" in ids, "walk '%s' must include 'jamon' goal" % lvl)
		_check("clock" in ids, "walk '%s' must include 'clock' goal" % lvl)

		# Instance walk to verify clearance and pathing
		game.level_id = lvl
		var inst: Node2D = main_scene.instantiate()
		root.add_child(inst)
		if not inst.is_node_ready():
			await inst.ready
		# the walls and bodies are real physics: ask the space, not
		# solid_rects, which is what the placement itself reads
		await physics_frame
		await physics_frame
		var space: PhysicsDirectSpaceState2D = inst.get_world_2d().direct_space_state

		# Check all letters on this walk
		_check(inst.word_letters.size() == 5, "%s spawns 5 letters" % lvl)
		for l: Dictionary in inst.word_letters:
			var lp: Vector2 = l.pos
			var le: Vector2 = inst.walk_edges(lp.y)
			_check(lp.x >= le.x + 15.0 and lp.x <= le.y - 15.0,
				"%s letter '%s' at %s must be on path (edges %.1f - %.1f)" % [lvl, String(l.letter), lp, le.x, le.y])
			for r: Rect2 in inst.solid_rects:
				_check(not r.grow(4.0).has_point(lp),
					"%s letter '%s' at %s must not intersect solid rect %s" % [lvl, String(l.letter), lp, r])
			_check(_clear_of_bodies(space, lp),
				"%s letter '%s' at %s must not sit inside a solid body" % [lvl, String(l.letter), lp])

		# Check pernil on this walk
		var jp: Vector2 = inst.jamon_pos
		var je: Vector2 = inst.walk_edges(jp.y)
		_check(jp.x >= je.x + 15.0 and jp.x <= je.y - 15.0,
			"%s pernil at %s must be on path (edges %.1f - %.1f)" % [lvl, jp, je.x, je.y])
		for r: Rect2 in inst.solid_rects:
			_check(not r.grow(4.0).has_point(jp),
				"%s pernil at %s must not intersect solid rect %s" % [lvl, jp, r])
		_check(_clear_of_bodies(space, jp),
			"%s pernil at %s must not sit inside a solid body" % [lvl, jp])

		inst.queue_free()

	# 2. Detailed gameplay mechanics test on 'barri'
	game.level_id = "barri"
	var m: Node2D = main_scene.instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready

	_check(m.spell_word == "LEASH", "barri level sets spell_word to LEASH (got '%s')" % m.spell_word)
	_check(m.word_letters.size() == 5, "barri spawns exactly 5 word letters (got %d)" % m.word_letters.size())
	_check(m.clock_target == 165, "barri sets clock_target to 165s (got %d)" % m.clock_target)
	_check(m.jamon_pos.x < INF, "barri sets secret pernil position")
	_check(not m.jamon_found, "secret pernil starts uncollected")
	_check(m.word_letters_collected == 0, "letters start uncollected")

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

	# 4. Simulate secret pernil collection (verifying single payout)
	var bones_before: int = m.bones
	m.dog.global_position = m.jamon_pos
	TonyHawk.tick(m, 0.016)
	_check(m.jamon_found == true, "dog at secret pernil pos finds the pernil")
	_check(m.run_goals_hit.has("jamon"), "jamon goal credited after finding the secret pernil")
	_check(m.bones == bones_before + 5, "pernil awards exactly 5 bones once (got +%d)" % (m.bones - bones_before))

	# 5. Beat-the-clock logic under par time
	m.dog.global_position = Vector2(640.0, m.HOME_Y + 50.0)
	m.human.global_position = Vector2(640.0, m.HOME_Y + 50.0)
	m.elapsed = 150.0 # Under 165s target
	Goals.finish_walk(m)
	_check(m.finished, "walk finishes")
	_check(m.run_goals_hit.has("clock"), "clock goal credited when finishing under target time")

	m.queue_free()

	# 6. Test clock failure when finishing over par time
	var m2: Node2D = main_scene.instantiate()
	root.add_child(m2)
	if not m2.is_node_ready():
		await m2.ready

	m2.dog.global_position = Vector2(640.0, m2.HOME_Y + 50.0)
	m2.human.global_position = Vector2(640.0, m2.HOME_Y + 50.0)
	m2.elapsed = 240.0 # Over 165s target
	Goals.finish_walk(m2)
	_check(not m2.run_goals_hit.has("clock"), "clock goal NOT credited when finishing over par time")
	m2.queue_free()

	if _failures == 0:
		print("test_tony_hawk_quests: OK")
		quit(0)
	else:
		print("test_tony_hawk_quests: %d FAILURES" % _failures)
		quit(1)


# A dog-sized circle at p overlaps no static body on the dog's layer.
func _clear_of_bodies(space: PhysicsDirectSpaceState2D, p: Vector2) -> bool:
	var q := PhysicsShapeQueryParameters2D.new()
	var c := CircleShape2D.new()
	c.radius = 8.0
	q.shape = c
	q.transform = Transform2D(0.0, p)
	q.collision_mask = 1
	return space.intersect_shape(q, 1).is_empty()
