extends SceneTree

# First-time tips (systems/tips.gd): a tip takes the banner once and never
# again, clears itself, is remembered across a save reload, and never shows in
# the tutorial or for the autowalk. Every tip names keys only through tokens.

const SAVE := "user://test_tips.cfg"
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
	var game = root.get_node("Game")
	game.persist = false
	game.tips_seen.clear()
	root.get_node("Sfx").muted = true
	game.level_id = "barri"
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	for k in range(3):
		await physics_frame
	m._skip_title()
	var T: GDScript = load("res://systems/tips.gd")
	_check(not T.show(m, "teeter"), "no tips in a headless run")
	T.force_headless = true

	for id: String in T.TEXT:
		var raw := String(T.TEXT[id])
		_check(raw == raw.to_upper() or raw.contains("{"), "tip '%s' is a banner: capitals" % id)
	_check(T.show(m, "teeter"), "a new tip shows")
	_check(m.tip_t > 0.0 and m.feed.banner_text() == m.tip_text if m.feed.has_method("banner_text") else m.tip_t > 0.0,
		"it takes the banner")
	_check(not T.show(m, "teeter"), "the same tip never shows twice")
	T.tick(m, T.SHOW_S + 0.1)
	_check(m.tip_t <= 0.0 and m.tip_text == "", "it clears itself after a few seconds")

	m.auto_walk = true
	_check(not T.show(m, "crack"), "no tips for the autowalk")
	m.auto_walk = false
	m.tutorial_mode = true
	_check(not T.show(m, "crack"), "no tips in the tutorial")
	m.tutorial_mode = false

	# remembered across a reload
	var GameScript: GDScript = load("res://autoload/game.gd")
	var g = GameScript.new()
	g.set("save_path", SAVE)
	g.tips_seen.assign(["teeter", "crack"])
	g.save_records()
	var g2 = GameScript.new()
	g2.set("save_path", SAVE)
	g2.load_records()
	_check(g2.tips_seen.has("teeter") and g2.tips_seen.has("crack"), "seen tips survive a reload")
	g.free()
	g2.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))

	m.free()
	print("test_tips: %d checks, %s" % [checks, "OK" if failures.is_empty() else "%d FAILED" % failures.size()])
	quit(1 if not failures.is_empty() else 0)
