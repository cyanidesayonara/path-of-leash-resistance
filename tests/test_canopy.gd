extends SceneTree

# Tree crowns over everyone (world/canopylayer.gd, main.canopy_trees):
#  1. the canopy layer is there, above the dog, the owner and the rope, and
#     under what hangs overhead
#  2. the walk's tree posts in view are its crowns, each with a radius
#  3. a crown fades while she is under it, and is solid when she is not

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
	root.get_node("Sfx").muted = true
	game.level_id = "park"
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	for k in range(3):
		await physics_frame
	m._skip_title()
	await physics_frame

	# 1) the layer
	var layer: Node2D = null
	for c in m.get_children():
		if c.get_script() == load("res://world/canopylayer.gd"):
			layer = c
	_check(layer != null, "the canopy layer is on the walk")
	if layer == null:
		m.free()
		quit(1)
		return
	_check(layer.z_index > m.dog.z_index and layer.z_index > m.human.z_index and layer.z_index > m.leash.z_index,
		"above the dog, the owner and the rope")
	_check(layer.z_index < 14, "and under what hangs overhead")

	# 2) the crowns in view
	var trees: Array = m.canopy_trees()
	_check(trees.size() > 0, "El Parc's trees in view are crowns (%d)" % trees.size())
	var ok := true
	for t: Dictionary in trees:
		if float(t["r"]) <= 0.0 or m.pole_tree(int(t["i"])) == m.TREE_NONE and int(t["id"]) < 100000:
			ok = false
	_check(ok, "each a tree, with a radius")

	# 3) under one, it fades; away, it does not
	var t0: Dictionary = trees[0]
	var tp: Vector2 = t0["p"]
	m.human.global_position = tp + Vector2(300, 200)
	m.dog.global_position = tp + Vector2(10, -8)
	layer._collect()
	var faded_ids: Array = layer._faded.map(func(t): return int(t["id"]))
	_check(faded_ids.has(int(t0["id"])), "the crown she is under fades")
	m.dog.global_position = tp + Vector2(250, 0)
	layer._collect()
	faded_ids = layer._faded.map(func(t): return int(t["id"]))
	_check(not faded_ids.has(int(t0["id"])), "and is solid when she walks out")

	m.free()
	print("test_canopy: %d checks, %s" % [checks, "OK" if failures.is_empty() else "%d FAILED" % failures.size()])
	quit(1 if not failures.is_empty() else 0)
