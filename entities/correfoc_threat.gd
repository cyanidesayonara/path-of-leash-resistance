extends Node2D

# The Correfoc festival pursuers for Walk 26: Festa de Gràcia.
# A troupe of festive fire devils (Colla de Diables de Gràcia) with sparklers,
# pitchforks (maces de foc), and a paper-mâché fire dragon (Drac de Gràcia).
# They are on foot (systems/chase_squad.gd), the dragon in the middle of the
# line: each runs for their place and goes round anything solid, kicks
# litter aside, skids in what she left lying, and the line waits for whoever
# is held up. The catch is theirs: a body and its fork, and the line while it
# holds together.
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
const DEVIL_R := 22.0
const DEVIL_REACH := 36.0         # the fork and its fountain, ahead of the body
const DEVIL_BACK := 62.0
const DRAGON := 3                 # the middle of the line
const HELD_LINES := ["Make way!", "Mind the sparks!", "Coming through!", "Out of the road!"]
const Squad := preload("res://systems/chase_squad.gd")


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
var squad = Squad.new()


func setup(m: Node2D, start_front_y: float, corridor_cx: float, corridor_half: float, correfoc_speed: float) -> void:
	main = m
	front_y = start_front_y
	cx = corridor_cx
	half = corridor_half
	speed = correfoc_speed
	cur_speed = correfoc_speed
	var slots: Array = []
	for i in range(DEVILS):
		slots.append((float(i) / float(DEVILS - 1) * 2.0 - 1.0) * half * 0.82)
	squad.setup(slots, Vector2(cx, front_y), DEVIL_R, DEVIL_REACH, DEVIL_BACK)


func advance(delta: float, gap := -1.0, aim := 0.0) -> void:
	jammed_now = false
	freed_now = false
	if jam_t > 0.0:
		jam_t = maxf(0.0, jam_t - delta)
		if jam_t == 0.0:
			freed_now = true
			jam_at = Vector2(INF, INF)
		_run(delta)
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

	# the line waits for whoever is held up on something
	cur_speed *= squad.pace()
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
	_run(delta)
	queue_redraw()


func _run(delta: float) -> void:
	if main != null:
		squad.run(main, delta, Vector2(cx + sway, front_y), cur_speed if jam_t <= 0.0 else 0.0, true, HELD_LINES, true, "Eww!")


func threat_boundary() -> float:
	return squad.front()


# a body and its fork, the line while it holds, or behind the whole troupe
# (whoever slipped by was in the sparks)
func caught(pos: Vector2) -> bool:
	return squad.caught(pos)


func gap_to(p: Vector2) -> float:
	return p.y - squad.front()


func jammed() -> bool:
	return jam_t > 0.0


func jam_remaining() -> float:
	return jam_t


func set_kerb_blocks(blocks: Array[Rect2]) -> void:
	kerb_blocks = blocks


func sweep_junk(junk: Array) -> int:
	return squad.sweep_junk(junk)


# Seen from above, coming south: the smoke they leave, the dragon down the
# middle breathing sparks at the street ahead, and a line of devils across the
# street, each spinning a sparkler on a pole. Everything sits north of the
# front (y <= 0), where caught() reaches.
func _draw() -> void:
	var b := ShapeBatch.new()
	# home_chase keeps the node at (walk_cx, front_y); each of them is drawn
	# where they really are (systems/chase_squad.gd)
	var c := Vector2(cx + sway, front_y) - global_position
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

	# the dragon runs in the middle of the line, where its member is
	if squad.members.size() > DRAGON:
		c = (squad.members[DRAGON]["pos"] as Vector2) - global_position + Vector2(0.0, DEVIL_BACK)
	# the Drac, as in the film (intro/film_gracia.gd): bearers' legs under the
	# skirt, the scaled body with its ridge, wings out and beating, the horned
	# head low with a red eye under a scowl and its jaws spraying sparks
	var flap := sin(t * 5.0) * 0.3
	for s: float in [-1.0, 1.0]:
		var root := c + Vector2(s * 20.0, -96.0)
		var wing := PackedVector2Array([root])
		for k in range(4):
			var a := (PI if s < 0.0 else 0.0) + s * (-0.9 + float(k) * 0.4 + flap)
			wing.append(root + Vector2.from_angle(a) * (64.0 - float(k % 2) * 18.0))
		b.polygon(wing, DRAGON_GREEN.darkened(0.25))
	for k in range(5):
		var sy := -150.0 + float(k) * 22.0
		var wob := sin(t * 3.0 - float(k) * 0.8) * 6.0
		var r := 17.0 + float(k) * 3.0
		b.circle(c + Vector2(wob + 4.0, sy + 6.0), r, SHADOW)
		for s: float in [-1.0, 1.0]:
			b.circle(c + Vector2(wob + s * r * 0.75, sy + 4.0), 3.5, DEVIL_BLACK)
		b.circle(c + Vector2(wob, sy), r + 2.0, Color(0.05, 0.04, 0.06))
		b.circle(c + Vector2(wob, sy), r, DRAGON_GREEN.darkened(0.08))
		b.circle(c + Vector2(wob, sy - 2.0), r * 0.55, DRAGON_GREEN.lightened(0.12))
		b.polygon(PackedVector2Array([c + Vector2(wob - 5.0, sy - r * 0.2), c + Vector2(wob, sy - r * 0.2 - 12.0),
			c + Vector2(wob + 5.0, sy - r * 0.2)]), DRAGON_BELLY)
	var head := c + Vector2(sin(t * 3.0 + 0.8) * 5.0, -34.0)
	b.circle(head + Vector2(4.0, 6.0), 28.0, SHADOW)
	for s: float in [-1.0, 1.0]:
		b.polygon(PackedVector2Array([head + Vector2(s * 12.0, -16.0), head + Vector2(s * 30.0, -38.0),
			head + Vector2(s * 20.0, -12.0)]), DEVIL_HORN)
	b.circle(head, 28.0, Color(0.05, 0.04, 0.06))
	b.circle(head, 26.0, DRAGON_GREEN)
	# the open jaws, teeth along them
	b.polygon(PackedVector2Array([head + Vector2(-16.0, 10.0), head + Vector2(16.0, 10.0), head + Vector2(12.0, 34.0),
		head + Vector2(-12.0, 34.0)]), Color(0.45, 0.06, 0.08))
	for k in range(4):
		var tx := -11.0 + float(k) * 7.3
		b.polygon(PackedVector2Array([head + Vector2(tx, 10.0), head + Vector2(tx + 5.0, 10.0), head + Vector2(tx + 2.5, 16.0)]),
			Color.WHITE)
	for s: float in [-1.0, 1.0]:
		b.circle(head + Vector2(s * 12.0, -6.0), 6.5, DRAGON_EYE)
		b.circle(head + Vector2(s * 12.0, -6.0), 2.5, SPARK_YELLOW)
		b.line(head + Vector2(s * 20.0, -15.0), head + Vector2(s * 5.0, -10.0), Color(0.05, 0.04, 0.06), 3.5)
	# the sparks out of the jaws, sprayed down the street ahead
	b.circle(head + Vector2(0.0, 36.0), 16.0, Color(1.0, 0.65, 0.20, 0.30))
	for k in range(18):
		var f := fposmod(t * 1.6 + float(k) * 0.37, 1.0)
		var ang := PI * 0.5 + sin(float(k) * 2.4) * 0.6
		var p := head + Vector2(0.0, 30.0) + Vector2(cos(ang), sin(ang)) * f * 56.0
		b.circle(p, 4.5 * (1.0 - f) + 1.0, SPARK_YELLOW if k % 2 == 0 else SPARK_ORANGE)

	# the devils in a line across the street, as in the film: a red cape over
	# black, the horned hood, and the fork held out ahead spraying its
	# fountain of sparks
	for i in range(DEVILS):
		var u := float(i) / float(DEVILS - 1) * 2.0 - 1.0
		if i == DRAGON or i >= squad.members.size():
			continue
		var held: bool = float(squad.members[i]["stuck_t"]) > 0.4
		var bob := sin(t * (12.0 if held else 5.0) + float(i) * 1.3) * 3.0
		var dp: Vector2 = (squad.members[i]["pos"] as Vector2) - global_position + Vector2(0.0, absf(u) * 14.0 + bob)
		b.circle(dp + Vector2(4.0, 6.0), 19.0, SHADOW)
		b.circle(dp + Vector2(0.0, -2.0), 19.0, Color(0.05, 0.04, 0.06))
		b.circle(dp + Vector2(0.0, -2.0), 17.0, DEVIL_RED)
		b.polygon(PackedVector2Array([dp + Vector2(-17.0, -2.0), dp + Vector2(17.0, -2.0), dp + Vector2(12.0, -16.0),
			dp + Vector2(-12.0, -16.0)]), DEVIL_RED.darkened(0.2))
		for s: float in [-1.0, 1.0]:
			b.polygon(PackedVector2Array([dp + Vector2(s * 5.0, -6.0), dp + Vector2(s * 16.0, -20.0),
				dp + Vector2(s * 9.0, -3.0)]), DEVIL_HORN)
		b.circle(dp + Vector2(0.0, -2.0), 10.5, DEVIL_BLACK)
		b.circle(dp + Vector2(0.0, 5.0), 5.0, Color(0.90, 0.72, 0.58))
		# the fork, out ahead, and its fountain
		var mace := dp + Vector2(-signf(u) * 6.0, 30.0)
		b.line(dp + Vector2(0.0, 6.0), mace, DRUM_WOOD, 3.5)
		b.line(mace, mace + Vector2(-6.0, 6.0), DRUM_WOOD, 2.5)
		b.line(mace, mace + Vector2(6.0, 6.0), DRUM_WOOD, 2.5)
		b.circle(mace + Vector2(0.0, 6.0), 12.0, Color(1.0, 0.65, 0.20, 0.28))
		b.circle(mace + Vector2(0.0, 6.0), 5.0, SPARK_YELLOW)
		for k in range(10):
			var f := fposmod(t * 1.9 + float(k) * 0.1 + float(i) * 0.13, 1.0)
			var a := float(k) * TAU / 10.0 + t * 2.0
			b.circle(mace + Vector2(0.0, 6.0) + Vector2(cos(a), sin(a) * 0.8 + 0.5) * f * 30.0, 2.8 * (1.0 - f) + 0.8,
				SPARK_YELLOW if k % 2 == 0 else SPARK_ORANGE)

	b.flush(self)
