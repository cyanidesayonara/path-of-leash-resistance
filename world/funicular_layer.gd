extends Node2D

# El Tibidabo's moving parts (systems/tibidabo.gd): the funicular carriage and
# the trackside signal. The edge layer is cached and only redraws after the
# camera has scrolled, so anything that moves is drawn here, every frame,
# culled to the view, in one batch.

const Tibidabo := preload("res://systems/tibidabo.gd")
const ShapeBatch := preload("res://systems/shape_batch.gd")

# how far past the view's top and bottom edge to draw
const VIEW_PAD := 420.0

var main: Node2D
var _batch: ShapeBatch


func setup(m: Node2D) -> void:
	main = m
	_batch = ShapeBatch.new(self)


func _process(_delta: float) -> void:
	if main != null:
		queue_redraw()


func _draw() -> void:
	if main == null:
		return
	var cy: float = main.cam.position.y
	Tibidabo.draw_moving(main, _batch, cy - VIEW_PAD, cy + VIEW_PAD)
	_batch.flush()
