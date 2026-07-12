extends Node2D

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
	var dd: float = global_position.distance_to(dog.global_position)
	if dd < 36.0 and not flustered:
		flustered = true
		if not noted:
			noted = true
			main.on_duck_disturbed(global_position)
	if flustered:
		position += (global_position - dog.global_position).normalized() * 130.0 * delta
		if dd > 75.0:
			flustered = false
	else:
		position += vel * delta
		position.y += sin(Time.get_ticks_msec() / 1000.0 * 8.0 + bob_seed) * 6.0 * delta
	if position.x < 240.0 or position.x > 1040.0:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var c := Color(0.45, 0.35, 0.2) if leader else Color(0.95, 0.85, 0.35)
	var r := 6.5 if leader else 3.5
	var fx := signf(vel.x)
	draw_circle(Vector2.ZERO, r, c)
	draw_circle(Vector2(fx * (r - 1.0), -1.5), r * 0.55, c)
	draw_circle(Vector2(fx * (r + 1.5), -1.8), 1.0, Color(0.9, 0.55, 0.15))
