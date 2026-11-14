class_name Shade
extends RefCounted

# The one light every object's shadow obeys. By day the sun throws shadows
# long to the lower right. After dark there is no sun: the light is diffuse
# (sky glow, lamps all round), so each object keeps only a short soft pool
# where it meets the ground, still leaning the same way so nothing jumps.
# main sets it as a walk starts; the day value is the old constant exactly.

const SUN := Vector2(0.5, 0.866)
const NIGHT_THROW := 0.22

# the direction and length shadows fall (unit length by day)
static var light := SUN
# how far shadows are thrown, for scripts that keep their own sun direction
static var throw := 1.0


static func set_night(night: bool) -> void:
	throw = NIGHT_THROW if night else 1.0
	light = SUN * throw
