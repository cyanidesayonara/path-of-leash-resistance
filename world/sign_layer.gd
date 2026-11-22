extends Node2D

# The walk's name, HOME and the words over the gate (world/world_sign.gd), on
# their own canvas.
#
# A sign is a hundred-odd loose pieces, each several shapes, and drawing them
# in main's world pass cost 3.5-4.5 ms of every 30 fps world redraw natively,
# several times that in the browser, to repeat a picture that had not
# changed: the pieces lie still until something walks through them. This
# canvas is redrawn only when its picture can differ - a sign comes into or
# leaves view, a piece moves (the sign's `rev`), the signs are rebuilt, or one
# is animating - and world-space canvas items keep the last picture for free.
#
# Each sign is painted at SUPERSAMPLE times its size into its own offscreen
# texture, and the texture is drawn here smoothed. Painted straight onto the
# world, its hundreds of small hard-edged shapes (the world has no 2D
# antialiasing) snapped from pixel to pixel as the camera slid by fractions
# of one, and a name shimmered whenever the camera moved; a filtered texture
# slides smoothly. The offscreen pass runs only when the picture changes.
#
# It must be main's first child at main's z, so it draws straight after the
# world pass and below everything else, exactly where the signs used to be.

const WorldSign := preload("res://world/world_sign.gd")

# how many texture pixels to a world unit
const SUPERSAMPLE := 2.0
# room round a sign's pieces for their shadows, rings and a kicked piece
const PAD := 40.0
# the largest texture side a sign may take, whatever its extent
const MAX_SIDE := 4096
# bucket SubViewport allocations so small rolling-piece bounds growth does not
# reallocate the offscreen texture every redraw
const ALLOC_STEP := 128


class Painter extends Node2D:
	var sign: Dictionary = {}
	var light := Vector2.ZERO

	func _draw() -> void:
		if sign.is_empty():
			return
		var b := ShapeBatch.new(self)
		# a sign is a few hundred small discs: sides they can show, not 64 each
		b.lod = true
		WorldSign.draw(b, sign, AnimClock.msec() / 1000.0, light)
		b.flush()


var main: Node2D
var _vt := 0.0
var _vb := 0.0
var _show := true
# what the last picture showed: rebuild count, then each sign drawn and its
# rev, then whether any of them was animating
var _key := PackedInt64Array()
# per sign index: {"vp": SubViewport, "painter": Painter, "rect": Rect2, "src": Rect2, "rev": int, "light": Vector2, "was_live": bool}
var _paint := {}
var _built := -1


func setup(m: Node2D) -> void:
	main = m
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	# the offscreen pass blends onto clear black, so its colours come out
	# already multiplied by their coverage: drawn with plain alpha they are
	# multiplied again, and every soft edge gets a dark rim
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_PREMULT_ALPHA
	material = mat


# Called from main's world pass with the band it was drawn for and whether
# the signs show at all; redraws only when that changes the picture, and
# says whether it did.
func refresh(vt: float, vb: float, show: bool) -> bool:
	var now := AnimClock.msec() / 1000.0
	var key := PackedInt64Array()
	key.append(int(main.signs_built))
	var live := false
	var shown: Array[int] = []
	if show:
		var signs: Array[Dictionary] = main.signs
		for i in range(signs.size()):
			var sg: Dictionary = signs[i]
			if not main.sign_shown(sg, vt, vb):
				continue
			key.append(i)
			key.append(int(sg.get("rev", 0)))
			shown.append(i)
			live = live or WorldSign.animated(sg, now)
	key.append(1 if live else 0)
	if not live and key == _key:
		return false
	_key = key
	_vt = vt
	_vb = vb
	_show = show
	_repaint(shown, now)
	queue_redraw()
	return true


# the world rect a sign's picture needs: its pieces or strokes, padded
static func extent(sg: Dictionary) -> Rect2:
	var lo := Vector2(INF, float(sg.top))
	var hi := Vector2(-INF, float(sg.bottom))
	for pc: Dictionary in sg.pieces:
		var p: Vector2 = pc.p
		lo = lo.min(p)
		hi = hi.max(p)
	for pl: PackedVector2Array in sg.lines:
		for v in pl:
			lo = lo.min(v)
			hi = hi.max(v)
	if lo.x > hi.x:
		return Rect2()
	var pad := PAD + float(sg.h) * 0.5
	var r := Rect2(lo - Vector2(pad, pad), hi - lo + Vector2(pad, pad) * 2.0)
	# a flower bed the sign is planted in, shared with the line above it
	if sg.has("planter") and not bool(sg.get("bed_shared", false)):
		r = r.merge((sg.planter as Rect2).grow(PAD))
	return r


# paint every shown sign whose picture changed into its texture
func _repaint(shown: Array[int], now: float) -> void:
	if int(main.signs_built) != _built:
		_built = int(main.signs_built)
		for k: int in _paint:
			(_paint[k].vp as SubViewport).queue_free()
		_paint.clear()
	var signs: Array[Dictionary] = main.signs
	for i: int in shown:
		var sg: Dictionary = signs[i]
		var rev := int(sg.get("rev", 0))
		var sg_live := WorldSign.animated(sg, now)
		var e: Dictionary = _paint.get(i, {})
		if not e.is_empty() and not sg_live and not bool(e.get("was_live", false)) and int(e.get("rev", -1)) == rev and e.get("light", Vector2.INF) == Shade.light:
			continue
		var r := extent(sg)
		if r.size.x <= 0.0:
			continue
		var px := Vector2i(mini(ceili(r.size.x * SUPERSAMPLE), MAX_SIDE), mini(ceili(r.size.y * SUPERSAMPLE), MAX_SIDE))
		var alloc := Vector2i(
			mini(((px.x + ALLOC_STEP - 1) / ALLOC_STEP) * ALLOC_STEP, MAX_SIDE),
			mini(((px.y + ALLOC_STEP - 1) / ALLOC_STEP) * ALLOC_STEP, MAX_SIDE),
		)
		if e.is_empty():
			var vp := SubViewport.new()
			vp.transparent_bg = true
			vp.disable_3d = true
			vp.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
			var painter := Painter.new()
			vp.add_child(painter)
			add_child(vp)
			e = {"vp": vp, "painter": painter}
			_paint[i] = e
		var vp: SubViewport = e.vp
		if vp.size.x < px.x or vp.size.y < px.y:
			vp.size = Vector2i(maxi(vp.size.x, alloc.x), maxi(vp.size.y, alloc.y))
		var painter: Painter = e.painter
		var k := Vector2(float(px.x) / r.size.x, float(px.y) / r.size.y)
		painter.scale = k
		painter.position = -r.position * k
		painter.sign = sg
		painter.light = Shade.light
		painter.queue_redraw()
		vp.render_target_update_mode = SubViewport.UPDATE_ONCE
		e.rect = r
		e.src = Rect2(Vector2.ZERO, Vector2(px))
		e.rev = rev
		e.light = Shade.light
		e.was_live = sg_live


func _draw() -> void:
	if main == null or not _show:
		return
	for i: int in _paint:
		var e: Dictionary = _paint[i]
		if not e.has("rect") or i >= main.signs.size():
			continue
		if not main.sign_shown(main.signs[i], _vt, _vb):
			continue
		draw_texture_rect_region((e.vp as SubViewport).get_texture(), e.rect, e.src, Color.WHITE, false)
