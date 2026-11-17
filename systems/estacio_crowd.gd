class_name EstacioCrowd
extends RefCounted

# L'Estacio's train-call commuter waves: when a departure is called, the
# departure boards flash and a PA chime sounds 1.2 s before a wave of
# commuters surges through the concourse and ticket barriers.

const ShapeBatch := preload("res://systems/shape_batch.gd")

enum State { IDLE, TELEGRAPH, SURGING }

const WARN_DURATION := 1.2
const SURGE_DURATION := 5.5
const COOLDOWN_FIRST := 3.5
const COOLDOWN_NEXT := 11.0
const WAVE_COUNT := 12
const BUMP_RADIUS := 24.0
const THREAT_RADIUS := 68.0
const BARK_RADIUS := 170.0

const COATS: Array[Color] = [
	Color(0.20, 0.26, 0.38),
	Color(0.46, 0.24, 0.20),
	Color(0.26, 0.34, 0.28),
	Color(0.32, 0.30, 0.34),
	Color(0.54, 0.42, 0.22),
]
const SKINS: Array[Color] = [
	Color(0.92, 0.78, 0.68),
	Color(0.82, 0.64, 0.50),
	Color(0.62, 0.44, 0.32),
]
const HAIRS: Array[Color] = [
	Color(0.16, 0.14, 0.13),
	Color(0.38, 0.26, 0.18),
	Color(0.66, 0.56, 0.42),
	Color(0.54, 0.56, 0.60),
]
const CASE_COLS: Array[Color] = [
	Color(0.20, 0.44, 0.78),
	Color(0.78, 0.22, 0.24),
	Color(0.88, 0.68, 0.18),
	Color(0.24, 0.26, 0.30),
]

const VALID_ROWS: Array[int] = [0, 2, 3, 4]

var state: State = State.IDLE
var timer: float = COOLDOWN_FIRST
var wave_idx: int = 0
var called_row: int = 0
var boarding: bool = true
var commuters: Array[Dictionary] = []
var human_hit: bool = false
var threatened: bool = false
var dodged: bool = false
var barked: bool = false
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	_rng.seed = 0xE57AC10


func reset() -> void:
	state = State.IDLE
	timer = COOLDOWN_FIRST
	wave_idx = 0
	called_row = 0
	boarding = true
	commuters.clear()
	human_hit = false
	threatened = false
	dodged = false
	barked = false


func is_telegraphing() -> bool:
	return state == State.TELEGRAPH


func is_active() -> bool:
	return state == State.TELEGRAPH or state == State.SURGING


func tick(delta: float, human_pos: Vector2, walk_edges_fn: Callable, walkway: Rect2, cafe: Rect2, train: Rect2, barrier_y: float, gaps: Array[float]) -> Dictionary:
	var out := {
		"warn": false,
		"surge": false,
		"bump": false,
		"bump_dir": Vector2.ZERO,
		"dodge": false,
		"row": called_row,
		"boarding": boarding,
	}

	match state:
		State.IDLE:
			if human_pos.y < -450.0 and human_pos.y > -4650.0:
				timer -= delta
				if timer <= 0.0:
					called_row = VALID_ROWS[wave_idx % VALID_ROWS.size()]
					boarding = (wave_idx % 2 == 0)
					wave_idx += 1
					state = State.TELEGRAPH
					timer = WARN_DURATION
					human_hit = false
					threatened = false
					dodged = false
					barked = false
					out["warn"] = true
					out["row"] = called_row
					out["boarding"] = boarding

		State.TELEGRAPH:
			timer -= delta
			if timer <= 0.0:
				state = State.SURGING
				timer = SURGE_DURATION
				_spawn_wave(human_pos, walk_edges_fn, walkway, cafe, train)
				out["surge"] = true

		State.SURGING:
			timer -= delta
			var close := false
			for c: Dictionary in commuters:
				_step_commuter(c, delta, walk_edges_fn, walkway, cafe, train, barrier_y, gaps)
				var d: float = (c["pos"] as Vector2).distance_to(human_pos)
				if d < THREAT_RADIUS:
					close = true
				if not human_hit and d < BUMP_RADIUS:
					human_hit = true
					out["bump"] = true
					var dir: Vector2 = human_pos - (c["pos"] as Vector2)
					out["bump_dir"] = dir.normalized() if dir.length_squared() > 0.01 else Vector2(1.0, 0.0)
			var step := NearMiss.consider(close, human_hit, threatened, dodged)
			threatened = bool(step["threatened"])
			if bool(step["dodge"]):
				dodged = true
				out["dodge"] = true
			if timer <= 0.0:
				state = State.IDLE
				timer = COOLDOWN_NEXT
				commuters.clear()

	return out


func on_bark(dog_pos: Vector2) -> bool:
	if barked or state != State.SURGING:
		return false
	var near := false
	for c: Dictionary in commuters:
		if (c["pos"] as Vector2).distance_to(dog_pos) < BARK_RADIUS:
			near = true
			var away: Vector2 = (c["pos"] as Vector2) - dog_pos
			c["side_push"] = (1.0 if away.x >= 0.0 else -1.0) * 44.0
	if near:
		barked = true
		return true
	return false


func _spawn_wave(human_pos: Vector2, walk_edges_fn: Callable, walkway: Rect2, cafe: Rect2, train: Rect2) -> void:
	commuters.clear()
	var base_y := clampf(human_pos.y + (340.0 if boarding else -340.0), -4620.0, -450.0)
	for i in range(WAVE_COUNT):
		var sy := base_y + _rng.randf_range(-90.0, 90.0)
		var e: Vector2 = walk_edges_fn.call(sy)
		var sx := _pick_clear_x(e, sy, walkway, cafe, train)
		var spd := _rng.randf_range(125.0, 162.0) * (-1.0 if boarding else 1.0)
		commuters.append({
			"pos": Vector2(sx, sy),
			"vy": spd,
			"vx": 0.0,
			"side_push": 0.0,
			"coat": COATS[_rng.randi() % COATS.size()],
			"skin": SKINS[_rng.randi() % SKINS.size()],
			"hair": HAIRS[_rng.randi() % HAIRS.size()],
			"has_case": _rng.randf() < 0.55,
			"case_col": CASE_COLS[_rng.randi() % CASE_COLS.size()],
			"phase": _rng.randf_range(0.0, TAU),
		})


func _pick_clear_x(e: Vector2, y: float, walkway: Rect2, cafe: Rect2, train: Rect2) -> float:
	for _try in range(10):
		var x := _rng.randf_range(e.x + 36.0, e.y - 36.0)
		var p := Vector2(x, y)
		if walkway.grow(14.0).has_point(p):
			continue
		if cafe.grow(18.0).has_point(p):
			continue
		if train.grow(18.0).has_point(p):
			continue
		return x
	return e.x + 70.0


func _step_commuter(c: Dictionary, delta: float, walk_edges_fn: Callable, walkway: Rect2, cafe: Rect2, train: Rect2, barrier_y: float, gaps: Array[float]) -> void:
	var p: Vector2 = c["pos"]
	var vy: float = float(c["vy"])
	var target_vx := 0.0

	# Steer through the nearest ticket barrier gap when approaching the barrier line
	if absf(p.y - barrier_y) < 160.0:
		var best_g := gaps[0]
		var best_d := absf(p.x - best_g)
		for g: float in gaps:
			var dg := absf(p.x - g)
			if dg < best_d:
				best_d = dg
				best_g = g
		target_vx += clampf((best_g - p.x) * 3.0, -180.0, 180.0)
		if absf(p.y - barrier_y) < 28.0 and best_d > 22.0:
			vy = 0.0

	# Steer clear of the moving walkway, cafe counter, and train
	var ahead := p + Vector2(0.0, signf(vy) * 26.0)
	target_vx += _steer_rect(ahead, walkway.grow(12.0))
	target_vx += _steer_rect(ahead, cafe.grow(16.0))
	target_vx += _steer_rect(ahead, train.grow(16.0))

	var push: float = float(c["side_push"])
	if absf(push) > 0.5:
		target_vx += push
		c["side_push"] = lerpf(push, 0.0, minf(1.0, delta * 3.0))

	p.x += target_vx * delta
	p.y += vy * delta
	var e: Vector2 = walk_edges_fn.call(p.y)
	p.x = clampf(p.x, e.x + 24.0, e.y - 24.0)
	c["pos"] = p
	c["vx"] = target_vx
	c["phase"] = float(c["phase"]) + delta * 9.0


static func _steer_rect(ahead: Vector2, obs: Rect2) -> float:
	if not obs.has_point(ahead):
		return 0.0
	return 120.0 if ahead.x >= obs.get_center().x else -120.0


func draw(m: Node2D, b: ShapeBatch, vt: float, vb: float) -> void:
	if state != State.SURGING or commuters.is_empty():
		return
	var dir_y := -1.0 if boarding else 1.0
	for c: Dictionary in commuters:
		var p: Vector2 = c["pos"]
		if p.y < vt - 40.0 or p.y > vb + 40.0:
			continue
		var ph: float = float(c["phase"])
		var swing := sin(ph) * 3.2
		var coat: Color = c["coat"]
		var skin: Color = c["skin"]
		var hair: Color = c["hair"]

		# Rolling suitcase trailing behind
		if bool(c["has_case"]):
			var cp := p + Vector2(8.0, -dir_y * 14.0)
			b.rect(Rect2(cp - Vector2(5.0, 7.0) + Shade.light * 3.0, Vector2(10.0, 14.0)), Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.18))
			b.rect(Rect2(cp - Vector2(5.0, 7.0), Vector2(10.0, 14.0)), c["case_col"])
			b.line(p + Vector2(5.0, 0.0), cp, Color(0.24, 0.24, 0.28), 1.4)

		# Shadow
		b.circle(p + Shade.light * 4.0, 9.0, Color(m.SHADOW_COL.r, m.SHADOW_COL.g, m.SHADOW_COL.b, 0.20))
		# Shoulders / coat
		b.rect(Rect2(p.x - 9.0, p.y - 5.0 + swing * 0.2, 18.0, 10.0), coat)
		# Swinging arms
		b.circle(p + Vector2(-9.0, dir_y * swing), 3.0, coat.darkened(0.12))
		b.circle(p + Vector2(9.0, -dir_y * swing), 3.0, coat.darkened(0.12))
		# Head & hair
		b.circle(p, 5.5, skin)
		b.circle(p + Vector2(0.0, -dir_y * 1.4), 5.2, hair)
