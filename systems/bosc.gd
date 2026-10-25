class_name Bosc
extends RefCounted

# WALK 8: EL BOSC (Collserola). Its drawing as static functions over main's
# state (main.WALK_MODULES): the wood either side of the trail, the stream
# and its stepping stones, the fallen logs, the trail's ragged edges, the
# way markers, the forest spring and the bocadillos.

const ShapeBatch := preload("res://systems/shape_batch.gd")

# A half-eaten bocadillo in its foil, dropped off someone's picnic.
static func draw_bocadillo(m: Node2D, c: Object, kp: Vector2) -> void:
	m.contact_shadow(c, kp, 11.0, 4.0, 0.20)
	c.draw_colored_polygon(PackedVector2Array([
		kp + Vector2(-12, -2), kp + Vector2(-4, -8), kp + Vector2(12, -5),
		kp + Vector2(10, 6), kp + Vector2(-8, 7),
	]), Color(0.78, 0.80, 0.83))
	c.draw_line(kp + Vector2(-6, -6), kp + Vector2(8, -3), Color(0.93, 0.94, 0.96), 1.5)
	c.draw_rect(Rect2(kp.x - 7.0, kp.y - 3.0, 14.0, 6.0), Color(0.80, 0.60, 0.33))
	c.draw_rect(Rect2(kp.x - 7.0, kp.y - 3.0, 14.0, 2.0), Color(0.88, 0.70, 0.42))
	c.draw_line(kp + Vector2(-6, 1), kp + Vector2(6, 1), Color(0.72, 0.26, 0.24), 1.6)


# The wood either side of El Bosc's trail, from the wood line outward:
# undergrowth along the line, then overlapping crowns to the edge of the
# frame. One batch, and every clump is hashed from its row so it holds still.
static func _draw_wood(m: Node2D, vt: float, vb: float) -> void:
	var out: float = m.LevelBuild.TRAIL_WOOD_OUT
	var b := ShapeBatch.new()
	var step := 56.0
	# stops at the gate: the clearing beyond has its own ring of trees
	var sy := maxf(floorf((vt - 80.0) / step) * step, m.GATE_Y + 100.0)
	while sy < vb + 80.0:
		var e: Vector2 = m.walk_edges(sy + step * 0.5)
		var row := int(absf(sy) / step)
		for side: float in [-1.0, 1.0]:
			var line: float = (e.x - out) if side < 0.0 else (e.y + out)
			var far_x: float = line + side * 12.0
			b.rect(Rect2(minf(far_x, far_x + side * 700.0), sy, 700.0, step + 1.0), Color(0.12, 0.20, 0.12))
			for k in range(5):
				var h := fmod(absf(sin(float(row * 7 + k) * 12.9898 + side * 3.1) * 43758.5453), 1.0)
				var cx: float = line + side * (26.0 + float(k) * 60.0 + h * 18.0)
				var cy := sy + step * 0.5 + (h - 0.5) * 30.0
				var r := 30.0 + h * 14.0
				b.circle(Vector2(cx, cy) + Vector2(3, 4), r, Color(0.10, 0.17, 0.10))
				b.circle(Vector2(cx, cy), r * 0.9, Color(0.17, 0.29, 0.16) if (row + k) % 3 != 0 else Color(0.20, 0.31, 0.15))
				b.circle(Vector2(cx, cy) - m.LIGHT * r * 0.35, r * 0.42, Color(0.25, 0.38, 0.20))
			# undergrowth and a trunk or two right on the line
			var hu := fmod(absf(sin(float(row) * 78.233 + side) * 43758.5453), 1.0)
			b.circle(Vector2(line + side * 4.0, sy + hu * step), 13.0 + hu * 6.0, Color(0.19, 0.30, 0.17))
			b.circle(Vector2(line - side * 6.0, sy + step * 0.5 + hu * 10.0), 9.0, Color(0.23, 0.35, 0.19))
			if row % 2 == 0:
				b.circle(Vector2(line + side * 16.0, sy + step * 0.3), 5.5, Color(0.30, 0.22, 0.15))
		sy += step
	b.flush(m._wc)


# A fallen trunk: bark with its furrows along it, a pale sawn or broken end
# out on the trail, moss on the top, a shadow under it.
static func _draw_fallen_log(m: Node2D, r: Rect2) -> void:
	var b := ShapeBatch.new()
	b.rect(Rect2(r.position + m.LIGHT * 7.0, r.size), Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.28))
	b.rect(r, Color(0.36, 0.26, 0.17))
	b.rect(Rect2(r.position.x, r.position.y, r.size.x, 6.0), Color(0.46, 0.34, 0.22))
	for k in range(4):
		var fy := r.position.y + 5.0 + float(k) * 4.0
		b.line(Vector2(r.position.x + 6.0 + float(k) * 9.0, fy), Vector2(r.end.x - 10.0 - float(k) * 7.0, fy), Color(0.27, 0.19, 0.12), 1.4)
	var hx: float = r.get_center().x
	b.circle(Vector2(hx - 20.0, r.position.y + 3.0), 6.0, Color(0.33, 0.44, 0.22))
	b.circle(Vector2(hx + 14.0, r.position.y + 2.0), 4.5, Color(0.38, 0.50, 0.25))
	# the broken ends: pale wood rings at both, splinters at the trail end
	for ex: float in [r.position.x, r.end.x]:
		b.circle(Vector2(ex, r.get_center().y), r.size.y * 0.5, Color(0.66, 0.54, 0.38))
		b.circle(Vector2(ex, r.get_center().y), r.size.y * 0.28, Color(0.55, 0.43, 0.29))
	b.flush(m._wc)


# The stream across the wood and the footbridge that carries the trail over
# it. The water rects (level_build.trail_stream) stop at the bridge; the
# stream is drawn across under it so it reads as running beneath.
static func _draw_stream(m: Node2D, vt: float, vb: float) -> void:
	var sy: float = m.LevelBuild.TRAIL_STREAM_Y
	var half: float = m.LevelBuild.TRAIL_HIGH_STREAM_HALF if m.bosc_high_stream else m.LevelBuild.TRAIL_STREAM_HALF
	if sy < vt - 120.0 or sy > vb + 120.0:
		return
	var wt := AnimClock.msec() / 1000.0
	var bank := PackedVector2Array()
	var water := PackedVector2Array()
	var xs: Array[float] = []
	var x := -400.0
	while x <= 1700.0:
		xs.append(x)
		x += 60.0
	for bx: float in xs:
		bank.append(Vector2(bx, sy - half - 10.0 + sin(bx * 0.021) * 5.0))
	for k in range(xs.size() - 1, -1, -1):
		bank.append(Vector2(xs[k], sy + half + 10.0 + sin(xs[k] * 0.017 + 1.0) * 5.0))
	for bx: float in xs:
		water.append(Vector2(bx, sy - half + sin(bx * 0.021) * 4.0))
	for k in range(xs.size() - 1, -1, -1):
		water.append(Vector2(xs[k], sy + half + sin(xs[k] * 0.017 + 1.0) * 4.0))
	m._wc.draw_colored_polygon(bank, Color(0.36, 0.30, 0.21))
	m._wc.draw_colored_polygon(water, Color(0.24, 0.40, 0.43) if m.bosc_high_stream else Color(0.27, 0.42, 0.44))
	var wb := ShapeBatch.new()
	# deeper down the middle: a darker band where the current runs
	var deep := PackedVector2Array()
	for bx: float in xs:
		deep.append(Vector2(bx, sy - half * 0.45 + sin(bx * 0.019 + 0.5) * 3.0))
	for k in range(xs.size() - 1, -1, -1):
		deep.append(Vector2(xs[k], sy + half * 0.40 + sin(xs[k] * 0.015 + 1.7) * 3.0))
	wb.polygon(deep, Color(0.18, 0.32, 0.36, 0.55))
	# foam where the water meets each bank, drifting with the current
	for k in range(34):
		var fx := fmod(float(k) * 61.0 + wt * 22.0, 2100.0) - 400.0
		var top := sy - half + sin(fx * 0.021) * 4.0 + 2.0
		var bot := sy + half + sin(fx * 0.017 + 1.0) * 4.0 - 2.0
		wb.line(Vector2(fx, top), Vector2(fx + 12.0, top), Color(0.92, 0.95, 0.94, 0.35), 2.0)
		wb.line(Vector2(fx + 30.0, bot), Vector2(fx + 40.0, bot), Color(0.92, 0.95, 0.94, 0.30), 2.0)
	# current lines running downstream (east), quicker in the deep middle
	for k in range(18):
		var lane := float(k % 3) - 1.0
		var speed := 52.0 if lane == 0.0 else 34.0
		if m.bosc_high_stream:
			speed += 20.0
		var rx := fmod(float(k) * 127.0 + wt * speed, 2100.0) - 400.0
		var ry := sy + lane * half * 0.5 + sin(rx * 0.02) * 2.0
		wb.line(Vector2(rx, ry), Vector2(rx + 26.0, ry + 1.0), Color(1, 1, 1, 0.18 if lane == 0.0 else 0.12), 2.0)
	# variegated river pebbles and stones along both shores
	var pebble_cols: Array[Color] = [
		Color(0.55, 0.52, 0.48),
		Color(0.66, 0.58, 0.46),
		Color(0.38, 0.38, 0.40),
		Color(0.80, 0.82, 0.82),
	]
	for k: int in range(16):
		var stx := -200.0 + float(k) * 120.0 + float(k % 3) * 19.0
		var sty := sy + (half + 4.0) * (1.0 if k % 2 == 0 else -1.0) + sin(float(k) * 1.8) * 3.0
		var srad := 4.5 + float(k % 4) * 1.5
		var scol: Color = pebble_cols[k % pebble_cols.size()]
		wb.circle(Vector2(stx, sty), srad + 2.0, Color(0.90, 0.95, 0.96, 0.20))
		wb.circle(Vector2(stx, sty), srad, scol)
		wb.circle(Vector2(stx - 1.2, sty - 1.2), srad * 0.45, scol.lightened(0.25))

	# the footbridge: planks across the trail's width, a rail each side
	var e: Vector2 = m.walk_edges(sy)
	var bh: float = m.LevelBuild.TRAIL_BRIDGE_HALF
	var deck := Rect2(e.x - 18.0, sy - bh, e.y - e.x + 36.0, bh * 2.0)
	wb.rect(Rect2(deck.position + m.LIGHT * 8.0, deck.size), Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.25))
	wb.rect(Rect2(deck.position.x + 8.0, sy - half, deck.size.x - 16.0, half * 2.0), Color(0.12, 0.20, 0.22, 0.45))
	wb.rect(Rect2(deck.position.x - 4.0, sy - bh - 2.0, 10.0, bh * 2.0 + 4.0), Color(0.42, 0.38, 0.32))
	wb.rect(Rect2(deck.end.x - 6.0, sy - bh - 2.0, 10.0, bh * 2.0 + 4.0), Color(0.42, 0.38, 0.32))
	wb.rect(deck, Color(0.55, 0.42, 0.28))
	var px := deck.position.x
	while px < deck.end.x:
		wb.line(Vector2(px, deck.position.y), Vector2(px, deck.end.y), Color(0.40, 0.30, 0.20), 2.0)
		wb.circle(Vector2(px + 8.0, deck.position.y + 7.0), 1.2, Color(0.25, 0.22, 0.18))
		wb.circle(Vector2(px + 8.0, deck.end.y - 7.0), 1.2, Color(0.25, 0.22, 0.18))
		px += 16.0
	for ry: float in [deck.position.y + 3.0, deck.end.y - 3.0]:
		wb.line(Vector2(deck.position.x, ry), Vector2(deck.end.x, ry), Color(0.36, 0.26, 0.16), 5.0)
		wb.line(Vector2(deck.position.x, ry - 1.5), Vector2(deck.end.x, ry - 1.5), Color(0.68, 0.54, 0.36), 1.5)
	# the four posts (they are poles: the rope wraps them)
	for i in range(m.deco_pole_count, m.deco_pole_count + 4):
		var bp: Vector2 = m.poles[i]
		wb.circle(bp, 7.0, Color(0.34, 0.25, 0.16))
		wb.circle(bp + Vector2(-1.5, -1.5), 4.5, Color(0.58, 0.46, 0.30))
		wb.circle(bp + Vector2(-1.0, -1.0), 2.0, Color(0.72, 0.60, 0.42))
	wb.flush(m._wc)


static func _draw_edges(m: Node2D, left: PackedVector2Array, right: PackedVector2Array, col: Color) -> void:
	if left.size() < 2:
		return
	var b := ShapeBatch.new()
	var worn := Color(col.r * 0.86, col.g * 0.86, col.b * 0.86, 0.6)
	var loose := Color(col.r * 0.92, col.g * 0.9, col.b * 0.86, 0.85)
	var root := Color(0.36, 0.26, 0.17)
	var top: float = left[0].y
	var bot: float = left[left.size() - 1].y
	var y: float = floorf(top / m.TRAIL_FRAY_STEP) * m.TRAIL_FRAY_STEP
	while y < bot:
		var e0: Vector2 = m.walk_edges(y)
		var e1: Vector2 = m.walk_edges(y + m.TRAIL_FRAY_STEP)
		for side in range(2):
			var out := -1.0 if side == 0 else 1.0
			var a := Vector2(e0.x if side == 0 else e0.y, y)
			var c := Vector2(e1.x if side == 0 else e1.y, y + m.TRAIL_FRAY_STEP)
			b.line(a + Vector2(-out * 7.0, 0.0), c + Vector2(-out * 7.0, 0.0), worn, 10.0)
			for k in range(2):
				var q := a.lerp(c, (float(k) + 0.5) / 2.0)
				var h: float = m._cell01(q.y, float(side) * 31.0)
				var rr := 6.0 + h * 5.0
				var cq := q + Vector2(out * (2.0 + h * 6.0), 0.0)
				var hex := PackedVector2Array()
				for v in range(6):
					hex.append(cq + Vector2.from_angle(TAU * float(v) / 6.0 + h) * rr)
				b.polygon(hex, loose)
			var hr: float = m._cell01(y, 7.0 + float(side))
			if hr < 0.22:
				# a root across the edge, from the wood into the path
				var rq := a.lerp(c, hr * 4.0)
				b.line(rq + Vector2(out * 26.0, -4.0), rq + Vector2(-out * 18.0, 3.0), root, 3.0)
				b.line(rq + Vector2(out * 6.0, -1.0), rq + Vector2(-out * 6.0, 9.0), root, 2.0)
			elif hr > 0.72:
				# wild saffron milk cap mushrooms (pinetells / rovellons) in pine needles
				var mq := a.lerp(c, (hr - 0.72) * 3.5) + Vector2(out * 24.0, 0.0)
				b.circle(mq + m.LIGHT * 1.5, 4.5, Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.2))
				b.circle(mq, 4.2, Color(0.86, 0.44, 0.16))
				b.circle(mq, 3.0, Color(0.76, 0.36, 0.12))
				b.circle(mq + Vector2(-0.8, -0.8), 1.2, Color(0.96, 0.65, 0.30))
				var sq := mq + Vector2(-out * 4.5, 3.5)
				b.circle(sq, 2.5, Color(0.84, 0.42, 0.16))
				b.circle(sq + Vector2(-0.5, -0.5), 0.8, Color(0.95, 0.62, 0.28))
			elif hr > 0.40 and hr < 0.52:
				# a stone pine cone (pinya) lying on the forest margin
				var pq := a.lerp(c, (hr - 0.40) * 8.0) + Vector2(out * 18.0, 0.0)
				b.circle(pq + m.LIGHT * 1.5, 3.5, Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.2))
				b.circle(pq, 3.2, Color(0.36, 0.24, 0.14))
				b.line(pq + Vector2(-2.0, 0.0), pq + Vector2(2.0, 0.0), Color(0.52, 0.38, 0.24), 1.4)
				b.line(pq + Vector2(0.0, -2.0), pq + Vector2(0.0, 2.0), Color(0.52, 0.38, 0.24), 1.4)
		if int(absf(y)) % 528 < int(m.TRAIL_FRAY_STEP):
			var wp := Vector2(e0.y + 16.0, y)
			m._draw_trail_waymarker(b, wp, 1.0)
		y += m.TRAIL_FRAY_STEP
	b.flush(m._wc)


# a forest spring, a font: the props match draws it for a trough on El Bosc
static func draw_trough_prop(m: Node2D, c: Object, p: Vector2) -> void:
	# a forest spring, a font: a stone back with a pipe, the water
	# falling from it into a round stone basin, moss on the stones
	c.draw_circle(p + m.LIGHT * 5.0, 22.0, Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.25))
	c.draw_rect(Rect2(p.x - 16.0, p.y - 26.0, 32.0, 12.0), Color(0.50, 0.47, 0.42))
	c.draw_rect(Rect2(p.x - 16.0, p.y - 26.0, 32.0, 3.0), Color(0.64, 0.61, 0.56))
	c.draw_circle(p, 20.0, Color(0.46, 0.43, 0.38))
	c.draw_circle(p - m.LIGHT * 3.0, 18.0, Color(0.58, 0.55, 0.49))
	c.draw_circle(p, 14.0, Color(0.20, 0.34, 0.40))
	c.draw_circle(p + Vector2(-3.0, -3.0), 9.0, Color(0.32, 0.50, 0.58))
	for mo: Vector2 in [Vector2(-14, 8), Vector2(12, 12), Vector2(-10, -24)]:
		c.draw_circle(p + mo, 4.0, Color(0.30, 0.44, 0.22, 0.85))
	# the pipe, and the water falling into the basin, rings spreading
	c.draw_line(p + Vector2(0, -20), p + Vector2(0, -12), Color(0.36, 0.34, 0.32), 3.0)
	c.draw_line(p + Vector2(0, -12), p + Vector2(0, -4), Color(0.78, 0.88, 0.94, 0.8), 2.0)
	# a still ring where it falls: this canvas is cached, so anything
	# animated here would freeze wherever the last redraw left it
	c.draw_arc(p + Vector2(0, -3), 5.0, 0, TAU, 14, Color(0.80, 0.90, 0.96, 0.4), 1.2)


# --- main's walk hooks (main.WALK_MODULES) ---------------------------------------

# the wood line: no grass past it
static func grass_blocked(m: Node2D, p: Vector2) -> bool:
	var e: Vector2 = m.walk_edges(p.y)
	return p.x < e.x - m.LevelBuild.TRAIL_WOOD_OUT or p.x > e.y + m.LevelBuild.TRAIL_WOOD_OUT


# the wood, the stream and the fallen logs, after the rest of the ground
static func draw_scenery(m: Node2D, _wc: ShapeBatch, vt: float, vb: float) -> void:
	_draw_wood(m, vt, vb)
	_draw_stream(m, vt, vb)
	for lr: Rect2 in m.LevelBuild.trail_logs(m):
		if lr.position.y > vt - 60.0 and lr.position.y < vb + 60.0:
			_draw_fallen_log(m, lr)


# the trail's own ragged edges in place of kerbs
static func draw_path_edges(m: Node2D, left: PackedVector2Array, right: PackedVector2Array, col: Color) -> void:
	_draw_edges(m, left, right, col)


# a way marker post for a hydrant (main._draw_waymarker, shared with Montjuic)
static func draw_bollard(m: Node2D, wc: ShapeBatch, h) -> void:
	m._draw_waymarker(wc, h)


# a dropped snack, on El Bosc, is a walker's bocadillo
static func draw_snack(m: Node2D, wc: ShapeBatch, kp: Vector2) -> void:
	draw_bocadillo(m, wc, kp)
