extends RefCounted

# Camera tricks for chases and boss fights:
# - Arena zoom-out while an active boss fight is underway
# - Brief dutch tilt on boss enrage only (never continuous tilt)
# - Letterbox bars during boss reveal cards (hush_banner)
# - Near-miss slow motion when saves_done or close_calls advance

const ARENA_ZOOM := 0.88
const ZOOM_RATE := 3.2
const TILT_DEG := 2.8
const TILT_SECS := 0.55
const LETTERBOX_H := 42.0
const LETTERBOX_RATE := 6.5


static func boss_node(m: Node2D) -> Variant:
	for k: String in ["boss_gat", "mamut", "drac", "lleons"]:
		var b: Variant = m.get(k)
		if b != null:
			return b
	return null


static func tick(m: Node2D, delta: float) -> void:
	if m.cam == null:
		return
	var dt := maxf(delta, 0.0)
	var boss: Variant = boss_node(m)
	var st_v: Variant = boss.get("state") if boss != null else null
	var hp_v: Variant = boss.get("hp") if boss != null else null
	var arena_active := boss != null and st_v != null and int(st_v) != 0 and hp_v != null and float(hp_v) > 0.0
	var enr_v: Variant = boss.get("enraged") if boss != null else null
	var ph_v: Variant = boss.get("phase") if boss != null else null
	var enraged := boss != null and ((enr_v != null and bool(enr_v)) or (ph_v != null and int(ph_v) >= 2))
	if enraged and not bool(m._boss_was_enraged):
		if float(m.cam_tilt_t) <= 0.0:
			m._cam_tilt_base_rot = m.cam.rotation
			m._cam_tilt_base_ignore = m.cam.ignore_rotation
		m.cam_tilt_t = TILT_SECS
		m._cam_tilt_dir = -1.0 if float(m._cam_tilt_dir) > 0.0 else 1.0
	m._boss_was_enraged = enraged

	# Arena zoom-out (multiplicative so UiScale and --shot-zoom stay orthogonal)
	var want_zoom := ARENA_ZOOM if (arena_active and not m.shot_zoom_set) else 1.0
	m.arena_zoom_mult = lerpf(float(m.arena_zoom_mult), want_zoom, 1.0 - exp(-ZOOM_RATE * dt))
	if not is_equal_approx(float(m.arena_zoom_mult), float(m._arena_zoom_applied)):
		m.cam.zoom *= float(m.arena_zoom_mult) / float(m._arena_zoom_applied)
		m._arena_zoom_applied = float(m.arena_zoom_mult)

	# Brief dutch tilt on enrage only; always returns cleanly to base rotation
	if float(m.cam_tilt_t) > 0.0:
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
