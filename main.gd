extends Node2D

# Path of Leash Resistance.
# You are the dog. Walk the phone-zombie human through it with the
# phone intact. Go touch grass.

# The walkable corridor. These used to be fixed constants, which is why
# every walk had identical proportions no matter how differently it was
# dressed. They are now derived from walk_cx/walk_half, so each level sets
# ONE width dial and both the pavement and the gameplay bounds follow: a
# tight medieval alley genuinely pinches, a station concourse genuinely
# opens out. (Set in _apply_corridor, per level.)
var sw_l := 300.0
var sw_r := 980.0
# The corridor's shape down the level: a short list of {y, cx, half} control
# nodes (edge_path.gd). Empty = the straight corridor sw_l..sw_r. Ask
# walk_edges(y) rather than sw_l/sw_r anywhere the answer depends on WHERE
# you are, or the path and the thing testing against it will disagree the
# moment a level bends.
var edge_nodes: Array = []
# parallel bike lane along the right side, plus a narrow far shoulder
# with temptations - crossing the lane is a voluntary risk
const BLANE_L := 988.0
const BLANE_R := 1072.0
const SHOULDER_R := 1100.0
const START_Y := 260.0
const GATE_Y := -5000.0
const PAIR_SPAWN_DIST := 560.0
const AUTOWALK_SEED := 0x5A17C0DE
const AUTOWALK_MIN_FINISH_TIME := 120.0
const PAIR_MIN_SPAWN_DIST := 360.0
const MAX_ACTIVE_PAIRS := 3
const LEASH_LENGTH := 340.0  # a proper 5-meter leash
# the frame the HUD is composed against; the live viewport is this grown along
# one axis (see _pin_wide and friends)
const REF_W := 1280.0
const REF_H := 720.0
const LEASH_STRETCH_CAP := 1.15
const LEASH_K := 32.0
const DOG_MASS := 1.0
const HUMAN_MASS := 4.0
const SwingMath := preload("res://swing.gd")
const Mood := preload("res://mood.gd")
const Surfaces := preload("res://surfaces.gd")
const EventFeed := preload("res://event_feed.gd")
const EdgePath := preload("res://edge_path.gd")
const TangleGeom := preload("res://tangle_geom.gd")
const POLE_RADIUS := 10.0
const TREE_RADIUS := 13.0  # a trunk is stouter than a lamppost
const HYDRANT_RADIUS := 9.0
const FOUNTAIN_RADIUS := 12.0
const PERFORMER_RADIUS := 12.0
const MANHOLE_RADIUS := 24.0
const BENCH_BODY_SIZE := Vector2(16.0, 48.0)
const VAN_BODY_SIZE := Vector2(64.0, 132.0)
const STALL_BODY_SIZE := Vector2(96.0, 56.0)
# chairs/tables/parasols share pole-radius bodies and leash POLE_PAD wraps;
# authored centres must clear both (2 * 13 + margin)
const FURNITURE_MIN_SEP := 28.0

const LANE_HALF := 70.0

const COL_GRASS := Color(0.32, 0.42, 0.3)
const COL_GRASS_DARK := Color(0.28, 0.37, 0.26)
const COL_SIDEWALK := Color(0.68, 0.66, 0.61)
const COL_SEAM := Color(0.6, 0.58, 0.53)
const COL_ROAD := Color(0.24, 0.24, 0.27)
const COL_STRIPE := Color(0.75, 0.72, 0.63)

var dog: CharacterBody2D
var human: CharacterBody2D
var leash: Node2D
var cam: Camera2D

var poles: Array[Vector2] = []
var manholes: Array[Vector2] = []
var hydrants: Array = []
var kebabs: Array = []
var tufts: Array[Vector2] = []
var trees: Array[Vector2] = []
var benches: Array[Vector2] = []
var cellars: Array[Rect2] = []
var tables: Array[Vector2] = []
var deco_pole_count := 0
var lane_state: Array = []
var vspawn_t := 2.5

# level identity: "street" or "park" (branch-based for now; extract a
# data-driven level system when the third setting arrives)
var lvl := "street"
var lane_ys: Array[float] = []
var pond := Rect2()
# Every body of water she can get into. `pond` is still the park's, because
# the prize and the NPC pairs' avoidance both reason about that one
# specifically, but the swimming, the wading owner and the skid at the edge
# all work off this list - which is how the beach gets a swimmable sea in two
# places at once, and how any later walk gets water for free.
var water: Array[Rect2] = []
var freedom_kind := "yard"
var dune_spots: Array[Vector2] = []
# THE FUR-GONETA: a mobile dog-grooming van, upholstered in shaggy fur, with
# ears on the front corners and a wet nose on the bonnet. An homage rather than
# a copy - our own name, our own livery - and to a dog it is the single most
# interesting object in the city, which is why it is worth a fortune to sniff.
var furgoneta := Vector2(INF, INF)
var furgoneta_sniffed := false
var freedomlayer: Node2D
var gate_text := "PARK"
var duck_ys: Array[float] = []
var ducks_disturbed := 0
# where the HUMAN's autopilot lives; the dog may roam anywhere between
# the outer walls, though an undistracted owner has opinions about it
var walk_cx := 640.0
var walk_half := 340.0
var gate_l := sw_l
var gate_r := sw_r
var tut_l := 220.0
var tut_r := 1160.0
var offpath_t := 0.0
# beach furniture
var towels: Array[Dictionary] = []
var parasols: Array[Vector2] = []
# the promenade palm ranks, kept so the paving cut-outs under them and the
# benches between them are placed from the same numbers (see the beach block)
var palm_spots: Array[Vector2] = []
var canopies: Array[Rect2] = []
# street furniture: chairs and A-stands share pole physics, vans are
# multi-circle colliders drawn as one vehicle, performers are pure life
var chairs: Array[Vector2] = []
var astands: Array[Vector2] = []
var vans: Array[Vector2] = []
var performers: Array[Vector2] = []
var cone_spots: Array[Vector2] = []
var stalls: Array[Vector2] = []
var fountains: Array[Vector2] = []
var body_pole_count := 0
var bypasser_blockers: Array[Dictionary] = []
var drunk_amount := 0.0
var swam := false
var night_cm: CanvasModulate
# the walk has three legs: out to the destination, an off-leash FREEDOM
# romp there, then the walk HOME. Reaching the gate is halfway, not the end.
var phase := "out"  # "out" | "freedom" | "home"
var gate_bench := Vector2(640, GATE_Y - 150)
# Furniture for the off-leash area. It was a bare green field, which is a
# waste of the one place in the game where the dog is free - so it gets
# things to climb, dig, drink from and sniff, spread wide so running around
# and exploring is rewarded rather than just running in a line.
var park_props: Array[Dictionary] = []
var digs_done := 0
# the teeter: the moment before you fall in (see teeter.gd)
var teeter: Node
var teeter_kind := ""
var teeter_at := Vector2.ZERO
var teeter_msg := ""
var teeter_cd := 0.0
# past this distance from the brink she has physically escaped it, whatever
# the balance meter thinks
const TEETER_ESCAPE_R := 34.0
# the nose: how far scent carries, at a dead run vs at an amble
const SCENT_REACH_MIN := 130.0
const SCENT_REACH_MAX := 430.0
# the tutorial walk (see tutorial.gd): one lesson at a time, all skippable
const TutorialSteps := preload("res://tutorial.gd")
const UiIcons := preload("res://ui_icons.gd")
var tutorial_mode := false
var tut_step := 0
var tut_flash := 0.0
var tut_start_y := 0.0
var tut_label: Label
var tut_hint: Label
# counters the tutorial checks against
var barks_done := 0
var grinds_landed := 0
var vaults_landed := 0
var rivals_beaten := 0
# the kerb grind (see grind.gd): ride the kerb line for style
var grind: Node
var grind_kerb_x := 0.0
var grind_cd := 0.0
# the owner's phone call: a long window of maximum slack (see _tick_call)
var call_active := false
var call_haul := 0
var call_slack_was := 340.0
# the leash-vault: swing around a wrapped pole and slingshot out
var vault_t := 0.0
var vault_cd := 0.0
var vault_arc := 0.0
var vault_pole := Vector2.ZERO
# the pole she last vaulted, and whether she has since cleared it. Without
# this she can sit in one pole's orbit re-triggering forever: the autowalk
# stall watchdog caught it, and it would also have been a score exploit
# (unlimited combo points from one lamppost).
var vault_done_pole := Vector2(INF, INF)
const VAULT_TRIGGER_SPEED := 200.0
const VAULT_MIN_SPEED := 210.0
const VAULT_MAX_SPEED := 430.0
const VAULT_LAUNCH := 470.0
const GRIND_SPEED := 190.0   # you have to be moving to get up on it
const GRIND_BAND := 13.0     # how close to the kerb line counts as on it
var ball: Node2D
var romp_timer := 0.0
var romp_catches := 0
var romp_target := 3
var romp_done := false
var tofu_quest_active := false
var tofu_home := false
var freedom_lo := GATE_Y - 620.0
const HOME_Y := 320.0
# the "outrun the sweeper" chase: a slow devourer that grinds down the
# corridor on the walk home. Slower than a pulling dog, faster than the
# owner's dawdle - keep moving or it eats the oblivious owner.
var chase_active := false
var chase_sweeper: Node2D
var chase_kind := "sweeper"  # "sweeper" (slow, drag the owner) or "bolt" (fast, owner drags you)
# El Gotic wall cats: perched temptations you shoo with a bark
var wallcat_spots: Array[Vector2] = []
var laundry_lines: Array[float] = []
var wall_cats_spooked := 0
# El Bosc: the owner keeps losing signal; muddy patches slow the going
var signal_prone := false
var mud_zones: Array[Rect2] = []
# Patches of something underfoot, as organic blobs that follow the path
# (see patch_has_point). Each carries its own substance kind, so a walk can
# have puddles, another wet cement, another spilled paint. The Rect2 list
# above is kept as their coarse bounds for culling and for the code that
# still only speaks rectangles.
var patches: Array[Dictionary] = []
# what sits on the grass either side of the walk (see _build_verge). Drawn on
# the cached edge canvas, because a lawn does not move.
var verge_items: Array[Dictionary] = []
# L'Estacio: a moving walkway that carries whoever stands on it
var conveyor_zone := Rect2()
var conveyor_dir := Vector2.ZERO
const CONV_SPEED := 118.0
const CAM_ZOOM := 1.28
# autowalk stall watchdog: how long a travelling leg may make no headway
# the goals card: wide enough that the longest goal name cannot spill out
const GOALS_X := 856.0
const GOALS_W := 416.0
const GOALS_MAX_ROWS := 7
const STALL_WINDOW := 13.0
const STALL_MIN_PROGRESS := 90.0
var _stall_t := 0.0
var _stall_last_y := 0.0
# Les Obres: wet cement that slows you and takes a trail of paw prints
var cement_zones: Array[Rect2] = []
# WHAT SHE IS TRACKING. Any dog owner knows the walk does not end at the
# door: whatever she stood in comes home with her, on the floor, on the
# furniture, and on you. Substances are data, so each walk can offer its own
# (mud in the woods, wet cement at the works, wet paint, beach sand, fish at
# the market, slush in the snow, festival confetti) and they all use one
# tracking, printing and smudging system.
const SUBSTANCES := {
	"mud":      {"col": Color(0.34, 0.26, 0.18), "life": 2.6, "quip": "MUDDY PAWS!"},
	"cement":   {"col": Color(0.62, 0.62, 0.60), "life": 2.5, "quip": "CEMENT PAWS!"},
	"paint":    {"col": Color(0.85, 0.30, 0.35), "life": 3.4, "quip": "WET PAINT!"},
	"sand":     {"col": Color(0.80, 0.72, 0.52), "life": 1.8, "quip": "SANDY PAWS!"},
	"fish":     {"col": Color(0.62, 0.68, 0.60), "life": 3.0, "quip": "FISHY PAWS!"},
	"slush":    {"col": Color(0.78, 0.82, 0.88), "life": 2.0, "quip": "SLUSHY PAWS!"},
	"confetti": {"col": Color(0.92, 0.55, 0.75), "life": 2.8, "quip": "COVERED IN CONFETTI!"},
	"oil":      {"col": Color(0.20, 0.19, 0.22), "life": 3.2, "quip": "OILY PAWS!"},
}
var substance_zones: Array[Dictionary] = []
var paw_prints: Array[Dictionary] = []
var paw_last := Vector2(INF, INF)
var wet_paws := 0.0
var paw_kind := "cement"
# ...and the owner has feet too. He walks through the same wet cement she
# does, and tracking it up the pavement without ever noticing is exactly
# what he would do. Same array, flagged as boots so it draws as a shoe.
var boot_last := Vector2(INF, INF)
var wet_boots := 0.0
var boot_kind := "cement"
# smudges she has left on her human, which is the actual joke
var owner_smudges: Array[Dictionary] = []
var smudges_left := 0
var smudge_cd := 0.0
var _scent_cache: Array = []
var _scent_cache_t := 0.0
var edge_layer: Node2D
# the verge scenery's own cached canvas. Cannot share the edge layer: that
# one is at z -5, behind the ground pass that would paint over it.
var verge_layer: Node2D
var _verge_drawn_y := 1.0e20
var _edge_drawn_y := 1.0e20
# La Castanyada: candy you must NOT eat (chocolate is poison to dogs)
var candy_spots: Array[Vector2] = []
var candy: Array[Dictionary] = []
var candy_eaten := 0
# El Desguas: stealth. Sleeping guard dogs (see guarddog.gd), sweeping
# security cameras and moving laser beams. Non-lethal - getting caught
# costs bones and dignity - but the ghost/unseen goals want a clean run.
var guard_posts: Array[Vector2] = []
var cameras: Array[Dictionary] = []
var lasers: Array[Dictionary] = []
var guards_woken := 0
var times_spotted := 0
const CHASE_SPEED := 140.0
const CHASE_SPEED_BOLT := 205.0
const CHASE_SPEED_BOTH := 220.0
const CHASE_START_GAP := 650.0
# goals completed this run (ids), for scoring/toasts/results independent
# of persistence; plus the star snapshot captured when the walk begins
var run_goals_hit := {}
var run_pre_total_stars := 0
var run_pre_level_stars := 0
# the hazardous hard-to-reach collectible, one per level
var prize_pos := Vector2(INF, INF)
var prize_text := "grab the prize"
var prize_taken := false
var prize_glow := 0.0
# carry / delivery mission: pick an item up in your mouth and take it to a
# marked drop-off. 0 = not yet picked up, 1 = carrying, 2 = delivered.
var carry_pickup := Vector2(INF, INF)
var carry_drop := Vector2(INF, INF)
var carry_state := 0
var carry_text := "make the delivery"
var carry_item := "the parcel"
const PAIR_PARK_SPOTS := [
	{"name": &"west_fence", "position": Vector2(240.0, GATE_Y - 120.0)},
	{"name": &"north_fence", "position": Vector2(430.0, GATE_Y - 260.0)},
	{"name": &"east_fence", "position": Vector2(1040.0, GATE_Y - 120.0)},
]
var auto_walk := false
var finished := false
var pair_spawn_t := 5.0
var park_pair_spawn_t := 5.0
var pair_park_slots := {}
var tangles := 0
var my_rope_sample: Array[Vector2] = []
var dogs_greeted := 0
var greeted := {}
# one group query per physics tick, shared by every cone, bird, duck and
# A-stand - thirty entities each asking the scene tree was the stutter
var riders_cache: Array = []
var critters_cache: Array = []
var birds_cache: Array = []
var hud_t := 0.0
var sq_spawn_t := 6.0
var whirl_arm := 0.0
var whirl_wind_acc := 0.0
var whirl_start_wind := 0.0
var whirl_flipped := false
var vault_recent := 0.0

var leash_len := LEASH_LENGTH
var leash_target := LEASH_LENGTH
var started := false
var bones := 0
var streak := 0
var phone_hp := 3
var pee := 1.0
var marks: Array[Vector2] = []
var puddles: Array[Dictionary] = []
# marks left by the OTHER dogs. A dog park is a noticeboard, so these are
# worth a sniff, and peeing over one is the whole point of being a dog.
var npc_marks: Array[Dictionary] = []
var overmarks := 0
var mark_progress := 0.0
var mark_target := Vector2(INF, INF)
var stray_t := 0.0
var mark_quest_done := false
var bins: Array[Vector2] = []
var bag_pending := false
var bag_flights: Array[Dictionary] = []
var cat_y := 0.0
var flock_ys: Array[float] = []

# per-walk counters feeding the rotating quests
var squirrels_chased := 0
var close_calls := 0
var sniffs_done := 0
var kebabs_eaten := 0
var saves_done := 0
var flings_done := 0
var dog_hits := 0
var active_quests: Array[Dictionary] = []
var poop_state := 0  # 0 not yet, 1 urge, 2 done, 3 forced telegraph, 4 forced squat
var urge_y := -2000.0
var urge_timer := 0.0
var squat_progress := 0.0
var business_spot := Vector2(INF, INF)
var elapsed := 0.0
var frozen := false
var shake_t := 0.0

var hud: CanvasLayer
var panel: Control
var goals_card: Control
# a goal landing opens the card for a moment even when it is collapsed:
# feedback without a permanent block of text in the corner
var goals_peek := 0.0
var results_card: Control
var results: Dictionary = {}
var weather_fx: Control
var menu_step := 0
var hud_status := ""
var title_l: Label
var sub_l: Label
var prompt_l: Label
var select_l: Label
var owner_l: Label
var night_l: Label
var weather_l: Label
var hint_l: Label
var record_l: Label
var shop_title_l: Label
var shop_l: Label
var shop_preview_bg: ColorRect
var shop_preview_l: Label
var shop_preview: CharacterBody2D
var in_shop := false
var shop_items: Array[Dictionary] = []
var shop_idx := 0
var prompt_tw: Tween
var msg_label: Label
var combo: Node
# the dog's mood: arrives from events, fades on its own, re-colours both the
# picture and the handling while it lasts (mood.gd)
var mood: Node
# the one channel for announcements about the state of the walk
var feed: Control
# latch for the run-yourself-empty trigger, so hitting empty is a moment
# rather than a condition (see _mood_ambient)
var mood_worn := false
# -1 for normal play; a Mood.M value when --mood= pins one on for photography
var mood_forced := -1
# floor between owner-event announcements at the dog (see owner_news)
var owner_news_cd := 0.0
var challenge: Node
var challenge_l: Label
var challenge_giver: Node2D
var challenge_offered := false
var dog_carrying := false
var paused := false
var pause_l: Label
var grade_rect: ColorRect
var _shot_done := false
var _shot_frames := 0
var _shot_at := 320
var _draw_cost_on := false
var _draw_us := 0
var _draw_n := 0
# scattered ground detail (cracks, litter, stones, stains) so hard surfaces
# stop reading as empty colour fields. Built with a LOCAL rng so it never
# perturbs the global seed the deterministic autowalk depends on.
var ground_detail: Array[Dictionary] = []
var in_progress_view := false
var progress_l: Label
var menu_hint_l: Label
var in_settings := false
var settings_idx := 0
var settings_panel: Control
var _redraw_acc := 0.0
# a neighbour's ball: a parked NPC owner throws one you can intercept and
# return to them for a shared-fetch bonus
var npc_ball: Node2D
var npc_ball_pair: Node2D
var daily_share := ""
var daily_copied := false
var combo_l: Label
var combo_bar: ColorRect
var combo_bar_bg: ColorRect
var dim: ColorRect
var font: Font


func _ready() -> void:
	Engine.time_scale = 1.0
	font = ThemeDB.fallback_font
	var autowalk_requested := "--autowalk" in OS.get_cmdline_user_args()
	if Game.is_daily(Game.level_id):
		# same layout, weather and time for everyone, all day
		Game.daily = true
		seed(Game.daily_seed())
		lvl = Game.daily_level()
		Game.weather = Game.daily_weather()
		Game.night = Game.daily_night()
	elif Game.is_tutorial(Game.level_id):
		# THE FIRST WALK: the boulevard's shape, but calm and safe by
		# construction - no traffic to dodge, no chase, no other walkers, and
		# a bright clear day. Nothing here can end your walk.
		Game.daily = false
		tutorial_mode = true
		lvl = "street"
		Game.weather = "clear"
		Game.night = false
	else:
		Game.daily = false
		if autowalk_requested:
			seed(AUTOWALK_SEED)
		lvl = Game.level_id
	# El Aguacero is always a downpour, whatever the weather selection says
	if lvl == "rain":
		Game.weather = "rain"
	# La Castanyada is always after dark
	if lvl == "spook":
		Game.night = true
	_setup_input()
	_build_level_data()
	_build_bypasser_blockers()
	_build_walls()
	_build_entities()
	_spawn_cones()
	_build_quests()
	_build_hud()
	_spawn_challenger()
	_spawn_wallcats()
	_spawn_guards()
	# day/night + weather: a canvas tint; HUD lives on a CanvasLayer,
	# unaffected
	night_cm = CanvasModulate.new()
	add_child(night_cm)
	night_cm.color = _weather_tint()
	# title screen holds the world until the player goes walkies;
	# headless runs (CI smoke test) start immediately
	if DisplayServer.get_name() == "headless":
		started = true
	else:
		frozen = true
	# --autowalk drives the dog through all three legs unattended, so CI
	# actually traverses out -> freedom -> home -> finish
	if autowalk_requested:
		auto_walk = true
		# the attract/CI bot cannot navigate clutter; let it glide through
		# so the full out->freedom->home->finish loop can be verified
		dog.collision_mask = 0
		human.collision_mask = 0
	# a short chase can strike on the walk home. Forced with --chase (slow
	# sweeper) or --bolt (fast, owner-panics variant); otherwise a seeded
	# chance and a coin-flip on which kind. It takes over the home leg, so
	# it and the Tofu herding are mutually exclusive.
	var args := OS.get_cmdline_user_args()
	var chase_forced := "--chase" in args
	var bolt_forced := "--bolt" in args
	var rescue_forced := "--rescue" in args
	chase_active = (chase_forced or bolt_forced or rescue_forced or (not auto_walk and not Game.daily and randf() < 0.25)) and not tutorial_mode
	if chase_active:
		tofu_quest_active = false
		if bolt_forced:
			chase_kind = "bolt"
		elif rescue_forced:
			chase_kind = "both"
		elif chase_forced:
			chase_kind = "sweeper"
		else:
			var r := randf()
			chase_kind = "sweeper" if r < 0.4 else ("bolt" if r < 0.75 else "both")
	_draw_cost_on = "--drawcost" in OS.get_cmdline_user_args()
	menu_step = Game.menu_step
	_apply_menu_step()
	# --at-freedom drops her straight into the off-leash space. Walking there
	# takes half a minute of real time per look, which is no way to iterate on
	# how the dog beach or the clearing is drawn.
	if "--at-freedom" in OS.get_cmdline_user_args():
		started = true
		frozen = false
		dog.global_position = Vector2(640.0, GATE_Y - 260.0)
		human.global_position = Vector2(640.0, GATE_Y - 120.0)
		cam.position = dog.global_position
		_enter_freedom()
	Sfx.start_music()
	# --selftest: validate the level we just built and exit. Runs inside the
	# real runtime (autoloads and all), so CI can sweep every walk for
	# content mistakes a pure-logic test cannot see.
	if "--selftest" in OS.get_cmdline_user_args():
		var problems: Array = load("res://level_check.gd").check(self)
		problems.append_array(_check_settings_roundtrip())
		for pr in problems:
			print("SELFTEST FAIL [%s] %s" % [lvl, pr])
		if problems.is_empty():
			print("SELFTEST OK [%s]" % lvl)
		get_tree().quit(1 if not problems.is_empty() else 0)


func _setup_input() -> void:
	if InputMap.has_action("plant"):
		return
	var moves := {
		"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN],
	}
	for action in moves:
		InputMap.add_action(action)
		for k in moves[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = k
			InputMap.action_add_event(action, ev)
	var axes := {
		"move_left": [JOY_AXIS_LEFT_X, -1.0], "move_right": [JOY_AXIS_LEFT_X, 1.0],
		"move_up": [JOY_AXIS_LEFT_Y, -1.0], "move_down": [JOY_AXIS_LEFT_Y, 1.0],
	}
	for action in axes:
		var ev := InputEventJoypadMotion.new()
		ev.axis = axes[action][0]
		ev.axis_value = axes[action][1]
		InputMap.action_add_event(action, ev)
	var buttons := {
		"plant": [KEY_SPACE, JOY_BUTTON_A], "bark": [KEY_E, JOY_BUTTON_B],
		"pee": [KEY_Q, JOY_BUTTON_X], "turbo": [KEY_SHIFT, JOY_BUTTON_RIGHT_SHOULDER],
		"restart": [KEY_R, JOY_BUTTON_START], "share": [KEY_C, JOY_BUTTON_Y],
		"pause": [KEY_ESCAPE, JOY_BUTTON_BACK], "mute_music": [KEY_M, JOY_BUTTON_LEFT_SHOULDER],
		"goals": [KEY_TAB, JOY_BUTTON_DPAD_UP],
	}
	for action in buttons:
		InputMap.add_action(action)
		var evk := InputEventKey.new()
		evk.physical_keycode = buttons[action][0]
		InputMap.action_add_event(action, evk)
		var evb := InputEventJoypadButton.new()
		evb.button_index = buttons[action][1]
		InputMap.action_add_event(action, evb)


func _apply_corridor() -> void:
	# ONE width dial per walk. This is what makes the levels stop feeling
	# like the same street redressed: a medieval alley that genuinely
	# pinches, a station concourse that genuinely opens out. It moves the
	# gameplay bounds and the pavement together, and narrow corridors are
	# mechanically harder - less room to thread a distracted owner past a
	# lamppost.
	var half := 340.0
	match lvl:
		"street": half = 340.0   # a proper boulevard
		"park": half = 300.0     # a dirt path through grass
		"beach": half = 340.0    # bespoke cross-section, left alone
		"rain": half = 320.0
		"market": half = 270.0   # stalls crowd the aisle
		"oldtown": half = 225.0  # the tightest: a medieval alley
		"trail": half = 250.0    # a single-file woodland trail
		"station": half = 390.0  # the widest: an open concourse
		"site": half = 295.0     # squeezed by the works
		"spook": half = 275.0
		"scrap": half = 305.0
		"guell": half = 300.0   # terraces, wide enough to carve on
	walk_cx = 640.0
	walk_half = half
	sw_l = walk_cx - walk_half
	sw_r = walk_cx + walk_half
	# The SHAPE of the corridor, on top of its width. Empty means a straight
	# pair of vertical lines at exactly sw_l/sw_r, which is what most levels
	# still are. See edge_path.gd; walk_edges(y) is what everything should ask.
	edge_nodes = []
	if lvl == "guell":
		# EL PARC. The serpentine, and the point of the whole level: Gaudi did
		# not draw a straight line and neither does this path. It is a longer,
		# deeper weave than El Bosc's - a bench terrace that swings right
		# across the level and back, so carving it is the walk.
		#
		# Kept inside the slope the self-test allows (0.85) so it can be run
		# rather than merely admired, and both ends sit centred so the start
		# line and the gate still line up.
		edge_nodes = [
			{"y": START_Y, "cx": 640.0, "half": 300.0},
			{"y": -700.0, "cx": 486.0, "half": 292.0},
			{"y": -1500.0, "cx": 792.0, "half": 268.0},
			{"y": -2300.0, "cx": 470.0, "half": 300.0},
			{"y": -3100.0, "cx": 806.0, "half": 262.0},
			{"y": -3900.0, "cx": 520.0, "half": 296.0},
			{"y": -4600.0, "cx": 700.0, "half": 300.0},
			{"y": GATE_Y, "cx": 640.0, "half": 300.0},
		]
	elif lvl == "trail":
		# EL BOSC BENDS - the first walk in the game that is not a straight
		# line. A woodland trail has no business being ruler-drawn: it wanders
		# either side of the centre and pinches where the trees close in, which
		# makes the single-file stretch an actual place rather than a number.
		#
		# It went first because it has no building frontage and no wall
		# blockers, so the bend has only the pavement, the props and the mud to
		# agree with - and all three read walk_edges now, the mud as a band
		# (see band_x) rather than as a rectangle that would hang off the
		# outside of every curve. Both ends sit dead centre at the level's
		# nominal width so the start line and the gate still line up.
		edge_nodes = [
			{"y": START_Y, "cx": 640.0, "half": 250.0},
			{"y": -900.0, "cx": 566.0, "half": 250.0},
			{"y": -2000.0, "cx": 716.0, "half": 212.0},   # the pinch
			{"y": -3100.0, "cx": 578.0, "half": 246.0},
			{"y": -4200.0, "cx": 668.0, "half": 250.0},
			{"y": GATE_Y, "cx": 640.0, "half": 250.0},
		]


func _fit_x(x: float, lo: float, hi: float) -> float:
	var f := clampf((x - 300.0) / 680.0, 0.0, 1.0)
	return lerpf(lo, hi, f)


func _fit_props_to_corridor() -> void:
	# Props were all authored for the old fixed 300..980 corridor, so a
	# narrower walk would leave them stranded out on the verge. Pull every
	# placed prop back inside whatever corridor this level declared, keeping
	# its side of the path. The beach is exempt: its sand/boardwalk/bike-path
	# cross-section deliberately places things outside the walkway.
	if lvl == "beach":
		return
	# Fitted at each prop's OWN y, so a bend in the path carries its lampposts
	# and bins around with it. Against the straight sw_l/sw_r a curved street
	# would leave a trail of furniture standing out on the grass where the path
	# used to be.
	var pad := 26.0
	for arr in [poles, tables, chairs, parasols, astands, vans, stalls, bins,
			benches, performers, cone_spots, manholes, wallcat_spots,
			guard_posts, candy_spots, fountains]:
		for i in range(arr.size()):
			var p: Vector2 = arr[i]
			var e := walk_edges(p.y)
			# remap proportionally so left-side props stay left, right stay right
			arr[i] = Vector2(_fit_x(p.x, e.x + pad, e.y - pad), p.y)
	# the dictionary-based pickups need the same treatment
	for list in [hydrants, kebabs, candy]:
		for d in list:
			var dp: Vector2 = d.pos
			var de := walk_edges(dp.y)
			d.pos = Vector2(_fit_x(dp.x, de.x + pad, de.y - pad), dp.y)
	# FUR-GONETA is authored against sw_l/sw_r already, so it is not remapped
	# here. Its rope flanks are appended after this fit from that same centre.


func _build_level_data() -> void:
	_apply_corridor()
	var hyd_list: Array[Vector2] = []
	var keb_list: Array[Vector2] = []
	# a couple of walks reuse a proven layout as a base for now (bespoke
	# geometry is a later pass) and re-theme it below: El Aguacero on the
	# boulevard, El Gotic on the stall-lined market channel.
	var geo := lvl
	if lvl == "rain" or lvl == "station" or lvl == "site" or lvl == "scrap":
		geo = "street"
	elif lvl == "oldtown" or lvl == "spook":
		geo = "market"
	elif lvl == "trail" or lvl == "guell":
		geo = "park"
	match geo:
		"street":
			lane_ys = [-1200.0, -2600.0, -4000.0]
			gate_text = "PARK"
			for i in range(7):
				var x := sw_l + 30.0 if i % 2 == 0 else sw_r - 30.0
				var y := -350.0 - i * 640.0
				var near_lane := false
				for ly in lane_ys:
					if absf(y - ly) < LANE_HALF + 60.0:
						near_lane = true
				if not near_lane:
					poles.append(Vector2(x, y))
			for mp in [Vector2(640, -1750), Vector2(700, -2900), Vector2(580, -4250)]:
				poles.append(mp)
			# a slalom line of street trees mid-walkway (in grates)
			for sl in [Vector2(590, -1880), Vector2(710, -2010), Vector2(590, -2140), Vector2(710, -2270)]:
				poles.append(sl)
			deco_pole_count = poles.size()
			# cafe terrace: tables join the poles array so they block
			# bodies and snag the leash, but they are drawn as tables.
			# Chairs and umbrellas make it properly hard to thread a dog
			# through, as in life.
			# cafe terrace: keep wrap/body centres >= FURNITURE_MIN_SEP so
			# chair and parasol colliders cannot nest under tension
			tables = [Vector2(760, -3560), Vector2(840, -3660), Vector2(700, -3700), Vector2(790, -3780)]
			chairs = [
				Vector2(725, -3535), Vector2(830, -3570), Vector2(872, -3690),
				Vector2(700, -3775), Vector2(670, -3672), Vector2(815, -3820),
			]
			parasols = [Vector2(800, -3610), Vector2(745, -3740)]
			# off the crossing lanes, by the shopfronts where they belong
			astands = [Vector2(365, -1600), Vector2(915, -2850), Vector2(372, -4330)]
			# a delivery van parked half on the walkway, as they do
			vans = [Vector2(890, -3050)]
			performers = [Vector2(400, -1550)]
			cone_spots = [Vector2(858, -2975), Vector2(920, -3130)]
			manholes = [
				Vector2(560, -700), Vector2(760, -950), Vector2(480, -1700),
				Vector2(700, -2100), Vector2(600, -3100), Vector2(820, -3450),
				Vector2(520, -4400),
			]
			cellars = [
				Rect2(sw_l, -2750, 62, 88), Rect2(sw_r - 62, -750, 62, 82),
				Rect2(sw_l, -4550, 62, 88),
			]
			bins = [
				Vector2(sw_l + 30, -600), Vector2(sw_r - 30, -1400),
				Vector2(sw_l + 30, -2150), Vector2(sw_r - 30, -3000),
				Vector2(sw_l + 30, -3700), Vector2(sw_r - 30, -4700),
			]
			benches = [Vector2(336, -1300), Vector2(944, -2450), Vector2(336, -3850)]
			hyd_list = [
				Vector2(sw_l + 45, -500), Vector2(sw_r - 45, -1500),
				Vector2(sw_l + 45, -2300), Vector2(sw_r - 45, -3300),
				Vector2(sw_l + 45, -4600),
				Vector2(SHOULDER_R - 12, -1000), Vector2(SHOULDER_R - 12, -3600),
			]
			keb_list = [Vector2(640, -1960), Vector2(700, -4200), Vector2(SHOULDER_R - 12, -2400)]
		"park":
			gate_text = "HOME"
			# the pond bites into the path; the strip past it is the bridge
			pond = Rect2(sw_l, -2950, 360, 470)
			duck_ys = [randf_range(-2200.0, -1400.0), randf_range(-4300.0, -3400.0)]
			for i in range(7):
				var x := sw_l + 30.0 if i % 2 == 0 else sw_r - 30.0
				var y := -350.0 - i * 640.0
				if not pond.grow(40.0).has_point(Vector2(x, y)):
					poles.append(Vector2(x, y))
			for mp in [Vector2(640, -1750), Vector2(700, -2900), Vector2(580, -4250)]:
				if not pond.grow(40.0).has_point(mp):
					poles.append(mp)
			# a tree slalom on the path, and repair cones by the bridge
			for sl in [Vector2(570, -1150), Vector2(690, -1280), Vector2(570, -1410), Vector2(690, -1540)]:
				poles.append(sl)
			deco_pole_count = poles.size()
			astands = [Vector2(350, -2050)]
			cone_spots = [Vector2(720, -2500), Vector2(700, -2960)]
			bins = [
				Vector2(sw_l + 30, -600), Vector2(sw_r - 30, -1400),
				Vector2(sw_l + 30, -2150), Vector2(sw_r - 30, -3000),
				Vector2(sw_l + 30, -3700), Vector2(sw_r - 30, -4700),
			]
			benches = [Vector2(336, -1300), Vector2(944, -2450), Vector2(336, -3850), Vector2(944, -1900)]
			hyd_list = [
				Vector2(sw_l + 45, -500), Vector2(sw_r - 45, -1500),
				Vector2(sw_l + 45, -2300), Vector2(sw_r - 45, -3300),
				Vector2(sw_l + 45, -4600),
			]
			keb_list = [Vector2(620, -1900), Vector2(700, -4200)]
		"beach":
			# Passeig Maritim: sea | sand | boardwalk | bike path |
			# pavement | palms and cafe terraces. The human walks the
			# pavement; the dog walks wherever a dog walks.
			gate_text = "HOME"
			walk_cx = 770.0
			walk_half = 210.0
			gate_l = 560.0
			gate_r = 980.0
			tut_l = 110.0
			tut_r = 1160.0
			# SAND ON THE PAVING. The most characteristic thing about a seafront
			# walk, and the beach had a ruler-straight sand edge with nothing
			# crossing it. Wind and feet carry it inland in tongues that thin
			# out the further they get from the beach, so these run from the
			# sand side and reach in - never across, because a promenade you
			# cannot get a clean line down is a chore rather than a walk.
			#
			# They are real SAND underfoot (surfaces.gd): heavy going, poor
			# grip, and they mark her paws, which feeds the existing substance
			# chain for free. Weaving to keep off them is the whole point.
			patches = [
				{"y": -620.0, "at": 0.02, "rx": 104.0, "ry": 58.0, "seed": 1.7, "kind": "sand"},
				{"y": -1340.0, "at": 0.10, "rx": 86.0, "ry": 48.0, "seed": 3.4, "kind": "sand"},
				{"y": -2180.0, "at": 0.04, "rx": 118.0, "ry": 64.0, "seed": 5.1, "kind": "sand"},
				{"y": -2960.0, "at": 0.14, "rx": 78.0, "ry": 44.0, "seed": 0.9, "kind": "sand"},
				{"y": -3720.0, "at": 0.06, "rx": 110.0, "ry": 60.0, "seed": 2.6, "kind": "sand"},
				{"y": -4380.0, "at": 0.12, "rx": 92.0, "ry": 52.0, "seed": 4.3, "kind": "sand"},
			]
			# PALMS IN ORDERLY SECTIONS, cut into the paving - exactly how the
			# promenade is planted, and nothing like the six-per-row scattering
			# this had. Two regular ranks at a proper street-tree spacing, kept
			# at the edges of the walk because that is where street trees go and
			# because a rank down the middle would choke a 420px corridor.
			#
			# Kept in their own list as well as in poles, so the paving cut-outs
			# and the benches between them are placed from the same numbers
			# rather than from a second copy that could drift.
			palm_spots.clear()
			for i in range(17):
				palm_spots.append(Vector2(462.0, -260.0 - i * 300.0))
			for i in range(15):
				palm_spots.append(Vector2(1012.0, -380.0 - i * 340.0))
			for ps: Vector2 in palm_spots:
				poles.append(ps)
			# long benches facing the sea, set between the seaward palms on the
			# concrete - the promenade is lined with them
			for i in range(16):
				benches.append(Vector2(524.0, -410.0 - i * 300.0))
			deco_pole_count = poles.size()
			# terrace tables under canopies, twice along the route
			tables = [
				Vector2(1040, -1500), Vector2(1110, -1560), Vector2(1050, -1620), Vector2(1120, -1680),
				Vector2(1040, -3300), Vector2(1110, -3360), Vector2(1050, -3420), Vector2(1120, -3480),
			]
			canopies = [Rect2(1015, -1710, 135, 240), Rect2(1015, -3510, 135, 240)]
			chairs = [
				Vector2(1075, -1470), Vector2(1020, -1560), Vector2(1090, -1640),
				Vector2(1075, -3270), Vector2(1020, -3360), Vector2(1090, -3440),
			]
			astands = [Vector2(600, -1450), Vector2(966, -3250)]
			vans = [Vector2(930, -4050)]
			performers = [Vector2(410, -2200)]
			cone_spots = [Vector2(492, -1500), Vector2(548, -3050)]
			# parasols are poles too: windable, markable, brilliant
			parasols = [Vector2(268, -900), Vector2(300, -2300), Vector2(262, -3700), Vector2(330, -4500)]
			var towel_cols := [Color(0.85, 0.4, 0.35), Color(0.35, 0.55, 0.8), Color(0.9, 0.75, 0.3), Color(0.5, 0.7, 0.5)]
			var ty := -800.0
			for i in range(5):
				towels.append({
					"rect": Rect2(randf_range(248.0, 330.0), ty, 46, 80),
					"col": towel_cols[i % 4], "bather": i % 2 == 0, "cd": 0.0,
				})
				ty -= randf_range(700.0, 1000.0)
			bins = [
				Vector2(590, -700), Vector2(950, -1600), Vector2(590, -2500),
				Vector2(950, -3400), Vector2(590, -4300),
			]
			benches = [Vector2(410, -1200), Vector2(410, -2800), Vector2(410, -4200)]
			hyd_list = [
				Vector2(578, -1000), Vector2(950, -2200), Vector2(578, -3200), Vector2(950, -4500),
			]
			keb_list = [Vector2(700, -1900), Vector2(860, -4200), Vector2(420, -3000)]
			fountains = [Vector2(420, -1300), Vector2(1005, -3550)]
		"market":
			# El Mercat: stalls line both edges, produce underfoot, the
			# cat is practically guaranteed (fish)
			gate_text = "PLAZA"
			stalls = [
				Vector2(370, -800), Vector2(910, -1150), Vector2(370, -1750),
				Vector2(910, -2300), Vector2(370, -2900), Vector2(910, -3500),
				Vector2(370, -4150), Vector2(910, -4650),
			]
			for i in range(7):
				var x := sw_l + 30.0 if i % 2 == 0 else sw_r - 30.0
				var lp := Vector2(x, -350.0 - i * 640.0)
				var clear := true
				for st in stalls:
					if absf(st.x - lp.x) < 75.0 and absf(st.y - lp.y) < 65.0:
						clear = false
				if clear:
					poles.append(lp)
			deco_pole_count = poles.size()
			manholes = [Vector2(640, -2050), Vector2(560, -3800)]
			bins = [
				Vector2(330, -1400), Vector2(950, -2700),
				Vector2(330, -3300), Vector2(950, -4400),
			]
			benches = [Vector2(336, -2450), Vector2(944, -3850)]
			astands = [
				Vector2(440, -880), Vector2(840, -1230), Vector2(440, -2980), Vector2(840, -3580),
			]
			performers = [Vector2(640, -2600), Vector2(400, -4400)]
			cone_spots = [Vector2(600, -1990), Vector2(690, -2110)]
			fountains = [Vector2(640, -3100)]
			# 5, not 3: the "4 good sniffs" goal on this layout (and on El
			# Gotic / La Castanyada, which inherit it) was impossible to
			# complete with only three hydrants. Caught by --selftest.
			hyd_list = [
				Vector2(345, -600), Vector2(935, -1900), Vector2(345, -3600),
				Vector2(935, -2900), Vector2(345, -4400),
			]
			keb_list = [
				Vector2(500, -900), Vector2(780, -1250), Vector2(620, -1800),
				Vector2(540, -2380), Vector2(760, -3000), Vector2(600, -3650),
				Vector2(820, -4250), Vector2(480, -4550),
			]
	if lvl == "street":
		fountains = [Vector2(335, -3350)]
	elif lvl == "park":
		fountains = [Vector2(944, -3300), Vector2(724, -2440)]
	elif lvl == "rain":
		# El Aguacero: get-out-of-the-rain gate, storm drains gaping open
		# down the middle of the road (open holes, lethal in a downpour),
		# a huddle of umbrella-toting pedestrians clogging the walkway, and
		# a fountain nobody needs today
		gate_text = "SHELTER"
		manholes.append_array([Vector2(640, -1500), Vector2(600, -2650), Vector2(680, -3900)])
		# a huddle of umbrellas clogging the walkway - dense enough to make
		# you thread it, with gaps left so it is never a wall
		performers.append_array([
			Vector2(500, -2250), Vector2(790, -2320),
			Vector2(560, -3560), Vector2(760, -3520),
		])
		fountains = [Vector2(335, -3350)]
	elif lvl == "oldtown":
		# El Gotic: a tight medieval alley. Wall cats perched on ledges up
		# both walls, laundry strung overhead, lanterns. Extra poles pinch
		# the channel so threading the owner through is the real work.
		gate_text = "PLACA"
		wallcat_spots = [
			Vector2(360, -900), Vector2(920, -1450), Vector2(360, -2100),
			Vector2(920, -2750), Vector2(360, -3350), Vector2(920, -3950),
		]
		laundry_lines = [-1250.0, -2000.0, -2850.0, -3650.0, -4300.0]
		for yy in [-1150.0, -1700.0, -2500.0, -3200.0, -3800.0, -4400.0]:
			poles.append(Vector2(walk_cx + (70.0 if int(yy) % 2 == 0 else -70.0), yy))
		fountains = [Vector2(345, -2600.0)]
	elif lvl == "trail":
		# El Bosc: a forest trail. No bars out here, so the owner is forever
		# stopping to hunt for a signal (see human.gd); muddy patches slow
		# the going, and a stream to drink from. Calm, stop-start rhythm.
		gate_text = "CLEARING"
		signal_prone = true
		# each patch spans the trail where the trail actually IS. A Rect2 cannot
		# bend, so it is measured at the middle of its own band - close enough
		# for a puddle, and far better than three rectangles pinned to where a
		# straight path used to be
		# PUDDLES, not a band across the whole trail. A full-width strip is a
		# wall you have to cross; puddles are things you weave between, which
		# is both more interesting to walk and more like a wood after rain.
		# Placed in pairs so a stretch reads as boggy rather than as one
		# tidy pool, and offset across the path so a careful line gets through.
		patches = [
			{"y": -1520.0, "at": 0.28, "rx": 84.0, "ry": 46.0, "seed": 1.10, "kind": "mud"},
			{"y": -1660.0, "at": 0.66, "rx": 70.0, "ry": 40.0, "seed": 2.40, "kind": "mud"},
			{"y": -2860.0, "at": 0.72, "rx": 92.0, "ry": 52.0, "seed": 3.75, "kind": "mud"},
			{"y": -3010.0, "at": 0.34, "rx": 66.0, "ry": 38.0, "seed": 5.02, "kind": "mud"},
			{"y": -4080.0, "at": 0.46, "rx": 100.0, "ry": 54.0, "seed": 0.62, "kind": "mud"},
			{"y": -4220.0, "at": 0.82, "rx": 58.0, "ry": 34.0, "seed": 4.18, "kind": "mud"},
		]
		fountains = [Vector2(360.0, -2400.0)]
	elif lvl == "station":
		# L'Estacio: a concourse with a moving walkway. On it you get carried
		# toward the platforms (north) - a boost on the way out, a shove to
		# fight on the way home. Luggage carts clutter the floor.
		gate_text = "PLATFORM"
		conveyor_zone = Rect2(walk_cx - 90.0, -3400.0, 180.0, 1500.0)
		conveyor_dir = Vector2(0, -1)
		vans = [Vector2(380, -1500), Vector2(900, -2600), Vector2(400, -4200)]
		fountains = [Vector2(1005, -3550)]
	elif lvl == "spook":
		# La Castanyada: the autumn festival at night. Sweets everywhere -
		# and here's the cruelty: chocolate is poison to dogs, so the one
		# thing you want most is the one thing you must NOT eat. Steer past
		# the candy strewn across your path; real treats are still fair game.
		gate_text = "PLACA"
		candy_spots = [
			Vector2(560, -1100), Vector2(700, -1400), Vector2(600, -1750),
			Vector2(720, -2200), Vector2(560, -2600), Vector2(690, -2950),
			Vector2(600, -3400), Vector2(720, -3800), Vector2(560, -4200),
		]
		performers.append_array([Vector2(400, -2100), Vector2(880, -3300)])
	elif lvl == "site":
		# Les Obres: a roadworks detour. Wet cement laid across the walkway
		# slows you AND takes a paw-print trail that follows you the rest of
		# the walk (the evidence). Extra cones and a parked works van.
		gate_text = "DETOUR"
		# WET CEMENT, poured in patches rather than laid across the whole
		# footway. A full-width slab is a wall with a paint penalty; poured
		# patches are a line to pick through, and a works that has done half a
		# job is more like a real works anyway. Same primitive as El Bosc's
		# puddles - only the substance differs, which is the point of it.
		cement_zones = []
		patches = [
			{"y": -1660.0, "at": 0.24, "rx": 96.0, "ry": 54.0, "seed": 2.05, "kind": "cement"},
			{"y": -1810.0, "at": 0.70, "rx": 78.0, "ry": 46.0, "seed": 4.60, "kind": "cement"},
			{"y": -3290.0, "at": 0.62, "rx": 104.0, "ry": 58.0, "seed": 1.35, "kind": "cement"},
			{"y": -3460.0, "at": 0.30, "rx": 72.0, "ry": 42.0, "seed": 5.85, "kind": "cement"},
		]
		cone_spots = [Vector2(520, -1650), Vector2(760, -1650), Vector2(560, -2020), Vector2(720, -2020), Vector2(600, -3250), Vector2(700, -3650)]
		vans = [Vector2(900, -2500)]
		fountains = [Vector2(335, -4200)]
	elif lvl == "guell":
		# El Parc: Gaudi's terraces. Broken-tile mosaic underfoot, which is
		# fast and slippery to run on, laid in organic sweeps rather than
		# slabs - the patch primitive was already the right shape for it.
		gate_text = "TERRACE"
		# It inherits the park's cross-section, which brings the park's pond
		# with it - and the pond is authored against a STRAIGHT corridor, so on
		# a serpentine it ends up swallowing whatever the path now runs over.
		# The self-test caught a fountain and a cone standing in it. The
		# terraces do their water as a fountain instead.
		pond = Rect2()
		patches = [
			{"y": -640.0, "at": 0.44, "rx": 150.0, "ry": 86.0, "seed": 1.42, "kind": "tile"},
			{"y": -1460.0, "at": 0.56, "rx": 168.0, "ry": 94.0, "seed": 3.07, "kind": "tile"},
			{"y": -2280.0, "at": 0.40, "rx": 158.0, "ry": 90.0, "seed": 4.61, "kind": "tile"},
			{"y": -3080.0, "at": 0.60, "rx": 174.0, "ry": 98.0, "seed": 0.88, "kind": "tile"},
			{"y": -3880.0, "at": 0.46, "rx": 156.0, "ry": 88.0, "seed": 2.35, "kind": "tile"},
		]
		fountains = [Vector2(walk_cx - 150.0, -2650.0)]
	elif lvl == "scrap":
		# El Desguas: the scrapyard shortcut. Sleeping guard dogs, sweeping
		# cameras, laser tripwires - and your stealth partner is a glowing,
		# ringing phone zombie on the other end of the rope. Slow is silent;
		# getting caught is embarrassing, not fatal.
		gate_text = "BACK GATE"
		guard_posts = [
			Vector2(380, -1350), Vector2(900, -2250),
			Vector2(390, -3150), Vector2(880, -4050),
		]
		cameras = [
			{"pos": Vector2(330, -1900), "base": 0.0, "range": 0.9, "speed": 0.7, "cd": 0.0},
			{"pos": Vector2(950, -3500), "base": PI, "range": 0.9, "speed": 0.55, "cd": 0.0},
		]
		lasers = [
			{"x0": sw_l, "x1": sw_r, "y_lo": -2750.0, "y_hi": -2550.0, "speed": 1.1, "cd": 0.0},
			{"x0": sw_l, "x1": sw_r, "y_lo": -4450.0, "y_hi": -4250.0, "speed": 0.8, "cd": 0.0},
		]
		# scrap heaps: wrecked cars (vans) and junk drums (cones)
		vans = [Vector2(880, -1600), Vector2(390, -2650), Vector2(900, -4400)]
		cone_spots = [Vector2(560, -1950), Vector2(720, -3050), Vector2(600, -3900)]
		fountains = [Vector2(1005, -2950)]
	if tutorial_mode:
		# Take away everything that can hurt, keep everything worth learning.
		# This has to run BEFORE the shared setup below consumes hyd_list /
		# keb_list and builds lane_state from lane_ys - doing it later left a
		# populated lane_state indexing an emptied lane_ys, which is exactly
		# the out-of-bounds it produced.
		lane_ys = []
		lane_state = []
		manholes = []
		cellars = []
		vans = []
		astands = []
		performers = []
		# a generous supply of practice apparatus, spread out and unhurried
		hyd_list = [Vector2(360.0, -700.0), Vector2(915.0, -1250.0), Vector2(360.0, -1900.0)]
		keb_list = [Vector2(640.0, -1500.0), Vector2(700.0, -2400.0)]
		poles.append(Vector2(500.0, -2100.0))
		poles.append(Vector2(790.0, -2750.0))
		deco_pole_count = poles.size()
	for tb in tables:
		poles.append(tb)
	for pa in parasols:
		poles.append(pa)
	for ch in chairs:
		poles.append(ch)
	# trash bins: bag deposit targets for the owner's chore chain; they
	# also join the poles array, so they block bodies, snag the leash,
	# and can absolutely be marked
	for bn in bins:
		poles.append(bn)
	# everything past body_pole_count is rope-wrap geometry only: vans
	# and stalls get one solid rectangular body each in _build_walls
	body_pole_count = poles.size()
	for v in vans:
		for off in [-52.0, -26.0, 0.0, 26.0, 52.0]:
			poles.append(v + Vector2(0, off))
	# stall wrap circles at the ENDS only: a mid circle made the rope
	# snake weirdly across the tabletop
	for st in stalls:
		poles.append(st + Vector2(-48, 0))
		poles.append(st + Vector2(48, 0))
	urge_y = randf_range(-3200.0, -1500.0)
	# rare visitors: a cat some walks, a pigeon flock or two most walks
	# (seagulls at the beach, obviously)
	var cat_p := 0.3
	if lvl == "park":
		cat_p = 0.4
	elif lvl == "market":
		cat_p = 0.75
	if randf() < cat_p:
		cat_y = randf_range(-4200.0, -1200.0)
	flock_ys = [randf_range(-1800.0, -800.0), randf_range(-4400.0, -2600.0)]
	if lvl != "street":
		flock_ys.insert(1, randf_range(-2600.0, -1900.0))
	for hp in hyd_list:
		if pond.size.x > 0.0 and pond.grow(30.0).has_point(hp):
			continue
		hydrants.append({"pos": hp, "done": false, "progress": 0.0})
	for kp in keb_list:
		kebabs.append({"pos": kp, "eaten": false})
	for cp in candy_spots:
		candy.append({"pos": cp, "eaten": false})
	_build_ground_detail()
	_build_freedom_area()
	_lift_props_out_of_water()
	# after the water and the holes are known, so a puddle cannot end up in
	# the pond and cement cannot be poured over a manhole
	_settle_patches()
	_build_dunes()
	_build_park_props()
	for i in range(140):
		var side := -1.0 if randf() < 0.5 else 1.0
		var x := 640.0 + side * randf_range(340.0, 620.0)
		tufts.append(Vector2(x, randf_range(GATE_Y - 600.0, START_Y + 150.0)))
	# The grove in the off-leash space. Fourteen is right for a park; a beach
	# with fourteen palms in it is a plantation, and the woods want more than a
	# park does. These are rope-wrap geometry as well as scenery, so the count
	# changes what the space plays like, not just what it looks like.
	# The clearing is ringed with woodland. Placed here rather than drawn as
	# scenery so it is solid, wraps the rope, and reads as the edge of a wood
	# you cannot simply walk out of.
	if freedom_kind == "clearing":
		var fr := _freedom_rect()
		for i in range(14):
			var f := float(i) / 13.0
			var edge := i % 3
			var tp := Vector2.ZERO
			match edge:
				0: tp = Vector2(lerpf(fr.position.x + 40.0, fr.end.x - 40.0, f), fr.position.y + 34.0)
				1: tp = Vector2(fr.position.x + 46.0, lerpf(fr.position.y + 60.0, fr.end.y - 60.0, f))
				_: tp = Vector2(fr.end.x - 46.0, lerpf(fr.position.y + 60.0, fr.end.y - 60.0, f))
			trees.append(tp)
	var grove := 14
	# Where they can stand at all. Palms do not grow in the sea or halfway down
	# a beach - they line the back of it - and a clearing is a clearing because
	# the middle of it is empty. The grove is rope-wrap geometry too, so this
	# decides how the space plays as well as how it looks.
	var grove_lo := 200.0
	var grove_hi := 1080.0
	match freedom_kind:
		"beach":
			grove = 5
			grove_lo = 800.0     # the back of the beach, inland of the dry sand
			grove_hi = 1060.0
		"clearing":
			grove = 10           # plus the ring the clearing draws
		"lot":
			grove = 6
			grove_lo = 150.0
			grove_hi = 1120.0
	for i in range(grove):
		for attempt in range(20):
			var tx := randf_range(grove_lo, grove_hi)
			if freedom_kind == "clearing":
				# outer thirds only: the middle is where the fetching happens
				tx = randf_range(150.0, 340.0) if randf() < 0.5 else randf_range(940.0, 1120.0)
			var tree := Vector2(tx, GATE_Y - randf_range(120.0, 550.0))
			var clear := tree.distance_to(gate_bench) > 95.0
			for w: Rect2 in water:
				clear = clear and not w.grow(30.0).has_point(tree)
			for slot in PAIR_PARK_SPOTS:
				var spot: Vector2 = slot.position
				clear = clear and tree.distance_to(spot) > 85.0
			if clear:
				trees.append(tree)
				break
	# THE FUR-GONETA, on the two walks a mobile groomer would actually work:
	# the market (a trade in nervous poodles) and the boulevard. Position only
	# here - wrap flanks are appended AFTER the corridor fit so body, draw,
	# blocker, scent and rope contacts share one fitted centre.
	if lvl == "market":
		furgoneta = Vector2(sw_r - 74.0, -2150.0)
	elif lvl == "street":
		furgoneta = Vector2(sw_l + 66.0, -3560.0)
	for ly in lane_ys:
		lane_state.append({"t": randf_range(1.0, 2.5), "phase": 0, "dir": 1})
	_build_substance_zones()
	_fit_props_to_corridor()
	# after the fit, deliberately: the verge is the one place whose contents
	# must NOT be pulled onto the pavement
	_build_verge()
	if furgoneta.x < INF:
		for off: float in [-52.0, -26.0, 0.0, 26.0, 52.0]:
			poles.append(furgoneta + Vector2(0.0, off))
	# The grove is wrap geometry too, so the rope catches on trunks. Appended
	# AFTER the corridor fit on purpose: the trees stand in the open off-leash
	# area, which is full width, so clamping them to the walkway would drag
	# them out of position. They sit past body_pole_count, which is why they
	# get their own collision bodies in _build_walls.
	for t in trees:
		poles.append(t)
	# the hazardous hard-to-reach collectible: one per level, in a spot
	# that costs you something to reach (deliberately outside the corridor
	# on some walks, so it is exempt from the corridor fit)
	match lvl:
		"street":
			prize_pos = Vector2(SHOULDER_R - 12.0, -2400.0)  # far shoulder, across the bike lane
			prize_text = "fetch the frisbee across the bike lane"
		"park":
			prize_pos = pond.get_center() if pond.size.x > 0.0 else Vector2(640.0, -2700.0)
			prize_text = "fetch the ball from the middle of the pond"
		"beach":
			# In the sea, so she swims for it - but x=20 was OUTSIDE THE FRAME.
			# The camera is zoomed 1.28 and sits on x=640, so only world x
			# 140..1140 is ever visible: the ball was a goal the player could
			# not see. Placed just inside the visible edge instead, still well
			# out past the shoreline.
			prize_pos = Vector2(178.0, -2600.0)
			prize_text = "swim out for the ball"
		"market":
			prize_pos = Vector2(640.0, -2050.0)  # by the drain in the middle aisle
			prize_text = "grab the churro by the open drain"
		"rain":
			prize_pos = Vector2(640.0, -1500.0)  # right on a gaping storm drain
			prize_text = "snatch the toy off the storm drain"
		"oldtown":
			prize_pos = Vector2(920.0, -2750.0)  # under a smug wall cat, up the wall
			prize_text = "steal the sardine under the cat's ledge"
		"trail":
			prize_pos = Vector2(300.0, -3400.0)  # a pinecone off in the muddy brush
			prize_text = "dig the pinecone out of the mud"
		"station":
			prize_pos = Vector2(640.0, -2650.0)  # a dropped sandwich mid-walkway
			prize_text = "grab the sandwich off the moving walkway"
		"site":
			prize_pos = Vector2(640.0, -3130.0)  # a trowel dropped in the wet cement
			prize_text = "fish the trowel out of the wet cement"
		"spook":
			prize_pos = Vector2(640.0, -2350.0)  # a dog-safe pumpkin treat, ringed by candy
			prize_text = "get the pumpkin treat without eating the candy"
		"scrap":
			prize_pos = Vector2(925.0, -2270.0)  # right beside a sleeping guard dog
			prize_text = "steal the bone from under the guard's nose"
		_:
			prize_pos = Vector2(SHOULDER_R - 12.0, -2400.0)
			prize_text = "fetch the frisbee"
	# carry / delivery mission on some walks: pick it up here, drop it there
	match lvl:
		"street":
			carry_pickup = Vector2(360.0, -1150.0)
			carry_drop = Vector2(905.0, -2850.0)
			carry_item = "the newspaper"
			carry_text = "deliver the newspaper to the stoop"
		"market":
			carry_pickup = Vector2(915.0, -1250.0)
			carry_drop = Vector2(360.0, -3050.0)
			carry_item = "the crate of oranges"
			carry_text = "run the oranges to the far stall"
		_:
			pass


func _draw_paving(vt: float, vb: float, base: Color) -> void:
	# A single flat fill with a seam line every 150px was the main reason the
	# ground read as a colour swatch. Real paving has JOINTS and every slab
	# has slightly different tone, which together give the eye a sense of
	# scale and of a surface. Slab size and bond pattern change per level, so
	# the alley's small setts do not look like the concourse's big tiles.
	var sw := 96.0     # slab width
	var sh := 112.0    # slab height
	var stagger := 0.5 # brick-bond offset per row
	var joint := Color(0.0, 0.0, 0.0, 0.10)
	match lvl:
		"oldtown", "spook":
			# setts, but not SO fine that the slab count doubles the frame's
			# draw cost - measured at 46x40 they alone pushed this walk to
			# 1.3ms of world draw. Still visibly smaller than the boulevard's.
			sw = 64.0
			sh = 56.0
			stagger = 0.5
		"station":
			sw = 132.0   # big polished tiles, laid square
			sh = 132.0
			stagger = 0.0
			joint = Color(0.0, 0.0, 0.0, 0.07)
		"market":
			sw = 84.0
			sh = 96.0
		"site", "scrap":
			return       # broken ground: no paving pattern at all
		"park", "trail":
			return       # dirt, not slabs
	var row := int(floorf(vt / sh)) - 1
	var y := float(row) * sh
	while y < vb + sh:
		var off := fmod(absf(float(row)) * stagger, 1.0) * sw
		var x := sw_l - sw + off
		while x < sw_r:
			var x0 := maxf(x, sw_l)
			var x1 := minf(x + sw - 2.0, sw_r)
			if x1 > x0:
				# a stable per-slab tone wobble, hashed from the grid position
				var h := fmod(absf(sin(float(row) * 12.9898 + floorf(x / sw) * 78.233) * 43758.5453), 1.0)
				var slab := base.lightened((h - 0.5) * 0.09) if h > 0.5 else base.darkened((0.5 - h) * 0.10)
				draw_rect(Rect2(x0, y, x1 - x0, sh - 2.0), slab)
			x += sw
		# the joints: a dark line, plus a light one below it so the slab edge
		# catches the light like a real chamfer
		draw_line(Vector2(sw_l, y), Vector2(sw_r, y), joint, 2.0)
		draw_line(Vector2(sw_l, y + 2.0), Vector2(sw_r, y + 2.0), Color(1, 1, 1, 0.045), 1.5)
		var vx := sw_l - sw + off
		while vx < sw_r:
			if vx > sw_l and vx < sw_r:
				draw_line(Vector2(vx, y), Vector2(vx, y + sh - 2.0), joint, 2.0)
			vx += sw
		row += 1
		y += sh


func _draw_edges(c: CanvasItem, vt: float, vb: float) -> void:
	# What flanks the corridor is what actually gives a walk its identity:
	# shopfronts say boulevard, stone walls say medieval alley, chain-link
	# says scrapyard. Drawn as repeating modules down the walk and culled to
	# the view, on both verges, facing inward.
	if lvl == "beach":
		return  # bespoke cross-section, dressed in its own block
	var mod := 220.0                     # height of one facade module
	var depth := 78.0                    # how far the detailed frontage juts
	# Built-up walks fill the whole verge with masonry, so no stray grass
	# shows past the buildings - that is a big part of why an alley feels
	# enclosed. Green walks (park, trail) keep their verge and just crowd
	# the path with foliage instead.
	var built := lvl != "park" and lvl != "trail"
	if built:
		var base := _edge_base_color()
		var far := 520.0
		var top_y := vt - 320.0
		var h := (vb - vt) + 640.0
		c.draw_rect(Rect2(sw_l - far, top_y, far, h), base)
		c.draw_rect(Rect2(sw_r, top_y, far, h), base)
		# Seen from directly overhead you do not see a facade at all - you
		# see the ROOF. So the verge is roofscape, and the building reads as
		# tall through three cues instead: a lit parapet cap along its edge,
		# a hard shadow thrown across the pavement, and ambient darkening
		# where wall meets ground.
		# THE HEIGHT ILLUSION. A flat roof butted against flat pavement reads
		# as ground you could stroll onto - which is exactly how it looked.
		# So the roof is drawn inset from its footprint and the gap between
		# them becomes a visible WALL FACE, angled toward the viewer: dark at
		# the base, lighter up the wall, with a bright cap along the roof
		# edge. Together with the cast shadow that gives a clear storey of
		# height and makes the roofline unmistakably a roofline.
		var face := 22.0
		for i in range(7):
			var f := float(i) / 6.0
			# left block: its face looks right, into the street
			var lx := sw_l - face + face * f
			c.draw_rect(Rect2(lx, top_y, face / 6.0 + 1.0, h), base.darkened(0.52 - f * 0.34))
			# right block: its face looks left, into the street
			var rx := sw_r + face - face * f
			c.draw_rect(Rect2(rx - face / 6.0 - 1.0, top_y, face / 6.0 + 1.0, h), base.darkened(0.56 - f * 0.34))
		# the lit cap where the wall meets the roof, and a hard kerb line
		c.draw_rect(Rect2(sw_l - face - 5.0, top_y, 5.0, h), base.lightened(0.30))
		c.draw_rect(Rect2(sw_r + face, top_y, 5.0, h), base.lightened(0.24))
		c.draw_line(Vector2(sw_l, top_y), Vector2(sw_l, top_y + h), Color(0.04, 0.03, 0.05, 0.55), 3.0)
		c.draw_line(Vector2(sw_r, top_y), Vector2(sw_r, top_y + h), Color(0.04, 0.03, 0.05, 0.55), 3.0)
		# the light is up-and-left, so the LEFT block throws a shadow out
		# across the pavement; the right block throws its own away from us
		var cast := 38.0
		for i in range(6):
			var f := float(i) / 5.0
			c.draw_rect(Rect2(sw_l, top_y, cast * (1.0 - f * 0.82), h), Color(0.05, 0.04, 0.07, 0.055))
		for i in range(3):
			var g := float(i) / 2.0
			c.draw_rect(Rect2(sw_r - 11.0 * (1.0 - g), top_y, 11.0 * (1.0 - g), h), Color(0.05, 0.04, 0.07, 0.05))
	# the roof sits BACK from the kerb by the depth of the wall face drawn
	# above, otherwise the roof clutter would be painted over the wall
	var inset := 27.0 if built else 0.0
	var y := floorf((vt - mod) / mod) * mod
	while y < vb + mod:
		for side in [-1.0, 1.0]:
			var inner: float = (sw_l - inset) if side < 0.0 else (sw_r + inset)
			var x0: float = inner - depth if side < 0.0 else inner
			# contiguous modules: gaps between them looked like missing wall
			var r := Rect2(x0, y, depth, mod)
			# a stable per-module variation without touching the global rng
			var k := int(absf(y) / mod) + (0 if side < 0.0 else 7)
			_draw_edge_module(c, r, side, k)
		y += mod


func draw_edges_onto(c: CanvasItem) -> void:
	# called by the edge layer, which decides WHEN rather than what
	var vt: float = cam.position.y - 560.0
	var vb: float = cam.position.y + 560.0
	_draw_edges(c, vt, vb)


func _edge_base_color() -> Color:
	match lvl:
		"oldtown", "spook": return Color(0.36, 0.33, 0.30)   # old stone
		"station": return Color(0.48, 0.48, 0.52)            # tiled interior
		"site": return Color(0.52, 0.42, 0.27)               # plywood hoarding
		"scrap": return Color(0.26, 0.25, 0.24)              # yard beyond the fence
		"market": return Color(0.44, 0.38, 0.34)
		_: return Color(0.38, 0.35, 0.37)                    # city block


func _draw_doorway(c: CanvasItem, inner_x: float, side: float, y: float, wall: Color) -> void:
	# A door from directly above is genuinely hard: the leaf is vertical, so
	# there is nothing to see. What you DO see is a recess in the wall, a
	# threshold sticking out onto the pavement, and the lintel's shadow lying
	# across it - and that shadow is the whole trick. Drawn as a grey
	# rectangle it read as a doormat someone had left in the street, which is
	# exactly what it looked like.
	var into: float = -side          # away from the pavement, into the building
	var jamb := wall.darkened(0.30)
	# the reveal: the wall thickness the door is set back into
	c.draw_rect(Rect2(inner_x + into * 22.0 if into > 0.0 else inner_x - 22.0,
		y - 18.0, 22.0, 36.0), jamb)
	# the leaf, foreshortened into a dark band, with a warm line of light
	# escaping under it
	var leaf_x: float = inner_x + into * 15.0
	c.draw_rect(Rect2(minf(leaf_x, leaf_x + into * 7.0), y - 15.0, 7.0, 30.0),
		Color(0.16, 0.12, 0.10))
	c.draw_rect(Rect2(minf(leaf_x, leaf_x + into * 7.0), y - 15.0, 2.0, 30.0),
		Color(0.30, 0.23, 0.18))
	c.draw_circle(Vector2(leaf_x + into * 3.0, y + 7.0), 1.6, Color(0.80, 0.70, 0.42))
	# the threshold, projecting onto the pavement, with a nosing on its edge
	var t_out: float = inner_x + side * 13.0
	c.draw_rect(Rect2(minf(inner_x, t_out), y - 16.0, 13.0, 32.0), Color(0.60, 0.57, 0.52))
	c.draw_rect(Rect2(t_out - (2.0 if side > 0.0 else 0.0), y - 16.0, 2.0, 32.0),
		Color(0.72, 0.69, 0.63))
	# the lintel shadow: deepest against the wall, fading out over the step
	for i in range(4):
		var f := float(i) / 3.0
		var sx: float = inner_x + side * (2.0 + f * 16.0)
		c.draw_rect(Rect2(minf(sx, sx + side * 5.0), y - 16.0, 5.0, 32.0),
			Color(SHADOW_COL.r, SHADOW_COL.g, SHADOW_COL.b, 0.30 * (1.0 - f)))


func _draw_edge_module(c: CanvasItem, r: Rect2, side: float, k: int) -> void:
	var inner_x: float = r.end.x if side < 0.0 else r.position.x
	var lit := fmod(float(k) * 0.37, 1.0)
	# Roofscape, not facades: from overhead the readable features are roof
	# material, chimneys, vents, skylights and plant - plus the things that
	# genuinely project over the pavement (awnings) and the things that sit
	# in the ground plane (doorsteps).
	match lvl:
		"oldtown", "spook":
			# terracotta pantiles running in courses, with chimney stacks
			var tile := Color(0.55, 0.31, 0.22).lightened(lit * 0.10)
			c.draw_rect(r, tile)
			var course := r.position.y
			while course < r.end.y:
				c.draw_line(Vector2(r.position.x, course), Vector2(r.end.x, course), tile.darkened(0.22), 2.0)
				course += 13.0
			# ridge line along the outer edge
			var ridge_x: float = r.position.x + 6.0 if side < 0.0 else r.end.x - 6.0
			c.draw_line(Vector2(ridge_x, r.position.y), Vector2(ridge_x, r.end.y), tile.lightened(0.26), 5.0)
			# a chimney with its own little shadow
			if k % 2 == 0:
				var cp := Vector2(inner_x + side * 46.0, r.position.y + 64.0)
				c.draw_rect(Rect2(cp.x - 8.0, cp.y - 9.0, 16.0, 18.0), Color(0.40, 0.24, 0.19))
				c.draw_rect(Rect2(cp.x - 8.0, cp.y - 9.0, 16.0, 5.0), Color(0.30, 0.19, 0.16))
				c.draw_rect(Rect2(cp.x + 8.0, cp.y - 5.0, 7.0, 18.0), Color(0.05, 0.04, 0.07, 0.22))
			_draw_doorway(c, inner_x, side, r.position.y + 156.0, tile)
		"trail", "park":
			# dense undergrowth and trunks crowding the path
			for b in range(4):
				var by := r.position.y + 26.0 + b * 52.0
				var bx := inner_x + side * (14.0 + float((k + b) % 3) * 13.0)
				c.draw_circle(Vector2(bx, by), 21.0 + float((k + b) % 4) * 4.0, Color(0.19, 0.31, 0.20))
				c.draw_circle(Vector2(bx - side * 5.0, by - 5.0), 12.0, Color(0.24, 0.38, 0.24))
			var trunk_x := inner_x + side * 44.0
			c.draw_circle(Vector2(trunk_x, r.get_center().y), 9.0, Color(0.32, 0.25, 0.18))
		"station":
			# a glazed platform canopy: steel frame, dusty glass panels, and
			# the light that leaks through it onto the concourse
			var glass := Color(0.52, 0.58, 0.62).lightened(lit * 0.07)
			c.draw_rect(r, glass)
			var pane_y := r.position.y
			while pane_y < r.end.y:
				c.draw_line(Vector2(r.position.x, pane_y), Vector2(r.end.x, pane_y), Color(0.36, 0.38, 0.42), 3.0)
				c.draw_line(Vector2(r.position.x, pane_y + 4.0), Vector2(r.end.x, pane_y + 4.0), Color(0.68, 0.74, 0.78, 0.5), 1.5)
				pane_y += 36.0
			# the spine truss running the length of the canopy
			var spine_x := r.get_center().x
			c.draw_line(Vector2(spine_x, r.position.y), Vector2(spine_x, r.end.y), Color(0.33, 0.35, 0.39), 6.0)
		"site":
			# scaffold decking and tarps over the works
			c.draw_rect(r, Color(0.46, 0.44, 0.40).lightened(lit * 0.08))
			# scaffold boards running across, with poles at the joints
			var board := r.position.y
			while board < r.end.y:
				c.draw_line(Vector2(r.position.x, board), Vector2(r.end.x, board), Color(0.58, 0.48, 0.31), 7.0)
				c.draw_line(Vector2(r.position.x, board + 4.0), Vector2(r.end.x, board + 4.0), Color(0.30, 0.25, 0.17), 1.5)
				board += 26.0
			# a blue tarp lashed over part of it, and hazard tape at the edge
			if k % 2 == 0:
				c.draw_rect(Rect2(inner_x + side * 58.0, r.position.y + 40.0, 58.0, 96.0), Color(0.20, 0.36, 0.52, 0.9))
			var tape_x: float = inner_x + side * 5.0
			for s in range(8):
				var sy := r.position.y + s * 28.0
				var sc := Color(0.92, 0.72, 0.15) if s % 2 == 0 else Color(0.15, 0.14, 0.13)
				c.draw_line(Vector2(tape_x, sy), Vector2(tape_x, sy + 14.0), sc, 5.0)
		"scrap":
			# corrugated shed roofs, rusting, with junk heaps between them
			var iron := Color(0.40, 0.38, 0.35).lightened(lit * 0.09)
			c.draw_rect(r, iron)
			var rib := r.position.x
			while rib < r.end.x:
				c.draw_line(Vector2(rib, r.position.y), Vector2(rib, r.end.y), iron.darkened(0.22), 2.0)
				c.draw_line(Vector2(rib + 4.0, r.position.y), Vector2(rib + 4.0, r.end.y), iron.lightened(0.16), 1.5)
				rib += 11.0
			# rust blooms
			for h in range(2):
				var hy := r.position.y + 50.0 + h * 96.0
				c.draw_circle(Vector2(inner_x + side * (34.0 + float(h) * 18.0), hy), 17.0, Color(0.48, 0.28, 0.17, 0.55))
			# the fence line at the kerb, seen from above as posts and wire
			var fx: float = inner_x + side * 5.0
			c.draw_line(Vector2(fx, r.position.y), Vector2(fx, r.end.y), Color(0.55, 0.57, 0.58, 0.7), 2.0)
			for d in range(5):
				c.draw_circle(Vector2(fx, r.position.y + float(d) * 46.0), 3.0, Color(0.42, 0.44, 0.45))
		_:
			# the default city block, seen from the air: a flat felt roof
			# with the usual clutter, and an awning that genuinely projects
			# out over the pavement
			var felt := Color(0.34, 0.33, 0.35).lightened(lit * 0.11)
			c.draw_rect(r, felt)
			# gravel ballast, in patches rather than a uniform fill
			for gi in range(9):
				var gx2 := r.position.x + fmod(float(gi) * 37.0 + float(k) * 11.0, r.size.x)
				var gy2 := r.position.y + fmod(float(gi) * 61.0 + float(k) * 23.0, r.size.y)
				c.draw_circle(Vector2(gx2, gy2), 9.0 + float(gi % 3) * 4.0, felt.lightened(0.09))
			# an air-conditioning unit with a cast shadow, and roof vents
			var ac_p := Vector2(inner_x + side * 44.0, r.position.y + 58.0)
			c.draw_rect(Rect2(ac_p.x + 6.0, ac_p.y + 6.0, 30.0, 24.0), Color(0.05, 0.04, 0.07, 0.28))
			c.draw_rect(Rect2(ac_p.x - 15.0, ac_p.y - 12.0, 30.0, 24.0), Color(0.62, 0.63, 0.65))
			c.draw_rect(Rect2(ac_p.x - 11.0, ac_p.y - 8.0, 22.0, 16.0), Color(0.47, 0.49, 0.52))
			for vi in range(2):
				var vp := Vector2(inner_x + side * 22.0, r.position.y + 128.0 + float(vi) * 34.0)
				c.draw_circle(vp, 7.0, Color(0.52, 0.53, 0.55))
				c.draw_circle(vp, 4.0, Color(0.24, 0.25, 0.27))
			# a rooflight: from above this is the window that makes sense
			if k % 3 == 0:
				var sk := Rect2(inner_x + side * 66.0, r.position.y + 96.0, 34.0, 46.0)
				c.draw_rect(sk, Color(0.88, 0.83, 0.52, 0.85) if Game.night else Color(0.62, 0.72, 0.78, 0.8))
				c.draw_rect(sk, felt.darkened(0.35), false, 3.0)
			# the awning: projects over the pavement, so it reads correctly
			# from overhead, and throws a shadow onto the paving below it
			if k % 2 == 0:
				var ac := Color(0.72, 0.3, 0.28) if k % 4 == 0 else Color(0.28, 0.42, 0.55)
				var aw_x: float = inner_x if side < 0.0 else inner_x - 34.0
				c.draw_rect(Rect2(aw_x, r.position.y + 44.0, 34.0, 76.0), Color(0.05, 0.04, 0.07, 0.16))
				c.draw_rect(Rect2(aw_x, r.position.y + 40.0, 30.0, 72.0), ac)
				for st in range(4):
					c.draw_line(Vector2(aw_x + 7.0 * float(st), r.position.y + 40.0),
						Vector2(aw_x + 7.0 * float(st), r.position.y + 112.0), ac.lightened(0.30), 3.0)
			_draw_doorway(c, inner_x, side, r.position.y + 168.0, felt)


func _build_verge() -> void:
	# WHAT LIVES ON THE VERGE.
	#
	# The grass either side of the walk was always walkable and always empty,
	# which is why nobody ever went there: it was a different colour and
	# nothing else. Now that grass reads as a surface in its own right (grips
	# better, holds far more smell) it is worth putting the city's own use of
	# it on there - people sitting about on a Sunday, and the things a lawn
	# accumulates.
	#
	# Authored by hand rather than scattered, like every other prop here: a
	# picnic wants to be somewhere that reads as a spot, and hand-placing also
	# keeps it out of the global RNG, which the autowalk determinism depends on.
	verge_items = []
	# WHERE THE VERGE ACTUALLY IS ON SCREEN. The camera is zoomed 1.28, so only
	# world x 140..1140 is ever visible - the level is 1200 wide but a fifth of
	# it never appears. The first pass of this put picnics at x=150 and x=1170:
	# one was clipped by the left edge of the frame and the other was
	# completely off screen. So the verge is placed relative to the pavement
	# and then held inside what the camera can see.
	var vl: float = clampf(sw_l - 85.0, 195.0, 1085.0)
	var vr: float = clampf(sw_r + 85.0, 195.0, 1085.0)
	match lvl:
		"street":
			# El Passeig: the boulevard's lawn, all of it on the west side -
			# east of the pavement is the bike lane and the shoulder, and what
			# green is left out there is past the edge of the frame.
			verge_items = [
				{"pos": Vector2(vl, -520.0), "kind": "picnic"},
				{"pos": Vector2(vl - 22.0, -1180.0), "kind": "stump"},
				{"pos": Vector2(vl + 14.0, -1760.0), "kind": "picnic"},
				{"pos": Vector2(vl - 30.0, -2480.0), "kind": "bush"},
				{"pos": Vector2(vl + 8.0, -3020.0), "kind": "picnic"},
				{"pos": Vector2(vl - 26.0, -3900.0), "kind": "bush"},
				{"pos": Vector2(vl + 12.0, -4420.0), "kind": "picnic"},
			]
		"park":
			# a park has verge on both sides, and the verge is the whole point
			verge_items = [
				{"pos": Vector2(vl, -760.0), "kind": "picnic"},
				{"pos": Vector2(vr, -1500.0), "kind": "picnic"},
				{"pos": Vector2(vl - 18.0, -2260.0), "kind": "stump"},
				{"pos": Vector2(vr + 10.0, -3100.0), "kind": "picnic"},
				{"pos": Vector2(vl + 16.0, -3820.0), "kind": "bush"},
			]
		"trail":
			# out here it is fallen wood and undergrowth, not tablecloths
			verge_items = [
				{"pos": Vector2(vl, -700.0), "kind": "stump"},
				{"pos": Vector2(vr, -1450.0), "kind": "bush"},
				{"pos": Vector2(vl + 18.0, -2200.0), "kind": "bush"},
				{"pos": Vector2(vr - 14.0, -2950.0), "kind": "stump"},
				{"pos": Vector2(vl - 16.0, -3700.0), "kind": "bush"},
				{"pos": Vector2(vr + 12.0, -4300.0), "kind": "stump"},
			]
	# Nothing on the verge may sit in a bike lane. They are drawn straight
	# across the level, verge included, so the first pass had a tree stump
	# apparently growing out of the tarmac. Pushed clear here rather than
	# hand-avoided in the lists above, so moving a lane later cannot quietly
	# strand a picnic in the middle of it.
	var clear_by := LANE_HALF + 52.0
	for i in range(verge_items.size()):
		var it: Dictionary = verge_items[i]
		var p: Vector2 = it["pos"]
		for ly: float in lane_ys:
			if absf(p.y - ly) < clear_by:
				p.y = (ly - clear_by) if p.y <= ly else (ly + clear_by)
		it["pos"] = p
		verge_items[i] = it


func draw_verge_onto(c: CanvasItem, vt: float, vb: float) -> void:
	# On the cached edge canvas, NOT the per-frame world draw. A lawn does not
	# move, and the edge treatment was already more than half the frame once
	# before it was moved off it (see edgelayer.gd) - putting picnics into the
	# 30-times-a-second draw is exactly how a walk starts to stutter.
	for it: Dictionary in verge_items:
		var p: Vector2 = it["pos"]
		if p.y < vt - 160.0 or p.y > vb + 160.0:
			continue
		match String(it["kind"]):
			"picnic":
				_draw_picnic(c, p)
			"stump":
				_draw_stump(c, p)
			"bush":
				_draw_verge_bush(c, p)


func _draw_picnic(c: CanvasItem, at: Vector2) -> void:
	# A blanket on the grass with people sitting round it, from above: the
	# blanket is the shape you read first, then heads. Same top-down anatomy as
	# everyone else in this game - a body disc and a head with hair on it.
	contact_shadow(c, at, 44.0, 6.0, 0.16)
	var cloth := Color(0.80, 0.28, 0.30) if int(at.y) % 3 == 0 else Color(0.36, 0.48, 0.68)
	c.draw_colored_polygon(
		PackedVector2Array([
			at + Vector2(-42.0, -30.0), at + Vector2(44.0, -34.0),
			at + Vector2(41.0, 33.0), at + Vector2(-45.0, 29.0),
		]), cloth)
	# a check pattern, which is what stops it reading as a flat red lozenge
	for i in range(1, 4):
		var f := float(i) / 4.0
		c.draw_line(at + Vector2(-43.0 + 86.0 * f, -32.0), at + Vector2(-44.0 + 86.0 * f, 31.0),
			cloth.lightened(0.22), 2.0)
		c.draw_line(at + Vector2(-43.0, -32.0 + 64.0 * f), at + Vector2(43.0, -33.0 + 64.0 * f),
			cloth.lightened(0.22), 2.0)
	# the spread: a basket and a couple of cups, which is the bit that smells
	c.draw_rect(Rect2(at.x - 9.0, at.y - 8.0, 20.0, 15.0), Color(0.62, 0.45, 0.24))
	c.draw_rect(Rect2(at.x - 9.0, at.y - 8.0, 20.0, 4.0), Color(0.74, 0.56, 0.32))
	for cup: Vector2 in [Vector2(20.0, 10.0), Vector2(-24.0, 6.0)]:
		c.draw_circle(at + cup, 4.0, Color(0.92, 0.90, 0.84))
	# two or three sitters round the edge, facing in
	var skins := [Color(0.88, 0.73, 0.58), Color(0.70, 0.54, 0.40), Color(0.94, 0.82, 0.70)]
	var shirts := [Color(0.42, 0.52, 0.44), Color(0.78, 0.72, 0.42), Color(0.50, 0.42, 0.60)]
	var seats := [Vector2(-30.0, -22.0), Vector2(32.0, -18.0), Vector2(6.0, 26.0)]
	for i in range(3):
		var s: Vector2 = at + seats[i]
		contact_shadow(c, s, 11.0, 5.0, 0.14)
		c.draw_circle(s, 11.0, shirts[i])
		# head pushed toward the blanket's middle, so they read as facing in
		var inward := (at - s).normalized() * 4.0
		c.draw_circle(s + inward, 7.0, skins[i])
		var back := (s - at).normalized().angle()
		c.draw_arc(s + inward, 7.0, back - 1.1, back + 1.1, 10, Color(0.26, 0.19, 0.13), 4.0)


func _draw_stump(c: CanvasItem, at: Vector2) -> void:
	# a sawn-off trunk: end grain in rings, and a real shadow so it has height
	cast_shadow(c, at, 17.0, 22.0, 0.20)
	c.draw_circle(at, 17.0, Color(0.44, 0.33, 0.22))
	c.draw_circle(at + Vector2(-2.0, -2.0), 14.0, Color(0.62, 0.49, 0.32))
	for r: float in [10.0, 6.0, 3.0]:
		c.draw_arc(at + Vector2(-2.0, -2.0), r, 0.0, TAU, 14, Color(0.48, 0.36, 0.23), 1.4)


func _draw_verge_bush(c: CanvasItem, at: Vector2) -> void:
	# clustered lobes with the light on the upper-left of each, same as the
	# tree canopies, so a bush belongs to the same world as everything else
	contact_shadow(c, at, 21.0, 14.0, 0.18)
	var dark := Color(0.17, 0.30, 0.18)
	var lit := Color(0.30, 0.46, 0.26)
	for lobe: Vector2 in [Vector2(-9.0, 3.0), Vector2(9.0, 5.0), Vector2(0.0, -8.0)]:
		c.draw_circle(at + lobe, 13.0, dark)
	for lobe2: Vector2 in [Vector2(-11.0, -1.0), Vector2(-2.0, -11.0)]:
		c.draw_circle(at + lobe2, 8.0, lit)


func _scent_sources() -> Array:
	# cached: this allocates a dictionary per source and does a group query,
	# and it was being rebuilt on every single world redraw
	if _scent_cache_t > 0.0:
		return _scent_cache
	_scent_cache_t = 0.45
	_scent_cache = _build_scent_sources()
	return _scent_cache


func _build_scent_sources() -> Array:
	# Everything worth smelling, and what it smells LIKE. Colour carries the
	# meaning, so a nose-led player learns to read them: warm amber for food,
	# pale bone for something buried, pink for the cat, blue for a job to do,
	# and a sickly green for the chocolate she must NOT eat - smelling
	# wonderful and being bad for you is the whole joke of that level.
	var out: Array = []
	for pp in park_props:
		if String(pp.kind) == "dig" and not pp.done:
			out.append({"pos": pp.pos, "col": Color(0.94, 0.90, 0.76)})
	for k in kebabs:
		if not k.eaten:
			out.append({"pos": k.pos, "col": Color(1.0, 0.76, 0.36)})
	# somebody else's lunch, out on the grass. This is what makes
	# the verge worth the detour rather than just a nicer colour: the best
	# smell on the boulevard is well off the path, and grass carries it
	# further than pavement would (see surfaces.gd)
	for it: Dictionary in verge_items:
		if String(it["kind"]) == "picnic":
			out.append({"pos": it["pos"], "col": Color(1.0, 0.82, 0.44)})
	for c in candy:
		if not c.eaten:
			out.append({"pos": c.pos, "col": Color(0.55, 0.85, 0.45)})
	if not prize_taken and prize_pos.x < INF:
		out.append({"pos": prize_pos, "col": Color(1.0, 0.86, 0.42)})
	if carry_state == 0 and carry_pickup.x < INF:
		out.append({"pos": carry_pickup, "col": Color(0.62, 0.82, 1.0)})
	elif carry_state == 1 and carry_drop.x < INF:
		out.append({"pos": carry_drop, "col": Color(0.62, 0.82, 1.0)})
	for tf in get_tree().get_nodes_in_group("tofu"):
		out.append({"pos": tf.global_position, "col": Color(1.0, 0.66, 0.80)})
	if furgoneta.x < INF and not furgoneta_sniffed:
		out.append({"pos": furgoneta, "col": Color(0.98, 0.82, 0.45)})
	# another dog's mark: a pale, unmistakable yellow-green
	for nm in npc_marks:
		if not bool(nm.sniffed):
			out.append({"pos": nm.pos, "col": Color(0.86, 0.88, 0.42)})
	return out


func _draw_scents() -> void:
	# THE NOSE. A dog's strongest sense, so it gets to be a real one rather
	# than a marker on a map: scent drifts off a source toward her, thickening
	# as she nears it, and she can sense things far outside what she can see -
	# which is what makes wandering off the direct line pay.
	#
	# The clever bit, and the reason this needs no extra button (so it works
	# the same on keyboard, pad and touch): her nose REACHES FURTHER THE
	# SLOWER SHE GOES. Barrel along and you smell almost nothing; drop to an
	# amble and the whole street opens up. Being a dog rewards taking your
	# time, which is rather the point of a walk.
	var speed := dog.velocity.length()
	var reach: float = lerpf(SCENT_REACH_MAX, SCENT_REACH_MIN, clampf(speed / 300.0, 0.0, 1.0))
	# and the mood closes the nose down on top of that. This is the sharpest
	# thing a mood does: frightened, the street stops telling you anything, so
	# SCARED costs you the sense the whole game is built on. It only shortens
	# what you can PERCEIVE - nothing here changes what is actually findable,
	# so a mood makes a walk harder to read, never impossible to finish.
	if mood != null:
		reach *= mood.scent_mult()
	# ...and what she is standing on. Grass and mud hold a day's worth of
	# smell where pavement holds almost none and water holds none at all, so
	# stepping onto the verge opens the street up. This is the reward half of
	# the surface trade: grass costs a little speed and pays in nose.
	reach *= Surfaces.scent_mult(dog.surface)
	var t := Time.get_ticks_msec() / 1000.0
	var shown := 0
	for src in _scent_sources():
		if shown >= 6:
			break  # keep the draw cost bounded on busy walks
		var at: Vector2 = src.pos
		var to_dog := dog.global_position - at
		var d := to_dog.length()
		if d > reach or d < 6.0:
			continue
		shown += 1
		var near: float = 1.0 - d / reach          # 0 at the edge, 1 on top of it
		var col: Color = src.col
		var dir := to_dog / d
		# motes drift from the source toward her nose, so the trail reads as
		# something arriving rather than a line pointing at a waypoint
		var motes := 3 + int(near * 5.0)
		for i in range(motes):
			var f := fmod(t * 0.45 + float(i) / float(motes), 1.0)
			var along := at + dir * (d * f)
			# a lazy sideways wander, so it looks carried on the air
			var wob := dir.orthogonal() * sin(f * 7.0 + float(i) * 1.7 + at.x * 0.01) * (9.0 + near * 7.0)
			var a: float = (0.10 + near * 0.34) * (1.0 - f * 0.55)
			draw_circle(along + wob, 2.0 + near * 2.4, Color(col.r, col.g, col.b, a))
		# right on top of it, a soft bloom so the last step is unmistakable
		if near > 0.62:
			draw_circle(at, 15.0 + near * 9.0, Color(col.r, col.g, col.b, 0.07 * near))


# --- one light for the whole game -------------------------------------
#
# Shadows were being written by hand at each prop, so some had one, some did
# not, and the ones that did disagreed about where the sun was - which is
# exactly what makes a scene look pasted together rather than lit. There is
# now ONE light, up and to the left, and every shadow in the game comes out
# of these two helpers.
#
# Height is the input, not offset: a snack sits on the pavement and barely
# has a shadow, a lamppost throws one several metres long. That difference
# is most of what tells the eye how tall something is in a top-down view.

const LIGHT := Vector2(0.5, 0.866)      # the direction shadows fall
const SHADOW_COL := Color(0.05, 0.05, 0.08)


func contact_shadow(c: CanvasItem, at: Vector2, r: float, h: float, a := 0.24) -> void:
	# for things that sit ON the ground: a squashed ellipse, pushed away from
	# the light by however tall the thing is
	c.draw_set_transform(at + LIGHT * h, 0.0, Vector2(1.15, 0.5))
	c.draw_circle(Vector2.ZERO, r, Color(SHADOW_COL.r, SHADOW_COL.g, SHADOW_COL.b, a))
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func cast_shadow(c: CanvasItem, at: Vector2, w: float, h: float, a := 0.20) -> void:
	# for uprights: a tapering shadow lying on the ground away from the light,
	# plus the darker patch where the object actually meets it
	var tip := at + LIGHT * h
	var side := LIGHT.orthogonal()
	c.draw_colored_polygon(
		PackedVector2Array([
			at + side * w, at - side * w,
			tip - side * w * 0.62, tip + side * w * 0.62,
		]),
		Color(SHADOW_COL.r, SHADOW_COL.g, SHADOW_COL.b, a))
	c.draw_set_transform(at + LIGHT * (w * 0.5), 0.0, Vector2(1.2, 0.55))
	c.draw_circle(Vector2.ZERO, w * 1.15, Color(SHADOW_COL.r, SHADOW_COL.g, SHADOW_COL.b, a * 0.9))
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_broadleaf(c: CanvasItem, p: Vector2, scale: float) -> void:
	# A tree from above is a canopy, and a canopy is not one flat circle: it
	# is clustered lobes with light on the top-left of each one, a trunk you
	# can see through the gaps, and a shadow the same shape as the crown. The
	# old version was two translucent discs.
	var r := 34.0 * scale
	# the crown's shadow, thrown clear of the trunk so the tree stands up
	c.draw_set_transform(p + LIGHT * (46.0 * scale), 0.0, Vector2(1.1, 0.55))
	c.draw_circle(Vector2.ZERO, r * 1.02, Color(SHADOW_COL.r, SHADOW_COL.g, SHADOW_COL.b, 0.17))
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var dark := Color(0.15, 0.27, 0.16)
	var mid := Color(0.21, 0.36, 0.20)
	var lit := Color(0.31, 0.48, 0.26)
	# The underside, then a solid crown, then lobes only on the lit side. Lobes
	# ringed evenly around the centre left a dark hole in the middle and the
	# canopy read as a doughnut.
	c.draw_circle(p + Vector2(2, 3) * scale, r, dark)
	c.draw_circle(p - LIGHT * r * 0.10, r * 0.86, mid)
	var lobes := [
		Vector2(-0.42, -0.30), Vector2(0.40, -0.34), Vector2(0.46, 0.32),
		Vector2(-0.38, 0.40), Vector2(0.02, -0.06),
	]
	for i in range(lobes.size()):
		var lp: Vector2 = p + (lobes[i] as Vector2) * r
		c.draw_circle(lp, r * 0.50, mid)
	# the light falls on the upper-left of the crown, so only those lobes catch
	for i in range(lobes.size()):
		var lv: Vector2 = lobes[i]
		if lv.dot(LIGHT) > 0.10:
			continue          # this lobe is on the shaded side
		c.draw_circle(p + lv * r - LIGHT * r * 0.14, r * 0.34, lit)
	c.draw_circle(p - LIGHT * r * 0.42, r * 0.30, lit.lightened(0.08))
	# the trunk, visible in the middle where the canopy parts
	c.draw_circle(p, 6.5 * scale, Color(0.22, 0.16, 0.11))
	c.draw_circle(p + Vector2(-1, -1) * scale, 4.4 * scale, Color(0.36, 0.27, 0.18))
	# a few leaf tips breaking the outline, so it is not a perfect circle
	for i in range(7):
		var a := TAU * float(i) / 7.0 + p.x * 0.013
		c.draw_circle(p + Vector2.from_angle(a) * r * 0.95, r * 0.17, mid)


func _draw_palm(c: CanvasItem, p: Vector2) -> void:
	# a palm from above: a ring of long fronds, each with a spine and leaflets,
	# radiating from a fat trunk. The shadow copies the frond pattern, which is
	# what makes the beach read as glaring midday sun.
	var sh := p + LIGHT * 40.0
	for j in range(7):
		var sa := TAU * float(j) / 7.0 + p.x * 0.01 + p.y * 0.007
		c.draw_line(sh, sh + Vector2.from_angle(sa) * 34.0,
			Color(SHADOW_COL.r, SHADOW_COL.g, SHADOW_COL.b, 0.14), 7.0)
	var t := Time.get_ticks_msec() / 1000.0
	for j in range(7):
		var fa := TAU * float(j) / 7.0 + p.x * 0.01 + p.y * 0.007
		# the whole frond nods in the sea breeze
		fa += sin(t * 0.7 + float(j) * 1.3 + p.y * 0.01) * 0.05
		var dir := Vector2.from_angle(fa)
		var tip := p + dir * 38.0
		c.draw_line(p, tip, Color(0.20, 0.36, 0.19), 6.0)
		c.draw_line(p, tip, Color(0.29, 0.47, 0.24), 3.0)
		# leaflets down both sides of the spine
		var side := dir.orthogonal()
		for k in range(4):
			var f := 0.35 + float(k) * 0.2
			var at := p + dir * (38.0 * f)
			var ln := 9.0 * (1.0 - f * 0.5)
			c.draw_line(at, at + (side + dir * 0.5).normalized() * ln, Color(0.24, 0.41, 0.21), 2.5)
			c.draw_line(at, at - (side - dir * 0.5).normalized() * ln, Color(0.24, 0.41, 0.21), 2.5)
	# the trunk, and the coconuts nobody should be under
	c.draw_circle(p, 9.0, Color(0.34, 0.26, 0.17))
	c.draw_circle(p + Vector2(-2, -2), 6.0, Color(0.48, 0.38, 0.25))
	c.draw_circle(p + Vector2(5, 4), 3.4, Color(0.28, 0.22, 0.14))
	c.draw_circle(p + Vector2(-4, 5), 3.0, Color(0.28, 0.22, 0.14))


func _draw_lamppost(p: Vector2) -> void:
	# A lamppost seen from above is mostly a shadow: the column is directly
	# under the lantern, so the long shadow lying away from it is what tells
	# you it is three metres tall and not a manhole cover.
	cast_shadow(self, p, 6.0, 52.0, 0.18)
	var halo_a := 0.32 if Game.night else 0.08
	draw_circle(p, 62.0, Color(1.0, 0.9, 0.6, halo_a))
	# the base plinth it is bolted to
	draw_circle(p + Vector2(0, 2), POLE_RADIUS + 6.0, Color(0.24, 0.24, 0.27))
	draw_circle(p + Vector2(0, 1), POLE_RADIUS + 3.5, Color(0.33, 0.33, 0.36))
	# the fluted column, lit down one side
	draw_circle(p, POLE_RADIUS, Color(0.38, 0.38, 0.42))
	draw_circle(p + Vector2(-1.5, -1.5), POLE_RADIUS * 0.62, Color(0.52, 0.52, 0.57))
	# four cross arms, each with a lantern on the end, glass and all
	for bo: Vector2 in [Vector2(11, 0), Vector2(-11, 0), Vector2(0, 11), Vector2(0, -11)]:
		draw_line(p, p + bo, Color(0.30, 0.30, 0.33), 3.5)
		draw_line(p, p + bo, Color(0.46, 0.46, 0.5), 1.5)
		var lp := p + bo * 1.4
		draw_circle(lp, 5.0, Color(0.26, 0.26, 0.29))
		draw_circle(lp, 3.6, Color(0.99, 0.95, 0.78) if Game.night else Color(0.86, 0.88, 0.9))
		if Game.night:
			draw_circle(lp, 6.5, Color(1.0, 0.92, 0.66, 0.35))


func _freedom_dirty() -> void:
	# the cached off-leash canvas is out of date: a hole got deeper, a post got
	# sniffed, Brutus made off with a bone
	if freedomlayer != null:
		freedomlayer.mark_dirty()


func draw_freedom_onto(c: CanvasItem) -> void:
	# Everything in the off-leash space that does not move, drawn onto
	# freedomlayer's canvas so it survives between redraws. `c` is that canvas;
	# the helpers below take it rather than assuming `self`.
	# the ground the space sits in, out to the level edges
	var surround := Color(0.27, 0.4, 0.27)
	match freedom_kind:
		"beach": surround = Color(0.80, 0.74, 0.59)
		"clearing": surround = Color(0.20, 0.30, 0.19)
		"lot": surround = Color(0.32, 0.31, 0.29)
	c.draw_rect(Rect2(-400.0, GATE_Y - 800.0, 2100.0, 800.0), surround)
	match freedom_kind:
		"beach": _draw_dog_beach(c)
		"clearing": _draw_clearing(c)
		"lot": _draw_yard(c, true)
		_: _draw_yard(c, false)
	# the grove stands in the off-leash area, so it is static too. It used to be
	# drawn every frame in the world, with its own near-duplicate tree
	# renderer: 16 trees at ~20 draw calls each, measured at over a
	# millisecond, for a picture that never changed.
	# The grove doubles as rope-wrap geometry, so it exists on every walk and
	# has to be drawn on every walk - but a broadleaf on a beach is nonsense,
	# so it wears whatever that place grows.
	for t in trees:
		if freedom_kind == "beach":
			_draw_palm(c, t)
		else:
			_draw_broadleaf(c, t, 0.85)
	_draw_park_props(c, -1e9, 1e9)


func _freedom_rect() -> Rect2:
	return Rect2(70.0, freedom_lo, 1110.0, GATE_Y - 30.0 - freedom_lo)


func _draw_beach_water() -> void:
	# The only part of the dog beach that moves. Everything else - sand, dunes,
	# parasols, the shower - is on freedomlayer's cached canvas, so this is all
	# the sea costs per frame. Crests and foam follow beach_shore_x so they
	# never draw over dry sand in the headland taper.
	var r := _freedom_rect()
	var t := Time.get_ticks_msec() / 1000.0
	var sea_top := r.position.y - 40.0
	var sea_bot := r.end.y
	for rank in range(3):
		var pts := PackedVector2Array()
		var wy := sea_top
		while wy < sea_bot:
			var shore := beach_shore_x(wy)
			var base_x := shore - 26.0 - float(rank) * 78.0
			pts.append(Vector2(
				base_x + sin(wy * 0.010 + t * (1.0 + float(rank) * 0.35)) * 15.0,
				wy))
			wy += 26.0
		if pts.size() > 1:
			draw_polyline(pts, Color(1, 1, 1, 0.22 - float(rank) * 0.055),
				4.0 - float(rank) * 0.8)
	var swell := PackedVector2Array()
	var sy2 := sea_top
	while sy2 < sea_bot:
		swell.append(Vector2(-210.0 + sin(sy2 * 0.007 - t * 0.6) * 26.0, sy2))
		sy2 += 34.0
	if swell.size() > 1:
		draw_polyline(swell, Color(1, 1, 1, 0.07), 5.0)
	var fy := r.position.y
	while fy < r.end.y:
		var fx := beach_shore_x(fy) + 4.0 + sin(fy * 0.02 + t * 1.4) * 4.0
		draw_line(Vector2(fx, fy), Vector2(fx, fy + 40.0), Color(1, 1, 1, 0.30), 2.5)
		fy += 52.0


func _draw_freedom_fence(c: CanvasItem, r: Rect2, gravel: bool) -> void:
	# chain-link on all four sides, open at the gate
	var fence := Color(0.62, 0.63, 0.6) if not gravel else Color(0.55, 0.5, 0.44)
	var post := Color(0.5, 0.5, 0.48)
	var mesh := Color(0.66, 0.68, 0.66, 0.25)
	var yl := r.position.x
	var yr := r.end.x
	var ytop := r.position.y
	var ybot := r.end.y
	c.draw_line(Vector2(yl, ytop), Vector2(yl, ybot), fence, 3.0)
	c.draw_line(Vector2(yr, ytop), Vector2(yr, ybot), fence, 3.0)
	c.draw_line(Vector2(yl, ytop), Vector2(yr, ytop), fence, 3.0)
	c.draw_line(Vector2(yl, ybot), Vector2(gate_l - 20.0, ybot), fence, 3.0)
	c.draw_line(Vector2(gate_r + 20.0, ybot), Vector2(yr, ybot), fence, 3.0)
	for px in range(int(yl), int(yr), 60):
		c.draw_line(Vector2(px, ytop), Vector2(px, ytop + 8.0), post, 2.0)
		if px < gate_l - 20.0 or px > gate_r + 20.0:
			c.draw_line(Vector2(px, ybot - 8.0), Vector2(px, ybot), post, 2.0)
	c.draw_line(Vector2(yl + 6.0, ytop + 6.0), Vector2(yr - 6.0, ytop + 6.0), mesh, 6.0)
	for cp: Vector2 in [Vector2(yl, ytop), Vector2(yr, ytop), Vector2(yl, ybot), Vector2(yr, ybot)]:
		c.draw_circle(cp, 4.0, post)


func _draw_freedom_benches(c: CanvasItem, r: Rect2, col: Color) -> void:
	for bx: Vector2 in [
		Vector2(r.position.x + 70.0, r.position.y + 60.0),
		Vector2(r.end.x - 70.0, r.position.y + 120.0),
		Vector2(r.position.x + 90.0, r.end.y - 80.0),
	]:
		contact_shadow(c, bx, 22.0, 8.0, 0.20)
		c.draw_rect(Rect2(bx.x - 22, bx.y - 5, 44, 10), col)
		c.draw_line(Vector2(bx.x - 20, bx.y - 5), Vector2(bx.x - 20, bx.y + 8), col.darkened(0.2), 2.0)
		c.draw_line(Vector2(bx.x + 20, bx.y - 5), Vector2(bx.x + 20, bx.y + 8), col.darkened(0.2), 2.0)
	# the bench the parked owner throws the ball from
	contact_shadow(c, gate_bench, 20.0, 8.0, 0.20)
	c.draw_rect(Rect2(gate_bench.x - 18, gate_bench.y - 6, 36, 11), Color(0.54, 0.4, 0.27))


func _freedom_sign(c: CanvasItem, r: Rect2, txt: String) -> void:
	c.draw_string(font, Vector2(0, r.position.y - 14), txt, HORIZONTAL_ALIGNMENT_CENTER, 1280,
		22, Color(0.9, 0.9, 0.82))


func _draw_yard(c: CanvasItem, gravel: bool) -> void:
	# the municipal dog park: grass (or a gravel compound on the industrial
	# walks), a worn patch in the middle where every dog plays, and a fence
	var r := _freedom_rect()
	c.draw_rect(r, Color(0.40, 0.38, 0.34) if gravel else Color(0.34, 0.5, 0.32))
	c.draw_circle(r.get_center(), 150.0,
		Color(0.34, 0.32, 0.29, 0.5) if gravel else Color(0.42, 0.44, 0.3, 0.35))
	if gravel:
		# grit, in place of the grass tufts
		for gi in range(90):
			var gp := Vector2(
				r.position.x + fmod(float(gi) * 197.0, r.size.x),
				r.position.y + fmod(float(gi) * 331.0, r.size.y))
			c.draw_circle(gp, 1.6, Color(0.30, 0.29, 0.27, 0.6))
	else:
		for tf in range(28):
			var gxp := r.position.x + 20.0 + tf * ((r.size.x - 40.0) / 27.0)
			var gyp := r.position.y + 40.0 + fmod(tf * 137.0, r.size.y - 80.0)
			c.draw_line(Vector2(gxp, gyp), Vector2(gxp - 3.0, gyp - 8.0), Color(0.28, 0.44, 0.27), 2.0)
			c.draw_line(Vector2(gxp, gyp), Vector2(gxp + 3.0, gyp - 7.0), Color(0.28, 0.44, 0.27), 2.0)
	_draw_freedom_fence(c, r, gravel)
	_draw_freedom_benches(c, r, Color(0.5, 0.38, 0.26))
	_freedom_sign(c, r, "OFF-LEASH YARD" if gravel else "OFF-LEASH DOG PARK")


func _draw_clearing(c: CanvasItem) -> void:
	# a clearing in the woods: no fence, because nothing out here is fenced.
	# The trees ARE the boundary, drawn with the same renderer as the ones on
	# the trail so it reads as the same wood.
	var r := _freedom_rect()
	c.draw_rect(r, Color(0.30, 0.42, 0.26))
	c.draw_circle(r.get_center(), 170.0, Color(0.40, 0.36, 0.26, 0.55))   # trodden earth
	# Sixteen, not forty. Forty of these cost 5.7ms of a 9ms frame, measured -
	# a ring of trees does not read forty times better than a ring of sixteen.
	# The ring of trees is not drawn here any more. It was decoration you could
	# walk straight through - and a tree you can walk through is worse than no
	# tree. They are placed as real trees at build time now, so they have
	# collision, the rope wraps them, and the grove draws them.
	_draw_freedom_benches(c, r, Color(0.42, 0.33, 0.22))
	_freedom_sign(c, r, "THE CLEARING")


func _draw_dog_beach(c: CanvasItem) -> void:
	# THE DOG BEACH. The other walks all end in the same municipal field; this
	# one ends where the city ends. Dry sand, wet sand, and open sea on the
	# west - and the sea is real water: she swims in it, the ball gets thrown
	# into it, and the owner will not enjoy any of that.
	var r := _freedom_rect()
	c.draw_rect(r, Color(0.85, 0.78, 0.62))
	# The bay OPENS OUT of the seafront's coastline rather than starting
	# abruptly at the gate. Shore x comes from beach_shore_x so fill,
	# foam and gameplay water agree.
	var bend_y := GATE_Y - 300.0
	var top_y := r.position.y - 40.0
	var bot_y := r.end.y
	var shore := PackedVector2Array([
		Vector2(-330.0, top_y), Vector2(beach_shore_x(top_y), top_y),
		Vector2(beach_shore_x(bend_y), bend_y), Vector2(beach_shore_x(bot_y), bot_y),
		Vector2(-330.0, bot_y),
	])
	c.draw_colored_polygon(shore, Color(0.24, 0.44, 0.54))
	var shallow := PackedVector2Array([
		Vector2(beach_shore_x(top_y) - 90.0, top_y), Vector2(beach_shore_x(top_y), top_y),
		Vector2(beach_shore_x(bend_y), bend_y), Vector2(beach_shore_x(bot_y), bot_y),
		Vector2(beach_shore_x(bot_y) - 80.0, bot_y),
		Vector2(beach_shore_x(bend_y) - 90.0, bend_y),
	])
	c.draw_colored_polygon(shallow, Color(0.34, 0.56, 0.62))
	var wet := PackedVector2Array([
		Vector2(beach_shore_x(top_y), top_y), Vector2(beach_shore_x(top_y) + 70.0, top_y),
		Vector2(beach_shore_x(bend_y) + 70.0, bend_y),
		Vector2(beach_shore_x(bot_y) + 70.0, bot_y),
		Vector2(beach_shore_x(bot_y), bot_y), Vector2(beach_shore_x(bend_y), bend_y),
	])
	c.draw_colored_polygon(wet, Color(0.70, 0.64, 0.52))
	# dunes along the east and north instead of a fence: marram grass on pale
	# mounds is a boundary you can see without chain-link
	# Pale sand mounds on pale sand were invisible; a dune reads by its SHADED
	# side and the grass on top, not by being a slightly different beige.
	for dp: Vector2 in dune_spots:
		contact_shadow(c, dp, 27.0, 12.0, 0.16)
		c.draw_circle(dp, 27.0, Color(0.74, 0.67, 0.52))          # the shaded flank
		c.draw_circle(dp - LIGHT * 7.0, 21.0, Color(0.93, 0.88, 0.73))  # the lit crest
		for g in range(6):
			var ga := -PI * 0.62 + (float(g) - 2.5) * 0.26
			var gl := 15.0 + fmod(dp.x * 0.7 + float(g) * 3.0, 9.0)
			c.draw_line(dp - LIGHT * 5.0, dp - LIGHT * 5.0 + Vector2.from_angle(ga) * gl,
				Color(0.55, 0.62, 0.36, 0.9), 2.0)
	# the outdoor shower, a lifeguard chair and parasols: a real beach has
	# furniture, and the shower is hers - it fills the tank back up
	var sh := Vector2(BEACH_SEA_R + 150.0, r.position.y + 120.0)
	cast_shadow(c, sh, 5.0, 34.0)
	c.draw_circle(sh, 7.0, Color(0.68, 0.70, 0.72))
	c.draw_line(sh, sh + Vector2(0, -16.0), Color(0.76, 0.78, 0.80), 4.0)
	c.draw_circle(sh + Vector2(0, -18.0), 5.0, Color(0.82, 0.86, 0.88))
	for di in range(4):
		c.draw_line(sh + Vector2(-6.0 + float(di) * 4.0, -14.0),
			sh + Vector2(-6.0 + float(di) * 4.0, -4.0), Color(0.7, 0.86, 0.95, 0.5), 1.5)
	var lg := Vector2(BEACH_SEA_R + 240.0, r.get_center().y)
	cast_shadow(c, lg, 14.0, 40.0)
	c.draw_rect(Rect2(lg.x - 15.0, lg.y - 15.0, 30.0, 30.0), Color(0.86, 0.80, 0.34))
	c.draw_rect(Rect2(lg.x - 15.0, lg.y - 15.0, 30.0, 30.0), Color(0.62, 0.56, 0.22), false, 2.0)
	c.draw_rect(Rect2(lg.x - 9.0, lg.y - 9.0, 18.0, 18.0), Color(0.94, 0.90, 0.58))
	var pcol := [Color(0.85, 0.45, 0.35, 0.85), Color(0.4, 0.6, 0.75, 0.85),
		Color(0.9, 0.8, 0.4, 0.85)]
	for i in range(3):
		var pa := Vector2(r.end.x - 260.0, r.position.y + 180.0 + float(i) * 210.0)
		# a parasol from above is panels radiating from a hub, with the shade
		# it is there to cast falling clear of it
		contact_shadow(c, pa, 36.0, 30.0, 0.20)
		var pc: Color = pcol[i % 3]
		c.draw_circle(pa, 36.0, pc)
		for panel in range(8):
			var a0 := TAU * float(panel) / 8.0 + float(i) * 0.2
			c.draw_line(pa, pa + Vector2.from_angle(a0) * 36.0, pc.darkened(0.22), 2.0)
			if panel % 2 == 0:
				c.draw_colored_polygon(
					PackedVector2Array([
						pa, pa + Vector2.from_angle(a0) * 36.0,
						pa + Vector2.from_angle(a0 + TAU / 8.0) * 36.0,
					]), Color(1, 1, 1, 0.10))
		c.draw_circle(pa - LIGHT * 10.0, 12.0, Color(1, 1, 1, 0.13))   # the lit side
		c.draw_circle(pa, 5.0, Color(0.42, 0.38, 0.34))                # the pole
		c.draw_circle(pa, 2.2, Color(0.62, 0.58, 0.52))
	_draw_freedom_benches(c, r, Color(0.62, 0.5, 0.34))
	_freedom_sign(c, r, "DOG BEACH  -  OFF LEASH")


# --- writing that belongs to the world --------------------------------
#
# The title and the walk's name used to float over the level as HUD labels,
# which is the one thing on screen that admits it is a screen. They are drawn
# INTO the world now, in whatever medium that walk would actually have to hand:
# chalk on the boulevard, a stick in the sand at the beach, scuffed dirt in the
# park, a painted board at the station. Because they live in world space they
# scroll away underfoot as you set off, which is free parallax and costs one
# more string per frame while the title is up.

const SIGN_STYLES := {
	"street": "chalk", "market": "chalk", "spook": "chalk",
	"beach": "sand", "park": "dirt", "trail": "dirt",
	"station": "board", "site": "board", "scrap": "board",
	"rain": "wet", "oldtown": "tile", "tutorial": "chalk",
}


func _hand_text(at: Vector2, txt: String, px: int, col: Color, jitter: float,
		key: float) -> void:
	# Each glyph placed by hand with its own wobble and tilt, so it reads as
	# something a person drew rather than something a font laid out. Advance
	# widths come from the font, so it stays centred whatever it says.
	var f := font
	var total: float = f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
	var x := at.x - total * 0.5
	for i in range(txt.length()):
		var ch := txt.substr(i, 1)
		var w: float = f.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
		# deterministic per-character wobble: same title, same wobble, always
		var n := sin(float(i) * 12.9898 + key) * 43758.5453
		var wob := fmod(absf(n), 1.0) * 2.0 - 1.0
		var n2 := sin(float(i) * 78.233 + key * 1.7) * 12345.6789
		var wob2 := fmod(absf(n2), 1.0) * 2.0 - 1.0
		draw_set_transform(Vector2(x + w * 0.5, at.y + wob * jitter),
			wob2 * jitter * 0.02, Vector2.ONE)
		draw_char(f, Vector2(-w * 0.5, 0.0), ch, px, col)
		x += w
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_world_text(at: Vector2, txt: String, px: int, style: String,
		key := 1.0) -> void:
	match style:
		"chalk":
			# pastel chalk: a soft dusty ghost under a brighter stroke, drawn
			# twice off-register the way chalk goes down
			_hand_text(at + Vector2(2, 2), txt, px, Color(0.55, 0.52, 0.48, 0.30), 2.2, key)
			_hand_text(at, txt, px, Color(0.96, 0.93, 0.86, 0.80), 2.2, key)
			_hand_text(at - Vector2(1, 1), txt, px, Color(1, 1, 1, 0.35), 2.4, key + 3.0)
		"sand":
			# a trench dragged with a stick: dark inside, bright sand piled on
			# the light side of the furrow
			_hand_text(at + LIGHT * 3.0, txt, px, Color(0.62, 0.55, 0.42, 0.75), 3.0, key)
			_hand_text(at, txt, px, Color(0.48, 0.42, 0.32, 0.85), 3.0, key)
			_hand_text(at - LIGHT * 2.0, txt, px, Color(0.97, 0.93, 0.82, 0.55), 3.0, key)
		"dirt":
			# scuffed into bare earth with a paw
			_hand_text(at, txt, px, Color(0.34, 0.28, 0.20, 0.75), 3.4, key)
			_hand_text(at - Vector2(1, 2), txt, px, Color(0.52, 0.46, 0.34, 0.5), 3.4, key + 2.0)
		"wet":
			# written on wet asphalt: it runs, and the shine sits under it
			_hand_text(at + Vector2(0, 3), txt, px, Color(0.55, 0.62, 0.70, 0.35), 2.0, key)
			_hand_text(at, txt, px, Color(0.80, 0.86, 0.92, 0.70), 2.0, key)
		"tile":
			# painted tiles set into the wall of the alley
			var w: float = font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
			var pad := 16.0
			var r := Rect2(at.x - w * 0.5 - pad, at.y - float(px) * 0.86,
				w + pad * 2.0, float(px) * 1.2)
			draw_rect(r, Color(0.90, 0.88, 0.82))
			draw_rect(r, Color(0.30, 0.42, 0.62), false, 3.0)
			var tx := r.position.x
			while tx < r.end.x:
				draw_line(Vector2(tx, r.position.y), Vector2(tx, r.end.y),
					Color(0.72, 0.72, 0.70, 0.6), 1.0)
				tx += r.size.y * 0.5
			_hand_text(at, txt, px, Color(0.18, 0.30, 0.55, 0.92), 0.8, key)
		_:
			# a works board or a departures board: dot-matrix on steel
			var bw: float = font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
			var br := Rect2(at.x - bw * 0.5 - 22.0, at.y - float(px) * 0.9,
				bw + 44.0, float(px) * 1.3)
			draw_rect(br, Color(0.14, 0.15, 0.16))
			draw_rect(br, Color(0.40, 0.42, 0.44), false, 3.0)
			draw_rect(Rect2(br.position.x + 4.0, br.position.y + 4.0, br.size.x - 8.0, 3.0),
				Color(1, 1, 1, 0.10))
			_hand_text(at, txt, px, Color(0.98, 0.78, 0.28, 0.95), 0.0, key)


func _draw_ground_title() -> void:
	# On the title screen the game's name is chalked on the ground she is
	# standing on; on the walk-select screen it is the walk's name, in that
	# walk's own medium. Both scroll away with the world once you set off,
	# which is the whole reason to draw them here rather than on the HUD.
	var style := String(SIGN_STYLES.get(lvl, "chalk"))
	var mid := 640.0
	if menu_step == 0:
		_draw_world_text(Vector2(mid, START_Y - 232.0), "PATH OF", 52, style, 1.0)
		_draw_world_text(Vector2(mid, START_Y - 176.0), "LEASH RESISTANCE", 52, style, 2.0)
		_draw_world_text(Vector2(mid, START_Y - 132.0), "you are the dog", 22, style, 3.0)
		return
	var name := String(Game.LEVEL_NAMES[lvl]).to_upper()
	var y := START_Y - 190.0
	_draw_world_text(Vector2(mid, y), name, 46, style, 4.0)
	# The name is Catalan for character; this says what it MEANS, because the
	# game ships in English and nobody should have to guess what a walk is.
	# Smaller and set under the name, in the same medium, so it reads as a
	# gloss rather than as a second title.
	var gloss := String(Game.LEVEL_SUBTITLES.get(lvl, ""))
	if gloss != "":
		_draw_world_text(Vector2(mid, y + 30.0), gloss, 21, style, 8.0)
	if not Game.is_unlocked(lvl):
		_draw_world_text(Vector2(mid, y + 62.0), "LOCKED", 24, style, 5.0)
	elif menu_step == 1:
		# the browse arrows, in the same medium as the name
		var w: float = font.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, 46).x
		_draw_world_text(Vector2(mid - w * 0.5 - 44.0, y), "<", 46, style, 6.0)
		_draw_world_text(Vector2(mid + w * 0.5 + 44.0, y), ">", 46, style, 7.0)
	# and no more than that: the records, the owner and the weather stay on the
	# HUD, where a changing value belongs


func _draw_seafront_works(vt: float, vb: float) -> void:
	# THE OLD DISTILLERY. The landmark of this stretch of coast is a low
	# industrial works with one very tall, very slender brick chimney, and from
	# above the chimney is almost nothing - a small circle. What makes it read
	# as a landmark is its SHADOW: the one light throws it right across the
	# promenade, so you walk through it, which is the only way a tall thing can
	# announce itself in a top-down game.
	#
	# The real works carries a liqueur brand that is very much still trading,
	# so nothing of it is borrowed but the architecture: an old seafront
	# distillery is a shed with a chimney, and that is vernacular rather than
	# anybody's property. The sign reads LA FABRICA - the factory.
	const WORKS_Y := -2450.0
	if WORKS_Y < vt - 900.0 or WORKS_Y > vb + 900.0:
		return
	var wx := 1190.0
	# the sheds: low, pale rendered walls with ribbed roofs
	for i in range(3):
		var sy := WORKS_Y + float(i) * 240.0 - 240.0
		draw_rect(Rect2(wx - 60.0, sy, 190.0, 200.0), Color(0.80, 0.76, 0.66))
		# barrel-vaulted roof ribs, which is what says "works" and not "flats"
		for r in range(9):
			var ry := sy + 14.0 + float(r) * 21.0
			draw_line(Vector2(wx - 54.0, ry), Vector2(wx + 118.0, ry),
				Color(0.62, 0.63, 0.62), 5.0)
		draw_rect(Rect2(wx - 60.0, sy, 190.0, 200.0), Color(0.32, 0.29, 0.25), false, 2.5)
	# the chimney: a tapering brick tower, and the long shadow that sells it
	var cx := wx - 34.0
	var cy := WORKS_Y
	cast_shadow(self, Vector2(cx, cy), 15.0, 340.0, 0.26)
	draw_circle(Vector2(cx, cy), 17.0, Color(0.52, 0.34, 0.25))
	draw_circle(Vector2(cx, cy), 12.5, Color(0.63, 0.42, 0.30))
	draw_circle(Vector2(cx - 2.0, cy - 2.0), 8.0, Color(0.72, 0.50, 0.36))
	draw_circle(Vector2(cx, cy), 5.0, Color(0.17, 0.14, 0.13))
	# a painted sign on the seaward shed wall, facing the walk
	_draw_world_text(Vector2(wx + 16.0, WORKS_Y + 176.0), "LA FABRICA", 17, "paint", 9.0)


func _draw_park_props(c: CanvasItem, vt: float, vb: float) -> void:
	for pp in park_props:
		var p: Vector2 = pp.pos
		# these were drawn in full every redraw with no culling at all
		if p.y < vt - 60.0 or p.y > vb + 60.0:
			continue
		var prog := float(pp.prog)
		var done: bool = pp.done
		# everything gets a shadow: it is an object, not a decal. Uprights get
		# a cast one, things lying on the ground get a contact patch.
		match String(pp.kind):
			"post":
				cast_shadow(c, p, 5.0, 34.0)
			"shrub":
				contact_shadow(c, p, 15.0, 9.0)
			"log", "driftwood":
				contact_shadow(c, p, 17.0, 6.0)
			"dig":
				pass       # a hole in the ground casts nothing
			_:
				contact_shadow(c, p, 14.0, 7.0)
		match String(pp.kind):
			"dig":
				# A HOLE, which means a rim of thrown earth around it and dark
				# inside - flat brown circles read as stains on the grass, and
				# this is the main reward for wandering off the path.
				var soil := Color(0.34, 0.26, 0.18)
				# spoil heaped on the far side, where a digging dog puts it
				c.draw_circle(p + LIGHT * 9.0, 16.0, soil.lightened(0.10))
				c.draw_circle(p + LIGHT * 12.0, 10.0, soil.lightened(0.22))
				c.draw_circle(p, 17.0, soil.darkened(0.10))
				# the pit: darker toward the light side, where the wall is
				c.draw_circle(p, 12.0 + prog * 3.0, soil.darkened(0.42 + prog * 0.2))
				c.draw_circle(p - LIGHT * 3.0, 8.0 + prog * 3.0, soil.darkened(0.62))
				c.draw_arc(p, 13.0 + prog * 3.0, PI * 0.95, PI * 1.95, 14,
					soil.lightened(0.30), 2.0)
				# clods and a couple of scratched-up roots
				for i in range(5):
					var a := TAU * float(i) / 5.0 + p.x * 0.02
					c.draw_circle(p + Vector2.from_angle(a) * (15.0 + prog * 6.0), 3.0, soil)
				c.draw_line(p + Vector2(-14, 6), p + Vector2(-6, 10), soil.lightened(0.3), 1.5)
				if done:
					# the prize, unearthed and left sitting in the hole
					c.draw_circle(p, 9.0, soil.darkened(0.35))
					c.draw_rect(Rect2(p.x - 7.0, p.y - 2.5, 14.0, 5.0), Color(0.92, 0.89, 0.80))
					c.draw_circle(p + Vector2(-7.0, 0.0), 3.4, Color(0.92, 0.89, 0.80))
					c.draw_circle(p + Vector2(7.0, 0.0), 3.4, Color(0.92, 0.89, 0.80))
				elif prog > 0.05:
					c.draw_arc(p, 22.0, -PI / 2.0, -PI / 2.0 + TAU * prog / 1.1, 18, Color(1, 0.9, 0.5), 3.0)
			"log":
				# a fallen log: bark, end grain, and a couple of knots
				var bark := Color(0.40, 0.30, 0.20)
				c.draw_rect(Rect2(p.x - 30.0, p.y - 9.0, 60.0, 18.0), bark)
				c.draw_rect(Rect2(p.x - 30.0, p.y - 9.0, 60.0, 5.0), bark.lightened(0.18))
				c.draw_circle(Vector2(p.x + 30.0, p.y), 9.0, Color(0.62, 0.50, 0.34))
				c.draw_arc(Vector2(p.x + 30.0, p.y), 5.0, 0, TAU, 10, Color(0.48, 0.38, 0.25), 1.5)
				c.draw_circle(Vector2(p.x - 8.0, p.y - 1.0), 3.0, bark.darkened(0.30))
			"driftwood":
				var pale := Color(0.68, 0.63, 0.55)
				c.draw_rect(Rect2(p.x - 32.0, p.y - 6.0, 64.0, 12.0), pale)
				c.draw_line(p + Vector2(-32, -1), p + Vector2(32, -1), pale.darkened(0.22), 2.0)
				c.draw_line(p + Vector2(8, -6), p + Vector2(22, -16), pale, 5.0)
			"tyre":
				c.draw_circle(p, 17.0, Color(0.14, 0.14, 0.15))
				c.draw_circle(p, 9.0, Color(0.26, 0.30, 0.24))
				for i in range(10):
					var a := TAU * float(i) / 10.0
					c.draw_line(p + Vector2.from_angle(a) * 11.0, p + Vector2.from_angle(a) * 17.0, Color(0.24, 0.24, 0.26), 2.0)
			"rock":
				# faceted rather than round: a boulder is flat planes, and the
				# planes are what catch the light differently
				var rp := PackedVector2Array()
				for i in range(7):
					var a := TAU * float(i) / 7.0 + p.y * 0.01
					var rr := 13.0 + fmod(float(i) * 5.7 + p.x * 0.03, 4.0)
					rp.append(p + Vector2(cos(a) * rr, sin(a) * rr * 0.88))
				c.draw_colored_polygon(rp, Color(0.46, 0.44, 0.42))
				var top := PackedVector2Array()
				for i in range(5):
					var a2 := TAU * float(i) / 5.0 + 0.4
					top.append(p - LIGHT * 4.0 + Vector2(cos(a2), sin(a2) * 0.9) * 8.0)
				c.draw_colored_polygon(top, Color(0.63, 0.61, 0.57))
				c.draw_polyline(rp, Color(0.34, 0.33, 0.32, 0.8), 1.4)
			"post":
				# A sniff post: a round timber post with a chamfered top, the
				# grain showing, and the bare patch every dog in the park has
				# worn round its foot.
				c.draw_circle(p, 15.0, Color(0.44, 0.40, 0.28, 0.40))
				c.draw_rect(Rect2(p.x - 5.0, p.y - 26.0, 10.0, 30.0), Color(0.40, 0.29, 0.19))
				c.draw_rect(Rect2(p.x - 5.0, p.y - 26.0, 4.0, 30.0), Color(0.50, 0.37, 0.24))
				for gi in range(3):
					c.draw_line(Vector2(p.x - 2.0 + float(gi) * 2.5, p.y - 24.0),
						Vector2(p.x - 2.0 + float(gi) * 2.5, p.y + 2.0),
						Color(0.34, 0.25, 0.16, 0.7), 1.0)
				# the cut top, seen from above: end grain in rings
				c.draw_circle(p + Vector2(0.0, -27.0), 7.0, Color(0.60, 0.47, 0.30))
				c.draw_arc(p + Vector2(0.0, -27.0), 4.0, 0, TAU, 10, Color(0.48, 0.36, 0.23), 1.4)
				c.draw_arc(p + Vector2(0.0, -27.0), 6.5, 0, TAU, 12, Color(0.42, 0.31, 0.20), 1.2)
			"trough":
				# A galvanised water trough: a thick rim, water sitting BELOW
				# it, a highlight where the light hits the surface, and a
				# slow ripple. It was three flat rectangles.
				var tw := Time.get_ticks_msec() / 1000.0
				c.draw_rect(Rect2(p.x - 23.0, p.y - 13.0, 46.0, 26.0), Color(0.34, 0.34, 0.38))
				c.draw_rect(Rect2(p.x - 23.0, p.y - 13.0, 46.0, 5.0), Color(0.52, 0.52, 0.56))
				# the water, inset and darker at the light-side wall
				c.draw_rect(Rect2(p.x - 18.0, p.y - 8.0, 36.0, 16.0), Color(0.22, 0.38, 0.48))
				c.draw_rect(Rect2(p.x - 18.0, p.y - 8.0, 36.0, 4.0), Color(0.16, 0.28, 0.38))
				c.draw_rect(Rect2(p.x - 15.0, p.y - 4.0, 30.0, 9.0), Color(0.34, 0.54, 0.66))
				# ripples, and the sky in it
				for i in range(2):
					var ry := p.y - 2.0 + float(i) * 6.0
					var rw := 11.0 + sin(tw * 1.3 + float(i) * 2.0) * 4.0
					c.draw_line(Vector2(p.x - rw, ry), Vector2(p.x + rw, ry),
						Color(0.72, 0.86, 0.92, 0.30), 1.5)
				c.draw_circle(p + Vector2(-9.0, -3.0), 3.0, Color(0.86, 0.94, 0.98, 0.35))
			_:
				# a shrub: clustered lobes, lit per lobe rather than one blob
				# with a highlight, plus leaf tips breaking the outline
				var g1 := Color(0.17, 0.28, 0.17)
				for i in range(5):
					var a := TAU * float(i) / 5.0 + p.y * 0.01
					c.draw_circle(p + Vector2.from_angle(a) * 8.0, 10.0, g1)
				for i in range(5):
					var a2 := TAU * float(i) / 5.0 + p.y * 0.01
					c.draw_circle(p + Vector2.from_angle(a2) * 8.0 - LIGHT * 4.0, 5.5,
						Color(0.28, 0.43, 0.25))
				for i in range(6):
					var a3 := TAU * float(i) / 6.0 + p.x * 0.02
					c.draw_circle(p + Vector2.from_angle(a3) * 16.0, 3.0, g1.lightened(0.10))
				if done:
					c.draw_circle(p + Vector2(9, -12), 2.6, Color(0.85, 0.85, 0.6, 0.7))
		# the sniff affordance: a soft scent bloom while she is working on it
		if not done and prog > 0.05 and String(pp.kind) != "dig":
			for i in range(2):
				var rr := 16.0 + prog * 12.0 + float(i) * 7.0
				c.draw_arc(p, rr, 0, TAU, 16, Color(0.85, 0.9, 0.75, 0.28 * (1.0 - float(i) * 0.4)), 1.5)


func _build_substance_zones() -> void:
	# Each walk offers whatever it would plausibly have lying about. The two
	# that also SLOW her (mud, wet cement) keep doing so; the rest are purely
	# a mess to carry around, which is the fun of them.
	substance_zones.clear()
	for pt: Dictionary in patches:
		# glazed tile is a surface, not a substance: it is fast and slippery
		# but it does not come away on her paws the way wet cement does
		if not SUBSTANCES.has(String(pt["kind"])):
			continue
		substance_zones.append({"rect": patch_bounds(pt), "patch": pt,
			"kind": String(pt["kind"]), "slow": true})
	for cz in cement_zones:
		substance_zones.append({"rect": cz, "kind": "cement", "slow": true})
	var w := sw_r - sw_l
	match lvl:
		"site":
			# a works has wet paint as well as wet cement
			substance_zones.append({"rect": Rect2(sw_l + 20.0, -2500.0, w * 0.4, 150.0), "kind": "paint"})
		"beach":
			# the whole sand side, which is most of the beach
			substance_zones.append({"rect": Rect2(230.0, GATE_Y, 150.0, absf(GATE_Y) + 400.0), "kind": "sand"})
		"market":
			# the fishmonger's patch, and everyone will know about it
			substance_zones.append({"rect": Rect2(sw_l + 30.0, -3050.0, w * 0.35, 130.0), "kind": "fish"})
		"scrap":
			substance_zones.append({"rect": Rect2(sw_l + 40.0, -1850.0, w * 0.45, 140.0), "kind": "oil"})
		"spook":
			substance_zones.append({"rect": Rect2(sw_l + 25.0, -2150.0, w * 0.5, 160.0), "kind": "confetti"})
		"trail":
			substance_zones.append({"rect": Rect2(sw_l + 20.0, -3650.0, w * 0.5, 150.0), "kind": "mud", "slow": true})
	# snow turns the whole walk to slush underfoot, whatever the level
	if Game.weather == "snow":
		substance_zones.append({"rect": Rect2(sw_l, GATE_Y, w, absf(GATE_Y) + 500.0), "kind": "slush"})


func _build_freedom_area() -> void:
	freedom_kind = String(FREEDOM_KINDS.get(lvl, "yard"))
	water.clear()
	if pond.size.x > 0.0:
		water.append(pond)
	if freedom_kind == "beach":
		# The sea, in two pieces that meet at the gate: a band along the whole
		# passeig (so she can go in ANYWHERE on the walk, which is the first
		# thing anyone tries on a seafront), and the wide bay in the dog beach
		# at the top. The bay uses thin horizontal strips so the diagonal
		# shoreline from beach_shore_x is wet in gameplay, not just on screen.
		water.append(Rect2(-360.0, GATE_Y - 40.0, 590.0, absf(GATE_Y) + 500.0))
		var strip_y := freedom_lo - 40.0
		var strip_h := 36.0
		var gate_y := GATE_Y - 30.0
		while strip_y < gate_y:
			var shore := beach_shore_x(strip_y + strip_h * 0.5)
			water.append(Rect2(-330.0, strip_y, shore + 330.0, strip_h + 0.5))
			strip_y += strip_h


func _patch_clear(pt: Dictionary) -> bool:
	# is this somewhere a patch could sensibly be?
	var b := patch_bounds(pt)
	var c := patch_centre(pt)
	if pond.size.x > 0.0 and pond.intersects(b):
		return false
	for w: Rect2 in water:
		if w.intersects(b):
			return false
	for mh: Vector2 in manholes:
		if b.has_point(mh):
			return false
	for cl: Rect2 in cellars:
		if cl.intersects(b):
			return false
	var e := walk_edges(c.y)
	return c.x >= e.x and c.x <= e.y


func _settle_patches() -> void:
	# Patches are authored by eye, and a perfectly plausible y can still land
	# in the pond or on top of an open manhole - which is exactly what the
	# first pass did, and it read as nonsense rather than as a mistake.
	#
	# So each one walks along the path until it finds ground that could hold
	# it, searching outward in both directions from where it was authored. It
	# never invents a position from nothing: the authored spot is the intent
	# and this only moves it as far as it has to. level_check still fails if a
	# patch cannot be placed at all, so nothing is quietly dropped.
	for i in range(patches.size()):
		var pt: Dictionary = patches[i]
		var y0 := float(pt["y"])
		if _patch_clear(pt):
			continue
		for step in range(16):
			var off: float = float(step / 2 + 1) * 85.0
			pt["y"] = y0 + (off if step % 2 == 0 else -off)
			if _patch_clear(pt):
				break
		patches[i] = pt


func _lift_props_out_of_water() -> void:
	# Anything the level data put in a pond or the sea gets pushed to the
	# nearest shore. The walks that reuse another walk's geometry inherit its
	# water but not its prop placement, which is how El Bosc ended up with a
	# roadworks cone standing in the middle of the pond.
	if water.is_empty():
		return
	var groups: Array = [parasols, benches, bins, tables, astands, fountains,
		cone_spots, manholes, performers, candy_spots, wallcat_spots, guard_posts]
	for arr: Array in groups:
		for i in range(arr.size()):
			arr[i] = _nearest_dry(arr[i] as Vector2)
	for k in kebabs:
		k.pos = _nearest_dry(k.pos as Vector2)
	for h in hydrants:
		h.pos = _nearest_dry(h.pos as Vector2)
	for tw in towels:
		var tr: Rect2 = tw.rect
		var moved := _nearest_dry(tr.get_center())
		tw.rect = Rect2(moved - tr.size * 0.5, tr.size)


func _nearest_dry(at: Vector2) -> Vector2:
	for w: Rect2 in water:
		if not w.grow(10.0).has_point(at):
			continue
		# out the closest side, far enough that its footprint is clear too
		var d_left: float = at.x - w.position.x
		var d_right: float = w.end.x - at.x
		var d_top: float = at.y - w.position.y
		var d_bot: float = w.end.y - at.y
		var m: float = minf(minf(d_left, d_right), minf(d_top, d_bot))
		if m == d_left:
			at.x = w.position.x - 30.0
		elif m == d_right:
			at.x = w.end.x + 30.0
		elif m == d_top:
			at.y = w.position.y - 30.0
		else:
			at.y = w.end.y + 30.0
	return at


func _build_dunes() -> void:
	# The dune line is the beach's boundary in place of a fence, so it has to
	# BE one: these get collision below, because a boundary you can stroll
	# through is just a pattern on the floor.
	dune_spots.clear()
	if freedom_kind != "beach":
		return
	var r := _freedom_rect()
	for i in range(26):
		var f := float(i) / 25.0
		if i % 2 == 0:
			dune_spots.append(Vector2(r.end.x - 70.0,
				lerpf(r.position.y + 60.0, r.end.y - 60.0, f)))
		else:
			dune_spots.append(Vector2(lerpf(r.position.x + 60.0, r.end.x - 60.0, f),
				r.position.y + 40.0))


func _build_park_props() -> void:
	# Spread across the whole width, deliberately AWAY from the straight line
	# between gate and meadow, so poking about off the direct route is what
	# finds things. Local rng, so the deterministic autowalk is untouched.
	park_props.clear()
	var r := RandomNumberGenerator.new()
	r.seed = 0xD06BA55
	var flavour := ["log", "dig", "shrub", "post", "dig", "shrub"]
	match lvl:
		"beach": flavour = ["driftwood", "dig", "rock", "dig", "rock"]
		"scrap", "site": flavour = ["tyre", "log", "dig", "tyre"]
		"trail", "park": flavour = ["log", "dig", "shrub", "shrub", "post", "dig"]
	var lo := freedom_lo + 70.0
	var hi := GATE_Y - 90.0
	# Guarantee the essentials rather than hoping the dice provide them: on
	# junk-flavoured walks a random draw left only one dig patch, which the
	# sanity sweep rightly failed. Digs are the main reward for exploring, so
	# they are placed first, spread across the width.
	var dig_xs: Array[float] = [250.0, 640.0, 1030.0]
	if freedom_kind == "beach":
		dig_xs = [560.0, 820.0, 1060.0]   # digging in dry sand, not in the sea
	var dig_fs: Array[float] = [0.22, 0.68, 0.42]
	for i in range(3):
		var gy := lerpf(lo + 60.0, hi - 60.0, dig_fs[i])
		park_props.append({"pos": Vector2(dig_xs[i], gy), "kind": "dig", "done": false, "prog": 0.0})
	for i in range(14):
		var kind: String = flavour[r.randi() % flavour.size()]
		# bias to the flanks: the middle is the fetch runway
		var side_pick := r.randf()
		var x := 0.0
		if freedom_kind == "beach":
			# all of it on the dry sand, east of the tide line
			x = r.randf_range(520.0, 780.0) if side_pick < 0.4 else r.randf_range(800.0, 1120.0)
		elif side_pick < 0.42:
			x = r.randf_range(140.0, 430.0)
		elif side_pick < 0.84:
			x = r.randf_range(860.0, 1150.0)
		else:
			x = r.randf_range(470.0, 820.0)
		var at := Vector2(x, r.randf_range(lo, hi))
		# keep clear of the owner's bench and the park slots
		if at.distance_to(gate_bench) < 110.0:
			continue
		# and out of the water: driftwood floating twenty metres out to sea is
		# not a sniffable object, it is a bug
		var in_water := false
		for w: Rect2 in water:
			if w.grow(24.0).has_point(at):
				in_water = true
		if in_water:
			continue
		var clear := true
		for slot in PAIR_PARK_SPOTS:
			if at.distance_to(slot.position as Vector2) < 90.0:
				clear = false
		if not clear:
			continue
		park_props.append({"pos": at, "kind": kind, "done": false, "prog": 0.0})
	# one water trough near the gate, because a romp is thirsty work
	# one water trough near the gate, because a romp is thirsty work - by the
	# shower on the beach, where the tap actually is
	var trough_at := Vector2(gate_bench.x - 150.0, gate_bench.y + 24.0)
	if freedom_kind == "beach":
		trough_at = Vector2(BEACH_SEA_R + 172.0, freedom_lo + 148.0)
	park_props.append({"pos": trough_at, "kind": "trough", "done": false, "prog": 0.0})


func _build_ground_detail() -> void:
	# a light dusting of wear over the whole walk: hairline cracks, grit,
	# litter, damp stains. Cheap to draw (culled, and the world redraws at
	# 30fps) but it is what stops a paved corridor looking like a colour
	# swatch. Local rng: the global sequence stays byte-identical.
	var r := RandomNumberGenerator.new()
	r.seed = 0x1CEB00DA  # fixed, so a walk wears the same way every visit
	ground_detail.clear()
	# stop at the gate: past it the off-leash space draws its own ground, and
	# pavement grit scattered over open water is not wear, it is a bug
	var y := START_Y + 200.0
	while y > GATE_Y + 20.0:
		y -= r.randf_range(55.0, 130.0)
		var kind := r.randi() % 4
		var x := r.randf_range(sw_l + 12.0, sw_r - 12.0)
		ground_detail.append({
			"pos": Vector2(x, y),
			"kind": kind,
			"rot": r.randf_range(0.0, TAU),
			"len": r.randf_range(14.0, 46.0),
			"sz": r.randf_range(1.4, 3.4),
		})


func _draw_ground_detail(vt: float, vb: float) -> void:
	var crack := Color(0.24, 0.23, 0.22, 0.30)
	var grit := Color(0.32, 0.31, 0.29, 0.36)
	var stain := Color(0.30, 0.30, 0.27, 0.13)
	var litter := [Color(0.72, 0.68, 0.58, 0.5), Color(0.55, 0.6, 0.5, 0.5)]
	for d in ground_detail:
		var p: Vector2 = d.pos
		if p.y < vt - 30.0 or p.y > vb + 30.0:
			continue
		var dir := Vector2.from_angle(float(d.rot))
		match int(d.kind):
			0:
				# a hairline crack with a kink in it
				var mid := p + dir * float(d.len) * 0.55
				var kink := mid + dir.rotated(0.5) * float(d.len) * 0.45
				draw_line(p, mid, crack, 1.4)
				draw_line(mid, kink, crack, 1.1)
			1:
				# a scatter of grit
				for g in range(3):
					draw_circle(p + dir.rotated(float(g) * 2.1) * (4.0 + g * 3.0), float(d.sz) * 0.5, grit)
			2:
				# a damp patch / old stain
				draw_circle(p, float(d.len) * 0.35, stain)
			_:
				# a bit of litter: a leaf or a scrap of paper
				var c: Color = litter[int(d.sz) % litter.size()]
				draw_line(p - dir * float(d.sz) * 1.6, p + dir * float(d.sz) * 1.6, c, float(d.sz))


func _build_bypasser_blockers() -> void:
	bypasser_blockers.clear()
	for i in range(body_pole_count):
		bypasser_blockers.append({
			"id": "pole_%d" % i,
			"center": poles[i],
			"radius": POLE_RADIUS,
		})
	for i in range(hydrants.size()):
		bypasser_blockers.append({
			"id": "hydrant_%d" % i,
			"center": hydrants[i].pos,
			"radius": HYDRANT_RADIUS,
		})
	for i in range(fountains.size()):
		bypasser_blockers.append({
			"id": "fountain_%d" % i,
			"center": fountains[i],
			"radius": FOUNTAIN_RADIUS,
		})
	for i in range(performers.size()):
		bypasser_blockers.append({
			"id": "performer_%d" % i,
			"center": performers[i],
			"radius": PERFORMER_RADIUS,
		})
	for i in range(benches.size()):
		bypasser_blockers.append({
			"id": "bench_%d" % i,
			"rect": Rect2(benches[i] - BENCH_BODY_SIZE * 0.5, BENCH_BODY_SIZE),
		})
	for i in range(vans.size()):
		bypasser_blockers.append({
			"id": "van_%d" % i,
			"rect": Rect2(vans[i] - VAN_BODY_SIZE * 0.5, VAN_BODY_SIZE),
		})
	if furgoneta.x < INF:
		bypasser_blockers.append({
			"id": "furgoneta",
			"rect": Rect2(furgoneta - VAN_BODY_SIZE * 0.5, VAN_BODY_SIZE),
		})
	for i in range(stalls.size()):
		bypasser_blockers.append({
			"id": "stall_%d" % i,
			"rect": Rect2(stalls[i] - STALL_BODY_SIZE * 0.5, STALL_BODY_SIZE),
		})
	for i in range(manholes.size()):
		bypasser_blockers.append({
			"id": "manhole_%d" % i,
			"center": manholes[i],
			"radius": MANHOLE_RADIUS,
		})
	for i in range(cellars.size()):
		bypasser_blockers.append({
			"id": "cellar_%d" % i,
			"rect": cellars[i],
		})
	if pond.size.x > 0.0 and pond.size.y > 0.0:
		bypasser_blockers.append({
			"id": "pond_0",
			"rect": pond,
			"forced_side": "right",
		})


func _build_walls() -> void:
	var walls := StaticBody2D.new()
	walls.collision_layer = 1
	var mid_y := (START_Y + GATE_Y) / 2.0
	var span := absf(START_Y - GATE_Y) + 1600.0
	# the walls sit at the LEVEL edges, not the path edges: the dog is
	# free to roam grass, sand and shoulders; the human stays on the walk
	# by inclination, not by invisible fences
	# On the beach the west wall moves out into the water, so she can actually
	# get in the sea - the whole point of walking a dog along the seafront.
	# Everywhere else it stays at the level edge.
	var west_x := -180.0 if lvl == "beach" else 40.0
	var defs := [
		[Vector2(west_x, mid_y), Vector2(100, span)],
		[Vector2(1240.0, mid_y), Vector2(100, span)],
		[Vector2(640, START_Y + 160.0), Vector2(1400, 100)],
		[Vector2(640, GATE_Y - 700.0), Vector2(1400, 100)],
	]
	for d in defs:
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = d[1]
		cs.shape = sh
		cs.position = d[0]
		walls.add_child(cs)
	add_child(walls)
	for i in range(body_pole_count):
		var sb := StaticBody2D.new()
		sb.collision_layer = 1
		sb.position = poles[i]
		var cs := CollisionShape2D.new()
		var sh := CircleShape2D.new()
		sh.radius = POLE_RADIUS
		cs.shape = sh
		sb.add_child(cs)
		add_child(sb)
	# The grove in the off-leash area used to be pure decoration you could
	# walk straight through - a flat texture, not an object. A tree is a
	# solid trunk with real heft, so it blocks bodies and the leash wraps
	# on it like any other pole.
	for d in dune_spots:
		var db := StaticBody2D.new()
		db.collision_layer = 1
		db.position = d
		var dcs := CollisionShape2D.new()
		var dsh := CircleShape2D.new()
		dsh.radius = 22.0
		dcs.shape = dsh
		db.add_child(dcs)
		add_child(db)
	for t in trees:
		var tb := StaticBody2D.new()
		tb.collision_layer = 1
		tb.position = t
		var tcs := CollisionShape2D.new()
		var tsh := CircleShape2D.new()
		tsh.radius = TREE_RADIUS
		tcs.shape = tsh
		tb.add_child(tcs)
		add_child(tb)
	# Buildings are solid, so you cannot stroll onto a roof. Only on the sides
	# that really ARE buildings, and only along the walking legs - the
	# off-leash area past the gate stays open. The boulevard and El Aguacero
	# keep their right side open because that is the bike lane and the far
	# shoulder, where the frisbee prize deliberately sits; the green walks and
	# the beach have no buildings at all.
	var wall_sides := []
	match lvl:
		"street", "rain": wall_sides = [-1.0]
		"park", "trail", "beach": wall_sides = []
		_: wall_sides = [-1.0, 1.0]
	for ws in wall_sides:
		var bx: float = (sw_l - 60.0) if ws < 0.0 else (sw_r + 60.0)
		var bb := StaticBody2D.new()
		bb.collision_layer = 1
		bb.position = Vector2(bx, (START_Y + GATE_Y) / 2.0)
		var bcs := CollisionShape2D.new()
		var bsh := RectangleShape2D.new()
		bsh.size = Vector2(120.0, absf(START_Y - GATE_Y) + 400.0)
		bcs.shape = bsh
		bb.add_child(bcs)
		add_child(bb)
	# the park's solid furniture: you go round a log, not through it. Digs,
	# shrubs and troughs stay walkable so nosing about is never obstructed.
	for pp in park_props:
		var pk := String(pp.kind)
		if pk != "log" and pk != "driftwood" and pk != "tyre":
			continue
		var lb := StaticBody2D.new()
		lb.collision_layer = 1
		lb.position = pp.pos
		var lcs := CollisionShape2D.new()
		if pk == "tyre":
			var csh := CircleShape2D.new()
			csh.radius = 16.0
			lcs.shape = csh
		else:
			var rsh := RectangleShape2D.new()
			rsh.size = Vector2(62.0, 18.0)
			lcs.shape = rsh
		lb.add_child(lcs)
		add_child(lb)
	# vans and stalls are solid rectangles: no walking over the van roof
	for v in vans:
		_add_rect_body(v, VAN_BODY_SIZE)
	if furgoneta.x < INF:
		_add_rect_body(furgoneta, VAN_BODY_SIZE)
	for st in stalls:
		_add_rect_body(st, STALL_BODY_SIZE)
	# performers have mass; you walk around a person, not through them
	for pf in performers:
		var pb := StaticBody2D.new()
		pb.collision_layer = 1
		pb.position = pf
		var pcs := CollisionShape2D.new()
		var psh := CircleShape2D.new()
		psh.radius = PERFORMER_RADIUS
		pcs.shape = psh
		pb.add_child(pcs)
		add_child(pb)


func _add_rect_body(at: Vector2, size: Vector2) -> void:
	var sb := StaticBody2D.new()
	sb.collision_layer = 1
	sb.position = at
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = size
	cs.shape = sh
	sb.add_child(cs)
	add_child(sb)


func _build_entities() -> void:
	leash = Node2D.new()
	leash.set_script(load("res://leash.gd"))
	leash.z_index = 5
	add_child(leash)

	dog = CharacterBody2D.new()
	dog.set_script(load("res://dog.gd"))
	dog.position = Vector2(700, START_Y)
	add_child(dog)
	dog.setup(self)

	human = CharacterBody2D.new()
	human.set_script(load("res://human.gd"))
	human.position = Vector2(600, START_Y - 70.0)
	add_child(human)
	human.setup(self)

	leash.setup(dog, human, poles, LEASH_LENGTH)
	leash.hero = true  # the player's rope draws every frame; NPC ropes at 30fps
	leash.furniture_poles = _furniture_wrap_poles()

	edge_layer = Node2D.new()
	edge_layer.set_script(load("res://edgelayer.gd"))
	edge_layer.z_index = -5   # behind everything in the world
	add_child(edge_layer)
	edge_layer.setup(self)
	verge_layer = Node2D.new()
	verge_layer.set_script(load("res://vergelayer.gd"))
	# above the ground pass, below the actors and props
	verge_layer.z_index = 1
	add_child(verge_layer)
	verge_layer.setup(self)
	# the off-leash space gets the same treatment: it is a fixed scene, so it
	# is drawn once onto its own canvas rather than thirty times a second
	freedomlayer = Node2D.new()
	freedomlayer.set_script(load("res://freedomlayer.gd"))
	freedomlayer.z_index = -9
	add_child(freedomlayer)
	freedomlayer.setup(self)
	cam = Camera2D.new()
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 6.0
	# the walkway is only ~680px of a 1280px frame, so half the screen used
	# to be empty verge and the characters read as specks. Pushing in fills
	# the frame and makes the animation and the rope legible - the single
	# biggest framing win available. Trade-off: less warning time on
	# oncoming hazards, so this is a feel dial (1.0 = the old framing).
	cam.zoom = Vector2(CAM_ZOOM, CAM_ZOOM)
	cam.position = Vector2(640, START_Y - 120.0)
	add_child(cam)
	cam.make_current()


const LEVEL_GOAL_IDS := {
	"street": ["mark", "sniff", "phone", "paws", "bag", "fetch", "tofu", "close", "fling", "carry", "combo", "prize"],
	"park": ["mark", "sniff", "phone", "paws", "bag", "fetch", "tofu", "hi", "drink", "combo", "prize"],
	"beach": ["mark", "sniff", "phone", "paws", "bag", "fetch", "tofu", "snack", "save", "combo", "prize"],
	"rain": ["mark", "sniff", "phone", "paws", "bag", "fetch", "tofu", "close", "drink", "combo", "prize"],
	"market": ["mark", "sniff", "phone", "paws", "bag", "fetch", "tofu", "snack", "zoom", "carry", "combo", "prize"],
	"oldtown": ["mark", "sniff", "phone", "paws", "bag", "fetch", "tofu", "cats", "snack", "combo", "prize"],
	"trail": ["mark", "sniff", "phone", "paws", "bag", "fetch", "tofu", "chase", "drink", "combo", "prize"],
	"station": ["mark", "sniff", "phone", "paws", "bag", "fetch", "tofu", "close", "snack", "combo", "prize"],
	"site": ["mark", "sniff", "phone", "paws", "bag", "fetch", "tofu", "close", "snack", "combo", "prize"],
	"spook": ["mark", "sniff", "phone", "paws", "bag", "fetch", "tofu", "tummy", "snack", "combo", "prize"],
	"scrap": ["mark", "sniff", "phone", "paws", "bag", "fetch", "tofu", "ghost", "unseen", "combo", "prize"],
	# El Parc leans on what the terraces are for: carving them (fling) and
	# riding the serpentine bench (combo), plus the park staples.
	"guell": ["mark", "sniff", "phone", "paws", "bag", "fetch", "tofu", "hi",
		"drink", "fling", "combo", "prize"],
}


func _goal_defs() -> Dictionary:
	# every goal the game knows, keyed by a stable id (persistence-facing)
	return {
		"mark": {"text": "claim %d spots", "target": 5, "fn": func() -> int: return marks.size()},
		"sniff": {"text": "%d proper sniffs", "target": 4, "fn": func() -> int: return sniffs_done},
		"phone": {"text": "get the phone home unscratched", "target": 1, "fn": func() -> int: return 1 if phone_hp == 3 else 0},
		"paws": {"text": "come home unscathed yourself", "target": 1, "fn": func() -> int: return 1 if dog_hits == 0 else 0},
		"bag": {"text": "have your business bagged", "target": 1, "fn": func() -> int: return 1 if poop_state == 2 and not bag_pending else 0},
		"fetch": {"text": "fetch %d balls back", "target": 3, "fn": func() -> int: return romp_catches},
		"tofu": {"text": "bring Tofu home", "target": 1, "fn": func() -> int: return 1 if tofu_home else 0},
		"hi": {"text": "greet %d other dogs", "target": 3, "fn": func() -> int: return dogs_greeted},
		"drink": {"text": "have a proper long drink", "target": 1, "fn": func() -> int: return 1 if drunk_amount >= 0.4 else 0},
		"zoom": {"text": "run the zoomies right out", "target": 1, "fn": func() -> int: return 1 if dog.energy <= 0.25 else 0},
		"chase": {"text": "see off %d critters", "target": 2, "fn": func() -> int: return squirrels_chased},
		"close": {"text": "%d near misses with traffic", "target": 3, "fn": func() -> int: return close_calls},
		"save": {"text": "haul the human clear %d times", "target": 2, "fn": func() -> int: return saves_done},
		"fling": {"text": "tetherball the human off a pole", "target": 1, "fn": func() -> int: return flings_done},
		"tangle": {"text": "tangle leashes with a stranger", "target": 1, "fn": func() -> int: return 1 if tangles >= 1 else 0},
		"snack": {"text": "hoover up %d dropped snacks", "target": 2, "fn": func() -> int: return kebabs_eaten},
		"cats": {"text": "see off %d wall cats", "target": 3, "fn": func() -> int: return wall_cats_spooked},
		"carry": {"text": carry_text, "target": 1, "fn": func() -> int: return 1 if carry_state >= 2 else 0},
		"combo": {"text": "land an x%d combo", "target": 5, "fn": func() -> int: return int(combo.best_mult) if combo != null else 0},
		"tummy": {"text": "walk past every chocolate", "target": 1, "fn": func() -> int: return 1 if candy_eaten == 0 else 0},
		"ghost": {"text": "cross the yard, wake nobody", "target": 1, "fn": func() -> int: return 1 if guards_woken == 0 else 0},
		"unseen": {"text": "never once be spotted", "target": 1, "fn": func() -> int: return 1 if times_spotted == 0 else 0},
		"prize": {"text": prize_text, "target": 1, "fn": func() -> int: return 1 if prize_taken else 0},
	}


func _build_quests() -> void:
	# a fixed ~10-goal list per level (Tony Hawk style): completing a goal
	# on any run marks it done for that level forever. Repeating goals,
	# a couple of level flavours, and the unique hazardous prize.
	if tutorial_mode:
		active_quests.clear()
		tofu_quest_active = false
		return
	var defs := _goal_defs()
	var ids: Array = LEVEL_GOAL_IDS.get(lvl, LEVEL_GOAL_IDS["street"])
	for id in ids:
		var d: Dictionary = defs[id]
		active_quests.append({
			"id": id, "text": d.text, "target": int(d.target), "fn": d.fn,
			"was_true": int(d.fn.call()) >= int(d.target),
		})
	tofu_quest_active = ("tofu" in ids) and not Game.goal_done(lvl, "tofu")


func _quest_text(q: Dictionary) -> String:
	var s: String = q.text
	if "%d" in s:
		s = s % int(q.target)
	return s


func _peek_goals() -> void:
	goals_peek = 3.0


func _credit_goal(q: Dictionary) -> void:
	# award + persist a goal the first time it completes this run
	if tutorial_mode:
		return
	var id: String = q.id
	if run_goals_hit.has(id):
		return
	run_goals_hit[id] = true
	_peek_goals()
	bones += 5
	var newly: bool = Game.mark_goal(lvl, id) if not Game.daily else false
	var tag := "GOAL! " if (newly or Game.daily) else "goal (again) "
	feed.say(tag + _quest_text(q), EventFeed.Tone.GOOD)


func _check_goals() -> void:
	# accumulate goals credit the moment they cross target; "maintain"
	# goals (true from the start, e.g. unscratched phone) are only judged
	# at the finish so they cannot auto-complete on frame one
	for q in active_quests:
		if q.was_true or run_goals_hit.has(q.id):
			continue
		if int(q.fn.call()) >= int(q.target):
			_credit_goal(q)


func _spawn_cones() -> void:
	# real, kickable cones at every work site plus a few loose ones
	var spots: Array[Vector2] = []
	spots.append_array(cone_spots)
	for m in manholes:
		spots.append(m + Vector2(32, -18))
		spots.append(m + Vector2(-30, 22))
		spots.append(m + Vector2(26, 28))
		spots.append(m + Vector2(-26, -26))
	for c in cellars:
		spots.append(Vector2(c.end.x + 14, c.position.y + 24))
		spots.append(Vector2(c.position.x - 12, c.end.y - 10))
	for s in spots:
		var cn := Node2D.new()
		cn.set_script(load("res://cone.gd"))
		cn.position = s
		cn.z_index = 11
		add_child(cn)
		cn.setup(self, dog, human, "cone")
	# Loose junk scattered down the whole walk, because punting things is one
	# of the reliable joys here and there was only ever cones. Mixed kinds so
	# the heft varies: cans rattle away, sacks barely budge. Local rng, so the
	# deterministic autowalk seed is untouched.
	var jr := RandomNumberGenerator.new()
	jr.seed = 0x7A17B0B
	# the level's background litter, for stretches with nothing else nearby
	var kinds := ["can", "bottle", "sack", "can"]
	match lvl:
		"scrap", "site": kinds = ["crate", "sack", "can", "bottle", "crate"]
		"beach": kinds = ["bottle", "ball", "can"]
		"park", "trail": kinds = ["bottle", "ball", "can"]
		"market", "spook": kinds = ["crate", "bottle", "can"]
		"station": kinds = ["can", "bottle", "bottle"]
		"oldtown": kinds = ["sack", "bottle", "can"]
	# Litter accumulates around whatever produced it, so junk is placed by
	# AREA rather than sprinkled evenly: crates pile up behind market stalls,
	# cans and bottles collect around cafe tables and buskers, sacks slump by
	# the bins, crates and cones litter the works. Feels observed rather than
	# randomised, and it makes each stretch of a walk look like somewhere.
	var zones: Array[Dictionary] = []
	for b in bins:
		zones.append({"at": b, "pal": ["sack", "sack", "bottle"]})
	for st in stalls:
		zones.append({"at": st, "pal": ["crate", "crate", "bottle"]})
	for tb in tables:
		zones.append({"at": tb, "pal": ["can", "bottle", "can"]})
	for pf in performers:
		zones.append({"at": pf, "pal": ["can", "can", "bottle"]})
	for v in vans:
		zones.append({"at": v, "pal": ["crate", "sack", "can"]})
	for bn in benches:
		zones.append({"at": bn, "pal": ["can", "bottle", "ball"]})
	for z in zones:
		var pal: Array = z.pal
		for i in range(jr.randi_range(1, 3)):
			var at: Vector2 = z.at
			var off := Vector2(jr.randf_range(-46.0, 46.0), jr.randf_range(-40.0, 46.0))
			var px := clampf(at.x + off.x, sw_l + 16.0, sw_r - 16.0)
			_spawn_junk(Vector2(px, at.y + off.y), pal[jr.randi() % pal.size()])
	# then a thin background scatter, so the quiet stretches are not bare
	var jy := START_Y - 120.0
	while jy > GATE_Y + 160.0:
		jy -= jr.randf_range(260.0, 520.0)
		var jx := jr.randf_range(sw_l + 30.0, sw_r - 30.0)
		_spawn_junk(Vector2(jx, jy), kinds[jr.randi() % kinds.size()])


func _spawn_junk(at: Vector2, kind: String) -> void:
	var jn := Node2D.new()
	jn.set_script(load("res://cone.gd"))
	jn.position = at
	jn.z_index = 11
	add_child(jn)
	jn.setup(self, dog, human, kind)


func on_junk_kicked(pos: Vector2, kind: String) -> void:
	# a light, kind-appropriate clatter; heavier things thud
	match kind:
		"can": Sfx.play("tangle", 1.9, -13.0)
		"bottle": Sfx.play("tangle", 1.6, -13.0)
		"ball": Sfx.play("snack", 0.7, -14.0)
		"sack", "crate": Sfx.play("crack", 0.6, -15.0)
		_: Sfx.play("tangle", 1.3, -14.0)
	# A-stands are entities too: light, toppleable, never re-stood
	for a in astands:
		var sa := Node2D.new()
		sa.set_script(load("res://astand.gd"))
		sa.position = a
		sa.z_index = 11
		add_child(sa)
		sa.setup(self, dog, human)


func _build_hud() -> void:
	# the colour grade sits over the world but UNDER the HUD, so the
	# interface stays crisp and unvignetted while the world gets graded
	var grade_layer := CanvasLayer.new()
	grade_layer.layer = 1
	add_child(grade_layer)
	grade_rect = ColorRect.new()
	# the whole viewport, not the reference frame: a fixed 1280x720 rect left
	# the strip that aspect "expand" reveals on a wide window completely
	# ungraded - no vignette, no grain, and visibly brighter than the picture
	# beside it
	grade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	grade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var gmat := ShaderMaterial.new()
	gmat.shader = load("res://grade.gdshader")
	grade_rect.material = gmat
	grade_layer.add_child(grade_rect)
	hud = CanvasLayer.new()
	hud.layer = 2
	add_child(hud)
	# weather sits behind the HUD text but over the world
	weather_fx = Control.new()
	weather_fx.set_script(load("res://weather_overlay.gd"))
	weather_fx.mode = Game.weather
	hud.add_child(weather_fx)
	# one quiet card for the vitals, one quiet card for the quests -
	# the world is busy on purpose, the overlay is not
	panel = Control.new()
	panel.set_script(load("res://hud_panel.gd"))
	panel.position = Vector2(16, 12)
	hud.add_child(panel)
	panel.setup(self)
	# the goal list draws itself: real ticks and meters instead of ASCII, and
	# a height that follows its contents
	goals_card = Control.new()
	goals_card.set_script(load("res://goals_card.gd"))
	goals_card.position = Vector2(GOALS_X, 8)
	hud.add_child(goals_card)
	goals_card.setup(self)
	# the end-of-walk card lays itself out: a twelve-goal walk used to run
	# straight off the bottom of the screen
	results_card = Control.new()
	results_card.set_script(load("res://results_panel.gd"))
	results_card.visible = false
	hud.add_child(results_card)
	results_card.setup(self)
	hint_l = _hud_label(Vector2(24, 686), 15)
	_pin_box(hint_l, 0.0, 0.0, 0.0, 1.0)
	hint_l.modulate.a = 0.75
	title_l = _hud_label(Vector2(0, 240), 44)
	_pin_wide(title_l, 52.0, 0.5)
	title_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_l.text = "PATH OF LEASH RESISTANCE"
	sub_l = _hud_label(Vector2(0, 300), 18)
	_pin_wide(sub_l, 30.0, 0.5)
	sub_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_l.text = "You are the dog. Go and touch grass."
	select_l = _hud_label(Vector2(0, 348), 22)
	_pin_wide(select_l, 32.0, 0.5)
	select_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	select_l.text = "<   %s   >" % Game.LEVEL_NAMES[lvl]
	record_l = _hud_label(Vector2(0, 300), 18)
	_pin_wide(record_l, 26.0, 0.5)
	record_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	record_l.modulate.a = 0.85
	# stacked ABOVE the controls line, which occupies y=686 from step 2 on
	menu_hint_l = _hud_label(Vector2(24, 662), 14)
	_pin_box(menu_hint_l, 0.0, 0.0, 0.0, 1.0)
	menu_hint_l.modulate.a = 0.55
	menu_hint_l.visible = false
	var version_l := _hud_label(Vector2(1150, 686), 13)
	_pin_box(version_l, 0.0, 0.0, 1.0, 1.0)
	version_l.text = "v1.54"
	version_l.modulate.a = 0.5
	owner_l = _hud_label(Vector2(0, 296), 26)
	_pin_wide(owner_l, 34.0, 0.5)
	owner_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	night_l = _hud_label(Vector2(0, 340), 26)
	_pin_wide(night_l, 34.0, 0.5)
	night_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	weather_l = _hud_label(Vector2(0, 384), 26)
	_pin_wide(weather_l, 34.0, 0.5)
	weather_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_l = _hud_label(Vector2(0, 470), 22)
	_pin_wide(prompt_l, 32.0, 0.5)
	prompt_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shop_preview_bg = ColorRect.new()
	shop_preview_bg.position = Vector2(60.0, 190.0)
	_pin_box(shop_preview_bg, 440.0, 390.0, 0.5, 0.5)
	shop_preview_bg.color = Color(0.05, 0.06, 0.07, 0.72)
	shop_preview_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shop_preview_bg.visible = false
	hud.add_child(shop_preview_bg)
	var preview := CharacterBody2D.new()
	preview.set_script(load("res://dog.gd"))
	preview.preview_mode = true
	preview.position = Vector2(280.0, 365.0)
	preview.scale = Vector2(3.0, 3.0)
	preview.visible = false
	hud.add_child(preview)
	preview.z_index = 1
	shop_preview = preview
	shop_title_l = _hud_label(Vector2(0, 70), 30)
	_pin_wide(shop_title_l, 40.0)
	shop_title_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shop_title_l.visible = false
	shop_preview_l = _hud_label(Vector2(60.0, 145.0), 18)
	_pin_box(shop_preview_l, 440.0, 30.0, 0.5, 0.5)
	shop_preview_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shop_preview_l.text = "HIGHLIGHTED LOOK"
	shop_preview_l.visible = false
	shop_l = _hud_label(Vector2(430.0, 150.0), 20)
	_pin_box(shop_l, 800.0, 460.0, 0.5, 0.5)
	shop_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shop_l.visible = false
	for k in Game.COLLARS:
		shop_items.append({"kind": "collar", "key": k})
	for k in Game.BANDANAS:
		if k != "none":
			shop_items.append({"kind": "bandana", "key": k})
	shop_items.append({"kind": "bandana", "key": "none"})
	# coats last: the biggest change to how Millie looks, and the first
	# working piece of the dog creator
	for k in Game.COATS:
		shop_items.append({"kind": "coat", "key": k})
	Input.joy_connection_changed.connect(func(_d: int, _c: bool) -> void: _refresh_menu_text())
	prompt_tw = create_tween().set_loops()
	prompt_tw.tween_property(prompt_l, "modulate:a", 0.3, 0.7)
	prompt_tw.tween_property(prompt_l, "modulate:a", 1.0, 0.7)
	var touch := Control.new()
	touch.set_script(load("res://touch_controls.gd"))
	hud.add_child(touch)
	# the combo meter: trick string + score/multiplier over a draining
	# window bar, bottom-centre, only visible while a chain is live
	combo = Node.new()
	combo.set_script(load("res://combo.gd"))
	add_child(combo)
	combo.setup(self)
	combo_bar_bg = ColorRect.new()
	combo_bar_bg.position = Vector2(440, 662)
	_pin_box(combo_bar_bg, 400.0, 8.0, 0.5, 1.0)
	combo_bar_bg.color = Color(0.05, 0.06, 0.07, 0.55)
	combo_bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	combo_bar_bg.visible = false
	hud.add_child(combo_bar_bg)
	combo_bar = ColorRect.new()
	combo_bar.position = Vector2(440, 662)
	_pin_box(combo_bar, 400.0, 8.0, 0.5, 1.0)
	combo_bar.color = Color(1.0, 0.78, 0.32)
	combo_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	combo_bar.visible = false
	hud.add_child(combo_bar)
	combo_l = _hud_label(Vector2(0, 624), 26)
	_pin_wide(combo_l, 34.0, 1.0)
	combo_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	combo_l.visible = false
	# the combo challenge (Phase B): a bounded trick dare from a bystander
	challenge = Node.new()
	challenge.set_script(load("res://challenge.gd"))
	add_child(challenge)
	challenge.setup(self)
	mood = Node.new()
	mood.set_script(load("res://mood.gd"))
	add_child(mood)
	mood.setup(self)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--mood="):
			var want := a.substr(7).to_upper()
			var names := {"SCARED": Mood.M.SCARED, "BARKY": Mood.M.BARKY,
				"ZOOMIES": Mood.M.ZOOMIES, "TIRED": Mood.M.TIRED}
			mood_forced = int(names.get(want, -1))
	teeter = Node.new()
	teeter.set_script(load("res://teeter.gd"))
	add_child(teeter)
	grind = Node.new()
	grind.set_script(load("res://grind.gd"))
	add_child(grind)
	challenge_l = _hud_label(Vector2(0, 70), 24)
	_pin_wide(challenge_l, 30.0)
	challenge_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	challenge_l.visible = false
	dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.visible = false
	hud.add_child(dim)
	msg_label = _hud_label(Vector2(0, 200), 22)
	_pin_wide(msg_label, 400.0, 0.5)
	msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg_label.visible = false
	pause_l = _hud_label(Vector2(0, 300), 26)
	_pin_wide(pause_l, 120.0, 0.5)
	pause_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_l.visible = false
	tut_label = _hud_label(Vector2(0, 96), 30)
	_pin_wide(tut_label, 40.0)
	tut_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tut_label.visible = false
	tut_hint = _hud_label(Vector2(0, 136), 19)
	_pin_wide(tut_hint, 60.0)
	tut_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tut_hint.visible = false
	progress_l = _hud_label(Vector2(0, 70), 19)
	_pin_wide(progress_l, 560.0)
	progress_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_l.visible = false
	# The single announcement channel. Added late so it draws over the other
	# HUD cards, and anchored to the live viewport like everything else.
	feed = Control.new()
	feed.set_script(load("res://event_feed.gd"))
	hud.add_child(feed)
	feed.setup(self)
	settings_panel = Control.new()
	settings_panel.set_script(load("res://settings_panel.gd"))
	settings_panel.visible = false
	hud.add_child(settings_panel)
	settings_panel.setup(self)
	_update_hud()


func _kb_or_pad(kb: String, pad: String) -> String:
	return pad if Input.get_connected_joypads().size() > 0 else kb


func _weather_tint() -> Color:
	var c := Color(0.5, 0.55, 0.78) if Game.night else Color.WHITE
	if Game.weather == "rain":
		c = c * Color(0.72, 0.76, 0.82)  # grey, overcast
	elif Game.weather == "wind":
		c = c * Color(0.92, 0.9, 0.82)  # dusty, warm-grey
	elif Game.weather == "snow":
		c = c * Color(0.9, 0.94, 1.02)  # cold, bright, blue-white
	return c


func _owner_label_text(owner_id: String) -> String:
	return "WALKING:  %s" % owner_id.to_upper()


func _apply_menu_step() -> void:
	# Tony Hawk rules: each screen shows ONE choice and ONE instruction.
	# Gameplay HUD (panel, quests) stays hidden until the walk begins.
	var in_menu := not started
	panel.visible = started
	goals_card.visible = started and not tutorial_mode
	# The game's name and the walk's name are drawn INTO the level now (chalk
	# on the pavement, a stick in the sand), so the labels that used to float
	# over the top of them are gone. What is left on the HUD is the things a
	# label is genuinely better at: the prompt and the run's details.
	title_l.visible = false
	sub_l.visible = false
	select_l.visible = false
	record_l.visible = in_menu and menu_step == 1
	owner_l.visible = in_menu and menu_step == 2
	night_l.visible = in_menu and menu_step == 2
	weather_l.visible = in_menu and menu_step == 2
	prompt_l.visible = in_menu
	# discreet, bottom-left, the same treatment as the version tag - the
	# middle of the title screen is already busy with the level blurb
	menu_hint_l.visible = in_menu
	menu_hint_l.text = "%s  settings" % _kb_or_pad("ESC", "Back")
	if not in_menu:
		return
	match menu_step:
		0:
			title_l.add_theme_font_size_override("font_size", 60)
			title_l.position.y = 210
			title_l.text = "PATH OF LEASH RESISTANCE"
			sub_l.add_theme_font_size_override("font_size", 22)
			sub_l.position.y = 288
			sub_l.text = "you are the dog. go and touch grass."
		1:
			title_l.add_theme_font_size_override("font_size", 30)
			title_l.position.y = 150
			title_l.text = "CHOOSE YOUR WALK   (%d stars)" % Game.total_stars()
			var sel: String = Game.level_id  # carousel id (may be "daily")
			var locked := not Game.is_unlocked(sel)
			select_l.add_theme_font_size_override("font_size", 52)
			select_l.text = ("[ %s ]" % Game.LEVEL_NAMES[sel]) if locked else ("<   %s   >" % Game.LEVEL_NAMES[sel])
			select_l.position.y = 220
			record_l.position.y = 300
			var rl: String = Game.best_line(sel)
			if sel != "daily" and Game.is_unlocked(sel):
				rl += "    goals %d/%d" % [Game.goals_count(sel), int((LEVEL_GOAL_IDS.get(sel, []) as Array).size())]
			record_l.text = rl
		2:
			title_l.add_theme_font_size_override("font_size", 40)
			title_l.position.y = 150
			title_l.text = Game.LEVEL_NAMES[Game.level_id].to_upper()
			owner_l.text = _owner_label_text(Game.owner_id)
	_refresh_menu_text()


func _open_shop() -> void:
	in_shop = true
	for l: Label in [title_l, sub_l, prompt_l, select_l, owner_l, night_l, weather_l, record_l,
			menu_hint_l]:
		l.visible = false
	shop_title_l.visible = true
	shop_l.visible = true
	shop_preview_bg.visible = true
	shop_preview_l.visible = true
	shop_preview.visible = true
	# the preview dog is a Node2D, so it cannot anchor itself the way the panel
	# behind it does - park it on the panel's centre instead, read at open time
	# so it follows the cluster onto whatever shape the screen turns out to be
	shop_preview.position = shop_preview_bg.position + Vector2(220.0, 175.0)
	_refresh_shop()


func _shop_data(kind: String, key: String) -> Dictionary:
	match kind:
		"collar": return Game.COLLARS[key]
		"coat": return Game.COATS[key]
		_: return Game.BANDANAS[key]


func _equip(kind: String, key: String) -> void:
	Game.equip(kind, key)


func _shop_select() -> void:
	var it: Dictionary = shop_items[shop_idx]
	var kind: String = it.kind
	var key: String = it.key
	if Game.is_owned(kind, key) or Game.buy(kind, key):
		_equip(kind, key)
		Game.save_records()
	# (if the buy failed, not enough bones - the price stays shown)
	_refresh_shop()


func _refresh_shop() -> void:
	shop_title_l.text = "MILLIE'S WARDROBE      %d bones" % Game.total_bones
	var lines := ""
	for i in range(shop_items.size()):
		var it: Dictionary = shop_items[i]
		var key: String = it.key
		var data: Dictionary = _shop_data(String(it.kind), key)
		var equipped: bool = (
			(it.kind == "collar" and Game.collar == key)
			or (it.kind == "bandana" and Game.bandana == key)
			or (it.kind == "coat" and Game.coat == key)
		)
		var tag := ""
		if equipped:
			tag = "  [EQUIPPED]"
		elif Game.is_owned(String(it.kind), key):
			tag = "  (owned - press to wear)"
		else:
			tag = "  %d bones" % int(data.cost)
		var cursor := ">  " if i == shop_idx else "    "
		lines += "%s%s%s\n" % [cursor, data.name, tag]
	lines += "\nleft / right browse    %s buy or wear    %s back" % [_kb_or_pad("SPACE", "A"), _kb_or_pad("E", "B")]
	shop_l.text = lines
	var highlighted: Dictionary = shop_items[shop_idx]
	var preview_collar: String = Game.collar
	var preview_bandana: String = Game.bandana
	var preview_coat: String = Game.coat
	match String(highlighted.kind):
		"collar": preview_collar = highlighted.key
		"coat": preview_coat = highlighted.key
		_: preview_bandana = highlighted.key
	shop_preview.set_cosmetic_preview(preview_collar, preview_bandana, preview_coat)


func _refresh_menu_text() -> void:
	# controller labels only when a controller is attached
	var pad := Input.get_connected_joypads().size() > 0
	hint_l.text = ("stick: move   A: dig in / squat   X: pee   B: bark   RB: turbo   Back: pause" if pad
		else "WASD: move   SPACE: dig in / squat   Q: pee   E: bark   SHIFT: turbo   ESC: pause")
	var fixed := "  (fixed today)" if Game.daily else "        (%s)" % _kb_or_pad("E", "B")
	night_l.text = "TIME:  %s%s" % [("NIGHT" if Game.night else "DAY"), fixed]
	weather_l.text = "WEATHER:  %s%s" % [Game.WEATHER_NAMES[Game.weather], "" if Game.daily else "        (%s)" % _kb_or_pad("Q", "X")]
	var go := _kb_or_pad("SPACE", "A")
	match menu_step:
		0:
			prompt_l.text = "press  %s  to begin" % go
			hint_l.visible = false
		1:
			if not Game.is_unlocked(Game.level_id):
				prompt_l.text = "locked - earn %d stars" % int(Game.STAR_GATE.get(Game.level_id, 0))
			else:
				prompt_l.text = "%s / %s  browse     %s  choose     %s  wardrobe     %s  progress" % [_kb_or_pad("A", "<"), _kb_or_pad("D", ">"), go, _kb_or_pad("E", "B"), _kb_or_pad("Q", "X")]
			hint_l.visible = false
		2:
			prompt_l.text = "press  %s  to go walkies" % go
			hint_l.visible = true


# --- settings ----------------------------------------------------------
#
# A download needs volume and fullscreen; muting the music with M was the
# whole of it before. Reachable with the pause key from either the title
# screen or a paused walk, and saved to the same records file as everything
# else. settings_panel.gd draws it; the rows below are the only source of
# truth for what is in there and in what order.

const SETTING_NAMES := {
	"master": "MASTER VOLUME", "sfx": "SOUND EFFECTS",
	"music": "MUSIC", "fullscreen": "FULLSCREEN", "goals": "GOAL LIST",
}


func settings_keys() -> Array:
	# the browser owns the window, so offering a fullscreen toggle there
	# would be a button that lies
	if OS.has_feature("web"):
		return ["master", "sfx", "music", "goals"]
	return ["master", "sfx", "music", "fullscreen", "goals"]


func settings_rows() -> Array:
	# the panel draws whatever this returns, so a new setting is one entry
	var out := []
	for k in settings_keys():
		var v: float = 0.0
		var kind := "slider"
		match k:
			"master": v = Game.vol_master
			"sfx": v = Game.vol_sfx
			"music": v = Game.vol_music
			"fullscreen":
				v = 1.0 if Game.fullscreen else 0.0
				kind = "toggle"
			"goals":
				v = 1.0 if Game.goals_expanded else 0.0
				kind = "toggle"
		out.append({"name": SETTING_NAMES[k], "kind": kind, "v": v})
	return out


func pad_hints() -> bool:
	return Input.get_connected_joypads().size() > 0


func _check_settings_roundtrip() -> Array:
	# The settings are only worth having if they survive a restart, and a
	# typo in a ConfigFile key fails silently - the value simply reverts to
	# its default the next time you launch. So write odd values, read them
	# back, and put the player's own settings back afterwards.
	var p: Array = []
	var keep := [Game.vol_master, Game.vol_sfx, Game.vol_music, Game.fullscreen]
	Game.vol_master = 0.3
	Game.vol_sfx = 0.1
	Game.vol_music = 0.7
	Game.fullscreen = true
	Game.save_records()
	Game.vol_master = 0.0
	Game.vol_sfx = 0.0
	Game.vol_music = 0.0
	Game.fullscreen = false
	Game.load_records()
	if not (is_equal_approx(Game.vol_master, 0.3) and is_equal_approx(Game.vol_sfx, 0.1)
			and is_equal_approx(Game.vol_music, 0.7) and Game.fullscreen):
		p.append("settings did not survive a save/load round trip (%.2f %.2f %.2f %s)"
			% [Game.vol_master, Game.vol_sfx, Game.vol_music, Game.fullscreen])
	Game.vol_master = keep[0]
	Game.vol_sfx = keep[1]
	Game.vol_music = keep[2]
	Game.fullscreen = keep[3]
	Game.save_records()
	# and the slider steps must stay inside 0..1 however hard you lean on them
	settings_idx = 0
	for i in range(20):
		_settings_adjust(-1)
	if Game.vol_master < 0.0:
		p.append("master volume ran below zero (%.2f)" % Game.vol_master)
	for i in range(30):
		_settings_adjust(1)
	if Game.vol_master > 1.0:
		p.append("master volume ran above one (%.2f)" % Game.vol_master)
	Game.vol_master = keep[0]
	Game.apply_settings()
	Game.save_records()
	return p


func _open_settings_from_menu() -> void:
	for l: Label in [title_l, sub_l, prompt_l, select_l, owner_l, night_l, weather_l, record_l,
			hint_l, menu_hint_l]:
		l.visible = false
	_open_settings()


func _open_settings() -> void:
	in_settings = true
	settings_idx = 0
	settings_panel.visible = true
	dim.visible = true
	Sfx.play("ui")


func _close_settings() -> void:
	in_settings = false
	settings_panel.visible = false
	Game.save_records()
	Sfx.play("ui")
	if paused:
		# back to the pause card we came from
		pause_l.visible = true
		dim.visible = true
	else:
		dim.visible = false
		_apply_menu_step()
		_refresh_menu_text()


func _settings_adjust(dir: int) -> void:
	var keys := settings_keys()
	var key: String = keys[settings_idx]
	match key:
		"master":
			Game.vol_master = clampf(Game.vol_master + 0.1 * dir, 0.0, 1.0)
			Game.apply_settings()
			Sfx.play("ui")
		"sfx":
			Game.vol_sfx = clampf(Game.vol_sfx + 0.1 * dir, 0.0, 1.0)
			Sfx.play("ui")  # so you hear what you just set
		"music":
			Game.vol_music = clampf(Game.vol_music + 0.1 * dir, 0.0, 1.0)
			Sfx.apply_music_volume()
		"fullscreen":
			Game.fullscreen = not Game.fullscreen
			Game.apply_settings()
			Sfx.play("ui")
		"goals":
			Game.goals_expanded = not Game.goals_expanded
			Sfx.play("ui")


func _tick_settings() -> void:
	var n: int = settings_keys().size()
	if Input.is_action_just_pressed("move_down"):
		settings_idx = wrapi(settings_idx + 1, 0, n)
		Sfx.play("ui")
	elif Input.is_action_just_pressed("move_up"):
		settings_idx = wrapi(settings_idx - 1, 0, n)
		Sfx.play("ui")
	elif Input.is_action_just_pressed("move_right"):
		_settings_adjust(1)
	elif Input.is_action_just_pressed("move_left"):
		_settings_adjust(-1)
	elif (Input.is_action_just_pressed("pause") or Input.is_action_just_pressed("bark")
			or Input.is_action_just_pressed("plant")):
		_close_settings()


func _progress_text() -> String:
	var t := "YOUR WALKS\n\n"
	for lv in Game.LEVELS:
		var nm: String = Game.LEVEL_NAMES[lv]
		if not Game.is_unlocked(lv):
			t += "%s   -   locked (%d stars)\n" % [nm, int(Game.STAR_GATE.get(lv, 0))]
			continue
		var total: int = (LEVEL_GOAL_IDS.get(lv, []) as Array).size()
		var rec := "no record yet"
		if Game.records.has(lv) and int(Game.records[lv].get("bones", 0)) > 0:
			rec = "%d bones  %ds" % [int(Game.records[lv].bones), int(Game.records[lv].time)]
		t += "%s   %s   goals %d/%d   %s\n" % [nm, Game.star_str(Game.stars(lv)), Game.goals_count(lv), total, rec]
	t += "\nTOTAL:  %d stars    %d bones banked\n\n%s  back" % [
		Game.total_stars(), Game.total_bones, _kb_or_pad("E", "B")]
	return t


	# The one-line answer to "what is going on" now lives in the feed
	# banner, centre screen near the dog, instead of as small text tucked
	# under the vitals card in the corner where it was never read.
	if feed != null:
		feed.set_banner(hud_status)

func _hud_label(pos: Vector2, size_px: int) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_font_size_override("font_size", size_px)
	hud.add_child(l)
	return l


# The HUD was composed against the 1280x720 reference frame, and stretch
# aspect "expand" makes the real viewport that frame grown along one axis:
# wider than 1280 on a landscape phone, taller than 720 in portrait. A label
# holding size.x = 1280 therefore centres its text on x=640 instead of on the
# middle of the screen, and a line placed at y=686 floats up the picture
# instead of sitting on the bottom edge.
#
# These pin an element to the live viewport with anchors, which re-solve on
# rotation with nothing listening for a resize. Anchors and then offsets are
# both written outright, in that order: assigning an anchor rewrites the
# offsets to preserve the current rect, so setting offsets afterwards is what
# makes the result independent of wherever the node was first placed.

func _pin_wide(c: Control, h: float, v_rule: float = 0.0) -> void:
	# full screen width, so CENTER-aligned text centres on the middle of the
	# screen instead of on x=640. v_rule picks which horizontal rule the
	# authored y is measured from: 0 the top edge, 0.5 the middle, 1 the
	# bottom. Everything sharing a rule shifts together, so a stack of lines
	# keeps the spacing it was composed with.
	var y := c.position.y - REF_H * v_rule
	c.anchor_left = 0.0
	c.anchor_right = 1.0
	c.anchor_top = v_rule
	c.anchor_bottom = v_rule
	c.offset_left = 0.0
	c.offset_right = 0.0
	c.offset_top = y
	c.offset_bottom = y + h


func _pin_box(c: Control, w: float, h: float, h_rule: float, v_rule: float) -> void:
	# a fixed-size element measured in from a chosen corner or rule: (0, 1) the
	# bottom-left, (1, 1) the bottom-right, (0.5, 0.5) the middle of the
	# screen. Elements composed as one cluster share a rule so they travel
	# together rather than each hugging a different edge and pulling apart.
	#
	# Pass w or h as 0 to leave that axis to the node: a Control never shrinks
	# below its own minimum size, so an auto-sized Label still fits its text.
	# Anchoring both sides to the same rule also keeps the rect offset-driven,
	# which is what lets the combo bar write size.x every frame as it drains.
	var p := c.position - Vector2(REF_W * h_rule, REF_H * v_rule)
	c.anchor_left = h_rule
	c.anchor_right = h_rule
	c.anchor_top = v_rule
	c.anchor_bottom = v_rule
	c.offset_left = p.x
	c.offset_right = p.x + w
	c.offset_top = p.y
	c.offset_bottom = p.y + h


func _update_hud() -> void:
	hud_status = ""
	if phase == "freedom":
		if romp_done:
			hud_status = "GO BACK DOWN TO HEAD HOME"
		else:
			hud_status = "FETCH! BRING IT BACK  %d/%d   %ds" % [romp_catches, romp_target, int(ceil(romp_timer))]
	elif phase == "home":
		if chase_active and chase_sweeper != null:
			if chase_kind == "both":
				hud_status = "RUN HOME TOGETHER!"
			elif chase_kind == "bolt":
				hud_status = "HE'S RUNNING! KEEP UP"
			else:
				hud_status = "RUN! DON'T LET IT CATCH YOU"
		elif tofu_quest_active and not tofu_home:
			hud_status = "GET THE CAT HOME! FOLLOW HER"
		else:
			hud_status = "HEAD HOME"
	elif poop_state == 1:
		hud_status = "NEED A WEE! FIND A SPOT, HOLD %s" % _kb_or_pad("SPACE", "A")
	elif poop_state >= 3:
		hud_status = "UH OH..."
	elif call_active:
		# NOT "they are on the phone": he is on the phone for the whole walk, so
		# saying so is never news. What is news is that he has stopped MOVING,
		# which is the part you can actually spend.
		hud_status = "LOOSE LEASH! %ds LEFT" % int(ceil(human.call_left()))
	elif lvl == "scrap":
		hud_status = "GO SLOW! SLOW IS QUIET"
	elif pee >= 0.999:
		hud_status = "FULL!"
	elif pee <= 0.02:
		hud_status = "THIRSTY! FIND A FOUNTAIN"
	goals_card.visible = started and not tutorial_mode


func goal_card_data() -> Dictionary:
	# The card draws whatever this returns. Open goals sort to the top so the
	# live ones are always on screen, and finished ones stay in the list
	# rather than vanishing - which is what made the row count wobble between
	# runs and the card jump about.
	var total := active_quests.size()
	var done_count: int = run_goals_hit.size() if Game.daily else Game.goals_count(lvl)
	done_count = mini(done_count, total)
	var open_rows: Array = []
	var done_rows: Array = []
	for q in active_quests:
		var persisted: bool = (not Game.daily) and Game.goal_done(lvl, q.id)
		var hit: bool = run_goals_hit.has(q.id)
		var target := int(q.target)
		if hit or persisted:
			done_rows.append({
				"text": _quest_text(q), "target": target, "got": target,
				# banked this run reads brighter than banked on a past walk
				"state": UiIcons.Check.DONE_NOW if hit else UiIcons.Check.DONE_BEFORE,
			})
		else:
			var got: int = mini(int(q.fn.call()), target)
			open_rows.append({
				"text": _quest_text(q), "target": target, "got": got,
				"state": UiIcons.Check.PARTIAL if got > 0 else UiIcons.Check.OPEN,
			})
	var rows: Array = open_rows + done_rows
	var shown: int = mini(rows.size(), GOALS_MAX_ROWS)
	var open: bool = Game.goals_expanded or goals_peek > 0.0
	return {
		"done": done_count, "total": total,
		"all_done": total > 0 and done_count >= total,
		"rows": rows.slice(0, shown) if open else [],
		"extra": (rows.size() - shown) if open else 0,
		"open": open, "peeking": goals_peek > 0.0 and not Game.goals_expanded,
		"key": _kb_or_pad("TAB", "up"),
	}


func _update_goal_card() -> void:
	if tutorial_mode:
		# a first walk has lessons, not goals: the boulevard's goal list would
		# be meaningless here and it collided with the lesson card
		goals_card.visible = false


func _update_combo_hud() -> void:
	var live: bool = combo.active() and combo.mult() >= 2
	combo_l.visible = live
	combo_bar.visible = live
	combo_bar_bg.visible = live
	if not live:
		return
	combo_l.text = "%s    %d   x%d" % [combo.label_text(), combo.points, combo.mult()]
	# the bar drains as the window closes, and warms to red near the end
	var f: float = combo.fraction()
	combo_bar.size.x = 400.0 * f
	combo_bar.color = Color(1.0, 0.78, 0.32) if f > 0.35 else Color(1.0, 0.45, 0.3)


func on_combo_banked(score: int, mult: int, bonus: int) -> void:
	Sfx.play("combo", 1.0 + 0.05 * mult)
	if bonus > 0:
		bones += bonus
	var col := Color(1.0, 0.85, 0.4) if mult < 5 else Color(1.0, 0.7, 0.85)
	var msg := "COMBO x%d   %d" % [mult, score]
	if bonus > 0:
		msg += "   +%d" % bonus
	float_text(dog.global_position + Vector2(0, -26), msg, col)
	if mult >= 5:
		_slowmo()


func _update_challenge_hud() -> void:
	var live: bool = challenge.active
	challenge_l.visible = live
	if not live:
		return
	challenge_l.text = "COMBO CHALLENGE   %d/%d tricks   %ds" % [
		challenge.count, challenge.target, int(ceil(challenge.timer))]
	challenge_l.modulate = Color(1, 0.95, 0.6) if challenge.fraction() > 0.3 else Color(1, 0.55, 0.4)


func on_trick() -> void:
	challenge.add_trick()
	# anything she gets up to during the call counts toward the payout
	if call_active:
		call_haul += 1


func start_challenge(giver: Node2D, target: int, seconds: float) -> void:
	if challenge_offered or challenge.active:
		return
	challenge_offered = true
	challenge_giver = giver
	challenge.begin(target, seconds)
	shake_t = maxf(shake_t, 0.2)
	feed.say("DO %d TRICKS!" % target, EventFeed.Tone.LOUD)


func on_challenge_done(win: bool, target: int, count: int) -> void:
	Sfx.play("star" if win else "ui")
	if is_instance_valid(challenge_giver):
		challenge_giver.resolve(win)
	if win:
		var reward := 20 + target * 3
		bones += reward
		feed.say("YOU DID IT!  +%d" % reward, EventFeed.Tone.GOOD)
		_slowmo()
	else:
		feed.say("SO CLOSE!  %d OF %d" % [count, target], EventFeed.Tone.BAD)


func _physics_process(delta: float) -> void:
	if frozen:
		return
	elapsed += delta
	riders_cache = get_tree().get_nodes_in_group("bikes")
	critters_cache = get_tree().get_nodes_in_group("squirrels")
	birds_cache = get_tree().get_nodes_in_group("pigeons")
	# weather nudges: rain makes the pavement slick, wind shoves everyone
	# gently downwind (the owner, dead weight, catches more of it)
	dog.slick = Game.weather == "rain"
	dog.ice = Game.weather == "snow"
	human.ice = Game.weather == "snow"
	if Game.weather == "wind":
		dog.velocity += Vector2(46.0, 0) * delta
		human.velocity += Vector2(70.0, 0) * delta
	# the moving walkway carries whoever is standing on it (L'Estacio)
	if conveyor_zone.size.y > 0.0:
		var carry := conveyor_dir * CONV_SPEED
		if conveyor_zone.has_point(dog.global_position):
			dog.velocity += carry * delta
		if conveyor_zone.has_point(human.global_position):
			human.velocity += carry * delta
	if auto_walk:
		_auto_drive(delta)
		_watch_stall(delta)
	dog.tick(delta)
	human.tick(delta)
	# the human owns the retractable leash: length changes on their whim
	# ("click!" event), never the dog's
	leash_len = move_toward(leash_len, leash_target, 150.0 * delta)
	leash.rest_len = leash_len
	# Dynamic NPC-rope obstacles must be current before the player leash
	# solve; a post-solve feed left the hero rope one frame stale.
	_refresh_pair_obstacles()
	_apply_leash(delta)
	if phase != "freedom":
		_lanes(delta)
		_vlane(delta)
	_squirrels(delta)
	_temptation(delta)
	_offpath(delta)
	_greetings()
	_pairs(delta)
	_hazards(delta)
	_pickups(delta)
	_bodily(delta)
	for i in range(bag_flights.size() - 1, -1, -1):
		var f: Dictionary = bag_flights[i]
		f.t += delta / 0.45
		if f.t >= 1.0:
			var to: Vector2 = f.to
			bag_flights.remove_at(i)
			on_business_bagged(to)
	if not cameras.is_empty() or not lasers.is_empty():
		_stealth(delta)
	if phase == "freedom":
		_romp(delta)
		_neighbour_fetch()
	elif phase == "home" and chase_active:
		_chase(delta)
	_check_goals()
	_progress(delta)
	combo.tick(delta)
	challenge.tick(delta)
	owner_news_cd = maxf(0.0, owner_news_cd - delta)
	# the banner shows live countdowns (slack left, fetch timer, chase), and
	# _update_hud is otherwise event-driven, so those would sit frozen
	if call_active or chase_active or phase == "freedom":
		_update_hud()
	_tick_mood(delta)
	_tick_teeter(delta)
	if tutorial_mode:
		_tick_tutorial(delta)
		_update_tut_card()
	if phase != "freedom":
		_tick_grind(delta)
		_tick_call(delta)
		_tick_vault(delta)
	_update_combo_hud()
	_update_challenge_hud()
	goals_peek = maxf(0.0, goals_peek - delta)
	vault_recent = maxf(0.0, vault_recent - delta)
	shake_t = maxf(0.0, shake_t - delta * 2.5)
	prize_glow += delta * 4.0
	_scent_cache_t = maxf(0.0, _scent_cache_t - delta)
	if freedomlayer != null:
		freedomlayer.tick(cam.position)


func _process(_delta: float) -> void:
	if not _shot_done and "--shot" in OS.get_cmdline_user_args():
		# --shot-at=N photographs frame N instead of 320, so a prop halfway up
		# the walk can be inspected by letting --autowalk drive there first
		for a in OS.get_cmdline_user_args():
			if a.begins_with("--shot-at="):
				_shot_at = int(a.substr(10))
		_shot_frames += 1
		if _shot_frames == 2:
			# --shot --shot-settings photographs the settings screen instead
			# of the world, so its layout can be eyeballed without playing
			if "--shot-results" in OS.get_cmdline_user_args():
				# the results card with this walk's real goals, in a spread of
				# states, so its layout can be checked without playing a walk
				# to the end (which takes two minutes)
				started = true
				frozen = true
				dim.visible = true
				var rr := _results_rows()
				for i in range(rr.size()):
					rr[i]["state"] = [UiIcons.Check.DONE_NOW, UiIcons.Check.DONE_BEFORE,
						UiIcons.Check.PARTIAL, UiIcons.Check.OPEN][i % 4]
				results = {
					"title": "GOOD DOG.", "stars": 2, "rating": "...well. A dog, anyway.",
					"rows": rr, "bones": 148, "phone": 2, "time": 137, "goal_bones": 30,
					"lines": [
						"+1 STAR   NEW BONES RECORD",
						"7/12 goals here    9 stars in all    1240 bones banked",
						"best combo x6    style 412",
						"3 spots over-marked. They will know.",
					],
					"prompt": "press  R  for another walk",
				}
				results_card.visible = true
				goals_card.visible = false
				panel.visible = false
				for l: Label in [title_l, sub_l, prompt_l, select_l, owner_l, night_l,
						weather_l, record_l, hint_l, menu_hint_l]:
					l.visible = false
				return
			if "--shot-settings" in OS.get_cmdline_user_args():
				_open_settings_from_menu()
				return
			# --shot-title leaves the menu up instead of skipping it, so the
			# walk-select screen and the name chalked on the pavement can be
			# reviewed. Everything else about --shot exists to get PAST this.
			if "--shot-title" in OS.get_cmdline_user_args():
				return
			started = true  # skip the title so the shot shows the world
			frozen = false
			_apply_menu_step()
			for l: Label in [title_l, sub_l, prompt_l, select_l, owner_l, night_l, weather_l, record_l]:
				l.visible = false
		if _shot_frames > _shot_at:
			_shot_done = true
			var img := get_viewport().get_texture().get_image()
			img.save_png("user://shot.png")
			print("SHOT saved to user://shot.png")
	if in_settings:
		_tick_settings()
		return
	if Input.is_action_just_pressed("goals") and started and not frozen:
		Game.goals_expanded = not Game.goals_expanded
		Game.save_records()
		Sfx.play("ui")
		goals_peek = 0.0
	if Input.is_action_just_pressed("mute_music"):
		Sfx.toggle_music()
	if Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()
		return
	# pause: only while actively walking (not on the title, a death, or the
	# results). Resume with the pause key or plant; bark quits to the menu.
	if started and not in_shop:
		if paused:
			if Input.is_action_just_pressed("pause") or Input.is_action_just_pressed("plant"):
				paused = false
				frozen = false
				pause_l.visible = false
				dim.visible = false
			elif Input.is_action_just_pressed("pee"):
				pause_l.visible = false
				_open_settings()
			elif Input.is_action_just_pressed("bark"):
				Game.menu_step = 1
				get_tree().reload_current_scene()
			return
		elif not frozen and Input.is_action_just_pressed("pause"):
			paused = true
			frozen = true
			pause_l.text = "PAUSED\n\n%s  resume     %s  restart     %s  menu\n\n%s  settings     %s  toggle music" % [
				_kb_or_pad("SPACE", "A"), _kb_or_pad("R", "Start"), _kb_or_pad("E", "B"),
				_kb_or_pad("Q", "X"), _kb_or_pad("M", "LB")]
			pause_l.visible = true
			dim.visible = true
			return
	if finished and Game.daily and not daily_copied and daily_share != "" and Input.is_action_just_pressed("share"):
		DisplayServer.clipboard_set(daily_share)
		daily_copied = true
		msg_label.text += "\n\n(copied to clipboard!)"
		return
	if not started and in_shop:
		if Input.is_action_just_pressed("move_left"):
			shop_idx = wrapi(shop_idx - 1, 0, shop_items.size())
			_refresh_shop()
		if Input.is_action_just_pressed("move_right"):
			shop_idx = wrapi(shop_idx + 1, 0, shop_items.size())
			_refresh_shop()
		if Input.is_action_just_pressed("plant"):
			_shop_select()
		if Input.is_action_just_pressed("bark"):
			in_shop = false
			shop_title_l.visible = false
			shop_l.visible = false
			shop_preview_bg.visible = false
			shop_preview_l.visible = false
			shop_preview.visible = false
			_apply_menu_step()
		return
	if not started:
		if Input.is_action_just_pressed("pause") and not in_progress_view:
			_open_settings_from_menu()
			return
		# the career overview: every walk's stars, goals and best run
		if in_progress_view:
			if Input.is_action_just_pressed("bark") or Input.is_action_just_pressed("pee") or Input.is_action_just_pressed("plant"):
				in_progress_view = false
				progress_l.visible = false
				dim.visible = false
				_apply_menu_step()
				_refresh_menu_text()
			return
		if menu_step == 1 and Input.is_action_just_pressed("pee"):
			in_progress_view = true
			for l: Label in [title_l, sub_l, prompt_l, select_l, owner_l, night_l, weather_l, record_l,
					hint_l, menu_hint_l]:
				l.visible = false
			progress_l.text = _progress_text()
			progress_l.visible = true
			dim.visible = true
			return
		# Tony Hawk rules: one screen, one instruction. Step 0 is just
		# the title; step 1 picks the walk; step 2 picks the details.
		if menu_step == 1 and Input.is_action_just_pressed("bark"):
			_open_shop()
			return
		if menu_step == 1 and (Input.is_action_just_pressed("move_left") or Input.is_action_just_pressed("move_right")):
			Game.cycle_level(1 if Input.is_action_just_pressed("move_right") else -1)
			Game.menu_step = 1
			get_tree().reload_current_scene()
			return
		if menu_step == 2 and (Input.is_action_just_pressed("move_up") or Input.is_action_just_pressed("move_down")):
			Game.toggle_owner()
			owner_l.text = _owner_label_text(Game.owner_id)
		# weather and time are fixed by the seed on the daily walk
		if menu_step == 2 and not Game.daily and Input.is_action_just_pressed("bark"):
			Game.night = not Game.night
			night_cm.color = _weather_tint()
			_refresh_menu_text()
		if menu_step == 2 and not Game.daily and Input.is_action_just_pressed("pee"):
			Game.cycle_weather(1)
			night_cm.color = _weather_tint()
			weather_fx.mode = Game.weather
			_refresh_menu_text()
		if Input.is_action_just_pressed("plant"):
			# cannot advance past a locked walk
			if menu_step == 1 and not Game.is_unlocked(Game.level_id):
				select_l.text = "%s  (locked)" % Game.LEVEL_NAMES[Game.level_id]
				return
			Sfx.play("ui")
			if menu_step < 2:
				menu_step += 1
				Game.menu_step = menu_step
				_apply_menu_step()
				return
			started = true
			frozen = false
			# snapshot progress so the results can report stars/unlocks
			run_pre_total_stars = Game.total_stars()
			run_pre_level_stars = Game.stars(lvl)
			Game.menu_step = 1
			prompt_tw.kill()
			panel.visible = true
			goals_card.visible = not tutorial_mode
			for l: Label in [title_l, sub_l, prompt_l, select_l, owner_l, night_l, weather_l, record_l]:
				var tw := create_tween()
				tw.tween_property(l, "modulate:a", 0.0, 0.5)
			# the hint earns its keep for a few seconds, then gets out
			# of the way
			var htw := create_tween()
			htw.tween_interval(6.0)
			htw.tween_property(hint_l, "modulate:a", 0.0, 1.2)
	var target_y := (dog.global_position.y + human.global_position.y) / 2.0 - 60.0
	if phase == "freedom":
		target_y = dog.global_position.y  # owner is parked; follow the dog
	cam.position = Vector2(640, target_y)
	if shake_t > 0.0:
		cam.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * 9.0 * shake_t
	else:
		cam.offset = Vector2.ZERO
	# the world is drawn in world space, so the camera scroll stays smooth
	# without re-running _draw - only the world's own animations (glints,
	# blinking lights) need refreshing, and 30fps is plenty for those. This
	# frees the big per-frame draw cost that hurt the web build most.
	_redraw_acc += _delta
	# the teeter is a reflex moment, so it gets every frame, not 30fps
	# the frontage only needs redrawing when new frontage comes into view
	if absf(cam.position.y - _edge_drawn_y) > 150.0:
		_edge_drawn_y = cam.position.y
		edge_layer.queue_redraw()
	if verge_layer != null and absf(cam.position.y - _verge_drawn_y) > 150.0:
		_verge_drawn_y = cam.position.y
		verge_layer.queue_redraw()
	if _redraw_acc >= 0.033 or shake_t > 0.0 or teeter.active or grind.active:
		_redraw_acc = 0.0
		queue_redraw()
	# keep the grade's surface texture pinned to world space, and drift the
	# film grain. Two uniform writes a frame - negligible next to a redraw.
	if grade_rect != null:
		var gm: ShaderMaterial = grade_rect.material
		# the screen's top-left in world space. Half of the ACTUAL viewport,
		# since a wide window sees past the reference frame's edges - using
		# half of 1280x720 would drag the ground texture along with the camera
		var view_px := get_viewport_rect().size
		gm.set_shader_parameter("view_px", view_px)
		gm.set_shader_parameter("cam_off", cam.position - view_px * 0.5)
		gm.set_shader_parameter("time_seed", fmod(elapsed * 7.0, 100.0))


func _tick_mood(delta: float) -> void:
	# A mood belongs to the walk. The menu has nothing to react to, and the
	# tutorial teaches one thing at a time - a re-graded screen mid-lesson
	# would read as a fault rather than a feeling.
	if not started or tutorial_mode:
		dog.mood_speed = 1.0
		dog.mood_accel = 1.0
		dog.mood_wobble = 0.0
		return
	_mood_ambient(delta)
	mood.tick(delta)
	# the handling first, the picture second - a mood should reach your hands
	# before it reaches your eyes
	dog.mood_speed = mood.speed_mult()
	dog.mood_accel = mood.accel_mult()
	dog.mood_wobble = mood.wobble()
	if grade_rect != null:
		var gm: ShaderMaterial = grade_rect.material
		var g: Dictionary = mood.grade()
		gm.set_shader_parameter("saturation", g["sat"])
		gm.set_shader_parameter("contrast", g["con"])
		gm.set_shader_parameter("vignette", g["vig"])
		gm.set_shader_parameter("vignette_tight", g["tight"])
		gm.set_shader_parameter("exposure", g["exp"])
		gm.set_shader_parameter("tint", g["tint"])
		gm.set_shader_parameter("lift", g["lift"])
		gm.set_shader_parameter("cool_shadows", g["cool"])
		gm.set_shader_parameter("warm_light", g["warm"])
	var line: String = mood.take_onset()
	if line != "":
		# an announcement about her, not about a place: it goes in the feed
		feed.say(line, EventFeed.Tone.LOUD)


func _mood_ambient(delta: float) -> void:
	# The two moods a walk GROWS into, as opposed to the ones it gets startled
	# into. Both are fed a little every frame the condition holds rather than
	# landed in one go, so they arrive at the pace the walk does.
	# --mood=scared|barky|zoomies|tired pins one on, so a look can be
	# photographed and tuned without having to provoke it in play. Barky in
	# particular needs a cat and a chase to arrive honestly.
	if mood_forced >= 0:
		mood.bump(mood_forced, delta * 3.0)
	var spd: float = dog.velocity.length()
	# Running yourself empty makes the legs go heavy - but as a one-off
	# reaction to the moment you run out, not a tax on being tired. Fed every
	# frame the tank was low it pinned TIRED on for the whole home leg, and
	# since TIRED is slow AND gives the human an easier tow, a walk could get
	# genuinely stuck in it. An edge trigger with hysteresis: it fires when you
	# hit empty, and cannot fire again until you have got your breath back.
	if dog.energy < 0.16 and not mood_worn:
		mood_worn = true
		mood.bump(Mood.M.TIRED, 0.70)
	elif dog.energy > 0.35:
		mood_worn = false
	# a rested dog let off the leash is a dog with the zoomies
	if phase == "freedom" and dog.energy > 0.80 and spd > 250.0:
		mood.bump(Mood.M.ZOOMIES, delta * 0.65)
	# Acting into a mood feeds it, and this is the whole of the player's
	# influence over their own moods: keep running and the zoomies keep going.
	# Only moods that reward DOING something get this. Feeding TIRED for being
	# slow was the same idea run backwards and it made a trap - standing still
	# is also what being stuck looks like, so it deepened the one mood you
	# most need to be able to come out of.
	if mood.active == Mood.M.ZOOMIES and spd > 240.0:
		mood.bump(Mood.M.ZOOMIES, delta * 0.30)
	# ...and the other half of the model: the things that genuinely ANSWER a
	# mood shorten it. Being tired is the mood a dog can actually do something
	# about, and all three answers are real ones rather than a button - stop
	# and get your breath back, get out of the sun, or find something to eat
	# (the eating is handled where the kebab is, since that is a moment).
	if mood.active == Mood.M.TIRED:
		if spd < 50.0:
			mood.soothe(Mood.M.TIRED, delta * 0.30)
		if _in_shade(dog.global_position):
			# shade is worth more when there is actually a sun to get out of
			mood.soothe(Mood.M.TIRED, delta * (0.34 if _sunny() else 0.12))
	# Something eating the pavement behind you is not a thing you get used to -
	# and it gets worse the closer it is. A flat rate made the far end of a
	# chase feel exactly like the near end, which wasted the one moment the
	# whole sequence is built around. Squared, so dread is a slow background
	# hum at a corridor's distance and climbs hard over the last stretch.
	# Suppressed under --shot-sweeper only, so the machine's paint can be
	# reviewed in daylight rather than through a frightened dog's eyes.
	if chase_active and not "--shot-sweeper" in OS.get_cmdline_user_args():
		var near := 0.0
		if chase_sweeper != null:
			near = clampf(1.0 - chase_sweeper.gap_to(dog.global_position) / 900.0, 0.0, 1.0)
		mood.bump(Mood.M.SCARED, delta * (0.16 + 0.90 * near * near))


func owner_news(line: String) -> void:
	# WHAT THE OWNER IS DOING, SAID WHERE THE PLAYER IS LOOKING.
	#
	# The owner announces himself with a speech bubble over his own head, which
	# is right - it is his moment and it belongs on his body. The trouble is
	# that the player is watching the DOG, and on a long leash he can be
	# most of a screen away, so the one thing that tells you the walk has gone
	# slack was arriving somewhere nobody was looking. Same news, repeated next
	# to her, in her voice.
	#
	# Rate-limited: he has seven of these states and they fire every few
	# seconds, so without a floor this would be a running commentary rather
	# than a signal.
	if not started or frozen or dog == null:
		return
	if owner_news_cd > 0.0:
		return
	owner_news_cd = 3.2
	feed.say(line, EventFeed.Tone.PLAIN)


func _sunny() -> bool:
	return Game.weather == "clear" and not Game.night


func _in_shade(p: Vector2) -> bool:
	# Shade is where the SHADOW is, not where the tree is. Everything in this
	# game throws its shadow along one light (LIGHT), so the cool patch under a
	# plane tree sits clear of the trunk on the far side - standing on the tree
	# does nothing, standing in its shadow is the thing. Costs nothing to agree
	# with the picture, and it is the kind of detail a dog owner would notice.
	for t: Vector2 in trees:
		var d := p - (t + LIGHT * 46.0)
		# the same squashed ellipse _draw_broadleaf lays its crown shadow on
		if (d.x * d.x) / 1450.0 + (d.y * d.y) / 365.0 <= 1.0:
			return true
	for u: Vector2 in parasols:
		var q := p - (u + LIGHT * 30.0)
		if (q.x * q.x) / 900.0 + (q.y * q.y) / 230.0 <= 1.0:
			return true
	# the terrace awnings are proper roofs: under one is simply under it
	for cn: Rect2 in canopies:
		if cn.has_point(p):
			return true
	return false


func _apply_leash(delta: float) -> void:
	# The rope itself (leash.gd) is the constraint. Here: run the rope
	# physics, then turn its stretch into tug-of-war forces. One tension,
	# applied to each end inversely to effective mass along the rope's end
	# tangent - so a wound-up human is pulled around the pole in an arc.
	# The human is ~4x the dog, so raw pulls yank the DOG around; the dog
	# wins by bracing (plant), winding poles (the coil grips and shields
	# both ends from raw tension while geometry still constrains), timing.
	human.strain = false
	dog.dragged = false
	if leash.detached:
		return  # off leash during the freedom romp
	leash.tick(delta)
	# the whirl manages its own release (aimed at the dog); no early exit,
	# or the launch direction would be random
	var whirling: bool = human.is_whirling()
	if whirling:
		# the choreographed unwind must never be arrested by rope grip
		leash.free_slip_t = 0.7
		# wrong-way guard: if the rope is winding TIGHTER, the direction
		# guess was wrong - flip once
		if not whirl_flipped and absf(leash.winding()) > whirl_start_wind + 0.35:
			human.flip_whirl()
			whirl_flipped = true
	if human.just_flung:
		# a fresh fling must never be arrested by a residual wrap
		human.just_flung = false
		flings_done += 1
		# the two moves now CHAIN: wind him up with a carve, then let go
		if vault_recent > 0.0:
			bones += 8
			combo.add("SLINGSHOT", 8)
			float_text(human.global_position + Vector2(0, -34), "SLINGSHOT! +8",
				Color(1.0, 0.86, 0.5))
			vault_recent = 0.0
		Sfx.play("fling")
		combo.add("FLING", 8)
		leash.free_slip_t = 1.2
	var used: float = leash.used_length()
	var excess := used - leash_len
	leash.taut = excess > 0.0
	if excess <= 0.0:
		whirl_arm = 0.0
		whirl_wind_acc = 0.0
		return
	var h_dir: Vector2 = leash.human_pull_dir()
	var d_dir: Vector2 = leash.dog_pull_dir()
	if h_dir == Vector2.ZERO or d_dir == Vector2.ZERO:
		return
	human.notify_strain()
	dog.dragged = not dog.planted
	# Only static wraps (poles/furniture) shield/anchor. Dynamic leash
	# tangles must not borrow pole-vault semantics.
	var shield := 1.0 / (1.0 + 0.3 * float(leash.static_contacts))
	var dog_m := DOG_MASS
	if dog.planted:
		dog_m *= 14.0
	elif dog.input_active:
		dog_m *= 2.0
	var human_m := HUMAN_MASS * (2.0 if human.is_fallen() else 1.0)
	var base_tension := minf(LEASH_K * excess, 1600.0)
	# pulley: with the rope wound and the dog working its end, the pole
	# redirects and amplifies the pull on the human continuously - not
	# only during the whirl. Wraps still shield the DOG from raw yanks.
	var wind_turns := absf(leash.winding())
	var pulley := 1.0
	if wind_turns > 0.3 and (dog.input_active or dog.planted):
		pulley = 1.0 + 0.4 * minf(wind_turns, 3.0)
	if whirling:
		# the dog's pulling feeds the whirl's spin-up
		human.whirl_pull = maxf(float(human.whirl_pull), base_tension)
	if not whirling:
		# the mood rides on the DOG's side of the tug of war: lunging at
		# something worth telling off tows the human further than an ordinary
		# pull would, and a flat dog barely troubles him at all. This is what
		# makes a mood something the human notices too.
		var lunge: float = mood.pull_mult() if mood != null else 1.0
		human.velocity += h_dir * (base_tension * pulley * lunge / human_m) * delta
	if not dog.planted:
		dog.velocity += d_dir * (base_tension * shield / dog_m) * delta
	# damp separating components so neither end bungees
	var sep_h := human.velocity.dot(-h_dir)
	if sep_h > 0.0 and not whirling:
		human.velocity += h_dir * sep_h * minf(5.0 * delta, 1.0)
	var sep_d := dog.velocity.dot(-d_dir)
	if sep_d > 0.0 and not dog.planted:
		dog.velocity += d_dir * sep_d * minf(3.0 * delta, 1.0)
	# hard cap: geometry always wins. Corrections follow the rope tangents
	# (unshielded), which is what whips a wound human along the arc.
	var cap := leash_len * (LEASH_STRETCH_CAP - 1.0)
	if excess > cap:
		var over := excess - cap
		var w_d := (1.0 / dog_m) / (1.0 / dog_m + 1.0 / human_m)
		var yank_speed := maxf(human.velocity.dot(-h_dir), 0.0)
		dog.move_and_collide(d_dir * over * w_d)
		if not whirling:
			human.move_and_collide(h_dir * over * (1.0 - w_d))
			var rel := human.velocity.dot(-h_dir)
			if rel > 0.0:
				human.velocity += h_dir * rel * 0.9
			var anchored: bool = dog.planted or leash.static_contacts > 0
			human.on_leash_yank(-h_dir, anchored, yank_speed)
	# cartoon tetherball: a human wound around a nearby pole who keeps
	# getting pulled starts to WHIRL - an accelerating orbit that unwinds
	# the rope and flings them when it runs out (Bugs Bunny physics).
	# The condition must hold for a quarter second (walking past a pole
	# briefly curves the rope and must not trigger), and the unwind
	# direction is averaged over that window instead of one noisy frame.
	var armed := false
	if not whirling and not human.is_fallen() and excess > 8.0:
		var end_wind: float = leash.human_end_winding()
		# 0.55 turns covers the 270-degree partial wind that used to jam
		# awkwardly without ever whirling
		if absf(leash.winding()) > 0.55 and absf(end_wind) > 2.4:
			var wp := _nearest_pole_to(human.global_position, 70.0)
			if wp.x < INF:
				armed = true
				whirl_arm += delta
				whirl_wind_acc += end_wind
				if whirl_arm >= 0.25:
					var spin_dir := -signf(whirl_wind_acc)
					if spin_dir == 0.0:
						spin_dir = 1.0
					whirl_start_wind = absf(leash.winding())
					whirl_flipped = false
					human.start_whirl(wp, spin_dir, whirl_start_wind)
					armed = false
	if not armed:
		whirl_arm = 0.0
		whirl_wind_acc = 0.0


func _lanes(delta: float) -> void:
	for i in range(lane_state.size()):
		var ls: Dictionary = lane_state[i]
		if absf(lane_ys[i] - cam.position.y) > 950.0:
			continue
		ls.t -= delta
		if ls.t <= 0.0:
			if ls.phase == 0:
				ls.phase = 1
				ls.dir = 1 if randf() < 0.5 else -1
				ls.t = 0.75
			else:
				ls.phase = 0
				ls.t = randf_range(1.7, 3.2)
				_spawn_bike(lane_ys[i] + randf_range(-34.0, 34.0), ls.dir)


func _spawn_bike(y: float, dir: int) -> void:
	var b := Node2D.new()
	b.set_script(load("res://bike.gd"))
	b.position = Vector2(-250.0 if dir > 0 else 1530.0, y)
	b.z_index = 12
	add_child(b)
	b.setup(self, dog, human, Vector2(dir * randf_range(480.0, 640.0), 0.0), "bike")


func _vlane(delta: float) -> void:
	# the parallel bike lane: fast commuters hold their line, kids on
	# scooters weave - and sometimes ride on the sidewalk itself
	vspawn_t -= delta
	if vspawn_t > 0.0:
		return
	vspawn_t = randf_range(3.2, 5.6) if lvl == "park" else randf_range(2.2, 4.2)
	if get_tree().get_nodes_in_group("bikes").size() >= 7:
		return
	var up := randf() < 0.62
	var y: float = cam.position.y + (560.0 if up else -560.0)
	if y > START_Y + 150.0 or y < GATE_Y - 400.0:
		return
	var kid := false
	var speed := 0.0
	var x := 0.0
	var band_lo := 0.0
	var band_hi := 0.0
	match lvl:
		"street":
			kid = randf() < 0.38
			speed = randf_range(70.0, 120.0) if kid else randf_range(300.0, 460.0)
			if kid and randf() < 0.45:
				x = randf_range(sw_l + 40.0, sw_r - 40.0)
				band_lo = sw_l + 30.0
				band_hi = sw_r - 30.0
			else:
				x = randf_range(BLANE_L + 16.0, BLANE_R - 16.0)
				band_lo = BLANE_L + 14.0
				band_hi = BLANE_R - 14.0
		"park":
			kid = randf() < 0.7
			speed = randf_range(70.0, 120.0) if kid else randf_range(220.0, 320.0)
			x = randf_range(sw_l + 40.0, sw_r - 40.0)
			band_lo = sw_l + 30.0
			band_hi = sw_r - 30.0
		"beach":
			kid = randf() < 0.4
			speed = randf_range(70.0, 120.0) if kid else randf_range(300.0, 440.0)
			if kid and randf() < 0.5:
				x = randf_range(590.0, 950.0)
				band_lo = 575.0
				band_hi = 960.0
			else:
				x = randf_range(488.0, 552.0)
				band_lo = 486.0
				band_hi = 554.0
		"market":
			# strollers and the occasional delivery scooter, kept to the
			# middle aisle between the stall rows
			kid = randf() < 0.75
			speed = randf_range(60.0, 105.0) if kid else randf_range(200.0, 300.0)
			x = randf_range(460.0, 820.0)
			band_lo = 450.0
			band_hi = 830.0
	var b := Node2D.new()
	b.set_script(load("res://bike.gd"))
	b.position = Vector2(x, y)
	b.z_index = 12
	b.setup(self, dog, human, Vector2(0.0, -speed if up else speed), "kid" if kid else "bike")
	if kid:
		b.lane_keep(band_lo, band_hi)
	if not b.configure_route(x, band_lo, band_hi, bypasser_blockers):
		b.free()
		return
	add_child(b)


func _squirrels(delta: float) -> void:
	# rare visitors arrive when the camera approaches their spot
	if cat_y < 0.0 and cam.position.y < cat_y + 700.0:
		var c := Node2D.new()
		c.set_script(load("res://squirrel.gd"))
		var cat_x := 336.0 if randf() < 0.5 else 944.0
		if lvl == "beach":
			cat_x = 1010.0 if randf() < 0.5 else 462.0
		c.position = Vector2(cat_x, cat_y)
		c.z_index = 9
		add_child(c)
		c.setup(self, dog, "cat")
		cat_y = 0.0
	while flock_ys.size() > 0 and cam.position.y < flock_ys[0] + 650.0:
		var fy: float = flock_ys.pop_front()
		var gulls := lvl == "beach"
		for i in range(5):
			var p := Node2D.new()
			p.set_script(load("res://pigeon.gd"))
			var fx := randf_range(480.0, 820.0)
			if gulls:
				fx = randf_range(120.0, 320.0) if randf() < 0.7 else randf_range(350.0, 470.0)
			p.position = Vector2(fx, fy + randf_range(-40.0, 40.0))
			p.z_index = 8
			add_child(p)
			p.setup(self, dog, human, gulls)
	while duck_ys.size() > 0 and cam.position.y < duck_ys[0] + 650.0:
		var dy: float = duck_ys.pop_front()
		var ddir := 1.0 if randf() < 0.5 else -1.0
		var start_x := 310.0 if ddir > 0.0 else 970.0
		for i in range(5):
			var d := Node2D.new()
			d.set_script(load("res://duckling.gd"))
			d.position = Vector2(start_x - ddir * i * 17.0, dy + sin(i * 1.7) * 4.0)
			d.z_index = 9
			add_child(d)
			d.setup(self, dog, ddir, i == 0)
	sq_spawn_t -= delta
	if sq_spawn_t > 0.0:
		return
	sq_spawn_t = randf_range(7.0, 13.0)
	if get_tree().get_nodes_in_group("squirrels").size() >= 2:
		return
	var y: float = cam.position.y - randf_range(420.0, 640.0)
	if y < GATE_Y + 100.0 or y > START_Y - 100.0:
		return
	var roll := randf()
	var x := 0.0
	if lvl == "beach":
		x = randf_range(1000.0, 1150.0) if roll < 0.6 else randf_range(320.0, 480.0)
	elif roll < 0.35:
		# open grass now that the dog can roam it
		x = randf_range(150.0, 290.0)
	elif roll < 0.65:
		x = randf_range(sw_r - 60.0, sw_r - 25.0) if lvl == "street" else randf_range(1000.0, 1140.0)
	else:
		# street: the far shoulder, live traffic between; park: far grass
		x = randf_range(BLANE_R + 8.0, SHOULDER_R - 8.0) if lvl == "street" else randf_range(150.0, 290.0)
	var s := Node2D.new()
	s.set_script(load("res://squirrel.gd"))
	s.position = Vector2(x, y)
	s.z_index = 9
	add_child(s)
	# the passeig has no squirrels; it has rats, and Millie is not picky
	s.setup(self, dog, "rat" if lvl == "beach" else "squirrel")


func _temptation(delta: float) -> void:
	# a nearby creature physically pulls at Millie; fight it or lean in.
	# The pull is instinct, tiered: cats are magnetic, squirrels and rats
	# nearly so, grounded birds a gentler tug.
	dog.tempted = false
	if dog.planted or dog.is_tumbling() or dog.peeing:
		return
	var best_s: Node2D = null
	var best_d := 1e9
	var best_rng := 0.0
	var best_str := 0.0
	for s in critters_cache:
		if s.state == 2:
			continue
		var rng: float = 320.0 if s.kind == "cat" else 240.0
		var d: float = dog.global_position.distance_to(s.global_position)
		if d < rng and d < best_d:
			best_d = d
			best_s = s
			best_rng = rng
			best_str = 500.0 if s.kind == "cat" else 420.0
	for p in birds_cache:
		if p.flying:
			continue
		var d2: float = dog.global_position.distance_to(p.global_position)
		if d2 < 160.0 and d2 < best_d:
			best_d = d2
			best_s = p
			best_rng = 160.0
			best_str = 200.0
	if best_s != null:
		dog.tempted = true
		var pull := (best_s.global_position - dog.global_position).normalized() * best_str * (1.0 - best_d / best_rng)
		dog.velocity += pull * delta


func nearest_cover(from: Vector2, threat: Vector2) -> Vector2:
	# where a cat hides: beside anything with a silhouette, away from
	# whatever spooked her
	var best := Vector2(INF, INF)
	var best_score := -1e9
	var away := (from - threat).normalized()
	for i in range(body_pole_count):
		var p := poles[i]
		var d := from.distance_to(p)
		if d < 120.0 or d > 520.0:
			continue
		var dirdot := (p - from).normalized().dot(away)
		if dirdot < 0.1:
			continue
		var score := dirdot * 200.0 - absf(d - 280.0)
		if score > best_score:
			best_score = score
			best = p
	if best.x < INF:
		return best + Vector2(16.0, 12.0)
	return best


func on_duck_disturbed(pos: Vector2) -> void:
	ducks_disturbed += 1
	float_text(pos, "quack!", Color(1, 0.9, 0.5))


func on_critter_chase(pos: Vector2, kind: String) -> void:
	squirrels_chased += 1
	mood.bump(Mood.M.BARKY, 0.35)
	if kind == "cat":
		# not enemies - Tofu just prefers a respectful distance, and a
		# nose boop is the closest Millie ever gets
		bones += 4
		combo.add("BOOP", 4)
		float_text(pos, "boop! +4", Color(1, 0.95, 0.7))
	else:
		bones += 2
		combo.add("CHASE", 2)
		float_text(pos, "almost got it! +2", Color(1, 0.95, 0.7))
	_update_hud()


func on_dog_hit() -> void:
	dog_hits += 1
	mood.bump(Mood.M.SCARED, 0.45)
	# a knock is a wipeout: whatever chain you had going is gone
	combo.bail()


func _greetings() -> void:
	# a nose-to-nose with any other dog counts once - sniff hello
	var others: Array = get_tree().get_nodes_in_group("freedogs")
	others.append_array(get_tree().get_nodes_in_group("pairs"))
	for o in others:
		var op: Vector2 = o.global_position if o.is_in_group("freedogs") else o.npc_dog.position
		var id: int = o.get_instance_id()
		if dog.global_position.distance_to(op) < 28.0 and not greeted.has(id):
			greeted[id] = true
			dogs_greeted += 1
			combo.add("HELLO", 3)
			float_text(op + Vector2(0, -18), "sniff! hi", Color(0.8, 1.0, 0.85))


func _pair_spawn_distance(camera_y: float) -> float:
	var max_distance := minf(
		PAIR_SPAWN_DIST,
		minf(camera_y - (GATE_Y + 60.0), (START_Y + 100.0) - camera_y)
	)
	return max_distance if max_distance >= PAIR_MIN_SPAWN_DIST else 0.0


func _pair_spawn_route(walk_phase: String, oncoming: bool, camera_y: float) -> Dictionary:
	var player_dir_y := -1.0 if walk_phase == "out" else 1.0
	var pair_dir_y := -player_dir_y if oncoming else player_dir_y
	var spawn_distance := _pair_spawn_distance(camera_y)
	return {
		"y": camera_y - pair_dir_y * spawn_distance,
		"direction": Vector2(0.0, pair_dir_y),
	}


func _pair_park_bounds() -> Rect2:
	return Rect2(90.0, freedom_lo, 1100.0, GATE_Y - 30.0 - freedom_lo)


func reserve_pair_park_spot(pair_id: int) -> Dictionary:
	if pair_park_slots.has(pair_id):
		var existing := int(pair_park_slots[pair_id])
		return {
			"found": true,
			"slot_id": existing,
			"position": PAIR_PARK_SPOTS[existing].position,
		}
	var occupied := pair_park_slots.values()
	for i in range(PAIR_PARK_SPOTS.size()):
		if i not in occupied:
			pair_park_slots[pair_id] = i
			return {
				"found": true,
				"slot_id": i,
				"position": PAIR_PARK_SPOTS[i].position,
			}
	return {"found": false, "slot_id": -1, "position": Vector2.ZERO}


func release_pair_park_spot(pair_instance_id: int) -> void:
	pair_park_slots.erase(pair_instance_id)


func _furniture_wrap_poles() -> Array[Vector2]:
	# typed furniture wrap centres: same collision as poles, distinct slip /
	# contact metadata so terrace chairs do not share pole-only semantics
	var furn: Array[Vector2] = []
	for arr in [tables, chairs, parasols, bins]:
		for p: Vector2 in arr:
			furn.append(p)
	return furn


func _make_pair(start: Vector2, direction: Vector2, activate := true) -> Node2D:
	var pair := Node2D.new()
	pair.set_script(load("res://otherpair.gd"))
	pair.setup(self, dog, poles, start, direction)
	pair.leash.furniture_poles = _furniture_wrap_poles()
	if not pair.configure_route(
		start.x,
		walk_cx - walk_half + 30.0,
		walk_cx + walk_half - 30.0,
		bypasser_blockers
	):
		pair.free()
		return null
	pair.configure_park_area(GATE_Y, _pair_park_bounds())
	if activate:
		add_child(pair)
	return pair


func _create_configured_pair(start: Vector2, direction: Vector2) -> Node2D:
	return _make_pair(start, direction, false)


func _pair_qualifies_for_arrival(pair: Node2D) -> bool:
	return (
		phase == "out" or phase == "freedom"
	) and (
		not pair.is_park_lifecycle_active()
		and pair.desired_vertical_speed < 0.0
		and pair.npc_owner.position.y <= GATE_Y + 35.0
		and pair.npc_owner.position.y >= GATE_Y - 45.0
	)


func _try_start_pair_arrival(pair: Node2D) -> bool:
	if not _pair_qualifies_for_arrival(pair):
		return false
	var pair_id := pair.get_instance_id()
	var reservation := reserve_pair_park_spot(pair_id)
	if not bool(reservation.found):
		return false
	if pair.begin_park_arrival(
		int(reservation.slot_id),
		reservation.position
	):
		return true
	release_pair_park_spot(pair_id)
	return false


func _start_pair_arrivals(pairs: Array) -> void:
	for pair in pairs:
		_try_start_pair_arrival(pair)


func _build_park_pair(kind: String) -> Node2D:
	var arriving := kind == "arrival"
	if not arriving and kind != "departure":
		return null
	var start := Vector2(
		randf_range(walk_cx - 120.0, walk_cx + 120.0),
		GATE_Y + 420.0 if arriving else GATE_Y - 120.0
	)
	var pair := _create_configured_pair(
		start,
		Vector2.UP if arriving else Vector2.DOWN
	)
	if pair == null:
		return null
	var pair_id := pair.get_instance_id()
	var reservation := reserve_pair_park_spot(pair_id)
	var prepared := false
	if bool(reservation.found):
		if arriving:
			prepared = pair.begin_park_arrival(
				int(reservation.slot_id),
				reservation.position
			)
		else:
			var bounds := _pair_park_bounds()
			var dog_position := Vector2(
				randf_range(bounds.position.x, bounds.end.x),
				randf_range(bounds.position.y, bounds.end.y)
			)
			prepared = pair.initialize_parked_departure(
				int(reservation.slot_id),
				reservation.position,
				dog_position,
				randf_range(1.5, 4.0)
			)
	if not prepared:
		release_pair_park_spot(pair_id)
		pair.free()
		return null
	return pair


func _spawn_freedom_pair(active_pair_count: int, preferred_kind: String) -> Node2D:
	if active_pair_count >= MAX_ACTIVE_PAIRS:
		return null
	var other_kind := "departure" if preferred_kind == "arrival" else "arrival"
	for kind in [preferred_kind, other_kind]:
		var pair := _build_park_pair(kind)
		if pair != null:
			add_child(pair)
			return pair
	return null


func _clear_detached_pair_tangles(pairs: Array, delta: float) -> void:
	for pair in pairs:
		pair.leash.dynamic_obstacles.clear()
		pair.update_tangle_state(false, delta)


func _prepare_pairs_for_home(pairs: Array) -> void:
	for pair in pairs:
		pair.begin_home_departure()


func _sample_player_rope() -> void:
	my_rope_sample.clear()
	for i in range(0, leash.N, 2):
		my_rope_sample.append(leash.pts[i])


func _refresh_pair_obstacles() -> void:
	# Called before the player leash solve. Clears stale dynamic contacts and
	# re-feeds from each visible pair whose rope bounds overlap ours.
	leash.dynamic_obstacles.clear()
	if tutorial_mode or not is_inside_tree():
		return
	var pairs := get_tree().get_nodes_in_group("pairs")
	if leash.detached:
		for pair in pairs:
			pair.leash.dynamic_obstacles.clear()
		return
	_sample_player_rope()
	var my_bounds := TangleGeom.rope_bounds(my_rope_sample, TangleGeom.BROADPHASE_PAD)
	for p in pairs:
		if not p.leash.visible or bool(p.leash.detached) or bool(p.mercy_hold):
			p.leash.dynamic_obstacles.clear()
			continue
		var their: Array[Vector2] = p.sampled
		if their.is_empty():
			p.leash.dynamic_obstacles.clear()
			continue
		var their_bounds := TangleGeom.rope_bounds(their, TangleGeom.BROADPHASE_PAD)
		if not TangleGeom.bounds_overlap(my_bounds, their_bounds):
			p.leash.dynamic_obstacles.clear()
			continue
		leash.dynamic_obstacles.append_array(their)
		p.leash.dynamic_obstacles = my_rope_sample.duplicate()


func _pairs(delta: float) -> void:
	if tutorial_mode:
		return  # a first walk is quiet: no other dog-walkers at all
	# mixed-direction dog-walkers; their leashes tangle yours
	var pairs := get_tree().get_nodes_in_group("pairs")
	if phase == "freedom":
		park_pair_spawn_t -= delta
		if park_pair_spawn_t <= 0.0 and pairs.size() < MAX_ACTIVE_PAIRS:
			var preferred_kind := "arrival" if randf() < 0.5 else "departure"
			var pair := _spawn_freedom_pair(pairs.size(), preferred_kind)
			park_pair_spawn_t = randf_range(7.0, 11.0) if pair != null else 1.0
			if pair != null:
				pairs.append(pair)
	else:
		pair_spawn_t -= delta
		if pair_spawn_t <= 0.0 and pairs.size() < MAX_ACTIVE_PAIRS:
			var camera_y := cam.get_screen_center_position().y
			var spawn_distance := _pair_spawn_distance(camera_y)
			if spawn_distance > 0.0:
				pair_spawn_t = randf_range(6.0, 11.0)
				var route := _pair_spawn_route(phase, randf() < 0.5, camera_y)
				var y: float = route["y"]
				if y >= GATE_Y + 60.0 and y <= START_Y + 100.0:
					var direction: Vector2 = route["direction"]
					var start := Vector2(randf_range(walk_cx - 120.0, walk_cx + 120.0), y)
					var pair := _make_pair(start, direction)
					if pair != null:
						pairs.append(pair)
	_start_pair_arrivals(pairs)
	if leash.detached:
		_clear_detached_pair_tangles(pairs, delta)
		return
	# Obstacle feed already ran before the player leash solve; here we only
	# evaluate segment/capsule contact + the rising-edge reward latch.
	_sample_player_rope()
	var my_bounds := TangleGeom.rope_bounds(my_rope_sample, TangleGeom.BROADPHASE_PAD)
	for p in pairs:
		var crossing := false
		if not p.leash.visible or bool(p.leash.detached):
			p.leash.dynamic_obstacles.clear()
		else:
			if bool(p.mercy_hold):
				p.leash.dynamic_obstacles.clear()
			var their: Array[Vector2] = p.sampled
			var their_bounds := TangleGeom.rope_bounds(their, TangleGeom.BROADPHASE_PAD)
			if their.is_empty() or not TangleGeom.bounds_overlap(my_bounds, their_bounds):
				if not bool(p.mercy_hold):
					p.leash.dynamic_obstacles.clear()
			else:
				crossing = TangleGeom.contact_with_hysteresis(
					my_rope_sample, their, bool(p.tangle_touching) or bool(p.mercy_hold)
				)
		if p.update_tangle_state(crossing, delta):
			tangles += 1
			bones += 3
			Sfx.play("tangle")
			combo.add("TANGLE", 3)
			feed.say("YOU TANGLED THEM!  +3", EventFeed.Tone.GOOD)


# A PATCH THAT LIES ON THE PATH.
#
# Everything that covers part of the walk - mud, a stream, the conveyor, a
# terrace awning - was a Rect2, and a hard axis-aligned rectangle laid across a
# bend overhangs the pavement onto the grass on the outside of every curve.
# That, not the edge maths, is what actually stopped a level from bending: the
# corridor could curve, but the things sitting on it could not follow.
#
# So a band spans a y RANGE and a fraction of the corridor's WIDTH, and asks
# walk_edges where the path is at each point down itself. Full width is
# {lo: 0, hi: 1}; the station's centre conveyor is about {lo: 0.38, hi: 0.62}.
# Being fractions rather than pixels also means a band narrows where the path
# narrows, which is what you want from a puddle and from a moving walkway both.
#
#   {"y": top y, "h": height, "lo": 0..1, "hi": 0..1}

# ORGANIC PATCHES: mud, wet cement, spilled paint, a pond.
#
# In life not one of these has a straight edge, and every one of them was a
# Rect2 - which is a good part of why the levels read as blocky. The park's
# pond was the worst of it: a rectangle with a grey rim reads as a municipal
# swimming pool rather than as water.
#
# A patch is a wobbled ellipse. Its outline is a sum of sines keyed to its own
# seed, which makes it organic, cheap enough to test every frame, and
# DETERMINISTIC - no RNG anywhere near it, so the autowalk stays reproducible.
#
# Position is PATH-RELATIVE: a fraction across the corridor plus a world y. So
# a puddle sits in the same part of the trail wherever the trail goes, and
# follows a bend for nothing.
#
#   {"y": float, "at": 0..1 across the path, "rx": float, "ry": float,
#    "seed": float}

const PATCH_LOBES := 22


func _patch_lobes(rx: float, ry: float) -> int:
	# segments scale with the patch, or a big one reads as a cut gem rather
	# than as water. The pond was visibly faceted at a flat 22.
	return clampi(int((rx + ry) * 0.5 / 6.0) + 12, 16, 56)


func patch_centre(pt: Dictionary) -> Vector2:
	var y := float(pt["y"])
	var e := walk_edges(y)
	return Vector2(e.x + (e.y - e.x) * float(pt["at"]), y)


func _patch_wobble(pt: Dictionary, ang: float) -> float:
	# three sines at unrelated frequencies: lumpy enough to read as natural,
	# smooth enough that the outline never kinks
	var sd := float(pt["seed"])
	return (1.0 + 0.17 * sin(ang * 3.0 + sd) + 0.10 * sin(ang * 5.0 + sd * 1.7)
		+ 0.06 * sin(ang * 8.0 + sd * 2.3))


func patch_has_point(pt: Dictionary, p: Vector2) -> bool:
	var d := p - patch_centre(pt)
	var nx := d.x / float(pt["rx"])
	var ny := d.y / float(pt["ry"])
	var dist := sqrt(nx * nx + ny * ny)
	if dist > 1.4:
		return false      # outside even the lumpiest possible outline
	return dist <= _patch_wobble(pt, atan2(ny, nx))


func patch_bounds(pt: Dictionary) -> Rect2:
	# a coarse box round the whole thing, for culling and for the code that
	# still only speaks Rect2
	var c := patch_centre(pt)
	var rx: float = float(pt["rx"]) * 1.3
	var ry: float = float(pt["ry"]) * 1.3
	return Rect2(c.x - rx, c.y - ry, rx * 2.0, ry * 2.0)


# TRENCADIS: a mosaic of broken tile, the technique El Parc's terraces are
# surfaced with. Style, not any particular work - a way of laying shards, which
# is nobody's property.
#
# Drawn as irregular shards inside the patch outline, from the same deterministic
# sine hashing as everything else here, so it never touches the RNG the autowalk
# depends on. The shard grid is bounded by the patch's own size, so a big terrace
# costs proportionally and no more.
const TRENCADIS := [
	Color(0.86, 0.88, 0.84),   # ceramic white
	Color(0.42, 0.66, 0.66),   # sea glass
	Color(0.30, 0.48, 0.62),   # deep blue
	Color(0.84, 0.62, 0.30),   # terracotta
	Color(0.72, 0.76, 0.52),   # olive
	Color(0.90, 0.80, 0.56),   # sand glaze
]


func _draw_sand_drift(pt: Dictionary) -> void:
	# WIND-BLOWN SAND, which is not a puddle.
	#
	# The generic patch draw gave this a solid body and a darker RIM, and a rim
	# is how you draw standing liquid - it reads as a depression holding
	# something, so a sand drift came out looking like quicksand on the paving.
	# Sand does the opposite of all of that. It arrives grain by grain, banks up
	# thickest on the side it blew in from, and has no edge at all: it dissolves
	# into the concrete.
	#
	# So: no rim and no outline. The body is several translucent passes, each
	# smaller and pushed back toward the beach, so density builds seaward and
	# thins inland instead of filling evenly. Then loose grains scattered past
	# the body, reaching furthest INLAND because that is the direction the drift
	# is creeping. All of it deterministic - no RNG anywhere near the autowalk.
	var mid := patch_centre(pt)
	var rx := float(pt["rx"])
	var ry := float(pt["ry"])
	var sd := float(pt["seed"])
	var col := Color(0.87, 0.79, 0.59)
	for i in range(4):
		var g: float = 1.0 - float(i) * 0.21
		# each pass sits a little further toward the sand it came from
		var off := Vector2(-rx * 0.09 * float(i), 0.0)
		# dense enough to be READ. This is a real surface - heavy going, poor
		# grip, marks her paws - so a drift you cannot see is a slow patch that
		# punishes you for nothing. Soft-edged, not faint.
		_draw_pinned_patch(pt, mid + off, Color(col.r, col.g, col.b, 0.34), g)
	# The dissolve: individual grains, thinning outward and carried further on
	# the inland side so the drift reads as a tongue rather than a blot.
	#
	# Precomputed at build time (see _seed_drift_grains), because a drift never
	# moves and hashing ninety positions per drift per frame is waste on
	# principle. Measured honestly: it did NOT move the number - the beach draw
	# is ~580us either way - so this is tidiness rather than a fix. The hot spot
	# at the far end of that walk is somewhere else and is not the drifts.
	var grains: PackedVector3Array = pt.get("grains", PackedVector3Array())
	if grains.is_empty():
		grains = _seed_drift_grains(pt)
		pt["grains"] = grains
	for gv: Vector3 in grains:
		draw_circle(mid + Vector2(gv.x, gv.y) * Vector2(rx, ry), 1.5 + gv.z * 1.5,
			Color(col.r, col.g, col.b, (1.0 - gv.z) * 0.55 + 0.12))


func _seed_drift_grains(pt: Dictionary) -> PackedVector3Array:
	# x,y are offsets in UNIT patch space (multiplied by rx/ry at draw time, so
	# the same grains still work if a drift is resized); z carries how far out
	# the grain got, which the draw turns into both its size and its fade.
	var sd := float(pt["seed"])
	var out := PackedVector3Array()
	for i in range(90):
		var h := sin(float(i) * 12.9898 + sd) * 43758.5453
		h = h - floor(h)
		var h2 := sin(float(i) * 78.233 + sd * 1.7) * 24634.6345
		h2 = h2 - floor(h2)
		var a := h * TAU
		var reach: float = 0.58 * (1.0 + 0.9 * maxf(0.0, cos(a)))
		var r: float = 0.94 + h2 * reach
		out.append(Vector3(cos(a) * r, sin(a) * r, clampf((r - 0.94) / reach, 0.0, 1.0)))
	return out


func _draw_trencadis(pt: Dictionary) -> void:
	var mid := patch_centre(pt)
	var rx := float(pt["rx"])
	var ry := float(pt["ry"])
	var sd := float(pt["seed"])
	# the mortar bed first, so the gaps between shards read as grout
	draw_patch(self, pt, Color(0.30, 0.28, 0.26, 0.95))
	# then the shards. Stepped in a grid and jittered, which is how a real
	# mosaic goes down - laid roughly in courses, never square.
	var step := 17.0
	var nx := int(rx * 2.0 / step)
	var ny := int(ry * 2.0 / step)
	for iy in range(ny):
		for ix in range(nx):
			var u := (float(ix) + 0.5) / float(nx) * 2.0 - 1.0
			var v := (float(iy) + 0.5) / float(ny) * 2.0 - 1.0
			# a deterministic wobble per cell, so shards are not on a lattice
			var h := sin(float(ix) * 12.9898 + float(iy) * 78.233 + sd) * 43758.5453
			h = h - floor(h)
			var h2 := sin(float(ix) * 39.3468 + float(iy) * 11.135 + sd * 1.7) * 24634.6345
			h2 = h2 - floor(h2)
			# jitter kept well under the step: real trencadis is fitted tight
			# with thin grout between shards, and at 0.8 of a step they drifted
			# apart and read as scattered confetti on tarmac
			var px := u * rx + (h - 0.5) * step * 0.42
			var py := v * ry + (h2 - 0.5) * step * 0.42
			# keep inside the patch's own wobbled outline
			var d := Vector2(px / rx, py / ry)
			if d.length() > _patch_wobble(pt, d.angle()) * 0.94:
				continue
			var col: Color = TRENCADIS[int(h * float(TRENCADIS.size())) % TRENCADIS.size()]
			# a shard: a quad, tilted and unequal, never a tile
			var w := step * (0.50 + 0.18 * h)
			var t := (h2 - 0.5) * 1.1
			var a := Vector2(cos(t), sin(t)) * w
			var b := Vector2(-sin(t), cos(t)) * (w * (0.62 + 0.4 * h2))
			var c := mid + Vector2(px, py)
			draw_colored_polygon(
				PackedVector2Array([c - a - b, c + a - b * 0.8, c + a * 0.9 + b, c - a * 0.8 + b]),
				col)


func _draw_pinned_patch(pt: Dictionary, at: Vector2, col: Color,
		grow := 1.0) -> void:
	# A patch at an absolute world position rather than a fraction across the
	# path, for things authored against the level itself - the park's pond sits
	# where the park put it, not where the path happens to be.
	#
	# grow scales the SAME outline outward, which is how the bank and the water
	# stay concentric. Drawing them from two different seeds made the bank poke
	# through the water as dark spikes wherever the two wobbles disagreed.
	var rx: float = float(pt["rx"]) * grow
	var ry: float = float(pt["ry"]) * grow
	var n := _patch_lobes(rx, ry)
	var poly := PackedVector2Array()
	for i in range(n):
		var a := TAU * float(i) / float(n)
		var r := _patch_wobble(pt, a)
		poly.append(at + Vector2(cos(a) * rx * r, sin(a) * ry * r))
	draw_colored_polygon(poly, col)


func draw_patch(c: CanvasItem, pt: Dictionary, col: Color,
		rim := Color(0, 0, 0, 0)) -> void:
	var mid := patch_centre(pt)
	var rx := float(pt["rx"])
	var ry := float(pt["ry"])
	var n := _patch_lobes(rx, ry)
	var poly := PackedVector2Array()
	for i in range(n):
		var a := TAU * float(i) / float(n)
		var r := _patch_wobble(pt, a)
		poly.append(mid + Vector2(cos(a) * rx * r, sin(a) * ry * r))
	if rim.a > 0.0:
		# a darker wet ring just outside, which is what makes a puddle read as
		# a dip in the ground rather than a sticker on top of it
		var out := PackedVector2Array()
		for i in range(poly.size()):
			out.append(mid + (poly[i] - mid) * 1.10)
		c.draw_colored_polygon(out, rim)
	c.draw_colored_polygon(poly, col)


func zone_has_point(z: Dictionary, p: Vector2) -> bool:
	# a substance zone is either a plain rectangle or a band that follows the
	# path. Asking here rather than at each call site is what stops the two
	# from drifting apart the way the old surface bools did.
	if z.has("patch"):
		return patch_has_point(z["patch"] as Dictionary, p)
	return (z["rect"] as Rect2).has_point(p)


func band_x(band: Dictionary, y: float) -> Vector2:
	# the band's left and right edge at this point down the level
	var e := walk_edges(y)
	var w: float = e.y - e.x
	return Vector2(e.x + w * float(band["lo"]), e.x + w * float(band["hi"]))


func band_has_point(band: Dictionary, p: Vector2) -> bool:
	var top: float = float(band["y"])
	if p.y < top or p.y > top + float(band["h"]):
		return false
	var x := band_x(band, p.y)
	return p.x >= x.x and p.x <= x.y


func band_bounds(band: Dictionary) -> Rect2:
	# a coarse rectangle around the whole band, for the cheap early-out tests
	# and for the code that still only speaks Rect2
	var top: float = float(band["y"])
	var h: float = float(band["h"])
	var a := band_x(band, top)
	var b := band_x(band, top + h * 0.5)
	var c := band_x(band, top + h)
	var lo: float = minf(a.x, minf(b.x, c.x))
	var hi: float = maxf(a.y, maxf(b.y, c.y))
	return Rect2(lo, top, hi - lo, h)


func draw_band(c: CanvasItem, band: Dictionary, col: Color, step := 40.0) -> void:
	# the same ribbon trick the pavement uses, so a patch follows the bend it
	# is lying on instead of hanging off the side of it
	var top: float = float(band["y"])
	var bot: float = top + float(band["h"])
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	var y := top
	while true:
		var yy: float = minf(y, bot)
		var x := band_x(band, yy)
		left.append(Vector2(x.x, yy))
		right.append(Vector2(x.y, yy))
		if yy >= bot:
			break
		y += step
	var poly := PackedVector2Array(left)
	for i in range(right.size() - 1, -1, -1):
		poly.append(right[i])
	c.draw_colored_polygon(poly, col)


func _draw_walk_ribbon(vt: float, vb: float, bottom: float, col: Color) -> void:
	# The pavement as a ribbon following the corridor, for a level whose path
	# bends. Sampled ONLY down the visible range: a walk is five thousand
	# pixels long and re-tracing all of it every frame is exactly the sort of
	# thing that turns a smooth walk choppy.
	#
	# The straight case never comes here (see the caller) so nothing pays for
	# this until a level actually uses it. The slab texture is left off a
	# curved path on purpose for now - _draw_paving rules its slabs between
	# the straight sw_l/sw_r and would overhang a bend.
	var top: float = maxf(GATE_Y - 40.0, vt - 80.0)
	var bot: float = minf(bottom, vb + 80.0)
	if bot <= top:
		return
	const STEP := 48.0
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	var y := top
	while y < bot + STEP:
		var yy: float = minf(y, bot)
		var e := walk_edges(yy)
		left.append(Vector2(e.x, yy))
		right.append(Vector2(e.y, yy))
		if yy >= bot:
			break
		y += STEP
	# one polygon: down the left edge and back up the right
	var poly := PackedVector2Array(left)
	for i in range(right.size() - 1, -1, -1):
		poly.append(right[i])
	draw_colored_polygon(poly, col)
	# the kerbs, following the same two edges the surface test uses
	for pts: PackedVector2Array in [left, right]:
		for i in range(pts.size() - 1):
			draw_line(pts[i], pts[i + 1], COL_SEAM, 3.0)


func walk_edges(y: float) -> Vector2:
	# (left_x, right_x) of the walkable path at this point down the level.
	# The single source of truth for where the path IS - the pavement is drawn
	# from it, the surface under her paws is decided by it, and props are
	# fitted to it, so a bend moves all three together.
	return EdgePath.edges(edge_nodes, y, walk_cx, walk_half)


func surface_at(p: Vector2) -> int:
	# The one place that decides what the ground is. Everything that cares -
	# how fast she goes, how well she can turn, how far she can smell - asks
	# this and then asks surfaces.gd, rather than each re-deriving it from a
	# different bit of geometry the way the old bools did.
	for w: Rect2 in water:
		if w.has_point(p):
			return Surfaces.S.WATER
	for pt: Dictionary in patches:
		if patch_has_point(pt, p):
			match String(pt["kind"]):
				"mud": return Surfaces.S.MUD
				"tile": return Surfaces.S.TILE
				_: return Surfaces.S.SAND
	if lvl == "beach":
		# THE SEAFRONT HAS NO GRASS. Its cross-section is sea, sand, boardwalk,
		# bike path, promenade, then cafe paving - so once the sea and the sand
		# are ruled out, everything left is firm ground. Falling through to the
		# generic verge test made the boardwalk and the cafe side read as lawn,
		# which is a third of the walk handling wrongly.
		if p.x < 340.0:
			return Surfaces.S.SAND
		return Surfaces.S.PAVEMENT
	for sz in substance_zones:
		if bool(sz.get("slow", false)) and zone_has_point(sz, p):
			return Surfaces.S.SAND
	var e := walk_edges(p.y)
	if p.x >= e.x and p.x <= e.y:
		return Surfaces.S.PAVEMENT
	# the carriageway and its shoulder are hard ground, not verge. Checked
	# after the walkway so the wider levels, whose pavement reaches across
	# this band, still read as pavement.
	if p.x >= BLANE_L - 10.0 and p.x <= SHOULDER_R:
		return Surfaces.S.PAVEMENT
	# anything else is the green either side, which is now somewhere worth
	# being rather than merely somewhere allowed
	return Surfaces.S.GRASS


func _offpath(delta: float) -> void:
	# the dog may roam, but an undistracted owner has opinions: after a
	# few seconds off the walk they tut and reel the leash in a notch
	dog.surface = surface_at(dog.global_position)
	# kept in step for the code that still asks the old question directly
	# (the dog's own drawing, the wading owner, the splash at the edge)
	dog.sand_slow = dog.surface == Surfaces.S.SAND or dog.surface == Surfaces.S.MUD
	# stand in something and it comes with you
	for sz in substance_zones:
		if zone_has_point(sz, dog.global_position):
			paw_kind = String(sz.kind)
			var sd: Dictionary = SUBSTANCES[paw_kind]
			wet_paws = float(sd.life)
			break
	# ...and a swim takes it all straight back off. True of dogs, the only way
	# to undo a substance, and the thing that makes water a trade rather than
	# purely a slow patch you have to cross
	if bool(Surfaces.feel(dog.surface)["washes"]) and wet_paws > 0.0:
		wet_paws = 0.0
		paw_kind = ""
	wet_paws = maxf(0.0, wet_paws - delta)
	if wet_paws > 0.0 and paw_last.distance_to(dog.global_position) > 26.0:
		paw_last = dog.global_position
		var side: Vector2 = dog.facing.orthogonal() * (5.0 if paw_prints.size() % 2 == 0 else -5.0)
		paw_prints.append({"pos": dog.global_position + side, "kind": paw_kind})
		if paw_prints.size() > 90:
			paw_prints.remove_at(0)
	# THE OWNER'S BOOTS. He is not exempt from the pavement, and a man who
	# has walked through wet cement while reading his phone leaves a trail
	# of it behind him. Strides are longer than hers and set wider apart.
	for sz in substance_zones:
		if zone_has_point(sz, human.global_position):
			boot_kind = String(sz.kind)
			wet_boots = float((SUBSTANCES[boot_kind] as Dictionary)["life"])
			break
	if wet_boots > 0.0:
		# he wades through the pond and it comes off him too
		var hf: Dictionary = Surfaces.feel(surface_at(human.global_position))
		if bool(hf["washes"]):
			wet_boots = 0.0
	wet_boots = maxf(0.0, wet_boots - delta)
	if wet_boots > 0.0 and boot_last.distance_to(human.global_position) > 38.0:
		boot_last = human.global_position
		var bside: Vector2 = human.face_dir.orthogonal() * (8.0 if paw_prints.size() % 2 == 0 else -8.0)
		paw_prints.append({"pos": human.global_position + bside, "kind": boot_kind,
			"boot": true, "ang": human.face_dir.angle()})
		if paw_prints.size() > 90:
			paw_prints.remove_at(0)
	# ...and so does your human, the moment you lean on their nice trousers
	if wet_paws > 0.0 and dog.global_position.distance_to(human.global_position) < 26.0 and smudge_cd <= 0.0:
		smudge_cd = 1.1
		var sdd: Dictionary = SUBSTANCES[paw_kind]
		owner_smudges.append({
			"off": (dog.global_position - human.global_position).limit_length(15.0),
			"kind": paw_kind,
		})
		if owner_smudges.size() > 10:
			owner_smudges.remove_at(0)
		smudges_left += 1
		bones += 2
		Sfx.play("snack", 0.8)
		combo.add("MUCKY", 3)
		float_text(human.global_position + Vector2(0, -34), String(sdd.quip) + " +2", Color(sdd.col).lightened(0.35))
	smudge_cd = maxf(0.0, smudge_cd - delta)
	var off: bool = dog.global_position.x < tut_l or dog.global_position.x > tut_r
	if off and human.is_available_for_chore() and not human.is_fallen():
		offpath_t += delta
		if offpath_t > 3.0:
			offpath_t = 0.0
			human.show_nag()
			set_leash_target(180.0)
	else:
		offpath_t = maxf(0.0, offpath_t - delta)


func _tick_vault(delta: float) -> void:
	# THE LEASH-VAULT. The rope is already the best thing in the game, so it
	# should be a way to MOVE, not only a way to be held back. Catch the
	# leash on a pole and keep running and the rope becomes a pivot: she
	# carves a fast arc around it and slingshots out along the tangent.
	# It steers her velocity rather than teleporting her, so the verlet rope
	# stays the source of truth and holds the radius honestly.
	vault_cd = maxf(0.0, vault_cd - delta)
	var pole: Vector2 = leash.contact_pole
	var wrapped: bool = pole.x < INF and leash.static_contacts > 0 and leash.contact_static
	if vault_t > 0.0:
		vault_t -= delta
		if not wrapped or dog.velocity.length() < 90.0 or dog.is_tumbling():
			_end_vault()
			return
		var tan := SwingMath.vault_tangent(pole, dog.global_position, dog.velocity)
		# hold her speed up and keep her pointed along the arc: this is the
		# carve. The rope itself stops her flying off the radius.
		var speed: float = maxf(dog.velocity.length(), VAULT_MIN_SPEED)
		dog.velocity = tan * minf(speed * 1.03, VAULT_MAX_SPEED)
		vault_arc += absf(dog.velocity.length() * delta / maxf(dog.global_position.distance_to(pole), 1.0))
		if vault_t <= 0.0:
			_end_vault()
		return
	if vault_cd > 0.0 or not wrapped or dog.is_tumbling() or teeter.active or grind.active:
		return
	# THE FLING HAS RIGHT OF WAY.
	#
	# These two moves are opposites and they were fighting over the same rope.
	# The vault steers her velocity along the arc, which is precisely the input
	# the whirl needs her to keep NOT doing - so a vault firing mid-wind-up
	# stole the fling, and the fling stole the vault back. They read as one
	# mechanic misbehaving rather than two.
	#
	# So the rope decides, by how wound the OWNER's end is: a clean single
	# wrap is a vault, and once his end is properly wound the vault stands
	# aside and lets the tetherball happen. Which also makes the vault the
	# set-up move - carve two arcs around a pole and you have wound him up
	# for the fling yourself.
	if human.is_whirling() or whirl_arm > 0.0:
		return
	if absf(leash.human_end_winding()) > 1.2:
		return
	# one vault per approach: she has to actually leave a pole before it will
	# give her another swing
	if vault_done_pole.x < INF:
		if dog.global_position.distance_to(vault_done_pole) > 210.0:
			vault_done_pole = Vector2(INF, INF)
		elif pole.distance_to(vault_done_pole) < 24.0:
			return
	# needs real pace and a rope under tension - a gentle wrap is not a vault
	var r := dog.global_position.distance_to(pole)
	if dog.velocity.length() < VAULT_TRIGGER_SPEED or r < 18.0 or r > 190.0:
		return
	if not leash.taut:
		return
	vault_t = 0.85
	vault_arc = 0.0
	vault_pole = pole
	vault_recent = 2.6
	Sfx.play("fling", 1.2, -8.0)
	feed.say("POLE SWING!", EventFeed.Tone.LOUD)


func _end_vault() -> void:
	if vault_t <= 0.0 and vault_arc <= 0.0:
		return
	vault_t = 0.0
	vault_cd = 0.7
	vault_done_pole = vault_pole
	# the payoff: a launch along the exit tangent, scaled by how much arc she
	# actually carved, so a committed swing throws her further than a clip
	var turns: float = vault_arc / TAU
	if turns > 0.12:
		var tan := SwingMath.vault_tangent(vault_pole, dog.global_position, dog.velocity)
		dog.velocity = tan * VAULT_LAUNCH
		var pts := int(round(8.0 + turns * 40.0))
		bones += int(pts / 4)
		vaults_landed += 1
		combo.add("VAULT", pts)
		Sfx.play("star", 1.15)
		feed.say("POLE SWING!  %d" % pts, EventFeed.Tone.LOUD)
		_slowmo()
		_update_hud()
	vault_arc = 0.0


func _tut_step_done(id: String) -> bool:
	# One check per lesson, each written against what the game already
	# tracks, so the tutorial teaches the REAL mechanics rather than a
	# scripted imitation of them.
	match id:
		"walk": return tut_start_y - dog.global_position.y > 240.0
		"pull": return leash.taut and leash.used_length() > leash_len * 0.98
		"pee": return marks.size() >= 1
		"sniff": return sniffs_done >= 1
		"nose":
			# ambling near something worth smelling: the lesson IS going slow
			if dog.velocity.length() > 110.0:
				return false
			for src in _scent_sources():
				if dog.global_position.distance_to(src.pos) < 240.0:
					return true
			return false
		"dig": return digs_done >= 1 or kebabs_eaten >= 1
		"bark": return barks_done >= 1
		"turbo": return dog.turbo_active and dog.energy < 0.94
		"grind": return grinds_landed >= 1
		"vault": return vaults_landed >= 1
		"done": return false   # the last card just sees you off
	return false


func _tick_tutorial(delta: float) -> void:
	tut_flash = maxf(0.0, tut_flash - delta)
	var st: Dictionary = TutorialSteps.step(tut_step)
	var id := String(st.id)
	if id == "":
		return
	# skippable, always: a tutorial that traps a player who cannot do the
	# thing is worse than no tutorial at all
	if Input.is_action_just_pressed("share") and id != "done":
		_tut_advance(false)
		return
	if _tut_step_done(id):
		_tut_advance(true)


func _tut_advance(earned: bool) -> void:
	tut_step += 1
	tut_flash = 1.1
	if earned:
		Sfx.play("star", 1.15)
		bones += 2
	else:
		Sfx.play("ui", 0.9)
	_update_hud()

func _update_tut_card() -> void:
	if not started:
		return
	var st: Dictionary = TutorialSteps.step(tut_step)
	if String(st.id) == "":
		tut_label.visible = false
		tut_hint.visible = false
		return
	tut_label.visible = true
	tut_hint.visible = true
	tut_label.text = String(st.title)
	var body := String(st.body)
	if String(st.id) != "done":
		body += "        (%s to skip)" % _kb_or_pad("C", "Y")
	tut_hint.text = body
	# a green flash of acknowledgement as each lesson lands
	var glow: float = clampf(tut_flash, 0.0, 1.0)
	tut_label.modulate = Color(1, 1, 1).lerp(Color(0.6, 1.0, 0.65), glow)


func on_rival_snatch(at: Vector2, what: String) -> void:
	mood.bump(Mood.M.BARKY, 0.45)
	# he has your things. This is a provocation, not a punishment: the combo
	# survives, and you can have it straight back if you go and get it.
	shake_t = maxf(shake_t, 0.3)
	Sfx.play("bark", 0.7, -5.0)
	var label := "MY BALL!" if what == "ball" else "MY BONE!"
	float_text(at + Vector2(0, -30), label + " bark at him!", Color(1, 0.7, 0.6))
	_update_hud()


func on_rival_drop(at: Vector2, what: String, msg: String, earned: bool) -> void:
	if what == "":
		return
	if not earned:
		# he wandered off with it. You get nothing, because you did nothing -
		# and the bone stays gone, so a thief who is ignored actually costs
		# you something.
		float_text(at + Vector2(0, -28), msg, Color(0.85, 0.8, 0.75))
		return
	# recovered: worth more than the thing was, because taking it back off
	# him is the better story
	var reward := 9 if what == "bone" else 7
	bones += reward
	rivals_beaten += 1
	Sfx.play("star", 1.1)
	combo.add("STEAL BACK", 7)
	float_text(at + Vector2(0, -30), "%s  +%d" % [msg, reward], Color(0.85, 1.0, 0.8))
	_slowmo()
	# only a genuine recovery puts the bone back within reach; letting him
	# escape with it means it is gone for good
	for pp in park_props:
		if String(pp.kind) == "dig" and pp.get("looted", false):
			pp["looted"] = false
			break
	_update_hud()


func _tick_call(_delta: float) -> void:
	# The owner takes a call and roots themselves for the better part of
	# twenty seconds. This is the premise of the whole game turned into a
	# gift: for once their obliviousness is YOUR window. The leash goes right
	# out (they are not reeling anyone in mid-natter), so the dog gets the
	# widest radius in the game to go and do as she pleases.
	var on_call: bool = human.is_on_call()
	if on_call and not call_active:
		call_active = true
		call_haul = 0
		call_slack_was = leash_target
		set_leash_target(440.0)
		Sfx.play("ui", 0.8)
		# at the DOG, not over an owner who may be most of a leash away. This is
		# the biggest gift in the game and it was being missed completely.
		# no transient here: human.gd already says he has stopped, and the
		# banner below carries the countdown. One event, one announcement.
	elif not on_call and call_active:
		call_active = false
		set_leash_target(call_slack_was)
		# paid by what you actually got up to with the freedom
		if call_haul > 0:
			var bonus := 3 + call_haul * 2
			bones += bonus
			Sfx.play("star", 1.05)
			feed.say("NICE! YOU DID %d THINGS  +%d" % [call_haul, bonus], EventFeed.Tone.GOOD)
			_update_hud()
		else:
			feed.say("YOU MISSED YOUR CHANCE", EventFeed.Tone.BAD)


func _tick_grind(delta: float) -> void:
	# The kerb is a rail. Run along one at a clip and you get up on it; hold
	# the balance with left/right nudges and it pays by the second. Bailing
	# costs the trick and the combo but nothing else, because this is a thing
	# you go looking for rather than a hazard to be survived.
	grind_cd = maxf(0.0, grind_cd - delta)
	var travelling_along := absf(dog.velocity.y) > absf(dog.velocity.x) * 1.4
	var fast_enough := dog.velocity.length() > GRIND_SPEED
	if grind.active:
		# lateral nudges feather the balance; leaving the rail lands it
		# Counter-steering, and the mapping is deliberately literal: your
		# stick tilts the balance, so you hold it up by leaning the other
		# way. Pressing left corrects a rightward tip.
		var counter: float = -dog.input_dir.x
		var res: String = grind.tick(delta, counter)
		var off_rail: bool = absf(dog.global_position.x - grind_kerb_x) > GRIND_BAND + 10.0
		if res == "bailed":
			grind_cd = 0.9
			combo.bail()
			Sfx.play("crack", 1.2, -10.0)
			feed.say("FELL OFF!", EventFeed.Tone.BAD)
			dog.stumble()
		elif off_rail or not fast_enough or not travelling_along:
			var pts := int(grind.land())
			grind_cd = 0.5
			if pts > 0:
				bones += int(pts / 4)
				grinds_landed += 1
				combo.add("GRIND", pts)
				Sfx.play("star", 1.2)
				feed.say("KERB RIDE!  %d" % pts, EventFeed.Tone.LOUD)
				_update_hud()
		return
	if grind_cd > 0.0 or dog.is_tumbling() or teeter.active or not fast_enough or not travelling_along:
		return
	# on a kerb? both corridor edges are rails
	for kx in [sw_l, sw_r]:
		if absf(dog.global_position.x - kx) < GRIND_BAND:
			grind_kerb_x = kx
			grind.begin()
			Sfx.play("save", 1.35, -10.0)
			feed.say("KERB RIDE!", EventFeed.Tone.LOUD)
			return


func _dist_to_rect_edge(r: Rect2, p: Vector2) -> float:
	# distance from a point OUTSIDE the rect to its nearest edge
	var cx := clampf(p.x, r.position.x, r.end.x)
	var cy := clampf(p.y, r.position.y, r.end.y)
	return p.distance_to(Vector2(cx, cy))


func _start_teeter(kind: String, at: Vector2, fail_msg := "") -> void:
	if teeter.active or teeter_cd > 0.0 or dog.is_tumbling():
		return
	teeter_kind = kind
	teeter_at = at
	teeter_msg = fail_msg
	teeter.begin()
	Sfx.play("save", 1.5, -8.0)
	shake_t = maxf(shake_t, 0.25)
	_slowmo()  # a beat of hang time, so you register that you can fight it


func _tick_teeter(delta: float) -> void:
	teeter_cd = maxf(0.0, teeter_cd - delta)
	if not teeter.active:
		return
	# scrambling AWAY from the brink is what saves you. Both the input AND
	# the actual travel count: if momentum is carrying her clear, that IS
	# escaping, and it would be daft to ignore it.
	var away := (dog.global_position - teeter_at).normalized()
	var counter := 0.0
	if dog.input_dir.length() > 0.1:
		counter = dog.input_dir.normalized().dot(away)
	if dog.velocity.length() > 40.0:
		counter = maxf(counter, dog.velocity.normalized().dot(away) * 0.9)
	# turbo is a panic scrabble: it helps, which is the intuitive reading
	if dog.turbo_active:
		counter += 0.25
	var res: String = teeter.tick(delta, counter)
	if res == "":
		return
	# She may have walked clear of the brink while the meter was filling, and
	# dying to a hole you are visibly standing past is indefensible. Physical
	# escape beats the meter: if she is no longer over it, she got out.
	if res == "fell" and dog.global_position.distance_to(teeter_at) > TEETER_ESCAPE_R:
		res = "saved"
	teeter_cd = 1.4  # never re-trigger instantly on the same brink
	if res == "saved":
		# a real recovery, scored like the stumble saves it echoes
		saves_done += 1
		streak += 1
		bones += 4
		Sfx.play("star", 1.1)
		combo.add("BALANCE", 6)
		feed.say("SAVED IT!  +4", EventFeed.Tone.GOOD)
		_slowmo()
		_update_hud()
		return
	# fell in. What that COSTS depends entirely on what you fell into.
	match teeter_kind:
		"water":
			# she is a dog who loves water: going in is not a punishment and
			# never ends the walk. It just breaks your run of tricks.
			combo.bail()
			Sfx.play("splash")
			feed.say("SPLASH! WORTH IT", EventFeed.Tone.PLAIN)
		_:
			# a hole is a hole
			if teeter_msg != "":
				_death(teeter_msg)
			else:
				dog.fall_in(teeter_at)


func _death(msg: String) -> void:
	frozen = true
	dim.visible = true
	msg_label.visible = true
	msg_label.text = msg + "\n\nPress %s to try again" % _kb_or_pad("R", "Start")


func _hazards(delta: float) -> void:
	for tw in towels:
		tw.cd = maxf(0.0, float(tw.cd) - delta)
		if tw.cd <= 0.0 and (tw.rect as Rect2).has_point(human.global_position):
			tw.cd = 4.0
			human.bumped((human.global_position - (tw.rect as Rect2).get_center()).normalized())
			float_text(human.global_position, "hey! my towel!", Color(1, 0.85, 0.7))
	# Millie LOVES the water. In she goes, paddling happily - and whatever is
	# on the other end of the leash comes too. The owner wades in reluctantly,
	# phone held high, and edges back to the bank. Nobody drowns; it is just
	# wet and a little undignified.
	if not water.is_empty():
		var dog_wet := false
		var hum_wet := false
		var bank_x: float = human.pond_bank_x
		for w: Rect2 in water:
			if w.grow(-4.0).has_point(dog.global_position):
				dog_wet = true
			if w.grow(-4.0).has_point(human.global_position):
				hum_wet = true
				# out the side he came in by, whichever is nearer
				bank_x = (w.position.x - 24.0
					if absf(human.global_position.x - w.position.x) < absf(human.global_position.x - w.end.x)
					else w.end.x + 24.0)
			# A wobble at the water's edge, but ONLY when she arrives at a
			# proper clip - a stumble, not a toll gate. It never blocks her
			# getting in (she loves water) and losing it costs nothing but the
			# combo, so this is pure comedy plus a chance to look graceful.
			if not dog_wet and not auto_walk and dog.velocity.length() > 210.0:
				if _dist_to_rect_edge(w, dog.global_position) < 26.0:
					_start_teeter("water", w.get_center())
		var was_swim: bool = dog.swimming
		dog.swimming = dog_wet
		if dog_wet and not was_swim:
			Sfx.play("splash")
			float_text(dog.global_position, "splish!", Color(0.7, 0.85, 1.0))
			swam = true
		var was_wade: bool = human.wading
		human.wading = hum_wet
		human.pond_bank_x = bank_x
		if hum_wet and not was_wade:
			float_text(human.global_position, "no no no-", Color(0.7, 0.85, 1.0))
	# open holes are the TOP tier of danger: falling in ends the walk,
	# full stop. Bumps hurt a little; holes hurt completely.
	# (auto_walk is a test/attract traversal - it is not allowed to die)
	if auto_walk:
		return
	for m in manholes:
		if human.global_position.distance_to(m) < 18.0 and not human.is_fallen():
			_death("THE HUMAN WENT DOWN THE MANHOLE\n\nThe phone gets a signal down there.\nThe walk does not.")
			return
		# the dog gets a teeter first: a brink is a skill moment, not an
		# instant punishment
		if dog.global_position.distance_to(m) < 22.0:
			_start_teeter("hole", m, "MILLIE WENT DOWN THE MANHOLE\n\nShe is fine. The walk is very over.")
			return
	for c in cellars:
		if c.has_point(human.global_position):
			_death("THE HUMAN FELL IN THE CELLAR\n\nRight onto the delivery. You did warn them,\nin the only language you have.")
			return
		if c.grow(6.0).has_point(dog.global_position):
			_start_teeter("hole", c.get_center(), "MILLIE FELL INTO THE CELLAR\n\nShe found the sausages. The walk is still over.")
			return


func _pickups(delta: float) -> void:
	if not prize_taken and prize_pos.x < INF and dog.global_position.distance_to(prize_pos) < 28.0:
		prize_taken = true
		bones += 8
		Sfx.play("star", 0.9)
		float_text(prize_pos, "got it! +8", Color(1, 0.9, 0.5))
	# carry mission: grab it, then take it to the drop-off
	if carry_pickup.x < INF:
		if carry_state == 0 and dog.global_position.distance_to(carry_pickup) < 28.0:
			carry_state = 1
			Sfx.play("pickup", 0.9)
			float_text(carry_pickup, "got %s!" % carry_item, Color(0.85, 1.0, 0.85))
			_update_hud()
		elif carry_state == 1 and dog.global_position.distance_to(carry_drop) < 34.0:
			carry_state = 2
			bones += 10
			Sfx.play("star")
			combo.add("DELIVER", 5)
			float_text(carry_drop, "delivered! +10", Color(0.8, 1.0, 0.8))
			_slowmo()
			_update_hud()
	for h in hydrants:
		if h.done:
			continue
		if dog.global_position.distance_to(h.pos) < 55.0 and dog.velocity.length() < 60.0:
			h.progress += delta
			if h.progress >= 0.8:
				h.done = true
				bones += 2
				sniffs_done += 1
				Sfx.play("mark", 1.2)
				combo.add("SNIFF", 2)
				float_text(h.pos, "good sniff +2", Color(1, 0.95, 0.7))
				_update_hud()
	# reading the noticeboard: another dog's mark is worth a proper sniff,
	# and it is how you find out who else has been through
	for nm in npc_marks:
		if bool(nm.sniffed):
			continue
		if dog.global_position.distance_to(nm.pos) < 30.0 and dog.velocity.length() < 70.0:
			nm.sniffed = true
			sniffs_done += 1
			bones += 2
			Sfx.play("mark", 1.3)
			combo.add("READ", 2)
			float_text(nm.pos, "%s was here +2" % String(nm.who), Color(0.9, 0.95, 0.75))
			_update_hud()
	# the Fur-Goneta: a van that smells of four hundred other dogs. Sniffing it
	# is the biggest single payout on the walk, and you only get it once.
	if furgoneta.x < INF and not furgoneta_sniffed:
		if dog.global_position.distance_to(furgoneta) < 82.0 and dog.velocity.length() < 90.0:
			furgoneta_sniffed = true
			bones += 12
			sniffs_done += 1
			Sfx.play("star", 0.9)
			combo.add("FUR-GONETA", 8)
			float_text(furgoneta + Vector2(0, -70.0),
				"four hundred dogs have been in there +12", Color(1, 0.9, 0.6))
			_update_hud()
	for k in kebabs:
		if not k.eaten and dog.global_position.distance_to(k.pos) < 26.0:
			k.eaten = true
			bones += 1
			kebabs_eaten += 1
			# food answers being tired, it does not cause it. A whole kebab off
			# the pavement is most of the way out of a flagging walk, which is
			# both realistic and the reason to go out of your way for one
			mood.soothe(Mood.M.TIRED, 0.55)
			Sfx.play("snack")
			combo.add("SNACK", 1)
			float_text(k.pos, "snack +1", Color(1, 0.95, 0.7))
			_update_hud()
	# The off-leash furniture, all of it rewarding a nose rather than a
	# straight line: dig patches hide a bone (hold still over one and keep
	# digging), shrubs and posts are worth a sniff, the trough is a drink.
	if phase == "freedom":
		for pp in park_props:
			if pp.done:
				continue
			var d := dog.global_position.distance_to(pp.pos)
			match String(pp.kind):
				"dig":
					if d < 30.0 and dog.velocity.length() < 70.0:
						pp.prog = float(pp.prog) + delta
						_freedom_dirty()
						if float(pp.prog) >= 1.1:
							pp.done = true
							digs_done += 1
							bones += 6
							Sfx.play("star", 0.85)
							combo.add("DIG", 4)
							float_text(pp.pos, "buried treasure! +6", Color(1, 0.9, 0.55))
							_update_hud()
					else:
						var was_dig: float = float(pp.prog)
						pp.prog = maxf(0.0, was_dig - delta * 0.6)
						if was_dig > 0.0 and float(pp.prog) < was_dig:
							_freedom_dirty()
				"shrub", "post", "rock", "driftwood", "tyre":
					if d < 34.0 and dog.velocity.length() < 80.0:
						pp.prog = float(pp.prog) + delta
						_freedom_dirty()
						if float(pp.prog) >= 0.7:
							pp.done = true
							sniffs_done += 1
							bones += 2
							Sfx.play("mark", 1.15)
							combo.add("SNIFF", 2)
							float_text(pp.pos, "good sniff +2", Color(1, 0.95, 0.7))
							_update_hud()
					else:
						var was_sniff: float = float(pp.prog)
						pp.prog = maxf(0.0, was_sniff - delta)
						if was_sniff > 0.0 and float(pp.prog) < was_sniff:
							_freedom_dirty()
				"trough":
					if d < 34.0:
						drunk_amount += 0.34 * delta
						pee = minf(1.0, pee + 0.3 * delta)
	# the candy you should not have: chocolate is poison to dogs, so
	# wolfing it costs you (and your clean-tummy goal)
	for c in candy:
		if not c.eaten and dog.global_position.distance_to(c.pos) < 26.0:
			c.eaten = true
			candy_eaten += 1
			bones = maxi(0, bones - 3)
			shake_t = maxf(shake_t, 0.4)
			Sfx.play("tangle", 0.7)
			float_text(c.pos, "BLEH! not for dogs -3", Color(1, 0.5, 0.45))
			_update_hud()


func _bodily(delta: float) -> void:
	# the life of a dog: pee anywhere the leash allows (spots score),
	# and once per walk nature calls for a longer stop.
	# No free refills: the tank only refills at water - fountains,
	# bowls, the beach shower - drunk standing still, like a lady.
	for f in fountains:
		if dog.global_position.distance_to(f) < 34.0 and dog.velocity.length() < 40.0:
			pee = minf(1.0, pee + 0.3 * delta)
			drunk_amount += 0.3 * delta
	dog.bladder_slow = pee >= 0.999
	# peeing has its own button now; a yank that gets you moving
	# interrupts it (the tank is a per-walk budget, ~9 breaks)
	# velocity gate is loose: being gently towed must not block the pee
	# (a hard yank still interrupts it)
	var going: bool = Input.is_action_pressed("pee") and pee > 0.02 \
		and not dog.is_tumbling() and dog.velocity.length() < 80.0
	dog.peeing = going
	if going:
		pee = maxf(0.0, pee - 0.16 * delta)
		var target := _nearest_markable(dog.global_position)
		if target.x < INF:
			if target != mark_target:
				mark_target = target
				mark_progress = 0.0
			mark_progress += delta
			stray_t = 0.0
			if mark_progress >= 0.7:
				# Over-marking. Any dog owner has watched this happen: the
				# interesting spot is not the clean post, it is the one that
				# already smells of someone else. So it pays double.
				var over := _npc_mark_at(target)
				var pay := 6 if not over.is_empty() else 3
				bones += pay
				marks.append(target)
				Sfx.play("mark")
				combo.add("OVER-MARK" if not over.is_empty() else "MARK", pay)
				if over.is_empty():
					float_text(target, "marked! +3", Color(1, 0.95, 0.7))
				else:
					overmarks += 1
					npc_marks.erase(over)
					float_text(target, "over-marked %s! +6" % String(over.who),
						Color(1, 0.85, 0.55))
				mark_progress = 0.0
				mark_target = Vector2(INF, INF)
				if marks.size() >= 5 and not mark_quest_done:
					mark_quest_done = true
					bones += 10
					feed.say("ALL YOUR SPOTS MARKED!  +10", EventFeed.Tone.GOOD)
		else:
			mark_target = Vector2(INF, INF)
			mark_progress = 0.0
			stray_t += delta
	else:
		if stray_t >= 0.4:
			# puddle size is a matter of commitment
			puddles.append({
				"pos": dog.global_position + Vector2(4, 8),
				"r": clampf(4.0 + stray_t * 7.0, 5.0, 13.0),
			})
		stray_t = 0.0
		mark_progress = 0.0
		mark_target = Vector2(INF, INF)
	match poop_state:
		0:
			if dog.global_position.y < urge_y:
				poop_state = 1
				urge_timer = 35.0
				float_text(dog.global_position, "uh oh...", Color(1, 0.9, 0.6))
		1:
			urge_timer -= delta
			if dog.planted and not dog.is_tumbling():
				squat_progress += delta
				dog.squat_ui = squat_progress / 2.5
				if squat_progress >= 2.5:
					_finish_business(true)
			else:
				squat_progress = maxf(0.0, squat_progress - delta * 2.0)
				dog.squat_ui = squat_progress / 2.5
			if poop_state == 1 and urge_timer <= 0.0:
				poop_state = 3
				urge_timer = 1.2
				float_text(dog.global_position, "UH OH", Color(1, 0.6, 0.5))
		2:
			# the owner's chore chain: walk to it, bag it, find a bin.
			# Falls and whirls interrupt; they resume when back on
			# their feet - with the bag, if they already picked it up
			if bag_pending and human.is_available_for_chore():
				if human.carrying_bag:
					human.resume_to_bin(nearest_bin(human.global_position))
				elif business_spot.x < INF:
					human.fetch_poop(business_spot)
		3:
			urge_timer -= delta
			if urge_timer <= 0.0:
				poop_state = 4
				dog.forced_squat(2.5)
		4:
			if dog.squat_t <= 0.0:
				_finish_business(false)
	# rebuilding the HUD strings every frame was wasted work
	hud_t -= delta
	if hud_t <= 0.0:
		hud_t = 0.15
		_update_hud()


func _finish_business(voluntary: bool) -> void:
	poop_state = 2
	dog.squat_ui = 0.0
	squat_progress = 0.0
	business_spot = dog.global_position + Vector2(0, 8)
	if voluntary:
		bones += 5
		feed.say("MUCH BETTER!  +5", EventFeed.Tone.GOOD)
	else:
		feed.say("COULDN'T WAIT...", EventFeed.Tone.BAD)
	bag_pending = true


func nearest_bin(pos: Vector2) -> Vector2:
	var best := bins[0]
	var best_d := 1e12
	for b in bins:
		var d := pos.distance_to(b)
		if d < best_d:
			best_d = d
			best = b
	return best


func on_business_picked() -> void:
	# the poop leaves the sidewalk the moment it is bagged, not at the bin
	business_spot = Vector2(INF, INF)


func toss_bag(from: Vector2, to: Vector2) -> void:
	bag_flights.append({"t": 0.0, "from": from, "to": to})


func on_business_bagged(pos: Vector2) -> void:
	bag_pending = false
	bones += 2
	float_text(pos, "swish! responsible +2", Color(0.8, 1.0, 0.8))
	_update_hud()


const OPENERS := {
	"street": "To the park and back. Mind the bike lanes.",
	"park": "Through the park to the meadow, then home. Mind the pond.",
	"beach": "Along the passeig and back. The sea is right there. So is the bike path.",
	"rain": "Out in it, because you insisted. Mind the drains.",
	"market": "Through the market to the plaza, then home. Everything smells edible.",
	"oldtown": "Up the alleys and back. Narrow, and the cats own the walls.",
	"trail": "Into the woods to the clearing. Everything out here moves.",
	"station": "Across the concourse and back. Nobody here is looking down.",
	"site": "Past the works to the far fence. The cement is wet, and it stays with you.",
	"spook": "Around the Castanyada and home. The sweets on the ground are not for dogs.",
	"scrap": "Through the yard and out. Quietly - things are sleeping.",
	"guell": "Up the terraces and back. The tiles are slippery. Run anyway.",
	"tutorial": "A short one, to get the hang of it. Nothing out here can hurt you.",
}

# The off-leash space at the top of the walk. Every level ended in the same
# fenced municipal dog park, which is a big part of why the walks still felt
# like one walk redressed - you always finished in the same field. The beach
# gets a DOG BEACH instead: sand, and a sea you can actually swim in.
const FREEDOM_KINDS := {
	"beach": "beach", "trail": "clearing", "site": "lot", "scrap": "lot",
	"guell": "clearing",
}
const BEACH_SEA_R := 430.0
const BEACH_GATE_SHORE_X := 230.0


func beach_shore_x(y: float) -> float:
	# Shared dog-beach shoreline: visual fill, animated foam/waves, and
	# gameplay water all derive from this so the headland taper cannot
	# disagree with where she actually gets wet.
	var bend_y := GATE_Y - 300.0
	var gate_y := GATE_Y - 30.0
	if y <= bend_y:
		return BEACH_SEA_R
	if y >= gate_y:
		return BEACH_GATE_SHORE_X
	return lerpf(BEACH_SEA_R, BEACH_GATE_SHORE_X, (y - bend_y) / (gate_y - bend_y))


const MARKABLE_PARK_KINDS := ["post", "shrub", "log", "rock", "driftwood", "tyre"]


func _nearest_markable(pos: Vector2) -> Vector2:
	var best := Vector2(INF, INF)
	var best_d := 42.0
	for h in hydrants:
		var hp: Vector2 = h.pos
		if not marks.has(hp):
			var d := pos.distance_to(hp)
			if d < best_d:
				best_d = d
				best = hp
	for p in poles:
		if not marks.has(p):
			var d := pos.distance_to(p)
			if d < best_d:
				best_d = d
				best = p
	# The off-leash area had nothing markable in it at all - every hydrant and
	# lamppost is back on the street - so the one place a dog is FREE to pee
	# was the one place she could not. Its posts, logs and shrubs count.
	for pp in park_props:
		if not MARKABLE_PARK_KINDS.has(String(pp.kind)):
			continue
		var ppos: Vector2 = pp.pos
		if marks.has(ppos):
			continue
		var pd := pos.distance_to(ppos)
		if pd < best_d:
			best_d = pd
			best = ppos
	return best


func _npc_mark_at(at: Vector2) -> Dictionary:
	for nm in npc_marks:
		if at.distance_to(nm.pos) < 26.0:
			return nm
	return {}


func on_npc_mark(at: Vector2, col: Color, who: String) -> void:
	# another dog has left a message. Cap the list: a long romp with four
	# dogs in it would otherwise grow this without bound.
	if npc_marks.size() > 14:
		npc_marks.remove_at(0)
	npc_marks.append({"pos": at, "col": col, "who": who, "sniffed": false})
	_scent_cache_t = 0.0


func _watch_stall(delta: float) -> void:
	# "the walk finished" is a weak assertion: the bot can crawl, wedge on a
	# prop and still squeak home inside the frame budget. This turns it into
	# "it never got stuck" by requiring real corridor progress in the legs
	# that are supposed to be travelling. The freedom romp is exempt - milling
	# about after a ball is the whole point there.
	# Exempt the legitimately-stationary beats. The watchdog exists to catch
	# being WEDGED, and a scripted pause is not that: while the owner is on
	# the phone they are rooted for the better part of twenty seconds, and on
	# the leash the dog simply cannot travel further than the rope - which
	# read as a stall and would have failed CI for a feature working exactly
	# as designed.
	# Exempt the beats where standing still is the game working, not the bot
	# being wedged. Diagnosing real stalls showed exactly two causes, both
	# legitimate: the owner rooted mid-phone-call (the dog cannot out-travel
	# the rope), and the owner mid-tetherball WHIRL while the dog vaults -
	# both of them orbiting a pole, which is the funniest thing in the game
	# and emphatically not a bug. The watchdog is for wedging.
	if (
		finished
		or phase == "freedom"
		or human.is_on_call()
		or human.is_fallen()
		or human.is_whirling()
		or vault_t > 0.0
		or teeter.active
		or grind.active
	):
		_stall_t = 0.0
		_stall_last_y = dog.global_position.y
		return
	_stall_t += delta
	if _stall_t < STALL_WINDOW:
		return
	_stall_t = 0.0
	var y := dog.global_position.y
	var moved := absf(y - _stall_last_y)
	_stall_last_y = y
	if moved < STALL_MIN_PROGRESS:
		print("AUTOWALK STALL phase=%s y=%.0f moved only %.0fpx in %.0fs" % [phase, y, moved, STALL_WINDOW])


func _auto_drive(_delta: float) -> void:
	# unattended traversal for CI / attract mode: up to the gate, romp on
	# the ball, then back home
	dog.auto = true
	# weave so a head-on pole doesn't stall the dumb driver forever
	var weave := sin(elapsed * 1.6) * 0.6 + clampf((walk_cx - dog.global_position.x) / 300.0, -0.6, 0.6)
	match phase:
		"out":
			dog.auto_move = Vector2(weave, -1.0).normalized()
		"freedom":
			if romp_done:
				dog.auto_move = Vector2(weave, 1.0).normalized()  # head down to leave
			elif is_instance_valid(ball):
				# carry a grabbed ball back to the owner; else chase it
				var goal: Vector2 = human.global_position if ball.is_carried() else ball.global_position
				dog.auto_move = (goal - dog.global_position).normalized()
			else:
				dog.auto_move = Vector2.from_angle(elapsed * 3.0)
		"home":
			dog.auto_move = Vector2(weave, 1.0).normalized()


func _progress(_delta: float) -> void:
	if finished:
		return
	match phase:
		"out":
			# reaching the gate together is the halfway point, not the end
			if dog.global_position.y < GATE_Y + 10.0 and human.global_position.y < GATE_Y + 140.0:
				_enter_freedom()
		"freedom":
			# walk back down through the gate to leave and head home
			if dog.global_position.y > GATE_Y + 40.0:
				_enter_home()
		"home":
			if (
				dog.global_position.y > HOME_Y
				and human.global_position.y > HOME_Y
				and (not auto_walk or elapsed >= AUTOWALK_MIN_FINISH_TIME)
			):
				_finish_walk()


func _enter_freedom() -> void:
	if auto_walk:
		print("AUTOWALK reached FREEDOM at t=%.1f" % elapsed)
	phase = "freedom"
	leash.detached = true
	leash.visible = false
	leash.dynamic_obstacles.clear()
	for pair in get_tree().get_nodes_in_group("pairs"):
		pair.leash.dynamic_obstacles.clear()
	human.park_at(gate_bench)
	_freedom_dirty()
	romp_timer = 30.0
	romp_catches = 0
	romp_done = false
	ball = Node2D.new()
	ball.set_script(load("res://ball.gd"))
	ball.z_index = 10
	ball.position = human.global_position
	add_child(ball)
	if freedom_kind == "beach":
		# into the surf, not across a field - window before the first throw
		ball.setup(self, dog, human, freedom_lo, GATE_Y - 30.0, -90.0, BEACH_SEA_R + 240.0)
	else:
		ball.setup(self, dog, human, freedom_lo, GATE_Y - 30.0)
	# other dogs to romp and say hi to
	for i in range(3):
		var fd := Node2D.new()
		fd.set_script(load("res://freedog.gd"))
		fd.position = Vector2(randf_range(200.0, 1080.0), randf_range(freedom_lo + 40.0, GATE_Y - 60.0))
		fd.z_index = 9
		add_child(fd)
		fd.setup(self, dog, freedom_lo, GATE_Y - 30.0)
	# BRUTUS, the park thief: he turns up on some walks to help himself to
	# whatever you have just earned. Not in the tutorial - a first walk is no
	# place to meet him.
	if not tutorial_mode and randf() < 0.5:
		var rv := Node2D.new()
		rv.set_script(load("res://rival.gd"))
		var rb := _pair_park_bounds()
		rv.position = Vector2(rb.position.x + 60.0, rb.get_center().y)
		rv.z_index = 9
		add_child(rv)
		rv.setup(self, dog, rb)
		float_text(rv.position, "...oh no. Brutus.", Color(1, 0.85, 0.75))
	feed.say("OFF THE LEASH! GO FETCH", EventFeed.Tone.LOUD)


func _spawn_wallcats() -> void:
	# perched temptations up both alley walls (El Gotic). They bolt away
	# from the centre when barked at.
	for spot in wallcat_spots:
		var wc := Node2D.new()
		wc.set_script(load("res://wallcat.gd"))
		wc.position = spot
		wc.z_index = 7
		add_child(wc)
		wc.setup(self, dog, 1.0 if spot.x > walk_cx else -1.0)


func on_wallcat_spooked(pos: Vector2) -> void:
	Sfx.play("hiss")
	mood.bump(Mood.M.BARKY, 0.30)
	wall_cats_spooked += 1
	bones += 2
	combo.add("SHOO", 3)
	float_text(pos + Vector2(0, -20), "scat! +2", Color(0.9, 0.95, 1.0))
	_update_hud()


func _spawn_guards() -> void:
	for spot in guard_posts:
		var gd := Node2D.new()
		gd.set_script(load("res://guarddog.gd"))
		gd.position = spot
		gd.z_index = 7
		add_child(gd)
		gd.setup(self, dog)


func on_guard_woken(pos: Vector2) -> void:
	guards_woken += 1
	mood.bump(Mood.M.SCARED, 0.60)
	bones = maxi(0, bones - 2)
	shake_t = maxf(shake_t, 0.5)
	Sfx.play("bark", 0.6, -3.0)  # a deeper, angrier dog than Millie
	human.halt(1.0)
	float_text(pos + Vector2(0, -26), "WOOF WOOF WOOF -2", Color(1, 0.5, 0.4))
	_update_hud()


func on_phone_noise(pos: Vector2) -> void:
	# the owner's phone going off: the world's worst stealth partner
	for g in get_tree().get_nodes_in_group("guards"):
		g.hear_noise(pos, 250.0)


func _stealth(delta: float) -> void:
	# sweeping cameras: a vision cone that pans back and forth
	var t := Time.get_ticks_msec() / 1000.0
	for c in cameras:
		c.cd = maxf(0.0, float(c.cd) - delta)
		var ang: float = float(c.base) + sin(t * float(c.speed)) * float(c.range)
		var to_dog: Vector2 = dog.global_position - (c.pos as Vector2)
		if c.cd <= 0.0 and to_dog.length() < 190.0 and absf(wrapf(to_dog.angle() - ang, -PI, PI)) < 0.32:
			c.cd = 3.0
			_caught("the camera")
	# laser tripwires: a beam that sweeps up and down its section
	for lz in lasers:
		lz.cd = maxf(0.0, float(lz.cd) - delta)
		var by := lerpf(float(lz.y_lo), float(lz.y_hi), 0.5 + 0.5 * sin(t * float(lz.speed)))
		if lz.cd <= 0.0 and dog.global_position.x > float(lz.x0) and dog.global_position.x < float(lz.x1) and absf(dog.global_position.y - by) < 7.0:
			lz.cd = 3.0
			_caught("the laser")


func _caught(what: String) -> void:
	times_spotted += 1
	bones = maxi(0, bones - 2)
	shake_t = maxf(shake_t, 0.4)
	Sfx.play("crack", 1.4)
	feed.say("THE %s SAW YOU!  -2" % what.to_upper(), EventFeed.Tone.BAD)
	# the racket wakes anyone dozing nearby
	for g in get_tree().get_nodes_in_group("guards"):
		g.hear_noise(dog.global_position, 200.0)
	_update_hud()


func _spawn_challenger() -> void:
	# one combo-challenge giver per walk, lounging on the out leg where you
	# still have room and energy to show off
	if tutorial_mode:
		return
	var giver := Node2D.new()
	giver.set_script(load("res://challenger.gd"))
	giver.position = Vector2(walk_cx + 170.0, -1600.0)
	giver.z_index = 6
	add_child(giver)
	giver.setup(self, dog, 5, 12.0)


func _neighbour_fetch() -> void:
	# a bonus loop for the player, not the attract bot. Spawning a ball
	# rolls the global RNG (the throw target), which would desync the
	# deterministic autowalk traversal - so the CI bot never sees one.
	if auto_walk:
		return
	# keep one neighbour ball in play, thrown by whichever pair is parked;
	# the player can grab it and bring it back for a shared-fetch bonus
	if is_instance_valid(npc_ball):
		if not is_instance_valid(npc_ball_pair) or not npc_ball_pair.is_parked():
			npc_ball.queue_free()
			npc_ball = null
		else:
			return
	for pair in get_tree().get_nodes_in_group("pairs"):
		if pair.is_parked() and is_instance_valid(pair.npc_owner):
			npc_ball = Node2D.new()
			npc_ball.set_script(load("res://ball.gd"))
			npc_ball.z_index = 10
			npc_ball.position = pair.npc_owner.global_position
			add_child(npc_ball)
			npc_ball.setup(self, dog, pair.npc_owner, freedom_lo, GATE_Y - 30.0)
			npc_ball_pair = pair
			float_text(pair.npc_owner.global_position + Vector2(0, -20), "fancy a game?", Color(0.85, 0.95, 1.0))
			return


func _romp(delta: float) -> void:
	if romp_done:
		return
	romp_timer = maxf(0.0, romp_timer - delta)
	if romp_timer <= 0.0:
		romp_done = true
		hud_status = ""
		feed.say("TIME TO HEAD HOME", EventFeed.Tone.PLAIN)


func on_tofu_home(pos: Vector2) -> void:
	if tutorial_mode:
		return
	Sfx.play("star")
	tofu_home = true
	bones += 15
	float_text(pos, "TOFU'S COMING HOME! +15", Color(1, 0.85, 0.7))
	_slowmo()


func on_ball_grabbed() -> void:
	float_text(dog.global_position, "got it!", Color(0.85, 1.0, 0.85))


func on_ball_returned(thrower: Node2D) -> void:
	# returning to your OWN owner is the fetch; returning another owner's
	# ball is a neighbourly bonus
	var mine := thrower == human
	romp_catches += 1
	var reward := 3 if mine else 4
	bones += reward
	Sfx.play("fetch")
	combo.add("FETCH", reward)
	float_text(thrower.global_position, ("good girl! +%d" % reward) if mine else ("shared! +%d" % reward), Color(0.8, 1.0, 0.8))
	if mine and is_instance_valid(thrower):
		human.throw_pose()
	if romp_catches >= romp_target and not romp_done:
		romp_done = true
		bones += 10
		feed.say("GOOD FETCH!  +10", EventFeed.Tone.GOOD)
		_slowmo()


func _enter_home() -> void:
	if auto_walk:
		print("AUTOWALK reached HOME leg at t=%.1f" % elapsed)
	phase = "home"
	leash.detached = false
	leash.resnap()
	leash.visible = true
	human.unpark()
	if is_instance_valid(ball):
		ball.queue_free()
	if is_instance_valid(npc_ball):
		npc_ball.queue_free()
	dog_carrying = false
	for fd in get_tree().get_nodes_in_group("freedogs"):
		fd.queue_free()
	_prepare_pairs_for_home(get_tree().get_nodes_in_group("pairs"))
	# the runaway: Tofu is loose on the way home, to be herded south from
	# hiding spot to hiding spot until she reaches HOME
	if tofu_quest_active and not tofu_home:
		var spots: Array[Vector2] = []
		var n := 7
		for i in range(n):
			var ty := lerpf(GATE_Y + 500.0, HOME_Y + 30.0, float(i) / float(n - 1))
			var tx := walk_cx + (walk_half * 0.6) * (1.0 if i % 2 == 0 else -1.0)
			if i == n - 1:
				tx = walk_cx
			spots.append(Vector2(tx, ty))
		var tf := Node2D.new()
		tf.set_script(load("res://tofu.gd"))
		tf.z_index = 9
		add_child(tf)
		tf.setup(self, dog, spots)
		float_text(spots[0], "Tofu!? she got out again - get her home!", Color(1, 0.85, 0.7))
	if chase_active:
		var owner_flees := chase_kind == "bolt" or chase_kind == "both"
		chase_sweeper = Node2D.new()
		chase_sweeper.set_script(load("res://sweeper.gd"))
		chase_sweeper.z_index = 8
		chase_sweeper.kind = chase_kind
		add_child(chase_sweeper)
		var spd := CHASE_SPEED
		if chase_kind == "bolt":
			spd = CHASE_SPEED_BOLT
		elif chase_kind == "both":
			spd = CHASE_SPEED_BOTH
		# --shot-sweeper starts it right on your heels instead of a corridor
		# away, so the machine can be photographed and its art reviewed. It
		# spends the rest of the chase behind the camera, which is exactly how
		# it went unlooked-at long enough to end up as a wall of rectangles.
		var gap: float = 250.0 if "--shot-sweeper" in OS.get_cmdline_user_args() else CHASE_START_GAP
		chase_sweeper.setup(self, dog.global_position.y - gap, walk_cx, walk_half, spd)
		shake_t = 1.0
		if owner_flees:
			human.panic = true
		if chase_kind == "both":
			float_text(human.global_position, "FIRE ENGINE!  GO GO GO!", Color(1, 0.55, 0.25))
		elif chase_kind == "bolt":
			float_text(human.global_position, "AAH!  the owner BOLTED!", Color(1, 0.6, 0.3))
		else:
			feed.say("STREET SWEEPER! RUN!", EventFeed.Tone.BAD)
	else:
		feed.say("LET'S GO HOME", EventFeed.Tone.PLAIN)


func _chase(delta: float) -> void:
	if chase_sweeper == null:
		return
	chase_sweeper.advance(delta)
	chase_sweeper.global_position = Vector2(walk_cx, chase_sweeper.front_y)
	chase_sweeper.queue_redraw()
	# a low rumble the closer it gets to the dog
	var gap: float = chase_sweeper.gap_to(dog.global_position)
	if gap < 260.0:
		shake_t = maxf(shake_t, 0.25)
	if auto_walk:
		return  # the attract/CI bot carries an unsweepable dog
	if chase_sweeper.caught(human.global_position):
		if chase_kind == "sweeper":
			_death("THE SWEEPER GOT YOUR HUMAN\n\nThey never once looked up from the phone.\nYou did try to tell them.")
		else:
			_death("THEY GOT YOUR HUMAN\n\nYou pulled. You barked. It was not enough.")
	elif chase_sweeper.caught(dog.global_position):
		if chase_kind == "sweeper":
			_death("YOU WENT INTO THE BRUSHES\n\nYou came out suspiciously clean.\nThe walk did not come out at all.")
		else:
			_death("NOBODY WAITED FOR YOU\n\nYou snagged, the leash went tight, and\nthey kept walking. They always keep walking.")


func _finish_walk() -> void:
	if dog.global_position.y > HOME_Y and human.global_position.y > HOME_Y:
		if tutorial_mode:
			_finish_tutorial_walk()
			return
		finished = true
		if auto_walk:
			print("AUTOWALK FINISHED the whole walk at t=%.1f" % elapsed)
		frozen = true
		dim.visible = true
		msg_label.visible = true
		# credit any goal still satisfied at the finish (catches the
		# "maintain" goals like unscratched phone / clean paws)
		for q in active_quests:
			if not run_goals_hit.has(q.id) and int(q.fn.call()) >= int(q.target):
				_credit_goal(q)
		var run_done := run_goals_hit.size()
		var total := active_quests.size()
		var rows: Array = _results_rows()
		var lifetime: int = run_done if Game.daily else Game.goals_count(lvl)
		# total == 0 made this TRUE, which is how a walk with no goal list
		# banked a PERFECT for The Boulevard. The tutorial no longer reaches
		# this path at all, but the trap should not be left armed.
		var perfect := total > 0 and run_done >= total
		var rating := ""
		if run_done == 0:
			rating = "...well. A dog, anyway."
		elif perfect:
			rating = "PERFECT WALK - every goal in one go"
		var rec: Dictionary = Game.record_result("daily" if Game.daily else lvl, bones, elapsed, perfect)
		var lines: Array = []
		var star_gain: int = Game.stars(lvl) - run_pre_level_stars
		var head := ""
		if star_gain > 0 and not Game.daily:
			head += "+%d STAR%s   " % [star_gain, "" if star_gain == 1 else "S"]
		if rec.bones_record:
			head += "NEW BONES RECORD   "
		if rec.time_record:
			head += "BEST TIME"
		if head != "":
			lines.append(head.strip_edges())
		lines.append("%d/%d goals here    %d stars in all    %d bones banked"
			% [lifetime, total, Game.total_stars(), Game.total_bones])
		if combo.best_mult >= 2:
			lines.append("best combo x%d    style %d" % [combo.best_mult, combo.run_style])
		if overmarks > 0:
			lines.append("%d spot%s over-marked. They will know."
				% [overmarks, "" if overmarks == 1 else "s"])
		if not Game.daily:
			for other in Game.LEVELS:
				if Game.gate_crossed(run_pre_total_stars, other):
					lines.append("NEW WALK UNLOCKED: %s" % Game.LEVEL_NAMES[other])
		if Game.daily:
			_build_daily_card(run_done, total, rec)
		else:
			results = {
				"title": "VERY GOOD DOG." if perfect else "GOOD DOG.", "stars": Game.stars(lvl),
				"rating": rating,
				"rows": rows, "bones": bones, "phone": phone_hp, "time": int(elapsed),
				"goal_bones": run_done * 5, "lines": lines,
				"prompt": "press  %s  for another walk" % _kb_or_pad("R", "Start"),
			}
			msg_label.visible = false
			results_card.visible = true
			# the in-walk HUD would otherwise sit on top of the card
			goals_card.visible = false
			panel.visible = false


func _finish_tutorial_walk() -> void:
	finished = true
	frozen = true
	dim.visible = true
	msg_label.visible = false
	results = {
		"title": "GOOD DOG.",
		"stars": 0,
		"rating": "You know the ropes.",
		"rows": [],
		"bones": bones,
		"phone": phone_hp,
		"time": int(elapsed),
		"goal_bones": 0,
		"lines": [
			"%d practice bones - not banked" % bones,
			"Lessons complete. The real walks are waiting.",
		],
		"prompt": "press  %s  for walk select" % _kb_or_pad("R", "Start"),
	}
	results_card.visible = true
	goals_card.visible = false
	panel.visible = false
	tut_label.visible = false
	tut_hint.visible = false


func _results_rows() -> Array:
	var rows: Array = []
	for q in active_quests:
		var hit: bool = run_goals_hit.has(q.id)
		var had: bool = (not Game.daily) and Game.goal_done(lvl, q.id) and not hit
		var target := int(q.target)
		var got: int = mini(int(q.fn.call()), target)
		var st: int = UiIcons.Check.OPEN
		if hit:
			st = UiIcons.Check.DONE_NOW
		elif had:
			st = UiIcons.Check.DONE_BEFORE
		elif got > 0:
			st = UiIcons.Check.PARTIAL
		rows.append({"text": _quest_text(q), "state": st, "got": got, "target": target})
	return rows


func results_data() -> Dictionary:
	return results


func _build_daily_card(run_done: int, total: int, rec: Dictionary) -> void:
	# a compact, screenshot-friendly summary of today's shared walk, with a
	# one-line share text the player can copy to the clipboard
	var d := Time.get_date_dict_from_system()
	var date_str := "%04d-%02d-%02d" % [d.year, d.month, d.day]
	var stars_n := Game._milestone_stars(run_done)
	var weather_bit: String = String(Game.WEATHER_NAMES[Game.weather]).to_lower()
	var when_bit := "night" if Game.night else "day"
	var combo_bit := "  combo x%d" % combo.best_mult if combo.best_mult >= 2 else ""
	daily_share = "Path of Leash Resistance - Daily %s\n%s, %s, %s\n%s  %d/%d goals  %d bones  %ds%s" % [
		date_str, Game.LEVEL_NAMES[lvl], weather_bit, when_bit,
		Game.star_str(stars_n), run_done, total, bones, int(elapsed), combo_bit]
	var best_line := "NEW DAILY BEST!\n\n" if rec.bones_record else ""
	daily_copied = false
	msg_label.text = "TODAY'S WALK\n\n%s\n\n%sPress %s to copy & share\nPress %s for another go" % [
		daily_share, best_line, _kb_or_pad("C", "Y"), _kb_or_pad("R", "Start")]


func on_bark(pos: Vector2) -> void:
	barks_done += 1
	mood.bump(Mood.M.BARKY, 0.22)
	Sfx.play("bark")
	if human.global_position.distance_to(pos) < 170.0:
		human.halt(0.8)
	for s in get_tree().get_nodes_in_group("squirrels"):
		if s.global_position.distance_to(pos) < 200.0:
			s.scare()
	for p in get_tree().get_nodes_in_group("pigeons"):
		if p.global_position.distance_to(pos) < 200.0:
			p.scare()
	for rv in get_tree().get_nodes_in_group("rivals"):
		if rv.global_position.distance_to(pos) < 132.0:
			rv.scare()
	for wc in get_tree().get_nodes_in_group("wallcats"):
		if wc.global_position.distance_to(pos) < 150.0:
			wc.scare()
	# in the scrapyard, YOUR bark is noise too
	for g in get_tree().get_nodes_in_group("guards"):
		g.hear_noise(pos, 230.0)


func set_leash_target(v: float) -> void:
	leash_target = clampf(v, 150.0, 440.0)


func _nearest_pole_to(pos: Vector2, max_d: float) -> Vector2:
	var best := Vector2(INF, INF)
	var best_d := max_d
	for p in poles:
		var d := pos.distance_to(p)
		if d < best_d:
			best_d = d
			best = p
	return best


func nearest_bench(pos: Vector2):
	var best = null
	var best_d := 380.0
	for b in benches:
		var d := pos.distance_to(b)
		if d < best_d:
			best_d = d
			best = b
	return best


func on_stumble_save(pos: Vector2) -> void:
	for b in get_tree().get_nodes_in_group("bikes"):
		if b.global_position.distance_to(pos) < 170.0:
			streak += 1
			saves_done += 1
			bones += streak
			Sfx.play("save", 1.0 + 0.06 * streak)
			combo.add("SAVE", 5)
			float_text(pos + Vector2(0, -30), "NICE SAVE +%d" % streak, Color(0.7, 1.0, 0.75))
			_slowmo()
			_update_hud()
			return


func _slowmo() -> void:
	Engine.time_scale = 0.3
	var t := get_tree().create_timer(0.35, true, false, true)
	t.timeout.connect(func() -> void: Engine.time_scale = 1.0)


func crack_phone(pos: Vector2) -> void:
	if auto_walk:
		return  # the attract/CI bot carries an unbreakable phone
	Sfx.play("crack", 1.0, -2.0)
	phone_hp -= 1
	streak = 0
	shake_t = 1.0
	_update_hud()
	float_text(pos, "PHONE CRACKED", Color(1, 0.45, 0.4))
	if phone_hp <= 0:
		frozen = true
		dim.visible = true
		msg_label.visible = true
		msg_label.text = "THE PHONE IS SHATTERED\n\nThe human is inconsolable, and blaming\nsomeone who cannot answer back.\n\nPress %s to try again" % _kb_or_pad("R", "Start")


func close_call(pos: Vector2) -> void:
	bones += 1
	close_calls += 1
	Sfx.play("save", 1.15)
	combo.add("CLOSE", 2)
	float_text(pos, "close call +1", Color(0.75, 0.9, 1.0))
	_update_hud()


func float_text(pos: Vector2, text: String, color: Color = Color.WHITE) -> void:
	var l := Label.new()
	l.text = text
	l.z_index = 100
	l.add_theme_font_size_override("font_size", 20)
	l.add_theme_color_override("font_color", color)
	add_child(l)
	l.position = pos + Vector2(-40, -56)
	var tw := create_tween()
	tw.tween_property(l, "position:y", l.position.y - 44.0, 0.9)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.9)
	tw.tween_callback(l.queue_free)


func _draw() -> void:
	# --drawcost prints what the world costs to draw. Smooth beats pretty, and
	# every visual pass since v1.31 has been signed off with this number rather
	# than a guess - guessing is how the edge treatment quietly grew to over
	# half the frame.
	var _t0 := Time.get_ticks_usec() if _draw_cost_on else 0
	_draw_world()
	if _draw_cost_on:
		_draw_us += Time.get_ticks_usec() - _t0
		_draw_n += 1
		if _draw_n >= 60:
			print("DRAWCOST %s %dus avg over %d draws" % [lvl, _draw_us / _draw_n, _draw_n])
			_draw_us = 0
			_draw_n = 0


func _draw_world() -> void:
	var top := GATE_Y - 800.0
	var bottom := START_Y + 320.0
	# The corridor's cross-section stops at the gate. It used to be painted all
	# the way to the top of the level, which was invisible while the off-leash
	# space was drawn afterwards in the same pass - but that space lives on its
	# own cached canvas now, so anything painted here covers it. (This is how
	# the dog beach turned green, and then sand-coloured.)
	var ctop := GATE_Y - 40.0
	# cull to the camera: redrawing 5500px of detail lines every frame
	# was the browser stutter
	var vt: float = cam.position.y - 440.0
	var vb: float = cam.position.y + 440.0
	if lvl == "beach":
		# Passeig Maritim, west to east: sea, sand, boardwalk, bike
		# path, pavement, cafe strip, buildings
		# The sea, and it is a Mediterranean one: turquoise, not the grey-blue
		# it was. A shallower band nearer the shore, because that is where the
		# colour actually comes from - sand under clear water.
		draw_rect(Rect2(-400, ctop, 630, bottom - ctop), Color(0.13, 0.47, 0.60))
		draw_rect(Rect2(120, ctop, 110, bottom - ctop), Color(0.26, 0.66, 0.70))
		var wt := Time.get_ticks_msec() / 1000.0
		var fy := top + 40.0
		while fy < bottom:
			if fy > vt and fy < vb:
				draw_line(Vector2(72 + sin(fy * 0.011 + wt * 1.5) * 9.0, fy), Vector2(84 + sin(fy * 0.013 + wt * 1.5) * 9.0, fy + 70.0), Color(1, 1, 1, 0.25), 3.0)
			fy += 150.0
		draw_rect(Rect2(230, ctop, 150, bottom - ctop), Color(0.88, 0.81, 0.64))
		# THE TIMBER DECK, nearest the sand. These two strips were the wrong way
		# round: the game had pale planks against the beach and a dark red strip
		# inland, where the promenade actually runs a dark reddish-brown WOODEN
		# deck along the sand edge and a pale concrete path with a dashed line
		# behind it. Swapped, so the boardwalk reads as boards.
		draw_rect(Rect2(380, ctop, 110, bottom - ctop), Color(0.46, 0.26, 0.21))
		# start at the top of the visible window, not the top of the level
		var py := minf(START_Y + 200.0, vb + 22.0 - fmod(vb, 22.0))
		while py > GATE_Y and py > vt - 22.0:
			if py < vb and py > vt:
				# plank ends, running across the walk the way decking is laid
				draw_line(Vector2(380, py), Vector2(490, py), Color(0.34, 0.19, 0.15), 2.0)
			py -= 22.0
		# the pale concrete path, with the dashed line down the middle of it
		draw_rect(Rect2(490, ctop, 80, bottom - ctop), Color(0.82, 0.79, 0.73))
		var ddy := minf(START_Y + 200.0, vb + 64.0 - fmod(vb, 64.0))
		while ddy > GATE_Y and ddy > vt - 64.0:
			if ddy < vb and ddy > vt:
				draw_line(Vector2(530, ddy), Vector2(530, ddy - 26.0), Color(0.97, 0.96, 0.93, 0.8), 3.0)
			ddy -= 64.0
		draw_rect(Rect2(570, ctop, 410, bottom - ctop), Color(0.79, 0.76, 0.7))
		var sy := minf(START_Y + 200.0, vb + 150.0 - fmod(vb, 150.0))
		while sy > GATE_Y and sy > vt - 150.0:
			if sy < vb and sy > vt:
				draw_line(Vector2(560, sy), Vector2(980, sy), Color(0.71, 0.68, 0.62), 2.0)
			sy -= 150.0
		draw_rect(Rect2(980, ctop, 200, bottom - ctop), Color(0.76, 0.72, 0.65))
		# The building strip was at x>=1180, and the camera never sees past
		# x=1140 (zoom 1.28 on a fixed x=640) - so the whole landward side of
		# this walk was being drawn where nobody could look at it. Brought
		# inside the frame.
		draw_rect(Rect2(1120, ctop, 580, bottom - ctop), Color(0.35, 0.33, 0.31))
		_draw_seafront_works(vt, vb)
		# SQUARE CUT-OUTS in the paving, one under each palm. The promenade's
		# trees are not planted in a verge, they are set into the concrete in
		# orderly openings with a kerb round them, and that grid of squares
		# down the walk is a good part of what the place looks like.
		for ps: Vector2 in palm_spots:
			if ps.y < vt - 60.0 or ps.y > vb + 60.0:
				continue
			var cut := Rect2(ps.x - 27.0, ps.y - 27.0, 54.0, 54.0)
			draw_rect(cut, Color(0.62, 0.58, 0.50))          # the kerb
			draw_rect(cut.grow(-5.0), Color(0.40, 0.34, 0.26))  # the soil in it
			draw_rect(cut, Color(0.34, 0.31, 0.27, 0.55), false, 2.0)
		draw_line(Vector2(380, bottom), Vector2(380, GATE_Y), Color(0.55, 0.45, 0.32), 3.0)
		draw_line(Vector2(490, bottom), Vector2(490, GATE_Y), COL_SEAM, 2.0)
		draw_line(Vector2(570, bottom), Vector2(570, GATE_Y), COL_SEAM, 2.0)
		draw_line(Vector2(980, bottom), Vector2(980, GATE_Y), COL_SEAM, 2.0)
		for t in tufts:
			if t.y > vt and t.y < vb and t.x > 110.0 and (t.x < 330.0 or t.x > 1000.0) and t.x < 1170.0:
				draw_circle(t, 4.0, Color(0.78, 0.7, 0.54))
		for twd in towels:
			var r: Rect2 = twd.rect
			draw_rect(r, twd.col)
			draw_rect(r, Color(1, 1, 1, 0.25), false, 2.0)
			if twd.bather:
				draw_circle(r.get_center() + Vector2(0, -20), 6.0, Color(0.75, 0.6, 0.45))
				draw_rect(Rect2(r.get_center().x - 7, r.get_center().y - 12, 14, 26), Color(0.55, 0.35, 0.45))
	else:
		var grass := COL_GRASS if lvl == "street" else Color(0.3, 0.45, 0.28)
		var walkway := Color(0.62, 0.55, 0.42)
		if lvl == "street":
			walkway = COL_SIDEWALK
		elif lvl == "market":
			grass = COL_GRASS
			walkway = Color(0.76, 0.73, 0.66)
		draw_rect(Rect2(-400, ctop, 2100, bottom - ctop), grass)
		for t in tufts:
			if t.y > vt and t.y < vb:
				draw_circle(t, 5.0, COL_GRASS_DARK)
		# the walkway: sidewalk downtown, packed dirt in the park
		if edge_nodes.is_empty():
			# A straight corridor, which is every level until one is authored a
			# bend: one rect and two lines, exactly as before. Kept as its own
			# branch rather than folded into the ribbon so that straight levels
			# pay nothing at all for the ability to curve.
			draw_rect(Rect2(sw_l, GATE_Y - 40.0, sw_r - sw_l, bottom - GATE_Y), walkway)
			_draw_paving(vt, vb, walkway)
			draw_line(Vector2(sw_l, bottom), Vector2(sw_l, GATE_Y), COL_SEAM, 3.0)
			draw_line(Vector2(sw_r, bottom), Vector2(sw_r, GATE_Y), COL_SEAM, 3.0)
		else:
			_draw_walk_ribbon(vt, vb, bottom, walkway)
	# (what lies beyond the gate is drawn by freedomlayer, which owns
	# everything up there - drawing it here put a green field on top of the
	# cached canvas, which is how the dog beach briefly turned into a lawn)
	# Trees, read from above: two flat green discs said "blob", not "tree".
	# A canopy needs a cast shadow to sit in the world, clustered lobes to
	# break the outline, a lit side, and a hint of trunk and limbs showing
	# through the gaps.
	if lvl == "street":
		# parallel bike lane + far shoulder
		draw_rect(Rect2(BLANE_L, GATE_Y - 40.0, BLANE_R - BLANE_L, bottom - GATE_Y), Color(0.4, 0.31, 0.29))
		draw_rect(Rect2(BLANE_R, GATE_Y - 40.0, SHOULDER_R - BLANE_R, bottom - GATE_Y), COL_SIDEWALK)
		var dy := minf(START_Y + 200.0, vb + 64.0 - fmod(vb, 64.0))
		while dy > GATE_Y and dy > vt - 64.0:
			if dy < vb and dy > vt:
				draw_line(Vector2((BLANE_L + BLANE_R) / 2.0, dy), Vector2((BLANE_L + BLANE_R) / 2.0, dy - 26.0), Color(0.85, 0.82, 0.75, 0.5), 2.0)
			dy -= 64.0
		var gy := START_Y - 100.0
		while gy > GATE_Y:
			if gy < vb and gy > vt:
				var cxx := (BLANE_L + BLANE_R) / 2.0 - 14.0
				draw_circle(Vector2(cxx - 7, gy), 4.0, Color(1, 1, 1, 0.3))
				draw_circle(Vector2(cxx + 7, gy), 4.0, Color(1, 1, 1, 0.3))
				draw_line(Vector2(cxx - 7, gy), Vector2(cxx + 7, gy - 6), Color(1, 1, 1, 0.3), 2.0)
			gy -= 600.0
		draw_line(Vector2(BLANE_L, bottom), Vector2(BLANE_L, GATE_Y), COL_SEAM, 3.0)
		draw_line(Vector2(BLANE_R, bottom), Vector2(BLANE_R, GATE_Y), COL_SEAM, 2.0)
		draw_line(Vector2(SHOULDER_R, bottom), Vector2(SHOULDER_R, GATE_Y), COL_SEAM, 3.0)
	if pond.size.x > 0.0:
		# THE POND. It was a rectangle with a grey rim, which read as a
		# municipal swimming pool rather than as water in a park - a hard
		# straight edge is the one thing a pond never has. Drawn as two blobs
		# now: a muddy bank and the water inside it, both from the same
		# primitive as the puddles and the wet cement.
		#
		# The Rect2 is kept for everything else that asks about the pond - the
		# swim test, the keep-out margins that stop props being placed in it,
		# the prize in the middle - because being slightly generous about where
		# the water is, is the right way round for all of those.
		var pc := pond.get_center()
		var bank := {"y": pc.y, "at": 0.5, "rx": pond.size.x * 0.5,
			"ry": pond.size.y * 0.5, "seed": 2.7}
		# path-relative x would drag the pond sideways on a bend; the park does
		# not bend and the pond is authored against the level, so pin it
		# muddy bank, then the water inside it, from one outline
		_draw_pinned_patch(bank, pc, Color(0.40, 0.36, 0.28), 1.08)
		_draw_pinned_patch(bank, pc, Color(0.31, 0.44, 0.52), 0.94)
		var wt := Time.get_ticks_msec() / 1000.0
		for i in range(4):
			var wy := pond.position.y + 70.0 + i * 105.0
			draw_arc(Vector2(pc.x + sin(wt * 0.7 + i) * 40.0, wy), 26.0, PI * 0.15, PI * 0.85, 10, Color(1, 1, 1, 0.14), 2.0)
		var px := pond.end.x + 8.0
		var py := pond.position.y
		while py < pond.end.y:
			draw_line(Vector2(px, py), Vector2(sw_r, py), Color(0.5, 0.4, 0.28), 5.0)
			py += 16.0
		draw_line(Vector2(px, pond.position.y), Vector2(px, pond.end.y), Color(0.36, 0.28, 0.2), 4.0)
	# bike lanes crossing the sidewalk
	for i in range(lane_ys.size()):
		var ly: float = lane_ys[i]
		draw_rect(Rect2(-400, ly - LANE_HALF, 2100, LANE_HALF * 2.0), COL_ROAD)
		var x := -380.0
		while x < 1700.0:
			draw_line(Vector2(x, ly), Vector2(x + 30.0, ly), COL_STRIPE, 3.0)
			x += 70.0
		draw_line(Vector2(-400, ly - LANE_HALF), Vector2(1700, ly - LANE_HALF), COL_STRIPE, 2.0)
		draw_line(Vector2(-400, ly + LANE_HALF), Vector2(1700, ly + LANE_HALF), COL_STRIPE, 2.0)
		var ls: Dictionary = lane_state[i]
		if ls.phase == 1 and fmod(Time.get_ticks_msec() / 150.0, 2.0) < 1.0:
			var wx := 40.0 if ls.dir > 0 else 1240.0
			draw_circle(Vector2(wx, ly), 16.0, Color(0.95, 0.8, 0.25))
			draw_rect(Rect2(wx - 2.0, ly - 9.0, 4.0, 10.0), Color(0.15, 0.15, 0.15))
			draw_circle(Vector2(wx, ly + 6.0), 2.2, Color(0.15, 0.15, 0.15))
	# manholes - open for street work; the cones are real nodes now.
	# This one has to read as A HOLE from a glance at speed, because falling
	# in ends the walk: hence the lifted cover leaning beside it, the lit
	# near rim, and the shaft going properly dark toward the far side.
	for m in manholes:
		if m.y < vt - 50.0 or m.y > vb + 50.0:
			continue
		# the cover, lifted off and propped against the kerb side
		var cv := m + LIGHT * 30.0
		contact_shadow(self, cv, 15.0, 5.0, 0.22)
		draw_circle(cv, 14.0, Color(0.30, 0.30, 0.33))
		draw_circle(cv, 11.0, Color(0.37, 0.37, 0.40))
		for gi in range(3):
			draw_line(cv + Vector2(-9.0, -6.0 + float(gi) * 6.0), cv + Vector2(9.0, -6.0 + float(gi) * 6.0),
				Color(0.26, 0.26, 0.29), 1.6)
		# the collar of brickwork it is set into
		draw_circle(m, 25.0, Color(0.34, 0.32, 0.31))
		draw_circle(m, 22.0, Color(0.24, 0.23, 0.23))
		# the shaft: dark, and darker away from the light
		draw_circle(m, 19.0, Color(0.10, 0.10, 0.12))
		draw_circle(m + LIGHT * 5.0, 15.0, Color(0.05, 0.05, 0.07))
		# the lit rim on the light side, which is what makes it a hole and
		# not a disc
		draw_arc(m, 19.5, PI * 0.95, PI * 1.95, 16, Color(0.55, 0.53, 0.50), 2.4)
		draw_arc(m, 19.5, PI * 0.0, PI * 0.6, 12, Color(0.16, 0.16, 0.18), 2.0)
		# rungs going down, just visible
		for ri in range(2):
			draw_line(m + Vector2(-6.0, 2.0 + float(ri) * 7.0), m + Vector2(6.0, 2.0 + float(ri) * 7.0),
				Color(0.22, 0.21, 0.20), 2.0)
	# hydrants: cast iron, and the most important object in the world if you
	# are a dog. Base flange, barrel, bonnet, two side outlets and a chain -
	# it was two flat circles and read as a red dot.
	for h in hydrants:
		var hp: Vector2 = h.pos
		if hp.y < vt - 40.0 or hp.y > vb + 40.0:
			continue
		var c := Color(0.45, 0.4, 0.38) if h.done else Color(0.68, 0.23, 0.18)
		cast_shadow(self, hp, 8.0, 26.0)
		# the flange it is bolted down with
		draw_circle(hp + Vector2(0, 3), 12.0, c.darkened(0.45))
		draw_circle(hp + Vector2(0, 3), 9.5, c.darkened(0.3))
		# side outlets, one either side, with their caps
		for so: float in [-1.0, 1.0]:
			var op := hp + Vector2(10.0 * so, -1.0)
			draw_line(hp, op, c.darkened(0.15), 5.0)
			draw_circle(op, 3.6, c.lightened(0.08))
			draw_circle(op, 1.8, c.darkened(0.35))
		# the barrel, lit from the upper left
		draw_circle(hp, 8.5, c)
		draw_circle(hp + Vector2(-2.5, -2.5), 5.0, c.lightened(0.16))
		# the bonnet on top, and its little cap nut
		draw_circle(hp + Vector2(0, -7), 5.6, c.darkened(0.12))
		draw_circle(hp + Vector2(-1.5, -8.5), 3.0, c.lightened(0.22))
		draw_circle(hp + Vector2(0, -11), 2.0, Color(0.85, 0.8, 0.7, 0.9))
		# the chain, hanging off to one side
		for ci in range(3):
			draw_circle(hp + Vector2(7.0 + float(ci) * 2.6, 6.0 + float(ci) * 1.6), 1.5,
				Color(0.62, 0.6, 0.58))
		if not h.done and h.progress > 0.0:
			draw_arc(hp, 17.0, -PI / 2.0, -PI / 2.0 + TAU * h.progress / 0.8, 20, Color(1, 0.95, 0.7), 3.0)
	# the dropped snack. A brown circle could have been anything; this is a
	# half-eaten kebab lying in its paper, which is unmistakably Barcelona
	# pavement and unmistakably worth eating off it.
	for k in kebabs:
		if k.eaten or k.pos.y < vt - 30.0 or k.pos.y > vb + 30.0:
			continue
		var kp: Vector2 = k.pos
		contact_shadow(self, kp, 9.0, 4.0, 0.20)
		# the paper wrapper, screwed open
		draw_colored_polygon(
			PackedVector2Array([
				kp + Vector2(-11, 3), kp + Vector2(-6, -8), kp + Vector2(7, -7),
				kp + Vector2(11, 5), kp + Vector2(0, 9),
			]), Color(0.90, 0.87, 0.79))
		draw_colored_polygon(
			PackedVector2Array([
				kp + Vector2(-7, 2), kp + Vector2(-3, -5), kp + Vector2(5, -4),
				kp + Vector2(7, 3), kp + Vector2(0, 6),
			]), Color(0.80, 0.77, 0.70))
		# the meat, and a sad shred of salad nobody wants
		draw_circle(kp + Vector2(-1, -1), 5.2, Color(0.62, 0.40, 0.22))
		draw_circle(kp + Vector2(-2.5, -2.5), 3.0, Color(0.74, 0.50, 0.28))
		draw_circle(kp + Vector2(3, 2), 2.4, Color(0.55, 0.34, 0.19))
		draw_line(kp + Vector2(-5, 4), kp + Vector2(1, 5), Color(0.45, 0.62, 0.32), 2.0)
	# candy: shiny wrapped sweets - tempting, forbidden, faintly glinting
	var candy_cols := [Color(0.85, 0.25, 0.35), Color(0.3, 0.5, 0.85), Color(0.55, 0.35, 0.7)]
	for ci in range(candy.size()):
		var c: Dictionary = candy[ci]
		if c.eaten or c.pos.y < vt - 20.0 or c.pos.y > vb + 20.0:
			continue
		var cc: Color = candy_cols[ci % candy_cols.size()]
		var gl := 0.6 + 0.4 * sin(prize_glow + ci)
		draw_circle(c.pos, 6.0, cc)
		draw_line(c.pos + Vector2(-6, -3), c.pos + Vector2(-9, -5), cc, 2.0)  # wrapper twists
		draw_line(c.pos + Vector2(-6, 3), c.pos + Vector2(-9, 5), cc, 2.0)
		draw_line(c.pos + Vector2(6, -3), c.pos + Vector2(9, -5), cc, 2.0)
		draw_line(c.pos + Vector2(6, 3), c.pos + Vector2(9, 5), cc, 2.0)
		draw_circle(c.pos + Vector2(-2, -2), 1.6, Color(1, 1, 1, 0.4 + gl * 0.4))
	# the hazardous prize: a glinting collectible with a beckoning ring
	if not prize_taken and prize_pos.x < INF and prize_pos.y > vt - 40.0 and prize_pos.y < vb + 40.0:
		var pg := 0.5 + 0.5 * sin(prize_glow)
		draw_arc(prize_pos, 16.0 + pg * 5.0, 0, TAU, 20, Color(1.0, 0.85, 0.3, 0.35 + pg * 0.3), 2.0)
		draw_circle(prize_pos, 7.0, Color(0.95, 0.8, 0.35))
		draw_circle(prize_pos + Vector2(-2, -2), 2.5, Color(1, 0.97, 0.85))
		draw_string(font, prize_pos + Vector2(-30, -22), "!", HORIZONTAL_ALIGNMENT_CENTER, 60, 18, Color(1, 0.9, 0.5))
	# carry mission: the parcel where it waits, the drop-off marker, and
	# the parcel riding in Millie's mouth while she totes it
	if carry_pickup.x < INF and carry_state < 2:
		if carry_state == 0:
			draw_rect(Rect2(carry_pickup.x - 8.0, carry_pickup.y - 5.0, 16.0, 10.0), Color(0.7, 0.6, 0.4))
			draw_line(carry_pickup + Vector2(-8, -1), carry_pickup + Vector2(8, -1), Color(0.4, 0.32, 0.2), 1.0)
		# the drop-off: a doormat with a downward chevron
		var dp := 0.5 + 0.5 * sin(prize_glow)
		draw_rect(Rect2(carry_drop.x - 16.0, carry_drop.y - 10.0, 32.0, 20.0), Color(0.35, 0.4, 0.5, 0.4 + dp * 0.25))
		draw_rect(Rect2(carry_drop.x - 16.0, carry_drop.y - 10.0, 32.0, 20.0), Color(0.7, 0.8, 0.95, 0.5), false, 2.0)
		draw_string(font, carry_drop + Vector2(-40, -16), "DROP", HORIZONTAL_ALIGNMENT_CENTER, 80, 13, Color(0.8, 0.9, 1.0, 0.8))
	if carry_state == 1:
		var mp: Vector2 = dog.global_position + dog.facing * 20.0
		draw_rect(Rect2(mp.x - 7.0, mp.y - 4.0, 14.0, 8.0), Color(0.7, 0.6, 0.4))
	# lampposts downtown, trees in the park, palms by the sea
	# (same physics, different soul)
	# night lighting: warm pools spilling from the lampposts. Layered
	# concentric alpha fakes a falloff gradient cheaply, and because the
	# lamps never move the 30fps world redraw is plenty.
	if Game.night:
		var lamp_t := Time.get_ticks_msec() / 1000.0
		for i in range(deco_pole_count):
			var lp := poles[i]
			if lp.y < vt - 190.0 or lp.y > vb + 190.0:
				continue
			if lp.x < sw_l - 90.0 or lp.x > sw_r + 90.0:
				continue
			# a faint flicker keeps the light from looking like a decal
			var flick := 0.94 + 0.06 * sin(lamp_t * 2.3 + lp.y * 0.01)
			# many thin rings: a smooth falloff instead of visible banding
			for ring in range(11):
				var f := float(ring) / 10.0
				var rr := lerpf(185.0, 26.0, f)
				var aa := (0.012 + f * f * 0.055) * flick
				draw_circle(lp + Vector2(0, 16), rr, Color(1.0, 0.86, 0.55, aa))
			draw_circle(lp + Vector2(0, -22), 7.0, Color(1.0, 0.94, 0.72, 0.9 * flick))
	for i in range(deco_pole_count):
		var p := poles[i]
		if p.y < vt - 60.0 or p.y > vb + 60.0:
			continue
		if lvl == "park":
			_draw_broadleaf(self, p, 1.0)
		elif lvl == "beach":
			_draw_palm(self, p)
		elif p.x > sw_l + 60.0 and p.x < sw_r - 60.0:
			# mid-walkway poles are street trees in grates - that is WHY
			# they stand in the middle of a sidewalk
			cast_shadow(self, p, 20.0, 40.0, 0.16)
			draw_circle(p, 19.0, Color(0.26, 0.24, 0.22))          # the pit
			draw_rect(Rect2(p.x - 16, p.y - 16, 32, 32), Color(0.34, 0.34, 0.37))
			for gi in range(4):
				var gy := p.y - 12.0 + float(gi) * 8.0
				draw_line(Vector2(p.x - 15, gy), Vector2(p.x + 15, gy), Color(0.2, 0.2, 0.22), 2.0)
			draw_rect(Rect2(p.x - 16, p.y - 16, 32, 32), Color(0.44, 0.44, 0.47), false, 2.0)
			_draw_broadleaf(self, p, 0.72)
		else:
			_draw_lamppost(p)
	# trash bins: green, lidded, with a visible mouth - the ONLY thing
	# the owner will throw a bag into
	for bn in bins:
		if bn.y < vt - 40.0 or bn.y > vb + 40.0:
			continue
		cast_shadow(self, bn, 11.0, 24.0)
		# the drum, on its post, with a lit rim and a genuinely dark mouth
		draw_circle(bn, 13.0, Color(0.18, 0.25, 0.20))
		draw_circle(bn, 11.0, Color(0.26, 0.36, 0.28))
		draw_circle(bn + Vector2(-3, -3), 7.0, Color(0.32, 0.44, 0.33))
		draw_arc(bn, 11.0, PI * 1.05, PI * 1.95, 14, Color(0.42, 0.55, 0.42), 2.0)
		# the hinged lid, tipped open toward the light
		draw_circle(bn + Vector2(1, 2), 8.6, Color(0.10, 0.14, 0.11))
		draw_arc(bn + Vector2(1, 2), 8.6, PI * 0.1, PI * 0.9, 12, Color(0.20, 0.28, 0.22), 3.0)
		# a bag someone has knotted round the handle, as always
		draw_circle(bn + Vector2(12, 6), 4.0, Color(0.78, 0.78, 0.74, 0.85))
		draw_line(bn + Vector2(10, 2), bn + Vector2(12, 5), Color(0.7, 0.7, 0.66), 1.5)
	# cafe tables with a little service on them
	for tb in tables:
		draw_circle(tb, 14.0, Color(0.6, 0.55, 0.48))
		draw_arc(tb, 14.0, 0, TAU, 20, Color(0.45, 0.4, 0.34), 2.0)
		draw_circle(tb + Vector2(5, -4), 3.2, Color(0.92, 0.9, 0.85))
		draw_circle(tb + Vector2(-4, 4), 2.0, Color(0.5, 0.32, 0.2))
		draw_circle(tb, 2.6, Color(0.4, 0.36, 0.3))
	# canopies over the beach terraces: out by day, furled at night
	for cn in canopies:
		if Game.night:
			draw_rect(Rect2(cn.position.x, cn.position.y, cn.size.x, 10), Color(0.72, 0.67, 0.57))
			draw_rect(Rect2(cn.position.x, cn.position.y, cn.size.x, 10), Color(0.5, 0.46, 0.38), false, 1.5)
		else:
			draw_rect(cn, Color(0.93, 0.9, 0.8, 0.45))
			draw_rect(cn, Color(0.6, 0.55, 0.45, 0.6), false, 2.0)
			draw_line(Vector2(cn.get_center().x, cn.position.y), Vector2(cn.get_center().x, cn.end.y), Color(0.6, 0.55, 0.45, 0.4), 1.5)
	# umbrellas: wide, OVER the tables by day; furled spikes at night
	var pcols := [Color(0.85, 0.45, 0.35, 0.7), Color(0.4, 0.6, 0.75, 0.7), Color(0.9, 0.8, 0.4, 0.7)]
	for i in range(parasols.size()):
		var pa := parasols[i]
		if Game.night:
			draw_line(pa + Vector2(-3, 24), pa + Vector2(3, -28), Color(0.45, 0.4, 0.35), 5.0)
			draw_circle(pa + Vector2(3, -28), 4.0, pcols[i % 3])
		else:
			draw_circle(pa, 40.0, pcols[i % 3])
			draw_arc(pa, 40.0, 0, TAU, 24, Color(1, 1, 1, 0.4), 2.0)
			for sp in range(6):
				draw_line(pa, pa + Vector2.from_angle(TAU * sp / 6.0) * 40.0, Color(1, 1, 1, 0.25), 2.0)
			draw_circle(pa, 3.5, Color(0.4, 0.35, 0.3))
	# benches
	for b in benches:
		draw_rect(Rect2(b.x - 8, b.y - 24, 16, 48), Color(0.5, 0.38, 0.26))
		draw_line(Vector2(b.x, b.y - 22), Vector2(b.x, b.y + 22), Color(0.42, 0.32, 0.22), 2.0)
	# terrace chairs: round seats, four legs, a hint of backrest
	for ch in chairs:
		for lg in [Vector2(-5, -5), Vector2(5, -5), Vector2(-5, 5), Vector2(5, 5)]:
			draw_circle(ch + lg, 1.5, Color(0.35, 0.27, 0.18))
		draw_circle(ch, 6.5, Color(0.58, 0.44, 0.3))
		draw_arc(ch, 6.5, PI * 1.15, PI * 1.85, 8, Color(0.4, 0.3, 0.2), 3.0)
	# fountains: where the tank refills
	for f in fountains:
		draw_circle(f, 12.0, Color(0.5, 0.55, 0.58))
		draw_circle(f, 8.0, Color(0.4, 0.55, 0.65))
		draw_circle(f + Vector2(0, -3), 2.5, Color(0.75, 0.88, 0.95))
		draw_circle(f + Vector2(14, 8), 5.0, Color(0.45, 0.6, 0.7, 0.5))
	# market stalls: awnings, crates, produce
	for i in range(stalls.size()):
		var st := stalls[i]
		draw_rect(Rect2(st.x - 48, st.y - 28, 96, 56), Color(0.55, 0.42, 0.3))
		var acol := Color(0.75, 0.3, 0.28) if i % 2 == 0 else Color(0.32, 0.5, 0.42)
		for s2 in range(6):
			draw_rect(Rect2(st.x - 48 + s2 * 16.0, st.y - 36, 8, 10), acol)
			draw_rect(Rect2(st.x - 40 + s2 * 16.0, st.y - 36, 8, 10), Color(0.92, 0.9, 0.84))
		draw_rect(Rect2(st.x - 40, st.y - 18, 24, 16), Color(0.7, 0.55, 0.35))
		draw_circle(st + Vector2(18, -2), 5.0, Color(0.85, 0.45, 0.3))
		draw_circle(st + Vector2(30, 6), 5.0, Color(0.9, 0.7, 0.3))
		draw_circle(st + Vector2(6, 10), 4.0, Color(0.5, 0.65, 0.35))
	# parked service vans, half on the walkway, hazards blinking in spirit
	# The service van: the biggest object in the game and, until now, a white
	# rectangle with four black tabs. A van seen from above is a roof - so it
	# gets a roof: ribs across it, a vent, roof bars, the windscreen raked
	# under the front edge, mirrors sticking out past the body, and the long
	# shadow a two-metre box actually throws.
	for v in vans:
		if v.y < vt - 140.0 or v.y > vb + 140.0:
			continue
		var body := Rect2(v.x - 32.0, v.y - 66.0, 64.0, 132.0)
		# it sits high, so the shadow is offset a long way and shaped like it
		draw_set_transform(v + LIGHT * 30.0, 0.0, Vector2.ONE)
		draw_rect(Rect2(-34.0, -66.0, 68.0, 134.0),
			Color(SHADOW_COL.r, SHADOW_COL.g, SHADOW_COL.b, 0.22))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# tyres, visible past the body on both sides
		for w: Vector2 in [Vector2(-35, -42), Vector2(29, -42), Vector2(-35, 28), Vector2(29, 28)]:
			draw_rect(Rect2(v.x + w.x, v.y + w.y, 6.0, 17.0), Color(0.10, 0.10, 0.12))
		# the roof, lit down its light-facing side
		draw_rect(body, Color(0.86, 0.86, 0.84))
		draw_rect(Rect2(body.position.x, body.position.y, 20.0, body.size.y),
			Color(0.93, 0.93, 0.91))
		draw_rect(Rect2(body.end.x - 12.0, body.position.y, 12.0, body.size.y),
			Color(0.72, 0.72, 0.71))
		draw_rect(body, Color(0.44, 0.44, 0.45), false, 2.0)
		# pressed ribs along the roof
		for ri in range(5):
			var ry := body.position.y + 26.0 + float(ri) * 20.0
			draw_line(Vector2(body.position.x + 5.0, ry), Vector2(body.end.x - 5.0, ry),
				Color(0.76, 0.76, 0.75), 1.5)
		# windscreen at the front (north), raked, with a wiper
		draw_rect(Rect2(v.x - 27.0, v.y - 63.0, 54.0, 20.0), Color(0.30, 0.38, 0.46))
		draw_rect(Rect2(v.x - 27.0, v.y - 63.0, 54.0, 7.0), Color(0.52, 0.62, 0.70, 0.7))
		draw_line(v + Vector2(-18, -46), v + Vector2(6, -52), Color(0.2, 0.2, 0.22), 1.6)
		# mirrors, which is what makes it read as a VEHICLE and not a crate
		for mx: float in [-1.0, 1.0]:
			draw_rect(Rect2(v.x + mx * 38.0 - 3.0, v.y - 52.0, 6.0, 9.0), Color(0.30, 0.30, 0.32))
		# roof vent and bars
		draw_rect(Rect2(v.x - 11.0, v.y - 16.0, 22.0, 16.0), Color(0.74, 0.74, 0.72))
		draw_rect(Rect2(v.x - 11.0, v.y - 16.0, 22.0, 16.0), Color(0.52, 0.52, 0.52), false, 1.5)
		for bx: float in [-20.0, 20.0]:
			draw_line(v + Vector2(bx, -34.0), v + Vector2(bx, 46.0), Color(0.62, 0.62, 0.62), 2.5)
		# the back doors and a livery stripe down the side
		draw_line(v + Vector2(-30, 58), v + Vector2(30, 58), Color(0.55, 0.55, 0.56), 2.0)
		draw_line(v + Vector2(0, 58), v + Vector2(0, 66), Color(0.55, 0.55, 0.56), 2.0)
		draw_rect(Rect2(v.x - 32.0, v.y + 4.0, 64.0, 7.0), Color(0.62, 0.28, 0.24))
		# a hazard beacon on the cab, because it is parked where it should not be
		var beat := 0.55 + 0.45 * sin(Time.get_ticks_msec() / 190.0)
		draw_circle(v + Vector2(0, -40.0), 4.0, Color(0.95, 0.62, 0.15, 0.55 + beat * 0.45))
	# THE FUR-GONETA. A grooming van done up as a shaggy dog, in the tradition
	# of every mobile groomer that has ever driven past you - fur over the whole
	# body, floppy ears on the front corners, a fringe hanging over the eyes,
	# a wet nose and a tongue out. Our own name and livery: the van it tips its
	# hat to belongs to somebody else.
	#
	# The one surface you can read from directly overhead is the roof, so the
	# signwriting goes in a raised sign box up there, which is where a real
	# grooming van puts it anyway.
	if furgoneta.x < INF and furgoneta.y > vt - 150.0 and furgoneta.y < vb + 150.0:
		var v := furgoneta
		var fur := Color(0.46, 0.30, 0.17)
		var fur_lit := Color(0.58, 0.40, 0.23)
		var fur_dark := Color(0.31, 0.20, 0.11)
		var cream := Color(0.88, 0.83, 0.72)
		var cream_dk := Color(0.74, 0.68, 0.57)
		# the shadow of a two-metre box, same as the other vans
		draw_set_transform(v + LIGHT * 30.0, 0.0, Vector2.ONE)
		draw_rect(Rect2(-34.0, -66.0, 68.0, 134.0),
			Color(SHADOW_COL.r, SHADOW_COL.g, SHADOW_COL.b, 0.22))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		for w: Vector2 in [Vector2(-35, -40), Vector2(29, -40), Vector2(-35, 26), Vector2(29, 26)]:
			draw_rect(Rect2(v.x + w.x, v.y + w.y, 6.0, 18.0), Color(0.10, 0.10, 0.12))
		# --- ears: big, floppy, hanging off the front corners --------------
		for sx: float in [-1.0, 1.0]:
			var ear_o := PackedVector2Array([
				v + Vector2(24.0 * sx, -58.0), v + Vector2(50.0 * sx, -40.0),
				v + Vector2(44.0 * sx, 2.0), v + Vector2(26.0 * sx, -12.0),
			])
			draw_colored_polygon(ear_o, fur_dark)
			draw_colored_polygon(PackedVector2Array([
				v + Vector2(26.0 * sx, -52.0), v + Vector2(43.0 * sx, -38.0),
				v + Vector2(38.0 * sx, -6.0), v + Vector2(27.0 * sx, -18.0),
			]), fur)
			# a paler inner edge, and the shaggy fringe along the bottom
			draw_line(v + Vector2(28.0 * sx, -48.0), v + Vector2(33.0 * sx, -14.0),
				fur_lit, 2.5)
			for tf in range(4):
				var ty := -6.0 + float(tf) * 2.5
				draw_line(v + Vector2((40.0 - float(tf) * 3.0) * sx, ty),
					v + Vector2((36.0 - float(tf) * 3.0) * sx, ty + 7.0), fur_dark, 2.0)
		# --- the body, in two tones like a real scruffy dog ---------------
		draw_rect(Rect2(v.x - 32.0, v.y - 66.0, 64.0, 132.0), fur)
		draw_rect(Rect2(v.x - 32.0, v.y - 66.0, 16.0, 132.0), fur_lit)   # lit flank
		draw_rect(Rect2(v.x + 22.0, v.y - 66.0, 10.0, 132.0), fur_dark)  # shaded flank
		# the cream patch over the face and along one side, which is what stops
		# it reading as a plain brown box
		draw_colored_polygon(PackedVector2Array([
			v + Vector2(-30.0, -66.0), v + Vector2(30.0, -66.0),
			v + Vector2(26.0, -30.0), v + Vector2(4.0, -24.0),
			v + Vector2(-22.0, -34.0), v + Vector2(-30.0, -52.0),
		]), cream)
		draw_colored_polygon(PackedVector2Array([
			v + Vector2(-30.0, 20.0), v + Vector2(-14.0, 26.0),
			v + Vector2(-18.0, 54.0), v + Vector2(-30.0, 58.0),
		]), cream_dk)
		# --- fur: ranks of little curved tufts, denser on the shaded side --
		for row in range(13):
			var ry := v.y - 62.0 + float(row) * 10.0
			for col in range(6):
				var rx := v.x - 27.0 + float(col) * 11.0 + (5.0 if row % 2 == 0 else 0.0)
				var on_cream: bool = ry < v.y - 28.0 or (rx < v.x - 14.0 and ry > v.y + 18.0)
				var tc: Color = cream_dk if on_cream else (fur_lit if rx < v.x - 12.0 else fur_dark)
				# a curl rather than a chevron: two short strokes at an angle
				draw_line(Vector2(rx, ry), Vector2(rx - 3.0, ry + 6.0), tc, 1.8)
				draw_line(Vector2(rx - 3.0, ry + 6.0), Vector2(rx + 1.0, ry + 8.0), tc, 1.6)
		# --- the face on the front (north) end ----------------------------
		# the fringe: a shaggy overhang that the eyes peer out from under
		for i in range(11):
			var fx := v.x - 25.0 + float(i) * 5.0
			draw_line(Vector2(fx, v.y - 66.0), Vector2(fx - 2.0, v.y - 50.0), cream_dk, 3.0)
		# small and dark, mostly hidden under the fringe - the reference van
		# has eyes you have to look for, not headlamps
		draw_circle(v + Vector2(-11.0, -46.0), 3.2, Color(0.13, 0.11, 0.11))
		draw_circle(v + Vector2(11.0, -46.0), 3.2, Color(0.13, 0.11, 0.11))
		draw_circle(v + Vector2(-11.6, -47.0), 1.0, Color(1, 1, 1, 0.55))
		draw_circle(v + Vector2(10.4, -47.0), 1.0, Color(1, 1, 1, 0.55))
		# the muzzle and a black nose where the grille would be. No tongue, no
		# collar: on the real thing the joke is the fur, and everything else is
		# still a work van.
		draw_circle(v + Vector2(0.0, -57.0), 11.0, cream)
		draw_circle(v + Vector2(0.0, -60.0), 7.0, Color(0.14, 0.12, 0.13))
		draw_circle(v + Vector2(-2.0, -62.0), 2.4, Color(0.34, 0.31, 0.32))
		# the front bumper, in van grey rather than a collar
		draw_rect(Rect2(v.x - 31.0, v.y - 33.0, 62.0, 6.0), Color(0.40, 0.38, 0.36))
		# --- the tail, wagging, on the back doors -------------------------
		var wag := sin(Time.get_ticks_msec() / 210.0) * 0.55
		var tail_dir := Vector2(0.0, 1.0).rotated(wag)
		var tail_root := v + Vector2(0.0, 64.0)
		draw_line(tail_root, tail_root + tail_dir * 30.0, fur_dark, 11.0)
		draw_line(tail_root, tail_root + tail_dir * 26.0, fur, 7.0)
		draw_circle(tail_root + tail_dir * 28.0, 5.0, cream)
		# --- the livery ----------------------------------------------------
		# Painted onto the roof rather than mounted above it. A light box the
		# size of the van looked like a taxi sign and drowned the vehicle; the
		# van this nods to just has its name written on it, so this does too.
		# Two lines, which keeps the panel inside the van's own width - the roof
		# is the only surface you can read from directly overhead, and that is
		# the one liberty being taken.
		var f_big := 16
		var f_small := 13
		var w_fur: float = font.get_string_size("FUR", HORIZONTAL_ALIGNMENT_LEFT, -1, f_big).x
		var w_gon: float = font.get_string_size("GONETA", HORIZONTAL_ALIGNMENT_LEFT, -1, f_small).x
		var pw: float = maxf(w_fur + 12.0, w_gon) + 12.0
		var panel := Rect2(v.x - pw * 0.5, v.y - 22.0, pw, 45.0)
		draw_rect(panel, Color(0.93, 0.90, 0.82, 0.93))
		draw_rect(panel, Color(0.44, 0.31, 0.20, 0.55), false, 1.5)
		var ink := Color(0.40, 0.20, 0.16)
		# FUR, with a paw print for the hyphen, then GONETA under it
		var fur_x := v.x - (w_fur + 11.0) * 0.5
		draw_string(font, Vector2(fur_x, v.y - 5.0), "FUR", HORIZONTAL_ALIGNMENT_LEFT, -1,
			f_big, ink)
		UiIcons.draw_paw(self, Vector2(fur_x + w_fur + 5.5, v.y - 12.0), 4.2,
			Color(0.62, 0.30, 0.22))
		draw_string(font, Vector2(panel.position.x, v.y + 10.0), "GONETA",
			HORIZONTAL_ALIGNMENT_CENTER, panel.size.x, f_small, ink)
		draw_string(font, Vector2(panel.position.x, v.y + 20.0), "dog grooming",
			HORIZONTAL_ALIGNMENT_CENTER, panel.size.x, 8, Color(0.52, 0.36, 0.26))
		if not furgoneta_sniffed:
			# it is the best smell in the city, so the nose can find it
			var fg := 0.5 + 0.5 * sin(prize_glow * 0.8)
			draw_arc(v, 74.0 + fg * 6.0, 0, TAU, 28, Color(1.0, 0.86, 0.5, 0.10 + fg * 0.07), 2.0)

	# L'Estacio: the moving walkway - a metal band with chevrons scrolling
	# in the carry direction
	if conveyor_zone.size.y > 0.0 and conveyor_zone.end.y > vt and conveyor_zone.position.y < vb:
		draw_rect(conveyor_zone, Color(0.32, 0.34, 0.38))
		draw_rect(conveyor_zone, Color(0.55, 0.58, 0.62), false, 2.0)
		var scroll := fmod(Time.get_ticks_msec() / 1000.0 * 90.0, 60.0) * conveyor_dir.y
		var cy := conveyor_zone.position.y + fmod(scroll, 60.0)
		while cy < conveyor_zone.end.y + 60.0:
			if cy > vt - 20.0 and cy < vb + 20.0:
				var cx := conveyor_zone.get_center().x
				draw_line(Vector2(cx - 30.0, cy + 10.0), Vector2(cx, cy), Color(0.6, 0.63, 0.68), 3.0)
				draw_line(Vector2(cx + 30.0, cy + 10.0), Vector2(cx, cy), Color(0.6, 0.63, 0.68), 3.0)
			cy += 60.0
	_draw_ground_detail(vt, vb)
	# the paw trail, in whatever she stood in
	for pr in paw_prints:
		var pp: Vector2 = pr.pos
		if pp.y < vt - 20.0 or pp.y > vb + 20.0:
			continue
		var pc: Color = SUBSTANCES[String(pr.kind)].col
		if bool(pr.get("boot", false)):
			# a sole: an oval pointing the way he was walking, so his trail
			# reads as a person's and hers reads as a dog's
			draw_set_transform(pp, float(pr.get("ang", 0.0)), Vector2(1.0, 0.62))
			draw_circle(Vector2.ZERO, 6.4, Color(pc.r, pc.g, pc.b, 0.62))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			continue
		draw_circle(pp, 3.2, Color(pc.r, pc.g, pc.b, 0.78))
		draw_circle(pp + Vector2(-2.5, -3.0), 1.4, Color(pc.r, pc.g, pc.b, 0.72))
		draw_circle(pp + Vector2(2.5, -3.0), 1.4, Color(pc.r, pc.g, pc.b, 0.72))
	# the substance patches themselves
	for sz in substance_zones:
		var zr: Rect2 = sz.rect
		if zr.end.y < vt - 40.0 or zr.position.y > vb + 40.0:
			continue
		if String(sz.kind) == "mud" or String(sz.kind) == "cement":
			continue  # those two draw themselves with their own level dressing
		if sz.has("patch"):
			# a patch already drew itself as an organic blob (draw_patch), and
			# painting its bounding RECTANGLE over the top put a visible tinted
			# box round every sand drift on the promenade
			continue
		var zc: Color = SUBSTANCES[String(sz.kind)].col
		draw_rect(zr, Color(zc.r, zc.g, zc.b, 0.55))
		draw_rect(zr, Color(zc.r, zc.g, zc.b, 0.85), false, 2.0)
	_draw_scents()
	# the grind: the rail lights up under her and a CENTRED balance bar shows
	# which way she is tipping, with the running score beside it
	if grind.active:
		var gy0 := maxf(vt - 40.0, GATE_Y)
		var gy1 := minf(vb + 40.0, START_Y + 200.0)
		draw_line(Vector2(grind_kerb_x, gy0), Vector2(grind_kerb_x, gy1), Color(1.0, 0.88, 0.45, 0.55), 4.0)
		var gp: Vector2 = dog.global_position + Vector2(0.0, -42.0)
		var gw := 74.0
		draw_rect(Rect2(gp.x - gw * 0.5, gp.y - 5.0, gw, 10.0), Color(0.06, 0.05, 0.08, 0.72))
		# centre mark, then the needle: middle is balanced, edges are a bail
		draw_line(Vector2(gp.x, gp.y - 5.0), Vector2(gp.x, gp.y + 5.0), Color(0.6, 0.62, 0.6, 0.8), 1.5)
		var nf: float = grind.fraction()
		var nx: float = gp.x - gw * 0.5 + gw * nf
		var tipping: float = absf(nf - 0.5) * 2.0
		draw_rect(Rect2(nx - 3.0, gp.y - 6.0, 6.0, 12.0),
			Color(0.6, 1.0, 0.6).lerp(Color(1.0, 0.4, 0.3), tipping))
		draw_string(font, gp + Vector2(-18.0, -12.0), "GRIND %d" % grind.points(),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(1, 0.95, 0.65))
	# the teeter meter: a tipping bar over the dog, filling toward the brink,
	# plus an arrow showing which way to scramble. Drawn in the world rather
	# than on the HUD so your eyes never leave her.
	if teeter.active:
		var f: float = teeter.fraction()
		var bp: Vector2 = dog.global_position + Vector2(0.0, -40.0)
		var bw := 66.0
		draw_rect(Rect2(bp.x - bw * 0.5, bp.y - 5.0, bw, 10.0), Color(0.06, 0.05, 0.08, 0.72))
		var danger := Color(1.0, 0.86, 0.35).lerp(Color(1.0, 0.32, 0.25), f)
		draw_rect(Rect2(bp.x - bw * 0.5 + 2.0, bp.y - 3.0, (bw - 4.0) * f, 6.0), danger)
		draw_rect(Rect2(bp.x - bw * 0.5, bp.y - 5.0, bw, 10.0), Color(0.9, 0.9, 0.85, 0.5), false, 1.5)
		# which way to fight: away from the brink
		var away: Vector2 = (dog.global_position - teeter_at).normalized()
		var ap: Vector2 = bp + Vector2(0.0, -16.0)
		var tip: Vector2 = ap + away * 17.0
		draw_line(ap, tip, Color(0.85, 1.0, 0.85, 0.95), 3.0)
		draw_line(tip, tip - away.rotated(0.5) * 7.0, Color(0.85, 1.0, 0.85, 0.95), 3.0)
		draw_line(tip, tip - away.rotated(-0.5) * 7.0, Color(0.85, 1.0, 0.85, 0.95), 3.0)
	# El Desguas: sweeping camera cones and laser tripwires
	if lvl == "scrap":
		var st := Time.get_ticks_msec() / 1000.0
		for c in cameras:
			var cp: Vector2 = c.pos
			if cp.y < vt - 220.0 or cp.y > vb + 220.0:
				continue
			var ang: float = float(c.base) + sin(st * float(c.speed)) * float(c.range)
			# the vision cone, hot for a beat after a catch
			var hot: bool = float(c.cd) > 2.5
			var cone := Color(1.0, 0.35, 0.3, 0.28) if hot else Color(1.0, 0.9, 0.55, 0.16)
			var pts := PackedVector2Array([cp])
			for k in range(9):
				var a := ang - 0.32 + 0.64 * float(k) / 8.0
				pts.append(cp + Vector2.from_angle(a) * 190.0)
			draw_colored_polygon(pts, cone)
			# the unit itself: pole, housing, blinking eye
			draw_rect(Rect2(cp.x - 2.0, cp.y, 4.0, 26.0), Color(0.35, 0.35, 0.38))
			draw_rect(Rect2(cp.x - 9.0, cp.y - 10.0, 18.0, 12.0), Color(0.25, 0.26, 0.3))
			draw_circle(cp + Vector2.from_angle(ang) * 8.0, 2.5, Color(1, 0.3, 0.25) if fmod(st, 1.0) < 0.5 else Color(0.5, 0.15, 0.12))
		for lz in lasers:
			var by := lerpf(float(lz.y_lo), float(lz.y_hi), 0.5 + 0.5 * sin(st * float(lz.speed)))
			if by < vt - 20.0 or by > vb + 20.0:
				continue
			draw_line(Vector2(float(lz.x0), by), Vector2(float(lz.x1), by), Color(1.0, 0.2, 0.2, 0.75), 2.0)
			draw_line(Vector2(float(lz.x0), by), Vector2(float(lz.x1), by), Color(1.0, 0.5, 0.4, 0.25), 6.0)
			draw_rect(Rect2(float(lz.x0) - 8.0, by - 6.0, 8.0, 12.0), Color(0.3, 0.3, 0.34))
			draw_rect(Rect2(float(lz.x1), by - 6.0, 8.0, 12.0), Color(0.3, 0.3, 0.34))
	# Les Obres: wet cement patches, and the paw-print trail they take
	if lvl == "site":
		for cz in cement_zones:
			if cz.end.y > vt and cz.position.y < vb:
				draw_rect(cz, Color(0.62, 0.62, 0.6))
				draw_rect(cz, Color(0.5, 0.5, 0.48), false, 2.0)
				draw_line(Vector2(cz.position.x, cz.position.y), Vector2(cz.end.x, cz.position.y), Color(0.9, 0.75, 0.2, 0.8), 3.0)
				draw_line(Vector2(cz.position.x, cz.end.y), Vector2(cz.end.x, cz.end.y), Color(0.9, 0.75, 0.2, 0.8), 3.0)
		pass  # prints are drawn for every walk now, further down
	# El Bosc: muddy patches across the trail (slow going)
	# whatever this walk has lying underfoot, drawn as the shape it would
	# actually be. Colour comes from SUBSTANCES so a new kind needs no new
	# drawing code.
	for pi in range(patches.size()):
		var pt: Dictionary = patches[pi]
		var pb := patch_bounds(pt)
		if pb.end.y < vt or pb.position.y > vb:
			continue
		var sk: String = String(pt["kind"])
		if sk == "tile":
			_draw_trencadis(pt)
			continue
		if sk == "sand":
			_draw_sand_drift(pt)
			continue
		var base: Color = Color(0.34, 0.26, 0.18)
		if SUBSTANCES.has(sk):
			base = Color((SUBSTANCES[sk] as Dictionary)["col"])
		draw_patch(self, pt, Color(base.r, base.g, base.b, 0.88),
			Color(base.r * 0.6, base.g * 0.6, base.b * 0.6, 0.45))
		# a few darker flecks, so a big patch is not one flat colour
		var mid := patch_centre(pt)
		for i in range(5):
			var a := float(i) * 1.31 + float(pt["seed"])
			var rr := 0.34 + 0.4 * fmod(float(i) * 0.37, 1.0)
			draw_circle(mid + Vector2(cos(a) * float(pt["rx"]) * rr,
				sin(a) * float(pt["ry"]) * rr), 5.0,
				Color(base.r * 0.7, base.g * 0.7, base.b * 0.7, 0.6))
	# El Gotic: laundry strung across the alley overhead, a lantern or two
	if lvl == "oldtown":
		var lt := Time.get_ticks_msec() / 1000.0
		var wash := [Color(0.8, 0.3, 0.35), Color(0.3, 0.5, 0.7), Color(0.9, 0.85, 0.6), Color(0.4, 0.65, 0.5)]
		for i in range(laundry_lines.size()):
			var ly: float = laundry_lines[i]
			draw_line(Vector2(sw_l - 20.0, ly), Vector2(sw_r + 20.0, ly - 8.0), Color(0.2, 0.18, 0.16), 1.5)
			for j in range(5):
				var hx := lerpf(sw_l + 20.0, sw_r - 20.0, float(j) / 4.0)
				var sway := sin(lt * 1.2 + j + i) * 2.0
				draw_rect(Rect2(hx - 9.0, ly - 6.0, 18.0, 26.0 + sway), wash[(i + j) % wash.size()])
		# lanterns down one wall
		for i in range(laundry_lines.size()):
			var lyy: float = laundry_lines[i] + 380.0
			var glow := 0.6 + 0.25 * sin(lt * 3.0 + i)
			draw_circle(Vector2(sw_l + 6.0, lyy), 6.0, Color(1.0, 0.8, 0.4, glow))
	# street performers: a hat, some coins, music in the air. In the rain
	# they are an umbrella crowd instead - hunched under canopies, no busking.
	var pt := Time.get_ticks_msec() / 1000.0
	var raining := Game.weather == "rain"
	var brolly_cols := [Color(0.75, 0.2, 0.25), Color(0.2, 0.35, 0.6), Color(0.25, 0.5, 0.35), Color(0.35, 0.3, 0.4)]
	for idx in range(performers.size()):
		var pf: Vector2 = performers[idx]
		draw_circle(pf, 12.0, Color(0.5, 0.35, 0.5))
		draw_circle(pf + Vector2(0, -4), 7.0, Color(0.85, 0.72, 0.58))
		if raining:
			# a wide domed umbrella over the head, on its stick
			var bc: Color = brolly_cols[idx % brolly_cols.size()]
			draw_line(pf + Vector2(0, -8), pf + Vector2(0, -30), Color(0.15, 0.14, 0.16), 2.0)
			draw_arc(pf + Vector2(0, -30), 26.0, PI, TAU, 20, bc, 7.0)
			for r in range(2):
				var rx := fmod(pt * 120.0 + idx * 30.0 + r * 60.0, 120.0)
				draw_line(pf + Vector2(-24 + rx * 0.4, -28), pf + Vector2(-24 + rx * 0.4, 12), Color(0.6, 0.7, 0.85, 0.4), 1.0)
			continue
		draw_arc(pf + Vector2(0, -4), 7.0, PI, TAU, 10, Color(0.2, 0.15, 0.1), 4.0)
		draw_circle(pf + Vector2(18, 12), 6.0, Color(0.3, 0.25, 0.2))
		draw_circle(pf + Vector2(16, 11), 1.5, Color(0.9, 0.8, 0.3))
		draw_circle(pf + Vector2(20, 13), 1.5, Color(0.9, 0.8, 0.3))
		for i in range(2):
			var ny := fmod(pt * 22.0 + i * 20.0, 44.0)
			var np := pf + Vector2(14.0 + i * 10.0 - ny * 0.2, -14.0 - ny)
			var na := clampf(1.0 - ny / 44.0, 0.0, 1.0) * 0.8
			draw_circle(np, 3.0, Color(1, 1, 1, na))
			draw_line(np + Vector2(2.5, -1), np + Vector2(2.5, -9), Color(1, 1, 1, na), 1.5)
	# cellar doors, propped open for a delivery
	for c in cellars:
		draw_rect(c, Color(0.1, 0.1, 0.12))
		draw_rect(Rect2(c.position.x, c.position.y, c.size.x, 6), Color(0.35, 0.28, 0.22))
		draw_line(c.position + Vector2(c.size.x / 2.0, 0), c.position + Vector2(c.size.x / 2.0, c.size.y), Color(0.3, 0.3, 0.33), 2.0)
		draw_rect(Rect2(c.end.x + 4, c.position.y + 10, 16, 20), Color(0.6, 0.45, 0.3))
	# marked spots, stray puddles and, discreetly, the business
	var pud := Color(0.93, 0.85, 0.4, 0.4)
	# the other dogs' marks: a small damp patch with a faint bloom, in their
	# own colour so you can tell who from across the park
	for nm in npc_marks:
		var nmp: Vector2 = nm.pos
		if nmp.y < vt - 30.0 or nmp.y > vb + 30.0:
			continue
		var nc: Color = nm.col
		draw_circle(nmp + Vector2(0, 6), 7.0, Color(0.82, 0.78, 0.32, 0.20))
		draw_circle(nmp + Vector2(0, 6), 3.4, Color(nc.r, nc.g, nc.b, 0.35))
		if not bool(nm.sniffed):
			var np := 0.5 + 0.5 * sin(prize_glow * 0.7 + nmp.x * 0.05)
			draw_arc(nmp + Vector2(0, 6), 11.0 + np * 3.0, 0, TAU, 14,
				Color(0.9, 0.92, 0.5, 0.12 + np * 0.10), 1.5)
	for mk in marks:
		draw_circle(mk + Vector2(6, 10), 6.0, pud)
		draw_circle(mk + Vector2(11, 13), 3.5, pud)
		draw_circle(mk + Vector2(7, 9), 3.0, Color(0.95, 0.88, 0.5, 0.7))
	for pd in puddles:
		var pr: float = pd.r
		draw_circle(pd.pos, pr, pud)
		draw_circle((pd.pos as Vector2) + Vector2(pr * 0.7, pr * 0.4), pr * 0.6, pud)
	if business_spot.x < INF:
		# soft-serve, cartoon rules, nothing gross
		var pcol := Color(0.36, 0.26, 0.16)
		draw_circle(business_spot, 4.5, pcol)
		draw_circle(business_spot + Vector2(0, -3), 3.2, pcol.lightened(0.08))
		draw_circle(business_spot + Vector2(1, -5.5), 1.8, pcol.lightened(0.16))
	for f in bag_flights:
		var e: float = f.t
		var bp: Vector2 = f.from.lerp(f.to, e) + (f.to - f.from).orthogonal().normalized() * sin(e * PI) * 26.0
		draw_circle(bp, 4.0 + sin(e * PI) * 2.0, Color(0.92, 0.92, 0.95))
	if mark_target.x < INF and mark_progress > 0.0:
		draw_arc(mark_target, 17.0, -PI / 2.0, -PI / 2.0 + TAU * mark_progress / 0.7, 20, Color(1, 0.95, 0.6), 3.0)
	# the off-leash freedom yard beyond the gate: a proper fenced dog
	# park - grass, chain-link fence with posts, human benches, and a
	# labelled entrance gate
	if vt < GATE_Y + 60.0 and freedom_kind == "beach":
		# only the water moves; the sand and everything on it is on the layer
		_draw_beach_water()
	# the gate between the walk and the off-leash yard
	draw_rect(Rect2(gate_l - 14, GATE_Y - 46, 14, 60), Color(0.35, 0.3, 0.28))
	draw_rect(Rect2(gate_r, GATE_Y - 46, 14, 60), Color(0.35, 0.3, 0.28))
	draw_rect(Rect2(gate_l - 14, GATE_Y - 58, gate_r - gate_l + 28, 14), Color(0.35, 0.3, 0.28))
	# centred on the gate mouth, not nudged left by an eyeballed 40px
	draw_string(font, Vector2(gate_l, GATE_Y - 66), gate_text, HORIZONTAL_ALIGNMENT_CENTER,
		gate_r - gate_l, 26, Color(0.9, 0.88, 0.8))
	var gx := gate_l
	while gx < gate_r:
		draw_line(Vector2(gx, GATE_Y), Vector2(gx + 16.0, GATE_Y), Color(0.9, 0.88, 0.8, 0.6), 3.0)
		gx += 32.0
	# HOME, at the bottom, where the walk both begins and ends
	if vb > START_Y + 30.0:
		draw_rect(Rect2(gate_l - 14, HOME_Y + 40.0, gate_r - gate_l + 28, 14), Color(0.4, 0.32, 0.3))
		draw_string(font, Vector2(gate_l, HOME_Y + 78.0), "HOME", HORIZONTAL_ALIGNMENT_CENTER,
			gate_r - gate_l, 24, Color(0.9, 0.85, 0.7))
	if not started and vb > START_Y - 260.0:
		_draw_ground_title()
	# The line painted on the pavement at the start: where you are going, and
	# the one thing about this walk that will get you. Eight of the twelve
	# walks used to fall back on the boulevard's line, so El Gotic told you to
	# mind bike lanes it does not have.
	draw_string(font, Vector2(0, START_Y + 90), String(OPENERS.get(lvl, OPENERS["street"])),
		HORIZONTAL_ALIGNMENT_CENTER, 1280, 17, Color(1, 1, 1, 0.5))
