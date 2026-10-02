extends Node2D

const Clay := preload("res://entities/clay.gd")
const TofuScript := preload("res://entities/tofu.gd")

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
			var t: float = main.elapsed
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
	if not chased and dd < 26.0:
		chased = true
		main.on_critter_chase(global_position, kind)
		scare()
	if Engine.get_physics_frames() % 2 == 0:
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
	var t := AnimClock.msec() / 1000.0
	if Clay.offscreen(self, main):
		return
	# which way it looks: its own way idle, at the dog when alert, away when
	# running (the cat at her new hiding spot)
	var face := Vector2.from_angle(seed_o * 2.7)
	if state == 1 and dog != null:
		var to := dog.global_position - global_position
		if to.length() > 0.5:
			face = to.normalized()
	elif state == 2:
		face = flee_dir
		if kind == "cat" and hide_target.x < INF:
			var to := hide_target - global_position
			if to.length() > 0.5:
				face = to.normalized()
	var b := ShapeBatch.new(self)
	match kind:
		"rat":
			_draw_rat(b, face, t)
		"cat":
			Clay.ground_shadow(b, Vector2.ZERO, 9.0, 6.0, 4.0, 0.24)
			TofuScript.draw_cat(b, Vector2.ZERO, face, TofuScript.TOFU_COAT, 1.0 if state == 2 else 0.0, 0.0,
				sin(t * 2.0 + seed_o) * 0.45, state == 1, 1.1)
		_:
			_draw_squirrel(b, face, t)
	b.flush()


# a squirrel from above: a small russet body, and the tail - the whole
# silhouette - a big fluffy plume curling up over its back
func _draw_squirrel(b: ShapeBatch, face: Vector2, t: float) -> void:
	var fwd := face
	var side := fwd.orthogonal()
	var body := Color(0.66, 0.36, 0.17)
	var belly := Color(0.93, 0.82, 0.64)
	var up := state == 1
	var run := 1.0 if state == 2 else 0.0
	var flick := sin(t * (14.0 if up else 6.0) + seed_o) * (0.5 if up else 0.25)
	Clay.ground_shadow(b, Vector2.ZERO, 7.0, 4.5, 3.0, 0.22)
	# the tail: three puffs swinging out behind and curling round
	var tail_root := -fwd * 4.5
	var curl := 1.0 - run
	var d1 := (-fwd).rotated((0.6 * curl + flick) * 0.5)
	var d2 := (-fwd).rotated(1.3 * curl + flick)
	var plume := body.lightened(0.12)
	Clay.blob(b, tail_root + d1 * 4.0, Vector2(5.0, 3.4), d1, plume)
	Clay.ball(b, tail_root + d1 * 5.0 + d2 * 4.0, 4.0, plume)
	b.draw_circle(tail_root + d1 * 5.0 + d2 * 5.5, 1.6, plume.lightened(0.25))
	# hind feet, body, and the front paws held up at the chest when alert
	for sd: float in [-1.0, 1.0]:
		b.draw_circle(-fwd * 2.5 + side * 3.6 * sd, 1.4, body.darkened(0.2))
	Clay.blob(b, Vector2.ZERO, Vector2(5.0 + run, 3.6), fwd, body)
	var hc := fwd * (5.5 + run)
	if up:
		for sd: float in [-1.0, 1.0]:
			b.draw_circle(fwd * 3.6 + side * 1.6 * sd, 1.1, belly)
	Clay.ball(b, hc, 3.0, body)
	for sd: float in [-1.0, 1.0]:
		# tufted ears, and the bright black eyes
		b.draw_circle(hc - fwd * 1.0 + side * 2.4 * sd, 1.1, body.darkened(0.25))
		b.draw_circle(hc + fwd * 0.9 + side * 1.6 * sd, 0.8, Color(0.08, 0.06, 0.05))
	b.draw_circle(hc + fwd * 2.8, 0.7, Color(0.25, 0.15, 0.12))


# a rat from above: a grey teardrop, pink ears and a long bare tail
func _draw_rat(b: ShapeBatch, face: Vector2, t: float) -> void:
	var fwd := face
	var side := fwd.orthogonal()
	var grey := Color(0.47, 0.43, 0.41)
	var pink := Color(0.86, 0.62, 0.60)
	Clay.ground_shadow(b, Vector2.ZERO, 6.0, 3.6, 2.0, 0.20)
	var tail := PackedVector2Array()
	for k in range(5):
		var f := float(k) / 4.0
		tail.append(-fwd * (4.5 + f * 10.0) + side * sin(t * 5.0 + seed_o + f * 2.5) * f * 2.5)
	Clay.stroke(b, tail, 1.4, 0.6, pink.darkened(0.15))
	Clay.blob(b, Vector2.ZERO, Vector2(5.2, 3.2), fwd, grey)
	var hc := fwd * 4.6
	b.draw_colored_polygon(PackedVector2Array([hc - side * 2.2, hc + fwd * 3.6, hc + side * 2.2]), grey)
	for sd: float in [-1.0, 1.0]:
		b.draw_circle(hc - fwd * 0.6 + side * 2.1 * sd, 1.2, pink)
		b.draw_circle(hc + fwd * 1.2 + side * 1.0 * sd, 0.55, Color(0.08, 0.06, 0.06))
	b.draw_circle(hc + fwd * 3.6, 0.6, pink.darkened(0.2))
