extends SceneTree

# Buried finds (systems/buried_finds.gd) and the training they pay for:
# every walk with soft ground off its path has its finds there, the same
# spots every time, never inside anything solid; standing still over one digs
# it up for a training point, once per dog; its scent reaches only as far as
# her nose; and a stat's next level costs the level it reaches.

# loaded once the autoloads are up: the module reads Game
var BuriedFinds: GDScript

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	call_deferred("_run")


func _load(game: Node, lv: String) -> Node2D:
	game.level_id = lv
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	return m


func _run() -> void:
	BuriedFinds = load("res://systems/buried_finds.gd")
	var game: Node = root.get_node("Game")
	game.persist = false
	game.dog = "millie"
	game.training = {}
	game.finds_found = {}
	game.dog_upgrades = {}
	var soft := [m_surf().S.GRASS, m_surf().S.SAND, m_surf().S.MUD]

	# where they lie
	var with_finds := 0
	for lv: String in ["barri", "park", "beach", "trail", "montjuic", "llevant"]:
		var m := await _load(game, lv)
		BuriedFinds.build(m)
		var first: Array = m.finds.duplicate(true)
		_check(m.finds.size() <= BuriedFinds.PER_WALK, "%s has at most %d finds" % [lv, BuriedFinds.PER_WALK])
		if not m.finds.is_empty():
			with_finds += 1
		for f: Dictionary in m.finds:
			var p: Vector2 = f.pos
			var by_tree := false
			for t: Vector2 in m.trees:
				by_tree = by_tree or t.distance_to(p) < 40.0
			for q: Vector2 in m.benches + m.bins:
				by_tree = by_tree or q.distance_to(p) < 40.0
			_check(int(m.surface_at(p)) in soft or by_tree, "%s: a find at %s is in soft ground, a tree's pit or a stash" % [lv, p])
			var inside := false
			for r: Rect2 in m.solid_rects:
				inside = inside or r.has_point(p)
			_check(not inside, "%s: a find at %s is not inside anything solid" % [lv, p])
			_check(p.y > float(m.GATE_Y) and p.y < float(m.START_Y), "%s: a find at %s is on the walk, not past the gate" % [lv, p])
		BuriedFinds.build(m)
		var same: bool = m.finds.size() == first.size()
		for i in range(mini(m.finds.size(), first.size())):
			same = same and (m.finds[i].pos as Vector2) == (first[i].pos as Vector2)
		_check(same, "%s's finds lie in the same spots every time" % lv)
		m.queue_free()
		await process_frame
	_check(with_finds >= 5, "the soft-ground walks all have finds (%d of 6)" % with_finds)

	# digging one up
	var m := await _load(game, "park")
	m.finds_built = true
	BuriedFinds.build(m)
	_check(not m.finds.is_empty(), "El Parc has finds to dig")
	if not m.finds.is_empty():
		var f: Dictionary = m.finds[0]
		var bones0: int = m.bones
		m.dog.global_position = f.pos
		m.dog.velocity = Vector2.ZERO
		var dug_at := -1
		for k in range(240):
			m.dog.velocity = Vector2.ZERO
			if BuriedFinds.tick(m, 1.0 / 60.0) and dug_at < 0 and bool(f.dug):
				dug_at = k
			if bool(f.dug) and dug_at < 0:
				dug_at = k
		_check(bool(f.dug), "standing still over a find digs it up")
		_check(dug_at > 30, "and it takes a moment of digging (%d frames)" % dug_at)
		_check(game.training_points("millie") == 1, "a first find is a training point for her (%d)" % game.training_points("millie"))
		_check(int(m.bones) == bones0 + BuriedFinds.BONUS, "and a few bones")
		_check(game.find_found("park", int(f.i), "millie"), "it is remembered as hers")
		_check(not game.find_found("park", int(f.i), "pipa"), "but not as Pipa's")
		# walking over one does not dig it
		if m.finds.size() > 1:
			var g: Dictionary = m.finds[1]
			for k in range(240):
				m.dog.global_position = g.pos
				m.dog.velocity = Vector2(200, 0)
				BuriedFinds.tick(m, 1.0 / 60.0)
			_check(not bool(g.dug), "running over a find does not dig it")
		# her nose decides how near she must be to smell one
		var reach_m: float = BuriedFinds.scents(m)[0].reach if not BuriedFinds.scents(m).is_empty() else 0.0
		game.dog = "pipa"
		var reach_p: float = BuriedFinds.scents(m)[0].reach if not BuriedFinds.scents(m).is_empty() else 0.0
		game.dog = "millie"
		_check(reach_m > reach_p and reach_p > 0.0, "Millie smells a find from further than Pipa (%.0f vs %.0f)" % [reach_m, reach_p])
	m.queue_free()
	await process_frame
	# the next walk on El Parc: the find she had is a hole, with no scent
	m = await _load(game, "park")
	BuriedFinds.build(m)
	if not m.finds.is_empty():
		_check(bool(m.finds[0].dug), "a find she has dug before is already a hole")
		var smelled := false
		for sc: Dictionary in BuriedFinds.scents(m):
			smelled = smelled or (sc.pos as Vector2) == (m.finds[0].pos as Vector2)
		_check(not smelled, "and smells of nothing")
	m.queue_free()
	await process_frame

	# training: level n costs n (speed, where Millie has no head start)
	game.training = {"millie": 3}
	_check(game.stat_cost("millie", "speed") == 1, "the first level of a stat costs 1")
	_check(game.upgrade_dog_stat("millie", "speed"), "1 point buys it")
	_check(game.stat_cost("millie", "speed") == 2, "the second costs 2")
	_check(game.upgrade_dog_stat("millie", "speed"), "2 points buy it")
	_check(game.training_points("millie") == 0, "which spends all 3")
	_check(not game.upgrade_dog_stat("millie", "speed"), "and nothing is left for the third")
	_check(game.dog_speed_mult("millie") > float(game.DOGS["millie"].get("speed_mult", 1.0)), "trained legs go faster")
	_check(game.dog_nose_mult("millie") > game.dog_nose_mult("pipa"), "her nose, born keen, reaches further")

	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("OK")
	quit(0 if failures.is_empty() else 1)


func m_surf() -> GDScript:
	return load("res://world/surfaces.gd")
