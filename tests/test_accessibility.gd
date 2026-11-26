extends SceneTree

# Accessibility settings regression test:
#   1. SCREEN SHAKE off => zero cam.offset even with shake_t > 0, no CamTricks tilt, no EventFeed punch
#   2. FLASHES off => no full-screen boss flash overlay, no Drac strobe, navy fallback in IntroKit.fade
#   3. TEXT SIZE large => UiScale factor steps up cleanly; settings & controls fit above prompt bar
#      across 1280x720, 844x390, and 390x844 in both normal and large
#   4. CONTROLS screen rebinding => rebind_wait_release ignores confirm key release, binds key & pad
#      actions across all 15 actions, updates InputMap and Prompts.key(), cancels cleanly on ESC, resets cleanly
#   5. Persistence => accessibility settings and rebinds survive save_records() / load_records().

var Flow: GDScript
var Kit: GDScript
var UiScale: GDScript
var EventFeed: GDScript
var CamTricks: GDScript

var checks := 0
var failures: Array[String] = []
var main: Node2D
var game: Node


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	call_deferred("_run")


func _make_key(code: Key, pressed: bool) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.physical_keycode = code
	ev.keycode = code
	ev.pressed = pressed
	return ev


func _make_pad(btn: JoyButton, pressed: bool) -> InputEventJoypadButton:
	var ev := InputEventJoypadButton.new()
	ev.button_index = btn
	ev.pressed = pressed
	return ev


func _make_axis(axis: JoyAxis, value: float) -> InputEventJoypadMotion:
	var ev := InputEventJoypadMotion.new()
	ev.axis = axis
	ev.axis_value = value
	return ev


func _run() -> void:
	Flow = load("res://hud/menu_flow.gd")
	Kit = load("res://hud/ui_kit.gd")
	UiScale = load("res://hud/ui_scale.gd")
	EventFeed = load("res://hud/event_feed.gd")
	CamTricks = load("res://systems/cam_tricks.gd")
	game = root.get_node("Game")
	var orig_persist: bool = game.persist
	var orig_save_path: String = game.save_path
	var scratch := "user://test_accessibility_scratch.cfg"
	game.persist = false
	game.save_path = scratch
	game.level_id = "barri"
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	# Start in walk state without intro blocking _process
	main.intro_playing = false
	main.film_playing = false
	main.arriving = false
	main._skip_title()

	await _test_screen_shake()
	main.set_process(false)
	await _test_flashes()
	await _test_text_size_and_layouts()
	await _test_controls_rebinding()
	await _test_persistence(scratch)

	# Cleanup
	game.screen_shake = true
	game.flashes = true
	game.text_size = "normal"
	game.clear_rebinds()
	UiScale.apply(main)
	game.save_path = orig_save_path
	game.persist = orig_persist
	var global_scratch := ProjectSettings.globalize_path(scratch)
	if FileAccess.file_exists(scratch):
		DirAccess.remove_absolute(global_scratch)
	main.free()
	await process_frame

	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_accessibility: OK")
		quit(0)
	else:
		quit(1)


func _test_screen_shake() -> void:
	game.screen_shake = false
	main.shake_t = 0.8
	main.set_process(true)
	await process_frame
	_check(main.cam.offset == Vector2.ZERO, "screen_shake off keeps cam.offset zero while shake_t > 0")

	game.screen_shake = true
	main.shake_t = 0.8
	await process_frame
	var nonzero: bool = main.cam.offset != Vector2.ZERO
	_check(nonzero, "screen_shake on moves cam.offset when shake_t > 0")

	game.screen_shake = false
	await process_frame
	_check(main.cam.offset == Vector2.ZERO, "turning screen_shake off clears cam.offset immediately")
	main.shake_t = 0.0

	# CamTricks dutch tilt triggers when screen_shake on and is suppressed/reset when off
	var dummy_boss = load("res://systems/boss_gat.gd").new()
	dummy_boss.state = 1
	dummy_boss.hp = 10.0
	dummy_boss.phase = 2
	main.boss_gat = dummy_boss
	main._boss_was_enraged = false
	main.cam_tilt_t = 0.0
	game.screen_shake = true
	CamTricks.tick(main, 0.016)
	_check(main.cam_tilt_t > 0.0, "screen_shake on enables CamTricks dutch tilt on enrage")
	game.screen_shake = false
	CamTricks.tick(main, 0.016)
	_check(main.cam_tilt_t == 0.0 and is_zero_approx(main.cam.rotation),
		"screen_shake off suppresses/resets CamTricks dutch tilt")
	main._boss_was_enraged = false
	main.boss_gat = null

	# EventFeed arrival punch suppressed when screen_shake off
	var feed: Control = EventFeed.new()
	root.add_child(feed)
	feed.lines = Array([{"text": "WOOF!", "tone": 1, "t": 0.01}], TYPE_DICTIONARY, &"", null)
	game.screen_shake = false
	var lay_off: Array[Dictionary] = feed.layout(Vector2(1280, 720))
	_check(is_equal_approx(float(lay_off[0].punch), 1.0), "screen_shake off removes EventFeed PUNCH scale")
	game.screen_shake = true
	var lay_on: Array[Dictionary] = feed.layout(Vector2(1280, 720))
	_check(float(lay_on[0].punch) > 1.05, "screen_shake on keeps EventFeed PUNCH scale")
	feed.free()


func _test_flashes() -> void:
	# BossDrac strobe flash in ENRAGE
	var Drac := load("res://systems/boss_drac.gd")
	var drac = Drac.new()
	drac.state = Drac.State.ENRAGE
	drac.flash = 0.0
	game.flashes = true
	var pose_on: Dictionary = drac._pose(0.05)
	_check(float(pose_on.get("flash", 0.0)) > 0.0, "BossDrac enrage strobes when flashes on")
	game.flashes = false
	var pose_off: Dictionary = drac._pose(0.05)
	_check(is_zero_approx(float(pose_off.get("flash", 0.0))), "BossDrac enrage has zero flash strobe when flashes off")

	# BossGat full-screen flash overlay suppressed when flashes off
	var vp := SubViewport.new()
	vp.size = Vector2i(32, 32)
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var gat = load("res://systems/boss_gat.gd").new()
	var gat_card := Control.new()
	gat_card.size = Vector2(32, 32)
	vp.add_child(gat_card)
	gat.card = gat_card
	gat.screen_flash = 0.8
	gat.card_t = 0.0
	gat_card.draw.connect(gat._draw_card)
	game.flashes = false
	gat_card.queue_redraw()
	await process_frame
	await process_frame
	var img_off := vp.get_texture().get_image()
	_check(img_off.get_pixel(16, 16).a < 0.02, "BossGat screen flash overlay is transparent when flashes off")

	game.flashes = true
	gat_card.queue_redraw()
	await process_frame
	await process_frame
	var img_on := vp.get_texture().get_image()
	_check(img_on.get_pixel(16, 16).a > 0.2, "BossGat screen flash overlay renders when flashes on")
	vp.free()

	# IntroKit.fade replaces bright white flash with dark navy when flashes off
	var fvp := SubViewport.new()
	fvp.size = Vector2i(32, 32)
	fvp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(fvp)
	var node := Node2D.new()
	fvp.add_child(node)
	node.draw.connect(func() -> void:
		IntroKit.fade(node, 1.0, Color(1.0, 0.95, 0.85))
	)
	game.flashes = false
	node.queue_redraw()
	await process_frame
	await process_frame
	var fimg := fvp.get_texture().get_image()
	var px := fimg.get_pixel(16, 16)
	_check(px.r < 0.2 and px.g < 0.2 and px.b < 0.3, "IntroKit.fade white turns dark when flashes off (%.2f, %.2f, %.2f)" % [px.r, px.g, px.b])
	fvp.free()
	game.flashes = true


func _test_text_size_and_layouts() -> void:
	_check(is_equal_approx(UiScale.factor_for(Vector2(1280, 720), "normal"), 1.0),
		"UiScale normal 1280x720 factor stays 1.0")
	var large_k: float = UiScale.factor_for(Vector2(1280, 720), "large")
	_check(large_k > 1.05, "UiScale large 1280x720 raises factor one step (%.2f)" % large_k)

	main.started = false
	main.frozen = true
	main.menu_step = 0
	main._apply_menu_step()

	for sz: Vector2i in [Vector2i(1280, 720), Vector2i(844, 390), Vector2i(390, 844)]:
		root.size = sz
		game.text_size = "normal"
		UiScale.apply(main)
		await process_frame
		await process_frame
		var k_norm := float(main.ui_scale)

		game.text_size = "large"
		UiScale.apply(main)
		await process_frame
		await process_frame
		var k_large := float(main.ui_scale)
		_check(k_large > k_norm + 0.05, "%s: text_size large raises live main.ui_scale (%.2f -> %.2f)" % [sz, k_norm, k_large])

		for ts: String in ["normal", "large"]:
			game.text_size = ts
			UiScale.apply(main)
			await process_frame
			await process_frame
			var vs: Vector2 = main.get_viewport_rect().size

			# Check Settings panel fit
			main._open_settings_from_menu()
			await process_frame
			await process_frame
			var s_top: float = Kit.prompt_bar_top(main.menu_screen, vs, Flow.prompts(main, "settings"))
			var s_rect: Rect2 = main.settings_panel.get_rect()
			_check(s_rect.position.x >= 0.0 and s_rect.end.x <= vs.x + 0.5,
				"%s (%s): settings panel fits horizontally (%.0f..%.0f / %.0f)" % [sz, ts, s_rect.position.x, s_rect.end.x, vs.x])
			_check(s_rect.position.y >= 4.0 and s_rect.end.y <= s_top + 0.5,
				"%s (%s): settings panel stays above prompt bar (%.0f <= %.0f)" % [sz, ts, s_rect.end.y, s_top])

			# Check Controls screen fit
			main._open_controls()
			await process_frame
			await process_frame
			var c_top: float = Kit.prompt_bar_top(main.menu_screen, vs, Flow.prompts(main, "controls"))
			var c_lay: Dictionary = main.menu_screen.controls_layout(vs, main, main.get_window())
			var c_rect: Rect2 = c_lay.rect
			_check(c_rect.position.x >= 0.0 and c_rect.end.x <= vs.x + 0.5,
				"%s (%s): controls panel fits horizontally (%.0f..%.0f / %.0f)" % [sz, ts, c_rect.position.x, c_rect.end.x, vs.x])
			_check(c_rect.position.y >= 4.0 and c_rect.end.y <= c_top + 0.5,
				"%s (%s): controls panel stays above prompt bar (%.0f <= %.0f)" % [sz, ts, c_rect.end.y, c_top])
			main._close_controls()
			main._close_settings()

	root.size = Vector2i(1280, 720)
	game.text_size = "normal"
	UiScale.apply(main)
	await process_frame


func _test_controls_rebinding() -> void:
	game.clear_rebinds()
	var was_style := Prompts.pad_style
	Prompts.pad_style = Prompts.PadStyle.XBOX
	main._open_settings_from_menu()
	var keys: Array = Flow.settings_keys(main)
	main.settings_idx = keys.find("controls")
	_check(Flow.screen(main) == "settings", "settings opens cleanly")

	# Left/right on CONTROLS submenu row leaves bindings untouched
	var before_keys: Dictionary = game.key_binds.duplicate(true)
	var before_pads: Dictionary = game.pad_binds.duplicate(true)
	Flow.settings_adjust(main, 1)
	Flow.settings_adjust(main, -1)
	_check(game.key_binds == before_keys and game.pad_binds == before_pads,
		"left/right on controls row leaves bindings untouched")

	Input.action_press("plant")
	main._tick_settings()
	Input.action_release("plant")
	_check(Flow.screen(main) == "controls" and main.in_controls, "plant on CONTROLS opens dedicated controls screen")

	var acts: Array[String] = game.REBIND_ACTIONS
	_check(acts.size() == 15, "all 15 input actions are registered in REBIND_ACTIONS (%d)" % acts.size())
	_check(Flow.controls_rows(main).size() == 16, "controls screen lists 15 actions + reset row")

	# Select "poop", enter listen mode, ignore stick noise, release SPACE cleanly via rebind_wait_release
	var poop_i := acts.find("poop")
	main.controls_idx = poop_i
	Input.action_press("plant")
	main._tick_controls()
	_check(game.rebind_step == poop_i and game.rebind_wait_release, "entering listen sets rebind_step & rebind_wait_release")
	Flow.rebind_input(main, _make_axis(JOY_AXIS_LEFT_X, 0.2))
	_check(game.rebind_wait_release, "stick drift does not clear rebind_wait_release")
	Flow.rebind_input(main, _make_key(KEY_SPACE, false))
	Input.action_release("plant")
	_check(not game.rebind_wait_release and not game.key_binds.has("poop"),
		"confirming key release clears rebind_wait_release without binding itself")

	# Strong stick push on a non-move action is ignored
	Flow.rebind_input(main, _make_axis(JOY_AXIS_LEFT_X, 0.8))
	_check(game.rebind_step == poop_i and not game.pad_binds.has("poop"),
		"stick push does not bind to non-movement action")

	# Press KEY_V to bind poop
	Flow.rebind_input(main, _make_key(KEY_V, true))
	_check(game.rebind_step == -1 and int(game.key_binds.get("poop", 0)) == KEY_V,
		"rebind_input binds KEY_V to poop")
	Prompts.device = Prompts.KEYS
	_check(Prompts.key("poop") == "V", "Prompts.key shows rebound key V (%s)" % Prompts.key("poop"))
	_check(InputMap.event_is_action(_make_key(KEY_V, true), "poop"), "InputMap matches KEY_V to poop")
	_check(not InputMap.event_is_action(_make_key(KEY_F, true), "poop"), "old KEY_F no longer triggers poop")

	# Rebind utility action ("goals") -> KEY_K and verify Prompts & InputMap
	var goals_i := acts.find("goals")
	main.controls_idx = goals_i
	game.rebind_step = goals_i
	game.rebind_wait_release = false
	Flow.rebind_input(main, _make_key(KEY_K, true))
	_check(Prompts.key("goals") == "K" and InputMap.event_is_action(_make_key(KEY_K, true), "goals"),
		"rebound goals key drives goals and updates Prompts.key")

	# Rebind movement ("move_up") -> KEY_U and check derived token
	var up_i := acts.find("move_up")
	game.rebind_step = up_i
	game.rebind_wait_release = false
	Flow.rebind_input(main, _make_key(KEY_U, true))
	_check(Prompts.key("move_up") == "U" and Prompts.key("up_down").begins_with("U /")
		and InputMap.event_is_action(_make_key(KEY_U, true), "move_up"),
		"rebound move_up updates Prompts and InputMap")

	# Rebind gamepad button for pickup -> JOY_BUTTON_Y
	var pick_i := acts.find("pickup")
	game.rebind_step = pick_i
	game.rebind_wait_release = false
	Flow.rebind_input(main, _make_pad(JOY_BUTTON_Y, true))
	Prompts.device = Prompts.PAD
	_check(Prompts.key("pickup") == "Y", "rebound pickup pad updates Prompts (%s)" % Prompts.key("pickup"))

	# Rebind gamepad trigger axis for pickup -> JOY_AXIS_TRIGGER_LEFT
	game.rebind_step = pick_i
	game.rebind_wait_release = false
	Flow.rebind_input(main, _make_axis(JOY_AXIS_TRIGGER_LEFT, 0.85))
	_check(game.rebind_step == -1 and game.pad_binds.get("pickup") is Dictionary
		and int((game.pad_binds["pickup"] as Dictionary).get("axis", -1)) == JOY_AXIS_TRIGGER_LEFT
		and Prompts.key("pickup") == "LT"
		and InputMap.event_is_action(_make_axis(JOY_AXIS_TRIGGER_LEFT, 0.85), "pickup"),
		"rebind_input binds analog trigger to pickup and updates Prompts & InputMap")

	# JOY_BUTTON_START can be bound (not treated as cancel); JOY_BUTTON_BACK cancels
	var bark_i := acts.find("bark")
	game.rebind_step = bark_i
	game.rebind_wait_release = false
	Flow.rebind_input(main, _make_pad(JOY_BUTTON_START, true))
	_check(game.rebind_step == -1 and int(game.pad_binds.get("bark", -1)) == JOY_BUTTON_START,
		"Start button binds instead of cancelling")
	game.rebind_step = bark_i
	game.rebind_wait_release = false
	Flow.rebind_input(main, _make_pad(JOY_BUTTON_BACK, true))
	_check(game.rebind_step == -1 and int(game.pad_binds.get("bark", -1)) == JOY_BUTTON_START and Flow.screen(main) == "controls",
		"Back button cancels listening cleanly without exiting controls")
	Prompts.device = Prompts.KEYS

	# Listening + ESC cancels listening cleanly without leaving controls screen
	game.rebind_step = poop_i
	game.rebind_wait_release = false
	Flow.rebind_input(main, _make_key(KEY_ESCAPE, true))
	main._tick_controls()  # must not bounce back to settings on same frame
	_check(game.rebind_step == -1 and Flow.screen(main) == "controls",
		"ESC cancels listening without exiting controls screen")

	# Reset to defaults row clears rebinds and restores prompts & InputMap
	main.controls_idx = acts.size()
	await process_frame
	Input.action_press("plant")
	main._tick_controls()
	Input.action_release("plant")
	Prompts.device = Prompts.PAD
	_check(Prompts.key("turbo") == "RT", "reset restores RT trigger prompt for turbo")
	Prompts.device = Prompts.KEYS
	_check(game.key_binds.is_empty() and game.pad_binds.is_empty() and Prompts.key("poop") == "F"
		and Prompts.key("goals") == "TAB" and Prompts.key("move_up") == "W",
		"reset row clears all rebinds and restores defaults")
	Prompts.pad_style = was_style

	main._close_controls()
	_check(Flow.screen(main) == "settings" and main.in_settings, "closing controls returns to settings")
	main._close_settings()


func _test_persistence(scratch: String) -> void:
	game.persist = true
	game.save_path = scratch
	game.screen_shake = false
	game.flashes = false
	game.text_size = "large"
	game.bind_key("poop", KEY_V)
	game.bind_key("goals", KEY_K)
	game.bind_pad("pickup", JOY_BUTTON_Y)
	game.bind_pad_axis("turbo", JOY_AXIS_TRIGGER_LEFT, 1)
	game.save_records()

	# Clobber in-memory state cleanly before reload
	game.screen_shake = true
	game.flashes = true
	game.text_size = "normal"
	game.key_binds = {}
	game.pad_binds = {}
	game.apply_control_layout()
	game.load_records()

	_check(not game.screen_shake, "screen_shake persists false across save/load")
	_check(not game.flashes, "flashes persists false across save/load")
	_check(game.text_size == "large", "text_size persists large across save/load")
	_check(int(game.key_binds.get("poop", 0)) == KEY_V and int(game.key_binds.get("goals", 0)) == KEY_K,
		"key_binds survive save/load")
	_check(int(game.pad_binds.get("pickup", -1)) == JOY_BUTTON_Y, "pad_binds button survives save/load")
	var tb: Variant = game.pad_binds.get("turbo")
	_check(tb is Dictionary and int((tb as Dictionary).get("axis", -1)) == JOY_AXIS_TRIGGER_LEFT,
		"pad_binds trigger axis survives save/load")
	Prompts.device = Prompts.KEYS
	_check(Prompts.key("poop") == "V" and Prompts.key("goals") == "K",
		"Prompts reflect loaded key binds after load_records()")
	_check(InputMap.event_is_action(_make_key(KEY_V, true), "poop")
		and InputMap.event_is_action(_make_key(KEY_K, true), "goals")
		and InputMap.event_is_action(_make_axis(JOY_AXIS_TRIGGER_LEFT, 0.85), "turbo"),
		"InputMap reflects loaded key and trigger binds after load_records()")

	var roundtrip: Array = Flow.check_settings_roundtrip(main)
	_check(roundtrip.is_empty(), "MenuFlow.check_settings_roundtrip passes: %s" % str(roundtrip))
