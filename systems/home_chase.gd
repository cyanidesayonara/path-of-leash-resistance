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

const EventFeed := preload("res://event_feed.gd")


# At level start. Forced with --chase (slow sweeper), --bolt (fast, owner
# panics) or --rescue (both); otherwise a seeded chance and a roll for which
# kind. It takes over the home leg, so it and the Tofu herding are mutually
# exclusive. The randf() calls are part of the walk's seeded sequence: their
# number and order must not change.
static func roll(m: Node2D) -> void:
	var args := OS.get_cmdline_user_args()
	var chase_forced := "--chase" in args
	var bolt_forced := "--bolt" in args
	var rescue_forced := "--rescue" in args
	m.chase_active = (chase_forced or bolt_forced or rescue_forced or (not m.auto_walk and not Game.daily and randf() < 0.25)) and not m.tutorial_mode
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
	sweeper.z_index = 8
	sweeper.kind = m.chase_kind
	m.chase_sweeper = sweeper
	m.add_child(sweeper)
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
	if m.auto_walk:
		return  # the attract/CI bot carries an unsweepable dog
	if sweeper.caught(m.human.global_position):
		if m.chase_kind == "sweeper":
			m._death("THE SWEEPER GOT YOUR HUMAN\n\nThey never once looked up from the phone.\nYou did try to tell them.")
		else:
			m._death("THEY GOT YOUR HUMAN\n\nYou pulled. You barked. It was not enough.")
	elif sweeper.caught(m.dog.global_position):
		if m.chase_kind == "sweeper":
			m._death("YOU WENT INTO THE BRUSHES\n\nYou came out suspiciously clean.\nThe walk did not come out at all.")
		else:
			m._death("NOBODY WAITED FOR YOU\n\nYou snagged, the leash went tight, and\nthey kept walking. They always keep walking.")
