extends RefCounted

# The chase that can take over the walk home: a street sweeper eating the path
# behind you ("sweeper"), a fast threat the owner bolts from ("bolt"), or both
# at once ("both"). sweeper.gd is the machine itself; this decides whether a
# walk gets a chase, starts it on the home leg, and ends the walk if it
# catches anyone.
#
# Static functions over main's state (chase_active, chase_kind,
# chase_sweeper), which the HUD, the mood wiring and the tests also read.
#
# A chase walk owns one PROFILE (profile_for): the threat script to
# instantiate, its fixed behavior kind and speed, and the warning and caught
# copy. La Neteja's is the sweeper, always. The profile also carries "bands",
# the ordered respites of the chase home, nearest the destination first; a
# band marked "checkpoint" is where the midpoint checkpoint is taken.
# The developer hooks --chase, --bolt and --rescue force a named behavior on
# any walk, profile or not; their numbers and copy come from kind_behavior.
#
# THE PHASES of the walk home (main.chase_phase; "" before it begins):
#   "warning"    the destination checkpoint is taken, then the warning is
#                given, for WARNING_SECS
#   "head_start" HEAD_START_SECS to get going
#   "chase"      the machine runs, and only now can it catch anyone
#   "hold"       a midpoint continue: the machine held at its jam for HOLD_SECS,
#                then free at once; the countdown is the whole respite
# Outside "chase" the machine does not advance, catch, or pay a close shave,
# and (mood_wiring.gd, through advancing()) adds no fear. The midpoint is
# never taken during a catch beat or with either of the pair at the kill
# line. Any loss on the home leg (the machine, the phone, a hazard) can be
# continued from the latest checkpoint (systems/chase_checkpoint.gd holds the
# snapshot): the destination repeats the warning and head start, the
# midpoint counts down at its jam.

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
# The camera leans back up the street, at most this far, to keep the threat's
# leading boundary LEAN_SHOW deep in the top of the screen. Never further, or
# there is no road left to see ahead of the dog.
const LEAN_MAX := 186.0
const LEAN_SHOW := 176.0
const LEAN_RATE := 3.0
const CAMERA_PAIR_OFFSET_Y := -60.0
const CAMERA_RUNWAY_PX := 110.0
# Camera2D smoothing trails a moving target by speed / smoothing speed.
# Reserve that live amount plus the largest shake; at turbo speed the safe
# chase_lean can become negative and briefly frame further down the road.
const CAMERA_SHAKE_WORLD := 9.0
const THREAT_VISIBLE_PX := 48.0
const LEAN_APPROACH_PX := 64.0

# the warning, the head start after it, and a midpoint continue's countdown
const WARNING_SECS := 1.2
const HEAD_START_SECS := 3.0
const HOLD_SECS := 3.0
# a band's jam_y is its dumpster's depth; the jam point the machine snags on
# is a little short of it
const BAND_JAM_REACH := 100.0

const SWEEPER_SCRIPT := "res://entities/sweeper.gd"
# La Neteja's dumpster jams, by depth (world/level_build.gd NETEJA_JAMS):
# the first the way home meets, then the later one, the midpoint
const NETEJA_BANDS := [
	{"id": "first_jam", "kind": "respite", "jam_y": -3600.0},
	{"id": "midpoint", "kind": "respite", "jam_y": -1900.0, "checkpoint": true},
]

const EventFeed := preload("res://hud/event_feed.gd")
const ChaseCheckpoint := preload("res://systems/chase_checkpoint.gd")


# The numbers and copy of one behavior kind ("sweeper", "bolt" or "both";
# anything else is the sweeper): its speed, whether the owner bolts, what is
# shouted when it starts and what a catch says. A profile fixes one kind for
# its walk; the developer hooks pick any.
# "warning_color" present means the warning floats over the owner; absent, it
# is a feed shout.
static func kind_behavior(kind: String) -> Dictionary:
	match kind:
		"bolt":
			return {
				"kind": "bolt", "speed": CHASE_SPEED_BOLT, "flee": true,
				"warning": "AAH!  YOUR HUMAN BOLTED!", "warning_color": Color(1, 0.6, 0.3),
				"caught_human": "THEY GOT YOUR HUMAN\n\nYou pulled. You barked. It was not enough.",
				"caught_dog": "NOBODY WAITED FOR YOU\n\nYou snagged, the leash went tight, and\nthey kept walking. They always keep walking.",
			}
		"both":
			return {
				"kind": "both", "speed": CHASE_SPEED_BOTH, "flee": true,
				"warning": "FIRE TRUCK!  GO GO GO!", "warning_color": Color(1, 0.55, 0.25),
				"caught_human": "THEY GOT YOUR HUMAN\n\nYou pulled. You barked. It was not enough.",
				"caught_dog": "NOBODY WAITED FOR YOU\n\nYou snagged, the leash went tight, and\nthey kept walking. They always keep walking.",
			}
	return {
		"kind": "sweeper", "speed": CHASE_SPEED, "flee": false,
		"warning": "STREET SWEEPER! RUN!",
		"caught_human": "THE SWEEPER GOT YOUR HUMAN\n\nThey never once looked up from the phone.\nYou did try to tell them.",
		"caught_dog": "YOU WENT INTO THE BRUSHES\n\nYou came out suspiciously clean.\nThe walk did not come out at all.",
	}


# The chase profile of a walk, or an empty dictionary when it has none (every
# walk but La Neteja). A fresh copy each call. Keys: "id", "script" (the
# threat script, a path or a Script), "kind", "speed", "flee", "warning",
# "caught_human", "caught_dog", and "bands" (the ordered respites of the
# chase home: "id", "kind", "jam_y", and "checkpoint" on the midpoint).
static func profile_for(level: String) -> Dictionary:
	if level != CHASE_LEVEL:
		return {}
	var p := kind_behavior("sweeper")
	p["id"] = CHASE_LEVEL
	p["script"] = SWEEPER_SCRIPT
	p["bands"] = NETEJA_BANDS.duplicate(true)
	return p


# The profile a walk runs its chase by: its own, or for a chase forced onto a
# walk that has none, the sweeper script with kind_behavior's numbers and copy.
static func active_profile(m: Node2D) -> Dictionary:
	var p := profile_for(m.lvl)
	if p.is_empty():
		p = kind_behavior("sweeper")
		p["id"] = "hook"
		p["script"] = SWEEPER_SCRIPT
		p["bands"] = []
	return p


# The profile this chase began with (begin() holds it on main). A chase that
# was set up without begin() falls back to the walk's active profile.
static func held_profile(m: Node2D) -> Dictionary:
	if m.chase_profile.is_empty():
		return active_profile(m)
	return m.chase_profile


# The numbers and copy for this walk's chase kind: the profile's when it is
# the profile's own kind, kind_behavior's (a developer hook's) otherwise.
static func _behavior(m: Node2D, profile: Dictionary) -> Dictionary:
	if String(profile.get("kind", "")) == String(m.chase_kind):
		return profile
	return kind_behavior(String(m.chase_kind))


# At level start. La Neteja always gets one; any walk can be forced with
# --chase (slow sweeper), --bolt (fast, owner panics) or --rescue (both).
# Then a roll for which kind. It takes over the home leg, so it and the Tofu
# herding are mutually exclusive.
#
# The chase used to roll on a quarter of every walk. It lives on its own walk
# now (#20), but the roll is still made, and ignored elsewhere: the randf()
# calls are part of each walk's seeded sequence (dailies, --seed replays, the
# soak), and dropping one would reshuffle everything drawn after it. The same
# goes for the kind draw on La Neteja: it is made, and the profile's fixed
# kind wins.
static func roll(m: Node2D, args: PackedStringArray = OS.get_cmdline_user_args()) -> void:
	var chase_forced := "--chase" in args
	var bolt_forced := "--bolt" in args
	var rescue_forced := "--rescue" in args
	var profile := profile_for(m.lvl)
	var chase_walk: bool = not profile.is_empty()
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
			# ordinary play on a profiled walk: drawn, then ignored
			if chase_walk:
				m.chase_kind = String(profile["kind"])


# On entering the home leg, when this walk rolled a chase. `profile` is the
# walk's own unless a caller hands one in.
static func begin(m: Node2D, profile: Dictionary = {}) -> void:
	if profile.is_empty():
		profile = active_profile(m)
	# the one profile the rest of this chase (the catch copy, later the
	# bands) is read from
	m.chase_profile = profile
	var behavior := _behavior(m, profile)
	var threat_script = profile["script"]
	if not threat_script is Script:
		threat_script = load(String(threat_script))
	var sweeper := Node2D.new()
	sweeper.set_script(threat_script)
	sweeper.kind = m.chase_kind
	m.chase_sweeper = sweeper
	m.add_child(sweeper)
	# Behind the living: the brushes reach a little past the kill line, and a
	# machine drawn over the human or the leash (#20) read as a bug, not a
	# threat. Anyone it draws over is already caught - see the catch beat.
	m.move_child(sweeper, mini(m.dog.get_index(), m.human.get_index()))
	m.chase_min_gap = INF
	var spd: float = behavior.get("speed", CHASE_SPEED)
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
	# the destination checkpoint, before anything is said
	ChaseCheckpoint.store(m, "destination")
	_warn(m, behavior)


# The warning, and the head start that follows it: the machine is held
# until both are over.
static func _warn(m: Node2D, behavior: Dictionary) -> void:
	m.chase_phase = "warning"
	m.chase_phase_t = WARNING_SECS
	m.shake_t = 1.0
	if behavior.get("flee", false):
		m.human.panic = true
	if behavior.has("warning_color"):
		m.float_text(m.human.global_position, String(behavior.get("warning", "")), behavior["warning_color"])
	else:
		m.feed.say(String(behavior.get("warning", "")), EventFeed.Tone.BAD)


# The head start is over: the machine runs and can catch. Tests call this to
# skip straight to the chase.
static func release(m: Node2D) -> void:
	m.chase_phase = "chase"
	m.chase_phase_t = 0.0


# Moving on the pair right now: what SCARED is fed by (mood_wiring.gd). Not
# before or after the chase, not held by a warning, a head start or a
# countdown, and not stuck on a dumpster.
static func advancing(m: Node2D) -> bool:
	var sweeper: Node2D = m.chase_sweeper
	return m.chase_active and sweeper != null and String(m.chase_phase) == "chase" \
		and not sweeper.jammed()


# The authored leading boundary that camera and fear share. A threat with a
# recoverable outer zone, such as floodwater, exposes that shallow edge with
# threat_boundary(); the sweeper's brushes remain its front_y.
static func threat_boundary(threat: Node2D) -> float:
	if threat.has_method("threat_boundary"):
		return float(threat.call("threat_boundary"))
	return float(threat.get("front_y"))


# Whether an authored threat boundary has entered the rendered world view far
# enough to read.
static func threat_visible(m: Node2D, boundary_y: float) -> bool:
	var zoom_y := maxf(float(m.cam.zoom.y), 0.01)
	var viewport_h := float(m.get_viewport_rect().size.y)
	var rendered_top := float(m.cam.get_screen_center_position().y) - viewport_h * 0.5 / zoom_y
	return (boundary_y - rendered_top) * zoom_y >= THREAT_VISIBLE_PX - 0.001


# The chase_lean target remains the one camera mechanism, capped by the
# rendered runway below the southernmost body.
static func camera_target(boundary_y: float, dog_y: float, human_y: float,
		viewport_h: float, zoom_y: float) -> float:
	zoom_y = maxf(zoom_y, 0.01)
	var cam_y := (dog_y + human_y) * 0.5 + CAMERA_PAIR_OFFSET_Y
	var view_half := viewport_h * 0.5 / zoom_y
	var need: float = (cam_y - view_half) - (boundary_y - LEAN_SHOW)
	var max_lean := camera_runway_cap(dog_y, human_y, viewport_h, zoom_y)
	# Begin the lean one small screen band before it can reveal the boundary.
	# The smooth ramp avoids pumping as the pair's separation changes the cap.
	var visible_reach := max_lean + LEAN_SHOW - THREAT_VISIBLE_PX / zoom_y
	var approach := clampf((visible_reach + LEAN_APPROACH_PX / zoom_y - need)
		/ (LEAN_APPROACH_PX / zoom_y), 0.0, 1.0)
	return clampf(need, 0.0, max_lean) * approach


static func camera_runway_cap(dog_y: float, human_y: float,
		viewport_h: float, zoom_y: float, follow_speed_y: float = 0.0,
		smoothing_speed: float = 6.0) -> float:
	zoom_y = maxf(zoom_y, 0.01)
	var cam_y := (dog_y + human_y) * 0.5 + CAMERA_PAIR_OFFSET_Y
	var view_half := viewport_h * 0.5 / zoom_y
	var smoothing_lag := maxf(follow_speed_y, 0.0) / maxf(smoothing_speed, 0.01)
	var runway_world := CAMERA_RUNWAY_PX / zoom_y + CAMERA_SHAKE_WORLD + smoothing_lag
	var runway_cap := cam_y + view_half - maxf(dog_y, human_y) - runway_world
	return minf(LEAN_MAX, runway_cap)


# A held phase's frame: the clock runs down and the machine idles where it
# is. Nothing advances, catches or pays.
static func _hold(m: Node2D, sweeper: Node2D, delta: float) -> void:
	sweeper.jammed_now = false
	sweeper.freed_now = false
	sweeper.rumble += delta
	sweeper.global_position = Vector2(m.walk_cx, sweeper.front_y)
	sweeper.queue_redraw()
	_lean(m, sweeper, delta)
	m.chase_phase_t = float(m.chase_phase_t) - delta
	if m.chase_phase_t > 0.0:
		return
	match String(m.chase_phase):
		"warning":
			m.chase_phase = "head_start"
			m.chase_phase_t = HEAD_START_SECS
		"hold":
			# the countdown was the respite: whatever was left of the jam goes
			sweeper.jam_t = 0.0
			_say_freed(m, sweeper)
			release(m)
		_:
			release(m)


static func _say_freed(m: Node2D, sweeper: Node2D) -> void:
	Sfx.play("hiss", 0.6, -6.0)
	m.float_text(Vector2(m.walk_cx + sweeper.sway, sweeper.front_y - 60.0), "VRRROOM", Color(1.0, 0.7, 0.4))


# Whether the jam the machine just snagged on is the profile's checkpoint.
static func _checkpoint_jam(m: Node2D, at: Vector2) -> bool:
	for band: Dictionary in held_profile(m).get("bands", []):
		if bool(band.get("checkpoint", false)) and absf(float(band.get("jam_y", INF)) - at.y) < BAND_JAM_REACH:
			return true
	return false


# What the banner says on the walk home ("" with no chase on the road).
static func banner(m: Node2D) -> String:
	var sweeper: Node2D = m.chase_sweeper
	if not m.chase_active or sweeper == null:
		return ""
	var left := int(ceil(maxf(float(m.chase_phase_t), 0.0)))
	match String(m.chase_phase):
		"warning":
			return "HERE IT COMES! HEAD FOR HOME"
		"head_start":
			return "HEAD START! GO  %d" % left
		"hold":
			return "IT'S STILL STUCK! GO  %d" % left
	if sweeper.jammed():
		return "IT'S STUCK! CATCH YOUR BREATH"
	if m.chase_kind == "both":
		return "RUN HOME TOGETHER!"
	if m.chase_kind == "bolt":
		return "HE'S RUNNING! KEEP UP"
	return "RUN! DON'T LET IT CATCH YOU"


# The end card's retry is "continue": the walk was lost on the home leg, to
# anything, with a checkpoint held. A loss on the way out has none.
static func can_continue(m: Node2D) -> bool:
	return not (m.chase_checkpoint as Dictionary).is_empty() and String(m.phase) == "home" \
		and m.started and m.frozen and not m.finished and not m.paused and m.msg_label.visible


# Back to the latest checkpoint, in place: its values replace the walk's,
# the card goes, and the destination repeats its warning and head start
# while the midpoint holds the machine at its jam for a countdown.
static func continue_run(m: Node2D) -> void:
	var snap: Dictionary = m.chase_checkpoint
	ChaseCheckpoint.restore(m, snap)
	m.chase_catch_t = 0.0
	m.chase_catch_msg = ""
	m.msg_label.visible = false
	m.dim.visible = false
	m.feed.clear()
	m.frozen = false
	Engine.time_scale = 1.0
	if String(snap.get("id", "")) == "midpoint":
		m.chase_phase = "hold"
		m.chase_phase_t = HOLD_SECS
		m.shake_t = 0.0
	else:
		_warn(m, _behavior(m, held_profile(m)))
	m.cam.position = (m.dog.global_position + m.human.global_position) * 0.5 \
		+ Vector2(0.0, CAMERA_PAIR_OFFSET_Y - float(m.chase_lean))
	m.cam.reset_smoothing()
	m._update_hud()


# Every physics frame of the home leg.
static func tick(m: Node2D, delta: float) -> void:
	var sweeper: Node2D = m.chase_sweeper
	if sweeper == null:
		return
	if String(m.chase_phase) != "chase" and m.chase_catch_t <= 0.0:
		_hold(m, sweeper, delta)
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
		_say_freed(m, sweeper)
	if sweeper.sweep_junk(m.get_tree().get_nodes_in_group("cones")) > 0:
		Sfx.play("tangle", 0.8, -10.0)
	# a low rumble the closer it gets to the dog
	var gap: float = sweeper.gap_to(m.dog.global_position)
	if gap < 260.0:
		m.shake_t = maxf(m.shake_t, 0.25)
	rear = minf(gap, sweeper.gap_to(m.human.global_position))
	# held at its jam: the midpoint checkpoint, if this is its jam, and only
	# with both of them clear of the brooms and no catch already rolling. A
	# jam that fails this keeps the checkpoint before it.
	if sweeper.jammed_now and m.chase_catch_t <= 0.0 and rear > 0.0 \
			and _checkpoint_jam(m, sweeper.jam_at):
		ChaseCheckpoint.store(m, "midpoint")
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
		_catch(m, String(_behavior(m, held_profile(m)).get("caught_human", "")))
	elif sweeper.caught(m.dog.global_position):
		_catch(m, String(_behavior(m, held_profile(m)).get("caught_dog", "")))


# How far the camera leans back up the street this frame: just enough to bring
# the threat's authored boundary LEAN_SHOW into the top of the screen, eased.
static func _lean(m: Node2D, sweeper: Node2D, delta: float) -> void:
	var want := camera_target(threat_boundary(sweeper),
		float(m.dog.global_position.y), float(m.human.global_position.y),
		float(m.get_viewport_rect().size.y), float(m.cam.zoom.y))
	var eased := lerpf(float(m.chase_lean), want, 1.0 - exp(-LEAN_RATE * delta))
	# Easing may never carry an old, larger lean past this frame's safety cap
	# when the leash opens and the southernmost body moves down-screen.
	var cap := camera_runway_cap(float(m.dog.global_position.y),
		float(m.human.global_position.y), float(m.get_viewport_rect().size.y),
		float(m.cam.zoom.y), maxf(float(m.dog.velocity.y), float(m.human.velocity.y)),
		float(m.cam.position_smoothing_speed))
	m.chase_lean = minf(eased, cap)


# Caught: bring the machine to the front so it visibly rolls over them, shout
# it, and hold the card back for CATCH_BEAT.
static func _catch(m: Node2D, msg: String) -> void:
	var sweeper: Node2D = m.chase_sweeper
	sweeper.z_index = 8
	m.chase_catch_t = CATCH_BEAT
	m.chase_catch_msg = msg
	m.shake_t = 1.0
	m.feed.say("SWEPT!", EventFeed.Tone.BAD)
