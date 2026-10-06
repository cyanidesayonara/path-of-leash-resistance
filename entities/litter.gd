extends Node2D

# A paper bag loose on Montjuïc's wind (systems/montjuic.gd blow_litter):
# every gust shoves it on along the path in skittering hops, and between
# gusts it drifts and settles. She catches it with a pounce, at speed. Self
# managing, like the sunhat: it reads the wind, the dog and the human.

const GUST_PUSH := 420.0       # px/s/s along the wind while a gust blows
const DRAG := 120.0
const DRIFT := 14.0            # the lazy creep it keeps up between gusts
const CATCH_R := 20.0
const POUNCE := 120.0          # she has to be moving at least this fast
const GONE_BEHIND := 720.0
const GONE_AHEAD := 900.0
const EDGE_IN := 10.0
# white paper, not brown: brown vanishes on a sandy path
const PAPER := Color(0.96, 0.95, 0.91)
const INK := Color(0.45, 0.43, 0.40)

var main: Node2D
var vel := Vector2.ZERO
var hop := 0.0
var lift := 0.0
var spin := 0.0
var _bag := PackedVector2Array([Vector2(-9, -8), Vector2(1, -10), Vector2(10, -5),
	Vector2(8, 8), Vector2(-2, 10), Vector2(-10, 4), Vector2(-9, -8)])
var _fold := PackedVector2Array([Vector2(-6, -2), Vector2(0, 1), Vector2(6, -1)])


func setup(m: Node2D, at: Vector2, v: Vector2) -> void:
	main = m
	global_position = at
	vel = v
	# from where it starts, not the global RNG, which the walk's sequence uses
	spin = fmod(absf(at.x) * 0.37 + absf(at.y) * 0.11, TAU)
	z_index = 2


func _physics_process(delta: float) -> void:
	if main == null or main.frozen:
		return
	if main.phase == "freedom":
		queue_free()
		return
	var wind: Vector2 = main.wind_dir
	if float(main.wind_gust) > 0.0:
		vel += wind * GUST_PUSH * delta
	vel = vel.move_toward(wind * DRIFT, DRAG * delta)
	global_position += vel * delta
	var sp := vel.length()
	# skittering hops: the faster it goes, the more it leaves the ground
	hop += delta * (4.0 + sp / 40.0)
	lift = absf(sin(hop)) * clampf(sp / 30.0, 0.0, 9.0)
	spin += delta * sp / 25.0 * signf(vel.x if absf(vel.x) > 0.1 else 1.0)
	_keep_on_path()
	var dog: Node2D = main.dog
	if global_position.distance_to(dog.global_position) < CATCH_R and dog.velocity.length() > POUNCE \
			and not dog.is_tumbling():
		main.on_litter_caught(global_position)
		queue_free()
		return
	var dy: float = global_position.y - main.human.global_position.y
	if dy > GONE_BEHIND or dy < -GONE_AHEAD:
		queue_free()
		return
	queue_redraw()


func _keep_on_path() -> void:
	var e: Vector2 = main.walk_edges(global_position.y)
	var lo := e.x + EDGE_IN
	var hi := e.y - EDGE_IN
	if hi <= lo:
		return
	if global_position.x < lo:
		global_position.x = lo
		vel.x = absf(vel.x) * 0.3
	elif global_position.x > hi:
		global_position.x = hi
		vel.x = -absf(vel.x) * 0.3


func _draw() -> void:
	main.contact_shadow(self, Vector2.ZERO, 10.0, 3.0 + lift * 0.5, 0.18)
	# a crumpled paper bag: a lumpy white square with its folds, turning over
	draw_set_transform(Vector2(0, -lift), spin, Vector2(1.0, 0.7 + 0.3 * absf(cos(spin * 0.7))))
	draw_colored_polygon(_bag, PAPER)
	draw_polyline(_bag, INK, 1.2)
	draw_polyline(_fold, INK, 1.0)
	draw_line(Vector2(0, 1), Vector2(-1, 7), INK, 1.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
