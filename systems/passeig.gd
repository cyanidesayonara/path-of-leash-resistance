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


# SAND CREEP: what the wind and a thousand pairs of feet bring up off the
# beach, all down the walk. Drawing only - the six drifts in the level data
# are the sand that slows her; this is the dusting round them that makes a
# seafront look lived on. It banks up along the deck's seaward edge, lodges in
# the plank seams and the paving joints, blows inland in thin wisps that fade
# the further they get, piles against the windward side of the palm kerbs and
# the benches, and leaves the beach on people's feet up every ramp.
# Hashed from position, never the RNG: the same walk every visit.
const CREEP_COL := Color(0.87, 0.79, 0.59)        # dry sand, on the timber
const CREEP_DUST := Color(0.86, 0.74, 0.48)       # warmer, to show on pale concrete
const CREEP_DECK_X := 380.0                       # the sand's edge, where the deck starts
const CREEP_INLAND := 980.0                       # the cafe strip, where it gives out
const CREEP_FRINGE_MAX := 24.0                    # widest spill over the deck edge
const CREEP_WISP_ROW := 38.0                      # one chance of a wisp per this many px
const CREEP_WISP_CHANCE := 0.5
const CREEP_GRAIN_ROW := 18.0
const CREEP_DUSTING_ROW := 110.0
const CREEP_DUSTING_CHANCE := 0.45
const CREEP_CHUNK := 200.0                        # built and cached a stretch at a time
const CREEP_REACH := 80.0                         # furthest a piece reaches from its anchor

static var _creep_cache := {}


static func _hash(i: float, s: float) -> float:
	var v := sin(i * 12.9898 + s * 78.233) * 43758.5453
	return v - floor(v)


# slow, smooth 0..1 along the walk: where the wind has piled more
static func _swell(y: float, s: float) -> float:
	return clampf(0.5 + 0.32 * sin(y * 0.0123 + s) + 0.18 * sin(y * 0.0317 + s * 2.3), 0.0, 1.0)


static func _fringe(y: float) -> float:
	return 4.0 + CREEP_FRINGE_MAX * pow(_swell(y, 1.3), 2.4) + 5.0 * _swell(y * 3.1, 4.0)


# a tongue of blown sand from `from`, `length` long inland, blunt at the
# seaward end and thinning to nothing; its edge ragged by `s`
static func _tongue(b: ShapeBatch, from: Vector2, length: float, width: float, slope: float, s: float, col: Color) -> void:
	const STEPS := 7
	var top := PackedVector2Array()
	var bot := PackedVector2Array()
	for j in range(STEPS + 1):
		var t := float(j) / float(STEPS)
		var hw := width * 0.5 * pow(1.0 - t, 0.8) * minf(1.0, 0.45 + t * 3.0)
		var rag := 0.7 + 0.6 * _hash(float(j), s)
		var rag2 := 0.7 + 0.6 * _hash(float(j) + 31.0, s)
		var c := from + Vector2(t * length, t * length * slope)
		top.append(c + Vector2(0.0, -hw * rag))
		bot.append(c + Vector2(0.0, hw * rag2))
	bot.reverse()
	top.append_array(bot)
	b.polygon(top, col)


# a soft blot with a wobbling edge, `s` picking the wobble
static func _smudge(b: ShapeBatch, at: Vector2, rx: float, ry: float, s: float, col: Color) -> void:
	const N := 14
	var poly := PackedVector2Array()
	for j in range(N):
		var ang := TAU * float(j) / float(N)
		var r := 0.72 + 0.22 * sin(ang * 2.0 + s) + 0.16 * _hash(float(j), s)
		poly.append(at + Vector2(cos(ang) * rx * r, sin(ang) * ry * r))
	b.polygon(poly, col)


# The sand never moves, so each CREEP_CHUNK of the walk is built once, as
# triangles, the first time it comes into view, and every frame after that
# only copies the visible chunks into the world's batch. Building it per
# frame cost the world draw ~2.7 ms.
static func _sand_creep(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	var lo := maxf(vt - CREEP_REACH, m.GATE_Y - 30.0)
	var hi := minf(vb + CREEP_REACH, m.START_Y + 200.0)
	if hi <= lo:
		return
	var wet := Game.weather == "rain"
	var c := int(floorf(lo / CREEP_CHUNK))
	while float(c) * CREEP_CHUNK < hi:
		var key := Vector2i(c, 1 if wet else 0)
		var chunk: ShapeBatch = _creep_cache.get(key)
		if chunk == null:
			chunk = _creep_chunk(m, float(c) * CREEP_CHUNK, float(c + 1) * CREEP_CHUNK, wet)
			_creep_cache[key] = chunk
		chunk.append_to(b)
		c += 1


# everything whose anchor lies in [y0, y1): the first multiple of each row's
# step at or after y0, so a row is in exactly one chunk
static func _row0(y0: float, step: float) -> float:
	return ceilf(y0 / step) * step


static func _creep_chunk(m: Node2D, y0: float, y1: float, wet: bool) -> ShapeBatch:
	var b := ShapeBatch.new()
	var sand := CREEP_COL.darkened(0.22) if wet else CREEP_COL
	var dust := CREEP_DUST.darkened(0.22) if wet else CREEP_DUST
	var top := maxf(y0, m.GATE_Y - 30.0)
	var bot := minf(y1, m.START_Y + 200.0)
	if bot <= top:
		return b
	# the spill over the deck edge: one ragged band, row by row, so it never
	# shows a seam; a little denser hard against the sand
	const ROW := 16.0
	var y := _row0(top, ROW)
	while y < bot:
		var w0 := _fringe(y)
		var w1 := _fringe(y + ROW)
		var x := CREEP_DECK_X - 2.0
		b.polygon(PackedVector2Array([Vector2(x, y), Vector2(x + w0, y), Vector2(x + w1, y + ROW), Vector2(x, y + ROW)]),
			Color(sand.r, sand.g, sand.b, 0.24))
		b.polygon(PackedVector2Array([Vector2(x, y), Vector2(x + w0 * 0.5, y), Vector2(x + w1 * 0.5, y + ROW), Vector2(x, y + ROW)]),
			Color(sand.r, sand.g, sand.b, 0.18))
		y += ROW
	# sand lodged in the gaps between the planks, here and there, from the
	# edge of the spill
	const PLANK := 22.0
	y = _row0(top, PLANK)
	while y < bot:
		var k := y / PLANK
		var edge := CREEP_DECK_X + _fringe(y) * 0.8
		var run := 6.0 + 34.0 * pow(_hash(k, 2.0), 2.0)
		if _hash(k, 3.0) > 0.5 and edge + run > CREEP_DECK_X + 12.0:
			var mid := minf(edge + run * 0.5, 486.0)
			b.line(Vector2(edge - 4.0, y - 1.0), Vector2(mid, y - 1.0), Color(sand.r, sand.g, sand.b, 0.3), 1.5)
			b.line(Vector2(mid, y - 1.0), Vector2(minf(edge + run, 488.0), y - 1.0), Color(sand.r, sand.g, sand.b, 0.14), 1.5)
		if _hash(k, 5.0) > 0.86:
			var px := 400.0 + 70.0 * _hash(k, 6.0)
			b.line(Vector2(px, y - 1.0), Vector2(px + 6.0 + 12.0 * _hash(k, 7.0), y - 1.0),
				Color(sand.r, sand.g, sand.b, 0.26), 1.5)
		y += PLANK
	# the wind's wisps: mostly starting on the deck or the bike path and
	# reaching across the promenade, fainter the further inland
	y = _row0(top, CREEP_WISP_ROW)
	while y < bot:
		var k := y / CREEP_WISP_ROW
		if _hash(k, 7.0) < CREEP_WISP_CHANCE:
			var x0 := 392.0 + 230.0 * pow(_hash(k, 8.0), 1.8)
			var reach := 1.0 - (x0 - 392.0) / 300.0
			var length := minf((36.0 + 170.0 * pow(_hash(k, 9.0), 1.6)) * (0.5 + 0.5 * reach), CREEP_INLAND - x0)
			var width := 7.0 + 14.0 * _hash(k, 10.0)
			var slope := 0.16 * sin(y * 0.0007) + 0.08 * (_hash(k, 11.0) - 0.5)
			var at := Vector2(x0, y + CREEP_WISP_ROW * _hash(k, 12.0))
			var col := sand if x0 < 490.0 else dust
			var a := 0.07 + 0.06 * reach
			for pass_i in range(2):
				var g := 1.0 - float(pass_i) * 0.4
				_tongue(b, at, length * g, width * (0.6 + 0.4 * g), slope, k + float(pass_i) * 17.0,
					Color(col.r, col.g, col.b, a))
		# a few faint ones well out on the promenade
		if _hash(k, 13.0) < 0.18:
			var at := Vector2(600.0 + 300.0 * _hash(k, 14.0), y + CREEP_WISP_ROW * _hash(k, 15.0))
			_tongue(b, at, 22.0 + 60.0 * _hash(k, 16.0), 6.0 + 8.0 * _hash(k, 17.0), 0.05, k + 51.0,
				Color(dust.r, dust.g, dust.b, 0.08))
		y += CREEP_WISP_ROW
	# thin dustings trodden out over the paving: soft, irregular, stretched
	# along the wind, and far thinner than the drifts that slow her
	y = _row0(top, CREEP_DUSTING_ROW)
	while y < bot:
		var k := y / CREEP_DUSTING_ROW
		if _hash(k, 40.0) < CREEP_DUSTING_CHANCE:
			var u := _hash(k, 41.0)
			var at := Vector2(500.0 + 420.0 * pow(u, 1.5), y + CREEP_DUSTING_ROW * _hash(k, 42.0))
			var size := (1.0 - 0.55 * u) * (0.5 + _hash(k, 43.0))
			var rx := 26.0 + 50.0 * size
			var ry := 12.0 + 18.0 * size * _hash(k, 44.0) + 6.0
			_smudge(b, at, rx, ry, k, Color(dust.r, dust.g, dust.b, 0.08))
			_smudge(b, at - Vector2(rx * 0.18, 0.0), rx * 0.6, ry * 0.65, k + 9.0, Color(dust.r, dust.g, dust.b, 0.06))
		y += CREEP_DUSTING_ROW
	# grit in the paving joints, from the seaward end
	const JOINT := 150.0
	y = _row0(top, JOINT)
	while y < bot:
		var k := y / JOINT
		b.line(Vector2(572.0, y), Vector2(572.0 + 10.0 + 60.0 * pow(_hash(k, 18.0), 2.0), y),
			Color(dust.r, dust.g, dust.b, 0.22), 1.5)
		y += JOINT
	# a little banked against the windward side of the seaward palms' kerbs,
	# and less at the cafe side's
	for ps: Vector2 in m.palm_spots:
		if ps.y < top or ps.y >= bot:
			continue
		var seaward := ps.x < 700.0
		var hs := _hash(ps.y, 19.0)
		if not seaward and hs < 0.55:
			continue
		var col := sand if seaward else dust
		var bank := PackedVector2Array()
		var rx := (6.0 + 6.0 * hs) * (1.0 if seaward else 0.6)
		var ry := 26.0 + 6.0 * _hash(ps.y, 20.0)
		for j in range(9):
			var ang := PI * 0.5 + PI * float(j) / 8.0
			bank.append(Vector2(ps.x - 27.0, ps.y) + Vector2(cos(ang) * rx, sin(ang) * ry))
		b.polygon(bank, Color(col.r, col.g, col.b, 0.26 if seaward else 0.16))
	# the same against the benches' seaward side
	for bn: Vector2 in m.benches:
		if bn.y < top or bn.y >= bot:
			continue
		var hb := _hash(bn.y, 21.0)
		var mound := PackedVector2Array()
		for j in range(9):
			var ang := PI * 0.5 + PI * float(j) / 8.0
			mound.append(Vector2(bn.x - 8.0, bn.y) + Vector2(cos(ang) * (4.0 + 4.0 * hb), sin(ang) * 22.0))
		b.polygon(mound, Color(dust.r, dust.g, dust.b, 0.2))
	# carried up off the beach on feet: a light smear at the head of each
	# ramp, then trails of prints fading out across the promenade
	var heads: Array[float] = [LevelBuild.BEACH_TOWER.y]
	for sp: Vector2 in LevelBuild.BEACH_SHOWERS:
		heads.append(sp.y)
	for ry0: float in heads:
		if ry0 < top or ry0 >= bot:
			continue
		_tongue(b, Vector2(CREEP_DECK_X, ry0), 120.0, 34.0, 0.0, ry0, Color(sand.r, sand.g, sand.b, 0.16))
		for tr in range(3):
			var off := -14.0 + 13.0 * float(tr) + 4.0 * _hash(ry0, 22.0 + float(tr))
			var span := 160.0 + 180.0 * _hash(ry0, 25.0 + float(tr))
			var step := 0
			var fx := 400.0 + 10.0 * float(tr)
			while fx < 400.0 + span:
				var fade := 1.0 - (fx - 400.0) / span
				var side := 4.0 if step % 2 == 0 else -4.0
				var fp := Vector2(fx, ry0 + off + side + 7.0 * sin(fx * 0.017 + float(tr)))
				var col := sand if fx < 490.0 else dust
				# heading inland: the ball of the foot ahead, the heel behind
				var pc := Color(col.r, col.g, col.b, 0.26 * fade + 0.04)
				b.coarse(fp + Vector2(2.2, 0.0), 2.4, pc)
				b.coarse(fp + Vector2(-2.6, 0.0), 1.9, pc)
				fx += 19.0 + 3.0 * _hash(fx, 28.0)
				step += 1
	# loose grains, thickest by the sand
	y = _row0(top, CREEP_GRAIN_ROW)
	while y < bot:
		var k := y / CREEP_GRAIN_ROW
		var n := 2 + int(4.0 * _hash(k, 30.0))
		for gi in range(n):
			var u := _hash(k * 7.0 + float(gi), 31.0)
			var gx := CREEP_DECK_X + (CREEP_INLAND - CREEP_DECK_X) * pow(u, 2.6)
			var gy := y + CREEP_GRAIN_ROW * _hash(k * 7.0 + float(gi), 32.0)
			var fade := 1.0 - (gx - CREEP_DECK_X) / (CREEP_INLAND - CREEP_DECK_X)
			var col := sand if gx < 490.0 else dust
			# a grain is a pixel or two across: a square, two triangles
			var gs := 1.4 + 1.6 * _hash(k * 7.0 + float(gi), 33.0)
			b.rect(Rect2(gx, gy, gs, gs), Color(col.r, col.g, col.b, 0.14 + 0.3 * fade))
		y += CREEP_GRAIN_ROW
	return b


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
	if LevelBuild.BEACH_PIER_Y > vt - 120.0 and LevelBuild.BEACH_PIER_Y < vb + 120.0:
		_pier(m)
		var inward := LevelBuild.beach_ramp_inward()
		_monkey(m, LevelBuild.beach_monkey(), atan2(inward.y, inward.x))
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


# EL PONT DEL PETROLI, from above. The wedge and the pier are planked across,
# as a pier is, the boards weathered silver on the pier and browner on the
# wedge, each board its own shade. Pale concrete curbs edge the pier, and its
# rails are stainless: raked posts and cables. Where the wedge stands over
# the sand it throws a shadow, and the rocks banked along its sides and the
# pier's foot are pale riprap. The gate at the head of the pier, between two
# rust-red posts with red bands, stands open.
const PIER_PLANK := Color(0.64, 0.62, 0.58)
const WEDGE_PLANK := Color(0.48, 0.28, 0.22)             # the boardwalk's own timber
const STEP_RISER := Color(0.28, 0.15, 0.11)
const STEP_NOSING := Color(0.62, 0.40, 0.31)
const STEP_W := 11.0
const PLANK_SEAM := Color(0.30, 0.26, 0.22, 0.55)
const PIER_CURB := Color(0.84, 0.83, 0.79)
const PIER_STEEL := Color(0.80, 0.82, 0.84)
const PIER_STEEL_DARK := Color(0.46, 0.48, 0.50)
const PIER_ROCK := Color(0.86, 0.85, 0.82)               # pale granite riprap
const PIER_ROCK_DARK := Color(0.66, 0.65, 0.62)
const GATE_RUST := Color(0.48, 0.26, 0.16)
const PLANK_W := 6.0


static func _pier(m: Node2D) -> void:
	var y := LevelBuild.BEACH_PIER_Y
	var h := LevelBuild.BEACH_PIER_HALF
	var tip := LevelBuild.BEACH_RAMP_TIP_X
	var base := LevelBuild.BEACH_RAMP_BASE_X
	var raised := LevelBuild.BEACH_RAMP_RAISED_X
	var far := -400.0
	var sh := Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.26)
	var b := ShapeBatch.new()
	# shadows: the pier's on the water and the sand, the wedge's where it is
	# above the sand, deeper toward the tip
	b.rect(Rect2(Vector2(far, y - h - 5.0) + m.LIGHT * 9.0, Vector2(tip - far, h * 2.0 + 10.0)), sh)
	var hr := LevelBuild.beach_ramp_half_at(raised)
	b.polygon(PackedVector2Array([Vector2(raised, y + hr), Vector2(tip, y + h),
		Vector2(tip, y + h) + m.LIGHT * 9.0, Vector2(raised, y + hr) + m.LIGHT * 2.0]), sh)
	# the rocks, under everything else
	for rk: Vector2 in LevelBuild.beach_pier_rocks():
		var k := rk.x * 0.37 + rk.y * 0.11
		var r := LevelBuild.BEACH_ROCK_R * (0.85 + 0.35 * _hash(k, 3.0))
		var pts := PackedVector2Array()
		for i in range(7):
			var a := TAU * (float(i) + 0.4 * _hash(k + float(i), 9.0)) / 7.0 + _hash(k, 7.0)
			pts.append(rk + Vector2(cos(a) * 1.15, sin(a) * 0.9).rotated(_hash(k, 2.0) * PI) * r * (0.7 + 0.45 * _hash(k + float(i), 5.0)))
		var shp := PackedVector2Array()
		for q: Vector2 in pts:
			shp.append(q + m.LIGHT * 3.0)
		b.polygon(shp, sh)
		b.polygon(pts, PIER_ROCK_DARK.lerp(PIER_ROCK, _hash(k, 11.0)))
		b.circle(rk - m.LIGHT * r * 0.3, r * 0.45, PIER_ROCK.lightened(0.08))
	# the pier: curbs, then the planks between them
	b.rect(Rect2(far, y - h - 5.0, tip - far + 1.0, h * 2.0 + 10.0), PIER_CURB)
	var x := tip
	var n := 0
	while x > far:
		var tone := 0.9 + 0.18 * _hash(float(n), 13.0)
		var col := Color(PIER_PLANK.r * tone, PIER_PLANK.g * tone, PIER_PLANK.b * tone)
		b.rect(Rect2(x - PLANK_W, y - h, PLANK_W - 0.8, h * 2.0), col)
		x -= PLANK_W
		n += 1
	# the wedge: in the boardwalk's own timber, a flight of long steps up from
	# the boardwalk to the pier, each tread planked along its length and its
	# riser a dark line on the landward side, out of the light
	x = base
	n = 0
	while x > tip + 0.5:
		var x0 := maxf(tip, x - STEP_W)
		var ha := LevelBuild.beach_ramp_half_at(x)
		var hb := LevelBuild.beach_ramp_half_at(x0)
		var tone := 0.92 + 0.12 * _hash(float(n), 17.0)
		var col := Color(WEDGE_PLANK.r * tone, WEDGE_PLANK.g * tone, WEDGE_PLANK.b * tone)
		b.polygon(PackedVector2Array([Vector2(x, y - ha), Vector2(x, y + ha), Vector2(x0, y + hb), Vector2(x0, y - hb)]), col)
		for k in range(1, 3):
			var sx := lerpf(x, x0, float(k) / 3.0)
			var sh2 := LevelBuild.beach_ramp_half_at(sx)
			b.line(Vector2(sx, y - sh2), Vector2(sx, y + sh2), PLANK_SEAM, 0.8)
		b.line(Vector2(x - 1.0, y - ha), Vector2(x - 1.0, y + ha), STEP_RISER, 2.0)
		b.line(Vector2(x0 + 1.0, y - hb), Vector2(x0 + 1.0, y + hb), STEP_NOSING, 1.0)
		x -= STEP_W
		n += 1
	# the wedge's edges: a hardwood trim, and up its top half the rails
	for side: float in [-1.0, 1.0]:
		b.line(Vector2(raised, y + side * hr), Vector2(tip, y + side * h), STEP_RISER, 2.5)
		var top := Vector2(tip, y + side * (h + 1.0))
		var mid := Vector2(lerpf(tip, raised, 0.55), y + side * (LevelBuild.beach_ramp_half_at(lerpf(tip, raised, 0.55)) - 2.0))
		b.line(top, mid, PIER_STEEL, 2.0)
		for k in range(1, 4):
			var at := top.lerp(mid, float(k) / 3.0)
			b.rect(Rect2(at - Vector2(1.5, 1.5), Vector2(3.0, 3.0)), PIER_STEEL_DARK)
	# the pier's rails: a steel top rail on each curb, raked posts, two cables
	for side: float in [-1.0, 1.0]:
		var ry := y + side * (h + 3.0)
		b.line(Vector2(far, ry + side * 1.5), Vector2(tip, ry + side * 1.5), Color(PIER_STEEL.r, PIER_STEEL.g, PIER_STEEL.b, 0.55), 0.8)
		b.line(Vector2(far, ry - side * 1.5), Vector2(tip, ry - side * 1.5), Color(PIER_STEEL.r, PIER_STEEL.g, PIER_STEEL.b, 0.55), 0.8)
		var px := tip - 14.0
		while px > far:
			b.line(Vector2(px, ry), Vector2(px + 3.0, ry + side * 3.0), PIER_STEEL_DARK, 2.0)
			px -= 22.0
		b.line(Vector2(far, ry), Vector2(tip, ry), PIER_STEEL, 2.0)
	# the gate: two rust posts at the head of the pier with red bands, and its
	# two leaves swung open against the rails
	for side: float in [-1.0, 1.0]:
		var post := Vector2(tip - 3.0, y + side * (h + 3.0))
		b.rect(Rect2(post + Vector2(-3.5, -3.5) + m.LIGHT * 3.0, Vector2(7.0, 7.0)), sh)
		b.rect(Rect2(post - Vector2(3.5, 3.5), Vector2(7.0, 7.0)), GATE_RUST)
		b.line(post + Vector2(-3.5, 1.5), post + Vector2(1.5, -3.5), Color(0.80, 0.18, 0.16), 1.6)
		b.line(post + Vector2(-1.5, 3.5), post + Vector2(3.5, -1.5), Color(0.80, 0.18, 0.16), 1.6)
		var leaf_end := post + Vector2(-h + 2.0, -side * 2.0)
		b.line(post + Vector2(-3.5, -side * 2.0), leaf_end, PIER_STEEL_DARK, 2.0)
		var lx := post.x - 7.0
		while lx > leaf_end.x:
			b.line(Vector2(lx, leaf_end.y - 1.5), Vector2(lx, leaf_end.y + 1.5), PIER_STEEL_DARK, 1.0)
			lx -= 4.0
	# foam where the swell meets the pier's curbs out on the water
	var t := AnimClock.msec() / 1000.0
	var fx := LevelBuild.BEACH_PIER_SAND_END - 12.0
	while fx > far:
		var f := 0.5 + 0.5 * sin(t * 1.4 + fx * 0.07)
		for side: float in [-1.0, 1.0]:
			var fy := y + side * (h + 7.0 + 2.0 * f)
			b.line(Vector2(fx, fy), Vector2(fx - 10.0, fy), Color(0.95, 0.98, 0.98, 0.35 + 0.3 * f), 1.5)
		fx -= 18.0
	b.flush(m._wc)


# THE MONKEY (Susana Ruiz's bronze for the old anís works, 2012): a monkey with
# Darwin's face, a heavy brow and a long beard, sat on a pale stone block with
# his feet on the planks and his tail hanging over the edge, holding out a
# bottle with the diamond-cut glass. Bronze, gone green on his back and arms.
# Drawn from above facing `rot`, life size, on his block.
const BRONZE := Color(0.27, 0.19, 0.12)
const BRONZE_MID := Color(0.42, 0.29, 0.17)
const BRONZE_LIT := Color(0.66, 0.48, 0.28)
const PATINA := Color(0.30, 0.40, 0.34)
const BLOCK_STONE := Color(0.66, 0.70, 0.74)            # blue-grey veined marble
const BLOCK_SIDE := Color(0.46, 0.50, 0.55)
const BLOCK_VEIN := Color(0.84, 0.87, 0.90, 0.7)


static func _ellipse(b: ShapeBatch, c: Vector2, rx: float, ry: float, rot: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(14):
		var a := TAU * float(i) / 14.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry).rotated(rot))
	b.polygon(pts, col)


static func _quad(b: ShapeBatch, c: Vector2, along: Vector2, half_l: float, half_w: float, col: Color) -> void:
	var across := Vector2(-along.y, along.x)
	b.polygon(PackedVector2Array([c - along * half_l - across * half_w, c + along * half_l - across * half_w,
		c + along * half_l + across * half_w, c - along * half_l + across * half_w]), col)


static func _monkey(m: Node2D, c: Vector2, rot: float) -> void:
	const K := 1.6
	var b := ShapeBatch.new()
	var sh := Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.3)
	var fwd := Vector2.from_angle(rot)
	var along := Vector2(-fwd.y, fwd.x)
	var bl := LevelBuild.BEACH_BLOCK_LEN * 0.5
	var bw := LevelBuild.BEACH_BLOCK_W * 0.5
	# the block, a long dressed stone, its side showing toward the light's far side
	_quad(b, c + m.LIGHT * 4.0, along, bl, bw, sh)
	_quad(b, c + fwd * 1.5, along, bl, bw + 1.5, BLOCK_SIDE)
	_quad(b, c, along, bl, bw, BLOCK_STONE)
	_quad(b, c - m.LIGHT * 1.0, along, bl - 3.0, bw - 3.0, BLOCK_STONE.lightened(0.06))
	# a little brass plaque on its face
	b.rect(Rect2(c + along * 14.0 + fwd * (bw - 1.0) - Vector2(2.5, 1.5), Vector2(5.0, 3.0)), Color(0.74, 0.64, 0.36))
	var P := func(v: Vector2) -> Vector2: return c + v.rotated(rot) * K
	# veins in the marble, along the block
	for k in range(3):
		var off := (float(k) - 1.0) * bw * 0.5 + (_hash(float(k), 23.0) - 0.5) * 2.0
		var a0 := c - along * (bl - 4.0) + fwd * off
		var a1 := c + along * (bl - 4.0) + fwd * (off + (_hash(float(k), 29.0) - 0.5) * 4.0)
		b.line(a0, a0.lerp(a1, 0.45) + fwd * 1.2, BLOCK_VEIN, 0.8)
		b.line(a0.lerp(a1, 0.45) + fwd * 1.2, a1, BLOCK_VEIN, 0.8)
	# his shadow, over the block's face and onto the planks
	_ellipse(b, P.call(Vector2(2.0, 0.0)) + m.LIGHT * 6.0, 8.0 * K, 7.5 * K, rot, sh)
	# the hanging leg: down off the block's front, the foot flat on the planks
	b.line(P.call(Vector2(1.0, 3.6)), P.call(Vector2(5.0, 4.0)), BRONZE, 3.2 * K)
	b.line(P.call(Vector2(5.0, 4.0)), P.call(Vector2(7.5, 4.4)), BRONZE, 2.6 * K)
	_ellipse(b, P.call(Vector2(8.8, 4.6)), 2.2 * K, 1.6 * K, rot + 0.25, BRONZE_MID)
	for t in range(3):
		b.circle(P.call(Vector2(10.6, 3.8 + float(t) * 0.9)), 0.5 * K, BRONZE_MID)
	# the other leg drawn up, knee high, foot on the block
	_ellipse(b, P.call(Vector2(3.5, -5.5)), 2.6 * K, 1.8 * K, rot, BRONZE)
	b.line(P.call(Vector2(0.5, -3.5)), P.call(Vector2(5.5, -4.5)), BRONZE, 3.4 * K)
	b.circle(P.call(Vector2(5.8, -4.6)), 2.6 * K, BRONZE_MID)
	# the body, sat upright: haunches, back, the green come out on it
	_ellipse(b, P.call(Vector2(-1.5, 0.0)), 6.8 * K, 7.0 * K, rot, BRONZE)
	_ellipse(b, P.call(Vector2(-2.5, 0.0)), 4.6 * K, 5.2 * K, rot, BRONZE.lerp(PATINA, 0.55))
	# his tail, round over the hanging leg's thigh
	var prev: Vector2 = P.call(Vector2(-5.5, 4.5))
	for i in range(1, 16):
		var t := float(i) / 15.0
		var a := PI * 1.1 - t * PI * 1.9
		var r := lerpf(5.0, 2.0, t)
		var nxt: Vector2 = P.call(Vector2(1.5, 4.5) + Vector2(cos(a), sin(a)) * r)
		b.line(prev, nxt, BRONZE_MID, (1.7 - t * 0.7) * K)
		prev = nxt
	# the near arm down to the raised knee, the hand over it
	b.line(P.call(Vector2(0.0, -5.0)), P.call(Vector2(5.0, -6.0)), BRONZE_MID, 2.3 * K)
	_ellipse(b, P.call(Vector2(6.4, -5.6)), 1.9 * K, 1.5 * K, rot, BRONZE_LIT.lerp(BRONZE_MID, 0.4))
	# the far arm up at his side, holding the bottle up to look at: upright,
	# so from above its shoulder and stopper, the diamond cut round it
	b.line(P.call(Vector2(0.0, 5.0)), P.call(Vector2(3.0, 8.5)), BRONZE_MID, 2.3 * K)
	var bt: Vector2 = P.call(Vector2(5.0, 9.0))
	b.circle(bt + m.LIGHT * 4.0, 3.4 * K, sh)
	b.circle(bt, 3.2 * K, BRONZE_MID)
	for k in range(6):
		var a := TAU * float(k) / 6.0 + 0.3
		b.line(bt + Vector2(cos(a), sin(a)) * 1.6 * K, bt + Vector2(cos(a + 0.9), sin(a + 0.9)) * 3.1 * K, BRONZE, 0.7)
	b.circle(bt - m.LIGHT * 1.5, 1.7 * K, BRONZE_LIT)
	b.circle(bt, 1.0 * K, BRONZE)
	_ellipse(b, P.call(Vector2(3.6, 8.2)), 1.8 * K, 2.2 * K, rot, BRONZE)
	# shoulders, lit from the light's side
	_ellipse(b, P.call(Vector2(-0.5, 0.0)) - m.LIGHT * 2.0, 4.0 * K, 5.2 * K, rot, BRONZE_MID.lerp(BRONZE_LIT, 0.35))
	# the head: ears out either side, the crown going bald, Darwin's long
	# beard down his chest, his muzzle, and deep-set eyes under a heavy brow,
	# looking at the bottle
	var hrot := rot + 0.35
	var H := func(v: Vector2) -> Vector2: return c + Vector2(1.5, 0.0).rotated(rot) * K + v.rotated(hrot) * K
	_ellipse(b, H.call(Vector2(3.4, 0.0)), 3.6 * K, 3.0 * K, hrot, BRONZE.lerp(PATINA, 0.3))
	for side: float in [-1.0, 1.0]:
		b.circle(H.call(Vector2(-0.5, 4.6 * side)), 2.0 * K, BRONZE)
		b.circle(H.call(Vector2(-0.3, 4.6 * side)), 1.0 * K, BRONZE_MID)
	b.circle(H.call(Vector2(0.0, 0.0)), 4.4 * K, BRONZE_MID)
	b.circle(H.call(Vector2(-0.4, -0.2)) - m.LIGHT * 1.6, 2.6 * K, BRONZE_LIT)
	_ellipse(b, H.call(Vector2(3.6, 0.0)), 1.8 * K, 2.4 * K, hrot, BRONZE_MID.lerp(BRONZE_LIT, 0.5))
	b.line(H.call(Vector2(2.4, -2.6)), H.call(Vector2(2.4, 2.6)), BRONZE_LIT.lightened(0.1), 1.3 * K)
	for side: float in [-1.0, 1.0]:
		b.circle(H.call(Vector2(3.1, 1.5 * side)), 0.75 * K, Color(0.10, 0.06, 0.03))
	b.circle(H.call(Vector2(5.0, 0.0)), 0.55 * K, Color(0.14, 0.09, 0.05))
	b.flush(m._wc)


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
	# where the dog beach's own ground stops: the land starts there, so its
	# edge meets the beach's rather than lying 10 px over it. The sea starts at
	# ctop, under the espigo, and so do the blocks, past the beach's side
	var ftop: float = m.GATE_Y - 30.0
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
	wc.draw_rect(Rect2(230, ftop, 150, bottom - ftop), m.BEACH_SAND)
	# the wet sand at the waterline and the foam on it: the dog beach's
	# shore has both, so here they carry its shore on down the walk
	wc.draw_rect(Rect2(m.BEACH_GATE_SHORE_X, ftop, m.BEACH_WET_W, bottom - ftop), m.BEACH_WET)
	var foam := ShapeBatch.new()
	var fmy := maxf(ftop, vt - fmod(vt, 52.0) - 52.0)
	while fmy < minf(bottom, vb + 52.0):
		var fmx: float = m.BEACH_GATE_SHORE_X + 4.0 + sin(fmy * 0.02 + wt * 1.4) * 4.0
		var fml := 30.0 + 14.0 * (0.5 + 0.5 * sin(fmy * 0.037))
		foam.line(Vector2(fmx, fmy), Vector2(fmx - 2.0, fmy + fml), Color(1, 1, 1, 0.26), 3.0)
		fmy += 52.0
	# tide drift line: cockle shells (petxines), sea pebbles (codols), posidonia along waterline
	var tdy := maxf(ftop, vt - fmod(vt, 32.0) - 32.0)
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
	# the espigo's rocks again, over the walk's own sea: this ground starts
	# under the dog beach's (ctop) so no gap shows, and without them the sea's
	# straight top edge cut across the breakwater
	m._draw_espigo(wc)
	# THE TIMBER DECK, nearest the sand. Planks laid across the walk with
	# alternating tones, fastener bolt pairs, and access ramps out to the sand.
	# It stops where the dog beach's sand starts, on an end board, rather than
	# running a plain stub of timber under the beach's palm.
	var deck_top := ftop
	wc.draw_rect(Rect2(380, deck_top, 110, bottom - deck_top), Color(0.46, 0.26, 0.21))
	var bdeck := ShapeBatch.new()
	var py := minf(m.START_Y + 200.0, vb + 22.0 - fmod(vb, 22.0))
	while py - 20.0 >= deck_top and py > vt - 22.0:
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
	if deck_top > vt - 10.0 and deck_top < vb:
		bdeck.rect(Rect2(380.0, deck_top, 110.0, 5.0), Color(0.32, 0.18, 0.14))
		bdeck.line(Vector2(380.0, deck_top + 5.5), Vector2(490.0, deck_top + 5.5), Color(0.58, 0.38, 0.30), 1.0)
	bdeck.flush(wc)
	# the pale concrete path, with the dashed line down the middle of it
	wc.draw_rect(Rect2(490, ftop, 80, bottom - ftop), Color(0.82, 0.79, 0.73))
	var ddy := minf(m.START_Y + 200.0, vb + 64.0 - fmod(vb, 64.0))
	while ddy > m.GATE_Y and ddy > vt - 64.0:
		if ddy < vb and ddy > vt:
			wc.draw_line(Vector2(530, ddy), Vector2(530, ddy - 26.0), Color(0.97, 0.96, 0.93, 0.8), 3.0)
		ddy -= 64.0
	wc.draw_rect(Rect2(570, ftop, 410, bottom - ftop), Color(0.79, 0.76, 0.7))
	var sy := minf(m.START_Y + 200.0, vb + 150.0 - fmod(vb, 150.0))
	while sy > m.GATE_Y and sy > vt - 150.0:
		if sy < vb and sy > vt:
			wc.draw_line(Vector2(560, sy), Vector2(980, sy), Color(0.71, 0.68, 0.62), 2.0)
		sy -= 150.0
	wc.draw_rect(Rect2(980, ftop, 210, bottom - ftop), Color(0.76, 0.72, 0.65))
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
	wc.draw_line(Vector2(380, bottom), Vector2(380, ftop), Color(0.55, 0.45, 0.32), 3.0)
	wc.draw_line(Vector2(490, bottom), Vector2(490, ftop), m.COL_SEAM, 2.0)
	wc.draw_line(Vector2(570, bottom), Vector2(570, ftop), m.COL_SEAM, 2.0)
	wc.draw_line(Vector2(980, bottom), Vector2(980, ftop), m.COL_SEAM, 2.0)
	_sand_creep(m, wc, vt, vb)
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


static func surface(m: Node2D, p: Vector2) -> int:
	if LevelBuild.beach_on_pier(p):
		return Surfaces.S.PAVEMENT
	if p.x < SAND_TO_X:
		return Surfaces.S.SAND
	# past the gate the dog beach is sand from the fence to the water, where
	# the deck and promenade stop (the sea is ruled out before this hook)
	if p.y < m.GATE_Y - 30.0:
		return Surfaces.S.SAND
	return Surfaces.S.PAVEMENT


# the sand takes prints; past the gate is the dog beach, sand from the fence
# to the water
static func takes_prints(m: Node2D, p: Vector2) -> bool:
	if LevelBuild.beach_on_pier(p):
		return false
	var s: int = m.surface_at(p)
	if p.y < m.GATE_Y:
		return s != Surfaces.S.WATER
	return s == Surfaces.S.SAND


# the seafront's bins are recycling stations
static func draw_bin(m: Node2D, c: Object, bn: Vector2) -> void:
	_recycling_station(m, c, bn)
