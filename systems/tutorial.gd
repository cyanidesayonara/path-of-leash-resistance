extends RefCounted

# THE FIRST WALK: a calm, safe place to learn each verb one at a time.
#
# No traffic, no chases, no walkers, nothing that can end your walk, and one
# instruction at a time with room to practice it for as long as you like
# before the next arrives. Every lesson is skippable, because a tutorial that
# traps a player who cannot do the thing is worse than no tutorial at all.
#
# Three parts.
#   THE BASICS (up to "poop"): what every walk needs. Then THAT'S THE BASICS
#     offers the first real walk straight away, or the tricks.
#   THE TRICKS (up to "dare"): the leash as a pivot, your human as a
#     tetherball, ledges, the brink, combos and dares.
#   FREE PRACTICE ("practice", "park"): a yard holding a little of
#     everything, then the dog park off the leash. Nothing is asked of you
#     there and nothing ends by itself; the prompt bar's finish button, any
#     time, is the way out.
#
# The steps are DATA so the teaching order can be retuned without touching
# the driver below. Each lesson has a STATION: "at" is how far up the walk it
# stands, holding exactly what the lesson needs (LevelBuild lays the props out
# from these numbers). "hold" means your human waits at the station until the
# lesson lands or is skipped; a lesson that needs them walking leaves it off.
# "stand" (-1 west, 1 east) puts the waiting human by that edge of the path,
# for a lesson whose target is off to one side; "bench" seats them on a park
# bench at their spot, on the phone. "mind" keeps a waiting human counting
# their patience. "meter" names the HUD meter the lesson uses (hud_panel.gd
# outlines it). "ghost" names the hint drawn in the world while the lesson is
# up (world/tutorial_layer.gd). "yard" steps share the practice yard's bench.
# "refill" tops the zoomies back up while she is not running: those lessons
# need them, and a bar burnt on the way must not leave a lesson undoable.
# "loose" leaves the waiting human unbraced (main.TUT_BRACE), and "back"
# overrides how far short of the station they wait: tetherball needs them
# close to the post and windable.
# "free" marks the practice steps, which are not lessons and have no check:
# their skip is "finish".
const STEPS: Array[Dictionary] = [
	{
		"id": "walk", "at": 60.0, "hold": false,
		"title": "Walk time.",
		"body": "Head up the path with {move_with}. Your human follows, eyes on the phone.",
	},
	{
		"id": "pull", "at": -380.0, "hold": true, "bench": true,
		"title": "The leash is real rope.",
		"body": "Your human has sat down. Walk on until the leash goes tight.",
	},
	{
		"id": "lead", "at": -650.0, "hold": true, "ghost": "ring",
		"title": "Lead the way.",
		"body": "A steady pull steers your human. Walk them through the chalk ring.",
	},
	{
		"id": "plant", "at": -850.0, "hold": false,
		"title": "Dig in.",
		"body": "Hold {plant} while the leash is tight. Your human can't budge you.",
	},
	{
		"id": "patience", "at": -1150.0, "hold": true, "mind": true,
		"title": "Easy does it.",
		"body": "Hauling wears out your human. Pull until a cloud shows, then ease off.",
	},
	{
		"id": "pee", "at": -1400.0, "hold": true, "bench": true, "meter": "tank", "ghost": "hydrant",
		"title": "Leave your mark.",
		"body": "Hold {pee} at the hydrant. The yellow bar is your pee.",
	},
	{
		"id": "sniff", "at": -1750.0, "hold": true, "bench": true, "ghost": "hydrant",
		"title": "A good sniff.",
		"body": "Stand still by the next hydrant and give it a long read.",
	},
	{
		"id": "nose", "at": -2100.0, "hold": true, "stand": -1,
		"title": "Follow your nose.",
		"body": "A snack is out on the grass. Go slowly: the slower you go, the farther you smell.",
	},
	{
		"id": "bark", "at": -2450.0, "hold": true, "bench": true,
		"title": "Use your voice.",
		"body": "Press {bark} at the pigeons. It scatters them and stops your human dead.",
	},
	{
		"id": "turbo", "refill": true, "at": -2600.0, "hold": false, "meter": "zoomies",
		"title": "The zoomies.",
		"body": "Hold {turbo} to run flat out. It burns the green bar.",
	},
	{
		"id": "poop", "at": -2850.0, "hold": true, "bench": true, "ghost": "grass",
		"title": "Nature calls.",
		"body": "Find some grass, stand still and hold {poop}. Your human bags it. Eventually.",
	},
	{
		"id": "vault", "refill": true, "at": -3200.0, "hold": true, "bench": true, "ghost": "swing",
		"title": "Swing around a post.",
		"body": "Hold {turbo} and run past the lamppost. The leash catches and slings you around it.",
	},
	{
		"id": "fling", "refill": true, "at": -3550.0, "hold": true, "ghost": "wind", "loose": true, "back": 90.0,
		"title": "Tetherball.",
		"body": "Your human is waiting by the post. Run around it twice to wind them up, then pull away.",
	},
	{
		"id": "grind", "refill": true, "at": -3900.0, "hold": true, "ghost": "ledge",
		"title": "Ride the ledge.",
		"body": "Hold {turbo} and run along the stone ledge to hop up. Steer against the wobble.",
	},
	{
		"id": "teeter", "refill": true, "at": -4270.0, "hold": true, "stand": 1,
		"title": "The brink.",
		"body": "Run at the pond's edge. When you wobble, steer away from the water.",
	},
	{
		"id": "combo", "refill": true, "at": -4600.0, "hold": true, "bench": true, "yard": true,
		"title": "Chain them.",
		"body": "Land tricks back to back, a swing then a grind, and the combo multiplies your bones.",
	},
	{
		"id": "dare", "refill": true, "at": -4600.0, "hold": true, "bench": true, "yard": true,
		"title": "Take a dare.",
		"body": "The kid on the bench has dares. Bark to take one. Losing costs nothing.",
	},
	{
		"id": "practice", "refill": true, "at": -4600.0, "hold": true, "bench": true, "yard": true, "free": true,
		"title": "Practice yard.",
		"body": "Try anything, as long as you like. Head through the gate when you're done.",
	},
	{
		"id": "park", "at": -5200.0, "hold": false, "free": true,
		"title": "Off the leash.",
		"body": "The dog park is all yours: fetch the ball, dig the loose dirt, say hi.",
	},
]

# the last lesson of THE BASICS: THAT'S THE BASICS follows it
const BASICS_END := "poop"
# where your human waits, this far south of the lesson's station
const HOLD_BACK := 150.0
# how far in from the path's edge a lesson's "stand" puts the waiting human
const STAND_IN := 60.0
# a lesson card is up at least this long before it can be passed, so no card
# flashes by unread (the leash goes tight the moment your human sits down)
const MIN_CARD_S := 1.2
# the lead lesson's chalk ring: its radius, and how far west of the path's
# middle it is drawn at the lesson's station. Your human walks up to it and
# stops level with it; a steady sideways pull then walks them across
# (LEAD_PULL: the rope tension that gets them stepping, LEAD_STEP: how far
# ahead of themselves a full pull aims them)
const RING_R := 60.0
const RING_X := 150.0
const LEAD_PULL := 140.0
const LEAD_STEP := 120.0
# how fast a "refill" lesson tops the zoomies back up, per second, while she
# is not running (they burn at 0.28)
const ZOOM_REFILL := 0.3
# the dig-in lesson: this long dug in on a tight leash
const PLANT_S := 1.0
# the practice yard, around the bench your human waits on (practice_bench):
# two lampposts, a hydrant, a stone ledge and the kid with the dares, each in
# reach of a full leash from the bench
const YARD_POLES: Array[Vector2] = [Vector2(-150.0, -200.0), Vector2(-60.0, -300.0)]
const YARD_HYDRANT := Vector2(60.0, -190.0)
const YARD_LEDGE_X := 190.0
const YARD_LEDGE_Y0 := 10.0
const YARD_LEDGE_Y1 := -250.0
const YARD_KID := Vector2(-200.0, -330.0)
# a lost ball lies in the yard, the one piece of loose junk on the First Walk
const YARD_BALL := Vector2(100.0, -90.0)
# leaving the yard: she has pulled the leash tight this far north of the
# bench, inside this far of the path's middle (heading for the gate, not for
# the kid or a post), and your human gets up and walks her to the gate
const YARD_EXIT_Y := 340.0
const YARD_EXIT_X := 150.0
# the vault lesson's lamppost stands this far beyond its station. A swing
# needs under 190 px of rope past the post (main._tick_vault), and under the
# zoomies the leash stretches to about 400: from 150 px away the rope past it
# was always too long, from 260 it swings
# (the yard's posts keep the same 250 px or more from its bench)
const VAULT_POST_AHEAD := 110.0
# the grind lesson's ledge (systems/rails.gd)
const LEDGE_X := 760.0
const LEDGE_HALF := 150.0
# the kid's dares in the yard: easier than a walk's (entities/challenger.gd)
const YARD_LADDER := [[3, 20.0], [5, 20.0], [8, 20.0]]


static func index_of(id: String) -> int:
	for i in range(STEPS.size()):
		if String(STEPS[i]["id"]) == id:
			return i
	return -1


static func at(id: String) -> float:
	var i := index_of(id)
	return float(STEPS[i]["at"]) if i >= 0 else 0.0


static func step_count() -> int:
	return STEPS.size()


static func step(i: int) -> Dictionary:
	if i < 0 or i >= STEPS.size():
		return {"id": "", "title": "", "body": "", "at": 0.0, "hold": false}
	return STEPS[i]


# The lessons, not counting the free practice at the end.
static func lesson_count() -> int:
	var n := 0
	for st: Dictionary in STEPS:
		if not bool(st.get("free", false)):
			n += 1
	return n


static func is_free(i: int) -> bool:
	return bool(step(i).get("free", false))


# What the card's prompt bar offers for the step up: moving on from a lesson,
# finishing from the free practice.
static func skip_label(i: int) -> String:
	return "finish" if is_free(i) else "move on"


static func vault_post() -> Vector2:
	return Vector2(640.0, at("vault") - VAULT_POST_AHEAD)


# The yard's bench: where your human waits through the practice steps.
static func practice_bench(m: Node2D) -> Vector2:
	return Vector2(float(m.walk_cx), at("practice") + HOLD_BACK)


static func yard_poles(m: Node2D) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var b := practice_bench(m)
	for o: Vector2 in YARD_POLES:
		out.append(b + o)
	return out


static func yard_hydrant(m: Node2D) -> Vector2:
	return practice_bench(m) + YARD_HYDRANT


static func yard_ledge(m: Node2D) -> PackedVector2Array:
	var b := practice_bench(m)
	return PackedVector2Array([Vector2(b.x + YARD_LEDGE_X, b.y + YARD_LEDGE_Y0),
		Vector2(b.x + YARD_LEDGE_X, b.y + YARD_LEDGE_Y1)])


static func yard_kid(m: Node2D) -> Vector2:
	return practice_bench(m) + YARD_KID


# The patch of lawn the poop lesson points at: level with the bench, just
# onto the west grass, well inside a full leash (squatting at the end of the
# leash, the tow from your human keeps interrupting her)
static func poop_grass(m: Node2D) -> Vector2:
	var y := at("poop") + HOLD_BACK
	var e: Vector2 = m.walk_edges(y)
	return Vector2(e.x - 40.0, y)


# Dares are offered once the dare lesson is up, never earlier (the kid sits
# within earshot of the brink station).
static func dares_open(m: Node2D) -> bool:
	return int(m.tut_step) >= index_of("dare")


# --- the driver: main.gd calls these through same-name forwarders ---------

# One check per lesson, each written against what the game already tracks,
# so the tutorial teaches the REAL mechanics rather than a scripted imitation
# of them.
static func step_done(m: Node2D, id: String) -> bool:
	match id:
		"walk": return float(m.tut_start_y) - m.dog.global_position.y > 240.0
		"pull": return m.leash.taut and m.leash.used_length() > float(m.leash_len) * 0.98
		"lead": return m.human.global_position.distance_to(m.tut_ring) < RING_R
		"plant": return float(m.tut_plant_t) >= PLANT_S
		"patience": return bool(m.tut_clouded) and (float(m.human.patience) > m.human.PATIENCE_WARN + 0.15 \
			or float(m.human.grace_t) > 0.0)
		"pee": return m.marks.size() >= 1
		"sniff": return int(m.sniffs_done) >= 1
		"nose": return int(m.kebabs_eaten) >= 1
		"bark": return int(m.barks_done) >= 1
		"turbo": return m.dog.turbo_active and float(m.dog.energy) < 0.94
		"poop": return int(m.poop_state) == 2 and not bool(m.bag_pending)
		"vault": return int(m.vaults_landed) >= 1
		"fling": return int(m.flings_done) >= 1
		"grind": return int(m.grinds_landed) >= 1
		"teeter": return bool(m.tut_teetered) and not m.teeter.active
		"combo": return m.combo.mult() >= 2
		"dare": return String(m.challenge.phase) == "live"
	# the free practice has no check: it ends when she goes through the gate
	# (practice) or when the player says so
	return false


# Where your human waits for lesson i: y short of the station, and x by the
# path's edge when the lesson gives a "stand" (INF when it does not, so they
# keep their own place in the weave).
static func hold_point(m: Node2D, i: int) -> Vector2:
	var st := step(i)
	if not bool(st.get("hold", false)):
		# a lesson that needs them walking still never walks them past the
		# next station: they stop there and wait for the lesson to land
		if not bool(st.get("free", false)):
			for j in range(i + 1, STEPS.size()):
				if bool(STEPS[j].get("hold", false)):
					return Vector2(INF, hold_point(m, j).y)
		return Vector2(INF, -INF)
	# the lead lesson: they stop level with the ring, wherever they are across
	if String(st.id) == "lead":
		return Vector2(INF, float(st["at"]))
	var y := float(st["at"]) + float(st.get("back", HOLD_BACK))
	var side := int(st.get("stand", 0))
	if side == 0:
		# a lesson with a bench seats them on it, mid-path
		return Vector2(float(m.walk_cx) if bool(st.get("bench", false)) else INF, y)
	var e: Vector2 = m.walk_edges(y)
	return Vector2((e.x + STAND_IN) if side < 0 else (e.y - STAND_IN), y)


static func tick(m: Node2D, delta: float) -> void:
	m.tut_flash = maxf(0.0, float(m.tut_flash) - delta)
	m.tut_card_t = float(m.tut_card_t) + delta
	var st := step(int(m.tut_step))
	var id := String(st.id)
	m.hud_point = String(st.get("meter", ""))
	# your human waits at a lesson that wants them still, just short of it
	var hp := hold_point(m, int(m.tut_step))
	if id == "practice" and _leaving_yard(m):
		hp = Vector2(INF, -INF)
	m.human.tut_hold_y = hp.y
	m.human.tut_hold_x = hp.x
	m.human.tut_mind = bool(st.get("mind", false))
	# a waiting human leaves the reel alone at full length: a lesson's target
	# is laid out for the whole leash, and a click to 170 would put it out of reach
	if bool(st.get("hold", false)) and float(m.leash_target) < m.LEASH_LENGTH:
		m.set_leash_target(m.LEASH_LENGTH)
	if bool(st.get("refill", false)) and not m.dog.turbo_active:
		m.dog.energy = minf(1.0, float(m.dog.energy) + ZOOM_REFILL * delta)
	if id == "plant" and m.dog.planted and m.leash.taut:
		m.tut_plant_t = float(m.tut_plant_t) + delta
	if id == "patience" and float(m.human.patience) < m.human.PATIENCE_WARN:
		m.tut_clouded = true
	if id == "lead":
		_tick_lead(m)
	if m.teeter.active:
		m.tut_teetered = true
	if id == "" or bool(m.finished):
		return
	if Input.is_action_just_pressed("share"):
		skip(m)
		return
	# the yard's practice ends when she goes through the gate into the park
	if id == "practice" and String(m.phase) == "freedom":
		advance(m, true)
		return
	if float(m.tut_card_t) < MIN_CARD_S:
		return
	if step_done(m, id):
		advance(m, true)


# Done practicing: once she heads for the gate on a tight leash, your human
# stops waiting and walks on with her, and keeps walking.
static func _leaving_yard(m: Node2D) -> bool:
	if bool(m.tut_leaving):
		return true
	var b := practice_bench(m)
	var d: Vector2 = m.dog.global_position
	if d.y < b.y - YARD_EXIT_Y and absf(d.x - b.x) < YARD_EXIT_X and m.leash.taut:
		m.tut_leaving = true
	return bool(m.tut_leaving)


# The lead lesson: the ring sits at its station, west of the middle. Your
# human walks up weaving and the pull steers them as on any walk; if they
# arrive level with it and outside, they wait there, and a steady sideways
# pull walks them across, a step at a time. There is no failing it.
static func ring_at(m: Node2D) -> Vector2:
	return Vector2(float(m.walk_cx) - RING_X, at("lead"))


static func _tick_lead(m: Node2D) -> void:
	m.tut_ring = ring_at(m)
	var h: Node2D = m.human
	if not h.tut_holding():
		return
	var px: float = h.felt_pull.x
	if absf(px) < LEAD_PULL:
		h.tut_hold_x = h.global_position.x
		return
	var e: Vector2 = m.walk_edges(h.global_position.y)
	var step := clampf(px / m.human.GIVE_FULL, -1.0, 1.0) * LEAD_STEP
	h.tut_hold_x = clampf(h.global_position.x + step, e.x + 30.0, e.y - 30.0)


# The prompt bar's button: skippable, always. A lesson is moved on from; in
# the free practice the same button finishes the First Walk.
static func skip(m: Node2D) -> void:
	if is_free(int(m.tut_step)):
		m._finish_tutorial_walk()
	else:
		advance(m, false)


static func advance(m: Node2D, earned: bool) -> void:
	var was := String(step(int(m.tut_step)).id)
	m.tut_step = int(m.tut_step) + 1
	m.tut_card_t = 0.0
	# the basics done: a card offering the first real walk now, or the tricks
	if was == BASICS_END and not bool(m.tut_basics_seen):
		m.MenuFlow.open_basics(m)
	m.tut_flash = 1.1
	if earned:
		m.get_node("/root/Sfx").play("star", 1.15)
		m.bones = int(m.bones) + 2
	else:
		m.get_node("/root/Sfx").play("ui", 0.9)
	m._update_hud()


static func update_card(m: Node2D) -> void:
	if not bool(m.started):
		return
	var st := step(int(m.tut_step))
	if String(st.id) == "" or bool(m.finished):
		m.tut_label.visible = false
		m.tut_hint.visible = false
		return
	m.tut_label.visible = true
	m.tut_hint.visible = true
	m.tut_label.text = String(st.title)
	# the skip button is offered in the card's own prompt bar (event_feed.gd),
	# never written into the sentence
	m.tut_skippable = true
	m.tut_skip_label = skip_label(int(m.tut_step))
	m.tut_hint.text = Prompts.fill(String(st.body))
	# a green flash of acknowledgement as each lesson lands
	var glow: float = clampf(float(m.tut_flash), 0.0, 1.0)
	m.tut_label.modulate = Color(1, 1, 1).lerp(Color(0.6, 1.0, 0.65), glow)
