extends Node2D

# What sits on the grass either side of the walk, on its own cached canvas.
#
# Same trick as edgelayer.gd - world-space canvas items persist, so scenery
# that does not move should not be redrawn thirty times a second - but it
# cannot share that canvas, because the edge layer sits at z_index -5, BEHIND
# the world, and main's ground pass paints its grass slab straight over
# anything drawn there. A picnic has to be on top of the lawn it is on.
#
# So: above the ground, below the actors, and still cached.

var main: Node2D


func setup(m: Node2D) -> void:
	main = m


func _draw() -> void:
	if main == null:
		return
	# a turned camera (La Diagonal) sees further up and down the world
	var vt: float = main.cam.position.y - 560.0 - main._rot_pad()
	var vb: float = main.cam.position.y + 560.0 + main._rot_pad()
	# through a ShapeBatch: the same pixels in a fraction of the draw calls
	# (systems/shape_batch.gd)
	var b := ShapeBatch.new(self)
	# tufts, flowers and picnickers are small discs: sides they can show
	b.lod = true
	main.draw_verge_onto(b, vt, vb)
	b.flush()
