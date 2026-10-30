extends Node2D

# The Correfoc festival pursuers for Walk 25: Festa de Gràcia.
# A troupe of festive fire devils (Colla de Diables de Gràcia) with sparklers,
# pitchforks (maces de foc), and a paper-mâché fire dragon (Drac de Gràcia).
# Implements the standard chase threat interface (setup, advance, caught,
# gap_to, threat_boundary, sweep_junk) so systems/home_chase drives it.

const ShapeBatch := preload("res://systems/shape_batch.gd")

const DEVIL_RED := Color(0.85, 0.18, 0.14)
const DEVIL_BLACK := Color(0.12, 0.12, 0.15)
const DEVIL_HORN := Color(0.92, 0.88, 0.60)
const DRAGON_GREEN := Color(0.22, 0.56, 0.28)
const DRAGON_BELLY := Color(0.78, 0.72, 0.35)
const DRAGON_EYE := Color(0.95, 0.25, 0.15)
const SPARK_YELLOW := Color(0.98, 0.94, 0.40)
const SPARK_ORANGE := Color(0.96, 0.52, 0.12)
const DRUM_WOOD := Color(0.55, 0.38, 0.22)
const DRUM_HEAD := Color(0.92, 0.90, 0.85)

const SURGE := 0.25
const CATCH_UP := 1.35
const JAM_SECS := 3.0

var main: Node2D
var speed := 140.0
var cur_speed := 140.0
var front_y := 0.0
var cx := 640.0
var half := 220.0
var rumble := 0.0
var kind := "correfoc"
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


func setup(m: Node2D, start_front_y: float, corridor_cx: float, corridor_half: float, correfoc_speed: float) -> void:
	main = m
	front_y = start_front_y
	cx = corridor_cx
	half = corridor_half
	speed = correfoc_speed
	cur_speed = correfoc_speed


func advance(delta: float, gap := -1.0, aim := 0.0) -> void:
	jammed_now = false
	freed_now = false
	if jam_t > 0.0:
		jam_t = maxf(0.0, jam_t - delta)
		if jam_t == 0.0:
			freed_now = true
			jam_at = Vector2(INF, INF)
		queue_redraw()
		return

	# Speed scales slightly with distance to keep tension
	if gap > 0.0:
		var target_speed := speed
		if gap > 450.0:
			target_speed = speed * CATCH_UP
		elif gap < 220.0:
			target_speed = speed * 0.92
		cur_speed = move_toward(cur_speed, target_speed, speed * SURGE * delta * 2.0)
	else:
		cur_speed = speed

	front_y += cur_speed * delta

	# Check jam waypoints
	for jp in jams:
		if absf(front_y - jp.y) < 18.0:
			jam_t = JAM_SECS
			jammed_now = true
			jam_at = jp
			break

	# Gentle festive swaying
	sway_v += (aim - sway) * 4.0 * delta
	sway_v *= exp(-3.0 * delta)
	sway += sway_v * delta
	sway = clampf(sway, -half * 0.45, half * 0.45)
	queue_redraw()


func threat_boundary() -> float:
	return front_y


func caught(pos: Vector2) -> bool:
	if absf(pos.x - (cx + sway)) > (half + 20.0):
		return false
	# Caught when player falls within sparker reach behind threat front
	return pos.y <= front_y and pos.y >= (front_y - 120.0)


func gap_to(p: Vector2) -> float:
	return p.y - front_y


func jammed() -> bool:
	return jam_t > 0.0


func jam_remaining() -> float:
	return jam_t


func set_kerb_blocks(blocks: Array[Rect2]) -> void:
	kerb_blocks = blocks


func sweep_junk(_junk: Array) -> void:
	pass


func _draw() -> void:
	var b := ShapeBatch.new()
	var center := Vector2(cx + sway, front_y)

	# 1. Paper-mâché Fire Dragon (Drac de Gràcia) in front
	# Dragon head snout & neck
	b.circle(center + Vector2(0.0, -15.0), 32.0, DRAGON_GREEN)
	b.circle(center + Vector2(0.0, -35.0), 24.0, DRAGON_GREEN)
	b.circle(center + Vector2(0.0, -10.0), 16.0, DRAGON_BELLY)
	# Red glowing eyes
	b.circle(center + Vector2(-12.0, -32.0), 5.0, DRAGON_EYE)
	b.circle(center + Vector2(12.0, -32.0), 5.0, DRAGON_EYE)

	# 2. Fire Devils (Colla de Diables) flanking the dragon
	for side: float in [-1.0, 1.0]:
		var devil_pos := center + Vector2(side * 55.0, -50.0)
		# Robes
		b.circle(devil_pos, 18.0, DEVIL_RED)
		b.circle(devil_pos + Vector2(0.0, -6.0), 14.0, DEVIL_BLACK)
		# Horned hoods
		b.circle(devil_pos + Vector2(-6.0, -16.0), 4.0, DEVIL_HORN)
		b.circle(devil_pos + Vector2(6.0, -16.0), 4.0, DEVIL_HORN)
		# Pitchfork sparkler (maça de foc) tip
		var mace_tip := devil_pos + Vector2(side * 22.0, 20.0)
		b.circle(mace_tip, 8.0, SPARK_ORANGE)
		b.circle(mace_tip, 5.0, SPARK_YELLOW)
		b.circle(mace_tip + Vector2(side * 6.0, 6.0), 3.0, SPARK_YELLOW)

	# 3. Festive spark clouds
	b.circle(center + Vector2(-25.0, 5.0), 6.0, SPARK_YELLOW)
	b.circle(center + Vector2(28.0, 8.0), 7.0, SPARK_ORANGE)
	b.circle(center + Vector2(5.0, 18.0), 5.0, SPARK_YELLOW)

	b.flush(self)
