extends Control

# Screen-space weather: rain, blown grit and leaves, or snow, drawn over the
# world but under the HUD text. Purely atmospheric; the gameplay nudges (slick
# ground, a shoving wind) live in main.gd.
#
# Every particle has a depth, 0 far to 1 near: near ones are bigger, brighter
# and faster, which is what makes a flat overlay read as weather falling
# THROUGH the air rather than across the glass. All of it goes through one
# ShapeBatch, so the whole of the weather is one draw call.

# `mode` needs a setter: _process returns early when the weather is "clear",
# so it never queued a redraw, and the LAST drawn frame of snow or rain
# stayed painted on the screen forever after you switched to a clear day.
# Changing the mode now always forces one more redraw to clear the canvas.
var mode := "clear":
	set(value):
		if mode == value:
			return
		mode = value
		_scatter()
		queue_redraw()
var night := false

# per 1280x720 of view; scaled to the real view so a wide window is as wet
const RAIN_N := 130
const GRIT_N := 70
const LEAF_N := 22
const SNOW_N := 140
const SPLASH_N := 18
const SPLASH_LIFE := 0.36
const SPLASH_RATE := 46.0

var drops: Array[Vector2] = []
var depth := PackedFloat32Array()
var spin := PackedFloat32Array()
var splash_at: Array[Vector2] = []
var splash_age := PackedFloat32Array()
var _splash_next := 0
var _splash_due := 0.0
var _leaf := PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
# the overlay's own dice. How many drops respawn depends on how much of the
# world the window shows, so drawing them from the global RNG made the rest
# of the walk (spawns, events) play out differently at different window
# sizes (#6)
var _rng := RandomNumberGenerator.new()
var t := 0.0
# the viewport stretches with aspect "expand", so a phone's real aspect ratio
# reveals more or less than the 1280x720 reference frame; caching the actual
# size (refreshed on resize) means rain/snow covers the whole visible screen
# instead of stopping at a hardcoded edge and leaving a dry strip on wide
# windows
var view_size := Vector2(1280.0, 720.0)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	view_size = get_viewport_rect().size
	# shot mode photographs the same rain every time (see AnimClock)
	if AnimClock.frame_clock:
		_rng.seed = 1
	get_viewport().size_changed.connect(_on_resized)
	_scatter()


func _on_resized() -> void:
	view_size = get_viewport_rect().size
	_scatter()


func _count() -> int:
	var area := clampf(view_size.x * view_size.y / (1280.0 * 720.0), 0.6, 1.8)
	match mode:
		"rain": return int(RAIN_N * area)
		"wind": return int(GRIT_N * area) + LEAF_N
		"snow": return int(SNOW_N * area)
	return 0


func _scatter() -> void:
	drops.clear()
	var n := _count()
	depth.resize(n)
	spin.resize(n)
	for i in range(n):
		drops.append(Vector2(_rng.randf() * view_size.x, _rng.randf() * view_size.y))
		depth[i] = _rng.randf()
		spin[i] = _rng.randf() * TAU
	splash_at.clear()
	splash_age.resize(SPLASH_N)
	for i in range(SPLASH_N):
		splash_at.append(Vector2.ZERO)
		splash_age[i] = SPLASH_LIFE
	t = 0.0


# the wind comes in gusts: a slow swell with a shorter flurry on top
func gust() -> float:
	return clampf(0.55 + 0.30 * sin(t * 0.61) + 0.25 * sin(t * 1.73 + 1.1) * sin(t * 0.37), 0.15, 1.1)


func _is_leaf(i: int) -> bool:
	return mode == "wind" and i >= drops.size() - LEAF_N


func _process(delta: float) -> void:
	if mode == "clear" or not visible:
		return
	t += delta
	var g := gust()
	for i in range(drops.size()):
		var z := depth[i]
		var v: Vector2
		match mode:
			"rain":
				v = Vector2(-90.0, 560.0) * (0.75 + z * 0.65)
			"wind":
				if _is_leaf(i):
					v = Vector2(170.0 + 160.0 * g, 30.0 + 40.0 * sin(t * 2.1 + float(i)))
					spin[i] += delta * (2.0 + z * 3.0) * g
				else:
					v = Vector2(240.0 + 220.0 * g, 30.0 * sin(t * 1.4 + float(i))) * (0.7 + z * 0.6)
			_:
				v = Vector2(sin(t * (0.9 + z * 0.6) + spin[i]) * (12.0 + z * 26.0), 26.0 + z * 64.0)
		drops[i] += v * delta
		var d := drops[i]
		if d.y > view_size.y + 10.0 or d.x < -40.0 or d.x > view_size.x + 40.0:
			if mode == "wind":
				drops[i] = Vector2(-30.0, _rng.randf() * view_size.y)
			else:
				drops[i] = Vector2(_rng.randf() * (view_size.x + 80.0) - 40.0, -10.0)
			depth[i] = _rng.randf()
	if mode == "rain":
		for k in range(SPLASH_N):
			splash_age[k] += delta
		_splash_due += delta * SPLASH_RATE * clampf(view_size.x * view_size.y / (1280.0 * 720.0), 0.6, 1.8)
		while _splash_due >= 1.0:
			_splash_due -= 1.0
			splash_at[_splash_next] = Vector2(_rng.randf() * view_size.x, _rng.randf() * view_size.y)
			splash_age[_splash_next] = 0.0
			_splash_next = (_splash_next + 1) % SPLASH_N
	queue_redraw()


func _draw() -> void:
	if mode == "clear":
		return
	var b := ShapeBatch.new(self)
	match mode:
		"rain": _draw_rain(b)
		"wind": _draw_wind(b)
		"snow": _draw_snow(b)
	b.flush()


func _draw_rain(b: ShapeBatch) -> void:
	# lit from below by the street at night, so the near drops catch more
	var col := Color(0.78, 0.84, 0.96) if night else Color(0.72, 0.80, 0.94)
	for i in range(drops.size()):
		var z := depth[i]
		var d := drops[i]
		var ln := 9.0 + z * 18.0
		b.line(d, d + Vector2(-0.16, 1.0) * ln, Color(col.r, col.g, col.b, 0.14 + z * 0.34), 1.0 + z * 0.9)
	# where a drop hits: a ring opening out flat on the ground, and two flecks
	for k in range(SPLASH_N):
		var a := splash_age[k]
		if a >= SPLASH_LIFE:
			continue
		var f := a / SPLASH_LIFE
		var p := splash_at[k]
		var rr := 2.0 + f * 9.0
		var ca := Color(col.r, col.g, col.b, 0.36 * (1.0 - f))
		for s in range(6):
			var a0 := TAU * float(s) / 6.0
			var a1 := a0 + TAU / 9.0
			b.line(p + Vector2(cos(a0) * rr, sin(a0) * rr * 0.45), p + Vector2(cos(a1) * rr, sin(a1) * rr * 0.45), ca, 1.0)
		if f < 0.5:
			var up := f * 2.0
			b.circle(p + Vector2(-4.0 * up, -7.0 * up * (1.0 - up)), 1.1, ca)
			b.circle(p + Vector2(4.0 * up, -6.0 * up * (1.0 - up)), 1.1, ca)


func _draw_wind(b: ShapeBatch) -> void:
	var g := gust()
	for i in range(drops.size()):
		var z := depth[i]
		var d := drops[i]
		if _is_leaf(i):
			var s := 6.0 + z * 6.0
			var ax := Vector2.from_angle(spin[i]) * s
			var ay := Vector2.from_angle(spin[i] + PI * 0.5) * s * 0.45 * absf(cos(spin[i] * 1.7))
			_leaf[0] = d + ax
			_leaf[1] = d + ay
			_leaf[2] = d - ax
			_leaf[3] = d - ay
			var lc := Color(0.62, 0.48, 0.22) if i % 3 == 0 else (Color(0.70, 0.36, 0.16) if i % 3 == 1 else Color(0.52, 0.56, 0.24))
			b.polygon(_leaf, Color(lc.r, lc.g, lc.b, 0.75 + z * 0.2))
			b.line(d - ax, d + ax, Color(lc.r * 0.6, lc.g * 0.6, lc.b * 0.6, 0.7), 1.0)
		else:
			var wob := sin(t * 6.0 + float(i)) * 3.0
			var ln := (12.0 + z * 22.0) * (0.6 + g * 0.6)
			b.line(d, d + Vector2(ln, wob), Color(0.88, 0.82, 0.70, (0.14 + z * 0.30) * (0.5 + g * 0.6)), 1.2 + z)


func _draw_snow(b: ShapeBatch) -> void:
	for i in range(drops.size()):
		var z := depth[i]
		var d := drops[i]
		var r := 1.2 + z * 3.0
		if z > 0.6:
			# the near flakes are soft: a faint halo round a brighter heart
			b.circle(d, r * 2.0, Color(0.96, 0.98, 1.0, 0.12 * z))
		b.circle(d, r, Color(0.97, 0.98, 1.0, 0.42 + z * 0.48))
