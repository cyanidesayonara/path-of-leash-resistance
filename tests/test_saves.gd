extends SceneTree

# What counts as a save (systems/saves.gd, main.stumble_saved_phone): yanking
# your human back scores only when a bike or the road train was really
# coming at them.
#  1. a bike heading at him threatens; one past him, riding away, passing
#     wide or too far off to arrive in time does not
#  2. the road train threatens a human in its row ahead of it, not behind it
#     or off its row
#  3. in a walk: a bike bearing down makes the stumble a save; the same bike
#     ridden away from him does not

const Saves := preload("res://systems/saves.gd")
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
	var h := Vector2(600, 0)
	var H := Saves.HORIZON
	var R := Saves.RADIUS
	_check(Saves.threatens(Vector2(600, -150), Vector2(0, 200), h, H, R), "a bike heading straight at him threatens")
	_check(not Saves.threatens(Vector2(600, 150), Vector2(0, 200), h, H, R), "one already past him does not")
	_check(not Saves.threatens(Vector2(600, -150), Vector2(0, -200), h, H, R), "one riding away does not")
	_check(not Saves.threatens(Vector2(700, -150), Vector2(0, 200), h, H, R), "one passing well wide does not")
	_check(not Saves.threatens(Vector2(600, -600), Vector2(0, 200), h, H, R), "one too far off to arrive in time does not")
	_check(not Saves.threatens(Vector2(600, -100), Vector2.ZERO, h, H, R), "a parked bike does not")

	var body := Rect2(300, -20, 200, 40)   # nose at x 500, heading +x
	_check(Saves.train_threatens(body, 1.0, 72.0, Vector2(560, 0), H, 30.0), "the train threatens him in its row just ahead")
	_check(not Saves.train_threatens(body, 1.0, 72.0, Vector2(250, 0), H, 30.0), "not behind it")
	_check(not Saves.train_threatens(body, 1.0, 72.0, Vector2(560, 120), H, 30.0), "not off its row")

	var game = root.get_node("Game")
	game.persist = false
	root.get_node("Sfx").muted = true
	game.level_id = "street"
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	for k in range(3):
		await physics_frame
	m._skip_title()
	for b in m.get_tree().get_nodes_in_group("bikes"):
		b.queue_free()
	await physics_frame
	var at: Vector2 = m.human.global_position
	var bike := Node2D.new()
	bike.set_script(load("res://entities/bike.gd"))
	bike.set_physics_process(false)
	m.add_child(bike)
	bike.global_position = at + Vector2(0, -140)
	bike.set("vel", Vector2(0, 260))
	bike.set("kind", "bike")
	if not bike.is_in_group("bikes"):
		bike.add_to_group("bikes")
	_check(m.stumble_saved_phone(at), "a bike bearing down makes the yank a save")
	var s0: int = m.saves_done
	m.on_stumble_save(at)
	_check(m.saves_done == s0 + 1, "and it scores")
	bike.set("vel", Vector2(0, -260))
	_check(not m.stumble_saved_phone(at), "the same bike riding away does not")
	m.on_stumble_save(at)
	_check(m.saves_done == s0 + 1, "and a yank then scores nothing")
	bike.free()

	m.free()
	print("test_saves: %d checks, %s" % [checks, "OK" if failures.is_empty() else "%d FAILED" % failures.size()])
	quit(1 if not failures.is_empty() else 0)
