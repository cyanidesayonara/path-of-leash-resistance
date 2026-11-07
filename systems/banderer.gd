class_name Banderer
extends RefCounted

# EL BANDERER DEL PARTIT (Dia de Partit live event)
#
# An enthusiastic match-day fan and flag bearer ("el banderer") in a striped
# Blaugrana jersey (#10), blue match shorts, and Catalan barretina hurries across the
# stadium avenue from the scarf stall (east kerb, x = 950.0) toward the stadium gates and
# west barricades (x = 350.0) at y = -1380.0, waving a large striped Blaugrana club flag
# on a wooden staff and carrying a bundle of supporter scarves.
#
# Design contract:
# - 0.8 s warning telegraph: approaches on outward walk (y < -1080.0), calls out
#   "Big flag coming through! Kickoff soon!" with stadium horn toot.
# - Distracted human bump hazard: -8 patience drop, "Whoa! Watch the flag!",
#   banderer: "Al tanto amb la bandera!".
# - Near-miss dodge save: NearMiss.consider awards "partit dodge! +2" and increments
#   saves_done only when entering threat radius and steering human safely clear.
#   Walking past without near miss awards nothing.
# - Dropped match scarf snatch trick: a lucky supporter scarf slips from his arm
#   at center avenue (x <= 640.0). Dog can snatch or boop it for "bufanda snatch! +2".
# - Direct boop trick: booping the flag bearer awards "banderer boop! +2".
# - Bark trick: barking within 130 px startles him into an excited flag flourish for "banderer bark! +2".
# - Autowalk clearance: passes well before autowalk pair arrives.
# - Zero new draw calls: batched into Partit's live ShapeBatch in draw_live.
# - Independent RNG sequence, zero mutation of rope physics.

enum State {
	IDLE,
	TELEGRAPH,
	WALKING,
	SETTLED,
}

const START_POS := Vector2(950.0, -1380.0)
const END_POS := Vector2(350.0, -1380.0)
const CROSSING_Y := -1380.0
const TRIGGER_Y := -1020.0
const DROP_X := 640.0
const WALK_SPEED := 230.0
const WARN_DURATION := 0.8

const BUMP_RADIUS := 25.0
const THREAT_RADIUS := 66.0
const BOOP_RADIUS := 28.0
const BARK_RADIUS := 130.0
const SNATCH_RADIUS := 26.0

var state: State = State.IDLE
var timer: float = 0.0
var pos: Vector2 = START_POS
var triggered: bool = false
var human_hit: bool = false
var booped: bool = false
var scarf_dropped: bool = false
var scarf_snatched: bool = false
var scarf_pos: Vector2 = Vector2.ZERO
var scarf_vel: Vector2 = Vector2.ZERO
var barked: bool = false
var dodged: bool = false
var threatened: bool = false
var wobble_t: float = 0.0
var anim_time: float = 0.0

var _toss: RandomNumberGenerator = RandomNumberGenerator.new()

# Attire & match day colors
const SHADOW := Color(0.04, 0.05, 0.06, 0.22)
const HOME_BLUE := Color(0.10, 0.29, 0.66)
const HOME_CLARET := Color(0.64, 0.07, 0.27)
const SENYERA_GOLD := Color(0.98, 0.80, 0.16)
const SENYERA_RED := Color(0.82, 0.12, 0.14)
const SHIRT_WHITE := Color(0.95, 0.95, 0.96)
const SKIN_TONE := Color(0.88, 0.72, 0.58)
const HAIR_DARK := Color(0.18, 0.14, 0.12)
const STAFF_WOOD := Color(0.72, 0.54, 0.36)
const SCARF_BLUE := Color(0.12, 0.32, 0.70)
const SCARF_CLARET := Color(0.68, 0.08, 0.28)
const SCARF_FRINGE := Color(0.96, 0.88, 0.22)


func _init() -> void:
	_toss.seed = 0xBA4CA


func reset() -> void:
	state = State.IDLE
	timer = 0.0
	pos = START_POS
	triggered = false
	human_hit = false
	booped = false
	scarf_dropped = false
	scarf_snatched = false
	scarf_pos = Vector2.ZERO
	scarf_vel = Vector2.ZERO
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

	# Update dropped match scarf physics
	if scarf_dropped and not scarf_snatched:
		scarf_pos += scarf_vel * delta
		scarf_vel = scarf_vel.move_toward(Vector2.ZERO, 50.0 * delta)
		if dog_pos.distance_to(scarf_pos) <= SNATCH_RADIUS:
			scarf_snatched = true
			out["snatch"] = true

	# Boop interaction
	if (state == State.TELEGRAPH or state == State.WALKING) and not booped:
		if dog_pos.distance_to(pos) <= BOOP_RADIUS:
			booped = true
			out["boop"] = true

	match state:
		State.IDLE:
			if not triggered and human_pos.y <= TRIGGER_Y and human_pos.y > CROSSING_Y - 200.0:
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
			pos.x -= WALK_SPEED * delta
			pos.y = CROSSING_Y + sin(anim_time * 9.0) * 2.0

			# Drops match scarf near center avenue
			if not scarf_dropped and pos.x <= DROP_X:
				scarf_dropped = true
				scarf_pos = pos + Vector2(0.0, 6.0)
				scarf_vel = Vector2(-25.0, _toss.randf_range(-14.0, 14.0))

			# Soft bump hazard on human
			if not human_hit and pos.distance_to(human_pos) <= BUMP_RADIUS:
				human_hit = true
				out["bump"] = true

			if pos.x <= END_POS.x:
				pos = END_POS
				state = State.SETTLED

		State.SETTLED:
			anim_time += delta

	if state == State.WALKING or state == State.SETTLED:
		var close := state == State.WALKING and pos.distance_to(human_pos) <= THREAT_RADIUS
		var step := NearMiss.consider(close, human_hit, threatened, dodged)
		threatened = step["threatened"]
		if step["dodge"]:
			dodged = true
			out["dodge"] = true

	return out


func on_bark(bark_pos: Vector2) -> bool:
	if (state == State.TELEGRAPH or state == State.WALKING) and not barked:
		if bark_pos.distance_to(pos) <= BARK_RADIUS:
			barked = true
			wobble_t = 0.5
			return true
	return false


func draw(_m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	if pos.y < vt - 100.0 or pos.y > vb + 100.0:
		return

	# Draw dropped match scarf on the asphalt
	if scarf_dropped and not scarf_snatched:
		b.rect(Rect2(scarf_pos + Vector2(-9.0, -1.0), Vector2(20.0, 7.0)), SHADOW)
		# Striped Blaugrana scarf with gold fringe
		b.rect(Rect2(scarf_pos + Vector2(-10.0, -3.0), Vector2(5.0, 6.0)), SCARF_CLARET)
		b.rect(Rect2(scarf_pos + Vector2(-5.0, -3.0), Vector2(5.0, 6.0)), SCARF_BLUE)
		b.rect(Rect2(scarf_pos + Vector2(0.0, -3.0), Vector2(5.0, 6.0)), SCARF_CLARET)
		b.rect(Rect2(scarf_pos + Vector2(5.0, -3.0), Vector2(5.0, 6.0)), SCARF_BLUE)
		# Fringe ends
		b.rect(Rect2(scarf_pos + Vector2(-12.0, -2.0), Vector2(2.0, 4.0)), SCARF_FRINGE)
		b.rect(Rect2(scarf_pos + Vector2(10.0, -2.0), Vector2(2.0, 4.0)), SCARF_FRINGE)

	# Flag bearer character drawing
	var trot := sin(anim_time * 9.0) * 2.0 if state == State.WALKING else 0.0
	var flag_wave := sin(anim_time * 7.0 + (3.0 if wobble_t > 0.0 else 0.0)) * 6.0
	var draw_p := pos + Vector2(0.0, trot)

	# Shadow
	b.circle(draw_p + Vector2(2.0, 4.0), 16.0, SHADOW)

	# Match jersey: Blaugrana striped shirt (facing west)
	b.circle(draw_p, 13.0, HOME_BLUE)
	b.circle(draw_p + Vector2(-2.0, 0.0), 11.5, HOME_CLARET)
	b.circle(draw_p + Vector2(-4.0, 0.0), 9.0, HOME_BLUE)
	b.circle(draw_p + Vector2(-6.0, 0.0), 6.5, HOME_CLARET)

	# Number 10 on back / white trim
	b.circle(draw_p + Vector2(3.0, 0.0), 3.0, SHIRT_WHITE)

	# Head & dark hair
	var head_p := draw_p + Vector2(-1.5, -2.0)
	b.circle(head_p, 8.5, HAIR_DARK)
	b.circle(head_p + Vector2(-2.0, 0.0), 6.5, SKIN_TONE)

	# Catalan red barretina / match cap with black trim
	b.circle(head_p + Vector2(-1.0, -3.0), 7.0, SENYERA_RED)
	b.circle(head_p + Vector2(-3.0, -3.0), 4.5, SENYERA_RED)
	b.rect(Rect2(head_p + Vector2(-5.0, -1.0), Vector2(8.0, 2.0)), Color(0.12, 0.12, 0.12))

	# Wooden staff angled backwards/upwards
	var staff_base := draw_p + Vector2(-4.0, 4.0)
	var staff_tip := draw_p + Vector2(18.0, -26.0)
	b.line(staff_base, staff_tip, STAFF_WOOD, 2.6)

	# Large waving Blaugrana flag attached to upper staff
	var flag_origin := staff_tip + Vector2(-2.0, 2.0)
	var wave_offset := Vector2(flag_wave, -sin(anim_time * 7.0) * 3.0)

	# Upper claret stripe of flag
	b.line(flag_origin, flag_origin + Vector2(14.0, 8.0) + wave_offset, HOME_CLARET, 5.0)
	# Middle blue stripe with gold crest touch
	b.line(flag_origin + Vector2(0.0, 5.0), flag_origin + Vector2(14.0, 13.0) + wave_offset, HOME_BLUE, 5.0)
	b.circle(flag_origin + Vector2(7.0, 7.0) + wave_offset * 0.5, 2.0, SENYERA_GOLD)
	# Lower claret stripe of flag
	b.line(flag_origin + Vector2(0.0, 10.0), flag_origin + Vector2(14.0, 18.0) + wave_offset, HOME_CLARET, 5.0)
