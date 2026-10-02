extends Node2D

const Clay := preload("res://entities/clay.gd")

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
	if Clay.offscreen(self, main):
		return
	# the whole family in one batch
	var b := ShapeBatch.new(self)
	var cross := Vector2(dir, 0.0)
	# the piglets, drawn in world space relative to this node
	for i in range(PIGLETS):
		var pp := piglet_pos(i) - global_position
		_draw_boar(b, pp, 0.62, cross, true, t + float(i))
	var rock := 0.0
	if state == S.ALARM:
		rock = sin(t * 40.0) * 2.5
	var facing := cross
	if state in [S.ALARM, S.CHARGE]:
		facing = charge_dir
	elif state == S.RETURN:
		var to := sow_home() - global_position
		if to.length() > 1.0:
			facing = to.normalized()
	_draw_boar(b, Vector2(rock, 0.0), 1.4, facing, false, t)
	if state == S.ALARM:
		# the scrape: dust kicked back
		for k in range(3):
			b.draw_circle(-facing * (30.0 + float(k) * 7.0) + facing.orthogonal() * (float(k) - 1.0) * 6.0,
				3.0 + float(k % 2), Color(0.55, 0.45, 0.32, 0.7))
	b.flush()
	if state == S.ALARM:
		draw_string(ThemeDB.fallback_font, Vector2(-5, -30), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1, 0.55, 0.4))


# A boar from straight above: a heavy wedge, all shoulders, tapering to the
# rump; a bristly dark mane down the spine; a long head ending in the flat
# pink-grey disc of the snout, with tusks. Piglets are ginger humbugs with
# pale stripes running nose to tail.
func _draw_boar(b: ShapeBatch, at: Vector2, s: float, facing: Vector2, piglet: bool, t: float) -> void:
	var fwd := facing.normalized() if facing.length() > 0.01 else Vector2.RIGHT
	var side := fwd.orthogonal()
	var body := Color(0.62, 0.42, 0.24) if piglet else Color(0.38, 0.30, 0.24)
	var ridge := Color(0.40, 0.25, 0.13) if piglet else Color(0.18, 0.14, 0.11)
	var legs := sin(t * 11.0) * 2.5 * s
	Clay.ground_shadow(b, at, 20.0 * s, 11.0 * s, 4.0 * s, 0.20)
	# hooves poking out under the body, trotting
	for lx: float in [-1.0, 1.0]:
		for sd: float in [-1.0, 1.0]:
			var step := legs * lx * sd
			b.draw_circle(at + fwd * (lx * 9.0 * s + step) + side * sd * 9.0 * s, 2.6 * s, ridge.darkened(0.2))
	# the tail, flicking
	var tail_end := at - fwd * 24.0 * s + side * sin(t * 6.0) * 3.0 * s
	b.draw_line(at - fwd * 15.0 * s, tail_end, ridge, 1.6 * s)
	b.draw_circle(tail_end, 1.6 * s, ridge)
	# rump, then the big shoulders over it
	var trunk := PackedVector2Array()
	for k in range(20):
		# an egg: broad at the shoulders, narrower at the rump
		var ang := TAU * float(k) / 20.0
		var w := 10.5 + 1.8 * cos(ang)
		trunk.append(at + fwd * (cos(ang) * 16.0 * s + 1.0 * s) + side * (sin(ang) * w * s))
	b.draw_colored_polygon(trunk, Clay.rim_of(body))
	var lit_trunk := PackedVector2Array()
	for p in trunk:
		lit_trunk.append(at + (p - at) * 0.88 - Clay.LIGHT * 1.2 * s)
	b.draw_colored_polygon(lit_trunk, body)
	Clay.patch(b, at + fwd * 3.0 * s - Clay.LIGHT * 4.0 * s, Vector2(8.0, 4.5) * s, fwd, Clay.lit_of(body, 0.10))
	# the head: a wedge narrowing to the snout
	var neck := at + fwd * 12.0 * s
	var snout := at + fwd * 27.0 * s
	var head := PackedVector2Array([
		neck + side * 7.5 * s, snout + side * 2.8 * s, snout - side * 2.8 * s, neck - side * 7.5 * s,
		neck - fwd * 2.0 * s,
	])
	b.draw_colored_polygon(head, Clay.rim_of(body))
	var head_lit := PackedVector2Array()
	for p in head:
		head_lit.append(p.lerp(neck + fwd * 6.0 * s, 0.18) - Clay.LIGHT * 0.6 * s)
	b.draw_colored_polygon(head_lit, body.darkened(0.04))
	# ears pricked back at the base of the head
	for sd: float in [-1.0, 1.0]:
		var eb := neck + side * sd * 5.5 * s
		b.draw_colored_polygon(PackedVector2Array([
			eb + fwd * 2.0 * s, eb - fwd * 3.5 * s + side * sd * 3.0 * s, eb - fwd * 1.0 * s - side * sd * 1.5 * s,
		]), ridge)
	# the snout disc and its nostrils
	b.draw_circle(snout, 3.2 * s, Color(0.58, 0.44, 0.40))
	for sd: float in [-1.0, 1.0]:
		b.draw_circle(snout + fwd * 0.6 * s + side * sd * 1.2 * s, 0.75 * s, Color(0.22, 0.14, 0.12))
	# small eyes either side of the head
	for sd: float in [-1.0, 1.0]:
		b.draw_circle(neck + fwd * 5.0 * s + side * sd * 4.2 * s, 0.9 * s, Color(0.06, 0.05, 0.04))
	if piglet:
		for k in range(4):
			var off := (float(k) - 1.5) * 3.6 * s
			b.draw_line(at - fwd * 14.0 * s + side * off * 0.8, at + fwd * 12.0 * s + side * off, Color(0.92, 0.80, 0.58, 0.85), 1.4 * s)
	else:
		# the mane: a dark bristly ridge from the head down the spine
		b.draw_line(neck, at - fwd * 13.0 * s, ridge, 4.0 * s)
		for k in range(7):
			var bx := neck - fwd * float(k) * 3.6 * s
			var w := (4.2 - float(k) * 0.35) * s
			b.draw_line(bx - side * w, bx + side * w + fwd * 1.6 * s, ridge.darkened(0.25), 1.3 * s)
		# the pale tusks curling up from the snout
		for sd: float in [-1.0, 1.0]:
			var tb := snout - fwd * 2.5 * s + side * sd * 2.6 * s
			b.draw_line(tb, tb + fwd * 2.2 * s + side * sd * 1.4 * s, Color(0.94, 0.90, 0.80), 1.2 * s)
