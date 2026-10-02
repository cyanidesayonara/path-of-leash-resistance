extends Node2D

const DogAppearanceScript := preload("res://entities/dog_appearance.gd")
const Clay := preload("res://entities/clay.gd")

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
	var t := AnimClock.msec() / 1000.0
	if Clay.offscreen(self, main):
		return
	var b := ShapeBatch.new(self)
	var post := Vector2(-2, -20)
	# the post, seen end-on: a round sawn top, shadow falling away from the light
	b.draw_line(post, post + Clay.LIGHT * 13.0, Color(Clay.SHADOW, 0.20), 8.0)
	Clay.ball(b, post, 4.6, Color(0.46, 0.36, 0.27))
	b.draw_circle(post - Clay.LIGHT * 0.6, 2.4, Color(0.56, 0.45, 0.33))
	b.draw_circle(post - Clay.LIGHT * 0.6, 1.0, Color(0.46, 0.36, 0.27))
	# a Rottweiler-ish lump: curled up asleep, up on its feet when riled
	var prof: Dictionary = DogAppearanceScript.get_profile("guard")
	var base: Color = prof["base_color"]
	var tan: Color = prof["marking_color"]
	var collar := Vector2.ZERO
	var bark_dir := Vector2.RIGHT
	# the dog goes in its own batch, laid over the chain once that is drawn
	var d := ShapeBatch.new()
	if asleep:
		var breathe := 1.0 + sin(t * 1.6 + seed_o) * 0.035
		var c := Vector2(2, 3)
		Clay.ground_shadow(b, c, 15.0, 9.0, 4.0, 0.24)
		# the tail wrapped round the front of the curl
		var tail := PackedVector2Array()
		for k in range(5):
			var ang := 2.0 + float(k) * 0.32
			tail.append(c + Vector2.from_angle(ang) * 11.5 * breathe)
		Clay.stroke(d, tail, 3.6, 2.0, Clay.rim_of(base))
		Clay.blob(d, c, Vector2(12.5, 10.5) * breathe, Vector2.RIGHT, base)
		# the line of the back, catching the light round the curl
		var back := PackedVector2Array()
		for k in range(6):
			back.append(c + Vector2.from_angle(-2.9 + float(k) * 0.55) * 6.5 * breathe)
		Clay.stroke(d, back, 2.4, 1.4, Clay.lit_of(base, 0.14))
		# the head resting on the curl, nose tucked round towards the tail
		var hc := c + Vector2(6.0, 0.5) * breathe
		var nose_dir := Vector2(-0.55, 0.85).normalized()
		var across := nose_dir.orthogonal()
		for sd: float in [-1.0, 1.0]:
			var ear_at := hc + across * 5.6 * sd - nose_dir * 2.0
			d.draw_colored_polygon(Clay.ellipse_pts(ear_at, Vector2(2.4, 3.0), nose_dir, 10), Clay.rim_of(base))
		Clay.ball(d, hc, 6.4, base)
		Clay.blob(d, hc + nose_dir * 6.2, Vector2(3.2, 2.9), nose_dir, tan)
		d.draw_circle(hc + nose_dir * 8.8, 1.4, Color(0.06, 0.05, 0.05))
		for sd: float in [-1.0, 1.0]:
			d.draw_circle(hc + nose_dir * 1.0 + across * 2.6 * sd, 0.9, tan)
			# eyes shut
			var eye := hc + nose_dir * 2.6 + across * 2.4 * sd
			d.draw_line(eye - across * 1.1, eye + across * 1.1, Color(0.50, 0.42, 0.36), 0.8)
		collar = hc - nose_dir * 3.0
	else:
		var bounce := absf(sin(t * 10.0)) * 1.5
		var face := Vector2.DOWN
		if my_dog != null:
			var to := my_dog.global_position - global_position
			if to.length() > 1.0:
				face = to.normalized()
		var at := Vector2(0, 2)
		Clay.ground_shadow(b, at, 16.0, 9.0, 6.0 + bounce, 0.24)
		var bark := clampf(sin(t * 12.0) * 1.4, 0.0, 1.0)
		DogAppearanceScript.draw_dog(d, prof, at, face, -bounce, t * 20.0, bark)
		# hackles up along the spine
		var side := face.orthogonal()
		for k in range(4):
			var sp := at - Vector2(0, bounce) + face * (6.0 - float(k) * 4.5)
			d.draw_line(sp - side * 2.6, sp + side * 2.6, Color(0.05, 0.05, 0.05), 1.4)
		collar = at - Vector2(0, bounce) + face * 13.0
		bark_dir = face
	# the chain: links lying slack on the ground, post to collar
	var sag := (post + collar) * 0.5 + Vector2(-5, 4 + sin(t + seed_o) * 1.0)
	var link := Color(0.62, 0.62, 0.66)
	for k in range(9):
		var f := float(k) / 8.0
		var q := post.lerp(sag, f).lerp(sag.lerp(collar, f), f)
		b.draw_circle(q, 1.3 if k % 2 == 0 else 1.0, link if k % 2 == 0 else link.darkened(0.25))
	d.flush(b)
	b.flush()
	if asleep:
		# drifting Zzz
		var zt := fmod(t * 0.7 + seed_o, 1.5) / 1.5
		draw_string(ThemeDB.fallback_font, Vector2(12, -14 - zt * 14.0), "z",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12 + int(zt * 4.0), Color(0.8, 0.85, 0.95, 1.0 - zt))
	else:
		draw_string(ThemeDB.fallback_font, Vector2(-4, -24), "!!",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 0.4, 0.35))
		# bark rings
		for i in range(2):
			var r := fmod(t * 60.0 + i * 14.0, 30.0)
			draw_arc(bark_dir * 18.0, 8.0 + r, bark_dir.angle() - 0.5, bark_dir.angle() + 0.5, 8, Color(1, 0.6, 0.4, 0.6 * (1.0 - r / 30.0)), 2.0)
