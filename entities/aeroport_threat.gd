extends Node2D

# The chase threat of L'Aeroport (Terminal 1): The Airport Security Cart Buggy.
# An electric airport utility buggy with an overzealous security guard, flashing
# amber roof beacon, siren chirps, and an overloaded rear luggage rack.
#
# What sets it apart: tumbling rolling suitcases.
# Every few seconds, an unsecured rolling suitcase slides off the cart bed and
# skids rapidly forward along the polished concourse floor toward the pair.
# A directional skid lane telegraphs where the suitcase will slide.
# Dodging clear counts toward the "luggage_dodge" goal; getting hit causes a tumble.
#
# Implements the standard chase threat interface (setup, advance, caught,
# gap_to, threat_boundary, sweep_junk) so systems/home_chase drives it.

const ShapeBatch := preload("res://systems/shape_batch.gd")

# Visual colors
const BUGGY_WHITE := Color(0.95, 0.96, 0.98)
const BUGGY_BLUE := Color(0.12, 0.28, 0.55)
const BUGGY_DARK := Color(0.18, 0.20, 0.24)
const BUGGY_BUMPER := Color(0.35, 0.38, 0.42)
const BEACON_AMBER := Color(1.0, 0.75, 0.15)
const BEACON_GLOW := Color(1.0, 0.65, 0.10, 0.45)
const WHEEL_RUBBER := Color(0.12, 0.12, 0.14)
const UNIFORM_NAVY := Color(0.14, 0.18, 0.28)
const HIVIS_YELLOW := Color(0.90, 0.95, 0.20)
const SUITCASE_RED := Color(0.85, 0.18, 0.15)
const SUITCASE_BLUE := Color(0.18, 0.40, 0.85)
const SUITCASE_HANDLE := Color(0.20, 0.20, 0.22)
const SKID_LINE := Color(0.95, 0.80, 0.20, 0.40)

# Movement and tuning
const SPEED_DEFAULT := 136.0
const SURGE := 0.12
const CATCH_UP := 1.35
const CATCH_UP_GAP := 650.0
const JAM_SECS := 3.0
const BUGGY_DEPTH := 140.0
const CATCH_SPAN := 0.72

# Tumbling suitcase hazards
const SUITCASE_FIRST := 1.8
const SUITCASE_EVERY := 2.6
const SUITCASE_JITTER := 0.5
const SUITCASE_WARN := 0.9
const SUITCASE_R := 42.0
const SUITCASE_DODGE_R := 110.0
const SUITCASE_LEAD := 0.5
const SUITCASE_MIN_AHEAD := 80.0
const MAX_SUITCASES := 3
const IMPACT_TIME := 0.4

var main: Node2D
var speed := SPEED_DEFAULT
var cur_speed := SPEED_DEFAULT
var front_y := 0.0
var cx := 640.0
var half := 260.0
var kind := "buggy"
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

# Sliding suitcases in flight: {"from": Vector2, "at": Vector2, "t": float, "color": Color}
var suitcases: Array[Dictionary] = []
# Impact ripples: {"at": Vector2, "t": float}
var impacts: Array[Dictionary] = []
var suitcase_t := SUITCASE_FIRST
var drop_count := 0
var hits := 0
var dodges := 0


func setup(m: Node2D, start_front_y: float, corridor_cx: float, corridor_half: float, cart_speed: float) -> void:
	main = m
	front_y = start_front_y
	cx = corridor_cx
	half = corridor_half
	speed = cart_speed
	cur_speed = cart_speed
	suitcases.clear()
	impacts.clear()
	suitcase_t = SUITCASE_FIRST
	position = Vector2(cx, front_y)


func advance(delta: float, gap := -1.0, aim := 0.0) -> void:
	rumble += delta
	jammed_now = false
	freed_now = false
	_tick_suitcases(delta)

	if jam_t > 0.0:
		jam_t -= delta
		cur_speed = 0.0
		if jam_t <= 0.0:
			freed_now = true
		queue_redraw()
		return

	var lurch := sin(rumble * 1.8) * 0.5
	var mult := 1.0 + SURGE * lurch
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
			jammed_now = true
			if Sfx != null:
				Sfx.play("crack", 0.9)
			break

	# Steer toward the dog/human
	var target_sway: float = clampf(aim, -half * 0.4, half * 0.4)
	sway_v += (target_sway - sway) * 2.2 * delta
	sway_v *= exp(-3.8 * delta)
	sway += sway_v * delta

	suitcase_t -= delta
	if suitcase_t <= 0.0 and suitcases.size() < MAX_SUITCASES:
		_drop_suitcase()
		suitcase_t = SUITCASE_EVERY + SUITCASE_JITTER * sin(float(drop_count) * 2.7)

	position = Vector2(cx + sway, front_y)
	queue_redraw()


func jammed() -> bool:
	return jam_t > 0.0


func threat_boundary() -> float:
	return front_y


func caught(p: Vector2) -> bool:
	if p.y <= front_y and p.y >= front_y - BUGGY_DEPTH * 0.7:
		return absf(p.x - (cx + sway)) <= half * CATCH_SPAN
	return p.y < front_y - BUGGY_DEPTH * 0.7


func gap_to(p: Vector2) -> float:
	return p.y - front_y


func sweep_junk(_junk: Array) -> int:
	return 0


func cart_pos() -> Vector2:
	return Vector2(cx + sway, front_y - BUGGY_DEPTH * 0.4)


func aim_point(target: Vector2, vel: Vector2) -> Vector2:
	var p := target + vel * SUITCASE_LEAD
	p.x = clampf(p.x, cx - half + SUITCASE_R, cx + half - SUITCASE_R)
	p.y = maxf(p.y, front_y + SUITCASE_MIN_AHEAD)
	return p


func _drop_suitcase() -> void:
	if main == null:
		return
	var at: Vector2
	if drop_count % 2 == 0:
		at = aim_point(main.dog.global_position, main.dog.velocity)
	else:
		at = aim_point(main.human.global_position, main.human.velocity)
	drop_count += 1
	var col := SUITCASE_RED if drop_count % 2 == 0 else SUITCASE_BLUE
	suitcases.append({"from": cart_pos(), "at": at, "t": 0.0, "color": col})
	if Sfx != null:
		Sfx.play("whoop", 1.4, -6.0)


func _tick_suitcases(delta: float) -> void:
	for i in range(impacts.size() - 1, -1, -1):
		impacts[i]["t"] = float(impacts[i]["t"]) - delta
		if float(impacts[i]["t"]) <= 0.0:
			impacts.remove_at(i)

	for i in range(suitcases.size() - 1, -1, -1):
		var s: Dictionary = suitcases[i]
		s["t"] = float(s["t"]) + delta
		if float(s["t"]) >= SUITCASE_WARN:
			suitcases.remove_at(i)
			_land_suitcase(s["at"])


func _land_suitcase(at: Vector2) -> void:
	impacts.append({"at": at, "t": IMPACT_TIME})
	if Sfx != null:
		Sfx.play("crack", 1.2, -4.0)

	if main == null or main.auto_walk:
		return

	var dp: Vector2 = main.dog.global_position
	var hp: Vector2 = main.human.global_position
	var hit := false

	if at.distance_to(dp) <= SUITCASE_R:
		hit = true
		hits += 1
		main.aeroport_cart_hits += 1
		main.dog.knocked((dp - at).normalized() if dp.distance_to(at) > 1.0 else Vector2.DOWN, "suitcase")
		main.float_text(dp + Vector2(0, -30), "TUMBLED BY LUGGAGE!", Color(1.0, 0.4, 0.3))

	if at.distance_to(hp) <= SUITCASE_R:
		hit = true
		hits += 1
		main.aeroport_cart_hits += 1
		main.human.bumped((hp - at).normalized() if hp.distance_to(at) > 1.0 else Vector2.DOWN)
		main.float_text(hp + Vector2(0, -30), "TRIPPED BY SUITCASE!", Color(1.0, 0.5, 0.3))

	if not hit:
		if at.distance_to(dp) <= SUITCASE_DODGE_R or at.distance_to(hp) <= SUITCASE_DODGE_R:
			dodges += 1
			main.aeroport_luggage_dodges += 1
			main.combo.add("SUITCASE DODGE", 1)
			main.float_text(dp + Vector2(0, -25), "SUITCASE DODGE! +1", Color(0.4, 0.9, 1.0))


func _draw() -> void:
	var b := ShapeBatch.new(self)
	_draw_skids_and_suitcases(b)
	_draw_buggy(b)
	b.flush()


func _draw_skids_and_suitcases(b: ShapeBatch) -> void:
	# Draw sliding tracks and airborne/sliding suitcases
	for s: Dictionary in suitcases:
		var p_from: Vector2 = s["from"] - position
		var p_at: Vector2 = s["at"] - position
		var t_ratio: float = clampf(float(s["t"]) / SUITCASE_WARN, 0.0, 1.0)
		var cur_pos: Vector2 = p_from.lerp(p_at, t_ratio)

		# Skid track line on floor
		b.rect(Rect2(p_at - Vector2(18.0, 4.0), Vector2(36.0, 8.0)), SKID_LINE)
		b.circle(p_at, SUITCASE_R * t_ratio, Color(1.0, 0.8, 0.2, 0.25))

		# Sliding suitcase
		var col: Color = s["color"]
		b.rect(Rect2(cur_pos - Vector2(14.0, 9.0), Vector2(28.0, 18.0)), col)
		b.rect(Rect2(cur_pos - Vector2(10.0, 11.0), Vector2(20.0, 3.0)), SUITCASE_HANDLE)
		b.circle(cur_pos - Vector2(9.0, -8.0), 3.0, WHEEL_RUBBER)
		b.circle(cur_pos + Vector2(9.0, 8.0), 3.0, WHEEL_RUBBER)

	# Impact shockwave ripples
	for imp: Dictionary in impacts:
		var ip: Vector2 = imp["at"] - position
		var it: float = float(imp["t"]) / IMPACT_TIME
		var r: float = (1.0 - it) * SUITCASE_R * 1.3
		b.circle(ip, r, Color(1.0, 0.7, 0.3, it * 0.5))


func _draw_buggy(b: ShapeBatch) -> void:
	# Local origin is (0, 0) which corresponds to (cx + sway, front_y)
	var cart_top := -BUGGY_DEPTH
	var cart_w := 90.0
	var cart_half := cart_w * 0.5

	# Four wheels
	b.rect(Rect2(-cart_half - 6.0, cart_top + 16.0, 10.0, 24.0), WHEEL_RUBBER)
	b.rect(Rect2(cart_half - 4.0, cart_top + 16.0, 10.0, 24.0), WHEEL_RUBBER)
	b.rect(Rect2(-cart_half - 6.0, -36.0, 10.0, 24.0), WHEEL_RUBBER)
	b.rect(Rect2(cart_half - 4.0, -36.0, 10.0, 24.0), WHEEL_RUBBER)

	# Main white body chassis
	b.rect(Rect2(-cart_half, cart_top, cart_w, BUGGY_DEPTH), BUGGY_WHITE)

	# Blue Aeroport security belt-stripe
	b.rect(Rect2(-cart_half, cart_top + 40.0, cart_w, 14.0), BUGGY_BLUE)

	# Front steel bumper and headlights
	b.rect(Rect2(-cart_half - 2.0, -10.0, cart_w + 4.0, 10.0), BUGGY_BUMPER)
	b.circle(Vector2(-cart_half + 14.0, -4.0), 5.0, Color(1.0, 1.0, 0.7))
	b.circle(Vector2(cart_half - 14.0, -4.0), 5.0, Color(1.0, 1.0, 0.7))

	# Windshield / front dash
	b.rect(Rect2(-cart_half + 8.0, cart_top + 58.0, cart_w - 16.0, 8.0), Color(0.2, 0.3, 0.4, 0.7))

	# Driver (security officer)
	b.circle(Vector2(-14.0, cart_top + 78.0), 10.0, UNIFORM_NAVY)
	b.rect(Rect2(-24.0, cart_top + 70.0, 20.0, 18.0), HIVIS_YELLOW)

	# Passenger seat / empty steering wheel
	b.circle(Vector2(14.0, cart_top + 78.0), 7.0, BUGGY_DARK)

	# Rear luggage bed with metal railing
	b.rect(Rect2(-cart_half + 6.0, cart_top + 10.0, cart_w - 12.0, 32.0), Color(0.25, 0.28, 0.32))
	# Confiscated bags in the back
	b.rect(Rect2(-cart_half + 12.0, cart_top + 14.0, 22.0, 16.0), SUITCASE_RED)
	b.rect(Rect2(4.0, cart_top + 18.0, 26.0, 18.0), SUITCASE_BLUE)

	# Roll-bar and rotating amber beacon on roof
	b.rect(Rect2(-cart_half + 4.0, cart_top + 64.0, cart_w - 8.0, 4.0), BUGGY_BUMPER)
	var flash_phase: float = fmod(AnimClock.msec() / 1000.0 * 6.0, 1.0)
	var flash_alpha: float = 0.5 + 0.5 * sin(flash_phase * TAU)
	b.circle(Vector2(0.0, cart_top + 66.0), 8.0, BEACON_AMBER)
	b.circle(Vector2(0.0, cart_top + 66.0), 18.0, Color(BEACON_GLOW.r, BEACON_GLOW.g, BEACON_GLOW.b, BEACON_GLOW.a * flash_alpha))
