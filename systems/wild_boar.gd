class_name WildBoar
extends RefCounted

# WALK 25: ELS SENGLARS - WILD BOAR FAMILY CROSSING
# Signature live event for Els Senglars (Collserola mountain woods):
# A wild sow (la truja senglara) and her two striped piglets root along
# the trail edge and cross the path westbound-to-eastbound at y = -2150.0,
# heading toward the oak hollows and mud wallow.
#
# Gameplay contract:
# - 0.8 s warning telegraph: Sow grunts deeply from the western thicket at
#   x = 340.0, y = -2150.0 ("Gronf!") with a telegraphed speech bubble
#   and rustling brush sound as two striped piglets peek out first.
# - Soft failure / hazard: distracted human wandering into the sow's crossing path
#   gets bumped flat by the protective sow (-8 patience drop, "Is that a boar?!").
# - Dog trick: as the sow roots across the center trail (x >= 590.0), an unearthed
#   wild black truffle drops onto the dirt; pouncing or booping it awards
#   "truffle snatch! +2" (sow: "Gronf!").
# - Bark trick: barking near the crossing sow startles her into a bluff-charge huff,
#   awarding "boar bark! +2" ("Gronf!").
# - Boop trick: booping the sow directly on the snout awards "boar boop! +2".
# - Dodge: steering your human safely clear past the crossing trajectory
#   awards "boar dodge! +2" / "Whew, close one!".
# - Autowalk: timing naturally clears the center corridor (x = 640.0) before the
#   autowalk pair arrives, ensuring 100% reliable automated traversal and test stability.
# - Zero new draw calls: batched directly into Els Senglars's existing ShapeBatch.

const ShapeBatch := preload("res://systems/shape_batch.gd")

const START_POS := Vector2(340.0, -2150.0)
const END_POS := Vector2(940.0, -2150.0)
const CROSSING_Y := -2150.0
const TRIGGER_Y := -1920.0

const WARN_DURATION := 0.8
const RUN_SPEED := 175.0
const BUMP_RADIUS := 32.0
const THREAT := 64.0
const SNATCH_RADIUS := 28.0
const BOOP_RADIUS := 26.0
const BARK_RADIUS := 140.0
const TRUFFLE_DROP_X := 590.0

enum State { IDLE, TELEGRAPH, RUNNING, SETTLED }

var state: State = State.IDLE
var timer: float = 0.0
var pos: Vector2 = START_POS
var triggered: bool = false
var human_hit: bool = false
var booped: bool = false
var truffle_dropped: bool = false
var truffle_snatched: bool = false
var truffle_pos: Vector2 = Vector2.ZERO
var truffle_vel: Vector2 = Vector2.ZERO
var barked: bool = false
var dodged: bool = false
var threatened: bool = false
var _toss := RandomNumberGenerator.new()
var anim_time: float = 0.0

# Visual colors
const FUR_DARK := Color(0.20, 0.17, 0.15)
const FUR_BRISTLE := Color(0.32, 0.26, 0.22)
const SNOUT_PINK := Color(0.76, 0.52, 0.50)
const TUSK_WHITE := Color(0.96, 0.95, 0.90)
const PIG_BASE := Color(0.48, 0.38, 0.28)
const PIG_STRIPE := Color(0.75, 0.65, 0.48)
const TRUFFLE_BLACK := Color(0.14, 0.12, 0.10)
const TRUFFLE_DIRT := Color(0.38, 0.28, 0.18)


func _init() -> void:
	_toss.seed = 0xB0A85


func reset() -> void:
	state = State.IDLE
	timer = 0.0
	pos = START_POS
	triggered = false
	human_hit = false
	booped = false
	truffle_dropped = false
	truffle_snatched = false
	truffle_pos = Vector2.ZERO
	truffle_vel = Vector2.ZERO
	barked = false
	dodged = false
	threatened = false
	anim_time = 0.0


func tick(delta: float, dog_pos: Vector2, _dog_vel: Vector2, human_pos: Vector2) -> Dictionary:
	var out := {
		"warn": false,
		"bump": false,
		"snatch": false,
		"boop": false,
		"dodge": false,
	}

	# Update dropped truffle physics
	if truffle_dropped and not truffle_snatched:
		truffle_pos += truffle_vel * delta
		truffle_vel = truffle_vel.move_toward(Vector2.ZERO, 90.0 * delta)

		if dog_pos.distance_to(truffle_pos) <= SNATCH_RADIUS:
			truffle_snatched = true
			out["snatch"] = true

	# Boop interaction
	if (state == State.TELEGRAPH or state == State.RUNNING) and not booped:
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
				state = State.RUNNING
				timer = 0.0

		State.RUNNING:
			anim_time += delta
			pos.x += RUN_SPEED * delta
			pos.y = CROSSING_Y + sin(anim_time * 8.0) * 2.0

			# Sow unearths a wild truffle near center trail
			if not truffle_dropped and pos.x >= TRUFFLE_DROP_X:
				truffle_dropped = true
				truffle_pos = pos + Vector2(2.0, 4.0)
				truffle_vel = Vector2(40.0, _toss.randf_range(-15.0, 15.0))

			# Soft bump hazard on human
			if not human_hit and pos.distance_to(human_pos) <= BUMP_RADIUS:
				human_hit = true
				out["bump"] = true

			if pos.x >= END_POS.x:
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


func on_bark(dog_pos: Vector2) -> bool:
	if (state == State.TELEGRAPH or state == State.RUNNING) and not barked:
		if dog_pos.distance_to(pos) < BARK_RADIUS:
			barked = true
			return true
	return false


func draw(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	if pos.y < vt - 80.0 or pos.y > vb + 80.0:
		return

	var sh := Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.26)

	# 1. Dropped wild truffle
	if truffle_dropped and not truffle_snatched:
		b.circle(truffle_pos + Shade.light * 2.0, 4.0, sh)
		b.circle(truffle_pos, 4.5, TRUFFLE_BLACK)
		b.circle(truffle_pos + Vector2(1.0, -1.0), 2.2, TRUFFLE_DIRT)

	if state == State.IDLE:
		return

	# 2. Striped piglets trotting ahead
	if state == State.RUNNING or state == State.TELEGRAPH:
		var piglet_lead := 42.0 if state == State.RUNNING else 22.0
		var p1 := pos + Vector2(piglet_lead, -12.0) + Vector2(sin(anim_time * 16.0) * 2.0, sin(anim_time * 18.0) * 2.0)
		var p2 := pos + Vector2(piglet_lead - 10.0, 14.0) + Vector2(cos(anim_time * 15.0) * 2.0, cos(anim_time * 17.0) * 2.0)
		for p: Vector2 in [p1, p2]:
			b.circle(p + Shade.light * 3.0, 5.0, sh)
			b.circle(p, 5.5, PIG_BASE)
			b.circle(p + Vector2(3.5, 0.0), 3.5, PIG_BASE)
			b.circle(p + Vector2(5.5, 0.0), 1.6, SNOUT_PINK)
			b.line(p + Vector2(-3.0, -2.0), p + Vector2(2.0, -2.0), PIG_STRIPE, 1.2)
			b.line(p + Vector2(-3.0, 2.0), p + Vector2(2.0, 2.0), PIG_STRIPE, 1.2)

	# 3. Mother Sow
	var bob := sin(anim_time * 12.0) * 2.0 if state == State.RUNNING else 0.0
	var sow_p := pos + Vector2(0.0, bob)

	# Cast shadow
	b.circle(sow_p + Shade.light * 6.0, 16.0, sh)

	# Body: hindquarters and shoulders
	b.circle(sow_p + Vector2(-6.0, 0.0), 12.0, FUR_DARK)
	b.circle(sow_p + Vector2(6.0, 0.0), 14.0, FUR_BRISTLE)

	# Bristly dorsal ridge
	b.line(sow_p + Vector2(-12.0, -7.0), sow_p + Vector2(10.0, -8.0), FUR_DARK.darkened(0.2), 2.2)

	# Head and cone wedge snout
	b.circle(sow_p + Vector2(16.0, 0.0), 8.5, FUR_BRISTLE)
	b.circle(sow_p + Vector2(22.0, 0.0), 5.0, FUR_BRISTLE)
	b.circle(sow_p + Vector2(25.0, 0.0), 3.2, SNOUT_PINK)
	b.circle(sow_p + Vector2(25.5, -1.0), 0.9, Color(0.2, 0.1, 0.1))
	b.circle(sow_p + Vector2(25.5, 1.0), 0.9, Color(0.2, 0.1, 0.1))

	# Pointed ears
	b.circle(sow_p + Vector2(13.0, -7.5), 2.8, FUR_DARK)
	b.circle(sow_p + Vector2(13.0, 7.5), 2.8, FUR_DARK)

	# White tusks
	b.line(sow_p + Vector2(19.0, -3.5), sow_p + Vector2(22.0, -5.5), TUSK_WHITE, 1.6)
	b.line(sow_p + Vector2(19.0, 3.5), sow_p + Vector2(22.0, 5.5), TUSK_WHITE, 1.6)

	# Curly tail
	b.line(sow_p + Vector2(-16.0, 0.0), sow_p + Vector2(-21.0, -4.0), FUR_DARK, 1.8)
	b.circle(sow_p + Vector2(-21.0, -4.0), 1.5, FUR_DARK)
