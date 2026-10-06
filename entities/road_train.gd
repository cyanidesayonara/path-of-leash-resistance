extends Node2D

# El trenet: Montjuïc's little tourist road train, a loco and two open
# carriages trundling across the hill on the road at Montjuic.TRAIN_Y. Slow,
# long, and it rings its bell before it reaches the path (main.gd's Montjuic
# tick does the ringing), so a dog who digs in at the crossing lets it by.
# Catching your human bowls them over like a bike would; catching the dog is
# a tumble.

const SPEED := 72.0
const CAR_L := 46.0
const CAR_GAP := 8.0
const CARS := 3                 # the loco and two carriages
const HALF_W := 17.0
const LOCO := Color(0.20, 0.52, 0.36)
const CARRIAGE := Color(0.92, 0.88, 0.76)
const AWNING := Color(0.84, 0.30, 0.26)

var main: Node2D
var dir := 1.0
var hit_done := false


func setup(m: Node2D, going: float) -> void:
	main = m
	dir = going
	z_index = 12


func length() -> float:
	return float(CARS) * CAR_L + float(CARS - 1) * CAR_GAP


# The train's body: from its nose back along its length.
func rect() -> Rect2:
	var l := length()
	var x0 := global_position.x - (l if dir > 0.0 else 0.0)
	return Rect2(x0, global_position.y - HALF_W, l, HALF_W * 2.0)


func nose_x() -> float:
	return global_position.x


func _physics_process(delta: float) -> void:
	if main == null or main.frozen:
		return
	global_position.x += dir * SPEED * delta
	var body := rect()
	if not hit_done and body.grow(10.0).has_point(main.human.global_position):
		if main.human.fall("train"):
			hit_done = true
			main.float_text(main.human.global_position + Vector2(0, -30), "ding! sorry!", Color(1, 1, 1, 0.9), main.POP_SAY)
	if body.grow(8.0).has_point(main.dog.global_position):
		main.dog.knocked(Vector2(dir, 0.0), "train")
	if (dir > 0.0 and body.position.x > 1600.0) or (dir < 0.0 and body.end.x < -320.0):
		queue_free()
	queue_redraw()


func _draw() -> void:
	var t := AnimClock.msec() / 1000.0
	for i in range(CARS):
		# car i's centre, counting back from the nose
		var back := float(i) * (CAR_L + CAR_GAP) + CAR_L * 0.5
		var cx := -dir * back
		var r := Rect2(cx - CAR_L * 0.5, -HALF_W, CAR_L, HALF_W * 2.0)
		draw_rect(Rect2(r.position + Vector2(4, 6), r.size), Color(0, 0, 0, 0.2))
		if i == 0:
			draw_rect(r, LOCO)
			draw_rect(Rect2(r.position.x + 6.0, r.position.y + 4.0, CAR_L - 12.0, HALF_W * 2.0 - 8.0), LOCO.lightened(0.18))
			# the lamp on its nose
			draw_circle(Vector2(cx + dir * CAR_L * 0.5, 0.0), 4.0, Color(1.0, 0.92, 0.6))
		else:
			draw_rect(r, CARRIAGE)
			# a striped awning, and heads of the tourists under it
			var k := 0
			var sx := r.position.x
			while sx < r.end.x:
				draw_rect(Rect2(sx, r.position.y, minf(8.0, r.end.x - sx), HALF_W * 2.0),
					AWNING if k % 2 == 0 else CARRIAGE.darkened(0.04))
				sx += 8.0
				k += 1
			for j in range(3):
				var hx := r.position.x + 9.0 + float(j) * 14.0
				draw_circle(Vector2(hx, -5.0 + sin(t * 3.0 + float(i * 3 + j)) * 1.5), 4.0,
					Color(0.36 + 0.1 * float(j), 0.26, 0.20))
		# wheels, a hint of them at the corners
		for wx: float in [r.position.x + 6.0, r.end.x - 6.0]:
			for wy: float in [-HALF_W - 1.0, HALF_W - 3.0]:
				draw_rect(Rect2(wx - 4.0, wy, 8.0, 4.0), Color(0.12, 0.12, 0.13))
	# the couplings
	for i in range(CARS - 1):
		var gx := -dir * (float(i + 1) * (CAR_L + CAR_GAP) - CAR_GAP * 0.5)
		draw_line(Vector2(gx - 4.0, 0), Vector2(gx + 4.0, 0), Color(0.15, 0.15, 0.15), 3.0)
