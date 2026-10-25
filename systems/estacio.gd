class_name Estacio
extends RefCounted

# WALK 9: L'ESTACIO (a Rodalies station). Its drawing as static functions over
# main's state (main.WALK_MODULES): the concourse and its terrazzo, the ticket
# gates, the departures board, the platforms and the train, the luggage and
# trolleys, the hall's pillars, the goods yard off leash and the running lines
# past its wall.

const ShapeBatch := preload("res://systems/shape_batch.gd")

# L'Estacio's floor and fittings
const TERRAZZO := Color(0.72, 0.73, 0.74)
const BRASS := Color(0.70, 0.56, 0.30, 0.55)
const CHIPS: Array[Color] = [Color(0.42, 0.40, 0.38, 0.55), Color(0.62, 0.40, 0.32, 0.45),
	Color(0.95, 0.94, 0.90, 0.6), Color(0.30, 0.34, 0.36, 0.45)]
const LUGGAGE_COLS: Array[Color] = [Color(0.20, 0.45, 0.82), Color(0.82, 0.22, 0.24),
	Color(0.92, 0.70, 0.16), Color(0.18, 0.65, 0.45)]
# The departures board's rows, amber dot-matrix on black: time, where to and
# the platform, the way Rodalies boards read. One train is always cancelled.
const DEPARTURES := [["10:42", "SITGES", "4"], ["10:47", "MATARÓ", "CANCEL·LAT"],
	["10:55", "GIRONA", "2"], ["11:03", "VIC", "5"]]


# L'ESTACIO: the concourse floor's big tiles, the departures board, the
# barrier cabinets, the platform edges and the train standing between them.
static func _draw_concourse(m: Node2D, vt: float, vb: float) -> void:
	var b := ShapeBatch.new()
	# polished terrazzo in big square panels: brass divider strips between
	# them, the marble chips set in each, and the roof lights' reflections
	# lying across the polish
	var ty := floorf((vt - 60.0) / 132.0) * 132.0
	while ty < vb + 60.0:
		var e: Vector2 = m.walk_edges(ty)
		b.line(Vector2(e.x, ty), Vector2(e.y, ty), BRASS, 2.0)
		var tx := floorf(e.x / 132.0) * 132.0 + 132.0
		while tx < e.y:
			b.line(Vector2(tx, ty), Vector2(tx, ty + 132.0), BRASS, 2.0)
			tx += 132.0
		# the chips, hashed from the panel so the floor stays put
		var cx := floorf(e.x / 132.0) * 132.0
		while cx < e.y:
			for k in range(9):
				var h := int(absf(sin(cx * 0.131 + ty * 0.071 + float(k) * 12.9898) * 43758.5453))
				var cp := Vector2(cx + float(h % 128) + 2.0, ty + float((h / 128) % 128) + 2.0)
				if cp.x > e.x + 3.0 and cp.x < e.y - 6.0:
					b.rect(Rect2(cp, Vector2(3.0 + float(h % 3), 2.0 + float(h % 2))), CHIPS[h % CHIPS.size()])
			cx += 132.0
		ty += 132.0
	var ry := floorf((vt - 200.0) / 396.0) * 396.0
	while ry < vb + 200.0:
		var re: Vector2 = m.walk_edges(ry)
		var rx := re.x + 60.0 + fmod(absf(ry) * 0.37, 120.0)
		b.polygon(PackedVector2Array([Vector2(rx, ry), Vector2(rx + 70.0, ry), Vector2(rx + 150.0, ry + 140.0),
			Vector2(rx + 80.0, ry + 140.0)]), Color(1, 1, 1, 0.10))
		ry += 396.0
	# the departures board, hung over the way in: overhead
	# (draw_overhead_piece), and here its shadow on the floor
	var bd: Vector2 = m.LevelBuild.ESTACIO_BOARD
	if bd.y > vt - 80.0 and bd.y < vb + 80.0:
		b.rect(Rect2(bd.x - 154.0 + 10.0, bd.y - 38.0 + 16.0, 308.0, 76.0), Color(0, 0, 0, 0.18))
	# the ticket barriers: a row of steel gate cabinets, each with its black
	# glass top, the card reader and the light; at each gap the glass paddles
	# swung open toward the platforms
	var by: float = m.LevelBuild.ESTACIO_BARRIER_Y
	if by > vt - 60.0 and by < vb + 60.0:
		for i in range(m.deco_pole_count):
			var p: Vector2 = m.poles[i]
			if absf(p.y - by) < 1.0:
				_gate_cabinet(m, b, p)
		for g: float in m.LevelBuild.ESTACIO_GAPS:
			var hw: float = m.LevelBuild.ESTACIO_GAP_W * 0.5
			# a yellow line across the floor of each gap, where you tap
			b.rect(Rect2(g - hw + 6.0, by + 22.0, hw * 2.0 - 12.0, 3.0), Color(0.95, 0.80, 0.20, 0.8))
			for sx: float in [-1.0, 1.0]:
				var hinge := Vector2(g + sx * (hw - 12.0), by - 4.0)
				var tip := hinge + Vector2(-sx * 6.0, -24.0)
				var n := Vector2(sx * 3.0, 0.0)
				b.polygon(PackedVector2Array([hinge, tip, tip + n, hinge + n]), Color(0.70, 0.84, 0.95, 0.65))
				b.line(hinge, tip, Color(0.88, 0.94, 1.0, 0.9), 1.2)
	# the train, the track pit between platforms, and tactile blister warning paving
	var tr: Rect2 = m.LevelBuild.ESTACIO_TRAIN
	if tr.end.y > vt - 40.0 and tr.position.y < vb + 40.0:
		var py0 := maxf(tr.position.y - 40.0, vt - 40.0)
		var py1 := minf(tr.end.y + 40.0, vb + 40.0)
		# the track bed pit between the two platform copings
		b.rect(Rect2(tr.position.x - 14.0, py0, tr.size.x + 28.0, py1 - py0), Color(0.18, 0.17, 0.16))
		# running rails in the track pit under the train
		for rx: float in [tr.position.x + 10.0, tr.end.x - 14.0]:
			b.rect(Rect2(rx, py0, 4.0, py1 - py0), Color(0.44, 0.46, 0.50))
			b.rect(Rect2(rx + 1.0, py0, 2.0, py1 - py0), Color(0.68, 0.70, 0.74))
		# the concrete platform copings and yellow tactile warning bands
		for ex: Array in [[tr.position.x - 14.0, -1.0], [tr.end.x + 14.0, 1.0]]:
			var px: float = ex[0]
			var side: float = ex[1]
			var cx0: float = px - 6.0 if side < 0.0 else px
			b.rect(Rect2(cx0, py0, 6.0, py1 - py0), Color(0.56, 0.58, 0.60))
			b.line(Vector2(px, py0), Vector2(px, py1), Color(0.38, 0.40, 0.42), 1.5)
			var bx0: float = cx0 - 10.0 if side < 0.0 else cx0 + 6.0
			b.rect(Rect2(bx0, py0, 10.0, py1 - py0), Color(0.95, 0.80, 0.20))
			var py_stud := floorf(py0 / 14.0) * 14.0
			while py_stud < py1:
				if py_stud >= py0:
					b.circle(Vector2(bx0 + 5.0, py_stud + 7.0), 1.8, Color(1.0, 0.92, 0.45))
				py_stud += 14.0
		b.rect(Rect2(tr.position + Vector2(10, 14), tr.size), Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.22))
		_train(m, b, tr, vt, vb)
	# the concourse luggage: colourful hard-shell rolling suitcases
	for i in range(m.LevelBuild.ESTACIO_LUGGAGE.size()):
		var lp: Vector2 = m.LevelBuild.ESTACIO_LUGGAGE[i]
		if lp.y > vt - 40.0 and lp.y < vb + 40.0:
			var lcol: Color = LUGGAGE_COLS[i % LUGGAGE_COLS.size()]
			_suitcase(m, b, lp, lcol)
	b.flush(m._wc)


static func _suitcase(m: Node2D, b: ShapeBatch, p: Vector2, col: Color) -> void:
	b.rect(Rect2(p - Vector2(10, 14) + m.LIGHT * 4.0, Vector2(20, 28)), Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.20))
	b.rect(Rect2(p - Vector2(10, 14), Vector2(20, 28)), col)
	b.rect(Rect2(p - Vector2(10, 14), Vector2(3, 28)), col.lightened(0.25))
	b.line(Vector2(p.x, p.y - 12), Vector2(p.x, p.y + 12), Color(0.12, 0.12, 0.14), 1.5)
	# telescoping handle
	b.line(Vector2(p.x - 4, p.y - 14), Vector2(p.x - 4, p.y - 20), Color(0.25, 0.25, 0.28), 1.5)
	b.line(Vector2(p.x + 4, p.y - 14), Vector2(p.x + 4, p.y - 20), Color(0.25, 0.25, 0.28), 1.5)
	b.line(Vector2(p.x - 5, p.y - 20), Vector2(p.x + 5, p.y - 20), Color(0.12, 0.12, 0.14), 2.2)
	# wheels
	b.circle(p + Vector2(-8, 14), 2.0, Color(0.15, 0.15, 0.18))
	b.circle(p + Vector2(8, 14), 2.0, Color(0.15, 0.15, 0.18))


# one ticket gate cabinet from above: the stainless body with a lit edge, the
# black glass top, the card reader (a yellow ring round the tap pad) and the
# green arrow light toward the platforms
static func _gate_cabinet(m: Node2D, b: ShapeBatch, p: Vector2) -> void:
	b.rect(Rect2(p.x - 11.0, p.y - 16.0, 26.0, 38.0), Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.25))
	b.rect(Rect2(p.x - 12.0, p.y - 19.0, 24.0, 38.0), Color(0.56, 0.58, 0.62))
	b.rect(Rect2(p.x - 12.0, p.y - 19.0, 3.0, 38.0), Color(0.80, 0.82, 0.86))
	b.rect(Rect2(p.x - 8.0, p.y - 15.0, 16.0, 30.0), Color(0.12, 0.13, 0.15))
	b.circle(p + Vector2(0, 6), 5.5, Color(0.96, 0.78, 0.16))
	b.circle(p + Vector2(0, 6), 3.5, Color(0.18, 0.18, 0.20))
	b.polygon(PackedVector2Array([p + Vector2(0, -13), p + Vector2(4, -7), p + Vector2(-4, -7)]), Color(0.30, 0.90, 0.42))


# The train between the platforms, from above: a Rodalies unit's dark grey
# roof with the white and red livery showing down its sides, the roof gear
# (air-conditioning pods, a pantograph on every other car), black gangway
# bellows between the cars and the cab's raked windscreen at the front
static func _train(m: Node2D, b: ShapeBatch, tr: Rect2, vt: float, vb: float) -> void:
	var cy := tr.position.y
	var n := 0
	while cy < tr.end.y - 10.0:
		var car := Rect2(tr.position.x, cy, tr.size.x, minf(230.0, tr.end.y - cy))
		if car.end.y > vt - 40.0 and car.position.y < vb + 40.0:
			b.rect(car, Color(0.94, 0.94, 0.95))
			b.rect(Rect2(car.end.x - 12.0, car.position.y, 8.0, car.size.y), Color(0.76, 0.14, 0.16))
			b.rect(Rect2(car.position.x + 4.0, car.position.y, 8.0, car.size.y), Color(0.76, 0.14, 0.16))
			var roof := car.grow_individual(-16.0, 0.0, -16.0, 0.0)
			b.rect(roof, Color(0.44, 0.46, 0.50))
			b.rect(Rect2(roof.position.x, roof.position.y, 6.0, roof.size.y), Color(0.56, 0.58, 0.62))
			# the roof walk, and the gear on it
			b.line(Vector2(roof.get_center().x, roof.position.y + 6.0), Vector2(roof.get_center().x, roof.end.y - 6.0), Color(0.36, 0.38, 0.42), 2.0)
			for vk in range(2):
				var ac := Rect2(roof.get_center().x - 34.0, car.position.y + 30.0 + float(vk) * 130.0, 68.0, 40.0)
				if ac.end.y < car.end.y - 6.0:
					b.rect(Rect2(ac.position + Vector2(4, 5), ac.size), Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.25))
					b.rect(ac, Color(0.70, 0.72, 0.74))
					b.circle(ac.get_center() + Vector2(-16.0, 0.0), 11.0, Color(0.34, 0.36, 0.40))
					b.circle(ac.get_center() + Vector2(16.0, 0.0), 11.0, Color(0.34, 0.36, 0.40))
					b.circle(ac.get_center() + Vector2(-16.0, 0.0), 4.0, Color(0.55, 0.57, 0.60))
					b.circle(ac.get_center() + Vector2(16.0, 0.0), 4.0, Color(0.55, 0.57, 0.60))
			if n % 2 == 1:
				# the pantograph, folded: a diamond of arms and the head bar
				var pc := Vector2(roof.get_center().x, car.position.y + 112.0)
				for d: Vector2 in [Vector2(-22, -14), Vector2(22, -14), Vector2(-22, 14), Vector2(22, 14)]:
					b.line(pc, pc + d, Color(0.22, 0.22, 0.24), 2.5)
				b.rect(Rect2(pc.x - 34.0, pc.y - 16.0, 68.0, 4.0), Color(0.20, 0.20, 0.22))
			# the gangway bellows to the next car
			if car.end.y < tr.end.y - 10.0:
				b.rect(Rect2(car.position.x + 30.0, car.end.y, car.size.x - 60.0, 10.0), Color(0.14, 0.14, 0.15))
		cy += 240.0
		n += 1
	if tr.position.y > vt - 60.0:
		# the cab: the nose raked to the windscreen, the headlamps
		var front := tr.position.y
		b.polygon(PackedVector2Array([Vector2(tr.position.x + 18.0, front + 24.0), Vector2(tr.end.x - 18.0, front + 24.0),
			Vector2(tr.end.x - 34.0, front + 6.0), Vector2(tr.position.x + 34.0, front + 6.0)]), Color(0.16, 0.20, 0.26))
		b.line(Vector2(tr.position.x + 38.0, front + 10.0), Vector2(tr.position.x + 80.0, front + 10.0), Color(1, 1, 1, 0.3), 2.0)
		b.circle(Vector2(tr.position.x + 26.0, front + 4.0), 5.0, Color(0.98, 0.96, 0.80))
		b.circle(Vector2(tr.end.x - 26.0, front + 4.0), 5.0, Color(0.98, 0.96, 0.80))


# L'Estacio's off-leash space, PIPICÀ: the old goods yard beside the
# station. Big concrete slabs with a siding still set into them, running to
# a buffer stop; the grove's trees in square pits; brick walls round it;
# bike stands along the gate wall. Past the far wall the running lines.
static func _draw_goods_yard(m: Node2D, c: Object) -> void:
	var r: Rect2 = m._freedom_rect()
	var b: ShapeBatch = c if c is ShapeBatch else ShapeBatch.new(c)
	var slab := Color(0.60, 0.60, 0.58)
	b.rect(r, slab)
	var row := 0
	var sy := r.position.y
	while sy < r.end.y:
		var sx := r.position.x - (40.0 if row % 2 == 1 else 0.0)
		var k := 0
		while sx < r.end.x:
			var h := fmod(absf(sin(float(row) * 12.9898 + float(k) * 78.233) * 43758.5453), 1.0)
			var x0 := maxf(sx, r.position.x)
			var x1 := minf(sx + 80.0, r.end.x)
			b.rect(Rect2(x0 + 1.0, sy + 1.0, x1 - x0 - 2.0, minf(78.0, r.end.y - sy - 1.0)), slab.lightened((h - 0.5) * 0.10))
			sx += 80.0
			k += 1
		sy += 80.0
		row += 1
	# worn pale where every dog plays
	b.circle(r.get_center() + Vector2(-40.0, 30.0), 150.0, Color(0.70, 0.69, 0.66, 0.30))
	# the old siding set flush into the slabs, rusted, to its buffer stop
	var ry := r.position.y + r.size.y * 0.62
	var buf_x := r.end.x - 110.0
	b.rect(Rect2(r.position.x, ry - 22.0, buf_x - r.position.x, 44.0), Color(0.50, 0.48, 0.45))
	var tx := r.position.x + 8.0
	while tx < buf_x:
		b.rect(Rect2(tx, ry - 20.0, 9.0, 40.0), Color(0.42, 0.36, 0.30, 0.7))
		tx += 26.0
	for rr: float in [-12.0, 12.0]:
		b.rect(Rect2(r.position.x, ry + rr - 2.5, buf_x - r.position.x, 5.0), Color(0.46, 0.30, 0.22))
		b.rect(Rect2(r.position.x, ry + rr - 2.5, buf_x - r.position.x, 1.5), Color(0.72, 0.62, 0.52))
	b.rect(Rect2(buf_x - 4.0, ry - 26.0, 22.0, 52.0), Color(0.24, 0.24, 0.26))
	b.rect(Rect2(buf_x - 12.0, ry - 22.0, 10.0, 44.0), Color(0.82, 0.18, 0.16))
	for sk in range(3):
		b.rect(Rect2(buf_x - 12.0, ry - 18.0 + float(sk) * 14.0, 10.0, 6.0), Color(0.94, 0.94, 0.90))
	# the grove's trees in square pits cut into the slabs
	for t: Vector2 in m.trees:
		b.rect(Rect2(t - Vector2(22, 22), Vector2(44, 44)), Color(0.44, 0.44, 0.44))
		b.rect(Rect2(t - Vector2(19, 19), Vector2(38, 38)), Color(0.34, 0.27, 0.20))
	# brick walls round it, open at the gate
	var brick := Color(0.58, 0.34, 0.26)
	b.rect(Rect2(r.position.x - 12.0, r.position.y - 12.0, r.size.x + 24.0, 12.0), brick)
	b.rect(Rect2(r.position.x - 12.0, r.position.y, 12.0, r.size.y + 12.0), brick)
	b.rect(Rect2(r.end.x, r.position.y, 12.0, r.size.y + 12.0), brick)
	b.rect(Rect2(r.position.x - 12.0, r.end.y, m.gate_l - 20.0 - r.position.x + 12.0, 12.0), brick)
	b.rect(Rect2(m.gate_r + 20.0, r.end.y, r.end.x + 12.0 - m.gate_r - 20.0, 12.0), brick)
	b.rect(Rect2(r.position.x - 12.0, r.position.y - 12.0, r.size.x + 24.0, 3.0), brick.lightened(0.22))
	var px := r.position.x + 60.0
	while px < r.end.x:
		b.rect(Rect2(px - 7.0, r.position.y - 14.0, 14.0, 16.0), brick.darkened(0.15))
		px += 120.0
	# bike stands along the gate wall: steel hoops seen from above
	for bx in range(5):
		var hp := Vector2(r.position.x + 150.0 + float(bx) * 34.0, r.end.y - 26.0)
		b.line(hp + Vector2(0, -12), hp + Vector2(0, 12), Color(0.66, 0.68, 0.70), 3.0)
		b.circle(hp + Vector2(0, -12), 2.5, Color(0.40, 0.42, 0.44))
		b.circle(hp + Vector2(0, 12), 2.5, Color(0.40, 0.42, 0.44))
	if b != c:
		b.flush()
	m._draw_freedom_benches(c, r, Color(0.36, 0.40, 0.44))
	m._freedom_sign(c, r, m.gate_text, "the old goods yard, off leash")


# Past L'Estacio's goods yard wall: the running lines (ballast, sleepers,
# two tracks, the catenary masts and wires) and the station's sheds either
# side. Static, on the cached canvas.
static func _draw_running_lines(m: Node2D, c: Object) -> void:
	var top: float = m._freedom_rect().position.y
	var b := ShapeBatch.new()
	# the running lines past the yard wall: ballast, sleepers, two
	# tracks, the catenary masts; the station's sheds either side
	b.rect(Rect2(-400.0, top - 2000.0, 2100.0, 1990.0), Color(0.46, 0.43, 0.40))
	for tk in range(2):
		var ty := top - 90.0 - float(tk) * 140.0
		var sx := -400.0
		while sx < 1700.0:
			b.rect(Rect2(sx, ty - 30.0, 10.0, 60.0), Color(0.36, 0.33, 0.30))
			sx += 24.0
		for rr: float in [-16.0, 16.0]:
			b.rect(Rect2(-400.0, ty + rr - 2.5, 2100.0, 5.0), Color(0.62, 0.62, 0.64))
	var mx := -340.0
	while mx < 1700.0:
		b.rect(Rect2(mx - 6.0, top - 330.0, 12.0, 12.0), Color(0.30, 0.32, 0.34))
		b.line(Vector2(mx, top - 324.0), Vector2(mx, top - 30.0), Color(0.24, 0.26, 0.28, 0.8), 2.0)
		mx += 260.0
	for wy: float in [top - 106.0, top - 246.0]:
		b.line(Vector2(-400.0, wy), Vector2(1700.0, wy), Color(0.20, 0.20, 0.22, 0.7), 1.2)
	var r2: Rect2 = m._freedom_rect()
	for sr: Rect2 in [Rect2(-400.0, top - 12.0, 458.0, r2.size.y + 40.0), Rect2(r2.end.x + 12.0, top - 12.0, 520.0, r2.size.y + 40.0)]:
		b.rect(sr, Color(0.50, 0.52, 0.54))
		var gy := sr.position.y + 6.0
		while gy < sr.end.y:
			b.line(Vector2(sr.position.x, gy), Vector2(sr.end.x, gy), Color(0.40, 0.42, 0.45), 2.0)
			gy += 14.0
	b.flush(c)


# The board itself, overhead: the steel case with a lit top edge, the dark
# face, the heading strip, then the rows (text, which flushes the batch and
# goes straight to the canvas it stands in for).
static func departures_board(m: Node2D, b: ShapeBatch, bd: Vector2) -> void:
	b.rect(Rect2(bd.x - 154.0, bd.y - 38.0, 308.0, 76.0), Color(0.42, 0.44, 0.48))
	b.rect(Rect2(bd.x - 154.0, bd.y - 38.0, 308.0, 3.0), Color(0.66, 0.68, 0.72))
	b.rect(Rect2(bd.x - 150.0, bd.y - 34.0, 300.0, 68.0), Color(0.07, 0.07, 0.09))
	b.rect(Rect2(bd.x - 150.0, bd.y - 34.0, 300.0, 13.0), Color(0.16, 0.30, 0.56))
	for row in range(4):
		b.line(Vector2(bd.x - 146.0, bd.y - 7.0 + float(row) * 11.0), Vector2(bd.x + 146.0, bd.y - 7.0 + float(row) * 11.0),
			Color(1, 1, 1, 0.04), 1.0)
	var amber := Color(1.0, 0.72, 0.18)
	b.draw_string(m.font, Vector2(bd.x - 144.0, bd.y - 24.0), "SORTIDES", HORIZONTAL_ALIGNMENT_LEFT, -1, 10,
		Color(0.94, 0.96, 1.0))
	b.draw_string(m.font, Vector2(bd.x + 40.0, bd.y - 24.0), "departures", HORIZONTAL_ALIGNMENT_LEFT, -1, 9,
		Color(0.80, 0.86, 0.96, 0.8))
	for row in range(DEPARTURES.size()):
		var d: Array = DEPARTURES[row]
		var y := bd.y - 10.0 + float(row) * 11.0
		b.draw_string(m.font, Vector2(bd.x - 144.0, y), String(d[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, amber)
		b.draw_string(m.font, Vector2(bd.x - 100.0, y), String(d[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, amber)
		var cancelled := String(d[2]).length() > 2
		b.draw_string(m.font, Vector2(bd.x + 144.0 - (68.0 if cancelled else 10.0), y), String(d[2]),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.98, 0.34, 0.28) if cancelled else amber)


# A row of luggage trolleys nested into each other, the length of a van.
static func _draw_trolleys(m: Node2D, v: Vector2) -> void:
	var b := ShapeBatch.new()
	b.rect(Rect2(v.x - 26.0 + 8.0, v.y - 64.0 + 10.0, 52.0, 128.0), Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.18))
	for k in range(6):
		var ty := v.y - 64.0 + float(k) * 21.0
		b.rect(Rect2(v.x - 24.0, ty, 48.0, 30.0), Color(0.62, 0.64, 0.68))
		b.rect(Rect2(v.x - 20.0, ty + 4.0, 40.0, 22.0), Color(0.40, 0.42, 0.46))
		b.line(Vector2(v.x - 26.0, ty), Vector2(v.x + 26.0, ty), Color(0.80, 0.20, 0.20), 3.0)
	b.flush(m._wc)


# a concourse pillar from above: a square granite plinth on the terrazzo,
# the round iron column standing on it with its lit side, and the moulded
# ring where the shaft meets the base. One batch.
static func _pillar(m: Node2D, p: Vector2) -> void:
	m.cast_shadow(m._wc, p, 18.0, 40.0, 0.2)
	var b := ShapeBatch.new()
	b.rect(Rect2(p.x - 22.0, p.y - 22.0, 44.0, 44.0), Color(0.42, 0.42, 0.45))
	b.rect(Rect2(p.x - 22.0, p.y - 22.0, 44.0, 4.0), Color(0.58, 0.58, 0.61))
	b.rect(Rect2(p.x - 22.0, p.y - 22.0, 4.0, 44.0), Color(0.54, 0.54, 0.57))
	b.rect(Rect2(p.x - 17.0, p.y - 17.0, 34.0, 34.0), Color(0.50, 0.50, 0.53))
	b.circle(p, 16.0, Color(0.30, 0.34, 0.38))
	b.circle(p, 13.5, Color(0.40, 0.46, 0.50))
	b.circle(p - m.LIGHT * 4.0, 8.0, Color(0.52, 0.58, 0.62))
	b.circle(p - m.LIGHT * 6.0, 3.5, Color(0.70, 0.75, 0.78))
	b.flush(m._wc)


# --- main's walk hooks (main.WALK_MODULES) ---------------------------------------

# the concourse, up to the gate
static func draw_live(m: Node2D, _wc: ShapeBatch, vt: float, vb: float) -> void:
	_draw_concourse(m, maxf(vt, m.GATE_Y - 30.0), vb)


# past the goods yard's wall: the running lines and the sheds
static func draw_freedom_beyond(m: Node2D, c: Object) -> void:
	_draw_running_lines(m, c)


# the off-leash space is the old goods yard
static func draw_freedom_ground(m: Node2D, c: Object) -> void:
	_draw_goods_yard(m, c)


# stacked creosote railway sleepers (travesses) with iron rail chairs
static func draw_log_prop(m: Node2D, c: Object, p: Vector2) -> void:
	# stacked creosote railway sleepers (travesses) with iron rail chairs
	var tie := Color(0.25, 0.18, 0.13)
	c.draw_rect(Rect2(p.x - 32.0, p.y - 10.0, 64.0, 9.0), tie.darkened(0.12))
	c.draw_rect(Rect2(p.x - 29.0, p.y - 2.0, 60.0, 9.0), tie)
	c.draw_rect(Rect2(p.x - 29.0, p.y - 2.0, 60.0, 3.0), tie.lightened(0.16))
	for sx: float in [-18.0, 16.0]:
		c.draw_rect(Rect2(p.x + sx - 4.0, p.y - 9.0, 8.0, 15.0), Color(0.36, 0.28, 0.22))
		c.draw_circle(Vector2(p.x + sx, p.y - 1.0), 2.2, Color(0.52, 0.42, 0.34))


# a planter with a potted palm, the station's stand-in for a hydrant
static func draw_bollard(m: Node2D, wc: ShapeBatch, h) -> void:
	var hp: Vector2 = h.pos
	# a planter with a potted palm, the station's stand-in for a hydrant
	m.contact_shadow(wc, hp, 13.0, 5.0, 0.2)
	wc.draw_circle(hp, 12.0, Color(0.36, 0.32, 0.30) if not h.done else Color(0.30, 0.28, 0.27))
	wc.draw_circle(hp, 9.0, Color(0.30, 0.24, 0.18))
	for k in range(5):
		var fa := TAU * float(k) / 5.0 + 0.4
		wc.draw_line(hp, hp + Vector2.from_angle(fa) * 16.0, Color(0.26, 0.48, 0.26), 4.0)
	if not h.done and h.progress > 0.0:
		wc.draw_arc(hp, 17.0, -PI / 2.0, -PI / 2.0 + TAU * h.progress / 0.8, 20, Color(1, 0.95, 0.7), 3.0)


# the hall's pillars; at the barrier line a post is a gate cabinet, drawn
# with the barriers
static func draw_column(m: Node2D, _wc: ShapeBatch, p: Vector2) -> void:
	if absf(p.y - m.LevelBuild.ESTACIO_BARRIER_Y) < 1.0:
		return
	_pillar(m, p)


# luggage trolleys where another walk parks a van
static func draw_van(m: Node2D, _wc: ShapeBatch, v: Vector2) -> void:
	_draw_trolleys(m, v)
