class_name Cremada
extends RefCounted

# WALK: LA CREMADA. Badalona on the Nit del Dimoni (the night of 10 May, before
# Sant Anastasi): from the Plaça de la Vila down Carrer del Mar, the town's
# pedestrian street, hung for the fiesta with devil pennants; under the
# railway through the underpass; across the Rambla's palms to the beach,
# where the Dimoni sits on his float by the Pont del Petroli, waiting to be
# burned. The houses either side are main's old-town roofscape.
#
# On the way out, a traca hung across the street from a balcony goes off as
# your human passes it (telegraphed: the fuse fizzes and a neighbor shouts);
# in rain or snow it is not hung out at all.
# On the way home the Dimoni's fuse is lit early, his float's brake gives, and
# he rolls up the street after them firing rockets (entities/dimoni_threat.gd,
# home_chase.CREMADA_BANDS). He wedges in the underpass, then on the fiesta
# arch: the two respites.

const ShapeBatch := preload("res://systems/shape_batch.gd")
const DimoniThreat := preload("res://entities/dimoni_threat.gd")
const Outdoors := preload("res://systems/outdoors.gd")

const HALF := 220.0
const WALL_L := 420.0
const WALL_R := 860.0

const PRIZE := Vector2(560.0, -4420.0)
const PRIZE_TEXT := "grab the dropped sparkler"

# THE PLACES, by depth
const VILA_TOP := -420.0              # the Plaça de la Vila gives onto the street
const RAMBLA_BOT := -3560.0           # the street meets the Rambla's palms
const UNDERPASS := Rect2(WALL_L, -3480.0, WALL_R - WALL_L, 130.0)
const UNDERPASS_PIERS: Array[Rect2] = [
	Rect2(WALL_L, -3470.0, 46.0, 110.0), Rect2(WALL_R - 46.0, -3470.0, 46.0, 110.0)]
# the respites (home_chase.CREMADA_BANDS): the float jams on the near side of
# the underpass, then on the fiesta arch
const UNDERPASS_JAM_Y := -3400.0
const ARCH_JAM_Y := -1900.0
const ARCH_FEET: Array[Rect2] = [
	Rect2(WALL_L, -1930.0, 30.0, 30.0), Rect2(WALL_R - 30.0, -1930.0, 30.0, 30.0)]
# the pennant strings across Carrer del Mar
const PENNANT_TOP := -3260.0
const PENNANT_STEP := 180.0
# the stalls and the kiosk on the street, and the Rambla's benches
const KIOSK := Rect2(700.0, -1150.0, 90.0, 60.0)
const STALL := Rect2(450.0, -2550.0, 96.0, 50.0)
# the Dimoni on his float at the beach, before he is lit; the float stands on
# the open sand between the sea and the palms, facing the gate
const PARKED_AT := Vector2(620.0, -5380.0)

# THE TRACA, a string of firecrackers hung across the street from a balcony
const TRACA_Y := -2250.0
const TRACA_NOTICE := 330.0          # your human this far short of it: the fuse is lit
const TRACA_WARN := 0.8              # the fuse fizzes this long first
const TRACA_POP := 1.1               # the bangs ripple across this long
const TRACA_REACH := 70.0            # within this of the line as it pops: startled
const TRACA_BONES := 2

const PENNANT_RED := Color(0.82, 0.14, 0.10)
const PENNANT_BLACK := Color(0.12, 0.10, 0.10)
const PENNANT_GOLD := Color(0.96, 0.78, 0.26)
const STRING := Color(0.18, 0.16, 0.14, 0.85)
const ARCH_BODY := Color(0.62, 0.12, 0.10)
const ARCH_FLAME := Color(1.0, 0.60, 0.16)
const RAIL_DECK := Color(0.46, 0.45, 0.44)
const RAIL := Color(0.62, 0.62, 0.66)
const SLEEPER := Color(0.30, 0.24, 0.20)
const UNDER_DARK := Color(0.03, 0.03, 0.06, 0.45)
const KIOSK_GREEN := Color(0.18, 0.36, 0.28)
const STALL_CLOTH := Color(0.86, 0.22, 0.14)
const TRACA_PAPER := Color(0.86, 0.16, 0.12)
const SPARK := Color(1.0, 0.92, 0.50)

# the lampposts down the street and the Rambla's: poles to wrap
const POSTS: Array[Vector2] = [
	Vector2(440.0, -650.0), Vector2(840.0, -950.0),
	Vector2(440.0, -1450.0), Vector2(840.0, -1700.0),
	Vector2(440.0, -2150.0), Vector2(840.0, -2700.0),
	Vector2(440.0, -3050.0), Vector2(840.0, -3200.0),
	Vector2(440.0, -3800.0), Vector2(840.0, -3800.0),
	Vector2(440.0, -4300.0), Vector2(840.0, -4300.0),
	Vector2(440.0, -4750.0), Vector2(840.0, -4750.0),
]
# the Rambla's palms, a double row down either side: poles to wrap, drawn
# here (their crowns over everyone)
const PALMS: Array[Vector2] = [
	Vector2(462.0, -3660.0), Vector2(818.0, -3660.0), Vector2(462.0, -3940.0), Vector2(818.0, -3940.0),
	Vector2(462.0, -4180.0), Vector2(818.0, -4180.0), Vector2(462.0, -4460.0), Vector2(818.0, -4460.0),
	Vector2(462.0, -4640.0), Vector2(818.0, -4640.0), Vector2(462.0, -4900.0), Vector2(818.0, -4900.0),
]
const PALM_TRUNK := Color(0.42, 0.32, 0.22)
const PALM_FROND := Color(0.16, 0.34, 0.20)
const RAMBLA_TILE := Color(0.62, 0.52, 0.46, 0.22)


static func build(m: Node2D) -> Array:
	m.gate_text = "PLATJA DEL DIMONI"
	m.walk_cx = 640.0
	m.walk_half = HALF
	m.sw_l = WALL_L
	m.sw_r = WALL_R
	m.gate_l = 440.0
	m.gate_r = 840.0
	for p: Vector2 in POSTS:
		m.poles.append(p)
	m.deco_pole_count = m.poles.size()
	for p: Vector2 in PALMS:
		m.poles.append(p)
	m.benches = Array([
		Vector2(452.0, -1300.0),
		Vector2(828.0, -2400.0),
		Vector2(452.0, -3950.0),
		Vector2(828.0, -4500.0),
	], TYPE_VECTOR2, &"", null)
	m.bins = Array([
		Vector2(440.0, -800.0),
		Vector2(840.0, -2000.0),
		Vector2(440.0, -3300.0),
		Vector2(840.0, -4600.0),
	], TYPE_VECTOR2, &"", null)
	m.chase_jams.clear()
	m.chase_jams.append(Vector2(640.0, UNDERPASS_JAM_Y))
	m.chase_jams.append(Vector2(640.0, ARCH_JAM_Y))
	# no traca hung out in the wet (systems/outdoors.gd)
	m.cremada_traca = {"state": "hung" if Outdoors.fireworks(Game.weather, Game.hour) else "spent", "t": 0.0}
	var hyd_list: Array[Vector2] = [
		Vector2(WALL_L + 25.0, -550.0),
		Vector2(WALL_R - 25.0, -1550.0),
		Vector2(WALL_L + 25.0, -2850.0),
		Vector2(WALL_R - 25.0, -4050.0),
		Vector2(WALL_L + 25.0, -4600.0),
	]
	# dropped coca de llardons
	var keb_list: Array[Vector2] = [
		Vector2(700.0, -1700.0),
		Vector2(580.0, -2900.0),
		Vector2(720.0, -4150.0),
	]
	m.prize_pos = PRIZE
	m.prize_text = PRIZE_TEXT
	return [hyd_list, keb_list]


static func solids(_m: Node2D) -> Array[Rect2]:
	var out: Array[Rect2] = [KIOSK, STALL, parked_rect()]
	out.append_array(UNDERPASS_PIERS)
	out.append_array(ARCH_FEET)
	return out


static func wrap_rects() -> Array[Rect2]:
	var out: Array[Rect2] = [KIOSK, STALL]
	out.append_array(UNDERPASS_PIERS)
	out.append_array(ARCH_FEET)
	return out


# the parked float's footprint on the sand
static func parked_rect() -> Rect2:
	var w := HALF * DimoniThreat.CATCH_SPAN
	return Rect2(PARKED_AT.x - w, PARKED_AT.y - DimoniThreat.FLOAT_DEPTH, w * 2.0, DimoniThreat.FLOAT_DEPTH)


# --- main's walk hooks -------------------------------------------------------

static func tick(m: Node2D, delta: float) -> void:
	_tick_traca(m, delta)


# The traca: lit as your human comes within TRACA_NOTICE of it on the way
# out, the fuse fizzing TRACA_WARN (a neighbor shouts it), then the bangs
# ripple across the street for TRACA_POP. Your human inside TRACA_REACH of the
# line while it pops is startled (bumped back, never a fall); pulled clear of
# it by then, it is the dog's save.
static func _tick_traca(m: Node2D, delta: float) -> void:
	var tr: Dictionary = m.cremada_traca
	var st := String(tr.get("state", "hung"))
	var hp: Vector2 = m.human.global_position
	match st:
		"hung":
			if String(m.phase) != "home" and hp.y < TRACA_Y + TRACA_NOTICE and hp.y > TRACA_Y:
				tr.state = "fuse"
				tr.t = 0.0
				m.human.warn_external("Traca! Cover your ears!", TRACA_WARN)
				Sfx.play("hiss", 1.4, -8.0)
		"fuse":
			tr.t = float(tr.t) + delta
			if float(tr.t) >= TRACA_WARN:
				tr.state = "pop"
				tr.t = 0.0
				tr.hit = false
		"pop":
			tr.t = float(tr.t) + delta
			if int(float(tr.t) * 14.0) != int((float(tr.t) - delta) * 14.0):
				Sfx.play("cracker", randf_range(0.9, 1.3), -6.0)
			if not bool(tr.get("hit", false)) and absf(hp.y - TRACA_Y) < TRACA_REACH and not m.auto_walk:
				tr.hit = true
				m.human.bumped(Vector2.DOWN)
				m.float_text(hp, "Ay!", Color(1.0, 0.85, 0.6))
			if float(tr.t) >= TRACA_POP:
				tr.state = "spent"
				if not bool(tr.get("hit", false)):
					m.cremada_traca_dodged = true
					m.bones += TRACA_BONES
					m.combo.add("TRACA", TRACA_BONES)
					m.float_text(m.dog.global_position + Vector2(0.0, -26.0), "traca dodge! +%d" % TRACA_BONES, SPARK)


static func draw_scenery(m: Node2D, _wc: ShapeBatch, vt: float, vb: float) -> void:
	var b := ShapeBatch.new()
	var sh := Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.28)
	# the underpass: dark under the deck, the piers on either side
	if UNDERPASS.end.y > vt - 80.0 and UNDERPASS.position.y < vb + 80.0:
		b.rect(UNDERPASS.grow_individual(0.0, 30.0, 0.0, 30.0), UNDER_DARK)
		for r: Rect2 in UNDERPASS_PIERS:
			b.rect(Rect2(r.position + Vector2(5, 7), r.size), sh)
			b.rect(r, RAIL_DECK.darkened(0.25))
			b.rect(r.grow(-4.0), RAIL_DECK)
	# the Rambla's paving: a warm terracotta herringbone over the grey
	if RAMBLA_BOT > vt - 40.0 and float(m.GATE_Y) < vb + 40.0:
		var ry := maxf(vt - 20.0, float(m.GATE_Y))
		ry = floorf(ry / 40.0) * 40.0
		while ry < minf(vb + 40.0, RAMBLA_BOT):
			var row := int(absf(ry) / 40.0)
			var rx := WALL_L + (20.0 if row % 2 == 0 else 0.0)
			while rx < WALL_R:
				b.rect(Rect2(rx, ry + 2.0, 36.0, 16.0), RAMBLA_TILE)
				b.rect(Rect2(rx + 2.0, ry + 20.0, 16.0, 16.0), RAMBLA_TILE)
				rx += 40.0
			ry += 40.0
	for p: Vector2 in PALMS:
		if p.y > vt - 60.0 and p.y < vb + 60.0:
			b.circle(p + m.LIGHT * 10.0, 16.0, sh)
			b.circle(p, 13.0, PALM_TRUNK.darkened(0.3))
			b.circle(p, 10.0, PALM_TRUNK)
	if _in_view(KIOSK, vt, vb):
		_draw_kiosk(m, b, sh)
	if _in_view(STALL, vt, vb):
		_draw_stall(b, sh)
	# the arch's feet
	if ARCH_JAM_Y > vt - 80.0 and ARCH_JAM_Y < vb + 80.0:
		for r: Rect2 in ARCH_FEET:
			b.rect(Rect2(r.position + Vector2(5, 7), r.size), sh)
			b.rect(r, ARCH_BODY.darkened(0.3))
	b.flush(m._wc)


static func _in_view(r: Rect2, vt: float, vb: float) -> bool:
	return r.end.y > vt - 80.0 and r.position.y < vb + 80.0


# the newspaper kiosk, green and shuttered for the night but for its lamp
static func _draw_kiosk(m: Node2D, b: ShapeBatch, sh: Color) -> void:
	var r := KIOSK
	b.rect(Rect2(r.position + m.LIGHT * 8.0, r.size), sh)
	b.rect(r, KIOSK_GREEN.darkened(0.3))
	b.rect(r.grow(-4.0), KIOSK_GREEN)
	for i in range(5):
		b.rect(Rect2(r.position.x + 8.0 + float(i) * 16.0, r.position.y + 10.0, 10.0, r.size.y - 20.0), KIOSK_GREEN.lightened(0.12))
	b.glow(Vector2(r.get_center().x, r.end.y + 6.0), 40.0, Color(1.0, 0.86, 0.5, 0.35), 0.2)


# a fiesta stall selling Dimoni masks and sparklers under a red awning
static func _draw_stall(b: ShapeBatch, sh: Color) -> void:
	var r := STALL
	b.rect(Rect2(r.position + Vector2(6, 8), r.size), sh)
	b.rect(r, STALL_CLOTH.darkened(0.3))
	var sx := r.position.x
	var k := 0
	while sx < r.end.x - 1.0:
		b.rect(Rect2(sx, r.position.y, minf(12.0, r.end.x - sx), r.size.y - 16.0), STALL_CLOTH if k % 2 == 0 else PENNANT_GOLD)
		sx += 12.0
		k += 1
	for i in range(4):
		var mp := Vector2(r.position.x + 14.0 + float(i) * 22.0, r.end.y - 8.0)
		b.circle(mp, 6.0, PENNANT_RED)
		b.circle(mp + Vector2(-2.0, -1.0), 1.5, PENNANT_GOLD)
		b.circle(mp + Vector2(2.0, -1.0), 1.5, PENNANT_GOLD)


# The Dimoni parked on the beach before he is lit, and the traca's fuse and
# bangs. The parked float goes once the chase has him.
static func draw_live(m: Node2D, wc: ShapeBatch, vt: float, vb: float) -> void:
	var t: float = AnimClock.msec() * 0.001
	if m.chase_sweeper == null and parked_rect().end.y > vt - 120.0 and parked_rect().position.y < vb + 160.0:
		var b := ShapeBatch.new()
		DimoniThreat.paint_float(b, Vector2(PARKED_AT.x, PARKED_AT.y), HALF * DimoniThreat.CATCH_SPAN, t, false)
		b.append_to(wc)
	var tr: Dictionary = m.cremada_traca
	var st := String(tr.get("state", "hung"))
	if TRACA_Y < vt - 60.0 or TRACA_Y > vb + 60.0 or st == "spent":
		return
	if st == "fuse":
		var k := float(tr.t) / TRACA_WARN
		var fx := lerpf(WALL_L + 10.0, WALL_L + 40.0, k)
		for i in range(5):
			var a := float(i) * 1.3 + t * 20.0
			wc.circle(Vector2(fx, TRACA_Y) + Vector2.from_angle(a) * (4.0 + float(i)), 2.0, SPARK)
	elif st == "pop":
		var k := clampf(float(tr.t) / TRACA_POP, 0.0, 1.0)
		var px := lerpf(WALL_L, WALL_R, k)
		for i in range(7):
			var a := float(i) * TAU / 7.0 + t * 9.0
			wc.circle(Vector2(px, TRACA_Y) + Vector2.from_angle(a) * (10.0 + float(i % 3) * 6.0), 3.0, SPARK)
		wc.glow(Vector2(px, TRACA_Y), 60.0, Color(1.0, 0.7, 0.3, 0.5), 0.2)


# The pennant strings, the fiesta arch, the railway deck over the underpass
# and the traca's paper string, over everyone. Drawn once, it holds still.
static func draw_overhead(m: Node2D, ci: CanvasItem) -> void:
	if m.lvl != "cremada":
		return
	var b := ShapeBatch.new(ci)
	var y := VILA_TOP - 80.0
	var k := 0
	while y > PENNANT_TOP:
		if absf(y - ARCH_JAM_Y) > 70.0 and absf(y - TRACA_Y) > 50.0:
			_pennants(b, y, k)
		y -= PENNANT_STEP
		k += 1
	_arch(b)
	_rail_deck(b)
	for p: Vector2 in PALMS:
		_palm_crown(b, p)
	# the traca's paper string, hung in a sag from balcony to balcony
	if not Outdoors.fireworks(Game.weather, Game.hour):
		b.flush()
		return
	var prev := Vector2(WALL_L, TRACA_Y)
	for i in range(1, 25):
		var f := float(i) / 24.0
		var p := Vector2(lerpf(WALL_L, WALL_R, f), TRACA_Y + sin(f * PI) * 12.0)
		b.line(prev, p, STRING, 1.5)
		b.capsule(p + Vector2(0.0, 2.0), p + Vector2(0.0, 9.0), 2.2, TRACA_PAPER)
		prev = p
	b.flush()


# a string of devil pennants: red and black triangles, a gold face on the red
static func _pennants(b: ShapeBatch, y: float, k: int) -> void:
	var n := 12
	var prev := Vector2(WALL_L, y)
	for i in range(1, n + 1):
		var f := float(i) / float(n)
		var p := Vector2(lerpf(WALL_L, WALL_R, f), y + sin(f * PI) * 10.0)
		b.line(prev, p, STRING, 1.5)
		var red := (i + k) % 2 == 0
		var tip := (prev + p) * 0.5 + Vector2(0.0, 13.0)
		b.polygon(PackedVector2Array([prev.lerp(p, 0.12), prev.lerp(p, 0.88), tip]), PENNANT_RED if red else PENNANT_BLACK)
		if red:
			var fc := (prev + p) * 0.5 + Vector2(0.0, 4.0)
			b.circle(fc + Vector2(-2.5, 0.0), 1.3, PENNANT_GOLD)
			b.circle(fc + Vector2(2.5, 0.0), 1.3, PENNANT_GOLD)
		prev = p


# the fiesta arch across Carrer del Mar: a red papier-mache deck with flames
# painted up its edges and a devil's head in the middle
static func _arch(b: ShapeBatch) -> void:
	var ay := ARCH_JAM_Y - 15.0
	var deck := Rect2(WALL_L - 4.0, ay - 14.0, WALL_R - WALL_L + 8.0, 28.0)
	b.rect(Rect2(deck.position + Vector2(8, 14), deck.size), Color(0.04, 0.05, 0.08, 0.2))
	b.rect(deck, ARCH_BODY.darkened(0.3))
	b.rect(deck.grow(-3.0), ARCH_BODY)
	var sx := deck.position.x + 12.0
	var i := 0
	while sx < deck.end.x - 6.0:
		var h := 8.0 + float(i % 3) * 4.0
		b.polygon(PackedVector2Array([Vector2(sx - 7.0, deck.position.y + 2.0), Vector2(sx + 7.0, deck.position.y + 2.0), Vector2(sx, deck.position.y - h)]), ARCH_FLAME)
		b.polygon(PackedVector2Array([Vector2(sx - 7.0, deck.end.y - 2.0), Vector2(sx + 7.0, deck.end.y - 2.0), Vector2(sx, deck.end.y + h * 0.7)]), ARCH_FLAME.darkened(0.15))
		sx += 22.0
		i += 1
	var c := Vector2(640.0, ay)
	for s: float in [-1.0, 1.0]:
		b.quad(c + Vector2(s * 12.0, -14.0), c + Vector2(s * 22.0, -18.0), c + Vector2(s * 30.0, -38.0), c + Vector2(s * 16.0, -20.0), PENNANT_GOLD)
	b.circle(c, 22.0, PENNANT_RED)
	for s: float in [-1.0, 1.0]:
		b.circle(c + Vector2(s * 8.0, -3.0), 4.0, PENNANT_GOLD)
	b.rect(Rect2(c.x - 10.0, c.y + 7.0, 20.0, 5.0), PENNANT_BLACK)


# the railway over the underpass: the concrete deck, ballast, two tracks
static func _rail_deck(b: ShapeBatch) -> void:
	var r := Rect2(WALL_L - 120.0, UNDERPASS.position.y, WALL_R - WALL_L + 240.0, UNDERPASS.size.y)
	b.rect(Rect2(r.position + Vector2(10, 18), r.size), Color(0.02, 0.02, 0.05, 0.3))
	b.rect(r, RAIL_DECK.darkened(0.2))
	b.rect(r.grow_individual(0.0, -8.0, 0.0, -8.0), Color(0.42, 0.38, 0.34))
	for ty: float in [r.position.y + 38.0, r.end.y - 38.0]:
		var x := r.position.x + 6.0
		while x < r.end.x:
			b.rect(Rect2(x, ty - 14.0, 8.0, 28.0), SLEEPER)
			x += 16.0
		b.rect(Rect2(r.position.x, ty - 9.0, r.size.x, 3.0), RAIL)
		b.rect(Rect2(r.position.x, ty + 6.0, r.size.x, 3.0), RAIL)
	b.rect(Rect2(r.position.x, r.position.y, r.size.x, 6.0), RAIL_DECK)
	b.rect(Rect2(r.position.x, r.end.y - 6.0, r.size.x, 6.0), RAIL_DECK)


# a palm's crown from above: fronds fanned out round the top, darker ribs
static func _palm_crown(b: ShapeBatch, p: Vector2) -> void:
	b.circle(p + Vector2(10.0, 16.0), 46.0, Color(0.02, 0.03, 0.05, 0.22))
	for i in range(9):
		var a := float(i) * TAU / 9.0 + p.y * 0.01
		var tip := p + Vector2.from_angle(a) * 54.0
		var side := Vector2.from_angle(a).orthogonal() * 11.0
		b.polygon(PackedVector2Array([p + side * 0.4, p + Vector2.from_angle(a) * 26.0 + side, tip, p + Vector2.from_angle(a) * 26.0 - side, p - side * 0.4]), PALM_FROND.lightened(0.06 * float(i % 3)))
		b.line(p, tip, PALM_FROND.darkened(0.3), 1.5)
	b.circle(p, 8.0, PALM_TRUNK.darkened(0.2))
