extends Node2D

# What hangs over the walk (El Gotic's bridge between two buildings): drawn
# above the dog and the owner, so they pass under it. Drawn once: a module
# that draws its whole walk's overhead needs nothing more. A module that culls
# its overhead to the camera, animates it or fades it over the pair declares
# `const OVERHEAD_FOLLOWS_CAMERA := true` and is redrawn at 30 fps.

const LIVE_STEP := 0.033

var main: Node2D
var _live := false
var _acc := 0.0


func setup(m: Node2D) -> void:
	main = m
	var mod: Variant = m.get("walk_mod")
	_live = mod is Script and (mod as Script).get_script_constant_map().get("OVERHEAD_FOLLOWS_CAMERA", false) == true
	set_process(_live)


func _process(delta: float) -> void:
	_acc += delta
	if _acc >= LIVE_STEP:
		_acc = 0.0
		queue_redraw()


func _draw() -> void:
	if main == null:
		return
	main.draw_overhead_onto(self)
