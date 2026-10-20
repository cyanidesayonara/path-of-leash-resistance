extends SceneTree

# La Neteja is its own back street at dawn (docs/LEVEL_DESIGN.md): dumpsters
# out at the kerbs (solid) that still leave the street runnable for the
# sweeper chase, scooters parked up, crates by the dumpsters, puddles from
# the water truck, washing overhead, and a dawn light over it all.

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
	game.level_id = "neteja"
	game.night = false
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	var dumps: Array = LevelBuild.neteja_dumpsters(m)
	_check(dumps.size() >= 4, "dumpsters out at the kerbs")
	# still runnable: a clear gap past every dumpster, wider than the pair
	var runnable := true
	for d: Vector2 in dumps:
		var e: Vector2 = m.walk_edges(d.y)
		var gap: float = (e.y - e.x) - LevelBuild.NETEJA_DUMPSTER.x - 12.0
		runnable = runnable and gap >= 250.0
	_check(runnable, "a runnable gap past every dumpster")
	_check(m.scooters.size() >= 3, "scooters parked up")
	var puddles := 0
	for pt: Dictionary in m.patches:
		if String(pt["kind"]) == "puddle":
			puddles += 1
	_check(puddles >= 4, "puddles from the water truck (%d)" % puddles)
	_check(m.laundry_lines.size() >= 4, "washing overhead")
	var tint: Color = m._weather_tint()
	_check(tint.r > tint.b + 0.1, "a warm dawn light")
	# the market skeleton used to leave an open manhole, and four warning
	# cones round it, in the middle of the chase
	_check(m.manholes.is_empty(), "no open manhole in the lane")
	var road_cones := 0
	var crates := 0
	for c: Node2D in m.get_tree().get_nodes_in_group("cones"):
		if String(c.kind) == "cone":
			road_cones += 1
		elif String(c.kind) == "crate":
			crates += 1
	_check(road_cones == 0, "no warning cones in the street (%d)" % road_cones)
	_check(crates >= dumps.size() * 2, "delivery crates stacked by the dumpsters (%d)" % crates)
	var lamps := true
	for i in range(m.deco_pole_count):
		lamps = lamps and m.pole_tree(i) == m.TREE_NONE
	_check(lamps and m.deco_pole_count >= 4, "the slalom posts are lampposts, not trees")
	var hydrant_clear := true
	for hyd: Dictionary in m.hydrants:
		var hp: Vector2 = hyd.pos
		for d: Vector2 in dumps:
			var body := Rect2(d - LevelBuild.NETEJA_DUMPSTER * 0.5, LevelBuild.NETEJA_DUMPSTER)
			if body.grow(6.0).has_point(hp):
				hydrant_clear = false
	_check(hydrant_clear, "no hydrant parked inside a dumpster")
	# a dumpster is solid
	var dog: CharacterBody2D = m.dog
	dog.collision_mask = 1
	var d0: Vector2 = dumps[0]
	var into := 1.0 if d0.x < m.walk_cx else -1.0
	dog.global_position = d0 + Vector2(into * 70.0, 0.0)
	for i in range(40):
		dog.velocity = Vector2(-into * 400.0, 0.0)
		dog.move_and_slide()
	_check(absf(dog.global_position.x - d0.x) > LevelBuild.NETEJA_DUMPSTER.x * 0.5 - 2.0, "a dumpster stops the dog")

	# the two bins the bag chore needs are intentional kerb obstacles: broad
	# clearance from everything else authored, a solid body the sweeper's
	# brooms swing in round, and the street still runnable past them
	var pole_r: float = m.POLE_RADIUS
	_check(m.bins.size() == 2, "two bins at the kerbs (%d)" % m.bins.size())
	var others: Array[Vector2] = []
	others.append_array(dumps)
	others.append_array(m.scooters)
	others.append_array(m.fountains)
	for i in range(m.deco_pole_count):
		others.append(m.poles[i])
	for hyd: Dictionary in m.hydrants:
		others.append(hyd.pos)
	for kb: Dictionary in m.kebabs:
		others.append(kb.pos)
	# the authored crate stacks; the scattered litter is random and not authored
	others.append_array(m.cone_spots)
	var broad := true
	var at_kerb := true
	var runnable_bins := true
	var blocked := true
	for b: Vector2 in m.bins:
		for o: Vector2 in others:
			if b.distance_to(o) <= 80.0:
				broad = false
				print("bin %s too close to %s" % [b, o])
		# the free cross-section at the bin's depth, past every kerb block
		# there: edge to edge minus what stands in the street
		var e: Vector2 = m.walk_edges(b.y)
		at_kerb = at_kerb and minf(b.x - e.x, e.y - b.x) <= 40.0
		var spans: Array[Vector2] = []
		var bin_block := false
		for r: Rect2 in m.chase_kerb_blocks:
			if r.position.y < b.y + 60.0 and r.end.y > b.y - 60.0:
				spans.append(Vector2(r.position.x, r.end.x))
			if r.has_point(b) and absf(r.size.x - pole_r * 2.0) < 0.01:
				bin_block = true
		blocked = blocked and bin_block
		spans.sort_custom(func(p: Vector2, q: Vector2) -> bool: return p.x < q.x)
		var cursor := e.x
		var widest := 0.0
		for sp: Vector2 in spans:
			widest = maxf(widest, sp.x - cursor)
			cursor = maxf(cursor, sp.y)
		widest = maxf(widest, e.y - cursor)
		runnable_bins = runnable_bins and widest >= 250.0
		if widest < 250.0:
			print("bin %s leaves %.0f" % [b, widest])
	_check(broad, "each bin stands more than 80 px from every authored prop, snack and the fountain")
	_check(at_kerb, "each bin stands at a kerb, inside the walk (within 40 px of its edge)")
	_check(blocked, "each bin's collision extents are a chase kerb block")
	_check(runnable_bins, "a 250 px runnable gap past every bin")
	# the brooms react: with the bin in the blocks, the broom on its side
	# swings in; without it, it stays out at the kerb
	var swept := true
	for b: Vector2 in m.bins:
		var side := signf(b.x - m.walk_cx)
		var with_blocks := Node2D.new()
		with_blocks.set_script(load("res://entities/sweeper.gd"))
		with_blocks.setup(m, b.y + 30.0, m.walk_cx, m.walk_half, 140.0)
		with_blocks.kerb_blocks = m.chase_kerb_blocks.duplicate()
		var without := Node2D.new()
		without.set_script(load("res://entities/sweeper.gd"))
		without.setup(m, b.y + 30.0, m.walk_cx, m.walk_half, 140.0)
		var pulled: float = (float(without._broom_x(side)) - float(with_blocks._broom_x(side))) * side
		swept = swept and pulled > 20.0
		with_blocks.free()
		without.free()
	_check(swept, "the sweeper's broom swings in round a kerb bin")
	m.queue_free()
	await process_frame
	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_neteja: OK")
		quit(0)
	else:
		quit(1)
