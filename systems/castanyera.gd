class_name Castanyera
extends RefCounted

# WALK 12: LA CASTANYADA - HURRYING CASTANYERA & STEAMING CHESTNUT BASKET
# Signature live event for La Castanyada (the nighttime autumn chestnut festival):
# A traditional Catalan castanyera in woollen shawl and dark floral apron emerges
# from the western alleyway threshold at y = -1780.0 carrying a steaming woven
# wicker basket of freshly roasted chestnuts ("paperines de castanyes calentes"),
# hurrying eastbound across the festival street toward a waiting plaza stall.
#
# Gameplay contract:
# - 0.8 s warning telegraph: The castanyera steps out at x = 405.0, y = -1780.0,
#   waving her hand and calling out from the sidewalk threshold: "Hot chestnuts coming through!"
#   with a telegraphed speech bubble and festive chime.
# - Soft failure / hazard: Distracted human wandering into the castanyera's path
#   gets bumped by her steaming basket (-8 patience drop, "Hot! Hot! Hot!").
# - Dog trick (paperina snatch): As she hurries across the center street (x >= 620.0),
#   a paper cone of hot roasted chestnuts ("paperina de castanyes") slips from the basket
#   onto the cobblestones; pouncing or booping it awards "chestnut snatch! +2" and
#   increments bones/combo (Castanyera: "Careful, they're hot!").
# - Boop trick: Booping the castanyera's apron directly awards "castanyera boop! +2"
#   ("Happy Castanyada, pup!").
# - Bark trick: Barking near the castanyera (within 140 px) startles her into a surprised
#   hop and apron ruffle, awarding "castanyera bark! +2" ("Oh, what a cutie!").
# - Dodge save: Steering your human safely clear past the crossing trajectory after
#   entering threat radius (64 px) awards "chestnut dodge! +2" and increments saves_done
#   via NearMiss.consider. Walking past outside threat radius awards nothing.
# - Autowalk: Timing naturally clears the central corridor before the autowalk pair
#   arrives, ensuring 100% reliable automated traversal and test stability.
# - Zero new draw calls: Batched into La Castanyada's ShapeBatch (draw_live).

const ShapeBatch := preload("res://systems/shape_batch.gd")

const START_POS := Vector2(405.0, -1780.0)
const END_POS := Vector2(875.0, -1780.0)
const CROSSING_Y := -1780.0
const TRIGGER_Y := -1460.0

const WARN_DURATION := 0.8
const WALK_SPEED := 180.0
const BUMP_RADIUS := 30.0
const THREAT := 64.0
const SNATCH_RADIUS := 28.0
const BOOP_RADIUS := 28.0
const BARK_RADIUS := 140.0
const DROP_X := 620.0

enum State { IDLE, TELEGRAPH, WALKING, SETTLED }

var state: State = State.IDLE
var timer: float = 0.0
var pos: Vector2 = START_POS
var triggered: bool = false
var human_hit: bool = false
var booped: bool = false
var paperina_dropped: bool = false
var paperina_snatched: bool = false
var paperina_pos: Vector2 = Vector2.ZERO
var paperina_vel: Vector2 = Vector2.ZERO
var barked: bool = false
var dodged: bool = false
var threatened: bool = false
var _toss := RandomNumberGenerator.new()
var anim_time: float = 0.0

# Visual colors
const LIGHT := Vector2(0.5, 0.866)
const SHADOW := Color(0.04, 0.04, 0.06, 0.26)

# Traditional Castanyera attire
const SKIRT_CHARCOAL := Color(0.18, 0.16, 0.18)
const APRON_DARK := Color(0.28, 0.25, 0.24)
const APRON_LACE := Color(0.88, 0.84, 0.78)
const SHAWL_BROWN := Color(0.48, 0.28, 0.18)
const SHAWL_WARM := Color(0.58, 0.36, 0.24)
const KERCHIEF_BLACK := Color(0.14, 0.14, 0.15)
const SKIN_TONE := Color(0.88, 0.72, 0.58)
const HAIR_GREY := Color(0.68, 0.66, 0.64)

# Steaming Wicker Basket & Chestnuts
const BASKET_WICKER := Color(0.72, 0.54, 0.28)
const BASKET_RIM := Color(0.82, 0.64, 0.35)
const BASKET_WEAVE := Color(0.55, 0.38, 0.18)
const LINING_WHITE := Color(0.92, 0.90, 0.86)
const CONE_KRAFT := Color(0.78, 0.65, 0.45)
const CHESTNUT_GLOSS := Color(0.35, 0.18, 0.10)
const CHESTNUT_SPLIT := Color(0.95, 0.80, 0.25)
const STEAM_WHITE := Color(0.95, 0.92, 0.88, 0.40)


func _init() -> void:
	_toss.seed = 0xCA57A


func reset() -> void:
	state = State.IDLE
	timer = 0.0
	pos = START_POS
	triggered = false
	human_hit = false
	booped = false
	paperina_dropped = false
	paperina_snatched = false
	paperina_pos = Vector2.ZERO
	paperina_vel = Vector2.ZERO
	barked = false
	dodged = false
	threatened = false
	anim_time = 0.0


func tick(delta: float, dog_pos: Vector2, _dog_vel: Vector2, human_pos: Vector2) -> Dictionary:
	var out: Dictionary = {
		"warn": false,
		"bump": false,
		"snatch": false,
		"boop": false,
		"dodge": false,
	}

	# Update dropped paperina physics
	if paperina_dropped and not paperina_snatched:
		paperina_pos += paperina_vel * delta
		paperina_vel = paperina_vel.move_toward(Vector2.ZERO, 90.0 * delta)

		if dog_pos.distance_to(paperina_pos) <= SNATCH_RADIUS:
			paperina_snatched = true
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
			pos.y = CROSSING_Y + sin(anim_time * 9.0) * 2.0

			# Drops a steaming paper cone of chestnuts near center street
			if not paperina_dropped and pos.x >= DROP_X:
				paperina_dropped = true
				paperina_pos = pos + Vector2(0.0, 6.0)
				paperina_vel = Vector2(25.0, _toss.randf_range(-15.0, 15.0))

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
			return true
	return false


func draw(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	if state == State.IDLE:
		return
	if pos.y < vt - 80.0 or pos.y > vb + 80.0:
		return

	# Draw dropped paperina of hot chestnuts on paving
	if paperina_dropped and not paperina_snatched:
		b.circle(paperina_pos + Vector2(1, 2), 7.0, SHADOW)
		# Paper cone shape
		b.polygon(PackedVector2Array([
			paperina_pos + Vector2(-6.0, 4.0),
			paperina_pos + Vector2(6.0, 4.0),
			paperina_pos + Vector2(0.0, -8.0),
		]), CONE_KRAFT)
		b.polygon(PackedVector2Array([
			paperina_pos + Vector2(-4.0, 3.0),
			paperina_pos + Vector2(4.0, 3.0),
			paperina_pos + Vector2(0.0, -6.0),
		]), CONE_KRAFT.lightened(0.12))
		# Roasted chestnuts nestled at cone opening
		b.circle(paperina_pos + Vector2(-2.0, 3.0), 3.2, CHESTNUT_GLOSS)
		b.circle(paperina_pos + Vector2(2.0, 3.0), 3.0, CHESTNUT_GLOSS)
		b.circle(paperina_pos + Vector2(0.0, 1.0), 2.8, CHESTNUT_GLOSS)
		# Golden roasted splits
		b.line(paperina_pos + Vector2(-3.0, 3.0), paperina_pos + Vector2(-1.0, 3.0), CHESTNUT_SPLIT, 1.2)
		b.line(paperina_pos + Vector2(1.0, 3.0), paperina_pos + Vector2(3.0, 3.0), CHESTNUT_SPLIT, 1.2)
		# Gentle steam puffs rising
		var st_cycle := fmod(anim_time * 2.0, 1.0)
		b.circle(paperina_pos + Vector2(sin(anim_time * 3.0) * 2.0, -8.0 - st_cycle * 8.0), 2.5 + st_cycle * 2.0, Color(STEAM_WHITE.r, STEAM_WHITE.g, STEAM_WHITE.b, STEAM_WHITE.a * (1.0 - st_cycle)))

	# Castanyera shadow
	b.circle(pos + Vector2(1, 4), 16.0, SHADOW)

	# Footsteps
	var bob := sin(anim_time * 9.0) * 1.5 if state == State.WALKING else 0.0
	var leg_step := sin(anim_time * 9.0) * 5.0 if state == State.WALKING else 0.0
	b.circle(pos + Vector2(-4.0 + leg_step, 6.0), 3.5, Color(0.12, 0.12, 0.14))
	b.circle(pos + Vector2(4.0 - leg_step, 6.0), 3.5, Color(0.12, 0.12, 0.14))

	# Dark woollen skirt
	b.circle(pos + Vector2(0.0, 2.0 + bob), 12.0, SKIRT_CHARCOAL)
	b.rect(Rect2(pos.x - 10.0, pos.y - 4.0 + bob, 20.0, 8.0), SKIRT_CHARCOAL)

	# Apron with lace hem
	b.rect(Rect2(pos.x - 7.0, pos.y - 3.0 + bob, 14.0, 8.0), APRON_DARK)
	b.line(Vector2(pos.x - 7.0, pos.y + 5.0 + bob), Vector2(pos.x + 7.0, pos.y + 5.0 + bob), APRON_LACE, 1.5)

	# Woollen shawl draped over shoulders
	b.circle(pos + Vector2(0.0, -5.0 + bob), 11.0, SHAWL_BROWN)
	b.circle(pos + Vector2(0.0, -6.0 + bob), 9.0, SHAWL_WARM)

	# Head with black kerchief and grey hair peeking
	b.circle(pos + Vector2(0.0, -10.0 + bob), 7.0, KERCHIEF_BLACK)
	b.circle(pos + Vector2(0.0, -9.0 + bob), 5.5, SKIN_TONE)
	b.circle(pos + Vector2(-3.5, -11.0 + bob), 2.2, HAIR_GREY)
	b.circle(pos + Vector2(3.5, -11.0 + bob), 2.2, HAIR_GREY)
	# Kerchief knot under chin
	b.circle(pos + Vector2(0.0, -4.5 + bob), 2.0, KERCHIEF_BLACK)

	# Steaming woven wicker basket held in arms in front
	var bkt_x := pos.x + 10.0
	var bkt_y := pos.y - 2.0 + bob
	b.circle(Vector2(bkt_x + 1, bkt_y + 3), 8.5, SHADOW)
	# Basket body
	b.rect(Rect2(bkt_x - 8.0, bkt_y - 6.0, 16.0, 12.0), BASKET_WICKER)
	b.line(Vector2(bkt_x - 9.0, bkt_y - 6.0), Vector2(bkt_x + 9.0, bkt_y - 6.0), BASKET_RIM, 2.5)
	# Wicker weave lines
	b.line(Vector2(bkt_x - 7.0, bkt_y - 1.0), Vector2(bkt_x + 7.0, bkt_y - 1.0), BASKET_WEAVE, 1.2)
	b.line(Vector2(bkt_x - 7.0, bkt_y + 3.0), Vector2(bkt_x + 7.0, bkt_y + 3.0), BASKET_WEAVE, 1.2)
	# White linen cloth lining
	b.rect(Rect2(bkt_x - 7.0, bkt_y - 7.0, 14.0, 4.0), LINING_WHITE)
	# Stacks of paperines with chestnuts
	for ci in range(3):
		var cx := bkt_x - 4.5 + float(ci) * 4.5
		b.polygon(PackedVector2Array([
			Vector2(cx - 2.5, bkt_y - 6.0),
			Vector2(cx + 2.5, bkt_y - 6.0),
			Vector2(cx, bkt_y - 11.0),
		]), CONE_KRAFT)
		b.circle(Vector2(cx, bkt_y - 6.5), 2.0, CHESTNUT_GLOSS)

	# Billowing warm steam puffs drifting from the basket
	for s in range(3):
		var st_prog := fmod(anim_time * 1.8 + float(s) * 0.33, 1.0)
		var sx := bkt_x - 3.0 - st_prog * 12.0 + sin(anim_time * 4.0 + float(s)) * 3.0
		var sy := bkt_y - 8.0 - st_prog * 14.0
		var sr := 3.0 + st_prog * 4.5
		var sa := STEAM_WHITE.a * (1.0 - st_prog)
		b.circle(Vector2(sx, sy), sr, Color(STEAM_WHITE.r, STEAM_WHITE.g, STEAM_WHITE.b, sa))
