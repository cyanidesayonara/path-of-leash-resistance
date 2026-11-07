class_name EspanyaBubble
extends RefCounted

# WALK 31: PLAÇA D'ESPANYA - EL BUFADOR DE BOMBOLLES LIVE EVENT
#
# A vibrant street artist in a striped sailor jersey and beret blowing colossal
# iridescent soap bubbles with a giant rope loop wand along Avinguda Maria Cristina.
#
# Event timeline & choreography:
# 1. IDLE: Waits on the east promenade terrace at x = 750.0, y = -1450.0.
# 2. TELEGRAPH: When dog or human approaches within 185 px from south (y >= -1630.0):
#    - 0.8 s warning telegraph: soapy swirl and announcement
#      ("Look at the bubbles!" / "Mireu les bombolles!").
# 3. BLOWING: Glides west across the avenue at 90 px/s casting a trail of giant floating bubbles:
#    - Distracted human bump hazard: -8 patience drop on bucket collision.
#    - Giant bubble popping trick: dog leaps/snouts into floating bubbles for "bubble pop! +2".
#    - Soapy wet-stone slide trick: dog sliding on soapy stone gives "soapy slide! +2".
#    - Artist cheer on bark: barking within 145 px prompts "Molt bé! +2".
#    - Near-miss dodge save: NearMiss.consider triggers "espanya dodge! +2".
# 4. SETTLED: Rests bucket on western promenade edge at x = 490.0, waving the loop.
#
# Performance contract:
# - Zero new draw calls: batched via Espanya's live ShapeBatch.

const ShapeBatch := preload("res://systems/shape_batch.gd")
const NearMiss := preload("res://systems/near_miss.gd")

enum State { IDLE, TELEGRAPH, BLOWING, SETTLED }

const CROSSING_Y := -1450.0
const START_POS := Vector2(750.0, CROSSING_Y)
const END_POS := Vector2(490.0, CROSSING_Y)
const SPEED := 95.0
const TELEGRAPH_TIME := 0.8

# Visual colors
const BERET_YELLOW := Color(0.94, 0.80, 0.22)
const SHIRT_STRIPE_NAVY := Color(0.14, 0.22, 0.38)
const SHIRT_STRIPE_WHITE := Color(0.94, 0.94, 0.96)
const PANTS_TERRACOTTA := Color(0.78, 0.38, 0.25)
const BUCKET_BLUE := Color(0.20, 0.45, 0.75)
const SOAP_SUDS := Color(0.96, 0.98, 1.0, 0.85)
const WAND_BRASS := Color(0.85, 0.70, 0.35)
const BUBBLE_SHEEN_CYAN := Color(0.50, 0.85, 0.95, 0.45)
const BUBBLE_SHEEN_MAGENTA := Color(0.92, 0.55, 0.85, 0.35)
const BUBBLE_RIM := Color(0.95, 0.98, 1.0, 0.70)

var state: State = State.IDLE
var pos: Vector2 = START_POS
var telegraph_t: float = 0.0
var anim_t: float = 0.0

var human_hit: bool = false
var bubble_popped: bool = false
var slide_done: bool = false
var cheered: bool = false
var threatened: bool = false
var dodge_done: bool = false

# Bubble floating positions relative to performer
var bubble_offsets: Array[Vector2] = [
	Vector2(32.0, -28.0),
	Vector2(65.0, -42.0),
	Vector2(95.0, -18.0),
	Vector2(130.0, -35.0),
]


func reset() -> void:
	state = State.IDLE
	pos = START_POS
	telegraph_t = 0.0
	anim_t = 0.0
	human_hit = false
	bubble_popped = false
	slide_done = false
	cheered = false
	threatened = false
	dodge_done = false


func tick(delta: float, dog_pos: Vector2, dog_vel: Vector2, human_pos: Vector2) -> Dictionary:
	var out := {
		"telegraph": false,
		"bump_hazard": false,
		"bubble_pop": false,
		"soapy_slide": false,
		"cheer": false,
		"dodge_save": false,
	}

	match state:
		State.IDLE:
			var trig_dist: float = minf(dog_pos.distance_to(pos), human_pos.distance_to(pos))
			if trig_dist < 185.0 or (human_pos.y > CROSSING_Y and human_pos.y < CROSSING_Y + 160.0 and absf(human_pos.x - 640.0) < 220.0):
				state = State.TELEGRAPH
				telegraph_t = 0.0
				out["telegraph"] = true

		State.TELEGRAPH:
			telegraph_t += delta
			if telegraph_t >= TELEGRAPH_TIME:
				state = State.BLOWING

		State.BLOWING:
			anim_t += delta
			pos.x = maxf(END_POS.x, pos.x - SPEED * delta)
			if pos.x <= END_POS.x:
				state = State.SETTLED

			# Distracted human bump hazard: bucket is placed slightly beside artist
			var bucket_pos := pos + Vector2(16.0, 6.0)
			if not human_hit and human_pos.distance_to(bucket_pos) < 26.0:
				human_hit = true
				out["bump_hazard"] = true

			# Giant bubble popping trick
			if not bubble_popped:
				for off: Vector2 in bubble_offsets:
					var b_pos := pos + off + Vector2(0.0, sin(anim_t * 3.0 + off.x) * 8.0)
					if dog_pos.distance_to(b_pos) < 32.0:
						bubble_popped = true
						out["bubble_pop"] = true
						break

			# Soapy wet stone slide trick (dog moving fast over the soapy track behind artist)
			if not slide_done and dog_vel.length() > 140.0:
				var trail_dist: float = dog_pos.distance_to(pos + Vector2(40.0, 0.0))
				if trail_dist < 42.0:
					slide_done = true
					out["soapy_slide"] = true

			# Near-miss dodge save
			var close: bool = human_pos.distance_to(pos) < 46.0 or dog_pos.distance_to(pos) < 38.0
			var res: Dictionary = NearMiss.consider(close, human_hit, threatened, dodge_done)
			threatened = res["threatened"]
			if res["dodge"]:
				dodge_done = true
				out["dodge_save"] = true

		State.SETTLED:
			pass

	return out


func on_bark(bark_pos: Vector2) -> bool:
	if not cheered and (state == State.BLOWING or state == State.TELEGRAPH or state == State.SETTLED):
		if bark_pos.distance_to(pos) < 145.0:
			cheered = true
			return true
	return false


func draw(batch: ShapeBatch) -> void:
	# Soapy wet trail on pavement behind performer
	if state == State.BLOWING or state == State.SETTLED:
		var trail_start := START_POS.x
		var trail_cur := pos.x
		var w := trail_start - trail_cur
		if w > 10.0:
			batch.rect(Rect2(trail_cur + 10.0, CROSSING_Y - 14.0, w, 28.0), Color(0.90, 0.95, 1.0, 0.18))
			# Tiny iridescent foam flecks
			for i in range(int(w / 35.0)):
				var fx := trail_cur + 20.0 + float(i) * 35.0
				batch.circle(Vector2(fx, CROSSING_Y - 4.0), 3.5, SOAP_SUDS)

	# Performer shadow
	batch.circle(pos + Vector2(0.0, 6.0), 14.0, Color(0.04, 0.05, 0.07, 0.25))

	# Performer body: pants, striped jersey torso, head, yellow beret
	batch.rect(Rect2(pos.x - 6.0, pos.y - 12.0, 12.0, 18.0), PANTS_TERRACOTTA)
	batch.rect(Rect2(pos.x - 8.0, pos.y - 28.0, 16.0, 16.0), SHIRT_STRIPE_NAVY)
	batch.rect(Rect2(pos.x - 8.0, pos.y - 25.0, 16.0, 3.5), SHIRT_STRIPE_WHITE)
	batch.rect(Rect2(pos.x - 8.0, pos.y - 19.0, 16.0, 3.5), SHIRT_STRIPE_WHITE)
	# Head
	batch.circle(pos + Vector2(0.0, -35.0), 7.0, Color(0.88, 0.72, 0.58))
	# Yellow beret tilted
	batch.circle(pos + Vector2(2.0, -39.0), 8.5, BERET_YELLOW)

	# Soapy bucket beside artist
	var bucket_pos := pos + Vector2(16.0, 4.0)
	batch.circle(bucket_pos + Vector2(0.0, 4.0), 8.0, Color(0.04, 0.05, 0.07, 0.22))
	batch.rect(Rect2(bucket_pos.x - 7.0, bucket_pos.y - 10.0, 14.0, 14.0), BUCKET_BLUE)
	batch.circle(bucket_pos + Vector2(0.0, -10.0), 7.0, SOAP_SUDS)

	# Wand loop held high
	var wand_pos := pos + Vector2(-12.0, -36.0)
	batch.rect(Rect2(wand_pos.x - 2.0, wand_pos.y - 2.0, 4.0, 18.0), WAND_BRASS)
	batch.circle(wand_pos + Vector2(0.0, -8.0), 10.0, WAND_BRASS)
	batch.circle(wand_pos + Vector2(0.0, -8.0), 8.0, SOAP_SUDS)

	# Giant floating bubbles drifting across the avenue
	if state == State.BLOWING and not bubble_popped:
		for i in range(bubble_offsets.size()):
			var off: Vector2 = bubble_offsets[i]
			var b_pos := pos + off + Vector2(0.0, sin(anim_t * 3.0 + off.x) * 8.0)
			var r: float = 12.0 + float(i % 3) * 4.0
			# Soft ground shadow under bubble
			batch.circle(Vector2(b_pos.x, CROSSING_Y + 12.0), r * 0.7, Color(0.04, 0.06, 0.10, 0.12))
			# Shimmering translucent bubble body
			batch.circle(b_pos, r, BUBBLE_SHEEN_CYAN)
			batch.circle(b_pos + Vector2(-2.0, -2.0), r * 0.75, BUBBLE_SHEEN_MAGENTA)
			# Shiny highlight gleam
			batch.circle(b_pos + Vector2(-r * 0.35, -r * 0.35), r * 0.25, BUBBLE_RIM)
