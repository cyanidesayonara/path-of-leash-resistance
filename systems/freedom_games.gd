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
const GamesLayer := preload("res://world/games_layer.gd")

const HOP_S := 0.36           # a jump's hang time
const HOP_H := 15.0           # ...and its height
const AGILITY_BONES := 5
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


# On leaving it.
static func end(m: Node2D) -> void:
	if m.tug != null:
		_end_tug(m, "")
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
	m.hop_t = maxf(0.0, m.hop_t - delta)
	m.dog.hop = sin(PI * (1.0 - m.hop_t / HOP_S)) * HOP_H if m.hop_t > 0.0 else 0.0


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
	for ev: Array in m.agility.step(a, b, delta):
		match String(ev[0]):
			"start":
				# a pop, not a shout: she may only have been passing (the
				# banner's clock says the rest)
				m.float_text(b, "Go!", Color(0.8, 1.0, 0.8))
				Sfx.play("ui", 1.4)
			"jump":
				m.hop_t = HOP_S
				m.float_text(b, "hup!", Color(1, 1, 1))
			"pole":
				if not ev[1]:
					m.float_text(b, "missed a pole! +%ds" % int(AgilityCourse.FAULT_S), Color(1, 0.7, 0.6))
			"tunnel_out":
				if ev[1]:
					m.float_text(b, "whoosh", Color(0.8, 0.9, 1.0))
			"finish":
				_agility_finish(m, float(ev[1]), int(ev[2]))
			"quit":
				# a run that never got going was not one
				if m.agility.t > 2.0:
					m.float_text(b, "...Or not.", Color(0.9, 0.9, 0.9), m.POP_SAY)


static func _agility_finish(m: Node2D, secs: float, faults: int) -> void:
	var best: float = Game.agility_best
	var reward := AGILITY_BONES
	var line := "AGILITY %.1fS" % secs
	if faults == 0:
		line += "  CLEAN!"
	if best <= 0.0 or secs < best:
		Game.agility_best = secs
		Game.save_records()
		if best > 0.0:
			reward += AGILITY_BEST_BONES
			line += "  NEW BEST"
	m.bones += reward
	m.agility_runs += 1
	m.combo.add("AGILITY", reward)
	m.feed.say(line, EventFeed.Tone.GOOD)
	m.float_text(m.dog.global_position, "agility! +%d" % reward, Color(0.85, 1.0, 0.85))
	Sfx.play("star")


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
			m.feed.say("TUG OF WAR!", EventFeed.Tone.PLAIN)
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
			m.feed.say("TUG WON! IT'S YOURS", EventFeed.Tone.GOOD)
			m.float_text(m.dog.global_position, "tug! +%d" % TUG_BONES, Color(0.85, 1.0, 0.85))
			Sfx.play("combo")
		"lost":
			fd.offer_cd = 8.0
			fd.vel = (fd.global_position - m.dog.global_position).normalized() * 170.0
			m.feed.say("IT GOT AWAY WITH IT", EventFeed.Tone.PLAIN)
		"draw":
			fd.offer_cd = 6.0
			m.feed.say("STALEMATE. BOTH LET GO", EventFeed.Tone.PLAIN)


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
		m.bones += AIR_BONES
		m.combo.add("AIR CATCH", AIR_BONES)
		m.feed.say("AIR CATCH!", EventFeed.Tone.GOOD)
		m.float_text(m.dog.global_position, "air catch! +%d" % AIR_BONES, Color(0.85, 1.0, 0.85))
		Sfx.play("star", 1.2)
	else:
		m.bones += GROUND_BONES
		m.float_text(m.dog.global_position, "got it +%d" % GROUND_BONES, Color(0.9, 0.95, 0.9))


static func on_frisbee_returned(m: Node2D, left: int) -> void:
	Sfx.play("fetch")
	if left <= 0:
		m.frisbee_done = true
		m.feed.say("FRISBEE DONE  %d/%d IN THE AIR" % [m.frisbee_air, Frisbee.THROWS],
			EventFeed.Tone.GOOD if m.frisbee_air > 0 else EventFeed.Tone.PLAIN)


# --- the banner -----------------------------------------------------------------

# What the banner says while a game is on, or "" for none.
static func banner(m: Node2D) -> String:
	if m.tug != null:
		# the meter over the two of them says who is winning; the banner says
		# what to do about the other dog's rhythm right now
		if m.tug.phase == RopeTug.P.REST:
			return "IT'S TIRED! PULL AWAY NOW"
		return Prompts.fill("HOLD ON! {plant} DIG IN")
	if m.agility != null and m.agility.running:
		return "AGILITY  %.1fS  %s" % [m.agility.t, _next_name(m.agility)]
	if is_instance_valid(m.frisbee):
		if m.frisbee.in_air():
			return "CATCH IT IN THE AIR!"
		if m.frisbee.is_carried():
			return "FRISBEE! BRING IT BACK"
		return "FRISBEE!  %d TO GO" % m.frisbee.throws_left
	if m.rope_carry_t > 0.0:
		return "SHOW IT OFF"
	var fd: Node2D = m.tug_dog
	if is_instance_valid(fd) and fd.rope and fd.state == fd.S.OFFER \
			and fd.global_position.distance_to(m.dog.global_position) < 160.0:
		return "A ROPE! GRAB THE END"
	return ""


static func _next_name(ag: AgilityCourse) -> String:
	for p: Dictionary in ag.parts:
		if not p["done"]:
			match int(p["kind"]):
				AgilityCourse.E.JUMP: return "JUMP!"
				AgilityCourse.E.WEAVE: return "WEAVE THE POLES"
				AgilityCourse.E.TUNNEL: return "THROUGH THE TUNNEL"
	return "TO THE FINISH!"


# the rotating hints after fetch: what there still is to play
static func hints(m: Node2D) -> Array[String]:
	var out: Array[String] = []
	if m.agility != null:
		if Game.agility_best > 0.0:
			out.append("AGILITY BEST %.1fS. BEAT IT AT THE GREEN FLAGS" % Game.agility_best)
		else:
			out.append("RUN THE AGILITY COURSE FROM THE GREEN FLAGS")
	var fd: Node2D = m.tug_dog
	if is_instance_valid(fd) and fd.rope:
		out.append("SOMEONE HAS A ROPE. TUG OF WAR?")
	return out


# --- drawing ------------------------------------------------------------------

# a cotton rope toy, as sold in any pet shop: natural cotton twisted with
# one dyed strand, a little grubby from use
const ROPE_A := Color(0.33, 0.47, 0.60)   # the dyed strand, washed-out denim
const ROPE_B := Color(0.89, 0.85, 0.75)   # natural cotton
const ROPE_GROOVE := Color(0.55, 0.50, 0.42, 0.55)


# the rope toy, from `a` to `b`: a stiff braided cord, two strands twisted
# round each other, a fat knot at each end. `bend` bows it sideways at the
# middle (RopeTug.bend), as a stiff rope bows: one smooth arc, never a kink.
const ROPE_SEGS := 8
const ROPE_R := 3.4           # half its thickness
const TWIST := 5.5            # px along the rope per strand crossing


static func draw_rope(c: ShapeBatch, a: Vector2, b: Vector2, bend := 0.0) -> void:
	var d := b - a
	var length := d.length()
	if length < 1.0:
		return
	var along := d / length
	var nrm := along.orthogonal()
	var ink := Color(0.16, 0.13, 0.11)
	var pts: Array[Vector2] = [a]
	for i in range(1, ROPE_SEGS + 1):
		var u := float(i) / float(ROPE_SEGS)
		pts.append(a.lerp(b, u) + nrm * bend * 4.0 * u * (1.0 - u))
	for i in range(ROPE_SEGS):
		c.capsule(pts[i], pts[i + 1], ROPE_R + 1.1, ink)
	for i in range(ROPE_SEGS):
		c.capsule(pts[i], pts[i + 1], ROPE_R, ROPE_B)
	# the twist: every other lay is the dyed strand, a fine groove between
	var walked := 0.0
	var next := TWIST * 0.5
	var lay := 0
	for i in range(ROPE_SEGS):
		var p0: Vector2 = pts[i]
		var p1: Vector2 = pts[i + 1]
		var seg := p0.distance_to(p1)
		if seg < 0.01:
			continue
		var tdir := (p1 - p0) / seg
		var sn := tdir.orthogonal()
		while next < walked + seg:
			var at := p0 + tdir * (next - walked)
			var from := at - sn * ROPE_R * 0.9 - tdir * 1.8
			var to := at + sn * ROPE_R * 0.9 + tdir * 1.8
			if lay % 2 == 0:
				c.line(from, to, ROPE_A, 2.6)
			c.line(from + tdir * 1.6, to + tdir * 1.6, ROPE_GROOVE, 0.8)
			next += TWIST * 0.5
			lay += 1
		walked += seg
	# the knots: a chunky wrap, the dyed strand round it, and the frayed
	# cotton tail sticking out past it
	for e in range(2):
		var end: Vector2 = a if e == 0 else b
		var out := -along if e == 0 else along
		for f in range(4):
			var spread := (float(f) - 1.5) * 0.42
			var tip := end + out.rotated(spread * 0.7) * (ROPE_R + 4.0 + float(f % 2) * 1.2)
			c.line(end, tip, Color(ink.r, ink.g, ink.b, 0.6), 2.0)
			c.line(end, tip - out * 0.5, ROPE_B.darkened(0.05), 1.3)
		c.circle(end, ROPE_R + 2.4, ink)
		c.circle(end, ROPE_R + 1.3, ROPE_B)
		for k2: float in [-1.0, 1.0]:
			var mid := end + along * k2 * 1.7
			c.line(mid - nrm * (ROPE_R + 0.9), mid + nrm * (ROPE_R + 0.9), ROPE_A, 1.5)
		c.circle(end - nrm * 1.3 - along * 1.0, 1.2, Color(1.0, 0.98, 0.92, 0.7))
