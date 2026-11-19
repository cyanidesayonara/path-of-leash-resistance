class_name Atraccions
extends RefCounted

# WALK: LES ATRACCIONS (an original theme park on the Costa Daurada)
# Bright day. Through the gates, past invented lands, off-leash on the picnic
# lawn. No chase yet: the mascots come later.
#
# Up the walk: the ticket gates and welcome arch; Cala del Corsari (white
# fishing village, harbour pool, pirate-ship swing); Canyon del Sol (boardwalk
# Wild West, mine-train track overhead); Selva dels Llorers (jungle of the
# park's own invention, log flume); Plaça del Loop (the big coaster's lift
# and loop); then the picnic lawn behind the last land.
#
# Live event: the flume's splash. The log boat clanks to the top and its
# riders scream (FLUME_WARN), then it plunges and a wave sloshes the path.
# Pull your human clear (or plant on the dry side) for a dodge; caught, they
# soak.

# the hooks main calls on this walk, held to it by tests/test_walk_hooks.gd
const HOOKS := ["draw_bollard", "draw_column", "draw_cross_section", "draw_edge_layer",
	"draw_live", "draw_overhead", "draw_snack", "idle_status", "is_lamp",
	"on_bark", "surface", "tick", "tree_kind"]

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
const SHADOW := Color(0.10, 0.14, 0.26, 0.26)

# paving and lands
const PAVEMENT := Color(0.78, 0.74, 0.68)
const PAVEMENT_LIT := Color(0.88, 0.84, 0.76)
const GRASS := Color(0.42, 0.62, 0.34)
const GRASS_LIT := Color(0.54, 0.74, 0.42)
const SAND := Color(0.90, 0.82, 0.62)
const WATER := Color(0.22, 0.58, 0.72)
const WATER_DEEP := Color(0.12, 0.42, 0.58)
const WHITEWASH := Color(0.96, 0.95, 0.90)
const TERRACOTTA := Color(0.78, 0.42, 0.28)
const WOOD := Color(0.56, 0.36, 0.22)
const WOOD_DARK := Color(0.36, 0.22, 0.14)
const STEEL := Color(0.58, 0.61, 0.66)
const STEEL_DARK := Color(0.32, 0.34, 0.38)
const SAFFRON := Color(0.96, 0.72, 0.18)
const MAGENTA := Color(0.86, 0.22, 0.52)
const TURQ := Color(0.18, 0.72, 0.68)
const JUNGLE := Color(0.18, 0.42, 0.28)
const JUNGLE_LIT := Color(0.28, 0.56, 0.36)
const PONCHO := Color(0.92, 0.40, 0.28)

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
const BOOTH := Rect2(PATH_L + 20.0, -80.0, 70.0, 50.0)
const TURNSTILES: Array[Vector2] = [
	Vector2(560.0, 40.0), Vector2(640.0, 40.0), Vector2(720.0, 40.0),
]

# Cala del Corsari
const HARBOUR := Rect2(PATH_L + 40.0, -1100.0, 200.0, 160.0)
const SHIP := Vector2(PATH_L + 140.0, -1020.0)
const VILLAGE_FRONTS: Array[float] = [-520.0, -680.0, -860.0, -1180.0]

# Canyon del Sol
const SALOON := Rect2(PATH_R - 110.0, -1680.0, 90.0, 70.0)
const MINE_YS: Array[float] = [-1500.0, -1750.0, -2000.0, -2250.0]

# Selva + flume
const FLUME_DROP := Vector2(PATH_R - 40.0, -2900.0)
const FLUME_POOL := Rect2(PATH_L + 30.0, -3020.0, PATH_R - PATH_L - 60.0, 140.0)
const FLUME_WARN := 1.0
const FLUME_SPLASH := 1.4
const FLUME_COOLDOWN := 7.0
const FLUME_Y0 := -3040.0
const FLUME_Y1 := -2860.0
const FLUME_REACH_X := PATH_L + 380.0
const FLUME_DRY_X := PATH_R - 80.0

# Plaça del Loop
const LIFT_HILL := Vector2(PATH_R - 30.0, -3800.0)
const LOOP_C := Vector2(CX + 40.0, -4000.0)
const LOOP_R := 90.0
const COASTER_SPEED := 110.0

# picnic finish
const PICNIC_TABLES: Array[Rect2] = [
	Rect2(420.0, -4620.0, 88.0, 40.0),
	Rect2(760.0, -4620.0, 88.0, 40.0),
]
const PRIZE := Vector2(640.0, -4680.0)
const PRIZE_TEXT := "snatch the churro off the picnic grill"

# queue rope posts the leash wraps (and she marks)
const QUEUE_POSTS: Array[Vector2] = [
	Vector2(500.0, -450.0), Vector2(780.0, -450.0),
	Vector2(520.0, -1550.0), Vector2(760.0, -1550.0),
	Vector2(500.0, -2550.0), Vector2(780.0, -2550.0),
	Vector2(520.0, -3550.0), Vector2(760.0, -3550.0),
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
const CAROUSEL := Vector2(PATH_L + 95.0, -3600.0)
const CAROUSEL_R := 48.0


static func solids(_m: Node2D = null) -> Array[Rect2]:
	return [
		BOOTH, SALOON,
		Rect2(SHIP.x - 50.0, SHIP.y - 30.0, 100.0, 60.0),
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
	# queue posts and a couple of lamp posts she marks
	var marks: Array[Vector2] = [
		QUEUE_POSTS[0], QUEUE_POSTS[1], QUEUE_POSTS[2], QUEUE_POSTS[4],
		QUEUE_POSTS[6], Vector2(PATH_L + 30.0, -1900.0), PRIZE + Vector2(-100.0, 40.0),
	]
	# dropped park food: popcorn, half a churro, ice cream wrapper
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
	return p.y >= FLUME_Y0 and p.y <= FLUME_Y1 and p.x >= PATH_L - 8.0 and p.x <= FLUME_REACH_X


static func on_dry_side(p: Vector2) -> bool:
	return p.y >= FLUME_Y0 - 40.0 and p.y <= FLUME_Y1 + 40.0 and p.x >= FLUME_DRY_X


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
			if hy >= FLUME_Y0 - 40.0 and hy <= FLUME_Y1 + 40.0 and m.human.global_position.x < FLUME_REACH_X + 20.0:
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
			# the pair is in the flume's stretch: a dodge if they stay out of the wash
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
				var close_now: bool = hpos.y >= FLUME_Y0 - 40.0 and hpos.y <= FLUME_Y1 + 40.0 and hpos.x < FLUME_REACH_X + 20.0
				var planted_dry: bool = bool(m.dog.planted) and on_dry_side(dpos) and not bool(w.get("hit", false))
				var nm: Dictionary = NearMiss.consider(close_now, bool(w.get("hit", false)), bool(w.get("threatened", false)), false)
				var cleared: bool = bool(w.get("threatened", false)) and not bool(w.get("hit", false)) \
					and (bool(nm.get("dodge", false)) or planted_dry or on_dry_side(hpos) or not in_wash)
				if cleared and not bool(w.get("paid", false)):
					w["paid"] = true
					m.atraccions_flume_dodges += 1
					m.combo.add("FLUME DODGED", 45)
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
	# soft park verge either side
	b.rect(Rect2(-460.0, top, PATH_L + 460.0, bot - top), GRASS)
	b.rect(Rect2(PATH_R, top, 1740.0 - PATH_R, bot - top), GRASS)
	var strip := 70.0
	var y := floorf(top / strip) * strip
	while y < bot:
		var k := absf(y) / strip
		for side: float in [-1.0, 1.0]:
			var bx := (PATH_L - 8.0) if side < 0.0 else (PATH_R + 8.0)
			b.coarse(Vector2(bx + side * 20.0, y + 20.0), 22.0, GRASS_LIT)
			for j in range(2):
				var hx := bx + side * (50.0 + _h(k + float(j)) * 220.0)
				var hy := y + _h(k * 3.0 + float(j)) * strip
				b.coarse(Vector2(hx, hy), 14.0 + _h(k + float(j)) * 18.0, JUNGLE if y < SELVA_Y0 and y > SELVA_Y1 else GRASS.darkened(0.1))
		y += strip
	# whitewashed village fronts on the west in Cala del Corsari
	for fy: float in VILLAGE_FRONTS:
		if fy < top - 80.0 or fy > bot + 80.0:
			continue
		_village_front(b, Vector2(PATH_L - 90.0, fy), -1.0)
		_village_front(b, Vector2(PATH_R + 90.0, fy - 80.0), 1.0)
	# saloon and west false fronts
	if SALOON.end.y > top and SALOON.position.y < bot:
		b.rect(Rect2(SALOON.position + Vector2(6.0, 8.0), SALOON.size), SHADOW)
		b.rect(SALOON, WOOD_DARK)
		b.rect(SALOON.grow(-4.0), WOOD)
		b.rect(Rect2(SALOON.position.x - 8.0, SALOON.position.y - 18.0, SALOON.size.x + 16.0, 18.0), WOOD_DARK)
		b.rect(Rect2(SALOON.position.x + 10.0, SALOON.position.y + 12.0, 28.0, 36.0), Color(0.20, 0.14, 0.10))
	b.lod = was


static func _village_front(b: ShapeBatch, p: Vector2, side: float) -> void:
	var w := 70.0
	var h := 55.0
	var r := Rect2(p.x - w * 0.5, p.y - h * 0.5, w, h)
	b.rect(Rect2(r.position + Vector2(5.0, 6.0), r.size), SHADOW)
	b.rect(r, WHITEWASH)
	b.rect(Rect2(r.position.x - 4.0, r.position.y - 14.0, r.size.x + 8.0, 16.0), TERRACOTTA)
	b.rect(Rect2(r.position.x + 22.0, r.position.y + 18.0, 18.0, 28.0), Color(0.55, 0.70, 0.78))
	b.circle(p + Vector2(side * 8.0, -6.0), 4.0, Color(0.70, 0.78, 0.86))


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
	wc.lod = was


static func _draw_path(wc: ShapeBatch, lo: float, hi: float) -> void:
	wc.rect(Rect2(PATH_L, lo, PATH_R - PATH_L, hi - lo), PAVEMENT)
	# panot on town stretches (gates, plaza); sand/boardwalk/jungle elsewhere
	var bands := [
		[GATE_BAND + 400.0, CORSARI_Y0],
		[LOOP_Y0, LOOP_Y1],
	]
	for band in bands:
		var a: float = maxf(lo, float(band[1]))
		var z: float = minf(hi, float(band[0]))
		if z > a:
			Panot.flor(wc, PATH_L, PATH_R, a, z, Color(0.10, 0.08, 0.06, 0.10), Color(1.0, 0.98, 0.94, 0.08))
	# boardwalk planks in Canyon del Sol
	var bw0 := maxf(lo, CANYON_Y1)
	var bw1 := minf(hi, CANYON_Y0)
	if bw1 > bw0:
		wc.rect(Rect2(PATH_L, bw0, PATH_R - PATH_L, bw1 - bw0), WOOD.lightened(0.15))
		var y := floorf(bw0 / 16.0) * 16.0
		while y < bw1:
			wc.rect(Rect2(PATH_L, y, PATH_R - PATH_L, 1.4), WOOD_DARK)
			y += 16.0
	# packed earth / leaf litter in the selva
	var s0 := maxf(lo, SELVA_Y1)
	var s1 := minf(hi, SELVA_Y0)
	if s1 > s0:
		wc.rect(Rect2(PATH_L, s0, PATH_R - PATH_L, s1 - s0), Color(0.48, 0.40, 0.28))
		var sy := floorf(s0 / 50.0) * 50.0
		while sy < s1:
			wc.coarse(Vector2(CX + (_h(sy) - 0.5) * 180.0, sy + 20.0), 12.0, JUNGLE)
			sy += 50.0
	# picnic lawn from PICNIC_Y toward the gate
	var g0 := maxf(lo, -5000.0)
	var g1 := minf(hi, PICNIC_Y)
	if g1 > g0:
		wc.rect(Rect2(PATH_L, g0, PATH_R - PATH_L, g1 - g0), GRASS)
		var gy := floorf(g0 / 40.0) * 40.0
		while gy < g1:
			wc.coarse(Vector2(CX + (_h(gy * 0.1) - 0.5) * 200.0, gy + 10.0), 10.0, GRASS_LIT)
			gy += 40.0


static func _draw_gates(wc: ShapeBatch, lo: float, hi: float) -> void:
	if hi < -200.0 or lo > 120.0:
		return
	# turnstiles
	for t: Vector2 in TURNSTILES:
		if t.y < lo - 40.0 or t.y > hi + 40.0:
			continue
		wc.rect(Rect2(t.x - 18.0 + 4.0, t.y - 10.0 + 4.0, 36.0, 20.0), SHADOW)
		wc.rect(Rect2(t.x - 18.0, t.y - 10.0, 36.0, 20.0), STEEL_DARK)
		wc.rect(Rect2(t.x - 14.0, t.y - 6.0, 28.0, 12.0), STEEL)
		wc.line(t + Vector2(-10.0, 0.0), t + Vector2(10.0, 0.0), SAFFRON, 2.0)
	# ticket booth
	if BOOTH.end.y > lo and BOOTH.position.y < hi:
		wc.rect(Rect2(BOOTH.position + Vector2(6.0, 8.0), BOOTH.size), SHADOW)
		wc.rect(BOOTH, MAGENTA.darkened(0.2))
		wc.rect(BOOTH.grow(-4.0), MAGENTA)
		wc.rect(Rect2(BOOTH.position.x + 12.0, BOOTH.position.y + 10.0, 30.0, 18.0), Color(0.70, 0.88, 0.95))
		wc.rect(Rect2(BOOTH.position.x - 4.0, BOOTH.position.y - 12.0, BOOTH.size.x + 8.0, 14.0), SAFFRON)
	# welcome arch
	if ARCH.y > lo - 80.0 and ARCH.y < hi + 80.0:
		wc.rect(Rect2(ARCH.x - 160.0 + 8.0, ARCH.y - 20.0 + 8.0, 40.0, 50.0), SHADOW)
		wc.rect(Rect2(ARCH.x + 120.0 + 8.0, ARCH.y - 20.0 + 8.0, 40.0, 50.0), SHADOW)
		wc.rect(Rect2(ARCH.x - 160.0, ARCH.y - 20.0, 40.0, 50.0), TURQ.darkened(0.15))
		wc.rect(Rect2(ARCH.x + 120.0, ARCH.y - 20.0, 40.0, 50.0), TURQ.darkened(0.15))
		wc.rect(Rect2(ARCH.x - 170.0, ARCH.y - 42.0, 340.0, 28.0), SAFFRON)
		wc.rect(Rect2(ARCH.x - 160.0, ARCH.y - 36.0, 320.0, 16.0), MAGENTA)
	# fountain
	if FOUNTAIN.y > lo - 40.0 and FOUNTAIN.y < hi + 40.0:
		wc.circle(FOUNTAIN + Shade.light * 16.0, 34.0, SHADOW)
		wc.circle(FOUNTAIN, 32.0, STEEL)
		wc.glow(FOUNTAIN, 36.0, Color(WATER, 0.45), 0.4)
		wc.circle(FOUNTAIN, 22.0, WATER)
		wc.circle(FOUNTAIN - Shade.light * 4.0, 10.0, Color(1.0, 1.0, 1.0, 0.35))
		wc.circle(FOUNTAIN, 6.0, STEEL_DARK)


static func _draw_corsari(wc: ShapeBatch, lo: float, hi: float) -> void:
	if HARBOUR.end.y < lo or HARBOUR.position.y > hi:
		pass
	else:
		wc.rect(Rect2(HARBOUR.position + Vector2(6.0, 8.0), HARBOUR.size), SHADOW)
		wc.rect(HARBOUR, WATER_DEEP)
		wc.band(PackedVector2Array([
			HARBOUR.position, Vector2(HARBOUR.end.x, HARBOUR.position.y),
			HARBOUR.position + Vector2(10.0, 30.0), Vector2(HARBOUR.end.x - 10.0, HARBOUR.position.y + 30.0),
			HARBOUR.position + Vector2(20.0, 70.0), Vector2(HARBOUR.end.x - 20.0, HARBOUR.position.y + 70.0),
			Vector2(HARBOUR.position.x + 30.0, HARBOUR.end.y), Vector2(HARBOUR.end.x - 30.0, HARBOUR.end.y),
		]), 2, WATER, PackedFloat32Array([0.9, 0.7, 0.45, 0.2]))
	# pirate ship rocker
	if SHIP.y > lo - 60.0 and SHIP.y < hi + 60.0:
		var swing := sin(float(AnimClock.msec()) * 0.0022) * 18.0
		var hull := SHIP + Vector2(swing, 0.0)
		wc.circle(hull + Shade.light * 18.0, 40.0, SHADOW)
		wc.capsule(hull + Vector2(-40.0, 0.0), hull + Vector2(40.0, 0.0), 16.0, WOOD_DARK)
		wc.capsule(hull + Vector2(-34.0, -4.0), hull + Vector2(34.0, -4.0), 12.0, WOOD)
		wc.line(hull + Vector2(0.0, -8.0), hull + Vector2(0.0, -48.0), WOOD_DARK, 3.0)
		wc.quad(hull + Vector2(0.0, -48.0), hull + Vector2(28.0, -40.0), hull + Vector2(26.0, -28.0), hull + Vector2(0.0, -34.0), Color(0.86, 0.18, 0.20))


static func _draw_canyon(wc: ShapeBatch, lo: float, hi: float) -> void:
	# hitching posts / barrels along the boardwalk
	for i in range(4):
		var p := Vector2(PATH_L + 40.0 + float(i % 2) * (PATH_R - PATH_L - 80.0), -1600.0 - float(i) * 160.0)
		if p.y < lo - 30.0 or p.y > hi + 30.0:
			continue
		wc.circle(p + Shade.light * 10.0, 14.0, SHADOW)
		wc.circle(p, 12.0, WOOD_DARK)
		wc.circle(p, 9.0, WOOD)
		wc.circle(p - Shade.light * 2.0, 3.0, WOOD.lightened(0.2))


static func _draw_selva(wc: ShapeBatch, lo: float, hi: float) -> void:
	if FLUME_POOL.end.y < lo or FLUME_POOL.position.y > hi:
		return
	wc.rect(Rect2(FLUME_POOL.position + Vector2(6.0, 8.0), FLUME_POOL.size), SHADOW)
	wc.rect(FLUME_POOL, WATER_DEEP)
	wc.glow(FLUME_POOL.get_center(), 90.0, Color(WATER, 0.35), 0.45)
	# flume trough toward the drop
	var drop := FLUME_DROP
	wc.line(Vector2(PATH_R - 20.0, -2750.0), drop, STEEL_DARK, 10.0)
	wc.line(Vector2(PATH_R - 20.0, -2750.0), drop, STEEL, 6.0)
	wc.circle(drop, 14.0, STEEL_DARK)
	wc.circle(drop, 9.0, STEEL)
	# poncho crowd on the splash rim when fair weather
	if Outdoors.theme_park(Game.weather, Game.hour):
		for i in range(5):
			var pp := Vector2(PATH_L + 50.0 + float(i) * 55.0, FLUME_Y0 - 20.0)
			if pp.y < lo - 20.0 or pp.y > hi + 20.0:
				continue
			wc.circle(pp + Shade.light * 8.0, 10.0, SHADOW)
			wc.circle(pp, 8.0, PONCHO)
			wc.circle(pp + Vector2(0.0, -10.0), 5.0, Color(0.86, 0.68, 0.52))


static func _draw_loop_plaza(wc: ShapeBatch, lo: float, hi: float) -> void:
	# carousel base on the plaza
	if CAROUSEL.y > lo - 60.0 and CAROUSEL.y < hi + 60.0:
		wc.circle(CAROUSEL + Shade.light * 20.0, CAROUSEL_R + 6.0, SHADOW)
		wc.circle(CAROUSEL, CAROUSEL_R, MAGENTA.darkened(0.15))
		wc.circle(CAROUSEL, CAROUSEL_R - 10.0, SAFFRON)
		wc.circle(CAROUSEL, 12.0, TURQ)
		var spin := float(AnimClock.msec()) * 0.003
		for i in range(6):
			var a := spin + float(i) * TAU / 6.0
			var hp := CAROUSEL + Vector2.from_angle(a) * (CAROUSEL_R - 22.0)
			wc.circle(hp, 7.0, Color(0.92, 0.92, 0.94))
			wc.circle(hp + Vector2(0.0, -8.0), 5.0, Color(0.86, 0.30, 0.40))
	# lift hill footings
	if LIFT_HILL.y > lo - 40.0 and LIFT_HILL.y < hi + 40.0:
		wc.rect(Rect2(LIFT_HILL.x - 16.0, LIFT_HILL.y - 16.0, 32.0, 32.0), STEEL_DARK)
		wc.rect(Rect2(LIFT_HILL.x - 12.0, LIFT_HILL.y - 12.0, 24.0, 24.0), STEEL)


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
	# rope barriers between paired posts
	for i in range(0, QUEUE_POSTS.size(), 2):
		var a: Vector2 = QUEUE_POSTS[i]
		var z: Vector2 = QUEUE_POSTS[i + 1]
		if maxf(a.y, z.y) < lo - 40.0 or minf(a.y, z.y) > hi + 40.0:
			continue
		var prev := a
		for s in range(1, 9):
			var f := float(s) / 8.0
			var pt := a.lerp(z, f) + Vector2(0.0, sin(f * PI) * 6.0)
			wc.line(prev, pt, Color(0.86, 0.22, 0.28), 2.2)
			prev = pt
		for p: Vector2 in [a, z]:
			wc.circle(p + Shade.light * 8.0, POST_R + 2.0, SHADOW)
			wc.circle(p, POST_R, STEEL_DARK)
			wc.circle(p, POST_R - 3.0, STEEL)
		# visitors in the queue on a clear day
		if Outdoors.theme_park(Game.weather, Game.hour):
			for j in range(4):
				var qp := a.lerp(z, 0.15 + float(j) * 0.18) + Vector2(0.0, 28.0)
				wc.circle(qp + Shade.light * 6.0, 8.0, SHADOW)
				wc.circle(qp, 7.0, Color(0.30 + _h(float(i + j)) * 0.5, 0.40, 0.70))
				wc.circle(qp + Vector2(0.0, -9.0), 4.5, Color(0.86, 0.68, 0.52))


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


static func draw_live(m: Node2D, wc: ShapeBatch, vt: float, vb: float) -> void:
	if m.lvl != "atraccions":
		return
	var w: Dictionary = m.atraccions_flume
	var st: String = str(w.get("state", "wait"))
	var drop := FLUME_DROP
	if drop.y < vt - 200.0 or drop.y > vb + 200.0:
		pass
	else:
		# log boat: climbs during telegraph, plunges on splash
		var boat := drop
		var t: float = float(w.get("t", 0.0))
		if st == "climb":
			boat = drop + Vector2(0.0, -40.0 - t * 30.0)
		elif st == "splash":
			var k := clampf(t / FLUME_SPLASH, 0.0, 1.0)
			boat = drop.lerp(FLUME_POOL.get_center(), k) + Vector2(-20.0 * k, 0.0)
		else:
			boat = drop + Vector2(-10.0, 10.0)
		wc.capsule(boat + Vector2(-16.0, 0.0), boat + Vector2(16.0, 0.0), 8.0, WOOD_DARK)
		wc.capsule(boat + Vector2(-12.0, -2.0), boat + Vector2(12.0, -2.0), 5.0, WOOD)
		wc.circle(boat + Vector2(-6.0, -10.0), 4.0, Color(0.90, 0.70, 0.55))
		wc.circle(boat + Vector2(6.0, -10.0), 4.0, Color(0.90, 0.70, 0.55))
		if st == "climb":
			# scream arcs
			wc.glow(boat + Vector2(0.0, -24.0), 28.0, Color(1.0, 0.85, 0.4, 0.35), 0.4)
		if st == "splash":
			var fade := minf(1.0, minf(t * 4.0, (FLUME_SPLASH - t) * 3.0))
			var reach := FLUME_REACH_X - PATH_L
			wc.band(PackedVector2Array([
				Vector2(PATH_L, FLUME_Y0), Vector2(FLUME_REACH_X, FLUME_Y0),
				Vector2(PATH_L, FLUME_Y0 + 40.0), Vector2(FLUME_REACH_X - 20.0, FLUME_Y0 + 40.0),
				Vector2(PATH_L, (FLUME_Y0 + FLUME_Y1) * 0.5), Vector2(FLUME_REACH_X - 40.0, (FLUME_Y0 + FLUME_Y1) * 0.5),
				Vector2(PATH_L, FLUME_Y1), Vector2(FLUME_REACH_X - 60.0, FLUME_Y1),
			]), 2, Color(WATER.lightened(0.25), 0.55 * fade), PackedFloat32Array([0.9, 0.7, 0.4, 0.1]))
			for j in range(18):
				var f := fposmod(float(AnimClock.msec()) * 0.0015 + float(j) * 0.11, 1.0)
				var p := Vector2(PATH_L + f * reach, lerpf(FLUME_Y0, FLUME_Y1, _h(float(j))))
				wc.circle(p, 4.0 + f * 8.0, Color(1.0, 1.0, 1.0, 0.55 * fade * (1.0 - f)))


static func draw_overhead(m: Node2D, ci: Object) -> void:
	if m.lvl != "atraccions":
		return
	var b := ShapeBatch.new()
	b.lod = true
	# palm crowns
	for i in range(PALMS.size()):
		_palm_crown(b, PALMS[i] + Vector2(0.0, -14.0), 40.0, float(i))
	for i in range(JUNGLE_TREES.size()):
		_jungle_crown(b, JUNGLE_TREES[i] + Vector2(0.0, -12.0), 44.0, float(i))
	# mine-train track across Canyon del Sol
	_draw_mine_train(b)
	# coaster lift + loop + train
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
	var y0 := CANYON_Y0 - 40.0
	var y1 := CANYON_Y1 + 40.0
	# track rails overhead, slight sag
	var left := Vector2(PATH_L - 40.0, y0)
	var right := Vector2(PATH_R + 40.0, y1)
	for rail: float in [-6.0, 6.0]:
		var prev := left + Vector2(0.0, rail)
		for s in range(1, 12):
			var f := float(s) / 11.0
			var pt := left.lerp(right, f) + Vector2(0.0, rail + sin(f * PI) * 18.0)
			b.line(prev, pt, STEEL_DARK, 2.4)
			prev = pt
	# supports
	for my: float in MINE_YS:
		b.line(Vector2(PATH_L + 10.0, my), Vector2(PATH_L + 10.0, my - 70.0), STEEL_DARK, 3.0)
		b.line(Vector2(PATH_R - 10.0, my), Vector2(PATH_R - 10.0, my - 70.0), STEEL_DARK, 3.0)
	# train car that passes now and then
	var span := left.distance_to(right)
	var shift := fmod(float(AnimClock.msec()) * 0.001 * 70.0, span + 120.0) - 60.0
	if shift > 0.0 and shift < span:
		var f := shift / span
		var car := left.lerp(right, f) + Vector2(0.0, sin(f * PI) * 18.0)
		b.rect(Rect2(car.x - 16.0, car.y - 10.0, 32.0, 18.0), Color(0.55, 0.22, 0.14))
		b.rect(Rect2(car.x - 12.0, car.y - 6.0, 24.0, 10.0), Color(0.72, 0.34, 0.20))
		b.circle(car + Vector2(-8.0, 8.0), 4.0, STEEL_DARK)
		b.circle(car + Vector2(8.0, 8.0), 4.0, STEEL_DARK)


static func _draw_coaster(b: ShapeBatch) -> void:
	# lift hill
	var base := Vector2(PATH_R - 80.0, LOOP_Y0 - 50.0)
	var top := LIFT_HILL + Vector2(0.0, -120.0)
	b.line(base, top, STEEL_DARK, 5.0)
	b.line(base + Vector2(10.0, 0.0), top + Vector2(10.0, 0.0), STEEL, 3.0)
	# loop
	var c := LOOP_C
	var pts := PackedVector2Array()
	for i in range(25):
		var a := -PI * 0.5 + float(i) / 24.0 * TAU
		pts.append(c + Vector2.from_angle(a) * LOOP_R)
	for i in range(pts.size() - 1):
		b.line(pts[i], pts[i + 1], STEEL_DARK, 4.0)
		b.line(pts[i], pts[i + 1], STEEL, 2.0)
	# train on the loop, screams as it crests
	var u := fmod(float(AnimClock.msec()) * 0.001 * COASTER_SPEED / (TAU * LOOP_R), 1.0)
	var ang := -PI * 0.5 + u * TAU
	var tp := c + Vector2.from_angle(ang) * LOOP_R
	b.capsule(tp + Vector2.from_angle(ang + PI * 0.5) * 10.0, tp - Vector2.from_angle(ang + PI * 0.5) * 10.0, 6.0, MAGENTA)
	b.circle(tp, 5.0, SAFFRON)
	# crest scream telegraph glow near the top
	if u > 0.2 and u < 0.35:
		b.glow(tp, 36.0, Color(1.0, 0.85, 0.45, 0.4), 0.4)


static func is_lamp(_m: Node2D, _p: Vector2) -> bool:
	return false


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
	# fallback stub
	wc.circle(p, 6.0, STEEL_DARK)


static func surface(m: Node2D, p: Vector2) -> int:
	if p.y <= m.GATE_Y:
		return -1
	# harbour / flume water
	if HARBOUR.has_point(p) or FLUME_POOL.has_point(p):
		return Surfaces.S.WATER
	# active splash reads as water
	var w: Dictionary = m.atraccions_flume
	if str(w.get("state", "")) == "splash" and in_splash(p):
		return Surfaces.S.WATER
	# picnic lawn
	if p.y < PICNIC_Y and p.x > PATH_L and p.x < PATH_R:
		return Surfaces.S.GRASS
	# selva packed earth handles as mud-ish sand
	if p.y <= SELVA_Y0 and p.y >= SELVA_Y1 and p.x > PATH_L and p.x < PATH_R:
		return Surfaces.S.SAND
	# canyon boardwalk = pavement
	if p.y <= CANYON_Y0 and p.y >= CANYON_Y1 and p.x > PATH_L and p.x < PATH_R:
		return Surfaces.S.PAVEMENT
	# verge grass
	if p.x < PATH_L or p.x > PATH_R:
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
	# popcorn box or half churro
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
