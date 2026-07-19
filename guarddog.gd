extends Node2D

# A junkyard guard dog (El Desguas): chained to a post, fast asleep - and
# the whole point is keeping it that way. It wakes to NOISE: a dog moving
# fast nearby, a bark, or (the killer) the owner's phone going off within
# earshot. Waking it is never lethal - it just barks the place down, costs
# you, and startles your human - but the "ghost the yard" goal wants zero.
# Creep past slowly and it sleeps like a log.

const WAKE_R := 120.0      # how close a FAST mover has to be to wake it
const FAST := 140.0        # speed that counts as noisy
const ALERT_T := 3.0       # how long it barks before settling back down

var main: Node2D
var my_dog: Node2D
var asleep := true
var alert_t := 0.0
var seed_o := 0.0


func setup(m: Node2D, mine: Node2D) -> void:
	add_to_group("guards")
	main = m
	my_dog = mine
	# position-derived phase, never the global RNG (autowalk determinism)
	seed_o = fmod(absf(position.x + position.y) * 0.013, TAU)


func _physics_process(delta: float) -> void:
	if main.frozen:
		return
	if asleep:
		# a fast mover nearby is noise; a slow creep is not
		var d: float = my_dog.global_position.distance_to(global_position)
		if d < WAKE_R and my_dog.velocity.length() > FAST:
			wake()
	else:
		alert_t -= delta
		if alert_t <= 0.0:
			asleep = true
	queue_redraw()


func hear_noise(pos: Vector2, radius: float) -> void:
	# a bark or a ringing phone within earshot
	if asleep and pos.distance_to(global_position) < radius:
		wake()


func wake() -> void:
	if not asleep:
		alert_t = ALERT_T  # already up: stays riled
		return
	asleep = false
	alert_t = ALERT_T
	main.on_guard_woken(global_position)


func _draw() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	# the post and chain
	draw_rect(Rect2(-3, -26, 6, 14), Color(0.4, 0.33, 0.28))
	var sag := Vector2(-14, -6 + sin(t + seed_o) * 1.0)
	draw_line(Vector2(0, -18), sag, Color(0.45, 0.45, 0.48), 2.0)
	draw_line(sag, Vector2(-4, -2), Color(0.45, 0.45, 0.48), 2.0)
	# a burly mutt, curled when asleep, up on its feet when riled
	var fur := Color(0.32, 0.28, 0.24)
	if asleep:
		draw_circle(Vector2(0, 2), 10.0, fur)
		draw_circle(Vector2(8, -1), 6.0, fur)
		draw_line(Vector2(11, -4), Vector2(12, -8), fur, 2.0)
		# drifting Zzz
		var zt := fmod(t * 0.7 + seed_o, 1.5) / 1.5
		draw_string(ThemeDB.fallback_font, Vector2(10, -12 - zt * 14.0), "z",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12 + int(zt * 4.0), Color(0.8, 0.85, 0.95, 1.0 - zt))
	else:
		var bounce := absf(sin(t * 10.0)) * 2.0
		draw_circle(Vector2(0, -2 - bounce), 9.0, fur)
		draw_circle(Vector2(9, -6 - bounce), 6.5, fur)
		draw_line(Vector2(7, -12 - bounce), Vector2(6, -16 - bounce), fur, 2.5)
		draw_line(Vector2(12, -12 - bounce), Vector2(13, -16 - bounce), fur, 2.5)
		draw_string(ThemeDB.fallback_font, Vector2(-4, -22), "!!",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 0.4, 0.35))
		# bark rings
		for i in range(2):
			var r := fmod(t * 60.0 + i * 14.0, 30.0)
			draw_arc(Vector2(12, -6), 8.0 + r, -0.5, 0.5, 8, Color(1, 0.6, 0.4, 0.6 * (1.0 - r / 30.0)), 2.0)
