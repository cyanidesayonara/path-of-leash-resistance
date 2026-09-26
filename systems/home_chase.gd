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
	sweeper.advance(delta)
	sweeper.global_position = Vector2(m.walk_cx, sweeper.front_y)
	sweeper.queue_redraw()
	# a low rumble the closer it gets to the dog
	var gap: float = sweeper.gap_to(m.dog.global_position)
	if gap < 260.0:
		m.shake_t = maxf(m.shake_t, 0.25)
	m.chase_min_gap = minf(m.chase_min_gap, minf(gap, sweeper.gap_to(m.human.global_position)))
	if m.chase_catch_t > 0.0:
		# the catch beat: the machine keeps rolling over them, then the card
		m.chase_catch_t -= delta
		m.shake_t = maxf(m.shake_t, 0.4)
		if m.chase_catch_t <= 0.0:
			m._death(m.chase_catch_msg)
		return
	if m.auto_walk:
		return  # the attract/CI bot carries an unsweepable dog
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


# Caught: bring the machine to the front so it visibly rolls over them, shout
# it, and hold the card back for CATCH_BEAT.
static func _catch(m: Node2D, msg: String) -> void:
	var sweeper: Node2D = m.chase_sweeper
	sweeper.z_index = 8
	m.chase_catch_t = CATCH_BEAT
	m.chase_catch_msg = msg
	m.shake_t = 1.0
	m.feed.say("SWEPT!", EventFeed.Tone.BAD)
