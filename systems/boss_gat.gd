class_name BossGat
extends RefCounted

# WALK 27: RAMBLA DEL RAVAL, the finale. Botero's fat bronze cat climbs off
# his plinth at the foot of the rambla and walks it ahead of you, and your
# human will not cross his plaça until he is dealt with.
#
# - The wake: the dog past WAKE_Y, he opens his eyes, cracks his plinth, roars
#   and hops down (AWAKEN_TIME), under a title card, with the camera leaning
#   his way. The rambla's onlookers (the terrace diners and the crowd at the
#   plaça) gasp and cheer through the whole fight.
# - The prowl: El Gat keeps LEAD ahead of your human (CATCH_SPEED when the
#   pair gets past him) and swats at the dog when she comes close. Every swat
#   is telegraphed by a ring that fills where the paw will land; a near miss
#   staggers him. His body is solid to both of you (BODY_R) off his plinths.
# - Below half: he rears and roars (ENRAGE_TIME, eyes red, steam), then charges
#   at her instead, a red lane SWAT_WARN ahead. A taut leash across his path
#   trips him (clothesline), a palm or a terrace in his way stuns him (smash),
#   and your human flung into him knocks him silly (pummel). Stunned, a bark
#   on the nose is a boop. The big hits get a beat of slow motion.
# - Out of fight, he walks back to his plinth in the plaça for a last stand,
#   still swatting at her (telegraphed) every LAST_SWAT_EVERY. The rope resting
#   on three of his four legs within LEG_MEMORY ties him up; he teeters
#   (WOBBLE_TIME) and topples, and a bark on the snout settles him for good,
#   to fireworks. Your human, who has waited at HOLD_Y all this time, walks on
#   into the plaça.

const Clay := preload("res://entities/clay.gd")
const ShapeBatch := preload("res://systems/shape_batch.gd")
const Surfaces := preload("res://world/surfaces.gd")
const EventFeed := preload("res://hud/event_feed.gd")
const Kit := preload("res://hud/ui_kit.gd")

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
# the wake, from eyes open to landing off the plinth
const AWAKEN_TIME := 2.4
const AWAKEN_CRACK := 0.9
const AWAKEN_ROAR := 1.25
const AWAKEN_HOP := 1.6
# the roar at half health before the first charge
const ENRAGE_TIME := 1.6
const ENRAGE_BLAST := 0.55
# walkers are kept this far from his middle while he is off his plinths
const BODY_R := 56.0
# a charge knocks whoever is this close
const CHARGE_HIT_R := BODY_R + 8.0
# the last stand on his plinth: a swat at her this often, this far out
const LAST_SWAT_EVERY := 2.4
const LAST_SWAT_REACH := 210.0
# tied up, he teeters this long before he goes over
const WOBBLE_TIME := 1.1
const CARD_TIME := 3.4
const CARD_FROM := 0.3
# the camera leans toward him by this share of the gap, never past LEAN_MAX
const LEAN_MAX := 220.0
const LEAN_EASE := 3.0
const CRACKS_MAX := 12
const CRACK_LIFE := 9.0
const SHOUT_GAP := 2.6
const FIREWORKS := 7
const FIREWORK_GAP := 0.45

# --- State Machine -----------------------------------------------------------
enum State {
	IDLE,
	AWAKEN,
	ENRAGE,
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

# the show: none of it touches the fight's rules
var act_t := 0.0                # seconds into AWAKEN, ENRAGE or WRAPPED
var enraged := false
var flash := 0.0                # his bronze lit white by a hit
var screen_flash := 0.0
var spin_t := 0.0               # the tumble at the start of a stun
var hop_z := 0.0                # how high off the ground he is drawn
var plinth_cracked := false
var ls_swat_t := 0.0            # last stand: the paw's telegraph clock
var ls_swat_cd := LAST_SWAT_EVERY
var ghost_t := 0.0
var steam_t := 0.0
var lean := 0.0
var card_t := -1.0
var card: Control = null
var cheer := 0.0
var gasp := 0.0
var shout_cd := 0.0
var fireworks_left := 0
var firework_t := 0.0
var heart_t := 0.0
var ghosts: Array[Dictionary] = []
var bits: Array[Dictionary] = []
var cracks: Array[Dictionary] = []
var crowd: Array[Dictionary] = []
# sparks, crowd shouts and fireworks draw from their own generator, so the
# show never shifts the walk's shared random sequence
var fx := RandomNumberGenerator.new()

const SHIRTS: Array[Color] = [
	Color(0.85, 0.30, 0.28), Color(0.25, 0.45, 0.75), Color(0.95, 0.78, 0.30),
	Color(0.30, 0.62, 0.42), Color(0.62, 0.38, 0.70), Color(0.92, 0.92, 0.88),
	Color(0.22, 0.24, 0.30), Color(0.95, 0.55, 0.25),
]
const SKINS: Array[Color] = [
	Color(0.96, 0.80, 0.66), Color(0.82, 0.62, 0.46), Color(0.62, 0.42, 0.30),
	Color(0.45, 0.30, 0.22),
]
const HAIRS: Array[Color] = [
	Color(0.12, 0.09, 0.07), Color(0.35, 0.22, 0.12), Color(0.70, 0.55, 0.30),
	Color(0.55, 0.55, 0.55),
]
const CHEERS: Array[String] = ["Olé!", "Bravo!", "Get him, pup!", "Again!", "What a dog!"]
const GASPS: Array[String] = ["Look out!", "Oh no!", "Watch out, pup!", "Run!"]
const WINS: Array[String] = ["Bravo!", "Olé!", "Good dog!", "Nice kitty!"]
const FIRE_COLS: Array[Color] = [
	Color(1.0, 0.45, 0.35), Color(1.0, 0.85, 0.30), Color(0.45, 0.80, 1.0),
	Color(0.55, 1.0, 0.55), Color(1.0, 0.55, 0.95),
]

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
	ghosts.clear()
	bits.clear()
	cracks.clear()
	enraged = false
	plinth_cracked = false
	card_t = -1.0
	lean = 0.0
	leg_poles.clear()
	for off: Vector2 in LEG_OFFSETS:
		leg_poles.append(pos + off)
	fx.seed = 1907
	_build_crowd()


# The onlookers: a diner at each terrace table, and people lining the rambla
# by the start plinth and round the plaça, outside the walls. Drawn only.
func _build_crowd() -> void:
	crowd.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = 2701
	for tr: Rect2 in TERRACES:
		for r in range(3):
			for c in range(2):
				var tp := tr.position + Vector2(16.0 + float(c) * 44.0, 24.0 + float(r) * 48.0)
				_add_onlooker(rng, tp + Vector2(0.0, -15.0), true)
	for side: float in [-1.0, 1.0]:
		var x: float = 640.0 + side * (HALF + 22.0)
		var y := -260.0
		while y > -700.0:
			_add_onlooker(rng, Vector2(x + rng.randf_range(-7.0, 7.0), y), false)
			y -= rng.randf_range(34.0, 48.0)
		y = -4180.0
		while y > -4900.0:
			_add_onlooker(rng, Vector2(x + side * 40.0 + rng.randf_range(-8.0, 8.0), y), false)
			if rng.randf() < 0.5:
				_add_onlooker(rng, Vector2(x + side * 68.0 + rng.randf_range(-6.0, 6.0), y - 18.0), false)
			y -= rng.randf_range(30.0, 42.0)


func _add_onlooker(rng: RandomNumberGenerator, at: Vector2, seated: bool) -> void:
	crowd.append({
		"p": at,
		"shirt": SHIRTS[rng.randi() % SHIRTS.size()],
		"skin": SKINS[rng.randi() % SKINS.size()],
		"hair": HAIRS[rng.randi() % HAIRS.size()],
		"ph": rng.randf() * TAU,
		"seated": seated,
	})


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
	if hp < was:
		flash = 1.0
		_cheer_up()
	if hp <= MAX_HP * 0.5 and phase == 1:
		phase = 2
		main.feed.say("EL GAT IS FURIOUS!", EventFeed.Tone.LOUD)
		main.human.notice("Is that cat... running at us?", 2.2)
	if hp <= 0.0 and was > 0.0:
		main.feed.say("EL GAT HAS HAD ENOUGH! AFTER HIM", EventFeed.Tone.GOOD)


func transition_to(new_state: State) -> void:
	# whatever he was doing, out of fight he goes home to his plinth, and the
	# first time he is back on his feet below half he rears up first
	if new_state == State.PROWL and hp <= 0.0:
		new_state = State.RETREAT
	elif new_state == State.PROWL and phase == 2 and not enraged:
		new_state = State.ENRAGE
	state = new_state
	state_t = 0.0
	act_t = 0.0
	match new_state:
		State.AWAKEN:
			gasp = 1.0
			Sfx.play("drum", 0.7, -4.0)
			Sfx.play("ooooh", 0.9, -10.0)
			card_t = 0.0
			_ensure_card()
		State.ENRAGE:
			enraged = true
			face_dir = _to_dog_dir()
			Sfx.play("gat_roar", 0.8, -2.0)
			main.shake_t = maxf(float(main.shake_t), 0.7)
			gasp = 1.0
			_crowd_shout(GASPS)
		State.PROWL:
			face_dir = Vector2.DOWN
		State.SWAT:
			state_t = SWAT_WARN
			swat_paw_active = 1 - swat_paw_active
			var to_dog: Vector2 = main.dog.global_position - pos
			swat_pos = pos + to_dog.limit_length(110.0)
			face_dir = to_dog.normalized() if to_dog.length() > 1.0 else Vector2.DOWN
			dust_rings.append({"pos": swat_pos, "r": SWAT_RADIUS, "life": SWAT_WARN, "max_life": SWAT_WARN, "warn": true})
		State.CHARGE_WARN:
			state_t = SWAT_WARN
			Sfx.play("gat_roar", 1.1, -4.0)
			charge_dir = _to_dog_dir()
			face_dir = charge_dir
			charge_lane_end = pos + charge_dir * CHARGE_SPEED * CHARGE_TIME
			dust_rings.append({"pos": pos, "r": 36.0, "life": SWAT_WARN, "max_life": SWAT_WARN})
			main.shake_t = maxf(float(main.shake_t), 0.3)
			gasp = 1.0
			_crowd_shout(GASPS)
		State.CHARGE:
			state_t = CHARGE_TIME
			charge_hit_done = false
			charge_from_obstacle = check_obstacle_collision()
			ghost_t = 0.0
			Sfx.play("fling", 0.7, -4.0)
		State.STUNNED:
			state_t = STUN_TIME
			stun_booped = false
			stun_pummeled = false
			spin_t = 0.5
			Sfx.play("groan", 1.0, -5.0)
			main.shake_t = maxf(float(main.shake_t), 0.6)
			_burst(pos + face_dir * 40.0, 14, Color(1.0, 0.9, 0.45), 180.0, 380.0, 2.5, 0.35, true)
		State.RETREAT:
			face_dir = (PEDESTAL_POS - pos).normalized() if pos.distance_to(PEDESTAL_POS) > 1.0 else Vector2.DOWN
			_crowd_shout(CHEERS)
		State.ROAR:
			pos = PEDESTAL_POS
			update_leg_positions()
			face_dir = Vector2.DOWN
			legs_tied = 0
			leg_touch_t = [-INF, -INF, -INF, -INF]
			ls_swat_t = 0.0
			ls_swat_cd = LAST_SWAT_EVERY
			Sfx.play("gat_roar", 0.95, -3.0)
			main.shake_t = maxf(float(main.shake_t), 0.6)
			main.feed.say("TIE UP HIS LEGS!", EventFeed.Tone.LOUD)
			# back up on his plinth with a thump
			for d_rad in [70.0, 130.0]:
				dust_rings.append({"pos": pos, "r": d_rad, "life": 0.7, "max_life": 0.7})
			_burst(pos, 16, STONE_DARK, 90.0, 260.0, 3.5, 0.6, false, 260.0)
			_scatter_pigeons(pos, 240.0)
		State.WRAPPED:
			state_t = WOBBLE_TIME
			ls_swat_t = 0.0
			Sfx.play("intro_taut", 0.9, -5.0)
			Sfx.play("groan", 1.1, -5.0)
			Sfx.play("ooooh", 1.0, -8.0)
			main.shake_t = maxf(float(main.shake_t), 0.8)
			gasp = 1.0
		State.TOPPLED:
			snout_pos = pos + Vector2(-54.0, -18.0)
			Sfx.play("crack", 0.6, -3.0)
			Sfx.play("gat_clang", 0.8, -2.0)
			Sfx.play("whoop", 1.0, -6.0)
			main.gat_toppled = true
			main.shake_t = 1.4
			main.feed.say("EL GAT IS DOWN!", EventFeed.Tone.LOUD)
			for d_rad in [40.0, 90.0, 150.0, 230.0]:
				dust_rings.append({"pos": pos, "r": d_rad, "life": 0.8, "max_life": 0.8})
			_burst(pos, 26, STONE_DARK, 120.0, 340.0, 4.0, 0.8, false, 300.0)
			_burst(pos + Vector2(-40.0, 0.0), 18, Color(1.0, 0.9, 0.45), 200.0, 460.0, 2.5, 0.4, true)
			_scatter_pigeons(pos, 900.0)
			screen_flash = 0.7
			_big_hit()
			_cheer_up()
			_crowd_shout(CHEERS)
		State.PURR:
			pos = PEDESTAL_POS
			update_leg_positions()
			Sfx.play("gat_purr", 1.0, -4.0)
			Sfx.play("star", 1.1)
			Sfx.play("whoop", 1.1, -4.0)
			main.gat_booped = true
			main.combo.add("BOOP", 10)
			main.float_text(snout_pos, "booped! +10", Color(1.0, 0.88, 0.25))
			main.feed.say("THE RAMBLA IS YOURS!", EventFeed.Tone.GOOD)
			main.human.say_line("Nice kitty.")
			cheer = 1.0
			fireworks_left = FIREWORKS
			firework_t = 0.15
			heart_t = 0.0
			shout_cd = 0.0
			_crowd_shout(WINS)
			var cols: Array[Color] = [Color(0.96, 0.35, 0.30), Color(0.95, 0.80, 0.25), Color(0.25, 0.65, 0.95), Color(0.35, 0.85, 0.40)]
			for i in range(48):
				var ang := TAU * float(i) / 48.0
				var spd := fx.randf_range(80.0, 240.0)
				confetti.append({"pos": pos, "vel": Vector2(cos(ang), sin(ang)) * spd, "col": cols[i % 4], "life": 3.0})


func execute_swat() -> void:
	Sfx.play("crack", 0.8, -6.0)
	main.shake_t = maxf(float(main.shake_t), 0.4)
	var dog_p: Vector2 = main.dog.global_position
	var d_dist: float = dog_p.distance_to(swat_pos)
	if d_dist <= SWAT_RADIUS:
		var dir: Vector2 = (dog_p - swat_pos).normalized() if d_dist > 1.0 else Vector2.DOWN
		main.dog.knocked(dir, "paw")
	elif d_dist < SWAT_REACH and hp > 0.0:
		# the last stand's swats are only to dodge: out of fight they pay nothing
		main.gat_swats_dodged += 1
		main.combo.add("DODGE", 2)
		main.float_text(swat_pos, "dodged! +2", Color(0.8, 1.0, 0.7))
		damage_boss(DODGE_DAMAGE)
	if main.human.global_position.distance_to(swat_pos) <= SWAT_RADIUS:
		main.human.bumped((main.human.global_position - swat_pos).normalized())
	_scatter_pigeons(swat_pos, 180.0)
	# the paw leaves the paving cracked
	cracks.append({"p": swat_pos, "a": fx.randf() * TAU, "life": CRACK_LIFE})
	if cracks.size() > CRACKS_MAX:
		cracks.remove_at(0)
	dust_rings.append({"pos": swat_pos, "r": SWAT_RADIUS * 1.6, "life": 0.45, "max_life": 0.45})
	_burst(swat_pos, 10, STONE_DARK, 80.0, 220.0, 3.0, 0.5, false, 240.0)
	_burst(swat_pos, 8, Color(1.0, 0.85, 0.4), 160.0, 320.0, 2.0, 0.25, true)


func _to_dog_dir() -> Vector2:
	var to_dog: Vector2 = main.dog.global_position - pos
	return to_dog.normalized() if to_dog.length() > 1.0 else Vector2.DOWN


# Bits thrown from a point: stone chips and dust (lob > 0 throws them up and
# they fall back), sparks (drawn as streaks), leaves, steam.
func _burst(at: Vector2, n: int, col: Color, spd_lo: float, spd_hi: float,
		r: float, life: float, spark := false, lob := 0.0) -> void:
	for i in range(n):
		var ang := fx.randf() * TAU
		var spd := fx.randf_range(spd_lo, spd_hi)
		bits.append({
			"p": at, "v": Vector2(cos(ang), sin(ang)) * spd * (0.55 if lob > 0.0 else 1.0),
			"z": 0.0, "vz": fx.randf_range(0.5, 1.0) * lob,
			"life": life * fx.randf_range(0.7, 1.0), "max": life,
			"col": col, "r": r, "spark": spark,
		})


# A beat of slow motion for the hits that matter. The bot playing the soak
# never fights him.
func _big_hit() -> void:
	if main.auto_walk:
		return
	main._slowmo()


func _cheer_up() -> void:
	cheer = 1.0
	gasp = 0.0
	Sfx.play("whoop", fx.randf_range(0.9, 1.15), -12.0)
	_crowd_shout(CHEERS)


# One of the onlookers near the dog calls out, now and then.
func _crowd_shout(lines: Array[String]) -> void:
	if shout_cd > 0.0 or crowd.is_empty():
		return
	var dog_p: Vector2 = main.dog.global_position
	var best := -1
	var best_d := 560.0
	var start := fx.randi() % crowd.size()
	for k in range(crowd.size()):
		var i := (start + k) % crowd.size()
		var d: float = (crowd[i].p as Vector2).distance_to(dog_p)
		if d < best_d and d > 90.0:
			best_d = d
			best = i
			if d < 420.0:
				break
	if best < 0:
		return
	shout_cd = SHOUT_GAP
	main.float_text(crowd[best].p + Vector2(0.0, -14.0), lines[fx.randi() % lines.size()],
			Color(1.0, 1.0, 1.0), main.POP_SAY)


# Keeps a walker out of his body while he is down on the paving.
func _shove_out(body: Node2D) -> void:
	var d: Vector2 = body.global_position - pos
	var l := d.length()
	if l >= BODY_R:
		return
	var n: Vector2 = d / l if l > 0.5 else Vector2.DOWN
	var to: Vector2 = pos + n * BODY_R
	# never into a bench, a terrace or a palm trunk: pinned there, she would be stuck
	for r: Rect2 in main.solid_rects:
		if r.grow(14.0).has_point(to):
			return
	for palm: Vector2 in PALMS:
		if to.distance_squared_to(palm) < (main.POLE_RADIUS + 14.0) * (main.POLE_RADIUS + 14.0):
			return
	body.global_position = to


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
	_burst(pos, 16, Color(1.0, 0.9, 0.45), 200.0, 420.0, 2.5, 0.4, true)
	screen_flash = 0.35
	_big_hit()


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
	_tick_show(delta)

	_hold_human()
	var dog_p: Vector2 = main.dog.global_position
	act_t += delta

	match state:
		State.IDLE:
			if dog_p.y < WAKE_Y:
				transition_to(State.AWAKEN)

		State.AWAKEN:
			var was := act_t - delta
			if was < AWAKEN_CRACK and act_t >= AWAKEN_CRACK:
				plinth_cracked = true
				Sfx.play("crack", 0.7, -3.0)
				main.shake_t = maxf(float(main.shake_t), 0.5)
				_burst(START_PLINTH, 18, STONE_DARK, 90.0, 260.0, 4.0, 0.7, false, 280.0)
			if was < AWAKEN_ROAR and act_t >= AWAKEN_ROAR:
				Sfx.play("gat_roar", 0.9, -1.0)
				main.shake_t = maxf(float(main.shake_t), 0.9)
				for d_rad in [90.0, 180.0, 300.0]:
					dust_rings.append({"pos": pos, "r": d_rad, "life": 0.9, "max_life": 0.9})
				_scatter_pigeons(pos, 260.0)
				main.human.notice("Huh, big cat today...", 2.2)
			# rears up, then hops down off the front of his plinth
			var from := START_PLINTH
			var to := START_PLINTH + Vector2(0.0, -PLINTH_HALF.y - 34.0)
			if act_t < AWAKEN_HOP:
				hop_z = minf(act_t / AWAKEN_ROAR, 1.0) * 12.0
			else:
				var k := clampf((act_t - AWAKEN_HOP) / (AWAKEN_TIME - AWAKEN_HOP - 0.2), 0.0, 1.0)
				pos = from.lerp(to, k)
				hop_z = 12.0 * (1.0 - k) + sin(k * PI) * 46.0
				if k >= 1.0 and was < AWAKEN_TIME - 0.2:
					Sfx.play("gat_clang", 0.7, -4.0)
					main.shake_t = maxf(float(main.shake_t), 0.5)
					dust_rings.append({"pos": pos, "r": 80.0, "life": 0.6, "max_life": 0.6})
					_burst(pos, 12, DUST_COLOR, 60.0, 180.0, 4.0, 0.6, false, 120.0)
				update_leg_positions()
			if act_t >= AWAKEN_TIME:
				hop_z = 0.0
				transition_to(State.PROWL)

		State.ENRAGE:
			face_dir = face_dir.slerp(_to_dog_dir(), minf(4.0 * delta, 1.0)).normalized()
			hop_z = sin(clampf(act_t / ENRAGE_TIME, 0.0, 1.0) * PI) * 16.0
			if act_t - delta < ENRAGE_BLAST and act_t >= ENRAGE_BLAST:
				main.shake_t = maxf(float(main.shake_t), 1.0)
				for d_rad in [80.0, 160.0, 260.0]:
					dust_rings.append({"pos": pos, "r": d_rad, "life": 0.8, "max_life": 0.8})
				_burst(pos, 24, Color(1.0, 0.55, 0.3), 260.0, 420.0, 3.0, 0.4, true)
				_scatter_pigeons(pos, 500.0)
				screen_flash = 0.25
			if act_t >= ENRAGE_TIME:
				hop_z = 0.0
				# the first charge comes soon after
				charge_cooldown = 0.6
				transition_to(State.PROWL)

		State.PROWL:
			swat_cooldown -= delta
			charge_cooldown -= delta
			# north only, LEAD ahead of your human, never past his plinth
			var want_y := maxf(minf(pos.y, main.human.global_position.y - LEAD), PEDESTAL_POS.y)
			# she is right against him: he does not walk into her
			var against := dog_p.distance_to(pos) < BODY_R + 24.0
			if against and dog_p.y < pos.y:
				want_y = pos.y
			var spd := CATCH_SPEED if pos.y - want_y > 120.0 else PROWL_SPEED
			pos.y = move_toward(pos.y, want_y, spd * delta)
			# between the palm rows, clear of the terraces
			var want_x := clampf(dog_p.x, CORRIDOR_L + 130.0, CORRIDOR_R - 130.0)
			if not against:
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
				screen_flash = 0.35
				_big_hit()
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
				# the palm sheds a few fronds' worth of leaves
				_burst(pos + charge_dir * 40.0, 12, PALM_LEAF_LIGHT, 60.0, 200.0, 4.0, 1.1, false, 200.0)
				screen_flash = 0.3
				_big_hit()
				transition_to(State.STUNNED)
				return

			if check_human_pummel():
				_pummel()
				transition_to(State.STUNNED)
				# the same fling is still in reach next frame: one pummel each
				stun_pummeled = true
				return

			# one knock per charge, however long she stays in front of him
			if not charge_hit_done and dog_p.distance_to(pos) < CHARGE_HIT_R:
				charge_hit_done = true
				main.dog.knocked(charge_dir, "charge")
			if main.human.global_position.distance_to(pos) < CHARGE_HIT_R:
				main.human.bumped(charge_dir)
			ghost_t -= delta
			if ghost_t <= 0.0:
				ghost_t = 0.05
				ghosts.append({"p": pos, "f": face_dir, "life": 0.3})
				_burst(pos - charge_dir * 50.0, 2, DUST_COLOR, 30.0, 90.0, 5.0, 0.5)

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
			_tick_last_stand(delta, dog_p)
			update_leg_tangle()

		State.WRAPPED:
			state_t -= delta
			if state_t <= 0.0:
				transition_to(State.TOPPLED)

		State.PURR:
			purr_vibe = sin(AnimClock.msec() * 0.035) * 1.5
			firework_t -= delta
			if fireworks_left > 0 and firework_t <= 0.0:
				fireworks_left -= 1
				firework_t = FIREWORK_GAP
				_firework()
			heart_t -= delta
			if heart_t <= 0.0 and act_t < 5.0:
				heart_t = 0.45
				bits.append({"p": pos + Vector2(fx.randf_range(-30.0, 30.0), -40.0),
					"v": Vector2(fx.randf_range(-15.0, 15.0), -55.0), "z": 0.0, "vz": 0.0,
					"life": 1.6, "max": 1.6, "col": Color(1.0, 0.45, 0.55), "r": 7.0,
					"spark": false, "heart": true})

	# solid off his plinths, where the plinth itself keeps walkers off. The
	# autowalk bot cannot fight him and is not held, so he would stand in
	# its way in the plaça for ever: to the bot he is a ghost.
	if not main.auto_walk and state in [State.PROWL, State.SWAT, State.CHARGE_WARN, State.CHARGE,
			State.STUNNED, State.RETREAT, State.ENRAGE]:
		_shove_out(main.dog)
		if not main.human.is_whirling():
			_shove_out(main.human)


# On his plinth with no fight left, he still swats at her while she ties him.
func _tick_last_stand(delta: float, dog_p: Vector2) -> void:
	face_dir = face_dir.slerp(_to_dog_dir(), minf(3.0 * delta, 1.0)).normalized()
	if ls_swat_t > 0.0:
		ls_swat_t -= delta
		if ls_swat_t <= 0.0:
			execute_swat()
		return
	ls_swat_cd -= delta
	if ls_swat_cd <= 0.0 and dog_p.distance_to(pos) < LAST_SWAT_REACH:
		ls_swat_cd = LAST_SWAT_EVERY
		ls_swat_t = SWAT_WARN
		swat_paw_active = 1 - swat_paw_active
		swat_pos = pos + (dog_p - pos).limit_length(120.0)
		dust_rings.append({"pos": swat_pos, "r": SWAT_RADIUS, "life": SWAT_WARN, "max_life": SWAT_WARN, "warn": true})


func _firework() -> void:
	# over the plaça, in the part of it the camera holds
	var at := PEDESTAL_POS + Vector2(fx.randf_range(-260.0, 260.0), fx.randf_range(-200.0, 60.0))
	var col: Color = FIRE_COLS[fx.randi() % FIRE_COLS.size()]
	var col2: Color = FIRE_COLS[fx.randi() % FIRE_COLS.size()].lightened(0.4)
	Sfx.play("cracker", fx.randf_range(0.85, 1.2), -6.0)
	for i in range(40):
		var ang := TAU * float(i) / 40.0
		var spd := fx.randf_range(240.0, 330.0) if i % 2 == 0 else fx.randf_range(120.0, 180.0)
		bits.append({"p": at, "v": Vector2(cos(ang), sin(ang)) * spd, "z": 0.0, "vz": 0.0,
			"life": 1.2, "max": 1.2, "col": col if i % 2 == 0 else col2, "r": 4.0,
			"spark": true, "drag": 1.8})
	bits.append({"p": at, "v": Vector2.ZERO, "z": 0.0, "vz": 0.0, "life": 0.3, "max": 0.3,
		"col": Color(1.0, 1.0, 0.92, 0.9), "r": 26.0, "spark": false})
	dust_rings.append({"pos": at, "r": 110.0, "life": 0.45, "max_life": 0.45, "col": col})


# Everything that is only for show: the particles, the flashes, the crowd's
# mood, the title card and the camera's lean.
func _tick_show(delta: float) -> void:
	flash = maxf(0.0, flash - delta * 5.0)
	screen_flash = maxf(0.0, screen_flash - delta * 2.5)
	spin_t = maxf(0.0, spin_t - delta)
	cheer = maxf(0.0, cheer - delta * (0.25 if state == State.PURR else 0.6))
	gasp = maxf(0.0, gasp - delta * 0.8)
	shout_cd = maxf(0.0, shout_cd - delta)
	for i in range(bits.size() - 1, -1, -1):
		var b: Dictionary = bits[i]
		b.life -= delta
		if b.life <= 0.0:
			bits.remove_at(i)
			continue
		b.p += b.v * delta
		b.v *= exp(-float(b.get("drag", 1.5)) * delta)
		if b.vz != 0.0 or b.z > 0.0:
			b.vz -= 900.0 * delta
			b.z = maxf(0.0, b.z + b.vz * delta)
			if b.z <= 0.0:
				b.vz = 0.0
	for i in range(ghosts.size() - 1, -1, -1):
		ghosts[i].life -= delta
		if ghosts[i].life <= 0.0:
			ghosts.remove_at(i)
	for i in range(cracks.size() - 1, -1, -1):
		cracks[i].life -= delta
		if cracks[i].life <= 0.0:
			cracks.remove_at(i)
	# steam from his nose while he is furious
	if phase == 2 and hp > 0.0 and state in [State.PROWL, State.CHARGE_WARN, State.ENRAGE]:
		steam_t -= delta
		if steam_t <= 0.0:
			steam_t = 0.7
			var nose := pos + face_dir * 74.0
			for sd: float in [-1.0, 1.0]:
				bits.append({"p": nose + face_dir.orthogonal() * sd * 6.0,
					"v": (face_dir + face_dir.orthogonal() * sd * 0.8) * 110.0, "z": 0.0, "vz": 0.0,
					"life": 0.6, "max": 0.6, "col": Color(0.92, 0.92, 0.95, 0.30), "r": 4.0,
					"spark": false, "grow": true})
	if card_t >= 0.0:
		card_t += delta
		if card_t > CARD_TIME + CARD_FROM:
			card_t = -1.0
	if card != null and is_instance_valid(card):
		card.queue_redraw()
	# the camera leans toward him while he is the thing to watch
	var want := 0.0
	var mid: float = (main.dog.global_position.y + main.human.global_position.y) * 0.5
	match state:
		State.AWAKEN:
			want = (pos.y - mid) * 0.55
		State.ENRAGE, State.WRAPPED:
			want = (pos.y - mid) * 0.35
		State.TOPPLED, State.PURR:
			if act_t < 2.5:
				want = (pos.y - mid) * 0.35
	want = clampf(want, -LEAN_MAX, LEAN_MAX)
	lean = lerpf(lean, want, 1.0 - exp(-LEAN_EASE * delta))


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
	var fight := fight_status()
	if fight != "":
		return fight
	if not beaten() and main.human.tut_hold_y == HOLD_Y and main.human.global_position.y < HOLD_Y + 40.0:
		return "YOUR HUMAN WON'T PASS HIM. DEAL WITH EL GAT"
	return ""


# The beat of the fight that needs the dog now: it outranks the bladder and
# the reel's banners, which return once the beat is over.
func fight_status() -> String:
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
		State.ENRAGE:
			return "EL GAT IS FURIOUS! GET CLEAR" if near else ""
		State.ROAR:
			return "WRAP THE LEASH AROUND HIS LEGS  %d/%d" % [legs_tied, LEGS_TO_TIE]
		State.TOPPLED:
			return Prompts.fill("HE'S DOWN! {bark} ON HIS SNOUT")
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


static func urgent_status(m: Node2D) -> String:
	if m.lvl != "raval" or m.boss_gat == null:
		return ""
	return m.boss_gat.fight_status()


# his title card runs across the top of the screen, where the banner sits
static func hush_banner(m: Node2D) -> bool:
	if m.lvl != "raval" or m.boss_gat == null:
		return false
	var k: float = m.boss_gat.card_t
	return k >= CARD_FROM and k <= CARD_TIME + CARD_FROM


static func cam_lean(m: Node2D) -> float:
	if m.lvl != "raval" or m.boss_gat == null:
		return 0.0
	return m.boss_gat.lean


# --- The title card and the flash, over the world ----------------------------

func _ensure_card() -> void:
	if card != null or main.hud == null:
		return
	card = Control.new()
	card.set_anchors_preset(Control.PRESET_FULL_RECT)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main.hud.add_child(card)
	# under the pause dim and the menus
	if main.dim != null:
		main.hud.move_child(card, main.dim.get_index())
	card.draw.connect(_draw_card)


func _draw_card() -> void:
	var vs: Vector2 = card.size
	if screen_flash > 0.0:
		card.draw_rect(Rect2(Vector2.ZERO, vs), Color(1.0, 0.97, 0.88, screen_flash * 0.55))
	if card_t < CARD_FROM:
		return
	var k := card_t - CARD_FROM
	# slides in from the left, holds, slides out to the right
	var slide := 0.0
	if k < 0.35:
		slide = -(1.0 - ease(k / 0.35, 0.4)) * vs.x
	elif k > CARD_TIME - 0.35:
		slide = ease((k - CARD_TIME + 0.35) / 0.35, 2.5) * vs.x
	# across the top, where the banner sits: the pair stands low on screen and
	# El Gat mid-screen, and a sideways phone gets a slimmer band
	var u := clampf(vs.y / 720.0, 0.5, 1.0)
	var cy := 64.0 * u
	var band := Rect2(Vector2(slide, cy - 58.0 * u), Vector2(vs.x, 116.0 * u))
	card.draw_rect(band, Color(0.06, 0.05, 0.05, 0.82))
	card.draw_rect(Rect2(band.position, Vector2(vs.x, 5.0 * u)), BRONZE_LIT)
	card.draw_rect(Rect2(band.position + Vector2(0.0, band.size.y - 5.0 * u), Vector2(vs.x, 5.0 * u)), BRONZE_LIT)
	Kit.heading(card, Vector2(slide, cy - 34.0 * u), "RAMBLA DEL RAVAL", int(18.0 * u), Color(0.86, 0.72, 0.52),
		HORIZONTAL_ALIGNMENT_CENTER, vs.x)
	Kit.heading(card, Vector2(slide, cy + 18.0 * u), "EL GAT DE BOTERO", int(52.0 * u), EYE_AMBER,
		HORIZONTAL_ALIGNMENT_CENTER, vs.x)
	var gloss := "Botero's cat, and he is awake"
	var gs := int(20.0 * u)
	var gw: float = Kit.text_w(Kit.body(), gloss, gs)
	card.draw_string(Kit.body(), Vector2(slide + (vs.x - gw) * 0.5, cy + 46.0 * u), gloss,
		HORIZONTAL_ALIGNMENT_LEFT, -1, gs, Color(0.92, 0.88, 0.80))


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
	var t: float = AnimClock.msec() / 1000.0
	gat.draw_ground_marks(c, vt, vb)
	gat.draw_crowd(c, vt, vb, t)
	if gat.pos.y > vt - 240.0 and gat.pos.y < vb + 240.0:
		gat.draw_gat(c, t)
	gat.draw_bits(c, vt, vb)


# The cracked plinth he left and the paving his paws cracked.
func draw_ground_marks(c: Object, vt: float, vb: float) -> void:
	var sb := ShapeBatch.new()
	var crack_col := Color(0.22, 0.20, 0.18, 0.75)
	if plinth_cracked and START_PLINTH.y > vt - 100.0 and START_PLINTH.y < vb + 100.0:
		var p := START_PLINTH
		sb.line(p + Vector2(-40, -30), p + Vector2(-8, -4), crack_col, 2.5)
		sb.line(p + Vector2(-8, -4), p + Vector2(14, -22), crack_col, 2.0)
		sb.line(p + Vector2(-8, -4), p + Vector2(4, 26), crack_col, 2.0)
		sb.line(p + Vector2(4, 26), p + Vector2(34, 18), crack_col, 1.5)
		sb.line(p + Vector2(14, -22), p + Vector2(42, -34), crack_col, 1.5)
		sb.rect(Rect2(p + Vector2(30, -40), Vector2(22, 14)), Color(0.48, 0.46, 0.43))
	for cr: Dictionary in cracks:
		var cp: Vector2 = cr.p
		if cp.y < vt - 60.0 or cp.y > vb + 60.0:
			continue
		var a: float = cr.a
		var col := Color(crack_col.r, crack_col.g, crack_col.b, crack_col.a * minf(float(cr.life) / 1.5, 1.0))
		for i in range(5):
			var d := Vector2.from_angle(a + float(i) * (TAU / 5.0) + sin(float(i) * 3.1) * 0.4)
			var mid := cp + d * (12.0 + float(i % 2) * 8.0)
			sb.line(cp, mid, col, 2.5)
			sb.line(mid, mid + d.rotated(0.6 - float(i % 3) * 0.5) * 14.0, col, 1.5)
		sb.circle(cp, 7.0, Color(col.r, col.g, col.b, col.a * 0.6))
	sb.flush(c)


# The onlookers: they lean away when he swats or charges, and jump with their
# arms up when she lands one on him.
func draw_crowd(c: Object, vt: float, vb: float, t: float) -> void:
	var sb := ShapeBatch.new()
	for pp: Dictionary in crowd:
		var p: Vector2 = pp.p
		if p.y < vt - 40.0 or p.y > vb + 40.0:
			continue
		var ph: float = pp.ph
		var away := Vector2(signf(p.x - pos.x), 0.0)
		var jump := absf(sin(t * 9.0 + ph)) * 7.0 * cheer
		var at := p + away * gasp * 4.0 + Vector2(0.0, -jump + sin(t * 1.3 + ph) * 0.6)
		sb.circle(p + LIGHT * 3.0, 9.0, SHADOW)
		var shirt: Color = pp.shirt
		var skin: Color = pp.skin
		if cheer > 0.3 or gasp > 0.5:
			# both arms up, hands on high
			var up := 14.0 if cheer > 0.3 else 9.0
			for sd: float in [-1.0, 1.0]:
				var hand := at + Vector2(sd * (9.0 + sin(t * 12.0 + ph) * 2.0 * cheer), -up)
				sb.line(at + Vector2(sd * 6.0, -2.0), hand, shirt, 4.0)
				sb.circle(hand, 2.6, skin)
		sb.circle(at, 9.0 if not pp.seated else 8.0, shirt.darkened(0.25))
		sb.circle(at - LIGHT * 1.2, 7.6 if not pp.seated else 6.6, shirt)
		sb.circle(at + Vector2(0.0, -2.0), 5.4, skin)
		sb.circle(at + Vector2(0.0, -3.4), 4.6, pp.hair)
	sb.flush(c)


func draw_bits(c: Object, vt: float, vb: float) -> void:
	var sb := ShapeBatch.new()
	for cf in confetti:
		sb.rect(Rect2(cf.pos.x - 3.0, cf.pos.y - 3.0, 6.0, 6.0), cf.col)
	for b: Dictionary in bits:
		var p: Vector2 = b.p
		if p.y < vt - 80.0 or p.y > vb + 80.0:
			continue
		var f: float = clampf(float(b.life) / float(b.max), 0.0, 1.0)
		var col: Color = b.col
		col.a *= minf(f * 2.0, 1.0)
		var at := p - Vector2(0.0, float(b.z))
		if b.spark:
			sb.line(at, at - (b.v as Vector2) * 0.035, col, float(b.r))
		elif b.has("heart"):
			var r: float = b.r
			sb.circle(at + Vector2(-r * 0.5, 0.0), r * 0.6, col)
			sb.circle(at + Vector2(r * 0.5, 0.0), r * 0.6, col)
			sb.circle(at + Vector2(0.0, r * 0.5), r * 0.55, col)
		else:
			if b.z > 0.0:
				sb.circle(p + LIGHT * 2.0, float(b.r) * 0.8, SHADOW)
			var r: float = float(b.r) * ((2.2 - f * 1.2) if b.has("grow") else (0.5 + f * 0.5))
			sb.circle(at, r, col)
	sb.flush(c)


func draw_gat(c: Object, t: float) -> void:
	var cur_pos := pos + Vector2(0, purr_vibe)
	# tied up, he teeters harder and harder until he goes over
	if state == State.WRAPPED:
		var k := clampf(act_t / WOBBLE_TIME, 0.0, 1.0)
		cur_pos.x += sin(act_t * 16.0) * (3.0 + k * 12.0)
	elif state == State.CHARGE_WARN:
		# hunkers back, haunches up, before he goes
		var k := 1.0 - clampf(state_t / SWAT_WARN, 0.0, 1.0)
		cur_pos -= charge_dir * 10.0 * k
		cur_pos.x += sin(t * 60.0) * 1.5 * k

	if state == State.CHARGE_WARN:
		var warn_pulse: float = 0.30 + sin(t * 14.0) * 0.12
		var lane_col := Color(1.0, 0.25, 0.15, warn_pulse)
		var side := charge_dir.orthogonal()
		c.draw_line(pos, charge_lane_end, lane_col, 34.0)
		c.draw_line(pos + side * 17.0, charge_lane_end + side * 17.0, Color(1.0, 0.3, 0.2, 0.6), 2.0)
		c.draw_line(pos - side * 17.0, charge_lane_end - side * 17.0, Color(1.0, 0.3, 0.2, 0.6), 2.0)
		# chevrons running down the lane, the way he will come
		var lane_len := pos.distance_to(charge_lane_end)
		var scroll := fmod(t * 260.0, 60.0)
		var d := 40.0 + scroll
		while d < lane_len - 10.0:
			var cp := pos + charge_dir * d
			var chev_col := Color(1.0, 0.85, 0.75, 0.75 * (1.0 - d / lane_len))
			c.draw_line(cp - side * 11.0 - charge_dir * 8.0, cp, chev_col, 3.0)
			c.draw_line(cp + side * 11.0 - charge_dir * 8.0, cp, chev_col, 3.0)
			d += 60.0
		c.draw_circle(charge_lane_end, 22.0, lane_col)

	# afterimages behind a charge
	for g: Dictionary in ghosts:
		var a: float = float(g.life) / 0.3 * 0.35
		c.draw_colored_polygon(Clay.ellipse_pts(g.p, Vector2(62.0, 52.0), g.f, 14),
			Color(BRONZE_LIT.r, BRONZE_LIT.g, BRONZE_LIT.b, a))
		c.draw_circle(g.p + (g.f as Vector2) * 38.0, 34.0, Color(BRONZE_LIT.r, BRONZE_LIT.g, BRONZE_LIT.b, a))

	if state == State.TOPPLED:
		draw_toppled_gat(c, cur_pos, t)
	else:
		draw_upright_gat(c, cur_pos, t)

	if state != State.IDLE and state != State.AWAKEN and hp > 0.0:
		draw_boss_health_bar(c, cur_pos - Vector2(0.0, hop_z))

	# the strokes last, together: each arc goes straight to the canvas
	for dr in dust_rings:
		var frac: float = 1.0 - (float(dr.life) / maxf(float(dr.max_life), 0.01))
		if dr.get("warn", false):
			# where the paw will land: the ring holds still and fills to it
			var wr: float = dr.r
			c.draw_circle(dr.pos, wr * frac, Color(1.0, 0.35, 0.2, 0.18 + 0.22 * frac))
			c.draw_arc(dr.pos, wr, 0.0, TAU, 32, Color(1.0, 0.4, 0.25, 0.55 + 0.4 * frac), 3.0)
			continue
		var r: float = float(dr.r) * (0.3 + frac * 0.7)
		var base: Color = dr.get("col", DUST_COLOR)
		c.draw_arc(dr.pos, r, 0.0, TAU, 32, Color(base.r, base.g, base.b, (1.0 - frac) * 0.6), 4.0)
	if state == State.ROAR:
		var ring_col := Color(0.98, 0.85, 0.30, 0.35 + sin(t * 8.0) * 0.15)
		c.draw_arc(cur_pos, 92.0, 0.0, TAU, 40, ring_col, 3.0)
	if state == State.ROAR or state == State.WRAPPED:
		for k in range(leg_poles.size()):
			if main.elapsed - leg_touch_t[k] <= LEG_MEMORY or state == State.WRAPPED:
				c.draw_arc(leg_poles[k], LEG_RADIUS + 6.0, 0.0, TAU, 20, Color(1.0, 0.90, 0.20, 0.9), 3.0)


func draw_boss_health_bar(c: Object, at: Vector2) -> void:
	var bar_w := 150.0
	var bar_h := 10.0
	var bar_pos := at + Vector2(-bar_w * 0.5, -104.0)
	c.draw_rect(Rect2(bar_pos + LIGHT * 3.0, Vector2(bar_w, bar_h)), SHADOW)
	c.draw_rect(Rect2(bar_pos - Vector2(2.0, 2.0), Vector2(bar_w + 4.0, bar_h + 4.0)), BRONZE_DARK)
	c.draw_rect(Rect2(bar_pos - Vector2(1.0, 1.0), Vector2(bar_w + 2.0, bar_h + 2.0)), BRONZE_LIT)
	c.draw_rect(Rect2(bar_pos, Vector2(bar_w, bar_h)), Color(0.10, 0.08, 0.07))
	var hp_frac := clampf(hp / max_hp, 0.0, 1.0)
	if hp_frac > 0.0:
		var fill_col := Color(0.96, 0.32, 0.22) if phase == 2 else Color(0.96, 0.74, 0.18)
		fill_col = fill_col.lerp(Color.WHITE, flash * 0.7)
		var fill := Rect2(bar_pos + Vector2(1, 1), Vector2((bar_w - 2.0) * hp_frac, bar_h - 2.0))
		c.draw_rect(fill, fill_col)
		c.draw_rect(Rect2(fill.position, Vector2(fill.size.x, 2.0)), fill_col.lightened(0.35))
	# the notch where he loses his temper
	c.draw_rect(Rect2(bar_pos + Vector2(bar_w * 0.5 - 1.0, -2.0), Vector2(2.0, bar_h + 4.0)), BRONZE_DARK)
	var f: Font = Kit.display()
	var label := "EL GAT"
	var tw: float = Kit.text_w(f, label, 14)
	var tp := bar_pos + Vector2((bar_w - tw) * 0.5, -5.0)
	c.draw_string_outline(f, tp, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, 4, Color(0.05, 0.04, 0.04, 0.85))
	c.draw_string(f, tp, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, EYE_AMBER)


func draw_upright_gat(c: Object, ground: Vector2, t: float) -> void:
	Clay.ground_shadow(c, ground, 80.0 - hop_z * 0.3, 62.0 - hop_z * 0.25, 6.0, 0.30)
	var at := ground - Vector2(0.0, hop_z)
	# a hit lights his bronze; below half the metal runs hot
	var hot := 0.12 if phase == 2 and hp > 0.0 else 0.0
	var base := BRONZE_BASE.lerp(Color(0.62, 0.26, 0.14), hot).lerp(Color.WHITE, flash * 0.55)
	var dark := BRONZE_DARK.lerp(Color.WHITE, flash * 0.4)
	var lit := BRONZE_LIT.lerp(Color.WHITE, flash * 0.5)
	# the tumble at the start of a stun turns him a full circle
	var face := face_dir.rotated(TAU * (spin_t / 0.5)) if spin_t > 0.0 else face_dir

	for leg: Vector2 in leg_poles:
		var lp := leg + (at - pos)
		Clay.ball(c, lp + LIGHT * 2.0, LEG_RADIUS + 2.0, dark)
		Clay.ball(c, lp, LEG_RADIUS, base)
		for toe: float in [-5.0, 0.0, 5.0]:
			c.draw_circle(lp + Vector2(toe, LEG_RADIUS - 4.0), 2.4, dark)

	# the fat tail, curled round behind him, lashing when he is angry
	var back := -face
	var side := face.orthogonal()
	var angry := phase == 2 and hp > 0.0
	var lash := sin(t * (9.0 if angry else 3.0)) * (12.0 if angry else 4.0)
	var tail_pts := PackedVector2Array([
		at + back * 45.0,
		at + back * 62.0 + side * 14.0,
		at + back * 74.0 + side * 30.0,
		at + back * 86.0 + side * (40.0 + lash),
	])
	Clay.stroke(c, tail_pts, 20.0, 16.0, dark)
	Clay.stroke(c, tail_pts, 15.0, 12.0, base)
	c.draw_circle(tail_pts[tail_pts.size() - 1], 9.0, base)

	var body_half := Vector2(62.0, 52.0)
	Clay.blob(c, at, body_half, face, base)
	c.draw_colored_polygon(Clay.ellipse_pts(at - LIGHT * 14.0, body_half * 0.45, face), BRONZE_SPEC)

	var head_c := at + face * 38.0
	var head_r := 36.0
	Clay.ball(c, head_c, head_r, base)
	Clay.ball(c, head_c + Vector2(-18.0, 8.0), 18.0, base)
	Clay.ball(c, head_c + Vector2(18.0, 8.0), 18.0, base)

	var ear_droop: float = 6.0 if state == State.STUNNED else (-3.0 if angry else 0.0)
	for sd: float in [-1.0, 1.0]:
		var ear_base1 := head_c + Vector2(sd * 10.0, -head_r + 4.0 + ear_droop)
		var ear_base2 := head_c + Vector2(sd * 24.0, -head_r + 10.0 + ear_droop)
		var ear_tip := head_c + Vector2(sd * (20.0 + (6.0 if angry else 0.0)), -head_r - 14.0 + ear_droop)
		c.draw_colored_polygon(PackedVector2Array([ear_base1, ear_tip, ear_base2]), dark)
		c.draw_colored_polygon(PackedVector2Array([ear_base1.lerp(ear_base2, 0.2), ear_tip.lerp(head_c, 0.25), ear_base2.lerp(ear_base1, 0.2)]), lit)

	var charging := state == State.CHARGE_WARN or state == State.CHARGE
	var blink: bool = fmod(t + pos.x * 0.01, 4.5) < 0.18 and state != State.ROAR and not charging and not angry
	var eye_col: Color = EYE_CHARGE if charging or angry or state == State.ENRAGE else EYE_AMBER
	# a statue's eyes are shut; they open on the wake
	var open := 1.0
	if state == State.IDLE:
		open = 0.0
	elif state == State.AWAKEN:
		open = clampf(act_t / 0.5, 0.0, 1.0)
	for sd: float in [-1.0, 1.0]:
		var eye_c := head_c + Vector2(sd * 15.0, -4.0)
		if state == State.PURR:
			# contented, shut: a soft upturned line each
			c.draw_line(eye_c + Vector2(-6, 1), eye_c + Vector2(0, -2), EYE_PUPIL, 2.5)
			c.draw_line(eye_c + Vector2(0, -2), eye_c + Vector2(6, 1), EYE_PUPIL, 2.5)
		elif state == State.STUNNED:
			c.draw_line(eye_c - Vector2(4, 4), eye_c + Vector2(4, 4), EYE_PUPIL, 2.2)
			c.draw_line(eye_c - Vector2(-4, 4), eye_c + Vector2(-4, 4), EYE_PUPIL, 2.2)
		elif blink or open <= 0.05:
			c.draw_line(eye_c - Vector2(6, 0), eye_c + Vector2(6, 0), EYE_PUPIL, 2.0)
		else:
			if charging or state == State.ENRAGE or (state == State.AWAKEN and act_t < 1.4):
				# the glow round a lit eye
				c.draw_circle(eye_c, 11.0, Color(eye_col.r, eye_col.g, eye_col.b, 0.28))
			c.draw_colored_polygon(Clay.ellipse_pts(eye_c, Vector2(6.5, 6.5 * open), Vector2.RIGHT, 12), eye_col)
			c.draw_line(eye_c - Vector2(0, 5.0 * open), eye_c + Vector2(0, 5.0 * open), EYE_PUPIL, 2.2)
			if angry:
				# a heavy bronze brow, slanted down to the nose
				c.draw_line(eye_c + Vector2(sd * 9.0, -12.0), eye_c + Vector2(-sd * 6.0, -6.0), dark, 4.0)

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
	var paw_t := state_t if state == State.SWAT else (ls_swat_t if state == State.ROAR else 0.0)
	if paw_t > 0.0:
		var lift := clampf(paw_t / SWAT_WARN, 0.0, 1.0)
		var shoulder := at + face.orthogonal() * (34.0 if swat_paw_active == 1 else -34.0)
		var p_to := swat_pos.lerp(shoulder, lift * 0.6) + Vector2(0, -26.0 * lift)
		c.draw_line(shoulder, p_to, base, 16.0)
		Clay.ball(c, p_to, 20.0, lit)
		# claws out
		for cl: float in [-7.0, 0.0, 7.0]:
			var tip := p_to + Vector2(cl, 14.0 + 4.0 * (1.0 - lift))
			c.draw_line(p_to + Vector2(cl * 0.8, 8.0), tip, Color(0.92, 0.90, 0.84), 2.0)

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
