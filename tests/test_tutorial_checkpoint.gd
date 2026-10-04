extends SceneTree

# The tutorial in two parts: when the bagging lesson lands, the walk stops on
# the THAT'S THE BASICS card (first real walk now, or the tricks); answering
# "the tricks" carries on and never asks again; and the last card, in the dog
# park, ends the tutorial by itself with no walk home. Nothing is saved.

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
	var sfx = root.get_node("Sfx")
	sfx.muted = true
	game.level_id = "tutorial"
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	for k in range(3):
		await physics_frame
	m._skip_title()
	var TUT: GDScript = load("res://systems/tutorial.gd")
	var Flow: GDScript = load("res://hud/menu_flow.gd")
	var bag: int = TUT.index_of("bag")
	_check(bag > 0 and bag < TUT.index_of("grind"), "bagging is among the basics, before the tricks")

	m.tut_step = bag
	m._tut_advance(true)
	_check(m.paused and m.frozen and String(m.confirm_id) == "basics", "the basics done: the walk stops on the card")
	_check(Flow.screen(m) == "confirm", "the card is the screen")
	var verbs: Array = []
	for p: Array in Flow.prompts(m):
		verbs.append(String(p[1]))
	_check("on to El Barri" in verbs and "teach me the tricks" in verbs, "it offers the first walk or the tricks")

	# the tricks: carry on, and it does not ask again
	Flow.resume(m)
	m.tut_basics_seen = true
	_check(not m.paused and not m.frozen and String(m.confirm_id) == "", "the tricks: the walk carries on")
	m.tut_step = bag
	m._tut_advance(true)
	_check(String(m.confirm_id) == "", "the card does not come back once answered")

	# the end, in the dog park: it finishes by itself
	m.tut_step = TUT.index_of("done")
	m._tick_tutorial(1.0)
	_check(not m.finished, "the last card stays up a moment")
	m._tick_tutorial(2.0)
	_check(m.finished and m.results_card.visible, "then the tutorial ends itself, no walk home")
	_check(game.tutorial_done, "and counts as done")

	m.free()
	print("test_tutorial_checkpoint: %d checks, %s" % [checks, "OK" if failures.is_empty() else "%d FAILED" % failures.size()])
	quit(1 if not failures.is_empty() else 0)
