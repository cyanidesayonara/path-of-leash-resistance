class_name Unicyclist
extends RefCounted

# WALK 21: EL TIBIDABO - SUMMIT FAIRGROUND JUGGLING UNICYCLIST
# Signature live event for El Tibidabo (the mountain road & fairground summit):
# An acrobatic fairground street performer on a tall unicycle (l'equilibrista
# del Tibidabo) emerges from the scenic balustrade terrace at y = -2100.0,
# teetering and juggling colourful pins as they pedal across the mountain road
# toward the eastern pine ridge.
#
# Gameplay contract:
# - 0.8 s warning telegraph: Unicyclist teeters on the stone road kerb at
#   x = 390.0, y = -2100.0, steadying their balance with outstretched arms
#   and shouting "Unicycle coming through!" with a telegraphed speech bubble.
# - Soft failure / hazard: distracted human wandering into the unicyclist's path
#   gets bumped by the wobbling wheel (-8 patience drop, "A unicycle? Really?").
# - Dog trick: as the performer pedals past the central road (x >= 550.0), a spinning
#   juggling pin slips from the juggle and clatters onto the asphalt; pouncing or
#   booping it awards "pin snatch! +2".
# - Bark trick: barking near the teetering performer startles them into an acrobatic
#   balancing pirouette, awarding "unicycle bark! +2" ("Epa!", "Phew, close one!").
# - Boop trick: booping the unicyclist directly awards "unicycle boop! +2".
# - Dodge: steering your human safely clear past the crossing trajectory
#   awards "summit dodge! +2" / "Whew, nice save!".
# - Autowalk: timing naturally clears the central road (x = 640.0) before the
#   autowalk pair arrives, ensuring 100% reliable automated traversal and test stability.
# - Zero new draw calls: batched into El Tibidabo's existing ShapeBatch.

const ShapeBatch := preload("res://systems/shape_batch.gd")

const START_POS := Vector2(390.0, -2100.0)
const END_POS := Vector2(840.0, -2100.0)
const CROSSING_Y := -2100.0
const TRIGGER_Y := -1920.0

const WARN_DURATION := 0.8
const RIDE_SPEED := 155.0
const BUMP_RADIUS := 30.0
const THREAT := 64.0
const SNATCH_RADIUS := 28.0
const BOOP_RADIUS := 26.0
const BARK_RADIUS := 140.0
const PIN_DROP_X := 550.0

enum State { IDLE, TELEGRAPH, RIDING, SETTLED }

var state: State = State.IDLE
var timer: float = 0.0
var pos: Vector2 = START_POS
var triggered: bool = false
var human_hit: bool = false
var booped: bool = false
var pin_dropped: bool = false
var pin_snatched: bool = false
var pin_pos: Vector2 = Vector2.ZERO
var pin_vel: Vector2 = Vector2.ZERO
var barked: bool = false
var dodged: bool = false
var threatened: bool = false
var anim_time: float = 0.0
var _toss := RandomNumberGenerator.new()

# Visual colors
const SHADOW := Color(0.04, 0.05, 0.08, 0.22)

# Unicycle chrome & rubber
const TIRE_BLACK := Color(0.14, 0.14, 0.16)
const SPOKE_CHROME := Color(0.82, 0.85, 0.88)
const PEDAL_GOLD := Color(0.85, 0.72, 0.24)
const SEAT_BLACK := Color(0.18, 0.18, 0.20)

# Performer attire
const SHIRT_RED := Color(0.88, 0.25, 0.22)
const SHIRT_WHITE := Color(0.96, 0.96, 0.96)
const PANTS_BLUE := Color(0.18, 0.28, 0.45)
const SUSPENDERS_LEATHER := Color(0.38, 0.24, 0.16)
const CAP_RED := Color(0.85, 0.20, 0.18)
const POMPOM_YELLOW := Color(0.95, 0.82, 0.24)
const SKIN_TONE := Color(0.88, 0.72, 0.60)
const HAIR_DARK := Color(0.25, 0.18, 0.14)

# Juggling pins
const PIN_WHITE := Color(0.96, 0.96, 0.96)
const PIN_CYAN := Color(0.20, 0.70, 0.88)
const PIN_MAGENTA := Color(0.90, 0.22, 0.60)
const PIN_YELLOW := Color(0.95, 0.82, 0.20)


func _init() -> void:
	_toss.seed = 0x71C1C1E


func reset() -> void:
	state = State.IDLE
	timer = 0.0
	pos = START_POS
	triggered = false
	human_hit = false
	booped = false
	pin_dropped = false
	pin_snatched = false
	pin_pos = Vector2.ZERO
	pin_vel = Vector2.ZERO
	barked = false
	dodged = false
	threatened = false
	anim_time = 0.0


func tick(delta: float, dog_pos: Vector2, _dog_vel: Vector2, human_pos: Vector2) -> Dictionary:
	var out: Dictionary = {
		"warn": false,
		"wobble": false,
		"bump": false,
		"boop": false,
		"drop_pin": false,
		"snatch": false,
		"dodge": false,
	}

	anim_time += delta

	# Dropped pin physics
	if pin_dropped and not pin_snatched:
		if pin_vel.length() > 2.0:
			pin_pos += pin_vel * delta
			pin_vel = pin_vel.move_toward(Vector2.ZERO, 85.0 * delta)
		if dog_pos.distance_to(pin_pos) < SNATCH_RADIUS:
			pin_snatched = true
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
				state = State.RIDING
				out["wobble"] = true

		State.RIDING:
			pos.x += RIDE_SPEED * delta

			# Drop juggling pin as unicyclist crosses middle road
			if not pin_dropped and pos.x >= PIN_DROP_X:
				pin_dropped = true
				pin_pos = pos + Vector2(2.0, 4.0)
				pin_vel = Vector2(45.0, _toss.randf_range(-16.0, 16.0))
				out["drop_pin"] = true

			# Soft bump on distracted human
			if not human_hit and human_pos.distance_to(pos) < BUMP_RADIUS:
				human_hit = true
				out["bump"] = true

			# Dog boop on unicyclist
			if not booped and dog_pos.distance_to(pos) < BOOP_RADIUS:
				booped = true
				out["boop"] = true

			# Reached eastern road verge
			if pos.x >= END_POS.x:
				pos = END_POS
				state = State.SETTLED

		State.SETTLED:
			pass

	if state == State.RIDING or state == State.SETTLED:
		var close := state == State.RIDING and pos.distance_to(human_pos) <= THREAT
		var step := NearMiss.consider(close, human_hit, threatened, dodged)
		threatened = bool(step["threatened"])
		if bool(step["dodge"]):
			dodged = true
			out["dodge"] = true

	return out


func on_bark(bark_pos: Vector2) -> bool:
	if state == State.RIDING and not barked and pos.distance_to(bark_pos) < BARK_RADIUS:
		barked = true
		return true
	return false


# Vector art batched into El Tibidabo's existing ShapeBatch
func draw(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	if m.lvl != "tibidabo":
		return

	# Only draw if within vertical view span
	if CROSSING_Y < vt - 120.0 or CROSSING_Y > vb + 120.0:
		return

	# 1. Dropped juggling pin on road asphalt
	if pin_dropped and not pin_snatched:
		b.circle(pin_pos + Shade.light * 2.0, 3.5, SHADOW)
		# Pin body & neck
		b.circle(pin_pos, 3.8, PIN_CYAN)
		b.line(pin_pos, pin_pos + Vector2(7.0, -2.0), PIN_WHITE, 2.2)
		b.circle(pin_pos + Vector2(8.0, -2.5), 1.8, PIN_YELLOW)

	# 2. Performer on Unicycle
	if state == State.RIDING or state == State.SETTLED or state == State.TELEGRAPH:
		var up := pos
		var wobble: float = sin(anim_time * 18.0) * 2.5 if state == State.RIDING else 0.0
		var pedal_angle: float = anim_time * 12.0 if state == State.RIDING else 0.0

		# Wheel shadow on asphalt
		b.circle(up + Shade.light * 4.0, 11.0, SHADOW)

		# Chrome unicycle wheel
		b.circle(up, 10.0, TIRE_BLACK)
		b.circle(up, 7.5, SPOKE_CHROME)
		b.circle(up, 3.5, TIRE_BLACK)
		b.circle(up, 2.0, PEDAL_GOLD)

		# Spokes
		for s in range(4):
			var sa := pedal_angle + float(s) * (PI * 0.5)
			b.line(up, up + Vector2.from_angle(sa) * 7.5, SPOKE_CHROME, 1.0)

		# Pedals & crank arms
		var crank_vec := Vector2.from_angle(pedal_angle) * 7.0
		b.line(up - crank_vec, up + crank_vec, SPOKE_CHROME, 2.0)
		b.rect(Rect2(up + crank_vec - Vector2(3.0, 1.5), Vector2(6.0, 3.0)), PEDAL_GOLD)
		b.rect(Rect2(up - crank_vec - Vector2(3.0, 1.5), Vector2(6.0, 3.0)), PEDAL_GOLD)

		# Frame post up to seat
		var seat_pos := up + Vector2(wobble * 0.6, -14.0)
		b.line(up, seat_pos, SPOKE_CHROME, 2.5)
		b.rect(Rect2(seat_pos.x - 5.0, seat_pos.y - 2.0, 10.0, 4.0), SEAT_BLACK)

		# Performer lower body (trousers & legs)
		var hip_pos := seat_pos + Vector2(0.0, -4.0)
		b.circle(hip_pos, 5.0, PANTS_BLUE)

		# Upper body (striped fairground shirt)
		var chest_pos := hip_pos + Vector2(wobble, -12.0)
		b.rect(Rect2(chest_pos.x - 6.0, chest_pos.y - 6.0, 12.0, 12.0), SHIRT_RED)
		# White stripes
		b.line(Vector2(chest_pos.x - 5.0, chest_pos.y - 2.0), Vector2(chest_pos.x + 5.0, chest_pos.y - 2.0), SHIRT_WHITE, 2.0)
		b.line(Vector2(chest_pos.x - 5.0, chest_pos.y + 3.0), Vector2(chest_pos.x + 5.0, chest_pos.y + 3.0), SHIRT_WHITE, 2.0)
		# Suspenders
		b.line(Vector2(chest_pos.x - 3.5, chest_pos.y - 6.0), Vector2(chest_pos.x - 3.5, chest_pos.y + 6.0), SUSPENDERS_LEATHER, 1.5)
		b.line(Vector2(chest_pos.x + 3.5, chest_pos.y - 6.0), Vector2(chest_pos.x + 3.5, chest_pos.y + 6.0), SUSPENDERS_LEATHER, 1.5)

		# Head & Cap
		var head_pos := chest_pos + Vector2(wobble * 0.5, -9.0)
		b.circle(head_pos, 5.5, SKIN_TONE)
		b.circle(head_pos + Vector2(0.0, -4.0), 5.0, CAP_RED)
		b.circle(head_pos + Vector2(3.0, -6.0), 2.2, POMPOM_YELLOW)

		# Outstretched balancing arms
		var arm_l := chest_pos + Vector2(-12.0, -2.0 + sin(anim_time * 8.0) * 3.0)
		var arm_r := chest_pos + Vector2(12.0, -2.0 - sin(anim_time * 8.0) * 3.0)
		b.line(chest_pos + Vector2(-5.0, -4.0), arm_l, SKIN_TONE, 2.0)
		b.line(chest_pos + Vector2(5.0, -4.0), arm_r, SKIN_TONE, 2.0)

		# Juggling pins cycling in air above head
		if state == State.RIDING or state == State.TELEGRAPH:
			var pin_colors: Array[Color] = [PIN_CYAN, PIN_MAGENTA, PIN_YELLOW]
			for p_idx in range(3):
				var phase := fmod(anim_time * 2.2 + float(p_idx) * 0.333, 1.0)
				# Parabolic juggle arc between hands
				var arc_x := lerpf(arm_l.x, arm_r.x, phase)
				var arc_y := head_pos.y - 12.0 - sin(phase * PI) * 16.0
				var p_col: Color = pin_colors[p_idx]
				b.circle(Vector2(arc_x, arc_y), 3.0, p_col)
				b.line(Vector2(arc_x, arc_y), Vector2(arc_x - 3.0, arc_y + 4.0), PIN_WHITE, 1.5)
