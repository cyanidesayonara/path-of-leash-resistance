class_name Encants
extends RefCounted

# WALK: ELS ENCANTS (Mercat dels Encants at Glòries, rainy day)
#
# Barcelona's old flea market under its mirrored canopy:
# - Start on the wet street at Glòries, Torre Glòries a distant abstract tower.
# - Into the market under the canopy: lanes between stalls heaped with junk,
#   gentle floor ramps, stilts holding the mirror overhead.
# - The auction corner: a small open ring where a seller calls lots.
# - Out the far side into a little square for the off-leash finish.
#
# Rain falls beyond the canopy's edge and drips along it; under it the floor
# is dry. No chase, no boss.
#
# Signature live event: a tower of chairs / crates wobbles with a seller's
# "Watch out!", then spills across the lane. A planted dog holds your human
# clear; a slack leash lets them walk into it and risk their phone.

# the hooks main calls on this walk, held to it by tests/test_walk_hooks.gd
const HOOKS := ["draw_bollard", "draw_column", "draw_cross_section", "draw_edge_layer",
	"draw_freedom", "draw_live", "draw_overhead", "draw_snack", "idle_status", "is_lamp",
	"night_fronts", "on_bark", "surface", "tick", "tree_kind"]


const ShapeBatch := preload("res://systems/shape_batch.gd")
const Surfaces := preload("res://world/surfaces.gd")
const NightFronts := preload("res://world/night_fronts.gd")
const EventFeed := preload("res://hud/event_feed.gd")
const Outdoors := preload("res://systems/outdoors.gd")
const AnimClock := preload("res://systems/anim_clock.gd")
const Panot := preload("res://world/panot.gd")

const OVERHEAD_FOLLOWS_CAMERA := true

const CX := 640.0
const HALF := 290.0
const PATH_L := CX - HALF
const PATH_R := CX + HALF
const START := 260.0
const GATE := -5000.0
const SUN := Vector2(0.55, 0.83)
const SHADOW := Color(0.05, 0.05, 0.09, 0.24)

# --- colours ------------------------------------------------------------------
const WET_PAVE := Color(0.42, 0.46, 0.54)
const WET_SHINE := Color(0.62, 0.70, 0.82, 0.35)
const DRY_PAVE := Color(0.72, 0.70, 0.64)
const DRY_SHADE := Color(0.58, 0.56, 0.50)
const RAMP_DARK := Color(0.50, 0.48, 0.44)
const CANOPY_STEEL := Color(0.55, 0.58, 0.62)
const CANOPY_DARK := Color(0.28, 0.30, 0.34)
const MIRROR := Color(0.55, 0.62, 0.70, 0.22)
const MIRROR_STALL := Color(0.70, 0.45, 0.30, 0.18)
const STILT := Color(0.72, 0.74, 0.76)
const STILT_DARK := Color(0.40, 0.42, 0.46)
const STALL_WOOD := Color(0.48, 0.34, 0.22)
const STALL_TARP_A := Color(0.18, 0.42, 0.58)
const STALL_TARP_B := Color(0.72, 0.22, 0.28)
const STALL_TARP_C := Color(0.86, 0.70, 0.20)
const JUNK_A := Color(0.62, 0.58, 0.50)
const JUNK_B := Color(0.36, 0.40, 0.48)
const JUNK_C := Color(0.78, 0.52, 0.28)
const PUDDLE := Color(0.28, 0.40, 0.52, 0.55)
const DRIP := Color(0.70, 0.84, 0.96, 0.70)
const TORRE := Color(0.55, 0.78, 0.82)
const TORRE_DARK := Color(0.22, 0.38, 0.42)
const UMBRELLA_A := Color(0.16, 0.18, 0.24)
const UMBRELLA_B := Color(0.74, 0.16, 0.18)
const UMBRELLA_C := Color(0.18, 0.38, 0.62)
const AUCTION_RING := Color(0.82, 0.78, 0.68)
const CHAIR := Color(0.42, 0.30, 0.20)
const CRATE := Color(0.58, 0.42, 0.24)
const RECORD := Color(0.12, 0.12, 0.14)
const LAMP_POST := Color(0.32, 0.34, 0.38)
const PANOT_DRY_GROOVE := Color(0.14, 0.10, 0.06, 0.10)
const PANOT_DRY_SHINE := Color(1.0, 0.96, 0.88, 0.08)
const PANOT_WET_GROOVE := Color(0.0, 0.02, 0.06, 0.13)
const PANOT_WET_SHINE := Color(0.90, 0.94, 1.0, 0.10)

# --- route zones --------------------------------------------------------------
const STREET_END := -700.0
const CANOPY_Y0 := -700.0
const CANOPY_Y1 := -4300.0
const AUCTION_Y := -2800.0
const AUCTION_R := 78.0
const SPILL_Y := -2100.0
const SPILL_STALL := Vector2(PATH_R - 70.0, -2100.0)
const SPILL_RECT := Rect2(CX - 70.0, -2160.0, 160.0, 120.0)
const SPILL_WARN := 1.05
const SPILL_SLIDE := 1.45
const SPILL_FIRST_WAIT := 2.8
const DARE_POS := Vector2(520.0, -1650.0)
const PRIZE := Vector2(PATH_L + 55.0, -3400.0)
const PRIZE_TEXT := "nab the churro from the snack stall"
const SOCK_PICKUP := Vector2(PATH_R - 90.0, -1500.0)
const SOCK_DROP := Vector2(CX + 20.0, -2900.0)
const TORRE_POS := Vector2(1080.0, 40.0)

# Stilts under the canopy (poles the leash wraps; markable)
const STILTS: Array[Vector2] = [
	Vector2(PATH_L + 36.0, -820.0), Vector2(PATH_R - 36.0, -820.0),
	Vector2(PATH_L + 36.0, -1120.0), Vector2(PATH_R - 36.0, -1120.0),
	Vector2(PATH_L + 36.0, -1420.0), Vector2(PATH_R - 36.0, -1420.0),
	Vector2(PATH_L + 36.0, -1720.0), Vector2(PATH_R - 36.0, -1720.0),
	Vector2(PATH_L + 36.0, -2020.0), Vector2(PATH_R - 36.0, -2020.0),
	Vector2(PATH_L + 36.0, -2420.0), Vector2(PATH_R - 36.0, -2420.0),
	Vector2(PATH_L + 36.0, -2720.0), Vector2(PATH_R - 36.0, -2720.0),
	Vector2(PATH_L + 36.0, -3120.0), Vector2(PATH_R - 36.0, -3120.0),
	Vector2(PATH_L + 36.0, -3520.0), Vector2(PATH_R - 36.0, -3520.0),
	Vector2(PATH_L + 36.0, -3920.0), Vector2(PATH_R - 36.0, -3920.0),
	Vector2(PATH_L + 36.0, -4220.0), Vector2(PATH_R - 36.0, -4220.0),
]

const STREET_LAMPS: Array[Vector2] = [
	Vector2(PATH_L + 28.0, -80.0), Vector2(PATH_R - 28.0, -80.0),
	Vector2(PATH_L + 28.0, -320.0), Vector2(PATH_R - 28.0, -320.0),
	Vector2(PATH_L + 28.0, -560.0), Vector2(PATH_R - 28.0, -560.0),
]

# Stall solid blocks along the edges (center lane stays clear)
const STALL_SOLIDS: Array[Rect2] = [
	Rect2(PATH_L + 8.0, -980.0, 88.0, 70.0),
	Rect2(PATH_R - 96.0, -980.0, 88.0, 70.0),
	Rect2(PATH_L + 8.0, -1280.0, 88.0, 70.0),
	Rect2(PATH_R - 96.0, -1280.0, 88.0, 70.0),
	Rect2(PATH_L + 8.0, -1580.0, 88.0, 70.0),
	Rect2(PATH_R - 96.0, -1580.0, 88.0, 70.0),
	Rect2(PATH_L + 8.0, -1880.0, 88.0, 70.0),
	Rect2(PATH_R - 96.0, -1880.0, 88.0, 70.0),
	Rect2(PATH_L + 8.0, -2280.0, 88.0, 70.0),
	Rect2(PATH_R - 96.0, -2280.0, 88.0, 70.0),
	Rect2(PATH_L + 8.0, -2580.0, 88.0, 70.0),
	Rect2(PATH_R - 96.0, -2580.0, 88.0, 70.0),
	Rect2(PATH_L + 8.0, -3080.0, 88.0, 70.0),
	Rect2(PATH_R - 96.0, -3080.0, 88.0, 70.0),
	Rect2(PATH_L + 8.0, -3380.0, 88.0, 70.0),
	Rect2(PATH_R - 96.0, -3380.0, 88.0, 70.0),
	Rect2(PATH_L + 8.0, -3680.0, 88.0, 70.0),
	Rect2(PATH_R - 96.0, -3680.0, 88.0, 70.0),
	Rect2(PATH_L + 8.0, -3980.0, 88.0, 70.0),
	Rect2(PATH_R - 96.0, -3980.0, 88.0, 70.0),
]

# Gentle ramp bands (visual + surface shade); y centers
const RAMP_YS: Array[float] = [-1200.0, -1900.0, -2600.0, -3300.0, -4000.0]


static func _h(k: int) -> float:
	return fposmod(absf(sin(float(k) * 12.9898 + 4.13) * 43758.5453), 1.0)


static func _under_canopy(y: float) -> bool:
	return y <= CANOPY_Y0 and y >= CANOPY_Y1


static func _is_in(list: Array[Vector2], p: Vector2) -> bool:
	for q: Vector2 in list:
		if p.distance_squared_to(q) < 4.0:
			return true
	return false


# --- solids / poles / surfaces -----------------------------------------------

static func solids(_m: Node2D = null) -> Array[Rect2]:
	return STALL_SOLIDS.duplicate()


static func wrap_rects(_m: Node2D = null) -> Array[Rect2]:
	return solids()


static func tree_kind(m: Node2D, _p: Vector2) -> int:
	return m.TREE_NONE


static func is_lamp(_m: Node2D, p: Vector2) -> bool:
	return _is_in(STREET_LAMPS, p)


static func surface(m: Node2D, p: Vector2) -> int:
	if p.y < float(m.GATE_Y):
		# finish square
		if p.x < 200.0 or p.x > 1080.0:
			return Surfaces.S.GRASS
		return Surfaces.S.PAVEMENT
	if p.x < PATH_L - 8.0 or p.x > PATH_R + 8.0:
		return Surfaces.S.PAVEMENT
	# walkable corridor: dry under canopy, wet outside
	return Surfaces.S.PAVEMENT


# --- build -------------------------------------------------------------------

static func build(m: Node2D) -> Array:
	m.gate_text = "PLAÇA DELS ENCANTS"
	m.gate_l = 420.0
	m.gate_r = 860.0
	m.stalls.clear()
	m.stall_kinds.clear()
	m.astands = Array([], TYPE_VECTOR2, &"", null)
	m.manholes = Array([], TYPE_VECTOR2, &"", null)

	m.encants_spill = {"state": "idle", "t": SPILL_FIRST_WAIT, "saved": false, "hit": false, "wobble": 0.0, "slide": 0.0}
	m.encants_spill_held = 0
	m.encants_auction_barked = false
	m.encants_stilts_marked = {}
	m.encants_browsers = []

	for sp: Vector2 in STILTS:
		m.poles.append(sp)
	for lp: Vector2 in STREET_LAMPS:
		m.poles.append(lp)
	m.deco_pole_count = m.poles.size()

	m.benches = Array([
		Vector2(CX - 40.0, -480.0),
		Vector2(CX + 50.0, -2950.0),
		Vector2(CX - 30.0, -4500.0),
	], TYPE_VECTOR2, &"", null)

	m.bins = Array([
		Vector2(PATH_L + 50.0, -400.0),
		Vector2(PATH_R - 50.0, -1600.0),
		Vector2(PATH_L + 50.0, -3200.0),
		Vector2(PATH_R - 50.0, -4100.0),
	], TYPE_VECTOR2, &"", null)

	m.fountains = Array([Vector2(CX, -440.0)], TYPE_VECTOR2, &"", null)

	m.cone_spots = Array([
		Vector2(CX - 30.0, -900.0),
		Vector2(CX + 40.0, -3600.0),
	], TYPE_VECTOR2, &"", null)

	var weather: String = Game.weather
	var hour: String = Game.hour
	var fill := Outdoors.flea_browsers(weather, hour)
	for i in range(m.benches.size()):
		if _h(i * 19 + 7) < fill:
			var bp: Vector2 = m.benches[i]
			m.encants_browsers.append({"pos": bp + Vector2(0.0, -6.0), "face": Vector2.RIGHT, "key": 4600 + i * 13})

	# sniff spots on junk piles / hydrants along the stalls
	var hyd_list: Array[Vector2] = [
		Vector2(PATH_L + 110.0, -1000.0),
		Vector2(PATH_R - 110.0, -1300.0),
		Vector2(PATH_L + 110.0, -1600.0),
		Vector2(PATH_R - 110.0, -2300.0),
		Vector2(PATH_L + 110.0, -3100.0),
		Vector2(PATH_R - 110.0, -3700.0),
		Vector2(CX, -2850.0),
		Vector2(PATH_L + 110.0, -4000.0),
	]
	var keb_list: Array[Vector2] = [
		Vector2(CX - 20.0, -600.0),
		Vector2(CX + 30.0, -1800.0),
		Vector2(CX - 10.0, -2500.0),
		Vector2(CX + 20.0, -3500.0),
		Vector2(CX, -4200.0),
	]
	return [hyd_list, keb_list]


# --- per frame: spill event, auction proximity -------------------------------

static func tick(m: Node2D, delta: float) -> void:
	if m.phase == "freedom" or m.get("frozen") == true:
		return
	var dp: Vector2 = m.dog.global_position
	var hp: Vector2 = m.human.global_position
	var st: Dictionary = m.encants_spill
	if st.is_empty():
		st = {"state": "idle", "t": SPILL_FIRST_WAIT, "saved": false, "hit": false, "wobble": 0.0, "slide": 0.0}
	var state := String(st.get("state", "idle"))
	var t := float(st.get("t", 0.0))
	var near_spill := hp.y < -1800.0 and hp.y > -2500.0

	match state:
		"idle":
			st["wobble"] = move_toward(float(st.get("wobble", 0.0)), 0.0, delta * 2.0)
			st["slide"] = 0.0
			if near_spill and hp.y < SPILL_Y + 180.0:
				t -= delta
				if t <= 0.0:
					st["state"] = "telegraph"
					st["t"] = SPILL_WARN
					st["saved"] = false
					st["hit"] = false
					_sfx(m, "hiss", 0.55)
					m.feed.say(I18n.t("w_encants_stack_wobbling"), EventFeed.Tone.LOUD)
					if m.human.can_warn_external():
						m.human.notice(I18n.t("w_watch_out"), 1.1)
					m.float_text(SPILL_STALL + Vector2(-40.0, -40.0), I18n.t("w_watch_out"), Color(1.0, 0.85, 0.45), m.POP_SAY)
				else:
					st["t"] = t
		"telegraph":
			t -= delta
			var prog := clampf(1.0 - t / SPILL_WARN, 0.0, 1.0)
			st["wobble"] = prog
			st["t"] = t
			if t <= 0.0:
				st["state"] = "spilling"
				st["t"] = SPILL_SLIDE
				st["slide"] = 0.0
				_sfx(m, "poof", 0.7)
				m.feed.say(I18n.t("w_encants_spill"), EventFeed.Tone.LOUD)
		"spilling":
			t -= delta
			st["t"] = t
			st["slide"] = clampf(1.0 - t / SPILL_SLIDE, 0.0, 1.0)
			st["wobble"] = 1.0
			# planted dog near the spill holds your human clear of the slide
			var dog_planted := bool(m.dog.planted)
			var dog_near := dp.distance_to(SPILL_RECT.get_center()) < 110.0
			if dog_planted and dog_near and not bool(st.get("saved", false)) and not bool(st.get("hit", false)):
				st["saved"] = true
				m.encants_spill_held += 1
				m.award_points(4, I18n.t("w_encants_held_4"))
				m.feed.say(I18n.t("w_encants_nice_plant"), EventFeed.Tone.GOOD)
				_sfx(m, "pickup", 1.1)
			# slack leash: human walks into the spill
			if not bool(st.get("hit", false)) and not bool(st.get("saved", false)):
				if SPILL_RECT.has_point(hp):
					st["hit"] = true
					m.human.patience = maxf(0.0, m.human.patience - m.LIVE_EVENT_BUMP_PATIENCE)
					m.human.bumped(Vector2(-0.6, 0.2))
					m.float_text(hp + Vector2(0.0, -34.0), I18n.t("w_whoa_my_phone"), Color(1.0, 0.65, 0.55), m.POP_SAY)
					_sfx(m, "thump", 0.85)
			if t <= 0.0:
				st["state"] = "done"
				st["wobble"] = 0.0
		"done":
			st["slide"] = move_toward(float(st.get("slide", 1.0)), 0.35, delta * 0.4)
			st["wobble"] = 0.0

	m.encants_spill = st


static func idle_status(m: Node2D) -> String:
	var st: Dictionary = m.encants_spill
	if String(st.get("state", "")) == "telegraph":
		return I18n.t("walk_encants_spill")
	if String(st.get("state", "")) == "spilling":
		return I18n.t("walk_encants_spill_now")
	return ""


static func on_bark(m: Node2D, pos: Vector2) -> void:
	if pos.distance_to(Vector2(CX, AUCTION_Y)) < 140.0 and not m.encants_auction_barked:
		m.encants_auction_barked = true
		m.bones += 3
		m.award_points(3, I18n.t("w_encants_auction_3"))
		m.float_text(Vector2(CX, AUCTION_Y) + Vector2(0.0, -40.0), I18n.t("w_sold"), Color(0.95, 0.85, 0.40))
		m.feed.say(I18n.t("w_encants_auction_bark"), EventFeed.Tone.GOOD)
		_sfx(m, "prize", 1.05)


static func _sfx(m: Node2D, name: String, pitch: float) -> void:
	if m.has_node("/root/Sfx"):
		m.get_node("/root/Sfx").play(name, pitch)


# --- drawing: edge layer (street, torre, umbrellas) --------------------------

static func draw_edge_layer(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	var top: float = maxf(vt, float(m.GATE_Y) - 40.0)
	var bot: float = minf(vb, float(m.START_Y) + 560.0)
	if bot <= top:
		return
	var was := b.lod
	b.lod = true
	# city blocks either side
	b.rect(Rect2(-420.0, top, PATH_L + 420.0, bot - top), Color(0.28, 0.30, 0.36))
	b.rect(Rect2(PATH_R, top, 1740.0 - PATH_R, bot - top), Color(0.30, 0.32, 0.38))
	# wet street flanks south of the canopy
	if bot > STREET_END:
		var s_lo := maxf(top, STREET_END)
		b.rect(Rect2(-420.0, s_lo, PATH_L + 420.0, bot - s_lo), Color(0.34, 0.38, 0.46))
		b.rect(Rect2(PATH_R, s_lo, 1740.0 - PATH_R, bot - s_lo), Color(0.34, 0.38, 0.46))
		# Torre Glòries: distant abstract cylinder stack (no branding)
		if TORRE_POS.y >= vt - 200.0 and TORRE_POS.y <= vb + 400.0:
			_draw_torre(b, TORRE_POS)
		# umbrellas outside in the rain
		if Game.weather == "rain" or Game.weather == "snow":
			for i in range(8):
				var uy := -40.0 - float(i) * 80.0
				if uy < STREET_END:
					break
				if uy < vt - 40.0 or uy > vb + 40.0:
					continue
				var ux := PATH_R + 40.0 + _h(i * 11) * 60.0
				_draw_umbrella(b, Vector2(ux, uy), i)
				var ux2 := PATH_L - 40.0 - _h(i * 17) * 50.0
				_draw_umbrella(b, Vector2(ux2, uy + 30.0), i + 3)
	# market flank walls under canopy: stall backs
	if top < CANOPY_Y0 and bot > CANOPY_Y1:
		var m_lo := maxf(top, CANOPY_Y1)
		var m_hi := minf(bot, CANOPY_Y0)
		b.rect(Rect2(-420.0, m_lo, PATH_L + 420.0, m_hi - m_lo), Color(0.40, 0.36, 0.32))
		b.rect(Rect2(PATH_R, m_lo, 1740.0 - PATH_R, m_hi - m_lo), Color(0.40, 0.36, 0.32))
	b.lod = was


static func _draw_torre(b: ShapeBatch, p: Vector2) -> void:
	# distant bullet-shaped tower: stacked ovals, glass tint, no logos
	b.circle(p + Vector2(4.0, 8.0), 38.0, SHADOW)
	b.rect(Rect2(p.x - 22.0, p.y - 180.0, 44.0, 190.0), TORRE_DARK)
	b.rect(Rect2(p.x - 18.0, p.y - 176.0, 36.0, 182.0), TORRE)
	b.glow(p + Vector2(0.0, -100.0), 48.0, Color(0.70, 0.90, 0.92, 0.25))
	b.circle(p + Vector2(0.0, -188.0), 20.0, TORRE.lightened(0.15))
	b.circle(p + Vector2(-4.0, -196.0), 10.0, Color(0.85, 0.95, 0.96, 0.5))


static func _draw_umbrella(b: ShapeBatch, p: Vector2, seed_i: int) -> void:
	var cols := [UMBRELLA_A, UMBRELLA_B, UMBRELLA_C]
	var col: Color = cols[seed_i % cols.size()]
	b.circle(p + Vector2(2.0, 3.0), 14.0, SHADOW)
	b.circle(p, 13.0, col)
	b.circle(p - Vector2(3.0, 3.0), 7.0, col.lightened(0.2))
	b.line(p, p + Vector2(0.0, 16.0), Color(0.20, 0.16, 0.12), 2.0)


# --- cross section: floor, stalls, stilts, auction, ramps --------------------

static func draw_cross_section(m: Node2D, wc: ShapeBatch, _top: float, _bottom: float, ctop: float, vt: float, vb: float) -> void:
	var keep_lod := wc.lod
	wc.lod = true
	var lo := maxf(vt - 40.0, maxf(ctop, float(m.GATE_Y) - 40.0))
	var hi := minf(vb + 40.0, float(m.START_Y) + 560.0)
	if hi > lo:
		_draw_floor(wc, lo, hi)
		_draw_ramps(wc, lo, hi)
		_draw_stalls(wc, lo, hi)
		_draw_stilts(wc, lo, hi)
		_draw_auction(wc, lo, hi)
		_draw_spill_stack_static(wc, lo, hi)
		_draw_edge_puddles(wc, lo, hi)
	wc.lod = keep_lod


static func _draw_floor(wc: ShapeBatch, lo: float, hi: float) -> void:
	var step := Panot.FLOR
	var y := floorf(lo / step) * step
	while y < hi:
		var mid := y + step * 0.5
		var dry := _under_canopy(mid)
		var col := DRY_PAVE if dry else WET_PAVE
		wc.rect(Rect2(PATH_L, y, HALF * 2.0, step + 0.5), col)
		if dry:
			Panot.flor_row(wc, PATH_L + 4.0, PATH_R - 4.0, y, PATH_L + 4.0, PANOT_DRY_GROOVE, PANOT_DRY_SHINE)
		else:
			# wet sheen strips
			if int(absf(y) / step) % 2 == 0:
				wc.rect(Rect2(PATH_L + 20.0, y + 4.0, HALF * 2.0 - 40.0, 3.0), WET_SHINE)
			Panot.flor_row(wc, PATH_L + 4.0, PATH_R - 4.0, y, PATH_L + 4.0, PANOT_WET_GROOVE, PANOT_WET_SHINE)
		y += step


static func _draw_ramps(wc: ShapeBatch, lo: float, hi: float) -> void:
	for ry: float in RAMP_YS:
		if ry < lo - 80.0 or ry > hi + 80.0:
			continue
		# gentle darker band reading as a floor rise / fall
		wc.band(PackedVector2Array([
			Vector2(PATH_L + 8.0, ry - 50.0), Vector2(PATH_R - 8.0, ry - 50.0),
			Vector2(PATH_L + 8.0, ry + 50.0), Vector2(PATH_R - 8.0, ry + 50.0),
		]), 2, RAMP_DARK, PackedFloat32Array([0.0, 0.55]), PackedFloat32Array([0.55, 0.0]))


static func _draw_stalls(wc: ShapeBatch, lo: float, hi: float) -> void:
	for i in range(STALL_SOLIDS.size()):
		var r: Rect2 = STALL_SOLIDS[i]
		if r.end.y < lo - 20.0 or r.position.y > hi + 20.0:
			continue
		var tarp: Color = [STALL_TARP_A, STALL_TARP_B, STALL_TARP_C][i % 3]
		wc.rect(Rect2(r.position + SUN * 5.0, r.size), SHADOW)
		wc.rect(r, STALL_WOOD)
		wc.rect(Rect2(r.position.x + 4.0, r.position.y + 4.0, r.size.x - 8.0, 14.0), tarp)
		# junk heap on the stall
		var c := r.get_center()
		wc.circle(c + Vector2(-10.0, 8.0), 10.0, JUNK_A)
		wc.circle(c + Vector2(8.0, 6.0), 8.0, JUNK_B)
		wc.circle(c + Vector2(0.0, 14.0), 7.0, JUNK_C)
		# records / lamp / crockery hints
		if i % 4 == 0:
			wc.circle(c + Vector2(-6.0, 2.0), 6.0, RECORD)
			wc.circle(c + Vector2(-6.0, 2.0), 2.0, Color(0.85, 0.85, 0.80))
		elif i % 4 == 1:
			wc.rect(Rect2(c.x + 4.0, c.y - 2.0, 10.0, 6.0), Color(0.70, 0.68, 0.55))
			wc.circle(c + Vector2(9.0, -6.0), 5.0, Color(0.90, 0.85, 0.55, 0.7))
		elif i % 4 == 2:
			wc.rect(Rect2(c.x - 14.0, c.y + 4.0, 16.0, 10.0), Color(0.55, 0.30, 0.22))
		else:
			wc.circle(c + Vector2(10.0, 10.0), 5.0, Color(0.80, 0.82, 0.78))
			wc.circle(c + Vector2(4.0, 12.0), 4.0, Color(0.70, 0.55, 0.40))


static func _draw_stilts(wc: ShapeBatch, lo: float, hi: float) -> void:
	for sp: Vector2 in STILTS:
		if sp.y < lo - 30.0 or sp.y > hi + 30.0:
			continue
		wc.circle(sp + SUN * 6.0, 12.0, SHADOW)
		wc.circle(sp, 11.0, STILT_DARK)
		wc.circle(sp - Vector2(2.0, 2.0), 8.0, STILT)
		wc.rect(Rect2(sp.x - 4.0, sp.y - 4.0, 8.0, 8.0), CANOPY_STEEL)


static func _draw_auction(wc: ShapeBatch, lo: float, hi: float) -> void:
	if AUCTION_Y < lo - 100.0 or AUCTION_Y > hi + 100.0:
		return
	var c := Vector2(CX, AUCTION_Y)
	# open ring on the floor
	wc.circle(c + SUN * 4.0, AUCTION_R + 4.0, SHADOW)
	wc.circle(c, AUCTION_R, AUCTION_RING)
	wc.circle(c, AUCTION_R - 10.0, DRY_PAVE)
	# lot pile in the middle
	wc.circle(c + Vector2(-8.0, 4.0), 14.0, JUNK_A)
	wc.circle(c + Vector2(10.0, 2.0), 12.0, JUNK_B)
	wc.rect(Rect2(c.x - 16.0, c.y - 8.0, 20.0, 14.0), CRATE)
	# seller at the north edge of the ring
	var seller := c + Vector2(0.0, -AUCTION_R + 8.0)
	wc.circle(seller + Vector2(2.0, 3.0), 9.0, SHADOW)
	wc.circle(seller, 8.0, Color(0.30, 0.28, 0.40))
	wc.circle(seller + Vector2(-1.0, -2.0), 5.0, Color(0.85, 0.68, 0.54))


static func _draw_spill_stack_static(wc: ShapeBatch, lo: float, hi: float) -> void:
	# resting chair tower + seller (animated spill is drawn live)
	if SPILL_Y < lo - 80.0 or SPILL_Y > hi + 80.0:
		return
	var base := SPILL_STALL
	for k in range(4):
		var p := base + Vector2(0.0, -float(k) * 12.0)
		wc.rect(Rect2(p.x - 14.0, p.y - 6.0, 28.0, 12.0), CHAIR if k % 2 == 0 else CRATE)
	var seller := base + Vector2(24.0, 8.0)
	wc.circle(seller + Vector2(2.0, 3.0), 8.0, SHADOW)
	wc.circle(seller, 7.5, Color(0.35, 0.32, 0.28))
	wc.circle(seller + Vector2(-1.0, -2.0), 4.5, Color(0.85, 0.68, 0.54))


static func _draw_edge_puddles(wc: ShapeBatch, lo: float, hi: float) -> void:
	# puddles at the canopy's drip line (outside edge)
	for side: float in [-1.0, 1.0]:
		var x := (PATH_L - 8.0) if side < 0.0 else (PATH_R + 8.0)
		var y := CANOPY_Y0
		while y > CANOPY_Y1:
			if y >= lo - 20.0 and y <= hi + 20.0:
				var k := int(absf(y) / 90.0)
				if k % 2 == 0:
					wc.glow(Vector2(x + side * 10.0, y), 16.0 + _h(k) * 8.0, PUDDLE)
			y -= 90.0


# --- overhead: mirrored canopy -----------------------------------------------

static func draw_overhead(m: Node2D, ci: Object) -> void:
	var b := ShapeBatch.new(ci)
	b.lod = true
	var vt: float = m.view_lo(160.0) if m.has_method("view_lo") else -6000.0
	var vb: float = m.view_hi(160.0) if m.has_method("view_hi") else 600.0
	var lo := maxf(vt - 40.0, CANOPY_Y1)
	var hi := minf(vb + 40.0, CANOPY_Y0)
	if hi > lo:
		# canopy plate
		b.rect(Rect2(PATH_L - 30.0, lo, HALF * 2.0 + 60.0, hi - lo), Color(CANOPY_DARK.r, CANOPY_DARK.g, CANOPY_DARK.b, 0.35))
		# dim warped reflection of stalls (ghostly blobs, not a copy)
		var sy := floorf(lo / 160.0) * 160.0
		var si := 0
		while sy < hi:
			if sy >= CANOPY_Y1 and sy <= CANOPY_Y0:
				var wx := PATH_L + 50.0 + _h(si * 7) * 40.0
				var ex := PATH_R - 50.0 - _h(si * 11) * 40.0
				var warp := sin(sy * 0.01 + float(si)) * 18.0
				b.glow(Vector2(wx + warp, sy - 20.0), 28.0, MIRROR_STALL)
				b.glow(Vector2(ex - warp, sy - 20.0), 26.0, MIRROR)
				b.glow(Vector2(CX + warp * 0.5, sy - 30.0), 22.0, Color(0.50, 0.55, 0.60, 0.12))
			sy += 160.0
			si += 1
		# stilts continuing up into the canopy
		for sp: Vector2 in STILTS:
			if sp.y >= lo - 20.0 and sp.y <= hi + 20.0:
				b.line(sp, sp + Vector2(0.0, -40.0), STILT_DARK, 5.0)
				b.circle(sp + Vector2(0.0, -42.0), 6.0, CANOPY_STEEL)
		# drip line along canopy edges when raining
		if Game.weather == "rain" or Game.weather == "snow":
			var tsec := float(AnimClock.msec()) * 0.001
			for side: float in [-1.0, 1.0]:
				var x := (PATH_L - 6.0) if side < 0.0 else (PATH_R + 6.0)
				var dy := lo
				var di := 0
				while dy < hi:
					var phase := fposmod(tsec * 2.4 + float(di) * 0.37, 1.0)
					var drop_y := dy + phase * 70.0
					if drop_y < hi:
						b.circle(Vector2(x, drop_y), 2.2, DRIP)
					dy += 55.0
					di += 1
	b.flush()


# --- live layer: browsers, spill motion already in cross-section via state ---

static func draw_live(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	# browsers on benches
	for br: Dictionary in m.encants_browsers:
		var p: Vector2 = br["pos"]
		if p.y < vt - 40.0 or p.y > vb + 40.0:
			continue
		b.circle(p + Vector2(2.0, 3.0), 9.0, SHADOW)
		b.circle(p, 8.0, Color(0.35, 0.40, 0.50))
		b.circle(p + Vector2(-1.0, -2.0), 5.0, Color(0.85, 0.68, 0.54))
		if not _under_canopy(p.y) and (Game.weather == "rain" or Game.weather == "snow"):
			b.circle(p + Vector2(0.0, -10.0), 12.0, UMBRELLA_A)
	# auction arm wave
	if AUCTION_Y >= vt - 60.0 and AUCTION_Y <= vb + 60.0:
		var wave := sin(float(AnimClock.msec()) * 0.006) * 6.0
		var seller := Vector2(CX, AUCTION_Y - AUCTION_R + 8.0)
		b.line(seller, seller + Vector2(10.0 + wave, -12.0), Color(0.85, 0.68, 0.54), 2.5)
	# spill wobble / slide over the resting stack
	if SPILL_Y >= vt - 80.0 and SPILL_Y <= vb + 80.0:
		var st: Dictionary = m.encants_spill
		var state := String(st.get("state", "idle"))
		var wob := float(st.get("wobble", 0.0))
		var slide := float(st.get("slide", 0.0))
		var base := SPILL_STALL
		var shake := sin(float(AnimClock.msec()) * 0.04) * wob * 4.0
		if state == "telegraph":
			for k in range(4):
				var p := base + Vector2(shake * (1.0 if k % 2 == 0 else -1.0), -float(k) * 12.0)
				b.rect(Rect2(p.x - 14.0, p.y - 6.0, 28.0, 12.0), Color(0.95, 0.85, 0.40, 0.55))
		elif state == "spilling" or state == "done":
			for k in range(6):
				var along := slide * (40.0 + float(k) * 22.0)
				var p := base + Vector2(-along + shake * 0.3, float(k % 3) * 10.0 - 10.0)
				if k % 3 == 0:
					b.rect(Rect2(p.x - 12.0, p.y - 5.0, 24.0, 10.0), CHAIR)
				elif k % 3 == 1:
					b.rect(Rect2(p.x - 10.0, p.y - 6.0, 20.0, 12.0), CRATE)
				else:
					b.circle(p, 7.0, RECORD)


static func draw_freedom(m: Node2D, c: Object) -> void:
	var r: Rect2 = m._freedom_rect()
	var b := ShapeBatch.new()
	b.rect(Rect2(r.position.x - 40.0, r.position.y - 40.0, r.size.x + 80.0, r.size.y + 80.0), Color(0.55, 0.58, 0.52))
	b.rect(r, DRY_PAVE)
	Panot.flor(b, r.position.x + 10.0, r.end.x - 10.0, r.position.y + 10.0, r.end.y - 10.0, PANOT_DRY_GROOVE, PANOT_DRY_SHINE)
	# little square planters
	for i in range(4):
		var px := lerpf(r.position.x + 40.0, r.end.x - 40.0, float(i) / 3.0)
		var py := r.position.y + 50.0
		b.rect(Rect2(px - 14.0, py - 14.0, 28.0, 28.0), Color(0.45, 0.40, 0.32))
		b.circle(Vector2(px, py), 10.0, Color(0.28, 0.48, 0.30))
	b.flush(c)
	if m.has_method("_draw_freedom_benches"):
		m._draw_freedom_benches(c, r, STALL_WOOD)


static func draw_bollard(m: Node2D, wc: ShapeBatch, h) -> void:
	# Barcelona pilona at a marking spot
	var p: Vector2 = h.pos
	wc.circle(p + SUN * 4.0, 9.0, SHADOW)
	wc.circle(p, 8.0, Color(0.78, 0.72, 0.55) if not h.done else Color(0.58, 0.54, 0.42))
	wc.circle(p - Vector2(1.0, 1.0), 5.0, Color(0.90, 0.86, 0.70))
	wc.rect(Rect2(p.x - 3.0, p.y - 3.0, 6.0, 6.0), Color(0.55, 0.50, 0.40))
	if not h.done and h.progress > 0.0:
		wc.draw_arc(p, 17.0, -PI / 2.0, -PI / 2.0 + TAU * h.progress / 0.8, 20, Color(1, 0.95, 0.7), 3.0)


static func draw_column(_m: Node2D, wc: ShapeBatch, p: Vector2) -> void:
	# canopy stilt as a deco pole
	wc.circle(p + SUN * 5.0, 11.0, SHADOW)
	wc.circle(p, 10.0, STILT_DARK)
	wc.circle(p - Vector2(2.0, 2.0), 7.0, STILT)


static func draw_snack(m: Node2D, wc: ShapeBatch, kp: Vector2) -> void:
	m.contact_shadow(wc, kp, 9.0, 3.0, 0.20)
	wc.circle(kp, 7.0, Color(0.86, 0.62, 0.28))
	wc.line(kp + Vector2(-4.0, 0.0), kp + Vector2(4.0, -2.0), Color(0.95, 0.85, 0.55), 3.0)


# --- night fronts ------------------------------------------------------------

static func night_fronts(_m: Node2D) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var y := -100.0
	var j := 0
	while y > STREET_END + 40.0:
		var kind := NightFronts.kind_of(4600 + j)
		if kind != "":
			out.append(NightFronts.front(Vector2(PATH_R + 4.0, y), -1.0, kind, 4600 + j))
		y -= 200.0
		j += 1
	return out
