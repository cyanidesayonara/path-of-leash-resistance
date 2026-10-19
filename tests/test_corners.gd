extends SceneTree

# Dia de Partit's corners: the kickabout telegraphs before the ball moves,
# the scarf comes off before kick-off, and the thieves stop at the whistle.

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _edges(_y: float) -> Vector2:
	return Vector2(240.0, 1040.0)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_kickabout()
	_scarf()
	await _live()
	print("test_corners: %d checks, %d failures" % [checks, failures.size()])
	quit(1 if failures.size() > 0 else 0)


func _kickabout() -> void:
	var far := Vector2(0.0, 0.0)
	var near := Kickabout.MOUTH + Vector2(-200.0, 0.0)
	var k := Kickabout.new()
	var quiet: Dictionary = k.tick(30.0, far, Vector2.RIGHT, false, false)
	_check(not bool(quiet["yell"]) and k.state == Kickabout.St.HELD, "nobody yells while she is streets away")
	var cue: Dictionary = k.tick(Kickabout.GAP - 0.1, near, Vector2.RIGHT, false, false)
	_check(not bool(cue["yell"]) and k.state == Kickabout.St.HELD, "the ball stays with the kids")
	cue = k.tick(0.2, near, Vector2.RIGHT, false, false)
	_check(bool(cue["yell"]) and k.state == Kickabout.St.WARN, "a kid yells before it rolls")
	_check(k.pos == Kickabout.KIDS[1], "the yell does not move the ball")
	k.tick(Kickabout.WARN_T - 0.05, far, Vector2.RIGHT, false, false)
	_check(k.state == Kickabout.St.WARN, "the yell holds")
	k.tick(0.1, far, Vector2.RIGHT, false, false)
	_check(k.state == Kickabout.St.ROLLING, "then the ball is loose")
	var x0: float = k.pos.x
	k.tick(0.3, far, Vector2.RIGHT, false, false)
	_check(k.pos.x < x0, "it rolls west across the avenue")
	k.state = Kickabout.St.LOOSE
	k.pos = Vector2(500.0, -2180.0)
	k.tick(0.05, k.pos, Vector2.RIGHT, false, false)
	_check(k.state == Kickabout.St.CARRIED, "she can pick the ball up")
	cue = k.tick(0.05, Kickabout.MOUTH, Vector2.RIGHT, false, false)
	_check(bool(cue["gol"]) and k.scored, "between the jackets is a goal")
	var over := Kickabout.new()
	over.tick(0.1, far, Vector2.RIGHT, false, true)
	_check(over.gone and over.state == Kickabout.St.LOOSE, "kick-off sends the kids inside")
	cue = over.tick(30.0, far, Vector2.RIGHT, false, true)
	_check(not bool(cue["yell"]), "nobody yells once they have gone in")


func _scarf() -> void:
	var calm := _fly(false)
	var gust := _fly(true)
	_check(gust < calm, "wind takes the scarf faster than a slip (%d, %d)" % [gust, calm])
	var s := LostScarf.new()
	s.wind = false
	s.tick(0.05, LostScarf.START, Vector2.DOWN, false, false, Callable(self, "_edges"))
	var n := 0
	while s.state == LostScarf.St.FLYING and n < 500:
		s.tick(0.05, Vector2.ZERO, Vector2.DOWN, false, false, Callable(self, "_edges"))
		n += 1
	_check(s.state == LostScarf.St.REST, "the scarf fetches up")
	_check(s.scarf.x < 320.0, "it lands at the edge of the river")
	s.tick(8.0, Vector2.ZERO, Vector2.DOWN, false, false, Callable(self, "_edges"))
	_check(s.waiting(), "they wait by the lamp, and say so")
	s.tick(0.05, s.scarf, Vector2.DOWN, false, false, Callable(self, "_edges"))
	_check(s.state == LostScarf.St.CARRIED, "she can pick the scarf up")
	var cue: Dictionary = s.tick(0.05, s.at, Vector2.DOWN, false, false, Callable(self, "_edges"))
	_check(bool(cue["good"]) and s.back, "bringing it back is the goal")
	var late := LostScarf.new()
	late.tick(0.1, LostScarf.START, Vector2.DOWN, false, true, Callable(self, "_edges"))
	_check(late.state == LostScarf.St.MISSED, "after kick-off the scarf stays on")


func _fly(wind: bool) -> int:
	var s := LostScarf.new()
	s.wind = wind
	s.tick(0.05, LostScarf.START, Vector2.DOWN, false, false, Callable(self, "_edges"))
	var n := 0
	while s.state == LostScarf.St.FLYING and n < 500:
		s.tick(0.05, Vector2.ZERO, Vector2.DOWN, false, false, Callable(self, "_edges"))
		n += 1
	return n


func _live() -> void:
	var game = root.get_node("Game")
	game.persist = false
	root.get_node("Sfx").muted = true
	game.level_id = "partit"
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	for k in range(3):
		await physics_frame
	m._skip_title()
	m.tip_t = 0.0
	for k in range(5):
		await physics_frame
	var P: GDScript = load("res://systems/partit.gd")
	_check(m.fountains.has(P.BOWL), "the bar has a water bowl")
	_check(m.kickabout != null and m.lost_scarf != null, "the side street and the scarf are on")
	_check(m.crowded(), "two pickpockets can work before kick-off")
	m.dog.global_position = Vector2(640.0, -1600.0)
	m.human.global_position = Vector2(600.0, -1560.0)
	m.cam.position_smoothing_enabled = false
	m.cam.position = Vector2(640.0, -1600.0)
	m.leash.resnap()
	for k in range(4):
		await physics_frame
	var fans := 0
	for p in m.get_tree().get_nodes_in_group("pairs"):
		var col: Color = p.owner_col
		if col.is_equal_approx(P.HOME_BLUE) or col.is_equal_approx(P.HOME_CLARET):
			fans += 1
	_check(fans >= 2, "fans' dogs are walking the avenue (%d)" % fans)
	m.cam.position.y = -1800.0
	m.pp_spawn_t = 0.0
	m._tick_crowd(0.2)
	_check(m.get_tree().get_nodes_in_group("pickpockets").size() == 1, "the first thief goes for your human")
	for pp in m.get_tree().get_nodes_in_group("pickpockets"):
		pp.queue_free()
	await physics_frame
	m.pp_spawn_t = 0.0
	m._tick_crowd(0.2)
	_check(m.pp_spawned == 2, "the second works a fan")
	for pp in m.get_tree().get_nodes_in_group("pickpockets"):
		pp.queue_free()
	await physics_frame
	m.pp_spawn_t = 0.0
	m._tick_crowd(0.2)
	_check(m.get_tree().get_nodes_in_group("pickpockets").size() == 0, "two is the lot")
	m.match_day.phase = MatchDay.Ph.KICKOFF
	_check(not m.crowded(), "kick-off sends the thieves off")
	var ids: Array = load("res://systems/goals.gd").LEVEL_GOAL_IDS["partit"]
	_check("scarf" in ids and "kickabout" in ids and not ("hi" in ids), "the two new goals, and not a thirteenth")
