extends SceneTree

const StreamFind := preload("res://entities/stream_find.gd")

class FakeDog:
	extends Node2D
	var facing := Vector2.RIGHT


class FakeMain:
	extends Node2D
	var dog := FakeDog.new()
	var dog_carrying := false
	var frozen := false
	var rewards := 0

	func _init() -> void:
		add_child(dog)

	func on_stream_find_returned(_kind: String, _at: Vector2) -> void:
		rewards += 1

	func on_stream_find_grabbed(_at: Vector2) -> void:
		pass


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
	var m := FakeMain.new()
	root.add_child(m)
	var find := Node2D.new()
	find.set_script(StreamFind)
	m.add_child(find)
	find.setup(m, "branch", Vector2(0.0, -2450.0), 300.0, -2450.0, 52.0)
	find.tick(1.0)
	_check(find.position.is_equal_approx(Vector2(0.0, -2450.0)),
		"the event waits until Millie can see the stream")
	m.dog.global_position = Vector2(0.0, -2250.0)
	find.tick(1.0)
	_check(find.position.is_equal_approx(Vector2(54.0, -2450.0)),
		"the loose find follows the stream's deterministic path (%s)" % find.position)
	m.dog.global_position = find.global_position
	find.tick(0.01)
	_check(find.is_carried() and m.dog_carrying, "Millie intercepts the loose find")
	m.dog.global_position = Vector2(54.0, -2370.0)
	find.tick(0.01)
	_check(find.state == find.State.RETURNED and m.rewards == 1 and not m.dog_carrying,
		"carrying the find onto dry ground earns the positive outcome")

	var missed := Node2D.new()
	missed.set_script(StreamFind)
	m.add_child(missed)
	missed.setup(m, "ball", Vector2(295.0, -2450.0), 300.0, -2450.0, 52.0)
	missed.tick(0.2)
	_check(missed.state == missed.State.MISSED and m.rewards == 1,
		"passing under the footbridge has no penalty")

	m.queue_free()
	await process_frame
	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_stream_find: OK")
		quit(0)
	else:
		quit(1)
