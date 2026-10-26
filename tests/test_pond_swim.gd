extends SceneTree

# El Parc's lake is drawn as a blob inside its Rect2, and swimming follows the
# drawing (main.water_has_point): the middle is water, the inner half of the
# muddy bank still counts, and the rect's corners - dry gravel on screen,
# where she used to paddle - do not. The lake's Rect2 itself is unchanged, for
# the props kept out of it and the owner's weave round it.

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
	game.level_id = "park"
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	var pond: Rect2 = m.pond
	var W: int = m.Surfaces.S.WATER
	_check(pond.size.x > 0.0 and pond in m.water, "the park has its pond, and it is in the water list")
	_check(m.surface_at(pond.get_center()) == W, "the middle of the pond is water")
	for corner: Vector2 in [pond.position, Vector2(pond.end.x, pond.position.y), Vector2(pond.position.x, pond.end.y), pond.end]:
		var inward: Vector2 = (pond.get_center() - corner).normalized() * 12.0
		_check(m.surface_at(corner + inward) != W, "the rect's corner at %s is dry ground, not water" % corner)
	# along each axis the water reaches the drawn water's edge (0.94 of the
	# outline) and on into the bank, but not past the outline's middle
	var o: Dictionary = m.pond_outline()
	var c: Vector2 = pond.get_center()
	for ang: float in [0.0, PI * 0.5, PI, PI * 1.5]:
		var r: float = m._patch_wobble(o, ang)
		var unit := Vector2(cos(ang) * float(o["rx"]), sin(ang) * float(o["ry"]))
		_check(m.surface_at(c + unit * r * 0.96) == W, "the edge of the drawn water swims at angle %.2f" % ang)
		_check(m.surface_at(c + unit * r * 1.06) != W, "the outer bank does not, at angle %.2f" % ang)
	# the wobble at the water's edge measures from the outline, not the rect
	var outside: Vector2 = c + Vector2(float(o["rx"]) * m._patch_wobble(o, 0.0) + 20.0, 0.0)
	_check(absf(m._dist_to_water_edge(pond, outside) - 20.0) < 2.0, "the edge distance is measured to the outline")
	print("%d checks, %d failures" % [checks, failures.size()])
	quit(1 if failures.size() > 0 else 0)
