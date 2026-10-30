class_name BossGat
extends RefCounted

# WALK 27: RAMBLA DEL RAVAL, the finale. Botero's fat bronze cat climbs off
# his plinth at the foot of the rambla and walks it ahead of you, and your
# human will not cross his plaça until he is dealt with.
#
# - The prowl: El Gat keeps LEAD ahead of your human (CATCH_SPEED when the
#   pair gets past him) and swats at the dog when she comes close. Every swat
#   is telegraphed by a dust ring where the paw will land; a near miss
#   staggers him.
# - Below half: he charges at her instead, a red lane SWAT_WARN ahead. A taut
#   leash across his path trips him (clothesline), a palm or a terrace in his
#   way stuns him (smash), and your human flung into him knocks him silly
#   (pummel). Stunned, a bark on the nose is a boop.
# - Out of fight, he walks back to his plinth in the plaça and sits. The rope
#   resting on three of his four legs within LEG_MEMORY ties him up; he
#   topples, and a bark on the snout settles him for good. Your human, who has
#   waited at HOLD_Y all this time, walks on into the plaça.

const Clay := preload("res://entities/clay.gd")
const ShapeBatch := preload("res://systems/shape_batch.gd")
const Surfaces := preload("res://world/surfaces.gd")
const EventFeed := preload("res://hud/event_feed.gd")

const LIGHT := Vector2(0.5, 0.866)
const SHADOW := Color(0.04, 0.05, 0.08, 0.24)

# --- Colors ------------------------------------------------------------------
const BRONZE_BASE := Color(0.30, 0.24, 0.19)
const BRONZE_DARK := Color(0.17, 0.13, 0.11)
const BRONZE_LIT := Color(0.46, 0.37, 0.27)
const BRONZE_SPEC := Color(0.78, 0.64, 0.46, 0.32)
const EYE_AMBER := Color(0.96, 0.78, 0.18)
const EYE_CHARGE := Color(1.00, 0.30, 0.12)
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
const STAR_GOLD := Color(1.00, 0.90, 0.25)

# --- Dimensions & Layout -----------------------------------------------------
const HALF := 320.0
const CORRIDOR_L := 320.0
const CORRIDOR_R := 960.0
const PEDESTAL_POS := Vector2(640.0, -4600.0)
# the plinth he climbs down from, at the foot of the rambla
const START_PLINTH := Vector2(640.0, -480.0)
const PLINTH_HALF := Vector2(55.0, 40.0)
const PLAZA_R := 220.0
# your human waits here, short of the plaça, until El Gat is settled
const HOLD_Y := PEDESTAL_POS.y + 150.0

const LEG_OFFSETS: Array[Vector2] = [
	Vector2(-36.0, -32.0), Vector2(36.0, -32.0),
	Vector2(-36.0, 32.0), Vector2(36.0, 32.0),
]
const LEG_RADIUS := 18.0
const SWAT_RADIUS := 42.0
const HIT_BOX_RADIUS := 46.0

const PRIZE := Vector2(730.0, -4520.0)
const PRIZE_TEXT := "snatch the yarn from the overturned kiosk"

# --- Tuning ------------------------------------------------------------------
const MAX_HP := 100.0
const WAKE_Y := -250.0          # the dog past this, he climbs down
const LEAD := 260.0             # how far ahead of your human he prowls
const PROWL_SPEED := 110.0
const CATCH_SPEED := 220.0      # the pair got past him: he hurries ahead again
const DRIFT_SPEED := 70.0       # sideways, to face the dog
const SWAT_REACH := 150.0       # she is this close: he swats
const SWAT_WARN := 0.85         # dust ring to paw: every owner-scale event is ~0.8 s
const SWAT_COOLDOWN := 3.0
const DODGE_DAMAGE := 15.0
const CHARGE_MIN := 160.0
const CHARGE_MAX := 460.0
const CHARGE_SPEED := 340.0
const CHARGE_TIME := 1.4
const CHARGE_COOLDOWN := 3.2
const CLOTHESLINE_DAMAGE := 25.0
const SMASH_DAMAGE := 20.0
const PUMMEL_DAMAGE := 30.0
const BOOP_DAMAGE := 10.0
const STUN_TIME := 2.6
const RETREAT_SPEED := 200.0
# the rope on three legs inside this window ties him up
const LEG_MEMORY := 1.5
const LEGS_TO_TIE := 3
# rope this near either end is the dog's collar or your human's hand, not a
# line across his path
const CLOTHESLINE_END_PTS := 3
const BOOP_REACH := 75.0

# --- State Machine -----------------------------------------------------------
enum State {
	IDLE,
	PROWL,
	SWAT,
	CHARGE_WARN,
	CHARGE,
	STUNNED,
	RETREAT,
	ROAR,
	WRAPPED,
	TOPPLED,
	PURR,
}

var state: State = State.IDLE
var state_t: float = 0.0

var hp: float = MAX_HP
var max_hp: float = MAX_HP
var phase: int = 1

var main: Node2D = null
var pos: Vector2 = START_PLINTH
var face_dir := Vector2.DOWN

var leg_poles: Array[Vector2] = []
var leg_indices: Array[int] = []
var leg_soft_indices: Array[int] = []
var leg_furniture_indices: Array[int] = []
var leg_touch_t: Array[float] = [-INF, -INF, -INF, -INF]
var legs_tied := 0

var swat_pos := Vector2.ZERO
var swat_cooldown := SWAT_COOLDOWN
var swat_paw_active := 0 # 0 left, 1 right

var charge_dir := Vector2.DOWN
var charge_lane_end := Vector2.ZERO
var charge_cooldown := CHARGE_COOLDOWN
var charge_hit_done := false
var charge_from_obstacle := false
var stun_booped := false
var stun_pummeled := false
var hold_noticed := false

var snout_pos := Vector2.ZERO
var purr_vibe := 0.0

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

# where the walk's pigeon flocks feed (LevelBuild sets main.flock_ys from these)
const PIGEON_SPOTS: Array[Vector2] = [
	Vector2(640.0, -800.0),
	Vector2(540.0, -1600.0),
	Vector2(740.0, -2500.0),
	Vector2(580.0, -3400.0),
	Vector2(640.0, -4300.0),
]

const KIOSK := Rect2(705.0, -4490.0, 50.0, 44.0)
const FOUNTAIN := Vector2(450.0, -1800.0)

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
	out.append(KIOSK)
	return out


static func solids(_m: Node2D) -> Array[Rect2]:
	var out: Array[Rect2] = []
	for t in TERRACES:
		out.append(t)
	# both plinths: the empty one he left and the one he goes back to
	out.append(Rect2(START_PLINTH - PLINTH_HALF, PLINTH_HALF * 2.0))
	out.append(Rect2(PEDESTAL_POS - PLINTH_HALF, PLINTH_HALF * 2.0))
	out.append(KIOSK)
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
	m.fountains = Array([FOUNTAIN], TYPE_VECTOR2, &"", null)
	m.benches = Array(BENCHES, TYPE_VECTOR2, &"", null)
	m.bins = Array([
		Vector2(360.0, -1400.0),
		Vector2(920.0, -1400.0),
		Vector2(360.0, -3200.0),
		Vector2(920.0, -3200.0),
	], TYPE_VECTOR2, &"", null)

	# your human walks round both plinths
	m.islands = Array([
		{"rect": Rect2(START_PLINTH - PLINTH_HALF - Vector2(15, 10), PLINTH_HALF * 2.0 + Vector2(30, 20)), "side": 1.0, "lead": 160.0},
		{"rect": Rect2(PEDESTAL_POS - PLINTH_HALF - Vector2(15, 10), PLINTH_HALF * 2.0 + Vector2(30, 20)), "side": 1.0, "lead": 160.0},
	], TYPE_DICTIONARY, &"", null)

	setup_poles(m)

	var gat := BossGat.new()
	gat.setup(m)
	m.boss_gat = gat
	m.gat_toppled = false
	m.gat_booped = false
	m.gat_swats_dodged = 0
	m.raval_pigeons_scattered = 0
	m.gat_clotheslined = false
	m.gat_human_pummeled = false
	m.gat_tree_smashed = false

	var marks: Array[Vector2] = [
		START_PLINTH + Vector2(0.0, PLINTH_HALF.y + 8.0), # the empty plinth
		FOUNTAIN,
		KIOSK.get_center() + Vector2(0.0, KIOSK.size.y * 0.5 + 8.0),
		Vector2(400.0, -1100.0), # palm grate
		Vector2(880.0, -3100.0), # palm grate
	]

	# dropped tapas off the terraces
	var snacks: Array[Vector2] = [
		Vector2(430.0, -1280.0),
		Vector2(850.0, -2480.0),
		Vector2(440.0, -3680.0),
		Vector2(680.0, -4420.0),
	]

	return [marks, snacks]


# Called by LevelBuild after the rope radii are filled: the legs are rope
# points with furniture slip (so the human never whirls round a walking cat),
# kept out of the static bodies, which only the poles before them get.
func register_legs(m: Node2D) -> void:
	leg_indices.clear()
	leg_soft_indices.clear()
	leg_furniture_indices.clear()
	leg_poles.clear()
	for off: Vector2 in LEG_OFFSETS:
		var lp: Vector2 = pos + off
		leg_indices.append(m.poles.size())
		leg_soft_indices.append(m.rope_soft.size())
		m.poles.append(lp)
		m.rope_radii.append(LEG_RADIUS + 2.0)
		m.rope_soft.append(lp)
		leg_poles.append(lp)


func is_leg_index(i: int) -> bool:
	return not leg_indices.is_empty() and i >= leg_indices[0] and i <= leg_indices[leg_indices.size() - 1]


# --- Instance Boss Methods ---------------------------------------------------

func setup(m_ref: Node2D) -> void:
	main = m_ref
	state = State.IDLE
	state_t = 0.0
	hp = MAX_HP
	max_hp = MAX_HP
	phase = 1
	pos = START_PLINTH
	face_dir = Vector2.DOWN
	legs_tied = 0
	leg_touch_t = [-INF, -INF, -INF, -INF]
	hold_noticed = false
	dust_rings.clear()
	confetti.clear()
	leg_poles.clear()
	for off: Vector2 in LEG_OFFSETS:
		leg_poles.append(pos + off)


func update_leg_positions() -> void:
	if leg_poles.size() != 4:
		return
	var leash_furn: Array = main.leash.furniture_poles if main.leash != null else []
	if leg_furniture_indices.size() != leg_indices.size():
		# the leash's furniture list is a copy: find the legs in it once
		leg_furniture_indices.clear()
		for k in range(leg_indices.size()):
			leg_furniture_indices.append(leash_furn.find(leg_poles[k]))
	for k in range(4):
		var target: Vector2 = pos + LEG_OFFSETS[k]
		leg_poles[k] = target
		if k < leg_indices.size():
			var idx: int = leg_indices[k]
			if idx >= 0 and idx < main.poles.size():
				main.poles[idx] = target
			var si: int = leg_soft_indices[k]
			if si >= 0 and si < main.rope_soft.size():
				main.rope_soft[si] = target
			var fi: int = leg_furniture_indices[k]
			if fi >= 0 and fi < leash_furn.size():
				leash_furn[fi] = target


func beaten() -> bool:
	return state == State.PURR


func damage_boss(amt: float) -> void:
	var was := hp
	hp = maxf(0.0, hp - amt)
	if hp <= MAX_HP * 0.5 and phase == 1:
		phase = 2
		main.feed.say("EL GAT IS CHARGING!", EventFeed.Tone.LOUD)
		main.human.notice("Is that cat... running at us?", 2.2)
	if hp <= 0.0 and was > 0.0:
		main.feed.say("EL GAT HAS HAD ENOUGH! AFTER HIM", EventFeed.Tone.GOOD)


func transition_to(new_state: State) -> void:
	# whatever he was doing, out of fight he goes home to his plinth
	if new_state == State.PROWL and hp <= 0.0:
		new_state = State.RETREAT
	state = new_state
	state_t = 0.0
	match new_state:
		State.PROWL:
			face_dir = Vector2.DOWN
		State.SWAT:
			state_t = SWAT_WARN
			swat_paw_active = 1 - swat_paw_active
			var to_dog: Vector2 = main.dog.global_position - pos
			swat_pos = pos + to_dog.limit_length(110.0)
			face_dir = to_dog.normalized() if to_dog.length() > 1.0 else Vector2.DOWN
			dust_rings.append({"pos": swat_pos, "r": SWAT_RADIUS, "life": SWAT_WARN, "max_life": SWAT_WARN})
		State.CHARGE_WARN:
			state_t = SWAT_WARN
			Sfx.play("gat_roar", 1.1, -4.0)
			var to_dog: Vector2 = main.dog.global_position - pos
			charge_dir = to_dog.normalized() if to_dog.length() > 1.0 else Vector2.DOWN
			face_dir = charge_dir
			charge_lane_end = pos + charge_dir * CHARGE_SPEED * CHARGE_TIME
			dust_rings.append({"pos": pos, "r": 36.0, "life": SWAT_WARN, "max_life": SWAT_WARN})
			main.shake_t = maxf(float(main.shake_t), 0.3)
		State.CHARGE:
			state_t = CHARGE_TIME
			charge_hit_done = false
			charge_from_obstacle = check_obstacle_collision()
			Sfx.play("fling", 0.7, -4.0)
		State.STUNNED:
			state_t = STUN_TIME
			stun_booped = false
			stun_pummeled = false
			Sfx.play("groan", 1.0, -5.0)
			main.shake_t = maxf(float(main.shake_t), 0.6)
		State.RETREAT:
			face_dir = (PEDESTAL_POS - pos).normalized() if pos.distance_to(PEDESTAL_POS) > 1.0 else Vector2.DOWN
		State.ROAR:
			pos = PEDESTAL_POS
			update_leg_positions()
			face_dir = Vector2.DOWN
			legs_tied = 0
			leg_touch_t = [-INF, -INF, -INF, -INF]
			Sfx.play("gat_roar", 0.95, -3.0)
			main.shake_t = maxf(float(main.shake_t), 0.6)
			main.feed.say("TIE UP HIS LEGS!", EventFeed.Tone.LOUD)
		State.WRAPPED:
			state_t = 0.85
			Sfx.play("intro_taut", 0.9, -5.0)
			Sfx.play("groan", 1.1, -5.0)
			main.shake_t = maxf(float(main.shake_t), 0.8)
		State.TOPPLED:
			snout_pos = pos + Vector2(-54.0, -18.0)
			Sfx.play("crack", 0.6, -3.0)
			Sfx.play("gat_clang", 0.8, -2.0)
			main.gat_toppled = true
			main.shake_t = 1.4
			main.feed.say("EL GAT IS DOWN!", EventFeed.Tone.LOUD)
			for d_rad in [40.0, 90.0, 150.0]:
				dust_rings.append({"pos": pos, "r": d_rad, "life": 0.8, "max_life": 0.8})
		State.PURR:
			pos = PEDESTAL_POS
			update_leg_positions()
			Sfx.play("gat_purr", 1.0, -4.0)
			Sfx.play("star", 1.1)
			main.gat_booped = true
			main.combo.add("BOOP", 10)
			main.float_text(snout_pos, "booped! +10", Color(1.0, 0.88, 0.25))
			main.feed.say("THE RAMBLA IS YOURS!", EventFeed.Tone.GOOD)
			main.human.say_line("Nice kitty.")
			var cols: Array[Color] = [Color(0.96, 0.35, 0.30), Color(0.95, 0.80, 0.25), Color(0.25, 0.65, 0.95), Color(0.35, 0.85, 0.40)]
			for i in range(48):
				var ang := TAU * float(i) / 48.0
				var spd := randf_range(80.0, 240.0)
				confetti.append({"pos": pos, "vel": Vector2(cos(ang), sin(ang)) * spd, "col": cols[i % 4], "life": 3.0})


func execute_swat() -> void:
	Sfx.play("crack", 0.8, -6.0)
	main.shake_t = maxf(float(main.shake_t), 0.4)
	var dog_p: Vector2 = main.dog.global_position
	var d_dist: float = dog_p.distance_to(swat_pos)
	if d_dist <= SWAT_RADIUS:
		var dir: Vector2 = (dog_p - swat_pos).normalized() if d_dist > 1.0 else Vector2.DOWN
		main.dog.knocked(dir, "paw")
	elif d_dist < SWAT_REACH:
		main.gat_swats_dodged += 1
		main.combo.add("DODGE", 2)
		main.float_text(swat_pos, "dodged! +2", Color(0.8, 1.0, 0.7))
		damage_boss(DODGE_DAMAGE)
	if main.human.global_position.distance_to(swat_pos) <= SWAT_RADIUS:
		main.human.bumped((main.human.global_position - swat_pos).normalized())
	_scatter_pigeons(swat_pos, 180.0)


func _scatter_pigeons(at: Vector2, r: float) -> void:
	for p in main.get_tree().get_nodes_in_group("pigeons"):
		if p.global_position.distance_to(at) < r:
			p.scare()


# --- Counters ----------------------------------------------------------------

# A taut leash across his path: the middle of the rope, not the dog's collar
# or your human's hand, within his body.
func check_clothesline() -> bool:
	var l = main.leash
	if l == null or l.detached:
		return false
	var rest: float = maxf(float(l.rest_len), 1.0)
	if l.taut_amount(l.used_length() / rest) < 0.15:
		return false
	var hit_sq := HIT_BOX_RADIUS * HIT_BOX_RADIUS
	var n: int = l.pts.size()
	for i in range(CLOTHESLINE_END_PTS, n - 1 - CLOTHESLINE_END_PTS):
		var cp: Vector2 = Geometry2D.get_closest_point_to_segment(pos, l.pts[i], l.pts[i + 1])
		if pos.distance_squared_to(cp) <= hit_sq:
			return true
	return false


func check_obstacle_collision() -> bool:
	for palm: Vector2 in PALMS:
		if pos.distance_squared_to(palm) < 42.0 * 42.0:
			return true
	for tr: Rect2 in TERRACES:
		if tr.grow(32.0).has_point(pos):
			return true
	return false


func check_human_pummel() -> bool:
	if main.human.global_position.distance_to(pos) > 68.0:
		return false
	return main.human.whirl_flung_t > 0.0 or main.human.velocity.length() > 200.0


func _pummel() -> void:
	main.gat_human_pummeled = true
	damage_boss(PUMMEL_DAMAGE)
	Sfx.play("crack", 0.7, -4.0)
	Sfx.play("gat_clang", 1.2, -5.0)
	main.shake_t = 1.2
	main.human.bumped((main.human.global_position - pos).normalized())
	main.feed.say("HUMAN BOWLING!", EventFeed.Tone.LOUD)
	main.combo.add("PUMMEL", 12)
	main.float_text(pos, "bowled! +12", Color(1.0, 0.6, 0.4))
	main.human.notice("Ow! Solid bronze!", 2.2)
	for d_rad in [45.0, 90.0]:
		dust_rings.append({"pos": pos, "r": d_rad, "life": 0.7, "max_life": 0.7})


# --- The tangle --------------------------------------------------------------

func update_leg_tangle() -> void:
	var now: float = main.elapsed
	legs_tied = 0
	for k in range(leg_poles.size()):
		if main.leash != null and main.leash.touches(leg_poles[k]):
			leg_touch_t[k] = now
		if now - leg_touch_t[k] <= LEG_MEMORY:
			legs_tied += 1
	if legs_tied >= LEGS_TO_TIE:
		transition_to(State.WRAPPED)


func _hold_human() -> void:
	# He will not walk into the plaça past a cat the size of a car. auto_walk
	# (the CI soak and the autowalk smoke) passes, as it cannot fight.
	var h = main.human
	var want: bool = not beaten() and not main.auto_walk and not h.homeward \
		and h.global_position.y < HOLD_Y + 260.0
	if want:
		h.tut_hold_y = HOLD_Y
		# the hold stops the reel's fiddling, and the tangle round his plinth
		# needs the whole leash, as the tutorial's holds do
		if main.leash_target < main.LEASH_LENGTH:
			main.set_leash_target(main.LEASH_LENGTH)
		if not hold_noticed and h.global_position.y < HOLD_Y + 20.0:
			hold_noticed = true
			h.notice("Not past that cat.", 1.8)
	elif h.tut_hold_y == HOLD_Y:
		h.tut_hold_y = -INF


# --- State Machine Tick ------------------------------------------------------

func tick_state(delta: float) -> void:
	if main.frozen:
		return

	for i in range(dust_rings.size() - 1, -1, -1):
		var dr: Dictionary = dust_rings[i]
		dr.life -= delta
		if dr.life <= 0.0:
			dust_rings.remove_at(i)
	for i in range(confetti.size() - 1, -1, -1):
		var cf: Dictionary = confetti[i]
		cf.life -= delta
		cf.pos += cf.vel * delta
		cf.vel.y += 120.0 * delta
		if cf.life <= 0.0:
			confetti.remove_at(i)

	_hold_human()
	var dog_p: Vector2 = main.dog.global_position

	match state:
		State.IDLE:
			if dog_p.y < WAKE_Y:
				main.human.notice("Huh, big cat today...", 2.2)
				transition_to(State.PROWL)

		State.PROWL:
			swat_cooldown -= delta
			charge_cooldown -= delta
			# north only, LEAD ahead of your human, never past his plinth
			var want_y := maxf(minf(pos.y, main.human.global_position.y - LEAD), PEDESTAL_POS.y)
			var spd := CATCH_SPEED if pos.y - want_y > 120.0 else PROWL_SPEED
			pos.y = move_toward(pos.y, want_y, spd * delta)
			# between the palm rows, clear of the terraces
			var want_x := clampf(dog_p.x, CORRIDOR_L + 130.0, CORRIDOR_R - 130.0)
			pos.x = move_toward(pos.x, want_x, DRIFT_SPEED * delta)
			update_leg_positions()
			var d := dog_p.distance_to(pos)
			if d < SWAT_REACH and swat_cooldown <= 0.0:
				swat_cooldown = SWAT_COOLDOWN
				transition_to(State.SWAT)
			elif phase == 2 and charge_cooldown <= 0.0 and d > CHARGE_MIN and d < CHARGE_MAX:
				charge_cooldown = CHARGE_COOLDOWN
				transition_to(State.CHARGE_WARN)

		State.SWAT:
			state_t -= delta
			if state_t <= 0.0:
				execute_swat()
				transition_to(State.PROWL)

		State.CHARGE_WARN:
			state_t -= delta
			if state_t <= 0.0:
				transition_to(State.CHARGE)

		State.CHARGE:
			state_t -= delta
			pos += charge_dir * CHARGE_SPEED * delta
			pos.x = clampf(pos.x, CORRIDOR_L + 60.0, CORRIDOR_R - 60.0)
			pos.y = clampf(pos.y, PEDESTAL_POS.y - 160.0, float(main.START_Y))
			update_leg_positions()
			_scatter_pigeons(pos, 120.0)

			if check_clothesline():
				main.gat_clotheslined = true
				damage_boss(CLOTHESLINE_DAMAGE)
				Sfx.play("intro_taut", 1.0, -4.0)
				Sfx.play("gat_clang", 1.1, -3.0)
				main.shake_t = 1.1
				main.feed.say("CLOTHESLINED!", EventFeed.Tone.LOUD)
				main.combo.add("CLOTHESLINE", 8)
				main.float_text(pos, "clothesline! +8", Color(1.0, 0.85, 0.2))
				for d_rad in [35.0, 70.0]:
					dust_rings.append({"pos": pos, "r": d_rad, "life": 0.6, "max_life": 0.6})
				transition_to(State.STUNNED)
				return

			# a charge begun beside a palm is not a smash until he has left it
			if charge_from_obstacle and not check_obstacle_collision():
				charge_from_obstacle = false
			if not charge_from_obstacle and check_obstacle_collision():
				main.gat_tree_smashed = true
				damage_boss(SMASH_DAMAGE)
				Sfx.play("crack", 0.6, -3.0)
				Sfx.play("gat_clang", 0.95, -3.0)
				main.shake_t = 1.2
				main.feed.say("BONK! RIGHT INTO IT", EventFeed.Tone.LOUD)
				main.combo.add("SMASH", 6)
				main.float_text(pos, "smash! +6", Color(0.9, 0.5, 0.3))
				for d_rad in [40.0, 80.0]:
					dust_rings.append({"pos": pos, "r": d_rad, "life": 0.7, "max_life": 0.7})
				transition_to(State.STUNNED)
				return

			if check_human_pummel():
				_pummel()
				transition_to(State.STUNNED)
				# the same fling is still in reach next frame: one pummel each
				stun_pummeled = true
				return

			# one knock per charge, however long she stays in front of him
			if not charge_hit_done and dog_p.distance_to(pos) < HIT_BOX_RADIUS:
				charge_hit_done = true
				main.dog.knocked(charge_dir, "charge")
			if main.human.global_position.distance_to(pos) < HIT_BOX_RADIUS:
				main.human.bumped(charge_dir)

			if state_t <= 0.0:
				transition_to(State.PROWL)

		State.STUNNED:
			state_t -= delta
			if not stun_pummeled and check_human_pummel():
				stun_pummeled = true
				_pummel()
			if state_t <= 0.0:
				transition_to(State.PROWL)

		State.RETREAT:
			pos = pos.move_toward(PEDESTAL_POS, RETREAT_SPEED * delta)
			update_leg_positions()
			if pos.distance_to(PEDESTAL_POS) < 1.0:
				transition_to(State.ROAR)

		State.ROAR:
			update_leg_tangle()

		State.WRAPPED:
			state_t -= delta
			if state_t <= 0.0:
				transition_to(State.TOPPLED)

		State.PURR:
			purr_vibe = sin(AnimClock.msec() * 0.035) * 1.5


func on_bark_action(bark_pos: Vector2) -> bool:
	var dog_p: Vector2 = main.dog.global_position
	if state == State.TOPPLED:
		if bark_pos.distance_to(snout_pos) < BOOP_REACH or dog_p.distance_to(snout_pos) < BOOP_REACH:
			Sfx.play("bark", 1.25)
			transition_to(State.PURR)
			return true
	elif state == State.STUNNED and not stun_booped:
		var nose := pos + face_dir * 48.0
		if bark_pos.distance_to(nose) < BOOP_REACH or dog_p.distance_to(nose) < BOOP_REACH:
			stun_booped = true
			damage_boss(BOOP_DAMAGE)
			main.combo.add("BOOP", 3)
			main.float_text(nose, "boop! +3", Color(1.0, 0.88, 0.25))
			return true
	return false


# The banner while he is about: what to do about him right now. Empty lets the
# walk's ordinary banner through.
func status() -> String:
	var near: bool = main.dog.global_position.distance_to(pos) < 600.0
	match state:
		State.SWAT:
			return "WATCH THE PAW!" if near else ""
		State.CHARGE_WARN, State.CHARGE:
			return "CHARGE! LEASH ACROSS HIS PATH" if near else ""
		State.STUNNED:
			return Prompts.fill("HE'S DAZED! {bark} ON HIS NOSE") if near else ""
		State.RETREAT:
			return "AFTER HIM! TO THE PLAÇA"
		State.ROAR:
			return "WRAP THE LEASH ROUND HIS LEGS  %d/%d" % [legs_tied, LEGS_TO_TIE]
		State.TOPPLED:
			return Prompts.fill("HE'S DOWN! {bark} ON HIS SNOUT")
	if not beaten() and main.human.tut_hold_y == HOLD_Y and main.human.global_position.y < HOLD_Y + 40.0:
		return "YOUR HUMAN WON'T PASS HIM. DEAL WITH EL GAT"
	return ""


# --- Walk Module Hooks Called by main.gd ------------------------------------

static func tick(m: Node2D, delta: float) -> void:
	if m.lvl != "raval" or m.boss_gat == null:
		return
	m.boss_gat.tick_state(delta)


static func on_bark(m: Node2D, pos: Vector2) -> void:
	if m.lvl != "raval" or m.boss_gat == null:
		return
	m.boss_gat.on_bark_action(pos)


static func idle_status(m: Node2D) -> String:
	if m.lvl != "raval" or m.boss_gat == null:
		return ""
	return m.boss_gat.status()


static func surface(m: Node2D, p: Vector2) -> int:
	if p.y > m.GATE_Y:
		return Surfaces.S.PAVEMENT
	return -1


static func draw_edge_layer(m: Node2D, b: ShapeBatch, vt: float = 0.0, vb: float = 0.0) -> void:
	if m.lvl != "raval":
		return

	# 1. Main promenade granite flagstones
	b.rect(Rect2(CORRIDOR_L, -5200.0, CORRIDOR_R - CORRIDOR_L, 5600.0), STONE_PLAZA)

	# 2. Flanking terracotta borders and panots pavement bands
	b.rect(Rect2(CORRIDOR_L - 30.0, -5200.0, 30.0, 5600.0), BAND_TERRACOTTA)
	b.rect(Rect2(CORRIDOR_R, -5200.0, 30.0, 5600.0), BAND_TERRACOTTA)

	# 3. Decorative panot strips
	for y: float in [-600.0, -1400.0, -2200.0, -3000.0, -3800.0]:
		b.rect(Rect2(CORRIDOR_L, y, CORRIDOR_R - CORRIDOR_L, 12.0), BAND_CREAM)
		b.rect(Rect2(CORRIDOR_L, y + 3.0, CORRIDOR_R - CORRIDOR_L, 6.0), STONE_DARK)

	# 4. Central circular plaza
	b.circle(PEDESTAL_POS + LIGHT * 8.0, PLAZA_R + 8.0, SHADOW)
	b.circle(PEDESTAL_POS, PLAZA_R, STONE_PLAZA)
	b.circle(PEDESTAL_POS, PLAZA_R - 12.0, BAND_TERRACOTTA)
	b.circle(PEDESTAL_POS, PLAZA_R - 24.0, STONE_PLAZA)
	for i in range(16):
		var a := float(i) * (TAU / 16.0)
		var dir := Vector2(cos(a), sin(a))
		b.line(PEDESTAL_POS + dir * 65.0, PEDESTAL_POS + dir * (PLAZA_R - 30.0), BAND_CREAM, 4.0)

	# 5. Both plinths
	for pc: Vector2 in [START_PLINTH, PEDESTAL_POS]:
		b.rect(Rect2(pc - PLINTH_HALF - Vector2(15, 5) + LIGHT * 6.0, PLINTH_HALF * 2.0 + Vector2(30, 10)), SHADOW)
		b.rect(Rect2(pc - PLINTH_HALF - Vector2(15, 5), PLINTH_HALF * 2.0 + Vector2(30, 10)), STONE_DARK)
		b.rect(Rect2(pc - PLINTH_HALF - Vector2(9, 0), PLINTH_HALF * 2.0 + Vector2(18, 0)), Color(0.72, 0.70, 0.66))

	# 6. Palm trunks and tree grates
	var culled := vb > vt
	for p: Vector2 in PALMS:
		if culled and (p.y < vt - 120.0 or p.y > vb + 120.0):
			continue
		for i in range(9):
			var a := float(i) * (TAU / 9.0) + _palm_spin(p)
			_frond(b, p + LIGHT * 22.0, a, 60.0 + sin(float(i) * 2.3) * 8.0, 13.0, SHADOW)
		b.circle(p + LIGHT * 5.0, 18.0, SHADOW)
		b.rect(Rect2(p.x - 16.0, p.y - 16.0, 32.0, 32.0), STONE_DARK)
		b.circle(p, 14.0, PALM_TRUNK)
		b.circle(p, 8.0, PALM_BARK)

	# 7. Dining terraces
	for tr: Rect2 in TERRACES:
		if culled and (tr.end.y < vt - 40.0 or tr.position.y > vb + 40.0):
			continue
		b.rect(Rect2(tr.position + LIGHT * 4.0, tr.size), SHADOW)
		b.rect(tr, Color(0.18, 0.16, 0.18, 0.35))
		for r in range(int(tr.size.y / 48.0)):
			for c in range(2):
				var tp := tr.position + Vector2(16.0 + float(c) * 44.0, 24.0 + float(r) * 48.0)
				b.circle(tp + LIGHT * 3.0, 12.0, SHADOW)
				b.circle(tp, 11.0, Color(0.92, 0.90, 0.86))
				b.circle(tp, 3.5, Color(0.25, 0.22, 0.20))

	# 8. Drinking fountain
	b.circle(FOUNTAIN + LIGHT * 4.0, 14.0, SHADOW)
	b.circle(FOUNTAIN, 12.0, Color(0.18, 0.26, 0.20))
	b.circle(FOUNTAIN, 6.0, Color(0.85, 0.72, 0.25))

	# 9. Overturned kiosk at the plaza edge
	b.rect(Rect2(KIOSK.position + LIGHT * 4.0, KIOSK.size), SHADOW)
	b.rect(KIOSK, Color(0.35, 0.24, 0.18))
	b.rect(KIOSK.grow(-4.0), Color(0.85, 0.40, 0.30))


# The overhead layer draws once and is never redrawn, so this covers the whole
# walk and stays still.
static func draw_overhead(m: Node2D, ci: CanvasItem) -> void:
	if m.lvl != "raval":
		return
	var b := ShapeBatch.new(ci)
	for p: Vector2 in PALMS:
		var spin := _palm_spin(p)
		for i in range(9):
			var a := float(i) * (TAU / 9.0) + spin
			_frond(b, p, a, 60.0 + sin(float(i) * 2.3) * 8.0, 13.0, PALM_LEAF)
		for i in range(7):
			var a := float(i) * (TAU / 7.0) + spin + 0.35
			_frond(b, p, a, 40.0 + cos(float(i) * 1.7) * 6.0, 10.0, PALM_LEAF_LIGHT)
		for i in range(9):
			var a := float(i) * (TAU / 9.0) + spin
			var dir := Vector2(cos(a), sin(a))
			b.line(p + dir * 8.0, p + dir * (52.0 + sin(float(i) * 2.3) * 8.0), PALM_LEAF.darkened(0.25), 1.5)
		b.circle(p, 9.0, PALM_BARK)
		b.circle(p + Vector2(-2.0, -2.0), 5.0, PALM_TRUNK)
	b.flush()


static func _palm_spin(p: Vector2) -> float:
	return p.y * 0.0007 + p.x * 0.003


# One frond seen from above: narrow at the crown, widest past the middle,
# a point at the tip, curling a little to one side.
static func _frond(b: ShapeBatch, root: Vector2, a: float, length: float, width: float, color: Color) -> void:
	var dir := Vector2(cos(a), sin(a))
	var side := Vector2(-dir.y, dir.x)
	var curl := side * length * 0.08
	b.polygon(PackedVector2Array([
		root + side * 2.0,
		root + dir * length * 0.55 + side * width * 0.5 + curl * 0.5,
		root + dir * length + curl,
		root + dir * length * 0.55 - side * width * 0.5 + curl * 0.5,
		root - side * 2.0,
	]), color)


static func draw_live(m: Node2D, c: Object, vt: float, vb: float) -> void:
	if m.lvl != "raval" or m.boss_gat == null:
		return
	var gat: BossGat = m.boss_gat
	if gat.pos.y < vt - 240.0 or gat.pos.y > vb + 240.0:
		return
	gat.draw_gat(c)


func draw_gat(c: Object) -> void:
	var t: float = AnimClock.msec() / 1000.0
	var cur_pos := pos + Vector2(0, purr_vibe)

	if state == State.CHARGE_WARN:
		var warn_pulse: float = 0.35 + sin(t * 14.0) * 0.15
		var lane_col := Color(1.0, 0.25, 0.15, warn_pulse)
		c.draw_line(pos, charge_lane_end, lane_col, 28.0)
		c.draw_circle(charge_lane_end, 20.0, lane_col)

	for cf in confetti:
		c.draw_rect(Rect2(cf.pos.x - 3.0, cf.pos.y - 3.0, 6.0, 6.0), cf.col)

	if state == State.TOPPLED:
		draw_toppled_gat(c, cur_pos, t)
	else:
		draw_upright_gat(c, cur_pos, t)

	if state != State.IDLE and hp > 0.0:
		draw_boss_health_bar(c, cur_pos)

	# the strokes last, together: each arc goes straight to the canvas
	for dr in dust_rings:
		var frac: float = 1.0 - (float(dr.life) / maxf(float(dr.max_life), 0.01))
		var r: float = float(dr.r) * (0.3 + frac * 0.7)
		var col := Color(DUST_COLOR.r, DUST_COLOR.g, DUST_COLOR.b, (1.0 - frac) * 0.55)
		c.draw_arc(dr.pos, r, 0.0, TAU, 32, col, 4.0)
	if state == State.ROAR:
		var ring_col := Color(0.98, 0.85, 0.30, 0.35 + sin(t * 8.0) * 0.15)
		c.draw_arc(cur_pos, 92.0, 0.0, TAU, 40, ring_col, 3.0)
		for k in range(leg_poles.size()):
			if main.elapsed - leg_touch_t[k] <= LEG_MEMORY:
				c.draw_arc(leg_poles[k], LEG_RADIUS + 6.0, 0.0, TAU, 20, Color(1.0, 0.90, 0.20, 0.9), 3.0)


func draw_boss_health_bar(c: Object, at: Vector2) -> void:
	var bar_w := 130.0
	var bar_h := 8.0
	var bar_pos := at + Vector2(-bar_w * 0.5, -96.0)
	c.draw_rect(Rect2(bar_pos + LIGHT * 2.0, Vector2(bar_w, bar_h)), SHADOW)
	c.draw_rect(Rect2(bar_pos - Vector2(1.5, 1.5), Vector2(bar_w + 3.0, bar_h + 3.0)), BRONZE_LIT)
	c.draw_rect(Rect2(bar_pos, Vector2(bar_w, bar_h)), BRONZE_DARK)
	var hp_frac := clampf(hp / max_hp, 0.0, 1.0)
	if hp_frac > 0.0:
		var fill_col := Color(0.96, 0.32, 0.22) if phase == 2 else Color(0.96, 0.74, 0.18)
		c.draw_rect(Rect2(bar_pos + Vector2(1, 1), Vector2((bar_w - 2.0) * hp_frac, bar_h - 2.0)), fill_col)


func draw_upright_gat(c: Object, at: Vector2, t: float) -> void:
	Clay.ground_shadow(c, at, 80.0, 62.0, 6.0, 0.30)

	for leg: Vector2 in leg_poles:
		var lp := leg + (at - pos)
		Clay.ball(c, lp + LIGHT * 2.0, LEG_RADIUS + 2.0, BRONZE_DARK)
		Clay.ball(c, lp, LEG_RADIUS, BRONZE_BASE)
		for toe: float in [-5.0, 0.0, 5.0]:
			c.draw_circle(lp + Vector2(toe, LEG_RADIUS - 4.0), 2.4, BRONZE_DARK)

	# the fat tail, curled round behind him
	var back := -face_dir
	var side := face_dir.orthogonal()
	var tail_pts := PackedVector2Array([
		at + back * 45.0,
		at + back * 62.0 + side * 14.0,
		at + back * 74.0 + side * 30.0,
		at + back * 86.0 + side * (40.0 + sin(t * 3.0) * 4.0),
	])
	Clay.stroke(c, tail_pts, 20.0, 16.0, BRONZE_DARK)
	Clay.stroke(c, tail_pts, 15.0, 12.0, BRONZE_BASE)
	c.draw_circle(tail_pts[tail_pts.size() - 1], 9.0, BRONZE_BASE)

	var body_half := Vector2(62.0, 52.0)
	Clay.blob(c, at, body_half, face_dir, BRONZE_BASE)
	c.draw_colored_polygon(Clay.ellipse_pts(at - LIGHT * 14.0, body_half * 0.45, face_dir), BRONZE_SPEC)

	var head_c := at + face_dir * 38.0
	var head_r := 36.0
	Clay.ball(c, head_c, head_r, BRONZE_BASE)
	Clay.ball(c, head_c + Vector2(-18.0, 8.0), 18.0, BRONZE_BASE)
	Clay.ball(c, head_c + Vector2(18.0, 8.0), 18.0, BRONZE_BASE)

	var ear_droop: float = 6.0 if state == State.STUNNED else 0.0
	for sd: float in [-1.0, 1.0]:
		var ear_base1 := head_c + Vector2(sd * 10.0, -head_r + 4.0 + ear_droop)
		var ear_base2 := head_c + Vector2(sd * 24.0, -head_r + 10.0 + ear_droop)
		var ear_tip := head_c + Vector2(sd * 20.0, -head_r - 14.0 + ear_droop)
		c.draw_colored_polygon(PackedVector2Array([ear_base1, ear_tip, ear_base2]), BRONZE_DARK)
		c.draw_colored_polygon(PackedVector2Array([ear_base1.lerp(ear_base2, 0.2), ear_tip.lerp(head_c, 0.25), ear_base2.lerp(ear_base1, 0.2)]), BRONZE_LIT)

	var charging := state == State.CHARGE_WARN or state == State.CHARGE
	var blink: bool = fmod(t + pos.x * 0.01, 4.5) < 0.18 and state != State.ROAR and not charging
	var eye_col: Color = EYE_CHARGE if charging else EYE_AMBER
	for sd: float in [-1.0, 1.0]:
		var eye_c := head_c + Vector2(sd * 15.0, -4.0)
		if state == State.PURR:
			# contented, shut: a soft upturned line each
			c.draw_line(eye_c + Vector2(-6, 1), eye_c + Vector2(0, -2), EYE_PUPIL, 2.5)
			c.draw_line(eye_c + Vector2(0, -2), eye_c + Vector2(6, 1), EYE_PUPIL, 2.5)
		elif state == State.STUNNED:
			c.draw_line(eye_c - Vector2(4, 4), eye_c + Vector2(4, 4), EYE_PUPIL, 2.2)
			c.draw_line(eye_c - Vector2(-4, 4), eye_c + Vector2(-4, 4), EYE_PUPIL, 2.2)
		elif blink:
			c.draw_line(eye_c - Vector2(6, 0), eye_c + Vector2(6, 0), EYE_PUPIL, 2.0)
		else:
			c.draw_circle(eye_c, 6.5, eye_col)
			c.draw_line(eye_c - Vector2(0, 5), eye_c + Vector2(0, 5), EYE_PUPIL, 2.2)

	var nose_c := head_c + Vector2(0.0, 10.0)
	c.draw_circle(nose_c, 5.0, NOSE_DARK)
	c.draw_line(nose_c, nose_c + Vector2(0, 6), NOSE_DARK, 2.0)
	c.draw_line(nose_c + Vector2(0, 6), nose_c + Vector2(-6, 9), NOSE_DARK, 2.0)
	c.draw_line(nose_c + Vector2(0, 6), nose_c + Vector2(6, 9), NOSE_DARK, 2.0)

	var w_tw := sin(t * 8.0) * 2.0
	for sd: float in [-1.0, 1.0]:
		var wp := head_c + Vector2(sd * 12.0, 10.0)
		c.draw_line(wp, wp + Vector2(sd * 28.0, -4.0 + w_tw), WHISKER_WIRE, 1.5)
		c.draw_line(wp, wp + Vector2(sd * 30.0, 2.0), WHISKER_WIRE, 1.5)
		c.draw_line(wp, wp + Vector2(sd * 26.0, 8.0 - w_tw), WHISKER_WIRE, 1.5)

	# the paw goes up during the warning and lands at the ring
	if state == State.SWAT:
		var lift := clampf(state_t / SWAT_WARN, 0.0, 1.0)
		var shoulder := at + face_dir.orthogonal() * (34.0 if swat_paw_active == 1 else -34.0)
		var p_to := swat_pos.lerp(shoulder, lift * 0.6) + Vector2(0, -26.0 * lift)
		c.draw_line(shoulder, p_to, BRONZE_BASE, 16.0)
		Clay.ball(c, p_to, 20.0, BRONZE_LIT)

	if state == State.STUNNED:
		for i in range(4):
			var star_a := t * 4.5 + float(i) * (TAU / 4.0)
			var star_p := head_c + Vector2(cos(star_a) * 34.0, sin(star_a) * 14.0 - 18.0)
			c.draw_circle(star_p, 4.0, STAR_GOLD)
			c.draw_circle(star_p, 2.0, Color.WHITE)


func draw_toppled_gat(c: Object, at: Vector2, t: float) -> void:
	Clay.ground_shadow(c, at, 90.0, 50.0, 4.0, 0.32)

	var belly_half := Vector2(68.0, 48.0)
	Clay.blob(c, at, belly_half, Vector2.RIGHT, BRONZE_BASE)
	c.draw_colored_polygon(Clay.ellipse_pts(at - LIGHT * 10.0, belly_half * 0.50, Vector2.RIGHT), BRONZE_SPEC)

	for i in range(4):
		var ang := float(i) * (TAU / 4.0) + PI * 0.25
		var lp := at + Vector2(cos(ang) * 55.0, sin(ang) * 35.0)
		Clay.ball(c, lp, LEG_RADIUS * 0.85, BRONZE_DARK)

	var paw_lift := sin(t * 4.0) * 6.0
	var paw_p := at + Vector2(15.0, -35.0 + paw_lift)
	c.draw_line(at + Vector2(10.0, -10.0), paw_p, BRONZE_BASE, 12.0)
	Clay.ball(c, paw_p, 14.0, BRONZE_LIT)

	var hc := snout_pos + (at - pos)
	Clay.ball(c, hc, 28.0, BRONZE_BASE)
	Clay.ball(c, hc + Vector2(-10, 4), 14.0, BRONZE_BASE)
	c.draw_circle(hc + Vector2(0, 6), 4.5, NOSE_DARK)

	var eye_c := hc + Vector2(4, -8)
	c.draw_circle(eye_c, 5.5, EYE_AMBER)
	c.draw_line(eye_c - Vector2(0, 4), eye_c + Vector2(0, 4), EYE_PUPIL, 2.0)

	if main.dog.global_position.distance_to(snout_pos) < BOOP_REACH:
		var pulse := 1.0 + sin(t * 10.0) * 0.15
		c.draw_circle(hc + Vector2(0, -28.0), 16.0 * pulse, Color(1.0, 0.90, 0.20, 0.75))
		c.draw_circle(hc + Vector2(0, -28.0), 11.0 * pulse, Color(1.0, 1.0, 1.0, 0.95))
