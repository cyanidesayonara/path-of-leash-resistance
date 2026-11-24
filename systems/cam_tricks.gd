extends RefCounted

# Camera tricks for chases and boss fights:
# - Fight framing: from the wake to the last blow the camera leans and pulls
#   back just enough that she, your human and the boss are all in the picture,
#   whichever way round him she runs, and lets go of him when she is far away
# - Shake as a smooth shudder that dies away, not a new random jolt a frame
# - Brief dutch tilt on boss enrage only (never continuous tilt)
# - Letterbox bars during boss reveal cards (hush_banner)
# - Near-miss slow motion when saves_done or close_calls advance

const HomeChase := preload("res://systems/home_chase.gd")

const ARENA_ZOOM := 0.88
const ZOOM_RATE := 3.2
const FIGHT_ZOOM_MIN := 0.70     # no further out than this, or she is a speck
const FIGHT_LEAN_MAX := 250.0
const LEAN_RATE := 3.2
const BOSS_R := 110.0            # the room a boss takes, with his health bar
const PAIR_R := 46.0
const TOP_PX := 92.0             # screen kept clear for the banner
const BOTTOM_PX := 40.0
const HOLD_NEAR := 560.0         # a boss this near her is fully framed,
const HOLD_FAR := 800.0          # this far not at all
const SHAKE_PX := 10.0
const TILT_DEG := 2.8
const TILT_SECS := 0.55
const LETTERBOX_H := 42.0
const LETTERBOX_RATE := 6.5


static func boss_node(m: Node2D) -> Variant:
	for k: String in ["boss_gat", "mamut", "drac", "lleons", "lleona"]:
		var b: Variant = m.get(k)
		if b != null:
			return b
	return null


# where the boss, or each of a pair of them, is
static func boss_points(boss: Variant) -> Array[Vector2]:
	var out: Array[Vector2] = []
	if boss == null:
		return out
	var p: Variant = boss.get("pos")
	if p is Vector2:
		out.append(p)
	for k: String in ["lion_a", "lion_b"]:
		var l: Variant = boss.get(k)
		if l is Dictionary and (l as Dictionary).get("pos") is Vector2:
			out.append(l["pos"])
	return out


static func fighting(boss: Variant) -> bool:
	if boss == null:
		return false
	if boss.has_method("in_fight"):
		return bool(boss.in_fight())
	var hp: Variant = boss.get("hp")
	return hp != null and float(hp) > 0.0 and int(boss.get("state")) != 0


# What it takes to show the fight: [how far from the pair's own framing the
# camera should lean, the zoom multiplier]. `base_zoom` is the zoom without it.
static func fight_frame(dog: Vector2, human: Vector2, bosses: Array[Vector2], view: Vector2, base_zoom: float) -> Vector2:
	var pair_y: float = (dog.y + human.y) * 0.5 + HomeChase.CAMERA_PAIR_OFFSET_Y
	var box := Rect2(dog, Vector2.ZERO).expand(human).grow(PAIR_R)
	var w := 0.0
	for p in bosses:
		w = maxf(w, 1.0 - clampf((dog.distance_to(p) - HOLD_NEAR) / (HOLD_FAR - HOLD_NEAR), 0.0, 1.0))
	if w <= 0.0:
		return Vector2(0.0, ARENA_ZOOM)
	var full := box
	for p in bosses:
		if dog.distance_to(p) < HOLD_FAR:
			full = full.merge(Rect2(p, Vector2.ZERO).grow(BOSS_R))
	var room := Vector2(view.x, view.y - TOP_PX - BOTTOM_PX) / base_zoom
	var mult := clampf(minf(room.x / full.size.x, room.y / full.size.y), FIGHT_ZOOM_MIN, ARENA_ZOOM)
	# the picture's middle, allowing for the banner over the top of it
	var mid_y := full.get_center().y - (TOP_PX - BOTTOM_PX) * 0.5 / (base_zoom * mult)
	# she is never pushed out of it to make room for him
	var half := view.y * 0.5 / (base_zoom * mult)
	mid_y = clampf(mid_y, box.end.y - half + BOTTOM_PX / (base_zoom * mult), box.position.y + half - TOP_PX / (base_zoom * mult)) 		if box.size.y < half * 2.0 - (TOP_PX + BOTTOM_PX) / (base_zoom * mult) else pair_y
	return Vector2(clampf(mid_y - pair_y, -FIGHT_LEAN_MAX, FIGHT_LEAN_MAX) * w, lerpf(ARENA_ZOOM, mult, w))


# The shudder of a hit: two slow-beating sines a side, dying away
static func shake(t: float, amount: float) -> Vector2:
	var k := amount * amount if amount < 1.0 else amount
	return Vector2(sin(t * 58.0) + 0.6 * sin(t * 91.0 + 1.3), sin(t * 67.0 + 0.7) + 0.6 * sin(t * 103.0)) * 0.62 * SHAKE_PX * k


static func tick(m: Node2D, delta: float) -> void:
	if m.cam == null:
		return
	var dt := maxf(delta, 0.0)
	var boss: Variant = boss_node(m)
	var arena_active := fighting(boss)
	var enr_v: Variant = boss.get("enraged") if boss != null else null
	var ph_v: Variant = boss.get("phase") if boss != null else null
	var enraged := boss != null and ((enr_v != null and bool(enr_v)) or (ph_v != null and int(ph_v) >= 2))
	var _ml := Engine.get_main_loop()
	var _gm: Node = _ml.root.get_node_or_null("Game") if _ml != null and _ml is SceneTree else null
	var shake_on := true if _gm == null else bool(_gm.screen_shake)
	if enraged and not bool(m._boss_was_enraged) and shake_on:
		if float(m.cam_tilt_t) <= 0.0:
			m._cam_tilt_base_rot = m.cam.rotation
			m._cam_tilt_base_ignore = m.cam.ignore_rotation
		m.cam_tilt_t = TILT_SECS
		m._cam_tilt_dir = -1.0 if float(m._cam_tilt_dir) > 0.0 else 1.0
	m._boss_was_enraged = enraged

	# Arena zoom-out (multiplicative so UiScale and --shot-zoom stay orthogonal)
	var want_zoom := 1.0
	var want_lean := 0.0
	if arena_active and not m.shot_zoom_set:
		var frame := fight_frame(m.dog.global_position, m.human.global_position, boss_points(boss),
			m.get_viewport_rect().size, float(m.cam.zoom.y) / float(m._arena_zoom_applied))
		want_zoom = frame.y
		want_lean = frame.x
	# the fight's lean hands over to and from the walk's own with no jump
	if not arena_active and m.walk_mod != null and m.walk_mod.has_method("cam_lean"):
		want_lean = float(m.walk_mod.cam_lean(m))
	m.fight_lean = lerpf(float(m.fight_lean), want_lean, 1.0 - exp(-LEAN_RATE * dt))
	m.arena_zoom_mult = lerpf(float(m.arena_zoom_mult), want_zoom, 1.0 - exp(-ZOOM_RATE * dt))
	if not is_equal_approx(float(m.arena_zoom_mult), float(m._arena_zoom_applied)):
		m.cam.zoom *= float(m.arena_zoom_mult) / float(m._arena_zoom_applied)
		m._arena_zoom_applied = float(m.arena_zoom_mult)

	# Brief dutch tilt on enrage only; always returns cleanly to base rotation
	if float(m.cam_tilt_t) > 0.0:
		if not shake_on:
			m.cam_tilt_t = 0.0
			m.cam.rotation = float(m._cam_tilt_base_rot)
			m.cam.ignore_rotation = bool(m._cam_tilt_base_ignore)
		else:
			m.cam_tilt_t = maxf(0.0, float(m.cam_tilt_t) - dt)
			if float(m.cam_tilt_t) <= 0.0:
				m.cam.rotation = float(m._cam_tilt_base_rot)
				m.cam.ignore_rotation = bool(m._cam_tilt_base_ignore)
			else:
				m.cam.ignore_rotation = false
				var u := 1.0 - float(m.cam_tilt_t) / TILT_SECS
				m.cam.rotation = float(m._cam_tilt_base_rot) + sin(u * PI) * deg_to_rad(TILT_DEG) * float(m._cam_tilt_dir)

	# Cinema letterbox bars during boss reveal cards
	var revealing: bool = m.walk_mod != null and m.walk_mod.has_method("hush_banner") and bool(m.walk_mod.hush_banner(m))
	m.letterbox_amt = lerpf(float(m.letterbox_amt), 1.0 if revealing else 0.0, 1.0 - exp(-LETTERBOX_RATE * dt))
	_update_letterbox(m)

	# Near-miss slow motion when a dodge save or close call lands
	if (int(m.saves_done) > int(m._prev_saves_done) or int(m.close_calls) > int(m._prev_close_calls)) \
			and m.started and not m.frozen and not m.auto_walk:
		m._slowmo()
	m._prev_saves_done = int(m.saves_done)
	m._prev_close_calls = int(m.close_calls)


static func _update_letterbox(m: Node2D) -> void:
	if m.letterbox_top == null or m.letterbox_bot == null:
		return
	var show := float(m.letterbox_amt) > 0.01
	m.letterbox_top.visible = show
	m.letterbox_bot.visible = show
	if not show:
		return
	var vp: Vector2 = m.get_viewport_rect().size
	var h := LETTERBOX_H * float(m.letterbox_amt)
	m.letterbox_top.position = Vector2.ZERO
	m.letterbox_top.size = Vector2(vp.x, h)
	m.letterbox_bot.position = Vector2(0.0, vp.y - h)
	m.letterbox_bot.size = Vector2(vp.x, h)
