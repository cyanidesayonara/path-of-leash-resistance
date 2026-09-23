extends SceneTree

# A portrait window cannot hold the game's layout (#5), so rotate_prompt.gd
# covers it with a "turn your phone" prompt and pauses the walk. This reshapes
# a real viewport between landscape and portrait and checks the prompt comes
# and goes with the shape, pauses only while it is up, never releases a pause
# it did not make, and keeps its text on screen at a readable size. Needs a
# rendering context, like test_hud_anchoring.gd.

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	# deferred so the autoloads are registered before main.gd is compiled
	call_deferred("_run")


func _shape(window: Vector2i) -> void:
	root.size = window
	await process_frame
	await process_frame


func _run() -> void:
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	if not main.is_node_ready():
		await main.ready
	var prompt: CanvasLayer = main.rotate_prompt
	_check(prompt != null, "main builds a rotate prompt")
	if prompt == null:
		_finish()
		return

	await _shape(Vector2i(1280, 720))
	_check(not prompt.visible, "landscape 1280x720: no prompt")
	_check(not paused, "landscape 1280x720: game not paused")

	await _shape(Vector2i(844, 390))
	_check(not prompt.visible, "landscape phone 844x390: no prompt")
	_check(not paused, "landscape phone 844x390: game not paused")

	await _shape(Vector2i(390, 844))
	_check(prompt.visible, "portrait 390x844: prompt shown")
	_check(paused, "portrait 390x844: game paused")
	var vs: Vector2 = root.get_visible_rect().size
	# logical units per physical pixel under the expand stretch
	var px_per_unit := 390.0 / vs.x
	for l: Label in [prompt._title, prompt._sub]:
		var r := Rect2(l.position, l.size)
		_check(r.position.x >= 0.0 and r.end.x <= vs.x + 0.5 and r.position.y >= 0.0 and r.end.y <= vs.y + 0.5,
			"'%s' stays on screen (%s in %s)" % [l.text, r, vs])
		var fs := float(l.get_theme_font_size("font_size"))
		_check(fs * px_per_unit >= 14.0,
			"'%s' renders at %.1fpx on the phone, want at least 14" % [l.text, fs * px_per_unit])

	await _shape(Vector2i(1280, 720))
	_check(not prompt.visible, "back to landscape: prompt gone")
	_check(not paused, "back to landscape: game resumes")

	# a pause someone else made survives the prompt coming and going
	paused = true
	await _shape(Vector2i(390, 844))
	await _shape(Vector2i(1280, 720))
	_check(paused, "the prompt never releases a pause it did not make")
	paused = false
	_finish()


func _finish() -> void:
	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("ROTATE PROMPT OK")
		quit(0)
	else:
		print("ROTATE PROMPT FAIL")
		quit(1)
