extends SceneTree

# The town walks, whose gates say PLAÇA, end in a square (main._draw_placa):
# the off-leash space is paved, its fountain is real water she can get into,
# its plane trees stand in rows round the edge (never in the fetching
# runway, nor by the owner's bench or the parked pairs' spots), and there
# are pigeons. The green dog park is still where the others end.

const SQUARES := ["market", "oldtown", "spook", "neteja"]

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
	var lb: GDScript = load("res://world/level_build.gd")
	var sf: GDScript = load("res://world/surfaces.gd")
	for lvl: String in SQUARES + ["street"]:
		root.get_node("Game").level_id = lvl
		var m: Node2D = load("res://main.tscn").instantiate()
		root.add_child(m)
		if not m.is_node_ready():
			await m.ready
		if lvl == "street":
			_check(m.freedom_kind == "yard", "street still ends in the dog park")
		else:
			_check(m.freedom_kind == "placa", "%s ends in a square" % lvl)
			var fr: Rect2 = lb.placa_fountain(m)
			_check(m.surface_at(fr.get_center()) == sf.S.WATER, "%s: the fountain is water" % lvl)
			var trees_ok := true
			var n := 0
			for t: Vector2 in m.trees:
				if t.y < m.GATE_Y - 30.0:
					n += 1
					var in_runway: bool = absf(t.x - 640.0) < 60.0 and t.y > m.GATE_Y - 500.0
					trees_ok = trees_ok and not in_runway and t.distance_to(m.gate_bench) > 95.0 \
						and not fr.grow(30.0).has_point(t)
					for slot in m.PAIR_PARK_SPOTS:
						trees_ok = trees_ok and t.distance_to(slot.position as Vector2) > 85.0
			_check(n >= 6 and trees_ok, "%s: plane trees round the edge, clear of the runway, bench, fountain and pairs (%d)" % [lvl, n])
			_check(m.flock_ys.has(m.GATE_Y - 330.0), "%s: pigeons in the square" % lvl)
		m.queue_free()
		await process_frame
	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_placa_freedom: OK")
		quit(0)
	else:
		quit(1)
