extends SceneTree

# The visible path and the strap's drawn polylines are rebuilt every frame on
# every rope, so they reuse fixed-size buffers: always 2N-1 samples, whatever
# the contacts, and a frame never shows samples left over from an earlier one.

var failures := 0


class PolylineSpy:
	extends ShapeBatch

	var polylines: Array[PackedVector2Array] = []

	func draw_polyline(...args: Array) -> void:
		polylines.append(PackedVector2Array(args[0]))

	func draw_circle(..._args: Array) -> void:
		pass

	func flush(_canvas: Object = null) -> void:
		pass


func _check(cond: bool, msg: String) -> void:
	if not cond:
		print("FAIL: " + msg)
		failures += 1


func _lay_open(leash: Node2D) -> void:
	for i in range(leash.N):
		var x := -180.0 + 360.0 * float(i) / float(leash.N - 1)
		leash.pts[i] = Vector2(x, 90.0 * (1.0 - absf(x) / 180.0))
		leash._touch[i] = -1


func _lay_wrapped(leash: Node2D, pole: Vector2) -> void:
	var mid: int = leash.N / 2
	for i in range(leash.N):
		leash._touch[i] = -1
		var x := -180.0 + 360.0 * float(i) / float(leash.N - 1)
		leash.pts[i] = Vector2(x, -20.0)
	for offset in range(-2, 3):
		var angle := -PI + float(offset + 2) * PI / 4.0
		leash.pts[mid + offset] = pole + Vector2.from_angle(angle) * 14.5
	leash._touch[mid] = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var dog := Node2D.new()
	var human := Node2D.new()
	var leash := Node2D.new()
	leash.set_script(load("res://entities/leash.gd"))
	root.add_child(dog)
	root.add_child(human)
	root.add_child(leash)
	dog.global_position = Vector2(-180, 0)
	human.global_position = Vector2(180, 0)
	var pole := Vector2.ZERO
	var poles: Array[Vector2] = [pole]
	leash.setup(dog, human, poles, 360.0)
	leash._touch.resize(leash.N)
	leash._obs_pos = PackedVector2Array([pole])
	leash._obs_kind = PackedInt32Array([leash.K_POLE])
	var samples: int = 2 * leash.N - 1

	_lay_open(leash)
	var open_a := PackedVector2Array(leash.visible_path())
	_lay_wrapped(leash, pole)
	var wrapped := PackedVector2Array(leash.visible_path())
	_lay_open(leash)
	var open_b := PackedVector2Array(leash.visible_path())
	_check(open_a.size() == samples, "open path has 2N-1 samples (got %d)" % open_a.size())
	_check(wrapped.size() == samples, "wrapped path has 2N-1 samples (got %d)" % wrapped.size())
	_check(open_a == open_b, "the same rope gives the same path after a wrapped frame")

	# a segment ending on the contact keeps its chord: its in-between sample is
	# the chord's midpoint, so it adds no bend and cannot cut the pole
	_lay_wrapped(leash, pole)
	var mid: int = leash.N / 2
	var path: PackedVector2Array = leash.visible_path()
	if path.size() == samples:
		var want: Vector2 = (leash.pts[mid] + leash.pts[mid + 1]) * 0.5
		_check(path[2 * mid + 1].distance_to(want) < 0.0001,
			"the sample between a contact and its neighbour is the chord midpoint (%s vs %s)" % [
				path[2 * mid + 1], want])
		for i in range(leash.N):
			_check(path[2 * i].distance_to(leash.pts[i]) < 0.0001,
				"solver point %d sits at sample %d" % [i, 2 * i])

	# the drawn polylines are the visible path, every frame, at full length
	var draws: Array = []
	for layout in ["open", "wrapped", "open"]:
		if layout == "open":
			_lay_open(leash)
		else:
			_lay_wrapped(leash, pole)
		var spy := PolylineSpy.new()
		leash._b = spy
		leash._draw_shapes()
		draws.append(spy.polylines)
		_check(spy.polylines.size() == 4, "the strap is four polylines (got %d)" % spy.polylines.size())
		for line: PackedVector2Array in spy.polylines:
			_check(line.size() == samples,
				"%s strap polyline has 2N-1 points (got %d)" % [layout, line.size()])
	if draws.size() == 3 and draws[0].size() == draws[2].size():
		for k in range(draws[0].size()):
			_check(draws[0][k] == draws[2][k],
				"polyline %d is redrawn identically after a wrapped frame" % k)

	leash.free()
	dog.free()
	human.free()
	if failures > 0:
		print("test_leash_draw_buffers: %d FAILURES" % failures)
		quit(1)
	else:
		print("test_leash_draw_buffers: OK")
		quit(0)
