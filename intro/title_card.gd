class_name IntroTitle
extends RefCounted

# The title as the intros end on it: PATH OF / LEASH RESISTANCE in the heavy
# face, cream with a dark outline and a soft drop shadow (the intro's look),
# and nothing under it. `t` is seconds since the
# card began; `drop` chooses the entrance: "swing" (hung on a leash from the
# top and swinging to rest), "slam" (in from the right with a thump), "none"
# (already there, for when a scene places the letters itself).

const UI := preload("res://hud/ui_kit.gd")
const CREAM := Color(0.99, 0.95, 0.84)
const INK := Color(0.07, 0.05, 0.06)
const SHADOW := Color(0.25, 0.14, 0.08, 0.35)
const LEASH := Color(0.70, 0.16, 0.20)


static func word(c: CanvasItem, txt: String, centre: Vector2, px: int, rot := 0.0, sc := Vector2.ONE) -> void:
	var f := UI.display()
	var w := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
	c.draw_set_transform(centre, rot, sc)
	var at := Vector2(-w * 0.5, float(px) * 0.36)
	c.draw_string_outline(f, at + Vector2(5, 7), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, px, 14, SHADOW)
	c.draw_string(f, at + Vector2(5, 7), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, px, SHADOW)
	c.draw_string_outline(f, at, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, px, 12, INK)
	c.draw_string(f, at, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, px, CREAM)
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# The title on its leash: the leash comes down from above the screen to a red
# collar buckled round the O of PATH OF, and the whole title hangs from it -
# drops in, overshoots, and swings to rest about that point.
static func _hanging(c: CanvasItem, t: float, cx: float, y1: float, y2: float) -> void:
	var f := UI.display()
	var top := "PATH OF"
	var w1 := f.get_string_size(top, HORIZONTAL_ALIGNMENT_LEFT, -1, 64).x
	var o_x := cx - w1 * 0.5 + f.get_string_size("PATH ", HORIZONTAL_ALIGNMENT_LEFT, -1, 64).x \
		+ f.get_string_size("O", HORIZONTAL_ALIGNMENT_LEFT, -1, 64).x * 0.5
	var ring := Vector2(o_x, y1 - 14.0)
	var fall: float = Anim.k(t, [[0.0, -560.0], [0.5, 26.0, "in"], [0.75, -10.0, "out"], [1.0, 0.0, "io"]])
	var ang: float = sin(t * 5.2) * 0.10 * exp(-t * 1.6)
	var pivot := Vector2(o_x, -60.0)
	var hang := ring + Vector2(0, fall)
	var r_now := pivot + (hang - pivot).rotated(ang)
	# the leash, down from off the top of the screen to the collar's ring
	c.draw_line(pivot, r_now + Vector2(0, -49).rotated(ang), INK, 10.0)
	c.draw_line(pivot, r_now + Vector2(0, -49).rotated(ang), LEASH, 6.0)
	# everything below hangs: draw it rotated about the pivot
	var to_title := func(p: Vector2) -> Vector2:
		return pivot + (p + Vector2(0, fall) - pivot).rotated(ang)
	word(c, top, to_title.call(Vector2(cx, y1)), 64, ang)
	word(c, "LEASH RESISTANCE", to_title.call(Vector2(cx, y2)), 104, ang)
	# the collar round the O, its buckle, and the ring the leash clips to
	var oc: Vector2 = to_title.call(ring)
	c.draw_set_transform(oc, ang, Vector2.ONE)
	# a broad band over the top of the O, like a collar on a neck
	c.draw_arc(Vector2(0, 6), 30.0, PI * 0.92, PI * 2.08, 28, INK, 17.0)
	c.draw_arc(Vector2(0, 6), 30.0, PI * 0.92, PI * 2.08, 28, LEASH, 11.0)
	c.draw_arc(Vector2(0, 6), 27.0, PI * 1.1, PI * 1.5, 12, LEASH.lightened(0.35), 3.0)
	c.draw_rect(Rect2(-9, -34, 18, 16), INK)
	c.draw_rect(Rect2(-6, -31, 12, 10), Color(0.90, 0.78, 0.42))
	c.draw_arc(Vector2(0, -41), 8.0, 0, TAU, 16, INK, 7.0)
	c.draw_arc(Vector2(0, -41), 8.0, 0, TAU, 16, Color(0.90, 0.78, 0.42), 3.5)
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func draw(c: CanvasItem, t: float, drop := "swing", size := Vector2(1280, 720)) -> void:
	var cx := size.x * 0.5
	var y1 := size.y * 0.33
	var y2 := size.y * 0.50
	var rot := 0.0
	var off := Vector2.ZERO
	var sc := Vector2.ONE
	match drop:
		"swing":
			_hanging(c, t, cx, y1, y2)
			return
		"slam":
			var sx: float = Anim.k(t, [[0.0, 1400.0], [0.28, -30.0, "in"], [0.45, 0.0, "back"]])
			off = Vector2(sx, 0)
			var hit := Anim.span(t, 0.28, 0.5)
			sc = Vector2(1.0 + 0.18 * (1.0 - hit) * float(t > 0.28), 1.0 - 0.14 * (1.0 - hit) * float(t > 0.28))
	# "none-letters": a scene has placed the title's letters itself, so only
	# the line under it and the prompt are drawn here
	if drop != "none-letters":
		word(c, "PATH OF", Vector2(cx, y1) + off, 64, rot, sc)
		word(c, "LEASH RESISTANCE", Vector2(cx, y2) + off * Vector2(1.15, 1.0), 104, rot * 0.8, sc)
	# no subtitle: the title stands alone (October 2026)
	# no prompt here: the title screen it fades into has its own prompt bar,
	# and a key name written into the film would break the Prompts rule
