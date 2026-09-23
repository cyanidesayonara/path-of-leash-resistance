extends RefCounted

# A CORRIDOR EDGE AS A FUNCTION OF Y.
#
# Every path in this game is two straight vertical lines, because the edges
# are plain floats (sw_l / sw_r) with no y term in them. That is the whole
# reason the world looks blocky: not the drawing, the geometry. There is
# exactly one edge anywhere that varies with y - the beach shoreline - and it
# is a straight diagonal that gameplay approximates with a stack of 36px
# horizontal water strips, PRECISELY BECAUSE nothing here could express a
# slanted edge.
#
# So the edge becomes a curve, sampled by y, and both the renderer and the
# things that ask "am I on the path" read the same function. A street can
# then weave, narrow at a pinch point and open out into a square, and the
# collision, the surface under her paws and the painted kerb all agree
# because they are all asking the same question.
#
# The shape is a short list of control nodes - a y, a centre and a half-width
# - interpolated with smoothstep so the path eases between them instead of
# turning corners. Few enough per level to author by hand and to read in a
# diff; smooth enough that nobody can see the joins.
#
# Pure math, no nodes and no drawing, so it tests headless.
#
# A level with no nodes is a straight corridor at its nominal width, exactly
# as before - which is what let this land as a refactor that changes nothing
# before any level actually bends.

# Beyond the last node the path holds that node's shape rather than
# extrapolating, so authoring three nodes in the middle of a level cannot
# accidentally send the far ends off into the buildings.


static func sample(nodes: Array, y: float, base_cx: float, base_half: float) -> Vector2:
	# returns (centre, half_width) at this y.
	#
	# Nodes are authored in WALK ORDER - down the level, which is decreasing y,
	# because the walk starts at START_Y 260 and ends at GATE_Y -5000. Every
	# other placement array in this game is written that way, so the shape of
	# the path should read in a diff the same way the props do.
	if nodes.is_empty():
		return Vector2(base_cx, base_half)
	var first: Dictionary = nodes[0]
	if y >= float(first["y"]):
		return Vector2(float(first["cx"]), float(first["half"]))
	var last: Dictionary = nodes[nodes.size() - 1]
	if y <= float(last["y"]):
		return Vector2(float(last["cx"]), float(last["half"]))
	for i in range(nodes.size() - 1):
		var a: Dictionary = nodes[i]
		var b: Dictionary = nodes[i + 1]
		var ay := float(a["y"])
		var by := float(b["y"])
		if y > ay or y < by:
			continue
		var span := ay - by
		var t: float = 0.0 if span <= 0.0 else (ay - y) / span
		# smoothstep, so the path eases in and out of a bend instead of
		# arriving at it on a corner
		t = t * t * (3.0 - 2.0 * t)
		return Vector2(lerpf(float(a["cx"]), float(b["cx"]), t),
			lerpf(float(a["half"]), float(b["half"]), t))
	return Vector2(base_cx, base_half)


static func edges(nodes: Array, y: float, base_cx: float, base_half: float) -> Vector2:
	# returns (left_x, right_x) at this y, which is what most callers want
	var s := sample(nodes, y, base_cx, base_half)
	return Vector2(s.x - s.y, s.x + s.y)


static func valid(nodes: Array, min_half: float = 60.0) -> Dictionary:
	# Authoring guard, used by the level self-test. A path that doubles back
	# on itself in y, or pinches to nothing, is a level that cannot be walked -
	# and it is far easier to catch that here than to discover it as a dog
	# stuck in a wall halfway up a chase.
	if nodes.is_empty():
		return {"ok": true, "why": ""}
	# walk order: each node must be further NORTH than the last, i.e. a
	# smaller y. A list that doubles back would make sample() return whichever
	# span it happened to meet first, which is a bug that would only show up
	# as one stretch of pavement mysteriously ignoring its own kerb.
	var prev_y := INF
	for i in range(nodes.size()):
		var n: Dictionary = nodes[i]
		for key: String in ["y", "cx", "half"]:
			if not n.has(key):
				return {"ok": false, "why": "node %d has no %s" % [i, key]}
		var ny := float(n["y"])
		if ny >= prev_y:
			return {"ok": false, "why": "node %d y=%.0f does not advance north (previous %.0f)" % [
				i, ny, prev_y]}
		prev_y = ny
		if float(n["half"]) < min_half:
			return {"ok": false, "why": "node %d is only %.0f wide, under the %.0f minimum" % [
				i, float(n["half"]), min_half]}
	return {"ok": true, "why": ""}


static func max_slope(nodes: Array, samples_per_span: int = 24) -> float:
	# How far sideways the path moves per unit travelled south, at its worst.
	# A corridor that slides sideways faster than a dog can strafe is a wall
	# you cannot see coming, so the self-test holds this to a sane number.
	if nodes.size() < 2:
		return 0.0
	var worst := 0.0
	for i in range(nodes.size() - 1):
		var a: Dictionary = nodes[i]
		var b: Dictionary = nodes[i + 1]
		var ay := float(a["y"])
		var by := float(b["y"])
		# walk order, so b is north of a and the span is ay - by
		if by >= ay:
			continue
		var prev := sample(nodes, ay, 0.0, 0.0)
		var dy := (ay - by) / float(samples_per_span)
		for s in range(1, samples_per_span + 1):
			var y := lerpf(ay, by, float(s) / float(samples_per_span))
			var cur := sample(nodes, y, 0.0, 0.0)
			if dy > 0.0:
				worst = maxf(worst, absf(cur.x - prev.x) / dy)
			prev = cur
	return worst
