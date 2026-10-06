extends RefCounted

# Pure geometry for the leash-vault. Lives on its own, with no dependency on
# the autoloads, so it can be tested by a bare `--script` run - the same
# reason teeter.gd and grind.gd are separate modules.
#
# The one decision here is which WAY she carves around a wrapped pole, and a
# flipped sign would fling her backwards into the pole instead of around it,
# so it is worth isolating and pinning.

static func vault_tangent(pole: Vector2, pos: Vector2, vel: Vector2) -> Vector2:
	var radial := pos - pole
	if radial.length() < 0.001:
		return Vector2.ZERO
	# perpendicular to the rope - a true circular carve, never radial
	var t := radial.orthogonal().normalized()
	# ...taken on whichever side she is already travelling, so a vault always
	# continues her momentum instead of reversing it
	if t.dot(vel) < 0.0:
		t = -t
	return t


# Which way she is going round a pole: +1 one way, -1 the other, 0 when she
# is not going round it at all.
static func sense(pole: Vector2, pos: Vector2, vel: Vector2) -> float:
	var c := (pos - pole).cross(vel)
	if absf(c) < 0.001:
		return 0.0
	return signf(c)


# A FIGURE EIGHT: this swing and the one before it went opposite ways round
# two different posts. `prev` is the last swing ({"pole", "sense"}), empty
# when there was none or it has lapsed.
static func is_figure_eight(prev: Dictionary, pole: Vector2, s: float, min_apart: float) -> bool:
	if prev.is_empty() or s == 0.0:
		return false
	if (prev["pole"] as Vector2).distance_to(pole) < min_apart:
		return false
	return float(prev["sense"]) == -s


# THREAD THE NEEDLE: her step this frame, p0 to p1, passes between two people
# at a and b, no further apart than max_gap (and not so close there is no
# gap at all).
static func crosses_gap(p0: Vector2, p1: Vector2, a: Vector2, b: Vector2, min_gap: float, max_gap: float) -> bool:
	var gap := a.distance_to(b)
	if gap < min_gap or gap > max_gap:
		return false
	return Geometry2D.segment_intersects_segment(p0, p1, a, b) != null
