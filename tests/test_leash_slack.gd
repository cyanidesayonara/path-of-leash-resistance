extends SceneTree

# Slack lies in curves, not an accordion (entities/leash.gd, BEND_MIN):
#  1. a slack rope on open ground has no joint folded back on itself: every
#     point two along stays at least most of BEND_MIN segments away
#  2. bending never lengthens the rope into a false pull: a slack rope stays
#     shorter than its rest length, so it never reads as taut
#  3. near a pole the solver is exactly what it was: no bending inside
#     BEND_BERTH, checked by the rope being free to fold there

const DT := 1.0 / 60.0
var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	call_deferred("_run")


func _rope(poles: Array[Vector2]) -> Array:
	var l: Node2D = Node2D.new()
	l.set_script(load("res://entities/leash.gd"))
	var dog := Node2D.new()
	var human := Node2D.new()
	root.add_child(dog)
	root.add_child(human)
	root.add_child(l)
	human.global_position = Vector2(0, 0)
	dog.global_position = Vector2(200, 0)
	l.setup(dog, human, poles, 260.0)
	return [l, dog, human]


func _min_fold(l: Node2D) -> float:
	var seg: float = l.rest_len / float(l.N - 1)
	var worst := INF
	for i in range(l.N - 2):
		worst = minf(worst, l.pts[i].distance_to(l.pts[i + 2]) / seg)
	return worst


func _run() -> void:
	# 1, 2) open ground: the dog walks in close and stands; the rope goes slack
	var a := _rope([] as Array[Vector2])
	var l: Node2D = a[0]
	var dog: Node2D = a[1]
	for i in range(240):
		dog.global_position = Vector2(200, 0).lerp(Vector2(50, 10), minf(float(i) / 120.0, 1.0))
		l.tick(DT)
	var fold := _min_fold(l)
	_check(fold > l.BEND_MIN * 0.75, "open-ground slack has no folded joint (tightest %.2f segments apart)" % fold)
	_check(l.used_length() < l.rest_len, "a slack rope stays shorter than its rest length (%.1f of %.1f)" % [l.used_length(), l.rest_len])
	for n in a:
		n.queue_free()

	# 3) beside a pole the old solver stands: nothing opens the folds
	var b := _rope([Vector2(100, 40)] as Array[Vector2])
	var lb: Node2D = b[0]
	var dogb: Node2D = b[1]
	for i in range(240):
		dogb.global_position = Vector2(200, 0).lerp(Vector2(50, 10), minf(float(i) / 120.0, 1.0))
		lb.tick(DT)
	_check(_min_fold(lb) < l.BEND_MIN * 0.75, "beside a pole it is the old solver, folds and all (%.2f)" % _min_fold(lb))
	for n in b:
		n.queue_free()

	print("test_leash_slack: %d checks, %s" % [checks, "OK" if failures.is_empty() else "%d FAILED" % failures.size()])
	quit(1 if not failures.is_empty() else 0)
