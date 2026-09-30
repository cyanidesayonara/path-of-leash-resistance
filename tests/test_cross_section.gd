extends SceneTree

# Every built-up walk has a cross-section (#65): pavement | strip | the
# building line. The frontage used to be hidden under a full-width lawn and
# the dog could walk out over the roofs. This builds each built walk and
# checks that the building line sits where CROSS_SECTIONS says (and follows
# the path where it bends), that the ground in the strip is what the strip
# is, that the off-leash area keeps its own ground, and that a dog pushed at
# the building line stops at it.

# loaded in _run: the module refers to the Game autoload, which does not
# exist yet while this script is being compiled
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
	for lv: String in LevelBuild.CROSS_SECTIONS.keys():
		game.level_id = lv
		var main: Node2D = load("res://main.tscn").instantiate()
		root.add_child(main)
		if not main.is_node_ready():
			await main.ready
		var xs: Array = LevelBuild.CROSS_SECTIONS[lv]
		_check(bool(main.built), "%s is built" % lv)
		var y := -2000.0
		var e: Vector2 = main.walk_edges(y)
		var f: Vector2 = main.frontage(y)
		_check(is_equal_approx(e.x - f.x, float(xs[1])) and is_equal_approx(f.y - e.y, float(xs[3])),
			"%s: the building line is the strip's width out from the paving" % lv)
		# the ground in each strip
		for side: int in [0, 1]:
			var kind := String(xs[side * 2])
			var width := float(xs[side * 2 + 1])
			if width <= 0.0:
				continue
			var p := Vector2((e.x - width * 0.5) if side == 0 else (e.y + width * 0.5), y)
			var want: int = main.Surfaces.S.GRASS if kind == "grass" else main.Surfaces.S.PAVEMENT
			_check(main.surface_at(p) == want, "%s: the %s strip is %s underfoot" % [lv, "left" if side == 0 else "right", kind])
		# the off-leash area past the gate keeps its own ground
		var yard := Vector2(main.walk_cx - main.walk_half - 60.0, main.GATE_Y - 300.0)
		_check(main.surface_at(yard) != main.Surfaces.S.PAVEMENT or lv == "station" or lv == "site" or lv == "scrap",
			"%s: the off-leash area is not turned into sidewalk" % lv)
		# a dog pushed at the building line stops at it
		var dog: CharacterBody2D = main.dog
		dog.collision_mask = 1
		dog.global_position = Vector2(e.x - float(xs[1]) * 0.5 + 10.0, y)
		for i in range(40):
			dog.velocity = Vector2(-600.0, 0.0)
			dog.move_and_slide()
		_check(dog.global_position.x > f.x - 30.0, "%s: the dog stops at the left building line (x %.0f, line %.0f)" % [lv, dog.global_position.x, f.x])
		main.queue_free()
		await process_frame
	# El Mosaic's terrace walls follow the path through every bend and wave,
	# standing right at its edge
	game.level_id = "guell"
	var g: Node2D = load("res://main.tscn").instantiate()
	root.add_child(g)
	if not g.is_node_ready():
		await g.ready
	var follows := true
	var yy: float = g.GATE_Y + 100.0
	while yy < g.START_Y:
		follows = follows and is_equal_approx(g.walk_edges(yy).x - g.frontage(yy).x, 0.0)
		yy += 137.0
	_check(follows, "guell: the building line follows the path through every bend")
	g.queue_free()
	await process_frame
	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_cross_section: OK")
		quit(0)
	else:
		quit(1)
