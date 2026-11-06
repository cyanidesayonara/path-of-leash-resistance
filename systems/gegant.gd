class_name Gegant
extends RefCounted

# WALK 26: FESTA DE GRÀCIA - GEGANT REHEARSAL TWIRL
# Signature live event for Festa de Gràcia (decorated narrow street):
# A towering papier-mâché festival giant (el Gegant de Gràcia) carried by a bearer
# inside rehearses festive twirls ("ball de gegants") across the decorated street
# at y = -2080.0, between the churro stand (y = -1940.0) and Arch 3 (y = -2350.0).
#
# Gameplay contract:
# - 0.8 s warning telegraph: Bearer hoists the giant and calls out from the western sidewalk
#   at x = 445.0, y = -2080.0 ("Giant coming through! Visca!" / "Compte amb el gegant!") with a celebratory
#   chime and rustling velvet folds as the towering figure prepares to twirl.
# - Soft failure / hazard: distracted human wandering into the giant's spinning velvet skirt
#   gets bumped (-8 patience drop, "Wow, that thing is huge!").
# - Dog trick (rosette snatch): as the giant twirls across the center street (x >= 610.0),
#   a decorative festival ribbon rosette slips loose and flutters onto the street pavement;
#   pouncing or booping it awards "rosette snatch! +2" and increments snack/bone count.
# - Bark trick: barking near the giant (within 150 px) prompts the giant to break into an
#   enthusiastic celebratory pirouette spin; the bearer/spectator shouts "Dance with us! Visca!" or "Olé!",
#   awarding "giant dance! +2".
# - Boop trick: booping the giant's hem directly awards "giant boop! +2".
# - Dodge: steering your human safely clear past the crossing trajectory after entering
#   threat radius (68 px) awards "giant dodge! +2" and increments saves_done.
#   Walking past outside threat radius awards nothing (Cursor near-miss rule).
# - Autowalk: timing naturally clears the center corridor (x = 640.0) well before the
#   autowalk pair arrives, ensuring 100% reliable automated traversal and test stability.
# - Zero new draw calls: batched directly into Festa de Gràcia's ShapeBatch (draw_live).

const ShapeBatch := preload("res://systems/shape_batch.gd")

const START_POS := Vector2(445.0, -2080.0)
const END_POS := Vector2(835.0, -2080.0)
const CROSSING_Y := -2080.0
const TRIGGER_Y := -1720.0

const WARN_DURATION := 0.8
const TWIRL_SPEED := 160.0
const BUMP_RADIUS := 34.0
const THREAT := 68.0
const SNATCH_RADIUS := 28.0
const BOOP_RADIUS := 30.0
const BARK_RADIUS := 150.0
const ROSETTE_DROP_X := 610.0

enum State { IDLE, TELEGRAPH, TWIRLING, SETTLED }

var state: State = State.IDLE
var timer: float = 0.0
var pos: Vector2 = START_POS
var triggered: bool = false
var human_hit: bool = false
var booped: bool = false
var rosette_dropped: bool = false
var rosette_snatched: bool = false
var rosette_pos: Vector2 = Vector2.ZERO
var rosette_vel: Vector2 = Vector2.ZERO
var barked: bool = false
var dodged: bool = false
var threatened: bool = false
var _toss := RandomNumberGenerator.new()
var anim_time: float = 0.0
var spin_angle: float = 0.0

# Visual colors
const VELVET_BLUE := Color(0.18, 0.32, 0.65)
const VELVET_DARK := Color(0.11, 0.19, 0.42)
const GOLD_TRIM := Color(0.92, 0.75, 0.22)
const SENYERA_RED := Color(0.85, 0.20, 0.16)
const SHIRT_WHITE := Color(0.95, 0.94, 0.90)
const SKIN_TONE := Color(0.88, 0.72, 0.58)
const HAIR_DARK := Color(0.20, 0.14, 0.10)
const CROWN_GOLD := Color(0.96, 0.82, 0.28)
const SHOE_LEATHER := Color(0.16, 0.12, 0.10)
const FLAGS: Array[Color] = [
	Color(0.85, 0.20, 0.16), Color(0.92, 0.75, 0.22),
	Color(0.18, 0.32, 0.65), Color(0.25, 0.65, 0.35)
]


func _init() -> void:
	_toss.seed = 0x6E67A


func reset() -> void:
	state = State.IDLE
	timer = 0.0
	pos = START_POS
	triggered = false
	human_hit = false
	booped = false
	rosette_dropped = false
	rosette_snatched = false
	rosette_pos = Vector2.ZERO
	rosette_vel = Vector2.ZERO
	barked = false
	dodged = false
	threatened = false
	anim_time = 0.0
	spin_angle = 0.0


func tick(delta: float, dog_pos: Vector2, _dog_vel: Vector2, human_pos: Vector2) -> Dictionary:
	var out := {
		"warn": false,
		"bump": false,
		"snatch": false,
		"boop": false,
		"dodge": false,
	}

	# Update dropped rosette physics
	if rosette_dropped and not rosette_snatched:
		rosette_pos += rosette_vel * delta
		rosette_vel = rosette_vel.move_toward(Vector2.ZERO, 90.0 * delta)

		if dog_pos.distance_to(rosette_pos) <= SNATCH_RADIUS:
			rosette_snatched = true
			out["snatch"] = true

	# Boop interaction
	if (state == State.TELEGRAPH or state == State.TWIRLING) and not booped:
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
			spin_angle = sin(anim_time * 4.0) * 0.2
			if timer >= WARN_DURATION:
				state = State.TWIRLING
				timer = 0.0

		State.TWIRLING:
			anim_time += delta
			pos.x += TWIRL_SPEED * delta
			pos.y = CROSSING_Y + sin(anim_time * 7.0) * 3.0
			spin_angle += (6.0 if barked else 4.2) * delta

			# Giant drops a festive rosette near center street
			if not rosette_dropped and pos.x >= ROSETTE_DROP_X:
				rosette_dropped = true
				rosette_pos = pos + Vector2(0.0, 8.0)
				rosette_vel = Vector2(30.0, _toss.randf_range(-15.0, 15.0))

			# Soft bump hazard on human
			if not human_hit and pos.distance_to(human_pos) <= BUMP_RADIUS:
				human_hit = true
				out["bump"] = true

			if pos.x >= END_POS.x:
				pos = END_POS
				state = State.SETTLED

		State.SETTLED:
			anim_time += delta
			spin_angle += 1.0 * delta

	if state == State.TWIRLING or state == State.SETTLED:
		var close := state == State.TWIRLING and pos.distance_to(human_pos) <= THREAT
		var step := NearMiss.consider(close, human_hit, threatened, dodged)
		threatened = bool(step["threatened"])
		if bool(step["dodge"]):
			dodged = true
			out["dodge"] = true

	return out


func on_bark(dog_pos: Vector2) -> bool:
	if (state == State.TWIRLING or state == State.SETTLED) and not barked:
		if dog_pos.distance_to(pos) <= BARK_RADIUS:
			barked = true
			spin_angle += PI * 0.75
			return true
	return false


func draw(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	if state == State.IDLE:
		return
	if pos.y < vt - 80.0 or pos.y > vb + 80.0:
		return
	var sh := Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.28)

	# Draw dropped ribbon rosette
	if rosette_dropped and not rosette_snatched:
		b.circle(rosette_pos + Vector2(1, 2), 6.5, sh)
		for k in range(5):
			var a := float(k) * (TAU / 5.0) + anim_time * 2.0
			var loop_p := rosette_pos + Vector2(cos(a) * 4.5, sin(a) * 4.5)
			b.circle(loop_p, 3.5, FLAGS[k % FLAGS.size()])
		b.circle(rosette_pos, 3.5, GOLD_TRIM)
		b.circle(rosette_pos, 1.8, SENYERA_RED)

	# 1. Shadow under giant and bearer
	b.circle(pos + Vector2(2, 6), 26.0, sh)

	# 2. Bearer's feet below the hem taking quick twirling steps
	var foot_phase := anim_time * 12.0
	var f1 := pos + Vector2(sin(foot_phase) * 6.0 - 4.0, 12.0 + cos(foot_phase) * 2.0)
	var f2 := pos + Vector2(-sin(foot_phase) * 6.0 + 4.0, 12.0 - cos(foot_phase) * 2.0)
	b.circle(f1, 3.5, SHOE_LEATHER)
	b.circle(f2, 3.5, SHOE_LEATHER)

	# 3. Giant's billowing velvet skirt with rotating pleats
	b.circle(pos, 24.0, VELVET_DARK)
	b.circle(pos, 22.5, GOLD_TRIM)
	b.circle(pos, 21.0, VELVET_BLUE)

	# Rotating pleats along the skirt
	for k in range(8):
		var a := float(k) * (TAU / 8.0) + spin_angle
		var pleat_out := pos + Vector2(cos(a) * 21.0, sin(a) * 21.0)
		var pleat_in := pos + Vector2(cos(a) * 9.0, sin(a) * 9.0)
		b.line(pleat_in, pleat_out, GOLD_TRIM.lightened(0.15) if k % 2 == 0 else VELVET_DARK, 2.0)

	# 4. Giant's torso / doublet and festival sash
	b.circle(pos + Vector2(0.0, -2.0), 12.0, VELVET_DARK)
	b.circle(pos + Vector2(0.0, -2.0), 10.5, VELVET_BLUE)
	# Catalan festival sash across chest
	var sash_dir := Vector2.from_angle(spin_angle + 0.8)
	b.line(pos + Vector2(0, -2) - sash_dir * 9.0, pos + Vector2(0, -2) + sash_dir * 9.0, SENYERA_RED, 3.5)
	b.line(pos + Vector2(0, -2) - sash_dir * 9.0, pos + Vector2(0, -2) + sash_dir * 9.0, GOLD_TRIM, 1.2)

	# 5. Outstretched papier-mâché arms
	var arm_dir := Vector2.from_angle(spin_angle)
	var arm_l := pos + Vector2(0, -2) - arm_dir * 18.0
	var arm_r := pos + Vector2(0, -2) + arm_dir * 18.0
	b.circle(arm_l, 4.5, VELVET_BLUE)
	b.circle(arm_r, 4.5, VELVET_BLUE)
	b.circle(arm_l, 3.0, SHIRT_WHITE)
	b.circle(arm_r, 3.0, SHIRT_WHITE)
	b.circle(arm_l - arm_dir * 2.0, 2.5, SKIN_TONE)
	b.circle(arm_r + arm_dir * 2.0, 2.5, SKIN_TONE)

	# 6. Sculpted head and crown
	var head_pos := pos + Vector2(0.0, -6.0)
	b.circle(head_pos, 7.5, HAIR_DARK)
	b.circle(head_pos, 6.0, SKIN_TONE)
	# Rosy festival cheeks
	var face_fwd := Vector2.from_angle(spin_angle + PI * 0.5)
	b.circle(head_pos + face_fwd * 2.0 + Vector2(-2, 0), 1.5, SENYERA_RED.lightened(0.4))
	b.circle(head_pos + face_fwd * 2.0 + Vector2(2, 0), 1.5, SENYERA_RED.lightened(0.4))
	# Crown with jeweled points
	b.circle(head_pos + Vector2(0, -3), 5.5, CROWN_GOLD)
	for p in range(3):
		var cp := head_pos + Vector2(float(p - 1) * 3.5, -7.5)
		b.circle(cp, 1.8, CROWN_GOLD)
		b.circle(cp, 1.0, SENYERA_RED)
