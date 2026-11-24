extends RefCounted

# The Raval's bronze cat, drawn from above (the walk) and side on (the films),
# so he is one animal in both. A cat of our own in the manner of the swollen
# monumental bronzes the city is fond of: everything on him is inflated and
# seamless, the volumes running into each other with no fur and no edges; a
# vast barrel on four pillar legs, a round moon of a face with everything on
# it too small and too close together, stub ears, a tail like a sausage. The
# bronze is black-brown and airbrushed, worn to gold where people touch him
# (his nose, the tips of his paws, the end of his tail), with a torn ear and a
# green bloom in the creases.
# He is never hackled or bristled: angry, he swells, and his little eyes heat.

const ShapeBatch := preload("res://systems/shape_batch.gd")

const BASE := Color(0.25, 0.20, 0.17)
const DARK := Color(0.10, 0.08, 0.08)
const LIT := Color(0.56, 0.46, 0.36)
const SPEC := Color(0.98, 0.88, 0.70)
const GOLD := Color(0.82, 0.62, 0.30)
const PATINA := Color(0.34, 0.52, 0.45)
const AMBER := Color(0.98, 0.78, 0.22)
const HOT := Color(1.00, 0.30, 0.12)
const PUPIL := Color(0.08, 0.05, 0.05)
const INK := Color(0.07, 0.05, 0.07)
const SUN := Vector2(-0.55, -0.83)     # where the light comes from
const ROWS := [0.0, 0.34, 0.62, 0.84, 1.0]


static func _oval(at: Vector2, half: Vector2, fwd: Vector2, n := 32) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var s := fwd.orthogonal()
	for i in range(n):
		var a := TAU * float(i) / float(n)
		pts.append(at + fwd * (cos(a) * half.x) + s * (sin(a) * half.y))
	return pts


# one airbrushed pass over an oval: `alpha` from its hot spot out to its rim
static func _wash(b: ShapeBatch, at: Vector2, half: Vector2, fwd: Vector2, hot: Vector2, col: Color, alpha: Array, n := 32) -> void:
	var rim := _oval(at, half, fwd, n)
	rim.append(rim[0])
	var pts := PackedVector2Array()
	for u: float in ROWS:
		for q in rim:
			pts.append(hot.lerp(q, u))
	b.band(pts, rim.size(), col, PackedFloat32Array(alpha))


# a swollen volume: its own dark at the rim away from the light, a broad soft
# light toward it, one small polished highlight. Its triangles are built once
# per shape and turn (in steps of BINS to the circle, so the light stays put as
# he turns) and stamped after that: he is a dozen of these every frame.
const BINS := 32
static var _shapes := {}
static var _paints := {}


static func vol(b: ShapeBatch, at: Vector2, half: Vector2, fwd: Vector2, tint: Color, shine := 1.0) -> void:
	var m := minf(half.x, half.y)
	var rx := snappedf(half.x / m, 0.02)
	var ry := snappedf(half.y / m, 0.02)
	var bin := posmod(roundi(fwd.angle() / TAU * float(BINS)), BINS)
	# the small ones need no finer a rim than they show
	var n := 14 if m < 24.0 else 28
	var key := Vector4(rx, ry, float(bin), float(n))
	var raw_key := "raw%d" % n
	if not _shapes.has(key):
		if _shapes.size() > 600:
			_shapes.clear()
		var rec := ShapeBatch.new()
		var sun := SUN.rotated(-TAU * float(bin) / float(BINS))
		var h := Vector2(rx, ry)
		rec.polygon(_oval(Vector2.ZERO, h, Vector2.RIGHT, n), Color.WHITE)
		_wash(rec, Vector2.ZERO, h, Vector2.RIGHT, sun * 0.22, DARK, [0.0, 0.0, 0.18, 0.52, 0.90], n)
		_wash(rec, Vector2.ZERO, h * 0.90, Vector2.RIGHT, sun * 0.42, LIT, [0.85, 0.60, 0.26, 0.06, 0.0], n)
		_wash(rec, sun * 0.48, h * 0.22, Vector2.RIGHT, sun * 0.50, SPEC, [0.75, 0.5, 0.22, 0.06, 0.0], n)
		_shapes[key] = rec._points
		if not _paints.has(raw_key):
			_paints[raw_key] = rec._colors
	var ink := [tint, shine, n]
	var cols: PackedColorArray
	if _paints.has(ink):
		cols = _paints[ink]
	else:
		if _paints.size() > 64:
			for k: Variant in _paints.keys():
				if k is Array:
					_paints.erase(k)
		cols = (_paints[raw_key] as PackedColorArray).duplicate()
		var base := (n - 2) * 3
		for i in range(cols.size()):
			if i < base:
				cols[i] = tint
			elif i >= base + (cols.size() - base) / 3:
				cols[i].a *= shine
		_paints[ink] = cols
	var xf := Transform2D(fwd.angle(), Vector2(m, m), 0.0, at)
	b._points.append_array(xf * (_shapes[key] as PackedVector2Array))
	b._colors.append_array(cols)


# a swollen limb, round at both ends, shaded along its length
static func tube(b: ShapeBatch, a: Vector2, c: Vector2, ra: float, rc: float, tint: Color) -> void:
	var d := c - a
	if d.length_squared() < 1.0:
		b.circle(a, ra, tint)
		return
	var n := d.normalized().orthogonal()
	if n.dot(SUN) < 0.0:
		n = -n
	b.circle(a, ra, tint)
	b.circle(c, rc, tint)
	b.quad(a + n * ra, c + n * rc, c - n * rc, a - n * ra, tint)
	b.band(PackedVector2Array([a + n * ra, a + n * ra * 0.55, a, c + n * rc, c + n * rc * 0.55, c]), 3, LIT,
		PackedFloat32Array([0.8, 0.8]), PackedFloat32Array([0.0, 0.8, 0.0]))
	b.band(PackedVector2Array([a, a - n * ra, c, c - n * rc]), 2, DARK, PackedFloat32Array([0.8, 0.8]), PackedFloat32Array([0.0, 0.9]))


static func _tail(b: ShapeBatch, pts: PackedVector2Array, w0: float, w1: float, tint: Color) -> void:
	var n := pts.size()
	for i in range(n):
		var w := lerpf(w0, w1, float(i) / float(n - 1))
		b.circle(pts[i], w, tint)
		if i > 0:
			b.line(pts[i - 1], pts[i], tint, w * 2.0)
	# its shading runs the length of it in one strip, so it has no joints
	var strip := PackedVector2Array()
	for i in range(n):
		var d := (pts[mini(i + 1, n - 1)] - pts[maxi(i - 1, 0)]).normalized().orthogonal()
		if d.dot(SUN) < 0.0:
			d = -d
		var w := lerpf(w0, w1, float(i) / float(n - 1))
		for u: float in [1.0, 0.5, 0.0, -0.45, -1.0]:
			strip.append(pts[i] + d * w * u)
	var rows := PackedFloat32Array()
	rows.resize(n)
	rows.fill(1.0)
	b.band(strip, 5, LIT, rows, PackedFloat32Array([0.0, 0.65, 0.0, 0.0, 0.0]))
	b.band(strip, 5, DARK, rows, PackedFloat32Array([0.0, 0.0, 0.0, 0.25, 0.85]))
	b.glow(pts[n - 1] + SUN * w1 * 0.2, w1 * 1.1, Color(GOLD, 0.75))


# --- from above ------------------------------------------------------------------

# `s` is how he is: face (Vector2), look (his head's way), paws (Array of Vector2 on the ground),
# tint, swell (1 and up), eyes (0 shut to 1), hot (bool), mood ("", "purr",
# "stun", "cross"), lash (the tail's swing), ear (droop), paw_to / paw_from /
# paw_lift for a swat.
static func top(b: ShapeBatch, at: Vector2, s: Dictionary, t: float) -> void:
	var face: Vector2 = s.face
	var back := -face
	var side := face.orthogonal()
	var tint: Color = s.tint
	var sw: float = s.get("swell", 1.0)
	# the paws: pillars' feet, splayed out from under the bulk
	for paw: Vector2 in s.paws:
		var out := (paw - at).normalized()
		var p := paw + out * 22.0
		vol(b, p, Vector2(20.0, 18.0), out, tint, 0.7)
		for k: float in [-0.5, 0.0, 0.5]:
			var d := out.rotated(k)
			b.line(p + d * 11.0, p + d * 18.0, DARK, 2.0)
		b.glow(p + out * 12.0, 12.0, Color(GOLD, 0.55))
	# the tail: one thick sausage, up off the rump and over to a blunt end
	var lash: float = s.get("lash", 0.0)
	var tail := PackedVector2Array()
	for i in range(7):
		var u := float(i) / 6.0
		tail.append(at + back * (52.0 + 44.0 * u - 14.0 * u * u) * sw + side * (u * u * (46.0 + lash)))
	_tail(b, tail, 13.0, 12.0, tint)
	# the body: haunches, barrel and chest, all one skin
	var haunch := 34.0 * sw
	for k: float in [-1.0, 1.0]:
		vol(b, at + back * 28.0 * sw + side * k * 40.0 * sw, Vector2(haunch, haunch), face, tint, 0.55)
	b.polygon(_oval(at + back * 4.0, Vector2(70.0, 62.0) * sw, face), tint)
	vol(b, at + back * 4.0, Vector2(72.0, 64.0) * sw, face, tint)
	# the patina gathers where the chest meets the neck
	b.arc(at + face * 6.0 * sw, 42.0 * sw, face.angle() - 0.75, face.angle() + 0.75, 12, Color(PATINA, 0.28), 3.0)
	# the neck: a fold, no more
	var look: Vector2 = s.get("look", face)
	var hc := at + (face * 30.0 + look * 20.0) * sw
	b.glow(hc - look * 14.0, 46.0, Color(DARK, 0.55))
	_face_top(b, hc, s, tint, t)
	# the paw that is up
	if s.has("paw_to"):
		var lift: float = s.paw_lift
		tube(b, s.paw_from, s.paw_to, 18.0, 15.0, tint)
		vol(b, s.paw_to, Vector2(25.0, 23.0), Vector2.RIGHT, tint, 1.0)
		for k: float in [-9.0, 0.0, 9.0]:
			var r: Vector2 = s.paw_to + Vector2(k, 14.0)
			b.circle(r, 6.0, tint)
			b.line(r + Vector2(0, 3), r + Vector2(k * 0.3, 14.0 + 4.0 * (1.0 - lift)), Color(0.94, 0.90, 0.78), 3.0)


static func _ear(b: ShapeBatch, hc: Vector2, sd: float, r: float, tint: Color, droop: float) -> void:
	var c := hc + Vector2(sd * r * 0.62, -r * 0.74 + droop)
	var up := Vector2(sd * 0.42, -0.9).normalized()
	vol(b, c, Vector2(r * 0.40, r * 0.30), up, tint, 0.7)
	b.polygon(_oval(c + up * r * 0.06, Vector2(r * 0.22, r * 0.14), up, 14), DARK)
	if sd > 0.0:
		# torn, long ago, by someone
		b.polygon(PackedVector2Array([c + up * r * 0.44 + Vector2(3.0, 0.0), c + up * r * 0.12, c + up * r * 0.40 + Vector2(-3.5, -1.0)]), DARK)


# a moon of a face seen from the front: small features crowded in the middle
static func _face_top(b: ShapeBatch, hc: Vector2, s: Dictionary, tint: Color, t: float) -> void:
	var r := 34.0
	var mood: String = s.get("mood", "")
	var hot: bool = s.get("hot", false)
	for sd: float in [-1.0, 1.0]:
		_ear(b, hc, sd, r, tint, float(s.get("ear", 0.0)))
	vol(b, hc, Vector2(r * 1.14, r), Vector2.RIGHT, tint)
	# his face is on the side of the ball he is looking out of: full on as he
	# comes down the screen, sliding round to a profile, gone as he goes up it
	var look: Vector2 = s.get("look", Vector2.DOWN)
	if look.y < -0.45:
		for sd: float in [-1.0, 1.0]:
			var w := hc + Vector2(look.x * 18.0 + sd * 27.0, -12.0)
			b.line(w, w + Vector2(sd * 13.0, -8.0), Color(LIT, 0.9), 1.6)
		return
	hc += Vector2(look.x * 19.0, -13.0 * (1.0 - clampf(look.y, -0.45, 1.0)))
	# the cheeks, swollen so the mouth is pinched between them
	for sd: float in [-1.0, 1.0]:
		vol(b, hc + Vector2(sd * 11.5, 13.0), Vector2(13.5, 11.5), Vector2.RIGHT, tint.lightened(0.05), 0.75)
	# the mouth, pursed; cross, it opens on two small fangs
	var mouth := hc + Vector2(0.0, 13.0)
	if mood == "cross":
		b.ellipse(mouth + Vector2(0.0, 8.0), 8.0, 7.0, Color(0.30, 0.06, 0.07))
		for sd: float in [-1.0, 1.0]:
			b.polygon(PackedVector2Array([mouth + Vector2(sd * 6.5, 3.0), mouth + Vector2(sd * 2.0, 2.0), mouth + Vector2(sd * 4.0, 10.0)]), Color(0.96, 0.93, 0.84))
	else:
		b.line(mouth, mouth + Vector2(0.0, 5.0), DARK, 2.0)
		for sd: float in [-1.0, 1.0]:
			b.line(mouth + Vector2(0.0, 5.0), mouth + Vector2(sd * 4.5, 7.5), DARK, 2.0)
	# the nose, rubbed gold by every child in the Raval
	b.polygon(PackedVector2Array([hc + Vector2(-5.5, 3.0), hc + Vector2(5.5, 3.0), hc + Vector2(0.0, 10.0)]), GOLD)
	b.circle(hc + Vector2(-1.5, 4.6), 1.4, SPEC)
	# whiskers: three cast ridges a side
	for sd: float in [-1.0, 1.0]:
		for k in range(3):
			var w := hc + Vector2(sd * 18.0, 9.0 + 4.0 * float(k))
			b.line(w, w + Vector2(sd * 20.0, -4.0 + 4.0 * float(k) + sin(t * 7.0) * 0.8), Color(LIT, 0.9), 1.6)
	# the eyes: too small for him, close to the nose
	var open: float = s.get("eyes", 1.0)
	for sd: float in [-1.0, 1.0]:
		var e := hc + Vector2(sd * 10.5, -5.5)
		b.glow(e, 11.0, Color(DARK, 0.75))
		if mood == "purr":
			b.line(e + Vector2(-5, 1), e + Vector2(0, -2), PUPIL, 2.4)
			b.line(e + Vector2(0, -2), e + Vector2(5, 1), PUPIL, 2.4)
		elif mood == "stun":
			b.line(e - Vector2(4, 4), e + Vector2(4, 4), AMBER, 2.4)
			b.line(e - Vector2(-4, 4), e + Vector2(-4, 4), AMBER, 2.4)
		elif open <= 0.08:
			b.line(e - Vector2(5, 0), e + Vector2(5, 0), PUPIL, 2.2)
		else:
			var col := HOT if hot else AMBER
			if hot:
				b.glow(e, 17.0, Color(HOT, 0.7))
			var h := 4.8 * open * (1.0 if hot else 0.62)
			b.ellipse(e + Vector2(0.0, 0.0 if hot else 1.4), 5.6, h, col)
			b.ellipse(e + Vector2(0.0, 0.0 if hot else 1.2), 1.5, h * 0.92, PUPIL)
			b.circle(e + Vector2(-1.8, -0.6), 1.0, Color(1, 1, 0.94))
			# the heavy lid, level when he is calm, down to the nose when he is not
			var tilt := 5.0 if hot or mood == "cross" else 0.0
			b.line(e + Vector2(sd * 8.0, -5.0 - tilt * 0.5), e + Vector2(-sd * 6.5, -4.0 + tilt * 0.6), DARK, 3.4)


# tied up and over on his side: the bulk of him like a dropped loaf, four
# pillars in the air, the head at `head`
static func toppled(b: ShapeBatch, at: Vector2, head: Vector2, t: float) -> void:
	var tail := PackedVector2Array()
	for i in range(6):
		var u := float(i) / 5.0
		tail.append(at + Vector2(56.0 + 48.0 * u, 8.0 - 34.0 * u * u + sin(t * 4.0) * 5.0 * u))
	_tail(b, tail, 13.0, 12.0, BASE)
	for k in range(4):
		var root := at + Vector2(-36.0 + 26.0 * float(k), 18.0)
		var foot := root + Vector2(-6.0 + 5.0 * float(k) + sin(t * 4.0 + float(k) * 1.4) * 4.0, 40.0)
		tube(b, root, foot, 17.0, 15.0, BASE.darkened(0.1 if k % 2 == 0 else 0.0))
		vol(b, foot, Vector2(18.0, 15.0), Vector2.RIGHT, BASE, 0.7)
		b.glow(foot + Vector2(0.0, 6.0), 12.0, Color(GOLD, 0.55))
	vol(b, at, Vector2(78.0, 52.0), Vector2.RIGHT, BASE)
	b.glow(head + (at - head) * 0.3, 40.0, Color(DARK, 0.5))
	_face_top(b, head, {"mood": "stun", "ear": 5.0}, BASE, t)


# --- side on ---------------------------------------------------------------------

# Facing right, his feet at `at`, about 400 wide and 370 tall at k = 1. Inked
# round the outside only, like everyone in the films, and seamless inside it.
static func side(c: CanvasItem, at: Vector2, k: float, t: float, awake: float, walking: bool, stretch: float,
		swat := 0.0, cross := 0.0) -> void:
	var b := ShapeBatch.new(c)
	var swell := 1.0 + 0.07 * cross + 0.02 * sin(t * 2.0) * awake
	var rise := sin(stretch * PI) * 26.0
	# the feet stay put; everything over them breathes
	var up := func(v: Vector2) -> Vector2:
		return at + Vector2(v.x * lerpf(1.0, swell, clampf(-v.y / 120.0, 0.0, 1.0)), v.y * swell - rise * clampf(-v.y / 160.0, 0.0, 1.0)) * k
	var p := func(v: Vector2) -> Vector2: return at + v * k
	b.polygon(_oval(at + Vector2(0, 4) * k, Vector2(196, 14) * k, Vector2.RIGHT), Color(0, 0, 0, 0.38))
	var stride := sin(t * 7.0) * 15.0 if walking else 0.0
	# the tail, up behind him and over
	var tail := PackedVector2Array()
	for i in range(10):
		var u := float(i) / 9.0
		tail.append(up.call(Vector2(-152.0 - sin(u * 2.5) * 74.0 + sin(t * 3.0 + u * 2.0) * 10.0 * u * awake, -170.0 - u * 168.0)))
	for q in tail:
		b.circle(q, 25.0 * k, INK)
	_tail(b, tail, 21.0 * k, 19.0 * k, BASE)
	# far legs, body, near legs: ink first, as one mass
	var body: Vector2 = up.call(Vector2(-14, -188))
	var bh := Vector2(186, 136) * k * swell
	var rump: Vector2 = up.call(Vector2(-98, -176))
	var rh := Vector2(112, 112) * k * swell
	var chest: Vector2 = up.call(Vector2(92, -190))
	var ch := Vector2(96, 104) * k * swell
	var far := [[Vector2(92, -110), Vector2(84 - stride, -16)], [Vector2(-84, -110), Vector2(-62 + stride, -16)]]
	var near := [[Vector2(-106, -104), Vector2(-112 - stride, -16)], [Vector2(112, -104), Vector2(124 + stride, -16)]]
	if swat > 0.0:
		near[1][1] = (near[1][1] as Vector2).lerp(Vector2(226, -132), swat)
	for leg: Array in far:
		_pillar(b, up.call(leg[0]), p.call(leg[1]), k, BASE.darkened(0.4), true)
	for part: Array in [[body, bh], [rump, rh], [chest, ch]]:
		b.polygon(_oval(part[0], part[1] + Vector2(6, 6) * k, Vector2.RIGHT, 48), INK)
	for leg: Array in far:
		_pillar(b, up.call(leg[0]), p.call(leg[1]), k, BASE.darkened(0.4), false)
	for leg: Array in near:
		_pillar(b, up.call(leg[0]), p.call(leg[1]), k, BASE, true)
	for part: Array in [[body, bh], [rump, rh], [chest, ch]]:
		b.polygon(_oval(part[0], part[1], Vector2.RIGHT, 48), BASE)
	# one skin over the three: the dark low and behind, the light along the back
	_wash(b, body, bh, Vector2.RIGHT, body + Vector2(-20, -60) * k, DARK, [0.0, 0.0, 0.15, 0.45, 0.75])
	_wash(b, rump, rh, Vector2.RIGHT, rump + SUN * 40.0 * k, LIT, [0.50, 0.40, 0.22, 0.07, 0.0])
	_wash(b, chest, ch * 0.96, Vector2.RIGHT, chest + SUN * 44.0 * k, LIT, [0.55, 0.42, 0.22, 0.06, 0.0])
	_wash(b, body + Vector2(-10, -66) * k, Vector2(130, 46) * k, Vector2.RIGHT, body + Vector2(-30, -84) * k, LIT, [0.85, 0.65, 0.34, 0.10, 0.0])
	_wash(b, body + Vector2(-52, -96) * k, Vector2(56, 13) * k, Vector2(0.97, -0.22), body + Vector2(-52, -98) * k, SPEC, [0.8, 0.6, 0.3, 0.1, 0.0])
	_wash(b, rump + Vector2(-34, -20) * k, Vector2(20, 34) * k, Vector2.RIGHT, rump + Vector2(-38, -26) * k, SPEC, [0.40, 0.30, 0.15, 0.05, 0.0])
	for leg: Array in near:
		_pillar(b, up.call(leg[0]), p.call(leg[1]), k, BASE, false)
	# the thigh rolls over the leg with no line, only a shadow under it
	_wash(b, up.call(Vector2(-104, -138)), Vector2(66, 62) * k, Vector2.RIGHT, up.call(Vector2(-114, -156)), LIT, [0.42, 0.30, 0.15, 0.04, 0.0])
	if swat > 0.3:
		var paw: Vector2 = p.call(near[1][1])
		for n: float in [-1.0, 0.0, 1.0]:
			var r := paw + Vector2(30, n * 13.0) * k
			b.line(r, r + Vector2(24, n * 5.0) * k * swat, INK, 9.0 * k)
			b.line(r, r + Vector2(21, n * 4.5) * k * swat, Color(0.95, 0.91, 0.80), 5.0 * k)
	# the head: small on that bulk, and turned a little to us
	_face_side(b, up.call(Vector2(190, -288)), k * swell, t, awake, cross)
	b.flush()


static func _pillar(b: ShapeBatch, a: Vector2, f: Vector2, k: float, tint: Color, ink: bool) -> void:
	var g := 6.0 * k if ink else 0.0
	var col := INK if ink else tint
	if ink:
		b.capsule(a, f, 41.0 * k + g, col)
		b.polygon(_oval(f + Vector2(8, 2) * k, Vector2(46, 22) * k + Vector2(g, g), Vector2.RIGHT), col)
		return
	tube(b, a, f, 43.0 * k, 38.0 * k, tint)
	vol(b, f + Vector2(8, 2) * k, Vector2(46, 22) * k, Vector2.RIGHT, tint, 0.7)
	for n: float in [0.0, 1.0]:
		b.line(f + Vector2(26.0 + n * 12.0, 0.0) * k, f + Vector2(29.0 + n * 12.0, 17.0) * k, DARK, 3.0 * k)
	b.glow(f + Vector2(40, 4) * k, 26.0 * k, Color(GOLD, 0.55))


static func _face_side(b: ShapeBatch, h: Vector2, k: float, t: float, awake: float, cross: float) -> void:
	var q := func(v: Vector2) -> Vector2: return h + v * k
	# ears: stubs, rounded; cross, they lie back
	for sd: float in [-1.0, 1.0]:
		var d := Vector2(-0.35 + sd * 0.32, -0.9).normalized().rotated(-0.7 * cross)
		var e: Vector2 = q.call(Vector2(-8.0 + sd * 36.0, -56.0))
		b.polygon(_oval(e, Vector2(34, 25) * k, d), INK)
		vol(b, e, Vector2(29, 20) * k, d, BASE if sd > 0.0 else BASE.darkened(0.3), 0.8)
		b.polygon(_oval(e + d * 4.0 * k, Vector2(16, 9) * k, d, 16), DARK)
		if sd > 0.0:
			b.polygon(PackedVector2Array([e + d * 36.0 * k + d.orthogonal() * 7.0 * k, e + d * 12.0 * k, e + d * 36.0 * k - d.orthogonal() * 5.0 * k]), INK)
	b.polygon(_oval(h, Vector2(84, 76) * k, Vector2.RIGHT, 40), INK)
	vol(b, h, Vector2(78, 70) * k, Vector2.RIGHT, BASE)
	# the features, far out on the moon of it and much too small
	for sd: float in [-1.0, 1.0]:
		vol(b, q.call(Vector2(34.0 + sd * 21.0, 26.0)), Vector2(25, 21) * k, Vector2.RIGHT, BASE.lightened(0.05), 0.75)
	var m: Vector2 = q.call(Vector2(36, 28))
	if cross > 0.05:
		b.ellipse(m + Vector2(0, 20.0 * cross) * k, 19.0 * k, 19.0 * k * cross, INK)
		b.ellipse(m + Vector2(0, 20.0 * cross) * k, 15.0 * k, 15.0 * k * cross, Color(0.36, 0.08, 0.09))
		b.ellipse(m + Vector2(0, 27.0 * cross) * k, 9.0 * k, 5.0 * k * cross, Color(0.80, 0.38, 0.42))
		for sd: float in [-1.0, 1.0]:
			b.polygon(PackedVector2Array([m + Vector2(sd * 12.0, 8.0) * k, m + Vector2(sd * 3.0, 6.0) * k, m + Vector2(sd * 7.0, 8.0 + 17.0 * cross) * k]), Color(0.96, 0.93, 0.84))
	else:
		b.line(m, m + Vector2(0, 11) * k, INK, 3.5 * k)
		for sd: float in [-1.0, 1.0]:
			b.line(m + Vector2(0, 11) * k, m + Vector2(sd * 10.0, 16.0) * k, INK, 3.5 * k)
	b.polygon(PackedVector2Array([q.call(Vector2(23, 4)), q.call(Vector2(49, 4)), q.call(Vector2(36, 20))]), GOLD)
	b.circle(q.call(Vector2(32, 8)), 3.0 * k, SPEC)
	for sd: float in [-1.0, 1.0]:
		for n in range(3):
			var w: Vector2 = q.call(Vector2(34.0 + sd * 30.0, 18.0 + 8.0 * float(n)))
			b.line(w, w + Vector2(sd * 46.0, -10.0 + 9.0 * float(n) + sin(t * 6.0) * 1.5) * k, Color(LIT.lightened(0.15), 0.95), 3.0 * k)
	for sd: float in [-1.0, 1.0]:
		var e: Vector2 = q.call(Vector2(32.0 + sd * 23.0, -14.0))
		b.glow(e, 24.0 * k, Color(DARK, 0.7))
		if awake <= 0.0:
			b.line(e + Vector2(-11, 0) * k, e + Vector2(11, 0) * k, INK, 4.5 * k)
			continue
		if cross > 0.0:
			b.glow(e, 38.0 * k, Color(HOT, 0.75 * cross))
		var hh := (7.0 + 4.0 * cross) * awake * k
		b.ellipse(e, 14.5 * k, hh + 3.0 * k, INK)
		b.ellipse(e, 11.5 * k, hh, AMBER.lerp(HOT, cross))
		b.ellipse(e, 3.0 * k, hh * 0.95, PUPIL)
		b.circle(e + Vector2(-4, -2) * k, 2.2 * k, Color(1, 1, 0.94))
		b.line(e + Vector2(sd * 17.0, -9.0 - 6.0 * cross) * k, e + Vector2(-sd * 14.0, -8.0 + 6.0 * cross) * k, INK, (5.0 + 3.0 * cross) * k)


# lying along his plinth, beaten and delighted, facing left; his underside at
# `at`
static func lying(c: CanvasItem, at: Vector2, k: float, t: float) -> void:
	var b := ShapeBatch.new(c)
	var p := func(v: Vector2) -> Vector2: return at + v * k
	b.polygon(_oval(p.call(Vector2(0, 2)), Vector2(176, 12) * k, Vector2.RIGHT), Color(0, 0, 0, 0.35))
	var tail := PackedVector2Array()
	for i in range(9):
		var u := float(i) / 8.0
		tail.append(p.call(Vector2(138.0 + sin(u * 2.4) * 64.0, -54.0 - u * 110.0 + sin(t * 4.0) * 8.0 * u)))
	for q in tail:
		b.circle(q, 23.0 * k, INK)
	_tail(b, tail, 19.0 * k, 17.0 * k, BASE)
	var bc: Vector2 = p.call(Vector2(10, -92))
	b.polygon(_oval(bc, Vector2(172, 104) * k, Vector2.RIGHT, 48), INK)
	vol(b, bc, Vector2(166, 98) * k, Vector2.RIGHT, BASE)
	for i in range(4):
		var root: Vector2 = p.call(Vector2(-96.0 + 64.0 * float(i), -34.0))
		var foot := root + Vector2(-14.0 + sin(t * 2.0 + float(i)) * 4.0, 22.0) * k
		b.capsule(root, foot, 31.0 * k, INK)
		tube(b, root, foot, 27.0 * k, 25.0 * k, BASE)
		b.glow(foot + Vector2(-8, 6) * k, 22.0 * k, Color(GOLD, 0.55))
	var h: Vector2 = p.call(Vector2(-136, -124))
	for sd: float in [-1.0, 1.0]:
		var d := Vector2(sd * 0.42, -0.9).normalized()
		var e := h + Vector2(sd * 38.0, -50.0) * k
		b.polygon(_oval(e, Vector2(30, 22) * k, d), INK)
		vol(b, e, Vector2(25, 17) * k, d, BASE, 0.8)
		b.polygon(_oval(e + d * 4.0 * k, Vector2(14, 8) * k, d, 16), DARK)
	b.polygon(_oval(h, Vector2(78, 70) * k, Vector2.RIGHT, 40), INK)
	vol(b, h, Vector2(72, 64) * k, Vector2.RIGHT, BASE)
	for sd: float in [-1.0, 1.0]:
		vol(b, h + Vector2(-10.0 + sd * 19.0, 24.0) * k, Vector2(23, 19) * k, Vector2.RIGHT, BASE.lightened(0.05), 0.75)
		var e := h + Vector2(-10.0 + sd * 22.0, -10.0) * k
		b.line(e + Vector2(-11, 4) * k, e + Vector2(0, -4) * k, INK, 4.5 * k)
		b.line(e + Vector2(0, -4) * k, e + Vector2(11, 4) * k, INK, 4.5 * k)
		b.line(h + Vector2(-10, 37) * k, h + Vector2(-10.0 + sd * 11.0, 43.0) * k, INK, 3.5 * k)
		for n in range(3):
			var w := h + Vector2(-10.0 + sd * 28.0, 17.0 + 7.0 * float(n)) * k
			b.line(w, w + Vector2(sd * 40.0, -8.0 + 8.0 * float(n)) * k, Color(LIT.lightened(0.15), 0.95), 2.6 * k)
	b.polygon(PackedVector2Array([h + Vector2(-22, 4) * k, h + Vector2(2, 4) * k, h + Vector2(-10, 19) * k]), GOLD)
	b.flush()
