class_name AgilityCourse
extends RefCounted

# The agility course in El Barri's dog park: a start, a jump, six weave poles,
# the pause table, a tunnel, a second jump and a finish, laid along one lane
# and run left to right against the clock. Nothing on it is solid: she runs
# the line and the course judges it. A jump is cleared by crossing its bar in
# the lane; the poles by passing each on its own side (the chalk racing line
# snakes through them the right way); the table by standing on it dug in for
# a count of three; the tunnel by going in one mouth and out the other. Each
# element missed is a fault, time added. The finish gives a medal by time and
# the best time is kept (Game.agility_best).
#
# What to do is always on the ground: the racing line, a bouncing arrow over
# the next element (over the start when no run is on), funnel wings at the
# tunnel's mouth, and each pole turns green or red as she passes it.
#
# Pure: it is fed the dog's position each frame and answers with events, so
# the rules are testable without a level (tests/test_freedom_games.gd).

enum E { START, JUMP, WEAVE, TUNNEL, FINISH, TABLE }

const LANE_H := 34.0          # half the lane's height: inside it counts
const WEAVE_N := 6
const WEAVE_GAP := 40.0
const WEAVE_SLACK := 6.0      # a pole passed this close to its line still counts
const TUNNEL_LEN := 100.0
const TUNNEL_R := 20.0        # the tube's half-width, as drawn
const TUNNEL_IN := 30.0       # the mouth she may go in by: the funnel wings guide her
const TABLE_HALF := 24.0
const TABLE_S := 1.5          # dug in on the table for this long: "1... 2... 3!"
const FAULT_S := 2.0          # seconds a missed element costs
const QUIT_DIST := 200.0      # this far off the lane and the run is abandoned
const QUIT_IDLE := 10.0       # ...or this long without getting anywhere
const DESIGN_W := 700.0       # start to finish at full size
# a medal by time (faults included): [name, seconds or under, bones]
const MEDALS := [["GOLD", 6.5, 8], ["SILVER", 9.0, 5], ["BRONZE", 14.0, 3]]

var ly := 0.0                 # the lane's centre line
var x0 := 0.0                 # start
var x1 := 0.0                 # finish
var parts: Array = []         # {kind, x, [x_end], [side], done}
var running := false
var can_start := true         # false while her mouth is full: no run by accident
var t := 0.0
var faults := 0
var last_time := 0.0
var _idle := 0.0
var _best_x := 0.0


func _init(lane_y: float, start_x: float, finish_x: float) -> void:
	ly = lane_y
	x0 = start_x
	x1 = finish_x
	var k := (x1 - x0) / DESIGN_W
	parts = [{"kind": E.JUMP, "x": x0 + 80.0 * k}]
	var w0 := x0 + 150.0 * k
	for i in range(WEAVE_N):
		parts.append({"kind": E.WEAVE, "x": w0 + WEAVE_GAP * float(i), "side": -1.0 if i % 2 == 0 else 1.0})
	parts.append({"kind": E.TABLE, "x": x0 + 430.0 * k, "hold": 0.0})
	parts.append({"kind": E.TUNNEL, "x": x0 + 500.0 * k, "x_end": x0 + 500.0 * k + TUNNEL_LEN})
	parts.append({"kind": E.JUMP, "x": x0 + 650.0 * k})
	for p: Dictionary in parts:
		p["done"] = false


# Where the lane runs in this space: low enough that the goals card never
# covers it (the camera stops at the top fence), clear of the fixed things
# (the beach's sea and shower, a plaça's trees and fountain).
static func for_space(kind: String, gate_y: float) -> AgilityCourse:
	match kind:
		"beach":
			# below the shower and its trough, on the dry sand
			return AgilityCourse.new(gate_y - 400.0, 560.0, 1060.0)
		"placa":
			# below the fountain: the plane trees line the top of a square
			return AgilityCourse.new(gate_y - 320.0, 460.0, 1040.0)
	return AgilityCourse.new(gate_y - 430.0, 260.0, 960.0)


# the ground the course stands on, grown by `margin`: props and trees keep out
func lane_rect(margin := 0.0) -> Rect2:
	return Rect2(x0 - 30.0, ly - LANE_H - 16.0, x1 - x0 + 60.0, (LANE_H + 16.0) * 2.0).grow(margin)


# A thing in the way is nudged off the lane rather than re-rolled, so the
# random numbers that placed it, and everything placed after it, are unchanged.
func push_out(p: Vector2, margin: float) -> Vector2:
	var r := lane_rect(margin)
	if not r.has_point(p):
		return p
	return Vector2(p.x, r.position.y - 1.0 if p.y < ly else r.end.y + 1.0)


func table_rect(p: Dictionary) -> Rect2:
	var px: float = p["x"]
	return Rect2(px - TABLE_HALF, ly - TABLE_HALF, TABLE_HALF * 2.0, TABLE_HALF * 2.0)


# One frame of the dog going from `a` to `b`, dug in or not. Returns the
# events in order: ["start"], ["jump"], ["pole", ok], ["table_count", n],
# ["table_done"], ["tunnel_in"], ["tunnel_out", ok], ["finish", seconds,
# faults, medal], ["quit"].
func step(a: Vector2, b: Vector2, delta: float, planted := false) -> Array:
	var ev: Array = []
	var in_lane := absf(b.y - ly) < LANE_H
	if not running:
		if a.x < x0 and b.x >= x0 and in_lane and can_start:
			running = true
			t = 0.0
			faults = 0
			_idle = 0.0
			_best_x = b.x
			for p: Dictionary in parts:
				p["done"] = false
				p.erase("ok")
				p["in"] = false
				if int(p["kind"]) == E.TABLE:
					p["hold"] = 0.0
			ev.append(["start"])
		return ev
	t += delta
	# getting somewhere means getting further along, or counting on the table
	var counting := false
	for p: Dictionary in parts:
		if int(p["kind"]) == E.TABLE and not p["done"] and table_rect(p).has_point(b):
			counting = planted
	if b.x > _best_x + 4.0 or counting:
		_best_x = maxf(_best_x, b.x)
		_idle = 0.0
	else:
		_idle += delta
	if absf(b.y - ly) > QUIT_DIST or _idle > QUIT_IDLE or b.x < x0 - 120.0:
		running = false
		ev.append(["quit"])
		return ev
	for p: Dictionary in parts:
		if p["done"]:
			continue
		var px: float = p["x"]
		match int(p["kind"]):
			E.JUMP:
				if a.x < px and b.x >= px:
					p["done"] = in_lane
					if in_lane:
						ev.append(["jump"])
			E.WEAVE:
				if a.x < px and b.x >= px:
					var dy := b.y - ly
					var side: float = p["side"]
					var ok := dy * side > -WEAVE_SLACK and absf(dy) < LANE_H + 14.0
					p["done"] = true
					p["ok"] = ok
					if not ok:
						faults += 1
					ev.append(["pole", ok])
			E.TABLE:
				var on := table_rect(p).has_point(b)
				if on and planted:
					var was: float = p["hold"]
					var now: float = minf(was + delta, TABLE_S)
					p["hold"] = now
					for n in [1, 2]:
						var at := TABLE_S * float(n) / 3.0
						if was < at and now >= at:
							ev.append(["table_count", n])
					if now >= TABLE_S:
						p["done"] = true
						ev.append(["table_done"])
				elif not on:
					p["hold"] = 0.0
			E.TUNNEL:
				var xe: float = p["x_end"]
				var inside := b.x > px and b.x < xe
				if not p.get("in", false):
					if a.x <= px and b.x > px and absf(b.y - ly) < TUNNEL_IN:
						p["in"] = true
						ev.append(["tunnel_in"])
				else:
					if b.x >= xe:
						p["in"] = false
						p["done"] = true
						ev.append(["tunnel_out", true])
					elif not inside or absf(b.y - ly) > TUNNEL_IN:
						# out of the side of a tunnel is not through it
						p["in"] = false
						ev.append(["tunnel_out", false])
	if a.x < x1 and b.x >= x1 and absf(b.y - ly) < LANE_H + 20.0:
		for p: Dictionary in parts:
			if not p["done"]:
				faults += 1
				p["ok"] = false
		running = false
		last_time = t + float(faults) * FAULT_S
		ev.append(["finish", last_time, faults, medal_for(last_time)])
	return ev


# "GOLD", "SILVER", "BRONZE" or "" for a time
static func medal_for(secs: float) -> String:
	for md: Array in MEDALS:
		if secs <= float(md[1]):
			return String(md[0])
	return ""


static func medal_bones(medal: String) -> int:
	for md: Array in MEDALS:
		if String(md[0]) == medal:
			return int(md[2])
	return 1


# the next element she should take, or {} when only the finish is left
func next_part() -> Dictionary:
	for p: Dictionary in parts:
		if not p["done"]:
			return p
	return {}


# where along the course she should be heading next (for the banner and the
# arrow): the next element's x, or the finish's
func next_x() -> float:
	var p := next_part()
	return x1 if p.is_empty() else float(p["x"])


func in_tunnel() -> bool:
	for p: Dictionary in parts:
		if int(p["kind"]) == E.TUNNEL and p.get("in", false):
			return true
	return false


# --- drawing -----------------------------------------------------------------

const RED := Color(0.86, 0.26, 0.2)
const WHITE := Color(0.96, 0.94, 0.88)
const BLUE := Color(0.24, 0.42, 0.78)
const YELLOW := Color(0.95, 0.78, 0.25)
const GREEN := Color(0.36, 0.76, 0.40)
const INK := Color(0.12, 0.1, 0.09)
const TUBE := Color(0.22, 0.5, 0.78)
const TABLE_TOP := Color(0.86, 0.36, 0.26)
const CHALK := Color(1.0, 1.0, 0.96, 0.55)


# the racing line's y at x: straight down the lane, snaking through the weave
func line_y(x: float) -> float:
	var first: float = INF
	var last: float = -INF
	for p: Dictionary in parts:
		if int(p["kind"]) == E.WEAVE:
			first = minf(first, float(p["x"]))
			last = maxf(last, float(p["x"]))
	if x < first - WEAVE_GAP * 0.5 or x > last + WEAVE_GAP * 0.5:
		return ly
	# a sine through the poles: at each pole it is out on that pole's side
	var u := (x - first) / WEAVE_GAP
	var amp := 17.0 * clampf(minf(x - (first - WEAVE_GAP * 0.5), (last + WEAVE_GAP * 0.5) - x) / (WEAVE_GAP * 0.5), 0.0, 1.0)
	return ly - cos(u * PI) * amp


# what stands on the ground (under the dog): lane marks, the racing line, the
# start and finish flags, jump wings and bars, the weave poles, the table, the
# tunnel's shadow, mouths and funnel wings, and the arrow over what is next
func draw_ground(c: Variant, now: float) -> void:
	var sh := Color(0, 0, 0, 0.18)
	# the lane: a run of chalk dashes either side
	var x := x0
	while x < x1:
		c.draw_rect(Rect2(x, ly - LANE_H, 14.0, 2.0), Color(1, 1, 1, 0.22))
		c.draw_rect(Rect2(x, ly + LANE_H, 14.0, 2.0), Color(1, 1, 1, 0.22))
		x += 30.0
	# the racing line: dashed chalk, the way to run it
	x = x0
	while x < x1:
		var x2 := minf(x + 9.0, x1)
		c.draw_line(Vector2(x, line_y(x)), Vector2(x2, line_y(x2)), CHALK, 2.5)
		x += 16.0
	_flag(c, Vector2(x0, ly - LANE_H - 6.0), GREEN, now)
	_flag(c, Vector2(x0, ly + LANE_H + 6.0), GREEN, now)
	_chequer(c, Vector2(x1, ly - LANE_H - 6.0), now)
	_chequer(c, Vector2(x1, ly + LANE_H + 6.0), now)
	for p: Dictionary in parts:
		var px: float = p["x"]
		var passed: bool = p["done"]
		var missed: bool = p.has("ok") and not bool(p["ok"])
		match int(p["kind"]):
			E.JUMP:
				var top := ly - LANE_H + 2.0
				var bot := ly + LANE_H - 2.0
				c.draw_rect(Rect2(px - 2.0, top + 6.0, 6.0, bot - top), sh)
				for wy: float in [top, bot]:
					c.draw_rect(Rect2(px - 6.0, wy - 6.0, 12.0, 12.0), INK)
					c.draw_rect(Rect2(px - 4.5, wy - 4.5, 9.0, 9.0), GREEN if passed else BLUE)
				# the bar, striped
				var seg := (bot - top) / 6.0
				for k in range(6):
					c.draw_rect(Rect2(px - 2.5, top + seg * float(k), 5.0, seg),
						RED if k % 2 == 0 else WHITE)
			E.WEAVE:
				c.draw_circle(Vector2(px + 3.0, ly + 4.0), 6.0, sh)
				c.draw_circle(Vector2(px, ly), 6.0, INK)
				var pc := YELLOW
				if passed:
					pc = RED if missed else GREEN
				c.draw_circle(Vector2(px, ly), 4.4, pc)
				c.draw_circle(Vector2(px - 1.2, ly - 1.2), 1.6, Color(1, 1, 1, 0.6))
			E.TABLE:
				var r := table_rect(p)
				c.draw_rect(Rect2(r.position + Vector2(4, 6), r.size), sh)
				c.draw_rect(r.grow(2.0), INK)
				c.draw_rect(r, GREEN.darkened(0.1) if passed else TABLE_TOP)
				c.draw_rect(Rect2(r.position + Vector2(3, 3), Vector2(r.size.x - 6.0, 5.0)), Color(1, 1, 1, 0.18))
				# the count, a ring filling round the middle
				var hold: float = p.get("hold", 0.0)
				if hold > 0.0 and not passed:
					c.draw_arc(r.get_center(), 15.0, -PI / 2.0, -PI / 2.0 + TAU * hold / TABLE_S, 24, WHITE, 3.5)
				else:
					# a paw print: stand here
					c.draw_circle(r.get_center() + Vector2(0, 3), 5.0, Color(1, 1, 1, 0.35))
					for k in range(3):
						c.draw_circle(r.get_center() + Vector2(-5.0 + float(k) * 5.0, -4.5), 2.2, Color(1, 1, 1, 0.35))
			E.TUNNEL:
				var xe: float = p["x_end"]
				c.draw_rect(Rect2(px + 6.0, ly - TUNNEL_R + 8.0, xe - px, TUNNEL_R * 2.0), sh)
				# funnel wings at the way in, so she lines up with the mouth
				for s: float in [-1.0, 1.0]:
					var a0 := Vector2(px - 2.0, ly + s * (TUNNEL_R + 2.0))
					c.draw_line(a0, a0 + Vector2(-26.0, s * 16.0), INK, 5.0)
					c.draw_line(a0, a0 + Vector2(-26.0, s * 16.0), YELLOW, 3.0)
	_draw_next(c, now)


# a bouncing arrow over the start (no run on) or over the next element
func _draw_next(c: Variant, now: float) -> void:
	var at: Vector2
	if not running:
		at = Vector2(x0, ly)
	else:
		var p := next_part()
		if p.is_empty():
			at = Vector2(x1, ly)
		elif int(p["kind"]) == E.TUNNEL:
			at = Vector2(float(p["x"]), ly)
		else:
			at = Vector2(float(p["x"]), line_y(float(p["x"])))
	var bob := absf(sin(now * 4.0)) * 6.0
	var tip := at + Vector2(0.0, -LANE_H - 10.0 - bob)
	var pts := PackedVector2Array([tip, tip + Vector2(-9, -12), tip + Vector2(9, -12)])
	c.draw_colored_polygon(PackedVector2Array([tip + Vector2(0, 2), tip + Vector2(-11, -13), tip + Vector2(11, -13)]), INK)
	c.draw_colored_polygon(pts, YELLOW)


# what goes over the dog: the tunnel's tube, so she vanishes into it
func draw_cover(c: Variant) -> void:
	for p: Dictionary in parts:
		if int(p["kind"]) != E.TUNNEL:
			continue
		var px: float = p["x"]
		var xe: float = p["x_end"]
		var r := Rect2(px, ly - TUNNEL_R - 4.0, xe - px, (TUNNEL_R + 4.0) * 2.0)
		c.draw_rect(r.grow(2.0), INK)
		c.draw_rect(r, GREEN.darkened(0.15) if p["done"] else TUBE)
		# the ribs of the tube, and its light side
		var x := px + 10.0
		while x < xe - 4.0:
			c.draw_rect(Rect2(x, r.position.y, 3.0, r.size.y), TUBE.darkened(0.22))
			x += 14.0
		c.draw_rect(Rect2(px, r.position.y + 4.0, xe - px, 5.0), TUBE.lightened(0.25))
		# the dark mouths
		for mx: float in [px, xe]:
			c.draw_circle(Vector2(mx, ly), TUNNEL_R + 2.0, INK)
			c.draw_circle(Vector2(mx, ly), TUNNEL_R - 2.0, Color(0.06, 0.06, 0.08))


func _flag(c: Variant, at: Vector2, col: Color, now: float) -> void:
	c.draw_line(at, at + Vector2(0, -26), INK, 2.5)
	var wave := sin(now * 5.0 + at.y) * 2.0
	c.draw_colored_polygon(PackedVector2Array([at + Vector2(1, -26), at + Vector2(16, -21 + wave),
		at + Vector2(1, -15)]), col)


func _chequer(c: Variant, at: Vector2, now: float) -> void:
	c.draw_line(at, at + Vector2(0, -26), INK, 2.5)
	var wave := sin(now * 5.0 + at.y) * 1.5
	for i in range(3):
		for j in range(2):
			var col := INK if (i + j) % 2 == 0 else WHITE
			c.draw_rect(Rect2(at + Vector2(1.0 + float(i) * 5.0, -26.0 + float(j) * 5.0 + wave * float(i) / 3.0),
				Vector2(5, 5)), col)
