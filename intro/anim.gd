class_name Anim
extends RefCounted

# Timing for the intro's animation: keyframes with eases, the "on twos" step
# that makes motion read as posed by hand, and the boil (a tiny jitter that
# changes with each held pose, the way clay never sits quite still).
#
# A key list is [[time, value, ease], ...] in time order; the ease named on a
# key shapes the move INTO that key. Values may be floats or Vector2s.
# Eases: "lin", "in", "out", "io" (in-out), "back" (overshoots and settles),
# "snap" (fast, for a yank), "hold" (jumps at the key).

const TWOS := 12.0   # poses per second when animating on twos


static func curve(e: String, f: float) -> float:
	f = clampf(f, 0.0, 1.0)
	match e:
		"in":
			return f * f * f
		"out":
			return 1.0 - pow(1.0 - f, 3.0)
		"io":
			return f * f * (3.0 - 2.0 * f)
		"back":
			var c1 := 1.70158
			var c3 := c1 + 1.0
			return 1.0 + c3 * pow(f - 1.0, 3.0) + c1 * pow(f - 1.0, 2.0)
		"snap":
			return 1.0 - pow(1.0 - f, 5.0)
		"hold":
			return 0.0 if f < 1.0 else 1.0
	return f


static func k(t: float, keys: Array):
	if keys.is_empty():
		return 0.0
	if t <= float(keys[0][0]):
		return keys[0][1]
	for i in range(1, keys.size()):
		var a: Array = keys[i - 1]
		var b: Array = keys[i]
		if t <= float(b[0]):
			var span := float(b[0]) - float(a[0])
			var f := 1.0 if span <= 0.0 else (t - float(a[0])) / span
			var e: String = b[2] if b.size() > 2 else "io"
			return lerp(a[1], b[1], curve(e, f))
	return keys[keys.size() - 1][1]


# time snapped to the held pose it falls in
static func twos(t: float) -> float:
	return floorf(t * TWOS) / TWOS


# a small offset that changes once per held pose: the boil
static func boil(t: float, key: float, amount := 0.6) -> Vector2:
	var n := floorf(t * TWOS) + key * 17.0
	var hx := fposmod(sin(n * 12.9898) * 43758.5453, 1.0) - 0.5
	var hy := fposmod(sin(n * 78.233) * 12345.678, 1.0) - 0.5
	return Vector2(hx, hy) * 2.0 * amount


# 0..1 over [a, b]
static func span(t: float, a: float, b: float) -> float:
	return clampf((t - a) / maxf(b - a, 0.0001), 0.0, 1.0)


# squash and stretch that keeps volume: stretch > 1 is tall and thin
static func squash(stretch: float) -> Vector2:
	return Vector2(1.0 / sqrt(maxf(stretch, 0.05)), sqrt(maxf(stretch, 0.05)))
