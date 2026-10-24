extends RefCounted

# The end of a walk, and the door it started from. Every walk is one of three
# families (apartment, transit, safe exit) and one arrival state drives all
# three: both of you past the home line, the walk freezes, Millie pulls in,
# your human looks up and pockets the phone, she goes through, they follow,
# the leash goes with them, then the card. The first half-second cannot be
# skipped. An autowalk finishes on the same frame it crosses, so its recorded
# time does not grow a cinematic.

const SkyLook := preload("res://systems/sky.gd")
const TofuRoute := preload("res://systems/tofu_route.gd")
const ExitPortals := preload("res://systems/exit_portals.gd")

const SKIP_LOCK := 0.5
const PULL := 0.55
const DOG_IN := 0.85
const HUMAN_IN := 0.85
const TAIL := 0.35
const DURATION := PULL + DOG_IN + HUMAN_IN + TAIL
const DEPART := 1.25
const DEPART_HOLD := 0.45
# the opening they actually pass through, north of the south wall
const MOUTH_W := 52.0
const MOUTH_H := 24.0
const PRINTS := 8
# the walk in: each one fades only over the last part of their way in, at the
# threshold, and steps as they go (hgait and gait per pixel, as in their ticks)
const FADE_FROM := 0.6
const HUMAN_STEP := 0.06
const DOG_STEP := 0.055
const TURN := 12.0
# The arrival starts this far north of HOME_Y, so they walk the last stretch
# to the door in the cinematic. Started at HOME_Y itself, the door was 8 px
# away and the walk in was a slide. The autowalk keeps HOME_Y: it finishes on
# the frame it crosses, and its recorded times stay as they were.
const WALK_IN := 140.0


static func line_y(m: Node2D) -> float:
	return float(m.HOME_Y) - (0.0 if m.auto_walk else WALK_IN)

const APARTMENT: Array[String] = [
	"tutorial", "barri", "street", "park", "beach", "rain", "market", "oldtown",
	"site", "spook", "scrap", "guell", "neteja", "port",
]


static func family_for(id: String) -> String:
	match place_for(id):
		"station", "funicular", "metro":
			return "transit"
		"trailhead", "ramp":
			return "safe"
		_:
			return "apartment"


static func place_for(id: String) -> String:
	if id in APARTMENT:
		return "apartment"
	match id:
		"station":
			return "station"
		"montjuic", "tibidabo":
			return "funicular"
		"partit":
			return "metro"
		"trail":
			return "trailhead"
		"besos":
			return "ramp"
		_:
			return "apartment"


static func place_of(m: Node2D) -> String:
	return place_for("tutorial" if m.tutorial_mode else String(m.lvl))


static func family_of(m: Node2D) -> String:
	return family_for("tutorial" if m.tutorial_mode else String(m.lvl))


# the door stands open behind an apartment pair until the walk starts
static func note_start(m: Node2D) -> void:
	if family_of(m) == "apartment":
		m.depart_open = 1.0
		m.depart_hold = DEPART_HOLD
	else:
		m.depart_open = 0.0
		m.depart_hold = 0.0


static func tick_depart(m: Node2D, delta: float) -> void:
	if not m.started or m.arriving or family_of(m) != "apartment":
		return
	var step := minf(delta, 0.05)
	if m.depart_hold > 0.0:
		m.depart_hold = maxf(0.0, float(m.depart_hold) - step)
		return
	if m.depart_open > 0.0:
		# a long frame must not slam the door; it shuts over DEPART either way
		m.depart_open = maxf(0.0, float(m.depart_open) - step / DEPART)


static func begin(m: Node2D) -> void:
	if m.arriving or m.finished:
		return
	m.arriving = true
	m.arrival_t = 0.0
	m.arrival_print_n = 0
	m.depart_open = 0.0
	m.depart_hold = 0.0
	m.frozen = true
	m.dog.velocity = Vector2.ZERO
	m.human.velocity = Vector2.ZERO
	_hold_threat(m)
	if m.arrival_at.x >= INF:
		m.arrival_at = fit(m)
	if m.auto_walk:
		m.arrival_t = DURATION
		_complete(m)


static func tick(m: Node2D, delta: float) -> void:
	if not m.arriving:
		return
	m.arrival_t = minf(float(m.arrival_t) + delta, DURATION)
	_hold_threat(m)
	_apply(m, delta)
	if float(m.arrival_t) >= SKIP_LOCK:
		m.feed.set_banner("HEAD INSIDE")
	m.dog.queue_redraw()
	m.human.queue_redraw()
	m.leash.queue_redraw()
	m.queue_redraw()
	if float(m.arrival_t) >= DURATION:
		_complete(m)


static func can_skip(m: Node2D) -> bool:
	return m.arriving and float(m.arrival_t) >= SKIP_LOCK


static func skip(m: Node2D) -> void:
	if not can_skip(m):
		return
	m.arrival_t = DURATION
	_complete(m)


static func aperture(m: Node2D) -> Rect2:
	# fit() asks the physics space, so draw uses the point physics already chose
	var c: Vector2 = m.arrival_at if m.arrival_at.x < INF else _fallback(m)
	return Rect2(c.x - MOUTH_W * 0.5, c.y - MOUTH_H * 0.5, MOUTH_W, MOUTH_H)


# Where they walk to and fade: the door itself, except El Tibidabo's, which is
# the near end of a platform; they cross it to the docked carriage's door.
static func walk_to(m: Node2D) -> Vector2:
	var c := aperture(m).get_center()
	if m.lvl == "tibidabo":
		return Vector2(Tibidabo.TRACK_X - Tibidabo.CAR_W * 0.5 - 6.0, c.y)
	return c


static func _fallback(m: Node2D) -> Vector2:
	var top := float(m.HOME_Y) + 8.0
	var e: Vector2 = m.walk_edges(top + MOUTH_H * 0.5)
	return Vector2((e.x + e.y) * 0.5, top + MOUTH_H * 0.5)


# a mouth on the path, clear of solids, as close to the middle as one can be
static func fit(m: Node2D) -> Vector2:
	var top := float(m.HOME_Y) + 8.0
	var e: Vector2 = m.walk_edges(top + MOUTH_H * 0.5)
	var mid := (e.x + e.y) * 0.5
	var half := (e.y - e.x) * 0.5
	var best := Vector2(mid, top + MOUTH_H * 0.5)
	# El Tibidabo's door is the funicular's bottom station, on the road's east
	# edge beside the track: as far east as is clear
	var fracs: Array[float] = [0.0, 0.2, -0.2, 0.4, -0.4, 0.55, -0.55]
	if m.lvl == "tibidabo":
		fracs = [0.55, 0.45, 0.35, 0.2, 0.0]
	for frac: float in fracs:
		var c := Vector2(mid + half * frac, top + MOUTH_H * 0.5)
		if rect_clear(m, Rect2(c.x - MOUTH_W * 0.5, c.y - MOUTH_H * 0.5, MOUTH_W, MOUTH_H)):
			return c
	return best


static func rect_clear(m: Node2D, r: Rect2) -> bool:
	var inset := r.grow(-6.0)
	if inset.size.x <= 1.0 or inset.size.y <= 1.0:
		return false
	var pts: Array[Vector2] = [
		inset.get_center(),
		inset.position, inset.end,
		Vector2(inset.position.x, inset.end.y),
		Vector2(inset.end.x, inset.position.y),
	]
	for p: Vector2 in pts:
		if not TofuRoute.point_ok(m, p, 0.0) or TofuRoute.static_hit(m, p):
			return false
	return true


static func _weather(m: Node) -> String:
	return String(m.get_tree().root.get_node("Game").weather)


static func _night(m: Node) -> bool:
	return bool(m.get_tree().root.get_node("Game").night)


static func draw(m: Node2D, b: ShapeBatch) -> void:
	var r := aperture(m)
	var c := r.get_center()
	var open := _open_amount(m)
	var place := place_of(m)
	var weather := _weather(m)
	var night := _night(m)
	ExitPortals.static_geometry(m, c, place, weather).append_to(b)
	ExitPortals.draw_live(b, m, c, place, open, night)
	if weather == "snow":
		b.rect(Rect2(c.x - 36.0, r.end.y - 3.0, 72.0, 7.0), Color(0.94, 0.97, 1.0, 0.92))
	if night:
		var tint := SkyLook.tint(String(m.lvl), weather, true)
		var warm := Color(1.0, 0.78, 0.46, 0.20)
		b.circle(c + Vector2(0.0, 10.0), 34.0, SkyLook.light(warm, tint))
		b.circle(c + Vector2(0.0, 10.0), 7.0, SkyLook.light(Color(1.0, 0.96, 0.82, 0.85), tint))
	var n := int(m.arrival_print_n)
	for i in n:
		var p: Vector2 = m.arrival_prints[i]
		b.circle(p, 3.0, Color(0.16, 0.17, 0.18, 0.40))
		b.circle(p + Vector2(4.5, 0.8), 2.2, Color(0.16, 0.17, 0.18, 0.32))


static func _open_amount(m: Node2D) -> float:
	if m.arriving:
		return clampf((float(m.arrival_t) - PULL * 0.4) / DOG_IN, 0.0, 1.0)
	if family_of(m) != "apartment":
		return 0.0
	return clampf(float(m.depart_open), 0.0, 1.0)


static func _hold_threat(m: Node2D) -> void:
	var s: Node2D = m.chase_sweeper
	if s == null or not is_instance_valid(s):
		return
	if s.global_position.y > float(m.HOME_Y):
		s.global_position.y = float(m.HOME_Y)


static func _apply(m: Node2D, delta := 0.0) -> void:
	var t := float(m.arrival_t)
	var pull_u := clampf(t / PULL, 0.0, 1.0)
	var dog_u := clampf((t - PULL) / DOG_IN, 0.0, 1.0)
	var human_u := clampf((t - PULL - DOG_IN) / HUMAN_IN, 0.0, 1.0)
	var mouth: Vector2 = walk_to(m)
	var dog_from: Vector2 = m.dog.global_position
	var human_from: Vector2 = m.human.global_position
	# she leans in on the pull, then goes; he follows. Eased at both ends, so
	# nobody starts or stops dead.
	var dog_aim := smoothstep(0.0, 1.0, clampf(pull_u * 0.35 + dog_u * 0.65, 0.0, 1.0))
	var human_aim := smoothstep(0.0, 1.0, human_u)
	var dog_world := dog_from.lerp(mouth, dog_aim) - dog_from
	var human_world := human_from.lerp(mouth, human_aim) - human_from
	# their steps: the legs swing at the speed they are actually moved at
	if delta > 0.0:
		var dog_step: float = (dog_world - m.leash.presentation_dog_offset).length()
		var human_step: float = (human_world - m.leash.presentation_human_offset).length()
		m.dog.presentation_speed = dog_step / delta
		m.human.presentation_speed = human_step / delta
		m.dog.gait += dog_step * DOG_STEP * m.dog._cadence()
		m.human.hgait += human_step * HUMAN_STEP
		# and they face where they are going
		var k := minf(TURN * delta, 1.0)
		var to_dog := mouth - (dog_from + dog_world)
		if dog_step > 0.05 and to_dog.length() > 2.0:
			m.dog.facing = m.dog.facing.slerp(to_dog.normalized(), k).normalized()
		var to_human := mouth - (human_from + human_world)
		var look := to_human if human_step > 0.05 and to_human.length() > 2.0 else (dog_from + dog_world) - (human_from + human_world)
		if look.length() > 2.0:
			m.human.face_dir = m.human.face_dir.slerp(look.normalized(), k).normalized()
	m.dog.presentation_offset = dog_world.rotated(-float(m.dog.global_rotation))
	m.human.presentation_offset = human_world.rotated(-float(m.human.global_rotation))
	m.human.phone_away = pull_u
	m.dog.modulate.a = 1.0 - smoothstep(FADE_FROM, 1.0, dog_u)
	m.human.modulate.a = 1.0 - smoothstep(FADE_FROM, 1.0, human_u)
	m.leash.presentation_dog_offset = dog_world
	m.leash.presentation_human_offset = human_world
	# she pulls the leash straight, and it follows him in
	m.leash.presentation_straighten = pull_u
	m.leash.modulate.a = 1.0 - smoothstep(FADE_FROM, 1.0, human_u)
	if _weather(m) == "rain" and dog_u > 0.0:
		_stamp(m, dog_from + dog_world)


static func _stamp(m: Node2D, p: Vector2) -> void:
	if int(m.arrival_print_n) > 0:
		var prev: Vector2 = m.arrival_prints[int(m.arrival_print_n) - 1]
		if prev.distance_to(p) < 14.0:
			return
	if int(m.arrival_print_n) >= PRINTS:
		return
	if m.arrival_prints.size() != PRINTS:
		m.arrival_prints.resize(PRINTS)
	m.arrival_prints[int(m.arrival_print_n)] = p
	m.arrival_print_n += 1


static func _complete(m: Node2D) -> void:
	if not m.arriving:
		return
	m.arriving = false
	_clear(m)
	# they went in: they are at the door, past HOME_Y, which finishing needs
	var mouth := aperture(m).get_center()
	m.dog.global_position.y = maxf(m.dog.global_position.y, mouth.y)
	m.human.global_position.y = maxf(m.human.global_position.y, mouth.y)
	m.feed.set_banner("")
	m._finish_walk()


static func _clear(m: Node2D) -> void:
	m.dog.presentation_offset = Vector2.ZERO
	m.dog.presentation_rotation = 0.0
	m.dog.presentation_speed = 0.0
	m.dog.modulate.a = 1.0
	m.human.presentation_offset = Vector2.ZERO
	m.human.presentation_rotation = 0.0
	m.human.presentation_speed = 0.0
	m.human.phone_away = 0.0
	m.human.modulate.a = 1.0
	m.leash.presentation_dog_offset = Vector2.ZERO
	m.leash.presentation_human_offset = Vector2.ZERO
	m.leash.presentation_straighten = 0.0
	m.leash.modulate.a = 1.0
	m.dog.queue_redraw()
	m.human.queue_redraw()
	m.leash.queue_redraw()
