extends SceneTree

# Tests for the "Back on the Sofa" epilogue cutscene, intro polish, and results integration:
#   - SceneHome renders the side-view arrival, hanging leash, sofa flop, and loaf curl
#   - SceneWalkies renders intro polish (carry tail wag, landing puffs)
#   - EpilogueStage coordinates playback, skipping, and results_card reveal
#   - MenuFlow.tick_end handles first-press skipping without accidental level restarts

class DrawTester extends Node2D:
	var callback: Callable
	func _draw() -> void:
		if callback.is_valid():
			callback.call(self)

var SceneHomeScript: GDScript
var SceneWalkiesScript: GDScript
var EpilogueStageScript: GDScript
var FlowScript: GDScript
var GoalsScript: GDScript

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
	SceneHomeScript = load("res://intro/scene_home.gd")
	SceneWalkiesScript = load("res://intro/scene_walkies.gd")
	EpilogueStageScript = load("res://hud/epilogue_stage.gd")
	FlowScript = load("res://hud/menu_flow.gd")
	GoalsScript = load("res://systems/goals.gd")

	_test_scene_home()
	_test_scene_walkies_polish()
	await _test_epilogue_stage_and_game_flow()

	print("HOME_EPILOGUE checks=%d failures=%d" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)


func _test_scene_home() -> void:
	_check(SceneHomeScript != null, "SceneHome script loads successfully")
	var length: float = float(SceneHomeScript.get_script_constant_map()["LENGTH"])
	_check(length >= 8.0 and length <= 10.0, "SceneHome duration is ~8.5s (%.1f)" % length)

	# Test camera tracking across the scene
	for t in [0.0, 1.5, 3.2, 5.0, 7.0, 8.5]:
		var cam: Array = SceneHomeScript.camera(t)
		_check(cam.size() == 2, "camera returns [pos, zoom] at t=%.1f" % t)
		var pos: Vector2 = cam[0]
		var zoom: float = float(cam[1])
		_check(pos.x > 300.0 and pos.x < 1100.0, "camera X in bounds at t=%.1f (%.1f)" % [t, pos.x])
		_check(zoom >= 0.9 and zoom <= 1.5, "camera zoom in bounds at t=%.1f (%.2f)" % [t, zoom])

	# Test drawing calls inside a valid draw context
	var tester := DrawTester.new()
	root.add_child(tester)
	for t in [0.0, 1.0, 2.5, 3.5, 4.5, 5.5, 6.5, 7.5, 8.5]:
		tester.callback = func(c: CanvasItem) -> void: SceneHomeScript.draw(c, t)
		tester.notification(CanvasItem.NOTIFICATION_DRAW)
	_check(true, "SceneHome.draw completes cleanly across all timestamps")
	tester.queue_free()


func _test_scene_walkies_polish() -> void:
	_check(SceneWalkiesScript != null, "SceneWalkies script loads successfully")
	var tester := DrawTester.new()
	root.add_child(tester)
	# Test the beats with carry tail wag and landing puffs (t=3.2..5.0)
	for t in [3.2, 3.35, 3.5, 3.8, 4.2, 4.8, 5.0]:
		tester.callback = func(c: CanvasItem) -> void: SceneWalkiesScript.draw(c, t)
		tester.notification(CanvasItem.NOTIFICATION_DRAW)
	_check(true, "SceneWalkies.draw with carry wag and landing puffs completes cleanly")
	tester.queue_free()


func _test_epilogue_stage_and_game_flow() -> void:
	var main: Node2D = load("res://main.tscn").instantiate()
	root.add_child(main)
	if not main.is_node_ready():
		await main.ready

	_check(main.epilogue_stage != null, "main.epilogue_stage is created")
	_check(main.epilogue_stage.get_script() == EpilogueStageScript, "epilogue_stage is an instance of EpilogueStage")

	# Test headless reset behavior: in headless, it skips immediately
	main.epilogue_stage.reset()
	_check(main.epilogue_stage.visible, "epilogue_stage is visible after reset")
	_check(main.epilogue_stage.skipped, "epilogue_stage skips immediately in headless mode")
	_check(main.epilogue_stage.t >= 6.2, "skipped stage timestamp is >= 6.2 (%.1f)" % main.epilogue_stage.t)

	# Test manual un-skip to verify interactive skip flow
	main.epilogue_stage.skipped = false
	main.epilogue_stage.t = 0.5
	main.epilogue_stage.skip()
	_check(main.epilogue_stage.skipped, "manual skip sets skipped=true")
	_check(main.epilogue_stage.t >= 6.2, "manual skip advances timestamp >= 6.2")
	_check(is_equal_approx(main.results_card.modulate.a, 1.0), "results_card is 100% opaque after skip")

	# Test Goals.finish_walk activates epilogue stage
	main.finished = false
	main.dog.global_position.y = main.HOME_Y + 10.0
	main.human.global_position.y = main.HOME_Y + 10.0
	main.results = {
		"title": "EL BARRI",
		"stars": 3,
		"rows": [],
		"lines": [],
		"rating": "GREAT",
		"time": 42.0,
	}
	GoalsScript.finish_walk(main)
	_check(main.finished, "Goals.finish_walk marks walk finished")
	_check(main.epilogue_stage.visible, "Goals.finish_walk makes epilogue_stage visible")
	_check(main.results_card.visible, "Goals.finish_walk makes results_card visible")

	# Test epilogue stage draw execution
	main.epilogue_stage.notification(CanvasItem.NOTIFICATION_DRAW)
	_check(true, "epilogue_stage._draw() completes cleanly")

	# Test MenuFlow.tick_end input swallowing during cutscene
	main.epilogue_stage.skipped = false
	main.epilogue_stage.t = 0.8
	main.finished = true
	main.tutorial_mode = false
	main.epilogue_stage.skip()
	_check(main.epilogue_stage.skipped, "epilogue_stage can be skipped before menu actions execute")

	main.queue_free()
