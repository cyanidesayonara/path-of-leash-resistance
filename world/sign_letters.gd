extends RefCounted

# Letters as strokes, for writing a walk's name OUT OF something: fallen
# leaves, fruit, tiles, twigs, puddles, spray paint, scrap plate.
#
# A font can only be drawn as a font. To lay oranges along the letters of
# EL MERCAT, or pave LA RAMBLA in tesserae, the game needs to know where the
# letters' lines ARE, so each capital here is a few polylines on a grid four
# units wide and six tall (y down), drawn the way a hand would: single
# strokes, round letters as runs of points. layout() places a whole name,
# centred on a point and fitted to a width; points() walks its strokes at a
# spacing, which is where a material puts its pieces.

const CAP := 6.0
const GAP := 1.5
const SPACE := 2.6
# accented capitals: [base letter, the mark added to it]
const ACCENTED := {
	"À": ["A", "grave"], "È": ["E", "grave"], "É": ["E", "acute"], "Í": ["I", "acute"],
	"Ï": ["I", "diaeresis"], "Ò": ["O", "grave"], "Ó": ["O", "acute"], "Ú": ["U", "acute"],
	"Ü": ["U", "diaeresis"], "Ç": ["C", "cedilla"],
}

# an ellipse's outline, for O, Q and the round parts of other letters
static func _arc(cx: float, cy: float, rx: float, ry: float, a0: float, a1: float, n: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in range(n + 1):
		var a := lerpf(a0, a1, float(i) / float(n))
		out.append(Vector2(cx + cos(a) * rx, cy + sin(a) * ry))
	return out


static func _p(pts: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for q in pts:
		out.append(Vector2(float(q[0]), float(q[1])))
	return out


# [advance width, [polyline, ...]] for one character, or [] if unknown
static func glyph(ch: String) -> Array:
	match ch:
		"A": return [4.0, [_p([[0, 6], [2, 0], [4, 6]]), _p([[0.75, 4], [3.25, 4]])]]
		"B": return [3.8, [_p([[0, 6], [0, 0], [2.6, 0], [3.4, 0.6], [3.5, 1.9], [2.8, 2.8], [0, 2.9]]),
			_p([[2.8, 2.9], [3.7, 3.6], [3.8, 5.1], [3.0, 6], [0, 6]])]]
		"C": return [4.0, [_arc(2.2, 3, 2.2, 3, -0.75, -TAU + 0.75, 14)]]
		"D": return [4.0, [_p([[0, 0], [0, 6], [1.8, 6]]), _arc(1.8, 3, 2.2, 3, PI * 0.5, -PI * 0.5, 10),
			_p([[1.8, 0], [0, 0]])]]
		"E": return [3.6, [_p([[3.6, 0], [0, 0], [0, 6], [3.6, 6]]), _p([[0, 3], [2.8, 3]])]]
		"F": return [3.6, [_p([[3.6, 0], [0, 0], [0, 6]]), _p([[0, 3], [2.8, 3]])]]
		"G": return [4.2, [_arc(2.2, 3, 2.2, 3, -0.75, -TAU + 0.35, 14), _p([[4.2, 4.0], [4.2, 3.3], [2.5, 3.3]])]]
		"H": return [4.0, [_p([[0, 0], [0, 6]]), _p([[4, 0], [4, 6]]), _p([[0, 3], [4, 3]])]]
		"I": return [0.0, [_p([[0, 0], [0, 6]])]]
		"J": return [3.4, [_p([[3.4, 0], [3.4, 4.4]]), _arc(1.7, 4.4, 1.7, 1.6, 0.0, PI, 7)]]
		"K": return [3.8, [_p([[0, 0], [0, 6]]), _p([[3.8, 0], [0, 3.7]]), _p([[1.3, 2.6], [3.9, 6]])]]
		"L": return [3.4, [_p([[0, 0], [0, 6], [3.4, 6]])]]
		"M": return [4.8, [_p([[0, 6], [0, 0], [2.4, 3.8], [4.8, 0], [4.8, 6]])]]
		"N": return [4.0, [_p([[0, 6], [0, 0], [4, 6], [4, 0]])]]
		"O": return [4.6, [_arc(2.3, 3, 2.3, 3, 0.0, TAU, 18)]]
		"P": return [3.7, [_p([[0, 6], [0, 0], [2.3, 0]]), _arc(2.3, 1.6, 1.4, 1.6, -PI * 0.5, PI * 0.5, 7),
			_p([[2.3, 3.2], [0, 3.2]])]]
		"Q": return [4.6, [_arc(2.3, 3, 2.3, 3, 0.0, TAU, 18), _p([[2.9, 4.6], [4.5, 6.4]])]]
		"R": return [3.8, [_p([[0, 6], [0, 0], [2.3, 0]]), _arc(2.3, 1.6, 1.4, 1.6, -PI * 0.5, PI * 0.5, 7),
			_p([[2.3, 3.2], [0, 3.2]]), _p([[2.0, 3.2], [3.8, 6]])]]
		"S": return [3.8, [_p([[3.7, 0.9], [2.9, 0.1], [1.8, 0], [0.8, 0.3], [0.2, 1.1], [0.3, 2.1],
			[1.2, 2.8], [2.5, 3.2], [3.5, 3.8], [3.9, 4.8], [3.4, 5.6], [2.3, 6], [1.0, 5.9], [0.1, 5.1]])]]
		"T": return [4.0, [_p([[0, 0], [4, 0]]), _p([[2, 0], [2, 6]])]]
		"U": return [4.0, [_p([[0, 0], [0, 4]]), _arc(2, 4, 2, 2, PI, 0.0, 9), _p([[4, 4], [4, 0]])]]
		"V": return [4.2, [_p([[0, 0], [2.1, 6], [4.2, 0]])]]
		"W": return [5.4, [_p([[0, 0], [1.35, 6], [2.7, 1.6], [4.05, 6], [5.4, 0]])]]
		"X": return [4.0, [_p([[0, 0], [4, 6]]), _p([[4, 0], [0, 6]])]]
		"Y": return [4.0, [_p([[0, 0], [2, 3]]), _p([[4, 0], [2, 3], [2, 6]])]]
		"Z": return [3.8, [_p([[0, 0], [3.8, 0], [0, 6], [3.8, 6]])]]
		"'": return [0.3, [_p([[0.3, 0], [0.1, 1.5]])]]
		"-": return [2.2, [_p([[0, 3.2], [2.2, 3.2]])]]
		".": return [0.3, [_p([[0.1, 5.7], [0.2, 6]])]]
		"<": return [2.6, [_p([[2.6, 1], [0, 3], [2.6, 5]])]]
		">": return [2.6, [_p([[0, 1], [2.6, 3], [0, 5]])]]
	# the Catalan names need their accents: the base letter and one more stroke
	if ACCENTED.has(ch):
		var base: Array = glyph(String(ACCENTED[ch][0]))
		var w: float = base[0]
		var strokes: Array = (base[1] as Array).duplicate()
		var c := w * 0.5
		match String(ACCENTED[ch][1]):
			"grave": strokes.append(_p([[c - 0.7, -1.7], [c + 0.5, -0.7]]))
			"acute": strokes.append(_p([[c + 0.7, -1.7], [c - 0.5, -0.7]]))
			"diaeresis":
				strokes.append(_p([[c - 1.0, -1.1], [c - 0.8, -0.9]]))
				strokes.append(_p([[c + 0.8, -1.1], [c + 1.0, -0.9]]))
			"cedilla": strokes.append(_p([[c, 6.0], [c + 0.6, 6.7], [c - 0.4, 7.4]]))
		return [w, strokes]
	return []


static func _advance(ch: String) -> float:
	if ch == " ":
		return SPACE
	var g := glyph(ch)
	return (float(g[0]) + GAP) if not g.is_empty() else SPACE


# the width of a name at cap height `h`, before any fitting
static func width(txt: String, h: float) -> float:
	var u := 0.0
	for i in range(txt.length()):
		u += _advance(txt.substr(i, 1))
	return maxf(0.0, u - GAP) * h / CAP


# A name as world-space polylines, centred on `at`, at cap height `h`, shrunk
# to fit `max_w` if it would run wider. Returns [polylines, height used].
static func layout(txt: String, at: Vector2, h: float, max_w := INF) -> Array:
	var up := txt.to_upper()
	var w := width(up, h)
	if w > max_w and w > 0.0:
		h *= max_w / w
		w = max_w
	var k := h / CAP
	var x := at.x - w * 0.5
	var top := at.y - h
	var out: Array[PackedVector2Array] = []
	for i in range(up.length()):
		var ch := up.substr(i, 1)
		var g := glyph(ch)
		if not g.is_empty():
			for line: PackedVector2Array in g[1]:
				var pl := PackedVector2Array()
				for q in line:
					pl.append(Vector2(x + q.x * k, top + q.y * k))
				out.append(pl)
		x += _advance(ch) * k
	return [out, h]


# Points every `step` along every stroke, ends included: where the pieces go.
static func points(lines: Array, step: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for pl: PackedVector2Array in lines:
		if pl.size() == 0:
			continue
		out.append(pl[0])
		var carry := 0.0
		for i in range(1, pl.size()):
			var a := pl[i - 1]
			var b := pl[i]
			var seg := a.distance_to(b)
			var d := step - carry
			while d <= seg:
				out.append(a.lerp(b, d / seg))
				d += step
			carry = seg - (d - step)
		if out[out.size() - 1].distance_to(pl[pl.size() - 1]) > step * 0.4:
			out.append(pl[pl.size() - 1])
	return out
