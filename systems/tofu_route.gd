extends RefCounted

# Where Tofu hides on the way home. Every hiding spot has to be ground Millie
# can reach and every dart between two has to be clear, or the goal cannot be
# finished: spots must sit on the path at their own y (walks bend), clear of
# solid rects, water and static bodies, and the last one short of the home
# line so the walk cannot end while she is still running to it.

const SPOTS := 7
const FIRST_AFTER_GATE := 500.0
# her last spot is 70 px short of where the arrival starts, which is
# Arrival.WALK_IN (140) north of HOME_Y: past it the walk freezes for the
# walk in, and a spot south of it could never be reached
const LAST_BEFORE_HOME := 210.0
const EDGE_MARGIN := 40.0
const BODY_R := 14.0
const DART_STEP := 16.0
const MIN_GAP_Y := 240.0
const DOG_MASK := 1 | 8
# across the path from its centre, as a fraction of the half-width, best first
const SIDE_FRACS := [0.6, 0.45, 0.75, 0.3, 0.15, 0.0]
const HOME_FRACS := [0.0, 0.2, -0.2, 0.4, -0.4]
const Y_NUDGES := [0.0, 70.0, -70.0, 140.0, -140.0, 210.0, -210.0]


# how many of a spot's good candidates are tried with a detour when none of
# them has a straight dart
const DETOUR_TRIES := 6
const WAY_FRACS := [0.0, 0.5, -0.5, 0.8, -0.8, 0.25, -0.25]
const WAY_TS := [0.5, 0.35, 0.65, 0.2, 0.8]


# {"spots": hiding spots north to south, "routes": for each spot after the
# first, the waypoints she runs through on the dart that ends there}
static func plan(m: Node2D) -> Dictionary:
	var spots: Array[Vector2] = []
	var routes: Array = []
	var prev := Vector2.INF
	var top: float = m.GATE_Y + FIRST_AFTER_GATE
	var bottom: float = m.HOME_Y - LAST_BEFORE_HOME
	for i in range(SPOTS):
		var last := i == SPOTS - 1
		var ty := lerpf(top, bottom, float(i) / float(SPOTS - 1))
		var side := 1.0 if i % 2 == 0 else -1.0
		var fracs: Array = HOME_FRACS
		if not last:
			# her own side of the path first, then the other where a wall
			# down the middle keeps the two apart
			fracs = []
			for f: float in SIDE_FRACS:
				fracs.append(side * f)
			for f: float in SIDE_FRACS:
				fracs.append(-side * f)
		var good: Array[Vector2] = []
		var best := Vector2.INF
		var way: Array[Vector2] = []
		for dy: float in Y_NUDGES:
			var y := ty + dy
			if last and dy > 0.0:
				continue
			if prev.x < INF and y < prev.y + MIN_GAP_Y:
				continue
			for frac: float in fracs:
				var p := across(m, y, frac)
				if not point_ok(m, p):
					continue
				good.append(p)
				if prev.x >= INF or leg_ok(m, prev, p):
					best = p
					break
			if best.x < INF:
				break
		if best.x >= INF:
			for k in range(mini(DETOUR_TRIES, good.size())):
				var d: Variant = detour(m, prev, good[k])
				if d != null:
					best = good[k]
					way = d
					break
		if best.x >= INF and not good.is_empty():
			best = good[0]
		if best.x >= INF:
			continue
		if prev.x < INF:
			routes.append(way)
		spots.append(best)
		prev = best
	return {"spots": spots, "routes": routes}


static func plan_spots(m: Node2D) -> Array[Vector2]:
	return plan(m)["spots"]


# one or two waypoints that get her from a to b round what is in the way, or
# null when there is no such run
static func detour(m: Node2D, a: Vector2, b: Vector2) -> Variant:
	for t: float in WAY_TS:
		for frac: float in WAY_FRACS:
			var w := across(m, lerpf(a.y, b.y, t), frac)
			if point_ok(m, w) and leg_ok(m, a, w) and leg_ok(m, w, b):
				return [w] as Array[Vector2]
	for f1: float in WAY_FRACS:
		var w1 := across(m, lerpf(a.y, b.y, 0.33), f1)
		if not point_ok(m, w1) or not leg_ok(m, a, w1):
			continue
		for f2: float in WAY_FRACS:
			var w2 := across(m, lerpf(a.y, b.y, 0.67), f2)
			if point_ok(m, w2) and leg_ok(m, w1, w2) and leg_ok(m, w2, b):
				return [w1, w2] as Array[Vector2]
	return null


# a point `frac` of the half-width from the path's centre at y (negative is left)
static func across(m: Node2D, y: float, frac: float) -> Vector2:
	var e: Vector2 = m.walk_edges(y)
	var cx := (e.x + e.y) * 0.5
	var half := maxf(0.0, (e.y - e.x) * 0.5 - EDGE_MARGIN)
	return Vector2(cx + half * frac, y)


static func point_ok(m: Node2D, p: Vector2, margin := EDGE_MARGIN) -> bool:
	var e: Vector2 = m.walk_edges(p.y)
	if p.x < e.x + margin or p.x > e.y - margin:
		return false
	for r: Rect2 in m.solid_rects:
		if r.grow(BODY_R).has_point(p):
			return false
	for w: Rect2 in m.water:
		if w.grow(BODY_R).has_point(p):
			return false
	if m.pond.size.x > 0.0 and m.pond.grow(BODY_R).has_point(p):
		return false
	return not static_hit(m, p)


static func leg_ok(m: Node2D, a: Vector2, b: Vector2) -> bool:
	var n := maxi(1, int(a.distance_to(b) / DART_STEP))
	for k in range(1, n):
		if not point_ok(m, a.lerp(b, float(k) / float(n)), 0.0):
			return false
	return true


static var _query: PhysicsShapeQueryParameters2D = null


static func static_hit(m: Node2D, p: Vector2) -> bool:
	if _query == null:
		_query = PhysicsShapeQueryParameters2D.new()
		var c := CircleShape2D.new()
		c.radius = BODY_R
		_query.shape = c
		_query.collision_mask = DOG_MASK
	_query.transform = Transform2D(0.0, p)
	for hit: Dictionary in m.get_world_2d().direct_space_state.intersect_shape(_query, 8):
		if hit.get("collider") is StaticBody2D:
			return true
	return false
