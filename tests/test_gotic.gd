extends SceneTree

# El Gotic is its own old town (docs/LEVEL_DESIGN.md): alleys that jink left
# and right and open into a plaça; no market stalls; the bridge between two
# buildings drawn over everyone; the plaça's fountain solid, with the owner
# walking round it and a dog able to drink at its rim; scooters parked
# against the walls that stop her; cats on the ledges; laundry overhead.

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
	var LevelBuild: GDScript = load("res://world/level_build.gd")
	var game: Node = root.get_node("Game")
	game.level_id = "oldtown"
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	_check(m.stalls.is_empty(), "none of the market's stalls")
	var west: Vector2 = m.walk_edges(-1100.0)
	var east: Vector2 = m.walk_edges(-2050.0)
	_check(absf((west.x + west.y) - (east.x + east.y)) > 300.0, "the alley jinks from one side to the other")
	var pl: Vector2 = m.walk_edges(LevelBuild.GOTIC_PLACA.y)
	_check(pl.y - pl.x > (west.y - west.x) + 150.0, "and opens out into the plaça")
	var over: Array = m.get_children().filter(func(c: Node) -> bool: return c.get_script() == load("res://world/overheadlayer.gd"))
	_check(over.size() == 1 and (over[0] as Node2D).z_index > m.dog.z_index, "the bridge is drawn above the dog")
	# the fountain: solid, walked round by the owner, drunk from at the rim
	var dog: CharacterBody2D = m.dog
	dog.collision_mask = 1
	var fp: Vector2 = LevelBuild.GOTIC_PLACA
	dog.global_position = fp + Vector2(0, 90)
	for i in range(40):
		dog.velocity = Vector2(0, -400)
		dog.move_and_slide()
	_check(dog.global_position.distance_to(fp) > 40.0, "the fountain basin is solid")
	_check(dog.global_position.distance_to(m.fountains[0]) < 34.0, "and a dog stopped at its rim can drink")
	var human: CharacterBody2D = m.human
	var round_it := true
	for y in [fp.y + 30.0, fp.y, fp.y - 30.0]:
		human.global_position = Vector2(fp.x + 90.0, y)
		human.velocity = Vector2.ZERO
		for f in range(600):
			m.elapsed += 1.0 / 30.0
			human._walk(1.0 / 30.0)
			human.global_position.y = y
			round_it = round_it and human.global_position.distance_to(fp) > 40.0
	_check(round_it, "the owner walks round the fountain, not through it")
	# a scooter against the wall is solid
	var sc: Vector2 = m.scooters[0]
	dog.global_position = sc + Vector2(80, 0)
	for i in range(40):
		dog.velocity = Vector2(-400, 0)
		dog.move_and_slide()
	_check(dog.global_position.x > sc.x + 10.0, "a parked scooter stops the dog")
	_check(m.wallcat_spots.size() == 6 and m.laundry_lines.size() >= 4, "cats on the ledges, laundry overhead")
	m.queue_free()
	await process_frame
	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_gotic: OK")
		quit(0)
	else:
		quit(1)
