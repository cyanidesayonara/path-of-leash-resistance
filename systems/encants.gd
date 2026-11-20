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
const NpcFigure := preload("res://entities/npc_figure.gd")
const SkyLook := preload("res://systems/sky.gd")

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
const PAVE_DRY := Color(0.72, 0.70, 0.65)
const PAVE_WET := Color(0.44, 0.47, 0.53)
const PAVE_SNOW := Color(0.82, 0.84, 0.88)
const CONC := Color(0.67, 0.64, 0.59)
const CONC_JOINT := Color(0.30, 0.27, 0.24, 0.28)
const PITCH_PAINT := Color(0.90, 0.72, 0.18, 0.55)
const ASPHALT := Color(0.30, 0.31, 0.33)
const ASPHALT_WET := Color(0.20, 0.22, 0.26)
const TRAM_GRASS := Color(0.36, 0.52, 0.28)
const RAIL_COL := Color(0.46, 0.46, 0.48)
const KERB := Color(0.74, 0.72, 0.68)
const OFFICE_WALL := Color(0.62, 0.64, 0.66)
const OFFICE_ROOF := Color(0.52, 0.53, 0.54)
const OFFICE_GLASS := Color(0.36, 0.50, 0.60)
const CANOPY_STEEL := Color(0.62, 0.65, 0.68)
const CANOPY_DARK := Color(0.26, 0.28, 0.32)
const STILT := Color(0.74, 0.76, 0.78)
const STILT_DARK := Color(0.38, 0.40, 0.44)
const STALL_WOOD := Color(0.48, 0.34, 0.22)
const CHAIR := Color(0.42, 0.30, 0.20)
const CRATE := Color(0.58, 0.42, 0.24)
const RECORD := Color(0.10, 0.10, 0.12)
const DRIP := Color(0.70, 0.84, 0.96, 0.75)
const LAMP_POST := Color(0.32, 0.34, 0.38)
const TORRE_DARK := Color(0.16, 0.20, 0.26)
const AUCTION_TIMBER := Color(0.72, 0.54, 0.32)
const AUCTION_ROPE := Color(0.62, 0.14, 0.14)
const TERRAT := Color(0.74, 0.46, 0.32)
const PANOT_DRY_GROOVE := Color(0.14, 0.10, 0.06, 0.10)
const PANOT_DRY_SHINE := Color(1.0, 0.96, 0.88, 0.08)
const PANOT_WET_GROOVE := Color(0.0, 0.02, 0.06, 0.13)
const PANOT_WET_SHINE := Color(0.90, 0.94, 1.0, 0.10)

# the tower's cladding: its reds, blues and greys
const TORRE_PANELS: Array[Color] = [Color(0.62, 0.18, 0.20), Color(0.80, 0.34, 0.26), Color(0.20, 0.36, 0.62),
	Color(0.30, 0.52, 0.72), Color(0.52, 0.56, 0.60), Color(0.70, 0.72, 0.74), Color(0.40, 0.44, 0.50)]
const TORRE_NIGHT: Array[Color] = [Color(0.90, 0.20, 0.50), Color(0.30, 0.40, 1.0), Color(0.20, 0.80, 0.90), Color(0.70, 0.30, 0.95)]
const UMBRELLAS: Array[Color] = [Color(0.14, 0.15, 0.20), Color(0.76, 0.16, 0.18), Color(0.18, 0.38, 0.66),
	Color(0.92, 0.74, 0.20), Color(0.24, 0.50, 0.34), Color(0.56, 0.24, 0.52), Color(0.86, 0.86, 0.84)]
const AWNINGS: Array[Color] = [Color(0.76, 0.20, 0.20), Color(0.18, 0.46, 0.32), Color(0.16, 0.26, 0.48),
	Color(0.88, 0.62, 0.16), Color(0.90, 0.86, 0.74), Color(0.90, 0.44, 0.16), Color(0.10, 0.52, 0.56),
	Color(0.50, 0.22, 0.44), Color(0.18, 0.44, 0.74)]
const TARPS: Array[Color] = [Color(0.20, 0.42, 0.70), Color(0.32, 0.46, 0.30), Color(0.56, 0.54, 0.50),
	Color(0.74, 0.62, 0.34), Color(0.62, 0.30, 0.24)]
const CLOTHS: Array[Color] = [Color(0.86, 0.82, 0.72), Color(0.66, 0.24, 0.22), Color(0.24, 0.36, 0.52),
	Color(0.38, 0.52, 0.36), Color(0.82, 0.66, 0.36), Color(0.52, 0.40, 0.56)]
const WOODS: Array[Color] = [Color(0.44, 0.28, 0.16), Color(0.58, 0.40, 0.22), Color(0.70, 0.54, 0.34), Color(0.34, 0.22, 0.14)]
const CHAIRS_COLS: Array[Color] = [Color(0.52, 0.34, 0.18), Color(0.70, 0.52, 0.30), Color(0.70, 0.22, 0.18),
	Color(0.26, 0.44, 0.38), Color(0.88, 0.84, 0.74), Color(0.36, 0.24, 0.14), Color(0.22, 0.34, 0.56)]
const SHADES: Array[Color] = [Color(0.94, 0.88, 0.72), Color(0.86, 0.56, 0.52), Color(0.36, 0.58, 0.40),
	Color(0.90, 0.70, 0.30), Color(0.74, 0.80, 0.84)]
const RUG_COLS: Array[Color] = [Color(0.62, 0.18, 0.16), Color(0.20, 0.26, 0.46), Color(0.78, 0.60, 0.34),
	Color(0.32, 0.42, 0.36), Color(0.50, 0.20, 0.28), Color(0.88, 0.82, 0.68)]
const SLEEVES: Array[Color] = [Color(0.86, 0.24, 0.20), Color(0.94, 0.86, 0.70), Color(0.18, 0.30, 0.60),
	Color(0.96, 0.72, 0.16), Color(0.14, 0.14, 0.16), Color(0.30, 0.62, 0.52), Color(0.76, 0.40, 0.62)]
const SPINES: Array[Color] = [Color(0.56, 0.16, 0.14), Color(0.18, 0.28, 0.46), Color(0.24, 0.40, 0.26),
	Color(0.80, 0.70, 0.46), Color(0.36, 0.24, 0.16), Color(0.90, 0.88, 0.80), Color(0.60, 0.44, 0.20)]
const GARMENTS: Array[Color] = [Color(0.80, 0.22, 0.24), Color(0.20, 0.32, 0.58), Color(0.92, 0.90, 0.84),
	Color(0.24, 0.24, 0.26), Color(0.86, 0.64, 0.20), Color(0.36, 0.54, 0.40), Color(0.70, 0.46, 0.62),
	Color(0.50, 0.36, 0.24)]
const TRINKETS: Array[Color] = [Color(0.22, 0.42, 0.70), Color(0.78, 0.30, 0.20), Color(0.86, 0.74, 0.30),
	Color(0.30, 0.56, 0.44), Color(0.92, 0.90, 0.84), Color(0.58, 0.30, 0.52), Color(0.70, 0.62, 0.52)]
const BIKES: Array[Color] = [Color(0.18, 0.40, 0.66), Color(0.72, 0.16, 0.16), Color(0.24, 0.44, 0.30), Color(0.86, 0.82, 0.70)]
const PLATES: Array[Color] = [Color(0.94, 0.92, 0.86), Color(0.70, 0.82, 0.90), Color(0.92, 0.86, 0.62)]
const UPHOLSTERY: Array[Color] = [Color(0.52, 0.20, 0.22), Color(0.30, 0.46, 0.40), Color(0.80, 0.70, 0.52), Color(0.36, 0.38, 0.56)]
const BLOCK_WALLS: Array[Color] = [Color(0.80, 0.74, 0.64), Color(0.74, 0.62, 0.52), Color(0.86, 0.82, 0.74),
	Color(0.70, 0.66, 0.62), Color(0.82, 0.68, 0.54)]
const ROOF_TILES: Array[Color] = [Color(0.70, 0.36, 0.24), Color(0.62, 0.32, 0.22), Color(0.74, 0.44, 0.30)]
const LAUNDRY: Array[Color] = [Color(0.94, 0.94, 0.92), Color(0.40, 0.56, 0.80), Color(0.86, 0.40, 0.40), Color(0.92, 0.80, 0.40)]
# the canopy's mirror: steel, a warm cast from the stalls below, a cool one from the sky
const MIRRORS: Array[Color] = [Color(0.50, 0.54, 0.58), Color(0.66, 0.52, 0.36), Color(0.46, 0.36, 0.30),
	Color(0.40, 0.48, 0.58), Color(0.72, 0.62, 0.48), Color(0.34, 0.38, 0.44), Color(0.58, 0.40, 0.34)]
# how solid the canopy's facets are going out from the lane's edge
const FACET_ALPHA: Array[float] = [0.30, 0.46, 0.58, 0.66, 0.70]

# --- route zones --------------------------------------------------------------
const STREET_END := -700.0
const CANOPY_Y0 := -700.0
const CANOPY_Y1 := -4300.0
const AUCTION_Y := -2800.0
const AUCTION_R := 78.0
const SPILL_Y := -2100.0
const SPILL_STALL := Vector2(CX + 120.0, -2100.0)
const SPILL_RECT := Rect2(CX - 40.0, -2160.0, 200.0, 120.0)
const SPILL_WARN := 1.05
const SPILL_SLIDE := 1.45
const SPILL_FIRST_WAIT := 2.8
const DARE_POS := Vector2(520.0, -1650.0)
const PRIZE := Vector2(PATH_L + 55.0, -3400.0)
const PRIZE_TEXT := "nab the churro from the snack stall"
const SOCK_PICKUP := Vector2(PATH_R - 90.0, -1500.0)
const SOCK_DROP := Vector2(CX + 20.0, -2900.0)
const TORRE_POS := Vector2(1072.0, -10.0)
const TORRE_R := 92.0
const COVER_FADE := 160.0
const COVER_TINT := 0.75
const WALKERS := 16

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

# Stall solid blocks packed along both edges (center lane stays clear)
const STALL_SOLIDS: Array[Rect2] = [
	Rect2(PATH_L + 6.0, -860.0, 92.0, 64.0), Rect2(PATH_R - 98.0, -860.0, 92.0, 64.0),
	Rect2(PATH_L + 6.0, -980.0, 92.0, 64.0), Rect2(PATH_R - 98.0, -980.0, 92.0, 64.0),
	Rect2(PATH_L + 6.0, -1100.0, 92.0, 64.0), Rect2(PATH_R - 98.0, -1100.0, 92.0, 64.0),
	Rect2(PATH_L + 6.0, -1220.0, 92.0, 64.0), Rect2(PATH_R - 98.0, -1220.0, 92.0, 64.0),
	Rect2(PATH_L + 6.0, -1340.0, 92.0, 64.0), Rect2(PATH_R - 98.0, -1340.0, 92.0, 64.0),
	Rect2(PATH_L + 6.0, -1460.0, 92.0, 64.0), Rect2(PATH_R - 98.0, -1460.0, 92.0, 64.0),
	Rect2(PATH_L + 6.0, -1580.0, 92.0, 64.0), Rect2(PATH_R - 98.0, -1580.0, 92.0, 64.0),
	Rect2(PATH_L + 6.0, -1700.0, 92.0, 64.0), Rect2(PATH_R - 98.0, -1700.0, 92.0, 64.0),
	Rect2(PATH_L + 6.0, -1820.0, 92.0, 64.0), Rect2(PATH_R - 98.0, -1820.0, 92.0, 64.0),
	Rect2(PATH_L + 6.0, -1940.0, 92.0, 64.0), Rect2(PATH_R - 98.0, -1940.0, 92.0, 64.0),
	Rect2(PATH_L + 6.0, -2240.0, 92.0, 64.0), Rect2(PATH_R - 98.0, -2240.0, 92.0, 64.0),
	Rect2(PATH_L + 6.0, -2360.0, 92.0, 64.0), Rect2(PATH_R - 98.0, -2360.0, 92.0, 64.0),
	Rect2(PATH_L + 6.0, -2480.0, 92.0, 64.0), Rect2(PATH_R - 98.0, -2480.0, 92.0, 64.0),
	Rect2(PATH_L + 6.0, -2600.0, 92.0, 64.0), Rect2(PATH_R - 98.0, -2600.0, 92.0, 64.0),
	Rect2(PATH_L + 6.0, -3000.0, 92.0, 64.0), Rect2(PATH_R - 98.0, -3000.0, 92.0, 64.0),
	Rect2(PATH_L + 6.0, -3120.0, 92.0, 64.0), Rect2(PATH_R - 98.0, -3120.0, 92.0, 64.0),
	Rect2(PATH_L + 6.0, -3240.0, 92.0, 64.0), Rect2(PATH_R - 98.0, -3240.0, 92.0, 64.0),
	Rect2(PATH_L + 6.0, -3360.0, 92.0, 64.0), Rect2(PATH_R - 98.0, -3360.0, 92.0, 64.0),
	Rect2(PATH_L + 6.0, -3480.0, 92.0, 64.0), Rect2(PATH_R - 98.0, -3480.0, 92.0, 64.0),
	Rect2(PATH_L + 6.0, -3600.0, 92.0, 64.0), Rect2(PATH_R - 98.0, -3600.0, 92.0, 64.0),
	Rect2(PATH_L + 6.0, -3720.0, 92.0, 64.0), Rect2(PATH_R - 98.0, -3720.0, 92.0, 64.0),
	Rect2(PATH_L + 6.0, -3840.0, 92.0, 64.0), Rect2(PATH_R - 98.0, -3840.0, 92.0, 64.0),
	Rect2(PATH_L + 6.0, -3960.0, 92.0, 64.0), Rect2(PATH_R - 98.0, -3960.0, 92.0, 64.0),
	Rect2(PATH_L + 6.0, -4080.0, 92.0, 64.0), Rect2(PATH_R - 98.0, -4080.0, 92.0, 64.0),
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
	# street, market floor and Plaça dels Encants are all pavement
	if p.y < float(m.GATE_Y):
		return Surfaces.S.PAVEMENT
	if p.x < PATH_L - 8.0 or p.x > PATH_R + 8.0:
		return Surfaces.S.PAVEMENT
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
	_apply_cover(m)
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

# --- the rain under the canopy -------------------------------------------------

# How far under the canopy the pair is, 0 on the open street to 1 well inside.
static func cover_at(y: float) -> float:
	return clampf((CANOPY_Y0 - y) / COVER_FADE, 0.0, 1.0) * clampf((y - CANOPY_Y1) / COVER_FADE, 0.0, 1.0)


# The rain on the screen fades out as the pair walks in under the roof and back
# as they come out the far side (the same trick as the metro's stairs).
static func _apply_cover(m: Node2D) -> void:
	if m.get("weather_fx") == null:
		return
	var u := 0.0
	if m.phase != "freedom":
		u = cover_at((m.dog.global_position.y + m.human.global_position.y) * 0.5)
	var was := float(m.get_meta("encants_cover", -1.0))
	if absf(u - was) < 0.01:
		return
	m.set_meta("encants_cover", u)
	m.weather_fx.modulate.a = 1.0 - u
	m.weather_fx.visible = u < 0.98
	# under the roof the light is the day's, half out of the rain's cast
	if m.get("night_cm") != null:
		var open_sky := SkyLook.tint(String(m.lvl), Game.sky, Game.time)
		var dry := SkyLook.tint(String(m.lvl), "clear", Game.time)
		m.night_cm.color = open_sky.lerp(dry, u * COVER_TINT)


# --- weather and materials ------------------------------------------------------

static func _rainy() -> bool:
	return Game.weather == "rain"


static func _snowy() -> bool:
	return Game.weather == "snow"


# the open-air paving's colour for the sky: dry stone, rain-dark, or a dusting
static func _pave() -> Color:
	if _rainy():
		return PAVE_WET
	if _snowy():
		return PAVE_SNOW
	return PAVE_DRY


static func _shadow_rect(b: ShapeBatch, r: Rect2, h: float, col := SHADOW) -> void:
	b.rect(Rect2(r.position + Shade.light * h, r.size), col)


# a long soft shadow off something tall standing at `at`
static func _tall_shadow(b: ShapeBatch, at: Vector2, w: float, length: float, a: float) -> void:
	var tip := at + Shade.light * length
	var side := Shade.SUN.orthogonal()
	b.band(PackedVector2Array([
		at - side * w, at, at + side * w,
		tip - side * w * 0.6, tip, tip + side * w * 0.6,
	]), 3, Color(SHADOW.r, SHADOW.g, SHADOW.b, a), PackedFloat32Array([1.0, 0.0]),
		PackedFloat32Array([0.3, 1.0, 0.3]))


# --- drawing: edge layer ----------------------------------------------------------

static func draw_edge_layer(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	var top: float = maxf(vt, float(m.GATE_Y) - 40.0)
	var bot: float = minf(vb, float(m.START_Y) + 560.0)
	if bot <= top:
		return
	var was := b.lod
	b.lod = true
	if bot > CANOPY_Y0:
		_edge_street(b, maxf(top, CANOPY_Y0), bot)
	if top < CANOPY_Y0 and bot > CANOPY_Y1:
		_edge_market(b, maxf(top, CANOPY_Y1), minf(bot, CANOPY_Y0))
	if top < CANOPY_Y1:
		_edge_north(b, top, minf(bot, CANOPY_Y1))
	b.lod = was


# The street at Glòries: the tram on its grass bed and the avenue to the west,
# the plaça round the tower and an office block to the east.
static func _edge_street(b: ShapeBatch, lo: float, hi: float) -> void:
	var pave := _pave()
	var wet := _rainy()
	# west: the pavement's last strip, the kerb, the tram bed, the road
	b.rect(Rect2(-420.0, lo, 590.0, hi - lo), ASPHALT_WET if wet else ASPHALT)
	b.rect(Rect2(170.0, lo, 120.0, hi - lo), TRAM_GRASS.darkened(0.12) if wet else TRAM_GRASS)
	b.rect(Rect2(296.0, lo, PATH_L - 296.0, hi - lo), pave)
	Panot.flor(b, 298.0, PATH_L, lo, hi, PANOT_WET_GROOVE if wet else PANOT_DRY_GROOVE, PANOT_WET_SHINE if wet else PANOT_DRY_SHINE)
	b.rect(Rect2(288.0, lo, 8.0, hi - lo), KERB)
	b.rect(Rect2(288.0, lo, 2.0, hi - lo), KERB.lightened(0.2))
	# grass bed texture: tufts, then two pairs of rails with a sheen
	var gy := floorf(lo / 18.0) * 18.0
	while gy < hi:
		var k := int(absf(gy) / 18.0)
		b.rect(Rect2(174.0 + _h(k) * 100.0, gy, 10.0 + _h(k + 9) * 8.0, 3.0), TRAM_GRASS.lightened(0.12))
		gy += 18.0
	for rx: float in [192.0, 214.0, 246.0, 268.0]:
		b.rect(Rect2(rx - 2.0, lo, 4.0, hi - lo), RAIL_COL)
		b.rect(Rect2(rx - 0.5, lo, 1.0, hi - lo), Color(0.86, 0.88, 0.90, 0.75 if wet else 0.5))
	# road: lane dashes, the kerb's gutter
	var dy := floorf(lo / 60.0) * 60.0
	while dy < hi:
		b.rect(Rect2(76.0, dy, 4.0, 30.0), Color(0.92, 0.92, 0.88, 0.75))
		dy += 60.0
	b.rect(Rect2(160.0, lo, 10.0, hi - lo), KERB.darkened(0.1))
	# the zebra crossing over road and tram bed to the market door
	if lo < -560.0:
		var zy0 := maxf(lo, -690.0)
		var zy1 := minf(hi, -610.0)
		if zy1 > zy0:
			b.rect(Rect2(170.0, zy0, 120.0, zy1 - zy0), Color(0.56, 0.56, 0.56) if wet else Color(0.66, 0.65, 0.62))
			var zx := -180.0
			while zx < 290.0:
				b.rect(Rect2(zx, -684.0, 14.0, 68.0), Color(0.94, 0.94, 0.90, 0.85))
				zx += 26.0
	# plane trees and parked scooters along the pavement
	var ty := floorf((lo - 40.0) / 150.0) * 150.0
	while ty < hi + 60.0:
		var k := int(absf(ty) / 150.0)
		var tp := Vector2(318.0, ty + 40.0)
		if tp.y > CANOPY_Y0 + 60.0:
			_plane_tree(b, tp, k)
			_scooter(b, Vector2(306.0, ty + 100.0), k)
		ty += 150.0
	# east: the plaça's big stone flags round the tower
	b.rect(Rect2(PATH_R, lo, 1740.0 - PATH_R, hi - lo), pave.darkened(0.04))
	var fy := floorf(lo / 64.0) * 64.0
	while fy < hi:
		b.rect(Rect2(PATH_R, fy, 1740.0 - PATH_R, 1.5), Color(0.0, 0.0, 0.0, 0.10))
		var fx := PATH_R + fmod(absf(fy), 128.0) * 0.5
		while fx < 1740.0:
			b.rect(Rect2(fx, fy, 1.5, 64.0), Color(0.0, 0.0, 0.0, 0.08))
			fx += 96.0
		fy += 64.0
	b.rect(Rect2(PATH_R, lo, 6.0, hi - lo), KERB)
	if wet:
		var wy := floorf(lo / 90.0) * 90.0
		while wy < hi:
			var k := int(absf(wy) / 90.0)
			b.glow(Vector2(PATH_R + 40.0 + _h(k) * 160.0, wy + 30.0), 26.0 + _h(k + 4) * 18.0, Color(0.62, 0.70, 0.82, 0.30))
			wy += 90.0
	# the office block north of the tower, its fronts on the pavement
	var blk := Rect2(958.0, -660.0, 420.0, 360.0)
	if blk.end.y > lo and blk.position.y < hi:
		_office_block(b, blk, 7)
	if TORRE_POS.y - 260.0 < hi and TORRE_POS.y + 260.0 > lo:
		_draw_torre(b, TORRE_POS)


# people out on the street at the pavement's edges: umbrellas in the rain,
# coats otherwise
static func _street_people(b: ShapeBatch, lo: float, hi: float) -> void:
	var wet := _rainy()
	for i in range(14):
		var p := Vector2(0.0, 0.0)
		if i % 2 == 0:
			p = Vector2(356.0 + _h(i * 11) * 10.0, 180.0 - float(i) * 58.0)
		else:
			p = Vector2(PATH_R - 20.0 - _h(i * 13) * 22.0, 140.0 - float(i) * 60.0)
		if p.y < lo - 30.0 or p.y > hi + 30.0 or p.y < CANOPY_Y0 + 40.0:
			continue
		var fwd := Vector2(0.0, -1.0 if i % 4 < 2 else 1.0)
		_passer(b, p, fwd, 4700 + i * 7, wet)


static func _plane_tree(b: ShapeBatch, p: Vector2, k: int) -> void:
	# a plàtan in its square pit: trunk, mottled crown, its shadow on the paving
	b.rect(Rect2(p.x - 12.0, p.y - 12.0, 24.0, 24.0), Color(0.40, 0.32, 0.24))
	b.rect(Rect2(p.x - 10.0, p.y - 10.0, 20.0, 20.0), Color(0.30, 0.24, 0.18))
	var bare := _snowy()
	var r := 30.0 + _h(k * 3) * 8.0
	b.circle(p + Shade.light * 26.0, r, Color(SHADOW.r, SHADOW.g, SHADOW.b, 0.20))
	if bare:
		for j in range(5):
			var a := float(j) * TAU / 5.0 + _h(k) * 2.0
			b.line(p, p + Vector2.from_angle(a) * r * 0.9, Color(0.42, 0.36, 0.30), 3.0)
		return
	var leaf := Color(0.30, 0.46, 0.24) if Game.hour != "night" else Color(0.18, 0.28, 0.18)
	b.circle(p, r, leaf.darkened(0.15))
	for j in range(6):
		var a := float(j) * TAU / 6.0 + _h(k + j) * 0.8
		b.circle(p + Vector2.from_angle(a) * r * 0.45, r * 0.5, leaf.lightened(0.04 * float(j % 3)))
	b.circle(p + Vector2(-8.0, -9.0), r * 0.42, leaf.lightened(0.18))


static func _scooter(b: ShapeBatch, p: Vector2, k: int) -> void:
	var col: Color = [Color(0.82, 0.16, 0.16), Color(0.92, 0.92, 0.90), Color(0.16, 0.18, 0.22), Color(0.20, 0.44, 0.66)][k % 4]
	b.capsule(p + Shade.light * 4.0 + Vector2(-14.0, 0.0), p + Shade.light * 4.0 + Vector2(14.0, 0.0), 6.0, SHADOW)
	b.capsule(p + Vector2(-14.0, 0.0), p + Vector2(14.0, 0.0), 2.5, Color(0.10, 0.10, 0.11))
	b.capsule(p + Vector2(-8.0, 0.0), p + Vector2(8.0, 0.0), 6.0, col)
	b.capsule(p + Vector2(-4.0, 0.0), p + Vector2(4.0, 0.0), 3.5, Color(0.12, 0.12, 0.13))
	b.line(p + Vector2(12.0, -8.0), p + Vector2(12.0, 8.0), Color(0.30, 0.30, 0.32), 2.0)


# A modern office block from above: a flat roof inside a parapet, plant on it,
# a skylight strip, and a glazed front on the pavement under a canopy.
static func _office_block(b: ShapeBatch, r: Rect2, k: int) -> void:
	_shadow_rect(b, r, 26.0, Color(SHADOW.r, SHADOW.g, SHADOW.b, 0.30))
	b.rect(r, OFFICE_WALL)
	b.rect(r.grow(-7.0), OFFICE_ROOF)
	# roof gravel speckle
	var y := r.position.y + 12.0
	while y < r.end.y - 10.0:
		b.rect(Rect2(r.position.x + 10.0 + fmod(absf(y) * 3.7, 30.0), y, r.size.x - 50.0, 1.5), Color(0.0, 0.0, 0.0, 0.05))
		y += 9.0
	# the glazed front facing the pavement: mullions and a glint
	b.rect(Rect2(r.position.x - 6.0, r.position.y + 8.0, 10.0, r.size.y - 16.0), OFFICE_GLASS)
	var gy := r.position.y + 8.0
	while gy < r.end.y - 8.0:
		b.rect(Rect2(r.position.x - 6.0, gy, 10.0, 2.0), OFFICE_WALL.darkened(0.2))
		gy += 24.0
	b.band(PackedVector2Array([
		Vector2(r.position.x - 6.0, r.position.y + 8.0), Vector2(r.position.x + 4.0, r.position.y + 8.0),
		Vector2(r.position.x - 6.0, r.end.y - 8.0), Vector2(r.position.x + 4.0, r.end.y - 8.0),
	]), 2, Color(0.85, 0.92, 1.0, 0.35), PackedFloat32Array([0.0, 1.0]))
	# plant: air handlers with fans, a lift overrun, solar panels
	for j in range(3):
		var u := Rect2(r.position.x + 60.0 + float(j) * 70.0, r.position.y + 40.0 + _h(k + j) * 30.0, 46.0, 30.0)
		_shadow_rect(b, u, 7.0)
		b.rect(u, Color(0.70, 0.72, 0.74))
		b.rect(u.grow(-3.0), Color(0.62, 0.64, 0.66))
		b.circle(u.get_center() + Vector2(-10.0, 0.0), 9.0, Color(0.30, 0.32, 0.34))
		b.circle(u.get_center() + Vector2(12.0, 0.0), 9.0, Color(0.30, 0.32, 0.34))
	var lift := Rect2(r.end.x - 130.0, r.position.y + 150.0, 60.0, 60.0)
	_shadow_rect(b, lift, 14.0)
	b.rect(lift, OFFICE_WALL.lightened(0.06))
	b.rect(lift.grow(-4.0), OFFICE_ROOF.lightened(0.05))
	for j in range(4):
		var sp := Rect2(r.position.x + 40.0 + float(j) * 52.0, r.end.y - 110.0, 44.0, 70.0)
		b.rect(Rect2(sp.position + Vector2(3.0, 4.0), sp.size), SHADOW)
		b.rect(sp, Color(0.16, 0.22, 0.36))
		b.rect(Rect2(sp.position.x, sp.position.y + 34.0, sp.size.x, 1.5), Color(0.6, 0.7, 0.8, 0.4))
		b.rect(Rect2(sp.position.x + 21.0, sp.position.y, 1.5, sp.size.y), Color(0.6, 0.7, 0.8, 0.4))
	# skylight strip down the middle
	b.rect(Rect2(r.position.x + 30.0, r.position.y + 100.0, r.size.x - 200.0, 16.0), Color(0.54, 0.66, 0.76))
	b.rect(Rect2(r.position.x + 30.0, r.position.y + 100.0, r.size.x - 200.0, 5.0), Color(0.80, 0.88, 0.94, 0.6))


# Torre Glòries from above: no branding, just the shape. A glass bullet seen
# down its nose: rings of coloured louvres over the glass, lighter towards the
# dome at the top, a cupola, and its long shadow over the plaça.
static func _draw_torre(b: ShapeBatch, p: Vector2) -> void:
	var r := TORRE_R
	# the shadow of something that tall runs off the screen
	_tall_shadow(b, p, r * 0.92, 520.0, 0.34)
	b.circle(p + Shade.light * 10.0, r + 4.0, Color(SHADOW.r, SHADOW.g, SHADOW.b, 0.35))
	# the plinth: a pale ring of paving and a water channel round the base
	b.circle(p, r + 16.0, KERB)
	b.circle(p, r + 10.0, Color(0.28, 0.42, 0.52) if not _snowy() else Color(0.80, 0.84, 0.88))
	b.circle(p, r + 2.0, TORRE_DARK)
	var night := Game.hour == "night"
	# the louvre rings, outside in: each a ring of panels in the tower's
	# reds, blues and greys, rising towards the nose
	var rings := 7
	# the nose stands far above the base, so each ring up sits a little
	# further from the eye's line: the bullet leans away up the screen
	var lean := Vector2(-0.22, -0.55) * r * 0.32
	for ri in range(rings):
		var t := float(ri) / float(rings)
		var pc := p + lean * t * t
		var r0 := r * (1.0 - t * 0.86)
		var r1 := r * (1.0 - (t + 1.0 / float(rings)) * 0.86)
		var n := 28 - ri * 2
		for j in range(n):
			var a0 := TAU * float(j) / float(n) + float(ri) * 0.21
			var a1 := TAU * float(j + 1) / float(n) + float(ri) * 0.21
			var hk := _h(ri * 61 + j * 7)
			var col: Color = TORRE_PANELS[int(hk * float(TORRE_PANELS.size())) % TORRE_PANELS.size()]
			col = col.lerp(Color(0.80, 0.88, 0.92), t * 0.45)
			if night:
				col = col.lerp(TORRE_NIGHT[(j + ri * 3) % TORRE_NIGHT.size()], 0.65)
			var gap := 0.03
			var lit := clampf(Vector2.from_angle((a0 + a1) * 0.5).dot(-Shade.SUN), -1.0, 1.0)
			col = col.lightened(maxf(lit, 0.0) * 0.18).darkened(maxf(-lit, 0.0) * 0.25)
			b.polygon(PackedVector2Array([
				pc + Vector2.from_angle(a0 + gap) * (r0 - 1.5), pc + Vector2.from_angle(a1 - gap) * (r0 - 1.5),
				pc + Vector2.from_angle(a1 - gap) * (r1 + 1.0), pc + Vector2.from_angle(a0 + gap) * (r1 + 1.0),
			]), col)
	# the cupola: glass lattice at the nose
	var cr := r * 0.16
	var nose := p + lean
	b.circle(nose, cr + 3.0, TORRE_DARK)
	b.circle(nose, cr, Color(0.62, 0.78, 0.86))
	for j in range(6):
		var a := TAU * float(j) / 6.0
		b.line(nose, nose + Vector2.from_angle(a) * cr, Color(0.30, 0.40, 0.46), 1.5)
	# daylight on the dome's lit side, or its own glow at night
	if night:
		b.glow(p, r * 1.25, Color(0.70, 0.40, 0.90, 0.22 * Game.lamp_glow()))
	else:
		b.glow(p + Vector2(-r * 0.32, -r * 0.34), r * 0.75, Color(1.0, 1.0, 1.0, 0.26))


# a passer-by on the open street: an umbrella over them in the rain
static func _passer(b: ShapeBatch, p: Vector2, fwd: Vector2, key: int, wet: bool) -> void:
	if wet:
		NpcFigure.person(b, p, fwd, key, -1.0, {"arms": NpcFigure.Arms.READY})
		_umbrella(b, p + fwd * 2.0, 17.0 + _h(key) * 4.0, key)
	else:
		var o := {}
		if _snowy():
			o["headwear"] = "beanie"
			o["headwear_col"] = UMBRELLAS[int(_h(key) * 7.0) % UMBRELLAS.size()]
		NpcFigure.person(b, p, fwd, key, 0.8 + _h(key) * 2.0, o)


# An umbrella from above: eight panels round the tip, lit on the sun's side,
# the ribs showing at the seams, its shadow on the ground.
static func _umbrella(b: ShapeBatch, p: Vector2, r: float, key: int) -> void:
	var ci := int(_h(key * 3 + 1) * float(UMBRELLAS.size())) % UMBRELLAS.size()
	var col: Color = UMBRELLAS[ci]
	var alt := col
	if _h(key + 5) < 0.35:
		alt = UMBRELLAS[(ci + 3) % UMBRELLAS.size()]
	b.circle(p + Shade.light * 10.0, r * 0.95, Color(SHADOW.r, SHADOW.g, SHADOW.b, 0.22))
	var turn := _h(key) * TAU
	var lit_dir := -Shade.SUN
	for j in range(8):
		var a0 := turn + TAU * float(j) / 8.0
		var a1 := turn + TAU * float(j + 1) / 8.0
		var mid := Vector2.from_angle((a0 + a1) * 0.5)
		var c := col if j % 2 == 0 else alt
		c = c.lightened(clampf(mid.dot(lit_dir), 0.0, 1.0) * 0.22).darkened(clampf(-mid.dot(lit_dir), 0.0, 1.0) * 0.18)
		b.polygon(PackedVector2Array([p, p + Vector2.from_angle(a0) * r, p + Vector2.from_angle(a1) * r]), c)
	for j in range(8):
		var a := turn + TAU * float(j) / 8.0
		b.line(p, p + Vector2.from_angle(a) * r, col.darkened(0.35), 1.0)
	b.circle(p, 2.0, Color(0.14, 0.14, 0.14))
	if _rainy():
		b.glow(p + lit_dir * r * 0.35, r * 0.45, Color(1.0, 1.0, 1.0, 0.16))


# Under the canopy either side of the lane: more of the market. A row of
# stalls back to back with the lane's, an aisle with its own browsers, and the
# next row beyond, all on the same concrete.
static func _edge_market(b: ShapeBatch, lo: float, hi: float) -> void:
	b.rect(Rect2(-420.0, lo, PATH_L + 420.0, hi - lo), CONC.darkened(0.06))
	b.rect(Rect2(PATH_R, lo, 1740.0 - PATH_R, hi - lo), CONC.darkened(0.06))
	_floor_joints(b, -420.0, PATH_L, lo, hi)
	_floor_joints(b, PATH_R, 1740.0, lo, hi)
	_slab_tones(b, -420.0, PATH_L, lo, hi)
	_slab_tones(b, PATH_R, 1740.0, lo, hi)
	for ry: float in RAMP_YS:
		if ry > lo - 80.0 and ry < hi + 80.0:
			_ramp(b, -420.0, PATH_L, ry)
			_ramp(b, PATH_R, 1740.0, ry)
	# the aisles' worn centre lines
	for ax: float in [182.0, 1098.0]:
		b.band(PackedVector2Array([
			Vector2(ax - 40.0, lo), Vector2(ax, lo), Vector2(ax + 40.0, lo),
			Vector2(ax - 40.0, hi), Vector2(ax, hi), Vector2(ax + 40.0, hi),
		]), 3, Color(1.0, 0.96, 0.88, 0.10), PackedFloat32Array([1.0, 1.0]), PackedFloat32Array([0.0, 1.0, 0.0]))
	# stall rows, each pitch its own length
	var step := 96.0
	var y := floorf(lo / step) * step
	while y < hi + step:
		var k := int(absf(y) / step)
		if y > CANOPY_Y1 + 20.0 and y + step < CANOPY_Y0 - 10.0:
			var len_a := 64.0 + _h(k * 5) * 26.0
			var len_b := 60.0 + _h(k * 7 + 1) * 30.0
			# west: backing onto the lane's stalls (front to the far aisle), then the far row
			_stall(b, Rect2(228.0, y + 4.0, 112.0 - _h(k + 2) * 18.0, len_a), -1.0, 900 + k, true)
			_stall(b, Rect2(30.0, y + 10.0, 104.0, len_b), 1.0, 1300 + k, true)
			_stall(b, Rect2(PATH_R + 10.0 + _h(k + 3) * 14.0, y + 8.0, 102.0, len_b), 1.0, 1700 + k, true)
			_stall(b, Rect2(1150.0, y + 2.0, 110.0, len_a), -1.0, 2100 + k, true)
			# aisle browsers, some moving between stalls
			for j in range(2):
				var hk := _h(k * 13 + j * 5)
				if hk < Outdoors.flea_browsers(Game.weather, Game.hour):
					var ax := 168.0 + _h(k * 3 + j) * 30.0 if j == 0 else 1084.0 + _h(k * 11 + j) * 30.0
					var p := Vector2(ax, y + 20.0 + hk * 60.0)
					var fwd := Vector2(0.0, -1.0) if _h(k + j * 31) < 0.5 else Vector2(0.0, 1.0)
					NpcFigure.person(b, p, fwd, 5200 + k * 3 + j, _h(k + j) * TAU)
		y += step


# each poured slab a shade off its neighbours, with a crack or a patch here and there
static func _slab_tones(b: ShapeBatch, x0: float, x1: float, lo: float, hi: float) -> void:
	var y := floorf(lo / 120.0) * 120.0
	while y < hi:
		var x := floorf(x0 / 146.0) * 146.0
		while x < x1:
			var k := int(absf(y) / 120.0) * 37 + int(absf(x) / 146.0) * 11
			var sx := maxf(x, x0)
			var ex := minf(x + 146.0, x1)
			var sy := maxf(y, lo)
			var ey := minf(y + 120.0, hi)
			if ex > sx and ey > sy:
				var t := _h(k)
				b.rect(Rect2(sx, sy, ex - sx, ey - sy), Color(0.0, 0.0, 0.0, 0.05) if t < 0.4 else Color(1.0, 0.98, 0.94, 0.04 * t))
				if _h(k + 3) < 0.25:
					var cp := Vector2(lerpf(sx, ex, _h(k + 5)), lerpf(sy, ey, _h(k + 6)))
					var d := Vector2.from_angle(_h(k + 7) * TAU)
					b.line(cp, cp + d * 22.0, Color(0.20, 0.18, 0.16, 0.25), 1.2)
					b.line(cp + d * 22.0, cp + d * 22.0 + d.rotated(0.7) * 14.0, Color(0.20, 0.18, 0.16, 0.25), 1.0)
			x += 146.0
		y += 120.0


static func _floor_joints(b: ShapeBatch, x0: float, x1: float, lo: float, hi: float) -> void:
	var y := floorf(lo / 120.0) * 120.0
	while y < hi:
		b.rect(Rect2(x0, y, x1 - x0, 1.5), CONC_JOINT)
		y += 120.0
	var x := floorf(x0 / 146.0) * 146.0
	while x < x1:
		if x > x0:
			b.rect(Rect2(x, lo, 1.5, hi - lo), CONC_JOINT)
		x += 146.0


# North of the canopy: Carrer dels Castillejos to the plaça, blocks of flats
# both sides, flat roof terraces and tiled roofs, shopfronts on the pavement.
static func _edge_north(b: ShapeBatch, lo: float, hi: float) -> void:
	if hi <= lo:
		return
	var pave := _pave()
	b.rect(Rect2(-420.0, lo, PATH_L + 420.0, hi - lo), pave.darkened(0.12))
	b.rect(Rect2(PATH_R, lo, 1740.0 - PATH_R, hi - lo), pave.darkened(0.12))
	var y := -5160.0
	var k := 0
	while y < CANOPY_Y1:
		var h := 150.0 + _h(k * 7) * 90.0
		var y1 := minf(y + h, CANOPY_Y1 - 6.0)
		if y1 > lo - 40.0 and y < hi + 40.0:
			_flat_block(b, Rect2(60.0, y + 3.0, PATH_L - 66.0, y1 - y - 6.0), 1.0, 3100 + k)
			_flat_block(b, Rect2(PATH_R + 6.0, y + 3.0, 290.0, y1 - y - 6.0), -1.0, 3500 + k)
		y += h
		k += 1


# A block of flats seen from above. `face` is the side its front is on (+1
# its front at its right edge, -1 its left). Either a flat roof terrace (terrat)
# in tiles inside a parapet with a water tank, washing and a stair hut, or a
# tiled pitched roof; a shopfront awning on the pavement either way.
static func _flat_block(b: ShapeBatch, r: Rect2, face: float, k: int) -> void:
	if r.size.y < 30.0:
		return
	_shadow_rect(b, r, 22.0, Color(SHADOW.r, SHADOW.g, SHADOW.b, 0.32))
	var wall: Color = BLOCK_WALLS[k % BLOCK_WALLS.size()]
	b.rect(r, wall)
	var front_x := r.end.x if face > 0.0 else r.position.x
	if _h(k * 3) < 0.55:
		# the terrat: tile floor, a parapet, a water tank, washing on a line
		var t := r.grow(-6.0)
		b.rect(t, TERRAT)
		var ty := t.position.y
		while ty < t.end.y:
			b.rect(Rect2(t.position.x, ty, t.size.x, 1.0), Color(0.40, 0.22, 0.14, 0.25))
			ty += 10.0
		var tx := t.position.x
		while tx < t.end.x:
			b.rect(Rect2(tx, t.position.y, 1.0, t.size.y), Color(0.40, 0.22, 0.14, 0.18))
			tx += 10.0
		b.rect(Rect2(t.position.x, t.position.y, t.size.x, 4.0), Color(0.0, 0.0, 0.0, 0.14))
		var hut := Rect2(t.position.x + t.size.x * (0.2 + _h(k) * 0.4), t.position.y + 10.0, 40.0, 34.0)
		_shadow_rect(b, hut, 12.0)
		b.rect(hut, wall.lightened(0.06))
		b.rect(Rect2(hut.position.x, hut.position.y, hut.size.x, 6.0), wall.darkened(0.12))
		var tank := Vector2(t.position.x + t.size.x * 0.7, t.end.y - 26.0)
		b.circle(tank + Shade.light * 8.0, 12.0, SHADOW)
		b.circle(tank, 11.0, Color(0.76, 0.76, 0.74))
		b.circle(tank + Vector2(-3.0, -3.0), 5.0, Color(0.90, 0.90, 0.88))
		if t.size.y > 90.0:
			var ly := t.get_center().y + 10.0
			b.line(Vector2(t.position.x + 12.0, ly), Vector2(t.end.x - 12.0, ly), Color(0.30, 0.30, 0.30, 0.6), 1.0)
			var lx := t.position.x + 20.0
			var j := 0
			while lx < t.end.x - 20.0:
				b.rect(Rect2(lx, ly, 9.0, 12.0 + _h(k + j) * 6.0), LAUNDRY[(k + j) % LAUNDRY.size()])
				lx += 16.0 + _h(k * 5 + j) * 10.0
				j += 1
	else:
		# a tiled roof pitched along the street: lit half, shaded half, the ridge
		var t := r.grow(-3.0)
		var mid := t.get_center().x
		var tile: Color = ROOF_TILES[k % ROOF_TILES.size()]
		b.rect(Rect2(t.position.x, t.position.y, mid - t.position.x, t.size.y), tile.lightened(0.10))
		b.rect(Rect2(mid, t.position.y, t.end.x - mid, t.size.y), tile.darkened(0.12))
		var ty := t.position.y + 6.0
		while ty < t.end.y:
			b.rect(Rect2(t.position.x, ty, t.size.x, 1.5), Color(0.0, 0.0, 0.0, 0.12))
			ty += 8.0
		b.rect(Rect2(mid - 2.0, t.position.y, 4.0, t.size.y), tile.darkened(0.3))
		if r.size.y > 80.0:
			var ch := Rect2(mid + 16.0, t.position.y + 20.0 + _h(k) * 30.0, 14.0, 14.0)
			_shadow_rect(b, ch, 10.0)
			b.rect(ch, wall.darkened(0.1))
	# balconies on the front, then a shop awning over the pavement
	var by := r.position.y + 14.0
	while by < r.end.y - 20.0:
		b.rect(Rect2(front_x - (10.0 if face > 0.0 else -2.0), by, 8.0, 18.0), Color(0.22, 0.22, 0.24))
		by += 34.0
	if _h(k * 11) < 0.7 and r.size.y > 60.0:
		var aw_col: Color = AWNINGS[k % AWNINGS.size()]
		var aw := Rect2(front_x if face > 0.0 else front_x - 16.0, r.position.y + 16.0, 16.0, minf(80.0, r.size.y - 32.0))
		_shadow_rect(b, aw, 5.0)
		b.rect(aw, aw_col)
		var sy := aw.position.y
		var j := 0
		while sy < aw.end.y:
			if j % 2 == 0:
				b.rect(Rect2(aw.position.x, sy, aw.size.x, 5.0), aw_col.lightened(0.3))
			sy += 5.0
			j += 1


# --- cross section: floor, ramps, stalls, stilts, auction, the chair tower --------

static func draw_cross_section(m: Node2D, wc: ShapeBatch, _top: float, _bottom: float, ctop: float, vt: float, vb: float) -> void:
	var keep_lod := wc.lod
	wc.lod = true
	var lo := maxf(vt - 40.0, maxf(ctop, float(m.GATE_Y) - 40.0))
	var hi := minf(vb + 40.0, float(m.START_Y) + 560.0)
	if hi > lo:
		_draw_floor(wc, lo, hi)
		for ry: float in RAMP_YS:
			if ry > lo - 80.0 and ry < hi + 80.0:
				_ramp(wc, PATH_L, PATH_R, ry)
		_draw_gaps(wc, lo, hi)
		_draw_stalls(wc, lo, hi)
		_draw_stilts(wc, lo, hi)
		_draw_auction(wc, lo, hi)
		_draw_spill_stack_static(wc, lo, hi)
		_draw_drip_line(wc, lo, hi)
		_street_people(wc, lo, hi)
	wc.lod = keep_lod


static func _draw_floor(wc: ShapeBatch, lo: float, hi: float) -> void:
	var step := Panot.FLOR
	var wet := _rainy()
	var pave := _pave()
	var y := floorf(lo / step) * step
	while y < hi:
		var mid := y + step * 0.5
		if _under_canopy(mid):
			wc.rect(Rect2(PATH_L, y, HALF * 2.0, step + 0.5), CONC)
		else:
			wc.rect(Rect2(PATH_L, y, HALF * 2.0, step + 0.5), pave)
			Panot.flor_row(wc, PATH_L + 4.0, PATH_R - 4.0, y, PATH_L + 4.0,
				PANOT_WET_GROOVE if wet else PANOT_DRY_GROOVE, PANOT_WET_SHINE if wet else PANOT_DRY_SHINE)
		y += step
	# the market floor: poured concrete in big slabs, stains, painted pitches
	var c_lo := maxf(lo, CANOPY_Y1)
	var c_hi := minf(hi, CANOPY_Y0)
	if c_hi > c_lo:
		_floor_joints(wc, PATH_L, PATH_R, c_lo, c_hi)
		_slab_tones(wc, PATH_L, PATH_R, c_lo, c_hi)
		var sy := floorf(c_lo / 70.0) * 70.0
		while sy < c_hi:
			var k := int(absf(sy) / 70.0)
			wc.glow(Vector2(PATH_L + 120.0 + _h(k) * (HALF * 2.0 - 240.0), sy + 30.0), 14.0 + _h(k + 2) * 22.0,
				Color(0.20, 0.17, 0.14, 0.10))
			sy += 70.0
		# painted pitch lines at the stalls' fronts, dashed
		for px: float in [PATH_L + 106.0, PATH_R - 108.0]:
			var dy := floorf(c_lo / 30.0) * 30.0
			while dy < c_hi:
				wc.rect(Rect2(px, dy, 2.5, 16.0), PITCH_PAINT)
				dy += 30.0
		# the mirror's soft bounce: warm light pooled down the lane's middle,
		# and the edges a little darker under the stalls' clutter
		wc.band(PackedVector2Array([
			Vector2(PATH_L, c_lo), Vector2(PATH_L + 120.0, c_lo), Vector2(CX, c_lo), Vector2(PATH_R - 120.0, c_lo), Vector2(PATH_R, c_lo),
			Vector2(PATH_L, c_hi), Vector2(PATH_L + 120.0, c_hi), Vector2(CX, c_hi), Vector2(PATH_R - 120.0, c_hi), Vector2(PATH_R, c_hi),
		]), 5, Color(1.0, 0.90, 0.70, 0.10), PackedFloat32Array([1.0, 1.0]), PackedFloat32Array([0.0, 0.2, 1.0, 0.2, 0.0]))
		var gy := floorf(c_lo / 260.0) * 260.0
		while gy < c_hi:
			var k := int(absf(gy) / 260.0)
			wc.glow(Vector2(CX + (_h(k * 3) - 0.5) * 220.0, gy + 130.0), 120.0, Color(1.0, 0.86, 0.62, 0.07))
			gy += 260.0
		# daylight reaching in under the canopy's two ends, the shade deepening inside
		for edge: float in [CANOPY_Y0, CANOPY_Y1]:
			var inward := -1.0 if edge == CANOPY_Y0 else 1.0
			var e0 := edge
			var e1 := edge + inward * 160.0
			if maxf(e0, e1) < lo or minf(e0, e1) > hi:
				continue
			wc.band(PackedVector2Array([
				Vector2(PATH_L, e0), Vector2(PATH_R, e0),
				Vector2(PATH_L, e1), Vector2(PATH_R, e1),
			]), 2, Color(0.0, 0.02, 0.06, 0.20), PackedFloat32Array([0.0, 1.0]))
			wc.band(PackedVector2Array([
				Vector2(PATH_L, e1), Vector2(PATH_R, e1),
				Vector2(PATH_L, e1 + inward * 220.0), Vector2(PATH_R, e1 + inward * 220.0),
			]), 2, Color(0.0, 0.02, 0.06, 0.20), PackedFloat32Array([1.0, 0.0]))
	# wet street: lamps and shopfronts reflected in streaks, puddles in the dips
	if wet:
		for lp: Vector2 in STREET_LAMPS:
			if lp.y < lo - 80.0 or lp.y > hi + 80.0:
				continue
			var x0 := lp.x + (16.0 if lp.x < CX else -16.0)
			wc.band(PackedVector2Array([
				Vector2(x0 - 10.0, lp.y + 8.0), Vector2(x0, lp.y + 8.0), Vector2(x0 + 10.0, lp.y + 8.0),
				Vector2(x0 - 6.0, lp.y + 90.0), Vector2(x0, lp.y + 90.0), Vector2(x0 + 6.0, lp.y + 90.0),
			]), 3, Color(0.90, 0.92, 1.0, 0.22), PackedFloat32Array([1.0, 0.0]), PackedFloat32Array([0.0, 1.0, 0.0]))
		for zone: Array in [[CANOPY_Y0 + 20.0, hi], [lo, CANOPY_Y1 - 20.0]]:
			var z0 := maxf(lo, float(zone[0]))
			var z1 := minf(hi, float(zone[1]))
			var py := floorf(z0 / 110.0) * 110.0
			while py < z1:
				var k := int(absf(py) / 110.0)
				if _h(k * 7 + 1) < 0.6:
					var pc := Vector2(PATH_L + 70.0 + _h(k * 3) * (HALF * 2.0 - 140.0), py + 50.0)
					wc.glow(pc, 26.0 + _h(k) * 20.0, Color(0.36, 0.44, 0.56, 0.40))
					wc.glow(pc + Vector2(-6.0, -4.0), 12.0 + _h(k) * 8.0, Color(0.80, 0.86, 0.96, 0.25))
				py += 110.0


# A ramp between two levels of the floor, rising north: its foot in shadow,
# ribbed for grip, a lit crest, and yellow nosing paint at its top.
static func _ramp(b: ShapeBatch, x0: float, x1: float, ry: float) -> void:
	b.band(PackedVector2Array([
		Vector2(x0, ry - 60.0), Vector2(x1, ry - 60.0),
		Vector2(x0, ry - 40.0), Vector2(x1, ry - 40.0),
		Vector2(x0, ry + 36.0), Vector2(x1, ry + 36.0),
		Vector2(x0, ry + 60.0), Vector2(x1, ry + 60.0),
	]), 2, Color(0.10, 0.08, 0.06, 0.30), PackedFloat32Array([0.0, 0.15, 0.55, 0.0]))
	b.band(PackedVector2Array([
		Vector2(x0, ry - 58.0), Vector2(x1, ry - 58.0),
		Vector2(x0, ry - 46.0), Vector2(x1, ry - 46.0),
		Vector2(x0, ry - 34.0), Vector2(x1, ry - 34.0),
	]), 2, Color(1.0, 0.97, 0.90, 0.22), PackedFloat32Array([0.0, 1.0, 0.0]))
	var y := ry - 36.0
	while y < ry + 34.0:
		b.rect(Rect2(x0, y, x1 - x0, 1.5), Color(0.0, 0.0, 0.0, 0.10))
		b.rect(Rect2(x0, y + 1.5, x1 - x0, 1.0), Color(1.0, 1.0, 1.0, 0.06))
		y += 7.0
	var x := x0 + 6.0
	while x < x1 - 6.0:
		b.rect(Rect2(x, ry - 44.0, 18.0, 4.0), PITCH_PAINT)
		x += 30.0


# between the lane's stalls: what each seller keeps at the back of the gap
static func _draw_gaps(wc: ShapeBatch, lo: float, hi: float) -> void:
	for i in range(0, STALL_SOLIDS.size() - 2, 2):
		var a: Rect2 = STALL_SOLIDS[i]
		var nb: Rect2 = STALL_SOLIDS[i + 2]
		var g0 := nb.end.y
		var g1 := a.position.y
		if g1 - g0 < 20.0 or g1 - g0 > 80.0 or g1 < lo - 20.0 or g0 > hi + 20.0:
			continue
		for side: float in [-1.0, 1.0]:
			var k := i * 3 + (7 if side > 0.0 else 0)
			var bx := PATH_L + 8.0 if side < 0.0 else PATH_R - 8.0
			var inward := -side
			var c := Vector2(bx + inward * 26.0, (g0 + g1) * 0.5)
			match int(_h(k) * 5.0):
				0:
					# boxes stacked
					for j in range(3):
						var br := Rect2(c.x - 13.0 + inward * float(j) * 7.0 - 6.0, c.y - 16.0 + float(j) * 11.0, 22.0, 14.0)
						_shadow_rect(wc, br, 3.0)
						wc.rect(br, CRATE.lightened(0.08 * float(j)))
						wc.rect(Rect2(br.position.x + br.size.x * 0.5 - 1.0, br.position.y, 2.0, br.size.y), Color(0.85, 0.78, 0.55, 0.6))
				1:
					# a rolled rug or two lying in the gap
					wc.capsule(c + Vector2(-inward * 18.0, -8.0) + Shade.light * 3.0, c + Vector2(inward * 22.0, -8.0) + Shade.light * 3.0, 7.0, SHADOW)
					wc.capsule(c + Vector2(-inward * 18.0, -8.0), c + Vector2(inward * 22.0, -8.0), 6.0, RUG_COLS[k % RUG_COLS.size()])
					wc.capsule(c + Vector2(-inward * 16.0, 8.0), c + Vector2(inward * 18.0, 8.0), 5.0, RUG_COLS[(k + 2) % RUG_COLS.size()])
				2:
					# chairs stacked out of the way
					for j in range(3):
						_chair(wc, c + Vector2(inward * float(j) * 2.0, -float(j) * 5.0), 0.2 * float(j), k + j, 1.0 + float(j) * 0.05)
				3:
					# a crate of odd lamps' shades and a standing lamp
					_lamp(wc, c + Vector2(0.0, -8.0), 9.0, k)
					_lamp(wc, c + Vector2(inward * 10.0, 10.0), 7.0, k + 1)
				_:
					# a mirror leant against the back
					_frame(wc, Rect2(c.x - 9.0, c.y - 18.0, 18.0, 36.0), k, true)


static func _draw_stalls(wc: ShapeBatch, lo: float, hi: float) -> void:
	for i in range(STALL_SOLIDS.size()):
		var r: Rect2 = STALL_SOLIDS[i]
		if r.end.y < lo - 40.0 or r.position.y > hi + 40.0:
			continue
		var face := 1.0 if r.get_center().x < CX else -1.0
		_stall(wc, r, face, i, true)
		# a browser or two at the front, looking at the goods
		var fill := Outdoors.flea_browsers(Game.weather, Game.hour)
		for j in range(2):
			var hk := _h(i * 17 + j * 3 + 1)
			if hk < fill * (0.85 if j == 0 else 0.45):
				var front_x := r.end.x if face > 0.0 else r.position.x
				var p := Vector2(front_x + face * (14.0 + _h(i + j * 7) * 16.0), r.position.y + 12.0 + hk * (r.size.y - 18.0))
				var look := Vector2(-face, (_h(i * 3 + j) - 0.5) * 0.8)
				var o := {}
				if _h(i * 5 + j) < 0.4:
					o["arms"] = NpcFigure.Arms.READY
				NpcFigure.person(wc, p, look, 6100 + i * 5 + j, -1.0, o)


# --- a stall ----------------------------------------------------------------------

enum G { FURNITURE, CHAIRS, LAMPS, RECORDS, BOOKS, CLOTHES, RUGS, BRICA, BIKES, FRAMES, RADIOS, CROCKERY }
const G_COUNT := 12


static func _stall_kind(k: int) -> int:
	# neighbours differ: step through the kinds by a stride prime to their count
	return (k * 5 + int(_h(k * 31 + 2) * 3.0)) % G_COUNT


# One stall seen from above in its pitch `r`. `face` is the side its front is
# on (+1: the lane is towards +x). A tarp hung along the back, a table, a
# blanket or bare floor, the goods, an awning over the back of the pitch, and
# the seller on a folding chair at the front corner.
static func _stall(b: ShapeBatch, r: Rect2, face: float, k: int, people: bool) -> void:
	var kind := _stall_kind(k)
	var back_x := r.position.x if face > 0.0 else r.end.x
	var depth := r.size.x
	var night := Game.hour == "night"
	_shadow_rect(b, r, 4.0, Color(SHADOW.r, SHADOW.g, SHADOW.b, 0.16))
	# the tarp or rack hung along the back
	var back_col: Color = TARPS[k % TARPS.size()]
	b.rect(_u_rect(r, face, 0.0, 6.0, -2.0, r.size.y + 2.0), back_col.darkened(0.25))
	b.rect(_u_rect(r, face, 0.0, 3.0, -2.0, r.size.y + 2.0), back_col.darkened(0.4))
	var u0 := 8.0
	var u1 := depth - 18.0
	var area := _u_rect(r, face, u0, u1, 4.0, r.size.y - 4.0)
	var base := int(_h(k * 7 + 3) * 3.0)
	if kind == G.FURNITURE or kind == G.CHAIRS or kind == G.BIKES:
		base = 2
	if kind == G.RUGS or kind == G.CLOTHES:
		base = 1
	var cloth: Color = CLOTHS[(k * 3 + 1) % CLOTHS.size()]
	match base:
		0:
			# trestle table under a cloth, its hem hanging over the front
			var t := _u_rect(r, face, u0 + 4.0, u1, 2.0, r.size.y - 2.0)
			_shadow_rect(b, t, 5.0)
			b.rect(t, cloth)
			b.rect(_u_rect(r, face, u1 - 4.0, u1, 2.0, r.size.y - 2.0), cloth.darkened(0.18))
		1:
			# a blanket on the floor, its border woven in
			var t := _u_rect(r, face, u0, depth - 4.0, 0.0, r.size.y)
			b.rect(t, cloth.darkened(0.08))
			b.rect(t.grow(-3.0), cloth)
			b.rect(t.grow(-6.0), cloth.lightened(0.06))
	if night:
		# packed up for the night under a roped tarp
		var tarp := _u_rect(r, face, 2.0, depth - 10.0, 0.0, r.size.y)
		_shadow_rect(b, tarp, 6.0)
		var tc: Color = TARPS[(k + 2) % TARPS.size()]
		b.rect(tarp, tc)
		b.rect(tarp.grow(-6.0), tc.lightened(0.08))
		for j in range(3):
			var yy := tarp.position.y + tarp.size.y * (0.2 + 0.3 * float(j))
			b.line(Vector2(tarp.position.x, yy), Vector2(tarp.end.x, yy + 4.0), Color(0.86, 0.80, 0.60), 1.2)
		b.glow(_u_pt(r, face, depth - 4.0, r.size.y * 0.5), 26.0, Color(1.0, 0.80, 0.46, 0.24 * Game.lamp_glow()))
		return
	_goods(b, area, face, kind, k)
	# the awning over the back of the pitch, of its own colour and cut
	if _h(k * 3 + 1) < 0.8:
		var aw_d := 20.0 + _h(k * 5 + 2) * 18.0
		var col: Color = AWNINGS[(k * 7 + int(_h(k) * 4.0)) % AWNINGS.size()]
		var aw := _u_rect(r, face, -2.0, aw_d, -3.0, r.size.y + 3.0)
		_shadow_rect(b, aw, 8.0, Color(SHADOW.r, SHADOW.g, SHADOW.b, 0.22))
		var cut := int(_h(k * 11 + 4) * 3.0)
		b.rect(aw, col)
		match cut:
			0:
				# stripes running out to the lane
				var sy := aw.position.y
				var j := 0
				while sy < aw.end.y:
					if j % 2 == 0:
						b.rect(Rect2(aw.position.x, sy, aw.size.x, 7.0), col.lightened(0.55))
					sy += 7.0
					j += 1
			1:
				# a tarp ridge: lit half and shaded half
				var half := _u_rect(r, face, aw_d * 0.5, aw_d, -3.0, r.size.y + 3.0)
				b.rect(half, col.darkened(0.16))
				b.rect(_u_rect(r, face, aw_d * 0.5 - 1.0, aw_d * 0.5 + 1.0, -3.0, r.size.y + 3.0), col.lightened(0.25))
			_:
				# plain with a contrasting border
				b.rect(aw.grow(-3.0), col.lightened(0.10))
		# the scalloped valance along its front edge
		var vy := aw.position.y + 3.0
		var vx := (aw.end.x if face > 0.0 else aw.position.x)
		while vy < aw.end.y - 2.0:
			b.circle(Vector2(vx, vy + 2.5), 2.6, col.darkened(0.12))
			vy += 5.0
		# string of bulbs along it after dark comes from the light layer; by
		# day a hanging price card
		if _h(k * 13) < 0.5:
			var cp := _u_pt(r, face, aw_d + 3.0, r.size.y * (0.3 + _h(k) * 0.4))
			b.rect(Rect2(cp.x - 4.0, cp.y - 3.0, 8.0, 6.0), Color(0.96, 0.94, 0.86))
			b.rect(Rect2(cp.x - 2.5, cp.y - 1.0, 5.0, 1.0), Color(0.2, 0.2, 0.2))
	if people and Outdoors.flea_sellers(Game.weather, Game.hour) and _h(k * 19 + 5) < 0.85:
		var top := _h(k * 23) < 0.5
		var sp := _u_pt(r, face, depth - 9.0, 9.0 if top else r.size.y - 9.0)
		var chair := Rect2(sp.x - 7.0 - face * 4.0, sp.y - 7.0, 14.0, 14.0)
		b.rect(Rect2(chair.position + Shade.light * 3.0, chair.size), SHADOW)
		b.rect(chair, Color(0.30, 0.42, 0.36) if k % 2 == 0 else Color(0.62, 0.30, 0.24))
		var look := Vector2(face, 0.4 if top else -0.4)
		var o := {"arms": NpcFigure.Arms.READY, "size": 0.92}
		if _h(k * 29) < 0.3:
			o["headwear"] = "cap"
			o["headwear_col"] = AWNINGS[(k + 4) % AWNINGS.size()]
		NpcFigure.person(b, sp, look, 7300 + k * 3, -1.0, o)


# a rect across a stall from `ua` to `ub` out from its back wall, `va` to `vb`
# down its length
static func _u_rect(r: Rect2, face: float, ua: float, ub: float, va: float, vb: float) -> Rect2:
	var xa := r.position.x + ua if face > 0.0 else r.end.x - ub
	return Rect2(xa, r.position.y + va, ub - ua, vb - va)


static func _u_pt(r: Rect2, face: float, u: float, v: float) -> Vector2:
	return Vector2(r.position.x + u if face > 0.0 else r.end.x - u, r.position.y + v)


# --- the goods ------------------------------------------------------------------

static func _goods(b: ShapeBatch, a: Rect2, face: float, kind: int, k: int) -> void:
	var c := a.get_center()
	match kind:
		G.FURNITURE:
			# an armchair, a dresser and a side table
			var ac := Vector2(a.position.x + a.size.x * 0.5, a.position.y + 16.0)
			_armchair(b, ac, face, k)
			var dr := Rect2(a.position.x + 4.0, a.end.y - 26.0, a.size.x - 8.0, 22.0)
			_shadow_rect(b, dr, 6.0)
			b.rect(dr, WOODS[k % WOODS.size()])
			b.rect(dr.grow(-2.0), WOODS[k % WOODS.size()].lightened(0.08))
			for j in range(3):
				var dx := dr.position.x + 4.0 + float(j) * (dr.size.x - 8.0) / 3.0
				b.rect(Rect2(dx, dr.position.y + 4.0, (dr.size.x - 8.0) / 3.0 - 2.0, dr.size.y - 8.0), WOODS[k % WOODS.size()].darkened(0.08))
				b.circle(Vector2(dx + (dr.size.x - 8.0) / 6.0 - 1.0, dr.get_center().y), 1.5, Color(0.86, 0.74, 0.40))
			var st := Vector2(a.position.x + a.size.x * 0.5, a.position.y + a.size.y * 0.5)
			b.circle(st + Shade.light * 3.0, 7.0, SHADOW)
			b.circle(st, 6.5, WOODS[(k + 1) % WOODS.size()])
			b.circle(st + Vector2(-1.5, -1.5), 3.0, WOODS[(k + 1) % WOODS.size()].lightened(0.2))
		G.CHAIRS:
			# odd chairs set out in rows, every one different
			var j := 0
			var yy := a.position.y + 4.0
			while yy < a.end.y - 12.0:
				var xx := a.position.x + 4.0
				while xx < a.end.x - 12.0:
					_chair(b, Vector2(xx + 7.0, yy + 7.0), (_h(k + j) - 0.5) * 0.8, k + j * 5, 1.0)
					xx += 19.0
					j += 1
				yy += 19.0
		G.LAMPS:
			_lamp(b, Vector2(a.position.x + a.size.x * 0.3, a.position.y + 12.0), 10.0, k)
			_lamp(b, Vector2(a.position.x + a.size.x * 0.72, a.position.y + 22.0), 8.0, k + 1)
			_lamp(b, Vector2(a.position.x + a.size.x * 0.35, a.end.y - 14.0), 9.0, k + 2)
			_lamp(b, Vector2(a.position.x + a.size.x * 0.75, a.end.y - 10.0), 6.5, k + 3)
			# a chandelier laid on its side
			var ch := Vector2(a.position.x + a.size.x * 0.55, c.y + 2.0)
			for j in range(5):
				var d := Vector2.from_angle(float(j) * TAU / 5.0) * 6.0
				b.line(ch, ch + d, Color(0.78, 0.66, 0.36), 1.2)
				b.circle(ch + d, 1.8, Color(0.96, 0.92, 0.78))
		G.RECORDS:
			# record crates: the sleeves' tops packed edge to edge
			var j := 0
			var yy := a.position.y + 2.0
			while yy < a.end.y - 14.0:
				var cr := Rect2(a.position.x + 2.0, yy, minf(a.size.x - 4.0, 32.0), 18.0)
				_shadow_rect(b, cr, 3.0)
				b.rect(cr, CRATE)
				b.rect(cr.grow(-2.0), Color(0.12, 0.11, 0.12))
				var sx := cr.position.x + 3.0
				var n := 0
				while sx < cr.end.x - 3.0:
					b.rect(Rect2(sx, cr.position.y + 3.0, 1.5, cr.size.y - 6.0), SLEEVES[(k + j * 3 + n) % SLEEVES.size()])
					sx += 2.5
					n += 1
				yy += 21.0
				j += 1
			# a few covers laid out face up, one with its disc half out
			for q in range(2):
				var cv := Rect2(a.end.x - 16.0, a.position.y + 4.0 + float(q) * 18.0, 14.0, 14.0)
				var cc: Color = SLEEVES[(k + q * 2) % SLEEVES.size()]
				b.rect(cv, cc)
				b.rect(Rect2(cv.position.x + 2.0, cv.position.y + 2.0, 10.0, 4.0), cc.lightened(0.35))
				if q == 0:
					b.circle(cv.get_center() + Vector2(0.0, 5.0), 6.0, RECORD)
					b.circle(cv.get_center() + Vector2(0.0, 5.0), 2.0, Color(0.90, 0.30, 0.20))
		G.BOOKS:
			# boxes of books spine-up, and a few piles
			var yy := a.position.y + 2.0
			var j := 0
			while yy < a.end.y - 16.0:
				var bx := Rect2(a.position.x + 2.0, yy, a.size.x * 0.6, 18.0)
				_shadow_rect(b, bx, 3.0)
				b.rect(bx, Color(0.66, 0.52, 0.34))
				var sx := bx.position.x + 2.0
				var n := 0
				while sx < bx.end.x - 3.0:
					var w := 2.5 + _h(k + n) * 2.0
					b.rect(Rect2(sx, bx.position.y + 2.0, w - 0.5, bx.size.y - 4.0), SPINES[(k + n + j) % SPINES.size()])
					sx += w
					n += 1
				yy += 21.0
				j += 1
			for q in range(3):
				var p := Vector2(a.end.x - 10.0, a.position.y + 8.0 + float(q) * 18.0)
				for s in range(3):
					var bc: Color = SPINES[(k + q * 3 + s) % SPINES.size()]
					b.quad(p + Vector2(-7.0, -5.0).rotated(float(s) * 0.15), p + Vector2(7.0, -5.0).rotated(float(s) * 0.15),
						p + Vector2(7.0, 5.0).rotated(float(s) * 0.15), p + Vector2(-7.0, 5.0).rotated(float(s) * 0.15), bc)
		G.CLOTHES:
			# a clothes rail down the pitch, everything hung across it
			var rx := c.x - face * 6.0
			b.rect(Rect2(rx - 1.0 + Shade.light.x * 6.0, a.position.y + 2.0 + Shade.light.y * 6.0, 14.0, a.size.y - 4.0), SHADOW)
			var yy := a.position.y + 4.0
			var j := 0
			while yy < a.end.y - 4.0:
				var gc: Color = GARMENTS[(k + j) % GARMENTS.size()]
				var gl := 11.0 + _h(k + j) * 5.0
				b.quad(Vector2(rx - gl, yy), Vector2(rx + gl, yy), Vector2(rx + gl - 1.0, yy + 4.5), Vector2(rx - gl + 1.0, yy + 4.5), gc)
				b.rect(Rect2(rx - gl, yy, gl * 2.0, 1.2), gc.lightened(0.25))
				yy += 4.0 + _h(k * 3 + j) * 1.5
				j += 1
			b.rect(Rect2(rx - 1.0, a.position.y, 2.0, a.size.y), Color(0.70, 0.72, 0.74))
			# and a heap of shoes at its foot
			for q in range(4):
				var sp := Vector2(a.end.x - 6.0 if face > 0.0 else a.position.x + 6.0, a.position.y + 8.0 + float(q) * 12.0)
				b.capsule(sp + Vector2(0.0, -3.0), sp + Vector2(0.0, 3.0), 2.8, GARMENTS[(k + q + 3) % GARMENTS.size()].darkened(0.3))
		G.RUGS:
			# rugs laid out flat, borders and a medallion, one rolled
			var rug := Rect2(a.position.x + 2.0, a.position.y + 2.0, a.size.x - 4.0, a.size.y * 0.62)
			_rug(b, rug, k)
			var roll_y := a.end.y - 9.0
			b.capsule(Vector2(a.position.x + 4.0, roll_y) + Shade.light * 3.0, Vector2(a.end.x - 4.0, roll_y) + Shade.light * 3.0, 7.0, SHADOW)
			b.capsule(Vector2(a.position.x + 4.0, roll_y), Vector2(a.end.x - 4.0, roll_y), 6.0, RUG_COLS[(k + 1) % RUG_COLS.size()])
			b.capsule(Vector2(a.position.x + 4.0, roll_y - 2.0), Vector2(a.end.x - 4.0, roll_y - 2.0), 2.0, RUG_COLS[(k + 1) % RUG_COLS.size()].lightened(0.2))
		G.BRICA:
			# bric-a-brac: cups, vases, a clock, a doll's head, tins, all over the cloth
			var n := 0
			var yy := a.position.y + 5.0
			while yy < a.end.y - 4.0:
				var xx := a.position.x + 5.0 + fmod(float(n) * 3.0, 6.0)
				while xx < a.end.x - 4.0:
					_trinket(b, Vector2(xx, yy), k * 7 + n)
					xx += 9.0 + _h(k + n) * 4.0
					n += 1
				yy += 9.0 + _h(k * 2 + n) * 3.0
		G.BIKES:
			# old bicycles stood side by side, a box of parts
			var yy := a.position.y + 8.0
			var j := 0
			while yy < a.end.y - 4.0:
				_bike(b, Vector2(c.x, yy), a.size.x - 6.0, k + j)
				yy += 13.0
				j += 1
		G.FRAMES:
			# paintings and mirrors laid face up, gilt and plain frames
			_frame(b, Rect2(a.position.x + 2.0, a.position.y + 2.0, a.size.x * 0.55, a.size.y * 0.45), k, false)
			_frame(b, Rect2(a.position.x + a.size.x * 0.6, a.position.y + 4.0, a.size.x * 0.38, a.size.y * 0.3), k + 1, true)
			_frame(b, Rect2(a.position.x + 4.0, a.position.y + a.size.y * 0.52, a.size.x * 0.42, a.size.y * 0.44), k + 2, false)
			_frame(b, Rect2(a.position.x + a.size.x * 0.52, a.position.y + a.size.y * 0.42, a.size.x * 0.44, a.size.y * 0.52), k + 3, k % 2 == 0)
		G.RADIOS:
			# old radios, a television, a typewriter
			var tv := Rect2(a.position.x + 2.0, a.position.y + 2.0, 26.0, 22.0)
			_shadow_rect(b, tv, 5.0)
			b.rect(tv, Color(0.42, 0.30, 0.20))
			b.rect(Rect2(tv.position.x + 3.0, tv.position.y + 3.0, 16.0, 16.0), Color(0.30, 0.38, 0.36))
			b.rect(Rect2(tv.position.x + 5.0, tv.position.y + 5.0, 5.0, 3.0), Color(0.7, 0.8, 0.8, 0.5))
			b.circle(Vector2(tv.end.x - 4.0, tv.position.y + 7.0), 1.8, Color(0.86, 0.80, 0.60))
			for q in range(3):
				var rp := Rect2(a.position.x + 3.0 + float(q % 2) * 22.0, a.position.y + 28.0 + float(q) * 9.0, 20.0, 11.0)
				var rc: Color = [Color(0.78, 0.68, 0.50), Color(0.56, 0.22, 0.18), Color(0.30, 0.46, 0.50)][q]
				_shadow_rect(b, rp, 3.0)
				b.rect(rp, rc)
				b.rect(Rect2(rp.position.x + 2.0, rp.position.y + 2.0, 9.0, 7.0), rc.darkened(0.3))
				b.circle(Vector2(rp.end.x - 5.0, rp.get_center().y), 2.5, Color(0.90, 0.86, 0.72))
			var tw := Rect2(a.end.x - 22.0, a.position.y + 6.0, 20.0, 16.0)
			_shadow_rect(b, tw, 3.0)
			b.rect(tw, Color(0.14, 0.14, 0.15))
			for q in range(3):
				b.rect(Rect2(tw.position.x + 3.0, tw.position.y + 6.0 + float(q) * 3.0, 14.0, 1.5), Color(0.80, 0.80, 0.76))
			b.rect(Rect2(tw.position.x + 2.0, tw.position.y - 3.0, 16.0, 4.0), Color(0.96, 0.96, 0.92))
		_:
			# crockery: plates stacked in boxes, glass bottles in a crate
			var yy := a.position.y + 2.0
			var j := 0
			while yy < a.end.y - 14.0:
				var bx := Rect2(a.position.x + 2.0, yy, a.size.x * 0.55, 18.0)
				_shadow_rect(b, bx, 3.0)
				b.rect(bx, CRATE.lightened(0.1))
				var px := bx.position.x + 7.0
				while px < bx.end.x - 4.0:
					var pc: Color = PLATES[(k + j + int(px)) % PLATES.size()]
					b.circle(Vector2(px, bx.get_center().y), 6.0, pc.darkened(0.1))
					b.circle(Vector2(px, bx.get_center().y), 4.0, pc)
					b.circle(Vector2(px, bx.get_center().y), 1.6, pc.darkened(0.12))
					px += 10.0
				yy += 21.0
				j += 1
			var gx := a.end.x - 18.0
			var gr := Rect2(gx, a.position.y + 4.0, 16.0, a.size.y - 8.0)
			b.rect(gr, CRATE.darkened(0.1))
			var gy := gr.position.y + 4.0
			var n := 0
			while gy < gr.end.y - 3.0:
				for q in range(2):
					var bc: Color = [Color(0.28, 0.50, 0.30, 0.9), Color(0.62, 0.40, 0.16, 0.9), Color(0.70, 0.80, 0.84, 0.8)][(n + q) % 3]
					b.circle(Vector2(gr.position.x + 4.5 + float(q) * 7.0, gy), 3.0, bc)
					b.circle(Vector2(gr.position.x + 3.8 + float(q) * 7.0, gy - 0.8), 1.0, Color(1, 1, 1, 0.6))
				gy += 7.0
				n += 1


static func _armchair(b: ShapeBatch, p: Vector2, face: float, k: int) -> void:
	var col: Color = UPHOLSTERY[k % UPHOLSTERY.size()]
	var r := Rect2(p.x - 13.0, p.y - 12.0, 26.0, 24.0)
	_shadow_rect(b, r, 6.0)
	b.rect(r, col.darkened(0.15))
	# back along the stall's back, arms down the sides
	var back_x := r.position.x if face > 0.0 else r.end.x - 6.0
	b.rect(Rect2(back_x, r.position.y, 6.0, r.size.y), col.darkened(0.28))
	b.rect(Rect2(r.position.x, r.position.y, r.size.x, 5.0), col.darkened(0.22))
	b.rect(Rect2(r.position.x, r.end.y - 5.0, r.size.x, 5.0), col.darkened(0.22))
	b.rect(Rect2(r.position.x + (7.0 if face > 0.0 else 3.0), r.position.y + 6.0, 16.0, 12.0), col.lightened(0.12))


static func _chair(b: ShapeBatch, p: Vector2, rot: float, k: int, s: float) -> void:
	var col: Color = CHAIRS_COLS[k % CHAIRS_COLS.size()]
	var x := Vector2(cos(rot), sin(rot)) * 7.0 * s
	var y := Vector2(-sin(rot), cos(rot)) * 7.0 * s
	b.quad(p - x - y + Shade.light * 4.0, p + x - y + Shade.light * 4.0, p + x + y + Shade.light * 4.0, p - x + y + Shade.light * 4.0, SHADOW)
	b.quad(p - x - y, p + x - y, p + x + y, p - x + y, col)
	b.quad(p - x * 0.8 - y * 0.8, p + x * 0.8 - y * 0.8, p + x * 0.8 + y * 0.6, p - x * 0.8 + y * 0.6, col.lightened(0.14))
	# the back rail
	b.quad(p - x - y * 1.25, p + x - y * 1.25, p + x - y * 0.8, p - x - y * 0.8, col.darkened(0.3))


static func _lamp(b: ShapeBatch, p: Vector2, r: float, k: int) -> void:
	var col: Color = SHADES[k % SHADES.size()]
	b.circle(p + Shade.light * (r * 0.9), r, Color(SHADOW.r, SHADOW.g, SHADOW.b, 0.18))
	b.circle(p, r, col.darkened(0.18))
	b.circle(p, r - 2.0, col)
	b.circle(p, r * 0.42, col.lightened(0.35))
	b.circle(p, 1.6, Color(0.70, 0.60, 0.30))
	if Game.lamp_glow() > 0.05:
		b.glow(p, r * 2.6, Color(1.0, 0.86, 0.55, 0.30 * Game.lamp_glow()))


static func _rug(b: ShapeBatch, r: Rect2, k: int) -> void:
	var col: Color = RUG_COLS[k % RUG_COLS.size()]
	var trim: Color = RUG_COLS[(k + 3) % RUG_COLS.size()]
	b.rect(r, trim)
	b.rect(r.grow(-3.0), col)
	b.rect(r.grow(-5.0), col.lightened(0.06))
	var c := r.get_center()
	var hw := r.size.x * 0.32
	var hh := r.size.y * 0.34
	b.polygon(PackedVector2Array([c + Vector2(0.0, -hh), c + Vector2(hw, 0.0), c + Vector2(0.0, hh), c + Vector2(-hw, 0.0)]), trim)
	b.polygon(PackedVector2Array([c + Vector2(0.0, -hh * 0.55), c + Vector2(hw * 0.55, 0.0), c + Vector2(0.0, hh * 0.55), c + Vector2(-hw * 0.55, 0.0)]), col.lightened(0.25))
	# fringe
	var x := r.position.x + 1.0
	while x < r.end.x:
		b.rect(Rect2(x, r.position.y - 2.0, 1.0, 2.0), Color(0.92, 0.88, 0.76))
		b.rect(Rect2(x, r.end.y, 1.0, 2.0), Color(0.92, 0.88, 0.76))
		x += 3.0


static func _trinket(b: ShapeBatch, p: Vector2, k: int) -> void:
	var col: Color = TRINKETS[k % TRINKETS.size()]
	match int(_h(k) * 5.0):
		0:
			# a cup and saucer
			b.circle(p, 3.6, Color(0.94, 0.92, 0.86))
			b.circle(p, 2.4, col)
			b.circle(p + Vector2(3.0, 0.0), 1.0, Color(0.94, 0.92, 0.86))
		1:
			# a vase
			b.circle(p + Shade.light * 2.0, 3.6, SHADOW)
			b.circle(p, 3.4, col)
			b.circle(p, 1.4, col.darkened(0.4))
		2:
			# a clock
			b.circle(p, 3.8, Color(0.62, 0.46, 0.26))
			b.circle(p, 2.9, Color(0.96, 0.94, 0.88))
			b.line(p, p + Vector2(0.0, -2.2), Color(0.1, 0.1, 0.1), 0.8)
			b.line(p, p + Vector2(1.6, 0.4), Color(0.1, 0.1, 0.1), 0.8)
		3:
			# a tin box
			b.rect(Rect2(p.x - 3.5, p.y - 2.5, 7.0, 5.0), col)
			b.rect(Rect2(p.x - 3.5, p.y - 2.5, 7.0, 1.5), col.lightened(0.3))
		_:
			# a figurine
			b.capsule(p + Vector2(0.0, -2.0), p + Vector2(0.0, 2.0), 1.8, col.lightened(0.2))
			b.circle(p + Vector2(0.0, -3.0), 1.4, Color(0.94, 0.88, 0.80))


static func _bike(b: ShapeBatch, p: Vector2, w: float, k: int) -> void:
	var col: Color = BIKES[k % BIKES.size()]
	var hw := w * 0.5
	b.capsule(p + Vector2(-hw + 2.0, 0.0) + Shade.light * 4.0, p + Vector2(hw - 2.0, 0.0) + Shade.light * 4.0, 2.5, SHADOW)
	b.capsule(p + Vector2(-hw + 2.0, 0.0), p + Vector2(-hw * 0.3, 0.0), 1.6, Color(0.10, 0.10, 0.10))
	b.capsule(p + Vector2(hw * 0.3, 0.0), p + Vector2(hw - 2.0, 0.0), 1.6, Color(0.10, 0.10, 0.10))
	b.line(p + Vector2(-hw * 0.6, 0.0), p + Vector2(hw * 0.6, 0.0), col, 2.2)
	b.line(p + Vector2(hw * 0.55, -4.0), p + Vector2(hw * 0.55, 4.0), Color(0.72, 0.74, 0.76), 1.6)
	b.capsule(p + Vector2(-hw * 0.3, 0.0), p + Vector2(-hw * 0.15, 0.0), 1.8, Color(0.20, 0.14, 0.10))
	if k % 3 == 0:
		b.rect(Rect2(p.x - hw * 0.7 - 3.0, p.y - 3.0, 6.0, 6.0), Color(0.62, 0.48, 0.28))


static func _frame(b: ShapeBatch, r: Rect2, k: int, mirror: bool) -> void:
	var gilt := _h(k * 3) < 0.5
	var fc := Color(0.80, 0.64, 0.28) if gilt else WOODS[k % WOODS.size()]
	_shadow_rect(b, r, 4.0)
	b.rect(r, fc.darkened(0.15))
	b.rect(r.grow(-1.5), fc)
	var inner := r.grow(-3.5)
	if inner.size.x < 2.0 or inner.size.y < 2.0:
		return
	if mirror:
		b.rect(inner, Color(0.66, 0.74, 0.80))
		b.quad(inner.position + Vector2(inner.size.x * 0.2, 0.0), inner.position + Vector2(inner.size.x * 0.5, 0.0),
			inner.position + Vector2(inner.size.x * 0.2, inner.size.y), inner.position + Vector2(0.0, inner.size.y),
			Color(0.95, 0.97, 1.0, 0.45))
	else:
		# a landscape: sky over hills, or a portrait's dark ground and a face
		if _h(k * 5) < 0.6:
			b.rect(inner, Color(0.56, 0.70, 0.80))
			b.rect(Rect2(inner.position.x, inner.position.y + inner.size.y * 0.55, inner.size.x, inner.size.y * 0.45), Color(0.40, 0.52, 0.30))
			b.circle(inner.position + inner.size * Vector2(0.75, 0.3), minf(inner.size.x, inner.size.y) * 0.12, Color(0.98, 0.90, 0.60))
		else:
			b.rect(inner, Color(0.22, 0.18, 0.16))
			b.circle(inner.get_center() + Vector2(0.0, -inner.size.y * 0.1), minf(inner.size.x, inner.size.y) * 0.22, Color(0.86, 0.70, 0.56))


static func _draw_stilts(wc: ShapeBatch, lo: float, hi: float) -> void:
	# the canopy's steel stilts: a base plate, and the long shadow of a column
	# that goes up out of sight (the column itself is draw_column)
	for sp: Vector2 in STILTS:
		if sp.y < lo - 140.0 or sp.y > hi + 40.0:
			continue
		wc.rect(Rect2(sp.x - 14.0, sp.y - 14.0, 28.0, 28.0), STILT_DARK.lightened(0.2))
		wc.rect(Rect2(sp.x - 12.0, sp.y - 12.0, 24.0, 24.0), STILT.darkened(0.1))
		for c: Vector2 in [Vector2(-9.0, -9.0), Vector2(9.0, -9.0), Vector2(-9.0, 9.0), Vector2(9.0, 9.0)]:
			wc.circle(sp + c, 1.8, STILT_DARK)


# The auction corner: a timber dais in an open ring of the floor, the lots
# heaped round its north rim, the auctioneer's rostrum, and rows of folding
# chairs either side of the lane full of bidders with their paddles.
static func _draw_auction(wc: ShapeBatch, lo: float, hi: float) -> void:
	if AUCTION_Y < lo - 220.0 or AUCTION_Y > hi + 220.0:
		return
	var c := Vector2(CX, AUCTION_Y)
	var R := AUCTION_R + 28.0
	# a rope ring on posts round the dais
	wc.circle(c + Shade.light * 6.0, R + 6.0, Color(SHADOW.r, SHADOW.g, SHADOW.b, 0.20))
	wc.circle(c, R + 6.0, Color(0.40, 0.28, 0.18))
	wc.circle(c, R, AUCTION_TIMBER)
	# boards
	var by := c.y - R
	while by < c.y + R:
		var dx := sqrt(maxf(0.0, R * R - (by - c.y) * (by - c.y)))
		wc.rect(Rect2(c.x - dx, by, dx * 2.0, 1.2), Color(0.30, 0.20, 0.10, 0.35))
		by += 9.0
	wc.glow(c + Vector2(-R * 0.3, -R * 0.3), R * 0.8, Color(1.0, 0.92, 0.76, 0.16))
	for j in range(16):
		var a := TAU * float(j) / 16.0
		var pp := c + Vector2.from_angle(a) * (R + 3.0)
		wc.circle(pp + Shade.light * 3.0, 3.2, SHADOW)
		wc.circle(pp, 3.0, Color(0.72, 0.62, 0.30))
	for j in range(16):
		var a0 := TAU * float(j) / 16.0
		var a1 := TAU * float(j + 1) / 16.0
		var mid := c + Vector2.from_angle((a0 + a1) * 0.5) * (R + 6.0)
		wc.line(c + Vector2.from_angle(a0) * (R + 3.0), mid, AUCTION_ROPE, 1.6)
		wc.line(mid, c + Vector2.from_angle(a1) * (R + 3.0), AUCTION_ROPE, 1.6)
	# the lots, heaped round the north rim
	var lots := [
		[Vector2(-58.0, -58.0), 0], [Vector2(-26.0, -78.0), 1], [Vector2(10.0, -82.0), 2],
		[Vector2(44.0, -70.0), 3], [Vector2(70.0, -40.0), 4], [Vector2(-76.0, -24.0), 5],
	]
	for lot: Array in lots:
		var lp: Vector2 = c + Vector2(lot[0])
		match int(lot[1]):
			0:
				_armchair(wc, lp, 1.0, 2)
			1:
				var wr := Rect2(lp.x - 22.0, lp.y - 10.0, 44.0, 20.0)
				_shadow_rect(wc, wr, 14.0)
				wc.rect(wr, Color(0.40, 0.26, 0.16))
				wc.rect(wr.grow(-2.0), Color(0.50, 0.34, 0.20))
				wc.rect(Rect2(wr.get_center().x - 1.0, wr.position.y + 2.0, 2.0, wr.size.y - 4.0), Color(0.30, 0.20, 0.12))
			2:
				# a rocking horse
				wc.capsule(lp + Vector2(-14.0, 6.0) + Shade.light * 4.0, lp + Vector2(14.0, 6.0) + Shade.light * 4.0, 4.0, SHADOW)
				wc.capsule(lp + Vector2(-14.0, 6.0), lp + Vector2(14.0, 6.0), 2.0, Color(0.40, 0.26, 0.14))
				wc.capsule(lp + Vector2(-9.0, 0.0), lp + Vector2(8.0, 0.0), 5.0, Color(0.92, 0.90, 0.86))
				wc.circle(lp + Vector2(12.0, -3.0), 4.0, Color(0.92, 0.90, 0.86))
				wc.rect(Rect2(lp.x - 4.0, lp.y - 5.0, 6.0, 10.0), Color(0.76, 0.20, 0.18))
			3:
				# a grandfather clock laid down
				var gr := Rect2(lp.x - 8.0, lp.y - 20.0, 16.0, 40.0)
				_shadow_rect(wc, gr, 6.0)
				wc.rect(gr, Color(0.36, 0.22, 0.12))
				wc.circle(Vector2(gr.get_center().x, gr.position.y + 9.0), 6.0, Color(0.94, 0.90, 0.78))
				wc.circle(Vector2(gr.get_center().x, gr.position.y + 26.0), 3.5, Color(0.84, 0.70, 0.30))
			4:
				for q in range(3):
					_chair(wc, lp + Vector2(float(q) * 4.0, float(q) * -4.0), 0.3 * float(q), 3 + q, 1.1 + float(q) * 0.05)
			_:
				_lamp(wc, lp, 11.0, 6)
	# the rostrum: a raised lectern on its crate, the auctioneer behind it
	var ro := Rect2(c.x - 20.0, c.y - R + 22.0, 40.0, 18.0)
	_shadow_rect(wc, ro, 10.0)
	wc.rect(ro, Color(0.30, 0.18, 0.10))
	wc.rect(ro.grow(-2.0), Color(0.46, 0.30, 0.16))
	wc.rect(Rect2(ro.position.x + 4.0, ro.end.y - 6.0, ro.size.x - 8.0, 4.0), Color(0.86, 0.72, 0.36))
	NpcFigure.person(wc, Vector2(c.x, ro.position.y - 4.0), Vector2(0.0, 1.0), 8801, -1.0,
		{"top": Color(0.20, 0.20, 0.24), "hair_style": "bald", "arms": NpcFigure.Arms.READY})
	# the bidders on folding chairs, rows either side of the lane
	for side: float in [-1.0, 1.0]:
		for col in range(3):
			var x := (PATH_L + 26.0 + float(col) * 30.0) if side < 0.0 else (PATH_R - 26.0 - float(col) * 30.0)
			for row in range(7):
				var y := AUCTION_Y - 96.0 + float(row) * 30.0
				var k := col * 11 + row * 3 + (50 if side > 0.0 else 0)
				var face := Vector2(-side, 0.0)
				var cp := Vector2(x, y)
				_chair(wc, cp - face * 3.0, side * PI * 0.5, k, 1.05)
				if _h(k * 7 + 2) < 0.9:
					var o := {"arms": NpcFigure.Arms.READY if _h(k) < 0.7 else NpcFigure.Arms.SIDE}
					NpcFigure.person(wc, cp, face, 8900 + k, -1.0, o)
					if _h(k * 5) < 0.18:
						# a bidder's paddle up
						var pad := cp + face * 10.0 + Vector2(0.0, -6.0)
						wc.rect(Rect2(pad.x - 4.0, pad.y - 4.0, 8.0, 8.0), Color(0.98, 0.96, 0.90))
						wc.rect(Rect2(pad.x - 2.0, pad.y - 1.0, 4.0, 2.0), Color(0.80, 0.16, 0.16))


# The tower of chairs that spills: crates at its foot and chairs stacked high,
# each one a little bigger and offset as it rises towards the eye, the top one
# already tipping, and its long shadow down the lane.
static func _draw_spill_stack_static(wc: ShapeBatch, lo: float, hi: float) -> void:
	if SPILL_Y < lo - 160.0 or SPILL_Y > hi + 160.0:
		return
	var base := SPILL_STALL
	_tall_shadow(wc, base, 22.0, 150.0, 0.32)
	wc.circle(base + Vector2(4.0, 6.0), 26.0, Color(SHADOW.r, SHADOW.g, SHADOW.b, 0.24))
	for q in range(3):
		var cr := Rect2(base.x - 26.0 + float(q) * 16.0, base.y + 4.0 - float(q % 2) * 6.0, 22.0, 16.0)
		_shadow_rect(wc, cr, 4.0)
		wc.rect(cr, CRATE.lightened(0.05 * float(q)))
		wc.rect(Rect2(cr.position.x, cr.position.y + 7.0, cr.size.x, 2.0), CRATE.darkened(0.2))
	for k in range(10):
		var rise := float(k)
		var p := base + Vector2(-rise * 1.2 + (2.0 if k % 2 == 0 else -2.0), -rise * 7.5)
		var s := 1.15 + rise * 0.045
		_chair(wc, p, (0.22 if k % 2 == 0 else -0.18) + rise * 0.02, 20 + k * 3, s)
	# the top one, tipped and catching the light
	var tp := base + Vector2(-8.0, -84.0)
	_chair(wc, tp, 0.9, 7, 1.6)
	wc.glow(tp, 18.0, Color(1.0, 0.92, 0.60, 0.22))
	var seller := base + Vector2(40.0, 16.0)
	wc.rect(Rect2(seller.x - 7.0, seller.y - 4.0, 14.0, 14.0), Color(0.30, 0.42, 0.36))
	NpcFigure.person(wc, seller, Vector2(-1.0, -0.3), 8711, -1.0, {"arms": NpcFigure.Arms.UP, "headwear": "cap", "headwear_col": Color(0.72, 0.18, 0.16)})


# Where the canopy ends over the open street: a darker line of drips on the
# paving, puddles along it in the rain.
static func _draw_drip_line(wc: ShapeBatch, lo: float, hi: float) -> void:
	for edge: float in [CANOPY_Y0, CANOPY_Y1]:
		if edge < lo - 40.0 or edge > hi + 40.0:
			continue
		var out := 1.0 if edge == CANOPY_Y0 else -1.0
		if _rainy():
			wc.band(PackedVector2Array([
				Vector2(PATH_L, edge), Vector2(PATH_R, edge),
				Vector2(PATH_L, edge + out * 10.0), Vector2(PATH_R, edge + out * 10.0),
				Vector2(PATH_L, edge + out * 26.0), Vector2(PATH_R, edge + out * 26.0),
			]), 2, Color(0.16, 0.22, 0.32, 0.45), PackedFloat32Array([0.0, 1.0, 0.0]))
			var x := PATH_L + 20.0
			var k := 0
			while x < PATH_R - 10.0:
				if _h(k * 3 + int(absf(edge))) < 0.5:
					wc.glow(Vector2(x, edge + out * 14.0), 14.0 + _h(k) * 12.0, Color(0.30, 0.40, 0.54, 0.45))
				x += 34.0
				k += 1


# --- overhead: the mirrored canopy -------------------------------------------------

static func draw_overhead(m: Node2D, ci: Object) -> void:
	var b := ShapeBatch.new(ci)
	b.lod = true
	var vt: float = m.view_lo(160.0) if m.has_method("view_lo") else -6000.0
	var vb: float = m.view_hi(160.0) if m.has_method("view_hi") else 600.0
	var lo := maxf(vt - 40.0, CANOPY_Y1)
	var hi := minf(vb + 40.0, CANOPY_Y0)
	if hi > lo:
		_canopy_flank(b, lo, hi, -1.0)
		_canopy_flank(b, lo, hi, 1.0)
	for edge: float in [CANOPY_Y0, CANOPY_Y1]:
		if edge > vt - 80.0 and edge < vb + 80.0:
			_fascia(b, edge)
	if m.has_method("_lamp_head"):
		for lp: Vector2 in STREET_LAMPS:
			if lp.y > vt - 40.0 and lp.y < vb + 40.0:
				m._lamp_head(b, lp)
	b.flush()


# The canopy over the market either side of the lane: its mirrored underside
# in tilted facets, each catching the stalls below in its own warm or cool
# tone, steel joints between them, and the steel edge beam along the lane.
static func _canopy_flank(b: ShapeBatch, lo: float, hi: float, side: float) -> void:
	var edge_x := PATH_L - 4.0 if side < 0.0 else PATH_R + 4.0
	var cell := 74.0
	var row0 := int(floorf(lo / cell))
	var row1 := int(ceilf(hi / cell))
	var cols := 5
	for row in range(row0, row1):
		for col in range(cols):
			var p00 := _facet_pt(edge_x, side, col, row, cell)
			var p10 := _facet_pt(edge_x, side, col + 1, row, cell)
			var p01 := _facet_pt(edge_x, side, col, row + 1, cell)
			var p11 := _facet_pt(edge_x, side, col + 1, row + 1, cell)
			var a := FACET_ALPHA[mini(col, FACET_ALPHA.size() - 1)]
			var k := absi(row) * 7 + col * 13 + (0 if side < 0.0 else 3)
			var ca: Color = MIRRORS[int(_h(k) * float(MIRRORS.size())) % MIRRORS.size()]
			var cb: Color = MIRRORS[int(_h(k + 1) * float(MIRRORS.size())) % MIRRORS.size()]
			if (row + col) % 2 == 0:
				b.polygon(PackedVector2Array([p00, p10, p11]), Color(ca, a))
				b.polygon(PackedVector2Array([p00, p11, p01]), Color(cb.darkened(0.1), a))
			else:
				b.polygon(PackedVector2Array([p00, p10, p01]), Color(ca.lightened(0.05), a))
				b.polygon(PackedVector2Array([p10, p11, p01]), Color(cb, a))
			# a stall's colour caught warped in the mirror
			if _h(k + 5) < 0.45:
				var rc: Color = AWNINGS[k % AWNINGS.size()]
				b.glow((p00 + p11) * 0.5, cell * 0.42, Color(rc, a * 0.45))
			var jc := Color(0.80, 0.82, 0.84, a * 0.8)
			b.line(p00, p10, jc, 1.5)
			b.line(p00, p01, jc, 1.5)
			b.line(p00, p11 if (row + col) % 2 == 0 else p01, Color(0.30, 0.32, 0.36, a * 0.5), 1.0)
	# the soft shade the canopy throws at its edge onto the lane below
	var shade_x := edge_x - side * 46.0
	b.band(PackedVector2Array([
		Vector2(minf(edge_x, shade_x), lo), Vector2(maxf(edge_x, shade_x), lo),
		Vector2(minf(edge_x, shade_x), hi), Vector2(maxf(edge_x, shade_x), hi),
	]), 2, Color(0.04, 0.05, 0.08, 0.14), PackedFloat32Array([1.0, 1.0]),
		PackedFloat32Array([0.0, 1.0]) if side < 0.0 else PackedFloat32Array([1.0, 0.0]))
	# the edge beam: a steel box section with its lit top and bolted splices
	var bx := edge_x - (14.0 if side < 0.0 else 0.0)
	b.rect(Rect2(bx, lo, 14.0, hi - lo), CANOPY_STEEL)
	b.rect(Rect2(bx + (10.0 if side < 0.0 else 0.0), lo, 4.0, hi - lo), CANOPY_DARK)
	b.rect(Rect2(bx + (2.0 if side < 0.0 else 6.0), lo, 3.0, hi - lo), Color(0.92, 0.94, 0.96, 0.8))
	var sy := floorf(lo / 74.0) * 74.0
	while sy < hi:
		b.rect(Rect2(bx - 1.0, sy - 3.0, 16.0, 6.0), CANOPY_DARK.lightened(0.1))
		b.circle(Vector2(bx + 4.0, sy), 1.4, Color(0.92, 0.94, 0.96))
		b.circle(Vector2(bx + 10.0, sy), 1.4, Color(0.92, 0.94, 0.96))
		sy += 74.0


static func _facet_pt(edge_x: float, side: float, col: int, row: int, cell: float) -> Vector2:
	# the grid's corners pushed about by a hash, the same corner for every
	# facet that shares it, so the facets tilt without gaps between them
	var jx := (_h(row * 31 + col * 17) - 0.5) * cell * 0.36 if col > 0 else 0.0
	var jy := (_h(row * 13 + col * 29 + 5) - 0.5) * cell * 0.36
	return Vector2(edge_x + side * (float(col) * cell + jx), float(row) * cell + jy)


# The canopy's end across the lane: a deep steel fascia with the mirror's
# facets along its underside, the rain dripping off its outer edge.
static func _fascia(b: ShapeBatch, edge: float) -> void:
	var out := 1.0 if edge == CANOPY_Y0 else -1.0
	var x0 := -200.0
	var x1 := 1480.0
	var y_in := edge - out * 30.0
	var r := Rect2(x0, minf(edge, y_in), x1 - x0, 30.0)
	b.rect(r, CANOPY_STEEL.darkened(0.05))
	var x := x0
	var k := 0
	while x < x1:
		var tip := Vector2(x + 18.0, y_in + out * 4.0)
		var c: Color = MIRRORS[k % MIRRORS.size()]
		b.polygon(PackedVector2Array([Vector2(x, edge - out * 4.0), Vector2(x + 36.0, edge - out * 4.0), tip]), Color(c, 0.85))
		b.polygon(PackedVector2Array([Vector2(x + 18.0, y_in), tip, Vector2(x + 36.0, edge - out * 4.0)]), Color(MIRRORS[(k + 2) % MIRRORS.size()], 0.6))
		x += 36.0
		k += 1
	b.rect(Rect2(x0, edge - (4.0 if out > 0.0 else 0.0), x1 - x0, 4.0), CANOPY_DARK)
	b.rect(Rect2(x0, y_in - (2.0 if out < 0.0 else 0.0), x1 - x0, 2.0), Color(0.92, 0.94, 0.96, 0.8))
	if _rainy():
		var tsec := float(AnimClock.msec()) * 0.001
		var dx := x0 + 6.0
		var di := 0
		while dx < x1:
			var ph := fposmod(tsec * 1.6 + _h(di) * 3.0, 1.0)
			var dp := Vector2(dx + _h(di + 3) * 10.0, edge + out * (2.0 + ph * 22.0))
			b.circle(dp, 2.0 * (1.0 - ph * 0.5), Color(DRIP.r, DRIP.g, DRIP.b, DRIP.a * (1.0 - ph)))
			if ph > 0.75:
				b.glow(Vector2(dp.x, edge + out * 26.0), 8.0, Color(DRIP.r, DRIP.g, DRIP.b, 0.35 * (1.0 - ph) * 4.0))
			dx += 22.0
			di += 1


# --- live: browsers moving between stalls, the auctioneer, the spill ---------------

static func draw_live(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	# browsers on benches
	for br: Dictionary in m.encants_browsers:
		var p: Vector2 = br["pos"]
		if p.y < vt - 40.0 or p.y > vb + 40.0:
			continue
		var o := {"arms": NpcFigure.Arms.READY}
		NpcFigure.person(b, p, Vector2(0.0, 1.0), int(br["key"]), -1.0, o)
		if not _under_canopy(p.y) and _rainy():
			_umbrella(b, p, 17.0, int(br["key"]))
	var tsec := float(AnimClock.msec()) * 0.001
	# shoppers drifting up and down the lane's edges, stopping at a stall
	var fill := Outdoors.flea_browsers(Game.weather, Game.hour)
	for i in range(WALKERS):
		if _h(i * 41 + 7) > fill:
			continue
		var side := -1.0 if i % 2 == 0 else 1.0
		var span := CANOPY_Y0 - CANOPY_Y1 - 160.0
		var speed := 18.0 + _h(i * 5) * 14.0
		var phase := fposmod(tsec * speed + _h(i * 3) * span * 2.0, span * 2.0)
		var going_up := phase < span
		var along := phase if going_up else span * 2.0 - phase
		# pause a while every so often, as if at a stall
		var y := CANOPY_Y0 - 80.0 - along
		if y < vt - 40.0 or y > vb + 40.0:
			continue
		var x := (PATH_L + 118.0 + _h(i * 9) * 110.0) if side < 0.0 else (PATH_R - 118.0 - _h(i * 9) * 110.0)
		var fwd := Vector2(0.0, -1.0) if going_up else Vector2(0.0, 1.0)
		NpcFigure.person(b, Vector2(x, y), fwd, 9100 + i * 7, tsec * speed * 0.45)
	# auction: the auctioneer's gavel arm going
	if AUCTION_Y >= vt - 120.0 and AUCTION_Y <= vb + 120.0:
		var wave := sin(tsec * 6.0) * 5.0
		var ap := Vector2(CX, AUCTION_Y - AUCTION_R - 28.0 + 22.0 - 4.0)
		b.line(ap + Vector2(6.0, 2.0), ap + Vector2(14.0 + wave * 0.3, 4.0 - absf(wave)), Color(0.86, 0.68, 0.54), 2.4)
		b.rect(Rect2(ap.x + 12.0 + wave * 0.3, 1.0 + ap.y - absf(wave), 6.0, 4.0), Color(0.40, 0.24, 0.12))
	# spill wobble / slide over the resting stack
	if SPILL_Y >= vt - 120.0 and SPILL_Y <= vb + 120.0:
		var st: Dictionary = m.encants_spill
		var state := String(st.get("state", "idle"))
		var wob := float(st.get("wobble", 0.0))
		var slide := float(st.get("slide", 0.0))
		var base := SPILL_STALL
		var shake := sin(tsec * 40.0) * wob * 4.0
		if state == "telegraph":
			for k in range(4):
				var p := base + Vector2(-float(6 + k) * 1.2 + shake * (1.0 if k % 2 == 0 else -1.0) * (1.0 + float(k) * 0.4), -float(6 + k) * 7.5)
				_chair(b, p, 0.2 + shake * 0.05 * float(k), 40 + k, 1.4 + float(k) * 0.05)
			b.glow(base + Vector2(-6.0, -60.0), 46.0, Color(1.0, 0.80, 0.30, 0.25 * wob))
		elif state == "spilling" or state == "done":
			for k in range(7):
				var along := slide * (40.0 + float(k) * 20.0)
				var p := base + Vector2(-along + shake * 0.3, float(k % 3) * 14.0 - 14.0)
				if k % 3 == 0:
					_chair(b, p, slide * 3.0 + float(k), 50 + k, 1.2)
				elif k % 3 == 1:
					var cr := Rect2(p.x - 10.0, p.y - 7.0, 20.0, 14.0)
					b.rect(Rect2(cr.position + Shade.light * 3.0, cr.size), SHADOW)
					b.rect(cr, CRATE)
				else:
					b.circle(p, 7.0, RECORD)
					b.circle(p, 2.2, Color(0.90, 0.30, 0.20))


# --- the off-leash square ---------------------------------------------------------

static func draw_freedom(m: Node2D, c: Object) -> void:
	var r: Rect2 = m._freedom_rect()
	var b := ShapeBatch.new()
	b.lod = true
	var pave := _pave()
	var wet := _rainy()
	# Plaça dels Encants: its own panots, a stone kerb, blocks of flats round it
	b.rect(Rect2(r.position.x - 100.0, r.position.y - 100.0, r.size.x + 200.0, r.size.y + 200.0), pave.darkened(0.12))
	b.rect(r, pave)
	Panot.flor(b, r.position.x + 8.0, r.end.x - 8.0, r.position.y + 8.0, r.end.y - 8.0,
		PANOT_WET_GROOVE if wet else PANOT_DRY_GROOVE, PANOT_WET_SHINE if wet else PANOT_DRY_SHINE)
	b.rect(Rect2(r.position.x - 8.0, r.position.y - 8.0, r.size.x + 16.0, 10.0), KERB)
	b.rect(Rect2(r.position.x - 8.0, r.end.y - 2.0, r.size.x + 16.0, 10.0), KERB)
	b.rect(Rect2(r.position.x - 8.0, r.position.y, 10.0, r.size.y), KERB)
	b.rect(Rect2(r.end.x - 2.0, r.position.y, 10.0, r.size.y), KERB)
	# the blocks round the square, their fronts on it
	var y := r.position.y + 10.0
	var k := 0
	while y < r.end.y - 40.0:
		var h := minf(130.0 + _h(k * 5) * 70.0, r.end.y - 20.0 - y)
		_flat_block(b, Rect2(r.position.x - 160.0, y, 170.0, h - 6.0), 1.0, 4100 + k)
		_flat_block(b, Rect2(r.end.x - 10.0, y, 170.0, h - 6.0), -1.0, 4400 + k)
		y += h
		k += 1
	var x := r.position.x + 10.0
	while x < r.end.x - 10.0:
		var w := minf(160.0 + _h(k * 3) * 80.0, r.end.x - 10.0 - x)
		_flat_block(b, Rect2(x, r.position.y - 170.0, w - 6.0, 176.0), 1.0, 4700 + k)
		x += w
		k += 1
	if wet:
		for j in range(9):
			b.glow(Vector2(lerpf(r.position.x + 120.0, r.end.x - 120.0, _h(j * 3)), lerpf(r.position.y + 100.0, r.end.y - 100.0, _h(j * 7))),
				30.0 + _h(j) * 24.0, Color(0.36, 0.44, 0.56, 0.38))
	# lamp posts at the corners
	for corner: Vector2 in [
		Vector2(r.position.x + 30.0, r.position.y + 30.0),
		Vector2(r.end.x - 30.0, r.position.y + 30.0),
		Vector2(r.position.x + 30.0, r.end.y - 30.0),
		Vector2(r.end.x - 30.0, r.end.y - 30.0),
	]:
		b.circle(corner + Shade.light * 5.0, 8.0, SHADOW)
		b.circle(corner, 6.0, LAMP_POST)
		var glow_a := Game.lamp_glow()
		if glow_a > 0.05:
			b.glow(corner, 28.0, Color(1.0, 0.88, 0.55, 0.22 * glow_a))
	b.flush(c)
	if m.has_method("_draw_freedom_benches"):
		m._draw_freedom_benches(c, r, STALL_WOOD)
	if m.has_method("_freedom_sign"):
		m._freedom_sign(c, r, m.gate_text, I18n.t("w_the_encants_square_off_leash"))


static func draw_bollard(m: Node2D, wc: ShapeBatch, h) -> void:
	# Barcelona pilona at a marking spot
	var p: Vector2 = h.pos
	wc.circle(p + Shade.light * 4.0, 9.0, SHADOW)
	wc.circle(p, 8.0, Color(0.78, 0.72, 0.55) if not h.done else Color(0.58, 0.54, 0.42))
	wc.circle(p - Vector2(1.0, 1.0), 5.0, Color(0.90, 0.86, 0.70))
	wc.rect(Rect2(p.x - 3.0, p.y - 3.0, 6.0, 6.0), Color(0.55, 0.50, 0.40))
	if not h.done and h.progress > 0.0:
		wc.draw_arc(p, 17.0, -PI / 2.0, -PI / 2.0 + TAU * h.progress / 0.8, 20, Color(1, 0.95, 0.7), 3.0)


static func draw_column(m: Node2D, wc: ShapeBatch, p: Vector2) -> void:
	if is_lamp(m, p):
		m._draw_lamppost(p)
		return
	# a canopy stilt: a slim steel column going up out of sight, so mostly
	# its long shadow, lit down one side
	m.cast_shadow(wc, p, 7.0, 150.0, 0.22)
	wc.circle(p, 10.0, STILT_DARK)
	wc.circle(p, 8.5, STILT)
	wc.circle(p + Vector2(-2.5, -2.5), 4.5, STILT.lightened(0.35))


static func draw_snack(m: Node2D, wc: ShapeBatch, kp: Vector2) -> void:
	m.contact_shadow(wc, kp, 9.0, 3.0, 0.20)
	wc.circle(kp, 7.0, Color(0.86, 0.62, 0.28))
	wc.line(kp + Vector2(-4.0, 0.0), kp + Vector2(4.0, -2.0), Color(0.95, 0.85, 0.55), 3.0)


# --- night fronts ------------------------------------------------------------------

static func night_fronts(_m: Node2D) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	# the office block's glazed front on the street at Glòries
	var y := -340.0
	var j := 0
	while y > STREET_END + 40.0:
		var kind := NightFronts.kind_of(4600 + j)
		if kind != "":
			out.append(NightFronts.front(Vector2(PATH_R + 4.0, y), -1.0, kind, 4600 + j))
		y -= 150.0
		j += 1
	# the flats on Castillejos past the canopy
	y = CANOPY_Y1 - 90.0
	while y > GATE + 40.0:
		for side: float in [-1.0, 1.0]:
			var kind := NightFronts.kind_of(4650 + j)
			if kind != "":
				var x := PATH_L - 4.0 if side < 0.0 else PATH_R + 4.0
				out.append(NightFronts.front(Vector2(x, y), -side, kind, 4650 + j))
			j += 1
		y -= 170.0
	return out
