extends SceneTree

# The other dog walkers shove the street's loose junk aside (entities/cone.gd),
# the way your human does, instead of walking through a bin bag as if it were
# not there.

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	call_deferred("_run")


func _bag(m: Node2D, at: Vector2) -> Node2D:
	var bag := Node2D.new()
	bag.set_script(load("res://entities/cone.gd"))
	m.add_child(bag)
	bag.setup(m, m.dog, m.human, "sack")
	bag.global_position = at
	return bag


func _run() -> void:
	var game: Node = root.get_node("Game")
	game.level_id = "street"
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	# a walker and her dog, standing in for an otherpair.gd pair, well away
	# from the player's own
	var owner_n := Node2D.new()
	var dog_n := Node2D.new()
	m.add_child(owner_n)
	m.add_child(dog_n)
	owner_n.global_position = m.dog.global_position + Vector2(0.0, -900.0)
	dog_n.global_position = owner_n.global_position + Vector2(40.0, 0.0)
	m.pairs_cache = [{"npc_owner": owner_n, "npc_dog": dog_n, "vel": Vector2(0.0, -60.0)}]
	m.cam.position = owner_n.global_position
	var bag := _bag(m, owner_n.global_position + Vector2(4.0, -2.0))
	bag._physics_process(1.0 / 60.0)
	_check((bag.vel as Vector2).length() > 1.0, "a walker who walks into a bin bag sends it aside (%s)" % bag.vel)
	var bag2 := _bag(m, dog_n.global_position + Vector2(3.0, 0.0))
	bag2._physics_process(1.0 / 60.0)
	_check((bag2.vel as Vector2).length() > 1.0, "and so does her dog (%s)" % bag2.vel)
	var far := _bag(m, owner_n.global_position + Vector2(200.0, 0.0))
	far._physics_process(1.0 / 60.0)
	_check((far.vel as Vector2).length() < 1.0, "a bag nobody touches stays put")
	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("OK")
	quit(0 if failures.is_empty() else 1)
