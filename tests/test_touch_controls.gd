extends SceneTree

# The touch controls (hud/touch_controls.gd) are the whole control scheme on a
# phone. Touch had no way to pause, open settings or turbo, and its restart
# button sat on the goals card all walk (#62). This checks, on a real main
# scene at three window shapes: which buttons show while walking, once the
# walk has stopped and on the title; that SKIP appears during tutorial lessons
# and SHARE on daily results; that no two buttons overlap and none sits on the
# vitals card or the goals card; and that tapping the goals card works.
# Needs a rendering context, like test_rotate_prompt.gd.

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	call_deferred("_run")


func _touch() -> Control:
	for c in (root.get_node("Main") if root.has_node("Main") else root.get_child(root.get_child_count() - 1)).hud.get_children():
		if c.get_script() != null and String(c.get_script().resource_path).ends_with("touch_controls.gd"):
			return c
	return null


func _shown(t: Control) -> Array:
	var out := []
	for b: Dictionary in t.buttons:
		if t._shown(b):
			out.append(String(b.label))
	return out


func _tap(t: Control, at: Vector2, down: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.index = 3
	e.position = at
	e.pressed = down
	t._input(e)


func _run() -> void:
	var main: Node2D = load("res://main.tscn").instantiate()
	root.add_child(main)
	if not main.is_node_ready():
		await main.ready
	var t := _touch()
	_check(t != null, "main builds the touch controls")
	if t == null:
		_finish()
		return
	t.visible = true
	for window: Vector2i in [Vector2i(1280, 720), Vector2i(844, 390), Vector2i(2340, 1080)]:
		root.size = window
		await process_frame
		await process_frame
		t._layout()
		var vs: Vector2 = t.get_viewport_rect().size
		main.started = true
		main.frozen = false
		main.paused = false
		var walking := _shown(t)
		_check("RUN" in walking and "MENU" in walking and not "R" in walking,
			"%s walking: RUN and MENU show, R does not (%s)" % [window, walking])
		main.frozen = true
		var stopped := _shown(t)
		_check("R" in stopped and not "RUN" in stopped and not "MENU" in stopped
				and not "DIG" in stopped and not "BARK" in stopped and not "PEE" in stopped,
			"%s stopped: only end-state controls remain" % window)
		main.paused = true
		_check("MENU" in _shown(t), "%s paused: MENU can resume" % window)
		main.paused = false
		main.started = false
		var title := _shown(t)
		_check("MENU" in title and "DIG" in title and not "R" in title, "%s title: MENU and DIG, no R" % window)
		# every button, in whichever state it shows, clear of the others it
		# can show with, of the vitals card, and of the goals card
		var vitals := Rect2(16.0, 12.0, 196.0, 92.0)
		var goals: Rect2 = main.goals_card.get_global_rect()
		var ok := true
		for i in range(t.buttons.size()):
			var a: Dictionary = t.buttons[i]
			var ar := float(a.r) + 16.0
			var box := Rect2(Vector2(a.center) - Vector2(ar, ar), Vector2(ar, ar) * 2.0)
			if box.intersects(vitals) or box.intersects(goals) or not Rect2(Vector2.ZERO, vs).encloses(box.grow(-16.0)):
				ok = false
				print("  %s at %s touches a card or the edge (%s)" % [a.action, a.center, window])
			for j in range(i + 1, t.buttons.size()):
				var b: Dictionary = t.buttons[j]
				var together := String(a.when) == "always" or String(b.when) == "always" or String(a.when) == String(b.when)
				if together and Vector2(a.center).distance_to(b.center) < float(a.r) + float(b.r) + 16.0:
					ok = false
					print("  %s and %s overlap (%s)" % [a.action, b.action, window])
		_check(ok, "%s: no button overlaps another or sits on a card" % window)
	# the overloaded keyboard/pad share action gets the label that describes
	# what it does in each touch context, and is absent everywhere else
	main.started = true
	main.frozen = false
	main.tutorial_mode = true
	main.tut_step = 0
	_check("SKIP" in _shown(t) and not "SHARE" in _shown(t), "tutorial lesson shows SKIP")
	main.tutorial_mode = false
	main.finished = true
	main.frozen = true
	main.daily_share = "daily result"
	main.daily_copied = false
	var game: Node = root.get_node("Game")
	game.daily = true
	_check("SHARE" in _shown(t) and not "SKIP" in _shown(t), "daily result shows SHARE")
	# At phone width the card is nearly the whole screen. Its controls must
	# stay in the exposed margins, not cover the result they act on.
	root.size = Vector2i(844, 390)
	await process_frame
	await process_frame
	t._layout()
	main.results = {
		"title": "GOOD DOG.", "stars": 2, "rating": "good", "rows": [],
		"bones": 10, "phone": 3, "time": 60, "goal_bones": 0,
		"lines": [], "prompt": "press {restart}",
	}
	main.results_card.visible = true
	await process_frame
	await process_frame
	var result_rect: Rect2 = main.results_card.get_global_rect()
	var clear := true
	for b: Dictionary in t.buttons:
		if not t._shown(b):
			continue
		var pad := float(b.r) + 16.0
		var button_rect := Rect2(Vector2(b.center) - Vector2(pad, pad), Vector2(pad, pad) * 2.0)
		if button_rect.intersects(result_rect):
			clear = false
			print("  %s overlaps the results card" % b.label)
	_check(clear, "daily result buttons stay clear of the results card")
	game.daily = false
	main.finished = false
	# tapping the goals card presses "goals" while walking, and lets go after
	main.started = true
	main.frozen = false
	main.goals_card.visible = true
	# the card sizes itself when it draws
	await process_frame
	await process_frame
	var gc: Vector2 = main.goals_card.get_global_rect().get_center()
	_check(main.goals_card.get_global_rect().size.x > 0.0, "the goals card has a size to tap")
	_tap(t, gc, true)
	_check(Input.is_action_pressed("goals"), "tapping the goals card presses goals")
	_tap(t, gc, false)
	_check(not Input.is_action_pressed("goals"), "and letting go releases it")
	# Restart reloads the scene before the finger comes up. The outgoing
	# controls must release their synthetic press or the next R cannot become
	# just_pressed in the new scene.
	main.frozen = true
	main.process_mode = Node.PROCESS_MODE_DISABLED
	var restart_at := Vector2.ZERO
	for b: Dictionary in t.buttons:
		if String(b.label) == "R":
			restart_at = b.center
			break
	_tap(t, restart_at, true)
	_check(Input.is_action_pressed("restart"), "touch R presses restart")
	t.free()
	_check(not Input.is_action_pressed("restart"), "scene teardown releases restart for the next tap")
	_finish()


func _finish() -> void:
	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_touch_controls: OK")
		quit(0)
	else:
		quit(1)
