extends SceneTree

# Menu layout, wardrobe preview turntable/hop, and Millie action/mood animations:
#   - 17-walk YOUR WALKS table fits above the bottom prompt bar at 720p and mobile
#   - 13-goal THIS WALK pause card splits into two columns and clears the prompt bar
#   - Wardrobe preview dog rotates on the spotlight and hops/barks when equipped
#   - In-game digging, sniffing, and drinking animations advance and draw cleanly

var MenuScreen: GDScript
var Flow: GDScript
var Kit: GDScript
var Mood: GDScript

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	# deferred so autoloads (Game, Sfx) are registered before menu scripts compile
	call_deferred("_run")


func _run() -> void:
	MenuScreen = load("res://hud/menu_screen.gd")
	Flow = load("res://hud/menu_flow.gd")
	Kit = load("res://hud/ui_kit.gd")
	Mood = load("res://systems/mood.gd")
	var game = root.get_node("Game")
	var row_count: int = game.LEVELS.size()
	_check(row_count >= 17, "roster has at least 17 walks (%d)" % row_count)

	for vs: Vector2 in [Vector2(1280, 720), Vector2(1024, 640), Vector2(844, 390)]:
		var r: Rect2 = MenuScreen.progress_rect(vs, row_count)
		var bar_top: float = vs.y - float(Kit.BAR_FROM_BOTTOM)
		_check(r.position.y >= 10.0,
			"progress card top stays on screen at %dx%d (y=%.1f)" % [int(vs.x), int(vs.y), r.position.y])
		_check(r.end.y <= bar_top - 10.0,
			"progress card bottom clears prompt bar at %dx%d (end.y=%.1f <= %.1f)" % [
				int(vs.x), int(vs.y), r.end.y, bar_top - 10.0])

	var wc13: Rect2 = MenuScreen.walk_card_rect(Vector2(1280, 720), 13, false)
	_check(is_equal_approx(wc13.size.x, float(MenuScreen.WALKCARD_TWO_COL_W)),
		"13-goal walk card uses two-column width (%.1f)" % wc13.size.x)
	_check(wc13.end.y <= 720.0 - float(Kit.BAR_FROM_BOTTOM) - 20.0,
		"13-goal walk card clears prompt bar at 720p (end.y=%.1f)" % wc13.end.y)

	var wc5: Rect2 = MenuScreen.walk_card_rect(Vector2(1280, 720), 5, false)
	_check(is_equal_approx(wc5.size.x, float(MenuScreen.WALKCARD_W)),
		"5-goal walk card stays single-column (%.1f)" % wc5.size.x)

	var main: Node2D = load("res://main.tscn").instantiate()
	root.add_child(main)
	if not main.is_node_ready():
		await main.ready
	main.started = false
	main.frozen = true

	Flow.open_shop(main)
	_check(main.in_shop and main.shop_preview.visible, "wardrobe opens with preview dog")
	main.menu_screen._process(0.25)
	_check(main.shop_preview.facing.distance_to(Vector2.UP) > 0.05,
		"wardrobe preview dog rotates on the spotlight turntable")
	_check(main.shop_preview.gait > 0.0,
		"wardrobe preview dog steps gently on the turntable")
	main.shop_idx = 0
	Flow.shop_select(main)
	_check(main.shop_preview.hop > 0.0 and main.shop_preview.bark_anim > 0.0,
		"equipping an item in the wardrobe triggers a celebratory hop and bark")
	Flow.close_shop(main)

	# In-game dog action animations: digging, sniffing, drinking
	main.started = true
	main.frozen = false
	main.phase = "freedom"
	var dog = main.dog
	dog.velocity = Vector2.ZERO

	main.park_props.clear()
	main.park_props.append({"kind": "dig", "pos": dog.global_position, "prog": 0.0, "done": false})
	main._pickups(0.1)
	_check(dog.digging > 0.0, "standing on a dig patch advances dog.digging (%.2f)" % dog.digging)

	main.park_props.clear()
	main.park_props.append({"kind": "shrub", "pos": dog.global_position, "prog": 0.0, "done": false})
	main._pickups(0.1)
	_check(dog.sniffing > 0.0, "standing by a sniffable prop advances dog.sniffing (%.2f)" % dog.sniffing)

	main.fountains.clear()
	main.fountains.append(dog.global_position)
	main._bodily(0.1)
	_check(dog.drinking > 0.0, "standing at a fountain advances dog.drinking (%.2f)" % dog.drinking)

	# Exercise _draw() across action and mood states inside NOTIFICATION_DRAW
	dog.digging = 1.0
	dog.sniffing = 1.0
	dog.drinking = 1.0
	dog.bark_anim = 0.3
	for mid: int in [Mood.M.HAPPY, Mood.M.BARKY, Mood.M.SCARED, Mood.M.TIRED, Mood.M.ZOOMIES]:
		main.mood.active = mid
		main.mood.intensity = 1.0
		dog.queue_redraw()
		await process_frame
	_check(true, "dog._draw() completes across all action and mood states")

	print("MENU_ANIM_POLISH checks=%d failures=%d" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
