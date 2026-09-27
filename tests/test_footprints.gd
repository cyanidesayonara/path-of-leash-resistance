extends SceneTree

# Footprints pressed into the ground (main._press_dents): the dog and her
# human leave prints in beach sand, and in any ground under snow, that fade
# as it fills back in. Not on dry paving. Kept to DENT_MAX so a long walk
# never piles up an unbounded trail. And sandy paws last long enough (3 s)
# to track sand onto the boardwalk where you can see it.

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	call_deferred("_run")


func _walk(m: Node2D, from: Vector2, steps: int) -> void:
	for i in range(steps):
		m.dog.global_position = from + Vector2(0.0, -24.0 * i)
		m.human.global_position = Vector2(m.walk_cx + 500.0, 100.0)
		m._press_dents()


func _main(lv: String, weather: String) -> Node2D:
	var game: Node = root.get_node("Game")
	game.level_id = lv
	game.weather = weather
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	return m


func _run() -> void:
	var beach := _main("beach", "clear")
	if not beach.is_node_ready():
		await beach.ready
	beach.dents.clear()
	_walk(beach, Vector2(300.0, -1500.0), 10)
	var on_sand: int = beach.dents.size()
	_check(on_sand >= 8, "the dog leaves prints in the beach sand (%d)" % on_sand)
	beach.dents.clear()
	_walk(beach, Vector2(760.0, -1500.0), 10)
	_check(beach.dents.is_empty(), "none on the dry promenade")
	beach.dents.clear()
	_walk(beach, Vector2(beach.walk_cx, beach.GATE_Y - 200.0), 6)
	_check(beach.dents.size() >= 4, "the dog beach past the gate takes prints too (%d)" % beach.dents.size())
	_check(float(beach.SUBSTANCES["sand"]["life"]) >= 3.0, "sandy paws last long enough to be seen on the boardwalk")
	# they fade: a print older than DENT_LIFE is gone
	beach.dents.clear()
	_walk(beach, Vector2(300.0, -1500.0), 3)
	beach.elapsed += beach.DENT_LIFE + 1.0
	beach.dog.global_position = Vector2(300.0, -2400.0)
	beach._press_dents()
	_check(beach.dents.size() <= 1, "prints older than their life fill back in (%d left)" % beach.dents.size())
	# and the trail is capped
	beach.dents.clear()
	_walk(beach, Vector2(300.0, -300.0), beach.DENT_MAX + 40)
	_check(beach.dents.size() <= beach.DENT_MAX, "the trail keeps at most DENT_MAX prints")
	beach.queue_free()
	await process_frame

	var snow := _main("street", "snow")
	if not snow.is_node_ready():
		await snow.ready
	snow.dents.clear()
	_walk(snow, Vector2(snow.walk_cx, -1500.0), 10)
	_check(snow.dents.size() >= 8, "snow takes prints on the paving (%d)" % snow.dents.size())
	snow.queue_free()
	await process_frame
	root.get_node("Game").weather = "clear"
	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_footprints: OK")
		quit(0)
	else:
		quit(1)
