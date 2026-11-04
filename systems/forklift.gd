class_name Forklift
extends RefCounted

# WALK 13: LA FERRALLA - SCRAPYARD FORKLIFT ("EL TORITO") LIVE EVENT
# Signature telegraphed live event for La Ferralla (the scrapyard):
# A yellow industrial forklift ("el torito" / carretó elevador) driven by an
# operator in blue overalls and an orange safety helmet crosses the open yard
# lane at y = -1150.0, carrying a load of rusty scrap pipes and iron across the
# path from the west dismantling bay toward the east scrap stacks.
#
# Gameplay contract:
# - 0.8 s warning telegraph: When the pair reaches y = -820.0, the forklift operator
#   sounds the reverse beeper ("Pi-pi-pi!") and calls out from the yard entrance:
#   "Compte amb el torito!" with a telegraphed speech bubble.
# - Soft failure / hazard: Distracted human wandering into the forklift's path
#   gets bumped (-8 patience drop, "Whoa! Watch the forklift!",
#   driver: "Al tanto, que porto ferralla!").
# - Dog trick (hubcap snatch): As the forklift crosses the lane (x >= 550.0), a shiny
#   vintage chrome hubcap ("tapacubs") slips loose from the forks onto the yard gravel;
#   pouncing or booping it awards "hubcap snatch! +2" and increments bones/combo
#   (Driver: "Ei, el meu ferro!").
# - Boop trick: Booping the forklift directly awards "forklift boop! +2"
#   ("Hola, gosset del ferro!").
# - Bark trick: Barking near the forklift (within 130 px) causes the driver to brake
#   with a tyre chirp, awarding "forklift bark! +2" ("Ui, quin fre!").
# - Dodge save: Steering your human safely clear past the crossing trajectory after
#   entering threat radius (70 px) awards "scrap dodge! +2" and increments saves_done
#   via NearMiss.consider. Walking past outside threat radius awards nothing.
# - Autowalk: Timing naturally clears the central corridor before the autowalk pair
#   arrives, ensuring 100% reliable automated traversal and test stability.
# - Zero new draw calls: Batched into La Ferralla's ShapeBatch (draw_live).

const ShapeBatch := preload("res://systems/shape_batch.gd")
const AnimClock := preload("res://systems/anim_clock.gd")

const START_POS := Vector2(240.0, -1150.0)
const END_POS := Vector2(950.0, -1150.0)
const CROSSING_Y := -1150.0
const TRIGGER_Y := -820.0

const WARN_DURATION := 0.8
const WALK_SPEED := 240.0
const BUMP_RADIUS := 34.0
const THREAT := 70.0
const SNATCH_RADIUS := 28.0
const BOOP_RADIUS := 30.0
const BARK_RADIUS := 130.0
const DROP_X := 550.0

enum State { IDLE, TELEGRAPH, DRIVING, SETTLED }

var state: State = State.IDLE
var timer: float = 0.0
var pos: Vector2 = START_POS
var triggered: bool = false
var human_hit: bool = false
var booped: bool = false
var hubcap_dropped: bool = false
var hubcap_snatched: bool = false
var hubcap_pos: Vector2 = Vector2.ZERO
var hubcap_vel: Vector2 = Vector2.ZERO
var barked: bool = false
var dodged: bool = false
var threatened: bool = false
var wobble_t: float = 0.0
var _toss := RandomNumberGenerator.new()
var anim_time: float = 0.0

# Visual colors
const LIGHT := Vector2(0.5, 0.866)
const SHADOW := Color(0.04, 0.04, 0.06, 0.26)

# Forklift colors
const FORKLIFT_YELLOW := Color(0.92, 0.70, 0.12)
const FORKLIFT_DARK := Color(0.74, 0.54, 0.08)
const CHASSIS_GREY := Color(0.24, 0.24, 0.26)
const STEEL_DARK := Color(0.32, 0.32, 0.35)
const STEEL_LIGHT := Color(0.55, 0.55, 0.60)
const TYRE_BLACK := Color(0.12, 0.12, 0.14)
const TYRE_RIM := Color(0.35, 0.35, 0.38)
const OVERALLS_BLUE := Color(0.22, 0.38, 0.65)
const HELMET_ORANGE := Color(0.95, 0.50, 0.12)
const SKIN_TONE := Color(0.88, 0.72, 0.58)
const BEACON_AMBER := Color(1.0, 0.75, 0.10)

# Scrap load & dropped hubcap
const RUST_BROWN := Color(0.55, 0.32, 0.18)
const RUST_DARK := Color(0.38, 0.22, 0.14)
const CHROME_BASE := Color(0.72, 0.75, 0.80)
const CHROME_SHINE := Color(0.92, 0.94, 0.98)
const CHROME_CORE := Color(0.58, 0.62, 0.68)


func _init() -> void:
	_toss.seed = 0xF02C1


func reset() -> void:
	state = State.IDLE
	timer = 0.0
	pos = START_POS
	triggered = false
	human_hit = false
	booped = false
	hubcap_dropped = false
	hubcap_snatched = false
	hubcap_pos = Vector2.ZERO
	hubcap_vel = Vector2.ZERO
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

	# Update dropped hubcap physics
	if hubcap_dropped and not hubcap_snatched:
		hubcap_pos += hubcap_vel * delta
		hubcap_vel = hubcap_vel.move_toward(Vector2.ZERO, 50.0 * delta)
		if dog_pos.distance_to(hubcap_pos) <= SNATCH_RADIUS:
			hubcap_snatched = true
			out["snatch"] = true

	# Boop interaction
	if (state == State.TELEGRAPH or state == State.DRIVING) and not booped:
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
				state = State.DRIVING
				timer = 0.0

		State.DRIVING:
			anim_time += delta
			pos.x += WALK_SPEED * delta
			pos.y = CROSSING_Y + sin(anim_time * 12.0) * 1.0

			# Drops a vintage chrome hubcap near center lane
			if not hubcap_dropped and pos.x >= DROP_X:
				hubcap_dropped = true
				hubcap_pos = pos + Vector2(0.0, 14.0)
				hubcap_vel = Vector2(28.0, _toss.randf_range(-14.0, 14.0))

			# Soft bump hazard on human
			if not human_hit and pos.distance_to(human_pos) <= BUMP_RADIUS:
				human_hit = true
				out["bump"] = true

			if pos.x >= END_POS.x:
				pos = END_POS
				state = State.SETTLED

		State.SETTLED:
			anim_time += delta

	if state == State.DRIVING or state == State.SETTLED:
		var close := state == State.DRIVING and pos.distance_to(human_pos) <= THREAT
		var step := NearMiss.consider(close, human_hit, threatened, dodged)
		threatened = step["threatened"]
		if step["dodge"]:
			dodged = true
			out["dodge"] = true

	return out


func on_bark(bark_pos: Vector2) -> bool:
	if (state == State.TELEGRAPH or state == State.DRIVING) and not barked:
		if bark_pos.distance_to(pos) <= BARK_RADIUS:
			barked = true
			wobble_t = 0.5
			return true
	return false


func draw(_m: Node2D, wc: ShapeBatch, vt: float, vb: float) -> void:
	if pos.y < vt - 80.0 or pos.y > vb + 80.0:
		return

	var b := ShapeBatch.new()
	var draw_pos := pos
	if wobble_t > 0.0:
		draw_pos.y += sin(wobble_t * 32.0) * 3.5

	# 1. Ground shadow
	b.circle(draw_pos + Vector2(2.0, 14.0), 32.0, SHADOW)
	b.rect(Rect2(draw_pos.x - 24.0, draw_pos.y - 12.0, 52.0, 26.0), SHADOW)

	# 2. Dropped Hubcap (if fallen and not yet snatched)
	if hubcap_dropped and not hubcap_snatched:
		b.circle(hubcap_pos + Vector2(1.0, 2.0), 8.0, SHADOW)
		b.circle(hubcap_pos, 7.5, CHROME_BASE)
		b.circle(hubcap_pos, 6.0, CHROME_SHINE)
		b.circle(hubcap_pos, 3.0, CHROME_CORE)
		b.circle(hubcap_pos, 1.2, Color(1.0, 1.0, 1.0))

	# 3. Solid rubber tyres (4 wheels)
	# Front drive wheels (+X)
	b.rect(Rect2(draw_pos.x + 8.0, draw_pos.y - 17.0, 12.0, 6.0), TYRE_BLACK)
	b.rect(Rect2(draw_pos.x + 10.0, draw_pos.y - 16.0, 8.0, 4.0), TYRE_RIM)
	b.rect(Rect2(draw_pos.x + 8.0, draw_pos.y + 11.0, 12.0, 6.0), TYRE_BLACK)
	b.rect(Rect2(draw_pos.x + 10.0, draw_pos.y + 12.0, 8.0, 4.0), TYRE_RIM)
	# Rear steer wheels (-X)
	b.rect(Rect2(draw_pos.x - 20.0, draw_pos.y - 15.0, 10.0, 5.0), TYRE_BLACK)
	b.rect(Rect2(draw_pos.x - 18.0, draw_pos.y - 14.0, 6.0, 3.0), TYRE_RIM)
	b.rect(Rect2(draw_pos.x - 20.0, draw_pos.y + 10.0, 10.0, 5.0), TYRE_BLACK)
	b.rect(Rect2(draw_pos.x - 18.0, draw_pos.y + 11.0, 6.0, 3.0), TYRE_RIM)

	# 4. Yellow industrial chassis & counterweight
	# Rear counterweight
	b.circle(draw_pos + Vector2(-16.0, 0.0), 13.0, CHASSIS_GREY)
	b.rect(Rect2(draw_pos.x - 22.0, draw_pos.y - 13.0, 38.0, 26.0), FORKLIFT_YELLOW)
	b.rect(Rect2(draw_pos.x - 20.0, draw_pos.y - 11.0, 34.0, 22.0), FORKLIFT_DARK)
	b.rect(Rect2(draw_pos.x - 16.0, draw_pos.y - 9.0, 26.0, 18.0), FORKLIFT_YELLOW)

	# 5. Driver in blue overalls & orange helmet
	b.circle(draw_pos + Vector2(-2.0, 0.0), 8.0, OVERALLS_BLUE)
	b.circle(draw_pos + Vector2(-1.0, 0.0), 5.5, HELMET_ORANGE)
	b.rect(Rect2(draw_pos.x + 1.0, draw_pos.y - 4.0, 3.0, 8.0), HELMET_ORANGE) # helmet visor
	b.circle(draw_pos + Vector2(4.0, -3.0), 2.5, SKIN_TONE) # hand
	b.circle(draw_pos + Vector2(4.0, 3.0), 2.5, SKIN_TONE) # hand
	b.circle(draw_pos + Vector2(6.0, 0.0), 3.0, STEEL_DARK) # steering wheel

	# 6. Overhead roll cage / protective roof canopy
	b.line(draw_pos + Vector2(-12.0, -10.0), draw_pos + Vector2(8.0, -10.0), STEEL_DARK, 2.0)
	b.line(draw_pos + Vector2(-12.0, 10.0), draw_pos + Vector2(8.0, 10.0), STEEL_DARK, 2.0)
	b.line(draw_pos + Vector2(-12.0, -10.0), draw_pos + Vector2(-12.0, 10.0), STEEL_DARK, 2.0)
	b.line(draw_pos + Vector2(8.0, -10.0), draw_pos + Vector2(8.0, 10.0), STEEL_DARK, 2.0)
	# Roof overhead slat guard
	b.line(draw_pos + Vector2(-6.0, -10.0), draw_pos + Vector2(-6.0, 10.0), STEEL_DARK, 1.5)
	b.line(draw_pos + Vector2(0.0, -10.0), draw_pos + Vector2(0.0, 10.0), STEEL_DARK, 1.5)

	# 7. Flashing amber beacon on roof
	var beacon_pos := draw_pos + Vector2(-8.0, 0.0)
	var flash := 0.7 + 0.3 * sin(float(AnimClock.msec()) * 0.015)
	b.circle(beacon_pos, 4.5, BEACON_AMBER * flash)
	b.circle(beacon_pos, 2.0, Color(1.0, 0.95, 0.6))

	# 8. Vertical mast and forward lifting forks
	# Mast uprights
	b.rect(Rect2(draw_pos.x + 14.0, draw_pos.y - 12.0, 4.0, 24.0), STEEL_DARK)
	b.line(draw_pos + Vector2(16.0, -10.0), draw_pos + Vector2(16.0, 10.0), STEEL_LIGHT, 2.0)
	# Steel forks (tines) extending forward in +X
	b.line(draw_pos + Vector2(18.0, -6.0), draw_pos + Vector2(38.0, -6.0), STEEL_LIGHT, 2.5)
	b.line(draw_pos + Vector2(18.0, 6.0), draw_pos + Vector2(38.0, 6.0), STEEL_LIGHT, 2.5)
	b.line(draw_pos + Vector2(37.0, -7.0), draw_pos + Vector2(39.0, -5.0), STEEL_LIGHT, 2.0)
	b.line(draw_pos + Vector2(37.0, 5.0), draw_pos + Vector2(39.0, 7.0), STEEL_LIGHT, 2.0)

	# 9. Scrap metal load on forks
	b.line(draw_pos + Vector2(20.0, -8.0), draw_pos + Vector2(32.0, -8.0), RUST_BROWN, 4.0)
	b.line(draw_pos + Vector2(19.0, 0.0), draw_pos + Vector2(34.0, 0.0), RUST_DARK, 5.0)
	b.line(draw_pos + Vector2(21.0, 8.0), draw_pos + Vector2(31.0, 8.0), RUST_BROWN, 4.0)
	b.circle(draw_pos + Vector2(25.0, -1.0), 4.0, STEEL_DARK) # old engine piece

	b.flush(wc)
