extends SceneTree

# The public visible path may resample or keep the solver point count, but it
# must smooth open spans, preserve static-contact pins, clear the pole, and be
# the path consumed by the real draw routine.

var failures := 0


class DrawProbe:
	extends "res://entities/leash.gd"

	var visible_path_calls := 0
	var draw_calls := 0

	func visible_path() -> PackedVector2Array:
		visible_path_calls += 1
		return PackedVector2Array(pts)

	func _draw() -> void:
		draw_calls += 1
		super._draw()


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
		# endpoints and smooth a deliberately sharp but obstacle-free span.
		for i in range(leash.N):
			var x := -180.0 + 360.0 * float(i) / float(leash.N - 1)
			leash.pts[i] = Vector2(x, 22.0 if i % 2 == 0 else -22.0)
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

		# Put the middle controls on a valid 14px arc around the 13px pole.
		# The contact and both adjacent controls are hard pins for smoothing.
		var mid: int = leash.N / 2
		leash._obs_pos = PackedVector2Array([pole])
		leash._obs_kind = PackedInt32Array([leash.K_POLE])
		for i in range(leash.N):
			leash._touch[i] = -1
		for offset in range(-2, 3):
			var angle := -PI / 2.0 + float(offset) * PI / 6.0
			leash.pts[mid + offset] = pole + Vector2.from_angle(angle) * 14.0
		leash._touch[mid] = 0
		var wrapped_path: Array = Array(leash.visible_path())
		for index in [mid - 1, mid, mid + 1]:
			_check(_contains_point(wrapped_path, leash.pts[index]),
				"render path pins control %d beside the static contact" % index)
		for p: Vector2 in wrapped_path:
			_check(p.distance_to(pole) + 0.01 >= leash.POLE_PAD,
				"smoothed render path clears POLE_PAD (point %s)" % p)

	# A virtual probe makes the integration behavioural: drawing one real
	# leash frame must request its public visible path. No source inspection.
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
	draw_probe.queue_redraw()
	await process_frame
	await process_frame
	_check(draw_probe.draw_calls > 0, "draw integration fixture rendered a real leash frame")
	_check(draw_probe.visible_path_calls > 0,
		"_draw_shapes consumes the public visible path")

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
