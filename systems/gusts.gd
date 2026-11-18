extends RefCounted

# The wind with real power: on a windy sky (Game.wind_amount() at GUST_FROM or
# more: a breeze, a storm, a gale) it comes in gusts. Each is telegraphed
# GUST_WARN ahead, as every hazard is: a whoosh, and the overlay's leaves and
# grit rushing. Then it shoves the dog and your human downwind for GUST_S,
# swelling and dying; the leash bows with it and litter takes off
# (entities/litter.gd reads wind_gust). A planted dog holds her ground. By the
# sea the wind blows onshore: it comes off whichever side of the walk is
# water. Montjuïc keeps its own hill wind (systems/montjuic.gd).
#
# The gust's state is main's (wind_warn, wind_gust, wind_dir, wind_next,
# wind_rng), shared with Montjuïc's, so the overlay and the litter read one
# wind wherever it comes from.

const Surfaces := preload("res://world/surfaces.gd")

const GUST_FROM := 0.5             # the wind strength gusts start at
const GUST_WARN := 0.8
const GUST_S := 1.2
const GUST_FORCE := 420.0          # px/s/s on the dog in a full gale
const HUMAN_SHARE := 0.45          # your human, heavier, catches less of it
const PLANTED_SHARE := 0.2         # a planted dog barely moves
const GUST_EVERY := Vector2(7.0, 13.0)   # seconds between gusts in a full gale
const LEASH_BOW := 0.55            # how far the rope's middle bows, per unit of push
const SEA_PROBE: Array[float] = [360.0, 520.0, 700.0, 900.0]   # how far out to each side to look for the sea


static func windy() -> bool:
	return Game.wind_amount() >= GUST_FROM


# where the wind blows toward: off the sea when one side of the walk is
# water, otherwise from the west most of the time (the city's garbí)
static func wind_dir(m: Node2D, y: float) -> Vector2:
	var left := sea_on(m, y, -1.0)
	var right := sea_on(m, y, 1.0)
	if left != right:
		return Vector2(1.0 if left else -1.0, -0.12).normalized()
	var s := 1.0 if m.wind_rng.randf() < 0.7 else -1.0
	return Vector2(s, m.wind_rng.randf_range(-0.2, 0.2)).normalized()


# water out to one side of the walk at this point (-1 west, +1 east)
static func sea_on(m: Node2D, y: float, side: float) -> bool:
	for d: float in SEA_PROBE:
		if int(m.surface_at(Vector2(float(m.walk_cx) + side * d, y))) == Surfaces.S.WATER:
			return true
	return false


static func _quiet(m: Node2D) -> bool:
	return bool(m.frozen) or String(m.phase) == "freedom" or String(m.lvl) == "tutorial" \
		or String(m.lvl) == "montjuic"


static func tick(m: Node2D, delta: float) -> void:
	if not windy() or _quiet(m):
		return
	var wk := Game.wind_amount()
	if not bool(m.wind_rng_seeded):
		m.wind_rng.seed = hash(String(m.lvl)) ^ 0x6057
		m.wind_rng_seeded = true
		m.wind_next = _every(m, wk) * 0.5
	if float(m.wind_gust) > 0.0:
		m.wind_gust = maxf(float(m.wind_gust) - delta, 0.0)
		var swell := sin(PI * clampf(1.0 - float(m.wind_gust) / GUST_S, 0.0, 1.0))
		var f: float = GUST_FORCE * wk * swell * delta
		var dir: Vector2 = m.wind_dir
		m.dog.velocity += dir * f * (PLANTED_SHARE if bool(m.dog.planted) else 1.0)
		m.human.velocity += dir * f * HUMAN_SHARE
		bow_leash(m.leash, dir * swell * wk * LEASH_BOW)
		return
	if float(m.wind_warn) > 0.0:
		m.wind_warn = maxf(float(m.wind_warn) - delta, 0.0)
		if float(m.wind_warn) <= 0.0:
			m.wind_gust = GUST_S
		return
	m.wind_next = float(m.wind_next) - delta
	if float(m.wind_next) <= 0.0:
		m.wind_warn = GUST_WARN
		m.wind_next = _every(m, wk)
		m.wind_dir = wind_dir(m, m.dog.global_position.y)
		Sfx.play("hiss", 0.4 + 0.2 * wk, -9.0 + 4.0 * wk)


static func _every(m: Node2D, wk: float) -> float:
	return m.wind_rng.randf_range(GUST_EVERY.x, GUST_EVERY.y) / clampf(wk, 0.4, 1.0)


# 0 to 1: how much of a gust is blowing now, the telegraph's rise included
static func push(m: Node2D) -> float:
	if float(m.wind_gust) > 0.0:
		return sin(PI * clampf(1.0 - float(m.wind_gust) / GUST_S, 0.0, 1.0))
	if float(m.wind_warn) > 0.0:
		return 0.35 * (1.0 - float(m.wind_warn) / GUST_WARN)
	return 0.0


# The rope's middle carried downwind, its ends left to the dog and the hand:
# each inner point is moved by `by` times how far it is from the nearer end,
# on the current points only, so the verlet step reads it as the wind's push.
static func bow_leash(leash: Node, by: Vector2) -> void:
	if leash == null:
		return
	var pts: Array[Vector2] = leash.pts
	var n := pts.size()
	if n < 3:
		return
	for i in range(1, n - 1):
		var u := float(i) / float(n - 1)
		pts[i] += by * (1.0 - absf(2.0 * u - 1.0))
