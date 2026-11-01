class_name FilmVet
extends RefCounted

# El Veterinari's film, "Booster day": the telegraph to run as the walk
# turns for home (systems/home_chase.gd plays it through
# intro/film_player.gd). The clinic corridor, side on: tiled walls, the
# waiting chairs, a cat in a carrier. The two of them heading for the doors,
# your human on the phone. The counter bell: her ears go up and she looks
# back. The consulting room door bangs open and out pours the clinic staff
# in scrubs and masks, each holding out something a dog dreads: a cone of
# shame, a giant syringe, the nail clippers, a catch net. The cat hisses, a
# glove snaps. A push in on
# her face. She spins, digs in and bolts; the leash snaps taut, your human is
# yanked off after her, and RUN! slams in with the cone's mouth filling the
# frame.

const LENGTH := FilmKit.LENGTH
const BG := Color(0.10, 0.15, 0.15)
const FEET := 640.0              # the floor the pair walks on
const WALL_FOOT := 580.0         # where the wall meets the floor
const DOOR_X := -60.0            # the consulting room door's centre
const OUT_AT := 2.3              # the door bangs open
const BOLT_AT := FilmKit.BOLT_AT
const TITLE_AT := FilmKit.TITLE_AT
const AS_K := 1.5                # the staff's scale: a head taller than your human
const DOSE := Color(0.45, 0.85, 0.40)
const CLIPPER_RED := Color(0.85, 0.20, 0.22)
# the line, as the walk's: [what they hold, x behind the lead, far rank,
# cap or hair, order out of the door]
const STAFF := [
	["net", -280.0, true, Color(0.16, 0.24, 0.42), 3],
	["syringe", -100.0, true, Color(0.13, 0.46, 0.43), 1],
	["clippers", -370.0, false, Color(0.62, 0.30, 0.16), 4],
	["syringe", -190.0, false, Color(0.85, 0.72, 0.35), 2],
	["cone", 0.0, false, Color(0.35, 0.22, 0.15), 0],
]
# the clinic's colours, as the walk's (systems/vet.gd, entities/vet_threat.gd)
const WALL_TILE := Color(0.90, 0.94, 0.93)
const WALL_LINE := Color(0.80, 0.86, 0.85)
const BASEBOARD := Color(0.30, 0.60, 0.55)
const TRIM := Color(0.20, 0.45, 0.42)
const LINO := Color(0.80, 0.87, 0.85)
const LINO_LINE := Color(0.72, 0.80, 0.78)
const DOOR_WOOD := Color(0.58, 0.42, 0.30)
const DOOR_FRAME := Color(0.35, 0.28, 0.22)
const PORTHOLE := Color(0.70, 0.88, 0.92)
const SCRUBS := Color(0.20, 0.65, 0.60)
const GLOVE := Color(0.30, 0.55, 0.90)
const MASK := Color(0.60, 0.85, 0.90)
const CLOG := Color(0.94, 0.96, 0.98)
const SKIN := Color(0.92, 0.76, 0.65)
const CONE := Color(0.80, 0.90, 0.97, 0.85)
const CONE_RIM := Color(0.25, 0.45, 0.75)
const NET := Color(0.80, 0.82, 0.85, 0.55)
const POLE := Color(0.70, 0.72, 0.75)
const CHAIR_BLUE := Color(0.22, 0.45, 0.72)
const CHAIR_ORANGE := Color(0.88, 0.45, 0.20)
const CHAIR_FRAME := Color(0.40, 0.42, 0.45)
const INK := IntroKit.INK
# the sound cues: [time, sound, pitch, volume dB]
const CUES := [
	[1.30, "bell", 1.0, -6.0],
	[OUT_AT, "intro_door", 1.0, -4.0],
	[2.60, "hiss", 1.3, -10.0],
	[3.40, "crack", 2.2, -12.0],
	[4.55, "whistle", 1.3, -10.0],
	[BOLT_AT, "bark", 1.0, -3.0],
	[BOLT_AT + 0.08, "intro_taut", 1.0, -8.0],
	[TITLE_AT, "crack", 0.6, -4.0],
]


# the camera: [centre, zoom]. On the pair; a pan back down the corridor when
# she looks round, held as the door bangs and they come for her; a whip back
# to a close-up of her; a cut wide on the bolt that runs right with them; the
# title card square on.
static func camera(t: float) -> Array:
	if t >= TITLE_AT:
		return FilmKit.card_camera(t)
	if t >= BOLT_AT:
		var cx: float = Anim.k(t, [[BOLT_AT, 900.0], [TITLE_AT, 1500.0, "in"]])
		return [Vector2(cx, 470.0), 1.0]
	var x: float = Anim.k(t, [[0.0, 600.0], [1.6, 660.0, "io"], [2.2, 260.0, "io"], [3.9, 380.0, "io"],
		[4.2, 760.0, "io"]])
	var y: float = Anim.k(t, [[0.0, 470.0], [2.2, 440.0, "io"], [3.9, 450.0], [4.2, 520.0, "io"]])
	var z: float = Anim.k(t, [[0.0, 1.2], [1.6, 1.25, "io"], [2.2, 0.92, "io"], [3.9, 0.98, "io"], [4.2, 1.7, "io"]])
	return [Vector2(x, y), z]


# where the lead assistant's feet are (the cone's mouth is ahead of them)
static func assistant_x(t: float) -> float:
	return Anim.k(t, [[OUT_AT, DOOR_X], [3.9, 70.0, "out"], [BOLT_AT, 200.0], [TITLE_AT, 1350.0, "in"]])


static func draw(c: CanvasItem, t_real: float) -> void:
	if t_real >= TITLE_AT:
		_title(c, t_real)
		return
	_corridor(c, t_real)
	if t_real >= OUT_AT:
		_assistants(c, Anim.twos(t_real), t_real)
	FilmKit.pair(c, t_real, FEET)
	FilmKit.fades(c, t_real)


# the clinic corridor: strip lights, tiled walls with a teal baseboard, the
# consulting room door with its porthole, a green cross, the waiting chairs
# with a cat in a carrier, the counter and the glass doors out
static func _corridor(c: CanvasItem, t: float) -> void:
	c.draw_rect(Rect2(-1600, -900, 4600, WALL_FOOT + 900.0), WALL_TILE)
	var y := -880.0
	while y < WALL_FOOT - 60.0:
		c.draw_line(Vector2(-1600, y), Vector2(3000, y), WALL_LINE, 2.0)
		y += 60.0
	var x := -1600.0
	while x < 3000.0:
		c.draw_line(Vector2(x, -900), Vector2(x, WALL_FOOT - 60.0), WALL_LINE, 2.0)
		x += 60.0
	c.draw_rect(Rect2(-1600, -60, 4600, 12), TRIM)
	# the strip lights along the ceiling
	for lx in range(-6, 12):
		var r := Rect2(float(lx) * 320.0, -40.0, 200.0, 18.0)
		c.draw_rect(r.grow(14.0), Color(1.0, 1.0, 0.92, 0.18))
		c.draw_rect(r, Color(1.0, 1.0, 0.95))
	c.draw_rect(Rect2(-1600, WALL_FOOT - 60.0, 4600, 60.0), BASEBOARD)
	c.draw_rect(Rect2(-1600, WALL_FOOT - 66.0, 4600, 8.0), TRIM)
	_door(c, t)
	# a second door further back, shut
	_door_leaf(c, Rect2(DOOR_X - 820.0, WALL_FOOT - 420.0, 200.0, 420.0), 1.0)
	# the green cross, lit
	var gx := Vector2(330.0, 140.0)
	c.draw_rect(Rect2(gx.x - 70.0, gx.y - 70.0, 140.0, 140.0), Color(0.20, 0.72, 0.42, 0.18))
	c.draw_rect(Rect2(gx.x - 18.0, gx.y - 54.0, 36.0, 108.0), Color(0.20, 0.72, 0.42))
	c.draw_rect(Rect2(gx.x - 54.0, gx.y - 18.0, 108.0, 36.0), Color(0.20, 0.72, 0.42))
	# a poster: a dog's head and a syringe
	IntroKit.box(c, Rect2(1180.0, 120.0, 150.0, 200.0), 6.0, Color(0.98, 0.94, 0.80))
	c.draw_circle(Vector2(1255.0, 190.0), 40.0, Color(0.82, 0.60, 0.38))
	c.draw_circle(Vector2(1222.0, 160.0), 16.0, Color(0.62, 0.42, 0.26))
	c.draw_circle(Vector2(1288.0, 160.0), 16.0, Color(0.62, 0.42, 0.26))
	c.draw_line(Vector2(1210.0, 286.0), Vector2(1300.0, 256.0), CONE_RIM, 8.0)
	c.draw_line(Vector2(1300.0, 256.0), Vector2(1318.0, 250.0), INK, 2.0)
	# the waiting chairs, the cat in its carrier on one of them
	for i in range(4):
		var cx := 820.0 + float(i) * 100.0
		var col := CHAIR_BLUE if i % 2 == 0 else CHAIR_ORANGE
		c.draw_line(Vector2(cx + 10.0, WALL_FOOT + 10.0), Vector2(cx + 10.0, WALL_FOOT - 50.0), CHAIR_FRAME, 6.0)
		c.draw_line(Vector2(cx + 80.0, WALL_FOOT + 10.0), Vector2(cx + 80.0, WALL_FOOT - 50.0), CHAIR_FRAME, 6.0)
		IntroKit.box(c, Rect2(cx, WALL_FOOT - 140.0, 90.0, 80.0), 12.0, col)
		IntroKit.box(c, Rect2(cx - 4.0, WALL_FOOT - 66.0, 98.0, 20.0), 8.0, col.darkened(0.15))
	_carrier(c, Vector2(1020.0, WALL_FOOT - 66.0), t)
	# the counter and the glass doors out
	IntroKit.box(c, Rect2(1440.0, WALL_FOOT - 210.0, 380.0, 220.0), 8.0, Color(0.68, 0.52, 0.38))
	c.draw_rect(Rect2(1430.0, WALL_FOOT - 224.0, 400.0, 18.0), Color(0.92, 0.90, 0.86))
	c.draw_circle(Vector2(1490.0, WALL_FOOT - 232.0), 12.0, Color(0.85, 0.72, 0.25))
	c.draw_rect(Rect2(1484.0, WALL_FOOT - 250.0, 12.0, 8.0), Color(0.40, 0.35, 0.15))
	c.draw_rect(Rect2(1980.0, WALL_FOOT - 440.0, 400.0, 440.0), Color(0.65, 0.85, 0.92, 0.6))
	c.draw_line(Vector2(2180.0, WALL_FOOT - 440.0), Vector2(2180.0, WALL_FOOT), CHAIR_FRAME, 6.0)
	c.draw_rect(Rect2(1980.0, WALL_FOOT - 440.0, 400.0, 440.0), CHAIR_FRAME, false, 8.0)
	# the linoleum floor
	c.draw_rect(Rect2(-1600, WALL_FOOT, 4600, 600.0), LINO)
	for px in range(-15, 30):
		c.draw_line(Vector2(float(px) * 120.0, WALL_FOOT), Vector2(float(px) * 120.0 - 60.0, WALL_FOOT + 240.0), LINO_LINE, 2.0)
	c.draw_line(Vector2(-1600, FEET + 40.0), Vector2(3000, FEET + 40.0), LINO_LINE, 2.0)
	c.draw_rect(Rect2(-1600, WALL_FOOT + 30.0, 4600, 14.0), Color(1, 1, 1, 0.25))


# the consulting room door: shut, then banged open at OUT_AT, the leaf
# flung round on its hinge and shuddering, the room dark behind it
static func _door(c: CanvasItem, t: float) -> void:
	var r := Rect2(DOOR_X - 100.0, WALL_FOOT - 420.0, 200.0, 420.0)
	c.draw_rect(r.grow(12.0), DOOR_FRAME)
	var open := Anim.span(t, OUT_AT, OUT_AT + 0.08)
	if open <= 0.0:
		_door_leaf(c, r, 1.0)
		return
	c.draw_rect(r, Color(0.16, 0.20, 0.22))
	# the leaf swung out toward us, seen nearly edge on, still shuddering
	var shake := sin(t * 40.0) * 0.12 * (1.0 - Anim.span(t, OUT_AT, OUT_AT + 0.7))
	_door_leaf(c, Rect2(r.position.x - 40.0, r.position.y - 10.0, 200.0, 440.0), clampf(0.22 + shake, 0.08, 1.0))
	var bang := Anim.span(t, OUT_AT, OUT_AT + 0.35)
	if bang < 1.0:
		for k in range(5):
			var d := Vector2.from_angle(PI + (float(k) - 2.0) * 0.4)
			var at := Vector2(r.position.x - 40.0, r.position.y + 200.0)
			c.draw_line(at + d * (30.0 + bang * 40.0), at + d * (70.0 + bang * 70.0), Color(INK, 1.0 - bang), 5.0)


# a door leaf, `w` its width seen (1 shut and square on, toward 0 edge on),
# hinged on its left edge
static func _door_leaf(c: CanvasItem, r: Rect2, w: float) -> void:
	var lr := Rect2(r.position, Vector2(r.size.x * w, r.size.y))
	c.draw_rect(lr, DOOR_WOOD)
	c.draw_rect(lr, DOOR_FRAME, false, 4.0)
	var ph := Vector2(lr.position.x + lr.size.x * 0.5, lr.position.y + 130.0)
	c.draw_colored_polygon(MillieSide.ellipse(ph, Vector2(44.0 * w + 2.0, 44.0)), DOOR_FRAME)
	c.draw_colored_polygon(MillieSide.ellipse(ph, Vector2(36.0 * w + 1.0, 36.0)), PORTHOLE)
	c.draw_rect(Rect2(lr.end.x - 26.0 * w, lr.position.y + 230.0, 14.0 * w, 30.0), Color(0.75, 0.76, 0.78))


# a cat carrier on a chair, the cat's eyes in the grille: it hisses as the
# door bangs, its eyes gone wide
static func _carrier(c: CanvasItem, at: Vector2, t: float) -> void:
	var hiss := Anim.span(t, 2.6, 2.7) * (1.0 - Anim.span(t, 3.6, 3.9))
	var jump := sin(Anim.span(t, 2.6, 2.75) * PI) * 10.0
	var r := Rect2(at.x - 60.0, at.y - 90.0 - jump, 120.0, 90.0)
	IntroKit.box(c, r, 14.0, Color(0.82, 0.30, 0.36))
	c.draw_rect(Rect2(r.position.x + 30.0, r.position.y - 16.0, 60.0, 12.0), INK)
	var g := Rect2(r.position.x + 16.0, r.position.y + 18.0, 88.0, 56.0)
	c.draw_rect(g, Color(0.10, 0.10, 0.12))
	var eye_r := 6.0 + 4.0 * hiss
	for ex: float in [g.position.x + 32.0, g.position.x + 56.0]:
		c.draw_circle(Vector2(ex, g.position.y + 26.0), eye_r, Color(0.95, 0.85, 0.20))
		c.draw_line(Vector2(ex, g.position.y + 26.0 - eye_r * 0.8), Vector2(ex, g.position.y + 26.0 + eye_r * 0.8), INK, 2.0)
	for gx in range(5):
		var lx := g.position.x + 8.0 + float(gx) * 18.0
		c.draw_line(Vector2(lx, g.position.y), Vector2(lx, g.end.y), Color(0.75, 0.76, 0.78), 3.0)
	if hiss > 0.0:
		for k in range(3):
			var d := Vector2.from_angle(-PI * 0.5 + (float(k) - 1.0) * 0.6)
			var o := Vector2(r.get_center().x, r.position.y - 20.0)
			c.draw_line(o + d * 14.0, o + d * (30.0 + 8.0 * sin(t * 30.0 + float(k))), Color(INK, hiss), 4.0)


# the staff pouring out of the door and down the corridor at a run, the
# walk's line (entities/vet_threat.gd) seen side on: two ranks, the far one
# a step smaller and higher, each holding out what a dog dreads. They come
# out one after another, a step smaller in the doorway, as from inside.
static func _assistants(c: CanvasItem, t: float, t_real: float) -> void:
	var ax := assistant_x(t)
	# the bodies first, then what they hold over all of them, so no tool is
	# lost behind the next one along
	var held := []
	for i in range(STAFF.size()):
		var st: Array = STAFF[i]
		var out := Anim.span(t, OUT_AT + float(st[4]) * 0.12, OUT_AT + float(st[4]) * 0.12 + 0.3)
		if out <= 0.0:
			continue
		var far: bool = st[2]
		var k := AS_K * (0.88 if far else 1.0) * lerpf(0.8, 1.0, out)
		var feet := lerpf(WALL_FOOT + 4.0, FEET - (18.0 if far else 0.0), out)
		var x := lerpf(DOOR_X, ax + float(st[1]), out)
		var pose := _pose(t_real + float(i) * 0.37, st[3])
		pose["reach"] = 1.0
		var hand := IntroKit.human(c, Vector2(x, feet), k, 1.0, Vector2.ONE, pose, 0.0, feet)
		_mask(c, Vector2(x, feet), k)
		held.append([String(st[0]), hand, t_real + float(i), k])
	for h: Array in held:
		_item(c, h[0], h[1], h[2], h[3])
	# a glove snapped on, over the ranks
	var snap := Anim.span(t, 3.4, 3.6)
	if snap > 0.0 and snap < 1.0:
		FilmKit._jolt(c, Vector2(ax - 40.0, FEET - 290.0), snap)


# what one of them holds out, from their hand, side on, facing right
static func _item(c: CanvasItem, item: String, hand: Vector2, t: float, k: float) -> void:
	match item:
		"cone":
			_cone(c, hand + Vector2(62.0, -4.0) * k, 52.0 * k, 64.0 * k, t)
		"syringe":
			_syringe(c, hand, k, t)
		"clippers":
			_clippers(c, hand, k, t)
		"net":
			_net(c, hand, t, k)
	c.draw_circle(hand, 6.5 * k, GLOVE)


# a giant syringe held like a lance: the plunger behind the hand, the barrel
# full of green, the needle out ahead with a drop on its tip
static func _syringe(c: CanvasItem, hand: Vector2, k: float, t: float) -> void:
	var back := hand - Vector2(34.0, 0.0) * k
	c.draw_rect(Rect2(back - Vector2(16.0, 3.0) * k, Vector2(16.0, 6.0) * k), POLE)
	c.draw_rect(Rect2(back - Vector2(20.0, 14.0) * k, Vector2(6.0, 28.0) * k), POLE)
	var barrel := Rect2(back + Vector2(0.0, -13.0) * k, Vector2(96.0, 26.0) * k)
	c.draw_colored_polygon(IntroKit.rrect(barrel, 5.0 * k), Color(0.92, 0.96, 1.0, 0.9))
	c.draw_rect(Rect2(barrel.position + Vector2(30.0, 4.0) * k, Vector2(62.0, 18.0) * k), DOSE)
	for m in range(5):
		var mx := barrel.position.x + (18.0 + float(m) * 15.0) * k
		c.draw_line(Vector2(mx, barrel.position.y), Vector2(mx, barrel.position.y + 9.0 * k), INK, 1.5 * k)
	c.draw_rect(barrel, INK, false, 2.0 * k)
	var tip := Vector2(barrel.end.x + 54.0 * k, barrel.get_center().y)
	c.draw_line(Vector2(barrel.end.x, tip.y), tip, Color(0.80, 0.82, 0.86), 3.0 * k)
	var drip := fposmod(t * 0.9, 1.0)
	c.draw_circle(tip + Vector2(2.0, 4.0 + drip * 12.0) * k, 4.0 * k * (1.0 - drip * 0.5), Color(DOSE, 1.0 - drip))
	c.draw_circle(tip, 3.0 * k, Color(1, 1, 1, 0.6 + 0.4 * sin(t * 9.0)))


# the nail clippers, raised and snipping at the air
static func _clippers(c: CanvasItem, hand: Vector2, k: float, t: float) -> void:
	var pivot := hand + Vector2(30.0, -40.0) * k
	var snip := absf(sin(t * 9.0)) * 0.45
	for s in [-1.0, 1.0]:
		c.draw_line(hand + Vector2(-4.0, s * 6.0) * k, pivot, CLIPPER_RED, 9.0 * k)
		c.draw_line(pivot, pivot + Vector2.from_angle(-0.7 + s * snip) * 64.0 * k, Color(0.80, 0.82, 0.86), 8.0 * k)
	c.draw_circle(pivot, 5.0 * k, INK)


# an assistant at a run in scrubs and clogs; `cap` is the cap or the hair
static func _pose(t: float, cap: Color) -> Dictionary:
	return {
		"stride": t * 13.0, "stride_amp": 1.0, "phone": 0.0, "lean": 0.18, "head": -0.1,
		"skin": SKIN, "shirt": SCRUBS, "trousers": SCRUBS, "hair": cap, "shoe": CLOG,
	}


# a surgical mask over the lower face of an assistant whose feet are at `at`
static func _mask(c: CanvasItem, at: Vector2, k: float) -> void:
	var up := Vector2.UP.rotated(0.18)
	var face := at + (up * 94.0 * 1.0 + Vector2(0.0, -98.0) + Vector2(12.0, 6.0)) * k
	c.draw_colored_polygon(IntroKit.rrect(Rect2(face - Vector2(10.0, 9.0) * k, Vector2(22.0, 18.0) * k), 4.0 * k), MASK)
	c.draw_line(face + Vector2(-10.0, -6.0) * k, face + Vector2(-22.0, -12.0) * k, Color(0.95, 0.97, 0.98), 2.0 * k)


# the giant cone of shame side on, its mouth facing right, centred at
# `mouth` with half height `rad`, `length` back to the neck: translucent
# plastic, a blue rim, the snap tabs round the neck; `open` is how far the
# mouth is turned toward us (its ellipse's width over its height)
static func _cone(c: CanvasItem, mouth: Vector2, rad: float, length: float, t: float, open := 0.24) -> void:
	var neck := mouth - Vector2(length, 0.0)
	var nr := rad * 0.36
	c.draw_colored_polygon(PackedVector2Array([neck + Vector2(0, -nr), mouth + Vector2(0, -rad), mouth + Vector2(0, rad),
		neck + Vector2(0, nr)]), CONE)
	c.draw_line(neck + Vector2(0, -nr), mouth + Vector2(0, -rad), CONE_RIM, maxf(2.0, rad * 0.035))
	c.draw_line(neck + Vector2(0, nr), mouth + Vector2(0, rad), CONE_RIM, maxf(2.0, rad * 0.035))
	var glint := 0.3 + 0.25 * sin(t * 5.0)
	c.draw_line(neck + Vector2(4, -nr * 0.6), mouth + Vector2(-6, -rad * 0.7), Color(1, 1, 1, glint), 3.0)
	c.draw_line(neck + Vector2(4, -nr * 0.1), mouth + Vector2(-6, -rad * 0.25), Color(1, 1, 1, glint * 0.6), 2.0)
	c.draw_colored_polygon(MillieSide.ellipse(mouth, Vector2(rad * open, rad)), Color(0.62, 0.76, 0.90, 0.9))
	c.draw_colored_polygon(MillieSide.ellipse(mouth - Vector2(rad * open * 0.3, 0.0), Vector2(rad * open * 0.45, rad * 0.4)),
		Color(0.40, 0.55, 0.72, 0.9))
	_ring(c, mouth, Vector2(rad * open, rad), CONE_RIM, maxf(3.0, rad * 0.07))
	_ring(c, neck, Vector2(nr * 0.3, nr), CONE_RIM, maxf(2.0, rad * 0.035))
	for i in range(4):
		var y := lerpf(-nr * 0.8, nr * 0.8, float(i) / 3.0)
		c.draw_rect(Rect2(neck + Vector2(-nr * 0.32, y - nr * 0.1), Vector2(nr * 0.3, nr * 0.2)), Color(0.95, 0.97, 1.0, 0.8))


static func _ring(c: CanvasItem, at: Vector2, r: Vector2, col: Color, w: float) -> void:
	var p := MillieSide.ellipse(at, r)
	p.append(p[0])
	c.draw_polyline(p, col, w)


# the catch net: a pole up and forward from the hand, the hoop and its
# sagging bag swaying
static func _net(c: CanvasItem, hand: Vector2, t: float, k: float) -> void:
	var sway := sin(t * 6.0) * 0.12
	var tip := hand + Vector2.from_angle(-0.95 + sway) * 200.0 * k
	c.draw_line(hand, tip, POLE, 6.0 * k)
	var hoop := tip + Vector2.from_angle(-0.95 + sway) * 40.0 * k
	c.draw_colored_polygon(MillieSide.ellipse(hoop + Vector2(20.0, 40.0) * k, Vector2(22.0, 46.0) * k), NET)
	for i in range(5):
		var f := (float(i) + 0.5) / 5.0
		c.draw_line(hoop + Vector2(-8.0, lerpf(-36.0, 36.0, f)) * k, hoop + Vector2(26.0, lerpf(10.0, 80.0, f)) * k,
			Color(0.55, 0.58, 0.62), 1.5 * k)
	_ring(c, hoop, Vector2(14.0, 42.0) * k, Color(0.3, 0.35, 0.40), 4.0 * k)


# the card: the clinic gone white-hot behind RUN!, the giant syringe driving
# in from the left of the frame, its drop trembling on the needle, and the
# clippers snipping in over it
static func _title(c: CanvasItem, t: float) -> void:
	for i in range(8):
		var f := float(i) / 7.0
		c.draw_rect(Rect2(-200, f * 720.0, 1680, 104.0), Color(0.92, 0.98, 0.96).lerp(Color(0.40, 0.72, 0.68), f))
	var d := t - TITLE_AT
	var bob := sin(t * 18.0) * 4.0
	_clippers(c, Vector2(40.0 + d * 60.0, 330.0 - bob), 3.6, t)
	var hand := Vector2(-60.0 + d * 160.0, 540.0 + bob)
	_syringe(c, hand, 5.5, t)
	c.draw_circle(hand, 40.0, GLOVE)
	FilmKit.slam(c, t, "RUN!", Vector2(880, 210))
	IntroKit.fade(c, 1.0 - Anim.span(t, TITLE_AT, TITLE_AT + 0.2), Color(1.0, 0.95, 0.85))
