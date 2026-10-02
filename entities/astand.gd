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


const WOOD := Color(0.64, 0.47, 0.30)
const SLATE := Color(0.20, 0.25, 0.23)
const CHALK := Color(0.94, 0.93, 0.88, 0.85)


# Standing, it is an A-frame seen from above: two chalkboards leaning on a
# hinge across the middle, the one facing the light paler than the one
# facing away, a tall shadow. Flat on its face it is one board, scrawled
# with the day's menu. One ShapeBatch, so one draw call.
func _draw() -> void:
	var w := 22.0
	var h := lerpf(28.0, 40.0, tip)
	var b := ShapeBatch.new(self)
	if tip > 0.0:
		b.draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 1.0 - tip * 0.3))
	var lift := 1.0 - tip
	b.rect(Rect2(-w / 2.0 + 1.0 + 4.0 * lift, -h / 2.0 + 2.0 + 6.0 * lift, w, h), Color(0.05, 0.05, 0.08, 0.18))
	b.rect(Rect2(-w / 2.0, -h / 2.0, w, h), WOOD.darkened(0.30))
	b.rect(Rect2(-w / 2.0, -h / 2.0, w - 1.5, h - 1.5), WOOD)
	if tip < 0.5:
		# the north board catches the light, the south one leans away from it
		b.rect(Rect2(-w / 2.0 + 2.5, -h / 2.0 + 2.5, w - 5.0, h / 2.0 - 4.0), SLATE.lightened(0.10))
		b.rect(Rect2(-w / 2.0 + 2.5, 1.5, w - 5.0, h / 2.0 - 4.0), SLATE.darkened(0.25))
		b.line(Vector2(-w / 2.0, 0), Vector2(w / 2.0, 0), WOOD.lightened(0.15), 2.0)
		b.circle(Vector2(-w / 2.0 + 2.0, 0), 1.3, Color(0.30, 0.30, 0.32))
		b.circle(Vector2(w / 2.0 - 2.0, 0), 1.3, Color(0.30, 0.30, 0.32))
		b.line(Vector2(-6, -9), Vector2(5, -9), CHALK, 1.6)
		b.line(Vector2(-6, -5), Vector2(2, -5), Color(0.96, 0.70, 0.40, 0.85), 1.6)
		b.line(Vector2(-6, 6), Vector2(4, 6), Color(CHALK.r, CHALK.g, CHALK.b, 0.45), 1.4)
	else:
		b.rect(Rect2(-w / 2.0 + 2.5, -h / 2.0 + 2.5, w - 5.0, h - 5.0), SLATE)
		b.line(Vector2(-6, -11), Vector2(6, -11), CHALK, 1.8)
		b.line(Vector2(-6, -5), Vector2(4, -5), CHALK, 1.6)
		b.line(Vector2(-6, 1), Vector2(6, 1), CHALK, 1.6)
		b.line(Vector2(-6, 8), Vector2(2, 8), Color(0.96, 0.70, 0.40, 0.85), 1.8)
	b.flush()
	if tip > 0.0:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
