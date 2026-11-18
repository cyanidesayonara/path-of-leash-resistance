extends RefCounted

# Rough stones for a bank of riprap, a breakwater or a groin: a few angular
# outlines round the origin, built once, stamped turned and squashed into a
# ShapeBatch, so a bank of a hundred stones costs no triangulation and no
# draw call of its own. `h` (0..1, from the caller's own hash) picks the
# outline, the turn and the squash, so a stone is the same every frame.

const ShapeBatch := preload("res://systems/shape_batch.gd")

const OUTLINES := 4
const SIDES := 7

static var _shapes: Array[PackedVector2Array] = []


static func _build() -> void:
	for v in range(OUTLINES):
		var rim: Array[Vector2] = []
		for k in range(SIDES):
			var j := fmod(absf(sin(float(v * 31 + k) * 12.9898) * 43758.5453), 1.0)
			var a := TAU * (float(k) + (j - 0.5) * 0.5) / float(SIDES)
			rim.append(Vector2.from_angle(a) * (0.80 + j * 0.28))
		var tris := PackedVector2Array()
		for k in range(SIDES):
			tris.append(Vector2.ZERO)
			tris.append(rim[k])
			tris.append(rim[(k + 1) % SIDES])
		_shapes.append(tris)


# one stone of about radius `r` at `at`
static func stone(b: ShapeBatch, at: Vector2, r: float, col: Color, h: float) -> void:
	if _shapes.is_empty():
		_build()
	var shape: PackedVector2Array = _shapes[int(h * 53.0) % OUTLINES]
	b.stamp(shape, Transform2D(h * TAU, Vector2(r, r * (0.78 + h * 0.3)), 0.0, at), col)


# a stone with its shadow cast by Shade.light and a lit facet on top
static func lit_stone(b: ShapeBatch, at: Vector2, r: float, col: Color, shadow: Color, h: float) -> void:
	stone(b, at + Shade.light * r * 0.3, r, shadow, h)
	stone(b, at, r, col, h)
	stone(b, at - Shade.light * r * 0.3, r * 0.5, col.lightened(0.14), fmod(h + 0.37, 1.0))
