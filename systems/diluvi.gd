class_name Diluvi
extends RefCounted

# WALK: EL DILUVI (the downpour). Its drawing as static functions over main's
# state (main.WALK_MODULES): the gutters and drains down the street, the
# cafe's terrace stacked and chained in the rain, the arcade's square
# pillars, and El Porxo past the gate - the porch, its pantile roofs and the
# terrats beyond. The wet meter itself (main._tick_wet) and the shelters
# stay in main: they are the walk's rules, not its picture.

const ShapeBatch := preload("res://systems/shape_batch.gd")
const LevelBuild := preload("res://world/level_build.gd")

# EL DILUVI: the arcade (a roof behind its pillars, arches between), the
# awnings, the gutters running down both sides, and the owner's wet meter.
static func _draw_street(m: Node2D, vt: float, vb: float) -> void:
	var b := ShapeBatch.new()
	var t := AnimClock.msec() / 1000.0
	# the gutters, running along curbs with storm drain grates and vortexes
	var gy := floorf((vt - 60.0) / 46.0) * 46.0
	while gy < vb + 60.0:
		var ge: Vector2 = m.walk_edges(gy)
		for gx: float in [ge.x + 6.0, ge.y - 6.0]:
			b.rect(Rect2(gx - 4.0, gy, 8.0, 46.0), Color(0.30, 0.36, 0.42))
			var fl := fmod(gy + t * 90.0, 46.0)
			b.line(Vector2(gx, gy + fl), Vector2(gx, gy + fl + 12.0), Color(0.75, 0.84, 0.92, 0.6), 2.0)
			if int(absf(gy)) % 184 < 46:
				# curbside iron slot grate and whirlpool drain
				b.rect(Rect2(gx - 5.0, gy + 10.0, 10.0, 26.0), Color(0.18, 0.20, 0.22))
				for gi: int in range(4):
					b.line(Vector2(gx - 3.5, gy + 14.0 + float(gi) * 5.0), Vector2(gx + 3.5, gy + 14.0 + float(gi) * 5.0), Color(0.10, 0.10, 0.12), 2.0)
				var wph := fmod(t * 2.2 + absf(gy) * 0.1, 1.0)
				b.circle(Vector2(gx, gy + 23.0), 2.5 + wph * 4.5, Color(0.72, 0.84, 0.94, 0.38 * (1.0 - wph)))
		gy += 46.0

	# expanding raindrop impact ripple rings across puddles
	for pt: Dictionary in m.patches:
		if String(pt.get("kind", "")) != "puddle":
			continue
		var pc: Vector2 = m.patch_centre(pt)
		if pc.y < vt - 60.0 or pc.y > vb + 60.0:
			continue
		var prx: float = float(pt.get("rx", 30.0))
		for ri: int in range(3):
			var rph := fmod(t * 1.6 + float(ri) * 0.33 + pc.x * 0.05, 1.0)
			var roff := Vector2(sin(float(ri) * 2.4 + pc.y) * prx * 0.4, cos(float(ri) * 2.1) * 8.0)
			b.circle(pc + roff, 3.0 + rph * 14.0, Color(0.85, 0.92, 0.98, 0.35 * (1.0 - rph)))
			b.circle(pc + roff, 1.5, Color(1.0, 1.0, 1.0, 0.55 * (1.0 - rph)))
	# the awnings and the arcade's roof are overhead (draw_overhead_piece):
	# here the shade each throws on the paving
	for i in range(1, m.shelters.size()):
		var r: Rect2 = m.shelters[i]
		if r.end.y < vt - 40.0 or r.position.y > vb + 40.0:
			continue
		b.rect(Rect2(r.position + Vector2(-8, 10), r.size), Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.18))
	if not m.shelters.is_empty():
		var ar: Rect2 = m.shelters[0]
		if ar.end.y > vt - 40.0 and ar.position.y < vb + 40.0:
			var y0 := maxf(ar.position.y, vt - 40.0)
			var y1 := minf(ar.end.y, vb + 40.0)
			b.rect(Rect2(ar.position.x, y0, ar.size.x, y1 - y0), Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.25))
	# the striped boards fenced along each side of an open storm drain (its
	# cones, end on to the way the street walks, are real nodes: spawn_cones)
	var bd: Vector2 = LevelBuild.DILUVI_DRAIN_BOARD
	for mh: Vector2 in m.manholes:
		if mh.y < vt - 80.0 or mh.y > vb + 80.0:
			continue
		for sx: float in [-1.0, 1.0]:
			_drain_board(m, b, mh + Vector2(sx * bd.y, 0.0), bd.x)
	var tr: Rect2 = LevelBuild.diluvi_terrace(m)
	if tr.end.y > vt - 60.0 and tr.position.y < vb + 60.0:
		_stacked_terrace(m, b, tr, t)
	# how wet the owner is, a drip meter over their head once it shows
	if m.human_soak > 0.08:
		var hp: Vector2 = m.human.global_position + Vector2(-16.0, -40.0)
		b.rect(Rect2(hp.x, hp.y, 32.0, 5.0), Color(0.08, 0.08, 0.10, 0.7))
		b.rect(Rect2(hp.x, hp.y, 32.0 * m.human_soak, 5.0), Color(0.45, 0.65, 0.95) if m.human_soak < 0.5 else Color(0.30, 0.45, 0.85))
	b.flush(m._wc)


# a street-works board beside an open drain: a red and white striped plank,
# running along the street, on two black feet, wet
static func _drain_board(m: Node2D, b: ShapeBatch, c: Vector2, hh: float) -> void:
	b.rect(Rect2(c.x - 1.0, c.y - hh + 4.0, 8.0, hh * 2.0), Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.22))
	for fy: float in [-hh + 4.0, hh - 4.0]:
		b.rect(Rect2(c.x - 7.0, c.y + fy - 3.0, 14.0, 6.0), Color(0.14, 0.14, 0.15))
	b.rect(Rect2(c.x - 3.5, c.y - hh, 7.0, hh * 2.0), Color(0.94, 0.92, 0.88))
	var sy := c.y - hh
	while sy < c.y + hh - 2.0:
		b.polygon(PackedVector2Array([Vector2(c.x - 3.5, sy + 5.0), Vector2(c.x + 3.5, sy),
			Vector2(c.x + 3.5, minf(sy + 5.0, c.y + hh)), Vector2(c.x - 3.5, minf(sy + 10.0, c.y + hh))]),
			Color(0.86, 0.18, 0.16))
		sy += 10.0
	b.line(Vector2(c.x - 2.5, c.y - hh), Vector2(c.x - 2.5, c.y + hh), Color(1, 1, 1, 0.30), 1.0)


# The cafe's terrace in the rain: two stacks of bistro chairs, the folded
# tables leaned behind them, all of it chained to the lamp standard with a
# padlock on the chain. Water stands on the top seats.
static func _stacked_terrace(m: Node2D, b: ShapeBatch, r: Rect2, t: float) -> void:
	b.rect(Rect2(r.position + m.LIGHT * 7.0, r.size), Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.26))
	# the folded tables, wrapped in a blue waterproof vinyl tarpaulin
	var tp := Rect2(r.end.x - 9.0, r.position.y + 2.0, 8.0, r.size.y - 4.0)
	b.rect(tp, Color(0.18, 0.38, 0.65))
	b.rect(Rect2(tp.position.x, tp.position.y, 2.5, tp.size.y), Color(0.28, 0.50, 0.80))
	for ey: float in [tp.position.y + 4.0, tp.end.y - 4.0]:
		b.circle(Vector2(tp.position.x + 3.0, ey), 1.2, Color(0.88, 0.78, 0.35))
	for k in range(2):
		var tx := r.end.x - 6.0 + float(k) * 3.0
		b.rect(Rect2(tx, r.position.y + 4.0 + float(k) * 3.0, 2.5, r.size.y - 8.0), Color(0.48, 0.50, 0.52))
	# two stacks of bistro chairs, rattan seats on bent cane frames, each one
	# stepped off the one below so every back shows; splayed legs at the foot
	var cane := Color(0.62, 0.44, 0.26)
	var weave := Color(0.80, 0.66, 0.44)
	for s in range(2):
		var base := Vector2(r.position.x + 1.0, r.position.y + 6.0 + float(s) * (r.size.y * 0.5))
		for lg: Vector2 in [Vector2(-1, -1), Vector2(17, -1), Vector2(-1, 17), Vector2(17, 17)]:
			b.circle(base + lg, 1.8, cane.darkened(0.35))
		for n in range(4):
			var sr := Rect2(base + Vector2(float(n) * 2.5, float(n) * -2.5), Vector2(16.0, 16.0))
			b.rect(Rect2(sr.position + Vector2(1.0, 1.5), sr.size), cane.darkened(0.55))
			b.rect(sr, cane.darkened(0.08 * float(3 - n)))
			b.rect(sr.grow(-2.5), weave.darkened(0.10 * float(3 - n)))
			# the back: a bent cane rail on the shopfront side
			b.rect(Rect2(sr.end.x - 1.0, sr.position.y - 1.0, 4.0, sr.size.y + 2.0), cane.darkened(0.25))
			b.rect(Rect2(sr.end.x - 1.0, sr.position.y - 1.0, 1.5, sr.size.y + 2.0), cane.lightened(0.25))
		var top := Rect2(base + Vector2(7.5, -7.5), Vector2(16.0, 16.0)).grow(-2.5)
		var wy := top.position.y + 2.0
		while wy < top.end.y:
			b.line(Vector2(top.position.x, wy), Vector2(top.end.x, wy), cane.darkened(0.15), 1.0)
			wy += 3.0
		# rain standing on the top seat, ringed by the drops landing in it
		var pud := top.get_center() + Vector2(-1.0, 1.0)
		b.circle(pud, 3.6, Color(0.50, 0.60, 0.72, 0.75))
		var ring := fmod(t * 1.3 + float(s) * 0.5, 1.0)
		b.circle(pud, 1.0 + ring * 3.0, Color(0.85, 0.92, 1.0, 0.5 * (1.0 - ring)))
	# the chain: round both stacks and up to the lamp standard, links in a row
	var lamp := Vector2(r.end.x - 10.0, LevelBuild.DILUVI_TERRACE_Y - 45.0)   # the pole, 26 in from the edge
	var path: Array[Vector2] = [lamp, Vector2(r.position.x + 1.0, r.position.y + 1.0),
		Vector2(r.position.x + 1.0, r.end.y - 1.0), Vector2(r.end.x - 9.0, r.end.y - 1.0),
		Vector2(r.end.x - 9.0, r.position.y + 6.0), lamp]
	var steel := Color(0.30, 0.31, 0.33)
	for k in range(path.size() - 1):
		var a: Vector2 = path[k]
		var z: Vector2 = path[k + 1]
		var n := int(a.distance_to(z) / 4.0)
		for li in range(n):
			b.circle(a.lerp(z, (float(li) + 0.5) / float(n)), 1.6 if li % 2 == 0 else 1.2, steel if li % 2 == 0 else steel.lightened(0.25))
	# the padlock where the ends meet
	var pl := Vector2(r.position.x + 1.0, r.end.y - 4.0)
	b.rect(Rect2(pl.x - 4.0, pl.y - 2.0, 8.0, 7.0), Color(0.74, 0.60, 0.24))
	b.rect(Rect2(pl.x - 4.0, pl.y - 2.0, 8.0, 2.0), Color(0.90, 0.78, 0.40))


static func _draw_porxo(m: Node2D, c: Object) -> void:
	var r: Rect2 = m._freedom_rect()
	# the freedom layer hands over a ShapeBatch already
	var b: ShapeBatch = c if c is ShapeBatch else ShapeBatch.new(c)
	# the court: wet sauló, darker where the rain pools
	var court := Color(0.62, 0.53, 0.40)
	b.rect(r, court)
	for gi in range(120):
		var gp := Vector2(r.position.x + fmod(float(gi) * 197.0, r.size.x), r.position.y + fmod(float(gi) * 331.0, r.size.y))
		b.circle(gp, 1.5, court.darkened(0.20))
	b.circle(r.get_center() + Vector2(30.0, 40.0), 160.0, Color(0.40, 0.36, 0.30, 0.35))
	for pd: Array in [[Vector2(0.30, 0.55), 46.0, 24.0], [Vector2(0.58, 0.60), 60.0, 30.0], [Vector2(0.48, 0.80), 38.0, 20.0], [Vector2(0.78, 0.70), 50.0, 26.0]]:
		var pc: Vector2 = r.position + r.size * (pd[0] as Vector2)
		b.polygon(m.ellipse_pts(pc, float(pd[1]) + 5.0, float(pd[2]) + 4.0, 14), court.darkened(0.22))
		b.polygon(m.ellipse_pts(pc, float(pd[1]), float(pd[2]), 14), Color(0.42, 0.50, 0.58, 0.85))
		b.polygon(m.ellipse_pts(pc + Vector2(-float(pd[1]) * 0.3, -float(pd[2]) * 0.3), float(pd[1]) * 0.35, float(pd[2]) * 0.25, 10), Color(0.80, 0.86, 0.94, 0.22))
	# the porch floors: west, north and east, terracotta tile in shade
	var floor_col := Color(0.62, 0.40, 0.30)
	var porches: Array[Rect2] = [
		Rect2(r.position.x, r.position.y, m.PORXO_W, r.size.y),
		Rect2(r.position.x, r.position.y, r.size.x, m.PORXO_W),
		Rect2(r.end.x - m.PORXO_W, r.position.y, m.PORXO_W, r.size.y),
	]
	for pr: Rect2 in porches:
		b.rect(pr, floor_col)
	for pr: Rect2 in porches:
		var tx := pr.position.x + 24.0
		while tx < pr.end.x:
			b.line(Vector2(tx, pr.position.y), Vector2(tx, pr.end.y), floor_col.darkened(0.16), 1.0)
			tx += 24.0
		var ty := pr.position.y + 24.0
		while ty < pr.end.y:
			b.line(Vector2(pr.position.x, ty), Vector2(pr.end.x, ty), floor_col.darkened(0.16), 1.0)
			ty += 24.0
	# the roof's shade over the porch, deepest against the wall
	for pr: Rect2 in porches:
		b.rect(pr, Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.22))
	b.rect(Rect2(r.position.x, r.position.y, r.size.x, 26.0), Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.18))
	b.rect(Rect2(r.position.x, r.position.y, 26.0, r.size.y), Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.18))
	b.rect(Rect2(r.end.x - 26.0, r.position.y, 26.0, r.size.y), Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.18))
	# the drip line: a dark wet edge where the eave sheds onto the court
	var ix0: float = r.position.x + m.PORXO_W
	var ix1: float = r.end.x - m.PORXO_W
	var iy0: float = r.position.y + m.PORXO_W
	b.rect(Rect2(ix0, iy0, ix1 - ix0, 6.0), court.darkened(0.30))
	b.rect(Rect2(ix0, iy0, 6.0, r.end.y - iy0), court.darkened(0.30))
	b.rect(Rect2(ix1 - 6.0, iy0, 6.0, r.end.y - iy0), court.darkened(0.30))
	# the columns along the porch's open edge, each on its square base
	var cols: Array[Vector2] = []
	var cx := ix0
	while cx <= ix1 + 1.0:
		cols.append(Vector2(cx, iy0))
		cx += (ix1 - ix0) / roundf((ix1 - ix0) / m.PORXO_BAY)
	var cy: float = iy0 + m.PORXO_BAY
	while cy < r.end.y - 30.0:
		cols.append(Vector2(ix0, cy))
		cols.append(Vector2(ix1, cy))
		cy += m.PORXO_BAY
	for cp: Vector2 in cols:
		b.circle(cp + m.LIGHT * 9.0, 12.0, Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.30))
		b.rect(Rect2(cp - Vector2(13, 13), Vector2(26, 26)), Color(0.64, 0.60, 0.54))
		b.circle(cp, 10.0, Color(0.76, 0.72, 0.66))
		b.circle(cp - m.LIGHT * 2.5, 6.5, Color(0.84, 0.81, 0.76))
	# the walls round the yard, open at the gate
	var wall := Color(0.60, 0.54, 0.46)
	b.rect(Rect2(r.position.x - 10.0, r.position.y - 10.0, r.size.x + 20.0, 10.0), wall)
	b.rect(Rect2(r.position.x - 10.0, r.position.y, 10.0, r.size.y + 10.0), wall)
	b.rect(Rect2(r.end.x, r.position.y, 10.0, r.size.y + 10.0), wall)
	b.rect(Rect2(r.position.x - 10.0, r.end.y, m.gate_l - 20.0 - r.position.x + 10.0, 10.0), wall)
	b.rect(Rect2(m.gate_r + 20.0, r.end.y, r.end.x + 10.0 - m.gate_r - 20.0, 10.0), wall)
	b.rect(Rect2(r.position.x - 10.0, r.position.y - 10.0, r.size.x + 20.0, 3.0), wall.lightened(0.18))
	# a downpipe in each corner of the court, spouting onto a splash stone
	for dp: Vector2 in [Vector2(ix0 + 10.0, iy0 + 10.0), Vector2(ix1 - 10.0, iy0 + 10.0)]:
		b.rect(Rect2(dp - Vector2(10, 7), Vector2(20, 14)), Color(0.66, 0.62, 0.56))
		b.circle(dp, 4.0, Color(0.48, 0.52, 0.56))
		b.circle(dp + Vector2(0, 8), 7.0, Color(0.50, 0.60, 0.70, 0.6))
	if b != c:
		b.flush()
	m._draw_freedom_benches(c, r, Color(0.46, 0.34, 0.24))
	m._freedom_sign(c, r, m.gate_text, "the covered yard, off leash")


# --- main's walk hooks (main.WALK_MODULES) ---------------------------------------

# the street, up to the gate
static func draw_live(m: Node2D, _wc: ShapeBatch, vt: float, vb: float) -> void:
	_draw_street(m, maxf(vt, m.GATE_Y - 30.0), vb)


# El Porxo, past the gate
static func draw_freedom_ground(m: Node2D, c: Object) -> void:
	_draw_porxo(m, c)


# El Porxo's porch roofs past its walls, wet pantile, and the block's
# terrats beyond
static func draw_freedom_beyond(m: Node2D, c: Object) -> void:
	var r: Rect2 = m._freedom_rect()
	var top := r.position.y
	var b := ShapeBatch.new()
	b.rect(Rect2(-400.0, top - 400.0, 2100.0, 390.0), Color(0.38, 0.35, 0.37))
	var bays: Array[Rect2] = [Rect2(-400.0, top - 110.0, 2100.0, 100.0),
		Rect2(-400.0, top - 10.0, 470.0, r.size.y + 40.0), Rect2(r.end.x + 10.0, top - 10.0, 520.0, r.size.y + 40.0)]
	for k in range(bays.size()):
		var bay: Rect2 = bays[k]
		var tile := Color(0.50, 0.29, 0.21)
		b.rect(bay, tile)
		if k == 0:
			var ty := bay.position.y + 4.0
			while ty < bay.end.y:
				b.line(Vector2(bay.position.x, ty), Vector2(bay.end.x, ty), tile.darkened(0.28), 2.0)
				ty += 9.0
		else:
			var tx := bay.position.x + 4.0
			while tx < bay.end.x:
				b.line(Vector2(tx, bay.position.y), Vector2(tx, bay.end.y), tile.darkened(0.28), 2.0)
				tx += 9.0
	for k in range(9):
		var tp := Vector2(-300.0 + float(k) * 240.0, top - 260.0 + fmod(float(k) * 53.0, 80.0))
		b.circle(tp + m.LIGHT * 10.0, 16.0, Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.3))
		b.circle(tp, 15.0, Color(0.80, 0.80, 0.78))
		b.circle(tp, 6.0, Color(0.56, 0.58, 0.60))
	b.flush(c)


# the arcade's pillars down the west side; lampposts down the east
static func draw_column(m: Node2D, wc: ShapeBatch, p: Vector2) -> void:
	if p.x >= m.walk_cx:
		m._draw_lamppost(p)
		return
	m.cast_shadow(wc, p, 12.0, 30.0, 0.2)
	wc.draw_rect(Rect2(p.x - 11.0, p.y - 11.0, 22.0, 22.0), Color(0.55, 0.50, 0.45))
	wc.draw_rect(Rect2(p.x - 11.0, p.y - 11.0, 8.0, 22.0), Color(0.64, 0.59, 0.53))
