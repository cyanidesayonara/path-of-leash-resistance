extends Node2D

# Another dog-walker: an NPC owner and dog joined by their own leash
# (a real leash.gd rope). They amble along the path. When their leash
# crosses yours, the two ropes drape over each other and TANGLE - the
# flagship dog-park mayhem, emergent from the shared rope physics.

var main: Node2D
var my_dog: Node2D
var npc_owner: Node2D
var npc_dog: Node2D
var leash: Node2D
var vel := Vector2.ZERO
var owner_col := Color(0.5, 0.45, 0.55)
var dog_col := Color(0.6, 0.5, 0.4)
var wander_t := 0.0
var wander := Vector2.ZERO
var seed_o := 0.0
var tangled_t := 0.0
var reacted := false
var sampled: Array[Vector2] = []


func setup(m: Node2D, mine: Node2D, poles: Array[Vector2], start: Vector2, direction: Vector2) -> void:
	add_to_group("pairs")
	main = m
	my_dog = mine
	vel = direction * randf_range(58.0, 82.0)
	seed_o = randf() * 10.0
	owner_col = [Color(0.5, 0.45, 0.55), Color(0.45, 0.5, 0.42), Color(0.55, 0.48, 0.4)][randi() % 3]
	dog_col = [Color(0.6, 0.5, 0.4), Color(0.75, 0.72, 0.68), Color(0.35, 0.3, 0.28)][randi() % 3]
	npc_owner = Node2D.new()
	npc_owner.position = start
	add_child(npc_owner)
	npc_dog = Node2D.new()
	npc_dog.position = start + Vector2(40, 30)
	add_child(npc_dog)
	leash = Node2D.new()
	leash.set_script(load("res://leash.gd"))
	leash.z_index = 6
	add_child(leash)
	leash.setup(npc_dog, npc_owner, poles, 150.0)


func _physics_process(delta: float) -> void:
	if main.frozen:
		return
	tangled_t = maxf(0.0, tangled_t - delta)
	# the owner ambles in their lane; a tangle roots them in place
	if tangled_t <= 0.0:
		npc_owner.position += vel * delta
	# the dog mooches around the owner, drifting toward your dog when near
	wander_t -= delta
	if wander_t <= 0.0:
		wander_t = randf_range(0.6, 1.6)
		wander = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * 40.0
	var to_mine := my_dog.global_position - npc_dog.global_position
	var curious := to_mine.normalized() * 34.0 if to_mine.length() < 160.0 else Vector2.ZERO
	var target := npc_owner.position + Vector2(30, 24) + wander + curious
	npc_dog.position = npc_dog.position.move_toward(target, 90.0 * delta)
	# keep the dog within their (short) leash
	var span := npc_dog.position - npc_owner.position
	if span.length() > 150.0:
		npc_dog.position = npc_owner.position + span.normalized() * 150.0
	leash.tick(delta)
	# sample our rope thinly for the other leash to collide against
	sampled.clear()
	for i in range(0, leash.N, 2):
		sampled.append(leash.pts[i])
	# despawn once well off camera
	if absf(npc_owner.position.y - float(main.cam.position.y)) > 1200.0:
		queue_free()
	queue_redraw()


func note_tangle() -> void:
	tangled_t = 0.4
	if not reacted:
		reacted = true
		main.float_text(npc_owner.position, "oh - sorry!", Color(1, 0.9, 0.8))
	else:
		reacted = false  # lets it re-fire on a fresh tangle later


func _draw() -> void:
	# NPC owner (no glowing phone - they are present, unlike yours)
	var op: Vector2 = npc_owner.position
	draw_circle(op + Vector2(0, 14), 5.0, Color(0.25, 0.25, 0.3))
	draw_circle(op, 13.0, owner_col)
	draw_circle(op + Vector2(0, -12), 7.0, Color(0.85, 0.72, 0.58))
	draw_arc(op + Vector2(0, -12), 7.0, PI, TAU, 10, Color(0.3, 0.24, 0.16), 4.0)
	# NPC dog
	var dp: Vector2 = npc_dog.position
	var t := Time.get_ticks_msec() / 1000.0
	draw_line(dp, dp + Vector2(-9, -3).rotated(sin(t * 8.0 + seed_o) * 0.4), dog_col.darkened(0.2), 3.0)
	draw_circle(dp, 7.0, dog_col)
	var face := (my_dog.global_position - dp).normalized()
	draw_circle(dp + face * 6.0, 4.5, dog_col)
	draw_circle(dp + face * 8.0, 1.4, Color(0.1, 0.09, 0.08))
