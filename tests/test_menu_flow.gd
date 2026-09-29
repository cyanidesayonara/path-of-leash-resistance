extends SceneTree

# The title-screen flow and every screen off it (hud/menu_flow.gd, drawn by
# hud/menu_screen.gd) on a real main scene, driven through the functions its
# input handling calls: each title step, getting ready, the wardrobe's tabs
# and cursor, settings from the title and from the pause menu, the pause
# menu's rows, the progress table and a notice card.
#
# Nothing else in CI opens these screens (headless runs skip the title), so
# this is their only automated check. It prints a MENUDUMP line per screen -
# which screen is up and what its prompt bar offers - so two builds can be
# diffed when a change is meant to leave the menus alone.

var Flow: GDScript

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


func _verbs(main: Node2D) -> Array:
	var out := []
	for it: Array in Flow.prompts(main):
		out.append(String(it[1]))
	return out


func _dump(main: Node2D, step: String) -> void:
	print("MENUDUMP %s  screen=%s  bar=%s" % [step, Flow.screen(main), ", ".join(_verbs(main))])


func _run() -> void:
	Flow = load("res://hud/menu_flow.gd")
	var game = root.get_node("Game")
	var keep := [game.vol_master, game.vol_sfx, game.vol_music, game.menu_step, game.owner_id,
		game.night, game.weather, game.collar, game.bandana, game.coat]
	var main: Node2D = load("res://main.tscn").instantiate()
	root.add_child(main)
	if not main.is_node_ready():
		await main.ready
	# headless runs start the walk straight away; put the title back up
	main.started = false
	main.frozen = true

	var names := ["title", "walk", "details"]
	for s in [0, 1, 2]:
		main.menu_step = s
		main._apply_menu_step()
		_dump(main, "menu_step_%d" % s)
		_check(Flow.screen(main) == names[s], "step %d is the %s screen" % [s, names[s]])
		_check(not main.panel.visible, "step %d: the walk HUD stays hidden on the title" % s)
		_check(not Flow.prompts(main).is_empty(), "step %d: the prompt bar offers something" % s)
	_check(_verbs(main).has("back"), "getting ready has a way back to the walk select")

	# getting ready: rows, and left/right changes the picked one
	var rows: Array = Flow.details_rows(main)
	_check(rows.size() == 3 and String(rows[0].name) == "YOUR HUMAN", "getting ready: your human, time, weather")
	main.details_idx = 0
	var who: String = game.owner_id
	Flow.details_change(main, 1)
	_check(game.owner_id != who, "left/right on YOUR HUMAN swaps who walks")
	main.details_idx = 2
	var w: String = game.weather
	Flow.details_change(main, 1)
	_check(game.weather != w, "left/right on WEATHER changes the weather")

	# the walk-select plaque
	main.menu_step = 1
	main._apply_menu_step()
	var info: Dictionary = Flow.walk_info(main)
	_check(info.has("index") and int(info.count) == game.CAROUSEL.size(), "the plaque knows where this walk sits in the list")

	main.started = true
	main._apply_menu_step()
	_dump(main, "walking")
	_check(main.panel.visible and Flow.screen(main) == "walking" and Flow.prompts(main).is_empty(),
		"once walking: the HUD is up and the prompt bar gone")
	main.started = false

	# the wardrobe: three tabs, up/down stays on a tab, left/right changes it
	main._open_shop()
	_dump(main, "shop_open")
	_check(main.in_shop and main.shop_preview.visible and Flow.screen(main) == "shop",
		"the wardrobe opens with Millie on show")
	# the preview draws its shadow through main; without it every draw errored (#33)
	_check(main.shop_preview.main == main, "the wardrobe preview dog is wired to main")
	main.shop_idx = 0
	var tab: String = Flow.shop_tab_of(main)
	for i in range(12):
		Flow.shop_step(main, 1)
	_check(Flow.shop_tab_of(main) == tab, "browsing up and down stays on one tab")
	Flow.shop_tab(main, 1)
	_check(Flow.shop_tab_of(main) != tab, "left/right moves to the next tab")
	Flow.shop_tab(main, 1)
	Flow.shop_tab(main, 1)
	_check(Flow.shop_tab_of(main) == tab, "and round to the first again")
	_check(_verbs(main).has("back"), "the wardrobe always shows the way out")
	Flow.close_shop(main)
	_check(not main.in_shop and not main.shop_preview.visible and Flow.screen(main) == "walk",
		"closing the wardrobe returns to the walk select")

	main.menu_step = 1
	main._apply_menu_step()
	main._open_settings_from_menu()
	_dump(main, "settings_from_title")
	_check(main.in_settings and main.settings_panel.visible and main.dim.visible, "settings open over a dimmed title")
	var srows: Array = main.settings_rows()
	_check(srows.size() == main.settings_keys().size(), "one settings row per setting (%d rows)" % srows.size())
	main.settings_idx = 1
	var before: float = float(srows[1].v)
	main._settings_adjust(-1)
	var after: float = float(main.settings_rows()[1].v)
	_check(is_equal_approx(after, maxf(0.0, before - 0.1)), "a slider steps down by a tenth (%.2f -> %.2f)" % [before, after])
	main._settings_adjust(1)
	main._close_settings()
	_dump(main, "settings_closed_to_title")
	_check(not main.in_settings and not main.dim.visible and Flow.screen(main) == "walk",
		"closing settings returns to the title")

	# the pause menu, and settings from it
	main.started = true
	main.frozen = false
	Flow.open_pause(main)
	_dump(main, "pause")
	_check(Flow.screen(main) == "pause" and main.frozen and main.dim.visible, "pausing opens the pause menu")
	_check(Flow.pause_rows(main).size() == Flow.PAUSE_ROWS.size(), "one pause row per action")
	main._open_settings()
	main._close_settings()
	_check(Flow.screen(main) == "pause" and main.dim.visible, "settings opened from pause close back to the pause menu")
	Flow.resume(main)
	_check(not main.paused and not main.frozen and not main.dim.visible, "resume gets back to the walk")

	# a notice card: its first line is the title, the rest the body
	Flow.show_notice(main, "TITLE LINE\n\nbody one\nbody two")
	var n: Dictionary = Flow.notice(main)
	_dump(main, "notice")
	_check(Flow.screen(main) == "notice" and String(n.title) == "TITLE LINE" and (n.body as Array).size() == 2,
		"a notice card has a title and its body")
	_check(_verbs(main).has("try again") and _verbs(main).has("walk select"),
		"a notice offers trying again and the walk select")
	main.msg_label.visible = false
	main.dim.visible = false
	main.started = false
	main.frozen = true

	var progress: Array = main._progress_rows()
	_check(progress.size() == game.LEVELS.size(), "the progress table lists every walk")
	main.menu_step = 1
	Flow.open_progress(main)
	_dump(main, "progress")
	_check(Flow.screen(main) == "progress" and main.dim.visible, "the progress table opens over a dimmed title")
	Flow.close_progress(main)

	game.vol_master = keep[0]
	game.vol_sfx = keep[1]
	game.vol_music = keep[2]
	game.menu_step = keep[3]
	game.owner_id = keep[4]
	game.night = keep[5]
	game.weather = keep[6]
	game.collar = keep[7]
	game.bandana = keep[8]
	game.coat = keep[9]
	game.save_records()

	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("MENU FLOW OK")
		quit(0)
	else:
		print("MENU FLOW FAIL")
		quit(1)
