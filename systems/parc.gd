class_name Parc
extends RefCounted

# WALK: EL PARC (the park). Its drawing as static functions over main's state
# (main.WALK_MODULES): the box-hedged flowerbeds, the bandstand, the
# Ciutadella mammoth, the playground (El Barri's square has one too, through
# main._playground) and the lake's shore, and the lawns they keep the grass
# off. The bandstand's roof on the overhead layer and the walk's pace stay
# in main.

const ShapeBatch := preload("res://systems/shape_batch.gd")
const LevelBuild := preload("res://world/level_build.gd")

# EL PARC's own furniture, on the lawns beside the path: box-hedged
# flowerbeds (their edging is a grind rail), the bandstand, the Ciutadella
# mammoth, and the playground.
static func _draw_lawns(m: Node2D, vt: float, vb: float) -> void:
	var b := ShapeBatch.new()
	var flower_cols := [Color(0.86, 0.30, 0.34), Color(0.95, 0.78, 0.30), Color(0.62, 0.42, 0.78), Color(0.96, 0.95, 0.92)]
	for bed: Rect2 in LevelBuild.PARK_BEDS:
		if bed.end.y < vt - 40.0 or bed.position.y > vb + 40.0:
			continue
		_flowerbed(m, b, bed, flower_cols)
	# the mammoth: grey stone, a huge domed head, the trunk curled, tusks
	var mp: Vector2 = LevelBuild.PARK_MAMMOTH
	if mp.y > vt - 120.0 and mp.y < vb + 120.0:
		var stone := Color(0.42, 0.38, 0.35)
		var mbs: Vector2 = LevelBuild.MAMMOTH_BODY
		var plinth := Rect2(mp - mbs * 0.5 - Vector2(8, 22), mbs + Vector2(16, 44))
		b.rect(Rect2(plinth.position + m.LIGHT * 10.0, plinth.size), Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.22))
		b.rect(plinth, Color(0.70, 0.68, 0.63))
		b.rect(plinth.grow(-3.0), Color(0.64, 0.62, 0.57))
		b.line(plinth.position + Vector2(4.0, 3.0), Vector2(plinth.end.x - 4.0, plinth.position.y + 3.0), Color(0.80, 0.78, 0.74), 1.5)
		# commemorative bronze plaque on the plinth face
		var pq := Rect2(mp.x - 14.0, plinth.end.y - 14.0, 28.0, 10.0)
		b.rect(pq, Color(0.45, 0.34, 0.18))
		b.rect(pq.grow(-1.2), Color(0.62, 0.48, 0.26))
		b.line(Vector2(pq.position.x + 3.0, pq.position.y + 3.5), Vector2(pq.end.x - 3.0, pq.position.y + 3.5), Color(0.32, 0.22, 0.12), 1.0)
		b.line(Vector2(pq.position.x + 4.0, pq.position.y + 6.5), Vector2(pq.end.x - 4.0, pq.position.y + 6.5), Color(0.32, 0.22, 0.12), 1.0)
		b.circle(mp + m.LIGHT * 22.0, 44.0, Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.22))
		for lg: Vector2 in [Vector2(-22, -30), Vector2(22, -30), Vector2(-22, 34), Vector2(22, 34)]:
			b.circle(mp + lg, 10.0, stone.darkened(0.25))
		b.circle(mp + Vector2(0, 16), 30.0, stone)
		b.circle(mp + Vector2(0, -12), 28.0, stone)
		b.circle(mp + Vector2(0, -44), 22.0, stone.lightened(0.06))
		b.circle(mp + Vector2(-6, -50), 10.0, stone.lightened(0.14))
		b.circle(mp + Vector2(-20, -40), 11.0, stone.darkened(0.12))
		b.circle(mp + Vector2(20, -40), 11.0, stone.darkened(0.12))
		b.line(mp + Vector2(0, -60), mp + Vector2(0, -78), stone.darkened(0.1), 9.0)
		b.circle(mp + Vector2(4, -80), 5.0, stone.darkened(0.1))
		for tx: float in [-1.0, 1.0]:
			b.line(mp + Vector2(tx * 10.0, -60), mp + Vector2(tx * 22.0, -80), Color(0.88, 0.85, 0.76), 4.0)
			b.line(mp + Vector2(tx * 22.0, -80), mp + Vector2(tx * 14.0, -92), Color(0.92, 0.89, 0.80), 3.5)
			b.circle(mp + Vector2(tx * 14.0, -92), 1.6, Color(0.96, 0.94, 0.88))
		b.line(mp + Vector2(0, 46), mp + Vector2(4, 60), stone.darkened(0.2), 3.0)
	# the bandstand: stone podium with concentric radial planks, iron railings and posts
	var bs: Vector2 = LevelBuild.PARK_BANDSTAND
	if bs.y > vt - 120.0 and bs.y < vb + 120.0:
		var r: float = LevelBuild.BANDSTAND_R
		b.circle(bs + m.LIGHT * 18.0, r + 18.0, Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.18))
		b.circle(bs, r + 8.0, Color(0.74, 0.70, 0.62))
		b.circle(bs, r - 6.0, Color(0.66, 0.62, 0.55))
		b.circle(bs, r - 12.0, Color(0.58, 0.54, 0.47))
		for ai: int in range(8):
			var a := float(ai) * PI / 4.0 + PI / 8.0
			b.line(bs, bs + Vector2.from_angle(a) * (r - 12.0), Color(0.50, 0.46, 0.40), 1.5)
		if m.park_posts.size() >= 2:
			for pi: int in range(m.park_posts.size()):
				var p0: Vector2 = m.park_posts[pi]
				var p1: Vector2 = m.park_posts[(pi + 1) % m.park_posts.size()]
				b.line(p0, p1, Color(0.18, 0.19, 0.22), 2.5)
				b.line(p0, p1, Color(0.36, 0.38, 0.42), 1.0)
		for bp: Vector2 in m.park_posts:
			b.circle(bp, 6.0, Color(0.16, 0.17, 0.19))
			b.circle(bp + Vector2(-1.0, -1.0), 2.2, Color(0.44, 0.46, 0.50))
	# the playground: a soft red surface, a slide, a pair of swings
	var pg: Rect2 = LevelBuild.PARK_PLAYGROUND
	if pg.end.y > vt - 40.0 and pg.position.y < vb + 40.0:
		playground(m, b, pg)
	var lk: Rect2 = LevelBuild.PARK_LAKE
	if lk.end.y > vt - 80.0 and lk.position.y < vb + 80.0:
		_lake_shore(m, b, lk)
	if LevelBuild.PARK_SLACK_A.y > vt - 80.0 and LevelBuild.PARK_SLACK_B.y < vb + 80.0:
		_slackline(m, b)
	b.flush(m._wc)


# The slackline between the two lawn trees: the webbing, the ratchet and its
# tree protectors at each end, and the slackliner out on it, arms up, swaying
# for balance. Their friend's rucksack and water bottle on the grass.
static func _slackline(m: Node2D, b: ShapeBatch) -> void:
	var a: Vector2 = LevelBuild.PARK_SLACK_A
	var z: Vector2 = LevelBuild.PARK_SLACK_B
	var t := AnimClock.msec() / 1000.0
	b.line(a + Vector2(5, 6), z + Vector2(5, 6), Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.25), 3.0)
	b.line(a, z, Color(0.96, 0.62, 0.16), 3.0)
	b.line(a + Vector2(1, 0), z + Vector2(1, 0), Color(1.0, 0.82, 0.40), 1.0)
	for e: Vector2 in [a, z]:
		var inward := (Vector2(a.x, (a.y + z.y) * 0.5) - e).normalized()
		b.rect(Rect2(e + inward * 22.0 - Vector2(5, 4), Vector2(10, 8)), Color(0.30, 0.30, 0.34))
		# the plane tree: its shadow, trunk with the line's padded sling, crown
		b.circle(e + m.LIGHT * 26.0, 40.0, Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.20))
		b.circle(e, LevelBuild.PARK_SLACK_TRUNK + 3.0, Color(0.20, 0.22, 0.36))
		b.circle(e, LevelBuild.PARK_SLACK_TRUNK, Color(0.52, 0.46, 0.36))
		for k in range(5):
			var lobe := e + Vector2.from_angle(float(k) * TAU / 5.0 + 0.4) * 20.0
			b.circle(lobe, 22.0, Color(0.26, 0.44, 0.24, 0.92))
		b.circle(e - m.LIGHT * 10.0, 18.0, Color(0.36, 0.54, 0.30, 0.9))
	# the slackliner, walking slowly along it and back
	var u := 0.5 + 0.32 * sin(t * 0.25)
	var p := a.lerp(z, u)
	var sway := sin(t * 2.3) * 4.0
	var arms := Vector2(1.0, 0.0).rotated(sin(t * 2.3) * 0.35)
	b.circle(p + Vector2(6, 8), 10.0, Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.25))
	b.line(p + Vector2(sway, 0) - arms * 18.0, p + Vector2(sway, 0) + arms * 18.0, Color(0.86, 0.66, 0.50), 3.0)
	b.circle(p + Vector2(sway, 0), 8.0, Color(0.20, 0.56, 0.52))
	b.circle(p + Vector2(sway, -1), 5.0, Color(0.36, 0.24, 0.16))
	var kit := a.lerp(z, 0.2) + Vector2(46.0, 0.0)
	b.rect(Rect2(kit.x - 9.0, kit.y - 12.0, 18.0, 24.0), Color(0.62, 0.20, 0.20))
	b.rect(Rect2(kit.x - 6.0, kit.y - 9.0, 12.0, 8.0), Color(0.48, 0.14, 0.14))
	b.circle(kit + Vector2(16, 10), 3.5, Color(0.40, 0.70, 0.86))


# A flowerbed on the lawn: a low clipped box hedge round it, soft at the
# corners and lit along its top, and the planting in drifts - a run of one
# colour, foliage mounds between, a few taller spikes - not a grid of dots.
static func _flowerbed(m: Node2D, b: ShapeBatch, bed: Rect2, cols: Array) -> void:
	b.rect(Rect2(bed.position + m.LIGHT * 5.0, bed.size), Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.18))
	var hedge := Color(0.17, 0.30, 0.16)
	b.rect(bed.grow(-4.0), hedge)
	for cx: float in [bed.position.x + 4.0, bed.end.x - 4.0]:
		for cy: float in [bed.position.y + 4.0, bed.end.y - 4.0]:
			b.circle(Vector2(cx, cy), 4.0, hedge)
	b.rect(Rect2(bed.position.x + 4.0, bed.position.y, bed.size.x - 8.0, bed.size.y), hedge)
	b.rect(Rect2(bed.position.x, bed.position.y + 4.0, bed.size.x, bed.size.y - 8.0), hedge)
	# the clipped top of the box: a lit rim, and its leafy texture
	b.rect(Rect2(bed.position.x + 4.0, bed.position.y + 1.0, bed.size.x - 8.0, 2.0), hedge.lightened(0.22))
	var t := bed.position.y + 6.0
	var k := 0
	while t < bed.end.y - 6.0:
		for hx: float in [bed.position.x + 3.5, bed.end.x - 3.5]:
			b.circle(Vector2(hx, t + float(k % 3)), 2.2, hedge.lightened(0.10 + 0.06 * float(k % 2)))
		t += 7.0
		k += 1
	var soil := bed.grow(-8.0)
	b.rect(soil, Color(0.36, 0.26, 0.18))
	# drifts, top to bottom, each its own colour and its own length
	var y := soil.position.y + 6.0
	var d := int(bed.position.y) & 7
	while y < soil.end.y - 6.0:
		var run := 34.0 + float((d * 17) % 5) * 9.0
		var fc: Color = cols[d % cols.size()]
		var y1 := minf(y + run, soil.end.y - 4.0)
		var fy := y
		var j := 0
		while fy < y1:
			var fx := soil.position.x + 8.0 + float((j * 7 + d * 3) % 5) * (soil.size.x - 16.0) / 4.0
			b.circle(Vector2(fx, fy), 6.5, Color(0.22, 0.38, 0.19))
			b.circle(Vector2(fx - 2.0, fy - 2.0), 3.4, fc)
			b.circle(Vector2(fx + 2.5, fy - 0.5), 3.0, fc.lightened(0.12))
			b.circle(Vector2(fx + 0.5, fy + 2.5), 2.6, fc.darkened(0.08))
			fy += 7.5
			j += 1
		# a foliage mound and a spike or two before the next drift
		var my := minf(y1 + 6.0, soil.end.y - 6.0)
		b.circle(Vector2(soil.get_center().x + float(d % 3 - 1) * 10.0, my), 8.0, Color(0.26, 0.44, 0.22))
		b.circle(Vector2(soil.get_center().x + float(d % 3 - 1) * 10.0 - 2.0, my - 2.0), 5.0, Color(0.32, 0.52, 0.26))
		if d % 2 == 0:
			for sx: float in [soil.position.x + 10.0, soil.end.x - 10.0]:
				b.line(Vector2(sx, my + 6.0), Vector2(sx, my - 6.0), Color(0.56, 0.44, 0.74), 2.6)
		y = y1 + 16.0
		d += 1


# The lake's shore: clumps of reeds round the bank, a timber jetty on the
# south side with two rowing boats tied up for hire, and ducks resting on the
# bank. All drawn on the bank and the water: the path round the lake stays
# clear for walking.
static func _lake_shore(m: Node2D, b: ShapeBatch, lk: Rect2) -> void:
	var lc := lk.get_center()
	var rx := lk.size.x * 0.5
	var ry := lk.size.y * 0.5
	var at := func(a: float, f: float) -> Vector2:
		return lc + Vector2(cos(a) * rx * f, sin(a) * ry * f)
	# the jetty: out from the south bank into the water
	var jb: Vector2 = at.call(PI * 0.5, 1.0)
	var jet := Rect2(jb.x - 12.0, jb.y - 70.0, 24.0, 76.0)
	b.rect(Rect2(jet.position + m.LIGHT * 5.0, jet.size), Color(0, 0, 0, 0.2))
	b.rect(jet, Color(0.50, 0.36, 0.22))
	var py := jet.position.y + 3.0
	while py < jet.end.y - 2.0:
		b.line(Vector2(jet.position.x + 1.0, py), Vector2(jet.end.x - 1.0, py), Color(0.40, 0.28, 0.16), 1.2)
		py += 6.0
	for px: float in [jet.position.x - 1.0, jet.end.x + 1.0]:
		for pyy: float in [jet.position.y + 2.0, jet.position.y + 36.0]:
			b.circle(Vector2(px, pyy), 3.2, Color(0.30, 0.20, 0.12))
	# the boats tied alongside, nosing at their ropes
	var bt := AnimClock.msec() / 1000.0
	for side: float in [-1.0, 1.0]:
		var bp := Vector2(jet.get_center().x + side * 28.0, jet.position.y + 22.0 + sin(bt * 1.3 + side) * 1.5)
		var hull := PackedVector2Array()
		var deck := PackedVector2Array()
		for q: Vector2 in [Vector2(0, -24), Vector2(10, -8), Vector2(10, 16), Vector2(-10, 16), Vector2(-10, -8)]:
			hull.append(bp + q)
			deck.append(bp + q * 0.74)
		b.polygon(hull, Color(0.55, 0.30, 0.22) if side < 0.0 else Color(0.24, 0.42, 0.56))
		b.polygon(deck, Color(0.78, 0.66, 0.50))
		b.line(bp + Vector2(-7, 2), bp + Vector2(7, 2), Color(0.45, 0.33, 0.22), 2.0)
		b.line(bp + Vector2(side * -10.0, -10.0), Vector2(jet.position.x if side < 0.0 else jet.end.x, jet.position.y + 4.0),
			Color(0.82, 0.78, 0.66), 1.0)
	# reeds round the bank, in clumps, leaving the jetty clear
	for i in range(9):
		var a := PI * 0.5 + 0.55 + float(i) * (TAU - 1.1) / 8.0
		var c: Vector2 = at.call(a, 1.0 + 0.02 * float(i % 2))
		b.circle(c + Vector2(2, 3), 9.0, Color(0, 0, 0, 0.12))
		for s in range(9):
			var off := Vector2(float((s * 5 + i) % 7) - 3.0, float((s * 3 + i) % 5) - 2.0) * 2.4
			var lean := Vector2(float((s + i) % 3 - 1) * 4.0, -16.0 - float((s * 7 + i) % 4) * 3.0)
			b.line(c + off, c + off + lean, Color(0.30, 0.48, 0.22) if s % 2 == 0 else Color(0.42, 0.58, 0.28), 2.0)
			if (s + i) % 3 == 0:
				b.line(c + off + lean * 0.7, c + off + lean * 0.95, Color(0.42, 0.26, 0.14), 3.2)
	# water lily pads (nenúfars) floating near the reeds
	for li: int in range(7):
		var la := PI * 0.8 + float(li) * 0.22
		var lp: Vector2 = at.call(la, 0.84 + 0.05 * float(li % 3))
		b.circle(lp, 5.0, Color(0.20, 0.48, 0.24))
		b.circle(lp + Vector2(1.2, -1.0), 1.8, Color(0.16, 0.36, 0.18))
		if li % 2 == 0:
			b.circle(lp + Vector2(-1.0, -1.5), 2.2, Color(0.96, 0.90, 0.94))
			b.circle(lp + Vector2(-1.0, -1.5), 1.0, Color(0.96, 0.84, 0.32))

	# lifebuoy ring on the jetty post
	var lb_pos := Vector2(jet.position.x - 3.0, jet.position.y + 16.0)
	b.circle(lb_pos + m.LIGHT * 2.0, 5.5, Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.2))
	b.circle(lb_pos, 5.0, Color(0.90, 0.22, 0.18))
	b.circle(lb_pos, 2.8, Color(0.50, 0.36, 0.22))
	for rk: int in range(4):
		b.circle(lb_pos + Vector2.from_angle(float(rk) * PI * 0.5) * 3.8, 1.2, Color(0.96, 0.96, 0.98))

	# ducks having a rest on the east bank, heads tucked or up
	for d in range(3):
		var dp: Vector2 = at.call(-0.25 + float(d) * 0.22, 1.05)
		b.circle(dp + Vector2(2, 2), 6.0, Color(0, 0, 0, 0.16))
		b.circle(dp, 6.0, Color(0.52, 0.40, 0.28))
		b.circle(dp + Vector2(-2, -1), 3.6, Color(0.60, 0.48, 0.34))
		var hd := dp + Vector2(5.0 if d % 2 == 0 else 3.0, -4.0)
		b.circle(hd, 3.2, Color(0.16, 0.42, 0.24) if d != 1 else Color(0.48, 0.36, 0.24))
		b.circle(hd + Vector2(3, 0.5), 1.4, Color(0.92, 0.74, 0.24))


static func playground(m: Node2D, b: ShapeBatch, pg: Rect2) -> void:
	if true:
		# poured rubber, soft-cornered, with a darker kerb round it and a
		# hopscotch let into it; a low fence with a gate on the path side
		var rub := Color(0.64, 0.36, 0.30)
		m._soft_rect(b, pg.grow(4.0), 14.0, rub.darkened(0.25))
		m._soft_rect(b, pg, 12.0, rub)
		for k in range(4):
			b.rect(Rect2(pg.position.x + 14.0, pg.end.y - 30.0 - float(k) * 18.0, 16.0, 16.0),
				Color(0.98, 0.84, 0.38, 0.55) if k % 2 == 0 else Color(0.40, 0.62, 0.80, 0.55))
		var fence := Color(0.66, 0.52, 0.34)
		var fr := pg.grow(10.0)
		for seg: Array in [[fr.position, Vector2(fr.end.x, fr.position.y)], [Vector2(fr.end.x, fr.position.y), fr.end],
				[fr.end, Vector2(fr.position.x, fr.end.y)],
				[fr.position, Vector2(fr.position.x, fr.get_center().y - 22.0)],
				[Vector2(fr.position.x, fr.get_center().y + 22.0), Vector2(fr.position.x, fr.end.y)]]:
			b.line((seg[0] as Vector2) + m.LIGHT * 3.0, (seg[1] as Vector2) + m.LIGHT * 3.0, Color(0, 0, 0, 0.16), 3.0)
			b.line(seg[0], seg[1], fence, 3.0)
		var fy := fr.position.y
		while fy <= fr.end.y:
			for fx: float in [fr.position.x, fr.end.x]:
				if absf(fy - fr.get_center().y) > 22.0 or fx == fr.end.x:
					b.circle(Vector2(fx, fy), 3.0, fence.darkened(0.3))
			fy += 20.0
		var fx2 := fr.position.x
		while fx2 <= fr.end.x:
			for fyy: float in [fr.position.y, fr.end.y]:
				b.circle(Vector2(fx2, fyy), 3.0, fence.darkened(0.3))
			fx2 += 20.0
		# sandpit toys: red bucket and blue spade in the sand
		var sp_toy := pg.position + Vector2(48.0, 180.0)
		b.circle(sp_toy + m.LIGHT * 2.0, 5.0, Color(0, 0, 0, 0.15))
		b.circle(sp_toy, 4.5, Color(0.88, 0.24, 0.20))
		b.circle(sp_toy, 2.5, Color(0.72, 0.18, 0.16))
		b.line(sp_toy + Vector2(7.0, -2.0), sp_toy + Vector2(16.0, 5.0), Color(0.24, 0.55, 0.85), 2.2)

		# two spring riders: a blue horse and a green frog on heavy coils
		var sr := pg.position + Vector2(126.0, 248.0)
		var hc := Color(0.30, 0.56, 0.86)
		b.circle(sr + m.LIGHT * 9.0, 11.0, Color(0, 0, 0, 0.16))
		b.line(sr + Vector2(0, 10), sr + Vector2(-3, 18), Color(0.96, 0.84, 0.30), 3.0)
		m._soft_rect(b, Rect2(sr.x - 6.0, sr.y - 10.0, 12.0, 22.0), 5.0, hc)
		# green frog spring rocker alongside
		var sr2 := pg.position + Vector2(126.0, 196.0)
		var fc := Color(0.28, 0.62, 0.32)
		b.circle(sr2 + m.LIGHT * 9.0, 11.0, Color(0, 0, 0, 0.16))
		b.line(sr2 + Vector2(0, 10), sr2 + Vector2(-3, 18), Color(0.96, 0.84, 0.30), 3.0)
		m._soft_rect(b, Rect2(sr2.x - 7.0, sr2.y - 8.0, 14.0, 18.0), 5.0, fc)
		b.circle(sr2 + Vector2(-5.0, -9.0), 3.0, fc.lightened(0.15))
		b.circle(sr2 + Vector2(5.0, -9.0), 3.0, fc.lightened(0.15))
		b.circle(sr + Vector2(0, -14), 6.0, hc.lightened(0.1))
		b.circle(sr + Vector2(-3.5, -19), 2.2, hc.darkened(0.2))
		b.circle(sr + Vector2(3.5, -19), 2.2, hc.darkened(0.2))
		b.rect(Rect2(sr.x - 5.0, sr.y - 1.0, 10.0, 8.0), Color(0.96, 0.84, 0.30))
		b.line(sr + Vector2(-8, -7), sr + Vector2(8, -7), Color(0.30, 0.30, 0.34), 2.0)
		# the slide: ladder, platform, chute
		var sl := pg.position + Vector2(40.0, 60.0)
		# its shadow, falling long from the platform
		b.polygon(PackedVector2Array([sl + Vector2(-8, -10), sl + Vector2(22, -4), sl + Vector2(26, 94),
			sl + Vector2(-2, 94)]), Color(0, 0, 0, 0.14))
		# the ladder's rails and rungs, up to the platform
		for lx: float in [-9.0, 9.0]:
			b.line(Vector2(sl.x + lx, sl.y - 42.0), Vector2(sl.x + lx, sl.y - 12.0), Color(0.36, 0.36, 0.40), 2.4)
		for rung in range(4):
			b.line(Vector2(sl.x - 9.0, sl.y - 16.0 - float(rung) * 7.0), Vector2(sl.x + 9.0, sl.y - 16.0 - float(rung) * 7.0), Color(0.46, 0.46, 0.50), 2.0)
		# the platform, its corner posts and the hand rail round it
		b.rect(Rect2(sl.x - 13.0, sl.y - 13.0, 26.0, 26.0), Color(0.22, 0.38, 0.58))
		b.rect(Rect2(sl.x - 11.0, sl.y - 11.0, 22.0, 22.0), Color(0.30, 0.50, 0.72))
		for pc: Vector2 in [Vector2(-11, -11), Vector2(11, -11), Vector2(-11, 11), Vector2(11, 11)]:
			b.circle(sl + pc, 2.6, Color(0.92, 0.30, 0.28))
		# the chute: a trough widening into its run-out, raised side rails,
		# and the shine down the middle where it is polished by every child
		var chute := PackedVector2Array([sl + Vector2(-8, 12), sl + Vector2(8, 12), sl + Vector2(11, 84),
			sl + Vector2(-11, 84)])
		b.polygon(chute, Color(0.92, 0.72, 0.24))
		b.polygon(PackedVector2Array([sl + Vector2(-5, 13), sl + Vector2(5, 13), sl + Vector2(7, 82),
			sl + Vector2(-7, 82)]), Color(0.98, 0.84, 0.38))
		b.line(sl + Vector2(-1, 16), sl + Vector2(-1, 80), Color(1, 0.96, 0.78), 2.0)
		for rs: float in [-1.0, 1.0]:
			b.line(sl + Vector2(8.5 * rs, 12), sl + Vector2(11.5 * rs, 84), Color(0.78, 0.56, 0.16), 2.0)
		# swings, seen from above: the top bar, the A-frame legs splayed out
		# at each end, and the seats hanging under the bar, swinging to and
		# fro across it over the hollows their kicking feet have worn
		var st := AnimClock.msec() / 1000.0
		var sw := pg.position + Vector2(118.0, 70.0)
		var frame := Color(0.34, 0.36, 0.40)
		b.line(sw + Vector2(-34, 0) + m.LIGHT * 12.0, sw + Vector2(34, 0) + m.LIGHT * 12.0, Color(0, 0, 0, 0.14), 5.0)
		for si: float in [-14.0, 14.0]:
			b.circle(sw + Vector2(si, 0.0), 9.0, rub.darkened(0.14))
		for ex: float in [-32.0, 32.0]:
			for ey: float in [-16.0, 16.0]:
				b.line(sw + Vector2(ex, 0), sw + Vector2(ex * 1.1, ey), frame.darkened(0.15), 3.0)
				b.circle(sw + Vector2(ex * 1.1, ey), 2.4, frame.darkened(0.35))
		for si: float in [-14.0, 14.0]:
			var seat := sw + Vector2(si, sin(st * 2.2 + si) * 11.0)
			b.line(sw + Vector2(si - 6.0, 0), seat + Vector2(-6, 0), Color(0.62, 0.62, 0.66), 1.4)
			b.line(sw + Vector2(si + 6.0, 0), seat + Vector2(6, 0), Color(0.62, 0.62, 0.66), 1.4)
			b.rect(Rect2(seat.x - 7.0, seat.y - 3.0, 14.0, 6.0), Color(0.20, 0.22, 0.26))
		b.line(sw + Vector2(-34, 0), sw + Vector2(34, 0), frame, 5.0)
		b.line(sw + Vector2(-34, -1.5), sw + Vector2(34, -1.5), frame.lightened(0.3), 1.2)
		# the sandpit's timber edge, its corner seats, a bucket and spade
		# left in it (the sand itself is a patch)
		var sp: Vector2 = pg.get_center() + Vector2(-28.0, 40.0)
		var timber := Rect2(sp.x - 54.0, sp.y - 44.0, 108.0, 88.0)
		m._soft_rect(b, timber, 8.0, Color(0.46, 0.34, 0.22))
		m._soft_rect(b, timber.grow(-6.0), 5.0, Color(0.86, 0.78, 0.58))
		for cs: Vector2 in [timber.position, Vector2(timber.end.x, timber.position.y), Vector2(timber.position.x, timber.end.y), timber.end]:
			b.circle(cs.move_toward(timber.get_center(), 9.0), 7.0, Color(0.56, 0.42, 0.28))
		b.rect(Rect2(sp.x + 14.0, sp.y + 6.0, 10.0, 12.0), Color(0.24, 0.52, 0.82))
		b.line(Vector2(sp.x + 13.0, sp.y + 6.0), Vector2(sp.x + 25.0, sp.y + 6.0), Color(0.18, 0.40, 0.66), 2.0)
		b.line(Vector2(sp.x - 20.0, sp.y - 10.0), Vector2(sp.x - 6.0, sp.y + 2.0), Color(0.90, 0.30, 0.28), 2.0)
		b.circle(Vector2(sp.x - 6.0, sp.y + 2.0), 3.0, Color(0.90, 0.30, 0.28))


# --- main's walk hooks (main.WALK_MODULES) ---------------------------------------

# the beds, the playground and the bandstand's ring keep the grass off
static func grass_blocked(_m: Node2D, p: Vector2) -> bool:
	for r: Rect2 in LevelBuild.PARK_BEDS:
		if r.grow(8.0).has_point(p):
			return true
	if LevelBuild.PARK_PLAYGROUND.grow(8.0).has_point(p):
		return true
	return p.distance_to(LevelBuild.PARK_BANDSTAND) < LevelBuild.BANDSTAND_R + 22.0


# the lawns' furniture, up to the gate
static func draw_live(m: Node2D, _wc: ShapeBatch, vt: float, vb: float) -> void:
	_draw_lawns(m, maxf(vt, m.GATE_Y - 30.0), vb)
