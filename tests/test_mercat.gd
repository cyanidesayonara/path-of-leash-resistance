extends SceneTree

# El Mercat is its own market hall (docs/LEVEL_DESIGN.md): in off the street
# under the arch into a hall much wider than the street; stall blocks down
# the middle that are solid, with the owner keeping to one aisle round each;
# an iron column at every block corner to wind the leash on; stalls along
# the walls, the fish counter among them with meltwater and scales in front;
# the arches drawn over everyone; and no van parked indoors.

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
	game.level_id = "market"
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	var street: Vector2 = m.walk_edges(-200.0)
	var hall: Vector2 = m.walk_edges(-2800.0)
	_check(hall.y - hall.x > (street.y - street.x) + 250.0, "the hall is much wider than the street outside")
	_check(m.islands.size() == LevelBuild.MERCAT_BLOCKS.size(), "the owner keeps to an aisle round every stall block")
	_check(m.deco_pole_count == LevelBuild.MERCAT_BLOCKS.size() * 4, "an iron column at every block corner")
	_check(m.furgoneta.x >= INF, "no van parked inside the hall")
	var kinds := {}
	for k: String in m.stall_kinds:
		kinds[k] = true
	_check(kinds.has("fish") and kinds.has("fruit") and kinds.has("jamon"), "fruit, fish and jamon stalls on the walls")
	var melt := 0
	for pt: Dictionary in m.patches:
		if String(pt["kind"]) == "puddle" or String(pt["kind"]) == "fish":
			melt += 1
	_check(melt >= 4, "meltwater and scales in front of the fish counters (%d)" % melt)
	var over: Array = m.get_children().filter(func(c: Node) -> bool: return c.get_script() == load("res://world/overheadlayer.gd"))
	_check(over.size() == 1 and (over[0] as Node2D).z_index > m.dog.z_index, "the arches are drawn over everyone")
	# a stall block is solid
	var dog: CharacterBody2D = m.dog
	dog.collision_mask = 1
	var blk: Rect2 = LevelBuild.MERCAT_BLOCKS[1]
	dog.global_position = Vector2(blk.get_center().x, blk.end.y + 40.0)
	for i in range(40):
		dog.velocity = Vector2(0, -400)
		dog.move_and_slide()
	_check(not blk.grow(-4.0).has_point(dog.global_position), "a stall block stops the dog")
	_check(m.hydrants.size() >= 4, "enough crate stacks to mark")
	m.queue_free()
	await process_frame
	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_mercat: OK")
		quit(0)
	else:
		quit(1)
