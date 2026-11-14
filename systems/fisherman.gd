class_name Fisherman
extends RefCounted

# WALK 18: EL PORT - QUAYSIDE REEL-IN & SEA BASS CATCH
# Signature live event for El Port: an old fisherman on the quayside stone
# coping hooks an energetic Mediterranean sea bass (llobarro), reeling it up
# out of the harbor basin in an animated spray arc onto the quayside flagstones.
#
# Gameplay contract:
# - 0.8 s warning telegraph: fisherman feels a heavy bite, leans back with a
#   straining bent rod, and calls out "Mind the fishing line!" with a speech bubble.
# - Soft failure / hazard: distracted human wandering into the quayside edge
#   zone gets snagged by the flying tackle or whipped by the swinging line
#   (patience drop, "Yikes, that's a hook!").
# - Dog trick: pouncing or dashing onto the flapping sea bass on the flagstones
#   awards "fish snatch! +2". Barking near the reeling fisherman scares wheeling
#   gulls and awards "gull bark! +2".
# - Dodge: steering your human safely along the central boardwalk (x < 780.0)
#   while passing the fishing spot earns "boardwalk dodge! +2" / "Whew, nice save!".
# - Autowalk: central walking line at x = 640.0 is >200 px clear of the quayside hazard.
# - Zero new draw calls: batched into ShapeBatch.

const ShapeBatch := preload("res://systems/shape_batch.gd")

const FISHERMAN_POS := Vector2(912.0, -1980.0)
const TACKLE_POS := Vector2(880.0, -1960.0)
const BUCKET_POS := Vector2(878.0, -1994.0)
const FISH_LAND_POS := Vector2(885.0, -1980.0)
const WATER_SURFACE_X := 965.0

const TRIGGER_Y := -1780.0
const WARN_DURATION := 0.8
const REEL_DURATION := 1.5
const LANDED_DURATION := 4.5
const SWING_ZONE_X := 840.0
const SWING_RADIUS := 46.0
const BARK_RADIUS := 180.0
const POUNCE_RADIUS := 36.0

enum State { IDLE, TELEGRAPH, REELING, LANDED, FINISHED }

var state: State = State.IDLE
var timer: float = 0.0
var human_hit: bool = false
var fish_snatched: bool = false
var dog_barked: bool = false
var dodged: bool = false
var threatened: bool = false
var triggered: bool = false

# Drawing colors matching Port & marine palette
const SHADOW := Color(0.04, 0.05, 0.08, 0.22)
const CAP_NAVY := Color(0.12, 0.20, 0.35)
const SWEATER_CREAM := Color(0.86, 0.86, 0.82)
const VEST_YELLOW := Color(0.92, 0.74, 0.16)
const PANTS_NAVY := Color(0.18, 0.24, 0.34)
const BOOTS_RUBBER := Color(0.70, 0.58, 0.20)
const SKIN_WEATHERED := Color(0.82, 0.64, 0.52)
const BEARD_GREY := Color(0.88, 0.88, 0.88)
const CRATE_WOOD := Color(0.56, 0.44, 0.30)
const CRATE_BAND := Color(0.28, 0.22, 0.16)
const ROD_CARBON := Color(0.22, 0.22, 0.24)
const ROD_GUIDE := Color(0.82, 0.84, 0.88)
const LINE_NYLON := Color(0.88, 0.94, 1.0, 0.75)
const BOBBER_RED := Color(0.90, 0.22, 0.18)
const BOBBER_WHITE := Color(0.96, 0.96, 0.96)
const BUCKET_METAL := Color(0.68, 0.70, 0.74)
const WATER_INNER := Color(0.16, 0.36, 0.52)
const TACKLE_RED := Color(0.76, 0.24, 0.20)
const FISH_SILVER := Color(0.84, 0.88, 0.94)
const FISH_BACK := Color(0.32, 0.46, 0.60)
const FISH_FIN := Color(0.24, 0.36, 0.48)
const SPRAY_FOAM := Color(0.88, 0.96, 1.0, 0.80)
const GULL_WHITE := Color(0.96, 0.96, 0.96)
const GULL_WING := Color(0.70, 0.74, 0.78)
const GULL_TIP := Color(0.14, 0.14, 0.16)
const GULL_BEAK := Color(0.96, 0.75, 0.15)


func reset() -> void:
	state = State.IDLE
	timer = 0.0
	human_hit = false
	fish_snatched = false
	dog_barked = false
	dodged = false
	threatened = false
	triggered = false


func tick(delta: float, dog_pos: Vector2, _dog_vel: Vector2, human_pos: Vector2) -> Dictionary:
	var out: Dictionary = {
		"warn": false,
		"reel": false,
		"line_snag": false,
		"fish_snatch": false,
		"dog_bark": false,
		"dodge": false,
	}

	match state:
		State.IDLE:
			# Trigger when approaching northward on outward walk
			if not triggered and (dog_pos.y < TRIGGER_Y or human_pos.y < TRIGGER_Y) and human_pos.y > FISHERMAN_POS.y:
				state = State.TELEGRAPH
				timer = WARN_DURATION
				triggered = true
				out["warn"] = true

		State.TELEGRAPH:
			timer -= delta
			if timer <= 0.0:
				state = State.REELING
				timer = REEL_DURATION
				out["reel"] = true

		State.REELING:
			timer -= delta

			# Check human hazard in quayside swing zone
			if not human_hit and human_pos.x > SWING_ZONE_X and absf(human_pos.y - FISHERMAN_POS.y) < SWING_RADIUS:
				human_hit = true
				out["line_snag"] = true

			if timer <= 0.0:
				state = State.LANDED
				timer = LANDED_DURATION

		State.LANDED:
			timer -= delta

			# Check dog pounce / snatch trick on the flapping fish
			if not fish_snatched and dog_pos.distance_to(FISH_LAND_POS) < POUNCE_RADIUS:
				fish_snatched = true
				out["fish_snatch"] = true

			if timer <= 0.0:
				state = State.FINISHED

		State.FINISHED:
			pass

	if state == State.REELING or state == State.LANDED or state == State.FINISHED:
		var close := state == State.REELING and human_pos.distance_to(FISHERMAN_POS) <= 110.0
		var step := NearMiss.consider(close, human_hit, threatened, dodged)
		threatened = bool(step["threatened"])
		if bool(step["dodge"]):
			dodged = true
			out["dodge"] = true

	return out


func on_bark(dog_pos: Vector2) -> bool:
	if (state == State.REELING or state == State.LANDED) and not dog_barked:
		if dog_pos.distance_to(FISHERMAN_POS) < BARK_RADIUS:
			dog_barked = true
			return true
	return false


func draw(b: ShapeBatch, vt: float, vb: float) -> void:
	if FISHERMAN_POS.y < vt - 150.0 or FISHERMAN_POS.y > vb + 150.0:
		return

	var t: float = AnimClock.msec() / 1000.0

	# 1. Ground props: wooden tackle crate stool, tackle box, bait bucket
	_draw_furniture(b)

	# 2. Old fisherman figure (seated on crate, facing water basin)
	_draw_fisherman(b, t)

	# 3. Fishing rod, line and bobber / catch
	_draw_tackle_and_fish(b, t)

	# 4. Wheeling gulls swooping during reel-in
	if (state == State.REELING or (state == State.LANDED and not dog_barked)):
		_draw_wheeling_gulls(b, t)


func _draw_furniture(b: ShapeBatch) -> void:
	# Wooden crate stool under fisherman
	var crate_rect := Rect2(FISHERMAN_POS.x - 12.0, FISHERMAN_POS.y - 10.0, 24.0, 20.0)
	b.rect(Rect2(crate_rect.position + Shade.light * 5.0, crate_rect.size), SHADOW)
	b.rect(crate_rect, CRATE_WOOD)
	b.rect(Rect2(crate_rect.position.x + 3.0, crate_rect.position.y, 2.5, crate_rect.size.y), CRATE_BAND)
	b.rect(Rect2(crate_rect.position.x + crate_rect.size.x - 5.5, crate_rect.position.y, 2.5, crate_rect.size.y), CRATE_BAND)

	# Tackle box on flagstones
	var tb_rect := Rect2(TACKLE_POS.x - 8.0, TACKLE_POS.y - 6.0, 16.0, 12.0)
	b.rect(Rect2(tb_rect.position + Shade.light * 4.0, tb_rect.size), SHADOW)
	b.rect(tb_rect, TACKLE_RED)
	b.rect(Rect2(tb_rect.position.x + 4.0, tb_rect.position.y - 2.0, 8.0, 2.0), ROD_CARBON)
	b.rect(Rect2(tb_rect.position.x + 2.0, tb_rect.position.y + 4.0, 12.0, 4.0), TACKLE_RED.darkened(0.2))

	# Bait bucket with water and sardine tails
	b.circle(BUCKET_POS + Shade.light * 4.0, 8.0, SHADOW)
	b.circle(BUCKET_POS, 7.5, BUCKET_METAL)
	b.circle(BUCKET_POS, 5.5, WATER_INNER)
	b.line(BUCKET_POS + Vector2(-6.0, 0.0), BUCKET_POS + Vector2(6.0, 0.0), BUCKET_METAL.lightened(0.2), 1.5)
	# Sardine tail sticking out
	b.line(BUCKET_POS + Vector2(1.0, 1.0), BUCKET_POS + Vector2(4.0, -4.0), FISH_SILVER, 2.2)
	b.circle(BUCKET_POS + Vector2(4.5, -4.5), 1.5, FISH_FIN)


func _draw_fisherman(b: ShapeBatch, t: float) -> void:
	var p: Vector2 = FISHERMAN_POS

	# Contact shadow
	b.circle(p + Shade.light * 6.0, 12.0, SHADOW)

	# Seated legs in dark navy trousers and rubber sea boots
	var boot_l := p + Vector2(10.0, -5.0)
	var boot_r := p + Vector2(10.0, 5.0)
	b.circle(boot_l, 4.2, BOOTS_RUBBER)
	b.circle(boot_r, 4.2, BOOTS_RUBBER)
	b.line(p + Vector2(2.0, -4.0), boot_l, PANTS_NAVY, 4.5)
	b.line(p + Vector2(2.0, 4.0), boot_r, PANTS_NAVY, 4.5)

	# Torso in cream knit sweater and yellow oilskin vest
	var body_pos := p + Vector2(-2.0, 0.0)
	if state == State.TELEGRAPH:
		# Straining back toward west
		body_pos.x -= 4.0 + sin(t * 36.0) * 0.8
	elif state == State.REELING:
		# Pumping torso while reeling
		body_pos.x -= 3.0 + sin(t * 16.0) * 1.5

	b.circle(body_pos, 9.5, SWEATER_CREAM)
	b.rect(Rect2(body_pos.x - 7.0, body_pos.y - 7.0, 14.0, 14.0), VEST_YELLOW)
	b.line(Vector2(body_pos.x, body_pos.y - 7.0), Vector2(body_pos.x, body_pos.y + 7.0), VEST_YELLOW.darkened(0.2), 1.5)

	# Head, weathered face, beard, navy watch cap
	var head_pos := body_pos + Vector2(1.0, 0.0)
	b.circle(head_pos, 6.0, SKIN_WEATHERED)
	# Full white/grey fisherman beard around chin and cheeks
	b.circle(head_pos + Vector2(3.0, 0.0), 4.2, BEARD_GREY)
	# Beanie cap
	b.circle(head_pos + Vector2(-1.5, 0.0), 5.5, CAP_NAVY)
	b.rect(Rect2(head_pos.x - 6.0, head_pos.y - 5.0, 3.5, 10.0), CAP_NAVY.lightened(0.15))

	# Arms holding rod
	var hand_pos := body_pos + Vector2(8.0, 0.0)
	if state == State.REELING:
		# Circular spinning motion for reeling hand
		var reel_angle := t * 24.0
		var reel_hand := hand_pos + Vector2(cos(reel_angle) * 3.5, sin(reel_angle) * 3.5)
		b.line(body_pos + Vector2(4.0, -3.0), hand_pos, SWEATER_CREAM, 3.2)
		b.line(body_pos + Vector2(4.0, 3.0), reel_hand, SWEATER_CREAM, 3.2)
		b.circle(hand_pos, 2.5, SKIN_WEATHERED)
		b.circle(reel_hand, 2.5, SKIN_WEATHERED)
	else:
		b.line(body_pos + Vector2(4.0, -3.0), hand_pos, SWEATER_CREAM, 3.2)
		b.line(body_pos + Vector2(4.0, 3.0), hand_pos, SWEATER_CREAM, 3.2)
		b.circle(hand_pos, 3.0, SKIN_WEATHERED)


func _draw_tackle_and_fish(b: ShapeBatch, t: float) -> void:
	var hand_pos := FISHERMAN_POS + Vector2(6.0, 0.0)
	if state == State.TELEGRAPH:
		hand_pos.x -= 4.0

	var rod_tip: Vector2
	var water_target := Vector2(WATER_SURFACE_X, FISHERMAN_POS.y)

	match state:
		State.IDLE:
			# Calm rod resting over the water, line dropping to floating bobber
			rod_tip = hand_pos + Vector2(50.0, 0.0)
			b.line(hand_pos, rod_tip, ROD_CARBON, 2.4)
			b.line(hand_pos + Vector2(20.0, 0.0), hand_pos + Vector2(20.0, -2.0), ROD_GUIDE, 1.2)
			b.line(hand_pos + Vector2(36.0, 0.0), hand_pos + Vector2(36.0, -2.0), ROD_GUIDE, 1.2)

			# Monofilament line to floating bobber
			var bobber_pos := water_target + Vector2(10.0, sin(t * 2.5) * 2.0)
			b.line(rod_tip, bobber_pos, LINE_NYLON, 1.0)
			# Bobber
			b.circle(bobber_pos, 3.2, BOBBER_WHITE)
			b.circle(bobber_pos + Vector2(-1.0, 0.0), 2.5, BOBBER_RED)
			# Subtle water rings around bobber
			var ripple_r := 4.0 + fmod(t * 3.0, 6.0)
			b.circle(bobber_pos, ripple_r, Color(0.42, 0.72, 0.88, 0.25))

		State.TELEGRAPH:
			# Straining curved rod bent down hard toward water with vibration
			var vib: float = sin(t * 40.0) * 2.2
			rod_tip = hand_pos + Vector2(56.0, 4.0 + vib)

			# Curved rod drawn as two segments
			var rod_mid := hand_pos + Vector2(28.0, -3.0)
			b.line(hand_pos, rod_mid, ROD_CARBON, 2.6)
			b.line(rod_mid, rod_tip, ROD_CARBON, 2.0)

			# Taut line diving into boiling water
			var churn_pos := water_target + Vector2(12.0, vib * 0.5)
			b.line(rod_tip, churn_pos, LINE_NYLON, 1.4)
			# Churning water spray / foam where the big fish is fighting the hook
			b.circle(churn_pos, 8.0 + sin(t * 20.0) * 2.0, SPRAY_FOAM)
			b.circle(churn_pos, 5.0, Color(0.42, 0.72, 0.88, 0.6))
			for di in range(4):
				var d_angle := float(di) * TAU / 4.0 + t * 6.0
				var dp := churn_pos + Vector2(cos(d_angle), sin(d_angle)) * (7.0 + fmod(t * 12.0 + float(di) * 2.0, 6.0))
				b.circle(dp, 1.8, SPRAY_FOAM)

		State.REELING:
			# High arched rod tip whipping overhead
			var arch_pump := sin(t * 18.0) * 4.0
			rod_tip = hand_pos + Vector2(30.0, -32.0 + arch_pump)
			var rod_mid := hand_pos + Vector2(16.0, -18.0)
			b.line(hand_pos, rod_mid, ROD_CARBON, 2.8)
			b.line(rod_mid, rod_tip, ROD_CARBON, 2.0)

			# Airborne arching sea bass flying from water onto quay
			var progress := 1.0 - clampf(timer / REEL_DURATION, 0.0, 1.0)
			var start_fish := water_target + Vector2(15.0, 0.0)
			var end_fish := FISH_LAND_POS

			# Parabolic flight trajectory with height arc
			var fish_x := lerpf(start_fish.x, end_fish.x, progress)
			var arc_height := sin(progress * PI) * 58.0
			var fish_y := lerpf(start_fish.y, end_fish.y, progress) - arc_height
			var fish_pos := Vector2(fish_x, fish_y)

			# Monofilament line from rod tip to fish mouth
			b.line(rod_tip, fish_pos, LINE_NYLON, 1.2)

			# Ground shadow underneath the airborne fish
			var shadow_pos := Vector2(fish_x, lerpf(start_fish.y, end_fish.y, progress)) + Shade.light * (arc_height * 0.35 + 4.0)
			var shadow_scale := 1.0 - clampf(arc_height / 100.0, 0.0, 0.5)
			b.circle(shadow_pos, 6.0 * shadow_scale, SHADOW)

			# Draw the airborne jumping sea bass
			_draw_fish_body(b, fish_pos, progress, t)

			# Trailing water droplet spray in the wake of the jumping fish
			for si in range(5):
				var s_prog := clampf(progress - float(si) * 0.06, 0.0, 1.0)
				var sx := lerpf(start_fish.x, end_fish.x, s_prog)
				var sy := lerpf(start_fish.y, end_fish.y, s_prog) - sin(s_prog * PI) * 58.0 + float(si % 2 * 4 - 2)
				b.circle(Vector2(sx, sy), 1.8, SPRAY_FOAM)

		State.LANDED, State.FINISHED:
			# Rod resting against coping or held upright
			rod_tip = hand_pos + Vector2(40.0, -12.0)
			b.line(hand_pos, rod_tip, ROD_CARBON, 2.2)

			# If the fish hasn't been snatched by the dog, it's flapping on the flagstones
			if not fish_snatched:
				b.line(rod_tip, FISH_LAND_POS, LINE_NYLON, 1.0)
				var flap := absf(sin(t * 14.0))
				var landed_pos := FISH_LAND_POS + Vector2(0.0, -flap * 3.5)
				# Wet contact shadow
				b.circle(FISH_LAND_POS + Shade.light * 3.0, 7.5, SHADOW)
				_draw_fish_body(b, landed_pos, 0.5, t)
				# Water splash rings on the flagstone
				b.circle(FISH_LAND_POS, 8.0 + flap * 2.0, Color(0.42, 0.72, 0.88, 0.3))
			else:
				# Fish was snatched! Sparkling star puffs
				var puff_pos := FISH_LAND_POS
				for pi in range(4):
					var p_angle := float(pi) * TAU / 4.0 + t * 4.0
					var pp := puff_pos + Vector2(cos(p_angle), sin(p_angle)) * (6.0 + fmod(t * 8.0 + float(pi) * 1.5, 6.0))
					b.circle(pp, 2.0, Color(1.0, 0.90, 0.35, 0.85))


func _draw_fish_body(b: ShapeBatch, p: Vector2, progress: float, t: float) -> void:
	# Curved crescent body of Mediterranean sea bass (Llobarro)
	var flap_tail := sin(t * 28.0) * 3.0
	var facing_dir := -1.0 # leaping leftward from water toward quay

	# Silvery belly / core
	b.circle(p, 5.5, FISH_SILVER)
	b.circle(p + Vector2(facing_dir * 5.0, 0.0), 4.2, FISH_SILVER)

	# Metallic dark blue-green back
	b.circle(p + Vector2(0.0, -1.8), 4.5, FISH_BACK)
	b.circle(p + Vector2(facing_dir * 4.0, -1.5), 3.2, FISH_BACK)

	# Spiny dorsal fin
	var fin_top := p + Vector2(0.0, -7.0)
	b.polygon(PackedVector2Array([
		p + Vector2(facing_dir * -3.0, -3.0),
		fin_top,
		p + Vector2(facing_dir * 3.0, -3.0)
	]), FISH_FIN)

	# Forked tail fin flapping
	var tail_root := p + Vector2(facing_dir * -7.0, flap_tail * 0.5)
	var tail_tip1 := tail_root + Vector2(facing_dir * -6.0, -4.0 + flap_tail)
	var tail_tip2 := tail_root + Vector2(facing_dir * -6.0, 4.0 + flap_tail)
	b.polygon(PackedVector2Array([tail_root, tail_tip1, tail_tip2]), FISH_FIN)

	# Head and eye
	var head_p := p + Vector2(facing_dir * 8.0, 0.5)
	b.circle(head_p, 3.2, FISH_SILVER)
	b.circle(head_p + Vector2(facing_dir * 1.0, -1.0), 1.2, Color(0.12, 0.12, 0.14))
	b.circle(head_p + Vector2(facing_dir * 0.8, -1.2), 0.5, Color.WHITE)


func _draw_wheeling_gulls(b: ShapeBatch, t: float) -> void:
	# 2 swooping harbor seagulls attracted by the thrashing sea bass
	for gi in range(2):
		var g_angle := t * 3.0 + float(gi) * PI
		var g_rad := 34.0 + sin(t * 2.0 + float(gi)) * 8.0
		var gull_pos := FISH_LAND_POS + Vector2(cos(g_angle) * g_rad * 1.2, sin(g_angle) * g_rad * 0.7 - 24.0)

		# Ground shadow
		var shadow_pos := Vector2(gull_pos.x, FISH_LAND_POS.y) + Shade.light * 16.0
		b.circle(shadow_pos, 4.0, SHADOW)

		# Flying gull body
		var fly_dir := Vector2(-sin(g_angle), cos(g_angle) * 0.6).normalized()
		var side := fly_dir.orthogonal()
		var flap := sin(t * 22.0 + float(gi) * 2.5)

		for sd: float in [-1.0, 1.0]:
			var root := gull_pos + side * sd * 2.5
			var tip := gull_pos + side * sd * (10.0 + flap * 3.5) - fly_dir * (2.0 + flap)
			b.polygon(PackedVector2Array([root + fly_dir * 3.0, tip, root - fly_dir * 3.0]), GULL_WING)
			b.polygon(PackedVector2Array([tip, tip.lerp(root + fly_dir * 3.0, 0.35), tip.lerp(root - fly_dir * 3.0, 0.35)]), GULL_TIP)

		b.circle(gull_pos, 4.2, GULL_WHITE)
		b.circle(gull_pos + fly_dir * 4.5, 2.5, GULL_WHITE)
		b.line(gull_pos + fly_dir * 5.5, gull_pos + fly_dir * 8.5, GULL_BEAK, 1.6)
