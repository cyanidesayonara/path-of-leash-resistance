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


# The title on its leash, set as the Store logo is (tools/make_store_art.gd):
# stacked, each line fitted to one measure, PATH OF small and spaced, LEASH the
# biggest word and in the leash's colour, RESISTANCE under it, every line a
# sticker (a stepped brown drop, a fat cream keyline, then the letters). The O
# of PATH OF is Millie's pink collar, and the leash comes straight down from the
# top of the screen to its D-ring: the title drops in on it, overshoots, swings
# to rest about that point and keeps a slow sway, as a hung sign would.
const LOGO_INK := Color(0.27, 0.15, 0.09)
const LOGO_DROP := Color(0.45, 0.25, 0.14)
const LOGO_CREAM := Color(1.0, 0.97, 0.88)
const LOGO_RED := Color(0.75, 0.27, 0.20)
const COLLAR := Color(0.93, 0.33, 0.55)
const MEASURE := 540.0           # RESISTANCE spans this many scene units
const SMALL_TRACK := 0.30
const BIG_TRACK := 0.04
static var _faces := {}


static func _face(px: int, track: float) -> FontVariation:
	var key := "%d/%.2f" % [px, track]
	if not _faces.has(key):
		var f := FontVariation.new()
		f.base_font = ThemeDB.fallback_font
		f.variation_embolden = 1.1
		f.set_spacing(TextServer.SPACING_GLYPH, int(round(px * track)))
		_faces[key] = f
	return _faces[key]


static func _width(text: String, px: int, track: float) -> float:
	# glyph spacing also follows the last letter; take it back off
	return _face(px, track).get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x - px * track


static func _fit(text: String, measure: float, track: float) -> int:
	return int(floor(200.0 * measure / _width(text, 200, track)))


static func _sticker(c: CanvasItem, text: String, left: Vector2, px: int, track: float, fill: Color) -> void:
	var f := _face(px, track)
	var sh := Vector2(0.0, px * 0.07)
	c.draw_string_outline(f, left + sh, text, HORIZONTAL_ALIGNMENT_LEFT, -1, px, int(px * 0.22), LOGO_DROP)
	c.draw_string(f, left + sh, text, HORIZONTAL_ALIGNMENT_LEFT, -1, px, LOGO_DROP)
	c.draw_string_outline(f, left, text, HORIZONTAL_ALIGNMENT_LEFT, -1, px, int(px * 0.20), LOGO_CREAM)
	c.draw_string(f, left, text, HORIZONTAL_ALIGNMENT_LEFT, -1, px, fill)


static func _hanging(c: CanvasItem, t: float, cx: float, top: float) -> void:
	var fs_path := _fit("PATH OF", MEASURE * 0.62, SMALL_TRACK)
	var fs_leash := mini(_fit("LEASH", MEASURE, BIG_TRACK), int(MEASURE * 0.30))
	var fs_res := _fit("RESISTANCE", MEASURE, BIG_TRACK)
	# PATH OF laid out round its O, which hangs under the leash at x = 0
	var w_all := _width("PATH OF", fs_path, SMALL_TRACK)
	var w_pre := _width("PATH ", fs_path, SMALL_TRACK) + fs_path * SMALL_TRACK
	var w_o := _width("O", fs_path, SMALL_TRACK)
	var o_x := -w_all * 0.5 + w_pre + w_o * 0.5
	var shift := -o_x                 # puts the O under the pivot, the title centred about it
	var base1 := float(fs_path) * 0.9
	var base2 := base1 + fs_leash * 0.98
	var base3 := base2 + fs_res * 1.12
	var o_c := Vector2(0.0, base1 - fs_path * 0.36)
	var ry := fs_path * 0.37
	var rx := maxf(w_o * 0.5, fs_path * 0.36)
	var stroke := fs_path * 0.105
	# the D-ring stands on the buckle at the top of the band
	var dring := o_c + Vector2(0, -(ry - stroke * 0.5) - stroke * 0.8 - 2.5)
	# the drop: a beat on the empty street, a fall that overshoots and bounces,
	# then a swing that dies into a slow sway
	var fall: float = Anim.k(t, [[0.0, -760.0], [0.1, -760.0], [0.5, 22.0, "in"], [0.68, -9.0, "out"], [0.86, 3.0, "io"],
		[1.0, 0.0, "io"]])
	var ts := maxf(t - 0.5, 0.0)
	var ang: float = sin(ts * 4.6) * 0.10 * exp(-ts * 1.4) + sin(t * 1.3) * 0.012
	# a squash as it lands, the letters settling on the leash
	var land := Anim.span(t, 0.5, 0.62) * (1.0 - Anim.span(t, 0.62, 0.9))
	var sc := Vector2(1.0 + 0.05 * land, 1.0 - 0.06 * land)
	var pivot := Vector2(cx, -80.0)
	var hang := top + 80.0 - dring.y        # pivot to the D-ring, at rest
	c.draw_set_transform(pivot, ang, Vector2.ONE)
	var ring_at := Vector2(0.0, hang + fall + (dring.y - 30.0) * sc.y)
	# the leash: a dark edge, the strap and the light along it
	c.draw_line(Vector2.ZERO, ring_at, LOGO_INK, 12.0)
	c.draw_line(Vector2.ZERO, ring_at, IntroKit.LEASH, 8.0)
	c.draw_line(Vector2(-1.5, 0), ring_at + Vector2(-1.5, 0), IntroKit.LEASH.lightened(0.35), 2.0)
	c.draw_set_transform(pivot + Vector2(0.0, hang + fall).rotated(ang), ang, sc)
	var path_left := Vector2(-w_all * 0.5 + shift, base1)
	_sticker(c, "PATH", path_left, fs_path, SMALL_TRACK, LOGO_INK)
	var f_left := Vector2(o_x + shift + w_o * 0.5 + fs_path * SMALL_TRACK, base1)
	_sticker(c, "F", f_left, fs_path, SMALL_TRACK, LOGO_INK)
	_sticker(c, "LEASH", Vector2(-_width("LEASH", fs_leash, BIG_TRACK) * 0.5 + shift, base2), fs_leash, BIG_TRACK, LOGO_RED)
	_sticker(c, "RESISTANCE", Vector2(-_width("RESISTANCE", fs_res, BIG_TRACK) * 0.5 + shift, base3), fs_res, BIG_TRACK,
		LOGO_INK)
	# the collar standing in for the O: drop, keyline, band, its light edge,
	# a buckle on top and the D-ring on the buckle
	var erx := rx - stroke * 0.5
	var ery := ry - stroke * 0.5
	var band := MillieSide.ellipse(o_c, Vector2(erx, ery), 0.0, 40)
	band.append(band[0])
	var drop := PackedVector2Array()
	for q in band:
		drop.append(q + Vector2(0.0, fs_path * 0.07))
	c.draw_polyline(drop, LOGO_DROP, stroke + fs_path * 0.20)
	c.draw_polyline(band, LOGO_CREAM, stroke + fs_path * 0.18)
	c.draw_polyline(band, COLLAR.darkened(0.3), stroke)
	c.draw_polyline(band, COLLAR, stroke * 0.62)
	var lit := PackedVector2Array()
	for i in range(10):
		var a := PI * 1.08 + float(i) / 9.0 * PI * 0.6
		lit.append(o_c + Vector2(cos(a) * erx, sin(a) * ery))
	c.draw_polyline(lit, COLLAR.lightened(0.5), stroke * 0.22)
	var silver := Color(0.90, 0.90, 0.94)
	var top_y := o_c.y - ery
	var bk := Rect2(Vector2(-stroke * 0.75, top_y - stroke * 0.8), Vector2(stroke * 1.5, stroke * 1.6))
	c.draw_rect(bk.grow(2.5), LOGO_INK)
	c.draw_rect(bk, silver)
	c.draw_rect(bk.grow(-stroke * 0.38), COLLAR.darkened(0.2))
	c.draw_arc(dring, 8.0, PI, TAU, 16, LOGO_INK, 7.0)
	c.draw_arc(dring, 8.0, PI, TAU, 16, silver, 3.5)
	# the leash's snap clip, hooked through the ring
	var clip := Rect2(dring + Vector2(-4.0, -31.0), Vector2(8.0, 18.0))
	c.draw_rect(clip.grow(2.0), LOGO_INK)
	c.draw_rect(clip, Color(0.74, 0.74, 0.78))
	c.draw_rect(Rect2(clip.position + Vector2(1.5, 2.0), Vector2(2.0, 11.0)), Color(1, 1, 1, 0.7))
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
			_hanging(c, t, cx, size.y * 0.07)
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
