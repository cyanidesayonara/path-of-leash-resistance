class_name Aigues
extends RefCounted

# WALK 22: LA CARRETERA DE LES AIGÜES (the hillside track)
# The old water main's service road along Collserola: a level track of packed
# sauló that follows the contour, bending into every gully and out round every
# spur. Uphill, east: the rock cut and the dry-stone retaining wall, pines and
# broom, and the water main's stone inspection hut. Downhill, west: a timber
# post-and-rail fence over the scrub, and the whole city to the sea. Runners
# and mountain bikes both ways, ringing as they come (rider_lane, tick).
#
# The gully: the track pinches over a stone culvert whose parapets are
# grindable (systems/rails.gd), with the mud lying in the low spot either
# side. The mirador: a bulge on the drop side with two benches at the fence;
# keep still there and your human looks up from the phone (the view goal).
# The off-leash clearing is the Font de la Budellera, in the wood at the end.
#
# Static functions over main's state (main.WALK_MODULES). The ground, the
# fence and the culvert are drawn on the world canvas each frame
# (draw_cross_section); the city below, the hillside and the hut on the
# cached edge layer (draw_edge_layer).

const ShapeBatch := preload("res://systems/shape_batch.gd")
const EventFeed := preload("res://hud/event_feed.gd")

const LIGHT := Vector2(0.5, 0.866)
const SHADOW := Color(0.05, 0.05, 0.08, 0.22)

# --- colors ------------------------------------------------------------------
const SAULO := Color(0.76, 0.66, 0.50)          # the track's pale granite grit
const SAULO_RUT := Color(0.67, 0.57, 0.42)
const SAULO_EDGE := Color(0.60, 0.52, 0.38)
const PEBBLE := Color(0.86, 0.80, 0.70)
const SCRUB := Color(0.34, 0.39, 0.25)
const SCRUB_DARK := Color(0.26, 0.31, 0.19)
const BROOM := Color(0.93, 0.80, 0.22)          # ginesta, yellow on the slopes
const ROCK_CUT := Color(0.60, 0.52, 0.42)
const ROCK_DARK := Color(0.47, 0.40, 0.32)
const DRYSTONE := Color(0.56, 0.52, 0.46)
const DRYSTONE_JOINT := Color(0.40, 0.37, 0.33)
const TIMBER := Color(0.52, 0.38, 0.24)
const TIMBER_LIT := Color(0.64, 0.49, 0.32)
const GRANITE := Color(0.74, 0.72, 0.68)
const IRON := Color(0.24, 0.24, 0.26)
const ROOF_TILE := Color(0.70, 0.38, 0.26)
const HAZE := Color(0.70, 0.66, 0.62)           # the city, late afternoon, far below
const BLOCK := Color(0.79, 0.72, 0.64)
const BLOCK_SHADE := Color(0.62, 0.57, 0.54)
const COURTYARD := Color(0.58, 0.62, 0.50)
const SEA := Color(0.48, 0.62, 0.72)
const SEA_GLINT := Color(0.92, 0.88, 0.74, 0.55)
const WATER := Color(0.36, 0.52, 0.60)

# --- layout ------------------------------------------------------------------
# the track's envelope: every bend stays inside sw_l..sw_r, so the straight
# walls at the level's sides never cut into it
const HALF := 320.0
# the gully, crossed on a stone culvert: the track pinches between parapets
const CULVERT_Y := -2225.0
const CULVERT_HALF_SPAN := 105.0        # parapets run CULVERT_Y +- this
const CULVERT_HALF_W := 150.0
# the mirador: a bulge on the drop side, the benches at its fence
const MIRADOR_Y := -3220.0
const MIRADOR_SPOT := Vector2(352.0, -3220.0)
const MIRADOR_R := 70.0
const VIEW_STILL := 18.0                # she counts as still under this speed
const VIEW_HOLD := 1.0                  # for this long
const VIEW_REACH := 260.0               # with your human this close
# the water main's inspection hut, set into the hillside off the east edge
const HUT := Rect2(930.0, -3980.0, 120.0, 92.0)
# fence posts on the drop side, one every FENCE_STEP; they catch the rope
const FENCE_STEP := 170.0
const FENCE_IN := 6.0                   # inside the track's west edge
# riders keep to the middle of the track, where every bend overlaps
const RIDE_LO := 520.0
const RIDE_HI := 760.0
const BELL_R := 300.0

# far below in the grid: (x, y, kind) - 0 the basilica's spires, 1 the tower
const LANDMARKS: Array[Vector3] = [Vector3(150.0, -1500.0, 0.0), Vector3(120.0, -3900.0, 1.0)]

const PRIZE := Vector2(386.0, -3150.0)
const PRIZE_TEXT := "nab the trail runner's banana off the mirador bench"


# Walk order, down the level: the trailhead, a spur west, a gully east, the
# culvert pinch, the mirador bulge west, the hut's lay-by east, the wood.
static func edge_nodes(m: Node2D) -> Array:
	return [
		{"y": m.START_Y, "cx": 640.0, "half": 220.0},
		{"y": -520.0, "cx": 590.0, "half": 220.0},
		{"y": -1120.0, "cx": 700.0, "half": 215.0},
		{"y": -1700.0, "cx": 585.0, "half": 220.0},
		{"y": -1990.0, "cx": 645.0, "half": 210.0},
		{"y": CULVERT_Y + CULVERT_HALF_SPAN + 20.0, "cx": 650.0, "half": CULVERT_HALF_W},
		{"y": CULVERT_Y - CULVERT_HALF_SPAN - 20.0, "cx": 650.0, "half": CULVERT_HALF_W},
		{"y": -2560.0, "cx": 660.0, "half": 215.0},
		{"y": -2980.0, "cx": 610.0, "half": 215.0},
		{"y": MIRADOR_Y, "cx": 590.0, "half": 265.0},
		{"y": -3460.0, "cx": 615.0, "half": 215.0},
		{"y": -3930.0, "cx": 700.0, "half": 225.0},
		{"y": -4420.0, "cx": 620.0, "half": 215.0},
		{"y": m.GATE_Y + 140.0, "cx": 640.0, "half": 235.0},
		{"y": m.GATE_Y, "cx": 640.0, "half": 250.0},
	]


static func _east(m: Node2D, y: float, inset: float) -> Vector2:
	var e: Vector2 = m.walk_edges(y)
	return Vector2(e.y - inset, y)


static func _west(m: Node2D, y: float, inset: float) -> Vector2:
	var e: Vector2 = m.walk_edges(y)
	return Vector2(e.x + inset, y)


static func on_culvert(y: float) -> bool:
	return absf(y - CULVERT_Y) <= CULVERT_HALF_SPAN


# The pines on the uphill margin, one standing at the gully's mouth to vault
# round, two behind the mirador. Deco poles: main draws them as forest trees.
static func pines(m: Node2D) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for y: float in [-260.0, -760.0, -1380.0, -1880.0, -2700.0, -3080.0, -3620.0, -4180.0, -4560.0]:
		out.append(_east(m, y, 26.0))
	# the gully's mouth, out on the track: the signature line's vault
	out.append(_east(m, CULVERT_Y + CULVERT_HALF_SPAN + 70.0, 70.0))
	return out


static func fence_posts(m: Node2D) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var y: float = m.START_Y - 120.0
	while y > m.GATE_Y + 160.0:
		if not on_culvert(y):
			out.append(_west(m, y, FENCE_IN))
		y -= FENCE_STEP
	return out


static func build(m: Node2D) -> Array:
	m.gate_text = "FONT DE LA BUDELLERA"
	m.stalls.clear()
	m.stall_kinds.clear()
	m.astands = Array([], TYPE_VECTOR2, &"", null)
	m.manholes = Array([], TYPE_VECTOR2, &"", null)
	for pp: Vector2 in pines(m):
		m.poles.append(pp)
	m.deco_pole_count = m.poles.size()
	for fp: Vector2 in fence_posts(m):
		m.poles.append(fp)
	# a runner's bottle and a gel wrapper, where people stop to look
	m.cone_spots = Array([
		_west(m, -1560.0, 60.0), _east(m, -3420.0, 70.0),
	], TYPE_VECTOR2, &"", null)
	m.bins = Array([
		_east(m, -420.0, 26.0), _east(m, MIRADOR_Y + 40.0, 30.0), _west(m, -4280.0, 30.0),
	], TYPE_VECTOR2, &"", null)
	# the mirador's two benches at the fence, facing the view
	m.benches = Array([
		_west(m, MIRADOR_Y + 70.0, 18.0), _west(m, MIRADOR_Y - 90.0, 18.0),
	], TYPE_VECTOR2, &"", null)
	# a stone font in the cut bank, below the clearing's own spring
	m.fountains = Array([_east(m, -4720.0, 22.0)], TYPE_VECTOR2, &"", null)
	# puddles in the low spots: the gully either side of the culvert, and
	# where the track dips into the other gullies
	m.patches = Array([
		{"y": CULVERT_Y + CULVERT_HALF_SPAN + 30.0, "at": 0.34, "rx": 52.0, "ry": 28.0, "seed": 1.30, "kind": "mud"},
		{"y": CULVERT_Y - CULVERT_HALF_SPAN - 40.0, "at": 0.62, "rx": 46.0, "ry": 26.0, "seed": 2.70, "kind": "mud"},
		{"y": -1150.0, "at": 0.70, "rx": 44.0, "ry": 24.0, "seed": 3.90, "kind": "mud"},
		{"y": -3960.0, "at": 0.40, "rx": 48.0, "ry": 26.0, "seed": 4.60, "kind": "mud"},
	], TYPE_DICTIONARY, &"", null)
	# Mark spots: the water main's stone markers along the edges, the hut's
	# corner, and the font
	var marks: Array[Vector2] = [
		_west(m, -620.0, 34.0),
		_east(m, -1240.0, 30.0),
		_west(m, -2000.0, 32.0),
		_east(m, -2900.0, 30.0),
		_east(m, HUT.get_center().y + 30.0, 24.0),
		_west(m, -4520.0, 34.0),
	]
	# dropped snacks: half an energy bar, a picnic bocadillo
	var snacks: Array[Vector2] = [
		_east(m, -1660.0, 80.0),
		_west(m, -2760.0, 90.0),
		_east(m, -4380.0, 90.0),
	]
	return [marks, snacks]


# --- main's walk hooks (main.WALK_MODULES) ---------------------------------------

# the pines on the margin are forest trees; nothing else here is a tree
static func tree_kind(m: Node2D, _p: Vector2) -> int:
	return m.TREE_FOREST


# riders keep to the middle of the track: mountain bikes fast, a kid now and
# then wobbling along on a bike of their own
static func rider_lane(_m: Node2D, _up: bool) -> Dictionary:
	var kid := randf() < 0.22
	var speed := randf_range(70.0, 115.0) if kid else randf_range(250.0, 360.0)
	var x := randf_range(RIDE_LO, RIDE_HI)
	return {"kid": kid, "speed": speed, "x": x, "lo": RIDE_LO, "hi": RIDE_HI}


static func tick(m: Node2D, delta: float) -> void:
	var hp: Vector2 = m.human.global_position
	# the riders ring as they come up on your human: the warning every
	# hazard to them gets
	for bk: Node2D in m.get_tree().get_nodes_in_group("bikes"):
		if String(bk.get("kind")) != "bike" or bk.has_meta("rang"):
			continue
		var to_h := hp - bk.global_position
		var v: Vector2 = bk.get("vel")
		if to_h.length() < BELL_R and v.dot(to_h) > 0.0:
			bk.set_meta("rang", true)
			m.float_text(bk.global_position + Vector2(0, -22), "ring ring!", Color(0.96, 0.94, 0.80))
			m.get_node("/root/Sfx").play("bell", 1.0 + randf_range(-0.04, 0.04), -9.0)
	# the view: keep still at the mirador with your human close by
	if bool(m.get_meta("aigues_view", false)):
		return
	var dp: Vector2 = m.dog.global_position
	var near: bool = dp.distance_to(MIRADOR_SPOT) < MIRADOR_R and m.dog.velocity.length() < VIEW_STILL \
		and dp.distance_to(hp) < VIEW_REACH
	var held: float = float(m.get_meta("aigues_still", 0.0)) + delta if near else 0.0
	m.set_meta("aigues_still", held)
	if held >= VIEW_HOLD:
		m.set_meta("aigues_view", true)
		m.bones += 5
		m.combo.add("THE VIEW", 4)
		m.float_text(hp + Vector2(0, -34), "...oh. wow.", Color(1, 1, 1, 0.9), m.POP_SAY)
		m.float_text(dp + Vector2(0, -30), "the view! +5", Color(0.96, 0.86, 0.32))
		m.feed.say("YOUR HUMAN LOOKED UP!", EventFeed.Tone.GOOD)
		m.get_node("/root/Sfx").play("prize", 1.05)


static func view_taken(m: Node2D) -> bool:
	return bool(m.get_meta("aigues_view", false))


# The ground, every frame, culled to the view: the track between its edges,
# its ruts and grit, the culvert's parapets and the fence along the drop.
static func draw_cross_section(m: Node2D, wc: ShapeBatch, _top: float, _bottom: float, ctop: float, vt: float, vb: float) -> void:
	var lo: float = maxf(vt - 30.0, ctop)
	var hi: float = minf(vb + 30.0, float(m.START_Y) + 560.0)
	var step := 24.0
	var y := floorf(hi / step) * step
	var eb: Vector2 = m.walk_edges(y + step)
	while y > lo - step:
		# a trapezoid per row, edge to edge, so the bends are smooth lines
		var ea: Vector2 = m.walk_edges(y)
		wc.polygon(PackedVector2Array([Vector2(ea.x, y), Vector2(ea.y, y), Vector2(eb.y, y + step), Vector2(eb.x, y + step)]), SAULO)
		# the berms where the grit gathers at the sides
		wc.line(Vector2(ea.x + 3.0, y), Vector2(eb.x + 3.0, y + step), SAULO_EDGE, 7.0)
		wc.line(Vector2(ea.y - 3.0, y), Vector2(eb.y - 3.0, y + step), SAULO_EDGE, 7.0)
		# two ruts worn by the service vans and the bikes since
		for f: float in [0.36, 0.64]:
			wc.line(Vector2(lerpf(ea.x, ea.y, f), y - 0.5), Vector2(lerpf(eb.x, eb.y, f), y + step + 0.5), SAULO_RUT, 9.0)
		var w: float = ea.y - ea.x
		var k := int(absf(y) / step)
		var h := fmod(absf(sin(float(k) * 12.9898) * 43758.5453), 1.0)
		wc.circle(Vector2(ea.x + 18.0 + h * (w - 36.0), y + h * step), 2.2, PEBBLE)
		wc.circle(Vector2(ea.x + 30.0 + fmod(h * 7.3, 1.0) * (w - 60.0), y + step * 0.5), 1.8, SAULO_EDGE)
		eb = ea
		y -= step
	_draw_culvert(m, wc, vt, vb)
	_draw_fence(m, wc, vt, vb)


# the culvert's parapets: dressed stone, coping on top, a keystone at each end
static func _draw_culvert(m: Node2D, wc: ShapeBatch, vt: float, vb: float) -> void:
	var y0 := CULVERT_Y + CULVERT_HALF_SPAN
	var y1 := CULVERT_Y - CULVERT_HALF_SPAN
	if y1 > vb + 20.0 or y0 < vt - 20.0:
		return
	var e: Vector2 = m.walk_edges(CULVERT_Y)
	for px: float in [e.x, e.y - 14.0]:
		wc.rect(Rect2(px + 4.0, y1 + 4.0, 14.0, y0 - y1), SHADOW)
		wc.rect(Rect2(px, y1, 14.0, y0 - y1), DRYSTONE)
		wc.rect(Rect2(px + 2.0, y1, 10.0, y0 - y1), GRANITE)
		var jy := y1 + 26.0
		while jy < y0:
			wc.line(Vector2(px + 2.0, jy), Vector2(px + 12.0, jy), DRYSTONE_JOINT, 1.2)
			jy += 26.0
		for ky: float in [y1, y0 - 12.0]:
			wc.rect(Rect2(px - 2.0, ky, 18.0, 12.0), DRYSTONE.darkened(0.12))


# the timber post-and-rail fence along the drop: two rails between posts
static func _draw_fence(m: Node2D, wc: ShapeBatch, vt: float, vb: float) -> void:
	var posts := fence_posts(m)
	for i in range(posts.size()):
		var p: Vector2 = posts[i]
		if p.y < vt - FENCE_STEP or p.y > vb + FENCE_STEP:
			continue
		if i + 1 < posts.size():
			var q: Vector2 = posts[i + 1]
			if absf(q.y - p.y) < FENCE_STEP * 1.6:
				wc.line(p + Vector2(-5, 0), q + Vector2(-5, 0), TIMBER, 3.0)
				wc.line(p + Vector2(-1, 0), q + Vector2(-1, 0), TIMBER_LIT, 2.0)
		wc.circle(p + LIGHT * 4.0, 6.0, SHADOW)
		wc.circle(p, 5.5, TIMBER)
		wc.circle(p - LIGHT * 1.5, 3.0, TIMBER_LIT)


# What does not move: the slope and the city below on the west, the cut bank,
# the hillside and the hut on the east, the gully crossing under the track.
static func draw_edge_layer(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	var top: float = maxf(vt, m.GATE_Y - 40.0)
	var bot: float = minf(vb, float(m.START_Y) + 560.0)
	if bot <= top:
		return
	_draw_city(m, b, top, bot)
	_draw_hillside(m, b, top, bot)
	_draw_gully(m, b, top, bot)
	if HUT.position.y < bot + 40.0 and HUT.end.y > top - 40.0:
		_draw_hut(b)


# The city from 400 m up, in the afternoon haze: the Eixample's small
# chamfered blocks in their grid, broken by the Diagonal, a landmark now and
# then, the sea along the far edge, and a slope of scrub and broom falling
# away below the fence. Low contrast on purpose: it is far away, and the
# track is what she plays on.
static func _draw_city(m: Node2D, b: ShapeBatch, top: float, bot: float) -> void:
	b.rect(Rect2(-400.0, top, 1100.0, bot - top), HAZE)
	b.rect(Rect2(-400.0, top, 424.0, bot - top), SEA)
	var gy := floorf(top / 90.0) * 90.0
	while gy < bot:
		var gk := int(absf(gy) / 90.0)
		var gx := 4.0 + float((gk * 7) % 13)
		b.line(Vector2(gx, gy + 20.0), Vector2(gx - 4.0, gy + 44.0), SEA_GLINT, 1.4)
		gy += 90.0
	# the beach, a pale line along the shore
	b.rect(Rect2(24.0, top, 6.0, bot - top), Color(0.84, 0.80, 0.70))
	var cell := 20.0
	var cy := floorf(top / cell) * cell
	while cy < bot:
		var e: Vector2 = m.walk_edges(cy)
		var x_end: float = e.x - 130.0
		var row := int(absf(cy) / cell)
		# a wider street every eighth row, and the Diagonal running across
		if row % 8 != 0:
			var cx := 36.0
			while cx + 14.0 < x_end:
				var col := int(cx / cell)
				var dg := absf(float(col) - (fmod(float(row) * 0.5, 40.0) + 2.0))
				if col % 8 != 0 and dg > 0.6:
					var h := fmod(absf(sin(float(row * 31 + col * 17) * 12.9898) * 43758.5453), 1.0)
					var o := Vector2(cx, cy)
					b.polygon(PackedVector2Array([
						o + Vector2(3, 0), o + Vector2(11, 0), o + Vector2(14, 3), o + Vector2(14, 11),
						o + Vector2(11, 14), o + Vector2(3, 14), o + Vector2(0, 11), o + Vector2(0, 3),
					]), BLOCK if h > 0.3 else BLOCK_SHADE)
					if h > 0.7:
						b.rect(Rect2(o.x + 5.0, o.y + 5.0, 4.0, 4.0), COURTYARD)
				cx += cell
		cy += cell
	# two landmarks in the grid: the basilica's spires and the bullet tower
	for lm: Vector3 in LANDMARKS:
		if lm.y < top - 40.0 or lm.y > bot + 40.0:
			continue
		var at := Vector2(lm.x, lm.y)
		if int(lm.z) == 0:
			b.rect(Rect2(at.x - 14.0, at.y - 22.0, 28.0, 44.0), BLOCK_SHADE)
			for sp: Vector2 in [Vector2(-8, -14), Vector2(8, -14), Vector2(-8, 14), Vector2(8, 14), Vector2(0, 0), Vector2(0, -6)]:
				b.circle(at + sp + LIGHT * 4.0, 4.0, Color(0.30, 0.28, 0.30, 0.35))
				b.circle(at + sp, 3.6, Color(0.86, 0.80, 0.68))
		else:
			b.circle(at + LIGHT * 6.0, 10.0, Color(0.30, 0.28, 0.30, 0.35))
			b.circle(at, 9.0, Color(0.42, 0.52, 0.66))
			b.circle(at - LIGHT * 3.0, 4.0, Color(0.78, 0.38, 0.32))
	# the haze thickening toward the sea
	b.rect(Rect2(24.0, top, 60.0, bot - top), Color(HAZE.r, HAZE.g, HAZE.b, 0.45))
	# the slope below the fence, row by row so it follows the bends
	var sy := floorf(top / 28.0) * 28.0
	while sy < bot:
		var e2: Vector2 = m.walk_edges(sy + 14.0)
		var k := int(absf(sy) / 28.0)
		var h2 := fmod(absf(sin(float(k) * 78.233) * 43758.5453), 1.0)
		var h3 := fmod(h2 * 17.31, 1.0)
		var reach := 110.0 + h2 * 34.0
		b.rect(Rect2(e2.x - reach, sy, reach, 29.0), SCRUB)
		b.circle(Vector2(e2.x - reach + 6.0, sy + 14.0), 13.0 + h2 * 7.0, SCRUB)
		b.circle(Vector2(e2.x - 30.0 - h3 * 70.0, sy + 10.0), 10.0 + h2 * 4.0, SCRUB_DARK)
		if h3 > 0.55:
			var bx: float = e2.x - 22.0 - h2 * 86.0
			b.circle(Vector2(bx, sy + 8.0 + h3 * 12.0), 6.0 + h3 * 2.0, BROOM)
			if h2 > 0.5:
				b.circle(Vector2(bx + 9.0, sy + 16.0), 4.5, BROOM.lightened(0.12))
		sy += 28.0


# The cut bank along the east edge, dry-stone wall in some stretches and bare
# rock in others, then the hillside's scrub and pines out to the frame.
static func _draw_hillside(m: Node2D, b: ShapeBatch, top: float, bot: float) -> void:
	var step := 32.0
	var y := floorf(top / step) * step
	while y < bot:
		var e: Vector2 = m.walk_edges(y + step * 0.5)
		var ea: Vector2 = m.walk_edges(y)
		var eb: Vector2 = m.walk_edges(y + step)
		var k := int(absf(y) / step)
		var h := fmod(absf(sin(float(k) * 45.164) * 43758.5453), 1.0)
		b.polygon(PackedVector2Array([Vector2(ea.y, y), Vector2(1400.0, y), Vector2(1400.0, y + step + 1.0), Vector2(eb.y, y + step + 1.0)]), SCRUB)
		var walled := int(absf(y) / 640.0) % 2 == 0
		var bank := 18.0 if walled else 22.0 + h * 10.0
		b.polygon(PackedVector2Array([Vector2(ea.y, y), Vector2(ea.y + bank, y), Vector2(eb.y + bank, y + step + 1.0), Vector2(eb.y, y + step + 1.0)]), DRYSTONE if walled else ROCK_CUT)
		if walled:
			var off := 0.0 if k % 2 == 0 else 9.0
			b.line(Vector2(ea.y, y), Vector2(ea.y + 18.0, y), DRYSTONE_JOINT, 1.2)
			b.line(Vector2(e.y + 4.0 + off, y + 2.0), Vector2(e.y + 4.0 + off, y + step * 0.5), DRYSTONE_JOINT, 1.0)
			b.line(Vector2(e.y + 13.0 - off, y + step * 0.5), Vector2(e.y + 13.0 - off, y + step - 2.0), DRYSTONE_JOINT, 1.0)
		else:
			b.rect(Rect2(e.y + 14.0 + h * 10.0, y + 4.0, 10.0, step - 8.0), ROCK_DARK)
		# scrub and broom on the bank, crowns of the pines above it
		b.circle(Vector2(e.y + 50.0 + h * 30.0, y + 16.0), 16.0 + h * 6.0, SCRUB_DARK)
		if k % 4 == 1:
			b.circle(Vector2(e.y + 70.0 + h * 40.0, y + 10.0), 8.0, BROOM)
		for c in range(4):
			var hc := fmod(absf(sin(float(k * 5 + c) * 91.7) * 43758.5453), 1.0)
			if hc < 0.45:
				continue
			var at := Vector2(e.y + 110.0 + float(c) * 70.0 + hc * 24.0, y + hc * step)
			var r := 22.0 + hc * 12.0
			b.circle(at + LIGHT * 8.0, r, Color(0.10, 0.16, 0.10, 0.5))
			b.circle(at, r, Color(0.20, 0.32, 0.18))
			b.circle(at - LIGHT * r * 0.3, r * 0.45, Color(0.28, 0.40, 0.22))
		y += step


# The gully: a winding bed of earth and pale stones down the hill to the
# culvert's mouth, and on down the slope below the fence, scrub along its
# banks. A trickle at each mouth.
static func _draw_gully(m: Node2D, b: ShapeBatch, top: float, bot: float) -> void:
	if CULVERT_Y - 60.0 > bot or CULVERT_Y + 60.0 < top:
		return
	var e: Vector2 = m.walk_edges(CULVERT_Y)
	for side: float in [-1.0, 1.0]:
		var x0: float = e.y + 16.0 if side > 0.0 else e.x - 16.0
		var run := 520.0 if side > 0.0 else 220.0
		var d := 0.0
		var i := 0
		while d < run:
			var x := x0 + side * d
			var wob := sin(d * 0.021 + side) * 12.0
			var half := 16.0 + d * 0.025
			var h := fmod(absf(sin(float(i) * 3.7 + side * 1.3) * 43758.5453), 1.0)
			b.circle(Vector2(x, CULVERT_Y + wob - half - 4.0), 9.0 + h * 5.0, SCRUB_DARK)
			b.circle(Vector2(x, CULVERT_Y + wob + half + 4.0), 9.0 + (1.0 - h) * 5.0, SCRUB_DARK)
			b.circle(Vector2(x, CULVERT_Y + wob), half, Color(0.45, 0.40, 0.33))
			if i % 2 == 0:
				b.circle(Vector2(x + h * 6.0, CULVERT_Y + wob + (h - 0.5) * half * 0.8), 2.5 + h * 3.0, Color(0.66, 0.62, 0.55))
			d += 9.0
			i += 1
		# the culvert's dark mouth in the bank, and a trickle at its foot
		var mx: float = e.y + 16.0 if side > 0.0 else e.x - 30.0
		b.rect(Rect2(mx, CULVERT_Y - 14.0, 14.0, 28.0), Color(0.12, 0.12, 0.12))
		b.rect(Rect2(mx - 2.0, CULVERT_Y - 17.0, 18.0, 4.0), DRYSTONE)
		b.line(Vector2(x0 + side * 14.0, CULVERT_Y), Vector2(x0 + side * 70.0, CULVERT_Y + sin(70.0 * 0.021 + side) * 12.0), WATER, 2.5)


# The water main's inspection hut, set into the bank: a hipped roof of
# terracotta tiles seen from above, its iron door to the track, the plaque.
static func _draw_hut(b: ShapeBatch) -> void:
	var r := HUT
	b.rect(Rect2(r.position + LIGHT * 10.0, r.size), SHADOW)
	b.rect(r, DRYSTONE)
	var c := r.get_center()
	var inner := r.grow(-8.0)
	b.polygon(PackedVector2Array([inner.position, Vector2(inner.end.x, inner.position.y), Vector2(c.x + 20.0, c.y), Vector2(c.x - 20.0, c.y)]), ROOF_TILE)
	b.polygon(PackedVector2Array([Vector2(inner.position.x, inner.end.y), inner.end, Vector2(c.x + 20.0, c.y), Vector2(c.x - 20.0, c.y)]), ROOF_TILE.darkened(0.15))
	b.polygon(PackedVector2Array([inner.position, Vector2(c.x - 20.0, c.y), Vector2(inner.position.x, inner.end.y)]), ROOF_TILE.lightened(0.10))
	b.polygon(PackedVector2Array([Vector2(inner.end.x, inner.position.y), inner.end, Vector2(c.x + 20.0, c.y)]), ROOF_TILE.darkened(0.25))
	b.line(Vector2(c.x - 20.0, c.y), Vector2(c.x + 20.0, c.y), ROOF_TILE.lightened(0.25), 2.0)
	# the iron door, on the track side, and the company's plaque beside it
	b.rect(Rect2(r.position.x - 4.0, c.y - 16.0, 6.0, 32.0), IRON)
	b.rect(Rect2(r.position.x - 3.0, c.y - 30.0, 4.0, 10.0), Color(0.62, 0.52, 0.30))


# a stone marker on the water main for a hydrant: a squat granite post with
# its iron plate, the progress ring while she marks it
static func draw_bollard(m: Node2D, wc: ShapeBatch, h) -> void:
	var hp: Vector2 = h.pos
	m.cast_shadow(wc, hp, 8.0, 18.0)
	var stone := GRANITE if not h.done else GRANITE.darkened(0.18)
	wc.rect(Rect2(hp.x - 8.0, hp.y - 8.0, 16.0, 16.0), stone.darkened(0.25))
	wc.rect(Rect2(hp.x - 7.0, hp.y - 7.0, 14.0, 14.0), stone)
	wc.rect(Rect2(hp.x - 7.0, hp.y - 7.0, 5.0, 14.0), stone.lightened(0.10))
	wc.rect(Rect2(hp.x - 4.0, hp.y - 3.0, 8.0, 6.0), IRON)
	if not h.done and h.progress > 0.0:
		wc.draw_arc(hp, 18.0, -PI / 2.0, -PI / 2.0 + TAU * h.progress / 0.8, 20, Color(1, 0.95, 0.7), 3.0)


# a dropped snack: half an energy bar in its torn foil
static func draw_snack(m: Node2D, wc: ShapeBatch, kp: Vector2) -> void:
	m.contact_shadow(wc, kp, 10.0, 3.0, 0.20)
	wc.polygon(PackedVector2Array([kp + Vector2(-11, -4), kp + Vector2(4, -6), kp + Vector2(8, 4), kp + Vector2(-9, 5)]), Color(0.82, 0.30, 0.22))
	wc.rect(Rect2(kp.x - 2.0, kp.y - 4.0, 12.0, 8.0), Color(0.62, 0.44, 0.26))
	wc.circle(kp + Vector2(10.0, 0.0), 4.0, Color(0.62, 0.44, 0.26))
	wc.line(kp + Vector2(-9, -2), kp + Vector2(2, -4), Color(0.95, 0.90, 0.86, 0.8), 1.2)


# the font in the cut bank: a dressed stone back, the bronze spout, the trough
static func draw_fountain(m: Node2D, f: Vector2) -> void:
	var c: ShapeBatch = m._wc
	c.rect(Rect2(f.x - 18.0 + 5.0, f.y - 14.0 + 8.0, 40.0, 30.0), SHADOW)
	c.rect(Rect2(f.x + 6.0, f.y - 22.0, 16.0, 44.0), DRYSTONE)
	c.rect(Rect2(f.x + 8.0, f.y - 20.0, 12.0, 40.0), GRANITE)
	c.rect(Rect2(f.x - 18.0, f.y - 12.0, 26.0, 24.0), DRYSTONE.darkened(0.1))
	c.rect(Rect2(f.x - 15.0, f.y - 9.0, 20.0, 18.0), WATER)
	c.rect(Rect2(f.x - 13.0, f.y - 7.0, 8.0, 6.0), WATER.lightened(0.25))
	c.line(Vector2(f.x + 8.0, f.y), Vector2(f.x, f.y), Color(0.62, 0.46, 0.22), 3.0)
	c.line(Vector2(f.x, f.y), Vector2(f.x - 4.0, f.y + 1.0), Color(0.82, 0.92, 0.96, 0.8), 2.0)


# the trail runner's banana on the mirador bench, until she has it
static func draw_live(m: Node2D, wc: ShapeBatch, vt: float, vb: float) -> void:
	if m.prize_taken or PRIZE.y < vt - 30.0 or PRIZE.y > vb + 30.0:
		return
	var pts := PackedVector2Array()
	for k in range(7):
		var a := PI * 0.15 + PI * 0.7 * float(k) / 6.0
		pts.append(PRIZE + Vector2(cos(a), sin(a) - 0.6) * 10.0)
	for k in range(pts.size() - 1):
		wc.line(pts[k], pts[k + 1], Color(0.96, 0.84, 0.26), 4.0)
	wc.circle(pts[0], 1.6, Color(0.36, 0.28, 0.16))
