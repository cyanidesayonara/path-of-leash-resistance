extends Node2D

# The chase threat of Montserrat: The Wild Goat Herd Leader (Cabres Salvatges).
# An agile alpha mountain goat bounding down the craggy trail with massive
# curved horns, sure-footed hooves, and a knack for kicking loose boulders.
#
# What sets it apart: rolling conglomerate boulders.
# Every few seconds, the goat head-butts or kicks a loose boulder that rolls
# and bounces down the mountain trail directly toward the pair.
# A directional dust trail telegraphs the boulder's trajectory.
# Dodging clear awards the "boulder_dodge" goal; getting hit causes a knockback
# and counts toward "montserrat_goat_hits".
#
# Implements the standard chase threat interface (setup, advance, caught,
# gap_to, threat_boundary, sweep_junk) so systems/home_chase drives it.

const ShapeBatch := preload("res://systems/shape_batch.gd")
const EventFeed := preload("res://hud/event_feed.gd")

# Colors
const GOAT_FUR := Color(0.58, 0.46, 0.36)
const GOAT_DARK := Color(0.40, 0.30, 0.22)
const GOAT_BELLY := Color(0.82, 0.76, 0.68)
const GOAT_HORN := Color(0.28, 0.26, 0.24)
const GOAT_HORN_TIP := Color(0.18, 0.16, 0.14)
const GOAT_EYE := Color(0.95, 0.85, 0.20)
const BOULDER_COL := Color(0.68, 0.62, 0.54)
const BOULDER_DARK := Color(0.48, 0.42, 0.36)
const DUST_COL := Color(0.82, 0.76, 0.66, 0.45)
const SHADOW := Color(0.06, 0.05, 0.08, 0.28)

# Movement and tuning
const SPEED_DEFAULT := 138.0
const SURGE := 0.15
const CATCH_UP := 1.35
const CATCH_UP_GAP := 650.0
const JAM_SECS := 3.0
const GOAT_DEPTH := 90.0
const CATCH_SPAN := 0.70

# Rolling boulder hazards
const BOULDER_FIRST := 1.6
const BOULDER_EVERY := 2.5
const BOULDER_JITTER := 0.4
const BOULDER_WARN := 0.8
const BOULDER_R := 36.0
const BOULDER_DODGE_R := 120.0
const BOULDER_LEAD := 0.5
const BOULDER_MIN_AHEAD := 80.0
const MAX_BOULDERS := 3
const IMPACT_TIME := 0.4

var main: Node2D
var speed := SPEED_DEFAULT
var cur_speed := SPEED_DEFAULT
var front_y := 0.0
var cx := 640.0
var half := 260.0
var kind := "goat"
var rumble := 0.0
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

# Rolling boulders in flight: {"from": Vector2, "at": Vector2, "target": Vector2, "t": float, "lead": float}
var boulders: Array[Dictionary] = []
# Dust impact puffs: {"at": Vector2, "t": float}
var dust_puffs: Array[Dictionary] = []
var boulder_t := BOULDER_FIRST
var drop_count := 0
var hits := 0
var dodges := 0


func setup(m: Node2D, start_front_y: float, corridor_cx: float, corridor_half: float, goat_speed: float) -> void:
	main = m
	front_y = start_front_y
	cx = corridor_cx
	half = corridor_half
	speed = goat_speed
	cur_speed = goat_speed
	boulders.clear()
	dust_puffs.clear()
	boulder_t = BOULDER_FIRST
	position = Vector2(cx, front_y)


func advance(delta: float, gap := -1.0, aim := 0.0) -> void:
	rumble += delta
	jammed_now = false
	freed_now = false
	_tick_boulders(delta)

	if jam_t > 0.0:
		jam_t -= delta
		cur_speed = 0.0
		if jam_t <= 0.0:
			freed_now = true
		queue_redraw()
		return

	var leap := sin(rumble * 2.2) * 0.5
	var mult := 1.0 + SURGE * leap
	if gap > CATCH_UP_GAP:
		mult = maxf(mult, CATCH_UP)
	cur_speed = speed * mult
	front_y += cur_speed * delta

	for i in range(jams.size()):
		if front_y >= jams[i].y:
			jam_side = signf(jams[i].x - cx)
			jam_at = jams[i]
			jams.remove_at(i)
			jam_t = JAM_SECS
			cur_speed = 0.0
			jammed_now = true
			if main != null and main.has_node("/root/Sfx"):
				main.get_node("/root/Sfx").play("crack", 1.0)
			break

	var target_x := cx + aim * (half * 0.55)
	var steer: float = (target_x - position.x) * 2.2
	position.x += steer * delta
	position.y = front_y
	queue_redraw()


func _tick_boulders(delta: float) -> void:
	if jam_t > 0.0 or main == null:
		return

	boulder_t -= delta
	if boulder_t <= 0.0 and boulders.size() < MAX_BOULDERS:
		_spawn_boulder()
		boulder_t = BOULDER_EVERY + randf() * BOULDER_JITTER

	# Advance boulders
	var i := boulders.size() - 1
	while i >= 0:
		var b: Dictionary = boulders[i]
		var t: float = float(b.get("t", 0.0)) + delta
		b["t"] = t
		var progress := clampf(t / float(b.get("lead", 1.0)), 0.0, 1.0)
		var from_pos: Vector2 = b["from"]
		var to_pos: Vector2 = b["target"]
		var cur_pos := from_pos.lerp(to_pos, progress)
		b["at"] = cur_pos

		if progress >= 1.0:
			_resolve_boulder_impact(b)
			boulders.remove_at(i)
		i -= 1

	# Decay dust puffs
	var j := dust_puffs.size() - 1
	while j >= 0:
		var d: Dictionary = dust_puffs[j]
		d["t"] = float(d.get("t", 0.0)) + delta
		if float(d["t"]) > IMPACT_TIME:
			dust_puffs.remove_at(j)
		j -= 1


func _spawn_boulder() -> void:
	if main == null or main.dog == null:
		return
	var target_pos: Vector2 = main.dog.global_position
	# Don't throw backwards
	if target_pos.y < front_y + BOULDER_MIN_AHEAD:
		target_pos.y = front_y + BOULDER_MIN_AHEAD + 40.0

	var from_pos := Vector2(position.x, front_y + 20.0)
	var travel_dist := from_pos.distance_to(target_pos)
	var lead_time := clampf(travel_dist / 280.0, 0.7, 1.4)

	boulders.append({
		"from": from_pos,
		"at": from_pos,
		"target": target_pos,
		"t": 0.0,
		"lead": lead_time,
	})
	drop_count += 1
	if main.has_node("/root/Sfx"):
		main.get_node("/root/Sfx").play("bleat", 0.95)


func _resolve_boulder_impact(b: Dictionary) -> void:
	if main == null or main.dog == null:
		return
	var impact_pos: Vector2 = b.get("target", Vector2.ZERO)
	dust_puffs.append({"at": impact_pos, "t": 0.0})

	if main.has_node("/root/Sfx"):
		main.get_node("/root/Sfx").play("crack", 1.2)

	var dog_pos: Vector2 = main.dog.global_position
	var dist := impact_pos.distance_to(dog_pos)

	if dist < BOULDER_R:
		# Direct hit!
		hits += 1
		main.montserrat_goat_hits += 1
		if main.dog.has_method("knocked"):
			var knock_dir := (dog_pos - impact_pos).normalized()
			if knock_dir == Vector2.ZERO:
				knock_dir = Vector2.DOWN
			main.dog.knocked(knock_dir, "boulder")
		if main.feed != null:
			main.feed.say("BOULDER HIT!", EventFeed.Tone.LOUD)
	elif dist < BOULDER_DODGE_R:
		# Clean dodge!
		dodges += 1
		main.montserrat_boulder_dodges += 1
		main.bones += 2
		main.float_text(dog_pos + Vector2(0, -25), "boulder dodged! +2", Color(0.96, 0.86, 0.32))
		if main.feed != null:
			main.feed.say("STEPPED CLEAR OF THE BOULDER!", EventFeed.Tone.GOOD)


func boulder_warning() -> bool:
	for b in boulders:
		if float(b.get("t", 0.0)) < BOULDER_WARN:
			return true
	return false


func gap_to(p: Vector2) -> float:
	return p.y - front_y


func caught(p: Vector2) -> bool:
	if p.y <= front_y and p.y >= front_y - GOAT_DEPTH * 0.7:
		return absf(p.x - position.x) <= half * CATCH_SPAN
	return p.y < front_y - GOAT_DEPTH * 0.7


func jammed() -> bool:
	return jam_t > 0.0


func threat_boundary() -> float:
	return front_y


func sweep_junk(_junk: Array) -> int:
	# Bounding goat leaps over loose trash
	return 0


func _draw() -> void:
	# Dust telegraph paths from rolling boulders
	for b in boulders:
		var from_p: Vector2 = to_local(b["from"])
		var target_p: Vector2 = to_local(b["target"])
		draw_line(from_p, target_p, DUST_COL, 6.0)
		# Draw rolling boulder
		var at_p: Vector2 = to_local(b["at"])
		draw_circle(at_p + Vector2(4, 4), BOULDER_R * 0.5, SHADOW)
		draw_circle(at_p, BOULDER_R * 0.5, BOULDER_COL)
		draw_circle(at_p - Vector2(4, 4), BOULDER_R * 0.3, BOULDER_DARK)

	# Impact dust puffs
	for d in dust_puffs:
		var p: Vector2 = to_local(d["at"])
		var progress: float = float(d.get("t", 0.0)) / IMPACT_TIME
		var r := 18.0 + progress * 24.0
		var alpha := 1.0 - progress
		draw_circle(p, r, Color(DUST_COL.r, DUST_COL.g, DUST_COL.b, alpha * 0.4))

	# The Alpha Mountain Goat (top-down view)
	var bob := sin(rumble * 12.0) * 4.0
	var head_tilt := sin(rumble * 6.0) * 0.2

	# Shadow
	draw_circle(Vector2(0, 10.0), 32.0, SHADOW)

	# Body
	draw_circle(Vector2(0, bob), 26.0, GOAT_FUR)
	draw_circle(Vector2(0, bob + 4.0), 20.0, GOAT_BELLY)

	# Shoulders & Flanks
	draw_circle(Vector2(-14.0, bob - 6.0), 14.0, GOAT_DARK)
	draw_circle(Vector2(14.0, bob - 6.0), 14.0, GOAT_DARK)

	# Head and Muzzle
	var head_y := bob - 22.0
	draw_circle(Vector2(0, head_y), 15.0, GOAT_FUR)
	# Muzzle
	draw_rect(Rect2(-7.0, head_y - 14.0, 14.0, 14.0), GOAT_BELLY)

	# Slit-pupil Eyes
	draw_circle(Vector2(-9.0, head_y - 6.0), 3.5, GOAT_EYE)
	draw_circle(Vector2(9.0, head_y - 6.0), 3.5, GOAT_EYE)
	draw_line(Vector2(-11.0, head_y - 6.0), Vector2(-7.0, head_y - 6.0), Color.BLACK, 1.5)
	draw_line(Vector2(7.0, head_y - 6.0), Vector2(11.0, head_y - 6.0), Color.BLACK, 1.5)

	# Goatee Beard
	draw_line(Vector2(0, head_y - 14.0), Vector2(0, head_y - 24.0), GOAT_BELLY, 3.0)

	# Large Backwards-Curved Ribbed Horns
	var horn_l := PackedVector2Array([
		Vector2(-6.0, head_y - 4.0),
		Vector2(-20.0, head_y + 12.0),
		Vector2(-26.0, head_y + 32.0),
		Vector2(-22.0, head_y + 30.0),
		Vector2(-14.0, head_y + 10.0),
		Vector2(-4.0, head_y - 4.0),
	])
	draw_colored_polygon(horn_l, GOAT_HORN)

	var horn_r := PackedVector2Array([
		Vector2(6.0, head_y - 4.0),
		Vector2(20.0, head_y + 12.0),
		Vector2(26.0, head_y + 32.0),
		Vector2(22.0, head_y + 30.0),
		Vector2(14.0, head_y + 10.0),
		Vector2(4.0, head_y - 4.0),
	])
	draw_colored_polygon(horn_r, GOAT_HORN)
