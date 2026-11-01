extends Node2D

# The wild boar stampede pursuers for Walk 20: Els Senglars (Collserola).
# The sounder charging down the trail line abreast: the mama in the middle,
# a big boar on each flank and the striped piglets between, dust kicked up
# behind them. The same animals are in the walk's film (intro/film_boars.gd),
# seen side on.
# Implements the standard chase threat interface (setup, advance, caught,
# gap_to, threat_boundary, sweep_junk) so systems/home_chase drives it.

const ShapeBatch := preload("res://systems/shape_batch.gd")

const FUR_DARK := Color(0.18, 0.16, 0.15)
const FUR_BRISTLE := Color(0.28, 0.24, 0.22)
const SNOUT_PINK := Color(0.72, 0.52, 0.50)
const TUSK_WHITE := Color(0.95, 0.94, 0.88)
const EYE_RED := Color(0.85, 0.20, 0.15)
const HOOF_DARK := Color(0.12, 0.10, 0.09)

# Piglet colours (striped rayones)
const PIG_BASE := Color(0.48, 0.38, 0.28)
const PIG_STRIPE := Color(0.75, 0.65, 0.48)

const INK := Color(0.05, 0.04, 0.06)
const DUST := Color(0.62, 0.50, 0.36)
# the line, west to east: [scale, piglet, how far ahead of the line it runs]
const SOUNDER := [[0.95, false, 0.0], [0.55, true, 6.0], [1.2, false, 10.0], [0.55, true, 4.0], [0.95, false, 0.0]]

const SURGE := 0.26
const CATCH_UP := 1.35
const JAM_SECS := 3.0

var main: Node2D
var speed := 142.0
var cur_speed := 142.0
var front_y := 0.0
var cx := 640.0
var half := 280.0
var rumble := 0.0
var kind := "boars"
var sway := 0.0
var sway_v := 0.0
var heading := 0.0
var jams: Array[Vector2] = []
var jam_t := 0.0
var jam_side := 0.0
var jam_at := Vector2(INF, INF)
var kerb_blocks: Array[Rect2] = []
var jammed_now := false
var freed_now := false


func setup(m: Node2D, start_front_y: float, corridor_cx: float, corridor_half: float, boar_speed: float) -> void:
	main = m
	front_y = start_front_y
	cx = corridor_cx
	half = corridor_half
	speed = boar_speed
	cur_speed = boar_speed


func advance(delta: float, gap := -1.0, aim := 0.0) -> void:
	rumble += delta
	jammed_now = false
	freed_now = false
	if jam_t > 0.0:
		jam_t -= delta
		cur_speed = 0.0
		if jam_t <= 0.0:
			freed_now = true
		return

	var lurch := sin(rumble * 1.3) * 0.5 + sin(rumble * 3.1) * 0.3
	var mult := 1.0 + SURGE * lurch
	if gap > 680.0:
		mult = maxf(mult, CATCH_UP)
	cur_speed = speed * mult
	front_y += cur_speed * delta

	# Check for jams (acorn piles, picnic benches)
	for i in range(jams.size()):
		if front_y >= jams[i].y:
			jam_side = signf(jams[i].x - cx)
			jam_at = jams[i]
			jams.remove_at(i)
			jam_t = JAM_SECS
			jammed_now = true
			break

	# Steer towards dog's x position with heavier inertia
	var target_sway: float = clampf(aim, -half * 0.55, half * 0.55)
	sway_v += (target_sway - sway) * 4.2 * delta
	sway_v *= exp(-2.8 * delta)
	sway += sway_v * delta
	position = Vector2(cx + sway, front_y)
	queue_redraw()


func jammed() -> bool:
	return jam_t > 0.0


func threat_boundary() -> float:
	return front_y


func caught(p: Vector2) -> bool:
	# Inside the mama boar and piglets front line
	if p.y <= front_y and p.y >= front_y - 120.0:
		return absf(p.x - (cx + sway)) <= half * 0.72
	# the herd has run right past them: whoever slipped by at the side went
	# under it, rather than the boars running on home without them
	return p.y < front_y - 120.0


func gap_to(p: Vector2) -> float:
	return p.y - front_y


func sweep_junk(_junk: Array) -> int:
	return 0


func _draw() -> void:
	# home_chase keeps the node at (walk_cx, front_y); caught() reads the sway.
	# The line spans what caught() catches (half * 0.72 either side), every
	# snout at the catch line and the bodies running back into its depth.
	draw_set_transform(Vector2(sway, 0.0))
	var b := ShapeBatch.new(self)
	var mw := half * 0.72
	# the dust they raise, behind the whole line
	for i in range(14):
		var f := fposmod(rumble * 1.6 + float(i) * 0.31, 1.0)
		var dx := lerpf(-mw, mw, float(i) / 13.0) + sin(float(i) * 2.7) * 18.0
		b.circle(Vector2(dx, -110.0 - f * 70.0), 14.0 + f * 22.0, Color(DUST, 0.45 * (1.0 - f)))
	for i in range(SOUNDER.size()):
		var st: Array = SOUNDER[i]
		var x := lerpf(-mw + 26.0, mw - 26.0, float(i) / float(SOUNDER.size() - 1))
		_boar(b, Vector2(x, -4.0 + float(st[2]) - 10.0), float(st[0]), rumble * 16.0 + float(i) * 1.3, bool(st[1]))
	b.flush()


# one of the sounder from above, its snout at `snout`, running south: the
# bristling body with high shoulders and the mane down the spine, legs at a
# gallop, ears out, the pink snout disc; an adult has tusks and red eyes
# under a scowl, a piglet stripes and a piglet's eyes
func _boar(b: ShapeBatch, snout: Vector2, k: float, phase: float, piglet: bool) -> void:
	var fur := PIG_BASE if piglet else FUR_DARK
	var c := snout + Vector2(0.0, -50.0 * k)
	b.circle(c + Vector2(5.0, 6.0) * k, 30.0 * k, Color(0.05, 0.06, 0.08, 0.24))
	# legs, two pairs, galloping
	var g := sin(phase) * 6.0 * k
	for s in [-1.0, 1.0]:
		b.circle(c + Vector2(s * 19.0 * k, 22.0 * k + g * s), 6.0 * k, HOOF_DARK)
		b.circle(c + Vector2(s * 17.0 * k, -26.0 * k - g * s), 6.0 * k, HOOF_DARK)
	# the tail, flicking
	b.line(c + Vector2(0, -40) * k, c + Vector2(sin(phase * 0.7) * 6.0, -52.0) * k, INK, 3.0 * k)
	# body and the high shoulders, outlined
	_oval(b, c + Vector2(0, -6) * k, Vector2(25, 40) * k, INK)
	_oval(b, c + Vector2(0, -6) * k, Vector2(22, 37) * k, fur)
	_oval(b, c + Vector2(0, 10) * k, Vector2(27, 21) * k, INK)
	_oval(b, c + Vector2(0, 10) * k, Vector2(24, 18) * k, fur)
	if piglet:
		for sx in [-9.0, 0.0, 9.0]:
			b.line(c + Vector2(sx, -34) * k, c + Vector2(sx, 18) * k, PIG_STRIPE, 3.0 * k)
	else:
		b.line(c + Vector2(0, -38) * k, c + Vector2(0, 18) * k, FUR_BRISTLE.lightened(0.15), 5.0 * k)
		for m in range(6):
			b.circle(c + Vector2(0.0, -34.0 + float(m) * 9.0) * k, 3.2 * k, FUR_BRISTLE.lightened(0.25))
	# ears out to the sides, the head down to the snout
	for s in [-1.0, 1.0]:
		b.polygon(PackedVector2Array([c + Vector2(s * 12, 20) * k, c + Vector2(s * 26, 14) * k,
			c + Vector2(s * 15, 30) * k]), fur.darkened(0.15))
	b.polygon(PackedVector2Array([c + Vector2(-16, 24) * k, c + Vector2(16, 24) * k, c + Vector2(10, 46) * k,
		c + Vector2(-10, 46) * k]), fur)
	b.circle(snout + Vector2(0, -2) * k, 9.0 * k, INK)
	b.circle(snout + Vector2(0, -2) * k, 7.5 * k, SNOUT_PINK)
	b.circle(snout + Vector2(-3, -2) * k, 1.8 * k, INK)
	b.circle(snout + Vector2(3, -2) * k, 1.8 * k, INK)
	if piglet:
		for s in [-1.0, 1.0]:
			b.circle(c + Vector2(s * 7, 33) * k, 2.6 * k, Color.WHITE)
			b.circle(c + Vector2(s * 7, 34) * k, 1.5 * k, INK)
		return
	# tusks curling out of the jaw
	for s in [-1.0, 1.0]:
		b.polygon(PackedVector2Array([snout + Vector2(s * 7, -8) * k, snout + Vector2(s * 19, -18) * k,
			snout + Vector2(s * 9, -3) * k]), TUSK_WHITE)
	# small red eyes under a scowl, the brows down toward the snout
	for s in [-1.0, 1.0]:
		b.circle(c + Vector2(s * 8, 33) * k, 3.2 * k, EYE_RED)
		b.line(c + Vector2(s * 14, 27) * k, c + Vector2(s * 4, 31) * k, INK, 2.6 * k)
	# a snort of steam off the snout now and then
	var sn := fposmod(phase * 0.08, 1.0)
	if sn < 0.4:
		b.circle(snout + Vector2(0.0, 10.0 + sn * 30.0) * k, (4.0 + sn * 14.0) * k, Color(0.95, 0.95, 0.95, 0.5 * (1.0 - sn / 0.4)))


func _oval(b: ShapeBatch, at: Vector2, r: Vector2, col: Color) -> void:
	var p := PackedVector2Array()
	for i in range(14):
		p.append(at + Vector2.from_angle(TAU * float(i) / 14.0) * r)
	b.polygon(p, col)
