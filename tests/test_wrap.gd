extends SceneTree

# Rope physics regression test. Run with:
#   godot --headless --path . --script res://tests/test_wrap.gd
# The leash is a verlet rope and that rope IS the gameplay constraint, so
# these assert the invariants gameplay depends on: stretch measurement,
# winding a pole (spiral-in, the way tetherball actually works), and the
# coil slipping off under a hard pull rather than sticking forever (the
# "magnetic owner" bug). Exits nonzero on failure.

const DT := 1.0 / 60.0

var leash: Node2D
var dog: Node2D
var human: Node2D
var failures := 0


func _check(cond: bool, msg: String) -> void:
	if not cond:
		print("FAIL: " + msg)
		failures += 1


func _orbit(cx: float, cy: float, from_r: float, to_r: float, degs: float) -> void:
	var steps := int(absf(degs))
	for i in range(steps):
		var t := float(i) / float(steps)
		var r := lerpf(from_r, to_r, t)
		var a := deg_to_rad(degs * t)
		dog.global_position = Vector2(cx, cy) + Vector2(r, 0).rotated(a)
		leash.tick(DT)


func _settle(frames: int) -> void:
	for i in range(frames):
		leash.tick(DT)


func _initialize() -> void:
	leash = Node2D.new()
	leash.set_script(load("res://leash.gd"))
	dog = Node2D.new()
	human = Node2D.new()
	root.add_child(dog)
	root.add_child(human)
	root.add_child(leash)
	dog.global_position = Vector2(60, 0)
	human.global_position = Vector2(-200, 0)
	var pole_list: Array[Vector2] = [Vector2.ZERO]
	leash.setup(dog, human, pole_list, 260.0)

	# 1) straight-line stretch is the rope's polyline length; end tangent
	#    points back along the rope
	dog.global_position = Vector2(100, 16)
	_settle(120)
	var used: float = leash.used_length()
	print("straight 300px pull: used %.0f" % used)
	_check(absf(used - 300.0) < 14.0, "used_length should track the 300px chord (got %.0f)" % used)
	_check(leash.dog_pull_dir().dot(Vector2(-1, 0)) > 0.9, "dog end pulled back along rope")

	# 2) wind the pole by spiralling in (tetherball). A slack wind is a
	#    LOOSE coil that may not touch the pole - correct physics. The
	#    property gameplay needs: once the wound rope pulls taut, the coil
	#    cinches onto the pole and the pull directions follow the rope
	#    around it (the arc-fling mechanic).
	human.global_position = Vector2(-80, 0)
	dog.global_position = Vector2(120, 0)
	_settle(60)
	_orbit(0, 0, 120.0, 26.0, 2.0 * 360.0)
	_settle(30)
	print("after spiral wind: winding %.2f, used %.0f" % [leash.winding(), leash.used_length()])
	_check(absf(leash.winding()) > 1.0, "spiral should register winding turns (got %.2f)" % leash.winding())
	# pull outward until taut: coil cinches, pull curves around the pole
	dog.global_position = Vector2(0, 90)
	_settle(120)
	print("tightened: contacts %d, winding %.2f, used %.0f" % [leash.contacts, leash.winding(), leash.used_length()])
	_check(leash.contacts >= 3, "a taut coil should grip the pole (%d contacts)" % leash.contacts)
	_check(absf(leash.winding()) > 0.8, "tightening should keep the coil (winding %.2f)" % leash.winding())
	var to_dog := (dog.global_position - human.global_position).normalized()
	var hp: Vector2 = leash.human_pull_dir()
	_check(hp.dot(to_dog) < 0.9, "wound pull should curve around the pole, not aim straight at the dog (dot %.2f)" % hp.dot(to_dog))

	# 3) the coil is not permanent: a hard pull away slips it off the pole
	#    (this is the magnetic-owner bug's regression guard). The dog pulls
	#    to the same side as the human so a still-hooked rope would hairpin
	#    around the pole and read clearly longer than the chord.
	dog.global_position = Vector2(-430, 320)
	_settle(1200)
	used = leash.used_length()
	var chord := human.global_position.distance_to(dog.global_position)
	print("after hard pull-away: used %.0f vs chord %.0f, contacts %d" % [used, chord, leash.contacts])
	_check(used < chord * 1.15, "sustained tension slips the coil off (used %.0f, chord %.0f)" % [used, chord])
	_check(absf(leash.winding()) < 0.5, "fully pulled away means unwound (winding %.2f)" % leash.winding())

	# 4) stability: no NaN anywhere in the rope
	var finite := true
	for p in leash.pts:
		if not (is_finite(p.x) and is_finite(p.y)):
			finite = false
	_check(finite, "rope points stay finite")

	if failures > 0:
		print("test_wrap: %d FAILURES" % failures)
		quit(1)
	else:
		print("test_wrap: OK")
		quit(0)
