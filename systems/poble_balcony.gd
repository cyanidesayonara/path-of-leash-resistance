class_name PobleBalcony
extends RefCounted

# El Poble Espanyol's live event: in the whitewashed Andalusian quarter a
# neighbor steps out onto a wrought-iron balcony with a watering can to water
# the geranium pots, and the water pours down onto the stepped lane below.
#
# Telegraphed 0.8 s before it fires like every owner event ("Heads up!"), with
# a dark wet patch on the stones showing where the stream will land.
# - Human caught under the pour: gets soaked (patience drop, a line in their
#   voice, human_soak rises and wet ground makes paws slick, putting the phone
#   at risk the way rain does).
# - Near miss: a save through systems/near_miss.gd (saves_done += 1, +2 bones).
# - Dog standing under the pour: shakes off the water ("shake! +2", +2 bones,
#   advances the watering-can goal).
# - Barking at the neighbor: gets a reply from the balcony and +2 bones.
# - Nose boop on the splash / fallen terracotta saucer: +2 bones.
# Fires up to three times down the lane at fixed balconies on the outward leg,
# never on top of the autowalk pair without its 0.8 s warning.

const ShapeBatch := preload("res://systems/shape_batch.gd")
const NearMiss := preload("res://systems/near_miss.gd")
const EventFeed := preload("res://hud/event_feed.gd")

enum State { IDLE, WARN, POURING, SETTLED }

const WARN_DURATION := 0.8
const POUR_DURATION := 1.65
const SPLASH_R := 46.0
const NEAR_MISS_R := 108.0
const BARK_R := 210.0
const BOOP_R := 42.0
const TRIGGER_LEAD := 230.0
const MIN_WARN_CLEARANCE := 95.0
const BUMP_PATIENCE := 0.08
const SOAK_ADD := 0.35

const STATIONS: Array[Dictionary] = [
	{
		"balcony_pos": Vector2(406.0, -3280.0),
		"splash_pos": Vector2(475.0, -3280.0),
		"side": -1.0,
	},
	{
		"balcony_pos": Vector2(790.0, -3640.0),
		"splash_pos": Vector2(720.0, -3640.0),
		"side": 1.0,
	},
	{
		"balcony_pos": Vector2(468.0, -4020.0),
		"splash_pos": Vector2(538.0, -4020.0),
		"side": -1.0,
	},
]

const HUMAN_LINES: Array[String] = [
	"Hey! Watch the phone!",
	"Aah! That's cold water!",
	"My shirt! Watch the phone!",
]

const BARK_REPLIES: Array[String] = [
	"Sorry down there!",
	"Just watering the geraniums!",
	"Good dog, mind the drip!",
]

var state: int = State.IDLE
var station_idx: int = 0
var warn_t: float = 0.0
var pour_t: float = 0.0
var balcony_pos: Vector2 = STATIONS[0]["balcony_pos"]
var pos: Vector2 = STATIONS[0]["splash_pos"]
var side: float = -1.0

var station_done: Array[bool] = [false, false, false]
var wet_patches: Array[Vector2] = []

var human_hit: bool = false
var threatened: bool = false
var dodged: bool = false
var shaken: bool = false
var barked: bool = false
var booped: bool = false
var total_shakes: int = 0
var total_soaks: int = 0


func reset() -> void:
	state = State.IDLE
	station_idx = 0
	warn_t = 0.0
	pour_t = 0.0
	balcony_pos = STATIONS[0]["balcony_pos"]
	pos = STATIONS[0]["splash_pos"]
	side = float(STATIONS[0]["side"])
	station_done = [false, false, false]
	wet_patches.clear()
	human_hit = false
	threatened = false
	dodged = false
	shaken = false
	barked = false
	booped = false
	total_shakes = 0
	total_soaks = 0


func trigger(m: Node2D, idx: int = 0) -> void:
	var clamped_idx: int = clampi(idx, 0, STATIONS.size() - 1)
	station_idx = clamped_idx
	var st: Dictionary = STATIONS[station_idx]
	balcony_pos = st["balcony_pos"]
	pos = st["splash_pos"]
	side = float(st["side"])
	state = State.WARN
	warn_t = 0.0
	pour_t = 0.0
	human_hit = false
	threatened = false
	dodged = false
	shaken = false
	barked = false
	booped = false
	if m != null:
		if m.human != null and "external_warning_t" in m.human:
			m.human.external_warning_t = maxf(float(m.human.external_warning_t), WARN_DURATION + 0.25)
		if m.has_method("float_text"):
			m.float_text(balcony_pos + Vector2(0.0, -34.0), "Heads up!", Color(0.98, 0.95, 0.88), m.POP_SAY)
		if m.get("feed") != null:
			m.feed.say("HEADS UP! WATER FROM THE BALCONY!", EventFeed.Tone.LOUD)
		var sfx = m.get_node_or_null("/root/Sfx")
		if sfx != null:
			sfx.play("intro_tap", 1.65, -4.0)


func in_wet_patch(p: Vector2) -> bool:
	if state == State.POURING and p.distance_to(pos) <= SPLASH_R + 6.0:
		return true
	for wp: Vector2 in wet_patches:
		if p.distance_to(wp) <= SPLASH_R:
			return true
	return false


func tick(m: Node2D, dt: float) -> void:
	if m == null or m.dog == null or m.human == null:
		return
	var dpos: Vector2 = m.dog.global_position
	var hpos: Vector2 = m.human.global_position
	var sfx = m.get_node_or_null("/root/Sfx")
	if in_wet_patch(dpos):
		m.dog.slick = true

	match state:
		State.IDLE, State.SETTLED:
			if String(m.phase) != "out":
				return
			var lead_y: float = minf(dpos.y, hpos.y)
			for i: int in range(STATIONS.size()):
				if station_done[i]:
					continue
				var sp: Vector2 = STATIONS[i]["splash_pos"]
				# If the pair already passed this balcony without arming, mark it done
				# so it never fires unannounced on top of them.
				if lead_y < sp.y + MIN_WARN_CLEARANCE:
					station_done[i] = true
					continue
				if lead_y <= sp.y + TRIGGER_LEAD:
					trigger(m, i)
					break

		State.WARN:
			warn_t += dt
			if warn_t >= WARN_DURATION:
				state = State.POURING
				pour_t = 0.0
				if not wet_patches.has(pos):
					wet_patches.append(pos)
				if sfx != null:
					sfx.play("splash", 1.25, -3.0)

		State.POURING:
			pour_t += dt
			# Dog standing or trotting under the pouring stream shakes off for +2
			if not shaken and dpos.distance_to(pos) <= SPLASH_R + 8.0:
				shaken = true
				total_shakes += 1
				if "poble_shakes" in m:
					m.poble_shakes += 1
				if m.has_method("award_points"):
					m.award_points(2, "shake! +2")
				if m.get("combo") != null:
					m.combo.add("SHAKE OFF", 2)
				if sfx != null:
					sfx.play("splash", 1.35, -3.0)
					sfx.play("rustle", 1.2, -4.0)
					sfx.play("star", 1.15, -5.0)
			# Nose boop on the outer splash rim / fallen terracotta saucer
			elif not booped and not shaken and dpos.distance_to(pos) <= SPLASH_R + BOOP_R * 0.45:
				var to_splash: Vector2 = pos - dpos
				if to_splash.length() > 1.0 and m.dog.facing.dot(to_splash.normalized()) > 0.35 and m.dog.velocity.length() > 85.0:
					booped = true
					if m.has_method("award_points"):
						m.award_points(2, "geranium boop! +2")
					if m.get("combo") != null:
						m.combo.add("GERANIUM BOOP", 2)
					if sfx != null:
						sfx.play("pop", 1.3, -4.0)
						sfx.play("star", 1.15, -5.0)

			# Human under the pouring stream gets soaked
			var h_dist: float = hpos.distance_to(pos)
			if not human_hit and h_dist <= SPLASH_R:
				human_hit = true
				total_soaks += 1
				m.human.patience = maxf(0.0, m.human.patience - BUMP_PATIENCE)
				var was_soak: float = float(m.human_soak)
				m.human_soak = minf(1.0, was_soak + SOAK_ADD)
				m.dog.slick = true
				if m.human.has_method("bumped"):
					m.human.bumped(Vector2.DOWN)
				var line: String = HUMAN_LINES[station_idx % HUMAN_LINES.size()]
				if m.has_method("float_text"):
					m.float_text(hpos + Vector2(0.0, -32.0), line, Color(1.0, 0.76, 0.74), m.POP_SAY)
				if was_soak < 0.5 and float(m.human_soak) >= 0.5:
					if m.human.has_method("notice"):
						m.human.notice("I'm soaked!", 1.6)
					if m.get("feed") != null:
						m.feed.say("YOUR HUMAN IS HALF SOAKED", EventFeed.Tone.BAD)
				if float(m.human_soak) >= 1.0 and m.has_method("crack_phone"):
					m.crack_phone(hpos)
				if sfx != null:
					sfx.play("splash", 0.95, -2.0)

			# Near-miss save via NearMiss.consider
			var close: bool = h_dist <= NEAR_MISS_R and h_dist > SPLASH_R
			var nm: Dictionary = NearMiss.consider(close, human_hit, threatened, dodged)
			threatened = bool(nm["threatened"])
			if bool(nm["dodge"]):
				dodged = true
				m.saves_done += 1
				if m.has_method("award_points"):
					m.award_points(2, "balcony dodge! +2")
				if m.get("combo") != null:
					m.combo.add("BALCONY DODGE", 2)
				if m.has_method("float_text"):
					m.float_text(hpos + Vector2(0.0, -32.0), "Whew, kept the phone dry!", Color(0.96, 0.94, 0.88), m.POP_SAY)
				if sfx != null:
					sfx.play("star", 1.15, -5.0)

			if pour_t >= POUR_DURATION:
				if threatened and not human_hit and not dodged:
					var nm_end: Dictionary = NearMiss.consider(false, human_hit, threatened, dodged)
					if bool(nm_end["dodge"]):
						dodged = true
						m.saves_done += 1
						if m.has_method("award_points"):
							m.award_points(2, "balcony dodge! +2")
						if m.get("combo") != null:
							m.combo.add("BALCONY DODGE", 2)
						if m.has_method("float_text"):
							m.float_text(hpos + Vector2(0.0, -32.0), "Whew, kept the phone dry!", Color(0.96, 0.94, 0.88), m.POP_SAY)
						if sfx != null:
							sfx.play("star", 1.15, -5.0)
				station_done[station_idx] = true
				state = State.SETTLED


func on_bark(m: Node2D, bark_pos: Vector2) -> bool:
	if m == null or barked:
		return false
	if state != State.WARN and state != State.POURING:
		return false
	if bark_pos.distance_to(balcony_pos) > BARK_R and bark_pos.distance_to(pos) > BARK_R:
		return false
	barked = true
	if m.has_method("award_points"):
		m.award_points(2, "balcony bark! +2")
	if m.get("combo") != null:
		m.combo.add("BALCONY BARK", 2)
	var reply: String = BARK_REPLIES[station_idx % BARK_REPLIES.size()]
	if m.has_method("float_text"):
		m.float_text(balcony_pos + Vector2(0.0, -34.0), reply, Color(0.98, 0.95, 0.88), m.POP_SAY)
	var sfx = m.get_node_or_null("/root/Sfx")
	if sfx != null:
		sfx.play("star", 1.18, -5.0)
	return true


func _ring_segments(b: ShapeBatch, center: Vector2, r: float, col: Color, width: float, segs: int = 16) -> void:
	var prev: Vector2 = center + Vector2(r, 0.0)
	for i: int in range(1, segs + 1):
		var a: float = TAU * float(i) / float(segs)
		var cur: Vector2 = center + Vector2(cos(a), sin(a)) * r
		b.line(prev, cur, col, width)
		prev = cur


func draw(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	var t: float = AnimClock.msec() / 1000.0
	# Draw lingering wet patches on the stepped lane
	for wp: Vector2 in wet_patches:
		if wp.y < vt - 80.0 or wp.y > vb + 80.0:
			continue
		b.circle(wp, SPLASH_R * 0.85, Color(0.18, 0.24, 0.32, 0.34))
		b.circle(wp + Vector2(-5.0, -3.0), SPLASH_R * 0.56, Color(0.28, 0.42, 0.56, 0.28))
		b.circle(wp + Vector2(8.0, 5.0), 4.0, Color(0.84, 0.20, 0.26, 0.75)) # fallen geranium petal
		b.circle(wp + Vector2(-11.0, 7.0), 3.2, Color(0.92, 0.26, 0.34, 0.75))

	# Draw the 3 wrought-iron Andalusian balconies & geranium boxes
	for i: int in range(STATIONS.size()):
		var st: Dictionary = STATIONS[i]
		var bp: Vector2 = st["balcony_pos"]
		var sp: Vector2 = st["splash_pos"]
		var s_side: float = float(st["side"])
		if bp.y < vt - 110.0 or bp.y > vb + 110.0:
			continue
		# Cast shadow under the wrought-iron balcony
		b.rect(Rect2(bp.x - 18.0, bp.y - 30.0, 36.0, 64.0), Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.26))
		# Whitewashed stone corbels & wrought-iron balcony deck
		b.rect(Rect2(bp.x - 16.0, bp.y - 32.0, 32.0, 64.0), Color(0.92, 0.90, 0.86))
		b.rect(Rect2(bp.x - 14.0, bp.y - 30.0, 28.0, 60.0), Color(0.16, 0.17, 0.20))
		# Wrought-iron railing bars
		for ry: int in range(-26, 28, 9):
			b.line(Vector2(bp.x - 14.0, bp.y + float(ry)), Vector2(bp.x + 14.0, bp.y + float(ry)), Color(0.24, 0.26, 0.30), 2.0)
		# Terracotta flowerboxes brimming with red and magenta geraniums
		for fy: float in [-20.0, 0.0, 20.0]:
			var pot_x: float = bp.x - s_side * 10.0
			b.rect(Rect2(pot_x - 5.0, bp.y + fy - 7.0, 10.0, 14.0), Color(0.74, 0.38, 0.22))
			b.circle(Vector2(pot_x, bp.y + fy - 3.0), 6.0, Color(0.20, 0.48, 0.22))
			b.circle(Vector2(pot_x - s_side * 2.0, bp.y + fy - 4.0), 4.0, Color(0.88, 0.18, 0.24))
			b.circle(Vector2(pot_x + s_side * 2.0, bp.y + fy + 3.0), 3.6, Color(0.94, 0.28, 0.42))

		# Active neighbor with watering can during WARN or POURING
		var is_active: bool = (i == station_idx) and (state == State.WARN or state == State.POURING)
		if is_active:
			var lean: float = -s_side * (6.0 if state == State.POURING else 3.0)
			var np: Vector2 = bp + Vector2(lean, 0.0)
			# Neighbor's straw hat / head and linen shirt
			b.circle(np, 9.5, Color(0.32, 0.54, 0.78))
			b.circle(np, 6.5, Color(0.88, 0.70, 0.56))
			b.circle(np + Vector2(0.0, -1.0), 5.0, Color(0.24, 0.18, 0.14))
			# Copper-green metal watering can held out over the railing
			var can_pos: Vector2 = np + Vector2(-s_side * 15.0, 2.0)
			b.circle(can_pos, 5.5, Color(0.22, 0.56, 0.44))
			b.line(can_pos, can_pos + Vector2(-s_side * 9.0, 2.0), Color(0.22, 0.56, 0.44), 3.0)
			b.circle(can_pos + Vector2(-s_side * 10.0, 2.5), 3.0, Color(0.76, 0.62, 0.34))

		# 0.8 s telegraph dark wet target patch & warning ring on the stepped lane
		if i == station_idx and state == State.WARN:
			var prog: float = clampf(warn_t / WARN_DURATION, 0.0, 1.0)
			b.circle(sp, SPLASH_R * (0.42 + 0.52 * prog), Color(0.16, 0.24, 0.34, 0.24 + 0.24 * prog))
			var pulse_r: float = SPLASH_R * (0.35 + 0.65 * fmod(t * 2.8, 1.0))
			_ring_segments(b, sp, pulse_r, Color(0.56, 0.82, 0.98, 0.65), 2.5, 16)
			# Early warning droplets falling from the spout
			for di: int in range(3):
				var df: float = fmod(prog * 2.0 + float(di) * 0.33, 1.0)
				var dp: Vector2 = bp.lerp(sp, df)
				b.circle(dp, 2.5, Color(0.68, 0.88, 1.0, 0.75))

		# Active pouring stream & splash crown on the lane
		elif i == station_idx and state == State.POURING:
			var spout: Vector2 = bp + Vector2(-s_side * 24.0, 2.5)
			b.glow(sp, SPLASH_R * 1.15, Color(0.48, 0.76, 0.96, 0.28))
			# Multiple shimmering streams from the watering-can rose to the lane
			for si: int in range(5):
				var spread: float = float(si - 2) * 5.5
				var target_p: Vector2 = sp + Vector2(spread * 0.6, spread)
				b.line(spout, target_p, Color(0.66, 0.88, 1.0, 0.55), 2.2)
				var drop_f: float = fmod(t * 5.5 + float(si) * 0.21, 1.0)
				b.circle(spout.lerp(target_p, drop_f), 3.0, Color(0.86, 0.96, 1.0, 0.85))
			# Expanding splash rings on the stones
			for ri: int in range(3):
				var rf: float = fmod(t * 2.6 + float(ri) * 0.33, 1.0)
				_ring_segments(b, sp, 8.0 + rf * (SPLASH_R - 8.0), Color(0.82, 0.94, 1.0, 0.65 * (1.0 - rf)), 2.2, 16)
