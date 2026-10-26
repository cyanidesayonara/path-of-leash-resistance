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
static func draw_street(m: Node2D, vt: float, vb: float) -> void:
	var b := ShapeBatch.new()
	var fp: Vector2 = LevelBuild.GOTIC_PLACA
	# setts, staggered, ruled inside the alley wherever it has jinked to
	var row := int(floorf((vt - 60.0) / 56.0))
	var ry := float(row) * 56.0
	while ry < vb + 60.0:
		var e0: Vector2 = m.walk_edges(ry)
		b.line(Vector2(e0.x, ry), Vector2(e0.y, ry), Color(0, 0, 0, 0.10), 2.0)
		var off := 32.0 if row % 2 == 0 else 0.0
		var rx := floorf(e0.x / 64.0) * 64.0 + off
		while rx < e0.y:
			if rx > e0.x:
				b.line(Vector2(rx, ry), Vector2(rx, ry + 56.0), Color(0, 0, 0, 0.10), 2.0)
			rx += 64.0
		# in narrow medieval alleys: a central stone drainage channel and iron grates
		if absf(ry - fp.y) > 340.0:
			var acx := (e0.x + e0.y) * 0.5
			b.line(Vector2(acx - 14.0, ry), Vector2(acx - 14.0, ry + 56.0), Color(0, 0, 0, 0.09), 1.5)
			b.line(Vector2(acx + 14.0, ry), Vector2(acx + 14.0, ry + 56.0), Color(0, 0, 0, 0.09), 1.5)
			if row % 6 == 0:
				b.rect(Rect2(acx - 10.0, ry + 16.0, 20.0, 24.0), Color(0.18, 0.18, 0.20))
				b.rect(Rect2(acx - 8.0, ry + 18.0, 16.0, 20.0), Color(0.10, 0.10, 0.12))
				for g in range(3):
					var gy := ry + 22.0 + float(g) * 5.0
					b.line(Vector2(acx - 7.0, gy), Vector2(acx + 7.0, gy), Color(0.28, 0.28, 0.30), 1.5)
		ry += 56.0
		row += 1

	# Plaça de Sant Felip Neri: radial stone paving, octagonal Baroque fountain, terracotta pots
	if fp.y > vt - 320.0 and fp.y < vb + 320.0:
		# radial stone sett ribs radiating from the octagonal fountain basin
		for k in range(8):
			var a := float(k) * TAU / 8.0 + PI / 8.0
			var v := Vector2.from_angle(a)
			b.line(fp + v * 44.0, fp + v * 230.0, Color(0, 0, 0, 0.13), 2.5)
		# concentric circular cobblestone joints
		for r_sett in [72.0, 108.0, 148.0, 192.0, 235.0]:
			for seg in range(32):
				var a0 := float(seg) * TAU / 32.0
				var a1 := float(seg + 1) * TAU / 32.0
				b.line(fp + Vector2.from_angle(a0) * r_sett, fp + Vector2.from_angle(a1) * r_sett, Color(0, 0, 0, 0.08), 1.8)

		# the octagonal Baroque stone fountain
		var pts_sh := PackedVector2Array()
		var pts_plinth := PackedVector2Array()
		var pts_rim := PackedVector2Array()
		var pts_water := PackedVector2Array()
		for i in range(8):
			var ang := float(i) * TAU / 8.0 + PI / 8.0
			var dir := Vector2.from_angle(ang)
			pts_sh.append(fp + m.LIGHT * 10.0 + dir * 44.0)
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
			var col := Color(0.78, 0.74, 0.67) if mid_n.dot(-m.LIGHT) > 0.0 else Color(0.46, 0.42, 0.36)
			b.line(p0, p1, col, 2.0)
		b.polygon(pts_water, Color(0.28, 0.46, 0.54))
		# water sky reflection & ripples
		b.circle(fp + Vector2(-8, -8), 13.0, Color(0.44, 0.62, 0.70, 0.6))
		b.circle(fp, 20.0, Color(0.34, 0.52, 0.60, 0.35))
		b.circle(fp, 13.0, Color(0.38, 0.56, 0.64, 0.3))
		# central Baroque baluster pedestal & spouts
		b.circle(fp + m.LIGHT * 3.0, 10.0, Color(0.20, 0.32, 0.38, 0.5))
		b.circle(fp, 9.5, Color(0.56, 0.52, 0.46))
		b.circle(fp - m.LIGHT * 1.5, 7.0, Color(0.68, 0.64, 0.58))
		b.circle(fp - m.LIGHT * 2.5, 4.0, Color(0.78, 0.74, 0.68))
		for s in range(4):
			var sdir := Vector2.from_angle(float(s) * TAU / 4.0)
			b.line(fp + sdir * 4.0, fp + sdir * 11.0, Color(0.44, 0.40, 0.30), 2.0)
			b.circle(fp + sdir * 16.0, 2.2, Color(0.85, 0.95, 1.0, 0.75))
			b.circle(fp + sdir * 16.0, 4.0, Color(0.48, 0.66, 0.74, 0.4))

	# doorway and square terracotta flowerpots with geraniums
	_draw_pots(m, b, vt, vb, fp)

	var sy: float = LevelBuild.GOTIC_STEPS_Y
	if sy > vt - 80.0 and sy < vb + 80.0:
		for k in range(5):
			var yy := sy + float(k) * 12.0
			var e: Vector2 = m.walk_edges(yy)
			b.rect(Rect2(e.x, yy, e.y - e.x, 12.0), Color(0.58, 0.54, 0.48).darkened(0.05 * float(k)))
			b.line(Vector2(e.x, yy), Vector2(e.y, yy), Color(0.72, 0.68, 0.62), 2.0)
	m._draw_scooters(b, vt, vb)

	# Pont del Bisbe: arched shadow cast onto the alley with corbel tabs and warm lantern pool
	var by: float = LevelBuild.GOTIC_BRIDGE_Y
	if by > vt - 120.0 and by < vb + 120.0:
		var e2: Vector2 = m.walk_edges(by)
		var cx := (e2.x + e2.y) * 0.5
		b.rect(Rect2(e2.x, by + 16.0, e2.y - e2.x, 68.0), Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.24))
		b.rect(Rect2(e2.x, by + 10.0, 26.0, 78.0), Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.28))
		b.rect(Rect2(e2.y - 26.0, by + 10.0, 26.0, 78.0), Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.28))
		b.rect(Rect2(e2.x, by + 84.0, e2.y - e2.x, 8.0), Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.12))
		# warm amber pool of light from the bridge lantern overhead
		b.circle(Vector2(cx, by + 46.0), 56.0, Color(1.0, 0.82, 0.40, 0.08))
		b.circle(Vector2(cx, by + 46.0), 38.0, Color(1.0, 0.86, 0.48, 0.12))
		b.circle(Vector2(cx, by + 46.0), 22.0, Color(1.0, 0.90, 0.58, 0.16))
		b.circle(Vector2(cx, by + 46.0), 10.0, Color(1.0, 0.95, 0.70, 0.22))
	b.flush(m._wc)


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
	]
	for pp in pots:
		if pp.y < vt - 30.0 or pp.y > vb + 30.0:
			continue
		b.circle(pp + m.LIGHT * 4.0, 8.0, Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.22))
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
			c.draw_circle(tp - m.LIGHT * 4.0, 10.0, Color(0.26, 0.42, 0.23))
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
