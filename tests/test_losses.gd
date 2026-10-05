extends SceneTree

# The card a lost walk ends on (systems/losses.gd): the joke, then how to
# avoid that loss next time, then the new goals the walk kept. The first loss
# ever adds a word of comfort, and only the first. The count is saved.

const SAVE := "user://test_losses.cfg"
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
	root.get_node("Sfx").muted = true
	game.level_id = "street"
	game.walks_lost = 0
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	for k in range(3):
		await physics_frame
	m._skip_title()
	var L: GDScript = load("res://systems/losses.gd")
	var Flow: GDScript = load("res://hud/menu_flow.gd")

	# every hint is a plain sentence that fits the card
	for cause: String in L.HINT:
		for line: String in String(L.HINT[cause]).split("\n"):
			_check(line.length() <= 64, "hint '%s' fits the card (%d chars)" % [cause, line.length()])
		_check(not String(L.HINT[cause]).contains("{"), "hint '%s' names no key" % cause)

	# the first loss: the joke, the hint, the comfort
	m.phone_hp = 1
	m.crack_phone(m.human.global_position)
	_check(m.frozen and m.msg_label.visible, "a smashed phone ends the walk on the card")
	var n: Dictionary = Flow.notice(m)
	_check(String(n.title) == "PHONE SMASHED", "the card keeps its title")
	var body := "\n".join(n.body)
	_check(body.contains("Bikes knock your human over"), "it says how to avoid it next time")
	_check(body.contains(L.COMFORT), "the first loss ever gets a word of comfort")
	_check(not body.contains("new goal"), "no goals line when the walk ticked none")
	_check(game.walks_lost == 1, "the loss is counted")
	var verbs: Array = []
	for p: Array in Flow.prompts(m):
		verbs.append(String(p[1]))
	_check("try again" in verbs, "try again is one press away")

	# a later loss, after ticking goals: no comfort, the goals counted
	m.run_goals_new = 2
	var t: String = L.card(m, "THE HUMAN WENT DOWN THE MANHOLE\n\nThe walk does not.", "manhole")
	_check(t.contains("Steer your human round open manholes"), "the manhole has its own hint")
	_check(t.contains("This walk ticked 2 new goals. They stay ticked."), "the new goals are counted")
	_check(not t.contains(L.COMFORT), "the comfort is for the first loss only")
	m.run_goals_new = 1
	_check(L.card(m, "X", "").contains("This walk ticked a new goal. It stays ticked."), "one goal reads as one")
	_check(not L.card(m, "X\n\nY", "").contains("\n\n\n"), "a loss with no hint has no gap for one")

	# remembered across a reload
	var GameScript: GDScript = load("res://autoload/game.gd")
	var g = GameScript.new()
	g.set("save_path", SAVE)
	g.walks_lost = 3
	g.save_records()
	var g2 = GameScript.new()
	g2.set("save_path", SAVE)
	g2.load_records()
	_check(g2.walks_lost == 3, "the count survives a reload")
	g.free()
	g2.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))

	m.free()
	print("test_losses: %d checks, %s" % [checks, "OK" if failures.is_empty() else "%d FAILED" % failures.size()])
	quit(1 if not failures.is_empty() else 0)
