extends RefCounted

# A walk's name made OUT OF the walk, as loose things lying on the ground:
# fallen leaves on the neighbourhood path, cut flowers from La Rambla's
# stalls, a flowerbed in El Parc, heaped sand on the passeig, puddles in El
# Diluvi, fruit tipped out at El Mercat, sticks in the woods, traffic cones at
# the works, chestnuts at the Castanyada, torch-cut plate at the scrapyard,
# trencadis on the terraces, soap suds at the dawn clean-up, sunflower seed
# scarf along the letters on match day, dark setts laid into the alley's paving, lights set into the
# concourse floor that go dark under whoever stands on them,
# river pebbles by the Besòs, the cactus garden on Montjuïc, mooring rope on
# the wharf, palm fronds in the square, dog biscuits at the vet, fairground
# bulbs on Tibidabo, pine cones on the hillside track, tennis balls on the
# first walk - and in snow, whatever the walk, her own paw prints.
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
	"partit": "scarf", "oldtown": "setts", "station": "studs", "besos": "pebbles",
	"montjuic": "cactus", "port": "rope", "reial": "fronds", "vet": "biscuits",
	"tibidabo": "bulbs", "aigues": "pinecones", "horta": "topiary", "llevant": "shells", "raval": "fronds", "tutorial": "balls",
}
# What lies under a walk's pieces so they read on its ground by brightness, not
# colour alone: a soft bed of light under dark-on-dark, of shade under
# light-on-light. Walks not listed need none.
const BEDS := {
	"spook": Color(0.98, 0.88, 0.66, 0.44), "partit": Color(0.96, 0.94, 0.88, 0.18),
	"neteja": Color(0.10, 0.12, 0.16, 0.34), "rain": Color(0.06, 0.08, 0.12, 0.24),
	"trail": Color(0.12, 0.08, 0.04, 0.18), "tibidabo": Color(0.04, 0.04, 0.08, 0.30),
}
# A name that will not fit on one line at least this tall is broken in two at
# the space nearest its middle, rather than shrunk.
const NAME_MIN_H := 50.0
const LINE_PITCH := 1.5
const SPLIT_MIN := 4             # letters either side of a break
# The pieces fall into place when a sign is laid out: left to right over
# REVEAL_SWEEP seconds, each landing in REVEAL_DROP from DROP_H cap heights up.
const REVEAL_SWEEP := 0.55
const REVEAL_DROP := 0.38
const DROP_H := 0.9

# How each material moves. spacing: piece pitch along a stroke, in cap
# heights; r: contact radius; drag: how fast a shove dies (per second);
# take: how much of a body's speed a piece picks up; spring: pull back to
# where it was laid (planted things); fixed: laid in, does not move at all.
const FEEL := {
	"leaves": {"spacing": 0.12, "r": 0.085, "drag": 5.0, "take": 1.1, "spin": 5.0},
	"pipes": {"spacing": 0.07, "r": 0.05, "drag": 6.0, "take": 1.3, "spin": 6.0},
	"carnations": {"spacing": 0.15, "r": 0.09, "drag": 4.0, "take": 0.9, "spin": 3.0},
	"flowerbed": {"spacing": 0.075, "r": 0.06, "drag": 7.0, "take": 0.8, "spring": 14.0},
	"sand": {"spacing": 0.085, "r": 0.075, "drag": 9.0, "take": 0.35, "scuff": true},
	"fruit": {"spacing": 0.14, "r": 0.075, "drag": 0.9, "take": 1.2, "roll": true},
	"sticks": {"spacing": 0.34, "r": 0.04, "drag": 6.0, "take": 0.7, "spin": 2.0, "segment": true},
	"cones": {"spacing": 0.3, "r": 0.12, "gap": 2.4, "drag": 3.2, "take": 0.9, "spin": 2.0, "topple": true},
	"chestnuts": {"spacing": 0.14, "r": 0.08, "drag": 1.3, "take": 1.1, "roll": true},
	"plate": {"spacing": 0.5, "r": 0.09, "drag": 9.0, "take": 0.35, "spin": 1.0, "segment": true},
	"suds": {"spacing": 0.055, "r": 0.05, "drag": 3.0, "take": 1.4, "pop": true},
	"pegs": {"spacing": 0.13, "r": 0.065, "drag": 5.0, "take": 1.1, "spin": 5.0},
	"tickets": {"spacing": 0.13, "r": 0.07, "drag": 4.0, "take": 1.3, "spin": 6.0},
	"pebbles": {"spacing": 0.11, "r": 0.07, "drag": 1.8, "take": 1.0, "roll": true},
	"cactus": {"spacing": 0.16, "r": 0.085, "drag": 7.0, "take": 0.6, "spring": 12.0},
	"scarf": {"spacing": 0.24, "r": 0.06, "drag": 7.0, "take": 0.6, "spin": 1.2, "segment": true},
	"rope": {"spacing": 0.2, "r": 0.05, "drag": 7.0, "take": 0.6, "spin": 1.5, "segment": true},
	"fronds": {"spacing": 0.3, "r": 0.06, "drag": 6.0, "take": 0.8, "spin": 2.5, "segment": true},
	"biscuits": {"spacing": 0.16, "r": 0.075, "drag": 4.0, "take": 1.1, "spin": 4.0},
	"pinecones": {"spacing": 0.15, "r": 0.08, "drag": 2.2, "take": 1.0, "roll": true},
	"shells": {"spacing": 0.14, "r": 0.075, "drag": 3.5, "take": 1.0, "spin": 3.0},
	"balls": {"spacing": 0.15, "r": 0.075, "drag": 0.9, "take": 1.2, "roll": true},
	"bulbs": {"fixed": true},
	"setts": {"fixed": true},
	"topiary": {"fixed": true},
	"studs": {"fixed": true, "lights": true},
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


# the space between letters for a material: fat pieces want air between
# letters, or two letters read as one
static func gap_for(mat: String) -> float:
	return float((FEEL.get(mat, {}) as Dictionary).get("gap", Letters.GAP))


static func material_for(lvl: String, weather: String) -> String:
	if weather == "snow":
		return "prints"
	return String(MATERIALS.get(lvl, ""))


# A walk's name: at full size on one line if it fits, else in two lines when
# one line would have to shrink below NAME_MIN_H. The first line keeps the
# top a one-line name of height `h` on baseline `at` would have, and a second
# hangs below it; `w` is the widest line.
static func build_name(txt: String, at: Vector2, h: float, mat: String, key: float, max_w: float, bed := Color(0, 0, 0, 0)) -> Dictionary:
	var gap := gap_for(mat)
	var up := txt.to_upper()
	var w1 := Letters.width(up, h, gap)
	var h1 := h if w1 <= max_w else h * max_w / w1
	var best := -1
	# never leave an article on a line of its own: EL / BOSC reads as two words
	if h1 < NAME_MIN_H and " " in up:
		var mid := float(up.length()) * 0.5
		for i in range(up.length()):
			if up.substr(i, 1) != " " or i < SPLIT_MIN or up.length() - i - 1 < SPLIT_MIN:
				continue
			if best < 0 or absf(float(i) - mid) < absf(float(best) - mid):
				best = i
	var top := at.y - h
	var sign := {}
	if best < 0:
		sign = build(txt, Vector2(at.x, top + h1), h1, mat, key, max_w)
		sign.w = Letters.width(up, float(sign.h), gap)
		sign.baseline = top + h1
	else:
		var a := up.substr(0, best)
		var b := up.substr(best + 1)
		var wa := Letters.width(a, h, gap)
		var wb := Letters.width(b, h, gap)
		var h2 := minf(h, h * max_w / maxf(wa, wb))
		var pitch := h2 * LINE_PITCH
		var la: Array = Letters.layout(a, Vector2(at.x, top + h2), h2, INF, gap)
		var lb: Array = Letters.layout(b, Vector2(at.x, top + h2 + pitch), h2, INF, gap)
		var lines: Array = []
		lines.append_array(la[0])
		lines.append_array(lb[0])
		sign = _from_lines(txt, mat, lines, h2, key, top - h2 * 0.3, top + h2 + pitch + h2 * 0.5)
		sign.w = Letters.width(a if wa > wb else b, h2, gap)
		sign.baseline = top + h2 + pitch
	sign.bed = bed
	return sign


# deterministic noise in 0..1 for piece i of the name with this key
static func _h(i: int, key: float, salt := 0.0) -> float:
	var n := sin(float(i) * 12.9898 + key * 78.233 + salt * 37.719) * 43758.5453
	return n - floorf(n)


static func _j(i: int, key: float, salt: float, amp: float) -> Vector2:
	return Vector2(_h(i, key, salt) - 0.5, _h(i, key, salt + 1.3) - 0.5) * 2.0 * amp


# A sign: `txt` centred on `at`, cap height `h`, fitted to `max_w`, in `mat`.
static func build(txt: String, at: Vector2, h: float, mat: String, key: float, max_w: float) -> Dictionary:
	var lay: Array = Letters.layout(txt, at, h, max_w, gap_for(mat))
	return _from_lines(txt, mat, lay[0], float(lay[1]), key, at.y - float(lay[1]) * 1.3, at.y + float(lay[1]) * 0.5)


static func _from_lines(txt: String, mat: String, lines: Array, h: float, key: float, top: float, bottom: float) -> Dictionary:
	var feel: Dictionary = FEEL.get(mat, {"fixed": true})
	var sign := {"txt": txt, "mat": mat, "lines": lines, "h": h, "key": key, "pieces": [], "rings": [],
		"feel": feel, "top": top, "bottom": bottom, "moving": false, "born": -100.0}
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
					{"len": d.length() * 1.2, "rot": d.angle(), "first": i == 1, "last": i == pts.size() - 1}))
				n += 1
		return sign
	var laid := PackedVector2Array()
	for q in Letters.points(lines, sp):
		# cones are fat: where two strokes meet, or a stroke's end lands just
		# past its last cone, one cone stands for both, or the letter clots
		if mat == "cones":
			var near := false
			for o in laid:
				near = near or o.distance_to(q) < sp * 0.7
			if near:
				continue
			laid.append(q)
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
	if bool(feel.get("lights", false)):
		_tick_lights(sign, bodies, rope, dt, t)
		return 0
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
	# whether anything drawn changed: the sign's canvas (world/sign_layer.gd)
	# redraws when `rev` moves on, and only then
	var changed := false
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
		var rot0: float = pc.rot
		var size0: float = pc.size
		var up0: bool = pc.up
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
		changed = changed or p != (pc.p as Vector2) or float(pc.rot) != rot0 or float(pc.size) != size0 \
				or bool(pc.up) != up0 or not bool(pc.alive)
		pc.p = p
		pc.v = v
	sign.moving = moving
	if changed:
		sign.rev = int(sign.get("rev", 0)) + 1
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


# Lights in the floor: each one goes dark while anyone, or the leash, lies
# over it, and comes back up when they move on, with a flare as it does.
const STUD_PITCH := 0.12      # cap heights between lights
const STUD_DIM := 14.0        # how fast a covered light goes out (per second)
const STUD_GLOW := 5.0        # and comes back
static func stud_points(sign: Dictionary) -> PackedVector2Array:
	var pts: PackedVector2Array = sign.get("stud_pts", PackedVector2Array())
	if pts.is_empty():
		pts = Letters.points(sign.lines, float(sign.h) * STUD_PITCH)
		sign.stud_pts = pts
		var cover := PackedFloat32Array()
		cover.resize(pts.size())
		sign.cover = cover
	return pts


static func _tick_lights(sign: Dictionary, bodies: Array, rope: Array, dt: float, t: float) -> void:
	var pts := stud_points(sign)
	var cover: PackedFloat32Array = sign.cover
	var near := false
	for b: Array in bodies:
		var bp: Vector2 = b[0]
		near = near or (bp.y > float(sign.top) - 60.0 and bp.y < float(sign.bottom) + 60.0)
	var changed := false
	var hits: Array = []
	if near:
		hits.append_array(bodies)
		for rp: Array in rope:
			hits.append([rp[0], rp[1], 3.0])
	for i in range(pts.size()):
		var on := false
		for b: Array in hits:
			var reach := float(b[2]) + float(sign.h) * 0.04
			if (b[0] as Vector2).distance_squared_to(pts[i]) < reach * reach:
				on = true
				break
		var c0 := cover[i]
		var c1 := minf(1.0, c0 + STUD_DIM * dt) if on else maxf(0.0, c0 - STUD_GLOW * dt)
		if c0 > 0.5 and c1 <= 0.5:
			sign.rings.append({"p": pts[i], "t": t, "big": false})
		if c1 != c0:
			cover[i] = c1
			changed = true
	sign.cover = cover
	if changed:
		sign.rev = int(sign.get("rev", 0)) + 1
	_age_rings(sign, t)


static func _age_rings(sign: Dictionary, t: float) -> void:
	var keep: Array = []
	for r: Dictionary in sign.rings:
		if t - float(r.t) < 0.8:
			keep.append(r)
	sign.rings = keep


# --- drawing ------------------------------------------------------------------

# Whether the sign's picture changes with time alone: puddles shimmer, suds
# breathe, bulbs chase, rings fade, and a sign just laid out is still falling
# into place. Anything else looks the same until a piece moves.
static func animated(sign: Dictionary, t: float) -> bool:
	var mat := String(sign.mat)
	return mat == "puddle" or mat == "suds" or mat == "bulbs" or mat == "studs" or not (sign.rings as Array).is_empty() \
		or revealing(sign, t)


static func revealing(sign: Dictionary, t: float) -> bool:
	return t - float(sign.get("born", -100.0)) < REVEAL_SWEEP + REVEAL_DROP + 0.1


# overshoots a little and settles: a thing dropped onto the ground
static func _ease_back(u: float) -> float:
	var k := 1.6
	var v := u - 1.0
	return 1.0 + (k + 1.0) * v * v * v + k * v * v


static func draw(c: Object, sign: Dictionary, t: float, light: Vector2) -> void:
	var h: float = sign.h
	var key: float = sign.key
	var lines: Array = sign.lines
	var bed: Color = sign.get("bed", Color(0, 0, 0, 0))
	if bed.a > 0.0:
		_stroke(c, lines, h * 0.42, bed)
	# falling into place: each piece drawn from above its spot, landing in turn
	# left to right; where the pieces lie is not touched
	var held: Array = []
	if revealing(sign, t) and not (sign.pieces as Array).is_empty():
		var age := t - float(sign.born)
		var x0 := INF
		var x1 := -INF
		for pc: Dictionary in sign.pieces:
			x0 = minf(x0, (pc.home as Vector2).x)
			x1 = maxf(x1, (pc.home as Vector2).x)
		for i in range(sign.pieces.size()):
			var pc: Dictionary = sign.pieces[i]
			held.append([pc.p, pc.r, pc.len])
			var f := ((pc.home as Vector2).x - x0) / maxf(1.0, x1 - x0)
			var u := clampf((age - f * REVEAL_SWEEP - _h(i, key, 41.0) * 0.06) / REVEAL_DROP, 0.0, 1.0)
			var e := _ease_back(u)
			pc.p = (pc.p as Vector2) + Vector2((_h(i, key, 42.0) - 0.5) * h * 0.3, -h * DROP_H) * (1.0 - e)
			var grow := clampf(u * 1.8, 0.0, 1.0)
			pc.r = float(pc.r) * maxf(0.01, grow)
			pc.len = float(pc.len) * grow
	match String(sign.mat):
		"leaves":
			_leaves(c, sign, h)
		"pipes":
			_pipes(c, sign, h)
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
		"pegs":
			_pegs(c, sign, h)
		"setts":
			_setts(c, lines, h, key, light)
		"topiary":
			_topiary(c, lines, h, key, light)
		"tickets":
			_tickets(c, sign, h)
		"pebbles":
			_pebbles(c, sign, h, light)
		"cactus":
			_cactus(c, sign, h, light)
		"rope":
			_rope(c, sign, h)
		"scarf":
			_scarf(c, sign, h)
		"fronds":
			_fronds(c, sign, h)
		"biscuits":
			_biscuits(c, sign, h, light)
		"pinecones":
			_pinecones(c, sign, h, light)
		"shells":
			_shells(c, sign, h, light)
		"balls":
			_balls(c, sign, h, light)
		"bulbs":
			_bulbs(c, lines, h, t)
		"studs":
			_studs(c, sign, h, t)
	for k in range(held.size()):
		var pc: Dictionary = sign.pieces[k]
		pc.p = held[k][0]
		pc.r = held[k][1]
		pc.len = held[k][2]
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


static func _pipes(c: Object, sign: Dictionary, h: float) -> void:
	# sunflower seed shells, spat out the way a whole stand of fans does: little
	# black teardrops striped grey, most split open, each lying its own way.
	# Rotated by hand rather than with draw_set_transform, so the whole name
	# stays one batch on the sign layer instead of a draw call a shell.
	var cols := [Color(0.14, 0.13, 0.12), Color(0.22, 0.20, 0.18), Color(0.30, 0.28, 0.25)]
	for pc: Dictionary in sign.pieces:
		var col := _pick(cols, float(pc["var"]))
		var r: float = pc.r
		var p: Vector2 = pc.p
		var ax := Vector2.from_angle(float(pc.rot))
		var ay := ax.orthogonal()
		c.draw_colored_polygon(_shell(p + Vector2(0.6, 0.8), ax, ay, r), Color(0, 0, 0, 0.14))
		c.draw_colored_polygon(_shell(p, ax, ay, r), col)
		c.draw_line(p - ax * r * 0.8, p + ax * r * 1.1, Color(0.78, 0.76, 0.70, 0.85), 1.0)
		if float(pc["var"]) > 0.4:
			# split: the pale inside of the other half showing
			c.draw_colored_polygon(_shell(p + ay * r * 0.5 - ax * r * 0.2, ax, ay, r * 0.6), Color(0.86, 0.82, 0.70))


# a seed shell's outline: a teardrop, blunt at the back, pointed at the front
static func _shell(p: Vector2, ax: Vector2, ay: Vector2, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in range(8):
		var a := TAU * float(k) / 8.0
		var along := cos(a) * r * (1.4 if cos(a) > 0.0 else 1.0)
		pts.append(p + ax * along + ay * sin(a) * r * 0.5)
	return pts


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
			# the foot only peeks out round the cone: a full dark square per cone
			# turned a word into a black smudge with orange spots in it
			c.draw_rect(Rect2(-r * 0.86, -r * 0.86, r * 1.72, r * 1.72), Color(0.16, 0.16, 0.17))
			c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			c.draw_circle(p, r * 0.84, Color(0.96, 0.42, 0.10))
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


# --- the walks' own things ------------------------------------------------------

# a piece's outline turned to its own angle by hand: one batch, no transforms
static func _oval(p: Vector2, rot: float, rx: float, ry: float, n := 10) -> PackedVector2Array:
	var ax := Vector2.from_angle(rot)
	var ay := ax.orthogonal()
	var pts := PackedVector2Array()
	for k in range(n):
		var a := TAU * float(k) / float(n)
		pts.append(p + ax * cos(a) * rx + ay * sin(a) * ry)
	return pts


static func _box(p: Vector2, rot: float, hx: float, hy: float) -> PackedVector2Array:
	var ax := Vector2.from_angle(rot) * hx
	var ay := Vector2.from_angle(rot).orthogonal() * hy
	return PackedVector2Array([p - ax - ay, p + ax - ay, p + ax + ay, p - ax + ay])


static func _pegs(c: Object, sign: Dictionary, h: float) -> void:
	# clothes pegs dropped off El Gòtic's washing lines: two halves and the
	# steel spring, in every colour a line of laundry has
	var cols := [Color(0.90, 0.20, 0.20), Color(0.18, 0.46, 0.86), Color(0.98, 0.80, 0.16),
		Color(0.22, 0.66, 0.36), Color(0.94, 0.94, 0.90)]
	for pc: Dictionary in sign.pieces:
		var r: float = pc.r
		c.draw_colored_polygon(_box((pc.p as Vector2) + Vector2(1.5, 2.0), float(pc.rot), r * 1.5, r * 0.55), Color(0, 0, 0, 0.28))
	for pc: Dictionary in sign.pieces:
		var r: float = pc.r
		var p: Vector2 = pc.p
		var rot: float = pc.rot
		var col := _pick(cols, float(pc["var"]))
		var ay := Vector2.from_angle(rot).orthogonal()
		c.draw_colored_polygon(_box(p, rot, r * 1.5, r * 0.55), col.darkened(0.45))
		c.draw_colored_polygon(_box(p - ay * r * 0.16, rot, r * 1.4, r * 0.22), col)
		c.draw_colored_polygon(_box(p + ay * r * 0.16, rot, r * 1.4, r * 0.22), col.lightened(0.15))
		c.draw_circle(p - Vector2.from_angle(rot) * r * 0.2, r * 0.26, Color(0.78, 0.80, 0.82))


static func _tickets(c: Object, sign: Dictionary, h: float) -> void:
	# used tickets blown about the concourse: orange or magenta card, the black
	# magnetic stripe across it, the odd one clipped
	for pc: Dictionary in sign.pieces:
		var r: float = pc.r
		c.draw_colored_polygon(_box((pc.p as Vector2) + Vector2(1.5, 2.0), float(pc.rot), r * 1.25, r * 0.78), Color(0, 0, 0, 0.30))
	for pc: Dictionary in sign.pieces:
		var r: float = pc.r
		var p: Vector2 = pc.p
		var rot: float = pc.rot
		var ax := Vector2.from_angle(rot)
		var card := Color(0.96, 0.58, 0.16) if float(pc["var"]) > 0.3 else Color(0.84, 0.24, 0.50)
		c.draw_colored_polygon(_box(p, rot, r * 1.3, r * 0.82), Color(0.22, 0.14, 0.10))
		c.draw_colored_polygon(_box(p, rot, r * 1.2, r * 0.72), card)
		c.draw_colored_polygon(_box(p + ax * r * 0.55, rot, r * 0.2, r * 0.72), Color(0.12, 0.10, 0.10))
		if float(pc["var"]) > 0.6:
			c.draw_circle(p - ax * r * 0.5, r * 0.18, Color(0.22, 0.14, 0.10))


static func _pebbles(c: Object, sign: Dictionary, h: float, light: Vector2) -> void:
	# river stones from the Besòs bed: worn smooth, grey and ochre and white
	var cols := [Color(0.62, 0.60, 0.56), Color(0.76, 0.66, 0.48), Color(0.88, 0.86, 0.80),
		Color(0.44, 0.44, 0.46), Color(0.70, 0.52, 0.40)]
	for pc: Dictionary in sign.pieces:
		var r: float = pc.r
		c.draw_colored_polygon(_oval((pc.p as Vector2) + light * r * 0.45, float(pc.rot), r * 1.1, r * 0.8), Color(0, 0, 0, 0.30))
	for pc: Dictionary in sign.pieces:
		var r: float = pc.r
		var p: Vector2 = pc.p
		var col := _pick(cols, float(pc["var"]))
		c.draw_colored_polygon(_oval(p, float(pc.rot), r * 1.1, r * 0.8), col.darkened(0.3))
		c.draw_colored_polygon(_oval(p, float(pc.rot), r * 0.98, r * 0.68), col)
		c.draw_circle(p - light * r * 0.35, r * 0.28, col.lightened(0.3))


static func _cactus(c: Object, sign: Dictionary, h: float, light: Vector2) -> void:
	# the Jardí de Cactus: barrel cacti planted in letters, ribbed, spined, and
	# now and then one in flower. Shoved, they spring back upright.
	for pc: Dictionary in sign.pieces:
		c.draw_circle((pc.p as Vector2) + light * float(pc.r) * 0.5, float(pc.r) * 1.05, Color(0, 0, 0, 0.30))
	for pc: Dictionary in sign.pieces:
		var r: float = pc.r
		var p: Vector2 = pc.p
		var green := Color(0.22, 0.48, 0.30).lerp(Color(0.36, 0.56, 0.26), float(pc["var"]))
		c.draw_circle(p, r, green.darkened(0.35))
		c.draw_circle(p, r * 0.86, green)
		for k in range(8):
			var d := Vector2.from_angle(float(pc.rot) + TAU * float(k) / 8.0)
			c.draw_line(p + d * r * 0.2, p + d * r * 0.84, green.darkened(0.22), 1.2)
			c.draw_circle(p + d * r * 0.9, 0.9, Color(0.96, 0.94, 0.80))
		if float(pc["var"]) > 0.72:
			c.draw_circle(p, r * 0.32, Color(0.96, 0.36, 0.56))
			c.draw_circle(p, r * 0.12, Color(0.98, 0.86, 0.30))
		else:
			c.draw_circle(p - light * r * 0.3, r * 0.22, green.lightened(0.25))


static func _rope(c: Object, sign: Dictionary, h: float) -> void:
	# a mooring line off the wharf laid along the letters: a fat hemp rope,
	# its twist showing as slanted strands
	for pc: Dictionary in sign.pieces:
		var half := Vector2.from_angle(float(pc.rot)) * float(pc.len) * 0.5
		var p: Vector2 = pc.p
		c.draw_line(p - half + Vector2(2, 2.5), p + half + Vector2(2, 2.5), Color(0, 0, 0, 0.3), h * 0.13)
		c.draw_line(p - half, p + half, Color(0.36, 0.26, 0.14), h * 0.13)
	for pc: Dictionary in sign.pieces:
		var dir := Vector2.from_angle(float(pc.rot))
		var half := dir * float(pc.len) * 0.5
		var p: Vector2 = pc.p
		var side := dir.orthogonal() * h * 0.045
		c.draw_line(p - half * 0.98, p + half * 0.98, Color(0.80, 0.66, 0.42), h * 0.095)
		var n := maxi(2, int(float(pc.len) / (h * 0.07)))
		for k in range(n):
			var q := p - half + dir * float(pc.len) * (float(k) + 0.5) / float(n)
			c.draw_line(q - side - dir * h * 0.02, q + side + dir * h * 0.02, Color(0.56, 0.42, 0.24), 1.6)


static func _fronds(c: Object, sign: Dictionary, h: float) -> void:
	# palm fronds fallen in the square: a pale midrib and the leaflets along it
	for pc: Dictionary in sign.pieces:
		var dir := Vector2.from_angle(float(pc.rot))
		var half := dir * float(pc.len) * 0.5
		var p: Vector2 = pc.p
		var side := dir.orthogonal()
		var green := Color(0.24, 0.48, 0.22).lerp(Color(0.48, 0.58, 0.22), float(pc["var"]) * 0.6)
		var n := maxi(3, int(float(pc.len) / (h * 0.055)))
		for k in range(n):
			var q := p - half + dir * float(pc.len) * (float(k) + 0.5) / float(n)
			for sd: float in [-1.0, 1.0]:
				var tip := q + side * sd * h * 0.13 + dir * h * 0.06
				c.draw_line(q + Vector2(1.5, 2), tip + Vector2(1.5, 2), Color(0, 0, 0, 0.22), h * 0.05)
				c.draw_line(q, tip, green, h * 0.045)
		c.draw_line(p - half, p + half, Color(0.78, 0.72, 0.46), h * 0.03)


static func _biscuits(c: Object, sign: Dictionary, h: float, light: Vector2) -> void:
	# bone-shaped dog biscuits from the treat jar on the vet's counter
	for pc: Dictionary in sign.pieces:
		_bone(c, (pc.p as Vector2) + light * float(pc.r) * 0.45, float(pc.rot), float(pc.r) * 0.92, Color(0, 0, 0, 0.28))
	for pc: Dictionary in sign.pieces:
		var r: float = pc.r
		var p: Vector2 = pc.p
		var col := Color(0.82, 0.58, 0.30).lerp(Color(0.64, 0.40, 0.22), float(pc["var"]))
		_bone(c, p, float(pc.rot), r * 0.92, col.darkened(0.4))
		_bone(c, p, float(pc.rot), r * 0.82, col)
		c.draw_circle(p - light * r * 0.2, r * 0.16, col.lightened(0.25))


static func _bone(c: Object, p: Vector2, rot: float, r: float, col: Color) -> void:
	var ax := Vector2.from_angle(rot)
	var ay := ax.orthogonal()
	c.draw_colored_polygon(_box(p, rot, r * 0.8, r * 0.36), col)
	for e: float in [-1.0, 1.0]:
		for s2: float in [-1.0, 1.0]:
			c.draw_circle(p + ax * e * r * 0.8 + ay * s2 * r * 0.32, r * 0.38, col)


static func _pinecones(c: Object, sign: Dictionary, h: float, light: Vector2) -> void:
	# Aleppo pine cones off the hillside: a tapered brown cone, its scales in
	# rows, the tips catching the light
	for pc: Dictionary in sign.pieces:
		var r: float = pc.r
		c.draw_colored_polygon(_oval((pc.p as Vector2) + light * r * 0.5, float(pc.rot), r * 1.35, r * 0.8), Color(0, 0, 0, 0.30))
	for pc: Dictionary in sign.pieces:
		var r: float = pc.r
		var p: Vector2 = pc.p
		var rot: float = pc.rot
		var ax := Vector2.from_angle(rot)
		var ay := ax.orthogonal()
		var brown := Color(0.50, 0.30, 0.14).lerp(Color(0.62, 0.40, 0.18), float(pc["var"]))
		c.draw_colored_polygon(_oval(p, rot, r * 1.35, r * 0.8), Color(0.26, 0.15, 0.07))
		c.draw_colored_polygon(_oval(p, rot, r * 1.22, r * 0.68), brown)
		for k in range(4):
			var q := p + ax * r * (-0.8 + float(k) * 0.52)
			var w := r * 0.62 * (1.0 - absf(float(k) - 1.4) * 0.22)
			c.draw_line(q - ay * w, q + ax * r * 0.22, Color(0.30, 0.17, 0.08), 1.4)
			c.draw_line(q + ay * w, q + ax * r * 0.22, Color(0.30, 0.17, 0.08), 1.4)
			c.draw_circle(q + ax * r * 0.2, r * 0.1, brown.lightened(0.3))


static func _balls(c: Object, sign: Dictionary, h: float, light: Vector2) -> void:
	# her tennis balls, the whole collection, set out for the first walk: felt
	# yellow, the white seam curling round
	for pc: Dictionary in sign.pieces:
		c.draw_circle((pc.p as Vector2) + light * float(pc.r) * 0.5, float(pc.r), Color(0, 0, 0, 0.32))
	for pc: Dictionary in sign.pieces:
		var r: float = pc.r
		var p: Vector2 = pc.p
		var felt := Color(0.82, 0.90, 0.20).lerp(Color(0.92, 0.86, 0.22), float(pc["var"]))
		c.draw_circle(p, r, felt.darkened(0.42))
		c.draw_circle(p, r * 0.88, felt)
		var d := Vector2.from_angle(float(pc.rot))
		var o := d.orthogonal()
		var prev := p - d * r * 0.8 + o * r * 0.3
		for k in range(1, 7):
			var u := float(k) / 6.0
			var q := p + d * r * (u * 1.6 - 0.8) + o * r * 0.3 * cos(u * PI)
			c.draw_line(prev, q, Color(0.98, 0.98, 0.94), 1.4)
			prev = q
		c.draw_circle(p - light * r * 0.35, r * 0.24, felt.lightened(0.3))


static func _bulbs(c: Object, lines: Array, h: float, t: float) -> void:
	# the summit fairground's festoon: a black cable run along the letters and
	# bulbs on it, warm white and coloured, the lights chasing along the name
	_stroke(c, lines, h * 0.035, Color(0.08, 0.08, 0.10), Vector2(1.5, 2.0))
	_stroke(c, lines, h * 0.03, Color(0.16, 0.16, 0.18))
	var pts := Letters.points(lines, h * 0.16)
	var cols := [Color(1.0, 0.86, 0.48), Color(0.98, 0.36, 0.30), Color(1.0, 0.86, 0.48), Color(0.40, 0.70, 1.0)]
	var step := int(floor(t * 5.0))
	for i in range(pts.size()):
		var col: Color = cols[i % cols.size()]
		var lit := (i + step) % 3 != 0
		var glow := h * (0.12 if lit else 0.07)
		c.draw_circle(pts[i], glow, Color(col.r, col.g, col.b, 0.28 if lit else 0.10))
		c.draw_circle(pts[i], h * 0.055, col if lit else col.darkened(0.5))
		c.draw_circle(pts[i] - Vector2(h * 0.015, h * 0.015), h * 0.02, Color(1, 1, 1, 0.9 if lit else 0.3))


static func _studs(c: Object, sign: Dictionary, h: float, t: float) -> void:
	# LED studs set flush in the concourse's terrazzo: a dark steel ring, a lens,
	# and the light pooling round it on the floor. A slow wave of brightness runs
	# along the name; a light someone is standing on is out.
	var pts := stud_points(sign)
	var cover: PackedFloat32Array = sign.cover
	var lens := Color(0.66, 0.92, 1.0)
	# the dark granite inlay the lights are set in, its polished edge catching
	# the hall's light
	_stroke(c, sign.lines, h * 0.19, Color(0.70, 0.72, 0.74), Vector2(-0.8, -0.8))
	_stroke(c, sign.lines, h * 0.17, Color(0.10, 0.11, 0.13))
	for i in range(pts.size()):
		var lit := (1.0 - cover[i]) * (0.72 + 0.28 * (0.5 + 0.5 * sin(t * 2.4 - pts[i].x * 0.018)))
		if lit > 0.02:
			c.draw_circle(pts[i], h * 0.15, Color(lens.r, lens.g, lens.b, 0.12 * lit))
			c.draw_circle(pts[i], h * 0.085, Color(lens.r, lens.g, lens.b, 0.32 * lit))
	for i in range(pts.size()):
		var lit := (1.0 - cover[i]) * (0.72 + 0.28 * (0.5 + 0.5 * sin(t * 2.4 - pts[i].x * 0.018)))
		c.draw_circle(pts[i], h * 0.045, Color(0.30, 0.32, 0.35))
		c.draw_circle(pts[i], h * 0.034, Color(0.06, 0.08, 0.10).lerp(lens, lit))
		c.draw_circle(pts[i] - Vector2(h * 0.01, h * 0.012), h * 0.016, Color(1, 1, 1, 0.25 + 0.7 * lit))


const SCARF_BLUE := Color(0.20, 0.36, 0.72)
const SCARF_CLARET := Color(0.66, 0.16, 0.28)
const SCARF_WHITE := Color(0.97, 0.96, 0.92)


static func _scarf(c: Object, sign: Dictionary, h: float) -> void:
	# a home fan's knitted scarf laid along the letters: blue and claret bars
	# split by white, the knit's rows showing, a white fringe at each end
	var w := h * 0.17
	for pc: Dictionary in sign.pieces:
		var half := Vector2.from_angle(float(pc.rot)) * float(pc.len) * 0.5
		var p: Vector2 = pc.p
		c.draw_line(p - half + Vector2(2, 2.5), p + half + Vector2(2, 2.5), Color(0, 0, 0, 0.32), w)
	for pc: Dictionary in sign.pieces:
		var dir := Vector2.from_angle(float(pc.rot))
		var half := dir * float(pc.len) * 0.5
		var p: Vector2 = pc.p
		var side := dir.orthogonal() * w * 0.5
		var col := SCARF_BLUE if int(float(pc["var"]) * 2.0) % 2 == 0 else SCARF_CLARET
		c.draw_line(p - half, p + half, col, w)
		for e: float in [-0.42, 0.42]:
			var q := p + half * e * 2.0
			c.draw_line(q - side, q + side, SCARF_WHITE, h * 0.035)
		var n := maxi(2, int(float(pc.len) / (h * 0.045)))
		for k in range(n):
			var q := p - half + dir * float(pc.len) * (float(k) + 0.5) / float(n)
			c.draw_line(q - side * 0.85, q + side * 0.85, col.darkened(0.18), 1.0)
		for end: Array in [[bool(pc.get("first", false)), -1.0], [bool(pc.get("last", false)), 1.0]]:
			if not bool(end[0]):
				continue
			var tip := p + half * float(end[1])
			for f in range(5):
				var fq := tip + side * (float(f) / 2.0 - 1.0) * 0.9
				c.draw_line(fq, fq + dir * float(end[1]) * h * 0.09, SCARF_WHITE, 1.4)



static func _setts(c: Object, lines: Array, h: float, key: float, light: Vector2) -> void:
	# the name laid into the alley's paving in dark granite setts, the way old
	# streets carry an inscription: pale mortar along the letters, and in it
	# small squared stones, each a little turned, worn smooth on top
	_stroke(c, lines, h * 0.22, Color(0.84, 0.80, 0.70))
	var pts := Letters.points(lines, h * 0.1)
	for i in range(pts.size()):
		var rot := (_h(i, key, 51.0) - 0.5) * 0.5
		var s := h * (0.042 + _h(i, key, 52.0) * 0.008)
		var col := Color(0.26, 0.25, 0.27).lerp(Color(0.38, 0.35, 0.33), _h(i, key, 53.0))
		c.draw_colored_polygon(_box(pts[i] + light * 1.2, rot, s, s * 0.9), Color(0, 0, 0, 0.30))
		c.draw_colored_polygon(_box(pts[i], rot, s, s * 0.9), col)
		c.draw_colored_polygon(_box(pts[i] - light * s * 0.25, rot, s * 0.55, s * 0.45), col.lightened(0.18))


static func _topiary(c: Object, lines: Array, h: float, key: float, light: Vector2) -> void:
	# the name clipped in box hedging, the way a parterre spells a monogram:
	# its shadow on the gravel, the dark body of the hedge, the clipped top
	# catching the light, and the clumps of the shears' work along it
	var w := h * 0.20
	_stroke(c, lines, w, Color(0.05, 0.08, 0.04, 0.34), light * w * 0.45)
	_stroke(c, lines, w, Color(0.12, 0.25, 0.14))
	_stroke(c, lines, w * 0.7, Color(0.22, 0.40, 0.22), -light * w * 0.08)
	var pts := Letters.points(lines, h * 0.075)
	for i in range(pts.size()):
		var q := pts[i] - light * w * 0.12 + Vector2(_h(i, key, 61.0) - 0.5, _h(i, key, 62.0) - 0.5) * w * 0.2
		c.draw_circle(q, w * (0.16 + _h(i, key, 63.0) * 0.06), Color(0.34, 0.54, 0.30).lerp(Color(0.42, 0.60, 0.32), _h(i, key, 64.0)))

static func _shells(c: Object, sign: Dictionary, h: float, light: Vector2) -> void:
	# seashells washed up on Platja de Llevant: ribbed cockles and scallops in
	# cream, coral and sand-gold, with radiated ridges from the hinge
	var cols := [Color(0.95, 0.88, 0.78), Color(0.92, 0.72, 0.62), Color(0.88, 0.78, 0.62),
		Color(0.96, 0.94, 0.90), Color(0.84, 0.66, 0.58)]
	for pc: Dictionary in sign.pieces:
		var r: float = pc.r
		c.draw_colored_polygon(_oval((pc.p as Vector2) + light * r * 0.45, float(pc.rot), r * 1.15, r * 0.95), Color(0, 0, 0, 0.26))
	for pc: Dictionary in sign.pieces:
		var r: float = pc.r
		var p: Vector2 = pc.p
		var rot: float = pc.rot
		var ax := Vector2.from_angle(rot)
		var ay := ax.orthogonal()
		var col := _pick(cols, float(pc["var"]))
		c.draw_colored_polygon(_oval(p, rot, r * 1.15, r * 0.95), col.darkened(0.28))
		c.draw_colored_polygon(_oval(p, rot, r * 1.02, r * 0.84), col)
		var hinge := p - ax * r * 0.65
		for k in range(-2, 3):
			var tip := p + ax * r * 0.75 + ay * float(k) * r * 0.28
			c.draw_line(hinge, tip, col.darkened(0.18), 1.1)
		c.draw_circle(p - light * r * 0.28, r * 0.24, col.lightened(0.22))
