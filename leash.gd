extends Node2D

# The leash IS the verlet rope. The visible rope is also the gameplay
# constraint: it wraps poles by colliding with them, winds up, unwinds,
# and slides off under tension like a real rope. There is no separate
# wrap bookkeeping to fall out of sync with what the player sees.
#
# main.gd sets rest_len (the human's retractable reel), calls tick() once
# per physics frame, then reads used_length() vs rest_len for tension and
# dog_pull_dir()/human_pull_dir() (the rope's end tangents) for force
# directions - which is why a wound-up human gets flung in an arc: the
# pull follows the rope around the pole.

const N := 24
const ITER := 14
const POLE_PAD := 13.0
const FRICTION := 0.5

var pts: Array[Vector2] = []
var prev: Array[Vector2] = []
var dog: Node2D
var human: Node2D
var poles: Array[Vector2] = []
var rest_len := 260.0
var taut := false
var contacts := 0


func setup(d: Node2D, h: Node2D, pole_list: Array[Vector2], max_len: float) -> void:
	dog = d
	human = h
	poles = pole_list
	rest_len = max_len
	for i in range(N):
		var p := d.global_position.lerp(h.global_position, float(i) / (N - 1))
		pts.append(p)
		prev.append(p)


func _hand_pos() -> Vector2:
	return human.global_position + Vector2(9, -16).rotated(human.rotation)


func tick(_delta: float) -> void:
	var seg := rest_len / (N - 1)
	# stick-slip: grip the pole at low tension (coils hold, winding
	# accumulates), slide freely when overstretched (rope slips off
	# instead of sticking to the pole forever)
	var stretch_ratio := used_length() / maxf(rest_len, 1.0)
	var slip := clampf(0.15 + (stretch_ratio - 1.0) * 0.8, 0.15, 1.0)
	for i in range(1, N - 1):
		var vel := (pts[i] - prev[i]) * 0.94
		prev[i] = pts[i]
		pts[i] += vel
	var start := pts.duplicate()
	var touched := {}
	for _iter in range(ITER):
		pts[0] = dog.global_position
		pts[N - 1] = _hand_pos()
		for i in range(N - 1):
			var d := pts[i + 1] - pts[i]
			var dist := d.length()
			if dist < 0.001:
				continue
			# stiff against stretch, loose against compression so slack
			# rope drapes instead of contracting into a straight line
			var k := 0.9 if dist > seg else 0.05
			var corr := d * ((dist - seg) / dist) * 0.5 * k
			if i > 0:
				pts[i] += corr
			if i + 1 < N - 1:
				pts[i + 1] -= corr
		# segment-vs-circle collision: point-only checks tunnel when
		# stretched segments straddle the pole between two points
		for i in range(N - 1):
			for pl in poles:
				var cp := _closest_on_segment(pts[i], pts[i + 1], pl)
				var dp := cp - pl
				var l := dp.length()
				if l < POLE_PAD and l > 0.001:
					var push := dp / l * (POLE_PAD - l)
					if i > 0:
						pts[i] += push
						touched[i] = pl
					if i + 1 < N - 1:
						pts[i + 1] += push
						touched[i + 1] = pl
	contacts = touched.size()
	# apply the stick-slip: contacted points keep only `slip` of the
	# tangential travel the solver gave them this frame, and lose their
	# sliding velocity memory
	for i in touched:
		var pl: Vector2 = touched[i]
		var r0: Vector2 = start[i] - pl
		var r1: Vector2 = pts[i] - pl
		if r0.length_squared() > 0.001 and r1.length_squared() > 0.001:
			var da := wrapf(r1.angle() - r0.angle(), -PI, PI)
			pts[i] = pl + Vector2.from_angle(r0.angle() + da * slip) * r1.length()
		prev[i] = prev[i].lerp(pts[i], FRICTION)
	queue_redraw()


func _closest_on_segment(a: Vector2, b: Vector2, c: Vector2) -> Vector2:
	var ab := b - a
	var l2 := ab.length_squared()
	if l2 < 0.0001:
		return a
	var t := clampf((c - a).dot(ab) / l2, 0.0, 1.0)
	return a + ab * t


func used_length() -> float:
	# actual polyline length: wrapping a pole consumes rope, so this is
	# the gameplay length (compare against rest_len)
	var total := 0.0
	for i in range(N - 1):
		total += pts[i].distance_to(pts[i + 1])
	return total


func winding() -> float:
	# net signed turning of the rope in full turns: a coil around a pole
	# reads as +/-N turns, while gentle slack curves mostly cancel out
	var total := 0.0
	for i in range(1, N - 1):
		var a := pts[i] - pts[i - 1]
		var b := pts[i + 1] - pts[i]
		if a.length_squared() > 0.01 and b.length_squared() > 0.01:
			total += a.angle_to(b)
	return total / TAU


func human_end_winding() -> float:
	# signed turning (radians) of the last few segments at the human end:
	# tells whether the HUMAN is the wound-up one, and which way unwinds
	var total := 0.0
	for i in range(maxi(1, N - 8), N - 1):
		var a := pts[i] - pts[i - 1]
		var b := pts[i + 1] - pts[i]
		if a.length_squared() > 0.01 and b.length_squared() > 0.01:
			total += a.angle_to(b)
	return total


func dog_pull_dir() -> Vector2:
	var d := pts[1] - pts[0]
	return d.normalized() if d.length() > 0.001 else Vector2.ZERO


func human_pull_dir() -> Vector2:
	var d := pts[N - 2] - pts[N - 1]
	return d.normalized() if d.length() > 0.001 else Vector2.ZERO


func _draw() -> void:
	var col := Color(0.78, 0.32, 0.26) if taut else Color(0.5, 0.26, 0.22)
	var arr := PackedVector2Array()
	for p in pts:
		arr.append(to_local(p))
	draw_polyline(arr, col, 3.0)
	draw_circle(to_local(_hand_pos()), 4.0, col.darkened(0.2))
