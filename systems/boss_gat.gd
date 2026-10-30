class_name BossGat
extends RefCounted

# WALK 26: RAMBLA DEL RAVAL (The Grand Finale — El Gat de Botero Boss Arena)
#
# The wide pedestrian promenade of Rambla del Raval in Barcelona, flanked by
# date palms, panots paving, café terraces, and a central circular plaza where
# Fernando Botero's colossal bronze cat sculpture ("El Gat de Botero") sits.
#
# A 3-phase boss encounter:
# - Phase 1: The Prowl (Navigation & Dodging)
#   El Gat stalks down the promenade, swatting massive bronze paws (radius 42px)
#   with telegraphed dust rings. Pigeons scatter dynamically.
# - Phase 2: The AT-AT Leash Tangle (Core Mechanics Climax)
#   El Gat pauses in the circular plaza at y = -4600. Its four cylindrical bronze
#   legs act as active verlet collision poles in the rope solver. The player dog
#   orbits the legs while the human holds anchor. Completing 3 full wrap coils
#   trips the giant statue onto its side with a colossal metallic CLANG!
# - Phase 3: The Belly Boop & Victory
#   El Gat is toppled on the plaza panots. A golden yarn prize rolls out. The player
#   runs up its round belly to its snout and presses BARK for the "Super Boop".
#   El Gat purrs contentedly, settles back onto its pedestal as a static bronze
#   monument, patrons cheer, and the walk finishes with a 3-star milestone reward.

const Clay := preload("res://entities/clay.gd")
const ShapeBatch := preload("res://systems/shape_batch.gd")
const Surfaces := preload("res://world/surfaces.gd")
const EventFeed := preload("res://hud/event_feed.gd")
const Goals := preload("res://systems/goals.gd")

const LIGHT := Vector2(0.5, 0.866)
const SHADOW := Color(0.04, 0.05, 0.08, 0.24)

# --- Colors ------------------------------------------------------------------
const BRONZE_BASE := Color(0.25, 0.21, 0.18)
const BRONZE_DARK := Color(0.15, 0.12, 0.10)
const BRONZE_LIT := Color(0.38, 0.32, 0.26)
const BRONZE_SPEC := Color(0.60, 0.50, 0.38, 0.40)
const EYE_AMBER := Color(0.96, 0.78, 0.18)
const EYE_PUPIL := Color(0.12, 0.08, 0.06)
const NOSE_DARK := Color(0.20, 0.15, 0.14)
const WHISKER_WIRE := Color(0.70, 0.64, 0.54)

const STONE_PLAZA := Color(0.74, 0.72, 0.68)
const STONE_DARK := Color(0.56, 0.54, 0.50)
const BAND_TERRACOTTA := Color(0.68, 0.38, 0.28)
const BAND_CREAM := Color(0.86, 0.84, 0.78)
const PANOT_TILE := Color(0.66, 0.64, 0.60)
const PANOT_LINE := Color(0.48, 0.46, 0.42)
const PALM_TRUNK := Color(0.46, 0.35, 0.25)
const PALM_BARK := Color(0.36, 0.26, 0.18)
const PALM_LEAF := Color(0.20, 0.48, 0.24)
const PALM_LEAF_LIGHT := Color(0.34, 0.64, 0.30)
const DUST_COLOR := Color(0.85, 0.78, 0.65, 0.50)
const YARN_GOLD := Color(0.98, 0.82, 0.28)
const YARN_DARK := Color(0.75, 0.55, 0.15)

# --- Dimensions & Layout -----------------------------------------------------
const HALF := 320.0
const CORRIDOR_L := 320.0
const CORRIDOR_R := 960.0
const PEDESTAL_POS := Vector2(640.0, -4600.0)
const PLAZA_R := 220.0

const LEG_OFFSET_X := 36.0
const LEG_OFFSET_Y := 32.0
const LEG_RADIUS := 18.0
const SWAT_RADIUS := 42.0

const PRIZE := Vector2(730.0, -4520.0)
const PRIZE_TEXT := "snatch the giant golden yarn from the overturned kiosk"

# --- State Machine -----------------------------------------------------------
enum State {
	IDLE,
	PROWL,
	SWAT,
	ROAR,
	WRAPPED,
	TOPPLED,
	PURR,
}

var state: State = State.IDLE
var state_t: float = 0.0

var main: Node2D = null
var pos: Vector2 = Vector2(640.0, -450.0)
var face_dir := Vector2.DOWN
var cur_speed := 95.0

var leg_poles: Array[Vector2] = []
var leg_indices: Array[int] = []

var swat_pos := Vector2.ZERO
var swat_telegraph := 0.0
var swat_cooldown := 3.2
var swat_paw_active := 0 # 0 left, 1 right

var wrap_coils := 0.0
var prev_coil_milestone := 0
var last_dog_angle := 0.0
var orbit_accum_angle := 0.0

var snout_pos := Vector2.ZERO
var purr_vibe := 0.0
var topple_angle := 0.0

var dust_rings: Array[Dictionary] = []
var confetti: Array[Dictionary] = []

# --- Authoring Data ----------------------------------------------------------
const PALMS: Array[Vector2] = [
	Vector2(400.0, 100.0), Vector2(880.0, 100.0),
	Vector2(400.0, -300.0), Vector2(880.0, -300.0),
	Vector2(400.0, -700.0), Vector2(880.0, -700.0),
	Vector2(400.0, -1100.0), Vector2(880.0, -1100.0),
	Vector2(400.0, -1500.0), Vector2(880.0, -1500.0),
	Vector2(400.0, -1900.0), Vector2(880.0, -1900.0),
	Vector2(400.0, -2300.0), Vector2(880.0, -2300.0),
	Vector2(400.0, -2700.0), Vector2(880.0, -2700.0),
	Vector2(400.0, -3100.0), Vector2(880.0, -3100.0),
	Vector2(400.0, -3500.0), Vector2(880.0, -3500.0),
	Vector2(400.0, -3900.0), Vector2(880.0, -3900.0),
	Vector2(400.0, -4300.0), Vector2(880.0, -4300.0),
	# Ring of palms around the circular plaza
	Vector2(440.0, -4600.0), Vector2(840.0, -4600.0),
	Vector2(500.0, -4740.0), Vector2(780.0, -4740.0),
	Vector2(500.0, -4460.0), Vector2(780.0, -4460.0),
]

const TERRACES: Array[Rect2] = [
	Rect2(340.0, -1250.0, 75.0, 150.0),
	Rect2(865.0, -1250.0, 75.0, 150.0),
	Rect2(340.0, -2450.0, 75.0, 150.0),
	Rect2(865.0, -2450.0, 75.0, 150.0),
	Rect2(340.0, -3650.0, 75.0, 150.0),
	Rect2(865.0, -3650.0, 75.0, 150.0),
]

const BENCHES: Array[Vector2] = [
	Vector2(530.0, -900.0), Vector2(750.0, -900.0),
	Vector2(530.0, -2100.0), Vector2(750.0, -2100.0),
	Vector2(530.0, -3300.0), Vector2(750.0, -3300.0),
]

const PIGEON_SPOTS: Array[Vector2] = [
	Vector2(640.0, -800.0),
	Vector2(540.0, -1600.0),
	Vector2(740.0, -2500.0),
	Vector2(580.0, -3400.0),
	Vector2(640.0, -4300.0),
]

# --- Static Level Building API -----------------------------------------------

static func edge_nodes(m: Node2D) -> Array:
	return [
		{"y": m.START_Y, "cx": 640.0, "half": 320.0},
		{"y": -800.0, "cx": 640.0, "half": 320.0},
		{"y": -1800.0, "cx": 640.0, "half": 320.0},
		{"y": -3000.0, "cx": 640.0, "half": 320.0},
		{"y": -4200.0, "cx": 640.0, "half": 320.0},
		{"y": -4600.0, "cx": 640.0, "half": 360.0}, # circular arena plaza
		{"y": -4800.0, "cx": 640.0, "half": 340.0},
		{"y": m.GATE_Y + 120.0, "cx": 640.0, "half": 320.0},
		{"y": m.GATE_Y, "cx": 640.0, "half": 320.0},
	]


static func wrap_rects() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for t in TERRACES:
		out.append(t)
	# Overturned kiosk near the arena
	out.append(Rect2(705.0, -4490.0, 50.0, 44.0))
	return out


static func solids(_m: Node2D) -> Array[Rect2]:
	var out: Array[Rect2] = []
	for t in TERRACES:
		out.append(t)
	# Stone pedestal collision footprint at the plaza
	out.append(Rect2(PEDESTAL_POS.x - 55.0, PEDESTAL_POS.y - 40.0, 110.0, 80.0))
	out.append(Rect2(705.0, -4490.0, 50.0, 44.0))
	return out


static func setup_poles(m: Node2D) -> void:
	for p in PALMS:
		m.poles.append(p)


static func build(m: Node2D) -> Array:
	m.gate_text = "RAMBLA DEL RAVAL"
	m.stalls.clear()
	m.stall_kinds.clear()
	m.astands = Array([], TYPE_VECTOR2, &"", null)
	m.manholes = Array([], TYPE_VECTOR2, &"", null)
	m.fountains = Array([Vector2(450.0, -1800.0)], TYPE_VECTOR2, &"", null)
	m.benches = Array(BENCHES, TYPE_VECTOR2, &"", null)
	m.bins = Array([
		Vector2(360.0, -1400.0),
		Vector2(920.0, -1400.0),
		Vector2(360.0, -3200.0),
		Vector2(920.0, -3200.0),
	], TYPE_VECTOR2, &"", null)

	# Steer owner around central plaza pedestal
	m.islands = Array([{
		"rect": Rect2(PEDESTAL_POS.x - 70.0, PEDESTAL_POS.y - 50.0, 140.0, 100.0),
		"side": 1.0,
		"lead": 160.0
	}], TYPE_DICTIONARY, &"", null)

	setup_poles(m)

	# Instantiate and wire the boss state machine
	var gat := BossGat.new()
	gat.setup(m)
	m.set("boss_gat", gat)
	m.set("gat_toppled", false)
	m.set("gat_booped", false)
	m.set("gat_swats_dodged", 0)
	m.set("raval_pigeons_scattered", 0)

	# Hydrants / sniff landmarks
	var marks: Array[Vector2] = [
		Vector2(640.0, -450.0), # initial statue plinth
		Vector2(450.0, -1800.0), # ornate iron fountain
		Vector2(730.0, -4460.0), # kiosk
		Vector2(400.0, -1100.0), # palm grate
		Vector2(880.0, -3100.0), # palm grate
	]

	# Dropped tapas / croquetes snacks from terraces
	var snacks: Array[Vector2] = [
		Vector2(430.0, -1280.0),
		Vector2(850.0, -2480.0),
		Vector2(440.0, -3680.0),
		Vector2(680.0, -4420.0),
	]

	return [marks, snacks]


# --- Instance Boss Methods ---------------------------------------------------

func setup(m_ref: Node2D) -> void:
	main = m_ref
	state = State.IDLE
	pos = Vector2(640.0, -480.0)
	face_dir = Vector2.DOWN
	wrap_coils = 0.0
	orbit_accum_angle = 0.0
	prev_coil_milestone = 0
	dust_rings.clear()
	confetti.clear()

	# Register the 4 cylindrical bronze legs into main.poles
	leg_indices.clear()
	leg_poles.clear()
	for offset in [
		Vector2(-LEG_OFFSET_X, -LEG_OFFSET_Y),
		Vector2(LEG_OFFSET_X, -LEG_OFFSET_Y),
		Vector2(-LEG_OFFSET_X, LEG_OFFSET_Y),
		Vector2(LEG_OFFSET_X, LEG_OFFSET_Y)
	]:
		var lp: Vector2 = pos + offset
		leg_indices.append(main.poles.size())
		main.poles.append(lp)
		leg_poles.append(lp)


func update_leg_positions() -> void:
	if leg_indices.size() != 4 or leg_poles.size() != 4:
		return
	var offsets := [
		Vector2(-LEG_OFFSET_X, -LEG_OFFSET_Y),
		Vector2(LEG_OFFSET_X, -LEG_OFFSET_Y),
		Vector2(-LEG_OFFSET_X, LEG_OFFSET_Y),
		Vector2(LEG_OFFSET_X, LEG_OFFSET_Y)
	]
	for k in range(4):
		var target: Vector2 = pos + offsets[k]
		leg_poles[k] = target
		var idx: int = leg_indices[k]
		if idx >= 0 and idx < main.poles.size():
			main.poles[idx] = target


func transition_to(new_state: State) -> void:
	state = new_state
	state_t = 0.0
	match new_state:
		State.PROWL:
			state_t = 0.0
			cur_speed = 95.0
			if main != null and main.human != null:
				main.human.notice("Huh, big cat today...", 2.2)
		State.SWAT:
			state_t = 0.8 # telegraph window
			trigger_swat()
		State.ROAR:
			state_t = 2.4
			pos = PEDESTAL_POS
			update_leg_positions()
			Sfx.play("roar", 0.9, 3.0)
			if main != null:
				main.shake_t = maxf(float(main.shake_t), 0.6)
				if main.human != null:
					main.human.halt(999.0) # hold center anchor in plaza
					main.human.notice("Is that... moving?!", 2.5)
		State.WRAPPED:
			state_t = 0.85
			Sfx.play("intro_taut", 0.9, 2.0)
			Sfx.play("groan", 1.1, 2.0)
			if main != null:
				main.shake_t = maxf(float(main.shake_t), 0.8)
				main.set_leash_target(main.leash_len * 0.65, true)
		State.TOPPLED:
			state_t = 0.0
			topple_angle = PI * 0.5
			snout_pos = pos + Vector2(-54.0, -18.0)
			Sfx.play("crack", 0.6, 4.0)
			Sfx.play("bell", 0.5, 6.0)
			if main != null:
				main.set("gat_toppled", true)
				main.shake_t = 1.4
				main.feed.say("EL GAT HAS TOPPLED!", EventFeed.Tone.LOUD)
				# Spawn massive dust explosion rings
				for d_rad in [40.0, 90.0, 150.0]:
					dust_rings.append({"pos": pos, "r": d_rad, "life": 0.8, "max_life": 0.8})
				# Reveal the prize from overturned kiosk
				main.prize_pos = PRIZE
				main.prize_text = PRIZE_TEXT
		State.PURR:
			state_t = 3.5
			topple_angle = 0.0
			pos = PEDESTAL_POS
			update_leg_positions()
			Sfx.play("star", 1.1)
			if main != null:
				main.set("gat_booped", true)
				main.feed.say("THE RAMBLA IS SAVED!", EventFeed.Tone.GOOD)
				if main.human != null:
					main.human.notice("Nice kitty.", 3.2)
					main.human.say_line("Nice kitty.")
				# Confetti burst
				for i in range(50):
					var ang := TAU * float(i) / 50.0
					var spd := randf_range(80.0, 240.0)
					var col: Color = [Color(0.96, 0.35, 0.30), Color(0.95, 0.80, 0.25), Color(0.25, 0.65, 0.95), Color(0.35, 0.85, 0.40)][i % 4]
					confetti.append({"pos": pos, "vel": Vector2(cos(ang), sin(ang)) * spd, "col": col, "life": 3.0})


func trigger_swat() -> void:
	swat_paw_active = 0 if swat_paw_active == 1 else 1
	var side_x := 46.0 if swat_paw_active == 1 else -46.0
	swat_pos = pos + Vector2(side_x, 60.0)
	swat_telegraph = 0.8
	dust_rings.append({"pos": swat_pos, "r": SWAT_RADIUS, "life": 0.8, "max_life": 0.8})


func execute_swat() -> void:
	Sfx.play("crack", 0.8, 1.0)
	if main == null:
		return
	main.shake_t = maxf(float(main.shake_t), 0.4)
	# Check dog impact or dodge
	var dog_p: Vector2 = main.dog.global_position
	var d_dist: float = dog_p.distance_to(swat_pos)
	if d_dist <= SWAT_RADIUS:
		var dir: Vector2 = (dog_p - swat_pos).normalized() if d_dist > 1.0 else Vector2.DOWN
		main.dog.knocked(dir * 220.0, "paw")
		main.on_dog_hit("paw")
	elif d_dist < 100.0:
		main.gat_swats_dodged += 1
		main.combo.add("DODGE", 2)
		main.float_text(swat_pos, "dodged! +2", Color(0.8, 1.0, 0.7))

	# Check human impact
	if main.human != null and main.human.global_position.distance_to(swat_pos) <= SWAT_RADIUS:
		var hdir: Vector2 = (main.human.global_position - swat_pos).normalized()
		main.human.bumped(hdir * 180.0)

	# Dynamic pigeon scatter
	for p in main.get_tree().get_nodes_in_group("pigeons"):
		if p.global_position.distance_to(swat_pos) < 180.0:
			p.scare()
			main.raval_pigeons_scattered += 1


func update_cable_wrap(_delta: float) -> void:
	if state != State.ROAR:
		return
	if main == null or main.leash == null or main.dog == null:
		return

	# 1. Check active contacts on El Gat's leg poles
	var leg_contacts := 0
	if main.leash._touch.size() == main.leash.N:
		for i in range(main.leash.N):
			var oi: int = main.leash._touch[i]
			if oi >= 0 and oi < main.leash._obs_pos.size():
				var obs_p: Vector2 = main.leash._obs_pos[oi]
				for leg in leg_poles:
					if obs_p.distance_squared_to(leg) < 4.0:
						leg_contacts += 1
						break

	# 2. Track dog angular orbit around El Gat's center
	var to_dog: Vector2 = main.dog.global_position - pos
	var cur_angle := to_dog.angle()
	var d_ang := wrapf(cur_angle - last_dog_angle, -PI, PI)
	last_dog_angle = cur_angle

	var orbit_r := to_dog.length()
	if orbit_r > 38.0 and orbit_r < 240.0 and leg_contacts > 0:
		orbit_accum_angle += d_ang

	# 3. Geometric winding of verlet rope points around pos
	var rope_pts: PackedVector2Array = PackedVector2Array(main.leash.pts)
	var geom_rads: float = main.leash.pole_winding(rope_pts, pos, 120.0)
	var geom_turns := absf(geom_rads) / TAU

	var accum_turns := absf(orbit_accum_angle) / TAU
	wrap_coils = maxf(accum_turns, geom_turns)

	# Milestones and feedback
	if wrap_coils >= 1.0 and prev_coil_milestone < 1:
		prev_coil_milestone = 1
		main.feed.say("AT-AT CABLE: 1 COIL!", EventFeed.Tone.LOUD)
		Sfx.play("save", 1.0)
	elif wrap_coils >= 2.0 and prev_coil_milestone < 2:
		prev_coil_milestone = 2
		main.feed.say("AT-AT CABLE: 2 COILS!", EventFeed.Tone.LOUD)
		Sfx.play("save", 1.2)
	elif wrap_coils >= 3.0 and prev_coil_milestone < 3:
		prev_coil_milestone = 3
		main.feed.say("AT-AT CABLE: 3 COILS! TAUT!", EventFeed.Tone.GOOD)
		Sfx.play("save", 1.4)
		transition_to(State.WRAPPED)


func tick_state(delta: float) -> void:
	if main == null or main.frozen:
		return

	# Update dust rings
	for i in range(dust_rings.size() - 1, -1, -1):
		var dr: Dictionary = dust_rings[i]
		dr.life -= delta
		if dr.life <= 0.0:
			dust_rings.remove_at(i)

	# Update confetti
	for i in range(confetti.size() - 1, -1, -1):
		var cf: Dictionary = confetti[i]
		cf.life -= delta
		cf.pos += cf.vel * delta
		cf.vel.y += 120.0 * delta # gravity
		if cf.life <= 0.0:
			confetti.remove_at(i)

	match state:
		State.IDLE:
			# Wake up when the pair advances up the promenade
			if main.dog != null and main.dog.global_position.y < -250.0:
				transition_to(State.PROWL)

		State.PROWL:
			swat_cooldown -= delta
			# Stalk north toward the plaza at y = -4600
			if main.human != null:
				var lead_target_y := minf(pos.y, main.human.global_position.y - 220.0)
				pos.y = move_toward(pos.y, lead_target_y, cur_speed * delta)
				pos.x = 640.0 + sin(pos.y * 0.005) * 30.0

			update_leg_positions()

			# Scatter pigeons as El Gat prowls
			for p in main.get_tree().get_nodes_in_group("pigeons"):
				if p.global_position.distance_to(pos) < 140.0:
					p.scare()

			# Check swat trigger
			if swat_cooldown <= 0.0 and pos.y > -4400.0:
				swat_cooldown = 3.4
				transition_to(State.SWAT)

			# Arrived at circular plaza arena
			if pos.y <= -4550.0:
				transition_to(State.ROAR)

		State.SWAT:
			state_t -= delta
			swat_telegraph = maxf(0.0, state_t)
			if state_t <= 0.0:
				execute_swat()
				transition_to(State.PROWL)

		State.ROAR:
			update_cable_wrap(delta)

		State.WRAPPED:
			state_t -= delta
			if state_t <= 0.0:
				transition_to(State.TOPPLED)

		State.TOPPLED:
			# Comically swat into the air periodically
			snout_pos = pos + Vector2(-54.0, -18.0)

		State.PURR:
			state_t -= delta
			purr_vibe = sin(AnimClock.msec() * 0.035) * 1.5
			if state_t <= 0.0:
				Goals.finish_walk(main)


func on_bark_action(bark_pos: Vector2) -> bool:
	if state == State.TOPPLED:
		if bark_pos.distance_to(snout_pos) < 75.0 or (main.dog != null and main.dog.global_position.distance_to(snout_pos) < 75.0):
			main.combo.add("SUPER BOOP", 10)
			main.float_text(snout_pos, "SUPER BOOP! +10", Color(1.0, 0.88, 0.25))
			Sfx.play("bark", 1.25)
			transition_to(State.PURR)
			return true
	return false


# --- Walk Module Hooks Called by main.gd ------------------------------------

static func tick(m: Node2D, delta: float) -> void:
	if m.lvl != "raval":
		return
	var gat: BossGat = m.get("boss_gat")
	if gat != null:
		gat.tick_state(delta)


static func on_bark(m: Node2D, pos: Vector2) -> void:
	if m.lvl != "raval":
		return
	var gat: BossGat = m.get("boss_gat")
	if gat != null:
		gat.on_bark_action(pos)


static func surface(m: Node2D, p: Vector2) -> int:
	if p.y > m.GATE_Y:
		return Surfaces.S.PAVEMENT
	return -1


static func draw_edge_layer(m: Node2D, b: ShapeBatch, _vt: float = 0.0, _vb: float = 0.0) -> void:
	if m.lvl != "raval":
		return

	# 1. Main promenade granite flagstones
	b.rect(Rect2(CORRIDOR_L, -5200.0, CORRIDOR_R - CORRIDOR_L, 5600.0), STONE_PLAZA)

	# 2. Flanking terracotta borders and panots pavement bands
	b.rect(Rect2(CORRIDOR_L - 30.0, -5200.0, 30.0, 5600.0), BAND_TERRACOTTA)
	b.rect(Rect2(CORRIDOR_R, -5200.0, 30.0, 5600.0), BAND_TERRACOTTA)

	# 3. Decorative panots (Barcelona 4-petal flower tiles) texture strips
	for y: float in [-600.0, -1400.0, -2200.0, -3000.0, -3800.0]:
		b.rect(Rect2(CORRIDOR_L, y, CORRIDOR_R - CORRIDOR_L, 12.0), BAND_CREAM)
		b.rect(Rect2(CORRIDOR_L, y + 3.0, CORRIDOR_R - CORRIDOR_L, 6.0), STONE_DARK)

	# 4. Central circular plaza at y = -4600.0
	b.circle(PEDESTAL_POS + LIGHT * 8.0, PLAZA_R + 8.0, SHADOW)
	b.circle(PEDESTAL_POS, PLAZA_R, STONE_PLAZA)
	b.circle(PEDESTAL_POS, PLAZA_R - 12.0, BAND_TERRACOTTA)
	b.circle(PEDESTAL_POS, PLAZA_R - 24.0, STONE_PLAZA)

	# Radial decorative starburst bands in the circular plaza
	for i in range(16):
		var a := float(i) * (TAU / 16.0)
		var dir := Vector2(cos(a), sin(a))
		b.line(PEDESTAL_POS + dir * 65.0, PEDESTAL_POS + dir * (PLAZA_R - 30.0), BAND_CREAM, 4.0)

	# 5. Central plinth pedestal for El Gat
	b.rect(Rect2(PEDESTAL_POS.x - 70.0 + LIGHT.x * 6.0, PEDESTAL_POS.y - 45.0 + LIGHT.y * 6.0, 140.0, 90.0), SHADOW)
	b.rect(Rect2(PEDESTAL_POS.x - 70.0, PEDESTAL_POS.y - 45.0, 140.0, 90.0), STONE_DARK)
	b.rect(Rect2(PEDESTAL_POS.x - 64.0, PEDESTAL_POS.y - 40.0, 128.0, 80.0), Color(0.72, 0.70, 0.66))

	# 6. Palms trunks and tree grates
	for p: Vector2 in PALMS:
		b.circle(p + LIGHT * 5.0, 18.0, SHADOW)
		b.rect(Rect2(p.x - 16.0, p.y - 16.0, 32.0, 32.0), STONE_DARK)
		b.circle(p, 14.0, PALM_TRUNK)
		b.circle(p, 8.0, PALM_BARK)

	# 7. Dining terraces under umbrellas
	for tr: Rect2 in TERRACES:
		b.rect(Rect2(tr.position + LIGHT * 4.0, tr.size), SHADOW)
		b.rect(tr, Color(0.18, 0.16, 0.18, 0.35))
		for r in range(int(tr.size.y / 48.0)):
			for c in range(2):
				var tp := tr.position + Vector2(16.0 + float(c) * 44.0, 24.0 + float(r) * 48.0)
				b.circle(tp + LIGHT * 3.0, 12.0, SHADOW)
				b.circle(tp, 11.0, Color(0.92, 0.90, 0.86)) # white marble top
				b.circle(tp, 3.5, Color(0.25, 0.22, 0.20)) # tapas plate

	# 8. Barcelona ornate drinking fountain
	var font_p := Vector2(450.0, -1800.0)
	b.circle(font_p + LIGHT * 4.0, 14.0, SHADOW)
	b.circle(font_p, 12.0, Color(0.18, 0.26, 0.20)) # dark iron green
	b.circle(font_p, 6.0, Color(0.85, 0.72, 0.25))  # brass tap

	# 9. Overturned kiosk at the plaza edge
	var kp := Vector2(705.0, -4490.0)
	b.rect(Rect2(kp.x + LIGHT.x * 4.0, kp.y + LIGHT.y * 4.0, 50.0, 44.0), SHADOW)
	b.rect(Rect2(kp.x, kp.y, 50.0, 44.0), Color(0.35, 0.24, 0.18))
	b.rect(Rect2(kp.x + 4.0, kp.y + 4.0, 42.0, 36.0), Color(0.85, 0.40, 0.30)) # striped awning


static func draw_overhead(m: Node2D, ci: CanvasItem) -> void:
	if m.lvl != "raval":
		return
	var b := ShapeBatch.new(ci)
	var t: float = AnimClock.msec() / 1000.0
	for p: Vector2 in PALMS:
		for i in range(10):
			var a := float(i) * (TAU / 10.0) + sin(t * 1.4 + p.y * 0.01) * 0.06
			var leaf_len := 56.0 + sin(float(i) * 2.3) * 7.0
			var dir := Vector2(cos(a), sin(a))
			var end_p := p + dir * leaf_len
			b.line(p, end_p, PALM_LEAF, 4.0)
			b.line(p, p + dir * leaf_len * 0.7, PALM_LEAF_LIGHT, 2.5)
			var norm := Vector2(-sin(a), cos(a)) * 5.0
			b.line(end_p, end_p - norm, PALM_LEAF_LIGHT, 1.5)
			b.line(end_p, end_p + norm, PALM_LEAF_LIGHT, 1.5)
	b.flush()


static func draw_live(m: Node2D, c: Object, _vt: float, _vb: float) -> void:
	if m.lvl != "raval":
		return
	var gat: BossGat = m.get("boss_gat")
	if gat == null:
		return
	gat.draw_gat(c)


func draw_gat(c: Object) -> void:
	var t: float = AnimClock.msec() / 1000.0
	var cur_pos := pos + Vector2(0, purr_vibe)

	# 1. Draw dust rings and telegraphs
	for dr in dust_rings:
		var frac: float = 1.0 - (float(dr.life) / maxf(float(dr.max_life), 0.01))
		var r: float = float(dr.r) * (0.3 + frac * 0.7)
		var col := Color(DUST_COLOR.r, DUST_COLOR.g, DUST_COLOR.b, (1.0 - frac) * 0.55)
		c.draw_circle(dr.pos, r, col, false, 4.0)
		c.draw_circle(dr.pos, r * 0.75, col, false, 2.5)

	# 2. Draw AT-AT Cable wrap progress rings during Phase 2 (ROAR)
	if state == State.ROAR:
		var ring_col := Color(0.98, 0.85, 0.30, 0.35 + sin(t * 8.0) * 0.15)
		c.draw_circle(cur_pos, 85.0, ring_col, false, 3.0)
		# Arc showing current wrap coil progress
		var coil_frac := clampf(wrap_coils / 3.0, 0.0, 1.0)
		if coil_frac > 0.01:
			c.draw_arc(cur_pos, 92.0, -PI * 0.5, -PI * 0.5 + TAU * coil_frac, 32, Color(1.0, 0.90, 0.20, 0.85), 5.0)

	# 3. Draw Confetti during Phase 3 victory
	for cf in confetti:
		c.draw_rect(Rect2(cf.pos.x - 3.0, cf.pos.y - 3.0, 6.0, 6.0), cf.col)

	# 4. Draw Giant Golden Yarn Prize if toppled or purring
	if state == State.TOPPLED or state == State.PURR:
		c.draw_circle(PRIZE + LIGHT * 4.0, 18.0, SHADOW)
		c.draw_circle(PRIZE, 16.0, YARN_DARK)
		c.draw_circle(PRIZE - LIGHT * 2.0, 14.0, YARN_GOLD)
		# Yarn winding strands
		c.draw_arc(PRIZE, 10.0, 0.0, TAU * 0.8, 12, Color(1.0, 0.92, 0.5), 2.5)
		c.draw_arc(PRIZE + Vector2(-2, 2), 6.0, 0.5, TAU * 0.9, 8, YARN_DARK, 2.0)

	# 5. Draw El Gat de Botero procedural bronze vector geometry
	if state == State.TOPPLED:
		draw_toppled_gat(c, cur_pos, t)
	else:
		draw_upright_gat(c, cur_pos, t)


func draw_upright_gat(c: Object, at: Vector2, t: float) -> void:
	# Ground shadow
	Clay.ground_shadow(c, at, 80.0, 62.0, 6.0, 0.30)

	# 4 Cylindrical bronze tree-trunk legs
	for leg: Vector2 in leg_poles:
		Clay.ball(c, leg + LIGHT * 2.0, LEG_RADIUS + 2.0, BRONZE_DARK)
		Clay.ball(c, leg, LEG_RADIUS, BRONZE_BASE)
		c.draw_circle(leg - LIGHT * 3.0, LEG_RADIUS * 0.45, BRONZE_LIT)
		# Toe indentations
		for toe in [-4.0, 0.0, 4.0]:
			c.draw_circle(leg + Vector2(toe, LEG_RADIUS - 3.0), 2.2, BRONZE_DARK)

	# Massive Botero sausage tail curling upwards
	var tail_pts := PackedVector2Array([
		at + Vector2(0, 45.0),
		at + Vector2(-15.0, 65.0),
		at + Vector2(-30.0, 80.0),
		at + Vector2(-38.0, 100.0 + sin(t * 3.0) * 4.0),
	])
	Clay.stroke(c, tail_pts, 20.0, 16.0, BRONZE_DARK)
	Clay.stroke(c, tail_pts, 15.0, 12.0, BRONZE_BASE)
	c.draw_circle(tail_pts[tail_pts.size() - 1], 9.0, BRONZE_BASE)

	# Chubby volumetric Botero body
	var body_half := Vector2(62.0, 52.0)
	Clay.blob(c, at, body_half, face_dir, BRONZE_BASE)
	# Metallic specular sheen highlight on round body
	c.draw_colored_polygon(Clay.ellipse_pts(at - LIGHT * 14.0, body_half * 0.45, face_dir), BRONZE_SPEC)

	# Rotund spherical head
	var head_c := at + face_dir * 38.0
	var head_r := 36.0
	Clay.ball(c, head_c, head_r, BRONZE_BASE)
	# Big chubby Botero jowls / cheeks
	Clay.ball(c, head_c + Vector2(-18.0, 8.0), 18.0, BRONZE_BASE)
	Clay.ball(c, head_c + Vector2(18.0, 8.0), 18.0, BRONZE_BASE)

	# Tiny cute triangular bronze ears
	for sd: float in [-1.0, 1.0]:
		var ear_base1 := head_c + Vector2(sd * 10.0, -head_r + 4.0)
		var ear_base2 := head_c + Vector2(sd * 24.0, -head_r + 10.0)
		var ear_tip := head_c + Vector2(sd * 20.0, -head_r - 14.0)
		c.draw_colored_polygon(PackedVector2Array([ear_base1, ear_tip, ear_base2]), BRONZE_DARK)
		c.draw_colored_polygon(PackedVector2Array([ear_base1 + Vector2(sd, 1), ear_tip - Vector2(0, -2), ear_base2 - Vector2(sd, 0)]), BRONZE_LIT)

	# Eyes (Amber slit eyes, blinking or happy)
	var blink: bool = fmod(t + pos.x * 0.01, 4.5) < 0.18 and state != State.ROAR
	for sd: float in [-1.0, 1.0]:
		var eye_c := head_c + Vector2(sd * 15.0, -4.0)
		if state == State.PURR:
			# Happy squinty eyes (^ . ^)
			c.draw_arc(eye_c, 6.0, PI * 0.1, PI * 0.9, 10, Color(0.12, 0.08, 0.06), 2.5)
		elif blink:
			c.draw_line(eye_c - Vector2(6, 0), eye_c + Vector2(6, 0), Color(0.12, 0.08, 0.06), 2.0)
		else:
			c.draw_circle(eye_c, 6.5, EYE_AMBER)
			# Vertical slit pupil
			c.draw_line(eye_c - Vector2(0, 5), eye_c + Vector2(0, 5), EYE_PUPIL, 2.2)

	# Snout & Nose
	var nose_c := head_c + Vector2(0.0, 10.0)
	c.draw_circle(nose_c, 5.0, NOSE_DARK)
	c.draw_line(nose_c, nose_c + Vector2(0, 6), NOSE_DARK, 2.0)
	c.draw_arc(nose_c + Vector2(-5, 6), 5.0, 0.0, PI * 0.8, 8, NOSE_DARK, 2.0)
	c.draw_arc(nose_c + Vector2(5, 6), 5.0, PI * 0.2, PI, 8, NOSE_DARK, 2.0)

	# Twitching stiff bronze wire whiskers
	var w_tw := sin(t * 8.0) * 2.0
	for sd: float in [-1.0, 1.0]:
		var wp := head_c + Vector2(sd * 12.0, 10.0)
		c.draw_line(wp, wp + Vector2(sd * 28.0, -4.0 + w_tw), WHISKER_WIRE, 1.5)
		c.draw_line(wp, wp + Vector2(sd * 30.0, 2.0), WHISKER_WIRE, 1.5)
		c.draw_line(wp, wp + Vector2(sd * 26.0, 8.0 - w_tw), WHISKER_WIRE, 1.5)

	# Swat paw active during SWAT
	if state == State.SWAT:
		var p_from := head_c + Vector2(40.0 if swat_paw_active == 1 else -40.0, 15.0)
		var p_to := swat_pos
		c.draw_line(p_from, p_to, BRONZE_BASE, 16.0)
		Clay.ball(c, p_to, 20.0, BRONZE_LIT)


func draw_toppled_gat(c: Object, at: Vector2, t: float) -> void:
	# Cast shadow
	Clay.ground_shadow(c, at, 90.0, 50.0, 4.0, 0.32)

	# Giant round belly exposed to the sky
	var belly_half := Vector2(68.0, 48.0)
	Clay.blob(c, at, belly_half, Vector2.RIGHT, BRONZE_BASE)
	# Metallic sheen highlight on round belly
	c.draw_colored_polygon(Clay.ellipse_pts(at - LIGHT * 10.0, belly_half * 0.50, Vector2.RIGHT), BRONZE_SPEC)

	# Tangled legs splayed sideways
	for i in range(4):
		var ang := float(i) * (TAU / 4.0) + PI * 0.25
		var lp := at + Vector2(cos(ang) * 55.0, sin(ang) * 35.0)
		Clay.ball(c, lp, LEG_RADIUS * 0.85, BRONZE_DARK)

	# Weakly swatting paw in the air
	var paw_lift := sin(t * 4.0) * 6.0
	var paw_p := at + Vector2(15.0, -35.0 + paw_lift)
	c.draw_line(at + Vector2(10.0, -10.0), paw_p, BRONZE_BASE, 12.0)
	Clay.ball(c, paw_p, 14.0, BRONZE_LIT)

	# Snout & Head resting sideways on the plaza panots
	var hc := snout_pos
	Clay.ball(c, hc, 28.0, BRONZE_BASE)
	Clay.ball(c, hc + Vector2(-10, 4), 14.0, BRONZE_BASE)
	c.draw_circle(hc + Vector2(0, 6), 4.5, NOSE_DARK)

	# Bewildered blinking slit eyes
	var eye_c := hc + Vector2(4, -8)
	c.draw_circle(eye_c, 5.5, EYE_AMBER)
	c.draw_line(eye_c - Vector2(0, 4), eye_c + Vector2(0, 4), EYE_PUPIL, 2.0)

	# Prompt for Super Boop
	if main != null and main.dog != null and main.dog.global_position.distance_to(snout_pos) < 70.0:
		var pulse := 1.0 + sin(t * 10.0) * 0.15
		c.draw_circle(snout_pos + Vector2(0, -28.0), 16.0 * pulse, Color(1.0, 0.90, 0.20, 0.75))
		c.draw_circle(snout_pos + Vector2(0, -28.0), 11.0 * pulse, Color(1.0, 1.0, 1.0, 0.95))
