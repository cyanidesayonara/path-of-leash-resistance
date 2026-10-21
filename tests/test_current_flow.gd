extends SceneTree

const CurrentFlow := preload("res://systems/current_flow.gd")
const RunEvents := preload("res://systems/run_events.gd")

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
	var body := CharacterBody2D.new()
	root.add_child(body)
	body.velocity = Vector2(0.0, -80.0)
	CurrentFlow.shove_body(body, true, Vector2.DOWN, 220.0, 28.0, false, 0.1)
	_check(is_equal_approx(body.position.y, 30.0),
		"current is a directional velocity floor even against upstream motion (%.1f)" % body.position.y)
	body.position = Vector2.ZERO
	body.velocity = Vector2.ZERO
	CurrentFlow.shove_body(body, true, Vector2.DOWN, 220.0, 28.0, true, 0.1)
	_check(is_equal_approx(body.position.y, 2.8), "planting resists current (%.1f)" % body.position.y)
	body.position = Vector2.ZERO
	CurrentFlow.shove_body(body, false, Vector2.DOWN, 220.0, 28.0, false, 0.1)
	_check(body.position == Vector2.ZERO, "a body outside current does not move")

	var loose := Node2D.new()
	root.add_child(loose)
	CurrentFlow.drift_loose(loose, true, Vector2.RIGHT, 60.0, 0.1, false)
	_check(is_equal_approx(loose.position.x, 6.0), "a loose object follows the same directional current")
	CurrentFlow.drift_loose(loose, true, Vector2.RIGHT, 60.0, 0.1, true)
	_check(is_equal_approx(loose.position.x, 6.0), "current leaves a carried object in Millie's mouth")

	var rainy := 0
	for seed_value in range(1000):
		if RunEvents.chosen(seed_value, "trail", "high_stream", "rain", 20):
			rainy += 1
	_check(rainy >= 180 and rainy <= 220, "the stable event hash is approximately 20%% (%d/1000)" % rainy)
	_check(not RunEvents.chosen(17, "trail", "high_stream", "clear", 20),
		"the high stream never appears on a dry run")
	_check(not RunEvents.chosen(17, "park", "high_stream", "rain", 20),
		"the high stream belongs only to El Bosc")
	_check(RunEvents.chosen(4, "trail", "high_stream", "rain", 20)
			and not RunEvents.chosen(0, "trail", "high_stream", "rain", 20),
		"--seed=4 selects the event and --seed=0 does not")
	var pinned := RunEvents.bucket(162, "trail", "high_stream")
	_check(pinned == RunEvents.bucket(162, "trail", "high_stream"),
		"the event hash is repeatable under --seed (%d)" % pinned)

	body.queue_free()
	loose.queue_free()
	await process_frame
	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_current_flow: OK")
		quit(0)
	else:
		quit(1)
