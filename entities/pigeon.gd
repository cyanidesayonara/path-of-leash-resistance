extends Node2D

const Clay := preload("res://entities/clay.gd")

# A pigeon. Waddles around minding its own business until someone gets
# close, then the whole flock scatters. Pure distraction; scattering a
# flock is its own reward. At El Mosaic it is a monk parakeet instead,
# feeding under the palms: green, loud, and off over the terrace wall.

var main: Node2D
var dog: Node2D
var human: Node2D
var flying := false
var gull := false
var parakeet := false
var wall_side := 0.0           # a parakeet flies off over this side's wall
var fly_dir := Vector2.UP
var wander_t := 0.0
var seed_o := 0.0


func setup(m: Node2D, d: Node2D, h: Node2D, is_gull: bool = false) -> void:
	add_to_group("pigeons")
	main = m
	dog = d
	human = h
	gull = is_gull
	seed_o = randf() * 10.0


func make_parakeet(side: float) -> void:
	parakeet = true
	wall_side = side


func _physics_process(delta: float) -> void:
	if main.frozen:
		return
	if flying:
		position += fly_dir * 430.0 * delta
		if absf(global_position.y - float(main.cam.position.y)) > 700.0:
			queue_free()
	else:
		wander_t -= delta
		if wander_t <= 0.0:
			wander_t = randf_range(0.5, 1.4)
			position += Vector2(randf_range(-9.0, 9.0), randf_range(-9.0, 9.0))
		var threat := minf(
			global_position.distance_to(dog.global_position),
			global_position.distance_to(human.global_position))
		if threat < 70.0:
			scare()
		else:
			# traffic scatters pigeons too
			for b in main.riders_cache:
				if global_position.distance_to(b.global_position) < 90.0:
					scare()
					break
	if Engine.get_physics_frames() % 2 == 0:
		queue_redraw()


func scare() -> void:
	if flying:
		return
	flying = true
	fly_dir = (global_position - dog.global_position).normalized().rotated(randf_range(-0.5, 0.5))
	if parakeet:
		# up into the palms over the wall, all shouting about it
		fly_dir = Vector2(wall_side, randf_range(-0.9, -0.2)).normalized()
		main.parakeet_squawk(global_position)


func _draw() -> void:
	if Clay.offscreen(self, main):
		return
	var t := AnimClock.msec() / 1000.0
	var fwd := fly_dir.normalized() if flying else Vector2.from_angle(seed_o * 2.3)
	var side := fwd.orthogonal()
	# the look of each bird: body, wings, wingtips, head, bill
	var body := Color(0.58, 0.60, 0.66)
	var wing := Color(0.66, 0.68, 0.74)
	var tip := Color(0.30, 0.30, 0.36)
	var head := Color(0.48, 0.50, 0.58)
	var bill := Color(0.30, 0.28, 0.30)
	var s := 1.2
	if gull:
		body = Color(0.96, 0.96, 0.95)
		wing = Color(0.72, 0.75, 0.80)
		tip = Color(0.12, 0.12, 0.14)
		head = Color(0.98, 0.98, 0.97)
		bill = Color(0.96, 0.80, 0.22)
		s = 1.55
	elif parakeet:
		body = Color(0.42, 0.74, 0.30)
		wing = Color(0.32, 0.62, 0.26)
		tip = Color(0.24, 0.42, 0.62)
		head = Color(0.72, 0.80, 0.70)
		bill = Color(0.95, 0.72, 0.40)
	var b := ShapeBatch.new(self)
	if flying:
		# wings spread wide from above, beating; the shadow left far below
		var flap := sin(t * 24.0 + seed_o)
		Clay.ground_shadow(b, Vector2.ZERO, 6.0 * s, 3.0 * s, 16.0, 0.14)
		for sd: float in [-1.0, 1.0]:
			var span := (9.0 + flap * 3.0) * s
			var root := side * sd * 2.0 * s
			var wtip := side * sd * span - fwd * (2.0 + flap) * s
			b.draw_colored_polygon(PackedVector2Array([root + fwd * 2.5 * s, wtip, root - fwd * 3.0 * s]), wing)
			b.draw_colored_polygon(PackedVector2Array([wtip, wtip.lerp(root + fwd * 2.5 * s, 0.3), wtip.lerp(root - fwd * 3.0 * s, 0.3)]), tip)
	else:
		Clay.ground_shadow(b, Vector2.ZERO, 5.5 * s, 3.4 * s, 2.0, 0.20)
	# the tail fan
	b.draw_colored_polygon(PackedVector2Array([
		-fwd * 3.5 * s + side * 1.8 * s, -fwd * (parakeet_tail() * s), -fwd * 3.5 * s - side * 1.8 * s]), tip if not gull else wing)
	Clay.blob(b, Vector2.ZERO, Vector2(5.0, 3.4) * s, fwd, body)
	if not flying:
		# folded wings down the back, wingtips crossing at the tail
		for sd: float in [-1.0, 1.0]:
			b.draw_colored_polygon(PackedVector2Array([
				fwd * 2.0 * s + side * sd * 2.9 * s, -fwd * 5.5 * s + side * sd * 0.6 * s, -fwd * 2.0 * s + side * sd * 3.3 * s]), wing)
			b.draw_colored_polygon(PackedVector2Array([
				-fwd * 3.0 * s + side * sd * 2.0 * s, -fwd * 5.8 * s, -fwd * 4.2 * s + side * sd * 0.4 * s]), tip)
		if not gull and not parakeet:
			# the pigeon's two dark wing bars
			for k in range(2):
				var x := -0.5 - float(k) * 1.6
				b.draw_line((fwd * x + side * 3.0) * s, (fwd * (x - 0.6) + side * 1.0) * s, tip, 0.9 * s)
				b.draw_line((fwd * x - side * 3.0) * s, (fwd * (x - 0.6) - side * 1.0) * s, tip, 0.9 * s)
	# the head, nodding forward as it walks
	var nod := 0.0 if flying else maxf(0.0, sin(t * 7.0 + seed_o)) * 1.3
	var hc := fwd * (4.2 * s + nod)
	if not gull and not parakeet:
		# the green and purple sheen round the neck
		b.draw_circle(fwd * 3.2 * s, 2.6 * s, Color(0.36, 0.56, 0.48))
		b.draw_circle((fwd * 3.0 - side * 0.8) * s, 1.6 * s, Color(0.55, 0.40, 0.60))
	Clay.ball(b, hc, 2.3 * s, head)
	b.draw_colored_polygon(PackedVector2Array([hc + fwd * 1.8 * s + side * 0.8 * s, hc + fwd * 3.8 * s, hc + fwd * 1.8 * s - side * 0.8 * s]), bill)
	if gull:
		b.draw_circle(hc + fwd * 3.0 * s + side * 0.3, 0.45 * s, Color(0.85, 0.20, 0.15))
	for sd: float in [-1.0, 1.0]:
		b.draw_circle(hc + fwd * 0.5 * s + side * sd * 1.3 * s, 0.5 * s, Color(0.95, 0.55, 0.20) if not parakeet else Color(0.06, 0.05, 0.05))
	b.flush()


# how far back the tail reaches: a parakeet's is long and tapering
func parakeet_tail() -> float:
	return 11.0 if parakeet else 7.0
