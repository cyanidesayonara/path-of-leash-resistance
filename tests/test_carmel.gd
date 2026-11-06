extends SceneTree

# Tests Walk 28: Els Búnquers del Carmel (systems/carmel.gd)
# - Registration in Game.LEVELS, CAROUSEL, STAR_GATE, LEVEL_NAMES, LEVEL_SUBTITLES
# - 15 goals in LEVEL_GOAL_IDS, Tony Hawk CLOCK_TARGETS, JAMON_POS
# - Geometry: edge nodes, bunker solids, circular cannon emplacements
# - Live event: El Guitarrista del Carmel (systems/guitarrista.gd)

const DT := 1.0 / 60.0
const Surfaces := preload("res://world/surfaces.gd")
const Guitarrista := preload("res://systems/guitarrista.gd")

var checks := 0
var failures: Array[String] = []


class FakeMain:
	extends Node2D
	var lvl := "carmel"
	var tutorial_mode := false
	var START_Y := 200.0
	var GATE_Y := -4800.0
	var POP_SAY := 0
	var bones := 0
	var saves_done := 0
	var dog: Node2D
	var human: FakeHuman
	var combo: FakeCombo
	var feed: FakeFeed
	var guitarrista: Guitarrista = null
	var marks: Array[Vector2] = []
	var stalls: Array = []
	var stall_kinds: Array = []
	var astands: Array[Vector2] = []
	var manholes: Array[Vector2] = []
	var cone_spots: Array[Vector2] = []
	var fountains: Array[Vector2] = []
	var bins: Array[Vector2] = []
	var benches: Array[Vector2] = []
	var poles: Array[Vector2] = []
	var deco_pole_count := 0
	var conveyor_zone := Rect2()
	var conveyor_dir := Vector2.ZERO
	var gate_text := ""
	var TREE_FOREST := 1

	func _init() -> void:
		dog = Node2D.new()
		human = FakeHuman.new()
		combo = FakeCombo.new()
		feed = FakeFeed.new()
		add_child(dog)
		add_child(human)
		dog.set_script(FakeDogScript)

	func walk_edges(y: float) -> Vector2:
		return Vector2(360.0, 920.0)

	func float_text(_pos: Vector2, _txt: String, _col: Color, _kind: int = 0) -> void:
		pass


class FakeDogScript:
	extends Node2D
	var velocity := Vector2.ZERO


class FakeHuman:
	extends Node2D
	var patience := 100.0
	func bump(_dir: Vector2, p: float) -> void:
		patience -= p


class FakeCombo:
	func add(_kind: String, _pts: int) -> void:
		pass


class FakeFeed:
	func say(_txt: String, _tone: int = 0) -> void:
		pass


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	create_timer(20.0).timeout.connect(func():
		print("FAIL: test watchdog timeout")
		quit(1)
	)
	call_deferred("_run")


func _run() -> void:
	root.get_node("Sfx").muted = true
	var game: Node = root.get_node("Game")
	var goals_mod: GDScript = load("res://systems/goals.gd")
	var th_mod: GDScript = load("res://systems/tony_hawk.gd")
	var carmel: GDScript = load("res://systems/carmel.gd")

	# 1. Registration checks
	_check(game.LEVELS.has("carmel"), "carmel in Game.LEVELS")
	_check(game.CAROUSEL.has("carmel"), "carmel in Game.CAROUSEL")
	_check(game.LEVEL_NAMES.has("carmel"), "LEVEL_NAMES has carmel")
	_check(game.LEVEL_SUBTITLES.has("carmel"), "LEVEL_SUBTITLES has carmel")
	_check(game.STAR_GATE.has("carmel"), "STAR_GATE has carmel")
	_check(game.chase_gate_needed("carmel") == "gracia", "carmel gated by gracia")

	# 2. Goals & Tony Hawk checks
	var g_list: Array = goals_mod.LEVEL_GOAL_IDS.get("carmel", [])
	_check(g_list.size() == 15, "carmel has 15 goals: %d" % g_list.size())
	_check(th_mod.CLOCK_TARGETS.has("carmel"), "CLOCK_TARGETS has carmel")
	_check(th_mod.JAMON_POS.has("carmel"), "JAMON_POS has carmel")

	# 3. Geometry & Layout
	var m := FakeMain.new()
	root.add_child(m)

	var nodes: Array = carmel.edge_nodes(m)
	_check(nodes.size() >= 8, "edge_nodes returns at least 8 sections")
	for node: Dictionary in nodes:
		_check(node.has("y") and node.has("cx") and node.has("half"), "node has y, cx, half")
		_check(float(node["half"]) > 200.0 and float(node["half"]) < 320.0, "node half width in bounds")

	var pl: Array = carmel.build(m)
	_check(pl.size() == 2, "build returns [marks, snacks]")
	_check(pl[0].size() >= 5, "at least 5 marks registered")
	_check(pl[1].size() >= 3, "at least 3 snacks registered")
	_check(m.poles.size() >= 10, "poles populated with pines, fence posts, cannons")
	_check(carmel.solids(m).size() >= 1, "bunker solids registered")
	_check(carmel.cannons().size() == 3, "3 circular cannon emplacements registered")

	# 4. Surface detection
	_check(carmel.surface(m, Vector2(640.0, -2000.0)) == Surfaces.S.SAND, "gravel track is sand surface")
	_check(carmel.surface(m, Vector2(530.0, -3200.0)) == Surfaces.S.TILE, "cannon emplacement is tile/stone")
	_check(carmel.surface(m, Vector2(850.0, -500.0)) == Surfaces.S.TILE, "escalator is tile surface")

	# 5. Sunset Mirador View Goal
	_check(not carmel.view_taken(m), "view starts not taken")
	m.dog.global_position = carmel.MIRADOR_SPOT
	m.human.global_position = carmel.MIRADOR_SPOT + Vector2(20.0, 0.0)
	carmel.tick(m, 1.2)
	_check(carmel.view_taken(m), "holding still at mirador takes the view")
	_check(m.bones == 5, "view awards 5 bones")

	# 6. Live Event: El Guitarrista del Carmel
	var g: Guitarrista = m.guitarrista
	_check(g != null, "guitarrista instantiated")
	_check(g.state == Guitarrista.State.IDLE, "guitarrista starts IDLE")

	# Approach trigger
	m.human.global_position = Vector2(640.0, Guitarrista.TRIGGER_Y - 10.0)
	g.tick(m, 0.05)
	_check(g.state == Guitarrista.State.TELEGRAPH, "approaching triggers TELEGRAPH")

	# Warning duration passes -> WALKING
	g.tick(m, Guitarrista.WARN_DURATION + 0.1)
	_check(g.state == Guitarrista.State.WALKING, "warning duration transitions to WALKING")

	# Bark trick
	m.dog.global_position = g.pos + Vector2(30.0, 0.0)
	var barked: bool = g.on_bark(m)
	_check(barked, "barking within reach triggers on_bark")
	_check(g.barked, "barked recorded")

	# Direct boop
	m.dog.global_position = g.pos + Vector2(10.0, 0.0)
	g.tick(m, 0.05)
	_check(g.booped, "booping guitarist recorded")

	# Olives dropped & snatched
	g.pos.x = Guitarrista.DROP_X - 10.0
	g.tick(m, 0.05)
	_check(g.olives_dropped, "olives drop past DROP_X")
	m.dog.global_position = g.olives_pos
	g.tick(m, 0.05)
	_check(g.olives_snatched, "dog snatches dropped olives")

	# Human bump
	m.human.global_position = g.pos
	var was_patience := m.human.patience
	g.tick(m, 0.05)
	_check(g.human_hit, "human bump recorded")
	_check(m.human.patience < was_patience, "human loses patience on bump")

	# Near-miss dodge save on second instance
	var g2 := Guitarrista.new()
	g2.state = Guitarrista.State.WALKING
	g2.pos = Vector2(640.0, -3500.0)
	m.human.global_position = g2.pos + Vector2(0.0, 40.0)
	g2.tick(m, 0.05)
	_check(g2.threatened, "human within threat radius threatens guitarist")
	m.human.global_position = g2.pos + Vector2(0.0, 120.0)
	g2.tick(m, 0.05)
	_check(g2.dodged, "steering human away triggers near-miss dodge")
	_check(m.saves_done >= 1, "dodge save increments saves_done")

	if failures.is_empty():
		print("test_carmel: %d checks, OK" % checks)
		quit(0)
	else:
		print("test_carmel: %d failures out of %d checks" % [failures.size(), checks])
		quit(1)
