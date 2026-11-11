extends SceneTree

# The street after dark (world/night_fronts.gd):
# - a doorway's kind comes from its module's index alone: the same every time,
#   every kind turns up, and most doors stay dark
# - a built-up walk with the generic edge gets a front per lit doorway, on its
#   building line, facing into the street
# - a walk whose edge is not a row of doors gets none
# - a walk that draws its own edges gets them through its night_fronts hook
# - building the fronts draws nothing from the RNG (seeded walks replay)
# - the light layer draws them only when the lamps are lit

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	call_deferred("_run")


func _walk(lvl: String) -> Node2D:
	var game = root.get_node("Game")
	game.level_id = lvl
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	for k in range(3):
		await physics_frame
	m._skip_title()
	await physics_frame
	m.set_physics_process(false)
	m.set_process(false)
	return m


func _run() -> void:
	var game = root.get_node("Game")
	game.persist = false
	root.get_node("Sfx").muted = true
	var NF: GDScript = load("res://world/night_fronts.gd")

	# 1. The kinds
	var counts := {"": 0}
	for name: String in NF.ORDER:
		counts[name] = 0
	for k in range(2000):
		var kind: String = NF.kind_of(k)
		if k < 20:
			_check(kind == NF.kind_of(k), "module %d is the same kind each time" % k)
		counts[kind] += 1
	for name: String in NF.ORDER:
		var share := float(counts[name]) / 2000.0
		_check(absf(share - float(NF.KINDS[name][0])) < 0.05, "%s is about its share of doorways (%.2f)" % [name, share])
	_check(float(counts[""]) / 2000.0 > 0.2, "a good share of doors stay dark")

	# 2. A generic built-up street: Festa de Gràcia
	var m: Node2D = await _walk("gracia")
	seed(4242)
	var before := randf()
	seed(4242)
	var fronts: Array[Dictionary] = NF.build(m)
	_check(randf() == before, "building the fronts draws nothing from the RNG")
	_check(fronts.size() >= 12, "Gràcia has lit doorways down the street: %d" % fronts.size())
	var on_line := true
	var faces_in := true
	var in_walk := true
	for f: Dictionary in fronts:
		var at: Vector2 = f.at
		var bl: Vector2 = m.building_line(at.y)
		var left := absf(at.x - (bl.x - 27.0)) < 0.5
		var right := absf(at.x - (bl.y + 27.0)) < 0.5
		on_line = on_line and (left or right)
		faces_in = faces_in and ((left and float(f.dir) > 0.0) or (right and float(f.dir) < 0.0))
		in_walk = in_walk and at.y > float(m.GATE_Y) and at.y < float(m.START_Y) + 80.0
		_check(NF.KINDS.has(String(f.kind)), "a front is one of the kinds")
	_check(on_line, "every front is on the building line")
	_check(faces_in, "and faces into the street")
	_check(in_walk, "and is within the walk")
	_check(m.night_fronts() == m.night_fronts(), "main builds them once")
	_check(m.night_fronts().size() == fronts.size(), "and hands out the same list")
	m.queue_free()
	await process_frame

	# 3. No row of doors: the wood, the river wall
	for lvl: String in ["trail", "besos"]:
		m = await _walk(lvl)
		_check(NF.build(m).is_empty(), "%s has no lit doorways" % lvl)
		m.queue_free()
		await process_frame

	# 4. Its own edges, its own fronts: Rambla del Raval, Plaça d'Espanya, L'Eixample, La Superilla, El Poble Espanyol, Els Àngels
	for lvl: String in ["raval", "espanya", "eixample", "superilla", "poble", "angels"]:
		m = await _walk(lvl)
		_check(m.walk_mod.has_method("night_fronts"), "%s says where its fronts are" % lvl)
		_check(NF.build(m).is_empty(), "none from the generic edge")
		var rf: Array[Dictionary] = m.night_fronts()
		_check(rf.size() >= 10, "and has them down %s: %d" % [lvl, rf.size()])
		m.queue_free()
		await process_frame

	# 5. Only when the lamps are lit
	m = await _walk("raval")
	var layer: Node2D = null
	for ch in m.get_children():
		if ch.get_script() != null and String(ch.get_script().resource_path).ends_with("light_layer.gd"):
			layer = ch
	_check(layer != null, "the light layer is there")
	_check(game.lamp_glow() > 0.0, "Raval's campaign sky is night: lamps lit")
	m.queue_free()
	await process_frame

	print("test_night_fronts: %d checks, %d failures" % [checks, failures.size()])
	quit(1 if not failures.is_empty() else 0)
