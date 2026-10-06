extends SceneTree

# A paper bag on Montjuïc's wind (montjuic.blow_litter, entities/litter.gd,
# main.on_litter_caught):
#  1. a gust lifts one, upwind of her; never two loose at once
#  2. a gust shoves it along the wind, and it stays on the path
#  3. walking into it is not a catch; a pounce at speed is, for bones
#  4. three a walk at most

var M: GDScript
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
	M = load("res://systems/montjuic.gd")
	var game = root.get_node("Game")
	game.persist = false
	root.get_node("Sfx").muted = true
	game.level_id = "montjuic"
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	for k in range(3):
		await physics_frame
	m._skip_title()
	await physics_frame

	# 1) a gust lifts one, upwind
	m.wind_dir = Vector2(1, 0.1).normalized()
	_check(M.blow_litter(m), "a gust lifts a paper bag")
	var bag: Node2D = m.get_meta("litter")
	_check(bag != null and bag.global_position.x < m.dog.global_position.x, "upwind of her")
	_check(not M.blow_litter(m), "never two loose at once")

	# 2) shoved along the wind, kept on the path
	var x0: float = bag.global_position.x
	m.wind_gust = 0.9
	m.dog.global_position = bag.global_position + Vector2(0, 300)
	for i in range(50):
		bag._physics_process(1.0 / 60.0)
	m.wind_gust = 0.0
	_check(bag.global_position.x > x0 + 20.0, "a gust shoves it along the wind")
	var e: Vector2 = m.walk_edges(bag.global_position.y)
	_check(bag.global_position.x >= e.x and bag.global_position.x <= e.y, "and it stays on the path")

	# 3) a pounce catches it, a stroll does not
	var b0: int = m.bones
	m.dog.global_position = bag.global_position
	m.dog.velocity = Vector2(0, -40)
	bag._physics_process(1.0 / 60.0)
	_check(is_instance_valid(bag) and not bag.is_queued_for_deletion(), "walking into it is not a catch")
	m.dog.global_position = bag.global_position
	m.dog.velocity = Vector2(0, -300)
	bag._physics_process(1.0 / 60.0)
	_check(bag.is_queued_for_deletion() and m.bones == b0 + 2, "a pounce at speed catches it, for bones")
	await physics_frame

	# 4) three a walk
	_check(M.blow_litter(m), "a second")
	(m.get_meta("litter") as Node2D).queue_free()
	await physics_frame
	_check(M.blow_litter(m), "a third")
	(m.get_meta("litter") as Node2D).queue_free()
	await physics_frame
	_check(not M.blow_litter(m), "and no fourth")

	m.free()
	print("test_litter: %d checks, %s" % [checks, "OK" if failures.is_empty() else "%d FAILED" % failures.size()])
	quit(1 if not failures.is_empty() else 0)
