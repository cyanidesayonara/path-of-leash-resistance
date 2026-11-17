extends RefCounted

# The walks' own dare-givers (entities/challenger.gd WHO), drawn from above
# like every person in the game: feet, a body disc, a head turned by which
# way they face, and the thing that makes them who they are held out where
# it reads. `c` is the challenger node, which they draw on; `fd` the way
# they face (the middle of the path), `t` the animation clock in seconds and
# `s` the giver's own phase offset, so two of them never move in step.

const HumanLook := preload("res://entities/human_appearance.gd")


# Draws `who`, or returns false if the cast has no such giver.
static func draw(c: Node2D, who: String, fd: Vector2, t: float, s: float) -> bool:
	match who:
		"kite":
			_kite(c, fd, t, s)
		"umbrella":
			_umbrella(c, fd, t, s)
		"baker":
			_baker(c, fd, t, s)
		"picker":
			_picker(c, fd, t, s)
		"castanyera":
			_castanyera(c, fd, t, s)
		"scrapper":
			_scrapper(c, fd, t, s)
		"nightowl":
			_nightowl(c, fd, t, s)
		"flamenco":
			_flamenco(c, fd, t, s)
		"catlady":
			_catlady(c, fd, t, s)
		"balloons":
			_balloons(c, fd, t)
		"hiker":
			_hiker(c, fd, t, s)
		"gardener":
			_gardener(c, fd, t, s)
		"surfer":
			_surfer(c, fd, t, s)
		"ranger":
			_ranger(c, fd, t, s)
		"drummer":
			_drummer(c, fd, t, s)
		"photographer":
			_photographer(c, fd, t, s)
		"chess":
			_chess(c, fd, t, s)
		"drone":
			_drone(c, fd, t, s)
		"bubbles":
			_bubbles(c, fd, t, s)
		"fortune":
			_fortune(c, fd, t, s)
		"guide":
			_guide(c, fd, t, s)
		"skateboarder":
			_skateboarder(c, fd, t, s)
		"potter":
			_potter(c, fd, t, s)
		"juggler":
			_juggler(c, fd, t, s)
		"devil":
			_devil(c, fd, t, s)
		"pilot":
			_pilot(c, fd, t, s)
		"monk":
			_monk(c, fd, t, s)
		"instructor":
			_instructor(c, fd, t, s)
		"rider":
			_rider(c, fd, t, s)
		"cook":
			_cook(c, fd, t, s)
		"sketcher":
			_sketcher(c, fd, t, s)
		_:
			return false
	return true


# --- shared parts ----------------------------------------------------------------------

static func _person(c: Node2D, at: Vector2, fd: Vector2, shirt: Color, skin: Color, hair: Color, style: String,
		headwear: String, headwear_col: Color) -> void:
	var env: Array = HumanLook.env(c)
	var dress: Dictionary = HumanLook.outfit(String(env[0]), String(env[1]), bool(env[2]), 5, shirt, headwear,
		headwear_col, "none")
	HumanLook.draw_torso(c, at, fd, Vector2(10.0, 12.5), dress["shirt"], bool(dress["coat"]), dress["scarf"])
	HumanLook.draw_head(c, at + fd * 5.0, fd, 8.0, skin, hair, style, String(dress["headwear"]), dress["headwear_col"])


static func _bar(at: Vector2, side: Vector2, length: float, depth: float) -> PackedVector2Array:
	var fwd := side.orthogonal()
	var h := side * (length * 0.5)
	var d := fwd * (depth * 0.5)
	return PackedVector2Array([at - h - d, at + h - d, at + h + d, at - h + d])


static func _shadow(c: Node2D, at: Vector2, rx: float, ry: float) -> void:
	var m: Node2D = c.get("main")
	if m != null:
		m.cast_shadow(c, at, rx, ry, 0.2)


# shoes showing in front of a standing figure
static func _shoes(c: Node2D, fd: Vector2, side: Vector2, shoe: Color, apart := 6.0) -> void:
	for e: float in [-1.0, 1.0]:
		c.draw_circle(side * e * apart + fd * 9.0, 3.4, shoe)


# legs out in front of a seated one
static func _seat_legs(c: Node2D, at: Vector2, fd: Vector2, side: Vector2, legs: Color, shoe: Color) -> void:
	for e: float in [-1.0, 1.0]:
		c.draw_line(at + side * e * 5.0, at + side * e * 6.0 + fd * 16.0, legs, 6.0)
		c.draw_circle(at + side * e * 6.0 + fd * 18.0, 3.6, shoe)


static func _arm(c: Node2D, from: Vector2, to: Vector2, sleeve: Color, hand: Color) -> void:
	c.draw_line(from, to, sleeve, 3.8)
	c.draw_circle(to, 2.8, hand)


# --- the cast --------------------------------------------------------------------------

# El Parc: flying a kite, the string up to it where it dips and climbs on
# the wind, its tail of bows behind
static func _kite(c: Node2D, fd: Vector2, t: float, s: float) -> void:
	var side := fd.orthogonal()
	var skin := Color(0.86, 0.68, 0.52)
	_shadow(c, Vector2.ZERO, 12.0, 14.0)
	_shoes(c, fd, side, Color(0.94, 0.40, 0.30))
	_person(c, Vector2.ZERO, fd, Color(0.30, 0.62, 0.86), skin, Color(0.40, 0.24, 0.14), "short", "cap",
		Color(0.94, 0.40, 0.30))
	var hand := side * 13.0 + fd * 8.0
	_arm(c, side * 8.0, hand, Color(0.30, 0.62, 0.86), skin)
	var kite := -fd * 34.0 + side * (40.0 + sin(t * 1.1 + s) * 6.0) + fd * cos(t * 0.8 + s) * 4.0
	c.draw_line(hand, kite, Color(0.96, 0.96, 0.94, 0.7), 1.0)
	c.draw_colored_polygon(PackedVector2Array([kite - fd * 11.0, kite + side * 8.0, kite + fd * 8.0, kite - side * 8.0]),
		Color(0.96, 0.82, 0.20))
	c.draw_colored_polygon(PackedVector2Array([kite - fd * 11.0, kite + side * 8.0, kite]), Color(0.90, 0.26, 0.30))
	c.draw_colored_polygon(PackedVector2Array([kite + fd * 8.0, kite - side * 8.0, kite]), Color(0.90, 0.26, 0.30))
	var tail := kite + fd * 8.0
	var bows: Array[Color] = [Color(0.30, 0.56, 0.86), Color(0.90, 0.26, 0.30), Color(0.30, 0.70, 0.40)]
	for k in range(3):
		var p := tail + fd * 7.0 + side * sin(t * 3.0 + float(k) + s) * 4.0
		c.draw_line(tail, p, Color(0.20, 0.20, 0.22, 0.6), 0.8)
		c.draw_circle(p, 2.0, bows[k])
		tail = p


# El Diluvi: selling umbrellas in the rain, one open over his head, the rest
# rolled in a bundle under his arm
static func _umbrella(c: Node2D, fd: Vector2, t: float, s: float) -> void:
	var side := fd.orthogonal()
	var skin := Color(0.62, 0.44, 0.32)
	_shadow(c, Vector2.ZERO, 14.0, 14.0)
	_shoes(c, fd, side, Color(0.14, 0.14, 0.16))
	var cols: Array[Color] = [Color(0.86, 0.22, 0.26), Color(0.20, 0.42, 0.74), Color(0.96, 0.78, 0.18),
		Color(0.18, 0.18, 0.20), Color(0.30, 0.64, 0.40)]
	for k in range(5):
		var a := -side * 12.0 + fd * (float(k) - 2.0) * 2.6
		c.draw_line(a - fd * 3.0 - side * 4.0, a + fd * 3.0 - side * 4.0 + fd * 16.0, cols[k], 2.4)
	_person(c, Vector2.ZERO, fd, Color(0.36, 0.38, 0.30), skin, Color(0.10, 0.08, 0.08), "short", "none", Color.BLACK)
	# the open one, over him: eight panels in two colours, and its tip
	var top := -fd * 2.0 + side * 3.0
	# turning it in his hand, the way a seller does to show it off
	var turn := t * 0.9 + s
	for k in range(8):
		var a0 := float(k) / 8.0 * TAU + turn
		var a1 := float(k + 1) / 8.0 * TAU + turn
		c.draw_colored_polygon(PackedVector2Array([top, top + Vector2.from_angle(a0) * 19.0, top + Vector2.from_angle(a1) * 19.0]),
			Color(0.20, 0.42, 0.74, 0.94) if k % 2 == 0 else Color(0.96, 0.94, 0.90, 0.94))
	c.draw_circle(top, 1.8, Color(0.12, 0.12, 0.12))


# Sarrià at dawn: the baker out of the shop with a tray of loaves, flour on
# his apron and a baker's cap
static func _baker(c: Node2D, fd: Vector2, t: float, s: float) -> void:
	var side := fd.orthogonal()
	var skin := Color(0.88, 0.70, 0.56)
	var white := Color(0.96, 0.95, 0.92)
	_shadow(c, Vector2.ZERO, 13.0, 14.0)
	_shoes(c, fd, side, Color(0.20, 0.18, 0.18))
	_person(c, Vector2.ZERO, fd, white, skin, Color(0.30, 0.22, 0.16), "short", "none", Color.BLACK)
	var head := fd * 5.0
	c.draw_circle(head, 7.6, Color(0.98, 0.98, 0.96))
	c.draw_circle(head - fd * 1.0, 5.0, Color(0.90, 0.90, 0.88))
	# holding the tray out to you, and back, and out again
	var tray := fd * (16.0 + maxf(0.0, sin(t * 1.8 + s)) * 3.0)
	c.draw_colored_polygon(_bar(tray, side, 30.0, 12.0), Color(0.52, 0.36, 0.20))
	for k in range(3):
		var lp := tray + side * (float(k) - 1.0) * 9.0
		c.draw_colored_polygon(_bar(lp, side, 7.0, 9.0), Color(0.80, 0.56, 0.26))
		c.draw_line(lp - fd * 3.0, lp + fd * 3.0, Color(0.92, 0.76, 0.48), 1.2)
	_arm(c, side * 9.0, tray + side * 13.0, white, skin)
	_arm(c, -side * 9.0, tray - side * 13.0, white, skin)


# El Bosc: a boletaire with his wicker basket of mushrooms, beret on, his
# knife out over a find
static func _picker(c: Node2D, fd: Vector2, t: float, s: float) -> void:
	var side := fd.orthogonal()
	var skin := Color(0.84, 0.64, 0.50)
	var jacket := Color(0.36, 0.42, 0.28)
	_shadow(c, Vector2.ZERO, 14.0, 14.0)
	var basket := side * 16.0 + fd * 4.0
	c.draw_circle(basket, 9.0, Color(0.54, 0.38, 0.20))
	c.draw_arc(basket, 9.0, 0.0, TAU, 16, Color(0.40, 0.28, 0.14), 1.6)
	for k in range(4):
		var mp := basket + Vector2.from_angle(float(k) * 1.6 + 0.4) * 4.0
		c.draw_circle(mp, 3.0, Color(0.50, 0.30, 0.16))
		c.draw_circle(mp - Vector2(0.8, 0.8), 1.2, Color(0.72, 0.52, 0.32))
	c.draw_line(basket - side * 9.0, basket + side * 9.0, Color(0.40, 0.28, 0.14), 1.6)
	_shoes(c, fd, side, Color(0.30, 0.22, 0.16))
	_person(c, Vector2.ZERO, fd, jacket, skin, Color(0.56, 0.54, 0.52), "bald_spot", "none", Color.BLACK)
	c.draw_circle(fd * 4.0, 7.8, Color(0.16, 0.16, 0.18))
	c.draw_circle(fd * 4.0 - side * 1.5, 1.2, Color(0.08, 0.08, 0.08))
	# working the knife round the stalk of his find
	var cut := -side * (6.0 + sin(t * 4.0 + s) * 2.0) + fd * 14.0
	_arm(c, -side * 8.0, cut, jacket, skin)
	c.draw_line(cut, cut + fd * 6.0 + side * 1.5, Color(0.70, 0.72, 0.74), 1.4)
	var shroom := fd * 24.0 - side * 4.0
	c.draw_circle(shroom, 3.6, Color(0.62, 0.36, 0.18))
	c.draw_circle(shroom - Vector2(1.0, 1.0), 1.4, Color(0.82, 0.60, 0.36))


# La Castanyada: the castanyera at her brazier, chestnuts roasting, a paper
# cone of them held out, a shawl round her shoulders
static func _castanyera(c: Node2D, fd: Vector2, t: float, s: float) -> void:
	var side := fd.orthogonal()
	var skin := Color(0.86, 0.70, 0.58)
	var dress := Color(0.42, 0.20, 0.24)
	var at := -fd * 6.0
	_shadow(c, at, 15.0, 15.0)
	var br := fd * 14.0
	c.draw_circle(br, 14.0, Color(0.22, 0.20, 0.20))
	c.draw_circle(br, 11.0, Color(0.10, 0.08, 0.08))
	var glow := 0.75 + 0.25 * sin(t * 4.0 + s)
	c.draw_circle(br, 9.0, Color(0.96, 0.40, 0.10, 0.55 * glow))
	for k in range(7):
		var cp := br + Vector2.from_angle(float(k) * 0.9 + 0.3) * (3.0 + float(k % 3) * 2.2)
		c.draw_circle(cp, 2.2, Color(0.36, 0.18, 0.10))
		c.draw_circle(cp - Vector2(0.6, 0.6), 0.8, Color(0.62, 0.34, 0.18))
	_seat_legs(c, at, fd, side, Color(0.20, 0.18, 0.22), Color(0.14, 0.12, 0.12))
	_person(c, at, fd, dress, skin, Color(0.74, 0.74, 0.76), "bun", "none", Color.BLACK)
	c.draw_arc(at, 11.0, fd.angle() + PI - 1.8, fd.angle() + PI + 1.8, 12, Color(0.20, 0.30, 0.22), 3.0)
	var cone := at + side * 15.0 + fd * 6.0
	_arm(c, at + side * 8.0, cone, dress, skin)
	c.draw_colored_polygon(PackedVector2Array([cone, cone + side * 6.0 - fd * 4.0, cone + side * 6.0 + fd * 4.0]),
		Color(0.94, 0.92, 0.86))


# La Ferralla: the scrap dealer and his trolley piled with metal
static func _scrapper(c: Node2D, fd: Vector2, t: float, s: float) -> void:
	var side := fd.orthogonal()
	var skin := Color(0.72, 0.52, 0.40)
	var shirt := Color(0.56, 0.40, 0.26)
	_shadow(c, Vector2.ZERO, 16.0, 14.0)
	# rocking his trolley, the scrap in it rattling
	var rock := sin(t * 2.2 + s)
	var cart := fd * (17.0 + rock * 1.6) + side * 4.0
	c.draw_colored_polygon(_bar(cart, side, 30.0, 22.0), Color(0.62, 0.64, 0.66))
	c.draw_colored_polygon(_bar(cart, side, 26.0, 18.0), Color(0.30, 0.30, 0.32))
	var junk: Array[Color] = [Color(0.66, 0.40, 0.24), Color(0.74, 0.76, 0.78), Color(0.46, 0.34, 0.28), Color(0.56, 0.58, 0.60)]
	for k in range(6):
		var jp := cart + side * (float(k % 3) - 1.0) * 8.0 + fd * (float(k / 3) - 0.5) * 8.0 \
			+ side * sin(t * 13.0 + float(k)) * 0.6 * absf(rock)
		c.draw_line(jp - side * 5.0 + fd * 2.0, jp + side * 5.0 - fd * 2.0, junk[k % junk.size()], 3.4)
	c.draw_circle(cart + side * 9.0 - fd * 3.0, 4.0, Color(0.74, 0.76, 0.78))
	c.draw_circle(cart + side * 9.0 - fd * 3.0, 2.2, Color(0.30, 0.30, 0.32))
	c.draw_line(cart - fd * 11.0 - side * 13.0, cart - fd * 11.0 + side * 13.0, Color(0.40, 0.40, 0.42), 2.0)
	_shoes(c, fd, side, Color(0.20, 0.18, 0.16))
	_person(c, Vector2.ZERO, fd, shirt, skin, Color(0.16, 0.12, 0.10), "short", "cap", Color(0.24, 0.26, 0.30))
	_arm(c, side * 8.0, cart - fd * 11.0 + side * 8.0, shirt, skin)
	_arm(c, -side * 8.0, cart - fd * 11.0 - side * 4.0, shirt, skin)


# La Neteja: a night owl on the way home at dawn, sunglasses on, a glow
# stick round her neck and another round her wrist, her heels in her hand
static func _nightowl(c: Node2D, fd: Vector2, t: float, s: float) -> void:
	var side := fd.orthogonal()
	var skin := Color(0.90, 0.74, 0.62)
	var dress := Color(0.16, 0.14, 0.20)
	var at := side * sin(t * 1.3 + s) * 1.5
	_shadow(c, at, 12.0, 14.0)
	for e: float in [-1.0, 1.0]:
		c.draw_circle(at + side * e * 6.0 + fd * 9.0, 3.0, skin)
	_person(c, at, fd, dress, skin, Color(0.86, 0.66, 0.30), "long", "none", Color.BLACK)
	c.draw_arc(at + fd * 2.0, 8.0, fd.angle() - 1.6, fd.angle() + 1.6, 12, Color(0.40, 1.0, 0.50), 2.0)
	var hand := at - side * 14.0 + fd * 6.0
	_arm(c, at - side * 8.0, hand, dress, skin)
	c.draw_arc(hand, 3.6, 0.0, TAU, 10, Color(1.0, 0.36, 0.80), 1.6)
	for e: float in [-1.0, 1.0]:
		c.draw_colored_polygon(_bar(hand + fd * 6.0 + side * e * 2.5, side, 4.0, 9.0), Color(0.86, 0.14, 0.24))
	var head := at + fd * 5.0
	for e: float in [-1.0, 1.0]:
		c.draw_circle(head + fd * 5.0 + side * e * 3.4, 2.4, Color(0.06, 0.06, 0.08))
	c.draw_line(head + fd * 5.0 - side * 3.4, head + fd * 5.0 + side * 3.4, Color(0.06, 0.06, 0.08), 1.0)


# Plaça Reial: a flamenco dancer, polka-dot dress and frilled skirt, a
# flower in her hair, one arm up and her fan flicking open and shut
static func _flamenco(c: Node2D, fd: Vector2, t: float, s: float) -> void:
	var side := fd.orthogonal()
	var skin := Color(0.84, 0.64, 0.50)
	var red := Color(0.82, 0.12, 0.16)
	_shadow(c, Vector2.ZERO, 15.0, 15.0)
	for k in range(12):
		c.draw_circle(Vector2.from_angle(float(k) / 12.0 * TAU) * 13.0, 5.0, red.darkened(0.12) if k % 2 == 0 else red)
	c.draw_circle(Vector2.ZERO, 13.0, red)
	for k in range(8):
		c.draw_circle(Vector2.from_angle(float(k) * 0.8 + 0.3) * 10.0, 1.4, Color(0.98, 0.96, 0.92))
	_person(c, Vector2.ZERO, fd, red, skin, Color(0.08, 0.06, 0.06), "bun", "none", Color.BLACK)
	c.draw_circle(fd * 2.0 - side * 6.0, 2.6, Color(0.98, 0.30, 0.40))
	_arm(c, side * 8.0, side * 12.0 - fd * 6.0, red, skin)
	var hand := -side * 13.0 + fd * 8.0
	_arm(c, -side * 8.0, hand, red, skin)
	var open := 0.5 + 0.5 * sin(t * 3.4 + s)
	var fa := (-side).angle()
	c.draw_colored_polygon(PackedVector2Array([hand, hand + Vector2.from_angle(fa - 0.9 * open - 0.1) * 12.0,
		hand + Vector2.from_angle(fa) * 13.0, hand + Vector2.from_angle(fa + 0.9 * open + 0.1) * 12.0]),
		Color(0.10, 0.08, 0.10))


# El Veterinari: a cat owner with the cat in its carrier, two eyes glaring
# out through the grille at the dog
static func _catlady(c: Node2D, fd: Vector2, t: float, s: float) -> void:
	var side := fd.orthogonal()
	var skin := Color(0.90, 0.74, 0.62)
	var cardigan := Color(0.62, 0.40, 0.62)
	_shadow(c, Vector2.ZERO, 15.0, 14.0)
	var box := side * 16.0 + fd * 6.0
	c.draw_colored_polygon(_bar(box, side, 16.0, 22.0), Color(0.72, 0.74, 0.78))
	c.draw_colored_polygon(_bar(box + fd * 9.0, side, 14.0, 4.0), Color(0.20, 0.20, 0.22))
	if fmod(t + s, 3.6) >= 0.15:
		for e: float in [-1.0, 1.0]:
			c.draw_circle(box + fd * 9.0 + side * e * 3.0, 1.4, Color(0.98, 0.84, 0.20))
	c.draw_line(box - fd * 11.0 - side * 4.0, box - fd * 11.0 + side * 4.0, Color(0.30, 0.30, 0.32), 2.0)
	_shoes(c, fd, side, Color(0.50, 0.30, 0.36))
	_person(c, Vector2.ZERO, fd, cardigan, skin, Color(0.82, 0.82, 0.84), "curly", "none", Color.BLACK)
	_arm(c, side * 8.0, box - fd * 11.0, cardigan, skin)


# El Tibidabo: the balloon seller, his bunch bobbing over his head
static func _balloons(c: Node2D, fd: Vector2, t: float) -> void:
	var side := fd.orthogonal()
	var skin := Color(0.84, 0.66, 0.52)
	var shirt := Color(0.92, 0.80, 0.30)
	_shadow(c, Vector2.ZERO, 12.0, 14.0)
	_shoes(c, fd, side, Color(0.22, 0.20, 0.20))
	_person(c, Vector2.ZERO, fd, shirt, skin, Color(0.24, 0.18, 0.14), "short", "cap", Color(0.86, 0.22, 0.26))
	var hand := side * 13.0 + fd * 2.0
	_arm(c, side * 8.0, hand, shirt, skin)
	var cols: Array[Color] = [Color(0.92, 0.22, 0.28), Color(0.24, 0.52, 0.90), Color(0.98, 0.80, 0.18),
		Color(0.30, 0.74, 0.42), Color(0.86, 0.40, 0.84), Color(0.98, 0.56, 0.18)]
	for k in range(6):
		var a := float(k) / 6.0 * TAU + 0.3
		var bp := hand - fd * 14.0 + side * 6.0 + Vector2.from_angle(a) * 10.0 \
			+ Vector2(sin(t * 1.4 + float(k)), cos(t * 1.1 + float(k))) * 1.6
		c.draw_line(hand, bp, Color(0.96, 0.96, 0.94, 0.5), 0.8)
		c.draw_circle(bp, 6.0, cols[k])
		c.draw_circle(bp - Vector2(2.0, 2.0), 1.8, Color(1.0, 1.0, 1.0, 0.55))


# La Carretera de les Aigües: a hiker with her pack and two poles, sun hat on
static func _hiker(c: Node2D, fd: Vector2, t: float, s: float) -> void:
	var side := fd.orthogonal()
	var skin := Color(0.82, 0.62, 0.48)
	var shirt := Color(0.30, 0.56, 0.62)
	_shadow(c, Vector2.ZERO, 13.0, 15.0)
	var pack := -fd * 9.0
	c.draw_colored_polygon(_bar(pack, side, 20.0, 14.0), Color(0.86, 0.34, 0.20))
	c.draw_colored_polygon(_bar(pack - fd * 4.0, side, 14.0, 5.0), Color(0.70, 0.26, 0.16))
	c.draw_colored_polygon(_bar(pack - fd * 9.0, side, 16.0, 5.0), Color(0.26, 0.40, 0.30))
	_shoes(c, fd, side, Color(0.40, 0.28, 0.18), 7.0)
	_person(c, Vector2.ZERO, fd, shirt, skin, Color(0.52, 0.32, 0.18), "long", "sunhat", Color(0.86, 0.78, 0.56))
	# catching her breath, leaning on one pole and then the other
	for e: float in [-1.0, 1.0]:
		var lean := maxf(0.0, sin(t * 1.6 + s + (PI if e > 0.0 else 0.0))) * 3.0
		var hand := side * e * 14.0 + fd * (6.0 + lean)
		_arm(c, side * e * 8.0, hand, shirt, skin)
		c.draw_line(hand, hand + fd * 14.0 + side * e * 3.0, Color(0.70, 0.72, 0.76), 1.6)
		c.draw_circle(hand + fd * 14.0 + side * e * 3.0, 1.4, Color(0.16, 0.16, 0.18))


# El Laberint d'Horta: the gardener with his hedge shears snipping, straw hat
# and green overalls
static func _gardener(c: Node2D, fd: Vector2, t: float, s: float) -> void:
	var side := fd.orthogonal()
	var skin := Color(0.80, 0.60, 0.46)
	var green := Color(0.26, 0.46, 0.30)
	_shadow(c, Vector2.ZERO, 13.0, 14.0)
	_shoes(c, fd, side, Color(0.22, 0.30, 0.20))
	_person(c, Vector2.ZERO, fd, green, skin, Color(0.40, 0.30, 0.20), "short", "sunhat", Color(0.90, 0.80, 0.52))
	var grip := fd * 14.0
	_arm(c, side * 8.0, grip + side * 4.0, green, skin)
	_arm(c, -side * 8.0, grip - side * 4.0, green, skin)
	var snip := 0.12 + 0.18 * absf(sin(t * 5.0 + s))
	for e: float in [-1.0, 1.0]:
		c.draw_line(grip + side * e * 3.0, grip + fd.rotated(e * snip) * 16.0, Color(0.74, 0.76, 0.78), 2.2)
	for k in range(3):
		c.draw_circle(grip + fd * (20.0 + float(k) * 4.0) + side * (float(k) - 1.0) * 5.0, 1.8, Color(0.30, 0.52, 0.26))


# Platja de Llevant: a surfer waiting on the waves, board under his arm,
# wetsuit and salty hair
static func _surfer(c: Node2D, fd: Vector2, t: float, s: float) -> void:
	var side := fd.orthogonal()
	var skin := Color(0.78, 0.56, 0.40)
	var suit := Color(0.10, 0.10, 0.12)
	_shadow(c, Vector2.ZERO, 14.0, 18.0)
	var board := side * 15.0
	var tilt := fd.rotated(sin(t * 1.1 + s) * 0.07)
	var a := board - tilt * 26.0
	var b := board + tilt * 22.0
	c.draw_line(a, b, Color(0.96, 0.94, 0.88), 11.0)
	c.draw_circle(a, 5.5, Color(0.96, 0.94, 0.88))
	c.draw_circle(b, 5.5, Color(0.96, 0.94, 0.88))
	c.draw_line(a + fd * 4.0, b - fd * 4.0, Color(0.20, 0.62, 0.78), 2.0)
	_shoes(c, fd, side, skin)
	# looking out over the water for a wave that is not coming
	_person(c, Vector2.ZERO, fd.rotated(sin(t * 0.5 + s) * 0.35), suit, skin, Color(0.84, 0.70, 0.38), "long", "none",
		Color.BLACK)
	_arm(c, side * 8.0, board + tilt * 4.0 - side * 4.0, suit, skin)


# Els Senglars: a forest ranger watching for boars through her binoculars,
# looking slowly one way and the other
static func _ranger(c: Node2D, fd: Vector2, t: float, s: float) -> void:
	var side := fd.orthogonal()
	var skin := Color(0.82, 0.62, 0.48)
	var khaki := Color(0.56, 0.52, 0.34)
	_shadow(c, Vector2.ZERO, 13.0, 14.0)
	_shoes(c, fd, side, Color(0.30, 0.22, 0.14), 7.0)
	var look := fd.rotated(sin(t * 0.6 + s) * 0.5)
	_person(c, Vector2.ZERO, look, khaki, skin, Color(0.30, 0.20, 0.12), "short", "sunhat", Color(0.40, 0.32, 0.20))
	var bino := look * 13.0
	for e: float in [-1.0, 1.0]:
		_arm(c, side * e * 8.0, bino + look.orthogonal() * e * 3.4, khaki, skin)
		c.draw_circle(bino + look.orthogonal() * e * 3.0 + look * 2.0, 2.8, Color(0.14, 0.14, 0.16))
	# her badge
	c.draw_circle(side * 4.0 + fd * 1.0, 1.8, Color(0.86, 0.80, 0.30))


# Festa de Gràcia: a festival drummer, the drum slung at his belly and the
# sticks coming down in turn
static func _drummer(c: Node2D, fd: Vector2, t: float, s: float) -> void:
	var side := fd.orthogonal()
	var skin := Color(0.84, 0.66, 0.52)
	var shirt := Color(0.12, 0.12, 0.14)
	_shadow(c, Vector2.ZERO, 14.0, 15.0)
	_shoes(c, fd, side, Color(0.94, 0.94, 0.92), 7.0)
	_person(c, Vector2.ZERO, fd, shirt, skin, Color(0.20, 0.14, 0.10), "curly", "none", Color.BLACK)
	c.draw_arc(Vector2.ZERO, 10.0, fd.angle() - 1.2, fd.angle() + 1.2, 10, Color(0.86, 0.20, 0.20), 3.0)
	var drum := fd * 16.0
	c.draw_circle(drum, 11.0, Color(0.72, 0.16, 0.16))
	c.draw_circle(drum, 9.0, Color(0.96, 0.92, 0.82))
	for k in range(8):
		var a := float(k) / 8.0 * TAU
		c.draw_line(drum + Vector2.from_angle(a) * 9.0, drum + Vector2.from_angle(a) * 11.0, Color(0.96, 0.82, 0.30), 1.2)
	for e: float in [-1.0, 1.0]:
		var hit := maxf(0.0, sin(t * 8.0 + s + (PI if e > 0.0 else 0.0)))
		var hand := side * e * 9.0 + fd * (6.0 + hit * 3.0)
		_arm(c, side * e * 8.0, hand, shirt, skin)
		c.draw_line(hand, drum + side * e * 3.0 - fd * (hit * 4.0 - 2.0), Color(0.76, 0.58, 0.34), 1.8)


# Els Búnquers: a photographer at her tripod, the camera on the sunset
static func _photographer(c: Node2D, fd: Vector2, t: float, s: float) -> void:
	var side := fd.orthogonal()
	var skin := Color(0.88, 0.72, 0.60)
	var coat := Color(0.24, 0.24, 0.30)
	_shadow(c, Vector2.ZERO, 13.0, 14.0)
	var tri := fd * 16.0
	for k in range(3):
		c.draw_line(tri, tri + Vector2.from_angle(fd.angle() + float(k) / 3.0 * TAU + 0.5) * 12.0, Color(0.20, 0.20, 0.22), 1.6)
	c.draw_colored_polygon(_bar(tri, side, 12.0, 8.0), Color(0.14, 0.14, 0.16))
	c.draw_circle(tri + fd * 5.0, 3.4, Color(0.26, 0.28, 0.32))
	c.draw_circle(tri + fd * 5.0, 1.8, Color(0.50, 0.66, 0.86))
	# a shot every few seconds: the flash, bright and gone
	var shot := fmod(t + s, 3.2)
	if shot < 0.16:
		c.draw_circle(tri + fd * 7.0, 6.0 + shot * 30.0, Color(1.0, 1.0, 0.94, 0.7 * (1.0 - shot / 0.16)))
	_shoes(c, fd, side, Color(0.30, 0.28, 0.30))
	_person(c, Vector2.ZERO, fd, coat, skin, Color(0.70, 0.20, 0.16), "long", "beanie", Color(0.92, 0.70, 0.20))
	# her hand on the focus ring, turning it
	var focus := fd * sin(t * 1.7 + s) * 1.5
	_arm(c, side * 8.0, tri + side * 5.0 - fd * 3.0 + focus, coat, skin)
	_arm(c, -side * 8.0, tri - side * 5.0 - fd * 3.0, coat, skin)


# La Superilla: a chess player at an outdoor table, the board set, waiting
# for somebody to sit down opposite, his hand hovering over a piece
static func _chess(c: Node2D, fd: Vector2, t: float, s: float) -> void:
	var side := fd.orthogonal()
	var skin := Color(0.80, 0.62, 0.50)
	var jumper := Color(0.60, 0.52, 0.40)
	var at := -fd * 8.0
	_shadow(c, fd * 4.0, 16.0, 16.0)
	var table := fd * 10.0
	c.draw_colored_polygon(_bar(table, side, 26.0, 26.0), Color(0.46, 0.40, 0.34))
	for i in range(4):
		for j in range(4):
			var sq := table + side * (float(i) - 1.5) * 5.0 + fd * (float(j) - 1.5) * 5.0
			c.draw_colored_polygon(_bar(sq, side, 5.0, 5.0),
				Color(0.94, 0.92, 0.86) if (i + j) % 2 == 0 else Color(0.20, 0.18, 0.16))
	for p: Vector3 in [Vector3(0, 0, 1), Vector3(3, 0, 1), Vector3(1, 3, 0), Vector3(2, 2, 0), Vector3(3, 3, 0)]:
		var pc := table + side * (p.x - 1.5) * 5.0 + fd * (p.y - 1.5) * 5.0
		c.draw_circle(pc, 1.8, Color(0.98, 0.96, 0.92) if p.z > 0.5 else Color(0.10, 0.10, 0.10))
	_seat_legs(c, at, fd, side, Color(0.30, 0.28, 0.26), Color(0.16, 0.14, 0.12))
	_person(c, at, fd, jumper, skin, Color(0.78, 0.78, 0.80), "bald_spot", "none", Color.BLACK)
	_arm(c, at + side * 8.0, at + fd * 6.0 + side * 2.0, jumper, skin)
	_arm(c, at - side * 8.0, table - fd * 4.0 - side * (4.0 + sin(t * 1.2 + s) * 2.0), jumper, skin)


# El Fòrum: a drone pilot, the controller in both hands and the drone
# hovering out over the esplanade, its rotors a blur
static func _drone(c: Node2D, fd: Vector2, t: float, s: float) -> void:
	var side := fd.orthogonal()
	var skin := Color(0.76, 0.56, 0.42)
	var jacket := Color(0.22, 0.30, 0.42)
	_shadow(c, Vector2.ZERO, 12.0, 14.0)
	_shoes(c, fd, side, Color(0.20, 0.22, 0.30))
	_person(c, Vector2.ZERO, fd, jacket, skin, Color(0.12, 0.10, 0.08), "short", "cap", Color(0.14, 0.14, 0.16))
	var ctl := fd * 12.0
	_arm(c, side * 8.0, ctl + side * 4.0, jacket, skin)
	_arm(c, -side * 8.0, ctl - side * 4.0, jacket, skin)
	c.draw_colored_polygon(_bar(ctl, side, 12.0, 6.0), Color(0.16, 0.16, 0.18))
	var dp := fd * 40.0 + side * (12.0 + sin(t * 0.9 + s) * 6.0) + fd * cos(t * 1.3 + s) * 4.0
	_shadow(c, dp + Vector2(10.0, 14.0), 8.0, 8.0)
	for k in range(4):
		var arm := Vector2.from_angle(float(k) * PI * 0.5 + PI * 0.25) * 8.0
		c.draw_line(dp, dp + arm, Color(0.30, 0.30, 0.32), 2.0)
		c.draw_circle(dp + arm, 4.6, Color(0.70, 0.72, 0.76, 0.35))
		var blade := Vector2.from_angle(t * 40.0 + float(k)) * 4.0
		c.draw_line(dp + arm - blade, dp + arm + blade, Color(0.20, 0.20, 0.22), 1.0)
	c.draw_circle(dp, 3.6, Color(0.92, 0.92, 0.94))
	c.draw_circle(dp + fd * 2.0, 1.2, Color(0.96, 0.30, 0.20))


# Plaça d'Espanya: a bubble maker, the rope loop between two sticks and a
# giant bubble wobbling off it, her bucket of soap at her feet
static func _bubbles(c: Node2D, fd: Vector2, t: float, s: float) -> void:
	var side := fd.orthogonal()
	var skin := Color(0.86, 0.68, 0.54)
	var top := Color(0.56, 0.30, 0.70)
	_shadow(c, Vector2.ZERO, 12.0, 14.0)
	c.draw_circle(-side * 12.0 + fd * 2.0, 5.0, Color(0.92, 0.92, 0.96))
	c.draw_circle(-side * 12.0 + fd * 2.0, 3.6, Color(0.70, 0.84, 0.96))
	_shoes(c, fd, side, Color(0.30, 0.20, 0.40))
	_person(c, Vector2.ZERO, fd, top, skin, Color(0.90, 0.70, 0.30), "curly", "none", Color.BLACK)
	var h0 := side * 13.0 + fd * 6.0
	var h1 := side * 4.0 + fd * 14.0
	_arm(c, side * 8.0, h0, top, skin)
	_arm(c, -side * 6.0, h1, top, skin)
	c.draw_line(h0, h0 + fd * 12.0, Color(0.70, 0.52, 0.30), 1.4)
	c.draw_line(h1, h1 + fd * 10.0 + side * 4.0, Color(0.70, 0.52, 0.30), 1.4)
	var life := fmod(t * 0.35 + s, 1.0)
	var bc := fd * (24.0 + life * 26.0) + side * (14.0 + sin(t * 2.0 + s) * 3.0)
	var br := 9.0 + life * 9.0
	var a := 0.55 * (1.0 - life * life)
	c.draw_arc(bc, br, 0.0, TAU, 28, Color(0.80, 0.92, 1.0, a), 1.4)
	c.draw_arc(bc, br - 1.2, -2.6, -1.4, 10, Color(1.0, 0.70, 0.90, a), 1.6)
	c.draw_arc(bc, br - 1.2, 0.4, 1.4, 10, Color(0.60, 1.0, 0.80, a), 1.4)
	for k in range(3):
		var sp := bc + Vector2.from_angle(float(k) * 2.1 + t + s) * (br + 6.0 + float(k) * 3.0)
		c.draw_arc(sp, 2.6, 0.0, TAU, 10, Color(0.86, 0.94, 1.0, 0.5), 1.0)


# Rambla del Raval: a fortune teller at her little table, the crystal ball
# glowing and three cards laid out
static func _fortune(c: Node2D, fd: Vector2, t: float, s: float) -> void:
	var side := fd.orthogonal()
	var skin := Color(0.78, 0.58, 0.44)
	var shawl := Color(0.20, 0.16, 0.34)
	var at := -fd * 8.0
	_shadow(c, fd * 4.0, 16.0, 16.0)
	var table := fd * 10.0
	c.draw_circle(table, 13.0, Color(0.36, 0.10, 0.30))
	c.draw_circle(table, 11.0, Color(0.46, 0.14, 0.38))
	for k in range(3):
		var cp := table + side * (float(k) - 1.0) * 6.0 + fd * 6.0
		c.draw_colored_polygon(_bar(cp, side, 4.0, 6.0), Color(0.96, 0.92, 0.80))
		c.draw_circle(cp, 1.0, Color(0.80, 0.20, 0.20) if k == 1 else Color(0.14, 0.14, 0.16))
	var pulse := 0.7 + 0.3 * sin(t * 2.2 + s)
	c.draw_circle(table - fd * 2.0, 9.0, Color(0.60, 0.80, 1.0, 0.18 * pulse))
	c.draw_circle(table - fd * 2.0, 5.5, Color(0.72, 0.86, 1.0, 0.85))
	c.draw_circle(table - fd * 2.0 - Vector2(1.6, 1.6), 1.8, Color(1.0, 1.0, 1.0, 0.9))
	_seat_legs(c, at, fd, side, Color(0.30, 0.10, 0.28), Color(0.20, 0.10, 0.14))
	_person(c, at, fd, shawl, skin, Color(0.12, 0.08, 0.08), "long", "hood", Color(0.62, 0.12, 0.44))
	for e: float in [-1.0, 1.0]:
		_arm(c, at + side * e * 8.0, table - fd * 2.0 + side * e * 6.0, shawl, skin)


# L'Eixample: a tour guide with her flag up on its stick so the group can
# find her, the lanyard and badge round her neck
static func _guide(c: Node2D, fd: Vector2, t: float, s: float) -> void:
	var side := fd.orthogonal()
	var skin := Color(0.88, 0.70, 0.56)
	var polo := Color(0.14, 0.56, 0.58)
	_shadow(c, Vector2.ZERO, 12.0, 14.0)
	_shoes(c, fd, side, Color(0.94, 0.94, 0.92))
	_person(c, Vector2.ZERO, fd, polo, skin, Color(0.30, 0.18, 0.10), "bun", "none", Color.BLACK)
	c.draw_arc(fd * 1.0, 7.0, fd.angle() - 1.0, fd.angle() + 1.0, 8, Color(0.94, 0.80, 0.20), 1.2)
	c.draw_colored_polygon(_bar(fd * 9.0, side, 4.0, 5.0), Color(0.96, 0.96, 0.94))
	var hand := side * 14.0 - fd * 2.0
	_arm(c, side * 8.0, hand, polo, skin)
	var top := hand - fd * 18.0 + side * 4.0
	c.draw_line(hand, top, Color(0.30, 0.30, 0.32), 1.6)
	var wave := sin(t * 3.0 + s) * 2.0
	c.draw_colored_polygon(PackedVector2Array([top, top + side * 12.0 + fd * wave, top + side * 12.0 + fd * (7.0 + wave),
		top + fd * 7.0]), Color(0.98, 0.56, 0.16))


# Els Àngels: a skateboarder, one foot on the board rolling it to and fro,
# beanie and hoodie
static func _skateboarder(c: Node2D, fd: Vector2, t: float, s: float) -> void:
	var side := fd.orthogonal()
	var skin := Color(0.72, 0.52, 0.38)
	var hoodie := Color(0.40, 0.42, 0.46)
	_shadow(c, Vector2.ZERO, 13.0, 16.0)
	var roll := sin(t * 1.4 + s) * 2.0
	var board := side * (5.0 + roll)
	c.draw_line(board - fd * 15.0, board + fd * 15.0, Color(0.16, 0.16, 0.18), 9.0)
	c.draw_circle(board - fd * 15.0, 4.5, Color(0.16, 0.16, 0.18))
	c.draw_circle(board + fd * 15.0, 4.5, Color(0.16, 0.16, 0.18))
	for e: float in [-1.0, 1.0]:
		for g: float in [-1.0, 1.0]:
			c.draw_circle(board + fd * e * 11.0 + side * g * 5.0, 1.8, Color(0.96, 0.86, 0.40))
	c.draw_circle(board + fd * 4.0, 3.4, Color(0.94, 0.30, 0.24))
	c.draw_circle(-side * 7.0 + fd * (4.0 - roll * 2.0), 3.4, Color(0.94, 0.30, 0.24))
	_person(c, Vector2.ZERO, fd, hoodie, skin, Color(0.10, 0.08, 0.06), "short", "beanie", Color(0.96, 0.62, 0.16))
	for e: float in [-1.0, 1.0]:
		_arm(c, side * e * 8.0, side * e * 15.0 + fd * 2.0, hoodie, skin)


# El Poble Espanyol: a potter at her wheel, the pot turning on it under her
# clay-brown hands
static func _potter(c: Node2D, fd: Vector2, t: float, s: float) -> void:
	var side := fd.orthogonal()
	var skin := Color(0.86, 0.68, 0.54)
	var smock := Color(0.84, 0.78, 0.66)
	var at := -fd * 8.0
	_shadow(c, fd * 4.0, 16.0, 16.0)
	var wheel := fd * 12.0
	c.draw_circle(wheel, 12.0, Color(0.40, 0.40, 0.42))
	c.draw_circle(wheel, 9.5, Color(0.56, 0.56, 0.58))
	var spin := t * 9.0 + s
	c.draw_line(wheel + Vector2.from_angle(spin) * 7.0, wheel + Vector2.from_angle(spin) * 9.5, Color(0.30, 0.30, 0.32), 1.4)
	c.draw_circle(wheel, 6.0, Color(0.70, 0.40, 0.24))
	c.draw_circle(wheel, 3.8, Color(0.50, 0.26, 0.14))
	_seat_legs(c, at, fd, side, Color(0.30, 0.34, 0.46), Color(0.20, 0.16, 0.14))
	_person(c, at, fd, smock, skin, Color(0.56, 0.30, 0.16), "bun", "none", Color.BLACK)
	c.draw_circle(at + fd * 2.0 + side * 3.0, 1.6, Color(0.70, 0.40, 0.24))
	for e: float in [-1.0, 1.0]:
		_arm(c, at + side * e * 8.0, wheel + side * e * 6.0 - fd * 1.0, smock, Color(0.74, 0.46, 0.30))


# La Ciutadella: a juggler, three clubs going round over his hands
static func _juggler(c: Node2D, fd: Vector2, t: float, s: float) -> void:
	var side := fd.orthogonal()
	var skin := Color(0.84, 0.64, 0.50)
	var shirt := Color(0.96, 0.84, 0.24)
	_shadow(c, Vector2.ZERO, 12.0, 14.0)
	_shoes(c, fd, side, Color(0.86, 0.26, 0.24), 7.0)
	_person(c, Vector2.ZERO, fd, shirt, skin, Color(0.40, 0.24, 0.14), "curly", "none", Color.BLACK)
	var cols: Array[Color] = [Color(0.92, 0.24, 0.30), Color(0.20, 0.52, 0.90), Color(0.30, 0.76, 0.42)]
	var mid := fd * 20.0
	for k in range(3):
		var ph := t * 3.6 + s + float(k) * TAU / 3.0
		var p := mid + side * cos(ph) * 12.0 + fd * sin(ph) * 7.0
		var d := Vector2.from_angle(ph * 2.0)
		c.draw_line(p - d * 4.0, p + d * 4.0, cols[k], 3.0)
		c.draw_circle(p + d * 4.0, 2.6, cols[k])
	for e: float in [-1.0, 1.0]:
		var hp := mid + side * e * 10.0 - fd * 4.0 + fd * maxf(0.0, sin(t * 3.6 + s + e)) * 2.0
		_arm(c, side * e * 8.0, hp, shirt, skin)


# La Cremada: a devil from the correfoc, horns and a red suit, his fork
# spitting sparks
static func _devil(c: Node2D, fd: Vector2, t: float, s: float) -> void:
	var side := fd.orthogonal()
	var red := Color(0.70, 0.08, 0.10)
	var skin := Color(0.82, 0.60, 0.46)
	_shadow(c, Vector2.ZERO, 13.0, 14.0)
	_shoes(c, fd, side, Color(0.10, 0.08, 0.08), 7.0)
	_person(c, Vector2.ZERO, fd, red, skin, Color(0.10, 0.06, 0.06), "short", "hood", red.darkened(0.2))
	var head := fd * 5.0
	for e: float in [-1.0, 1.0]:
		var base := head + side * e * 4.5 - fd * 1.0
		c.draw_colored_polygon(PackedVector2Array([base - side * e * 1.6, base + side * e * 2.0, base + side * e * 3.0 - fd * 6.0]),
			Color(0.20, 0.06, 0.06))
	var hand := side * 13.0 + fd * 6.0
	_arm(c, side * 8.0, hand, red, skin)
	var tip := hand + fd * 16.0 + side * 6.0
	c.draw_line(hand - fd * 6.0, tip, Color(0.22, 0.20, 0.20), 2.0)
	for k in range(10):
		var ph := fmod(t * 2.6 + float(k) * 0.37 + s, 1.0)
		var p := tip + Vector2.from_angle(float(k) * 2.4 + t * 1.3) * (2.0 + ph * 16.0)
		c.draw_circle(p, 1.6 * (1.0 - ph) + 0.4, Color(1.0, 0.86 - ph * 0.4, 0.30, 1.0 - ph))
	c.draw_circle(tip, 3.0, Color(1.0, 0.96, 0.70))


# L'Aeroport: a pilot with his cap and stripes, his flight bag at his side
static func _pilot(c: Node2D, fd: Vector2, t: float, s: float) -> void:
	var side := fd.orthogonal()
	var skin := Color(0.80, 0.60, 0.46)
	var navy := Color(0.12, 0.16, 0.28)
	var gold := Color(0.96, 0.80, 0.30)
	_shadow(c, Vector2.ZERO, 14.0, 14.0)
	var bag := side * 16.0 + fd * 2.0
	c.draw_colored_polygon(_bar(bag, side, 12.0, 22.0), Color(0.10, 0.10, 0.12))
	c.draw_colored_polygon(_bar(bag, side, 9.0, 19.0), Color(0.20, 0.20, 0.24))
	c.draw_line(bag - fd * 11.0, bag - fd * 15.0, Color(0.60, 0.62, 0.66), 1.6)
	_shoes(c, fd, side, Color(0.06, 0.06, 0.08))
	_person(c, Vector2.ZERO, fd, navy, skin, Color(0.40, 0.40, 0.42), "short", "none", Color.BLACK)
	for e: float in [-1.0, 1.0]:
		for k in range(3):
			var x := side * e * (7.0 + float(k) * 1.6)
			c.draw_line(x - fd * 2.0, x + fd * 2.0, gold, 0.9)
	var head := fd * 5.0
	c.draw_circle(head, 8.2, Color(0.98, 0.98, 0.96))
	c.draw_colored_polygon(_bar(head + fd * 6.0, side, 10.0, 4.0), Color(0.08, 0.08, 0.10))
	c.draw_circle(head + fd * 3.0, 1.6, gold)
	_arm(c, side * 8.0, bag - fd * 15.0, navy, skin)
	# a look at his watch every few seconds: the wrist comes up in front
	var w := fmod(t + s, 4.0)
	var up := clampf(minf(w / 0.3, (1.4 - w) / 0.3), 0.0, 1.0) if w < 1.4 else 0.0
	var wrist := (-side * 12.0 + fd * 3.0).lerp(-side * 3.0 + fd * 12.0, up)
	_arm(c, -side * 8.0, wrist, navy, skin)
	c.draw_circle(wrist - fd * 1.5, 1.6, gold)


# Montserrat: a Benedictine monk in his black habit, hands folded on his
# rosary, the hood down on his shoulders
static func _monk(c: Node2D, fd: Vector2, t: float, s: float) -> void:
	var side := fd.orthogonal()
	var skin := Color(0.88, 0.70, 0.58)
	var black := Color(0.10, 0.10, 0.12)
	_shadow(c, Vector2.ZERO, 14.0, 15.0)
	c.draw_circle(Vector2.ZERO, 14.0, black)
	c.draw_circle(-fd * 5.0, 9.0, black.lightened(0.08))
	_person(c, Vector2.ZERO, fd, black, skin, Color(0.70, 0.70, 0.72), "bald_spot", "none", Color.BLACK)
	var hands := fd * 11.0
	_arm(c, side * 8.0, hands + side * 2.0, black, skin)
	_arm(c, -side * 8.0, hands - side * 2.0, black, skin)
	# telling his beads, one passing through his fingers at a time
	var told := fmod(t * 1.2 + s, 1.0) * 1.6
	for k in range(6):
		c.draw_circle(hands + fd * (2.0 + float(k) * 1.6 + told) + side * sin(float(k) + told) * 1.2, 0.9,
			Color(0.56, 0.36, 0.20))
	c.draw_circle(hands + fd * 12.0, 1.4, Color(0.80, 0.66, 0.30))


# La Diagonal: a delivery rider by his bike, the insulated box on his back
# and the next order on his phone
static func _rider(c: Node2D, fd: Vector2, t: float, s: float) -> void:
	var side := fd.orthogonal()
	var skin := Color(0.62, 0.44, 0.32)
	var teal := Color(0.12, 0.66, 0.62)
	_shadow(c, Vector2.ZERO, 14.0, 14.0)
	var bike := side * 15.0
	c.draw_line(bike - fd * 18.0, bike + fd * 18.0, Color(0.16, 0.16, 0.18), 3.0)
	for e: float in [-1.0, 1.0]:
		c.draw_colored_polygon(_bar(bike + fd * e * 15.0, side, 3.0, 12.0), Color(0.10, 0.10, 0.10))
	c.draw_line(bike + fd * 12.0 - side * 6.0, bike + fd * 12.0 + side * 6.0, Color(0.30, 0.30, 0.32), 2.0)
	c.draw_colored_polygon(_bar(bike - fd * 4.0, side, 5.0, 8.0), Color(0.12, 0.12, 0.12))
	var box := -fd * 10.0
	c.draw_colored_polygon(_bar(box + Vector2(1.5, 2.0), side, 22.0, 20.0), Color(0.0, 0.0, 0.0, 0.25))
	c.draw_colored_polygon(_bar(box, side, 22.0, 20.0), teal)
	c.draw_colored_polygon(_bar(box, side, 18.0, 3.0), teal.darkened(0.25))
	_shoes(c, fd, side, Color(0.20, 0.20, 0.22))
	_person(c, Vector2.ZERO, fd, teal, skin, Color(0.10, 0.08, 0.06), "short", "none", Color.BLACK)
	c.draw_circle(fd * 5.0, 7.8, Color(0.94, 0.94, 0.92))
	c.draw_circle(fd * 4.0, 5.0, Color(0.80, 0.82, 0.84))
	var ph := fd * 13.0 - side * 4.0
	_arm(c, -side * 8.0, ph, teal, skin)
	c.draw_colored_polygon(_bar(ph + fd * 2.0, side, 5.0, 8.0), Color(0.08, 0.08, 0.10))
	# the next order coming in: the screen lights up, and his thumb goes
	var ping := maxf(0.0, sin(t * 2.5 + s))
	c.draw_colored_polygon(_bar(ph + fd * 2.0, side, 3.6, 6.4), Color(0.60, 0.84, 0.96).lightened(0.3 * ping))
	_arm(c, side * 8.0, ph + side * 3.0 + fd * (1.0 + ping * 2.0), teal, skin)


# Carrer de Blai: a cook out of the kitchen for a minute, whites and toque,
# a coffee in one hand and his cloth in the other
static func _cook(c: Node2D, fd: Vector2, t: float, s: float) -> void:
	var side := fd.orthogonal()
	var skin := Color(0.80, 0.60, 0.46)
	var white := Color(0.96, 0.96, 0.94)
	_shadow(c, Vector2.ZERO, 13.0, 14.0)
	_shoes(c, fd, side, Color(0.12, 0.12, 0.14))
	_person(c, Vector2.ZERO, fd, white, skin, Color(0.14, 0.10, 0.08), "short", "none", Color.BLACK)
	for e: float in [-1.0, 1.0]:
		for k in range(2):
			c.draw_circle(side * e * 3.0 + fd * (float(k) * 4.0), 0.9, Color(0.30, 0.30, 0.32))
	var head := fd * 5.0
	for k in range(6):
		c.draw_circle(head + Vector2.from_angle(float(k) / 6.0 * TAU) * 4.4, 4.0, white)
	c.draw_circle(head, 5.0, Color(0.90, 0.90, 0.88))
	# a sip of his coffee every few seconds
	var sip := fmod(t + s, 3.8)
	var up := clampf(minf(sip / 0.35, (1.3 - sip) / 0.35), 0.0, 1.0) if sip < 1.3 else 0.0
	var cup := (side * 12.0 + fd * 10.0).lerp(side * 5.0 + fd * 12.0, up)
	_arm(c, side * 8.0, cup, white, skin)
	c.draw_circle(cup + fd * 2.0, 3.2, Color(0.94, 0.94, 0.92))
	c.draw_circle(cup + fd * 2.0, 2.2, Color(0.36, 0.22, 0.12))
	var flick := sin(t * 3.0 + s) * 1.5
	_arm(c, -side * 8.0, -side * 10.0 + fd * (4.0 + flick), white, skin)
	c.draw_colored_polygon(_bar(-side * (10.0 + flick * 0.5) + fd * (8.0 + flick), side, 4.0, 10.0),
		Color(0.86, 0.86, 0.84))


# La Molina: the ski school's instructor in her red jacket and bobble hat,
# skis on, leaning on her poles, the whistle to her lips every so often
static func _instructor(c: Node2D, fd: Vector2, t: float, s: float) -> void:
	var side := fd.orthogonal()
	var skin := Color(0.90, 0.72, 0.60)
	var red := Color(0.86, 0.14, 0.14)
	_shadow(c, Vector2.ZERO, 14.0, 15.0)
	# the skis, side by side under her, tips curled up toward the path
	for e: float in [-1.0, 1.0]:
		var sk := side * e * 6.0
		c.draw_line(sk - fd * 24.0, sk + fd * 22.0, Color(0.96, 0.84, 0.18), 4.0)
		c.draw_circle(sk + fd * 23.0, 2.2, Color(0.96, 0.84, 0.18))
	# a little shuffle on them, as instructors do while they wait
	var shuffle := sin((t + s) * 3.0) * 1.5
	_person(c, fd * shuffle * 0.3, fd, red, skin, Color(0.40, 0.24, 0.12), "ponytail", "beanie", Color(0.96, 0.96, 0.98))
	# the bobble on her hat
	c.draw_circle(fd * shuffle * 0.3 - fd * 2.0, 3.0, red)
	# her poles, planted ahead either side, her hands on the grips
	for e: float in [-1.0, 1.0]:
		var grip := fd * 8.0 + side * e * 13.0
		var tip := fd * 20.0 + side * e * 19.0
		_arm(c, side * e * 8.0, grip, red, Color(0.14, 0.14, 0.16))
		c.draw_line(grip, tip, Color(0.70, 0.72, 0.76), 1.8)
		c.draw_circle(tip, 2.6, Color(0.20, 0.20, 0.22))
	# the whistle, up to her lips for a moment every few seconds
	var w := fmod(t + s, 5.0)
	if w < 0.5:
		c.draw_circle(fd * 9.0, 1.8, Color(0.92, 0.92, 0.20))

# Sant Pau: a watercolor painter seated at her easel in the dusk gardens,
# painting the modernista brick domes from a tin palette and rinse jar
static func _sketcher(c: Node2D, fd: Vector2, t: float, s: float) -> void:
	var side := fd.orthogonal()
	var skin := Color(0.88, 0.70, 0.56)
	var shirt := Color(0.92, 0.88, 0.80)
	var at := -fd * 7.0
	_shadow(c, fd * 4.0, 16.0, 16.0)
	# Wooden easel in front, holding a watercolor wash of brick & turquoise dome
	var easel := fd * 14.0
	var wood := Color(0.46, 0.30, 0.18)
	c.draw_line(easel - side * 8.0 - fd * 2.0, easel + side * 8.0 - fd * 2.0, wood, 2.2)
	c.draw_line(easel, easel + fd * 5.0, wood, 2.0)
	c.draw_colored_polygon(_bar(easel, side, 20.0, 13.0), Color(0.96, 0.94, 0.88))
	c.draw_circle(easel - side * 3.0, 3.2, Color(0.68, 0.30, 0.22, 0.85))
	c.draw_circle(easel + side * 4.0 - fd * 1.0, 2.8, Color(0.14, 0.62, 0.58, 0.85))
	c.draw_circle(easel + fd * 2.0, 2.2, Color(0.95, 0.68, 0.16, 0.80))
	# Tin palette & water jar beside her
	var pal := at + side * 15.0 + fd * 2.0
	c.draw_colored_polygon(_bar(pal, side, 8.0, 12.0), Color(0.24, 0.26, 0.28))
	c.draw_circle(pal - fd * 3.0, 1.6, Color(0.95, 0.68, 0.16))
	c.draw_circle(pal, 1.6, Color(0.14, 0.62, 0.58))
	c.draw_circle(pal + fd * 3.0, 1.6, Color(0.76, 0.25, 0.44))
	var jar := at - side * 14.0 + fd * 5.0
	c.draw_circle(jar, 3.6, Color(0.76, 0.84, 0.90, 0.85))
	c.draw_circle(jar, 2.4, Color(0.28, 0.56, 0.62, 0.8))
	# Painter on her stool, brush moving between palette and paper
	_seat_legs(c, at, fd, side, Color(0.28, 0.34, 0.44), Color(0.36, 0.22, 0.14))
	_person(c, at, fd, shirt, skin, Color(0.42, 0.24, 0.14), "bun", "beret", Color(0.76, 0.25, 0.44))
	_arm(c, at - side * 8.0, at - side * 10.0 + fd * 6.0, shirt, skin)
	var dab := 0.5 + 0.5 * sin(t * 2.2 + s)
	var brush_hand := (pal - side * 2.0).lerp(easel + side * 2.0 - fd * 2.0, dab)
	_arm(c, at + side * 8.0, brush_hand, shirt, skin)
	c.draw_line(brush_hand, brush_hand + fd * 7.0 - side * 2.0, Color(0.36, 0.22, 0.12), 1.4)
