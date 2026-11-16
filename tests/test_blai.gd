extends SceneTree

# Tests Carrer de Blai (systems/blai.gd):
# - registered after La Diagonal, at Les Aigües' star gate, in La Diagonal's
#   chase tier, glossed, a clear night, fifteen goals with its own three
# - the street: the placeta opens on the left; the level check passes; no
#   two solid things (tables, chairs, poles, people, bins, deliveries)
#   stand inside each other, and all of it is on the paving
# - after dark every bar is open and lit as a bar front; by day some are
#   shuttered and fewer people sit out
# - heading for a dropped pintxo, your human says "Leave it!"; leaving it
#   pays and gives patience back, once per pintxo; eating it while told
#   costs LEAVE_COST of their patience
# - the placeta's waiter's tray rocks WOBBLE_T before it goes, on its own;
#   a bump or a bark starts it too; a pintxo caught in the air counts, the
#   rest land on the floor; your human then says leave them
# - sitting pretty by a diner gets a pintxo, and costs no patience

const DT := 1.0 / 60.0

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		printerr("FAIL: ", what)


func _initialize() -> void:
	call_deferred("_run")


func _load(game, hour: String) -> Node2D:
	game.weather = "clear"
	game.hour = hour
	game.level_id = "blai"
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	for k in range(3):
		await physics_frame
	m._skip_title()
	await physics_frame
	m.set_physics_process(false)
	m.set_process(false)
	m.auto_walk = false
	return m


func _free(m: Node2D) -> void:
	m.get_parent().remove_child(m)
	m.free()


func _run() -> void:
	var game = root.get_node("Game")
	game.persist = false
	game.sky_from_args = true
	root.get_node("Sfx").muted = true
	var B: GDScript = load("res://systems/blai.gd")
	var G: GDScript = load("res://systems/goals.gd")

	# --- 1. registration ---
	_check(game.LEVELS.find("blai") == game.LEVELS.find("diagonal") + 1, "in LEVELS right after La Diagonal")
	_check(game.CAROUSEL.find("blai") == game.CAROUSEL.find("diagonal") + 1, "in CAROUSEL right after La Diagonal")
	_check(int(game.STAR_GATE["blai"]) == int(game.STAR_GATE["aigues"]), "opens at Les Aigües' star gate")
	_check(String(game.CHASE_GATE.get("blai", "")) == String(game.CHASE_GATE["diagonal"]), "in La Diagonal's chase tier")
	_check(String(game.LEVEL_NAMES["blai"]) == "Carrer de Blai", "named Carrer de Blai")
	_check(game.LEVEL_SUBTITLES.has("blai") and game.LEVEL_SUBTITLES_CA.has("blai") and game.LEVEL_SUBTITLES_ES.has("blai"),
		"glossed in English, Catalan and Spanish")
	_check(game.CAMPAIGN_SKY["blai"] == ["clear", "night"], "a clear night")
	var ids: Array = G.LEVEL_GOAL_IDS["blai"]
	_check(ids.size() == 15 and ids.has("leave_it") and ids.has("tray") and ids.has("beg"), "fifteen goals with its own three")

	# --- 2. the street at night ---
	var m: Node2D = await _load(game, "night")
	var e: Vector2 = m.walk_edges(-2680.0)
	_check(e.x < B.WALL_L - 100.0 and absf(e.y - B.WALL_R) < 1.0, "the placeta opens on the left (%.0f..%.0f)" % [e.x, e.y])
	var problems: Array = load("res://world/level_check.gd").check(m)
	_check(problems.is_empty(), "the level check passes: %s" % str(problems))
	_check(m.blai_diners.size() > 20, "the terraces are full at night (%d)" % m.blai_diners.size())
	_check(m.performers.size() >= 12, "groups stand out with a drink (%d)" % m.performers.size())
	_check(m.blai_delivery.is_empty(), "no deliveries at night")
	# solid things clear of one another, and on the paving
	var things: Array = []
	for i in range(m.body_pole_count):
		things.append([m.poles[i], m.POLE_RADIUS, "pole %s" % m.poles[i]])
	for p: Vector2 in m.performers:
		things.append([p, m.PERFORMER_RADIUS, "person %s" % p])
	for h: Dictionary in m.hydrants:
		things.append([h.pos, m.HYDRANT_RADIUS, "pilona %s" % h.pos])
	for f: Vector2 in m.fountains:
		things.append([f, m.FOUNTAIN_RADIUS, "fountain %s" % f])
	var clashes: Array[String] = []
	for i in range(things.size()):
		for j in range(i + 1, things.size()):
			var a: Array = things[i]
			var b: Array = things[j]
			var same_group := String(a[2]).begins_with("person") and String(b[2]).begins_with("person")
			if same_group:
				continue
			if (a[0] as Vector2).distance_to(b[0]) < float(a[1]) + float(b[1]) - 1.0:
				clashes.append("%s / %s" % [a[2], b[2]])
	_check(clashes.is_empty(), "nothing stands inside anything else: %s" % str(clashes.slice(0, 6)))
	var off: Array[String] = []
	for t: Array in things:
		var at: Vector2 = t[0]
		var ee: Vector2 = m.walk_edges(at.y)
		if at.y > m.GATE_Y and (at.x < ee.x - 2.0 or at.x > ee.y + 2.0):
			off.append(String(t[2]))
	_check(off.is_empty(), "everything is on the paving: %s" % str(off.slice(0, 6)))
	# the bars after dark
	var bars := 0
	for f: Dictionary in m.night_fronts():
		if String(f.kind) == "bar":
			bars += 1
	_check(bars >= B.BARS.size(), "every bar is lit after dark (%d of %d)" % [bars, B.BARS.size()])

	# --- 3. leave it ---
	var food: Dictionary = m.kebabs[0]
	var fp: Vector2 = food.pos
	m.human.global_position = fp + Vector2(0.0, 160.0)
	m.human.bubble.visible = false
	m.human.patience = 0.6
	m.dog.global_position = fp + Vector2(0.0, 80.0)
	m.dog.velocity = Vector2(0.0, -120.0)
	m.blai_leave_cool = 0.0
	B.tick(m, DT)
	_check(not m.blai_leave.is_empty(), "heading for a dropped pintxo gets a leave it")
	_check(m.human.bubble.text == "Leave it!", "and your human says so")
	m.dog.velocity = Vector2.ZERO
	m.dog.global_position = fp + Vector2(0.0, 200.0)
	B.tick(m, DT)
	_check(m.blai_leaves == 1, "walking away from it is leaving it")
	_check(float(m.human.patience) > 0.6, "and gives your human a little patience back")
	# the same pintxo again: no second payout
	for i in range(int(1.5 / DT)):
		B.tick(m, DT)
	m.human.bubble.visible = false
	m.dog.global_position = fp + Vector2(0.0, 40.0)
	B.tick(m, DT)
	_check(not m.blai_leave.is_empty(), "she is told again, back at it")
	m.dog.global_position = fp + Vector2(0.0, 220.0)
	B.tick(m, DT)
	_check(m.blai_leaves == 1, "and the same pintxo pays only once")
	# eating one while told
	var food2: Dictionary = m.kebabs[1]
	for i in range(int(1.5 / DT)):
		B.tick(m, DT)
	m.human.bubble.visible = false
	m.human.global_position = (food2.pos as Vector2) + Vector2(0.0, 160.0)
	m.dog.global_position = (food2.pos as Vector2) + Vector2(0.0, 30.0)
	m.human.patience = 0.9
	B.tick(m, DT)
	_check(not m.blai_leave.is_empty(), "told to leave the second")
	food2.eaten = true
	B.tick(m, DT)
	_check(absf(float(m.human.patience) - (0.9 - B.LEAVE_COST)) < 0.02, "eating it anyway costs LEAVE_COST of their patience (%.2f)" % float(m.human.patience))
	_check(m.blai_gobbled == 1, "and is counted")

	# --- 4. the placeta's tray goes on its own, telegraphed ---
	var w = m.blai_waiters[0]
	m.blai_leave = {}
	m.blai_leave_cool = 0.0
	m.human.global_position = Vector2(760.0, -2300.0)
	m.dog.global_position = Vector2(560.0, -2380.0)
	w.t = 0.0
	var wob_at := -1.0
	var tip_at := -1.0
	var time := 0.0
	while time < 8.0 and tip_at < 0.0:
		m.dog.global_position = Vector2(560.0, -2380.0)
		B.tick(m, DT)
		time += DT
		if wob_at < 0.0 and w.st == B.TrayRun.St.WOBBLE:
			wob_at = time
		if tip_at < 0.0 and not m.blai_pieces.is_empty():
			tip_at = time
	_check(wob_at > 0.0, "the placeta's waiter comes out and the tray rocks on its own")
	_check(tip_at > 0.0 and absf(tip_at - wob_at - B.WOBBLE_T) < 0.1,
		"and goes WOBBLE_T after it starts rocking (%.2f s)" % (tip_at - wob_at))
	_check(m.blai_pieces.size() == B.SPILL_N, "six pintxos in the air")
	# catch one: stand where it is coming down
	var pc: Dictionary = m.blai_pieces[0]
	var kebabs0: int = m.kebabs.size()
	m.human.bubble.visible = false
	m.human.global_position = Vector2(700.0, -2560.0)
	var caught := false
	time = 0.0
	while time < 1.0 and not m.blai_pieces.is_empty():
		if not m.blai_pieces.is_empty() and m.blai_pieces[0] == pc:
			var f: float = clampf((float(pc.t) + DT) / float(pc.T), 0.0, 1.0)
			m.dog.global_position = (pc.from as Vector2).lerp(pc.to, f)
		B.tick(m, DT)
		time += DT
	caught = m.blai_tray_catches >= 1
	_check(caught, "a pintxo caught in the air counts")
	_check(m.kebabs.size() == kebabs0 + B.SPILL_N - m.blai_tray_catches, "the rest land on the floor (%d)" % (m.kebabs.size() - kebabs0))
	_check(int(m.blai_leave.get("pay", 0)) == B.LEAVE_SPILL_PAY,
		"your human says to leave the spill (%s, %s)" % [str(m.blai_leave), m.human.bubble.text])
	# once only on its own: the next run serves its plates
	w.st = B.TrayRun.St.IDLE
	w.pos = w.door
	w.t = 0.0
	var tipped0: int = m.blai_trays_tipped
	time = 0.0
	while time < 6.0:
		m.dog.global_position = Vector2(560.0, -2380.0)
		B.tick(m, DT)
		time += DT
	_check(m.blai_trays_tipped == tipped0, "the tray goes on its own only once")
	# a bark at a waiter with a full tray rocks it
	w.st = B.TrayRun.St.OUT
	w.full = true
	w.pos = Vector2(700.0, -2695.0)
	_check(B.on_bark(m, Vector2(700.0, -2640.0)), "a bark by a waiter with a full tray is heard")
	_check(w.st == B.TrayRun.St.WOBBLE and w.cause == "bark", "and rocks the tray")

	# --- 5. sitting pretty by a diner ---
	w.st = B.TrayRun.St.IDLE
	w.pos = w.door
	w.t = 99.0
	var d: Dictionary = m.blai_diners[0]
	m.blai_leave = {}
	m.blai_leave_cool = 5.0
	var dp: Vector2 = d.pos
	var ce: Vector2 = m.walk_edges(dp.y)
	m.dog.global_position = dp + Vector2(30.0 if dp.x < (ce.x + ce.y) * 0.5 else -30.0, 0.0)
	m.dog.velocity = Vector2.ZERO
	m.human.patience = 0.8
	var eaten0: int = m.kebabs_eaten
	for i in range(int((B.BEG_T + 0.2) / DT)):
		B.tick(m, DT)
	_check(m.blai_begged == 1 and m.kebabs_eaten == eaten0 + 1, "sitting pretty by a diner gets a pintxo")
	_check(absf(float(m.human.patience) - 0.8) < 0.001, "and your human does not mind")
	_free(m)

	# --- 6. by day ---
	m = await _load(game, "day")
	var shut := 0
	for i in range(B.BARS.size()):
		if not bool(m.blai_open[i]):
			shut += 1
	_check(shut > 0, "by day some bars have the shutter down (%d)" % shut)
	var day_bars := 0
	for f: Dictionary in m.night_fronts():
		if String(f.kind) == "bar":
			day_bars += 1
	_check(day_bars == B.BARS.size() - shut, "and only the open ones are listed as bar fronts")
	_check(not m.blai_delivery.is_empty(), "a delivery by a bar door")
	var problems_day: Array = load("res://world/level_check.gd").check(m)
	_check(problems_day.is_empty(), "the level check passes by day: %s" % str(problems_day))
	_free(m)

	print("test_blai: %d checks, %d FAILED" % [checks, failures.size()])
	if failures.is_empty():
		print("OK")
	quit(0 if failures.is_empty() else 1)
