extends SceneTree

# The verge's grass cache (main.grass_row): every row of every sampled walk
# grows exactly the cells the uncached checks pass, and ground added
# mid-walk (a slow zone, as the horses' droppings add) is seen at once.

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	create_timer(120.0).timeout.connect(func():
		print("FAIL: test watchdog timeout")
		quit(1)
	)
	call_deferred("_run")


func _fresh(m: Node2D, y: float) -> PackedFloat32Array:
	var row := PackedFloat32Array()
	var x := -200.0
	while x < 1480.0:
		var h: float = m._cell01(x, y)
		var p := Vector2(x + (h - 0.5) * m.GRASS_STEP * 0.9, y + (fmod(h * 7.13, 1.0) - 0.5) * m.GRASS_STEP * 0.9)
		if p.y > m.GATE_Y and m.surface_at(p) == m.Surfaces.S.GRASS and not m._grass_blocked(p):
			row.append(x)
		x += m.GRASS_STEP
	return row


func _run() -> void:
	var game = root.get_node("Game")
	game.persist = false
	root.get_node("Sfx").muted = true
	for lvl: String in ["park", "partit", "market", "scrap"]:
		game.level_id = lvl
		var m: Node2D = load("res://main.tscn").instantiate()
		root.add_child(m)
		if not m.is_node_ready():
			await m.ready
		for k in range(3):
			await physics_frame
		m._skip_title()
		var step: float = m.GRASS_STEP
		var y := floorf(m.GATE_Y / step) * step
		var same := true
		var grown := 0
		var sample := Vector2.INF
		while y < m.START_Y + 600.0:
			var want := _fresh(m, y)
			# asked twice: the second answer comes from the cache
			same = same and m.grass_row(y) == want and m.grass_row(y) == want
			grown += want.size()
			if sample == Vector2.INF and want.size() > 0:
				sample = Vector2(want[0], y)
			y += step
		_check(same, "%s: every cached row matches the uncached checks" % lvl)
		if lvl == "park":
			_check(grown > 100, "park grows grass (%d cells)" % grown)
		if sample != Vector2.INF:
			var h: float = m._cell01(sample.x, sample.y)
			var p := Vector2(sample.x + (h - 0.5) * step * 0.9, sample.y + (fmod(h * 7.13, 1.0) - 0.5) * step * 0.9)
			m.substance_zones.append({"rect": Rect2(p - Vector2(14.0, 10.0), Vector2(28.0, 20.0)), "kind": "stinky", "slow": true})
			_check(not (sample.x in m.grass_row(sample.y)), "%s: a slow zone added mid-walk clears the grass under it" % lvl)
			m.substance_zones.pop_back()
			_check(sample.x in m.grass_row(sample.y), "%s: and it grows back when the zone goes" % lvl)
		m.queue_free()
		await process_frame
	if failures.is_empty():
		print("test_grass_cache: %d checks, OK" % checks)
		quit(0)
	else:
		print("test_grass_cache: %d checks, %d FAILURES" % [checks, failures.size()])
		quit(1)
