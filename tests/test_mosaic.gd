extends SceneTree

# El Mosaic is walked through Park Guell's pieces in order (docs/LEVEL_DESIGN.md):
# the salamander on the dragon stair, solid, the owner walking round it and
# the drink at its mouth; the hypostyle hall's forest of columns with a lane
# left through it; the plaza wider than the hall with its edges waving, which
# is the serpentine bench and grinds as one; the viaduct's leaning columns;
# and none of the old park's pond or slippery mosaic floor.

var LevelBuild: GDScript
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
	LevelBuild = load("res://world/level_build.gd")
	var game: Node = root.get_node("Game")
	game.level_id = "guell"
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	_check(m.pond.size.x <= 0.0, "none of the old park's pond")
	var tiles := 0
	for pt: Dictionary in m.patches:
		if String(pt["kind"]) == "tile":
			tiles += 1
	_check(tiles == 0, "no slippery mosaic floor: the mosaic is on the landmarks")
	# the hypostyle hall's columns, with a lane through the middle
	var cols := 0
	for i in range(m.deco_pole_count):
		var p: Vector2 = m.poles[i]
		if p.y < LevelBuild.MOSAIC_HALL_Y0 and p.y > LevelBuild.MOSAIC_HALL_Y1:
			cols += 1
	_check(cols >= 16, "a forest of columns in the hypostyle hall (%d)" % cols)
	var lane := true
	for i in range(m.deco_pole_count):
		var p: Vector2 = m.poles[i]
		if p.y < LevelBuild.MOSAIC_HALL_Y0 and p.y > LevelBuild.MOSAIC_HALL_Y1:
			lane = lane and absf(p.x - 640.0) > 50.0
	_check(lane, "a lane left through the hall for the owner")
	# the plaza: wider than the hall, and its edges wave (the bench)
	var hall: Vector2 = m.walk_edges(-2000.0)
	var halves: Array[float] = []
	var y: float = LevelBuild.MOSAIC_PLAZA_Y0 - 20.0
	while y > LevelBuild.MOSAIC_PLAZA_Y1 + 20.0:
		var e: Vector2 = m.walk_edges(y)
		halves.append((e.y - e.x) * 0.5)
		y -= 25.0
	_check(halves.max() > (hall.y - hall.x) * 0.5 + 20.0, "the plaza opens out beyond the hall")
	_check(halves.max() - halves.min() > 15.0, "the plaza's edges wave: the serpentine bench")
	_check(m.on_mosaic_bench(-3200.0) and not m.on_mosaic_bench(-2000.0), "grinding the plaza edge is grinding the bench")
	# the salamander: solid, walked round, the drink at its mouth
	_check(m.islands.size() == 1, "the owner walks round the salamander")
	var sm: Vector2 = LevelBuild.MOSAIC_SALAMANDER
	var sz: Vector2 = LevelBuild.MOSAIC_SALAMANDER_SIZE
	_check(m.fountains.size() == 1 and absf(m.fountains[0].x - sm.x) < 1.0 and m.fountains[0].y > sm.y, "the drink is at the salamander's mouth")
	var dog: CharacterBody2D = m.dog
	dog.collision_mask = 1
	dog.global_position = sm + Vector2(0.0, sz.y * 0.5 + 60.0)
	for i in range(40):
		dog.velocity = Vector2(0, -400)
		dog.move_and_slide()
	_check(not Rect2(sm - sz * 0.5, sz).grow(-4.0).has_point(dog.global_position), "the salamander is solid")
	_check(m.hydrants.size() >= 4, "enough agave planters to mark")
	m.queue_free()
	await process_frame
	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_mosaic: OK")
		quit(0)
	else:
		quit(1)
