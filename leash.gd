extends Node2D

# Verlet rope between dog and human. The visual rope wraps around poles;
# the gameplay constraint (in main.gd) is a straight-line distance check.

const N := 16

var pts: Array[Vector2] = []
var prev: Array[Vector2] = []
var dog: Node2D
var human: Node2D
var poles: Array[Vector2] = []
var seg_len := 16.0
var taut := false


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
