extends Node2D

# The wild boar stampede pursuers for Walk 20: Els Senglars (Collserola).
# A fierce mama boar and two striped piglets charging down the hillside
# trail after an overturned dumpster.
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

# Overturned bin
const BIN_GREEN := Color(0.18, 0.45, 0.25)
const BIN_DARK := Color(0.10, 0.28, 0.15)
const WHEEL_GREY := Color(0.20, 0.22, 0.24)

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
	return false


func gap_to(p: Vector2) -> float:
	return p.y - front_y


func sweep_junk(_junk: Array) -> int:
	return 0


func _draw() -> void:
	var b := ShapeBatch.new(self)

	# 1. Ground contact shadows
	b.circle(Vector2(0.0, -35.0), 38.0, Color(0.05, 0.06, 0.08, 0.26))
	b.circle(Vector2(-55.0, -42.0), 22.0, Color(0.05, 0.06, 0.08, 0.22))
	b.circle(Vector2(55.0, -42.0), 22.0, Color(0.05, 0.06, 0.08, 0.22))

	# 2. Mama Boar (center, massive bristly body facing downward)
	_draw_mama(b)

	# 3. Left Piglet (scampering alongside)
	_draw_piglet(b, Vector2(-55.0, -40.0), sin(rumble * 16.0))

	# 4. Right Piglet (scampering alongside)
	_draw_piglet(b, Vector2(55.0, -40.0), cos(rumble * 16.0))

	# 5. Overturned trash bin dragged behind them
	_draw_dumpster(b, Vector2(10.0, -95.0))

	b.flush()


func _draw_mama(b: ShapeBatch) -> void:
	var bob := sin(rumble * 14.0) * 4.0

	# Bristly shoulders & body
	b.circle(Vector2(0.0, -40.0 + bob), 32.0, FUR_DARK)
	b.circle(Vector2(0.0, -26.0 + bob), 26.0, FUR_BRISTLE)

	# Spine mane / dorsal ridge
	b.line(Vector2(0.0, -68.0 + bob), Vector2(0.0, -18.0 + bob), FUR_BRISTLE.lightened(0.12), 4.0)

	# Pointy bristly ears
	var ear_l: PackedVector2Array = [
		Vector2(-22.0, -32.0 + bob),
		Vector2(-36.0, -48.0 + bob),
		Vector2(-14.0, -44.0 + bob)
	]
	var ear_r: PackedVector2Array = [
		Vector2(22.0, -32.0 + bob),
		Vector2(36.0, -48.0 + bob),
		Vector2(14.0, -44.0 + bob)
	]
	b.polygon(ear_l, FUR_DARK)
	b.polygon(ear_r, FUR_DARK)

	# Heavy snout pointing down
	b.rect(Rect2(-12.0, -14.0 + bob, 24.0, 16.0), FUR_DARK)
	# Disc snout pad
	b.circle(Vector2(0.0, 2.0 + bob), 9.0, SNOUT_PINK)
	b.circle(Vector2(-3.5, 2.0 + bob), 2.2, Color(0.18, 0.12, 0.10))
	b.circle(Vector2(3.5, 2.0 + bob), 2.2, Color(0.18, 0.12, 0.10))

	# Prominent curved tusks
	var tusk_l: PackedVector2Array = [
		Vector2(-12.0, -4.0 + bob),
		Vector2(-20.0, -10.0 + bob),
		Vector2(-11.0, 0.0 + bob)
	]
	var tusk_r: PackedVector2Array = [
		Vector2(12.0, -4.0 + bob),
		Vector2(20.0, -10.0 + bob),
		Vector2(11.0, 0.0 + bob)
	]
	b.polygon(tusk_l, TUSK_WHITE)
	b.polygon(tusk_r, TUSK_WHITE)

	# Small fierce glinting red eyes
	b.circle(Vector2(-11.0, -16.0 + bob), 2.8, EYE_RED)
	b.circle(Vector2(11.0, -16.0 + bob), 2.8, EYE_RED)


func _draw_piglet(b: ShapeBatch, pos: Vector2, leg_phase: float) -> void:
	var pbob := sin(rumble * 18.0) * 3.0
	var c := pos + Vector2(0.0, pbob)

	# Body
	b.circle(c, 16.0, PIG_BASE)
	# Humbug stripes
	b.line(c + Vector2(-9.0, -6.0), c + Vector2(-9.0, 6.0), PIG_STRIPE, 2.5)
	b.line(c + Vector2(-3.0, -10.0), c + Vector2(-3.0, 10.0), PIG_STRIPE, 2.5)
	b.line(c + Vector2(3.0, -10.0), c + Vector2(3.0, 10.0), PIG_STRIPE, 2.5)
	b.line(c + Vector2(9.0, -6.0), c + Vector2(9.0, 6.0), PIG_STRIPE, 2.5)

	# Little snout
	b.circle(c + Vector2(0.0, 14.0), 5.5, SNOUT_PINK)
	# Little ears
	b.circle(c + Vector2(-10.0, -8.0), 4.5, PIG_BASE)
	b.circle(c + Vector2(10.0, -8.0), 4.5, PIG_BASE)

	# Tiny trotters
	var l_off := leg_phase * 4.0
	b.circle(c + Vector2(-8.0, 16.0 + l_off), 3.0, HOOF_DARK)
	b.circle(c + Vector2(8.0, 16.0 - l_off), 3.0, HOOF_DARK)


func _draw_dumpster(b: ShapeBatch, pos: Vector2) -> void:
	# Overturned green trash container rolling and bouncing
	var wobble := sin(rumble * 10.0) * 0.12
	var r := Rect2(pos.x - 35.0, pos.y - 20.0, 70.0, 40.0)
	b.rect(r, BIN_GREEN)
	b.rect(Rect2(pos.x - 32.0, pos.y - 18.0, 64.0, 10.0), BIN_DARK)
	# Wheels
	b.circle(pos + Vector2(-30.0, 20.0), 7.0, WHEEL_GREY)
	b.circle(pos + Vector2(30.0, 20.0), 7.0, WHEEL_GREY)
	# Debris scattering
	b.circle(pos + Vector2(-15.0, -25.0), 4.0, Color(0.95, 0.55, 0.15)) # orange peel
	b.circle(pos + Vector2(18.0, -28.0), 3.5, Color(0.90, 0.88, 0.35)) # chip bag
