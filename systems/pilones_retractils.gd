class_name PilonesRetractils
extends RefCounted

# Retractable lit bollards (pilones retràctils) for pedestrian zones (El Gòtic):
# set into flush steel plates at alley entries, rising to keep cars out and
# sinking into the paving after a 0.8 s amber strobe telegraph so delivery vans
# can pass. Barking near a raised bollard trips its sensor once for points.

const ShapeBatch := preload("res://systems/shape_batch.gd")
const AnimClock := preload("res://systems/anim_clock.gd")

enum State { UP, WARN_DOWN, DOWN, WARN_UP }

const GATE_YS: Array[float] = [-1350.0, -3720.0]
const WALL_INSET := 92.0
const PLATE_R := 18.0
const BOLLARD_R := 11.0
const WARN_SECS := 0.8
const UP_SECS := 4.2
const DOWN_SECS := 3.2
const LIFT_RATE := 6.5
const BARK_R := 110.0
const VAN_SPEED := 95.0
const VAN_WAIT_GAP := 92.0
const VAN_SPAN := 240.0


static func _ensure(m: Node2D) -> Array[Dictionary]:
	if not m.gotic_pilones.is_empty():
		return m.gotic_pilones
	for i in range(GATE_YS.size()):
		var gy := GATE_YS[i]
		var e: Vector2 = m.walk_edges(gy)
		var pos := Vector2(e.x + WALL_INSET, gy)
		var body := StaticBody2D.new()
		body.collision_layer = 1
		body.position = pos
		var cs := CollisionShape2D.new()
		var sh := CircleShape2D.new()
		sh.radius = BOLLARD_R
		cs.shape = sh
		body.add_child(cs)
		m.add_child(body)
		m.gotic_pilones.append({
			"id": i,
			"pos": pos,
			"state": State.UP,
			"t": UP_SECS * (0.45 if i == 0 else 0.85),
			"lift": 1.0,
			"body": body,
			"shape": cs,
			"van_off": -VAN_WAIT_GAP,
			"van_dir": 1.0,
			"bark_paid": false,
			"warn_shown": false,
		})
	return m.gotic_pilones


static func tick(m: Node2D, delta: float) -> void:
	if m.lvl != "oldtown" or m.detour_active:
		return
	var gates := _ensure(m)
	var dp: Vector2 = m.dog.global_position if m.dog != null else Vector2(INF, INF)
	for g: Dictionary in gates:
		var st := int(g["state"])
		var pos: Vector2 = g["pos"]
		g["t"] = float(g["t"]) - delta
		match st:
			State.UP:
				g["lift"] = move_toward(float(g["lift"]), 1.0, LIFT_RATE * delta)
				if float(g["t"]) <= 0.0:
					g["state"] = State.WARN_DOWN
					g["t"] = WARN_SECS
					g["warn_shown"] = false
					if dp.distance_to(pos) < 260.0 and Sfx != null:
						Sfx.play("bell", 1.4, -14.0)
			State.WARN_DOWN:
				if not bool(g["warn_shown"]) and dp.distance_to(pos) < 220.0:
					g["warn_shown"] = true
					m.float_text(pos + Vector2(0.0, -24.0), "Beep! Dropping...", Color(1.0, 0.82, 0.35), m.POP_SAY)
				if float(g["t"]) <= 0.0:
					g["state"] = State.DOWN
					g["t"] = DOWN_SECS
			State.DOWN:
				g["lift"] = move_toward(float(g["lift"]), 0.0, LIFT_RATE * delta)
				var vdir := float(g["van_dir"])
				g["van_off"] = clampf(float(g["van_off"]) + vdir * VAN_SPEED * delta, -VAN_SPAN * 0.5, VAN_SPAN * 0.5)
				if float(g["t"]) <= 0.0:
					g["state"] = State.WARN_UP
					g["t"] = WARN_SECS
					g["warn_shown"] = false
					if dp.distance_to(pos) < 260.0 and Sfx != null:
						Sfx.play("bell", 1.6, -14.0)
			State.WARN_UP:
				if not bool(g["warn_shown"]) and dp.distance_to(pos) < 85.0:
					g["warn_shown"] = true
					m.float_text(pos + Vector2(0.0, -24.0), "Watch your paws!", Color(1.0, 0.55, 0.30), m.POP_SAY)
				if float(g["t"]) <= 0.0:
					g["state"] = State.UP
					g["t"] = UP_SECS
					g["van_dir"] = -float(g["van_dir"])
					g["van_off"] = -float(g["van_dir"]) * VAN_WAIT_GAP
					_nudge_clear(m, pos)
		var cs: CollisionShape2D = g["shape"]
		if cs != null:
			cs.disabled = float(g["lift"]) <= 0.45


static func _nudge_clear(m: Node2D, pos: Vector2) -> void:
	var min_d := BOLLARD_R + 14.0
	for body: Node2D in [m.dog, m.human]:
		if body == null:
			continue
		var d: Vector2 = body.global_position - pos
		if d.length() < min_d:
			var n := d.normalized() if d.length() > 0.5 else Vector2.RIGHT
			body.global_position = pos + n * min_d


static func on_bark(m: Node2D, pos: Vector2) -> bool:
	if m.lvl != "oldtown" or m.detour_active:
		return false
	var gates := _ensure(m)
	for g: Dictionary in gates:
		var gp: Vector2 = g["pos"]
		if pos.distance_to(gp) <= BARK_R and int(g["state"]) == State.UP:
			g["state"] = State.WARN_DOWN
			g["t"] = WARN_SECS
			g["warn_shown"] = false
			if Sfx != null:
				Sfx.play("bell", 1.5, -10.0)
			if not bool(g["bark_paid"]):
				g["bark_paid"] = true
				m.combo.add("BOLLARD", 2)
				m.award_points(2, "sensor beep! +2")
			return true
	return false


static func draw(m: Node2D, wc: ShapeBatch, vt: float, vb: float) -> void:
	if m.lvl != "oldtown" or m.detour_active:
		return
	var gates := _ensure(m)
	var t := AnimClock.msec() / 1000.0
	for g: Dictionary in gates:
		var pos: Vector2 = g["pos"]
		if pos.y < vt - 180.0 or pos.y > vb + 180.0:
			continue
		var st := int(g["state"])
		var lift := float(g["lift"])
		var warning := st == State.WARN_DOWN or st == State.WARN_UP
		var flash := fmod(t * 9.0, 2.0) < 1.0 if warning else true

		# Flush steel street housing plate
		wc.rect(Rect2(pos - Vector2(PLATE_R, PLATE_R), Vector2(PLATE_R * 2.0, PLATE_R * 2.0)), Color(0.24, 0.25, 0.27))
		wc.rect(Rect2(pos - Vector2(PLATE_R - 2.0, PLATE_R - 2.0), Vector2((PLATE_R - 2.0) * 2.0, (PLATE_R - 2.0) * 2.0)), Color(0.32, 0.33, 0.35))
		for cx: float in [-1.0, 1.0]:
			for cy: float in [-1.0, 1.0]:
				wc.circle(pos + Vector2(cx * (PLATE_R - 4.0), cy * (PLATE_R - 4.0)), 1.6, Color(0.16, 0.16, 0.18))
		wc.circle(pos, BOLLARD_R + 2.0, Color(0.10, 0.10, 0.12))

		if lift > 0.03:
			var h_off := Vector2(0.0, -lift * 6.0)
			wc.circle(pos + Vector2(lift * 5.0, lift * 7.0), BOLLARD_R * (0.7 + 0.3 * lift), Color(0, 0, 0, 0.24 * lift))
			wc.circle(pos + h_off, BOLLARD_R, Color(0.12, 0.13, 0.15))
			wc.circle(pos + h_off, BOLLARD_R * 0.85, Color(0.28, 0.30, 0.33))
			var led_col := Color(1.0, 0.34, 0.14) if st == State.WARN_UP else Color(1.0, 0.78, 0.18)
			if flash:
				wc.glow(pos + h_off, BOLLARD_R * 2.1, Color(led_col.r, led_col.g, led_col.b, 0.26 * lift), 0.5)
				wc.circle(pos + h_off, BOLLARD_R * 0.68, led_col)
			wc.circle(pos + h_off, BOLLARD_R * 0.42, Color(0.34, 0.36, 0.40))
		elif warning and flash:
			wc.glow(pos, PLATE_R * 1.4, Color(1.0, 0.65, 0.18, 0.35), 0.5)
			wc.circle(pos, BOLLARD_R * 0.55, Color(1.0, 0.78, 0.22))

		# Delivery van waiting or passing through the gate
		var vp := Vector2(pos.x, pos.y + float(g["van_off"]))
		_draw_delivery_van(wc, vp, float(g["van_dir"]), st == State.UP or warning, t)


static func _draw_delivery_van(wc: ShapeBatch, p: Vector2, dir: float, waiting: bool, t: float) -> void:
	var w := 24.0
	var h := 44.0
	wc.rect(Rect2(p.x - w + 3.0, p.y - h + 4.0, w * 2.0, h * 2.0), Color(0, 0, 0, 0.22))
	wc.rect(Rect2(p.x - w, p.y - h, w * 2.0, h * 2.0), Color(0.90, 0.89, 0.86))
	wc.rect(Rect2(p.x - w + 3.0, p.y - h + 3.0, (w - 3.0) * 2.0, (h - 3.0) * 2.0), Color(0.96, 0.95, 0.92))
	var cab_y := p.y + dir * (h - 14.0)
	wc.rect(Rect2(p.x - w + 4.0, cab_y - 6.0, (w - 4.0) * 2.0, 12.0), Color(0.24, 0.32, 0.40))
	if waiting and fmod(t * 4.0, 2.0) < 1.0:
		for sx: float in [-w + 3.0, w - 3.0]:
			wc.circle(Vector2(p.x + sx, p.y + dir * (h - 2.0)), 3.2, Color(1.0, 0.72, 0.14))
