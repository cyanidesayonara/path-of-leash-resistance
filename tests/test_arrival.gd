extends SceneTree

# The way a walk ends. Both of you have to cross. The clock stops. The first
# half-second cannot be skipped; after that, confirm or back brings the card.
# Millie is through the opening before your human moves. A chase threat holds
# on the line. Every walk's opening is clear of props and collision, and the
# loose HOME letters are gone. An apartment door shuts as the walk starts;
# a trailhead does not. An autowalk still finishes on the crossing frame.
# The arrival starts a stretch short of the door, so they walk to it: legs
# stepping, facing the door, the leash pulled straight rather than balled up.

const Arrival := preload("res://systems/arrival.gd")
const ShapeBatch := preload("res://systems/shape_batch.gd")

var checks := 0
var failures: Array[String] = []
var main: Node2D = null


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	call_deferred("_run")


func _load(level_id: String) -> Node2D:
	if main != null:
		main.get_parent().remove_child(main)
		main.free()
		main = null
	var game = root.get_node("Game")
	game.level_id = level_id
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	await process_frame
	main = m
	return m


func _home(m: Node2D, dog_past: bool, human_past: bool, auto := false) -> void:
	m.started = true
	m.phase = "home"
	m.frozen = false
	m.finished = false
	m.arriving = false
	m.auto_walk = auto
	m.dog.velocity = Vector2.ZERO
	m.human.velocity = Vector2.ZERO
	var y := Arrival.line_y(m)
	m.dog.global_position = Vector2(640.0, y + (6.0 if dog_past else -40.0))
	m.human.global_position = Vector2(600.0, y + (4.0 if human_past else -50.0))


func _run() -> void:
	var game = root.get_node("Game")
	game.persist = false
	root.get_node("Sfx").muted = true
	var places := {
		"tutorial": ["apartment", "apartment"],
		"barri": ["apartment", "apartment"],
		"street": ["apartment", "apartment"],
		"park": ["apartment", "apartment"],
		"beach": ["apartment", "apartment"],
		"rain": ["apartment", "apartment"],
		"market": ["apartment", "apartment"],
		"oldtown": ["apartment", "apartment"],
		"site": ["apartment", "apartment"],
		"spook": ["apartment", "apartment"],
		"scrap": ["apartment", "apartment"],
		"guell": ["apartment", "apartment"],
		"neteja": ["apartment", "apartment"],
		"station": ["transit", "station"],
		"montjuic": ["transit", "funicular"],
		"partit": ["transit", "metro"],
		"trail": ["safe", "trailhead"],
		"besos": ["safe", "ramp"],
	}
	for id: String in places:
		var want: Array = places[id]
		_check(Arrival.family_for(id) == String(want[0]) and Arrival.place_for(id) == String(want[1]),
			"%s is a %s %s" % [id, want[0], want[1]])

	for id: String in game.CAROUSEL:
		var m: Node2D = await _load(id)
		_check(Arrival.place_of(m) == Arrival.place_for(id), "%s draws its own place" % id)
		var home := false
		for sg: Dictionary in m.signs:
			if String(sg.txt) == "HOME":
				home = true
		_check(not home, "%s has no loose HOME letters" % id)
		var mouth: Rect2 = Arrival.aperture(m)
		_check(Arrival.rect_clear(m, mouth),
			"%s opening is clear at (%.0f, %.0f)" % [id, mouth.get_center().x, mouth.get_center().y])
		_check(mouth.end.y < float(m.START_Y) + 110.0, "%s opening is north of the south wall" % id)
		# the exit is a whole place closing the walk's south end, not a door
		# on the open path: its fixed part is built and cached once
		var ex: ShapeBatch = Arrival.ExitPortals.static_geometry(m, mouth.get_center(), Arrival.place_of(m), String(game.weather))
		_check(ex._points.size() > 600, "%s has a built exit (%d vertices)" % [id, ex._points.size()])
		_check(Arrival.ExitPortals.static_geometry(m, mouth.get_center(), Arrival.place_of(m), String(game.weather)) == ex,
			"%s builds its exit once" % id)

	var barri: Node2D = await _load("barri")
	_check(is_equal_approx(float(barri.depart_open), 1.0), "the apartment door stands open before the walk (%.2f)" % float(barri.depart_open))
	_home(barri, true, false)
	barri._progress(0.016)
	_check(not barri.arriving and not barri.results_card.visible, "one of you past the line is not home yet")
	_home(barri, true, true)
	var clock := float(barri.elapsed)
	barri._progress(0.016)
	_check(barri.arriving and barri.frozen and not barri.results_card.visible, "both past the line, the arrival starts")
	_check(is_equal_approx(float(barri.elapsed), clock), "the clock stops as it starts")
	var threat := Node2D.new()
	barri.add_child(threat)
	threat.global_position = Vector2(640.0, float(barri.HOME_Y) + 80.0)
	barri.chase_sweeper = threat
	Arrival._hold_threat(barri)
	_check(is_equal_approx(threat.global_position.y, float(barri.HOME_Y)), "a threat already over the line is held on it")
	var held := threat.global_position.y
	for _i in range(8):
		barri._physics_process(1.0 / 60.0)
	_check(is_equal_approx(float(barri.elapsed), clock), "the clock stays stopped through the arrival")
	_check(is_equal_approx(threat.global_position.y, held), "the threat does not come past the line")
	barri.arrival_t = Arrival.PULL + 0.25
	Arrival._apply(barri)
	_check(barri.human.phone_away > 0.5, "your human is pocketing the phone")
	_check(barri.human.presentation_offset.length() < 1.0 and barri.dog.presentation_offset.length() > 4.0,
		"Millie is through before your human moves")
	# the walk in: a real distance to the door, stepped, facing it
	var mouth: Vector2 = Arrival.aperture(barri).get_center()
	_check(mouth.y - Arrival.line_y(barri) >= 100.0,
		"the arrival starts a walk short of the door (%.0f px)" % (mouth.y - Arrival.line_y(barri)))
	var hg: float = barri.human.hgait
	var dg: float = barri.dog.gait
	barri.arrival_t = Arrival.PULL + Arrival.DOG_IN
	for _i in range(20):
		Arrival.tick(barri, 1.0 / 60.0)
	_check(barri.human.hgait > hg + 0.5 and barri.human.presentation_speed > 20.0,
		"your human's legs step on the way in (gait %.2f -> %.2f)" % [hg, barri.human.hgait])
	_check(barri.dog.gait != dg, "and Millie's")
	var to_door: Vector2 = mouth - (barri.human.global_position + barri.human.presentation_offset)
	_check(to_door.length() < 2.0 or barri.human.face_dir.dot(to_door.normalized()) > 0.7,
		"your human faces the door going in")
	_check(is_equal_approx(barri.leash.presentation_straighten, 1.0), "the leash is pulled straight, not balled up")
	barri.arrival_t = 0.2
	Arrival.skip(barri)
	_check(barri.arriving and not barri.results_card.visible, "the first half-second cannot be skipped")
	game.weather = "rain"
	barri.arrival_t = Arrival.PULL
	Arrival.tick(barri, Arrival.DOG_IN)
	_check(int(barri.arrival_print_n) > 0, "rain leaves pawprints on the way in")
	var before := int(barri.phone_hp)
	barri.arrival_t = Arrival.SKIP_LOCK
	var ev := InputEventAction.new()
	ev.action = "bark"
	ev.pressed = true
	Input.parse_input_event(ev)
	await process_frame
	ev.pressed = false
	Input.parse_input_event(ev)
	await process_frame
	_check(barri.finished and barri.results_card.visible and not barri.arriving,
		"back, after the lock, brings the card")
	_check(barri.dog.global_position.y > float(barri.HOME_Y) and barri.human.global_position.y > float(barri.HOME_Y),
		"they end at the door, past the home line")
	_check(is_equal_approx(float(barri.elapsed), clock), "the card's time is the time at the line")
	_check(int(barri.phone_hp) == before, "the phone takes no damage on the way in")
	_check(is_equal_approx(barri.dog.modulate.a, 1.0) and is_equal_approx(barri.human.phone_away, 0.0),
		"the arrival pose is cleared for the card")

	var again: Node2D = await _load("barri")
	_check(is_equal_approx(float(again.depart_open), 1.0), "a fresh apartment still starts with the door open (%.2f)" % float(again.depart_open))
	again.begin_departure()
	again.started = true
	again.depart_hold = 0.0
	Arrival.tick_depart(again, 0.4)
	_check(float(again.depart_open) < 1.0 and float(again.depart_open) > 0.0, "starting the walk closes the door")

	var trail: Node2D = await _load("trail")
	_check(is_equal_approx(float(trail.depart_open), 0.0), "the trailhead has no departure beat")
	trail.begin_departure()
	trail.started = true
	Arrival.tick_depart(trail, 0.4)
	_check(is_equal_approx(float(trail.depart_open), 0.0), "and it still has none after the start")

	var bot: Node2D = await _load("street")
	_home(bot, true, true, true)
	bot.elapsed = 130.0
	bot._progress(0.016)
	_check(bot.finished and not bot.arriving and is_equal_approx(float(bot.elapsed), 130.0),
		"an autowalk finishes on the crossing frame, at that time")

	if main != null:
		main.get_parent().remove_child(main)
		main.free()
	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_arrival: OK")
		quit(0)
	else:
		quit(1)
