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
	"name_place", "on_bark", "surface", "tick", "tree_kind"]

const Surfaces := preload("res://world/surfaces.gd")
const ShapeBatch := preload("res://systems/shape_batch.gd")
const EventFeed := preload("res://hud/event_feed.gd")
const AnimClock := preload("res://systems/anim_clock.gd")
const NearMiss := preload("res://systems/near_miss.gd")
const Panot := preload("res://world/panot.gd")
const Outdoors := preload("res://systems/outdoors.gd")

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
	Vector2(560.0, 40.0), Vector2(640.0, 40.0), Vector2(720.0, 40.0),
]

# Cala del Corsari — harbour pool off the west edge of the path
const HARBOUR := Rect2(PATH_L - 210.0, -1140.0, 190.0, 180.0)
const SHIP := Vector2(PATH_L - 115.0, -1050.0)
const SHIP_PIVOT := Vector2(PATH_L - 115.0, -1150.0)
const VILLAGE_FRONTS: Array[float] = [
	-460.0, -540.0, -620.0, -700.0, -780.0, -860.0,
	-940.0, -1020.0, -1100.0, -1180.0, -1260.0, -1340.0,
]

# Canyon del Sol
const SALOON := Rect2(PATH_R - 100.0, -1720.0, 90.0, 80.0)
const MINE_YS: Array[float] = [-1520.0, -1720.0, -1920.0, -2120.0, -2280.0]
const WEST_FRONTS: Array[float] = [
	-1460.0, -1540.0, -1620.0, -1700.0, -1780.0,
	-1860.0, -1940.0, -2020.0, -2100.0, -2180.0, -2260.0, -2340.0,
]

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

# Plaça del Loop
const LIFT_HILL := Vector2(PATH_R - 40.0, -3820.0)
const LOOP_C := Vector2(CX + 60.0, -4020.0)
const LOOP_R := 100.0
const COASTER_SPEED := 110.0

# picnic finish
const PICNIC_TABLES: Array[Rect2] = [
	Rect2(420.0, -4620.0, 88.0, 40.0),
	Rect2(760.0, -4620.0, 88.0, 40.0),
]
const PRIZE := Vector2(640.0, -4680.0)
const PRIZE_TEXT := "snatch the churro off the picnic grill"

# queue rope posts the leash wraps (and she marks) — zig-zag mazes
const QUEUE_POSTS: Array[Vector2] = [
	Vector2(500.0, -450.0), Vector2(620.0, -450.0), Vector2(740.0, -450.0),
	Vector2(520.0, -520.0), Vector2(760.0, -520.0),
	Vector2(500.0, -1550.0), Vector2(620.0, -1550.0), Vector2(780.0, -1550.0),
	Vector2(520.0, -1620.0), Vector2(760.0, -1620.0),
	Vector2(500.0, -2550.0), Vector2(640.0, -2550.0), Vector2(780.0, -2550.0),
	Vector2(520.0, -2620.0), Vector2(760.0, -2620.0),
	Vector2(520.0, -3550.0), Vector2(640.0, -3550.0), Vector2(760.0, -3550.0),
]
const POST_R := 10.0

# palms and jungle trees (poles + crowns)
const PALMS: Array[Vector2] = [
	Vector2(470.0, -600.0), Vector2(820.0, -900.0),
	Vector2(480.0, -2100.0), Vector2(810.0, -2700.0),
	Vector2(500.0, -3200.0), Vector2(790.0, -4100.0),
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
	m.deco_pole_count = m.poles.size()
	var marks: Array[Vector2] = [
		QUEUE_POSTS[0], QUEUE_POSTS[2], QUEUE_POSTS[5], QUEUE_POSTS[7],
		QUEUE_POSTS[10], QUEUE_POSTS[15], Vector2(PATH_L + 30.0, -1900.0),
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

static func _h(n: float) -> float:
	return fposmod(sin(n * 12.9898 + 4.1) * 43758.5453, 1.0)


static func draw_edge_layer(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	var top: float = maxf(vt, m.GATE_Y - 40.0)
	var bot: float = minf(vb, float(m.START_Y) + 560.0)
	if bot <= top:
		return
	var was := b.lod
	b.lod = true
	_edge_corsari(b, top, bot)
	_edge_canyon(b, top, bot)
	_edge_selva(b, top, bot)
	_edge_loop(b, top, bot)
	_edge_picnic(b, top, bot)
	_edge_gates(b, top, bot)
	b.lod = was


static func _edge_gates(b: ShapeBatch, top: float, bot: float) -> void:
	if bot < -400.0 or top > 200.0:
		return
	var lo := maxf(top, -400.0)
	var hi := minf(bot, 200.0)
	if hi <= lo:
		return
	# entry plaza paving either side, then kiosk fronts — never a hedge strip
	b.rect(Rect2(-460.0, lo, PATH_L + 460.0, hi - lo), PAVEMENT_LIT)
	b.rect(Rect2(PATH_R, lo, 1740.0 - PATH_R, hi - lo), PAVEMENT_LIT)
	var y := floorf(lo / 110.0) * 110.0
	var i := 0
	while y < hi:
		var seed_n := _h(float(i) * 5.0)
		# left kiosk / gift-shop front with awning
		var left := Rect2(PATH_L - 170.0 - seed_n * 30.0, y + 6.0, 150.0, 96.0)
		b.rect(Rect2(left.position + Vector2(8.0, 10.0), left.size), SHADOW)
		b.rect(left, MAGENTA.darkened(0.18) if i % 2 == 0 else TURQ.darkened(0.15))
		b.rect(left.grow(-8.0), MAGENTA if i % 2 == 0 else TURQ)
		b.rect(Rect2(left.position.x - 8.0, left.position.y - 16.0, left.size.x + 16.0, 20.0), SAFFRON)
		b.rect(Rect2(left.position.x + 18.0, left.position.y + 28.0, 36.0, 28.0), Color(0.70, 0.88, 0.95))
		b.rect(Rect2(left.position.x + 70.0, left.position.y + 40.0, 22.0, 36.0), Color(0.30, 0.18, 0.14))
		# flower planter strip between kiosk and path
		b.rect(Rect2(PATH_L - 22.0, y + 16.0, 16.0, 76.0), GRASS)
		for j in range(3):
			b.coarse(Vector2(PATH_L - 14.0, y + 28.0 + float(j) * 22.0), 6.0,
				MAGENTA if j % 2 == 0 else SAFFRON)
		# right souvenir arcade
		var right := Rect2(PATH_R + 18.0, y + 10.0, 140.0 + seed_n * 40.0, 90.0)
		b.rect(Rect2(right.position + Vector2(8.0, 10.0), right.size), SHADOW)
		b.rect(right, STEEL_DARK)
		b.rect(right.grow(-8.0), STEEL)
		b.rect(Rect2(right.position.x - 6.0, right.position.y - 14.0, right.size.x + 12.0, 18.0), MAGENTA)
		b.rect(Rect2(PATH_R + 4.0, y + 16.0, 12.0, 76.0), GRASS)
		for j in range(3):
			b.coarse(Vector2(PATH_R + 10.0, y + 28.0 + float(j) * 22.0), 6.0,
				TURQ if j % 2 == 0 else SAFFRON)
		# rail posts along the kerb
		b.rect(Rect2(PATH_L - 8.0, y + 8.0, 5.0, 88.0), STEEL_DARK)
		b.rect(Rect2(PATH_R + 3.0, y + 8.0, 5.0, 88.0), STEEL_DARK)
		y += 110.0
		i += 1
	# ticket-office block behind the booth (a little building, not a flat box)
	if BOOTH.end.y > top and BOOTH.position.y < bot:
		var roof := Rect2(PATH_L - 50.0, BOOTH.position.y - 28.0, 150.0, 100.0)
		b.rect(Rect2(roof.position + Vector2(10.0, 12.0), roof.size), SHADOW)
		b.rect(roof, MAGENTA.darkened(0.28))
		b.rect(roof.grow(-10.0), SAFFRON)
		b.rect(Rect2(roof.position.x + 20.0, roof.position.y + 24.0, 40.0, 28.0), Color(0.70, 0.88, 0.95))
		b.rect(Rect2(roof.position.x + 80.0, roof.position.y + 40.0, 28.0, 40.0), Color(0.30, 0.18, 0.14))


static func _edge_corsari(b: ShapeBatch, top: float, bot: float) -> void:
	var lo := maxf(top, CORSARI_Y1)
	var hi := minf(bot, CORSARI_Y0)
	if hi <= lo:
		return
	# whitewashed village ground either side
	b.rect(Rect2(-460.0, lo, PATH_L + 460.0, hi - lo), WHITE_SHADE)
	b.rect(Rect2(PATH_R, lo, 1740.0 - PATH_R, hi - lo), WHITE_SHADE)
	for fy: float in VILLAGE_FRONTS:
		if fy < top - 100.0 or fy > bot + 100.0:
			continue
		_village_house(b, Vector2(PATH_L - 120.0, fy), -1.0, _h(fy))
		_village_house(b, Vector2(PATH_R + 120.0, fy - 70.0), 1.0, _h(fy + 3.0))
	# harbour stone apron around the pool
	if HARBOUR.end.y > top and HARBOUR.position.y < bot:
		var apron := HARBOUR.grow(28.0)
		b.rect(apron, STONE)
		b.rect(apron.grow(-8.0), SETT_DARK)


static func _village_house(b: ShapeBatch, p: Vector2, side: float, seed_n: float) -> void:
	# depth like Sitges: terrace parapet, barrel-tile roof, shutters, chimney
	var w := 96.0 + seed_n * 28.0
	var h := 78.0 + seed_n * 22.0
	var r := Rect2(p.x - w * 0.5, p.y - h * 0.5, w, h)
	b.rect(Rect2(r.position + Vector2(9.0, 11.0), r.size), SHADOW)
	b.rect(r, WHITEWASH)
	b.rect(r.grow(-4.0), WHITE_SHADE.lightened(0.04))
	# pitched terracotta roof with light/shade flutes
	var roof := Rect2(r.position.x - 8.0, r.position.y - 22.0, r.size.x + 16.0, 26.0)
	b.rect(roof, TERRACOTTA)
	b.rect(Rect2(roof.position.x, roof.position.y, roof.size.x * 0.5, roof.size.y), TERRACOTTA_LIT)
	b.line(Vector2(roof.get_center().x, roof.position.y + 2.0), Vector2(roof.get_center().x, roof.end.y - 2.0), TERRACOTTA.darkened(0.22), 3.0)
	for rx in range(4):
		var lx := roof.position.x + 10.0 + float(rx) * (roof.size.x / 4.5)
		b.rect(Rect2(lx, roof.position.y + 2.0, 5.0, roof.size.y - 4.0), TERRACOTTA_LIT.lightened(0.06))
	# whitewash parapet on the path face
	b.rect(Rect2(r.position.x - 4.0 * side, r.position.y + 4.0, 8.0, h - 8.0), WHITEWASH)
	b.rect(Rect2(r.position.x - 8.0 * side, r.position.y + 8.0, 5.0, h - 16.0), SHADOW)
	# door + cobalt shutters
	b.rect(Rect2(r.position.x + w * 0.38, r.position.y + h * 0.38, 16.0, 30.0), Color(0.42, 0.28, 0.18))
	b.rect(Rect2(r.position.x + 12.0, r.position.y + 16.0, 16.0, 20.0), SHUTTER)
	b.rect(Rect2(r.position.x + 12.0, r.position.y + 16.0, 7.0, 9.0), SHUTTER.lightened(0.12))
	b.rect(Rect2(r.position.x + 12.0, r.position.y + 27.0, 7.0, 9.0), SHUTTER.lightened(0.12))
	# chimney + laundry line
	b.rect(Rect2(r.position.x + w * 0.68, r.position.y - 34.0, 14.0, 18.0), WHITE_SHADE)
	b.circle(p + Vector2(side * 12.0, -10.0), 4.0, Color(0.70, 0.78, 0.86))
	if seed_n > 0.45:
		b.line(r.position + Vector2(8.0, 8.0), r.position + Vector2(w - 8.0, 6.0), Color(0.85, 0.85, 0.88), 1.2)
		b.rect(Rect2(r.position.x + w * 0.2, r.position.y + 2.0, 14.0, 10.0), Color(0.92, 0.55, 0.55, 0.85))


static func _edge_canyon(b: ShapeBatch, top: float, bot: float) -> void:
	var lo := maxf(top, CANYON_Y1)
	var hi := minf(bot, CANYON_Y0)
	if hi <= lo:
		return
	# red dust and rock either side of the boardwalk
	b.rect(Rect2(-460.0, lo, PATH_L + 460.0, hi - lo), DUST)
	b.rect(Rect2(PATH_R, lo, 1740.0 - PATH_R, hi - lo), DUST)
	var y := floorf(lo / 36.0) * 36.0
	while y < hi:
		b.coarse(Vector2(PATH_L - 50.0 - _h(y) * 100.0, y + 12.0), 20.0 + _h(y + 1.0) * 16.0, DUST_LIT)
		b.coarse(Vector2(PATH_R + 50.0 + _h(y + 2.0) * 100.0, y + 16.0), 18.0 + _h(y + 3.0) * 14.0, DUST.darkened(0.12))
		# rock shelves
		b.polygon(PackedVector2Array([
			Vector2(PATH_L - 20.0 - _h(y) * 40.0, y),
			Vector2(PATH_L - 70.0 - _h(y + 1.0) * 50.0, y + 10.0),
			Vector2(PATH_L - 30.0, y + 22.0),
		]), DUST.darkened(0.18))
		y += 36.0
	# false-front saloon row on BOTH sides
	for fy: float in WEST_FRONTS:
		if fy < top - 80.0 or fy > bot + 80.0:
			continue
		_saloon_front(b, Vector2(PATH_R + 78.0, fy), _h(fy))
		_saloon_front(b, Vector2(PATH_L - 78.0, fy - 40.0), _h(fy + 2.0))
	if SALOON.end.y > top and SALOON.position.y < bot:
		_saloon_front(b, SALOON.get_center(), 0.4)


static func _saloon_front(b: ShapeBatch, p: Vector2, seed_n: float) -> void:
	var w := 96.0 + seed_n * 20.0
	var h := 78.0
	var r := Rect2(p.x - w * 0.5, p.y - h * 0.5, w, h)
	b.rect(Rect2(r.position + Vector2(8.0, 10.0), r.size), SHADOW)
	b.rect(r, WOOD_DARK)
	b.rect(r.grow(-5.0), WOOD)
	# false-front peak
	var peak := PackedVector2Array([
		Vector2(r.position.x - 4.0, r.position.y),
		Vector2(r.get_center().x, r.position.y - 28.0 - seed_n * 10.0),
		Vector2(r.end.x + 4.0, r.position.y),
	])
	b.polygon(peak, WOOD_DARK)
	b.polygon(PackedVector2Array([
		peak[0] + Vector2(6.0, 0.0), peak[1] + Vector2(0.0, 6.0), peak[2] + Vector2(-6.0, 0.0),
	]), WOOD)
	# swinging doors + porch posts
	b.rect(Rect2(r.position.x + w * 0.35, r.position.y + h * 0.4, 12.0, 30.0), WOOD_DARK)
	b.rect(Rect2(r.position.x + w * 0.52, r.position.y + h * 0.4, 12.0, 30.0), WOOD_DARK)
	b.rect(Rect2(r.position.x + 8.0, r.position.y + 10.0, 8.0, h - 16.0), WOOD_LIT)
	b.rect(Rect2(r.end.x - 16.0, r.position.y + 10.0, 8.0, h - 16.0), WOOD_LIT)


static func _edge_selva(b: ShapeBatch, top: float, bot: float) -> void:
	var lo := maxf(top, SELVA_Y1)
	var hi := minf(bot, SELVA_Y0)
	if hi <= lo:
		return
	b.rect(Rect2(-460.0, lo, PATH_L + 460.0, hi - lo), EARTH)
	b.rect(Rect2(PATH_R, lo, 1740.0 - PATH_R, hi - lo), EARTH)
	var y := floorf(lo / 28.0) * 28.0
	while y < hi:
		# continuous big-leaved wall of planting, not sparse bushes
		for k in range(3):
			var lx := PATH_L - 30.0 - float(k) * 55.0 - _h(y + float(k)) * 40.0
			var rx := PATH_R + 30.0 + float(k) * 55.0 + _h(y + float(k) + 2.0) * 40.0
			var rr := 18.0 + _h(y + float(k) * 3.0) * 14.0
			b.coarse(Vector2(lx, y + 8.0 + float(k) * 4.0), rr, JUNGLE if k % 2 == 0 else JUNGLE_LIT)
			b.coarse(Vector2(rx, y + 10.0 + float(k) * 3.0), rr + 2.0, JUNGLE_LIT if k % 2 == 0 else JUNGLE)
		# root knuckles and fallen logs along the verge
		b.capsule(Vector2(PATH_L - 8.0, y), Vector2(PATH_L + 22.0, y + 12.0), 3.5, EARTH_LIT)
		b.capsule(Vector2(PATH_R + 8.0, y + 4.0), Vector2(PATH_R - 20.0, y + 16.0), 3.5, EARTH_LIT)
		if int(absf(y) / 28.0) % 5 == 0:
			b.capsule(Vector2(PATH_L - 40.0, y + 6.0), Vector2(PATH_L - 10.0, y + 14.0), 5.0, WOOD_DARK)
		y += 28.0


static func _edge_loop(b: ShapeBatch, top: float, bot: float) -> void:
	var lo := maxf(top, LOOP_Y1)
	var hi := minf(bot, LOOP_Y0)
	if hi <= lo:
		return
	b.rect(Rect2(-460.0, lo, PATH_L + 460.0, hi - lo), PAVEMENT_LIT)
	b.rect(Rect2(PATH_R, lo, 1740.0 - PATH_R, hi - lo), PAVEMENT_LIT)
	# coaster station sheds and queue canopies along both sides
	var y := floorf(lo / 140.0) * 140.0
	var i := 0
	while y < hi:
		var seed_n := _h(float(i) * 7.0)
		var left := Rect2(PATH_L - 160.0 - seed_n * 40.0, y + 8.0, 140.0, 110.0)
		var right := Rect2(PATH_R + 20.0, y + 12.0, 130.0 + seed_n * 30.0, 100.0)
		b.rect(Rect2(left.position + Vector2(8.0, 10.0), left.size), SHADOW)
		b.rect(left, STEEL_DARK)
		b.rect(left.grow(-8.0), MAGENTA.darkened(0.1) if i % 2 == 0 else TURQ.darkened(0.1))
		b.rect(Rect2(left.position.x - 6.0, left.position.y - 14.0, left.size.x + 12.0, 18.0), SAFFRON)
		b.rect(Rect2(right.position + Vector2(8.0, 10.0), right.size), SHADOW)
		b.rect(right, STEEL_DARK)
		b.rect(right.grow(-8.0), STEEL)
		b.rect(Rect2(right.position.x - 6.0, right.position.y - 14.0, right.size.x + 12.0, 18.0), MAGENTA)
		y += 140.0
		i += 1


static func _edge_picnic(b: ShapeBatch, top: float, bot: float) -> void:
	var lo := maxf(top, -5100.0)
	var hi := minf(bot, PICNIC_Y)
	if hi <= lo:
		return
	b.rect(Rect2(-460.0, lo, 2200.0, hi - lo), GRASS)
	var y := floorf(lo / 50.0) * 50.0
	while y < hi:
		b.coarse(Vector2(200.0 + _h(y) * 200.0, y + 12.0), 14.0, GRASS_LIT)
		b.coarse(Vector2(1100.0 + _h(y + 1.0) * 200.0, y + 16.0), 16.0, GRASS.darkened(0.08))
		y += 50.0


static func draw_cross_section(m: Node2D, wc: ShapeBatch, _top: float, _bottom: float, ctop: float, vt: float, vb: float) -> void:
	var lo: float = maxf(vt - 60.0, ctop)
	var hi: float = minf(vb + 60.0, float(m.START_Y) + 560.0)
	if hi <= lo:
		return
	var was := wc.lod
	wc.lod = true
	_draw_path(wc, lo, hi)
	_draw_gates(wc, lo, hi)
	_draw_corsari(wc, lo, hi)
	_draw_canyon(wc, lo, hi)
	_draw_selva(wc, lo, hi)
	_draw_loop_plaza(wc, lo, hi)
	_draw_picnic(wc, lo, hi)
	_draw_queues(wc, lo, hi)
	_draw_carts(wc, lo, hi)
	_draw_crowd(wc, lo, hi)
	wc.lod = was


static func _draw_path(wc: ShapeBatch, lo: float, hi: float) -> void:
	wc.rect(Rect2(PATH_L, lo, PATH_R - PATH_L, hi - lo), PAVEMENT)
	# gates + loop plaza: panot
	for band in [[GATE_BAND + 400.0, CORSARI_Y0], [LOOP_Y0, LOOP_Y1]]:
		var a: float = maxf(lo, float(band[1]))
		var z: float = minf(hi, float(band[0]))
		if z > a:
			Panot.flor(wc, PATH_L, PATH_R, a, z, Color(0.10, 0.08, 0.06, 0.10), Color(1.0, 0.98, 0.94, 0.08))
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
	# Canyon: timber boardwalk + dust shoulders
	var bw0 := maxf(lo, CANYON_Y1)
	var bw1 := minf(hi, CANYON_Y0)
	if bw1 > bw0:
		wc.rect(Rect2(PATH_L, bw0, PATH_R - PATH_L, bw1 - bw0), WOOD_LIT)
		var y := floorf(bw0 / 14.0) * 14.0
		while y < bw1:
			wc.rect(Rect2(PATH_L, y, PATH_R - PATH_L, 1.6), WOOD_DARK)
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
			sy2 += 28.0
	# flume walkway bridge planks through the splash band (not water)
	var f0 := maxf(lo, FLUME_Y0)
	var f1 := minf(hi, FLUME_Y1)
	if f1 > f0:
		wc.rect(Rect2(PATH_L, f0, PATH_R - PATH_L, f1 - f0), WOOD_LIT.lightened(0.08))
		var fy := floorf(f0 / 12.0) * 12.0
		while fy < f1:
			wc.rect(Rect2(PATH_L, fy, PATH_R - PATH_L, 1.4), WOOD_DARK)
			fy += 12.0
		# rail along the pool side
		wc.rect(Rect2(PATH_R - 8.0, f0, 6.0, f1 - f0), STEEL_DARK)
	# picnic lawn
	var g0 := maxf(lo, -5000.0)
	var g1 := minf(hi, PICNIC_Y)
	if g1 > g0:
		wc.rect(Rect2(PATH_L, g0, PATH_R - PATH_L, g1 - g0), GRASS)
		var gy := floorf(g0 / 40.0) * 40.0
		while gy < g1:
			wc.coarse(Vector2(CX + (_h(gy * 0.1) - 0.5) * 200.0, gy + 10.0), 10.0, GRASS_LIT)
			gy += 40.0


static func _draw_gates(wc: ShapeBatch, lo: float, hi: float) -> void:
	if hi < -220.0 or lo > 140.0:
		return
	for t: Vector2 in TURNSTILES:
		if t.y < lo - 40.0 or t.y > hi + 40.0:
			continue
		wc.rect(Rect2(t.x - 18.0 + 4.0, t.y - 10.0 + 4.0, 36.0, 20.0), SHADOW)
		wc.rect(Rect2(t.x - 18.0, t.y - 10.0, 36.0, 20.0), STEEL_DARK)
		wc.rect(Rect2(t.x - 14.0, t.y - 6.0, 28.0, 12.0), STEEL)
		wc.line(t + Vector2(-10.0, 0.0), t + Vector2(10.0, 0.0), SAFFRON, 2.0)
	# ticket booth as a little building
	if BOOTH.end.y > lo and BOOTH.position.y < hi:
		wc.rect(Rect2(BOOTH.position + Vector2(8.0, 10.0), BOOTH.size), SHADOW)
		wc.rect(BOOTH, MAGENTA.darkened(0.18))
		wc.rect(BOOTH.grow(-5.0), MAGENTA)
		wc.rect(Rect2(BOOTH.position.x - 8.0, BOOTH.position.y - 18.0, BOOTH.size.x + 16.0, 20.0), SAFFRON)
		wc.rect(Rect2(BOOTH.position.x - 4.0, BOOTH.position.y - 14.0, BOOTH.size.x + 8.0, 12.0), TURQ)
		wc.rect(Rect2(BOOTH.position.x + 14.0, BOOTH.position.y + 14.0, 36.0, 22.0), Color(0.70, 0.88, 0.95))
		wc.rect(Rect2(BOOTH.position.x + 18.0, BOOTH.position.y + 40.0, 22.0, 18.0), Color(0.30, 0.18, 0.14))
		wc.circle(BOOTH.position + Vector2(58.0, 22.0), 4.0, SAFFRON)
	# welcome arch with depth and lettered lintel
	if ARCH.y > lo - 100.0 and ARCH.y < hi + 100.0:
		_welcome_arch(wc)
	# fountain
	if FOUNTAIN.y > lo - 40.0 and FOUNTAIN.y < hi + 40.0:
		wc.circle(FOUNTAIN + Shade.light * 16.0, 36.0, SHADOW)
		wc.circle(FOUNTAIN, 34.0, STEEL)
		wc.glow(FOUNTAIN, 40.0, Color(WATER, 0.5), 0.45)
		wc.circle(FOUNTAIN, 24.0, WATER_DEEP)
		wc.circle(FOUNTAIN - Shade.light * 4.0, 12.0, Color(1.0, 1.0, 1.0, 0.35))
		wc.circle(FOUNTAIN, 7.0, STEEL_DARK)
		wc.glow(FOUNTAIN + Vector2(0.0, -18.0), 10.0, Color(1.0, 1.0, 1.0, 0.4), 0.3)


static func _welcome_arch(wc: ShapeBatch) -> void:
	var left := Vector2(ARCH.x - 160.0, ARCH.y)
	var right := Vector2(ARCH.x + 160.0, ARCH.y)
	# deep piers with stepped bases and capitals
	for pier: Vector2 in [left, right]:
		wc.rect(Rect2(pier.x - 28.0 + 10.0, pier.y - 14.0 + 12.0, 56.0, 86.0), SHADOW)
		wc.rect(Rect2(pier.x - 28.0, pier.y + 50.0, 56.0, 18.0), TURQ.darkened(0.3))
		wc.rect(Rect2(pier.x - 24.0, pier.y - 14.0, 48.0, 78.0), TURQ.darkened(0.18))
		wc.rect(Rect2(pier.x - 18.0, pier.y - 8.0, 36.0, 64.0), TURQ)
		wc.rect(Rect2(pier.x - 12.0, pier.y + 4.0, 24.0, 40.0), TURQ.lightened(0.14))
		wc.rect(Rect2(pier.x - 30.0, pier.y - 22.0, 60.0, 14.0), SAFFRON)
	# deep lintel with park name on two ranks of letter blocks
	wc.rect(Rect2(ARCH.x - 190.0 + 10.0, ARCH.y - 72.0 + 10.0, 380.0, 56.0), SHADOW)
	wc.rect(Rect2(ARCH.x - 190.0, ARCH.y - 72.0, 380.0, 56.0), SAFFRON)
	wc.rect(Rect2(ARCH.x - 178.0, ARCH.y - 64.0, 356.0, 40.0), MAGENTA)
	# LES
	var les := "LES"
	for i in range(les.length()):
		var cx := ARCH.x - 70.0 + float(i) * 28.0
		wc.rect(Rect2(cx - 8.0, ARCH.y - 58.0, 16.0, 12.0), SAFFRON)
	# ATRACCIONS
	var atr := "ATRACCIONS"
	var aw := 300.0
	var ax0 := ARCH.x - aw * 0.5
	for i in range(atr.length()):
		var cx2 := ax0 + (float(i) + 0.5) / float(atr.length()) * aw
		wc.rect(Rect2(cx2 - 7.0, ARCH.y - 42.0, 14.0, 14.0), SAFFRON)
	# keystone jewel and hanging lanterns
	wc.circle(ARCH + Vector2(0.0, -72.0), 12.0, TURQ)
	wc.circle(ARCH + Vector2(0.0, -72.0), 6.0, SAFFRON)
	wc.glow(left + Vector2(0.0, -30.0), 14.0, Color(1.0, 0.90, 0.55, 0.35), 0.35)
	wc.glow(right + Vector2(0.0, -30.0), 14.0, Color(1.0, 0.90, 0.55, 0.35), 0.35)


static func _draw_corsari(wc: ShapeBatch, lo: float, hi: float) -> void:
	if HARBOUR.end.y >= lo and HARBOUR.position.y <= hi:
		# soft harbour water (gradient, not a flat disc stack)
		var hc := HARBOUR.get_center()
		wc.circle(hc + Shade.light * 18.0, 88.0, SHADOW)
		wc.glow(hc, 100.0, Color(WATER_DEEP, 0.55), 0.35)
		wc.glow(hc + Vector2(-10.0, -8.0), 70.0, Color(WATER, 0.55), 0.4)
		wc.band(PackedVector2Array([
			HARBOUR.position, Vector2(HARBOUR.end.x, HARBOUR.position.y),
			HARBOUR.position + Vector2(12.0, 40.0), Vector2(HARBOUR.end.x - 12.0, HARBOUR.position.y + 40.0),
			HARBOUR.position + Vector2(24.0, 90.0), Vector2(HARBOUR.end.x - 24.0, HARBOUR.position.y + 90.0),
			Vector2(HARBOUR.position.x + 36.0, HARBOUR.end.y), Vector2(HARBOUR.end.x - 36.0, HARBOUR.end.y),
		]), 2, WATER_SOFT, PackedFloat32Array([0.85, 0.65, 0.4, 0.15]))
		# stone coping
		wc.rect(Rect2(HARBOUR.position.x - 6.0, HARBOUR.position.y - 6.0, HARBOUR.size.x + 12.0, 10.0), STONE)
		wc.rect(Rect2(HARBOUR.position.x - 6.0, HARBOUR.end.y - 4.0, HARBOUR.size.x + 12.0, 10.0), STONE)
	# pirate ship on a swinging frame
	if SHIP.y > lo - 80.0 and SHIP.y < hi + 80.0:
		_pirate_ship(wc)


static func _pirate_ship(wc: ShapeBatch) -> void:
	var swing := sin(float(AnimClock.msec()) * 0.0020) * 0.38
	var tip := SHIP_PIVOT + Vector2(sin(swing) * 70.0, cos(swing) * 70.0)
	# A-frame with thick posts and a cross-brace
	wc.rect(Rect2(SHIP_PIVOT.x - 62.0 + 6.0, SHIP_PIVOT.y + 4.0 + 6.0, 124.0, 14.0), SHADOW)
	wc.rect(Rect2(SHIP_PIVOT.x - 62.0, SHIP_PIVOT.y + 4.0, 124.0, 14.0), STEEL_DARK)
	wc.line(SHIP_PIVOT + Vector2(-58.0, 10.0), SHIP_PIVOT + Vector2(0.0, -78.0), STEEL_DARK, 8.0)
	wc.line(SHIP_PIVOT + Vector2(58.0, 10.0), SHIP_PIVOT + Vector2(0.0, -78.0), STEEL_DARK, 8.0)
	wc.line(SHIP_PIVOT + Vector2(-58.0, 10.0), SHIP_PIVOT + Vector2(0.0, -78.0), STEEL, 4.0)
	wc.line(SHIP_PIVOT + Vector2(58.0, 10.0), SHIP_PIVOT + Vector2(0.0, -78.0), STEEL, 4.0)
	wc.line(SHIP_PIVOT + Vector2(-40.0, -20.0), SHIP_PIVOT + Vector2(40.0, -20.0), STEEL, 3.0)
	wc.circle(SHIP_PIVOT + Vector2(0.0, -78.0), 9.0, STEEL_DARK)
	wc.circle(SHIP_PIVOT + Vector2(0.0, -78.0), 5.0, STEEL)
	# hangers
	wc.line(SHIP_PIVOT + Vector2(0.0, -78.0), tip, STEEL_DARK, 4.0)
	wc.line(SHIP_PIVOT + Vector2(0.0, -78.0), tip, STEEL, 2.0)
	# hull + shadow (reads as a boat from above)
	wc.circle(tip + Shade.light * 18.0, 42.0, SHADOW)
	var left := tip + Vector2.from_angle(swing + PI) * 48.0
	var right := tip + Vector2.from_angle(swing) * 48.0
	wc.capsule(left, right, 18.0, WOOD_DARK)
	wc.capsule(left + Vector2(0.0, -5.0), right + Vector2(0.0, -5.0), 13.0, WOOD)
	wc.capsule(left + Vector2(0.0, -9.0), right + Vector2(0.0, -9.0), 7.0, WOOD_LIT)
	# mast + sail
	var mast := tip + Vector2.from_angle(swing - PI * 0.5) * 42.0
	wc.line(tip, mast, WOOD_DARK, 4.0)
	wc.quad(mast, mast + Vector2.from_angle(swing) * 26.0,
		mast + Vector2.from_angle(swing) * 20.0 + Vector2.from_angle(swing - PI * 0.5) * 12.0,
		mast + Vector2.from_angle(swing - PI * 0.5) * 14.0, Color(0.86, 0.18, 0.20))
	# riders in the hull
	for i in range(4):
		var f := (float(i) - 1.5) * 0.28
		var rp := tip + Vector2.from_angle(swing) * f * 34.0 + Vector2.from_angle(swing - PI * 0.5) * 10.0
		wc.circle(rp, 5.5, Color(0.86, 0.68, 0.52))
		wc.circle(rp + Vector2(0.0, 8.0), 6.5, Color(0.30 + _h(float(i)) * 0.4, 0.45, 0.70))


static func _draw_canyon(wc: ShapeBatch, lo: float, hi: float) -> void:
	for i in range(5):
		var p := Vector2(PATH_L + 36.0 + float(i % 2) * (PATH_R - PATH_L - 72.0), -1580.0 - float(i) * 140.0)
		if p.y < lo - 30.0 or p.y > hi + 30.0:
			continue
		wc.circle(p + Shade.light * 10.0, 14.0, SHADOW)
		wc.circle(p, 12.0, WOOD_DARK)
		wc.circle(p, 9.0, WOOD)
		wc.circle(p - Shade.light * 2.0, 3.0, WOOD_LIT)


static func _draw_selva(wc: ShapeBatch, lo: float, hi: float) -> void:
	# splash pool beside the path (east) — soft water
	if FLUME_POOL.end.y >= lo and FLUME_POOL.position.y <= hi:
		var pc := FLUME_POOL.get_center()
		wc.circle(pc + Shade.light * 20.0, 95.0, SHADOW)
		wc.glow(pc, 110.0, Color(WATER_DEEP, 0.5), 0.35)
		wc.glow(pc + Vector2(-8.0, -6.0), 72.0, Color(WATER, 0.55), 0.4)
		wc.band(PackedVector2Array([
			FLUME_POOL.position, Vector2(FLUME_POOL.end.x, FLUME_POOL.position.y),
			FLUME_POOL.position + Vector2(14.0, 45.0), Vector2(FLUME_POOL.end.x - 14.0, FLUME_POOL.position.y + 45.0),
			FLUME_POOL.position + Vector2(28.0, 100.0), Vector2(FLUME_POOL.end.x - 28.0, FLUME_POOL.position.y + 100.0),
			Vector2(FLUME_POOL.position.x + 40.0, FLUME_POOL.end.y), Vector2(FLUME_POOL.end.x - 40.0, FLUME_POOL.end.y),
		]), 2, WATER_SOFT, PackedFloat32Array([0.9, 0.7, 0.4, 0.15]))
		# pool coping
		wc.rect(Rect2(FLUME_POOL.position.x - 8.0, FLUME_POOL.position.y - 8.0, FLUME_POOL.size.x + 16.0, 12.0), STONE)
		wc.rect(Rect2(FLUME_POOL.position.x - 8.0, FLUME_POOL.end.y - 4.0, FLUME_POOL.size.x + 16.0, 12.0), STONE)
	# flume channel from lift to drop
	var climb_top := Vector2(PATH_R - 10.0, -2680.0)
	wc.line(climb_top + Vector2(6.0, 8.0), FLUME_DROP + Vector2(6.0, 8.0), SHADOW, 14.0)
	wc.line(climb_top, FLUME_DROP, STEEL_DARK, 12.0)
	wc.line(climb_top, FLUME_DROP, STEEL, 7.0)
	wc.line(climb_top + Vector2(-8.0, 0.0), FLUME_DROP + Vector2(-8.0, 0.0), WOOD_DARK, 4.0)
	wc.line(climb_top + Vector2(8.0, 0.0), FLUME_DROP + Vector2(8.0, 0.0), WOOD_DARK, 4.0)
	wc.circle(FLUME_DROP + Shade.light * 10.0, 16.0, SHADOW)
	wc.circle(FLUME_DROP, 14.0, STEEL_DARK)
	wc.circle(FLUME_DROP, 9.0, STEEL)
	# channel into the pool
	wc.line(FLUME_DROP, FLUME_POOL.get_center() + Vector2(-40.0, -20.0), STEEL_DARK, 8.0)
	wc.line(FLUME_DROP, FLUME_POOL.get_center() + Vector2(-40.0, -20.0), STEEL, 4.0)
	# poncho crowd on the pool rim
	if Outdoors.theme_park(Game.weather, Game.hour):
		for i in range(6):
			var pp := Vector2(FLUME_POOL.position.x + 20.0 + float(i) * 28.0, FLUME_POOL.position.y - 14.0)
			if pp.y < lo - 20.0 or pp.y > hi + 20.0:
				continue
			wc.circle(pp + Shade.light * 8.0, 10.0, SHADOW)
			wc.circle(pp, 8.0, PONCHO if i % 2 == 0 else Color(0.20, 0.55, 0.70))
			wc.circle(pp + Vector2(0.0, -10.0), 5.0, Color(0.86, 0.68, 0.52))


static func _draw_loop_plaza(wc: ShapeBatch, lo: float, hi: float) -> void:
	if CAROUSEL.y > lo - 70.0 and CAROUSEL.y < hi + 70.0:
		_carousel(wc)
	if LIFT_HILL.y > lo - 40.0 and LIFT_HILL.y < hi + 40.0:
		wc.rect(Rect2(LIFT_HILL.x - 18.0 + 6.0, LIFT_HILL.y - 18.0 + 8.0, 36.0, 36.0), SHADOW)
		wc.rect(Rect2(LIFT_HILL.x - 18.0, LIFT_HILL.y - 18.0, 36.0, 36.0), STEEL_DARK)
		wc.rect(Rect2(LIFT_HILL.x - 12.0, LIFT_HILL.y - 12.0, 24.0, 24.0), STEEL)


static func _carousel(wc: ShapeBatch) -> void:
	var spin := float(AnimClock.msec()) * 0.0028
	wc.circle(CAROUSEL + Shade.light * 22.0, CAROUSEL_R + 10.0, SHADOW)
	# canopy
	wc.circle(CAROUSEL, CAROUSEL_R + 6.0, MAGENTA.darkened(0.1))
	wc.circle(CAROUSEL, CAROUSEL_R - 2.0, SAFFRON)
	for i in range(10):
		var a := spin * 0.5 + float(i) * TAU / 10.0
		var tip := CAROUSEL + Vector2.from_angle(a) * (CAROUSEL_R + 2.0)
		wc.polygon(PackedVector2Array([
			CAROUSEL, tip, CAROUSEL + Vector2.from_angle(a + TAU / 20.0) * (CAROUSEL_R + 2.0),
		]), MAGENTA if i % 2 == 0 else TURQ)
	wc.circle(CAROUSEL, 14.0, TURQ)
	wc.circle(CAROUSEL, 6.0, SAFFRON)
	# horses
	for i in range(6):
		var a := spin + float(i) * TAU / 6.0
		var bob := sin(spin * 3.0 + float(i)) * 4.0
		var hp := CAROUSEL + Vector2.from_angle(a) * (CAROUSEL_R - 24.0) + Vector2(0.0, bob)
		wc.circle(hp + Shade.light * 6.0, 9.0, SHADOW)
		wc.capsule(hp + Vector2(-8.0, 2.0), hp + Vector2(8.0, 2.0), 6.0, Color(0.92, 0.90, 0.88))
		wc.circle(hp + Vector2(6.0, -4.0), 5.0, Color(0.92, 0.90, 0.88))
		wc.circle(hp + Vector2(-4.0, 8.0), 3.0, Color(0.70, 0.30, 0.35))
		wc.circle(hp + Vector2(4.0, 8.0), 3.0, Color(0.70, 0.30, 0.35))
		wc.line(CAROUSEL, hp, STEEL, 1.5)


static func _draw_picnic(wc: ShapeBatch, lo: float, hi: float) -> void:
	for t: Rect2 in PICNIC_TABLES:
		if t.end.y < lo or t.position.y > hi:
			continue
		wc.rect(Rect2(t.position + Vector2(8.0, 10.0), t.size), SHADOW)
		wc.rect(t, WOOD_DARK)
		wc.rect(t.grow(-3.0), WOOD)
	if PRIZE.y > lo - 40.0 and PRIZE.y < hi + 40.0:
		var g := PRIZE + Vector2(0.0, -40.0)
		wc.rect(Rect2(g.x - 36.0, g.y - 12.0, 72.0, 24.0), Color(0.16, 0.16, 0.18))
		wc.glow(g, 28.0, Color(1.0, 0.46, 0.12, 0.35), 0.35)
		for i in range(3):
			wc.capsule(g + Vector2(-16.0 + float(i) * 16.0, 0.0) + Vector2(-6.0, 0.0),
				g + Vector2(-16.0 + float(i) * 16.0, 0.0) + Vector2(6.0, 0.0), 3.0, Color(0.78, 0.50, 0.22))


static func _draw_queues(wc: ShapeBatch, lo: float, hi: float) -> void:
	# maze ropes: connect posts that share a y-band
	var bands: Array = [
		[0, 1, 2], [3, 4],
		[5, 6, 7], [8, 9],
		[10, 11, 12], [13, 14],
		[15, 16, 17],
	]
	for band in bands:
		var idxs: Array = band
		for k in range(idxs.size() - 1):
			var a: Vector2 = QUEUE_POSTS[int(idxs[k])]
			var z: Vector2 = QUEUE_POSTS[int(idxs[k + 1])]
			if maxf(a.y, z.y) < lo - 40.0 or minf(a.y, z.y) > hi + 40.0:
				continue
			var prev := a
			for s in range(1, 7):
				var f := float(s) / 6.0
				var pt := a.lerp(z, f) + Vector2(0.0, sin(f * PI) * 5.0)
				wc.line(prev, pt, Color(0.86, 0.22, 0.28), 2.2)
				prev = pt
		for ii in idxs:
			var p: Vector2 = QUEUE_POSTS[int(ii)]
			if p.y < lo - 40.0 or p.y > hi + 40.0:
				continue
			wc.circle(p + Shade.light * 8.0, POST_R + 2.0, SHADOW)
			wc.circle(p, POST_R, STEEL_DARK)
			wc.circle(p, POST_R - 3.0, STEEL)
		# visitors in the maze
		if Outdoors.theme_park(Game.weather, Game.hour) and idxs.size() >= 2:
			var a0: Vector2 = QUEUE_POSTS[int(idxs[0])]
			var a1: Vector2 = QUEUE_POSTS[int(idxs[idxs.size() - 1])]
			for j in range(5):
				var qp := a0.lerp(a1, 0.12 + float(j) * 0.16) + Vector2(0.0, 26.0)
				if qp.y < lo - 20.0 or qp.y > hi + 20.0:
					continue
				wc.circle(qp + Shade.light * 6.0, 8.0, SHADOW)
				wc.circle(qp, 7.0, Color(0.30 + _h(float(j) + float(idxs[0])) * 0.5, 0.40, 0.70))
				wc.circle(qp + Vector2(0.0, -9.0), 4.5, Color(0.86, 0.68, 0.52))
				if j % 3 == 0:
					wc.circle(qp + Vector2(0.0, -16.0), 3.5, Color(0.95, 0.55, 0.70))


static func _draw_carts(wc: ShapeBatch, lo: float, hi: float) -> void:
	if CHURRO.y > lo - 40.0 and CHURRO.y < hi + 40.0:
		wc.rect(Rect2(CHURRO.x - 28.0 + 5.0, CHURRO.y - 18.0 + 6.0, 56.0, 36.0), SHADOW)
		wc.rect(Rect2(CHURRO.x - 28.0, CHURRO.y - 18.0, 56.0, 36.0), Color(0.86, 0.28, 0.22))
		wc.rect(Rect2(CHURRO.x - 24.0, CHURRO.y - 30.0, 48.0, 14.0), SAFFRON)
		wc.capsule(CHURRO + Vector2(-10.0, -6.0), CHURRO + Vector2(10.0, -4.0), 3.0, Color(0.78, 0.52, 0.22))
	if ICECREAM.y > lo - 40.0 and ICECREAM.y < hi + 40.0 and Outdoors.icecream_open(Game.weather, Game.hour):
		wc.rect(Rect2(ICECREAM.x - 24.0 + 5.0, ICECREAM.y - 16.0 + 6.0, 48.0, 32.0), SHADOW)
		wc.rect(Rect2(ICECREAM.x - 24.0, ICECREAM.y - 16.0, 48.0, 32.0), Color(0.95, 0.95, 0.98))
		wc.rect(Rect2(ICECREAM.x - 20.0, ICECREAM.y - 28.0, 40.0, 14.0), TURQ)
		wc.circle(ICECREAM + Vector2(0.0, -8.0), 6.0, Color(1.0, 0.70, 0.80))


static func _draw_crowd(wc: ShapeBatch, lo: float, hi: float) -> void:
	if not Outdoors.theme_park(Game.weather, Game.hour):
		return
	# families strolling the middle of quiet stretches
	var spots: Array[Vector2] = [
		Vector2(600.0, -880.0), Vector2(700.0, -1320.0), Vector2(580.0, -1980.0),
		Vector2(690.0, -2780.0), Vector2(610.0, -3380.0), Vector2(720.0, -3880.0),
	]
	for i in range(spots.size()):
		var p: Vector2 = spots[i]
		if p.y < lo - 30.0 or p.y > hi + 30.0:
			continue
		wc.circle(p + Shade.light * 7.0, 9.0, SHADOW)
		wc.circle(p, 8.0, Color(0.35 + _h(float(i)) * 0.4, 0.42, 0.65))
		wc.circle(p + Vector2(0.0, -10.0), 5.0, Color(0.86, 0.68, 0.52))
		# kid
		var kid := p + Vector2(14.0, 6.0)
		wc.circle(kid + Shade.light * 5.0, 6.0, SHADOW)
		wc.circle(kid, 5.5, Color(0.90, 0.45, 0.35))
		wc.circle(kid + Vector2(0.0, -7.0), 4.0, Color(0.90, 0.72, 0.55))
	# balloon sellers (bunches tug upward)
	for i in range(BALLOON_SPOTS.size()):
		var p: Vector2 = BALLOON_SPOTS[i]
		if p.y < lo - 40.0 or p.y > hi + 40.0:
			continue
		wc.circle(p + Shade.light * 8.0, 9.0, SHADOW)
		wc.circle(p, 8.0, Color(0.20, 0.35, 0.55))
		wc.circle(p + Vector2(0.0, -10.0), 5.0, Color(0.86, 0.68, 0.52))
		var tug := sin(float(AnimClock.msec()) * 0.003 + float(i)) * 4.0
		for j in range(5):
			var a := float(j) * TAU / 5.0 + float(AnimClock.msec()) * 0.001
			var bp := p + Vector2(0.0, -28.0 + tug) + Vector2.from_angle(a) * 12.0
			wc.line(p + Vector2(0.0, -8.0), bp, Color(0.85, 0.85, 0.88, 0.7), 1.0)
			wc.circle(bp, 6.0, [MAGENTA, SAFFRON, TURQ, Color(0.30, 0.55, 0.90), Color(0.95, 0.40, 0.55)][j])


static func draw_live(m: Node2D, wc: ShapeBatch, vt: float, vb: float) -> void:
	if m.lvl != "atraccions":
		return
	var w: Dictionary = m.atraccions_flume
	var st: String = str(w.get("state", "wait"))
	var drop := FLUME_DROP
	if drop.y >= vt - 200.0 and drop.y <= vb + 200.0:
		var boat := drop
		var t: float = float(w.get("t", 0.0))
		if st == "climb":
			boat = drop + Vector2(0.0, -50.0 - t * 36.0)
		elif st == "splash":
			var k := clampf(t / FLUME_SPLASH, 0.0, 1.0)
			boat = drop.lerp(FLUME_POOL.get_center(), k)
		else:
			boat = drop + Vector2(-8.0, 8.0)
		wc.circle(boat + Shade.light * 12.0, 18.0, SHADOW)
		wc.capsule(boat + Vector2(-18.0, 0.0), boat + Vector2(18.0, 0.0), 9.0, WOOD_DARK)
		wc.capsule(boat + Vector2(-14.0, -3.0), boat + Vector2(14.0, -3.0), 6.0, WOOD)
		wc.circle(boat + Vector2(-7.0, -11.0), 4.5, Color(0.90, 0.70, 0.55))
		wc.circle(boat + Vector2(7.0, -11.0), 4.5, Color(0.90, 0.70, 0.55))
		if st == "climb":
			wc.glow(boat + Vector2(0.0, -24.0), 30.0, Color(1.0, 0.85, 0.4, 0.35), 0.4)
		if st == "splash":
			var fade := minf(1.0, minf(t * 4.0, (FLUME_SPLASH - t) * 3.0))
			# wave from the pool across the path toward the dry (left) side
			wc.band(PackedVector2Array([
				Vector2(FLUME_WASH_X, FLUME_Y0), Vector2(PATH_R, FLUME_Y0),
				Vector2(FLUME_WASH_X + 20.0, FLUME_Y0 + 40.0), Vector2(PATH_R, FLUME_Y0 + 40.0),
				Vector2(FLUME_WASH_X + 40.0, (FLUME_Y0 + FLUME_Y1) * 0.5), Vector2(PATH_R, (FLUME_Y0 + FLUME_Y1) * 0.5),
				Vector2(FLUME_WASH_X + 60.0, FLUME_Y1), Vector2(PATH_R, FLUME_Y1),
			]), 2, Color(WATER.lightened(0.25), 0.55 * fade), PackedFloat32Array([0.9, 0.7, 0.4, 0.1]))
			for j in range(16):
				var f := fposmod(float(AnimClock.msec()) * 0.0015 + float(j) * 0.11, 1.0)
				var p := Vector2(lerpf(PATH_R, FLUME_WASH_X, f), lerpf(FLUME_Y0, FLUME_Y1, _h(float(j))))
				wc.circle(p, 4.0 + f * 8.0, Color(1.0, 1.0, 1.0, 0.55 * fade * (1.0 - f)))


static func draw_overhead(m: Node2D, ci: Object) -> void:
	if m.lvl != "atraccions":
		return
	var b := ShapeBatch.new()
	b.lod = true
	for i in range(PALMS.size()):
		_palm_crown(b, PALMS[i] + Vector2(0.0, -14.0), 40.0, float(i))
	for i in range(JUNGLE_TREES.size()):
		_jungle_crown(b, JUNGLE_TREES[i] + Vector2(0.0, -12.0), 44.0, float(i))
	_draw_mine_train(b)
	_draw_coaster(b)
	b.flush(ci)


static func _palm_crown(b: ShapeBatch, p: Vector2, r: float, seed_n: float) -> void:
	b.coarse(p + Shade.light * (r * 0.5), r * 0.9, SHADOW)
	for i in range(7):
		var a := float(i) * TAU / 7.0 + seed_n
		var tip := p + Vector2.from_angle(a) * r
		b.capsule(p, tip, 4.0, Color(0.22, 0.55, 0.32))
		b.capsule(p, tip * 0.85 + p * 0.15, 2.5, Color(0.40, 0.70, 0.38))
	b.coarse(p, 8.0, Color(0.55, 0.40, 0.22))


static func _jungle_crown(b: ShapeBatch, p: Vector2, r: float, seed_n: float) -> void:
	b.coarse(p + Shade.light * (r * 0.55), r, SHADOW)
	for tier in range(3):
		var tr := r * (1.0 - float(tier) * 0.25)
		b.coarse(p - Shade.light * float(tier) * 3.0, tr, JUNGLE.lerp(JUNGLE_LIT, float(tier) * 0.35))
	for i in range(5):
		var a := float(i) * TAU / 5.0 + seed_n
		b.coarse(p + Vector2.from_angle(a) * r * 0.55, r * 0.35, JUNGLE_LIT)


static func _draw_mine_train(b: ShapeBatch) -> void:
	var y0 := CANYON_Y0 - 30.0
	var y1 := CANYON_Y1 + 30.0
	var left := Vector2(PATH_L - 30.0, y0)
	var right := Vector2(PATH_R + 50.0, y1)
	# trestle shadow on the boardwalk
	for s in range(12):
		var f := float(s) / 11.0
		var pt := left.lerp(right, f) + Vector2(0.0, sin(f * PI) * 22.0)
		b.circle(pt + Shade.light * 28.0 + Vector2(0.0, 40.0), 10.0, Color(SHADOW, 0.35))
	# twin rails with sleepers (reads as a trestle track, not a thin line)
	for rail: float in [-9.0, 9.0]:
		var prev := left + Vector2(0.0, rail)
		for s in range(1, 16):
			var f := float(s) / 15.0
			var pt := left.lerp(right, f) + Vector2(0.0, rail + sin(f * PI) * 22.0)
			b.line(prev, pt, STEEL_DARK, 5.0)
			b.line(prev + Vector2(0.0, 1.5), pt + Vector2(0.0, 1.5), STEEL, 2.5)
			if s % 2 == 0:
				b.line(pt + Vector2(0.0, -9.0), pt + Vector2(0.0, 9.0), WOOD_DARK, 3.0)
			prev = pt
	# trestle posts + cross-bracing
	for my: float in MINE_YS:
		var f := clampf((my - y0) / (y1 - y0), 0.0, 1.0)
		var at := left.lerp(right, f) + Vector2(0.0, sin(f * PI) * 22.0)
		b.line(at + Shade.light * 10.0, Vector2(at.x, at.y + 60.0) + Shade.light * 10.0, Color(SHADOW, 0.4), 6.0)
		b.line(at, Vector2(at.x, at.y + 60.0), WOOD_DARK, 6.0)
		b.line(Vector2(at.x - 22.0, at.y + 60.0), Vector2(at.x + 22.0, at.y + 60.0), WOOD_DARK, 4.0)
		b.line(at + Vector2(-14.0, 18.0), at + Vector2(14.0, 42.0), WOOD, 3.0)
		b.line(at + Vector2(14.0, 18.0), at + Vector2(-14.0, 42.0), WOOD, 3.0)
	# train of two cars
	var span := left.distance_to(right)
	var shift := fmod(float(AnimClock.msec()) * 0.001 * 75.0, span + 140.0) - 70.0
	if shift > 0.0 and shift < span:
		var f := shift / span
		for ci in range(2):
			var f2 := clampf(f - float(ci) * 0.04, 0.0, 1.0)
			var car := left.lerp(right, f2) + Vector2(0.0, sin(f2 * PI) * 22.0)
			b.rect(Rect2(car.x - 20.0 + 4.0, car.y - 12.0 + 6.0, 40.0, 22.0), SHADOW)
			b.rect(Rect2(car.x - 20.0, car.y - 12.0, 40.0, 22.0), Color(0.55, 0.22, 0.14))
			b.rect(Rect2(car.x - 16.0, car.y - 8.0, 32.0, 12.0), Color(0.72, 0.34, 0.20))
			b.circle(car + Vector2(-8.0, 10.0), 5.0, STEEL_DARK)
			b.circle(car + Vector2(8.0, 10.0), 5.0, STEEL_DARK)
			b.circle(car + Vector2(-4.0, -14.0), 4.0, Color(0.90, 0.70, 0.55))
			b.circle(car + Vector2(4.0, -14.0), 4.0, Color(0.90, 0.70, 0.55))


static func _draw_coaster(b: ShapeBatch) -> void:
	var base := Vector2(PATH_R - 90.0, LOOP_Y0 - 40.0)
	var top := LIFT_HILL + Vector2(0.0, -140.0)
	# solid lift hill with twin rails, sleepers and a ground shadow
	b.line(base + Shade.light * 24.0, top + Shade.light * 24.0, Color(SHADOW, 0.45), 16.0)
	b.line(base, top, STEEL_DARK, 16.0)
	b.line(base + Vector2(16.0, 0.0), top + Vector2(16.0, 0.0), STEEL_DARK, 16.0)
	b.line(base + Vector2(4.0, 0.0), top + Vector2(4.0, 0.0), STEEL, 8.0)
	b.line(base + Vector2(12.0, 0.0), top + Vector2(12.0, 0.0), STEEL, 8.0)
	b.line(base + Vector2(8.0, 0.0), top + Vector2(8.0, 0.0), Color(0.78, 0.80, 0.84), 3.0)
	# lift supports with cross-bracing
	for i in range(6):
		var f := float(i) / 5.0
		var at := base.lerp(top, f)
		var foot_y := at.y + 44.0 + (1.0 - f) * 56.0
		b.line(at + Vector2(8.0, 0.0), Vector2(at.x + 8.0, foot_y), STEEL_DARK, 5.0)
		b.line(at + Vector2(-6.0, 18.0), at + Vector2(20.0, 36.0), STEEL, 2.5)
		b.line(at + Vector2(20.0, 18.0), at + Vector2(-6.0, 36.0), STEEL, 2.5)
	# loop with solid track + shadow
	var c := LOOP_C
	var pts := PackedVector2Array()
	for i in range(32):
		var a := -PI * 0.5 + float(i) / 31.0 * TAU
		pts.append(c + Vector2.from_angle(a) * LOOP_R)
	for i in range(pts.size() - 1):
		b.line(pts[i] + Shade.light * 18.0, pts[i + 1] + Shade.light * 18.0, Color(SHADOW, 0.4), 12.0)
	for i in range(pts.size() - 1):
		b.line(pts[i], pts[i + 1], STEEL_DARK, 14.0)
		b.line(pts[i], pts[i + 1], STEEL, 8.0)
		b.line(pts[i], pts[i + 1], Color(0.80, 0.82, 0.86), 3.0)
	# runout from lift to loop
	b.line(top, pts[0], STEEL_DARK, 10.0)
	b.line(top + Vector2(10.0, 0.0), pts[0] + Vector2(10.0, 0.0), STEEL, 6.0)
	# train of three cars
	var u := fmod(float(AnimClock.msec()) * 0.001 * COASTER_SPEED / (TAU * LOOP_R), 1.0)
	for car_i in range(3):
		var uc := fmod(u + float(car_i) * 0.04, 1.0)
		var ang := -PI * 0.5 + uc * TAU
		var tp := c + Vector2.from_angle(ang) * LOOP_R
		var tang := Vector2.from_angle(ang + PI * 0.5)
		b.capsule(tp + tang * 12.0, tp - tang * 12.0, 7.0, MAGENTA if car_i == 0 else SAFFRON)
		b.circle(tp + Vector2.from_angle(ang) * 5.0, 4.0, Color(0.90, 0.70, 0.55))
	if u > 0.2 and u < 0.35:
		var tip := c + Vector2.from_angle(-PI * 0.5 + u * TAU) * LOOP_R
		b.glow(tip, 44.0, Color(1.0, 0.85, 0.45, 0.4), 0.4)


static func is_lamp(_m: Node2D, _p: Vector2) -> bool:
	return false


static func name_place(_m: Node2D) -> Dictionary:
	# stubs are fat (gap 1.65): one line of LES ATRACCIONS is ~509 px at
	# NAME_H, so a room under NAME_MIN_H forces LES / ATRACCIONS on two
	# lines. Keep the room wide enough that ATRACCIONS itself stays at
	# full height (~364 px) with margin inside the 540-wide path
	return {"x": CX, "room": 400.0}


static func tree_kind(m: Node2D, p: Vector2) -> int:
	for t: Vector2 in PALMS:
		if t.distance_squared_to(p) < 4.0:
			return m.TREE_PALM
	for t: Vector2 in JUNGLE_TREES:
		if t.distance_squared_to(p) < 4.0:
			return m.TREE_FOREST
	return m.TREE_NONE


static func draw_column(m: Node2D, wc: ShapeBatch, p: Vector2) -> void:
	for t: Vector2 in QUEUE_POSTS:
		if t.distance_squared_to(p) < 4.0:
			wc.circle(p + Shade.light * 8.0, POST_R + 2.0, SHADOW)
			wc.circle(p, POST_R, STEEL_DARK)
			wc.circle(p, POST_R - 3.0, STEEL)
			wc.circle(p - Shade.light * 1.5, 2.5, STEEL.lightened(0.25))
			return
	for t: Vector2 in PALMS:
		if t.distance_squared_to(p) < 4.0:
			wc.circle(p + Shade.light * 14.0, 16.0, SHADOW)
			wc.circle(p, 10.0, Color(0.55, 0.40, 0.22))
			wc.circle(p, 7.0, Color(0.68, 0.50, 0.28))
			return
	for t: Vector2 in JUNGLE_TREES:
		if t.distance_squared_to(p) < 4.0:
			wc.circle(p + Shade.light * 14.0, 18.0, SHADOW)
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
