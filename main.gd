extends Node2D

# Path of Leash Resistance.
# You are the dog. Walk the phone-zombie human through it with the
# phone intact. Go touch grass.

const SIDEWALK_LEFT := 300.0
const SIDEWALK_RIGHT := 980.0
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
const LEASH_STRETCH_CAP := 1.15
const LEASH_K := 32.0
const DOG_MASS := 1.0
const HUMAN_MASS := 4.0
const POLE_RADIUS := 10.0
const HYDRANT_RADIUS := 9.0
const FOUNTAIN_RADIUS := 12.0
const PERFORMER_RADIUS := 12.0
const MANHOLE_RADIUS := 24.0
const BENCH_BODY_SIZE := Vector2(16.0, 48.0)
const VAN_BODY_SIZE := Vector2(64.0, 132.0)
const STALL_BODY_SIZE := Vector2(96.0, 56.0)

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
var gate_text := "PARK"
var duck_ys: Array[float] = []
var ducks_disturbed := 0
# where the HUMAN's autopilot lives; the dog may roam anywhere between
# the outer walls, though an undistracted owner has opinions about it
var walk_cx := 640.0
var walk_half := 340.0
var gate_l := SIDEWALK_LEFT
var gate_r := SIDEWALK_RIGHT
var tut_l := 220.0
var tut_r := 1160.0
var offpath_t := 0.0
# beach furniture
var towels: Array[Dictionary] = []
var parasols: Array[Vector2] = []
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

var leash_len := LEASH_LENGTH
var leash_target := LEASH_LENGTH
var started := false
var bones := 0
var streak := 0
var phone_hp := 3
var pee := 1.0
var marks: Array[Vector2] = []
var puddles: Array[Dictionary] = []
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
var qbg: Panel
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
var quests_label: Label
var msg_label: Label
var combo: Node
var challenge: Node
var challenge_l: Label
var challenge_giver: Node2D
var challenge_offered := false
var dog_carrying := false
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
	else:
		Game.daily = false
		if autowalk_requested:
			seed(AUTOWALK_SEED)
		lvl = Game.level_id
	# El Aguacero is always a downpour, whatever the weather selection says
	if lvl == "rain":
		Game.weather = "rain"
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
	chase_active = chase_forced or bolt_forced or rescue_forced or (not auto_walk and not Game.daily and randf() < 0.25)
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
	menu_step = Game.menu_step
	_apply_menu_step()


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
	}
	for action in buttons:
		InputMap.add_action(action)
		var evk := InputEventKey.new()
		evk.physical_keycode = buttons[action][0]
		InputMap.action_add_event(action, evk)
		var evb := InputEventJoypadButton.new()
		evb.button_index = buttons[action][1]
		InputMap.action_add_event(action, evb)


func _build_level_data() -> void:
	var hyd_list: Array[Vector2] = []
	var keb_list: Array[Vector2] = []
	# a couple of walks reuse a proven layout as a base for now (bespoke
	# geometry is a later pass) and re-theme it below: El Aguacero on the
	# boulevard, El Gotic on the stall-lined market channel.
	var geo := lvl
	if lvl == "rain":
		geo = "street"
	elif lvl == "oldtown":
		geo = "market"
	match geo:
		"street":
			lane_ys = [-1200.0, -2600.0, -4000.0]
			gate_text = "PARK"
			for i in range(7):
				var x := SIDEWALK_LEFT + 30.0 if i % 2 == 0 else SIDEWALK_RIGHT - 30.0
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
			tables = [Vector2(760, -3560), Vector2(840, -3660), Vector2(700, -3700), Vector2(790, -3780)]
			chairs = [
				Vector2(725, -3535), Vector2(800, -3595), Vector2(872, -3690),
				Vector2(736, -3745), Vector2(670, -3672), Vector2(815, -3820),
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
				Rect2(SIDEWALK_LEFT, -2750, 62, 88), Rect2(SIDEWALK_RIGHT - 62, -750, 62, 82),
				Rect2(SIDEWALK_LEFT, -4550, 62, 88),
			]
			bins = [
				Vector2(SIDEWALK_LEFT + 30, -600), Vector2(SIDEWALK_RIGHT - 30, -1400),
				Vector2(SIDEWALK_LEFT + 30, -2150), Vector2(SIDEWALK_RIGHT - 30, -3000),
				Vector2(SIDEWALK_LEFT + 30, -3700), Vector2(SIDEWALK_RIGHT - 30, -4700),
			]
			benches = [Vector2(336, -1300), Vector2(944, -2450), Vector2(336, -3850)]
			hyd_list = [
				Vector2(SIDEWALK_LEFT + 45, -500), Vector2(SIDEWALK_RIGHT - 45, -1500),
				Vector2(SIDEWALK_LEFT + 45, -2300), Vector2(SIDEWALK_RIGHT - 45, -3300),
				Vector2(SIDEWALK_LEFT + 45, -4600),
				Vector2(SHOULDER_R - 12, -1000), Vector2(SHOULDER_R - 12, -3600),
			]
			keb_list = [Vector2(640, -1960), Vector2(700, -4200), Vector2(SHOULDER_R - 12, -2400)]
		"park":
			gate_text = "HOME"
			# the pond bites into the path; the strip past it is the bridge
			pond = Rect2(SIDEWALK_LEFT, -2950, 360, 470)
			duck_ys = [randf_range(-2200.0, -1400.0), randf_range(-4300.0, -3400.0)]
			for i in range(7):
				var x := SIDEWALK_LEFT + 30.0 if i % 2 == 0 else SIDEWALK_RIGHT - 30.0
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
				Vector2(SIDEWALK_LEFT + 30, -600), Vector2(SIDEWALK_RIGHT - 30, -1400),
				Vector2(SIDEWALK_LEFT + 30, -2150), Vector2(SIDEWALK_RIGHT - 30, -3000),
				Vector2(SIDEWALK_LEFT + 30, -3700), Vector2(SIDEWALK_RIGHT - 30, -4700),
			]
			benches = [Vector2(336, -1300), Vector2(944, -2450), Vector2(336, -3850), Vector2(944, -1900)]
			hyd_list = [
				Vector2(SIDEWALK_LEFT + 45, -500), Vector2(SIDEWALK_RIGHT - 45, -1500),
				Vector2(SIDEWALK_LEFT + 45, -2300), Vector2(SIDEWALK_RIGHT - 45, -3300),
				Vector2(SIDEWALK_LEFT + 45, -4600),
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
			# palms: a row along the boardwalk, a row by the cafes -
			# where the city actually plants them
			for i in range(6):
				poles.append(Vector2(462.0, -400.0 - i * 880.0))
			for i in range(5):
				poles.append(Vector2(998.0, -700.0 - i * 880.0))
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
			parasols = [Vector2(200, -900), Vector2(150, -2300), Vector2(240, -3700), Vector2(170, -4500)]
			var towel_cols := [Color(0.85, 0.4, 0.35), Color(0.35, 0.55, 0.8), Color(0.9, 0.75, 0.3), Color(0.5, 0.7, 0.5)]
			var ty := -800.0
			for i in range(5):
				towels.append({
					"rect": Rect2(randf_range(120.0, 270.0), ty, 46, 80),
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
				var x := SIDEWALK_LEFT + 30.0 if i % 2 == 0 else SIDEWALK_RIGHT - 30.0
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
			hyd_list = [Vector2(345, -600), Vector2(935, -1900), Vector2(345, -3600)]
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
	for i in range(140):
		var side := -1.0 if randf() < 0.5 else 1.0
		var x := 640.0 + side * randf_range(340.0, 620.0)
		tufts.append(Vector2(x, randf_range(GATE_Y - 600.0, START_Y + 150.0)))
	for i in range(14):
		for attempt in range(20):
			var tree := Vector2(randf_range(200.0, 1080.0), GATE_Y - randf_range(120.0, 550.0))
			var clear := tree.distance_to(gate_bench) > 95.0
			for slot in PAIR_PARK_SPOTS:
				var spot: Vector2 = slot.position
				clear = clear and tree.distance_to(spot) > 85.0
			if clear:
				trees.append(tree)
				break
	for ly in lane_ys:
		lane_state.append({"t": randf_range(1.0, 2.5), "phase": 0, "dir": 1})
	# the hazardous hard-to-reach collectible: one per level, in a spot
	# that costs you something to reach
	match lvl:
		"street":
			prize_pos = Vector2(SHOULDER_R - 12.0, -2400.0)  # far shoulder, across the bike lane
			prize_text = "fetch the frisbee across the bike lane"
		"park":
			prize_pos = pond.get_center() if pond.size.x > 0.0 else Vector2(640.0, -2700.0)
			prize_text = "fetch the ball from the middle of the pond"
		"beach":
			prize_pos = Vector2(300.0, -2600.0)  # down at the waterline on the sand
			prize_text = "fetch the ball from the water's edge"
		"market":
			prize_pos = Vector2(640.0, -2050.0)  # by the drain in the middle aisle
			prize_text = "grab the churro by the open drain"
		"rain":
			prize_pos = Vector2(640.0, -1500.0)  # right on a gaping storm drain
			prize_text = "snatch the toy off the storm drain"
		"oldtown":
			prize_pos = Vector2(920.0, -2750.0)  # under a smug wall cat, up the wall
			prize_text = "steal the sardine under the cat's ledge"
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
	var defs := [
		[Vector2(40.0, mid_y), Vector2(100, span)],
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
	# vans and stalls are solid rectangles: no walking over the van roof
	for v in vans:
		_add_rect_body(v, VAN_BODY_SIZE)
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

	cam = Camera2D.new()
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 6.0
	cam.position = Vector2(640, START_Y - 120.0)
	add_child(cam)
	cam.make_current()


const LEVEL_GOAL_IDS := {
	"street": ["mark", "sniff", "phone", "paws", "bag", "fetch", "tofu", "close", "fling", "carry", "prize"],
	"park": ["mark", "sniff", "phone", "paws", "bag", "fetch", "tofu", "hi", "drink", "prize"],
	"beach": ["mark", "sniff", "phone", "paws", "bag", "fetch", "tofu", "snack", "save", "prize"],
	"rain": ["mark", "sniff", "phone", "paws", "bag", "fetch", "tofu", "close", "drink", "prize"],
	"market": ["mark", "sniff", "phone", "paws", "bag", "fetch", "tofu", "snack", "zoom", "carry", "prize"],
	"oldtown": ["mark", "sniff", "phone", "paws", "bag", "fetch", "tofu", "cats", "snack", "prize"],
}


func _goal_defs() -> Dictionary:
	# every goal the game knows, keyed by a stable id (persistence-facing)
	return {
		"mark": {"text": "mark %d spots", "target": 5, "fn": func() -> int: return marks.size()},
		"sniff": {"text": "%d good sniffs", "target": 4, "fn": func() -> int: return sniffs_done},
		"phone": {"text": "phone without a scratch", "target": 1, "fn": func() -> int: return 1 if phone_hp == 3 else 0},
		"paws": {"text": "keep your own paws clean", "target": 1, "fn": func() -> int: return 1 if dog_hits == 0 else 0},
		"bag": {"text": "get the business bagged", "target": 1, "fn": func() -> int: return 1 if poop_state == 2 and not bag_pending else 0},
		"fetch": {"text": "bring back %d balls", "target": 3, "fn": func() -> int: return romp_catches},
		"tofu": {"text": "bring Tofu home", "target": 1, "fn": func() -> int: return 1 if tofu_home else 0},
		"hi": {"text": "say hi to %d dogs", "target": 3, "fn": func() -> int: return dogs_greeted},
		"drink": {"text": "have a good long drink", "target": 1, "fn": func() -> int: return 1 if drunk_amount >= 0.4 else 0},
		"zoom": {"text": "burn off the zoomies", "target": 1, "fn": func() -> int: return 1 if dog.energy <= 0.25 else 0},
		"chase": {"text": "chase %d critters", "target": 2, "fn": func() -> int: return squirrels_chased},
		"close": {"text": "%d close calls", "target": 3, "fn": func() -> int: return close_calls},
		"save": {"text": "%d nice saves", "target": 2, "fn": func() -> int: return saves_done},
		"fling": {"text": "fling the owner off a pole", "target": 1, "fn": func() -> int: return flings_done},
		"tangle": {"text": "tangle with another walker", "target": 1, "fn": func() -> int: return 1 if tangles >= 1 else 0},
		"snack": {"text": "steal %d dropped snacks", "target": 2, "fn": func() -> int: return kebabs_eaten},
		"cats": {"text": "shoo %d wall cats", "target": 3, "fn": func() -> int: return wall_cats_spooked},
		"carry": {"text": carry_text, "target": 1, "fn": func() -> int: return 1 if carry_state >= 2 else 0},
		"prize": {"text": prize_text, "target": 1, "fn": func() -> int: return 1 if prize_taken else 0},
	}


func _build_quests() -> void:
	# a fixed ~10-goal list per level (Tony Hawk style): completing a goal
	# on any run marks it done for that level forever. Repeating goals,
	# a couple of level flavours, and the unique hazardous prize.
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


func _credit_goal(q: Dictionary) -> void:
	# award + persist a goal the first time it completes this run
	var id: String = q.id
	if run_goals_hit.has(id):
		return
	run_goals_hit[id] = true
	bones += 5
	var newly: bool = Game.mark_goal(lvl, id) if not Game.daily else false
	var tag := "GOAL! " if (newly or Game.daily) else "goal (again) "
	float_text(dog.global_position, tag + _quest_text(q), Color(0.8, 1.0, 0.8))


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
		cn.setup(self, dog, human)
	# A-stands are entities too: light, toppleable, never re-stood
	for a in astands:
		var sa := Node2D.new()
		sa.set_script(load("res://astand.gd"))
		sa.position = a
		sa.z_index = 11
		add_child(sa)
		sa.setup(self, dog, human)


func _build_hud() -> void:
	hud = CanvasLayer.new()
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
	var qsb := StyleBoxFlat.new()
	qsb.bg_color = Color(0.08, 0.09, 0.1, 0.3)
	qsb.set_corner_radius_all(10)
	qbg = Panel.new()
	qbg.add_theme_stylebox_override("panel", qsb)
	qbg.position = Vector2(924, 8)
	qbg.size = Vector2(348, 112)
	hud.add_child(qbg)
	quests_label = _hud_label(Vector2(938, 16), 15)
	quests_label.size = Vector2(330, 100)
	hint_l = _hud_label(Vector2(24, 686), 15)
	hint_l.modulate.a = 0.75
	title_l = _hud_label(Vector2(0, 240), 44)
	title_l.size = Vector2(1280, 52)
	title_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_l.text = "PATH OF LEASH RESISTANCE"
	sub_l = _hud_label(Vector2(0, 300), 18)
	sub_l.size = Vector2(1280, 30)
	sub_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_l.text = "You are the dog. Go touch grass."
	select_l = _hud_label(Vector2(0, 348), 22)
	select_l.size = Vector2(1280, 32)
	select_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	select_l.text = "<   %s   >" % Game.LEVEL_NAMES[lvl]
	record_l = _hud_label(Vector2(0, 300), 18)
	record_l.size = Vector2(1280, 26)
	record_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	record_l.modulate.a = 0.85
	var version_l := _hud_label(Vector2(1150, 686), 13)
	version_l.text = "v1.18"
	version_l.modulate.a = 0.5
	owner_l = _hud_label(Vector2(0, 296), 26)
	owner_l.size = Vector2(1280, 34)
	owner_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	night_l = _hud_label(Vector2(0, 340), 26)
	night_l.size = Vector2(1280, 34)
	night_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	weather_l = _hud_label(Vector2(0, 384), 26)
	weather_l.size = Vector2(1280, 34)
	weather_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_l = _hud_label(Vector2(0, 470), 22)
	prompt_l.size = Vector2(1280, 32)
	prompt_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shop_preview_bg = ColorRect.new()
	shop_preview_bg.position = Vector2(60.0, 190.0)
	shop_preview_bg.size = Vector2(440.0, 390.0)
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
	shop_title_l.size = Vector2(1280, 40)
	shop_title_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shop_title_l.visible = false
	shop_preview_l = _hud_label(Vector2(60.0, 145.0), 18)
	shop_preview_l.size = Vector2(440.0, 30.0)
	shop_preview_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shop_preview_l.text = "HIGHLIGHTED LOOK"
	shop_preview_l.visible = false
	shop_l = _hud_label(Vector2(430.0, 150.0), 20)
	shop_l.size = Vector2(800.0, 460.0)
	shop_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shop_l.visible = false
	for k in Game.COLLARS:
		shop_items.append({"kind": "collar", "key": k})
	for k in Game.BANDANAS:
		if k != "none":
			shop_items.append({"kind": "bandana", "key": k})
	shop_items.append({"kind": "bandana", "key": "none"})
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
	combo_bar_bg.size = Vector2(400, 8)
	combo_bar_bg.color = Color(0.05, 0.06, 0.07, 0.55)
	combo_bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	combo_bar_bg.visible = false
	hud.add_child(combo_bar_bg)
	combo_bar = ColorRect.new()
	combo_bar.position = Vector2(440, 662)
	combo_bar.size = Vector2(400, 8)
	combo_bar.color = Color(1.0, 0.78, 0.32)
	combo_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	combo_bar.visible = false
	hud.add_child(combo_bar)
	combo_l = _hud_label(Vector2(0, 624), 26)
	combo_l.size = Vector2(1280, 34)
	combo_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	combo_l.visible = false
	# the combo challenge (Phase B): a bounded trick dare from a bystander
	challenge = Node.new()
	challenge.set_script(load("res://challenge.gd"))
	add_child(challenge)
	challenge.setup(self)
	challenge_l = _hud_label(Vector2(0, 70), 24)
	challenge_l.size = Vector2(1280, 30)
	challenge_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	challenge_l.visible = false
	dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.size = Vector2(1280, 720)
	dim.visible = false
	hud.add_child(dim)
	msg_label = _hud_label(Vector2(0, 200), 22)
	msg_label.size = Vector2(1280, 400)
	msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg_label.visible = false
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
	qbg.visible = started
	quests_label.visible = started
	title_l.visible = in_menu
	sub_l.visible = in_menu and menu_step == 0
	select_l.visible = in_menu and menu_step >= 1
	record_l.visible = in_menu and menu_step == 1
	owner_l.visible = in_menu and menu_step == 2
	night_l.visible = in_menu and menu_step == 2
	weather_l.visible = in_menu and menu_step == 2
	prompt_l.visible = in_menu
	if not in_menu:
		return
	match menu_step:
		0:
			title_l.add_theme_font_size_override("font_size", 60)
			title_l.position.y = 210
			title_l.text = "PATH OF LEASH RESISTANCE"
			sub_l.add_theme_font_size_override("font_size", 22)
			sub_l.position.y = 288
			sub_l.text = "you are the dog. go touch grass."
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
	for l: Label in [title_l, sub_l, prompt_l, select_l, owner_l, night_l, weather_l, record_l]:
		l.visible = false
	shop_title_l.visible = true
	shop_l.visible = true
	shop_preview_bg.visible = true
	shop_preview_l.visible = true
	shop_preview.visible = true
	_refresh_shop()


func _shop_select() -> void:
	var it: Dictionary = shop_items[shop_idx]
	var key: String = it.key
	if Game.owned.get(key, false):
		# equip
		if it.kind == "collar":
			Game.collar = key
		else:
			Game.bandana = key
		Game.save_records()
	elif Game.buy(key):
		if it.kind == "collar":
			Game.collar = key
		else:
			Game.bandana = key
		Game.save_records()
	# (if the buy failed, not enough bones - the price stays shown)
	_refresh_shop()


func _refresh_shop() -> void:
	shop_title_l.text = "MILLIE'S WARDROBE      %d bones" % Game.total_bones
	var lines := ""
	for i in range(shop_items.size()):
		var it: Dictionary = shop_items[i]
		var key: String = it.key
		var data: Dictionary = Game.COLLARS[key] if it.kind == "collar" else Game.BANDANAS[key]
		var equipped: bool = (it.kind == "collar" and Game.collar == key) or (it.kind == "bandana" and Game.bandana == key)
		var tag := ""
		if equipped:
			tag = "  [EQUIPPED]"
		elif Game.owned.get(key, false):
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
	if highlighted.kind == "collar":
		preview_collar = highlighted.key
	else:
		preview_bandana = highlighted.key
	shop_preview.set_cosmetic_preview(preview_collar, preview_bandana)


func _refresh_menu_text() -> void:
	# controller labels only when a controller is attached
	var pad := Input.get_connected_joypads().size() > 0
	hint_l.text = ("stick: move   A: dig in / squat   X: pee   B: bark   RB: turbo   Start: restart" if pad
		else "WASD: move   SPACE: dig in / squat   Q: pee   E: bark   SHIFT: turbo   R: restart")
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
				prompt_l.text = "%s / %s  browse     %s  choose     %s  wardrobe" % [_kb_or_pad("A", "<"), _kb_or_pad("D", ">"), go, _kb_or_pad("E", "B")]
			hint_l.visible = false
		2:
			prompt_l.text = "press  %s  to go walkies" % go
			hint_l.visible = true


func _hud_label(pos: Vector2, size_px: int) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_font_size_override("font_size", size_px)
	hud.add_child(l)
	return l


func _update_hud() -> void:
	hud_status = ""
	if phase == "freedom":
		if romp_done:
			hud_status = "walk back down to head home"
		else:
			hud_status = "FETCH!  bring it back  %d/%d   %ds left" % [romp_catches, romp_target, int(ceil(romp_timer))]
	elif phase == "home":
		if chase_active and chase_sweeper != null:
			if chase_kind == "both":
				hud_status = "EMERGENCY!  sprint home together - don't fight it!"
			elif chase_kind == "bolt":
				hud_status = "your human BOLTED - keep up and don't snag!"
			else:
				hud_status = "RUN!  keep the sweeper behind you - drag them along!"
		elif tofu_quest_active and not tofu_home:
			hud_status = "herd Tofu home - keep after her!"
		else:
			hud_status = "head home"
	elif poop_state == 1:
		hud_status = "GOTTA GO!  find a spot, hold %s" % _kb_or_pad("SPACE", "A")
	elif poop_state >= 3:
		hud_status = "UH OH..."
	elif pee >= 0.999:
		hud_status = "FULL!"
	elif pee <= 0.02:
		hud_status = "empty - find a fountain"
	# the level's goal list: lifetime progress in the header, then the
	# goals still open (plus any ticked off this run), capped for space
	var total := active_quests.size()
	var done_count: int = run_goals_hit.size() if Game.daily else Game.goals_count(lvl)
	var qlines := "GOALS  %d/%d" % [mini(done_count, total), total]
	var shown := 0
	for q in active_quests:
		var persisted: bool = (not Game.daily) and Game.goal_done(lvl, q.id)
		var hit: bool = run_goals_hit.has(q.id)
		if persisted and not hit:
			continue  # earned on a past run; keep the live list to what's left
		var line := ("[x] " if hit else "[ ] ") + _quest_text(q)
		if not hit and int(q.target) > 1:
			line += "  %d/%d" % [mini(int(q.fn.call()), int(q.target)), int(q.target)]
		qlines += "\n" + line
		shown += 1
		if shown >= 6:
			break
	quests_label.text = qlines
	# grow the card to fit however many lines we ended up showing
	qbg.size.y = 18.0 + float(shown + 1) * 21.0


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


func start_challenge(giver: Node2D, target: int, seconds: float) -> void:
	if challenge_offered or challenge.active:
		return
	challenge_offered = true
	challenge_giver = giver
	challenge.begin(target, seconds)
	shake_t = maxf(shake_t, 0.2)
	float_text(dog.global_position + Vector2(0, -26), "%d TRICKS - GO!" % target, Color(1, 0.9, 0.5))


func on_challenge_done(win: bool, target: int, count: int) -> void:
	if is_instance_valid(challenge_giver):
		challenge_giver.resolve(win)
	if win:
		var reward := 20 + target * 3
		bones += reward
		float_text(dog.global_position + Vector2(0, -30), "CHALLENGE! +%d" % reward, Color(0.8, 1.0, 0.85))
		_slowmo()
	else:
		float_text(dog.global_position + Vector2(0, -30), "so close - %d/%d" % [count, target], Color(1, 0.8, 0.6))


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
	if auto_walk:
		_auto_drive(delta)
	dog.tick(delta)
	human.tick(delta)
	# the human owns the retractable leash: length changes on their whim
	# ("click!" event), never the dog's
	leash_len = move_toward(leash_len, leash_target, 150.0 * delta)
	leash.rest_len = leash_len
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
	if phase == "freedom":
		_romp(delta)
		_neighbour_fetch()
	elif phase == "home" and chase_active:
		_chase(delta)
	_check_goals()
	_progress(delta)
	combo.tick(delta)
	challenge.tick(delta)
	_update_combo_hud()
	_update_challenge_hud()
	shake_t = maxf(0.0, shake_t - delta * 2.5)
	prize_glow += delta * 4.0


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()
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
			qbg.visible = true
			quests_label.visible = true
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
	if _redraw_acc >= 0.033 or shake_t > 0.0:
		_redraw_acc = 0.0
		queue_redraw()


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
	var shield := 1.0 / (1.0 + 0.3 * float(leash.contacts))
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
		human.velocity += h_dir * (base_tension * pulley / human_m) * delta
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
			var anchored: bool = dog.planted or leash.contacts > 0
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
				x = randf_range(SIDEWALK_LEFT + 40.0, SIDEWALK_RIGHT - 40.0)
				band_lo = SIDEWALK_LEFT + 30.0
				band_hi = SIDEWALK_RIGHT - 30.0
			else:
				x = randf_range(BLANE_L + 16.0, BLANE_R - 16.0)
				band_lo = BLANE_L + 14.0
				band_hi = BLANE_R - 14.0
		"park":
			kid = randf() < 0.7
			speed = randf_range(70.0, 120.0) if kid else randf_range(220.0, 320.0)
			x = randf_range(SIDEWALK_LEFT + 40.0, SIDEWALK_RIGHT - 40.0)
			band_lo = SIDEWALK_LEFT + 30.0
			band_hi = SIDEWALK_RIGHT - 30.0
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
		x = randf_range(SIDEWALK_RIGHT - 60.0, SIDEWALK_RIGHT - 25.0) if lvl == "street" else randf_range(1000.0, 1140.0)
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


func _make_pair(start: Vector2, direction: Vector2, activate := true) -> Node2D:
	var pair := Node2D.new()
	pair.set_script(load("res://otherpair.gd"))
	pair.setup(self, dog, poles, start, direction)
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


func _pairs(delta: float) -> void:
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
	# tangle feed: our rope and theirs each become obstacles for the other
	leash.dynamic_obstacles.clear()
	if leash.detached:
		_clear_detached_pair_tangles(pairs, delta)
		return
	my_rope_sample.clear()
	for i in range(0, leash.N, 2):
		my_rope_sample.append(leash.pts[i])
	for p in pairs:
		var crossing := false
		if not p.leash.visible:
			p.leash.dynamic_obstacles.clear()
		elif dog.global_position.distance_to(p.npc_owner.position) > 320.0:
			p.leash.dynamic_obstacles.clear()
		else:
			leash.dynamic_obstacles.append_array(p.sampled)
			p.leash.dynamic_obstacles = my_rope_sample.duplicate()
			crossing = _ropes_crossing(my_rope_sample, p.sampled)
		if p.update_tangle_state(crossing, delta):
			tangles += 1
			bones += 3
			combo.add("TANGLE", 3)
			float_text(dog.global_position, "TANGLED! +3", Color(1, 0.85, 0.7))


func _ropes_crossing(a: Array[Vector2], b: Array[Vector2]) -> bool:
	for pa in a:
		for pb in b:
			if pa.distance_squared_to(pb) < 289.0:  # ~17px
				return true
	return false


func _offpath(delta: float) -> void:
	# the dog may roam, but an undistracted owner has opinions: after a
	# few seconds off the walk they tut and reel the leash in a notch
	dog.sand_slow = lvl == "beach" and dog.global_position.x < 340.0
	var off: bool = dog.global_position.x < tut_l or dog.global_position.x > tut_r
	if off and human.is_available_for_chore() and not human.is_fallen():
		offpath_t += delta
		if offpath_t > 3.0:
			offpath_t = 0.0
			human.show_nag()
			set_leash_target(180.0)
	else:
		offpath_t = maxf(0.0, offpath_t - delta)


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
	if pond.size.x > 0.0:
		# Millie LOVES the water. In she goes, paddling happily - and
		# whatever is on the other end of the leash comes too. The owner
		# wades in reluctantly, phone held high, and edges back to the
		# bank. Nobody drowns; it is just wet and a little undignified.
		var dog_wet: bool = pond.grow(-4.0).has_point(dog.global_position)
		var was_swim: bool = dog.swimming
		dog.swimming = dog_wet
		if dog_wet and not was_swim:
			float_text(dog.global_position, "splish!", Color(0.7, 0.85, 1.0))
			swam = true
		var hum_wet: bool = pond.grow(-4.0).has_point(human.global_position)
		var was_wade: bool = human.wading
		human.wading = hum_wet
		human.pond_bank_x = pond.end.x + 24.0
		if hum_wet and not was_wade:
			float_text(human.global_position, "no no no-", Color(0.7, 0.85, 1.0))
	# open holes are the TOP tier of danger: falling in ends the walk,
	# full stop. Bumps hurt a little; holes hurt completely.
	# (auto_walk is a test/attract traversal - it is not allowed to die)
	if auto_walk:
		return
	for m in manholes:
		if human.global_position.distance_to(m) < 18.0 and not human.is_fallen():
			_death("THE HUMAN WENT DOWN THE MANHOLE\n\nThe phone gets reception down there. The walk does not.")
			return
		if dog.global_position.distance_to(m) < 15.0:
			_death("MILLIE WENT DOWN THE MANHOLE\n\nShe is fine. The walk is very over.")
			return
	for c in cellars:
		if c.has_point(human.global_position):
			_death("THE HUMAN FELL INTO THE CELLAR\n\nRight onto the delivery. The walk is over.")
			return
		if c.has_point(dog.global_position):
			_death("MILLIE FELL INTO THE CELLAR\n\nShe found the sausages. The walk is still over.")
			return


func _pickups(delta: float) -> void:
	if not prize_taken and prize_pos.x < INF and dog.global_position.distance_to(prize_pos) < 28.0:
		prize_taken = true
		bones += 8
		float_text(prize_pos, "got it! +8", Color(1, 0.9, 0.5))
	# carry mission: grab it, then take it to the drop-off
	if carry_pickup.x < INF:
		if carry_state == 0 and dog.global_position.distance_to(carry_pickup) < 28.0:
			carry_state = 1
			float_text(carry_pickup, "got %s!" % carry_item, Color(0.85, 1.0, 0.85))
			_update_hud()
		elif carry_state == 1 and dog.global_position.distance_to(carry_drop) < 34.0:
			carry_state = 2
			bones += 10
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
				combo.add("SNIFF", 2)
				float_text(h.pos, "good sniff +2", Color(1, 0.95, 0.7))
				_update_hud()
	for k in kebabs:
		if not k.eaten and dog.global_position.distance_to(k.pos) < 26.0:
			k.eaten = true
			bones += 1
			kebabs_eaten += 1
			combo.add("SNACK", 1)
			float_text(k.pos, "snack +1", Color(1, 0.95, 0.7))
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
				bones += 3
				marks.append(target)
				combo.add("MARK", 3)
				float_text(target, "marked! +3", Color(1, 0.95, 0.7))
				mark_progress = 0.0
				mark_target = Vector2(INF, INF)
				if marks.size() >= 5 and not mark_quest_done:
					mark_quest_done = true
					bones += 10
					float_text(dog.global_position, "territory secured +10", Color(0.8, 1.0, 0.8))
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
		float_text(dog.global_position, "relief +5", Color(0.8, 1.0, 0.8))
	else:
		float_text(dog.global_position, "couldn't wait", Color(1, 0.8, 0.6))
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
	return best


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
	romp_timer = 30.0
	romp_catches = 0
	romp_done = false
	ball = Node2D.new()
	ball.set_script(load("res://ball.gd"))
	ball.z_index = 10
	ball.position = human.global_position
	add_child(ball)
	ball.setup(self, dog, human, freedom_lo, GATE_Y - 30.0)
	# other dogs to romp and say hi to
	for i in range(3):
		var fd := Node2D.new()
		fd.set_script(load("res://freedog.gd"))
		fd.position = Vector2(randf_range(200.0, 1080.0), randf_range(freedom_lo + 40.0, GATE_Y - 60.0))
		fd.z_index = 9
		add_child(fd)
		fd.setup(self, dog, freedom_lo, GATE_Y - 30.0)
	float_text(dog.global_position, "OFF LEASH!  FETCH!", Color(0.8, 1.0, 0.8))


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
	wall_cats_spooked += 1
	bones += 2
	combo.add("SHOO", 3)
	float_text(pos + Vector2(0, -20), "scat! +2", Color(0.9, 0.95, 1.0))
	_update_hud()


func _spawn_challenger() -> void:
	# one combo-challenge giver per walk, lounging on the out leg where you
	# still have room and energy to show off
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
		float_text(dog.global_position, "time to head home", Color(1, 0.95, 0.7))


func on_tofu_home(pos: Vector2) -> void:
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
	combo.add("FETCH", reward)
	float_text(thrower.global_position, ("good girl! +%d" % reward) if mine else ("shared! +%d" % reward), Color(0.8, 1.0, 0.8))
	if mine and is_instance_valid(thrower):
		human.throw_pose()
	if romp_catches >= romp_target and not romp_done:
		romp_done = true
		bones += 10
		float_text(dog.global_position, "GOOD FETCH! +10", Color(0.7, 1.0, 0.75))
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
		chase_sweeper.setup(self, dog.global_position.y - CHASE_START_GAP, walk_cx, walk_half, spd)
		shake_t = 1.0
		if owner_flees:
			human.panic = true
		if chase_kind == "both":
			float_text(human.global_position, "FIRE ENGINE!  GO GO GO!", Color(1, 0.55, 0.25))
		elif chase_kind == "bolt":
			float_text(human.global_position, "AAH!  the owner BOLTED!", Color(1, 0.6, 0.3))
		else:
			float_text(dog.global_position, "THE STREET SWEEPER! RUN!", Color(1, 0.6, 0.3))
	else:
		float_text(dog.global_position, "let's go home", Color(1, 0.95, 0.7))


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
			_death("CAUGHT\n\nYou couldn't get the two of you clear in time.")
	elif chase_sweeper.caught(dog.global_position):
		if chase_kind == "sweeper":
			_death("SWEPT UP\n\nMillie disappeared into the brushes.\nSuspiciously clean about it, too.")
		else:
			_death("LEFT BEHIND\n\nYou snagged, the leash went taut, and\nnobody thought to wait.")


func _finish_walk() -> void:
	if dog.global_position.y > HOME_Y and human.global_position.y > HOME_Y:
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
		var qtext := ""
		for q in active_quests:
			var hit: bool = run_goals_hit.has(q.id)
			var had: bool = (not Game.daily) and Game.goal_done(lvl, q.id) and not hit
			qtext += ("[x]  " if hit else ("[.]  " if had else "[ ]  ")) + _quest_text(q) + "\n"
		var lifetime: int = run_done if Game.daily else Game.goals_count(lvl)
		var perfect := run_done >= total
		var rating := Game.star_str(Game.stars(lvl))
		if run_done == 0:
			rating += "   ...still a good dog."
		elif perfect:
			rating += "   PERFECT WALK - every goal!"
		var rec: Dictionary = Game.record_result("daily" if Game.daily else lvl, bones, elapsed, perfect)
		var rec_line := ""
		var star_gain: int = Game.stars(lvl) - run_pre_level_stars
		if star_gain > 0 and not Game.daily:
			rec_line += "+%d STAR%s!   " % [star_gain, "" if star_gain == 1 else "S"]
		if rec.bones_record:
			rec_line += "NEW BONES RECORD!   "
		if rec.time_record:
			rec_line += "BEST TIME!"
		if rec_line == "":
			rec_line = "goals this run: %d" % run_done
		rec_line += "\ngoals: %d/%d here    stars: %d total    bones: %d" % [lifetime, total, Game.total_stars(), Game.total_bones]
		if combo.best_mult >= 2:
			rec_line += "\nbest combo: x%d    style: %d" % [combo.best_mult, combo.run_style]
		var unlock_line := ""
		if not Game.daily:
			for other in Game.LEVELS:
				if Game.gate_crossed(run_pre_total_stars, other):
					unlock_line = "\n\nNEW WALK UNLOCKED: %s" % Game.LEVEL_NAMES[other]
		if Game.daily:
			_build_daily_card(run_done, total, rec)
		else:
			msg_label.text = "WALK COMPLETE\n\n%s\nGoals this run: +%d bones\n\nBones: %d    Phone: %d/3    Time: %ds\n%s%s\n\n%s\n\nPress %s for another walk" % [
				qtext, run_done * 5, bones, phone_hp, int(elapsed), rec_line, unlock_line, rating, _kb_or_pad("R", "Start")]


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
	if human.global_position.distance_to(pos) < 170.0:
		human.halt(0.8)
	for s in get_tree().get_nodes_in_group("squirrels"):
		if s.global_position.distance_to(pos) < 200.0:
			s.scare()
	for p in get_tree().get_nodes_in_group("pigeons"):
		if p.global_position.distance_to(pos) < 200.0:
			p.scare()
	for wc in get_tree().get_nodes_in_group("wallcats"):
		if wc.global_position.distance_to(pos) < 150.0:
			wc.scare()


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
	phone_hp -= 1
	streak = 0
	shake_t = 1.0
	_update_hud()
	float_text(pos, "PHONE CRACKED", Color(1, 0.45, 0.4))
	if phone_hp <= 0:
		frozen = true
		dim.visible = true
		msg_label.visible = true
		msg_label.text = "THE PHONE IS SHATTERED\n\nThe human is inconsolable. The walk is over.\n\nPress %s to try again" % _kb_or_pad("R", "Start")


func close_call(pos: Vector2) -> void:
	bones += 1
	close_calls += 1
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
	var top := GATE_Y - 800.0
	var bottom := START_Y + 320.0
	# cull to the camera: redrawing 5500px of detail lines every frame
	# was the browser stutter
	var vt: float = cam.position.y - 440.0
	var vb: float = cam.position.y + 440.0
	if lvl == "beach":
		# Passeig Maritim, west to east: sea, sand, boardwalk, bike
		# path, pavement, cafe strip, buildings
		draw_rect(Rect2(-400, top, 490, bottom - top), Color(0.25, 0.45, 0.55))
		var wt := Time.get_ticks_msec() / 1000.0
		var fy := top + 40.0
		while fy < bottom:
			if fy > vt and fy < vb:
				draw_line(Vector2(72 + sin(fy * 0.011 + wt * 1.5) * 9.0, fy), Vector2(84 + sin(fy * 0.013 + wt * 1.5) * 9.0, fy + 70.0), Color(1, 1, 1, 0.25), 3.0)
			fy += 150.0
		draw_rect(Rect2(90, top, 250, bottom - top), Color(0.87, 0.8, 0.66))
		draw_rect(Rect2(340, top, 140, bottom - top), Color(0.74, 0.66, 0.53))
		var py := START_Y + 200.0
		while py > GATE_Y:
			if py < vb and py > vt:
				draw_line(Vector2(340, py), Vector2(480, py), Color(0.66, 0.58, 0.45), 2.0)
			py -= 22.0
		draw_rect(Rect2(480, top, 80, bottom - top), Color(0.44, 0.24, 0.2))
		var ddy := START_Y + 200.0
		while ddy > GATE_Y:
			if ddy < vb and ddy > vt:
				draw_line(Vector2(520, ddy), Vector2(520, ddy - 26.0), Color(0.85, 0.82, 0.75, 0.5), 2.0)
			ddy -= 64.0
		draw_rect(Rect2(560, top, 420, bottom - top), Color(0.79, 0.76, 0.7))
		var sy := START_Y + 200.0
		while sy > GATE_Y:
			if sy < vb and sy > vt:
				draw_line(Vector2(560, sy), Vector2(980, sy), Color(0.71, 0.68, 0.62), 2.0)
			sy -= 150.0
		draw_rect(Rect2(980, top, 200, bottom - top), Color(0.76, 0.72, 0.65))
		draw_rect(Rect2(1180, top, 520, bottom - top), Color(0.35, 0.33, 0.31))
		draw_line(Vector2(340, bottom), Vector2(340, GATE_Y), Color(0.55, 0.45, 0.32), 3.0)
		draw_line(Vector2(480, bottom), Vector2(480, GATE_Y), COL_SEAM, 2.0)
		draw_line(Vector2(560, bottom), Vector2(560, GATE_Y), COL_SEAM, 2.0)
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
		draw_rect(Rect2(-400, top, 2100, bottom - top), grass)
		for t in tufts:
			if t.y > vt and t.y < vb:
				draw_circle(t, 5.0, COL_GRASS_DARK)
		# the walkway: sidewalk downtown, packed dirt in the park
		draw_rect(Rect2(SIDEWALK_LEFT, GATE_Y - 40.0, SIDEWALK_RIGHT - SIDEWALK_LEFT, bottom - GATE_Y), walkway)
		if lvl == "street" or lvl == "market":
			var y := START_Y + 200.0
			while y > GATE_Y:
				if y < vb and y > vt:
					draw_line(Vector2(SIDEWALK_LEFT, y), Vector2(SIDEWALK_RIGHT, y), COL_SEAM, 2.0)
				y -= 150.0
		draw_line(Vector2(SIDEWALK_LEFT, bottom), Vector2(SIDEWALK_LEFT, GATE_Y), COL_SEAM, 3.0)
		draw_line(Vector2(SIDEWALK_RIGHT, bottom), Vector2(SIDEWALK_RIGHT, GATE_Y), COL_SEAM, 3.0)
	# whatever lies beyond the gate
	draw_rect(Rect2(-400, top, 2100, GATE_Y - top), Color(0.27, 0.4, 0.27))
	for t in trees:
		draw_circle(t, 26.0, Color(0.22, 0.34, 0.22))
		draw_circle(t + Vector2(8, 6), 18.0, Color(0.25, 0.38, 0.24))
	if lvl == "street":
		# parallel bike lane + far shoulder
		draw_rect(Rect2(BLANE_L, GATE_Y - 40.0, BLANE_R - BLANE_L, bottom - GATE_Y), Color(0.4, 0.31, 0.29))
		draw_rect(Rect2(BLANE_R, GATE_Y - 40.0, SHOULDER_R - BLANE_R, bottom - GATE_Y), COL_SIDEWALK)
		var dy := START_Y + 200.0
		while dy > GATE_Y:
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
		# the pond, and the bridge planks squeezing past it
		draw_rect(pond.grow(14.0), Color(0.42, 0.4, 0.34))
		draw_rect(pond, Color(0.33, 0.45, 0.52))
		var wt := Time.get_ticks_msec() / 1000.0
		for i in range(4):
			var wy := pond.position.y + 70.0 + i * 105.0
			draw_arc(Vector2(pond.get_center().x + sin(wt * 0.7 + i) * 40.0, wy), 26.0, PI * 0.15, PI * 0.85, 10, Color(1, 1, 1, 0.14), 2.0)
		var px := pond.end.x + 8.0
		var py := pond.position.y
		while py < pond.end.y:
			draw_line(Vector2(px, py), Vector2(SIDEWALK_RIGHT, py), Color(0.5, 0.4, 0.28), 5.0)
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
	# manholes - open for street work; the cones are real nodes now
	for m in manholes:
		draw_circle(m, 24.0, Color(0.12, 0.12, 0.14))
		draw_arc(m, 19.0, 0, TAU, 24, Color(0.3, 0.3, 0.33), 2.0)
	# hydrants
	for h in hydrants:
		var c := Color(0.45, 0.4, 0.38) if h.done else Color(0.64, 0.26, 0.2)
		draw_circle(h.pos, 9.0, c)
		draw_circle(h.pos + Vector2(0, -8), 5.0, c.darkened(0.2))
		if not h.done and h.progress > 0.0:
			draw_arc(h.pos, 15.0, -PI / 2.0, -PI / 2.0 + TAU * h.progress / 0.8, 20, Color(1, 0.95, 0.7), 3.0)
	# kebabs
	for k in kebabs:
		if not k.eaten:
			draw_circle(k.pos, 7.0, Color(0.75, 0.55, 0.3))
			draw_line(k.pos + Vector2(-3, 5), k.pos + Vector2(4, -6), Color(0.5, 0.35, 0.2), 2.0)
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
	for i in range(deco_pole_count):
		var p := poles[i]
		if p.y < vt - 60.0 or p.y > vb + 60.0:
			continue
		if lvl == "park":
			draw_circle(p, 56.0, Color(0.2, 0.35, 0.2, 0.3))
			draw_circle(p + Vector2(12, 10), 38.0, Color(0.22, 0.38, 0.21, 0.3))
			draw_circle(p, POLE_RADIUS, Color(0.4, 0.3, 0.2))
			draw_circle(p, 4.0, Color(0.32, 0.24, 0.16))
		elif lvl == "beach":
			draw_circle(p + Vector2(10, 10), 30.0, Color(0, 0, 0, 0.12))
			for j in range(6):
				var fa := TAU * j / 6.0 + p.x * 0.01 + p.y * 0.007
				draw_line(p, p + Vector2.from_angle(fa) * 36.0, Color(0.27, 0.44, 0.24, 0.85), 5.0)
			draw_circle(p, 7.0, Color(0.45, 0.35, 0.22))
		elif p.x > SIDEWALK_LEFT + 60.0 and p.x < SIDEWALK_RIGHT - 60.0:
			# mid-walkway poles are street trees in grates - that is WHY
			# they stand in the middle of a sidewalk
			draw_rect(Rect2(p.x - 15, p.y - 15, 30, 30), Color(0.3, 0.3, 0.33), false, 2.0)
			draw_circle(p, 34.0, Color(0.28, 0.42, 0.26, 0.4))
			draw_circle(p, POLE_RADIUS - 2.0, Color(0.4, 0.3, 0.2))
		else:
			# lamppost: four bulbs on cross arms and a warm halo - an
			# actual light source, brightest at night
			var halo_a := 0.32 if Game.night else 0.1
			draw_circle(p, 62.0, Color(1.0, 0.9, 0.6, halo_a))
			draw_circle(p, POLE_RADIUS + 3.0, Color(0.2, 0.2, 0.22, 0.35))
			draw_circle(p, POLE_RADIUS, Color(0.44, 0.44, 0.48))
			for bo in [Vector2(10, 0), Vector2(-10, 0), Vector2(0, 10), Vector2(0, -10)]:
				draw_line(p, p + bo, Color(0.5, 0.5, 0.55), 2.5)
				draw_circle(p + bo * 1.35, 3.5, Color(0.98, 0.93, 0.7))
	# trash bins: green, lidded, with a visible mouth - the ONLY thing
	# the owner will throw a bag into
	for bn in bins:
		draw_circle(bn, 11.0, Color(0.24, 0.32, 0.26))
		draw_circle(bn, 8.0, Color(0.32, 0.45, 0.34))
		draw_arc(bn, 8.0, PI * 0.15, PI * 0.85, 10, Color(0.14, 0.2, 0.16), 3.5)
		draw_circle(bn, 3.2, Color(0.08, 0.12, 0.1))
		draw_line(bn + Vector2(-5, 0), bn + Vector2(5, 0), Color(0.55, 0.66, 0.56), 2.0)
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
	for v in vans:
		for w in [Vector2(-36, -44), Vector2(30, -44), Vector2(-36, 30), Vector2(30, 30)]:
			draw_rect(Rect2(v.x + w.x, v.y + w.y, 6, 16), Color(0.12, 0.12, 0.14))
		draw_rect(Rect2(v.x - 32, v.y - 66, 64, 132), Color(0.88, 0.88, 0.86))
		draw_rect(Rect2(v.x - 32, v.y - 66, 64, 132), Color(0.55, 0.55, 0.55), false, 2.0)
		draw_rect(Rect2(v.x - 26, v.y - 60, 52, 22), Color(0.35, 0.42, 0.5))
		draw_line(v + Vector2(-24, 62), v + Vector2(24, 62), Color(0.6, 0.3, 0.25), 3.0)
	# El Gotic: laundry strung across the alley overhead, a lantern or two
	if lvl == "oldtown":
		var lt := Time.get_ticks_msec() / 1000.0
		var wash := [Color(0.8, 0.3, 0.35), Color(0.3, 0.5, 0.7), Color(0.9, 0.85, 0.6), Color(0.4, 0.65, 0.5)]
		for i in range(laundry_lines.size()):
			var ly: float = laundry_lines[i]
			draw_line(Vector2(SIDEWALK_LEFT - 20.0, ly), Vector2(SIDEWALK_RIGHT + 20.0, ly - 8.0), Color(0.2, 0.18, 0.16), 1.5)
			for j in range(5):
				var hx := lerpf(SIDEWALK_LEFT + 20.0, SIDEWALK_RIGHT - 20.0, float(j) / 4.0)
				var sway := sin(lt * 1.2 + j + i) * 2.0
				draw_rect(Rect2(hx - 9.0, ly - 6.0, 18.0, 26.0 + sway), wash[(i + j) % wash.size()])
		# lanterns down one wall
		for i in range(laundry_lines.size()):
			var lyy: float = laundry_lines[i] + 380.0
			var glow := 0.6 + 0.25 * sin(lt * 3.0 + i)
			draw_circle(Vector2(SIDEWALK_LEFT + 6.0, lyy), 6.0, Color(1.0, 0.8, 0.4, glow))
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
	if vt < GATE_Y + 60.0:
		var yl := 70.0
		var yr := 1180.0
		var ytop := freedom_lo
		var ybot := GATE_Y - 30.0
		draw_rect(Rect2(yl, ytop, yr - yl, ybot - ytop), Color(0.34, 0.5, 0.32))
		# scattered grass tufts + a worn dirt patch in the middle (play area)
		draw_circle(Vector2((yl + yr) / 2.0, (ytop + ybot) / 2.0), 150.0, Color(0.42, 0.44, 0.3, 0.35))
		for tf in range(28):
			var gxp := yl + 20.0 + tf * ((yr - yl - 40.0) / 27.0)
			var gyp := ytop + 40.0 + fmod(tf * 137.0, ybot - ytop - 80.0)
			draw_line(Vector2(gxp, gyp), Vector2(gxp - 3.0, gyp - 8.0), Color(0.28, 0.44, 0.27), 2.0)
			draw_line(Vector2(gxp, gyp), Vector2(gxp + 3.0, gyp - 7.0), Color(0.28, 0.44, 0.27), 2.0)
		# chain-link fence: rail + posts on all four sides, open at the gate
		var fence := Color(0.62, 0.63, 0.6)
		var post := Color(0.5, 0.5, 0.48)
		var mesh := Color(0.66, 0.68, 0.66, 0.25)
		# side rails
		draw_line(Vector2(yl, ytop), Vector2(yl, ybot), fence, 3.0)
		draw_line(Vector2(yr, ytop), Vector2(yr, ybot), fence, 3.0)
		# top rail
		draw_line(Vector2(yl, ytop), Vector2(yr, ytop), fence, 3.0)
		# bottom rail, split around the gate opening
		draw_line(Vector2(yl, ybot), Vector2(gate_l - 20.0, ybot), fence, 3.0)
		draw_line(Vector2(gate_r + 20.0, ybot), Vector2(yr, ybot), fence, 3.0)
		for px in range(int(yl), int(yr), 60):
			draw_line(Vector2(px, ytop), Vector2(px, ytop + 8.0), post, 2.0)
			if px < gate_l - 20.0 or px > gate_r + 20.0:
				draw_line(Vector2(px, ybot - 8.0), Vector2(px, ybot), post, 2.0)
		draw_line(Vector2(yl + 6.0, ytop + 6.0), Vector2(yr - 6.0, ytop + 6.0), mesh, 6.0)
		# posts at the four corners
		for cp in [Vector2(yl, ytop), Vector2(yr, ytop), Vector2(yl, ybot), Vector2(yr, ybot)]:
			draw_circle(cp, 4.0, post)
		# human benches along the fence
		for bx in [Vector2(yl + 70.0, ytop + 60.0), Vector2(yr - 70.0, ytop + 120.0), Vector2(yl + 90.0, ybot - 80.0)]:
			draw_rect(Rect2(bx.x - 22, bx.y - 5, 44, 10), Color(0.5, 0.38, 0.26))
			draw_line(Vector2(bx.x - 20, bx.y - 5), Vector2(bx.x - 20, bx.y + 8), Color(0.42, 0.32, 0.22), 2.0)
			draw_line(Vector2(bx.x + 20, bx.y - 5), Vector2(bx.x + 20, bx.y + 8), Color(0.42, 0.32, 0.22), 2.0)
		# the owner's waiting bench (where the parked owner throws from)
		draw_rect(Rect2(gate_bench.x - 18, gate_bench.y - 6, 36, 11), Color(0.54, 0.4, 0.27))
		draw_string(font, Vector2((yl + yr) / 2.0 - 70.0, ytop - 14), "OFF-LEASH DOG PARK", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.9, 0.9, 0.82))
	# the gate between the walk and the off-leash yard
	draw_rect(Rect2(gate_l - 14, GATE_Y - 46, 14, 60), Color(0.35, 0.3, 0.28))
	draw_rect(Rect2(gate_r, GATE_Y - 46, 14, 60), Color(0.35, 0.3, 0.28))
	draw_rect(Rect2(gate_l - 14, GATE_Y - 58, gate_r - gate_l + 28, 14), Color(0.35, 0.3, 0.28))
	draw_string(font, Vector2((gate_l + gate_r) / 2.0 - 40.0, GATE_Y - 66), gate_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(0.9, 0.88, 0.8))
	var gx := gate_l
	while gx < gate_r:
		draw_line(Vector2(gx, GATE_Y), Vector2(gx + 16.0, GATE_Y), Color(0.9, 0.88, 0.8, 0.6), 3.0)
		gx += 32.0
	# HOME, at the bottom, where the walk both begins and ends
	if vb > START_Y + 30.0:
		draw_rect(Rect2(gate_l - 14, HOME_Y + 40.0, gate_r - gate_l + 28, 14), Color(0.4, 0.32, 0.3))
		draw_string(font, Vector2((gate_l + gate_r) / 2.0 - 40.0, HOME_Y + 78.0), "HOME", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(0.9, 0.85, 0.7))
	# start hint
	var hint_txt := "To the park and back. Mind the bike lanes."
	if lvl == "park":
		hint_txt = "Through the park to the meadow, then home. Mind the pond."
	elif lvl == "beach":
		hint_txt = "Along the passeig and back. Mind the bike path."
	elif lvl == "market":
		hint_txt = "Through the market to the plaza, then home."
	draw_string(font, Vector2(430, START_Y + 90), hint_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(1, 1, 1, 0.5))
