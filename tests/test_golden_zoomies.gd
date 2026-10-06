extends SceneTree

# Golden zoomies (main.on_scored): a trick refills the zoomies, business does
# not; filling them with a trick turns them golden, and while golden tricks
# score double and the grind steadies; it wears off. And a walk keeps its
# best style as a record.

const SAVE := "user://test_golden.cfg"
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
	game.level_id = "park"
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	for k in range(3):
		await physics_frame
	m._skip_title()

	m.dog.energy = 0.5
	m.combo.add("SNIFF", 2)
	_check(is_equal_approx(m.dog.energy, 0.5), "business does not refill the zoomies")
	m.combo.add("POLE SWING", 20)
	_check(m.dog.energy > 0.5 and m.golden_t == 0.0, "a trick refills them, short of full: not golden yet")

	m.dog.energy = 0.95
	m.combo.add("FLING", 30)
	_check(m.dog.energy >= 1.0 and m.golden_t > 0.0, "filling them with a trick turns them golden")
	var p0: int = m.combo.points
	m.combo.add("WALL WALK", 20)
	_check(m.combo.points - p0 == 40, "golden: a trick scores double (got %d)" % (m.combo.points - p0))
	p0 = m.combo.points
	m.combo.add("SNIFF", 2)
	_check(m.combo.points - p0 == 2, "business does not")
	m._tick_grind(1.0 / 60.0)
	_check(m.grind.ease < 1.0, "golden steadies the grind")
	m._tick_grind(m.GOLDEN_S + 0.1)
	_check(m.golden_t == 0.0 and is_equal_approx(m.grind.ease, 1.0), "and it wears off")
	m.dog.energy = 1.0
	m.combo.add("FLING", 30)
	_check(m.golden_t == 0.0, "already full: a trick does not turn them golden again")

	# the style record
	var GameScript: GDScript = load("res://autoload/game.gd")
	var g = GameScript.new()
	g.set("save_path", SAVE)
	_check(g.record_style("park", 300), "a first style is a record")
	_check(not g.record_style("park", 200), "a lower one is not")
	_check(g.record_style("park", 450), "a higher one is")
	var g2 = GameScript.new()
	g2.set("save_path", SAVE)
	g2.load_records()
	_check(int(g2.records["park"].get("style", 0)) == 450, "the best style survives a reload")
	g.free()
	g2.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))

	m.free()
	print("test_golden_zoomies: %d checks, %s" % [checks, "OK" if failures.is_empty() else "%d FAILED" % failures.size()])
	quit(1 if not failures.is_empty() else 0)
