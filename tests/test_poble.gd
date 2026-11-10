extends SceneTree

# Tests Walk: El Poble Espanyol (The walled village of copied towns, systems/poble.gd)
# - Registration in Game.LEVELS, CAROUSEL (right after espanya), STAR_GATE 46,
#   CHASE_GATE "boars", CAMPAIGN_SKY ["clear", "day"], LEVEL_NAMES, LEVEL_SUBTITLES (EN/CA/ES),
#   WALKS_SINCE_GATES
# - 15 goals in LEVEL_GOAL_IDS ("columns_poble", "workshops", "watering" + 12 shared),
#   Tony Hawk CLOCK_TARGETS, JAMON_POS
# - Path shape: open road -> stone gate pinch -> Castilian bend -> Plaza Mayor bulge ->
#   stepped Andalusian lane -> Aragonese brick tower court
# - Props & signature line: gate columns, 10 arcade columns, central stone fountain in m.poles,
#   cafe tables in m.tables, stage + Aragonese tower in solids, custom freedom props
# - Live event: systems/poble_balcony.gd (0.8s telegraph "Heads up!" + wet patch, pouring soak,
#   near-miss save, dog shake-off reward, bark reply, boop, outward leg only, autowalk safe)

const DT := 1.0 / 60.0
const Surfaces := preload("res://world/surfaces.gd")
const Poble := preload("res://systems/poble.gd")
const PobleBalcony := preload("res://systems/poble_balcony.gd")
const ShapeBatch := preload("res://systems/shape_batch.gd")

var checks := 0
var failures: Array[String] = []


class FakeEventFeed:
	enum Tone { INFO, GOOD, WARN, BAD }


class FakeMain:
	extends Node2D
	var lvl := "poble"
	var tutorial_mode := false
	var attract_mode := false
	var START_Y := 200.0
	var GATE_Y := -5000.0
	var POP_SAY := 0
	var SHADOW_COL := Color(0.05, 0.04, 0.08, 0.24)
	var EventFeed := FakeEventFeed
	var bones := 0
	var saves_done := 0
	var human_soak := 0.0
	var phase := "out"
	var dog: FakeDog
	var human: FakeHuman
	var leash: FakeLeash
	var combo: FakeCombo
	var feed: FakeFeed
	var poble_balcony: PobleBalcony = null
	var marks: Array[Vector2] = []
	var bins: Array[Vector2] = []
	var benches: Array[Vector2] = []
	var fountains: Array[Vector2] = []
	var poles: Array[Vector2] = []
	var tables: Array[Vector2] = []
	var chairs: Array[Vector2] = []
	var islands: Array[Dictionary] = []
	var sniff_spots: Array[Dictionary] = []
	var deco_pole_count := 0
	var gate_text := ""
	var walk_cx := 640.0
	var walk_half := 260.0
	var sw_l := 380.0
	var sw_r := 900.0
	var gate_l := 420.0
	var gate_r := 860.0
	var freedom_rect := Rect2(70.0, -5620.0, 1110.0, 590.0)
	var prize_pos := Vector2.ZERO
	var prize_text := ""
	var carry_text := ""
	var clock_target := 180.0
	var elapsed := 0.0
	var prize_taken := false
	var finished := false
	var phone_cracked := false
	var poble_columns_wrapped: Dictionary = {}
	var poble_workshops_sniffed: Dictionary = {}
	var poble_shakes := 0
	var poble_fountain_wrapped := false
	var floated: Array[String] = []

	func _init() -> void:
		dog = FakeDog.new()
		human = FakeHuman.new()
		leash = FakeLeash.new()
		combo = FakeCombo.new()
		feed = FakeFeed.new()
		add_child(dog)
		add_child(human)

	func float_text(_pos: Vector2, txt: String, _col: Color, _kind: int = 0) -> void:
		floated.append(txt)

	func award_points(pts: int, _label: String = "") -> void:
		bones += pts

	func crack_phone(_pos: Vector2) -> void:
		phone_cracked = true

	func walk_edges(_y: float) -> Vector2:
		return Vector2(sw_l, sw_r)


class FakeDog:
	extends Node2D
	var velocity := Vector2.ZERO
	var facing := Vector2.UP
	var slick := false
	var sniffing := false


class FakeHuman:
	extends Node2D
	var patience := 1.0
	var external_warning_t := 0.0

	func bumped(_dir: Vector2) -> void:
		pass

	func notice(_txt: String, _dur: float = 1.4) -> void:
		pass


class FakeLeash:
	var static_contacts := 0
	var contact_pole := Vector2(INF, INF)
	var human_contact_pole := Vector2(INF, INF)


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
	var level_build: GDScript = load("res://world/level_build.gd")
	var world_sign: GDScript = load("res://world/world_sign.gd")

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

	# 1. Campaign registration checks
	_check(game.LEVELS.has("poble"), "poble in Game.LEVELS")
	_check(game.CAROUSEL.has("poble"), "poble in Game.CAROUSEL")
	var esp_idx: int = game.CAROUSEL.find("espanya")
	var pob_idx: int = game.CAROUSEL.find("poble")
	_check(esp_idx >= 0 and pob_idx == esp_idx + 1, "poble is directly after espanya in CAROUSEL (%d -> %d)" % [esp_idx, pob_idx])
	_check(String(game.LEVEL_NAMES.get("poble", "")) == "El Poble Espanyol", "LEVEL_NAMES['poble'] is El Poble Espanyol")
	_check(String(game.LEVEL_SUBTITLES.get("poble", "")) == "The walled village of copied towns", "EN subtitle matches")
	_check(String(game.LEVEL_SUBTITLES_CA.get("poble", "")) == "El poble emmurallat de pobles copiats", "CA subtitle matches")
	_check(String(game.LEVEL_SUBTITLES_ES.get("poble", "")) == "El pueblo amurallado de pueblos copiados", "ES subtitle matches")
	_check(int(game.STAR_GATE.get("poble", -1)) == 46, "STAR_GATE['poble'] is 46")
	_check(int(game.STAR_GATE.get("espanya", -1)) == 45 and int(game.STAR_GATE.get("site", -1)) == 47, "neighboring star gates unrenumbered (45, 47)")
	_check(String(game.CHASE_GATE.get("poble", "")) == "boars", "poble gated by boars")
	var sky: Array = game.CAMPAIGN_SKY.get("poble", [])
	_check(sky == ["clear", "day"], "CAMPAIGN_SKY['poble'] is ['clear', 'day']")
	_check(game.WALKS_SINCE_GATES.has("poble"), "WALKS_SINCE_GATES has poble")
	_check(String(world_sign.MATERIALS.get("poble", "")) == "azulejos", "world_sign material for poble is azulejos")

	# 2. Goals & Tony Hawk checks
	var g_list: Array = goals_mod.LEVEL_GOAL_IDS.get("poble", [])
	_check(g_list.size() == 15, "poble has 15 goals: %d" % g_list.size())
	_check("columns_poble" in g_list, "columns_poble goal registered")
	_check("workshops" in g_list, "workshops goal registered")
	_check("watering" in g_list, "watering goal registered")
	_check(th_mod.CLOCK_TARGETS.has("poble") and int(th_mod.CLOCK_TARGETS["poble"]) == 180, "poble clock target is 180s")
	_check(th_mod.JAMON_POS.has("poble"), "JAMON_POS has poble")
	_check(level_build.FREEDOM_PROPS.has("poble"), "FREEDOM_PROPS has custom poble garden layout")

	# 3. Path shape & geometry checks
	var m := FakeMain.new()
	root.add_child(m)
	var nodes: Array = Poble.edge_nodes(m)
	_check(nodes.size() >= 12, "edge_nodes defines multi-segment village path")
	var gate_half := 999.0
	var castilian_cx := 640.0
	var plaza_half := 0.0
	for n: Dictionary in nodes:
		var ny := float(n["y"])
		if is_equal_approx(ny, -460.0):
			gate_half = float(n["half"])
		elif is_equal_approx(ny, -1120.0):
			castilian_cx = float(n["cx"])
		elif is_equal_approx(ny, -1860.0):
			plaza_half = float(n["half"])
	_check(gate_half <= 155.0, "stone city gate is a real pinch (half=%f)" % gate_half)
	_check(absf(castilian_cx - 640.0) >= 60.0, "Castilian street has a real bend (cx=%f)" % castilian_cx)
	_check(plaza_half >= 360.0, "Plaza Mayor is a wide open bulge (half=%f)" % plaza_half)

	var pl: Array = Poble.build(m)
	_check(pl.size() == 2, "build returns [marks, snacks]")
	_check(pl[0].size() >= 6, "at least 6 marks registered")
	_check(pl[1].size() >= 4, "at least 4 snacks registered")
	_check(m.poles.has(Poble.FOUNTAIN_POS), "central stone fountain is in m.poles")
	for col: Vector2 in Poble.ARCADE_COLUMNS:
		_check(m.poles.has(col), "arcade column %s in m.poles" % str(col))
	_check(m.tables.size() >= Poble.CAFE_TABLES.size(), "cafe tables under arcades populated in m.tables")
	_check(m.poble_balcony != null, "PobleBalcony live event initialized")
	var solids: Array[Rect2] = Poble.solids(m)
	_check(solids.has(Poble.STAGE_RECT) and solids.has(Poble.TOWER_RECT), "stage and Aragonese tower in solids")

	# 4. Surface detection
	_check(Poble.surface(m, Poble.FOUNTAIN_POS) == Surfaces.S.WATER, "fountain center is water")
	_check(Poble.surface(m, Vector2(640.0, -2300.0)) == Surfaces.S.PAVEMENT, "Plaza Mayor stone paving is pavement")
	_check(Poble.surface(m, Vector2(200.0, -5200.0)) == Surfaces.S.GRASS, "terraced olive garden wing is grass")
	_check(Poble.surface(m, Vector2(640.0, -5200.0)) == Surfaces.S.PAVEMENT, "central bastion promenade is pavement")

	# 5. Signature line & walk-specific goals: wrap 4 arcade columns + fountain, sniff 3 workshops
	m.leash.static_contacts = 1
	for i in range(4):
		m.leash.contact_pole = Poble.ARCADE_COLUMNS[i]
		Poble.tick(m, DT)
	_check(m.poble_columns_wrapped.size() == 4, "wrapped 4 distinct arcade columns (%d)" % m.poble_columns_wrapped.size())
	_check("ARCADE WRAP" in m.combo.banked, "awarded ARCADE WRAP combo")

	m.leash.contact_pole = Poble.FOUNTAIN_POS
	Poble.tick(m, DT)
	_check(m.poble_fountain_wrapped, "wrapped Plaza Mayor stone fountain")
	_check("FOUNTAIN WRAP" in m.combo.banked, "awarded FOUNTAIN WRAP combo")
	m.leash.static_contacts = 0
	m.leash.contact_pole = Vector2(INF, INF)

	for w: Dictionary in Poble.WORKSHOPS:
		m.dog.global_position = w["pos"]
		m.dog.velocity = Vector2(10.0, 0.0)
		Poble.tick(m, DT)
	_check(m.poble_workshops_sniffed.size() == 3, "sniffed all 3 craft workshops (%d)" % m.poble_workshops_sniffed.size())
	_check("CRAFT SNIFF" in m.combo.banked, "awarded CRAFT SNIFF combo")

	# 6. Live event: PobleBalcony (0.8s warning, soak, near-miss save, dog shake-off, bark, boop, outward only)
	var bal: PobleBalcony = m.poble_balcony
	bal.reset()
	_check(bal.state == PobleBalcony.State.IDLE, "balcony starts IDLE")

	# Does not fire on home leg
	m.phase = "home"
	m.human.global_position = Vector2(640.0, -3100.0)
	m.dog.global_position = Vector2(640.0, -3100.0)
	bal.tick(m, DT)
	_check(bal.state == PobleBalcony.State.IDLE, "balcony never triggers on the home leg")

	# Does not fire on top of autowalk pair without warning room (already inside MIN_WARN_CLEARANCE)
	m.phase = "out"
	m.attract_mode = true
	m.human.global_position = PobleBalcony.STATIONS[0]["splash_pos"]
	m.dog.global_position = PobleBalcony.STATIONS[0]["splash_pos"]
	bal.tick(m, DT)
	_check(bal.state == PobleBalcony.State.IDLE, "balcony never fires unannounced on top of autowalk pair")
	m.attract_mode = false
	bal.reset()

	# Normal trigger on outward leg -> 0.8s telegraph
	m.human.global_position = Vector2(640.0, -3100.0)
	m.dog.global_position = Vector2(640.0, -3100.0)
	bal.tick(m, DT)
	_check(bal.state == PobleBalcony.State.WARN, "balcony enters WARN state")
	_check("Heads up!" in m.floated, "neighbor telegraphs 'Heads up!' speech bubble")
	_check(is_equal_approx(PobleBalcony.WARN_DURATION, 0.8), "telegraph duration is 0.8s")

	# Advance 0.5s: still in WARN
	bal.tick(m, 0.5)
	_check(bal.state == PobleBalcony.State.WARN, "still warning at 0.5s")

	# Advance past 0.8s -> POURING
	m.human.global_position = Vector2(640.0, -3100.0)
	bal.tick(m, 0.35)
	_check(bal.state == PobleBalcony.State.POURING, "transitions to POURING after 0.8s warning")

	# Bark at neighbor
	m.dog.global_position = bal.balcony_pos + Vector2(20.0, 20.0)
	var barked: bool = Poble.on_bark(m)
	_check(barked, "barking at balcony neighbor gets a reply")
	_check("BALCONY BARK" in m.combo.banked, "awarded BALCONY BARK combo")

	# Nose boop on the outer splash rim before shaking off
	m.dog.global_position = bal.pos + Vector2(0.0, PobleBalcony.SPLASH_R + 12.0)
	m.dog.facing = Vector2.UP
	m.dog.velocity = Vector2(0.0, -140.0)
	bal.tick(m, DT)
	_check(bal.booped, "booped geranium splash rim")
	_check("GERANIUM BOOP" in m.combo.banked, "awarded GERANIUM BOOP combo")

	# Dog stands under pouring water -> shake-off reward (+2, watering goal)
	var bones_before_shake := m.bones
	m.dog.global_position = bal.pos
	bal.tick(m, DT)
	_check(bal.shaken, "dog shook off under watering can")
	_check(m.poble_shakes == 1, "poble_shakes incremented for watering goal")
	_check(m.bones == bones_before_shake + 2, "shake-off awarded +2 bones")
	_check("SHAKE OFF" in m.combo.banked, "awarded SHAKE OFF combo")

	# Near-miss save when human passes close to splash without getting soaked
	m.human.global_position = bal.pos + Vector2(PobleBalcony.SPLASH_R + 18.0, 0.0)
	bal.tick(m, DT)
	m.human.global_position = bal.pos + Vector2(PobleBalcony.SPLASH_R + 120.0, 0.0)
	bal.tick(m, DT)
	_check(bal.dodged and m.saves_done >= 1, "near miss recorded a save through NearMiss")
	_check("BALCONY DODGE" in m.combo.banked, "awarded BALCONY DODGE combo")

	# Human steps under pouring water -> soaked (patience drop, human_soak rises, dog.slick)
	var pat_before := m.human.patience
	m.human.global_position = bal.pos
	bal.tick(m, DT)
	_check(bal.human_hit, "human soaked when stepping under pour")
	_check(m.human.patience < pat_before, "human patience dropped on soak")
	_check(m.human_soak > 0.0, "human_soak increased (phone goal at risk like rain)")
	_check(m.dog.slick, "wet patch makes ground slick under splash")

	# Verify all 3 walk-specific goals now evaluate as done
	var gdefs: Dictionary = goals_mod.defs(m)
	for gid: String in ["columns_poble", "workshops", "watering"]:
		var d: Dictionary = gdefs[gid]
		var got := int((d["fn"] as Callable).call())
		var target := int(d["target"])
		_check(got >= target, "%s goal check passes (%d/%d)" % [gid, got, target])

	# 7. ShapeBatch drawing runs cleanly
	var batch := ShapeBatch.new()
	Poble.draw_edge_layer(m, batch, -5000.0, 200.0)
	Poble.draw_live(m, batch, -5000.0, 200.0)
	_check(true, "Poble draw methods executed without error")

	game.records = saved_records
	game.gate_open = saved_open
	game.free_play = saved_free_play
	game.persist = saved_persist

	print("test_poble: %d checks, %s" % [checks, "OK" if failures.is_empty() else "%d FAILED" % failures.size()])
	quit(1 if not failures.is_empty() else 0)
