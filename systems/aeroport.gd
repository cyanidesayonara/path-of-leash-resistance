class_name Aeroport
extends RefCounted

# WALK: L'AEROPORT. Barcelona-El Prat Josep Tarradellas Airport (Terminal 1).
# A soaring modern international terminal concourse: polished high-gloss tile
# floors, central moving walkway (travelator) carrying travelers north,
# panoramic floor-to-ceiling glass curtain walls overlooking the runway and
# apron with parked jetliners, boarding gates B20 through B30 with overhead LED
# flight information displays, duty-free islands, and baggage carousels.
#
# On the way out:
# - Moving walkway: +120 px/s forward boost outbound, resists inbound.
# - The Gate Rush live event: an airport chime (ding-dong-ding) and PA announcement
#   ("LAST CALL FOR GATE B30!") sparks a hurried sprint of business travelers with
#   rolling suitcases crossing the concourse. Steer clear to dodge.
# - Baggage carousel: rotating loop with suitcases and pet crate; bark for +2.
# - Unique prize: grab the duty-free giant chocolate box.
#
# On the way home:
# - The airport security squad (entities/aeroport_threat.gd) chases the pair
#   down the concourse in a line, crate and net and whistle out, booting
#   confiscated suitcases up the tiles at them.
# - Wedges into the duty-free perfume pyramid (-3400) and tangles in the
#   gate B22 queue's tape (-1900, checkpoint): the two respites.
#
# Past the gate the bridge ends in the jet's cabin, which is the off-leash
# space (systems/aeroport_cabin.gd). The picture is systems/aeroport_art.gd.

const ShapeBatch := preload("res://systems/shape_batch.gd")
const AeroportThreat := preload("res://entities/aeroport_threat.gd")
const Surfaces := preload("res://world/surfaces.gd")
const EventFeed := preload("res://hud/event_feed.gd")

const HALF := 260.0
const WALL_L := 380.0
const WALL_R := 900.0

const PRIZE := Vector2(780.0, -4450.0)
const PRIZE_TEXT := "snatch the giant duty-free chocolate box"

# THE PLACES, by depth
const ENTRANCE_Y := -350.0            # security archway into terminal
const DUTY_FREE_Y := -680.0           # duty-free perfume & chocolate islands
const TRAVELATOR_START_Y := -900.0    # travelator begins
const TRAVELATOR_END_Y := -4000.0     # travelator ends
const GATE_RUSH_Y := -4120.0          # Gate B30 crossing, just past the walkway's far end
const CAROUSEL_Y := -4500.0           # baggage reclaim loop
const BRIDGE_Y := -4640.0             # the pier ends; the jet bridge out to the cabin

# Central moving walkway geometry
const WALKWAY_RECT := Rect2(570.0, -4000.0, 140.0, 3100.0)
# The walkway's sides, as in a real terminal: a glass balustrade with a rubber
# handrail along each edge, solid for anyone walking, open only at the two
# ends. The leash lies over the handrail (no rope rect).
const BALUSTRADE_W := 12.0

# Respite obstacle locations (home_chase.AEROPORT_BANDS)
const PERFUME_JAM_Y := -3400.0
const STANCHION_JAM_Y := -1900.0

# Solids: duty-free islands, gate counters, pillars, carousel
# in the west lane: it stood on the travelator, an invisible wall under the belt
const PERFUME_ISLAND := Rect2(445.0, -3470.0, 90.0, 56.0)
const CHOCOLATE_ISLAND := Rect2(720.0, -680.0, 80.0, 50.0)
const CAROUSEL_RECT := Rect2(420.0, -4580.0, 110.0, 160.0)

# Gate check-in desks along the east wall
const GATE_DESKS: Array[Rect2] = [
	Rect2(850.0, -1120.0, 46.0, 60.0),
	Rect2(850.0, -1720.0, 46.0, 60.0),
	Rect2(850.0, -2520.0, 46.0, 60.0),
	Rect2(850.0, -3120.0, 46.0, 60.0),
	Rect2(850.0, -3720.0, 46.0, 60.0),
	Rect2(850.0, -4320.0, 46.0, 60.0),
]

# Structural steel pillars (pairs down concourse, wrap poles)
const POSTS: Array[Vector2] = [
	Vector2(440.0, -600.0), Vector2(840.0, -600.0),
	Vector2(440.0, -1200.0), Vector2(840.0, -1200.0),
	Vector2(440.0, -1800.0), Vector2(840.0, -1800.0),
	Vector2(440.0, -2400.0), Vector2(840.0, -2400.0),
	Vector2(440.0, -3000.0), Vector2(840.0, -3000.0),
	Vector2(440.0, -3600.0), Vector2(840.0, -3600.0),
	Vector2(440.0, -4200.0), Vector2(840.0, -4200.0),
]

# THE GATE RUSH LIVE EVENT
# the rush fires while your human is this far short of the crossing line, so
# the runners sweep it as they arrive: a dog can plant and hold them back
const RUSH_LEAD := 200.0
const RUSH_HIT_HALF := 30.0
const RUSH_WARN_SECS := 0.85
const RUSH_CROSS_SECS := 2.2
const RUSH_COUNT := 4

# Terminal color palette
const TILE_LIGHT := Color(0.88, 0.90, 0.93)
const TILE_DARK := Color(0.82, 0.84, 0.88)
const TILE_GRID := Color(0.76, 0.78, 0.82)
const GLASS_FRAME := Color(0.35, 0.38, 0.44)
const GLASS_PANE := Color(0.68, 0.82, 0.90, 0.60)
const RUNWAY_TARMAC := Color(0.32, 0.34, 0.36)
const RUNWAY_LINE := Color(0.95, 0.82, 0.20)
const PLANE_WHITE := Color(0.96, 0.97, 0.98)
const PLANE_BLUE := Color(0.12, 0.28, 0.58)
const PILLAR_STEEL := Color(0.50, 0.54, 0.60)
const PILLAR_BASE := Color(0.30, 0.33, 0.38)
const TRAVELATOR_STEEL := Color(0.42, 0.44, 0.48)
const TRAVELATOR_COMB := Color(0.94, 0.78, 0.16)
const TRAVELATOR_HANDRAIL := Color(0.12, 0.12, 0.14)
const BALUSTRADE_GLASS := Color(0.72, 0.84, 0.90, 0.55)
const BALUSTRADE_SKIRT := Color(0.58, 0.60, 0.64)
const SIGN_BLUE := Color(0.10, 0.30, 0.65)
const SIGN_YELLOW := Color(0.96, 0.84, 0.22)
const CAROUSEL_RUBBER := Color(0.16, 0.16, 0.18)
const CAROUSEL_TRIM := Color(0.70, 0.72, 0.76)
const PERFUME_GLASS := Color(0.85, 0.45, 0.75, 0.70)
const PERFUME_GOLD := Color(0.92, 0.78, 0.28)
const CHOCOLATE_GOLD := Color(0.88, 0.72, 0.20)


static func build(m: Node2D) -> Array:
	m.gate_text = "LA CABINA"
	# where the squad comes unstuck on the way home (home_chase.AEROPORT_BANDS): the
	# perfume pyramid in the west lane, then the tape of the gate queue
	m.chase_jams.clear()
	m.chase_jams.append(Vector2(PERFUME_ISLAND.get_center().x, PERFUME_JAM_Y))
	m.chase_jams.append(Vector2(640.0, STANCHION_JAM_Y))
	m.poles.clear()
	for p: Vector2 in POSTS:
		m.poles.append(p)
	m.deco_pole_count = m.poles.size()

	# Conveyor zone (moving walkway)
	m.conveyor_zone = WALKWAY_RECT
	m.conveyor_dir = Vector2(0, -1)

	# Benches: airport gate seating clusters
	m.benches = Array([
		Vector2(780.0, -1200.0), Vector2(780.0, -1800.0),
		Vector2(780.0, -2600.0), Vector2(780.0, -3200.0),
		Vector2(780.0, -3800.0), Vector2(780.0, -4400.0),
		Vector2(460.0, -1500.0), Vector2(460.0, -2700.0),
		Vector2(460.0, -3900.0),
	], TYPE_VECTOR2, &"", null)

	# Bins: sleek stainless steel recycling bins
	m.bins = Array([
		Vector2(WALL_L + 25.0, -800.0), Vector2(WALL_R - 25.0, -1500.0),
		Vector2(WALL_L + 25.0, -2200.0), Vector2(WALL_R - 25.0, -2900.0),
		Vector2(WALL_L + 25.0, -3600.0), Vector2(WALL_R - 25.0, -4300.0),
	], TYPE_VECTOR2, &"", null)

	# Water drinking fountains
	m.fountains = Array([
		Vector2(WALL_R - 35.0, -2100.0), Vector2(WALL_L + 35.0, -3300.0)
	], TYPE_VECTOR2, &"", null)

	# Wet-floor caution signs at travelator entries and concourse
	m.cone_spots = Array([
		Vector2(520.0, -880.0), Vector2(760.0, -880.0),
		Vector2(520.0, -4020.0), Vector2(760.0, -4020.0),
	], TYPE_VECTOR2, &"", null)

	# Hydrants & kebabs / snacks
	var hydrants: Array[Vector2] = [
		Vector2(WALL_L + 30.0, -500.0),
		Vector2(WALL_R - 30.0, -1400.0),
		Vector2(WALL_L + 30.0, -2300.0),
		Vector2(WALL_R - 30.0, -3300.0),
		Vector2(WALL_L + 30.0, -4100.0),
		Vector2(WALL_R - 30.0, -4700.0),
	]
	var kebabs: Array[Vector2] = [
		Vector2(720.0, -710.0),   # dropped duty-free chocolate snack
		Vector2(760.0, -2450.0),  # dropped pretzel/croissant by gate
		Vector2(450.0, -3150.0),  # dropped sandwich crumb by window
	]
	return [hydrants, kebabs]


static func balustrades() -> Array[Rect2]:
	var z := WALKWAY_RECT
	var h := BALUSTRADE_W * 0.5
	return [Rect2(z.position.x - h, z.position.y, BALUSTRADE_W, z.size.y),
		Rect2(z.end.x - h, z.position.y, BALUSTRADE_W, z.size.y)]


static func solids(_m: Node2D) -> Array[Rect2]:
	var out: Array[Rect2] = balustrades()
	out.append(PERFUME_ISLAND)
	out.append(CHOCOLATE_ISLAND)
	out.append(CAROUSEL_RECT)
	out.append_array(GATE_DESKS)
	return out


static func wrap_rects() -> Array[Rect2]:
	var out: Array[Rect2] = []
	out.append(PERFUME_ISLAND)
	out.append(CHOCOLATE_ISLAND)
	out.append(CAROUSEL_RECT)
	out.append_array(GATE_DESKS)
	return out


# terrazzo, then the bridge's rubber, then the cabin's carpet: none of it lawn
static func surface(_m: Node2D, _pos: Vector2) -> int:
	return Surfaces.S.PAVEMENT


static func tick(m: Node2D, delta: float) -> void:
	if m.lvl != "aeroport":
		return
	_tick_gate_rush(m, delta)
	_tick_carousel(m)


static func on_bark(m: Node2D, pos: Vector2 = Vector2.ZERO) -> void:
	if m.lvl != "aeroport":
		return
	var bp: Vector2 = pos if pos != Vector2.ZERO else m.dog.global_position
	# Bark at baggage carousel
	if not m.aeroport_carousel_barked and CAROUSEL_RECT.grow(80.0).has_point(bp):
		m.aeroport_carousel_barked = true
		m.combo.add("CAROUSEL BARK", 2)
		m.award_points(2, "carousel bark! +2")


static func _tick_gate_rush(m: Node2D, delta: float) -> void:
	# Only triggers on the way out
	if m.phase != "out":
		return
	var rush: Dictionary = m.aeroport_rush
	var state: String = rush.get("state", "waiting")
	var hp: Vector2 = m.human.global_position

	match state:
		"waiting":
			if hp.y < GATE_RUSH_Y + RUSH_LEAD:
				rush["state"] = "warn"
				rush["t"] = 0.0
				rush["hit"] = false
				Sfx.play("chime", 1.0)
				m.feed.say("LAST CALL FOR GATE B30!", EventFeed.Tone.LOUD)
				m.float_text(Vector2(640.0, GATE_RUSH_Y - 40.0), "Bing bong!", Color(1.0, 0.9, 0.3), m.POP_SAY)
		"warn":
			rush["t"] = float(rush.get("t", 0.0)) + delta
			if float(rush.t) >= RUSH_WARN_SECS:
				rush["state"] = "running"
				rush["t"] = 0.0
		"running":
			rush["t"] = float(rush.get("t", 0.0)) + delta
			var progress: float = clampf(float(rush.t) / RUSH_CROSS_SECS, 0.0, 1.0)
			# the runners sweep the line from the baggage hall to the gate; the
			# group spans the stagger drawn in _draw_gate_rush_live
			var lead_x: float = lerpf(390.0, 870.0, progress)
			var tail_x: float = lerpf(390.0, 870.0, clampf(progress - 0.08 * float(RUSH_COUNT - 1), 0.0, 1.0))
			var on_line := absf(hp.y - GATE_RUSH_Y) <= RUSH_HIT_HALF
			if not bool(rush.get("hit", false)) and on_line and hp.x >= tail_x - 20.0 and hp.x <= lead_x + 20.0:
				rush["hit"] = true
				m.human.patience = maxf(0.0, m.human.patience - m.LIVE_EVENT_BUMP_PATIENCE)
				m.human.bumped(Vector2.RIGHT)
				Sfx.play("bump", 1.1, -3.0)
				m.float_text(hp + Vector2(0, -32), "Excuse me! Running late!", Color(1.0, 0.86, 0.80), m.POP_SAY)
			if progress >= 1.0:
				rush["state"] = "done"
				if not bool(rush.get("hit", false)) and not m.aeroport_rush_dodged:
					m.aeroport_rush_dodged = true
					m.combo.add("GATE RUSH", 3)
					m.award_points(3, "gate rush! +3")


static func _tick_carousel(_m: Node2D) -> void:
	pass


# --- WORLD DRAWING ---
# The picture is systems/aeroport_art.gd (the terminal) and
# systems/aeroport_cabin.gd (the jet). What does not move is on the cached
# edge, ground, overhead and freedom canvases; the world pass draws only the
# walkway's belt, the carousel's bags, the apron's traffic and the rush.

# both sides of the concourse, on the edge layer
static func draw_edge_layer(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	AeroportArt.draw_edge(m, b, vt, vb)


# the concourse floor and what stands on it, on the ground layer
static func draw_cross_section(m: Node2D, wc: ShapeBatch, _top: float, bottom: float, ctop: float, vt: float, vb: float) -> void:
	AeroportArt.draw_floor(m, wc, vt, vb, ctop, bottom)


static func draw_scenery(m: Node2D, wc: ShapeBatch, vt: float, vb: float) -> void:
	if m.lvl != "aeroport":
		return
	AeroportArt.draw_apron_live(wc, vt, vb)
	AeroportArt.draw_bridges(wc, vt, vb)
	_draw_travelator(wc, vt, vb)
	_draw_carousel_bags(wc, vt, vb)


static func _draw_travelator(b: ShapeBatch, vt: float, vb: float) -> void:
	var z: Rect2 = WALKWAY_RECT
	if z.end.y < vt or z.position.y > vb:
		return
	var top := maxf(z.position.y, vt)
	var bot := minf(z.end.y, vb)
	var t: float = AnimClock.msec() / 1000.0

	# the belt: dark grooved pallets, their seams and a yellow edge strip
	# sliding up the hall at the speed it carries her
	b.rect(Rect2(z.position.x, top, z.size.x, bot - top), TRAVELATOR_STEEL)
	var gx := z.position.x + 16.0
	while gx < z.end.x - 10.0:
		b.rect(Rect2(gx, top, 2.0, bot - top), Color(0.34, 0.36, 0.40))
		gx += 9.0
	var scroll: float = fmod(t * 120.0, 48.0)
	var py := floorf((top + scroll) / 48.0) * 48.0 - scroll
	while py <= bot:
		if py >= top:
			b.rect(Rect2(z.position.x + 8.0, py, z.size.x - 16.0, 2.0), Color(0.22, 0.23, 0.26))
			b.rect(Rect2(z.position.x + 8.0, py + 2.0, z.size.x - 16.0, 1.0), Color(0.56, 0.58, 0.62))
		py += 48.0
	var chev: float = fmod(t * 120.0, 240.0)
	var cy := floorf((top + chev) / 240.0) * 240.0 - chev
	while cy <= bot + 30.0:
		if cy >= top + 24.0 and cy <= bot - 10.0:
			var cx := z.get_center().x
			b.quad(Vector2(cx, cy - 16.0), Vector2(cx + 26.0, cy + 6.0), Vector2(cx + 26.0, cy + 16.0), Vector2(cx, cy - 6.0), Color(TRAVELATOR_COMB, 0.75))
			b.quad(Vector2(cx, cy - 16.0), Vector2(cx, cy - 6.0), Vector2(cx - 26.0, cy + 16.0), Vector2(cx - 26.0, cy + 6.0), Color(TRAVELATOR_COMB, 0.75))
		cy += 240.0
	for ex: float in [z.position.x + 8.0, z.end.x - 12.0]:
		b.rect(Rect2(ex, top, 4.0, bot - top), Color(TRAVELATOR_COMB, 0.9))

	# the comb plates at both ends: steel teeth, a yellow line to step over
	for ey: float in [z.position.y, z.end.y - 26.0]:
		if ey + 26.0 < vt or ey > vb:
			continue
		b.rect(Rect2(z.position.x, ey, z.size.x, 26.0), Color(0.70, 0.72, 0.76))
		var tx := z.position.x + 10.0
		var teeth_y := ey + 18.0 if ey == z.position.y else ey
		while tx < z.end.x - 8.0:
			b.rect(Rect2(tx, teeth_y, 3.0, 8.0), Color(0.46, 0.48, 0.52))
			tx += 6.0
		b.rect(Rect2(z.position.x, ey + 10.0, z.size.x, 5.0), TRAVELATOR_COMB)

	# The sides: a steel skirt at the floor, the glass panel standing on it
	# (seen from above as a pale strip with its joints), and the black rubber
	# handrail along the top, rounded off in a newel at each end. The handrail
	# moves with the belt: a pale seam slides along it.
	for r: Rect2 in balustrades():
		var seen := Rect2(r.position.x, top, r.size.x, bot - top)
		b.rect(Rect2(seen.position + Vector2(4.0, 0.0), seen.size), Color(0.0, 0.0, 0.0, 0.16))
		b.rect(seen, BALUSTRADE_SKIRT)
		b.rect(seen.grow_individual(-2.0, 0.0, -2.0, 0.0), BALUSTRADE_GLASS)
		var jy := floorf(top / 90.0) * 90.0
		while jy < bot:
			if jy > top and jy > r.position.y + 30.0 and jy < r.end.y - 30.0:
				b.rect(Rect2(seen.position.x + 1.0, jy, seen.size.x - 2.0, 2.0), BALUSTRADE_SKIRT)
			jy += 90.0
		var cxr := r.get_center().x
		b.rect(Rect2(cxr - 3.0, top, 6.0, bot - top), TRAVELATOR_HANDRAIL)
		b.rect(Rect2(cxr - 3.0, top, 2.0, bot - top), Color(0.30, 0.30, 0.32))
		var hs: float = fmod(t * 120.0, 160.0)
		var hy := floorf((top + hs) / 160.0) * 160.0 - hs
		while hy <= bot:
			if hy >= top:
				b.rect(Rect2(cxr - 3.0, hy, 6.0, 3.0), Color(0.46, 0.46, 0.50))
			hy += 160.0
		for ey: float in [r.position.y, r.end.y]:
			if ey >= vt - 12.0 and ey <= vb + 12.0:
				b.circle(Vector2(cxr, ey), 8.0, TRAVELATOR_HANDRAIL)
				b.circle(Vector2(cxr - 2.0, ey - 2.0), 3.0, Color(0.30, 0.30, 0.32))


# what rides the carousel: cases with their straps and tags, a guitar, and
# the pet crate with somebody furious in it (the one worth a bark)
static func _draw_carousel_bags(b: ShapeBatch, vt: float, vb: float) -> void:
	var r: Rect2 = CAROUSEL_RECT
	if r.end.y < vt - 20.0 or r.position.y > vb + 20.0:
		return
	var t: float = AnimClock.msec() / 1000.0 * 26.0
	for i in range(7):
		var deg := fmod(t + float(i) * 51.0, 360.0)
		var p := _carousel_pos(r, deg)
		var ahead := _carousel_pos(r, deg + 4.0)
		var dir := (ahead - p).angle()
		var f := Vector2.from_angle(dir)
		var s := f.orthogonal()
		if i == 3:
			# the crate: grey shell, a wire door, two eyes and a paw through it
			AeroportArt.box(b, p + AeroportArt.LIGHT * 2.0, dir, 12.0, 9.0, Color(0.05, 0.05, 0.08, 0.3))
			AeroportArt.box(b, p, dir, 12.0, 9.0, Color(0.56, 0.58, 0.62))
			AeroportArt.box(b, p, dir, 10.0, 7.0, Color(0.74, 0.76, 0.80))
			AeroportArt.box(b, p + f * 8.0, dir, 3.0, 6.0, Color(0.14, 0.14, 0.16))
			for k in range(3):
				b.line(p + f * 5.5 + s * (float(k) - 1.0) * 4.0, p + f * 11.0 + s * (float(k) - 1.0) * 4.0, Color(0.80, 0.82, 0.86), 1.0)
			b.circle(p + f * 8.0 - s * 2.4, 1.4, Color(0.98, 0.90, 0.30))
			b.circle(p + f * 8.0 + s * 2.4, 1.4, Color(0.98, 0.90, 0.30))
			b.circle(p + f * 13.0 + s * 3.0, 2.0, Color(0.90, 0.56, 0.24))
		elif i == 5:
			# a guitar case
			b.circle(p - f * 4.0, 7.0, Color(0.14, 0.12, 0.12))
			b.circle(p + f * 4.0, 5.0, Color(0.14, 0.12, 0.12))
			AeroportArt.box(b, p + f * 12.0, dir, 7.0, 2.4, Color(0.14, 0.12, 0.12))
			b.circle(p - f * 4.0, 2.0, Color(0.80, 0.70, 0.30))
		else:
			var col := AeroportArt.pick(AeroportArt.BAGS, i * 3 + 1)
			var hl := 11.0 + AeroportArt.h(i) * 3.0
			AeroportArt.box(b, p + AeroportArt.LIGHT * 2.0, dir, hl, 7.5, Color(0.05, 0.05, 0.08, 0.3))
			AeroportArt.box(b, p, dir, hl, 7.5, col.darkened(0.25))
			AeroportArt.box(b, p, dir, hl - 1.5, 6.0, col)
			b.line(p - s * 6.0 + f * 3.0, p + s * 6.0 + f * 3.0, col.darkened(0.35), 1.6)
			b.line(p - s * 6.0 - f * 4.0, p + s * 6.0 - f * 4.0, col.lightened(0.3), 1.2)
			AeroportArt.box(b, p + f * (hl + 1.5), dir, 1.5, 3.5, Color(0.12, 0.12, 0.14))
			# the white tag, flapping off the handle
			AeroportArt.box(b, p + f * (hl + 4.0) + s * 4.0, dir + 0.6, 3.5, 1.6, Color(0.98, 0.98, 0.95))


static func _carousel_pos(r: Rect2, angle_deg: float) -> Vector2:
	var rad: float = deg_to_rad(angle_deg)
	var c := r.get_center()
	var rx: float = r.size.x * 0.5 - 16.0
	var ry: float = r.size.y * 0.5 - 16.0
	return c + Vector2(cos(rad) * rx, sin(rad) * ry)


static func draw_live(m: Node2D, wc: ShapeBatch, vt: float, vb: float) -> void:
	if m.lvl != "aeroport":
		return
	_draw_gate_rush_live(m, wc, vt, vb)


# The rush: during the warning the crossing lights up, a row of amber
# chevrons chasing across it the way they will run; then the runners, each a
# traveller at full tilt with a case bouncing behind. The group's lead and
# tail are the ones _tick_gate_rush sweeps the line with.
static func _draw_gate_rush_live(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	var rush: Dictionary = m.aeroport_rush
	var state: String = rush.get("state", "waiting")
	if state != "running" and state != "warn":
		return
	if GATE_RUSH_Y < vt - 60.0 or GATE_RUSH_Y > vb + 60.0:
		return
	var t: float = AnimClock.msec() / 1000.0
	var lane := Rect2(390.0, GATE_RUSH_Y - RUSH_HIT_HALF, 480.0, RUSH_HIT_HALF * 2.0)
	if state == "warn":
		var k: float = clampf(float(rush.get("t", 0.0)) / RUSH_WARN_SECS, 0.0, 1.0)
		var pulse := 0.5 + 0.5 * sin(t * 16.0)
		b.band(PackedVector2Array([Vector2(lane.position.x, lane.position.y - 14.0), Vector2(lane.end.x, lane.position.y - 14.0),
			Vector2(lane.position.x, lane.get_center().y), Vector2(lane.end.x, lane.get_center().y),
			Vector2(lane.position.x, lane.end.y + 14.0), Vector2(lane.end.x, lane.end.y + 14.0)]), 2,
			Color(1.0, 0.76, 0.16, 0.30 + 0.16 * pulse), PackedFloat32Array([0.0, 1.0, 0.0]))
		for i in range(12):
			var cx := lane.position.x + 20.0 + fposmod(float(i) * 40.0 + t * 160.0, lane.size.x - 40.0)
			var a := 0.75 * k
			b.quad(Vector2(cx + 10.0, GATE_RUSH_Y), Vector2(cx - 2.0, GATE_RUSH_Y - 12.0), Vector2(cx - 8.0, GATE_RUSH_Y - 12.0), Vector2(cx + 4.0, GATE_RUSH_Y), Color(1.0, 0.80, 0.20, a))
			b.quad(Vector2(cx + 10.0, GATE_RUSH_Y), Vector2(cx + 4.0, GATE_RUSH_Y), Vector2(cx - 8.0, GATE_RUSH_Y + 12.0), Vector2(cx - 2.0, GATE_RUSH_Y + 12.0), Color(1.0, 0.80, 0.20, a))
		return
	var progress: float = clampf(float(rush.get("t", 0.0)) / RUSH_CROSS_SECS, 0.0, 1.0)
	for k in range(RUSH_COUNT - 1, -1, -1):
		var p: float = clampf(progress - float(k) * 0.08, 0.0, 1.0)
		if p <= 0.0 or p >= 1.0:
			continue
		var px: float = lerpf(390.0, 870.0, p)
		var py: float = GATE_RUSH_Y + float((k % 2) * 2 - 1) * 16.0 + sin(t * 15.0 + float(k)) * 1.5
		AeroportArt.runner(b, Vector2(px, py), 0.0, k, t)


static func draw_overhead(m: Node2D, c: CanvasItem) -> void:
	if m.lvl != "aeroport":
		return
	AeroportArt.draw_overhead(m, c)


# --- the walk's furniture, as a terminal has it ------------------------------

# a roof column: a concrete drum on a steel shoe, with the soft shadow of
# something that goes all the way up
static func draw_column(m: Node2D, wc: ShapeBatch, p: Vector2) -> void:
	wc.glow(p + m.LIGHT * 16.0, 40.0, Color(0.05, 0.05, 0.08, 0.26), 0.3)
	wc.circle(p, 19.0, PILLAR_BASE)
	wc.circle(p, 16.5, Color(0.44, 0.47, 0.52))
	wc.circle(p, 14.0, Color(0.80, 0.80, 0.79))
	wc.circle(p - m.LIGHT * 3.5, 9.5, Color(0.90, 0.90, 0.89))
	# the wayfinding band painted round it
	wc.circle(p + Vector2(0.0, 9.0), 3.2, AeroportArt.SIGN_YELLOW)


# the columns hold up a roof, not a lantern
static func is_lamp(_m: Node2D, _p: Vector2) -> bool:
	return false


# a row of four seats on a beam, where a park would have a bench
static func draw_bench(m: Node2D, wc: ShapeBatch, p: Vector2) -> void:
	m.box_shadow(wc, Rect2(p.x - 9.0, p.y - 25.0, 18.0, 50.0), 4.0, 7.0)
	wc.rect(Rect2(p.x + 6.0, p.y - 26.0, 3.0, 52.0), AeroportArt.STEEL)
	for k in range(4):
		var sp := Vector2(p.x, p.y - 18.0 + float(k) * 12.0)
		wc.rect(Rect2(sp.x - 9.0, sp.y - 5.5, 17.0, 11.0), AeroportArt.SEAT)
		wc.rect(Rect2(sp.x - 8.0, sp.y - 4.5, 11.0, 9.0), AeroportArt.SEAT_PAD)
		wc.rect(Rect2(sp.x + 4.0, sp.y - 5.0, 3.0, 10.0), AeroportArt.SEAT.lightened(0.14))
	for ey: float in [-25.0, 23.0]:
		wc.rect(Rect2(p.x - 9.0, p.y + ey, 18.0, 2.0), AeroportArt.STEEL_DARK)


# the recycling point: three steel mouths, one colour each
static func draw_bin(m: Node2D, wc: ShapeBatch, p: Vector2) -> void:
	m.box_shadow(wc, Rect2(p.x - 13.0, p.y - 9.0, 26.0, 18.0), 3.0, 7.0)
	wc.rect(Rect2(p.x - 13.0, p.y - 9.0, 26.0, 18.0), AeroportArt.STEEL_DARK)
	wc.rect(Rect2(p.x - 12.0, p.y - 8.0, 24.0, 15.0), AeroportArt.STEEL)
	var cols: Array[Color] = [Color(0.96, 0.80, 0.16), Color(0.20, 0.44, 0.80), Color(0.26, 0.60, 0.36)]
	for k in range(3):
		var q := Vector2(p.x - 8.0 + float(k) * 8.0, p.y - 1.0)
		wc.circle(q, 3.4, cols[k])
		wc.circle(q, 2.3, Color(0.08, 0.08, 0.10))


# a fig in a steel tub: the terminal's stand-in for a lamp post to sniff
static func draw_bollard(m: Node2D, wc: ShapeBatch, h) -> void:
	var hp: Vector2 = h.pos
	m.contact_shadow(wc, hp, 16.0, 6.0, 0.2)
	wc.draw_circle(hp, 13.0, AeroportArt.STEEL_DARK)
	wc.draw_circle(hp, 11.0, AeroportArt.STEEL if not h.done else AeroportArt.STEEL.darkened(0.15))
	wc.draw_circle(hp, 9.0, Color(0.30, 0.24, 0.18))
	for k in range(7):
		var a := TAU * float(k) / 7.0 + hp.y * 0.01
		wc.capsule(hp, hp + Vector2.from_angle(a) * 16.0, 4.2, Color(0.20, 0.44, 0.26))
		wc.draw_line(hp, hp + Vector2.from_angle(a) * 15.0, Color(0.36, 0.62, 0.36), 1.6)
	if not h.done and h.progress > 0.0:
		wc.draw_arc(hp, 19.0, -PI / 2.0, -PI / 2.0 + TAU * h.progress / 0.8, 20, Color(1, 0.95, 0.7), 3.0)


# --- the cabin ---------------------------------------------------------------

static func draw_freedom(m: Node2D, c: Object) -> void:
	AeroportCabin.draw(m, c)


static func draw_park_prop(m: Node2D, c: Object, pp: Dictionary) -> bool:
	return AeroportCabin.draw_prop(m, c, pp)


static func draw_gate(m: Node2D, b: ShapeBatch) -> void:
	AeroportCabin.draw_gate(m, b)
