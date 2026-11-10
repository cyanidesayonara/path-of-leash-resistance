extends RefCounted

# THE STREET AFTER DARK. A lamp every so often lit the paving, and everything
# past the kerb was a dark slab: nobody home anywhere. From above, what says
# a street is lived in at night is the light that comes OUT of it: a door
# ajar, a shopfront, a bar, the blue of a television, each lying across the
# paving in a fan, and a lit window up on the roofs behind.
#
# One rule for every built-up walk, hashed from the module's index (never the
# RNG, so a seeded walk is unchanged): each doorway the edge modules already
# draw (main._draw_edge_module) is one KIND of front, and that kind is what
# spills. A walk that draws its own edges (draw_edge_layer) lists its fronts
# through a `night_fronts(m)` hook instead, as the same dictionaries.
#
# Drawn by world/light_layer.gd in its one batch, over the dog and your human
# (who are lit as they pass a doorway) and under the tree crowns, scaled by
# Game.lamp_glow(): full at night, fainter at dusk and dawn, nothing by day.
# Static: the layer only redraws as the camera moves on.

const SkyLook := preload("res://systems/sky.gd")

# the kinds: [share of doorways, width of the opening, how far the light
# reaches into the street, strength, colour]. The shares sum to under one;
# the rest are dark, because most doors are shut at night.
const KINDS := {
	"home": [0.34, 26.0, 78.0, 0.50, Color(1.0, 0.84, 0.56)],
	"shop": [0.16, 76.0, 128.0, 0.58, Color(1.0, 0.92, 0.70)],
	"bar": [0.12, 54.0, 116.0, 0.60, Color(1.0, 0.70, 0.36)],
	"tv": [0.10, 30.0, 64.0, 0.42, Color(0.56, 0.74, 1.0)],
}
const ORDER := ["home", "shop", "bar", "tv"]
# where the edge modules put their doorway, down from the module's top
const DOOR_Y_OLD := 156.0
const DOOR_Y_CITY := 168.0
# walks whose generic edge is not a row of doors: a wall, a wood, a canopy,
# a fence, a yard, or a module of the walk's own
const NO_DOORS := ["besos", "neteja", "guell", "boars", "trail", "park", "station", "site", "scrap", "market"]
const OLD_STYLE := ["oldtown", "spook", "gracia", "cremada"]
# a television's window is beside the door, not in it
const TV_OFFSET := -62.0
# the lit window up on the roof behind a lit front: how far back, its size
const ROOF_BACK := Vector2(58.0, 150.0)
const ROOF_WIN := Vector2(16.0, 22.0)
const ROOF_SHARE := 0.55
# the opening itself, a bright slit in the wall face
const SLIT_DEPTH := 9.0
const MOD := 220.0


static func _hash(k: int, salt: float) -> float:
	return fposmod(sin(float(k) * 12.9898 + salt * 78.233) * 43758.5453, 1.0)


# The kind of front a module's doorway is, or "" for a dark one.
static func kind_of(k: int) -> String:
	var h := _hash(k, 1.0)
	var acc := 0.0
	for name: String in ORDER:
		acc += float(KINDS[name][0])
		if h < acc:
			return name
	return ""


# One front: where its opening is on the building line, which way the street
# is (`dir`, +1 or -1 along x), and its kind's numbers.
static func front(at: Vector2, dir: float, kind: String, k := 0) -> Dictionary:
	var spec: Array = KINDS[kind]
	return {"at": at, "dir": dir, "kind": kind, "w": float(spec[1]), "reach": float(spec[2]),
		"a": float(spec[3]), "col": spec[4], "k": k}


# The generic built-up edge's lit fronts, one per lit doorway. A walk's own
# `night_fronts` hook adds to these in main.night_fronts().
static func build(m: Node2D) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var own_edges: bool = m.walk_mod != null and m.walk_mod.has_method("draw_edge_layer")
	if bool(m.built) and not own_edges and not NO_DOORS.has(String(m.lvl)):
		var door_y := DOOR_Y_OLD if OLD_STYLE.has(String(m.lvl)) else DOOR_Y_CITY
		var y: float = floorf(float(m.GATE_Y) / MOD) * MOD
		while y < float(m.START_Y) + MOD:
			if y + MOD * 0.5 >= float(m.GATE_Y):
				for side: float in [-1.0, 1.0]:
					# the same index the edge module is drawn with
					var k := int(absf(y) / MOD) + (0 if side < 0.0 else 7)
					var kind := kind_of(k)
					if kind == "":
						continue
					var dy := y + door_y + (TV_OFFSET if kind == "tv" else 0.0)
					if dy <= float(m.GATE_Y) + 20.0 or dy > float(m.START_Y) + 60.0:
						continue
					var bl: Vector2 = m.building_line(dy)
					var fx: float = (bl.x - 27.0) if side < 0.0 else (bl.y + 27.0)
					out.append(front(Vector2(fx, dy), -side, kind, k))
			y += MOD
	return out


# For a walk that draws its own edges: a front every `step` down both of its
# paving edges (main.walk_edges) between two depths, the same kinds by the
# same hash, `inset` px back from the edge to where its wall stands. `salt`
# keeps one walk's pattern from being another's.
static func along_edges(m: Node2D, y_from: float, y_to: float, step: float, inset := 0.0, salt := 0) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var y := maxf(y_to, float(m.GATE_Y) + 40.0)
	var i := 0
	while y < minf(y_from, float(m.START_Y) + 60.0):
		var e: Vector2 = m.walk_edges(y)
		for side: float in [-1.0, 1.0]:
			var k := i * 2 + (0 if side < 0.0 else 1) + salt * 101
			var kind := kind_of(k)
			if kind != "":
				out.append(front(Vector2(e.x - inset if side < 0.0 else e.y + inset, y), -side, kind, k))
		y += step
		i += 1
	return out


# The fronts in view, into the light layer's batch. `lit` is Game.lamp_glow().
static func draw(b: ShapeBatch, fronts: Array[Dictionary], c: Vector2, half: Vector2, lit: float, tint: Color, wet := false) -> void:
	for f: Dictionary in fronts:
		var at: Vector2 = f.at
		if absf(at.x - c.x) > half.x or absf(at.y - c.y) > half.y:
			continue
		var dir: float = f.dir
		var w: float = f.w
		var reach: float = f.reach
		var col: Color = f.col
		var a: float = float(f.a) * lit
		var light := SkyLook.light(Color(col.r, col.g, col.b, a), tint)
		# the fan across the paving: full at the opening, gone at its reach,
		# widening as it goes, its sides feathered to nothing
		var pts := PackedVector2Array()
		for row: Array in [[0.0, 0.5], [0.36, 0.78], [1.0, 1.25]]:
			var x := at.x + dir * reach * float(row[0])
			var hw := w * float(row[1])
			for cx: float in [-1.0, -0.55, 0.55, 1.0]:
				pts.append(Vector2(x, at.y + hw * cx))
		b.band(pts, 4, light, PackedFloat32Array([1.0, 0.5, 0.0]), PackedFloat32Array([0.0, 1.0, 1.0, 0.0]))
		# the opening: a bright slit set in the wall face, and its halo
		var bright := SkyLook.light(Color(lerpf(col.r, 1.0, 0.5), lerpf(col.g, 1.0, 0.5), lerpf(col.b, 1.0, 0.5), minf(1.0, 0.55 + lit * 0.45)), tint)
		var sx := at.x - dir * SLIT_DEPTH
		b.rect(Rect2(minf(sx, at.x), at.y - w * 0.42, SLIT_DEPTH, w * 0.84), bright)
		b.glow(at, w * 0.7 + 14.0, SkyLook.light(Color(col.r, col.g, col.b, 0.34 * lit), tint), 0.2)
		if wet:
			# each front's reflection in the wet paving: streaks toward the
			# viewer along the opening and across the light fan
			for s in range(3):
				var sf := float(s) / 2.0
				var rx := at.x + dir * (4.0 + sf * reach * 0.55)
				var streak_len := lerpf(w * 1.4, w * 0.8, sf)
				var streak_w := lerpf(7.0, 4.0, sf)
				var streak_bits := 5
				for k in range(streak_bits):
					var kf := float(k) / float(streak_bits)
					var sw := streak_w * (0.8 + 0.4 * absf(sin(float(k) * 2.7 + rx)))
					var y0 := at.y + w * 0.35 + kf * streak_len
					var alpha := 0.14 * lit * (1.0 - kf) * (1.0 - sf * 0.35)
					b.rect(Rect2(rx - sw * 0.5, y0, sw, streak_len / float(streak_bits) - 1.5),
						SkyLook.light(Color(col.r, col.g, col.b, alpha), tint))
		# a lit window up on the roof behind it: someone is in upstairs
		var k: int = f.k
		if _hash(k, 2.0) < ROOF_SHARE:
			var back := lerpf(ROOF_BACK.x, ROOF_BACK.y, _hash(k, 3.0))
			var wp := Vector2(at.x - dir * back, at.y + lerpf(-70.0, 50.0, _hash(k, 4.0)))
			var warm := Color(1.0, 0.86, 0.58) if f.kind != "tv" else Color(0.62, 0.78, 1.0)
			b.glow(wp, 34.0, SkyLook.light(Color(warm.r, warm.g, warm.b, 0.30 * lit), tint), 0.15)
			b.rect(Rect2(wp - ROOF_WIN * 0.5 - Vector2(2, 2), ROOF_WIN + Vector2(4, 4)), Color(0.08, 0.07, 0.09, 0.8 * lit))
			b.rect(Rect2(wp - ROOF_WIN * 0.5, ROOF_WIN), SkyLook.light(Color(warm.r, warm.g, warm.b, minf(1.0, 0.5 + lit * 0.5)), tint))
			# the glazing bar
			b.rect(Rect2(wp.x - 0.75, wp.y - ROOF_WIN.y * 0.5, 1.5, ROOF_WIN.y), Color(0.10, 0.09, 0.10, 0.7 * lit))
