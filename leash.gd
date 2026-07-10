extends Node2D

# The leash. Two jobs:
# - Gameplay: track pivot points where the rope wraps around poles. Pivots
#   shorten the usable length and redirect the pull; main.gd applies forces
#   toward each end's nearest anchor. Walking back around a pole unwinds it.
# - Visual: a verlet chain that drapes and wraps on its own.

const N := 16
const WRAP_R := 14.0

var pts: Array[Vector2] = []
var prev: Array[Vector2] = []
var dog: Node2D
var human: Node2D
var poles: Array[Vector2] = []
var seg_len := 16.0
var taut := false

# pivot: {pos: Vector2, pole: int, wind: float}; ordered dog side -> human side
var pivots: Array = []


func setup(d: Node2D, h: Node2D, pole_list: Array[Vector2], max_len: float) -> void:
	dog = d
	human = h
	poles = pole_list
	seg_len = max_len / (N - 1)
	for i in range(N):
		var p := d.global_position.lerp(h.global_position, float(i) / (N - 1))
		pts.append(p)
		prev.append(p)


func _hand_pos() -> Vector2:
	return human.global_position + Vector2(9, -16).rotated(human.rotation)


# --- wrap bookkeeping -------------------------------------------------------

func update_wraps() -> void:
	_unwrap_end(true)
	_unwrap_end(false)
	_wrap_end(true)
	_wrap_end(false)


func used_length() -> float:
	var total := 0.0
	var p := dog.global_position
	for piv in pivots:
		total += p.distance_to(piv.pos)
		p = piv.pos
	return total + p.distance_to(human.global_position)


func human_anchor() -> Vector2:
	if pivots.size() > 0:
		return pivots[-1]["pos"] as Vector2
	return dog.global_position


func dog_anchor() -> Vector2:
	if pivots.size() > 0:
		return pivots[0]["pos"] as Vector2
	return human.global_position


func _adjacent_anchor(human_end: bool) -> Vector2:
	return human_anchor() if human_end else dog_anchor()


func _adjacent_pole(human_end: bool) -> int:
	if pivots.size() == 0:
		return -1
	return (pivots[-1]["pole"] if human_end else pivots[0]["pole"]) as int


func _anchor_beyond(human_end: bool) -> Vector2:
	# the anchor on the far side of this end's pivot
	if human_end:
		return (pivots[-2]["pos"] as Vector2) if pivots.size() > 1 else dog.global_position
	return (pivots[1]["pos"] as Vector2) if pivots.size() > 1 else human.global_position


func _wrap_end(human_end: bool) -> void:
	if pivots.size() >= 24:
		return
	var p := human.global_position if human_end else dog.global_position
	var a := _adjacent_anchor(human_end)
	var same_pole := _adjacent_pole(human_end)
	var best := -1
	var best_d := 1e9
	var best_cp := Vector2.ZERO
	for i in range(poles.size()):
		var cp := _closest_on_segment(a, p, poles[i])
		if cp.distance_to(poles[i]) >= WRAP_R or cp.distance_to(a) <= 2.0 or cp.distance_to(p) <= 2.0:
			continue
		if i == same_pole:
			# the same pole can be wound again and again, but only once the
			# rope has swung well past the existing contact point
			var swung := absf((a - poles[i]).angle_to(cp - poles[i]))
			if swung < 1.5:
				continue
		var d := cp.distance_to(a)
		if d < best_d:
			best_d = d
			best = i
			best_cp = cp
	if best < 0:
		return
	var c := poles[best]
	var n := best_cp - c
	n = n.normalized() if n.length() > 0.001 else (a - c).normalized()
	var pos := c + n * WRAP_R
	var wind := signf((pos - a).cross(p - pos))
	if wind == 0.0:
		wind = 1.0
	var piv := {"pos": pos, "pole": best, "wind": wind}
	if human_end:
		pivots.append(piv)
	else:
		pivots.push_front(piv)


func _unwrap_end(human_end: bool) -> void:
	while pivots.size() > 0:
		var piv: Dictionary = pivots[-1] if human_end else pivots[0]
		var b := _anchor_beyond(human_end)
		var p := human.global_position if human_end else dog.global_position
		var pos: Vector2 = piv.pos
		var pole_c: Vector2 = poles[int(piv.pole)]
		# endpoint hugging the pole: geometry is degenerate, freeze the state
		# (step away from the pole to unwind)
		if p.distance_to(pole_c) < WRAP_R + 12.0:
			break
		var cur := signf((pos - b).cross(p - pos))
		# the cross sign also flips when the rope winds PAST a half turn;
		# only a flip on the straightened side (endpoint out beyond the
		# pivot along the anchor->pivot ray) is a real unwind
		var straightened := (p - pos).dot(pos - b) > 0.0
		if cur != 0.0 and cur != float(piv.wind) and straightened:
			if human_end:
				pivots.pop_back()
			else:
				pivots.pop_front()
		else:
			break


func _closest_on_segment(a: Vector2, b: Vector2, c: Vector2) -> Vector2:
	var ab := b - a
	var l2 := ab.length_squared()
	if l2 < 0.0001:
		return a
	var t := clampf((c - a).dot(ab) / l2, 0.0, 1.0)
	return a + ab * t


# --- visual rope ------------------------------------------------------------

func tick(_delta: float) -> void:
	pts[0] = dog.global_position
	pts[N - 1] = _hand_pos()
	for i in range(1, N - 1):
		var vel := (pts[i] - prev[i]) * 0.9
		prev[i] = pts[i]
		pts[i] += vel
	for _iter in range(14):
		pts[0] = dog.global_position
		pts[N - 1] = _hand_pos()
		for i in range(N - 1):
			var d := pts[i + 1] - pts[i]
			var dist := d.length()
			if dist < 0.001:
				continue
			var k := 0.5 if dist > seg_len else 0.05
			var corr := d * ((dist - seg_len) / dist) * k
			if i > 0:
				pts[i] += corr
			if i + 1 < N - 1:
				pts[i + 1] -= corr
		for i in range(1, N - 1):
			for pl in poles:
				var dp := pts[i] - pl
				var l := dp.length()
				if l < 13.0 and l > 0.001:
					pts[i] = pl + dp / l * 13.0
	queue_redraw()


func _draw() -> void:
	var col := Color(0.78, 0.32, 0.26) if taut else Color(0.5, 0.26, 0.22)
	var arr := PackedVector2Array()
	for p in pts:
		arr.append(to_local(p))
	draw_polyline(arr, col, 3.0)
	draw_circle(to_local(_hand_pos()), 4.0, col.darkened(0.2))
	for piv in pivots:
		draw_circle(to_local(piv.pos), 3.0, col.darkened(0.35))
