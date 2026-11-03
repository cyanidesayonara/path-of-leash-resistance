extends SceneTree

# The live events added on 2026-11-03 paid a "dodge" for walking the ordinary
# line, drew three actors on the cached edge canvas (so they froze), creaked
# a cart wheel on every frame of a seam, and let a bark at the fisherman
# count as startling a harbour gull. This holds the corrected behaviour.

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
	_ordinary_line_is_not_a_save()
	_stepping_clear_of_a_hazard_is_a_save()
	_a_seam_creaks_once()
	_a_treat_toss_does_not_touch_the_global_rng()
	await _actors_move_on_the_live_pass()
	await _a_bark_at_the_fisherman_is_not_a_gull()
	print("test_live_event_fixes: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)


# The positions these used to reward: the path, the promenade, the dry side.
func _ordinary_line_is_not_a_save() -> void:
	var sprinkler := Sprinkler.new()
	sprinkler.tick(0.016, Vector2(430.0, -650.0), Vector2(580.0, -850.0))
	sprinkler.tick(0.85, Vector2(430.0, -650.0), Vector2(580.0, -950.0))
	var spray: Dictionary = sprinkler.tick(0.016, Vector2(580.0, -1180.0), Vector2(580.0, -1150.0))
	_check(not bool(spray["dodge"]), "walking past the sprinkler on the path is not a save")

	var ball := Volleyball.new()
	ball.tick(0.016, Vector2(400.0, -1600.0), Vector2.UP, Vector2(770.0, -1950.0))
	ball.tick(0.85, Vector2(400.0, -1600.0), Vector2.UP, Vector2(770.0, -1980.0))
	var volley: Dictionary = ball.tick(0.016, Vector2(400.0, -1600.0), Vector2.UP, Vector2(770.0, -2150.0))
	_check(not bool(volley["dodge"]), "walking the promenade past the volleyball is not a save")

	var waiter := Waiter.new()
	waiter.state = Waiter.State.WALKING
	waiter.pos = Waiter.START_POS
	var stood: Dictionary = waiter.tick(0.0, Vector2(640.0, -900.0), Vector2.ZERO, Vector2(640.0, Waiter.CROSSING_Y - 30.0))
	_check(not bool(stood["dodge"]), "standing on the walking line while the waiter is still at the door is not a save")

	var reel := Fisherman.new()
	reel.state = Fisherman.State.REELING
	var board: Dictionary = reel.tick(0.05, Vector2(640.0, -1600.0), Vector2.ZERO, Vector2(640.0, Fisherman.FISHERMAN_POS.y - 10.0))
	_check(not bool(board["dodge"]), "the boardwalk past the fisherman is not a save")

	var drill := Jackhammer.new()
	drill.state = Jackhammer.State.DRILLING
	drill.timer = 1.0
	var quiet: Dictionary = drill.tick(0.05, Vector2(640.0, -2400.0), Vector2.ZERO, Vector2(640.0, Jackhammer.PIT_POS.y - 10.0))
	_check(not bool(quiet["dodge"]), "the footway past the jackhammer is not a save")

	var dump := AwningDump.new()
	dump.state = AwningDump.State.DUMPING
	dump.timer = 1.0
	var arcade: Dictionary = dump.tick(0.05, Vector2(480.0, -1500.0), Vector2.ZERO, Vector2(480.0, AwningDump.DUMP_Y - 10.0))
	_check(not bool(arcade["dodge"]), "the far side of the street, away from the awning, is not a save")

	var tourist := LostTourist.new()
	tourist.triggered = true
	tourist.state = LostTourist.State.RUNNING
	tourist.pos = Vector2(850.0, LostTourist.CROSSING_Y)
	var walked_on: Dictionary = tourist.tick(0.0, Vector2.ZERO, Vector2.ZERO, Vector2(640.0, LostTourist.CROSSING_Y - 40.0))
	_check(not bool(walked_on["dodge"]), "passing the tourist's street while he is at the far hedge is not a save")


func _stepping_clear_of_a_hazard_is_a_save() -> void:
	var waiter := Waiter.new()
	waiter.state = Waiter.State.WALKING
	waiter.pos = Waiter.START_POS
	var beside := waiter.pos + Vector2(50.0, 0.0)
	var near: Dictionary = waiter.tick(0.0, Vector2(2000.0, 2000.0), Vector2.ZERO, beside)
	_check(not bool(near["dodge"]), "being beside the waiter is not yet a save")
	_check(not bool(near["bump"]), "fifty pixels out is not a bump")
	var clear: Dictionary = waiter.tick(0.0, Vector2(2000.0, 2000.0), Vector2.ZERO, beside + Vector2(0.0, 140.0))
	_check(bool(clear["dodge"]), "stepping clear of the waiter earns the dodge")
	var again: Dictionary = waiter.tick(0.0, Vector2(2000.0, 2000.0), Vector2.ZERO, beside + Vector2(0.0, 200.0))
	_check(not bool(again["dodge"]), "the dodge is earned once")


func _a_seam_creaks_once() -> void:
	var cart := MercatCart.new()
	cart.state = MercatCart.St.CROSSING
	cart.pos = Vector2(181.0, MercatCart.CROSSING_Y)
	var creaks := 0
	for _i in 4:
		var cue: Dictionary = cart.tick(0.01, Vector2(-1000.0, -4000.0), Vector2(-1000.0, -4000.0))
		if bool(cue["creak"]):
			creaks += 1
	_check(creaks == 1, "a floor seam creaks once, not every frame (%d)" % creaks)


func _a_treat_toss_does_not_touch_the_global_rng() -> void:
	seed(12345)
	randf()
	var untouched := randf()
	seed(12345)
	randf()
	var pup := ConeDog.new()
	pup.state = ConeDog.State.RUNNING
	pup.pos = Vector2(ConeDog.TREAT_DROP_X - 1.0, ConeDog.CROSSING_Y)
	pup.tick(0.05, Vector2(2000.0, 2000.0), Vector2.ZERO, Vector2(2000.0, 2000.0))
	_check(is_equal_approx(untouched, randf()), "the cone dog's treat toss keeps its own random sequence")


func _actors_move_on_the_live_pass() -> void:
	var game: Node = root.get_node("Game")
	game.persist = false
	root.get_node("Sfx").muted = true
	for walk: String in ["reial", "vet", "tibidabo"]:
		game.level_id = walk
		var m: Node2D = load("res://main.tscn").instantiate()
		root.add_child(m)
		if not m.is_node_ready():
			await m.ready
		var mod: GDScript = m.walk_mod
		_check(mod.has_method("draw_live"), "%s draws its actor on the live pass" % walk)
		var field := ""
		var shown := 0
		match walk:
			"reial":
				field = "waiter"
				shown = Waiter.State.WALKING
			"vet":
				field = "cone_dog"
				shown = ConeDog.State.RUNNING
			"tibidabo":
				field = "unicyclist"
				shown = Unicyclist.State.RIDING
		var actor: Object = m.get(field)
		_check(actor != null, "%s has its actor" % walk)
		if actor == null:
			m.free()
			await process_frame
			continue
		actor.state = shown
		var home: Vector2 = actor.pos
		var view_top := -2400.0
		var view_bottom := -800.0
		var first := ShapeBatch.new()
		mod.draw_edge_layer(m, first, view_top, view_bottom)
		actor.pos = home + Vector2(180.0, 0.0)
		var second := ShapeBatch.new()
		mod.draw_edge_layer(m, second, view_top, view_bottom)
		_check(first._points == second._points, "%s's edge canvas does not carry the moving actor" % walk)
		if mod.has_method("draw_live"):
			actor.pos = home
			var live_a := ShapeBatch.new()
			mod.draw_live(m, live_a, view_top, view_bottom)
			actor.pos = home + Vector2(180.0, 0.0)
			var live_b := ShapeBatch.new()
			mod.draw_live(m, live_b, view_top, view_bottom)
			_check(not live_a._points.is_empty() and live_a._points != live_b._points, "%s's live pass follows the actor" % walk)
		m.free()
		await process_frame


func _a_bark_at_the_fisherman_is_not_a_gull() -> void:
	var game: Node = root.get_node("Game")
	game.persist = false
	game.level_id = "port"
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	_check(m.fisherman != null, "the port has its fisherman")
	m.fisherman.state = Fisherman.State.REELING
	var before: int = m.port_gulls_startled
	var reached := 0
	for spot: Vector2 in Port.GULL_SPOTS:
		if spot.distance_to(Fisherman.FISHERMAN_POS) < Port.GULL_BARK_R:
			reached += 1
	m.on_bark(Fisherman.FISHERMAN_POS)
	_check(m.port_gulls_startled == before + reached,
			"barking at the fisherman counts the harbour gulls it reaches, and no extra (%d)" % m.port_gulls_startled)
	m.free()
	await process_frame
