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


static func draw(c: CanvasItem, t: float, drop := "swing", size := Vector2(1280, 720)) -> void:
	var cx := size.x * 0.5
	var y1 := size.y * 0.33
	var y2 := size.y * 0.50
	var rot := 0.0
	var off := Vector2.ZERO
	var sc := Vector2.ONE
	match drop:
		"swing":
			# falls on its leash, overshoots, swings to rest
			var fall: float = Anim.k(t, [[0.0, -520.0], [0.45, 30.0, "in"], [0.7, -12.0, "out"], [0.95, 0.0, "io"]])
			off = Vector2(0, fall)
			rot = sin(t * 6.0) * 0.12 * exp(-t * 2.2)
			# the leash it hangs from, off the top of the screen
			var hook := Vector2(cx, -40.0)
			c.draw_line(hook, Vector2(cx, y1 - 70.0) + off, INK, 8.0)
			c.draw_line(hook, Vector2(cx, y1 - 70.0) + off, LEASH, 4.5)
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
