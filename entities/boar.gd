extends Node2D

# Collserola's wild boar: a sow and her striped piglets crossing El Bosc's
# trail at their own pace. They take nothing. Crowd the piglets, get between
# her and them, or bark at her, and she snorts, scrapes the ground, and then
# charges the dog flat. The owner, phone up, walks into her after a warning
# bubble and gets shoved aside. Everything is telegraphed: the family grunts
# as it comes out of the trees, the piglets cross first, and a charge always
# follows a snort and a scrape (ALARM_T).
#
# Self-managing and order-independent, like the other critters: it reads the
# dog and the owner and never moves them except through their own knock and
# bump calls.

const PIGLETS := 4
const WALK_SPEED := 40.0       # the family's pace across the trail
const PIGLET_GAP := 30.0
const LEAD_GAP := 50.0         # the first piglet this far ahead of her
const CROWD_R := 64.0          # the dog this close to a piglet is crowding them
const BETWEEN_R := 40.0        # ...or this close to the line from her to them
const BARK_R := 180.0          # a bark this close provokes her
const ALARM_T := 0.7           # snort and scrape before she goes
const CHARGE_SPEED := 300.0
const CHARGE_T := 0.9
const CALM_T := 3.0            # after a charge she will not go again this soon
const HIT_R := 36.0
const OWNER_WARN_R := 150.0
const OWNER_WARN_T := 0.8      # the design contract: a bubble this long first
const OWNER_HIT_R := 36.0

enum S { CROSS, ALARM, CHARGE, RETURN }

var main: Node2D
var dog: Node2D
var human: Node2D
var state := S.CROSS
var state_t := 0.0
var calm_t := 0.0
var dir := 1.0                 # crossing east (+1) or west (-1)
var line_y := 0.0
var family_x := 0.0            # how far across the lead of the family is
var end_x := 0.0
var charge_dir := Vector2.RIGHT
var owner_warn_t := -1.0       # time since the owner was warned; <0 not yet
var owner_cd := 0.0
var charges := 0
var shoves := 0


func setup(m: Node2D, d: Node2D, h: Node2D, y: float, from_x: float, to_x: float) -> void:
	add_to_group("boars")
	main = m
	dog = d
	human = h
	line_y = y
	family_x = from_x
	end_x = to_x
	dir = signf(to_x - from_x)
	global_position = Vector2(from_x, y)
	Sfx.play("grunt", 0.9)
	main.float_text(global_position + Vector2(0, -26), "grunt grunt", Color(0.95, 0.85, 0.7))


# where piglet i is: ahead of her on the crossing line, waddling
func piglet_pos(i: int) -> Vector2:
	var t: float = main.elapsed
	var x := family_x + dir * (LEAD_GAP + PIGLET_GAP * float(i))
	return Vector2(x, line_y + sin(t * 9.0 + float(i) * 1.7) * 3.0)


# where she walks when she is not charging: behind the piglets
func sow_home() -> Vector2:
	return Vector2(family_x, line_y)


func provoke() -> void:
	if state == S.CROSS and calm_t <= 0.0:
		state = S.ALARM
		state_t = ALARM_T
		Sfx.play("grunt", 0.75, -3.0)
		main.float_text(global_position + Vector2(0, -30), "SNORT!", Color(1, 0.7, 0.55))


func _crowded() -> bool:
	var dp: Vector2 = dog.global_position
	for i in range(PIGLETS):
		if dp.distance_to(piglet_pos(i)) < CROWD_R:
			return true
	var a := global_position
	var b := piglet_pos(0)
	var ab := b - a
	var f := clampf((dp - a).dot(ab) / maxf(ab.length_squared(), 1.0), 0.0, 1.0)
	return dp.distance_to(a + ab * f) < BETWEEN_R


func _physics_process(delta: float) -> void:
	if main.frozen:
		return
	calm_t = maxf(0.0, calm_t - delta)
	owner_cd = maxf(0.0, owner_cd - delta)
	match state:
		S.CROSS:
			family_x += dir * WALK_SPEED * delta
			global_position = sow_home()
			if _crowded():
				provoke()
		S.ALARM:
			state_t -= delta
			# the scrape: she rocks on the spot, facing the dog
			charge_dir = (dog.global_position - global_position).normalized()
			if state_t <= 0.0:
				state = S.CHARGE
				state_t = CHARGE_T
				charges += 1
		S.CHARGE:
			state_t -= delta
			global_position += charge_dir * CHARGE_SPEED * delta
			if global_position.distance_to(dog.global_position) < HIT_R and not dog.is_tumbling():
				dog.knocked(charge_dir, "boar")
				Sfx.play("grunt", 1.1)
				main.float_text(global_position + Vector2(0, -24), "THUMP", Color(1, 0.8, 0.6))
				state_t = 0.0
			if state_t <= 0.0:
				state = S.RETURN
		S.RETURN:
			var to := sow_home() - global_position
			if to.length() < 4.0:
				state = S.CROSS
				calm_t = CALM_T
			else:
				global_position += to.normalized() * minf(to.length(), WALK_SPEED * 3.0 * delta)
	_owner(delta)
	if dir * (family_x - end_x) > 0.0:
		queue_free()


func _owner(delta: float) -> void:
	# the phone never comes down, so the owner walks into her: a bubble
	# first, and only then the shove
	var d: float = human.global_position.distance_to(global_position)
	if owner_warn_t < 0.0:
		if d < OWNER_WARN_R and owner_cd <= 0.0:
			owner_warn_t = 0.0
			human.notice("...is that a pig?", 1.6)
		return
	owner_warn_t += delta
	if owner_warn_t >= OWNER_WARN_T and d < OWNER_HIT_R and owner_cd <= 0.0:
		human.bumped((human.global_position - global_position).normalized())
		Sfx.play("grunt", 0.85)
		main.float_text(human.global_position + Vector2(0, -34), "OOF", Color(1, 1, 1))
		shoves += 1
		owner_cd = 2.5
		owner_warn_t = -1.0
	elif d > OWNER_WARN_R + 60.0:
		owner_warn_t = -1.0


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var t := AnimClock.msec() / 1000.0
	# the piglets, drawn in world space relative to this node
	for i in range(PIGLETS):
		var pp := piglet_pos(i) - global_position
		_draw_boar(pp, 0.62, dir, true, t + float(i))
	var rock := 0.0
	if state == S.ALARM:
		rock = sin(t * 40.0) * 2.5
	var facing := dir
	if state in [S.ALARM, S.CHARGE]:
		facing = signf(charge_dir.x + 0.001)
	_draw_boar(Vector2(rock, 0.0), 1.4, facing, false, t)
	if state == S.ALARM:
		# the scrape: dust kicked back, and a mark over her
		for k in range(3):
			draw_circle(Vector2(-facing * (26.0 + float(k) * 7.0), 8.0 + float(k % 2) * 4.0), 3.0, Color(0.55, 0.45, 0.32, 0.7))
		draw_string(ThemeDB.fallback_font, Vector2(-5, -30), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1, 0.55, 0.4))


# A boar from above: a long wedge body, bristly dark ridge down the spine,
# the long snout forward, small ears. Piglets are ginger with pale stripes.
func _draw_boar(at: Vector2, s: float, facing: float, piglet: bool, t: float) -> void:
	var body := Color(0.44, 0.31, 0.20) if piglet else Color(0.29, 0.24, 0.20)
	var ridge := Color(0.25, 0.17, 0.10) if piglet else Color(0.16, 0.13, 0.11)
	var b := ShapeBatch.new()
	var fwd := Vector2(facing, 0.0)
	var legs := sin(t * 11.0) * 3.0 * s
	# shadow, legs, body
	b.circle(at + Vector2(4, 6) * s, 17.0 * s, Color(0, 0, 0, 0.18))
	for lx: float in [-10.0, 10.0]:
		b.circle(at + fwd * (lx * s + legs * signf(lx)) + Vector2(0, -9.0 * s), 3.5 * s, ridge)
		b.circle(at + fwd * (lx * s - legs * signf(lx)) + Vector2(0, 9.0 * s), 3.5 * s, ridge)
	b.circle(at - fwd * 8.0 * s, 13.0 * s, body)
	b.circle(at + fwd * 5.0 * s, 12.0 * s, body)
	b.circle(at + fwd * 17.0 * s, 8.0 * s, body.darkened(0.08))
	# the snout, with its flat disc at the end
	b.circle(at + fwd * 25.0 * s, 5.0 * s, body.darkened(0.15))
	b.circle(at + fwd * 29.0 * s, 3.4 * s, Color(0.50, 0.38, 0.33))
	# ears
	b.circle(at + fwd * 14.0 * s + Vector2(0, -7.0 * s), 3.2 * s, ridge)
	b.circle(at + fwd * 14.0 * s + Vector2(0, 7.0 * s), 3.2 * s, ridge)
	if piglet:
		for k in range(3):
			var off := (float(k) - 1.0) * 5.0 * s
			b.line(at + Vector2(-16.0 * s * facing, off), at + Vector2(14.0 * s * facing, off), Color(0.86, 0.74, 0.52, 0.8), 1.6 * s)
	else:
		b.line(at - fwd * 20.0 * s, at + fwd * 14.0 * s, ridge, 5.0 * s)
		# bristles along the ridge, and the pale tusks at the snout
		for k in range(5):
			var bx := at - fwd * (16.0 - float(k) * 7.0) * s
			b.line(bx + Vector2(0, -4.0 * s), bx + Vector2(0, 4.0 * s), ridge.darkened(0.3), 1.4)
		for ty: float in [-4.0, 4.0]:
			b.line(at + fwd * 23.0 * s + Vector2(0, ty * s), at + fwd * 27.0 * s + Vector2(0, ty * 1.5 * s), Color(0.92, 0.88, 0.78), 1.6)
		# the tail, flicking
		b.line(at - fwd * 20.0 * s, at - fwd * 27.0 * s + Vector2(0, sin(t * 6.0) * 3.0), ridge, 2.0)
	b.flush(self)
