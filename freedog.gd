extends Node2D

const DogAppearanceScript := preload("res://dog_appearance.gd")

# An off-leash dog in the freedom area: no owner, no leash, all zoomies.
#
# It used to pick a random direction every second or so, which read as a
# screensaver. Dogs in a park are not random - they are BUSY. This one has
# somewhere to be at all times: a post to check, a message to leave, a new
# arrival to bother, and a strong opinion about being run into.
#
# It leaves marks, which is the other half of the point: the park is a
# noticeboard, so there is something for Millie to read (and to write over).
#
# Local RNG throughout. The deterministic autowalk crosses this area, and
# every randf() here would otherwise shift the global sequence.

enum S { WANDER, SEEK, SNIFF, MARK, PLAY, DODGE }

const TROT := 118.0
const SEEK_SPEED := 132.0
const BOLT := 172.0
const DODGE_SPEED := 210.0
const ACCEL := 620.0
const NAMES := [
	"a spaniel", "a big grey lad", "someone small", "a very wet retriever",
	"a whippet", "a terrier with opinions", "an enormous poodle",
]

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

var state: S = S.WANDER
var state_t := 0.0
var target := Vector2(INF, INF)
var mark_cd := 6.0
var visited: Array[Vector2] = []
var my_name := "a spaniel"
var rng := RandomNumberGenerator.new()
var face := Vector2.DOWN
var lean := 0.0        # sniffing tips her forward, marking tips her sideways


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
	rng.seed = appearance_key
	my_name = NAMES[phase_bucket % NAMES.size()]
	# stagger the first errand so a park full of dogs does not sniff in unison
	mark_cd = rng.randf_range(1.5, 7.0)


func _physics_process(delta: float) -> void:
	if main.frozen or main.phase != "freedom":
		return
	state_t -= delta
	mark_cd -= delta
	bow += delta
	var to_mine: Vector2 = my_dog.global_position - global_position
	var d_mine := to_mine.length()

	# Getting barged into by a strange dog at speed is worth reacting to,
	# and it is the one thing that interrupts anything else.
	if state != S.DODGE and d_mine < 74.0 and my_dog.velocity.length() > 235.0:
		var closing: bool = my_dog.velocity.normalized().dot(-to_mine.normalized()) > 0.35
		if closing:
			state = S.DODGE
			state_t = 0.55
			var side := to_mine.orthogonal().normalized()
			if rng.randf() < 0.5:
				side = -side
			vel = side * DODGE_SPEED
			lean = 0.0

	match state:
		S.WANDER:
			wander_t -= delta
			if wander_t <= 0.0:
				wander_t = rng.randf_range(0.5, 1.4)
				vel = Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)).normalized() * TROT
			if state_t <= 0.0:
				_choose_errand(d_mine)
		S.SEEK:
			if target.x >= INF:
				_go_wander(0.6)
			else:
				var want := target - global_position
				if want.length() < 20.0:
					state = S.SNIFF
					state_t = rng.randf_range(0.9, 1.8)
					vel = Vector2.ZERO
				else:
					vel = vel.move_toward(want.normalized() * SEEK_SPEED, ACCEL * delta)
				if state_t <= -6.0:
					# gave up: something is in the way. Cross it off, or she
					# will pick the same unreachable thing again forever.
					visited.append(target)
					_go_wander(0.8)
		S.SNIFF:
			vel = vel.move_toward(Vector2.ZERO, 900.0 * delta)
			lean = minf(lean + delta * 4.0, 1.0)
			if state_t <= 0.0:
				# a good sniff usually deserves a reply
				if mark_cd <= 0.0 and target.x < INF:
					state = S.MARK
					state_t = 1.1
				else:
					_go_wander(rng.randf_range(1.0, 2.5))
		S.MARK:
			vel = Vector2.ZERO
			lean = minf(lean + delta * 5.0, 1.0)
			if state_t <= 0.0:
				if target.x < INF:
					main.on_npc_mark(target + Vector2(0.0, 8.0), col, my_name)
					visited.append(target)
				mark_cd = rng.randf_range(9.0, 17.0)
				_go_wander(rng.randf_range(0.8, 2.0))
		S.PLAY:
			if d_mine > 340.0 or state_t <= 0.0:
				_go_wander(rng.randf_range(1.0, 2.0))
			elif d_mine < 56.0:
				# the play bow: front end down, back end up, tail going
				vel = vel.move_toward(Vector2.ZERO, 700.0 * delta)
				lean = minf(lean + delta * 3.0, 1.0)
			else:
				lean = maxf(lean - delta * 3.0, 0.0)
				vel = vel.move_toward(to_mine.normalized() * BOLT, ACCEL * delta)
		S.DODGE:
			lean = 0.0
			if state_t <= 0.0:
				_go_wander(0.5)

	if state != S.SNIFF and state != S.MARK and state != S.PLAY:
		lean = maxf(lean - delta * 4.0, 0.0)
	position += vel * delta
	if state == S.WANDER:
		vel = vel.move_toward(Vector2.ZERO, 120.0 * delta)
	position.x = clampf(position.x, 90.0, 1190.0)
	position.y = clampf(position.y, lo, hi)
	# face where she is going, or what she is looking at
	if vel.length() > 14.0:
		face = vel.normalized()
	elif target.x < INF and (state == S.SNIFF or state == S.MARK):
		var tf := target - global_position
		if tf.length() > 1.0:
			face = tf.normalized()
	elif state == S.PLAY and d_mine > 1.0:
		face = to_mine / d_mine
	# the node moves via its transform every frame; the drawn pose only
	# needs ~30fps, halving this entity's draw cost (web-build budget)
	if Engine.get_physics_frames() % 2 == 0:
		queue_redraw()


func _go_wander(t: float) -> void:
	state = S.WANDER
	state_t = t
	wander_t = 0.0
	target = Vector2(INF, INF)


func _choose_errand(d_mine: float) -> void:
	# a new arrival beats furniture, which beats milling about
	if d_mine < 300.0 and rng.randf() < 0.38:
		state = S.PLAY
		state_t = rng.randf_range(2.0, 4.5)
		return
	var best_at := Vector2(INF, INF)
	var best_d := 460.0
	for pp in main.park_props:
		var kind := String(pp.kind)
		if kind == "dig" or kind == "trough":
			continue        # her bone to find, not ours
		var at: Vector2 = pp.pos
		if visited.has(at):
			continue
		var d := global_position.distance_to(at)
		if d < best_d:
			best_d = d
			best_at = at
	if best_at.x >= INF:
		visited.clear()     # the whole park has been checked; go round again
		_go_wander(rng.randf_range(0.8, 1.6))
		return
	target = best_at
	state = S.SEEK
	state_t = 0.0


func _draw() -> void:
	main.contact_shadow(self, Vector2.ZERO, 11.0, 8.0, 0.24)
	var t := Time.get_ticks_msec() / 1000.0
	var b := sin(bow * 6.0 + seed_o) * 1.5
	# the pose: sniffing crouches her over the spot, marking cocks a leg (a
	# sideways tilt reads as one at this size), the play bow drops her front
	if lean > 0.01:
		var tilt := 0.0
		var squash := Vector2.ONE
		match state:
			S.SNIFF:
				squash = Vector2(1.0 - lean * 0.10, 1.0 + lean * 0.13)
			S.MARK:
				tilt = lean * 0.30
				squash = Vector2(1.0 + lean * 0.06, 1.0 - lean * 0.05)
			S.PLAY:
				squash = Vector2(1.0 + lean * 0.12, 1.0 - lean * 0.14)
		draw_set_transform(face * lean * 3.0, tilt, squash)
	DogAppearanceScript.draw_dog(
		self,
		appearance_profile,
		Vector2.ZERO,
		face,
		b,
		t * (18.0 if state == S.PLAY else 12.0) + seed_o
	)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# what she is up to, in the only language a top-down view has room for
	match state:
		S.SNIFF:
			for i in range(3):
				var f := fmod(t * 1.6 + float(i) * 0.33, 1.0)
				draw_circle(face * (13.0 + f * 9.0) + Vector2(0, 4),
					2.2 - f * 1.2, Color(0.85, 0.88, 0.7, 0.5 - f * 0.4))
		S.MARK:
			draw_circle(face * 6.0 + Vector2(0, 10), 3.0 + lean * 2.0,
				Color(0.88, 0.86, 0.42, 0.45))
		S.PLAY:
			if lean > 0.4:
				draw_string(ThemeDB.fallback_font, Vector2(-10, -28), "!",
					HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(1, 0.95, 0.8, 0.9))
