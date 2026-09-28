extends Node2D

# One of La Rambla's crowd: a tourist ambling up or down the promenade,
# stopping now and then for a photo. The crowd is what the pickpockets work,
# and what the dog and her owner have to thread. Tourists are not bodies: they
# step aside from the dog, the owner and each other rather than blocking, so a
# crowd can be dense without ever wedging the walk shut.
#
# Self-managing and order-independent, like the other critters and bikes.

const WALK_MIN := 34.0
const WALK_MAX := 58.0
const GIVE_WAY_R := 34.0       # step aside from anything this close
const PHOTO_T := 2.2

var main: Node2D
var rng: RandomNumberGenerator
var dir := -1.0                # -1 walking north (up the screen), +1 south
var speed := 45.0
var lane_x := 640.0            # where across the promenade they walk
var photo_t := 0.0
var next_photo := 6.0
var col := Color.WHITE
var hair := Color.BLACK
var has_wallet := true
var robbed_t := 0.0            # the "!" after a lift
var cheer_t := 0.0             # clapping for a dog who got a wallet back
var look := "map"              # what they are holding: map, camera, stick


func setup(m: Node2D, r: RandomNumberGenerator, at: Vector2, d: float) -> void:
	add_to_group("tourists")
	main = m
	rng = r
	global_position = at
	lane_x = at.x
	dir = d
	speed = rng.randf_range(WALK_MIN, WALK_MAX)
	next_photo = rng.randf_range(4.0, 12.0)
	col = [Color(0.92, 0.45, 0.35), Color(0.35, 0.60, 0.85), Color(0.95, 0.85, 0.40),
		Color(0.55, 0.75, 0.45), Color(0.85, 0.85, 0.88), Color(0.70, 0.45, 0.75)][rng.randi() % 6]
	hair = [Color(0.15, 0.12, 0.10), Color(0.55, 0.40, 0.22), Color(0.85, 0.75, 0.50), Color(0.60, 0.60, 0.62)][rng.randi() % 4]
	look = ["map", "camera", "stick", "map"][rng.randi() % 4]


func is_stopped() -> bool:
	return photo_t > 0.0


func robbed() -> void:
	has_wallet = false
	robbed_t = 1.2


func cheer() -> void:
	cheer_t = 1.8


func _physics_process(delta: float) -> void:
	if main.frozen:
		return
	robbed_t = maxf(0.0, robbed_t - delta)
	cheer_t = maxf(0.0, cheer_t - delta)
	if photo_t > 0.0:
		photo_t -= delta
		return
	next_photo -= delta
	if next_photo <= 0.0:
		photo_t = PHOTO_T
		next_photo = rng.randf_range(8.0, 16.0)
		return
	var e: Vector2 = main.walk_edges(global_position.y)
	lane_x = clampf(lane_x, e.x + 30.0, e.y - 30.0)
	var step := Vector2(0.0, dir * speed)
	# drift back to their line, and give way to whatever is in the road
	step.x = (lane_x - global_position.x) * 1.5
	for other: Node2D in [main.dog, main.human]:
		var away: Vector2 = global_position - other.global_position
		if away.length() < GIVE_WAY_R + 14.0:
			step.x += signf(away.x + 0.01) * 90.0
	global_position += step * delta
	global_position.x = clampf(global_position.x, e.x + 16.0, e.y - 16.0)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var t := AnimClock.msec() / 1000.0
	var bob := 0.0 if photo_t > 0.0 else sin(t * 7.0 + lane_x) * 1.2
	var b := ShapeBatch.new()
	b.circle(Vector2(3, 4), 11.0, Color(0, 0, 0, 0.18))
	b.circle(Vector2(0, bob), 11.0, col)
	b.circle(Vector2(0, -4.0 + bob), 6.5, Color(0.90, 0.74, 0.60))
	b.circle(Vector2(0, -6.0 + bob), 5.5, hair)
	var fwd := Vector2(0, dir)
	match look:
		"map":
			b.rect(Rect2(-8.0, dir * 10.0 - 4.0 + bob, 16.0, 8.0), Color(0.95, 0.93, 0.85))
			b.line(Vector2(-2, dir * 10.0 - 4.0 + bob), Vector2(-2, dir * 10.0 + 4.0 + bob), Color(0.6, 0.7, 0.8), 1.0)
		"camera":
			b.rect(Rect2(-4.0, dir * 11.0 - 3.0 + bob, 8.0, 6.0), Color(0.12, 0.12, 0.14))
		"stick":
			var tip := fwd * (26.0 if photo_t > 0.0 else 14.0) + Vector2(8, 0)
			b.line(Vector2(4, 0), tip, Color(0.3, 0.3, 0.32), 1.5)
			b.rect(Rect2(tip.x - 3.0, tip.y - 2.0, 6.0, 4.0), Color(0.1, 0.1, 0.12))
	if photo_t > 0.0 and fmod(photo_t, 0.9) < 0.08:
		b.circle(fwd * 16.0, 7.0, Color(1, 1, 0.9, 0.8))     # the flash
	b.flush(self)
	if robbed_t > 0.0:
		draw_string(ThemeDB.fallback_font, Vector2(-4, -18), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 0.5, 0.4))
	if cheer_t > 0.0 and fmod(t, 0.3) < 0.15:
		draw_line(Vector2(-10, -8), Vector2(-4, -12), Color(1, 1, 1, 0.8), 1.5)
		draw_line(Vector2(10, -8), Vector2(4, -12), Color(1, 1, 1, 0.8), 1.5)
