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
# It must be main's first child at main's z, so it draws straight after the
# world pass and below everything else, exactly where the signs used to be.

const WorldSign := preload("res://world/world_sign.gd")

var main: Node2D
var _vt := 0.0
var _vb := 0.0
var _show := true
# what the last picture showed: rebuild count, then each sign drawn and its
# rev, then whether any of them was animating
var _key := PackedInt64Array()


func setup(m: Node2D) -> void:
	main = m


# Called from main's world pass with the band it was drawn for and whether
# the signs show at all; redraws only when that changes the picture, and
# says whether it did.
func refresh(vt: float, vb: float, show: bool) -> bool:
	var key := PackedInt64Array()
	key.append(int(main.signs_built))
	var live := false
	if show:
		var signs: Array[Dictionary] = main.signs
		for i in range(signs.size()):
			var sg: Dictionary = signs[i]
			if not main.sign_shown(sg, vt, vb):
				continue
			key.append(i)
			key.append(int(sg.get("rev", 0)))
			live = live or WorldSign.animated(sg)
	key.append(1 if live else 0)
	if not live and key == _key:
		return false
	_key = key
	_vt = vt
	_vb = vb
	_show = show
	queue_redraw()
	return true


func _draw() -> void:
	if main == null or not _show:
		return
	# the same batching as the world pass: runs of shapes become one call
	var b := ShapeBatch.new(self)
	main.draw_signs_onto(b, _vt, _vb)
	b.flush()
