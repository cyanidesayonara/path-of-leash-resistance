class_name Mosaic
extends RefCounted

# WALK 14: EL MOSAIC (Park Guell). Its drawing and its crowd groups, as
# static functions over main's state (main.WALK_MODULES): the plaza, the
# serpentine bench, the hypostyle hall and viaduct columns, the hilltop
# off-leash space, the gate queue and the posers at the salamander.

const ShapeBatch := preload("res://systems/shape_batch.gd")
const LevelBuild := preload("res://world/level_build.gd")
const LIGHT := Vector2(0.5, 0.866)

# El Mosaic's gate queue: this many people up the west side of the forecourt
const QUEUE := 9
# where the posers stand round the salamander, from its middle: on its west
# and south, clear of the owner's way round its east side
const POSERS: Array[Vector2] = [Vector2(-125, -60), Vector2(-120, 30), Vector2(-95, 115),
	Vector2(-170, -5), Vector2(-135, -140)]
# El Mosaic's scenery is static but expensive to tessellate: its geometry is
# retained on main (_mosaic_cache) and appended into the live batch in order
const CACHE_STEP := 150.0
const CACHE_MARGIN := 170.0

const SHARDS := [Color(0.12, 0.30, 0.70), Color(0.18, 0.62, 0.70), Color(0.34, 0.62, 0.30),
	Color(0.96, 0.80, 0.24), Color(0.92, 0.50, 0.18), Color(0.97, 0.96, 0.92), Color(0.82, 0.24, 0.26)]


static func on_bench(m: Node2D, y: float) -> bool:
	return m.lvl == "guell" and y < LevelBuild.MOSAIC_PLAZA_Y0 + 40.0 and y > LevelBuild.MOSAIC_PLAZA_Y1 - 40.0


# broken tile set in mortar, as a disc: every shard its own odd shape
static func trencadis_disc(m: Node2D, c: Object, at: Vector2, r: float, key: int) -> void:
	c.draw_circle(at, r, Color(0.92, 0.90, 0.84))
	for k in range(9):
		var a := float(k) * 2.39996 + float(key % 7)
		var d := r * sqrt(fmod(float(k) * 0.37 + 0.13, 1.0)) * 0.8
		var q := at + Vector2(cos(a), sin(a)) * d
		var poly := PackedVector2Array()
		for v in range(4):
			var va := a + float(v) * 1.57 + float((key + k + v) % 5) * 0.2
			poly.append(q + Vector2(cos(va), sin(va)) * r * (0.22 + 0.08 * float((k + v) % 3)))
		c.draw_colored_polygon(poly, SHARDS[(k + key) % SHARDS.size()])


# ...and as a band between two points, for the bench: the seat tiled edge to
# edge in two courses of broken tile, the mortar showing between, so it reads
# as one solid bench rather than flags on a string
static func trencadis_band(m: Node2D, b: ShapeBatch, a: Vector2, z: Vector2, w: float, key: int) -> void:
	b.line(a, z, Color(0.93, 0.91, 0.85), w)
	var ln := a.distance_to(z)
	var n := maxi(2, int(ln / 8.0))
	var along := (z - a) / ln
	var side := along.orthogonal()
	var tl := ln / float(n)
	var hw := w * 0.2
	for row in range(2):
		var off := side * w * (-0.23 if row == 0 else 0.23)
		var shift := 0.0 if row == 0 else 0.5
		for k in range(n):
			var h := (k * 7 + row * 3 + key * 5) % 11
			var t0 := tl * (float(k) + shift)
			var t1 := minf(t0 + tl, ln)
			if t1 - t0 < 3.0:
				continue
			var c0 := a + along * t0 + off
			var c1 := a + along * t1 + off
			var j := float(h % 3) * 0.7
			var poly := PackedVector2Array([c0 + along * 1.0 - side * (hw - j), c1 - along * 1.0 - side * hw,
				c1 - along * (1.0 + j) + side * hw, c0 + along * 1.0 + side * (hw - float(h % 2))])
			var colr: Color = SHARDS[(k * 3 + row * 5 + key) % SHARDS.size()]
			if h < 3:
				colr = Color(0.97, 0.96, 0.92)     # the white ground Gaudi set the colour in
			b.polygon(poly, colr)


# the serpentine bench's bays, where it bellies out: a spot just in front of
# the seat in each, on both sides of the plaza
static func bays(m: Node2D) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var y: float = LevelBuild.MOSAIC_PLAZA_Y0 - LevelBuild.MOSAIC_BAY * 2.0
	while y > LevelBuild.MOSAIC_PLAZA_Y1 + 10.0:
		var e: Vector2 = m.walk_edges(y)
		out.append(Vector2(e.x + 34.0, y))
		out.append(Vector2(e.y - 34.0, y))
		y -= LevelBuild.MOSAIC_BAY * 2.0
	return out


# one of El Mosaic's columns, from above, into a batch: a fat Doric column
# of the hypostyle hall (round capital, its ring, a trencadis medallion on
# top), or a viaduct column of rubble stone like a palm trunk, the outer row
# leaning into the hill, read from its long shadow
static func draw_column(m: Node2D, cb: ShapeBatch, p: Vector2) -> void:
	if p.y > LevelBuild.MOSAIC_HALL_Y1 - 50.0 and p.y < LevelBuild.MOSAIC_HALL_Y0 + 50.0:
		# cast_shadow's squashed contact patch needs a transform, which would
		# break the batch: the same shadow, the patch as a polygon
		var side := LIGHT.orthogonal()
		var tip := p + LIGHT * 50.0
		var sc := Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.22)
		cb.polygon(PackedVector2Array([p + side * 20.0, p - side * 20.0, tip - side * 12.4, tip + side * 12.4]), sc)
		var patch := PackedVector2Array()
		for k in range(16):
			var a := float(k) * TAU / 16.0
			patch.append(p + LIGHT * 10.0 + Vector2(cos(a) * 27.6, sin(a) * 12.65))
		cb.polygon(patch, Color(sc.r, sc.g, sc.b, 0.2))
		# Doric column: base plinth, fluted stone capital with 20 flutes
		# catching light/shadow, and concentric stone moldings - classical
		# Park Guell temple architecture without mosaic wallpaper on the shafts
		cb.circle(p, 25.0, Color(0.72, 0.68, 0.60))
		cb.circle(p - LIGHT * 2.0, 23.0, Color(0.82, 0.78, 0.70))
		for k in range(20):
			var fa := float(k) * TAU / 20.0
			var fdir := Vector2(cos(fa), sin(fa))
			var lit := clampf(fdir.dot(-LIGHT) * 0.5 + 0.5, 0.0, 1.0)
			var fcol := Color(0.66, 0.62, 0.54).lerp(Color(0.92, 0.89, 0.82), lit)
			cb.circle(p + fdir * 18.0, 2.2, fcol)
		cb.circle(p, 17.0, Color(0.80, 0.76, 0.68))
		cb.circle(p - LIGHT * 1.5, 14.0, Color(0.87, 0.84, 0.77))
		cb.circle(p, 6.0, Color(0.78, 0.74, 0.66))
		return
	var outer: bool = m.walk_edges(p.y).y - p.x < (LevelBuild.MOSAIC_VIADUCT_OUTER + LevelBuild.MOSAIC_VIADUCT_INNER) * 0.5
	var sh := Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.22)
	if outer:
		cb.polygon(PackedVector2Array([p + Vector2(-14, 10), p + Vector2(14, 10),
			p + Vector2(40, 60), p + Vector2(18, 64)]), sh)
	else:
		cb.polygon(PackedVector2Array([p + Vector2(-12, 6), p + Vector2(12, 6),
			p + Vector2(28, 40), p + Vector2(10, 44)]), sh)
	var top := p + (Vector2(-6, -10) if outer else Vector2(-2, -4))
	cb.circle(p, 17.0, Color(0.50, 0.42, 0.34))
	cb.circle(top, 15.0, Color(0.60, 0.51, 0.40))
	for k in range(6):
		cb.circle(top + Vector2.from_angle(float(k) * 1.05 + p.y) * 9.0, 3.0, Color(0.44, 0.37, 0.30))
	cb.circle(top, 4.0, Color(0.68, 0.60, 0.48))


# main.WALK_MODULES draw_live: the scenery up to the gate, from the retained
# geometry while the view stays within CACHE_STEP of where it was built
static func draw_live(m: Node2D, _wc: ShapeBatch, vt: float, vb: float) -> void:
	vt = maxf(vt, m.GATE_Y - 30.0)
	if m._mosaic_cache == null or absf(vt - m._mosaic_cache_vt) > CACHE_STEP \
			or absf(vb - m._mosaic_cache_vb) > CACHE_STEP:
		var live: ShapeBatch = m._wc
		m._mosaic_cache = ShapeBatch.new()
		m._wc = m._mosaic_cache
		draw_scenery(m, vt - CACHE_MARGIN, vb + CACHE_MARGIN)
		m._wc = live
		m._mosaic_cache_vt = vt
		m._mosaic_cache_vb = vb
	m._mosaic_cache.append_to(m._wc)


static func draw_scenery(m: Node2D, vt: float, vb: float) -> void:
	var b := ShapeBatch.new()
	# gravel: the sandy ground, with its stones
	var gy := floorf((vt - 20.0) / 31.0) * 31.0
	while gy < vb + 20.0:
		var e: Vector2 = m.walk_edges(gy)
		var gx := e.x + fmod(absf(gy) * 0.61, 23.0)
		while gx < e.y:
			var n := fmod(absf(gx * 12.9898 + gy * 78.233), 5.0)
			b.circle(Vector2(gx, gy), 1.3 + n * 0.3, Color(0.64, 0.56, 0.42, 0.55) if int(n) % 2 == 0 else Color(0.90, 0.84, 0.70, 0.5))
			gx += 23.0 + n * 4.0
		gy += 31.0
	# the dragon stair: a long flight of shallow steps all the way up, their
	# nosings catching the light, heavier steps at its foot and its head
	var s0: float = LevelBuild.MOSAIC_STAIR_Y0 - 78.0
	var s1: float = LevelBuild.MOSAIC_STAIR_Y1
	var sy0 := maxf(vt - 30.0, s1)
	var sy1 := minf(vb + 30.0, s0)
	var st := ceilf(sy0 / 26.0) * 26.0
	while st < sy1:
		var e: Vector2 = m.walk_edges(st)
		b.rect(Rect2(e.x, st, e.y - e.x, 5.0), Color(0.40, 0.32, 0.22, 0.12))
		b.line(Vector2(e.x, st), Vector2(e.y, st), Color(0.96, 0.90, 0.78, 0.35), 2.0)
		st += 26.0
	for sy: float in [LevelBuild.MOSAIC_STAIR_Y0, LevelBuild.MOSAIC_STAIR_Y1]:
		if sy < vt - 80.0 or sy > vb + 80.0:
			continue
		for k in range(6):
			var yy := sy - float(k) * 13.0
			var e: Vector2 = m.walk_edges(yy)
			b.rect(Rect2(e.x, yy - 13.0, e.y - e.x, 13.0), Color(0.72, 0.66, 0.56).darkened(0.04 * float(k)))
			b.line(Vector2(e.x, yy - 13.0), Vector2(e.y, yy - 13.0), Color(0.86, 0.80, 0.70), 2.0)
	# the dripping-stone grotto walls either side of the stair
	var ya := maxf(vt - 40.0, LevelBuild.MOSAIC_STAIR_Y1)
	var yz := minf(vb + 40.0, LevelBuild.MOSAIC_STAIR_Y0)
	var dy := floorf(ya / 40.0) * 40.0
	while dy < yz:
		var e: Vector2 = m.walk_edges(dy)
		for sx: float in [e.x, e.y]:
			var into := 1.0 if sx == e.x else -1.0
			b.circle(Vector2(sx + into * 8.0, dy), 11.0, Color(0.52, 0.46, 0.38))
			b.circle(Vector2(sx + into * 12.0, dy + 14.0), 5.0, Color(0.44, 0.38, 0.32))
		dy += 40.0
	b.flush(m._wc)
	# the salamander on the landing: the landmark, in trencadis, climbing out
	# of the stair's stepped grotto fountain
	var sm: Vector2 = LevelBuild.MOSAIC_SALAMANDER
	if sm.y > vt - 160.0 and sm.y < vb + 160.0:
		var sz: Vector2 = LevelBuild.MOSAIC_SALAMANDER_SIZE
		var b2: ShapeBatch = m._wc     # the world canvas is itself a batch
		# the fountain's three tiers of dripping stone, each a step down the
		# stair, ragged at the edges like the grotto walls
		for tier in range(3):
			var tw := sz.x * 0.5 + 6.0 - float(tier) * 8.0
			var ty0 := sm.y - sz.y * 0.5 + float(tier) * 50.0
			var ty1 := ty0 + 60.0
			var tc := Color(0.62, 0.55, 0.44).lightened(0.10 * float(tier))
			b2.circle(Vector2(sm.x, ty1) + LIGHT * 10.0, tw, Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.18))
			b2.rect(Rect2(sm.x - tw, ty0, tw * 2.0, ty1 - ty0), tc)
			b2.circle(Vector2(sm.x, ty1), tw, tc)
			var rk := ty0 + 6.0
			while rk < ty1 + tw * 0.7:
				var hh := fmod(absf(rk) * 0.37, 1.0)
				var rx := tw if rk < ty1 else sqrt(maxf(0.0, tw * tw - (rk - ty1) * (rk - ty1)))
				for sd: float in [-1.0, 1.0]:
					b2.circle(Vector2(sm.x + sd * (rx - 3.0), rk), 6.0 + hh * 4.0, tc.darkened(0.18 + hh * 0.1))
				rk += 13.0
			# the trickle down its front
			b2.line(Vector2(sm.x - 4.0, ty1 + tw - 10.0), Vector2(sm.x + 2.0, ty1 + tw + 2.0), Color(0.56, 0.70, 0.78, 0.6), 3.0)
		# the basin the water falls into: a trencadis rim round still water
		var bs := sm + Vector2(0, sz.y * 0.5 + 16.0)
		b2.circle(bs, 26.0, Color(0.93, 0.91, 0.85))
		for k in range(14):
			b2.circle(bs + Vector2.from_angle(float(k) * TAU / 14.0) * 22.0, 3.6, SHARDS[(k * 3) % SHARDS.size()])
		b2.circle(bs, 18.0, Color(0.30, 0.48, 0.60))
		b2.circle(bs + Vector2(-5, -5), 8.0, Color(0.42, 0.60, 0.70))
		# its body, head down the stair and tail curling up it: a chain of
		# trencadis scales, fattest at the shoulders, its shadow under it
		var spine := [sm + Vector2(0, 74), sm + Vector2(10, 46), sm + Vector2(-4, 16), sm + Vector2(10, -14),
			sm + Vector2(-2, -44), sm + Vector2(-18, -66), sm + Vector2(-30, -80)]
		var bw := [16.0, 24.0, 27.0, 24.0, 18.0, 12.0, 8.0]
		for k in range(spine.size()):
			b2.circle(spine[k] + LIGHT * 8.0, bw[k], Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.22))
		for leg: Vector2 in [Vector2(-34, 40), Vector2(36, 34), Vector2(-30, -20), Vector2(32, -26)]:
			trencadis_disc(m, b2, sm + leg, 11.0, int(leg.x + leg.y))
		for k in range(spine.size()):
			trencadis_disc(m, b2, spine[k], bw[k], k * 5 + 3)
		# its head, with a blunt snout and two dark eyes
		var hd: Vector2 = sm + Vector2(0, 86)
		b2.draw_colored_polygon(PackedVector2Array([hd + Vector2(-16, -10), hd + Vector2(16, -10), hd + Vector2(10, 16),
			hd + Vector2(-10, 16)]), Color(0.18, 0.62, 0.70))
		trencadis_disc(m, b2, hd, 13.0, 21)
		b2.circle(hd + Vector2(-7, 6), 3.0, Color(0.1, 0.1, 0.1))
		b2.circle(hd + Vector2(7, 6), 3.0, Color(0.1, 0.1, 0.1))
		# the water from its mouth into the basin
		b2.line(hd + Vector2(0, 14), bs + Vector2(0, -6), Color(0.62, 0.78, 0.86, 0.8), 4.0)
	# the hypostyle hall: in the shade under the plaza, its floor darker,
	# the shade thinning out at both ends rather than stopping at a line
	var b3 := ShapeBatch.new()
	var h0: float = LevelBuild.MOSAIC_HALL_Y0
	var h1: float = LevelBuild.MOSAIC_HALL_Y1
	var fade := 220.0
	if h1 - fade < vb + 40.0 and h0 + fade > vt - 40.0:
		var y0 := maxf(vt - 40.0, h1 - fade)
		var y1 := minf(vb + 40.0, h0 + fade)
		var hy := floorf(y0 / 20.0) * 20.0
		while hy < y1:
			var e: Vector2 = m.walk_edges(hy + 10.0)
			var f := smoothstep(0.0, 1.0, clampf(minf(hy - (h1 - fade), (h0 + fade) - hy) / (fade * 2.0), 0.0, 1.0))
			if f > 0.01:
				b3.rect(Rect2(e.x, hy, e.y - e.x, 20.0), Color(0.10, 0.08, 0.06, 0.20 * f))
			hy += 20.0
		# Jujol's ceiling vault medallions: the celebrated trencadis sunbursts
		# set into the ceiling domes between the columns, where Gaudi omitted columns
		for mj: Vector2 in LevelBuild.MOSAIC_JUJOL_MEDALLIONS:
			if mj.y > vt - 60.0 and mj.y < vb + 60.0:
				b3.circle(mj + LIGHT * 6.0, 27.0, Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.22))
				b3.circle(mj, 25.0, Color(0.92, 0.90, 0.84))
				trencadis_disc(m, b3, mj, 21.0, int(absf(mj.x * 3.0 + mj.y)))
				b3.circle(mj, 8.0, Color(0.96, 0.94, 0.88))
				b3.circle(mj, 5.0, Color(0.86, 0.76, 0.28))
	# the serpentine bench: the plaza's edges, finished in trencadis, its
	# backrest along the outside and its shadow falling off it
	var p0: float = LevelBuild.MOSAIC_PLAZA_Y0 + 40.0
	var p1: float = LevelBuild.MOSAIC_PLAZA_Y1 - 40.0
	if p1 < vb + 40.0 and p0 > vt - 40.0:
		var y0 := maxf(vt - 40.0, p1)
		var y1 := minf(vb + 40.0, p0)
		var by := floorf(y0 / 24.0) * 24.0
		while by < y1:
			var ea: Vector2 = m.walk_edges(by)
			var ez: Vector2 = m.walk_edges(by + 24.0)
			for sd: float in [-1.0, 1.0]:
				var xa: float = ea.x if sd < 0.0 else ea.y
				var xz: float = ez.x if sd < 0.0 else ez.y
				b3.line(Vector2(xa + sd * 14.0, by) + LIGHT * 8.0, Vector2(xz + sd * 14.0, by + 24.0) + LIGHT * 8.0,
					Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.22), 30.0)
			by += 24.0
		by = floorf(y0 / 24.0) * 24.0
		while by < y1:
			var ea: Vector2 = m.walk_edges(by)
			var ez: Vector2 = m.walk_edges(by + 24.0)
			for sd: float in [-1.0, 1.0]:
				var xa: float = ea.x if sd < 0.0 else ea.y
				var xz: float = ez.x if sd < 0.0 else ez.y
				# the backrest's top, a rolled rim of white tile
				b3.line(Vector2(xa + sd * 24.0, by), Vector2(xz + sd * 24.0, by + 24.0), Color(0.80, 0.76, 0.68), 9.0)
				b3.line(Vector2(xa + sd * 22.0, by), Vector2(xz + sd * 22.0, by + 24.0), Color(0.97, 0.96, 0.92), 3.0)
				trencadis_band(m, b3, Vector2(xa + sd * 8.0, by), Vector2(xz + sd * 8.0, by + 24.0), 20.0,
					int(absf(by)) % (11 if sd < 0.0 else 13))
			by += 24.0
	# the viaduct: the covered walk under the road, its colonnade down the
	# east side, the planted slope of the hill on its west
	var v0: float = LevelBuild.MOSAIC_VIADUCT_Y0
	var v1: float = LevelBuild.MOSAIC_VIADUCT_Y1
	if v1 < vb + 60.0 and v0 > vt - 60.0:
		var y0 := maxf(vt - 60.0, v1)
		var y1 := minf(vb + 60.0, v0)
		# the slope: one smooth bank that tapers in and out at its ends (#21),
		# dry grass with scrub and stones on it, a rubble kerb at its foot
		var bank := PackedVector2Array()
		var foot := PackedVector2Array()
		var vy := floorf(y0 / 25.0) * 25.0
		while vy <= y1 + 25.0:
			var yy := minf(vy, v0)
			var e: Vector2 = m.walk_edges(yy)
			var f := smoothstep(0.0, 1.0, clampf(minf(yy - v1, v0 - yy) / 180.0, 0.0, 1.0))
			bank.append(Vector2(e.x - 4.0 - 130.0 * f, yy))
			foot.append(Vector2(e.x, yy))
			if yy >= v0:
				break
			vy += 25.0
		if bank.size() >= 2:
			var poly := bank.duplicate()
			for i in range(foot.size() - 1, -1, -1):
				poly.append(foot[i])
			b3.polygon(poly, Color(0.58, 0.56, 0.38))
			for i in range(bank.size()):
				var w: float = foot[i].x - bank[i].x
				if w < 24.0:
					continue
				var hh := fmod(absf(bank[i].y) * 0.731, 1.0)
				var sp := Vector2(bank[i].x + w * (0.25 + hh * 0.5), bank[i].y + hh * 10.0)
				if int(absf(bank[i].y) / 25.0) % 2 == 0:
					b3.circle(sp + LIGHT * 4.0, 9.0, Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.2))
					b3.circle(sp, 8.0 + hh * 4.0, Color(0.38, 0.44, 0.28))
				else:
					b3.circle(sp, 3.5, Color(0.66, 0.60, 0.50))
				b3.circle(foot[i] + Vector2(-5.0, 12.0 * hh), 6.0, Color(0.52, 0.45, 0.36))
		# the road over the covered walk: its shade over the colonnade
		vy = floorf(y0 / 25.0) * 25.0
		while vy < y1:
			var e: Vector2 = m.walk_edges(vy + 12.5)
			var f := smoothstep(0.0, 1.0, clampf(minf(vy - v1, v0 - vy) / 160.0, 0.0, 1.0))
			if f > 0.01:
				var x0: float = e.y - LevelBuild.MOSAIC_VIADUCT_INNER - 26.0
				b3.rect(Rect2(x0, vy, e.y - x0, 25.0), Color(0.10, 0.08, 0.06, 0.16 * f))
				b3.rect(Rect2(x0 - 14.0, vy, 14.0, 25.0), Color(0.10, 0.08, 0.06, 0.07 * f))
			vy += 25.0
	# the calvary: a heap of rubble stone at the top, steps up its south
	# face, and the three crosses standing on it
	var cv: Vector2 = LevelBuild.MOSAIC_CALVARY
	if cv.y > vt - 140.0 and cv.y < vb + 140.0:
		b3.circle(cv + LIGHT * 18.0, 74.0, Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.22))
		b3.circle(cv, 72.0, Color(0.48, 0.41, 0.33))
		b3.circle(cv - LIGHT * 10.0, 56.0, Color(0.56, 0.48, 0.38))
		b3.circle(cv - LIGHT * 16.0, 36.0, Color(0.62, 0.54, 0.43))
		for k in range(26):
			var ang := float(k) * 2.39996
			var rr := 14.0 + fmod(float(k) * 23.7, 54.0)
			var q := cv + Vector2(cos(ang), sin(ang)) * rr
			var lit := 0.5 + 0.5 * Vector2(cos(ang), sin(ang)).dot(-LIGHT)
			b3.circle(q, 6.0 + fmod(float(k) * 3.1, 4.0), Color(0.44, 0.37, 0.30).lightened(0.18 * lit))
		# the steps, up from the path
		for k in range(5):
			var sy := cv.y + 70.0 - float(k) * 10.0
			b3.rect(Rect2(cv.x - 50.0, sy - 9.0, 36.0, 9.0), Color(0.66, 0.60, 0.50).darkened(0.05 * float(k)))
			b3.line(Vector2(cv.x - 50.0, sy - 9.0), Vector2(cv.x - 14.0, sy - 9.0), Color(0.80, 0.74, 0.64), 1.5)
		# three stone crosses, the middle one tallest, each throwing its shadow
		for cx: Array in [[Vector2(-30, -6), 0.8], [Vector2(4, -18), 1.15], [Vector2(32, 4), 0.8]]:
			var at: Vector2 = cv + (cx[0] as Vector2)
			var s := float(cx[1])
			var sh := Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.3)
			b3.line(at, at + LIGHT * 46.0 * s, sh, 6.0 * s)
			b3.line(at + LIGHT * 30.0 * s - LIGHT.orthogonal() * 12.0 * s, at + LIGHT * 30.0 * s + LIGHT.orthogonal() * 12.0 * s, sh, 5.0 * s)
			b3.circle(at, 8.0 * s, Color(0.40, 0.34, 0.28))
			b3.rect(Rect2(at - Vector2(3.5, 18.0) * s, Vector2(7.0, 30.0) * s), Color(0.90, 0.88, 0.84))
			b3.rect(Rect2(at - Vector2(13.0, 10.0) * s, Vector2(26.0, 6.0) * s), Color(0.90, 0.88, 0.84))
			b3.rect(Rect2(at - Vector2(3.5, 18.0) * s, Vector2(2.5, 30.0) * s), Color(0.98, 0.97, 0.94))
	b3.flush(m._wc)
	# the gatehouses either side of the entrance: gingerbread walls, wavy
	# roofs iced white with mosaic caps, one with the mushroom and its cross
	for gs: float in [-1.0, 1.0]:
		var e: Vector2 = m.walk_edges(-60.0)
		var gc := Vector2((e.x - 130.0) if gs < 0.0 else (e.y + 130.0), -60.0)
		if gc.y < vt - 200.0 or gc.y > vb + 200.0:
			continue
		var b4: ShapeBatch = m._wc     # the world canvas is itself a batch
		b4.rect(Rect2(gc - Vector2(90, 110) + LIGHT * 16.0, Vector2(180, 220)), Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.25))
		b4.rect(Rect2(gc - Vector2(90, 110), Vector2(180, 220)), Color(0.66, 0.46, 0.30))
		for w in range(9):
			b4.circle(gc + Vector2(-80.0 + float(w) * 20.0, -104.0), 12.0, Color(0.96, 0.94, 0.90))
			b4.circle(gc + Vector2(-80.0 + float(w) * 20.0, 104.0), 12.0, Color(0.96, 0.94, 0.90))
		b4.rect(Rect2(gc - Vector2(70, 80), Vector2(140, 160)), Color(0.56, 0.36, 0.22))
		trencadis_disc(m, b4, gc + Vector2(-34, -30), 22.0, 4 if gs < 0.0 else 9)
		trencadis_disc(m, b4, gc + Vector2(36, 34), 18.0, 7 if gs < 0.0 else 2)
		if gs > 0.0:
			# the mushroom spire and its cross, from above
			b4.circle(gc + Vector2(30, -40), 26.0, Color(0.86, 0.24, 0.26))
			for d in range(6):
				b4.circle(gc + Vector2(30, -40) + Vector2.from_angle(float(d)) * 16.0, 5.0, Color(0.97, 0.96, 0.92))
			b4.rect(Rect2(gc + Vector2(26, -56), Vector2(8, 32)), Color(0.90, 0.88, 0.84))
			b4.rect(Rect2(gc + Vector2(14, -44), Vector2(32, 8)), Color(0.90, 0.88, 0.84))


static func tick_crowd(m: Node2D) -> void:
	var cy: float = m.cam.position.y
	if not m.mosaic_queue_out:
		m.mosaic_queue_out = true
		var qe: Vector2 = m.walk_edges(0.0)
		for i in range(QUEUE):
			var qy := 150.0 - float(i) * 36.0
			var tw: Node2D = m._spawn_tourist(Vector2(qe.x + 70.0 + m.crowd_rng.randf_range(-6.0, 6.0), qy), -1.0)
			tw.stand("queue", Vector2.ZERO)
	var sm: Vector2 = LevelBuild.MOSAIC_SALAMANDER
	if not m.mosaic_posers_out and cy < sm.y + 900.0:
		m.mosaic_posers_out = true
		for off: Vector2 in POSERS:
			var tw: Node2D = m._spawn_tourist(sm + off, -1.0)
			tw.stand("pose", sm)
	# the plaza: people in the serpentine bench's bays, photographing the
	# view out over the city from it, a pair in every other one
	if not m.mosaic_bays_out and cy < LevelBuild.MOSAIC_PLAZA_Y0 + 900.0:
		m.mosaic_bays_out = true
		var bays := bays(m)
		for bi in range(bays.size()):
			var bp: Vector2 = bays[bi]
			var out := -1.0 if bp.x < m.walk_cx else 1.0
			for k in range(2 if bi % 2 == 0 else 1):
				var tw: Node2D = m._spawn_tourist(bp + Vector2(0.0, -16.0 + 32.0 * float(k)), -1.0)
				tw.stand("pose", bp + Vector2(out * 400.0, -60.0 + 120.0 * float(k)))
	# a dog drinking at the salamander is the photo everyone wanted
	if not m.mosaic_aww and m.dog.global_position.distance_to(sm) < 130.0:
		for tw: Node2D in m.get_tree().get_nodes_in_group("tourists"):
			if tw.mode == "pose" and tw.global_position.distance_to(m.dog.global_position) < 200.0:
				m.mosaic_aww = true
				m.float_text(tw.global_position + Vector2(0, -26), "aww, look at her", Color(1, 0.9, 0.95), m.POP_SAY)
				tw.photo_t = 1.2
				break


# El Mosaic's off-leash space is the top of the hill past the calvary: dry
# ground, not a lawn - packed ochre earth worn pale where everyone walks,
# sun-bleached grass in tufts, rubble stones, and rosemary and lentisk scrub
# between the pines
const HILL_EARTH := Color(0.66, 0.56, 0.40)
const HILL_SCRUB := Color(0.40, 0.40, 0.26)


static func draw_clearing(m: Node2D, c: Object, r: Rect2) -> void:
	var b := ShapeBatch.new()
	b.rect(r, HILL_EARTH)
	b.circle(r.get_center(), 190.0, Color(0.80, 0.70, 0.52, 0.5))       # worn pale
	b.circle(r.get_center() + Vector2(-60, 40), 120.0, Color(0.82, 0.73, 0.55, 0.4))
	var k := 0
	var y := r.position.y + 14.0
	while y < r.end.y:
		var x := r.position.x + fmod(y * 0.37, 41.0)
		while x < r.end.x:
			var h := fmod(absf(x * 12.9898 + y * 78.233), 1.0)
			var at := Vector2(x, y + h * 20.0)
			var mid := at.distance_to(r.get_center()) < 200.0
			if k % 5 == 0 and not mid:
				# a clump of scrub, darker green-grey, with its shadow
				b.circle(at + LIGHT * 5.0, 13.0, Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.18))
				b.circle(at, 12.0 + h * 5.0, Color(0.36, 0.40, 0.26))
				b.circle(at - LIGHT * 4.0, 6.0 + h * 3.0, Color(0.46, 0.50, 0.32))
			elif k % 3 == 0:
				b.circle(at, 2.5 + h * 3.0, Color(0.56, 0.50, 0.42))       # a stone
			else:
				# dry grass, bleached
				for g in range(3):
					var ga := -PI * 0.5 + (float(g) - 1.0) * 0.45
					b.line(at, at + Vector2.from_angle(ga) * (6.0 + h * 5.0), Color(0.78, 0.70, 0.44, 0.9), 1.6)
			k += 1
			x += 46.0 + h * 30.0
		y += 38.0
	b.flush(c)
	m._draw_freedom_benches(c, r, Color(0.42, 0.33, 0.22))
	m._freedom_sign(c, r, m.gate_text, "the hilltop, off leash")


# a rubble-stone planter with an agave in it (main.WALK_MODULES draw_bollard)
static func draw_bollard(m: Node2D, wc: ShapeBatch, h) -> void:
	var hp: Vector2 = h.pos
	m.contact_shadow(wc, hp, 15.0, 6.0, 0.22)
	wc.draw_circle(hp, 15.0, Color(0.56, 0.48, 0.38) if not h.done else Color(0.48, 0.42, 0.34))
	wc.draw_circle(hp, 11.0, Color(0.34, 0.28, 0.22))
	for f in range(7):
		wc.draw_line(hp, hp + Vector2.from_angle(float(f) * TAU / 7.0) * 15.0, Color(0.44, 0.60, 0.54), 3.5)
	if not h.done and h.progress > 0.0:
		wc.draw_arc(hp, 21.0, -PI / 2.0, -PI / 2.0 + TAU * h.progress / 0.8, 20, Color(1, 0.95, 0.7), 3.0)
