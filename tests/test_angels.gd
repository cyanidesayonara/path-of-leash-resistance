extends SceneTree

# Tests Els Àngels (the skate plaza outside the white museum, systems/angels.gd)
# - Registration in Game.LEVELS, CAROUSEL (after trail), STAR_GATE (22), CHASE_GATE (vet), CAMPAIGN_SKY
# - 15 goals in LEVEL_GOAL_IDS, Tony Hawk CLOCK_TARGETS, JAMON_POS
# - Path shape (narrow Raval street -> wide plaza bulge -> narrow exit), grindable rails, solids
# - Live event: bailing skater & runaway board (systems/angels_skate.gd)

const DT := 1.0 / 60.0
const Surfaces := preload("res://world/surfaces.gd")
const Angels := preload("res://systems/angels.gd")
const AngelsSkate := preload("res://systems/angels_skate.gd")
const ShapeBatch := preload("res://systems/shape_batch.gd")

var checks := 0
var failures: Array[String] = []


class FakeGrind:
	var active := false


class FakeMain:
	extends Node2D
	var lvl := "angels"
	var phase := "out"
	var tutorial_mode := false
	var START_Y := 200.0
	var GATE_Y := -4800.0
	var POP_SAY := 0
	var bones := 0
	var saves_done := 0
	var sniffs_done := 0
	var grinds_landed := 0
	var kebabs_eaten := 0
	var churros_eaten := 0
	var dog: Node2D
	var human: FakeHuman
	var combo: FakeCombo
	var feed: FakeFeed
	var grind: FakeGrind
	var angels_skate: AngelsSkate = null
	var rails: Array = []
	var hydrants: Array = []
	var marks: Array[Vector2] = []
	var bins: Array[Vector2] = []
	var benches: Array[Vector2] = []
	var fountains: Array[Vector2] = []
	var poles: Array[Vector2] = []
	var deco_pole_count := 0
	var gate_text := ""
	var walk_cx := 640.0
	var walk_half := 420.0
	var sw_l := 220.0
	var sw_r := 1060.0
	var gate_l := 440.0
	var gate_r := 840.0
	var freedom_rect := Rect2(140.0, -5420.0, 1000.0, 620.0)
	var prize_pos := Vector2.ZERO
	var prize_text := ""
	var prize_taken := false
	var finished := false
	var angels_ledge_ground := false
	var angels_decks_sniffed := 0
	var angels_decks_visited: Dictionary = {}
	var angels_churro_stolen := false
	var angels_lamps_wrapped: Dictionary = {}
	var leash: FakeLeash = FakeLeash.new()

	func _init() -> void:
		dog = Node2D.new()
		human = FakeHuman.new()
		combo = FakeCombo.new()
		feed = FakeFeed.new()
		grind = FakeGrind.new()
		add_child(dog)
		add_child(human)
		dog.set_script(FakeDogScript)

	func float_text(_pos: Vector2, _txt: String, _col: Color, _kind: int = 0) -> void:
		pass

	func _freedom_rect() -> Rect2:
		return freedom_rect


class FakeLeash:
	var contact_pole := Vector2(INF, INF)
	var static_contacts := 0
	var contact_static := false


class FakeDogScript:
	extends Node2D
	var velocity := Vector2.ZERO
	var sniffing := false


class FakeHuman:
	extends Node2D
	var patience := 1.0
	func bumped(_dir: Vector2) -> void:
		pass


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
	var rails_mod: GDScript = load("res://systems/rails.gd")

	var saved_persist: bool = game.persist
	var saved_free_play: bool = game.free_play
	var saved_records: Dictionary = game.records.duplicate(true)
	var saved_open: Array[String] = game.gate_open.duplicate()
	game.persist = false
	game.free_play = false
	game.gate_open.clear()
	game.records = {}
	for lv: String in game.LEVELS:
		game.records[lv] = game._default_level_record()

	# 1. Registration checks
	_check(game.LEVELS.has("angels"), "angels in Game.LEVELS")
	_check(game.CAROUSEL.has("angels"), "angels in Game.CAROUSEL")
	var trail_idx: int = game.CAROUSEL.find("trail")
	var angels_idx: int = game.CAROUSEL.find("angels")
	_check(angels_idx == trail_idx + 1, "angels directly after trail in CAROUSEL (%d vs %d)" % [angels_idx, trail_idx])
	_check(String(game.LEVEL_NAMES.get("angels", "")) == "Els Àngels", "LEVEL_NAMES has Els Àngels")
	_check(String(game.LEVEL_SUBTITLES.get("angels", "")) == "The skate plaza outside the white museum", "LEVEL_SUBTITLES has angels")
	_check(game.LEVEL_SUBTITLES_CA.has("angels"), "LEVEL_SUBTITLES_CA has angels")
	_check(game.LEVEL_SUBTITLES_ES.has("angels"), "LEVEL_SUBTITLES_ES has angels")
	_check(int(game.STAR_GATE.get("angels", -1)) == 22, "STAR_GATE for angels is 22")
	_check(String(game.CHASE_GATE.get("angels", "")) == "vet", "angels gated by vet")
	_check(game.CAMPAIGN_SKY.get("angels", []) == ["clear", "day"], "angels CAMPAIGN_SKY is [clear, day]")

	# 2. Goals & Tony Hawk checks
	var g_list: Array = goals_mod.LEVEL_GOAL_IDS.get("angels", [])
	_check(g_list.size() == 15, "angels has 15 goals: %d" % g_list.size())
	_check("ledge" in g_list, "ledge goal registered")
	_check("decks" in g_list, "decks goal registered")
	_check("lamps" in g_list, "lamps goal registered")
	_check(not ("churro" in g_list), "no walk goal about churros beside the churro prize")
	_check(th_mod.CLOCK_TARGETS.has("angels"), "CLOCK_TARGETS has angels")
	_check(int(th_mod.CLOCK_TARGETS["angels"]) == 180, "angels clock target is 180s")
	_check(th_mod.JAMON_POS.has("angels"), "JAMON_POS has angels")

	# 3. Path shape & Geometry
	var m := FakeMain.new()
	root.add_child(m)

	var nodes: Array = Angels.edge_nodes(m)
	_check(nodes.size() >= 6, "edge_nodes defines narrow -> bulge -> narrow path shape")
	_check(float(nodes[0]["half"]) < 220.0, "starts as narrow Raval street")
	var max_half := 0.0
	for n: Dictionary in nodes:
		max_half = maxf(max_half, float(n["half"]))
	_check(max_half >= 350.0, "opens wide into the plaza bulge")
	_check(float(nodes[nodes.size() - 1]["half"]) < 220.0, "pinches narrow again at far end")

	var pl: Array = Angels.build(m)
	_check(pl.size() == 2, "build returns [marks, snacks]")
	_check(pl[0].size() >= 5, "at least 5 marks registered")
	_check(pl[1].size() >= 4, "at least 4 snacks registered")
	_check(m.poles.size() >= 12, "poles populated with plaza lamps and podiums: %d" % m.poles.size())
	_check(m.angels_skate != null, "AngelsSkate live event initialized")

	var solids: Array[Rect2] = Angels.solids(m)
	_check(solids.size() == 8, "8 solid obstacles (podium blocks, convent plinth, bike rack, 4 planters): %d" % solids.size())
	_check(Angels.wrap_rects().size() == solids.size(), "wrap rects match solids")
	for sr: Rect2 in solids:
		_check(not sr.grow(30.0).has_point(Vector2(sr.get_center().x, AngelsSkate.CROSSING_Y)), "solid %s clear of the board's crossing" % sr)
		for rx: float in [340.0, 450.0, 920.0]:
			_check(sr.end.x < rx - 6.0 or sr.position.x > rx + 6.0 or sr.end.y < -3260.0 or sr.position.y > -1480.0 or (rx == 450.0 and (sr.end.y < -2100.0 or sr.position.y > -1840.0)) or (rx == 920.0 and (sr.end.y < -2420.0 or sr.position.y > -1900.0)), "solid %s clear of the rail at x %d" % [sr, rx])

	rails_mod.build(m)
	_check(m.rails.size() == 4, "4 grindable rails built on museum ledges, stair handrail, and convent ledge: %d" % m.rails.size())

	# 4. Surface detection
	_check(Angels.surface(m, Vector2(640.0, -2400.0)) == Surfaces.S.PAVEMENT, "plaza granite is pavement")
	_check(Angels.surface(m, Vector2(640.0, -5100.0)) == Surfaces.S.PAVEMENT, "university courtyard center is pavement")
	_check(Angels.surface(m, Vector2(220.0, -5100.0)) == Surfaces.S.GRASS, "university courtyard west bed is grass")
	_check(Angels.surface(m, Vector2(1060.0, -5100.0)) == Surfaces.S.GRASS, "university courtyard east bed is grass")

	# 5. Walk-specific goals: grind museum ledge & sniff 3 skateboards
	m.grind.active = true
	Angels.tick(m, DT)
	_check(m.angels_ledge_ground, "grinding a rail on angels sets angels_ledge_ground")
	m.grind.active = false

	for i in range(3):
		m.dog.global_position = Angels.DECK_SPOTS[i]
		Angels.tick(m, DT)
	_check(m.angels_decks_sniffed == 3, "sniffed 3 skateboards on the ground: %d" % m.angels_decks_sniffed)
	_check("DECK INSPECTOR" in m.combo.banked, "awarded DECK INSPECTOR combo")

	# Wrapping the leash round three different lamp posts completes the lamps goal;
	# the same post twice counts once, a podium block not at all
	m.leash.static_contacts = 1
	m.leash.contact_static = true
	for lp: Vector2 in [Angels.LAMP_POSTS[2], Angels.LAMP_POSTS[2], Angels.LAMP_POSTS[3]]:
		m.leash.contact_pole = lp
		Angels.tick(m, DT)
	_check(m.angels_lamps_wrapped.size() == 2, "the same post counts once: %d" % m.angels_lamps_wrapped.size())
	m.leash.contact_pole = Vector2(Angels.MUSEUM_PODIUM_S.position.x + 8.0, Angels.MUSEUM_PODIUM_S.get_center().y)
	Angels.tick(m, DT)
	_check(m.angels_lamps_wrapped.size() == 2, "a podium block is not a lamp post")
	m.leash.contact_pole = Angels.LAMP_POSTS[5]
	Angels.tick(m, DT)
	_check(m.angels_lamps_wrapped.size() == 3, "three lamp posts wrapped")
	m.leash.contact_pole = Vector2(INF, INF)
	m.leash.static_contacts = 0

	# 6. Live event: bailing skater & runaway board
	var sk: AngelsSkate = m.angels_skate
	_check(sk.state == AngelsSkate.State.IDLE, "skater starts IDLE")

	# Telegraph trigger (0.8s warning before board shoots across)
	m.human.global_position = Vector2(640.0, AngelsSkate.TRIGGER_Y - 10.0)
	sk.tick(m, DT)
	_check(sk.state == AngelsSkate.State.TELEGRAPH, "skater transitions to TELEGRAPH when human approaches")
	_check(m.feed.messages.size() >= 1, "skater warns with feed announcement")

	# Advance past 0.8s warning
	sk.tick(m, AngelsSkate.WARN_DURATION + 0.05)
	_check(sk.state == AngelsSkate.State.ROLLING, "board transitions to ROLLING after warning")

	# Bark cheer
	m.dog.global_position = sk.pos + Vector2(40.0, 0.0)
	var bark_ok: bool = Angels.on_bark(m)
	_check(bark_ok, "on_bark handled by runaway board")
	_check("SKATE CHEER" in m.combo.banked, "awarded SKATE CHEER combo")

	# Dog boop
	m.dog.global_position = sk.pos + Vector2(10.0, 0.0)
	sk.tick(m, DT)
	_check(sk.booped, "runaway board booped by dog")
	_check("BOARD BOOP" in m.combo.banked, "awarded BOARD BOOP combo")

	# Churro drop and snatch
	while not sk.churro_dropped and sk.state == AngelsSkate.State.ROLLING:
		sk.tick(m, DT)
	_check(sk.churro_dropped, "churro dropped on plaza")

	m.dog.global_position = sk.churro_pos
	sk.tick(m, DT)
	_check(sk.churro_snatched and m.angels_churro_stolen, "dropped churro stolen by dog")
	_check("CHURRO SNATCH" in m.combo.banked, "awarded CHURRO SNATCH combo")

	# Near-miss dodge save
	m.human.global_position = sk.pos + Vector2(0.0, 50.0)
	sk.tick(m, DT)
	m.human.global_position = sk.pos + Vector2(0.0, 150.0)
	sk.tick(m, DT)
	_check(sk.dodged, "near miss dodge detected")
	_check("BOARD DODGE" in m.combo.banked, "awarded BOARD DODGE combo")
	_check(m.saves_done >= 1, "saves_done incremented")

	# Settle board after crossing plaza
	while sk.state == AngelsSkate.State.ROLLING:
		sk.tick(m, DT)
	_check(sk.state == AngelsSkate.State.SETTLED, "board settled after crossing plaza")

	# Check human bump path on a fresh instance
	var sk2 := AngelsSkate.new()
	sk2.state = AngelsSkate.State.ROLLING
	sk2.pos = Vector2(640.0, AngelsSkate.CROSSING_Y)
	m.human.global_position = sk2.pos
	var p_before: float = m.human.patience
	sk2.tick(m, DT)
	_check(sk2.human_hit and m.human.patience < p_before, "board bumping human drops patience")

	# 7. ShapeBatch drawing runs without error
	var batch := ShapeBatch.new()
	Angels.draw_edge_layer(m, batch, -3600.0, -1000.0)
	Angels.draw_live(m, batch, -3600.0, -1000.0)
	Angels.draw_overhead(m, batch)
	_check(true, "Angels draw methods executed successfully")

	game.records = saved_records
	game.gate_open = saved_open
	game.free_play = saved_free_play
	game.persist = saved_persist

	if failures.is_empty():
		print("test_angels: OK (%d checks)" % checks)
		quit(0)
	else:
		print("test_angels: %d FAILURES of %d checks" % [failures.size(), checks])
		for f: String in failures:
			print("  - " + f)
		quit(1)
