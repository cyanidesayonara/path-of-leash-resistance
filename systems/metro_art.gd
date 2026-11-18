extends RefCounted

# EL METRO's pictures (systems/metro.gd holds the walk's layout and logic).
#
# The ground (draw_ground) and the edges (draw_edges) are cached by main and
# never read the animation clock. What moves is draw_live (the turnstile
# bars, the car's doors, the other train and everyone on foot), the
# escalators' treads (draw_escalators) and the overhead: the car's outside,
# a station or the tunnel going by, and the tunnel laid over the platforms
# beyond its shut doors while it rides.
#
# The line roundels are this walk's own: a disc in the line's colour, a
# white ring and a white letter. Line A is orange, line C teal.

const ShapeBatch := preload("res://systems/shape_batch.gd")
const Letters := preload("res://world/sign_letters.gd")
const Panot := preload("res://world/panot.gd")
const Outdoors := preload("res://systems/outdoors.gd")
const NpcFigure := preload("res://entities/npc_figure.gd")
const AnimClock := preload("res://systems/anim_clock.gd")
const Gotic := preload("res://world/gotic.gd")

const M := preload("res://systems/metro.gd")

const SHADOW := Color(0.04, 0.05, 0.07, 0.22)
# the street
const PAVE := Color(0.66, 0.65, 0.63)
const PAVE_WET := Color(0.52, 0.53, 0.55)
const KERB := Color(0.60, 0.59, 0.57)
const KERB_LIT := Color(0.72, 0.71, 0.69)
const ASPHALT := Color(0.25, 0.25, 0.27)
const ASPHALT_WET := Color(0.20, 0.21, 0.24)
const LANE_LINE := Color(0.86, 0.85, 0.80, 0.8)
const ROOF_TONES: Array[Color] = [Color(0.72, 0.52, 0.40), Color(0.66, 0.46, 0.38), Color(0.76, 0.60, 0.48), Color(0.70, 0.68, 0.64)]
const PARAPET := Color(0.86, 0.82, 0.74)
const AWNINGS: Array[Color] = [Color(0.20, 0.45, 0.36), Color(0.72, 0.22, 0.20), Color(0.18, 0.34, 0.56), Color(0.86, 0.62, 0.20)]
const RAILING := Color(0.16, 0.30, 0.24)
const RAILING_LIT := Color(0.30, 0.48, 0.38)
const GRANITE := Color(0.56, 0.55, 0.54)
# underground
const VOID := Color(0.13, 0.12, 0.12)
const VOID_LINE := Color(0.18, 0.17, 0.16)
const STONE := Color(0.17, 0.16, 0.15)
const LINING := Color(0.40, 0.39, 0.37)
const LINING_DARK := Color(0.26, 0.25, 0.24)
const SLAB := Color(0.52, 0.51, 0.48)
const SLAB_LIT := Color(0.64, 0.63, 0.60)
const REBAR := Color(0.34, 0.24, 0.18)
const SKIRT := Color(0.32, 0.32, 0.33)
const STRIP := Color(1.0, 0.97, 0.86)
const WASH := Color(1.0, 0.96, 0.84, 0.16)
const BORDER := Color(0.68, 0.66, 0.62)
const BRASS := Color(0.80, 0.64, 0.30)
const GRILLE := Color(0.22, 0.22, 0.23)
const PARTY := Color(0.30, 0.27, 0.26)
const ZEBRA := Color(0.90, 0.89, 0.85, 0.85)
const SHEEN := Color(0.80, 0.86, 0.94)
const TILE := Color(0.90, 0.90, 0.86)
const TILE_GROUT := Color(0.74, 0.74, 0.70)
const TILE_SHADE := Color(0.80, 0.80, 0.76)
const STEP := Color(0.70, 0.68, 0.64)
const STEP_DEEP := Color(0.60, 0.59, 0.57)
const STEP_EDGE := Color(0.46, 0.45, 0.44)
const NOSING := Color(0.86, 0.72, 0.26)
const TERRAZZO := Color(0.80, 0.78, 0.73)
const TERRAZZO_JOINT := Color(0.66, 0.64, 0.60)
const CHIPS: Array[Color] = [Color(0.56, 0.54, 0.50), Color(0.92, 0.90, 0.86), Color(0.62, 0.48, 0.40), Color(0.44, 0.46, 0.48)]
const PASS_FLOOR := Color(0.70, 0.70, 0.68)
const PASS_JOINT := Color(0.60, 0.60, 0.58)
const PLAT_FLOOR := Color(0.75, 0.74, 0.71)
const PLAT_JOINT := Color(0.64, 0.63, 0.60)
const TACTILE := Color(0.92, 0.74, 0.16)
const TACTILE_DOT := Color(0.80, 0.62, 0.10)
const COPING := Color(0.88, 0.87, 0.83)
const SAFETY := Color(0.96, 0.96, 0.94)
const PIT := Color(0.10, 0.10, 0.10)
const BALLAST := Color(0.20, 0.19, 0.18)
const SLEEPER := Color(0.30, 0.27, 0.24)
const RAIL := Color(0.62, 0.62, 0.64)
const RAIL_LIT := Color(0.84, 0.84, 0.86)
const STEEL := Color(0.70, 0.72, 0.74)
const STEEL_DARK := Color(0.40, 0.42, 0.45)
const STEEL_LIT := Color(0.88, 0.89, 0.90)
const RUBBER := Color(0.10, 0.10, 0.11)
const GLASS := Color(0.62, 0.78, 0.84, 0.35)
const LAMP_POOL := Color(1.0, 0.97, 0.88, 0.10)
# each station its own colour; the line roundels
const PARAIGUES := Color(0.20, 0.42, 0.72)
const SANT_GOS := Color(0.88, 0.64, 0.20)
const LINE_A := Color(0.95, 0.52, 0.14)
const LINE_C := Color(0.10, 0.62, 0.62)
# the car
const CAR_FLOOR := Color(0.34, 0.36, 0.38)
const CAR_DOT := Color(0.40, 0.42, 0.44)
const CAR_SHELL := Color(0.90, 0.91, 0.92)
const CAR_GLASS := Color(0.18, 0.24, 0.30)
const SEAT := Color(0.24, 0.38, 0.60)
const SEAT_LIT := Color(0.32, 0.48, 0.70)
const DOOR := Color(0.78, 0.80, 0.82)
const DOOR_EDGE := Color(0.14, 0.14, 0.15)
const WARN_OFF := Color(0.36, 0.30, 0.16)
const WARN_ON := Color(1.0, 0.76, 0.18)
const TUNNEL := Color(0.09, 0.09, 0.10)
const TUNNEL_WALL := Color(0.16, 0.15, 0.15)
const TUNNEL_LAMP := Color(1.0, 0.86, 0.56)
const CABLE := Color(0.05, 0.05, 0.06, 0.9)
const TRAIN_BODY := Color(0.88, 0.89, 0.90)
const TRAIN_ROOF := Color(0.78, 0.79, 0.80)
const PRINT := Color(0.28, 0.26, 0.24)
const RED := Color(0.82, 0.14, 0.12)
const GREEN := Color(0.30, 0.86, 0.42)


static func _h(k: int) -> float:
	return fmod(absf(sin(float(k) * 12.9898) * 43758.5453), 1.0)


static func letters(c: ShapeBatch, txt: String, at: Vector2, h: float, col: Color, w := 1.6, max_w := INF) -> void:
	var lay: Array = Letters.layout(txt, at, h, max_w)
	for pl: PackedVector2Array in lay[0]:
		for i in range(pl.size()):
			c.circle(pl[i], w * 0.5, col)
			if i > 0:
				c.line(pl[i - 1], pl[i], col, w)


# a line roundel: the disc, a white ring, the letter
static func roundel(c: ShapeBatch, at: Vector2, r: float, col: Color, letter: String) -> void:
	c.circle(at, r + 1.5, Color(0.08, 0.08, 0.09))
	c.circle(at, r, Color(0.98, 0.98, 0.96))
	c.circle(at, r * 0.82, col)
	letters(c, letter, at + Vector2(0.0, r * 0.42), r * 0.86, Color(0.98, 0.98, 0.96), maxf(1.4, r * 0.16))


# a station's name panel: a frame in the station's colour, the name in white,
# the line's roundel at its end
static func name_panel(c: ShapeBatch, centre: Vector2, w: float, name: String, col: Color) -> void:
	var r := Rect2(centre - Vector2(w * 0.5, 13.0), Vector2(w, 26.0))
	c.rect(r.grow(2.0), Color(0.06, 0.06, 0.07))
	c.rect(r, col)
	c.rect(r.grow(-2.5), col.darkened(0.25))
	letters(c, name, centre + Vector2(-8.0, 6.0), 12.0, Color(0.97, 0.97, 0.95), 1.8, w - 34.0)
	roundel(c, Vector2(r.end.x - 13.0, centre.y), 8.5, LINE_A, "A")


# --- the ground inside the walls (cached) ---------------------------------------------

static func draw_ground(m: Node2D, wc: ShapeBatch, ctop: float, vt: float, vb: float) -> void:
	var keep := wc.lod
	wc.lod = true
	var lo: float = maxf(vt - 30.0, maxf(ctop, float(m.GATE_Y) - 40.0))
	var hi: float = minf(vb + 30.0, float(m.START_Y) + 560.0)
	if hi > lo:
		_ground(m, wc, lo, hi)
	wc.lod = keep


static func _clip(lo: float, hi: float, y0: float, y1: float) -> Vector2:
	return Vector2(maxf(lo, y0), minf(hi, y1))


static func _ground(m: Node2D, wc: ShapeBatch, lo: float, hi: float) -> void:
	var wet := Outdoors.tracks_wet(Game.weather)
	for sec: Array in M.SECTIONS:
		var c := _clip(lo, hi, float(sec[0]), float(sec[1]))
		if c.y <= c.x:
			continue
		var x0: float = sec[2]
		var x1: float = sec[3]
		match String(sec[4]):
			"street", "street_b":
				_street(wc, x0, x1, c.x, c.y, wet)
			"stairs":
				_steps(wc, x0, x1, c.x, c.y, M.STAIR_TOP, M.STAIR_FOOT)
				if M.STAIR_RAIL.end.y > c.x and M.STAIR_RAIL.position.y < c.y:
					_rail(wc, M.STAIR_RAIL)
			"stairs_b":
				_steps(wc, x0, x1, c.x, c.y, M.STREET_B, M.STAIR_B0)
			"hall":
				_terrazzo(wc, x0, x1, c.x, c.y)
				_hall_fittings(wc, c.x, c.y)
			"esc_a":
				_steps(wc, x0, M.BAL_A.position.x, c.x, c.y, M.HALL_Y1, M.PASS_Y0)
				wc.rect(Rect2(M.BAL_A.end.x, c.x, x1 - M.BAL_A.end.x, c.y - c.x), STEEL_DARK)
				_balustrade(wc, M.BAL_A, c.x, c.y)
			"esc_b":
				_steps(wc, M.BAL_B.end.x, x1, c.x, c.y, M.PLAT_B1, M.STAIR_B0)
				wc.rect(Rect2(x0, c.x, M.BAL_B.position.x - x0, c.y - c.x), STEEL_DARK)
				_balustrade(wc, M.BAL_B, c.x, c.y)
			"passage":
				_small_tiles(wc, x0, x1, c.x, c.y)
			"plat_a":
				_platform(wc, x0, x1, c.x, c.y, PARAIGUES)
			"plat_b":
				_platform(wc, x0, x1, c.x, c.y, SANT_GOS)
			"car":
				_car_inside(wc, c.x, c.y)
		# the strip lamps along the walls wash the floor beside them
		match String(sec[4]):
			"hall", "passage":
				_wash(wc, x0, 90.0, c.x, c.y, WASH)
				_wash(wc, x1, -90.0, c.x, c.y, WASH)
			"plat_a", "plat_b":
				_wash(wc, x0, 110.0, c.x, c.y, WASH)
	if wet:
		_footprints(wc, lo, hi)
	_lamp_pools(wc, lo, hi)
	_chamfers(m, wc, lo, hi)


# Where the walls splay from one width to the next, the floor's rectangle
# reaches past them: wall over it, following main.walk_edges, so the floor
# ends exactly at the wall the dog walks along. Tile underground; at street
# level the pavement round the stair mouth, its railing along the edge.
static func _chamfers(m: Node2D, wc: ShapeBatch, lo: float, hi: float) -> void:
	for sec: Array in M.SECTIONS:
		var y0 := maxf(float(sec[0]), lo)
		var y1 := minf(float(sec[1]), hi)
		if y1 <= y0:
			continue
		var x0: float = sec[2]
		var x1: float = sec[3]
		var street := String(sec[4]).begins_with("street")
		var col := PAVE if street else TILE
		if street and Outdoors.tracks_wet(Game.weather):
			col = PAVE_WET
		var left := PackedVector2Array()
		var right := PackedVector2Array()
		var any := false
		var y := y0
		while true:
			var e: Vector2 = m.walk_edges(y)
			if e.x > x0 + 0.5 or e.y < x1 - 0.5:
				any = true
			left.append(Vector2(maxf(e.x, x0), y))
			right.append(Vector2(minf(e.y, x1), y))
			if y >= y1:
				break
			y = minf(y + 8.0, y1)
		if not any:
			continue
		var lp := PackedVector2Array([Vector2(x0 - 1.0, y1), Vector2(x0 - 1.0, y0)])
		lp.append_array(left)
		var rr := right.duplicate()
		rr.reverse()
		var rp := PackedVector2Array([Vector2(x1 + 1.0, y0), Vector2(x1 + 1.0, y1)])
		rp.append_array(rr)
		wc.polygon(lp, col)
		wc.polygon(rp, col)
		if street:
			for i in range(left.size() - 1):
				if left[i].x > x0 + 1.0 or left[i + 1].x > x0 + 1.0:
					wc.line(left[i], left[i + 1], RAILING, 4.0)
				if right[i].x < x1 - 1.0 or right[i + 1].x < x1 - 1.0:
					wc.line(right[i], right[i + 1], RAILING, 4.0)
		else:
			# the splayed wall is tiled like the rest: the frieze and the
			# skirting follow it round
			var fc := _wall_colour(String(sec[4]))
			for i in range(left.size() - 1):
				if left[i].x > x0 + 1.0 or left[i + 1].x > x0 + 1.0:
					wc.line(left[i] - Vector2(16.0, 0.0), left[i + 1] - Vector2(16.0, 0.0), fc, 5.0)
					wc.line(left[i] - Vector2(2.0, 0.0), left[i + 1] - Vector2(2.0, 0.0), SKIRT, 4.0)
				if right[i].x < x1 - 1.0 or right[i + 1].x < x1 - 1.0:
					wc.line(right[i] + Vector2(16.0, 0.0), right[i + 1] + Vector2(16.0, 0.0), fc, 5.0)
					wc.line(right[i] + Vector2(2.0, 0.0), right[i + 1] + Vector2(2.0, 0.0), SKIRT, 4.0)


static func _street(wc: ShapeBatch, x0: float, x1: float, lo: float, hi: float, wet: bool) -> void:
	wc.rect(Rect2(x0, lo, x1 - x0, hi - lo), PAVE_WET if wet else PAVE)
	Panot.flor(wc, x0 + 10.0, x1, lo, hi)
	# the kerb along the road side
	wc.rect(Rect2(x0, lo, 10.0, hi - lo), KERB)
	wc.rect(Rect2(x0, lo, 2.5, hi - lo), KERB_LIT)
	if wet:
		# the paving shining under the rain, in soft streaks, a puddle by
		# the kerb where the gutter backs up
		var y := floorf(lo / 90.0) * 90.0
		while y < hi:
			var k := int(y)
			_streak(wc, Rect2(x0 + 30.0 + _h(k) * 380.0, y - 4.0, 60.0 + _h(k * 3) * 120.0, 12.0), SHEEN, 0.16)
			if _h(k * 7) < 0.35:
				wc.glow(Vector2(x0 + 26.0 + _h(k * 5) * 20.0, y + 40.0), 22.0 + _h(k * 11) * 16.0, Color(0.60, 0.68, 0.80, 0.22), 0.4)
			y += 90.0


# a soft streak of light, feathered on every side (ShapeBatch.band)
static var _sp := PackedVector2Array()
static var _fade3 := PackedFloat32Array([0.0, 1.0, 0.0])
static var _fade2 := PackedFloat32Array([1.0, 0.0])
static var _ones2 := PackedFloat32Array([1.0, 1.0])


static func _streak(b: ShapeBatch, r: Rect2, col: Color, a: float) -> void:
	_sp.resize(9)
	for j in range(3):
		for i in range(3):
			_sp[j * 3 + i] = r.position + Vector2(r.size.x * 0.5 * float(i), r.size.y * 0.5 * float(j))
	b.band(_sp, 3, Color(col.r, col.g, col.b, a), _fade3, _fade3)


# light washed across the floor from a wall's strip lamps: full at the wall
# (x_wall), nothing `reach` px out into the room (negative reaches west)
static func _wash(b: ShapeBatch, x_wall: float, reach: float, y0: float, y1: float, col: Color) -> void:
	_sp.resize(4)
	_sp[0] = Vector2(x_wall, y0)
	_sp[1] = Vector2(x_wall + reach, y0)
	_sp[2] = Vector2(x_wall, y1)
	_sp[3] = Vector2(x_wall + reach, y1)
	b.band(_sp, 2, col, _ones2, _fade2)


# stairs: a tread every 16 px, darker as they go down, the yellow nosing at
# each step's edge; `top` is the street end, `deep` the station end
static func _steps(wc: ShapeBatch, x0: float, x1: float, lo: float, hi: float, top: float, deep: float) -> void:
	var y := floorf(lo / 16.0) * 16.0
	while y < hi:
		var f := clampf((y - top) / (deep - top), 0.0, 1.0)
		wc.rect(Rect2(x0, y, x1 - x0, 16.0), STEP.lerp(STEP_DEEP, f))
		wc.rect(Rect2(x0, y, x1 - x0, 2.0), STEP_EDGE)
		wc.rect(Rect2(x0 + 6.0, y + 2.0, x1 - x0 - 12.0, 1.6), NOSING)
		y += 16.0
	# the low walls the handrails are fixed to
	wc.rect(Rect2(x0, lo, 6.0, hi - lo), STEP_EDGE)
	wc.rect(Rect2(x1 - 6.0, lo, 6.0, hi - lo), STEP_EDGE)
	wc.rect(Rect2(x0 + 2.0, lo, 2.5, hi - lo), STEEL)
	wc.rect(Rect2(x1 - 4.5, lo, 2.5, hi - lo), STEEL)


static func _rail(wc: ShapeBatch, r: Rect2) -> void:
	wc.rect(Rect2(r.position + Vector2(5.0, 5.0), r.size), SHADOW)
	wc.rect(r, STEP_EDGE)
	wc.rect(r.grow(-3.0), STEEL)
	wc.rect(Rect2(r.position.x + 3.0, r.position.y, 2.0, r.size.y), STEEL_LIT)


static func _balustrade(wc: ShapeBatch, r: Rect2, lo: float, hi: float) -> void:
	var y0 := maxf(r.position.y, lo)
	var y1 := minf(r.end.y, hi)
	if y1 <= y0:
		return
	wc.rect(Rect2(r.position.x + 4.0, y0 + 4.0, r.size.x, y1 - y0), SHADOW)
	wc.rect(Rect2(r.position.x, y0, r.size.x, y1 - y0), STEEL_DARK)
	wc.rect(Rect2(r.position.x + 3.0, y0, r.size.x - 6.0, y1 - y0), GLASS)
	# the black rubber handrails along both of its edges, a sheen down each
	wc.rect(Rect2(r.position.x, y0, 4.0, y1 - y0), RUBBER)
	wc.rect(Rect2(r.end.x - 4.0, y0, 4.0, y1 - y0), RUBBER)
	wc.rect(Rect2(r.position.x + 1.0, y0, 1.0, y1 - y0), Color(0.50, 0.52, 0.56, 0.7))
	wc.rect(Rect2(r.end.x - 3.0, y0, 1.0, y1 - y0), Color(0.50, 0.52, 0.56, 0.7))
	# the newels where the handrails turn under, at both ends
	for ny: float in [r.position.y, r.end.y]:
		if ny >= y0 - 1.0 and ny <= y1 + 1.0:
			wc.rect(Rect2(r.position.x - 1.0, ny - 6.0, r.size.x + 2.0, 12.0), STEEL_DARK)
			wc.circle(Vector2(r.position.x + 2.0, ny), 4.0, RUBBER)
			wc.circle(Vector2(r.end.x - 2.0, ny), 4.0, RUBBER)


static func _terrazzo(wc: ShapeBatch, x0: float, x1: float, lo: float, hi: float) -> void:
	wc.rect(Rect2(x0, lo, x1 - x0, hi - lo), TERRAZZO)
	var y := floorf(lo / 80.0) * 80.0
	while y < hi:
		wc.rect(Rect2(x0, y, x1 - x0, 1.4), TERRAZZO_JOINT)
		var x := x0
		while x < x1:
			wc.rect(Rect2(x, y, 1.4, 80.0), TERRAZZO_JOINT)
			x += 80.0
		y += 80.0
	# a darker border poured along the walls, a brass strip dividing it off
	for bx: float in [x0, x1 - 22.0]:
		wc.rect(Rect2(bx, lo, 22.0, hi - lo), BORDER)
	wc.rect(Rect2(x0 + 22.0, lo, 1.6, hi - lo), BRASS)
	wc.rect(Rect2(x1 - 23.6, lo, 1.6, hi - lo), BRASS)
	# the chips set in it
	var cy := floorf(lo / 11.0) * 11.0
	while cy < hi:
		var k := int(cy) * 7
		for j in range(3):
			var cx := x0 + _h(k + j * 31) * (x1 - x0)
			wc.circle(Vector2(cx, cy + _h(k + j) * 10.0), 1.2 + _h(k * 3 + j) * 1.2, CHIPS[(k + j) % CHIPS.size()])
		cy += 11.0
	# the line's roundel inlaid in the floor at the foot of the stairs
	if lo < -900.0 and hi > -1020.0:
		var at := Vector2(M.CX, -960.0)
		wc.circle(at, 52.0, Color(0.30, 0.29, 0.28))
		wc.circle(at, 49.0, Color(0.94, 0.93, 0.90))
		wc.circle(at, 40.0, LINE_A)
		letters(wc, "A", at + Vector2(0.0, 18.0), 36.0, Color(0.96, 0.95, 0.92), 6.0)


static func _hall_fittings(wc: ShapeBatch, lo: float, hi: float) -> void:
	var l: Vector2 = Shade.light
	# the ticket machines along the west wall: three, screen and slot each
	var r := M.MACHINES
	if r.end.y > lo and r.position.y < hi:
		wc.rect(Rect2(r.position + l * 8.0, r.size), SHADOW)
		for i in range(3):
			var mr := Rect2(r.position.x, r.position.y + float(i) * 66.0 + 2.0, r.size.x, 62.0)
			wc.rect(mr, Color(0.22, 0.24, 0.27))
			wc.rect(mr.grow(-2.0), Color(0.86, 0.87, 0.88))
			wc.rect(Rect2(mr.end.x - 14.0, mr.position.y + 10.0, 10.0, 26.0), Color(0.14, 0.30, 0.42))
			wc.rect(Rect2(mr.end.x - 13.0, mr.position.y + 12.0, 8.0, 10.0), Color(0.44, 0.72, 0.88))
			wc.rect(Rect2(mr.position.x + 6.0, mr.position.y + 40.0, 12.0, 4.0), Color(0.10, 0.10, 0.11))
			wc.rect(Rect2(mr.position.x + 3.0, mr.position.y + 2.0, mr.size.x - 6.0, 5.0), LINE_A)
	# the attendant's booth: a glass front onto the hall
	r = M.BOOTH
	if r.end.y > lo and r.position.y < hi:
		wc.rect(Rect2(r.position + l * 10.0, r.size), SHADOW)
		wc.rect(r, Color(0.30, 0.31, 0.33))
		wc.rect(r.grow(-3.0), Color(0.58, 0.60, 0.62))
		wc.rect(Rect2(r.position.x, r.position.y + 10.0, 8.0, r.size.y - 20.0), Color(0.56, 0.74, 0.82, 0.8))
		wc.rect(Rect2(r.position.x + 16.0, r.position.y + 30.0, 30.0, 50.0), Color(0.44, 0.34, 0.26))
		wc.circle(Vector2(r.position.x + 32.0, r.position.y + 100.0), 9.0, Color(0.20, 0.24, 0.40))
		wc.circle(Vector2(r.position.x + 32.0, r.position.y + 98.0), 5.5, Color(0.70, 0.54, 0.42))
	# the turnstiles' cabinets (their bars are live)
	if M.TURN_Y + 40.0 > lo and M.TURN_Y - 40.0 < hi:
		for x: float in M.CAB_XS:
			_cabinet(wc, M.cab_rect(x))
		_cabinet(wc, M.CAB_END)
		# the wide gate's glass flaps, open
		for fx: float in [M.WIDE_GATE.x + 4.0, M.WIDE_GATE.y - 18.0]:
			wc.rect(Rect2(fx, M.TURN_Y - 2.0, 14.0, 4.0), Color(0.62, 0.80, 0.88, 0.7))


static func _cabinet(wc: ShapeBatch, r: Rect2) -> void:
	wc.rect(Rect2(r.position + Shade.light * 7.0, r.size), SHADOW)
	wc.rect(r, STEEL_DARK)
	wc.rect(r.grow(-2.0), STEEL)
	wc.rect(Rect2(r.position.x + 2.0, r.position.y + 2.0, r.size.x - 4.0, 4.0), STEEL_LIT)
	# the card reader, lit
	wc.rect(Rect2(r.position.x + 5.0, r.end.y - 18.0, r.size.x - 10.0, 9.0), Color(0.12, 0.13, 0.15))
	wc.rect(Rect2(r.position.x + 7.0, r.end.y - 16.0, r.size.x - 14.0, 5.0), LINE_A)


static func _small_tiles(wc: ShapeBatch, x0: float, x1: float, lo: float, hi: float) -> void:
	wc.rect(Rect2(x0, lo, x1 - x0, hi - lo), PASS_FLOOR)
	var y := floorf(lo / 24.0) * 24.0
	while y < hi:
		wc.rect(Rect2(x0, y, x1 - x0, 1.0), PASS_JOINT)
		y += 24.0
	var x := x0
	while x < x1:
		wc.rect(Rect2(x, lo, 1.0, hi - lo), PASS_JOINT)
		x += 24.0
	# the worn line down the middle where everyone walks
	wc.rect(Rect2(M.CX - 40.0, lo, 80.0, hi - lo), Color(0.74, 0.74, 0.72, 0.5))
	# drain grilles along the west wall, where the mop water runs
	var gy := floorf(lo / 160.0) * 160.0 + 60.0
	while gy < hi:
		_grille(wc, Rect2(x0 + 8.0, gy, 14.0, 40.0))
		gy += 160.0


# a cast drain grille: its frame, the slots across it
static func _grille(wc: ShapeBatch, r: Rect2) -> void:
	wc.rect(r.grow(1.5), Color(0.48, 0.48, 0.47))
	wc.rect(r, GRILLE)
	if r.size.y > r.size.x:
		var s := r.position.y + 3.0
		while s < r.end.y - 2.0:
			wc.rect(Rect2(r.position.x + 2.0, s, r.size.x - 4.0, 1.6), STEEL_DARK)
			s += 4.0
	else:
		var s := r.position.x + 3.0
		while s < r.end.x - 2.0:
			wc.rect(Rect2(s, r.position.y + 2.0, 1.6, r.size.y - 4.0), STEEL_DARK)
			s += 4.0


static func _platform(wc: ShapeBatch, x0: float, x1: float, lo: float, hi: float, col: Color) -> void:
	wc.rect(Rect2(x0, lo, x1 - x0, hi - lo), PLAT_FLOOR)
	var y := floorf(lo / 48.0) * 48.0
	while y < hi:
		wc.rect(Rect2(x0, y, x1 - x0, 1.2), PLAT_JOINT)
		var x := x0 + (0.0 if int(y / 48.0) % 2 == 0 else 24.0)
		while x < x1 - 40.0:
			wc.rect(Rect2(x, y, 1.2, 48.0), PLAT_JOINT)
			x += 48.0
		y += 48.0
	# the station's colour in a band along the wall, a drain channel inside it
	wc.rect(Rect2(x0, lo, 8.0, hi - lo), col)
	wc.rect(Rect2(x0 + 8.0, lo, 3.0, hi - lo), col.darkened(0.45))
	var gy := floorf(lo / 220.0) * 220.0 + 100.0
	while gy < hi:
		_grille(wc, Rect2(x0 + 12.0, gy, 12.0, 34.0))
		gy += 220.0
	# the platform edge: a white line, the yellow studs, the coping
	wc.rect(Rect2(x1 - 54.0, lo, 3.0, hi - lo), SAFETY)
	wc.rect(Rect2(x1 - 46.0, lo, 30.0, hi - lo), TACTILE)
	var dy := floorf(lo / 8.0) * 8.0
	while dy < hi:
		for j in range(4):
			wc.circle(Vector2(x1 - 42.0 + float(j) * 7.5 + (3.7 if int(dy / 8.0) % 2 == 0 else 0.0), dy + 4.0), 1.5, TACTILE_DOT)
		dy += 8.0
	wc.rect(Rect2(x1 - 16.0, lo, 16.0, hi - lo), COPING)
	wc.rect(Rect2(x1 - 3.0, lo, 3.0, hi - lo), Color(0.56, 0.55, 0.52))


static func _car_inside(wc: ShapeBatch, lo: float, hi: float) -> void:
	var x0 := M.CAR_L
	var x1 := M.CAR_R
	wc.rect(Rect2(x0, lo, x1 - x0, hi - lo), CAR_FLOOR)
	var y := floorf(lo / 10.0) * 10.0
	while y < hi:
		var off := 0.0 if int(y / 10.0) % 2 == 0 else 5.0
		var x := x0 + 4.0 + off
		while x < x1:
			wc.circle(Vector2(x, y), 1.3, CAR_DOT)
			x += 10.0
		y += 10.0
	# the shell: white walls, a run of windows down each side
	for sx: float in [x0 - 16.0, x1]:
		wc.rect(Rect2(sx, lo, 16.0, hi - lo), CAR_SHELL)
		var wy := floorf((lo - M.CAR_N) / 74.0) * 74.0 + M.CAR_N + 12.0
		while wy < hi:
			if wy > M.CAR_N + 6.0 and wy + 52.0 < M.CAR_S - 6.0:
				wc.rect(Rect2(sx + 4.0, wy, 8.0, 52.0), CAR_GLASS)
			wy += 74.0
		wc.rect(Rect2(sx + (12.0 if sx < x0 else 2.0), lo, 2.0, hi - lo), LINE_A)
	# the end walls round the doors
	for r: Rect2 in M.car_walls():
		if r.end.y > lo and r.position.y < hi:
			wc.rect(r.grow(2.0), STEEL_DARK)
			wc.rect(r, CAR_SHELL)
	# the bench seats, and the people sitting on them
	var k := 0
	for r: Rect2 in M.seats():
		if r.end.y < lo or r.position.y > hi:
			k += 6
			continue
		wc.rect(Rect2(r.position + Vector2(3.0, 3.0), r.size), SHADOW)
		wc.rect(r, SEAT.darkened(0.3))
		var sy := r.position.y + 2.0
		var j := 0
		while sy + 34.0 <= r.end.y:
			wc.rect(Rect2(r.position.x + 2.0, sy, r.size.x - 4.0, 32.0), SEAT)
			wc.rect(Rect2(r.position.x + 4.0, sy + 3.0, r.size.x - 8.0, 10.0), SEAT_LIT)
			if _h(k * 7 + j) < 0.55:
				var left := r.position.x < M.CX
				var at := Vector2(r.position.x + r.size.x * (0.62 if left else 0.38), sy + 16.0)
				NpcFigure.person(wc, at, Vector2.RIGHT if left else Vector2.LEFT, 300 + k * 5 + j, -1.0, {"arms": NpcFigure.Arms.READY})
			sy += 36.0
			j += 1
		k += 6
	# the ribbed sill plates in the two end doorways
	for sy: float in [M.CAR_S - 16.0, M.CAR_N + 6.0]:
		if sy + 10.0 > lo and sy < hi:
			wc.rect(Rect2(M.DOOR_L, sy, M.DOOR_R - M.DOOR_L, 10.0), STEEL_DARK)
			var rx := M.DOOR_L + 3.0
			while rx < M.DOOR_R - 2.0:
				wc.rect(Rect2(rx, sy + 1.5, 1.5, 7.0), STEEL)
				rx += 5.0
			wc.rect(Rect2(M.DOOR_L, sy + (8.0 if sy > (M.CAR_S + M.CAR_N) * 0.5 else 0.0), M.DOOR_R - M.DOOR_L, 2.0), NOSING)
	# the grab rail along the ceiling, drawn where its poles stand
	wc.line(Vector2(M.CX - 55.0, maxf(lo, M.CAR_N + 20.0)), Vector2(M.CX - 55.0, minf(hi, M.CAR_S - 20.0)), Color(0.70, 0.72, 0.74, 0.35), 3.0)
	wc.line(Vector2(M.CX + 55.0, maxf(lo, M.CAR_N + 20.0)), Vector2(M.CX + 55.0, minf(hi, M.CAR_S - 20.0)), Color(0.70, 0.72, 0.74, 0.35), 3.0)


# shoe prints walked in off the street, fading the further in they go
static func _footprints(wc: ShapeBatch, lo: float, hi: float) -> void:
	var y0 := maxf(lo, M.TURN_Y + 40.0)
	var y1 := minf(hi, M.STAIR_TOP + 40.0)
	if y1 <= y0:
		return
	for trail in range(7):
		var tx := 520.0 + float(trail) * 40.0 + _h(trail * 9) * 30.0
		var y := floorf(y0 / 30.0) * 30.0
		var side := 0
		while y < y1:
			var depth := clampf((M.STAIR_TOP - y) / (M.STAIR_TOP - M.TURN_Y), 0.0, 1.0)
			var a := 0.32 * (1.0 - depth)
			if a > 0.02 and (trail < 3 or y > -1000.0):
				var px := tx + (7.0 if side % 2 == 0 else -7.0) + sin(y * 0.013 + float(trail)) * 18.0
				var p := Vector2(px, y)
				wc.circle(p, 4.2, Color(PRINT.r, PRINT.g, PRINT.b, a))
				wc.circle(p + Vector2(0.0, 7.0), 3.0, Color(PRINT.r, PRINT.g, PRINT.b, a))
			y += 30.0
			side += 1


# the station's own lamps: soft pools down the middle of every room
static func _lamp_pools(wc: ShapeBatch, lo: float, hi: float) -> void:
	var y := floorf(lo / 180.0) * 180.0 + 90.0
	while y < hi + 180.0:
		var u: float = M.under_at(y)
		if u > 0.3 and y > M.STREET_B and y < M.STAIR_TOP:
			var x := M.CX
			if y < M.STAIR_FOOT - 200.0 and y > M.HALL_Y1:
				for hx: float in [M.CX - 170.0, M.CX + 170.0]:
					wc.glow(Vector2(hx, y), 170.0, Color(LAMP_POOL.r, LAMP_POOL.g, LAMP_POOL.b, LAMP_POOL.a * u), 0.2)
			else:
				wc.glow(Vector2(x, y), 150.0, Color(LAMP_POOL.r, LAMP_POOL.g, LAMP_POOL.b, LAMP_POOL.a * u), 0.2)
		y += 180.0


# --- beyond the walls (cached) ----------------------------------------------------------

static func draw_edges(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	var keep := b.lod
	b.lod = true
	var lo := maxf(vt - 400.0, float(m.GATE_Y) - 40.0)
	var hi := minf(vb + 400.0, float(m.START_Y) + 700.0)
	if hi > lo:
		_edges(m, b, lo, hi)
	b.lod = keep


static func _edges(m: Node2D, b: ShapeBatch, lo: float, hi: float) -> void:
	var wet := Outdoors.tracks_wet(Game.weather)
	var c: Vector2
	# underground, everything past the walls is the ground it is dug into
	c = _clip(lo, hi, M.STAIR_B0, M.STAIR_FOOT)
	if c.y > c.x:
		b.rect(Rect2(-900.0, c.x, 3080.0, c.y - c.x), VOID)
		# the ground it is dug through: its beds, and stones in them
		var y := floorf(c.x / 70.0) * 70.0
		while y < c.y:
			b.rect(Rect2(-900.0, y + _h(int(y)) * 20.0, 3080.0, 2.0), VOID_LINE)
			for j in range(8):
				var k := int(y) * 13 + j * 7
				b.coarse(Vector2(-120.0 + _h(k) * 1520.0, y + _h(k + 5) * 70.0), 3.0 + _h(k + 9) * 7.0, STONE)
			y += 70.0
		# where the street gives way to the dig: the slab cut through, and
		# the dark under it
		for cut: Vector2 in [Vector2(M.STAIR_FOOT, -1.0), Vector2(M.STAIR_B0, 1.0)]:
			if cut.x > c.x - 80.0 and cut.x < c.y + 80.0:
				_slab_cut(b, cut.x, cut.y)
		_walls(b, c.x, c.y)
		_tracks(b, c.x, c.y)
		_signs(b, c.x, c.y)
	# the streets: the road to the west, the shops to the east
	c = _clip(lo, hi, M.STAIR_FOOT, float(m.START_Y) + 700.0)
	if c.y > c.x:
		_street_edges(m, b, c.x, c.y, wet, true)
	c = _clip(lo, hi, float(m.GATE_Y) - 40.0, M.STAIR_B0)
	if c.y > c.x:
		_street_edges(m, b, c.x, c.y, wet, false)


# The street's slab where the dig begins, seen cut through: concrete with its
# reinforcing bars, lit along the street's edge, and the dark falling away
# under it. `under` is the side the dig lies on (-1 north, 1 south).
static func _slab_cut(b: ShapeBatch, y: float, under: float) -> void:
	var y0 := y - 18.0 if under < 0.0 else y
	b.rect(Rect2(-900.0, y0, 3080.0, 18.0), SLAB)
	b.rect(Rect2(-900.0, y - 3.0 if under < 0.0 else y, 3080.0, 3.0), SLAB_LIT)
	var x := -880.0
	while x < 2170.0:
		b.circle(Vector2(x, y0 + 9.0), 2.0, REBAR)
		x += 22.0
	var d0 := y0 if under < 0.0 else y0 + 18.0
	_sp.resize(4)
	_sp[0] = Vector2(-900.0, d0)
	_sp[1] = Vector2(2180.0, d0)
	_sp[2] = Vector2(-900.0, d0 + under * 90.0)
	_sp[3] = Vector2(2180.0, d0 + under * 90.0)
	b.band(_sp, 2, Color(0.02, 0.02, 0.03, 0.55), _fade2)


# a section's walls: bevelled white tile on its concrete lining, laid in
# staggered courses, a frieze in the section's colour, strip lamps along it
# and a dark skirting where it meets the floor
static func _walls(b: ShapeBatch, lo: float, hi: float) -> void:
	for sec: Array in M.SECTIONS:
		var kind := String(sec[4])
		if kind.begins_with("street") or kind.begins_with("stairs") or kind == "car":
			continue
		var y0 := maxf(float(sec[0]) - 26.0, lo)
		var y1 := minf(float(sec[1]) + 26.0, hi)
		if y1 <= y0:
			continue
		var x0: float = float(sec[2]) - 26.0
		var w: float = float(sec[3]) - float(sec[2]) + 52.0
		var h := y1 - y0
		b.rect(Rect2(x0 - 12.0, y0, w + 24.0, h), LINING)
		b.rect(Rect2(x0 - 12.0, y0, 3.0, h), LINING_DARK)
		b.rect(Rect2(x0 + w + 9.0, y0, 3.0, h), LINING_DARK)
		b.rect(Rect2(x0, y0, w, h), TILE)
		var ty := floorf(y0 / 13.0) * 13.0
		while ty < y1:
			b.rect(Rect2(x0, ty, w, 1.2), TILE_GROUT)
			if int(ty / 13.0) % 2 != 0:
				b.rect(Rect2(x0 + 13.0, ty, 1.2, 13.0), TILE_GROUT)
				b.rect(Rect2(x0 + w - 14.2, ty, 1.2, 13.0), TILE_GROUT)
			ty += 13.0
		b.rect(Rect2(x0, y0, 4.0, h), TILE_SHADE)
		b.rect(Rect2(x0 + w - 4.0, y0, 4.0, h), TILE_SHADE)
		var col := _wall_colour(kind)
		b.rect(Rect2(x0 + 5.0, y0, 5.0, h), col)
		b.rect(Rect2(x0 + w - 10.0, y0, 5.0, h), col)
		# the strip lamps, a fitting every 120 px, lit
		for lx: float in [x0 + 15.0, x0 + w - 18.0]:
			var ly := floorf(y0 / 120.0) * 120.0
			while ly < y1:
				var a := maxf(ly + 10.0, y0)
				var z := minf(ly + 100.0, y1)
				if z > a:
					b.rect(Rect2(lx - 1.0, a, 5.0, z - a), STEEL_DARK)
					b.rect(Rect2(lx, a + 1.0, 3.0, z - a - 2.0), STRIP)
				ly += 120.0
		b.rect(Rect2(x0 + 22.0, y0, 4.0, h), SKIRT)
		b.rect(Rect2(x0 + w - 26.0, y0, 4.0, h), SKIRT)
	# the car's tunnel, beyond its shell (the overhead draws what is out there)
	var cc := _clip(lo, hi, M.CAR_N, M.CAR_S)
	if cc.y > cc.x:
		b.rect(Rect2(-900.0, cc.x, 3080.0, cc.y - cc.x), TUNNEL)


static func _wall_colour(kind: String) -> Color:
	match kind:
		"plat_a":
			return PARAIGUES
		"plat_b", "esc_b":
			return SANT_GOS
		"passage":
			return LINE_C
	return LINE_A


# the other line's track, east of both platforms, and the tunnel wall beyond
static func _tracks(b: ShapeBatch, lo: float, hi: float) -> void:
	for sec: Vector2 in [Vector2(M.CAR_S - 5.0, M.PLAT_A0), Vector2(M.PLAT_B1, M.CAR_N + 5.0)]:
		var c := _clip(lo, hi, sec.x, sec.y)
		if c.y <= c.x:
			continue
		var x0 := 880.0
		b.rect(Rect2(x0, c.x, 170.0, c.y - c.x), PIT)
		b.rect(Rect2(x0 + 20.0, c.x, 130.0, c.y - c.x), BALLAST)
		var y := floorf(c.x / 30.0) * 30.0
		while y < c.y:
			b.rect(Rect2(M.TRACK_X - 40.0, y, 80.0, 10.0), SLEEPER)
			y += 30.0
		for rx: float in [M.TRACK_X - 26.0, M.TRACK_X + 26.0]:
			b.rect(Rect2(rx - 3.0, c.x, 6.0, c.y - c.x), RAIL)
			b.rect(Rect2(rx - 2.0, c.x, 1.5, c.y - c.x), RAIL_LIT)
		# the far wall, tiled, the station's colour along it
		b.rect(Rect2(x0 + 170.0, c.x, 30.0, c.y - c.x), TILE)
		b.rect(Rect2(x0 + 170.0, c.x, 6.0, c.y - c.x), PARAIGUES if sec.y == M.PLAT_A0 else SANT_GOS)


# the station names and the way out, on the walls
static func _signs(b: ShapeBatch, lo: float, hi: float) -> void:
	var panels := [
		[Vector2(300.0, -2700.0), "PARAIGÜES", PARAIGUES], [Vector2(300.0, -2960.0), "PARAIGÜES", PARAIGUES],
		[Vector2(300.0, -3200.0), "PARAIGÜES", PARAIGUES], [Vector2(1150.0, -2850.0), "PARAIGÜES", PARAIGUES],
		[Vector2(1150.0, -3150.0), "PARAIGÜES", PARAIGUES],
		[Vector2(300.0, -4000.0), "SANT GOS", SANT_GOS], [Vector2(300.0, -4330.0), "SANT GOS", SANT_GOS],
		[Vector2(1150.0, -4150.0), "SANT GOS", SANT_GOS],
		[Vector2(280.0, -980.0), "PARAIGÜES", PARAIGUES], [Vector2(280.0, -1400.0), "ANDANES", Color(0.30, 0.30, 0.32)],
		[Vector2(1000.0, -1350.0), "SORTIDA", Color(0.20, 0.52, 0.30)], [Vector2(980.0, -4600.0), "SORTIDA", Color(0.20, 0.52, 0.30)],
		[Vector2(372.0, -2380.0), "ANDANA", Color(0.30, 0.30, 0.32)],
	]
	for p: Array in panels:
		var at: Vector2 = p[0]
		if at.y < lo - 30.0 or at.y > hi + 30.0:
			continue
		name_panel(b, at, 150.0, String(p[1]), p[2])
	# the change to line C, in the passage
	if lo < -2180.0 and hi > -2260.0:
		var at := Vector2(372.0, -2220.0)
		b.rect(Rect2(at - Vector2(70.0, 13.0), Vector2(140.0, 26.0)), Color(0.96, 0.96, 0.94))
		roundel(b, at + Vector2(-52.0, 0.0), 9.0, LINE_C, "C")
		letters(b, "CORRESPONDÈNCIA", at + Vector2(10.0, 5.0), 9.0, Color(0.14, 0.14, 0.16), 1.3, 100.0)
	# posters on the walls down to the platform, framed
	for i in range(POSTERS.size()):
		var at: Vector2 = POSTERS[i]
		if at.y > lo - 50.0 and at.y < hi + 50.0:
			_poster(b, at, i)
	# the line's map, between the name panels on the platform walls
	for p: Array in ROUTE_MAPS:
		var at: Vector2 = p[0]
		if at.y > lo - 30.0 and at.y < hi + 30.0:
			route_map(b, at, 150.0, int(p[1]))


# beside the escalator down and in the passage, clear of the signs and the niche
const POSTERS: Array[Vector2] = [
	Vector2(350.0, -1700.0), Vector2(930.0, -1760.0), Vector2(350.0, -1920.0), Vector2(930.0, -1980.0),
	Vector2(417.0, -2130.0), Vector2(863.0, -2130.0), Vector2(417.0, -2480.0), Vector2(863.0, -2490.0),
]


# [where, the stop it is at]: Paraigües is the third stop of six, Sant Gos the fourth
const ROUTE_MAPS := [
	[Vector2(300.0, -2830.0), 2], [Vector2(300.0, -3080.0), 2], [Vector2(1150.0, -3000.0), 2],
	[Vector2(300.0, -4165.0), 3], [Vector2(1150.0, -4320.0), 3],
]


# the line's map: its roundel, the line in its colour, a stop for each
# station, this one ringed, and the change to line C at Paraigües
static func route_map(c: ShapeBatch, centre: Vector2, w: float, here: int) -> void:
	var r := Rect2(centre - Vector2(w * 0.5, 13.0), Vector2(w, 26.0))
	c.rect(r.grow(2.0), Color(0.06, 0.06, 0.07))
	c.rect(r, Color(0.96, 0.96, 0.93))
	roundel(c, Vector2(r.position.x + 13.0, centre.y), 8.0, LINE_A, "A")
	var a := Vector2(r.position.x + 32.0, centre.y + 3.0)
	var e := Vector2(r.end.x - 10.0, centre.y + 3.0)
	c.line(a, e, LINE_A, 4.0)
	for i in range(6):
		var p := a.lerp(e, float(i) / 5.0)
		if i == here:
			c.circle(p, 5.5, Color(0.10, 0.10, 0.11))
			c.circle(p, 4.0, Color(0.98, 0.98, 0.96))
			c.circle(p, 2.2, RED)
		else:
			c.circle(p, 3.4, Color(0.98, 0.98, 0.96))
			c.circle(p, 1.8, LINE_A.darkened(0.2))
		# each stop's name, too small to read from here: a printed dash
		c.rect(Rect2(p.x - 6.0, centre.y - 9.0, 12.0, 2.0), Color(0.30, 0.30, 0.32))
		if i == 2:
			c.circle(p + Vector2(0.0, 7.0), 2.6, LINE_C)


# A poster in the passage, framed: a concert, the beach, a gallery's show
# and a dog groomer's, all this walk's own and none of them selling anything
# real.
static func _poster(b: ShapeBatch, at: Vector2, n: int) -> void:
	var x := at.x
	var py := at.y
	var white := Color(0.96, 0.96, 0.94)
	b.rect(Rect2(x - 30.0, py - 44.0, 60.0, 88.0), Color(0.08, 0.08, 0.09))
	var inner := Rect2(x - 27.0, py - 41.0, 54.0, 82.0)
	match n % 4:
		0:
			# a concert: a night sky, a big record, the bill
			b.rect(inner, Color(0.16, 0.12, 0.30))
			b.circle(Vector2(x, py - 10.0), 19.0, Color(0.06, 0.06, 0.08))
			b.circle(Vector2(x, py - 10.0), 13.0, Color(0.12, 0.12, 0.14))
			b.circle(Vector2(x, py - 10.0), 6.0, Color(0.96, 0.50, 0.22))
			b.circle(Vector2(x, py - 10.0), 1.5, Color(0.06, 0.06, 0.08))
			b.rect(Rect2(x - 20.0, py + 18.0, 40.0, 5.0), Color(0.98, 0.84, 0.30))
			b.rect(Rect2(x - 20.0, py + 28.0, 28.0, 3.0), white)
		1:
			# the beach: sky, sun, sea, sand
			b.rect(Rect2(inner.position, Vector2(inner.size.x, 34.0)), Color(0.56, 0.80, 0.92))
			b.circle(Vector2(x + 10.0, py - 26.0), 8.0, Color(0.99, 0.86, 0.34))
			b.rect(Rect2(inner.position.x, py - 7.0, inner.size.x, 22.0), Color(0.12, 0.42, 0.66))
			b.rect(Rect2(inner.position.x, py - 7.0, inner.size.x, 2.0), white)
			b.rect(Rect2(inner.position.x, py + 15.0, inner.size.x, 26.0), Color(0.92, 0.80, 0.56))
			b.rect(Rect2(x - 20.0, py + 26.0, 30.0, 4.0), Color(0.16, 0.30, 0.48))
		2:
			# a gallery's show: bright shapes on white
			b.rect(inner, Color(0.95, 0.93, 0.88))
			b.circle(Vector2(x - 8.0, py - 18.0), 11.0, Color(0.86, 0.18, 0.16))
			b.rect(Rect2(x + 2.0, py - 10.0, 16.0, 16.0), Color(0.14, 0.32, 0.66))
			b.circle(Vector2(x + 12.0, py - 26.0), 4.0, Color(0.98, 0.80, 0.18))
			b.line(Vector2(x - 20.0, py + 8.0), Vector2(x + 18.0, py - 30.0), Color(0.08, 0.08, 0.09), 1.6)
			b.rect(Rect2(x - 20.0, py + 22.0, 40.0, 4.0), Color(0.08, 0.08, 0.09))
		_:
			# a dog groomer's: a happy dog's head, freshly fluffed
			b.rect(inner, Color(0.98, 0.70, 0.62))
			var hd := Vector2(x, py - 10.0)
			b.circle(hd + Vector2(-13.0, -6.0), 7.0, Color(0.42, 0.28, 0.20))
			b.circle(hd + Vector2(13.0, -6.0), 7.0, Color(0.42, 0.28, 0.20))
			b.circle(hd, 14.0, Color(0.90, 0.78, 0.58))
			b.circle(hd + Vector2(-5.0, -2.0), 1.8, Color(0.08, 0.08, 0.09))
			b.circle(hd + Vector2(5.0, -2.0), 1.8, Color(0.08, 0.08, 0.09))
			b.circle(hd + Vector2(0.0, 5.0), 3.0, Color(0.10, 0.08, 0.08))
			b.rect(Rect2(x - 20.0, py + 18.0, 40.0, 5.0), white)
			b.rect(Rect2(x - 20.0, py + 28.0, 24.0, 3.0), Color(0.40, 0.20, 0.30))
	# a glare across the glass
	b.line(Vector2(x - 24.0, py - 20.0), Vector2(x - 6.0, py - 38.0), Color(1.0, 1.0, 1.0, 0.18), 5.0)


static func _street_edges(m: Node2D, b: ShapeBatch, lo: float, hi: float, wet: bool, south: bool) -> void:
	var x0 := M.CX - M.STREET_HALF
	var x1 := M.CX + M.STREET_HALF
	# the road to the west, glossy in the rain, a lane line down it
	b.rect(Rect2(x0 - 160.0, lo, 160.0, hi - lo), ASPHALT_WET if wet else ASPHALT)
	# the gutter along the kerb, its grates
	b.rect(Rect2(x0 - 12.0, lo, 12.0, hi - lo), Color(0.30, 0.30, 0.31) if wet else Color(0.36, 0.36, 0.37))
	var dy := floorf(lo / 80.0) * 80.0
	while dy < hi:
		b.rect(Rect2(x0 - 82.0, dy, 3.0, 40.0), LANE_LINE)
		if wet:
			_streak(b, Rect2(x0 - 156.0 + _h(int(dy)) * 110.0, dy + 14.0, 44.0, 12.0), SHEEN, 0.22)
		if int(absf(dy) / 80.0) % 3 == 0:
			_grille(b, Rect2(x0 - 30.0, dy + 30.0, 22.0, 12.0))
		dy += 80.0
	# a zebra crossing a little way up from each stair mouth
	var zy := 300.0 if south else -4990.0
	if zy + 60.0 > lo and zy < hi:
		var zx := x0 - 152.0
		while zx < x0 - 14.0:
			b.rect(Rect2(zx, zy, 12.0, 60.0), ZEBRA)
			zx += 24.0
	# the far pavement and its roofs, the buildings' shadow along it
	var s0 := M.STAIR_FOOT if south else float(m.GATE_Y) - 40.0
	var s1 := float(m.START_Y) + 700.0 if south else M.STAIR_B0
	b.rect(Rect2(x0 - 210.0, lo, 50.0, hi - lo), PAVE_WET if wet else PAVE)
	_roofs(m, b, x0 - 1100.0, x0 - 210.0, lo, hi, s0, s1, 3, true)
	b.rect(Rect2(x0 - 210.0, lo, 12.0, hi - lo), SHADOW)
	# the shops to the east: their fronts, and an awning over each
	b.rect(Rect2(x1, lo, 30.0, hi - lo), Color(0.46, 0.42, 0.40))
	_roofs(m, b, x1 + 30.0, x1 + 1000.0, lo, hi, s0, s1, 9, false)
	var ay := floorf(lo / 110.0) * 110.0
	while ay < hi:
		var k := int(absf(ay)) / 110
		var col: Color = AWNINGS[k % AWNINGS.size()]
		# the shopfront between this awning and the next: a door, dark
		b.rect(Rect2(x1, ay + 96.0, 12.0, 12.0), Color(0.16, 0.14, 0.14))
		b.rect(Rect2(x1 + 2.0, ay + 18.0, 22.0, 80.0), SHADOW)
		b.rect(Rect2(x1 - 2.0, ay + 14.0, 26.0, 80.0), col)
		for s in range(4):
			b.rect(Rect2(x1 - 2.0, ay + 14.0 + float(s) * 20.0, 26.0, 9.0), col.lightened(0.18))
		# the valance along its front edge, scalloped, and the roller bar
		b.rect(Rect2(x1 - 5.0, ay + 14.0, 4.0, 80.0), col.darkened(0.2))
		var vy := ay + 18.0
		while vy < ay + 92.0:
			b.circle(Vector2(x1 - 5.0, vy), 3.0, col.darkened(0.2))
			vy += 8.0
		b.rect(Rect2(x1 + 20.0, ay + 12.0, 5.0, 84.0), Color(0.28, 0.28, 0.30))
		ay += 110.0
	# the stair mouth: the pavement round it at street level, and its railing
	var top := M.STAIR_TOP if south else M.STREET_B
	var deep := M.STAIR_FOOT if south else M.STAIR_B0
	var c := _clip(lo, hi, minf(top, deep), maxf(top, deep))
	if c.y > c.x:
		for side: float in [-1.0, 1.0]:
			var wx := M.CX + side * M.STAIR_HALF
			var px := minf(wx, M.CX + side * M.STREET_HALF)
			b.rect(Rect2(px, c.x, M.STREET_HALF - M.STAIR_HALF, c.y - c.x), PAVE_WET if wet else PAVE)
			Panot.flor(b, px, px + M.STREET_HALF - M.STAIR_HALF, c.x, c.y)
			# the granite parapet the railing stands on, and the railing
			var gx := wx if side > 0.0 else wx - 14.0
			b.rect(Rect2(gx, c.x, 14.0, c.y - c.x), GRANITE)
			b.rect(Rect2(gx + 5.0, c.x, 4.0, c.y - c.x), RAILING)
			b.rect(Rect2(gx + 5.0, c.x, 1.5, c.y - c.x), RAILING_LIT)
			var ry := floorf(c.x / 22.0) * 22.0
			while ry < c.y:
				b.circle(Vector2(gx + 7.0, ry), 2.6, RAILING)
				ry += 22.0


# The roofs along a street, a row of buildings each 150 px along it: one
# against the street, as deep as its hash says, and one behind, each with
# its own roof (world/gotic.gd: pantiles, a terrat, a light well), the gaps
# between them the party walls. Blocks are cut to the street's own stretch
# [s0, s1], never to the view, so a redraw lays the same roofs. `west` is the
# side of the road they stand on.
static func _roofs(m: Node2D, b: ShapeBatch, x0: float, x1: float, lo: float, hi: float, s0: float, s1: float, salt: int, west: bool) -> void:
	var y := floorf(lo / 150.0) * 150.0
	while y < hi:
		var a := maxf(y, s0)
		var z := minf(y + 150.0, s1)
		if z - a > 30.0:
			b.rect(Rect2(x0, a, x1 - x0, z - a), PARTY)
			var k := int(absf(y)) / 150 + salt
			var depth := 170.0 + _h(k * 5) * 110.0
			var front := Rect2(x1 - depth, a + 3.0, depth - 2.0, z - a - 6.0) if west else Rect2(x0 + 2.0, a + 3.0, depth - 2.0, z - a - 6.0)
			var back := Rect2(x0, a + 3.0, x1 - x0 - depth - 4.0, z - a - 6.0) if west else Rect2(x0 + depth + 4.0, a + 3.0, x1 - x0 - depth - 4.0, z - a - 6.0)
			Gotic.draw_block(m, b, front, Gotic.roof_hash(k, salt))
			Gotic.draw_block(m, b, back, Gotic.roof_hash(k, salt + 17))
			# the cornice along the street front
			var cx := front.end.x - 4.0 if west else front.position.x
			b.rect(Rect2(cx, a + 3.0, 4.0, z - a - 6.0), PARAPET)
		y += 150.0


# --- the escalators' treads (live) -------------------------------------------------------

static func draw_escalators(_m: Node2D, wc: ShapeBatch, vt: float, vb: float) -> void:
	var scroll := fmod(AnimClock.msec() / 1000.0 * 118.0, 18.0)
	for z: Rect2 in [M.ESC_A, M.ESC_B]:
		if z.end.y < vt - 40.0 or z.position.y > vb + 40.0:
			continue
		var y0 := maxf(z.position.y, vt - 40.0)
		var y1 := minf(z.end.y, vb + 40.0)
		wc.rect(Rect2(z.position.x, y0, z.size.x, y1 - y0), Color(0.46, 0.48, 0.51))
		# treads moving north: a cleat line every 18 px
		var y := floorf(y0 / 18.0) * 18.0 - scroll
		while y < y1:
			if y > z.position.y + 10.0 and y < z.end.y - 10.0:
				wc.rect(Rect2(z.position.x + 6.0, y, z.size.x - 12.0, 2.0), Color(0.30, 0.31, 0.33))
				wc.rect(Rect2(z.position.x + 6.0, y + 2.0, z.size.x - 12.0, 1.0), STEEL_LIT)
			y += 18.0
		# the yellow-edged skirt, and the comb plates at each end
		wc.rect(Rect2(z.position.x, y0, 6.0, y1 - y0), NOSING)
		wc.rect(Rect2(z.end.x - 6.0, y0, 6.0, y1 - y0), NOSING)
		for ey: float in [z.position.y, z.end.y - 12.0]:
			if ey > vt - 40.0 and ey < vb + 40.0:
				# the landing plate, ribbed, and the comb's teeth where the
				# treads slide under it
				var top: bool = ey == z.position.y
				wc.rect(Rect2(z.position.x, ey + (-14.0 if top else 12.0), z.size.x, 14.0), STEEL_DARK)
				var rx := z.position.x + 4.0
				while rx < z.end.x - 3.0:
					wc.rect(Rect2(rx, ey + (-12.0 if top else 14.0), 1.5, 10.0), STEEL)
					rx += 6.0
				wc.rect(Rect2(z.position.x, ey, z.size.x, 12.0), STEEL)
				wc.rect(Rect2(z.position.x, ey + (10.0 if top else 0.0), z.size.x, 2.0), NOSING)
				var tx := z.position.x + 8.0
				var teeth_y := ey + 12.0 if top else ey - 4.0
				while tx < z.end.x - 8.0:
					wc.rect(Rect2(tx, teeth_y, 2.0, 4.0), STEEL_DARK)
					tx += 5.0


# --- live: bars, doors, the other train, everyone on foot -----------------------------------

static func draw_live(m: Node2D, wc: ShapeBatch, vt: float, vb: float) -> void:
	var st = m.metro
	if st == null:
		return
	var t := AnimClock.msec() / 1000.0
	if M.TURN_Y > vt - 60.0 and M.TURN_Y < vb + 60.0:
		_bars(wc, st)
	if M.CAR_S > vt - 60.0 and M.CAR_N < vb + 60.0:
		_doors(wc, st.train, t)
	if M.CAR_S > vt - 200.0 and M.PLAT_A0 < vb + 200.0:
		_other_train(wc, st.surge, vt, vb)
	if M.BUSKER.y > vt - 80.0 and M.BUSKER.y < vb + 80.0:
		_busker(wc, t)
	if -860.0 > vt - 80.0 and -860.0 < vb + 80.0 and Outdoors.umbrella_shakers(Game.weather, Game.hour):
		_shakers(wc, t)
	for p: Dictionary in st.people:
		var pos: Vector2 = p.p
		if pos.y < vt - 40.0 or pos.y > vb + 40.0:
			continue
		var moving: bool = (p.v as Vector2).length() > 5.0
		var stride := float(p.t) * 9.0 if moving else -1.0
		var size := 1.0 + (0.14 if float(p.hop) > 0.0 else 0.0)
		NpcFigure.person(wc, pos, p.face, int(p.key), stride, {"size": size,
			"arms": NpcFigure.Arms.READY if String(p.mode) == "wait" else NpcFigure.Arms.SIDE})


static func _bars(wc: ShapeBatch, st) -> void:
	var g = st.gate
	for i in range(M.GATE_XS.size()):
		var gx: float = M.GATE_XS[i]
		var hub := Vector2(gx - 26.0, M.TURN_Y + 6.0)
		var ang := 0.0
		if i == M.HUMAN_GATE:
			ang = float(g.bar) * PI * 0.5
		var tip := hub + Vector2(cos(-ang), sin(-ang)) * 48.0
		wc.line(hub + Vector2(1.5, 2.0), tip + Vector2(1.5, 2.0), SHADOW, 4.0)
		wc.line(hub, tip, STEEL_DARK, 4.0)
		wc.line(hub, tip, STEEL_LIT, 1.6)
		wc.circle(hub, 4.0, STEEL_DARK)
		# the lamp on the cabinet: green for your human's, once the card is read
		var lamp := Vector2(gx + 29.0, M.TURN_Y - 20.0)
		var open: bool = i == M.HUMAN_GATE and float(g.bar) > 0.2
		wc.circle(lamp, 3.0, GREEN if open else RED)


# the car's two ends, and a door's two leaves (west, east): hoisted so the
# per-frame loops allocate nothing
const ENDS: Array[int] = [1, -1]
const SIDES: Array[float] = [-1.0, 1.0]
const SHAKER_AT: Array[Vector2] = [Vector2(430.0, -860.0), Vector2(852.0, -872.0)]
const SHAKER_KEY: Array[int] = [41, 53]
static var _canopy := PackedVector2Array()


static func _doors(wc: ShapeBatch, tr, t: float) -> void:
	var warn: bool = tr.state == 1 or tr.state == 2
	var caught: bool = tr.state == 3
	for end: int in ENDS:
		var y := M.CAR_S if end > 0 else M.CAR_N
		var g: float = tr.gap_s if end > 0 else tr.gap_n
		var leaf := M.DOOR_HALF * (1.0 - g)
		var pinched: bool = caught and end == tr.open_end
		for side: float in SIDES:
			var edge := M.DOOR_L if side < 0.0 else M.DOOR_R
			var x0 := minf(edge, edge - side * leaf)
			var w := leaf
			if pinched:
				# closed on the strap where it crosses (Metro._pinch's rects)
				if side < 0.0:
					x0 = M.DOOR_L
					w = float(tr.pinch_x) - M.PINCH - M.DOOR_L
				else:
					x0 = float(tr.pinch_x) + M.PINCH
					w = M.DOOR_R - x0
			# the leaves slide into pockets in the end wall
			wc.rect(Rect2(x0, y - 5.0, w, 10.0), DOOR)
			if w > 6.0:
				wc.rect(Rect2(x0 + 3.0, y - 2.5, w - 6.0, 5.0), CAR_GLASS)
				var lip := x0 + w if side < 0.0 else x0
				wc.rect(Rect2(lip - 1.5, y - 6.0, 3.0, 12.0), DOOR_EDGE)
		# the warning lamp over the doorway, flashing with the chime
		var on: bool = (warn or pinched) and end == tr.open_end and (true if not Game.flashes else fmod(t * 4.0, 1.0) < 0.5)
		for side: float in SIDES:
			var lx := M.DOOR_L - 8.0 if side < 0.0 else M.DOOR_R + 8.0
			wc.circle(Vector2(lx, y), 4.0, WARN_ON if on else WARN_OFF)
			if on:
				wc.glow(Vector2(lx, y), 26.0, Color(1.0, 0.76, 0.2, 0.35), 0.2)


# the other line's train, in on the far track by the Paraigües platform
static func _other_train(wc: ShapeBatch, s, vt: float, vb: float) -> void:
	if s.state == 0:
		return
	var off := 0.0
	match int(s.state):
		1:
			var k := clampf(float(s.t) / M.SURGE_IN_T, 0.0, 1.0)
			off = -pow(1.0 - k, 2.0) * 1100.0
		5:
			var k := clampf(float(s.t) / M.SURGE_OUT_T, 0.0, 1.0)
			off = k * k * 1300.0
	var top := M.CAR_S + 6.0
	var bot := M.PLAT_A0 - 6.0
	var open: bool = int(s.state) >= 2 and int(s.state) <= 4
	var x0 := M.TRACK_X - 50.0
	var y := top + off - 40.0
	var car := 0
	while car < 4:
		var c0 := y + float(car) * 236.0
		var c1 := c0 + 226.0
		var a := maxf(c0, maxf(top, vt - 40.0))
		var b2 := minf(c1, minf(bot, vb + 40.0))
		if b2 > a:
			wc.rect(Rect2(x0, a, 100.0, b2 - a), TRAIN_BODY)
			wc.rect(Rect2(x0 + 12.0, a, 76.0, b2 - a), TRAIN_ROOF)
			wc.rect(Rect2(x0 + 2.0, a, 4.0, b2 - a), LINE_A)
			# the roof's seams, the air-conditioning units and their grilles
			wc.rect(Rect2(x0 + 12.0, a, 1.5, b2 - a), STEEL_DARK)
			wc.rect(Rect2(x0 + 86.5, a, 1.5, b2 - a), STEEL_DARK)
			for u in range(2):
				var uy := c0 + 40.0 + float(u) * 110.0
				if uy > a and uy + 44.0 < b2:
					wc.rect(Rect2(x0 + 26.0, uy + 3.0, 52.0, 44.0), SHADOW)
					wc.rect(Rect2(x0 + 24.0, uy, 52.0, 44.0), STEEL)
					wc.rect(Rect2(x0 + 24.0, uy, 52.0, 3.0), STEEL_LIT)
					wc.circle(Vector2(x0 + 50.0, uy + 22.0), 13.0, STEEL_DARK)
					wc.circle(Vector2(x0 + 50.0, uy + 22.0), 10.0, Color(0.20, 0.21, 0.23))
					wc.line(Vector2(x0 + 41.0, uy + 22.0), Vector2(x0 + 59.0, uy + 22.0), STEEL_DARK, 2.0)
			# the gangway's bellows to the next car
			if car < 3 and c1 > a and c1 + 10.0 < b2 + 10.0:
				wc.rect(Rect2(x0 + 14.0, c1, 72.0, 10.0), RUBBER)
				wc.rect(Rect2(x0 + 14.0, c1 + 3.0, 72.0, 1.5), STEEL_DARK)
				wc.rect(Rect2(x0 + 14.0, c1 + 6.5, 72.0, 1.5), STEEL_DARK)
			# its doors on the platform side, open while it stands
			for d in range(2):
				var dy := c0 + 50.0 + float(d) * 110.0
				if dy > a and dy + 40.0 < b2:
					wc.rect(Rect2(x0 - 2.0, dy, 8.0, 40.0), Color(1.0, 0.92, 0.70) if open else DOOR)
					if open:
						wc.glow(Vector2(x0 - 20.0, dy + 20.0), 44.0, Color(1.0, 0.92, 0.7, 0.22), 0.2)
		car += 1
	# its headlights, coming in
	if int(s.state) == 1:
		var front := y + 4.0 * 236.0 - 10.0
		if front > top and front < bot:
			wc.glow(Vector2(M.TRACK_X, front + 40.0), 90.0, Color(1.0, 0.96, 0.8, 0.30), 0.2)


static func _busker(wc: ShapeBatch, t: float) -> void:
	var p := M.BUSKER
	# the open case and the coins in it
	wc.rect(Rect2(p.x - 50.0, p.y + 12.0, 34.0, 22.0), Color(0.20, 0.12, 0.10))
	wc.rect(Rect2(p.x - 48.0, p.y + 14.0, 30.0, 18.0), Color(0.62, 0.16, 0.20))
	for i in range(5):
		wc.circle(Vector2(p.x - 44.0 + _h(i) * 22.0, p.y + 18.0 + _h(i * 3) * 10.0), 2.0, Color(0.92, 0.80, 0.36))
	if not Outdoors.underground_busker(Game.weather, Game.hour):
		return
	NpcFigure.person(wc, p, Vector2.LEFT, 77, -1.0, {"hair": Color(0.82, 0.82, 0.80), "headwear": "cap",
		"headwear_col": Color(0.24, 0.20, 0.18), "arms": NpcFigure.Arms.READY})
	# the accordion, breathing in and out
	var sq := 6.0 + 4.0 * sin(t * 3.2)
	var at := p + Vector2(-14.0, 0.0)
	wc.rect(Rect2(at.x - 6.0, at.y - sq - 6.0, 12.0, 6.0), Color(0.82, 0.14, 0.16))
	wc.rect(Rect2(at.x - 6.0, at.y + sq, 12.0, 6.0), Color(0.82, 0.14, 0.16))
	var by := at.y - sq
	while by < at.y + sq:
		wc.rect(Rect2(at.x - 5.0, by, 10.0, 1.6), Color(0.14, 0.12, 0.12))
		by += 3.0
	# notes rising off it
	for i in range(3):
		var ph := fmod(t * 0.6 + float(i) / 3.0, 1.0)
		var np := at + Vector2(-10.0 - ph * 30.0 + sin(ph * 9.0 + float(i)) * 6.0, -10.0 - ph * 46.0)
		var a := (1.0 - ph) * 0.8
		wc.circle(np, 2.6, Color(1.0, 0.95, 0.75, a))
		wc.line(np + Vector2(2.2, 0.0), np + Vector2(2.2, -8.0), Color(1.0, 0.95, 0.75, a), 1.2)


# out of the rain: two people at the foot of the stairs shaking out their umbrellas
static func _shakers(wc: ShapeBatch, t: float) -> void:
	for si in range(SHAKER_AT.size()):
		var p: Vector2 = SHAKER_AT[si]
		var k: int = SHAKER_KEY[si]
		var face := Vector2.RIGHT if p.x < M.CX else Vector2.LEFT
		NpcFigure.person(wc, p, face, k, -1.0, {"arms": NpcFigure.Arms.READY})
		var shake := sin(t * 11.0 + float(k)) * 0.5
		var tip := p + face.rotated(shake) * 30.0
		var col: Color = AWNINGS[k % AWNINGS.size()]
		_canopy.resize(8)
		for i in range(8):
			var a := TAU * float(i) / 8.0
			_canopy[i] = tip + Vector2(cos(a) * 15.0, sin(a) * 11.0).rotated(shake)
		wc.polygon(_canopy, col)
		wc.circle(tip, 2.0, Color(0.10, 0.10, 0.10))
		wc.line(p + face * 8.0, tip, Color(0.12, 0.12, 0.12), 1.6)
		# the water flung off it
		for i in range(6):
			var ph := fmod(t * 2.2 + float(i) / 6.0 + float(k), 1.0)
			var d := face.rotated(shake * 2.0 + (float(i) - 2.5) * 0.4) * (18.0 + ph * 30.0)
			wc.circle(tip + d, 1.6, Color(0.70, 0.82, 0.96, 0.7 * (1.0 - ph)))


# --- overhead: the car's outside, the tunnel over the platforms during a ride ---------------

static func draw_overhead(m: Node2D, c: CanvasItem) -> void:
	var st = m.metro
	if st == null or m.cam == null:
		return
	var cy: float = m.cam.get_screen_center_position().y
	if absf(cy - (M.CAR_S + M.CAR_N) * 0.5) > 1300.0:
		return
	var b := ShapeBatch.new(c)
	var tr = st.train
	var riding: bool = tr.state == 5 or tr.state == 6
	# how far the station still has to slide in, braking into it
	var slide := 0.0
	if tr.state == 6:
		var k := clampf(float(tr.t) / M.BRAKE_T, 0.0, 1.0)
		slide = pow(1.0 - k, 2.0) * 520.0
	var travel_dir := -float(tr.open_end)        # -1 north
	for side: float in [-1.0, 1.0]:
		var x_in := M.CAR_L - 16.0 if side < 0.0 else M.CAR_R + 16.0
		var x0 := minf(x_in, x_in + side * 900.0)
		var r := Rect2(x0, M.CAR_N, 900.0, M.CAR_S - M.CAR_N)
		b.rect(r, TUNNEL)
		if riding:
			_tunnel(b, x_in, side, float(tr.travel), float(tr.speed), travel_dir)
		if tr.state == 6 or not riding:
			# docked (or braking into it): the station's platform beside the car
			var here: int = tr.open_end
			if tr.state == 6:
				here = -tr.open_end
			_station_side(b, x_in, side, here > 0, slide * travel_dir)
	# the platforms beyond the shut doors are the tunnel while it rides
	if riding:
		for end: int in [1, -1]:
			var y := M.CAR_S if end > 0 else M.CAR_N
			var reach := 260.0
			if tr.state == 6 and end == -tr.open_end:
				reach *= minf(1.0, slide / 520.0 + 0.05)
			var y0 := y if end > 0 else y - reach
			b.rect(Rect2(M.CX - M.PLAT_HALF - 30.0, y0, M.PLAT_HALF * 2.0 + 60.0, reach), TUNNEL)
			# with the tunnel's own lamps going by
			var ly := fmod(float(tr.travel) * 0.7, 260.0)
			for j in range(2):
				var yy := y0 + fmod(ly + float(j) * 130.0, reach)
				b.rect(Rect2(M.CX - M.PLAT_HALF - 20.0, yy, 10.0, 6.0 + float(tr.speed) * 0.04), TUNNEL_LAMP)
				b.rect(Rect2(M.CX + M.PLAT_HALF + 10.0, yy, 10.0, 6.0 + float(tr.speed) * 0.04), TUNNEL_LAMP)
	b.flush()


static func _tunnel(b: ShapeBatch, x_in: float, side: float, travel: float, speed: float, dir: float) -> void:
	# the tunnel wall close to the windows, its lamps and cables streaking by
	var wall_x := x_in + side * 40.0
	b.rect(Rect2(minf(wall_x, wall_x + side * 30.0), M.CAR_N, 30.0, M.CAR_S - M.CAR_N), TUNNEL_WALL)
	for k in range(3):
		var cx := x_in + side * (18.0 + float(k) * 6.0)
		b.rect(Rect2(cx - 1.0, M.CAR_N, 2.0, M.CAR_S - M.CAR_N), CABLE)
	var streak := 8.0 + speed * 0.06
	var ph := fmod(travel, 220.0)
	var y := M.CAR_N - 220.0 - ph * dir
	while y < M.CAR_S + 220.0:
		if y > M.CAR_N and y + streak < M.CAR_S:
			b.rect(Rect2(wall_x - 4.0 if side < 0.0 else wall_x - 6.0, y, 10.0, streak), TUNNEL_LAMP)
			b.glow(Vector2(x_in + side * 20.0, y + streak * 0.5), 34.0, Color(1.0, 0.86, 0.56, 0.18), 0.2)
		y += 220.0


static func _station_side(b: ShapeBatch, x_in: float, side: float, paraigues: bool, off: float) -> void:
	var col := PARAIGUES if paraigues else SANT_GOS
	var name := "PARAIGÜES" if paraigues else "SANT GOS"
	var y0 := M.CAR_N + off
	var y1 := M.CAR_S + off
	var a := maxf(y0, M.CAR_N)
	var z := minf(y1, M.CAR_S)
	if z <= a:
		return
	# the platform at the car's side, its yellow edge, then the wall
	var px := minf(x_in, x_in + side * 150.0)
	b.rect(Rect2(px, a, 150.0, z - a), PLAT_FLOOR)
	var ex := x_in + side * 4.0
	b.rect(Rect2(minf(ex, ex + side * 22.0), a, 22.0, z - a), TACTILE)
	var wx := x_in + side * 150.0
	b.rect(Rect2(minf(wx, wx + side * 40.0), a, 40.0, z - a), TILE)
	b.rect(Rect2(minf(wx, wx + side * 8.0), a, 8.0, z - a), col)
	var ny := y0 + 120.0
	while ny < y1:
		if ny > M.CAR_N + 20.0 and ny < M.CAR_S - 20.0:
			name_panel(b, Vector2(x_in + side * 75.0, ny), 120.0, name, col)
		ny += 240.0
	b.glow(Vector2(x_in + side * 70.0, (a + z) * 0.5), 260.0, Color(1.0, 0.97, 0.88, 0.10), 0.2)


# --- furniture -------------------------------------------------------------------------

static func draw_column(m: Node2D, wc: ShapeBatch, p: Vector2) -> void:
	var l: Vector2 = Shade.light
	if p in M.LAMPS:
		m._draw_lamppost(p)
		return
	if p in M.ROUNDEL_POSTS:
		# the entrance's post: a tall steel pole, its roundel on top
		wc.line(p + l * 6.0, p + l * 70.0, SHADOW, 6.0)
		wc.circle(p + l * 70.0, 14.0, SHADOW)
		wc.circle(p, 5.0, STEEL_DARK)
		roundel(wc, p, 12.0, LINE_A, "A")
		return
	if p in M.CAR_POLES:
		# a grab pole: polished steel, floor to ceiling
		wc.circle(p + l * 4.0, 5.0, SHADOW)
		wc.circle(p, 4.5, STEEL_DARK)
		wc.circle(p, 3.4, STEEL)
		wc.circle(p - l * 1.2, 1.4, STEEL_LIT)
		return
	if absf(p.x - M.CX) < 1.0 and p.y > M.STAIR_FOOT and p.y < M.STAIR_TOP + 20.0:
		# the handrail's end posts
		wc.circle(p, 6.0, STEP_EDGE)
		wc.circle(p, 4.5, STEEL)
		return
	# the platforms' and the hall's columns: square, tiled, the station's colour round them
	var col := PARAIGUES if p.y > M.CAR_S else SANT_GOS
	if p.y > M.HALL_Y1:
		col = LINE_A
	wc.glow(p + l * 14.0, 36.0, Color(0.05, 0.05, 0.08, 0.26), 0.3)
	wc.rect(Rect2(p - Vector2(16.0, 16.0), Vector2(32.0, 32.0)), TILE_GROUT)
	wc.rect(Rect2(p - Vector2(14.0, 14.0), Vector2(28.0, 28.0)), TILE)
	wc.rect(Rect2(p - Vector2(14.0, 3.0), Vector2(28.0, 6.0)), col)
	wc.rect(Rect2(p - Vector2(14.0, 14.0), Vector2(28.0, 3.0)), Color(1, 1, 1, 0.6))


static func draw_bench(m: Node2D, wc: ShapeBatch, p: Vector2) -> void:
	# a row of perforated steel seats on a rail along the wall
	m.box_shadow(wc, Rect2(p.x - 10.0, p.y - 30.0, 20.0, 60.0), 4.0, 7.0)
	wc.rect(Rect2(p.x - 12.0, p.y - 30.0, 3.0, 60.0), STEEL_DARK)
	for k in range(4):
		var sp := Vector2(p.x, p.y - 22.0 + float(k) * 15.0)
		wc.rect(Rect2(sp.x - 9.0, sp.y - 6.0, 19.0, 13.0), STEEL_DARK)
		wc.rect(Rect2(sp.x - 8.0, sp.y - 5.0, 17.0, 11.0), STEEL)
		for d in range(3):
			wc.circle(Vector2(sp.x - 4.0 + float(d) * 5.0, sp.y), 1.0, STEEL_DARK)


static func draw_bin(m: Node2D, wc: ShapeBatch, p: Vector2) -> void:
	if p.y > M.STAIR_TOP or p.y < M.STREET_B:
		m._draw_paperera(p)
		return
	# a metro bin: a steel ring holding a clear bag, so it hides nothing
	m.contact_shadow(wc, p, 13.0, 6.0, 0.22)
	wc.circle(p, 12.0, STEEL_DARK)
	wc.circle(p, 10.5, Color(0.78, 0.84, 0.86, 0.55))
	wc.circle(p + Vector2(-2.0, 1.0), 5.0, Color(0.92, 0.90, 0.84, 0.5))
	wc.rect(Rect2(p.x - 12.0, p.y - 1.5, 24.0, 3.0), STEEL)


static func draw_bollard(m: Node2D, wc: ShapeBatch, h) -> void:
	var hp: Vector2 = h.pos
	if hp.y > M.STAIR_TOP or hp.y < M.STREET_B:
		m._draw_pilona(wc, hp, h.done)
		if not h.done and h.progress > 0.0:
			wc.draw_arc(hp, 20.0, -PI / 2.0, -PI / 2.0 + TAU * h.progress / 0.8, 20, Color(1, 0.95, 0.7), 3.0)
		return
	# a fire extinguisher on its stand by the wall: the station's lamp post
	m.contact_shadow(wc, hp, 12.0, 8.0, 0.24)
	wc.rect(Rect2(hp.x - 10.0, hp.y - 4.0, 20.0, 8.0), STEEL_DARK)
	var body := RED if not h.done else RED.darkened(0.3)
	wc.circle(hp, 8.0, body.darkened(0.3))
	wc.circle(hp, 6.6, body)
	wc.circle(hp - Shade.light * 2.0, 2.4, body.lightened(0.35))
	wc.circle(hp + Vector2(0.0, -2.0), 2.2, Color(0.12, 0.12, 0.13))
	wc.line(hp + Vector2(1.5, -2.0), hp + Vector2(9.0, -8.0), Color(0.12, 0.12, 0.13), 2.0)
	if not h.done and h.progress > 0.0:
		wc.draw_arc(hp, 18.0, -PI / 2.0, -PI / 2.0 + TAU * h.progress / 0.8, 20, Color(1, 0.95, 0.7), 3.0)
