class_name FreedomGames
extends RefCounted

# The off-leash space's games, the same in every space (yard, lot, clearing,
# plaça, beach): the agility course (systems/agility.gd), tug-of-war over a
# free dog's rope toy (systems/rope_tug.gd) and, after the fetch round, the
# frisbee (entities/frisbee.gd). Static functions over main's state, like the
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


# At level build, before the props: the course decides where they may stand.
static func plan(m: Node2D) -> void:
	m.agility = AgilityCourse.for_space(m.freedom_kind, m.GATE_Y)


# On entering the space.
static func begin(m: Node2D) -> void:
	if m.agility == null:
		plan(m)
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


# Every frame in the space, after the dog has moved.
static func tick(m: Node2D, delta: float) -> void:
	_tick_agility(m, delta)
	_tick_tug(m, delta)
	_tick_frisbee(m)
	m.hop_t = maxf(0.0, m.hop_t - delta)
	m.dog.hop = sin(PI * (1.0 - m.hop_t / HOP_S)) * HOP_H if m.hop_t > 0.0 else 0.0


# --- agility ------------------------------------------------------------------

static func _tick_agility(m: Node2D, delta: float) -> void:
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
				m.float_text(b, "go!", Color(0.8, 1.0, 0.8))
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
					m.float_text(b, "...or not", Color(0.9, 0.9, 0.9))


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
		# grabbing the free end starts it
		if fd.rope and not m.dog_carrying and m.agility != null and not m.agility.running \
				and mouth.distance_to(fd.rope_end()) < GRAB_R:
			m.tug = RopeTug.new(m.dog.global_position, fd.global_position)
			m.tug_prev = m.dog.global_position
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
	if String(out[2]) != "":
		_end_tug(m, String(out[2]))


static func _end_tug(m: Node2D, result: String) -> void:
	var fd: Node2D = m.tug_dog
	m.tug = null
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
		var bal: float = m.tug.balance()
		var meter := ""
		for i in range(10):
			meter += "|" if float(i) / 9.0 <= (bal + 1.0) * 0.5 else "."
		return Prompts.fill("TUG! PULL AWAY, {plant} DIG IN  [%s]" % meter)
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
	if Game.agility_best > 0.0:
		out.append("AGILITY BEST %.1fS. BEAT IT AT THE GREEN FLAGS" % Game.agility_best)
	else:
		out.append("RUN THE AGILITY COURSE FROM THE GREEN FLAGS")
	var fd: Node2D = m.tug_dog
	if is_instance_valid(fd) and fd.rope:
		out.append("SOMEONE HAS A ROPE. TUG OF WAR?")
	return out


# --- drawing ------------------------------------------------------------------

const ROPE_A := Color(0.86, 0.3, 0.24)
const ROPE_B := Color(0.95, 0.9, 0.8)


# the rope toy, from `a` to `b`: a twisted two-colour cord, knotted at the ends
static func draw_rope(c: Variant, a: Vector2, b: Vector2) -> void:
	var ink := Color(0.12, 0.1, 0.09)
	c.draw_line(a, b, ink, 5.0)
	var n := maxi(2, int(a.distance_to(b) / 5.0))
	for i in range(n):
		var p0 := a.lerp(b, float(i) / float(n))
		var p1 := a.lerp(b, float(i + 1) / float(n))
		c.draw_line(p0, p1, ROPE_A if i % 2 == 0 else ROPE_B, 3.0)
	c.draw_circle(a, 3.4, ink)
	c.draw_circle(a, 2.4, ROPE_A)
	c.draw_circle(b, 4.2, ink)
	c.draw_circle(b, 3.0, ROPE_A)
