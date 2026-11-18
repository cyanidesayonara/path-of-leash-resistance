extends SceneTree

# Platja de Llevant's stone: the groins and the espigó at the gate line are
# runs of tipped rock (two staggered courses of stamped stones, world/stones.gd)
# along their line from end to end, and the espigó is the walk's own, through
# main._draw_espigo's hook, so the other dog beaches keep their breakwater.

const ShapeBatch := preload("res://systems/shape_batch.gd")
const Stones := preload("res://world/stones.gd")

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
	var game: Node = root.get_node("Game")
	game.persist = false
	game.level_id = "llevant"
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	var L: GDScript = load("res://systems/llevant.gd")
	_check(m.walk_mod == L and L.has_method("draw_espigo"), "Llevant lays its own espigó")
	# a run of rock: stones in two courses, each with shadow, body and facet
	var a := Vector2(-130.0, -2180.0)
	var z := Vector2(270.0, -2180.0)
	var b := ShapeBatch.new()
	L._rock_run(b, a, z, 11.0, Color(0, 0, 0, 0.2), -2180)
	var n := int(a.distance_to(z) / (11.0 * 1.25))
	_check(b._points.size() == (n + 1) * 2 * 3 * Stones.SIDES * 3, "a groin is %d pairs of lit stones" % (n + 1))
	var lo := INF
	var hi := -INF
	var off_line := 0
	for p: Vector2 in b._points:
		lo = minf(lo, p.x)
		hi = maxf(hi, p.x)
		if absf(p.y - a.y) > 30.0:
			off_line += 1
	_check(lo < a.x + 5.0 and hi > z.x - 5.0, "the groin runs end to end (%.0f..%.0f)" % [lo, hi])
	_check(off_line == 0, "and stays on its line (%d points off it)" % off_line)
	var e := ShapeBatch.new()
	L.draw_espigo(m, e)
	_check(not e._points.is_empty(), "the espigó draws into the batch it is given")
	m.queue_free()
	await process_frame
	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_llevant: OK")
		quit(0)
	else:
		quit(1)
