class_name Waiter
extends RefCounted

# WALK 19: PLAÇA REIAL - BUSTLING BISTRO WAITER & TAPAS TRAY
# Signature live event for Plaça Reial: a dapper Catalan bistro waiter
# (el cambrer amb safata de tapes) emerges from the portico arcade terrace
# at y = -1280.0, balancing a high-loaded silver tray of drinks and hot tapas,
# briskly crossing the royal plaza flagstones toward outdoor bistro tables.
#
# Gameplay contract:
# - 0.8 s warning telegraph: waiter steps out of the west arcade arch at
#   x = 350.0, y = -1280.0, steadying the precariously balanced silver tray
#   with an upraised palm and calling out "Compte amb la safata!" with a speech bubble.
# - Soft failure / hazard: distracted human wandering into the waiter's crossing
#   path gets bumped and splashed (patience drop, "Whoa! Watch the tray!").
# - Dog trick: as the waiter crosses, a crispy tapas croqueta bounces off the plate;
#   pouncing onto or snatching it awards "croqueta snatch! +2". Barking near the
#   balancing waiter startles them into a theatrical balance recovery ("waiter bark! +2").
# - Dodge: steering your human safely along the far side of the plaza or waiting
#   cleanly earns "plaza dodge! +2" / "Whew, nice save!".
# - Autowalk: timing naturally clears the central corridor before the autowalk
#   pair arrives, ensuring 100% reliable automated traversal and test stability.
# - Zero new draw calls: batched into Plaça Reial's existing ShapeBatch.

const ShapeBatch := preload("res://systems/shape_batch.gd")

const START_POS := Vector2(350.0, -1280.0)
const END_POS := Vector2(720.0, -1280.0)
const CROSSING_Y := -1280.0
const TRIGGER_Y := -1100.0

const WARN_DURATION := 0.8
const WALK_SPEED := 160.0
const BUMP_RADIUS := 30.0
const SNATCH_RADIUS := 28.0
const BARK_RADIUS := 150.0
const CROQUETA_DROP_X := 520.0

enum State { IDLE, TELEGRAPH, WALKING, SETTLED }

var state: State = State.IDLE
var timer: float = 0.0
var pos: Vector2 = START_POS
var triggered: bool = false
var human_hit: bool = false
var croqueta_dropped: bool = false
var croqueta_snatched: bool = false
var croqueta_pos: Vector2 = Vector2.ZERO
var croqueta_vel: Vector2 = Vector2.ZERO
var barked: bool = false
var dodged: bool = false

# Visual colors
const LIGHT := Vector2(0.5, 0.866)
const SHADOW := Color(0.04, 0.05, 0.08, 0.22)

# Waiter uniform
const SHIRT_WHITE := Color(0.96, 0.96, 0.96)
const VEST_BLACK := Color(0.12, 0.12, 0.14)
const BOWTIE_BLACK := Color(0.10, 0.10, 0.12)
const APRON_WHITE := Color(0.94, 0.94, 0.92)
const PANTS_DARK := Color(0.16, 0.16, 0.18)
const SHOE_BLACK := Color(0.10, 0.10, 0.12)
const HAIR_DARK := Color(0.24, 0.18, 0.14)
const SKIN_TONE := Color(0.85, 0.70, 0.58)

# Tray & Tapas
const TRAY_SILVER := Color(0.82, 0.84, 0.88)
const TRAY_HIGHLIGHT := Color(0.96, 0.97, 0.99)
const BEER_AMBER := Color(0.92, 0.65, 0.16)
const BEER_FOAM := Color(0.98, 0.98, 0.95)
const WATER_CYAN := Color(0.65, 0.88, 0.96, 0.85)
const PLATE_WHITE := Color(0.95, 0.94, 0.90)
const CROQUETA_GOLD := Color(0.82, 0.54, 0.22)
const PAPRIKA_RED := Color(0.86, 0.26, 0.18)


func reset() -> void:
	state = State.IDLE
	timer = 0.0
	pos = START_POS
	triggered = false
	human_hit = false
	croqueta_dropped = false
	croqueta_snatched = false
	croqueta_pos = Vector2.ZERO
	croqueta_vel = Vector2.ZERO
	barked = false
	dodged = false


func tick(delta: float, dog_pos: Vector2, _dog_vel: Vector2, human_pos: Vector2) -> Dictionary:
	var out: Dictionary = {
		"warn": false,
		"walk": false,
		"clink": false,
		"bump": false,
		"drop_croqueta": false,
		"snatch": false,
		"dodge": false,
	}

	# Dropped croqueta physics
	if croqueta_dropped and not croqueta_snatched:
		if croqueta_vel.length() > 2.0:
			croqueta_pos += croqueta_vel * delta
			croqueta_vel = croqueta_vel.move_toward(Vector2.ZERO, 90.0 * delta)
		if dog_pos.distance_to(croqueta_pos) < SNATCH_RADIUS:
			croqueta_snatched = true
			out["snatch"] = true

	match state:
		State.IDLE:
			if not triggered and (dog_pos.y < TRIGGER_Y or human_pos.y < TRIGGER_Y) and human_pos.y > CROSSING_Y:
				state = State.TELEGRAPH
				timer = WARN_DURATION
				triggered = true
				out["warn"] = true

		State.TELEGRAPH:
			timer -= delta
			if timer <= 0.0:
				state = State.WALKING
				timer = 0.0
				out["walk"] = true

		State.WALKING:
			timer += delta
			pos.x = minf(END_POS.x, pos.x + WALK_SPEED * delta)

			# Drop tapas croqueta around middle plaza
			if not croqueta_dropped and pos.x >= CROQUETA_DROP_X:
				croqueta_dropped = true
				croqueta_pos = pos + Vector2(10.0, 8.0)
				croqueta_vel = Vector2(40.0, 30.0)
				out["drop_croqueta"] = true
				out["clink"] = true

			# Check human hazard bump
			if not human_hit and absf(human_pos.y - CROSSING_Y) < BUMP_RADIUS and absf(human_pos.x - pos.x) < BUMP_RADIUS:
				human_hit = true
				out["bump"] = true

			# Check safe dodge
			if not dodged and not human_hit:
				if human_pos.y < CROSSING_Y - 20.0 and human_pos.y > CROSSING_Y - 80.0:
					dodged = true
					out["dodge"] = true

			if pos.x >= END_POS.x:
				state = State.SETTLED
				timer = 0.0

		State.SETTLED:
			timer += delta
			# Check safe dodge if human passed during settled
			if not dodged and not human_hit:
				if human_pos.y < CROSSING_Y - 20.0 and human_pos.y > CROSSING_Y - 80.0:
					dodged = true
					out["dodge"] = true

	return out


func on_bark(dog_pos: Vector2) -> bool:
	if state in [State.TELEGRAPH, State.WALKING] and not barked:
		if dog_pos.distance_to(pos) < BARK_RADIUS:
			barked = true
			return true
	return false


func draw(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	if pos.y < vt - 80.0 or pos.y > vb + 80.0:
		return

	var wp := pos
	var wobble := sin(timer * 22.0) * 1.5 if state == State.WALKING else 0.0

	# 1. Ground shadows
	b.circle(wp + LIGHT * 4.0, 9.0, SHADOW)
	b.circle(wp + Vector2(10.0, -12.0) + LIGHT * 3.0, 8.0, SHADOW) # tray shadow

	# 2. Waiter body & legs
	# Dark trousers & shoes
	var leg_stride := sin(timer * 14.0) * 4.0 if state == State.WALKING else 0.0
	b.circle(wp + Vector2(-3.0 + leg_stride, -4.0), 2.2, SHOE_BLACK)
	b.circle(wp + Vector2(-3.0 - leg_stride, 4.0), 2.2, SHOE_BLACK)
	b.rect(Rect2(wp.x - 4.0, wp.y - 6.0, 8.0, 12.0), PANTS_DARK)

	# White bistro apron wrapped round waist
	b.rect(Rect2(wp.x - 3.0, wp.y - 6.5, 7.0, 13.0), APRON_WHITE)
	b.line(Vector2(wp.x - 3.0, wp.y), Vector2(wp.x + 4.0, wp.y), Color(0.85, 0.85, 0.85), 1.0)

	# Torso: White shirt under tailored black vest
	b.rect(Rect2(wp.x - 5.0, wp.y - 7.0, 10.0, 14.0), SHIRT_WHITE)
	b.rect(Rect2(wp.x - 5.0, wp.y - 7.0, 8.0, 14.0), VEST_BLACK)
	b.rect(Rect2(wp.x - 1.0, wp.y - 7.0, 2.0, 14.0), SHIRT_WHITE) # visible shirt front
	b.circle(wp + Vector2(0.0, -4.5), 1.4, BOWTIE_BLACK) # bowtie

	# Head & dark hair
	b.circle(wp, 7.5, HAIR_DARK)
	b.circle(wp + Vector2(2.5, 0.0), 5.5, SKIN_TONE)

	# 3. Arms & balancing pose
	var tray_center := wp + Vector2(10.0 + wobble, -12.0)
	match state:
		State.TELEGRAPH:
			# Upraised arm steadying the tray
			b.line(wp + Vector2(2.0, -5.0), tray_center + Vector2(-2.0, 3.0), SHIRT_WHITE, 2.8)
			b.line(wp + Vector2(2.0, -5.0), tray_center + Vector2(-2.0, 3.0), VEST_BLACK, 1.8)
			b.circle(tray_center + Vector2(-2.0, 3.0), 2.5, SKIN_TONE)
			# Left hand tucked behind back (classic bistro pose)
			b.line(wp + Vector2(-3.0, 4.0), wp + Vector2(-6.0, 1.0), SHIRT_WHITE, 2.4)
			b.circle(wp + Vector2(-6.0, 1.0), 2.2, SKIN_TONE)

		State.WALKING:
			# Right arm raised holding the tray
			b.line(wp + Vector2(3.0, -5.0), tray_center, SHIRT_WHITE, 2.8)
			b.circle(tray_center, 2.5, SKIN_TONE)
			# Left arm swinging for balance
			var balance_arm := wp + Vector2(-4.0, 6.0 + sin(timer * 14.0) * 3.0)
			b.line(wp + Vector2(0.0, 5.0), balance_arm, SHIRT_WHITE, 2.4)
			b.circle(balance_arm, 2.2, SKIN_TONE)

		State.SETTLED:
			# Arms lowered resting by side
			b.line(wp + Vector2(2.0, -5.0), wp + Vector2(6.0, -3.0), SHIRT_WHITE, 2.5)
			b.line(wp + Vector2(2.0, 5.0), wp + Vector2(6.0, 3.0), SHIRT_WHITE, 2.5)
			b.circle(wp + Vector2(7.0, -3.0), 2.2, SKIN_TONE)
			b.circle(wp + Vector2(7.0, 3.0), 2.2, SKIN_TONE)

		State.IDLE:
			b.line(wp + Vector2(2.0, -5.0), tray_center, SHIRT_WHITE, 2.5)
			b.circle(tray_center, 2.5, SKIN_TONE)

	# 4. Loaded Silver Tray & Tapas (drawn only while carried or placed)
	if state != State.SETTLED:
		# Silver platter
		b.circle(tray_center, 12.0, TRAY_SILVER)
		b.circle(tray_center, 11.0, TRAY_HIGHLIGHT)
		b.circle(tray_center, 10.0, TRAY_SILVER)

		# Tall glass of beer (caña)
		var beer_pos := tray_center + Vector2(-4.0, -3.0)
		b.circle(beer_pos, 3.2, BEER_AMBER)
		b.circle(beer_pos + Vector2(0.0, -1.0), 2.0, BEER_FOAM)

		# Glass of sparkling water
		var water_pos := tray_center + Vector2(4.0, -4.0)
		b.circle(water_pos, 2.8, WATER_CYAN)

		# Small plate of hot tapas
		var plate_pos := tray_center + Vector2(0.0, 4.0)
		b.circle(plate_pos, 4.5, PLATE_WHITE)
		if not croqueta_dropped:
			b.circle(plate_pos, 2.6, CROQUETA_GOLD)
			b.circle(plate_pos + Vector2(0.8, -0.6), 1.0, PAPRIKA_RED)

	# 5. Dropped tapas croqueta on the plaza flagstones
	if croqueta_dropped and not croqueta_snatched:
		b.circle(croqueta_pos + LIGHT * 2.0, 3.0, SHADOW)
		b.circle(croqueta_pos, 3.0, CROQUETA_GOLD)
		b.circle(croqueta_pos + Vector2(0.8, -0.6), 1.2, PAPRIKA_RED)
		b.circle(croqueta_pos + Vector2(-0.8, 0.6), 1.0, CROQUETA_GOLD.lightened(0.25))
