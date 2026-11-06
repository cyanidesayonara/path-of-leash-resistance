extends SceneTree

# Tests Walk 29: La Superilla (Poblenou Superblock, systems/superilla.gd)
# - Registration in Game.LEVELS, CAROUSEL, STAR_GATE, LEVEL_NAMES, LEVEL_SUBTITLES
# - 15 goals in LEVEL_GOAL_IDS, Tony Hawk CLOCK_TARGETS, JAMON_POS
# - Geometry: planter boxes, ping-pong tables, painted asphalt circles
# - Live event: El Patí de Càrrega (systems/superilla_cargo.gd)

const DT := 1.0 / 60.0
const Surfaces := preload("res://world/surfaces.gd")
const Superilla := preload("res://systems/superilla.gd")
const SuperillaCargo := preload("res://systems/superilla_cargo.gd")
const ShapeBatch := preload("res://systems/shape_batch.gd")

var checks := 0
var failures: Array[String] = []


class FakeMain:
	extends Node2D
	var lvl := "superilla"
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
	var cargo: SuperillaCargo = null
	var marks: Array[Vector2] = []
	var bins: Array[Vector2] = []
	var benches: Array[Vector2] = []
	var poles: Array[Vector2] = []
	var deco_pole_count := 0
	var gate_text := ""
	var walk_cx := 640.0
	var walk_half := 300.0
	var sw_l := 340.0
	var sw_r := 940.0
	var gate_l := 440.0
	var gate_r := 840.0
	var prize_pos := Vector2.ZERO
	var prize_text := ""
	var finished := false
	var superilla_circles_sprinted := 0
	var superilla_pingpong_slid := false
	var superilla_circles_visited: Dictionary = {}

	func _init() -> void:
		dog = Node2D.new()
		human = FakeHuman.new()
		combo = FakeCombo.new()
		feed = FakeFeed.new()
		add_child(dog)
		add_child(human)
		dog.set_script(FakeDogScript)

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
	var banked: Array[String] = []
	func add(kind: String, _pts: int) -> void:
		banked.append(kind)


class FakeFeed:
	var messages: Array[String] = []
	func say(txt: String, _tone: int = 0) -> void:
		messages.append(txt)


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

	# 1. Registration checks
	_check(game.LEVELS.has("superilla"), "superilla in Game.LEVELS")
	_check(game.CAROUSEL.has("superilla"), "superilla in Game.CAROUSEL")
	_check(game.LEVEL_NAMES.has("superilla"), "LEVEL_NAMES has superilla")
	_check(game.LEVEL_SUBTITLES.has("superilla"), "LEVEL_SUBTITLES has superilla")
	_check(game.LEVEL_SUBTITLES_CA.has("superilla"), "LEVEL_SUBTITLES_CA has superilla")
	_check(game.LEVEL_SUBTITLES_ES.has("superilla"), "LEVEL_SUBTITLES_ES has superilla")
	_check(game.STAR_GATE.has("superilla"), "STAR_GATE has superilla")
	_check(game.chase_gate_needed("superilla") == "gracia", "superilla gated by gracia")

	# 2. Goals & Tony Hawk checks
	var g_list: Array = goals_mod.LEVEL_GOAL_IDS.get("superilla", [])
	_check(g_list.size() == 15, "superilla has 15 goals: %d" % g_list.size())
	_check("cargo" in g_list, "cargo goal registered")
	_check("pingpong" in g_list, "pingpong goal registered")
	_check("circles" in g_list, "circles goal registered")
	_check(th_mod.CLOCK_TARGETS.has("superilla"), "CLOCK_TARGETS has superilla")
	_check(int(th_mod.CLOCK_TARGETS["superilla"]) == 180, "superilla clock target is 180s")
	_check(th_mod.JAMON_POS.has("superilla"), "JAMON_POS has superilla")

	# 3. Geometry & Layout
	var m := FakeMain.new()
	root.add_child(m)

	var pl: Array = Superilla.build(m)
	_check(pl.size() == 2, "build returns [marks, snacks]")
	_check(pl[0].size() >= 5, "at least 5 marks registered")
	_check(pl[1].size() >= 4, "at least 4 snacks registered")
	_check(m.poles.size() >= 12, "poles populated with planters and pingpong tables: %d" % m.poles.size())
	_check(m.cargo != null, "SuperillaCargo live event initialized")

	var solids: Array[Rect2] = Superilla.solids(m)
	_check(solids.size() == 10, "10 solid obstacles (2 ping-pong tables + 8 planter boxes): %d" % solids.size())
	_check(Superilla.wrap_rects().size() == 10, "10 wrap rects matching solids")

	# 4. Surface detection
	_check(Superilla.surface(m, Vector2(640.0, -2000.0)) == Surfaces.S.PAVEMENT, "asphalt court is pavement")

	# 5. Tactical circles sprint combo
	m.dog.set("velocity", Vector2(0.0, -250.0))
	for i in range(3):
		var circ: Dictionary = Superilla.PAINT_CIRCLES[i]
		m.dog.global_position = circ["pos"]
		Superilla.tick(m, DT)
	_check(m.superilla_circles_sprinted == 3, "sprinted through 3 painted circles")
	_check("TACTICAL RUNNER" in m.combo.banked, "awarded TACTICAL RUNNER combo")

	# 6. Ping-pong table slide combo
	_check(not m.superilla_pingpong_slid, "pingpong slide starts false")
	m.dog.global_position = Superilla.PINGPONG_1.get_center()
	Superilla.tick(m, DT)
	_check(m.superilla_pingpong_slid, "dog slides under ping-pong table")
	_check("PINGPONG SLIDE" in m.combo.banked, "awarded PINGPONG SLIDE combo")

	# 7. Live event: El Patí de Càrrega
	var cargo: SuperillaCargo = m.cargo
	_check(cargo.state == SuperillaCargo.State.IDLE, "cargo starts IDLE")

	# Telegraph trigger
	m.human.global_position = Vector2(640.0, -1880.0)
	cargo.tick(m, DT)
	_check(cargo.state == SuperillaCargo.State.TELEGRAPH, "cargo transitions to TELEGRAPH when human approaches")
	_check(m.feed.messages.size() >= 1, "cargo warns with feed announcement")

	# Advance past warning
	cargo.tick(m, SuperillaCargo.WARN_DURATION + 0.1)
	_check(cargo.state == SuperillaCargo.State.RIDING, "cargo transitions to RIDING")

	# Bark cheer
	m.dog.global_position = cargo.pos + Vector2(50.0, 0.0)
	var bark_result: bool = Superilla.on_bark(m)
	_check(bark_result, "on_bark handled by cargo trike")
	_check("CARGO CHEER" in m.combo.banked, "awarded CARGO CHEER combo")

	# Dog boop
	m.dog.global_position = cargo.pos + Vector2(10.0, 0.0)
	cargo.tick(m, DT)
	_check(cargo.booped, "cargo booped by dog")
	_check("CARGO BOOP" in m.combo.banked, "awarded CARGO BOOP combo")

	# Baguette drop and snatch
	while not cargo.baguette_dropped and cargo.state == SuperillaCargo.State.RIDING:
		cargo.tick(m, DT)
	_check(cargo.baguette_dropped, "baguette dropped at center of superblock")

	m.dog.global_position = cargo.baguette_pos
	cargo.tick(m, DT)
	_check(cargo.baguette_snatched, "baguette snatched by dog")
	_check("BAGUETTE SNATCH" in m.combo.banked, "awarded BAGUETTE SNATCH combo")

	# Near-miss dodge save
	m.human.global_position = cargo.pos + Vector2(0.0, 50.0)
	cargo.tick(m, DT)
	m.human.global_position = cargo.pos + Vector2(0.0, 150.0)
	cargo.tick(m, DT)
	_check(cargo.dodged, "near miss dodge detected")
	_check("SUPERILLA DODGE" in m.combo.banked, "awarded SUPERILLA DODGE combo")
	_check(m.saves_done >= 1, "saves_done incremented")

	# Settle cargo bike
	while cargo.state == SuperillaCargo.State.RIDING:
		cargo.tick(m, DT)
	_check(cargo.state == SuperillaCargo.State.SETTLED, "cargo settled after crossing")

	# 8. ShapeBatch drawing runs without error
	var batch := ShapeBatch.new()
	Superilla.draw_edge_layer(m, batch, -3000.0, -1000.0)
	Superilla.draw_live(m, batch, -3000.0, -1000.0)
	Superilla.draw_overhead(m, batch)
	_check(true, "Superilla draw methods executed successfully")

	# Report
	if failures.is_empty():
		print("test_superilla: OK (%d checks)" % checks)
		quit(0)
	else:
		print("test_superilla: %d FAILURES of %d checks" % [failures.size(), checks])
		for f: String in failures:
			print("  - " + f)
		quit(1)
