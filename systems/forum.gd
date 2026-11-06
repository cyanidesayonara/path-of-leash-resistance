class_name Forum
extends RefCounted

# WALK 30: EL FÒRUM (Parc del Fòrum / Esplanada del Fòrum)
#
# A breezy coastal afternoon at Barcelona's northern seafront where the city
# opens out into the monumental Parc del Fòrum.
#
# Distinctive features:
# - The Pèrgola Fotovoltaica: the colossal inclined solar pergola that dominates
#   the horizon, supported by massive angled steel pylon bases that form
#   substantial leash wrapping obstacles, casting vast diagonal geometric shadows.
# - Concrete skate obstacles & grindable rails: low angled banks and polished steel
#   coping rails along the esplanade, popular with local street skaters.
# - The Mediterranean bathing zone & marina: along the eastern boundary, stepped
#   concrete breaks down into the open blue sea water with salty wave crests.
# - Wind cones (windsocks): tall slender masts with red-and-white striped cones
#   fluttering in the stiff sea breeze.
# - Signature live event: El Skater de l'Esplanada (ForumSkater) cruising across
#   the open pavement practicing an ollie.

const ShapeBatch := preload("res://systems/shape_batch.gd")
const Surfaces := preload("res://world/surfaces.gd")
const ForumSkater := preload("res://systems/forum_skater.gd")

const LIGHT := Vector2(0.5, 0.866)
const SHADOW := Color(0.04, 0.05, 0.07, 0.22)

# --- colors ------------------------------------------------------------------
const CONCRETE_LIGHT := Color(0.74, 0.75, 0.74)
const CONCRETE_DARK := Color(0.64, 0.65, 0.64)
const CONCRETE_JOINT := Color(0.50, 0.52, 0.52)
const SEA_BLUE_DEEP := Color(0.12, 0.38, 0.62)
const SEA_BLUE_SHALLOW := Color(0.22, 0.54, 0.72)
const SEA_FOAM := Color(0.92, 0.96, 0.98, 0.75)
const SEA_WALL_STONE := Color(0.56, 0.56, 0.58)

# Solar Pergola colors
const SOLAR_STEEL_DARK := Color(0.24, 0.26, 0.28)
const SOLAR_STEEL_LIT := Color(0.38, 0.42, 0.46)
const SOLAR_PANEL_BLUE := Color(0.10, 0.24, 0.42)
const SOLAR_CELL_CYAN := Color(0.20, 0.48, 0.74)
const SOLAR_SHADOW := Color(0.06, 0.08, 0.12, 0.32)

# Skate Furniture colors
const SKATE_CONCRETE := Color(0.68, 0.70, 0.68)
const SKATE_RAIL_STEEL := Color(0.85, 0.88, 0.92)
const WINDSOCK_RED := Color(0.88, 0.24, 0.20)
const WINDSOCK_WHITE := Color(0.96, 0.96, 0.94)

# --- layout constants --------------------------------------------------------
const HALF := 280.0
const WALL_L := 360.0
const WALL_R := 920.0

# Massive solar pergola pylon bases (solid rectangular obstacles and wrap points)
const PYLON_NW := Rect2(440.0, -1820.0, 50.0, 70.0)
const PYLON_NE := Rect2(780.0, -1820.0, 50.0, 70.0)
const PYLON_SW := Rect2(440.0, -1380.0, 50.0, 70.0)
const PYLON_SE := Rect2(780.0, -1380.0, 50.0, 70.0)

# Concrete skate banks with grindable coping rails
const SKATE_BANK_1 := Rect2(430.0, -960.0, 70.0, 130.0)
const SKATE_BANK_2 := Rect2(750.0, -3200.0, 70.0, 130.0)

# Sea wall safety boundary on east edge
const SEAWALL_EDGE_X := 870.0

# Unique walk prize (Solar cell trophy at marina plaza podium)
const PRIZE := Vector2(580.0, -4500.0)
const PRIZE_TEXT := "snatch the solar cell trophy from the marina plaza podium"

# Wind cone mast positions
const WINDSOCK_POSTS: Array[Vector2] = [
	Vector2(400.0, -600.0),
	Vector2(850.0, -600.0),
	Vector2(400.0, -2500.0),
	Vector2(850.0, -2500.0),
	Vector2(400.0, -3900.0),
	Vector2(850.0, -3900.0),
]


static func build(m: Node2D) -> Array:
	m.gate_text = "ESPLANADA DEL FÒRUM"
	m.walk_cx = 640.0
	m.walk_half = HALF
	m.sw_l = WALL_L
	m.sw_r = WALL_R
	m.gate_l = 400.0
	m.gate_r = 880.0

	# Reset tracking state
	m.forum_pergola_sprinted = 0
	m.forum_rails_grinded = 0

	# Poles for leash wrapping: windsock masts and pergola pylon corners
	for p: Vector2 in WINDSOCK_POSTS:
		m.poles.append(p)
	m.deco_pole_count = m.poles.size()

	# Wrap points for pergola pylons
	for r: Rect2 in [PYLON_NW, PYLON_NE, PYLON_SW, PYLON_SE]:
		m.poles.append(Vector2(r.position.x + 8.0, r.get_center().y))
		m.poles.append(Vector2(r.end.x - 8.0, r.get_center().y))

	m.benches = Array([
		Vector2(420.0, -750.0),
		Vector2(820.0, -2050.0),
		Vector2(420.0, -3450.0),
	], TYPE_VECTOR2, &"", null)

	m.bins = Array([
		Vector2(410.0, -650.0),
		Vector2(840.0, -1950.0),
		Vector2(410.0, -2950.0),
		Vector2(840.0, -4150.0),
	], TYPE_VECTOR2, &"", null)

	var hyd_list: Array[Vector2] = [
		Vector2(WALL_L + 25.0, -500.0),
		Vector2(WALL_R - 25.0, -1250.0),
		Vector2(WALL_L + 25.0, -2300.0),
		Vector2(WALL_R - 25.0, -3500.0),
		Vector2(WALL_L + 25.0, -4200.0),
	]

	var keb_list: Array[Vector2] = [
		Vector2(620.0, -1100.0),
		Vector2(660.0, -2700.0),
		Vector2(580.0, -3700.0),
	]

	m.prize_pos = PRIZE
	m.prize_text = PRIZE_TEXT

	m.skater = ForumSkater.new()
	return [hyd_list, keb_list]


static func solids(_m: Node2D) -> Array[Rect2]:
	return [PYLON_NW, PYLON_NE, PYLON_SW, PYLON_SE, SKATE_BANK_1, SKATE_BANK_2]


static func wrap_rects() -> Array[Rect2]:
	return solids(null)


static func surface(_m: Node2D, p: Vector2) -> int:
	# East side bathing pool / marina sea water
	if p.x > SEAWALL_EDGE_X and p.y < -450.0 and p.y > -4450.0:
		return Surfaces.S.WATER
	return Surfaces.S.PAVEMENT


static func tick(m: Node2D, delta: float) -> void:
	if m.skater == null:
		return

	var res: Dictionary = m.skater.tick(delta, m.dog.global_position, m.dog.velocity, m.human.global_position)

	if res["telegraph"]:
		m.float_text(m.skater.pos + Vector2(0.0, -36.0), "Watch the board!", Color(0.96, 0.94, 0.88), m.POP_SAY)

	if res["bump_hazard"]:
		m.human.patience = maxf(0.0, m.human.patience - 8.0)
		m.human.temper_t = 1.2
		m.human.say("Ugh, watch out!", 1.2)

	if res["boop"]:
		m.award_points(2, "board boop! +2")

	if res["snack_snatched"]:
		m.award_points(2, "energy bar snack! +2")

	if res["dodge_save"]:
		m.award_points(2, "forum dodge! +2")
		m.saves_done += 1

	# Solar pergola sprint detector (under canopy between y = -1900.0 and y = -1300.0)
	var dp: Vector2 = m.dog.global_position
	if dp.y < -1350.0 and dp.y > -1850.0 and dp.x > WALL_L + 40.0 and dp.x < WALL_R - 40.0:
		if m.dog.velocity.length() > 200.0:
			if not m.has_meta("forum_canopy_in"):
				m.set_meta("forum_canopy_in", true)
				m.forum_pergola_sprinted += 1
				m.award_points(2, "solar sprint! +2")
	else:
		if m.has_meta("forum_canopy_in"):
			m.remove_meta("forum_canopy_in")

	# Skate rail grinding detector
	for sb: Rect2 in [SKATE_BANK_1, SKATE_BANK_2]:
		if absf(dp.y - sb.get_center().y) < sb.size.y * 0.5 + 10.0:
			if absf(dp.x - sb.position.x) < 14.0 or absf(dp.x - sb.end.x) < 14.0:
				if m.dog.velocity.length() > 180.0:
					if not m.has_meta("forum_rail_grind"):
						m.set_meta("forum_rail_grind", true)
						m.forum_rails_grinded += 2
						m.award_points(2, "skate rail grind! +2")
					return
	if m.has_meta("forum_rail_grind"):
		m.remove_meta("forum_rail_grind")


static func on_bark(m: Node2D, _pos: Vector2 = Vector2.ZERO) -> bool:
	if m.skater != null and m.skater.on_bark(m.dog.global_position):
		m.float_text(m.skater.pos + Vector2(0.0, -36.0), "Yeah! Kickflip!", Color(0.96, 0.94, 0.88), m.POP_SAY)
		m.award_points(2, "skate cheer! +2")
		return true
	return false


# --- drawing -----------------------------------------------------------------

static func draw_edge_layer(m: Node2D, wc: Object, vt: float, vb: float) -> void:
	var b := ShapeBatch.new()
	var sh := Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.28)

	# 1. Mediterranean sea water along eastern edge
	if SEAWALL_EDGE_X < 1280.0:
		var sea_rect := Rect2(SEAWALL_EDGE_X + 16.0, vt - 40.0, 1280.0 - SEAWALL_EDGE_X - 16.0, (vb - vt) + 80.0)
		b.rect(sea_rect, SEA_BLUE_DEEP)

		# Stepped shallow wave margin
		var margin_rect := Rect2(SEAWALL_EDGE_X + 16.0, vt - 40.0, 36.0, (vb - vt) + 80.0)
		b.rect(margin_rect, SEA_BLUE_SHALLOW)

		# Coastal waves crests
		var wave_y := floorf(vt / 90.0) * 90.0
		while wave_y < vb + 90.0:
			b.rect(Rect2(SEAWALL_EDGE_X + 20.0, wave_y, 44.0, 5.0), SEA_FOAM)
			wave_y += 90.0

		# Sea wall stone coping
		b.rect(Rect2(SEAWALL_EDGE_X, vt - 40.0, 16.0, (vb - vt) + 80.0), SEA_WALL_STONE.darkened(0.2))
		b.rect(Rect2(SEAWALL_EDGE_X + 2.0, vt - 40.0, 12.0, (vb - vt) + 80.0), SEA_WALL_STONE)

	# 2. Large concrete flagstone pavement joints
	var py := floorf(vt / 140.0) * 140.0
	while py < vb + 140.0:
		b.rect(Rect2(WALL_L, py, WALL_R - WALL_L, 2.0), CONCRETE_JOINT)
		py += 140.0

	var px := WALL_L + 140.0
	while px < WALL_R - 20.0:
		b.rect(Rect2(px, vt - 40.0, 2.0, (vb - vt) + 80.0), CONCRETE_JOINT)
		px += 140.0

	# 3. Solar pergola diagonal ground shadow
	var shadow_top := -1980.0
	var shadow_bot := -1260.0
	if shadow_bot > vt - 80.0 and shadow_top < vb + 80.0:
		var sy := maxf(shadow_top, vt - 40.0)
		var sh_h := minf(shadow_bot, vb + 40.0) - sy
		if sh_h > 0.0:
			# Diagonal striped shadow pattern from solar panel louvers
			var sl_y := shadow_top
			while sl_y < shadow_bot:
				if sl_y >= vt - 60.0 and sl_y <= vb + 60.0:
					b.rect(Rect2(WALL_L + 20.0, sl_y, (WALL_R - WALL_L) - 40.0, 28.0), SOLAR_SHADOW)
				sl_y += 56.0

	b.flush(wc)


static func draw_live(m: Node2D, wc: Object, vt: float, vb: float) -> void:
	var b := ShapeBatch.new()
	var sh := Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.28)

	# 1. Concrete skate banks & grindable coping rails
	for sb: Rect2 in [SKATE_BANK_1, SKATE_BANK_2]:
		if sb.end.y > vt - 80.0 and sb.position.y < vb + 80.0:
			b.rect(Rect2(sb.position + Vector2(4, 6), sb.size), sh)
			b.rect(sb, SKATE_CONCRETE.darkened(0.2))
			b.rect(sb.grow(-3.0), SKATE_CONCRETE)
			# Steel coping edge rails
			b.rect(Rect2(sb.position.x, sb.position.y, 4.0, sb.size.y), SKATE_RAIL_STEEL)
			b.rect(Rect2(sb.end.x - 4.0, sb.position.y, 4.0, sb.size.y), SKATE_RAIL_STEEL)

	# 2. Solar pergola pylon bases
	for py_rect: Rect2 in [PYLON_NW, PYLON_NE, PYLON_SW, PYLON_SE]:
		if py_rect.end.y > vt - 80.0 and py_rect.position.y < vb + 80.0:
			b.rect(Rect2(py_rect.position + Vector2(6, 8), py_rect.size), sh)
			b.rect(py_rect, SOLAR_STEEL_DARK)
			b.rect(py_rect.grow(-4.0), SOLAR_STEEL_LIT)
			# Angled brace lines
			b.rect(Rect2(py_rect.get_center().x - 2.0, py_rect.position.y + 4.0, 4.0, py_rect.size.y - 8.0), SOLAR_STEEL_DARK)

	# 3. Windsock masts & cones
	for wp: Vector2 in WINDSOCK_POSTS:
		if wp.y > vt - 80.0 and wp.y < vb + 80.0:
			b.circle(wp + Vector2(2, 4), 6.0, sh)
			b.circle(wp, 4.5, SOLAR_STEEL_DARK)
			b.circle(wp, 2.5, SKATE_RAIL_STEEL)
			# Striped cone fluttering east in sea breeze
			b.rect(Rect2(wp.x + 4.0, wp.y - 4.0, 10.0, 8.0), WINDSOCK_RED)
			b.rect(Rect2(wp.x + 14.0, wp.y - 3.0, 8.0, 6.0), WINDSOCK_WHITE)
			b.rect(Rect2(wp.x + 22.0, wp.y - 2.0, 8.0, 4.0), WINDSOCK_RED)

	# 4. Signature live event: El Skater
	if m.skater != null:
		m.skater.draw(m, b, vt, vb)

	b.flush(wc)


static func draw_overhead(m: Node2D, wc: Object) -> void:
	# Massive Pèrgola Fotovoltaica steel superstructure & photovoltaic panels
	var b := ShapeBatch.new()
	var cam_y: float = m.cam.position.y if m.cam != null else -1600.0

	# Only draw when camera is near the pergola (-2300 to -900)
	if cam_y < -850.0 and cam_y > -2350.0:
		var pergola_rect := Rect2(WALL_L - 20.0, -1880.0, (WALL_R - WALL_L) + 40.0, 520.0)

		# Outer steel truss frame
		b.rect(pergola_rect, Color(SOLAR_STEEL_DARK.r, SOLAR_STEEL_DARK.g, SOLAR_STEEL_DARK.b, 0.88))
		b.rect(pergola_rect.grow(-8.0), Color(SOLAR_STEEL_LIT.r, SOLAR_STEEL_LIT.g, SOLAR_STEEL_LIT.b, 0.85))

		# Photovoltaic solar cell array grids
		var grid_y := pergola_rect.position.y + 14.0
		while grid_y < pergola_rect.end.y - 20.0:
			var grid_x := pergola_rect.position.x + 14.0
			while grid_x < pergola_rect.end.x - 20.0:
				b.rect(Rect2(grid_x, grid_y, 44.0, 36.0), SOLAR_PANEL_BLUE)
				b.rect(Rect2(grid_x + 2.0, grid_y + 2.0, 40.0, 32.0), SOLAR_CELL_CYAN)
				grid_x += 48.0
			grid_y += 42.0

	b.flush(wc)
