class_name FreedomGames
extends RefCounted

# The off-leash space's games, the same in every space (yard, lot, clearing,
# plaça, beach): tug-of-war over a free dog's rope toy (systems/rope_tug.gd)
# and, after the fetch round, the frisbee (entities/frisbee.gd). The agility
# course (systems/agility.gd) stands in El Barri only (AGILITY_WALKS). Static functions over main's state, like the
# other split-out systems; main keeps the state and the forwarders.
#
# None of it runs under the autowalk: the rope is never offered, the frisbee
# never thrown, and the course only watches.

const EventFeed := preload("res://hud/event_feed.gd")
const Frisbee := preload("res://entities/frisbee.gd")
const PigeonGameScript := preload("res://systems/pigeon_game.gd")
const WaveGameScript := preload("res://systems/wave_game.gd")
const SquirrelGameScript := preload("res://systems/squirrel_game.gd")
const GamesLayer := preload("res://world/games_layer.gd")

const HOP_S := 0.36           # a jump's hang time
const HOP_H := 15.0           # ...and its height
const AGILITY_BEST_BONES := 5
const TUG_BONES := 6
const AIR_BONES := 4
const GROUND_BONES := 1
const CARRY_S := 3.0          # how long she parades a won rope before dropping it
const ROPE_BACK_S := 10.0     # before the other dog goes to fetch it back
const GRAB_R := 24.0          # her mouth to the rope's free end


# The agility course stands only in El Barri's dog park, the one place to set
# a best time; every other off-leash area is tug-of-war and frisbee.
const AGILITY_WALKS: Array[String] = ["barri"]


static func has_agility(m: Node2D) -> bool:
	return m.lvl in AGILITY_WALKS


# At level build, before the props: the course decides where they may stand.
static func plan(m: Node2D) -> void:
	m.agility = AgilityCourse.for_space(m.freedom_kind, m.GATE_Y) if has_agility(m) else null


# On entering the space.
static func begin(m: Node2D) -> void:
	if m.agility == null:
		plan(m)
	if m.agility != null:
		m.agility.running = false
	if m.games_ground == null:
		m.games_ground = GamesLayer.new()
		m.games_ground.setup(m, false)
		m.games_ground.z_index = 7
		m.add_child(m.games_ground)
		m.games_cover = GamesLayer.new()
		m.games_cover.setup(m, true)
		m.games_cover.z_index = 12
		m.add_child(m.games_cover)
	m.games_ground.visible = true
	m.games_cover.visible = true
	m.games_cover.refresh()
	m.agility_prev = m.dog.global_position
	m.tug = null
	# a plaça's own game: the pigeons (the autowalk never plays)
	if m.pigeon_game != null:
		m.pigeon_game.clear()
	m.pigeon_game = PigeonGameScript.new(int(m.GATE_Y) ^ 0xC0105) if m.freedom_kind == "placa" and not m.auto_walk else null
	# the dog beach's: the waves
	m.wave_game = WaveGameScript.new() if m.freedom_kind == "beach" and not m.auto_walk else null
	# the woodland clearing's: a squirrel to tree
	if m.squirrel_game != null:
		m.squirrel_game.clear()
	m.squirrel_game = null
	if m.freedom_kind == "clearing" and not m.auto_walk:
		m.squirrel_game = SquirrelGameScript.new(int(m.GATE_Y) ^ 0x5017)
		m.squirrel_game.attach(m)
	m.rope_loose = Vector2(INF, INF)
	m.rope_carry_t = 0.0
	m.frisbee_done = false
	m.frisbee_air = 0
	# one of the free dogs has the rope (the autowalk never meets it)
	m.tug_dog = null
	if not m.auto_walk:
		for fd in m.get_tree().get_nodes_in_group("freedogs"):
			if not fd.is_queued_for_deletion():
				fd.rope = true
				m.tug_dog = fd
				break


# --at-freedom with --shot-tug starts a tug on the spot, and --shot-carry=rope
# or ball puts that in her mouth, so how a held toy is drawn can be
# photographed without playing up to it.
static func shot_setup(m: Node2D) -> void:
	var args := OS.get_cmdline_user_args()
	var fd: Node2D = m.tug_dog
	for a: String in args:
		if a.begins_with("--shot-dog-at="):
			var xy := a.substr(14).split(",")
			m.dog.global_position = Vector2(float(xy[0]), float(xy[1]))
	if "--shot-tug" in args and is_instance_valid(fd):
		fd.global_position = m.dog.global_position + Vector2(-70.0, 22.0)
		m.tug = RopeTug.new(m.dog.global_position, fd.global_position)
		m.tug_prev = m.dog.global_position
		m.tug_phase_was = m.tug.phase
		_face_the_toy(m, fd)
		fd.state = fd.S.TUG
		fd.face = (m.dog.global_position - fd.global_position).normalized()
		m.dog_carrying = true
	for a: String in args:
		if a == "--shot-carry=rope":
			if is_instance_valid(fd):
				fd.rope = false
			m.dog_carrying = true
			m.rope_carry_t = 999.0
		elif a == "--shot-carry=ball" and is_instance_valid(m.ball):
			m.ball.state = m.ball.State.CARRIED
			m.dog_carrying = true


# On leaving it.
static func end(m: Node2D) -> void:
	if m.tug != null:
		_end_tug(m, "")
	if m.pigeon_game != null:
		m.pigeon_game.clear()
		m.pigeon_game = null
	m.wave_game = null
	if m.squirrel_game != null:
		m.squirrel_game.clear()
		m.squirrel_game = null
	if is_instance_valid(m.frisbee):
		m.frisbee.queue_free()
	m.frisbee = null
	m.tug_dog = null
	m.rope_loose = Vector2(INF, INF)
	if m.agility != null:
		m.agility.running = false
	if m.games_ground != null:
		m.games_ground.visible = false
		m.games_cover.visible = false
	m.dog.hop = 0.0
	m.dog.face_lock = Vector2.ZERO


# Every frame in the space, after the dog has moved.
static func tick(m: Node2D, delta: float) -> void:
	_tick_agility(m, delta)
	_tick_tug(m, delta)
	_tick_frisbee(m)
	if m.pigeon_game != null:
		m.pigeon_game.tick(m, delta)
	if m.squirrel_game != null:
		m.squirrel_game.tick(m, delta)
	_tick_waves(m, delta)
	m.hop_t = maxf(0.0, m.hop_t - delta)
	m.dog.hop = sin(PI * (1.0 - m.hop_t / HOP_S)) * HOP_H if m.hop_t > 0.0 else 0.0


# --- the waves (the dog beach) ------------------------------------------------

static func _tick_waves(m: Node2D, delta: float) -> void:
	var wg: WaveGame = m.wave_game
	if wg == null or wg.done:
		return
	var p: Vector2 = m.dog.global_position
	for ev: Array in wg.step(p.x - m.beach_shore_x(p.y), delta):
		match String(ev[0]):
			"outran":
				var pay: int = ev[1]
				m.bones += pay
				m.combo.add("WAVES", pay)
				m.float_text(p, I18n.t("w_outran_it") % pay, Color(0.85, 1.0, 0.85))
				if int(ev[2]) > 1:
					m.feed.say(I18n.t("w_dry_in_a_row") % int(ev[2]), EventFeed.Tone.GOOD)
				Sfx.play("whoop", 1.3, -10.0)
			"soaked":
				m.float_text(p, I18n.t("w_sploosh"), Color(0.75, 0.9, 1.0))
				m.feed.say(I18n.t("w_soaked_2"), EventFeed.Tone.PLAIN)
				Sfx.play("splash", 1.0)
			"done":
				m.feed.say(I18n.t("w_the_sea_wins_in_the_end"), EventFeed.Tone.PLAIN)


# --- agility ------------------------------------------------------------------

static func _tick_agility(m: Node2D, delta: float) -> void:
	if m.agility == null:
		return
	var a: Vector2 = m.agility_prev
	var b: Vector2 = m.dog.global_position
	m.agility_prev = b
	if m.tug != null:
		return
	m.agility.can_start = not m.dog_carrying
	for ev: Array in m.agility.step(a, b, delta, m.dog.planted):
		match String(ev[0]):
			"start":
				# a pop, not a shout: she may only have been passing (the
				# banner's clock says the rest)
				m.float_text(b, I18n.t("w_go"), Color(0.8, 1.0, 0.8))
				Sfx.play("ui", 1.4)
			"jump":
				m.hop_t = HOP_S
				m.float_text(b, I18n.t("w_hup_2"), Color(1, 1, 1))
			"pole":
				if ev[1]:
					Sfx.play("ui", 1.6, -14.0)
				else:
					m.float_text(b, I18n.t("w_missed_a_pole_s") % int(AgilityCourse.FAULT_S), Color(1, 0.7, 0.6))
			"table_count":
				m.float_text(b, "%d..." % int(ev[1]), Color(1, 1, 1), m.POP_SAY)
				Sfx.play("count", 1.0)
			"table_done":
				m.float_text(b, I18n.t("w_3_go"), Color(0.8, 1.0, 0.8), m.POP_SAY)
				Sfx.play("go", 1.0)
			"tunnel_out":
				if ev[1]:
					m.float_text(b, I18n.t("w_whoosh"), Color(0.8, 0.9, 1.0))
			"finish":
				_agility_finish(m, float(ev[1]), int(ev[2]), String(ev[3]))
			"quit":
				# a run that never got going was not one
				if m.agility.t > 2.0:
					m.float_text(b, I18n.t("w_or_not"), Color(0.9, 0.9, 0.9), m.POP_SAY)


static func _agility_finish(m: Node2D, secs: float, faults: int, medal := "") -> void:
	var best: float = Game.agility_best
	var reward := AgilityCourse.medal_bones(medal)
	var line := I18n.t("w_agility_secs") % secs
	if medal != "":
		line = I18n.t("w_medal_secs") % [I18n.of_english(medal), secs]
	if faults == 0:
		line += "  " + I18n.t("w_agility_clean")
	if best <= 0.0 or secs < best:
		Game.agility_best = secs
		Game.save_records()
		if best > 0.0:
			reward += AGILITY_BEST_BONES
			line += "  " + I18n.t("w_agility_new_best")
	m.bones += reward
	m.agility_runs += 1
	m.combo.add("AGILITY", reward)
	m.feed.say(line, EventFeed.Tone.GOOD)
	m.float_text(m.dog.global_position, I18n.t("w_word_score") % [I18n.of_english(medal).to_lower() if medal != "" else I18n.t("w_agility"), reward], Color(0.85, 1.0, 0.85))
	Sfx.play("star" if medal != "" else "combo")


# --- tug-of-war ---------------------------------------------------------------

static func _tick_tug(m: Node2D, delta: float) -> void:
	var fd: Node2D = m.tug_dog
	if not is_instance_valid(fd):
		# no one at the other end: nothing holds her facing
		m.dog.face_lock = Vector2.ZERO
		return
	var mouth: Vector2 = m.dog.global_position + m.dog.facing * 22.0
	if m.tug == null:
		# a won rope, paraded and then dropped where she stands
		if m.rope_carry_t > 0.0:
			m.rope_carry_t -= delta
			if m.rope_carry_t <= 0.0:
				m.dog_carrying = false
				# where the other dog can get to it (free dogs keep to a box)
				m.rope_loose = mouth.clamp(Vector2(100.0, m.freedom_lo + 50.0), Vector2(1180.0, m.GATE_Y - 40.0))
				fd.offer_cd = ROPE_BACK_S
				m.games_cover.refresh()
		# the other dog picks a dropped rope back up
		if m.rope_loose.x < INF and fd.global_position.distance_to(m.rope_loose) < 20.0:
			fd.rope = true
			fd.offer_cd = 5.0
			fd._go_wander(1.0)      # got it: no sniffing the spot it lay on
			m.rope_loose = Vector2(INF, INF)
			m.games_cover.refresh()
		# grabbing the free end starts it (not mid agility run; most walks have
		# no course at all)
		if fd.rope and not m.dog_carrying and (m.agility == null or not m.agility.running) \
				and mouth.distance_to(fd.rope_end()) < GRAB_R:
			m.tug = RopeTug.new(m.dog.global_position, fd.global_position)
			m.tug_prev = m.dog.global_position
			m.tug_phase_was = m.tug.phase
			_face_the_toy(m, fd)
			fd.state = fd.S.TUG
			m.dog_carrying = true
			m.feed.say(I18n.t("w_tug_of_war"), EventFeed.Tone.PLAIN)
			Sfx.play("grunt", 1.3)
		return
	# her own running counts for only a part while she hauls
	var prev: Vector2 = m.tug_prev
	var me: Vector2 = prev + (m.dog.global_position - prev) * RopeTug.MY_SPEED
	var out: Array = m.tug.step(me, fd.global_position, m.dog.input_dir, m.dog.planted,
		m.dog.turbo_active, delta)
	var r: Rect2 = m._freedom_rect()
	# moved, not placed: a tree or the fence stops her being dragged into it
	m.dog.move_and_collide((out[0] as Vector2).clamp(r.position, r.end) - m.dog.global_position)
	fd.global_position = (out[1] as Vector2).clamp(r.position, r.end)
	m.tug_prev = m.dog.global_position
	_face_the_toy(m, fd)
	var tug: RopeTug = m.tug
	if tug.phase != m.tug_phase_was:
		match tug.phase:
			RopeTug.P.WIND:
				Sfx.play("snort", 0.7, -10.0)
			RopeTug.P.HEAVE:
				Sfx.play("grunt", 0.9, -8.0)
		m.tug_phase_was = tug.phase
	if tug.yank:
		Sfx.play("grunt", 1.5, -6.0)
	if String(out[2]) != "":
		_end_tug(m, String(out[2]))


# All through a tug she faces the other dog along the rope, so pushing away
# from it backs her up, rump first, instead of turning her round to run.
static func _face_the_toy(m: Node2D, fd: Node2D) -> void:
	var to_toy: Vector2 = fd.global_position - m.dog.global_position
	if to_toy.length() > 1.0:
		m.dog.face_lock = to_toy.normalized()
		m.dog.facing = m.dog.face_lock


static func _end_tug(m: Node2D, result: String) -> void:
	var fd: Node2D = m.tug_dog
	m.tug = null
	m.dog.face_lock = Vector2.ZERO
	m.dog_carrying = false
	if not is_instance_valid(fd):
		return
	fd._go_wander(1.5)
	match result:
		"won":
			fd.rope = false
			m.dog_carrying = true
			m.rope_carry_t = CARRY_S
			m.bones += TUG_BONES
			m.tugs_won += 1
			m.combo.add("TUG", TUG_BONES)
			m.feed.say(I18n.t("w_tug_won_it_s_yours"), EventFeed.Tone.GOOD)
			m.float_text(m.dog.global_position, I18n.t("w_tug") % TUG_BONES, Color(0.85, 1.0, 0.85))
			Sfx.play("combo")
		"lost":
			fd.offer_cd = 8.0
			fd.vel = (fd.global_position - m.dog.global_position).normalized() * 170.0
			m.feed.say(I18n.t("w_it_got_away_with_it"), EventFeed.Tone.PLAIN)
		"draw":
			fd.offer_cd = 6.0
			m.feed.say(I18n.t("w_stalemate_both_let_go"), EventFeed.Tone.PLAIN)


# --- the frisbee ----------------------------------------------------------------

static func _tick_frisbee(m: Node2D) -> void:
	if m.auto_walk or m.frisbee_done or is_instance_valid(m.frisbee) or not m.romp_done:
		return
	# the ball comes in first: not while it is in her mouth
	if is_instance_valid(m.ball):
		if m.ball.is_carried():
			return
		m.ball.queue_free()
		m.ball = null
	var f: Node2D = Frisbee.new()
	f.z_index = 10
	m.add_child(f)
	f.setup(m, m.dog, m.human, m._freedom_rect(), int(m.GATE_Y) ^ 0xF15B)
	m.frisbee = f


static func on_frisbee_caught(m: Node2D, air: bool) -> void:
	if air:
		m.frisbee_air += 1
		# a streak of air catches pays more each time; a leap pays more again
		var streak: int = maxi(1, m.frisbee.streak) if is_instance_valid(m.frisbee) else 1
		var leap: bool = is_instance_valid(m.frisbee) and m.frisbee.leapt
		var pay := AIR_BONES + 2 * (streak - 1) + (2 if leap else 0)
		var word := I18n.t("w_leap_catch_word") if leap else I18n.t("w_air_catch_word")
		m.bones += pay
		m.combo.add("AIR CATCH", pay)
		if leap:
			m.hop_t = HOP_S
		var shout := I18n.t("w_leap_catch") if leap else I18n.t("w_air_catch")
		if streak > 1:
			shout += "  " + I18n.t("w_x_in_a_row") % streak
		m.feed.say(shout, EventFeed.Tone.GOOD)
		m.float_text(m.dog.global_position, I18n.t("w_word_score") % [word, pay], Color(0.85, 1.0, 0.85))
		Sfx.play("star", 1.2 + 0.08 * float(mini(streak, 5)))
	else:
		m.bones += GROUND_BONES
		m.float_text(m.dog.global_position, I18n.t("w_got_it_4") % GROUND_BONES, Color(0.9, 0.95, 0.9))


static func on_frisbee_returned(m: Node2D, left: int) -> void:
	Sfx.play("fetch")
	if left <= 0:
		m.frisbee_done = true
		m.feed.say(I18n.t("w_frisbee_done_in_the_air") % [m.frisbee_air, Frisbee.THROWS],
			EventFeed.Tone.GOOD if m.frisbee_air > 0 else EventFeed.Tone.PLAIN)


# --- the banner -----------------------------------------------------------------

# What the banner says while a game is on, or "" for none.
static func banner(m: Node2D) -> String:
	if m.tug != null:
		# the meter over the two of them says who is winning; the banner says
		# what to do about the other dog's rhythm right now
		if m.tug.phase == RopeTug.P.REST:
			return I18n.t("fg_tired")
		return Prompts.fill(I18n.t("fg_hold"))
	if m.agility != null and m.agility.running:
		return I18n.t("fg_agility") % [m.agility.t, _next_name(m.agility)]
	if is_instance_valid(m.frisbee):
		if m.frisbee.in_air():
			return I18n.t("fg_leap")
		if m.frisbee.is_carried():
			return I18n.t("fg_frisbee_back")
		return I18n.t("fg_frisbee_left") % m.frisbee.throws_left
	if m.rope_carry_t > 0.0:
		return I18n.t("fg_show")
	if m.wave_game != null and not m.wave_game.done \
			and m.dog.global_position.x - m.beach_shore_x(m.dog.global_position.y) < 320.0:
		return I18n.t("fg_wave")
	if m.pigeon_game != null and m.pigeon_game.active() \
			and m.dog.global_position.distance_to(m.pigeon_game.at) < 360.0:
		return Prompts.fill(I18n.t("fg_pigeons"))
	if m.squirrel_game != null and m.squirrel_game.banner(m) != "":
		return m.squirrel_game.banner(m)
	var fd: Node2D = m.tug_dog
	if is_instance_valid(fd) and fd.rope and fd.state == fd.S.OFFER \
			and fd.global_position.distance_to(m.dog.global_position) < 160.0:
		return I18n.t("fg_rope")
	return ""


static func _next_name(ag: AgilityCourse) -> String:
	var p := ag.next_part()
	if p.is_empty():
		return I18n.t("fg_finish")
	match int(p["kind"]):
		AgilityCourse.E.JUMP: return I18n.t("fg_jump")
		AgilityCourse.E.WEAVE: return I18n.t("fg_weave")
		AgilityCourse.E.TABLE: return Prompts.fill(I18n.t("fg_table"))
		AgilityCourse.E.TUNNEL: return I18n.t("fg_tunnel")
	return I18n.t("fg_finish")


# the rotating hints after fetch: what there still is to play
static func hints(m: Node2D) -> Array[String]:
	var out: Array[String] = []
	if m.agility != null:
		if Game.agility_best > 0.0:
			out.append(I18n.t("fg_hint_best") % Game.agility_best)
		else:
			out.append(I18n.t("fg_hint_run"))
	var fd: Node2D = m.tug_dog
	if is_instance_valid(fd) and fd.rope:
		out.append(I18n.t("fg_hint_tug"))
	return out


# --- drawing ------------------------------------------------------------------

# a cotton rope toy, as sold in any pet shop: natural cotton twisted with
# one dyed strand, a little grubby from use, a knot at each end
const Clay := preload("res://entities/clay.gd")
const ROPE_A := Color(0.33, 0.47, 0.60)   # the dyed strand, washed-out denim
const ROPE_B := Color(0.89, 0.85, 0.75)   # natural cotton
const ROPE_GROOVE := Color(0.50, 0.45, 0.37, 0.75)
const ROPE_INK := Color(0.16, 0.13, 0.11, 0.85)
const ROPE_SEGS := 8
const ROPE_R := 2.1           # half its thickness
const TWIST := 3.0            # px along the rope per strand crossing
const KNOT_R := 4.0           # the knot's half width
const ROPE_TAIL := 7.0        # how far a gripped end shows past the jaw


# a rope from a to b, sagging `bend` px sideways at its middle; a knot at
# either end that is a real end (a dog's mouth hides the rest)
static func draw_rope(c: ShapeBatch, a: Vector2, b: Vector2, bend := 0.0,
		knot_a := true, knot_b := true, mid_band := false) -> void:
	var d := b - a
	if d.length() < 1.0:
		return
	var nrm := (d / d.length()).orthogonal()
	var pts := PackedVector2Array()
	for i in range(ROPE_SEGS + 1):
		var u := float(i) / float(ROPE_SEGS)
		pts.append(a.lerp(b, u) + nrm * bend * 4.0 * u * (1.0 - u))
	draw_rope_path(c, pts, knot_a, knot_b, mid_band)


static func draw_rope_path(c: ShapeBatch, pts: PackedVector2Array, knot_a := true,
		knot_b := true, mid_band := false) -> void:
	var n := pts.size()
	if n < 2:
		return
	for i in range(n - 1):
		c.capsule(pts[i], pts[i + 1], ROPE_R + 0.8, ROPE_INK)
	for i in range(n - 1):
		c.capsule(pts[i], pts[i + 1], ROPE_R, ROPE_B)
	var total := 0.0
	for i in range(n - 1):
		total += pts[i].distance_to(pts[i + 1])
	# the lay: every strand crossing slants the same way down the rope, every
	# third one the dyed strand, with the shade on the side away from the light
	var walked := 0.0
	var next := TWIST * 0.5
	var lay := 0
	for i in range(n - 1):
		var p0: Vector2 = pts[i]
		var p1: Vector2 = pts[i + 1]
		var seg := p0.distance_to(p1)
		if seg < 0.01:
			continue
		var tdir := (p1 - p0) / seg
		var sn := tdir.orthogonal()
		var lit := 1.0 if sn.dot(Clay.LIGHT) < 0.0 else -1.0
		c.line(p0 - sn * lit * ROPE_R * 0.55, p1 - sn * lit * ROPE_R * 0.55, Color(0.62, 0.56, 0.46, 0.55), ROPE_R * 0.8)
		while next < walked + seg:
			var at := p0 + tdir * (next - walked)
			var from := at - sn * ROPE_R * 0.95 - tdir * 1.3
			var to := at + sn * ROPE_R * 0.95 + tdir * 1.3
			var mid := mid_band and absf(next - total * 0.5) < TWIST * 1.6
			if mid or lay % 3 == 0:
				c.line(from, to, ROPE_A, 1.5)
			else:
				c.line(from, to, ROPE_GROOVE, 0.6)
			next += TWIST
			lay += 1
		c.line(p0 + sn * lit * ROPE_R * 0.5, p1 + sn * lit * ROPE_R * 0.5, Color(1.0, 0.98, 0.92, 0.35), 0.6)
		walked += seg
	if knot_a:
		draw_knot(c, pts[0], (pts[0] - pts[1]).normalized())
	if knot_b:
		draw_knot(c, pts[n - 1], (pts[n - 1] - pts[n - 2]).normalized())


# an overhand knot at a rope's end, `out` pointing off the end: a fat wrap
# with the dyed strand round it and the frayed cotton tassel past it
static func draw_knot(c: ShapeBatch, at: Vector2, out: Vector2) -> void:
	var side := out.orthogonal()
	var k := at + out * 1.5
	for f in range(5):
		var spread := (float(f) - 2.0) * 0.32
		var tip := k + out.rotated(spread) * (KNOT_R + 3.2 + float(f % 2) * 1.3)
		c.line(k, tip, ROPE_INK, 1.5)
		c.line(k, tip - out * 0.4, ROPE_B.darkened(0.04), 0.9)
	c.capsule(k - out * 1.6, k + out * 1.0, KNOT_R + 0.8, ROPE_INK)
	c.capsule(k - out * 1.6, k + out * 1.0, KNOT_R, ROPE_B)
	for s2: float in [-1.0, 0.0, 1.0]:
		var w := k + out * s2 * 1.6
		c.line(w - side * KNOT_R * 0.9 - out * 0.9, w + side * KNOT_R * 0.9 + out * 0.9,
			ROPE_A if s2 == 0.0 else ROPE_GROOVE, 1.4 if s2 == 0.0 else 0.6)
	c.circle(k - side * 1.4 - Clay.LIGHT * 0.8, 1.1, Color(1.0, 0.98, 0.92, 0.55))


# What a dog's mouth holds, drawn in her own space between her head and her
# muzzle, so the muzzle closes over it: `bite` is the middle of her jaws,
# `jaw` their half width. In a tug the rope runs in from the front (drawn by
# the games layer under her) and its knotted end pokes out of the corner of
# her mouth on side `sd`.
static func draw_rope_bite(c: ShapeBatch, bite: Vector2, fwd: Vector2, side: Vector2,
		jaw: float, sd: float) -> void:
	var out := (side * sd * 1.0 - fwd * 0.35).normalized()
	var pts := PackedVector2Array([bite + fwd * 2.0, bite, bite + out * (jaw + 1.0),
		bite + out * (jaw + ROPE_TAIL)])
	draw_rope_path(c, pts, false, true)


# a rope carried on its own: across her jaws, both knotted ends out either side
static func draw_rope_carried(c: ShapeBatch, bite: Vector2, fwd: Vector2, side: Vector2,
		jaw: float) -> void:
	var reach := jaw + ROPE_TAIL + 3.0
	var pts := PackedVector2Array([
		bite + side * reach - fwd * 5.0,
		bite + side * (jaw + 1.0) - fwd * 0.6,
		bite,
		bite - side * (jaw + 1.0) - fwd * 0.6,
		bite - side * reach - fwd * 6.5,
	])
	draw_rope_path(c, pts, true, true)
