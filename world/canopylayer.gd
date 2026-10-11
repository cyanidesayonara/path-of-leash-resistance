extends Node2D

# Tree crowns, above the dog, the owner and the rope (z 13, under the overhead
# layer): they walk and wrap round the trunks UNDER the leaves, as they would.
# The ground pass draws only what lies on the ground (the crown's shadow, the
# pit or grate, roots); the crowns are drawn here, all in one batch.
# A crown someone is under fades so she and the rope stay readable; its trunk
# stays solid (the ground pass draws it). It is drawn
# into a CanvasGroup, which fades it as one sheet: the crown is a stack of
# overlapping discs, and fading each disc would show every overlap as a blotch.

const FADE_A := 0.36
# under a crown: within its radius plus this
const UNDER_PAD := 6.0

var main: Node2D
var _group: CanvasGroup
var _faded_node: Node2D
var _solid: Array[Dictionary] = []
var _faded: Array[Dictionary] = []
var _fade_key := ""


func setup(m: Node2D) -> void:
	main = m
	_group = CanvasGroup.new()
	_group.self_modulate = Color(1, 1, 1, FADE_A)
	add_child(_group)
	_faded_node = Node2D.new()
	_group.add_child(_faded_node)
	_faded_node.draw.connect(_draw_faded)


func _physics_process(_delta: float) -> void:
	if main == null:
		return
	_collect()
	# which crowns are faded is the only state that changes the picture
	# between redraws, apart from the palms' sway; the world redraws at 30 fps
	# and so do the crowns
	var key := ""
	for t: Dictionary in _faded:
		key += "%d," % int(t["id"])
	if key != _fade_key or Engine.get_physics_frames() % 2 == 0:
		_fade_key = key
		queue_redraw()
		_faded_node.queue_redraw()


func _collect() -> void:
	_solid.clear()
	_faded.clear()
	var trees: Array[Dictionary] = main.canopy_trees()
	var who: Array[Vector2] = [main.dog.global_position, main.human.global_position]
	for t: Dictionary in trees:
		var p: Vector2 = t["p"]
		var r: float = float(t["r"]) + UNDER_PAD
		var under := false
		for w: Vector2 in who:
			if w.distance_squared_to(p) < r * r:
				under = true
				break
		if under:
			_faded.append(t)
		else:
			_solid.append(t)


func _draw() -> void:
	if main == null:
		return
	var b := ShapeBatch.new()
	for t: Dictionary in _solid:
		main.draw_tree_crown(b, t)
	b.flush(self)


func _draw_faded() -> void:
	if main == null or _faded.is_empty():
		return
	var b := ShapeBatch.new()
	for t: Dictionary in _faded:
		main.draw_tree_crown(b, t, true)
	b.flush(_faded_node)
