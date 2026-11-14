class_name ChaseSquad
extends RefCounted

# A chase threat that is a line of people (or animals) on foot, rather than one
# machine: each member is a body of its own that runs for its slot in the line
# and goes round what is solid on the way, the walk's bypasser blockers, the
# same ones the passers-by steer round. They kick junk aside as they come
# (sweep_junk), never pass through anything, and stay between the walk's
# edges and off each other's toes.
#
# The feel is a cartoon chase: the line barrels on, but a member who meets
# something solid has to get round it, and the more of the line is held up,
# the more the whole line slows to wait for them (pace()). A pile-up on a
# bench is a breather. The catch is theirs, not a line across the street:
# a member's body and what they hold out ahead, and the belt between two
# neighbours while they are still in formation. Split round a pillar, the
# gap between them is open. Get behind the whole line and they have you.
#
# The threat owns the anchor (its front_y, cx, sway), as every chase threat
# does, and calls tick() each frame with it. Members are in world space.
# Tuning knobs are the constants below; per-squad shape is setup()'s.

const SPEED_MULT := 1.55          # how much faster than the line a member can run to catch up
const LATERAL := 190.0            # px/s a member can sidestep
const LOOK := 72.0                # how far ahead a member sees something solid
const SEPARATION := 0.92          # neighbours kept this fraction of their spacing apart
const STUCK_SPEED := 18.0         # under this toward their slot, and far from it, they are held up
const STUCK_FAR := 46.0
const LAG_EASY := 40.0            # a lag the line ignores
const LAG_STOP := 260.0           # the lag at which the line all but waits
const PACE_MIN := 0.28
const BELT_SPAN := 1.35           # neighbours this many spacings apart still hold the belt between them
const BELT_REACH := 16.0
const BEHIND := 70.0              # this far behind the rearmost of them is caught
const SNAP := 420.0               # further than this from the slot (a continue moved the line): put there
const SLIP_SECS := 0.9            # a member who runs through what she left is held up this long
const SLIP_R := 16.0
const CLAMBER_AFTER := 2.5        # held up this long, a member clambers over whatever it is
const CLAMBER_SECS := 0.5

# one per member: {"pos", "vel", "slot", "stuck_t", "lag", "said", "slip_t", "slipped"}
var members: Array[Dictionary] = []
# what they skid in: set by the threat each frame (where she went, left lying)
var slip_points: Array[Vector2] = []
var _slip_said := -1
var radius := 22.0                # a member's body
var reach := 34.0                 # how far ahead of the body their catch reaches
var spacing := 90.0
var back := 70.0                  # the line stands this far behind the anchor
var _blockers: Array = []         # the walk's blockers in a band round the line
var _band := Vector2(INF, -INF)


# `slots`: each member's x offset from the anchor, west to east
func setup(slots: Array, anchor: Vector2, body_r: float, catch_reach: float, line_back: float) -> void:
	radius = body_r
	reach = catch_reach
	back = line_back
	members.clear()
	for sx: float in slots:
		members.append({"pos": anchor + Vector2(sx, -back), "vel": Vector2.ZERO, "slot": sx,
			"stuck_t": 0.0, "lag": 0.0, "said": false, "slip_t": 0.0, "slipped": [], "clamber_t": 0.0})
	spacing = 90.0
	if slots.size() > 1:
		spacing = absf(float(slots[1]) - float(slots[0]))


# Where member i wants to be this frame
func target(i: int, anchor: Vector2) -> Vector2:
	return anchor + Vector2(float(members[i]["slot"]), -back)


# The walk's solids near the line, refreshed as it moves down the walk
func _gather(m: Node2D, y: float) -> void:
	if y > _band.x + 150.0 and y < _band.y - 150.0:
		return
	_band = Vector2(y - 700.0, y + 700.0)
	_blockers.clear()
	for bl: Dictionary in m.bypasser_blockers:
		if bl.has("rect"):
			var r: Rect2 = bl["rect"]
			if r.end.y > _band.x and r.position.y < _band.y:
				_blockers.append(bl)
		else:
			var c: Vector2 = bl["center"]
			if c.y > _band.x and c.y < _band.y:
				_blockers.append(bl)


# Each member a frame closer to its slot. `line_speed` is how fast the
# anchor is going (px/s, down the walk); 0 while the threat is jammed.
func tick(m: Node2D, delta: float, anchor: Vector2, line_speed: float) -> void:
	_gather(m, anchor.y)
	var top := maxf(line_speed, 60.0) * SPEED_MULT
	for i in range(members.size()):
		var mb: Dictionary = members[i]
		var p: Vector2 = mb["pos"]
		var want := target(i, anchor)
		if p.distance_to(want) > SNAP:
			p = _resolve(m, want)
			mb["pos"] = p
			mb["stuck_t"] = 0.0
		var to := want - p
		# skidding in it: carried on a little, flailing, then up again
		if float(mb["slip_t"]) > 0.0:
			mb["slip_t"] = float(mb["slip_t"]) - delta
			var sv: Vector2 = (mb["vel"] as Vector2) * exp(-4.0 * delta)
			mb["vel"] = sv
			mb["pos"] = _resolve(m, p + sv * delta)
			mb["lag"] = maxf(0.0, want.y - (mb["pos"] as Vector2).y)
			mb["stuck_t"] = maxf(float(mb["stuck_t"]), 0.7)
			continue
		for sp: Vector2 in slip_points:
			if p.distance_to(sp) < radius * 0.6 + SLIP_R and not (mb["slipped"] as Array).has(sp):
				(mb["slipped"] as Array).append(sp)
				mb["slip_t"] = SLIP_SECS
				_slip_said = i
		if float(mb["slip_t"]) > 0.0:
			continue
		# run for the slot: forward as fast as they can, sideways a sidestep
		var v := Vector2(clampf(to.x * 4.0, -LATERAL, LATERAL), clampf(to.y * 3.0 + line_speed, -top * 0.4, top))
		if line_speed <= 0.0:
			v.y = clampf(to.y * 3.0, -top * 0.4, top * 0.6)
		# going round something: the sidestep wins over heading for the slot
		var dodge := _dodge(m, p, v)
		if dodge != 0.0:
			v.x = dodge * LATERAL
		# keep off the neighbours
		for j in [i - 1, i + 1]:
			if j < 0 or j >= members.size():
				continue
			var q: Vector2 = members[j]["pos"]
			var d := p - q
			# a held-up member squeezes in: the line bunches round what is in the way
			var near := spacing * SEPARATION
			if float(mb["stuck_t"]) > 0.2 or float(members[j]["stuck_t"]) > 0.2:
				near = maxf(radius * 2.0, near * 0.55)
			if d.length() < near and d.length() > 0.01:
				v += d.normalized() * (near - d.length()) * 6.0
		var before := p
		# held up too long: over it they go, rather than wedged for good
		if float(mb["stuck_t"]) > CLAMBER_AFTER and float(mb.get("clamber_t", 0.0)) <= 0.0:
			mb["clamber_t"] = CLAMBER_SECS
		if float(mb.get("clamber_t", 0.0)) > 0.0:
			mb["clamber_t"] = float(mb["clamber_t"]) - delta
			p = _edges(m, p + Vector2(to.x * 2.0, maxf(to.y * 2.0, top * 0.6)) * delta)
			if float(mb["clamber_t"]) <= 0.0:
				p = _resolve(m, p)
				mb["stuck_t"] = 0.0
		else:
			p = _resolve(m, p + v * delta)
		var moved := (p - before) / maxf(delta, 0.0001)
		mb["vel"] = moved
		mb["pos"] = p
		# held up: far from the slot and not getting nearer to it
		var lag := maxf(0.0, want.y - p.y)
		mb["lag"] = lag
		var gaining := moved.dot(to.normalized()) if to.length() > 0.01 else 0.0
		if to.length() > STUCK_FAR and gaining < STUCK_SPEED:
			mb["stuck_t"] = float(mb["stuck_t"]) + delta
		else:
			mb["stuck_t"] = maxf(0.0, float(mb["stuck_t"]) - delta * 2.0)
			if float(mb["stuck_t"]) <= 0.0:
				mb["said"] = false


# Something solid ahead: which way to sidestep (-1 west, 1 east, 0 clear), the
# shorter way round that a member fits through within the walk's edges
func _dodge(m: Node2D, p: Vector2, v: Vector2) -> float:
	var dir := v.normalized() if v.length() > 1.0 else Vector2.DOWN
	var ahead := p + dir * LOOK
	var best := 0.0
	var best_d := INF
	for bl: Dictionary in _blockers:
		var hit := false
		var cx := 0.0
		var half := 0.0
		if bl.has("rect"):
			var r: Rect2 = (bl["rect"] as Rect2).grow(radius)
			hit = _segment_hits_rect(p, ahead, r)
			cx = r.get_center().x
			half = r.size.x * 0.5
		else:
			var c: Vector2 = bl["center"]
			var rr: float = float(bl["radius"]) + radius
			hit = Geometry2D.get_closest_point_to_segment(c, p, ahead).distance_to(c) < rr
			cx = c.x
			half = rr
		if not hit:
			continue
		var d := absf(_centre_y(bl) - p.y)
		if d >= best_d:
			continue
		best_d = d
		# the shorter way round that fits: a thing against the wall has one way
		var e: Vector2 = m.walk_edges(p.y + LOOK * 0.5)
		var fits_w := cx - half >= e.x + radius
		var fits_e := cx + half <= e.y - radius
		var west := (p.x - (cx - half))
		var east := ((cx + half) - p.x)
		if fits_w and (not fits_e or west < east):
			best = -1.0
		elif fits_e:
			best = 1.0
		else:
			best = 0.0
	return best


static func _centre_y(bl: Dictionary) -> float:
	if bl.has("rect"):
		return (bl["rect"] as Rect2).get_center().y
	return (bl["center"] as Vector2).y


static func _segment_hits_rect(a: Vector2, b: Vector2, r: Rect2) -> bool:
	if r.has_point(a) or r.has_point(b):
		return true
	var corners := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]
	for k in range(4):
		if Geometry2D.segment_intersects_segment(a, b, corners[k], corners[(k + 1) % 4]) != null:
			return true
	return false


# out of anything solid, and inside the walk's edges
func _resolve(m: Node2D, p: Vector2) -> Vector2:
	for _pass in range(2):
		for bl: Dictionary in _blockers:
			if bl.has("rect"):
				var r: Rect2 = (bl["rect"] as Rect2).grow(radius)
				if r.has_point(p):
					var dl := p.x - r.position.x
					var dr := r.end.x - p.x
					var dt := p.y - r.position.y
					var db := r.end.y - p.y
					var mn := minf(minf(dl, dr), minf(dt, db))
					if mn == dl:
						p.x = r.position.x
					elif mn == dr:
						p.x = r.end.x
					elif mn == dt:
						p.y = r.position.y
					else:
						p.y = r.end.y
			else:
				var c: Vector2 = bl["center"]
				var rr: float = float(bl["radius"]) + radius
				var d := p - c
				if d.length() < rr:
					p = c + (d.normalized() if d.length() > 0.01 else Vector2.UP) * rr
	return _edges(m, p)


func _edges(m: Node2D, p: Vector2) -> Vector2:
	var e: Vector2 = m.walk_edges(p.y)
	p.x = clampf(p.x, e.x + radius, e.y - radius)
	return p


# The frame a squad threat (entities/*_threat.gd) runs each step: what she
# left lying for them to skid in (unless `slips` is false: boars love muck),
# the tick, and a word from whoever has just skidded or been held up.
# `held` are their lines when held up, said in turn; `speech` puts them in a
# bubble (people) rather than as a sound (animals).
var _said_n := 0


func run(m: Node2D, delta: float, anchor: Vector2, line_speed: float, slips: bool, held: Array,
		speech: bool, slip_line: String) -> void:
	slip_points.clear()
	if slips and m.has_method("left_business"):
		var lb: Vector2 = m.left_business()
		if lb.x < INF:
			slip_points.append(lb)
	tick(m, delta, anchor, line_speed)
	var sl := newly_slipped()
	var st := newly_stuck()
	if bool(m.get("auto_walk")) or not m.has_method("float_text"):
		return
	var kind: int = int(m.POP_SAY) if speech else -1
	if sl >= 0 and slip_line != "":
		m.float_text((members[sl]["pos"] as Vector2) + Vector2(0.0, -34.0), slip_line, Color(0.92, 0.94, 1.0), kind)
		var sfx := m.get_node_or_null("/root/Sfx")
		if sfx != null:
			sfx.play("squelch", 0.8, -6.0)
	if st >= 0 and not held.is_empty():
		m.float_text((members[st]["pos"] as Vector2) + Vector2(0.0, -34.0), String(held[_said_n % held.size()]),
			Color(0.92, 0.94, 1.0), kind)
		_said_n += 1


# How fast the line goes, as a share of its speed: it waits for the ones held
# up, the more the further behind they are
func pace() -> float:
	if members.is_empty():
		return 1.0
	var lag := 0.0
	for mb: Dictionary in members:
		lag += float(mb["lag"])
	lag /= float(members.size())
	var worst := 0.0
	for mb: Dictionary in members:
		worst = maxf(worst, float(mb["lag"]))
	var k := clampf((maxf(lag, worst * 0.5) - LAG_EASY) / (LAG_STOP - LAG_EASY), 0.0, 1.0)
	return lerpf(1.0, PACE_MIN, k)


# how many are held up on something right now
func held_up() -> int:
	var n := 0
	for mb: Dictionary in members:
		if float(mb["stuck_t"]) > 0.5:
			n += 1
	return n


# the member who has just skidded in it (-1 for none), once
func newly_slipped() -> int:
	var i := _slip_said
	_slip_said = -1
	return i


func clambering(i: int) -> bool:
	return float(members[i].get("clamber_t", 0.0)) > 0.0


func slipping(i: int) -> bool:
	return float(members[i]["slip_t"]) > 0.0


# The one member who has just been held up long enough to complain, once a
# hold-up (-1 for none)
func newly_stuck() -> int:
	for i in range(members.size()):
		var mb: Dictionary = members[i]
		if float(mb["stuck_t"]) > 0.6 and not bool(mb["said"]):
			mb["said"] = true
			return i
	return -1


# the frontmost of them, down the walk (larger y is further down)
func front() -> float:
	var y := -INF
	for mb: Dictionary in members:
		y = maxf(y, (mb["pos"] as Vector2).y + reach)
	return y


func rear() -> float:
	var y := INF
	for mb: Dictionary in members:
		y = minf(y, (mb["pos"] as Vector2).y)
	return y


# whether neighbours i and i + 1 still hold the belt between them
func belt_held(i: int) -> bool:
	if i < 0 or i + 1 >= members.size():
		return false
	var a: Vector2 = members[i]["pos"]
	var b: Vector2 = members[i + 1]["pos"]
	return a.distance_to(b) < spacing * BELT_SPAN


func caught(p: Vector2) -> bool:
	if members.is_empty():
		return false
	for mb: Dictionary in members:
		var q: Vector2 = mb["pos"]
		# the body, and the reach ahead of it
		if Geometry2D.get_closest_point_to_segment(p, q, q + Vector2(0.0, reach)).distance_to(p) < radius + 6.0:
			return true
	for i in range(members.size() - 1):
		if belt_held(i):
			var a: Vector2 = (members[i]["pos"] as Vector2) + Vector2(0.0, reach * 0.6)
			var b: Vector2 = (members[i + 1]["pos"] as Vector2) + Vector2(0.0, reach * 0.6)
			if Geometry2D.get_closest_point_to_segment(p, a, b).distance_to(p) < BELT_REACH:
				return true
	return p.y < rear() - BEHIND


# Kicks aside junk a member runs into; returns how many were kicked
func sweep_junk(junk: Array) -> int:
	var n := 0
	for c: Node2D in junk:
		if not is_instance_valid(c) or not c.has_method("_kick_by"):
			continue
		for mb: Dictionary in members:
			var q: Vector2 = mb["pos"]
			if absf(c.global_position.y - q.y) > radius + reach + 20.0:
				continue
			var v: Vector2 = mb["vel"]
			if v.length() < 20.0:
				continue
			if c.global_position.distance_to(q + Vector2(0.0, reach * 0.4)) < radius + 14.0:
				c._kick_by(q, v, radius + 30.0)
				n += 1
	return n


# member positions, for a test or the playtest's watch
func points() -> Array[Vector2]:
	var out: Array[Vector2] = []
	for mb: Dictionary in members:
		out.append(mb["pos"])
	return out
