extends Node2D

# A critter: squirrel, rat, or (rarely) Tofu the cat. The temptation
# that tugs at the DOG (main.gd applies the pull; Tofu pulls hardest).
# Squirrels and rats are never catchable. Tofu and Millie are NOT
# enemies - Tofu simply keeps a respectful distance, allows the
# occasional boop, and relocates to a new hiding spot with dignity.

var main: Node2D
var dog: Node2D
var kind := "squirrel"  # "squirrel" | "rat" | "cat"
var state := 0  # 0 idle, 1 alert, 2 flee
var flee_dir := Vector2.UP
var hide_target := Vector2(INF, INF)
var hop_t := 0.0
var seed_o := 0.0
var chased := false


func setup(m: Node2D, d: Node2D, k: String = "squirrel") -> void:
	add_to_group("squirrels")
	main = m
	dog = d
	kind = k
	seed_o = randf() * 10.0


func _physics_process(delta: float) -> void:
	if main.frozen:
		return
	var dd: float = global_position.distance_to(dog.global_position)
	var alert_r := 220.0 if kind == "cat" else 150.0
	var flee_r := 40.0 if kind == "cat" else 95.0
	match state:
		0:
			hop_t -= delta
			if hop_t <= 0.0:
				hop_t = randf_range(0.8, 2.2)
				if kind != "cat":
					position += Vector2(randf_range(-14.0, 14.0), randf_range(-14.0, 14.0))
			if dd < alert_r:
				state = 1
		1:
			if dd < flee_r:
				scare()
			elif dd > alert_r + 40.0:
				state = 0
			else:
				# traffic spooks critters too (cats merely disapprove)
				for b in main.riders_cache:
					if global_position.distance_to(b.global_position) < (35.0 if kind == "cat" else 60.0):
						scare()
						break
		2:
			var t := Time.get_ticks_msec() / 1000.0
			if kind == "cat" and hide_target.x < INF:
				# a spooked cat skitters and zigzags to a NEW hiding
				# spot, then resettles - cats relocate, they don't leave
				var to := hide_target - global_position
				if to.length() < 12.0:
					state = 0
					hop_t = randf_range(1.0, 2.2)
				else:
					position += to.normalized().rotated(sin(t * 14.0 + seed_o) * 0.6) * 430.0 * delta
			else:
				# zigzag escape, faster than any dog in a straight line
				var wiggle := 0.2 if kind == "cat" else 0.5
				var speed := 460.0 if kind == "cat" else 400.0
				position += flee_dir.rotated(sin(t * 9.0 + seed_o) * wiggle) * speed * delta
				if absf(global_position.y - float(main.cam.position.y)) > 800.0:
					queue_free()
	if not chased and state != 2 and dd < 26.0:
		chased = true
		main.on_critter_chase(global_position, kind)
		scare()
	queue_redraw()


func scare() -> void:
	if state == 2:
		return
	state = 2
	flee_dir = (global_position - dog.global_position).normalized()
	# prefer escaping along the walk axis rather than into walls
	flee_dir = (flee_dir + Vector2(0, -1.2 if flee_dir.y < 0.0 else 1.2)).normalized()
	if kind == "cat":
		hide_target = main.nearest_cover(global_position, dog.global_position)


func _draw() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	if kind == "rat":
		# passeig rats: grey, quick, long naked tail; Millie finds them
		# every bit as compelling as squirrels
		var grey := Color(0.45, 0.4, 0.38)
		draw_line(Vector2(-5, 1), Vector2(-14, 3 + sin(t * 5.0 + seed_o) * 2.0), Color(0.58, 0.48, 0.45), 1.5)
		draw_circle(Vector2.ZERO, 4.5, grey)
		draw_circle(Vector2(4, -1), 2.8, grey)
		draw_circle(Vector2(3.5, -3.5), 1.3, grey.darkened(0.15))
		draw_circle(Vector2(6.2, -1), 0.9, Color(0.12, 0.1, 0.1))
		return
	if kind == "cat":
		# Tofu: white with brown on top, pink harness, friendly but
		# professionally skittish
		var white := Color(0.93, 0.91, 0.88)
		var brown := Color(0.62, 0.45, 0.28)
		draw_line(Vector2(-6, 0), Vector2(-6, 0) + Vector2(-9, -6).rotated(sin(t * 2.0 + seed_o) * 0.25), brown, 2.5)
		draw_circle(Vector2.ZERO, 6.5, white)
		draw_circle(Vector2(-1, -2), 4.0, brown)
		draw_circle(Vector2(5, -3), 4.0, white)
		draw_circle(Vector2(6, -5), 2.2, brown)
		draw_line(Vector2(3, -6), Vector2(2, -9), brown, 2.0)
		draw_line(Vector2(7, -6), Vector2(8, -9), brown, 2.0)
		draw_line(Vector2(1, 0), Vector2(7, 0), Color(0.9, 0.45, 0.62), 2.0)
		if state == 1:
			draw_circle(Vector2(6, -3), 1.0, Color(0.75, 0.9, 0.3))
		return
	var body := Color(0.5, 0.33, 0.2)
	var up := state == 1
	# the tail is the whole silhouette
	draw_arc(Vector2(-7, 2), 6.0, PI * 0.2 + sin(t * 6.0 + seed_o) * 0.3, PI * 1.4, 10, body.lightened(0.15), 4.0)
	draw_circle(Vector2.ZERO, 5.5, body)
	draw_circle(Vector2(2, -6) if up else Vector2(4, -3), 3.5, body)
	draw_circle(Vector2(3, -8) if up else Vector2(5, -5), 1.2, Color(0.1, 0.08, 0.06))
