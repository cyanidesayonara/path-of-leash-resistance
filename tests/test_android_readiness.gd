extends SceneTree

# Verifies Android-readiness pieces without requiring an Android device:
#   - UiScale.safe_insets defaults to zero off-device and applies test/CLI insets
#     onto the top-left HUD panel and top-right goals card
#   - main.on_back_request() pauses active walks and steps menus via MenuFlow
#   - main.on_app_paused(true) pauses an active mobile walk
#   - export_presets.cfg [preset.2] Android metadata & 432x432 adaptive icons exist

const UiScale := preload("res://hud/ui_scale.gd")

var Flow: GDScript
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
	Flow = load("res://hud/menu_flow.gd")
	# 1. Export preset & 432x432 adaptive icons
	var cfg := FileAccess.get_file_as_string("res://export_presets.cfg")
	_check("[preset.2]" in cfg and 'platform="Android"' in cfg, "Android export preset present")
	_check('package/unique_name="com.santtunykanen.pathofleashresistance"' in cfg, "Android package ID present")
	_check('gradle_build/target_sdk="35"' in cfg, "Android targetSdk 35 set")
	var fg := Image.load_from_file(ProjectSettings.globalize_path("res://store/android/icon_foreground.png"))
	var bg := Image.load_from_file(ProjectSettings.globalize_path("res://store/android/icon_background.png"))
	_check(fg != null and fg.get_width() == 432 and fg.get_height() == 432, "foreground adaptive icon is 432x432")
	_check(bg != null and bg.get_width() == 432 and bg.get_height() == 432, "background adaptive icon is 432x432")

	# 2. Safe-area defaults to zero headless/desktop
	UiScale.test_safe_insets = Vector4(-1.0, -1.0, -1.0, -1.0)
	_check(UiScale.safe_insets(null) == Vector4.ZERO, "safe_insets defaults to zero without overrides")

	var game := root.get_node("Game")
	game.persist = false
	game.level_id = "barri"
	var scene: PackedScene = load("res://main.tscn")
	var m: Node2D = scene.instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	m.set_process(false)
	await process_frame

	_check(not quit_on_go_back, "quit_on_go_back disabled on SceneTree")
	UiScale.apply_safe_area(m)
	_check(m.panel.position == Vector2(16.0, 12.0), "panel starts at default desktop inset")

	# 3. Simulated display cutout shifts HUD corners and touch layout cleanly
	UiScale.test_safe_insets = Vector4(48.0, 24.0, 32.0, 18.0)
	UiScale.apply_safe_area(m)
	_check(m.panel.position == Vector2(64.0, 36.0), "panel shifts by left/top safe-area inset")
	_check(is_equal_approx(m.goals_card.position.y, 32.0), "goals card shifts down by top safe-area inset")
	for child in m.hud.get_children():
		if child.has_method("_layout") and "buttons" in child:
			child._layout()
			var dig := {}
			var menu := {}
			for b: Dictionary in child.buttons:
				if String(b.get("label", "")) == "DIG":
					dig = b
				elif String(b.get("label", "")) == "MENU":
					menu = b
			_check(is_equal_approx(float(menu.center.x), child.MENU_X + 48.0), "touch MENU button respects left safe inset")
			_check(is_equal_approx(float(menu.center.y), 64.0), "touch MENU button respects top safe inset")
			var expected_dig: Vector2 = child.get_viewport_rect().size - Vector2(130.0 + 32.0, 130.0 + 18.0)
			_check(Vector2(dig.center).distance_to(expected_dig) < 0.5, "touch DIG cluster respects right/bottom safe inset")

	UiScale.test_safe_insets = Vector4(-1.0, -1.0, -1.0, -1.0)
	UiScale.apply_safe_area(m)
	_check(m.panel.position == Vector2(16.0, 12.0), "panel restores default inset after reset")

	# 4. Android back button pauses an active walk and drives menu back
	m.started = true
	m.frozen = false
	m.paused = false
	m.arriving = false
	m.on_back_request()
	_check(m.paused and Flow.screen(m) == "pause", "on_back_request pauses active walk")
	m.on_back_request()
	Flow.tick_pause(m)
	_check(not m.paused and not m.frozen, "second on_back_request resumes from pause menu")

	Flow.resume(m)
	m.on_app_paused(true)
	_check(m.paused, "on_app_paused(true) auto-pauses active walk on mobile")

	Flow.resume(m)
	m.started = false
	m.menu_step = 2
	m.on_back_request()
	_check(Flow.back_requested, "on_back_request sets MenuFlow.back_requested on menus")
	Flow.tick_title(m)
	_check(m.menu_step == 1 and not Flow.back_requested, "MenuFlow consumes back_requested and steps details -> walk")

	Flow.back_requested = false
	m.free()
	await process_frame
	if failures.is_empty():
		print("test_android_readiness: %d checks, OK" % checks)
		quit(0)
	else:
		print("test_android_readiness: %d failures" % failures.size())
		quit(1)
