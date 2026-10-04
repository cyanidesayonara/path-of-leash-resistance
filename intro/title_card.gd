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
const SHADOW := Color(0.22, 0.12, 0.06, 0.5)
const TOP_PX := 80
const LEASH := Color(0.70, 0.16, 0.20)


static func word(c: CanvasItem, txt: String, centre: Vector2, px: int, rot := 0.0, sc := Vector2.ONE) -> void:
	var f := UI.display()
	var w := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
	c.draw_set_transform(centre, rot, sc)
	var at := Vector2(-w * 0.5, float(px) * 0.36)
	c.draw_string_outline(f, at + Vector2(6, 8), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, px, 16, SHADOW)
	c.draw_string(f, at + Vector2(6, 8), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, px, SHADOW)
	c.draw_string_outline(f, at, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, px, 12, INK)
	c.draw_string(f, at, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, px, CREAM)
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# The title on its leash. The O of PATH OF is a dog's collar: a red band the
# size and weight of the letter, outlined and shadowed like the letters round
# it, buckled at the top, with the D-ring there that the leash clips to. The
# leash hangs straight down from the top of the screen, and the whole title
# hangs from it: drops in, overshoots, and swings to rest about that point.
static func _hanging(c: CanvasItem, t: float, cx: float, y1: float, y2: float) -> void:
	var f := UI.display()
	var px := TOP_PX
	var w_all := f.get_string_size("PATH OF", HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
	var x0 := cx - w_all * 0.5
	var w_path := f.get_string_size("PATH", HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
	var w_pre := f.get_string_size("PATH ", HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
	var w_o := f.get_string_size("O", HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
	var w_f := f.get_string_size("F", HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
	var path_c := Vector2(x0 + w_path * 0.5, y1)
	var o_c := Vector2(x0 + w_pre + w_o * 0.5, y1)
	var f_c := Vector2(x0 + w_pre + w_o + w_f * 0.5, y1)
	# a beat on the empty street, then it drops, overshoots and swings to rest
	var fall: float = Anim.k(t, [[0.0, -620.0], [0.1, -620.0], [0.55, 24.0, "io"], [0.78, -8.0, "out"], [1.0, 0.0, "io"]])
	var ts := maxf(t - 0.55, 0.0)
	var ang: float = sin(ts * 5.2) * 0.11 * exp(-ts * 1.5)
	var pivot := Vector2(o_c.x, -60.0)
	var to_title := func(q: Vector2) -> Vector2:
		return pivot + (q + Vector2(0, fall) - pivot).rotated(ang)
	# the collar's size, from the letter it stands in for
	var stroke := float(px) * 0.135
	var rx := w_o * 0.5 - stroke * 0.15
	var ry := float(px) * 0.37 - stroke * 0.5
	var dring := Vector2(0, -ry - stroke * 0.5 - 10.0)
	# the leash, straight down from the top of the screen to the D-ring
	var ring_now: Vector2 = to_title.call(o_c + dring + Vector2(0, -6))
	c.draw_line(pivot, ring_now, INK, 10.0)
	c.draw_line(pivot, ring_now, LEASH, 6.0)
	word(c, "PATH", to_title.call(path_c), px, ang)
	word(c, "F", to_title.call(f_c), px, ang)
	word(c, "LEASH RESISTANCE", to_title.call(Vector2(cx, y2)), 104, ang)
	# the collar: shadow, outline, band, the light along its top, stitching
	var oc: Vector2 = to_title.call(o_c)
	c.draw_set_transform(oc, ang, Vector2.ONE)
	var band := MillieSide.ellipse(Vector2.ZERO, Vector2(rx, ry), 0.0, 48)
	band.append(band[0])
	var sh := PackedVector2Array()
	for q in band:
		sh.append(q + Vector2(6, 8))
	c.draw_polyline(sh, SHADOW, stroke + 8.0)
	c.draw_polyline(band, INK, stroke + 7.0)
	c.draw_polyline(band, LEASH, stroke)
	var lit := PackedVector2Array()
	for i in range(12):
		var a := PI * 1.05 + float(i) / 11.0 * PI * 0.62
		lit.append(Vector2(cos(a) * rx, sin(a) * ry) + Vector2(0, -stroke * 0.18))
	c.draw_polyline(lit, LEASH.lightened(0.38), stroke * 0.22)
	for i in range(18):
		var a0 := TAU * float(i) / 18.0
		var a1 := a0 + TAU / 36.0
		var r0 := Vector2(cos(a0) * rx, sin(a0) * ry)
		var r1 := Vector2(cos(a1) * rx, sin(a1) * ry)
		c.draw_line(r0, r1, LEASH.darkened(0.35), 1.4)
	# the buckle across the top of the band, and the D-ring above it
	var brass := Color(0.92, 0.78, 0.40)
	var bk := Rect2(Vector2(-stroke * 0.7, -ry - stroke * 0.75), Vector2(stroke * 1.4, stroke * 1.5))
	c.draw_rect(bk.grow(2.5), INK)
	c.draw_rect(bk, brass)
	c.draw_rect(bk.grow(-stroke * 0.32), LEASH.darkened(0.1))
	c.draw_line(Vector2(0, bk.position.y + 2.0), Vector2(0, bk.end.y - 2.0), INK, 2.0)
	c.draw_arc(dring, 8.0, PI, TAU, 14, INK, 7.0)
	c.draw_line(dring + Vector2(-8, 0), dring + Vector2(8, 0), INK, 7.0)
	c.draw_arc(dring, 8.0, PI, TAU, 14, brass, 3.5)
	c.draw_line(dring + Vector2(-8, 0), dring + Vector2(8, 0), brass, 3.5)
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
