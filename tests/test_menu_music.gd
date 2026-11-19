extends SceneTree

# The menus have a tune of their own (audio/music.gd "menu"): the main menu and
# the screens it opens play it, the walk select and GET READY play the shown
# walk's tune, and the intro film hands over to it.

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
	var Music: GDScript = load("res://audio/music.gd")
	var Flow: GDScript = load("res://hud/menu_flow.gd")
	var st: Dictionary = Music.STYLES.get("menu", {})
	_check(not st.is_empty(), "the menus have a style of their own")
	_check(st.has("mel") and st.has("chords"), "with its own melody and chords, not the walks' tune")
	_check((st.chords as Array).size() == 16, "sixteen bars of chords")

	var game: Node = root.get_node("Game")
	game.level_id = "park"
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	# headless runs start the walk straight away; put the title back up
	m.started = false
	m.menu_step = 0
	game.menu_step = 0
	m._apply_menu_step()
	_check(m._music_cue() == "menu", "the main menu plays the menus' tune (%s)" % m._music_cue())
	_check(m._music_next() == Music.walk_style(m.lvl), "with the shown walk's tune made ready")
	m.menu_step = 1
	game.menu_step = 1
	m._apply_menu_step()
	_check(m._music_cue() == Music.walk_style(m.lvl), "the walk select plays the shown walk's tune (%s)" % m._music_cue())
	_check(m._music_next() == "menu", "with the menus' tune made ready")
	m.menu_step = 2
	game.menu_step = 2
	m._apply_menu_step()
	_check(m._music_cue() == Music.walk_style(m.lvl), "and so does GET READY")
	m.menu_step = 1
	game.menu_step = 1
	m._apply_menu_step()
	Flow.open_shop(m)
	_check(m._music_cue() == "menu", "the wardrobe plays the menus' tune, from the walk select too")
	Flow.close_shop(m)
	_check(m._music_cue() == Music.walk_style(m.lvl), "closed, the walk's tune again")
	m.intro_playing = true
	_check(m._music_next() == "menu", "the intro makes the menus' tune ready for its handoff")
	m.intro_playing = false

	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("OK")
	quit(0 if failures.is_empty() else 1)
