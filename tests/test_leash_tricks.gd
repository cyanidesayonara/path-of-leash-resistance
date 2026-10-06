extends SceneTree

# The leash tricks (main._end_vault, main._tick_needle, systems/swing.gd):
#  1. which way she goes round a pole, and the figure-eight rule: opposite
#     ways round two different posts
#  2. a fast swing pays more than a slow one of the same turns
#  3. two opposite swings round two posts land a FIGURE EIGHT; the same way
#     round does not
#  4. a dash between two tourists threads the needle; between an owner and
#     their own dog it does not, nor through a gap too wide, nor at a trot

const SwingMath := preload("res://systems/swing.gd")
var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	call_deferred("_run")


# one finished swing of `turns` round `pole`, carried at `pace`, with her
# going round it the `way` given (+1 / -1)
func _swing(m: Node2D, pole: Vector2, turns: float, pace: float, way: float) -> int:
	m.vault_pole = pole
	m.vault_t = 0.1
	m.vault_arc = turns * TAU
	m.vault_elapsed = 1.0
	m.vault_speed_sum = pace
	m.dog.global_position = pole + Vector2(60, 0)
	m.dog.velocity = Vector2(0, -200.0 * way)
	var before: int = m.combo.points
	m._end_vault()
	return m.combo.points - before


func _person(group: String, at: Vector2) -> Node2D:
	var n := Node2D.new()
	n.add_to_group(group)
	root.add_child(n)
	n.global_position = at
	return n


func _run() -> void:
	# 1) pure rules
	var pole := Vector2(100, 100)
	var s1 := SwingMath.sense(pole, pole + Vector2(50, 0), Vector2(0, -100))
	var s2 := SwingMath.sense(pole, pole + Vector2(50, 0), Vector2(0, 100))
	_check(s1 != 0.0 and s1 == -s2, "reversing her travel reverses the way round")
	_check(SwingMath.sense(pole, pole + Vector2(50, 0), Vector2(100, 0)) == 0.0, "running straight at it is not going round")
	_check(SwingMath.is_figure_eight({"pole": pole, "sense": s1}, pole + Vector2(120, 0), -s1, 40.0), "opposite ways round two posts is a figure eight")
	_check(not SwingMath.is_figure_eight({"pole": pole, "sense": s1}, pole + Vector2(120, 0), s1, 40.0), "the same way round is not")
	_check(not SwingMath.is_figure_eight({"pole": pole, "sense": s1}, pole + Vector2(10, 0), -s1, 40.0), "back round the same post is not")
	_check(not SwingMath.is_figure_eight({}, pole, -s1, 40.0), "nor with no swing before it")
	_check(SwingMath.crosses_gap(Vector2(30, -10), Vector2(30, 10), Vector2(0, 0), Vector2(60, 0), 26.0, 96.0), "a step between two people crosses the gap")
	_check(not SwingMath.crosses_gap(Vector2(80, -10), Vector2(80, 10), Vector2(0, 0), Vector2(60, 0), 26.0, 96.0), "a step beside them does not")
	_check(not SwingMath.crosses_gap(Vector2(60, -10), Vector2(60, 10), Vector2(0, 0), Vector2(120, 0), 26.0, 96.0), "too wide a gap is not a needle")

	var game = root.get_node("Game")
	game.persist = false
	root.get_node("Sfx").muted = true
	game.level_id = "street"
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	for k in range(3):
		await physics_frame
	m._skip_title()
	m.golden_t = 0.0
	m.dog.energy = 0.0

	# 2) pace pays
	var slow := _swing(m, Vector2(300, -500), 1.0, 150.0, 1.0)
	m.last_swing.clear()
	m.dog.energy = 0.0
	var fast := _swing(m, Vector2(300, -500), 1.0, 400.0, 1.0)
	m.last_swing.clear()
	_check(fast > slow and slow > 0, "a fast swing pays more than a slow one (%d vs %d)" % [fast, slow])

	# 3) the figure eight
	m.dog.energy = 0.0
	var f0: int = m.needles_done
	_swing(m, Vector2(300, -500), 0.6, 250.0, 1.0)
	var same := _swing(m, Vector2(450, -500), 0.6, 250.0, 1.0)
	_check(not m.combo.names.has("FIGURE EIGHT"), "two swings the same way round are not a figure eight")
	m.last_swing.clear()
	_swing(m, Vector2(300, -500), 0.6, 250.0, 1.0)
	m.dog.energy = 0.0
	var eight := _swing(m, Vector2(450, -500), 0.6, 250.0, -1.0)
	_check(m.combo.names.has("FIGURE EIGHT") and eight > same, "opposite ways round two posts land a FIGURE EIGHT")
	_check(m.needles_done == f0, "no needle from swinging")

	# 4) threading the needle
	var y: float = m.dog.global_position.y - 400.0
	var a := _person("tourists", Vector2(600, y))
	var b := _person("tourists", Vector2(660, y))
	m.needle_cd = 0.0
	m.needle_prev = Vector2(630, y + 12)
	m.dog.global_position = Vector2(630, y - 12)
	m.dog.velocity = Vector2(0, -320)
	m._tick_needle(1.0 / 60.0)
	_check(m.needles_done == 1 and m.combo.names.has("THREAD THE NEEDLE"), "a dash between two tourists threads the needle")
	m.needle_cd = 0.0
	m.needle_prev = Vector2(630, y + 12)
	m.dog.global_position = Vector2(630, y - 12)
	m.dog.velocity = Vector2(0, -120)
	m._tick_needle(1.0 / 60.0)
	_check(m.needles_done == 1, "not at a trot")
	b.global_position = Vector2(760, y)
	m.needle_cd = 0.0
	m.needle_prev = Vector2(680, y + 12)
	m.dog.global_position = Vector2(680, y - 12)
	m.dog.velocity = Vector2(0, -320)
	m._tick_needle(1.0 / 60.0)
	_check(m.needles_done == 1, "not through a gap you could walk a bus through")
	a.queue_free()
	b.queue_free()

	m.free()
	print("test_leash_tricks: %d checks, %s" % [checks, "OK" if failures.is_empty() else "%d FAILED" % failures.size()])
	quit(1 if not failures.is_empty() else 0)
