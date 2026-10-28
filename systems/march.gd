class_name March
extends RefCounted

# La Marxa, the away column (docs/superpowers/specs/2026-10-17-dia-de-partit-design.md).
# One rect on the east carriageway, walking south. It is a keep-out the human
# already knows how to step around, and a carry if they walk into it. The
# horses are bodies. They are not rope contacts.

const COL_W := 150.0
const COL_L := 360.0
const SPEED := 55.0
const WARN_T := 4.0
const EAST_X := 760.0
const LINE_Y := -3280.0
const HORSE_R := 18.0
const HORSE_X: Array[float] = [760.0, 830.0, 900.0, 970.0]

var on := false
var passed := false
var caught := false
var warned := false
var home_line := false
var banner := ""
var foot := Rect2()
var horses: Array[Vector2] = []
var droppings: Array[Dictionary] = []
var shifting := -1
var _keep_i := -1
var _drop_in := 1.6
var _drum_in := 0.0
var _whoa_in := 0.0
var _shift_in := 2.4
var _shift_arm := -1.0
var _bodies: Array[StaticBody2D] = []


func arm(at: Vector2) -> void:
	on = true
	warned = false
	banner = ""
	# the south edge starts WARN_T plus a couple of seconds north of the pair,
	# so the siren is heard before the column arrives
	var south := at.y - SPEED * (WARN_T + 2.0)
	foot = Rect2(EAST_X, south - COL_L, COL_W, COL_L)
	horses = _corners()


# true on the frame the siren starts. gap is how far the south edge still
# is north of the pair; warning at SPEED * WARN_T is four seconds out.
func advance(dt: float, pair: Vector2) -> bool:
	if not on:
		return false
	foot.position.y += SPEED * dt
	horses = _corners()
	var gap := pair.y - foot.end.y
	var just := false
	if not warned and gap <= SPEED * WARN_T and gap > 0.0:
		warned = true
		banner = "AWAY FANS! GET YOUR HUMAN CLEAR"
		just = true
	if foot.position.y > pair.y + 40.0:
		on = false
		passed = true
		banner = ""
	return just


func holds_bot(p: Vector2) -> bool:
	if not on:
		return false
	if p.x < foot.position.x - 24.0:
		return false
	return foot.end.y < p.y + 40.0


func tick(m: Node2D, dt: float) -> void:
	_whoa_in = maxf(0.0, _whoa_in - dt)
	if m.phase == "home":
		on = false
		banner = ""
		_clear_keep(m)
		if m.match_crowd != null:
			m.match_crowd.clear_east = 0.0
		_stand_home(m, dt)
		return
	if m.phase != "out":
		return
	if not on and not passed and m.human.global_position.y < -2100.0 and m.human.global_position.y > -3600.0:
		arm(m.human.global_position)
		_bodies_at(m)
	if not on:
		_clear_keep(m)
		if m.match_crowd != null:
			m.match_crowd.clear_east = 0.0
		return
	if advance(dt, m.human.global_position):
		Sfx.play("whoop", 0.9, -4.0)
	_bodies_at(m)
	_keep(m)
	if m.match_crowd != null:
		m.match_crowd.clear_east = foot.position.x if on else 0.0
	if on and warned:
		_drum_in -= dt
		if _drum_in <= 0.0:
			_drum_in = 0.55
			Sfx.play("drum", 0.7, -8.0)
	_carry(m, dt)
	_horses_hit(m)
	_drop(m, dt)
	_sniff(m)
	if not on:
		_clear_keep(m)
		if m.match_crowd != null:
			m.match_crowd.clear_east = 0.0


func draw(b: ShapeBatch) -> void:
	if on:
		var bike := Vector2(foot.get_center().x, foot.end.y + 28.0)
		b.circle(bike + Vector2(2.0, 4.0), 10.0, Color(0, 0, 0, 0.2))
		b.rect(Rect2(bike.x - 7.0, bike.y - 16.0, 14.0, 28.0), Color(0.12, 0.13, 0.16))
		var blink := 0.55 + 0.45 * sin(AnimClock.msec() * 0.02)
		b.circle(bike + Vector2(0.0, -18.0), 4.0, Color(0.25, 0.55, 1.0, blink))
		for i in 6:
			var p := Vector2(foot.position.x + 28.0 + float(i % 3) * 42.0, foot.position.y + 50.0 + float(i / 3) * 80.0)
			b.coarse(p, 7.0, Color(0.92, 0.50, 0.16) if i % 2 == 0 else Color(0.36, 0.40, 0.46))
	for i in horses.size():
		_horse(b, horses[i], i == shifting)


func _corners() -> Array[Vector2]:
	return [
		Vector2(foot.position.x + 16.0, foot.position.y + 20.0),
		Vector2(foot.end.x - 16.0, foot.position.y + 20.0),
		Vector2(foot.position.x + 16.0, foot.end.y - 20.0),
		Vector2(foot.end.x - 16.0, foot.end.y - 20.0),
	]


func _keep(m: Node2D) -> void:
	if _keep_i < 0 or _keep_i >= m.owner_keepouts.size():
		m.owner_keepouts.append(foot)
		_keep_i = m.owner_keepouts.size() - 1
	else:
		m.owner_keepouts[_keep_i] = foot


func _clear_keep(m: Node2D) -> void:
	if _keep_i >= 0 and _keep_i < m.owner_keepouts.size():
		m.owner_keepouts[_keep_i] = Rect2(-4000.0, -4000.0, 1.0, 1.0)


func _carry(m: Node2D, dt: float) -> void:
	var h: CharacterBody2D = m.human
	if not foot.has_point(h.global_position):
		return
	caught = true
	if h.is_whirling() or h.is_fallen():
		return
	h.march_t = 0.2
	h.patience = maxf(0.0, h.patience - dt * 0.12)
	if _whoa_in <= 0.0:
		_whoa_in = 1.4
		m.float_text(h.global_position, "Whoa, whoa, whoa!", Color(1, 1, 1), m.POP_SAY)


func _horses_hit(m: Node2D) -> void:
	for p: Vector2 in horses:
		if m.human.global_position.distance_to(p) < HORSE_R + 14.0 and not m.auto_walk:
			m.human.fall("horse")
		if m.dog.global_position.distance_to(p) < HORSE_R + 10.0:
			m.dog.knocked(Vector2(0.0, 1.0), "horse")


func _drop(m: Node2D, dt: float) -> void:
	_drop_in -= dt
	if _drop_in > 0.0:
		return
	_drop_in = 1.6
	var at := horses[0] + Vector2(0.0, -24.0)
	droppings.append({"pos": at, "sniffed": false})
	m.substance_zones.append({"rect": Rect2(at - Vector2(14.0, 10.0), Vector2(28.0, 20.0)), "kind": "stinky", "slow": true})


func _sniff(m: Node2D) -> void:
	for d: Dictionary in droppings:
		if bool(d["sniffed"]):
			continue
		if m.dog.global_position.distance_to(d["pos"]) < 26.0 and m.dog.velocity.length() < 70.0:
			d["sniffed"] = true
			m.sniffs_done += 1
			m.bones += 4
			Sfx.play("mark", 1.1)
			m.float_text(d["pos"], "what a sniff +4", Color(0.85, 0.7, 0.4))


func _stand_home(m: Node2D, dt: float) -> void:
	if not home_line and m.human.global_position.y < -3000.0:
		home_line = true
		on = false
		banner = ""
		horses.clear()
		for x: float in HORSE_X:
			horses.append(Vector2(x, LINE_Y))
		_bodies_at(m)
		if not m.prize_taken:
			m.prize_pos = horses[1] + Vector2(0.0, 26.0)
			m.prize_text = "snatch the sausage from under the police horses"
	if not home_line:
		return
	_shift_in -= dt
	if _shift_arm < 0.0 and _shift_in <= 0.0:
		_shift_arm = 0.8
		shifting = 1
		Sfx.play("snort", 0.8, -6.0)
	if _shift_arm >= 0.0:
		_shift_arm -= dt
		if _shift_arm <= 0.0:
			_shift_arm = -1.0
			shifting = -1
			_shift_in = 3.2
			var p: Vector2 = horses[1]
			if m.dog.global_position.distance_to(p) < 36.0:
				m.dog.knocked(Vector2(1.0, 0.0), "horse")


func _bodies_at(m: Node2D) -> void:
	while _bodies.size() < horses.size():
		var sb := StaticBody2D.new()
		sb.collision_layer = 1
		var cs := CollisionShape2D.new()
		var sh := CircleShape2D.new()
		sh.radius = HORSE_R
		cs.shape = sh
		sb.add_child(cs)
		m.add_child(sb)
		_bodies.append(sb)
	for i in _bodies.size():
		if i < horses.size():
			_bodies[i].global_position = horses[i]
			_bodies[i].visible = false


func _horse(b: ShapeBatch, p: Vector2, swish: bool) -> void:
	b.circle(p + Vector2(3.0, 5.0), 16.0, Color(0, 0, 0, 0.18))
	b.coarse(p, 14.0, Color(0.42, 0.28, 0.16))
	b.coarse(p + Vector2(0.0, -8.0), 5.0, Color(0.36, 0.24, 0.14))
	b.coarse(p + Vector2(-2.0, -16.0), 5.5, Color(0.12, 0.16, 0.28))
	var tail := Vector2(-16.0, 6.0) if not swish else Vector2(-8.0, -12.0)
	b.line(p, p + tail, Color(0.20, 0.12, 0.08), 2.2)
