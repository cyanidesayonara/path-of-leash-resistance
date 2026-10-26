class_name Passeig
extends RefCounted

# WALK: PASSEIG MARÍTIM (the seafront). Its drawing as static functions over
# main's state (main.WALK_MODULES): the cross-section from the sea to the
# blocks behind the promenade, the old works and its chimney, the showers,
# the lifeguard tower, the volleyball court and the chiringuitos, the towels
# on the sand and the recycling stations. The dog beach past the gate is the
# beach freedom kind, which other walks share, so it stays in main.

const ShapeBatch := preload("res://systems/shape_batch.gd")
const LevelBuild := preload("res://world/level_build.gd")
const Surfaces := preload("res://world/surfaces.gd")

# A BEACH TOWEL: striped across both ends, fringed, and either someone lying
# on it in the sun or the things they left (flip-flops, a paperback, the sun
# cream). In rain or snow nobody is sunbathing: the towel is left out, wet or
# dusted white. Drawing only; where a towel is and what it does stays put.
const TOWEL_SKINS := [Color(0.94, 0.78, 0.64), Color(0.80, 0.60, 0.44), Color(0.58, 0.40, 0.28), Color(0.96, 0.70, 0.60)]
const TOWEL_HAIR := [Color(0.20, 0.14, 0.10), Color(0.62, 0.42, 0.20), Color(0.86, 0.74, 0.44), Color(0.12, 0.10, 0.10)]
const TOWEL_SUITS := [Color(0.16, 0.30, 0.62), Color(0.86, 0.26, 0.30), Color(0.12, 0.52, 0.46), Color(0.96, 0.62, 0.20)]


# THE BLOCKS BEHIND THE SEAFRONT, from above: their flat roofs. Tiled
# terraces inside a parapet, a stairwell hut and a water tank or two, a
# sunshade or a washing line, with a narrow street between blocks. Hashed from
# the block's index, so the same walk has the same skyline every visit.
static func _roofs(m: Node2D, vt: float, vb: float) -> void:
	var b := ShapeBatch.new()
	var roofs := [Color(0.76, 0.70, 0.62), Color(0.66, 0.44, 0.34), Color(0.62, 0.62, 0.60), Color(0.82, 0.78, 0.70)]
	var y: float = m.START_Y + 560.0
	var k := 0
	while y > m.GATE_Y - 40.0:
		var h := 170.0 + fmod(float(k) * 61.0, 110.0)
		var top := y - h
		# the old works stands on this stretch, and draws itself
		var works := top < -2000.0 and y > -2700.0
		if y > vt - 40.0 and top < vb + 40.0 and not works:
			var r := Rect2(1196.0, top + 8.0, 420.0, h - 16.0)
			var col: Color = roofs[k % roofs.size()]
			b.rect(r, col.darkened(0.25))
			b.rect(r.grow(-5.0), col)
			# the tiles of a roof terrace, in a grid
			var gy := r.position.y + 18.0
			while gy < r.end.y - 6.0:
				b.line(Vector2(r.position.x + 5.0, gy), Vector2(r.position.x + 120.0, gy), col.darkened(0.08), 1.0)
				gy += 18.0
			var hut := Rect2(r.position.x + 26.0 + fmod(float(k) * 29.0, 40.0), r.position.y + 20.0 + fmod(float(k) * 43.0, maxf(1.0, r.size.y - 80.0)), 34.0, 28.0)
			b.rect(Rect2(hut.position + m.LIGHT * 8.0, hut.size), Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.22))
			b.rect(hut, Color(0.70, 0.66, 0.60))
			b.rect(Rect2(hut.position, Vector2(hut.size.x, 5.0)), Color(0.80, 0.76, 0.70))
			if k % 2 == 0:
				var tank := Vector2(r.position.x + 82.0, hut.end.y + 22.0)
				if tank.y < r.end.y - 14.0:
					b.circle(tank + m.LIGHT * 6.0, 10.0, Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.22))
					b.circle(tank, 10.0, Color(0.30, 0.30, 0.32))
					b.circle(tank + Vector2(-2.0, -2.0), 5.0, Color(0.44, 0.44, 0.46))
			if k % 3 == 1:
				# a washing line across the terrace, things pegged on it
				var wy := r.end.y - 20.0
				b.line(Vector2(r.position.x + 12.0, wy), Vector2(r.position.x + 110.0, wy), Color(0.86, 0.86, 0.84, 0.8), 1.0)
				for p in range(4):
					var wc := [Color(0.92, 0.92, 0.90), Color(0.40, 0.56, 0.78), Color(0.86, 0.46, 0.40)][(p + k) % 3] as Color
					b.rect(Rect2(r.position.x + 20.0 + float(p) * 22.0, wy, 12.0, 8.0), wc)
			elif k % 3 == 2:
				b.circle(Vector2(r.position.x + 70.0, r.end.y - 40.0) + m.LIGHT * 10.0, 20.0, Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.2))
				b.circle(Vector2(r.position.x + 70.0, r.end.y - 40.0), 20.0, Color(0.88, 0.56, 0.30))
				b.circle(Vector2(r.position.x + 70.0, r.end.y - 40.0), 3.0, Color(0.40, 0.34, 0.28))
		y = top
		k += 1
	b.flush(m._wc)


static func _works(m: Node2D, vt: float, vb: float) -> void:
	# THE OLD DISTILLERY. The landmark of this stretch of coast is a low
	# industrial works with one very tall, very slender brick chimney, and from
	# above the chimney is almost nothing - a small circle. What makes it read
	# as a landmark is its SHADOW: the one light throws it right across the
	# promenade, so you walk through it, which is the only way a tall thing can
	# announce itself in a top-down game.
	#
	# The real works carries a liqueur brand that is very much still trading,
	# so nothing of it is borrowed but the architecture: an old seafront
	# distillery is a shed with a chimney, and that is vernacular rather than
	# anybody's property. The sign reads LA FABRICA - the factory.
	const WORKS_Y := -2450.0
	if WORKS_Y < vt - 900.0 or WORKS_Y > vb + 900.0:
		return
	var wx := 1190.0
	# the sheds: low, pale rendered walls with ribbed roofs
	for i in range(3):
		var sy := WORKS_Y + float(i) * 240.0 - 240.0
		m._wc.draw_rect(Rect2(wx - 60.0, sy, 190.0, 200.0), Color(0.80, 0.76, 0.66))
		# barrel-vaulted roof ribs, which is what says "works" and not "flats"
		for r in range(9):
			var ry := sy + 14.0 + float(r) * 21.0
			m._wc.draw_line(Vector2(wx - 54.0, ry), Vector2(wx + 118.0, ry),
				Color(0.62, 0.63, 0.62), 5.0)
		m._wc.draw_rect(Rect2(wx - 60.0, sy, 190.0, 200.0), Color(0.32, 0.29, 0.25), false, 2.5)
	# the chimney: a tapering brick tower, and the long shadow that sells it
	var cx := wx - 34.0
	var cy := WORKS_Y
	m.cast_shadow(m._wc, Vector2(cx, cy), 15.0, 340.0, 0.26)
	m._wc.draw_circle(Vector2(cx, cy), 17.0, Color(0.52, 0.34, 0.25))
	m._wc.draw_circle(Vector2(cx, cy), 12.5, Color(0.63, 0.42, 0.30))
	m._wc.draw_circle(Vector2(cx - 2.0, cy - 2.0), 8.0, Color(0.72, 0.50, 0.36))
	m._wc.draw_circle(Vector2(cx, cy), 5.0, Color(0.17, 0.14, 0.13))
	# a painted sign on the seaward shed wall, facing the walk
	m._draw_world_text(Vector2(wx + 16.0, WORKS_Y + 176.0), "LA FÀBRICA", 17, "paint", 9.0)


# THE CHIRINGUITOS. Each terrace was tables on the paving under a pale
# sheet, against flat grey (#151). Now each stands on its own timber deck
# with oleanders in planters along the back, and the bar itself at the end:
# a hut with a counter and stools facing the tables, thatched at one and
# under striped canvas at the other.
static func _landmarks(m: Node2D, vt: float, vb: float) -> void:
	var rb := ShapeBatch.new()
	for sp: Vector2 in LevelBuild.BEACH_SHOWERS:
		if sp.y > vt - 60.0 and sp.y < vb + 60.0:
			_access_ramp(m, rb, 380.0, 345.0, sp.y, 32.0)
	var tw: Vector2 = LevelBuild.BEACH_TOWER
	if tw.y > vt - 120.0 and tw.y < vb + 80.0:
		_access_ramp(m, rb, 380.0, 320.0, tw.y, 32.0)
	rb.flush(m._wc)
	if _drawn_window(LevelBuild.BEACH_COURT, vt, vb):
		_volley_court(m, LevelBuild.BEACH_COURT)
	for sp: Vector2 in LevelBuild.BEACH_SHOWERS:
		if sp.y > vt - 60.0 and sp.y < vb + 60.0:
			m._draw_beach_shower(m._wc, sp)
	if tw.y > vt - 120.0 and tw.y < vb + 80.0:
		m._draw_lifeguard_tower(m._wc, tw, true, false)
	for i in range(LevelBuild.BEACH_BARS.size()):
		var bar: Rect2 = LevelBuild.BEACH_BARS[i]
		var cn: Rect2 = m.canopies[i] if i < m.canopies.size() else bar
		var whole := cn.merge(bar)
		var deck := Rect2(992.0, whole.position.y - 12.0, 198.0, whole.size.y + 24.0)
		if not _drawn_window(deck, vt, vb):
			continue
		var b := ShapeBatch.new()
		b.rect(deck, Color(0.56, 0.40, 0.27))
		var dx := deck.position.x + 6.0
		while dx < deck.end.x:
			b.line(Vector2(dx, deck.position.y), Vector2(dx, deck.end.y), Color(0.46, 0.32, 0.21), 1.5)
			dx += 11.0
		b.rect(Rect2(deck.position.x, deck.position.y, 4.0, deck.size.y), Color(0.40, 0.28, 0.18))
		b.rect(Rect2(deck.position.x, deck.position.y, deck.size.x, 3.0), Color(0.40, 0.28, 0.18))
		b.rect(Rect2(deck.position.x, deck.end.y - 3.0, deck.size.x, 3.0), Color(0.40, 0.28, 0.18))
		# planters along the back of the deck, oleander in flower
		var py := cn.position.y + 30.0
		while py < cn.end.y - 20.0:
			var box := Rect2(1154.0, py - 22.0, 28.0, 44.0)
			b.rect(Rect2(box.position + m.LIGHT * 5.0, box.size), Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.2))
			b.rect(box, Color(0.62, 0.36, 0.24))
			b.rect(box.grow(-3.0), Color(0.34, 0.26, 0.18))
			for k in range(3):
				var lp := Vector2(box.get_center().x + (-4.0 if k % 2 == 0 else 4.0), box.position.y + 9.0 + float(k) * 13.0)
				b.circle(lp, 9.0, Color(0.22, 0.40, 0.24))
				b.circle(lp - m.LIGHT * 3.0, 5.0, Color(0.32, 0.52, 0.30))
				b.circle(lp + Vector2(3.0, -2.0), 2.2, Color(0.92, 0.46, 0.62) if i == 0 else Color(0.96, 0.92, 0.94))
			py += 80.0
		_bar_hut(m, b, bar, i == 0, bar.position.y > cn.position.y)
		# the name along the front of the roof: straight on the thatch, on a
		# painted board over the stripes
		var face_y := bar.end.y if bar.position.y < cn.position.y else bar.position.y
		var sign_at := Vector2(bar.position.x + 66.0, face_y + (-8.0 if bar.position.y < cn.position.y else 22.0))
		if i == 1:
			b.rect(Rect2(sign_at.x - 50.0, sign_at.y - 13.0, 100.0, 17.0), Color(0.12, 0.22, 0.40))
		b.flush(m._wc)
		m._wc.draw_string(m.font, sign_at - Vector2(50.0, 0.0), "XIRINGUITO", HORIZONTAL_ALIGNMENT_CENTER, 100.0, 12,
			Color(0.98, 0.96, 0.88) if i == 1 else Color(0.30, 0.18, 0.10))


static func _access_ramp(m: Node2D, b: ShapeBatch, from_x: float, to_x: float, y: float, w: float = 32.0) -> void:
	var rlen := from_x - to_x
	var ramp := Rect2(to_x, y - w * 0.5, rlen, w)
	b.rect(Rect2(ramp.position + m.LIGHT * 3.0, ramp.size), Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.16))
	b.rect(ramp, Color(0.48, 0.28, 0.22))
	var rx := to_x + 3.0
	while rx < from_x:
		b.line(Vector2(rx, ramp.position.y), Vector2(rx, ramp.end.y), Color(0.34, 0.19, 0.15), 1.5)
		rx += 9.0
	b.line(Vector2(to_x, ramp.position.y), Vector2(from_x, ramp.position.y), Color(0.38, 0.22, 0.17), 2.0)
	b.line(Vector2(to_x, ramp.end.y), Vector2(from_x, ramp.end.y), Color(0.38, 0.22, 0.17), 2.0)
	b.circle(Vector2(to_x + 2.0, y - w * 0.3), 3.0, Color(0.85, 0.78, 0.62, 0.40))
	b.circle(Vector2(to_x + 2.0, y + w * 0.3), 3.0, Color(0.85, 0.78, 0.62, 0.40))


static func _drawn_window(r: Rect2, vt: float, vb: float) -> bool:
	return r.end.y > vt - 60.0 and r.position.y < vb + 60.0


# the bar hut: its roof from above, the counter along the side that faces the
# terrace, and the stools in front (none where a terrace chair already is)
static func _bar_hut(m: Node2D, b: ShapeBatch, r: Rect2, thatch: bool, faces_north: bool) -> void:
	b.rect(Rect2(r.position + m.LIGHT * 10.0, r.size), Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.24))
	var front_y := r.position.y if faces_north else r.end.y
	var out := -1.0 if faces_north else 1.0
	# the counter, a timber top a little proud of the hut
	var counter := Rect2(r.position.x + 8.0, front_y - (10.0 if faces_north else -2.0), r.size.x - 22.0, 8.0)
	b.rect(counter, Color(0.48, 0.32, 0.20))
	b.rect(Rect2(counter.position.x, counter.position.y + 1.0, counter.size.x, 2.5), Color(0.66, 0.48, 0.32))
	var sx := counter.position.x + 12.0
	while sx < counter.end.x - 6.0:
		var st := Vector2(sx, front_y + out * 16.0)
		var clear := true
		for ch: Vector2 in m.chairs:
			if ch.distance_to(st) < 20.0:
				clear = false
		for tb: Vector2 in m.tables:
			if tb.distance_to(st) < 24.0:
				clear = false
		if clear:
			b.circle(st + m.LIGHT * 2.0, 5.0, Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.2))
			b.circle(st, 4.6, Color(0.30, 0.24, 0.18))
			b.circle(st + Vector2(-0.8, -0.8), 3.2, Color(0.56, 0.42, 0.28))
		sx += 22.0
	# the roof
	if thatch:
		b.rect(r, Color(0.66, 0.52, 0.30))
		b.rect(r.grow(-4.0), Color(0.80, 0.66, 0.40))
		var ridge := r.get_center().y
		var tx := r.position.x + 5.0
		var k := 0
		while tx < r.end.x - 4.0:
			var ln := 6.0 + fmod(float(k) * 3.7, 5.0)
			b.line(Vector2(tx, r.position.y + 4.0), Vector2(tx + 1.5, r.position.y + 4.0 + ln), Color(0.62, 0.48, 0.26), 1.5)
			b.line(Vector2(tx + 3.0, r.end.y - 4.0), Vector2(tx + 1.5, r.end.y - 4.0 - ln), Color(0.62, 0.48, 0.26), 1.5)
			tx += 5.0
			k += 1
		b.line(Vector2(r.position.x + 6.0, ridge), Vector2(r.end.x - 6.0, ridge), Color(0.56, 0.42, 0.22), 4.0)
		b.line(Vector2(r.position.x + 6.0, ridge - 2.0), Vector2(r.end.x - 6.0, ridge - 2.0), Color(0.90, 0.78, 0.52), 1.5)
	else:
		b.rect(r, Color(0.20, 0.38, 0.62))
		var stx := r.position.x
		var k := 0
		while stx < r.end.x:
			if k % 2 == 0:
				b.rect(Rect2(stx, r.position.y, minf(12.0, r.end.x - stx), r.size.y), Color(0.95, 0.94, 0.90))
			stx += 12.0
			k += 1
		# the scalloped hem over the counter
		var hx := r.position.x + 6.0
		while hx < r.end.x:
			b.circle(Vector2(hx, front_y), 6.0, Color(0.20, 0.38, 0.62))
			hx += 12.0
		b.line(Vector2(r.position.x, r.get_center().y), Vector2(r.end.x, r.get_center().y), Color(0, 0, 0, 0.12), 2.0)


# The volleyball court on the sand: a raked court inside its tape, scuffed
# where the players land, and the net across the middle on two posts (the
# posts are poles; the net is drawn over the sand, so she goes under it).
static func _volley_court(m: Node2D, court: Rect2) -> void:
	var b := ShapeBatch.new()
	b.rect(court, Color(0.92, 0.86, 0.70))
	var cy := court.get_center().y
	# parallel sand rake comb ridges across court
	var ry := court.position.y + 14.0
	while ry < court.end.y - 8.0:
		if absf(ry - cy) > 12.0:
			b.line(Vector2(court.position.x + 4.0, ry), Vector2(court.end.x - 4.0, ry), Color(0.85, 0.79, 0.63, 0.35), 1.0)
			b.line(Vector2(court.position.x + 4.0, ry + 1.0), Vector2(court.end.x - 4.0, ry + 1.0), Color(0.96, 0.90, 0.75, 0.25), 1.0)
		ry += 16.0
	for k in range(9):
		var sp := court.position + Vector2(fmod(float(k) * 47.0, court.size.x - 20.0) + 10.0,
			fmod(float(k) * 83.0, court.size.y - 20.0) + 10.0)
		b.circle(sp, 3.0 + fmod(float(k) * 1.7, 3.0), Color(0.78, 0.71, 0.55, 0.45))
	var tape := Color(0.20, 0.44, 0.76)
	b.line(court.position, Vector2(court.end.x, court.position.y), tape, 3.0)
	b.line(Vector2(court.position.x, court.end.y), court.end, tape, 3.0)
	b.line(court.position, Vector2(court.position.x, court.end.y), tape, 3.0)
	b.line(Vector2(court.end.x, court.position.y), court.end, tape, 3.0)
	# corner anchor plates
	for cp: Vector2 in [court.position, Vector2(court.end.x, court.position.y), Vector2(court.position.x, court.end.y), court.end]:
		b.circle(cp, 3.5, Color(0.18, 0.38, 0.68))
		b.circle(cp, 1.8, Color(0.85, 0.85, 0.88))
	var posts := LevelBuild.beach_net_posts()
	var a: Vector2 = posts[0]
	var e: Vector2 = posts[1]
	# referee tall chair next to post e
	var ref_p := Vector2(court.end.x + 18.0, cy)
	b.rect(Rect2(ref_p + m.LIGHT * 16.0 - Vector2(6.0, 6.0), Vector2(12.0, 12.0)), Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.18))
	for off: Vector2 in [Vector2(-5, -5), Vector2(5, -5), Vector2(-5, 5), Vector2(5, 5)]:
		b.circle(ref_p + off, 1.8, Color(0.35, 0.35, 0.38))
	b.rect(Rect2(ref_p.x - 4.0, ref_p.y - 5.0, 8.0, 10.0), Color(0.24, 0.52, 0.80))
	b.line(Vector2(ref_p.x + 3.0, ref_p.y - 5.0), Vector2(ref_p.x + 3.0, ref_p.y + 5.0), Color(0.95, 0.95, 0.95), 2.5)
	# guy ropes out to their pegs, then the net's shadow, the mesh and its tape
	for p: Vector2 in [a, e]:
		var out := -1.0 if p.x < court.get_center().x else 1.0
		for dy: float in [-16.0, 16.0]:
			b.line(p, p + Vector2(out * 8.0, dy), Color(0.86, 0.84, 0.78, 0.8), 1.2)
	b.line(a + m.LIGHT * 22.0, e + m.LIGHT * 22.0, Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.18), 4.0)
	b.line(a, e, Color(0.16, 0.16, 0.18, 0.75), 5.0)
	var mx := a.x + 4.0
	while mx < e.x - 2.0:
		b.line(Vector2(mx, a.y - 2.5), Vector2(mx, a.y + 2.5), Color(0.92, 0.92, 0.90, 0.5), 1.0)
		mx += 4.0
	b.line(a + Vector2(0.0, -2.5), e + Vector2(0.0, -2.5), Color(0.97, 0.97, 0.95), 1.6)
	for p: Vector2 in [a, e]:
		b.circle(p + m.LIGHT * 4.0, 6.0, Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.22))
		b.circle(p, 5.5, Color(0.30, 0.30, 0.33))
		b.circle(p + Vector2(-1.2, -1.2), 3.2, Color(0.70, 0.72, 0.76))
	b.flush(m._wc)


static func _towel(m: Node2D, twd: Dictionary, i: int) -> void:
	var r: Rect2 = twd.rect
	var col: Color = twd.col
	var wx: String = Game.weather
	if wx == "rain":
		col = col.darkened(0.3)
	m._wc.draw_rect(r, col)
	# stripes across each end, and the fringe past them
	var stripe := Color(1, 1, 1, 0.55) if i % 2 == 0 else col.darkened(0.25)
	for e: float in [r.position.y + 8.0, r.end.y - 13.0]:
		m._wc.draw_rect(Rect2(r.position.x, e, r.size.x, 5.0), stripe)
	var fx := r.position.x + 3.0
	while fx < r.end.x - 1.0:
		m._wc.draw_line(Vector2(fx, r.position.y), Vector2(fx, r.position.y - 4.0), col.lightened(0.2), 1.2)
		m._wc.draw_line(Vector2(fx, r.end.y), Vector2(fx, r.end.y + 4.0), col.lightened(0.2), 1.2)
		fx += 5.0
	if wx == "snow":
		m._wc.draw_rect(r.grow(-3.0), Color(0.96, 0.97, 1.0, 0.55))
	var c := r.get_center()
	var basking: bool = twd.bather and wx != "rain" and wx != "snow" and not Game.night
	if basking:
		var skin: Color = TOWEL_SKINS[i % TOWEL_SKINS.size()]
		var suit: Color = TOWEL_SUITS[(i + 1) % TOWEL_SUITS.size()]
		var sh := Color(0, 0, 0, 0.18)
		# lying on their back, head at the top end: shadow, legs, arms, body
		m._wc.draw_line(c + Vector2(-4, 4) + m.LIGHT * 2.0, c + Vector2(-5, 30) + m.LIGHT * 2.0, sh, 6.0)
		m._wc.draw_line(c + Vector2(4, 4) + m.LIGHT * 2.0, c + Vector2(6, 30) + m.LIGHT * 2.0, sh, 6.0)
		for s: float in [-1.0, 1.0]:
			var foot := c + Vector2(s * (5.0 + float(i % 2)), 30.0)
			m._wc.draw_line(c + Vector2(s * 4.0, 4.0), foot, skin, 5.5)
			m._wc.draw_circle(foot, 2.8, skin)
			m._wc.draw_line(c + Vector2(s * 8.0, -14.0), c + Vector2(s * 11.0, 2.0), skin.darkened(0.06), 3.6)
			m._wc.draw_circle(c + Vector2(s * 11.0, 2.0), 2.2, skin.darkened(0.06))
		HumanAppearance.draw_torso(m._wc, c + Vector2(0, -8), Vector2.UP, Vector2(9.0, 8.0), skin)
		# the swimsuit: trunks, or a one-piece
		if i % 2 == 0:
			m._wc.draw_rect(Rect2(c.x - 6.0, c.y - 2.0, 12.0, 7.0), suit)
		else:
			m._wc.draw_colored_polygon(PackedVector2Array([c + Vector2(-6, -15), c + Vector2(6, -15),
				c + Vector2(6, 5), c + Vector2(-6, 5)]), suit)
		var head := c + Vector2(0, -24)
		HumanAppearance.draw_head(m._wc, head, Vector2.UP, 6.0, skin, TOWEL_HAIR[i % TOWEL_HAIR.size()],
			"long" if i % 2 == 1 else "short")
		# sunglasses on, eyes shut
		m._wc.draw_line(head + Vector2(-4.0, -2.2), head + Vector2(4.0, -2.2), Color(0.08, 0.08, 0.10), 2.2)
	else:
		# what they left: flip-flops at the foot, the paperback and the sun cream
		for s: float in [-1.0, 1.0]:
			var ff := Vector2(c.x + s * 6.0, r.end.y - 22.0)
			m._wc.draw_colored_polygon(HumanAppearance._disc_points(ff, Vector2(6.0, 3.0), Vector2.UP), Color(0.20, 0.62, 0.86))
			m._wc.draw_line(ff + Vector2(0, -3), ff + Vector2(s * 2.0, 1.0), Color(0.96, 0.96, 0.94), 1.0)
		m._wc.draw_rect(Rect2(c.x - 8.0, c.y - 18.0, 13.0, 9.0), Color(0.94, 0.90, 0.80))
		m._wc.draw_line(Vector2(c.x - 1.5, c.y - 18.0), Vector2(c.x - 1.5, c.y - 9.0), Color(0.6, 0.55, 0.5), 1.0)
		m._wc.draw_rect(Rect2(c.x + 7.0, c.y - 4.0, 5.0, 11.0), Color(0.98, 0.84, 0.30))
		m._wc.draw_rect(Rect2(c.x + 7.5, c.y - 6.0, 4.0, 2.5), Color(0.90, 0.40, 0.20))


# Barcelona seafront selective recycling station:
# three color-coded cylindrical bins (yellow for envasos/plastics, grey for resta, blue for paper)
# on a stainless steel mounting bar. The bin obstacle center remains at bn.
static func _recycling_station(m: Node2D, c: Object, bn: Vector2) -> void:
	m.cast_shadow(c, bn, 14.0, 22.0)
	var b := ShapeBatch.new()
	# horizontal brushed stainless mounting bar
	b.line(bn + Vector2(-15.0, 0), bn + Vector2(15.0, 0), Color(0.70, 0.72, 0.74), 3.0)
	# post footing
	b.circle(bn, 3.5, Color(0.38, 0.40, 0.42))
	# 1. Left bin: yellow (envasos / packaging)
	var p0 := bn + Vector2(-12.0, 0)
	b.circle(p0, 6.5, Color(0.22, 0.24, 0.22))
	b.circle(p0, 5.5, Color(0.88, 0.74, 0.16))
	b.circle(p0 + Vector2(-1.2, -1.2), 3.5, Color(0.96, 0.84, 0.26))
	b.rect(Rect2(p0.x - 3.0, p0.y - 1.2, 6.0, 2.4), Color(0.12, 0.12, 0.14))
	# 2. Center bin: grey (resta / general)
	var p1 := bn + Vector2(0.0, 0)
	b.circle(p1, 6.5, Color(0.22, 0.24, 0.22))
	b.circle(p1, 5.5, Color(0.48, 0.48, 0.46))
	b.circle(p1 + Vector2(-1.2, -1.2), 3.5, Color(0.60, 0.60, 0.58))
	b.rect(Rect2(p1.x - 3.0, p1.y - 1.2, 6.0, 2.4), Color(0.12, 0.12, 0.14))
	# 3. Right bin: blue (paper i cartro / paper)
	var p2 := bn + Vector2(12.0, 0)
	b.circle(p2, 6.5, Color(0.22, 0.24, 0.22))
	b.circle(p2, 5.5, Color(0.18, 0.46, 0.75))
	b.circle(p2 + Vector2(-1.2, -1.2), 3.5, Color(0.30, 0.58, 0.88))
	b.line(p2 + Vector2(-3.5, 0), p2 + Vector2(3.5, 0), Color(0.12, 0.12, 0.14), 1.4)
	# knotted dog waste bag on center bin handle
	b.circle(p1 + Vector2(6.5, 3.5), 3.0, Color(0.78, 0.78, 0.74, 0.85))
	b.line(p1 + Vector2(5.0, 1.5), p1 + Vector2(6.5, 3.5), Color(0.70, 0.70, 0.66), 1.4)
	b.flush(c)


# --- main's walk hooks (main.WALK_MODULES) ---------------------------------------

# no edge layer: the cross-section below runs out past the building line
static func draw_edge_layer(_m: Node2D, _c: Object, _vt: float, _vb: float) -> void:
	pass


# the ground from the sea to the blocks, in place of main's lawn and walkway
static func draw_cross_section(m: Node2D, wc: ShapeBatch, top: float, bottom: float, ctop: float, vt: float, vb: float) -> void:
	# Passeig Maritim, west to east: sea, sand, boardwalk, bike
	# path, pavement, cafe strip, buildings
	# The sea, and it is a Mediterranean one: turquoise, not the grey-blue
	# it was. A shallower band nearer the shore, because that is where the
	# colour actually comes from - sand under clear water.
	wc.draw_rect(Rect2(-400, ctop, 630, bottom - ctop), m.BEACH_SEA_DEEP)
	wc.draw_rect(Rect2(m.BEACH_GATE_SHORE_X - m.BEACH_SHALLOW_W, ctop, m.BEACH_SHALLOW_W, bottom - ctop), m.BEACH_SEA_SHALLOW)
	var wt := AnimClock.msec() / 1000.0
	var fy := top + 40.0
	while fy < bottom:
		if fy > vt and fy < vb:
			wc.draw_line(Vector2(72 + sin(fy * 0.011 + wt * 1.5) * 9.0, fy), Vector2(84 + sin(fy * 0.013 + wt * 1.5) * 9.0, fy + 70.0), Color(1, 1, 1, 0.25), 3.0)
		fy += 150.0
	wc.draw_rect(Rect2(230, ctop, 150, bottom - ctop), m.BEACH_SAND)
	# the wet sand at the waterline and the foam on it: the dog beach's
	# shore has both, so here they carry its shore on down the walk
	wc.draw_rect(Rect2(m.BEACH_GATE_SHORE_X, ctop, m.BEACH_WET_W, bottom - ctop), m.BEACH_WET)
	var foam := ShapeBatch.new()
	var fmy := maxf(ctop, vt - fmod(vt, 52.0) - 52.0)
	while fmy < minf(bottom, vb + 52.0):
		var fmx: float = m.BEACH_GATE_SHORE_X + 4.0 + sin(fmy * 0.02 + wt * 1.4) * 4.0
		var fml := 30.0 + 14.0 * (0.5 + 0.5 * sin(fmy * 0.037))
		foam.line(Vector2(fmx, fmy), Vector2(fmx - 2.0, fmy + fml), Color(1, 1, 1, 0.26), 3.0)
		fmy += 52.0
	# tide drift line: cockle shells (petxines), sea pebbles (codols), posidonia along waterline
	var tdy := maxf(ctop, vt - fmod(vt, 32.0) - 32.0)
	while tdy < minf(bottom, vb + 32.0):
		var tdx: float = m.BEACH_GATE_SHORE_X + m.BEACH_WET_W + sin(tdy * 0.041) * 3.0
		var pk := absi(int(tdy * 0.13)) % 4
		if pk == 0:
			# smooth rounded sea pebble
			foam.circle(Vector2(tdx + 1.5, tdy) + m.LIGHT * 1.2, 2.2, Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.18))
			foam.circle(Vector2(tdx + 1.5, tdy), 2.0, Color(0.50, 0.48, 0.44))
			foam.circle(Vector2(tdx + 0.8, tdy - 0.6), 1.0, Color(0.68, 0.66, 0.62))
		elif pk == 1:
			# Mediterranean cockle / tellin shell (petxina)
			foam.polygon(PackedVector2Array([
				Vector2(tdx + 2.0, tdy - 1.5), Vector2(tdx + 5.0, tdy),
				Vector2(tdx + 2.0, tdy + 1.5)
			]), Color(0.96, 0.93, 0.88))
		elif pk == 2:
			# smaller pinkish wedge shell
			foam.circle(Vector2(tdx - 1.0, tdy), 1.6, Color(0.95, 0.84, 0.80))
		else:
			# tiny posidonia sea kelp fleck
			foam.line(Vector2(tdx, tdy), Vector2(tdx + 3.0, tdy + 2.0), Color(0.28, 0.32, 0.20), 1.2)
		tdy += 32.0
	foam.flush(wc)
	# THE TIMBER DECK, nearest the sand. Planks laid across the walk with
	# alternating tones, fastener bolt pairs, and access ramps out to the sand.
	wc.draw_rect(Rect2(380, ctop, 110, bottom - ctop), Color(0.46, 0.26, 0.21))
	var bdeck := ShapeBatch.new()
	var py := minf(m.START_Y + 200.0, vb + 22.0 - fmod(vb, 22.0))
	while py > m.GATE_Y and py > vt - 22.0:
		if py < vb and py > vt:
			# plank fill tone variation
			var pcol: Color = [Color(0.46, 0.26, 0.21), Color(0.43, 0.24, 0.19), Color(0.48, 0.28, 0.23)][absi(int(py / 22.0)) % 3]
			bdeck.rect(Rect2(380.0, py - 20.0, 110.0, 20.0), pcol)
			# plank ends, running across the walk the way decking is laid
			bdeck.line(Vector2(380, py), Vector2(490, py), Color(0.32, 0.18, 0.14), 2.0)
			# countersunk bolt pairs near plank edges
			bdeck.circle(Vector2(385.0, py - 5.0), 1.0, Color(0.24, 0.12, 0.08))
			bdeck.circle(Vector2(385.0, py - 15.0), 1.0, Color(0.24, 0.12, 0.08))
			bdeck.circle(Vector2(485.0, py - 5.0), 1.0, Color(0.24, 0.12, 0.08))
			bdeck.circle(Vector2(485.0, py - 15.0), 1.0, Color(0.24, 0.12, 0.08))
		py -= 22.0
	bdeck.flush(wc)
	# the pale concrete path, with the dashed line down the middle of it
	wc.draw_rect(Rect2(490, ctop, 80, bottom - ctop), Color(0.82, 0.79, 0.73))
	var ddy := minf(m.START_Y + 200.0, vb + 64.0 - fmod(vb, 64.0))
	while ddy > m.GATE_Y and ddy > vt - 64.0:
		if ddy < vb and ddy > vt:
			wc.draw_line(Vector2(530, ddy), Vector2(530, ddy - 26.0), Color(0.97, 0.96, 0.93, 0.8), 3.0)
		ddy -= 64.0
	wc.draw_rect(Rect2(570, ctop, 410, bottom - ctop), Color(0.79, 0.76, 0.7))
	var sy := minf(m.START_Y + 200.0, vb + 150.0 - fmod(vb, 150.0))
	while sy > m.GATE_Y and sy > vt - 150.0:
		if sy < vb and sy > vt:
			wc.draw_line(Vector2(560, sy), Vector2(980, sy), Color(0.71, 0.68, 0.62), 2.0)
		sy -= 150.0
	wc.draw_rect(Rect2(980, ctop, 210, bottom - ctop), Color(0.76, 0.72, 0.65))
	# The building strip was at x>=1180, and the camera never sees past
	# x=1140 (zoom 1.28 on a fixed x=640) - so the whole landward side of
	# this walk was being drawn where nobody could look at it. Brought
	# inside the frame. A sideways phone sees further, and what it saw was
	# one flat grey (#151): the blocks' roofs now, from the building line
	# at the east wall, with the cafe strip running up to it.
	wc.draw_rect(Rect2(1190, ctop, 510, bottom - ctop), Color(0.35, 0.33, 0.31))
	_roofs(m, vt, vb)
	_works(m, vt, vb)
	# SQUARE CUT-OUTS in the paving, one under each palm. The promenade's
	# trees are not planted in a verge, they are set into the concrete in
	# orderly openings with a kerb round them, and that grid of squares
	# down the walk is a good part of what the place looks like.
	for ps: Vector2 in m.palm_spots:
		if ps.y < vt - 60.0 or ps.y > vb + 60.0:
			continue
		var cut := Rect2(ps.x - 27.0, ps.y - 27.0, 54.0, 54.0)
		wc.draw_rect(cut, Color(0.62, 0.58, 0.50))          # the kerb
		wc.draw_rect(cut.grow(-5.0), Color(0.40, 0.34, 0.26))  # the soil in it
		wc.draw_rect(cut, Color(0.34, 0.31, 0.27, 0.55), false, 2.0)
	wc.draw_line(Vector2(380, bottom), Vector2(380, m.GATE_Y), Color(0.55, 0.45, 0.32), 3.0)
	wc.draw_line(Vector2(490, bottom), Vector2(490, m.GATE_Y), m.COL_SEAM, 2.0)
	wc.draw_line(Vector2(570, bottom), Vector2(570, m.GATE_Y), m.COL_SEAM, 2.0)
	wc.draw_line(Vector2(980, bottom), Vector2(980, m.GATE_Y), m.COL_SEAM, 2.0)
	for t in m.tufts:
		if t.y > vt and t.y < vb and t.x > 110.0 and (t.x < 330.0 or t.x > 1000.0) and t.x < 1170.0:
			wc.draw_circle(t, 4.0, Color(0.78, 0.7, 0.54))
	for ti in range(m.towels.size()):
		if (m.towels[ti].rect as Rect2).end.y > vt - 40.0 and (m.towels[ti].rect as Rect2).position.y < vb + 40.0:
			_towel(m, m.towels[ti], ti)
	_landmarks(m, vt, vb)


# the cabins of both lifeguard towers stand over everyone
static func draw_overhead(m: Node2D, c: CanvasItem) -> void:
	m._draw_lifeguard_tower(c, LevelBuild.BEACH_TOWER, false, true)
	m._draw_lifeguard_tower(c, m.dog_beach_tower(), false, true)


# THE SEAFRONT HAS NO GRASS. Its cross-section is sea, sand, boardwalk,
# bike path, promenade, then cafe paving - so once the sea and the sand
# are ruled out, everything left is firm ground. Falling through to the
# generic verge test made the boardwalk and the cafe side read as lawn,
# which is a third of the walk handling wrongly. The sand runs to the deck,
# SAND_TO_X: it stopped 40 px short, so the strip of beach beside the deck
# handled as pavement.
const SAND_TO_X := 380.0


static func surface(_m: Node2D, p: Vector2) -> int:
	if p.x < SAND_TO_X:
		return Surfaces.S.SAND
	return Surfaces.S.PAVEMENT


# the sand takes prints; past the gate is the dog beach, sand from the fence
# to the water
static func takes_prints(m: Node2D, p: Vector2) -> bool:
	var s: int = m.surface_at(p)
	if p.y < m.GATE_Y:
		return s != Surfaces.S.WATER
	return s == Surfaces.S.SAND


# the seafront's bins are recycling stations
static func draw_bin(m: Node2D, c: Object, bn: Vector2) -> void:
	_recycling_station(m, c, bn)
