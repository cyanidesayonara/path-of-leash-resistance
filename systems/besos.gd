class_name Besos
extends RefCounted

# WALK: EL BESÒS (the river walk). Its drawing as static functions over main's
# state (main.WALK_MODULES): the concrete flood wall along the west side, the
# river beside the path (margin, deep channel, apron, weir, gauge, reeds,
# bridge) and the Parc Fluvial waymarkers that stand in for hydrants. The
# river's water and depth (LevelBuild.besos_water_rect, besos_deep_rect)
# and the clearing past the gate stay where they are.

# its off-leash area's worn patch is soft at the edge (main.soft_wear)
const SOFT_WEAR := true
# the hooks main calls on this walk, held to it by tests/test_walk_hooks.gd
const HOOKS := [
	"build_layer",
	"draw_bollard",
	"draw_clearing",
	"draw_edge_layer",
	"draw_over_walkway",
	"draw_threshold",
	"night_lights",
]


const ShapeBatch := preload("res://systems/shape_batch.gd")
const LevelBuild := preload("res://world/level_build.gd")
const Stones := preload("res://world/stones.gd")

# the deep channel, and the lighter water where it shelves up to the riprap,
# feathered out over SHELF_W by SHELF_COLS
const DEEP := Color(0.08, 0.21, 0.29)
const SHALLOWER := Color(0.12, 0.28, 0.36)
const SHELF_W := 120.0
const SHELF_COLS: Array[float] = [1.0, 0.7, 0.35, 0.12, 0.0]
# the riprap: a pair of stones every RIP_STEP down the bank
const RIP_STEP := 16.0
const RIP_STONES: Array[Color] = [Color(0.44, 0.43, 0.39), Color(0.50, 0.47, 0.41),
	Color(0.40, 0.40, 0.38), Color(0.53, 0.50, 0.44)]

static func draw_wall_module(m: Node2D, c: Object, r: Rect2, k: int, inner_x: float) -> void:
	var y0 := r.position.y
	var y1 := r.end.y
	var h := r.size.y
	# Upper riverside embankment behind the concrete flood wall: planted grass
	# berm, upper promenade bike/walkway (passeig superior), and heavy concrete
	# parapet coping with expansion joints and emergency exit stairs.
	c.draw_rect(Rect2(r.position.x - 160.0, y0, r.size.x + 160.0, h), Color(0.30, 0.44, 0.27))
	c.draw_rect(Rect2(r.position.x + 10.0, y0, 44.0, h), Color(0.46, 0.45, 0.42))
	c.draw_line(Vector2(r.position.x + 10.0, y0), Vector2(r.position.x + 10.0, y1), Color(0.62, 0.60, 0.56), 2.0)
	c.draw_line(Vector2(r.position.x + 54.0, y0), Vector2(r.position.x + 54.0, y1), Color(0.62, 0.60, 0.56), 2.0)
	var dy := y0 + 12.0
	while dy < y1 - 8.0:
		c.draw_line(Vector2(r.position.x + 32.0, dy), Vector2(r.position.x + 32.0, minf(dy + 18.0, y1 - 4.0)),
			Color(0.90, 0.88, 0.80, 0.55), 1.8)
		dy += 36.0
	# Concrete flood wall coping cap and galvanized safety railing
	var cap_x := inner_x - 14.0
	c.draw_rect(Rect2(cap_x, y0, 19.0, h), Color(0.66, 0.64, 0.59))
	c.draw_rect(Rect2(cap_x, y0, 4.0, h), Color(0.76, 0.74, 0.69))
	c.draw_line(Vector2(cap_x + 3.0, y0), Vector2(cap_x + 3.0, y1), Color(0.42, 0.46, 0.48), 2.2)
	for pi in range(5):
		var py := y0 + 18.0 + float(pi) * 46.0
		c.draw_circle(Vector2(cap_x + 3.0, py), 2.6, Color(0.30, 0.33, 0.36))
	# Vertical expansion joints across the coping and battered concrete wall face
	for ji in range(4):
		var jy := y0 + float(ji) * 55.0
		c.draw_line(Vector2(cap_x, jy), Vector2(m.sw_l, jy), Color(0.26, 0.25, 0.23, 0.60), 1.6)
		c.draw_line(Vector2(cap_x, jy + 1.8), Vector2(m.sw_l, jy + 1.8), Color(0.78, 0.76, 0.71, 0.35), 1.0)
	# Weep-hole drainage pipes (barbacanes) near the foot of the flood wall
	for wi in range(2):
		var wy := y0 + 42.0 + float(wi) * 110.0
		c.draw_rect(Rect2(m.sw_l - 6.0, wy - 3.0, 6.0, 6.0), Color(0.28, 0.32, 0.26, 0.45))
		c.draw_circle(Vector2(m.sw_l - 3.0, wy), 2.2, Color(0.16, 0.17, 0.18))
	# Upper embankment hackberry/pine tree crowns west of the upper walkway
	var ty := y0 + 56.0 + float(k % 3) * 34.0
	var tp := Vector2(r.position.x - 16.0, ty)
	c.draw_circle(tp + Vector2(5.0, 6.0), 20.0, Color(0.06, 0.08, 0.06, 0.26))
	c.draw_circle(tp, 19.0, Color(0.21, 0.36, 0.21))
	c.draw_circle(tp + Vector2(-4.0, -4.0), 12.0, Color(0.29, 0.46, 0.27))
	# Every second module has a recessed emergency evacuation stairway bay
	if k % 2 == 0:
		var sy0 := y0 + 74.0
		var sh := 68.0
		var bay := Rect2(cap_x - 12.0, sy0, (m.sw_l - cap_x) + 12.0, sh)
		c.draw_rect(bay, Color(0.40, 0.39, 0.36))
		for st in range(6):
			var sy := sy0 + 5.0 + float(st) * 10.0
			var tone := 0.62 - float(st) * 0.03
			c.draw_rect(Rect2(bay.position.x + 3.0, sy, bay.size.x - 6.0, 8.0), Color(tone, tone * 0.98, tone * 0.92))
			c.draw_line(Vector2(bay.position.x + 3.0, sy), Vector2(bay.end.x - 3.0, sy), Color(0.24, 0.23, 0.21, 0.7), 1.4)
		# Yellow tubular steel safety handrails and green evacuation sign plaque
		c.draw_line(Vector2(bay.position.x + 2.0, sy0 + 2.0), Vector2(m.sw_l - 1.0, sy0 + 2.0), Color(0.88, 0.72, 0.18), 2.6)
		c.draw_line(Vector2(bay.position.x + 2.0, sy0 + sh - 2.0), Vector2(m.sw_l - 1.0, sy0 + sh - 2.0), Color(0.88, 0.72, 0.18), 2.6)
		var sign_r := Rect2(m.sw_l - 10.0, sy0 - 14.0, 9.0, 10.0)
		c.draw_rect(sign_r, Color(0.14, 0.52, 0.28))
		c.draw_rect(sign_r.grow(-1.5), Color(0.94, 0.96, 0.94))
		c.draw_rect(sign_r.grow(-2.8), Color(0.14, 0.52, 0.28))


static func draw_post(m: Node2D, c: Object, h: Dictionary) -> void:
	# Parc Fluvial del Besos waymarker & SAHBE emergency zone post (replaces
	# urban fire hydrants along the riverside walk).
	var hp: Vector2 = h.pos
	m.cast_shadow(c, hp, 8.0, 28.0)
	var done := bool(h.done)
	var base_col := Color(0.56, 0.54, 0.50) if not done else Color(0.44, 0.43, 0.40)
	var post_col := Color(0.20, 0.44, 0.28) if not done else Color(0.28, 0.34, 0.30)
	var wood_col := Color(0.54, 0.40, 0.25) if not done else Color(0.42, 0.35, 0.26)
	# Concrete collar footing
	c.draw_circle(hp + Vector2(0.0, 2.0), 11.5, base_col.darkened(0.28))
	c.draw_circle(hp + Vector2(0.0, 1.5), 9.2, base_col)
	# Treated-timber & green steel totem post
	c.draw_rect(Rect2(hp.x - 6.5, hp.y - 7.5, 13.0, 13.0), wood_col.darkened(0.25))
	c.draw_rect(Rect2(hp.x - 5.5, hp.y - 6.5, 11.0, 11.0), wood_col)
	c.draw_rect(Rect2(hp.x - 5.5, hp.y - 6.5, 11.0, 4.5), post_col)
	# SAHBE zone band (yellow/blue hydrological badge)
	var badge_a := 0.95 if not done else 0.40
	c.draw_rect(Rect2(hp.x - 4.5, hp.y - 1.5, 9.0, 2.6), Color(0.94, 0.78, 0.20, badge_a))
	c.draw_rect(Rect2(hp.x - 4.5, hp.y + 1.2, 9.0, 2.2), Color(0.18, 0.50, 0.72, badge_a))
	if not done and float(h.progress) > 0.0:
		c.draw_arc(hp, 17.0, -PI / 2.0, -PI / 2.0 + TAU * float(h.progress) / 0.8, 20, Color(1, 0.95, 0.7), 3.0)


# The river beside the path: shallow margin, the deep channel, the apron the
# flood holds on, and the gear that warns you. One batch, only while the
# south end of it is the walk (the meadow past the gate stays grass).
static func draw_river(m: Node2D, vt: float, vb: float) -> void:
	var water := LevelBuild.besos_water_rect(m)
	var channel := LevelBuild.besos_deep_rect(m)
	var river_top := float(m.GATE_Y)
	var river_bot := float(m.START_Y) + 560.0
	if river_bot < vt - 40.0 or river_top > vb + 40.0:
		return
	var b := ShapeBatch.new()
	var y0 := maxf(river_top, vt - 20.0)
	var y1 := minf(river_bot, vb + 20.0)
	var wt := AnimClock.msec() / 1000.0
	var apron := LevelBuild.BESOS_APRON

	# 1. Shared pedestrian & two-way cycle track along the west side of the paved path
	var lane_x0: float = m.sw_l + 16.0
	var lane_w := 86.0
	var lane_x1 := lane_x0 + lane_w
	var lane_cx := lane_x0 + lane_w * 0.5
	var path_y0 := maxf(float(m.GATE_Y) - 28.0, vt - 20.0)
	var path_y1 := minf(river_bot, vb + 20.0)
	var south_wall_y := float(m.HOME_Y) + 34.0
	var lane_bot := minf(path_y1, south_wall_y)
	var apron_n := apron.position.y - 12.0
	var apron_s := apron.end.y + 12.0
	var segs: Array = []
	if path_y0 < apron_n:
		segs.append([path_y0, minf(lane_bot, apron_n), path_y0 <= float(m.GATE_Y) - 27.5, lane_bot >= apron_n - 0.5])
	if lane_bot > apron_s:
		segs.append([maxf(path_y0, apron_s), lane_bot, path_y0 <= apron_s + 0.5, lane_bot >= south_wall_y - 0.5])
	for sg: Array in segs:
		var sy0 := float(sg[0])
		var sy1 := float(sg[1])
		if sy1 <= sy0:
			continue
		b.rect(Rect2(lane_x0, sy0, lane_w, sy1 - sy0), Color(0.64, 0.44, 0.36, 0.20))
		b.line(Vector2(lane_x0, sy0), Vector2(lane_x0, sy1), Color(0.94, 0.92, 0.86, 0.46), 2.0)
		b.line(Vector2(lane_x1, sy0), Vector2(lane_x1, sy1), Color(0.94, 0.92, 0.86, 0.46), 2.0)
		if bool(sg[2]):
			b.line(Vector2(lane_x0, sy0), Vector2(lane_x1, sy0), Color(0.94, 0.92, 0.86, 0.62), 2.4)
			b.line(Vector2(lane_x0 + 6.0, sy0 + 8.0), Vector2(lane_x1 - 6.0, sy0 + 8.0), Color(0.94, 0.92, 0.86, 0.35), 1.6)
		if bool(sg[3]):
			var cap_y := sy1 - 2.0 if sy1 >= south_wall_y - 0.5 else sy1
			b.line(Vector2(lane_x0, cap_y), Vector2(lane_x1, cap_y), Color(0.94, 0.92, 0.86, 0.62), 2.4)
		var dash_y := floorf(sy0 / 48.0) * 48.0
		while dash_y < sy1:
			var d0 := maxf(dash_y, sy0)
			var d1 := minf(dash_y + 22.0, sy1)
			if d1 > d0 + 2.0:
				b.line(Vector2(lane_cx, d0), Vector2(lane_cx, d1), Color(0.94, 0.92, 0.86, 0.42), 1.8)
			dash_y += 48.0
		# Painted white bicycle lane symbols every 640px
		var sym_y := floorf(sy0 / 640.0) * 640.0 + 220.0
		while sym_y < sy1 - 24.0:
			if sym_y > sy0 + 24.0 and sym_y < float(m.START_Y) - 80.0:
				var bc := Vector2(lane_cx - 21.0, sym_y)
				var sc_col := Color(0.94, 0.92, 0.86, 0.48)
				b.circle(bc + Vector2(0.0, -7.0), 4.2, sc_col)
				b.circle(bc + Vector2(0.0, -7.0), 2.4, Color(0.68, 0.58, 0.48, 0.85))
				b.circle(bc + Vector2(0.0, 7.0), 4.2, sc_col)
				b.circle(bc + Vector2(0.0, 7.0), 2.4, Color(0.68, 0.58, 0.48, 0.85))
				b.line(bc + Vector2(0.0, -7.0), bc + Vector2(4.0, 0.0), sc_col, 1.6)
				b.line(bc + Vector2(4.0, 0.0), bc + Vector2(0.0, 7.0), sc_col, 1.6)
				b.line(bc + Vector2(-4.0, -2.0), bc + Vector2(4.0, 0.0), sc_col, 1.6)
			sym_y += 640.0

	# 2. Riverbed base, feathered shingle shoreline, shallow wading margin, and deep channel
	var deep_w := channel.size.x + 180.0
	if vt < float(m.GATE_Y) + 20.0:
		# Tuck grass under the stone headwall coping at GATE_Y - 9 so no gap shows at the bank
		b.rect(Rect2(water.position.x - 8.0, float(m.GATE_Y) - 9.0, water.size.x + deep_w + 8.0, 11.0), Color(0.30, 0.45, 0.28))
	b.rect(Rect2(m.sw_r, y0, water.position.x - m.sw_r, y1 - y0), Color(0.30, 0.45, 0.28))
	b.rect(Rect2(water.position.x, y0, water.size.x, y1 - y0), Color(0.44, 0.50, 0.40))
	b.rect(Rect2(water.position.x, y0, water.size.x, y1 - y0), Color(0.45, 0.68, 0.66, 0.85))
	# Feathered shallow-water sun shelf along the shingle bank (no hard vertical stripe)
	var wade_pts := PackedVector2Array()
	for yy: float in [y0, y1]:
		for wx_off: float in [0.0, 22.0, 54.0, 92.0]:
			wade_pts.append(Vector2(water.position.x + wx_off, yy))
	b.band(wade_pts, 4, Color(0.58, 0.78, 0.74), PackedFloat32Array([1.0, 1.0]), PackedFloat32Array([0.42, 0.24, 0.08, 0.0]))
	# Feathered sandy-gravel shingle margin between the lawn and shallow water
	var shin_pts := PackedVector2Array()
	for yy: float in [y0, y1]:
		for sx_off: float in [-14.0, -4.0, 5.0, 16.0]:
			shin_pts.append(Vector2(water.position.x + sx_off, yy))
	b.band(shin_pts, 4, Color(0.62, 0.58, 0.48), PackedFloat32Array([1.0, 1.0]), PackedFloat32Array([0.0, 0.80, 0.72, 0.0]))
	# Concrete edging kerb along the east side of the promenade (sw_r) + grass tufts over its edge
	var kerb_y0 := maxf(float(m.GATE_Y) - 40.0, vt - 20.0)
	var kerb_y1 := minf(float(m.START_Y) + 420.0, vb + 20.0)
	if kerb_y1 > kerb_y0:
		b.rect(Rect2(m.sw_r + 5.0, kerb_y0, 5.0, kerb_y1 - kerb_y0), Color(0.05, 0.04, 0.07, 0.16))
		b.rect(Rect2(m.sw_r - 4.0, kerb_y0, 9.0, kerb_y1 - kerb_y0), Color(0.58, 0.56, 0.51))
		b.rect(Rect2(m.sw_r - 4.0, kerb_y0, 2.5, kerb_y1 - kerb_y0), Color(0.76, 0.74, 0.69))
		var kj := floorf(kerb_y0 / 112.0) * 112.0
		while kj < kerb_y1:
			if kj > kerb_y0 + 2.0:
				b.line(Vector2(m.sw_r - 4.0, kj), Vector2(m.sw_r + 5.0, kj), Color(0.36, 0.35, 0.32, 0.65), 1.4)
			kj += 112.0
		var ky := floorf(kerb_y0 / 26.0) * 26.0
		while ky < kerb_y1:
			if ky > kerb_y0 + 4.0:
				var kh: float = m._cell01(ky, 31.0)
				if kh > 0.25:
					var gx: float = m.sw_r + 5.0
					var gy := ky + kh * 14.0
					var gc := Color(0.28, 0.43, 0.25) if kh > 0.6 else Color(0.34, 0.50, 0.29)
					b.line(Vector2(gx + 2.0, gy), Vector2(gx - 3.0 - kh * 2.5, gy - 2.0), gc, 1.8)
					b.line(Vector2(gx + 2.0, gy), Vector2(gx - 2.0, gy + 3.0), gc, 1.6)
			ky += 26.0
	# the channel shelving away from the bank: one fill, lighter along the
	# riprap and feathering into the deep water (a second flat rect showed
	# its edge as a seam down the river)
	b.rect(Rect2(channel.position.x, y0, deep_w, y1 - y0), DEEP)
	var shelf := PackedVector2Array()
	for yy: float in [y0, y1]:
		for k in range(SHELF_COLS.size()):
			shelf.append(Vector2(channel.position.x + SHELF_W * float(k) / float(SHELF_COLS.size() - 1), yy))
	b.band(shelf, SHELF_COLS.size(), SHALLOWER, PackedFloat32Array([1.0, 1.0]), PackedFloat32Array(SHELF_COLS))
	if vt < float(m.GATE_Y) + 20.0:
		# Stone headwall coping tucked directly against the Pont de Can Peixauet bridge deck at GATE_Y
		b.rect(Rect2(water.position.x - 8.0, float(m.GATE_Y) - 9.0, water.size.x + deep_w + 8.0, 10.0), Color(0.56, 0.54, 0.49))
		b.rect(Rect2(water.position.x - 8.0, float(m.GATE_Y) - 9.0, water.size.x + deep_w + 8.0, 3.0), Color(0.68, 0.66, 0.60))

	# Rounded river cobbles and overhanging grass blades along the shingle shoreline
	var sh_y := floorf(y0 / 16.0) * 16.0
	while sh_y < y1:
		if sh_y + 8.0 < y0 + 4.0:
			sh_y += 16.0
			continue
		var h0: float = m._cell01(sh_y, 19.0)
		var cx_s := water.position.x - 2.0 + (h0 - 0.5) * 11.0
		var cr := 2.2 + fmod(h0 * 13.0, 2.4)
		var c_col := Color(0.58, 0.55, 0.47) if h0 > 0.45 else Color(0.48, 0.46, 0.40)
		b.circle(Vector2(cx_s, sh_y + 8.0), cr, c_col)
		if h0 > 0.52:
			var gx_b := water.position.x - 8.0 + (h0 - 0.52) * 8.0
			var gc_b := Color(0.28, 0.43, 0.25)
			b.line(Vector2(gx_b, sh_y + 4.0), Vector2(gx_b + 5.0, sh_y + 1.0), gc_b, 1.7)
			b.line(Vector2(gx_b, sh_y + 5.0), Vector2(gx_b + 4.0, sh_y + 7.5), gc_b, 1.5)
		sh_y += 16.0

	# 3. Quarry-stone riprap embankment (escullera) between shallow margin and deep channel
	var rip_x := channel.position.x
	b.rect(Rect2(rip_x - 8.0, y0, 16.0, y1 - y0), Color(0.20, 0.24, 0.24, 0.72))
	# quarry stones tipped, not laid: two staggered courses of angular blocks
	# of every size, the odd small one wedged between (a single file of round
	# stones read as a string of beads)
	var ry := floorf(y0 / RIP_STEP) * RIP_STEP
	while ry < y1:
		if ry + RIP_STEP < y0:
			ry += RIP_STEP
			continue
		var rh: float = m._cell01(ry, 73.0)
		for course in range(2):
			var h: float = m._cell01(ry + float(course) * 7.0, 81.0 + float(course) * 13.0)
			var at := Vector2(rip_x + (course * 2 - 1) * 5.5 + (h - 0.5) * 7.0,
				ry + RIP_STEP * 0.5 * float(course) + (rh - 0.5) * 5.0)
			var rr := 5.0 + h * 5.5
			var stone_c := RIP_STONES[int(h * 97.0) % RIP_STONES.size()]
			Stones.stone(b, at + Vector2(1.5, 1.8), rr, Color(0.10, 0.14, 0.16, 0.55), h)
			Stones.stone(b, at, rr, stone_c, h)
			Stones.stone(b, at - Vector2(rr * 0.22, rr * 0.25), rr * 0.5, stone_c.lightened(0.14), h + 0.37)
			if h > 0.62:
				var chip := at + Vector2((h - 0.8) * 14.0, rr + 1.5)
				Stones.stone(b, chip, 2.4 + h * 1.6, stone_c.darkened(0.12), h + 0.71)
		if int(rh * 31.0) % 3 == 0:
			var lap := sin(ry * 0.04 + wt * 2.2) * 1.5
			b.line(Vector2(rip_x - 13.0 + lap, ry + 3.0), Vector2(rip_x - 12.0 + lap, ry + 15.0),
				Color(0.92, 0.97, 0.96, 0.42), 1.6)
		ry += RIP_STEP

	# 4. Water current ripples and surface shimmer in both shallow margin and deep channel
	var wy := floorf(y0 / 90.0) * 90.0
	while wy < y1:
		if wy < y0 + 6.0:
			wy += 90.0
			continue
		var wobble := sin(wy * 0.02 + wt) * 4.0
		b.line(Vector2(water.position.x + 12.0 + wobble, wy),
			Vector2(water.end.x - 14.0 + wobble, wy + 28.0), Color(1, 1, 1, 0.18), 2.0)
		var dwobble := cos(wy * 0.017 - wt * 1.4) * 6.0
		b.line(Vector2(channel.position.x + 26.0 + dwobble, wy + 18.0),
			Vector2(channel.position.x + 180.0 + dwobble, wy + 52.0), Color(0.72, 0.88, 0.94, 0.14), 2.2)
		b.line(Vector2(channel.position.x + 90.0 - dwobble, wy + 54.0),
			Vector2(channel.position.x + 110.0 - dwobble, wy + 78.0), Color(0.84, 0.94, 0.98, 0.12), 1.6)
		wy += 90.0

	# 5. Riverside reed beds (canyissars & boga / Typha), denser in the authored reedy stretch (-4250..-3450)
	var cy := floorf(y0 / 55.0) * 55.0
	while cy < y1:
		if cy + 22.0 < y0 + 14.0:
			cy += 55.0
			continue
		var in_reedy := cy >= -4260.0 and cy <= -3440.0
		var ch: float = m._cell01(cy, 41.0)
		if (in_reedy or int(absf(cy / 55.0)) % 2 == 0) and absf(cy - (-3112.0)) > 42.0:
			var sway := sin(wt * 1.8 + cy * 0.015) * 2.6
			var base_p := Vector2(water.position.x + 8.0 + fmod(ch * 19.0, 14.0), cy + 22.0)
			b.circle(base_p + Vector2(1.0, 2.0), 7.5, Color(0.16, 0.28, 0.22, 0.45))
			for st in range(5):
				var ang := -PI * 0.5 + (float(st) - 2.0) * 0.28 + (ch - 0.5) * 0.2
				var ln := 13.0 + float(st % 2) * 4.5
				var tip := base_p + Vector2.from_angle(ang) * ln + Vector2(sway, 0.0)
				var blade_c := Color(0.24, 0.46, 0.24) if st % 2 == 0 else Color(0.34, 0.56, 0.30)
				b.line(base_p, tip, blade_c, 2.0)
				if st == 1 or (in_reedy and st == 3):
					# Brown cattail spike (boga) or feathery Arundo plume
					var mid := base_p.lerp(tip, 0.72)
					if int(ch * 100.0 + float(st)) % 2 == 0:
						b.line(mid, tip, Color(0.42, 0.25, 0.13), 3.4)
					else:
						b.circle(tip, 2.6, Color(0.86, 0.82, 0.68, 0.85))
			if in_reedy and int(ch * 23.0) % 2 == 0:
				var r_cluster := Vector2(rip_x - 10.0 - fmod(ch * 11.0, 8.0), cy + 36.0)
				for st2 in range(4):
					var ang2 := -PI * 0.5 + (float(st2) - 1.5) * 0.30
					var tip2 := r_cluster + Vector2.from_angle(ang2) * 12.0 + Vector2(sway, 0.0)
					b.line(r_cluster, tip2, Color(0.26, 0.48, 0.26), 1.8)
		cy += 55.0

	# 6. Raised concrete maintenance apron & high-water refuge (LevelBuild.BESOS_APRON)
	if apron.end.y > vt - 20.0 and apron.position.y < vb + 20.0:
		b.rect(apron.grow(10.0), Color(0.48, 0.46, 0.43))
		b.rect(apron.grow(6.0), Color(0.62, 0.60, 0.56))
		b.rect(apron, Color(0.78, 0.74, 0.66))
		# Concrete slab expansion joints on the apron deck
		for jx: float in [apron.position.x + 80.0, apron.position.x + 160.0]:
			b.line(Vector2(jx, apron.position.y + 4.0), Vector2(jx, apron.end.y - 4.0),
				Color(0.56, 0.53, 0.47, 0.55), 1.6)
		for jy: float in [apron.position.y + 73.0, apron.position.y + 146.0]:
			b.line(Vector2(apron.position.x + 4.0, jy), Vector2(apron.end.x - 4.0, jy),
				Color(0.56, 0.53, 0.47, 0.55), 1.6)
		# Upstream (north) flood-diverting cutwater kerb with yellow/black hazard stripes
		var kerb_y := apron.position.y - 6.0
		b.rect(Rect2(apron.position.x - 6.0, kerb_y, apron.size.x + 12.0, 8.0), Color(0.20, 0.20, 0.22))
		var sx := apron.position.x - 2.0
		var s_idx := 0
		while sx < apron.end.x - 6.0:
			var scol := Color(0.92, 0.74, 0.16) if s_idx % 2 == 0 else Color(0.18, 0.18, 0.20)
			b.rect(Rect2(sx, kerb_y + 1.0, 14.0, 6.0), scol)
			sx += 14.0
			s_idx += 1
		# Corner cast-iron drainage scupper grates and refuge chevron emblem
		for sc_p: Vector2 in [
			apron.position + Vector2(14.0, 14.0),
			Vector2(apron.end.x - 14.0, apron.position.y + 14.0),
			Vector2(apron.position.x + 14.0, apron.end.y - 14.0),
			apron.end - Vector2(14.0, 14.0),
		]:
			b.rect(Rect2(sc_p - Vector2(5.0, 5.0), Vector2(10.0, 10.0)), Color(0.26, 0.27, 0.28))
			b.rect(Rect2(sc_p - Vector2(3.5, 3.5), Vector2(7.0, 7.0)), Color(0.16, 0.17, 0.18))
		var ac := apron.get_center()
		b.rect(Rect2(ac.x - 22.0, ac.y - 16.0, 44.0, 32.0), Color(0.22, 0.52, 0.34, 0.28))
		b.line(ac + Vector2(-12.0, 5.0), ac + Vector2(0.0, -7.0), Color(0.94, 0.94, 0.90, 0.55), 2.4)
		b.line(ac + Vector2(0.0, -7.0), ac + Vector2(12.0, 5.0), Color(0.94, 0.94, 0.90, 0.55), 2.4)

	# 7. Enamelled hydrological depth gauges (escales limnimetriques) & SAHBE beacons on the flood wall
	var alert_on := String(m.chase_phase) != ""
	var gy: float = floorf(maxf(y0, m.GATE_Y) / 800.0) * 800.0
	while gy < y1:
		if gy >= m.GATE_Y and gy <= m.START_Y:
			b.rect(Rect2(m.sw_l - 10.0, gy - 4.0, 13.0, 36.0), Color(0.26, 0.28, 0.30))
			b.rect(Rect2(m.sw_l - 8.0, gy - 2.0, 10.0, 32.0), Color(0.94, 0.94, 0.90))
			b.rect(Rect2(m.sw_l - 8.0, gy, 10.0, 28.0), Color(0.75, 0.55, 0.18))
			b.rect(Rect2(m.sw_l - 8.0, gy + 18.0, 10.0, 10.0), Color(0.20, 0.48, 0.74))
			b.rect(Rect2(m.sw_l - 8.0, gy - 2.0, 10.0, 10.0), Color(0.86, 0.22, 0.18))
			b.rect(Rect2(m.sw_l - 4.0, gy + 8.0, 4.0, 8.0), Color(0.9, 0.2, 0.15))
			for ti in range(7):
				var ty := gy - 1.0 + float(ti) * 4.5
				b.line(Vector2(m.sw_l - 8.0, ty), Vector2(m.sw_l - 3.0, ty), Color(0.14, 0.15, 0.16, 0.85), 1.2)
			# SAHBE acoustic siren & optical beacon housing above the gauge
			var siren_p := Vector2(m.sw_l - 4.0, gy - 12.0)
			b.rect(Rect2(siren_p.x - 5.0, siren_p.y - 5.0, 10.0, 10.0), Color(0.34, 0.36, 0.38))
			var dome_c := Color(1.0, 0.68, 0.14) if alert_on else Color(0.72, 0.44, 0.14)
			b.circle(siren_p, 3.5, dome_c)
			if alert_on:
				var pulse := 0.35 + 0.45 * absf(sin(wt * 9.0 + gy * 0.01))
				b.circle(siren_p, 9.5, Color(1.0, 0.56, 0.12, pulse))
		gy += 800.0

	# 8. Inflatable rubber weir (assut inflable) across the river at y = -3112
	if absf(-3100.0 - (vt + vb) * 0.5) < 520.0:
		var weir_y := -3112.0
		var weir_w := deep_w + water.size.x
		# Concrete abutment piers anchored into the banks
		b.rect(Rect2(water.position.x - 14.0, weir_y - 5.0, 18.0, 28.0), Color(0.56, 0.54, 0.50))
		b.rect(Rect2(water.position.x - 12.0, weir_y - 3.0, 14.0, 24.0), Color(0.68, 0.66, 0.61))
		b.rect(Rect2(channel.position.x - 9.0, weir_y - 4.0, 18.0, 26.0), Color(0.54, 0.52, 0.48))
		# Cylindrical EPDM elastomer bladder dam
		b.rect(Rect2(water.position.x - 8.0, weir_y, weir_w + 16.0, 18.0), Color(0.25, 0.32, 0.34))
		b.rect(Rect2(water.position.x - 4.0, weir_y + 2.0, weir_w + 8.0, 14.0), Color(0.17, 0.21, 0.23))
		b.rect(Rect2(water.position.x - 4.0, weir_y + 4.0, weir_w + 8.0, 5.0), Color(0.34, 0.40, 0.43))
		var rx_rib := water.position.x + 18.0
		while rx_rib < water.position.x + weir_w - 12.0:
			b.line(Vector2(rx_rib, weir_y + 1.0), Vector2(rx_rib, weir_y + 17.0), Color(0.11, 0.14, 0.16, 0.80), 2.0)
			rx_rib += 32.0
		# Downstream white cascading overflow foam and aerated water trails
		b.rect(Rect2(water.position.x + 4.0, weir_y + 18.0, weir_w - 8.0, 7.0), Color(0.92, 0.97, 0.96, 0.72))
		var fx := water.position.x + 14.0
		while fx < water.position.x + weir_w - 16.0:
			var flen := 14.0 + 7.0 * sin(fx * 0.09 + wt * 4.5)
			b.line(Vector2(fx, weir_y + 20.0), Vector2(fx + 2.0, weir_y + 20.0 + flen),
				Color(0.94, 0.98, 0.98, 0.46), 2.4)
			fx += 16.0

	# 9. Mid-walk road bridge shadow (-2560) and cable-stayed Pont de Can Peixauet shadow at GATE_Y
	if absf(-2560.0 - (vt + vb) * 0.5) < 480.0:
		var mby := -2560.0
		var mb_w: float = channel.end.x + 260.0 - m.sw_l
		b.rect(Rect2(m.sw_l, mby, mb_w, 26.0), Color(0.16, 0.17, 0.20, 0.26))
		b.rect(Rect2(m.sw_l, mby, mb_w, 4.0), Color(0.12, 0.13, 0.16, 0.34))
		b.rect(Rect2(m.sw_l, mby + 22.0, mb_w, 4.0), Color(0.12, 0.13, 0.16, 0.34))
		b.rect(Rect2(channel.position.x - 10.0, mby - 4.0, 20.0, 34.0), Color(0.52, 0.50, 0.46))

	if vb > m.GATE_Y - 30.0 and vt < m.GATE_Y + 110.0:
		var br_y := float(m.GATE_Y) - 2.0
		var br_w: float = channel.end.x + 260.0 - m.sw_l
		b.rect(Rect2(m.sw_l, br_y + 4.0, channel.end.x - m.sw_l, 22.0), Color(0.2, 0.2, 0.22, 0.35))
		b.rect(Rect2(m.sw_l, br_y, br_w, 30.0), Color(0.16, 0.17, 0.20, 0.28))
		b.rect(Rect2(m.sw_l, br_y, br_w, 4.0), Color(0.10, 0.11, 0.14, 0.38))
		b.rect(Rect2(m.sw_l, br_y + 26.0, br_w, 4.0), Color(0.10, 0.11, 0.14, 0.38))
		# Cable-stayed pylon base on the river bank and radiating stay-cable shadows
		var pylon := Vector2(water.position.x - 16.0, br_y + 15.0)
		b.rect(Rect2(pylon.x - 11.0, pylon.y - 16.0, 22.0, 32.0), Color(0.58, 0.56, 0.52))
		b.rect(Rect2(pylon.x - 8.0, pylon.y - 13.0, 16.0, 26.0), Color(0.72, 0.70, 0.66))
		for ci in range(7):
			var target_x: float = m.sw_l + 40.0 + float(ci) * 135.0
			b.line(pylon + Vector2(0.0, -12.0), Vector2(target_x, br_y + 26.0),
				Color(0.12, 0.13, 0.16, 0.24), 1.8)

	# 10. SAHBE electronic entrance information sign (OBERT / ALERTA RIU),
	# tucked east of the cycle lane, below the walk's name and gloss
	var board := Rect2(m.sw_l + 114.0, 118.0, 46.0, 28.0)
	if board.end.y > vt - 20.0 and board.position.y < vb + 20.0:
		var open := String(m.chase_phase) == ""
		# Support posts, solar panel, and dark steel display cabinet
		for px: float in [board.position.x + 6.0, board.end.x - 6.0]:
			b.circle(Vector2(px + 2.0, board.end.y + 5.0), 4.5, Color(0.06, 0.07, 0.08, 0.25))
			b.rect(Rect2(px - 2.5, board.end.y - 1.0, 5.0, 7.0), Color(0.38, 0.40, 0.42))
		b.rect(Rect2(board.position.x + 9.0, board.position.y - 9.0, 28.0, 5.0), Color(0.16, 0.26, 0.38))
		b.rect(board.grow(3.5), Color(0.20, 0.22, 0.24))
		b.rect(Rect2(board.position.x - 2.0, board.position.y - 2.0, board.size.x + 4.0, 4.0), Color(0.16, 0.44, 0.26))
		var status_col := Color(0.2, 0.55, 0.28) if open else Color(0.7, 0.16, 0.14)
		b.rect(board, status_col)
		b.rect(board.grow(-2.5), Color(0.10, 0.13, 0.12) if open else Color(0.18, 0.08, 0.08))
		var led_col := Color(0.34, 0.92, 0.48) if open else Color(1.0, 0.30, 0.24)
		b.rect(Rect2(board.position.x + 5.0, board.position.y + 5.0, 36.0, 5.0), led_col)
		b.rect(Rect2(board.position.x + 5.0, board.position.y + 13.0, 24.0, 3.0), led_col.darkened(0.15))
		b.rect(Rect2(board.position.x + 5.0, board.position.y + 19.0, 30.0, 3.0), led_col.darkened(0.15))
		# Twin top corner warning beacons (flash amber when closed)
		for bx: float in [board.position.x + 3.0, board.end.x - 3.0]:
			var bp := Vector2(bx, board.position.y - 4.5)
			b.circle(bp, 2.8, Color(1.0, 0.72, 0.16) if not open else Color(0.58, 0.42, 0.14))
			if not open:
				var _ml := Engine.get_main_loop()
				var _gm: Node = _ml.root.get_node_or_null("Game") if _ml != null and _ml is SceneTree else null
				var flashes_on := true if _gm == null else bool(_gm.flashes)
				var pulse := 0.52 if not flashes_on else 0.38 + 0.32 * absf(sin(wt * 10.0))
				b.circle(bp, 7.0, Color(1.0, 0.60, 0.12, pulse))
	if m.ornitoleg != null:
		m.ornitoleg.draw(m, b, vt, vb)
	b.flush(m._wc)


# --- main's walk hooks (main.WALK_MODULES) ---------------------------------------

# Center the gate mouth and its south freedom-fence collider on the riverside path
static func build_layer(m: Node2D) -> void:
	m.gate_l = m.sw_l
	m.gate_r = m.sw_r
	var fy := float(m.GATE_Y) - 30.0
	for ch: Node in m.get_children():
		if not (ch is StaticBody2D):
			continue
		for cs: Node in ch.get_children():
			if cs is CollisionShape2D and (cs as CollisionShape2D).shape is SegmentShape2D:
				var seg := (cs as CollisionShape2D).shape as SegmentShape2D
				if is_equal_approx(seg.a.y, fy) and is_equal_approx(seg.b.y, fy):
					if seg.a.x < m.walk_cx:
						seg.b.x = m.gate_l - 20.0
					else:
						seg.a.x = m.gate_r + 20.0


# West flood wall & upper embankment, terminated cleanly at the Pont de Can Peixauet abutment
static func draw_edge_layer(m: Node2D, c: Object, vt: float, vb: float) -> void:
	var base := Color(0.58, 0.56, 0.52)
	var far := 520.0
	var face := 22.0
	var cast := 38.0
	var slice := 55.0
	var gate_top := float(m.GATE_Y) - 30.0
	var sy := floorf((vt - 320.0) / slice) * slice
	while sy < vb + 320.0:
		var sy1 := sy + slice
		if sy1 > gate_top:
			var y0 := maxf(sy, gate_top)
			var h := sy1 - y0
			c.draw_rect(Rect2(m.sw_l - far, y0, far, h), base)
			for i in range(7):
				var t := float(i) / 6.0
				var lo := -face + face * t
				c.draw_rect(Rect2(m.sw_l + lo, y0, face / 6.0 + 1.0, h), base.darkened(0.52 - t * 0.34))
			c.draw_rect(Rect2(m.sw_l - face - 5.0, y0, 5.0, h), base.lightened(0.30))
			for i in range(6):
				var t := float(i) / 5.0
				c.draw_rect(Rect2(m.sw_l, y0, cast * (1.0 - t * 0.82), h), Color(0.05, 0.04, 0.07, 0.055))
		sy = sy1

	var mod := 220.0
	var depth := 78.0
	var inset := 27.0
	var inner: float = m.sw_l - inset
	var x0: float = inner - depth
	var y := floorf((vt - mod) / mod) * mod
	while y < vb + mod:
		var y1 := y + mod
		if y1 > gate_top:
			var k := int(absf(y) / mod)
			if y >= gate_top:
				draw_wall_module(m, c, Rect2(x0, y, depth, mod), k, inner)
			else:
				var h := y1 - gate_top
				c.draw_rect(Rect2(m.sw_l - far, gate_top, inner - (m.sw_l - far), h), Color(0.30, 0.44, 0.27))
				# the gate's lawn feathers south into the paving behind the berm
				if c is ShapeBatch:
					var fade := PackedVector2Array()
					for yy: float in [y1, y1 + 140.0]:
						fade.append(Vector2(m.sw_l - far, yy))
						fade.append(Vector2(x0 - 160.0, yy))
					(c as ShapeBatch).band(fade, 2, Color(0.30, 0.44, 0.27), PackedFloat32Array([1.0, 0.0]))
				c.draw_rect(Rect2(x0 + 10.0, gate_top, 44.0, h), Color(0.46, 0.45, 0.42))
				c.draw_line(Vector2(x0 + 10.0, gate_top), Vector2(x0 + 10.0, y1), Color(0.62, 0.60, 0.56), 2.0)
				c.draw_line(Vector2(x0 + 54.0, gate_top), Vector2(x0 + 54.0, y1), Color(0.62, 0.60, 0.56), 2.0)
				var dy := gate_top + 12.0
				while dy < y1 - 8.0:
					c.draw_line(Vector2(x0 + 32.0, dy), Vector2(x0 + 32.0, minf(dy + 18.0, y1 - 4.0)),
						Color(0.90, 0.88, 0.80, 0.55), 1.8)
					dy += 36.0
				var cap_x := inner - 14.0
				c.draw_rect(Rect2(cap_x, gate_top, 19.0, h), Color(0.66, 0.64, 0.59))
				c.draw_rect(Rect2(cap_x, gate_top, 4.0, h), Color(0.76, 0.74, 0.69))
				c.draw_line(Vector2(cap_x + 3.0, gate_top), Vector2(cap_x + 3.0, y1), Color(0.42, 0.46, 0.48), 2.2)
		y = y1

	# Bridge deck shadows carried across the west embankment and flood wall
	if vt <= -2520.0 and vb >= -2570.0:
		var mby := -2560.0
		var b_l: float = m.sw_l - far
		var b_w: float = m.sw_l - b_l
		c.draw_rect(Rect2(b_l, mby, b_w, 26.0), Color(0.16, 0.17, 0.20, 0.26))
		c.draw_rect(Rect2(b_l, mby, b_w, 4.0), Color(0.12, 0.13, 0.16, 0.34))
		c.draw_rect(Rect2(b_l, mby + 22.0, b_w, 4.0), Color(0.12, 0.13, 0.16, 0.34))
	if vt <= float(m.GATE_Y) + 40.0 and vb >= float(m.GATE_Y) - 20.0:
		var br_y := float(m.GATE_Y) - 2.0
		var b_l: float = m.sw_l - far
		var b_w: float = m.sw_l - b_l
		c.draw_rect(Rect2(b_l, br_y, b_w, 30.0), Color(0.16, 0.17, 0.20, 0.28))
		c.draw_rect(Rect2(b_l, br_y, b_w, 4.0), Color(0.10, 0.11, 0.14, 0.38))
		c.draw_rect(Rect2(b_l, br_y + 26.0, b_w, 4.0), Color(0.10, 0.11, 0.14, 0.38))

	# Clean north termination of the embankment berm, upper promenade, and flood wall at gate_top
	if vt - 90.0 <= gate_top and vb + 90.0 >= gate_top:
		if c is ShapeBatch:
			var sb := c as ShapeBatch
			var berm_pts := PackedVector2Array()
			for yy: float in [gate_top - 74.0, gate_top - 26.0, gate_top + 4.0]:
				berm_pts.append(Vector2(m.sw_l - far, yy))
				berm_pts.append(Vector2(m.sw_l - 22.0, yy))
			sb.band(berm_pts, 2, Color(0.30, 0.44, 0.27), PackedFloat32Array([0.0, 0.65, 1.0]))
		# Upper promenade kerb return and bollards
		c.draw_rect(Rect2(x0 + 8.0, gate_top - 10.0, 48.0, 12.0), Color(0.56, 0.54, 0.49))
		c.draw_rect(Rect2(x0 + 10.0, gate_top - 10.0, 44.0, 4.0), Color(0.70, 0.68, 0.62))
		for bx: float in [x0 + 21.0, x0 + 43.0]:
			c.draw_circle(Vector2(bx, gate_top - 4.0), 3.6, Color(0.28, 0.31, 0.34))
			c.draw_circle(Vector2(bx - 0.8, gate_top - 4.8), 1.6, Color(0.56, 0.60, 0.64))
		# Flood-wall terminal concrete abutment pier and railing end post
		var pier := Rect2(inner - 16.0, gate_top - 4.0, 45.0, 20.0)
		c.draw_rect(Rect2(pier.position + Vector2(3.0, 4.0), pier.size), Color(0.05, 0.04, 0.07, 0.22))
		c.draw_rect(pier, Color(0.62, 0.60, 0.55))
		c.draw_rect(Rect2(pier.position.x, pier.position.y, pier.size.x, 4.0), Color(0.76, 0.74, 0.69))
		c.draw_circle(Vector2(inner - 11.0, gate_top + 4.0), 3.4, Color(0.30, 0.33, 0.36))


# Seamless off-leash meadow: feather clearing edges into woodland and match the riverbank lawn
static func draw_clearing(m: Node2D, c: Object, r: Rect2) -> void:
	var b := ShapeBatch.new()
	var meadow := Color(0.30, 0.42, 0.26)
	var bank_grass := Color(0.30, 0.45, 0.28)
	b.rect(r, meadow)
	# Feather west, east, and north edges into the darker woodland surround
	var west_pts := PackedVector2Array()
	for yy: float in [r.position.y - 80.0, r.end.y]:
		for wx: float in [r.position.x - 160.0, r.position.x - 50.0, r.position.x]:
			west_pts.append(Vector2(wx, yy))
	b.band(west_pts, 3, meadow, PackedFloat32Array([1.0, 1.0]), PackedFloat32Array([0.0, 0.50, 1.0]))
	var east_pts := PackedVector2Array()
	for yy: float in [r.position.y - 80.0, r.end.y]:
		for ex: float in [r.end.x, r.end.x + 50.0, r.end.x + 160.0]:
			east_pts.append(Vector2(ex, yy))
	b.band(east_pts, 3, meadow, PackedFloat32Array([1.0, 1.0]), PackedFloat32Array([1.0, 0.50, 0.0]))
	var north_pts := PackedVector2Array()
	for ny: float in [r.position.y - 120.0, r.position.y - 35.0, r.position.y]:
		north_pts.append(Vector2(r.position.x - 20.0, ny))
		north_pts.append(Vector2(r.end.x + 20.0, ny))
	b.band(north_pts, 2, meadow, PackedFloat32Array([0.0, 0.55, 1.0]))
	# South meadow collar matching the riverbank lawn across the river headwall and east edge
	var south_pts := PackedVector2Array()
	for sy: float in [r.end.y - 76.0, r.end.y - 24.0, r.end.y + 28.0]:
		for sx: float in [m.sw_l, 1240.0, 1380.0, 1540.0]:
			south_pts.append(Vector2(sx, sy))
	b.band(south_pts, 4, bank_grass, PackedFloat32Array([0.0, 0.72, 1.0]), PackedFloat32Array([1.0, 1.0, 0.55, 0.0]))
	b.flush(c)
	m._worn_patch(c, r.get_center(), 170.0, Color(0.40, 0.36, 0.26, 0.55))
	m._draw_freedom_benches(c, r, Color(0.42, 0.33, 0.22))
	m._freedom_sign(c, r, m.gate_text, I18n.t("w_the_clearing_off_leash"))


# Threshold where the concrete river path wears into the meadow clearing
static func draw_threshold(m: Node2D, b: ShapeBatch) -> void:
	var y := float(m.GATE_Y) - 40.0
	var ge: Vector2 = m.walk_edges(float(m.GATE_Y) - 16.0)
	var gl := maxf(float(m.gate_l), ge.x)
	var gr := minf(float(m.gate_r), ge.y)
	var mx := (gl + gr) * 0.5
	var gap := 156.0
	var hw := gap * 0.5

	# Tapered worn concrete-to-earth desire path through the gate opening
	var earth := Color(0.54, 0.50, 0.42)
	var path_pts := PackedVector2Array([
		Vector2(mx - hw - 18.0, y + 14.0), Vector2(mx + hw + 18.0, y + 14.0),
		Vector2(mx - hw, y - 4.0), Vector2(mx + hw, y - 4.0),
		Vector2(mx - hw * 0.78, y - 76.0), Vector2(mx + hw * 0.78, y - 76.0),
		Vector2(mx - hw * 0.48, y - 168.0), Vector2(mx + hw * 0.48, y - 168.0),
	])
	b.band(path_pts, 2, earth, PackedFloat32Array([0.0, 0.76, 0.48, 0.0]))
	b.glow(Vector2(mx, y - 22.0), hw * 0.92, Color(0.62, 0.58, 0.48, 0.52), 0.35)
	b.glow(Vector2(mx, y - 82.0), hw * 0.85, Color(0.48, 0.43, 0.33, 0.36), 0.25)
	for pi in range(9):
		var ph: float = m._cell01(float(pi) * 19.0, 53.0)
		var side := -1.0 if pi % 2 == 0 else 1.0
		var py := y - 12.0 - float(pi) * 14.0
		var px := mx + side * (hw * (0.48 - float(pi) * 0.03) + (ph - 0.5) * 22.0)
		Stones.stone(b, Vector2(px, py), 2.2 + ph * 2.0, Color(0.56, 0.53, 0.47, 0.85), ph)

	# Dressed granite threshold kerbs flanking the worn opening, with meadow grass over the rim
	var sh := Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.24)
	var kerb_col := Color(0.52, 0.50, 0.45)
	for seg: Vector2 in [Vector2(ge.x, mx - hw), Vector2(mx + hw, ge.y)]:
		if seg.y - seg.x < 4.0:
			continue
		b.rect(Rect2(seg.x, y - 2.0, seg.y - seg.x, 10.0), sh)
		b.rect(Rect2(seg.x, y - 5.0, seg.y - seg.x, 10.0), kerb_col)
		b.rect(Rect2(seg.x, y - 5.0, seg.y - seg.x, 2.5), kerb_col.lightened(0.24))
		var jx := seg.x + 28.0
		while jx < seg.y - 4.0:
			b.line(Vector2(jx, y - 5.0), Vector2(jx, y + 5.0), kerb_col.darkened(0.24), 1.3)
			jx += 28.0
		var tx := seg.x + 6.0
		while tx < seg.y - 6.0:
			var h: float = m._cell01(tx, 67.0)
			if h > 0.28:
				var gc := Color(0.28, 0.43, 0.25) if h > 0.6 else Color(0.34, 0.50, 0.29)
				b.line(Vector2(tx, y - 3.0), Vector2(tx - 3.0, y + 4.5 + h * 5.0), gc, 2.0)
				b.line(Vector2(tx, y - 3.0), Vector2(tx + 3.0, y + 3.5 + h * 4.5), gc, 1.8)
			tx += 10.0 + h * 7.0

	# Grass tufts knitting the riverbank verge into the north meadow
	var rx := ge.y + 12.0
	while rx < 1260.0:
		var rh: float = m._cell01(rx, 91.0)
		if rh > 0.35:
			var gy := y - 4.0 + (rh - 0.5) * 14.0
			var gc := Color(0.27, 0.42, 0.25)
			b.line(Vector2(rx, gy), Vector2(rx - 3.0, gy - 5.0), gc, 1.8)
			b.line(Vector2(rx, gy), Vector2(rx + 3.0, gy - 4.0), gc, 1.6)
		rx += 22.0 + rh * 12.0


# the street's lamps, less the wall lamps it would hang on the east building
# line: here that is the river's shingle, with no wall to hang one on
static func night_lights(m: Node2D) -> Array[Vector3]:
	var out: Array[Vector3] = []
	for l: Vector3 in m.street_night_lights():
		if l.z < m.NIGHT_LAMP_R and l.x > m.walk_cx:
			continue
		out.append(l)
	return out


# the river, over the walkway and the lawns beside it
static func draw_over_walkway(m: Node2D, _wc: ShapeBatch, vt: float, vb: float) -> void:
	draw_river(m, vt, vb)


# the waymarker posts, where other walks have hydrants
static func draw_bollard(m: Node2D, wc: Object, h: Dictionary) -> void:
	draw_post(m, wc, h)
