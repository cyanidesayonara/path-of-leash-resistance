extends Node2D

# Tree crowns, above the dog, the owner and the rope (z 13, under the overhead
# layer): they walk and wrap round the trunks UNDER the leaves, as they would.
# The ground pass draws only what lies on the ground (the crown's shadow, the
# pit or grate, roots); the crowns are drawn here, all in one batch.
# Everything else she passes under is drawn here too (main.overhead_pieces:
# parasols, awnings and the arcade roof, washing lines, lamp heads, the
# bandstand roof, the departures board...), above the NPCs (z 9) and the riders
# (z 12) as well.
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
	var dp: Vector2 = main.dog.global_position
	var hp: Vector2 = main.human.global_position
	_sort(main.canopy_trees(), dp, hp)
	_sort(main.overhead_pieces(), dp, hp)


func _sort(pieces: Array[Dictionary], dp: Vector2, hp: Vector2) -> void:
	for t: Dictionary in pieces:
		if not t.get("solid", false) and (is_under(t, dp) or is_under(t, hp)):
			_faded.append(t)
		else:
			_solid.append(t)


# under a crown or a round piece: within its radius (plus the pad) of it; under
# a long one (an awning, a washing line, the board): inside its rect, padded
static func is_under(t: Dictionary, w: Vector2) -> bool:
	if t.has("rect"):
		return (t["rect"] as Rect2).grow(UNDER_PAD).has_point(w)
	var r: float = float(t["r"]) + UNDER_PAD
	return w.distance_squared_to(t["p"]) < r * r


func _draw() -> void:
	if main == null:
		return
	_draw_set(_solid, self, false)


func _draw_faded() -> void:
	if main == null or _faded.is_empty():
		return
	_draw_set(_faded, _faded_node, true)


# the batch stands in for the canvas, so a piece's text and arcs go straight
# through to it in order
func _draw_set(items: Array[Dictionary], canvas: CanvasItem, faded: bool) -> void:
	var b := ShapeBatch.new(canvas)
	for t: Dictionary in items:
		if t.has("over"):
			main.draw_overhead_piece(b, t, faded)
		else:
			main.draw_tree_crown(b, t, faded)
	b.flush()
