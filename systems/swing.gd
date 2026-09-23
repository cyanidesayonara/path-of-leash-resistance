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
