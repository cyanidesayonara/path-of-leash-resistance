extends RefCounted

# A chase checkpoint: a run-local snapshot of the walk home, taken where
# systems/home_chase.gd says (leaving the destination, and the sweeper held
# at the later dumpster jam), and put back in place when a loss on the walk
# home is continued. It lives on main (chase_checkpoint) and dies with the
# scene; it is never written to the save, and capturing or restoring it
# touches nothing in Game.
#
# Restore REPLACES values, it never adds to them, so every reward in the
# snapshot is kept and nothing earned after it can be paid twice: the
# consumed-pickup lists come back with the counters and bones that paid for
# them. A list of dictionaries the same length as the snapshot's is
# rewritten in place, so anything holding one of its entries still sees it.
#
# THE SCHEMA. One list of fields per object, read and written by name:
#   main     the dog's business (pee, poop and its chore, marking), the
#            leash's length, the phone, bones, run-goal progress and every
#            counter a goal reads, the one-run pickups and rewards (hydrant
#            sniffs, snacks, other dogs' marks, chocolate, the prize, the
#            Fur-Goneta, the dare offer), the chase's own one-shots (its
#            closest approach, an armed close shave, the camera lean), and
#            the teeter, grind and pole-swing cooldowns
#   dog      where she is and how she is moving, her energy, a squat or
#            tumble in progress
#   human    where they are and how they are moving, the leash conversation
#            (patience and its timers), the next owner-event and reel timers,
#            the bag they carry, the once-a-walk call, and a panic
#   combo    the chain in progress and the run's best and style totals
#   challenge the kid's dare, whatever phase it is in
#   sweeper  the machine: kill line, lurch, swerve, the jams still ahead and
#            one it is stuck on
# The chase band (which checkpoint, so whether the warning repeats or the
# held jam counts down) is the snapshot's "id".
#
# NOT RESTORED, on purpose:
#   - the dog's mood: fear she has is left to decay through mood.gd, never
#     cleared by a continue
#   - the walk clock (elapsed): a continue costs time, so it can never buy a
#     better time record
#   - run_goals_new and Game: a goal ticked after the checkpoint stays ticked
#     in the save, as on any lost walk; it is open again for this run, and
#     re-earning it pays its run bones once and is not counted new twice
#   - what an owner was in the middle of (a stop, a selfie, a whirl, the
#     call): they come back walking, with the event timers the snapshot had
#   - a stunt in progress (a teeter at a brink, a grind, a pole swing): it is
#     ended without paying or failing, so she comes back on her feet; only
#     the cooldowns are kept
#   - the rope's points: laid fresh from dog to hand, as the gate does
#   - other walkers and their dogs, bikes, critters, loose junk and crates,
#     toppled scooters, paw prints and other cosmetics: none of them is a
#     reward, and they carry on from where they are

const Human := preload("res://entities/human.gd")

const MAIN_FIELDS := [
	# business and resources
	"pee", "poop_state", "urge_y", "urge_timer", "squat_progress", "business_spot",
	"bag_pending", "bag_flights", "marks", "puddles", "mark_progress", "mark_target",
	"mark_quest_done", "overmarks", "stray_t", "golden_t", "drunk_amount",
	# the leash
	"leash_len", "leash_target", "leash_haul", "nag_haul_t",
	# the phone, and the save streak a crack resets
	"phone_hp", "streak",
	# bones and run-goal progress: every counter a goal reads
	"bones", "run_goals_hit", "sniffs_done", "dog_hits", "squirrels_chased",
	"close_calls", "kebabs_eaten", "saves_done", "flings_done", "tangles",
	"dogs_greeted", "greeted", "romp_catches", "tofu_home", "splashes", "shallow_splashes", "human_soak",
	"wall_cats_spooked", "candy_eaten", "guards_woken", "times_spotted",
	"walkway_rides", "thieves_stopped", "wallets_returned", "owner_wallet_taken",
	"owner_wallet_lost", "carry_state", "cable_rides",
	# Els Senglars' and Festa de Gràcia's own goals
	"boar_mud_splashes", "boar_swings", "churros_eaten", "gracia_arches_zoomed", "gracia_arch_mask",
	# one-run pickups and rewards
	"hydrants", "kebabs", "npc_marks", "candy", "prize_taken", "furgoneta_sniffed",
	"challenge_offered",
	# the chase's one-shots
	"chase_min_gap", "chase_shave_armed", "chase_lean",
	# stunt cooldowns (the stunts themselves are ended by _settle)
	"teeter_cd", "grind_cd", "vault_cd",
]
const DOG_FIELDS := [
	"global_position", "velocity", "facing", "energy", "squat_t", "squat_ui",
	"tumble_t", "hole_cd",
]
const HUMAN_FIELDS := [
	"global_position", "velocity", "face_dir", "patience", "grace_t", "correct_t",
	"glance_t", "event_timer", "reel_timer", "carrying_bag", "call_used",
	"call_total", "iframes", "panic", "homeward", "parked",
]
const COMBO_FIELDS := ["links", "points", "timer", "names", "best_mult", "run_style"]
const CHALLENGE_FIELDS := [
	"phase", "active", "done", "succeeded", "target", "count", "timer", "duration",
	"reward", "retry", "offer_t", "end_t",
]
const SWEEPER_FIELDS := [
	"front_y", "cur_speed", "rumble", "sway", "sway_v", "heading", "jams", "jam_t",
	"jam_side", "jam_at",
]
const SECTIONS := {
	"main": MAIN_FIELDS, "dog": DOG_FIELDS, "human": HUMAN_FIELDS,
	"combo": COMBO_FIELDS, "challenge": CHALLENGE_FIELDS, "sweeper": SWEEPER_FIELDS,
}

# tests set this to see each snapshot the moment it is taken
static var capture_hook := Callable()


# The object a section's fields are read from and written to.
static func target(m: Node2D, section: String) -> Object:
	match section:
		"main":
			return m
		"dog":
			return m.dog
		"human":
			return m.human
		"combo":
			return m.combo
		"challenge":
			return m.challenge
		"sweeper":
			return m.chase_sweeper
	return null


# A snapshot of the walk as it stands. id names the checkpoint.
static func capture(m: Node2D, id: String) -> Dictionary:
	var sections := {}
	for section: String in SECTIONS:
		var obj := target(m, section)
		if obj == null:
			continue
		var vals := {}
		for key: String in SECTIONS[section]:
			if not key in obj:
				push_error("chase checkpoint: %s has no field %s" % [section, key])
				continue
			vals[key] = _copy(obj.get(key))
		sections[section] = vals
	return {"id": id, "sections": sections}


# Capture, and hold it on main as the latest checkpoint.
static func store(m: Node2D, id: String) -> void:
	m.chase_checkpoint = capture(m, id)
	if capture_hook.is_valid():
		capture_hook.call(m.chase_checkpoint)


static func clear(m: Node2D) -> void:
	m.chase_checkpoint = {}


# Put a snapshot back: its values replace the walk's, then whatever was
# mid-way that the schema leaves out is settled so the walk can go on.
static func restore(m: Node2D, snap: Dictionary) -> void:
	var sections: Dictionary = snap.get("sections", {})
	for section: String in sections:
		var obj := target(m, section)
		if obj == null:
			continue
		var vals: Dictionary = sections[section]
		for key: String in vals:
			_put(obj, key, vals[key])
	_settle(m)


static func _copy(v: Variant) -> Variant:
	if v is Array or v is Dictionary:
		return v.duplicate(true)
	return v


static func _put(obj: Object, key: String, val: Variant) -> void:
	var cur: Variant = obj.get(key)
	if cur is Array and val is Array and (cur as Array).size() == (val as Array).size() \
			and _all_dicts(cur) and _all_dicts(val):
		for i in range((cur as Array).size()):
			var d: Dictionary = cur[i]
			d.clear()
			d.merge((val[i] as Dictionary).duplicate(true))
		return
	obj.set(key, _copy(val))


static func _all_dicts(a: Array) -> bool:
	for e in a:
		if not e is Dictionary:
			return false
	return true


static func _settle(m: Node2D) -> void:
	var d: CharacterBody2D = m.dog
	d.skid = 0.0
	d.drag_amt = 0.0
	d.dragged = false
	d.peeing = false
	# no stunt carries over: ended, not landed or failed, so nothing pays
	m.teeter.cancel()
	m.grind.active = false
	m.grind.lean = 0.0
	m.grind.vel = 0.0
	m.grind_rail = -1
	m.vault_t = 0.0
	m.vault_arc = 0.0
	m.vault_elapsed = 0.0
	m.vault_speed_sum = 0.0
	var h: CharacterBody2D = m.human
	h.state = Human.HState.WALK
	h.state_t = 0.0
	h.telegraph_t = 0.0
	h.halt_t = 0.0
	h.reel_pending_t = 0.0
	h.pending_bench = false
	h.sit_after_dash = false
	h.whirl_omega = 0.0
	h.whirl_pull = 0.0
	h.just_flung = false
	h.whirl_flung_t = 0.0
	h.whirl_bailed = false
	h.rotation = 0.0
	h.felt_pull = Vector2.ZERO
	h.drag_amt = 0.0
	h.stuck_t = 0.0
	h.sidestep_t = 0.0
	h.sidestep_total = 0.0
	h.bin_stuck_t = 0.0
	h.waited = 0.0
	h.planted_at_hey = false
	if h.bubble != null:
		h.bubble.visible = false
	# the call ended with the walk; its leash came back with the snapshot
	m.call_active = false
	m.leash.rest_len = m.leash_len
	m.leash.free_slip_t = 0.0
	m.leash.resnap()
	if m.chase_sweeper != null:
		if m.chase_sweeper.has_method("cancel_branch_warning"):
			m.chase_sweeper.cancel_branch_warning()
		m.chase_sweeper.z_index = 0
		m.chase_sweeper.jammed_now = false
		m.chase_sweeper.freed_now = false
		m.chase_sweeper.global_position = Vector2(m.walk_cx, m.chase_sweeper.front_y)
		m.chase_sweeper.queue_redraw()
