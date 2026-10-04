class_name AgilityCourse
extends RefCounted

# The agility course in every off-leash space: a start, a jump, five weave
# poles, a tunnel, a second jump and a finish, laid along one lane across the
# space, run left to right against the clock. Nothing on it is solid - she
# runs the line, and the course judges it: a jump cleared or not, the poles
# woven on the right sides, the tunnel gone through end to end. Each fault is
# time added, and the best time is kept (Game.agility_best).
#
# Pure: it is fed the dog's position each frame and answers with events, so
# the rules are testable without a level (tests/test_freedom_games.gd).

enum E { START, JUMP, WEAVE, TUNNEL, FINISH }

const LANE_H := 34.0          # half the lane's height: inside it counts
const WEAVE_GAP := 44.0
const TUNNEL_LEN := 120.0
const TUNNEL_R := 20.0        # the mouth: she must go in along the lane
const FAULT_S := 2.0          # seconds a missed element costs
const QUIT_DIST := 170.0      # this far off the lane and the run is abandoned
const QUIT_IDLE := 6.0        # ...or this long without getting anywhere
const DESIGN_W := 700.0       # start to finish at full size

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
	parts = [
		{"kind": E.JUMP, "x": x0 + 100.0 * k},
		{"kind": E.WEAVE, "x": x0 + 190.0 * k, "side": -1.0},
		{"kind": E.WEAVE, "x": x0 + 190.0 * k + WEAVE_GAP, "side": 1.0},
		{"kind": E.WEAVE, "x": x0 + 190.0 * k + WEAVE_GAP * 2.0, "side": -1.0},
		{"kind": E.WEAVE, "x": x0 + 190.0 * k + WEAVE_GAP * 3.0, "side": 1.0},
		{"kind": E.WEAVE, "x": x0 + 190.0 * k + WEAVE_GAP * 4.0, "side": -1.0},
		{"kind": E.TUNNEL, "x": x0 + 440.0 * k, "x_end": x0 + 440.0 * k + TUNNEL_LEN},
		{"kind": E.JUMP, "x": x0 + 620.0 * k},
	]
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


# One frame of the dog going from `a` to `b`. Returns the events in order:
# ["start"], ["jump"], ["pole", ok], ["tunnel_in"], ["tunnel_out", ok],
# ["finish", seconds, faults], ["quit"].
func step(a: Vector2, b: Vector2, delta: float) -> Array:
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
			ev.append(["start"])
		return ev
	t += delta
	# getting somewhere means getting further along
	if b.x > _best_x + 4.0:
		_best_x = b.x
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
					var ok := signf(b.y - ly) == float(p["side"]) and absf(b.y - ly) < LANE_H + 14.0
					p["done"] = true
					p["ok"] = ok
					if not ok:
						faults += 1
					ev.append(["pole", ok])
			E.TUNNEL:
				var xe: float = p["x_end"]
				var inside := b.x > px and b.x < xe
				if not p.get("in", false):
					if a.x <= px and b.x > px and absf(b.y - ly) < TUNNEL_R:
						p["in"] = true
						ev.append(["tunnel_in"])
				else:
					if b.x >= xe:
						p["in"] = false
						p["done"] = true
						ev.append(["tunnel_out", true])
					elif not inside or absf(b.y - ly) > TUNNEL_R:
						# out of the side of a tunnel is not through it
						p["in"] = false
						ev.append(["tunnel_out", false])
	if a.x < x1 and b.x >= x1 and absf(b.y - ly) < LANE_H + 20.0:
		for p: Dictionary in parts:
			if not p["done"]:
				faults += 1
		running = false
		last_time = t + float(faults) * FAULT_S
		ev.append(["finish", last_time, faults])
	return ev


# where along the course she should be heading next (for the banner and the
# arrow), or INF when the run is complete
func next_x() -> float:
	for p: Dictionary in parts:
		if not p["done"]:
			return p["x"]
	return x1


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
const INK := Color(0.12, 0.1, 0.09)
const TUBE := Color(0.22, 0.5, 0.78)


# what stands on the ground (under the dog): lane marks, the start and finish
# flags, jump wings and bars, the weave poles, the tunnel's shadow and mouths
func draw_ground(c: Variant, now: float) -> void:
	var sh := Color(0, 0, 0, 0.18)
	# the lane: a run of chalk dashes either side
	var x := x0
	while x < x1:
		c.draw_rect(Rect2(x, ly - LANE_H, 14.0, 2.0), Color(1, 1, 1, 0.22))
		c.draw_rect(Rect2(x, ly + LANE_H, 14.0, 2.0), Color(1, 1, 1, 0.22))
		x += 30.0
	_flag(c, Vector2(x0, ly - LANE_H - 6.0), Color(0.3, 0.72, 0.36), now)
	_flag(c, Vector2(x0, ly + LANE_H + 6.0), Color(0.3, 0.72, 0.36), now)
	_chequer(c, Vector2(x1, ly - LANE_H - 6.0), now)
	_chequer(c, Vector2(x1, ly + LANE_H + 6.0), now)
	for p: Dictionary in parts:
		var px: float = p["x"]
		match int(p["kind"]):
			E.JUMP:
				var top := ly - LANE_H + 2.0
				var bot := ly + LANE_H - 2.0
				c.draw_rect(Rect2(px - 2.0, top + 6.0, 6.0, bot - top), sh)
				for wy: float in [top, bot]:
					c.draw_rect(Rect2(px - 5.0, wy - 5.0, 10.0, 10.0), INK)
					c.draw_rect(Rect2(px - 3.5, wy - 3.5, 7.0, 7.0), BLUE)
				# the bar, striped
				var seg := (bot - top) / 6.0
				for k in range(6):
					c.draw_rect(Rect2(px - 2.0, top + seg * float(k), 4.0, seg),
						RED if k % 2 == 0 else WHITE)
			E.WEAVE:
				c.draw_circle(Vector2(px + 3.0, ly + 4.0), 5.0, sh)
				c.draw_circle(Vector2(px, ly), 5.0, INK)
				c.draw_circle(Vector2(px, ly), 3.6, YELLOW if p.get("ok", true) or not p["done"] else RED)
				# which side to pass: a little chevron in the chalk
				var s: float = p["side"]
				c.draw_rect(Rect2(px - 3.0, ly + s * 18.0 - 1.0, 6.0, 2.0), Color(1, 1, 1, 0.35))
			E.TUNNEL:
				var xe: float = p["x_end"]
				c.draw_rect(Rect2(px + 6.0, ly - TUNNEL_R + 8.0, xe - px, TUNNEL_R * 2.0), sh)


# what goes over the dog: the tunnel's tube, so she vanishes into it
func draw_cover(c: Variant) -> void:
	for p: Dictionary in parts:
		if int(p["kind"]) != E.TUNNEL:
			continue
		var px: float = p["x"]
		var xe: float = p["x_end"]
		var r := Rect2(px, ly - TUNNEL_R - 4.0, xe - px, (TUNNEL_R + 4.0) * 2.0)
		c.draw_rect(r.grow(2.0), INK)
		c.draw_rect(r, TUBE)
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
