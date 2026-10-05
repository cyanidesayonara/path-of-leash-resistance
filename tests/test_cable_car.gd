extends SceneTree

# Montjuic's telefèric (systems/cable_car.gd): the ticket lies off the path;
# without it the station does nothing; with it the pair ride up from the low
# station on the way out and arrive by the top one with the leash laid
# straight, and ride back down on the way home, which spends the ticket. The
# autowalk bot never takes it.

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	call_deferred("_run")


func _place(m: Node2D, at: Vector2) -> void:
	m.dog.global_position = at
	m.human.global_position = at + Vector2(-20, 30)
	m.leash.resnap()


func _ride(m: Node2D) -> void:
	for i in range(int(60.0 * 7.5)):
		await physics_frame
		if not m.cable_riding:
			return


func _run() -> void:
	var game = root.get_node("Game")
	game.persist = false
	root.get_node("Sfx").muted = true
	game.level_id = "montjuic"
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	for k in range(3):
		await physics_frame
	m._skip_title()
	await physics_frame

	var e: Vector2 = m.walk_edges(m.cable_ticket_pos.y)
	_check(m.cable_ticket_pos.x < e.x - 40.0, "the ticket lies off the path, out on the terrace")
	_check(m.cable_low.y > m.cable_top.y and m.cable_top.y > m.GATE_Y, "the low station is below the top one, both on the climb")

	# no ticket: the station does nothing
	_place(m, m.cable_low)
	await physics_frame
	await physics_frame
	_check(not m.cable_riding, "no ticket, no ride")

	# the ticket
	_place(m, m.cable_ticket_pos)
	await physics_frame
	await physics_frame
	_check(m.cable_ticket and m.cable_ticket_taken, "she picks up the ticket")

	# up
	_place(m, m.cable_low)
	await physics_frame
	await physics_frame
	_check(m.cable_riding and not m.dog.visible, "with it, the pair board at the low station")
	await _ride(m)
	_check(not m.cable_riding and m.cable_rides == 1, "the ride ends")
	_check(m.dog.global_position.distance_to(m.cable_top) < 200.0, "by the top station")
	_check(m.dog.visible and m.human.visible and m.leash.visible, "back on their feet, leash and all")
	_check(m.leash.used_length() < m.leash_len * 1.05, "the leash laid straight, not stretched across the hill")
	_check(m.cable_ticket, "the ticket is a return")
	var G: GDScript = load("res://systems/goals.gd")
	var q: Dictionary = G.defs(m)["cable"]
	_check(int(q.fn.call()) == 1, "riding it does the goal")

	# not again on the way out
	_place(m, m.cable_low)
	await physics_frame
	await physics_frame
	_check(not m.cable_riding, "one ride up per walk")

	# down, on the way home
	m.phase = "home"
	_place(m, m.cable_top)
	await physics_frame
	await physics_frame
	_check(m.cable_riding, "on the way home, down from the top station")
	await _ride(m)
	_check(m.dog.global_position.distance_to(m.cable_low) < 200.0, "to the low station")
	_check(not m.cable_ticket and m.cable_rides == 2, "the ticket is spent")

	# the bot never takes it
	m.free()
	await physics_frame
	var m2: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m2)
	if not m2.is_node_ready():
		await m2.ready
	for k in range(3):
		await physics_frame
	m2._skip_title()
	m2.auto_walk = true
	_place(m2, m2.cable_ticket_pos)
	await physics_frame
	await physics_frame
	_check(not m2.cable_ticket_taken, "the autowalk bot leaves the ticket where it is")
	m2.free()

	print("test_cable_car: %d checks, %s" % [checks, "OK" if failures.is_empty() else "%d FAILED" % failures.size()])
	quit(1 if not failures.is_empty() else 0)
