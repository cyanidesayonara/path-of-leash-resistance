extends Node2D

# The cross-section - the ground, the strips, the walkway and its paving - on
# its own canvas, behind main's.
#
# It is the first thing the world pass drew, so drawn behind main at main's
# own z it lands exactly where it was: over the edge layer (z -5), under
# everything main draws. The world pass redraws at about 30 fps for what
# moves; this canvas keeps its picture and is redrawn only when the camera
# has gone main.SECTION_BAND or the weather, night or a detour changes it
# (main._draw_ground), so the renderer is not handed the same paving again
# every redraw. A walk whose cross-section animates keeps drawing it in the
# world pass instead, and this canvas stays empty.

var main: Node2D
# the band this picture covers, set by main when it asks for a redraw
var vt := 0.0
var vb := 0.0
var on := false


func setup(m: Node2D) -> void:
	main = m
	show_behind_parent = true


func _draw() -> void:
	if main == null or not on:
		return
	var b := ShapeBatch.new(self)
	main.draw_ground_onto(b, vt, vb)
	b.flush()
