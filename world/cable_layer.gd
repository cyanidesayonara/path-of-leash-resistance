extends Node2D

# The telefèric drawn over Montjuïc (systems/cable_car.gd): the two stations,
# the cable on its pylons, the cabins, and the dropped ticket. Above the trees,
# since the cable runs over them. Redrawn only while any of it is in view.

const CableCar := preload("res://systems/cable_car.gd")

const CABLE := Color(0.18, 0.18, 0.20, 0.85)
const PYLON := Color(0.52, 0.54, 0.56)
const CABIN := Color(0.86, 0.33, 0.24)
const CABIN_TRIM := Color(0.96, 0.92, 0.84)
const GLASS := Color(0.62, 0.78, 0.88)
const STATION := Color(0.84, 0.80, 0.72)
const ROOF := Color(0.42, 0.40, 0.38)
const SHADOW := Color(0, 0, 0, 0.18)

var main: Node2D


func setup(m: Node2D) -> void:
	main = m


func _process(_delta: float) -> void:
	if main == null:
		return
	var cy: float = main.cam.position.y
	var top: float = minf(main.cable_low.y, main.cable_top.y) - 500.0
	var bottom: float = maxf(main.cable_low.y, main.cable_ticket_pos.y) + 500.0
	if main.cable_riding or (cy > top and cy < bottom):
		queue_redraw()


# the cable's sag at fraction f along it, the same curve the cabin rides
func _cable_at(f: float, a: Vector2, b: Vector2) -> Vector2:
	return a.lerp(b, f) + Vector2(0.0, 40.0 * sin(PI * f))


func _draw() -> void:
	if main == null:
		return
	var b := ShapeBatch.new(self)
	var lo: Vector2 = main.cable_low
	var hi: Vector2 = main.cable_top
	# the ticket, fluttering where it fell
	if not main.cable_ticket_taken:
		var tp: Vector2 = main.cable_ticket_pos
		var flap := sin(AnimClock.msec() / 260.0) * 0.18
		var tx := Transform2D(flap, tp)
		var pts := PackedVector2Array()
		for v: Vector2 in [Vector2(-9, -5), Vector2(9, -5), Vector2(9, 5), Vector2(-9, 5)]:
			pts.append(tx * v)
		b.polygon(pts, CABIN_TRIM)
		b.line(tx * Vector2(-9, -1), tx * Vector2(9, -1), CABIN, 3.0)
		# a glint now and then, for a dog who is looking
		var g := fmod(AnimClock.msec() / 1000.0, 2.6)
		if g < 0.35:
			var gl := sin(PI * g / 0.35)
			b.line(tp + Vector2(-7, -10) * gl, tp + Vector2(7, 10) * gl, Color(1, 1, 0.9, 0.8), 1.6)
			b.line(tp + Vector2(7, -10) * gl, tp + Vector2(-7, 10) * gl, Color(1, 1, 0.9, 0.8), 1.6)
	# the stations
	for s: Vector2 in [lo, hi]:
		b.rect(Rect2(s + Vector2(-34, -20), Vector2(72, 46)), SHADOW)
		b.rect(Rect2(s + Vector2(-36, -24), Vector2(72, 46)), STATION)
		b.rect(Rect2(s + Vector2(-40, -28), Vector2(80, 14)), ROOF)
	# the two cables, up and down, side by side, on two pylons
	var off := (hi - lo).normalized().orthogonal() * 8.0
	for side: float in [-1.0, 1.0]:
		var prev := lo + off * side
		for i in range(1, 17):
			var p := _cable_at(float(i) / 16.0, lo, hi) + off * side
			b.line(prev, p, CABLE, 1.6)
			prev = p
	for f: float in [0.34, 0.67]:
		var p := _cable_at(f, lo, hi)
		b.rect(Rect2(p + Vector2(-5, -2), Vector2(14, 22)), SHADOW)
		b.rect(Rect2(p + Vector2(-6, -4), Vector2(12, 22)), PYLON)
		b.rect(Rect2(p + Vector2(-14, -10), Vector2(28, 5)), PYLON)
	# the cabins: one riding, or one waiting at each station
	if main.cable_riding:
		_cabin(b, CableCar.cabin_pos(main), true)
	else:
		_cabin(b, lo + Vector2(0, -2), false)
		_cabin(b, hi + Vector2(0, -2), false)
	b.flush()
	var f := ThemeDB.fallback_font
	for s: Vector2 in [lo, hi]:
		draw_string(f, s + Vector2(-38, -32), "TELEFÈRIC", HORIZONTAL_ALIGNMENT_CENTER, 76, 11, CABIN_TRIM)


func _cabin(b: ShapeBatch, p: Vector2, full: bool) -> void:
	b.rect(Rect2(p + Vector2(-20, 4), Vector2(44, 34)), SHADOW)
	b.line(p + Vector2(0, -16), p + Vector2(0, -3), CABLE, 2.4)
	b.rect(Rect2(p + Vector2(-22, -3), Vector2(44, 34)), CABIN)
	b.rect(Rect2(p + Vector2(-18, 1), Vector2(36, 13)), GLASS)
	b.rect(Rect2(p + Vector2(-22, 25), Vector2(44, 6)), CABIN_TRIM)
	if full:
		# two heads at the window: a dog's ears, a human's hair
		b.circle(p + Vector2(8, 10), 6.0, Color(0.12, 0.11, 0.12))
		b.circle(p + Vector2(4, 5), 2.6, Color(0.12, 0.11, 0.12))
		b.circle(p + Vector2(12, 5), 2.6, Color(0.12, 0.11, 0.12))
		b.circle(p + Vector2(-8, 9), 6.5, Color(0.45, 0.30, 0.22))
