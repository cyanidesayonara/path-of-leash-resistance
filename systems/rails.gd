extends RefCounted

# THE GRINDABLES. A grind is a trick, so it needs something to grind: not the
# edge of the path (running along the border of path and grass is not a
# trick, and every walk had two of them under her paws all the time), but
# things built to be ridden - a hedge's clipped top, the serpentine bench, a
# terrace wall, an escalator's handrail, the tutorial's stone ledge.
#
# A rail is {"pts": PackedVector2Array, "name": String}: a polyline she rides
# in either direction, and the name she shouts and the combo scores (the same
# word in both places). Static functions over main's state, like the other
# systems; main.rails holds the walk's list.

const LevelBuild := preload("res://world/level_build.gd")
const TutorialSteps := preload("res://systems/tutorial.gd")

# how close to a rail's line she has to be to get up on it, at speed
const MOUNT_BAND := 18.0
# how squarely along it she has to be travelling: the cosine of the angle
const ALONG := 0.8
# the tutorial's stone ledge, beside the path at the grind lesson
const TUT_LEDGE_X := 760.0
const TUT_LEDGE_HALF := 200.0


static func rail(pts: PackedVector2Array, name: String) -> Dictionary:
	return {"pts": pts, "name": name}


static func line(a: Vector2, b: Vector2, name: String) -> Dictionary:
	return rail(PackedVector2Array([a, b]), name)


# The walk's grindables, once its edges and props are laid out.
static func build(m: Node2D) -> void:
	m.rails.clear()
	if m.tutorial_mode:
		var at := TutorialSteps.at("grind")
		m.rails.append(line(Vector2(TUT_LEDGE_X, at + TUT_LEDGE_HALF), Vector2(TUT_LEDGE_X, at - TUT_LEDGE_HALF), "LEDGE RUN"))
		return
	match String(m.lvl):
		"park":
			# the flowerbeds' clipped hedge edging, both long sides of each
			for bed: Rect2 in LevelBuild.PARK_BEDS:
				for bx: float in [bed.position.x, bed.end.x]:
					m.rails.append(line(Vector2(bx, bed.end.y), Vector2(bx, bed.position.y), "HEDGE RUN"))
		"guell":
			# the serpentine bench runs round the plaza: both of its edges
			for side in range(2):
				var pts := PackedVector2Array()
				var y := LevelBuild.MOSAIC_PLAZA_Y0
				while y >= LevelBuild.MOSAIC_PLAZA_Y1:
					var e: Vector2 = m.walk_edges(y)
					pts.append(Vector2(e.x if side == 0 else e.y, y))
					y -= 40.0
				m.rails.append(rail(pts, "BENCH GRIND"))
		"montjuic":
			# the terrace walls, path to rim on either side, and the
			# escalators' outer handrails
			for wy: float in Montjuic.terrace_ys(m):
				var e2: Vector2 = m.walk_edges(wy)
				var cx := (e2.x + e2.y) * 0.5
				var hh := Montjuic.hill_half(m, wy)
				if e2.x - 12.0 - (cx - hh + 30.0) > 120.0:
					m.rails.append(line(Vector2(cx - hh + 30.0, wy - 3.0), Vector2(e2.x - 12.0, wy - 3.0), "WALL WALK"))
				if cx + hh - 30.0 - (e2.y + 12.0) > 120.0:
					m.rails.append(line(Vector2(e2.y + 12.0, wy - 3.0), Vector2(cx + hh - 30.0, wy - 3.0), "WALL WALK"))
			var z: Rect2 = m.conveyor_zone
			if z.size.y > 0.0:
				for hx: float in [z.position.x - 1.0, z.end.x + 1.0]:
					m.rails.append(line(Vector2(hx, z.end.y), Vector2(hx, z.position.y), "HANDRAIL"))


# The nearest point of a rail to p: {"q": point, "dir": unit direction of that
# segment, "s": distance along the rail, "len": its whole length, "d": how
# far p is from q}.
static func nearest(r: Dictionary, p: Vector2) -> Dictionary:
	var pts: PackedVector2Array = r["pts"]
	var best := {"q": pts[0], "dir": Vector2.RIGHT, "s": 0.0, "len": 0.0, "d": INF}
	var run := 0.0
	for i in range(pts.size() - 1):
		var a := pts[i]
		var b := pts[i + 1]
		var ab := b - a
		var l := ab.length()
		if l < 0.001:
			continue
		var f := clampf((p - a).dot(ab) / (l * l), 0.0, 1.0)
		var q := a + ab * f
		var d := p.distance_to(q)
		if d < float(best["d"]):
			best = {"q": q, "dir": ab / l, "s": run + l * f, "len": 0.0, "d": d}
		run += l
	best["len"] = run
	return best


# The rail she could get up on now, or -1: near its line, travelling along it.
static func mountable(m: Node2D, p: Vector2, vel: Vector2) -> int:
	var sp := vel.length()
	if sp < 1.0:
		return -1
	for i in range(m.rails.size()):
		var n := nearest(m.rails[i], p)
		if float(n["d"]) > MOUNT_BAND:
			continue
		if absf(vel.dot(n["dir"])) / sp < ALONG:
			continue
		# not right at an end, where there is no rail left to ride
		if float(n["s"]) < 4.0 or float(n["s"]) > float(n["len"]) - 4.0:
			continue
		return i
	return -1


# The balance's sideways: perpendicular to the rail, pointing right on the
# screen for an upright rail and down for a level one, so the stick and the
# balance bar agree whichever way she rides.
static func side(dir: Vector2) -> Vector2:
	var n := Vector2(-dir.y, dir.x)
	if absf(n.x) >= absf(n.y):
		return n if n.x >= 0.0 else -n
	return n if n.y >= 0.0 else -n
