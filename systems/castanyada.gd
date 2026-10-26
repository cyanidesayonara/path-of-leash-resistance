class_name Castanyada
extends RefCounted

# WALK: LA CASTANYADA (the chestnut festival, by night). Its drawing as static
# functions over main's state (main.WALK_MODULES): the plaça's paving, the
# stage and the stalls down the street, the lantern strings and lamp-lit
# fronts on the overhead layer, and the festival yard past the gate. The
# candy, the roaster's queue and the braziers' and sacks' props stay in
# main: they are the walk's rules and shared prop loops, not its picture.

const ShapeBatch := preload("res://systems/shape_batch.gd")
const LevelBuild := preload("res://world/level_build.gd")

static func _draw_street(m: Node2D, vt: float, vb: float) -> void:
	var b := ShapeBatch.new()
	var t := AnimClock.msec() / 1000.0
	var pc: Vector2 = LevelBuild.CAST_PLACA
	# the plaça's paving: a ring of setts round the middle
	if pc.y > vt - 520.0 and pc.y < vb + 520.0:
		for ring in range(5):
			b.circle(pc, 380.0 - float(ring) * 70.0, Color(0, 0, 0, 0.035))
		# the stage: boards on trestles, speakers at its corners, bunting
		var st: Rect2 = LevelBuild.castanyada_stage(m)
		b.rect(Rect2(st.position + m.LIGHT * 12.0, st.size), Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.25))
		b.rect(st, Color(0.46, 0.32, 0.22))
		var by := st.position.y + 12.0
		while by < st.end.y:
			b.line(Vector2(st.position.x, by), Vector2(st.end.x, by), Color(0.34, 0.24, 0.16), 2.0)
			by += 24.0
		for sp: Vector2 in [st.position + Vector2(10, 10), Vector2(st.end.x - 10.0, st.position.y + 10.0),
				Vector2(st.position.x + 10.0, st.end.y - 10.0), st.end - Vector2(10, 10)]:
			b.rect(Rect2(sp - Vector2(9, 9), Vector2(18, 18)), Color(0.10, 0.10, 0.12))
			b.circle(sp, 5.0, Color(0.30, 0.30, 0.34))
		# the roaster: the castanyera's cart, the walk's landmark - a timber
		# cart on two big wheels, the brazier drum glowing under its lid of
		# chestnuts, a stovepipe chimney at the back with smoke pouring off
		# it, sacks and paper cones on the counter, a lamp at each corner
		var rc: Vector2 = LevelBuild.CAST_ROASTER_AT
		var rr := Rect2(rc - LevelBuild.CAST_ROASTER * 0.5, LevelBuild.CAST_ROASTER)
		# its light on the setts; the festival is always at night
		for ring in range(8):
			var f := float(ring) / 7.0
			b.circle(rc, lerpf(240.0, 50.0, f), Color(1.0, 0.62, 0.26, 0.03 + f * f * 0.12))
		b.rect(Rect2(rr.position + m.LIGHT * 12.0, rr.size), Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.25))
		# the wheels, either end, and the shafts out the front
		for wx: float in [rr.position.x - 4.0, rr.end.x - 8.0]:
			b.rect(Rect2(wx, rc.y - 30.0, 12.0, 60.0), Color(0.16, 0.12, 0.10))
			b.rect(Rect2(wx + 3.0, rc.y - 26.0, 6.0, 52.0), Color(0.36, 0.26, 0.18))
		for sx: float in [rc.x - 30.0, rc.x + 30.0]:
			b.line(Vector2(sx, rr.end.y), Vector2(sx, rr.end.y + 30.0), Color(0.36, 0.24, 0.14), 5.0)
		b.rect(rr, Color(0.42, 0.27, 0.16))
		var py := rr.position.y + 12.0
		while py < rr.end.y:
			b.line(Vector2(rr.position.x, py), Vector2(rr.end.x, py), Color(0.34, 0.21, 0.12), 2.0)
			py += 14.0
		b.rect(Rect2(rr.position, Vector2(rr.size.x, 10.0)), Color(0.74, 0.20, 0.16))
		b.rect(Rect2(rr.position.x, rr.position.y + 10.0, rr.size.x, 3.0), Color(0.96, 0.82, 0.40))
		var drum := rc + Vector2(-26.0, 6.0)
		b.circle(drum, 36.0, Color(0.14, 0.12, 0.12))
		var glow := 0.85 + 0.15 * sin(t * 9.0)
		b.circle(drum, 29.0, Color(0.96, 0.44, 0.12, glow))
		b.circle(drum, 19.0, Color(1.0, 0.78, 0.32, glow))
		for k in range(14):
			b.circle(drum + Vector2.from_angle(float(k) * 0.9) * (8.0 + float(k % 3) * 6.0), 3.6, Color(0.36, 0.18, 0.08))
		# the chimney, at the back corner: a stovepipe with its cap
		var chim := Vector2(rr.end.x - 26.0, rr.position.y + 22.0)
		b.circle(chim + m.LIGHT * 14.0, 11.0, Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.3))
		b.circle(chim, 11.0, Color(0.20, 0.20, 0.22))
		b.circle(chim, 7.0, Color(0.08, 0.08, 0.09))
		b.circle(chim, 4.0, Color(1.0, 0.56, 0.20, 0.6 * glow))
		# sacks and cones on the counter
		b.circle(rc + Vector2(30.0, 18.0), 13.0, Color(0.66, 0.54, 0.36))
		b.circle(rc + Vector2(30.0, 18.0), 6.0, Color(0.38, 0.22, 0.12))
		for k in range(4):
			var cp := rc + Vector2(50.0 + float(k % 2) * 14.0, 4.0 + float(k / 2) * 20.0)
			b.polygon(PackedVector2Array([cp + Vector2(-5, -7), cp + Vector2(5, -7), cp + Vector2(0, 8)]), Color(0.92, 0.88, 0.78))

		# sweet potato (moniato) roaster pan: warm metal tray with baked sweet potatoes
		var mbox := Rect2(rc.x + 8.0, rc.y - 28.0, 32.0, 20.0)
		b.rect(Rect2(mbox.position + m.LIGHT * 3.0, mbox.size), Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.25))
		b.rect(mbox, Color(0.24, 0.22, 0.22))
		b.rect(mbox.grow(-1.5), Color(0.78, 0.70, 0.54))
		for mi: int in range(3):
			var my := mbox.position.y + 4.0 + float(mi) * 5.5
			var mx := mbox.position.x + 5.0 + float(mi % 2) * 2.0
			b.line(Vector2(mx, my), Vector2(mx + 20.0, my), Color(0.84, 0.44, 0.16), 4.2)
			b.line(Vector2(mx + 4.0, my), Vector2(mx + 16.0, my), Color(0.42, 0.18, 0.08), 2.0)
			b.circle(Vector2(mx + 20.0, my), 2.1, Color(0.84, 0.44, 0.16))
			b.circle(Vector2(mx, my), 2.1, Color(0.84, 0.44, 0.16))
			var sph := fmod(t * 0.5 + float(mi) * 0.33, 1.0)
			b.line(Vector2(mx + 10.0 + sin(t * 2.0 + float(mi)) * 2.0, my - 2.0 - sph * 12.0),
				Vector2(mx + 11.0 + sin(t * 2.0 + float(mi)) * 3.0, my - 6.0 - sph * 16.0),
				Color(0.94, 0.90, 0.85, 0.35 * (1.0 - sph)), 1.5)

		# tray of panellets de pinyons (marzipan sweets rolled in roasted pine nuts)
		var pbox := Rect2(rc.x + 44.0, rc.y - 28.0, 26.0, 20.0)
		b.rect(Rect2(pbox.position + m.LIGHT * 3.0, pbox.size), Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.25))
		b.rect(pbox, Color(0.38, 0.26, 0.16))
		b.rect(pbox.grow(-1.5), Color(0.86, 0.82, 0.74))
		for pi: int in range(6):
			var px := pbox.position.x + 5.0 + float(pi % 3) * 7.5
			var py2 := pbox.position.y + 5.0 + float(pi / 3) * 8.5
			b.circle(Vector2(px, py2), 3.2, Color(0.82, 0.64, 0.30))
			b.circle(Vector2(px - 1.0, py2 - 1.0), 1.2, Color(0.96, 0.90, 0.68))
			b.circle(Vector2(px + 1.2, py2 + 0.8), 1.0, Color(0.56, 0.36, 0.16))

		# blackboard menu (la pissarra) propped near the cart shaft
		var bb := Rect2(rc.x - 72.0, rr.end.y + 4.0, 28.0, 34.0)
		b.rect(Rect2(bb.position + m.LIGHT * 4.0, bb.size), Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.3))
		b.rect(bb, Color(0.44, 0.28, 0.16))
		b.rect(bb.grow(-2.0), Color(0.16, 0.18, 0.18))
		b.line(Vector2(bb.position.x + 4.0, bb.position.y + 7.0), Vector2(bb.end.x - 4.0, bb.position.y + 7.0), Color(0.94, 0.94, 0.96, 0.8), 1.6)
		b.line(Vector2(bb.position.x + 5.0, bb.position.y + 13.0), Vector2(bb.end.x - 7.0, bb.position.y + 13.0), Color(0.90, 0.90, 0.92, 0.65), 1.2)
		b.line(Vector2(bb.position.x + 5.0, bb.position.y + 19.0), Vector2(bb.end.x - 6.0, bb.position.y + 19.0), Color(0.90, 0.90, 0.92, 0.65), 1.2)
		b.line(Vector2(bb.position.x + 5.0, bb.position.y + 25.0), Vector2(bb.end.x - 9.0, bb.position.y + 25.0), Color(0.90, 0.90, 0.92, 0.65), 1.2)

		# a lamp at each front corner
		for lx: float in [rr.position.x + 8.0, rr.end.x - 8.0]:
			b.circle(Vector2(lx, rr.end.y - 6.0), 14.0, Color(1.0, 0.82, 0.46, 0.25))
			b.circle(Vector2(lx, rr.end.y - 6.0), 5.0, Color(1.0, 0.92, 0.66))
		# smoke pouring off the chimney, and a little off the drum
		for k in range(7):
			var ph := fmod(t * 0.3 + float(k) / 7.0, 1.0)
			b.circle(chim + Vector2(sin(t + float(k)) * 8.0 + ph * 40.0, -ph * 170.0), 9.0 + ph * 30.0,
				Color(0.86, 0.84, 0.82, 0.46 * (1.0 - ph)))
		for k in range(3):
			var ph := fmod(t * 0.4 + float(k) / 3.0, 1.0)
			b.circle(drum + Vector2(ph * 20.0, -ph * 70.0), 8.0 + ph * 14.0, Color(0.90, 0.88, 0.86, 0.28 * (1.0 - ph)))
		# confetti thrown from the stage, thickest in front of it
		for k in range(90):
			var ang := float(k) * 2.39996
			var rad := 40.0 + fmod(float(k) * 37.1, 330.0)
			var cp2 := st.get_center() + Vector2(st.size.x * 0.5 + 20.0, 0.0) + Vector2(cos(ang) * rad, sin(ang) * rad * 1.2)
			var ccol: Color = [Color(0.96, 0.30, 0.36), Color(0.98, 0.84, 0.28), Color(0.36, 0.64, 0.92),
				Color(0.52, 0.80, 0.40), Color(0.94, 0.94, 0.96)][k % 5]
			b.rect(Rect2(cp2, Vector2(4.0, 3.0)), ccol)
		# carved festival pumpkins flanking the stage and the roaster cart
		m._draw_cast_pumpkin(b, Vector2(st.position.x + 18.0, st.end.y + 12.0), 3.1, t)
		m._draw_cast_pumpkin(b, Vector2(st.end.x - 18.0, st.end.y + 12.0), 4.2, t)
		m._draw_cast_pumpkin(b, Vector2(rc.x + 58.0, rr.end.y + 18.0), 5.3, t)
		m._draw_cast_pumpkin(b, Vector2(rc.x - 84.0, rr.end.y + 16.0), 6.4, t)
	# chestnut shells, autumn fallen leaves and confetti scattered all along the street
	var cy := floorf((vt - 20.0) / 90.0) * 90.0
	while cy < vb + 20.0:
		var e: Vector2 = m.walk_edges(cy)
		var n := fmod(absf(cy) * 0.173, 1.0)
		var cx := lerpf(e.x + 20.0, e.y - 20.0, n)
		b.circle(Vector2(cx, cy), 2.4, Color(0.40, 0.22, 0.12, 0.8))
		var cc: Color = [Color(0.96, 0.30, 0.36), Color(0.98, 0.84, 0.28), Color(0.36, 0.64, 0.92), Color(0.52, 0.80, 0.40)][int(absf(cy) / 90.0) % 4]
		b.rect(Rect2(lerpf(e.x + 20.0, e.y - 20.0, fmod(n * 7.3, 1.0)), cy + 30.0, 4.0, 3.0), cc)
		# fallen leaf drifts along walls
		m._draw_autumn_leaves(b, Vector2(e.x + 8.0, cy + 15.0), absf(cy) * 0.05)
		m._draw_autumn_leaves(b, Vector2(e.y - 8.0, cy + 55.0), absf(cy) * 0.07 + 3.0)
		# doorstep jack-o'-lanterns along the street
		if int(absf(cy) / 90.0) % 3 == 0:
			var west_side: bool = (int(absf(cy) / 90.0) % 6 == 0)
			var px: float = e.x - 12.0 if west_side else e.y + 12.0
			m._draw_cast_pumpkin(b, Vector2(px, cy + 45.0), absf(cy) * 0.03, t)
		cy += 90.0
	# the lanterns' glow on the ground under each string
	for ly: float in LevelBuild.CAST_LANTERN_YS:
		if ly < vt - 120.0 or ly > vb + 120.0:
			continue
		var le: Vector2 = m.walk_edges(ly)
		var lx := le.x + 40.0
		while lx < le.y - 30.0:
			b.circle(Vector2(lx, ly + 10.0), 50.0, Color(1.0, 0.72, 0.36, 0.09))
			b.circle(Vector2(lx, ly + 10.0), 26.0, Color(1.0, 0.78, 0.44, 0.08))
			lx += 70.0
	b.flush(m._wc)


# a pool of warm light on the overhead layer, fading out from the middle in
# thin rings; its colour divided by the night's tint, so it comes out warm
static func _glow(b: ShapeBatch, at: Vector2, r: float, peak: float) -> void:
	for ring in range(7):
		var f := float(ring) / 6.0
		b.circle(at, lerpf(r, r * 0.2, f), Color(2.0, 1.36, 0.52, 0.008 + f * f * peak))


# La Castanyada's lantern strings, drawn over everyone: a wire from balcony to
# balcony, sagging, with paper lanterns on it, lit
static func _draw_lanterns(m: Node2D, c: CanvasItem) -> void:
	var b := ShapeBatch.new(c)
	var t := AnimClock.msec() / 1000.0
	var cols := [Color(0.96, 0.46, 0.20), Color(0.98, 0.80, 0.30), Color(0.90, 0.28, 0.30), Color(0.60, 0.80, 0.40)]
	# The festival's lights, here rather than on the ground so the night's
	# blue grade does not drown them (their colours are divided by the
	# night's tint, so they come out warm under it). Every stall lit: a warm pool spilling
	# off its counter, and the bulbs strung along its front
	for si in range(m.stalls.size()):
		var sp: Vector2 = m.stalls[si]
		var into := 1.0 if sp.x < m.walk_cx else -1.0
		var pool := sp + Vector2(into * 50.0, 0.0)
		_glow(b, pool, 130.0, 0.11)
		for k in range(5):
			var bp := sp + Vector2(into * 50.0, -44.0 + float(k) * 22.0)
			b.circle(bp, 6.0, Color(2.00, 1.56, 0.72, 0.22))
			b.circle(bp, 2.4, Color(2.00, 1.75, 1.05, 0.9))
	# the fronts along the street, lamp-lit: a wall lantern every so often,
	# alternating sides, and the light from open doorways and shop windows
	var fy := floorf((m.START_Y + 100.0) / 170.0) * 170.0
	while fy > m.GATE_Y + 60.0:
		var fe: Vector2 = m.walk_edges(fy)
		var k := int(absf(fy) / 170.0)
		var west := k % 2 == 0
		var fx: float = fe.x if west else fe.y
		var into := 1.0 if west else -1.0
		if k % 3 != 2:
			# a doorway's or a window's glow out across the pavement
			_glow(b, Vector2(fx, fy + 30.0), 90.0, 0.09)
			b.rect(Rect2(fx - (10.0 if west else 0.0), fy + 12.0, 10.0, 36.0), Color(2.00, 1.45, 0.59, 0.55))
		else:
			# a wall lantern, a fanal on its bracket
			_glow(b, Vector2(fx + into * 10.0, fy), 110.0, 0.11)
			b.line(Vector2(fx, fy), Vector2(fx + into * 10.0, fy), Color(0.12, 0.10, 0.10), 2.0)
			b.circle(Vector2(fx + into * 10.0, fy), 5.0, Color(2.00, 1.71, 0.92))
		fy -= 170.0
	# the roaster's fire, the brightest light in the plaça
	_glow(b, LevelBuild.CAST_ROASTER_AT + Vector2(-26.0, 6.0), 230.0, 0.07)
	var fr: Rect2 = m._freedom_rect()
	var ys: Array[float] = []
	ys.append_array(LevelBuild.CAST_LANTERN_YS)
	var n_walk := ys.size()
	# and three more over the festival yard off the leash, wall to wall
	ys.append_array(yard_strings(m))
	for i in range(ys.size()):
		var ly: float = ys[i]
		var e: Vector2 = m.walk_edges(ly) if i < n_walk else Vector2(fr.position.x - 10.0, fr.end.x + 10.0)
		var a := Vector2(e.x - 10.0, ly - 20.0)
		var z := Vector2(e.y + 10.0, ly + 20.0)
		var prev := a
		for k in range(1, 13):
			var f := float(k) / 12.0
			var q := a.lerp(z, f) + Vector2(0, sin(f * PI) * 26.0)
			b.line(prev, q, Color(0.14, 0.12, 0.12, 0.8), 1.6)
			prev = q
		for k in range(1, 9):
			var f := float(k) / 9.0
			var q := a.lerp(z, f) + Vector2(0, sin(f * PI) * 26.0 + 6.0)
			var col: Color = cols[(k + i) % 4]
			var flick := 0.9 + 0.1 * sin(t * 3.0 + float(k + i))
			b.circle(q, 20.0, Color(col.r, col.g, col.b, 0.22 * flick))
			b.circle(q, 13.0, Color(col.r, col.g, col.b, 0.35 * flick))
			b.circle(q, 8.0, col.lightened(0.2))
			b.circle(q + Vector2(-2, -2), 3.0, Color(1.0, 0.95, 0.80, 0.8 * flick))
	b.flush()


# La Castanyada's off-leash plaça is the festival's own yard, not El Gòtic's
# square again: a timber dance floor laid on the paving, the lantern strings'
# light on the ground under them (the strings are the overhead layer's), lit
# windows all round, chestnut shells, paper cones and confetti everywhere.
# The planters are the castanyeres' braziers (park props).
static func yard_strings(m: Node2D) -> Array[float]:
	return [m.GATE_Y - 170.0, m.GATE_Y - 330.0, m.GATE_Y - 490.0]


static func _draw_yard(m: Node2D, c: Object, r: Rect2) -> void:
	var b := ShapeBatch.new()
	# the dance floor: boards on the paving, a rope ring for the sardana
	var df := Rect2(r.get_center().x - 170.0, m.GATE_Y - 420.0, 340.0, 220.0)
	b.rect(Rect2(df.position + m.LIGHT * 6.0, df.size), Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.2))
	b.rect(df, Color(0.50, 0.36, 0.24))
	var bx := df.position.x + 20.0
	while bx < df.end.x:
		b.line(Vector2(bx, df.position.y), Vector2(bx, df.end.y), Color(0.40, 0.28, 0.18), 2.0)
		bx += 20.0
	b.line(df.position, Vector2(df.end.x, df.position.y), Color(0.64, 0.48, 0.32), 3.0)
	# concentric sardana dance ring marked on the wood
	var df_c := df.get_center()
	b.circle(df_c, 58.0, Color(0.38, 0.26, 0.16))
	b.circle(df_c, 56.0, Color(0.50, 0.36, 0.24))
	b.circle(df_c, 54.0, Color(0.86, 0.78, 0.62, 0.7))
	b.circle(df_c, 52.0, Color(0.50, 0.36, 0.24))
	b.circle(df_c, 24.0, Color(0.86, 0.78, 0.62, 0.45))
	# dancers' coats and bags piled in the center of the sardana circle
	b.circle(df_c + Vector2(-4.0, 2.0), 7.0, Color(0.26, 0.34, 0.42))
	b.circle(df_c + Vector2(3.0, -2.0), 6.0, Color(0.68, 0.24, 0.20))
	b.circle(df_c + Vector2(1.0, 4.0), 5.5, Color(0.46, 0.38, 0.26))
	m._draw_cast_pumpkin(b, Vector2(r.position.x + 24.0, m.GATE_Y - 24.0), 1.0, AnimClock.msec() / 1000.0)
	m._draw_cast_pumpkin(b, Vector2(r.end.x - 24.0, m.GATE_Y - 24.0), 2.0, AnimClock.msec() / 1000.0)
	# the lanterns' light on the ground under each string
	for ly: float in yard_strings(m):
		var lx := r.position.x + 60.0
		while lx < r.end.x - 40.0:
			b.circle(Vector2(lx, ly + 16.0), 56.0, Color(1.0, 0.72, 0.36, 0.08))
			b.circle(Vector2(lx, ly + 16.0), 28.0, Color(1.0, 0.78, 0.44, 0.08))
			lx += 92.0
	# lit windows in the house fronts round three sides
	var wx := r.position.x + 30.0
	while wx < r.end.x - 20.0:
		b.rect(Rect2(wx, r.position.y - 36.0, 16.0, 20.0), Color(1.0, 0.78, 0.42, 0.75))
		b.circle(Vector2(wx + 8.0, r.position.y + 6.0), 40.0, Color(1.0, 0.72, 0.38, 0.06))
		wx += 75.0
	for sx: float in [r.position.x, r.end.x]:
		var wy := r.position.y + 40.0
		while wy < r.end.y - 80.0:
			b.rect(Rect2(sx - (30.0 if sx < r.get_center().x else -14.0), wy, 16.0, 20.0), Color(1.0, 0.78, 0.42, 0.75))
			b.circle(Vector2(sx, wy + 10.0), 40.0, Color(1.0, 0.72, 0.38, 0.06))
			wy += 65.0
	# chestnut shells, dropped paper cones and confetti
	for k in range(140):
		var h := fmod(float(k) * 0.6180339, 1.0)
		var h2 := fmod(float(k) * 0.4142135 + 0.3, 1.0)
		var at := Vector2(lerpf(r.position.x + 20.0, r.end.x - 20.0, h), lerpf(r.position.y + 20.0, r.end.y - 30.0, h2))
		if k % 3 == 0:
			b.circle(at, 2.6, Color(0.40, 0.22, 0.12, 0.85))
		elif k % 11 == 1:
			b.polygon(PackedVector2Array([at + Vector2(-5, -6), at + Vector2(5, -6), at + Vector2(0, 8)]), Color(0.90, 0.86, 0.76))
		else:
			var cc: Color = [Color(0.96, 0.30, 0.36), Color(0.98, 0.84, 0.28), Color(0.36, 0.64, 0.92),
				Color(0.52, 0.80, 0.40), Color(0.94, 0.94, 0.96)][k % 5]
			b.rect(Rect2(at, Vector2(4.0, 3.0)), cc)
	b.flush(c)


# --- main's walk hooks (main.WALK_MODULES) ---------------------------------------

# the street and the plaça, up to the gate
static func draw_live(m: Node2D, _wc: ShapeBatch, vt: float, vb: float) -> void:
	_draw_street(m, maxf(vt, m.GATE_Y - 30.0), vb)


# the lantern strings and every light, over everyone
static func draw_overhead(m: Node2D, c: CanvasItem) -> void:
	_draw_lanterns(m, c)


# the festival yard on the off-leash plaça
static func draw_yard(m: Node2D, c: Object, r: Rect2) -> void:
	_draw_yard(m, c, r)
