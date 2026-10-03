extends SceneTree

# The public visible path may resample or keep the solver point count, but it
# must smooth open spans, preserve static-contact pins, clear the pole, and be
# the path consumed by the real draw routine.

var failures := 0


class DrawProbe:
	extends "res://entities/leash.gd"

	var visible_path_calls := 0
	var taut_amount_calls := 0
	var forced_taut_amount := 0.0

	func visible_path() -> PackedVector2Array:
		visible_path_calls += 1
		return PackedVector2Array(pts)

	func taut_amount(_stretch_ratio: float) -> float:
		taut_amount_calls += 1
		return forced_taut_amount


class BatchSpy:
	extends ShapeBatch

	var widths: Array[float] = []

	func draw_polyline(...args: Array) -> void:
		widths.append(float(args[2]))

	func draw_circle(..._args: Array) -> void:
		pass

	func flush(_canvas: Object = null) -> void:
		pass


func _check(cond: bool, msg: String) -> void:
	if not cond:
		print("FAIL: " + msg)
		failures += 1


func _contains_point(path: Array, target: Vector2) -> bool:
	for p: Vector2 in path:
		if p.distance_to(target) < 0.01:
			return true
	return false


func _max_turn(path: Array) -> float:
	var result := 0.0
	for i in range(1, path.size() - 1):
		var incoming: Vector2 = path[i] - path[i - 1]
		var outgoing: Vector2 = path[i + 1] - path[i]
		if incoming.length_squared() > 0.001 and outgoing.length_squared() > 0.001:
			result = maxf(result, absf(incoming.angle_to(outgoing)))
	return result


func _path_length(path: Array) -> float:
	var result := 0.0
	for i in range(path.size() - 1):
		result += path[i].distance_to(path[i + 1])
	return result


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

	_check(leash.has_method("visible_path"),
		"leash exposes visible_path() for the geometry it draws")
	if leash.has_method("visible_path"):
		# The public result may have any useful sample count. It must retain the
		# endpoints and round one deliberate, obstacle-free V without flattening
		# away the rope's meaningful arc length.
		for i in range(leash.N):
			var x := -180.0 + 360.0 * float(i) / float(leash.N - 1)
			leash.pts[i] = Vector2(x, 90.0 * (1.0 - absf(x) / 180.0))
			leash._touch[i] = -1
		var open_path: Array = Array(leash.visible_path())
		_check(open_path.size() >= 2, "visible path contains drawable geometry")
		if open_path.size() >= 2:
			_check(open_path[0].distance_to(leash.pts[0]) < 0.01,
				"visible path keeps the dog endpoint pinned")
			_check(open_path[-1].distance_to(leash.pts[-1]) < 0.01,
				"visible path keeps the human endpoint pinned")
			_check(_max_turn(open_path) < _max_turn(leash.pts) - 0.05,
				"open visible path smooths sharp solver corners (%.3f vs %.3f radians)" % [
					_max_turn(open_path), _max_turn(leash.pts)])
			var solver_length := _path_length(leash.pts)
			var visible_length := _path_length(open_path)
			_check(visible_length >= solver_length * 0.95,
				"open smoothing preserves at least 95%% of rope arc length (%.1f vs %.1f)" % [
					visible_length, solver_length])
			_check(visible_length <= solver_length * 1.05,
				"open smoothing does not invent more than 5%% rope length (%.1f vs %.1f)" % [
					visible_length, solver_length])

		# Put the middle controls on a valid 14px arc around the 13px pole.
		# The contact and both adjacent controls are hard pins for smoothing.
		var mid: int = leash.N / 2
		leash._obs_pos = PackedVector2Array([pole])
		leash._obs_kind = PackedInt32Array([leash.K_POLE])
		for i in range(leash.N):
			leash._touch[i] = -1
			var x := -180.0 + 360.0 * float(i) / float(leash.N - 1)
			leash.pts[i] = Vector2(x, -20.0)
		for offset in range(-2, 3):
			var angle := -PI + float(offset + 2) * PI / 4.0
			leash.pts[mid + offset] = pole + Vector2.from_angle(angle) * 14.5
		leash._touch[mid] = 0
		var wrapped_path: Array = Array(leash.visible_path())
		for index in [mid - 1, mid, mid + 1]:
			_check(_contains_point(wrapped_path, leash.pts[index]),
				"render path pins control %d beside the static contact" % index)
		for i in range(wrapped_path.size() - 1):
			var closest: Vector2 = leash._closest_on_segment(
				wrapped_path[i], wrapped_path[i + 1], pole)
			_check(closest.distance_to(pole) + 0.01 >= leash.POLE_PAD,
				"visible segment %d clears POLE_PAD (closest point %s)" % [i, closest])

	# Script-level spies make draw integration behavioural without source
	# inspection or pixels: the real _draw_shapes must request the public path
	# and use the continuous taut amount to interpolate its primary width.
	var draw_dog := Node2D.new()
	var draw_human := Node2D.new()
	var draw_probe := DrawProbe.new()
	root.add_child(draw_dog)
	root.add_child(draw_human)
	root.add_child(draw_probe)
	draw_dog.global_position = Vector2(40, 80)
	draw_human.global_position = Vector2(240, 80)
	var no_poles: Array[Vector2] = []
	draw_probe.setup(draw_dog, draw_human, no_poles, 220.0)
	var primary_widths: Array[float] = []
	for amount in [0.0, 0.5, 1.0]:
		draw_probe.forced_taut_amount = amount
		var batch := BatchSpy.new()
		draw_probe._b = batch
		draw_probe._draw_shapes()
		_check(batch.widths.size() >= 1,
			"draw integration fixture records the primary polyline width")
		if batch.widths.size() >= 1:
			primary_widths.append(batch.widths[0])
	_check(draw_probe.visible_path_calls > 0,
		"_draw_shapes consumes the public visible path")
	_check(draw_probe.taut_amount_calls >= 3,
		"_draw_shapes consumes continuous taut_amount for each sampled width")
	if primary_widths.size() == 3:
		_check(primary_widths[0] > primary_widths[1]
				and primary_widths[1] > primary_widths[2],
			"draw width changes continuously at taut amounts 0, 0.5, 1 (%s)"
				% [primary_widths])

	leash.free()
	dog.free()
	human.free()
	draw_probe.free()
	draw_dog.free()
	draw_human.free()
	if failures > 0:
		print("test_leash_render_path: %d FAILURES" % failures)
		quit(1)
	else:
		print("test_leash_render_path: OK")
		quit(0)
