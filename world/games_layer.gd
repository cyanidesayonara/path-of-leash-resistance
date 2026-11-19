extends Node2D

# Draws the off-leash games (systems/freedom_games.gd) in two layers: the
# ground layer under the dogs (the course's lane, flags, jumps, poles, and the
# rope between two dogs in a tug, its ends under their muzzles) and the cover
# layer over them (the tunnel's tube, which she disappears into, the tug's meter).

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
		var rope: bool = main.tug != null
		if rope or rope != _was_rope:
			queue_redraw()
		_was_rope = rope
	else:
		# her end of a rope is drawn in her mouth, by her (draw_held)
		var holding: bool = main.tug != null or main.rope_carry_t > 0.0
		if holding:
			main.dog.held = self
		elif main.dog.held == self:
			main.dog.held = null
		if main.tug != null or Engine.get_process_frames() % 2 == 0:
			queue_redraw()


# her end of the rope, between her jaws (entities/dog.gd calls this)
func draw_held(c: ShapeBatch, bite: Vector2, fwd: Vector2, side: Vector2, jaw: float) -> void:
	if main.tug != null:
		FreedomGames.draw_rope_bite(c, bite, fwd, side, jaw, 1.0)
	elif main.rope_carry_t > 0.0:
		FreedomGames.draw_rope_carried(c, bite, fwd, side, jaw)


# a dropped rope appears or is picked up: one redraw
func refresh() -> void:
	queue_redraw()


const HER := Color(0.42, 0.86, 0.46)      # her side of a tug: the meter, her win line
const THEIRS := Color(0.98, 0.52, 0.30)   # the other dog's
const CHALK := Color(0.96, 0.95, 0.88)
const ROPE_GIVE := 0.3      # how much of the tug's sideways jiggle shows in the taut rope
const MARK := Color(0.93, 0.36, 0.30)      # the rope middle on the meter
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
		_draw_rope_ground()
	_b.flush()


const SURF := Color(0.40, 0.74, 0.78, 0.55)
const FOAM := Color(0.98, 0.99, 1.0, 0.85)
const WET_SAND := Color(0.62, 0.55, 0.42, 0.35)


# the wave game's water up the sand: a softly feathered wash from the shoreline
# to its edge, lacy seafoam + bubbles along the tongue, feathered wet sand as
# it drains, and a soft offshore swell crest building before it arrives
func _draw_waves(wg: WaveGame) -> void:
	var r: Rect2 = main._freedom_rect()
	var top := r.position.y
	var bot := r.end.y
	var off := wg.front_off()
	var step := 36.0
	var wet := wg.phase == WaveGame.P.DRAIN or wg.phase == WaveGame.P.LULL
	var ys := PackedFloat32Array()
	var shores := PackedFloat32Array()
	var wiggles := PackedFloat32Array()
	var y := top
	while true:
		ys.append(y)
		shores.append(main.beach_shore_x(y))
		wiggles.append(sin(y * 0.031 + float(wg.wave)) * 6.0)
		if y >= bot:
			break
		y = minf(y + step, bot)
	var n := ys.size()
	if n < 2:
		return
	if wet:
		var wet_pts := PackedVector2Array()
		wet_pts.resize(n * 3)
		for i in range(n):
			var yi := ys[i]
			var s := shores[i]
			wet_pts[i] = Vector2(s, yi)
			wet_pts[n + i] = Vector2(s + SURGE_WET * 0.55, yi)
			wet_pts[n * 2 + i] = Vector2(s + SURGE_WET, yi)
		_b.band(wet_pts, n, WET_SAND, PackedFloat32Array([1.0, 0.72, 0.0]))
	if off > 1.0:
		var surf_pts := PackedVector2Array()
		surf_pts.resize(n * 3)
		for i in range(n):
			var yi := ys[i]
			var edge := shores[i] + off + wiggles[i]
			surf_pts[i] = Vector2(shores[i], yi)
			surf_pts[n + i] = Vector2(edge, yi)
			surf_pts[n * 2 + i] = Vector2(edge + 14.0, yi)
		_b.band(surf_pts, n, SURF, PackedFloat32Array([1.0, 0.85, 0.0]))
		for i in range(n - 1):
			var p0 := Vector2(shores[i] + off + wiggles[i], ys[i])
			var p1 := Vector2(shores[i + 1] + off + wiggles[i + 1], ys[i + 1])
			_b.line(p0, p1, FOAM, 3.6)
			_b.line(p0 + Vector2(-4.0, 0.0), p1 + Vector2(-4.0, 0.0), Color(FOAM.r, FOAM.g, FOAM.b, 0.35), 2.2)
			if i % 2 == 0:
				var bub := p0.lerp(p1, 0.45) + Vector2(3.5 + sin(ys[i] * 0.13) * 2.5, 0.0)
				_b.circle(bub, 2.2 + 0.8 * absf(cos(ys[i] * 0.09)), Color(1.0, 1.0, 1.0, 0.65))
	var k := wg.crest()
	if k > 0.0:
		var crest_pts := PackedVector2Array()
		crest_pts.resize(n * 3)
		for i in range(n):
			var yi := ys[i]
			var cx := shores[i] - 70.0 + 30.0 * k + wiggles[i]
			crest_pts[i] = Vector2(cx - 10.0, yi)
			crest_pts[n + i] = Vector2(cx, yi)
			crest_pts[n * 2 + i] = Vector2(cx + 10.0, yi)
		_b.band(crest_pts, n, Color(1.0, 1.0, 1.0, 0.25 + 0.35 * k), PackedFloat32Array([0.0, 1.0, 0.0]))
		for i in range(n - 1):
			var c0 := Vector2(shores[i] - 70.0 + 30.0 * k + wiggles[i], ys[i])
			var c1 := Vector2(shores[i + 1] - 70.0 + 30.0 * k + wiggles[i + 1], ys[i + 1])
			_b.line(c0, c1, Color(1.0, 1.0, 1.0, 0.4 + 0.5 * k), 2.0 + 3.5 * k)


const SURGE_WET := 110.0


func _draw_rope_cover() -> void:
	var fd: Node2D = main.tug_dog
	if main.tug != null and is_instance_valid(fd):
		var tug: RopeTug = main.tug
		_draw_meter(tug, main.dog.global_position, fd.global_position)
		if tug.phase == RopeTug.P.WIND:
			_draw_growl(fd, tug.wind_amount())


# Under the dogs: the rope between two mouths in a tug, its ends hidden in
# their jaws and their muzzles over it, taut but for a little give; or the
# rope lying on the grass where she dropped it.
func _draw_rope_ground() -> void:
	var fd: Node2D = main.tug_dog
	if main.tug != null and is_instance_valid(fd):
		FreedomGames.draw_rope(_b, main.dog.mouth_point(), fd.mouth_point(), main.tug.bend * ROPE_GIVE,
			false, false, true)
	elif main.rope_loose.x < INF:
		var p: Vector2 = main.rope_loose
		FreedomGames.draw_rope(_b, p + Vector2(-17, 4), p + Vector2(17, -4), 3.0)


# chalked on the grass: where the rope's middle started, and the line each side
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


# a small bar over the two of them: the rope middle's way, her side green, theirs
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
	# the rope middle's mark on the bar
	_b.circle(Vector2(to, mid.y), 4.2, ink)
	_b.circle(Vector2(to, mid.y), 3.0, MARK)


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
