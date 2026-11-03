class_name Jackhammer
extends RefCounted

# WALK 11: LES OBRES - PNEUMATIC JACKHAMMER CREW
# Signature live event for Les Obres roadworks: a construction worker operating
# a pneumatic pavement breaker / jackhammer connected to an air compressor.
#
# Gameplay contract:
# - 0.8 s warning telegraph: as the pair approaches outward bound (y ≈ -2320.0),
#   the worker revs the compressor, raises a hand and shouts "Atenció, piconadora!".
# - Hazard: walking into the noisy vibration rattle zone startles the human
#   (covers ears, stumbles, patience loss, "Too loud!").
# - Dog tricks: barking at the drill awards "jackhammer bark! +2".
#   Dashing through the detour lane beside the cones awards "smooth detour! +2".
# - Dodge: guiding the human along the quiet far side (x < 660.0) earns
#   "quiet detour! +2" / "Whew, nice save!".
# - Autowalk: central footway path (x ≈ 680.0..690.0) remains completely clear.
# - Zero new draw calls: batched into ShapeBatch.

const ShapeBatch := preload("res://systems/shape_batch.gd")

const PIT_POS := Vector2(830.0, -2550.0)
const WORKER_POS := Vector2(830.0, -2532.0)
const COMPRESSOR_POS := Vector2(884.0, -2518.0)
const TRIGGER_Y := -2320.0
const WARN_DURATION := 0.8
const DRILL_DURATION := 1.4
const RATTLE_RADIUS := 52.0
const BARK_RADIUS := 90.0

enum State { IDLE, TELEGRAPH, DRILLING, FINISHED }

var state: State = State.IDLE
var timer: float = 0.0
var human_hit: bool = false
var dog_splashed: bool = false
var dog_barked: bool = false
var dodged: bool = false
var triggered: bool = false

# Colors
const HIVIS_ORANGE := Color(0.96, 0.48, 0.10)
const REFLECT_SILVER := Color(0.90, 0.92, 0.88)
const HARDHAT_YELLOW := Color(0.98, 0.86, 0.18)
const EAR_DEFENDER := Color(0.12, 0.12, 0.14)
const SKIN := Color(0.85, 0.68, 0.54)
const WORK_PANTS := Color(0.22, 0.32, 0.46)
const STEEL_DRILL := Color(0.68, 0.70, 0.72)
const RUBBER_BLACK := Color(0.16, 0.16, 0.18)
const HOSE_YELLOW := Color(0.92, 0.78, 0.16)
const COMPRESSOR_BODY := Color(0.86, 0.42, 0.14)
const ASPHALT_CUT := Color(0.24, 0.24, 0.26)
const RUBBLE_STONE := Color(0.48, 0.46, 0.44)
const DUST_WHITE := Color(0.88, 0.86, 0.82, 0.40)


func reset() -> void:
	state = State.IDLE
	timer = 0.0
	human_hit = false
	dog_splashed = false
	dog_barked = false
	dodged = false
	triggered = false


func tick(delta: float, dog_pos: Vector2, dog_vel: Vector2, human_pos: Vector2) -> Dictionary:
	var out: Dictionary = {
		"warn": false,
		"drill": false,
		"rattle": false,
		"dog_detour": false,
		"dog_bark": false,
		"dodge": false,
	}

	match state:
		State.IDLE:
			if not triggered and (dog_pos.y < TRIGGER_Y or human_pos.y < TRIGGER_Y) and human_pos.y > PIT_POS.y:
				state = State.TELEGRAPH
				timer = WARN_DURATION
				triggered = true
				out["warn"] = true

		State.TELEGRAPH:
			timer -= delta
			if timer <= 0.0:
				state = State.DRILLING
				timer = DRILL_DURATION
				out["drill"] = true

		State.DRILLING:
			timer -= delta

			# Check human in deafening rattle zone
			if not human_hit and human_pos.distance_to(PIT_POS) < RATTLE_RADIUS:
				human_hit = true
				out["rattle"] = true

			# Check fast dog dashing through detour lane beside the cones
			if not dog_splashed and dog_pos.x > 640.0 and dog_pos.x < 770.0 and absf(dog_pos.y - PIT_POS.y) < 40.0:
				if dog_vel.length() > 90.0:
					dog_splashed = true
					out["dog_detour"] = true

			# Check quiet detour: human guided safely past along quiet side (x < 660.0)
			if not dodged and not human_hit:
				if human_pos.y < PIT_POS.y + 20.0 and human_pos.y > PIT_POS.y - 50.0:
					if human_pos.x < 670.0:
						dodged = true
						out["dodge"] = true

			if timer <= 0.0:
				state = State.FINISHED

		State.FINISHED:
			pass

	return out


func on_bark(dog_pos: Vector2) -> bool:
	if state == State.DRILLING and not dog_barked:
		if dog_pos.distance_to(PIT_POS) < BARK_RADIUS:
			dog_barked = true
			return true
	return false


func draw(b: ShapeBatch, vt: float, vb: float) -> void:
	if PIT_POS.y < vt - 120.0 or PIT_POS.y > vb + 120.0:
		return

	var t: float = AnimClock.msec() / 1000.0

	# 1. Ground: asphalt cutout excavation pit and warning cones
	_draw_pit(b)

	# 2. Air compressor and flexible hose
	_draw_compressor(b, t)

	# 3. Worker and jackhammer
	_draw_worker_and_tool(b, t)

	# 4. Drilling effects: dust clouds, flying sparks, vibration wave
	if state == State.DRILLING:
		_draw_drilling_effects(b, t)


func _draw_pit(b: ShapeBatch) -> void:
	# Excavation cutout rectangle in pavement
	var pit_rect := Rect2(PIT_POS.x - 16.0, PIT_POS.y - 14.0, 32.0, 28.0)
	b.rect(pit_rect, ASPHALT_CUT)
	b.rect(pit_rect.grow(-3.0), ASPHALT_CUT.darkened(0.2))

	# Loose rubble stones around edges
	for i in range(5):
		var stone_pos: Vector2 = PIT_POS + Vector2(sin(float(i) * 2.3) * 14.0, cos(float(i) * 1.8) * 12.0)
		b.circle(stone_pos, 2.8, RUBBLE_STONE)

	# Safety cones at corners flanking the pit
	for cy: float in [PIT_POS.y - 18.0, PIT_POS.y + 18.0]:
		var cone_pos := Vector2(PIT_POS.x - 20.0, cy)
		b.circle(cone_pos + Vector2(1.5, 2.5), 6.5, Color(0, 0, 0, 0.25))
		b.circle(cone_pos, 5.5, HIVIS_ORANGE)
		b.circle(cone_pos, 3.2, REFLECT_SILVER)
		b.circle(cone_pos, 1.4, HIVIS_ORANGE)


func _draw_compressor(b: ShapeBatch, t: float) -> void:
	var cp: Vector2 = COMPRESSOR_POS
	# Vibration when running
	var vib: Vector2 = Vector2.ZERO
	if state == State.TELEGRAPH or state == State.DRILLING:
		vib = Vector2(sin(t * 30.0) * 0.8, cos(t * 26.0) * 0.6)

	# Shadow
	b.rect(Rect2(cp.x - 12.0 + 3.0, cp.y - 10.0 + 4.0, 24.0, 20.0), Color(0.04, 0.05, 0.08, 0.25))
	# Body
	var body_rect := Rect2(cp.x - 12.0 + vib.x, cp.y - 10.0 + vib.y, 24.0, 20.0)
	b.rect(body_rect, COMPRESSOR_BODY)
	b.rect(body_rect.grow(-2.0), COMPRESSOR_BODY.lightened(0.15))

	# Grate lines on engine deck
	for k in range(3):
		var ly: float = body_rect.position.y + 4.0 + float(k) * 4.0
		b.line(Vector2(body_rect.position.x + 3.0, ly), Vector2(body_rect.position.x + 11.0, ly), Color(0.2, 0.2, 0.22), 1.5)

	# Pressure gauge
	b.circle(cp + vib + Vector2(6.0, -3.0), 2.5, Color(0.95, 0.95, 0.92))
	b.line(cp + vib + Vector2(6.0, -3.0), cp + vib + Vector2(7.5, -4.5), Color(0.85, 0.15, 0.15), 1.0)

	# Air hose snaking from compressor to jackhammer
	var tool_top: Vector2 = PIT_POS + Vector2(0.0, 2.0)
	var mid_p1: Vector2 = cp.lerp(tool_top, 0.35) + Vector2(4.0, 8.0)
	var mid_p2: Vector2 = cp.lerp(tool_top, 0.70) + Vector2(-6.0, 6.0)
	b.line(cp + Vector2(-10.0, 4.0), mid_p1, HOSE_YELLOW, 2.2)
	b.line(mid_p1, mid_p2, HOSE_YELLOW, 2.2)
	b.line(mid_p2, tool_top + Vector2(2.0, 4.0), HOSE_YELLOW, 2.2)


func _draw_worker_and_tool(b: ShapeBatch, t: float) -> void:
	var wp: Vector2 = WORKER_POS
	var tool_pos: Vector2 = PIT_POS

	# High-frequency vertical tremor during drilling
	var tremor := 0.0
	if state == State.DRILLING:
		tremor = sin(t * 50.0) * 1.8

	# Worker contact shadow
	b.circle(wp + Vector2(2.0, 4.0), 9.0, Color(0.04, 0.05, 0.08, 0.25))

	# Worker body & hi-vis vest
	var body_p: Vector2 = wp + Vector2(0.0, tremor * 0.5)
	b.circle(body_p, 8.5, HIVIS_ORANGE)
	# Reflective stripes across vest
	b.line(body_p + Vector2(-6.0, -2.0), body_p + Vector2(6.0, -2.0), REFLECT_SILVER, 2.0)
	b.line(body_p + Vector2(-5.0, 2.0), body_p + Vector2(5.0, 2.0), REFLECT_SILVER, 1.8)

	# Arms gripping T-bar handle
	var arm_l: Vector2 = body_p + Vector2(-7.0, -2.0)
	var arm_r: Vector2 = body_p + Vector2(7.0, -2.0)
	var handle_l: Vector2 = tool_pos + Vector2(-8.0, 4.0 + tremor)
	var handle_r: Vector2 = tool_pos + Vector2(8.0, 4.0 + tremor)

	if state == State.TELEGRAPH:
		# One hand raised in warning gesture
		b.line(arm_l, body_p + Vector2(-12.0, -10.0), HIVIS_ORANGE.darkened(0.15), 3.0)
		b.circle(body_p + Vector2(-12.0, -10.0), 2.5, SKIN)
		b.line(arm_r, handle_r, HIVIS_ORANGE.darkened(0.15), 3.0)
	else:
		# Both hands gripping handle
		b.line(arm_l, handle_l, HIVIS_ORANGE.darkened(0.15), 3.0)
		b.circle(handle_l, 2.2, SKIN)
		b.line(arm_r, handle_r, HIVIS_ORANGE.darkened(0.15), 3.0)
		b.circle(handle_r, 2.2, SKIN)

	# Head, hardhat, and black ear defenders
	var head_p: Vector2 = body_p + Vector2(0.0, -2.0)
	b.circle(head_p, 5.0, SKIN)
	# Hardhat
	b.circle(head_p + Vector2(0.0, -1.5), 5.5, HARDHAT_YELLOW)
	b.line(head_p + Vector2(-5.5, -1.0), head_p + Vector2(5.5, -1.0), HARDHAT_YELLOW.lightened(0.2), 2.0)
	# Ear defenders
	b.circle(head_p + Vector2(-5.0, -0.5), 2.2, EAR_DEFENDER)
	b.circle(head_p + Vector2(5.0, -0.5), 2.2, EAR_DEFENDER)
	b.line(head_p + Vector2(-4.5, -4.5), head_p + Vector2(4.5, -4.5), EAR_DEFENDER, 1.5)

	# The Jackhammer tool: T-bar handle, cylinder body, and steel chisel bit
	var tp: Vector2 = tool_pos + Vector2(0.0, tremor)
	# T-handle
	b.line(tp + Vector2(-9.0, 4.0), tp + Vector2(9.0, 4.0), RUBBER_BLACK, 3.0)
	# Tool cylinder body
	b.rect(Rect2(tp.x - 3.5, tp.y - 4.0, 7.0, 10.0), STEEL_DRILL.darkened(0.15))
	b.rect(Rect2(tp.x - 2.5, tp.y - 3.0, 5.0, 8.0), STEEL_DRILL)
	# Hex collar
	b.rect(Rect2(tp.x - 3.0, tp.y - 7.0, 6.0, 3.5), RUBBER_BLACK)
	# Chisel pointed into asphalt
	b.line(tp + Vector2(0.0, -6.0), tp + Vector2(0.0, -12.0), STEEL_DRILL.lightened(0.2), 2.5)


func _draw_drilling_effects(b: ShapeBatch, t: float) -> void:
	# 1. Pavement vibration shockwave ring
	var v_phase: float = fmod(t * 4.0, 1.0)
	var v_radius: float = 12.0 + v_phase * (RATTLE_RADIUS - 12.0)
	var v_alpha: float = (1.0 - v_phase) * 0.35
	b.circle(PIT_POS, v_radius, Color(0.90, 0.88, 0.82, v_alpha))

	# 2. Billowing dust clouds at chisel point
	for di in range(4):
		var d_ph: float = fmod(t * 3.5 + float(di) * 0.25, 1.0)
		var d_radius: float = 4.0 + d_ph * 14.0
		var d_alpha: float = (1.0 - d_ph) * 0.40
		var d_off := Vector2(sin(float(di) * 2.2 + t * 4.0) * 8.0, -8.0 - d_ph * 10.0)
		b.circle(PIT_POS + d_off, d_radius, Color(DUST_WHITE.r, DUST_WHITE.g, DUST_WHITE.b, d_alpha))

	# 3. Flying sparks and stone chips
	for si in range(5):
		var s_ang: float = float(si) * TAU / 5.0 + t * 6.0
		var s_dist: float = 6.0 + fmod(t * 30.0 + float(si) * 5.0, 16.0)
		var sp: Vector2 = PIT_POS + Vector2(cos(s_ang) * s_dist, sin(s_ang) * s_dist * 0.7)
		b.circle(sp, 1.4, Color(0.96, 0.90, 0.60, 0.8))
