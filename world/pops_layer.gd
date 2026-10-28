extends Node2D

# Everything the world says out loud, at the thing that said it, in three
# looks that cannot be mistaken for each other or for the HUD:
#
#   SAY    a speech bubble: somebody in the world talking ("Excuse me, go
#          ahead.", "My wallet?!"), in world/speech_bubble.gd's look. A
#          passing line holds still and is read, then goes; a speaker that
#          keeps talking (your human, a dare-giver) registers with
#          add_speaker and its bubble stays as long as it has a line.
#   SFX    a sound: "plop", "THUMP", "SNORT!", "quack!". Heavy comic
#          lettering, tilted, outlined, punching in and gone quickly.
#   SCORE  something earned or lost right there: "snack +1", "marked! +3".
#          A small word and a gold chip with a bone on it (red when it is a
#          loss), rising as it fades.
#
# These used to be one Label each in one style, so a stranger's apology, a
# splash and a +3 all looked alike and piled on each other. They are drawn
# here in one pass, newest on top, and a new pop that would land on a live
# one moves up clear of it. Bubbles are laid out together every frame: one
# that would cover another moves up, its tail stretching back to the
# speaker, and none leaves the screen sideways. The layer sits above every
# world layer (canopies are z 13), so nothing in the world hides a line.

const Kit := preload("res://hud/ui_kit.gd")
const Icons := preload("res://hud/ui_icons.gd")
const Bubble := preload("res://world/speech_bubble.gd")

enum Kind { SAY, SFX, SCORE }

const LIFE := {Kind.SAY: 2.0, Kind.SFX: 0.85, Kind.SCORE: 1.1}
const RISE := {Kind.SAY: 0.0, Kind.SFX: 14.0, Kind.SCORE: 34.0}
const SFX_PX := 22
const SCORE_PX := 15
# pops closer than this to a live one stack above it
const STACK_GAP := 26.0
const MAX_POPS := 14

var pops: Array[Dictionary] = []
# speakers that hold a bubble while they have something to say:
# {"node": Node, "fn": Callable}. fn returns {} for nothing, or "tip" (the
# speaker's head, in this layer's space), "text", and optionally "split" (a
# suffix that takes the second line) and "paper" (the bubble's colour).
var speakers: Array[Dictionary] = []
# per speaker: the line it is showing and for how long
var _held := {}
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


func add_speaker(node: Node, fn: Callable) -> void:
	speakers.append({"node": node, "fn": fn})


func add(pos: Vector2, text: String, col: Color, kind := -1) -> Dictionary:
	if kind < 0:
		kind = classify(text)
	var p := {"pos": pos, "text": text, "col": col, "kind": kind, "t": 0.0,
		"tilt": (fmod(absf(sin(float(pops.size()) * 7.31 + pos.x * 0.13)) * 10.0, 1.0) - 0.5) * 0.24}
	if kind == Kind.SCORE:
		var parts := text.strip_edges().rsplit(" ", true, 1)
		p["word"] = parts[0] if parts.size() > 1 else ""
		p["amount"] = parts[parts.size() - 1]
	# stack clear of whatever is already there (speech is laid out as it is
	# drawn, in _draw)
	for _pass in range(4 if kind != Kind.SAY else 0):
		var moved := false
		for q: Dictionary in pops:
			if int(q.kind) == Kind.SAY:
				continue
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
	var i_s := speakers.size() - 1
	while i_s >= 0:
		var sp: Dictionary = speakers[i_s]
		var n: Node = sp.node
		if not is_instance_valid(n) or not n.is_inside_tree():
			_held.erase(sp.get("id", 0))
			speakers.remove_at(i_s)
			i_s -= 1
			continue
		var id := n.get_instance_id()
		sp["id"] = id
		var d: Dictionary = (sp.fn as Callable).call()
		if d.is_empty() or String(d.get("text", "")) == "":
			_held.erase(id)
		else:
			var h: Dictionary = _held.get(id, {})
			if String(h.get("text", "")) != String(d.text):
				h = {"text": String(d.text), "t": 0.0}
			h["t"] = float(h.get("t", 0.0)) + delta
			h["d"] = d
			_held[id] = h
		i_s -= 1
	if pops.is_empty() and _held.is_empty():
		return
	queue_redraw()
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
	_draw_speech()
	for p: Dictionary in pops:
		var life: float = LIFE[int(p.kind)]
		var t: float = p.t
		var fade: float = clampf((life - t) / (life * 0.35), 0.0, 1.0)
		var at: Vector2 = (p.pos as Vector2) - Vector2(0, float(RISE[int(p.kind)]) * t / life)
		match int(p.kind):
			Kind.SAY:
				pass
			Kind.SFX:
				_sfx(at, String(p.text), p.col, fade, t, float(p.tilt))
			Kind.SCORE:
				_score(at, String(p.word), String(p.amount), p.col, fade, t)


# Every bubble on screen, laid out together: speakers holding a line first
# (they were there first), then passing lines oldest first. Each sits over
# its speaker, inside the screen's sides; one that would cover a bubble
# already placed moves up above it.
func _draw_speech() -> void:
	var items: Array[Dictionary] = []
	for h: Dictionary in _held.values():
		var d: Dictionary = h.d
		items.append({"tip": d.tip, "text": h.text, "split": String(d.get("split", "")),
			"paper": d.get("paper", Bubble.PAPER), "t": float(h.t), "a": 1.0})
	for p: Dictionary in pops:
		if int(p.kind) != Kind.SAY:
			continue
		var life: float = LIFE[Kind.SAY]
		items.append({"tip": p.pos, "text": String(p.text), "split": "", "paper": Bubble.PAPER,
			"t": float(p.t), "a": clampf((life - float(p.t)) / (life * 0.35), 0.0, 1.0)})
	if items.is_empty():
		return
	var vis := get_global_transform_with_canvas().affine_inverse() * get_viewport_rect()
	var placed: Array[Rect2] = []
	for it: Dictionary in items:
		var ls: Array[String] = Bubble.lines(String(it.text), String(it.split))
		var sz := Bubble.size_of(ls)
		var tip: Vector2 = it.tip
		var box := Rect2(tip.x - sz.x * 0.5, tip.y - Bubble.TAIL_H - sz.y, sz.x, sz.y)
		box.position.x = clampf(box.position.x, vis.position.x + 6.0, maxf(vis.position.x + 6.0, vis.end.x - 6.0 - sz.x))
		for _pass in range(6):
			var moved := false
			for q: Rect2 in placed:
				if q.grow(3.0).intersects(box):
					box.position.y = q.position.y - 4.0 - sz.y
					moved = true
			if not moved:
				break
		placed.append(box)
		it["box"] = box
		it["ls"] = ls
	# drawn last-placed first: a bubble lifted clear of another has a long
	# tail down past it, and the lower bubble covers that tail
	for i in range(items.size() - 1, -1, -1):
		var it: Dictionary = items[i]
		Bubble.draw(self, it.box, it.tip, it.ls, float(it.t), float(it.a), it.paper)


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
