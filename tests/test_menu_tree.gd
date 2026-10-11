extends SceneTree

# The whole menu tree, driven the way a player drives it: real presses of the
# input actions, routed as main._process routes them (settings first, then
# the pause menu, then the title's screens). From the main menu every screen
# is reached with up/down and the plant action, and every one leads back to
# the main menu with BACK alone - the bark action, and the pause action too.
# EXIT GAME is on the main menu on desktop, never under --no-exit or on the
# web; it always asks first, and quit_hook fires only after the yes.
#
# main._process is switched off for the run, so each press is handled once,
# here; menus that would reload the scene call reload_hook instead.

var Flow: GDScript

var checks := 0
var failures: Array[String] = []
var main: Node2D
var quits := 0
var reloads := 0


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	call_deferred("_run")


# One press of one action, handled by whichever screen is up, then let go.
func _press(action: String) -> void:
	Input.action_press(action)
	if main.in_settings:
		main._tick_settings()
	elif main.started and main.paused:
		Flow.tick_pause(main)
	elif main.started and main.frozen:
		Flow.tick_end(main)
	elif not main.started:
		Flow.tick_title(main)
	Input.action_release(action)
	await process_frame


func _screen() -> String:
	return Flow.screen(main)


# Move the main menu's cursor to a row with presses, and pick it.
func _pick_main(id: String) -> void:
	var ids: Array = Flow.main_ids(main)
	var guard := 0
	while String(ids[main.main_idx]) != id and guard < 20:
		await _press("move_down")
		guard += 1
	_check(String(ids[main.main_idx]) == id, "down reaches %s on the main menu" % id)
	await _press("plant")


func _to_main(back: String) -> void:
	var guard := 0
	while _screen() != "title" and guard < 6:
		await _press(back)
		guard += 1


func _run() -> void:
	Flow = load("res://hud/menu_flow.gd")
	var game = root.get_node("Game")
	var keep := [game.menu_step, game.level_id, game.ask_tutorial, game.tutorial_done, game.quick_start]
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	if not main.is_node_ready():
		await main.ready
	main.set_process(false)
	# a press in the frame the scene came up in is not seen as just pressed
	await process_frame
	await process_frame
	main.started = false
	main.frozen = true
	main.menu_step = 0
	main.main_idx = 0
	main._apply_menu_step()
	Flow.quit_hook = func() -> void: quits += 1
	Flow.reload_hook = func() -> void: reloads += 1
	Flow.exit_hidden = false
	game.ask_tutorial = false
	game.tutorial_done = true
	# the first walk is always open, so the walk select's plant gets ready
	game.level_id = "barri"

	_check(_screen() == "title", "the game opens on the main menu")
	# up and down wrap round the list
	await _press("move_up")
	_check(main.main_idx == Flow.main_ids(main).size() - 1, "up from the top lands on the last row")
	await _press("move_down")
	_check(main.main_idx == 0, "down from the last row wraps to the top")

	for back in ["bark", "pause"]:
		# PLAY -> walk select -> getting ready, and BACK all the way out
		main.main_idx = 0
		await _pick_main("play")
		_check(_screen() == "walk", "PLAY opens the walk select")
		await _press("plant")
		_check(_screen() == "details", "plant on the walk select gets ready")
		await _press(back)
		_check(_screen() == "walk", "%s on getting ready returns to the walk select" % back)
		# the wardrobe from the walk select closes back to the walk select
		await _press("pee")
		_check(_screen() == "shop", "the walk select opens the wardrobe")
		await _press(back)
		_check(_screen() == "walk", "%s closes the wardrobe to the walk select" % back)
		await _press(back)
		_check(_screen() == "title", "%s on the walk select returns to the main menu" % back)
		# the screens off the main menu close back to it
		for row: Array in [["shop", "shop"], ["progress", "progress"], ["settings", "settings"]]:
			main.main_idx = 0
			await _pick_main(String(row[0]))
			_check(_screen() == String(row[1]), "%s opens from the main menu" % row[0])
			# confirm never closes a screen (in the wardrobe it would buy)
			if String(row[0]) != "shop":
				await _press("plant")
				_check(_screen() == String(row[1]), "plant does not close %s" % row[0])
			await _to_main(back)
			_check(_screen() == "title" and main.menu_step == 0,
				"%s on %s returns to the main menu" % [back, row[0]])
		# BACK on the main menu asks to quit, and BACK again cancels
		await _press(back)
		_check(_screen() == "confirm" and main.confirm_id == "exit" and quits == 0,
			"%s on the main menu asks EXIT GAME" % back)
		await _press(back)
		_check(_screen() == "title" and quits == 0, "%s cancels the question" % back)

	# EXIT GAME on the list asks first; quit_hook fires only after yes
	main.main_idx = 0
	await _pick_main("exit")
	_check(_screen() == "confirm" and quits == 0, "EXIT GAME asks before quitting")
	await _press("plant")
	_check(quits == 1, "yes quits, once")
	main.confirm_id = ""

	# TUTORIAL starts the tutorial walk
	main.main_idx = 0
	reloads = 0
	await _pick_main("tutorial")
	_check(reloads == 1 and game.level_id == "tutorial" and game.quick_start, "TUTORIAL starts the tutorial walk")
	game.level_id = "barri"
	game.quick_start = false

	# a new player's PLAY asks first; BACK returns to the main menu, and the
	# two answers are the tutorial and the walk select
	game.ask_tutorial = true
	game.tutorial_done = false
	main.main_idx = 0
	await _pick_main("play")
	_check(_screen() == "confirm" and main.confirm_id == "first", "a new player's PLAY asks the first-time question")
	_check(main.first_idx == 0, "the tutorial is the first answer")
	await _press("bark")
	_check(_screen() == "title", "BACK on the first-time question returns to the main menu")
	await _pick_main("play")
	await _press("move_down")
	_check(main.first_idx == 1, "down picks the second answer")
	await _press("pee")
	_check(not game.ask_tutorial, "pee ticks don't ask again")
	await _press("pee")
	_check(game.ask_tutorial, "and unticks it")
	await _press("plant")
	_check(_screen() == "walk", "straight to the walks opens the walk select")
	await _press("bark")
	await _pick_main("play")
	reloads = 0
	await _press("plant")
	_check(reloads == 1 and game.level_id == "tutorial", "learn the ropes starts the tutorial")
	game.level_id = "barri"
	game.quick_start = false
	main.confirm_id = ""
	game.ask_tutorial = false
	game.tutorial_done = true

	# no EXIT GAME where the game cannot quit, and BACK on the main menu
	# does nothing there
	Flow.exit_hidden = true
	_check(not Flow.main_ids(main).has("exit"), "no EXIT GAME row under --no-exit or on the web")
	main.main_idx = 0
	await _press("bark")
	await _press("pause")
	_check(_screen() == "title" and quits == 1, "BACK on the web's main menu stays put")
	Flow.exit_hidden = false

	# the pause menu: BACK resumes, from the grid and from its cards
	main.started = true
	main.frozen = false
	for back in ["bark", "pause"]:
		Flow.open_pause(main)
		await _press(back)
		_check(not main.paused and _screen() == "walking", "%s resumes from the pause menu" % back)
		Flow.open_pause(main)
		main.pause_idx = Flow.pause_ids(main).find("walk")
		await _press("plant")
		_check(_screen() == "walkcard", "THIS WALK opens its card")
		await _press("plant")
		_check(_screen() == "walkcard", "plant does not close the card")
		await _press(back)
		_check(_screen() == "pause", "%s closes the card to the pause grid" % back)
		main.pause_idx = Flow.pause_ids(main).find("settings")
		await _press("plant")
		_check(_screen() == "settings", "SETTINGS opens from the pause grid")
		await _press(back)
		_check(_screen() == "pause", "%s closes settings to the pause grid" % back)
		main.pause_idx = Flow.pause_ids(main).find("exit")
		await _press("plant")
		await _press(back)
		_check(_screen() == "pause" and quits == 1, "%s cancels EXIT GAME in the pause menu" % back)
		await _press(back)
		_check(_screen() == "walking", "and %s again resumes" % back)

	Flow.quit_hook = Callable()
	Flow.reload_hook = Callable()
	game.menu_step = keep[0]
	game.level_id = keep[1]
	game.ask_tutorial = keep[2]
	game.tutorial_done = keep[3]
	game.quick_start = keep[4]
	game.save_records()

	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("MENU TREE OK")
		quit(0)
	else:
		print("MENU TREE FAIL")
		quit(1)
