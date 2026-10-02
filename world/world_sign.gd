extends RefCounted

# A walk's name made OUT OF the walk, as loose things lying on the ground:
# fallen leaves on the neighbourhood path, cut flowers from La Rambla's
# stalls, a flowerbed in El Parc, heaped sand on the passeig, puddles in El
# Diluvi, fruit tipped out at El Mercat, sticks in the woods, traffic cones at
# the works, chestnuts at the Castanyada, torch-cut plate at the scrapyard,
# trencadis on the terraces, soap suds at the dawn clean-up - and in snow,
# whatever the walk, her own paw prints.
#
# The pieces are physical, and the walk starts right on top of them: the dog,
# the human and the rope shove, roll and scatter them, cones topple, suds
# pop, planted flowers spring back, sand scuffs flat, puddles ring. They stay
# where they end up, so you come home past whatever you did to the name.
#
# Nothing here pushes back: pieces never touch the dog, the human or the rope
# (the behaviour snapshot does not change), and all the noise is a hash of
# the piece index, so a name lies the same way every run and every shot.
#
# The letters come from world/sign_letters.gd as strokes; a material is a
# rule for what goes along a stroke and how it behaves.

const Letters := preload("res://world/sign_letters.gd")

# the material per walk; a walk not listed keeps main.gd's drawn styles
const MATERIALS := {
	"barri": "leaves", "street": "carnations", "park": "flowerbed", "beach": "sand",
	"rain": "puddle", "market": "fruit", "trail": "sticks", "site": "cones",
	"spook": "chestnuts", "scrap": "plate", "guell": "trencadis", "neteja": "suds",
}
# the colour a material's gloss, the line under the name, is written in
const GLOSS := {
	"leaves": Color(0.40, 0.30, 0.18, 0.85), "carnations": Color(0.96, 0.93, 0.86, 0.8),
	"flowerbed": Color(0.26, 0.34, 0.18, 0.85), "sand": Color(0.48, 0.42, 0.32, 0.85),
	"puddle": Color(0.80, 0.86, 0.92, 0.75), "fruit": Color(0.96, 0.92, 0.84, 0.85),
	"sticks": Color(0.36, 0.28, 0.18, 0.85), "cones": Color(0.96, 0.94, 0.88, 0.85),
	"chestnuts": Color(0.96, 0.84, 0.62, 0.85), "plate": Color(0.86, 0.78, 0.66, 0.8),
	"trencadis": Color(0.14, 0.30, 0.62, 0.85), "suds": Color(0.94, 0.97, 1.0, 0.8),
	"prints": Color(0.50, 0.56, 0.70, 0.8),
}

# How each material moves. spacing: piece pitch along a stroke, in cap
# heights; r: contact radius; drag: how fast a shove dies (per second);
# take: how much of a body's speed a piece picks up; spring: pull back to
# where it was laid (planted things); fixed: laid in, does not move at all.
const FEEL := {
	"leaves": {"spacing": 0.12, "r": 0.085, "drag": 5.0, "take": 1.1, "spin": 5.0},
	"carnations": {"spacing": 0.15, "r": 0.09, "drag": 4.0, "take": 0.9, "spin": 3.0},
	"flowerbed": {"spacing": 0.075, "r": 0.06, "drag": 7.0, "take": 0.8, "spring": 14.0},
	"sand": {"spacing": 0.085, "r": 0.075, "drag": 9.0, "take": 0.35, "scuff": true},
	"fruit": {"spacing": 0.14, "r": 0.075, "drag": 0.9, "take": 1.2, "roll": true},
	"sticks": {"spacing": 0.34, "r": 0.04, "drag": 6.0, "take": 0.7, "spin": 2.0, "segment": true},
	"cones": {"spacing": 0.34, "r": 0.14, "drag": 3.2, "take": 0.9, "spin": 2.0, "topple": true},
	"chestnuts": {"spacing": 0.14, "r": 0.08, "drag": 1.3, "take": 1.1, "roll": true},
	"plate": {"spacing": 0.5, "r": 0.09, "drag": 9.0, "take": 0.35, "spin": 1.0, "segment": true},
	"suds": {"spacing": 0.055, "r": 0.05, "drag": 3.0, "take": 1.4, "pop": true},
	"puddle": {"fixed": true, "splash": true},
	"trencadis": {"fixed": true},
	"prints": {"fixed": true},
}

const TOPPLE_SPEED := 150.0  # a cone hit harder than this goes over
# the rope brushes things aside rather than sweeping them up: this much of a
# body's shove
const ROPE_TAKE := 0.3
# a body kicks things to the side rather than pushing them along in front:
# how much of the push is turned sideways, away from the way it is going
const KICK_ASIDE := 1.4
const REST := 3.0            # below this speed a piece is lying still


static func material_for(lvl: String, weather: String) -> String:
	if weather == "snow":
		return "prints"
	return String(MATERIALS.get(lvl, ""))


# deterministic noise in 0..1 for piece i of the name with this key
static func _h(i: int, key: float, salt := 0.0) -> float:
	var n := sin(float(i) * 12.9898 + key * 78.233 + salt * 37.719) * 43758.5453
	return n - floorf(n)


static func _j(i: int, key: float, salt: float, amp: float) -> Vector2:
	return Vector2(_h(i, key, salt) - 0.5, _h(i, key, salt + 1.3) - 0.5) * 2.0 * amp


# A sign: `txt` centred on `at`, cap height `h`, fitted to `max_w`, in `mat`.
static func build(txt: String, at: Vector2, h: float, mat: String, key: float, max_w: float) -> Dictionary:
	var lay: Array = Letters.layout(txt, at, h, max_w)
	var lines: Array = lay[0]
	h = float(lay[1])
	var feel: Dictionary = FEEL.get(mat, {"fixed": true})
	var sign := {"txt": txt, "mat": mat, "lines": lines, "h": h, "key": key, "pieces": [], "rings": [],
		"feel": feel, "top": at.y - h * 1.3, "bottom": at.y + h * 0.5, "moving": false}
	if bool(feel.get("fixed", false)):
		return sign
	var pieces: Array = sign.pieces
	var sp: float = float(feel.spacing) * h
	var n := 0
	if bool(feel.get("segment", false)):
		# a stick or a plate per stretch of stroke, overlapping its
		# neighbours a little the way things laid by hand do
		for pl: PackedVector2Array in lines:
			var pts := Letters.points([pl], sp)
			for i in range(1, pts.size()):
				var a := pts[i - 1] + _j(n, key, 12.0, h * 0.02)
				var b := pts[i] + _j(n, key, 13.0, h * 0.02)
				var d := b - a
				pieces.append(_piece(n, key, (a + b) * 0.5, float(feel.r) * h,
					{"len": d.length() * 1.2, "rot": d.angle()}))
				n += 1
		return sign
	for q in Letters.points(lines, sp):
		var jit := 0.0 if mat == "cones" else h * 0.025
		pieces.append(_piece(n, key, q + _j(n, key, 0.0, jit), float(feel.r) * h, {}))
		n += 1
	return sign


static func _piece(n: int, key: float, p: Vector2, r: float, extra: Dictionary) -> Dictionary:
	var pc := {"p": p, "home": p, "v": Vector2.ZERO, "rot": _h(n, key, 3.0) * TAU, "w": 0.0,
		"r": r, "var": _h(n, key, 2.0), "up": true, "size": 1.0, "alive": true, "len": 0.0}
	pc.merge(extra, true)
	return pc


# One step. bodies: [[position, velocity, radius], ...]; rope: the leash's
# points with their velocities, [[p, v], ...]. Returns the number of cones
# knocked over this step, so main can clonk.
static func tick(sign: Dictionary, bodies: Array, rope: Array, dt: float, t: float) -> int:
	var feel: Dictionary = sign.feel
	var toppled := 0
	if bool(feel.get("splash", false)):
		_tick_splash(sign, bodies, dt, t)
		return 0
	if bool(feel.get("fixed", false)):
		return 0
	# nothing near: nothing moves, and nothing to do
	var near := false
	for b: Array in bodies:
		var bp: Vector2 = b[0]
		if bp.y > float(sign.top) - 80.0 and bp.y < float(sign.bottom) + 80.0:
			near = true
	if not near and not bool(sign.moving):
		return 0
	var take: float = float(feel.take)
	var drag: float = float(feel.drag)
	var spring: float = float(feel.get("spring", 0.0))
	var seg: bool = bool(feel.get("segment", false))
	var moving := false
	var hits: Array = []
	for b: Array in bodies:
		hits.append(b)
	if near:
		for rp: Array in rope:
			hits.append([rp[0], rp[1], 3.0, true])
	for pc: Dictionary in sign.pieces:
		if not bool(pc.alive):
			continue
		var p: Vector2 = pc.p
		for b: Array in hits:
			var bp: Vector2 = b[0]
			var bv: Vector2 = b[1]
			var br: float = float(b[2])
			var cp := p
			if seg:
				cp = _closest_on(pc, bp)
			var d := cp - bp
			var reach: float = br + float(pc.r)
			if d.length_squared() >= reach * reach:
				continue
			var dist := maxf(0.001, d.length())
			var nrm := d / dist
			var is_rope: bool = b.size() > 3
			var k: float = take * (ROPE_TAKE if is_rope else 1.0)
			if not is_rope and bv.length() > 1.0:
				# kicked aside: turn the push away from the line of travel,
				# to whichever side the piece already is (or its own, dead ahead)
				var fwd := bv.normalized()
				var lat := nrm - fwd * nrm.dot(fwd)
				if lat.length() < 0.2:
					lat = fwd.orthogonal() * (1.0 if float(pc["var"]) > 0.5 else -1.0)
				nrm = (nrm + lat.normalized() * KICK_ASIDE).normalized()
			if bool(feel.get("pop", false)):
				pc.alive = false
				sign.rings.append({"p": p, "t": t, "big": false})
				break
			# out of the way, then carried along with whatever hit it
			# out of the way round the side, so a body walks through a letter
			# rather than shoving a pile of it along in front
			p += nrm * (reach - dist) * (0.5 if spring > 0.0 or is_rope else 1.2)
			var vn: float = maxf(0.0, (bv - (pc.v as Vector2)).dot(d / dist))
			if vn > 0.0:
				pc.v = (pc.v as Vector2) + nrm * vn * k * (1.0 if is_rope else 1.3)
				var sp: float = float(feel.get("spin", 0.0))
				if sp > 0.0:
					pc.w = float(pc.w) + (1.0 if nrm.cross(bv) > 0.0 else -1.0) * minf(bv.length(), 200.0) / 200.0 * sp
				if bool(feel.get("topple", false)) and bool(pc.up) and vn > TOPPLE_SPEED and not is_rope:
					pc.up = false
					pc.rot = bv.angle()
					toppled += 1
			if bool(feel.get("scuff", false)):
				# a heap of sand spreads and flattens under a paw
				pc.size = maxf(0.35, float(pc.size) - dt * 1.6)
		var v: Vector2 = pc.v
		if spring > 0.0:
			v += ((pc.home as Vector2) - p) * spring * dt
		v *= exp(-drag * dt)
		p += v * dt
		pc.w = float(pc.w) * exp(-drag * dt)
		pc.rot = float(pc.rot) + float(pc.w) * dt
		if bool(feel.get("roll", false)):
			# round things roll: the highlight turns with the distance covered
			pc.rot = float(pc.rot) + v.length() * dt / maxf(1.0, float(pc.r))
		if v.length() < REST and spring <= 0.0:
			v = Vector2.ZERO
		elif v.length() >= REST:
			moving = true
		pc.p = p
		pc.v = v
	sign.moving = moving
	_age_rings(sign, t)
	return toppled


static func _closest_on(pc: Dictionary, q: Vector2) -> Vector2:
	var half := Vector2.from_angle(float(pc.rot)) * float(pc.len) * 0.5
	var p: Vector2 = pc.p
	return Geometry2D.get_closest_point_to_segment(q, p - half, p + half)


static func _tick_splash(sign: Dictionary, bodies: Array, dt: float, t: float) -> void:
	# a puddle does not move, but anything running through it rings it
	var pts: PackedVector2Array = sign.get("splash_pts", PackedVector2Array())
	if pts.is_empty():
		pts = Letters.points(sign.lines, float(sign.h) * 0.08)
		sign.splash_pts = pts
	var reach := float(sign.h) * 0.12
	for b: Array in bodies:
		var bp: Vector2 = b[0]
		var bv: Vector2 = b[1]
		if bv.length() < 30.0 or bp.y < float(sign.top) - 20.0 or bp.y > float(sign.bottom) + 20.0:
			continue
		for q in pts:
			if q.distance_squared_to(bp) < reach * reach:
				var last := -1.0
				if not sign.rings.is_empty():
					last = float(sign.rings[sign.rings.size() - 1].t)
				if t - last > 0.12:
					sign.rings.append({"p": bp, "t": t, "big": true})
				break
	_age_rings(sign, t)


static func _age_rings(sign: Dictionary, t: float) -> void:
	var keep: Array = []
	for r: Dictionary in sign.rings:
		if t - float(r.t) < 0.8:
			keep.append(r)
	sign.rings = keep


# --- drawing ------------------------------------------------------------------

static func draw(c: Object, sign: Dictionary, t: float, light: Vector2) -> void:
	var h: float = sign.h
	var key: float = sign.key
	var lines: Array = sign.lines
	match String(sign.mat):
		"leaves":
			_leaves(c, sign, h)
		"carnations":
			_carnations(c, sign, h)
		"flowerbed":
			_stroke(c, lines, h * 0.28, Color(0.36, 0.26, 0.17))
			_stroke(c, lines, h * 0.19, Color(0.25, 0.42, 0.20))
			_flowerbed(c, sign, h)
		"sand":
			_sand(c, sign, h, light)
		"puddle":
			_puddle(c, lines, h, key, t, light)
		"fruit":
			_fruit(c, sign, h, light)
		"sticks":
			_sticks(c, sign, h)
		"cones":
			_cones(c, sign, h, light)
		"chestnuts":
			_chestnuts(c, sign, h, light)
		"plate":
			_plate(c, sign, h)
		"trencadis":
			_trencadis(c, lines, h, key)
		"suds":
			_stroke(c, lines, h * 0.26, Color(0.22, 0.26, 0.30, 0.3))
			_suds(c, sign, h, t)
		"prints":
			_prints(c, lines, h, light)
	for r: Dictionary in sign.rings:
		var age: float = (t - float(r.t)) / 0.8
		var rr: float = h * (0.05 + age * (0.3 if bool(r.big) else 0.12))
		c.draw_arc(r.p, rr, 0, TAU, 16, Color(0.9, 0.94, 1.0, 0.6 * (1.0 - age)), 1.5)


static func _stroke(c: Object, lines: Array, w: float, col: Color, off := Vector2.ZERO) -> void:
	# a thick stroke with round joints: segments, and a disc at every vertex
	for pl: PackedVector2Array in lines:
		for i in range(pl.size()):
			c.draw_circle(pl[i] + off, w * 0.5, col)
			if i > 0:
				c.draw_line(pl[i - 1] + off, pl[i] + off, col, w)


static func _pick(cols: Array, v: float) -> Color:
	return cols[int(v * float(cols.size())) % cols.size()]


static func _leaves(c: Object, sign: Dictionary, h: float) -> void:
	# plane-tree leaves raked into letters, browns and yellows, each turned
	# its own way
	var cols := [Color(0.78, 0.46, 0.16), Color(0.86, 0.66, 0.22), Color(0.62, 0.34, 0.14),
		Color(0.72, 0.56, 0.20), Color(0.55, 0.40, 0.18)]
	for pc: Dictionary in sign.pieces:
		c.draw_circle((pc.p as Vector2) + Vector2(1.5, 1.5), float(pc.r) * 0.85, Color(0, 0, 0, 0.12))
	for pc: Dictionary in sign.pieces:
		var col := _pick(cols, float(pc["var"]))
		var r: float = pc.r
		c.draw_set_transform(pc.p, float(pc.rot), Vector2(1.0, 0.55))
		c.draw_circle(Vector2.ZERO, r, col)
		c.draw_circle(Vector2(r * 0.45, 0), r * 0.6, col.lightened(0.08))
		c.draw_line(Vector2(-r * 1.2, 0), Vector2(r * 1.1, 0), col.darkened(0.35), 1.2)
		c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _carnations(c: Object, sign: Dictionary, h: float) -> void:
	# cut carnations from the flower stalls, laid in the letters: a stem, two
	# leaves, and a frilled head
	var cols := [Color(0.88, 0.16, 0.22), Color(0.96, 0.52, 0.64), Color(0.98, 0.96, 0.92),
		Color(0.94, 0.72, 0.20)]
	for pc: Dictionary in sign.pieces:
		var r: float = pc.r
		var dir := Vector2.from_angle(float(pc.rot))
		var p: Vector2 = pc.p
		c.draw_line(p, p - dir * r * 2.4, Color(0.30, 0.50, 0.24), 1.8)
		c.draw_line(p - dir * r * 1.2, p - dir * r * 1.2 + dir.rotated(0.9) * r * 0.9, Color(0.30, 0.50, 0.24), 1.4)
	for pc: Dictionary in sign.pieces:
		var r: float = pc.r
		var p: Vector2 = pc.p
		var col := _pick(cols, float(pc["var"]))
		c.draw_circle(p + Vector2(1.2, 1.5), r * 0.8, Color(0, 0, 0, 0.18))
		for k in range(6):
			var a := float(pc.rot) + TAU * float(k) / 6.0
			c.draw_circle(p + Vector2.from_angle(a) * r * 0.45, r * 0.45, col)
		c.draw_circle(p, r * 0.4, col.darkened(0.2))


static func _flowerbed(c: Object, sign: Dictionary, h: float) -> void:
	# the planting in a municipal flowerbed; shoved plants spring back
	var cols := [Color(0.92, 0.22, 0.24), Color(0.98, 0.84, 0.26), Color(0.98, 0.96, 0.92),
		Color(0.84, 0.40, 0.72)]
	for pc: Dictionary in sign.pieces:
		c.draw_circle(pc.p, float(pc.r) * 0.8, Color(0.33, 0.55, 0.26))
	for pc: Dictionary in sign.pieces:
		if float(pc["var"]) < 0.35:
			continue
		var p: Vector2 = (pc.p as Vector2) + Vector2.from_angle(float(pc.rot)) * float(pc.r) * 0.3
		c.draw_circle(p, h * 0.03, _pick(cols, fmod(float(pc["var"]) * 7.3, 1.0)))
		c.draw_circle(p, h * 0.011, Color(0.98, 0.84, 0.3))


static func _sand(c: Object, sign: Dictionary, h: float, light: Vector2) -> void:
	# the letters heaped up in sand dug from beside them: the damp dark of
	# the trench, then each heap a mound shaded away from the light. A paw
	# spreads a heap flat.
	_stroke(c, sign.lines, h * 0.34, Color(0.60, 0.50, 0.34, 0.55))
	for pc: Dictionary in sign.pieces:
		var r: float = float(pc.r) * (1.4 - 0.4 * float(pc.size))
		c.draw_circle((pc.p as Vector2) + light * r * 0.4 * float(pc.size), r, Color(0.50, 0.40, 0.26, 0.7))
	for pc: Dictionary in sign.pieces:
		var s: float = pc.size
		var r: float = float(pc.r) * (1.4 - 0.4 * s)
		c.draw_circle(pc.p, r * 0.92, Color(0.94, 0.86, 0.66).lerp(Color(0.80, 0.70, 0.52), 1.0 - s))
		c.draw_circle((pc.p as Vector2) - light * r * 0.3 * s, r * 0.55, Color(0.98, 0.93, 0.80, 0.8 * s))


static func _puddle(c: Object, lines: Array, h: float, key: float, t: float, light: Vector2) -> void:
	# the rain has pooled in the letters: dark water, the sky along one edge,
	# and drops landing in it
	_stroke(c, lines, h * 0.23, Color(0.18, 0.21, 0.26, 0.5), Vector2(0, 1.5))
	_stroke(c, lines, h * 0.19, Color(0.34, 0.40, 0.48, 0.88))
	_stroke(c, lines, h * 0.06, Color(0.74, 0.82, 0.90, 0.45), -light * h * 0.04)
	var pts := Letters.points(lines, h * 0.5)
	for i in range(pts.size()):
		var ph := fmod(t * 0.7 + _h(i, key, 9.0), 1.0)
		c.draw_arc(pts[i], h * (0.02 + ph * 0.09), 0, TAU, 14, Color(0.85, 0.9, 0.95, 0.45 * (1.0 - ph)), 1.2)


static func _fruit(c: Object, sign: Dictionary, h: float, light: Vector2) -> void:
	# a crate's worth tipped out along the letters: oranges, lemons, apples.
	# They roll, and a good shove sends one a long way.
	var kinds := [[Color(0.96, 0.56, 0.12), 1.0], [Color(0.96, 0.86, 0.26), 0.8],
		[Color(0.78, 0.14, 0.12), 0.95], [Color(0.52, 0.72, 0.20), 0.95]]
	for pc: Dictionary in sign.pieces:
		c.draw_circle((pc.p as Vector2) + Vector2(2, 2.5), float(pc.r), Color(0, 0, 0, 0.2))
	for pc: Dictionary in sign.pieces:
		var kind: Array = kinds[int(float(pc["var"]) * kinds.size()) % kinds.size()]
		var col: Color = kind[0]
		var r: float = float(pc.r) * float(kind[1])
		var p: Vector2 = pc.p
		c.draw_circle(p, r, col)
		c.draw_circle(p - light * r * 0.35, r * 0.32, col.lightened(0.35))
		# the stalk turns as it rolls
		var sd := Vector2.from_angle(float(pc.rot))
		c.draw_line(p + sd * r * 0.55, p + sd * r * 0.95, Color(0.30, 0.45, 0.18), 1.6)


static func _sticks(c: Object, sign: Dictionary, h: float) -> void:
	# twigs laid end to end along the strokes, the odd one forked
	for pc: Dictionary in sign.pieces:
		var half := Vector2.from_angle(float(pc.rot)) * float(pc.len) * 0.5
		var p: Vector2 = pc.p
		var col := Color(0.70, 0.60, 0.46).lerp(Color(0.80, 0.72, 0.58), float(pc["var"]))
		c.draw_line(p - half + Vector2(2, 2), p + half + Vector2(2, 2), Color(0, 0, 0, 0.3), h * 0.09)
		c.draw_line(p - half, p + half, Color(0.26, 0.19, 0.12), h * 0.1)
		c.draw_line(p - half * 0.98, p + half * 0.98, col, h * 0.07)
		c.draw_line(p - half * 0.9 - Vector2(0, h * 0.012), p + half * 0.9 - Vector2(0, h * 0.012), col.lightened(0.3), h * 0.02)
		if float(pc["var"]) > 0.7:
			c.draw_line(p, p + half.rotated(0.7) * 0.7, Color(0.26, 0.19, 0.12), h * 0.05)
			c.draw_line(p, p + half.rotated(0.7) * 0.7, col, h * 0.03)


static func _cones(c: Object, sign: Dictionary, h: float, light: Vector2) -> void:
	# traffic cones set out in letters. From above an upright cone is a
	# square foot, an orange ring and a white band; knocked over, it lies on
	# its side pointing the way it was hit.
	for pc: Dictionary in sign.pieces:
		var p: Vector2 = pc.p
		var r: float = pc.r
		if bool(pc.up):
			c.draw_circle(p + light * r * 0.9, r * 0.9, Color(0, 0, 0, 0.18))
			c.draw_set_transform(p, float(pc.rot) * 0.1, Vector2.ONE)
			c.draw_rect(Rect2(-r, -r, r * 2.0, r * 2.0), Color(0.16, 0.16, 0.17))
			c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			c.draw_circle(p, r * 0.8, Color(0.96, 0.42, 0.10))
			c.draw_arc(p, r * 0.5, 0, TAU, 14, Color(0.96, 0.96, 0.94), r * 0.2)
			c.draw_circle(p, r * 0.22, Color(0.98, 0.56, 0.20))
		else:
			var dir := Vector2.from_angle(float(pc.rot))
			var side := dir.orthogonal()
			var base := p - dir * r * 1.1
			var tip := p + dir * r * 1.3
			c.draw_colored_polygon(PackedVector2Array([base + side * r * 0.85 + Vector2(2, 2),
				tip + Vector2(2, 2), base - side * r * 0.85 + Vector2(2, 2)]), Color(0, 0, 0, 0.18))
			c.draw_colored_polygon(PackedVector2Array([base + side * r * 0.85, tip, base - side * r * 0.85]),
				Color(0.96, 0.42, 0.10))
			var m0 := base.lerp(tip, 0.35)
			var m1 := base.lerp(tip, 0.55)
			c.draw_colored_polygon(PackedVector2Array([m0 + side * r * 0.56, m1 + side * r * 0.39,
				m1 - side * r * 0.39, m0 - side * r * 0.56]), Color(0.96, 0.96, 0.94))
			c.draw_line(base + side * r, base - side * r, Color(0.16, 0.16, 0.17), r * 0.35)


static func _chestnuts(c: Object, sign: Dictionary, h: float, light: Vector2) -> void:
	# roast chestnuts from the stall, set out in letters
	for pc: Dictionary in sign.pieces:
		c.draw_circle((pc.p as Vector2) + Vector2(1.5, 2.0), float(pc.r), Color(0, 0, 0, 0.22))
	for pc: Dictionary in sign.pieces:
		var p: Vector2 = pc.p
		var r: float = pc.r
		# a pale paper-cone rim, so a dark nut still reads on the dark ground
		# of a festival night
		c.draw_circle(p, r * 1.28, Color(0.98, 0.88, 0.66, 0.95))
		c.draw_circle(p, r, Color(0.46, 0.24, 0.12))
		# the pale base turns with the nut as it rolls
		c.draw_circle(p + Vector2.from_angle(float(pc.rot)) * r * 0.5, r * 0.55, Color(0.78, 0.64, 0.44))
		c.draw_circle(p - light * r * 0.4, r * 0.3, Color(0.78, 0.52, 0.30))


static func _plate(c: Object, sign: Dictionary, h: float) -> void:
	# letters cut from rusted sheet with a torch: a scorched edge, rust on the
	# face, and a rivet at each end
	for pc: Dictionary in sign.pieces:
		var half := Vector2.from_angle(float(pc.rot)) * float(pc.len) * 0.5
		var p: Vector2 = pc.p
		c.draw_line(p - half + Vector2(2, 2), p + half + Vector2(2, 2), Color(0, 0, 0, 0.25), h * 0.2)
		c.draw_line(p - half, p + half, Color(0.20, 0.12, 0.08), h * 0.2)
		c.draw_line(p - half * 0.97, p + half * 0.97, Color(0.54, 0.29, 0.15), h * 0.15)
		c.draw_circle(p + half * 0.3, h * 0.025, Color(0.70, 0.40, 0.18) if float(pc["var"]) > 0.5 else Color(0.38, 0.20, 0.11))
		for e in [-0.8, 0.8]:
			c.draw_circle(p + half * e, h * 0.03, Color(0.62, 0.62, 0.60))


static func _trencadis(c: Object, lines: Array, h: float, key: float) -> void:
	# trencadis: broken tile set in white mortar, cobalt and turquoise and
	# yellow, every shard its own odd shape. Set in, so it stays.
	_stroke(c, lines, h * 0.24, Color(0.90, 0.88, 0.82))
	var pts := Letters.points(lines, h * 0.075)
	var cols := [Color(0.12, 0.30, 0.70), Color(0.18, 0.62, 0.70), Color(0.34, 0.62, 0.30),
		Color(0.96, 0.80, 0.24), Color(0.92, 0.50, 0.18), Color(0.97, 0.96, 0.92)]
	for i in range(pts.size()):
		var poly := PackedVector2Array()
		var sides := 3 + int(_h(i, key, 27.0) * 3.0)
		var rot := _h(i, key, 28.0) * TAU
		for k in range(sides):
			var a := rot + TAU * float(k) / float(sides)
			poly.append(pts[i] + Vector2(cos(a), sin(a)) * h * (0.045 + _h(i * 7 + k, key, 29.0) * 0.035))
		c.draw_colored_polygon(poly, _pick(cols, _h(i, key, 26.0)))


static func _suds(c: Object, sign: Dictionary, h: float, t: float) -> void:
	# soap foam after the sweeper, in bubbles; run through and they pop
	for pc: Dictionary in sign.pieces:
		if not bool(pc.alive):
			continue
		var rr: float = float(pc.r) * (0.5 + float(pc["var"])) * (0.9 + 0.1 * sin(t * 1.5 + float(pc.rot)))
		c.draw_circle(pc.p, rr, Color(0.96, 0.98, 1.0, 0.72))
		c.draw_circle((pc.p as Vector2) - Vector2(rr, rr) * 0.35, rr * 0.3, Color(1, 1, 1, 0.9))


static func _prints(c: Object, lines: Array, h: float, light: Vector2) -> void:
	# snow: she has walked the letters out herself, left and right of the line
	var n := 0
	for pl: PackedVector2Array in lines:
		var pts := Letters.points([pl], h * 0.17)
		for i in range(pts.size()):
			n += 1
			var dir := Vector2.DOWN
			if pts.size() > 1:
				var a := pts[maxi(0, i - 1)]
				var b := pts[mini(pts.size() - 1, i + 1)]
				if a.distance_to(b) > 0.1:
					dir = (b - a).normalized()
			var side := 1.0 if n % 2 == 0 else -1.0
			_paw(c, pts[i] + dir.orthogonal() * side * h * 0.05, dir, h * 0.075, light)


static func _paw(c: Object, at: Vector2, dir: Vector2, s: float, light: Vector2) -> void:
	var hollow := Color(0.40, 0.46, 0.60, 0.85)
	var lip := Color(1, 1, 1, 0.8)
	var side := dir.orthogonal()
	c.draw_circle(at + light * s * 0.25, s * 0.55, lip)
	c.draw_circle(at, s * 0.5, hollow)
	for k in range(4):
		var off := dir * s * 0.75 + side * s * (float(k) - 1.5) * 0.42 - dir * absf(float(k) - 1.5) * s * 0.18
		c.draw_circle(at + off + light * s * 0.12, s * 0.22, lip)
		c.draw_circle(at + off, s * 0.19, hollow)
