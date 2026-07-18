extends Node2D

const DogAppearanceScript := preload("res://dog_appearance.gd")

# An off-leash dog in the freedom area: no owner, no leash, all zoomies.
# Wanders, play-bows, and is delighted to be greeted (once).

var main: Node2D
var my_dog: Node2D
var vel := Vector2.ZERO
var wander_t := 0.0
var seed_o := 0.0
var col := Color(0.6, 0.5, 0.4)
var appearance_profile: Dictionary = {}
var lo := 0.0
var hi := 0.0
var bow := 0.0


func _appearance_key(y_lo: float, y_hi: float) -> int:
	return (
		roundi(position.x) * 73856093
		+ roundi(position.y) * 19349663
		+ roundi(y_lo) * 83492791
		+ roundi(y_hi) * 2654435761
	)


func setup(m: Node2D, mine: Node2D, y_lo: float, y_hi: float) -> void:
	add_to_group("freedogs")
	main = m
	my_dog = mine
	lo = y_lo
	hi = y_hi
	var appearance_key := _appearance_key(y_lo, y_hi)
	appearance_profile = DogAppearanceScript.profile_for_key(appearance_key)
	var phase_bucket := ((appearance_key % 10000) + 10000) % 10000
	seed_o = float(phase_bucket) / 1000.0
	col = appearance_profile["base_color"]


func _physics_process(delta: float) -> void:
	if main.frozen or main.phase != "freedom":
		return
	wander_t -= delta
	if wander_t <= 0.0:
		wander_t = randf_range(0.5, 1.5)
		# mostly mill about; sometimes bolt after your dog to play
		if randf() < 0.4 and my_dog.global_position.distance_to(global_position) < 300.0:
			vel = (my_dog.global_position - global_position).normalized() * 150.0
		else:
			vel = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * 110.0
	bow += delta
	position += vel * delta
	vel = vel.move_toward(Vector2.ZERO, 120.0 * delta)
	position.x = clampf(position.x, 90.0, 1190.0)
	position.y = clampf(position.y, lo, hi)
	# the node moves via its transform every frame; the drawn pose only
	# needs ~30fps, halving this entity's draw cost (web-build budget)
	if Engine.get_physics_frames() % 2 == 0:
		queue_redraw()


func _draw() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var b := sin(bow * 6.0 + seed_o) * 1.5
	var face := (my_dog.global_position - global_position).normalized()
	DogAppearanceScript.draw_dog(
		self,
		appearance_profile,
		Vector2.ZERO,
		face,
		b,
		t * 12.0 + seed_o
	)
