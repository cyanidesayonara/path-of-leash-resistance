class_name SuperillaCargo
extends RefCounted

const NearMiss := preload("res://systems/near_miss.gd")
const EventFeed := preload("res://hud/event_feed.gd")
const ShapeBatch := preload("res://systems/shape_batch.gd")

# EL PATÍ DE CÀRREGA DEL POBLENOU (Superilla live event)
#
# A front-loading family cargo trike ("el patí de càrrega") with a timber cargo box
# rolls westbound across the superblock's painted asphalt court along the green cycle lane
# at y = -2200.0.
#
# Design contract:
# - 0.8 s warning telegraph: approaches on outward walk (y < -1860.0), rings a cheerful
#   brass bell with float text "Ding-ding! Passeu, si us plau!" and a bicycle bell chime.
# - Distracted human bump hazard: -8 patience drop, "Whoa! Watch the cargo bike!",
#   cyclist: "Al tanto amb la bici!".
# - Near-miss dodge save: NearMiss.consider awards "superilla dodge! +2" and increments
#   saves_done only when entering threat radius and steering human safely clear.
# - Dropped baguette snatch trick: a fresh crusty baguette slips from the front cargo crate
#   at center path (x <= 640.0). Dog can snatch it for "baguette snatch! +2".
# - Direct boop trick: booping the trike awards "cargo boop! +2".
# - Bark trick: barking within 140 px prompts an enthusiastic double-chime bell ring for "cargo cheer! +2".
# - Autowalk clearance: crosses comfortably before autowalk pair arrives.
# - Zero new draw calls: batched directly into Superilla's live ShapeBatch.

enum State {
	IDLE,
	TELEGRAPH,
	RIDING,
	SETTLED,
}

const START_POS := Vector2(880.0, -2200.0)
const END_POS := Vector2(400.0, -2200.0)
const CROSSING_Y := -2200.0
const TRIGGER_Y := -1860.0
const DROP_X := 640.0
const RIDE_SPEED := 220.0
const WARN_DURATION := 0.8

const BUMP_RADIUS := 28.0
const THREAT_RADIUS := 68.0
const BOOP_RADIUS := 30.0
const BARK_RADIUS := 140.0
const SNATCH_RADIUS := 26.0

var state: State = State.IDLE
var timer: float = 0.0
var pos: Vector2 = START_POS
var triggered: bool = false
var human_hit: bool = false
var booped: bool = false
var baguette_dropped: bool = false
var baguette_snatched: bool = false
var baguette_pos: Vector2 = Vector2.ZERO
var baguette_vel: Vector2 = Vector2.ZERO
var barked: bool = false
var dodged: bool = false
var threatened: bool = false
var pedal_t: float = 0.0
var anim_time: float = 0.0

var _toss: RandomNumberGenerator = RandomNumberGenerator.new()

# Visual colors
const SHADOW := Color(0.04, 0.05, 0.06, 0.22)
const FRAME_SAGE := Color(0.38, 0.52, 0.44)
const BOX_WOOD := Color(0.62, 0.46, 0.32)
const WHEEL_RUBBER := Color(0.20, 0.20, 0.22)
const WHEEL_SPOKE := Color(0.82, 0.84, 0.86)
const BAGUETTE_CRUST := Color(0.86, 0.64, 0.36)
const BAGUETTE_SCORE := Color(0.96, 0.82, 0.54)
const RIDER_SHIRT := Color(0.24, 0.46, 0.62)
const RIDER_CAP := Color(0.82, 0.30, 0.24)
const RIDER_SKIN := Color(0.88, 0.72, 0.58)


func _init() -> void:
	_toss.seed = 0x50B1E0


func reset() -> void:
	state = State.IDLE
	timer = 0.0
	pos = START_POS
	triggered = false
	human_hit = false
	booped = false
	baguette_dropped = false
	baguette_snatched = false
	baguette_pos = Vector2.ZERO
	baguette_vel = Vector2.ZERO
	barked = false
	dodged = false
	threatened = false
	pedal_t = 0.0
	anim_time = 0.0


func tick(m: Node2D, delta: float) -> void:
	anim_time += delta

	var dog_p: Vector2 = m.dog.global_position
	var human_p: Vector2 = m.human.global_position

	# Dropped baguette physics
	if baguette_dropped and not baguette_snatched:
		baguette_pos += baguette_vel * delta
		baguette_vel = baguette_vel.move_toward(Vector2.ZERO, delta * 240.0)
		if dog_p.distance_to(baguette_pos) < SNATCH_RADIUS:
			baguette_snatched = true
			m.combo.add("BAGUETTE SNATCH", 2)
			m.float_text(baguette_pos, "baguette snatch! +2", Color(0.96, 0.82, 0.54))
			var sfx = m.get_node_or_null("/root/Sfx")
			if sfx != null:
				sfx.play("snack", 1.2, -2.0)

	match state:
		State.IDLE:
			if not triggered and human_p.y < TRIGGER_Y and human_p.y > CROSSING_Y - 400.0:
				triggered = true
				state = State.TELEGRAPH
				timer = WARN_DURATION
				m.feed.say("El del patí de càrrega: \"Ding-ding! Passeu, si us plau!\"", EventFeed.Tone.LOUD)
				var sfx = m.get_node_or_null("/root/Sfx")
				if sfx != null:
					sfx.play("bell", 1.2, -3.0)

		State.TELEGRAPH:
			timer -= delta
			if timer <= 0.0:
				state = State.RIDING

		State.RIDING:
			pedal_t += delta * 7.5
			pos.x -= RIDE_SPEED * delta

			# Drop baguette at center
			if not baguette_dropped and pos.x <= DROP_X:
				baguette_dropped = true
				baguette_pos = pos + Vector2(10.0, 4.0)
				baguette_vel = Vector2(-35.0, 25.0)
				var sfx = m.get_node_or_null("/root/Sfx")
				if sfx != null:
					sfx.play("grit", 1.1, -4.0)

			# Human bump
			if not human_hit:
				var dist_human := human_p.distance_to(pos)
				if dist_human < BUMP_RADIUS:
					human_hit = true
					m.human.bump(Vector2.DOWN, 8.0)
					m.float_text(human_p + Vector2(0, -34), "Watch the cargo bike!", Color(1.0, 0.45, 0.4), m.POP_SAY)
					m.float_text(pos + Vector2(0, -28), "Al tanto amb la bici!", Color(0.96, 0.88, 0.35))
					var sfx = m.get_node_or_null("/root/Sfx")
					if sfx != null:
						sfx.play("grunt", 0.95, -2.0)

			# Dog boop
			if not booped and dog_p.distance_to(pos) < BOOP_RADIUS:
				booped = true
				m.combo.add("CARGO BOOP", 2)
				m.float_text(pos + Vector2(0, -32), "cargo boop! +2", Color(1.0, 0.85, 0.3))
				var sfx = m.get_node_or_null("/root/Sfx")
				if sfx != null:
					sfx.play("whoop", 1.25, -3.0)

			# Finish crossing
			if pos.x <= END_POS.x:
				pos = END_POS
				state = State.SETTLED

		State.SETTLED:
			pass

	# Near-miss dodge save
	if state == State.RIDING or state == State.SETTLED:
		var close: bool = state == State.RIDING and pos.distance_to(human_p) <= THREAT_RADIUS
		var step: Dictionary = NearMiss.consider(close, human_hit, threatened, dodged)
		threatened = bool(step["threatened"])
		if bool(step["dodge"]):
			dodged = true
			m.saves_done += 1
			m.combo.add("SUPERILLA DODGE", 2)
			m.float_text(pos + Vector2(0, -32), "superilla dodge! +2", Color(0.96, 0.88, 0.35))
			var sfx = m.get_node_or_null("/root/Sfx")
			if sfx != null:
				sfx.play("bell", 1.35, -2.0)


func on_bark(m: Node2D) -> bool:
	if barked or state == State.IDLE:
		return false
	var dog_p: Vector2 = m.dog.global_position
	if dog_p.distance_to(pos) < BARK_RADIUS:
		barked = true
		m.combo.add("CARGO CHEER", 2)
		m.float_text(pos + Vector2(0, -32), "cargo cheer! +2", Color(0.4, 0.9, 0.6))
		var sfx = m.get_node_or_null("/root/Sfx")
		if sfx != null:
			sfx.play("bell", 1.45, -2.0)
		return true
	return false


func draw(b: ShapeBatch, vt: float, vb: float) -> void:
	if pos.y + 60.0 < vt or pos.y - 60.0 > vb:
		return

	# Dropped baguette on the street
	if baguette_dropped and not baguette_snatched:
		b.rect(Rect2(baguette_pos.x - 7.0, baguette_pos.y + 2.0, 14.0, 4.0), SHADOW)
		b.line(baguette_pos + Vector2(-6.0, 0.0), baguette_pos + Vector2(6.0, 0.0), BAGUETTE_CRUST, 4.0)
		b.circle(baguette_pos + Vector2(-6.0, 0.0), 2.0, BAGUETTE_CRUST)
		b.circle(baguette_pos + Vector2(6.0, 0.0), 2.0, BAGUETTE_CRUST)
		b.line(baguette_pos + Vector2(-3.0, -1.0), baguette_pos + Vector2(-1.0, 1.0), BAGUETTE_SCORE, 1.2)
		b.line(baguette_pos + Vector2(1.0, -1.0), baguette_pos + Vector2(3.0, 1.0), BAGUETTE_SCORE, 1.2)

	if state == State.IDLE:
		return

	# Trike shadow
	b.rect(Rect2(pos.x - 22.0, pos.y + 6.0, 44.0, 12.0), SHADOW)

	# Front cargo box (wooden container)
	var box_r := Rect2(pos.x - 20.0, pos.y - 10.0, 24.0, 18.0)
	b.rect(box_r, BOX_WOOD)
	b.rect(Rect2(box_r.position.x + 2.0, box_r.position.y + 2.0, box_r.size.x - 4.0, box_r.size.y - 4.0), BOX_WOOD.darkened(0.15))

	# Front wheels (left and right of box)
	b.circle(pos + Vector2(-12.0, -10.0), 5.0, WHEEL_RUBBER)
	b.circle(pos + Vector2(-12.0, 8.0), 5.0, WHEEL_RUBBER)

	# Frame & rear wheel
	b.line(pos + Vector2(4.0, -1.0), pos + Vector2(18.0, -1.0), FRAME_SAGE, 3.0)
	b.circle(pos + Vector2(18.0, -1.0), 6.0, WHEEL_RUBBER)

	# Rider (top-down head & cap)
	var rider_p := pos + Vector2(10.0, -1.0)
	b.circle(rider_p, 8.0, RIDER_SHIRT)
	b.circle(rider_p + Vector2(-2.0, 0.0), 6.0, RIDER_SKIN)
	b.circle(rider_p + Vector2(-3.0, 0.0), 5.0, RIDER_CAP)
	# Cap visor facing left
	b.line(rider_p + Vector2(-6.0, -3.0), rider_p + Vector2(-6.0, 3.0), RIDER_CAP.darkened(0.2), 2.0)
