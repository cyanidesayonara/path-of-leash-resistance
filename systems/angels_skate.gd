class_name AngelsSkate
extends RefCounted

const NearMiss := preload("res://systems/near_miss.gd")
const EventFeed := preload("res://hud/event_feed.gd")
const ShapeBatch := preload("res://systems/shape_batch.gd")

# EL PATINADOR DELS ÀNGELS (Els Àngels live event)
#
# A street skater bails off the granite museum ledge at y = -2400.0 and their
# skateboard shoots eastbound across the stone plaza slabs.
#
# Design contract:
# - 0.8 s warning telegraph: triggers on outward walk (y < -2020.0), shouts
#   "Board!" in a speech bubble and "RUNAWAY BOARD!" on the feed.
# - Distracted human bump hazard: patience drop, human speech bubble in their
#   voice ("Ow! My ankles!"), and skater apology ("Sorry! Lost my board!").
# - Near-miss dodge save: NearMiss.consider awards "board dodge! +2" and
#   increments saves_done when entering threat radius and steering clear.
# - Dropped churro: a paper-wrapped churro tumbles onto the plaza at x = 520.0;
#   stealing it awards "churro snatch! +2" and marks angels_churro_stolen.
# - Boop & bark rewards: booping the runaway board awards "board boop! +2",
#   barking within 140 px awards "skate cheer! +2".
# - Autowalk clearance: triggers with full 0.8 s warning well ahead of the
#   autowalk pair and never fires on top of them unannounced.

enum State {
	IDLE,
	TELEGRAPH,
	ROLLING,
	SETTLED,
}

const SKATER_POS := Vector2(356.0, -2400.0)
const START_POS := Vector2(384.0, -2400.0)
const END_POS := Vector2(956.0, -2400.0)
const CROSSING_Y := -2400.0
const TRIGGER_Y := -2020.0
const DROP_X := 520.0
const ROLL_SPEED := 310.0
const WARN_DURATION := 0.8

const BUMP_RADIUS := 28.0
const THREAT_RADIUS := 68.0
const BOOP_RADIUS := 30.0
const BARK_RADIUS := 140.0
const SNATCH_RADIUS := 28.0

var state: State = State.IDLE
var timer: float = 0.0
var pos: Vector2 = START_POS
var skater_pos: Vector2 = SKATER_POS
var triggered: bool = false
var human_hit: bool = false
var booped: bool = false
var churro_dropped: bool = false
var churro_snatched: bool = false
var churro_pos: Vector2 = Vector2.ZERO
var churro_vel: Vector2 = Vector2.ZERO
var barked: bool = false
var dodged: bool = false
var threatened: bool = false
var wheel_t: float = 0.0
var anim_time: float = 0.0

const SHADOW := Color(0.04, 0.05, 0.07, 0.24)
const DECK_MAPLE := Color(0.84, 0.66, 0.42)
const DECK_GRIP := Color(0.16, 0.17, 0.19)
const DECK_STRIPE := Color(0.88, 0.28, 0.22)
const TRUCK_SILVER := Color(0.76, 0.78, 0.82)
const WHEEL_URETHANE := Color(0.95, 0.92, 0.84)
const SKATER_TEE := Color(0.92, 0.90, 0.86)
const SKATER_JEANS := Color(0.24, 0.34, 0.48)
const SKATER_BEANIE := Color(0.82, 0.26, 0.20)
const SKATER_SKIN := Color(0.88, 0.72, 0.58)
const CHURRO_GOLD := Color(0.84, 0.58, 0.24)
const CHURRO_SUGAR := Color(0.96, 0.92, 0.82)


func reset() -> void:
	state = State.IDLE
	timer = 0.0
	pos = START_POS
	skater_pos = SKATER_POS
	triggered = false
	human_hit = false
	booped = false
	churro_dropped = false
	churro_snatched = false
	churro_pos = Vector2.ZERO
	churro_vel = Vector2.ZERO
	barked = false
	dodged = false
	threatened = false
	wheel_t = 0.0
	anim_time = 0.0


func tick(m: Node2D, delta: float) -> void:
	anim_time += delta

	var dog_p: Vector2 = m.dog.global_position
	var human_p: Vector2 = m.human.global_position

	# Dropped churro physics & snatch
	if churro_dropped and not churro_snatched:
		churro_pos += churro_vel * delta
		churro_vel = churro_vel.move_toward(Vector2.ZERO, delta * 240.0)
		if dog_p.distance_to(churro_pos) < SNATCH_RADIUS:
			churro_snatched = true
			m.angels_churro_stolen = true
			m.churros_eaten += 1
			m.combo.add("CHURRO SNATCH", 2)
			m.float_text(churro_pos, "churro snatch! +2", Color(0.96, 0.82, 0.44))
			var sfx = m.get_node_or_null("/root/Sfx")
			if sfx != null:
				sfx.play("snack", 1.2, -2.0)

	match state:
		State.IDLE:
			if not triggered and m.phase == "out" and human_p.y < TRIGGER_Y and human_p.y > CROSSING_Y - 360.0:
				triggered = true
				state = State.TELEGRAPH
				timer = WARN_DURATION
				m.feed.say("RUNAWAY BOARD!", EventFeed.Tone.LOUD)
				m.float_text(SKATER_POS + Vector2(0.0, -30.0), "Board!", Color(1.0, 0.88, 0.36), m.POP_SAY)
				var sfx = m.get_node_or_null("/root/Sfx")
				if sfx != null:
					sfx.play("grit", 1.15, -2.0)

		State.TELEGRAPH:
			timer -= delta
			if timer <= 0.0:
				state = State.ROLLING

		State.ROLLING:
			wheel_t += delta * 14.0
			pos.x += ROLL_SPEED * delta
			skater_pos = SKATER_POS + Vector2(minf((pos.x - START_POS.x) * 0.16, 42.0), 6.0)

			# Drop churro near the west side of the plaza
			if not churro_dropped and pos.x >= DROP_X:
				churro_dropped = true
				churro_pos = pos + Vector2(-8.0, 8.0)
				churro_vel = Vector2(28.0, 22.0)
				var sfx = m.get_node_or_null("/root/Sfx")
				if sfx != null:
					sfx.play("grit", 1.05, -4.0)

			# Human bump
			if not human_hit:
				var dist_human := human_p.distance_to(pos)
				if dist_human < BUMP_RADIUS:
					human_hit = true
					if m.human.has_method("bumped"):
						m.human.bumped(Vector2.DOWN)
					if "patience" in m.human:
						m.human.patience = maxf(0.0, float(m.human.patience) - 0.10)
					m.float_text(human_p + Vector2(0.0, -34.0), "Ow! My ankles!", Color(1.0, 0.45, 0.40), m.POP_SAY)
					m.float_text(skater_pos + Vector2(0.0, -28.0), "Sorry! Lost my board!", Color(0.96, 0.88, 0.35), m.POP_SAY)
					var sfx = m.get_node_or_null("/root/Sfx")
					if sfx != null:
						sfx.play("grunt", 0.95, -2.0)

			# Dog boop
			if not booped and dog_p.distance_to(pos) < BOOP_RADIUS:
				booped = true
				m.combo.add("BOARD BOOP", 2)
				m.float_text(pos + Vector2(0.0, -30.0), "board boop! +2", Color(1.0, 0.85, 0.30))
				var sfx = m.get_node_or_null("/root/Sfx")
				if sfx != null:
					sfx.play("whoop", 1.25, -3.0)

			# Finish crossing at east plaza edge
			if pos.x >= END_POS.x:
				pos = END_POS
				state = State.SETTLED

		State.SETTLED:
			pass

	# Near-miss dodge save
	if state == State.ROLLING or state == State.SETTLED:
		var close: bool = state == State.ROLLING and pos.distance_to(human_p) <= THREAT_RADIUS
		var step: Dictionary = NearMiss.consider(close, human_hit, threatened, dodged)
		threatened = bool(step["threatened"])
		if bool(step["dodge"]):
			dodged = true
			m.saves_done += 1
			m.combo.add("BOARD DODGE", 2)
			m.float_text(pos + Vector2(0.0, -30.0), "board dodge! +2", Color(0.96, 0.88, 0.35))
			var sfx = m.get_node_or_null("/root/Sfx")
			if sfx != null:
				sfx.play("bell", 1.35, -2.0)


func on_bark(m: Node2D) -> bool:
	if barked or state == State.IDLE:
		return false
	var dog_p: Vector2 = m.dog.global_position
	if dog_p.distance_to(pos) < BARK_RADIUS or dog_p.distance_to(skater_pos) < BARK_RADIUS:
		barked = true
		m.combo.add("SKATE CHEER", 2)
		m.float_text(skater_pos + Vector2(0.0, -30.0), "skate cheer! +2", Color(0.42, 0.92, 0.62))
		var sfx = m.get_node_or_null("/root/Sfx")
		if sfx != null:
			sfx.play("whoop", 1.20, -2.0)
		return true
	return false


func draw(b: ShapeBatch, vt: float, vb: float) -> void:
	if pos.y + 70.0 < vt or pos.y - 70.0 > vb:
		return

	# Dropped paper-wrapped churro on the plaza stone
	if churro_dropped and not churro_snatched:
		b.circle(churro_pos + Vector2(1.5, 2.0), 8.0, SHADOW)
		b.polygon(PackedVector2Array([
			churro_pos + Vector2(-9.0, 1.0), churro_pos + Vector2(-3.0, -6.0),
			churro_pos + Vector2(5.0, -4.0), churro_pos + Vector2(2.0, 5.0),
		]), CHURRO_SUGAR)
		b.line(churro_pos + Vector2(-2.0, -2.0), churro_pos + Vector2(9.0, 3.0), CHURRO_GOLD, 4.2)
		b.line(churro_pos + Vector2(-1.0, -2.2), churro_pos + Vector2(7.0, 1.8), CHURRO_SUGAR, 1.4)

	if state == State.IDLE:
		return

	# Bailed skater sitting/sliding on the west plaza slabs
	b.circle(skater_pos + Vector2(3.0, 5.0), 12.0, SHADOW)
	b.line(skater_pos + Vector2(-4.0, 4.0), skater_pos + Vector2(12.0, 7.0), SKATER_JEANS, 5.0)
	b.line(skater_pos + Vector2(-4.0, -2.0), skater_pos + Vector2(10.0, -5.0), SKATER_JEANS, 5.0)
	b.circle(skater_pos, 8.5, SKATER_TEE)
	b.line(skater_pos + Vector2(2.0, -5.0), skater_pos + Vector2(13.0, -2.0), SKATER_SKIN, 3.2)
	b.circle(skater_pos + Vector2(-2.0, -1.0), 6.2, SKATER_SKIN)
	b.circle(skater_pos + Vector2(-3.5, -1.5), 5.4, SKATER_BEANIE)

	# Runaway skateboard shooting east across the plaza
	b.rect(Rect2(pos.x - 16.0, pos.y + 4.0, 32.0, 9.0), SHADOW)
	# Four urethane wheels poking out from under the trucks
	for wx: float in [-10.0, 10.0]:
		for wy: float in [-5.5, 5.5]:
			b.circle(pos + Vector2(wx, wy), 2.4, WHEEL_URETHANE)
	# Silver trucks
	b.line(pos + Vector2(-10.0, -5.0), pos + Vector2(-10.0, 5.0), TRUCK_SILVER, 2.2)
	b.line(pos + Vector2(10.0, -5.0), pos + Vector2(10.0, 5.0), TRUCK_SILVER, 2.2)
	# Maple rim & dark grip tape deck with nose/tail kicks
	b.rect(Rect2(pos.x - 13.0, pos.y - 4.5, 26.0, 9.0), DECK_MAPLE)
	b.circle(pos + Vector2(-13.0, 0.0), 4.5, DECK_MAPLE)
	b.circle(pos + Vector2(13.0, 0.0), 4.5, DECK_MAPLE)
	b.rect(Rect2(pos.x - 11.5, pos.y - 3.6, 23.0, 7.2), DECK_GRIP)
	b.circle(pos + Vector2(-11.5, 0.0), 3.6, DECK_GRIP)
	b.circle(pos + Vector2(11.5, 0.0), 3.6, DECK_GRIP)
	# Grip-tape cutout stripe
	b.line(pos + Vector2(4.0, -3.5), pos + Vector2(4.0, 3.5), DECK_STRIPE, 2.0)
