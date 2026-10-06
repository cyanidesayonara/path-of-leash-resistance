extends SceneTree

# Your human's sunhat on Montjuïc (montjuic.blow_hat, entities/sunhat.gd,
# main.on_hat_returned):
#  1. a gust takes it once a walk: their head is bare and the hat is out
#  2. it goes off downwind and comes to rest on the path, inside its edges
#  3. she picks it up, and taking it to them puts it back on, for bones and
#     a full patience
#  4. never a second time; and not while they are down
#  5. a hat carried into the off-leash space is dropped there

var M: GDScript
var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	call_deferred("_run")


func _hat(m: Node2D) -> Node2D:
	for c in m.get_children():
		if c.get_script() == M.get("Sunhat"):
			return c
	return null


func _run() -> void:
	M = load("res://systems/montjuic.gd")
	var game = root.get_node("Game")
	game.persist = false
	root.get_node("Sfx").muted = true
	game.level_id = "montjuic"
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	for k in range(3):
		await physics_frame
	m._skip_title()
	await physics_frame

	# 1) the gust takes it
	_check(not m.human.hat_off, "they start the climb in their hat")
	m.wind_dir = Vector2(1, 0.2).normalized()
	var from: Vector2 = m.human.global_position
	_check(M.blow_hat(m), "a gust takes the hat")
	var hat := _hat(m)
	_check(m.human.hat_off and hat != null, "their head is bare and the hat is out")

	# 2) downwind, then at rest inside the path
	m.human.global_position = from
	for i in range(240):
		m.human.global_position = from
		m.dog.global_position = from + Vector2(-200, 0)
		hat._physics_process(1.0 / 60.0)
	_check(hat.state == hat.State.RESTING, "it comes to rest")
	_check(hat.global_position.x > from.x, "downwind of them")
	var e: Vector2 = m.walk_edges(hat.global_position.y)
	_check(hat.global_position.x >= e.x and hat.global_position.x <= e.y, "on the path, inside its edges")

	# 3) fetched and given back
	m.dog.global_position = hat.global_position
	hat._physics_process(1.0 / 60.0)
	_check(hat.state == hat.State.CARRIED, "she picks it up")
	var b0: int = m.bones
	m.human.patience = 0.3
	m.dog.global_position = m.human.global_position + Vector2(0, 20)
	hat._physics_process(1.0 / 60.0)
	_check(not m.human.hat_off and m.bones == b0 + 6 and is_equal_approx(m.human.patience, 1.0),
		"taking it to them puts it back on, for bones and patience")
	_check(hat.is_queued_for_deletion(), "and the hat on the path is gone")
	await physics_frame

	# 4) once a walk
	_check(not M.blow_hat(m) and not m.human.hat_off, "never a second time")
	m.remove_meta("hat_done")
	m.human.fall("test")
	_check(not M.blow_hat(m), "not while they are down")
	await physics_frame
	m.human.state = 0
	m.human.iframes = 0.0

	# 5) dropped at the gate
	m.remove_meta("hat_done")
	m.human.hat_off = false
	_check(M.blow_hat(m), "a fresh walk's gust")
	hat = _hat(m)
	hat.state = hat.State.CARRIED
	m.phase = "freedom"
	hat._physics_process(1.0 / 60.0)
	_check(hat.state == hat.State.RESTING, "a carried hat is dropped in the off-leash space")
	m.phase = "out"

	m.free()
	print("test_sunhat: %d checks, %s" % [checks, "OK" if failures.is_empty() else "%d FAILED" % failures.size()])
	quit(1 if not failures.is_empty() else 0)
