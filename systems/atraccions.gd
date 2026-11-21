class_name Atraccions
extends RefCounted

# WALK: LES ATRACCIONS (an original theme park on the Costa Daurada)
# Bright day. Through the gates, past invented lands, off-leash on the picnic
# lawn. No chase yet: the mascots come later.
#
# Up the walk: the ticket gates and welcome arch; Cala del Corsari (white
# fishing village, harbour pool, pirate-ship swing); Canyon del Sol (boardwalk
# Wild West, mine-train trestle overhead); Selva dels Llorers (jungle of the
# park's own invention, log flume beside the path); Plaça del Loop (the big
# coaster's lift and loop); then the picnic lawn behind the last land.
#
# Live event: the flume's splash. The log boat clanks to the top and its
# riders scream (FLUME_WARN), then it plunges into the pool beside the path
# and a wave sloshes across the walkway. Pull your human to the dry (left)
# side, or plant there, for a dodge; caught, they soak.

# the hooks main calls on this walk, held to it by tests/test_walk_hooks.gd
const HOOKS := ["draw_bollard", "draw_column", "draw_cross_section", "draw_edge_layer",
	"draw_live", "draw_overhead", "draw_snack", "idle_status", "is_lamp",
	"name_place", "night_fronts", "night_lights", "on_bark", "surface", "tick", "tree_kind"]

# the overhead culls to the camera and runs the trains: redrawn at 30 fps
const OVERHEAD_FOLLOWS_CAMERA := true

const Surfaces := preload("res://world/surfaces.gd")
const ShapeBatch := preload("res://systems/shape_batch.gd")
const EventFeed := preload("res://hud/event_feed.gd")
const AnimClock := preload("res://systems/anim_clock.gd")
const NearMiss := preload("res://systems/near_miss.gd")
const Panot := preload("res://world/panot.gd")
const Outdoors := preload("res://systems/outdoors.gd")
const SkyLook := preload("res://systems/sky.gd")
const SignLetters := preload("res://world/sign_letters.gd")
const NightFronts := preload("res://world/night_fronts.gd")

const HALF := 270.0
const CX := 640.0
const PATH_L := CX - HALF
const PATH_R := CX + HALF
const SHADOW := Color(0.10, 0.14, 0.26, 0.28)

# paving and lands
const PAVEMENT := Color(0.78, 0.74, 0.68)
const PAVEMENT_LIT := Color(0.88, 0.84, 0.76)
const SETT := Color(0.86, 0.84, 0.80)
const SETT_DARK := Color(0.70, 0.68, 0.64)
const STONE := Color(0.62, 0.60, 0.56)
const GRASS := Color(0.42, 0.62, 0.34)
const GRASS_LIT := Color(0.54, 0.74, 0.42)
const DUST := Color(0.72, 0.48, 0.28)
const DUST_LIT := Color(0.84, 0.60, 0.38)
const EARTH := Color(0.36, 0.28, 0.18)
const EARTH_LIT := Color(0.48, 0.38, 0.24)
const WATER := Color(0.22, 0.58, 0.72)
const WATER_DEEP := Color(0.12, 0.42, 0.58)
const WATER_SOFT := Color(0.36, 0.70, 0.82, 0.55)
const WHITEWASH := Color(0.96, 0.95, 0.90)
const WHITE_SHADE := Color(0.88, 0.86, 0.80)
const TERRACOTTA := Color(0.78, 0.42, 0.28)
const TERRACOTTA_LIT := Color(0.88, 0.54, 0.36)
const WOOD := Color(0.56, 0.36, 0.22)
const WOOD_DARK := Color(0.36, 0.22, 0.14)
const WOOD_LIT := Color(0.68, 0.48, 0.30)
const STEEL := Color(0.58, 0.61, 0.66)
const STEEL_DARK := Color(0.32, 0.34, 0.38)
const SAFFRON := Color(0.96, 0.72, 0.18)
const MAGENTA := Color(0.86, 0.22, 0.52)
const TURQ := Color(0.18, 0.72, 0.68)
const JUNGLE := Color(0.18, 0.42, 0.28)
const JUNGLE_LIT := Color(0.28, 0.56, 0.36)
const PONCHO := Color(0.92, 0.40, 0.28)
const SHUTTER := Color(0.22, 0.48, 0.62)

# land bands (y going up the screen / more negative)
const GATE_BAND := -200.0
const CORSARI_Y0 := -400.0
const CORSARI_Y1 := -1400.0
const CANYON_Y0 := -1400.0
const CANYON_Y1 := -2400.0
const SELVA_Y0 := -2400.0
const SELVA_Y1 := -3400.0
const LOOP_Y0 := -3400.0
const LOOP_Y1 := -4400.0
const PICNIC_Y := -4400.0

# entrance
const ARCH := Vector2(CX, -120.0)
const FOUNTAIN := Vector2(CX, -280.0)
const BOOTH := Rect2(PATH_L + 16.0, -90.0, 86.0, 64.0)
const TURNSTILES: Array[Vector2] = [
	Vector2(560.0, -340.0), Vector2(640.0, -340.0), Vector2(720.0, -340.0),
]

# Cala del Corsari: the harbour basin off the west edge of the path, its
# quay round it, and the pirate ship swinging north and south over it
const HARBOUR := Rect2(PATH_L - 300.0, -1215.0, 262.0, 250.0)
const QUAY := 30.0
const SHIP := Vector2(PATH_L - 169.0, -1090.0)
const SHIP_SWING := 74.0

# Canyon del Sol
const SALOON := Rect2(PATH_R - 100.0, -1720.0, 90.0, 80.0)
# the mine station on the west side, at the head of the Canyon's queue
const MINE_STATION := Rect2(PATH_L - 236.0, -1900.0, 214.0, 250.0)
# the mine train's run, in travel order: out of the station's north end,
# over the boardwalk and off east, then (out of sight) back over it further
# down and into the station's south end. MINE_GAP is the off-screen leg.
const MINE_PATH: Array[Vector2] = [
	Vector2(200.0, -1700.0), Vector2(200.0, -1880.0), Vector2(290.0, -1960.0),
	Vector2(460.0, -2010.0), Vector2(650.0, -2080.0), Vector2(820.0, -2160.0),
	Vector2(990.0, -2230.0), Vector2(1170.0, -2280.0), Vector2(1760.0, -2300.0),
	Vector2(1760.0, -1500.0), Vector2(1160.0, -1490.0), Vector2(910.0, -1510.0),
	Vector2(670.0, -1560.0), Vector2(470.0, -1610.0), Vector2(300.0, -1660.0),
	Vector2(200.0, -1700.0),
]
const MINE_GAP := 8
const MINE_SPEED := 150.0

# Selva + flume — splash pool well east of the corridor; path stays dry
const FLUME_DROP := Vector2(PATH_R - 20.0, -2880.0)
const FLUME_POOL := Rect2(PATH_R + 48.0, -3060.0, 200.0, 180.0)
const FLUME_WARN := 1.0
const FLUME_SPLASH := 1.4
const FLUME_COOLDOWN := 7.0
const FLUME_Y0 := -3040.0
const FLUME_Y1 := -2860.0
# wave reaches leftward across the path from the pool; dry side is the far left
const FLUME_WASH_X := PATH_L + 160.0
const FLUME_DRY_X := PATH_L + 120.0
const FLUME_REACH_X := PATH_R - 10.0

# Plaça del Loop: the coaster's station east of the path, its lift hill
# north of it, the loop over the path; the circuit in travel order
const STATION := Rect2(PATH_R + 26.0, -3990.0, 230.0, 300.0)
const LOOP_C := Vector2(CX + 60.0, -4020.0)
const LOOP_R := 100.0
const COASTER_SPEED := 260.0
const LIFT_TOP := Vector2(1060.0, -4270.0)
# the flume's lift tower and its drop into the splash pool
const FLUME_TOP := Vector2(1060.0, -3330.0)
const FLUME_FOOT := Vector2(1060.0, -3070.0)

# picnic finish
const PICNIC_TABLES: Array[Rect2] = [
	Rect2(400.0, -4560.0, 96.0, 44.0),
	Rect2(760.0, -4560.0, 96.0, 44.0),
	Rect2(520.0, -4720.0, 96.0, 44.0),
	Rect2(700.0, -4840.0, 96.0, 44.0),
]
const PRIZE := Vector2(640.0, -4680.0)
const PRIZE_TEXT := "snatch the churro off the picnic grill"

# queue rope posts the leash wraps (and she marks) — zig-zag mazes
# Canyon saloon queue (west of path), Selva flume queue (east), Loop station queue (east).
# Indices 0-5 / 6-12 / 13-20; path centre stays walkable.
const QUEUE_POSTS: Array[Vector2] = [
	# Canyon — zig-zag by the saloon
	Vector2(PATH_L + 36.0, -1680.0), Vector2(PATH_L + 36.0, -1740.0), Vector2(PATH_L + 36.0, -1800.0),
	Vector2(PATH_L + 90.0, -1710.0), Vector2(PATH_L + 90.0, -1770.0), Vector2(PATH_L + 90.0, -1830.0),
	# Selva — longer switchback by the flume entrance
	Vector2(PATH_R - 36.0, -2780.0), Vector2(PATH_R - 36.0, -2860.0), Vector2(PATH_R - 36.0, -2940.0),
	Vector2(PATH_R - 36.0, -3020.0), Vector2(PATH_R - 92.0, -2820.0), Vector2(PATH_R - 92.0, -2900.0),
	Vector2(PATH_R - 92.0, -2980.0),
	# Loop — compact maze by the lift hill
	Vector2(PATH_R - 40.0, -3720.0), Vector2(PATH_R - 40.0, -3800.0), Vector2(PATH_R - 40.0, -3880.0),
	Vector2(PATH_R - 96.0, -3760.0), Vector2(PATH_R - 96.0, -3840.0), Vector2(PATH_R - 96.0, -3920.0),
	Vector2(PATH_R - 152.0, -3800.0), Vector2(PATH_R - 152.0, -3880.0),
]
const POST_R := 10.0

# palms and jungle trees (poles + crowns)
const PALMS: Array[Vector2] = [
	Vector2(470.0, -600.0), Vector2(820.0, -900.0),
	Vector2(480.0, -2100.0), Vector2(810.0, -2700.0),
	Vector2(500.0, -3200.0), Vector2(790.0, -4100.0),
]
# park lamps (poles + soft pools after dark via Game.lamp_glow)
const PARK_LAMPS: Array[Vector2] = [
	Vector2(480.0, -80.0), Vector2(800.0, -80.0),
	Vector2(470.0, -320.0), Vector2(810.0, -520.0),
	Vector2(480.0, -1100.0), Vector2(800.0, -1500.0),
	Vector2(470.0, -1900.0), Vector2(810.0, -2300.0),
	Vector2(480.0, -2900.0), Vector2(800.0, -3300.0),
	Vector2(470.0, -3700.0), Vector2(810.0, -4100.0),
	Vector2(520.0, -4550.0), Vector2(760.0, -4550.0),
]
const JUNGLE_TREES: Array[Vector2] = [
	Vector2(460.0, -2500.0), Vector2(830.0, -2650.0),
	Vector2(470.0, -3100.0), Vector2(820.0, -3300.0),
]

# park furniture
const CHURRO := Vector2(780.0, -720.0)
const ICECREAM := Vector2(500.0, -1820.0)
const BALLOON_SPOTS: Array[Vector2] = [
	Vector2(560.0, -340.0), Vector2(720.0, -1480.0), Vector2(580.0, -3180.0),
]
const CAROUSEL := Vector2(PATH_L + 110.0, -3600.0)
const CAROUSEL_R := 56.0


static func solids(_m: Node2D = null) -> Array[Rect2]:
	# ship frame and harbour sit off the corridor (edge layer); no solids there
	return [
		BOOTH, SALOON,
		PICNIC_TABLES[0], PICNIC_TABLES[1],
		Rect2(CAROUSEL.x - 28.0, CAROUSEL.y - 28.0, 56.0, 56.0),
		Rect2(CHURRO.x - 28.0, CHURRO.y - 18.0, 56.0, 36.0),
		Rect2(ICECREAM.x - 24.0, ICECREAM.y - 16.0, 48.0, 32.0),
	]


static func wrap_rects(_m: Node2D = null) -> Array[Rect2]:
	var out: Array[Rect2] = solids(null)
	for p: Vector2 in QUEUE_POSTS:
		out.append(Rect2(p.x - POST_R, p.y - POST_R, POST_R * 2.0, POST_R * 2.0))
	return out


static func build(m: Node2D) -> Array:
	m.gate_text = "JARDÍ DEL PÍCNIC"
	m.chase_jams.clear()
	m.stalls.clear()
	m.stall_kinds.clear()
	m.astands = Array([], TYPE_VECTOR2, &"", null)
	m.manholes = Array([], TYPE_VECTOR2, &"", null)
	m.cone_spots = Array([], TYPE_VECTOR2, &"", null)
	m.fountains = Array([FOUNTAIN], TYPE_VECTOR2, &"", null)
	m.bins = Array([
		Vector2(PATH_L + 28.0, -350.0),
		Vector2(PATH_R - 28.0, -1200.0),
		Vector2(PATH_L + 28.0, -2200.0),
		Vector2(PATH_R - 28.0, -3000.0),
		Vector2(PATH_L + 28.0, -3900.0),
		Vector2(PATH_R - 28.0, -4500.0),
	], TYPE_VECTOR2, &"", null)
	m.benches = Array([
		Vector2(520.0, -380.0), Vector2(760.0, -1280.0),
		Vector2(520.0, -2180.0), Vector2(760.0, -3480.0),
	], TYPE_VECTOR2, &"", null)
	for p: Vector2 in QUEUE_POSTS:
		m.poles.append(p)
	for p: Vector2 in PALMS:
		m.poles.append(p)
	for p: Vector2 in JUNGLE_TREES:
		m.poles.append(p)
	for p: Vector2 in PARK_LAMPS:
		m.poles.append(p)
	m.deco_pole_count = m.poles.size()
	var marks: Array[Vector2] = [
		QUEUE_POSTS[0], QUEUE_POSTS[5], QUEUE_POSTS[6], QUEUE_POSTS[12],
		QUEUE_POSTS[13], QUEUE_POSTS[20], Vector2(PATH_L + 30.0, -1900.0),
		PRIZE + Vector2(-100.0, 40.0),
	]
	var snacks: Array[Vector2] = [
		Vector2(560.0, -500.0),
		Vector2(700.0, -980.0),
		Vector2(580.0, -1700.0),
		Vector2(720.0, -2480.0),
		Vector2(600.0, -3180.0),
		Vector2(680.0, -4050.0),
	]
	m.atraccions_flume = {"state": "wait", "t": 0.0, "cooldown": 1.5, "hit": false, "threatened": false, "warned": false}
	m.atraccions_flume_dodges = 0
	m.atraccions_churro_barked = false
	m.atraccions_carousel_spins = 0
	return [marks, snacks]


# --- flume splash --------------------------------------------------------------

static func in_splash(p: Vector2) -> bool:
	# wash across the path from the pool's side; left of FLUME_WASH_X stays dry
	return p.y >= FLUME_Y0 and p.y <= FLUME_Y1 and p.x >= FLUME_WASH_X and p.x <= PATH_R + 8.0


static func on_dry_side(p: Vector2) -> bool:
	return p.y >= FLUME_Y0 - 40.0 and p.y <= FLUME_Y1 + 40.0 and p.x <= FLUME_DRY_X and p.x >= PATH_L - 8.0


static func tick(m: Node2D, delta: float) -> void:
	if m.lvl != "atraccions":
		return
	_tick_flume(m, delta)


static func _tick_flume(m: Node2D, delta: float) -> void:
	var w: Dictionary = m.atraccions_flume
	var dog_y: float = m.dog.global_position.y
	var hum_y: float = m.human.global_position.y
	var near: bool = minf(dog_y, hum_y) < FLUME_Y1 + 280.0 and maxf(dog_y, hum_y) > FLUME_Y0 - 280.0
	var st: String = str(w.get("state", "wait"))
	match st:
		"wait":
			if float(w.get("cooldown", 0.0)) > 0.0:
				w["cooldown"] = float(w["cooldown"]) - delta
			elif near:
				w["state"] = "climb"
				w["t"] = 0.0
				w["hit"] = false
				w["threatened"] = false
				w["warned"] = false
				Sfx.play("ui", 0.7, -6.0)
		"climb":
			w["t"] = float(w["t"]) + delta
			var hy: float = m.human.global_position.y
			if hy >= FLUME_Y0 - 40.0 and hy <= FLUME_Y1 + 40.0 and m.human.global_position.x >= FLUME_WASH_X - 20.0:
				w["threatened"] = true
			if not bool(w.get("warned", false)) and near:
				w["warned"] = true
				m.float_text(m.human.global_position + Vector2(0.0, -34.0), I18n.t("w_flume_hold_on"), Color(0.95, 0.90, 0.70), m.POP_SAY)
				m.feed.say(I18n.t("w_flume_scream"), EventFeed.Tone.LOUD)
				Sfx.play("whoop", 0.85, -4.0)
			if float(w["t"]) >= FLUME_WARN:
				w["state"] = "splash"
				w["t"] = 0.0
				Sfx.play("splash", 0.95, -3.0)
				m.feed.say(I18n.t("w_flume_splash"), EventFeed.Tone.LOUD)
		"splash":
			w["t"] = float(w["t"]) + delta
			var hpos: Vector2 = m.human.global_position
			var dpos: Vector2 = m.dog.global_position
			if hpos.y >= FLUME_Y0 - 40.0 and hpos.y <= FLUME_Y1 + 40.0:
				w["threatened"] = true
			if in_splash(hpos):
				w["hit"] = true
				m.human_soak = minf(1.0, float(m.human_soak) + delta * 0.55)
				m.human.patience = maxf(0.0, m.human.patience - delta * 0.35)
			if in_splash(dpos):
				m.dog.slick = true
			if float(w["t"]) >= FLUME_SPLASH:
				var in_wash: bool = in_splash(hpos)
				var close_now: bool = hpos.y >= FLUME_Y0 - 40.0 and hpos.y <= FLUME_Y1 + 40.0 and hpos.x >= FLUME_WASH_X - 20.0
				var planted_dry: bool = bool(m.dog.planted) and on_dry_side(dpos) and not bool(w.get("hit", false))
				var nm: Dictionary = NearMiss.consider(close_now, bool(w.get("hit", false)), bool(w.get("threatened", false)), false)
				var cleared: bool = bool(w.get("threatened", false)) and not bool(w.get("hit", false)) \
					and (bool(nm.get("dodge", false)) or planted_dry or on_dry_side(hpos) or not in_wash)
				if cleared and not bool(w.get("paid", false)):
					w["paid"] = true
					m.atraccions_flume_dodges += 1
					m.combo.add(I18n.t("w_flume_dodged"), 45)
					m.award_points(45, I18n.t("w_stayed_dry_45"))
					m.float_text(hpos + Vector2(0.0, -34.0), I18n.t("w_missed_me"), Color(0.75, 0.96, 1.0), m.POP_SAY)
					m.feed.say(I18n.t("w_pulled_clear"), EventFeed.Tone.GOOD)
				elif bool(w.get("hit", false)):
					m.feed.say(I18n.t("w_soaked_2"), EventFeed.Tone.LOUD)
				w["state"] = "wait"
				w["t"] = 0.0
				w["cooldown"] = FLUME_COOLDOWN
				w["paid"] = false
	m.atraccions_flume = w


static func idle_status(m: Node2D) -> String:
	if m.lvl != "atraccions":
		return ""
	var w: Dictionary = m.atraccions_flume
	if str(w.get("state", "")) == "climb":
		var dp: Vector2 = m.dog.global_position
		if absf(dp.y - FLUME_DROP.y) < 320.0:
			return I18n.t("walk_atraccions_flume")
	return ""


static func on_bark(m: Node2D, pos: Vector2) -> void:
	if m.lvl != "atraccions":
		return
	if pos.distance_to(CHURRO) < 140.0 and not m.atraccions_churro_barked:
		m.atraccions_churro_barked = true
		m.bones += 3
		m.float_text(CHURRO + Vector2(0.0, -36.0), I18n.t("w_churro_3"), SAFFRON)
		m.feed.say(I18n.t("w_one_churro_coming"), EventFeed.Tone.GOOD)
		Sfx.play("bark", 1.2, -6.0)
	if pos.distance_to(CAROUSEL) < 160.0 and int(m.atraccions_carousel_spins) < 1:
		m.atraccions_carousel_spins = 1
		m.bones += 2
		m.float_text(CAROUSEL + Vector2(0.0, -50.0), I18n.t("w_ride_spin_2"), MAGENTA)
		m.feed.say(I18n.t("w_round_we_go"), EventFeed.Tone.GOOD)
		Sfx.play("chime", 1.0, -6.0)


# --- drawing -----------------------------------------------------------------
#
# Where each part is drawn, so the ground can stay cached:
# - draw_edge_layer (cached, behind everything): each land's ground past the
#   path, its buildings from above, the harbour, the flume's pool, the mine
#   and coaster stations, the picnic lawn's hedges and fence.
# - draw_cross_section (cached; never reads the clock): the path's own ground,
#   the gate's towers and turnstiles, the queue mazes and their people, the
#   carts, the shadows the overhead tracks throw.
# - draw_live (every frame): the pirate ship, the carousel, the flume's boat
#   and wave, the grill's smoke, the balloons, and every bulb after dark.
# - draw_overhead (above everyone): the welcome arch's lintel, tree crowns,
#   the mine train's trestle and the coaster's track, with their trains.

const WARM := Color(1.0, 0.86, 0.60)
const COOL := Color(0.30, 0.36, 0.62)
const INK := Color(0.12, 0.10, 0.14)
const BULB := Color(1.0, 0.93, 0.66)
const BULB_DAY := Color(0.96, 0.93, 0.84)
const GLASS := Color(0.62, 0.80, 0.88)
const GLASS_DARK := Color(0.26, 0.34, 0.42)
# village roof tiles, sun-faded to fresh
const TILES: Array[Color] = [
	Color(0.78, 0.42, 0.28), Color(0.72, 0.36, 0.24), Color(0.84, 0.52, 0.34),
	Color(0.68, 0.34, 0.26), Color(0.80, 0.46, 0.30),
]
const SHUTTERS: Array[Color] = [
	Color(0.18, 0.40, 0.66), Color(0.20, 0.52, 0.46), Color(0.16, 0.32, 0.54),
	Color(0.42, 0.60, 0.30),
]
# the West's painted false fronts
const PAINTS: Array[Color] = [
	Color(0.36, 0.56, 0.58), Color(0.78, 0.60, 0.30), Color(0.56, 0.22, 0.18),
	Color(0.86, 0.80, 0.66), Color(0.42, 0.30, 0.20), Color(0.54, 0.62, 0.44),
]
const TIN := Color(0.64, 0.64, 0.62)
const RUST := Color(0.58, 0.32, 0.18)
const ROCK := Color(0.70, 0.38, 0.24)
const ROCK_LIT := Color(0.86, 0.54, 0.34)
const ROCK_DARK := Color(0.50, 0.24, 0.16)
const THATCH := Color(0.74, 0.60, 0.34)
const THATCH_DARK := Color(0.52, 0.40, 0.20)
const BAMBOO := Color(0.70, 0.72, 0.38)
const LEAF := Color(0.16, 0.46, 0.26)
const LEAF_LIT := Color(0.32, 0.62, 0.32)
const LEAF_DARK := Color(0.08, 0.30, 0.20)
# plaza stucco
const STUCCO: Array[Color] = [
	Color(0.96, 0.80, 0.82), Color(0.74, 0.90, 0.84), Color(0.98, 0.90, 0.66),
	Color(0.80, 0.84, 0.96), Color(0.98, 0.84, 0.70),
]
const HEDGE := Color(0.20, 0.44, 0.24)
const HEDGE_LIT := Color(0.32, 0.58, 0.30)
const SKINS: Array[Color] = [
	Color(0.96, 0.80, 0.66), Color(0.86, 0.66, 0.50), Color(0.70, 0.50, 0.36),
	Color(0.50, 0.34, 0.24), Color(0.92, 0.74, 0.60),
]
const HAIRS: Array[Color] = [
	Color(0.16, 0.12, 0.10), Color(0.36, 0.22, 0.12), Color(0.70, 0.52, 0.28),
	Color(0.86, 0.76, 0.50), Color(0.50, 0.24, 0.14), Color(0.58, 0.58, 0.60),
]
const SHIRTS: Array[Color] = [
	Color(0.86, 0.22, 0.52), Color(0.18, 0.66, 0.64), Color(0.96, 0.72, 0.18),
	Color(0.94, 0.94, 0.92), Color(0.22, 0.34, 0.62), Color(0.86, 0.30, 0.26),
	Color(0.30, 0.60, 0.36), Color(0.56, 0.36, 0.70), Color(0.95, 0.60, 0.30),
]
# the queue mazes: [rope runs as post indices, the lanes visitors stand in
# (each from its tail to its head), how many stand there, a hat they bought]
const MAZES: Array = [
	[[[0, 1, 2], [3, 4, 5]], [[Vector2(433.0, -1676.0), Vector2(433.0, -1846.0)], [Vector2(389.0, -1690.0), Vector2(389.0, -1830.0)]], 9, "cowboy"],
	[[[6, 7, 8, 9], [10, 11, 12]], [[Vector2(892.0, -2770.0), Vector2(892.0, -3030.0)], [Vector2(846.0, -2830.0), Vector2(846.0, -2990.0)]], 11, "poncho"],
	[[[13, 14, 15], [16, 17, 18], [19, 20]], [[Vector2(890.0, -3720.0), Vector2(890.0, -3900.0)], [Vector2(842.0, -3760.0), Vector2(842.0, -3920.0)], [Vector2(786.0, -3800.0), Vector2(786.0, -3880.0)]], 12, "ears"],
]
const ROPE_COLS: Array[Color] = [Color(0.70, 0.18, 0.20), Color(0.16, 0.50, 0.40), Color(0.22, 0.36, 0.76)]


static func _h(n: float) -> float:
	return fposmod(sin(n * 12.9898 + 4.1) * 43758.5453, 1.0)


static func _hk(k: float, salt: float) -> float:
	return fposmod(sin(k * 12.9898 + salt * 78.233) * 43758.5453, 1.0)


static func _pick(list: Array, k: float, salt: float):
	return list[int(_hk(k, salt) * float(list.size())) % list.size()]


static func _tint(m: Node2D) -> Color:
	if m == null or not ("night_cm" in m) or m.night_cm == null:
		return Color.WHITE
	return m.night_cm.color


# --- shared shapes -------------------------------------------------------------

# a building's shadow, thrown down and right by its height, soft at the rim
static func _cast(b: ShapeBatch, r: Rect2, h: float) -> void:
	var d := Shade.light * h
	b.rect(Rect2(r.position + d - Vector2(3.0, 3.0), r.size + Vector2(6.0, 6.0)), Color(SHADOW, 0.10))
	b.rect(Rect2(r.position + d, r.size), Color(SHADOW, 0.24))


static func _disc_shadow(b: ShapeBatch, c: Vector2, r: float, h: float) -> void:
	b.circle(c + Shade.light * h, r + 3.0, Color(SHADOW, 0.10))
	b.circle(c + Shade.light * h, r, Color(SHADOW, 0.24))


# A pitched tile roof over r: the ridge up the screen (ridge_y) or across it,
# the slope toward the sun (west, or north) warm, the other in shade, the
# tiles' channels running down from the ridge, a dark drip line at the eaves
static func _roof(b: ShapeBatch, r: Rect2, tile: Color, ridge_y: bool, rib := 8.0) -> void:
	var lit := tile.lightened(0.12).lerp(WARM, 0.06)
	var shade := tile.darkened(0.18).lerp(COOL, 0.06)
	var c := r.get_center()
	if ridge_y:
		b.rect(Rect2(r.position.x, r.position.y, c.x - r.position.x, r.size.y), lit)
		b.rect(Rect2(c.x, r.position.y, r.end.x - c.x, r.size.y), shade)
		var y := r.position.y + rib * 0.5
		while y < r.end.y:
			b.line(Vector2(r.position.x + 1.0, y), Vector2(c.x - 2.0, y), lit.darkened(0.12), 1.3)
			b.line(Vector2(c.x + 2.0, y), Vector2(r.end.x - 1.0, y), shade.darkened(0.12), 1.3)
			y += rib
		b.line(Vector2(c.x + 2.5, r.position.y), Vector2(c.x + 2.5, r.end.y), Color(0.05, 0.04, 0.08, 0.20), 2.5)
		b.line(Vector2(c.x, r.position.y), Vector2(c.x, r.end.y), tile.lightened(0.30), 3.0)
	else:
		b.rect(Rect2(r.position.x, r.position.y, r.size.x, c.y - r.position.y), lit)
		b.rect(Rect2(r.position.x, c.y, r.size.x, r.end.y - c.y), shade)
		var x := r.position.x + rib * 0.5
		while x < r.end.x:
			b.line(Vector2(x, r.position.y + 1.0), Vector2(x, c.y - 2.0), lit.darkened(0.12), 1.3)
			b.line(Vector2(x, c.y + 2.0), Vector2(x, r.end.y - 1.0), shade.darkened(0.12), 1.3)
			x += rib
		b.line(Vector2(r.position.x, c.y + 2.5), Vector2(r.end.x, c.y + 2.5), Color(0.05, 0.04, 0.08, 0.20), 2.5)
		b.line(Vector2(r.position.x, c.y), Vector2(r.end.x, c.y), tile.lightened(0.30), 3.0)
	b.rect(Rect2(r.position.x, r.end.y - 2.0, r.size.x, 2.0), shade.darkened(0.25))
	b.rect(Rect2(r.end.x - 2.0, r.position.y, 2.0, r.size.y), shade.darkened(0.25))


# A hipped roof: four slopes up to a ridge (or a point on a square), each
# lit by how it faces the sun
static func _hip(b: ShapeBatch, r: Rect2, col: Color) -> void:
	var inset := minf(r.size.x, r.size.y) * 0.5
	var c := r.get_center()
	var p0: Vector2
	var p1: Vector2
	if r.size.x >= r.size.y:
		p0 = Vector2(r.position.x + inset, c.y)
		p1 = Vector2(r.end.x - inset, c.y)
	else:
		p0 = Vector2(c.x, r.position.y + inset)
		p1 = Vector2(c.x, r.end.y - inset)
	var nw := r.position
	var ne := Vector2(r.end.x, r.position.y)
	var se := r.end
	var sw := Vector2(r.position.x, r.end.y)
	if r.size.x >= r.size.y:
		b.quad(nw, ne, p1, p0, col.lightened(0.16).lerp(WARM, 0.05))
		b.quad(p0, p1, se, sw, col.darkened(0.20).lerp(COOL, 0.06))
		b.quad(nw, p0, p0, sw, col.lightened(0.06))
		b.quad(ne, se, p1, p1, col.darkened(0.10))
	else:
		b.quad(nw, p0, p1, sw, col.lightened(0.10).lerp(WARM, 0.05))
		b.quad(p0, ne, se, p1, col.darkened(0.18).lerp(COOL, 0.06))
		b.quad(nw, ne, p0, p0, col.lightened(0.18))
		b.quad(sw, p1, p1, se, col.darkened(0.08))
	b.line(p0, p1, col.lightened(0.30), 2.5)
	b.line(nw, p0, col.lightened(0.22), 1.5)
	b.line(ne, p1, col.darkened(0.05), 1.5)
	b.line(sw, p0, col.lightened(0.02), 1.5)
	b.line(se, p1, col.darkened(0.28), 1.5)


# A round roof of n segments, alternating two colours (a striped kiosk or a
# carousel's canopy), each segment shaded by the way it faces the sun.
# `turn` turns the stripes (a carousel's canopy spins).
static func _cone(b: ShapeBatch, c: Vector2, r: float, a: Color, z: Color, n: int, turn := 0.0) -> void:
	var sun := Vector2(-0.5, -0.866)
	for i in range(n):
		var a0 := turn + float(i) * TAU / float(n)
		var a1 := turn + float(i + 1) * TAU / float(n)
		var mid := Vector2.from_angle((a0 + a1) * 0.5)
		var lit := mid.dot(sun)
		var col := a if i % 2 == 0 else z
		col = col.lightened(0.14 * maxf(lit, 0.0)).darkened(0.20 * maxf(-lit, 0.0))
		b.quad(c, c + Vector2.from_angle(a0) * r, c + Vector2.from_angle(a1) * r, c, col)
	b.circle(c, r * 0.16, a.darkened(0.2))
	b.circle(c - Vector2(1.0, 1.5), r * 0.10, SAFFRON.lightened(0.2))


# a thatched cone: rings of straw from the dark eaves up to a lighter top,
# lit on the sun's side, strokes of straw down the slope, a bound topknot
static func _thatch(b: ShapeBatch, c: Vector2, r: float, k: float) -> void:
	var sun := Vector2(-0.5, -0.866)
	var seg := 14
	for ring in range(4):
		var rr := r * (1.0 - float(ring) * 0.22)
		var base := THATCH_DARK.lerp(THATCH, float(ring) / 3.0)
		for i in range(seg):
			var a0 := float(i) * TAU / float(seg) + k
			var a1 := float(i + 1) * TAU / float(seg) + k
			var lit := Vector2.from_angle((a0 + a1) * 0.5).dot(sun)
			var col := base.lightened(0.16 * maxf(lit, 0.0)).darkened(0.18 * maxf(-lit, 0.0))
			b.quad(c, c + Vector2.from_angle(a0) * rr, c + Vector2.from_angle(a1) * rr, c, col)
	for i in range(18):
		var a := float(i) * TAU / 18.0 + k * 1.7
		b.line(c + Vector2.from_angle(a) * r * 0.25, c + Vector2.from_angle(a) * r * 0.98, THATCH_DARK.darkened(0.1), 1.2)
	# the ragged eave
	for i in range(22):
		var a := float(i) * TAU / 22.0 + k
		b.circle(c + Vector2.from_angle(a) * r, 3.0, THATCH_DARK if i % 2 == 0 else THATCH)
	b.circle(c, r * 0.14, THATCH_DARK.darkened(0.2))
	b.circle(c - Vector2(1.0, 1.0), r * 0.08, THATCH.lightened(0.2))


# a flat roof inside its parapet, a light tile floor and its joints
static func _terrat(b: ShapeBatch, r: Rect2, wall: Color, floor_col: Color, grid := 14.0) -> void:
	b.rect(r, wall)
	var f := r.grow(-5.0)
	b.rect(f, floor_col)
	var x := f.position.x + grid
	while x < f.end.x:
		b.line(Vector2(x, f.position.y), Vector2(x, f.end.y), floor_col.darkened(0.08), 1.0)
		x += grid
	var y := f.position.y + grid
	while y < f.end.y:
		b.line(Vector2(f.position.x, y), Vector2(f.end.x, y), floor_col.darkened(0.08), 1.0)
		y += grid
	# the parapet's shadow along its sunny inside edges
	b.rect(Rect2(f.position, Vector2(f.size.x, 4.0)), Color(SHADOW, 0.22))
	b.rect(Rect2(f.position, Vector2(4.0, f.size.y)), Color(SHADOW, 0.22))
	b.rect(Rect2(r.position, Vector2(r.size.x, 2.0)), wall.lightened(0.25))


# Someone from above: shoulders, arms, head and hair (or a hat), facing
# `face`, their colours from k. s < 1 is a child.
static func _person(b: ShapeBatch, p: Vector2, k: float, s := 1.0, face := Vector2.UP, hat := "") -> void:
	var shirt: Color = _pick(SHIRTS, k, 1.0)
	var skin: Color = _pick(SKINS, k, 2.0)
	var hair: Color = _pick(HAIRS, k, 3.0)
	var side := face.orthogonal()
	b.circle(p + Shade.light * 5.0 * s, 7.0 * s, Color(SHADOW, 0.26))
	if hat == "poncho":
		b.circle(p, 9.0 * s, Color(PONCHO if _hk(k, 4.0) < 0.5 else Color(0.20, 0.56, 0.82), 0.92))
		b.circle(p - Vector2(1.5, 1.5) * s, 6.0 * s, Color(1.0, 1.0, 1.0, 0.18))
		b.circle(p + face * 1.0 * s, 4.2 * s, skin)
		b.circle(p - face * 0.6 * s, 4.4 * s, Color(PONCHO.darkened(0.1) if _hk(k, 4.0) < 0.5 else Color(0.16, 0.46, 0.72)))
		return
	b.capsule(p - side * 5.5 * s, p + side * 5.5 * s, 4.0 * s, shirt.darkened(0.18))
	b.capsule(p - side * 5.0 * s - face * 0.6 * s, p + side * 5.0 * s - face * 0.6 * s, 3.2 * s, shirt)
	b.circle(p - side * 9.0 * s + face * 2.5 * s, 1.9 * s, skin)
	b.circle(p + side * 9.0 * s + face * 2.5 * s, 1.9 * s, skin)
	var head := p + face * 0.8 * s
	b.circle(head, 4.2 * s, skin)
	match hat:
		"cowboy":
			b.circle(head, 7.0 * s, Color(0.56, 0.38, 0.20))
			b.circle(head - Vector2(0.8, 0.8) * s, 4.0 * s, Color(0.66, 0.46, 0.26))
			b.line(head - side * 3.5 * s, head + side * 3.5 * s, Color(0.36, 0.22, 0.12), 1.4 * s)
		"ears":
			b.circle(head - face * 1.0 * s, 4.1 * s, hair)
			b.circle(head - side * 4.5 * s, 2.6 * s, INK)
			b.circle(head + side * 4.5 * s, 2.6 * s, INK)
		"cap":
			b.circle(head - face * 0.6 * s, 4.3 * s, _pick([MAGENTA, TURQ, SAFFRON, Color(0.22, 0.34, 0.62)], k, 5.0))
			b.capsule(head + face * 2.5 * s - side * 2.0 * s, head + face * 2.5 * s + side * 2.0 * s, 1.8 * s, _pick([MAGENTA, TURQ, SAFFRON, Color(0.22, 0.34, 0.62)], k, 5.0))
		"sunhat":
			b.circle(head, 6.6 * s, Color(0.94, 0.86, 0.64))
			b.circle(head, 3.8 * s, Color(0.88, 0.78, 0.54))
			b.line(head - side * 3.6 * s, head + side * 3.6 * s, MAGENTA, 1.2 * s)
		_:
			b.circle(head - face * 1.2 * s, 3.9 * s, hair)
			b.circle(head - face * 1.4 * s - Vector2(0.8, 0.8) * s, 2.2 * s, hair.lightened(0.15))


# A row of plots along one side of the path between y_hi (nearer the start)
# and y_lo: [y0, y1, k] from a hash of where the run starts, never the RNG
static func _plots(y_lo: float, y_hi: float, salt: float, short: float, long: float, gap: float) -> Array:
	var out: Array = []
	var y := y_hi
	var k := 0
	while y > y_lo:
		var len := lerpf(short, long, _hk(float(k), salt))
		var y0 := maxf(y_lo, y - len)
		if y - y0 > short * 0.55:
			out.append([y0, y, salt * 100.0 + float(k)])
		y = y0 - gap * (0.4 + _hk(float(k), salt + 0.5))
		k += 1
	return out


# the strip a plot stands on, out from the path on its side
static func _plot_rect(side: float, y0: float, y1: float, inset: float, depth: float) -> Rect2:
	if side < 0.0:
		return Rect2(PATH_L - inset - depth, y0, depth, y1 - y0)
	return Rect2(PATH_R + inset, y0, depth, y1 - y0)


static func draw_edge_layer(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	var top: float = maxf(vt, m.GATE_Y - 40.0)
	var bot: float = minf(vb, float(m.START_Y) + 560.0)
	if bot <= top:
		return
	var was := b.lod
	b.lod = true
	_edge_gates(b, top, bot)
	_edge_corsari(b, top, bot)
	_edge_canyon(b, top, bot)
	_edge_selva(b, top, bot)
	_edge_loop(b, top, bot)
	_edge_picnic(b, top, bot)
	_seams(b, top, bot, -460.0, PATH_L)
	_seams(b, top, bot, PATH_R, 1740.0)
	_edge_bulbs(b, top, bot)
	b.lod = was


# where one land meets the next, the upper land's ground feathers over the
# lower's instead of stopping on a hard line: [y, colour on the far side,
# colour on the path]
const SEAMS: Array = [
	[CORSARI_Y0, Color(0.86, 0.84, 0.80), Color(0.86, 0.84, 0.80)],
	[CANYON_Y0, Color(0.72, 0.48, 0.28), Color(0.68, 0.48, 0.30)],
	[SELVA_Y0, Color(0.36, 0.28, 0.18), Color(0.36, 0.28, 0.18)],
	[LOOP_Y0, Color(0.84, 0.80, 0.74), Color(0.78, 0.74, 0.68)],
	[PICNIC_Y, Color(0.42, 0.62, 0.34), Color(0.42, 0.62, 0.34)],
]


static func _seams(b: ShapeBatch, top: float, bot: float, x0: float, x1: float, on_path := false) -> void:
	for sm: Array in SEAMS:
		var y: float = sm[0]
		if y < top - 80.0 or y > bot + 80.0:
			continue
		var col: Color = sm[2] if on_path else sm[1]
		b.band(PackedVector2Array([Vector2(x0, y - 4.0), Vector2(x1, y - 4.0), Vector2(x0, y + 46.0), Vector2(x1, y + 46.0)]),
			2, col, PackedFloat32Array([1.0, 0.0]))


static func _span(top: float, bot: float, y_lo: float, y_hi: float) -> Vector2:
	return Vector2(maxf(top - 160.0, y_lo), minf(bot + 160.0, y_hi))


# paving laid in big flags with their joints, between x0 and x1
static func _flags(b: ShapeBatch, x0: float, x1: float, lo: float, hi: float, base: Color, size := 46.0) -> void:
	b.rect(Rect2(x0, lo, x1 - x0, hi - lo), base)
	var joint := base.darkened(0.10)
	var y := floorf(lo / size) * size
	var row := int(absf(y) / size)
	while y < hi:
		b.line(Vector2(x0, y), Vector2(x1, y), joint, 1.2)
		var x := x0 + (size * 0.5 if row % 2 == 0 else 0.0)
		while x < x1:
			b.line(Vector2(x, maxf(y, lo)), Vector2(x, minf(y + size, hi)), joint, 1.2)
			x += size * 1.5
		if _hk(float(row), 3.0) > 0.6:
			var fx := x0 + _hk(float(row), 4.0) * (x1 - x0 - size)
			b.rect(Rect2(fx, y + 2.0, size * 1.4, size - 4.0), base.lightened(0.04))
		y += size
		row += 1


# --- the gates ---------------------------------------------------------------
# Outside the arch, the forecourt: ticket windows, planters, flags. The arch's
# towers stand in the park's wall. Inside, gift shops with striped awnings and
# a striped kiosk either side of the fountain.

const GATE_IN := -200.0      # the wall's inner face; the plaza begins
const GATE_OUT := -40.0      # the wall's outer face; the forecourt begins
const TOWER := 92.0


static func _tower_rect(side: float) -> Rect2:
	var cx := PATH_L - 48.0 if side < 0.0 else PATH_R + 48.0
	return Rect2(cx - TOWER * 0.5, ARCH.y - TOWER * 0.5, TOWER, TOWER)


static func _edge_gates(b: ShapeBatch, top: float, bot: float) -> void:
	var s := _span(top, bot, CORSARI_Y0, 820.0)
	if s.y <= s.x:
		return
	_flags(b, -460.0, PATH_L, s.x, s.y, PAVEMENT_LIT)
	_flags(b, PATH_R, 1740.0, s.x, s.y, PAVEMENT_LIT)
	# the park's wall, out from the towers either way
	if GATE_OUT > s.x and GATE_IN < s.y:
		for side: float in [-1.0, 1.0]:
			var wr := Rect2(-460.0, ARCH.y - 22.0, PATH_L - 48.0 + 460.0, 44.0) if side < 0.0 \
				else Rect2(PATH_R + 48.0, ARCH.y - 22.0, 1740.0 - PATH_R - 48.0, 44.0)
			_cast(b, wr, 22.0)
			b.rect(wr, Color(0.90, 0.74, 0.56))
			b.rect(Rect2(wr.position.x, wr.position.y, wr.size.x, 8.0), SAFFRON)
			b.rect(Rect2(wr.position.x, wr.end.y - 12.0, wr.size.x, 12.0), Color(0.78, 0.58, 0.42))
			# the wall's merlons, rounded like a sandcastle's
			var x := wr.position.x + 14.0
			while x < wr.end.x - 8.0:
				b.circle(Vector2(x, wr.position.y + 16.0), 7.0, Color(0.96, 0.82, 0.62))
				b.circle(Vector2(x - 1.5, wr.position.y + 14.5), 3.5, Color(1.0, 0.92, 0.74))
				x += 30.0
		for side: float in [-1.0, 1.0]:
			_gate_tower(b, _tower_rect(side), side)
	# plots: the forecourt outside, the plaza inside
	for side: float in [-1.0, 1.0]:
		for pl: Array in _plots(maxf(s.x, CORSARI_Y0), minf(GATE_IN - 10.0, s.y), 11.0 + side, 110.0, 150.0, 16.0):
			_gift_shop(b, side, pl[0], pl[1], pl[2])
		for pl: Array in _plots(maxf(s.x, GATE_OUT + 30.0), s.y, 13.0 + side, 120.0, 170.0, 40.0):
			_ticket_hall(b, side, pl[0], pl[1], pl[2])


static func _gate_tower(b: ShapeBatch, r: Rect2, side: float) -> void:
	_cast(b, r, 46.0)
	# the wall's face toward the forecourt, under the roof's eaves
	var face := Rect2(r.position.x, r.end.y - 4.0, r.size.x, 22.0)
	b.rect(face, TURQ.darkened(0.22))
	b.rect(Rect2(face.position.x, face.position.y, face.size.x, 4.0), TURQ.darkened(0.42))
	# its doorway and a round window
	b.rect(Rect2(r.get_center().x - 12.0, face.position.y + 4.0, 24.0, 18.0), INK)
	b.rect(r, TURQ.darkened(0.1))
	_hip(b, r.grow(-4.0), MAGENTA)
	b.circle(r.get_center() + Shade.light * 6.0, 7.0, Color(SHADOW, 0.3))
	b.circle(r.get_center(), 6.0, SAFFRON.darkened(0.1))
	b.circle(r.get_center() - Vector2(1.5, 1.5), 3.0, SAFFRON.lightened(0.3))
	# the pennant on the finial
	var tip := r.get_center() + Vector2(side * 4.0, -2.0)
	b.quad(tip, tip + Vector2(26.0 * side, -6.0), tip + Vector2(26.0 * side, 2.0), tip + Vector2(0.0, 6.0), SAFFRON)
	b.quad(tip, tip + Vector2(14.0 * side, -3.0), tip + Vector2(14.0 * side, 4.0), tip + Vector2(0.0, 6.0), MAGENTA.lightened(0.1))


# a gift shop inside the gates: stucco under a flat roof with its plant and
# a big sign on the parapet, a candy-striped awning over its windows
static func _gift_rect(side: float, y0: float, y1: float, k: float) -> Rect2:
	return _plot_rect(side, y0, y1, 34.0, 130.0 + _hk(k, 1.0) * 50.0)


static func _gift_shop(b: ShapeBatch, side: float, y0: float, y1: float, k: float) -> void:
	var r := _gift_rect(side, y0, y1, k)
	var wall: Color = _pick(STUCCO, k, 2.0)
	var accent: Color = _pick([MAGENTA, TURQ, Color(0.94, 0.46, 0.20), Color(0.36, 0.46, 0.86)], k, 3.0)
	_cast(b, r, 26.0)
	b.rect(Rect2(r.position.x, r.end.y - 2.0, r.size.x, 14.0), wall.darkened(0.22))
	_terrat(b, r, wall, wall.lerp(Color(0.86, 0.84, 0.80), 0.6), 16.0)
	# rooftop plant: a vent and an air-con box with their shadows
	var ac := Vector2(r.get_center().x + side * -12.0, r.position.y + 26.0 + _hk(k, 4.0) * (r.size.y - 60.0))
	b.rect(Rect2(ac + Vector2(4.0, 5.0), Vector2(22.0, 16.0)), Color(SHADOW, 0.3))
	b.rect(Rect2(ac, Vector2(22.0, 16.0)), Color(0.82, 0.82, 0.84))
	b.circle(ac + Vector2(11.0, 8.0), 5.5, Color(0.58, 0.58, 0.62))
	# the sign board along the path side of the roof, its letters as strokes
	var fx := r.end.x if side < 0.0 else r.position.x
	var sign := Rect2(fx - (14.0 if side < 0.0 else -2.0), r.position.y + 12.0, 12.0, r.size.y - 24.0)
	b.rect(Rect2(sign.position + Vector2(3.0, 4.0), sign.size), Color(SHADOW, 0.3))
	b.rect(sign, accent)
	b.rect(sign.grow(-2.0), accent.lightened(0.12))
	var ly := sign.position.y + 8.0
	while ly < sign.end.y - 8.0:
		b.rect(Rect2(sign.position.x + 3.0, ly, 6.0, 7.0), Color(1.0, 0.96, 0.86))
		ly += 11.0 + _hk(ly, 1.0) * 4.0
	# the awning out toward the path, striped, its scalloped edge
	var aw := Rect2(r.end.x, r.position.y + 8.0, 34.0, r.size.y - 16.0) if side < 0.0 \
		else Rect2(r.position.x - 34.0, r.position.y + 8.0, 34.0, r.size.y - 16.0)
	b.rect(Rect2(aw.position + Shade.light * 8.0, aw.size), Color(SHADOW, 0.22))
	var n := int(aw.size.y / 12.0)
	for i in range(n):
		var sy := aw.position.y + float(i) * aw.size.y / float(n)
		var col := accent if i % 2 == 0 else Color(0.98, 0.96, 0.90)
		b.rect(Rect2(aw.position.x, sy, aw.size.x, aw.size.y / float(n) + 0.5), col)
		var ex := aw.position.x if side > 0.0 else aw.end.x
		b.circle(Vector2(ex, sy + aw.size.y / float(n) * 0.5), aw.size.y / float(n) * 0.5, col)
	# the fold where the awning leaves the wall, shaded
	var wx := aw.position.x if side < 0.0 else aw.end.x - 6.0
	b.rect(Rect2(wx, aw.position.y, 6.0, aw.size.y), Color(SHADOW, 0.25))


# the ticket windows in the forecourt: a pavilion under a hipped roof, its
# windows on the path, a queue line painted on the paving
static func _ticket_hall(b: ShapeBatch, side: float, y0: float, y1: float, k: float) -> void:
	var depth := 110.0 + _hk(k, 1.0) * 40.0
	var r := _plot_rect(side, y0, y1, 40.0, depth)
	var wall: Color = _pick(STUCCO, k, 2.0)
	_cast(b, r, 22.0)
	b.rect(Rect2(r.position.x, r.end.y - 2.0, r.size.x, 14.0), wall.darkened(0.25))
	var fx := r.end.x if side < 0.0 else r.position.x
	# the windows: glass in the path-facing wall, under the eaves
	var wy := r.position.y + 14.0
	while wy < r.end.y - 30.0:
		b.rect(Rect2(fx - (4.0 if side < 0.0 else -1.0), wy, 3.0, 22.0), GLASS)
		wy += 34.0
	b.rect(r, wall.darkened(0.08))
	_hip(b, r.grow(-3.0), _pick([SAFFRON, TURQ, MAGENTA], k, 4.0))
	# planters at each end: a box of geraniums and an agave
	for py: float in [r.position.y - 16.0, r.end.y + 16.0]:
		var pc := Vector2(fx + side * -30.0, py)
		b.rect(Rect2(pc + Vector2(-18.0, -10.0) + Shade.light * 4.0, Vector2(36.0, 20.0)), Color(SHADOW, 0.25))
		b.rect(Rect2(pc + Vector2(-18.0, -10.0), Vector2(36.0, 20.0)), TERRACOTTA)
		b.rect(Rect2(pc + Vector2(-15.0, -7.0), Vector2(30.0, 14.0)), Color(0.30, 0.22, 0.16))
		for j in range(4):
			var fc := pc + Vector2(-10.0 + float(j) * 7.0, -1.0 + _hk(py + float(j), 1.0) * 3.0)
			b.circle(fc, 4.0, LEAF)
			b.circle(fc - Vector2(0.5, 1.0), 2.4, MAGENTA if j % 2 == 0 else Color(0.96, 0.30, 0.26))


# --- Cala del Corsari ---------------------------------------------------------
# A white fishing village: houses with terracotta roofs (some with a terrat,
# some a net loft), cobalt shutters and bougainvillea on the path, and on the
# west the harbour basin with its quay, boats and the pirate ship's frame.

static func _edge_corsari(b: ShapeBatch, top: float, bot: float) -> void:
	var s := _span(top, bot, CORSARI_Y1, CORSARI_Y0)
	if s.y <= s.x:
		return
	# the lanes behind: whitewashed setts
	for side: float in [-1.0, 1.0]:
		var x0 := -460.0 if side < 0.0 else PATH_R
		var x1 := PATH_L if side < 0.0 else 1740.0
		b.rect(Rect2(x0, s.x, x1 - x0, s.y - s.x), SETT)
		var y := floorf(s.x / 20.0) * 20.0
		while y < s.y:
			b.line(Vector2(x0, y), Vector2(x1, y), SETT_DARK, 1.0)
			y += 20.0
	var q := HARBOUR.grow(QUAY + 14.0)
	if q.end.y > s.x and q.position.y < s.y:
		_harbour(b)
	for side: float in [-1.0, 1.0]:
		# the back row first, so the front row's shadows fall over it
		for pl: Array in _plots(s.x, s.y, 21.0 + side, 70.0, 130.0, 4.0):
			if side < 0.0 and pl[1] > q.position.y - 10.0 and pl[0] < q.end.y + 10.0:
				continue
			var depth := 120.0 + _hk(pl[2], 9.0) * 60.0
			var br := _plot_rect(side, pl[0], pl[1], 30.0 + 150.0, depth)
			_cast(b, br, 18.0)
			_roof(b, br, (_pick(TILES, pl[2], 3.0) as Color).darkened(0.06), _hk(pl[2], 4.0) < 0.5)
		for pl: Array in _plots(s.x, s.y, 23.0 + side, 76.0, 128.0, 10.0):
			if side < 0.0 and pl[1] > q.position.y - 30.0 and pl[0] < q.end.y + 30.0:
				continue
			_village_house(b, side, pl[0], pl[1], pl[2])


static func _house_rect(side: float, y0: float, y1: float, k: float) -> Rect2:
	return _plot_rect(side, y0, y1, 12.0, 120.0 + _hk(k, 1.0) * 50.0)


static func _house_door_y(r: Rect2, k: float) -> float:
	return r.position.y + r.size.y * (0.35 + _hk(k, 9.0) * 0.3)


static func _village_house(b: ShapeBatch, side: float, y0: float, y1: float, k: float) -> void:
	var r := _house_rect(side, y0, y1, k)
	var kind := _hk(k, 2.0)
	_cast(b, r, 24.0)
	# the south wall under the eaves, whitewash with a window
	b.rect(Rect2(r.position.x, r.end.y - 2.0, r.size.x, 14.0), WHITE_SHADE)
	b.rect(Rect2(r.position.x + r.size.x * 0.4, r.end.y + 2.0, 12.0, 8.0), _pick(SHUTTERS, k, 5.0))
	var tile: Color = _pick(TILES, k, 3.0)
	var fx := r.end.x if side < 0.0 else r.position.x
	if kind < 0.24:
		# a terrat: the parapet, a floor of red rajoles, a water tank, washing
		_terrat(b, r, WHITEWASH, Color(0.82, 0.56, 0.44), 12.0)
		var tank := Vector2(r.get_center().x - side * 18.0, r.position.y + 24.0)
		_disc_shadow(b, tank, 10.0, 6.0)
		b.circle(tank, 10.0, Color(0.86, 0.86, 0.84))
		b.circle(tank - Vector2(2.0, 2.0), 5.0, Color(0.96, 0.96, 0.94))
		var ly := r.position.y + r.size.y * 0.62
		b.line(Vector2(r.position.x + 10.0, ly), Vector2(r.end.x - 10.0, ly), Color(0.5, 0.5, 0.5), 1.0)
		for j in range(4):
			var lx := r.position.x + 18.0 + float(j) * (r.size.x - 36.0) / 4.0
			b.rect(Rect2(lx + 2.0, ly + 2.0, 12.0, 10.0), Color(SHADOW, 0.2))
			b.rect(Rect2(lx, ly, 12.0, 10.0), _pick([Color(0.95, 0.95, 0.92), Color(0.30, 0.52, 0.80), Color(0.92, 0.40, 0.40), SAFFRON], k + float(j), 6.0))
	else:
		_roof(b, r, tile, true)
		if kind > 0.84:
			# a net loft: the nets spread to dry over the slope
			var nr := Rect2(r.position.x + 8.0, r.position.y + 10.0, r.size.x * 0.4, r.size.y * 0.5)
			b.rect(nr, Color(0.22, 0.50, 0.42, 0.75))
			var nx := nr.position.x + 4.0
			while nx < nr.end.x:
				b.line(Vector2(nx, nr.position.y), Vector2(nx, nr.end.y), Color(0.14, 0.36, 0.30, 0.8), 1.0)
				nx += 5.0
			b.circle(nr.position + Vector2(nr.size.x - 6.0, nr.size.y * 0.5), 4.0, Color(0.92, 0.80, 0.40))
		# a chimney: a whitewashed stack, its pot and its shadow
		var ch := Vector2(r.position.x + r.size.x * (0.22 + _hk(k, 7.0) * 0.5), r.position.y + 14.0 + _hk(k, 8.0) * (r.size.y - 40.0))
		b.rect(Rect2(ch + Shade.light * 12.0, Vector2(14.0, 14.0)), Color(SHADOW, 0.32))
		b.rect(Rect2(ch, Vector2(14.0, 14.0)), WHITE_SHADE)
		b.rect(Rect2(ch, Vector2(14.0, 3.0)), WHITEWASH)
		b.rect(Rect2(ch + Vector2(4.0, 4.0), Vector2(6.0, 6.0)), Color(0.24, 0.20, 0.18))
	# the wall on the path: whitewash, a door with its step, shutters
	var wall := Rect2(fx - (10.0 if side < 0.0 else 0.0), r.position.y, 10.0, r.size.y)
	b.rect(wall, WHITEWASH)
	b.rect(Rect2(wall.position.x + (0.0 if side < 0.0 else 8.0), wall.position.y, 2.0, wall.size.y), WHITE_SHADE)
	var sh: Color = _pick(SHUTTERS, k, 5.0)
	var door_y := _house_door_y(r, k)
	var ox := wall.end.x if side < 0.0 else wall.position.x - 10.0
	b.rect(Rect2(ox, door_y - 10.0, 10.0, 20.0), Color(0.80, 0.78, 0.74))
	b.rect(Rect2(wall.position.x + 2.0, door_y - 9.0, 6.0, 18.0), Color(0.46, 0.30, 0.18))
	var wy := r.position.y + 14.0
	while wy < r.end.y - 14.0:
		if absf(wy - door_y) > 22.0:
			b.rect(Rect2(wall.position.x + 1.0, wy - 8.0, 8.0, 16.0), sh)
			b.line(Vector2(wall.position.x + 1.0, wy), Vector2(wall.position.x + 9.0, wy), sh.darkened(0.3), 1.0)
		wy += 30.0
	# bougainvillea over the wall, or pots on the step
	if _hk(k, 10.0) < 0.55:
		var by := r.position.y + 10.0 + _hk(k, 11.0) * (r.size.y - 30.0)
		var bx := wall.get_center().x
		b.circle(Vector2(bx, by), 12.0, LEAF)
		b.circle(Vector2(bx - side * 2.0, by + 12.0), 10.0, LEAF.darkened(0.1))
		for j in range(6):
			b.circle(Vector2(bx + (_hk(by + float(j), 1.0) - 0.5) * 16.0, by - 4.0 + float(j) * 4.0), 4.5, MAGENTA.lightened(0.08 * float(j % 2)))
	else:
		for j in range(3):
			var pp := Vector2(ox + 5.0, door_y + 18.0 + float(j) * 10.0)
			b.circle(pp, 4.5, TERRACOTTA)
			b.circle(pp, 3.0, LEAF_LIT)


static func _harbour(b: ShapeBatch) -> void:
	var w := HARBOUR
	var q := w.grow(QUAY)
	# the quay: big stone flags round the basin, its kerb, bollards
	_cast(b, q, 6.0)
	b.rect(q, STONE.lightened(0.10))
	var y := q.position.y + 22.0
	while y < q.end.y:
		b.line(Vector2(q.position.x, y), Vector2(q.end.x, y), STONE.darkened(0.04), 1.2)
		y += 22.0
	var x := q.position.x + 30.0
	while x < q.end.x:
		b.line(Vector2(x, q.position.y), Vector2(x, q.end.y), STONE.darkened(0.04), 1.2)
		x += 30.0
	# the basin: the wall's shadow at its sunny rim, deep water out from it,
	# a soft lighter middle, ripples; corners rounded off
	var rr := 26.0
	var poly := PackedVector2Array()
	for c: Array in [[w.position + Vector2(rr, rr), PI], [Vector2(w.end.x - rr, w.position.y + rr), PI * 1.5],
			[w.end - Vector2(rr, rr), 0.0], [Vector2(w.position.x + rr, w.end.y - rr), PI * 0.5]]:
		for i in range(5):
			poly.append((c[0] as Vector2) + Vector2.from_angle(float(c[1]) + float(i) * PI * 0.125) * rr)
	b.polygon(poly, STONE.darkened(0.30))
	var inner := PackedVector2Array()
	var cen := w.get_center()
	for p: Vector2 in poly:
		inner.append(cen + (p - cen) * Vector2((w.size.x - 8.0) / w.size.x, (w.size.y - 8.0) / w.size.y))
	b.polygon(inner, WATER_DEEP)
	# soft gradient: lighter toward the middle, no hard edge
	b.glow(cen + Vector2(-6.0, -6.0), w.size.y * 0.62, Color(WATER, 0.95), 0.25)
	b.glow(cen + Vector2(-26.0, -40.0), w.size.y * 0.32, Color(WATER.lightened(0.18), 0.45), 0.1)
	# the quay's shadow on the water along the north and west walls
	var n := inner.size()
	var band := PackedVector2Array()
	for i in range(n):
		band.append(inner[i])
	for i in range(n):
		band.append(cen + (inner[i] - cen) * 0.86)
	b.band(band, n, Color(0.04, 0.16, 0.26), PackedFloat32Array([0.45, 0.0]))
	# ripples
	for i in range(9):
		var rp := w.position + Vector2(30.0 + _hk(float(i), 1.0) * (w.size.x - 60.0), 26.0 + _hk(float(i), 2.0) * (w.size.y - 52.0))
		b.line(rp, rp + Vector2(18.0, 0.0), Color(1.0, 1.0, 1.0, 0.22), 1.4)
	# the kerb
	b.rect(Rect2(q.position.x, q.position.y, q.size.x, 3.0), STONE.lightened(0.22))
	# bollards and coiled rope on the quay
	for bp: Vector2 in [Vector2(w.end.x + 15.0, w.position.y + 40.0), Vector2(w.end.x + 15.0, w.end.y - 40.0), Vector2(w.position.x + 60.0, w.end.y + 15.0)]:
		_disc_shadow(b, bp, 6.0, 6.0)
		b.circle(bp, 6.0, Color(0.24, 0.24, 0.26))
		b.circle(bp - Vector2(1.5, 1.5), 3.0, Color(0.44, 0.44, 0.46))
	# two llaguts moored on the far side, their shadows on the water
	for i in range(2):
		var bc := Vector2(w.position.x + 30.0, w.position.y + 52.0 + float(i) * 120.0)
		var hull := PackedVector2Array([bc + Vector2(0.0, -30.0), bc + Vector2(11.0, -12.0), bc + Vector2(10.0, 22.0), bc + Vector2(-10.0, 22.0), bc + Vector2(-11.0, -12.0)])
		var sh := PackedVector2Array()
		for p: Vector2 in hull:
			sh.append(p + Shade.light * 6.0)
		b.polygon(sh, Color(0.02, 0.10, 0.18, 0.35))
		b.polygon(hull, Color(0.94, 0.94, 0.90) if i == 0 else Color(0.20, 0.44, 0.70))
		b.rect(Rect2(bc + Vector2(-7.0, -10.0), Vector2(14.0, 28.0)), Color(0.66, 0.50, 0.32))
		b.line(bc + Vector2(-7.0, 2.0), bc + Vector2(7.0, 2.0), Color(0.44, 0.30, 0.18), 2.0)
		b.line(bc + Vector2(0.0, -30.0), Vector2(q.position.x + 6.0, bc.y - 34.0), Color(0.80, 0.72, 0.56), 1.2)
	# the ship's frame stands on the quay: an A-frame either side of the
	# basin, its legs splayed along the swing, the axle beam over the water
	for sx: float in [q.position.x + 14.0, q.end.x - 14.0]:
		var axle := Vector2(sx, SHIP.y)
		for d: float in [-1.0, 1.0]:
			var foot := axle + Vector2(0.0, d * 64.0)
			b.line(axle + Shade.light * 34.0, foot + Shade.light * 2.0, Color(SHADOW, 0.30), 9.0)
			b.line(axle, foot, STEEL_DARK, 9.0)
			b.line(axle + Vector2(-2.0, 0.0), foot + Vector2(-2.0, 0.0), STEEL, 4.0)
			b.rect(Rect2(foot - Vector2(9.0, 6.0), Vector2(18.0, 12.0)), STEEL_DARK)
		b.line(axle + Vector2(-8.0, -32.0), axle + Vector2(-8.0, 32.0), STEEL_DARK, 3.0)


# --- Canyon del Sol -------------------------------------------------------------
# Red dust, mesas behind, false-fronted timber stores along the boardwalk
# with their porches, the mine station on the west, a water tower, cacti.

static func _edge_canyon(b: ShapeBatch, top: float, bot: float) -> void:
	var s := _span(top, bot, CANYON_Y1, CANYON_Y0)
	if s.y <= s.x:
		return
	for side: float in [-1.0, 1.0]:
		var x0 := -460.0 if side < 0.0 else PATH_R
		var x1 := PATH_L if side < 0.0 else 1740.0
		b.rect(Rect2(x0, s.x, x1 - x0, s.y - s.x), DUST)
		# wind ripples and pebbles in the dust
		var y := floorf(s.x / 26.0) * 26.0
		while y < s.y:
			var rx := lerpf(x0, x1, _h(y + side))
			b.line(Vector2(rx, y), Vector2(rx + 34.0, y + 4.0), DUST_LIT, 2.0)
			b.line(Vector2(rx + 10.0, y + 9.0), Vector2(rx + 40.0, y + 13.0), DUST.darkened(0.10), 1.5)
			b.circle(Vector2(lerpf(x0, x1, _h(y * 1.3 + side)), y + 18.0), 2.5, DUST.darkened(0.2))
			y += 26.0
		_mesa(b, side, s.x, s.y)
	if MINE_STATION.end.y > s.x - 40.0 and MINE_STATION.position.y < s.y + 40.0:
		_mine_station(b)
	for side: float in [-1.0, 1.0]:
		var prev := INF
		for pl: Array in _plots(s.x, s.y, 31.0 + side, 84.0, 130.0, 60.0):
			# a cactus or a cart wheel and barrels in the gap below this plot
			if prev - pl[1] > 34.0 and prev < INF:
				var gc := Vector2(PATH_L - 70.0 if side < 0.0 else PATH_R + 70.0, (prev + pl[1]) * 0.5)
				if _hk(pl[2], 13.0) < 0.6:
					_cactus(b, gc, pl[2])
				else:
					for j in range(3):
						var bc := gc + Vector2(float(j - 1) * 15.0, (_hk(pl[2], 14.0 + float(j)) - 0.5) * 8.0)
						_disc_shadow(b, bc, 7.0, 6.0)
						b.circle(bc, 7.0, WOOD_DARK)
						b.circle(bc, 5.0, WOOD)
			prev = pl[0]
			if side < 0.0 and pl[1] > MINE_STATION.position.y - 20.0 and pl[0] < MINE_STATION.end.y + 20.0:
				continue
			if side > 0.0 and _hk(pl[2], 12.0) < 0.16:
				_water_tower(b, Vector2(PATH_R + 80.0, (pl[0] + pl[1]) * 0.5), pl[2])
				continue
			_western(b, side, pl[0], pl[1], pl[2])


# The mesa behind each row: a cliff face toward the path in its own shade,
# terraces of lighter strata, a sunlit top with scrub
static func _mesa(b: ShapeBatch, side: float, lo: float, hi: float) -> void:
	var step := 40.0
	var y := floorf(lo / step) * step
	var far := -460.0 if side < 0.0 else 1740.0
	while y < hi:
		var e0 := _mesa_x(side, y)
		var e1 := _mesa_x(side, y + step)
		var face := ROCK_DARK if side < 0.0 else ROCK.lightened(0.06)
		b.quad(Vector2(e0, y), Vector2(e1, y + step), Vector2(far, y + step), Vector2(far, y), face)
		# strata: each terrace set back and lighter
		for t in range(1, 4):
			var off := float(t) * 22.0 * -side
			var col := ROCK.lerp(ROCK_LIT, float(t - 1) / 2.0)
			b.quad(Vector2(e0 + off, y), Vector2(e1 + off, y + step), Vector2(far, y + step), Vector2(far, y), col)
			b.line(Vector2(e0 + off, y), Vector2(e1 + off, y + step), col.darkened(0.25), 2.0)
		# scrub on the top
		var sx := e0 - side * (90.0 + _h(y + side) * 60.0)
		b.circle(Vector2(sx, y + 18.0), 7.0, Color(0.46, 0.50, 0.26))
		b.circle(Vector2(sx - 2.0, y + 16.0), 4.0, Color(0.58, 0.62, 0.32))
		y += step
	# the cliff's foot: a shadow on the dust on the shaded side, talus
	y = floorf(lo / step) * step
	while y < hi:
		var e0 := _mesa_x(side, y)
		var e1 := _mesa_x(side, y + step)
		if side < 0.0:
			b.quad(Vector2(e0, y), Vector2(e1, y + step), Vector2(e1 + 26.0, y + step), Vector2(e0 + 26.0, y), Color(SHADOW, 0.22))
		b.circle(Vector2(e0 - side * -8.0, y + 12.0), 6.0 + _h(y) * 5.0, ROCK.darkened(0.1))
		b.circle(Vector2(e0 - side * -16.0, y + 30.0), 4.0, ROCK_DARK)
		y += step


static func _mesa_x(side: float, y: float) -> float:
	var wob := sin(y * 0.011) * 26.0 + (_h(floorf(y / 40.0)) - 0.5) * 22.0
	return (PATH_L - 176.0 + wob) if side < 0.0 else (PATH_R + 182.0 + wob)


# a false-fronted timber store: its roof (tin, shingle or a brick parapet),
# the tall painted front on the boardwalk with its sign, the porch before it
static func _western_rect(side: float, y0: float, y1: float, k: float) -> Rect2:
	return _plot_rect(side, y0, y1, 34.0, 80.0 + _hk(k, 1.0) * 34.0)


static func _arcade_rect(side: float, y0: float, y1: float, k: float) -> Rect2:
	return _plot_rect(side, y0, y1, 26.0, 96.0 + _hk(k, 1.0) * 40.0)


static func _western(b: ShapeBatch, side: float, y0: float, y1: float, k: float) -> void:
	var r := _western_rect(side, y0, y1, k)
	var paint: Color = _pick(PAINTS, k, 2.0)
	var kind := _hk(k, 3.0)
	_cast(b, r, 22.0)
	b.rect(Rect2(r.position.x, r.end.y - 2.0, r.size.x, 12.0), WOOD_DARK)
	var plank := r.position.x + 6.0
	while plank < r.end.x:
		b.line(Vector2(plank, r.end.y), Vector2(plank, r.end.y + 10.0), WOOD_DARK.darkened(0.3), 1.0)
		plank += 8.0
	if kind < 0.45:
		_roof(b, r, TIN, false, 4.0)
		for j in range(2):
			var rp := r.position + Vector2(10.0 + _hk(k, 4.0 + float(j)) * (r.size.x - 40.0), 8.0 + _hk(k, 6.0 + float(j)) * (r.size.y - 30.0))
			b.rect(Rect2(rp, Vector2(18.0 + float(j) * 8.0, 10.0)), Color(RUST, 0.55))
	elif kind < 0.8:
		_roof(b, r, Color(0.50, 0.36, 0.24), false, 7.0)
		var cy := r.position.y + 5.0
		var row := 0
		while cy < r.end.y - 3.0:
			var cx := r.position.x + (5.0 if row % 2 == 0 else 0.0)
			while cx < r.end.x:
				b.line(Vector2(cx, cy), Vector2(cx, cy + 6.0), Color(0.30, 0.20, 0.12, 0.5), 1.0)
				cx += 10.0
			cy += 7.0
			row += 1
	else:
		_terrat(b, r, Color(0.62, 0.30, 0.22), Color(0.26, 0.24, 0.24), 20.0)
	# a stovepipe and its smoke-black ring
	var pipe := Vector2(r.position.x + r.size.x * (0.3 + _hk(k, 8.0) * 0.4), r.position.y + 14.0 + _hk(k, 9.0) * (r.size.y - 30.0))
	b.circle(pipe + Shade.light * 10.0, 5.0, Color(SHADOW, 0.3))
	b.circle(pipe, 5.0, Color(0.20, 0.20, 0.22))
	b.circle(pipe, 2.5, INK)
	# the false front: taller than the roof, wider than the store
	var fx := r.end.x if side < 0.0 else r.position.x - 12.0
	var front := Rect2(fx, r.position.y - 8.0, 12.0, r.size.y + 16.0)
	if side > 0.0:
		b.rect(Rect2(front.end.x, front.position.y + 4.0, 14.0, front.size.y - 4.0), Color(SHADOW, 0.30))
	b.rect(front, paint.darkened(0.25))
	b.rect(front.grow(-2.0), paint)
	b.rect(Rect2(front.position.x, front.position.y, front.size.x, 3.0), paint.lightened(0.25))
	# its sign: a board across the top of the front, lettered in strokes
	var sign := Rect2(front.position.x + 2.0, front.get_center().y - 26.0, 8.0, 52.0)
	b.rect(sign, Color(0.94, 0.88, 0.70) if paint.get_luminance() < 0.5 else Color(0.24, 0.16, 0.10))
	var ly := sign.position.y + 4.0
	while ly < sign.end.y - 5.0:
		b.rect(Rect2(sign.position.x + 2.0, ly, 4.0, 4.0), paint.darkened(0.3))
		ly += 7.0
	# the porch: a plank roof on posts between the front and the boardwalk
	var px := front.end.x if side < 0.0 else front.position.x - 22.0
	var porch := Rect2(px, r.position.y + 4.0, 22.0, r.size.y - 8.0)
	b.rect(Rect2(porch.position + Shade.light * 8.0, porch.size), Color(SHADOW, 0.24))
	b.rect(porch, WOOD)
	var py := porch.position.y + 6.0
	while py < porch.end.y:
		b.line(Vector2(porch.position.x, py), Vector2(porch.end.x, py), WOOD_DARK, 1.0)
		py += 6.0
	var post_x := porch.end.x - 3.0 if side < 0.0 else porch.position.x + 3.0
	for pyy: float in [porch.position.y + 3.0, porch.end.y - 3.0]:
		b.circle(Vector2(post_x, pyy), 3.5, WOOD_DARK)
	# a barrel or a water trough out front
	if _hk(k, 10.0) < 0.5:
		var bc := Vector2(post_x + 8.0 * side, porch.position.y - 10.0)
		_disc_shadow(b, bc, 8.0, 6.0)
		b.circle(bc, 8.0, WOOD_DARK)
		b.circle(bc, 6.0, WOOD)
		b.line(bc + Vector2(-6.0, 0.0), bc + Vector2(6.0, 0.0), STEEL_DARK, 1.0)


static func _mine_station(b: ShapeBatch) -> void:
	var r := MINE_STATION
	_cast(b, r, 30.0)
	# the track running in at the south end and out at the north
	b.rect(Rect2(r.position.x + 50.0, r.position.y - 30.0, 32.0, r.size.y + 60.0), Color(0.44, 0.30, 0.20))
	# the platform along the path side, under the eaves
	var plat := Rect2(r.end.x - 40.0, r.position.y + 10.0, 40.0, r.size.y - 20.0)
	b.rect(plat, WOOD_LIT)
	var pl := plat.position.y
	while pl < plat.end.y:
		b.line(Vector2(plat.position.x, pl), Vector2(plat.end.x, pl), WOOD_DARK, 1.0)
		pl += 7.0
	# the shed's long shingle roof, ridge up the screen
	var roof := Rect2(r.position.x, r.position.y, r.size.x - 40.0, r.size.y)
	_roof(b, roof, Color(0.46, 0.32, 0.22), true, 7.0)
	# a louvred lantern along the ridge
	var lan := Rect2(roof.get_center().x - 12.0, roof.position.y + 40.0, 24.0, roof.size.y - 80.0)
	b.rect(Rect2(lan.position + Shade.light * 8.0, lan.size), Color(SHADOW, 0.3))
	_roof(b, lan, Color(0.40, 0.28, 0.20), true, 5.0)
	# the station's sign over the platform: a big board, ore cart on it
	var sign := Rect2(r.end.x - 14.0, r.get_center().y - 50.0, 12.0, 100.0)
	b.rect(Rect2(sign.position + Vector2(4.0, 6.0), sign.size), Color(SHADOW, 0.3))
	b.rect(sign, Color(0.24, 0.16, 0.10))
	b.rect(sign.grow(-2.0), SAFFRON.darkened(0.1))
	b.rect(Rect2(sign.position.x + 3.0, sign.get_center().y - 14.0, 6.0, 28.0), Color(0.40, 0.24, 0.16))
	# lanterns on the platform posts
	var ly := plat.position.y + 20.0
	while ly < plat.end.y:
		b.circle(Vector2(plat.end.x - 3.0, ly), 3.5, WOOD_DARK)
		ly += 52.0


static func _water_tower(b: ShapeBatch, c: Vector2, k: float) -> void:
	var r := 34.0
	_disc_shadow(b, c, r, 60.0)
	for d: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		var leg := c + d * r * 0.75
		b.line(leg + Shade.light * 30.0, leg + Shade.light * 58.0, Color(SHADOW, 0.3), 5.0)
	b.circle(c, r, WOOD_DARK)
	_cone(b, c, r - 3.0, Color(0.56, 0.38, 0.24), Color(0.48, 0.32, 0.20), 16, k)
	# the spout swung out over the boardwalk side
	b.line(c + Vector2(-r * 0.6, 4.0), c + Vector2(-r - 18.0, 10.0), STEEL_DARK, 4.0)


static func _cactus(b: ShapeBatch, c: Vector2, k: float) -> void:
	var col := Color(0.30, 0.52, 0.30)
	b.capsule(c + Shade.light * 6.0, c + Shade.light * 46.0, 6.0, Color(SHADOW, 0.28))
	for j in range(2 + int(_h(k) * 2.0)):
		var a := -PI * 0.5 + (float(j) - 0.5) * 1.6 + _h(k + float(j)) * 0.4
		var tip := c + Vector2.from_angle(a) * (14.0 + _h(k + 3.0) * 6.0)
		b.capsule(c, tip, 4.5, col.darkened(0.08))
		b.circle(tip - Vector2(1.0, 1.0), 2.5, col.lightened(0.2))
	b.circle(c, 8.0, col)
	b.circle(c - Vector2(2.0, 2.0), 4.0, col.lightened(0.18))
	b.circle(c - Vector2(2.5, 3.0), 1.5, Color(0.96, 0.60, 0.70))


# --- Selva dels Llorers ---------------------------------------------------------
# Big-leaved planting edge to edge, bamboo fences along the path, thatched
# huts in their clearings with tiki torches, and east of the path the flume's
# lagoon under its lift tower.

static func _edge_selva(b: ShapeBatch, top: float, bot: float) -> void:
	var s := _span(top, bot, SELVA_Y1, SELVA_Y0)
	if s.y <= s.x:
		return
	b.rect(Rect2(-460.0, s.x, PATH_L + 460.0, s.y - s.x), EARTH)
	b.rect(Rect2(PATH_R, s.x, 1740.0 - PATH_R, s.y - s.x), EARTH)
	var huts: Array = []
	for side: float in [-1.0, 1.0]:
		for pl: Array in _plots(s.x, s.y, 41.0 + side, 120.0, 170.0, 140.0):
			var c := Vector2(PATH_L - 110.0 if side < 0.0 else PATH_R + 110.0, (pl[0] + pl[1]) * 0.5)
			if side > 0.0 and c.y > FLUME_TOP.y - 100.0 and c.y < FLUME_POOL.end.y + 90.0:
				continue
			huts.append([c, pl[2], side])
	var pool := FLUME_POOL.grow(60.0)
	# the planting, everywhere but the clearings and the lagoon
	var y := floorf(s.x / 44.0) * 44.0
	while y < s.y:
		var row := int(absf(y) / 44.0)
		var x := -200.0 + (22.0 if row % 2 == 0 else 0.0)
		while x < 1500.0:
			if x > PATH_L - 24.0 and x < PATH_R + 24.0:
				x = PATH_R + 24.0 + (22.0 if row % 2 == 0 else 0.0)
				continue
			var p := Vector2(x + (_h(x * 0.3 + y) - 0.5) * 24.0, y + (_h(x + y * 0.7) - 0.5) * 20.0)
			var clear := pool.has_point(p) or Rect2(FLUME_TOP.x - 60.0, FLUME_TOP.y - 60.0, 160.0, 280.0).has_point(p)
			for hu: Array in huts:
				if p.distance_to(hu[0]) < 92.0:
					clear = true
					break
			if not clear:
				_plant(b, p, x * 0.17 + y, 1.0)
			x += 44.0
		y += 44.0
	for hu: Array in huts:
		_hut(b, hu[0], hu[1], hu[2])
	for side: float in [-1.0, 1.0]:
		_bamboo_fence(b, side, s.x, s.y, huts)
	if pool.end.y > s.x and pool.position.y < s.y + 300.0:
		_lagoon(b)


# a clump of big leaves round a centre: each a pointed blade with its rib
static func _plant(b: ShapeBatch, c: Vector2, k: float, sc: float) -> void:
	var n := 5 + int(_h(k) * 3.0)
	b.circle(c + Shade.light * 10.0, 22.0 * sc, Color(SHADOW, 0.22))
	for i in range(n):
		var a := float(i) * TAU / float(n) + _h(k + 1.0) * 2.0
		var dir := Vector2.from_angle(a)
		var len := (26.0 + _h(k + float(i)) * 16.0) * sc
		var wid := (8.0 + _h(k + float(i) * 2.0) * 5.0) * sc
		var col: Color = [LEAF, LEAF_LIT, LEAF_DARK, LEAF.lightened(0.06)][(i + int(k)) % 4]
		var lit := dir.dot(Vector2(-0.5, -0.866))
		col = col.lightened(0.10 * maxf(lit, 0.0))
		var base := c + dir * 3.0
		var mid := c + dir * len * 0.5
		var tip := c + dir * len
		var n2 := dir.orthogonal() * wid * 0.5
		b.quad(base, mid + n2, tip, mid - n2, col)
		b.line(base, tip - dir * 3.0, col.lightened(0.22), 1.2)
	b.circle(c, 3.0 * sc, LEAF_DARK)


static func _hut(b: ShapeBatch, c: Vector2, k: float, side: float) -> void:
	# the clearing: trodden earth, lighter where the sun lands
	b.circle(c, 88.0, EARTH_LIT)
	b.circle(c + Vector2(-8.0, -8.0), 70.0, EARTH_LIT.lightened(0.06))
	if _hk(k, 1.0) < 0.6:
		var r := 46.0 + _hk(k, 2.0) * 12.0
		_disc_shadow(b, c, r, 26.0)
		_thatch(b, c, r, k)
	else:
		var r := Rect2(c.x - 60.0, c.y - 44.0, 120.0, 88.0)
		_cast(b, r, 24.0)
		_hip(b, r, THATCH)
		# straw courses over the hip
		var yy := r.position.y + 8.0
		while yy < r.end.y:
			b.line(Vector2(r.position.x + 6.0, yy), Vector2(r.end.x - 6.0, yy), Color(THATCH_DARK, 0.45), 1.0)
			yy += 8.0
		b.line(Vector2(r.position.x, r.end.y), Vector2(r.end.x, r.end.y), THATCH_DARK, 3.0)
	# a carved post at the door toward the path, a torch either side
	var door := c + Vector2(-side * 62.0, 0.0)
	b.rect(Rect2(door + Vector2(-6.0, -6.0) + Shade.light * 10.0, Vector2(12.0, 12.0)), Color(SHADOW, 0.3))
	b.rect(Rect2(door + Vector2(-6.0, -6.0), Vector2(12.0, 12.0)), WOOD_DARK)
	b.rect(Rect2(door + Vector2(-4.0, -4.0), Vector2(8.0, 8.0)), _pick([TURQ, MAGENTA, SAFFRON], k, 3.0))
	b.circle(door + Vector2(-2.0, -1.0), 1.2, INK)
	b.circle(door + Vector2(2.0, -1.0), 1.2, INK)


static func _torch_spots(side: float, c: Vector2) -> Array[Vector2]:
	return [c + Vector2(-side * 70.0, -30.0), c + Vector2(-side * 70.0, 30.0)]


# a bamboo fence along the path's edge, canes lashed at each post, broken
# where a hut's path comes out
static func _bamboo_fence(b: ShapeBatch, side: float, lo: float, hi: float, huts: Array) -> void:
	var x := PATH_L - 10.0 if side < 0.0 else PATH_R + 10.0
	var y := floorf(lo / 12.0) * 12.0
	while y < hi:
		var gap := false
		for hu: Array in huts:
			if float(hu[2]) == side and absf((hu[0] as Vector2).y - y) < 18.0:
				gap = true
		if not gap:
			b.capsule(Vector2(x + Shade.light.x * 6.0, y + Shade.light.y * 6.0), Vector2(x + Shade.light.x * 6.0, y + 12.0 + Shade.light.y * 6.0), 3.0, Color(SHADOW, 0.25))
			b.capsule(Vector2(x, y), Vector2(x, y + 10.0), 3.2, BAMBOO.darkened(0.1 * float(int(absf(y) / 12.0) % 2)))
			b.line(Vector2(x - 3.0, y + 11.0), Vector2(x + 3.0, y + 11.0), BAMBOO.darkened(0.35), 1.2)
			if int(absf(y) / 12.0) % 8 == 0:
				b.circle(Vector2(x, y), 5.0, WOOD_DARK)
				b.circle(Vector2(x, y), 3.0, BAMBOO.lightened(0.2))
		y += 12.0


static func _lagoon(b: ShapeBatch) -> void:
	var c := FLUME_POOL.get_center()
	var rx := FLUME_POOL.size.x * 0.5
	var ry := FLUME_POOL.size.y * 0.5
	# the rocks round it, lit on their sunny side
	for i in range(26):
		var a := float(i) * TAU / 26.0
		var rr := 1.06 + _h(float(i)) * 0.10
		var p := c + Vector2(cos(a) * rx * rr, sin(a) * ry * rr)
		var r := 12.0 + _h(float(i) + 3.0) * 10.0
		_disc_shadow(b, p, r, 6.0)
		b.circle(p, r, Color(0.50, 0.46, 0.40))
		b.circle(p - Vector2(3.0, 3.0), r * 0.6, Color(0.62, 0.58, 0.50))
	# the water: deep, soft lighter middle, the rocks' shade at its rim
	var poly := PackedVector2Array()
	for i in range(28):
		var a := float(i) * TAU / 28.0
		poly.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	b.polygon(poly, WATER_DEEP)
	b.glow(c + Vector2(-10.0, -6.0), ry * 1.05, Color(WATER, 0.95), 0.3)
	b.glow(c + Vector2(-30.0, -30.0), ry * 0.5, Color(WATER.lightened(0.2), 0.4), 0.1)
	var band := PackedVector2Array()
	for p: Vector2 in poly:
		band.append(p)
	for p: Vector2 in poly:
		band.append(c + (p - c) * 0.82)
	b.band(band, poly.size(), Color(0.04, 0.16, 0.24), PackedFloat32Array([0.5, 0.0]))
	# foam where the drop comes in
	var foot := Vector2(FLUME_FOOT.x, FLUME_POOL.position.y + 16.0)
	b.glow(foot, 34.0, Color(1.0, 1.0, 1.0, 0.45), 0.2)
	# the boarding pavilion north-west of it, at the head of the queue
	var pav := Rect2(PATH_R + 14.0, FLUME_POOL.position.y - 120.0, 110.0, 84.0)
	_cast(b, pav, 22.0)
	b.rect(Rect2(pav.position.x - 4.0, pav.end.y - 4.0, pav.size.x + 8.0, 12.0), WOOD_DARK)
	_hip(b, pav, THATCH)
	var yy := pav.position.y + 8.0
	while yy < pav.end.y:
		b.line(Vector2(pav.position.x + 6.0, yy), Vector2(pav.end.x - 6.0, yy), Color(THATCH_DARK, 0.45), 1.0)
		yy += 8.0
	# the lift tower: a timber frame at the top of the drop
	var t := FLUME_TOP
	b.rect(Rect2(t + Vector2(-34.0, -34.0) + Shade.light * 60.0, Vector2(68.0, 68.0)), Color(SHADOW, 0.25))
	b.rect(Rect2(t + Vector2(-34.0, -34.0), Vector2(68.0, 68.0)), WOOD_DARK)
	b.rect(Rect2(t + Vector2(-28.0, -28.0), Vector2(56.0, 56.0)), WOOD)
	b.line(t + Vector2(-28.0, -28.0), t + Vector2(28.0, 28.0), WOOD_DARK, 3.0)
	b.line(t + Vector2(28.0, -28.0), t + Vector2(-28.0, 28.0), WOOD_DARK, 3.0)
	# the trough down the drop, water running in it, and on east out of sight
	var foot2 := FLUME_FOOT
	b.line(t + Shade.light * 40.0, foot2 + Shade.light * 6.0, Color(SHADOW, 0.3), 26.0)
	b.line(t, foot2, WOOD_DARK, 26.0)
	b.line(t, foot2, Color(0.60, 0.44, 0.28), 20.0)
	b.line(t, foot2, Color(WATER, 0.9), 12.0)
	b.line(t + Vector2(-3.0, 0.0), foot2 + Vector2(-3.0, 0.0), Color(1.0, 1.0, 1.0, 0.35), 2.0)
	var east := t + Vector2(400.0, -40.0)
	b.line(t + Shade.light * 30.0, east + Shade.light * 30.0, Color(SHADOW, 0.25), 24.0)
	b.line(t, east, WOOD_DARK, 24.0)
	b.line(t, east, Color(0.60, 0.44, 0.28), 18.0)
	b.line(t, east, Color(WATER, 0.9), 10.0)
	var sy := foot2.y - 30.0
	while sy > t.y + 30.0:
		b.line(Vector2(t.x - 14.0, sy), Vector2(t.x + 14.0, sy), WOOD_DARK, 3.0)
		sy -= 34.0


# --- Plaça del Loop ---------------------------------------------------------------
# Park paving with a coloured kerb, striped kiosks and arcade stalls along
# the west, the coaster's station on the east with its marquee.

static func _edge_loop(b: ShapeBatch, top: float, bot: float) -> void:
	var s := _span(top, bot, LOOP_Y1, LOOP_Y0)
	if s.y <= s.x:
		return
	_flags(b, -460.0, PATH_L, s.x, s.y, Color(0.84, 0.80, 0.74), 52.0)
	_flags(b, PATH_R, 1740.0, s.x, s.y, Color(0.84, 0.80, 0.74), 52.0)
	# the kerb inlay along the path: turquoise and magenta tiles
	var y := floorf(s.x / 16.0) * 16.0
	while y < s.y:
		var col := TURQ if int(absf(y) / 16.0) % 2 == 0 else MAGENTA
		b.rect(Rect2(PATH_L - 10.0, y, 10.0, 16.0), col)
		b.rect(Rect2(PATH_R, y, 10.0, 16.0), col)
		y += 16.0
	if STATION.end.y > s.x - 60.0 and STATION.position.y < s.y + 60.0:
		_station(b)
	for side: float in [-1.0, 1.0]:
		for pl: Array in _plots(s.x, s.y, 51.0 + side, 96.0, 140.0, 40.0):
			if side > 0.0 and pl[1] > STATION.position.y - 340.0 and pl[0] < STATION.end.y + 30.0:
				continue
			if _hk(pl[2], 1.0) < 0.38:
				var kc := Vector2(PATH_L - 70.0 if side < 0.0 else PATH_R + 70.0, (pl[0] + pl[1]) * 0.5)
				_kiosk(b, kc, pl[2])
			else:
				_arcade(b, side, pl[0], pl[1], pl[2])


static func _kiosk(b: ShapeBatch, c: Vector2, k: float) -> void:
	var r := 40.0
	_disc_shadow(b, c, r, 24.0)
	b.circle(c, r + 3.0, Color(0.94, 0.94, 0.92))
	var a: Color = _pick([MAGENTA, TURQ, Color(0.94, 0.46, 0.20), Color(0.36, 0.46, 0.86)], k, 2.0)
	_cone(b, c, r, a, Color(0.98, 0.96, 0.90), 16, k)
	# what it sells, on a board by the path: a cone, popcorn, a drink
	var bc := c + Vector2(0.0, r + 10.0)
	b.rect(Rect2(bc + Vector2(-14.0, -6.0), Vector2(28.0, 12.0)), INK)
	b.rect(Rect2(bc + Vector2(-12.0, -4.0), Vector2(24.0, 8.0)), SAFFRON)
	b.circle(bc, 3.0, a)


# an arcade stall: a striped tent roof over a counter on the path, prizes
# hung along its front
static func _arcade(b: ShapeBatch, side: float, y0: float, y1: float, k: float) -> void:
	var r := _arcade_rect(side, y0, y1, k)
	var a: Color = _pick([MAGENTA, TURQ, Color(0.94, 0.46, 0.20), Color(0.36, 0.46, 0.86), SAFFRON], k, 2.0)
	_cast(b, r, 22.0)
	b.rect(Rect2(r.position.x, r.end.y - 2.0, r.size.x, 12.0), a.darkened(0.35))
	# the tent: stripes running down both slopes from a ridge across x
	var c := r.get_center()
	var n := int(r.size.x / 14.0)
	for i in range(n):
		var x0 := r.position.x + float(i) * r.size.x / float(n)
		var w := r.size.x / float(n) + 0.5
		var col := a if i % 2 == 0 else Color(0.98, 0.96, 0.90)
		b.rect(Rect2(x0, r.position.y, w, c.y - r.position.y), col.lightened(0.08))
		b.rect(Rect2(x0, c.y, w, r.end.y - c.y), col.darkened(0.14))
	b.line(Vector2(r.position.x, c.y), Vector2(r.end.x, c.y), a.lightened(0.3), 3.0)
	# scallops along the front
	var fx := r.end.x if side < 0.0 else r.position.x
	var sy := r.position.y + 6.0
	var j := 0
	while sy < r.end.y - 4.0:
		b.circle(Vector2(fx, sy), 6.0, a if j % 2 == 0 else Color(0.98, 0.96, 0.90))
		sy += 12.0
		j += 1
	# the counter and the prizes: plush toys in a row
	var cx := fx + (6.0 if side < 0.0 else -16.0)
	b.rect(Rect2(cx, r.position.y + 8.0, 10.0, r.size.y - 16.0), WOOD)
	var py := r.position.y + 16.0
	while py < r.end.y - 12.0:
		var pc := Vector2(cx + 5.0, py)
		var toy: Color = _pick([Color(0.96, 0.62, 0.76), Color(0.60, 0.80, 0.96), SAFFRON, Color(0.70, 0.90, 0.60), Color(0.80, 0.60, 0.40)], py, 7.0)
		b.circle(pc, 5.0, toy)
		b.circle(pc + Vector2(-3.5, -3.5), 2.2, toy)
		b.circle(pc + Vector2(3.5, -3.5), 2.2, toy)
		py += 15.0


static func _station(b: ShapeBatch) -> void:
	var r := STATION
	_cast(b, r, 34.0)
	# the track in at the south end and out at the north, up the lift
	b.rect(Rect2(LIFT_TOP.x - 18.0, r.position.y - 20.0, 36.0, r.size.y + 60.0), Color(0.36, 0.36, 0.40))
	b.rect(Rect2(r.position.x, r.end.y - 2.0, r.size.x, 18.0), MAGENTA.darkened(0.35))
	# a sawtooth roof: north lights of glass, slopes of magenta steel
	var y := r.position.y
	var bay := 30.0
	while y < r.end.y - 1.0:
		var h := minf(bay, r.end.y - y)
		b.rect(Rect2(r.position.x, y, r.size.x, h * 0.35), GLASS.darkened(0.1))
		b.rect(Rect2(r.position.x, y + h * 0.35, r.size.x, h * 0.65), MAGENTA.darkened(0.05))
		b.line(Vector2(r.position.x, y + h * 0.35), Vector2(r.end.x, y + h * 0.35), MAGENTA.lightened(0.28), 2.0)
		b.line(Vector2(r.position.x, y + h - 1.0), Vector2(r.end.x, y + h - 1.0), MAGENTA.darkened(0.35), 2.0)
		y += bay
	# the canopy along the path, saffron, over the queue's exit
	var can := Rect2(r.position.x - 18.0, r.position.y + 20.0, 22.0, r.size.y - 40.0)
	b.rect(Rect2(can.position + Shade.light * 10.0, can.size), Color(SHADOW, 0.25))
	b.rect(can, SAFFRON)
	b.rect(Rect2(can.position.x, can.position.y, 5.0, can.size.y), SAFFRON.lightened(0.2))
	# the marquee on the roof's edge: a big board over the platform
	var sign := Rect2(r.position.x + 10.0, r.get_center().y - 70.0, 18.0, 140.0)
	b.rect(Rect2(sign.position + Vector2(5.0, 8.0), sign.size), Color(SHADOW, 0.35))
	b.rect(sign, INK)
	b.rect(sign.grow(-3.0), TURQ.darkened(0.2))
	var ly := sign.position.y + 10.0
	while ly < sign.end.y - 10.0:
		b.rect(Rect2(sign.position.x + 5.0, ly, 8.0, 10.0), SAFFRON)
		ly += 16.0


# --- the picnic lawn -------------------------------------------------------------
# Mown lawn either side, a clipped hedge along the path with shade trees
# behind, the park's back fence, a pergola over more tables.

const SHADE_TREES: Array[Vector2] = [
	Vector2(250.0, -4520.0), Vector2(1030.0, -4600.0), Vector2(290.0, -4800.0),
	Vector2(1050.0, -4880.0), Vector2(180.0, -4980.0),
]
const PERGOLA := Rect2(PATH_R + 40.0, -4800.0, 150.0, 180.0)


static func _edge_picnic(b: ShapeBatch, top: float, bot: float) -> void:
	var s := _span(top, bot, -5200.0, PICNIC_Y)
	if s.y <= s.x:
		return
	# mown stripes
	var y := floorf(s.x / 40.0) * 40.0
	while y < s.y:
		var col := GRASS if int(absf(y) / 40.0) % 2 == 0 else GRASS.lightened(0.05)
		b.rect(Rect2(-460.0, y, PATH_L + 460.0, 40.0), col)
		b.rect(Rect2(PATH_R, y, 1740.0 - PATH_R, 40.0), col)
		b.circle(Vector2(140.0 + _h(y) * 200.0, y + 14.0), 3.0, Color(0.96, 0.94, 0.70))
		b.circle(Vector2(980.0 + _h(y + 1.0) * 200.0, y + 24.0), 3.0, Color(0.96, 0.70, 0.80))
		y += 40.0
	# the park's back fence: railings on a low wall, out past the trees
	for side: float in [-1.0, 1.0]:
		var fx := PATH_L - 214.0 if side < 0.0 else PATH_R + 214.0
		var outer := Rect2(-460.0, s.x, fx - 8.0 + 460.0, s.y - s.x) if side < 0.0 else Rect2(fx + 8.0, s.x, 1740.0 - fx - 8.0, s.y - s.x)
		b.rect(outer, Color(0.24, 0.40, 0.24))
		var ty := floorf(s.x / 60.0) * 60.0
		while ty < s.y:
			var tc := Vector2(fx + side * (40.0 + _h(ty) * 60.0), ty + 30.0)
			b.circle(tc + Shade.light * 14.0, 30.0, Color(SHADOW, 0.3))
			b.circle(tc, 30.0, Color(0.16, 0.34, 0.22))
			b.circle(tc - Vector2(6.0, 6.0), 18.0, Color(0.24, 0.44, 0.26))
			ty += 60.0
		b.rect(Rect2(fx - 6.0, s.x, 12.0, s.y - s.x), Color(0.74, 0.70, 0.64))
		b.rect(Rect2(fx - 6.0, s.x, 3.0, s.y - s.x), Color(0.86, 0.84, 0.78))
		var py := floorf(s.x / 10.0) * 10.0
		while py < s.y:
			b.rect(Rect2(fx - 2.0, py, 4.0, 4.0), Color(0.16, 0.18, 0.20))
			py += 10.0
	# the hedge along the path, gaps where the lawn runs out to the tables
	for side: float in [-1.0, 1.0]:
		var hx := PATH_L - 38.0 if side < 0.0 else PATH_R + 14.0
		var hy := floorf(s.x / 120.0) * 120.0
		while hy < s.y:
			var hr := Rect2(hx, hy + 14.0, 24.0, 92.0)
			b.rect(Rect2(hr.position + Shade.light * 8.0, hr.size), Color(SHADOW, 0.28))
			b.rect(hr, HEDGE)
			b.rect(Rect2(hr.position, Vector2(hr.size.x, 5.0)), HEDGE_LIT)
			b.rect(Rect2(hr.position, Vector2(6.0, hr.size.y)), HEDGE_LIT)
			var dy := hr.position.y + 8.0
			while dy < hr.end.y - 4.0:
				b.circle(Vector2(hr.get_center().x + (_h(dy) - 0.5) * 10.0, dy), 4.0, HEDGE_LIT.lightened(0.05))
				dy += 13.0
			hy += 120.0
	# trunks of the shade trees (their crowns hang overhead)
	for t: Vector2 in SHADE_TREES:
		if t.y > s.x - 60.0 and t.y < s.y + 60.0:
			b.circle(t + Shade.light * 70.0, 54.0, Color(SHADOW, 0.20))
			b.circle(t, 10.0, Color(0.40, 0.30, 0.20))
	# the pergola: posts, timber slats, a vine over it, tables in its shade
	var pg := PERGOLA
	if pg.end.y > s.x and pg.position.y < s.y:
		b.rect(Rect2(pg.position + Shade.light * 20.0, pg.size), Color(SHADOW, 0.18))
		for i in range(2):
			var tr := Rect2(pg.position.x + 30.0, pg.position.y + 30.0 + float(i) * 80.0, 90.0, 40.0)
			b.rect(Rect2(tr.position.x - 4.0, tr.position.y - 12.0, tr.size.x + 8.0, 8.0), WOOD_DARK)
			b.rect(Rect2(tr.position.x - 4.0, tr.end.y + 4.0, tr.size.x + 8.0, 8.0), WOOD_DARK)
			b.rect(tr, WOOD)
			b.rect(tr.grow(-4.0), Color(0.92, 0.90, 0.84) if i == 0 else Color(0.30, 0.50, 0.80))
		var sx := pg.position.x
		while sx <= pg.end.x:
			b.line(Vector2(sx, pg.position.y), Vector2(sx, pg.end.y), WOOD_DARK, 4.0)
			b.line(Vector2(sx - 1.0, pg.position.y), Vector2(sx - 1.0, pg.end.y), WOOD_LIT, 1.5)
			sx += 25.0
		for corner: Vector2 in [pg.position, Vector2(pg.end.x, pg.position.y), pg.end, Vector2(pg.position.x, pg.end.y)]:
			b.rect(Rect2(corner - Vector2(5.0, 5.0), Vector2(10.0, 10.0)), WOOD_DARK)
		for i in range(14):
			var vp := pg.position + Vector2(_h(float(i)) * pg.size.x, _h(float(i) + 7.0) * pg.size.y)
			b.circle(vp, 9.0 + _h(float(i) + 2.0) * 6.0, Color(LEAF_LIT, 0.85))
			if i % 3 == 0:
				b.circle(vp + Vector2(2.0, 1.0), 3.0, Color(0.56, 0.30, 0.56))


# --- the path's own ground and what stands on it (cached) -----------------------

static func draw_cross_section(m: Node2D, wc: ShapeBatch, _top: float, _bottom: float, ctop: float, vt: float, vb: float) -> void:
	var lo: float = maxf(vt - 60.0, ctop)
	var hi: float = minf(vb + 60.0, float(m.START_Y) + 560.0)
	if hi <= lo:
		return
	var was := wc.lod
	wc.lod = true
	_draw_path(wc, lo, hi)
	_seams(wc, lo, hi, PATH_L, PATH_R, true)
	_draw_track_shadows(wc, lo, hi)
	_draw_gates(wc, lo, hi)
	_draw_canyon(wc, lo, hi)
	_draw_picnic(wc, lo, hi)
	_draw_queues(wc, lo, hi)
	_draw_carts(wc, lo, hi)
	_draw_crowd(wc, lo, hi)
	wc.lod = was


# the park's own paving: warm concrete flags, a coloured flag here and there
static func _park_paving(wc: ShapeBatch, a: float, z: float, base: Color) -> void:
	wc.rect(Rect2(PATH_L, a, PATH_R - PATH_L, z - a), base)
	var size := 45.0
	var y := floorf(a / size) * size
	while y < z:
		var row := int(absf(y) / size)
		var x := PATH_L
		var col := 0
		while x < PATH_R:
			var hk := _hk(float(row * 13 + col), 2.0)
			if hk > 0.86:
				var tint: Color = [SAFFRON, TURQ, MAGENTA][int(hk * 97.0) % 3]
				wc.rect(Rect2(x + 1.0, maxf(y, a) + 1.0, size - 2.0, minf(y + size, z) - maxf(y, a) - 2.0), base.lerp(tint, 0.28))
			elif hk < 0.2:
				wc.rect(Rect2(x + 1.0, maxf(y, a) + 1.0, size - 2.0, minf(y + size, z) - maxf(y, a) - 2.0), base.lightened(0.04))
			x += size
			col += 1
		wc.line(Vector2(PATH_L, y), Vector2(PATH_R, y), base.darkened(0.12), 1.4)
		y += size
	var x2 := PATH_L + size
	while x2 < PATH_R:
		wc.line(Vector2(x2, a), Vector2(x2, z), base.darkened(0.12), 1.4)
		x2 += size


static func _draw_path(wc: ShapeBatch, lo: float, hi: float) -> void:
	# the gates' plaza and Plaça del Loop: the park's paving
	for band in [[820.0, CORSARI_Y0], [LOOP_Y0, LOOP_Y1]]:
		var a: float = maxf(lo, float(band[1]))
		var z: float = minf(hi, float(band[0]))
		if z > a:
			_park_paving(wc, a, z, PAVEMENT)
	# the Loop's painted track: a ribbon of the coaster's colours down the plaza
	var l0 := maxf(lo, LOOP_Y1)
	var l1 := minf(hi, LOOP_Y0)
	if l1 > l0:
		var yy := floorf(l0 / 20.0) * 20.0
		while yy < l1:
			var x0 := CX - 150.0 + sin(yy * 0.006) * 90.0
			var x1 := CX - 150.0 + sin((yy + 20.0) * 0.006) * 90.0
			wc.quad(Vector2(x0 - 9.0, yy), Vector2(x0 + 9.0, yy), Vector2(x1 + 9.0, yy + 20.0), Vector2(x1 - 9.0, yy + 20.0), Color(MAGENTA, 0.30))
			wc.line(Vector2(x0 - 9.0, yy), Vector2(x1 - 9.0, yy + 20.0), Color(MAGENTA.darkened(0.2), 0.45), 1.5)
			wc.line(Vector2(x0 + 9.0, yy), Vector2(x1 + 9.0, yy + 20.0), Color(MAGENTA.darkened(0.2), 0.45), 1.5)
			yy += 20.0
	# Corsari: whitewashed setts
	var c0 := maxf(lo, CORSARI_Y1)
	var c1 := minf(hi, CORSARI_Y0)
	if c1 > c0:
		wc.rect(Rect2(PATH_L, c0, PATH_R - PATH_L, c1 - c0), SETT)
		var sy := floorf(c0 / 18.0) * 18.0
		while sy < c1:
			wc.rect(Rect2(PATH_L, sy, PATH_R - PATH_L, 1.2), SETT_DARK)
			var sx := PATH_L + fmod(absf(sy) / 18.0, 2.0) * 9.0
			while sx < PATH_R:
				wc.rect(Rect2(sx, sy, 1.0, 18.0), SETT_DARK)
				sx += 18.0
			sy += 18.0
		# a gutter of blue tiles down each side, as the village's lanes have
		wc.rect(Rect2(PATH_L, c0, 8.0, c1 - c0), Color(0.56, 0.66, 0.78))
		wc.rect(Rect2(PATH_R - 8.0, c0, 8.0, c1 - c0), Color(0.56, 0.66, 0.78))
	# Canyon: timber boardwalk + dust shoulders
	var bw0 := maxf(lo, CANYON_Y1)
	var bw1 := minf(hi, CANYON_Y0)
	if bw1 > bw0:
		wc.rect(Rect2(PATH_L, bw0, PATH_R - PATH_L, bw1 - bw0), WOOD_LIT)
		var y := floorf(bw0 / 14.0) * 14.0
		while y < bw1:
			wc.rect(Rect2(PATH_L, y, PATH_R - PATH_L, 1.6), WOOD_DARK)
			# board ends staggered, nail heads
			var bx := PATH_L + 60.0 + _h(y) * 120.0
			wc.rect(Rect2(bx, y, 1.4, 14.0), WOOD_DARK)
			wc.rect(Rect2(bx + 180.0 + _h(y + 1.0) * 80.0, y, 1.4, 14.0), WOOD_DARK)
			if int(absf(y) / 14.0) % 3 == 0:
				wc.rect(Rect2(PATH_L + 30.0 + _h(y + 2.0) * 400.0, y + 4.0, 70.0, 8.0), WOOD_LIT.lightened(0.06))
			wc.rect(Rect2(PATH_L, y + 1.0, 10.0, 12.0), DUST)
			wc.rect(Rect2(PATH_R - 10.0, y + 1.0, 10.0, 12.0), DUST)
			y += 14.0
	# Selva: packed earth with roots (handles as mud)
	var s0 := maxf(lo, SELVA_Y1)
	var s1 := minf(hi, SELVA_Y0)
	if s1 > s0:
		wc.rect(Rect2(PATH_L, s0, PATH_R - PATH_L, s1 - s0), EARTH)
		var sy2 := floorf(s0 / 28.0) * 28.0
		while sy2 < s1:
			wc.coarse(Vector2(CX + (_h(sy2) - 0.5) * 160.0, sy2 + 10.0), 10.0, EARTH_LIT)
			wc.capsule(
				Vector2(PATH_L + 20.0 + _h(sy2) * 40.0, sy2),
				Vector2(PATH_L + 80.0 + _h(sy2 + 1.0) * 60.0, sy2 + 16.0),
				2.5, EARTH.darkened(0.15))
			wc.capsule(
				Vector2(PATH_R - 20.0 - _h(sy2 + 2.0) * 40.0, sy2 + 4.0),
				Vector2(PATH_R - 90.0 - _h(sy2 + 3.0) * 50.0, sy2 + 18.0),
				2.5, EARTH.darkened(0.15))
			# fallen leaves
			wc.quad(Vector2(CX - 200.0 + _h(sy2 + 5.0) * 400.0, sy2 + 6.0), Vector2(CX - 194.0 + _h(sy2 + 5.0) * 400.0, sy2 + 2.0),
				Vector2(CX - 188.0 + _h(sy2 + 5.0) * 400.0, sy2 + 8.0), Vector2(CX - 194.0 + _h(sy2 + 5.0) * 400.0, sy2 + 12.0), Color(LEAF, 0.6))
			sy2 += 28.0
	# the flume's boardwalk through the splash band (not water): planks over
	# the mud, edge beams, mud spattered over its ends
	var f0 := maxf(lo, FLUME_Y0)
	var f1 := minf(hi, FLUME_Y1)
	if f1 > f0:
		wc.rect(Rect2(PATH_L, f0, PATH_R - PATH_L, f1 - f0), WOOD_LIT)
		var fy := floorf(f0 / 12.0) * 12.0
		while fy < f1:
			wc.rect(Rect2(PATH_L, fy, PATH_R - PATH_L, 1.4), WOOD_DARK)
			wc.rect(Rect2(PATH_L + _h(fy) * 300.0, fy + 3.0, 90.0, 6.0), WOOD_LIT.lightened(0.05))
			fy += 12.0
		wc.rect(Rect2(PATH_L, f0, 12.0, f1 - f0), WOOD_DARK)
		wc.rect(Rect2(PATH_R - 12.0, f0, 12.0, f1 - f0), WOOD_DARK)
		# the boards dark and wet on the pool's side
		var wet := PackedVector2Array([Vector2(FLUME_WASH_X, f0), Vector2(PATH_R, f0), Vector2(FLUME_WASH_X, f1), Vector2(PATH_R, f1)])
		wc.band(wet, 2, Color(0.20, 0.14, 0.10), PackedFloat32Array([0.22, 0.22]), PackedFloat32Array([0.0, 1.0]))
		for e: float in [FLUME_Y0, FLUME_Y1]:
			if e > lo - 20.0 and e < hi + 20.0:
				var d := 1.0 if e == FLUME_Y1 else -1.0
				wc.band(PackedVector2Array([Vector2(PATH_L, e - d * 10.0), Vector2(PATH_R, e - d * 10.0), Vector2(PATH_L, e + d * 6.0), Vector2(PATH_R, e + d * 6.0)]),
					2, EARTH, PackedFloat32Array([0.0, 1.0]))
	# the picnic lawn, mown in stripes
	var g0 := maxf(lo, m_gate())
	var g1 := minf(hi, PICNIC_Y)
	if g1 > g0:
		var gy := floorf(g0 / 40.0) * 40.0
		while gy < g1:
			var col := GRASS if int(absf(gy) / 40.0) % 2 == 0 else GRASS.lightened(0.05)
			wc.rect(Rect2(PATH_L, maxf(gy, g0), PATH_R - PATH_L, minf(gy + 40.0, g1) - maxf(gy, g0)), col)
			wc.coarse(Vector2(CX + (_h(gy * 0.1) - 0.5) * 360.0, gy + 10.0), 3.0, Color(0.96, 0.94, 0.70))
			gy += 40.0
		# the paved path ends in a soft edge on the grass
		if PICNIC_Y > lo and PICNIC_Y < hi + 30.0:
			wc.band(PackedVector2Array([Vector2(PATH_L, PICNIC_Y - 18.0), Vector2(PATH_R, PICNIC_Y - 18.0), Vector2(PATH_L, PICNIC_Y), Vector2(PATH_R, PICNIC_Y)]),
				2, PAVEMENT, PackedFloat32Array([0.0, 1.0]))


static func m_gate() -> float:
	return -5000.0


# the ground under the overhead tracks: their shadows, thrown by their height
static func _draw_track_shadows(wc: ShapeBatch, lo: float, hi: float) -> void:
	var d := Shade.light * 46.0
	for i in range(MINE_PATH.size() - 1):
		if i == MINE_GAP:
			continue
		var a: Vector2 = MINE_PATH[i] + d
		var z: Vector2 = MINE_PATH[i + 1] + d
		if maxf(a.y, z.y) < lo - 30.0 or minf(a.y, z.y) > hi + 30.0:
			continue
		wc.line(a, z, Color(SHADOW, 0.20), 22.0)
	var path := _coaster_path()
	var d2 := Shade.light * 64.0
	for i in range(path.size() - 1):
		var a: Vector2 = path[i] + d2
		var z: Vector2 = path[i + 1] + d2
		if maxf(a.y, z.y) < lo - 30.0 or minf(a.y, z.y) > hi + 30.0:
			continue
		wc.line(a, z, Color(SHADOW, 0.18), 18.0)
	# the arch's lintel throws a band of shade across the path
	d = Shade.light * 52.0
	var ly := ARCH.y - 46.0 + d.y
	if ly + 80.0 > lo and ly - 10.0 < hi:
		wc.band(PackedVector2Array([
			Vector2(PATH_L + d.x, ly - 8.0), Vector2(PATH_R + d.x, ly - 8.0),
			Vector2(PATH_L + d.x, ly + 4.0), Vector2(PATH_R + d.x, ly + 4.0),
			Vector2(PATH_L + d.x, ly + 60.0), Vector2(PATH_R + d.x, ly + 60.0),
			Vector2(PATH_L + d.x, ly + 72.0), Vector2(PATH_R + d.x, ly + 72.0),
		]), 2, SHADOW, PackedFloat32Array([0.0, 0.9, 0.9, 0.0]))


static func _draw_gates(wc: ShapeBatch, lo: float, hi: float) -> void:
	if hi < -400.0 or lo > 140.0:
		return
	# the turnstiles: steel cabinets, their three arms, a light on each
	for t: Vector2 in TURNSTILES:
		if t.y < lo - 40.0 or t.y > hi + 40.0:
			continue
		for d: float in [-1.0, 1.0]:
			var cab := Rect2(t.x + d * 22.0 - 7.0, t.y - 16.0, 14.0, 32.0)
			wc.rect(Rect2(cab.position + Shade.light * 8.0, cab.size), Color(SHADOW, 0.3))
			wc.rect(cab, STEEL_DARK)
			wc.rect(cab.grow(-2.0), STEEL)
			wc.circle(cab.get_center() + Vector2(0.0, -10.0), 2.5, Color(0.30, 0.90, 0.50))
		for j in range(3):
			var a := float(j) * TAU / 3.0 + 0.4
			wc.line(t + Vector2(-15.0, 0.0), t + Vector2(-15.0, 0.0) + Vector2.from_angle(a) * 14.0, Color(0.80, 0.82, 0.86), 2.5)
	# the ticket booth: a little building under a hipped roof, its window on
	# the path with a striped awning
	if BOOTH.end.y > lo and BOOTH.position.y < hi:
		_cast(wc, BOOTH, 22.0)
		wc.rect(Rect2(BOOTH.position.x, BOOTH.end.y - 2.0, BOOTH.size.x, 14.0), MAGENTA.darkened(0.30))
		wc.rect(Rect2(BOOTH.position.x + 30.0, BOOTH.end.y + 1.0, 30.0, 10.0), GLASS)
		wc.rect(BOOTH, MAGENTA.darkened(0.1))
		_hip(wc, BOOTH.grow(-3.0), TURQ)
		var aw := Rect2(BOOTH.end.x, BOOTH.position.y + 10.0, 16.0, BOOTH.size.y - 20.0)
		for i in range(4):
			wc.rect(Rect2(aw.position.x, aw.position.y + float(i) * aw.size.y / 4.0, aw.size.x, aw.size.y / 4.0 + 0.5), SAFFRON if i % 2 == 0 else Color(0.98, 0.96, 0.90))
		wc.circle(BOOTH.get_center(), 5.0, SAFFRON)
	# the fountain: a stepped basin, its water soft at the rim, the jet
	if FOUNTAIN.y > lo - 60.0 and FOUNTAIN.y < hi + 60.0:
		_disc_shadow(wc, FOUNTAIN, 48.0, 10.0)
		wc.circle(FOUNTAIN, 48.0, Color(0.86, 0.80, 0.70))
		wc.circle(FOUNTAIN, 44.0, Color(0.74, 0.68, 0.60))
		wc.circle(FOUNTAIN, 40.0, WATER_DEEP)
		wc.glow(FOUNTAIN + Vector2(-4.0, -4.0), 38.0, Color(WATER, 0.95), 0.3)
		for i in range(8):
			var a := float(i) * TAU / 8.0
			wc.circle(FOUNTAIN + Vector2.from_angle(a) * 46.0, 4.0, TURQ if i % 2 == 0 else MAGENTA)
		wc.circle(FOUNTAIN, 12.0, Color(0.86, 0.80, 0.70))
		wc.circle(FOUNTAIN, 8.0, Color(0.92, 0.88, 0.80))
		wc.glow(FOUNTAIN, 26.0, Color(1.0, 1.0, 1.0, 0.45), 0.2)
	# the towers' shade either side of the arch, on the paving's edge
	if ARCH.y > lo - 120.0 and ARCH.y < hi + 120.0:
		for side: float in [-1.0, 1.0]:
			var tr := _tower_rect(side)
			var sh := Rect2(tr.position + Shade.light * 46.0, tr.size)
			var clip_l := maxf(sh.position.x, PATH_L)
			var clip_r := minf(sh.end.x, PATH_R)
			if clip_r > clip_l:
				wc.rect(Rect2(clip_l, sh.position.y, clip_r - clip_l, sh.size.y), Color(SHADOW, 0.24))


static func _draw_canyon(wc: ShapeBatch, lo: float, hi: float) -> void:
	for i in range(5):
		var p := Vector2(PATH_L + 36.0 + float(i % 2) * (PATH_R - PATH_L - 72.0), -1580.0 - float(i) * 140.0)
		if p.y < lo - 30.0 or p.y > hi + 30.0:
			continue
		_disc_shadow(wc, p, 12.0, 8.0)
		wc.circle(p, 12.0, WOOD_DARK)
		wc.circle(p, 9.0, WOOD)
		wc.line(p + Vector2(-9.0, -3.0), p + Vector2(9.0, -3.0), STEEL_DARK, 1.2)
		wc.line(p + Vector2(-9.0, 3.0), p + Vector2(9.0, 3.0), STEEL_DARK, 1.2)
		wc.circle(p - Vector2(2.0, 2.0), 3.0, WOOD_LIT)
	# the assay shack on the boardwalk: tin roof, its false front to the west
	if SALOON.end.y > lo and SALOON.position.y < hi:
		var r := SALOON
		_cast(wc, r, 20.0)
		wc.rect(Rect2(r.position.x, r.end.y - 2.0, r.size.x, 12.0), WOOD_DARK)
		_roof(wc, r, TIN, false, 4.0)
		var front := Rect2(r.position.x - 10.0, r.position.y - 6.0, 12.0, r.size.y + 12.0)
		wc.rect(Rect2(front.end.x, front.position.y + 4.0, 12.0, front.size.y - 4.0), Color(SHADOW, 0.3))
		wc.rect(front, Color(0.56, 0.22, 0.18).darkened(0.2))
		wc.rect(front.grow(-2.0), Color(0.56, 0.22, 0.18))
		wc.rect(Rect2(front.position.x + 2.0, front.get_center().y - 18.0, 8.0, 36.0), Color(0.94, 0.88, 0.70))


static func _draw_picnic(wc: ShapeBatch, lo: float, hi: float) -> void:
	# tables with their benches, cloths and lunch
	for ti in range(PICNIC_TABLES.size()):
		var t: Rect2 = PICNIC_TABLES[ti]
		if t.end.y < lo - 20.0 or t.position.y > hi + 20.0:
			continue
		_cast(wc, Rect2(t.position.x - 6.0, t.position.y - 14.0, t.size.x + 12.0, t.size.y + 28.0), 10.0)
		for by: float in [t.position.y - 14.0, t.end.y + 2.0]:
			wc.rect(Rect2(t.position.x - 6.0, by, t.size.x + 12.0, 12.0), WOOD_DARK)
			wc.rect(Rect2(t.position.x - 6.0, by, t.size.x + 12.0, 4.0), WOOD_LIT)
		wc.rect(t, WOOD_DARK)
		wc.rect(t.grow(-3.0), WOOD)
		var cloth := Color(0.92, 0.90, 0.84) if ti % 2 == 0 else Color(0.86, 0.28, 0.32)
		var cr := Rect2(t.position.x + 4.0, t.position.y + 2.0, t.size.x - 8.0, t.size.y - 4.0)
		wc.rect(cr, cloth)
		# gingham checks on the red cloths
		if ti % 2 == 1:
			var cx := cr.position.x + 6.0
			while cx < cr.end.x:
				wc.rect(Rect2(cx, cr.position.y, 6.0, cr.size.y), Color(1.0, 1.0, 1.0, 0.22))
				cx += 12.0
		wc.circle(t.get_center() + Vector2(-22.0, 0.0), 6.0, Color(0.96, 0.96, 0.94))
		wc.circle(t.get_center() + Vector2(-22.0, 0.0), 3.5, Color(0.86, 0.56, 0.30))
		wc.circle(t.get_center() + Vector2(22.0, 0.0), 6.0, Color(0.96, 0.96, 0.94))
		wc.circle(t.get_center() + Vector2(22.0, 0.0), 3.5, Color(0.50, 0.70, 0.30))
		wc.rect(Rect2(t.get_center() + Vector2(-6.0, -8.0), Vector2(12.0, 16.0)), Color(0.80, 0.62, 0.40))
	# the grill (its fire and smoke are live)
	if PRIZE.y > lo - 60.0 and PRIZE.y < hi + 60.0:
		var g := PRIZE + Vector2(0.0, -40.0)
		var gr := Rect2(g.x - 40.0, g.y - 16.0, 80.0, 32.0)
		_cast(wc, gr, 12.0)
		wc.rect(gr, Color(0.16, 0.16, 0.18))
		wc.rect(gr.grow(-4.0), Color(0.26, 0.24, 0.24))
		var gx := gr.position.x + 8.0
		while gx < gr.end.x - 4.0:
			wc.line(Vector2(gx, gr.position.y + 4.0), Vector2(gx, gr.end.y - 4.0), STEEL_DARK, 1.5)
			gx += 6.0
		for i in range(3):
			wc.capsule(g + Vector2(-22.0 + float(i) * 22.0, 0.0) + Vector2(-8.0, 0.0),
				g + Vector2(-22.0 + float(i) * 22.0, 0.0) + Vector2(8.0, 0.0), 3.4, Color(0.80, 0.52, 0.22))
	# families on blankets, a parasol over one, a cool box
	if Outdoors.theme_park(Game.weather, Game.hour) or Outdoors.picnics(Game.weather, Game.hour):
		var blankets: Array[Vector2] = [
			Vector2(460.0, -4640.0), Vector2(830.0, -4760.0), Vector2(560.0, -4900.0), Vector2(840.0, -4470.0),
		]
		for i in range(blankets.size()):
			var bp: Vector2 = blankets[i]
			if bp.y < lo - 40.0 or bp.y > hi + 40.0:
				continue
			var col: Color = [Color(0.86, 0.28, 0.32), Color(0.20, 0.45, 0.70), SAFFRON, TURQ][i]
			var br := Rect2(bp.x - 32.0, bp.y - 22.0, 64.0, 44.0)
			wc.rect(Rect2(br.position + Vector2(2.0, 3.0), br.size), Color(SHADOW, 0.2))
			wc.rect(br, col)
			var sx := br.position.x + 8.0
			while sx < br.end.x:
				wc.rect(Rect2(sx, br.position.y, 4.0, br.size.y), col.lightened(0.25))
				sx += 16.0
			_person(wc, bp + Vector2(-14.0, -2.0), float(i) * 7.0 + 1.0, 1.0, Vector2.RIGHT, "sunhat" if i % 2 == 0 else "")
			_person(wc, bp + Vector2(14.0, 6.0), float(i) * 7.0 + 2.0, 0.7, Vector2.LEFT)
			wc.rect(Rect2(bp + Vector2(6.0, -16.0), Vector2(14.0, 10.0)), Color(0.94, 0.94, 0.96))
			wc.rect(Rect2(bp + Vector2(6.0, -16.0), Vector2(14.0, 3.0)), Color(0.30, 0.52, 0.80))
			if i == 1:
				_disc_shadow(wc, bp + Vector2(-20.0, -26.0), 30.0, 26.0)
				_cone(wc, bp + Vector2(-20.0, -26.0), 30.0, Color(0.96, 0.96, 0.92), SAFFRON, 10)
	# bins at the lawn's edge
	for bi in range(3):
		var bpos := Vector2(380.0 + float(bi) * 260.0, -4470.0 - float(bi) * 30.0)
		if bpos.y < lo - 20.0 or bpos.y > hi + 20.0:
			continue
		_disc_shadow(wc, bpos, 9.0, 8.0)
		wc.circle(bpos, 9.0, Color(0.18, 0.42, 0.28))
		wc.circle(bpos, 6.0, Color(0.12, 0.30, 0.20))
		wc.circle(bpos - Vector2(2.0, 2.0), 2.0, Color(0.30, 0.56, 0.38))


# the queue mazes: chrome stanchions, belts between them in each ride's
# colour, and the visitors standing in the lanes, each a different person
static func _draw_queues(wc: ShapeBatch, lo: float, hi: float) -> void:
	for mi in range(MAZES.size()):
		var mz: Array = MAZES[mi]
		var rope: Color = ROPE_COLS[mi]
		for run: Array in mz[0]:
			for j in range(run.size() - 1):
				var a: Vector2 = QUEUE_POSTS[int(run[j])]
				var z: Vector2 = QUEUE_POSTS[int(run[j + 1])]
				if maxf(a.y, z.y) < lo - 40.0 or minf(a.y, z.y) > hi + 40.0:
					continue
				var mid := a.lerp(z, 0.5) + Vector2(3.0, 0.0)
				wc.line(a + Shade.light * 5.0, z + Shade.light * 5.0, Color(SHADOW, 0.22), 3.0)
				wc.line(a, mid, rope.darkened(0.25), 3.6)
				wc.line(mid, z, rope.darkened(0.25), 3.6)
				wc.line(a, mid, rope, 2.0)
				wc.line(mid, z, rope, 2.0)
		if not Outdoors.theme_park(Game.weather, Game.hour):
			continue
		var lanes: Array = mz[1]
		var total: int = mz[2]
		var hat: String = mz[3]
		var placed := 0
		for li in range(lanes.size()):
			var tail: Vector2 = lanes[li][0]
			var head: Vector2 = lanes[li][1]
			var len := tail.distance_to(head)
			var dir := (head - tail).normalized()
			var t := 8.0 + _hk(float(mi * 10 + li), 1.0) * 14.0
			while t < len - 6.0 and placed < total:
				var k := float(mi * 100 + placed) + 0.5
				var p := tail + dir * t + dir.orthogonal() * (_hk(k, 8.0) - 0.5) * 8.0
				if p.y > lo - 20.0 and p.y < hi + 20.0:
					var kid := _hk(k, 9.0) < 0.25
					var wear := hat if _hk(k, 10.0) < 0.55 else ("cap" if _hk(k, 11.0) < 0.3 else "")
					_person(wc, p, k, 0.72 if kid else 1.0, dir, wear)
				placed += 1
				t += 18.0 + _hk(k, 12.0) * 12.0


static func _draw_carts(wc: ShapeBatch, lo: float, hi: float) -> void:
	if CHURRO.y > lo - 60.0 and CHURRO.y < hi + 60.0:
		var cr := Rect2(CHURRO.x - 28.0, CHURRO.y - 18.0, 56.0, 36.0)
		_cast(wc, cr, 12.0)
		wc.rect(cr, Color(0.86, 0.28, 0.22))
		wc.rect(cr.grow(-3.0), Color(0.94, 0.36, 0.26))
		wc.rect(Rect2(cr.position.x + 6.0, cr.position.y + 6.0, 24.0, 10.0), Color(0.96, 0.90, 0.76))
		for i in range(4):
			wc.capsule(Vector2(cr.position.x + 9.0, cr.position.y + 8.0 + float(i) * 2.0), Vector2(cr.position.x + 27.0, cr.position.y + 8.0 + float(i) * 2.0), 1.2, Color(0.80, 0.52, 0.22))
		for d: float in [-1.0, 1.0]:
			wc.circle(Vector2(CHURRO.x + d * 22.0, cr.end.y + 2.0), 5.0, INK)
		# the striped umbrella over the cart, on its pole
		_disc_shadow(wc, CHURRO + Vector2(10.0, -6.0), 30.0, 24.0)
		_cone(wc, CHURRO + Vector2(10.0, -6.0), 30.0, SAFFRON, Color(0.86, 0.28, 0.22), 10, 0.3)
	if ICECREAM.y > lo - 60.0 and ICECREAM.y < hi + 60.0 and Outdoors.icecream_open(Game.weather, Game.hour):
		var ir := Rect2(ICECREAM.x - 24.0, ICECREAM.y - 16.0, 48.0, 32.0)
		_cast(wc, ir, 12.0)
		wc.rect(ir, Color(0.95, 0.95, 0.98))
		for i in range(3):
			wc.circle(Vector2(ir.position.x + 10.0 + float(i) * 14.0, ir.get_center().y), 5.0, [Color(1.0, 0.70, 0.80), Color(0.98, 0.94, 0.80), Color(0.56, 0.36, 0.24)][i])
		_disc_shadow(wc, ICECREAM + Vector2(-8.0, -6.0), 26.0, 22.0)
		_cone(wc, ICECREAM + Vector2(-8.0, -6.0), 26.0, TURQ, Color(0.98, 0.96, 0.90), 10, 0.1)


static func _draw_crowd(wc: ShapeBatch, lo: float, hi: float) -> void:
	if not Outdoors.theme_park(Game.weather, Game.hour):
		return
	# families out for the day: a grown-up or two and their kids, strolling
	var spots: Array[Vector2] = [
		Vector2(600.0, -880.0), Vector2(700.0, -1320.0), Vector2(580.0, -1980.0),
		Vector2(690.0, -2780.0), Vector2(610.0, -3380.0), Vector2(720.0, -3880.0),
		Vector2(560.0, -160.0), Vector2(780.0, -560.0), Vector2(520.0, -2350.0),
	]
	for i in range(spots.size()):
		var p: Vector2 = spots[i]
		if p.y < lo - 40.0 or p.y > hi + 40.0:
			continue
		var face := Vector2.UP if i % 3 != 1 else Vector2.DOWN
		var hat := ""
		if p.y < CANYON_Y0 and p.y > CANYON_Y1:
			hat = "cowboy"
		elif p.y < LOOP_Y0 and p.y > LOOP_Y1:
			hat = "ears"
		_person(wc, p, float(i) * 11.0, 1.0, face, hat if i % 2 == 0 else "")
		if i % 2 == 0:
			_person(wc, p + Vector2(-18.0, 4.0), float(i) * 11.0 + 3.0, 1.0, face)
		_person(wc, p + Vector2(16.0, 8.0), float(i) * 11.0 + 5.0, 0.7, face, hat)


# --- every frame: rides, the flume, smoke, balloons, bulbs -------------------------

static func draw_live(m: Node2D, wc: ShapeBatch, vt: float, vb: float) -> void:
	if m.lvl != "atraccions":
		return
	var was := wc.lod
	wc.lod = true
	var t_ms := float(AnimClock.msec())
	if SHIP.y > vt - 200.0 and SHIP.y < vb + 200.0:
		_pirate_ship(wc, t_ms)
	if CAROUSEL.y > vt - 100.0 and CAROUSEL.y < vb + 100.0:
		_carousel(wc, t_ms)
	if PRIZE.y > vt - 120.0 and PRIZE.y < vb + 120.0:
		_grill_fire(wc, t_ms)
	_balloons(wc, vt, vb, t_ms)
	_torches(wc, vt, vb, t_ms)
	_flume_live(m, wc, vt, vb)
	var glow := Game.lamp_glow()
	if glow > 0.02:
		_bulbs_lit(m, wc, vt, vb, glow, t_ms)
	wc.lod = was


static func _pirate_ship(wc: ShapeBatch, t_ms: float) -> void:
	# the swing: north and south over the basin, highest at either end, so
	# its shadow falls further off and it looks a touch bigger up there
	var th := sin(t_ms * 0.0011) * 1.05
	var c := SHIP + Vector2(0.0, sin(th) * SHIP_SWING)
	var lift := (1.0 - cos(th)) * SHIP_SWING
	var sc := 1.0 + lift * 0.0016
	var hull := PackedVector2Array([
		Vector2(0.0, -64.0), Vector2(16.0, -44.0), Vector2(23.0, -12.0), Vector2(22.0, 30.0),
		Vector2(15.0, 56.0), Vector2(-15.0, 56.0), Vector2(-22.0, 30.0), Vector2(-23.0, -12.0), Vector2(-16.0, -44.0),
	])
	var sh := PackedVector2Array()
	var hp := PackedVector2Array()
	var deck := PackedVector2Array()
	for p: Vector2 in hull:
		sh.append(c + p * sc + Shade.light * (16.0 + lift * 0.45))
		hp.append(c + p * sc)
		deck.append(c + p * sc * 0.80 + Vector2(0.0, 2.0))
	wc.polygon(sh, Color(0.02, 0.10, 0.18, 0.32))
	wc.polygon(hp, Color(0.30, 0.18, 0.12))
	wc.polygon(deck, WOOD)
	# the gunwale's paint and the deck's planks
	wc.line(hp[2], hp[3], Color(0.86, 0.70, 0.20), 3.0)
	wc.line(hp[7], hp[6], Color(0.86, 0.70, 0.20), 3.0)
	for i in range(-2, 3):
		var px := c.x + float(i) * 6.0 * sc
		wc.line(Vector2(px, c.y - 40.0 * sc), Vector2(px, c.y + 46.0 * sc), WOOD_DARK, 1.0)
	# riders in rows, arms up as it peaks
	var peak := absf(sin(th)) > 0.82
	for row in range(5):
		var ry := c.y + (-30.0 + float(row) * 16.0) * sc
		wc.rect(Rect2(c.x - 17.0 * sc, ry + 5.0 * sc, 34.0 * sc, 3.0 * sc), WOOD_DARK)
		for col in range(2):
			var rp := Vector2(c.x + (-8.0 + float(col) * 16.0) * sc, ry)
			var k := float(row * 2 + col)
			wc.circle(rp, 5.5 * sc, _pick(SHIRTS, k, 1.0))
			wc.circle(rp + Vector2(0.0, -1.0) * sc, 3.8 * sc, _pick(SKINS, k, 2.0))
			wc.circle(rp + Vector2(0.0, 0.8) * sc, 3.4 * sc, _pick(HAIRS, k, 3.0))
			if peak:
				wc.circle(rp + Vector2(-6.0, -5.0) * sc, 1.8 * sc, _pick(SKINS, k, 2.0))
				wc.circle(rp + Vector2(6.0, -5.0) * sc, 1.8 * sc, _pick(SKINS, k, 2.0))
	# the stern's flag: black, a white skull dot
	var fl := c + Vector2(0.0, 58.0) * sc
	wc.quad(fl, fl + Vector2(18.0, 4.0) * sc, fl + Vector2(18.0, 14.0) * sc, fl + Vector2(0.0, 12.0) * sc, INK)
	wc.circle(fl + Vector2(9.0, 8.0) * sc, 2.6 * sc, Color(0.96, 0.96, 0.92))
	# the arms up to the axle and the beam across the basin, over the ship
	var q := HARBOUR.grow(QUAY)
	var ax := Vector2(SHIP.x, SHIP.y)
	for d: float in [-1.0, 1.0]:
		wc.line(ax + Vector2(d * 14.0, 0.0), c + Vector2(d * 14.0 * sc, 0.0), STEEL_DARK, 5.0)
		wc.line(ax + Vector2(d * 14.0, 0.0), c + Vector2(d * 14.0 * sc, 0.0), STEEL, 2.0)
	wc.line(Vector2(q.position.x + 14.0, SHIP.y) + Shade.light * 30.0, Vector2(q.end.x - 14.0, SHIP.y) + Shade.light * 30.0, Color(0.02, 0.10, 0.18, 0.25), 10.0)
	wc.line(Vector2(q.position.x + 14.0, SHIP.y), Vector2(q.end.x - 14.0, SHIP.y), STEEL_DARK, 11.0)
	wc.line(Vector2(q.position.x + 14.0, SHIP.y - 2.0), Vector2(q.end.x - 14.0, SHIP.y - 2.0), STEEL.lightened(0.1), 4.0)
	wc.circle(ax, 9.0, STEEL_DARK)
	wc.circle(ax - Vector2(1.5, 1.5), 5.0, STEEL.lightened(0.2))


static func _carousel(wc: ShapeBatch, t_ms: float) -> void:
	var spin := t_ms * 0.0011
	var c := CAROUSEL
	_disc_shadow(wc, c, CAROUSEL_R + 10.0, 22.0)
	# the platform's rim, then the canopy turning with it, scalloped
	wc.circle(c, CAROUSEL_R + 10.0, Color(0.94, 0.90, 0.80))
	for i in range(20):
		var a := spin + float(i) * TAU / 20.0
		wc.circle(c + Vector2.from_angle(a) * (CAROUSEL_R + 6.0), 6.0, MAGENTA if i % 2 == 0 else SAFFRON)
	_cone(wc, c, CAROUSEL_R + 2.0, MAGENTA, Color(0.98, 0.94, 0.84), 20, spin)
	# the horses peeping out under the canopy's edge, bobbing
	for i in range(8):
		var a := spin + float(i) * TAU / 8.0 + 0.2
		var bob := sin(spin * 6.0 + float(i) * 1.3) * 2.0
		var hp := c + Vector2.from_angle(a) * (CAROUSEL_R + 1.0 + bob)
		var tang := Vector2.from_angle(a + PI * 0.5)
		wc.capsule(hp - tang * 7.0, hp + tang * 7.0, 4.5, Color(0.96, 0.94, 0.92) if i % 2 == 0 else Color(0.62, 0.40, 0.26))
		wc.circle(hp + tang * 8.0 + Vector2.from_angle(a) * 2.0, 3.6, Color(0.96, 0.94, 0.92) if i % 2 == 0 else Color(0.62, 0.40, 0.26))
		wc.line(hp, hp - Vector2.from_angle(a) * 6.0, SAFFRON, 1.5)
	# the crown: a finial and its flag
	wc.circle(c, 12.0, TURQ)
	wc.circle(c - Vector2(2.0, 2.0), 6.0, SAFFRON.lightened(0.2))
	var fa := spin * 2.0
	wc.quad(c, c + Vector2.from_angle(fa) * 20.0, c + Vector2.from_angle(fa + 0.3) * 18.0, c, MAGENTA)


static func _grill_fire(wc: ShapeBatch, t_ms: float) -> void:
	var g := PRIZE + Vector2(0.0, -40.0)
	var tsec := t_ms * 0.001
	var flick := 0.8 + 0.2 * sin(tsec * 9.0)
	wc.glow(g, 34.0, Color(1.0, 0.46, 0.12, 0.40 * flick), 0.35)
	for i in range(5):
		var f := fposmod(tsec * 0.35 + float(i) * 0.2, 1.0)
		var sp := g + Vector2(sin(tsec * 1.3 + float(i) * 2.0) * 8.0 + f * 26.0, -10.0 - f * 70.0)
		wc.glow(sp, 10.0 + f * 16.0, Color(0.82, 0.82, 0.86, 0.34 * (1.0 - f)), 0.3)


static func _balloons(wc: ShapeBatch, vt: float, vb: float, t_ms: float) -> void:
	if not Outdoors.theme_park(Game.weather, Game.hour):
		return
	for i in range(BALLOON_SPOTS.size()):
		var p: Vector2 = BALLOON_SPOTS[i]
		if p.y < vt - 60.0 or p.y > vb + 60.0:
			continue
		_person(wc, p, 300.0 + float(i), 1.0, Vector2.DOWN, "cap")
		var tug := sin(t_ms * 0.003 + float(i)) * 4.0
		var drift := Vector2(sin(t_ms * 0.0013 + float(i)) * 3.0, -30.0 + tug)
		for j in range(7):
			var a := float(j) * TAU / 7.0 + t_ms * 0.0004
			var bp := p + drift + Vector2.from_angle(a) * (9.0 + float(j % 2) * 6.0)
			wc.line(p + Vector2(6.0, -2.0), bp, Color(0.90, 0.90, 0.92, 0.7), 1.0)
		for j in range(7):
			var a := float(j) * TAU / 7.0 + t_ms * 0.0004
			var bp := p + drift + Vector2.from_angle(a) * (9.0 + float(j % 2) * 6.0)
			var col: Color = [MAGENTA, SAFFRON, TURQ, Color(0.30, 0.55, 0.90), Color(0.95, 0.40, 0.55), Color(0.60, 0.85, 0.40), Color(0.96, 0.96, 0.94)][j]
			wc.circle(bp + Shade.light * 22.0, 6.0, Color(SHADOW, 0.12))
			wc.circle(bp, 7.0, col)
			wc.circle(bp + Vector2(-2.5, -2.5), 2.2, Color(1.0, 1.0, 1.0, 0.55))


# the tiki torches either side of each hut's door, burning day and night
static func _torches(wc: ShapeBatch, vt: float, vb: float, t_ms: float) -> void:
	if vb < SELVA_Y1 - 100.0 or vt > SELVA_Y0 + 100.0:
		return
	var tint_lit := Game.lamp_glow()
	for tp: Vector2 in _torch_list():
		if tp.y < vt - 40.0 or tp.y > vb + 40.0:
			continue
		var fl := 0.8 + 0.2 * sin(t_ms * 0.012 + tp.x)
		wc.circle(tp + Shade.light * 10.0, 4.0, Color(SHADOW, 0.3))
		wc.circle(tp, 4.5, WOOD_DARK)
		wc.glow(tp + Vector2(0.0, -2.0), 9.0 + 8.0 * tint_lit, Color(1.0, 0.62, 0.20, 0.55 * fl), 0.3)
		wc.circle(tp + Vector2(0.0, -2.0), 2.6 * fl, Color(1.0, 0.86, 0.40))


static var _torches_cache: Array[Vector2] = []


static func _torch_list() -> Array[Vector2]:
	if _torches_cache.is_empty():
		for side: float in [-1.0, 1.0]:
			for pl: Array in _plots(SELVA_Y1, SELVA_Y0, 41.0 + side, 120.0, 170.0, 140.0):
				var c := Vector2(PATH_L - 110.0 if side < 0.0 else PATH_R + 110.0, (pl[0] + pl[1]) * 0.5)
				if side > 0.0 and c.y > FLUME_TOP.y - 100.0 and c.y < FLUME_POOL.end.y + 90.0:
					continue
				_torches_cache.append_array(_torch_spots(side, c))
	return _torches_cache


static func _flume_live(m: Node2D, wc: ShapeBatch, vt: float, vb: float) -> void:
	if FLUME_POOL.end.y < vt - 300.0 or FLUME_TOP.y > vb + 200.0:
		return
	var w: Dictionary = m.atraccions_flume
	var st: String = str(w.get("state", "wait"))
	var t: float = float(w.get("t", 0.0))
	var t_ms := float(AnimClock.msec())
	var pool_c := FLUME_POOL.get_center()
	var boat := pool_c + Vector2(sin(t_ms * 0.0007) * 30.0, cos(t_ms * 0.0005) * 14.0)
	var tilt := 1.0
	if st == "climb":
		# clanking at the top of the drop, its riders screaming
		boat = FLUME_TOP + Vector2(sin(t_ms * 0.04) * 1.5, 30.0)
	elif st == "splash":
		var k := clampf(t / (FLUME_SPLASH * 0.3), 0.0, 1.0)
		boat = (FLUME_TOP + Vector2(0.0, 30.0)).lerp(FLUME_FOOT + Vector2(0.0, 24.0), k * k)
		tilt = 1.0 + k * 0.25
	# the log boat: a hollowed log, four riders in ponchos
	wc.capsule(boat + Vector2(0.0, -20.0) * tilt + Shade.light * 10.0, boat + Vector2(0.0, 20.0) * tilt + Shade.light * 10.0, 11.0, Color(0.02, 0.10, 0.18, 0.3))
	wc.capsule(boat + Vector2(0.0, -20.0) * tilt, boat + Vector2(0.0, 20.0) * tilt, 11.0, WOOD_DARK)
	wc.capsule(boat + Vector2(0.0, -17.0) * tilt, boat + Vector2(0.0, 17.0) * tilt, 7.5, WOOD)
	for i in range(4):
		var rp := boat + Vector2(0.0, (-12.0 + float(i) * 8.0) * tilt)
		wc.circle(rp, 4.5, PONCHO if i % 2 == 0 else Color(0.20, 0.56, 0.82))
		wc.circle(rp + Vector2(0.0, -1.0), 2.8, _pick(SKINS, float(i), 2.0))
	if st == "climb":
		wc.glow(boat + Vector2(0.0, -10.0), 30.0, Color(1.0, 0.85, 0.4, 0.30), 0.4)
	if st == "splash":
		var fade := minf(1.0, minf(t * 4.0, (FLUME_SPLASH - t) * 3.0))
		# the plume where it hits the pool
		var foot := FLUME_FOOT + Vector2(0.0, 30.0)
		wc.glow(foot, 60.0 + t * 30.0, Color(1.0, 1.0, 1.0, 0.55 * fade), 0.3)
		for j in range(10):
			var a := float(j) * TAU / 10.0
			var r := 20.0 + t * 70.0
			wc.circle(foot + Vector2.from_angle(a) * r, 6.0, Color(1.0, 1.0, 1.0, 0.6 * fade))
		# the wave from the pool across the path toward the dry (west) side
		wc.band(PackedVector2Array([
			Vector2(FLUME_WASH_X, FLUME_Y0), Vector2(PATH_R + 50.0, FLUME_Y0),
			Vector2(FLUME_WASH_X + 20.0, FLUME_Y0 + 40.0), Vector2(PATH_R + 50.0, FLUME_Y0 + 40.0),
			Vector2(FLUME_WASH_X + 40.0, (FLUME_Y0 + FLUME_Y1) * 0.5), Vector2(PATH_R + 50.0, (FLUME_Y0 + FLUME_Y1) * 0.5),
			Vector2(FLUME_WASH_X + 60.0, FLUME_Y1), Vector2(PATH_R + 50.0, FLUME_Y1),
		]), 2, Color(WATER.lightened(0.25), 0.55 * fade), PackedFloat32Array([0.4, 0.8, 0.8, 0.3]), PackedFloat32Array([0.0, 1.0]))
		for j in range(16):
			var f := fposmod(t_ms * 0.0015 + float(j) * 0.11, 1.0)
			var p := Vector2(lerpf(PATH_R + 40.0, FLUME_WASH_X, f), lerpf(FLUME_Y0, FLUME_Y1, _h(float(j))))
			wc.circle(p, 4.0 + f * 8.0, Color(1.0, 1.0, 1.0, 0.55 * fade * (1.0 - f)))


# --- bulbs: the rides' and kiosks' lights, unlit by day, glowing after dark ------

static var _bulb_cache: Array[Vector3] = []


# every bulb on the buildings, the stations and the ship's frame, built
# once; z is its kind (0 white bulb, 1 oil lamp, 2 coloured festoon)
static func _bulbs() -> Array[Vector3]:
	if not _bulb_cache.is_empty():
		return _bulb_cache
	var out: Array[Vector3] = []
	for side: float in [-1.0, 1.0]:
		for pl: Array in _plots(CORSARI_Y0, GATE_IN - 10.0, 11.0 + side, 110.0, 150.0, 16.0):
			var r := _gift_rect(side, pl[0], pl[1], pl[2])
			var ex := r.end.x + 34.0 if side < 0.0 else r.position.x - 34.0
			var y := r.position.y + 12.0
			while y < r.end.y - 8.0:
				out.append(Vector3(ex, y, 0.0))
				y += 16.0
		for pl: Array in _plots(CANYON_Y1, CANYON_Y0, 31.0 + side, 84.0, 130.0, 60.0):
			if side < 0.0 and pl[1] > MINE_STATION.position.y - 20.0 and pl[0] < MINE_STATION.end.y + 20.0:
				continue
			if side > 0.0 and _hk(pl[2], 12.0) < 0.16:
				continue
			var r := _western_rect(side, pl[0], pl[1], pl[2])
			var px := PATH_L - 3.0 if side < 0.0 else PATH_R + 3.0
			out.append(Vector3(px, r.position.y + 7.0, 1.0))
			out.append(Vector3(px, r.end.y - 7.0, 1.0))
		for pl: Array in _plots(LOOP_Y1, LOOP_Y0, 51.0 + side, 96.0, 140.0, 40.0):
			if side > 0.0 and pl[1] > STATION.position.y - 340.0 and pl[0] < STATION.end.y + 30.0:
				continue
			if _hk(pl[2], 1.0) < 0.38:
				var kc := Vector2(PATH_L - 70.0 if side < 0.0 else PATH_R + 70.0, (pl[0] + pl[1]) * 0.5)
				for i in range(12):
					var bp := kc + Vector2.from_angle(float(i) * TAU / 12.0) * 43.0
					out.append(Vector3(bp.x, bp.y, 2.0))
			else:
				var r := _arcade_rect(side, pl[0], pl[1], pl[2])
				var fx := r.end.x if side < 0.0 else r.position.x
				var y := r.position.y + 6.0
				while y < r.end.y - 4.0:
					out.append(Vector3(fx, y, 0.0))
					y += 24.0
	# the mine station's platform lanterns
	var ly := MINE_STATION.position.y + 30.0
	while ly < MINE_STATION.end.y - 10.0:
		out.append(Vector3(MINE_STATION.end.x - 3.0, ly, 1.0))
		ly += 52.0
	# the coaster station's marquee, round its board
	var sign := Rect2(STATION.position.x + 10.0, STATION.get_center().y - 70.0, 18.0, 140.0)
	var sy := sign.position.y
	while sy <= sign.end.y:
		out.append(Vector3(sign.position.x - 3.0, sy, 0.0))
		out.append(Vector3(sign.end.x + 3.0, sy, 0.0))
		sy += 14.0
	# and its canopy's edge
	sy = STATION.position.y + 26.0
	while sy < STATION.end.y - 20.0:
		out.append(Vector3(STATION.position.x - 18.0, sy, 2.0))
		sy += 20.0
	# the pirate ship's beam
	var q := HARBOUR.grow(QUAY)
	var bx := q.position.x + 30.0
	while bx < q.end.x - 20.0:
		out.append(Vector3(bx, SHIP.y + 7.0, 2.0))
		bx += 22.0
	_bulb_cache = out
	return out


static func _bulb_col(kind: float, i: int) -> Color:
	if kind == 1.0:
		return Color(1.0, 0.72, 0.36)
	if kind == 2.0:
		return [Color(1.0, 0.50, 0.70), Color(1.0, 0.86, 0.40), Color(0.50, 0.92, 0.90), Color(1.0, 0.96, 0.84)][i % 4]
	return BULB


# unlit bulbs on the buildings by day (in the cached edge layer)
static func _edge_bulbs(b: ShapeBatch, top: float, bot: float) -> void:
	if Game.lamp_glow() > 0.02:
		return
	for bl: Vector3 in _bulbs():
		if bl.y < top - 40.0 or bl.y > bot + 40.0:
			continue
		b.coarse(Vector2(bl.x, bl.y), 2.6, Color(0.30, 0.28, 0.26))
		b.coarse(Vector2(bl.x - 0.6, bl.y - 0.6), 1.6, BULB_DAY)


static func _bulbs_lit(m: Node2D, wc: ShapeBatch, vt: float, vb: float, glow: float, t_ms: float) -> void:
	var tint := _tint(m)
	var i := 0
	var chase := int(t_ms / 220.0)
	for bl: Vector3 in _bulbs():
		i += 1
		if bl.y < vt - 30.0 or bl.y > vb + 30.0:
			continue
		var col := _bulb_col(bl.z, i)
		# festoons chase, one bulb in three dimmer in turn
		var k := 0.55 if bl.z == 2.0 and (i + chase) % 3 == 0 else 1.0
		var p := Vector2(bl.x, bl.y)
		wc.coarse(p, 9.0, SkyLook.light(Color(col.r, col.g, col.b, 0.22 * glow * k), tint))
		wc.coarse(p, 2.8, SkyLook.light(Color(col.r, col.g, col.b, glow * k), tint))
	# the carousel's rim
	if CAROUSEL.y > vt - 100.0 and CAROUSEL.y < vb + 100.0:
		var spin := t_ms * 0.0011
		for j in range(20):
			var p := CAROUSEL + Vector2.from_angle(spin + float(j) * TAU / 20.0 + 0.16) * (CAROUSEL_R + 6.0)
			var col := _bulb_col(2.0, j)
			wc.coarse(p, 8.0, SkyLook.light(Color(col.r, col.g, col.b, 0.25 * glow), tint))
			wc.coarse(p, 2.6, SkyLook.light(Color(col.r, col.g, col.b, glow), tint))


# --- overhead: the arch, crowns, trestle, coaster ------------------------------------

static var _arch_cache: Array = []
static var _arch_points := PackedVector2Array()


static func _arch_letters() -> Array:
	if _arch_cache.is_empty():
		var lay: Array = SignLetters.layout("LES ATRACCIONS", Vector2(CX, ARCH.y + 13.0), 25.0, 460.0)
		_arch_cache = lay[0]
		_arch_points = SignLetters.points(_arch_cache, 10.0)
	return _arch_cache


static func draw_overhead(m: Node2D, ci: Object) -> void:
	if m.lvl != "atraccions":
		return
	var b := ShapeBatch.new()
	b.lod = true
	var t_ms := float(AnimClock.msec())
	var cy: float = m.cam.position.y if m.get("cam") != null else 0.0
	var vt := cy - 700.0
	var vb := cy + 700.0
	for i in range(PALMS.size()):
		if PALMS[i].y > vt and PALMS[i].y < vb:
			_palm_crown(b, PALMS[i] + Vector2(0.0, -14.0), 40.0, float(i))
	for i in range(JUNGLE_TREES.size()):
		if JUNGLE_TREES[i].y > vt and JUNGLE_TREES[i].y < vb:
			_jungle_crown(b, JUNGLE_TREES[i] + Vector2(0.0, -12.0), 44.0, float(i))
	for i in range(SHADE_TREES.size()):
		if SHADE_TREES[i].y > vt - 100.0 and SHADE_TREES[i].y < vb + 100.0:
			_shade_crown(b, SHADE_TREES[i], float(i))
	if vb > CANYON_Y1 - 200.0 and vt < CANYON_Y0 + 400.0:
		_draw_mine_train(b, t_ms)
	if vb > LOOP_Y1 - 200.0 and vt < LOOP_Y0 + 200.0:
		_draw_coaster(b, t_ms)
	if ARCH.y > vt - 200.0 and ARCH.y < vb + 200.0:
		_lintel(m, b, t_ms)
	_festoons(m, b, vt, vb, t_ms)
	b.flush(ci)


static func _lintel(m: Node2D, b: ShapeBatch, t_ms: float) -> void:
	var x0 := PATH_L - 2.0
	var x1 := PATH_R + 2.0
	var top := Rect2(x0, ARCH.y - 46.0, x1 - x0, 28.0)
	var face := Rect2(x0, ARCH.y - 18.0, x1 - x0, 42.0)
	# the beam's top: saffron, striped with turquoise
	b.rect(top, SAFFRON)
	var sx := x0 + 10.0
	while sx < x1:
		b.rect(Rect2(sx, top.position.y + 3.0, 14.0, top.size.y - 6.0), SAFFRON.lightened(0.14))
		sx += 28.0
	b.rect(Rect2(x0, top.position.y, top.size.x, 4.0), SAFFRON.lightened(0.3))
	# the face toward the forecourt with the park's name
	b.rect(face, MAGENTA.darkened(0.15))
	b.rect(Rect2(x0, face.position.y, face.size.x, 4.0), MAGENTA.lightened(0.1))
	b.rect(Rect2(x0, face.end.y - 6.0, face.size.x, 6.0), MAGENTA.darkened(0.45))
	var lines := _arch_letters()
	for pl: PackedVector2Array in lines:
		for i in range(pl.size() - 1):
			b.line(pl[i] + Vector2(1.5, 2.0), pl[i + 1] + Vector2(1.5, 2.0), MAGENTA.darkened(0.5), 5.0)
	for pl: PackedVector2Array in lines:
		for i in range(pl.size() - 1):
			b.line(pl[i], pl[i + 1], Color(1.0, 0.94, 0.78), 4.4)
		b.circle(pl[0], 2.2, Color(1.0, 0.94, 0.78))
		b.circle(pl[pl.size() - 1], 2.2, Color(1.0, 0.94, 0.78))
	# the crest over the middle: a sun in a ring, a coaster car across it
	var cc := Vector2(CX, top.position.y - 20.0)
	b.circle(cc + Shade.light * 12.0, 34.0, Color(SHADOW, 0.3))
	b.circle(cc, 34.0, TURQ.darkened(0.2))
	b.circle(cc, 29.0, TURQ)
	_cone(b, cc, 24.0, SAFFRON, SAFFRON.lightened(0.25), 12, 0.0)
	b.capsule(cc + Vector2(-14.0, 4.0), cc + Vector2(14.0, 4.0), 6.0, MAGENTA)
	b.circle(cc + Vector2(-8.0, 2.0), 3.0, Color(0.96, 0.80, 0.66))
	b.circle(cc + Vector2(6.0, 2.0), 3.0, Color(0.96, 0.80, 0.66))
	# the letters' bulbs: unlit by day, the name in lights after dark
	var glow := Game.lamp_glow()
	var tint := _tint(m)
	for p: Vector2 in _arch_points:
		if glow > 0.02:
			b.coarse(p, 7.0, SkyLook.light(Color(BULB.r, BULB.g, BULB.b, 0.22 * glow), tint))
			b.coarse(p, 2.4, SkyLook.light(Color(BULB.r, BULB.g, BULB.b, glow), tint))
		else:
			b.coarse(p, 1.4, Color(0.98, 0.98, 0.94))
	# bulbs along the beam's edge, chasing after dark
	var chase := int(t_ms / 180.0)
	var bx := x0 + 8.0
	var j := 0
	while bx < x1:
		var p := Vector2(bx, top.position.y + 2.0)
		if glow > 0.02:
			var col := _bulb_col(2.0, j)
			var k := 0.5 if (j + chase) % 3 == 0 else 1.0
			b.coarse(p, 7.0, SkyLook.light(Color(col.r, col.g, col.b, 0.25 * glow * k), tint))
			b.coarse(p, 2.6, SkyLook.light(Color(col.r, col.g, col.b, glow * k), tint))
		else:
			b.coarse(p, 2.2, BULB_DAY)
		bx += 16.0
		j += 1


# festoons of coloured bulbs strung across the plazas and the lawn: the wire
# sagging between its poles, the bulbs unlit by day
const FESTOONS: Array = [
	[Vector2(PATH_L - 40.0, -300.0), Vector2(PATH_R + 40.0, -360.0)],
	[Vector2(PATH_L - 30.0, -3460.0), Vector2(PATH_R + 30.0, -3520.0)],
	[Vector2(PATH_L - 30.0, -4180.0), Vector2(PATH_R + 30.0, -4240.0)],
	[Vector2(PATH_L - 40.0, -4560.0), Vector2(PATH_R + 40.0, -4600.0)],
	[Vector2(PATH_L - 40.0, -4860.0), Vector2(PATH_R + 40.0, -4820.0)],
]


static func _festoons(m: Node2D, b: ShapeBatch, vt: float, vb: float, t_ms: float) -> void:
	var glow := Game.lamp_glow()
	var tint := _tint(m)
	var chase := int(t_ms / 260.0)
	for fi in range(FESTOONS.size()):
		var a: Vector2 = FESTOONS[fi][0]
		var z: Vector2 = FESTOONS[fi][1]
		if maxf(a.y, z.y) < vt - 60.0 or minf(a.y, z.y) > vb + 60.0:
			continue
		var n := 24
		var prev := a
		for i in range(1, n + 1):
			var f := float(i) / float(n)
			var p := a.lerp(z, f) + Vector2(0.0, sin(f * PI) * 34.0)
			b.line(prev, p, Color(0.16, 0.16, 0.18), 1.4)
			prev = p
		for i in range(1, n):
			var f := float(i) / float(n)
			var p := a.lerp(z, f) + Vector2(0.0, sin(f * PI) * 34.0 + 3.0)
			var col := _bulb_col(2.0, i + fi)
			if glow > 0.02:
				var k := 0.5 if (i + chase) % 4 == 0 else 1.0
				b.coarse(p, 8.0, SkyLook.light(Color(col.r, col.g, col.b, 0.24 * glow * k), tint))
				b.coarse(p, 2.6, SkyLook.light(Color(col.r, col.g, col.b, glow * k), tint))
			else:
				b.coarse(p, 2.6, col.darkened(0.25))
				b.coarse(p - Vector2(0.7, 0.7), 1.2, Color(1.0, 1.0, 1.0, 0.6))
		for e: Vector2 in [a, z]:
			b.circle(e, 5.0, STEEL_DARK)
			b.circle(e - Vector2(1.0, 1.0), 2.5, STEEL)


static func _palm_crown(b: ShapeBatch, p: Vector2, r: float, seed_n: float) -> void:
	b.coarse(p + Shade.light * (r * 0.9), r * 0.9, Color(SHADOW, 0.22))
	for i in range(8):
		var a := float(i) * TAU / 8.0 + seed_n
		var dir := Vector2.from_angle(a)
		var tip := p + dir * r
		var n := dir.orthogonal() * 7.0
		b.quad(p, p + dir * r * 0.5 + n, tip, p + dir * r * 0.5 - n, Color(0.20, 0.50, 0.30))
		b.quad(p, p + dir * r * 0.5 + n * 0.5, tip - dir * 4.0, p + dir * r * 0.5, Color(0.36, 0.66, 0.36))
		b.line(p, tip - dir * 3.0, Color(0.50, 0.72, 0.40), 1.2)
	b.coarse(p, 7.0, Color(0.55, 0.40, 0.22))
	b.coarse(p + Vector2(3.0, 2.0), 3.0, Color(0.42, 0.28, 0.14))


static func _jungle_crown(b: ShapeBatch, p: Vector2, r: float, seed_n: float) -> void:
	b.coarse(p + Shade.light * (r * 0.9), r, Color(SHADOW, 0.25))
	for tier in range(3):
		var tr := r * (1.0 - float(tier) * 0.25)
		b.coarse(p - Vector2(1.0, 1.0) * float(tier) * 4.0, tr, JUNGLE.lerp(JUNGLE_LIT, float(tier) * 0.35))
	for i in range(6):
		var a := float(i) * TAU / 6.0 + seed_n
		b.coarse(p + Vector2.from_angle(a) * r * 0.62, r * 0.34, JUNGLE_LIT if i % 2 == 0 else JUNGLE)
		b.coarse(p + Vector2.from_angle(a) * r * 0.62 - Vector2(3.0, 3.0), r * 0.16, JUNGLE_LIT.lightened(0.1))


static func _shade_crown(b: ShapeBatch, p: Vector2, seed_n: float) -> void:
	var r := 62.0
	for i in range(7):
		var a := float(i) * TAU / 7.0 + seed_n
		var q := p + Vector2.from_angle(a) * r * 0.55
		b.coarse(q, r * 0.48, Color(0.20, 0.42, 0.24))
	b.coarse(p, r * 0.7, Color(0.24, 0.48, 0.26))
	for i in range(5):
		var a := float(i) * TAU / 5.0 + seed_n * 2.0
		b.coarse(p + Vector2.from_angle(a) * r * 0.35 - Vector2(8.0, 8.0), r * 0.28, Color(0.34, 0.58, 0.32))
	b.coarse(p - Vector2(14.0, 14.0), r * 0.22, Color(0.44, 0.66, 0.38))


# the length along a polyline to each of its points
static func _cumulative(path: PackedVector2Array, skip := -1) -> PackedFloat32Array:
	var out := PackedFloat32Array([0.0])
	for i in range(path.size() - 1):
		var seg := 0.0 if i == skip else path[i].distance_to(path[i + 1])
		out.append(out[i] + seg)
	return out


# the point at distance s along a polyline, and its heading
static func _along(path: PackedVector2Array, cum: PackedFloat32Array, s: float) -> Array:
	var total := cum[cum.size() - 1]
	s = fposmod(s, total)
	for i in range(path.size() - 1):
		if s <= cum[i + 1] and cum[i + 1] > cum[i]:
			var f := (s - cum[i]) / (cum[i + 1] - cum[i])
			return [path[i].lerp(path[i + 1], f), (path[i + 1] - path[i]).normalized(), i]
	return [path[0], Vector2.UP, 0]


static var _mine_pv := PackedVector2Array()
static var _mine_cum := PackedFloat32Array()


static func _draw_mine_train(b: ShapeBatch, t_ms: float) -> void:
	if _mine_pv.is_empty():
		_mine_pv = PackedVector2Array(MINE_PATH)
		_mine_cum = _cumulative(_mine_pv, MINE_GAP)
	# the trestle's bents: a timber crossbeam and its two legs every so often
	for i in range(_mine_pv.size() - 1):
		if i == MINE_GAP:
			continue
		var a := _mine_pv[i]
		var z := _mine_pv[i + 1]
		var dir := (z - a).normalized()
		var n := dir.orthogonal()
		var seg := a.distance_to(z)
		var s := 30.0
		while s < seg:
			var p := a + dir * s
			b.line(p - n * 20.0, p + n * 20.0, WOOD_DARK, 6.0)
			b.circle(p - n * 18.0, 4.0, WOOD_DARK)
			b.circle(p + n * 18.0, 4.0, WOOD_DARK)
			s += 80.0
	# the ties and the rails
	for i in range(_mine_pv.size() - 1):
		if i == MINE_GAP:
			continue
		var a := _mine_pv[i]
		var z := _mine_pv[i + 1]
		var dir := (z - a).normalized()
		var n := dir.orthogonal()
		var seg := a.distance_to(z)
		var s := 0.0
		while s < seg:
			var p := a + dir * s
			b.line(p - n * 11.0, p + n * 11.0, Color(0.40, 0.26, 0.16), 4.0)
			s += 11.0
		for r: float in [-7.0, 7.0]:
			b.line(a + n * r, z + n * r, STEEL_DARK, 3.4)
			b.line(a + n * r - Vector2(0.6, 0.6), z + n * r - Vector2(0.6, 0.6), STEEL.lightened(0.2), 1.2)
	# the train: an engine and three ore cars full of riders
	var total := _mine_cum[_mine_cum.size() - 1]
	var head := fposmod(t_ms * 0.001 * MINE_SPEED, total + 900.0)
	if head > total:
		return
	for ci in range(4):
		var s := head - float(ci) * 36.0
		if s < 0.0:
			continue
		var at: Array = _along(_mine_pv, _mine_cum, s)
		if int(at[2]) == MINE_GAP:
			continue
		var p: Vector2 = at[0]
		var dir: Vector2 = at[1]
		var n := dir.orthogonal()
		b.quad(p - dir * 15.0 - n * 12.0 + Shade.light * 8.0, p + dir * 15.0 - n * 12.0 + Shade.light * 8.0,
			p + dir * 15.0 + n * 12.0 + Shade.light * 8.0, p - dir * 15.0 + n * 12.0 + Shade.light * 8.0, Color(SHADOW, 0.3))
		var body := Color(0.22, 0.22, 0.24) if ci == 0 else Color(0.55, 0.26, 0.16)
		b.quad(p - dir * 15.0 - n * 12.0, p + dir * 15.0 - n * 12.0, p + dir * 15.0 + n * 12.0, p - dir * 15.0 + n * 12.0, body)
		b.quad(p - dir * 12.0 - n * 9.0, p + dir * 12.0 - n * 9.0, p + dir * 12.0 + n * 9.0, p - dir * 12.0 + n * 9.0, body.lightened(0.15))
		if ci == 0:
			b.circle(p + dir * 6.0, 5.0, INK)
			b.circle(p + dir * 6.0, 2.5, Color(0.36, 0.36, 0.38))
			b.circle(p - dir * 8.0, 3.0, SAFFRON)
		else:
			for d: float in [-1.0, 1.0]:
				var rp := p + n * d * 4.5
				var k := float(ci * 2) + d
				b.circle(rp, 4.2, _pick(SHIRTS, k, 1.0))
				b.circle(rp, 3.0, _pick(SKINS, k, 2.0))
				b.circle(rp - dir * 0.8, 2.6, _pick(HAIRS, k, 3.0))


static var _coaster_pv := PackedVector2Array()
static var _coaster_cum := PackedFloat32Array()


# the coaster's circuit: out of the station north up the lift, round over the
# crest and west down into the loop, once round it, then back east over the
# queue into the station
static func _coaster_path() -> PackedVector2Array:
	if not _coaster_pv.is_empty():
		return _coaster_pv
	var p := PackedVector2Array()
	p.append(Vector2(LIFT_TOP.x, STATION.end.y - 10.0))
	p.append(Vector2(LIFT_TOP.x, STATION.position.y))
	p.append(LIFT_TOP)
	var crest := LIFT_TOP + Vector2(-70.0, 0.0)
	for i in range(1, 9):
		p.append(crest + Vector2.from_angle(-float(i) * PI / 8.0) * 70.0)
	p.append(Vector2(860.0, -4230.0))
	p.append(Vector2(780.0, -4140.0))
	var top := LOOP_C + Vector2(0.0, -LOOP_R)
	p.append(top + Vector2(20.0, -2.0))
	for i in range(49):
		var a := -PI * 0.5 - float(i) * TAU / 48.0
		p.append(LOOP_C + Vector2.from_angle(a) * LOOP_R + Vector2(0.0, -float(i) * 0.25))
	p.append(Vector2(600.0, -4140.0))
	p.append(Vector2(530.0, -4090.0))
	p.append(Vector2(510.0, -3990.0))
	p.append(Vector2(540.0, -3880.0))
	p.append(Vector2(640.0, -3840.0))
	p.append(Vector2(800.0, -3810.0))
	p.append(Vector2(940.0, -3760.0))
	p.append(Vector2(LIFT_TOP.x - 20.0, -3720.0))
	p.append(Vector2(LIFT_TOP.x, STATION.end.y - 10.0))
	_coaster_pv = p
	_coaster_cum = _cumulative(p)
	return p


static func _draw_coaster(b: ShapeBatch, t_ms: float) -> void:
	var path := _coaster_path()
	# the pylons under the track, and the loop's own A-frame
	var acc := 0.0
	for i in range(path.size() - 1):
		acc += path[i].distance_to(path[i + 1])
		if acc > 90.0:
			acc = 0.0
			b.circle(path[i] + Shade.light * 10.0, 7.0, Color(SHADOW, 0.3))
			b.circle(path[i], 7.0, STEEL_DARK)
			b.circle(path[i] - Vector2(1.5, 1.5), 3.5, STEEL)
	b.line(LOOP_C + Vector2(-LOOP_R - 18.0, 30.0), LOOP_C + Vector2(LOOP_R + 18.0, 30.0), STEEL_DARK, 8.0)
	b.line(LOOP_C + Vector2(-LOOP_R - 18.0, 28.0), LOOP_C + Vector2(LOOP_R + 18.0, 28.0), STEEL, 3.0)
	# the track: a dark spine, its ties, two bright rails
	for i in range(path.size() - 1):
		var a := path[i]
		var z := path[i + 1]
		b.line(a, z, Color(0.24, 0.20, 0.30), 16.0)
		b.circle(a, 8.0, Color(0.24, 0.20, 0.30))
	for i in range(path.size() - 1):
		var a := path[i]
		var z := path[i + 1]
		var dir := (z - a).normalized()
		var n := dir.orthogonal()
		var seg := a.distance_to(z)
		var s := 0.0
		while s < seg:
			b.line(a + dir * s - n * 8.0, a + dir * s + n * 8.0, MAGENTA.darkened(0.3), 2.0)
			s += 9.0
		for r: float in [-5.5, 5.5]:
			b.line(a + n * r, z + n * r, Color(0.86, 0.88, 0.92), 2.6)
	# the lift's chain up the middle
	var ly := STATION.position.y
	while ly > LIFT_TOP.y:
		b.rect(Rect2(LIFT_TOP.x - 1.5, ly - 4.0, 3.0, 4.0), INK)
		ly -= 8.0
	# the train: five cars, riders two by two, arms up on the loop
	var total := _coaster_cum[_coaster_cum.size() - 1]
	var head := fposmod(t_ms * 0.001 * COASTER_SPEED, total + 600.0)
	if head > total:
		return
	for ci in range(5):
		var s := head - float(ci) * 30.0
		if s < 0.0:
			continue
		var at: Array = _along(path, _coaster_cum, s)
		var p: Vector2 = at[0]
		var dir: Vector2 = at[1]
		var n := dir.orthogonal()
		var col := MAGENTA if ci == 0 else (SAFFRON if ci % 2 == 1 else TURQ)
		b.capsule(p - dir * 10.0 + Shade.light * 12.0, p + dir * 10.0 + Shade.light * 12.0, 9.0, Color(SHADOW, 0.25))
		b.capsule(p - dir * 10.0, p + dir * 10.0, 9.0, col.darkened(0.2))
		b.capsule(p - dir * 9.0, p + dir * 9.0, 7.0, col)
		var on_loop := int(at[2]) >= 14 and int(at[2]) <= 62
		for d: float in [-1.0, 1.0]:
			var rp := p + n * d * 4.0
			var k := float(ci * 2) + d
			b.circle(rp, 3.4, _pick(SKINS, k, 2.0))
			b.circle(rp - dir * 0.8, 2.8, _pick(HAIRS, k, 3.0))
			if on_loop:
				b.circle(rp + n * d * 5.0 + dir * 3.0, 1.6, _pick(SKINS, k, 2.0))


# --- night ---------------------------------------------------------------------------

# the light out of the park's doors and windows after dark, each where its
# front stands in draw_edge_layer
static func night_fronts(_m: Node2D) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var n := 0
	for side: float in [-1.0, 1.0]:
		var at_x := PATH_L if side < 0.0 else PATH_R
		var dir := 1.0 if side < 0.0 else -1.0
		for pl: Array in _plots(CORSARI_Y0, GATE_IN - 10.0, 11.0 + side, 110.0, 150.0, 16.0):
			out.append(NightFronts.front(Vector2(at_x, (pl[0] + pl[1]) * 0.5), dir, "shop", 6100 + n))
			n += 1
		for pl: Array in _plots(GATE_OUT + 30.0, 820.0, 13.0 + side, 120.0, 170.0, 40.0):
			out.append(NightFronts.front(Vector2(at_x, (pl[0] + pl[1]) * 0.5), dir, "shop", 6100 + n))
			n += 1
		var q := HARBOUR.grow(QUAY + 14.0)
		for pl: Array in _plots(CORSARI_Y1, CORSARI_Y0, 23.0 + side, 76.0, 128.0, 10.0):
			if side < 0.0 and pl[1] > q.position.y - 30.0 and pl[0] < q.end.y + 30.0:
				continue
			var kind: String = ["home", "home", "tv", "bar", ""][int(_hk(pl[2], 20.0) * 5.0) % 5]
			if kind != "":
				var r := _house_rect(side, pl[0], pl[1], pl[2])
				out.append(NightFronts.front(Vector2(at_x, _house_door_y(r, pl[2])), dir, kind, 6100 + n))
			n += 1
		for pl: Array in _plots(CANYON_Y1, CANYON_Y0, 31.0 + side, 84.0, 130.0, 60.0):
			if side < 0.0 and pl[1] > MINE_STATION.position.y - 20.0 and pl[0] < MINE_STATION.end.y + 20.0:
				continue
			if side > 0.0 and _hk(pl[2], 12.0) < 0.16:
				continue
			out.append(NightFronts.front(Vector2(at_x, (pl[0] + pl[1]) * 0.5), dir, "bar" if _hk(pl[2], 21.0) < 0.5 else "shop", 6100 + n))
			n += 1
		for pl: Array in _plots(LOOP_Y1, LOOP_Y0, 51.0 + side, 96.0, 140.0, 40.0):
			if side > 0.0 and pl[1] > STATION.position.y - 340.0 and pl[0] < STATION.end.y + 30.0:
				continue
			if _hk(pl[2], 1.0) >= 0.38:
				out.append(NightFronts.front(Vector2(at_x, (pl[0] + pl[1]) * 0.5), dir, "shop", 6100 + n))
			n += 1
	out.append(NightFronts.front(Vector2(PATH_L, MINE_STATION.get_center().y), 1.0, "shop", 6190))
	out.append(NightFronts.front(Vector2(PATH_R, STATION.get_center().y), -1.0, "shop", 6191))
	return out


# the park's lamps and a pool of light under each lit ride
static func night_lights(m: Node2D) -> Array[Vector3]:
	var out: Array[Vector3] = []
	var lamp_r: float = m.NIGHT_LAMP_R
	for lp: Vector2 in PARK_LAMPS:
		out.append(Vector3(lp.x, lp.y + 16.0, lamp_r))
	for p: Vector3 in [
		Vector3(ARCH.x, ARCH.y + 30.0, 260.0), Vector3(CAROUSEL.x, CAROUSEL.y, 230.0),
		Vector3(SHIP.x + 80.0, SHIP.y, 230.0), Vector3(STATION.position.x - 20.0, STATION.get_center().y, 240.0),
		Vector3(PATH_R + 20.0, FLUME_POOL.position.y - 80.0, 200.0), Vector3(PRIZE.x, PRIZE.y - 40.0, 210.0),
		Vector3(FOUNTAIN.x, FOUNTAIN.y, 200.0),
	]:
		out.append(p)
	return out


static func is_lamp(_m: Node2D, p: Vector2) -> bool:
	for lp: Vector2 in PARK_LAMPS:
		if lp.distance_squared_to(p) < 4.0:
			return true
	return false


static func name_place(_m: Node2D) -> Dictionary:
	# stubs are fat: force LES / ATRACCIONS on two lines with room for the
	# stub pieces inside the 540-wide path (Camí de Ronda / Carrer de Blai
	# style). Turnstiles sit at y=-340, clear of the letters.
	return {"x": CX, "room": 220.0, "down": 40.0}


static func tree_kind(m: Node2D, p: Vector2) -> int:
	for t: Vector2 in PALMS:
		if t.distance_squared_to(p) < 4.0:
			return m.TREE_PALM
	for t: Vector2 in JUNGLE_TREES:
		if t.distance_squared_to(p) < 4.0:
			return m.TREE_FOREST
	return m.TREE_NONE


static func draw_column(m: Node2D, wc: ShapeBatch, p: Vector2) -> void:
	for lp: Vector2 in PARK_LAMPS:
		if lp.distance_squared_to(p) < 4.0:
			wc.circle(p + Shade.light * 8.0, 8.0, Color(SHADOW, 0.3))
			wc.circle(p, 6.0, STEEL_DARK)
			wc.circle(p, 4.0, STEEL)
			return
	for t: Vector2 in QUEUE_POSTS:
		if t.distance_squared_to(p) < 4.0:
			# a chrome stanchion on its round foot
			wc.circle(p + Shade.light * 8.0, POST_R, Color(SHADOW, 0.3))
			wc.circle(p, POST_R, STEEL_DARK)
			wc.circle(p, POST_R - 2.5, Color(0.80, 0.82, 0.86))
			wc.circle(p - Vector2(1.5, 1.5), 3.0, Color(0.96, 0.97, 1.0))
			return
	for t: Vector2 in PALMS:
		if t.distance_squared_to(p) < 4.0:
			wc.circle(p + Shade.light * 14.0, 16.0, Color(SHADOW, 0.3))
			wc.circle(p, 10.0, Color(0.55, 0.40, 0.22))
			wc.circle(p, 7.0, Color(0.68, 0.50, 0.28))
			return
	for t: Vector2 in JUNGLE_TREES:
		if t.distance_squared_to(p) < 4.0:
			wc.circle(p + Shade.light * 14.0, 18.0, Color(SHADOW, 0.3))
			wc.circle(p, 12.0, Color(0.36, 0.24, 0.14))
			wc.circle(p, 8.0, Color(0.46, 0.30, 0.18))
			return
	wc.circle(p, 6.0, STEEL_DARK)


static func surface(m: Node2D, p: Vector2) -> int:
	if p.y <= m.GATE_Y:
		return -1
	# harbour / flume water (pools are off the corridor)
	if HARBOUR.has_point(p) or FLUME_POOL.has_point(p):
		return Surfaces.S.WATER
	# active splash wash across the path
	var w: Dictionary = m.atraccions_flume
	if str(w.get("state", "")) == "splash" and in_splash(p):
		return Surfaces.S.WATER
	# picnic lawn
	if p.y < PICNIC_Y and p.x > PATH_L and p.x < PATH_R:
		return Surfaces.S.GRASS
	# flume walkway stays pavement (checked before selva mud)
	if p.y >= FLUME_Y0 and p.y <= FLUME_Y1 and p.x > PATH_L and p.x < PATH_R:
		return Surfaces.S.PAVEMENT
	# selva packed earth — mud (drawn as dark earth)
	if p.y <= SELVA_Y0 and p.y >= SELVA_Y1 and p.x > PATH_L and p.x < PATH_R:
		return Surfaces.S.MUD
	# canyon boardwalk
	if p.y <= CANYON_Y0 and p.y >= CANYON_Y1 and p.x > PATH_L and p.x < PATH_R:
		return Surfaces.S.PAVEMENT
	# canyon dust verge
	if p.y <= CANYON_Y0 and p.y >= CANYON_Y1 and (p.x < PATH_L or p.x > PATH_R):
		return Surfaces.S.SAND
	# verge
	if p.x < PATH_L or p.x > PATH_R:
		if p.y <= SELVA_Y0 and p.y >= SELVA_Y1:
			return Surfaces.S.MUD
		if p.y <= CORSARI_Y0 and p.y >= CORSARI_Y1:
			return Surfaces.S.PAVEMENT
		# the gates' plaza and Plaça del Loop are paved out to their fronts
		if p.y > CORSARI_Y0 or (p.y <= LOOP_Y0 and p.y >= LOOP_Y1):
			return Surfaces.S.PAVEMENT
		return Surfaces.S.GRASS
	return Surfaces.S.PAVEMENT


static func draw_bollard(m: Node2D, wc: ShapeBatch, h) -> void:
	var hp: Vector2 = h.pos
	m.cast_shadow(wc, hp, 8.0, 20.0)
	wc.circle(hp, 11.0, STEEL_DARK)
	if h.done:
		wc.circle(hp + Vector2(3.0, 4.0), 9.0, Color(0.96, 0.86, 0.30, 0.7))
	wc.circle(hp, 7.0, STEEL)
	wc.circle(hp, 4.0, SAFFRON)
	if not h.done and h.progress > 0.0:
		wc.draw_arc(hp, 18.0, -PI / 2.0, -PI / 2.0 + TAU * h.progress / 0.8, 20, Color(1, 0.95, 0.7), 3.0)


static func draw_snack(m: Node2D, wc: ShapeBatch, kp: Vector2) -> void:
	m.contact_shadow(wc, kp, 12.0, 3.0, 0.20)
	var kind := int(_h(kp.x * 0.1 + kp.y * 0.01) * 3.0)
	if kind == 0:
		wc.rect(Rect2(kp.x - 8.0, kp.y - 6.0, 16.0, 14.0), Color(0.92, 0.30, 0.28))
		wc.circle(kp + Vector2(-3.0, -8.0), 3.0, Color(0.98, 0.94, 0.80))
		wc.circle(kp + Vector2(3.0, -9.0), 3.0, Color(0.98, 0.94, 0.80))
	elif kind == 1:
		wc.capsule(kp + Vector2(-10.0, 0.0), kp + Vector2(10.0, -2.0), 3.5, Color(0.78, 0.52, 0.22))
		wc.capsule(kp + Vector2(-8.0, 0.0), kp + Vector2(8.0, -1.5), 1.8, Color(0.92, 0.72, 0.36))
	else:
		wc.circle(kp, 7.0, Color(0.95, 0.55, 0.70))
		wc.circle(kp + Vector2(-2.0, -2.0), 2.0, Color(1.0, 1.0, 1.0, 0.5))
