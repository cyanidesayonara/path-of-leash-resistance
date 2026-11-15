extends Node2D

# Draws the off-leash games (systems/freedom_games.gd) in two layers: the
# ground layer under the dogs (the course's lane, flags, jumps, poles) and the
# cover layer over them (the tunnel's tube, which she disappears into, and the
# rope between two dogs in a tug).

var main: Node2D
var cover := false
var _b: ShapeBatch


func setup(m: Node2D, is_cover: bool) -> void:
	main = m
	cover = is_cover


var _was_rope := true


# Redraw only what moves: the flags wave (half rate is plenty), and over the
# dogs only a rope in play moves - the tunnel itself stands still.
func _process(_delta: float) -> void:
	if not visible or main == null:
		return
	if cover:
		var rope: bool = main.tug != null or main.rope_carry_t > 0.0
		if rope or rope != _was_rope:
			queue_redraw()
		_was_rope = rope
	elif Engine.get_process_frames() % 2 == 0:
		queue_redraw()


# a dropped rope appears or is picked up: one redraw
func refresh() -> void:
	queue_redraw()


const HER := Color(0.42, 0.86, 0.46)      # her side of a tug: the meter, her win line
const THEIRS := Color(0.98, 0.52, 0.30)   # the other dog's
const CHALK := Color(0.96, 0.95, 0.88)
const RIBBON := Color(0.93, 0.36, 0.30)    # a red rag knotted round the middle
const LINE_HALF := 22.0
const METER_W := 70.0
const METER_H := 8.0
const METER_UP := 46.0


func _draw() -> void:
	if main == null:
		return
	_b = ShapeBatch.new(self)
	if cover:
		if main.agility != null:
			main.agility.draw_cover(_b)
		_draw_rope_cover()
	else:
		if main.agility != null:
			main.agility.draw_ground(_b, AnimClock.msec() / 1000.0)
		if main.pigeon_game != null:
			main.pigeon_game.draw_ground(_b)
		if main.wave_game != null and not main.wave_game.done:
			_draw_waves(main.wave_game)
		if main.tug != null:
			_draw_tug_ground(main.tug)
	_b.flush()


const SURF := Color(0.40, 0.74, 0.78, 0.55)
const FOAM := Color(0.98, 0.99, 1.0, 0.85)
const WET_SAND := Color(0.62, 0.55, 0.42, 0.35)


# the wave game's water up the sand: a sheet from the shoreline to its edge,
# a line of foam at the edge, the wet sand it leaves as it drains, and the
# crest building out at sea before it comes (the telegraph)
func _draw_waves(wg: WaveGame) -> void:
	var r: Rect2 = main._freedom_rect()
	var top := r.position.y
	var bot := r.end.y
	var off := wg.front_off()
	var step := 40.0
	var y := top
	var wet := wg.phase == WaveGame.P.DRAIN or wg.phase == WaveGame.P.LULL
	while y < bot:
		var y2 := minf(y + step, bot)
		var s1: float = main.beach_shore_x(y)
		var s2: float = main.beach_shore_x(y2)
		var w1 := sin(y * 0.031 + float(wg.wave)) * 6.0
		var w2 := sin(y2 * 0.031 + float(wg.wave)) * 6.0
		if wet:
			_b.quad(Vector2(s1, y), Vector2(s1 + SURGE_WET, y), Vector2(s2 + SURGE_WET, y2), Vector2(s2, y2), WET_SAND)
		if off > 1.0:
			_b.quad(Vector2(s1, y), Vector2(s1 + off + w1, y), Vector2(s2 + off + w2, y2), Vector2(s2, y2), SURF)
			_b.line(Vector2(s1 + off + w1, y), Vector2(s2 + off + w2, y2), FOAM, 4.0)
		var k := wg.crest()
		if k > 0.0:
			var cx1 := s1 - 70.0 + 30.0 * k
			var cx2 := s2 - 70.0 + 30.0 * k
			_b.line(Vector2(cx1 + w1, y), Vector2(cx2 + w2, y2), Color(1, 1, 1, 0.4 + 0.5 * k), 2.0 + 5.0 * k)
		y = y2


const SURGE_WET := 110.0


func _draw_rope_cover() -> void:
	var fd: Node2D = main.tug_dog
	if main.tug != null and is_instance_valid(fd):
		var tug: RopeTug = main.tug
		var a: Vector2 = main.dog.global_position + main.dog.facing * 18.0
		var b: Vector2 = fd.global_position + fd.face * 15.0
		FreedomGames.draw_rope(_b, a, b, tug.bend)
		_draw_ribbon((a + b) * 0.5 + (b - a).normalized().orthogonal() * tug.bend, (b - a).normalized())
		_draw_meter(tug, a, b)
		if tug.phase == RopeTug.P.WIND:
			_draw_growl(fd, tug.wind_amount())
	elif main.rope_carry_t > 0.0:
		var m0: Vector2 = main.dog.global_position + main.dog.facing * 16.0
		FreedomGames.draw_rope(_b, m0, m0 + main.dog.facing.rotated(0.6) * 34.0)
	elif main.rope_loose.x < INF:
		var p: Vector2 = main.rope_loose
		FreedomGames.draw_rope(_b, p + Vector2(-17, 4), p + Vector2(17, -4), 3.0)


# chalked on the grass: where the ribbon started, and the line each side
# has to drag it past
func _draw_tug_ground(tug: RopeTug) -> void:
	var side := tug.axis.orthogonal()
	var lines := [[0.0, CHALK, 0.55], [1.0, HER, 0.75], [-1.0, THEIRS, 0.75]]
	for l: Array in lines:
		var c: Vector2 = tug.line_at(float(l[0]))
		var col: Color = l[1]
		col.a = float(l[2])
		# dashed, as chalk on rough ground
		for k in range(4):
			var u0 := -1.0 + float(k) * 0.5
			_b.line(c + side * LINE_HALF * u0, c + side * LINE_HALF * (u0 + 0.36), col, 3.0)


func _draw_ribbon(at: Vector2, along: Vector2) -> void:
	var n := along.orthogonal()
	var ink := Color(0.12, 0.1, 0.09)
	for s: float in [-1.0, 1.0]:
		var tip := at + n * 7.0 * s + along * 2.4 * s
		var t2 := at + n * 7.0 * s - along * 2.4 * s
		_b.polygon(PackedVector2Array([at, tip + (tip - at).normalized() * 1.2, t2 + (t2 - at).normalized() * 1.2]), ink)
		_b.polygon(PackedVector2Array([at, tip, t2]), RIBBON)
	_b.circle(at, 2.6, ink)
	_b.circle(at, 1.8, RIBBON)


# a small bar over the two of them: the ribbon's way, her side green, theirs
# orange, her end on whichever side of the screen she is
func _draw_meter(tug: RopeTug, a: Vector2, b: Vector2) -> void:
	var her_right := a.x >= b.x
	var mid := (a + b) * 0.5 - Vector2(0.0, METER_UP)
	var half := METER_W * 0.5
	var r := Rect2(mid.x - half, mid.y - METER_H * 0.5, METER_W, METER_H)
	var ink := Color(0.10, 0.09, 0.09, 0.85)
	_b.rect(r.grow(2.0), ink)
	_b.rect(r, Color(0.24, 0.22, 0.21, 0.9))
	# the ends: whose win each is
	var her_x := r.end.x if her_right else r.position.x
	var their_x := r.position.x if her_right else r.end.x
	_b.rect(Rect2(her_x - 2.0, r.position.y, 4.0, METER_H), HER)
	_b.rect(Rect2(their_x - 2.0, r.position.y, 4.0, METER_H), THEIRS)
	var bal := tug.balance()
	var to := mid.x + bal * half * (1.0 if her_right else -1.0)
	var col := HER if bal >= 0.0 else THEIRS
	_b.rect(Rect2(minf(mid.x, to), r.position.y + 1.5, absf(to - mid.x), METER_H - 3.0), col)
	_b.rect(Rect2(mid.x - 1.0, r.position.y - 2.0, 2.0, METER_H + 4.0), CHALK)
	# the ribbon's mark on the bar
	_b.circle(Vector2(to, mid.y), 4.2, ink)
	_b.circle(Vector2(to, mid.y), 3.0, RIBBON)


# the wind-up: the other dog gets low and growls, marks shaking off its head
func _draw_growl(fd: Node2D, k: float) -> void:
	var face: Vector2 = fd.face
	var head: Vector2 = fd.global_position + face * 10.0
	var side := face.orthogonal()
	var col := Color(0.98, 0.52, 0.30, 0.35 + 0.55 * k)
	var wob := sin(AnimClock.msec() * 0.06) * 1.5
	for s: float in [-1.0, 1.0]:
		var base := head + side * s * (16.0 + 4.0 * k) - face * 4.0
		var out := side * s
		_b.line(base, base + out * 5.0 + face * (3.0 + wob), col, 2.0)
		_b.line(base - face * 6.0, base - face * 6.0 + out * 6.0 + face * (2.0 - wob), col, 2.0)
