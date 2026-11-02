class_name Redraw
extends RefCounted

# A redraw asked for from physics, made once a frame.
#
# Godot runs the queued redraws after every physics step, not once a frame.
# When a frame runs slow, the engine catches up with several physics steps
# (two at 30 fps, up to eight in a struggling browser), and every node that
# called queue_redraw() in its _physics_process drew that many times, all but
# the last picture thrown away: a bike drawn eight times a frame. Redraw.later
# marks the node instead, and the Game autoload asks each marked node for one
# redraw in the frame's process pass, which comes after the physics steps, so
# the picture is the one the last step left.

static var _due := {}


static func later(ci: CanvasItem) -> void:
	_due[ci] = true


static func flush() -> void:
	if _due.is_empty():
		return
	for ci: Variant in _due:
		if is_instance_valid(ci):
			(ci as CanvasItem).queue_redraw()
	_due.clear()
