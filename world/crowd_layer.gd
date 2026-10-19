extends Node2D

# Every visible person in a CrowdRiver, in one ShapeBatch, redrawn at 30 fps
# like the NPC pairs. A match fan is six shapes. A shopper is a coat and a
# head; their umbrella is a second layer of this same script, above the leash,
# because the canopy is overhead and the strap is at the waist. Darker and
# smaller than the pair. Fans are data; nothing here is a body or a rope contact.

const Partit := preload("res://systems/partit.gd")
const REDRAW := 0.033
const BAND := 520.0

const COATS: Array[Color] = [
	Color(0.18, 0.24, 0.36), Color(0.46, 0.22, 0.18),
	Color(0.28, 0.34, 0.26), Color(0.24, 0.22, 0.24),
]
const CANOPIES: Array[Color] = [
	Color(0.72, 0.16, 0.18), Color(0.16, 0.28, 0.48),
	Color(0.78, 0.62, 0.18), Color(0.14, 0.14, 0.16), Color(0.52, 0.60, 0.46),
]

var main: Node2D
var river: CrowdRiver
# the overhead pass: canopies only, so the leash draws under them
var draw_canopies := false
var _acc := 0.0
var flush_count := 0
var _cost_us := 0
var _cost_n := 0
var _blue: Color = Partit.HOME_BLUE.darkened(0.22)
var _claret: Color = Partit.HOME_CLARET.darkened(0.22)
var _orange: Color = Partit.AWAY_ORANGE.darkened(0.22)
var _slate: Color = Partit.AWAY_SLATE.darkened(0.22)
var _skin: Array[Color] = []
var _hair: Array[Color] = []


func setup(m: Node2D) -> void:
	main = m
	river = m.match_crowd
	_colors()


func _colors() -> void:
	if not _skin.is_empty():
		return
	for c: Color in Partit.SKINS:
		_skin.append(c.darkened(0.12))
	for c: Color in Partit.HAIRS:
		_hair.append(c.darkened(0.08))


func _process(delta: float) -> void:
	if main == null or river == null or main.phase != "out":
		return
	_acc += delta
	if _acc < REDRAW:
		return
	_acc = 0.0
	queue_redraw()


func _draw() -> void:
	if river == null or main == null or main.phase != "out" or main.cam == null:
		return
	var timed := bool(main.get("_draw_cost_on"))
	var t0 := Time.get_ticks_usec() if timed else 0
	var b := ShapeBatch.new(self)
	paint(b, main.cam.position.y)
	b.flush()
	flush_count += 1
	if timed:
		_cost_us += Time.get_ticks_usec() - t0
		_cost_n += 1
		if _cost_n >= 30:
			print("CROWDCOST %d fans %dus avg over %d draws" % [river.active_count(), _cost_us / _cost_n, _cost_n])
			_cost_us = 0
			_cost_n = 0


# one batch, however many fans are in the band
func paint(b: ShapeBatch, cam_y: float) -> void:
	_colors()
	var top := cam_y - BAND
	var bot := cam_y + BAND
	for i in river.count:
		if river.on[i] == 0:
			continue
		var y: float = river.py[i]
		if y < top or y > bot:
			continue
		if river.shuffle:
			if draw_canopies:
				_canopy(b, i)
			else:
				_shopper(b, i)
		else:
			_fan(b, i)


func _fan(b: ShapeBatch, i: int) -> void:
	var x: float = river.px[i]
	var y: float = river.py[i]
	if river.hop[i] > 0.0:
		y -= sin((1.0 - river.hop[i] / CrowdRiver.HOP_T) * PI) * 7.0
	var bob := sin(river.phase[i]) * 0.8
	var vendor := river.kind[i] == 2
	var fy := 1.0 if vendor else -1.0
	var c0: Color
	var c1: Color
	if vendor:
		c0 = Color(0.62, 0.56, 0.44)
		c1 = Color(0.14, 0.15, 0.18)
	elif river.kind[i] == 1:
		c0 = _orange
		c1 = _slate
	else:
		c0 = _blue
		c1 = _claret
	b.coarse(Vector2(x + 2.0, y + 3.0), 6.4, Color(0, 0, 0, 0.16))
	b.coarse(Vector2(x - 3.1, y + bob), 6.0, c0)
	b.coarse(Vector2(x + 3.1, y + bob), 6.0, c1)
	var head := Vector2(x, y + bob + fy * 3.6)
	var si := i % _skin.size()
	b.coarse(head, 3.9, _skin[si])
	b.coarse(head + Vector2(0.0, fy * 1.3), 2.3, _hair[si])
	if vendor:
		b.rect(Rect2(x - 5.0, y + bob + 1.5, 10.0, 3.0), Color(0.42, 0.30, 0.16))
	else:
		b.rect(Rect2(x - 6.0, y + bob - 2.2, 12.0, 2.4), c1)


func _shopper(b: ShapeBatch, i: int) -> void:
	var x: float = river.px[i]
	var y: float = river.py[i]
	var bob := sin(river.phase[i]) * 0.6
	var coat: Color = COATS[i % COATS.size()]
	b.coarse(Vector2(x + 2.0, y + 3.0), 6.2, Color(0, 0, 0, 0.18))
	b.coarse(Vector2(x, y + bob), 6.4, coat)
	var head := Vector2(x, y + bob - 4.2)
	var si := i % _skin.size()
	b.coarse(head, 3.5, _skin[si])
	b.coarse(head + Vector2(0.0, -1.1), 2.0, _hair[si])


func _canopy(b: ShapeBatch, i: int) -> void:
	var c := Vector2(river.px[i], river.py[i] - 2.0)
	main._brolly_canopy(b, c, CANOPIES[i % CANOPIES.size()], float(i) * 1.7)
