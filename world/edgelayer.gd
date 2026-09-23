extends Node2D

# The buildings, roofs and verge foliage flanking the corridor, on their own
# canvas.
#
# Measuring the frame showed the edge treatment was 1007us of a 1844us world
# draw - over half of it - and every bit of that was being redrawn 30 times a
# second to produce an identical picture, because buildings do not move. It
# lives here now and only redraws when the camera has actually scrolled far
# enough to reveal new frontage, which is the same trick that fixed the world
# draw back in v1.17: world-space canvas items persist, so not redrawing them
# costs nothing visually.

var main: Node2D


func setup(m: Node2D) -> void:
	main = m


func _draw() -> void:
	if main == null:
		return
	main.draw_edges_onto(self)
