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
# - Banys del Fòrum: the unique open-air seaside bathing park and terraces at the
#   finish of the walk.
# - Signature live event: El Skater de l'Esplanada (ForumSkater) cruising across
#   the open pavement practicing an ollie.

const ShapeBatch := preload("res://systems/shape_batch.gd")
# a bump costs your human this much of their patience (0..1, entities/human.gd)
const BUMP_PATIENCE := 0.08
# the overhead layer redraws this walk at 30 fps: the pergola culls to the
# camera and thins over the pair
const OVERHEAD_FOLLOWS_CAMERA := true
const Surfaces := preload("res://world/surfaces.gd")
const ForumSkater := preload("res://systems/forum_skater.gd")

const SHADOW := Color(0.04, 0.05, 0.07, 0.24)

# --- colors ------------------------------------------------------------------
const CONCRETE_LIGHT := Color(0.78, 0.79, 0.80)
const CONCRETE_MID := Color(0.71, 0.72, 0.73)
const CONCRETE_DARK := Color(0.58, 0.60, 0.62)
const CONCRETE_JOINT := Color(0.46, 0.48, 0.50)
const SKATE_ASPHALT := Color(0.30, 0.32, 0.34)
const GRATE_STEEL := Color(0.42, 0.44, 0.47)
const SEAWALL_COPING := Color(0.82, 0.83, 0.82)
const SEAWALL_DARK := Color(0.52, 0.54, 0.55)

# Mediterranean Sea & Marina
const SEA_DEEP := Color(0.08, 0.30, 0.54)
const SEA_MID := Color(0.14, 0.42, 0.66)
const SEA_SHALLOW := Color(0.22, 0.58, 0.74)
const SEA_FOAM := Color(0.92, 0.97, 1.0, 0.80)
const TETRAPOD_STONE := Color(0.62, 0.64, 0.65)
const TETRAPOD_DARK := Color(0.44, 0.46, 0.48)
const PONTOON_WOOD := Color(0.68, 0.55, 0.40)
const BOAT_WHITE := Color(0.94, 0.95, 0.96)
const BOAT_NAVY := Color(0.12, 0.20, 0.36)
const BOAT_TEAL := Color(0.16, 0.50, 0.55)

# Architecture: Museu Blau & CCIB
const MUSEU_BLUE := Color(0.14, 0.22, 0.38)
const MUSEU_BLUE_DARK := Color(0.09, 0.15, 0.26)
const GLASS_FISSURE := Color(0.70, 0.88, 0.96, 0.90)
const GLASS_GLINT := Color(1.0, 1.0, 1.0, 0.95)
const CCIB_FACADE := Color(0.44, 0.47, 0.50)
const CCIB_GLASS := Color(0.22, 0.32, 0.42)

# Solar Pergola colors
const SOLAR_STEEL_DARK := Color(0.20, 0.22, 0.25)
const SOLAR_STEEL_LIT := Color(0.36, 0.40, 0.45)
const SOLAR_STEEL_YELLOW := Color(0.88, 0.76, 0.20)
const SOLAR_PANEL_NAVY := Color(0.08, 0.16, 0.30, 0.92)
const SOLAR_CELL_CYAN := Color(0.18, 0.42, 0.65, 0.88)
const SOLAR_CELL_GRID := Color(0.30, 0.60, 0.85, 0.50)
const SOLAR_SHADOW := Color(0.05, 0.07, 0.10, 0.35)

# Skate Furniture colors
const SKATE_CONCRETE := Color(0.70, 0.72, 0.70)
const SKATE_RAMP_SLOPE := Color(0.62, 0.64, 0.62)
const SKATE_RAIL_STEEL := Color(0.88, 0.90, 0.94)
const SKATE_WAX := Color(0.96, 0.94, 0.80, 0.70)
const WINDSOCK_RED := Color(0.88, 0.22, 0.18)
const WINDSOCK_WHITE := Color(0.96, 0.96, 0.94)
const TEAK_PLANK := Color(0.58, 0.42, 0.28)
const TEAK_DARK := Color(0.42, 0.30, 0.20)

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
const PRIZE_TEXT := "snatch the solar trophy off the marina podium"

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
	# East side bathing pool / marina sea water along walk
	if p.x > SEAWALL_EDGE_X and p.y < -450.0 and p.y > -4450.0:
		return Surfaces.S.WATER
	# Banys del Fòrum sea bathing basin in off-leash area
	if p.y < -5000.0 and p.x > 840.0:
		return Surfaces.S.WATER
	return Surfaces.S.PAVEMENT


static func tick(m: Node2D, delta: float) -> void:
	if m.skater == null:
		return

	var res: Dictionary = m.skater.tick(delta, m.dog.global_position, m.dog.velocity, m.human.global_position)

	if res["telegraph"]:
		m.float_text(m.skater.pos + Vector2(0.0, -36.0), "Watch the board!", Color(0.96, 0.94, 0.88), m.POP_SAY)

	if res["bump_hazard"]:
		m.human.patience = maxf(0.0, m.human.patience - BUMP_PATIENCE)
		m.human.say_line("Ugh, watch out!")

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

static func draw_edge_layer(m: Node2D, c: Object, vt: float, vb: float) -> void:
	var b: ShapeBatch = c as ShapeBatch if c is ShapeBatch else ShapeBatch.new(c)
	var sh := Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.26)
	var t_sec := AnimClock.msec() / 1000.0

	# =========================================================================
	# EAST SIDE: Open Mediterranean Sea, Waves, Tetrapods, and Port Fòrum Marina
	# =========================================================================
	if SEAWALL_EDGE_X < 1280.0:
		var sea_top := vt - 40.0
		var sea_h := (vb - vt) + 80.0

		# Deep Mediterranean sea water
		b.rect(Rect2(SEAWALL_EDGE_X + 16.0, sea_top, 1280.0 - SEAWALL_EDGE_X - 16.0, sea_h), SEA_DEEP)

		# Coastal shallows margin
		b.rect(Rect2(SEAWALL_EDGE_X + 16.0, sea_top, 60.0, sea_h), SEA_SHALLOW)
		b.rect(Rect2(SEAWALL_EDGE_X + 76.0, sea_top, 40.0, sea_h), SEA_MID)

		# Animated rhythmic coastal waves
		var wave_step := 110.0
		var wave_start := floorf((vt - 40.0) / wave_step) * wave_step
		var wy := wave_start
		while wy < vb + 60.0:
			var wave_phase := sin(t_sec * 2.2 + wy * 0.02)
			var wave_x := SEAWALL_EDGE_X + 24.0 + wave_phase * 12.0
			var wave_w := 48.0 + cos(t_sec * 1.8 + wy * 0.03) * 16.0
			b.rect(Rect2(wave_x, wy, wave_w, 4.0), SEA_FOAM)
			# Outer wave crest
			var wave2_x := SEAWALL_EDGE_X + 90.0 + cos(t_sec * 1.6 + wy * 0.02) * 18.0
			b.rect(Rect2(wave2_x, wy + 45.0, 38.0, 3.0), Color(SEA_FOAM.r, SEA_FOAM.g, SEA_FOAM.b, 0.55))
			wy += wave_step

		# Breakwater armoring: interlocking concrete tetrapods along the waterline
		var tetra_step := 52.0
		var ty := floorf((vt - 40.0) / tetra_step) * tetra_step
		while ty < vb + 40.0:
			var tx := SEAWALL_EDGE_X + 10.0
			b.circle(Vector2(tx + 4.0, ty + 4.0), 9.0, sh)
			b.circle(Vector2(tx, ty), 8.5, TETRAPOD_DARK)
			b.circle(Vector2(tx - 2.0, ty - 2.0), 6.5, TETRAPOD_STONE)
			# Tetrapod arms
			b.rect(Rect2(tx - 9.0, ty - 3.0, 18.0, 6.0), TETRAPOD_DARK)
			b.rect(Rect2(tx - 8.0, ty - 2.0, 16.0, 4.0), TETRAPOD_STONE)
			b.rect(Rect2(tx - 3.0, ty - 9.0, 6.0, 18.0), TETRAPOD_DARK)
			b.rect(Rect2(tx - 2.0, ty - 8.0, 4.0, 16.0), TETRAPOD_STONE)
			ty += tetra_step

		# Port Fòrum Marina: floating finger docks and moored recreational boats
		for dy: float in [-1500.0, -2100.0, -2700.0, -3300.0]:
			if dy > vt - 120.0 and dy < vb + 120.0:
				# Wooden finger dock
				b.rect(Rect2(1000.0 + 3.0, dy + 5.0, 220.0, 24.0), sh)
				b.rect(Rect2(1000.0, dy, 220.0, 22.0), PONTOON_WOOD.darkened(0.2))
				b.rect(Rect2(1002.0, dy + 2.0, 216.0, 18.0), PONTOON_WOOD)
				# Dock planks
				var px := 1010.0
				while px < 1210.0:
					b.rect(Rect2(px, dy + 2.0, 1.5, 18.0), PONTOON_WOOD.darkened(0.3))
					px += 14.0

				# Moored speedboats
				for boat_side: float in [-1.0, 1.0]:
					var by: float = dy + boat_side * 36.0
					var bx := 1040.0
					b.rect(Rect2(bx + 4.0, by + 4.0, 110.0, 32.0), sh)
					# Hull
					b.rect(Rect2(bx, by, 110.0, 30.0), BOAT_WHITE.darkened(0.15))
					b.rect(Rect2(bx + 2.0, by + 2.0, 106.0, 26.0), BOAT_WHITE)
					# Cockpit / cabin
					var deck_col := BOAT_NAVY if boat_side < 0.0 else BOAT_TEAL
					b.rect(Rect2(bx + 20.0, by + 6.0, 60.0, 18.0), deck_col)
					b.rect(Rect2(bx + 26.0, by + 8.0, 40.0, 14.0), Color(0.85, 0.92, 0.96, 0.9))
					# Mooring line to dock
					b.line(Vector2(bx + 15.0, by + (15.0 if boat_side < 0.0 else 0.0)), Vector2(bx + 15.0, dy + 11.0), Color(0.3, 0.3, 0.3), 1.5)

	# =========================================================================
	# WEST SIDE: Edifici Fòrum (Museu Blau), CCIB Halls, and Monumental Ramps
	# =========================================================================
	var west_w := WALL_L - (-100.0)
	var west_rect := Rect2(-100.0, vt - 40.0, west_w, (vb - vt) + 80.0)
	b.rect(west_rect, CONCRETE_DARK)

	# Base plaza terrace joints
	var wjy := floorf((vt - 40.0) / 90.0) * 90.0
	while wjy < vb + 60.0:
		b.rect(Rect2(-100.0, wjy, west_w, 2.0), CONCRETE_JOINT)
		wjy += 90.0

	# 1. Museu Blau / Edifici Fòrum (y = -450 to -1750)
	var mb_top := -1750.0
	var mb_bot := -450.0
	if mb_bot > vt - 80.0 and mb_top < vb + 80.0:
		var mb_w := 320.0
		var mb_rect := Rect2(-60.0, mb_top, mb_w, mb_bot - mb_top)

		# Building mass shadow
		b.rect(Rect2(mb_rect.position + Vector2(10.0, 14.0), mb_rect.size), sh)
		# Deep indigo-blue textured concrete mass
		b.rect(mb_rect, MUSEU_BLUE_DARK)
		b.rect(mb_rect.grow(-6.0), MUSEU_BLUE)

		# Mirrored glass fissure cuts running through the blue facade
		var fiss_y := mb_top + 40.0
		while fiss_y < mb_bot - 40.0:
			var fiss_rect := Rect2(mb_rect.end.x - 38.0, fiss_y, 24.0, 70.0)
			b.rect(fiss_rect, GLASS_FISSURE)
			# Bright glass reflection glint
			b.line(fiss_rect.position + Vector2(2.0, 4.0), fiss_rect.position + Vector2(20.0, 66.0), GLASS_GLINT, 2.0)
			fiss_y += 110.0

		# Cantilevered triangular undercroft shadow
		b.rect(Rect2(mb_rect.position.x, mb_bot - 90.0, mb_w, 90.0), MUSEU_BLUE_DARK)

	# 2. CCIB Convention Halls (y = -1900 to -3700)
	var ccib_top := -3700.0
	var ccib_bot := -1900.0
	if ccib_bot > vt - 80.0 and ccib_top < vb + 80.0:
		var ccib_w := 340.0
		var ccib_rect := Rect2(-60.0, ccib_top, ccib_w, ccib_bot - ccib_top)

		b.rect(Rect2(ccib_rect.position + Vector2(10.0, 12.0), ccib_rect.size), sh)
		# Zinc & stainless cladding
		b.rect(ccib_rect, CCIB_FACADE.darkened(0.2))
		b.rect(ccib_rect.grow(-4.0), CCIB_FACADE)

		# Tinted glass curtain wall window bays
		var bay_y := ccib_top + 30.0
		while bay_y < ccib_bot - 30.0:
			b.rect(Rect2(ccib_rect.end.x - 30.0, bay_y, 22.0, 55.0), CCIB_GLASS)
			b.rect(Rect2(ccib_rect.end.x - 28.0, bay_y + 2.0, 18.0, 51.0), Color(0.28, 0.42, 0.54, 0.9))
			bay_y += 85.0

	# 3. Terraced Amphitheater Concrete Seating (y = -3850 to -4900)
	var amphi_top := -4900.0
	var amphi_bot := -3850.0
	if amphi_bot > vt - 80.0 and amphi_top < vb + 80.0:
		var ay := amphi_top
		while ay < amphi_bot:
			if ay >= vt - 60.0 and ay <= vb + 60.0:
				b.rect(Rect2(120.0, ay, 200.0, 36.0), CONCRETE_MID)
				b.rect(Rect2(120.0, ay + 32.0, 200.0, 4.0), CONCRETE_DARK)
				# Safety handrails
				b.line(Vector2(310.0, ay), Vector2(310.0, ay + 36.0), SKATE_RAIL_STEEL, 1.5)
			ay += 40.0

	if c is not ShapeBatch:
		b.flush(c)


static func draw_cross_section(m: Node2D, wc: ShapeBatch, _top: float, bottom: float, ctop: float, vt: float, vb: float) -> void:
	var sh := Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.24)

	# 1. Main Esplanade Ground Pavement Field
	var walk_w := WALL_R - WALL_L
	var walk_rect := Rect2(WALL_L, ctop, walk_w, bottom - ctop)
	wc.rect(walk_rect, CONCRETE_MID)

	# Alternating slab tone stripes (large precast pavers)
	var slab_step := 120.0
	var slab_y := floorf(maxf(ctop, vt - 40.0) / slab_step) * slab_step
	while slab_y < minf(bottom, vb + 40.0):
		if int(absf(slab_y / slab_step)) % 2 == 0:
			wc.rect(Rect2(WALL_L, slab_y, walk_w, slab_step), CONCRETE_LIGHT)
		slab_y += slab_step

	# Longitudinal expansion joint lines
	for px: float in [430.0, 500.0, 570.0, 640.0, 710.0, 780.0, 850.0]:
		wc.rect(Rect2(px, maxf(ctop, vt - 40.0), 2.0, minf(bottom, vb + 40.0) - maxf(ctop, vt - 40.0)), CONCRETE_JOINT)

	# Transverse expansion joint lines
	var jy := floorf(maxf(ctop, vt - 40.0) / slab_step) * slab_step
	while jy < minf(bottom, vb + 40.0):
		wc.rect(Rect2(WALL_L, jy, walk_w, 2.0), CONCRETE_JOINT)
		jy += slab_step

	# 2. Smooth Charcoal Asphalt Skate Speed Strip (x = 510 to 610)
	var skate_x := 510.0
	var skate_w := 100.0
	wc.rect(Rect2(skate_x, maxf(ctop, vt - 40.0), skate_w, minf(bottom, vb + 40.0) - maxf(ctop, vt - 40.0)), SKATE_ASPHALT)
	# Dashed center speed run line
	var dly := floorf(maxf(ctop, vt - 40.0) / 40.0) * 40.0
	while dly < minf(bottom, vb + 40.0):
		wc.rect(Rect2(skate_x + skate_w * 0.5 - 1.5, dly, 3.0, 22.0), Color(0.95, 0.95, 0.95, 0.85))
		dly += 40.0

	# 3. Linear Stainless Steel Slot Drains (x = 410 and x = 840)
	for gx: float in [410.0, 840.0]:
		wc.rect(Rect2(gx - 4.0, maxf(ctop, vt - 40.0), 8.0, minf(bottom, vb + 40.0) - maxf(ctop, vt - 40.0)), GRATE_STEEL)
		wc.rect(Rect2(gx - 1.5, maxf(ctop, vt - 40.0), 3.0, minf(bottom, vb + 40.0) - maxf(ctop, vt - 40.0)), Color(0.18, 0.18, 0.20))

	# 4. Seawall Granite Promenade Coping (x = 868 to 884)
	var sea_len := minf(bottom, vb + 40.0) - maxf(ctop, vt - 40.0)
	wc.rect(Rect2(SEAWALL_EDGE_X - 2.0, maxf(ctop, vt - 40.0), 16.0, sea_len), SEAWALL_DARK)
	wc.rect(Rect2(SEAWALL_EDGE_X, maxf(ctop, vt - 40.0), 12.0, sea_len), SEAWALL_COPING)

	# 5. Solar Pergola Diagonal Ground Shadow (y = -1980 to -1260)
	var shadow_top := -1980.0
	var shadow_bot := -1260.0
	if shadow_bot > vt - 80.0 and shadow_top < vb + 80.0:
		var sl_y := shadow_top
		while sl_y < shadow_bot:
			if sl_y >= vt - 60.0 and sl_y <= vb + 60.0:
				wc.rect(Rect2(WALL_L + 15.0, sl_y, (WALL_R - WALL_L) - 30.0, 32.0), SOLAR_SHADOW)
				# Diagonal truss beam shadows
				wc.line(Vector2(WALL_L + 20.0, sl_y), Vector2(WALL_R - 20.0, sl_y + 40.0), SOLAR_SHADOW.darkened(0.2), 6.0)
			sl_y += 56.0

	# 6. Concrete Skate Banks with Coping Rails
	for sb: Rect2 in [SKATE_BANK_1, SKATE_BANK_2]:
		if sb.end.y > vt - 80.0 and sb.position.y < vb + 80.0:
			# Cast drop shadow
			wc.rect(Rect2(sb.position + Shade.light * 8.0, sb.size), sh)
			# Concrete transition body
			wc.rect(sb, SKATE_CONCRETE.darkened(0.25))
			wc.rect(sb.grow(-3.0), SKATE_CONCRETE)
			wc.rect(Rect2(sb.position.x + 8.0, sb.position.y + 4.0, sb.size.x - 16.0, sb.size.y - 8.0), SKATE_RAMP_SLOPE)
			# Steel coping edge pipes
			wc.rect(Rect2(sb.position.x, sb.position.y, 5.0, sb.size.y), SKATE_RAIL_STEEL)
			wc.rect(Rect2(sb.end.x - 5.0, sb.position.y, 5.0, sb.size.y), SKATE_RAIL_STEEL)
			# Grind wax sheen along the copings
			wc.rect(Rect2(sb.position.x + 1.0, sb.position.y + 10.0, 3.0, sb.size.y - 20.0), SKATE_WAX)
			wc.rect(Rect2(sb.end.x - 4.0, sb.position.y + 10.0, 3.0, sb.size.y - 20.0), SKATE_WAX)
			# Urban skate tags / stickers
			wc.rect(Rect2(sb.position.x + 14.0, sb.position.y + 20.0, 16.0, 8.0), Color(0.88, 0.20, 0.50))
			wc.rect(Rect2(sb.position.x + 18.0, sb.position.y + 70.0, 12.0, 12.0), Color(0.15, 0.75, 0.85))

	# 7. Pergola Pylon Footing Bases
	for py_rect: Rect2 in [PYLON_NW, PYLON_NE, PYLON_SW, PYLON_SE]:
		if py_rect.end.y > vt - 80.0 and py_rect.position.y < vb + 80.0:
			wc.rect(Rect2(py_rect.position + Shade.light * 10.0, py_rect.size), sh)
			# Heavy chamfered concrete pad
			wc.rect(py_rect.grow(4.0), CONCRETE_DARK)
			wc.rect(py_rect, SOLAR_STEEL_DARK)
			wc.rect(py_rect.grow(-4.0), SOLAR_STEEL_LIT)
			# Center stiffener plate
			wc.rect(Rect2(py_rect.get_center().x - 3.0, py_rect.position.y + 4.0, 6.0, py_rect.size.y - 8.0), SOLAR_STEEL_DARK)
			# Industrial yellow hazard border striping
			wc.rect(Rect2(py_rect.position.x + 4.0, py_rect.end.y - 8.0, py_rect.size.x - 8.0, 4.0), SOLAR_STEEL_YELLOW)

	# 8. Marina Plaza Viewing Platform & Solar Cell Trophy (at PRIZE = 580, -4500)
	if -4500.0 > vt - 120.0 and -4500.0 < vb + 120.0:
		var pp := PRIZE
		# Circular teak hardwood observation deck
		wc.circle(pp + Shade.light * 8.0, 46.0, sh)
		wc.circle(pp, 44.0, TEAK_DARK)
		wc.circle(pp, 42.0, TEAK_PLANK)
		# Planks across viewing deck
		for tky: float in [-30.0, -15.0, 0.0, 15.0, 30.0]:
			wc.rect(Rect2(pp.x - 36.0, pp.y + tky, 72.0, 1.5), TEAK_DARK)
		# Compass rose star inlay
		wc.line(pp + Vector2(-22.0, 0.0), pp + Vector2(22.0, 0.0), Color(0.85, 0.72, 0.35), 2.0)
		wc.line(pp + Vector2(0.0, -22.0), pp + Vector2(0.0, 22.0), Color(0.85, 0.72, 0.35), 2.0)
		# Marine cable railing stanchions around rim
		for a_i in range(8):
			var a := float(a_i) * (TAU / 8.0)
			var sp := pp + Vector2(cos(a), sin(a)) * 40.0
			wc.circle(sp, 2.5, SKATE_RAIL_STEEL)

		# Trophy pedestal
		wc.circle(pp + Shade.light * 4.0, 14.0, sh)
		wc.circle(pp, 12.0, CONCRETE_DARK)
		wc.circle(pp, 9.0, SKATE_RAIL_STEEL)
		# Solar Cell Trophy (the snatchable walk prize)
		wc.circle(pp, 6.0, SOLAR_PANEL_NAVY)
		wc.circle(pp, 4.0, SOLAR_CELL_CYAN)
		wc.rect(Rect2(pp.x - 2.0, pp.y - 2.0, 4.0, 4.0), Color(1.0, 1.0, 1.0, 0.9))


static func draw_overhead(m: Node2D, c: Object) -> void:
	# Massive Pèrgola Fotovoltaica steel space frame & 4,000 m² photovoltaic array
	var b: ShapeBatch = c as ShapeBatch if c is ShapeBatch else ShapeBatch.new(c)

	var pergola_rect := Rect2(WALL_L - 30.0, -1940.0, (WALL_R - WALL_L) + 60.0, 680.0)
	# off screen: nothing to draw (the camera sees about 400 px either way)
	var cam_y: float = m.cam.position.y if m.cam != null else pergola_rect.get_center().y
	if cam_y < pergola_rect.position.y - 460.0 or cam_y > pergola_rect.end.y + 460.0:
		if c is not ShapeBatch:
			b.flush(c)
		return
	# the canopy is over the pair: thin it so the dog and your human show
	# through, as every overhead piece does when someone walks under it
	var f := 1.0
	for who: Node2D in [m.dog, m.human]:
		if who != null and pergola_rect.grow(30.0).has_point(who.global_position):
			f = 0.3

	# 1. Structural steel perimeter space truss
	b.rect(pergola_rect, Color(SOLAR_STEEL_DARK.r, SOLAR_STEEL_DARK.g, SOLAR_STEEL_DARK.b, 0.94 * f))
	b.rect(pergola_rect.grow(-8.0), Color(SOLAR_STEEL_LIT.r, SOLAR_STEEL_LIT.g, SOLAR_STEEL_LIT.b, 0.90 * f))

	# 2. Heavy industrial yellow support diagonal struts
	b.line(Vector2(pergola_rect.position.x + 20.0, pergola_rect.position.y + 20.0),
		Vector2(pergola_rect.end.x - 20.0, pergola_rect.end.y - 20.0), _faded(SOLAR_STEEL_YELLOW, f), 5.0)
	b.line(Vector2(pergola_rect.position.x + 20.0, pergola_rect.end.y - 20.0),
		Vector2(pergola_rect.end.x - 20.0, pergola_rect.position.y + 20.0), _faded(SOLAR_STEEL_YELLOW, f), 5.0)

	# 3. Photovoltaic solar array matrix modules
	var grid_y := pergola_rect.position.y + 18.0
	while grid_y < pergola_rect.end.y - 24.0:
		var grid_x := pergola_rect.position.x + 18.0
		while grid_x < pergola_rect.end.x - 24.0:
			var panel_rect := Rect2(grid_x, grid_y, 42.0, 34.0)
			b.rect(panel_rect, _faded(SOLAR_PANEL_NAVY, f))
			b.rect(panel_rect.grow(-2.0), _faded(SOLAR_CELL_CYAN, f))
			# Silver busbar solar gridlines
			b.line(Vector2(grid_x + 14.0, grid_y + 2.0), Vector2(grid_x + 14.0, grid_y + 32.0), _faded(SOLAR_CELL_GRID, f), 1.0)
			b.line(Vector2(grid_x + 28.0, grid_y + 2.0), Vector2(grid_x + 28.0, grid_y + 32.0), _faded(SOLAR_CELL_GRID, f), 1.0)
			grid_x += 48.0
		grid_y += 42.0

	if c is not ShapeBatch:
		b.flush(c)


static func _faded(col: Color, f: float) -> Color:
	return Color(col.r, col.g, col.b, col.a * f)


static func draw_freedom(m: Node2D, ci: Object) -> void:
	# Banys del Fòrum: seaside bathing park, sunbathing terraces, and open sea
	var b := ShapeBatch.new()
	var r: Rect2 = m._freedom_rect()
	var sh := Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.24)

	# 1. Base seaside esplanade concrete ground
	b.rect(r, CONCRETE_MID)

	# Precast concrete paving slabs with joints
	var slab_w := 90.0
	var sx := r.position.x
	while sx < r.end.x:
		b.line(Vector2(sx, r.position.y), Vector2(sx, r.end.y), CONCRETE_JOINT, 2.0)
		sx += slab_w

	var sy := r.position.y
	while sy < r.end.y:
		b.line(Vector2(r.position.x, sy), Vector2(r.end.x, sy), CONCRETE_JOINT, 2.0)
		sy += 70.0

	# 2. East side Sea Bathing Basin (Banys del Fòrum for x > 840)
	var sea_basin_x := 840.0
	var sea_rect := Rect2(sea_basin_x, r.position.y, r.end.x - sea_basin_x, r.size.y)
	b.rect(sea_rect, SEA_MID)
	b.rect(Rect2(sea_basin_x, r.position.y, 40.0, r.size.y), SEA_SHALLOW)

	# Wave ripples in bathing basin
	var wy := r.position.y + 30.0
	while wy < r.end.y:
		b.rect(Rect2(sea_basin_x + 16.0, wy, 36.0, 3.0), SEA_FOAM)
		wy += 60.0

	# Stepped concrete swimming terraces leading down into water
	for terrace_i in range(3):
		var tx := sea_basin_x - float(terrace_i + 1) * 16.0
		b.rect(Rect2(tx, r.position.y, 14.0, r.size.y), CONCRETE_DARK)
		b.rect(Rect2(tx + 2.0, r.position.y, 10.0, r.size.y), CONCRETE_LIGHT)

	# Stainless steel swimming ladder handrails
	for ly: float in [r.position.y + 120.0, r.position.y + 320.0]:
		b.rect(Rect2(sea_basin_x - 14.0, ly, 22.0, 4.0), SKATE_RAIL_STEEL)
		b.circle(Vector2(sea_basin_x - 14.0, ly + 2.0), 3.0, SKATE_RAIL_STEEL)
		b.circle(Vector2(sea_basin_x + 8.0, ly + 2.0), 3.0, SKATE_RAIL_STEEL)

	# Concrete tetrapod breakwaters along the deep corner
	for tetra_y: float in [r.position.y + 40.0, r.position.y + 200.0, r.position.y + 440.0]:
		var tp := Vector2(sea_basin_x + 60.0, tetra_y)
		b.circle(tp + Shade.light * 4.0, 12.0, sh)
		b.circle(tp, 11.0, TETRAPOD_DARK)
		b.circle(tp, 8.0, TETRAPOD_STONE)

	# 3. Northwest Sunbathing Wooden Platform
	var deck_rect := Rect2(r.position.x + 40.0, r.position.y + 40.0, 180.0, 120.0)
	b.rect(Rect2(deck_rect.position + Shade.light * 6.0, deck_rect.size), sh)
	b.rect(deck_rect, TEAK_DARK)
	b.rect(deck_rect.grow(-3.0), TEAK_PLANK)
	for dpy in range(6):
		var py := deck_rect.position.y + 10.0 + float(dpy) * 18.0
		b.line(Vector2(deck_rect.position.x + 4.0, py), Vector2(deck_rect.end.x - 4.0, py), TEAK_DARK, 1.5)

	# Flush pre-sign geometry
	b.flush(ci)

	# Standard benches and authentic entrance title sign
	m._draw_freedom_benches(ci, r, Color(0.35, 0.38, 0.42))
	m._freedom_sign(ci, r, "BANYS DEL FÒRUM", "the seaside bathing park, off leash")


static func draw_column(m: Node2D, wc: ShapeBatch, p: Vector2) -> void:
	# Windsock mast: concrete foundation pad, stainless steel mounting flange,
	# slender marine mast, and fluttering red-and-white conical windsock.
	var sh := Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.26)
	var t_sec := AnimClock.msec() / 1000.0

	# 1. Concrete foundation footing
	wc.circle(p + Shade.light * 4.0, 10.0, sh)
	wc.circle(p, 9.0, CONCRETE_DARK)
	wc.circle(p, 7.5, CONCRETE_LIGHT)

	# 2. Steel flange baseplate with anchor bolts
	wc.circle(p, 5.5, SOLAR_STEEL_DARK)
	wc.circle(p, 3.5, SKATE_RAIL_STEEL)

	# 3. Tall mast shadow
	m.cast_shadow(wc, p, 3.5, 36.0)

	# 4. Animated nautical windsock cone fluttering eastward in sea breeze
	var flutter := sin(t_sec * 6.0 + p.y * 0.02) * 2.5
	var droop := cos(t_sec * 3.0 + p.y * 0.01) * 1.5
	var sock_x := p.x + 5.0
	var sock_y := p.y - 4.0 + droop

	# Segment 1 (Red throat)
	wc.rect(Rect2(sock_x, sock_y, 11.0, 9.0), WINDSOCK_RED)
	# Segment 2 (White center)
	wc.rect(Rect2(sock_x + 11.0, sock_y + 1.0 + flutter * 0.3, 9.0, 7.0), WINDSOCK_WHITE)
	# Segment 3 (Red tip)
	wc.rect(Rect2(sock_x + 20.0, sock_y + 2.0 + flutter * 0.7, 9.0, 5.0), WINDSOCK_RED)


static func draw_bollard(m: Node2D, wc: ShapeBatch, h: Dictionary) -> void:
	# Marine stainless steel bollard: cylindrical satin post, mooring line collar,
	# and progress ring while being marked.
	var p: Vector2 = h.pos
	var done: bool = bool(h.get("done", false))
	var prog: float = float(h.get("prog", 0.0))
	var sh := Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.26)

	# Drop shadow
	m.cast_shadow(wc, p, 8.0, 20.0)

	# Base mounting ring
	wc.circle(p + Vector2(0.5, 0.5), 9.0, Color(0.35, 0.38, 0.40))
	# Stainless steel cylindrical body
	var body_col := SKATE_RAIL_STEEL if not done else SKATE_RAIL_STEEL.darkened(0.18)
	wc.circle(p, 8.0, body_col.darkened(0.2))
	wc.circle(p, 7.0, body_col)
	# Beveled domed cap highlight
	wc.circle(p + Vector2(-1.5, -1.5), 4.5, body_col.lightened(0.25))

	# Wet mark or progress ring
	if done:
		wc.circle(p + Vector2(0.0, 6.0), 3.0, Color(0.20, 0.35, 0.25, 0.6))
	elif prog > 0.0:
		wc.draw_arc(p, 11.0, 0.0, prog * TAU, 16, Color(1.0, 0.85, 0.20), 2.5)


static func draw_bin(m: Node2D, wc: ShapeBatch, bn: Vector2) -> void:
	# Perforated stainless steel coastal recycling station with sorting hood
	var sh := Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.26)
	wc.circle(bn + Shade.light * 6.0, 13.0, sh)

	# Outer stainless steel perforated drum
	wc.circle(bn, 12.0, Color(0.40, 0.42, 0.45))
	wc.circle(bn, 10.5, SKATE_RAIL_STEEL)
	# Dark aperture mouth
	wc.circle(bn + Vector2(1.0, 1.0), 7.0, Color(0.16, 0.18, 0.20))
	# Yellow selective sorting ring for plastic/packaging
	wc.circle(bn + Vector2(1.0, 1.0), 4.5, Color(0.92, 0.78, 0.20))


static func draw_fountain(m: Node2D, f: Vector2) -> void:
	# Coastal stainless steel drinking column with drainage grate & wet splash
	var wc: ShapeBatch = m._wc
	var sh := Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.24)

	# Wet spray patch on paving
	wc.circle(f + Vector2(12.0, 8.0), 10.0, Color(0.35, 0.50, 0.65, 0.40))
	wc.circle(f + Vector2(16.0, 12.0), 6.0, Color(0.35, 0.50, 0.65, 0.25))

	# Column drop shadow
	wc.rect(Rect2(f.x - 7.0 + 4.0, f.y - 7.0 + 6.0, 14.0, 14.0), sh)

	# Stainless square column body
	wc.rect(Rect2(f.x - 7.0, f.y - 7.0, 14.0, 14.0), Color(0.38, 0.40, 0.44))
	wc.rect(Rect2(f.x - 6.0, f.y - 6.0, 12.0, 12.0), SKATE_RAIL_STEEL)
	# Push-button bubbler & basin
	wc.circle(f, 3.5, Color(0.20, 0.38, 0.55))
	wc.circle(f + Vector2(-1.0, -1.0), 1.5, Color(0.85, 0.95, 1.0))


static func draw_snack(m: Node2D, wc: ShapeBatch, kp: Vector2) -> void:
	# Dropped sports nutrition energy bar in foil packaging
	m.contact_shadow(wc, kp, 9.0, 4.0, 0.20)
	# Metallic foil packaging
	wc.polygon(PackedVector2Array([
		kp + Vector2(-10.0, -5.0),
		kp + Vector2(8.0, -6.0),
		kp + Vector2(10.0, 4.0),
		kp + Vector2(-8.0, 5.0)
	]), Color(0.80, 0.82, 0.85))
	# Cyan & orange sports nutrition logo label
	wc.rect(Rect2(kp.x - 4.0, kp.y - 3.0, 8.0, 6.0), Color(0.15, 0.65, 0.85))
	wc.rect(Rect2(kp.x - 2.0, kp.y - 1.0, 4.0, 3.0), Color(0.95, 0.50, 0.15))


static func draw_live(m: Node2D, wc: ShapeBatch, vt: float, vb: float) -> void:
	# Signature live event: El Skater de l'Esplanada
	if m.skater != null:
		m.skater.draw(m, wc, vt, vb)
