extends Node2D

const Clay := preload("res://entities/clay.gd")

# A duck family member crossing the path in a line: mother in front,
# ducklings behind. A moving no-go zone - disturbing them is quest
# failure material, not points. They hop away flustered and regroup.

var main: Node2D
var dog: Node2D
var vel := Vector2.ZERO
var leader := false
var flustered := false
var noted := false
var bob_seed := 0.0


func setup(m: Node2D, d: Node2D, direction: float, is_leader: bool) -> void:
	add_to_group("ducklings")
	main = m
	dog = d
	vel = Vector2(direction * 42.0, 0)
	leader = is_leader
	bob_seed = randf() * 10.0


func _physics_process(delta: float) -> void:
	if main.frozen:
		return
	# ducks fear everything with legs or wheels, as is wise
	var threat_pos: Vector2 = dog.global_position
	var dd: float = global_position.distance_to(dog.global_position)
	var hd: float = global_position.distance_to(main.human.global_position)
	if hd < dd:
		dd = hd
		threat_pos = main.human.global_position
	for b in main.riders_cache:
		var bd: float = global_position.distance_to(b.global_position)
		if bd < dd:
			dd = bd
			threat_pos = b.global_position
	if dd < 36.0 and not flustered:
		flustered = true
		if not noted:
			noted = true
			main.on_duck_disturbed(global_position)
	if flustered:
		position += (global_position - threat_pos).normalized() * 130.0 * delta
		if dd > 75.0:
			flustered = false
	else:
		position += vel * delta
		position.y += sin(float(main.elapsed) * 8.0 + bob_seed) * 6.0 * delta
	if position.x < 240.0 or position.x > 1040.0:
		queue_free()
	if Engine.get_physics_frames() % 2 == 0:
		queue_redraw()


func _draw() -> void:
	if Clay.offscreen(self, main):
		return
	var t := AnimClock.msec() / 1000.0
	var fwd := Vector2(signf(vel.x) if vel.x != 0.0 else 1.0, 0.0)
	if flustered and dog != null:
		var away := global_position - dog.global_position
		if away.length() > 0.5:
			fwd = away.normalized()
	# the waddle: a rock from side to side, quicker when flustered
	fwd = fwd.rotated(sin(t * (16.0 if flustered else 8.0) + bob_seed) * 0.12)
	var side := fwd.orthogonal()
	var b := ShapeBatch.new(self)
	var bill := Color(0.95, 0.58, 0.16)
	if leader:
		# a mallard hen from above: a speckled brown teardrop, the folded
		# wings meeting at the tail, a blue flash on each, an orange bill
		var brown := Color(0.55, 0.42, 0.27)
		Clay.ground_shadow(b, Vector2.ZERO, 9.0, 5.5, 3.0, 0.22)
		b.draw_colored_polygon(PackedVector2Array([
			-fwd * 6.0 + side * 3.0, -fwd * 12.0, -fwd * 6.0 - side * 3.0]), brown.darkened(0.30))
		Clay.blob(b, Vector2.ZERO, Vector2(8.0, 5.6), fwd, brown)
		for sd: float in [-1.0, 1.0]:
			# the folded wing, with its blue speculum
			b.draw_colored_polygon(PackedVector2Array([
				fwd * 3.0 + side * sd * 5.0, -fwd * 9.0 + side * sd * 1.0, -fwd * 4.0 + side * sd * 5.2]),
				brown.darkened(0.18))
			b.draw_line(-fwd * 1.5 + side * sd * 4.8, -fwd * 4.5 + side * sd * 4.4, Color(0.25, 0.38, 0.78), 1.4)
		for k in range(4):
			b.draw_circle(fwd * (2.0 - float(k) * 2.2) + side * (float(k % 2) * 2.0 - 1.0), 0.7, brown.darkened(0.35))
		var hc := fwd * 8.0
		Clay.ball(b, hc, 3.4, brown.lightened(0.05))
		b.draw_line(hc - side * 2.9 + fwd * 0.4, hc + side * 2.9 + fwd * 0.4, brown.darkened(0.35), 0.8)
		b.draw_colored_polygon(Clay.ellipse_pts(hc + fwd * 4.0, Vector2(2.2, 1.5), fwd, 10), bill)
		for sd: float in [-1.0, 1.0]:
			b.draw_circle(hc + fwd * 0.8 + side * sd * 1.8, 0.65, Color(0.06, 0.05, 0.04))
	else:
		# a duckling: a yellow fluff ball with a smudge of brown down its back
		var fluff := Color(0.98, 0.86, 0.36)
		Clay.ground_shadow(b, Vector2.ZERO, 5.0, 3.2, 2.0, 0.20)
		Clay.ball(b, -fwd * 0.5, 4.2, fluff)
		b.draw_colored_polygon(Clay.ellipse_pts(-fwd * 1.5, Vector2(2.4, 1.6), fwd, 10), Color(0.62, 0.50, 0.26, 0.75))
		var hc := fwd * 3.6
		Clay.ball(b, hc, 2.4, fluff)
		b.draw_circle(hc + fwd * 2.4, 1.0, bill)
		for sd: float in [-1.0, 1.0]:
			b.draw_circle(hc + fwd * 0.6 + side * sd * 1.3, 0.5, Color(0.06, 0.05, 0.04))
	b.flush()
