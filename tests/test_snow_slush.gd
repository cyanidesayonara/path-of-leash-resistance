extends SceneTree

# Snow lays slush over the path (world/level_build.gd, build_substance_zones).
# It was a rectangle between the corridor's nominal edges, so on the walks
# that bend the path ran out from under it and slush lay on the grass beside
# it. It is a band that follows walk_edges() now: this checks, down the whole
# walk on every bending level and one straight one, that the middle of the
# path is always in the slush and the ground just off either edge never is.

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	# deferred so the autoloads are registered before main.gd is compiled
	call_deferred("_run")


func _run() -> void:
	var game: Node = root.get_node("Game")
	for lv: String in ["trail", "guell", "street"]:
		game.level_id = lv
		game.weather = "snow"
		var main: Node2D = load("res://main.tscn").instantiate()
		root.add_child(main)
		if not main.is_node_ready():
			await main.ready
		var slush: Dictionary = {}
		for z: Dictionary in main.substance_zones:
			if String(z.kind) == "slush":
				slush = z
		_check(not slush.is_empty(), "%s: snow lays slush" % lv)
		if not slush.is_empty():
			var on_path := true
			var off_path := true
			var y: float = main.GATE_Y + 20.0
			while y < main.START_Y:
				var e: Vector2 = main.walk_edges(y)
				on_path = on_path and main.zone_has_point(slush, Vector2((e.x + e.y) * 0.5, y))
				off_path = off_path and not main.zone_has_point(slush, Vector2(e.x - 12.0, y)) \
					and not main.zone_has_point(slush, Vector2(e.y + 12.0, y))
				y += 50.0
			_check(on_path, "%s: the middle of the path is slush all the way down" % lv)
			_check(off_path, "%s: the ground beside the path never is" % lv)
		main.queue_free()
		await process_frame
	game.weather = "clear"
	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_snow_slush: OK")
		quit(0)
	else:
		quit(1)
