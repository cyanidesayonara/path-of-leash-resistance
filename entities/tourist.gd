extends Node2D

const HumanLook := preload("res://entities/human_appearance.gd")

# One of La Rambla's or El Mosaic's crowd: a tourist ambling up or down the
# promenade, stopping now and then for a photo; or, at El Mosaic, standing in
# the queue at the gate, or posing round the salamander for photos of it (and
# of any dog who comes up to drink). The crowd is what the pickpockets work,
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
var mode := "amble"            # amble | queue | pose
var anchor := Vector2.ZERO     # where a queuer or poser stands
var face := Vector2.ZERO       # what a poser photographs
var shuffle_t := 0.0           # the queue edging forward


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


# stand in one place instead of walking: in the gate queue, or posing and
# photographing `at`
func stand(how: String, at: Vector2) -> void:
	mode = how
	anchor = global_position
	face = at
	shuffle_t = rng.randf_range(3.0, 7.0)
	if how == "pose":
		look = "camera" if rng.randf() < 0.6 else "stick"
		next_photo = rng.randf_range(0.5, 3.0)


func facing() -> Vector2:
	if mode == "amble":
		return Vector2(0.0, dir)
	var to_dog: Vector2 = main.dog.global_position - global_position
	# a poser turns to photograph a dog who comes close
	if mode == "pose" and to_dog.length() < 130.0:
		return to_dog.normalized()
	if mode == "queue":
		return Vector2.UP
	var to := face - global_position
	return to.normalized() if to.length() > 1.0 else Vector2.UP


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
	if mode != "amble":
		_tick_standing(delta)
		return
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


func _tick_standing(delta: float) -> void:
	if mode == "pose":
		photo_t = maxf(0.0, photo_t - delta)
		next_photo -= delta
		if next_photo <= 0.0:
			photo_t = PHOTO_T * 0.6
			next_photo = rng.randf_range(2.5, 6.0)
	else:
		# the queue edges forward a step, then the next person closes up
		shuffle_t -= delta
		if shuffle_t <= 0.0:
			shuffle_t = rng.randf_range(4.0, 8.0)
			anchor.y -= 6.0
	# step aside for the dog and her human, then back into place
	var home := anchor
	for other: Node2D in [main.dog, main.human]:
		var away: Vector2 = global_position - other.global_position
		if away.length() < GIVE_WAY_R + 14.0:
			home += away.normalized() * (GIVE_WAY_R + 16.0 - away.length())
	global_position = global_position.lerp(home, minf(1.0, delta * 6.0))


const SKINS := [Color(0.92, 0.76, 0.62), Color(0.62, 0.44, 0.32), Color(0.82, 0.64, 0.50), Color(0.45, 0.30, 0.22)]


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var t := AnimClock.msec() / 1000.0
	var bob := 0.0 if photo_t > 0.0 or mode != "amble" else sin(t * 7.0 + lane_x) * 1.2
	var b := ShapeBatch.new(self)
	b.circle(Vector2(3, 4), 11.0, Color(0, 0, 0, 0.18))
	var fwd := facing()
	# drawn like every other person: from above, dressed for the weather,
	# and a holiday look of their own (a cap or a sunhat, now and then)
	var k := int(absf(lane_x) * 7.0) + int(col.r * 100.0)
	var own_hat: String = ["none", "cap", "none", "sunhat"][k % 4]
	var dress: Dictionary = HumanLook.outfit(Game.weather, Game.level_id, Game.night, k, col, own_hat,
		[Color(0.92, 0.84, 0.62), Color(0.86, 0.30, 0.28), Color(0.25, 0.45, 0.70)][k % 3], "none")
	var skin: Color = SKINS[k % SKINS.size()]
	var c0 := Vector2(0, bob)
	for sg: float in [-1.0, 1.0]:
		b.polygon(HumanLook._disc_points(c0 + fwd.orthogonal() * 4.5 * sg + fwd * 3.0, Vector2(4.0, 3.0), fwd),
			Color(0.24, 0.22, 0.24))
	HumanLook.draw_torso(b, c0, fwd, Vector2(9.0, 11.5), dress["shirt"], bool(dress["coat"]), dress["scarf"])
	HumanLook.draw_head(b, c0 + fwd * 3.0, fwd, 6.4, skin, hair, ["short", "long", "curly", "bun", "short"][k % 5],
		String(dress["headwear"]), dress["headwear_col"])
	if String(dress["eyewear"]) == "sunglasses":
		var sd := fwd.orthogonal()
		b.circle(c0 + fwd * 7.2 + sd * 2.3, 1.7, Color(0.08, 0.08, 0.1))
		b.circle(c0 + fwd * 7.2 - sd * 2.3, 1.7, Color(0.08, 0.08, 0.1))
	match look:
		"map":
			var mp := fwd * 10.0 + Vector2(0.0, bob)
			b.rect(Rect2(mp.x - 8.0, mp.y - 4.0, 16.0, 8.0), Color(0.95, 0.93, 0.85))
			b.line(mp + Vector2(-2, -4), mp + Vector2(-2, 4), Color(0.6, 0.7, 0.8), 1.0)
		"camera":
			var cp := fwd * 11.0 + Vector2(0.0, bob)
			b.rect(Rect2(cp.x - 4.0, cp.y - 3.0, 8.0, 6.0), Color(0.12, 0.12, 0.14))
		"stick":
			var tip := fwd * (26.0 if photo_t > 0.0 else 14.0) + fwd.orthogonal() * 8.0
			b.line(fwd.orthogonal() * 4.0, tip, Color(0.3, 0.3, 0.32), 1.5)
			b.rect(Rect2(tip.x - 3.0, tip.y - 2.0, 6.0, 4.0), Color(0.1, 0.1, 0.12))
	if photo_t > 0.0 and fmod(photo_t, 0.9) < 0.08:
		b.circle(fwd * 16.0, 7.0, Color(1, 1, 0.9, 0.8))     # the flash
	b.flush(self)
	if robbed_t > 0.0:
		draw_string(ThemeDB.fallback_font, Vector2(-4, -18), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 0.5, 0.4))
	if cheer_t > 0.0 and fmod(t, 0.3) < 0.15:
		draw_line(Vector2(-10, -8), Vector2(-4, -12), Color(1, 1, 1, 0.8), 1.5)
		draw_line(Vector2(10, -8), Vector2(4, -12), Color(1, 1, 1, 0.8), 1.5)
