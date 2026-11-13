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
# - The Security Cart Buggy (entities/aeroport_threat.gd) chases the pair down
#   the terminal concourse, flashing its amber roof beacon, siren chirping,
#   and shedding tumbling rolling suitcases that skid across the tiles.
# - Wedges into the duty-free perfume pyramid (-3400) and tangles in the
#   Gate B24 queue stanchions (-1900, checkpoint): the two respites.

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
const TERRACE_Y := -4800.0            # outdoor pet relief terrace

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


static func surface(_m: Node2D, pos: Vector2) -> int:
	if pos.y < TERRACE_Y and absf(pos.x - 640.0) < 200.0:
		return Surfaces.S.GRASS
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

static func draw_scenery(m: Node2D, wc: ShapeBatch, vt: float, vb: float) -> void:
	if m.lvl != "aeroport":
		return
	var b: ShapeBatch = wc
	_draw_runway_apron(b, vt, vb)
	_draw_terminal_floor(b, vt, vb)
	_draw_travelator(m, b, vt, vb)
	_draw_boarding_gates(b, vt, vb)
	_draw_duty_free(b, vt, vb)
	_draw_baggage_carousel(m, b, vt, vb)


static func _draw_runway_apron(b: ShapeBatch, vt: float, vb: float) -> void:
	# West tarmac outside glass curtain wall (x < WALL_L)
	var tarmac_rect := Rect2(0.0, vt, WALL_L, vb - vt)
	b.rect(tarmac_rect, RUNWAY_TARMAC)

	# Yellow taxiway centerlines
	var ty := floorf(vt / 120.0) * 120.0
	while ty <= vb:
		b.rect(Rect2(WALL_L - 140.0, ty, 6.0, 80.0), RUNWAY_LINE)
		ty += 120.0

	# Parked airliner wingtip silhouette at y ≈ -1800
	if -2000.0 < vb and -1600.0 > vt:
		var wing := PackedVector2Array([
			Vector2(WALL_L - 280.0, -1700.0),
			Vector2(WALL_L - 80.0, -1820.0),
			Vector2(WALL_L - 70.0, -1880.0),  # winglet up
			Vector2(WALL_L - 90.0, -1880.0),
			Vector2(WALL_L - 110.0, -1830.0),
			Vector2(WALL_L - 300.0, -1760.0),
		])
		b.polygon(wing, PLANE_WHITE)
		b.rect(Rect2(WALL_L - 86.0, -1876.0, 12.0, 46.0), PLANE_BLUE)

	# Glass curtain wall mullions along WALL_L
	b.rect(Rect2(WALL_L - 6.0, vt, 12.0, vb - vt), GLASS_FRAME)
	var my := floorf(vt / 60.0) * 60.0
	while my <= vb:
		b.rect(Rect2(WALL_L - 14.0, my - 2.0, 20.0, 4.0), GLASS_FRAME)
		my += 60.0


static func _draw_terminal_floor(b: ShapeBatch, vt: float, vb: float) -> void:
	# Polished light granite concourse flooring
	var floor_rect := Rect2(WALL_L, vt, WALL_R - WALL_L, vb - vt)
	b.rect(floor_rect, TILE_LIGHT)

	# Alternating polished darker tile bands every 160 px
	var by := floorf(vt / 160.0) * 160.0
	while by <= vb:
		b.rect(Rect2(WALL_L, by, WALL_R - WALL_L, 40.0), TILE_DARK)
		by += 160.0

	# Thin subtle tile grid lines
	var gx := WALL_L
	while gx <= WALL_R:
		b.rect(Rect2(gx, vt, 1.0, vb - vt), TILE_GRID)
		gx += 80.0


static func _draw_travelator(_m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	var z: Rect2 = WALKWAY_RECT
	if z.end.y < vt or z.position.y > vb:
		return
	var top := maxf(z.position.y, vt)
	var bot := minf(z.end.y, vb)

	# Main steel bed
	b.rect(Rect2(z.position.x, top, z.size.x, bot - top), TRAVELATOR_STEEL)

	# Scrolling yellow caution chevrons
	var scroll: float = fmod(AnimClock.msec() / 1000.0 * 110.0, 60.0)
	var cy := floorf((top - scroll) / 60.0) * 60.0 + scroll
	while cy <= bot:
		if cy >= z.position.y and cy <= z.end.y:
			var pts := PackedVector2Array([
				Vector2(z.get_center().x, cy - 14.0),
				Vector2(z.get_center().x + 24.0, cy + 4.0),
				Vector2(z.get_center().x - 24.0, cy + 4.0),
			])
			b.polygon(pts, Color(0.95, 0.82, 0.20, 0.80))
		cy += 60.0

	# Yellow comb warning plates at both ends
	if z.position.y >= vt and z.position.y <= vb:
		b.rect(Rect2(z.position.x, z.position.y, z.size.x, 24.0), TRAVELATOR_COMB)
	if z.end.y >= vt and z.end.y <= vb:
		b.rect(Rect2(z.position.x, z.end.y - 24.0, z.size.x, 24.0), TRAVELATOR_COMB)

	# The sides: a steel skirt at the floor, the glass panel standing on it
	# (seen from above as a pale strip with its joints), and the black rubber
	# handrail along the top, rounded off in a newel at each end
	for r: Rect2 in balustrades():
		var seen := Rect2(r.position.x, top, r.size.x, bot - top)
		b.rect(Rect2(seen.position + Vector2(3.0, 0.0), seen.size), Color(0.0, 0.0, 0.0, 0.16))
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
		for ey: float in [r.position.y, r.end.y]:
			if ey >= vt - 12.0 and ey <= vb + 12.0:
				b.circle(Vector2(cxr, ey), 8.0, TRAVELATOR_HANDRAIL)
				b.circle(Vector2(cxr - 2.0, ey - 2.0), 3.0, Color(0.30, 0.30, 0.32))


static func _draw_boarding_gates(b: ShapeBatch, vt: float, vb: float) -> void:
	for i in range(GATE_DESKS.size()):
		var desk: Rect2 = GATE_DESKS[i]
		if desk.end.y < vt or desk.position.y > vb:
			continue
		# Desk body
		b.rect(desk, Color(0.24, 0.26, 0.30))
		b.rect(Rect2(desk.position.x, desk.position.y, 4.0, desk.size.y), Color(0.40, 0.44, 0.50))
		# Overhead blue LED gate sign
		var sign_rect := Rect2(desk.position.x - 20.0, desk.position.y - 30.0, 60.0, 22.0)
		b.rect(sign_rect, SIGN_BLUE)
		b.rect(sign_rect.grow(-2.0), Color(0.12, 0.16, 0.24))
		b.rect(Rect2(sign_rect.position.x + 4.0, sign_rect.position.y + 4.0, 16.0, 4.0), SIGN_YELLOW)


static func _draw_duty_free(b: ShapeBatch, vt: float, vb: float) -> void:
	# Perfume island (first jam respite)
	if PERFUME_ISLAND.end.y >= vt and PERFUME_ISLAND.position.y <= vb:
		b.rect(PERFUME_ISLAND, Color(0.25, 0.22, 0.28))
		b.rect(PERFUME_ISLAND.grow(-4.0), Color(0.35, 0.30, 0.40))
		# Perfume bottles on tiered display
		var bx: float = PERFUME_ISLAND.position.x + 12.0
		while bx < PERFUME_ISLAND.end.x - 10.0:
			b.circle(Vector2(bx, PERFUME_ISLAND.get_center().y), 9.0, PERFUME_GLASS)
			b.circle(Vector2(bx, PERFUME_ISLAND.get_center().y - 2.0), 3.0, PERFUME_GOLD)
			bx += 22.0

	# the giant duty-free chocolate display
	if CHOCOLATE_ISLAND.end.y >= vt and CHOCOLATE_ISLAND.position.y <= vb:
		b.rect(CHOCOLATE_ISLAND, Color(0.30, 0.24, 0.18))
		# Triangular gold packaging
		var tri := PackedVector2Array([
			Vector2(CHOCOLATE_ISLAND.get_center().x, CHOCOLATE_ISLAND.position.y + 6.0),
			Vector2(CHOCOLATE_ISLAND.end.x - 8.0, CHOCOLATE_ISLAND.end.y - 8.0),
			Vector2(CHOCOLATE_ISLAND.position.x + 8.0, CHOCOLATE_ISLAND.end.y - 8.0),
		])
		b.polygon(tri, CHOCOLATE_GOLD)


static func _draw_baggage_carousel(_m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	var r: Rect2 = CAROUSEL_RECT
	if r.end.y < vt or r.position.y > vb:
		return
	# Stainless steel housing
	b.rect(r, CAROUSEL_TRIM)
	b.rect(r.grow(-8.0), CAROUSEL_RUBBER)
	# Center island
	b.rect(r.grow(-24.0), Color(0.40, 0.42, 0.46))

	# Suitcases moving around the loop
	var t: float = AnimClock.msec() / 1000.0 * 45.0
	var bags: Array[Color] = [Color(0.85, 0.18, 0.16), Color(0.18, 0.45, 0.85), Color(0.20, 0.20, 0.22)]
	for i in range(bags.size()):
		var bag_pos := _carousel_pos(r, fmod(t + float(i) * 90.0, 360.0))
		b.rect(Rect2(bag_pos - Vector2(10.0, 7.0), Vector2(20.0, 14.0)), bags[i])
		b.rect(Rect2(bag_pos - Vector2(3.0, 3.0), Vector2(6.0, 6.0)), Color(0.9, 0.9, 0.9))


static func _carousel_pos(r: Rect2, angle_deg: float) -> Vector2:
	var rad: float = deg_to_rad(angle_deg)
	var c := r.get_center()
	var rx: float = r.size.x * 0.5 - 16.0
	var ry: float = r.size.y * 0.5 - 16.0
	return c + Vector2(cos(rad) * rx, sin(rad) * ry)


static func draw_live(m: Node2D, wc: ShapeBatch, vt: float, vb: float) -> void:
	if m.lvl != "aeroport":
		return
	var b: ShapeBatch = wc
	_draw_gate_rush_live(m, b, vt, vb)


static func _draw_gate_rush_live(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	var rush: Dictionary = m.aeroport_rush
	var state: String = rush.get("state", "waiting")
	if state != "running" and state != "warn":
		return
	if GATE_RUSH_Y < vt or GATE_RUSH_Y > vb:
		return

	if state == "warn":
		# Warning telegraph: dashed amber crossing line
		b.rect(Rect2(400.0, GATE_RUSH_Y - 2.0, 480.0, 4.0), Color(1.0, 0.8, 0.2, 0.45))
	elif state == "running":
		var progress: float = clampf(float(rush.get("t", 0.0)) / RUSH_CROSS_SECS, 0.0, 1.0)
		for k in range(RUSH_COUNT):
			var stagger: float = float(k) * 0.08
			var p: float = clampf(progress - stagger, 0.0, 1.0)
			var px: float = lerpf(390.0, 870.0, p)
			var py: float = GATE_RUSH_Y + float((k % 2) * 2 - 1) * 16.0
			# Traveler body
			b.circle(Vector2(px, py), 8.0, Color(0.20, 0.25, 0.35))
			# Rolling suitcase behind them
			b.rect(Rect2(px - 18.0, py - 6.0, 12.0, 10.0), Color(0.70, 0.20, 0.15))
			b.rect(Rect2(px - 6.0, py - 1.0, 6.0, 2.0), Color(0.1, 0.1, 0.1))  # handle


static func draw_overhead(m: Node2D, c: CanvasItem) -> void:
	if m.lvl != "aeroport":
		return
	# Draw structural pillars with metallic rims and 3D caps
	for p: Vector2 in POSTS:
		c.draw_circle(p, 16.0, PILLAR_BASE)
		c.draw_circle(p, 13.0, PILLAR_STEEL)
		c.draw_circle(p + Vector2(-3.0, -3.0), 5.0, Color(0.75, 0.80, 0.88))
