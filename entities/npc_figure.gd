class_name NpcFigure
extends RefCounted

# A passer-by drawn the way the other dog walkers are (entities/human_appearance.gd):
# seen from above, a shadow cast along the light, feet that step, arms
# posed for what they are doing, lit shoulders and a head with that person's
# own skin and hair. For the walks' smaller characters (the kids at a
# kickabout, the petanca players, the volleyball players), so nobody on a
# walk is a stack of circles beside a dog walker drawn properly.
#
# `key` is the person's own stable number: the same person looks the same
# every frame. Draws into the caller's ShapeBatch, so no draw call of its own.

const HumanLook := preload("res://entities/human_appearance.gd")
const GameScript := preload("res://autoload/game.gd")

const SHOE := Color(0.18, 0.16, 0.15)
const SHADOW := Color(0.04, 0.05, 0.07, 0.22)
const TOPS: Array[Color] = [Color(0.30, 0.38, 0.52), Color(0.62, 0.30, 0.28), Color(0.40, 0.48, 0.36),
	Color(0.78, 0.74, 0.66), Color(0.24, 0.24, 0.27), Color(0.70, 0.56, 0.30), Color(0.52, 0.36, 0.52)]
const LEGS: Array[Color] = [Color(0.22, 0.26, 0.38), Color(0.18, 0.18, 0.20), Color(0.45, 0.40, 0.32),
	Color(0.30, 0.34, 0.30)]
const STYLES: Array[String] = ["short", "curly", "long", "bun", "short", "bald"]

# arm poses
enum Arms { SIDE, BEHIND, READY, UP, THROW }


static func skin_for(key: int) -> Color:
	return GameScript.HUMAN_SKINS[absi(key * 7 + 3) % GameScript.HUMAN_SKINS.size()]


static func hair_for(key: int) -> Color:
	return GameScript.HUMAN_HAIRS[absi(key * 5 + 1) % GameScript.HUMAN_HAIRS.size()]


static func _oval(c: Vector2, rx: float, ry: float, facing: Vector2) -> PackedVector2Array:
	var side := facing.orthogonal()
	var pts := PackedVector2Array()
	pts.resize(12)
	for k in range(12):
		var a := TAU * float(k) / 12.0
		pts[k] = c + facing * cos(a) * rx + side * sin(a) * ry
	return pts


# One person at `at` facing `facing`. `stride` is a walk-cycle phase in
# radians, or a negative number standing still. Options (all optional):
# top, legs, skin, hair, hair_style, headwear, headwear_col (Color), size
# (1.0 an adult), arms (Arms), step (0..1, how far the feet swing).
static func person(c: ShapeBatch, at: Vector2, facing: Vector2, key: int, stride := -1.0, o := {}) -> void:
	var f := facing.normalized() if facing.length() > 0.01 else Vector2.DOWN
	var side := f.orthogonal()
	var k := absi(key)
	var size := float(o.get("size", 1.0))
	var top: Color = o.get("top", TOPS[k % TOPS.size()])
	var legs: Color = o.get("legs", LEGS[(k / 3) % LEGS.size()])
	var skin: Color = o.get("skin", skin_for(k))
	var hair: Color = o.get("hair", hair_for(k))
	var style := String(o.get("hair_style", STYLES[(k / 2) % STYLES.size()]))
	if style == "bald" and size < 0.9 and not o.has("hair_style"):
		style = "curly"   # a child is never drawn bald
	var arms := int(o.get("arms", Arms.SIDE))
	var step := float(o.get("step", 1.0))
	var walking := stride >= 0.0
	var sw := sin(stride) if walking else 0.0
	# the shadow, cast along the light
	c.draw_colored_polygon(_oval(at + Shade.light * 4.0 * size, 9.0 * size, 7.5 * size, f), SHADOW)
	# feet: stepping one ahead of the other, or stood side by side
	for s: float in [-1.0, 1.0]:
		var fwd := sw * s * 4.2 * step * size if walking else 0.6 * size
		var foot := at + side * s * 3.0 * size + f * fwd
		c.draw_line(at + side * s * 2.6 * size, foot, legs, 3.0 * size)
		c.draw_colored_polygon(_oval(foot + f * 1.4 * size, 2.6 * size, 1.6 * size, f), SHOE)
	# arms, under the shoulders' edge
	var sh_half := 7.2 * size
	for s: float in [-1.0, 1.0]:
		var shoulder := at + side * s * sh_half * 0.82
		var hand: Vector2
		match arms:
			Arms.BEHIND:
				hand = at - f * 5.0 * size + side * s * 2.2 * size
			Arms.READY:
				hand = at + f * 6.5 * size + side * s * 4.0 * size
			Arms.UP:
				hand = at + f * 3.0 * size + side * s * 9.5 * size
			Arms.THROW:
				hand = at + (f * 9.0 + side * 3.0 * s) * size if s > 0.0 else at - f * 2.0 * size + side * s * 7.0 * size
			_:
				hand = shoulder + f * (-sw * s * 3.6 * size if walking else 0.4 * size) + side * s * 0.8 * size
		c.draw_line(shoulder, hand, top.darkened(0.06), 2.8 * size)
		c.draw_circle(hand, 1.7 * size, skin)
	HumanLook.draw_torso(c, at, f, Vector2(4.6, sh_half) * size, top)
	HumanLook.draw_head(c, at + f * 0.8 * size, f, 4.4 * size, skin, hair, style,
		String(o.get("headwear", "none")), o.get("headwear_col", Color.BLACK))
