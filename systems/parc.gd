class_name Parc
extends RefCounted

# WALK: EL PARC (the park). Its drawing as static functions over main's state
# (main.WALK_MODULES): the box-hedged flowerbeds, the bandstand, the
# bronze dog, the playground (El Barri's square has one too, through
# main._playground) and the lake's shore, and the lawns they keep the grass
# off. The bandstand's roof on the overhead layer and the walk's pace stay
# in main.

const ShapeBatch := preload("res://systems/shape_batch.gd")
const LevelBuild := preload("res://world/level_build.gd")

# EL PARC's own furniture, on the lawns beside the path: box-hedged
# flowerbeds (their edging is a grind rail), the bandstand, the bronze dog on
# his plinth, and the playground.
static func _draw_lawns(m: Node2D, vt: float, vb: float) -> void:
	var b := ShapeBatch.new()
	var flower_cols := [Color(0.86, 0.30, 0.34), Color(0.95, 0.78, 0.30), Color(0.62, 0.42, 0.78), Color(0.96, 0.95, 0.92)]
	for bed: Rect2 in LevelBuild.PARK_BEDS:
		if bed.end.y < vt - 40.0 or bed.position.y > vb + 40.0:
			continue
		_flowerbed(m, b, bed, flower_cols)
	# the bronze dog: sitting up on his plinth, looking down the path, his nose
	# and one paw rubbed bright by everyone who passes
	var sp: Vector2 = LevelBuild.PARK_STATUE
	if sp.y > vt - 120.0 and sp.y < vb + 120.0:
		var sbs: Vector2 = LevelBuild.STATUE_BODY
		var plinth := Rect2(sp - sbs * 0.5, sbs)
		b.rect(Rect2(plinth.position + m.LIGHT * 10.0, plinth.size), Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.22))
		b.rect(plinth, Color(0.64, 0.62, 0.57))
		b.rect(plinth.grow(-4.0), Color(0.72, 0.70, 0.65))
		b.line(plinth.position + Vector2(4.0, 3.0), Vector2(plinth.end.x - 4.0, plinth.position.y + 3.0), Color(0.82, 0.80, 0.76), 1.5)
		var pq := Rect2(sp.x - 14.0, plinth.end.y - 13.0, 28.0, 9.0)
		b.rect(pq, Color(0.45, 0.34, 0.18))
		b.rect(pq.grow(-1.2), Color(0.62, 0.48, 0.26))
		b.line(Vector2(pq.position.x + 3.0, pq.position.y + 4.5), Vector2(pq.end.x - 3.0, pq.position.y + 4.5), Color(0.32, 0.22, 0.12), 1.0)
		var bronze := Color(0.36, 0.30, 0.22)
		var lit := Color(0.50, 0.42, 0.30)
		var verd := Color(0.34, 0.50, 0.42)
		var gold := Color(0.92, 0.76, 0.40)
		var d := sp + Vector2(0.0, -6.0)
		var dark := bronze.darkened(0.35)
		# haunches and the tail curled round them
		b.circle(d + Vector2(3.0, 5.0), 21.0, Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.25))
		b.circle(d, 20.0, dark)
		b.circle(d, 18.0, bronze)
		b.circle(d + Vector2(-5.0, -5.0), 10.0, lit)
		b.capsule(d + Vector2(17.0, -6.0), d + Vector2(20.0, 10.0), 4.0, dark)
		b.capsule(d + Vector2(20.0, 10.0), d + Vector2(13.0, 20.0), 3.5, bronze)
		# the front paws, side by side under the chest
		var chest := d + Vector2(0.0, 16.0)
		for sd: float in [-1.0, 1.0]:
			b.capsule(chest + Vector2(sd * 10.0, 2.0), chest + Vector2(sd * 10.0, 18.0), 4.5, dark)
			b.circle(chest + Vector2(sd * 10.0, 19.0), 4.2, lit)
		b.circle(chest + Vector2(10.0, 19.0), 3.0, gold)
		# the head: big and forward, pointed ears up, the muzzle past the paws
		var head := chest + Vector2(0.0, 6.0)
		for sd: float in [-1.0, 1.0]:
			b.polygon(PackedVector2Array([head + Vector2(sd * 4.0, -8.0), head + Vector2(sd * 17.0, -17.0),
				head + Vector2(sd * 13.0, 2.0)]), dark)
			b.polygon(PackedVector2Array([head + Vector2(sd * 6.0, -7.0), head + Vector2(sd * 14.0, -13.0),
				head + Vector2(sd * 12.0, -1.0)]), bronze)
		b.circle(head, 12.0, dark)
		b.circle(head, 10.5, bronze)
		b.circle(head + Vector2(-3.0, -4.0), 5.5, lit)
		b.capsule(head + Vector2(0.0, 6.0), head + Vector2(0.0, 18.0), 5.0, dark)
		b.capsule(head + Vector2(0.0, 6.0), head + Vector2(0.0, 17.0), 4.0, bronze)
		b.circle(head + Vector2(0.0, 19.5), 3.4, gold)
		for sd: float in [-1.0, 1.0]:
			b.circle(head + Vector2(sd * 5.0, 2.0), 1.6, dark.darkened(0.4))
		# weathering: green in the hollows
		b.circle(d + Vector2(9.0, -12.0), 3.5, Color(verd.r, verd.g, verd.b, 0.6))
		b.circle(d + Vector2(-11.0, 6.0), 2.5, Color(verd.r, verd.g, verd.b, 0.5))
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
	if m.sprinkler != null and Sprinkler.HEAD_POS.y > vt - 180.0 and Sprinkler.HEAD_POS.y < vb + 180.0:
		_draw_sprinkler(m, b)
	_bike_lane(b, vt, vb)
	_borders(b, vt, vb)
	_shrubs(m, b, vt, vb)
	_edge_benches(m, b, vt, vb)
	if LevelBuild.PARK_BOAT_HUT.y > vt - 120.0 and LevelBuild.PARK_BOAT_HUT.y < vb + 120.0:
		_boat_hut(m, b)
	_lawn_people(m, b, vt, vb)
	if LevelBuild.PARK_KIOSK.y > vt - 120.0 and LevelBuild.PARK_KIOSK.y < vb + 120.0:
		_kiosk(m, b)
	var pc: Rect2 = LevelBuild.PARK_PICNIC
	if pc.end.y > vt - 40.0 and pc.position.y < vb + 40.0:
		_picnic(m, b)
	if LevelBuild.PARK_FRISBEE_B.y < vb + 60.0 and LevelBuild.PARK_FRISBEE_A.y > vt - 60.0:
		_frisbee(m, b)
	if LevelBuild.PARK_READER_TREE.y > vt - 120.0 and LevelBuild.PARK_READER_TREE.y < vb + 120.0:
		_reader(m, b)
	_lamps(m, b, vt, vb)
	_trees(m, b, vt, vb)
	b.flush(m._wc)



# The rotary lawn sprinkler on the west lawn verge: turf cup, brass rotating
# nozzle, rocker arm, and sparkling fan of water droplets across the path.
static func _draw_sprinkler(m: Node2D, b: ShapeBatch) -> void:
	var sp: Sprinkler = m.sprinkler
	var hp := Sprinkler.HEAD_POS
	var t := AnimClock.msec() / 1000.0
	# moist soil and green grass ring around the sprinkler
	b.circle(hp, 22.0, Color(0.18, 0.34, 0.17, 0.65))
	b.circle(hp, 13.0, Color(0.15, 0.28, 0.14, 0.85))
	# shadow
	b.circle(hp + m.LIGHT * 3.0, 6.0, Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.22))
	# ground cup and brass body
	b.circle(hp, 6.0, Color(0.22, 0.24, 0.22))
	b.circle(hp, 4.2, Color(0.82, 0.68, 0.28))
	b.circle(hp, 2.2, Color(0.95, 0.84, 0.44))
	# rocker arm
	var arm_dir := Vector2.from_angle(sp.angle)
	var arm_tip := hp + arm_dir * 8.0
	b.line(hp, arm_tip, Color(0.76, 0.60, 0.20), 2.2)
	b.circle(arm_tip, 2.0, Color(0.88, 0.74, 0.32))
	var counter := arm_dir.rotated(PI * 0.75)
	b.line(hp, hp + counter * 5.0, Color(0.68, 0.52, 0.18), 1.6)

	if not sp.active:
		if sp.state == Sprinkler.St.WARN:
			var mist_f := fmod(t * 3.0, 1.0)
			b.circle(hp + arm_dir * (mist_f * 18.0), 4.0 + mist_f * 6.0, Color(0.90, 0.95, 1.0, 0.25 * (1.0 - mist_f)))
		return

	# active water spray: arc of flying droplets
	var jet_dir := arm_dir
	var perp := jet_dir.orthogonal()
	var spray_len := Sprinkler.SPRAY_RADIUS

	# fine mist near nozzle
	for mi in range(3):
		var mf := 0.15 + float(mi) * 0.12
		var mp := hp + jet_dir * (mf * spray_len * 0.3) + perp * sin(t * 12.0 + float(mi)) * 3.0
		b.circle(mp, 5.0 + float(mi) * 2.5, Color(0.88, 0.94, 1.0, 0.22))

	# flying droplets along the jet
	for i in range(16):
		var fi := float(i) / 15.0
		var dist := 14.0 + fi * (spray_len - 14.0)
		var spread := (fi * fi) * 12.0 * sin(float(i * 7) + t * 8.0)
		var dp := hp + jet_dir * dist + perp * spread
		var col := Color(0.88, 0.95, 1.0, 0.85 - fi * 0.35)
		b.circle(dp, maxf(1.4, 2.8 - fi * 1.0), col)

	# glistening wet ground patches where the water lands
	var landing := hp + jet_dir * spray_len
	b.circle(landing, 14.0, Color(0.55, 0.80, 0.98, 0.16))
	b.circle(landing + perp * 8.0, 10.0, Color(0.55, 0.80, 0.98, 0.12))

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
	# the lawn's furniture: the kiosk, the hut, the blankets, the shrub beds
	if p.distance_to(LevelBuild.PARK_KIOSK) < LevelBuild.PARK_KIOSK_R + 22.0:
		return true
	if Rect2(LevelBuild.PARK_BOAT_HUT - Vector2(46.0, 46.0), Vector2(92.0, 110.0)).has_point(p):
		return true
	if LevelBuild.PARK_BIKE_LANE.grow(8.0).has_point(p):
		return true
	if LevelBuild.PARK_PICNIC.grow(10.0).has_point(p):
		return true
	if Rect2(LevelBuild.PARK_SUNBATHER - Vector2(22.0, 40.0), Vector2(44.0, 80.0)).has_point(p):
		return true
	for sh: Vector2 in LevelBuild.PARK_SHRUBS:
		var d := p - sh
		if (d.x * d.x) / (54.0 * 54.0) + (d.y * d.y) / (66.0 * 66.0) < 1.0:
			return true
	return p.distance_to(LevelBuild.PARK_BANDSTAND) < LevelBuild.BANDSTAND_R + 22.0


# the lawns' furniture, up to the gate
static func draw_live(m: Node2D, _wc: ShapeBatch, vt: float, vb: float) -> void:
	_draw_lawns(m, maxf(vt, m.GATE_Y - 30.0), vb)


# --- the park round the path (2026-11-08) --------------------------------------
# What made El Parc read as El Barri: the path was one flat fill with a seam,
# the lawns empty grass. The path now has a granite edging and the park's low
# iron hoop fence beside it, raked gravel and a worn track down the middle;
# the lawns have the city's green iron lamps, a round kiosk by the gate with
# the bike lane behind it, people on the grass (a picnic, a reader under a
# plane tree, a frisbee pair) and flower borders.

const EDGING := Color(0.80, 0.77, 0.70)
const EDGING_DARK := Color(0.58, 0.55, 0.49)
const HOOP := Color(0.16, 0.26, 0.20)
const GRAVEL_DARK := Color(0.62, 0.55, 0.42, 0.55)
const GRAVEL_LIGHT := Color(0.86, 0.80, 0.68, 0.55)
const TRACK := Color(0.56, 0.49, 0.37, 0.22)
const LAMP_GREEN := Color(0.14, 0.24, 0.19)
const LAMP_GREEN_LIT := Color(0.30, 0.44, 0.34)
const KIOSK_GREEN := Color(0.16, 0.32, 0.24)
const AWNING_A := Color(0.86, 0.24, 0.22)
const AWNING_B := Color(0.96, 0.93, 0.86)
const LANE := Color(0.40, 0.50, 0.44)
const LANE_LINE := Color(0.92, 0.92, 0.88, 0.85)
const GRAVEL_STEP := 17.0
const TRACK_STEP := 40.0
const HOOP_STEP := 22.0
# the stretch round the lake, where the path splits: no centre track there
const LAKE_TOP := -3350.0
const LAKE_BOT := -2080.0
# where the flower borders run beside the edging: [x0, x1, y_top, y_bottom]
const BORDERS: Array[Rect2] = [
	Rect2(372.0, -1460.0, 22.0, 340.0),
	Rect2(886.0, -3900.0, 22.0, 440.0),
	Rect2(886.0, -880.0, 22.0, 220.0),
]


static func _hash(x: float, y: float) -> float:
	return fposmod(sin(x * 12.9898 + y * 78.233) * 43758.5453, 1.0)


# the walk's own path edges: the granite edging, a dark joint on the gravel
# side, and the low iron hoop fence a step out on the lawn with its posts
static func draw_path_edges(m: Node2D, left: PackedVector2Array, right: PackedVector2Array, _col: Color) -> void:
	var b := ShapeBatch.new()
	for side: int in 2:
		var pts: PackedVector2Array = left if side == 0 else right
		var out := -1.0 if side == 0 else 1.0
		var run := 0.0
		for i in range(pts.size() - 1):
			var a: Vector2 = pts[i]
			var z: Vector2 = pts[i + 1]
			if a.y > float(m.START_Y) + 160.0 and z.y > float(m.START_Y) + 160.0:
				continue
			var off := Vector2(out, 0.0)
			b.line(a + off * 3.0, z + off * 3.0, EDGING, 5.0)
			b.line(a - off * 0.5, z - off * 0.5, EDGING_DARK, 1.5)
			b.line(a + off * 6.0, z + off * 6.0, Color(EDGING_DARK.r, EDGING_DARK.g, EDGING_DARK.b, 0.5), 1.0)
			# the hoop fence: its shadow, the rail, a post every HOOP_STEP
			var ha := a + off * 13.0
			var hz := z + off * 13.0
			b.line(ha + m.LIGHT * 3.0, hz + m.LIGHT * 3.0, Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.22), 2.0)
			b.line(ha, hz, HOOP, 1.6)
			var seg := a.distance_to(z)
			while run < seg:
				var p := ha.lerp(hz, run / maxf(seg, 0.001))
				b.rect(Rect2(p - Vector2(1.6, 1.6), Vector2(3.2, 3.2)), HOOP)
				run += HOOP_STEP
			run -= seg
	b.flush(m._wc)


# raked gravel on the path, a worn track down its middle where the walkers go
static func draw_over_walkway(m: Node2D, wc: Object, vt: float, vb: float) -> void:
	var b := ShapeBatch.new()
	var top: float = maxf(vt - GRAVEL_STEP, float(m.GATE_Y) - 30.0)
	var lk: Rect2 = LevelBuild.PARK_LAKE.grow(6.0)
	# the worn track, feathered at both sides
	var tpts := PackedVector2Array()
	var rows := PackedFloat32Array()
	var ty := floorf(top / TRACK_STEP) * TRACK_STEP
	var lo := minf(vb + TRACK_STEP, float(m.START_Y) + 120.0)
	while ty <= lo:
		if ty < LAKE_TOP or ty > LAKE_BOT:
			var e: Vector2 = m.walk_edges(ty)
			var cx := (e.x + e.y) * 0.5
			tpts.append_array([Vector2(cx - 70.0, ty), Vector2(cx - 22.0, ty), Vector2(cx + 22.0, ty), Vector2(cx + 70.0, ty)])
			rows.append(1.0)
		elif tpts.size() > 0:
			b.band(tpts, 4, TRACK, rows, PackedFloat32Array([0.0, 1.0, 1.0, 0.0]))
			tpts = PackedVector2Array()
			rows = PackedFloat32Array()
		ty += TRACK_STEP
	if tpts.size() >= 8:
		b.band(tpts, 4, TRACK, rows, PackedFloat32Array([0.0, 1.0, 1.0, 0.0]))
	_mown_stripes(m, b, top, vb)
	_litter(m, b, top, vb)
	# the stones: on a grid fixed in the world, so they do not crawl
	var gy := floorf(top / GRAVEL_STEP) * GRAVEL_STEP
	while gy <= vb + GRAVEL_STEP:
		var e: Vector2 = m.walk_edges(gy)
		var gx := ceilf((e.x + 6.0) / GRAVEL_STEP) * GRAVEL_STEP
		while gx < e.y - 6.0:
			var h := _hash(gx, gy)
			if h < 0.62:
				var p := Vector2(gx + (h - 0.3) * 24.0, gy + (_hash(gy, gx) - 0.5) * 14.0)
				if not lk.has_point(p):
					var s := 1.6 + h * 1.6
					b.rect(Rect2(p, Vector2(s, s)), GRAVEL_DARK if h < 0.31 else GRAVEL_LIGHT)
			gx += GRAVEL_STEP
		gy += GRAVEL_STEP
	b.flush(wc)


# the city's park lamp: a green cast-iron post on a fluted base, a lantern
# with four glass panes and a cap; a pool of light on the gravel when lit
static func _lamps(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	var glow := Game.lamp_glow()
	for p: Vector2 in LevelBuild.PARK_LAMPS:
		if p.y < vt - 120.0 or p.y > vb + 120.0:
			continue
		if glow > 0.0:
			b.glow(p + Vector2(0.0, 6.0), 110.0, Color(1.0, 0.86, 0.52, 0.30 * glow), 0.15)
		# the post's long shadow, and the lantern's at its end
		var sh: Color = Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.24)
		b.capsule(p, p + m.LIGHT * 62.0, 2.6, sh)
		b.circle(p + m.LIGHT * 64.0, 6.0, sh)
		# the fluted base on the grass
		b.circle(p, 10.0, LAMP_GREEN)
		b.circle(p, 7.5, LAMP_GREEN_LIT)
		# the lantern seen from above: its frame, four panes, the cap and finial
		var lp: Vector2 = p - m.LIGHT * 6.0
		b.rect(Rect2(lp - Vector2(9, 9), Vector2(18, 18)), LAMP_GREEN)
		var pane := Color(0.56, 0.66, 0.62).lerp(Color(1.0, 0.88, 0.56), glow)
		for q: Vector2 in [Vector2(-7, -7), Vector2(1, -7), Vector2(-7, 1), Vector2(1, 1)]:
			b.rect(Rect2(lp + q, Vector2(6, 6)), pane)
		b.quad(lp + Vector2(-5, -5), lp + Vector2(5, -5), lp + Vector2(5, 5), lp + Vector2(-5, 5), LAMP_GREEN)
		b.circle(lp, 3.4, LAMP_GREEN_LIT)
		b.circle(lp + Vector2(-1, -1), 1.4, Color(0.62, 0.74, 0.62))


# the round kiosk by the gate: a green iron drum under a striped scalloped
# awning, the dome and its finial, the hatch open with a cold box and a
# board of ice creams, the bike rack beside it with a bike locked to it
static func _kiosk(m: Node2D, b: ShapeBatch) -> void:
	var c: Vector2 = LevelBuild.PARK_KIOSK
	var r: float = LevelBuild.PARK_KIOSK_R
	b.circle(c + m.LIGHT * 18.0, r + 14.0, Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.22))
	# the counter's paving round it
	b.circle(c, r + 18.0, Color(0.70, 0.67, 0.60))
	b.circle(c, r + 15.0, Color(0.76, 0.73, 0.66))
	# the awning: twelve scallops, alternate stripes
	var segs := 16
	for i in range(segs):
		var a0 := TAU * float(i) / float(segs)
		var a1 := TAU * float(i + 1) / float(segs)
		var col := AWNING_A if i % 2 == 0 else AWNING_B
		b.polygon(PackedVector2Array([c, c + Vector2.from_angle(a0) * (r + 6.0), c + Vector2.from_angle((a0 + a1) * 0.5) * (r + 9.0), c + Vector2.from_angle(a1) * (r + 6.0)]), col)
	for i in range(segs):
		var a0 := TAU * float(i) / float(segs)
		b.line(c + Vector2.from_angle(a0) * 12.0, c + Vector2.from_angle(a0) * (r + 6.0), Color(0.0, 0.0, 0.0, 0.08), 1.0)
	b.circle(c, 15.0, KIOSK_GREEN)
	b.circle(c - m.LIGHT * 3.0, 11.0, KIOSK_GREEN.lightened(0.18))
	b.circle(c - m.LIGHT * 5.0, 3.0, Color(0.86, 0.72, 0.30))
	# the hatch, on the path side, with the cold box and the board
	var hp := c + Vector2(-r - 14.0, 6.0)
	b.rect(Rect2(hp.x - 7.0, hp.y - 12.0, 14.0, 24.0), Color(0.88, 0.90, 0.92))
	b.rect(Rect2(hp.x - 5.0, hp.y - 10.0, 10.0, 20.0), Color(0.62, 0.78, 0.86))
	var board := c + Vector2(-r - 30.0, -26.0)
	b.rect(Rect2(board.x - 9.0, board.y - 6.0, 18.0, 12.0), Color(0.22, 0.20, 0.18))
	for k in range(3):
		b.circle(board + Vector2(-5.0 + float(k) * 5.0, 0.0), 2.0, [Color(0.96, 0.60, 0.70), Color(0.98, 0.90, 0.60), Color(0.62, 0.42, 0.30)][k])
	# the bike rack (a steel hoop) and a bike locked to it
	var rack := c + Vector2(r + 26.0, 30.0)
	b.line(rack + Vector2(0, -12), rack + Vector2(0, 12), Color(0.62, 0.64, 0.68), 3.0)
	var bk := rack + Vector2(7.0, 0.0)
	b.line(bk + Vector2(4, -20) + m.LIGHT * 4.0, bk + Vector2(4, 20) + m.LIGHT * 4.0, Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.22), 4.0)
	b.line(bk + Vector2(0, -20), bk + Vector2(0, 20), Color(0.14, 0.14, 0.15), 3.0)
	b.line(bk + Vector2(0, -6), bk + Vector2(0, 8), Color(0.16, 0.42, 0.62), 3.0)
	b.line(bk + Vector2(-6, -15), bk + Vector2(6, -15), Color(0.20, 0.20, 0.22), 2.0)
	b.rect(Rect2(bk + Vector2(-2.5, 9.0), Vector2(5.0, 5.0)), Color(0.18, 0.16, 0.14))


# the bike lane across the east lawn, from the street to the bandstand
static func _bike_lane(b: ShapeBatch, vt: float, vb: float) -> void:
	var ln: Rect2 = LevelBuild.PARK_BIKE_LANE
	var y0 := maxf(ln.position.y, vt - 20.0)
	var y1 := minf(ln.end.y, vb + 20.0)
	if y1 <= y0:
		return
	b.rect(Rect2(ln.position.x - 2.0, y0, ln.size.x + 4.0, y1 - y0), Color(0.64, 0.62, 0.56))
	b.rect(Rect2(ln.position.x, y0, ln.size.x, y1 - y0), LANE)
	var cx := ln.get_center().x
	var dy := floorf(y0 / 36.0) * 36.0
	while dy < y1:
		if dy + 18.0 > y0:
			b.rect(Rect2(cx - 1.0, maxf(dy, y0), 2.0, minf(18.0, y1 - maxf(dy, y0))), LANE_LINE)
		dy += 36.0
	# a bicycle painted on the lane every few hundred px, both ways
	var sy := floorf(y0 / 420.0) * 420.0
	while sy < y1:
		if sy > y0 + 20.0 and sy < ln.end.y - 30.0:
			for hx: float in [ln.position.x + 11.0, ln.end.x - 11.0]:
				b.circle(Vector2(hx, sy - 8.0), 4.5, LANE_LINE)
				b.circle(Vector2(hx, sy - 8.0), 3.0, LANE)
				b.circle(Vector2(hx, sy + 8.0), 4.5, LANE_LINE)
				b.circle(Vector2(hx, sy + 8.0), 3.0, LANE)
				b.line(Vector2(hx, sy - 8.0), Vector2(hx, sy + 8.0), LANE_LINE, 1.4)
		sy += 420.0


# a seated person seen from above: shoulders, the head, the arms forward
static func _sitter(b: ShapeBatch, p: Vector2, facing: float, shirt: Color, hair: Color, skin: Color) -> void:
	var f := Vector2.from_angle(facing)
	var s := f.orthogonal()
	b.capsule(p - s * 7.0, p + s * 7.0, 6.0, shirt)
	b.line(p + s * 7.0, p + s * 6.0 + f * 9.0, skin, 3.0)
	b.line(p - s * 7.0, p - s * 6.0 + f * 9.0, skin, 3.0)
	b.capsule(p + f * 8.0 + s * 3.0, p + f * 14.0 + s * 3.0, 2.6, Color(0.22, 0.26, 0.38))
	b.capsule(p + f * 8.0 - s * 3.0, p + f * 14.0 - s * 3.0, 2.6, Color(0.22, 0.26, 0.38))
	b.circle(p + f * 1.0, 5.2, skin)
	b.circle(p - f * 0.6, 5.0, hair)


# a standing person seen from above
static func _stander(b: ShapeBatch, p: Vector2, facing: float, arm: float, shirt: Color, hair: Color, skin: Color) -> void:
	var f := Vector2.from_angle(facing)
	var s := f.orthogonal()
	b.circle(p + Vector2(6, 8), 10.0, Color(0.04, 0.05, 0.07, 0.20))
	b.line(p + s * 8.0, p + s * 9.0 + f.rotated(-arm) * 11.0, skin, 3.0)
	b.line(p - s * 8.0, p - s * 9.0 + f * 5.0, skin, 3.0)
	b.capsule(p - s * 8.0, p + s * 8.0, 6.5, shirt)
	b.circle(p, 5.4, skin)
	b.circle(p - f * 1.0, 5.2, hair)


# the picnic on the west lawn: a checked blanket, two friends on it, the
# basket, a bottle, bread and fruit
static func _picnic(m: Node2D, b: ShapeBatch) -> void:
	var r: Rect2 = LevelBuild.PARK_PICNIC
	b.rect(Rect2(r.position + m.LIGHT * 4.0, r.size), Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.18))
	b.rect(r, Color(0.94, 0.92, 0.88))
	var n := 6
	var cw := r.size.x / float(n)
	var ch := r.size.y / 4.0
	for i in range(n):
		for j in range(4):
			if (i + j) % 2 == 0:
				b.rect(Rect2(r.position + Vector2(float(i) * cw, float(j) * ch), Vector2(cw, ch)), Color(0.78, 0.28, 0.26, 0.85))
	var c := r.get_center()
	b.rect(Rect2(c + Vector2(-9, -8), Vector2(18, 14)), Color(0.62, 0.44, 0.24))
	b.rect(Rect2(c + Vector2(-7, -6), Vector2(14, 10)), Color(0.74, 0.56, 0.32))
	b.line(c + Vector2(-7, -1), c + Vector2(7, -1), Color(0.52, 0.36, 0.20), 2.0)
	b.capsule(c + Vector2(16, -14), c + Vector2(16, -4), 2.6, Color(0.24, 0.42, 0.26))
	b.capsule(c + Vector2(-20, 10), c + Vector2(-8, 12), 3.0, Color(0.86, 0.68, 0.40))
	b.circle(c + Vector2(4, 14), 3.0, Color(0.92, 0.36, 0.24))
	b.circle(c + Vector2(10, 14), 3.0, Color(0.60, 0.80, 0.30))
	_sitter(b, r.position + Vector2(18.0, 20.0), 0.6, Color(0.30, 0.56, 0.72), Color(0.24, 0.16, 0.10), Color(0.90, 0.74, 0.60))
	_sitter(b, Vector2(r.end.x - 16.0, r.end.y - 18.0), PI + 0.5, Color(0.92, 0.80, 0.30), Color(0.56, 0.36, 0.20), Color(0.70, 0.52, 0.40))


# the reader under the plane tree on the east lawn, back to the trunk
static func _reader(m: Node2D, b: ShapeBatch) -> void:
	var t: Vector2 = LevelBuild.PARK_READER_TREE
	var p := t + Vector2(-62.0, 34.0)
	b.rect(Rect2(p + Vector2(-14, -10), Vector2(30, 40)), Color(0.34, 0.50, 0.66, 0.9))
	_sitter(b, p, PI * 0.75, Color(0.82, 0.86, 0.80), Color(0.12, 0.10, 0.10), Color(0.84, 0.66, 0.52))
	var bk := p + Vector2.from_angle(PI * 0.75) * 9.0
	b.quad(bk + Vector2(-5, -3), bk + Vector2(5, -5), bk + Vector2(6, 3), bk + Vector2(-4, 5), Color(0.96, 0.95, 0.90))
	b.line(bk + Vector2(0, -4), bk + Vector2(1, 4), Color(0.46, 0.20, 0.18), 1.2)
	# the tree: shadow, trunk, mottled crown over all of it
	b.circle(t + m.LIGHT * 30.0, 50.0, Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.18))
	b.circle(t, LevelBuild.PARK_TREE_TRUNK + 2.0, Color(0.36, 0.34, 0.28))
	b.circle(t, LevelBuild.PARK_TREE_TRUNK, Color(0.66, 0.62, 0.50))
	b.circle(t + Vector2(-4, 3), 5.0, Color(0.80, 0.76, 0.62))
	b.circle(t + Vector2(5, -4), 4.0, Color(0.52, 0.50, 0.40))
	for k in range(6):
		var lobe := t + Vector2.from_angle(float(k) * TAU / 6.0 + 0.2) * 26.0
		b.circle(lobe, 28.0, Color(0.14, 0.27, 0.15))
	for k in range(6):
		var lobe := t + Vector2.from_angle(float(k) * TAU / 6.0 + 0.2) * 26.0
		b.circle(lobe, 25.0, Color(0.22, 0.40, 0.21))
	b.circle(t - m.LIGHT * 12.0, 22.0, Color(0.34, 0.52, 0.28, 0.9))
	b.circle(t - m.LIGHT * 20.0 + Vector2(10, 0), 10.0, Color(0.44, 0.60, 0.34, 0.85))


# two friends throwing a frisbee across the west lawn
static func _frisbee(m: Node2D, b: ShapeBatch) -> void:
	var a: Vector2 = LevelBuild.PARK_FRISBEE_A
	var z: Vector2 = LevelBuild.PARK_FRISBEE_B
	var t := AnimClock.msec() / 1000.0
	var face := (z - a).angle()
	var cyc := fposmod(t / 2.4, 2.0)
	var u := cyc if cyc < 1.0 else 2.0 - cyc
	var thrower_a := cyc < 0.15 or cyc > 1.85
	_stander(b, a, face, 0.9 if thrower_a else 0.2, Color(0.86, 0.36, 0.30), Color(0.20, 0.14, 0.10), Color(0.88, 0.70, 0.56))
	_stander(b, z, face + PI, 0.9 if (cyc > 0.85 and cyc < 1.15) else 0.2, Color(0.24, 0.30, 0.52), Color(0.80, 0.64, 0.34), Color(0.62, 0.44, 0.32))
	var fp := a.lerp(z, u) + (z - a).orthogonal().normalized() * sin(u * PI) * 28.0
	var lift := sin(u * PI) * 16.0
	b.circle(fp + m.LIGHT * (4.0 + lift), 5.0, Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.22))
	b.circle(fp, 5.5, Color(0.98, 0.84, 0.18))
	b.circle(fp, 3.4, Color(1.0, 0.92, 0.46))


# flower borders beside the edging: drifts of one colour, foliage between
static func _borders(b: ShapeBatch, vt: float, vb: float) -> void:
	var cols := [Color(0.90, 0.36, 0.42), Color(0.98, 0.82, 0.34), Color(0.66, 0.46, 0.82), Color(0.98, 0.97, 0.94)]
	for r: Rect2 in BORDERS:
		if r.end.y < vt - 20.0 or r.position.y > vb + 20.0:
			continue
		b.rect(r, Color(0.40, 0.30, 0.20))
		var y := r.position.y + 6.0
		var i := 0
		while y < r.end.y - 4.0:
			var col: Color = cols[int(floorf(y / 90.0)) % cols.size()]
			var h := _hash(r.position.x, y)
			b.circle(Vector2(r.position.x + 6.0 + h * 10.0, y), 5.0, Color(0.24, 0.44, 0.22))
			b.circle(Vector2(r.position.x + 5.0 + h * 12.0, y + 2.0), 2.6, col)
			if i % 2 == 0:
				b.circle(Vector2(r.end.x - 6.0 - h * 4.0, y + 5.0), 2.4, col.lightened(0.15))
			y += 9.0
			i += 1


# --- the second pass: the avenue, the lawns' groups, more people --------------

const MOW := Color(0.80, 0.92, 0.62, 0.07)
const MOW_STEP := 56.0
const LEAF_COLS: Array[Color] = [Color(0.80, 0.56, 0.22), Color(0.70, 0.42, 0.18), Color(0.86, 0.70, 0.32), Color(0.56, 0.40, 0.20)]
const CONKER := Color(0.42, 0.20, 0.10)
const GLOVE := Vector2(800.0, -4000.0)
const BENCH_WOOD := Color(0.56, 0.41, 0.27)
const BENCH_IRON := Color(0.16, 0.16, 0.17)


# the lawns mown in stripes, the mower's way, up and back
static func _mown_stripes(m: Node2D, b: ShapeBatch, top: float, vb: float) -> void:
	var y := floorf(top / MOW_STEP) * MOW_STEP
	while y < vb + MOW_STEP:
		if int(floorf(y / MOW_STEP)) % 2 == 0:
			var e: Vector2 = m.walk_edges(y + MOW_STEP * 0.5)
			var e2: Vector2 = m.walk_edges(y)
			var e3: Vector2 = m.walk_edges(y + MOW_STEP)
			var lx := minf(e.x, minf(e2.x, e3.x)) - 20.0
			var rx := maxf(e.y, maxf(e2.y, e3.y)) + 20.0
			b.rect(Rect2(-400.0, y, lx + 400.0, MOW_STEP), MOW)
			b.rect(Rect2(rx, y, 1700.0 - rx, MOW_STEP), MOW)
		y += MOW_STEP


# fallen plane leaves and conkers along the path's edges under the avenue,
# and someone's lost glove
static func _litter(m: Node2D, b: ShapeBatch, top: float, vb: float) -> void:
	var y := floorf(top / 23.0) * 23.0
	while y < vb + 23.0:
		if y > LAKE_BOT or y < LAKE_TOP:
			var e: Vector2 = m.walk_edges(y)
			for side: int in 2:
				var h := _hash(y, 7.0 + float(side))
				var x: float = (e.x + 8.0 + h * 54.0) if side == 0 else (e.y - 8.0 - h * 54.0)
				var p := Vector2(x, y + (_hash(x, y) - 0.5) * 16.0)
				if h < 0.55:
					var a := _hash(x, 3.0) * TAU
					var f := Vector2.from_angle(a) * 4.5
					var s := f.orthogonal() * 0.75
					var col: Color = LEAF_COLS[int(h * 40.0) % LEAF_COLS.size()]
					b.quad(p - f, p - s * 0.6, p + f, p + s * 1.1, col)
					b.line(p - f * 0.8, p + f * 0.8, col.darkened(0.25), 0.8)
				elif h < 0.62:
					b.circle(p, 2.8, CONKER)
					b.circle(p + Vector2(-0.8, -0.8), 1.0, Color(0.70, 0.40, 0.22))
		y += 23.0
	if GLOVE.y > top and GLOVE.y < vb:
		var g := GLOVE
		b.capsule(g + Vector2(-5, 2), g + Vector2(5, -1), 4.2, Color(0.26, 0.34, 0.56))
		for k in range(4):
			b.capsule(g + Vector2(3.0, -4.0 + float(k) * 2.6), g + Vector2(9.0, -6.0 + float(k) * 3.2), 1.3, Color(0.26, 0.34, 0.56))
		b.capsule(g + Vector2(-2, -4), g + Vector2(1, -8), 1.4, Color(0.26, 0.34, 0.56))
		b.line(g + Vector2(-7, 3), g + Vector2(-7, -2), Color(0.86, 0.84, 0.78), 2.0)


# a plane tree from above: its soft shade on the ground (falling toward the
# path), the trunk, and a crown of lobes, darker at the rim. i varies the size
# and tint, and every other one is a horse chestnut, darker and rounder.
static func _tree(m: Node2D, b: ShapeBatch, t: Vector2, lean: float, i: int) -> void:
	var r := 30.0 + float(i % 3) * 4.0
	var c := t + Vector2(lean * 12.0, -4.0)
	var chestnut := i % 2 == 1
	b.glow(c + m.LIGHT * 26.0, r + 30.0, Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.30), 0.35)
	b.glow(c + m.LIGHT * 26.0 + Vector2(lean * 22.0, 10.0), r * 0.7, Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.14), 0.2)
	b.circle(t, LevelBuild.PARK_AVENUE_TRUNK + 2.0, Color(0.30, 0.28, 0.24))
	b.circle(t, LevelBuild.PARK_AVENUE_TRUNK, Color(0.64, 0.60, 0.48) if not chestnut else Color(0.42, 0.34, 0.26))
	var rim := Color(0.13, 0.26, 0.14) if not chestnut else Color(0.10, 0.20, 0.12)
	var leaf := Color(0.24, 0.42, 0.21) if not chestnut else Color(0.18, 0.34, 0.18)
	var lobes := 6 if not chestnut else 5
	for k in range(lobes):
		b.circle(c + Vector2.from_angle(float(k) * TAU / float(lobes) + float(i)) * r * 0.62, r * 0.62 + 2.5, rim)
	for k in range(lobes):
		b.circle(c + Vector2.from_angle(float(k) * TAU / float(lobes) + float(i)) * r * 0.62, r * 0.62, leaf)
	b.circle(c - m.LIGHT * r * 0.35, r * 0.55, leaf.lightened(0.12))
	b.circle(c - m.LIGHT * r * 0.6 + Vector2(r * 0.25, 0.0), r * 0.22, leaf.lightened(0.26))
	if chestnut:
		# its candles of white flower
		for k in range(4):
			b.circle(c + Vector2.from_angle(float(k) * 1.7 + float(i)) * r * 0.5, 2.4, Color(0.96, 0.94, 0.88))


# the avenue along the path and the groups on the lawns
static func _trees(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	var i := 0
	for t: Vector2 in LevelBuild.park_avenue():
		if t.y > vt - 90.0 and t.y < vb + 90.0:
			_tree(m, b, t, 1.0 if t.x < 640.0 else -1.0, i)
		i += 1
	for t: Vector2 in LevelBuild.PARK_TREE_GROUPS:
		if t.y > vt - 90.0 and t.y < vb + 90.0:
			_tree(m, b, t, 0.0, i)
		i += 1


# low shrub beds on the lawns: a mulched oval and clipped mounds
static func _shrubs(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	var k := 0
	for s: Vector2 in LevelBuild.PARK_SHRUBS:
		k += 1
		if s.y < vt - 80.0 or s.y > vb + 80.0:
			continue
		b.glow(s + m.LIGHT * 10.0, 62.0, Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.22), 0.4)
		var pts := PackedVector2Array()
		for a in range(16):
			var v := Vector2.from_angle(TAU * float(a) / 16.0)
			pts.append(s + Vector2(v.x * 44.0, v.y * 56.0))
		b.polygon(pts, Color(0.38, 0.28, 0.20))
		for j in range(7):
			var off := Vector2.from_angle(float(j) * 0.9 + float(k)) * (12.0 + float(j % 3) * 9.0)
			off.y *= 1.25
			b.circle(s + off, 15.0, Color(0.16, 0.32, 0.18))
			b.circle(s + off - m.LIGHT * 3.0, 12.0, Color(0.26, 0.46, 0.24) if j % 3 != 0 else Color(0.40, 0.30, 0.46))


# the benches on the verge, facing the path; someone on some of them
static func _edge_benches(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	for bn: Vector3 in LevelBuild.PARK_EDGE_BENCHES:
		if bn.y < vt - 60.0 or bn.y > vb + 60.0:
			continue
		var p := Vector2(bn.x, bn.y)
		var face := 1.0 if p.x < 640.0 else -1.0
		b.rect(Rect2(p + Vector2(-8.0, -24.0) + m.LIGHT * 6.0, Vector2(16.0, 48.0)), Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.22))
		for ey: float in [-21.0, 17.0]:
			b.rect(Rect2(p.x - 10.0, p.y + ey, 20.0, 4.0), BENCH_IRON)
		for si in range(3):
			var wc := BENCH_WOOD.lightened(0.10 if si == 0 else 0.0).darkened(0.12 if si == 2 else 0.0)
			b.rect(Rect2(p.x - 8.0 + float(si) * 5.5, p.y - 24.0, 5.0, 48.0), wc.darkened(0.3))
			b.rect(Rect2(p.x - 8.0 + float(si) * 5.5, p.y - 24.0, 3.8, 46.8), wc)
		# the backrest on the lawn side
		b.rect(Rect2(p.x - face * 11.0 - 2.0, p.y - 24.0, 4.0, 48.0), BENCH_WOOD.darkened(0.2))
		if bn.z >= 1.0:
			var ang := 0.0 if face > 0.0 else PI
			_sitter(b, p + Vector2(-face * 2.0, -8.0 if bn.z >= 2.0 else 0.0), ang, Color(0.46, 0.48, 0.52), Color(0.86, 0.86, 0.84), Color(0.86, 0.70, 0.58))
			if bn.z >= 2.0:
				_sitter(b, p + Vector2(-face * 2.0, 12.0), ang, Color(0.62, 0.30, 0.40), Color(0.70, 0.70, 0.72), Color(0.84, 0.66, 0.54))
			else:
				# his newspaper
				b.rect(Rect2(p + Vector2(face * 8.0 - 6.0, -6.0), Vector2(12.0, 10.0)), Color(0.92, 0.90, 0.84))
				b.line(p + Vector2(face * 8.0 - 4.0, -3.0), p + Vector2(face * 8.0 + 4.0, -3.0), Color(0.40, 0.40, 0.40), 1.0)


# the boat-hire hut on the east lawn by the lake: a timber hut with a pitched
# roof, the hire board, oars racked against its wall, a life ring
static func _boat_hut(m: Node2D, b: ShapeBatch) -> void:
	var c: Vector2 = LevelBuild.PARK_BOAT_HUT
	var r := Rect2(c - Vector2(30.0, 24.0), Vector2(60.0, 48.0))
	b.rect(Rect2(r.position + m.LIGHT * 12.0, r.size), Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.26))
	b.rect(r.grow(4.0), Color(0.66, 0.62, 0.54))
	b.rect(Rect2(r.position, Vector2(r.size.x * 0.5, r.size.y)), Color(0.34, 0.46, 0.52))
	b.rect(Rect2(r.position + Vector2(r.size.x * 0.5, 0.0), Vector2(r.size.x * 0.5, r.size.y)), Color(0.42, 0.56, 0.62))
	b.line(Vector2(c.x, r.position.y), Vector2(c.x, r.end.y), Color(0.24, 0.32, 0.36), 2.0)
	var y := r.position.y + 6.0
	while y < r.end.y:
		b.line(Vector2(r.position.x, y), Vector2(r.end.x, y), Color(0.0, 0.0, 0.0, 0.08), 1.0)
		y += 6.0
	# the board at its north end, the oars, the life ring
	b.rect(Rect2(c.x - 12.0, r.position.y - 18.0, 24.0, 11.0), Color(0.94, 0.92, 0.86))
	b.rect(Rect2(c.x - 9.0, r.position.y - 15.0, 10.0, 3.0), Color(0.20, 0.40, 0.60))
	b.rect(Rect2(c.x - 9.0, r.position.y - 11.0, 16.0, 2.0), Color(0.40, 0.40, 0.40))
	for k in range(3):
		var ox := r.position.x + 10.0 + float(k) * 7.0
		b.line(Vector2(ox, r.end.y + 2.0), Vector2(ox + 2.0, r.end.y + 26.0), Color(0.62, 0.44, 0.26), 2.4)
		b.capsule(Vector2(ox + 2.0, r.end.y + 22.0), Vector2(ox + 2.5, r.end.y + 30.0), 2.6, Color(0.70, 0.52, 0.30))
	var lr := Vector2(r.end.x + 10.0, c.y)
	b.circle(lr, 8.0, Color(0.92, 0.30, 0.24))
	b.circle(lr, 4.6, Color(0.66, 0.62, 0.54))
	for a: float in [0.4, 2.0, 3.6, 5.2]:
		b.line(lr + Vector2.from_angle(a) * 4.8, lr + Vector2.from_angle(a) * 7.8, Color(0.96, 0.95, 0.92), 2.4)


# someone lying down, seen from above, on a towel
static func _lier(b: ShapeBatch, p: Vector2, skin: Color, wear: Color) -> void:
	b.rect(Rect2(p - Vector2(16.0, 34.0), Vector2(32.0, 68.0)), Color(0.20, 0.62, 0.70))
	for k in range(4):
		b.rect(Rect2(p.x - 16.0, p.y - 30.0 + float(k) * 18.0, 32.0, 5.0), Color(0.96, 0.94, 0.86))
	b.capsule(p + Vector2(-4, -6), p + Vector2(-4, 26), 3.0, skin)
	b.capsule(p + Vector2(4, -6), p + Vector2(4, 26), 3.0, skin)
	b.capsule(p + Vector2(0, -18), p + Vector2(0, 2), 7.0, wear)
	b.capsule(p + Vector2(-9, -18), p + Vector2(-12, -2), 2.4, skin)
	b.capsule(p + Vector2(9, -18), p + Vector2(12, -2), 2.4, skin)
	b.circle(p + Vector2(0, -24), 5.6, skin)
	b.rect(Rect2(p + Vector2(-5, -27), Vector2(10, 3)), Color(0.10, 0.10, 0.12))


# the sunbather, the dog walker with a sniffing terrier, the parent at the
# playground and the toddler, and a jogger running up and down the bike lane
static func _lawn_people(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	var t := AnimClock.msec() / 1000.0
	var sb: Vector2 = LevelBuild.PARK_SUNBATHER
	if sb.y > vt - 60.0 and sb.y < vb + 60.0:
		_lier(b, sb, Color(0.92, 0.74, 0.60), Color(0.90, 0.30, 0.44))
		b.circle(sb + Vector2(26.0, -26.0), 4.0, Color(0.96, 0.62, 0.20))
	var dw: Vector2 = LevelBuild.PARK_DOG_WALKER
	if dw.y > vt - 80.0 and dw.y < vb + 80.0:
		var sniff := dw + Vector2(cos(t * 0.7) * 26.0, 18.0 + sin(t * 1.1) * 12.0)
		_stander(b, dw, (sniff - dw).angle(), 0.4, Color(0.36, 0.40, 0.30), Color(0.40, 0.30, 0.22), Color(0.80, 0.62, 0.50))
		b.line(dw + Vector2(6, 2), sniff, Color(0.82, 0.24, 0.20), 1.2)
		var dd := Vector2.from_angle(t * 0.9 + 1.0)
		b.circle(sniff + Vector2(4, 5), 6.0, Color(0.04, 0.05, 0.07, 0.2))
		b.capsule(sniff - dd * 5.0, sniff + dd * 4.0, 4.4, Color(0.90, 0.88, 0.82))
		b.circle(sniff + dd * 6.5, 3.4, Color(0.90, 0.88, 0.82))
		b.circle(sniff + dd * 6.0 + dd.orthogonal() * 2.6, 1.6, Color(0.50, 0.34, 0.22))
		b.circle(sniff + dd * 6.0 - dd.orthogonal() * 2.6, 1.6, Color(0.50, 0.34, 0.22))
	var pa: Vector2 = LevelBuild.PARK_PARENT
	if pa.y > vt - 80.0 and pa.y < vb + 80.0:
		var tod := pa + Vector2(36.0 + sin(t * 0.6) * 14.0, 6.0 + cos(t * 0.8) * 10.0)
		_stander(b, pa, (tod - pa).angle(), 0.6, Color(0.52, 0.66, 0.76), Color(0.22, 0.16, 0.12), Color(0.74, 0.56, 0.44))
		var bob := sin(t * 6.0) * 0.8
		b.circle(tod + Vector2(3, 4), 5.0, Color(0.04, 0.05, 0.07, 0.2))
		b.capsule(tod + Vector2(-4, bob), tod + Vector2(4, -bob), 3.6, Color(0.98, 0.78, 0.30))
		b.circle(tod, 3.6, Color(0.80, 0.62, 0.50))
		b.circle(tod + Vector2(0, -0.6), 3.2, Color(0.66, 0.48, 0.26))
	# the jogger: up the lane and back down it, about half a minute a lap
	var ln: Rect2 = LevelBuild.PARK_BIKE_LANE
	var u := fposmod(t / 14.0, 2.0)
	var k := u if u < 1.0 else 2.0 - u
	var jy := lerpf(ln.end.y - 40.0, ln.position.y + 40.0, k)
	if jy > vt - 40.0 and jy < vb + 40.0:
		var up := u < 1.0
		var jp := Vector2(ln.position.x + 12.0 if up else ln.end.x - 12.0, jy)
		var face := -PI * 0.5 if up else PI * 0.5
		var stride := sin(t * 9.0)
		var f := Vector2.from_angle(face)
		var s := f.orthogonal()
		b.circle(jp + Vector2(5, 7), 8.0, Color(0.04, 0.05, 0.07, 0.2))
		b.line(jp + s * 7.0, jp + s * 7.0 + f * 7.0 * stride, Color(0.86, 0.68, 0.54), 3.0)
		b.line(jp - s * 7.0, jp - s * 7.0 - f * 7.0 * stride, Color(0.86, 0.68, 0.54), 3.0)
		b.capsule(jp - s * 6.5, jp + s * 6.5, 5.6, Color(0.20, 0.72, 0.56))
		b.circle(jp, 4.8, Color(0.86, 0.68, 0.54))
		b.circle(jp - f * 1.0, 4.4, Color(0.18, 0.12, 0.08))
		b.capsule(jp - f * 4.0, jp - f * 9.0, 1.8, Color(0.18, 0.12, 0.08))
