extends SceneTree

# Draw order: what she passes under and what she walks over
# (world/canopylayer.gd, main.overhead_pieces, level_build.JUNK_Z):
#  1. the canopy layer is above the dog, the owner, the rope, the NPCs and the
#     riders, and under the overhead layer
#  2. cones and junk lie under the rope, and the rope under the dog and owner
#  3. every walk's overhead things are pieces of the canopy layer: parasols,
#     the beach terraces' canopies, El Diluvi's awnings and arcade roof, the
#     washing lines, the departures board, the bandstand roof, lamp heads,
#     the ice cream umbrella, the performers' umbrellas in the rain, the dog
#     beach's parasols and El Mercat's shop awnings
#  4. a piece fades while she is under it and is solid when she is not; a
#     lamp head never fades
#  5. nothing else on the walk draws above the canopy layer but the layers
#     that hang over it on purpose

var checks := 0
var failures: Array[String] = []

const CANOPY := "res://world/canopylayer.gd"
const OVERHEAD := "res://world/overheadlayer.gd"
# what may draw above the canopy on purpose: the overhead layer, the cable car,
# the score pops
const ABOVE_OK := ["res://world/overheadlayer.gd", "res://world/cable_layer.gd", "res://world/pops_layer.gd"]


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	call_deferred("_run")


func _load(lv: String) -> Node2D:
	var game = root.get_node("Game")
	game.level_id = lv
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	for k in range(3):
		await physics_frame
	m._skip_title()
	await physics_frame
	return m


func _layer(m: Node2D, path: String) -> Node2D:
	for c in m.get_children():
		if c.get_script() != null and (c.get_script() as Script).resource_path == path:
			return c
	return null


func _kinds(m: Node2D) -> Array:
	m._build_overhead()
	var out := []
	for t: Dictionary in m._over_all:
		if not out.has(int(t["over"])):
			out.append(int(t["over"]))
	return out


func _run() -> void:
	var game = root.get_node("Game")
	game.persist = false
	root.get_node("Sfx").muted = true

	# 1, 2, 4 and 5 on La Rambla: parasols, lamp heads, the ice cream cart
	var m: Node2D = await _load("street")
	var ov: Dictionary = m.Over
	var canopy := _layer(m, CANOPY)
	_check(canopy != null, "the canopy layer is on the walk")
	if canopy == null:
		_finish(m)
		return
	var cz: int = canopy.z_index
	_check(cz > m.dog.z_index and cz > m.human.z_index and cz > m.leash.z_index,
		"the canopy is above the dog, the owner and the rope")
	_check(cz > 12, "and above the riders (bikes and the road train draw at 12)")
	_check(cz < 14, "and under the overhead layer (14)")
	_check(m.leash.z_index < m.dog.z_index and m.leash.z_index < m.human.z_index,
		"the rope is under the dog and the owner")
	var junk: Array = m.get_tree().get_nodes_in_group("cones")
	_check(junk.size() > 0, "La Rambla has cones and junk (%d)" % junk.size())
	var low := true
	for j: Node2D in junk:
		if j.z_index >= m.leash.z_index:
			low = false
	_check(low, "cones and junk lie under the rope")

	# let the walk spawn its people, riders and critters, then nothing but the
	# hanging layers may draw above the canopy
	for k in range(240):
		await physics_frame
	var above := []
	for c in m.get_children():
		if c == canopy or not (c is CanvasItem):
			continue
		var path := "" if c.get_script() == null else (c.get_script() as Script).resource_path
		if path in ABOVE_OK:
			continue
		if (c as CanvasItem).z_index >= cz:
			above.append("%s z%d" % [path.get_file() if path != "" else c.name, (c as CanvasItem).z_index])
	_check(above.is_empty(), "nothing on the walk draws above the canopy: %s" % str(above))

	var kinds := _kinds(m)
	for k: int in [ov.PARASOL, ov.LAMP, ov.ICECREAM]:
		_check(kinds.has(k), "La Rambla's overhead has %s" % ov.keys()[k])

	# 4) fading: under the first parasol it fades, away it is solid
	var par: Dictionary = {}
	var lamp: Dictionary = {}
	for t: Dictionary in m._over_all:
		if par.is_empty() and int(t["over"]) == ov.PARASOL:
			par = t
		if lamp.is_empty() and int(t["over"]) == ov.LAMP:
			lamp = t
	if not par.is_empty():
		var pp: Vector2 = par["p"]
		m.cam.position = pp
		m.dog.global_position = pp + Vector2(12, -10)
		m.human.global_position = pp + Vector2(400, 300)
		canopy._collect()
		_check(_ids(canopy._faded).has(int(par["id"])), "the parasol she is under fades")
		m.dog.global_position = pp + Vector2(300, 0)
		canopy._collect()
		_check(_ids(canopy._solid).has(int(par["id"])) and not _ids(canopy._faded).has(int(par["id"])),
			"and is solid when she walks out")
	if not lamp.is_empty():
		var lp: Vector2 = lamp["p"]
		m.cam.position = lp
		m.dog.global_position = lp + Vector2(18, 0)
		canopy._collect()
		_check(_ids(canopy._solid).has(int(lamp["id"])), "a lamp head over her stays solid")
	m.free()
	await process_frame

	# 3) every other walk's overhead things
	var want := {
		"beach": [ov.PARASOL, ov.PERGOLA, ov.BEACH_PARASOL],
		"rain": [ov.AWNING, ov.ARCADE, ov.LAMP, ov.BROLLY],
		"oldtown": [ov.LAUNDRY, ov.WALL_LAMP],
		"neteja": [ov.LAUNDRY],
		"station": [ov.BOARD],
		"market": [ov.SHOP_AWNING],
		"park": [ov.BANDSTAND],
		"scrap": [ov.LAMP],
	}
	for lv: String in want:
		var w: Node2D = await _load(lv)
		var got := _kinds(w)
		for k: int in want[lv]:
			_check(got.has(k), "%s's overhead has %s" % [lv, ov.keys()[k]])
		if lv == "rain":
			# El Diluvi's umbrellas are up: it always rains there
			w.cam.position = (w.performers[0] as Vector2)
			var shown: Array = w.overhead_pieces().map(func(t): return int(t["over"]))
			_check(game.weather != "rain" or shown.has(ov.BROLLY),
				"a performer in the rain has an umbrella overhead")
		if lv == "beach":
			_check(_layer(w, OVERHEAD) != null, "the seafront has its overhead layer (the lifeguard cabins)")
		w.free()
		await process_frame

	_finish(null)


func _ids(arr: Array) -> Array:
	return arr.map(func(t): return int(t["id"]))


func _finish(m: Node2D) -> void:
	if m != null:
		m.free()
	print("test_zorder_overhead: %d checks, %s" % [checks, "OK" if failures.is_empty() else "%d FAILED" % failures.size()])
	quit(1 if not failures.is_empty() else 0)
