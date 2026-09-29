extends Node2D

# What hangs over the walk (El Gotic's bridge between two buildings): drawn
# above the dog and the owner, so they pass under it. Cached like the edge
# layer: it only redraws when the camera has moved far enough to matter.

var main: Node2D


func setup(m: Node2D) -> void:
	main = m


func _draw() -> void:
	if main == null:
		return
	main.draw_overhead_onto(self)
