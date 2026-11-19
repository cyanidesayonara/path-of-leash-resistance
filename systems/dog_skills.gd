extends RefCounted

# Each dog's signature skill, and the skill goal it opens on every walk: one
# more row under the walk's goals, for that dog only, never counted toward the
# walk's stars, so the campaign is as fair with one dog as another. The first
# time a dog meets her skill goal on a walk it is a training point for her
# (Game.record_skill), spent on her stats in the wardrobe like a buried find's.
#
#   Millie, the nose: sniff out and dig up a buried find (systems/buried_finds.gd)
#   Pipa, the sprint: run flat out, well past her own top speed, without a break
#   Mochi, the plant: dig in as the leash yanks, so your human stumbles
#   Bruna, the herd: lead your human across the path on a steady pull
#   Tito, the squeeze: slip through gaps a bigger dog's body would not fit
#   Perla, the dig: dig things up (buried finds, a yard's dig patches), in
#     half the time anyone else takes
#   Duna, the leap: run into a bench and clear it in a standing jump
#
# What each one measures lives on main (skill_*), counted here or where the
# thing happens (a stumble in human.gd, a dig in buried_finds.gd).

const EventFeed := preload("res://hud/event_feed.gd")

const GOALS := {
	"millie": {"id": "skill_nose", "text": "Sniff out and dig up a buried find", "target": 1},
	"pipa": {"id": "skill_sprint", "text": "Sprint flat out for %d seconds", "target": 2},
	"mochi": {"id": "skill_dig_in", "text": "Dig in and trip your human %d times", "target": 2},
	"bruna": {"id": "skill_herd", "text": "Herd your human for %d seconds", "target": 5},
	"tito": {"id": "skill_squeeze", "text": "Slip through %d gaps only you fit", "target": 3},
	"perla": {"id": "skill_dig", "text": "Dig up %d holes", "target": 2},
	"duna": {"id": "skill_leap", "text": "Leap %d benches", "target": 2},
}

# Pipa: flat out is this much past her own top speed (turbo is TURBO_MULT)
const SPRINT_OVER := 1.35
# Bruna: a pull this share of the human's full give, sideways, is herding
const HERD_PULL := 0.45
# Tito: how often she is checked for a squeeze, the gap a normal dog's body
# needs (entities/dog.gd BODY_RADIUS), and how far she must go before
# another squeeze counts
const SQUEEZE_EVERY := 0.12
const SQUEEZE_APART := 90.0
# two contacts this close to opposite sides of her are a gap, not a wall
const SQUEEZE_OPPOSED := -0.6


static func goal_for(d: String) -> Dictionary:
	return GOALS.get(d, {})


# The walk's skill goal for the dog she is, or {} (the tutorial has none).
static func build(m: Node2D) -> void:
	m.skill_quest = {}
	if bool(m.tutorial_mode):
		return
	var g := goal_for(Game.dog)
	if g.is_empty():
		return
	m.skill_quest = {"id": String(g.id), "text": String(g.text), "target": int(g.target)}


# what she has done toward it this walk
static func progress(m: Node2D) -> int:
	match Game.dog:
		"millie": return int(m.finds_dug)
		"pipa": return int(floor(float(m.skill_sprint_best) + 0.001))
		"mochi": return int(m.skill_stumbles)
		"bruna": return int(floor(float(m.skill_herd_t) + 0.001))
		"tito": return int(m.skill_squeezes)
		"perla": return int(m.finds_dug) + int(m.digs_done)
		"duna": return int(m.skill_leaps)
	return 0


static func tick(m: Node2D, delta: float) -> void:
	if (m.skill_quest as Dictionary).is_empty():
		return
	if Game.dog == "tito" and not bool(m.skill_gaps_scanned):
		# her gaps are found a few rows a frame once the walk's solids are
		# known: as many as the walk has, up to her target; none, and she
		# has no skill goal here
		if not scan_gaps(m, int(GOALS.tito.target), SCAN_ROWS_PER_TICK):
			return
		m.skill_gaps_scanned = true
		var n: int = (m.skill_scan_spots as Array).size()
		if n == 0:
			m.skill_quest = {}
			return
		m.skill_quest.target = n
	match Game.dog:
		"pipa": _tick_sprint(m, delta)
		"bruna": _tick_herd(m, delta)
		"tito": _tick_squeeze(m, delta)
	if Game.dog_leaps():
		tick_leap(m, delta)
	if not bool(m.skill_done_run) and progress(m) >= int(m.skill_quest.target):
		credit(m)


static func _tick_sprint(m: Node2D, delta: float) -> void:
	var dog: Node = m.dog
	var flat_out: bool = bool(dog.turbo_active) and (dog.velocity as Vector2).length() >= float(dog.base_speed()) * SPRINT_OVER
	m.skill_sprint_t = float(m.skill_sprint_t) + delta if flat_out else 0.0
	m.skill_sprint_best = maxf(float(m.skill_sprint_best), float(m.skill_sprint_t))


static func _tick_herd(m: Node2D, delta: float) -> void:
	var h: Node = m.human
	# leading, not dragging: he is walking on and giving way across the path
	if int(h.state) != int(h.HState.WALK) and int(h.state) != int(h.HState.DRIFT):
		return
	var lat: float = absf((h.felt_pull as Vector2).x) / float(h.GIVE_FULL)
	if lat >= HERD_PULL:
		m.skill_herd_t = float(m.skill_herd_t) + delta


static func _tick_squeeze(m: Node2D, delta: float) -> void:
	m.skill_squeeze_t = float(m.skill_squeeze_t) - delta
	if float(m.skill_squeeze_t) > 0.0:
		return
	m.skill_squeeze_t = SQUEEZE_EVERY
	var dog: CharacterBody2D = m.dog
	if (dog.velocity as Vector2).length() < 40.0:
		return
	var at: Vector2 = dog.global_position
	if (m.skill_squeeze_at as Vector2).distance_to(at) < SQUEEZE_APART:
		return
	if squeezed(dog):
		m.skill_squeezes = int(m.skill_squeezes) + 1
		m.skill_squeeze_at = at
		m.float_text(at + Vector2(0, -26), I18n.t("skill_squeeze_pop"), Color(0.7, 0.95, 1.0), m.POP_SAY)


# Tito's gaps along the walk, up to `want` of them SQUEEZE_APART apart: a
# coarse scan of the path, once per walk.
const SCAN_ROW := 36.0
const SCAN_COL := 10.0
const SCAN_MARGIN := 60.0
const SCAN_ROWS_PER_TICK := 2           # about 2.5 ms a frame, done within the first seconds


static func count_gaps(m: Node2D, want: int) -> int:
	m.skill_scan_y = INF
	m.skill_scan_spots = []
	while not scan_gaps(m, want, 1000):
		pass
	return (m.skill_scan_spots as Array).size()


# `rows` more rows of the scan, carried on main (skill_scan_y, skill_scan_spots).
# Says whether it is finished.
static func scan_gaps(m: Node2D, want: int, rows: int) -> bool:
	var spots: Array = m.skill_scan_spots
	var y: float = float(m.skill_scan_y)
	if y == INF:
		y = float(m.START_Y) - 200.0
	for r in range(rows):
		if y <= float(m.GATE_Y) + 200.0 or spots.size() >= want:
			m.skill_scan_y = y
			return true
		var e: Vector2 = m.walk_edges(y)
		var x: float = e.x - SCAN_MARGIN
		while x < e.y + SCAN_MARGIN and spots.size() < want:
			var p := Vector2(x, y)
			var apart := true
			for q: Vector2 in spots:
				apart = apart and q.distance_to(p) >= SQUEEZE_APART
			if apart and squeezed(m.dog, p):
				spots.append(p)
			x += SCAN_COL
		y -= SCAN_ROW
	m.skill_scan_y = y
	return y <= float(m.GATE_Y) + 200.0 or spots.size() >= want


# Whether a normal-sized dog's body, where she stands, would touch solid
# things on two opposite sides of her: a gap only a small dog fits.
static func squeezed(dog: CharacterBody2D, at := Vector2.INF) -> bool:
	if at == Vector2.INF:
		at = dog.global_position
	var normal: float = float(dog.BODY_RADIUS)
	if float(dog.collision_radius()) >= normal - 0.5:
		return false
	var shape := CircleShape2D.new()
	shape.radius = normal
	var q := PhysicsShapeQueryParameters2D.new()
	q.shape = shape
	q.transform = Transform2D(0.0, at)
	q.collision_mask = dog.collision_mask
	q.exclude = [dog.get_rid()]
	var pts: Array = dog.get_world_2d().direct_space_state.collide_shape(q, 16)
	# collide_shape gives pairs; the second of each is on the other body
	var dirs: Array[Vector2] = []
	for i in range(1, pts.size(), 2):
		var v: Vector2 = (pts[i] as Vector2) - at
		if v.length() > 0.5:
			dirs.append(v.normalized())
	for i in range(dirs.size()):
		for j in range(i + 1, dirs.size()):
			if dirs[i].dot(dirs[j]) <= SQUEEZE_OPPOSED:
				return true
	return false


static func credit(m: Node2D) -> void:
	m.skill_done_run = true
	var text := quest_text(m.skill_quest)
	var newly := Game.record_skill(String(m.lvl), Game.dog)
	if newly:
		m.feed.toast("goal", I18n.t("toast_skill") % Game.dog_name().to_upper(), text, Color(0.55, 0.95, 0.9))
		m.float_text(m.dog.global_position + Vector2(0, -34), I18n.t("find_score"), Color(0.55, 0.95, 0.9))
	else:
		m.feed.toast("goal", I18n.t("toast_goal_again"), text, Color(0.58, 0.78, 0.62))
	Sfx.play("star", 1.1)
	m._update_hud()


static func quest_text(q: Dictionary) -> String:
	var s := I18n.of_english(String(q.text))
	if "%d" in s:
		s = s % int(q.target)
	return s.substr(0, 1).to_upper() + s.substr(1)


# The skill goal's row for the goals card: under the walk's own goals, its
# own colour, ticked once she has it on this walk.
static func card_row(m: Node2D, UiIcons: GDScript) -> Dictionary:
	var q: Dictionary = m.skill_quest
	if q.is_empty():
		return {}
	var target := int(q.target)
	var had := Game.skill_done(String(m.lvl), Game.dog)
	var hit: bool = bool(m.skill_done_run)
	var got := target if (had or hit) else mini(progress(m), target)
	var state: int = UiIcons.Check.DONE_NOW if hit else (UiIcons.Check.DONE_BEFORE if had else (UiIcons.Check.PARTIAL if got > 0 else UiIcons.Check.OPEN))
	return {"text": quest_text(q), "target": target, "got": got, "state": state, "skill": true}


# Duna's standing jump. Running into a bench, she goes over it: the bench
# lets her through for LEAP_S while she arcs up and over (her hop, drawn by
# entities/dog.gd), carried across at least LEAP_SPEED. Only a bench, only on
# the walk (the off-leash games have their own hops).
const LEAP_S := 0.42
const LEAP_SPEED := 260.0
const LEAP_H := 14.0
const LEAP_MIN_SPEED := 90.0       # how hard she must be going into it
const LEAP_REST := 0.35            # after landing, before another leap


static func tick_leap(m: Node2D, delta: float) -> void:
	var dog: CharacterBody2D = m.dog
	if float(m.leap_t) > 0.0:
		m.leap_t = maxf(0.0, float(m.leap_t) - delta)
		var u := 1.0 - float(m.leap_t) / LEAP_S
		dog.hop = sin(PI * u) * LEAP_H
		if (dog.velocity as Vector2).dot(m.leap_dir) < LEAP_SPEED:
			dog.velocity = (m.leap_dir as Vector2) * LEAP_SPEED
		if float(m.leap_t) <= 0.0:
			dog.hop = 0.0
			if is_instance_valid(m.leap_body):
				dog.remove_collision_exception_with(m.leap_body)
			m.leap_body = null
			m.leap_cd = LEAP_REST
		return
	if float(m.leap_cd) > 0.0:
		m.leap_cd = maxf(0.0, float(m.leap_cd) - delta)
		return
	if String(m.phase) == "freedom" or dog.velocity.length() < LEAP_MIN_SPEED and not bool(dog.input_active):
		return
	var body := bench_hit(m)
	if body == null:
		return
	m.leap_body = body
	m.leap_t = LEAP_S
	var across: Vector2 = body.global_position - dog.global_position
	m.leap_dir = across.normalized() if across.length() > 0.5 else Vector2.UP
	dog.add_collision_exception_with(body)
	m.skill_leaps = int(m.skill_leaps) + 1
	m.float_text(dog.global_position + Vector2(0, -26), I18n.t("skill_leap_pop"), Color(1.0, 0.86, 0.5), m.POP_SAY)
	Sfx.play("whoop", 1.15)


# The bench she ran into this frame, or null: what she collided with as she
# moved, if it is one of the walk's benches.
static func bench_hit(m: Node2D) -> StaticBody2D:
	var dog: CharacterBody2D = m.dog
	for i in range(dog.get_slide_collision_count()):
		var c := dog.get_slide_collision(i)
		var b := c.get_collider() as StaticBody2D
		if b == null:
			continue
		for bn: Vector2 in m.benches:
			if b.global_position.distance_to(bn) < 2.0:
				return b
	return null
