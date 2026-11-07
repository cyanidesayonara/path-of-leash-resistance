class_name AwningDump
extends RefCounted

# WALK 5: EL DILUVI - AWNING RAIN DUMP ("Water coming down!")
# Signature live event for El Diluvi: shopkeepers poke waterlogged sagging
# canvas awnings with a broom handle during torrential downpours, dumping
# pooled rainwater onto the street with the traditional cry "Water coming down!".
#
# Gameplay contract:
# - 0.8 s warning telegraph: shopkeeper steps to the door holding a broom,
#   the awning canvas bulges with trembling water, and calls "Water coming down!".
# - Soft failure / hazard: distracted human walking under the dump gets drenched
#   (soak boost, patience drop, phone fumbled/wiped).
# - Dog trick: dashing through the falling water or splash pool awards
#   "awning splash! +2". Barking near the cascade awards "rain bark! +2".
# - Dodge: steering your human safely into the covered stone arcade on the west
#   side earns "dry passage! +2" / "Whew, nice save!".
# - Autowalk: central promenade at x = 640.0 remains completely clear of the dump.
# - Zero new draw calls: batched into ShapeBatch.

const ShapeBatch := preload("res://systems/shape_batch.gd")

const DUMP_Y := -1650.0
const SHOPKEEPER_POS := Vector2(852.0, -1650.0)
const CASCADE_X := 814.0
const SPLASH_RECT := Rect2(772.0, -1690.0, 68.0, 80.0)
const TRIGGER_Y := -1410.0
const WARN_DURATION := 0.8
const DUMP_DURATION := 1.3

enum State { IDLE, TELEGRAPH, DUMPING, DRAINED }

var state: State = State.IDLE
var timer: float = 0.0
var human_hit: bool = false
var dog_splashed: bool = false
var dog_barked: bool = false
var dodged: bool = false
var threatened: bool = false
var triggered: bool = false

# Drawing colors
const APRON_NAVY := Color(0.16, 0.22, 0.32)
const SHIRT_WHITE := Color(0.92, 0.90, 0.86)
const SKIN := Color(0.85, 0.68, 0.54)
const BROOM_WOOD := Color(0.58, 0.42, 0.26)
const BROOM_STRAW := Color(0.82, 0.72, 0.42)
const WATER_DEEP := Color(0.24, 0.40, 0.58, 0.75)
const WATER_CASCADE := Color(0.80, 0.90, 0.98, 0.85)
const WATER_FOAM := Color(0.94, 0.97, 1.0, 0.90)
const WATER_SPLASH := Color(0.70, 0.84, 0.96, 0.45)


func reset() -> void:
	state = State.IDLE
	timer = 0.0
	human_hit = false
	dog_splashed = false
	dog_barked = false
	dodged = false
	threatened = false
	triggered = false


func tick(delta: float, dog_pos: Vector2, dog_vel: Vector2, human_pos: Vector2) -> Dictionary:
	var out: Dictionary = {
		"warn": false,
		"dump": false,
		"soak": false,
		"dog_splash": false,
		"dog_bark": false,
		"dodge": false,
	}

	match state:
		State.IDLE:
			# Trigger when approaching northward on outward walk
			if not triggered and (dog_pos.y < TRIGGER_Y or human_pos.y < TRIGGER_Y) and human_pos.y > DUMP_Y:
				state = State.TELEGRAPH
				timer = WARN_DURATION
				triggered = true
				out["warn"] = true

		State.TELEGRAPH:
			timer -= delta
			if timer <= 0.0:
				state = State.DUMPING
				timer = DUMP_DURATION
				out["dump"] = true

		State.DUMPING:
			timer -= delta

			# Check human collision with water cascade
			if not human_hit and SPLASH_RECT.has_point(human_pos):
				human_hit = true
				out["soak"] = true

			# Check dog splash trick: dashing through cascade at speed
			if not dog_splashed and SPLASH_RECT.has_point(dog_pos) and dog_vel.length() > 90.0:
				dog_splashed = true
				out["dog_splash"] = true

			if timer <= 0.0:
				state = State.DRAINED

		State.DRAINED:
			pass

	if state == State.DUMPING or state == State.DRAINED:
		var close := state == State.DUMPING and SPLASH_RECT.grow(28.0).has_point(human_pos)
		var step := NearMiss.consider(close, human_hit, threatened, dodged)
		threatened = bool(step["threatened"])
		if bool(step["dodge"]):
			dodged = true
			out["dodge"] = true

	return out


func on_bark(dog_pos: Vector2) -> bool:
	if state == State.DUMPING and not dog_barked:
		if dog_pos.distance_to(Vector2(CASCADE_X, DUMP_Y)) < 90.0:
			dog_barked = true
			return true
	return false


func draw(b: ShapeBatch, vt: float, vb: float) -> void:
	if DUMP_Y < vt - 120.0 or DUMP_Y > vb + 120.0:
		return

	var t: float = AnimClock.msec() / 1000.0

	# 1. Shopkeeper standing at shopfront doorway holding broom
	_draw_shopkeeper(b, t)

	# 2. Awning canvas sag / water bulge
	_draw_canvas_water(b, t)

	# 3. Falling water cascade and ground splash
	if state == State.DUMPING:
		_draw_cascade(b, t)
	elif state == State.DRAINED:
		_draw_drain_drips(b, t)


func _draw_shopkeeper(b: ShapeBatch, t: float) -> void:
	var p: Vector2 = SHOPKEEPER_POS
	# Contact shadow
	b.circle(p + Vector2(2.0, 4.0), 10.0, Color(0.04, 0.05, 0.08, 0.25))

	# Body / Apron
	b.circle(p, 9.5, APRON_NAVY)
	b.rect(Rect2(p.x - 6.0, p.y - 4.0, 12.0, 10.0), APRON_NAVY.darkened(0.1))
	b.line(Vector2(p.x - 3.0, p.y - 4.0), Vector2(p.x + 3.0, p.y + 4.0), SHIRT_WHITE, 1.8)

	# Head / Hair
	var head_pos: Vector2 = p + Vector2(-2.0, -1.0)
	b.circle(head_pos, 5.5, SKIN)
	b.circle(head_pos + Vector2(0.5, -1.0), 5.0, Color(0.30, 0.22, 0.16))

	# Broom handle extending up and out toward the awning canvas
	var broom_tip: Vector2
	if state == State.TELEGRAPH:
		# Poking up against canvas with trembling vibration
		var vib: float = sin(t * 36.0) * 1.5
		broom_tip = Vector2(CASCADE_X + 16.0 + vib, DUMP_Y)
	elif state == State.DUMPING:
		# Pushed high up into canvas
		broom_tip = Vector2(CASCADE_X + 8.0, DUMP_Y - 4.0)
	else:
		# Resting at shopkeeper's side
		broom_tip = p + Vector2(-18.0, 12.0)

	var hand_pos: Vector2 = p + Vector2(-5.0, 1.0)
	b.line(hand_pos + Vector2(6.0, 8.0), broom_tip, BROOM_WOOD, 2.2)
	# Broom straw head at tip
	b.line(broom_tip, broom_tip + Vector2(-4.0, -5.0), BROOM_STRAW, 5.0)
	b.line(broom_tip + Vector2(-1.0, -1.0), broom_tip + Vector2(-5.0, -6.0), BROOM_STRAW.darkened(0.2), 2.0)


func _draw_canvas_water(b: ShapeBatch, t: float) -> void:
	if state == State.TELEGRAPH:
		# Heavy sag bulge in awning canvas
		var bulge_center := Vector2(CASCADE_X + 18.0, DUMP_Y)
		var pulse: float = 1.0 + sin(t * 18.0) * 0.15
		b.circle(bulge_center, 12.0 * pulse, WATER_DEEP)
		b.circle(bulge_center + Vector2(-1.0, -1.0), 7.0 * pulse, Color(0.42, 0.62, 0.82, 0.6))
		# Dripping preview droplets along hem
		for di in range(3):
			var d_off: float = fmod(t * 4.0 + float(di) * 0.33, 1.0)
			var dp := Vector2(CASCADE_X + 2.0, DUMP_Y - 14.0 + float(di) * 14.0 + d_off * 10.0)
			b.circle(dp, 2.0, WATER_CASCADE)
	elif state == State.IDLE:
		# Slight glistening sag before trigger
		var bulge_center := Vector2(CASCADE_X + 18.0, DUMP_Y)
		b.circle(bulge_center, 6.0, Color(0.20, 0.32, 0.48, 0.4))


func _draw_cascade(b: ShapeBatch, t: float) -> void:
	# Waterfall pouring from awning hem (x = CASCADE_X) down onto street
	var phase: float = (DUMP_DURATION - timer) / DUMP_DURATION
	var intensity: float = sin(phase * PI)

	# 1. Sheet of falling water streams
	var y_top: float = DUMP_Y - 24.0
	var y_bot: float = DUMP_Y + 24.0
	var streams: int = 7
	for si in range(streams):
		var sy: float = lerpf(y_top, y_bot, float(si) / float(streams - 1))
		var x_fall: float = CASCADE_X - 4.0 - float(si % 3) * 3.0
		var flow: float = fmod(t * 12.0 + float(si) * 0.4, 1.0)
		var start_p := Vector2(x_fall + 6.0, sy - 2.0)
		var end_p := Vector2(x_fall - 10.0, sy + 3.0)
		b.line(start_p, end_p, WATER_CASCADE, 3.5 * intensity)
		b.line(start_p + Vector2(1.0, 0.0), end_p + Vector2(1.0, 0.0), WATER_FOAM, 1.6 * intensity)
		# Falling droplets
		var drop_p: Vector2 = start_p.lerp(end_p, flow)
		b.circle(drop_p, 2.5 * intensity, WATER_FOAM)

	# 2. Foaming ground splash pool
	var ground_center := Vector2(CASCADE_X - 16.0, DUMP_Y)
	b.circle(ground_center, 22.0 * intensity, WATER_SPLASH)
	b.circle(ground_center, 14.0 * intensity, Color(0.82, 0.92, 1.0, 0.6 * intensity))

	# 3. Expanding splash rings
	for ri in range(4):
		var r_ph: float = fmod(t * 3.5 + float(ri) * 0.25, 1.0)
		var r_rad: float = 8.0 + r_ph * 24.0
		var r_alpha: float = (1.0 - r_ph) * 0.7 * intensity
		b.circle(ground_center + Vector2(sin(float(ri) * 2.0) * 8.0, cos(float(ri) * 3.0) * 12.0),
			r_rad, Color(0.88, 0.94, 1.0, r_alpha))

	# 4. Flying water droplets bouncing into street
	for bi in range(6):
		var b_angle: float = float(bi) * TAU / 6.0 + t * 4.0
		var b_dist: float = 14.0 + fmod(t * 40.0 + float(bi) * 7.0, 22.0)
		var bp: Vector2 = ground_center + Vector2(cos(b_angle) * b_dist * 0.8, sin(b_angle) * b_dist * 0.5)
		b.circle(bp, 1.8 * intensity, WATER_FOAM)


func _draw_drain_drips(b: ShapeBatch, t: float) -> void:
	# Residual glistening wet patch on ground
	var ground_center := Vector2(CASCADE_X - 16.0, DUMP_Y)
	b.circle(ground_center, 12.0, Color(0.25, 0.38, 0.52, 0.35))
	# Occasional slow drip
	var drip_ph: float = fmod(t * 1.5, 1.0)
	if drip_ph < 0.6:
		var dp := Vector2(CASCADE_X, DUMP_Y + drip_ph * 10.0)
		b.circle(dp, 1.6, WATER_CASCADE)
