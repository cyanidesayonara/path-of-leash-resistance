extends Node2D

# Everything the world says out loud, at the thing that said it, in three
# looks that cannot be mistaken for each other or for the HUD:
#
#   SAY    a speech bubble: somebody in the world talking ("excuse me - go
#          on", "my wallet?!"). White, rounded, a tail down to the speaker,
#          dark lower-case text. It holds still and is read, then goes.
#   SFX    a sound: "plop", "THUMP", "SNORT!", "quack!". Heavy comic
#          lettering, tilted, outlined, punching in and gone quickly.
#   SCORE  something earned or lost right there: "snack +1", "marked! +3".
#          A small word and a gold chip with a bone on it (red when it is a
#          loss), rising as it fades.
#
# These used to be one Label each in one style, so a stranger's apology, a
# splash and a +3 all looked alike and piled on each other. They are drawn
# here in one pass, newest on top, and a new pop that would land on a live
# one moves up clear of it.

const Kit := preload("res://hud/ui_kit.gd")
const Icons := preload("res://hud/ui_icons.gd")

enum Kind { SAY, SFX, SCORE }

const LIFE := {Kind.SAY: 2.0, Kind.SFX: 0.85, Kind.SCORE: 1.1}
const RISE := {Kind.SAY: 0.0, Kind.SFX: 14.0, Kind.SCORE: 34.0}
const SAY_PX := 14
const SFX_PX := 22
const SCORE_PX := 15
# pops closer than this to a live one stack above it
const STACK_GAP := 26.0
const MAX_POPS := 14

var pops: Array[Dictionary] = []
var _t := 0.0


func _ready() -> void:
	z_index = 100


# A score is anything ending in "+N" or "-N"; the caller says when it is
# speech; everything else is a sound.
static func classify(text: String) -> int:
	var parts := text.strip_edges().rsplit(" ", true, 1)
	var tail: String = parts[parts.size() - 1]
	if tail.length() > 1 and (tail.begins_with("+") or tail.begins_with("-")) and tail.substr(1).is_valid_int():
		return Kind.SCORE
	return Kind.SFX


func add(pos: Vector2, text: String, col: Color, kind := -1) -> Dictionary:
	if kind < 0:
		kind = classify(text)
	var p := {"pos": pos, "text": text, "col": col, "kind": kind, "t": 0.0,
		"tilt": (fmod(absf(sin(float(pops.size()) * 7.31 + pos.x * 0.13)) * 10.0, 1.0) - 0.5) * 0.24}
	if kind == Kind.SCORE:
		var parts := text.strip_edges().rsplit(" ", true, 1)
		p["word"] = parts[0] if parts.size() > 1 else ""
		p["amount"] = parts[parts.size() - 1]
	# stack clear of whatever is already there
	for _pass in range(4):
		var moved := false
		for q: Dictionary in pops:
			var qp: Vector2 = q.pos
			if absf(qp.x - float(p.pos.x)) < 90.0 and absf(qp.y - float(p.pos.y)) < STACK_GAP:
				p.pos = Vector2(float(p.pos.x), qp.y - STACK_GAP)
				moved = true
		if not moved:
			break
	pops.append(p)
	while pops.size() > MAX_POPS:
		pops.remove_at(0)
	queue_redraw()
	return p


func _process(delta: float) -> void:
	if pops.is_empty():
		return
	var i := pops.size() - 1
	while i >= 0:
		var p: Dictionary = pops[i]
		p.t = float(p.t) + delta
		if float(p.t) >= float(LIFE[int(p.kind)]):
			pops.remove_at(i)
		i -= 1
	queue_redraw()


func _draw() -> void:
	for p: Dictionary in pops:
		var life: float = LIFE[int(p.kind)]
		var t: float = p.t
		var fade: float = clampf((life - t) / (life * 0.35), 0.0, 1.0)
		var at: Vector2 = (p.pos as Vector2) - Vector2(0, float(RISE[int(p.kind)]) * t / life)
		match int(p.kind):
			Kind.SAY:
				_say(at, String(p.text), fade, t)
			Kind.SFX:
				_sfx(at, String(p.text), p.col, fade, t, float(p.tilt))
			Kind.SCORE:
				_score(at, String(p.word), String(p.amount), p.col, fade, t)


func _say(at: Vector2, text: String, a: float, t: float) -> void:
	var f := Kit.body()
	var w := Kit.text_w(f, text, SAY_PX) + 18.0
	var h := 24.0
	# the bubble pops open over the first tenth of a second
	var s := minf(1.0, t / 0.1)
	var r := Rect2(at.x - w * 0.5 * s, at.y - h - 10.0, w * s, h)
	var ink := Color(0.12, 0.11, 0.12, a)
	draw_rect(Rect2(r.position + Vector2(2, 2), r.size), Color(0, 0, 0, 0.18 * a))
	draw_colored_polygon(PackedVector2Array([Vector2(at.x - 5.0, r.end.y - 1.0), Vector2(at.x + 5.0, r.end.y - 1.0),
		Vector2(at.x - 1.0, at.y)]), Color(0.98, 0.97, 0.94, a))
	draw_rect(r, Color(0.98, 0.97, 0.94, a))
	draw_rect(r, Color(0.2, 0.18, 0.2, 0.35 * a), false, 1.0)
	if s >= 1.0:
		draw_string(f, Vector2(r.position.x + 9.0, r.position.y + 17.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, SAY_PX, ink)


func _sfx(at: Vector2, text: String, col: Color, a: float, t: float, tilt: float) -> void:
	var f := Kit.display()
	var punch := lerpf(1.45, 1.0, clampf(t / 0.12, 0.0, 1.0))
	var w := Kit.text_w(f, text, SFX_PX)
	draw_set_transform(at, tilt, Vector2(punch, punch))
	var pos := Vector2(-w * 0.5, 0.0)
	f.draw_string_outline(get_canvas_item(), pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, SFX_PX, 7,
		Color(0.06, 0.05, 0.08, 0.85 * a))
	f.draw_string(get_canvas_item(), pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, SFX_PX,
		Color(col.r, col.g, col.b, a))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _score(at: Vector2, word: String, amount: String, col: Color, a: float, t: float) -> void:
	var f := Kit.body()
	var fd := Kit.display()
	var loss := amount.begins_with("-")
	var chip_col := Color(0.86, 0.34, 0.28, a) if loss else Color(0.96, 0.76, 0.30, a)
	var aw := Kit.text_w(fd, amount, SCORE_PX)
	var ww := Kit.text_w(f, word, SCORE_PX) if word != "" else 0.0
	var chip_w := aw + 30.0
	var total := chip_w + (ww + 6.0 if word != "" else 0.0)
	var x := at.x - total * 0.5
	if word != "":
		f.draw_string_outline(get_canvas_item(), Vector2(x, at.y), word, HORIZONTAL_ALIGNMENT_LEFT, -1, SCORE_PX, 5,
			Color(0.05, 0.04, 0.06, 0.8 * a))
		f.draw_string(get_canvas_item(), Vector2(x, at.y), word, HORIZONTAL_ALIGNMENT_LEFT, -1, SCORE_PX,
			Color(col.r, col.g, col.b, a))
		x += ww + 6.0
	var punch := lerpf(1.3, 1.0, clampf(t / 0.12, 0.0, 1.0))
	var r := Rect2(x, at.y - 15.0, chip_w, 20.0)
	draw_set_transform(r.get_center(), 0.0, Vector2(punch, punch))
	var rr := Rect2(-r.size * 0.5, r.size)
	draw_rect(Rect2(rr.position + Vector2(1.5, 1.5), rr.size), Color(0, 0, 0, 0.25 * a))
	draw_rect(rr, chip_col)
	Icons.draw_bone(self, Vector2(rr.position.x + 11.0, 0.0), 7.0, Color(0.20, 0.14, 0.08, a))
	draw_string(fd, Vector2(rr.position.x + 21.0, 5.5), amount, HORIZONTAL_ALIGNMENT_LEFT, -1, SCORE_PX,
		Color(0.16, 0.10, 0.06, a))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
