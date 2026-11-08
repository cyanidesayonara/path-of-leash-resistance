extends SceneTree

# The First Walk's flow (systems/tutorial.gd): the lesson cards' words, a card
# that cannot flash by, the lead and patience lessons landing on the real
# leash conversation, your human never walking a lesson past the next
# station, the owner's events held off while they wait, the practice yard's
# kid and dares, leaving the yard for the dog park, and the free practice
# never ending by itself.

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game = root.get_node("Game")
	game.persist = false
	root.get_node("Sfx").muted = true
	game.level_id = "tutorial"
	var TUT: GDScript = load("res://systems/tutorial.gd")
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	for k in range(3):
		await physics_frame
	m._skip_title()

	# the cards' words: a title and one short instruction each, in the game's
	# voice, buttons only as tokens
	var lessons := 0
	for i in range(TUT.step_count()):
		var st: Dictionary = TUT.step(i)
		var title := String(st.title)
		var body := String(st.body)
		_check(title.length() > 0 and title.substr(0, 1) == title.substr(0, 1).to_upper() and title.ends_with("."),
			"%s: the title is a short sentence (%s)" % [st.id, title])
		_check(body.length() <= 96, "%s: the body is short (%d chars)" % [st.id, body.length()])
		_check(body.substr(0, 1) == body.substr(0, 1).to_upper(), "%s: the body starts with a capital" % st.id)
		_check(not Prompts.fill(body).contains("{"), "%s: every token in the body fills" % st.id)
		_check(not body.to_lower().contains(" lead ") and not body.to_lower().contains("owner"),
			"%s: says leash and your human" % st.id)
		for key in ["SPACE", "SHIFT", "WASD", "ESC", "ENTER"]:
			_check(not body.contains(key), "%s: no key name written into the text" % st.id)
		if not TUT.is_free(i):
			lessons += 1
	_check(TUT.lesson_count() == lessons and lessons == TUT.step_count() - 2, "two free steps close it, the rest are lessons")
	_check(TUT.index_of("poop") < TUT.index_of("vault") and TUT.index_of("dare") < TUT.index_of("practice")
		and TUT.index_of("practice") < TUT.index_of("park"), "basics, then tricks, then free practice")

	# a lesson that needs your human walking never walks them past the next
	# station: they stop at its spot and wait
	for i in range(TUT.step_count()):
		var st: Dictionary = TUT.step(i)
		if bool(st.get("hold", false)) or TUT.is_free(i):
			continue
		var hp: Vector2 = m.tut_hold_point(i)
		var nxt := -1
		for j in range(i + 1, TUT.step_count()):
			if bool(TUT.step(j).get("hold", false)):
				nxt = j
				break
		_check(nxt >= 0 and is_equal_approx(hp.y, m.tut_hold_point(nxt).y),
			"%s: your human stops at the next station (%.0f)" % [st.id, hp.y])

	# a card is up long enough to read before it can pass
	m.tut_step = TUT.index_of("walk")
	m.tut_card_t = 0.0
	m.tut_start_y = m.dog.global_position.y + 1000.0
	m._tick_tutorial(0.5)
	_check(int(m.tut_step) == TUT.index_of("walk"), "a lesson done in its first moment waits for the card to be read")
	m._tick_tutorial(TUT.MIN_CARD_S)
	_check(int(m.tut_step) == TUT.index_of("pull"), "then it lands")

	# the patience lesson: your human waits and still counts the leash; the
	# cloud shows, the leash eases, it lands
	var h: CharacterBody2D = m.human
	m.tut_step = TUT.index_of("patience")
	m.tut_card_t = 5.0
	m._tick_tutorial(0.0)
	_check(h.tut_mind and h.tut_hold_y > -INF, "waiting for the patience lesson, your human keeps score")
	h.patience = 0.3
	m._tick_tutorial(0.1)
	_check(m.tut_clouded and int(m.tut_step) == TUT.index_of("patience"), "a cloud alone does not pass it")
	h.patience = 0.8
	m._tick_tutorial(0.1)
	_check(int(m.tut_step) == TUT.index_of("pee"), "easing off until they calm down does")
	h.patience = 1.0

	# while they wait at a lesson, the phone leaves them be
	m.tut_step = TUT.index_of("pee")
	m._tick_tutorial(0.0)
	h.global_position = m.tut_hold_point(m.tut_step)
	h.event_timer = 0.0
	h.telegraph_t = 0.0
	h._events(1.0)
	_check(h.telegraph_t <= 0.0, "no owner event starts while they wait at a lesson")

	# the lead lesson: they stop level with the ring, and a steady sideways
	# pull walks them into it
	m.tut_step = TUT.index_of("lead")
	m.tut_card_t = 5.0
	m._tick_tutorial(0.0)
	var ring: Vector2 = m.tut_ring
	_check(ring.is_equal_approx(TUT.ring_at(m)) and ring.x < m.walk_cx, "the chalk ring is west of the middle, at the station")
	h.global_position = Vector2(ring.x + 160.0, ring.y + 4.0)
	h.velocity = Vector2.ZERO
	_check(h.tut_holding(), "your human waits level with the ring")
	for f in range(240):
		h.felt_pull = Vector2(-600.0, 0.0)
		m._tick_tutorial(1.0 / 60.0)
		if int(m.tut_step) != TUT.index_of("lead"):
			break
		h._walk(1.0 / 60.0)
	_check(int(m.tut_step) == TUT.index_of("lead") + 1,
		"a steady pull leads them into the ring (they stopped at x %.0f, ring at %.0f)" % [h.global_position.x, ring.x])
	h.felt_pull = Vector2.ZERO

	# every meter a lesson outlines is a rect the status card draws
	var HudPanel: GDScript = load("res://hud/hud_panel.gd")
	for i in range(TUT.step_count()):
		var mt := String(TUT.step(i).get("meter", ""))
		if mt != "":
			_check(HudPanel.POINT_RECTS.has(mt), "%s: its meter outline %s is on the status card" % [TUT.step(i).id, mt])

	# the poop lesson's ringed grass is a good spot, and the First Walk pays it
	_check(m.walk_has_good_spots(), "the First Walk has good spots to teach")
	_check(m.poop_spot_good(TUT.poop_grass(m)), "the lesson's ringed grass is a good spot")
	_check(String(TUT.step(TUT.index_of("poop")).body).contains("good spot"), "the poop lesson names good spots")

	# the lessons that need the zoomies give them back while she is not running
	m.tut_step = TUT.index_of("vault")
	m.dog.energy = 0.0
	m.dog.turbo_active = false
	m._tick_tutorial(2.0)
	_check(float(m.dog.energy) > 0.5, "a bar burnt on the way fills again at a trick lesson")
	m.tut_step = TUT.index_of("pee")
	m.dog.energy = 0.0
	m._tick_tutorial(2.0)
	_check(float(m.dog.energy) == 0.0, "and only there")
	m.dog.energy = 1.0

	# the yard's ledge can be ridden, and two tricks in a row pass the combo
	# lesson; business alone does not
	var yl: PackedVector2Array = TUT.yard_ledge(m)
	m.tut_step = TUT.index_of("combo")
	m.tut_card_t = 5.0
	m.dog.global_position = Vector2(yl[0].x + 6.0, yl[0].y - 50.0)
	m.dog.velocity = Vector2(0, -420)
	m.dog.turbo_active = true
	m.grind_cd = 0.0
	m._tick_grind(1.0 / 60.0)
	_check(m.grind.active, "zoomies along the yard's ledge: she is up on it")
	m.grind.active = false
	m.dog.turbo_active = false
	m.combo.add("SNIFF", 2)
	m.combo.add("MARK", 3)
	m._tick_tutorial(0.1)
	_check(int(m.tut_step) == TUT.index_of("combo"), "business is not a combo")
	m.combo.add("LEDGE RUN", 4)
	m.combo.add("POLE SWING", 4)
	m._tick_tutorial(0.1)
	_check(int(m.tut_step) == TUT.index_of("dare"), "a grind then a swing is")

	# the yard: the kid sits there, and dares only once the dare lesson is up
	var kid: Node2D = m.challenge_giver if is_instance_valid(m.challenge_giver) else null
	for c in m.get_children():
		if c.get_script() != null and String(c.get_script().resource_path).ends_with("challenger.gd"):
			kid = c
	_check(kid != null and kid.global_position.is_equal_approx(TUT.yard_kid(m)), "the kid with the dares sits in the yard")
	if kid != null:
		_check(kid.ladder() == TUT.YARD_LADDER and int(kid.ladder()[0][0]) < int(kid.LADDER[0][0]),
			"and the First Walk's dares are easier than a walk's")
	m.tut_step = TUT.index_of("teeter")
	_check(not m.tut_dares_open(), "no dares before the dare lesson")
	m.tut_step = TUT.index_of("dare")
	_check(m.tut_dares_open(), "dares from the dare lesson on")
	m.challenge.phase = "live"
	m.tut_card_t = 5.0
	m._tick_tutorial(0.1)
	_check(int(m.tut_step) == TUT.index_of("practice"), "taking a dare passes the lesson, win or lose")
	m.challenge.phase = ""
	m.challenge.active = false

	# leaving the yard: heading for the gate on a tight leash gets your human up
	var bench: Vector2 = TUT.practice_bench(m)
	m._tick_tutorial(0.0)
	_check(h.tut_hold_y > -INF, "in the yard your human waits on the bench")
	m.dog.global_position = Vector2(bench.x + 300.0, bench.y - TUT.YARD_EXIT_Y - 30.0)
	m.leash.taut = true
	m._tick_tutorial(0.0)
	_check(h.tut_hold_y > -INF, "a tight leash toward the kid or a post is not leaving")
	m.dog.global_position = Vector2(bench.x, bench.y - TUT.YARD_EXIT_Y - 30.0)
	m.leash.taut = true
	m._tick_tutorial(0.0)
	_check(h.tut_hold_y == -INF and m.tut_leaving, "toward the gate, your human gets up and goes with her")
	m.phase = "freedom"
	m._tick_tutorial(0.1)
	_check(int(m.tut_step) == TUT.index_of("park"), "through the gate, the dog park's card")
	_check(String(TUT.skip_label(m.tut_step)) == "finish", "which offers finish, not move on")

	m.queue_free()
	await process_frame
	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_tutorial_flow: OK")
		quit(0)
	else:
		quit(1)
