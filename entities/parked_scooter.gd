extends Node2D

# A parked scooter is tall enough for its handlebars to meet the strap, but
# too light to become a permanent anchor. Bodies or a taut crossing tip it.

const HIT_R := 15.0

var main: Node2D
var fallen := false


func setup(m: Node2D) -> void:
	main = m
	add_to_group("parked_scooters")


func _physics_process(_delta: float) -> void:
	if fallen or main == null or main.frozen:
		return
	var hit := Vector2.ZERO
	for body: Node2D in [main.dog, main.human]:
		if global_position.distance_to(body.global_position) < 25.0:
			hit = global_position - body.global_position
			break
	if hit == Vector2.ZERO and main.leash.taut:
		for i in range(main.leash.pts.size() - 1):
			var a: Vector2 = main.leash.pts[i]
			var b: Vector2 = main.leash.pts[i + 1]
			var ab := b - a
			var at := a
			if ab.length_squared() > 0.001:
				at += ab * clampf((global_position - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
			if at.distance_to(global_position) < HIT_R:
				hit = global_position - main.dog.global_position
				break
	if hit != Vector2.ZERO:
		_topple(hit)


func _topple(dir: Vector2) -> void:
	fallen = true
	var side := dir.normalized()
	if side == Vector2.ZERO:
		side = Vector2.RIGHT
	main.scooter_falls[global_position] = side
	main.float_text(global_position, "clatter", Color(0.9, 0.9, 0.9))
	Sfx.play("tangle", 1.1, -10.0)
	set_physics_process(false)
