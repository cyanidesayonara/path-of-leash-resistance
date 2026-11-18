class_name Diluvi
extends RefCounted

# WALK: EL DILUVI (the downpour). Its drawing as static functions over main's
# state (main.WALK_MODULES): the gutters and drains down the street, the
# cafe's terrace stacked and chained in the rain, the arcade's square
# pillars, and El Porxo past the gate - the porch, its pantile roofs and the
# terrats beyond. The wet meter itself (main._tick_wet) and the shelters
# stay in main: they are the walk's rules, not its picture.

# the hooks main calls on this walk, held to it by tests/test_walk_hooks.gd
const HOOKS := [
	"draw_column",
	"draw_edge_layer",
	"draw_freedom_beyond",
	"draw_freedom_ground",
	"draw_live",
	"draw_over_walkway",
	"draw_threshold",
	"night_fronts",
	"surface",
]


const ShapeBatch := preload("res://systems/shape_batch.gd")
const LevelBuild := preload("res://world/level_build.gd")
const NightFronts := preload("res://world/night_fronts.gd")
const Panot := preload("res://world/panot.gd")
const Surfaces := preload("res://world/surfaces.gd")
const RING_SEGS := 12
const PORXO_PUDDLE_SEGS := 28
const PILLAR_STONE := Color(0.58, 0.53, 0.47)

# street geometry constants matching main.gd and LevelBuild
const EDGE_MOD := 220.0
const EDGE_DEPTH := 78.0
const EDGE_INSET := 27.0
const DOOR_OFFSET := 168.0
const GUTTER_W := 10.0
const KERB_W := 4.0
const ARCADE_GUTTER_X := 98.0
const KERB_STONE := Color(0.56, 0.54, 0.50)
const GUTTER_BED := Color(0.24, 0.28, 0.34)
const DRY_ARCADE_STONE := Color(0.68, 0.62, 0.52)
const PORXO_KERB_W := 10.0
const PORXO_KERB_COL := Color(0.65, 0.61, 0.54)


static func _in_crossing(m: Node2D, y: float, pad := 0.0) -> bool:
	for ly: float in m.lane_ys:
		if absf(y - ly) < float(m.LANE_HALF) + pad:
			return true
	return false


static func _doorway_ys(m: Node2D, y_min: float, y_max: float) -> Array[float]:
	var out: Array[float] = []
	var y := floorf(y_min / EDGE_MOD) * EDGE_MOD
	while y < y_max:
		var dy := y + DOOR_OFFSET
		if dy > y_min + 26.0 and dy < y_max - 26.0 and not _in_crossing(m, dy, 28.0):
			out.append(dy)
		y += EDGE_MOD
	return out


static func _near_doorway(dy_list: Array[float], y: float, half_h := 16.0) -> bool:
	for dy: float in dy_list:
		if absf(y - dy) < half_h:
			return true
	return false


static func _in_arcade_y(y: float) -> bool:
	return y >= LevelBuild.DILUVI_ARCADE_Y0 and y <= LevelBuild.DILUVI_ARCADE_Y1


# Where the gutter center runs on each side: outside the arcade on the west
# side, it steps out to the arcade's drip channel along [ARCADE_Y0, ARCADE_Y1].
static func _gutter_x(ge: Vector2, gy: float, west: bool) -> float:
	if not west:
		return ge.y - GUTTER_W * 0.5
	if _in_arcade_y(gy):
		return ge.x + ARCADE_GUTTER_X - GUTTER_W * 0.5
	return ge.x + GUTTER_W * 0.5


# EL DILUVI: the arcade (a roof behind its pillars, arches between), the
# awnings, the gutters running down both sides, and the owner's wet meter.
static func _draw_street(m: Node2D, vt: float, vb: float) -> void:
	var b := ShapeBatch.new()
	var t := AnimClock.msec() / 1000.0
	var y_top_lim: float = float(m.GATE_Y) + 14.0
	var y_bot_lim: float = float(m.START_Y) + 52.0
	var door_ys := _doorway_ys(m, float(m.GATE_Y) - 20.0, float(m.START_Y) + 74.0)
	# the gutters: running water and storm drain grates (static stone beds &
	# kerbs are cached on ground_layer in draw_over_walkway)
	var gy := floorf(maxf(vt - 60.0, y_top_lim) / 46.0) * 46.0
	var gy_end := minf(vb + 60.0, y_bot_lim)
	while gy < gy_end:
		var seg_a := maxf(gy, y_top_lim)
		var seg_b := minf(gy + 46.0, y_bot_lim)
		var mid := (seg_a + seg_b) * 0.5
		if seg_b > seg_a + 2.0 and not _in_crossing(m, mid, 4.0):
			var ge: Vector2 = m.walk_edges(mid)
			for west: bool in [true, false]:
				var gx := _gutter_x(ge, mid, west)
				var on_arcade := west and _in_arcade_y(mid)
				if on_arcade or not _near_doorway(door_ys, mid, 15.0):
					b.rect(Rect2(gx - 3.5, seg_a, 7.0, seg_b - seg_a), Color(0.30, 0.36, 0.42, 0.85))
					var fl := fmod(gy + t * 90.0, 46.0)
					var fy0 := clampf(gy + fl, seg_a, seg_b - 2.0)
					var fy1 := clampf(gy + fl + 12.0, seg_a, seg_b)
					if fy1 > fy0 + 2.0:
						b.line(Vector2(gx, fy0), Vector2(gx, fy1), Color(0.75, 0.84, 0.92, 0.6), 2.0)
				if int(absf(gy)) % 184 < 46 and (on_arcade or not _near_doorway(door_ys, gy + 23.0, 18.0)):
					if gy + 10.0 >= y_top_lim and gy + 36.0 <= y_bot_lim and not _in_crossing(m, gy + 23.0, 16.0):
						_draw_grate(b, gx, gy + 23.0, t, gy)
		gy += 46.0

	# terminal catch-basin grates where gutters meet crossings, the gate, the
	# arcade ends, and the start facade so water drains cleanly rather than ending mid-stream
	var catch_ys: Array[float] = [y_top_lim + 12.0, y_bot_lim - 12.0,
		LevelBuild.DILUVI_ARCADE_Y1 + 14.0, LevelBuild.DILUVI_ARCADE_Y0 - 14.0]
	for ly: float in m.lane_ys:
		catch_ys.append(ly - float(m.LANE_HALF) - 14.0)
		catch_ys.append(ly + float(m.LANE_HALF) + 14.0)
	for cy: float in catch_ys:
		if cy < vt - 40.0 or cy > vb + 40.0:
			continue
		var ce: Vector2 = m.walk_edges(cy)
		for west: bool in [true, false]:
			_draw_grate(b, _gutter_x(ce, cy, west), cy, t, cy)

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
			_ring(b, pc + roff, 3.0 + rph * 14.0, 1.4, Color(0.85, 0.92, 0.98, 0.45 * (1.0 - rph)))
			if rph < 0.25:
				b.circle(pc + roff, 1.5, Color(1.0, 1.0, 1.0, 0.55 * (1.0 - rph * 4.0)))
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
			b.rect(Rect2(ar.position.x, y0, ar.size.x, y1 - y0), Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.20))
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
	if m.awning_dump != null:
		m.awning_dump.draw(b, vt, vb)
	b.flush(m._wc)


static func _draw_grate(b: ShapeBatch, gx: float, cy: float, t: float, phase_seed: float) -> void:
	b.rect(Rect2(gx - 4.5, cy - 11.0, 9.0, 22.0), Color(0.18, 0.20, 0.22))
	for gi: int in range(4):
		var ly := cy - 7.5 + float(gi) * 5.0
		b.line(Vector2(gx - 3.0, ly), Vector2(gx + 3.0, ly), Color(0.10, 0.10, 0.12), 2.0)
	var wph := fmod(t * 2.2 + absf(phase_seed) * 0.1, 1.0)
	b.circle(Vector2(gx, cy), 2.0 + wph * 4.0, Color(0.72, 0.84, 0.94, 0.35 * (1.0 - wph)))


# a ripple's ring on standing water: RING_SEGS quads round the centre, so a
# drop's ring is a ring and not a growing disc
static func _ring(b: ShapeBatch, c: Vector2, r: float, w: float, col: Color) -> void:
	var prev_o := c + Vector2(r + w * 0.5, 0.0)
	var prev_i := c + Vector2(maxf(r - w * 0.5, 0.0), 0.0)
	for k in range(1, RING_SEGS + 1):
		var d := Vector2.from_angle(TAU * float(k) / float(RING_SEGS))
		var o := c + d * (r + w * 0.5)
		var i := c + d * maxf(r - w * 0.5, 0.0)
		b.quad(prev_o, o, i, prev_i, col)
		prev_o = o
		prev_i = i


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
	b.rect(Rect2(r.position + Shade.light * 7.0, r.size), Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.26))
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
	# the court's low middle, where it stays wettest: darker toward its heart
	b.glow(r.get_center() + Vector2(30.0, 40.0), 230.0, Color(0.40, 0.36, 0.30, 0.42), 0.25)
	for pd: Array in [[Vector2(0.30, 0.55), 46.0, 24.0], [Vector2(0.58, 0.60), 60.0, 30.0], [Vector2(0.48, 0.80), 38.0, 20.0], [Vector2(0.78, 0.70), 50.0, 26.0]]:
		var pc: Vector2 = r.position + r.size * (pd[0] as Vector2)
		var rx: float = pd[1]
		var ry: float = pd[2]
		b.polygon(m.ellipse_pts(pc, rx + 5.0, ry + 4.0, PORXO_PUDDLE_SEGS), court.darkened(0.22))
		b.polygon(m.ellipse_pts(pc, rx, ry, PORXO_PUDDLE_SEGS), Color(0.42, 0.50, 0.58, 0.85))
		b.polygon(m.ellipse_pts(pc + Vector2(-rx * 0.3, -ry * 0.3), rx * 0.35, ry * 0.25, 16), Color(0.80, 0.86, 0.94, 0.22))
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
	b.rect(Rect2(r.position.x, r.end.y - 10.0, m.PORXO_W, 10.0), Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.14))
	b.rect(Rect2(r.end.x - m.PORXO_W, r.end.y - 10.0, m.PORXO_W, 10.0), Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.14))
	# soft wet eave drip feathering into the sauló court, bordered by a dressed
	# stone porch kerb along the column line
	var ix0: float = r.position.x + m.PORXO_W
	var ix1: float = r.end.x - m.PORXO_W
	var iy0: float = r.position.y + m.PORXO_W
	var drip_col := Color(0.36, 0.30, 0.22, 0.44)
	var drip_rows := PackedFloat32Array([1.0, 0.45, 0.0])
	var end_cols := PackedFloat32Array([1.0, 1.0])
	b.band(PackedVector2Array([
		Vector2(ix0, iy0), Vector2(ix1, iy0),
		Vector2(ix0, iy0 + 8.0), Vector2(ix1, iy0 + 8.0),
		Vector2(ix0, iy0 + 20.0), Vector2(ix1, iy0 + 20.0),
	]), 2, drip_col, drip_rows, end_cols)
	b.band(PackedVector2Array([
		Vector2(ix0, iy0), Vector2(ix0, r.end.y),
		Vector2(ix0 + 8.0, iy0), Vector2(ix0 + 8.0, r.end.y),
		Vector2(ix0 + 20.0, iy0), Vector2(ix0 + 20.0, r.end.y),
	]), 2, drip_col, drip_rows, end_cols)
	b.band(PackedVector2Array([
		Vector2(ix1, iy0), Vector2(ix1, r.end.y),
		Vector2(ix1 - 8.0, iy0), Vector2(ix1 - 8.0, r.end.y),
		Vector2(ix1 - 20.0, iy0), Vector2(ix1 - 20.0, r.end.y),
	]), 2, drip_col, drip_rows, end_cols)
	_porxo_kerbs(b, ix0, ix1, iy0, r.end.y)
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
		b.circle(cp + Shade.light * 9.0, 12.0, Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.30))
		b.rect(Rect2(cp - Vector2(13, 13), Vector2(26, 26)), Color(0.64, 0.60, 0.54))
		b.circle(cp, 10.0, Color(0.76, 0.72, 0.66))
		b.circle(cp - Shade.light * 2.5, 6.5, Color(0.84, 0.81, 0.76))
	# the walls round the yard, open at the gate, with a lit top stone coping
	var wall := Color(0.60, 0.54, 0.46)
	var coping := wall.lightened(0.18)
	b.rect(Rect2(r.position.x - 10.0, r.position.y - 10.0, r.size.x + 20.0, 10.0), wall)
	b.rect(Rect2(r.position.x - 10.0, r.position.y, 10.0, r.size.y + 10.0), wall)
	b.rect(Rect2(r.end.x, r.position.y, 10.0, r.size.y + 10.0), wall)
	b.rect(Rect2(r.position.x - 10.0, r.end.y, m.gate_l - 20.0 - r.position.x + 10.0, 10.0), wall)
	b.rect(Rect2(m.gate_r + 20.0, r.end.y, r.end.x + 10.0 - m.gate_r - 20.0, 10.0), wall)
	b.rect(Rect2(r.position.x - 10.0, r.position.y - 10.0, r.size.x + 20.0, 3.0), coping)
	b.rect(Rect2(r.position.x - 10.0, r.position.y - 10.0, 3.0, r.size.y + 20.0), coping)
	b.rect(Rect2(r.end.x, r.position.y - 10.0, 3.0, r.size.y + 20.0), coping)
	b.rect(Rect2(r.position.x - 10.0, r.end.y, m.gate_l - 20.0 - r.position.x + 10.0, 3.0), coping)
	b.rect(Rect2(m.gate_r + 20.0, r.end.y, r.end.x + 10.0 - m.gate_r - 20.0, 3.0), coping)
	# a downpipe in each corner of the court, spouting onto a splash stone
	for dp: Vector2 in [Vector2(ix0 + 18.0, iy0 + 16.0), Vector2(ix1 - 18.0, iy0 + 16.0)]:
		b.rect(Rect2(dp - Vector2(10, 7), Vector2(20, 14)), Color(0.66, 0.62, 0.56))
		b.circle(dp, 4.0, Color(0.48, 0.52, 0.56))
		b.circle(dp + Vector2(0, 8), 7.0, Color(0.50, 0.60, 0.70, 0.6))
	if b != c:
		b.flush()
	m._draw_freedom_benches(c, r, Color(0.46, 0.34, 0.24))
	m._freedom_sign(c, r, m.gate_text, I18n.t("w_the_covered_yard_off_leash"))


static func _porxo_kerbs(b: ShapeBatch, ix0: float, ix1: float, iy0: float, y_bot: float) -> void:
	var hk := PORXO_KERB_W * 0.5
	b.rect(Rect2(ix0 - hk, iy0 - hk, ix1 - ix0 + PORXO_KERB_W, PORXO_KERB_W), PORXO_KERB_COL)
	b.rect(Rect2(ix0 - hk, iy0 - hk, ix1 - ix0 + PORXO_KERB_W, 2.0), PORXO_KERB_COL.lightened(0.14))
	b.rect(Rect2(ix0 - hk, iy0 - hk, PORXO_KERB_W, y_bot - iy0 + hk), PORXO_KERB_COL)
	b.rect(Rect2(ix0 - hk, iy0 - hk, 2.0, y_bot - iy0 + hk), PORXO_KERB_COL.lightened(0.14))
	b.rect(Rect2(ix1 - hk, iy0 - hk, PORXO_KERB_W, y_bot - iy0 + hk), PORXO_KERB_COL)
	b.rect(Rect2(ix1 - hk, iy0 - hk, 2.0, y_bot - iy0 + hk), PORXO_KERB_COL.lightened(0.14))
	var joint := PORXO_KERB_COL.darkened(0.22)
	var jx := ix0 + 37.0
	while jx < ix1 - 12.0:
		b.line(Vector2(jx, iy0 - hk), Vector2(jx, iy0 + hk), joint, 1.2)
		jx += 37.0
	var jy := iy0 + 37.0
	while jy < y_bot - 12.0:
		b.line(Vector2(ix0 - hk, jy), Vector2(ix0 + hk, jy), joint, 1.2)
		b.line(Vector2(ix1 - hk, jy), Vector2(ix1 + hk, jy), joint, 1.2)
		jy += 37.0


# --- main's walk hooks (main.WALK_MODULES) ---------------------------------------

# the street, up to the gate
static func draw_live(m: Node2D, _wc: ShapeBatch, vt: float, vb: float) -> void:
	_draw_street(m, maxf(vt, m.GATE_Y - 30.0), vb)


# El Porxo is paved and packed from wall to wall: past the gate it handles as
# paving, bar the soft ground round its trees' trunks and its dig spots.
static func surface(m: Node2D, p: Vector2) -> int:
	return Surfaces.paved_past_gate(m, p, m.trees)


# El Porxo, past the gate
static func draw_freedom_ground(m: Node2D, c: Object) -> void:
	_draw_porxo(m, c)


# El Porxo's porch roofs past its walls, wet pantile, and the block's
# terrats beyond, meeting the street's north building blocks cleanly at the
# south wall without overlapping past it.
static func draw_freedom_beyond(m: Node2D, c: Object) -> void:
	var r: Rect2 = m._freedom_rect()
	var top := r.position.y
	var wall_bot := r.end.y + 10.0
	var b := ShapeBatch.new()
	b.rect(Rect2(-400.0, top - 400.0, 2100.0, 390.0), Color(0.38, 0.35, 0.37))
	var tile := Color(0.50, 0.29, 0.21)
	# north wing (-400..1700, top-110..top-10)
	var n_bay := Rect2(-400.0, top - 110.0, 2100.0, 100.0)
	b.rect(n_bay, tile)
	var ty := n_bay.position.y + 4.0
	while ty < n_bay.end.y:
		b.line(Vector2(n_bay.position.x, ty), Vector2(n_bay.end.x, ty), tile.darkened(0.28), 2.0)
		ty += 9.0
	# west and east porch wings ending flush with El Porxo's south stone wall
	var w_bay := Rect2(-400.0, top - 10.0, r.position.x - 10.0 + 400.0, wall_bot - (top - 10.0))
	var e_bay := Rect2(r.end.x + 10.0, top - 10.0, 1700.0 - (r.end.x + 10.0), wall_bot - (top - 10.0))
	for bay: Rect2 in [w_bay, e_bay]:
		b.rect(bay, tile)
		var tx := bay.position.x + 4.0
		while tx < bay.end.x:
			b.line(Vector2(tx, bay.position.y), Vector2(tx, bay.end.y), tile.darkened(0.28), 2.0)
			tx += 9.0
		# south parapet coping joining El Porxo's south stone wall
		b.rect(Rect2(bay.position.x, wall_bot - 6.0, bay.size.x, 6.0), Color(0.60, 0.54, 0.46))
		b.rect(Rect2(bay.position.x, wall_bot - 6.0, bay.size.x, 2.0), Color(0.70, 0.64, 0.55))
	# mitered hip ridges where the north and side porch roofs meet at the corners
	for side_x: Array in [[r.position.x - 10.0, -1.0], [r.end.x + 10.0, 1.0]]:
		var cx := float(side_x[0])
		var sx := float(side_x[1])
		var hip_a := Vector2(cx, top - 10.0)
		var hip_b := Vector2(cx + sx * 100.0, top - 110.0)
		b.polygon(PackedVector2Array([hip_a, hip_b, Vector2(cx + sx * 100.0, top - 10.0)]), tile.darkened(0.05))
		var hty := top - 105.0
		while hty < top - 10.0:
			var frac := (hty - (top - 10.0)) / -100.0
			var hx := cx + sx * frac * 100.0
			var x_lo := minf(cx, hx)
			var x_hi := maxf(cx, hx)
			if x_hi - x_lo > 4.0:
				b.line(Vector2(x_lo, hty), Vector2(x_hi, hty), tile.darkened(0.28), 2.0)
			hty += 9.0
		b.line(hip_a, hip_b, tile.darkened(0.26), 7.0)
		b.line(hip_a, hip_b, tile.lightened(0.16), 3.5)
	for k in range(9):
		var tp := Vector2(-300.0 + float(k) * 240.0, top - 260.0 + fmod(float(k) * 53.0, 80.0))
		b.circle(tp + Shade.light * 10.0, 16.0, Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.3))
		b.circle(tp, 15.0, Color(0.80, 0.80, 0.78))
		b.circle(tp, 6.0, Color(0.56, 0.58, 0.60))
	b.flush(c)


# the arcade's pillars down the west side; lampposts down the east
static func draw_column(m: Node2D, wc: ShapeBatch, p: Vector2) -> void:
	if p.x >= m.walk_cx:
		m._draw_lamppost(p)
		return
	# flush stone paving collar seating the plinth into the panots
	wc.rect(Rect2(p.x - 16.0, p.y - 16.0, 32.0, 32.0), Color(0.46, 0.44, 0.41))
	m.cast_shadow(wc, p, 12.0, 30.0, 0.2)
	# the plinth, then the shaft: lit on the west face and shaded on the east,
	# as the light falls, with a dressed edge along the top
	wc.rect(Rect2(p.x - 14.0, p.y - 14.0, 28.0, 28.0), PILLAR_STONE.darkened(0.30))
	wc.rect(Rect2(p.x - 13.0, p.y - 13.0, 26.0, 26.0), PILLAR_STONE.darkened(0.12))
	wc.rect(Rect2(p.x - 10.0, p.y - 10.0, 20.0, 20.0), PILLAR_STONE)
	wc.rect(Rect2(p.x - 10.0, p.y - 10.0, 7.0, 20.0), PILLAR_STONE.lightened(0.12))
	wc.rect(Rect2(p.x + 3.0, p.y - 10.0, 7.0, 20.0), PILLAR_STONE.darkened(0.18))
	wc.rect(Rect2(p.x - 10.0, p.y - 10.0, 20.0, 2.0), PILLAR_STONE.lightened(0.22))


# Custom building edge layer for El Diluvi: omits the generic _draw_edge_awning
# (which collided with the west arcade and east DILUVI_AWNINGS), stops cleanly
# at El Porxo's south wall (-5020) and the start apartment block (+334), and
# frames the two cross-streets cleanly.
static func draw_edge_layer(m: Node2D, c: Object, vt: float, vb: float) -> void:
	var b: ShapeBatch = c if c is ShapeBatch else ShapeBatch.new(c)
	var y_min: float = float(m.GATE_Y) - 20.0
	var y_max: float = float(m.START_Y) + 74.0
	var base: Color = m._edge_base_color()
	var face := 22.0
	var cast := 38.0
	var slice := 55.0
	var sy := maxf(floorf((vt - 320.0) / slice) * slice, y_min)
	var sy_end := minf(vb + 320.0, y_max)
	while sy < sy_end - 0.5:
		var sn := minf(sy + slice, sy_end)
		for seg: Vector2 in _subtract_crossings(m, sy, sn):
			m._edge_band(b, seg.x, seg.y - seg.x, base, 520.0, face, cast)
		sy = sn

	var door_ys := _doorway_ys(m, y_min, y_max)
	var my := maxf(floorf((vt - EDGE_MOD) / EDGE_MOD) * EDGE_MOD, floorf(y_min / EDGE_MOD) * EDGE_MOD)
	var my_end := minf(vb + EDGE_MOD, y_max)
	while my < my_end:
		var m_top := maxf(my, y_min)
		var m_bot := minf(my + EDGE_MOD, y_max)
		if m_bot > m_top + 1.0:
			var k_base := int(absf(my) / EDGE_MOD)
			var spans := _subtract_crossings(m, m_top, m_bot)
			for side: float in [-1.0, 1.0]:
				var line: Vector2 = m.frontage(clampf((m_top + m_bot) * 0.5, y_min + 1.0, y_max - 1.0))
				var inner: float = (line.x - EDGE_INSET) if side < 0.0 else (line.y + EDGE_INSET)
				var x0: float = inner - EDGE_DEPTH if side < 0.0 else inner
				var k := k_base + (0 if side < 0.0 else 7)
				for seg: Vector2 in spans:
					var sh := seg.y - seg.x
					if sh >= 165.0:
						m._draw_diluvi_roofs(b, Rect2(x0, seg.x, EDGE_DEPTH, sh), side, k, inner)
					elif sh >= 8.0:
						_draw_corner_roof(m, b, inner, side, seg.x, sh, k)
				var dy := my + DOOR_OFFSET
				if dy in door_ys:
					m._draw_doorway(b, inner, side, dy, Color(0.48, 0.30, 0.22))
		my += EDGE_MOD

	# stone coping along cross-street corners and at El Porxo's south boundary
	var coping := Color(0.60, 0.54, 0.46)
	for ly: float in m.lane_ys:
		var ct := ly - float(m.LANE_HALF)
		var cb := ly + float(m.LANE_HALF)
		for side: float in [-1.0, 1.0]:
			var ce: Vector2 = m.frontage(ly)
			var x_lo := ce.x - 447.0 if side < 0.0 else ce.y
			if ct > vt - 60.0 and ct < vb + 60.0:
				b.rect(Rect2(x_lo, ct - 5.0, 447.0, 5.0), coping)
				b.rect(Rect2(x_lo, ct - 5.0, 447.0, 2.0), coping.lightened(0.16))
			if cb > vt - 60.0 and cb < vb + 60.0:
				b.rect(Rect2(x_lo, cb, 447.0, 5.0), coping)
				b.rect(Rect2(x_lo, cb, 447.0, 2.0), coping.lightened(0.16))
				b.rect(Rect2(x_lo, cb + 5.0, 447.0, 6.0), Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.20))
	if b != c:
		b.flush()


static func _subtract_crossings(m: Node2D, y0: float, y1: float) -> Array[Vector2]:
	var segs: Array[Vector2] = [Vector2(y0, y1)]
	for ly: float in m.lane_ys:
		var ct := ly - float(m.LANE_HALF)
		var cb := ly + float(m.LANE_HALF)
		var next: Array[Vector2] = []
		for s: Vector2 in segs:
			if s.y <= ct or s.x >= cb:
				next.append(s)
			else:
				if s.x < ct:
					next.append(Vector2(s.x, ct))
				if s.y > cb:
					next.append(Vector2(cb, s.y))
		segs = next
	return segs


# Clipped roof corner where a module is shortened by a cross-street or the
# south apartment facade so skylights or chimneys never overhang the road.
static func _draw_corner_roof(m: Node2D, b: ShapeBatch, inner_x: float, out: float, y0: float, h: float, k: int) -> void:
	var front_pitched := (k % 3) != 1
	for is_front: bool in [true, false]:
		var d0 := 0.0 if is_front else 150.0
		var d1 := 150.0 if is_front else 420.0
		var a := inner_x + out * d0
		var z := inner_x + out * d1
		var lot := Rect2(minf(a, z), y0, absf(z - a), h)
		var pitched := front_pitched if is_front else (not front_pitched)
		if pitched:
			var tile: Color = [Color(0.50, 0.28, 0.20), Color(0.56, 0.32, 0.22), Color(0.46, 0.27, 0.21)][k % 3]
			b.rect(lot, tile)
			var ridge := lot.get_center().x
			b.rect(Rect2(ridge, lot.position.y, lot.end.x - ridge, lot.size.y), tile.darkened(0.12))
			var ty := lot.position.y + 4.0
			while ty < lot.end.y - 2.0:
				b.line(Vector2(lot.position.x + 2.0, ty), Vector2(lot.end.x - 2.0, ty), tile.darkened(0.30), 2.0)
				ty += 9.0
			b.rect(Rect2(ridge - 4.0, lot.position.y, 8.0, lot.size.y), tile.lightened(0.16))
			b.rect(Rect2(ridge - 1.0, lot.position.y, 2.0, lot.size.y), tile.darkened(0.20))
		else:
			var flag := Color(0.62, 0.56, 0.50)
			b.rect(lot, flag.darkened(0.35))
			var floor_r := lot.grow(-6.0)
			if floor_r.size.y > 2.0:
				b.rect(floor_r, flag)
				var gx := floor_r.position.x + 18.0
				while gx < floor_r.end.x:
					b.line(Vector2(gx, floor_r.position.y), Vector2(gx, floor_r.end.y), flag.darkened(0.12), 1.0)
					gx += 18.0
				var gy := floor_r.position.y + 18.0
				while gy < floor_r.end.y:
					b.line(Vector2(floor_r.position.x, gy), Vector2(floor_r.end.x, gy), flag.darkened(0.12), 1.0)
					gy += 18.0
	var gx_eave := inner_x + out * 4.0
	b.rect(Rect2(gx_eave - 4.0, y0, 8.0, h), Color(0.50, 0.53, 0.56))
	b.rect(Rect2(gx_eave - 2.5, y0, 5.0, h), Color(0.40, 0.52, 0.64))
	if h > 16.0:
		b.circle(Vector2(gx_eave, y0 + 8.0), 5.0, Color(0.56, 0.58, 0.60))
		b.circle(Vector2(gx_eave, y0 + 8.0), 3.0, Color(0.22, 0.26, 0.30))


# Lit doorways for world/light_layer.gd matching draw_edge_layer's exact doors.
static func night_fronts(m: Node2D) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var y_min: float = float(m.GATE_Y) - 20.0
	var y_max: float = float(m.START_Y) + 74.0
	var door_ys := _doorway_ys(m, y_min, y_max)
	var y := floorf(y_min / EDGE_MOD) * EDGE_MOD
	while y < y_max:
		var base_dy := y + DOOR_OFFSET
		if base_dy in door_ys:
			for side: float in [-1.0, 1.0]:
				var k := int(absf(y) / EDGE_MOD) + (0 if side < 0.0 else 7)
				var kind: String = NightFronts.kind_of(k)
				if kind == "":
					continue
				var dy := base_dy + (NightFronts.TV_OFFSET if kind == "tv" else 0.0)
				if dy <= float(m.GATE_Y) + 20.0 or dy > float(m.START_Y) + 60.0 or _in_crossing(m, dy, 12.0):
					continue
				var bl: Vector2 = m.building_line(dy)
				var fx: float = (bl.x - EDGE_INSET) if side < 0.0 else (bl.y + EDGE_INSET)
				out.append(NightFronts.front(Vector2(fx, dy), -side, kind, k))
		y += EDGE_MOD
	return out


# Joins the wet panot street, gutters, stone gate sill and El Porxo's sauló
# courtyard cleanly across GATE_Y - 40 .. GATE_Y - 6 without leaving a bare
# grey paving strip poking into the courtyard.
static func draw_threshold(m: Node2D, b: ShapeBatch) -> void:
	var y_court_end: float = float(m.GATE_Y) - 30.0
	var y_sill_top: float = float(m.GATE_Y) - 6.0
	var y_fill_top: float = float(m.GATE_Y) - 40.0
	var ge: Vector2 = m.walk_edges(float(m.GATE_Y) - 16.0)
	var gl := maxf(float(m.gate_l), ge.x)
	var gr := minf(float(m.gate_r), ge.y)
	var mx := (gl + gr) * 0.5
	var court := Color(0.62, 0.53, 0.40)
	# bring El Porxo's sauló cleanly down to the wall line (-5030) across the mouth
	b.rect(Rect2(ge.x, y_fill_top, ge.y - ge.x, y_court_end - y_fill_top), court)
	# dressed stone entrance apron from the gate sill (-5006) up to the courtyard (-5030)
	var apron_col := Color(0.66, 0.61, 0.53)
	b.rect(Rect2(gl, y_court_end, gr - gl, y_sill_top - y_court_end), apron_col)
	b.rect(Rect2(gl, y_court_end, gr - gl, 2.0), Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.16))
	var jx := gl + 38.0
	while jx < gr - 10.0:
		b.line(Vector2(jx, y_court_end), Vector2(jx, y_sill_top), apron_col.darkened(0.20), 1.3)
		jx += 38.0
	# soldier course of narrow granite setts edging the panots right before the gate sill
	var sill_bot: float = float(m.GATE_Y) + 6.0
	b.rect(Rect2(gl, sill_bot, gr - gl, 8.0), KERB_STONE.darkened(0.08))
	var sx := gl
	while sx < gr - 2.0:
		var sw := minf(22.0, gr - sx)
		b.rect(Rect2(sx + 1.0, sill_bot + 1.0, sw - 2.0, 6.0), KERB_STONE.lightened(0.04 if int(sx / 22.0) % 2 == 0 else -0.05))
		sx += 22.0
	# worn damp sauló tongue feathering from the courtyard through the gate mouth
	var tongue_half := 72.0
	var tpts := PackedVector2Array()
	var trows := PackedFloat32Array([0.85, 0.55, 0.25, 0.0])
	var tcol := PackedFloat32Array([0.0, 0.85, 1.0, 0.85, 0.0])
	for sp: Array in [[y_court_end - 18.0, 1.0], [y_court_end - 2.0, 0.90], [y_sill_top - 2.0, 0.72], [sill_bot + 16.0, 0.48]]:
		var sy := float(sp[0])
		var hw := tongue_half * float(sp[1])
		tpts.append_array([
			Vector2(mx - hw, sy), Vector2(mx - hw * 0.55, sy), Vector2(mx, sy),
			Vector2(mx + hw * 0.55, sy), Vector2(mx + hw, sy),
		])
	b.band(tpts, 5, court, trows, tcol)


# The street is paved in panots de flor, the Barcelona pavement tile with a
# four-petal flower pressed into it, laid square (world/panot.gd): drawn over
# the walkway's slabs, the flowers' grooves dark with water and their crowns
# catching the light. Off the crossings, which are asphalt.
const PANOT := Panot.FLOR
const PANOT_GROOVE := Color(0.0, 0.02, 0.06, 0.13)
const PANOT_SHINE := Color(0.90, 0.94, 1.0, 0.10)
const PANOT_DRY_GROOVE := Color(0.14, 0.10, 0.06, 0.10)
const PANOT_DRY_SHINE := Color(1.0, 0.96, 0.88, 0.08)


static func _on_crossing(m: Node2D, y: float) -> bool:
	for ly: float in m.lane_ys:
		if absf(y - ly) < float(m.LANE_HALF) - PANOT * 0.35:
			return true
	return false


static func draw_over_walkway(m: Node2D, wc: ShapeBatch, vt: float, vb: float) -> void:
	var y_top_lim: float = float(m.GATE_Y) + 6.0
	var y_bot_lim: float = float(m.START_Y) + 74.0
	var arc_y0: float = LevelBuild.DILUVI_ARCADE_Y0
	var arc_y1: float = LevelBuild.DILUVI_ARCADE_Y1
	var arc_w: float = LevelBuild.DILUVI_ARCADE_W

	# 1. Dry arcade paving slab + stone kerb along [ARCADE_Y0, ARCADE_Y1]
	var ay0 := maxf(arc_y0, vt - PANOT)
	var ay1 := minf(arc_y1, vb + PANOT)
	if ay1 > ay0:
		wc.rect(Rect2(m.sw_l, ay0, arc_w, ay1 - ay0), DRY_ARCADE_STONE)
		wc.rect(Rect2(m.sw_l + arc_w - 3.0, ay0, 6.0, ay1 - ay0), KERB_STONE)
		wc.rect(Rect2(m.sw_l + arc_w - 3.0, ay0, 2.0, ay1 - ay0), KERB_STONE.lightened(0.14))
		# stone end-return thresholds anchoring the north and south ends of the arcade
		for end_y: float in [arc_y0, arc_y1]:
			if end_y >= vt - 40.0 and end_y <= vb + 40.0:
				wc.rect(Rect2(m.sw_l, end_y - 6.0, arc_w + 14.0, 12.0), KERB_STONE)
				wc.rect(Rect2(m.sw_l, end_y - 6.0, arc_w + 14.0, 2.0), KERB_STONE.lightened(0.16))
				wc.rect(Rect2(m.sw_l, end_y + 6.0, arc_w + 14.0, 3.0), Color(0, 0, 0, 0.14))

	# 2. Panot tiles: dry tiles under the arcade, wet street tiles between the kerbs
	var top: float = maxf(vt - PANOT, y_top_lim)
	var bot: float = minf(vb + PANOT, y_bot_lim)
	var y := floorf(top / PANOT) * PANOT
	while y < bot:
		var r_top := maxf(y, y_top_lim)
		var r_bot := minf(y + PANOT, y_bot_lim)
		var r_mid := (r_top + r_bot) * 0.5
		if r_bot - r_top >= PANOT * 0.5 and not _on_crossing(m, r_mid):
			var in_arc := _in_arcade_y(r_mid)
			var past_gutter := r_mid > float(m.START_Y) + 56.0
			if in_arc:
				Panot.flor_row(wc, m.sw_l + 2.0, m.sw_l + arc_w - 4.0, y, m.sw_l + 2.0, PANOT_DRY_GROOVE, PANOT_DRY_SHINE)
			var wet_l: float = m.sw_l if past_gutter else ((m.sw_l + ARCADE_GUTTER_X + KERB_W) if in_arc else (m.sw_l + GUTTER_W + KERB_W))
			var wet_r: float = m.sw_r if past_gutter else (m.sw_r - GUTTER_W - KERB_W)
			Panot.flor_row(wc, wet_l, wet_r, y, m.sw_l + 30.0, PANOT_GROOVE, PANOT_SHINE)
		y += PANOT

	# 3. Cached gutter stone beds, granite kerbs, and doorway culvert bridges
	var g_top := maxf(vt - 60.0, float(m.GATE_Y) + 14.0)
	var g_bot := minf(vb + 60.0, float(m.START_Y) + 52.0)
	if float(m.START_Y) + 52.0 >= vt - 40.0 and float(m.START_Y) + 52.0 <= vb + 40.0:
		var ky := float(m.START_Y) + 52.0
		wc.rect(Rect2(m.sw_l, ky, GUTTER_W + KERB_W, KERB_W), KERB_STONE)
		wc.rect(Rect2(m.sw_r - GUTTER_W - KERB_W, ky, GUTTER_W + KERB_W, KERB_W), KERB_STONE)
	for seg: Vector2 in _subtract_crossings(m, g_top, g_bot):
		# east gutter bed + granite kerb
		wc.rect(Rect2(m.sw_r - GUTTER_W, seg.x, GUTTER_W, seg.y - seg.x), GUTTER_BED)
		wc.rect(Rect2(m.sw_r - GUTTER_W - KERB_W, seg.x, KERB_W, seg.y - seg.x), KERB_STONE)
		# west gutter bed + granite kerb (steps out around the arcade)
		var w_pieces: Array[Array] = []
		if seg.x < arc_y0:
			w_pieces.append([seg.x, minf(seg.y, arc_y0), false])
		if seg.y > arc_y0 and seg.x < arc_y1:
			w_pieces.append([maxf(seg.x, arc_y0), minf(seg.y, arc_y1), true])
		if seg.y > arc_y1:
			w_pieces.append([maxf(seg.x, arc_y1), seg.y, false])
		for wp: Array in w_pieces:
			var wy0 := float(wp[0])
			var wy1 := float(wp[1])
			if wy1 <= wy0:
				continue
			if bool(wp[2]):
				var gx0: float = m.sw_l + ARCADE_GUTTER_X - GUTTER_W
				wc.rect(Rect2(gx0, wy0, GUTTER_W, wy1 - wy0), GUTTER_BED)
				wc.rect(Rect2(gx0 + GUTTER_W, wy0, KERB_W, wy1 - wy0), KERB_STONE)
			else:
				wc.rect(Rect2(m.sw_l, wy0, GUTTER_W, wy1 - wy0), GUTTER_BED)
				wc.rect(Rect2(m.sw_l + GUTTER_W, wy0, KERB_W, wy1 - wy0), KERB_STONE)

	# stone doorstep culvert slabs bridging the gutter cleanly
	for dy: float in _doorway_ys(m, float(m.GATE_Y) - 20.0, y_bot_lim):
		if dy < vt - 40.0 or dy > vb + 40.0:
			continue
		if not _in_arcade_y(dy):
			wc.rect(Rect2(m.sw_l, dy - 16.0, GUTTER_W + KERB_W + 1.0, 32.0), Color(0.60, 0.57, 0.52))
			wc.rect(Rect2(m.sw_l + GUTTER_W + KERB_W - 1.0, dy - 16.0, 2.0, 32.0), Color(0.72, 0.69, 0.63))
		wc.rect(Rect2(m.sw_r - GUTTER_W - KERB_W - 1.0, dy - 16.0, GUTTER_W + KERB_W + 1.0, 32.0), Color(0.60, 0.57, 0.52))
		wc.rect(Rect2(m.sw_r - GUTTER_W - KERB_W - 1.0, dy - 16.0, 2.0, 32.0), Color(0.72, 0.69, 0.63))
