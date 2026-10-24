extends SceneTree

# Every walk in Game.LEVELS has its own hand-authored off-leash prop list in
# LevelBuild.FREEDOM_PROPS rather than a single seeded generator: distinct per
# walk, with buried bones, a water trough, solid furniture to run round, and
# markable spots, all clear of the agility lane, water, sign, bench, and pairs.

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
	var game = root.get_node("Game")
	game.persist = false
	var lb: GDScript = load("res://world/level_build.gd")
	var sigs := {}
	for lvl: String in game.LEVELS:
		_check(lb.FREEDOM_PROPS.has(lvl), "%s has a hand-authored FREEDOM_PROPS list" % lvl)
		var sig := str(lb.FREEDOM_PROPS.get(lvl, []))
		_check(not sigs.has(sig), "%s has a distinct FREEDOM_PROPS layout" % lvl)
		sigs[sig] = lvl

		game.level_id = lvl
		var m: Node2D = load("res://main.tscn").instantiate()
		root.add_child(m)
		if not m.is_node_ready():
			await m.ready

		var digs := 0
		var troughs := 0
		var solids := 0
		var markables := 0
		var clear_ok := true
		# only El Barri has an agility course; elsewhere there is no lane
		var lane: Rect2 = m.agility.lane_rect() if m.agility != null else Rect2()
		var sign_r: Rect2 = lb.freedom_sign_rect(m).grow(28.0)
		for i in range(m.park_props.size()):
			var pp: Dictionary = m.park_props[i]
			var k := String(pp.kind)
			var at: Vector2 = pp.pos
			if k == "dig":
				digs += 1
			elif k == "trough":
				troughs += 1
			elif k in ["log", "driftwood", "tyre", "planter"]:
				solids += 1
			if m.MARKABLE_PARK_KINDS.has(k):
				markables += 1
			if lane.has_point(at):
				clear_ok = false
			if k in ["log", "driftwood"] and sign_r.has_point(at):
				clear_ok = false
			for w: Rect2 in m.water:
				if w.has_point(at):
					clear_ok = false
			if k != "trough":
				if at.distance_to(m.gate_bench) < 110.0:
					clear_ok = false
				for si in range(m.PAIR_PARK_SPOTS.size()):
					if at.distance_to(m.pair_park_spot(si)) < 90.0:
						clear_ok = false
				if m.freedom_kind == "placa":
					if lb.placa_fountain(m).grow(34.0).has_point(at):
						clear_ok = false
					for tr: Vector2 in lb.placa_trees(m):
						if at.distance_to(tr) < 66.0:
							clear_ok = false
					for j in range(i):
						var prev: Dictionary = m.park_props[j]
						if String(prev.kind) != "trough" and at.distance_to(prev.pos) < 72.0:
							clear_ok = false

		_check(digs >= 3 and troughs == 1 and solids >= 2 and markables >= 4,
			"%s prop mix ok (digs=%d troughs=%d solids=%d markables=%d)" % [lvl, digs, troughs, solids, markables])
		_check(clear_ok, "%s props clear of agility lane, water, sign, bench, pairs, and placa pits" % lvl)

		m.queue_free()
		await process_frame

	print("test_freedom_props: %d checks, %d failures" % [checks, failures.size()])
	quit(1 if not failures.is_empty() else 0)
