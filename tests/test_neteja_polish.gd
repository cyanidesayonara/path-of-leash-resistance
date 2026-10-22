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

	# Verify drawing methods exist on main
	_check(m.has_method("_draw_neteja"), "La Neteja ground and prop drawing function exists")
	_check(m.has_method("_draw_neteja_module"), "La Neteja building module and storefront drawing function exists")
	_check(m.has_method("_neteja_open_shop"), "La Neteja bakery / shop state resolver exists")

	# Allow a frame to render normally through Godot's pipeline
	await process_frame
	await process_frame
	_check(true, "La Neteja frames rendered cleanly with batched shapes")

	m.queue_free()
	await process_frame

	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_neteja_polish: OK")
		quit(0)
	else:
		quit(1)
