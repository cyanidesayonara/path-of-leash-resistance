class_name ChaseVehicle
extends RefCounted

const ShapeBatch := preload("res://systems/shape_batch.gd")

# A chase threat that is one big cartoon machine (the street sweeper, the
# Dimoni's float): it barrels down the walk and cares about what is in its
# way only as far as a cartoon would. Heavy things it cannot flatten (a
# parked van, a stall, a fountain, a statue, the walk's own solid blocks) it
# swerves round, hard, if there is room beside them; light ones (posts,
# hydrants, benches) it bonks straight over, juddering and losing a little
# speed, sparks and bits flying. Where a walk wants it stopped, its authored
# jams still hold it: those are the rest and save points.
#
# It reads the walk's bypasser blockers, the same list the passers-by steer
# round, and decides heavy or light by what each one is (its id).
# A heavy thing it could not get round stops it dead for a moment when it
# hits it (slam), the crash and shudder of a cartoon, and then it smashes on
# through: an unplanned breather, besides the walk's authored jams.
# The threat owns its movement; this only answers three questions each frame:
# where to swerve to (dodge_sway), what it has just run over (bonk), and
# what it has just slammed into (slam).

const LOOK := 260.0               # how far ahead of its nose it sees what is coming
const BONK_SECS := 0.35           # the judder of running something over
const BONK_SLOW := 0.78           # its speed while it judders
const SLAM_SECS := 1.3            # how long a heavy thing it hits holds it
# what it flattens rather than goes round, by blocker id
const LIGHT := ["pole_", "hydrant_", "bench_"]
# what it neither goes round nor feels: flat on the ground
const FLAT := ["manhole_", "cellar_"]

var bonk_t := 0.0
var bonk_at := Vector2(INF, INF)  # where the last bonk was, world space
var _bonked := {}                 # ids already run over, once each
var _slammed := {}                # ids already slammed into, once each
var _debris: Array[Dictionary] = []  # {"p", "v", "t", "c"} world space
var _blockers: Array = []
var _band := Vector2(INF, -INF)


static func _is(id: String, kinds: Array) -> bool:
	for k: String in kinds:
		if id.begins_with(k):
			return true
	return false


func _gather(m: Node2D, y: float) -> void:
	if y > _band.x + 200.0 and y < _band.y - 400.0:
		return
	_band = Vector2(y - 500.0, y + 900.0)
	_blockers.clear()
	for bl: Dictionary in m.bypasser_blockers:
		var id := String(bl.get("id", ""))
		if _is(id, FLAT):
			continue
		var r := _rect(bl)
		if r.end.y > _band.x and r.position.y < _band.y:
			_blockers.append(bl)


static func _rect(bl: Dictionary) -> Rect2:
	if bl.has("rect"):
		return bl["rect"]
	var c: Vector2 = bl["center"]
	var rr: float = float(bl["radius"])
	return Rect2(c - Vector2(rr, rr), Vector2(rr, rr) * 2.0)


# Where it wants its centre (an x offset from `cx`, like the threat's sway)
# to get round the nearest heavy thing in its lane ahead of `nose_y`, or
# NAN when its lane is clear or there is no room either side. `half_w` is
# its half width; `room` how far it may sway from the centre line.
func dodge_sway(m: Node2D, cx: float, sway: float, nose_y: float, half_w: float, room: float) -> float:
	_gather(m, nose_y)
	var best := NAN
	var best_d := INF
	for bl: Dictionary in _blockers:
		var id := String(bl.get("id", ""))
		if _is(id, LIGHT):
			continue
		var r := _rect(bl)
		# ahead of the nose (down the walk), within sight
		if r.end.y < nose_y - 20.0 or r.position.y > nose_y + LOOK:
			continue
		var x0 := cx + sway - half_w - 10.0
		var x1 := cx + sway + half_w + 10.0
		if r.end.x < x0 or r.position.x > x1:
			continue
		var d := r.position.y - nose_y
		if d >= best_d:
			continue
		# the roomier side, if it fits there at all
		var west := (r.position.x - half_w - 14.0) - cx
		var east := (r.end.x + half_w + 14.0) - cx
		var can_w := west >= -room
		var can_e := east <= room
		if not can_w and not can_e:
			continue
		var go := west if can_w and (not can_e or absf(west - sway) <= absf(east - sway)) else east
		best = go
		best_d = d
	return best


# Whether its body (a rect in world space) has just run over something light,
# once each; starts the judder and throws the bits. True on the frame it does.
func bonk(m: Node2D, body: Rect2, delta: float) -> bool:
	bonk_t = maxf(0.0, bonk_t - delta)
	for i in range(_debris.size() - 1, -1, -1):
		var d: Dictionary = _debris[i]
		d["t"] = float(d["t"]) - delta
		d["p"] = (d["p"] as Vector2) + (d["v"] as Vector2) * delta
		d["v"] = (d["v"] as Vector2) * exp(-3.0 * delta)
		if float(d["t"]) <= 0.0:
			_debris.remove_at(i)
	var hit := false
	for bl: Dictionary in _blockers:
		var id := String(bl.get("id", ""))
		if not _is(id, LIGHT) or _bonked.has(id):
			continue
		var r := _rect(bl)
		if not body.intersects(r):
			continue
		_bonked[id] = true
		bonk_t = BONK_SECS
		bonk_at = r.get_center()
		hit = true
		for k in range(10):
			var a := -PI * 0.5 + (float(k) / 9.0 - 0.5) * 2.6
			_debris.append({"p": bonk_at, "v": Vector2.from_angle(a) * (120.0 + float(k % 3) * 70.0) + Vector2(0.0, 90.0),
				"t": 0.5 + float(k % 4) * 0.08, "c": k % 3})
	return hit


# Whether its body has just hit something heavy (it could not swerve round),
# once each; throws the bits like a bonk. The threat holds it SLAM_SECS.
# Returns the side the thing was on (-1 west, 1 east) or 0 for none.
func slam(m: Node2D, body: Rect2, cx: float) -> float:
	for bl: Dictionary in _blockers:
		var id := String(bl.get("id", ""))
		if _is(id, LIGHT) or _slammed.has(id):
			continue
		var r := _rect(bl)
		if not body.grow(-8.0).intersects(r):
			continue
		_slammed[id] = true
		bonk_t = BONK_SECS
		bonk_at = Vector2(r.get_center().x, body.end.y)
		for k in range(16):
			var a := -PI * 0.5 + (float(k) / 15.0 - 0.5) * 3.0
			_debris.append({"p": bonk_at, "v": Vector2.from_angle(a) * (160.0 + float(k % 4) * 60.0) + Vector2(0.0, 120.0),
				"t": 0.6 + float(k % 4) * 0.08, "c": k % 3})
		return signf(r.get_center().x - cx) if absf(r.get_center().x - cx) > 1.0 else 1.0
	return 0.0


# its speed share while it judders over something
func pace() -> float:
	return BONK_SLOW if bonk_t > 0.0 else 1.0


# the judder, for drawing: an offset to add to its body
func jolt() -> Vector2:
	if bonk_t <= 0.0:
		return Vector2.ZERO
	var k := bonk_t / BONK_SECS
	return Vector2(sin(bonk_t * 70.0) * 4.0 * k, -absf(sin(bonk_t * 26.0)) * 7.0 * k)


# the bits flying off what it ran over, in the threat's local space (`origin`
# is the threat's world position); sparks, chips of paint, a bolt or two
func draw_debris(b: ShapeBatch, origin: Vector2) -> void:
	for d: Dictionary in _debris:
		var p: Vector2 = (d["p"] as Vector2) - origin
		var t: float = d["t"]
		var a := clampf(t / 0.5, 0.0, 1.0)
		match int(d["c"]):
			0:
				b.line(p, p - (d["v"] as Vector2) * 0.03, Color(1.0, 0.86, 0.40, a), 2.6)
			1:
				b.rect(Rect2(p - Vector2(2.5, 2.5), Vector2(5.0, 5.0)), Color(0.36, 0.38, 0.42, a))
			_:
				b.circle(p, 2.6, Color(0.92, 0.92, 0.90, a))
	if bonk_t > 0.0:
		var k := bonk_t / BONK_SECS
		var at := bonk_at - origin
		b.glow(at, 46.0 * (1.4 - k), Color(1.0, 0.90, 0.60, 0.5 * k), 0.2)
		for i in range(8):
			var a2 := float(i) * TAU / 8.0
			b.line(at + Vector2.from_angle(a2) * (14.0 + (1.0 - k) * 20.0), at + Vector2.from_angle(a2) * (26.0 + (1.0 - k) * 30.0),
				Color(1.0, 1.0, 1.0, 0.9 * k), 3.0)
