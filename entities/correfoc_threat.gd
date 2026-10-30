extends Node2D

# The Correfoc festival pursuers for Walk 26: Festa de Gràcia.
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
const SMOKE := Color(0.62, 0.60, 0.62, 0.30)
const SHADOW := Color(0.04, 0.05, 0.08, 0.22)
# across the street, the middle ones left out for the dragon
const DEVILS := 7

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

	# a respite holds the troupe once, then it is behind them
	for i in range(jams.size()):
		if front_y >= jams[i].y:
			jam_side = signf(jams[i].x - cx)
			jam_at = jams[i]
			jams.remove_at(i)
			jam_t = JAM_SECS
			jammed_now = true
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


func sweep_junk(_junk: Array) -> int:
	return 0


# Seen from above, coming south: the smoke they leave, the dragon down the
# middle breathing sparks at the street ahead, and a line of devils across the
# street, each spinning a sparkler on a pole. Everything sits north of the
# front (y <= 0), where caught() reaches.
func _draw() -> void:
	var b := ShapeBatch.new()
	# home_chase keeps the node at (walk_cx, front_y): only the sway is local
	var c := Vector2(sway, 0.0)
	var t := float(AnimClock.msec()) * 0.001
	var reach := half * 0.82

	# smoke hanging behind the troupe
	for i in range(7):
		var sx := (float(i) / 6.0 - 0.5) * reach * 2.0
		var drift := sin(t * 0.7 + float(i) * 1.9) * 10.0
		b.circle(c + Vector2(sx + drift, -150.0 - float(i % 3) * 14.0), 46.0, SMOKE)
	for i in range(5):
		var sx := (float(i) / 4.0 - 0.5) * reach * 1.6
		b.circle(c + Vector2(sx, -108.0 + sin(t + float(i)) * 6.0), 34.0, SMOKE.lightened(0.08))

	# the dragon: tail to head, scaled, its head low and its jaws open
	for k in range(5):
		var sy := -150.0 + float(k) * 22.0
		var wob := sin(t * 3.0 - float(k) * 0.8) * 6.0
		var r := 15.0 + float(k) * 2.6
		b.circle(c + Vector2(wob + 4.0, sy + 6.0), r, SHADOW)
		b.circle(c + Vector2(wob, sy), r, DRAGON_GREEN.darkened(0.12))
		b.circle(c + Vector2(wob, sy - 2.0), r * 0.55, DRAGON_GREEN.lightened(0.12))
		b.circle(c + Vector2(wob - r * 0.7, sy), 4.0, DRAGON_BELLY)
		b.circle(c + Vector2(wob + r * 0.7, sy), 4.0, DRAGON_BELLY)
	var head := c + Vector2(sin(t * 3.0 + 0.8) * 5.0, -34.0)
	b.circle(head + Vector2(4.0, 6.0), 26.0, SHADOW)
	b.circle(head, 26.0, DRAGON_GREEN)
	b.circle(head + Vector2(0.0, 16.0), 16.0, DRAGON_BELLY)
	b.circle(head + Vector2(-13.0, -8.0), 6.0, DRAGON_EYE)
	b.circle(head + Vector2(13.0, -8.0), 6.0, DRAGON_EYE)
	b.circle(head + Vector2(-13.0, -9.0), 2.5, SPARK_YELLOW)
	b.circle(head + Vector2(13.0, -9.0), 2.5, SPARK_YELLOW)
	# horns, and a fan of sparks out of the jaws toward the street ahead
	b.circle(head + Vector2(-20.0, -20.0), 5.0, DEVIL_HORN)
	b.circle(head + Vector2(20.0, -20.0), 5.0, DEVIL_HORN)
	for k in range(9):
		var f := fposmod(t * 1.6 + float(k) * 0.37, 1.0)
		var ang := PI * 0.5 + sin(float(k) * 2.4) * 0.45
		var p := head + Vector2(0.0, 26.0) + Vector2(cos(ang), sin(ang)) * f * 28.0
		b.circle(p, 4.5 * (1.0 - f) + 1.0, SPARK_YELLOW if k % 2 == 0 else SPARK_ORANGE)

	# the devils, in a line across the street
	for i in range(DEVILS):
		var u := float(i) / float(DEVILS - 1) * 2.0 - 1.0
		if absf(u) < 0.3:
			continue
		var bob := sin(t * 5.0 + float(i) * 1.3) * 3.0
		var dp := c + Vector2(u * reach, -62.0 + absf(u) * 14.0 + bob)
		b.circle(dp + Vector2(4.0, 6.0), 17.0, SHADOW)
		b.circle(dp, 17.0, DEVIL_RED)
		b.circle(dp + Vector2(0.0, -4.0), 11.0, DEVIL_BLACK)
		b.circle(dp + Vector2(-8.0, -13.0), 3.5, DEVIL_HORN)
		b.circle(dp + Vector2(8.0, -13.0), 3.5, DEVIL_HORN)
		# the sparkler on its pole, held out ahead and spinning
		var mace := dp + Vector2(-signf(u) * 6.0, 26.0)
		b.line(dp + Vector2(0.0, 6.0), mace, DRUM_WOOD, 3.0)
		b.circle(mace, 6.0, SPARK_ORANGE)
		b.circle(mace, 3.5, SPARK_YELLOW)
		for k in range(6):
			var a := t * 9.0 + float(k) * TAU / 6.0 + float(i)
			b.circle(mace + Vector2(cos(a), sin(a)) * 13.0, 2.4, SPARK_YELLOW if k % 2 == 0 else SPARK_ORANGE)

	b.flush(self)
