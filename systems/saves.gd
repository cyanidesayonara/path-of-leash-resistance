extends RefCounted

# What makes a save a SAVE (main.on_stumble_save): she yanked your human back
# while something that knocks them over - a bike, the road train - was
# actually coming at them. A bike that has already gone by, or one riding
# away, or one passing well wide, was never going to cost the phone, so
# yanking him then is just yanking him. Pure geometry, tested headless.

# how far ahead to look, and how close a pass counts as a hit
const HORIZON := 1.1
const RADIUS := 46.0


# A rider at `pos` going `vel` passes within `radius` of `target` in the
# next `horizon` seconds, and is coming toward it, not leaving.
static func threatens(pos: Vector2, vel: Vector2, target: Vector2, horizon: float, radius: float) -> bool:
	var v2 := vel.length_squared()
	if v2 < 1.0:
		return false
	var rel := target - pos
	var along := rel.dot(vel)
	if along <= 0.0:
		return false
	var t := minf(along / v2, horizon)
	return (pos + vel * t).distance_to(target) < radius


# The road train's body `r`, heading `dir` (+1 / -1 along x) at `speed`,
# sweeps over `target` within `horizon` seconds (padded by `pad`).
static func train_threatens(r: Rect2, dir: float, speed: float, target: Vector2, horizon: float, pad: float) -> bool:
	var now := r.grow(pad)
	var later := Rect2(now.position + Vector2(dir * speed * horizon, 0.0), now.size)
	return now.merge(later).has_point(target)
