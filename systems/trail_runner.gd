class_name TrailRunner
extends RefCounted

# WALK 22: LA CARRETERA DE LES AIGÜES - COLLSEROLA TRAIL RUNNER
# Signature live event for La Carretera de les Aigües (the hillside track):
# An enthusiastic Collserola mountain trail runner (el corredor de muntanya)
# wearing a neon technical shirt, hydration vest, and pumping trekking poles
# bursts down from the eastern hillside rock spur at y = -1700.0, sprinting
# westbound across the sauló trail towards the valley overlook fence.
#
# Gameplay contract:
# - 0.8 s warning telegraph: Trail runner steps onto the rock spur threshold at
#   x = 810.0, y = -1700.0, trekking poles clicking sharply against the gravel
#   ("tac, tac, tac") as they call out "Runner coming through!" with a telegraphed speech bubble.
# - Soft failure / hazard: distracted human wandering into the runner's path
#   gets bumped by the runner's hydration pack/poles (-8 patience drop, "Oof! Fast, aren't you?").
# - Dog trick: as the runner sprints past the center track (x <= 600.0), a foil
#   electrolyte energy gel pouch drops from their hydration pocket; pouncing or
#   booping it awards "gel snatch! +2".
# - Bark trick: barking near the passing runner startles them into an agile
#   high-knee stride recovery, awarding "runner bark! +2" ("Epa!", "Faster than me!").
# - Boop trick: booping the trail runner directly awards "runner boop! +2".
# - Dodge: steering your human safely clear past the crossing trajectory
#   awards "trail dodge! +2" / "Whew, close one!".
# - Autowalk: timing naturally clears the center line (x = 585.0) before the
#   autowalk pair arrives, ensuring 100% reliable automated traversal and test stability.
# - Zero new draw calls: batched into La Carretera de les Aigües's existing ShapeBatch.

const ShapeBatch := preload("res://systems/shape_batch.gd")

const START_POS := Vector2(810.0, -1700.0)
const END_POS := Vector2(365.0, -1700.0)
const CROSSING_Y := -1700.0
const TRIGGER_Y := -1520.0

const WARN_DURATION := 0.8
const RUN_SPEED := 175.0
const BUMP_RADIUS := 30.0
const THREAT := 64.0
const SNATCH_RADIUS := 28.0
const BOOP_RADIUS := 26.0
const BARK_RADIUS := 140.0
const GEL_DROP_X := 600.0

enum State { IDLE, TELEGRAPH, RUNNING, SETTLED }

var state: State = State.IDLE
var timer: float = 0.0
var pos: Vector2 = START_POS
var triggered: bool = false
var human_hit: bool = false
var booped: bool = false
var gel_dropped: bool = false
var gel_snatched: bool = false
var gel_pos: Vector2 = Vector2.ZERO
var gel_vel: Vector2 = Vector2.ZERO
var barked: bool = false
var dodged: bool = false
var threatened: bool = false
var _toss := RandomNumberGenerator.new()
var anim_time: float = 0.0

# Visual colors
const SHADOW := Color(0.04, 0.05, 0.08, 0.22)

# Runner attire
const SHIRT_NEON := Color(0.96, 0.55, 0.12)
const SHORTS_DARK := Color(0.15, 0.16, 0.18)
const VEST_BLACK := Color(0.12, 0.12, 0.14)
const FLASK_CAP := Color(0.85, 0.90, 0.95)
const CAP_WHITE := Color(0.92, 0.94, 0.96)
const SKIN_TONE := Color(0.88, 0.72, 0.60)
const POLE_CARBON := Color(0.35, 0.38, 0.40)
const POLE_TIP := Color(0.85, 0.88, 0.92)

# Electrolyte gel pouch
const GEL_SILVER := Color(0.78, 0.82, 0.88)
const GEL_BLUE := Color(0.20, 0.60, 0.85)
const GEL_ORANGE := Color(0.96, 0.50, 0.15)


func _init() -> void:
	_toss.seed = 0x71A11


func reset() -> void:
	state = State.IDLE
	timer = 0.0
	pos = START_POS
	triggered = false
	human_hit = false
	booped = false
	gel_dropped = false
	gel_snatched = false
	gel_pos = Vector2.ZERO
	gel_vel = Vector2.ZERO
	barked = false
	dodged = false
	threatened = false
	anim_time = 0.0


func tick(delta: float, dog_pos: Vector2, _dog_vel: Vector2, human_pos: Vector2) -> Dictionary:
	var out: Dictionary = {
		"warn": false,
		"clack": false,
		"bump": false,
		"boop": false,
		"drop_gel": false,
		"snatch": false,
		"dodge": false,
	}

	anim_time += delta

	# Dropped energy gel physics
	if gel_dropped and not gel_snatched:
		if gel_vel.length() > 2.0:
			gel_pos += gel_vel * delta
			gel_vel = gel_vel.move_toward(Vector2.ZERO, 90.0 * delta)
		if dog_pos.distance_to(gel_pos) < SNATCH_RADIUS:
			gel_snatched = true
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
				state = State.RUNNING
				out["clack"] = true

		State.RUNNING:
			# Running westbound (-x)
			pos.x -= RUN_SPEED * delta

			# Drop energy gel as runner crosses center trail
			if not gel_dropped and pos.x <= GEL_DROP_X:
				gel_dropped = true
				gel_pos = pos + Vector2(-2.0, 4.0)
				gel_vel = Vector2(-45.0, _toss.randf_range(-15.0, 15.0))
				out["drop_gel"] = true

			# Soft bump on distracted human
			if not human_hit and human_pos.distance_to(pos) < BUMP_RADIUS:
				human_hit = true
				out["bump"] = true

			# Dog boop on trail runner
			if not booped and dog_pos.distance_to(pos) < BOOP_RADIUS:
				booped = true
				out["boop"] = true

			# Reached western fence verge
			if pos.x <= END_POS.x:
				pos = END_POS
				state = State.SETTLED

		State.SETTLED:
			pass

	if state == State.RUNNING or state == State.SETTLED:
		var close := state == State.RUNNING and pos.distance_to(human_pos) <= THREAT
		var step := NearMiss.consider(close, human_hit, threatened, dodged)
		threatened = bool(step["threatened"])
		if bool(step["dodge"]):
			dodged = true
			out["dodge"] = true

	return out


func on_bark(bark_pos: Vector2) -> bool:
	if state == State.RUNNING and not barked and pos.distance_to(bark_pos) < BARK_RADIUS:
		barked = true
		return true
	return false


# Vector art batched into La Carretera de les Aigües's existing ShapeBatch
func draw(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	if m.lvl != "aigues":
		return

	# Only draw if within vertical view span
	if CROSSING_Y < vt - 120.0 or CROSSING_Y > vb + 120.0:
		return

	# 1. Dropped electrolyte gel pouch on sauló grit
	if gel_dropped and not gel_snatched:
		b.circle(gel_pos + Shade.light * 2.0, 3.5, SHADOW)
		# Shiny foil packet with tear tab
		b.rect(Rect2(gel_pos.x - 4.0, gel_pos.y - 2.5, 8.0, 5.0), GEL_SILVER)
		b.rect(Rect2(gel_pos.x - 2.0, gel_pos.y - 2.0, 4.0, 4.0), GEL_BLUE)
		b.circle(gel_pos + Vector2(3.5, 0.0), 1.2, GEL_ORANGE)

	# 2. Trail Runner
	if state == State.RUNNING or state == State.SETTLED or state == State.TELEGRAPH:
		var rp := pos
		var stride: float = sin(anim_time * 24.0) if state == State.RUNNING else 0.0
		var pole_stride: float = cos(anim_time * 24.0) if state == State.RUNNING else 0.0

		# Shadow on trail grit
		b.circle(rp + Shade.light * 4.0, 11.0, SHADOW)

		# Pumping legs in running shorts
		var leg_l := rp + Vector2(-stride * 5.0, -5.0)
		var leg_r := rp + Vector2(stride * 5.0, 5.0)
		b.circle(leg_l, 3.0, SHORTS_DARK)
		b.circle(leg_r, 3.0, SHORTS_DARK)
		b.circle(leg_l + Vector2(-stride * 3.0, 0.0), 2.2, SKIN_TONE)
		b.circle(leg_r + Vector2(stride * 3.0, 0.0), 2.2, SKIN_TONE)

		# Torso (neon running shirt with black hydration vest)
		b.circle(rp, 7.5, SHIRT_NEON)
		b.rect(Rect2(rp.x - 5.0, rp.y - 5.0, 10.0, 10.0), SHIRT_NEON)
		# Hydration vest straps & twin flask caps on chest
		b.rect(Rect2(rp.x - 4.0, rp.y - 4.0, 3.0, 8.0), VEST_BLACK)
		b.rect(Rect2(rp.x + 1.0, rp.y - 4.0, 3.0, 8.0), VEST_BLACK)
		b.circle(rp + Vector2(-2.5, -2.0), 1.2, FLASK_CAP)
		b.circle(rp + Vector2(2.5, -2.0), 1.2, FLASK_CAP)

		# Head with white running sun visor
		var head_p := rp + Vector2(-2.0, 0.0)
		b.circle(head_p, 5.5, SKIN_TONE)
		b.circle(head_p + Vector2(-1.0, 0.0), 4.5, CAP_WHITE)
		# Visor brim pointing west (-x)
		b.line(head_p + Vector2(-4.0, -2.0), head_p + Vector2(-7.0, 0.0), CAP_WHITE, 1.8)

		# Outstretched arms with trekking poles
		var hand_l := rp + Vector2(-4.0 + pole_stride * 6.0, -8.0)
		var hand_r := rp + Vector2(-4.0 - pole_stride * 6.0, 8.0)
		b.circle(hand_l, 2.0, SKIN_TONE)
		b.circle(hand_r, 2.0, SKIN_TONE)

		# Trekking poles angling down to the ground
		var pole_tip_l := hand_l + Vector2(-8.0 + pole_stride * 4.0, -4.0)
		var pole_tip_r := hand_r + Vector2(-8.0 - pole_stride * 4.0, 4.0)
		b.line(hand_l, pole_tip_l, POLE_CARBON, 1.8)
		b.line(hand_r, pole_tip_r, POLE_CARBON, 1.8)
		b.circle(pole_tip_l, 1.2, POLE_TIP)
		b.circle(pole_tip_r, 1.2, POLE_TIP)
