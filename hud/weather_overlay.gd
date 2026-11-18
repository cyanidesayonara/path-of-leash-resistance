extends Control

# Screen-space weather: rain, blown grit and leaves (spray off the sea),
# snow, or the calima's dust, drawn over the world but under the HUD text. Purely atmospheric; the
# gameplay nudges (slick ground, a shoving wind) live in main.gd.
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
# the sky's strength (Game.SKY): how hard it rains and blows. A drizzle is
# fewer, finer drops; a storm drives them sideways. A breeze on a clear day
# is the wind's leaves and grit, thinned out.
var rain_k := 1.0
var wind_k := 0.0
# how thick the dust hangs (Game.dust_amount): a calima's light wind carries
# fine motes, never leaves
var dust_k := 0.0
# a gust blowing now (main's wind_gust, 0 to 1) and which way the wind
# blows across the screen (+1 left to right)
var push := 0.0
var wind_sign := 1.0
# the wind is coming in off the sea (main's wind_off_sea): what it carries is
# salt spray, not leaves, which come off trees inland
var sea := false


# the walk's sky in one call: the mode, and a fresh scatter when only the
# strength changed (a drizzle turning to a downpour is still "rain")
func set_sky(kind: String, rain: float, wind: float, dust := 0.0) -> void:
	var m := kind
	if kind == "clear" and dust > 0.0:
		m = "dust"
	elif kind == "clear" and wind >= 0.3:
		m = "wind"
	var changed := not is_equal_approx(rain, rain_k) or not is_equal_approx(wind, wind_k) \
		or not is_equal_approx(dust, dust_k)
	rain_k = rain
	wind_k = wind
	dust_k = dust
	if m != mode:
		mode = m
	elif changed:
		_scatter()
		queue_redraw()

# per 1280x720 of view; scaled to the real view so a wide window is as wet
const RAIN_N := 130
const GRIT_N := 70
const LEAF_N := 22
const SNOW_N := 140
const DUST_N := 48
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
		"rain": return int(RAIN_N * area * (0.35 + 0.65 * rain_k) * (1.0 + 0.4 * wind_k))
		"wind": return int(GRIT_N * area * wind_k) + int(LEAF_N * (0.4 + 0.6 * wind_k))
		"snow": return int(SNOW_N * area)
		"dust": return int(DUST_N * area * dust_k)
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
	var own := clampf(0.55 + 0.30 * sin(t * 0.61) + 0.25 * sin(t * 1.73 + 1.1) * sin(t * 0.37), 0.15, 1.1)
	return maxf(own * (0.5 + 0.5 * wind_k), 0.6 + push * 0.9)


func _is_leaf(i: int) -> bool:
	return mode == "wind" and i >= drops.size() - int(LEAF_N * (0.4 + 0.6 * wind_k))


# the slant the rain falls at: a little drift, driven over by a storm's wind
func _rain_slant(g: float) -> float:
	return (-0.16 + 0.85 * wind_k * g) * wind_sign if wind_k > 0.25 else -0.16


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
				var fall := 560.0 * (0.8 + 0.2 * rain_k)
				v = Vector2(_rain_slant(g) * fall, fall) * (0.75 + z * 0.65)
			"wind":
				if _is_leaf(i) and sea:
					# spray rides the wind faster than a leaf and sinks as it goes
					v = Vector2((260.0 + 220.0 * g) * wind_sign, 22.0 + 18.0 * sin(t * 3.3 + float(i))) * (0.75 + z * 0.5)
					spin[i] += delta * 4.0
				elif _is_leaf(i):
					v = Vector2((170.0 + 160.0 * g) * wind_sign, 30.0 + 40.0 * sin(t * 2.1 + float(i)))
					spin[i] += delta * (2.0 + z * 3.0) * g
				else:
					v = Vector2((240.0 + 220.0 * g) * wind_sign, 30.0 * sin(t * 1.4 + float(i))) * (0.7 + z * 0.6)
			"dust":
				# hanging in the air more than falling: a slow drift downwind
				# that wanders as it goes
				v = Vector2((14.0 + 46.0 * wind_k) * wind_sign + sin(t * 0.5 + spin[i]) * 6.0,
					5.0 + 4.0 * sin(t * 0.37 + spin[i] * 1.3)) * (0.6 + z * 0.7)
			_:
				v = Vector2(sin(t * (0.9 + z * 0.6) + spin[i]) * (12.0 + z * 26.0), 26.0 + z * 64.0)
		drops[i] += v * delta
		var d := drops[i]
		if d.y > view_size.y + 10.0 or d.x < -40.0 or d.x > view_size.x + 40.0:
			if mode == "wind" or mode == "dust":
				drops[i] = Vector2(-30.0 if wind_sign > 0.0 else view_size.x + 30.0, _rng.randf() * view_size.y)
			elif mode == "rain" and absf(_rain_slant(g)) > 0.3:
				# driven rain comes in from the windward side too
				var from_side := _rng.randf() < 0.5
				var sx := -30.0 if wind_sign > 0.0 else view_size.x + 30.0
				drops[i] = Vector2(sx, _rng.randf() * view_size.y) if from_side else Vector2(_rng.randf() * (view_size.x + 80.0) - 40.0, -10.0)
			else:
				drops[i] = Vector2(_rng.randf() * (view_size.x + 80.0) - 40.0, -10.0)
			depth[i] = _rng.randf()
	if mode == "rain":
		for k in range(SPLASH_N):
			splash_age[k] += delta
		_splash_due += delta * SPLASH_RATE * (0.35 + 0.65 * rain_k) * clampf(view_size.x * view_size.y / (1280.0 * 720.0), 0.6, 1.8)
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
		"dust": _draw_dust(b)
	b.flush()


func _draw_rain(b: ShapeBatch) -> void:
	# lit from below by the street at night, so the near drops catch more
	var col := Color(0.78, 0.84, 0.96) if night else Color(0.72, 0.80, 0.94)
	var slant := _rain_slant(gust())
	var fine := 0.6 + 0.4 * rain_k
	for i in range(drops.size()):
		var z := depth[i]
		var d := drops[i]
		var ln := (9.0 + z * 18.0) * fine * (1.0 + 0.5 * absf(slant))
		b.line(d, d + Vector2(slant, 1.0).normalized() * ln, Color(col.r, col.g, col.b, (0.14 + z * 0.34) * fine), (1.0 + z * 0.9) * fine)
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
		if _is_leaf(i) and sea:
			# a fleck of spray: a bright droplet and the fine streak it leaves
			var tail := (8.0 + z * 14.0) * (0.6 + g * 0.5)
			var wob := sin(spin[i]) * 2.0
			var sc := Color(0.90, 0.95, 0.98)
			b.line(d, d - Vector2(tail * wind_sign, wob), Color(sc.r, sc.g, sc.b, 0.16 + z * 0.22), 1.0 + z * 0.8)
			b.circle(d, 0.9 + z * 1.5, Color(sc.r, sc.g, sc.b, 0.40 + z * 0.40))
		elif _is_leaf(i):
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
			b.line(d, d + Vector2(ln * wind_sign, wob), Color(0.88, 0.82, 0.70, (0.14 + z * 0.30) * (0.5 + g * 0.6)), 1.2 + z)


# a mote of dust: tiny, soft, ochre by day and lamp-orange after dark, the
# near ones with a faint halo so they read as out of focus
func _draw_dust(b: ShapeBatch) -> void:
	var col := Color(1.0, 0.78, 0.50) if night else Color(1.0, 0.93, 0.80)
	for i in range(drops.size()):
		var z := depth[i]
		var d := drops[i]
		var r := 0.8 + z * 1.4
		if z > 0.55:
			b.circle(d, r * 2.4, Color(col.r, col.g, col.b, 0.10 * z))
		b.circle(d, r, Color(col.r, col.g, col.b, 0.30 + z * 0.36))


func _draw_snow(b: ShapeBatch) -> void:
	for i in range(drops.size()):
		var z := depth[i]
		var d := drops[i]
		var r := 1.2 + z * 3.0
		if z > 0.6:
			# the near flakes are soft: a faint halo round a brighter heart
			b.circle(d, r * 2.0, Color(0.96, 0.98, 1.0, 0.12 * z))
		b.circle(d, r, Color(0.97, 0.98, 1.0, 0.42 + z * 0.48))
