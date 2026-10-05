extends RefCounted

# The chase that can take over the walk home: a street sweeper eating the path
# behind you ("sweeper"), a fast threat the owner bolts from ("bolt"), or both
# at once ("both"). sweeper.gd is the machine itself; this decides whether a
# walk gets a chase, starts it on the home leg, and ends the walk if it
# catches anyone.
#
# Static functions over main's state (chase_active, chase_kind,
# chase_sweeper), which the HUD, the mood wiring and the tests also read.

const CHASE_SPEED := 140.0
const CHASE_SPEED_BOLT := 205.0
const CHASE_SPEED_BOTH := 220.0
const CHASE_START_GAP := 650.0
# the walk the chase lives on (#20): only here does the home leg roll one
const CHASE_LEVEL := "neteja"
# the "outrun" goal: never let the machine closer than this to the dog or
# the human, about a leash length
const OUTRUN_GAP := 150.0
# how long the machine rolls over whoever it caught before the card comes up,
# so being swept is something you SEE happen rather than a cut to a caption
const CATCH_BEAT := 0.75
# CLOSE SHAVE: let the brooms within this of the rearmost of you, then get
# back out past CLOSE_SHAVE_CLEAR without being swept
const CLOSE_SHAVE_GAP := 60.0
const CLOSE_SHAVE_CLEAR := 200.0
const CLOSE_SHAVE_BONES := 2
# The camera leans back up the street, at most this far, to keep the machine
# LEAN_SHOW deep in the top of the screen: the boulder is something you watch
# coming. Never further, or there is no road left to see ahead of the dog.
const LEAN_MAX := 90.0
const LEAN_SHOW := 80.0
const LEAN_RATE := 3.0

const EventFeed := preload("res://hud/event_feed.gd")


# At level start. La Neteja always gets one; any walk can be forced with
# --chase (slow sweeper), --bolt (fast, owner panics) or --rescue (both).
# Then a roll for which kind. It takes over the home leg, so it and the Tofu
# herding are mutually exclusive.
#
# The chase used to roll on a quarter of every walk. It lives on its own walk
# now (#20), but the roll is still made, and ignored elsewhere: the randf()
# calls are part of each walk's seeded sequence (dailies, --seed replays, the
# soak), and dropping one would reshuffle everything drawn after it.
static func roll(m: Node2D) -> void:
	var args := OS.get_cmdline_user_args()
	var chase_forced := "--chase" in args
	var bolt_forced := "--bolt" in args
	var rescue_forced := "--rescue" in args
	var chase_walk: bool = m.lvl == CHASE_LEVEL
	var forced := chase_forced or bolt_forced or rescue_forced
	# the old roll, drawn exactly when it always was
	var rolled: bool = forced or (not m.auto_walk and not Game.daily and randf() < 0.25)
	m.chase_active = (forced or chase_walk) and not m.tutorial_mode
	# ...and so is the kind: whenever the old roll would have started a chase
	if m.chase_active or (rolled and not m.tutorial_mode):
		if m.chase_active:
			m.tofu_quest_active = false
		if bolt_forced:
			m.chase_kind = "bolt"
		elif rescue_forced:
			m.chase_kind = "both"
		elif chase_forced:
			m.chase_kind = "sweeper"
		else:
			var r := randf()
			m.chase_kind = "sweeper" if r < 0.4 else ("bolt" if r < 0.75 else "both")


# On entering the home leg, when this walk rolled a chase.
static func begin(m: Node2D) -> void:
	var owner_flees: bool = m.chase_kind == "bolt" or m.chase_kind == "both"
	var sweeper := Node2D.new()
	sweeper.set_script(load("res://entities/sweeper.gd"))
	sweeper.kind = m.chase_kind
	m.chase_sweeper = sweeper
	m.add_child(sweeper)
	# Behind the living: the brushes reach a little past the kill line, and a
	# machine drawn over the human or the leash (#20) read as a bug, not a
	# threat. Anyone it draws over is already caught - see the catch beat.
	m.move_child(sweeper, mini(m.dog.get_index(), m.human.get_index()))
	m.chase_min_gap = INF
	var spd := CHASE_SPEED
	if m.chase_kind == "bolt":
		spd = CHASE_SPEED_BOLT
	elif m.chase_kind == "both":
		spd = CHASE_SPEED_BOTH
	# --shot-sweeper starts it right on your heels instead of a corridor
	# away, so the machine can be photographed and its art reviewed. It
	# spends the rest of the chase behind the camera, which is exactly how
	# it went unlooked-at long enough to end up as a wall of rectangles.
	var gap: float = 250.0 if "--shot-sweeper" in OS.get_cmdline_user_args() else CHASE_START_GAP
	sweeper.setup(m, m.dog.global_position.y - gap, m.walk_cx, m.walk_half, spd)
	# only the dumpsters still ahead of it: a chase forced on from further
	# down the street must not start stuck on one it never reached
	for j: Vector2 in m.chase_jams:
		if j.y > sweeper.front_y:
			sweeper.jams.append(j)
	sweeper.kerb_blocks = m.chase_kerb_blocks.duplicate()
	m.chase_lean = 0.0
	m.chase_shave_armed = false
	m.shake_t = 1.0
	if owner_flees:
		m.human.panic = true
	if m.chase_kind == "both":
		m.float_text(m.human.global_position, "FIRE ENGINE!  GO GO GO!", Color(1, 0.55, 0.25))
	elif m.chase_kind == "bolt":
		m.float_text(m.human.global_position, "AAH!  the owner BOLTED!", Color(1, 0.6, 0.3))
	else:
		m.feed.say("STREET SWEEPER! RUN!", EventFeed.Tone.BAD)


# Every physics frame of the home leg.
static func tick(m: Node2D, delta: float) -> void:
	var sweeper: Node2D = m.chase_sweeper
	if sweeper == null:
		return
	var rear: float = minf(sweeper.gap_to(m.dog.global_position), sweeper.gap_to(m.human.global_position))
	sweeper.advance(delta, rear, m.dog.global_position.x - m.walk_cx)
	sweeper.global_position = Vector2(m.walk_cx, sweeper.front_y)
	sweeper.queue_redraw()
	if sweeper.jammed_now:
		m.shake_t = maxf(m.shake_t, 0.6)
		Sfx.play("crack", 0.5, -4.0)
		m.float_text(Vector2(m.walk_cx + sweeper.jam_side * (m.walk_half - 40.0), sweeper.front_y), "CLONK", Color(1.0, 0.85, 0.5))
		m.feed.say("IT'S JAMMED!", EventFeed.Tone.GOOD)
	elif sweeper.freed_now:
		Sfx.play("hiss", 0.6, -6.0)
		m.float_text(Vector2(m.walk_cx + sweeper.sway, sweeper.front_y - 60.0), "VRRROOM", Color(1.0, 0.7, 0.4))
	if sweeper.sweep_junk(m.get_tree().get_nodes_in_group("cones")) > 0:
		Sfx.play("tangle", 0.8, -10.0)
	# a low rumble the closer it gets to the dog
	var gap: float = sweeper.gap_to(m.dog.global_position)
	if gap < 260.0:
		m.shake_t = maxf(m.shake_t, 0.25)
	rear = minf(gap, sweeper.gap_to(m.human.global_position))
	m.chase_min_gap = minf(m.chase_min_gap, rear)
	_lean(m, sweeper, delta)
	if m.chase_catch_t > 0.0:
		# the catch beat: the machine keeps rolling over them, then the card
		m.chase_catch_t -= delta
		m.shake_t = maxf(m.shake_t, 0.4)
		if m.chase_catch_t <= 0.0:
			m._death(m.chase_catch_msg, "chase")
		return
	if m.auto_walk:
		return  # the attract/CI bot carries an unsweepable dog
	if rear > 0.0 and rear < CLOSE_SHAVE_GAP:
		m.chase_shave_armed = true
	elif m.chase_shave_armed and rear > CLOSE_SHAVE_CLEAR:
		m.chase_shave_armed = false
		m.bones += CLOSE_SHAVE_BONES
		m.combo.add("CLOSE SHAVE", 6)
		Sfx.play("save", 1.3)
		m.float_text(m.dog.global_position, "close shave! +%d" % CLOSE_SHAVE_BONES, Color(0.75, 0.9, 1.0))
	if sweeper.caught(m.human.global_position):
		if m.chase_kind == "sweeper":
			_catch(m, "THE SWEEPER GOT YOUR HUMAN\n\nThey never once looked up from the phone.\nYou did try to tell them.")
		else:
			_catch(m, "THEY GOT YOUR HUMAN\n\nYou pulled. You barked. It was not enough.")
	elif sweeper.caught(m.dog.global_position):
		if m.chase_kind == "sweeper":
			_catch(m, "YOU WENT INTO THE BRUSHES\n\nYou came out suspiciously clean.\nThe walk did not come out at all.")
		else:
			_catch(m, "NOBODY WAITED FOR YOU\n\nYou snagged, the leash went tight, and\nthey kept walking. They always keep walking.")


# How far the camera leans back up the street this frame: just enough to
# bring the machine's front LEAN_SHOW into the top of the screen, eased.
static func _lean(m: Node2D, sweeper: Node2D, delta: float) -> void:
	var view_half: float = m.get_viewport_rect().size.y * 0.5 / maxf(float(m.cam.zoom.y), 0.01)
	var cam_y: float = (m.dog.global_position.y + m.human.global_position.y) * 0.5 - 60.0
	var need: float = (cam_y - view_half) - (float(sweeper.front_y) - LEAN_SHOW)
	# past twice the most it can lean, leaning shows nothing but a dark road
	var want := clampf(need, 0.0, LEAN_MAX) if need < LEAN_MAX * 2.0 else 0.0
	m.chase_lean = lerpf(float(m.chase_lean), want, 1.0 - exp(-LEAN_RATE * delta))


# Caught: bring the machine to the front so it visibly rolls over them, shout
# it, and hold the card back for CATCH_BEAT.
static func _catch(m: Node2D, msg: String) -> void:
	var sweeper: Node2D = m.chase_sweeper
	sweeper.z_index = 8
	m.chase_catch_t = CATCH_BEAT
	m.chase_catch_msg = msg
	m.shake_t = 1.0
	m.feed.say("SWEPT!", EventFeed.Tone.BAD)
