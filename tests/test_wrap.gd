extends SceneTree

# Winding regression test. Run with:
#   godot --headless --path . --script res://tests/test_wrap.gd
# Orbits the dog around a pole three full revolutions, expects the leash to
# accumulate pivots and hold them, then orbits back and expects a full
# unwind. Exits nonzero on failure.


func _initialize() -> void:
	var leash := Node2D.new()
	leash.set_script(load("res://leash.gd"))
	var dog := Node2D.new()
	var human := Node2D.new()
	root.add_child(dog)
	root.add_child(human)
	root.add_child(leash)
	dog.global_position = Vector2(60, 0)
	human.global_position = Vector2(-200, 0)
	var pole_list: Array[Vector2] = [Vector2.ZERO]
	leash.setup(dog, human, pole_list, 260.0)

	var failures := 0
	var max_pivots := 0

	# wind: three CCW revolutions in 1-degree steps
	for i in range(3 * 360):
		dog.global_position = Vector2(60, 0).rotated(deg_to_rad(float(i)))
		leash.update_wraps()
		max_pivots = maxi(max_pivots, leash.pivots.size())
	print("after 3 revolutions: %d pivots (max seen %d)" % [leash.pivots.size(), max_pivots])
	if leash.pivots.size() < 6:
		print("FAIL: winding should accumulate pivots (got %d, want >= 6)" % leash.pivots.size())
		failures += 1

	# used length must have grown by roughly the wound-up rope
	var used: float = leash.used_length()
	if used < 300.0:
		print("FAIL: wound leash should consume length (used %.0f, want >= 300)" % used)
		failures += 1

	# unwind: three revolutions back
	for i in range(3 * 360):
		dog.global_position = Vector2(60, 0).rotated(deg_to_rad(float(3 * 360 - i)))
		leash.update_wraps()
	print("after unwinding: %d pivots" % leash.pivots.size())
	# one residual pivot is legitimate: at the start angle the straight rope
	# passes right through the pole
	if leash.pivots.size() > 1:
		print("FAIL: reversing should unwind (still %d pivots)" % leash.pivots.size())
		failures += 1

	# same test clockwise, to catch a one-sided sign convention
	for i in range(2 * 360):
		dog.global_position = Vector2(60, 0).rotated(deg_to_rad(-float(i)))
		leash.update_wraps()
	print("after 2 CW revolutions: %d pivots" % leash.pivots.size())
	if leash.pivots.size() < 4:
		print("FAIL: clockwise winding should accumulate pivots (got %d, want >= 4)" % leash.pivots.size())
		failures += 1

	if failures > 0:
		print("test_wrap: %d FAILURES" % failures)
		quit(1)
	else:
		print("test_wrap: OK")
		quit(0)
