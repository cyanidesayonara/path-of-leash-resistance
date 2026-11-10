extends Node2D

# The chase threat of La Cremada (Badalona's Nit del Dimoni): the Dimoni on
# his float. The papier-mache devil sits enthroned on a timber float, his
# fork crammed with fireworks, and the fuse is already lit: the brake gave as
# they turned for home and the whole float rolls up Carrer del Mar after
# them, spraying sparks. One huge, slow juggernaut, not a crowd (Festa de
# Gràcia owns the correfoc devils; no two chases share a threat).
#
# What sets it apart: it fires. Every few seconds a rocket leaves the fork
# for a spot ahead of it - where the dog or your human is heading - and a
# ring fills on the ground where it will land, ROCKET_WARN long. Whoever is
# inside when it lands is knocked (the dog tumbles; your human is bumped, a
# stagger, never a fall). Out of the ring as it lands, near enough to feel
# it, is a dodge. The float itself is the catch line, as every chase's.
#
# Implements the standard chase threat interface (setup, advance, caught,
# gap_to, threat_boundary, sweep_junk) so systems/home_chase drives it. Only
# advance() moves it, and home_chase only calls that in the "chase" phase,
# so nothing fires during the warning, the head start or a hold.

const ShapeBatch := preload("res://systems/shape_batch.gd")

# the float: timber deck, painted skirt, iron-shod wheels
const DECK := Color(0.40, 0.27, 0.16)
const DECK_DARK := Color(0.26, 0.17, 0.10)
const SKIRT := Color(0.78, 0.16, 0.12)
const SKIRT_GOLD := Color(0.95, 0.74, 0.22)
const WHEEL := Color(0.10, 0.09, 0.08)
# the Dimoni: red papier-mache, black brows, gold horns, a toothy grin
const DEVIL := Color(0.80, 0.14, 0.10)
const DEVIL_DARK := Color(0.50, 0.07, 0.06)
const DEVIL_BLACK := Color(0.10, 0.08, 0.08)
const HORN := Color(0.96, 0.80, 0.34)
const TEETH := Color(0.98, 0.95, 0.86)
const EYE := Color(1.0, 0.92, 0.30)
const FORK := Color(0.22, 0.20, 0.20)
const FLAME := Color(1.0, 0.56, 0.12)
const FLAME_CORE := Color(1.0, 0.90, 0.46)
const SPARK := Color(1.0, 0.94, 0.56)
const SMOKE := Color(0.30, 0.28, 0.30, 0.34)
const SHADOW := Color(0.02, 0.02, 0.05, 0.30)
# bright enough to read under the night grade: the ring is the telegraph
const RING := Color(1.0, 0.78, 0.30)
const RING_FILL := Color(1.0, 0.45, 0.12, 0.42)
const BLAST := Color(1.0, 0.84, 0.40)

# the roll: steady, a little surge on the slope, catching up when far back
const SURGE := 0.18
const CATCH_UP := 1.4
const CATCH_UP_GAP := 680.0
const JAM_SECS := 3.0
# how far behind its leading edge the float runs (its deck and the Dimoni)
const FLOAT_DEPTH := 230.0
# the catch line is this share of the corridor's half either side
const CATCH_SPAN := 0.78

# THE ROCKETS
const ROCKET_FIRST := 1.6         # after the chase begins, the first launch
const ROCKET_EVERY := 2.4         # between launches, before the jitter
const ROCKET_JITTER := 0.6
const ROCKET_WARN := 1.0          # the ring fills this long, then it lands
const ROCKET_R := 48.0            # inside this when it lands: hit
const ROCKET_DODGE_R := 120.0     # outside ROCKET_R but inside this: a dodge
const ROCKET_LEAD := 0.55         # aims where its mark will be this much later
const ROCKET_MIN_AHEAD := 90.0    # never lands closer than this ahead of the float
const ROCKET_ARC := 150.0         # how high the rocket climbs, drawn
const MAX_ROCKETS := 3
const BLAST_TIME := 0.45
const DODGE_BONES := 1

var main: Node2D
var speed := 118.0
var cur_speed := 118.0
var front_y := 0.0
var cx := 640.0
var half := 280.0
var kind := "dimoni"
var rumble := 0.0
var sway := 0.0
var sway_v := 0.0
# unused by a float that does not turn; the chase checkpoint snapshots it on
# every threat (systems/chase_checkpoint.gd SWEEPER_FIELDS)
var heading := 0.0
var jams: Array[Vector2] = []
var jam_t := 0.0
var jam_side := 0.0
var jam_at := Vector2(INF, INF)
var kerb_blocks: Array[Rect2] = []
var jammed_now := false
var freed_now := false

# each: {"from": Vector2, "at": Vector2, "t": float (counts up to ROCKET_WARN)}
var rockets: Array[Dictionary] = []
# each: {"at": Vector2, "t": float (counts down from BLAST_TIME)}
var blasts: Array[Dictionary] = []
var fire_t := ROCKET_FIRST
var shots := 0
# what the rockets did, for the walk's goals and the tests
var hits := 0
var dodges := 0


func setup(m: Node2D, start_front_y: float, corridor_cx: float, corridor_half: float, float_speed: float) -> void:
	main = m
	front_y = start_front_y
	cx = corridor_cx
	half = corridor_half
	speed = float_speed
	cur_speed = float_speed
	rockets.clear()
	blasts.clear()
	fire_t = ROCKET_FIRST
	position = Vector2(cx, front_y)


func advance(delta: float, gap := -1.0, aim := 0.0) -> void:
	rumble += delta
	jammed_now = false
	freed_now = false
	_tick_rockets(delta)
	if jam_t > 0.0:
		jam_t -= delta
		cur_speed = 0.0
		if jam_t <= 0.0:
			freed_now = true
		queue_redraw()
		return

	var lurch := sin(rumble * 0.9) * 0.6 + sin(rumble * 2.3) * 0.4
	var mult := 1.0 + SURGE * lurch
	if gap > CATCH_UP_GAP:
		mult = maxf(mult, CATCH_UP)
	cur_speed = speed * mult
	front_y += cur_speed * delta

	for i in range(jams.size()):
		if front_y >= jams[i].y:
			jam_side = signf(jams[i].x - cx)
			jam_at = jams[i]
			jams.remove_at(i)
			jam_t = JAM_SECS
			jammed_now = true
			break

	# a float this heavy barely steers: a slow drift toward the dog's side
	var target_sway: float = clampf(aim, -half * 0.35, half * 0.35)
	sway_v += (target_sway - sway) * 1.6 * delta
	sway_v *= exp(-3.2 * delta)
	sway += sway_v * delta

	fire_t -= delta
	if fire_t <= 0.0 and rockets.size() < MAX_ROCKETS:
		_fire()
		fire_t = ROCKET_EVERY + ROCKET_JITTER * sin(float(shots) * 2.39)
	position = Vector2(cx + sway, front_y)
	queue_redraw()


func jammed() -> bool:
	return jam_t > 0.0


func threat_boundary() -> float:
	return front_y


func caught(p: Vector2) -> bool:
	if p.y <= front_y and p.y >= front_y - FLOAT_DEPTH * 0.6:
		return absf(p.x - (cx + sway)) <= half * CATCH_SPAN
	# rolled right past them: whoever slipped by at the side went under it
	return p.y < front_y - FLOAT_DEPTH * 0.6


func gap_to(p: Vector2) -> float:
	return p.y - front_y


func sweep_junk(_junk: Array) -> int:
	return 0


# where the fork's tip is, in the world: the rockets leave from here
func launcher() -> Vector2:
	return Vector2(cx + sway + 34.0, front_y - FLOAT_DEPTH * 0.55)


# The mark the next rocket goes for: the dog and your human in turn, led by
# their velocity, kept on the corridor and ahead of the float.
func aim_point(target: Vector2, vel: Vector2) -> Vector2:
	var p := target + vel * ROCKET_LEAD
	p.x = clampf(p.x, cx - half + ROCKET_R, cx + half - ROCKET_R)
	p.y = maxf(p.y, front_y + ROCKET_MIN_AHEAD)
	return p


func _fire() -> void:
	if main == null:
		return
	var at: Vector2
	if shots % 2 == 0:
		at = aim_point(main.dog.global_position, main.dog.velocity)
	else:
		at = aim_point(main.human.global_position, main.human.velocity)
	shots += 1
	rockets.append({"from": launcher(), "at": at, "t": 0.0})
	Sfx.play("whistle", 1.6, -10.0)


func _tick_rockets(delta: float) -> void:
	for i in range(blasts.size() - 1, -1, -1):
		blasts[i]["t"] = float(blasts[i]["t"]) - delta
		if float(blasts[i]["t"]) <= 0.0:
			blasts.remove_at(i)
	for i in range(rockets.size() - 1, -1, -1):
		var r: Dictionary = rockets[i]
		r["t"] = float(r["t"]) + delta
		if float(r["t"]) >= ROCKET_WARN:
			rockets.remove_at(i)
			land(r["at"])


# A rocket comes down at `at`: knock whoever is in the ring, count a dodge for
# the dog near it and clear. The autowalk bot is never knocked (CI's selftest
# and the soak carry an unsweepable pair; home_chase does the same for the
# catch).
func land(at: Vector2) -> void:
	blasts.append({"at": at, "t": BLAST_TIME})
	if main == null:
		return
	Sfx.play("cracker", 0.9, -4.0)
	main.shake_t = maxf(float(main.shake_t), 0.3)
	var auto: bool = bool(main.auto_walk)
	var dog_p: Vector2 = main.dog.global_position
	var hum_p: Vector2 = main.human.global_position
	var dd := dog_p.distance_to(at)
	var hd := hum_p.distance_to(at)
	var hit := false
	if dd <= ROCKET_R and not auto:
		hit = true
		main.dog.knocked((dog_p - at).normalized() if dd > 1.0 else Vector2.DOWN, "rocket")
	if hd <= ROCKET_R and not auto:
		hit = true
		main.human.bumped((hum_p - at).normalized() if hd > 1.0 else Vector2.DOWN)
		main.float_text(hum_p, "Yikes!", Color(1.0, 0.85, 0.6))
	if hit:
		hits += 1
		if "cremada_hits" in main:
			main.cremada_hits += 1
		main.float_text(at, "BANG", BLAST)
		return
	main.float_text(at, "BANG", BLAST)
	if dd <= ROCKET_DODGE_R or hd <= ROCKET_DODGE_R:
		dodges += 1
		if "cremada_dodges" in main:
			main.cremada_dodges += 1
		main.bones += DODGE_BONES
		main.float_text(dog_p + Vector2(0.0, -30.0), "dodged! +%d" % DODGE_BONES, Color(0.75, 0.9, 1.0))


# The banner while a ring is filling near either of them: the one thing to do.
func rocket_warning() -> bool:
	if main == null:
		return false
	for r: Dictionary in rockets:
		var at: Vector2 = r["at"]
		if at.distance_to(main.dog.global_position) < ROCKET_DODGE_R \
				or at.distance_to(main.human.global_position) < ROCKET_DODGE_R:
			return true
	return false


func _draw() -> void:
	var b := ShapeBatch.new(self)
	var t := rumble
	# the rings on the ground ahead, under everything (world space, so undo
	# the node's own position)
	var o := -position
	for r: Dictionary in rockets:
		_ring(b, Vector2(r["at"]) + o, clampf(float(r["t"]) / ROCKET_WARN, 0.0, 1.0))
	for bl: Dictionary in blasts:
		var k := 1.0 - float(bl["t"]) / BLAST_TIME
		var at: Vector2 = Vector2(bl["at"]) + o
		b.glow(at, ROCKET_R * (1.1 + k * 0.9), Color(BLAST, 0.75 * (1.0 - k)), 0.3)
		for i in range(10):
			var a := float(i) * TAU / 10.0 + 0.3
			b.line(at + Vector2.from_angle(a) * ROCKET_R * (0.3 + k * 0.6),
				at + Vector2.from_angle(a) * ROCKET_R * (0.55 + k * 1.1), Color(SPARK, 1.0 - k), 3.0)
	paint_float(b, Vector2.ZERO, half * CATCH_SPAN, t, true)
	# rockets in flight, over everything: a spark streak and its smoke
	for r: Dictionary in rockets:
		var k := clampf(float(r["t"]) / ROCKET_WARN, 0.0, 1.0)
		var from: Vector2 = Vector2(r["from"]) + o
		var to: Vector2 = Vector2(r["at"]) + o
		var ground := from.lerp(to, k)
		var lift := sin(k * PI) * ROCKET_ARC
		var head := ground + Vector2(0.0, -lift)
		for j in range(4):
			var kk := maxf(0.0, k - float(j + 1) * 0.04)
			var gp := from.lerp(to, kk) + Vector2(0.0, -sin(kk * PI) * ROCKET_ARC)
			b.circle(gp, 6.0 - float(j), Color(SMOKE, 0.5 - float(j) * 0.1))
		b.circle(head, 6.0, FLAME)
		b.circle(head, 3.5, SPARK)
	b.flush()


# The float and the Dimoni with the float's front edge at `c`, `w` either
# side: the walk's parked figure on the beach and the chase's threat are the
# same drawing. `burning`: flames round the deck (the fuse is lit).
static func paint_float(b: ShapeBatch, c: Vector2, w: float, t: float, burning: bool) -> void:
	# its glow on the paving ahead: the fireworks light the street
	b.glow(c + Vector2(0.0, -FLOAT_DEPTH * 0.45), w * 1.5, Color(FLAME, 0.20 + 0.06 * sin(t * 9.0)), 0.2)
	b.rect(Rect2(c.x - w - 6.0, c.y - FLOAT_DEPTH + 10.0, w * 2.0 + 12.0, FLOAT_DEPTH), SHADOW)
	# wheels, iron-shod, turning
	for sx: float in [-1.0, 1.0]:
		for wy: float in [-FLOAT_DEPTH + 40.0, -36.0]:
			var wc := c + Vector2(sx * (w + 2.0), wy)
			b.capsule(wc + Vector2(0.0, -20.0), wc + Vector2(0.0, 20.0), 11.0, WHEEL)
			var spin := fposmod(t * 3.2, 1.0)
			b.line(wc + Vector2(-8.0, -20.0 + spin * 40.0), wc + Vector2(8.0, -20.0 + spin * 40.0), Color(0.36, 0.34, 0.32), 3.0)
	# the deck and its painted skirt with a gold fringe
	b.rect(Rect2(c.x - w, c.y - FLOAT_DEPTH, w * 2.0, FLOAT_DEPTH - 8.0), DECK_DARK)
	b.rect(Rect2(c.x - w + 8.0, c.y - FLOAT_DEPTH + 8.0, w * 2.0 - 16.0, FLOAT_DEPTH - 24.0), DECK)
	for i in range(int(w * 2.0 / 18.0)):
		var px := c.x - w + 9.0 + float(i) * 18.0
		b.line(Vector2(px, c.y - FLOAT_DEPTH + 8.0), Vector2(px, c.y - 16.0), DECK_DARK, 1.5)
	b.rect(Rect2(c.x - w, c.y - 18.0, w * 2.0, 14.0), SKIRT)
	for i in range(int(w * 2.0 / 14.0)):
		var fx := c.x - w + 7.0 + float(i) * 14.0
		b.circle(Vector2(fx, c.y - 3.0), 4.0, SKIRT_GOLD)
	# flames licking up round the deck's edge: the float is burning
	for i in range(12 if burning else 0):
		var ang := float(i) / 12.0
		var fx := c.x + lerpf(-w + 14.0, w - 14.0, ang)
		var fy := c.y - FLOAT_DEPTH + 18.0 + (FLOAT_DEPTH - 48.0) * (0.5 + 0.5 * sin(float(i) * 1.7))
		var flick := 0.6 + 0.4 * sin(t * 13.0 + float(i) * 2.1)
		if i % 3 != 0:
			continue
		b.circle(Vector2(fx, fy), 13.0 * flick, Color(FLAME, 0.85))
		b.circle(Vector2(fx, fy - 6.0), 7.0 * flick, FLAME_CORE)
	_dimoni(b, c + Vector2(0.0, -FLOAT_DEPTH * 0.52), t)


# a target ring filling over `k` (0..1): a dashed outline and its fill
func _ring(b: ShapeBatch, at: Vector2, k: float) -> void:
	# a pool of firelight on the paving, growing as the rocket comes down
	b.glow(at, ROCKET_R * (1.5 + k * 0.6), Color(1.0, 0.55, 0.15, 0.35 + 0.35 * k), 0.15)
	b.circle(at, ROCKET_R * k, RING_FILL)
	var dashes := 16
	var pulse := 0.75 + 0.25 * sin(rumble * 18.0)
	for i in range(dashes):
		var a0 := float(i) * TAU / float(dashes) + rumble * 1.5
		var a1 := a0 + TAU / float(dashes) * 0.6
		var p0 := at + Vector2.from_angle(a0) * ROCKET_R
		var p1 := at + Vector2.from_angle(a1) * ROCKET_R
		b.line(p0, p1, Color(0.20, 0.05, 0.02, 0.8), 7.0)
		b.line(p0, p1, Color(RING, pulse), 4.0)
	b.circle(at, 6.0, Color(RING, 0.95))


# The Dimoni enthroned, seen from above and a little in front: shoulders and
# chest, the big head with its horns and grin facing down the street at
# them, one arm up with the fork of fireworks spraying sparks.
static func _dimoni(b: ShapeBatch, at: Vector2, t: float) -> void:
	var bob := sin(t * 2.0) * 2.0
	# the throne's back
	b.rect(Rect2(at.x - 58.0, at.y - 72.0, 116.0, 40.0), DECK_DARK)
	# body and shoulders, the cape behind
	b.circle(at + Vector2(0.0, -34.0), 60.0, DEVIL_BLACK)
	b.circle(at + Vector2(0.0, -12.0 + bob), 50.0, DEVIL)
	b.circle(at + Vector2(-46.0, -18.0 + bob), 20.0, DEVIL_DARK)
	b.circle(at + Vector2(46.0, -18.0 + bob), 20.0, DEVIL_DARK)
	# the left arm on the throne, the right one up with the fork
	b.capsule(at + Vector2(-46.0, -14.0 + bob), at + Vector2(-58.0, 26.0), 12.0, DEVIL)
	var hand := at + Vector2(52.0, -46.0 + bob)
	b.capsule(at + Vector2(46.0, -16.0 + bob), hand, 12.0, DEVIL)
	var tip := hand + Vector2(0.0, -46.0)
	b.line(hand + Vector2(0.0, 36.0), tip, FORK, 5.0)
	for px: float in [-12.0, 0.0, 12.0]:
		b.line(tip + Vector2(px, 0.0), tip + Vector2(px, -18.0), FORK, 4.0)
		# a firework on each prong, fizzing
		var spray := fposmod(t * 3.0 + px * 0.05, 1.0)
		for s in range(5):
			var a := -PI * 0.5 + (float(s) - 2.0) * 0.45 + sin(t * 7.0 + float(s)) * 0.2
			var d := 10.0 + spray * 34.0 + float(s % 2) * 8.0
			b.circle(tip + Vector2(px, -18.0) + Vector2.from_angle(a) * d, 2.6 * (1.0 - spray) + 1.0, SPARK)
	b.circle(hand, 12.0, DEVIL_DARK)
	# the head, horns and face, toward the street
	var head := at + Vector2(0.0, 30.0 + bob)
	for sx: float in [-1.0, 1.0]:
		b.quad(head + Vector2(sx * 22.0, -26.0), head + Vector2(sx * 40.0, -34.0),
			head + Vector2(sx * 54.0, -70.0), head + Vector2(sx * 30.0, -38.0), HORN)
	b.circle(head, 42.0, DEVIL)
	b.circle(head + Vector2(0.0, 14.0), 30.0, DEVIL_DARK)
	# black brows slanted down, yellow eyes
	for sx: float in [-1.0, 1.0]:
		b.quad(head + Vector2(sx * 6.0, -6.0), head + Vector2(sx * 32.0, -22.0),
			head + Vector2(sx * 34.0, -14.0), head + Vector2(sx * 8.0, 0.0), DEVIL_BLACK)
		b.circle(head + Vector2(sx * 17.0, 2.0), 7.0, EYE)
		b.circle(head + Vector2(sx * 17.0, 3.0), 3.0, DEVIL_BLACK)
	# the grin, teeth and all, and a pointed beard
	b.quad(head + Vector2(-24.0, 16.0), head + Vector2(24.0, 16.0),
		head + Vector2(16.0, 30.0), head + Vector2(-16.0, 30.0), DEVIL_BLACK)
	for i in range(6):
		var tx := -18.0 + float(i) * 7.2
		b.rect(Rect2(head.x + tx, head.y + 17.0, 5.0, 6.0), TEETH)
	b.quad(head + Vector2(-10.0, 32.0), head + Vector2(10.0, 32.0),
		head + Vector2(2.0, 54.0), head + Vector2(-2.0, 54.0), DEVIL_BLACK)
	# sparks off the horns: the fuse is in his crown
	for i in range(6):
		var f := fposmod(t * 2.4 + float(i) * 0.37, 1.0)
		var sx := -1.0 if i % 2 == 0 else 1.0
		var base := head + Vector2(sx * 54.0, -70.0)
		b.circle(base + Vector2(sx * f * 22.0, -f * 30.0 + f * f * 26.0), 2.4 * (1.0 - f) + 0.8, SPARK)
