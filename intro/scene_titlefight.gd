class_name SceneTitleFight
extends RefCounted

# Intro 3, "The title fights back": the shortest, and the logo's own joke. On
# a cream ground the title lies in a heap, its letters tied to Millie's leash.
# She tugs; the heap wobbles and springs back. She plants her paws and hauls,
# and the letters fly out of the heap into their places one after another,
# PATH OF, LEASH RESISTANCE. The last E hangs on, hops, sails over and bonks
# her on the nose before dropping into its slot. Stars. She shakes it off,
# wags, and the title is done.

const LENGTH := 11.0
const UI := preload("res://hud/ui_kit.gd")
const GROUND := 600.0
const LINES := [["PATH OF", 64, 238.0], ["LEASH RESISTANCE", 104, 360.0]]
const FLY_START := 3.0
const FLY_EACH := 0.11
const FLY_TIME := 0.45
const BONK := 5.95


static func camera(t: float) -> Array:
	var z: float = Anim.k(t, [[0.0, 1.0], [5.8, 1.0], [5.95, 1.06, "snap"], [6.2, 1.0, "out"]])
	return [Vector2(640, 380), z]


# every letter: [char, px, final centre, heap position, heap rotation, order]
static func _letters() -> Array:
	var f: Font = UI.display()
	var out := []
	var order := 0
	for ln: Array in LINES:
		var txt: String = ln[0]
		var px: int = ln[1]
		var y: float = ln[2]
		var w := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
		var x0 := 640.0 - w * 0.5
		for i in range(txt.length()):
			var ch := txt[i]
			if ch == " ":
				continue
			var pre := f.get_string_size(txt.substr(0, i), HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
			var cw := f.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
			var h := fposmod(sin(float(order) * 12.9898) * 43758.5453, 1.0)
			var h2 := fposmod(sin(float(order) * 78.233) * 9631.7, 1.0)
			var heap := Vector2(980.0 + (h - 0.5) * 260.0, GROUND - 30.0 - h2 * 120.0 - float(order % 4) * 14.0)
			out.append([ch, px, Vector2(x0 + pre + cw * 0.5, y), heap, (h - 0.5) * 1.6, order])
			order += 1
	return out


static func draw(c: CanvasItem, t_real: float) -> void:
	var t := Anim.twos(t_real)
	# the cream ground, a floor line, a soft vignette of warmth
	c.draw_rect(Rect2(-600, -400, 2480, 1520), Color(0.99, 0.94, 0.82))
	c.draw_rect(Rect2(-600, GROUND, 2480, 600), Color(0.93, 0.84, 0.66))
	c.draw_line(Vector2(-600, GROUND), Vector2(1880, GROUND), IntroKit.INK, 4.0)
	var letters := _letters()
	var n := letters.size()
	var last := n - 1
	# the tug: three pulls the heap answers like rubber, then the haul
	var tug := maxf(0.0, sin((t - 1.3) * 7.5)) * Anim.span(t, 1.3, 1.5) * (1.0 - Anim.span(t, 2.5, 2.6))
	var haul := Anim.span(t, 2.6, 2.9)
	# Millie: hauling left, sliding a little as each letter comes
	var mx: float = Anim.k(t, [[0.0, 330.0], [2.6, 330.0], [3.0, 300.0, "out"], [5.0, 250.0, "io"]])
	var dazed := Anim.span(t, BONK, BONK + 0.05) * (1.0 - Anim.span(t, 7.0, 7.3))
	var proud := Anim.span(t, 5.1, 5.4) * (1.0 - Anim.span(t, BONK - 0.05, BONK))
	var pose := {
		"crouch": 0.5 * tug + 0.9 * haul * (1.0 - Anim.span(t, 5.0, 5.3)) + 0.9 * dazed,
		"lean": -0.25 * tug - 0.3 * haul * (1.0 - Anim.span(t, 5.0, 5.3)) - 0.3 * dazed,
		"reach": 0.8 * haul * (1.0 - Anim.span(t, 5.0, 5.3)),
		"push": -0.6 * dazed + 0.3 * tug,
		"head_up": Anim.k(t, [[0.6, 0.0], [0.8, 0.3, "out"], [1.2, 0.3], [1.3, 0.0]]) + 0.4 * proud - 0.3 * dazed
			+ sin(t_real * 22.0) * 0.25 * Anim.span(t, 7.0, 7.1) * (1.0 - Anim.span(t, 7.4, 7.5)),
		"ear": 0.5 * haul + sin(t_real * 22.0) * 0.6 * Anim.span(t, 7.0, 7.1) * (1.0 - Anim.span(t, 7.4, 7.5)),
		"tail": sin(t_real * 18.0) * 0.5 * (proud + Anim.span(t, 7.5, 7.7)),
		"mouth": 0.7 * maxf(tug, haul * (1.0 - Anim.span(t, 5.0, 5.3))),
		"brow": proud - 0.8 * maxf(tug, haul) + 0.6 * Anim.span(t, 7.5, 7.7),
		"blink": 1.0 if t > BONK and t < BONK + 0.6 else 0.0,
	}
	var face: float = Anim.k(t, [[0.0, -1.0], [0.7, -1.0], [0.75, 1.0, "hold"], [1.2, 1.0], [1.25, -1.0, "hold"]])
	var sq := Anim.squash(Anim.k(t, [[2.5, 1.0], [2.75, 0.75, "out"], [3.0, 0.88, "io"], [BONK - 0.02, 0.92],
		[BONK, 0.6, "snap"], [BONK + 0.3, 1.0, "back"]]))
	var mpos := Vector2(mx, GROUND) + Anim.boil(t_real, 3.0, 0.5)
	var m := IntroKit.millie(c, mpos, 1.9, face, sq, pose)
	# the letters: in the heap (jiggling with each tug), flying, or in place
	var knot := Vector2.ZERO
	for L: Array in letters:
		var order: int = L[5]
		var start := FLY_START + float(order) * FLY_EACH
		if order == last:
			start = BONK - 0.35
		var f := Anim.span(t, start, start + FLY_TIME)
		var heap: Vector2 = L[3] + Vector2(-26.0 * tug - 14.0 * haul, 0.0)
		var p := heap
		var rot: float = L[4] * (1.0 - f) + sin(t_real * 9.0 + float(order)) * 0.12 * tug
		var sc := lerpf(0.72, 1.0, f)
		if order == last and t > start:
			# up and over onto her nose, then down into its slot
			var nose: Vector2 = m["mouth"] + Vector2(-10, -40)
			if t < BONK:
				var g := Anim.span(t, start, BONK)
				p = heap.lerp(nose, g) + Vector2(0, -sin(g * PI) * 180.0)
				rot = g * 6.0
			else:
				var g2 := Anim.span(t, BONK, BONK + 0.45)
				p = nose.lerp(L[2], Anim.curve("out", g2)) + Vector2(0, -sin(g2 * PI) * 140.0)
				rot = (1.0 - g2) * -3.0
			sc = 1.0
		elif f > 0.0:
			var e := Anim.curve("back", f)
			p = heap.lerp(L[2], e) + Vector2(0, -sin(f * PI) * 160.0)
		IntroTitle.word(c, String(L[0]), p, int(L[1]), rot, Vector2(sc, sc))
		if order == 6:
			knot = p + Vector2(-30, 10)
	# the leash, from her collar to the L of LEASH, wherever it is
	var taut := maxf(tug, haul * (1.0 - Anim.span(t, 5.0, 5.3)))
	IntroKit.leash(c, m["ring"], knot, lerpf(40.0, 0.0, taut))
	if haul > 0.0 and t < 5.0:
		IntroKit.speed_lines(c, mpos + Vector2(60, -60), Vector2.LEFT, 80.0, 3, 0.6)
		for k in range(3):
			IntroKit.puff(c, mpos + Vector2(70.0 + float(k) * 24.0, -10.0 - float(k % 2) * 12.0), 12.0 - float(k) * 3.0,
				0.9 * (1.0 - Anim.span(t, 4.2, 5.0)))
	# stars round her head after the bonk
	if dazed > 0.0:
		var head: Vector2 = m["mouth"] + Vector2(-30, -70)
		for k in range(4):
			var a := t_real * 5.0 + float(k) * TAU / 4.0
			var sp := head + Vector2(cos(a) * 46.0, sin(a) * 14.0)
			_star(c, sp, 9.0)
	# the subtitle and the prompt, once she has it sorted
	if t_real > 7.4:
		var tt := t_real - 7.4 + 1.1
		IntroTitle.draw(c, tt, "none-letters")
	IntroKit.fade(c, 1.0 - Anim.span(t_real, 0.0, 0.7))


static func _star(c: CanvasItem, at: Vector2, r: float) -> void:
	var pts := PackedVector2Array()
	for i in range(10):
		var rr := r if i % 2 == 0 else r * 0.45
		pts.append(at + Vector2.from_angle(-PI * 0.5 + TAU * float(i) / 10.0) * rr)
	var fat := PackedVector2Array()
	for i in range(10):
		var rr2 := (r + 3.0) if i % 2 == 0 else (r * 0.45 + 3.0)
		fat.append(at + Vector2.from_angle(-PI * 0.5 + TAU * float(i) / 10.0) * rr2)
	c.draw_colored_polygon(fat, IntroKit.INK)
	c.draw_colored_polygon(pts, Color(1.0, 0.86, 0.30))
