extends SceneTree

# Regression test for Walk 30: «El Fòrum» (Parc del Fòrum / Esplanada del Fòrum)
# Covers:
# 1. Walk registration in Game (LEVELS, CAROUSEL, LEVEL_NAMES, LEVEL_SUBTITLES)
# 2. Exact 15 goals roster in goals.gd
# 3. Tony Hawk clock target, jamon pos, and spell word
# 4. Forum layout constants, solids, wrap points, and prize
# 5. Mediterranean water surface mapping
# 6. El Skater de l'Esplanada live event states, telegraph, tricks, and near-miss
# 7. Pergola sprint and skate rail grind detectors
# 8. ShapeBatch draw call contract

const Forum := preload("res://systems/forum.gd")
const ForumSkater := preload("res://systems/forum_skater.gd")
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
	var lvl := "forum"
	var tutorial_mode := false
	var START_Y := 200.0
	var GATE_Y := -4800.0
	var POP_SAY := 0
	var bones := 0
	var saves_done := 0
	var dog: Node2D
	var human: FakeHuman
	var camera: Node2D
	var skater: ForumSkater = null
	var marks: Array[Vector2] = []
	var bins: Array[Vector2] = []
	var benches: Array[Vector2] = []
	var poles: Array[Vector2] = []
	var deco_pole_count := 0
	var gate_text := ""
	var walk_cx := 640.0
	var walk_half := 280.0
	var sw_l := 360.0
	var sw_r := 920.0
	var gate_l := 400.0
	var gate_r := 880.0
	var prize_pos := Vector2.ZERO
	var prize_text := ""
	var finished := false
	var forum_pergola_sprinted := 0
	var forum_rails_grinded := 0
	var SHADOW_COL := Color(0, 0, 0, 0.28)

	func _init() -> void:
		dog = FakeDog.new()
		human = FakeHuman.new()
		camera = Node2D.new()
		add_child(dog)
		add_child(human)
		add_child(camera)

	func float_text(_pos: Vector2, _txt: String, _col: Color, _kind: int = 0) -> void:
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


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game = root.get_node("Game")
	game.persist = false

	# 1. Registration
	_check(game.LEVELS.has("forum"), "forum registered in Game.LEVELS")
	_check(game.CAROUSEL.has("forum"), "forum in CAROUSEL")
	_check(game.LEVEL_NAMES.get("forum") == "El Fòrum", "LEVEL_NAMES is El Fòrum")
	_check(game.LEVEL_SUBTITLES.has("forum"), "LEVEL_SUBTITLES has forum")
	_check(game.STAR_GATE.get("forum") == 45, "STAR_GATE for forum is 45")
	_check(game.CHASE_GATE.get("forum") == "gracia", "CHASE_GATE for forum is gracia")

	# 2. Exact 15 goals roster
	var goals_mod: GDScript = load("res://systems/goals.gd")
	var g_list: Array = goals_mod.LEVEL_GOAL_IDS.get("forum", [])
	_check(g_list.size() == 15, "forum has exactly 15 goals: %d" % g_list.size())
	for req_g in ["mark", "sniff", "phone", "paws", "bag", "fetch", "snack", "skater", "pergola", "rails", "combo", "prize", "spell", "jamon", "clock"]:
		_check(g_list.has(req_g), "forum roster contains goal: %s" % req_g)

	# 3. Tony Hawk par time & jamón
	var th_mod: GDScript = load("res://systems/tony_hawk.gd")
	_check(th_mod.CLOCK_TARGETS.get("forum") == 180, "clock target is 180s")
	_check(th_mod.JAMON_POS.get("forum") == Vector2(480.0, -1820.0), "jamon pos is set")

	# 4. Layout constants & Solids
	_check(Forum.HALF == 280.0, "half is 280")
	_check(Forum.WALL_L == 360.0, "wall_l is 360")
	_check(Forum.WALL_R == 920.0, "wall_r is 920")
	_check(Forum.PRIZE == Vector2(580.0, -4500.0), "prize position matches")

	var solids: Array[Rect2] = Forum.solids(null)
	_check(solids.size() == 6, "has 6 solid bodies (4 pylons, 2 skate banks)")
	_check(solids.has(Forum.PYLON_NW), "solids has PYLON_NW")
	_check(solids.has(Forum.PYLON_NE), "solids has PYLON_NE")
	_check(solids.has(Forum.PYLON_SW), "solids has PYLON_SW")
	_check(solids.has(Forum.PYLON_SE), "solids has PYLON_SE")
	_check(solids.has(Forum.SKATE_BANK_1), "solids has SKATE_BANK_1")
	_check(solids.has(Forum.SKATE_BANK_2), "solids has SKATE_BANK_2")

	# 5. Surface mapping
	_check(Forum.surface(null, Vector2(640.0, -1200.0)) == Surfaces.S.PAVEMENT, "center esplanade is pave")
	_check(Forum.surface(null, Vector2(900.0, -1200.0)) == Surfaces.S.WATER, "east bathing margin is water")

	# 6. El Skater live event choreography
	var skater := ForumSkater.new()
	_check(skater.state == ForumSkater.State.IDLE, "skater starts IDLE")
	_check(skater.pos == ForumSkater.START_POS, "skater positioned at START_POS")

	# Approach trigger
	var far_dog := Vector2(640.0, -2500.0)
	var far_human := Vector2(640.0, -2530.0)
	var res1: Dictionary = skater.tick(0.016, far_dog, Vector2.ZERO, far_human)
	_check(skater.state == ForumSkater.State.IDLE, "skater remains IDLE when far away")

	var near_human := Vector2(640.0, -2100.0)
	var res2: Dictionary = skater.tick(0.016, far_dog, Vector2.ZERO, near_human)
	_check(skater.state == ForumSkater.State.TELEGRAPH, "transitions to TELEGRAPH on approach")
	_check(res2["telegraph"], "emits telegraph event")

	# Complete 0.8s telegraph
	skater.tick(0.81, far_dog, Vector2.ZERO, near_human)
	_check(skater.state == ForumSkater.State.SKATING, "transitions to SKATING after telegraph")
	_check(skater.snack_dropped, "drops energy bar snack packet")

	# Snack snatch trick
	var res_snack: Dictionary = skater.tick(0.016, skater.snack_pos, Vector2.ZERO, near_human)
	_check(res_snack["snack_snatched"], "dog snatches energy bar snack")
	_check(skater.snack_taken, "snack marked as taken")

	# Bark cheer trick
	_check(skater.on_bark(skater.pos), "bark within 140px prompts cheer")
	_check(skater.cheered, "cheered marked true")

	# Board boop trick
	var res_boop: Dictionary = skater.tick(0.016, skater.pos, Vector2.ZERO, far_human)
	_check(res_boop["boop"], "booping rolling board awards boop trick")

	# Run until settled at sea wall
	for i in range(150):
		skater.tick(0.05, far_dog, Vector2.ZERO, far_human)
	_check(skater.state == ForumSkater.State.SETTLED, "skater settles at sea wall")
	_check(skater.pos == ForumSkater.END_POS, "skater at END_POS")

	# 7. FakeMain integration test for pergola sprint and skate rail grind
	var m := FakeMain.new()
	root.add_child(m)

	var pl: Array = Forum.build(m)
	_check(pl.size() == 2, "build returns hydrants and snacks")
	_check(m.poles.size() >= 14, "poles array holds windsock masts and pylon wrap points")
	_check(m.skater != null, "skater instantiated by Forum.build")

	# Test pergola sprint detector
	m.dog.position = Vector2(640.0, -1600.0)
	m.dog.set("velocity", Vector2(0.0, -250.0))
	Forum.tick(m, 0.016)
	_check(m.forum_pergola_sprinted == 1, "sprinting under pergola triggers pergola_sprinted count: %d" % m.forum_pergola_sprinted)

	# Test skate rail grind detector
	m.dog.position = Vector2(Forum.SKATE_BANK_1.position.x, Forum.SKATE_BANK_1.get_center().y)
	m.dog.set("velocity", Vector2(0.0, -220.0))
	Forum.tick(m, 0.016)
	_check(m.forum_rails_grinded == 2, "grinding skate bank rail awards rails_grinded: %d" % m.forum_rails_grinded)

	# Verify batching
	var b := ShapeBatch.new()
	Forum.draw_edge_layer(m, b, -3000.0, -1000.0)
	Forum.draw_live(m, b, -3000.0, -1000.0)
	Forum.draw_overhead(m, b)
	_check(b._points.size() > 0, "ShapeBatch accumulates geometry without error")

	m.queue_free()

	if failures.is_empty():
		print("test_forum: OK (%d checks)" % checks)
		quit(0)
	else:
		print("test_forum: FAILED (%d failures out of %d checks)" % [failures.size(), checks])
		quit(1)
