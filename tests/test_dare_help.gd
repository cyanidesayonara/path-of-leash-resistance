extends SceneTree

# A dare tells her what to do and gives her the means to do it:
#  1. the clock starting fills her zoomies, and turbo burns none of them
#     while the dare is live; once it is over they drain again
#  2. while the dare is up, the real poles near her are ringed
#     (entities/dare_marks.gd), and a pole she has just swung round is not
#  3. the live card's hint says what just counted, and otherwise what to try,
#     with its key tokens filled

const DT := 1.0 / 60.0

var checks := 0
var failures: Array[String] = []
var m: Node2D
var g: Node2D


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.get_node("Game").persist = false
	root.get_node("Game").level_id = "park"
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	m.set_process(false)
	m.set_physics_process(false)
	m.started = true
	m.frozen = false
	m.phase = "out"
	g = get_nodes_in_group("challengers")[0]
	g.set_physics_process(false)
	var marks: Node2D = null
	for c in g.get_children():
		if c.has_method("showing"):
			marks = c
	_check(marks != null, "the giver owns the dare marks")

	# 1) free zoomies while live
	m.dog.energy = 0.2
	m.start_challenge(g, 4, 20.0)
	_check(marks != null and marks.showing(), "the marks are up while the dare is on offer")
	m.on_bark(m.dog.global_position)
	for i in range(int(round((m.challenge.READY_S + 0.1) / DT))):
		m.challenge.tick(DT)
	_check(String(m.challenge.phase) == "live", "the dare went live")
	_check(is_equal_approx(float(m.dog.energy), 1.0), "the clock starting fills the zoomies (%.2f)" % m.dog.energy)
	m.dog.free_turbo = m.challenge.active
	_check(bool(m.dog.free_turbo), "turbo is free while the dare is live")
	Input.action_press("turbo")
	Input.action_press("move_up")
	for i in range(30):
		m.dog.free_turbo = m.challenge.active
		m.dog.tick(DT)
	_check(is_equal_approx(float(m.dog.energy), 1.0), "turbo held for half a second in a dare spent nothing (%.3f)" % m.dog.energy)

	# 2) rings round real poles near her, not round the one just swung
	var pole := Vector2(INF, INF)
	var kinds: PackedInt32Array = m.leash.kinds()
	for i in range(m.leash.poles.size()):
		if kinds[i] == m.leash.K_POLE:
			pole = m.leash.poles[i]
			break
	_check(pole.x < INF, "the park has a real pole")
	m.dog.global_position = pole + Vector2(80.0, 0.0)
	marks._segs.clear()
	marks._draw_into()
	_check(marks._segs.size() > 0, "a pole near her is ringed")
	var near_ring := false
	for s: Vector2 in marks._segs:
		if s.distance_to(pole) < 40.0:
			near_ring = true
	_check(near_ring, "the ring is round that pole")
	m.vault_done_pole = pole
	marks._segs.clear()
	marks._draw_into()
	var still := false
	for s: Vector2 in marks._segs:
		if s.distance_to(pole) < 30.0:
			still = true
	_check(not still, "the pole she just swung round has no ring")
	m.vault_done_pole = Vector2(INF, INF)

	# 3) the hint
	var hint: String = m.dare_hint()
	_check(hint != "" and hint == hint.strip_edges(), "the live card has a hint (%s)" % hint)
	_check(not hint.contains("{"), "the hint's tokens are filled (%s)" % hint)
	m.combo.add("POLE SWING", 20)
	_check(m.dare_hint() == "Pole Swing counts!", "a trick that counted is named (%s)" % m.dare_hint())
	m.dare_last_t = 0.0

	# and once it is over, the zoomies cost again
	for i in range(int(round(25.0 / DT))):
		m.challenge.tick(DT)
	_check(not m.challenge.active, "the dare ended")
	m.dog.free_turbo = m.challenge.active
	m.dog.energy = 1.0
	for i in range(30):
		m.dog.tick(DT)
	_check(float(m.dog.energy) < 0.95, "after the dare, turbo burns zoomies again (%.3f)" % m.dog.energy)
	Input.action_release("turbo")
	Input.action_release("move_up")

	if failures.is_empty():
		print("test_dare_help: OK (%d checks)" % checks)
		quit(0)
	else:
		print("test_dare_help: %d FAILURES" % failures.size())
		quit(1)
