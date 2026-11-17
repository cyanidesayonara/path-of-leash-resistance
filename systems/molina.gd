class_name Molina
extends RefCounted

# WALK: LA MOLINA (the ski station in the Cerdanya Pyrenees, in snow)
# The first snow walk. Up a groomed piste through the firs from the bottom of
# the lifts to the xalet at the top: corduroy snow down the middle, deep
# powder banked up either side (it drags at her paws), orange piste markers
# along the edges, the ski school's slalom gates and firs standing in the way
# to wind the leash on, the chairlift's cable and chairs going over.
#
# The live event is the snow cannons. Three stand at the piste's edge; each
# spins up with a whir and its lamp flashing (CANNON_WARN, the telegraph),
# then blows a cone of snow across the piste for CANNON_BLOW. Whoever is in
# the cone is knocked (the dog) or bumped and chilled (your human). A blast
# that comes by the pair and catches neither is a dodge.
#
# Higher up, the ski-hire rack (y = -3300) and the snowman beside the piste;
# then the terrace of the xalet, its picnic tables, and the grill.
#
# On the way home the piste basher's brake lets go (entities/groomer_threat.gd):
# it comes down after them, rolling snowballs ahead of its blade. It wedges in
# the ski-hire rack, then at the chairlift's queue barriers.

const Surfaces := preload("res://world/surfaces.gd")
const ShapeBatch := preload("res://systems/shape_batch.gd")
const EventFeed := preload("res://hud/event_feed.gd")
const AnimClock := preload("res://systems/anim_clock.gd")
const Groomer := preload("res://entities/groomer_threat.gd")

const HALF := 270.0
const CX := 640.0
const PATH_L := CX - HALF
const PATH_R := CX + HALF
const SHADOW := Color(0.10, 0.14, 0.26, 0.26)

# the snow, lit from the north-west, blue in the shade as snow is
const SNOW := Color(0.95, 0.96, 0.99)
const SNOW_LIT := Color(1.0, 1.0, 1.0)
const SNOW_SHADE := Color(0.78, 0.83, 0.93)
const SNOW_DEEP := Color(0.62, 0.70, 0.86)
const PISTE := Color(0.91, 0.93, 0.98)
const CORDUROY := Color(0.80, 0.85, 0.95)
const ICE := Color(0.74, 0.86, 0.94)
# the firs: dark blue-green, snow on their boughs
const FIR := Color(0.13, 0.27, 0.25)
const FIR_LIT := Color(0.22, 0.38, 0.32)
const FIR_TRUNK := Color(0.36, 0.24, 0.18)
# the piste furniture
const MARKER_ORANGE := Color(0.98, 0.50, 0.10)
const MARKER_BLACK := Color(0.12, 0.12, 0.14)
const GATE_RED := Color(0.90, 0.16, 0.16)
const GATE_BLUE := Color(0.14, 0.36, 0.86)
const STEEL := Color(0.58, 0.61, 0.66)
const STEEL_DARK := Color(0.32, 0.34, 0.38)
const WOOD := Color(0.52, 0.34, 0.22)
const WOOD_DARK := Color(0.34, 0.22, 0.14)
const ROOF_SLATE := Color(0.30, 0.30, 0.34)
const STONE := Color(0.62, 0.60, 0.58)
const CANNON := Color(0.92, 0.88, 0.20)
const CANNON_DARK := Color(0.52, 0.48, 0.12)
const LAMP_ON := Color(1.0, 0.52, 0.12)
const CARROT := Color(0.96, 0.48, 0.10)

# firs standing on the piste: poles the leash winds round
const FIRS: Array[Vector2] = [
	Vector2(470.0, -700.0), Vector2(820.0, -1050.0), Vector2(560.0, -1420.0),
	Vector2(790.0, -2250.0), Vector2(480.0, -2850.0), Vector2(830.0, -3050.0),
	Vector2(590.0, -3720.0), Vector2(770.0, -4020.0),
]
const FIR_R := 22.0
const FIR_CROWN := 46.0
# the ski school's slalom gates: a red and a blue pole, flags between
const GATES: Array[Vector2] = [
	Vector2(610.0, -430.0), Vector2(700.0, -560.0),
	Vector2(600.0, -2440.0), Vector2(690.0, -2570.0),
]

# the snow cannons: [nozzle, firing direction across the piste, phase offset]
const CANNONS := [
	[Vector2(PATH_R + 18.0, -1000.0), Vector2(-1.0, 0.18), 0.0],
	[Vector2(PATH_L - 18.0, -2680.0), Vector2(1.0, 0.18), 3.0],
	[Vector2(PATH_R + 18.0, -3900.0), Vector2(-1.0, 0.18), 6.0],
]
const CANNON_CYCLE := 9.0       # one blast every this long
const CANNON_WARN := 1.0        # whir and lamp before the snow comes
const CANNON_BLOW := 2.0        # how long it blows
const CANNON_REACH := 330.0     # how far across the piste the cone goes
const CANNON_W0 := 26.0         # the cone's half-width at the nozzle
const CANNON_SPREAD := 0.34     # and how it widens with distance
const CANNON_INVOLVED := 240.0  # a blast this near the pair counts toward a dodge

# the chairlift: its cable crosses the piste here, a pylon either side
const LIFT_Y := -2000.0
const LIFT_PYLONS: Array[Vector2] = [Vector2(250.0, -2060.0), Vector2(1030.0, -1940.0)]
const LIFT_SPEED := 70.0
const LIFT_GAP := 150.0

# the chairlift's queue barriers: two posts, the midpoint jam between them
const LIFT_POSTS: Array[Rect2] = [
	Rect2(380.0, -1924.0, 36.0, 28.0),
	Rect2(864.0, -1924.0, 36.0, 28.0),
]
# the ski-hire rack, where the groomer wedges first
const RACK_RECT := Rect2(410.0, -3320.0, 96.0, 36.0)
const RACK_POS := Vector2(458.0, -3300.0)
# the snowman, beside the piste: bark at him and his nose drops off
const SNOWMAN := Vector2(842.0, -3560.0)

# the top: the xalet's terrace, its picnic tables, the grill
const TERRACE_Y := -4300.0
const TERRACE_TOP := -4760.0
const TABLES: Array[Rect2] = [
	Rect2(390.0, -4620.0, 92.0, 40.0),
	Rect2(798.0, -4620.0, 92.0, 40.0),
]
const GRILL := Vector2(640.0, -4700.0)
const PRIZE := Vector2(640.0, -4680.0)
const PRIZE_TEXT := "snatch the botifarra off the xalet's grill"


static func solids(_m: Node2D) -> Array[Rect2]:
	return [RACK_RECT, LIFT_POSTS[0], LIFT_POSTS[1], TABLES[0], TABLES[1]]


static func wrap_rects() -> Array[Rect2]:
	return solids(null)


static func build(m: Node2D) -> Array:
	m.gate_text = "XALET DE LA MOLINA"
	m.chase_jams.clear()
	m.chase_jams.append(RACK_POS)
	m.chase_jams.append(Vector2(CX, -1900.0))
	m.stalls.clear()
	m.stall_kinds.clear()
	m.astands = Array([], TYPE_VECTOR2, &"", null)
	m.manholes = Array([], TYPE_VECTOR2, &"", null)
	m.cone_spots = Array([Vector2(560.0, -1600.0), Vector2(720.0, -3150.0)], TYPE_VECTOR2, &"", null)
	m.fountains = Array([], TYPE_VECTOR2, &"", null)
	m.bins = Array([
		Vector2(PATH_L + 30.0, -1150.0),
		Vector2(PATH_R - 30.0, -2150.0),
		Vector2(PATH_L + 30.0, -3460.0),
		Vector2(PATH_R - 30.0, -4400.0),
	], TYPE_VECTOR2, &"", null)
	for f: Vector2 in FIRS:
		m.poles.append(f)
	for g: Vector2 in GATES:
		m.poles.append(g)
	# their feet are drawn on the ground (draw_column)
	m.deco_pole_count = m.poles.size()
	# the piste markers she marks: an orange pole in a cap of snow
	var marks: Array[Vector2] = [
		Vector2(PATH_L + 26.0, -380.0),
		Vector2(PATH_R - 26.0, -1250.0),
		Vector2(PATH_L + 26.0, -2100.0),
		Vector2(PATH_R - 26.0, -2900.0),
		RACK_POS + Vector2(0.0, 60.0),
		Vector2(PATH_L + 26.0, -4100.0),
		PRIZE + Vector2(-120.0, 60.0),
	]
	# what skiers drop: a bocata in its foil
	var snacks: Array[Vector2] = [
		Vector2(540.0, -820.0),
		Vector2(760.0, -1720.0),
		Vector2(590.0, -2780.0),
		Vector2(520.0, -3390.0),
		Vector2(700.0, -4220.0),
	]
	return [marks, snacks]


# --- the snow cannons ----------------------------------------------------------
# Walk time (main.elapsed) drives them, so a seeded walk replays.

# 0 idle, 1 spinning up (the telegraph), 2 blowing
static func cannon_state(i: int, elapsed: float) -> int:
	var t := fposmod(elapsed + float(CANNONS[i][2]), CANNON_CYCLE)
	var blow_at := CANNON_CYCLE - CANNON_BLOW
	if t >= blow_at:
		return 2
	if t >= blow_at - CANNON_WARN:
		return 1
	return 0


# how far into its blast a cannon is, 0..1, or -1 when it is not blowing
static func cannon_blow_k(i: int, elapsed: float) -> float:
	var t := fposmod(elapsed + float(CANNONS[i][2]), CANNON_CYCLE)
	var blow_at := CANNON_CYCLE - CANNON_BLOW
	return (t - blow_at) / CANNON_BLOW if t >= blow_at else -1.0


static func in_cone(i: int, p: Vector2) -> bool:
	var nz: Vector2 = CANNONS[i][0]
	var dir: Vector2 = (CANNONS[i][1] as Vector2).normalized()
	var d := p - nz
	var along := d.dot(dir)
	if along < 0.0 or along > CANNON_REACH:
		return false
	return absf(d.dot(dir.orthogonal())) < CANNON_W0 + along * CANNON_SPREAD


static func tick(m: Node2D, delta: float) -> void:
	if m.lvl != "molina":
		return
	var dp: Vector2 = m.dog.global_position
	var hp: Vector2 = m.human.global_position
	var st: Dictionary = m.molina_cannons
	for i in range(CANNONS.size()):
		var key := str(i)
		var c: Dictionary = st.get(key, {"state": 0, "hit": false, "involved": false})
		var now := cannon_state(i, m.elapsed)
		var was := int(c["state"])
		var nz: Vector2 = CANNONS[i][0]
		if now != was:
			if now == 1:
				c["hit"] = false
				c["involved"] = false
				if absf(dp.y - nz.y) < 600.0:
					Sfx.play("cannon_whir", 1.0, -6.0)
			elif now == 2:
				if absf(dp.y - nz.y) < 600.0:
					Sfx.play("poof", 0.5, -4.0)
			elif was == 2:
				# a blast that came by the pair and touched neither: dodged
				if bool(c["involved"]) and not bool(c["hit"]):
					m.molina_cannon_dodges += 1
					m.award_points(2, "dodged the cannon! +2")
			c["state"] = now
		if now == 2:
			if absf(hp.y - nz.y) < CANNON_INVOLVED or absf(dp.y - nz.y) < CANNON_INVOLVED:
				c["involved"] = true
			if not bool(c["hit"]):
				var dog_hit := in_cone(i, dp)
				var hum_hit := in_cone(i, hp)
				if dog_hit or hum_hit:
					c["hit"] = true
					m.molina_cannon_hits += 1
					var dir: Vector2 = (CANNONS[i][1] as Vector2).normalized()
					m.feed.say("SNOWED ON!", EventFeed.Tone.LOUD)
					if dog_hit:
						m.dog.knocked(dir, "snow")
					if hum_hit:
						m.human.patience = maxf(0.0, m.human.patience - m.LIVE_EVENT_BUMP_PATIENCE)
						m.human.bumped(dir)
						m.float_text(hp, "Brrr!", Color(0.86, 0.94, 1.0))
		st[key] = c
	m.molina_cannons = st


# the banner while a cannon near them is spinning up
static func idle_status(m: Node2D) -> String:
	if m.lvl != "molina":
		return ""
	var dp: Vector2 = m.dog.global_position
	for i in range(CANNONS.size()):
		var nz: Vector2 = CANNONS[i][0]
		if cannon_state(i, m.elapsed) == 1 and absf(dp.y - nz.y) < 260.0:
			return "SNOW CANNON! KEEP OUT OF ITS WAY"
	return ""


static func on_bark(m: Node2D, pos: Vector2) -> void:
	if m.lvl != "molina":
		return
	if pos.distance_to(SNOWMAN) < 150.0 and not m.molina_snowman_barked:
		m.molina_snowman_barked = true
		m.bones += 3
		m.float_text(SNOWMAN + Vector2(0.0, -40.0), "nose! +3", CARROT)
		m.feed.say("HIS NOSE FELL OFF!", EventFeed.Tone.GOOD)
		Sfx.play("poof", 1.4, -6.0)


# --- drawing -----------------------------------------------------------------

static func _h(n: float) -> float:
	return fposmod(sin(n * 12.9898 + 4.1) * 43758.5453, 1.0)


# where the deep snow begins either side of the piste, wandering a little
static func _bank_x(y: float, side: float) -> float:
	var wob := 10.0 * sin(y * 0.013 + side) + 6.0 * sin(y * 0.041 + 2.0 * side)
	return (PATH_R + 8.0 + wob) if side > 0.0 else (PATH_L - 8.0 + wob)


# The mountainside either side: banks of deep powder, the fir forest on them
# with snow on its boughs, a far piste with its skiers on the east.
static func draw_edge_layer(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	var top: float = maxf(vt, m.GATE_Y - 40.0)
	var bot: float = minf(vb, float(m.START_Y) + 560.0)
	if bot <= top:
		return
	var was := b.lod
	b.lod = true
	b.rect(Rect2(-460.0, top, PATH_L + 460.0, bot - top), SNOW_SHADE)
	b.rect(Rect2(PATH_R, top, 1740.0 - PATH_R, bot - top), SNOW_SHADE)
	var strip := 60.0
	var y := floorf(top / strip) * strip
	while y < bot:
		var k := absf(y) / strip
		for side: float in [-1.0, 1.0]:
			# the bank's lit lip along the piste
			var bx := _bank_x(y, side)
			b.coarse(Vector2(bx + side * 18.0, y + 30.0), 26.0, SNOW)
			b.coarse(Vector2(bx + side * 10.0 - 5.0, y + 24.0), 16.0, SNOW_LIT)
			# drifts and hummocks in the powder
			for j in range(3):
				var hx := bx + side * (60.0 + _h(k * 3.1 + float(j) * 7.0 + side) * 300.0)
				var hy := y + _h(k * 5.7 + float(j) + side * 3.0) * strip
				var hr := 20.0 + _h(k + float(j) * 2.0) * 30.0
				b.coarse(Vector2(hx + 6.0, hy + 6.0), hr, SNOW_DEEP.lerp(SNOW_SHADE, 0.5))
				b.coarse(Vector2(hx, hy), hr, SNOW)
				b.coarse(Vector2(hx - hr * 0.3, hy - hr * 0.3), hr * 0.55, SNOW_LIT)
		y += strip
	# the forest: firs from above, thicker further from the piste
	var fy := floorf(top / 90.0) * 90.0
	while fy < bot + 90.0:
		var k := absf(fy) / 90.0
		for side: float in [-1.0, 1.0]:
			for j in range(4):
				var off := 110.0 + float(j) * 95.0 + _h(k * 1.3 + float(j) + side) * 60.0
				var x := (PATH_R + off) if side > 0.0 else (PATH_L - off)
				var py := fy + _h(k * 7.1 + float(j) * 3.0 + side) * 80.0
				if side > 0.0 and j == 3 and int(k) % 5 < 2:
					continue
				fir_top(b, Vector2(x, py), 30.0 + _h(k + float(j) * 4.0) * 18.0, k + float(j) * 3.0)
		fy += 90.0
	# the chairlift's pylons, standing in the powder either side
	for p: Vector2 in LIFT_PYLONS:
		if p.y > top - 100.0 and p.y < bot + 100.0:
			b.circle(p + Shade.light * 26.0, 18.0, SHADOW)
			b.rect(Rect2(p.x - 12.0, p.y - 12.0, 24.0, 24.0), STEEL_DARK)
			b.rect(Rect2(p.x - 9.0, p.y - 9.0, 18.0, 18.0), STEEL)
			b.circle(p, 5.0, SNOW)
	b.lod = was


# a fir from above: tiers of boughs, darkest at the bottom, snow on each
static func fir_top(b: ShapeBatch, p: Vector2, r: float, seed_n: float) -> void:
	b.coarse(p + Shade.light * (r * 0.6), r * 1.02, SHADOW)
	for tier in range(3):
		var tr := r * (1.0 - float(tier) * 0.28)
		var c := p - Shade.light * (float(tier) * r * 0.08)
		var n := 7 - tier
		for i in range(n):
			var a := float(i) * TAU / float(n) + seed_n * 0.9 + float(tier) * 0.4
			var bp := c + Vector2.from_angle(a) * tr * 0.62
			b.coarse(bp, tr * 0.42, FIR.lerp(FIR_LIT, float(tier) * 0.3))
			b.coarse(bp - Shade.light * (tr * 0.10), tr * 0.24, SNOW if (i + tier) % 2 == 0 else SNOW_SHADE)
		b.coarse(c, tr * 0.45, FIR.lerp(FIR_LIT, float(tier) * 0.3))
	b.coarse(p - Shade.light * (r * 0.22), r * 0.20, SNOW_LIT)


# --- cross section: the piste and what stands on it --------------------------

static func draw_cross_section(m: Node2D, wc: ShapeBatch, _top: float, _bottom: float, ctop: float, vt: float, vb: float) -> void:
	var lo: float = maxf(vt - 60.0, ctop)
	var hi: float = minf(vb + 60.0, float(m.START_Y) + 560.0)
	if hi <= lo:
		return
	var was := wc.lod
	wc.lod = true
	_draw_piste(wc, lo, hi)
	_draw_markers(wc, lo, hi)
	_draw_rack(wc, lo, hi)
	_draw_lift_posts(wc, lo, hi)
	_draw_terrace(wc, lo, hi)
	_draw_cannons(wc, lo, hi)
	wc.lod = was


# groomed snow: corduroy down the fall line, a trodden track up the middle,
# the odd ski track curving across, ice where it is polished
static func _draw_piste(wc: ShapeBatch, lo: float, hi: float) -> void:
	wc.rect(Rect2(PATH_L, lo, PATH_R - PATH_L, hi - lo), PISTE)
	var x := PATH_L + 6.0
	var i := 0
	while x < PATH_R:
		wc.rect(Rect2(x, lo, 3.0, hi - lo), Color(CORDUROY, 0.55 if i % 2 == 0 else 0.35))
		x += 11.0
		i += 1
	# the walkers' trodden track
	wc.rect(Rect2(CX - 46.0, lo, 92.0, hi - lo), Color(SNOW_SHADE, 0.35))
	var strip := 120.0
	var y := floorf(lo / strip) * strip
	while y < hi:
		var k := absf(y) / strip
		# a skier's two tracks, curving across
		var sx := PATH_L + 40.0 + _h(k * 2.3) * (PATH_R - PATH_L - 80.0)
		var bend := (_h(k * 4.1) - 0.5) * 160.0
		for side: float in [-4.0, 4.0]:
			var prev := Vector2(sx + side, y)
			for s in range(1, 7):
				var f := float(s) / 6.0
				var pt := Vector2(sx + side + sin(f * PI) * bend, y + f * strip)
				if pt.x > PATH_L + 10.0 and pt.x < PATH_R - 10.0 and prev.x > PATH_L + 10.0 and prev.x < PATH_R - 10.0:
					wc.line(prev, pt, Color(SNOW_DEEP, 0.40), 2.0)
				prev = pt
		# an icy patch, polished blue
		if int(k) % 3 == 1:
			var ip := Vector2(PATH_L + 70.0 + _h(k * 6.7) * (PATH_R - PATH_L - 140.0), y + 40.0 + _h(k) * 40.0)
			wc.coarse(ip, 20.0 + _h(k * 2.0) * 14.0, Color(ICE, 0.55))
			wc.coarse(ip - Vector2(5.0, 5.0), 8.0, Color(1.0, 1.0, 1.0, 0.5))
		y += strip


# the piste's edge, marked every so often with an orange-and-black pole
static func _draw_markers(wc: ShapeBatch, lo: float, hi: float) -> void:
	var step := 300.0
	var y := floorf(lo / step) * step
	while y < hi:
		for side: float in [-1.0, 1.0]:
			var p := Vector2(_bank_x(y, side) - side * 4.0, y)
			wc.line(p + Vector2(3.0, 3.0), p + Vector2(18.0, 16.0), SHADOW, 4.0)
			wc.circle(p, 5.0, MARKER_BLACK)
			wc.circle(p, 3.6, MARKER_ORANGE)
			wc.circle(p + Vector2(-1.0, -1.0), 1.4, Color(1.0, 0.86, 0.6))
		y += step


static func _draw_rack(wc: ShapeBatch, lo: float, hi: float) -> void:
	var r := RACK_RECT
	if r.end.y < lo or r.position.y > hi:
		return
	wc.rect(Rect2(r.position + Vector2(8.0, 10.0), r.size), SHADOW)
	wc.rect(r, WOOD_DARK)
	wc.rect(r.grow(-3.0), WOOD)
	wc.rect(Rect2(r.position.x, r.position.y, r.size.x, 6.0), SNOW)
	# the hire skis and boards stood in it, tips up
	var cols := [GATE_RED, GATE_BLUE, Color(0.98, 0.84, 0.18), Color(0.20, 0.72, 0.52), GATE_RED, Color(0.92, 0.94, 0.96)]
	for i in range(cols.size()):
		var x := r.position.x + 9.0 + float(i) * 15.0
		wc.capsule(Vector2(x, r.position.y + 4.0), Vector2(x, r.end.y - 4.0), 4.0, cols[i])
		wc.circle(Vector2(x, r.position.y + 5.0), 3.0, (cols[i] as Color).lightened(0.3))


static func _draw_lift_posts(wc: ShapeBatch, lo: float, hi: float) -> void:
	if LIFT_POSTS[0].end.y < lo - 40.0 or LIFT_POSTS[0].position.y > hi + 40.0:
		return
	# the queue's rope maze between the posts, slack in the middle
	var a := LIFT_POSTS[0].get_center()
	var z := LIFT_POSTS[1].get_center()
	for row in range(2):
		var dy := -14.0 + float(row) * 28.0
		var prev := a + Vector2(0.0, dy)
		for s in range(1, 13):
			var f := float(s) / 12.0
			var pt := a.lerp(z, f) + Vector2(0.0, dy + sin(f * PI) * 8.0)
			wc.line(prev, pt, Color(0.16, 0.30, 0.70), 2.4)
			prev = pt
	for r: Rect2 in LIFT_POSTS:
		wc.rect(Rect2(r.position + Vector2(6.0, 8.0), r.size), SHADOW)
		wc.rect(r, STEEL_DARK)
		wc.rect(r.grow(-3.0), STEEL)
		wc.rect(Rect2(r.position.x + 4.0, r.position.y + 4.0, r.size.x - 8.0, 6.0), SNOW)


static func _draw_terrace(wc: ShapeBatch, lo: float, hi: float) -> void:
	if TERRACE_Y < lo:
		return
	var top := maxf(lo, TERRACE_TOP)
	if hi <= top:
		return
	# the terrace's boards, cleared of snow, a dusting at the edges
	var r := Rect2(PATH_L, top, PATH_R - PATH_L, minf(hi, TERRACE_Y) - top)
	if r.size.y > 0.0:
		wc.rect(r, WOOD)
		var y := floorf(r.position.y / 18.0) * 18.0
		while y < r.end.y:
			wc.rect(Rect2(r.position.x, y, r.size.x, 1.6), WOOD_DARK)
			y += 18.0
		wc.rect(Rect2(PATH_L, TERRACE_Y - 10.0, PATH_R - PATH_L, 10.0), Color(SNOW, 0.85))
	for t: Rect2 in TABLES:
		if t.end.y < lo or t.position.y > hi:
			continue
		wc.rect(Rect2(t.position + Vector2(8.0, 10.0), t.size), SHADOW)
		wc.rect(Rect2(t.position.x - 4.0, t.position.y - 10.0, t.size.x + 8.0, 7.0), WOOD_DARK)
		wc.rect(Rect2(t.position.x - 4.0, t.end.y + 3.0, t.size.x + 8.0, 7.0), WOOD_DARK)
		wc.rect(t, WOOD_DARK)
		wc.rect(t.grow(-2.5), WOOD.lightened(0.12))
		wc.circle(t.get_center() + Vector2(-20.0, 0.0), 6.0, Color(0.94, 0.94, 0.92))
		wc.circle(t.get_center() + Vector2(-20.0, 0.0), 4.0, Color(0.42, 0.22, 0.12))
		wc.circle(t.get_center() + Vector2(22.0, -4.0), 5.0, Color(0.94, 0.94, 0.92))
	# the grill: a half barrel on legs, the coals glowing, botifarres on it
	if GRILL.y > lo and GRILL.y < hi:
		var g := GRILL + Vector2(0.0, -60.0)
		wc.rect(Rect2(g.x - 40.0 + 8.0, g.y - 14.0 + 10.0, 80.0, 28.0), SHADOW)
		wc.rect(Rect2(g.x - 40.0, g.y - 14.0, 80.0, 28.0), Color(0.16, 0.16, 0.18))
		wc.glow(g, 40.0, Color(1.0, 0.46, 0.12, 0.35), 0.3)
		wc.rect(Rect2(g.x - 34.0, g.y - 9.0, 68.0, 18.0), Color(0.62, 0.20, 0.08))
		for i in range(5):
			wc.line(Vector2(g.x - 34.0 + float(i) * 17.0, g.y - 9.0), Vector2(g.x - 34.0 + float(i) * 17.0, g.y + 9.0), Color(0.30, 0.30, 0.32), 1.5)
		for i in range(3):
			var sp := g + Vector2(-20.0 + float(i) * 20.0, 0.0)
			wc.capsule(sp + Vector2(-8.0, -1.0), sp + Vector2(8.0, 1.0), 3.4, Color(0.54, 0.26, 0.20))


static func _draw_cannons(wc: ShapeBatch, lo: float, hi: float) -> void:
	for i in range(CANNONS.size()):
		var nz: Vector2 = CANNONS[i][0]
		if nz.y < lo - 120.0 or nz.y > hi + 120.0:
			continue
		var dir: Vector2 = (CANNONS[i][1] as Vector2).normalized()
		var base := nz - dir * 34.0
		# the tower's foot in the bank and its shadow
		wc.circle(base + Shade.light * 18.0, 16.0, SHADOW)
		wc.circle(base, 12.0, STEEL_DARK)
		wc.circle(base, 9.0, STEEL)


static func draw_live(m: Node2D, wc: ShapeBatch, vt: float, vb: float) -> void:
	if m.lvl != "molina":
		return
	var flash := int(AnimClock.msec() / 180) % 2 == 0
	for i in range(CANNONS.size()):
		var nz: Vector2 = CANNONS[i][0]
		if nz.y < vt - 360.0 or nz.y > vb + 360.0:
			continue
		var dir: Vector2 = (CANNONS[i][1] as Vector2).normalized()
		var st := cannon_state(i, m.elapsed)
		var side := dir.orthogonal()
		# the cone of snow it is blowing across the piste
		if st == 2:
			var k := cannon_blow_k(i, m.elapsed)
			var fade := minf(1.0, minf(k * 6.0, (1.0 - k) * 5.0))
			var reach := CANNON_REACH
			var far := nz + dir * reach
			var wf := CANNON_W0 + reach * CANNON_SPREAD
			wc.polygon(PackedVector2Array([nz + side * CANNON_W0, far + side * wf, far - side * wf, nz - side * CANNON_W0]), Color(SNOW, 0.34 * fade))
			for j in range(26):
				var f := fposmod(float(AnimClock.msec()) * 0.0011 + float(j) * 0.137, 1.0)
				var lat := (_h(float(j) * 3.3) - 0.5) * 2.0
				var p := nz + dir * (f * reach) + side * lat * (CANNON_W0 + f * reach * CANNON_SPREAD)
				wc.circle(p, 3.0 + f * 5.0, Color(SNOW_LIT, 0.85 * fade * (1.0 - f * 0.6)))
		# the fan housing on its tower: a yellow drum, the nozzle ring, its lamp
		var c := nz - dir * 14.0
		wc.circle(c + Shade.light * 10.0, 24.0, SHADOW)
		wc.circle(c, 22.0, CANNON_DARK)
		wc.circle(c, 19.0, CANNON)
		var spin := float(AnimClock.msec()) * (0.03 if st > 0 else 0.002)
		for j in range(5):
			var a := spin + float(j) * TAU / 5.0
			wc.line(c, c + Vector2.from_angle(a) * 15.0, CANNON_DARK, 3.0)
		wc.circle(c, 5.0, STEEL_DARK)
		wc.circle(nz, 8.0, STEEL_DARK)
		wc.circle(nz, 5.0, STEEL)
		var lamp := c - side * 24.0
		if st == 1 and flash:
			wc.glow(lamp, 30.0, Color(LAMP_ON, 0.6))
		wc.circle(lamp, 5.0, LAMP_ON if (st == 1 and flash) or st == 2 else Color(0.42, 0.22, 0.10))
	# the snowman: a carrot nose until she barks it off
	if SNOWMAN.y > vt - 80.0 and SNOWMAN.y < vb + 80.0:
		var s := SNOWMAN
		wc.circle(s + Shade.light * 14.0, 26.0, SHADOW)
		wc.circle(s + Vector2(0.0, 6.0), 24.0, SNOW_SHADE)
		wc.circle(s + Vector2(-3.0, 3.0), 21.0, SNOW)
		wc.circle(s + Vector2(0.0, -16.0), 15.0, SNOW_SHADE)
		wc.circle(s + Vector2(-2.0, -18.0), 13.0, SNOW_LIT)
		wc.line(s + Vector2(-12.0, -6.0), s + Vector2(12.0, -6.0), Color(0.86, 0.14, 0.16), 5.0)
		wc.circle(s + Vector2(-5.0, -21.0), 2.0, MARKER_BLACK)
		wc.circle(s + Vector2(4.0, -21.0), 2.0, MARKER_BLACK)
		for j in range(2):
			wc.line(s + Vector2(-20.0 + float(j) * 40.0, 0.0), s + Vector2(-36.0 + float(j) * 72.0, -12.0), WOOD_DARK, 2.5)
		if m.molina_snowman_barked:
			wc.polygon(PackedVector2Array([s + Vector2(10.0, 22.0), s + Vector2(24.0, 26.0), s + Vector2(11.0, 28.0)]), CARROT)
		else:
			wc.polygon(PackedVector2Array([s + Vector2(-1.0, -18.0), s + Vector2(14.0, -15.0), s + Vector2(-1.0, -13.0)]), CARROT)


# over the pair: the firs' crowns, the slalom flags, the chairlift's cable and
# its chairs going over
static func draw_overhead(m: Node2D, ci: Object) -> void:
	if m.lvl != "molina":
		return
	var b := ShapeBatch.new()
	b.lod = true
	for i in range(FIRS.size()):
		fir_top(b, FIRS[i] + Vector2(0.0, -12.0), FIR_CROWN, float(i) * 2.7)
	# each slalom pole's flag at its top, stirring in the air
	for i in range(GATES.size()):
		var top: Vector2 = GATES[i] + Vector2(0.0, -26.0)
		var col := GATE_RED if (i / 2) % 2 == 0 else GATE_BLUE
		var flap := sin(float(AnimClock.msec()) * 0.004 + float(i)) * 2.0
		b.quad(top, top + Vector2(17.0, 2.0 + flap), top + Vector2(16.0, 13.0 + flap), top + Vector2(0.0, 12.0), col)
		b.line(top + Vector2(1.0, 6.0), top + Vector2(16.0, 7.5 + flap), col.lightened(0.35), 1.5)
	var a0: Vector2 = LIFT_PYLONS[0] + Vector2(0.0, -70.0)
	var a1: Vector2 = LIFT_PYLONS[1] + Vector2(0.0, -70.0)
	b.line(a0 + Vector2(0.0, -6.0), a1 + Vector2(0.0, -6.0), STEEL_DARK, 2.0)
	b.line(a0 + Vector2(0.0, 6.0), a1 + Vector2(0.0, 6.0), STEEL_DARK, 2.0)
	for p: Vector2 in [a0, a1]:
		b.rect(Rect2(p.x - 20.0, p.y - 8.0, 40.0, 16.0), STEEL)
		b.circle(p + Vector2(-14.0, 0.0), 5.0, STEEL_DARK)
		b.circle(p + Vector2(14.0, 0.0), 5.0, STEEL_DARK)
	var span := a0.distance_to(a1)
	var dirv := (a1 - a0) / span
	var shift := fmod(float(AnimClock.msec()) * 0.001 * LIFT_SPEED, LIFT_GAP)
	var d := shift
	while d < span:
		for lane: float in [-6.0, 6.0]:
			var dd := d if lane < 0.0 else span - d
			var cp := a0 + dirv * dd + Vector2(0.0, lane)
			b.line(cp, cp + Vector2(0.0, 22.0), STEEL_DARK, 2.0)
			b.rect(Rect2(cp.x - 13.0, cp.y + 20.0, 26.0, 12.0), Color(0.14, 0.20, 0.42))
			b.rect(Rect2(cp.x - 13.0, cp.y + 20.0, 26.0, 3.0), SNOW)
			if int(dd / LIFT_GAP) % 3 == 0:
				b.circle(cp + Vector2(-5.0, 26.0), 5.0, GATE_RED)
				b.circle(cp + Vector2(6.0, 26.0), 5.0, Color(0.98, 0.84, 0.18))
		d += LIFT_GAP
	b.flush(ci)


# no street lamps on the mountain: its posts are drawn as what they are
static func is_lamp(_m: Node2D, _p: Vector2) -> bool:
	return false


static func tree_kind(m: Node2D, _p: Vector2) -> int:
	return m.TREE_NONE


static func _is_fir(p: Vector2) -> bool:
	for f: Vector2 in FIRS:
		if f.distance_squared_to(p) < 4.0:
			return true
	return false


# a pole's foot: a fir's trunk in its well of snow, or a slalom pole
static func draw_column(_m: Node2D, wc: ShapeBatch, p: Vector2) -> void:
	if _is_fir(p):
		wc.glow(p + Shade.light * 24.0, FIR_CROWN * 1.2, Color(0.12, 0.18, 0.34, 0.28), 0.45)
		wc.circle(p, FIR_R + 4.0, SNOW_DEEP)
		wc.circle(p - Shade.light * 2.0, FIR_R, SNOW_SHADE)
		wc.circle(p, 8.0, FIR_TRUNK.darkened(0.25))
		wc.circle(p, 6.5, FIR_TRUNK)
		wc.circle(p - Shade.light * 1.6, 3.2, FIR_TRUNK.lightened(0.2))
		return
	var red := false
	for i in range(GATES.size()):
		if GATES[i].distance_squared_to(p) < 4.0:
			red = (i / 2) % 2 == 0
	wc.line(p + Vector2(2.0, 3.0), p + Vector2(14.0, 14.0), SHADOW, 4.0)
	wc.circle(p, 4.0, MARKER_BLACK)
	wc.circle(p, 3.0, GATE_RED if red else GATE_BLUE)
	wc.line(p, p + Vector2(0.0, -26.0), GATE_RED if red else GATE_BLUE, 3.0)


static func surface(m: Node2D, p: Vector2) -> int:
	if p.y > m.GATE_Y and p.y > TERRACE_Y:
		if p.x < _bank_x(p.y, -1.0) or p.x > _bank_x(p.y, 1.0):
			return Surfaces.S.SAND
		return Surfaces.S.PAVEMENT
	return -1


# What a dog marks on a piste: an orange marker pole capped with snow.
# Marked, a yellow stain spreads at its foot.
static func draw_bollard(m: Node2D, wc: ShapeBatch, h) -> void:
	var hp: Vector2 = h.pos
	m.cast_shadow(wc, hp, 8.0, 22.0)
	wc.circle(hp, 10.0, SNOW_SHADE)
	if h.done:
		wc.circle(hp + Vector2(3.0, 4.0), 9.0, Color(0.96, 0.86, 0.30, 0.7))
	wc.circle(hp, 6.0, MARKER_BLACK)
	wc.circle(hp, 4.6, MARKER_ORANGE)
	wc.line(hp, hp + Vector2(0.0, -22.0), MARKER_ORANGE, 4.0)
	for k in range(3):
		wc.line(hp + Vector2(0.0, -4.0 - float(k) * 7.0), hp + Vector2(0.0, -7.0 - float(k) * 7.0), MARKER_BLACK, 4.0)
	wc.circle(hp + Vector2(0.0, -23.0), 4.0, SNOW_LIT)
	if not h.done and h.progress > 0.0:
		wc.draw_arc(hp, 19.0, -PI / 2.0, -PI / 2.0 + TAU * h.progress / 0.8, 20, Color(1, 0.95, 0.7), 3.0)


# a dropped snack: half a bocata in its foil
static func draw_snack(m: Node2D, wc: ShapeBatch, kp: Vector2) -> void:
	m.contact_shadow(wc, kp, 12.0, 3.0, 0.20)
	wc.polygon(PackedVector2Array([kp + Vector2(-13, -6), kp + Vector2(4, -8), kp + Vector2(6, 6), kp + Vector2(-12, 7)]), Color(0.80, 0.82, 0.86))
	wc.line(kp + Vector2(-13, -6), kp + Vector2(4, -8), Color(0.96, 0.97, 1.0), 1.6)
	wc.capsule(kp + Vector2(-2, 0), kp + Vector2(12, -2), 5.0, Color(0.86, 0.66, 0.36))
	wc.capsule(kp + Vector2(0, 1), kp + Vector2(11, -1), 2.2, Color(0.80, 0.30, 0.30))
