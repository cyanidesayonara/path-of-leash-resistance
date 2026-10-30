extends SceneTree

# Small screens (hud/ui_scale.gd): the interface is enlarged only below the
# threshold frame scale, never past the cap, and an enlarged interface opens
# a shorter goal list. Headless runs never touch the window.

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
	var U: GDScript = load("res://hud/ui_scale.gd")
	_check(is_equal_approx(U.factor_for(Vector2(1280, 720)), 1.0), "the reference frame is left alone")
	_check(is_equal_approx(U.factor_for(Vector2(1920, 1080)), 1.0), "a big screen is left alone")
	_check(is_equal_approx(U.factor_for(Vector2(1024, 576)), 1.0), "a smallish window at 0.8 is left alone")
	var phone: float = U.factor_for(Vector2(844, 390))
	_check(phone > 1.3 and phone <= U.MAX_FACTOR, "a sideways phone gets a bigger interface (%.2f)" % phone)
	_check(is_equal_approx(U.factor_for(Vector2(390, 844)), U.MAX_FACTOR), "never more than the cap")
	var mid: float = U.factor_for(Vector2(900, 506))
	_check(mid > 1.0 and mid < phone, "the smaller the screen, the bigger the factor (%.2f)" % mid)

	var game = root.get_node("Game")
	var was_records: Dictionary = game.records.duplicate(true)
	game.persist = false
	game.records = {}
	root.get_node("Sfx").muted = true
	game.level_id = "barri"
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	for k in range(3):
		await physics_frame
	_check(is_equal_approx(m.ui_scale, 1.0) and is_equal_approx(m.get_window().content_scale_factor, 1.0),
		"a headless run never scales the window")
	_check(is_equal_approx(m.cam.zoom.x, m.CAM_ZOOM), "and keeps the camera's zoom")
	var was: bool = game.goals_expanded
	var G: GDScript = load("res://systems/goals.gd")
	# a peek keeps the list short, and shorter still on an enlarged interface
	game.goals_expanded = false
	m.goals_peek = 3.0
	var full: int = (G.card_data(m).rows as Array).size()
	m.ui_scale = 1.4
	var small: int = (G.card_data(m).rows as Array).size()
	_check(full > G.GOALS_ROWS_SMALL and small == G.GOALS_ROWS_SMALL,
		"an enlarged interface peeks a shorter goal list (%d, then %d)" % [full, small])
	# opened on purpose, every goal is listed, whatever the scale
	game.goals_expanded = true
	m.goals_peek = 0.0
	var opened: Dictionary = G.card_data(m)
	_check((opened.rows as Array).size() == m.active_quests.size() and int(opened.extra) == 0,
		"the opened list shows all %d goals (%d)" % [m.active_quests.size(), (opened.rows as Array).size()])
	# the goals that count up come first, as a group
	var seen_single := false
	var grouped := true
	for r: Dictionary in opened.rows:
		if int(r.target) > 1 and seen_single:
			grouped = false
		elif int(r.target) <= 1:
			seen_single = true
	_check(grouped, "the counting goals are listed first")
	m.ui_scale = 1.0
	game.goals_expanded = was
	game.records = was_records

	m.free()
	print("test_ui_scale: %d checks, %s" % [checks, "OK" if failures.is_empty() else "%d FAILED" % failures.size()])
	quit(1 if not failures.is_empty() else 0)
