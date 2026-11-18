class_name Neteja
extends RefCounted

# WALK: LA NETEJA (the street cleaning, at dawn). Its drawing as static
# functions over main's state (main.WALK_MODULES): the low sun down the cross
# streets and the wet setts, and the frontage modules along both sides - El
# Gòtic's roofs (world/gotic.gd) over shops with their shutters still down.
# The sweeper, the chase home and the suds round the bollards stay in main.

# its off-leash area's worn patch is soft at the edge (main.soft_wear)
const SOFT_WEAR := true
# the hooks main calls on this walk, held to it by tests/test_walk_hooks.gd
const HOOKS := ["draw_grove", "draw_live", "draw_threshold", "night_lights", "surface"]


const ShapeBatch := preload("res://systems/shape_batch.gd")
const LevelBuild := preload("res://world/level_build.gd")
const Gotic := preload("res://world/gotic.gd")
const Surfaces := preload("res://world/surfaces.gd")

# a sun band's cross-section: four rows down its width (as fractions of
# SUN_W), clear at both edges and brightest a little above the middle
const SUN_W := 90.0
const SUN_ROWS := [0.0, 0.38, 0.6, 1.0]
static var SUN_ALPHA := PackedFloat32Array([0.0, 1.0, 0.8, 0.0])
# a wet streak's columns: clear, the middle, clear
static var WET_COLS := PackedFloat32Array([0.0, 1.0, 0.0])
# feathered doorway light from an open shop: soft top/bottom and fading streetward
static var SHOP_ROWS := PackedFloat32Array([0.0, 1.0, 1.0, 0.0])
static var SHOP_COLS := PackedFloat32Array([1.0, 0.46, 0.0])
# wall lamps on the plaça's house fronts, down each side as fractions of its
# depth. Under main.NIGHT_LAMP_R, so the light layer draws each its bracket
const PLACA_LAMPS: Array[float] = [0.25, 0.6]
const PLACA_LAMP_R := 140.0
# how far in from the plaça's edge its house fronts stand
const PLACA_FRONT := 30.0


static func _shop_span(m: Node2D, mod_y: float, h: int) -> Vector2:
	var s0 := mod_y + 26.0 + float((h >> 3) % 3) * 8.0
	var s1 := mod_y + 220.0 - 46.0
	var top_lim: float = m.GATE_Y - 30.0
	if mod_y < top_lim:
		s0 = maxf(s0, top_lim + 52.0)
	var bot_lim: float = float(m.START_Y) + 26.0
	if mod_y + 220.0 > bot_lim:
		s1 = minf(s1, bot_lim)
		s0 = minf(s0, s1 - 26.0)
	return Vector2(s0, s1)


static func _draw_street(m: Node2D, vt: float, vb: float) -> void:
	var b := ShapeBatch.new()
	var gate_lim: float = m.GATE_Y - 28.0
	var south_lim: float = float(m.START_Y) + 26.0
	# the low sun down the cross streets: long warm bands lying across the
	# setts, brightest along the middle and fading to nothing at both edges
	var sy := floorf((vt - 400.0) / 520.0) * 520.0
	var sun := PackedVector2Array()
	sun.resize(8)
	while sy < vb + 400.0:
		if sy - 120.0 >= gate_lim and sy - 120.0 <= south_lim:
			var e: Vector2 = m.walk_edges(sy)
			for r in range(4):
				var off: float = SUN_ROWS[r] * SUN_W
				sun[r * 2] = Vector2(e.x, minf(sy + off, south_lim))
				sun[r * 2 + 1] = Vector2(e.y, clampf(sy - 120.0 + off, gate_lim, south_lim))
			b.band(sun, 2, Color(1.0, 0.76, 0.52, 0.24), SUN_ALPHA)
		sy += 520.0

	# wall lantern halos aligned to each module's bracket and soft warm light
	# spilling out from open bakeries onto the wet setts
	var fan := PackedVector2Array()
	fan.resize(12)
	var mod_y := floorf((vt - 280.0) / 220.0) * 220.0
	while mod_y < vb + 220.0:
		if mod_y + 220.0 > m.GATE_Y - 30.0 and mod_y < south_lim:
			for side in [-1.0, 1.0]:
				var mod_k := int(absf(mod_y) / 220.0) + (0 if side < 0.0 else 7)
				var mod_h := Gotic.roof_hash(mod_k, int(mod_y))
				var sp := _shop_span(m, mod_y, mod_h)
				var s0 := sp.x
				var s1 := sp.y
				var ly := s0 - 22.0
				if ly >= m.GATE_Y - 12.0 and ly <= float(m.START_Y) + 12.0:
					var le: Vector2 = m.walk_edges(ly)
					var lx: float = le.x + 6.0 if side < 0.0 else le.y - 6.0
					b.glow(Vector2(lx, ly), 40.0, Color(1.0, 0.80, 0.48, 0.13))
				if open_shop(mod_y, side) and s1 > s0 + 12.0:
					var down := lerpf(s0, s1, 0.42)
					var mid_y := (down + s1) * 0.5
					var shop_e: Vector2 = m.walk_edges(mid_y)
					var shop_x: float = shop_e.x if side < 0.0 else shop_e.y
					var dir: float = 1.0 if side < 0.0 else -1.0
					var ys0 := [down - 6.0, down + 4.0, s1 - 4.0, s1 + 6.0]
					var ys1 := [down - 14.0, down - 1.0, s1 + 1.0, s1 + 14.0]
					var ys2 := [down - 26.0, down - 6.0, s1 + 6.0, s1 + 26.0]
					for row_i in range(4):
						fan[row_i * 3] = Vector2(shop_x, ys0[row_i])
						fan[row_i * 3 + 1] = Vector2(shop_x + dir * 28.0, ys1[row_i])
						fan[row_i * 3 + 2] = Vector2(shop_x + dir * 88.0, ys2[row_i])
					b.band(fan, 3, Color(1.0, 0.72, 0.36, 0.28), SHOP_ROWS, SHOP_COLS)
					b.glow(Vector2(shop_x + dir * 8.0, mid_y), 44.0, Color(1.0, 0.76, 0.40, 0.14))
		mod_y += 220.0

	# curbside storm drain grates (embornals) along the kerb line with runoff channels and soap suds
	var gy := floorf((vt - 60.0) / 140.0) * 140.0
	while gy < vb + 60.0:
		if gy >= m.GATE_Y + 25.0 and gy <= float(m.START_Y) - 25.0:
			var ge: Vector2 = m.walk_edges(gy)
			for side in [-1.0, 1.0]:
				var gx: float = ge.x + 6.0 if side < 0.0 else ge.y - 6.0
				var gp := Vector2(gx, gy)
				# cast iron frame & void
				b.rect(Rect2(gp.x - 6.0, gp.y - 12.0, 12.0, 24.0), Color(0.18, 0.19, 0.22))
				b.rect(Rect2(gp.x - 4.5, gp.y - 10.0, 9.0, 20.0), Color(0.06, 0.07, 0.09))
				# slotted cast iron grate bars
				for bi in range(5):
					var bar_y := gp.y - 8.0 + float(bi) * 4.0
					b.line(Vector2(gp.x - 4.5, bar_y), Vector2(gp.x + 4.5, bar_y), Color(0.28, 0.30, 0.34), 1.6)
					b.line(Vector2(gp.x - 4.5, bar_y + 1.0), Vector2(gp.x + 4.5, bar_y + 1.0), Color(0.42, 0.44, 0.48, 0.45), 0.8)
				# wet runoff channel leading to drain
				var street_in: float = gx + (16.0 if side < 0.0 else -16.0)
				b.line(Vector2(street_in, gy + 14.0), Vector2(gx, gy), Color(0.16, 0.20, 0.25, 0.22), 4.0)
				# soap suds (bromera) trapped in grate corners
				for sidx in range(4):
					var hval := int(absf(gy * 13.0 + float(sidx) * 37.0 + side * 19.0))
					var srad: float = 1.4 + float(hval % 3) * 0.8
					var sox: float = float((hval % 7) - 3) * 1.5
					var soy: float = (12.0 if sidx < 2 else -12.0) + float((hval % 5) - 2)
					var sp := gp + Vector2(sox, soy)
					b.circle(sp, srad + 0.8, Color(0.80, 0.90, 0.98, 0.55))
					b.circle(sp, srad, Color(0.96, 0.98, 1.0, 0.85))
					b.circle(sp + Vector2(-0.4, -0.4), srad * 0.4, Color(1.0, 1.0, 1.0, 0.95))
		gy += 140.0

	# the water truck's wet streaks down the street: a darker sheen that
	# feathers out at its edges and wanders a little, the dawn on one edge
	var y := floorf((vt - 40.0) / 220.0) * 220.0
	while y < vb + 40.0:
		if y + 220.0 > m.GATE_Y - 24.0 and y < float(m.START_Y) + 8.0:
			_wet_block(m, y).append_to(b)
		y += 220.0

	# the dumpsters: Cuidem Barcelona selective recycling stations (envasos, paper, orgànica, resta, vidre),
	# foot-pedal mechanisms, municipal branding, flattened cardboard stacks and bottle crates, and curbside soap suds
	var dump_list: Array[Vector2] = LevelBuild.neteja_dumpsters(m)
	for d_idx in range(dump_list.size()):
		var d: Vector2 = dump_list[d_idx]
		if d.y < vt - 80.0 or d.y > vb + 80.0:
			continue
		var sz: Vector2 = LevelBuild.NETEJA_DUMPSTER
		var r := Rect2(d - sz * 0.5, sz)
		b.rect(Rect2(r.position + Shade.light * 12.0, r.size), Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.25))

		# Cuidem Barcelona selective recycling category:
		# 0: Envasos (Yellow), 1: Paper (Blue), 2: Orgànica (Brown), 3: Resta (Grey), 4: Vidre (Green)
		var cat := d_idx % 5
		var lid_col := Color(0.92, 0.76, 0.14)
		match cat:
			1: lid_col = Color(0.18, 0.46, 0.82)
			2: lid_col = Color(0.55, 0.36, 0.22)
			3: lid_col = Color(0.46, 0.48, 0.50)
			4: lid_col = Color(0.20, 0.52, 0.32)
		var body_col := Color(0.25, 0.27, 0.29)

		# the castors with mounting brackets
		for cx: float in [r.position.x + 5.0, r.end.x - 5.0]:
			for cy: float in [r.position.y + 6.0, r.end.y - 6.0]:
				b.rect(Rect2(cx - 3.5, cy, 7.0, 5.0), Color(0.16, 0.17, 0.18))
				b.circle(Vector2(cx, cy) + Vector2(0.0, 3.0), 5.0, Color(0.08, 0.08, 0.09))
				b.circle(Vector2(cx, cy) + Vector2(0.0, 3.0), 1.8, Color(0.38, 0.40, 0.44))

		# dumpster body & outer rim
		b.rect(r, body_col.darkened(0.28))
		b.rect(r.grow(-2.0), body_col)

		# municipal identification stripe across the body
		var stripe_y := d.y - 2.0
		b.rect(Rect2(r.position.x + 3.0, stripe_y, sz.x - 6.0, 4.0), Color(0.90, 0.92, 0.94, 0.88))
		b.rect(Rect2(d.x - 6.0, stripe_y + 0.5, 12.0, 3.0), Color(0.22, 0.24, 0.26))
		b.rect(Rect2(d.x - 2.0, stripe_y + 1.0, 4.0, 2.0), lid_col)

		# the two hinged lids, color-coded with ribs and grab handles
		for half in range(2):
			var lr := Rect2(r.position.x + 3.0, r.position.y + 3.0 + float(half) * (sz.y * 0.5 - 1.0), sz.x - 6.0, sz.y * 0.5 - 5.0)
			var lc := lid_col.lightened(0.10 if half == 0 else 0.04)
			b.rect(lr, lc)
			var ry := lr.position.y + 7.0
			while ry < lr.end.y - 3.0:
				b.line(Vector2(lr.position.x + 2.0, ry), Vector2(lr.end.x - 2.0, ry), lc.darkened(0.16), 1.5)
				b.line(Vector2(lr.position.x + 2.0, ry + 1.5), Vector2(lr.end.x - 2.0, ry + 1.5), lc.lightened(0.14), 1.0)
				ry += 9.0
			var hx: float = lr.end.x - 5.0 if d.x < m.walk_cx else lr.position.x + 3.0
			b.rect(Rect2(hx, lr.get_center().y - 6.0, 2.0, 12.0), Color(0.14, 0.14, 0.15))
		b.line(Vector2(r.position.x, d.y), Vector2(r.end.x, d.y), body_col.darkened(0.35), 2.0)

		# the handlebars at each end
		for ey: float in [r.position.y - 3.0, r.end.y + 3.0]:
			b.line(Vector2(r.position.x + 8.0, ey), Vector2(r.end.x - 8.0, ey), Color(0.20, 0.20, 0.22), 3.0)

		# foot-pedal bar (pedal de peu) along the street-facing side
		var is_west: bool = d.x < m.walk_cx
		var pedal_x: float = r.end.x + 2.5 if is_west else r.position.x - 2.5
		b.line(Vector2(pedal_x, d.y - 20.0), Vector2(pedal_x, d.y + 20.0), Color(0.20, 0.22, 0.24), 2.8)
		b.line(Vector2(pedal_x, d.y - 14.0), Vector2(r.end.x if is_west else r.position.x, d.y - 14.0), Color(0.30, 0.32, 0.34), 2.0)
		b.line(Vector2(pedal_x, d.y + 14.0), Vector2(r.end.x if is_west else r.position.x, d.y + 14.0), Color(0.30, 0.32, 0.34), 2.0)

		# the lid at the end lifted on a full bag
		b.circle(d + Vector2(0.0, sz.y * 0.5 + 14.0), 11.0, Color(0.10, 0.10, 0.12))
		b.circle(d + Vector2(-3.0, sz.y * 0.5 + 11.0), 4.0, Color(0.30, 0.30, 0.34))
		b.line(d + Vector2(-2.0, sz.y * 0.5 + 3.0), d + Vector2(3.0, sz.y * 0.5 + 6.0), Color(0.10, 0.10, 0.12), 3.0)

		# category-specific props beside the dumpster
		var prop_x: float = r.position.x - 8.0 if is_west else r.end.x + 8.0
		match cat:
			1:
				var cb_w := 9.0
				var cb_h := 32.0
				var cb_r := Rect2(prop_x - cb_w * 0.5, d.y - cb_h * 0.5, cb_w, cb_h)
				b.rect(cb_r, Color(0.72, 0.56, 0.38))
				b.rect(Rect2(cb_r.position.x + 2.0, cb_r.position.y + 2.0, cb_w - 3.0, cb_h - 4.0), Color(0.80, 0.64, 0.44))
				b.line(Vector2(cb_r.position.x, d.y - 7.0), Vector2(cb_r.end.x, d.y - 7.0), Color(0.90, 0.86, 0.72), 1.2)
				b.line(Vector2(cb_r.position.x, d.y + 7.0), Vector2(cb_r.end.x, d.y + 7.0), Color(0.90, 0.86, 0.72), 1.2)
			4:
				var cr_r := Rect2(prop_x - 7.0, d.y - 9.0, 14.0, 18.0)
				b.rect(cr_r, Color(0.16, 0.42, 0.24))
				b.rect(cr_r.grow(-1.5), Color(0.12, 0.34, 0.18))
				for bx in [-3.5, 3.5]:
					for by in [-4.5, 0.0, 4.5]:
						b.circle(cr_r.get_center() + Vector2(bx, by), 2.0, Color(0.20, 0.56, 0.32))
						b.circle(cr_r.get_center() + Vector2(bx - 0.5, by - 0.5), 0.7, Color(0.85, 0.95, 0.88, 0.90))

		# curbside soap suds / foam bubbles (bromera) pooled around dumpster wheels
		for fx in [r.position.x + 2.0, r.end.x - 2.0]:
			for fy in [r.position.y - 4.0, r.end.y + 4.0]:
				for bi in range(3):
					var boff := Vector2(float(bi * 3 - 3), float((bi * 5) % 4 - 2))
					var brad: float = 2.2 + float((bi + d_idx) % 3) * 0.8
					var bp := Vector2(fx, fy) + boff
					b.circle(bp, brad + 0.6, Color(0.82, 0.92, 0.98, 0.50))
					b.circle(bp, brad, Color(0.95, 0.98, 1.0, 0.85))
					b.circle(bp + Vector2(-0.4, -0.4), brad * 0.4, Color(1.0, 1.0, 1.0, 0.95))

	m._draw_scooters(b, vt, vb)
	if m.escombriaire != null:
		m.escombriaire.draw(m, b, vt, vb)
	b.flush(m._wc)


# La Neteja's shop modules are 220px tall. One bakery, on the west side near
# the top of the street, is always open; the hash opens at most a couple more.
static func open_shop(y: float, side: float) -> bool:
	if int(y) == -660 and side < 0.0:
		return true
	var k := int(absf(y) / 220.0) + (0 if side < 0.0 else 7)
	return Gotic.roof_hash(k, int(y)) % 13 == 2


# One of La Neteja's frontage modules. The old town's roofs, each module two
# lots of its own (pantiles or a terrace, split where the hash says), so no
# two neighbours match; along the kerb the shops' shutter boxes and their
# shutters, still down at this hour - slatted, tagged, a padlocked bottom
# rail - except a bakery's, half up with the light on inside, and the
# low dawn catching the roofs' street edge. The light on the setts is drawn
# with the street (_draw_neteja): this layer sits behind the paving.
static func draw_module(m: Node2D, c: Object, r: Rect2, side: float, k: int, inner_x: float) -> void:
	var north_clip: bool = r.position.y < m.GATE_Y - 30.0
	var mod_y0 := maxf(r.position.y, m.GATE_Y - 30.0)
	var mod_h := r.end.y - mod_y0
	if mod_h <= 12.0:
		return
	var h := Gotic.roof_hash(k, int(r.position.y))
	var cut := mod_h * (0.38 + float(h % 5) * 0.06)
	var block_pad := 4.0 if north_clip else 2.0
	Gotic.draw_block(m, c, Rect2(r.position.x + 2.0, mod_y0 + block_pad, r.size.x - 4.0, cut - block_pad - 2.0), h)
	Gotic.draw_block(m, c, Rect2(r.position.x + 2.0, mod_y0 + cut + 2.0, r.size.x - 4.0, mod_h - cut - 4.0),
		Gotic.roof_hash(h, 7))
	if north_clip:
		# stone parapet coping closing the exposed north roof gable onto Plaça dels Gossos
		c.draw_rect(Rect2(r.position.x, mod_y0, r.size.x, 4.5), Color(0.56, 0.52, 0.46))
		c.draw_rect(Rect2(r.position.x, mod_y0, r.size.x, 1.5), Color(0.70, 0.66, 0.58))
		c.draw_rect(Rect2(r.position.x + 1.0, mod_y0 + 4.5, r.size.x - 2.0, 2.0), Color(0.05, 0.04, 0.07, 0.24))
	# the dawn on the roofs' street edge
	var lx: float = inner_x - (6.0 if side < 0.0 else 0.0)
	c.draw_rect(Rect2(lx, mod_y0, 6.0, mod_h), Color(1.0, 0.74, 0.56, 0.28))
	# the shop front along the kerb: its fascia sign, shutter box and shutter
	var sx: float = inner_x if side < 0.0 else inner_x - 16.0
	var sp := _shop_span(m, r.position.y, h)
	var s0 := sp.x
	var s1 := sp.y
	var bakery := open_shop(r.position.y, side)

	# commercial fascia signage (rètol de botiga) above the shutter housing
	var sign_h := 11.0
	var sign_y := s0 - 6.0 - sign_h
	var sign_r := Rect2(sx, sign_y, 16.0, sign_h)
	var fascia_col := Color(0.18, 0.20, 0.22)
	var emblem_col := Color(0.85, 0.80, 0.65)
	if bakery:
		fascia_col = Color(0.48, 0.24, 0.10)
		emblem_col = Color(1.0, 0.88, 0.52)
	else:
		match (h >> 5) % 4:
			0:
				fascia_col = Color(0.10, 0.28, 0.16)
				emblem_col = Color(0.24, 0.88, 0.45)
			1:
				fascia_col = Color(0.14, 0.22, 0.36)
				emblem_col = Color(0.88, 0.74, 0.32)
			2:
				fascia_col = Color(0.35, 0.12, 0.16)
				emblem_col = Color(0.92, 0.76, 0.40)
			3:
				fascia_col = Color(0.26, 0.22, 0.20)
				emblem_col = Color(0.96, 0.90, 0.78)
	c.draw_rect(sign_r, fascia_col.darkened(0.25))
	c.draw_rect(sign_r.grow(-1.0), fascia_col)
	if not bakery and (h >> 5) % 4 == 0:
		var cx: float = sign_r.get_center().x
		var cy: float = sign_r.get_center().y
		c.draw_line(Vector2(cx - 3.5, cy), Vector2(cx + 3.5, cy), emblem_col, 2.0)
		c.draw_line(Vector2(cx, cy - 3.5), Vector2(cx, cy + 3.5), emblem_col, 2.0)
	else:
		c.draw_line(Vector2(sign_r.position.x + 2.5, sign_r.get_center().y),
			Vector2(sign_r.end.x - 2.5, sign_r.get_center().y), emblem_col, 2.2)

	# wrought-iron wall lantern bracket projecting onto street
	var ly := s0 - 22.0
	var lamp_x: float = inner_x + (side * -4.0)
	c.draw_line(Vector2(sx + 8.0, ly), Vector2(lamp_x, ly - 2.0), Color(0.18, 0.18, 0.20), 2.0)
	c.draw_line(Vector2(lamp_x, ly - 2.0), Vector2(lamp_x, ly + 3.0), Color(0.18, 0.18, 0.20), 2.0)
	c.draw_circle(Vector2(lamp_x, ly + 2.0), 2.6, Color(1.0, 0.82, 0.46))

	c.draw_rect(Rect2(sx, s0 - 6.0, 16.0, 6.0), Color(0.40, 0.41, 0.43))
	var steel := [Color(0.58, 0.59, 0.60), Color(0.52, 0.56, 0.58), Color(0.62, 0.58, 0.52)][(h >> 7) % 3] as Color
	var down := s1 if not bakery else lerpf(s0, s1, 0.42)
	c.draw_rect(Rect2(sx, s0, 16.0, down - s0), steel)
	var sl := s0 + 4.0
	while sl < down - 2.0:
		c.draw_rect(Rect2(sx + 1.0, sl, 14.0, 1.6), steel.darkened(0.22))
		sl += 5.5
	# the bottom rail and the padlocks that hold it
	c.draw_rect(Rect2(sx, down - 5.0, 16.0, 5.0), steel.darkened(0.35))
	for px: float in [sx + 4.5, sx + 11.5]:
		c.draw_rect(Rect2(px - 2.0, down + 0.5, 4.0, 2.5), Color(0.28, 0.28, 0.30))
		c.draw_circle(Vector2(px, down - 2.5), 1.8, Color(0.72, 0.62, 0.28))
		c.draw_circle(Vector2(px, down - 4.5), 1.0, Color(0.85, 0.85, 0.90))
	if bakery:
		# the gap under the half-raised shutter: a lit shop, three rolls on the sill
		c.draw_rect(Rect2(sx, down, 16.0, s1 - down), Color(0.62, 0.36, 0.16))
		c.draw_rect(Rect2(sx + 3.0, down + 2.0, 10.0, maxf(s1 - down - 4.0, 4.0)), Color(1.0, 0.84, 0.50))
		var rolls := mini(3, int((s1 - down) / 9.0))
		for b_roll in range(rolls):
			var ry := down + 7.0 + float(b_roll) * 9.0
			c.draw_circle(Vector2(sx + 8.0, ry), 3.2, Color(0.90, 0.62, 0.28))
			c.draw_circle(Vector2(sx + 6.6, ry - 1.0), 1.3, Color(1.0, 0.88, 0.64))
	else:
		# a tag across it, everyone's different, kept on the shutter
		var tag: Color = [Color(0.86, 0.26, 0.40), Color(0.30, 0.66, 0.86), Color(0.96, 0.80, 0.24),
			Color(0.40, 0.80, 0.46), Color(0.94, 0.94, 0.96)][(h >> 9) % 5]
		var span := down - s0
		var ty := s0 + span * (0.18 + float((h >> 11) % 3) * 0.08)
		var tend := minf(ty + span * 0.42, down - 10.0)
		c.draw_line(Vector2(sx + 2.0, ty), Vector2(sx + 13.0, lerpf(ty, tend, 0.55)), tag, 2.6)
		c.draw_line(Vector2(sx + 13.0, lerpf(ty, tend, 0.55)), Vector2(sx + 3.0, tend), tag, 2.6)
	if r.end.y - 24.0 <= float(m.START_Y) + 26.0:
		m._draw_doorway(c, inner_x, side, r.end.y - 24.0, Color(0.46, 0.40, 0.36))


# --- main's walk hooks (main.WALK_MODULES) ---------------------------------------

# the street, up to the gate
static func draw_live(m: Node2D, _wc: ShapeBatch, vt: float, vb: float) -> void:
	_draw_street(m, maxf(vt, m.GATE_Y - 30.0), vb)


# dressed stone soldier course bridging Plaça dels Gossos' flags cleanly to the
# damp street setts with no unjointed gap at the gate corners
static func draw_threshold(m: Node2D, b: ShapeBatch) -> void:
	var thresh_y: float = m.GATE_Y - 40.0
	var edge: Vector2 = m.walk_edges(thresh_y + 2.0)
	var y0 := thresh_y - 8.0
	var y1: float = m.GATE_Y - 29.0
	var th := y1 - y0
	b.rect(Rect2(edge.x, y0, edge.y - edge.x, th), Color(0.36, 0.35, 0.34))
	var stone := Color(0.58, 0.55, 0.50)
	var sx := edge.x
	var idx := 0
	while sx < edge.y - 2.0:
		var bw := minf(24.0, edge.y - sx)
		var tone := stone.lightened(0.03) if idx % 2 == 0 else stone.darkened(0.05)
		b.rect(Rect2(sx + 1.0, y0 + 1.5, bw - 2.0, th - 3.0), tone)
		b.rect(Rect2(sx + 1.0, y0 + 1.5, bw - 2.0, 2.0), tone.lightened(0.14))
		sx += 24.0
		idx += 1
	b.rect(Rect2(edge.x, y1, edge.y - edge.x, 2.5), Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.22))


# the plaça past the gate is paved wall to wall, soft only in its tree pits
static func surface(m: Node2D, p: Vector2) -> int:
	return Surfaces.paved_past_gate(m, p, LevelBuild.placa_trees(m))


# the plaça's trees are broadleaves standing in their pits
static func draw_grove(m: Node2D, c: Object, p: Vector2, _i: int) -> void:
	m.broadleaf_grove(c, p)


# the street's lamps, and wall lamps on the plaça's house fronts
static func night_lights(m: Node2D) -> Array[Vector3]:
	var out: Array[Vector3] = m.street_night_lights()
	out.append_array(m.freedom_side_lamps(PLACA_LAMPS, PLACA_FRONT, PLACA_LAMP_R))
	return out


# The wet streaks in one 220-unit stretch of street, built once: they never
# move, and building their feathered sheens every frame cost the walk about
# 2 ms of each world redraw. Keyed by the walk and the stretch.
static var _wet_cache := {}


static func _wet_fade(m: Node2D, yy: float, lane: float) -> float:
	var north := clampf((yy - (m.GATE_Y - 24.0)) / 56.0, 0.0, 1.0)
	var south := clampf((float(m.START_Y) + 6.0 - yy) / 48.0, 0.0, 1.0)
	var wave := 0.74 + 0.26 * sin(yy * 0.0085 + lane * 4.7)
	return north * south * wave


static func _wet_block(m: Node2D, y: float) -> ShapeBatch:
	var key := Vector2(float(m.get_instance_id() % 1000003), y)
	var blk: ShapeBatch = _wet_cache.get(key)
	if blk != null:
		return blk
	if _wet_cache.size() > 48:
		_wet_cache.clear()
	blk = ShapeBatch.new()
	for lane: float in [0.3, 0.68]:
		var yy := y
		while yy < y + 220.0 - 0.5:
			var y2 := yy + 20.0
			var tf := _wet_fade(m, yy, lane)
			var tf2 := _wet_fade(m, y2, lane)
			if tf <= 0.0 and tf2 <= 0.0:
				yy += 20.0
				continue
			var e: Vector2 = m.walk_edges(yy)
			var x := lerpf(e.x, e.y, lane) + sin(yy * 0.01) * 12.0 + sin(yy * 0.047 + lane * 9.0) * 4.0
			var e2: Vector2 = m.walk_edges(y2)
			var x2 := lerpf(e2.x, e2.y, lane) + sin(y2 * 0.01) * 12.0 + sin(y2 * 0.047 + lane * 9.0) * 4.0
			# the sheen: dark along the middle, feathered to nothing at its
			# sides, and the dawn caught along its left edge
			var wet := PackedVector2Array([Vector2(x - 22.0, yy), Vector2(x, yy), Vector2(x + 22.0, yy),
				Vector2(x2 - 22.0, y2), Vector2(x2, y2), Vector2(x2 + 22.0, y2)])
			blk.band(wet, 3, Color(0.16, 0.18, 0.22, 0.16), PackedFloat32Array([tf, tf2]), WET_COLS)
			var gleam := PackedVector2Array([Vector2(x - 22.0, yy), Vector2(x - 19.0, yy), Vector2(x - 16.0, yy),
				Vector2(x2 - 22.0, y2), Vector2(x2 - 19.0, y2), Vector2(x2 - 16.0, y2)])
			blk.band(gleam, 3, Color(1.0, 0.82, 0.70, 0.10), PackedFloat32Array([tf, tf2]), WET_COLS)
			yy += 20.0
	_wet_cache[key] = blk
	return blk
