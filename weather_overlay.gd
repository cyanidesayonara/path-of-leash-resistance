extends Control

# Screen-space weather: rain streaks or blown grit, drawn over the world
# but under the HUD text. Purely atmospheric; the gameplay nudges (slick
# ground, a shoving wind) live in main.gd.

var mode := "clear"
var drops: Array[Vector2] = []
var t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	for i in range(90):
		drops.append(Vector2(randf() * 1280.0, randf() * 720.0))


func _process(delta: float) -> void:
	if mode == "clear" or not visible:
		return
	t += delta
	var vel := Vector2(-90.0, 760.0) if mode == "rain" else Vector2(280.0, 40.0)
	for i in range(drops.size()):
		drops[i] += vel * delta
		if drops[i].y > 726.0 or drops[i].x < -6.0 or drops[i].x > 1286.0:
			drops[i] = Vector2(randf() * 1360.0 - 40.0, -6.0 if mode == "rain" else randf() * 720.0)
			if mode == "wind":
				drops[i].x = -40.0
	queue_redraw()


func _draw() -> void:
	if mode == "rain":
		for d in drops:
			draw_line(d, d + Vector2(-4, 16), Color(0.7, 0.8, 0.95, 0.4), 1.5)
	elif mode == "wind":
		for i in range(drops.size()):
			var d := drops[i]
			var wob := sin(t * 6.0 + i) * 3.0
			draw_line(d, d + Vector2(18, wob), Color(0.85, 0.8, 0.7, 0.22), 1.5)
