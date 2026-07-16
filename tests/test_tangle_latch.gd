extends SceneTree

var failures := 0


class FakeMain:
	extends Node2D

	var apologies := 0

	func float_text(_pos: Vector2, text: String, _color: Color) -> void:
		if text == "oh - sorry!":
			apologies += 1


func _check(cond: bool, msg: String) -> void:
	if not cond:
		print("FAIL: " + msg)
		failures += 1


func _make_pair(main: Node2D) -> Node2D:
	var pair := Node2D.new()
	pair.set_script(load("res://otherpair.gd"))
	pair.main = main
	pair.npc_owner = Node2D.new()
	pair.add_child(pair.npc_owner)
	return pair


func _initialize() -> void:
	var main := FakeMain.new()
	root.add_child(main)
	var pair := _make_pair(main)

	_check(pair.update_tangle_state(true, 0.016), "first crossing is a new event")
	_check(is_equal_approx(pair.tangled_t, 0.4), "crossing refreshes the root timer")
	_check(main.apologies == 1, "first crossing displays one apology")

	pair.tangled_t = 0.1
	_check(not pair.update_tangle_state(true, 0.016), "sustained crossing does not retrigger")
	_check(is_equal_approx(pair.tangled_t, 0.4), "sustained crossing refreshes the root timer")
	_check(main.apologies == 1, "sustained crossing does not repeat the apology")

	_check(not pair.update_tangle_state(false, 0.49), "short separation does not emit an event")
	_check(pair.tangle_active, "short separation does not rearm")
	_check(not pair.update_tangle_state(true, 0.016), "one-frame recross remains the same snag")
	_check(main.apologies == 1, "geometry flicker does not repeat the apology")
	_check(not pair.update_tangle_state(false, 0.01), "recrossed separation does not emit an event")
	_check(pair.tangle_active, "recross resets accumulated separation")
	_check(not pair.update_tangle_state(true, 0.016), "second recross remains the same snag")

	_check(not pair.update_tangle_state(false, 0.5), "full separation only rearms")
	_check(not pair.tangle_active, "half-second separation rearms the pair")
	_check(pair.update_tangle_state(true, 0.016), "later crossing is a new event")
	_check(main.apologies == 2, "later crossing displays one new apology")

	pair.free()
	if failures > 0:
		print("test_tangle_latch: %d FAILURES" % failures)
		quit(1)
	else:
		print("test_tangle_latch: OK")
		quit(0)
