extends SceneTree

# The whirl (entities/human.gd WHIRL, armed in main.gd): an owner wound round
# a pole orbits it to unwind. It must orbit the pole the rope is actually
# wound on at the owner's end, and only a real pole (orbiting a café table,
# or the wrong bollard of two, never unwinds anything - La Rambla's terrace
# once held an owner in a whirl-stumble loop for two minutes); and it must
# begin where the owner stands and tighten in, not teleport them onto the
# orbit on the first frame.

const DT := 1.0 / 60.0

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	_rope_knows_its_pole()
	call_deferred("_run")


# wind a rope round one of two poles and ask it which one the owner's end is on
func _rope_knows_its_pole() -> void:
	var leash: Node2D = Node2D.new()
	leash.set_script(load("res://entities/leash.gd"))
	var dog := Node2D.new()
	var human := Node2D.new()
	root.add_child(dog)
	root.add_child(human)
	root.add_child(leash)
	var near := Vector2.ZERO
	# close to the owner (so "nearest pole" would pick it) but off the rope
	var decoy := Vector2(-45, 75)
	human.global_position = Vector2(-40, 30)
	dog.global_position = Vector2(-60, -40)
	var poles: Array[Vector2] = [decoy, near]
	leash.setup(dog, human, poles, 260.0)
	# the dog circles the near pole, winding the rope on it
	for i in range(540):
		var a := deg_to_rad(float(i))
		dog.global_position = near + Vector2(-40, 0).rotated(-a)
		leash.tick(DT)
	_check(leash.human_contact_pole.distance_to(near) < 1.0,
		"the rope reports the pole it is wound on at the owner's end (%s)" % leash.human_contact_pole)
	_check(leash.human_contact_is_pole, "and knows it is a pole, not furniture")
	leash.queue_free()
	dog.queue_free()
	human.queue_free()


func _run() -> void:
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	var h: CharacterBody2D = m.human
	var pole: Vector2 = h.global_position + Vector2(60, 0)
	var start: Vector2 = h.global_position
	h.velocity = Vector2(0, -120)
	h.start_whirl(pole, 1.0, 1.5)
	h.tick(DT)
	var jump := h.global_position.distance_to(start)
	# one frame of orbit at the starting radius, not a snap onto 30 px
	_check(jump < float(h.whirl_omega) * 60.0 * DT + 6.0, "the whirl starts where the owner is (moved %.1f px)" % jump)
	_check(h.global_position.distance_to(pole) > 50.0, "and tightens in from there (%.0f from the pole)" % h.global_position.distance_to(pole))
	for i in range(30):
		h.tick(DT)
	_check(absf(h.global_position.distance_to(pole) - h.WHIRL_R) < 2.0 or not h.is_whirling(),
		"within half a second it is on the orbit")
	m.queue_free()
	await process_frame
	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_whirl: OK")
		quit(0)
	else:
		quit(1)
