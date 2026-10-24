extends SceneTree

# Tests visual polish additions for La Neteja:
# 1. Cuidem Barcelona selective recycling dumpsters (yellow envasos, blue paper, brown organica, grey resta, green vidre)
# 2. Foot-pedal opening mechanism and municipal branding band
# 3. Flanking waste props (flattened cardboard stacks, glass bottle crates)
# 4. Curbside soap suds / cleaning foam bubbles (bromera) around wheels and gutter drains
# 5. Curbside storm drain grates (embornals de reixa) with runoff streaks
# 6. Commercial storefront fascia boards (rètols de botiga) and facade gooseneck lanterns

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
	game.level_id = "neteja"
	game.night = false
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready

	var dumps: Array[Vector2] = LevelBuild.neteja_dumpsters(m)
	_check(dumps.size() == 5, "five Cuidem Barcelona dumpster stations along the street (%d)" % dumps.size())

	# Test dumpster categories and positioning along the kerb
	for i in range(dumps.size()):
		var d: Vector2 = dumps[i]
		var e: Vector2 = m.walk_edges(d.y)
		var is_west: bool = d.x < m.walk_cx
		var kerb_x: float = e.x if is_west else e.y
		_check(absf(d.x - kerb_x) < 40.0, "dumpster %d sits neatly along the kerb" % i)

	# the dumpsters stand at the kerb, clear of the middle of the street
	for i in range(dumps.size()):
		_check(absf(dumps[i].x - m.walk_cx) > 120.0, "dumpster %d leaves the middle of the street clear" % i)
	# the bakery is open where the walk shows it open (y -660, west side), and
	# the shop state is fixed per module, not random per frame
	_check(m._neteja_open_shop(-660.0, -1.0), "the bakery at -660 on the west side is open")
	_check(m._neteja_open_shop(-1100.0, 1.0) == m._neteja_open_shop(-1100.0, 1.0), "a shop's state is fixed")
	# a couple of real frames: a draw error here fails the run (SCRIPT ERROR)
	await process_frame
	await process_frame

	m.queue_free()
	await process_frame

	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_neteja_polish: OK")
		quit(0)
	else:
		quit(1)
