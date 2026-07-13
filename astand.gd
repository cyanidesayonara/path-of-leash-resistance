extends Node2D

# A sandwich board. Light, proud, and doomed: bodies knock it over and a
# taut leash sweeps it flat. Nobody ever stands it back up.

var main: Node2D
var dog: Node2D
var human: Node2D
var fallen := false
var tip := 0.0
var fall_dir := Vector2.RIGHT


func setup(m: Node2D, d: Node2D, h: Node2D) -> void:
	main = m
	dog = d
	human = h


func _physics_process(delta: float) -> void:
	if main.frozen:
		return
	if not fallen:
		if global_position.distance_to(dog.global_position) < 24.0:
			_topple((global_position - dog.global_position).normalized())
		elif global_position.distance_to(human.global_position) < 26.0:
			_topple((global_position - human.global_position).normalized())
		elif main.leash.taut:
			for rp in main.leash.pts:
				if global_position.distance_to(rp) < 14.0:
					_topple((global_position - dog.global_position).normalized())
					break
		if not fallen:
			for b in main.riders_cache:
				if global_position.distance_to(b.global_position) < 26.0:
					_topple((b.vel as Vector2).normalized())
					break
	elif tip < 1.0:
		tip = minf(tip + delta * 4.0, 1.0)
		position += fall_dir * 34.0 * delta * (1.0 - tip)
		queue_redraw()
		if tip >= 1.0:
			# flat is forever; stop thinking about it
			set_physics_process(false)


func _topple(dir: Vector2) -> void:
	fallen = true
	fall_dir = dir
	rotation = dir.angle()
	main.float_text(global_position, "clatter", Color(0.9, 0.9, 0.9))
	queue_redraw()


func _draw() -> void:
	var w := 22.0
	var h := lerpf(28.0, 40.0, tip)
	if tip > 0.0:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 1.0 - tip * 0.3))
	draw_rect(Rect2(-w / 2.0 - 2, -h / 2.0 + 3, w, h), Color(0, 0, 0, 0.12))
	draw_rect(Rect2(-w / 2.0, -h / 2.0, w, h), Color(0.92, 0.88, 0.8))
	draw_rect(Rect2(-w / 2.0, -h / 2.0, w, h), Color(0.4, 0.36, 0.3), false, 2.0)
	draw_line(Vector2(-6, -6), Vector2(6, -6), Color(0.5, 0.45, 0.38), 2.0)
	draw_line(Vector2(-6, 0), Vector2(6, 0), Color(0.5, 0.45, 0.38), 2.0)
	draw_line(Vector2(-6, 6), Vector2(2, 6), Color(0.75, 0.4, 0.3), 2.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
