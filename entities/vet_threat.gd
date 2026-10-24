extends Node2D

# The clinic pursuers for Walk 20: El Veterinari.
# Two clinic assistants in medical scrubs and lab coats pursuing with
# a giant Elizabethan "cone of shame" and catch nets.
# Implements the standard chase threat interface (setup, advance, caught,
# gap_to, threat_boundary, sweep_junk) so systems/home_chase drives it.

const ShapeBatch := preload("res://systems/shape_batch.gd")
const AnimClock := preload("res://hud/anim_clock.gd")

const SCRUBS_TEAL := Color(0.20, 0.65, 0.60)
const COAT_WHITE := Color(0.94, 0.96, 0.98)
const GLOVES_BLUE := Color(0.30, 0.55, 0.90)
const MASK_CYAN := Color(0.60, 0.85, 0.90)
const HAIR_BROWN := Color(0.35, 0.22, 0.15)
const HAIR_BLONDE := Color(0.85, 0.72, 0.35)
const SKIN_TONE := Color(0.92, 0.76, 0.65)

const CONE_PLASTIC := Color(0.88, 0.94, 0.98, 0.60)
const CONE_RIM := Color(0.25, 0.45, 0.75)
const NET_MESH := Color(0.80, 0.82, 0.85, 0.50)
const POLE_ALUMINUM := Color(0.70, 0.72, 0.75)

const SURGE := 0.24
const CATCH_UP := 1.35
const JAM_SECS := 3.0

var main: Node2D
var speed := 138.0
var cur_speed := 138.0
var front_y := 0.0
var cx := 640.0
var half := 280.0
var rumble := 0.0
var kind := "vet"
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


func setup(m: Node2D, start_front_y: float, corridor_cx: float, corridor_half: float, vet_speed: float) -> void:
	main = m
	front_y = start_front_y
	cx = corridor_cx
	half = corridor_half
	speed = vet_speed
	cur_speed = vet_speed


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

	var lurch := sin(rumble * 1.1) * 0.5 + sin(rumble * 2.5) * 0.3
	var mult := 1.0 + SURGE * lurch
	# Catch up if the pair is far ahead
	if gap > 680.0:
		mult = maxf(mult, CATCH_UP)
	cur_speed = speed * mult
	front_y += cur_speed * delta

	# Check for jams (sliding doors, reception desk)
	for i in range(jams.size()):
		if front_y >= jams[i].y:
			jam_side = signf(jams[i].x - cx)
			jam_at = jams[i]
			jams.remove_at(i)
			jam_t = JAM_SECS
			jammed_now = true
			break

	# Steer towards dog's x position
	var target_sway: float = clampf(aim, -half * 0.5, half * 0.5)
	sway_v += (target_sway - sway) * 5.0 * delta
	sway_v *= exp(-3.0 * delta)
	sway += sway_v * delta
	position = Vector2(cx + sway, front_y)
	queue_redraw()


func jammed() -> bool:
	return jam_t > 0.0


func threat_boundary() -> float:
	return front_y


func caught(p: Vector2) -> bool:
	# Inside the giant cone's reach
	if p.y <= front_y and p.y >= front_y - 140.0:
		return absf(p.x - (cx + sway)) <= half * 0.75
	return false


func gap_to(p: Vector2) -> float:
	return p.y - front_y


func sweep_junk(_junk: Array) -> int:
	return 0


func _draw() -> void:
	var b := ShapeBatch.new()
	b.target = self

	# Shadow on the linoleum floor
	b.circle(Vector2(-60.0, -40.0), 28.0, Color(0.04, 0.05, 0.08, 0.22))
	b.circle(Vector2(60.0, -40.0), 28.0, Color(0.04, 0.05, 0.08, 0.22))
	b.rect(Rect2(-120.0, -60.0, 240.0, 50.0), Color(0.04, 0.05, 0.08, 0.18))

	# Giant cone of shame spanning between the assistants (front edge at y = 0)
	var cone_pts: PackedVector2Array = [
		Vector2(-110.0, 0.0),
		Vector2(110.0, 0.0),
		Vector2(60.0, -70.0),
		Vector2(-60.0, -70.0),
	]
	b.polygon(cone_pts, CONE_PLASTIC)
	# Translucent plastic sheen lines
	b.line(Vector2(-110.0, 0.0), Vector2(110.0, 0.0), CONE_RIM, 3.5)
	b.line(Vector2(-90.0, -15.0), Vector2(90.0, -15.0), Color(1, 1, 1, 0.4), 2.0)
	b.line(Vector2(-75.0, -40.0), Vector2(75.0, -40.0), Color(1, 1, 1, 0.3), 1.5)
	b.line(Vector2(-60.0, -70.0), Vector2(60.0, -70.0), CONE_RIM, 2.5)

	# Assistant 1 (left: Dr. Marta in teal scrubs and lab coat)
	_draw_assistant(b, Vector2(-75.0, -55.0), HAIR_BROWN, true)

	# Assistant 2 (right: Dr. Jordi in lab coat with catch net)
	_draw_assistant(b, Vector2(75.0, -55.0), HAIR_BLONDE, false)

	# Catch net held by right assistant
	b.line(Vector2(75.0, -55.0), Vector2(125.0, -25.0), POLE_ALUMINUM, 3.0)
	b.circle(Vector2(130.0, -20.0), 16.0, NET_MESH)
	b.circle(Vector2(130.0, -20.0), 16.0, Color(0.3, 0.35, 0.40))
	b.circle(Vector2(130.0, -20.0), 14.0, NET_MESH)

	b.flush()


func _draw_assistant(b: ShapeBatch, pos: Vector2, hair_col: Color, is_left: bool) -> void:
	# Lab coat body
	b.rect(Rect2(pos.x - 16.0, pos.y - 12.0, 32.0, 24.0), COAT_WHITE)
	# Teal scrubs collar
	b.circle(Vector2(pos.x, pos.y - 6.0), 8.0, SCRUBS_TEAL)
	# Stethoscope around neck
	b.arc(Vector2(pos.x, pos.y - 4.0), 9.0, PI * 0.1, PI * 0.9, 8, Color(0.2, 0.22, 0.25), 1.8)
	b.circle(Vector2(pos.x + 4.0, pos.y + 6.0), 2.5, Color(0.8, 0.82, 0.85))

	# Head
	b.circle(Vector2(pos.x, pos.y - 16.0), 10.0, SKIN_TONE)
	# Hair
	b.circle(Vector2(pos.x, pos.y - 19.0), 9.0, hair_col)
	# Surgical mask
	b.rect(Rect2(pos.x - 6.0, pos.y - 14.0, 12.0, 6.0), MASK_CYAN)

	# Hands with blue rubber gloves holding cone
	var hand_x: float = pos.x + (16.0 if is_left else -16.0)
	b.circle(Vector2(hand_x, pos.y + 4.0), 4.5, GLOVES_BLUE)
