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
# It redraws only when main says the furniture changed (a hole being dug, a
# post sniffed clean). It used to redraw every 110 px of camera travel too,
# but the whole space is drawn every time and none of it depends on the view:
# that was 4-9 ms of the same picture, a hitch every few steps near the gate
# and all through the off-leash space. (A water bowl's ripple, read from the
# clock, now holds still between redraws; it only ever moved on those.)

var main: Node2D
var dirty := true


func setup(m: Node2D) -> void:
	main = m


func mark_dirty() -> void:
	dirty = true


func tick(_cam_pos: Vector2) -> void:
	if dirty:
		dirty = false
		queue_redraw()


func _draw() -> void:
	if main == null:
		return
	# through a ShapeBatch: the same pixels in a fraction of the draw calls
	# (systems/shape_batch.gd)
	var b := ShapeBatch.new(self)
	main.draw_freedom_onto(b)
	b.flush()
