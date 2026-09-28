extends SceneTree

# El Barri is the first walk (docs/LEVEL_DESIGN.md): open from the start and
# first in the list after the tutorial and the Daily Walk, with La Rambla now
# behind a couple of stars. It is the everyday park at the end of the
# street: no traffic, no crowd, no pickpockets, nothing that says where.

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
	var game: Node = root.get_node("Game")
	_check(game.LEVELS[0] == "barri", "El Barri is the first walk")
	_check(int(game.STAR_GATE["barri"]) == 0, "and open from the start")
	_check(int(game.STAR_GATE["street"]) > 0, "La Rambla now needs stars")
	var c: Array = game.CAROUSEL
	_check(c.find("barri") == c.find("daily") + 1, "first in the list after the Daily Walk")
	game.level_id = "barri"
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	_check(not m.rambla(), "it is not La Rambla")
	_check(m.lane_ys.is_empty(), "no traffic to cross")
	_check(m.blankets.is_empty() and m.statues.is_empty(), "none of La Rambla's clutter")
	_check(m.stall_kinds.size() == 1 and m.stall_kinds[0] == "pingpong", "the one table is the ping-pong table")
	_check(m.freedom_kind == "yard", "the off-leash area is the fenced dog park")
	for i in range(240):
		await physics_frame
	_check(m.get_tree().get_nodes_in_group("tourists").is_empty() and m.get_tree().get_nodes_in_group("pickpockets").is_empty(),
		"no crowd and no pickpockets")
	m.queue_free()
	await process_frame
	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_barri: OK")
		quit(0)
	else:
		quit(1)
