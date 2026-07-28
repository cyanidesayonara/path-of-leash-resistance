extends SceneTree

# Regression for the leash-vault's swing direction (main.vault_tangent).
# The maths that decides WHICH WAY she carves around a wrapped pole is the
# part most likely to be silently wrong - a flipped sign would fling her
# backwards into the pole instead of around it - so it is pulled out as a
# static function and pinned here.
#
#  1. the swing is always perpendicular to the rope (a true circular carve)
#  2. it follows the way she is already travelling, never reverses her
#  3. it flips with her, so approaching from the other side swings the
#     other way
#  4. degenerate input (standing exactly on the pole) is handled, not NaN

const SwingMath := preload("res://swing.gd")


func _initialize() -> void:
	var failures := 0
	var pole := Vector2(100.0, 100.0)

	# 1) perpendicular to the rope
	var pos := pole + Vector2(50.0, 0.0)      # she is due right of the pole
	var vel := Vector2(0.0, -160.0)           # travelling up
	var t: Vector2 = SwingMath.vault_tangent(pole, pos, vel)
	var radial := (pos - pole).normalized()
	if absf(t.dot(radial)) > 0.001:
		print("FAIL: the swing must be perpendicular to the rope, dot=%.3f" % t.dot(radial))
		failures += 1
	if absf(t.length() - 1.0) > 0.001:
		print("FAIL: the swing direction should be a unit vector, got %.3f" % t.length())
		failures += 1

	# 2) it never reverses her: it goes with her travel
	if t.dot(vel) <= 0.0:
		print("FAIL: the swing should follow her travel, dot=%.3f" % t.dot(vel))
		failures += 1

	# 3) same spot, opposite travel -> opposite swing
	var t2: Vector2 = SwingMath.vault_tangent(pole, pos, Vector2(0.0, 160.0))
	if t2.dot(t) > -0.9:
		print("FAIL: reversing her travel should reverse the carve")
		failures += 1

	# 4) approaching the pole from the other side mirrors the carve
	var pos_l := pole + Vector2(-50.0, 0.0)
	var t3: Vector2 = SwingMath.vault_tangent(pole, pos_l, Vector2(0.0, -160.0))
	if absf(t3.dot((pos_l - pole).normalized())) > 0.001:
		print("FAIL: the mirrored case must still be perpendicular")
		failures += 1
	if t3.dot(Vector2(0.0, -160.0)) <= 0.0:
		print("FAIL: the mirrored case should still follow her travel")
		failures += 1

	# 5) standing exactly on the pole must not produce NaN
	var t4: Vector2 = SwingMath.vault_tangent(pole, pole, Vector2(10.0, 0.0))
	if is_nan(t4.x) or is_nan(t4.y):
		print("FAIL: a zero-length rope produced NaN")
		failures += 1

	if failures > 0:
		print("test_vault: %d FAILURES" % failures)
		quit(1)
	else:
		print("test_vault: OK")
		quit(0)
