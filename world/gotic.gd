class_name Gotic
extends RefCounted

# WALK: EL GÒTIC (the old town). Its picture as static functions over main's
# state: the alley's paving, doors and plant pots, the roofscape either side
# (La Neteja's streets share it, through draw_roofs and draw_block), and the
# Pont del Bisbe over the alley. systems/detour.gd is the walk's module and
# forwards main's draw hooks here; the laundry lines, the plaça's trees and
# the geranium pots' props stay in main.

const ShapeBatch := preload("res://systems/shape_batch.gd")
const LevelBuild := preload("res://world/level_build.gd")
const GoticCastellers := preload("res://systems/gotic_castellers.gd")
const Scooter := preload("res://systems/scooter.gd")
const Shade := preload("res://systems/shade.gd")
const NightFronts := preload("res://world/night_fronts.gd")

const LANE_HALF := 34.0
const SOMNI_DOOR_Y := -2150.0
const PLACA_MEDALLION_R := 118.0
const EDGE_BAY := 220.0
const WALL_D := 24.0

# Past the alley's own roofs, the old town goes on: the frame either side of
# the walk was the bare masonry fill, flat noisy grey over two fifths of the
# view. Now it is the roofscape seen from above, on a grid fixed in the world
# so it scrolls with everything else: pantile roofs, their ridges one way or
# the other, flat terraces with their water tanks, pots and washing, and the
# odd courtyard or light well dropping down between them. Drawn into the
# edge layer's batch, so it costs no draw calls of its own.
const ROOF_W := 120.0
const ROOF_H := 100.0
# rows start here plus whole rows, so one boundary falls on the plaça's edge
# at GATE_Y - 30 and the two halves of the roofscape meet without a seam
const ROOF_Y0 := -30.0
const TILE: Array[Color] = [Color(0.58, 0.32, 0.22), Color(0.64, 0.38, 0.26), Color(0.54, 0.30, 0.22),
	Color(0.68, 0.44, 0.30)]
const TERRAT: Array[Color] = [Color(0.70, 0.54, 0.42), Color(0.74, 0.68, 0.58), Color(0.66, 0.58, 0.50)]


static func roof_hash(ix: int, iy: int) -> int:
	var h := (ix * 73856093) ^ (iy * 19349663)
	h = (h ^ (h >> 13)) * 1274126177
	return absi(h ^ (h >> 16))


# EL GOTIC: the steps, the parked scooters, and the bridge between two
# buildings, drawn as its shadow across the alley and its stone lip at each
# wall (the overhead layer draws the bridge itself above everyone)
static func _batch_for(target: Object) -> ShapeBatch:
	if target is ShapeBatch:
		return target as ShapeBatch
	return ShapeBatch.new(target)


static func _alley_edges(m: Node2D, y: float) -> Vector2:
	return m.walk_edges(maxf(y, m.GATE_Y))


static func _alley_doors(m: Node2D) -> Array[Vector3]:
	var out: Array[Vector3] = []
	var fp: Vector2 = LevelBuild.GOTIC_PLACA
	var lane_y: float = Scooter.CROSSING_Y
	var min_y: float = m.GATE_Y + 90.0
	var max_y: float = float(m.START_Y) - 120.0
	var bay0 := int(floorf(min_y / EDGE_BAY))
	var bay1 := int(ceilf(max_y / EDGE_BAY))
	for bi in range(bay0, bay1 + 1):
		var dy := float(bi) * EDGE_BAY + EDGE_BAY * 0.5
		if dy < min_y or dy > max_y:
			continue
		if absf(dy - lane_y) < 70.0 or absf(dy - LevelBuild.GOTIC_STEPS_Y) < 60.0 or absf(dy - fp.y) < 165.0:
			continue
		var ea: Vector2 = _alley_edges(m, dy - 26.0)
		var eb: Vector2 = _alley_edges(m, dy + 26.0)
		var em: Vector2 = _alley_edges(m, dy)
		for side: float in [-1.0, 1.0]:
			if side < 0.0 and absf(dy - SOMNI_DOOR_Y) < 95.0:
				continue
			var slope := absf(ea.x - eb.x) if side < 0.0 else absf(ea.y - eb.y)
			if slope > 4.0:
				continue
			var h := roof_hash(bi, 17 if side < 0.0 else 29)
			if h % 4 == 0:
				continue
			var wx := em.x if side < 0.0 else em.y
			out.append(Vector3(wx, dy, side))
	return out


static func _draw_clipped_h(b: ShapeBatch, x0: float, x1: float, y: float, fp: Vector2, r: float, col: Color, w: float) -> void:
	if x1 <= x0 + 1.0:
		return
	var dy := absf(y - fp.y)
	if dy >= r:
		b.line(Vector2(x0, y), Vector2(x1, y), col, w)
		return
	var dx := sqrt(maxf(0.0, r * r - dy * dy))
	var gap_l := fp.x - dx
	var gap_r := fp.x + dx
	if gap_l > x0 + 1.0:
		b.line(Vector2(x0, y), Vector2(minf(x1, gap_l), y), col, w)
	if x1 > gap_r + 1.0:
		b.line(Vector2(maxf(x0, gap_r), y), Vector2(x1, y), col, w)


static func _draw_clipped_v(b: ShapeBatch, x: float, y0: float, y1: float, fp: Vector2, r: float, col: Color, w: float) -> void:
	if y1 <= y0 + 1.0:
		return
	var dx := absf(x - fp.x)
	if dx >= r:
		b.line(Vector2(x, y0), Vector2(x, y1), col, w)
		return
	var dy := sqrt(maxf(0.0, r * r - dx * dx))
	var gap_t := fp.y - dy
	var gap_b := fp.y + dy
	if gap_t > y0 + 1.0:
		b.line(Vector2(x, y0), Vector2(x, minf(y1, gap_t)), col, w)
	if y1 > gap_b + 1.0:
		b.line(Vector2(x, maxf(y0, gap_b)), Vector2(x, y1), col, w)


static func _draw_placa_medallion(m: Node2D, b: ShapeBatch, fp: Vector2) -> void:
	# radial honed-stone medallion kept inside the open plaza between tree pit and castellers
	b.circle(fp, PLACA_MEDALLION_R + 2.0, Color(0.49, 0.44, 0.36))
	b.circle(fp, PLACA_MEDALLION_R - 1.5, Color(0.66, 0.60, 0.49))
	for k in range(8):
		var a := float(k) * TAU / 8.0 + PI / 8.0
		var v := Vector2.from_angle(a)
		b.line(fp + v * 42.0, fp + v * (PLACA_MEDALLION_R - 2.0), Color(0, 0, 0, 0.14), 2.4)
	for r_sett in [68.0, 94.0]:
		for seg in range(32):
			var a0 := float(seg) * TAU / 32.0
			var a1 := float(seg + 1) * TAU / 32.0
			b.line(fp + Vector2.from_angle(a0) * r_sett, fp + Vector2.from_angle(a1) * r_sett, Color(0, 0, 0, 0.10), 1.8)

	# the octagonal Baroque stone fountain
	var pts_sh := PackedVector2Array()
	var pts_plinth := PackedVector2Array()
	var pts_rim := PackedVector2Array()
	var pts_water := PackedVector2Array()
	for i in range(8):
		var ang := float(i) * TAU / 8.0 + PI / 8.0
		var dir := Vector2.from_angle(ang)
		pts_sh.append(fp + Shade.light * 10.0 + dir * 44.0)
		pts_plinth.append(fp + dir * 42.0)
		pts_rim.append(fp + dir * 39.0)
		pts_water.append(fp + dir * 31.0)
	b.polygon(pts_sh, Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.24))
	b.polygon(pts_plinth, Color(0.54, 0.50, 0.44))
	b.polygon(pts_rim, Color(0.66, 0.62, 0.55))
	for i in range(8):
		var p0 := pts_rim[i]
		var p1 := pts_rim[(i + 1) % 8]
		var mid_n := ((p0 + p1) * 0.5 - fp).normalized()
		var col := Color(0.78, 0.74, 0.67) if mid_n.dot(-Shade.light) > 0.0 else Color(0.46, 0.42, 0.36)
		b.line(p0, p1, col, 2.0)
	b.polygon(pts_water, Color(0.28, 0.46, 0.54))
	# water sky reflection & ripples
	b.circle(fp + Vector2(-8, -8), 13.0, Color(0.44, 0.62, 0.70, 0.6))
	b.circle(fp, 20.0, Color(0.34, 0.52, 0.60, 0.35))
	b.circle(fp, 13.0, Color(0.38, 0.56, 0.64, 0.3))
	# central Baroque baluster pedestal & spouts
	b.circle(fp + Shade.light * 3.0, 10.0, Color(0.20, 0.32, 0.38, 0.5))
	b.circle(fp, 9.5, Color(0.56, 0.52, 0.46))
	b.circle(fp - Shade.light * 1.5, 7.0, Color(0.68, 0.64, 0.58))
	b.circle(fp - Shade.light * 2.5, 4.0, Color(0.78, 0.74, 0.68))
	for s in range(4):
		var sdir := Vector2.from_angle(float(s) * TAU / 4.0)
		b.line(fp + sdir * 4.0, fp + sdir * 11.0, Color(0.44, 0.40, 0.30), 2.0)
		b.circle(fp + sdir * 16.0, 2.2, Color(0.85, 0.95, 1.0, 0.75))
		b.circle(fp + sdir * 16.0, 4.0, Color(0.48, 0.66, 0.74, 0.4))


static func _draw_side_lane_row(b: ShapeBatch, r_top: float, r_bot: float, e0: Vector2, e1: Vector2, row: int, walkway: Color, sh_col: Color) -> void:
	var lane_t := Scooter.CROSSING_Y - LANE_HALF
	var lane_b := Scooter.CROSSING_Y + LANE_HALF
	var a := maxf(r_top, lane_t)
	var c_bot := minf(r_bot, lane_b)
	if c_bot <= a:
		return
	var lane_col := walkway.darkened(0.09)
	var lx_in := minf(e0.x, e1.x)
	var rx_in := maxf(e0.y, e1.y)
	b.rect(Rect2(-240.0, a, lx_in + 240.5, c_bot - a), lane_col)
	b.rect(Rect2(rx_in - 0.5, a, 1540.0 - rx_in, c_bot - a), lane_col)
	var off := 32.0 if row % 2 == 0 else 0.0
	var gx := -240.0 + off
	while gx < 1540.0:
		if gx < lx_in - 2.0 or gx > rx_in + 2.0:
			b.line(Vector2(gx, a), Vector2(gx, c_bot), Color(0, 0, 0, 0.09), 1.8)
		gx += 64.0
	if absf(a - r_top) < 0.5 and a > lane_t + 2.0:
		b.line(Vector2(-240.0, a), Vector2(lx_in, a), Color(0, 0, 0, 0.09), 1.8)
		b.line(Vector2(rx_in, a), Vector2(1540.0, a), Color(0, 0, 0, 0.09), 1.8)
	# top & bottom eaves shade along the cross-alley walls
	if a < lane_t + 8.0:
		var h0 := minf(c_bot, lane_t + 8.0) - a
		b.rect(Rect2(-240.0, a, lx_in + 240.0, h0), sh_col)
		b.rect(Rect2(rx_in, a, 1540.0 - rx_in, h0), sh_col)
	if c_bot > lane_b - 6.0:
		var y_sh := maxf(a, lane_b - 6.0)
		b.rect(Rect2(-240.0, y_sh, lx_in + 240.0, c_bot - y_sh), sh_col)
		b.rect(Rect2(rx_in, y_sh, 1540.0 - rx_in, c_bot - y_sh), sh_col)
	# subtle mouth kerb stones where the cross-alley joins the main alley
	b.line(Vector2(e0.x, a), Vector2(e1.x, c_bot), Color(0, 0, 0, 0.14), 2.0)
	b.line(Vector2(e0.y, a), Vector2(e1.y, c_bot), Color(0, 0, 0, 0.14), 2.0)


static func draw_cross_section(m: Node2D, wc: Object, _top: float, bottom: float, _ctop: float, vt: float, vb: float) -> void:
	var b := _batch_for(wc)
	var y_lo := maxf(vt - 80.0, m.GATE_Y - 30.0)
	var y_hi := minf(vb + 80.0, bottom)
	if y_hi <= y_lo:
		if not (wc is ShapeBatch):
			b.flush()
		return

	var fp: Vector2 = LevelBuild.GOTIC_PLACA
	var walkway: Color = m.walkway_col()
	var sh_col := Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.12)
	var drain_end := float(m.NAME_Y) - 24.0
	var lane_t := Scooter.CROSSING_Y - LANE_HALF
	var lane_b := Scooter.CROSSING_Y + LANE_HALF

	# Plaça dels Gossos threshold apron (-5030..-5000): carry the square's stone flags through the gateposts
	if y_lo < m.GATE_Y and y_hi > m.GATE_Y - 30.0:
		var t0 := maxf(y_lo, m.GATE_Y - 30.0)
		var t1 := minf(y_hi, m.GATE_Y)
		var ge0 := _alley_edges(m, t0)
		var ge1 := _alley_edges(m, t1)
		b.polygon(PackedVector2Array([
			Vector2(ge0.x, t0), Vector2(ge0.y, t0),
			Vector2(ge1.y, t1), Vector2(ge1.x, t1),
		]), Color(0.66, 0.60, 0.52))
		var gx := 70.0 + ceilf((maxf(ge0.x, ge1.x) - 70.0) / 56.0) * 56.0
		var gx_max := minf(ge0.y, ge1.y) - 2.0
		while gx <= gx_max:
			b.line(Vector2(gx, t0), Vector2(gx, t1), Color(0.56, 0.50, 0.43, 0.5), 1.5)
			gx += 56.0

	# Staggered stone setts from wall to wall inside the alley and Sant Felip Neri
	var start_y := maxf(y_lo, m.GATE_Y)
	var row := int(floorf((start_y - 60.0) / 56.0))
	var ry := float(row) * 56.0
	while ry < y_hi + 56.0:
		var r_top := maxf(ry, m.GATE_Y)
		var r_bot := minf(ry + 56.0, y_hi)
		if r_bot > r_top:
			var e0: Vector2 = _alley_edges(m, r_top)
			var e1: Vector2 = _alley_edges(m, r_bot)
			b.polygon(PackedVector2Array([
				Vector2(e0.x, r_top), Vector2(e0.y, r_top),
				Vector2(e1.y, r_bot), Vector2(e1.x, r_bot),
			]), walkway)

			if r_bot > lane_t and r_top < lane_b:
				_draw_side_lane_row(b, r_top, r_bot, e0, e1, row, walkway, sh_col)

			# subtle stone-to-stone value shift on full interior setts
			var in_steps := r_bot > LevelBuild.GOTIC_STEPS_Y - 6.0 and r_top < LevelBuild.GOTIC_STEPS_Y + 66.0
			var off := 32.0 if row % 2 == 0 else 0.0
			var rx := floorf(minf(e0.x, e1.x) / 64.0) * 64.0 + off
			var x_hi_max := maxf(e0.y, e1.y)
			var in_x_min := maxf(e0.x, e1.x) + 2.0
			var in_x_max := minf(e0.y, e1.y) - 2.0
			if not in_steps and r_bot - r_top >= 40.0:
				var cx_row := rx
				while cx_row < x_hi_max:
					if cx_row >= in_x_min and cx_row + 64.0 <= in_x_max:
						var sc := Vector2(cx_row + 32.0, (r_top + r_bot) * 0.5)
						if sc.distance_to(fp) > PLACA_MEDALLION_R + 40.0:
							var sh_hash := roof_hash(int(floorf(cx_row / 64.0)), row) % 11
							if sh_hash < 2:
								b.rect(Rect2(cx_row + 1.0, r_top + 1.0, 62.0, r_bot - r_top - 2.0), walkway.lightened(0.032))
							elif sh_hash == 2:
								b.rect(Rect2(cx_row + 1.0, r_top + 1.0, 62.0, r_bot - r_top - 2.0), walkway.darkened(0.035))
					cx_row += 64.0

			# sett mortar lines (kept clear of the steps and radial plaza medallion)
			if absf(r_top - ry) < 0.5 and ry > m.GATE_Y + 2.0:
				var skip_h := ry > LevelBuild.GOTIC_STEPS_Y - 4.0 and ry < LevelBuild.GOTIC_STEPS_Y + 64.0
				if not skip_h:
					_draw_clipped_h(b, e0.x, e0.y, ry, fp, PLACA_MEDALLION_R, Color(0, 0, 0, 0.10), 2.0)
			var vx := rx
			while vx < x_hi_max:
				var y_clip_t := r_top
				var y_clip_b := r_bot
				if in_steps:
					if r_bot > LevelBuild.GOTIC_STEPS_Y and r_top < LevelBuild.GOTIC_STEPS_Y + 60.0:
						vx += 64.0
						continue
				if vx > in_x_min and vx < in_x_max:
					_draw_clipped_v(b, vx, y_clip_t, y_clip_b, fp, PLACA_MEDALLION_R, Color(0, 0, 0, 0.10), 2.0)
				vx += 64.0

			# soft wall-foot shadow along solid facades (skipped across the -1720 side-alley mouth)
			var is_mouth := r_top >= lane_t and r_bot <= lane_b
			if not is_mouth:
				b.polygon(PackedVector2Array([
					Vector2(e0.x, r_top), Vector2(e0.x + 7.0, r_top),
					Vector2(e1.x + 7.0, r_bot), Vector2(e1.x, r_bot),
				]), sh_col)
				b.polygon(PackedVector2Array([
					Vector2(e0.y - 7.0, r_top), Vector2(e0.y, r_top),
					Vector2(e1.y, r_bot), Vector2(e1.y - 7.0, r_bot),
				]), sh_col)

			# central stone drainage channel and iron grates (stop cleanly north of Sant Felip Neri, steps, crossing, and title)
			var mid_y := (r_top + r_bot) * 0.5
			var in_drain_zone: bool = r_top >= float(m.GATE_Y) + 24.0 and r_bot <= drain_end
			var skip_drain: bool = absf(mid_y - fp.y) < 250.0 or (r_bot > LevelBuild.GOTIC_STEPS_Y - 16.0 and r_top < LevelBuild.GOTIC_STEPS_Y + 76.0) or (r_bot > lane_t - 6.0 and r_top < lane_b + 6.0)
			if in_drain_zone and not skip_drain:
				var dt := maxf(r_top, float(m.GATE_Y) + 28.0)
				var db := minf(r_bot, drain_end)
				if db > dt:
					var e_dt := _alley_edges(m, dt)
					var e_db := _alley_edges(m, db)
					var cx_dt := (e_dt.x + e_dt.y) * 0.5
					var cx_db := (e_db.x + e_db.y) * 0.5
					b.line(Vector2(cx_dt - 14.0, dt), Vector2(cx_db - 14.0, db), Color(0, 0, 0, 0.09), 1.5)
					b.line(Vector2(cx_dt + 14.0, dt), Vector2(cx_db + 14.0, db), Color(0, 0, 0, 0.09), 1.5)
					var is_end_grate := row == -2
					var near_bridge := absf(ry + 28.0 - LevelBuild.GOTIC_BRIDGE_Y) < 60.0
					if (row % 6 == 0 or is_end_grate) and ry >= float(m.GATE_Y) + 60.0 and not near_bridge and db - dt >= 42.0:
						var acx := (cx_dt + cx_db) * 0.5
						b.rect(Rect2(acx - 10.0, dt + 16.0, 20.0, 24.0), Color(0.18, 0.18, 0.20))
						b.rect(Rect2(acx - 8.0, dt + 18.0, 16.0, 20.0), Color(0.10, 0.10, 0.12))
						for g in range(3):
							var gy := dt + 22.0 + float(g) * 5.0
							b.line(Vector2(acx - 7.0, gy), Vector2(acx + 7.0, gy), Color(0.28, 0.28, 0.30), 1.5)
		ry += 56.0
		row += 1

	# Side-alley stone parapet walls and corner quoins framing the scooter crossing
	if lane_b > y_lo - 40.0 and lane_t < y_hi + 40.0:
		var et := _alley_edges(m, lane_t)
		var eb := _alley_edges(m, lane_b)
		var wall_base := Color(0.36, 0.33, 0.30)
		var coping := wall_base.lightened(0.28)
		var face_sh := wall_base.darkened(0.42)
		var quoin := Color(0.58, 0.53, 0.46)
		# North parapet of side-alley (lane_t - 10..lane_t)
		b.rect(Rect2(-240.0, lane_t - 10.0, et.x + 240.0, 10.0), face_sh)
		b.rect(Rect2(-240.0, lane_t - 14.0, et.x + 240.0, 4.5), coping)
		b.rect(Rect2(et.y, lane_t - 10.0, 1540.0 - et.y, 10.0), face_sh)
		b.rect(Rect2(et.y, lane_t - 14.0, 1540.0 - et.y, 4.5), coping)
		# South parapet of side-alley (lane_b..lane_b + 8)
		b.rect(Rect2(-240.0, lane_b, eb.x + 240.0, 8.0), face_sh.darkened(0.10))
		b.rect(Rect2(-240.0, lane_b + 8.0, eb.x + 240.0, 4.5), coping.darkened(0.06))
		b.rect(Rect2(eb.y, lane_b, 1540.0 - eb.y, 8.0), face_sh.darkened(0.10))
		b.rect(Rect2(eb.y, lane_b + 8.0, 1540.0 - eb.y, 4.5), coping.darkened(0.06))
		# Dressed limestone corner quoins at the four junction corners
		b.rect(Rect2(et.x - 16.0, lane_t - 14.0, 16.0, 14.0), quoin)
		b.rect(Rect2(et.y, lane_t - 14.0, 16.0, 14.0), quoin)
		b.rect(Rect2(eb.x - 16.0, lane_b, 16.0, 12.5), quoin.darkened(0.06))
		b.rect(Rect2(eb.y, lane_b, 16.0, 12.5), quoin.darkened(0.06))

	# projecting limestone threshold steps under each street door
	for door: Vector3 in _alley_doors(m):
		if door.y < y_lo - 40.0 or door.y > y_hi + 40.0:
			continue
		var street := -door.z
		var sx := door.x if street > 0.0 else door.x - 12.0
		b.rect(Rect2(sx, door.y - 16.0, 12.0, 32.0), Color(0.60, 0.57, 0.51))
		var rim_x := door.x + 10.0 if street > 0.0 else door.x - 12.0
		b.rect(Rect2(rim_x, door.y - 16.0, 2.0, 32.0), Color(0.74, 0.70, 0.64))
		var sh_x := door.x + 2.0 if street > 0.0 else door.x - 14.0
		b.rect(Rect2(sh_x, door.y - 15.0, 12.0, 30.0), Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.13))

	# Plaça de Sant Felip Neri medallion and Baroque fountain
	if fp.y > y_lo - 260.0 and fp.y < y_hi + 260.0:
		_draw_placa_medallion(m, b, fp)

	# Terracotta pots of geraniums
	_draw_pots(m, b, y_lo, y_hi, fp)

	# Stepped stone slope running cleanly wall-to-wall
	var sy: float = LevelBuild.GOTIC_STEPS_Y
	if sy > y_lo - 80.0 and sy < y_hi + 80.0:
		for k in range(5):
			var yy := sy + float(k) * 12.0
			var yy_b := yy + 12.0
			var e_t := _alley_edges(m, yy)
			var e_b := _alley_edges(m, yy_b)
			b.polygon(PackedVector2Array([
				Vector2(e_t.x, yy), Vector2(e_t.y, yy),
				Vector2(e_b.y, yy_b), Vector2(e_b.x, yy_b),
			]), Color(0.58, 0.54, 0.48).darkened(0.05 * float(k)))
			b.line(Vector2(e_t.x, yy), Vector2(e_t.y, yy), Color(0.73, 0.69, 0.63), 2.0)
			b.line(Vector2(e_b.x, yy_b), Vector2(e_b.y, yy_b), Color(0, 0, 0, 0.16), 1.4)
		var bot_e := _alley_edges(m, sy + 60.0)
		var bot_sh_e := _alley_edges(m, sy + 66.0)
		b.polygon(PackedVector2Array([
			Vector2(bot_e.x, sy + 60.0), Vector2(bot_e.y, sy + 60.0),
			Vector2(bot_sh_e.y, sy + 66.0), Vector2(bot_sh_e.x, sy + 66.0),
		]), Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.16))

	# Pont del Bisbe: arched shadow cast onto the alley with corbel tabs and warm lantern pool
	var by: float = LevelBuild.GOTIC_BRIDGE_Y
	if by > y_lo - 120.0 and by < y_hi + 120.0:
		var e2: Vector2 = _alley_edges(m, by)
		var cx := (e2.x + e2.y) * 0.5
		b.rect(Rect2(e2.x, by + 16.0, e2.y - e2.x, 68.0), Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.24))
		b.rect(Rect2(e2.x, by + 10.0, 26.0, 78.0), Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.28))
		b.rect(Rect2(e2.y - 26.0, by + 10.0, 26.0, 78.0), Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.28))
		b.rect(Rect2(e2.x, by + 84.0, e2.y - e2.x, 8.0), Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.12))
		b.glow(Vector2(cx, by + 46.0), 60.0, Color(1.0, 0.88, 0.52, 0.55), 0.15)

	if not (wc is ShapeBatch):
		b.flush()


static func draw_live(m: Node2D, wc: ShapeBatch, vt: float, vb: float) -> void:
	var fp: Vector2 = LevelBuild.GOTIC_PLACA
	if fp.y > vt - 320.0 and fp.y < vb + 320.0:
		GoticCastellers.draw(m, wc, vt, vb)
	m._draw_scooters(wc, vt, vb)


static func draw_edge_layer(m: Node2D, c: Object, vt: float, vb: float) -> void:
	var b := _batch_for(c)
	var gate_top: float = m.GATE_Y - 30.0
	var y_lo := maxf(vt - 320.0, gate_top)
	var y_hi := vb + 320.0
	if y_hi <= y_lo:
		if not (c is ShapeBatch):
			b.flush()
		return

	var base := Color(0.36, 0.33, 0.30)
	var lane_t := Scooter.CROSSING_Y - LANE_HALF
	var lane_b := Scooter.CROSSING_Y + LANE_HALF

	# 1. Continuous masonry base fill following the alley's true edges
	var sy := y_lo
	while sy < y_hi - 0.1:
		var sy_next := minf(sy + 40.0, y_hi)
		var ea := _alley_edges(m, sy)
		var eb := _alley_edges(m, sy_next)
		b.quad(Vector2(-900.0, sy), Vector2(ea.x, sy), Vector2(eb.x, sy_next), Vector2(-900.0, sy_next), base)
		b.quad(Vector2(ea.y, sy), Vector2(2200.0, sy), Vector2(2200.0, sy_next), Vector2(eb.y, sy_next), base)
		sy = sy_next

	# 2. Outer old-town roofscape grid
	draw_roofs(m, b, vt, vb)

	# 3. Front-row terracotta pantile roofs meeting the alley wall face without gaps
	var iy0 := int(floorf((vt - 320.0 - ROOF_Y0) / ROOF_H))
	var iy1 := int(ceilf((vb + 320.0 - ROOF_Y0) / ROOF_H))
	for iy in range(iy0, iy1):
		var y0 := float(iy) * ROOF_H + ROOF_Y0
		var y1 := y0 + ROOF_H
		if y1 <= gate_top:
			continue
		y0 = maxf(y0, gate_top)
		var lim_l := INF
		var lim_r := -INF
		for t: float in [0.0, 0.5, 1.0]:
			var f: Vector2 = m.frontage(maxf(lerpf(y0, y1, t), m.GATE_Y + 1.0))
			lim_l = minf(lim_l, f.x)
			lim_r = maxf(lim_r, f.y)
		var mid := (y0 + y1) * 0.5
		for half in range(2):
			var ha: float = y0 if half == 0 else mid
			var hb: float = mid if half == 0 else y1
			if hb <= gate_top or hb - ha < 12.0:
				continue
			ha = maxf(ha, gate_top)
			var fa: Vector2 = m.frontage(maxf(ha, m.GATE_Y + 1.0))
			var fb: Vector2 = m.frontage(maxf(hb, m.GATE_Y + 1.0))
			var hl := minf(fa.x, fb.x)
			var hr := maxf(fa.y, fb.y)
			var out_l: float = (hl - 106.0) if (hl - lim_l >= 38.0) else (lim_l - 106.0)
			var out_r: float = (hr + 106.0) if (lim_r - hr >= 38.0) else (lim_r + 106.0)
			var bay := int(floorf(((ha + hb) * 0.5) / EDGE_BAY))
			var tile_l: Color = TILE[roof_hash(bay, 11) % TILE.size()]
			var tile_r: Color = TILE[roof_hash(bay, 23) % TILE.size()]

			for s in range(2):
				var ya := lerpf(ha, hb, float(s) * 0.5)
				var yb := lerpf(ha, hb, float(s + 1) * 0.5)
				if yb <= ya + 0.5:
					continue
				var ea := _alley_edges(m, ya)
				var eb := _alley_edges(m, yb)
				var in_l_a := ea.x - WALL_D
				var in_l_b := eb.x - WALL_D
				var in_r_a := ea.y + WALL_D
				var in_r_b := eb.y + WALL_D
				if in_l_a > out_l + 4.0 and in_l_b > out_l + 4.0:
					b.quad(Vector2(out_l, ya), Vector2(in_l_a, ya), Vector2(in_l_b, yb), Vector2(out_l, yb), tile_l)
					var cy := ya + 6.0
					while cy < yb - 1.0:
						var ec := _alley_edges(m, cy)
						b.line(Vector2(out_l + 2.0, cy), Vector2(ec.x - WALL_D - 1.0, cy), tile_l.darkened(0.22), 1.8)
						cy += 12.5
					b.line(Vector2(out_l + 4.5, ya), Vector2(out_l + 4.5, yb), tile_l.lightened(0.26), 4.0)
				if out_r > in_r_a + 4.0 and out_r > in_r_b + 4.0:
					b.quad(Vector2(in_r_a, ya), Vector2(out_r, ya), Vector2(out_r, yb), Vector2(in_r_b, yb), tile_r)
					var cy := ya + 6.0
					while cy < yb - 1.0:
						var ec := _alley_edges(m, cy)
						b.line(Vector2(ec.y + WALL_D + 1.0, cy), Vector2(out_r - 2.0, cy), tile_r.darkened(0.22), 1.8)
						cy += 12.5
					b.line(Vector2(out_r - 4.5, ya), Vector2(out_r - 4.5, yb), tile_r.lightened(0.26), 4.0)

			# Party-wall parapet and chimney stack once per roof bay
			if half == 1 and hb > gate_top + 20.0 and (hb < lane_t - 12.0 or hb > lane_b + 12.0):
				var eh := _alley_edges(m, hb)
				if eh.x - WALL_D > out_l + 10.0:
					b.line(Vector2(out_l, hb), Vector2(eh.x - WALL_D, hb), base.darkened(0.25), 3.0)
				if out_r > eh.y + WALL_D + 10.0:
					b.line(Vector2(eh.y + WALL_D, hb), Vector2(out_r, hb), base.darkened(0.25), 3.0)
			if half == 0 and (ha + 26.0 < lane_t - 16.0 or ha + 26.0 > lane_b + 16.0):
				var ec := _alley_edges(m, ha + 24.0)
				if roof_hash(iy, 41) % 2 == 0 and ec.x - WALL_D - out_l > 42.0:
					var cp := Vector2(ec.x - WALL_D - 28.0, ha + 18.0)
					b.rect(Rect2(cp + Vector2(4.0, 5.0), Vector2(14.0, 16.0)), Color(0.05, 0.04, 0.07, 0.24))
					b.rect(Rect2(cp, Vector2(14.0, 16.0)), Color(0.44, 0.28, 0.21))
					b.rect(Rect2(cp + Vector2(3.0, 3.0), Vector2(8.0, 7.0)), Color(0.20, 0.16, 0.15))
				if roof_hash(iy, 53) % 2 == 0 and out_r - (ec.y + WALL_D) > 42.0:
					var cp := Vector2(ec.y + WALL_D + 14.0, ha + 20.0)
					b.rect(Rect2(cp + Vector2(4.0, 5.0), Vector2(14.0, 16.0)), Color(0.05, 0.04, 0.07, 0.24))
					b.rect(Rect2(cp, Vector2(14.0, 16.0)), Color(0.44, 0.28, 0.21))
					b.rect(Rect2(cp + Vector2(3.0, 3.0), Vector2(8.0, 7.0)), Color(0.20, 0.16, 0.15))

	# 4. Inclined stone wall faces, limestone roof coping, and cast shadows along the alley
	var wy := y_lo
	while wy < y_hi - 0.1:
		var wy_next := minf(wy + 24.0, y_hi)
		if wy < lane_t and wy_next > lane_t:
			wy_next = lane_t
		elif wy >= lane_t and wy < lane_b:
			wy = minf(lane_b, y_hi)
			continue
		var ea := _alley_edges(m, wy)
		var eb := _alley_edges(m, wy_next)
		for i in range(6):
			var t0 := float(i) / 6.0
			var t1 := float(i + 1) / 6.0
			var lo0 := -WALL_D + WALL_D * t0
			var lo1 := -WALL_D + WALL_D * t1 + 0.6
			b.quad(Vector2(ea.x + lo0, wy), Vector2(ea.x + lo1, wy), Vector2(eb.x + lo1, wy_next), Vector2(eb.x + lo0, wy_next), base.darkened(0.52 - t0 * 0.34))
			var hi0 := WALL_D - WALL_D * t1 - 0.6
			var hi1 := WALL_D - WALL_D * t0
			b.quad(Vector2(ea.y + hi0, wy), Vector2(ea.y + hi1, wy), Vector2(eb.y + hi1, wy_next), Vector2(eb.y + hi0, wy_next), base.darkened(0.56 - t0 * 0.34))
		# Roof-edge limestone coping stones
		b.quad(Vector2(ea.x - WALL_D - 5.0, wy), Vector2(ea.x - WALL_D, wy), Vector2(eb.x - WALL_D, wy_next), Vector2(eb.x - WALL_D - 5.0, wy_next), base.lightened(0.30))
		b.quad(Vector2(ea.y + WALL_D, wy), Vector2(ea.y + WALL_D + 5.0, wy), Vector2(eb.y + WALL_D + 5.0, wy_next), Vector2(eb.y + WALL_D, wy_next), base.lightened(0.24))
		wy = wy_next

	# 5. Recessed Gothic doorway reveals along the alley walls
	for door: Vector3 in _alley_doors(m):
		if door.y < y_lo - 40.0 or door.y > y_hi + 40.0:
			continue
		var into := door.z
		var wx := door.x
		var dy := door.y
		b.rect(Rect2(minf(wx, wx + into * 24.0), dy - 20.0, 24.0, 40.0), Color(0.48, 0.44, 0.38))
		b.rect(Rect2(minf(wx, wx + into * 22.0), dy - 18.0, 22.0, 36.0), Color(0.22, 0.19, 0.17))
		var leaf_x := wx + into * 15.0
		b.rect(Rect2(minf(leaf_x, leaf_x + into * 7.0), dy - 15.0, 7.0, 30.0), Color(0.16, 0.12, 0.10))
		b.rect(Rect2(minf(leaf_x, leaf_x + into * 7.0), dy - 15.0, 2.0, 30.0), Color(0.30, 0.23, 0.18))
		b.circle(Vector2(leaf_x + into * 3.0, dy + 7.0), 1.6, Color(0.80, 0.70, 0.42))

	# 6. North Plaça dels Gossos threshold cornice and dressed stone gatepost returns at y = GATE_Y - 30
	if y_lo <= gate_top + 16.0 and y_hi >= gate_top - 4.0:
		var ge := _alley_edges(m, m.GATE_Y)
		var coping_col := Color(0.70, 0.65, 0.57)
		var frieze_col := Color(0.52, 0.47, 0.40)
		var soffit_col := Color(0.32, 0.28, 0.24)
		# West cornice return (-900..ge.x)
		b.rect(Rect2(-900.0, gate_top, ge.x + 900.0, 5.0), coping_col)
		b.rect(Rect2(-900.0, gate_top + 5.0, ge.x + 900.0, 5.0), frieze_col)
		b.line(Vector2(-900.0, gate_top + 10.0), Vector2(ge.x, gate_top + 10.0), soffit_col, 2.0)
		# East cornice return (ge.y..2200)
		b.rect(Rect2(ge.y, gate_top, 2200.0 - ge.y, 5.0), coping_col)
		b.rect(Rect2(ge.y, gate_top + 5.0, 2200.0 - ge.y, 5.0), frieze_col)
		b.line(Vector2(ge.y, gate_top + 10.0), Vector2(2200.0, gate_top + 10.0), soffit_col, 2.0)
		# Corner quoin piers tying the alley walls into the gateposts
		b.rect(Rect2(ge.x - WALL_D - 5.0, gate_top, WALL_D + 5.0, 30.0), Color(0.60, 0.55, 0.47))
		b.rect(Rect2(ge.x - WALL_D - 2.0, gate_top + 3.0, WALL_D - 1.0, 24.0), Color(0.68, 0.63, 0.55))
		b.rect(Rect2(ge.y, gate_top, WALL_D + 5.0, 30.0), Color(0.60, 0.55, 0.47))
		b.rect(Rect2(ge.y + 3.0, gate_top + 3.0, WALL_D - 1.0, 24.0), Color(0.68, 0.63, 0.55))

	if not (c is ShapeBatch):
		b.flush()


static func night_fronts(m: Node2D) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var idx := 0
	for door: Vector3 in _alley_doors(m):
		var k := 700 + idx
		idx += 1
		var kind := NightFronts.kind_of(k)
		if kind == "":
			kind = "home" if idx % 2 == 0 else "bar"
		var side := door.z
		out.append(NightFronts.front(Vector2(door.x, door.y), -side, kind, k))
	return out


# terracotta pots of geraniums flanking old doorways and plaza corners
static func _draw_pots(m: Node2D, b: ShapeBatch, vt: float, vb: float, fp: Vector2) -> void:
	var pots: Array[Vector2] = [
		Vector2(fp.x - 225.0, fp.y - 120.0),
		Vector2(fp.x - 225.0, fp.y - 95.0),
		Vector2(fp.x + 230.0, fp.y + 90.0),
		Vector2(fp.x + 230.0, fp.y + 115.0),
		Vector2(m.walk_edges(-850.0).y - 18.0, -850.0),
		Vector2(m.walk_edges(-1400.0).x + 18.0, -1400.0),
		Vector2(m.walk_edges(-2250.0).y - 18.0, -2250.0),
		Vector2(m.walk_edges(-3400.0).x + 18.0, -3400.0),
		Vector2(m.walk_edges(-4200.0).y - 18.0, -4200.0),
		# the last stretch before the plaça: a pair by each of its doors
		Vector2(m.walk_edges(-4660.0).y - 18.0, -4660.0),
		Vector2(m.walk_edges(-4710.0).y - 18.0, -4710.0),
		Vector2(m.walk_edges(-4875.0).x + 18.0, -4875.0),
		Vector2(m.walk_edges(-4925.0).x + 18.0, -4925.0),
	]
	for pp in pots:
		if pp.y < vt - 30.0 or pp.y > vb + 30.0:
			continue
		b.circle(pp + Shade.light * 4.0, 8.0, Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.22))
		b.circle(pp, 7.5, Color(0.72, 0.38, 0.24))
		b.circle(pp, 5.5, Color(0.30, 0.20, 0.14))
		for lf in range(4):
			b.circle(pp + Vector2.from_angle(float(lf) * TAU / 4.0 + 0.4) * 3.5, 3.2, Color(0.24, 0.44, 0.20))
		for fl in range(3):
			b.circle(pp + Vector2.from_angle(float(fl) * TAU / 3.0 + 0.8) * 3.0, 2.0, Color(0.92, 0.16, 0.24))


static func draw_roofs(m: Node2D, c: Object, vt: float, vb: float) -> void:
	var iy0 := int(floorf((vt - 320.0 - ROOF_Y0) / ROOF_H))
	var iy1 := int(ceilf((vb + 320.0 - ROOF_Y0) / ROOF_H))
	for iy in range(iy0, iy1):
		var y0 := float(iy) * ROOF_H + ROOF_Y0
		var y1 := y0 + ROOF_H
		if y1 <= m.GATE_Y - 30.0:
			continue          # the plaça draws the roofs round itself
		y0 = maxf(y0, m.GATE_Y - 30.0)
		# stay behind the alley's own roofs wherever the alley has jinked to
		var lim_l := INF
		var lim_r := -INF
		for t: float in [0.0, 0.5, 1.0]:
			# (past the gate the walk's edges are the square's, so ask below it)
			var f: Vector2 = m.frontage(maxf(lerpf(y0, y1, t), m.GATE_Y + 1.0))
			lim_l = minf(lim_l, f.x)
			lim_r = maxf(lim_r, f.y)
		_roof_row(m, c, iy, lim_l - 700.0, lim_l - 108.0, y0, y1)
		_roof_row(m, c, iy, lim_r + 108.0, lim_r + 700.0, y0, y1)
		# where the alley jinks inside the row, the half that is clear of it
		# gets one more roof in the gap rather than a strip of bare masonry
		var mid := (y0 + y1) * 0.5
		for half in range(2):
			var ha: float = y0 if half == 0 else mid
			var hb: float = mid if half == 0 else y1
			if hb - ha < 34.0:
				continue
			var fa: Vector2 = m.frontage(maxf(ha, m.GATE_Y + 1.0))
			var fb: Vector2 = m.frontage(maxf(hb, m.GATE_Y + 1.0))
			var hl := minf(fa.x, fb.x)
			var hr := maxf(fa.y, fb.y)
			if hl - lim_l >= 38.0:
				draw_block(m, c, Rect2(lim_l - 106.0, ha + 2.0, hl - lim_l - 4.0, hb - ha - 4.0), roof_hash(iy * 2 + half, 911))
			if lim_r - hr >= 38.0:
				draw_block(m, c, Rect2(hr + 110.0, ha + 2.0, lim_r - hr - 4.0, hb - ha - 4.0), roof_hash(iy * 2 + half, 913))


# ...and round the plaça at the top, for as far as the camera can see
static func draw_roofs_round_placa(m: Node2D, c: Object) -> void:
	var r: Rect2 = m._freedom_rect()
	var hole := Rect2(r.position.x - 40.0, r.position.y - 46.0, r.size.x + 80.0, r.size.y + 46.0)
	var cy: float = m.cam.position.y
	var iy0 := int(floorf((cy - 900.0 - ROOF_Y0) / ROOF_H))
	var iy1 := int(ceilf((cy + 900.0 - ROOF_Y0) / ROOF_H))
	for iy in range(iy0, iy1):
		var y0 := float(iy) * ROOF_H + ROOF_Y0
		var y1 := minf(y0 + ROOF_H, m.GATE_Y - 30.0)
		if y1 - y0 < 34.0:
			continue
		if y1 > hole.position.y and y0 < hole.end.y:
			# beside the square's own house fronts, which stand behind the
			# roofs' cut edge
			if y0 < hole.position.y:
				_roof_row(m, c, iy, -900.0, 2200.0, y0, hole.position.y)
				y0 = hole.position.y
			_roof_row(m, c, iy, -900.0, hole.position.x, y0, y1)
			_roof_row(m, c, iy, hole.end.x, 2200.0, y0, y1)
		else:
			_roof_row(m, c, iy, -900.0, 2200.0, y0, y1)


# one row of the roofscape between x_lo and x_hi, cut to y_lo..y_hi. Each row
# is slid sideways by its own amount, so the party walls do not line up into
# a grid the way no medieval street plan ever did.
static func _roof_row(m: Node2D, c: Object, iy: int, x_lo: float, x_hi: float, y_lo: float, y_hi: float) -> void:
	if x_hi - x_lo < 34.0 or y_hi - y_lo < 34.0:
		return
	var off := float(roof_hash(7, iy) % int(ROOF_W))
	var ix0 := int(floorf((x_lo - off) / ROOF_W))
	var ix1 := int(ceilf((x_hi - off) / ROOF_W))
	for ix in range(ix0, ix1):
		var x0 := maxf(off + float(ix) * ROOF_W, x_lo)
		var x1 := minf(off + float(ix + 1) * ROOF_W, x_hi)
		if x1 - x0 >= 34.0:
			draw_block(m, c, Rect2(x0 + 2.0, y_lo + 2.0, x1 - x0 - 4.0, y_hi - y_lo - 4.0), roof_hash(ix, iy))


# a block is one building, or two sharing a party wall
static func draw_block(m: Node2D, c: Object, r: Rect2, h: int) -> void:
	var split := (h >> 14) % 5
	if split == 0 and r.size.x >= 84.0:
		var cut := r.size.x * (0.36 + float((h >> 17) % 5) * 0.07)
		_draw_roof(m, c, Rect2(r.position, Vector2(cut - 2.0, r.size.y)), h)
		_draw_roof(m, c, Rect2(r.position.x + cut + 2.0, r.position.y, r.size.x - cut - 2.0, r.size.y), roof_hash(h, 3))
	elif split == 1 and r.size.y >= 84.0:
		var cut := r.size.y * (0.40 + float((h >> 17) % 3) * 0.08)
		_draw_roof(m, c, Rect2(r.position, Vector2(r.size.x, cut - 2.0)), h)
		_draw_roof(m, c, Rect2(r.position.x, r.position.y + cut + 2.0, r.size.x, r.size.y - cut - 2.0), roof_hash(h, 5))
	else:
		_draw_roof(m, c, r, h)


static func _draw_roof(m: Node2D, c: Object, r: Rect2, h: int) -> void:
	if r.size.x < 26.0 or r.size.y < 26.0:
		return
	# its shadow on whatever is lower, down and right, away from the light
	c.draw_rect(Rect2(r.position + Vector2(5.0, 7.0), r.size), Color(0.05, 0.04, 0.07, 0.30))
	var kind := h % 100
	if kind >= 74 and (r.size.x < 70.0 or r.size.y < 70.0):
		kind = 10                         # too small to hold a courtyard
	elif kind >= 52 and kind < 74 and (r.size.x < 46.0 or r.size.y < 46.0):
		kind = 20                         # or a terrat worth the name
	if kind < 52:
		# a pantile roof: the side toward the light lit, the far side in
		# shade, the courses running parallel to the ridge
		var tile: Color = TILE[(h >> 4) % TILE.size()]
		var lit := tile.lightened(0.07)
		var shade := tile.darkened(0.14)
		var course := tile.darkened(0.26)
		if (h >> 7) % 2 == 0 or r.size.x < 60.0:
			var mid := r.position.y + r.size.y * 0.5
			c.draw_rect(Rect2(r.position, Vector2(r.size.x, mid - r.position.y)), lit)
			c.draw_rect(Rect2(r.position.x, mid, r.size.x, r.end.y - mid), shade)
			var cy := r.position.y + 9.0
			while cy < r.end.y - 3.0:
				if absf(cy - mid) > 3.0:
					c.draw_line(Vector2(r.position.x, cy), Vector2(r.end.x, cy), course, 1.5)
				cy += 10.0
			c.draw_line(Vector2(r.position.x, mid), Vector2(r.end.x, mid), tile.lightened(0.30), 3.0)
		else:
			var midx := r.position.x + r.size.x * 0.5
			c.draw_rect(Rect2(r.position, Vector2(midx - r.position.x, r.size.y)), lit)
			c.draw_rect(Rect2(midx, r.position.y, r.end.x - midx, r.size.y), shade)
			var cx := r.position.x + 9.0
			while cx < r.end.x - 3.0:
				if absf(cx - midx) > 3.0:
					c.draw_line(Vector2(cx, r.position.y), Vector2(cx, r.end.y), course, 1.5)
				cx += 10.0
			c.draw_line(Vector2(midx, r.position.y), Vector2(midx, r.end.y), tile.lightened(0.30), 3.0)
		if (h >> 9) % 3 == 0:
			# a chimney stack and its shadow
			var cp := r.position + Vector2(r.size.x * 0.28, r.size.y * 0.30)
			c.draw_rect(Rect2(cp + Vector2(4.0, 5.0), Vector2(11.0, 13.0)), Color(0.05, 0.04, 0.07, 0.30))
			c.draw_rect(Rect2(cp, Vector2(11.0, 13.0)), Color(0.48, 0.42, 0.38))
			c.draw_rect(Rect2(cp + Vector2(2.5, 2.5), Vector2(6.0, 6.0)), Color(0.20, 0.17, 0.16))
		if (h >> 11) % 4 == 0 and r.size.x > 60.0:
			# a skylight let into the slope
			c.draw_rect(Rect2(r.end.x - 30.0, r.end.y - 26.0, 16.0, 12.0), Color(0.40, 0.48, 0.52))
			c.draw_rect(Rect2(r.end.x - 30.0, r.end.y - 26.0, 16.0, 3.0), Color(0.62, 0.70, 0.74))
	elif kind < 74:
		# a terrat: a flat roof of pale tiles inside its parapet, lived on
		var floor_col: Color = TERRAT[(h >> 4) % TERRAT.size()]
		c.draw_rect(r, floor_col.lightened(0.18))
		var fl := r.grow(-4.0)
		c.draw_rect(fl, floor_col)
		var joint := floor_col.darkened(0.10)
		var gx := fl.position.x + 16.0
		while gx < fl.end.x:
			c.draw_line(Vector2(gx, fl.position.y), Vector2(gx, fl.end.y), joint, 1.0)
			gx += 16.0
		var gy := fl.position.y + 16.0
		while gy < fl.end.y:
			c.draw_line(Vector2(fl.position.x, gy), Vector2(fl.end.x, gy), joint, 1.0)
			gy += 16.0
		# the parapet's shadow along its sunny inside edges
		c.draw_rect(Rect2(fl.position, Vector2(fl.size.x, 4.0)), Color(0.05, 0.04, 0.07, 0.14))
		c.draw_rect(Rect2(fl.position, Vector2(4.0, fl.size.y)), Color(0.05, 0.04, 0.07, 0.14))
		# what stands on it goes in its corners, a different one each time
		var corner := (h >> 7) % 4
		var cs: Array[Vector2] = [fl.position, Vector2(fl.end.x, fl.position.y), fl.end, Vector2(fl.position.x, fl.end.y)]
		if (h >> 9) % 3 != 0 and fl.size.x > 40.0:
			# the stair hut that lets out onto it
			var hc: Vector2 = cs[corner]
			var hut := Rect2(clampf(hc.x - 12.0, fl.position.x + 4.0, fl.end.x - 28.0),
				clampf(hc.y - 10.0, fl.position.y + 4.0, fl.end.y - 24.0), 24.0, 20.0)
			c.draw_rect(Rect2(hut.position + Vector2(4.0, 5.0), hut.size), Color(0.05, 0.04, 0.07, 0.26))
			c.draw_rect(hut, Color(0.78, 0.74, 0.66))
			c.draw_rect(Rect2(hut.position, Vector2(hut.size.x, 5.0)), Color(0.88, 0.85, 0.78))
		if (h >> 10) % 2 == 0:
			# a water tank on its stand, in the opposite corner
			var tc: Vector2 = cs[(corner + 2) % 4]
			var tp := Vector2(clampf(tc.x, fl.position.x + 12.0, fl.end.x - 12.0), clampf(tc.y, fl.position.y + 12.0, fl.end.y - 12.0))
			c.draw_circle(tp + Vector2(3.0, 4.0), 8.0, Color(0.05, 0.04, 0.07, 0.26))
			c.draw_circle(tp, 8.0, Color(0.80, 0.80, 0.78))
			c.draw_circle(tp - Vector2(2.0, 2.0), 3.5, Color(0.92, 0.92, 0.90))
		if (h >> 11) % 3 == 0 and fl.size.x > 50.0:
			# washing on the terrat too
			var wy := fl.position.y + fl.size.y * (0.40 + float((h >> 13) % 3) * 0.12)
			c.draw_line(Vector2(fl.position.x + 6.0, wy), Vector2(fl.end.x - 6.0, wy), Color(0.30, 0.28, 0.26), 1.0)
			var wx := fl.position.x + 12.0
			var k := 0
			while wx < fl.end.x - 16.0:
				c.draw_rect(Rect2(wx, wy, 9.0, 11.0), m.WASH_COLS[(h + k) % m.WASH_COLS.size()])
				wx += 14.0
				k += 1
		# pots of geraniums along one parapet
		var pots := (h >> 12) % 4
		var down: bool = (h >> 15) % 2 == 0
		for k in range(pots):
			var pp := Vector2(fl.position.x + 9.0, fl.position.y + 22.0 + float(k) * 13.0) if down \
				else Vector2(fl.position.x + 22.0 + float(k) * 13.0, fl.end.y - 9.0)
			if pp.x > fl.end.x - 10.0 or pp.y > fl.end.y - 10.0:
				break
			c.draw_circle(pp, 5.5, Color(0.62, 0.34, 0.22))
			c.draw_circle(pp, 4.2, Color(0.26, 0.44, 0.22) if k % 2 == 0 else Color(0.34, 0.50, 0.26))
			if k % 2 == 0:
				c.draw_circle(pp + Vector2(1.0, -1.0), 1.5, Color(0.88, 0.20, 0.24))
	elif kind < 95:
		# a courtyard: roofs round three sides of a well of shadow, and the
		# patio at its foot catching what light gets down there
		var tile: Color = TILE[(h >> 4) % TILE.size()]
		c.draw_rect(r, tile)
		var well := r.grow(-20.0)
		c.draw_rect(well, Color(0.26, 0.23, 0.21))
		c.draw_rect(Rect2(well.position + Vector2(8.0, 10.0), well.size - Vector2(8.0, 10.0)), Color(0.46, 0.42, 0.36))
		c.draw_line(Vector2(r.position.x, well.position.y - 10.0), Vector2(r.end.x, well.position.y - 10.0), tile.lightened(0.22), 2.0)
		c.draw_line(Vector2(r.position.x, well.end.y + 10.0), Vector2(r.end.x, well.end.y + 10.0), tile.darkened(0.22), 2.0)
		if (h >> 8) % 2 == 0:
			# a tree in the patio, its crown up in the light
			var tp := well.get_center() + Vector2(4.0, 4.0)
			c.draw_circle(tp, 15.0, Color(0.17, 0.30, 0.17))
			c.draw_circle(tp - Shade.light * 4.0, 10.0, Color(0.26, 0.42, 0.23))
		else:
			c.draw_circle(well.get_center() + Vector2(6.0, 6.0), 5.0, Color(0.62, 0.34, 0.22))
			c.draw_circle(well.get_center() + Vector2(6.0, 6.0), 3.8, Color(0.30, 0.46, 0.24))
	else:
		# a zinc roof, its seams running down it, and a light well beside
		var zinc := Color(0.50, 0.52, 0.54)
		c.draw_rect(r, zinc)
		var sx := r.position.x + 7.0
		while sx < r.end.x - 2.0:
			c.draw_line(Vector2(sx, r.position.y), Vector2(sx, r.end.y), zinc.lightened(0.16), 1.5)
			sx += 9.0
		c.draw_rect(Rect2(r.position.x + 8.0, r.end.y - 30.0, 22.0, 22.0), Color(0.18, 0.16, 0.15))
		c.draw_rect(Rect2(r.position.x + 8.0, r.end.y - 30.0, 22.0, 4.0), Color(0.10, 0.09, 0.09))


static func draw_bridge(b: ShapeBatch, by: float, e: Vector2) -> void:
	var span := e.y - e.x
	var cx := (e.x + e.y) * 0.5
	var r := Rect2(e.x - 30.0, by - 36.0, span + 60.0, 72.0)

	# Massive carved stone corbel brackets at both wall springers
	for side in [-1.0, 1.0]:
		var wx: float = e.x if side < 0.0 else e.y
		var dir := 1.0 if side < 0.0 else -1.0
		b.rect(Rect2(wx, by - 30.0, dir * 28.0, 60.0), Color(0.48, 0.44, 0.38))
		b.rect(Rect2(wx, by - 24.0, dir * 20.0, 48.0), Color(0.55, 0.50, 0.44))
		b.rect(Rect2(wx, by - 16.0, dir * 12.0, 32.0), Color(0.62, 0.57, 0.49))
		b.line(Vector2(wx + dir * 28.0, by - 30.0), Vector2(wx + dir * 28.0, by + 30.0), Color(0.68, 0.63, 0.55), 2.0)

	# Main bridge body & gallery (aged Montjuïc sandstone)
	b.rect(r, Color(0.54, 0.49, 0.42))
	# Roof ridge / top lead cap (lit)
	b.rect(Rect2(r.position.x, r.position.y, r.size.x, 8.0), Color(0.68, 0.62, 0.54))
	# Cornice shadow line
	b.line(Vector2(r.position.x, r.position.y + 8.0), Vector2(r.end.x, r.position.y + 8.0), Color(0.38, 0.34, 0.29), 2.0)
	# Bottom soffit molding (shaded)
	b.rect(Rect2(r.position.x, r.end.y - 8.0, r.size.x, 8.0), Color(0.40, 0.36, 0.31))
	b.line(Vector2(r.position.x, r.end.y), Vector2(r.end.x, r.end.y), Color(0.32, 0.28, 0.24), 2.0)

	# Crenellated Gothic balustrade along the top parapet
	var merlon_x := r.position.x + 10.0
	while merlon_x < r.end.x - 10.0:
		b.rect(Rect2(merlon_x, by - 40.0, 10.0, 6.0), Color(0.66, 0.60, 0.52))
		b.line(Vector2(merlon_x, by - 40.0), Vector2(merlon_x + 10.0, by - 40.0), Color(0.76, 0.70, 0.62), 1.5)
		merlon_x += 20.0

	# Neo-Gothic pointed-arch window bays across the gallery
	var n_bays := 5
	var bay_spacing := (span - 40.0) / float(n_bays - 1)
	for i in range(n_bays):
		var wx := (e.x + 20.0) + float(i) * bay_spacing
		var is_center := (i == n_bays / 2)
		var ww := 22.0 if is_center else 18.0
		var wh := 28.0
		# Stone hood mold arch surround
		b.rect(Rect2(wx - ww * 0.5 - 2.0, by - 16.0, ww + 4.0, wh + 2.0), Color(0.64, 0.58, 0.50))
		# Recessed dark window opening
		b.rect(Rect2(wx - ww * 0.5, by - 14.0, ww, wh), Color(0.18, 0.16, 0.14))
		# Pointed arch top
		var arch_pts := PackedVector2Array([
			Vector2(wx - ww * 0.5, by - 14.0),
			Vector2(wx, by - 25.0),
			Vector2(wx + ww * 0.5, by - 14.0)
		])
		b.polygon(arch_pts, Color(0.18, 0.16, 0.14))
		# Slender vertical stone mullions & tracery
		b.line(Vector2(wx, by - 20.0), Vector2(wx, by + 14.0), Color(0.55, 0.50, 0.44), 2.0)
		# Trefoil cusps in the arch head
		b.circle(Vector2(wx, by - 16.0), 2.5, Color(0.60, 0.55, 0.48))
		# Molded window sill
		b.rect(Rect2(wx - ww * 0.5 - 3.0, by + 14.0, ww + 6.0, 3.5), Color(0.70, 0.64, 0.56))

	# Central oriel projection pilasters
	b.line(Vector2(cx - 15.0, by - 36.0), Vector2(cx - 15.0, by + 28.0), Color(0.72, 0.66, 0.58), 2.0)
	b.line(Vector2(cx + 15.0, by - 36.0), Vector2(cx + 15.0, by + 28.0), Color(0.42, 0.38, 0.33), 2.0)

	# "El Crani i la Daga" (The Skull and Dagger) - Joan Rubió's famous 1928 detail
	var skull_p := Vector2(cx, by + 29.0)
	# Carved bone/limestone skull
	b.circle(skull_p, 3.8, Color(0.86, 0.83, 0.77))
	b.rect(Rect2(skull_p.x - 2.0, skull_p.y + 2.0, 4.0, 3.0), Color(0.82, 0.79, 0.73))
	# Eye sockets
	b.circle(skull_p + Vector2(-1.3, 0.2), 1.0, Color(0.20, 0.18, 0.16))
	b.circle(skull_p + Vector2(1.3, 0.2), 1.0, Color(0.20, 0.18, 0.16))
	# Dagger piercing through it
	b.line(skull_p + Vector2(0, -6.0), skull_p + Vector2(0, 8.0), Color(0.65, 0.68, 0.72), 1.5)
	b.line(skull_p + Vector2(-3.5, -4.5), skull_p + Vector2(3.5, -4.5), Color(0.35, 0.32, 0.28), 1.5)
	b.circle(skull_p + Vector2(0, -6.5), 1.2, Color(0.35, 0.32, 0.28))

	# Suspended wrought-iron Gothic street lantern
	var lant_y := by + 34.0
	# Iron bracket & chain
	b.line(Vector2(cx, by + 22.0), Vector2(cx, lant_y), Color(0.14, 0.13, 0.15), 2.0)
	b.line(Vector2(cx - 5.0, lant_y - 4.0), Vector2(cx + 5.0, lant_y - 4.0), Color(0.14, 0.13, 0.15), 1.5)
	# Lantern hood / canopy
	var hood_pts := PackedVector2Array([
		Vector2(cx - 8.0, lant_y + 3.0),
		Vector2(cx, lant_y),
		Vector2(cx + 8.0, lant_y + 3.0)
	])
	b.polygon(hood_pts, Color(0.18, 0.18, 0.20))
	# Glowing amber glass chamber
	b.rect(Rect2(cx - 6.5, lant_y + 3.0, 13.0, 14.0), Color(1.0, 0.84, 0.46))
	# Bright warm flame core
	b.circle(Vector2(cx, lant_y + 10.0), 3.2, Color(1.0, 0.98, 0.85))
	# Iron cage struts
	b.line(Vector2(cx - 6.5, lant_y + 3.0), Vector2(cx - 6.5, lant_y + 17.0), Color(0.14, 0.13, 0.15), 1.5)
	b.line(Vector2(cx, lant_y + 3.0), Vector2(cx, lant_y + 17.0), Color(0.14, 0.13, 0.15), 1.2)
	b.line(Vector2(cx + 6.5, lant_y + 3.0), Vector2(cx + 6.5, lant_y + 17.0), Color(0.14, 0.13, 0.15), 1.5)
	b.line(Vector2(cx - 7.5, lant_y + 17.0), Vector2(cx + 7.5, lant_y + 17.0), Color(0.14, 0.13, 0.15), 2.0)
	# Bottom finial drop
	b.circle(Vector2(cx, lant_y + 19.0), 1.8, Color(0.14, 0.13, 0.15))
