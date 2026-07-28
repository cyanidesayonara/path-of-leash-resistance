extends Node2D

# The off-leash space at the top of the walk, on its own canvas.
#
# Measuring it (--drawcost) showed the freedom view costing 3.3ms on the park
# and 9.0ms in the woods, against 0.7ms for the corridor - the clearing's ring
# of trees alone was 5.7ms, redrawn thirty times a second to produce an
# identical picture, because trees do not move. Same story as the building
# frontage in v1.17 and v1.49, same fix: world-space canvas items persist, so
# not redrawing them costs nothing visually.
#
# What lives here is everything static: the ground, the fence or the dunes, the
# benches, the trees, the sign, and the park furniture. The animated things -
# the sea's crests, the marks the other dogs leave - stay in the main draw,
# because those genuinely change every frame.
#
# It redraws when the camera has moved far enough to reveal new ground, or when
# main says the furniture changed (a hole being dug, a post sniffed clean).

var main: Node2D
var last_cam := Vector2(1e9, 1e9)
var dirty := true


func setup(m: Node2D) -> void:
	main = m


func mark_dirty() -> void:
	dirty = true


func tick(cam_pos: Vector2) -> void:
	if dirty or cam_pos.distance_to(last_cam) > 110.0:
		dirty = false
		last_cam = cam_pos
		queue_redraw()


func _draw() -> void:
	if main == null:
		return
	main.draw_freedom_onto(self)
