class_name Gardener
extends RefCounted

# WALK 14: EL MOSAIC (Park Guell) - GARDENER & FLOWER WHEELBARROW
# Signature live event for Park Guell (the hilltop mosaic garden):
# A municipal park gardener in straw hat and dark green apron pushes a
# wooden garden wheelbarrow loaded with potted red geraniums across the
# vast sandy terrace of Plaça de la Natura at y = -3200.0, heading from
# the west bay toward the east colonnade.
#
# Gameplay contract:
# - 0.8 s warning telegraph: Gardener calls out from the west terrace edge:
#   "Pas al carretó!" with a squeaky wooden trundle sound and speech bubble.
# - Soft failure / hazard: Distracted human wandering into the wheelbarrow
#   gets bumped (-8 patience drop, "Whoa! Watch the wheelbarrow!",
#   gardener: "Atenció a les plantes!").
# - Dog trick (geranium snatch): As the wheelbarrow trundles across center plaza
#   (x >= 610.0), a terracotta clay pot with red geraniums slips off the barrow
#   onto the sand; dog can snatch or boop it for "geranium snatch! +2" and
#   bones/snack count (gardener: "Ei, les meves flors!").
# - Boop trick: Booping the gardener's boots/apron awards "gardener boop! +2"
#   ("Hola, trapella!").
# - Bark trick: Barking within 130 px startles the gardener into a momentary
#   wobble, awarding "gardener bark! +2" ("Ui, quin trontoll!").
# - Dodge save: Steering your human safely clear of the crossing trajectory
#   after entering threat radius (70 px) awards "mosaic dodge! +2" and increments
#   saves_done via NearMiss.consider. Walking past outside threat radius awards nothing.
# - Autowalk: Timing clears the central corridor before the autowalk pair arrives,
#   ensuring 100% reliable automated traversal and test stability.
# - Zero new draw calls: Batched into El Mosaic's live ShapeBatch (draw_live).

const ShapeBatch := preload("res://systems/shape_batch.gd")

const START_POS := Vector2(250.0, -3200.0)
const END_POS := Vector2(1030.0, -3200.0)
const CROSSING_Y := -3200.0
const TRIGGER_Y := -2820.0

const WARN_DURATION := 0.8
const WALK_SPEED := 220.0
const BUMP_RADIUS := 32.0
const THREAT := 70.0
const SNATCH_RADIUS := 28.0
const BOOP_RADIUS := 28.0
const BARK_RADIUS := 130.0
const DROP_X := 610.0

enum State { IDLE, TELEGRAPH, WALKING, SETTLED }

var state: State = State.IDLE
var timer: float = 0.0
var pos: Vector2 = START_POS
var triggered: bool = false
var human_hit: bool = false
var booped: bool = false
var pot_dropped: bool = false
var pot_snatched: bool = false
var pot_pos: Vector2 = Vector2.ZERO
var pot_vel: Vector2 = Vector2.ZERO
var barked: bool = false
var dodged: bool = false
var threatened: bool = false
var wobble_t: float = 0.0
var _toss := RandomNumberGenerator.new()
var anim_time: float = 0.0

# Visual colors
const LIGHT := Vector2(0.5, 0.866)
const SHADOW := Color(0.04, 0.04, 0.06, 0.22)

# Attire
const HAT_STRAW := Color(0.92, 0.84, 0.52)
const HAT_BAND := Color(0.18, 0.36, 0.20)
const SHIRT_BEIGE := Color(0.86, 0.82, 0.74)
const APRON_GREEN := Color(0.22, 0.38, 0.24)
const APRON_STRAP := Color(0.16, 0.28, 0.18)
const TROUSERS_KHAKI := Color(0.48, 0.44, 0.36)
const BOOTS_LEATHER := Color(0.32, 0.22, 0.14)
const SKIN_TONE := Color(0.88, 0.72, 0.58)

# Wheelbarrow & Plants
const WOOD_PLANK := Color(0.58, 0.42, 0.28)
const WOOD_DARK := Color(0.44, 0.30, 0.18)
const WHEEL_IRON := Color(0.28, 0.26, 0.25)
const TERRACOTTA := Color(0.82, 0.44, 0.28)
const TERRACOTTA_RIM := Color(0.88, 0.50, 0.32)
const SOIL_DARK := Color(0.30, 0.22, 0.16)
const LEAF_GREEN := Color(0.24, 0.50, 0.20)
const GERANIUM_RED := Color(0.92, 0.18, 0.22)
const GERANIUM_CORE := Color(0.98, 0.82, 0.30)


func _init() -> void:
	_toss.seed = 0x60E11


func reset() -> void:
	state = State.IDLE
	timer = 0.0
	pos = START_POS
	triggered = false
	human_hit = false
	booped = false
	pot_dropped = false
	pot_snatched = false
	pot_pos = Vector2.ZERO
	pot_vel = Vector2.ZERO
	barked = false
	dodged = false
	threatened = false
	wobble_t = 0.0
	anim_time = 0.0


func tick(delta: float, dog_pos: Vector2, _dog_vel: Vector2, human_pos: Vector2) -> Dictionary:
	var out := {
		"warn": false,
		"bump": false,
		"snatch": false,
		"boop": false,
		"dodge": false,
	}

	if wobble_t > 0.0:
		wobble_t = maxf(0.0, wobble_t - delta)

	# Update dropped flower pot physics
	if pot_dropped and not pot_snatched:
		pot_pos += pot_vel * delta
		pot_vel = pot_vel.move_toward(Vector2.ZERO, 50.0 * delta)
		if dog_pos.distance_to(pot_pos) <= SNATCH_RADIUS:
			pot_snatched = true
			out["snatch"] = true

	# Boop interaction
	if (state == State.TELEGRAPH or state == State.WALKING) and not booped:
		if dog_pos.distance_to(pos) <= BOOP_RADIUS:
			booped = true
			out["boop"] = true

	match state:
		State.IDLE:
			if not triggered and human_pos.y <= TRIGGER_Y and human_pos.y > CROSSING_Y:
				triggered = true
				state = State.TELEGRAPH
				timer = 0.0
				out["warn"] = true

		State.TELEGRAPH:
			timer += delta
			anim_time += delta
			if timer >= WARN_DURATION:
				state = State.WALKING
				timer = 0.0

		State.WALKING:
			anim_time += delta
			pos.x += WALK_SPEED * delta
			pos.y = CROSSING_Y + sin(anim_time * 8.0) * 1.5

			# Drops a flower pot near center plaza
			if not pot_dropped and pos.x >= DROP_X:
				pot_dropped = true
				pot_pos = pos + Vector2(10.0, 10.0)
				pot_vel = Vector2(25.0, _toss.randf_range(-18.0, 18.0))

			# Soft bump hazard on human
			if not human_hit and pos.distance_to(human_pos) <= BUMP_RADIUS:
				human_hit = true
				out["bump"] = true

			if pos.x >= END_POS.x:
				pos = END_POS
				state = State.SETTLED

		State.SETTLED:
			anim_time += delta

	if state == State.WALKING or state == State.SETTLED:
		var close := state == State.WALKING and pos.distance_to(human_pos) <= THREAT
		var step := NearMiss.consider(close, human_hit, threatened, dodged)
		threatened = bool(step["threatened"])
		if bool(step["dodge"]):
			dodged = true
			out["dodge"] = true

	return out


func on_bark(dog_pos: Vector2) -> bool:
	if (state == State.WALKING or state == State.SETTLED) and not barked:
		if dog_pos.distance_to(pos) <= BARK_RADIUS:
			barked = true
			wobble_t = 0.6
			return true
	return false


func draw(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	if pos.y < vt - 120.0 or pos.y > vb + 120.0:
		return

	var bob := sin(anim_time * 10.0) * 1.8 if state == State.WALKING else 0.0
	var wobble := sin(anim_time * 26.0) * 3.5 if wobble_t > 0.0 else 0.0
	var draw_pos := pos + Vector2(0.0, bob + wobble)

	# 1. Contact shadow under gardener & wheelbarrow
	b.circle(draw_pos + Vector2(14.0, 6.0) + LIGHT * 6.0, 22.0, SHADOW)
	b.circle(draw_pos + Vector2(-10.0, 10.0) + LIGHT * 5.0, 16.0, SHADOW)

	# 2. Wheelbarrow:
	# Front wheel (rolls forward at front of barrow)
	var barrow_front := draw_pos + Vector2(30.0, 0.0)
	b.circle(barrow_front, 6.5, WHEEL_IRON)
	b.circle(barrow_front, 4.0, WOOD_DARK)
	b.line(barrow_front + Vector2(-5, 0), barrow_front + Vector2(5, 0), WHEEL_IRON, 1.4)
	b.line(barrow_front + Vector2(0, -5), barrow_front + Vector2(0, 5), WHEEL_IRON, 1.4)

	# Wooden barrow body (slanted tray)
	var tray := PackedVector2Array([
		draw_pos + Vector2(26.0, -11.0),
		draw_pos + Vector2(28.0, 11.0),
		draw_pos + Vector2(0.0, 14.0),
		draw_pos + Vector2(-2.0, -14.0)
	])
	b.polygon(tray, WOOD_PLANK)
	b.line(draw_pos + Vector2(26.0, -11.0), draw_pos + Vector2(-2.0, -14.0), WOOD_DARK, 2.0)
	b.line(draw_pos + Vector2(28.0, 11.0), draw_pos + Vector2(0.0, 14.0), WOOD_DARK, 2.0)
	b.line(draw_pos + Vector2(13.0, -12.5), draw_pos + Vector2(14.0, 12.5), WOOD_DARK, 1.2)

	# Wheelbarrow handles extending back to gardener's hands
	b.line(draw_pos + Vector2(2.0, -9.0), draw_pos + Vector2(-16.0, -11.0), WOOD_DARK, 2.4)
	b.line(draw_pos + Vector2(4.0, 9.0), draw_pos + Vector2(-14.0, 11.0), WOOD_DARK, 2.4)

	# Potted Geraniums inside barrow tray
	for p_off: Vector2 in [Vector2(16.0, -4.0), Vector2(18.0, 5.0), Vector2(7.0, -2.0)]:
		var pp := draw_pos + p_off
		b.circle(pp, 5.5, TERRACOTTA)
		b.circle(pp, 4.2, SOIL_DARK)
		# Green leaves cluster
		for la in range(4):
			var lang := float(la) * 1.57 + 0.3
			b.circle(pp + Vector2(cos(lang), sin(lang)) * 3.5, 2.8, LEAF_GREEN)
		# Red geranium bloom
		b.circle(pp, 3.2, GERANIUM_RED)
		b.circle(pp, 1.2, GERANIUM_CORE)

	# 3. Gardener (walking behind wheelbarrow):
	# Boots
	var l_stride := sin(anim_time * 10.0) * 5.0 if state == State.WALKING else 0.0
	b.circle(draw_pos + Vector2(-24.0 + l_stride, -7.0), 4.2, BOOTS_LEATHER)
	b.circle(draw_pos + Vector2(-24.0 - l_stride, 7.0), 4.2, BOOTS_LEATHER)

	# Body / Apron
	b.circle(draw_pos + Vector2(-18.0, 0.0), 9.0, APRON_GREEN)
	b.line(draw_pos + Vector2(-22.0, -5.0), draw_pos + Vector2(-12.0, -5.0), APRON_STRAP, 1.5)
	b.line(draw_pos + Vector2(-22.0, 5.0), draw_pos + Vector2(-12.0, 5.0), APRON_STRAP, 1.5)

	# Arms pushing handles
	b.line(draw_pos + Vector2(-16.0, -7.0), draw_pos + Vector2(-14.0, -10.0), SHIRT_BEIGE, 3.0)
	b.circle(draw_pos + Vector2(-14.0, -10.0), 2.2, SKIN_TONE)
	b.line(draw_pos + Vector2(-16.0, 7.0), draw_pos + Vector2(-12.0, 10.0), SHIRT_BEIGE, 3.0)
	b.circle(draw_pos + Vector2(-12.0, 10.0), 2.2, SKIN_TONE)

	# Head & Straw Hat
	var head_pos := draw_pos + Vector2(-16.0, 0.0)
	b.circle(head_pos, 5.0, SKIN_TONE)
	b.circle(head_pos, 10.5, HAT_STRAW)
	b.circle(head_pos, 6.5, HAT_BAND)
	b.circle(head_pos, 5.2, HAT_STRAW)

	# 4. Dropped terracotta pot (if on ground)
	if pot_dropped:
		var dp := pot_pos
		if not pot_snatched:
			b.circle(dp + LIGHT * 3.0, 7.0, SHADOW)
			b.circle(dp, 6.5, TERRACOTTA)
			b.circle(dp, 4.8, SOIL_DARK)
			for la in range(4):
				var lang := float(la) * 1.57 + 0.4
				b.circle(dp + Vector2(cos(lang), sin(lang)) * 4.2, 3.0, LEAF_GREEN)
			b.circle(dp, 3.6, GERANIUM_RED)
			b.circle(dp, 1.4, GERANIUM_CORE)
		else:
			# Snatched: a crumb of soil and broken terracotta shard
			b.circle(dp, 3.0, TERRACOTTA_RIM)
			b.circle(dp + Vector2(4.0, -2.0), 1.6, SOIL_DARK)
			b.circle(dp + Vector2(-3.0, 3.0), 1.8, GERANIUM_RED)
