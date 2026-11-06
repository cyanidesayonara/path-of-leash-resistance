extends SceneTree

# Regression test for Walk 31: «Plaça d'Espanya» (Avinguda Maria Cristina & La Font Màgica)
# Covers:
# 1. Walk registration in Game (LEVELS, CAROUSEL, LEVEL_NAMES, LEVEL_SUBTITLES)
# 2. Exact 15 goals roster in goals.gd
# 3. Tony Hawk clock target, jamon pos, and spell word
# 4. Espanya layout constants, solids, wrap points, and prize
# 5. Magic Fountain water & cascade pool water surface mapping
# 6. El Bufador de Bombolles live event states, telegraph, bubble popping, and near-miss
# 7. Escalator propulsion and Magic Fountain splash detectors
# 8. ShapeBatch draw call contract

const Espanya := preload("res://systems/espanya.gd")
const EspanyaBubble := preload("res://systems/espanya_bubble.gd")
const ShapeBatch := preload("res://systems/shape_batch.gd")
const Surfaces := preload("res://world/surfaces.gd")

var checks: int = 0
var failures: Array[String] = []


func _check(ok: bool, msg: String) -> void:
	checks += 1
	if not ok:
		failures.append(msg)
		print("FAIL: ", msg)


class FakeMain:
	extends Node2D
	var lvl := "espanya"
	var tutorial_mode := false
	var START_Y := 200.0
	var GATE_Y := -4800.0
	var POP_SAY := 0
	var bones := 0
	var saves_done := 0
	var dog: Node2D
	var human: FakeHuman
	var camera: Node2D
	var espanya_bubble: EspanyaBubble = null
	var marks: Array[Vector2] = []
	var bins: Array[Vector2] = []
	var benches: Array[Vector2] = []
	var poles: Array[Vector2] = []
	var deco_pole_count := 0
	var gate_text := ""
	var walk_cx := 640.0
	var walk_half := 260.0
	var sw_l := 380.0
	var sw_r := 900.0
	var gate_l := 400.0
	var gate_r := 880.0
	var prize_pos := Vector2.ZERO
	var prize_text := ""
	var finished := false
	var espanya_bubbles_popped := 0
	var espanya_fountain_splashed := 0
	var espanya_columns_wrapped := 0
	var espanya_escalator_ridden := 0
	var leash: FakeLeash = null
	var SHADOW_COL := Color(0, 0, 0, 0.28)

	func _init() -> void:
		dog = FakeDog.new()
		human = FakeHuman.new()
		camera = Node2D.new()
		leash = FakeLeash.new()
		add_child(dog)
		add_child(human)
		add_child(camera)

	func float_text(_pos: Vector2, _txt: String, _col: Color, _kind: int = 0) -> void:
		pass

	func play_sfx(_sfx: String) -> void:
		pass

	func award_points(pts: int, _txt: String) -> void:
		bones += pts


class FakeDog:
	extends Node2D
	var velocity := Vector2.ZERO


class FakeHuman:
	extends Node2D
	var patience := 100.0
	var temper_t := 0.0
	func say(_txt: String, _dur: float) -> void:
		pass


class FakeLeash:
	var contacts: Array[Vector2] = []
	func has_contact_with(p: Vector2) -> bool:
		return contacts.has(p)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game = root.get_node("Game")
	game.persist = false

	# 1. Registration
	_check(game.LEVELS.has("espanya"), "espanya registered in Game.LEVELS")
	_check(game.CAROUSEL.has("espanya"), "espanya in CAROUSEL")
	_check(game.LEVEL_NAMES.get("espanya") == "Plaça d'Espanya", "LEVEL_NAMES is Plaça d'Espanya")
	_check(game.LEVEL_SUBTITLES.has("espanya"), "LEVEL_SUBTITLES has espanya")
	_check(game.STAR_GATE.get("espanya") == 46, "STAR_GATE for espanya is 46")
	_check(game.CHASE_GATE.get("espanya") == "gracia", "CHASE_GATE for espanya is gracia")

	# 2. Exact 15 goals roster
	var goals_mod: GDScript = load("res://systems/goals.gd")
	var g_list: Array = goals_mod.LEVEL_GOAL_IDS.get("espanya", [])
	_check(g_list.size() == 15, "espanya has exactly 15 goals: %d" % g_list.size())
	for req_g in ["mark", "sniff", "phone", "paws", "bag", "fetch", "snack", "bubble", "magic_fountain", "columns", "combo", "prize", "spell", "jamon", "clock"]:
		_check(g_list.has(req_g), "espanya roster contains goal: %s" % req_g)

	# 3. Tony Hawk par time & jamón
	var th_mod: GDScript = load("res://systems/tony_hawk.gd")
	_check(th_mod.CLOCK_TARGETS.get("espanya") == 180, "clock target is 180s")
	_check(th_mod.JAMON_POS.get("espanya") == Vector2(860.0, -3200.0), "jamon pos is set")

	# 4. Layout constants & Solids
	_check(Espanya.HALF == 260.0, "half is 260")
	_check(Espanya.WALL_L == 380.0, "wall_l is 380")
	_check(Espanya.WALL_R == 900.0, "wall_r is 900")
	_check(Espanya.PRIZE == Vector2(640.0, -4400.0), "prize position matches")

	var solids: Array[Rect2] = Espanya.solids(null)
	_check(solids.size() == 3, "has 3 solid bodies (2 towers, 1 fountain pedestal)")
	_check(solids.has(Espanya.TOWER_WEST), "solids has TOWER_WEST")
	_check(solids.has(Espanya.TOWER_EAST), "solids has TOWER_EAST")
	_check(solids.has(Espanya.FOUNTAIN_PEDESTAL), "solids has FOUNTAIN_PEDESTAL")

	# 5. Surface mapping
	_check(Espanya.surface(null, Vector2(640.0, -1200.0)) == Surfaces.S.PAVEMENT, "center avenue is pavement")
	_check(Espanya.surface(null, Espanya.FOUNTAIN_CENTER) == Surfaces.S.WATER, "inside Magic Fountain is water")
	_check(Espanya.surface(null, Vector2(640.0, -4100.0)) == Surfaces.S.WATER, "central cascade pool is water")
	_check(Espanya.surface(null, Vector2(420.0, -4100.0)) == Surfaces.S.TILE, "escalator / palace stairs are tile")
	_check(Espanya.surface(null, Vector2(640.0, -2250.0)) == Surfaces.S.TILE, "column plaza is tile")

	# 6. El Bufador de Bombolles live event choreography
	var bubble := EspanyaBubble.new()
	_check(bubble.state == EspanyaBubble.State.IDLE, "bubble artist starts IDLE")
	_check(bubble.pos == EspanyaBubble.START_POS, "positioned at START_POS")

	# Approach trigger
	var far_dog := Vector2(640.0, -2500.0)
	var far_human := Vector2(640.0, -2530.0)
	var res1: Dictionary = bubble.tick(0.016, far_dog, Vector2.ZERO, far_human)
	_check(bubble.state == EspanyaBubble.State.IDLE, "remains IDLE when far away")

	var near_human := Vector2(640.0, -1400.0)
	var res2: Dictionary = bubble.tick(0.016, far_dog, Vector2.ZERO, near_human)
	_check(bubble.state == EspanyaBubble.State.TELEGRAPH, "transitions to TELEGRAPH on approach")
	_check(res2["telegraph"], "emits telegraph event")

	# Complete 0.8s telegraph
	bubble.tick(0.81, far_dog, Vector2.ZERO, near_human)
	_check(bubble.state == EspanyaBubble.State.BLOWING, "transitions to BLOWING after telegraph")

	# Bubble pop trick
	var bubble_target := bubble.pos + bubble.bubble_offsets[0]
	var res_pop: Dictionary = bubble.tick(0.016, bubble_target, Vector2.ZERO, far_human)
	_check(res_pop["bubble_pop"], "popping floating bubble awards trick")
	_check(bubble.bubble_popped, "bubble_popped marked true")

	# Bark cheer trick
	_check(bubble.on_bark(bubble.pos), "bark within 145px prompts cheer")
	_check(bubble.cheered, "cheered marked true")

	# Run until settled at western promenade edge
	for i in range(150):
		bubble.tick(0.05, far_dog, Vector2.ZERO, far_human)
	_check(bubble.state == EspanyaBubble.State.SETTLED, "settles at western edge")
	_check(bubble.pos == EspanyaBubble.END_POS, "positioned at END_POS")

	# 7. FakeMain integration test for escalator and fountain
	var m := FakeMain.new()
	root.add_child(m)

	var pl: Array = Espanya.build(m)
	_check(pl.size() == 2, "build returns hydrants and snacks")
	_check(m.poles.size() >= 12, "poles array holds flagpoles, columns, and pedestal wrap points")
	_check(m.espanya_bubble != null, "espanya_bubble instantiated by Espanya.build")

	# Test escalator propulsion
	m.dog.position = Vector2(Espanya.ESCALATOR_L.position.x + 10.0, Espanya.ESCALATOR_L.get_center().y)
	var pre_y: float = m.dog.position.y
	Espanya.tick(m, 0.05)
	_check(m.dog.position.y < pre_y, "dog propelled upward on escalator")
	_check(m.espanya_escalator_ridden == 1, "escalator_ridden marked 1")

	# Test Magic Fountain splash
	m.dog.position = Espanya.FOUNTAIN_CENTER + Vector2(20.0, 0.0)
	Espanya.tick(m, 0.016)
	_check(m.espanya_fountain_splashed == 1, "fountain_splashed marked 1")

	# Test Columns wrap
	m.leash.contacts.append(Espanya.COLUMN_POSTS[0])
	Espanya.tick(m, 0.016)
	_check(m.espanya_columns_wrapped == 1, "columns_wrapped marked 1")

	# Verify batching
	var b := ShapeBatch.new()
	Espanya.draw_edge_layer(m, b, -4500.0, -500.0)
	Espanya.draw_live(m, b, -4500.0, -500.0)
	Espanya.draw_overhead(m, b)
	_check(b._points.size() > 0, "ShapeBatch accumulates geometry without error")

	m.queue_free()

	if failures.is_empty():
		print("test_espanya: OK (%d checks)" % checks)
		quit(0)
	else:
		print("test_espanya: FAILED (%d failures out of %d checks)" % [failures.size(), checks])
		quit(1)
