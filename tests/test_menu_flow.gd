extends SceneTree

# The title-screen flow, wardrobe and settings screens (hud/menu_flow.gd) on a
# real main scene, driven through main's own methods the way its input
# handling calls them: each menu step, opening the wardrobe and moving the
# cursor, opening settings from the title and from a paused walk, nudging a
# slider, and the progress screen.
#
# Nothing else in CI opens these screens (headless runs skip the title), so
# this is their only automated check. It also prints a MENUDUMP line after
# every step - which labels are visible and what they say - so two builds can
# be diffed when a change is meant to leave the menus alone.

const LABELS := ["title_l", "sub_l", "select_l", "record_l", "owner_l", "night_l",
	"weather_l", "prompt_l", "menu_hint_l", "hint_l", "pause_l", "shop_title_l",
	"shop_preview_l", "shop_l"]
const NODES := ["panel", "goals_card", "dim", "settings_panel", "shop_preview_bg"]

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


func _dump(main: Node2D, step: String) -> void:
	var parts: Array[String] = []
	for n: String in LABELS:
		var l: Label = main.get(n)
		parts.append("%s=%s:%s" % [n, "on" if l.visible else "off",
			l.text.replace("\n", "|") if l.visible else ""])
	for n: String in NODES:
		var c: CanvasItem = main.get(n)
		parts.append("%s=%s" % [n, "on" if c.visible else "off"])
	print("MENUDUMP %s  %s" % [step, "  ".join(parts)])


func _run() -> void:
	var game = root.get_node("Game")
	var keep := [game.vol_master, game.vol_sfx, game.vol_music, game.menu_step]
	var main: Node2D = load("res://main.tscn").instantiate()
	root.add_child(main)
	if not main.is_node_ready():
		await main.ready
	# headless runs start the walk straight away; put the title back up
	main.started = false
	main.frozen = true

	for s in [0, 1, 2]:
		main.menu_step = s
		main._apply_menu_step()
		_dump(main, "menu_step_%d" % s)
		_check(main.prompt_l.visible, "step %d: the prompt is shown" % s)
		_check(not main.panel.visible, "step %d: the walk HUD stays hidden on the title" % s)
		_check(main.record_l.visible == (s == 1), "step %d: the record line only on walk select" % s)
		_check(main.owner_l.visible == (s == 2), "step %d: the owner line only on the last step" % s)
	_check(String(main.owner_l.text).begins_with("WALKING:"), "the owner line names who is walking")

	main.started = true
	main._apply_menu_step()
	_dump(main, "walking")
	_check(main.panel.visible and not main.prompt_l.visible, "once walking: the HUD is up and the prompt gone")
	main.started = false

	main._open_shop()
	_dump(main, "shop_open")
	_check(main.in_shop and main.shop_l.visible and main.shop_preview.visible, "the wardrobe opens with its list and preview")
	_check(String(main.shop_l.text).contains(">  "), "the wardrobe shows a cursor")
	# the preview draws its shadow through main; without it every draw errored (#33)
	_check(main.shop_preview.main == main, "the wardrobe preview dog is wired to main")
	main.shop_idx = 1
	main._refresh_shop()
	_dump(main, "shop_cursor_1")
	main.in_shop = false

	main.menu_step = 1
	main._apply_menu_step()
	main._open_settings_from_menu()
	_dump(main, "settings_from_title")
	_check(main.in_settings and main.settings_panel.visible and main.dim.visible, "settings open over a dimmed title")
	var rows: Array = main.settings_rows()
	_check(rows.size() == main.settings_keys().size(), "one settings row per setting (%d rows)" % rows.size())
	main.settings_idx = 1
	var before: float = float(rows[1].v)
	main._settings_adjust(-1)
	var after: float = float(main.settings_rows()[1].v)
	_check(is_equal_approx(after, maxf(0.0, before - 0.1)), "a slider steps down by a tenth (%.2f -> %.2f)" % [before, after])
	main._settings_adjust(1)
	main._close_settings()
	_dump(main, "settings_closed_to_title")
	_check(not main.in_settings and not main.dim.visible and main.prompt_l.visible, "closing settings returns to the title")

	main.paused = true
	main._open_settings()
	main._close_settings()
	_dump(main, "settings_closed_to_pause")
	_check(main.pause_l.visible and main.dim.visible, "settings opened from pause close back to the pause screen")
	main.paused = false

	var progress: String = main._progress_text()
	print("MENUDUMP progress  %s" % progress.replace("\n", "|"))
	_check(progress.begins_with("YOUR WALKS"), "the progress screen lists the walks")

	game.vol_master = keep[0]
	game.vol_sfx = keep[1]
	game.vol_music = keep[2]
	game.menu_step = keep[3]
	game.save_records()

	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("MENU FLOW OK")
		quit(0)
	else:
		print("MENU FLOW FAIL")
		quit(1)
