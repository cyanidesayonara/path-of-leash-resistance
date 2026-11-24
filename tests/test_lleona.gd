extends SceneTree

# La Lleona, Girona's statue boss (systems/boss_lleona.gd):
# - Registration: a boss walk that ends its chapter; legs on the rope
# - The wake holds your human, and only while they are short of her
# - Part one: no attack under her title card; the rake and the ripple, hit and
#   dodged, each telegraphed 0.8 s or more
# - Part two: the gaze turns a dog in the open to stone and not one behind the
#   column or a planter (once each); your human is never touched by it; trip,
#   spout, boop, kiss and bowl; from every perch the column's shadow is within
#   the leash's reach of where your human waits
# - Part three: the column, three legs, the slide, the bark; and the same tie
#   with the real rope, both ways round

const DT := 1.0 / 60.0

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	create_timer(120.0).timeout.connect(func():
		print("FAIL: test watchdog timeout")
		quit(1)
	)
	call_deferred("_run")


func _ticks(m: Node2D, secs: float) -> void:
	for i in range(int(ceilf(secs / DT - 0.001))):
		m.elapsed += DT
		m.lleona.tick_state(DT)


func _load_walk() -> Node2D:
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	for k in range(3):
		await physics_frame
	m._skip_title()
	await physics_frame
	m.auto_walk = false
	return m


func _quiet(le) -> void:
	le.rake_cd = 99.0
	le.ripple_cd = 99.0
	le.gaze_cd = 99.0
	le.spout_t = 99.0
	le.spout_pouring = false


# a gaze from a given perch at a dog standing at `at`
func _gaze(m: Node2D, BL: GDScript, perch: Vector2, at: Vector2) -> void:
	var le = m.lleona
	le.pos = perch
	le.state = BL.State.STALK
	_quiet(le)
	m.dog.stone_t = 0.0
	m.dog.global_position = at
	le.transition_to(BL.State.GAZE_WARN)
	_ticks(m, BL.GAZE_WARN + BL.GAZE_SWEEP + 0.1)


func _run() -> void:
	var game = root.get_node("Game")
	game.persist = false
	root.get_node("Sfx").muted = true
	game.level_id = "girona"
	var BL: GDScript = load("res://systems/boss_lleona.gd")
	var Girona: GDScript = load("res://systems/girona.gd")
	var m: Node2D = await _load_walk()
	m.set_physics_process(false)
	m.set_process(false)
	var le = m.lleona

	# 1. Registration
	_check(game.BOSS_WALKS.has("girona"), "girona is a boss walk")
	var ch: Array = game.chapters()[game.chapter_index("girona")]
	_check(String(ch[ch.size() - 1]) == "girona", "girona ends its chapter")
	_check(le != null and le.state == BL.State.IDLE and le.pos == BL.COLUMN, "asleep on her column")
	_check(le.leg_indices.size() == 4 and le.is_leg_index(le.leg_indices[0]), "four legs on the rope")
	_check(Girona.LLEONA_PLINTH == BL.COLUMN_RECT and Girona.LLEONA_COL == BL.COLUMN, "the column she guards is the column drawn")
	for r: Rect2 in BL.PLANTERS:
		_check(Girona.solids(m).has(r), "planter %s is solid" % r)
	for w: float in [BL.RAKE_WARN, BL.RIPPLE_WARN, BL.GAZE_WARN, BL.SPOUT_WARN]:
		_check(w >= 0.8, "telegraphed 0.8 s or more (%.2f)" % w)
	# the column's shadow from each perch, where the dog has to get to
	for p: Vector2 in BL.PERCHES:
		var hide: Vector2 = BL.COLUMN + (BL.COLUMN - p).normalized() * 62.0
		_check(hide.distance_to(Vector2(640.0, BL.HOLD_Y)) < m.LEASH_LENGTH - 30.0, "the hide from %s is in reach" % p)

	# 2. A pair already past her leaves her asleep
	m.human.global_position = Vector2(640.0, BL.HOLD_Y - 400.0)
	m.dog.global_position = Vector2(640.0, BL.HOLD_Y - 500.0)
	_ticks(m, 0.5)
	_check(le.state == BL.State.IDLE, "still asleep with the pair past her")

	# 3. The wake and the hold
	m.human.global_position = Vector2(640.0, BL.HOLD_Y + 180.0)
	m.dog.global_position = Vector2(640.0, BL.WAKE_Y - 30.0)
	_ticks(m, 0.1)
	_check(le.state == BL.State.AWAKEN, "wakes as the dog passes")
	_check(m.human.tut_hold_y == BL.HOLD_Y, "your human is held short of her")
	_check(m.human.tut_hold_x == BL.COLUMN.x, "and on the column's line, so the leash reaches round it")
	_ticks(m, BL.AWAKEN_TIME + 0.1)
	_check(le.state == BL.State.STALK and le.pos.distance_to(BL.LANDING) < 40.0, "down off the column and stalking")

	# 4. The rake
	_quiet(le)
	le.rake_cd = 0.0
	m.dog.tumble_t = 0.0
	le.pos = Vector2(640.0, -3500.0)
	le.face_dir = Vector2.DOWN
	m.dog.global_position = le.pos + Vector2(60.0, 90.0)
	le.card_t = BL.CARD_FROM + 0.5
	_ticks(m, DT * 2.0)
	_check(le.state == BL.State.STALK, "no attack while her card hushes the banner")
	le.card_t = -1.0
	_ticks(m, DT * 2.0)
	_check(le.state == BL.State.RAKE, "close in front: she rakes")
	var hits: int = m.dog_hits
	_ticks(m, BL.RAKE_WARN - 0.1)
	_check(m.dog_hits == hits, "not before the sector has filled")
	_ticks(m, 0.2)
	_check(m.dog_hits == hits + 1, "the rake knocks a dog in its sector")
	_ticks(m, BL.RAKE_STRIKE + 0.1)
	le.state = BL.State.STALK
	le.face_dir = Vector2.DOWN
	m.dog.tumble_t = 0.0
	le.transition_to(BL.State.RAKE)
	m.dog.global_position = le.pos + Vector2(230.0, -20.0)
	var hp0: float = le.hp
	_ticks(m, BL.RAKE_WARN + 0.1)
	_check(m.lleona_dodges == 1 and le.hp < hp0, "a dodged rake wears her down")
	_ticks(m, BL.RAKE_STRIKE + 0.1)

	# 5. The ripple
	for dodge: bool in [false, true]:
		_quiet(le)
		le.state = BL.State.STALK
		le.pos = Vector2(500.0, -3560.0)
		m.dog.tumble_t = 0.0
		m.dog.global_position = Vector2(500.0, -3340.0)
		hits = m.dog_hits
		var d0: int = m.lleona_dodges
		le.transition_to(BL.State.RIPPLE)
		_ticks(m, BL.RIPPLE_WARN - 0.1)
		_check(m.dog_hits == hits, "the ripple waits for its lane")
		if dodge:
			m.dog.global_position = Vector2(600.0, -3400.0)
		_ticks(m, 0.2 + BL.RIPPLE_LEN / BL.RIPPLE_SPEED)
		if dodge:
			_check(m.dog_hits == hits and m.lleona_dodges == d0 + 1, "a sidestepped ripple is a dodge")
		else:
			_check(m.dog_hits == hits + 1, "the ripple knocks a dog in its lane")

	# 6. Part two
	le.state = BL.State.STALK
	_quiet(le)
	le.damage(le.hp - 45.0)
	_ticks(m, DT)
	_check(le.phase == 2 and le.state == BL.State.ENRAGE, "below half she roars")
	_ticks(m, BL.ENRAGE_TIME + 0.1)
	_check(le.state == BL.State.STALK and le.enraged, "then stalks on, furious")
	le.gaze_cd = 0.0
	le.spout_t = 99.0
	m.dog.global_position = Vector2(640.0, -3200.0)
	_ticks(m, DT * 2.0)
	_check(le.state == BL.State.BOUND and le.perch == BL.PERCHES[1], "she bounds to the perch farthest from the dog")
	for p: Vector2 in BL.PERCHES:
		for from: Vector2 in [Vector2(640.0, -3440.0), Vector2(640.0, -3200.0), Vector2(730.0, -3330.0)]:
			le.state = BL.State.STALK
			le.pos = from
			le.transition_to(BL.State.BOUND)
			le.perch = p
			var t := 0.0
			while le.state == BL.State.BOUND and t < 4.0:
				# her way there, not the leash's hold on it
				m.leash.detached = true
				_ticks(m, DT)
				t += DT
			m.leash.detached = false
			_check(le.pos.distance_to(p) < 8.0, "from %s she gets to %s round the column (%s)" % [from, p, le.pos])

	# the gaze on a dog in the open
	le.hp = 100.0
	hits = m.dog_hits
	var hum: Vector2 = m.human.global_position
	_gaze(m, BL, BL.PERCHES[1], Vector2(760.0, -3340.0))
	_check(m.dog_hits == hits + 1 and le.gaze_caught, "seen in the open, the dog is stone")
	_check(le.state == BL.State.STALK and le.hp == 100.0, "and it costs her nothing")
	m.dog.stone_t = 0.5
	m.dog.velocity = Vector2(200.0, 0.0)
	m.dog.tick(DT)
	_check(m.dog.planted and m.dog.velocity == Vector2.ZERO, "a stone dog is rooted")
	m.dog.tick(1.0)
	_check(m.dog.stone_t <= 0.0, "and thaws")
	_check(m.human.global_position == hum and not m.human.is_fallen(), "your human never looks up")

	# behind the column, from every perch
	for p: Vector2 in BL.PERCHES:
		le.hp = 100.0
		hits = m.dog_hits
		var n: int = m.lleona_hides
		_gaze(m, BL, p, BL.COLUMN + (BL.COLUMN - p).normalized() * 62.0)
		_check(m.dog_hits == hits and m.lleona_hides == n + 1, "unseen behind the column from %s" % p)
		_check(le.state == BL.State.SPENT and absf(100.0 - le.hp - BL.HIDE_DAMAGE) < 0.1, "it wears her down and leaves her spent")

	# behind a planter, once
	var pc: Vector2 = BL.PLANTERS[0].get_center()
	var behind: Vector2 = pc + (pc - BL.PERCHES[1]).normalized() * 52.0
	_gaze(m, BL, BL.PERCHES[1], behind)
	_check(le.gaze_hid and not le.planters_up[0], "a planter hides the dog once, then crumbles")
	hits = m.dog_hits
	_gaze(m, BL, BL.PERCHES[1], behind)
	_check(le.gaze_caught and m.dog_hits == hits + 1, "rubble hides nobody")

	# spent: boop and kiss, once each
	le.hp = 100.0
	le.state = BL.State.STALK
	le.pos = Vector2(760.0, -3480.0)
	le.face_dir = Vector2.DOWN
	le.transition_to(BL.State.SPENT)
	m.dog.global_position = le.nose() + Vector2(0.0, 20.0)
	_check(Girona.on_bark(m, m.dog.global_position) and m.lleona_booped, "a bark on her nose while spent is a boop")
	m.dog.global_position = le.rear()
	_ticks(m, DT * 3.0)
	_check(m.lleona_kissed and absf(100.0 - le.hp - BL.BOOP_DAMAGE - BL.KISS_DAMAGE) < 0.1, "a nose at her tail is the kiss, once")
	m.human.global_position = le.pos + Vector2(60.0, 0.0)
	m.human.whirl_flung_t = 0.5
	_ticks(m, DT)
	_check(m.lleona_bowled, "your human flung into her bowls her")
	m.human.whirl_flung_t = 0.0
	m.human.velocity = Vector2.ZERO
	m.human.global_position = hum

	# the spout blinds her only where it pours
	le.hp = 100.0
	le.state = BL.State.STALK
	_quiet(le)
	le.pos = Vector2(500.0, -3500.0)
	m.dog.global_position = Vector2(500.0, -3400.0)
	le.spout_t = 0.01
	_ticks(m, 0.1)
	_check(le.spout_pouring and le.hp == 100.0, "elsewhere, the spout only pours")
	le.pos = BL.SPOUT_AT
	_ticks(m, DT * 2.0)
	_check(m.lleona_blinded and le.state == BL.State.STUNNED, "under it, she is blinded and dazed")
	le.state = BL.State.STALK
	le._hit("trip")
	_check(m.lleona_tripped and le.state == BL.State.STUNNED, "a trip dazes her")

	# 7. Part three
	_quiet(le)
	le.damage(le.hp)
	le.transition_to(BL.State.STALK)
	_check(le.state == BL.State.RETREAT, "out of fight she retreats")
	_ticks(m, 5.0)
	_check(le.state == BL.State.STAND and le.pos == BL.COLUMN, "the last stand, on her column")
	m.dog.global_position = BL.COLUMN + Vector2(0.0, 300.0)
	for k in range(3):
		le.leg_touch_t[k] = m.elapsed
	_ticks(m, DT)
	_check(le.state == BL.State.WRAPPED, "three legs tied: she wobbles")
	_ticks(m, BL.WOBBLE_TIME + 0.1)
	_check(le.state == BL.State.SAT and m.lleona_sat, "and slides down")
	m.dog.global_position = le.nose() + Vector2(0.0, 30.0)
	Girona.on_bark(m, m.dog.global_position)
	_check(le.state == BL.State.CONTENT and m.lleona_settled, "a bark settles her")
	_ticks(m, DT)
	_check(m.human.tut_hold_y != BL.HOLD_Y and m.human.tut_hold_x == INF, "your human may walk on")
	m.queue_free()
	await process_frame

	# 8. The tie, with the real rope
	for cs: Array in [[160.0, 1.0, 135.0], [240.0, -1.0, 105.0]]:
		m = await _load_walk()
		le = m.lleona
		le.hp = 0.0
		le.transition_to(BL.State.STAND)
		m.human.global_position = Vector2(640.0, BL.HOLD_Y + 10.0)
		m.dog.global_position = BL.COLUMN + Vector2(0.0, cs[2])
		m.leash.resnap()
		var ang := PI * 0.5
		var t := 0.0
		while t < 6.0 and le.state == BL.State.STAND:
			le.last_rake_cd = 99.0
			ang += float(cs[1]) * float(cs[0]) / float(cs[2]) / 60.0
			m.dog.global_position = BL.COLUMN + Vector2(cos(ang), sin(ang)) * float(cs[2])
			m.dog.velocity = Vector2(-sin(ang), cos(ang)) * float(cs[0]) * float(cs[1])
			await physics_frame
			t += DT
		_check(le.state == BL.State.WRAPPED, "circling %s ties her (%s after %.1fs)" % [cs, BL.State.keys()[le.state], t])
		m.queue_free()
		await process_frame

	print("test_lleona: %d checks, %d failures" % [checks, failures.size()])
	for f in failures:
		print("  " + f)
	quit(1 if failures.size() > 0 else 0)
