extends Node2D

# Path of Leash Resistance.
# You play the dog. Walk the phone-zombie human through it with the
# phone intact.

# The walkable corridor. These used to be fixed constants, which is why
# every walk had identical proportions no matter how differently it was
# dressed. They are now derived from walk_cx/walk_half, so each level sets
# ONE width dial and both the pavement and the gameplay bounds follow: a
# tight medieval alley genuinely pinches, a station concourse genuinely
# opens out. (Set in _apply_corridor, per level.)
var sw_l := 300.0
var sw_r := 980.0
# THE CROSS-SECTION either side of the walk (#65): pavement | strip | the
# building line. Set per walk in LevelBuild.apply_corridor. A strip is "grass",
# "sidewalk" or "none" (buildings straight onto the paving, as in an alley).
# built is false on the green walks and the seafront, which keep their verge
# out to the level edge and have no building line.
var built := false
# the intro is playing over the title (intro/intro_player.gd)
var intro_playing := false
# Montjuic's wind (systems/montjuic.gd): its own RNG, the next gust, the
# telegraph and the gust itself
var wind_rng := RandomNumberGenerator.new()
var wind_rng_seeded := false
var wind_next := 0.0
var wind_warn := 0.0
var wind_gust := 0.0
var wind_dir := Vector2.RIGHT
# Montjuic's telefèric (systems/cable_car.gd): the stations and the dropped
# ticket, whether she has it, and the ride under way
var cable_low := Vector2.ZERO
var cable_top := Vector2.ZERO
var cable_ticket_pos := Vector2.ZERO
var cable_ticket := false
var cable_ticket_taken := false
var cable_riding := false
var cable_up_done := false
var cable_down_done := false
var cable_from := Vector2.ZERO
var cable_to := Vector2.ZERO
var cable_t := 0.0
var cable_rides := 0
# where --shot-cam points the camera (INF: follow the pair as usual)
var shot_cam := Vector2(INF, INF)
var strip_l := 0.0
var strip_r := 0.0
var strip_kind_l := "none"
var strip_kind_r := "none"
# The corridor's shape down the level: a short list of {y, cx, half} control
# nodes (edge_path.gd). Empty = the straight corridor sw_l..sw_r. Ask
# walk_edges(y) rather than sw_l/sw_r anywhere the answer depends on WHERE
# you are, or the path and the thing testing against it will disagree the
# moment a level bends.
var edge_nodes: Array = []
# every solid rectangle LevelBuild.add_rect_body made (stall blocks, the
# salamander, dumpsters...), for placing loose things clear of them
var solid_rects: Array[Rect2] = []
# parallel bike lane along the right side, plus a narrow far shoulder
# with temptations - crossing the lane is a voluntary risk
# the hang-time beat on big moments: game speed, and how long it lasts in
# real time
const SLOWMO_SCALE := 0.3
const SLOWMO_SECS := 0.35
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
# the walks with riders along the path (_vlane has a case for each)
const VLANE_LEVELS := ["street", "park", "beach", "market"]
const LEASH_LENGTH := 340.0  # a proper 5-meter leash
const LEASH_STRETCH_CAP := 1.15
const LEASH_K := 32.0
const DOG_MASS := 1.0
const HUMAN_MASS := 4.0
# how much planting multiplies the dog's mass in the tug: dug in on dry
# ground, on wet ground, and on packed snow, where she skids a long way
const PLANT_GRIP := 14.0
const PLANT_GRIP_WET := 9.0
const PLANT_GRIP_ICE := 5.0
# The whirl's arming (_apply_leash). The rope must be wound, at the owner's
# end, on a real pole within reach, and stay that way for WHIRL_ARM_T before
# the orbit starts - walking past a pole briefly curves the rope and must not
# trigger. WHIRL_SLIP keeps the rope free-slipping for the choreographed
# unwind, and WHIRL_SLIP_BAIL does the same while she staggers out of one.
const WHIRL_ARM_T := 0.25
const WHIRL_ARM_EXCESS := 8.0
const WHIRL_ARM_WIND := 0.55
const WHIRL_ARM_END_WIND := 2.4
const WHIRL_ARM_RANGE := 70.0
const WHIRL_SLIP := 0.7
const WHIRL_SLIP_BAIL := 0.5
# a planted dog dragged at least this far in a frame is skidding, and leaves
# paw furrows that fade over SKID_LIFE seconds, at most SKID_MAX of them
const SKID_MIN := 0.25
const SKID_LIFE := 8.0
const SKID_MAX := 120
const SwingMath := preload("res://systems/swing.gd")
const Mood := preload("res://systems/mood.gd")
const Surfaces := preload("res://world/surfaces.gd")
const EventFeed := preload("res://hud/event_feed.gd")
const EdgePath := preload("res://world/edge_path.gd")
const TangleGeom := preload("res://systems/tangle_geom.gd")
const MoodWiring := preload("res://systems/mood_wiring.gd")
const HomeChase := preload("res://systems/home_chase.gd")
const Goals := preload("res://systems/goals.gd")
const HudBuild := preload("res://hud/hud_build.gd")
const MenuFlow := preload("res://hud/menu_flow.gd")
const Rails := preload("res://systems/rails.gd")
const CableCar := preload("res://systems/cable_car.gd")
const UiScale := preload("res://hud/ui_scale.gd")
const LevelBuild := preload("res://world/level_build.gd")
const WorldSign := preload("res://world/world_sign.gd")
const PopsLayer := preload("res://world/pops_layer.gd")
# float_text(..., POP_SAY) draws a speech bubble rather than a sound or a score
const POP_SAY := 0
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
# a sidewalk strip between the walk and the buildings (#65)
const STRIP_SIDEWALK := Color(0.63, 0.61, 0.57)
const STRIP_JOINT := Color(0.52, 0.50, 0.47, 0.6)
const STRIP_KERB := Color(0.47, 0.46, 0.44)
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
var gate_text := "PIPICÀ"
var duck_ys: Array[float] = []
var boars_out := false
# where the path splits round something: {"rect", "side"}. The owner keeps
# to that side of it (+1 east, -1 west); see human._walk
var islands: Array[Dictionary] = []
# solid posts standing off the path (El Parc's bandstand), drawn by their walk
var park_posts: Array[Vector2] = []
# where the owner is kept to a narrow line across the path (Les Obres' plank
# over the trench): {"y0", "y1", "x0", "x1"}; see human._walk
var narrows: Array[Dictionary] = []
# El Gotic's parked scooters (they are also rope poles), drawn by their walk
var scooters: Array[Vector2] = []
# where it is dry (El Diluvi's arcade and awnings), and how wet the owner is
var shelters: Array[Rect2] = []
var human_soak := 0.0          # 0 dry, 1 wet through
# L'Estacio: where she got on the walkway (INF off it), and full rides
var walkway_from := INF
var walkway_rides := 0
var splashes := 0
var splash_cd := 0.0
# out in it, the owner soaks through in SOAK_T seconds; under cover, dries in DRY_T
const SOAK_T := 150.0
const DRY_T := 40.0
const SPLASH_SPEED := 250.0
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
# what each stall sells, where a walk says ("kiosk", "flowers", ...); empty
# is the market's produce stall
var stall_kinds: Array[String] = []
# La Rambla: sellers' blankets {"rect", "goods", "cd"} and the human statues
var blankets: Array[Dictionary] = []
var statues: Array[Vector2] = []
var statue_wait: Dictionary = {}     # index -> how long she has stood watching
var statue_bow: Dictionary = {}      # index -> time left on the bow
# the shell game: {"pos", "done", "t"}; empty where there is none
var shell_game: Dictionary = {}
var whistle_t := WHISTLE_FIRST
# La Rambla's crowd and its pickpockets (entities/tourist.gd, pickpocket.gd).
# The crowd has its own RNG so it never shifts the global sequence.
var crowd_rng := RandomNumberGenerator.new()
var crowd_seeded := false
var pp_spawn_t := PP_FIRST
var pp_spawned := 0
# El Mosaic's standing groups, out once each walk, and the salamander's "aww"
var mosaic_queue_out := false
var mosaic_posers_out := false
var mosaic_aww := false
var thieves_stopped := 0
var wallets_returned := 0
var owner_wallet_taken := false      # he has it right now
var owner_wallet_lost := false       # and he got away with it, or it went down a drain
var fountains: Array[Vector2] = []
var body_pole_count := 0
var bypasser_blockers: Array[Dictionary] = []
var drunk_amount := 0.0
# what the "drink" goal asks for, and whether she has been told she managed it
const DRINK_ENOUGH := 0.4
var drink_praised := false
var lap_t := 0.0
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
const TutorialSteps := preload("res://systems/tutorial.gd")
const UiIcons := preload("res://hud/ui_icons.gd")
var tutorial_mode := false
var tut_step := 0
# where the owner stands to wait, this far south of the lesson's station
const TUT_HOLD_BACK := 150.0
# how far in from the path's edge a lesson's "stand" puts the waiting owner
const TUT_STAND_IN := 60.0
var tut_plant_t := 0.0
var tut_teetered := false
var tut_flash := 0.0
var tut_start_y := 0.0
var tut_label: Label
var tut_hint: Label
# counters the tutorial checks against
var barks_done := 0
var grinds_landed := 0
var vaults_landed := 0
var rivals_beaten := 0
# the grind (see grind.gd): ride a grindable for style
var grind: Node
# the walk's grindables (systems/rails.gd), and which one she is on
var grind_rail := -1
var rails: Array[Dictionary] = []
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
# the off-leash games (systems/freedom_games.gd)
var agility: AgilityCourse
var agility_prev := Vector2.ZERO
var agility_runs := 0
var games_ground: Node2D
var games_cover: Node2D
var frisbee: Node2D
var frisbee_done := false
var frisbee_air := 0
var tug: RopeTug
var tug_dog: Node2D
var tug_prev := Vector2.ZERO
var tugs_won := 0
var rope_loose := Vector2(INF, INF)
var rope_carry_t := 0.0
var hop_t := 0.0
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
# the closest the machine has come to the dog or the human this chase (px);
# INF until it starts. The "outrun" goal reads it.
var chase_min_gap := INF
# seconds left of the catch beat: the machine rolls over whoever it caught
# before the card comes up (systems/home_chase.gd)
var chase_catch_t := 0.0
var chase_catch_msg := ""
# how far the camera leans back up the street to keep the machine in shot
var chase_lean := 0.0
# the brooms have come within a whisker; getting clear again is a CLOSE SHAVE
var chase_shave_armed := false
# where this walk's sweeper snags a broom on a dumpster and stalls (level data)
var chase_jams: Array[Vector2] = []
var chase_kerb_blocks: Array[Rect2] = []
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
# the west wall's x on the beach, out in the sea (LevelBuild.build_walls)
const FREEDOM_WALL_W := -180.0
# how quickly the camera's x catches up when it starts or stops following her
# sideways (it eases, so crossing the gate never jumps the view)
const CAM_X_EASE := 5.0
var cam_x_now := 1e9
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
	"sand":     {"col": Color(0.80, 0.72, 0.52), "life": 3.2, "quip": "SANDY PAWS!"},
	"fish":     {"col": Color(0.62, 0.68, 0.60), "life": 3.0, "quip": "FISHY PAWS!"},
	"slush":    {"col": Color(0.78, 0.82, 0.88), "life": 2.0, "quip": "SLUSHY PAWS!"},
	"confetti": {"col": Color(0.92, 0.55, 0.75), "life": 2.8, "quip": "COVERED IN CONFETTI!"},
	"oil":      {"col": Color(0.20, 0.19, 0.22), "life": 3.2, "quip": "OILY PAWS!"},
	"puddle":   {"col": Color(0.42, 0.50, 0.58), "life": 1.4, "quip": "WET PAWS!"},
	"icecream": {"col": Color(0.96, 0.72, 0.78), "life": 2.6, "quip": "STICKY PAWS!"},
}
var substance_zones: Array[Dictionary] = []
var paw_prints: Array[Dictionary] = []
# FOOTPRINTS PRESSED INTO THE GROUND: sand, and any ground under snow, takes
# the shape of whatever walks on it. Hers and his, fading as it fills back in.
# Separate from paw_prints, which is what a wet paw LEAVES on dry ground.
var dents: Array[Dictionary] = []
# what her paws do to the ground as she goes (_ground_marks): grass she
# flattens springs back, mud she runs through flies up, water she steps into
# rings out. Pooled and capped at MARKS_MAX, deterministic, cosmetic only.
var ground_marks: Array[Dictionary] = []
var mark_last := Vector2(INF, INF)
var mark_surface := -1
var squelch_t := 0.0
const MARKS_MAX := 24
const FLAT_LIFE := 2.5
const SPLAT_LIFE := 1.2
const RING_LIFE := 1.0
var dent_last_dog := Vector2(INF, INF)
var dent_last_human := Vector2(INF, INF)
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
# goals completed this run (ids), for scoring/toasts/results independent
# of persistence; plus the star snapshot captured when the walk begins
var run_goals_hit := {}
# goals ticked for the first time ever on this walk (the loss card counts them)
var run_goals_new := 0
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
# Her coil, SIGNED, added up over the arming frames, and how many of them. One
# number for both halves of the decision: a window that keeps changing its mind
# nets out to nearly nothing, and nearly nothing is what there is to take off -
# votes for the way round counted separately from how wound she was would read a
# contested coil as a busy one and send her round as far as a coil that never
# wavered.
var whirl_coil_acc := 0.0
var whirl_arm_n := 0
var vault_recent := 0.0

var leash_len := LEASH_LENGTH
# set when the owner is deliberately hauling the leash in (the nag), which
# may shorten a taut rope; a plain reel click only takes up slack
var leash_haul := false
const NAG_WARN := 0.8
var nag_haul_t := 0.0
var leash_target := LEASH_LENGTH
var started := false
var bones := 0
var streak := 0
var phone_hp := 3
# a first-time tip on the banner (systems/tips.gd), and how long it has left
var tip_text := ""
var tip_t := 0.0
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
# Brutus, while he is about (off the leash, some walks)
var rival: Node2D = null
# when she came through the gate this visit
var freedom_at := 0.0
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
# camera shake draws from its own RNG: it runs per rendered frame, and the
# global sequence has to stay the simulation's alone. Fixed seed: the shake
# lands in cam.offset, which get_screen_center_position() includes, and the
# pair spawner reads that - an unseeded shake made the autowalk vary run to run
const SHAKE_SEED := 0x5AFE
var _shake_rng := RandomNumberGenerator.new()

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
# every menu screen (hud/menu_screen.gd) and where the cursor is on the ones
# with rows; locked_nudge shakes whatever refused a press
var menu_screen: Control
# the walk's name and HOME, made of loose things on the ground
# (world/world_sign.gd); rebuilt when the menu step changes what it says
var signs: Array[Dictionary] = []
var _signs_for := ""
# counts rebuilds of `signs`, so their canvas knows the pieces are new
var signs_built := 0
# the signs' own cached canvas (world/sign_layer.gd)
var sign_layer: Node2D
# the gloss under the name is menu text: it fades as the walk begins
var gloss_a := 1.0
var details_idx := 0
var pause_idx := 0
# a question the menus are waiting on ("restart", "exit"), and which pause
# card is open over the grid ("walk"); empty when neither
var confirm_id := ""
# the tutorial's halfway card has been answered "the tricks", and how long
# the last card has been up (the tutorial ends itself after it)
var tut_basics_seen := false
# the window's content scale factor on a small screen (hud/ui_scale.gd); the
# camera's zoom is divided by it, so only the interface grows
var ui_scale := 1.0
# the HUD meter the current lesson uses ("tank", "zoomies"), outlined on the
# card while the lesson is up; "" for none
var hud_point := ""
var tut_done_t := 0.0
var pause_view := ""
var locked_nudge := 0.0
var shop_preview: CharacterBody2D
var in_shop := false
var shop_items: Array[Dictionary] = []
var shop_idx := 0
var msg_label: Label
var combo: Node
# the dog's mood: arrives from events, fades on its own, re-colours both the
# picture and the handling while it lasts (mood.gd)
var mood: Node
# the one channel for announcements about the state of the walk
var feed: Control
# latch for the run-yourself-empty trigger, so hitting empty is a moment
# rather than a condition (see systems/mood_wiring.gd)
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
var grade_rect: ColorRect
var _shot_done := false
var _shot_frames := 0
var _shot_at := 320
# --soak[=SECONDS]: start a walk, touch nothing, count what happens to the
# dog, print one SOAK line and quit. See tools/idle_soak.sh.
var _soak_secs := 0.0
var _soak_frames := 0
var _soak_t0 := -1.0
var _soak_knocks := {}
var _soak_moods := {}
var _soak_last_mood := 0
var _soak_cracks := 0
var _draw_cost_on := false
var _draw_us := 0
var _draw_n := 0
# microseconds the most recent world draw took, while --drawcost (or the perf
# probe, which turns it on) is timing draws
var last_draw_us := 0
# per-subsystem physics timing for the perf probe: _prof("name") charges the
# time since the previous mark to that name. Off (one bool test) unless --perf.
var _prof_on := false
var _prof_t := 0
var prof_us := {}
# scattered ground detail (cracks, litter, stones, stains) so hard surfaces
# stop reading as empty colour fields. Built with a LOCAL rng so it never
# perturbs the global seed the deterministic autowalk depends on.
var ground_detail: Array[Dictionary] = []
var in_progress_view := false
var in_settings := false
var settings_idx := 0
var settings_panel: Control
var rotate_prompt: CanvasLayer
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


# every script something spawns after the level is built (see _ready)
const MIDWALK_SCRIPTS := [
	"res://entities/ball.gd", "res://entities/freedog.gd", "res://entities/rival.gd",
	"res://entities/tofu.gd", "res://entities/sweeper.gd", "res://entities/otherpair.gd",
	"res://entities/bike.gd", "res://entities/squirrel.gd", "res://entities/pigeon.gd",
	"res://entities/duckling.gd", "res://entities/boar.gd", "res://entities/tourist.gd",
	"res://entities/pickpocket.gd",
]


func _ready() -> void:
	Engine.time_scale = 1.0
	font = ThemeDB.fallback_font
	var autowalk_requested := "--autowalk" in OS.get_cmdline_user_args()
	if "--no-exit" in OS.get_cmdline_user_args():
		MenuFlow.exit_hidden = true
	_shake_rng.seed = SHAKE_SEED
	if Game.is_daily(Game.level_id):
		# same layout, weather and time for everyone, all day
		Game.daily = true
		seed(Game.daily_seed())
		lvl = Game.daily_level()
		Game.weather = Game.daily_weather()
		Game.night = Game.daily_night()
	elif Game.is_tutorial(Game.level_id):
		# THE FIRST WALK: El Barri laid out as one station per lesson, calm and
		# safe by construction - no traffic to dodge, no chase, no other
		# walkers, and a bright clear day. Nothing here can end your walk.
		Game.daily = false
		tutorial_mode = true
		lvl = "barri"
		Game.weather = "clear"
		Game.night = false
	else:
		Game.daily = false
		if autowalk_requested:
			seed(AUTOWALK_SEED)
		# --seed=N pins every random layout and spawn, so a soak or a bug
		# report can be replayed exactly
		for a in OS.get_cmdline_user_args():
			if a.begins_with("--seed="):
				seed(int(a.substr(7)))
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
	Rails.build(self)
	_build_entities()
	if lvl == "montjuic":
		CableCar.build(self)
	_spawn_cones()
	_build_quests()
	UiScale.apply(self)
	get_tree().root.size_changed.connect(_on_window_resized)
	_build_hud()
	_spawn_challenger()
	_spawn_wallcats()
	_spawn_guards()
	# Scripts first needed mid-walk are compiled now, while the level loads
	# anyway: load() keeps them, so the later load() calls cost nothing.
	# Compiling ball.gd, freedog.gd and rival.gd on the spot was a 36-49 ms
	# hitch at the gate, and tofu.gd and the sweeper hitched the way home.
	for path in MIDWALK_SCRIPTS:
		load(path)
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
	# whether this walk gets a chase on the way home: systems/home_chase.gd
	HomeChase.roll(self)
	_draw_cost_on = "--drawcost" in OS.get_cmdline_user_args()
	for a in OS.get_cmdline_user_args():
		if a == "--soak":
			_soak_secs = 30.0
		elif a.begins_with("--soak="):
			_soak_secs = maxf(1.0, float(a.substr(7)))
		elif a == "--perf" or a.begins_with("--perf="):
			# frame-time probe; see dev/perf_probe.gd and tools/perf_sweep.sh
			var probe := Node.new()
			probe.set_script(load("res://dev/perf_probe.gd"))
			probe.setup(self, float(a.substr(7)) if a.begins_with("--perf=") else 60.0)
			add_child(probe)
	menu_step = Game.menu_step
	_apply_menu_step()
	build_signs()
	# "try again" and "start again" come straight back into the walk
	if Game.quick_start:
		Game.quick_start = false
		MenuFlow.start_walk(self)
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
	# the intro, on a plain launch, once a session (intro/intro_player.gd)
	if not started and IntroPlayer.should_play(self):
		IntroPlayer.play(self)
	# --selftest: validate the level we just built and exit. Runs inside the
	# real runtime (autoloads and all), so CI can sweep every walk for
	# content mistakes a pure-logic test cannot see.
	if "--selftest" in OS.get_cmdline_user_args():
		var problems: Array = load("res://world/level_check.gd").check(self)
		problems.append_array(_check_settings_roundtrip())
		for pr in problems:
			print("SELFTEST FAIL [%s] %s" % [lvl, pr])
		if problems.is_empty():
			print("SELFTEST OK [%s]" % lvl)
		get_tree().quit(1 if not problems.is_empty() else 0)


# a small screen gets a bigger interface, the same walk (hud/ui_scale.gd)
func _on_window_resized() -> void:
	UiScale.apply(self)


# the soundtrack: the loop that belongs on screen now (see Sfx.music_tick)
func _music_cue() -> String:
	if intro_playing:
		return ""
	if not started:
		return "title"
	if finished:
		return "won"
	# frozen and not paused, mid-walk: a card the walk ended on
	if frozen and not paused:
		return "lost"
	if phase == "freedom":
		return "freedom"
	return Music.walk_style(lvl)


# ...and the one to have ready for when it changes
func _music_next() -> String:
	# the intro is silent and the title theme is next: built while it plays
	if intro_playing:
		return "title"
	if not started:
		return Music.walk_style(lvl)
	if phase == "freedom":
		return Music.walk_style(lvl)
	return "freedom" if phase != "home" else ""


func _input(event: InputEvent) -> void:
	# the prompts follow whichever device the player last used; text set once
	# (the pause menu, a death card) is re-filled, and the title's is rebuilt
	if Prompts.note(event):
		Prompts.refresh()


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
	LevelBuild.apply_corridor(self)


func _fit_x(x: float, lo: float, hi: float) -> float:
	return LevelBuild.fit_x(self, x, lo, hi)


func _fit_props_to_corridor() -> void:
	LevelBuild.fit_props_to_corridor(self)


func _build_level_data() -> void:
	LevelBuild.build_level_data(self)


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
		"park", "trail", "barri":
			return       # dirt and gravel, not slabs
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
				_wc.draw_rect(Rect2(x0, y, x1 - x0, sh - 2.0), slab)
			x += sw
		# the joints: a dark line, plus a light one below it so the slab edge
		# catches the light like a real chamfer
		_wc.draw_line(Vector2(sw_l, y), Vector2(sw_r, y), joint, 2.0)
		_wc.draw_line(Vector2(sw_l, y + 2.0), Vector2(sw_r, y + 2.0), Color(1, 1, 1, 0.045), 1.5)
		var vx := sw_l - sw + off
		while vx < sw_r:
			if vx > sw_l and vx < sw_r:
				_wc.draw_line(Vector2(vx, y), Vector2(vx, y + sh - 2.0), joint, 2.0)
			vx += sw
		row += 1
		y += sh


func _draw_edges(c: Object, vt: float, vb: float) -> void:
	# What flanks the corridor is what actually gives a walk its identity:
	# shopfronts say boulevard, stone walls say medieval alley, chain-link
	# says scrapyard. Drawn as repeating modules down the walk and culled to
	# the view, on both verges, facing inward.
	if lvl == "beach":
		return  # bespoke cross-section, dressed in its own block
	if lvl == "montjuic":
		Montjuic.draw_below(self, c, vt, vb)
		return
	var mod := 220.0                     # height of one facade module
	var depth := 78.0                    # how far the detailed frontage juts
	# Built-up walks fill everything past the building line with masonry, so
	# no stray grass shows past the buildings - a big part of why an alley
	# feels enclosed. Green walks (park, trail) keep their verge and crowd
	# the path with foliage instead. The line is main.frontage(y): the paving
	# edge plus the walk's strip, and it follows the path where it bends, so
	# everything here is drawn in horizontal slices at that slice's line.
	if built:
		var base := _edge_base_color()
		var far := 520.0
		var face := 22.0
		var cast := 38.0
		var slice := 55.0
		var sy := floorf((vt - 320.0) / slice) * slice
		while sy < vb + 320.0:
			# past the gate the off-leash space draws its own surroundings:
			# the street's buildings stop at the gate, not halfway across it
			if sy + slice <= GATE_Y - 30.0:
				sy += slice
				continue
			var f := frontage(sy + slice * 0.5)
			var fl := f.x
			var fr := f.y
			c.draw_rect(Rect2(fl - far, sy, far, slice), base)
			c.draw_rect(Rect2(fr, sy, far, slice), base)
			# Seen from directly overhead you do not see a facade at all - you
			# see the ROOF. The roof is inset from its footprint and the gap
			# becomes a visible WALL FACE, angled toward the viewer: dark at the
			# base, lighter up the wall, with a bright cap along the roof edge.
			for i in range(7):
				var t := float(i) / 6.0
				c.draw_rect(Rect2(fl - face + face * t, sy, face / 6.0 + 1.0, slice), base.darkened(0.52 - t * 0.34))
				c.draw_rect(Rect2(fr + face - face * t - face / 6.0 - 1.0, sy, face / 6.0 + 1.0, slice), base.darkened(0.56 - t * 0.34))
			c.draw_rect(Rect2(fl - face - 5.0, sy, 5.0, slice), base.lightened(0.30))
			c.draw_rect(Rect2(fr + face, sy, 5.0, slice), base.lightened(0.24))
			# the light is up-and-left, so the LEFT block throws a shadow out
			# across the ground; the right block throws its own away from us
			for i in range(6):
				var t := float(i) / 5.0
				c.draw_rect(Rect2(fl, sy, cast * (1.0 - t * 0.82), slice), Color(0.05, 0.04, 0.07, 0.055))
			for i in range(3):
				var g := float(i) / 2.0
				c.draw_rect(Rect2(fr - 11.0 * (1.0 - g), sy, 11.0 * (1.0 - g), slice), Color(0.05, 0.04, 0.07, 0.05))
			sy += slice
	# the roof sits BACK from the kerb by the depth of the wall face drawn
	# above, otherwise the roof clutter would be painted over the wall
	var inset := 27.0 if built else 0.0
	var y := floorf((vt - mod) / mod) * mod
	while y < vb + mod:
		if y + mod * 0.5 < GATE_Y:
			y += mod
			continue
		for side in [-1.0, 1.0]:
			var line: Vector2 = frontage(y + mod * 0.5) if built else Vector2(sw_l, sw_r)
			var inner: float = (line.x - inset) if side < 0.0 else (line.y + inset)
			var x0: float = inner - depth if side < 0.0 else inner
			# contiguous modules: gaps between them looked like missing wall
			var r := Rect2(x0, y, depth, mod)
			# a stable per-module variation without touching the global rng
			var k := int(absf(y) / mod) + (0 if side < 0.0 else 7)
			_draw_edge_module(c, r, side, k)
		y += mod


func draw_edges_onto(c: Object) -> void:
	# called by the edge layer, which decides WHEN rather than what
	var vt: float = cam.position.y - 560.0
	var vb: float = cam.position.y + 560.0
	# drawn through a ShapeBatch: the modules alternate rects, lines and discs,
	# and every switch was a new draw call (316 of street's 781 a frame). Same
	# pixels, see systems/shape_batch.gd. c is a CanvasItem or that stand-in.
	var b := ShapeBatch.new(c)
	_draw_edges(b, vt, vb)
	b.flush()


func _edge_base_color() -> Color:
	match lvl:
		"oldtown", "spook": return Color(0.36, 0.33, 0.30)   # old stone
		"station": return Color(0.48, 0.48, 0.52)            # tiled interior
		"site": return Color(0.52, 0.42, 0.27)               # plywood hoarding
		"scrap": return Color(0.26, 0.25, 0.24)              # yard beyond the fence
		"market": return Color(0.44, 0.38, 0.34)
		_: return Color(0.38, 0.35, 0.37)                    # city block


func _draw_doorway(c: Object, inner_x: float, side: float, y: float, wall: Color) -> void:
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


func _draw_edge_module(c: Object, r: Rect2, side: float, k: int) -> void:
	var inner_x: float = r.end.x if side < 0.0 else r.position.x
	var lit := fmod(float(k) * 0.37, 1.0)
	# Roofscape, not facades: from overhead the readable features are roof
	# material, chimneys, vents, skylights and plant - plus the things that
	# genuinely project over the pavement (awnings) and the things that sit
	# in the ground plane (doorsteps).
	var style := lvl
	if lvl == "guell":
		style = "guell"
	if lvl == "market":
		# inside the hall the edge is the hall's own roof; outside it, the city's
		var in_hall: bool = r.position.y < LevelBuild.MERCAT_ARCH_Y and r.end.y > LevelBuild.MERCAT_DOOR_Y
		style = "hall" if in_hall else "oldtown"
	match style:
		"guell":
			# rubble-stone terrace walls, the stones laid rough, and the
			# planting along the top: palms and agaves
			var stone := Color(0.56, 0.48, 0.38).lightened(lit * 0.08)
			c.draw_rect(r, stone)
			for si in range(14):
				var sp := r.position + Vector2(fmod(float(si) * 53.0 + float(k) * 17.0, r.size.x),
					fmod(float(si) * 31.0 + float(k) * 41.0, r.size.y))
				c.draw_circle(sp, 9.0 + float(si % 3) * 4.0, stone.darkened(0.12) if si % 2 == 0 else stone.lightened(0.08))
			c.draw_line(Vector2(inner_x + side * 3.0, r.position.y), Vector2(inner_x + side * 3.0, r.end.y),
				Color(0.40, 0.33, 0.26), 6.0)
			var palm := Vector2(inner_x + side * 60.0, r.position.y + 70.0 + float(k % 3) * 30.0)
			for f in range(8):
				var fd := Vector2.from_angle(float(f) * TAU / 8.0 + float(k))
				c.draw_line(palm, palm + fd * 34.0, Color(0.30, 0.48, 0.24), 5.0)
			c.draw_circle(palm, 6.0, Color(0.46, 0.36, 0.24))
			var ag := Vector2(inner_x + side * 34.0, r.position.y + 170.0)
			for f in range(6):
				c.draw_line(ag, ag + Vector2.from_angle(float(f) * TAU / 6.0 + 0.3) * 18.0, Color(0.42, 0.56, 0.52), 4.0)
		"hall":
			# the market hall's roof: glazing between red iron trusses, and a
			# glow of the stalls' light coming up through it
			var glass := Color(0.60, 0.66, 0.66).lightened(lit * 0.06)
			c.draw_rect(r, glass)
			var ty := r.position.y
			while ty < r.end.y:
				c.draw_line(Vector2(r.position.x, ty), Vector2(r.end.x, ty), Color(0.56, 0.20, 0.16), 5.0)
				c.draw_line(Vector2(r.position.x, ty + 5.0), Vector2(r.end.x, ty + 5.0), Color(0.80, 0.86, 0.86, 0.45), 1.5)
				ty += 48.0
			var spine := r.get_center().x
			c.draw_line(Vector2(spine, r.position.y), Vector2(spine, r.end.y), Color(0.50, 0.18, 0.14), 7.0)
			c.draw_line(Vector2(inner_x + side * 4.0, r.position.y), Vector2(inner_x + side * 4.0, r.end.y),
				Color(0.40, 0.34, 0.30), 8.0)
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
			# La Neteja at dawn: the shops' shutter boxes over their fronts,
			# the shutters down, tagged, and no awnings out yet
			if lvl == "neteja":
				var sx: float = inner_x if side < 0.0 else inner_x - 14.0
				c.draw_rect(Rect2(sx, r.position.y + 30.0, 14.0, r.size.y - 60.0), Color(0.56, 0.57, 0.58))
				var sl := r.position.y + 34.0
				while sl < r.end.y - 30.0:
					c.draw_line(Vector2(sx, sl), Vector2(sx + 14.0, sl), Color(0.42, 0.43, 0.45), 1.5)
					sl += 6.0
				var tag: Color = [Color(0.86, 0.26, 0.40), Color(0.30, 0.66, 0.86), Color(0.96, 0.80, 0.24)][k % 3]
				c.draw_line(Vector2(sx + 2.0, r.position.y + 70.0), Vector2(sx + 12.0, r.position.y + 96.0), tag, 3.0)
				c.draw_line(Vector2(sx + 12.0, r.position.y + 96.0), Vector2(sx + 3.0, r.position.y + 118.0), tag, 3.0)
			# the awning: projects over the pavement, so it reads correctly
			# from overhead, and throws a shadow onto the paving below it
			if k % 2 == 0 and lvl != "neteja":
				var ac := Color(0.72, 0.3, 0.28) if k % 4 == 0 else Color(0.28, 0.42, 0.55)
				var aw_x: float = inner_x if side < 0.0 else inner_x - 34.0
				c.draw_rect(Rect2(aw_x, r.position.y + 44.0, 34.0, 76.0), Color(0.05, 0.04, 0.07, 0.16))
				c.draw_rect(Rect2(aw_x, r.position.y + 40.0, 30.0, 72.0), ac)
				for st in range(4):
					c.draw_line(Vector2(aw_x + 7.0 * float(st), r.position.y + 40.0),
						Vector2(aw_x + 7.0 * float(st), r.position.y + 112.0), ac.lightened(0.30), 3.0)
			_draw_doorway(c, inner_x, side, r.position.y + 168.0, felt)


func _build_verge() -> void:
	LevelBuild.build_verge(self)


func draw_verge_onto(c: Object, vt: float, vb: float) -> void:
	# On the cached edge canvas, NOT the per-frame world draw. A lawn does not
	# move, and the edge treatment was already more than half the frame once
	# before it was moved off it (see edgelayer.gd) - putting picnics into the
	# 30-times-a-second draw is exactly how a walk starts to stutter.
	_draw_grass_detail(c, vt, vb)
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


# GRASS THAT READS AS GRASS: tufts in two greens, now and then a seed head or
# a flower, on a jittered grid wherever surface_at() says grass - so it can
# never disagree with the handling. Drawn on the cached verge canvas: a redraw
# every 150px of camera, never a frame. Positions are hashed from the grid
# cell, never from the RNG, so the same lawn grows the same way every walk.
const GRASS_STEP := 34.0


static func _cell01(x: float, y: float) -> float:
	var n := sin(x * 12.9898 + y * 78.233) * 43758.5453
	return n - floorf(n)


func _grass_blocked(p: Vector2) -> bool:
	if built:
		# past the building line are roofs, which the edge layer draws
		var f := frontage(p.y)
		if p.x < f.x or p.x > f.y:
			return true
	if lvl == "trail":
		var e := walk_edges(p.y)
		if p.x < e.x - LevelBuild.TRAIL_WOOD_OUT or p.x > e.y + LevelBuild.TRAIL_WOOD_OUT:
			return true
	if lvl == "montjuic" and (Montjuic.CACTUS_BED.grow(8.0).has_point(p) or Montjuic.FONT.grow(16.0).has_point(p)):
		return true
	for r: Rect2 in solid_rects:
		if r.grow(6.0).has_point(p):
			return true
	if lvl == "montjuic":
		var me := walk_edges(p.y)
		if absf(p.x - (me.x + me.y) * 0.5) > Montjuic.hill_half(self, p.y) - 16.0:
			return true
	if lvl == "park":
		for r: Rect2 in LevelBuild.PARK_BEDS:
			if r.grow(8.0).has_point(p):
				return true
		if LevelBuild.PARK_PLAYGROUND.grow(8.0).has_point(p):
			return true
		if p.distance_to(LevelBuild.PARK_BANDSTAND) < LevelBuild.BANDSTAND_R + 22.0:
			return true
	if lvl == "barri" or tutorial_mode:
		if LevelBuild.BARRI_PETANCA.grow(8.0).has_point(p) or LevelBuild.BARRI_PLAYGROUND.grow(8.0).has_point(p):
			return true
	for it: Dictionary in verge_items:
		if p.distance_to(it["pos"]) < 52.0:
			return true
	return false


func _draw_grass_detail(c: Object, vt: float, vb: float) -> void:
	var dark := Color(0.16, 0.30, 0.16, 0.55)
	var lite := Color(0.50, 0.66, 0.36, 0.55)
	var seedc := Color(0.86, 0.82, 0.62, 0.7)
	if lvl == "trail":
		# the forest floor: browner, and no meadow flowers under the trees
		dark = Color(0.14, 0.22, 0.12, 0.6)
		lite = Color(0.42, 0.50, 0.26, 0.5)
	var flowers := [Color(0.97, 0.96, 0.92), Color(0.98, 0.84, 0.30), Color(0.86, 0.48, 0.70)]
	var y := floorf((vt - 40.0) / GRASS_STEP) * GRASS_STEP
	while y < vb + 40.0:
		var x := -200.0
		while x < 1480.0:
			var h := _cell01(x, y)
			var p := Vector2(x + (h - 0.5) * GRASS_STEP * 0.9, y + (fmod(h * 7.13, 1.0) - 0.5) * GRASS_STEP * 0.9)
			if p.y > GATE_Y and surface_at(p) == Surfaces.S.GRASS and not _grass_blocked(p):
				var lean := (h - 0.5) * 0.8
				for bl in range(3):
					var a := -PI * 0.5 + lean + (float(bl) - 1.0) * 0.45
					var foot := p + Vector2((float(bl) - 1.0) * 1.6, 0.0)
					var ln := 5.0 + fmod(h * 13.0 + float(bl), 1.0) * 3.5
					c.draw_line(foot, foot + Vector2.from_angle(a) * ln, lite if bl == 1 else dark, 1.6)
				var kind := int(h * 1000.0) % 29
				if lvl == "trail" and kind < 12:
					# ferns, and leaves come down off the trees
					if kind < 7:
						for fr in range(5):
							var fa := -PI * 0.5 + (float(fr) - 2.0) * 0.55 + lean
							c.draw_line(p, p + Vector2.from_angle(fa) * (9.0 + float(fr % 2) * 3.0), Color(0.26, 0.42, 0.20, 0.8), 2.0)
					else:
						c.draw_circle(p + Vector2(4.0, 2.0), 2.4, Color(0.62, 0.42, 0.18, 0.8))
						c.draw_circle(p + Vector2(-3.0, 4.0), 2.0, Color(0.52, 0.34, 0.14, 0.8))
				elif kind == 0 and lvl != "trail":
					var fc: Color = flowers[int(h * 97.0) % 3]
					for pe in range(4):
						c.draw_circle(p + Vector2(3.0, -7.0) + Vector2.from_angle(float(pe) * PI * 0.5) * 1.8, 1.4, fc)
					c.draw_circle(p + Vector2(3.0, -7.0), 1.0, Color(0.95, 0.72, 0.20))
				elif kind < 4:
					c.draw_line(p, p + Vector2(lean * 4.0, -11.0), dark, 1.0)
					c.draw_circle(p + Vector2(lean * 4.0, -11.5), 1.6, seedc)
			x += GRASS_STEP
		y += GRASS_STEP


func _draw_picnic(c: Object, at: Vector2) -> void:
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


func _draw_stump(c: Object, at: Vector2) -> void:
	# a sawn-off trunk: end grain in rings, and a real shadow so it has height
	cast_shadow(c, at, 17.0, 22.0, 0.20)
	c.draw_circle(at, 17.0, Color(0.44, 0.33, 0.22))
	c.draw_circle(at + Vector2(-2.0, -2.0), 14.0, Color(0.62, 0.49, 0.32))
	for r: float in [10.0, 6.0, 3.0]:
		c.draw_arc(at + Vector2(-2.0, -2.0), r, 0.0, TAU, 14, Color(0.48, 0.36, 0.23), 1.4)


func _draw_verge_bush(c: Object, at: Vector2) -> void:
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
	var t := AnimClock.msec() / 1000.0
	var shown := 0
	# every mote and bloom is one draw call (systems/shape_batch.gd)
	var puffs := ShapeBatch.new()
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
			puffs.circle(along + wob, 2.0 + near * 2.4, Color(col.r, col.g, col.b, a))
		# right on top of it, a soft bloom so the last step is unmistakable
		if near > 0.62:
			puffs.circle(at, 15.0 + near * 9.0, Color(col.r, col.g, col.b, 0.07 * near))
	puffs.flush(self)


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


func contact_shadow(c: Object, at: Vector2, r: float, h: float, a := 0.24) -> void:
	# for things that sit ON the ground: a squashed ellipse, pushed away from
	# the light by however tall the thing is
	c.draw_set_transform(at + LIGHT * h, 0.0, Vector2(1.15, 0.5))
	c.draw_circle(Vector2.ZERO, r, Color(SHADOW_COL.r, SHADOW_COL.g, SHADOW_COL.b, a))
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func cast_shadow(c: Object, at: Vector2, w: float, h: float, a := 0.20) -> void:
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


func _draw_broadleaf(c: Object, p: Vector2, scale: float) -> void:
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
	# every disc from here on is one draw call (systems/shape_batch.gd)
	var crown := ShapeBatch.new()
	crown.circle(p + Vector2(2, 3) * scale, r, dark)
	crown.circle(p - LIGHT * r * 0.10, r * 0.86, mid)
	var lobes := [
		Vector2(-0.42, -0.30), Vector2(0.40, -0.34), Vector2(0.46, 0.32),
		Vector2(-0.38, 0.40), Vector2(0.02, -0.06),
	]
	for i in range(lobes.size()):
		var lp: Vector2 = p + (lobes[i] as Vector2) * r
		crown.circle(lp, r * 0.50, mid)
	# the light falls on the upper-left of the crown, so only those lobes catch
	for i in range(lobes.size()):
		var lv: Vector2 = lobes[i]
		if lv.dot(LIGHT) > 0.10:
			continue          # this lobe is on the shaded side
		crown.circle(p + lv * r - LIGHT * r * 0.14, r * 0.34, lit)
	crown.circle(p - LIGHT * r * 0.42, r * 0.30, lit.lightened(0.08))
	# the trunk, visible in the middle where the canopy parts
	crown.circle(p, 6.5 * scale, Color(0.22, 0.16, 0.11))
	crown.circle(p + Vector2(-1, -1) * scale, 4.4 * scale, Color(0.36, 0.27, 0.18))
	# a few leaf tips breaking the outline, so it is not a perfect circle
	for i in range(7):
		var a := TAU * float(i) / 7.0 + p.x * 0.013
		crown.circle(p + Vector2.from_angle(a) * r * 0.95, r * 0.17, mid)
	crown.flush(c)



# El Bosc's ground: packed dark earth on the trail, leaf litter either side
const TRAIL_DIRT := Color(0.50, 0.41, 0.29)
const TRAIL_FLOOR := Color(0.25, 0.31, 0.19)
const TRAIL_LITTER: Array = [
	Color(0.36, 0.30, 0.17), Color(0.45, 0.33, 0.16), Color(0.21, 0.27, 0.16), Color(0.52, 0.40, 0.20),
]


# The wood is Collserola's: stone pines (a flat umbrella of needles on a red
# trunk) and holm oaks (dense, dark, round). Roots run out across the trail
# from the trunks at its edges, which is what makes it a trail and not a
# park path.
func _draw_forest_tree(c: Object, p: Vector2, i: int) -> void:
	var e := walk_edges(p.y)
	var edge_side := 0.0
	if p.x < e.x + 50.0:
		edge_side = 1.0
	elif p.x > e.y - 50.0:
		edge_side = -1.0
	if edge_side != 0.0:
		for ri in range(3):
			var a := (float(ri) - 1.0) * 0.55 + (0.2 if i % 2 == 0 else -0.2)
			var d := Vector2(edge_side, 0.0).rotated(a)
			var tip := p + d * (34.0 + float((i + ri) % 3) * 12.0)
			c.draw_line(p, tip, Color(0.33, 0.25, 0.16), 4.0 - float(ri % 2))
			c.draw_line(p + Vector2(0, -1), tip + Vector2(0, -1), Color(0.44, 0.35, 0.23), 1.2)
	if i % 3 == 1:
		_draw_broadleaf(c, p, 0.85)   # holm oak
		return
	# stone pine: the umbrella crown, dark underneath, needle clumps on top
	var r := 40.0
	c.draw_set_transform(p + LIGHT * 52.0, 0.0, Vector2(1.15, 0.55))
	c.draw_circle(Vector2.ZERO, r, Color(SHADOW_COL.r, SHADOW_COL.g, SHADOW_COL.b, 0.18))
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var crown := ShapeBatch.new()
	crown.circle(p + Vector2(2, 3), r, Color(0.20, 0.25, 0.13))
	for k in range(9):
		var a := TAU * float(k) / 9.0 + float(i) * 0.7
		var lr := r * (0.58 + 0.12 * float((k + i) % 3))
		crown.circle(p + Vector2.from_angle(a) * lr, r * 0.36, Color(0.30, 0.37, 0.18))
	for k in range(5):
		var a := TAU * float(k) / 5.0 + float(i) * 1.3
		var lp := p + Vector2.from_angle(a) * r * 0.42 - LIGHT * 6.0
		crown.circle(lp, r * 0.24, Color(0.40, 0.47, 0.24))
	crown.circle(p - LIGHT * r * 0.5, r * 0.20, Color(0.48, 0.54, 0.29))
	# the red-brown trunk showing through at the middle
	crown.circle(p, 6.0, Color(0.42, 0.22, 0.14))
	crown.circle(p + Vector2(-1, -1), 3.6, Color(0.58, 0.33, 0.20))
	crown.flush(c)


# A waymarker post, where the town has hydrants: a squared timber post with
# the long-distance path's red-over-white bands. Marked posts go grey-brown.
func _draw_waymarker(c: Object, h: Dictionary) -> void:
	var hp: Vector2 = h.pos
	cast_shadow(c, hp, 7.0, 30.0)
	var wood := Color(0.47, 0.36, 0.24) if not h.done else Color(0.40, 0.36, 0.32)
	c.draw_rect(Rect2(hp.x - 7.0, hp.y - 7.0, 14.0, 14.0), wood.darkened(0.3))
	c.draw_rect(Rect2(hp.x - 6.0, hp.y - 6.0, 12.0, 12.0), wood)
	c.draw_rect(Rect2(hp.x - 6.0, hp.y - 6.0, 5.0, 12.0), wood.lightened(0.12))
	var band_a := 1.0 if not h.done else 0.35
	c.draw_rect(Rect2(hp.x - 6.0, hp.y - 4.0, 12.0, 3.0), Color(0.95, 0.94, 0.90, band_a))
	c.draw_rect(Rect2(hp.x - 6.0, hp.y - 1.0, 12.0, 3.0), Color(0.80, 0.16, 0.14, band_a))
	if not h.done and h.progress > 0.0:
		c.draw_arc(hp, 17.0, -PI / 2.0, -PI / 2.0 + TAU * h.progress / 0.8, 20, Color(1, 0.95, 0.7), 3.0)


# A half-eaten bocadillo in its foil, dropped off someone's picnic.
func _draw_bocadillo(c: Object, kp: Vector2) -> void:
	contact_shadow(c, kp, 11.0, 4.0, 0.20)
	c.draw_colored_polygon(PackedVector2Array([
		kp + Vector2(-12, -2), kp + Vector2(-4, -8), kp + Vector2(12, -5),
		kp + Vector2(10, 6), kp + Vector2(-8, 7),
	]), Color(0.78, 0.80, 0.83))
	c.draw_line(kp + Vector2(-6, -6), kp + Vector2(8, -3), Color(0.93, 0.94, 0.96), 1.5)
	c.draw_rect(Rect2(kp.x - 7.0, kp.y - 3.0, 14.0, 6.0), Color(0.80, 0.60, 0.33))
	c.draw_rect(Rect2(kp.x - 7.0, kp.y - 3.0, 14.0, 2.0), Color(0.88, 0.70, 0.42))
	c.draw_line(kp + Vector2(-6, 1), kp + Vector2(6, 1), Color(0.72, 0.26, 0.24), 1.6)


# The wood either side of El Bosc's trail, from the wood line outward:
# undergrowth along the line, then overlapping crowns to the edge of the
# frame. One batch, and every clump is hashed from its row so it holds still.
func _draw_wood(vt: float, vb: float) -> void:
	var out: float = LevelBuild.TRAIL_WOOD_OUT
	var b := ShapeBatch.new()
	var step := 56.0
	# stops at the gate: the clearing beyond has its own ring of trees
	var sy := maxf(floorf((vt - 80.0) / step) * step, GATE_Y + 100.0)
	while sy < vb + 80.0:
		var e := walk_edges(sy + step * 0.5)
		var row := int(absf(sy) / step)
		for side: float in [-1.0, 1.0]:
			var line: float = (e.x - out) if side < 0.0 else (e.y + out)
			var far_x: float = line + side * 12.0
			b.rect(Rect2(minf(far_x, far_x + side * 700.0), sy, 700.0, step + 1.0), Color(0.12, 0.20, 0.12))
			for k in range(5):
				var h := fmod(absf(sin(float(row * 7 + k) * 12.9898 + side * 3.1) * 43758.5453), 1.0)
				var cx: float = line + side * (26.0 + float(k) * 60.0 + h * 18.0)
				var cy := sy + step * 0.5 + (h - 0.5) * 30.0
				var r := 30.0 + h * 14.0
				b.circle(Vector2(cx, cy) + Vector2(3, 4), r, Color(0.10, 0.17, 0.10))
				b.circle(Vector2(cx, cy), r * 0.9, Color(0.17, 0.29, 0.16) if (row + k) % 3 != 0 else Color(0.20, 0.31, 0.15))
				b.circle(Vector2(cx, cy) - LIGHT * r * 0.35, r * 0.42, Color(0.25, 0.38, 0.20))
			# undergrowth and a trunk or two right on the line
			var hu := fmod(absf(sin(float(row) * 78.233 + side) * 43758.5453), 1.0)
			b.circle(Vector2(line + side * 4.0, sy + hu * step), 13.0 + hu * 6.0, Color(0.19, 0.30, 0.17))
			b.circle(Vector2(line - side * 6.0, sy + step * 0.5 + hu * 10.0), 9.0, Color(0.23, 0.35, 0.19))
			if row % 2 == 0:
				b.circle(Vector2(line + side * 16.0, sy + step * 0.3), 5.5, Color(0.30, 0.22, 0.15))
		sy += step
	b.flush(_wc)


# A fallen trunk: bark with its furrows along it, a pale sawn or broken end
# out on the trail, moss on the top, a shadow under it.
func _draw_fallen_log(r: Rect2) -> void:
	var b := ShapeBatch.new()
	b.rect(Rect2(r.position + LIGHT * 7.0, r.size), Color(SHADOW_COL.r, SHADOW_COL.g, SHADOW_COL.b, 0.28))
	b.rect(r, Color(0.36, 0.26, 0.17))
	b.rect(Rect2(r.position.x, r.position.y, r.size.x, 6.0), Color(0.46, 0.34, 0.22))
	for k in range(4):
		var fy := r.position.y + 5.0 + float(k) * 4.0
		b.line(Vector2(r.position.x + 6.0 + float(k) * 9.0, fy), Vector2(r.end.x - 10.0 - float(k) * 7.0, fy), Color(0.27, 0.19, 0.12), 1.4)
	var hx: float = r.get_center().x
	b.circle(Vector2(hx - 20.0, r.position.y + 3.0), 6.0, Color(0.33, 0.44, 0.22))
	b.circle(Vector2(hx + 14.0, r.position.y + 2.0), 4.5, Color(0.38, 0.50, 0.25))
	# the broken ends: pale wood rings at both, splinters at the trail end
	for ex: float in [r.position.x, r.end.x]:
		b.circle(Vector2(ex, r.get_center().y), r.size.y * 0.5, Color(0.66, 0.54, 0.38))
		b.circle(Vector2(ex, r.get_center().y), r.size.y * 0.28, Color(0.55, 0.43, 0.29))
	b.flush(_wc)


# A stack of wrecked cars from above: the top car's roof, rusted and dented,
# the ones under it showing past its edges at a skew, glass long gone.
func _draw_wreck_stack(v: Vector2) -> void:
	var b := ShapeBatch.new()
	var h := int(absf(v.y)) % 5
	var cols := [Color(0.55, 0.22, 0.18), Color(0.30, 0.38, 0.46), Color(0.48, 0.46, 0.30), Color(0.62, 0.62, 0.60), Color(0.24, 0.34, 0.26)]
	b.rect(Rect2(v.x - 32.0 + 30.0, v.y - 66.0 + 30.0, 68.0, 134.0), Color(SHADOW_COL.r, SHADOW_COL.g, SHADOW_COL.b, 0.26))
	for k in range(3):
		var off := Vector2(float((h + k) % 3 - 1) * 6.0, float(k - 1) * 5.0)
		var c: Color = (cols[(h + k) % cols.size()] as Color).darkened(0.18 * float(2 - k))
		b.rect(Rect2(v.x - 30.0 + off.x, v.y - 62.0 + off.y, 60.0, 124.0), c)
	var top: Color = cols[(h + 2) % cols.size()]
	b.rect(Rect2(v.x - 22.0, v.y - 26.0, 44.0, 52.0), top.lightened(0.08))                # the roof
	b.rect(Rect2(v.x - 22.0, v.y - 46.0, 44.0, 18.0), Color(0.12, 0.12, 0.13))             # no windscreen
	b.rect(Rect2(v.x - 22.0, v.y + 28.0, 44.0, 12.0), Color(0.12, 0.12, 0.13))
	for k in range(4):
		b.circle(v + Vector2(-14.0 + float(k % 2) * 28.0, -8.0 + float(k / 2) * 20.0), 4.0 + float((h + k) % 3), Color(0.44, 0.28, 0.16, 0.8))  # rust
	b.flush(_wc)


# EL GOTIC: the steps, the parked scooters, and the bridge between two
# buildings, drawn as its shadow across the alley and its stone lip at each
# wall (the overhead layer draws the bridge itself above everyone)
func _draw_gotic(vt: float, vb: float) -> void:
	var b := ShapeBatch.new()
	# setts, staggered, ruled inside the alley wherever it has jinked to
	var row := int(floorf((vt - 60.0) / 56.0))
	var ry := float(row) * 56.0
	while ry < vb + 60.0:
		var e0 := walk_edges(ry)
		b.line(Vector2(e0.x, ry), Vector2(e0.y, ry), Color(0, 0, 0, 0.10), 2.0)
		var off := 32.0 if row % 2 == 0 else 0.0
		var rx := floorf(e0.x / 64.0) * 64.0 + off
		while rx < e0.y:
			if rx > e0.x:
				b.line(Vector2(rx, ry), Vector2(rx, ry + 56.0), Color(0, 0, 0, 0.10), 2.0)
			rx += 64.0
		ry += 56.0
		row += 1
	# the plaça's fountain: a round stone basin, water, a spout in the middle
	var fp: Vector2 = LevelBuild.GOTIC_PLACA
	if fp.y > vt - 80.0 and fp.y < vb + 80.0:
		b.circle(fp + LIGHT * 10.0, 40.0, Color(SHADOW_COL.r, SHADOW_COL.g, SHADOW_COL.b, 0.22))
		b.circle(fp, 38.0, Color(0.62, 0.58, 0.52))
		b.circle(fp, 31.0, Color(0.34, 0.48, 0.56))
		b.circle(fp + Vector2(-8, -8), 12.0, Color(0.46, 0.60, 0.68))
		b.circle(fp, 7.0, Color(0.58, 0.54, 0.48))
	var sy: float = LevelBuild.GOTIC_STEPS_Y
	if sy > vt - 80.0 and sy < vb + 80.0:
		for k in range(5):
			var yy := sy + float(k) * 12.0
			var e := walk_edges(yy)
			b.rect(Rect2(e.x, yy, e.y - e.x, 12.0), Color(0.58, 0.54, 0.48).darkened(0.05 * float(k)))
			b.line(Vector2(e.x, yy), Vector2(e.y, yy), Color(0.72, 0.68, 0.62), 2.0)
	_draw_scooters(b, vt, vb)
	var by: float = LevelBuild.GOTIC_BRIDGE_Y
	if by > vt - 120.0 and by < vb + 120.0:
		var e2 := walk_edges(by)
		b.rect(Rect2(e2.x, by + 20.0, e2.y - e2.x, 70.0), Color(SHADOW_COL.r, SHADOW_COL.g, SHADOW_COL.b, 0.25))
	b.flush(_wc)


# parked scooters, El Gotic's and La Neteja's: seat, wheels, handlebars
func _draw_scooters(b: ShapeBatch, vt: float, vb: float) -> void:
	for sc: Vector2 in scooters:
		if sc.y < vt - 60.0 or sc.y > vb + 60.0:
			continue
		var c: Color = [Color(0.70, 0.16, 0.16), Color(0.86, 0.84, 0.78), Color(0.22, 0.40, 0.56)][int(absf(sc.y)) % 3]
		b.rect(Rect2(sc.x - 9.0 + 5.0, sc.y - 26.0 + 7.0, 18.0, 52.0), Color(0, 0, 0, 0.2))
		b.circle(sc + Vector2(0, -20), 7.0, Color(0.10, 0.10, 0.11))
		b.circle(sc + Vector2(0, 20), 7.0, Color(0.10, 0.10, 0.11))
		b.rect(Rect2(sc.x - 9.0, sc.y - 16.0, 18.0, 34.0), c)
		b.circle(sc + Vector2(0, 4), 8.0, (c as Color).darkened(0.25))
		b.line(sc + Vector2(-12, -18), sc + Vector2(12, -18), Color(0.2, 0.2, 0.22), 3.0)


# El Mosaic's plaza edges are the serpentine bench: grinding them is the bench
# a grindable's line, where it is on screen
func _draw_rail(r: Dictionary, vt: float, vb: float, col: Color, w: float) -> void:
	var pts: PackedVector2Array = r["pts"]
	for i in range(pts.size() - 1):
		var a := pts[i]
		var bb := pts[i + 1]
		if maxf(a.y, bb.y) < vt - 20.0 or minf(a.y, bb.y) > vb + 20.0:
			continue
		_wc.draw_line(a, bb, col, w)


func on_mosaic_bench(y: float) -> bool:
	return lvl == "guell" and y < LevelBuild.MOSAIC_PLAZA_Y0 + 40.0 and y > LevelBuild.MOSAIC_PLAZA_Y1 - 40.0


const SHARDS := [Color(0.12, 0.30, 0.70), Color(0.18, 0.62, 0.70), Color(0.34, 0.62, 0.30),
	Color(0.96, 0.80, 0.24), Color(0.92, 0.50, 0.18), Color(0.97, 0.96, 0.92), Color(0.82, 0.24, 0.26)]


# broken tile set in mortar, as a disc: every shard its own odd shape
func _trencadis_disc(c: Object, at: Vector2, r: float, key: int) -> void:
	c.draw_circle(at, r, Color(0.92, 0.90, 0.84))
	for k in range(9):
		var a := float(k) * 2.39996 + float(key % 7)
		var d := r * sqrt(fmod(float(k) * 0.37 + 0.13, 1.0)) * 0.8
		var q := at + Vector2(cos(a), sin(a)) * d
		var poly := PackedVector2Array()
		for v in range(4):
			var va := a + float(v) * 1.57 + float((key + k + v) % 5) * 0.2
			poly.append(q + Vector2(cos(va), sin(va)) * r * (0.22 + 0.08 * float((k + v) % 3)))
		c.draw_colored_polygon(poly, SHARDS[(k + key) % SHARDS.size()])


# ...and as a band between two points, for the bench
func _trencadis_band(b: ShapeBatch, a: Vector2, z: Vector2, w: float, key: int) -> void:
	b.line(a, z, Color(0.92, 0.90, 0.84), w)
	var n := int(a.distance_to(z) / 9.0)
	var side := (z - a).normalized().orthogonal()
	for k in range(n):
		var q := a.lerp(z, (float(k) + 0.5) / float(maxi(n, 1))) + side * (fmod(float(k * 7 + key), 5.0) - 2.0) * w * 0.12
		var poly := PackedVector2Array()
		for v in range(4):
			var va := float(v) * 1.57 + float((k + key + v) % 5) * 0.35
			poly.append(q + Vector2(cos(va), sin(va)) * w * (0.26 + 0.06 * float((k + v) % 3)))
		b.polygon(poly, SHARDS[(k * 3 + key) % SHARDS.size()])


func _draw_mosaic(vt: float, vb: float) -> void:
	var b := ShapeBatch.new()
	# gravel: the sandy ground, with its stones
	var gy := floorf((vt - 20.0) / 31.0) * 31.0
	while gy < vb + 20.0:
		var e := walk_edges(gy)
		var gx := e.x + fmod(absf(gy) * 0.61, 23.0)
		while gx < e.y:
			var n := fmod(absf(gx * 12.9898 + gy * 78.233), 5.0)
			b.circle(Vector2(gx, gy), 1.3 + n * 0.3, Color(0.64, 0.56, 0.42, 0.55) if int(n) % 2 == 0 else Color(0.90, 0.84, 0.70, 0.5))
			gx += 23.0 + n * 4.0
		gy += 31.0
	# the dragon stair: steps across the whole width at its foot and its head
	for sy: float in [LevelBuild.MOSAIC_STAIR_Y0, LevelBuild.MOSAIC_STAIR_Y1]:
		if sy < vt - 80.0 or sy > vb + 80.0:
			continue
		for k in range(6):
			var yy := sy - float(k) * 13.0
			var e := walk_edges(yy)
			b.rect(Rect2(e.x, yy - 13.0, e.y - e.x, 13.0), Color(0.72, 0.66, 0.56).darkened(0.04 * float(k)))
			b.line(Vector2(e.x, yy - 13.0), Vector2(e.y, yy - 13.0), Color(0.86, 0.80, 0.70), 2.0)
	# the dripping-stone grotto walls either side of the stair
	var ya := maxf(vt - 40.0, LevelBuild.MOSAIC_STAIR_Y1)
	var yz := minf(vb + 40.0, LevelBuild.MOSAIC_STAIR_Y0)
	var dy := floorf(ya / 40.0) * 40.0
	while dy < yz:
		var e := walk_edges(dy)
		for sx: float in [e.x, e.y]:
			var into := 1.0 if sx == e.x else -1.0
			b.circle(Vector2(sx + into * 8.0, dy), 11.0, Color(0.52, 0.46, 0.38))
			b.circle(Vector2(sx + into * 12.0, dy + 14.0), 5.0, Color(0.44, 0.38, 0.32))
		dy += 40.0
	b.flush(_wc)
	# the salamander on the landing: the landmark, in trencadis
	var sm: Vector2 = LevelBuild.MOSAIC_SALAMANDER
	if sm.y > vt - 120.0 and sm.y < vb + 120.0:
		var sz: Vector2 = LevelBuild.MOSAIC_SALAMANDER_SIZE
		var b2 := ShapeBatch.new()
		b2.rect(Rect2(sm - sz * 0.5 + LIGHT * 12.0, sz), Color(SHADOW_COL.r, SHADOW_COL.g, SHADOW_COL.b, 0.25))
		b2.rect(Rect2(sm - sz * 0.5, sz), Color(0.66, 0.60, 0.50))
		b2.flush(_wc)
		# its body, head down the stair and tail curling up it: a chain of
		# trencadis scales, fattest at the shoulders
		var spine := [sm + Vector2(0, 74), sm + Vector2(10, 46), sm + Vector2(-4, 16), sm + Vector2(10, -14),
			sm + Vector2(-2, -44), sm + Vector2(-18, -66), sm + Vector2(-30, -80)]
		var bw := [16.0, 24.0, 27.0, 24.0, 18.0, 12.0, 8.0]
		for leg: Vector2 in [Vector2(-34, 40), Vector2(36, 34), Vector2(-30, -20), Vector2(32, -26)]:
			_trencadis_disc(_wc, sm + leg, 11.0, int(leg.x + leg.y))
		for k in range(spine.size()):
			_trencadis_disc(_wc, spine[k], bw[k], k * 5 + 3)
		# its head, with a blunt snout and two dark eyes
		var hd: Vector2 = sm + Vector2(0, 86)
		_wc.draw_colored_polygon(PackedVector2Array([hd + Vector2(-16, -10), hd + Vector2(16, -10), hd + Vector2(10, 16),
			hd + Vector2(-10, 16)]), Color(0.18, 0.62, 0.70))
		_trencadis_disc(_wc, hd, 13.0, 21)
		_wc.draw_circle(hd + Vector2(-7, 6), 3.0, Color(0.1, 0.1, 0.1))
		_wc.draw_circle(hd + Vector2(7, 6), 3.0, Color(0.1, 0.1, 0.1))
		# the water from its mouth
		_wc.draw_circle(sm + Vector2(0, sz.y * 0.5 + 14.0), 12.0, Color(0.34, 0.50, 0.62))
	# the hypostyle hall: in the shade under the plaza, its floor darker
	var b3 := ShapeBatch.new()
	var h0: float = LevelBuild.MOSAIC_HALL_Y0
	var h1: float = LevelBuild.MOSAIC_HALL_Y1
	if h1 < vb + 40.0 and h0 > vt - 40.0:
		var y0 := maxf(vt - 40.0, h1)
		var y1 := minf(vb + 40.0, h0)
		var hy := floorf(y0 / 60.0) * 60.0
		while hy < y1:
			var e := walk_edges(hy)
			b3.rect(Rect2(e.x, hy, e.y - e.x, 60.0), Color(0.10, 0.08, 0.06, 0.12))
			hy += 60.0
	# the serpentine bench: the plaza's edges, finished in trencadis
	var p0: float = LevelBuild.MOSAIC_PLAZA_Y0 + 40.0
	var p1: float = LevelBuild.MOSAIC_PLAZA_Y1 - 40.0
	if p1 < vb + 40.0 and p0 > vt - 40.0:
		var y0 := maxf(vt - 40.0, p1)
		var y1 := minf(vb + 40.0, p0)
		var by := floorf(y0 / 24.0) * 24.0
		while by < y1:
			var ea := walk_edges(by)
			var ez := walk_edges(by + 24.0)
			_trencadis_band(b3, Vector2(ea.x - 9.0, by), Vector2(ez.x - 9.0, by + 24.0), 18.0, int(absf(by)) % 11)
			_trencadis_band(b3, Vector2(ea.y + 9.0, by), Vector2(ez.y + 9.0, by + 24.0), 18.0, int(absf(by)) % 13)
			by += 24.0
	# the viaduct: the covered walk, the slope on its west side
	var v0: float = LevelBuild.MOSAIC_VIADUCT_Y0
	var v1: float = LevelBuild.MOSAIC_VIADUCT_Y1
	if v1 < vb + 60.0 and v0 > vt - 60.0:
		var y0 := maxf(vt - 60.0, v1)
		var y1 := minf(vb + 60.0, v0)
		var vy := floorf(y0 / 25.0) * 25.0
		while vy < y1:
			var e := walk_edges(vy)
			# the slope tapers in and out at each end of the viaduct instead
			# of stopping in a straight edge (#21)
			var f := smoothstep(0.0, 1.0, clampf(minf(vy - v1, v0 - vy) / 160.0, 0.0, 1.0))
			var w := 120.0 * f
			if w > 2.0:
				b3.rect(Rect2(e.x - w, vy, w, 25.0), Color(0.46, 0.52, 0.34))
				b3.circle(Vector2(e.x - w, vy + 12.5), 12.5, Color(0.46, 0.52, 0.34))
				if int(absf(vy) / 25.0) % 2 == 0 and f > 0.5:
					b3.circle(Vector2(e.x - w * 0.5, vy + 12.5), 14.0 * f, Color(0.36, 0.44, 0.28))
			vy += 25.0
	# the calvary: three crosses on a heap of stones at the top
	var cv: Vector2 = LevelBuild.MOSAIC_CALVARY
	if cv.y > vt - 80.0 and cv.y < vb + 80.0:
		b3.circle(cv, 46.0, Color(0.54, 0.46, 0.36))
		b3.circle(cv + Vector2(-8, -8), 32.0, Color(0.62, 0.54, 0.42))
		for cx: Vector2 in [Vector2(0, -6), Vector2(-26, 14), Vector2(26, 14)]:
			b3.rect(Rect2(cv + cx - Vector2(3, 14), Vector2(6, 28)), Color(0.86, 0.84, 0.80))
			b3.rect(Rect2(cv + cx - Vector2(12, 3), Vector2(24, 6)), Color(0.86, 0.84, 0.80))
	b3.flush(_wc)
	# the gatehouses either side of the entrance: gingerbread walls, wavy
	# roofs iced white with mosaic caps, one with the mushroom and its cross
	for gs: float in [-1.0, 1.0]:
		var e := walk_edges(-60.0)
		var gc := Vector2((e.x - 130.0) if gs < 0.0 else (e.y + 130.0), -60.0)
		if gc.y < vt - 200.0 or gc.y > vb + 200.0:
			continue
		var b4 := ShapeBatch.new()
		b4.rect(Rect2(gc - Vector2(90, 110) + LIGHT * 16.0, Vector2(180, 220)), Color(SHADOW_COL.r, SHADOW_COL.g, SHADOW_COL.b, 0.25))
		b4.rect(Rect2(gc - Vector2(90, 110), Vector2(180, 220)), Color(0.66, 0.46, 0.30))
		for w in range(9):
			b4.circle(gc + Vector2(-80.0 + float(w) * 20.0, -104.0), 12.0, Color(0.96, 0.94, 0.90))
			b4.circle(gc + Vector2(-80.0 + float(w) * 20.0, 104.0), 12.0, Color(0.96, 0.94, 0.90))
		b4.rect(Rect2(gc - Vector2(70, 80), Vector2(140, 160)), Color(0.56, 0.36, 0.22))
		b4.flush(_wc)
		_trencadis_disc(_wc, gc + Vector2(-34, -30), 22.0, 4 if gs < 0.0 else 9)
		_trencadis_disc(_wc, gc + Vector2(36, 34), 18.0, 7 if gs < 0.0 else 2)
		if gs > 0.0:
			# the mushroom spire and its cross, from above
			_wc.draw_circle(gc + Vector2(30, -40), 26.0, Color(0.86, 0.24, 0.26))
			for d in range(6):
				_wc.draw_circle(gc + Vector2(30, -40) + Vector2.from_angle(float(d)) * 16.0, 5.0, Color(0.97, 0.96, 0.92))
			_wc.draw_rect(Rect2(gc + Vector2(26, -56), Vector2(8, 32)), Color(0.90, 0.88, 0.84))
			_wc.draw_rect(Rect2(gc + Vector2(14, -44), Vector2(32, 8)), Color(0.90, 0.88, 0.84))


func _draw_neteja(vt: float, vb: float) -> void:
	var b := ShapeBatch.new()
	# the water truck's wet streaks down the street, a darker sheen on the
	# paving with the dawn catching one edge
	var y := ceilf(vt / 220.0) * 220.0
	while y < vb + 40.0:
		var e := walk_edges(y)
		for lane: float in [0.3, 0.68]:
			var x := lerpf(e.x, e.y, lane) + sin(y * 0.01) * 12.0
			b.rect(Rect2(x - 22.0, y, 44.0, 200.0), Color(0.16, 0.18, 0.22, 0.16))
			b.rect(Rect2(x - 22.0, y, 5.0, 200.0), Color(1.0, 0.82, 0.70, 0.10))
		y += 220.0
	# the dumpsters: steel bins with their lids, and a bag that did not fit
	for d: Vector2 in LevelBuild.neteja_dumpsters(self):
		if d.y < vt - 80.0 or d.y > vb + 80.0:
			continue
		var sz: Vector2 = LevelBuild.NETEJA_DUMPSTER
		var r := Rect2(d - sz * 0.5, sz)
		b.rect(Rect2(r.position + LIGHT * 12.0, r.size), Color(SHADOW_COL.r, SHADOW_COL.g, SHADOW_COL.b, 0.25))
		var col := Color(0.24, 0.40, 0.30) if int(absf(d.y)) % 3 == 0 else Color(0.30, 0.32, 0.36)
		b.rect(r, col)
		b.rect(Rect2(r.position.x + 3.0, r.position.y + 3.0, r.size.x - 6.0, r.size.y * 0.5 - 4.0), col.lightened(0.12))
		b.rect(Rect2(r.position.x + 3.0, d.y + 1.0, r.size.x - 6.0, r.size.y * 0.5 - 4.0), col.lightened(0.06))
		b.line(Vector2(r.position.x, d.y), Vector2(r.end.x, d.y), col.darkened(0.3), 2.0)
		b.circle(d + Vector2(0.0, sz.y * 0.5 + 12.0), 10.0, Color(0.14, 0.14, 0.16))
	_draw_scooters(b, vt, vb)
	b.flush(_wc)


func _draw_castanyada(vt: float, vb: float) -> void:
	var b := ShapeBatch.new()
	var t := AnimClock.msec() / 1000.0
	var pc: Vector2 = LevelBuild.CAST_PLACA
	# the plaça's paving: a ring of setts round the middle
	if pc.y > vt - 520.0 and pc.y < vb + 520.0:
		for ring in range(5):
			b.circle(pc, 380.0 - float(ring) * 70.0, Color(0, 0, 0, 0.035))
		# the stage: boards on trestles, speakers at its corners, bunting
		var st: Rect2 = LevelBuild.castanyada_stage(self)
		b.rect(Rect2(st.position + LIGHT * 12.0, st.size), Color(SHADOW_COL.r, SHADOW_COL.g, SHADOW_COL.b, 0.25))
		b.rect(st, Color(0.46, 0.32, 0.22))
		var by := st.position.y + 12.0
		while by < st.end.y:
			b.line(Vector2(st.position.x, by), Vector2(st.end.x, by), Color(0.34, 0.24, 0.16), 2.0)
			by += 24.0
		for sp: Vector2 in [st.position + Vector2(10, 10), Vector2(st.end.x - 10.0, st.position.y + 10.0),
				Vector2(st.position.x + 10.0, st.end.y - 10.0), st.end - Vector2(10, 10)]:
			b.rect(Rect2(sp - Vector2(9, 9), Vector2(18, 18)), Color(0.10, 0.10, 0.12))
			b.circle(sp, 5.0, Color(0.30, 0.30, 0.34))
		# the roaster: a big castanyera's stand, the drum glowing, smoke going up
		var rr := Rect2(pc - LevelBuild.CAST_ROASTER * 0.5, LevelBuild.CAST_ROASTER)
		# its light on the setts; the festival is always at night
		for ring in range(8):
			var f := float(ring) / 7.0
			b.circle(pc, lerpf(190.0, 36.0, f), Color(1.0, 0.62, 0.26, 0.03 + f * f * 0.12))
		b.rect(Rect2(rr.position + LIGHT * 10.0, rr.size), Color(SHADOW_COL.r, SHADOW_COL.g, SHADOW_COL.b, 0.25))
		b.rect(rr, Color(0.40, 0.26, 0.16))
		b.rect(Rect2(rr.position, Vector2(rr.size.x, 8.0)), Color(0.72, 0.20, 0.16))
		var drum := pc + Vector2(-22.0, 4.0)
		b.circle(drum, 26.0, Color(0.16, 0.14, 0.14))
		var glow := 0.85 + 0.15 * sin(t * 9.0)
		b.circle(drum, 20.0, Color(0.96, 0.44, 0.12, glow))
		b.circle(drum, 13.0, Color(1.0, 0.78, 0.32, glow))
		for k in range(9):
			b.circle(drum + Vector2.from_angle(float(k) * 0.7) * 11.0, 3.4, Color(0.36, 0.18, 0.08))
		# sacks and cones on the counter
		b.circle(pc + Vector2(26.0, -10.0), 12.0, Color(0.66, 0.54, 0.36))
		for k in range(3):
			var cp := pc + Vector2(22.0 + float(k) * 11.0, 16.0)
			b.polygon(PackedVector2Array([cp + Vector2(-5, -7), cp + Vector2(5, -7), cp + Vector2(0, 8)]), Color(0.92, 0.88, 0.78))
		# smoke drifting off the drum
		for k in range(5):
			var ph := fmod(t * 0.35 + float(k) * 0.2, 1.0)
			b.circle(drum + Vector2(sin(t + float(k)) * 8.0 + ph * 30.0, -ph * 120.0), 10.0 + ph * 22.0,
				Color(0.90, 0.88, 0.86, 0.42 * (1.0 - ph)))
		# confetti thrown from the stage, thickest in front of it
		for k in range(90):
			var ang := float(k) * 2.39996
			var rad := 40.0 + fmod(float(k) * 37.1, 330.0)
			var cp2 := st.get_center() + Vector2(st.size.x * 0.5 + 20.0, 0.0) + Vector2(cos(ang) * rad, sin(ang) * rad * 1.2)
			var ccol: Color = [Color(0.96, 0.30, 0.36), Color(0.98, 0.84, 0.28), Color(0.36, 0.64, 0.92),
				Color(0.52, 0.80, 0.40), Color(0.94, 0.94, 0.96)][k % 5]
			b.rect(Rect2(cp2, Vector2(4.0, 3.0)), ccol)
	# chestnut shells and confetti scattered all along the street
	var cy := floorf((vt - 20.0) / 90.0) * 90.0
	while cy < vb + 20.0:
		var e := walk_edges(cy)
		var n := fmod(absf(cy) * 0.173, 1.0)
		var cx := lerpf(e.x + 20.0, e.y - 20.0, n)
		b.circle(Vector2(cx, cy), 2.4, Color(0.40, 0.22, 0.12, 0.8))
		var cc: Color = [Color(0.96, 0.30, 0.36), Color(0.98, 0.84, 0.28), Color(0.36, 0.64, 0.92), Color(0.52, 0.80, 0.40)][int(absf(cy) / 90.0) % 4]
		b.rect(Rect2(lerpf(e.x + 20.0, e.y - 20.0, fmod(n * 7.3, 1.0)), cy + 30.0, 4.0, 3.0), cc)
		cy += 90.0
	# the lanterns' glow on the ground under each string
	for ly: float in LevelBuild.CAST_LANTERN_YS:
		if ly < vt - 120.0 or ly > vb + 120.0:
			continue
		var le := walk_edges(ly)
		var lx := le.x + 40.0
		while lx < le.y - 30.0:
			b.circle(Vector2(lx, ly + 10.0), 50.0, Color(1.0, 0.72, 0.36, 0.09))
			b.circle(Vector2(lx, ly + 10.0), 26.0, Color(1.0, 0.78, 0.44, 0.08))
			lx += 70.0
	b.flush(_wc)


# La Castanyada's lantern strings, drawn over everyone: a wire from balcony to
# balcony, sagging, with paper lanterns on it, lit
func _draw_castanyada_lanterns(c: CanvasItem) -> void:
	var b := ShapeBatch.new(c)
	var t := AnimClock.msec() / 1000.0
	var cols := [Color(0.96, 0.46, 0.20), Color(0.98, 0.80, 0.30), Color(0.90, 0.28, 0.30), Color(0.60, 0.80, 0.40)]
	for i in range(LevelBuild.CAST_LANTERN_YS.size()):
		var ly: float = LevelBuild.CAST_LANTERN_YS[i]
		var e := walk_edges(ly)
		var a := Vector2(e.x - 10.0, ly - 20.0)
		var z := Vector2(e.y + 10.0, ly + 20.0)
		var prev := a
		for k in range(1, 13):
			var f := float(k) / 12.0
			var q := a.lerp(z, f) + Vector2(0, sin(f * PI) * 26.0)
			b.line(prev, q, Color(0.14, 0.12, 0.12, 0.8), 1.6)
			prev = q
		for k in range(1, 9):
			var f := float(k) / 9.0
			var q := a.lerp(z, f) + Vector2(0, sin(f * PI) * 26.0 + 6.0)
			var col: Color = cols[(k + i) % 4]
			var flick := 0.9 + 0.1 * sin(t * 3.0 + float(k + i))
			b.circle(q, 20.0, Color(col.r, col.g, col.b, 0.22 * flick))
			b.circle(q, 13.0, Color(col.r, col.g, col.b, 0.35 * flick))
			b.circle(q, 8.0, col.lightened(0.2))
			b.circle(q + Vector2(-2, -2), 3.0, Color(1.0, 0.95, 0.80, 0.8 * flick))
	b.flush()


# El Mercat's arches, drawn over everyone: an iron span across the street
# with a fan of stained glass in it and the name in iron letters
func _draw_mercat_arch(c: CanvasItem, y: float, sign: String) -> void:
	var e := walk_edges(y)
	var b := ShapeBatch.new(c)
	var r := Rect2(e.x - 40.0, y - 26.0, e.y - e.x + 80.0, 52.0)
	b.rect(Rect2(r.position + Vector2(0, 60.0), r.size), Color(SHADOW_COL.r, SHADOW_COL.g, SHADOW_COL.b, 0.18))
	b.rect(r, Color(0.46, 0.16, 0.13))
	var glass := [Color(0.86, 0.30, 0.22), Color(0.96, 0.78, 0.26), Color(0.26, 0.52, 0.72), Color(0.34, 0.62, 0.32)]
	var x := r.position.x + 10.0
	var k := 0
	while x < r.end.x - 14.0:
		b.rect(Rect2(x, y - 18.0, 20.0, 36.0), glass[k % 4])
		b.rect(Rect2(x, y - 18.0, 20.0, 5.0), Color(1, 1, 1, 0.2))
		x += 24.0
		k += 1
	b.rect(Rect2(r.position.x, y - 26.0, r.size.x, 6.0), Color(0.34, 0.12, 0.10))
	b.rect(Rect2(r.position.x, y + 20.0, r.size.x, 6.0), Color(0.34, 0.12, 0.10))
	# the name board in the middle of the span
	var nb := Rect2(r.get_center().x - 90.0, y - 16.0, 180.0, 32.0)
	b.rect(nb, Color(0.12, 0.10, 0.10))
	b.flush()
	c.draw_string(font, Vector2(nb.position.x, y + 8.0), sign, HORIZONTAL_ALIGNMENT_CENTER, nb.size.x, 22,
		Color(0.96, 0.86, 0.56))


func _draw_mercat(vt: float, vb: float) -> void:
	var b := ShapeBatch.new()
	var top: float = LevelBuild.MERCAT_ARCH_Y
	var bot: float = LevelBuild.MERCAT_DOOR_Y
	# terrazzo: the hall floor, chips of stone set in the pale slab
	var y0 := maxf(vt - 20.0, bot)
	var y1 := minf(vb + 20.0, top)
	var yy := floorf(y0 / 37.0) * 37.0
	while yy < y1:
		var e := walk_edges(yy)
		var xx := e.x + fmod(absf(yy) * 0.37, 29.0)
		while xx < e.y:
			var n := fmod(absf(xx * 12.9898 + yy * 78.233), 7.0)
			b.circle(Vector2(xx, yy), 1.4 + n * 0.25, [Color(0.52, 0.48, 0.44, 0.5), Color(0.66, 0.42, 0.36, 0.45),
				Color(0.40, 0.44, 0.40, 0.45)][int(n) % 3])
			xx += 29.0 + n * 3.0
		yy += 37.0
	# sawdust in front of the fish and the ham, where the floor gets swept
	for i in range(LevelBuild.MERCAT_WALL_STALLS.size()):
		var kind := String(LevelBuild.MERCAT_WALL_STALLS[i][2])
		if kind != "fish" and kind != "jamon":
			continue
		var f := LevelBuild.mercat_stall_front(self, i)
		if f.y < vt - 80.0 or f.y > vb + 80.0:
			continue
		for k in range(22):
			var sp := f + Vector2(fmod(float(k) * 37.3, 90.0) - 45.0, fmod(float(k) * 23.7, 70.0) - 35.0)
			b.circle(sp, 1.6, Color(0.86, 0.74, 0.50, 0.7))
	# the stall blocks down the middle: counters facing both aisles round a
	# back wall, each side its own trade, with its sign in Catalan
	var signs := ["VERDURES", "FORMATGES", "FRUITES", "OUS", "BACALLA", "ESPECIES", "XARCUTERIA", "BOLETS"]
	for bi in range(LevelBuild.MERCAT_BLOCKS.size()):
		var blk: Rect2 = LevelBuild.MERCAT_BLOCKS[bi]
		if blk.end.y < vt - 80.0 or blk.position.y > vb + 80.0:
			continue
		b.rect(Rect2(blk.position + LIGHT * 14.0, blk.size), Color(SHADOW_COL.r, SHADOW_COL.g, SHADOW_COL.b, 0.25))
		b.rect(blk, Color(0.40, 0.30, 0.22))
		var mid := blk.get_center().x
		b.rect(Rect2(mid - 6.0, blk.position.y + 6.0, 12.0, blk.size.y - 12.0), Color(0.30, 0.22, 0.16))
		for side in [-1.0, 1.0]:
			var cx: float = mid + side * 50.0
			var trade := (bi * 2 + (0 if side < 0.0 else 1)) % 8
			var pal: Array = [[Color(0.34, 0.60, 0.22), Color(0.56, 0.74, 0.30), Color(0.86, 0.40, 0.20)],
				[Color(0.96, 0.84, 0.46), Color(0.92, 0.72, 0.36), Color(0.98, 0.92, 0.70)],
				[Color(0.96, 0.56, 0.12), Color(0.78, 0.14, 0.12), Color(0.96, 0.86, 0.26)],
				[Color(0.96, 0.92, 0.82), Color(0.84, 0.66, 0.46), Color(0.96, 0.92, 0.82)],
				[Color(0.88, 0.86, 0.80), Color(0.76, 0.74, 0.68), Color(0.88, 0.86, 0.80)],
				[Color(0.80, 0.36, 0.14), Color(0.92, 0.70, 0.20), Color(0.56, 0.30, 0.18)],
				[Color(0.56, 0.22, 0.18), Color(0.82, 0.46, 0.40), Color(0.92, 0.84, 0.74)],
				[Color(0.62, 0.46, 0.30), Color(0.84, 0.72, 0.52), Color(0.46, 0.34, 0.22)]][trade]
			var ty := blk.position.y + 18.0
			while ty < blk.end.y - 18.0:
				b.rect(Rect2(cx - 36.0, ty - 12.0, 72.0, 26.0), Color(0.62, 0.50, 0.36))
				for f in range(8):
					b.circle(Vector2(cx - 30.0 + float(f % 4) * 20.0, ty - 5.0 + float(f / 4) * 12.0), 5.0,
						pal[(f + int(ty)) % 3])
				ty += 34.0
		b.flush(_wc)
		b = ShapeBatch.new()
		for side in [-1.0, 1.0]:
			var trade := (bi * 2 + (0 if side < 0.0 else 1)) % 8
			var sx: float = mid + side * 50.0
			_wc.draw_rect(Rect2(sx - 38.0, blk.position.y - 4.0, 76.0, 16.0), Color(0.12, 0.26, 0.20))
			_wc.draw_string(font, Vector2(sx - 38.0, blk.position.y + 8.0), String(signs[trade]),
				HORIZONTAL_ALIGNMENT_CENTER, 76.0, 11, Color(0.96, 0.90, 0.72))
	# the drain in the middle aisle, grated, a little wet round it
	var dr: Vector2 = LevelBuild.MERCAT_DRAIN
	if dr.y > vt - 60.0 and dr.y < vb + 60.0:
		b.circle(dr, 22.0, Color(0.40, 0.44, 0.48, 0.25))
	b.flush(_wc)


# the overhead layer's picture: El Gotic's bridge, carved stone, a
# pointed-arch window in its side, over the alley at GOTIC_BRIDGE_Y
func draw_overhead_onto(c: CanvasItem) -> void:
	if lvl == "spook":
		_draw_castanyada_lanterns(c)
		return
	if lvl == "market":
		_draw_mercat_arch(c, LevelBuild.MERCAT_ARCH_Y, "MERCAT")
		_draw_mercat_arch(c, LevelBuild.MERCAT_DOOR_Y, "PLAÇA")
		return
	if lvl != "oldtown":
		return
	var by: float = LevelBuild.GOTIC_BRIDGE_Y
	var e := walk_edges(by)
	var b := ShapeBatch.new(c)
	var r := Rect2(e.x - 30.0, by - 34.0, e.y - e.x + 60.0, 68.0)
	b.rect(r, Color(0.52, 0.47, 0.40))
	b.rect(Rect2(r.position.x, r.position.y, r.size.x, 8.0), Color(0.64, 0.58, 0.50))
	b.rect(Rect2(r.position.x, r.end.y - 8.0, r.size.x, 8.0), Color(0.40, 0.36, 0.31))
	var wx := r.position.x + 40.0
	while wx < r.end.x - 40.0:
		b.rect(Rect2(wx - 10.0, by - 14.0, 20.0, 28.0), Color(0.22, 0.20, 0.18))
		b.circle(Vector2(wx, by - 14.0), 10.0, Color(0.22, 0.20, 0.18))
		wx += 70.0
	b.flush()


# a kennel beside each sleeping guard dog, its chain run out to the dog
func _draw_kennels(vt: float, vb: float) -> void:
	var b := ShapeBatch.new()
	for gp: Vector2 in guard_posts:
		if gp.y < vt - 80.0 or gp.y > vb + 80.0:
			continue
		var side := -1.0 if gp.x < walk_cx else 1.0
		var kp := gp + Vector2(side * 46.0, -10.0)
		b.rect(Rect2(kp.x - 22.0 + 6.0, kp.y - 18.0 + 8.0, 44.0, 36.0), Color(0, 0, 0, 0.2))
		b.rect(Rect2(kp.x - 22.0, kp.y - 18.0, 44.0, 36.0), Color(0.44, 0.30, 0.18))
		b.rect(Rect2(kp.x - 22.0, kp.y - 18.0, 44.0, 10.0), Color(0.34, 0.22, 0.14))
		b.line(Vector2(kp.x, kp.y - 18.0), Vector2(kp.x, kp.y + 18.0), Color(0.30, 0.20, 0.12), 2.0)
		b.rect(Rect2(kp.x - side * 22.0 - 5.0, kp.y - 6.0, 10.0, 14.0), Color(0.08, 0.06, 0.05))
		var n := 5
		for k in range(n):
			b.circle(kp.lerp(gp, (float(k) + 0.5) / float(n)), 2.0, Color(0.62, 0.62, 0.64))
	b.flush(_wc)


# The crane over the yard: its tracks and cab off the lane's east side, and
# the long shadow of its boom lying across the lane with the magnet's.
func _draw_crane(vt: float, vb: float) -> void:
	var cb: Vector2 = LevelBuild.FERRALLA_CRANE
	var tip: Vector2 = LevelBuild.FERRALLA_BOOM_TO
	if maxf(cb.y, tip.y) < vt - 120.0 or minf(cb.y, tip.y) > vb + 120.0:
		return
	var b := ShapeBatch.new()
	var sh := Color(SHADOW_COL.r, SHADOW_COL.g, SHADOW_COL.b, 0.22)
	b.line(cb + Vector2(20, 40), tip + Vector2(30, 60), sh, 18.0)
	b.circle(tip + Vector2(30, 90), 26.0, sh)
	b.rect(Rect2(cb.x - 40.0, cb.y - 50.0, 80.0, 100.0), Color(0.16, 0.16, 0.17))
	b.rect(Rect2(cb.x - 30.0, cb.y - 30.0, 60.0, 60.0), Color(0.92, 0.70, 0.12))
	b.rect(Rect2(cb.x - 26.0, cb.y - 26.0, 22.0, 22.0), Color(0.30, 0.38, 0.44))
	# the boom itself, lattice, from the cab out over the lane
	b.line(cb, tip, Color(0.90, 0.68, 0.10), 10.0)
	var n := int(cb.distance_to(tip) / 24.0)
	for k in range(n):
		var p0: Vector2 = cb.lerp(tip, float(k) / float(n))
		var p1: Vector2 = cb.lerp(tip, float(k + 1) / float(n))
		b.line(p0 + Vector2(0, -5), p1 + Vector2(0, 5), Color(0.70, 0.52, 0.08), 2.0)
	# the magnet, hanging
	b.circle(tip, 20.0, Color(0.22, 0.22, 0.24))
	b.circle(tip, 14.0, Color(0.36, 0.36, 0.40))
	b.flush(_wc)


# A row of luggage trolleys nested into each other, the length of a van.
func _draw_trolleys(v: Vector2) -> void:
	var b := ShapeBatch.new()
	b.rect(Rect2(v.x - 26.0 + 8.0, v.y - 64.0 + 10.0, 52.0, 128.0), Color(SHADOW_COL.r, SHADOW_COL.g, SHADOW_COL.b, 0.18))
	for k in range(6):
		var ty := v.y - 64.0 + float(k) * 21.0
		b.rect(Rect2(v.x - 24.0, ty, 48.0, 30.0), Color(0.62, 0.64, 0.68))
		b.rect(Rect2(v.x - 20.0, ty + 4.0, 40.0, 22.0), Color(0.40, 0.42, 0.46))
		b.line(Vector2(v.x - 26.0, ty), Vector2(v.x + 26.0, ty), Color(0.80, 0.20, 0.20), 3.0)
	b.flush(_wc)


# The parked digger, from above: two rubber tracks on their rollers, the
# yellow house on top with its engine deck, exhaust and striped counterweight
# at the back, the cab with its glass roof on the left, and the boom and dipper
# folded forward on their rams, the bucket's teeth resting on a heap of spoil.
# Same footprint as a van; one batch, one draw call.
func _draw_digger(v: Vector2) -> void:
	var b := ShapeBatch.new()
	var yel := Color(0.93, 0.70, 0.12)
	var yel_d := Color(0.72, 0.52, 0.08)
	var yel_l := Color(1.0, 0.84, 0.36)
	var steel := Color(0.70, 0.72, 0.74)
	b.polygon(round_rect_pts(Rect2(v.x - 36.0 + 10.0, v.y - 50.0 + 14.0, 72.0, 100.0), 10.0),
		Color(SHADOW_COL.r, SHADOW_COL.g, SHADOW_COL.b, 0.20))
	# the tracks: rubber pads over a sprocket and an idler at each end
	for tx: float in [-36.0, 20.0]:
		var tr := Rect2(v.x + tx, v.y - 50.0, 16.0, 100.0)
		b.polygon(round_rect_pts(tr, 7.0), Color(0.13, 0.13, 0.14))
		b.polygon(round_rect_pts(tr.grow(-3.0), 5.0), Color(0.22, 0.22, 0.24))
		var ty := v.y - 44.0
		while ty < v.y + 44.0:
			b.line(Vector2(tr.position.x + 2.0, ty), Vector2(tr.end.x - 2.0, ty), Color(0.10, 0.10, 0.11), 2.4)
			ty += 7.0
		for ey: float in [-41.0, 41.0]:
			b.circle(Vector2(tr.get_center().x, v.y + ey), 4.0, Color(0.34, 0.34, 0.36))
	# the house: rounded, its shaded rim, the lit upper-left of the deck
	var house := Rect2(v.x - 28.0, v.y - 26.0, 56.0, 64.0)
	b.polygon(round_rect_pts(house.grow(1.5), 12.0), yel_d)
	b.polygon(round_rect_pts(house, 11.0), yel)
	b.polygon(round_rect_pts(Rect2(house.position + Vector2(4, 4), Vector2(30, 22)), 8.0), yel_l)
	# the counterweight at the back, hazard-striped
	var cw := Rect2(v.x - 26.0, v.y + 30.0, 52.0, 12.0)
	b.polygon(round_rect_pts(cw, 5.0), Color(0.16, 0.16, 0.17))
	for k in range(6):
		var sx := cw.position.x + 4.0 + float(k) * 8.0
		b.line(Vector2(sx, cw.end.y - 2.0), Vector2(sx + 6.0, cw.position.y + 2.0), yel, 3.0)
	# the engine deck: louvres, and the exhaust stack with soot round it
	for k in range(4):
		var gy := v.y + 12.0 + float(k) * 4.0
		b.line(Vector2(v.x + 4.0, gy), Vector2(v.x + 22.0, gy), yel_d, 1.6)
	b.circle(Vector2(v.x + 18.0, v.y + 4.0), 4.0, Color(0.20, 0.20, 0.20, 0.5))
	b.circle(Vector2(v.x + 18.0, v.y + 4.0), 2.6, Color(0.16, 0.16, 0.17))
	# the cab on the left: a dark frame, a glass roof with the sky in it
	var cab := Rect2(v.x - 26.0, v.y - 22.0, 22.0, 30.0)
	b.polygon(round_rect_pts(cab, 4.0), Color(0.18, 0.18, 0.20))
	b.polygon(round_rect_pts(cab.grow(-2.5), 3.0), Color(0.36, 0.48, 0.56))
	b.polygon(PackedVector2Array([cab.position + Vector2(4, 4), cab.position + Vector2(14, 4),
		cab.position + Vector2(5, 15)]), Color(0.72, 0.84, 0.90, 0.7))
	b.line(Vector2(cab.position.x + 2.5, cab.get_center().y + 2.0), Vector2(cab.end.x - 2.5, cab.get_center().y + 2.0),
		Color(0.18, 0.18, 0.20), 1.6)
	# the boom from its foot beside the cab, the dipper folded back down
	var foot := v + Vector2(8.0, -22.0)
	var knee := v + Vector2(10.0, -66.0)
	var wrist := v + Vector2(2.0, -80.0)
	b.line(foot + LIGHT * 4.0, knee + LIGHT * 4.0, Color(SHADOW_COL.r, SHADOW_COL.g, SHADOW_COL.b, 0.25), 12.0)
	b.polygon(PackedVector2Array([foot + Vector2(-7, 0), foot + Vector2(7, 0), knee + Vector2(4, 0), knee + Vector2(-4, 0)]), yel_d)
	b.polygon(PackedVector2Array([foot + Vector2(-5, 0), foot + Vector2(3, 0), knee + Vector2(1, 0), knee + Vector2(-3, 0)]), yel)
	# the ram along the boom: a steel rod out of its yellow cylinder
	b.line(foot + Vector2(-1, -4), foot.lerp(knee, 0.55) + Vector2(-1, 0), yel_d, 4.0)
	b.line(foot.lerp(knee, 0.55) + Vector2(-1, 0), knee + Vector2(-1, 6), steel, 2.0)
	b.line(knee, wrist, yel_d, 8.0)
	b.line(knee, wrist, yel, 5.0)
	b.circle(knee, 4.0, Color(0.28, 0.28, 0.30))
	b.circle(knee, 1.6, steel)
	# the spoil heap, and the bucket on it, teeth down
	# (heaped on the road side: the kerb side has a hydrant by it)
	b.circle(wrist + Vector2(10, -6), 12.0, Color(0.46, 0.36, 0.25))
	b.circle(wrist + Vector2(0, -10), 9.0, Color(0.52, 0.41, 0.28))
	b.circle(wrist + Vector2(16, -12), 6.0, Color(0.58, 0.47, 0.33))
	var bk := Rect2(wrist.x - 13.0, wrist.y - 13.0, 26.0, 12.0)
	b.polygon(round_rect_pts(bk, 3.0), Color(0.26, 0.26, 0.28))
	b.polygon(round_rect_pts(Rect2(bk.position + Vector2(2, 2), bk.size - Vector2(4, 6)), 2.0), Color(0.40, 0.40, 0.42))
	for k in range(5):
		var tx2 := bk.position.x + 3.0 + float(k) * 5.0
		b.polygon(PackedVector2Array([Vector2(tx2 - 1.6, bk.position.y), Vector2(tx2 + 1.6, bk.position.y),
			Vector2(tx2, bk.position.y - 4.0)]), steel)
	b.flush(_wc)


# LES OBRES: the pours in their formwork with tape round them, the fresh
# zebra, the trench with its plank and pipe, all drawn over the paving.
func _draw_obres(vt: float, vb: float) -> void:
	var b := ShapeBatch.new()
	for cz: Rect2 in cement_zones:
		if cz.end.y < vt - 40.0 or cz.position.y > vb + 40.0:
			continue
		# the timber formwork, then the wet pour inside it, float marks on top
		b.rect(cz.grow(7.0), Color(0.56, 0.42, 0.26))
		b.rect(cz.grow(3.0), Color(0.44, 0.32, 0.20))
		b.rect(cz, Color(0.60, 0.60, 0.58))
		var fy := cz.position.y + 16.0
		while fy < cz.end.y - 8.0:
			b.line(Vector2(cz.position.x + 10.0, fy), Vector2(cz.end.x - 10.0, fy + 4.0), Color(0.68, 0.68, 0.66), 2.0)
			fy += 22.0
		# tape round the cones at the corners, red and white
		var corners: Array[Vector2] = []
		for c: Vector2 in [cz.position, Vector2(cz.end.x, cz.position.y), cz.end, Vector2(cz.position.x, cz.end.y)]:
			corners.append(c + (c - cz.get_center()).normalized() * 16.0)
		for k in range(4):
			var a: Vector2 = corners[k]
			var c2: Vector2 = corners[(k + 1) % 4]
			var n := int(a.distance_to(c2) / 12.0)
			for j in range(n):
				var p0 := a.lerp(c2, float(j) / float(n))
				var p1 := a.lerp(c2, float(j + 1) / float(n))
				b.line(p0, p1, Color(0.90, 0.20, 0.18) if j % 2 == 0 else Color(0.96, 0.96, 0.94), 2.0)
	# the zebra, freshly painted: wet white bars with a sheen
	var zy: float = LevelBuild.OBRES_ZEBRA_Y
	if zy > vt - 80.0 and zy < vb + 80.0:
		var ze := walk_edges(zy)
		var zx := ze.x + 36.0
		while zx < ze.y - 36.0:
			b.rect(Rect2(zx, zy + 4.0, 26.0, LevelBuild.OBRES_ZEBRA_H - 8.0), Color(0.96, 0.95, 0.90))
			b.rect(Rect2(zx + 3.0, zy + 6.0, 5.0, LevelBuild.OBRES_ZEBRA_H - 12.0), Color(1, 1, 1, 0.9))
			zx += 46.0
	# the trench: dug earth at the lips, dark inside, a pipe along the bottom,
	# and the plank across it
	var ty: float = LevelBuild.OBRES_TRENCH_Y
	var th: float = LevelBuild.OBRES_TRENCH_H
	if ty > vt - 80.0 and ty < vb + 80.0:
		for c: Rect2 in cellars:
			b.rect(c.grow(6.0), Color(0.46, 0.36, 0.25))
			b.rect(c, Color(0.16, 0.13, 0.11))
			b.rect(Rect2(c.position.x, c.position.y + th * 0.5 - 5.0, c.size.x, 10.0), Color(0.72, 0.42, 0.20))
			b.rect(Rect2(c.position.x, c.position.y + th * 0.5 - 5.0, c.size.x, 3.0), Color(0.84, 0.56, 0.30))
		var te := walk_edges(ty)
		var pc := (te.x + te.y) * 0.5
		var plank := Rect2(pc - LevelBuild.OBRES_PLANK * 0.5 - 6.0, ty - 10.0, LevelBuild.OBRES_PLANK + 12.0, th + 20.0)
		b.rect(Rect2(plank.position + LIGHT * 6.0, plank.size), Color(0, 0, 0, 0.22))
		b.rect(plank, Color(0.66, 0.50, 0.30))
		for k in range(3):
			var px := plank.position.x + 8.0 + float(k) * (plank.size.x - 16.0) / 2.0
			b.line(Vector2(px, plank.position.y), Vector2(px, plank.end.y), Color(0.50, 0.37, 0.22), 2.0)
	b.flush(_wc)


func sheltered(p: Vector2) -> bool:
	for r: Rect2 in shelters:
		if r.has_point(p):
			return true
	return false


# El Diluvi: the owner soaks in the open and dries under cover; the dog
# splashing through a puddle at speed is a trick
func _tick_wet(delta: float) -> void:
	var was := human_soak
	if sheltered(human.global_position):
		human_soak = maxf(0.0, human_soak - delta / DRY_T)
	else:
		human_soak = minf(1.0, human_soak + delta / SOAK_T)
	if was < 0.5 and human_soak >= 0.5:
		human.notice("I'm SOAKED", 1.6)
		feed.say("YOUR HUMAN IS HALF SOAKED", EventFeed.Tone.BAD)
	splash_cd = maxf(0.0, splash_cd - delta)
	if splash_cd <= 0.0 and dog.velocity.length() > SPLASH_SPEED:
		for pt: Dictionary in patches:
			if String(pt["kind"]) == "puddle" and patch_has_point(pt, dog.global_position):
				splashes += 1
				splash_cd = 0.8
				Sfx.play("splash", 1.2)
				combo.add("SPLASH", 3)
				float_text(dog.global_position + Vector2(0, -26), "SPLASH!", Color(0.75, 0.88, 1.0))
				# and anyone near gets it too
				if human.global_position.distance_to(dog.global_position) < 70.0:
					human_soak = minf(1.0, human_soak + 0.06)
				break


# L'ESTACIO: the concourse floor's big tiles, the departures board, the
# barrier cabinets, the platform edges and the train standing between them.
func _draw_estacio(vt: float, vb: float) -> void:
	var b := ShapeBatch.new()
	# big polished tiles, ruled inside the path wherever it is
	var ty := floorf((vt - 60.0) / 132.0) * 132.0
	while ty < vb + 60.0:
		var e := walk_edges(ty)
		b.line(Vector2(e.x, ty), Vector2(e.y, ty), Color(0, 0, 0, 0.07), 2.0)
		var tx := floorf(e.x / 132.0) * 132.0 + 132.0
		while tx < e.y:
			b.line(Vector2(tx, ty), Vector2(tx, ty + 132.0), Color(0, 0, 0, 0.07), 2.0)
			tx += 132.0
		ty += 132.0
	# the departures board, hung over the way in
	var bd: Vector2 = LevelBuild.ESTACIO_BOARD
	var board_on := bd.y > vt - 80.0 and bd.y < vb + 80.0
	if board_on:
		# its shadow, the steel case with a lit top edge, the dark face, and
		# the heading strip; the rows are written after the batch (text)
		b.rect(Rect2(bd.x - 154.0 + 10.0, bd.y - 38.0 + 16.0, 308.0, 76.0), Color(0, 0, 0, 0.18))
		b.rect(Rect2(bd.x - 154.0, bd.y - 38.0, 308.0, 76.0), Color(0.42, 0.44, 0.48))
		b.rect(Rect2(bd.x - 154.0, bd.y - 38.0, 308.0, 3.0), Color(0.66, 0.68, 0.72))
		b.rect(Rect2(bd.x - 150.0, bd.y - 34.0, 300.0, 68.0), Color(0.07, 0.07, 0.09))
		b.rect(Rect2(bd.x - 150.0, bd.y - 34.0, 300.0, 13.0), Color(0.16, 0.30, 0.56))
		for row in range(4):
			b.line(Vector2(bd.x - 146.0, bd.y - 7.0 + float(row) * 11.0), Vector2(bd.x + 146.0, bd.y - 7.0 + float(row) * 11.0),
				Color(1, 1, 1, 0.04), 1.0)
	# the ticket barriers: grey cabinets, and the glass paddles in each gap
	var by: float = LevelBuild.ESTACIO_BARRIER_Y
	if by > vt - 60.0 and by < vb + 60.0:
		for i in range(deco_pole_count):
			var p := poles[i]
			if absf(p.y - by) < 1.0:
				b.rect(Rect2(p.x - 12.0, p.y - 18.0, 24.0, 36.0), Color(0.46, 0.48, 0.52))
				b.rect(Rect2(p.x - 12.0, p.y - 18.0, 24.0, 6.0), Color(0.62, 0.64, 0.68))
				b.circle(p + Vector2(0, 4), 3.0, Color(0.30, 0.85, 0.40))
		for g: float in LevelBuild.ESTACIO_GAPS:
			b.rect(Rect2(g - 30.0, by - 2.0, 22.0, 4.0), Color(0.75, 0.85, 0.95, 0.6))
			b.rect(Rect2(g + 8.0, by - 2.0, 22.0, 4.0), Color(0.75, 0.85, 0.95, 0.6))
	# the train, and the yellow lines along both platform edges
	var tr: Rect2 = LevelBuild.ESTACIO_TRAIN
	if tr.end.y > vt - 40.0 and tr.position.y < vb + 40.0:
		for ex: float in [tr.position.x - 22.0, tr.end.x + 14.0]:
			b.rect(Rect2(ex, maxf(tr.position.y - 30.0, vt - 40.0), 8.0, minf(tr.end.y + 30.0, vb + 40.0) - maxf(tr.position.y - 30.0, vt - 40.0)), Color(0.95, 0.80, 0.20))
		b.rect(Rect2(tr.position + Vector2(10, 14), tr.size), Color(SHADOW_COL.r, SHADOW_COL.g, SHADOW_COL.b, 0.22))
		var cy := tr.position.y
		while cy < tr.end.y - 10.0:
			var car := Rect2(tr.position.x, cy, tr.size.x, minf(230.0, tr.end.y - cy))
			b.rect(car, Color(0.80, 0.82, 0.84))
			b.rect(Rect2(car.position.x, car.position.y, 10.0, car.size.y), Color(0.86, 0.87, 0.89))
			b.rect(Rect2(car.end.x - 22.0, car.position.y, 12.0, car.size.y), Color(0.72, 0.16, 0.18))
			for vk in range(3):
				b.rect(Rect2(car.get_center().x - 22.0, car.position.y + 34.0 + float(vk) * 64.0, 44.0, 18.0), Color(0.64, 0.66, 0.70))
			cy += 240.0
		b.circle(Vector2(tr.get_center().x, tr.position.y + 6.0), 10.0, Color(0.95, 0.95, 0.80))   # the headlamp
	b.flush(_wc)
	if board_on:
		_draw_departures(bd)


# The departures board's rows, amber dot-matrix on black: time, where to and
# the platform, the way Rodalies boards read. One train is always cancelled.
const DEPARTURES := [["10:42", "SITGES", "4"], ["10:47", "MATARÓ", "CANCEL·LAT"],
	["10:55", "GIRONA", "2"], ["11:03", "VIC", "5"]]


func _draw_departures(bd: Vector2) -> void:
	var amber := Color(1.0, 0.72, 0.18)
	_wc.draw_string(font, Vector2(bd.x - 144.0, bd.y - 24.0), "SORTIDES", HORIZONTAL_ALIGNMENT_LEFT, -1, 10,
		Color(0.94, 0.96, 1.0))
	_wc.draw_string(font, Vector2(bd.x + 40.0, bd.y - 24.0), "departures", HORIZONTAL_ALIGNMENT_LEFT, -1, 9,
		Color(0.80, 0.86, 0.96, 0.8))
	for row in range(DEPARTURES.size()):
		var d: Array = DEPARTURES[row]
		var y := bd.y - 10.0 + float(row) * 11.0
		_wc.draw_string(font, Vector2(bd.x - 144.0, y), String(d[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, amber)
		_wc.draw_string(font, Vector2(bd.x - 100.0, y), String(d[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, amber)
		var cancelled := String(d[2]).length() > 2
		_wc.draw_string(font, Vector2(bd.x + 144.0 - (68.0 if cancelled else 10.0), y), String(d[2]),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.98, 0.34, 0.28) if cancelled else amber)


# EL DILUVI: the arcade (a roof behind its pillars, arches between), the
# awnings, the gutters running down both sides, and the owner's wet meter.
func _draw_diluvi(vt: float, vb: float) -> void:
	var b := ShapeBatch.new()
	var t := AnimClock.msec() / 1000.0
	# the gutters, running
	var gy := floorf((vt - 60.0) / 46.0) * 46.0
	while gy < vb + 60.0:
		var ge := walk_edges(gy)
		for gx: float in [ge.x + 6.0, ge.y - 6.0]:
			b.rect(Rect2(gx - 4.0, gy, 8.0, 46.0), Color(0.30, 0.36, 0.42))
			var fl := fmod(gy + t * 90.0, 46.0)
			b.line(Vector2(gx, gy + fl), Vector2(gx, gy + fl + 12.0), Color(0.75, 0.84, 0.92, 0.6), 2.0)
		gy += 46.0
	# the awnings: striped canvas over the pavement, dripping at the edge
	for i in range(1, shelters.size()):
		var r: Rect2 = shelters[i]
		if r.end.y < vt - 40.0 or r.position.y > vb + 40.0:
			continue
		b.rect(Rect2(r.position + Vector2(-8, 10), r.size), Color(SHADOW_COL.r, SHADOW_COL.g, SHADOW_COL.b, 0.18))
		var ac: Color = [Color(0.62, 0.20, 0.22), Color(0.20, 0.36, 0.30), Color(0.22, 0.30, 0.50)][i % 3]
		b.rect(r, ac)
		var sx := r.position.x + 6.0
		while sx < r.end.x:
			b.rect(Rect2(sx, r.position.y, 6.0, r.size.y), ac.lightened(0.25))
			sx += 14.0
		for k in range(3):
			var dy := fmod(t * 60.0 + float(k) * 13.0 + r.position.y, 26.0)
			b.circle(Vector2(r.position.x - 3.0, r.position.y + 12.0 + float(k) * r.size.y / 3.0 + dy * 0.3), 1.6, Color(0.8, 0.88, 0.95, 0.8))
	# the arcade: its vaulted roof seen from above, a shadow under it
	if not shelters.is_empty():
		var ar: Rect2 = shelters[0]
		if ar.end.y > vt - 40.0 and ar.position.y < vb + 40.0:
			var y0 := maxf(ar.position.y, vt - 40.0)
			var y1 := minf(ar.end.y, vb + 40.0)
			b.rect(Rect2(ar.position.x, y0, ar.size.x, y1 - y0), Color(0.46, 0.40, 0.36))
			b.rect(Rect2(ar.end.x - 10.0, y0, 10.0, y1 - y0), Color(0.36, 0.31, 0.28))
			var vy := floorf(y0 / 120.0) * 120.0 + 20.0
			while vy < y1:
				b.line(Vector2(ar.position.x, vy), Vector2(ar.end.x, vy), Color(0.54, 0.48, 0.43), 3.0)
				vy += 120.0
	# how wet the owner is, a drip meter over their head once it shows
	if human_soak > 0.08:
		var hp: Vector2 = human.global_position + Vector2(-16.0, -40.0)
		b.rect(Rect2(hp.x, hp.y, 32.0, 5.0), Color(0.08, 0.08, 0.10, 0.7))
		b.rect(Rect2(hp.x, hp.y, 32.0 * human_soak, 5.0), Color(0.45, 0.65, 0.95) if human_soak < 0.5 else Color(0.30, 0.45, 0.85))
	b.flush(_wc)


# the narrow pavement between a "road" strip and the building line
const ROAD_PAVEMENT := 44.0


# La Rambla proper, not the First Walk that shares its boulevard
func rambla() -> bool:
	return lvl == "street" and not tutorial_mode


func _tick_rambla(delta: float) -> void:
	var dp := dog.global_position
	_tick_whistle(delta)
	_tick_shells(delta)
	# walk across a seller's blanket and you hear about it
	for i in range(blankets.size()):
		var bl: Dictionary = blankets[i]
		bl["cd"] = maxf(0.0, float(bl["cd"]) - delta)
		var r: Rect2 = bl["rect"]
		if String(bl.get("state", "laid")) == "laid" and r.grow(4.0).has_point(dp) and float(bl["cd"]) <= 0.0:
			bl["cd"] = 3.0
			float_text(_seller_pos(r) + Vector2(0, -22), "eh! EH!", Color(1, 0.9, 0.75), POP_SAY)
	# a human statue holds still until she stands and watches, then bows
	for i in range(statues.size()):
		statue_bow[i] = maxf(0.0, float(statue_bow.get(i, 0.0)) - delta)
		var sp: Vector2 = statues[i]
		if dp.distance_to(sp) < 70.0 and dog.velocity.length() < 40.0:
			statue_wait[i] = float(statue_wait.get(i, 0.0)) + delta
			if float(statue_wait[i]) >= STATUE_WATCH and float(statue_bow[i]) <= 0.0:
				statue_bow[i] = 2.2
				statue_wait[i] = -4.0      # not another bow straight away
				bones += 2
				combo.add("STATUE", 3)
				float_text(sp + Vector2(0, -34), "*bows*", Color(0.95, 0.9, 0.7))
		elif float(statue_wait.get(i, 0.0)) > 0.0:
			statue_wait[i] = 0.0

# stand and watch a human statue this long and it bows to her
const STATUE_WATCH := 1.0
# the whistle: the sellers bundle up their blankets and clear off for a while
const WHISTLE_FIRST := 24.0
const WHISTLE_EVERY := 42.0
const BUNDLE_SPEED := 150.0
const BUNDLE_AWAY := 8.0


func _tick_whistle(delta: float) -> void:
	whistle_t -= delta
	if whistle_t <= 0.0:
		var near: Array[Dictionary] = []
		for bl: Dictionary in blankets:
			if String(bl["state"]) == "laid" and absf((bl["rect"] as Rect2).get_center().y - cam.position.y) < 460.0:
				near.append(bl)
		if near.is_empty():
			whistle_t = 5.0
		else:
			whistle_t = WHISTLE_EVERY
			# the whistle from somewhere up the promenade: the tell for all of it
			float_text(Vector2(walk_cx, cam.position.y - 200.0), "PHWEEET!", Color(0.9, 0.95, 1.0))
			feed.say("PHWEET! THE SELLERS BOLT", EventFeed.Tone.LOUD)
			for bl: Dictionary in near:
				bl["state"] = "pack"
				bl["t"] = 0.0
	for bl: Dictionary in blankets:
		var st := String(bl["state"])
		if st == "laid":
			continue
		bl["t"] = float(bl["t"]) + delta
		var r: Rect2 = bl["rect"]
		var home: Vector2 = _seller_pos(r)
		match st:
			"pack":
				if float(bl["t"]) >= 0.6:
					# off to the nearer edge of the promenade, and along it
					var e := walk_edges(r.get_center().y)
					var ex := e.x + 18.0 if r.get_center().x < walk_cx else e.y - 18.0
					var along := -220.0 if int(r.position.y) % 2 == 0 else 220.0
					bl["to"] = Vector2(ex, r.get_center().y + along)
					bl["state"] = "carry"
					bl["t"] = 0.0
			"carry":
				var sp: Vector2 = bl["sp"]
				sp = sp.move_toward(bl["to"], BUNDLE_SPEED * delta)
				bl["sp"] = sp
				if sp.distance_to(bl["to"]) < 2.0:
					bl["state"] = "away"
					bl["t"] = 0.0
			"away":
				if float(bl["t"]) >= BUNDLE_AWAY:
					bl["state"] = "back"
					bl["t"] = 0.0
			"back":
				var sp2: Vector2 = bl["sp"]
				sp2 = sp2.move_toward(home, BUNDLE_SPEED * 0.7 * delta)
				bl["sp"] = sp2
				if sp2.distance_to(home) < 2.0:
					bl["state"] = "unpack"
					bl["t"] = 0.0
			"unpack":
				if float(bl["t"]) >= 0.6:
					bl["state"] = "laid"


# where a blanket seller is right now (on the move with the bundle, or by it)
func seller_at(bl: Dictionary) -> Vector2:
	return bl["sp"] if bl.has("sp") else _seller_pos(bl["rect"])


func bundle_moving(bl: Dictionary) -> bool:
	return String(bl.get("state", "laid")) in ["carry", "back"]


func _tick_shells(delta: float) -> void:
	if shell_game.is_empty():
		return
	if bool(shell_game["done"]):
		shell_game["t"] = float(shell_game["t"]) + delta
		return
	var sp: Vector2 = shell_game["pos"]
	if dog.global_position.distance_to(sp) < 34.0 and dog.velocity.length() > 200.0:
		_bust_shells("the dog ploughed through it")


func _bust_shells(_why: String) -> void:
	shell_game["done"] = true
	shell_game["t"] = 0.0
	var sp: Vector2 = shell_game["pos"]
	bones += 6
	combo.add("RIGGED", 6)
	float_text(sp + Vector2(0, -30), "THE GAME'S UP!", Color(1, 0.9, 0.5))
	feed.say("SHELL GAME BUSTED +6", EventFeed.Tone.GOOD)
	for tw: Node2D in get_tree().get_nodes_in_group("tourists"):
		if tw.global_position.distance_to(sp) < 240.0:
			tw.cheer()
# the crowd: this many tourists kept walking around the camera (El Mosaic's
# walkers are fewer; most of its tourists stand in the queue or at the
# salamander)
const CROWD_SIZE := 14
const MOSAIC_CROWD := 6
# El Mosaic's gate queue: this many people up the west side of the forecourt
const MOSAIC_QUEUE := 9
# where the posers stand round the salamander, from its middle: on its west
# and south, clear of the owner's way round its east side
const MOSAIC_POSERS: Array[Vector2] = [Vector2(-125, -60), Vector2(-120, 30), Vector2(-95, 115),
	Vector2(-170, -5), Vector2(-135, -140)]


# La Rambla and El Mosaic have a crowd, and pickpockets working it
func crowded() -> bool:
	return (lvl == "street" or lvl == "guell") and not tutorial_mode


func _spawn_tourist(at: Vector2, d: float) -> Node2D:
	var tw := Node2D.new()
	tw.set_script(load("res://entities/tourist.gd"))
	tw.z_index = 8
	add_child(tw)
	tw.setup(self, crowd_rng, at, d)
	return tw


# a flock of parakeets going up: one squawk for the lot of them
var squawk_t := 0.0


func parakeet_squawk(at: Vector2) -> void:
	if elapsed < squawk_t:
		return
	squawk_t = elapsed + 1.5
	Sfx.play("squawk", randf_range(0.9, 1.1), -8.0)
	float_text(at + Vector2(0, -16), "squawk!", Color(0.6, 0.9, 0.5))


func _tick_mosaic_groups() -> void:
	var cy: float = cam.position.y
	if not mosaic_queue_out:
		mosaic_queue_out = true
		var qe := walk_edges(0.0)
		for i in range(MOSAIC_QUEUE):
			var qy := 150.0 - float(i) * 36.0
			var tw := _spawn_tourist(Vector2(qe.x + 70.0 + crowd_rng.randf_range(-6.0, 6.0), qy), -1.0)
			tw.stand("queue", Vector2.ZERO)
	var sm: Vector2 = LevelBuild.MOSAIC_SALAMANDER
	if not mosaic_posers_out and cy < sm.y + 900.0:
		mosaic_posers_out = true
		for off: Vector2 in MOSAIC_POSERS:
			var tw := _spawn_tourist(sm + off, -1.0)
			tw.stand("pose", sm)
	# a dog drinking at the salamander is the photo everyone wanted
	if not mosaic_aww and dog.global_position.distance_to(sm) < 130.0:
		for tw: Node2D in get_tree().get_nodes_in_group("tourists"):
			if tw.mode == "pose" and tw.global_position.distance_to(dog.global_position) < 200.0:
				mosaic_aww = true
				float_text(tw.global_position + Vector2(0, -26), "aww, look at her", Color(1, 0.9, 0.95), POP_SAY)
				tw.photo_t = 1.2
				break
# pickpockets: the first this many seconds in, then one every PP_EVERY while
# none is at work, PP_MAX a walk. The first one always goes for the owner.
const PP_FIRST := 10.0
const PP_EVERY := 28.0
const PP_MAX := 3


func _tick_crowd(delta: float) -> void:
	if not crowd_seeded:
		crowd_seeded = true
		crowd_rng.seed = 0xC40D
	var cy: float = cam.position.y
	var n := 0
	for tw: Node2D in get_tree().get_nodes_in_group("tourists"):
		if absf(tw.global_position.y - cy) > 950.0:
			tw.queue_free()
		elif tw.mode == "amble":
			n += 1
	var mosaic := lvl == "guell"
	if mosaic:
		_tick_mosaic_groups()
	# the first fill puts people on screen too; after that they arrive from
	# off screen, so nobody pops into view
	var first_fill := n == 0
	while n < (MOSAIC_CROWD if mosaic else CROWD_SIZE):
		var y := cy + crowd_rng.randf_range(-680.0, 680.0)
		if absf(y - cy) < 420.0 and not first_fill:
			y = cy + (420.0 + crowd_rng.randf_range(0.0, 300.0)) * (1.0 if crowd_rng.randf() < 0.5 else -1.0)
		if y < GATE_Y + 200.0 or y > START_Y - 60.0:
			break
		var e := walk_edges(y)
		_spawn_tourist(Vector2(crowd_rng.randf_range(e.x + 40.0, e.y - 40.0), y),
			-1.0 if crowd_rng.randf() < 0.5 else 1.0)
		n += 1
	# a pickpocket, now and then, while none is at work
	if get_tree().get_nodes_in_group("pickpockets").size() > 0 or pp_spawned >= PP_MAX:
		return
	# El Mosaic's work the gate queue, so they start at the gate
	if cy > START_Y - (100.0 if mosaic else 500.0) or cy < GATE_Y + 900.0:
		return
	pp_spawn_t -= delta
	if pp_spawn_t > 0.0:
		return
	pp_spawn_t = PP_EVERY
	var target: Node2D = human
	var is_owner := pp_spawned == 0
	if not is_owner:
		var best := INF
		for tw: Node2D in get_tree().get_nodes_in_group("tourists"):
			var d: float = tw.global_position.distance_to(dog.global_position)
			if tw.has_wallet and d > 120.0 and d < best and absf(tw.global_position.y - cy) < 300.0:
				best = d
				target = tw
		if target == human:
			return
	pp_spawned += 1
	var pe := walk_edges(cy - 260.0)
	var from := Vector2(pe.x + 50.0 if target.global_position.x > walk_cx else pe.y - 50.0, cy - 260.0)
	# at El Mosaic he steps out of the queue, when there is one in sight
	if mosaic:
		for tw: Node2D in get_tree().get_nodes_in_group("tourists"):
			if tw.mode == "queue" and absf(tw.global_position.y - cy) < 300.0 \
					and tw.global_position.distance_to(target.global_position) > 90.0:
				from = tw.global_position + Vector2(24.0, 0.0)
				break
	var pp := Node2D.new()
	pp.set_script(load("res://entities/pickpocket.gd"))
	pp.z_index = 9
	add_child(pp)
	pp.setup(self, from, target, is_owner, crowd_rng.randf() * 10.0)
	feed.say("PICKPOCKET! WATCH HIS HANDS", EventFeed.Tone.LOUD)


func on_pickpocket_lift(at: Vector2, from_owner: bool) -> void:
	float_text(at + Vector2(0, -30), "my wallet?!" if not from_owner else "!", Color(1, 0.6, 0.5), POP_SAY)
	feed.say("HE'S GOT %s WALLET! STOP HIM" % ("YOUR HUMAN'S" if from_owner else "A"), EventFeed.Tone.BAD)


const PP_WHY := {"bump": "BOWLED OVER!", "tangle": "TANGLED!", "owner": "HUMAN BOWLING!",
	"blanket": "TRIPPED!", "slip": "SLIP!"}


func on_pickpocket_stopped(at: Vector2, why: String, lost: bool, mark: Node2D, from_owner: bool) -> void:
	Sfx.play("crack", 0.8, -6.0)
	float_text(at + Vector2(0, -28), String(PP_WHY.get(why, "GOT HIM!")), Color(1, 0.9, 0.5))
	if lost:
		# stopped, but the wallet went down the hole: a stop that earns nothing
		float_text(at + Vector2(0, -8), "...plop", Color(0.8, 0.85, 1.0))
		feed.say("IT WENT DOWN THE DRAIN", EventFeed.Tone.BAD)
		if from_owner:
			owner_wallet_taken = false
			owner_wallet_lost = true
		return
	thieves_stopped += 1
	wallets_returned += 1
	var pay := 15 if from_owner else 8
	bones += pay
	combo.add("THIEF", 10)
	if from_owner:
		owner_wallet_taken = false
		feed.say("YOUR HUMAN'S WALLET IS BACK +%d" % pay, EventFeed.Tone.GOOD)
	else:
		if mark != null and is_instance_valid(mark) and "has_wallet" in mark:
			mark.has_wallet = true
		feed.say("WALLET SAVED! +%d" % pay, EventFeed.Tone.GOOD)
	# the crowd round about applauds the dog
	for tw: Node2D in get_tree().get_nodes_in_group("tourists"):
		if tw.global_position.distance_to(at) < 260.0:
			tw.cheer()
	_update_hud()


func on_pickpocket_escaped(from_owner: bool) -> void:
	feed.say("HE GOT AWAY", EventFeed.Tone.BAD)
	if from_owner:
		owner_wallet_taken = false
		owner_wallet_lost = true


func on_pickpocket_busted(at: Vector2) -> void:
	# seen off before the lift
	thieves_stopped += 1
	bones += 4
	combo.add("BUSTED", 5)
	float_text(at + Vector2(0, -26), "BUSTED", Color(1, 0.9, 0.5))


func _seller_pos(r: Rect2) -> Vector2:
	# the seller stands on the promenade side of the blanket
	var inward := 1.0 if r.get_center().x < walk_cx else -1.0
	return Vector2(r.get_center().x + inward * (r.size.x * 0.5 + 16.0), r.get_center().y)


func _draw_rambla(vt: float, vb: float) -> void:
	var b := ShapeBatch.new()
	# the round pavement mosaic in the square: pale tiles, a ring, flat
	# primary shapes and a heavy black line through them
	var mc: Vector2 = LevelBuild.RAMBLA_MOSAIC
	var mr: float = LevelBuild.RAMBLA_MOSAIC_R
	if mc.y > vt - 100.0 and mc.y < vb + 100.0:
		b.circle(mc, mr + 6.0, Color(0.55, 0.52, 0.47))
		b.circle(mc, mr, Color(0.90, 0.87, 0.80))
		b.circle(mc + Vector2(-22, -14), 20.0, Color(0.82, 0.18, 0.16))
		b.circle(mc + Vector2(26, 18), 14.0, Color(0.14, 0.32, 0.66))
		b.circle(mc + Vector2(18, -30), 9.0, Color(0.96, 0.78, 0.12))
		b.circle(mc + Vector2(-30, 28), 8.0, Color(0.20, 0.52, 0.30))
		b.line(mc + Vector2(-52, 10), mc + Vector2(48, -20), Color(0.08, 0.08, 0.08), 5.0)
		b.line(mc + Vector2(-8, 44), mc + Vector2(6, -50), Color(0.08, 0.08, 0.08), 4.0)
		b.circle(mc + Vector2(26, 18), 5.0, Color(0.08, 0.08, 0.08))
	# the blankets and their goods, and the seller beside each; bundled up
	# and carried off when the whistle goes
	for bl: Dictionary in blankets:
		var r: Rect2 = bl["rect"]
		if r.end.y < vt - 240.0 or r.position.y > vb + 240.0:
			continue
		var bst := String(bl.get("state", "laid"))
		if bst != "laid":
			var sat := seller_at(bl)
			if bst in ["pack", "unpack"]:
				b.rect(Rect2(r.get_center() - Vector2(20, 14), Vector2(40, 28)), Color(0.86, 0.84, 0.80))
			b.circle(sat + Vector2(2, 3), 11.0, Color(0, 0, 0, 0.18))
			b.circle(sat, 11.0, Color(0.20, 0.24, 0.32))
			b.circle(sat + Vector2(0, -3), 6.5, Color(0.36, 0.24, 0.17))
			if bst in ["carry", "away", "back"]:
				# the whole stall in a sheet over his shoulder
				b.circle(sat + Vector2(12, 4), 13.0, Color(0.86, 0.84, 0.80))
				b.circle(sat + Vector2(10, 2), 9.0, Color(0.93, 0.92, 0.89))
				b.line(sat + Vector2(4, -4), sat + Vector2(10, -8), Color(0.55, 0.50, 0.45), 2.0)
			continue
		b.rect(Rect2(r.position + Vector2(2, 3), r.size), Color(0, 0, 0, 0.16))
		# a white sheet, tasselled at its ends, with the fold still in it
		for tx in range(int(r.size.y / 6.0)):
			for side: float in [r.position.x - 3.0, r.end.x]:
				b.rect(Rect2(side, r.position.y + 3.0 + float(tx) * 6.0, 3.0, 2.0), Color(0.80, 0.78, 0.74))
		b.rect(r, Color(0.84, 0.82, 0.78))
		b.rect(Rect2(r.position, r.size - Vector2(2, 2)), Color(0.92, 0.91, 0.88))
		b.line(Vector2(r.get_center().x, r.position.y + 2.0), Vector2(r.get_center().x, r.end.y - 3.0), Color(0.82, 0.80, 0.76), 1.5)
		var goods := String(bl["goods"])
		# the cords at the corners, gathered to the seller's hand: one pull
		# and the whole stall is a bundle
		var sp: Vector2 = bl["sp"]
		for corner: Vector2 in [r.position, Vector2(r.end.x, r.position.y), Vector2(r.position.x, r.end.y), r.end]:
			b.line(corner, corner.lerp(sp, 0.35), Color(0.30, 0.30, 0.34, 0.8), 1.2)
		b.line(Vector2(r.position.x + 2.0, r.get_center().y), Vector2(r.end.x - 3.0, r.get_center().y), Color(0.84, 0.82, 0.78), 1.0)
		var bi := posmod(int(r.position.y), 7)
		for gi in range(6):
			# laid out by hand: not quite a grid, not quite straight
			var jx := float((gi * 5 + bi) % 7) - 3.0
			var jy := float((gi * 3 + bi) % 5) - 2.0
			var gp := r.position + Vector2(13.0 + float(gi % 3) * 24.0 + jx, 14.0 + float(gi / 3) * 23.0 + jy)
			var tilt := (float((gi + bi) % 5) - 2.0) * 0.18
			_draw_blanket_good(b, goods, gp, tilt, gi + bi)
		b.circle(sp + Vector2(2, 3), 11.0, Color(0, 0, 0, 0.18))
		b.circle(sp, 11.0, Color(0.20, 0.24, 0.32))
		b.circle(sp + Vector2(0, -3), 6.5, Color(0.36, 0.24, 0.17))
	# the dropped ice cream: the cone, upside down in its pink puddle
	var ic: Vector2 = LevelBuild.RAMBLA_ICECREAM
	if ic.y > vt - 40.0 and ic.y < vb + 40.0:
		b.polygon(PackedVector2Array([ic + Vector2(-3, -2), ic + Vector2(12, -9), ic + Vector2(10, -1)]), Color(0.85, 0.66, 0.40))
		b.circle(ic + Vector2(-2, 1), 6.0, Color(0.98, 0.84, 0.88))
	# the shell game: a cardboard box, three cups, the man working it and his
	# shills leaning in; scattered and gone once it is busted
	if not shell_game.is_empty():
		var sg: Vector2 = shell_game["pos"]
		if sg.y > vt - 80.0 and sg.y < vb + 80.0:
			var busted := bool(shell_game["done"])
			var sbox := Rect2(sg.x - 22.0, sg.y - 14.0, 44.0, 28.0)
			box_shadow(b, sbox, 3.0, 5.0)
			clay_slab(b, sbox, 3.0, Color(0.66, 0.50, 0.32), 2.0)
			b.line(Vector2(sg.x - 21.0, sg.y), Vector2(sg.x + 20.0, sg.y), Color(0.52, 0.38, 0.24), 1.5)
			var tt2 := AnimClock.msec() / 1000.0
			for k in range(3):
				var cx := sg.x - 12.0 + float(k) * 12.0
				var cup := Vector2(cx + (0.0 if busted else sin(tt2 * 6.0 + float(k) * 2.1) * 6.0), sg.y)
				if busted:
					cup = sg + Vector2(-30.0 + float(k) * 34.0, 22.0 - float(k % 2) * 40.0)
				b.circle(cup + Vector2(1.0, 1.6), 5.0, Color(0, 0, 0, 0.22))
				b.circle(cup, 5.0, Color(0.16, 0.16, 0.18))
				b.circle(cup + Vector2(-0.6, -0.6), 3.8, Color(0.32, 0.32, 0.36))
				b.circle(cup + Vector2(-1.6, -1.6), 1.4, Color(0.70, 0.70, 0.74))
			if not busted:
				b.circle(sg + Vector2(0, -28), 11.0, Color(0.30, 0.26, 0.22))      # the man with the cups
				b.circle(sg + Vector2(0, -31), 6.5, Color(0.72, 0.56, 0.42))
				for k in range(4):
					var on := sg + Vector2.from_angle(PI * 0.25 + float(k) * PI * 0.33) * 34.0
					b.circle(on, 10.0, [Color(0.55, 0.40, 0.60), Color(0.35, 0.55, 0.45), Color(0.70, 0.50, 0.30), Color(0.40, 0.45, 0.60)][k])
					b.circle(on + Vector2(0, -3), 6.0, Color(0.86, 0.70, 0.56))
	# the human statues: a box, and a figure painted all one metal colour
	var t := AnimClock.msec() / 1000.0
	for i in range(statues.size()):
		var sp: Vector2 = statues[i]
		if sp.y < vt - 60.0 or sp.y > vb + 60.0:
			continue
		var paint := Color(0.80, 0.66, 0.30) if i % 2 == 0 else Color(0.72, 0.74, 0.76)
		var box := Rect2(sp.x - 16.0, sp.y - 16.0, 32.0, 32.0)
		box_shadow(b, box, 4.0, 9.0)
		# the box: a painted crate, lit on its upper-left, a seam near the front
		clay_slab(b, box, 4.0, Color(0.30, 0.27, 0.27), 3.0)
		b.line(Vector2(box.position.x + 3.0, box.end.y - 6.0), Vector2(box.end.x - 5.0, box.end.y - 6.0), Color(0.20, 0.18, 0.18), 1.5)
		var bow := float(statue_bow.get(i, 0.0))
		var lean := Vector2(0, 8.0 * sin(clampf(bow / 2.2, 0.0, 1.0) * PI)) if bow > 0.0 else Vector2.ZERO
		# the figure, painted head to foot in one metal: shoulders, the arm
		# held out frozen (it drops for the bow), the head under a hat, and
		# a hard sheen on the lit side that says paint, not skin
		b.polygon(ellipse_pts(sp + Vector2(0, 1), 13.0, 9.0), paint.darkened(0.35))
		b.polygon(ellipse_pts(sp + Vector2(-0.8, 0.2), 12.0, 8.0), paint)
		b.polygon(ellipse_pts(sp + Vector2(-4.5, -2.0), 5.0, 3.2), paint.lightened(0.30))
		var arm := Vector2(18, -10) if bow <= 0.0 else Vector2(8, 10)
		b.line(sp + Vector2(7, -1), sp + arm, paint.darkened(0.35), 5.5)
		b.line(sp + Vector2(7, -1.6), sp + arm + Vector2(0, -0.6), paint.darkened(0.02), 3.0)
		b.circle(sp + arm, 3.2, paint.darkened(0.30))
		b.circle(sp + arm + Vector2(-0.5, -0.5), 2.5, paint)
		# the other arm, down at the side
		b.circle(sp + Vector2(-11.0, 2.5), 3.6, paint.darkened(0.30))
		b.circle(sp + Vector2(-11.4, 2.0), 2.8, paint.darkened(0.04))
		var hp := sp + Vector2(0, -3) + lean
		b.circle(hp + Vector2(0.6, 0.6), 6.6, paint.darkened(0.38))
		b.circle(hp, 6.0, paint.darkened(0.06))
		if i % 2 == 1:
			# a bowler hat: brim and crown
			b.circle(hp + Vector2(0.4, 0.2), 7.6, paint.darkened(0.42))
			b.circle(hp + Vector2(-0.3, -0.5), 4.8, paint.darkened(0.12))
		else:
			# sculpted curls
			for cu in range(4):
				b.circle(hp + Vector2.from_angle(PI * 0.9 + float(cu) * 0.55) * 3.6, 2.0, paint.darkened(0.16))
		b.circle(hp + Vector2(-2.0, -2.2), 1.8, paint.lightened(0.50))
		b.circle(hp + Vector2(0.4, 5.6), 1.8, paint.darkened(0.22))    # the nose, to the front
		b.circle(sp + Vector2(-6.5, -1.5), 1.2, Color(1, 1, 1, 0.75))
		# the hat for coins on the paving in front
		b.circle(sp + Vector2(-2, 25), 7.0, Color(0.10, 0.09, 0.09))
		b.circle(sp + Vector2(-2.4, 24.4), 5.4, Color(0.20, 0.18, 0.18))
		b.circle(sp + Vector2(-4, 23.5), 1.7, Color(0.95, 0.82, 0.30))
		b.circle(sp + Vector2(-0.5, 25.5), 1.5, Color(0.84, 0.70, 0.26))
		if bow <= 0.0 and float(statue_wait.get(i, 0.0)) > 0.3:
			# the eyes slide towards her, under the brim: it is alive
			for ex: float in [-2.6, 2.6]:
				b.circle(hp + Vector2(ex, 3.6), 1.4, Color(0.98, 0.96, 0.92))
				b.circle(hp + Vector2(ex + 0.6 * sin(t * 3.0), 3.9), 0.8, Color(0.1, 0.1, 0.1))
	b.flush(_wc)


# The Canaletes fountain: a cast-iron column with four taps and a lamp on
# top, painted black, on a round step.
func _draw_canaletes(f: Vector2) -> void:
	contact_shadow(_wc, f, 16.0, 6.0, 0.25)
	_wc.draw_circle(f, 18.0, Color(0.52, 0.50, 0.46))
	_wc.draw_circle(f, 14.0, Color(0.36, 0.40, 0.44))
	for k in range(4):
		var d := Vector2.from_angle(TAU * float(k) / 4.0 + PI / 4.0)
		_wc.draw_line(f + d * 7.0, f + d * 15.0, Color(0.12, 0.12, 0.13), 3.0)
		_wc.draw_circle(f + d * 15.0, 2.4, Color(0.70, 0.62, 0.36))
	_wc.draw_circle(f, 8.0, Color(0.10, 0.10, 0.11))
	_wc.draw_circle(f + Vector2(-2, -2), 5.0, Color(0.95, 0.90, 0.72, 0.9))   # the lamp
	_wc.draw_circle(f + Vector2(14, 10), 5.0, Color(0.45, 0.6, 0.7, 0.5))     # the wet step


# A busker, from above: shoulders and a head of hair, a guitar slung across
# the front with the strumming hand going, the case lying open on the paving
# beside him with the day's coins in it, and notes going up. Colours come from
# where he stands, so the same busker always wears the same jumper.
func _draw_busker(pf: Vector2, idx: int, pt: float) -> void:
	var k := int(absf(pf.x * 3.0 + pf.y))
	var jumper: Color = [Color(0.52, 0.34, 0.54), Color(0.24, 0.46, 0.50), Color(0.30, 0.48, 0.30), Color(0.30, 0.34, 0.52)][k % 4]
	var hair: Color = [Color(0.20, 0.14, 0.10), Color(0.46, 0.28, 0.14), Color(0.12, 0.11, 0.11)][k % 3]
	var skin: Color = [Color(0.86, 0.70, 0.56), Color(0.64, 0.44, 0.32), Color(0.92, 0.76, 0.62)][(k / 3) % 3]
	var wood := Color(0.86, 0.50, 0.20)
	contact_shadow(_wc, pf, 14.0, 5.0, 0.22)
	# the open case, on the paving to his right: lid, red lining, coins
	var cs := pf + Vector2(28.0, 13.0)
	contact_shadow(_wc, cs, 14.0, 2.0, 0.16)
	_wc.draw_colored_polygon(round_rect_pts(Rect2(cs.x - 14.0, cs.y - 7.0, 28.0, 15.0), 6.0), Color(0.16, 0.12, 0.10))
	_wc.draw_colored_polygon(round_rect_pts(Rect2(cs.x - 12.0, cs.y - 5.0, 24.0, 11.0), 5.0), Color(0.62, 0.14, 0.18))
	_wc.draw_colored_polygon(round_rect_pts(Rect2(cs.x - 11.0, cs.y - 4.5, 12.0, 5.0), 2.5), Color(0.76, 0.24, 0.26))
	for c in range(4):
		var cp := cs + Vector2(-7.0 + float((k + c * 5) % 14), -2.0 + float((k + c * 3) % 5))
		_wc.draw_circle(cp, 1.9, Color(0.70, 0.56, 0.20))
		_wc.draw_circle(cp + Vector2(-0.4, -0.4), 1.3, Color(0.98, 0.86, 0.38))
	# the shoulders, a ball of jumper lit on its upper-left
	_wc.draw_colored_polygon(ellipse_pts(pf + Vector2(0.5, 1.0), 13.0, 10.0), jumper.darkened(0.32))
	_wc.draw_colored_polygon(ellipse_pts(pf + Vector2(-0.6, -0.2), 12.0, 9.0), jumper)
	_wc.draw_colored_polygon(ellipse_pts(pf + Vector2(-4.5, -3.0), 5.0, 3.4), jumper.lightened(0.22))
	# the guitar, slung across the front: body low on his left, neck up to
	# his right with the fretting hand on it
	var gb := pf + Vector2(-5.0, 9.0)
	var gn := pf + Vector2(16.0, -3.0)
	_wc.draw_line(gb, gn, Color(0.30, 0.20, 0.12), 3.6)
	_wc.draw_line(gb, gn, Color(0.50, 0.34, 0.20), 1.6)
	_wc.draw_colored_polygon(round_rect_pts(Rect2(gn.x - 1.0, gn.y - 3.5, 6.0, 5.0), 1.5), Color(0.24, 0.16, 0.10))
	_wc.draw_circle(gb + Vector2(-3.0, 1.5), 7.4, wood.darkened(0.40))
	_wc.draw_circle(gb + Vector2(-3.4, 1.2), 6.6, wood)
	_wc.draw_circle(gb + Vector2(2.6, -1.2), 5.4, wood.darkened(0.40))
	_wc.draw_circle(gb + Vector2(2.2, -1.5), 4.7, wood)
	_wc.draw_circle(gb + Vector2(-5.4, -0.8), 2.4, wood.lightened(0.30))
	_wc.draw_circle(gb + Vector2(0.4, -0.2), 2.2, Color(0.14, 0.09, 0.06))
	# the hands: one on the neck, one strumming over the sound hole
	var strum := sin(pt * 9.0 + float(idx)) * 2.2
	_wc.draw_circle(pf + Vector2(10.0, -1.0), 2.8, skin.darkened(0.15))
	_wc.draw_circle(gb + Vector2(1.5 + strum * 0.3, 2.5 + strum), 2.8, skin)
	# the head: mostly hair from up here, a sliver of face to the front
	var hp := pf + Vector2(0.0, -2.0)
	_wc.draw_circle(hp + Vector2(0.5, 2.6), 6.4, skin.darkened(0.10))
	_wc.draw_circle(hp, 6.8, hair.darkened(0.20))
	_wc.draw_circle(hp + Vector2(-0.5, -0.6), 6.0, hair)
	_wc.draw_circle(hp + Vector2(-2.4, -2.4), 2.2, hair.lightened(0.28))
	# music, going up
	for i in range(2):
		var ny := fmod(pt * 22.0 + i * 20.0, 44.0)
		var np := pf + Vector2(14.0 + i * 10.0 - ny * 0.2, -14.0 - ny)
		var na := clampf(1.0 - ny / 44.0, 0.0, 1.0) * 0.8
		_wc.draw_circle(np, 3.0, Color(1, 1, 1, na))
		_wc.draw_line(np + Vector2(2.5, -1), np + Vector2(2.5, -9), Color(1, 1, 1, na), 1.5)


# A La Rambla stall by what it sells. Same footprint as a market stall
# (STALL_BODY_SIZE), so bodies, wrap points and blockers are unchanged.
func _draw_cellar(c: Rect2) -> void:
	var b := ShapeBatch.new()
	var steel := Color(0.40, 0.41, 0.44)
	var tread := Color(0.54, 0.55, 0.58)
	b.rect(Rect2(c.position + LIGHT * 4.0, c.size).grow(3.0), Color(0, 0, 0, 0.18))
	b.rect(c.grow(3.0), Color(0.60, 0.58, 0.54))
	var lw := c.size.x * 0.24
	var hole := Rect2(c.position.x + lw, c.position.y + 3.0, c.size.x - lw * 2.0, c.size.y - 6.0)
	for side in range(2):
		var leaf := Rect2(c.position.x if side == 0 else c.end.x - lw, c.position.y, lw, c.size.y)
		b.rect(leaf, steel)
		b.rect(Rect2(leaf.position.x, leaf.position.y, leaf.size.x, 2.0), steel.lightened(0.25))
		var ty := leaf.position.y + 5.0
		var k := 0
		while ty < leaf.end.y - 4.0:
			var x0 := leaf.position.x + (3.0 if k % 2 == 0 else 6.0)
			b.line(Vector2(x0, ty), Vector2(x0 + 3.5, ty + 2.0), tread, 1.4)
			ty += 6.0
			k += 1
		var hx := leaf.end.x - 2.0 if side == 0 else leaf.position.x
		for hy: float in [leaf.position.y + 8.0, leaf.end.y - 14.0]:
			b.rect(Rect2(hx, hy, 2.0, 6.0), Color(0.16, 0.16, 0.18))
	b.rect(hole, Color(0.06, 0.06, 0.07))
	# the treads, lit where the daylight reaches down into it
	var n := 5
	for k in range(n):
		var sy := hole.end.y - float(k + 1) * hole.size.y / float(n + 1)
		b.rect(Rect2(hole.position.x, sy, hole.size.x, 4.0),
			Color(0.36, 0.32, 0.28, 0.85 - 0.15 * float(k)))
	# the delivery: two crates on a sack truck beside the hatch
	var tx := c.end.x + 6.0
	b.line(Vector2(tx + 2.0, c.position.y + 6.0), Vector2(tx + 2.0, c.position.y + 46.0), Color(0.22, 0.22, 0.24), 2.0)
	for cr in range(2):
		var cy := c.position.y + 8.0 + float(cr) * 18.0
		b.rect(Rect2(tx + 4.0, cy, 18.0, 16.0), Color(0.62, 0.46, 0.28))
		b.rect(Rect2(tx + 4.0, cy, 18.0, 3.0), Color(0.72, 0.56, 0.36))
		b.line(Vector2(tx + 4.0, cy + 9.0), Vector2(tx + 22.0, cy + 9.0), Color(0.48, 0.34, 0.20), 1.2)
	b.circle(Vector2(tx + 4.0, c.position.y + 47.0), 3.0, Color(0.12, 0.12, 0.13))
	b.circle(Vector2(tx + 20.0, c.position.y + 47.0), 3.0, Color(0.12, 0.12, 0.13))
	b.flush(_wc)


# people browsing at a La Rambla stall, pressed up to its front: not solid,
# so they stand close enough to the counter that nobody walks through them
const BROWSER_SHIRTS := [Color(0.86, 0.30, 0.28), Color(0.25, 0.45, 0.70), Color(0.92, 0.84, 0.62),
	Color(0.30, 0.52, 0.36), Color(0.62, 0.40, 0.62), Color(0.95, 0.95, 0.92)]
const BROWSER_HAIR := [Color(0.16, 0.12, 0.10), Color(0.42, 0.28, 0.16), Color(0.80, 0.66, 0.40), Color(0.30, 0.30, 0.32)]
const BROWSER_SKIN := [Color(0.92, 0.76, 0.62), Color(0.62, 0.44, 0.32), Color(0.82, 0.64, 0.50), Color(0.45, 0.30, 0.22)]


func _draw_browsers(b: ShapeBatch, r: Rect2, i: int) -> void:
	# the counter faces the middle of the promenade
	var face_right := r.get_center().x < 640.0
	var fwd := Vector2.LEFT if face_right else Vector2.RIGHT
	var fx := r.end.x + 12.0 if face_right else r.position.x - 12.0
	var count := 2 + (i % 2)
	for k in range(count):
		var h := (i * 7 + k * 13) % 97
		var p := Vector2(fx + float(h % 5) - 2.0, r.position.y + 10.0 + float(k) * (r.size.y - 16.0) / float(maxi(count - 1, 1)))
		var lean := fwd.rotated((float(h % 7) - 3.0) * 0.08)
		b.circle(p + Vector2(3, 4), 10.0, Color(0, 0, 0, 0.16))
		HumanAppearance.draw_torso(b, p, lean, Vector2(8.0, 10.5), BROWSER_SHIRTS[h % BROWSER_SHIRTS.size()])
		HumanAppearance.draw_head(b, p + lean * 3.0, lean, 6.0, BROWSER_SKIN[h % BROWSER_SKIN.size()],
			BROWSER_HAIR[(h / 3) % BROWSER_HAIR.size()], ["short", "long", "curly", "bun"][h % 4])


# one thing on a seller's blanket, drawn as itself
func _draw_blanket_good(b: ShapeBatch, goods: String, p: Vector2, tilt: float, k: int) -> void:
	var ax := Vector2.RIGHT.rotated(tilt)
	var ay := ax.orthogonal()
	match goods:
		"shades":
			# a pair of sunglasses, folded: two lenses, the bridge, the arms
			var frame: Color = [Color(0.08, 0.08, 0.10), Color(0.46, 0.28, 0.16), Color(0.92, 0.90, 0.86), Color(0.70, 0.16, 0.18)][k % 4]
			for s: float in [-1.0, 1.0]:
				var lc := p + ax * 5.0 * s
				b.circle(lc, 4.4, frame)
				b.circle(lc, 3.2, Color(0.12, 0.14, 0.18))
				b.circle(lc - Vector2(1.2, 1.2), 1.0, Color(1, 1, 1, 0.6))
				b.line(lc - ay * 3.6 + ax * 3.0 * s, lc - ay * 3.6 - ax * 3.0 * s, frame, 1.2)
			b.line(p - ax * 1.2, p + ax * 1.2, frame, 1.6)
		"bags":
			# a handbag: a soft trapezoid body, the strap up over it, a clasp
			var col: Color = [Color(0.66, 0.46, 0.28), Color(0.12, 0.12, 0.14), Color(0.72, 0.18, 0.22), Color(0.90, 0.86, 0.76)][k % 4]
			var body := PackedVector2Array([p - ax * 8.0 + ay * 6.0, p + ax * 8.0 + ay * 6.0,
				p + ax * 6.0 - ay * 3.0, p - ax * 6.0 - ay * 3.0])
			b.polygon(body, col)
			b.line(p - ax * 4.0 - ay * 3.0, p - ax * 2.0 - ay * 8.0, col.darkened(0.3), 1.6)
			b.line(p - ax * 2.0 - ay * 8.0, p + ax * 2.0 - ay * 8.0, col.darkened(0.3), 1.6)
			b.line(p + ax * 2.0 - ay * 8.0, p + ax * 4.0 - ay * 3.0, col.darkened(0.3), 1.6)
			b.circle(p + ay * 0.5, 1.4, Color(0.86, 0.74, 0.34))
		_:
			# toys: a football, a light-up spinner, a little plush bear
			match k % 3:
				0:
					b.circle(p, 5.0, Color(0.96, 0.96, 0.94))
					b.circle(p, 2.0, Color(0.12, 0.12, 0.14))
					for a in range(5):
						b.circle(p + Vector2.from_angle(TAU * float(a) / 5.0 + tilt) * 4.0, 1.0, Color(0.12, 0.12, 0.14))
				1:
					for a in range(3):
						var bl := Vector2.from_angle(TAU * float(a) / 3.0 + tilt)
						b.line(p, p + bl * 7.0, [Color(0.95, 0.3, 0.6), Color(0.3, 0.8, 0.95), Color(0.98, 0.85, 0.3)][a], 2.4)
					b.circle(p, 2.2, Color(0.95, 0.95, 0.9))
				_:
					b.circle(p + ay * 2.0, 4.6, Color(0.66, 0.46, 0.30))
					b.circle(p - ay * 3.0, 3.6, Color(0.70, 0.50, 0.32))
					b.circle(p - ay * 3.0 - ax * 3.0 - ay * 2.0, 1.6, Color(0.56, 0.38, 0.24))
					b.circle(p - ay * 3.0 + ax * 3.0 - ay * 2.0, 1.6, Color(0.56, 0.38, 0.24))
					b.circle(p - ay * 2.4, 0.8, Color(0.1, 0.1, 0.1))


func _draw_rambla_stall(st: Vector2, kind: String, i: int) -> void:
	var b := ShapeBatch.new()
	var r := Rect2(st.x - 48.0, st.y - 28.0, 96.0, 56.0)
	if kind == "icecream" or kind == "caricature":
		b.rect(Rect2(r.position + LIGHT * 12.0, r.size), Color(SHADOW_COL.r, SHADOW_COL.g, SHADOW_COL.b, 0.22))
	else:
		box_shadow(b, r, 5.0, 12.0)
	match kind:
		"kiosk":
			# the newspaper kiosk: a dark green box with a pitched roof,
			# racks of magazines and postcards round it
			b.rect(r, Color(0.18, 0.30, 0.24))
			b.rect(r.grow(-6.0), Color(0.24, 0.38, 0.30))
			b.line(Vector2(r.position.x + 6.0, st.y), Vector2(r.end.x - 6.0, st.y), Color(0.14, 0.24, 0.19), 3.0)
			for k in range(8):
				var mc: Color = [Color(0.9, 0.3, 0.3), Color(0.95, 0.85, 0.3), Color(0.3, 0.55, 0.9), Color(0.95, 0.95, 0.9)][k % 4]
				b.rect(Rect2(r.position.x + 4.0 + float(k) * 11.5, r.end.y - 2.0, 9.0, 8.0), mc)
		"flowers":
			# a flower stall: green iron frame, buckets of blooms spilling out
			b.rect(r, Color(0.20, 0.34, 0.22))
			for k in range(12):
				var fc: Color = [Color(0.92, 0.30, 0.40), Color(0.98, 0.84, 0.30), Color(0.96, 0.60, 0.20), Color(0.70, 0.40, 0.85), Color(0.98, 0.98, 0.95)][(k + i) % 5]
				var fp := Vector2(r.position.x + 10.0 + float(k % 6) * 15.0, r.position.y + 14.0 + float(k / 6) * 26.0)
				b.circle(fp, 7.0, Color(0.26, 0.44, 0.24))
				b.circle(fp + Vector2(-1, -1), 4.5, fc)
			for k in range(4):
				b.circle(Vector2(r.position.x + 12.0 + float(k) * 24.0, r.end.y + 7.0), 6.0, Color(0.48, 0.50, 0.52))
				b.circle(Vector2(r.position.x + 12.0 + float(k) * 24.0, r.end.y + 6.0), 4.0, [Color(0.95, 0.4, 0.5), Color(0.98, 0.9, 0.4)][k % 2])
		"souvenir":
			# football shirts on a rail, fans and fridge magnets
			b.rect(r, Color(0.46, 0.36, 0.28))
			for k in range(5):
				var sc: Color = [Color(0.62, 0.12, 0.24), Color(0.12, 0.22, 0.52)][k % 2]
				var sx := r.position.x + 12.0 + float(k) * 18.0
				b.rect(Rect2(sx - 6.0, r.position.y + 6.0, 12.0, 20.0), sc)
				b.line(Vector2(sx - 6.0, r.position.y + 12.0), Vector2(sx + 6.0, r.position.y + 12.0), [Color(0.12, 0.22, 0.52), Color(0.62, 0.12, 0.24)][k % 2], 3.0)
			for k in range(6):
				b.circle(Vector2(r.position.x + 12.0 + float(k) * 15.0, r.end.y - 12.0), 5.0, [Color(0.95, 0.75, 0.2), Color(0.9, 0.3, 0.25), Color(0.3, 0.6, 0.85)][k % 3])
		"books":
			# second-hand books on a trestle, spines up in rows, a couple
			# lying open, a crate of comics at the end
			b.rect(r, Color(0.44, 0.32, 0.22))
			b.rect(r.grow(-4.0), Color(0.52, 0.38, 0.26))
			var spine := [Color(0.62, 0.16, 0.18), Color(0.16, 0.30, 0.52), Color(0.86, 0.78, 0.56),
				Color(0.24, 0.42, 0.28), Color(0.20, 0.18, 0.18), Color(0.82, 0.52, 0.22)]
			for row in range(2):
				var bx := r.position.x + 6.0
				var k := row * 5 + i
				while bx < r.end.x - 34.0:
					var w := 3.0 + float(k % 3)
					b.rect(Rect2(bx, r.position.y + 6.0 + float(row) * 22.0, w, 16.0 - float(k % 2) * 2.0), spine[k % spine.size()])
					bx += w + 1.0
					k += 1
			for ob in range(2):
				var op := Vector2(r.end.x - 30.0, r.position.y + 7.0 + float(ob) * 22.0)
				b.rect(Rect2(op, Vector2(24.0, 16.0)), Color(0.96, 0.95, 0.90))
				b.line(op + Vector2(12, 1), op + Vector2(12, 15), Color(0.70, 0.68, 0.62), 1.2)
				for ln in range(3):
					b.line(op + Vector2(3, 4 + ln * 4), op + Vector2(10, 4 + ln * 4), Color(0.6, 0.6, 0.6), 1.0)
					b.line(op + Vector2(14, 4 + ln * 4), op + Vector2(21, 4 + ln * 4), Color(0.6, 0.6, 0.6), 1.0)
		"painter":
			# a painter's pitch: a rack of small framed views of the city
			# (the sea, the Sagrada's spires, a sunset) and the easel
			b.rect(Rect2(r.position.x, r.position.y, 60.0, r.size.y), Color(0.30, 0.24, 0.20))
			var views := [[Color(0.30, 0.56, 0.80), Color(0.94, 0.84, 0.56)], [Color(0.96, 0.62, 0.30), Color(0.62, 0.36, 0.28)],
				[Color(0.40, 0.66, 0.42), Color(0.86, 0.86, 0.80)], [Color(0.92, 0.46, 0.40), Color(0.32, 0.30, 0.52)]]
			for k in range(6):
				var fp := Vector2(r.position.x + 5.0 + float(k % 3) * 18.0, r.position.y + 5.0 + float(k / 3) * 25.0)
				var v: Array = views[(k + i) % views.size()]
				b.rect(Rect2(fp, Vector2(16.0, 21.0)), Color(0.78, 0.62, 0.30))
				b.rect(Rect2(fp + Vector2(2, 2), Vector2(12.0, 17.0)), v[0])
				b.rect(Rect2(fp + Vector2(2, 12), Vector2(12.0, 7.0)), v[1])
			b.line(Vector2(st.x + 24.0, st.y - 22.0), Vector2(st.x + 34.0, st.y + 20.0), Color(0.45, 0.32, 0.20), 3.0)
			b.line(Vector2(st.x + 44.0, st.y - 22.0), Vector2(st.x + 34.0, st.y + 20.0), Color(0.45, 0.32, 0.20), 3.0)
			b.rect(Rect2(st.x + 22.0, st.y - 26.0, 24.0, 18.0), Color(0.98, 0.97, 0.94))
			b.rect(Rect2(st.x + 25.0, st.y - 23.0, 18.0, 6.0), Color(0.30, 0.56, 0.80))
			b.rect(Rect2(st.x + 25.0, st.y - 17.0, 18.0, 6.0), Color(0.94, 0.84, 0.56))
		"icecream":
			# the ice cream cart under its striped umbrella
			b.rect(Rect2(st.x - 30.0, st.y - 18.0, 60.0, 36.0), Color(0.95, 0.93, 0.88))
			b.rect(Rect2(st.x - 30.0, st.y - 18.0, 60.0, 6.0), Color(0.55, 0.78, 0.86))
			for k in range(8):
				var a := TAU * float(k) / 8.0
				b.polygon(PackedVector2Array([st, st + Vector2.from_angle(a) * 34.0, st + Vector2.from_angle(a + TAU / 8.0) * 34.0]),
					Color(0.95, 0.45, 0.55, 0.85) if k % 2 == 0 else Color(0.98, 0.96, 0.92, 0.85))
			b.circle(st, 3.0, Color(0.4, 0.35, 0.3))
			for wx: float in [-22.0, 22.0]:
				b.circle(Vector2(st.x + wx, st.y + 20.0), 5.0, Color(0.15, 0.15, 0.16))
		"fruit":
			# a greengrocer's counter: crates tipped towards the aisle, piled
			# with oranges, lemons, apples, grapes, and little price cards
			b.rect(r, Color(0.46, 0.33, 0.22))
			for k in range(6):
				var cr := Rect2(r.position.x + 4.0 + float(k % 3) * 30.0, r.position.y + 4.0 + float(k / 3) * 26.0, 28.0, 24.0)
				b.rect(cr, Color(0.66, 0.50, 0.32))
				var fc: Color = [Color(0.96, 0.56, 0.12), Color(0.96, 0.86, 0.26), Color(0.78, 0.14, 0.12),
					Color(0.52, 0.72, 0.20), Color(0.48, 0.24, 0.46), Color(0.96, 0.56, 0.12)][(k + i) % 6]
				for f in range(5):
					b.circle(cr.position + Vector2(6.0 + float(f % 3) * 8.0, 7.0 + float(f / 3) * 9.0), 4.6, fc)
				b.rect(Rect2(cr.position.x + 18.0, cr.end.y - 7.0, 9.0, 6.0), Color(0.97, 0.96, 0.92))
		"fish":
			# the fish counter: steel, a bed of crushed ice, the catch laid on
			# it head to tail, lemon halves; the meltwater is on the floor
			b.rect(r, Color(0.58, 0.60, 0.62))
			b.rect(r.grow(-4.0), Color(0.88, 0.93, 0.96))
			for k in range(14):
				b.circle(r.position + Vector2(8.0 + float(k * 13 % 80), 8.0 + float(k * 7 % 40)), 2.5, Color(1, 1, 1, 0.8))
			for k in range(5):
				var fp := Vector2(r.position.x + 14.0 + float(k) * 17.0, st.y + (6.0 if k % 2 == 0 else -6.0))
				var fcol: Color = [Color(0.66, 0.70, 0.74), Color(0.86, 0.56, 0.52), Color(0.56, 0.62, 0.70)][k % 3]
				b.polygon(PackedVector2Array([fp + Vector2(0, -12), fp + Vector2(5, -2), fp + Vector2(0, 10),
					fp + Vector2(-5, -2)]), fcol)
				b.polygon(PackedVector2Array([fp + Vector2(0, 9), fp + Vector2(5, 15), fp + Vector2(-5, 15)]), fcol.darkened(0.2))
			b.circle(Vector2(r.end.x - 10.0, r.position.y + 10.0), 5.0, Color(0.98, 0.88, 0.30))
		"jamon":
			# the ham counter: whole legs laid in a row, hoof to hip, sausages
			# hanging off the front rail
			b.rect(r, Color(0.30, 0.20, 0.14))
			for k in range(4):
				var hp := Vector2(r.position.x + 14.0 + float(k) * 23.0, st.y - 4.0)
				b.circle(hp + Vector2(0, 6), 10.0, Color(0.56, 0.24, 0.18))
				b.circle(hp + Vector2(-2, 4), 5.0, Color(0.92, 0.84, 0.74))
				b.line(hp + Vector2(0, -4), hp + Vector2(0, -16), Color(0.20, 0.13, 0.10), 4.0)
			for k in range(7):
				b.circle(Vector2(r.position.x + 8.0 + float(k) * 13.0, r.end.y - 5.0), 4.0, Color(0.52, 0.16, 0.14))
		"olives":
			# tubs of olives and pickles, green and black and purple
			b.rect(r, Color(0.44, 0.36, 0.26))
			for k in range(6):
				var tp := Vector2(r.position.x + 16.0 + float(k % 3) * 32.0, r.position.y + 15.0 + float(k / 3) * 26.0)
				b.circle(tp, 12.0, Color(0.86, 0.84, 0.78))
				var oc: Color = [Color(0.42, 0.52, 0.18), Color(0.16, 0.14, 0.14), Color(0.40, 0.20, 0.30)][(k + i) % 3]
				b.circle(tp, 9.5, oc)
				b.circle(tp + Vector2(-3, -3), 2.5, oc.lightened(0.35))
		"juice":
			# the juice stand: cups in rows, every colour of fruit going
			b.rect(r, Color(0.94, 0.92, 0.86))
			for k in range(12):
				var cp := Vector2(r.position.x + 10.0 + float(k % 6) * 15.0, r.position.y + 16.0 + float(k / 6) * 22.0)
				var jc: Color = [Color(0.96, 0.56, 0.12), Color(0.86, 0.22, 0.34), Color(0.56, 0.78, 0.24),
					Color(0.98, 0.84, 0.30), Color(0.64, 0.30, 0.60), Color(0.98, 0.66, 0.60)][k % 6]
				b.circle(cp, 6.0, Color(1, 1, 1, 0.9))
				b.circle(cp, 4.6, jc)
		"sweets":
			# pick-and-mix: bins of jellies and chocolates under the counter glass
			b.rect(r, Color(0.86, 0.60, 0.70))
			for k in range(8):
				var bin := Rect2(r.position.x + 4.0 + float(k % 4) * 22.5, r.position.y + 4.0 + float(k / 4) * 24.0, 20.0, 22.0)
				b.rect(bin, Color(0.97, 0.95, 0.94))
				var sc: Color = [Color(0.96, 0.40, 0.56), Color(0.98, 0.86, 0.30), Color(0.40, 0.66, 0.92),
					Color(0.36, 0.22, 0.14)][(k + i) % 4]
				for d in range(4):
					b.circle(bin.position + Vector2(5.0 + float(d % 2) * 10.0, 6.0 + float(d / 2) * 10.0), 3.4, sc)
		"castanyes":
			# a chestnut seller's barrow: the brazier drum glowing, chestnuts
			# roasting on its grille, paper cones stacked ready
			b.rect(r, Color(0.36, 0.24, 0.16))
			b.circle(Vector2(st.x - 14.0, st.y), 22.0, Color(0.18, 0.16, 0.16))
			b.circle(Vector2(st.x - 14.0, st.y), 17.0, Color(0.96, 0.46, 0.14))
			b.circle(Vector2(st.x - 14.0, st.y), 11.0, Color(1.0, 0.76, 0.30))
			for k in range(7):
				b.circle(Vector2(st.x - 14.0, st.y) + Vector2.from_angle(float(k) * 0.9) * 9.0, 3.2, Color(0.38, 0.20, 0.10))
			for k in range(4):
				var cp := Vector2(st.x + 22.0 + float(k % 2) * 14.0, st.y - 12.0 + float(k / 2) * 22.0)
				b.polygon(PackedVector2Array([cp + Vector2(-6, -8), cp + Vector2(6, -8), cp + Vector2(0, 9)]),
					Color(0.92, 0.88, 0.78))
		"panellets":
			# trays of panellets: little marzipan balls rolled in pine nuts,
			# and some in coconut, some in cocoa
			b.rect(r, Color(0.52, 0.36, 0.24))
			for t in range(2):
				var tr := Rect2(r.position.x + 5.0 + float(t) * 45.0, r.position.y + 6.0, 40.0, 44.0)
				b.rect(tr, Color(0.90, 0.86, 0.80))
				for k in range(9):
					var pp := tr.position + Vector2(7.0 + float(k % 3) * 13.0, 8.0 + float(k / 3) * 13.0)
					var pc: Color = [Color(0.90, 0.74, 0.46), Color(0.96, 0.94, 0.88), Color(0.44, 0.28, 0.18)][(k + t) % 3]
					b.circle(pp, 5.0, pc)
					if (k + t) % 3 == 0:
						b.circle(pp + Vector2(-1.5, -1.5), 1.4, Color(0.98, 0.90, 0.70))
		"moniatos":
			# roast sweet potatoes, split, on a griddle
			b.rect(r, Color(0.30, 0.22, 0.18))
			b.rect(r.grow(-6.0), Color(0.20, 0.18, 0.18))
			for k in range(6):
				var mp := Vector2(r.position.x + 18.0 + float(k % 3) * 30.0, st.y + (-10.0 if k < 3 else 10.0))
				b.circle(mp + Vector2(-5, 0), 7.0, Color(0.46, 0.24, 0.20))
				b.circle(mp + Vector2(5, 0), 7.0, Color(0.46, 0.24, 0.20))
				b.circle(mp, 4.0, Color(0.98, 0.62, 0.24))
		"caricature":
			# an easel, a stool for the sitter, drawings pegged up to show
			b.rect(Rect2(st.x - 46.0, st.y - 26.0, 44.0, 52.0), Color(0.93, 0.92, 0.88))
			for k in range(4):
				var cp := Vector2(st.x - 36.0 + float(k % 2) * 22.0, st.y - 14.0 + float(k / 2) * 26.0)
				b.circle(cp, 7.0, Color(0.96, 0.84, 0.70))
				b.circle(cp + Vector2(0, -2), 4.0, Color(0.24, 0.20, 0.18))
			b.line(Vector2(st.x + 12.0, st.y - 20.0), Vector2(st.x + 26.0, st.y + 22.0), Color(0.45, 0.32, 0.20), 3.0)
			b.line(Vector2(st.x + 40.0, st.y - 20.0), Vector2(st.x + 26.0, st.y + 22.0), Color(0.45, 0.32, 0.20), 3.0)
			b.rect(Rect2(st.x + 12.0, st.y - 24.0, 28.0, 20.0), Color(0.98, 0.97, 0.94))
			b.circle(Vector2(st.x + 26.0, st.y + 30.0), 7.0, Color(0.36, 0.26, 0.18))
	if kind == "icecream":
		# the cart is narrower than a stall: they queue at its side
		_draw_browsers(b, r.grow_individual(-18.0, 0.0, -18.0, 0.0), i)
	elif kind != "caricature":
		_draw_browsers(b, r, i)
	if kind != "icecream" and kind != "caricature" and kind != "painter":
		# the counter's edges, plasticine-soft: a lit lip along the top and
		# left, a dark rim along the bottom and right where it turns away
		b.line(Vector2(r.position.x + 1.0, r.position.y + 1.5), Vector2(r.end.x - 2.0, r.position.y + 1.5), Color(1, 1, 1, 0.26), 3.0)
		b.line(Vector2(r.position.x + 1.5, r.position.y + 1.0), Vector2(r.position.x + 1.5, r.end.y - 2.0), Color(1, 1, 1, 0.20), 3.0)
		b.line(Vector2(r.position.x + 2.0, r.end.y - 1.5), Vector2(r.end.x, r.end.y - 1.5), Color(0, 0, 0, 0.26), 3.0)
		b.line(Vector2(r.end.x - 1.5, r.position.y + 2.0), Vector2(r.end.x - 1.5, r.end.y), Color(0, 0, 0, 0.30), 3.0)
	b.flush(_wc)


# the brink lesson's pond: a muddy bank and the water, like El Parc's lake
func _draw_tutorial_pond() -> void:
	var r: Rect2 = LevelBuild.tutorial_pond(self)
	var pc := r.get_center()
	var bank := {"y": pc.y, "at": 0.5, "rx": r.size.x * 0.5, "ry": r.size.y * 0.5, "seed": 1.9}
	_draw_pinned_patch(bank, pc, Color(0.40, 0.36, 0.28), 1.08)
	_draw_pinned_patch(bank, pc, Color(0.31, 0.44, 0.52), 0.94)


# The grind lesson's stone ledge: a long low wall beside the path, its coping
# pale and worn smooth, made to be ridden (systems/rails.gd).
func _draw_tutorial_ledge(vt: float, vb: float) -> void:
	var at := TutorialSteps.at("grind")
	var r := Rect2(Rails.TUT_LEDGE_X - 9.0, at - Rails.TUT_LEDGE_HALF, 18.0, Rails.TUT_LEDGE_HALF * 2.0)
	if r.end.y < vt or r.position.y > vb:
		return
	var b := ShapeBatch.new()
	b.rect(Rect2(r.position + Vector2(5, 6), r.size), Color(0, 0, 0, 0.18))
	b.rect(r, Color(0.62, 0.58, 0.52))
	b.rect(Rect2(r.position.x + 2.0, r.position.y, r.size.x - 4.0, r.size.y), Color(0.80, 0.77, 0.70))
	var y := r.position.y + 30.0
	while y < r.end.y:
		b.rect(Rect2(r.position.x, y, r.size.x, 2.0), Color(0.52, 0.48, 0.42))
		y += 30.0
	b.flush(_wc)


# EL BARRI: the petanca pitch with its boules, and the playground. Nothing
# here is anywhere in particular.
func _draw_barri(vt: float, vb: float) -> void:
	var b := ShapeBatch.new()
	var pp: Rect2 = LevelBuild.BARRI_PETANCA
	if pp.end.y > vt - 40.0 and pp.position.y < vb + 40.0:
		b.rect(pp.grow(5.0), Color(0.52, 0.40, 0.26))
		b.rect(pp, Color(0.82, 0.74, 0.56))
		for k in range(6):
			var bp := pp.position + Vector2(20.0 + fmod(float(k) * 37.0, pp.size.x - 40.0), 30.0 + fmod(float(k) * 71.0, pp.size.y - 60.0))
			b.circle(bp + Vector2(1, 2), 5.0, Color(0, 0, 0, 0.2))
			b.circle(bp, 5.0, Color(0.62, 0.62, 0.64))
			b.circle(bp + Vector2(-1.5, -1.5), 2.0, Color(0.85, 0.85, 0.88))
		b.circle(pp.position + Vector2(pp.size.x * 0.5, 40.0), 3.0, Color(0.85, 0.30, 0.20))   # the jack
	var pg: Rect2 = LevelBuild.BARRI_PLAYGROUND
	if pg.end.y > vt - 40.0 and pg.position.y < vb + 40.0:
		_playground(b, pg)
	b.flush(_wc)


# the ping-pong table: concrete, a net across it, a white line round
func _draw_pingpong(st: Vector2) -> void:
	var r := Rect2(st.x - 44.0, st.y - 24.0, 88.0, 48.0)
	contact_shadow(_wc, st, 44.0, 8.0, 0.22)
	_wc.draw_rect(r, Color(0.36, 0.48, 0.44))
	_wc.draw_rect(r.grow(-3.0), Color(0.42, 0.56, 0.50))
	_wc.draw_rect(r.grow(-3.0), Color(0.92, 0.92, 0.88), false, 1.5)
	_wc.draw_line(Vector2(st.x, r.position.y - 4.0), Vector2(st.x, r.end.y + 4.0), Color(0.18, 0.18, 0.20), 3.0)


# EL PARC's own furniture, on the lawns beside the path: box-hedged
# flowerbeds (their edging is a grind rail), the bandstand, the Ciutadella
# mammoth, and the playground.
func _draw_parc(vt: float, vb: float) -> void:
	var b := ShapeBatch.new()
	var flower_cols := [Color(0.86, 0.30, 0.34), Color(0.95, 0.78, 0.30), Color(0.62, 0.42, 0.78), Color(0.96, 0.95, 0.92)]
	for bed: Rect2 in LevelBuild.PARK_BEDS:
		if bed.end.y < vt - 40.0 or bed.position.y > vb + 40.0:
			continue
		_flowerbed(b, bed, flower_cols)
	# the mammoth: grey stone, a huge domed head, the trunk curled, tusks
	var mp: Vector2 = LevelBuild.PARK_MAMMOTH
	if mp.y > vt - 120.0 and mp.y < vb + 120.0:
		var stone := Color(0.42, 0.38, 0.35)
		var mbs: Vector2 = LevelBuild.MAMMOTH_BODY
		b.rect(Rect2(mp - mbs * 0.5 - Vector2(8, 22), mbs + Vector2(16, 44)), Color(0.70, 0.68, 0.63))   # the plinth
		b.rect(Rect2(mp - mbs * 0.5 - Vector2(8, 22), mbs + Vector2(16, 44)).grow(-4.0), Color(0.64, 0.62, 0.57))
		b.circle(mp + LIGHT * 22.0, 44.0, Color(SHADOW_COL.r, SHADOW_COL.g, SHADOW_COL.b, 0.22))
		for lg: Vector2 in [Vector2(-22, -30), Vector2(22, -30), Vector2(-22, 34), Vector2(22, 34)]:
			b.circle(mp + lg, 10.0, stone.darkened(0.25))
		b.circle(mp + Vector2(0, 16), 30.0, stone)
		b.circle(mp + Vector2(0, -12), 28.0, stone)
		b.circle(mp + Vector2(0, -44), 22.0, stone.lightened(0.06))      # the head
		b.circle(mp + Vector2(-6, -50), 10.0, stone.lightened(0.14))
		b.circle(mp + Vector2(-20, -40), 11.0, stone.darkened(0.12))     # ears
		b.circle(mp + Vector2(20, -40), 11.0, stone.darkened(0.12))
		b.line(mp + Vector2(0, -60), mp + Vector2(0, -78), stone.darkened(0.1), 9.0)   # the trunk
		b.circle(mp + Vector2(4, -80), 5.0, stone.darkened(0.1))
		for tx: float in [-1.0, 1.0]:
			b.line(mp + Vector2(tx * 10.0, -60), mp + Vector2(tx * 22.0, -80), Color(0.88, 0.85, 0.76), 4.0)
			b.line(mp + Vector2(tx * 22.0, -80), mp + Vector2(tx * 14.0, -92), Color(0.88, 0.85, 0.76), 3.5)
		b.line(mp + Vector2(0, 46), mp + Vector2(4, 60), stone.darkened(0.2), 3.0)       # the tail
	# the bandstand: an octagonal roof over eight iron posts, drawn as its
	# roof ring so the posts and the space inside still read
	var bs: Vector2 = LevelBuild.PARK_BANDSTAND
	if bs.y > vt - 120.0 and bs.y < vb + 120.0:
		var r: float = LevelBuild.BANDSTAND_R
		b.circle(bs + LIGHT * 18.0, r + 18.0, Color(SHADOW_COL.r, SHADOW_COL.g, SHADOW_COL.b, 0.18))
		b.circle(bs, r + 8.0, Color(0.74, 0.70, 0.62))                 # the stone platform
		b.circle(bs, r - 6.0, Color(0.66, 0.62, 0.55))
		var roof := PackedVector2Array()
		for i in range(8):
			roof.append(bs + Vector2.from_angle(TAU * float(i) / 8.0 + PI / 8.0) * (r + 14.0))
		var inner := PackedVector2Array()
		for i in range(8):
			inner.append(bs + Vector2.from_angle(TAU * float(i) / 8.0 + PI / 8.0) * (r - 12.0))
		# the roof as eight panels round an open lantern, green copper
		for i in range(8):
			var j := (i + 1) % 8
			var pan := PackedVector2Array([roof[i], roof[j], inner[j], inner[i]])
			b.polygon(pan, Color(0.30, 0.52, 0.46) if i % 2 == 0 else Color(0.26, 0.46, 0.41))
		b.circle(bs, 9.0, Color(0.36, 0.58, 0.51))
		for bp: Vector2 in park_posts:
			b.circle(bp, 5.0, Color(0.16, 0.17, 0.19))
	# the playground: a soft red surface, a slide, a pair of swings
	var pg: Rect2 = LevelBuild.PARK_PLAYGROUND
	if pg.end.y > vt - 40.0 and pg.position.y < vb + 40.0:
		_playground(b, pg)
	var lk: Rect2 = LevelBuild.PARK_LAKE
	if lk.end.y > vt - 80.0 and lk.position.y < vb + 80.0:
		_lake_shore(b, lk)
	b.flush(_wc)


# A flowerbed on the lawn: a low clipped box hedge round it, soft at the
# corners and lit along its top, and the planting in drifts - a run of one
# colour, foliage mounds between, a few taller spikes - not a grid of dots.
func _flowerbed(b: ShapeBatch, bed: Rect2, cols: Array) -> void:
	b.rect(Rect2(bed.position + LIGHT * 5.0, bed.size), Color(SHADOW_COL.r, SHADOW_COL.g, SHADOW_COL.b, 0.18))
	var hedge := Color(0.17, 0.30, 0.16)
	b.rect(bed.grow(-4.0), hedge)
	for cx: float in [bed.position.x + 4.0, bed.end.x - 4.0]:
		for cy: float in [bed.position.y + 4.0, bed.end.y - 4.0]:
			b.circle(Vector2(cx, cy), 4.0, hedge)
	b.rect(Rect2(bed.position.x + 4.0, bed.position.y, bed.size.x - 8.0, bed.size.y), hedge)
	b.rect(Rect2(bed.position.x, bed.position.y + 4.0, bed.size.x, bed.size.y - 8.0), hedge)
	# the clipped top of the box: a lit rim, and its leafy texture
	b.rect(Rect2(bed.position.x + 4.0, bed.position.y + 1.0, bed.size.x - 8.0, 2.0), hedge.lightened(0.22))
	var t := bed.position.y + 6.0
	var k := 0
	while t < bed.end.y - 6.0:
		for hx: float in [bed.position.x + 3.5, bed.end.x - 3.5]:
			b.circle(Vector2(hx, t + float(k % 3)), 2.2, hedge.lightened(0.10 + 0.06 * float(k % 2)))
		t += 7.0
		k += 1
	var soil := bed.grow(-8.0)
	b.rect(soil, Color(0.36, 0.26, 0.18))
	# drifts, top to bottom, each its own colour and its own length
	var y := soil.position.y + 6.0
	var d := int(bed.position.y) & 7
	while y < soil.end.y - 6.0:
		var run := 34.0 + float((d * 17) % 5) * 9.0
		var fc: Color = cols[d % cols.size()]
		var y1 := minf(y + run, soil.end.y - 4.0)
		var fy := y
		var j := 0
		while fy < y1:
			var fx := soil.position.x + 8.0 + float((j * 7 + d * 3) % 5) * (soil.size.x - 16.0) / 4.0
			b.circle(Vector2(fx, fy), 6.5, Color(0.22, 0.38, 0.19))
			b.circle(Vector2(fx - 2.0, fy - 2.0), 3.4, fc)
			b.circle(Vector2(fx + 2.5, fy - 0.5), 3.0, fc.lightened(0.12))
			b.circle(Vector2(fx + 0.5, fy + 2.5), 2.6, fc.darkened(0.08))
			fy += 7.5
			j += 1
		# a foliage mound and a spike or two before the next drift
		var my := minf(y1 + 6.0, soil.end.y - 6.0)
		b.circle(Vector2(soil.get_center().x + float(d % 3 - 1) * 10.0, my), 8.0, Color(0.26, 0.44, 0.22))
		b.circle(Vector2(soil.get_center().x + float(d % 3 - 1) * 10.0 - 2.0, my - 2.0), 5.0, Color(0.32, 0.52, 0.26))
		if d % 2 == 0:
			for sx: float in [soil.position.x + 10.0, soil.end.x - 10.0]:
				b.line(Vector2(sx, my + 6.0), Vector2(sx, my - 6.0), Color(0.56, 0.44, 0.74), 2.6)
		y = y1 + 16.0
		d += 1


# The lake's shore: clumps of reeds round the bank, a timber jetty on the
# south side with two rowing boats tied up for hire, and ducks resting on the
# bank. All drawn on the bank and the water: the path round the lake stays
# clear for walking.
func _lake_shore(b: ShapeBatch, lk: Rect2) -> void:
	var lc := lk.get_center()
	var rx := lk.size.x * 0.5
	var ry := lk.size.y * 0.5
	var at := func(a: float, f: float) -> Vector2:
		return lc + Vector2(cos(a) * rx * f, sin(a) * ry * f)
	# the jetty: out from the south bank into the water
	var jb: Vector2 = at.call(PI * 0.5, 1.0)
	var jet := Rect2(jb.x - 12.0, jb.y - 70.0, 24.0, 76.0)
	b.rect(Rect2(jet.position + LIGHT * 5.0, jet.size), Color(0, 0, 0, 0.2))
	b.rect(jet, Color(0.50, 0.36, 0.22))
	var py := jet.position.y + 3.0
	while py < jet.end.y - 2.0:
		b.line(Vector2(jet.position.x + 1.0, py), Vector2(jet.end.x - 1.0, py), Color(0.40, 0.28, 0.16), 1.2)
		py += 6.0
	for px: float in [jet.position.x - 1.0, jet.end.x + 1.0]:
		for pyy: float in [jet.position.y + 2.0, jet.position.y + 36.0]:
			b.circle(Vector2(px, pyy), 3.2, Color(0.30, 0.20, 0.12))
	# the boats tied alongside, nosing at their ropes
	var bt := AnimClock.msec() / 1000.0
	for side: float in [-1.0, 1.0]:
		var bp := Vector2(jet.get_center().x + side * 28.0, jet.position.y + 22.0 + sin(bt * 1.3 + side) * 1.5)
		var hull := PackedVector2Array()
		var deck := PackedVector2Array()
		for q: Vector2 in [Vector2(0, -24), Vector2(10, -8), Vector2(10, 16), Vector2(-10, 16), Vector2(-10, -8)]:
			hull.append(bp + q)
			deck.append(bp + q * 0.74)
		b.polygon(hull, Color(0.55, 0.30, 0.22) if side < 0.0 else Color(0.24, 0.42, 0.56))
		b.polygon(deck, Color(0.78, 0.66, 0.50))
		b.line(bp + Vector2(-7, 2), bp + Vector2(7, 2), Color(0.45, 0.33, 0.22), 2.0)
		b.line(bp + Vector2(side * -10.0, -10.0), Vector2(jet.position.x if side < 0.0 else jet.end.x, jet.position.y + 4.0),
			Color(0.82, 0.78, 0.66), 1.0)
	# reeds round the bank, in clumps, leaving the jetty clear
	for i in range(9):
		var a := PI * 0.5 + 0.55 + float(i) * (TAU - 1.1) / 8.0
		var c: Vector2 = at.call(a, 1.0 + 0.02 * float(i % 2))
		b.circle(c + Vector2(2, 3), 9.0, Color(0, 0, 0, 0.12))
		for s in range(9):
			var off := Vector2(float((s * 5 + i) % 7) - 3.0, float((s * 3 + i) % 5) - 2.0) * 2.4
			var lean := Vector2(float((s + i) % 3 - 1) * 4.0, -16.0 - float((s * 7 + i) % 4) * 3.0)
			b.line(c + off, c + off + lean, Color(0.30, 0.48, 0.22) if s % 2 == 0 else Color(0.42, 0.58, 0.28), 2.0)
			if (s + i) % 3 == 0:
				b.line(c + off + lean * 0.7, c + off + lean * 0.95, Color(0.42, 0.26, 0.14), 3.2)
	# ducks having a rest on the east bank, heads tucked or up
	for d in range(3):
		var dp: Vector2 = at.call(-0.25 + float(d) * 0.22, 1.05)
		b.circle(dp + Vector2(2, 2), 6.0, Color(0, 0, 0, 0.16))
		b.circle(dp, 6.0, Color(0.52, 0.40, 0.28))
		b.circle(dp + Vector2(-2, -1), 3.6, Color(0.60, 0.48, 0.34))
		var hd := dp + Vector2(5.0 if d % 2 == 0 else 3.0, -4.0)
		b.circle(hd, 3.2, Color(0.16, 0.42, 0.24) if d != 1 else Color(0.48, 0.36, 0.24))
		b.circle(hd + Vector2(3, 0.5), 1.4, Color(0.92, 0.74, 0.24))


# A playground: a soft red surface, a slide, a pair of swings, and a sandpit
# (whose sand is a patch the level lays at the same spot).
# a rectangle with rounded corners, in one colour
func _soft_rect(b: ShapeBatch, r: Rect2, rad: float, col: Color) -> void:
	rad = minf(rad, minf(r.size.x, r.size.y) * 0.5)
	b.rect(Rect2(r.position.x + rad, r.position.y, r.size.x - rad * 2.0, r.size.y), col)
	b.rect(Rect2(r.position.x, r.position.y + rad, r.size.x, r.size.y - rad * 2.0), col)
	for cx: float in [r.position.x + rad, r.end.x - rad]:
		for cy: float in [r.position.y + rad, r.end.y - rad]:
			b.circle(Vector2(cx, cy), rad, col)


func _playground(b: ShapeBatch, pg: Rect2) -> void:
	if true:
		# poured rubber, soft-cornered, with a darker kerb round it and a
		# hopscotch let into it; a low fence with a gate on the path side
		var rub := Color(0.64, 0.36, 0.30)
		_soft_rect(b, pg.grow(4.0), 14.0, rub.darkened(0.25))
		_soft_rect(b, pg, 12.0, rub)
		for k in range(4):
			b.rect(Rect2(pg.position.x + 14.0, pg.end.y - 30.0 - float(k) * 18.0, 16.0, 16.0),
				Color(0.98, 0.84, 0.38, 0.55) if k % 2 == 0 else Color(0.40, 0.62, 0.80, 0.55))
		var fence := Color(0.66, 0.52, 0.34)
		var fr := pg.grow(10.0)
		for seg: Array in [[fr.position, Vector2(fr.end.x, fr.position.y)], [Vector2(fr.end.x, fr.position.y), fr.end],
				[fr.end, Vector2(fr.position.x, fr.end.y)],
				[fr.position, Vector2(fr.position.x, fr.get_center().y - 22.0)],
				[Vector2(fr.position.x, fr.get_center().y + 22.0), Vector2(fr.position.x, fr.end.y)]]:
			b.line((seg[0] as Vector2) + LIGHT * 3.0, (seg[1] as Vector2) + LIGHT * 3.0, Color(0, 0, 0, 0.16), 3.0)
			b.line(seg[0], seg[1], fence, 3.0)
		var fy := fr.position.y
		while fy <= fr.end.y:
			for fx: float in [fr.position.x, fr.end.x]:
				if absf(fy - fr.get_center().y) > 22.0 or fx == fr.end.x:
					b.circle(Vector2(fx, fy), 3.0, fence.darkened(0.3))
			fy += 20.0
		var fx2 := fr.position.x
		while fx2 <= fr.end.x:
			for fyy: float in [fr.position.y, fr.end.y]:
				b.circle(Vector2(fx2, fyy), 3.0, fence.darkened(0.3))
			fx2 += 20.0
		# a spring rider: a little red horse on its coil
		var sr := pg.position + Vector2(126.0, 248.0)
		b.circle(sr + Vector2(2, 3), 9.0, Color(0, 0, 0, 0.16))
		b.circle(sr, 4.0, Color(0.36, 0.36, 0.40))
		b.rect(Rect2(sr.x - 6.0, sr.y - 12.0, 12.0, 22.0), Color(0.86, 0.26, 0.24))
		b.circle(sr + Vector2(0, -14), 5.0, Color(0.90, 0.30, 0.26))
		b.line(sr + Vector2(-7, -6), sr + Vector2(7, -6), Color(0.96, 0.84, 0.30), 2.0)
		# the slide: ladder, platform, chute
		var sl := pg.position + Vector2(40.0, 60.0)
		# its shadow, falling long from the platform
		b.polygon(PackedVector2Array([sl + Vector2(-8, -10), sl + Vector2(22, -4), sl + Vector2(26, 94),
			sl + Vector2(-2, 94)]), Color(0, 0, 0, 0.14))
		# the ladder's rails and rungs, up to the platform
		for lx: float in [-9.0, 9.0]:
			b.line(Vector2(sl.x + lx, sl.y - 42.0), Vector2(sl.x + lx, sl.y - 12.0), Color(0.36, 0.36, 0.40), 2.4)
		for rung in range(4):
			b.line(Vector2(sl.x - 9.0, sl.y - 16.0 - float(rung) * 7.0), Vector2(sl.x + 9.0, sl.y - 16.0 - float(rung) * 7.0), Color(0.46, 0.46, 0.50), 2.0)
		# the platform, its corner posts and the hand rail round it
		b.rect(Rect2(sl.x - 13.0, sl.y - 13.0, 26.0, 26.0), Color(0.22, 0.38, 0.58))
		b.rect(Rect2(sl.x - 11.0, sl.y - 11.0, 22.0, 22.0), Color(0.30, 0.50, 0.72))
		for pc: Vector2 in [Vector2(-11, -11), Vector2(11, -11), Vector2(-11, 11), Vector2(11, 11)]:
			b.circle(sl + pc, 2.6, Color(0.92, 0.30, 0.28))
		# the chute: a trough widening into its run-out, raised side rails,
		# and the shine down the middle where it is polished by every child
		var chute := PackedVector2Array([sl + Vector2(-8, 12), sl + Vector2(8, 12), sl + Vector2(11, 84),
			sl + Vector2(-11, 84)])
		b.polygon(chute, Color(0.92, 0.72, 0.24))
		b.polygon(PackedVector2Array([sl + Vector2(-5, 13), sl + Vector2(5, 13), sl + Vector2(7, 82),
			sl + Vector2(-7, 82)]), Color(0.98, 0.84, 0.38))
		b.line(sl + Vector2(-1, 16), sl + Vector2(-1, 80), Color(1, 0.96, 0.78), 2.0)
		for rs: float in [-1.0, 1.0]:
			b.line(sl + Vector2(8.5 * rs, 12), sl + Vector2(11.5 * rs, 84), Color(0.78, 0.56, 0.16), 2.0)
		# swings, gently going
		var st := AnimClock.msec() / 1000.0
		var sw := pg.position + Vector2(118.0, 70.0)
		b.line(sw + Vector2(-30, 0), sw + Vector2(30, 0), Color(0.34, 0.36, 0.40), 5.0)
		for si: float in [-14.0, 14.0]:
			var swing := sin(st * 2.2 + si) * 16.0
			var seat := sw + Vector2(si, 22.0 + swing)
			b.line(sw + Vector2(si - 6.0, 0), seat + Vector2(-6, 0), Color(0.55, 0.55, 0.58), 1.4)
			b.line(sw + Vector2(si + 6.0, 0), seat + Vector2(6, 0), Color(0.55, 0.55, 0.58), 1.4)
			b.rect(Rect2(seat.x - 8.0, seat.y - 3.0, 16.0, 6.0), Color(0.20, 0.22, 0.26))
		# the sandpit's timber edge, its corner seats, a bucket and spade
		# left in it (the sand itself is a patch)
		var sp: Vector2 = pg.get_center() + Vector2(-28.0, 40.0)
		var timber := Rect2(sp.x - 54.0, sp.y - 44.0, 108.0, 88.0)
		_soft_rect(b, timber, 8.0, Color(0.46, 0.34, 0.22))
		_soft_rect(b, timber.grow(-6.0), 5.0, Color(0.86, 0.78, 0.58))
		for cs: Vector2 in [timber.position, Vector2(timber.end.x, timber.position.y), Vector2(timber.position.x, timber.end.y), timber.end]:
			b.circle(cs.move_toward(timber.get_center(), 9.0), 7.0, Color(0.56, 0.42, 0.28))
		b.rect(Rect2(sp.x + 14.0, sp.y + 6.0, 10.0, 12.0), Color(0.24, 0.52, 0.82))
		b.line(Vector2(sp.x + 13.0, sp.y + 6.0), Vector2(sp.x + 25.0, sp.y + 6.0), Color(0.18, 0.40, 0.66), 2.0)
		b.line(Vector2(sp.x - 20.0, sp.y - 10.0), Vector2(sp.x - 6.0, sp.y + 2.0), Color(0.90, 0.30, 0.28), 2.0)
		b.circle(Vector2(sp.x - 6.0, sp.y + 2.0), 3.0, Color(0.90, 0.30, 0.28))


# The stream across the wood and the footbridge that carries the trail over
# it. The water rects (level_build.trail_stream) stop at the bridge; the
# stream is drawn across under it so it reads as running beneath.
func _draw_trail_stream(vt: float, vb: float) -> void:
	var sy: float = LevelBuild.TRAIL_STREAM_Y
	var half: float = LevelBuild.TRAIL_STREAM_HALF
	if sy < vt - 120.0 or sy > vb + 120.0:
		return
	var wt := AnimClock.msec() / 1000.0
	var bank := PackedVector2Array()
	var water := PackedVector2Array()
	var xs: Array[float] = []
	var x := -400.0
	while x <= 1700.0:
		xs.append(x)
		x += 60.0
	for bx: float in xs:
		bank.append(Vector2(bx, sy - half - 10.0 + sin(bx * 0.021) * 5.0))
	for k in range(xs.size() - 1, -1, -1):
		bank.append(Vector2(xs[k], sy + half + 10.0 + sin(xs[k] * 0.017 + 1.0) * 5.0))
	for bx: float in xs:
		water.append(Vector2(bx, sy - half + sin(bx * 0.021) * 4.0))
	for k in range(xs.size() - 1, -1, -1):
		water.append(Vector2(xs[k], sy + half + sin(xs[k] * 0.017 + 1.0) * 4.0))
	_wc.draw_colored_polygon(bank, Color(0.36, 0.30, 0.21))
	_wc.draw_colored_polygon(water, Color(0.27, 0.42, 0.44))
	var wb := ShapeBatch.new()
	# deeper down the middle: a darker band where the current runs
	var deep := PackedVector2Array()
	for bx: float in xs:
		deep.append(Vector2(bx, sy - half * 0.45 + sin(bx * 0.019 + 0.5) * 3.0))
	for k in range(xs.size() - 1, -1, -1):
		deep.append(Vector2(xs[k], sy + half * 0.40 + sin(xs[k] * 0.015 + 1.7) * 3.0))
	wb.polygon(deep, Color(0.18, 0.32, 0.36, 0.55))
	# foam where the water meets each bank, drifting with the current
	for k in range(34):
		var fx := fmod(float(k) * 61.0 + wt * 22.0, 2100.0) - 400.0
		var top := sy - half + sin(fx * 0.021) * 4.0 + 2.0
		var bot := sy + half + sin(fx * 0.017 + 1.0) * 4.0 - 2.0
		wb.line(Vector2(fx, top), Vector2(fx + 12.0, top), Color(0.92, 0.95, 0.94, 0.35), 2.0)
		wb.line(Vector2(fx + 30.0, bot), Vector2(fx + 40.0, bot), Color(0.92, 0.95, 0.94, 0.30), 2.0)
	# current lines running downstream (east), quicker in the deep middle
	for k in range(18):
		var lane := float(k % 3) - 1.0
		var speed := 52.0 if lane == 0.0 else 34.0
		var rx := fmod(float(k) * 127.0 + wt * speed, 2100.0) - 400.0
		var ry := sy + lane * half * 0.5 + sin(rx * 0.02) * 2.0
		wb.line(Vector2(rx, ry), Vector2(rx + 26.0, ry + 1.0), Color(1, 1, 1, 0.18 if lane == 0.0 else 0.12), 2.0)
	wb.flush(_wc)
	# stones along the banks
	for k in range(10):
		var stx := -200.0 + float(k) * 190.0 + float(k % 3) * 23.0
		var sty := sy + (half + 4.0) * (1.0 if k % 2 == 0 else -1.0)
		_wc.draw_circle(Vector2(stx, sty), 6.0 + float(k % 3) * 2.0, Color(0.52, 0.50, 0.46))
	# the footbridge: planks across the trail's width, a rail each side
	var e := walk_edges(sy)
	var bh: float = LevelBuild.TRAIL_BRIDGE_HALF
	var deck := Rect2(e.x - 18.0, sy - bh, e.y - e.x + 36.0, bh * 2.0)
	_wc.draw_rect(Rect2(deck.position + LIGHT * 8.0, deck.size), Color(SHADOW_COL.r, SHADOW_COL.g, SHADOW_COL.b, 0.25))
	_wc.draw_rect(deck, Color(0.55, 0.42, 0.28))
	var px := deck.position.x
	while px < deck.end.x:
		_wc.draw_line(Vector2(px, deck.position.y), Vector2(px, deck.end.y), Color(0.40, 0.30, 0.20), 2.0)
		px += 16.0
	for ry: float in [deck.position.y + 3.0, deck.end.y - 3.0]:
		_wc.draw_line(Vector2(deck.position.x, ry), Vector2(deck.end.x, ry), Color(0.36, 0.26, 0.16), 5.0)
		_wc.draw_line(Vector2(deck.position.x, ry - 1.5), Vector2(deck.end.x, ry - 1.5), Color(0.62, 0.48, 0.32), 1.5)
	# the four posts (they are poles: the rope wraps them)
	for i in range(deco_pole_count, deco_pole_count + 4):
		var bp := poles[i]
		_wc.draw_circle(bp, 7.0, Color(0.34, 0.25, 0.16))
		_wc.draw_circle(bp + Vector2(-1.5, -1.5), 4.5, Color(0.52, 0.40, 0.26))

func _draw_palm(c: Object, p: Vector2) -> void:
	# a palm from above: a ring of long fronds, each with a spine and leaflets,
	# radiating from a fat trunk. The shadow copies the frond pattern, which is
	# what makes the beach read as glaring midday sun.
	var sh := p + LIGHT * 40.0
	for j in range(7):
		var sa := TAU * float(j) / 7.0 + p.x * 0.01 + p.y * 0.007
		c.draw_line(sh, sh + Vector2.from_angle(sa) * 34.0,
			Color(SHADOW_COL.r, SHADOW_COL.g, SHADOW_COL.b, 0.14), 7.0)
	var t := AnimClock.msec() / 1000.0
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
	# the trunk, and the coconuts nobody should be under: one draw call
	var trunk := ShapeBatch.new()
	trunk.circle(p, 9.0, Color(0.34, 0.26, 0.17))
	trunk.circle(p + Vector2(-2, -2), 6.0, Color(0.48, 0.38, 0.25))
	trunk.circle(p + Vector2(5, 4), 3.4, Color(0.28, 0.22, 0.14))
	trunk.circle(p + Vector2(-4, 5), 3.0, Color(0.28, 0.22, 0.14))
	trunk.flush(c)


func _draw_lamppost(p: Vector2) -> void:
	# A lamppost seen from above is mostly a shadow: the column is directly
	# under the lantern, so the long shadow lying away from it is what tells
	# you it is three metres tall and not a manhole cover.
	cast_shadow(_wc, p, 6.0, 52.0, 0.18)
	var halo_a := 0.32 if Game.night else 0.08
	_wc.draw_circle(p, 62.0, Color(1.0, 0.9, 0.6, halo_a))
	# the base plinth it is bolted to
	_wc.draw_circle(p + Vector2(0, 2), POLE_RADIUS + 6.0, Color(0.24, 0.24, 0.27))
	_wc.draw_circle(p + Vector2(0, 1), POLE_RADIUS + 3.5, Color(0.33, 0.33, 0.36))
	# the fluted column, lit down one side
	_wc.draw_circle(p, POLE_RADIUS, Color(0.38, 0.38, 0.42))
	_wc.draw_circle(p + Vector2(-1.5, -1.5), POLE_RADIUS * 0.62, Color(0.52, 0.52, 0.57))
	# four cross arms, each with a lantern on the end, glass and all
	for bo: Vector2 in [Vector2(11, 0), Vector2(-11, 0), Vector2(0, 11), Vector2(0, -11)]:
		_wc.draw_line(p, p + bo, Color(0.30, 0.30, 0.33), 3.5)
		_wc.draw_line(p, p + bo, Color(0.46, 0.46, 0.5), 1.5)
		var lp := p + bo * 1.4
		_wc.draw_circle(lp, 5.0, Color(0.26, 0.26, 0.29))
		_wc.draw_circle(lp, 3.6, Color(0.99, 0.95, 0.78) if Game.night else Color(0.86, 0.88, 0.9))
		if Game.night:
			_wc.draw_circle(lp, 6.5, Color(1.0, 0.92, 0.66, 0.35))


# A rounded rectangle as one polygon: four corners of three steps each. One
# polygon is one batched run, where four circles and two rects would be six.
static func round_rect_pts(r: Rect2, rad: float) -> PackedVector2Array:
	var k := minf(rad, minf(r.size.x, r.size.y) * 0.5)
	var cs := [Vector2(r.end.x - k, r.position.y + k), Vector2(r.end.x - k, r.end.y - k),
		Vector2(r.position.x + k, r.end.y - k), Vector2(r.position.x + k, r.position.y + k)]
	var pts := PackedVector2Array()
	for ci in range(4):
		for s in range(4):
			pts.append(cs[ci] + Vector2.from_angle(-PI * 0.5 + float(ci) * PI * 0.5 + float(s) * PI / 6.0) * k)
	return pts


# An ellipse as one polygon of n points, for shoulders and seats; batchable
# where a transformed circle is not.
static func ellipse_pts(at: Vector2, rx: float, ry: float, n := 14) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in range(n):
		var a := TAU * float(k) / float(n)
		pts.append(at + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


# A slab of plasticine seen from above: a darker rim showing on the side away
# from the light, the face itself, and a soft sheen on the lit corner. Three
# polygons, all batchable.
func clay_slab(c: Object, r: Rect2, rad: float, col: Color, lift := 2.5) -> void:
	c.draw_colored_polygon(round_rect_pts(r, rad), col.darkened(0.30))
	c.draw_colored_polygon(round_rect_pts(Rect2(r.position, r.size - Vector2(lift, lift)), rad), col)
	var sheen := Rect2(r.position + Vector2(lift, lift), Vector2(r.size.x * 0.55, r.size.y * 0.42))
	var lit := col.lightened(0.22)
	c.draw_colored_polygon(round_rect_pts(sheen, rad * 0.8), Color(lit.r, lit.g, lit.b, 0.55))


# The long soft shadow of anything a couple of metres tall and boxy: a firm
# core and a fainter fringe, both pushed away from the light.
func box_shadow(c: Object, r: Rect2, rad: float, h: float) -> void:
	var sc := Color(SHADOW_COL.r, SHADOW_COL.g, SHADOW_COL.b, 0.10)
	c.draw_colored_polygon(round_rect_pts(Rect2(r.position + LIGHT * (h * 1.15), r.size).grow(3.0), rad + 3.0), sc)
	c.draw_colored_polygon(round_rect_pts(Rect2(r.position + LIGHT * h, r.size), rad),
		Color(SHADOW_COL.r, SHADOW_COL.g, SHADOW_COL.b, 0.18))


# The service van: a van seen from above is a roof, so it gets one - rounded
# corners, ribs across it, a vent, roof bars, the windscreen raked under the
# front edge, mirrors sticking out past the body, and the long shadow a
# two-metre box throws.
func _draw_service_van(v: Vector2) -> void:
	var body := Rect2(v.x - 32.0, v.y - 66.0, 64.0, 132.0)
	box_shadow(_wc, body, 12.0, 26.0)
	# tyres, visible past the body on both sides
	for w: Vector2 in [Vector2(-35, -42), Vector2(29, -42), Vector2(-35, 28), Vector2(29, 28)]:
		_wc.draw_colored_polygon(round_rect_pts(Rect2(v.x + w.x, v.y + w.y, 6.0, 17.0), 2.5), Color(0.10, 0.10, 0.12))
	# the roof, plasticine white, lit on its upper-left corner
	clay_slab(_wc, body, 12.0, Color(0.88, 0.88, 0.86), 3.0)
	# pressed ribs along the roof, each a groove with a lit lip behind it
	for ri in range(5):
		var ry := body.position.y + 26.0 + float(ri) * 20.0
		_wc.draw_line(Vector2(body.position.x + 6.0, ry), Vector2(body.end.x - 7.0, ry), Color(0.72, 0.72, 0.71), 2.0)
		_wc.draw_line(Vector2(body.position.x + 6.0, ry + 2.0), Vector2(body.end.x - 7.0, ry + 2.0), Color(0.97, 0.97, 0.95), 1.0)
	# windscreen at the front (north), raked, with a glare streak and a wiper
	_wc.draw_colored_polygon(PackedVector2Array([v + Vector2(-27, -62), v + Vector2(27, -62),
		v + Vector2(24, -43), v + Vector2(-24, -43)]), Color(0.27, 0.35, 0.43))
	_wc.draw_colored_polygon(PackedVector2Array([v + Vector2(-24, -61), v + Vector2(-10, -61),
		v + Vector2(-17, -44), v + Vector2(-22, -44)]), Color(0.62, 0.72, 0.80, 0.55))
	_wc.draw_line(v + Vector2(-18, -46), v + Vector2(6, -52), Color(0.16, 0.16, 0.18), 1.6)
	# mirrors, which is what makes it read as a VEHICLE and not a crate
	for mx: float in [-1.0, 1.0]:
		_wc.draw_colored_polygon(round_rect_pts(Rect2(v.x + mx * 38.0 - 3.0, v.y - 52.0, 6.0, 9.0), 2.5), Color(0.28, 0.28, 0.30))
	# roof vent and bars
	clay_slab(_wc, Rect2(v.x - 11.0, v.y - 16.0, 22.0, 16.0), 4.0, Color(0.76, 0.76, 0.74), 2.0)
	for bx: float in [-20.0, 20.0]:
		_wc.draw_line(v + Vector2(bx, -34.0), v + Vector2(bx, 46.0), Color(0.58, 0.58, 0.58), 3.0)
		_wc.draw_line(v + Vector2(bx - 1.0, -34.0), v + Vector2(bx - 1.0, 46.0), Color(0.78, 0.78, 0.78), 1.0)
	# the back doors and a livery stripe down the side
	_wc.draw_line(v + Vector2(-29, 58), v + Vector2(29, 58), Color(0.58, 0.58, 0.59), 2.0)
	_wc.draw_line(v + Vector2(0, 58), v + Vector2(0, 65), Color(0.58, 0.58, 0.59), 2.0)
	_wc.draw_rect(Rect2(v.x - 31.0, v.y + 4.0, 61.0, 7.0), Color(0.66, 0.30, 0.25))
	_wc.draw_rect(Rect2(v.x - 31.0, v.y + 4.0, 61.0, 2.0), Color(0.80, 0.42, 0.35))
	# a hazard beacon on the cab, because it is parked where it should not be
	var beat := 0.55 + 0.45 * sin(AnimClock.msec() / 190.0)
	_wc.draw_circle(v + Vector2(0, -38.0), 5.0, Color(0.55, 0.36, 0.10))
	_wc.draw_circle(v + Vector2(0, -38.0), 4.0, Color(0.95, 0.62, 0.15, 0.55 + beat * 0.45))
	_wc.draw_circle(v + Vector2(-1.2, -39.2), 1.4, Color(1.0, 0.95, 0.80, 0.8))


# THE FUR-GONETA. A grooming van done up as a shaggy dog, in the tradition of
# every mobile groomer that has ever driven past you: fur over the roof,
# floppy ears hanging down the sides, a fringe falling over the windscreen
# with the eyes peering out from under it, a wet nose on the bonnet, a tail
# on the back doors. Our own name and livery: the van it tips its hat to
# belongs to somebody else.
#
# The one surface you can read from directly overhead is the roof, so the
# signwriting is painted up there, which is where a real grooming van puts it
# anyway. Front is north; body, wheels and footprint are the service van's.
func _draw_furgoneta(v: Vector2) -> void:
	var fur := Color(0.50, 0.33, 0.19)
	var fur_lit := Color(0.64, 0.45, 0.27)
	var fur_dark := Color(0.33, 0.21, 0.12)
	var cream := Color(0.92, 0.86, 0.74)
	var cream_dk := Color(0.76, 0.69, 0.57)
	var ink := Color(0.40, 0.20, 0.16)
	var body := Rect2(v.x - 32.0, v.y - 66.0, 64.0, 132.0)
	box_shadow(_wc, body, 14.0, 26.0)
	for w: Vector2 in [Vector2(-35, -40), Vector2(29, -40), Vector2(-35, 26), Vector2(29, 26)]:
		_wc.draw_colored_polygon(round_rect_pts(Rect2(v.x + w.x, v.y + w.y, 6.0, 18.0), 2.5), Color(0.10, 0.10, 0.12))
	# --- ears: big and floppy, hung from the front of the roof down the sides
	for sx: float in [-1.0, 1.0]:
		_wc.draw_colored_polygon(PackedVector2Array([
			v + Vector2(24.0 * sx, -40.0), v + Vector2(48.0 * sx, -26.0),
			v + Vector2(46.0 * sx, 6.0), v + Vector2(38.0 * sx, 16.0),
			v + Vector2(27.0 * sx, 2.0),
		]), fur_dark)
		_wc.draw_colored_polygon(PackedVector2Array([
			v + Vector2(26.0 * sx, -35.0), v + Vector2(42.0 * sx, -24.0),
			v + Vector2(40.0 * sx, 4.0), v + Vector2(36.0 * sx, 10.0),
			v + Vector2(28.0 * sx, -2.0),
		]), fur if sx > 0.0 else fur_lit)
		# the shaggy ends of the ear
		for tf in range(3):
			var tx := (32.0 + float(tf) * 4.5) * sx
			_wc.draw_line(v + Vector2(tx, 6.0 + float(tf)), v + Vector2(tx - 1.5 * sx, 14.0 + float(tf) * 1.5), fur_dark, 2.2)
	# --- the body: a soft fur slab, cream down the face and one rear corner
	clay_slab(_wc, body, 14.0, fur, 3.0)
	_wc.draw_colored_polygon(round_rect_pts(Rect2(v.x - 31.0, v.y + 22.0, 18.0, 41.0), 9.0), cream_dk)
	# --- fur: rows of little curls over the roof, lit side and shaded side
	for row in range(9):
		var ry := v.y - 26.0 + float(row) * 10.5
		for col in range(6):
			var rx := v.x - 26.0 + float(col) * 10.5 + (5.0 if row % 2 == 0 else 0.0)
			if absf(rx - v.x) < 25.0 and ry > v.y - 25.0 and ry < v.y + 26.0:
				continue     # under the signwriting
			var on_cream: bool = rx < v.x - 13.0 and ry > v.y + 22.0
			var tc: Color = cream if on_cream else (fur_lit if rx < v.x - 6.0 else fur_dark)
			_wc.draw_line(Vector2(rx, ry), Vector2(rx - 3.0, ry + 5.0), tc, 2.0)
			_wc.draw_line(Vector2(rx - 3.0, ry + 5.0), Vector2(rx + 1.0, ry + 7.5), tc, 1.6)
	# --- the face on the front (north) end -------------------------------
	# the bumper, peeking out in front of the muzzle, with its two headlamps
	_wc.draw_colored_polygon(round_rect_pts(Rect2(v.x - 30.0, v.y - 69.0, 60.0, 8.0), 4.0), Color(0.36, 0.34, 0.33))
	for hx: float in [-21.0, 21.0]:
		_wc.draw_circle(v + Vector2(hx, -64.0), 4.6, Color(0.30, 0.28, 0.26))
		_wc.draw_circle(v + Vector2(hx, -64.0), 3.4, Color(0.98, 0.94, 0.78))
		_wc.draw_circle(v + Vector2(hx - 1.0, -65.0), 1.2, Color(1, 1, 1))
	# the muzzle over the bonnet, and a big wet nose where the grille would be
	clay_slab(_wc, Rect2(v.x - 17.0, v.y - 66.0, 34.0, 19.0), 9.0, cream, 2.0)
	_wc.draw_circle(v + Vector2(0.0, -59.0), 7.5, Color(0.10, 0.09, 0.10))
	_wc.draw_circle(v + Vector2(-0.6, -59.8), 6.0, Color(0.17, 0.15, 0.16))
	_wc.draw_circle(v + Vector2(-2.6, -62.0), 2.2, Color(0.62, 0.60, 0.62))
	_wc.draw_line(v + Vector2(0.0, -52.5), v + Vector2(0.0, -48.5), Color(0.30, 0.22, 0.18), 1.6)
	# the windscreen, raked, with a glare streak across it
	_wc.draw_colored_polygon(PackedVector2Array([v + Vector2(-27, -47), v + Vector2(27, -47),
		v + Vector2(25, -30), v + Vector2(-25, -30)]), Color(0.22, 0.29, 0.36))
	_wc.draw_colored_polygon(PackedVector2Array([v + Vector2(-25, -46), v + Vector2(-13, -46),
		v + Vector2(-19, -31), v + Vector2(-24, -31)]), Color(0.58, 0.68, 0.76, 0.5))
	# the eyes, painted on the glass the way a cartoon car's are, peering out
	# from under the fringe; the pupils slide towards the dog when she is near
	var look := Vector2.ZERO
	if dog != null and dog.global_position.distance_to(v) < 260.0:
		look = (dog.global_position - v).normalized() * 1.6
	for ex: float in [-10.5, 10.5]:
		var ep := v + Vector2(ex, -40.5)
		_wc.draw_circle(ep, 6.0, Color(0.20, 0.16, 0.14))
		_wc.draw_circle(ep, 5.0, Color(0.98, 0.97, 0.94))
		_wc.draw_circle(ep + Vector2(0.4, 1.2) + look, 2.6, Color(0.12, 0.10, 0.10))
		_wc.draw_circle(ep + Vector2(-0.6, 0.2) + look, 0.9, Color(1, 1, 1))
	# the fringe, hanging off the front of the roof over the tops of the eyes
	for i in range(10):
		var fx := v.x - 24.0 + float(i) * 5.4
		var fl := 6.0 + float((i * 7) % 4) * 1.4
		var fc: Color = fur_lit if fx < v.x - 6.0 else fur
		_wc.draw_colored_polygon(PackedVector2Array([Vector2(fx - 3.4, v.y - 29.0),
			Vector2(fx + 3.4, v.y - 29.0), Vector2(fx - 1.0, v.y - 29.0 - fl)]), fc)
	# mirrors, out past the ears' roots
	for mx: float in [-1.0, 1.0]:
		_wc.draw_colored_polygon(round_rect_pts(Rect2(v.x + mx * 37.0 - 3.0, v.y - 47.0, 6.0, 8.0), 2.5), Color(0.28, 0.26, 0.25))
	# --- the tail, wagging, on the back doors -----------------------------
	var wag := sin(AnimClock.msec() / 210.0) * 0.55
	var tail_dir := Vector2(0.0, 1.0).rotated(wag)
	var tail_root := v + Vector2(0.0, 62.0)
	_wc.draw_line(tail_root, tail_root + tail_dir * 30.0, fur_dark, 11.0)
	_wc.draw_line(tail_root, tail_root + tail_dir * 26.0, fur, 7.0)
	_wc.draw_line(tail_root - tail_dir.orthogonal() * 1.5, tail_root + tail_dir * 22.0 - tail_dir.orthogonal() * 1.5, fur_lit, 2.0)
	_wc.draw_circle(tail_root + tail_dir * 29.0, 5.5, cream_dk)
	_wc.draw_circle(tail_root + tail_dir * 28.0 + Vector2(-1, -1), 4.2, cream)
	# --- the livery ----------------------------------------------------------
	# Painted onto the roof rather than mounted above it: a light box the size
	# of the van looked like a taxi sign. Two lines, inside the van's width.
	var f_big := 16
	var f_small := 13
	var w_fur: float = font.get_string_size("FUR", HORIZONTAL_ALIGNMENT_LEFT, -1, f_big).x
	var w_gon: float = font.get_string_size("GONETA", HORIZONTAL_ALIGNMENT_LEFT, -1, f_small).x
	var pw: float = maxf(w_fur + 12.0, w_gon) + 12.0
	var panel := Rect2(v.x - pw * 0.5, v.y - 23.0, pw, 47.0)
	_wc.draw_colored_polygon(round_rect_pts(panel.grow(1.5), 8.0), Color(0.44, 0.28, 0.17))
	clay_slab(_wc, panel, 7.0, Color(0.95, 0.91, 0.82), 2.0)
	# a bone under the lettering, the one emblem every dog can read
	var bc := v + Vector2(0.0, 30.0)
	_wc.draw_line(bc + Vector2(-8, 0), bc + Vector2(8, 0), Color(0.40, 0.26, 0.16), 6.0)
	for bx2: float in [-1.0, 1.0]:
		for by2: float in [-1.0, 1.0]:
			_wc.draw_circle(bc + Vector2(9.0 * bx2, 3.2 * by2), 4.4, Color(0.40, 0.26, 0.16))
	_wc.draw_line(bc + Vector2(-8, 0), bc + Vector2(8, 0), cream, 3.6)
	for bx2: float in [-1.0, 1.0]:
		for by2: float in [-1.0, 1.0]:
			_wc.draw_circle(bc + Vector2(9.0 * bx2, 3.2 * by2), 3.2, cream)
	# FUR, with a paw print for the hyphen, then GONETA under it
	var fur_x := v.x - (w_fur + 11.0) * 0.5
	UiIcons.draw_paw(_wc, Vector2(fur_x + w_fur + 5.5, v.y - 13.0), 4.2, Color(0.66, 0.30, 0.22))
	_wc.draw_string(font, Vector2(fur_x, v.y - 6.0), "FUR", HORIZONTAL_ALIGNMENT_LEFT, -1,
		f_big, ink)
	_wc.draw_string(font, Vector2(panel.position.x, v.y + 9.0), "GONETA",
		HORIZONTAL_ALIGNMENT_CENTER, panel.size.x, f_small, ink)
	_wc.draw_string(font, Vector2(panel.position.x, v.y + 19.0), "dog grooming",
		HORIZONTAL_ALIGNMENT_CENTER, panel.size.x, 8, Color(0.52, 0.36, 0.26))
	if not furgoneta_sniffed:
		# it is the best smell in the city, so the nose can find it
		var fg := 0.5 + 0.5 * sin(prize_glow * 0.8)
		_wc.draw_arc(v, 74.0 + fg * 6.0, 0, TAU, 28, Color(1.0, 0.86, 0.5, 0.10 + fg * 0.07), 2.0)


func _freedom_dirty() -> void:
	# the cached off-leash canvas is out of date: a hole got deeper, a post got
	# sniffed, Brutus made off with a bone
	if freedomlayer != null:
		freedomlayer.mark_dirty()


func draw_freedom_onto(c: Object) -> void:
	# Everything in the off-leash space that does not move, drawn onto
	# freedomlayer's canvas so it survives between redraws. `c` is that canvas;
	# the helpers below take it rather than assuming `self`.
	# the ground the space sits in, out to the level edges
	var surround := Color(0.27, 0.4, 0.27)
	match freedom_kind:
		"beach": surround = Color(0.80, 0.74, 0.59)
		"clearing": surround = Color(0.20, 0.30, 0.19)
		"lot": surround = Color(0.32, 0.31, 0.29)
		"placa": surround = Color(0.36, 0.32, 0.30)
	if lvl == "montjuic":
		surround = Montjuic.RAMPART.darkened(0.2)
	c.draw_rect(Rect2(-400.0, GATE_Y - 2400.0, 2100.0, 2400.0), surround)
	# Montjuic's off-leash space is a plaça in everything but its look: the
	# castle's esplanade
	if lvl == "montjuic":
		Montjuic.draw_castle_beyond(self, c)
		Montjuic.draw_esplanade(self, c)
	else:
		_draw_freedom_beyond(c)
		match freedom_kind:
			"beach": _draw_dog_beach(c)
			"clearing": _draw_clearing(c)
			"lot": _draw_yard(c, true)
			"placa": _draw_placa(c)
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


# Off the leash the camera follows her sideways too. On the walk its x is
# fixed at 640 and the path fits the view; the off-leash space is wider than
# the view at play zoom (and far wider on a phone), so she could run off
# either side, and on the beach swim out of sight. It follows her, clamped so
# the view never shows past the space's walls.
func _cam_x() -> float:
	# off the leash, or on it again but still inside the space going home;
	# never on the way out, where the path fits the view
	var inside := dog.global_position.y < GATE_Y + 20.0
	if not (phase == "freedom" or (phase == "home" and inside)):
		return 640.0
	var hw := get_viewport_rect().size.x / (2.0 * cam.zoom.x)
	var lo := FREEDOM_WALL_W + 50.0 if freedom_kind == "beach" else _freedom_rect().position.x - 20.0
	var hi := _freedom_rect().end.x + 20.0
	if hi - lo <= hw * 2.0:
		return (lo + hi) * 0.5
	return clampf(dog.global_position.x, lo + hw, hi - hw)


func _freedom_rect() -> Rect2:
	return Rect2(70.0, freedom_lo, 1110.0, GATE_Y - 30.0 - freedom_lo)


# PAST THE FAR FENCE. The off-leash space used to stop in a ruled line onto
# the grey of nothing, wherever the camera could see over it. Now there is a
# place beyond it: a hedge and trees behind a dog park, sheds and a wall behind
# a yard, more forest round a clearing, roofs behind a plaça's houses, and the
# sea and sand going on at the beach. Static, on the cached canvas.
func _draw_freedom_beyond(c: Object) -> void:
	var r := _freedom_rect()
	var top := r.position.y
	var b := ShapeBatch.new()
	match freedom_kind:
		"yard":
			# a clipped hedge along the fence, then a row of trees in grass
			b.rect(Rect2(-400.0, top - 34.0, 2100.0, 30.0), Color(0.20, 0.34, 0.20))
			var hx := -380.0
			while hx < 1700.0:
				b.circle(Vector2(hx, top - 19.0), 17.0, Color(0.24, 0.40, 0.23))
				b.circle(Vector2(hx - 5.0, top - 24.0), 8.0, Color(0.32, 0.48, 0.28))
				hx += 26.0
			for k in range(12):
				var tp := Vector2(-300.0 + float(k) * 170.0 + fmod(float(k) * 53.0, 60.0), top - 150.0 - fmod(float(k) * 97.0, 120.0))
				b.circle(tp + LIGHT * 18.0, 52.0, Color(SHADOW_COL.r, SHADOW_COL.g, SHADOW_COL.b, 0.2))
				b.circle(tp, 50.0, Color(0.22, 0.36, 0.21))
				b.circle(tp - LIGHT * 14.0, 30.0, Color(0.30, 0.46, 0.27))
		"lot":
			# a block wall along the fence, and the backs of sheds behind it
			b.rect(Rect2(-400.0, top - 26.0, 2100.0, 22.0), Color(0.52, 0.50, 0.46))
			b.rect(Rect2(-400.0, top - 26.0, 2100.0, 4.0), Color(0.64, 0.62, 0.58))
			var sx := -360.0
			var k := 0
			while sx < 1700.0:
				var w := 150.0 + fmod(float(k) * 71.0, 90.0)
				var sh := Rect2(sx, top - 230.0 - fmod(float(k) * 37.0, 60.0), w - 16.0, 180.0)
				b.rect(Rect2(sh.position + LIGHT * 12.0, sh.size), Color(SHADOW_COL.r, SHADOW_COL.g, SHADOW_COL.b, 0.22))
				var roof := [Color(0.46, 0.48, 0.50), Color(0.56, 0.40, 0.30), Color(0.40, 0.44, 0.40)][k % 3] as Color
				b.rect(sh, roof)
				var ry := sh.position.y + 8.0
				while ry < sh.end.y:
					b.line(Vector2(sh.position.x, ry), Vector2(sh.end.x, ry), roof.darkened(0.18), 2.0)
					ry += 12.0
				sx += w
				k += 1
		"clearing":
			# the wood goes on: canopy over canopy, darker the deeper in
			for row in range(4):
				var cy := top - 40.0 - float(row) * 95.0
				var cx := -380.0 + float(row % 2) * 60.0
				while cx < 1700.0:
					var rr := 54.0 + fmod(absf(cx) * 0.37 + float(row) * 13.0, 22.0)
					var dk := 0.06 * float(row)
					b.circle(Vector2(cx, cy) + LIGHT * 16.0, rr, Color(0.08, 0.12, 0.08, 0.3))
					b.circle(Vector2(cx, cy), rr, Color(0.17 - dk, 0.30 - dk, 0.17 - dk))
					b.circle(Vector2(cx, cy) - LIGHT * rr * 0.3, rr * 0.55, Color(0.23 - dk, 0.38 - dk, 0.21 - dk))
					cx += 110.0
		"placa":
			# the houses' roofs behind their fronts: terracotta in ridged rows
			var rx := -380.0
			var k := 0
			while rx < 1700.0:
				var w := 150.0
				var roof := Rect2(rx, top - 300.0, w - 4.0, 254.0)
				var tile := [Color(0.66, 0.36, 0.24), Color(0.60, 0.32, 0.22), Color(0.70, 0.42, 0.28)][k % 3] as Color
				b.rect(roof, tile)
				var ty := roof.position.y + 6.0
				while ty < roof.end.y:
					b.line(Vector2(roof.position.x, ty), Vector2(roof.end.x, ty), tile.darkened(0.2), 2.0)
					ty += 10.0
				b.line(Vector2(roof.get_center().x, roof.position.y), Vector2(roof.get_center().x, roof.end.y), tile.lightened(0.15), 3.0)
				if k % 3 == 1:
					b.rect(Rect2(roof.position.x + 24.0, roof.position.y + 60.0, 18.0, 18.0), Color(0.50, 0.44, 0.40))
				rx += w
				k += 1
		"beach":
			# the sea and the sand both go on: no edge on the coast
			b.rect(Rect2(-400.0, top - 2000.0, BEACH_SEA_R + 400.0, 1960.0), Color(0.24, 0.44, 0.54))
			b.rect(Rect2(BEACH_SEA_R - 90.0, top - 2000.0, 90.0, 1960.0), Color(0.34, 0.56, 0.62))
			b.rect(Rect2(BEACH_SEA_R, top - 2000.0, 70.0, 1960.0), Color(0.74, 0.66, 0.50))
	b.flush(c)


# THE GATE, as the place would have it. It was a dark bar across the path
# over a dashed line, which read as a road to cross on every walk, the forest
# included. Now: timber posts and no sill on the walks that end in nature,
# stone gateposts and a stone sill in town, and an iron dog-park gate with its
# two leaves swung open everywhere else. Same mouth, gate_l to gate_r.
func _draw_gate() -> void:
	var b := ShapeBatch.new()
	var style := "iron"
	if lvl in ["trail", "guell", "park", "barri", "beach"] and not tutorial_mode:
		style = "timber"
	elif freedom_kind == "placa":
		style = "stone"
	var gy := GATE_Y - 16.0
	# the posts stand at the path's real edges here: gate_l and gate_r are the
	# nominal mouth, which a bending walk's path does not always fill
	var ge := walk_edges(gy)
	var gl := maxf(gate_l, ge.x)
	var gr := minf(gate_r, ge.y)
	match style:
		"timber":
			for px: float in [gl - 12.0, gr + 12.0]:
				b.circle(Vector2(px, gy) + LIGHT * 6.0, 10.0, Color(SHADOW_COL.r, SHADOW_COL.g, SHADOW_COL.b, 0.25))
				b.circle(Vector2(px, gy), 9.0, Color(0.42, 0.30, 0.18))
				b.circle(Vector2(px, gy), 6.0, Color(0.58, 0.44, 0.28))
				# the end grain: a ring, and the heart
				b.circle(Vector2(px, gy), 4.0, Color(0.50, 0.37, 0.23))
				b.circle(Vector2(px, gy), 1.8, Color(0.42, 0.30, 0.18))
		"stone":
			var sill := Rect2(gl, GATE_Y - 6.0, gr - gl, 12.0)
			b.rect(sill, Color(0.70, 0.66, 0.58))
			var jx := gl + 40.0
			while jx < gr:
				b.line(Vector2(jx, sill.position.y), Vector2(jx, sill.end.y), Color(0.56, 0.52, 0.46), 1.5)
				jx += 40.0
			for px: float in [gl - 14.0, gr + 14.0]:
				var pr := Rect2(px - 14.0, gy - 14.0, 28.0, 28.0)
				b.rect(Rect2(pr.position + LIGHT * 8.0, pr.size), Color(SHADOW_COL.r, SHADOW_COL.g, SHADOW_COL.b, 0.25))
				b.rect(pr, Color(0.62, 0.56, 0.48))
				b.rect(pr.grow(-5.0), Color(0.74, 0.69, 0.60))
				b.circle(pr.get_center(), 5.0, Color(0.66, 0.60, 0.52))
		_:
			var iron := Color(0.20, 0.22, 0.22)
			for side: float in [-1.0, 1.0]:
				var hinge := Vector2(gl - 10.0 if side < 0.0 else gr + 10.0, gy)
				b.rect(Rect2(hinge - Vector2(8, 8) + LIGHT * 5.0, Vector2(16, 16)), Color(SHADOW_COL.r, SHADOW_COL.g, SHADOW_COL.b, 0.25))
				b.rect(Rect2(hinge - Vector2(7, 7), Vector2(14, 14)), iron)
				b.circle(hinge, 3.0, Color(0.40, 0.42, 0.42))
				# the leaf, swung open into the dog park against the fence
				var tip := hinge + Vector2(side * 18.0, -62.0)
				b.line(hinge, tip, iron, 3.0)
				var mid := hinge.lerp(tip, 0.5)
				b.line(hinge + Vector2(side * 4.0, -2.0), tip + Vector2(side * 4.0, 2.0), Color(0.36, 0.38, 0.38), 1.2)
				for k in range(1, 5):
					var q := hinge.lerp(tip, float(k) / 5.0)
					b.line(q, q + Vector2(side * 6.0, 0.0), iron, 1.6)
				b.circle(mid, 2.0, Color(0.50, 0.40, 0.20))
	b.flush(_wc)


func _draw_beach_water() -> void:
	# The only part of the dog beach that moves. Everything else - sand, dunes,
	# parasols, the shower - is on freedomlayer's cached canvas, so this is all
	# the sea costs per frame. Crests and foam follow beach_shore_x so they
	# never draw over dry sand in the headland taper.
	var r := _freedom_rect()
	var t := AnimClock.msec() / 1000.0
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
			_wc.draw_polyline(pts, Color(1, 1, 1, 0.22 - float(rank) * 0.055),
				4.0 - float(rank) * 0.8)
	var swell := PackedVector2Array()
	var sy2 := sea_top
	while sy2 < sea_bot:
		swell.append(Vector2(-210.0 + sin(sy2 * 0.007 - t * 0.6) * 26.0, sy2))
		sy2 += 34.0
	if swell.size() > 1:
		_wc.draw_polyline(swell, Color(1, 1, 1, 0.07), 5.0)
	var fy := r.position.y
	while fy < r.end.y:
		var fx := beach_shore_x(fy) + 4.0 + sin(fy * 0.02 + t * 1.4) * 4.0
		_wc.draw_line(Vector2(fx, fy), Vector2(fx, fy + 40.0), Color(1, 1, 1, 0.30), 2.5)
		fy += 52.0


func _draw_freedom_fence(c: Object, r: Rect2, gravel: bool) -> void:
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


func _draw_freedom_benches(c: Object, r: Rect2, col: Color) -> void:
	var x0 := maxf(r.position.x, _dry_x0())
	for bx: Vector2 in [
		Vector2(x0 + 70.0, r.position.y + 60.0),
		Vector2(r.end.x - 70.0, r.position.y + 120.0),
		Vector2(x0 + 90.0, r.end.y - 80.0),
	]:
		contact_shadow(c, bx, 22.0, 8.0, 0.20)
		c.draw_rect(Rect2(bx.x - 22, bx.y - 5, 44, 10), col)
		c.draw_line(Vector2(bx.x - 20, bx.y - 5), Vector2(bx.x - 20, bx.y + 8), col.darkened(0.2), 2.0)
		c.draw_line(Vector2(bx.x + 20, bx.y - 5), Vector2(bx.x + 20, bx.y + 8), col.darkened(0.2), 2.0)
	# the bench the parked owner throws the ball from
	contact_shadow(c, gate_bench, 20.0, 8.0, 0.20)
	c.draw_rect(Rect2(gate_bench.x - 18, gate_bench.y - 6, 36, 11), Color(0.54, 0.4, 0.27))


func _freedom_sign(c: Object, r: Rect2, txt: String, gloss := "") -> void:
	# both lines above the far fence: the gloss used to sit on the fence line
	c.draw_string(font, Vector2(0, r.position.y - 30), txt, HORIZONTAL_ALIGNMENT_CENTER, 1280,
		22, Color(0.9, 0.9, 0.82))
	if gloss != "":
		c.draw_string(font, Vector2(0, r.position.y - 12), gloss, HORIZONTAL_ALIGNMENT_CENTER, 1280,
			14, Color(0.9, 0.9, 0.82, 0.8))


func _draw_yard(c: Object, gravel: bool) -> void:
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
	_freedom_sign(c, r, gate_text, "the off-leash yard" if gravel else "the off-leash dog park")


func _draw_placa(c: Object) -> void:
	# a town square: paving in big squares, house fronts round three sides
	# instead of a fence, plane trees in their pits, and the fountain
	var r := _freedom_rect()
	c.draw_rect(r, Color(0.66, 0.60, 0.52))
	var gx := r.position.x
	while gx < r.end.x:
		c.draw_line(Vector2(gx, r.position.y), Vector2(gx, r.end.y), Color(0.56, 0.50, 0.43, 0.5), 1.5)
		gx += 56.0
	var gy := r.position.y
	while gy < r.end.y:
		c.draw_line(Vector2(r.position.x, gy), Vector2(r.end.x, gy), Color(0.56, 0.50, 0.43, 0.5), 1.5)
		gy += 56.0
	# worn pale where every dog in the barri plays
	c.draw_circle(r.get_center() + Vector2(-80.0, 40.0), 140.0, Color(0.74, 0.68, 0.58, 0.35))
	# the house fronts: a strip of facade with doorways, shutters and a
	# balcony rail, along the top and both sides
	var fcols := [Color(0.62, 0.44, 0.34), Color(0.70, 0.58, 0.42), Color(0.56, 0.48, 0.44)]
	var k := 0
	var fx := r.position.x
	while fx < r.end.x:
		var w := minf(150.0, r.end.x - fx)
		var col: Color = fcols[k % 3]
		c.draw_rect(Rect2(fx, r.position.y - 46.0, w, 46.0), col)
		c.draw_rect(Rect2(fx, r.position.y - 6.0, w, 6.0), col.darkened(0.3))
		c.draw_rect(Rect2(fx + w * 0.5 - 12.0, r.position.y - 30.0, 24.0, 30.0), Color(0.22, 0.17, 0.14))
		c.draw_line(Vector2(fx + 10.0, r.position.y - 38.0), Vector2(fx + w - 10.0, r.position.y - 38.0), Color(0.16, 0.16, 0.18), 2.0)
		fx += 150.0
		k += 1
	for sx: float in [r.position.x - 40.0, r.end.x]:
		var fy := r.position.y
		k = 1
		while fy < r.end.y - 60.0:
			var col2: Color = fcols[k % 3]
			c.draw_rect(Rect2(sx, fy, 40.0, 130.0), col2)
			c.draw_rect(Rect2(sx + (34.0 if sx < r.position.x else 0.0), fy, 6.0, 130.0), col2.darkened(0.3))
			c.draw_rect(Rect2(sx + 8.0, fy + 50.0, 24.0, 30.0), Color(0.22, 0.17, 0.14))
			fy += 130.0
			k += 1
	# the plane trees' pits: squares of earth in the paving
	for t: Vector2 in trees:
		c.draw_rect(Rect2(t - Vector2(20, 20), Vector2(40, 40)), Color(0.36, 0.28, 0.20))
		c.draw_rect(Rect2(t - Vector2(20, 20), Vector2(40, 40)), Color(0.30, 0.30, 0.32), false, 2.0)
	# the fountain: a stone basin, water a dog can get into, a spout
	var fr: Rect2 = LevelBuild.placa_fountain(self)
	contact_shadow(c, fr.get_center(), fr.size.x * 0.5, 10.0, 0.2)
	c.draw_rect(fr.grow(10.0), Color(0.78, 0.74, 0.66))
	c.draw_rect(fr.grow(10.0), Color(0.58, 0.54, 0.48), false, 2.0)
	c.draw_rect(fr, Color(0.30, 0.50, 0.58))
	c.draw_rect(Rect2(fr.position, Vector2(fr.size.x, 8.0)), Color(0.22, 0.40, 0.48))
	for i in range(3):
		c.draw_arc(fr.get_center(), 16.0 + float(i) * 14.0, 0.0, TAU, 24, Color(0.70, 0.86, 0.92, 0.35 - float(i) * 0.1), 1.5)
	c.draw_circle(fr.get_center(), 9.0, Color(0.70, 0.66, 0.58))
	c.draw_circle(fr.get_center(), 4.0, Color(0.84, 0.94, 0.98))
	_draw_freedom_benches(c, r, Color(0.36, 0.30, 0.24))
	_freedom_sign(c, r, "PLAÇA DELS GOSSOS", "the dogs' square, off leash")


func _draw_clearing(c: Object) -> void:
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
	_freedom_sign(c, r, gate_text, "the clearing, off leash")


func _draw_dog_beach(c: Object) -> void:
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
	# spaced round the agility lane, which runs between the first two
	for i in range(3):
		var pa := Vector2(r.end.x - 260.0, r.position.y + [150.0, 390.0, 600.0][i])
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
	_freedom_sign(c, r, "PLATJA DELS GOSSOS", "the dog beach, off leash")
	_draw_espigo(c)


# the espigó: a breakwater of big rocks across the water at the gate line,
# which is where the dog beach's bottom boundary runs (LevelBuild.build_walls)
func _draw_espigo(c: Object) -> void:
	var b := ShapeBatch.new()
	var fy := GATE_Y - 30.0
	var bx := FREEDOM_WALL_W - 10.0
	var k := 0
	while bx < BEACH_GATE_SHORE_X + 10.0:
		var rr := 15.0 + fmod(float(k) * 7.3, 8.0)
		var rp := Vector2(bx, fy + fmod(float(k) * 5.1, 8.0) - 4.0)
		b.circle(rp + LIGHT * 5.0, rr, Color(0.10, 0.20, 0.26, 0.45))
		b.circle(rp, rr, Color(0.46, 0.44, 0.40))
		b.circle(rp - LIGHT * rr * 0.35, rr * 0.5, Color(0.60, 0.58, 0.53))
		bx += rr * 1.5
		k += 1
	b.flush(c)


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
	"beach": "sand", "park": "dirt", "trail": "dirt", "barri": "dirt",
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
		_wc.draw_set_transform(Vector2(x + w * 0.5, at.y + wob * jitter),
			wob2 * jitter * 0.02, Vector2.ONE)
		_wc.draw_char(f, Vector2(-w * 0.5, 0.0), ch, px, col)
		x += w
	_wc.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


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
			_wc.draw_rect(r, Color(0.90, 0.88, 0.82))
			_wc.draw_rect(r, Color(0.30, 0.42, 0.62), false, 3.0)
			var tx := r.position.x
			while tx < r.end.x:
				_wc.draw_line(Vector2(tx, r.position.y), Vector2(tx, r.end.y),
					Color(0.72, 0.72, 0.70, 0.6), 1.0)
				tx += r.size.y * 0.5
			_hand_text(at, txt, px, Color(0.18, 0.30, 0.55, 0.92), 0.8, key)
		_:
			# a works board or a departures board: dot-matrix on steel
			var bw: float = font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
			var br := Rect2(at.x - bw * 0.5 - 22.0, at.y - float(px) * 0.9,
				bw + 44.0, float(px) * 1.3)
			_wc.draw_rect(br, Color(0.14, 0.15, 0.16))
			_wc.draw_rect(br, Color(0.40, 0.42, 0.44), false, 3.0)
			_wc.draw_rect(Rect2(br.position.x + 4.0, br.position.y + 4.0, br.size.x - 8.0, 3.0),
				Color(1, 1, 1, 0.10))
			_hand_text(at, txt, px, Color(0.98, 0.78, 0.28, 0.95), 0.0, key)


# the tutorial walks another walk's ground, but it is still the First Walk
func _walk_name() -> String:
	return String(Game.LEVEL_NAMES["tutorial" if tutorial_mode else lvl])


func _sign_mat() -> String:
	return WorldSign.material_for(lvl, Game.weather)


# The name, the browse arrows and HOME, as loose pieces for a walk with a
# material. Built from what the title step says; the same step twice keeps
# the pieces where they are.
func build_signs() -> void:
	var mat := _sign_mat()
	var arrows := not started and menu_step == 1
	var want := "%s/%d/%s" % [mat, 0 if menu_step == 0 and not started else 1, arrows]
	if want == _signs_for:
		return
	_signs_for = want
	signs.clear()
	signs_built += 1
	if mat == "":
		return
	var e := walk_edges(START_Y - 190.0)
	var room := maxf(300.0, e.y - e.x - 80.0)
	var mid := (e.x + e.y) * 0.5
	if menu_step == 0 and not started:
		signs.append(WorldSign.build("PATH OF", Vector2(mid, START_Y - 232.0), 44.0, mat, 1.0, room))
		signs.append(WorldSign.build("LEASH RESISTANCE", Vector2(mid, START_Y - 172.0), 44.0, mat, 2.0, room))
	else:
		var name := _walk_name()
		var nm := WorldSign.build(name, Vector2(mid, START_Y - 190.0), 44.0, mat, 4.0, room - 120.0)
		signs.append(nm)
		if arrows:
			var hw: float = WorldSign.Letters.width(name.to_upper(), float(nm.h)) * 0.5
			signs.append(WorldSign.build("<", Vector2(mid - hw - 44.0, START_Y - 190.0), 44.0, mat, 6.0, 80.0))
			signs.append(WorldSign.build(">", Vector2(mid + hw + 44.0, START_Y - 190.0), 44.0, mat, 7.0, 80.0))
	var he := walk_edges(HOME_Y + 84.0)
	signs.append(WorldSign.build("HOME", Vector2((he.x + he.y) * 0.5, HOME_Y + 84.0), 26.0, mat, 9.0, 300.0))
	# over the gate, what is through it and what that means, in the same stuff
	var gm := (gate_l + gate_r) * 0.5
	var gw := maxf(160.0, gate_r - gate_l - 20.0)
	# traffic cones are fat pieces: small words in them are a pile of cones
	var gk := 1.4 if mat == "cones" else 1.0
	signs.append(WorldSign.build(gate_text, Vector2(gm, GATE_Y - 72.0 * gk), 36.0 * gk, mat, 11.0, gw))
	signs.append(WorldSign.build("OFF LEASH", Vector2(gm, GATE_Y - 124.0 * gk - 4.0), 24.0 * gk, mat, 12.0, gw))


func _tick_signs(delta: float) -> void:
	if signs.is_empty():
		return
	var bodies := [[dog.global_position, dog.velocity, 15.0], [human.global_position, human.velocity, 18.0]]
	var rope := []
	if not leash.detached:
		for k in range(leash.pts.size()):
			rope.append([leash.pts[k], (leash.pts[k] - leash.prev[k]) / maxf(delta, 0.001)])
	var toppled := 0
	for sg: Dictionary in signs:
		toppled += WorldSign.tick(sg, bodies, rope, delta, elapsed)
	if toppled > 0:
		Sfx.play("tangle", 1.7, -16.0)


# Whether a sign is drawn with the world drawn for the band vt..vb.
func sign_shown(sg: Dictionary, vt: float, vb: float) -> bool:
	if float(sg.bottom) < vt - 60.0 or float(sg.top) > vb + 60.0:
		return false
	# HOME means nothing before she has set off, and on the title and the
	# walk select it sits under the prompt bar (#21)
	return started or String(sg.get("txt", "")) != "HOME"


func _draw_signs(vt: float, vb: float) -> void:
	draw_signs_onto(_wc, vt, vb)


# the sign layer's picture: every sign shown for the band vt..vb
func draw_signs_onto(c: Object, vt: float, vb: float) -> void:
	for sg: Dictionary in signs:
		if sign_shown(sg, vt, vb):
			WorldSign.draw(c, sg, AnimClock.msec() / 1000.0, LIGHT)


func _draw_ground_title() -> void:
	# On the title screen the game's name is on the ground she is standing
	# on; on the walk select it is the walk's name. A walk with a material
	# (world/world_sign.gd) spells it in loose pieces, drawn by _draw_signs
	# whether or not the walk has started; the rest write it in their medium
	# here. The gloss is menu text, and fades as the walk begins.
	var style := String(SIGN_STYLES.get(lvl, "chalk"))
	var mat := _sign_mat()
	var ge := walk_edges(START_Y - 190.0)
	var mid := (ge.x + ge.y) * 0.5
	if menu_step == 0 and not started:
		if mat == "":
			_draw_world_text(Vector2(mid, START_Y - 232.0), "PATH OF", 52, style, 1.0)
			_draw_world_text(Vector2(mid, START_Y - 176.0), "LEASH RESISTANCE", 52, style, 2.0)
		# no subtitle under the title: the name and the walk say it
		return
	var name := _walk_name().to_upper()
	var y := START_Y - 190.0
	if mat == "":
		_draw_world_text(Vector2(mid, y), name, 46, style, 4.0)
		if menu_step == 1 and not started:
			var w: float = font.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, 46).x
			_draw_world_text(Vector2(mid - w * 0.5 - 44.0, y), "<", 46, style, 6.0)
			_draw_world_text(Vector2(mid + w * 0.5 + 44.0, y), ">", 46, style, 7.0)
	# The name is Catalan for character; this says what it MEANS, because the
	# game ships in English and nobody should have to guess what a walk is.
	var gloss := String(Game.LEVEL_SUBTITLES.get("tutorial" if tutorial_mode else lvl, ""))
	if gloss != "":
		_draw_gloss(Vector2(mid, y + 30.0), gloss, mat, style, 8.0)


func _draw_gloss(at: Vector2, txt: String, mat: String, style: String, key: float) -> void:
	if gloss_a <= 0.01:
		return
	# the line under the walk's name is menu text, so it is set plainly in the
	# menus' face (not hand-wobbled) and fades with the rest as the walk begins
	var col: Color = WorldSign.GLOSS.get(mat, Color(0.97, 0.95, 0.88, 0.9))
	var f: Font = load("res://hud/ui_kit.gd").body()
	var px := 20
	var w: float = f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
	var p := at - Vector2(w * 0.5, 0.0)
	_wc.draw_string(f, p + Vector2(1.0, 1.5), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, px,
		Color(0, 0, 0, 0.30 * col.a * gloss_a))
	_wc.draw_string(f, p, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, px, Color(col.r, col.g, col.b, col.a * gloss_a))


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
		_wc.draw_rect(Rect2(wx - 60.0, sy, 190.0, 200.0), Color(0.80, 0.76, 0.66))
		# barrel-vaulted roof ribs, which is what says "works" and not "flats"
		for r in range(9):
			var ry := sy + 14.0 + float(r) * 21.0
			_wc.draw_line(Vector2(wx - 54.0, ry), Vector2(wx + 118.0, ry),
				Color(0.62, 0.63, 0.62), 5.0)
		_wc.draw_rect(Rect2(wx - 60.0, sy, 190.0, 200.0), Color(0.32, 0.29, 0.25), false, 2.5)
	# the chimney: a tapering brick tower, and the long shadow that sells it
	var cx := wx - 34.0
	var cy := WORKS_Y
	cast_shadow(_wc, Vector2(cx, cy), 15.0, 340.0, 0.26)
	_wc.draw_circle(Vector2(cx, cy), 17.0, Color(0.52, 0.34, 0.25))
	_wc.draw_circle(Vector2(cx, cy), 12.5, Color(0.63, 0.42, 0.30))
	_wc.draw_circle(Vector2(cx - 2.0, cy - 2.0), 8.0, Color(0.72, 0.50, 0.36))
	_wc.draw_circle(Vector2(cx, cy), 5.0, Color(0.17, 0.14, 0.13))
	# a painted sign on the seaward shed wall, facing the walk
	_draw_world_text(Vector2(wx + 16.0, WORKS_Y + 176.0), "LA FABRICA", 17, "paint", 9.0)


func _draw_park_props(c: Object, vt: float, vb: float) -> void:
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
			"post" when freedom_kind == "placa":
				contact_shadow(c, p, 8.0, 5.0)
			"dig" when freedom_kind == "placa":
				# dug in a tree pit's earth, not through the paving
				c.draw_rect(Rect2(p - Vector2(24, 24), Vector2(48, 48)), Color(0.38, 0.30, 0.22))
				c.draw_rect(Rect2(p - Vector2(24, 24), Vector2(48, 48)), Color(0.30, 0.30, 0.32), false, 2.0)
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
			"post" when freedom_kind == "placa":
				# a cast-iron bollard, the barri's lamp-post for dogs
				c.draw_circle(p, 13.0, Color(0.52, 0.48, 0.42, 0.35))
				c.draw_circle(p, 7.0, Color(0.16, 0.17, 0.18))
				c.draw_circle(p + Vector2(-1.5, -1.5), 4.5, Color(0.28, 0.29, 0.31))
				c.draw_circle(p + Vector2(-2.0, -2.0), 1.6, Color(0.50, 0.52, 0.54))
			"planter":
				# a stone planter with a clipped bush in it: solid, go round it
				c.draw_rect(Rect2(p - Vector2(17, 17), Vector2(34, 34)), Color(0.74, 0.70, 0.62))
				c.draw_rect(Rect2(p - Vector2(17, 17), Vector2(34, 34)), Color(0.56, 0.52, 0.46), false, 2.0)
				c.draw_circle(p, 12.0, Color(0.26, 0.42, 0.24))
				c.draw_circle(p - LIGHT * 4.0, 7.0, Color(0.34, 0.52, 0.30))
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
			"trough" when lvl == "trail":
				# a forest spring, a font: a stone back with a pipe, the water
				# falling from it into a round stone basin, moss on the stones
				c.draw_circle(p + LIGHT * 5.0, 22.0, Color(SHADOW_COL.r, SHADOW_COL.g, SHADOW_COL.b, 0.25))
				c.draw_rect(Rect2(p.x - 16.0, p.y - 26.0, 32.0, 12.0), Color(0.50, 0.47, 0.42))
				c.draw_rect(Rect2(p.x - 16.0, p.y - 26.0, 32.0, 3.0), Color(0.64, 0.61, 0.56))
				c.draw_circle(p, 20.0, Color(0.46, 0.43, 0.38))
				c.draw_circle(p - LIGHT * 3.0, 18.0, Color(0.58, 0.55, 0.49))
				c.draw_circle(p, 14.0, Color(0.20, 0.34, 0.40))
				c.draw_circle(p + Vector2(-3.0, -3.0), 9.0, Color(0.32, 0.50, 0.58))
				for mo: Vector2 in [Vector2(-14, 8), Vector2(12, 12), Vector2(-10, -24)]:
					c.draw_circle(p + mo, 4.0, Color(0.30, 0.44, 0.22, 0.85))
				# the pipe, and the water falling into the basin, rings spreading
				c.draw_line(p + Vector2(0, -20), p + Vector2(0, -12), Color(0.36, 0.34, 0.32), 3.0)
				c.draw_line(p + Vector2(0, -12), p + Vector2(0, -4), Color(0.78, 0.88, 0.94, 0.8), 2.0)
				# a still ring where it falls: this canvas is cached, so anything
				# animated here would freeze wherever the last redraw left it
				c.draw_arc(p + Vector2(0, -3), 5.0, 0, TAU, 14, Color(0.80, 0.90, 0.96, 0.4), 1.2)
			"trough":
				# A galvanised water trough: a thick rim, water sitting BELOW
				# it, a highlight where the light hits the surface, and a
				# slow ripple. It was three flat rectangles.
				var tw := AnimClock.msec() / 1000.0
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
	LevelBuild.build_substance_zones(self)


func _build_freedom_area() -> void:
	LevelBuild.build_freedom_area(self)


func _patch_clear(pt: Dictionary) -> bool:
	return LevelBuild.patch_clear(self, pt)


func _settle_patches() -> void:
	LevelBuild.settle_patches(self)


func _lift_props_out_of_water() -> void:
	LevelBuild.lift_props_out_of_water(self)


func _nearest_dry(at: Vector2) -> Vector2:
	return LevelBuild.nearest_dry(self, at)


func _build_dunes() -> void:
	LevelBuild.build_dunes(self)


func _build_park_props() -> void:
	LevelBuild.build_park_props(self)


func _build_ground_detail() -> void:
	LevelBuild.build_ground_detail(self)


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
				_wc.draw_line(p, mid, crack, 1.4)
				_wc.draw_line(mid, kink, crack, 1.1)
			1:
				# a scatter of grit
				for g in range(3):
					_wc.draw_circle(p + dir.rotated(float(g) * 2.1) * (4.0 + g * 3.0), float(d.sz) * 0.5, grit)
			2:
				# a damp patch / old stain
				_wc.draw_circle(p, float(d.len) * 0.35, stain)
			4:
				# a drain grate set in the paving: a dark frame and its slots
				var dq := PackedVector2Array([p + dir * 9.0 + dir.orthogonal() * 6.0, p + dir * 9.0 - dir.orthogonal() * 6.0,
					p - dir * 9.0 - dir.orthogonal() * 6.0, p - dir * 9.0 + dir.orthogonal() * 6.0])
				_wc.draw_colored_polygon(dq, Color(0.20, 0.20, 0.22, 0.75))
				for k in range(4):
					var sx := p + dir * (-6.0 + float(k) * 4.0)
					_wc.draw_line(sx + dir.orthogonal() * 4.0, sx - dir.orthogonal() * 4.0, Color(0.08, 0.08, 0.10, 0.8), 1.4)
			5:
				# an old repair: an uneven patch of newer, darker surface, its seam
				# showing only along the edges the roller missed. Six corners, so
				# it reads as patched ground, not a box set on it
				var o := dir.orthogonal()
				var rq := PackedVector2Array([p + dir * 17.0 + o * 6.0, p + dir * 9.0 - o * 11.0,
					p - dir * 8.0 - o * 10.0, p - dir * 16.0 - o * 2.0, p - dir * 10.0 + o * 11.0, p + dir * 6.0 + o * 12.0])
				_wc.draw_colored_polygon(rq, Color(0.22, 0.22, 0.24, 0.12))
				_wc.draw_polyline(PackedVector2Array([rq[4], rq[5], rq[0], rq[1]]), Color(0.18, 0.18, 0.20, 0.22), 1.1)
			_:
				# a bit of litter: a leaf or a scrap of paper
				var c: Color = litter[int(d.sz) % litter.size()]
				_wc.draw_line(p - dir * float(d.sz) * 1.6, p + dir * float(d.sz) * 1.6, c, float(d.sz))


# A parasol from above, as the dog beach draws them: eight panels in two
# tones round a hub, a scalloped hem, the lit side, and its shade falling
# clear on the ground. Still see-through, so she can be seen under it.
func _draw_parasol(pa: Vector2, col: Color, key: float) -> void:
	var R := 40.0
	var turn := key * 0.37
	var b := ShapeBatch.new()
	b.circle(pa + LIGHT * 16.0, R * 0.92, Color(SHADOW_COL.r, SHADOW_COL.g, SHADOW_COL.b, 0.16))
	var light := Color(minf(col.r + 0.30, 1.0), minf(col.g + 0.30, 1.0), minf(col.b + 0.28, 1.0), col.a)
	for panel in range(8):
		var a0 := TAU * float(panel) / 8.0 + turn
		var a1 := a0 + TAU / 8.0
		var mid := Vector2.from_angle((a0 + a1) * 0.5) * R * 1.03
		b.polygon(PackedVector2Array([pa, pa + Vector2.from_angle(a0) * R * 0.97, pa + mid,
			pa + Vector2.from_angle(a1) * R * 0.97]), col if panel % 2 == 0 else light)
	for panel in range(8):
		var a := TAU * float(panel) / 8.0 + turn
		b.line(pa, pa + Vector2.from_angle(a) * R * 0.97, Color(col.r * 0.6, col.g * 0.6, col.b * 0.6, 0.55), 1.5)
	b.circle(pa - LIGHT * 12.0, 13.0, Color(1, 1, 1, 0.12))
	b.circle(pa, 4.5, Color(0.42, 0.38, 0.34))
	b.circle(pa, 2.0, Color(0.66, 0.62, 0.56))
	b.flush(_wc)


# A BEACH TOWEL: striped across both ends, fringed, and either someone lying
# on it in the sun or the things they left (flip-flops, a paperback, the sun
# cream). In rain or snow nobody is sunbathing: the towel is left out, wet or
# dusted white. Drawing only; where a towel is and what it does stays put.
const TOWEL_SKINS := [Color(0.94, 0.78, 0.64), Color(0.80, 0.60, 0.44), Color(0.58, 0.40, 0.28), Color(0.96, 0.70, 0.60)]
const TOWEL_HAIR := [Color(0.20, 0.14, 0.10), Color(0.62, 0.42, 0.20), Color(0.86, 0.74, 0.44), Color(0.12, 0.10, 0.10)]
const TOWEL_SUITS := [Color(0.16, 0.30, 0.62), Color(0.86, 0.26, 0.30), Color(0.12, 0.52, 0.46), Color(0.96, 0.62, 0.20)]


func _draw_towel(twd: Dictionary, i: int) -> void:
	var r: Rect2 = twd.rect
	var col: Color = twd.col
	var wx: String = Game.weather
	if wx == "rain":
		col = col.darkened(0.3)
	_wc.draw_rect(r, col)
	# stripes across each end, and the fringe past them
	var stripe := Color(1, 1, 1, 0.55) if i % 2 == 0 else col.darkened(0.25)
	for e: float in [r.position.y + 8.0, r.end.y - 13.0]:
		_wc.draw_rect(Rect2(r.position.x, e, r.size.x, 5.0), stripe)
	var fx := r.position.x + 3.0
	while fx < r.end.x - 1.0:
		_wc.draw_line(Vector2(fx, r.position.y), Vector2(fx, r.position.y - 4.0), col.lightened(0.2), 1.2)
		_wc.draw_line(Vector2(fx, r.end.y), Vector2(fx, r.end.y + 4.0), col.lightened(0.2), 1.2)
		fx += 5.0
	if wx == "snow":
		_wc.draw_rect(r.grow(-3.0), Color(0.96, 0.97, 1.0, 0.55))
	var c := r.get_center()
	var basking: bool = twd.bather and wx != "rain" and wx != "snow" and not Game.night
	if basking:
		var skin: Color = TOWEL_SKINS[i % TOWEL_SKINS.size()]
		var suit: Color = TOWEL_SUITS[(i + 1) % TOWEL_SUITS.size()]
		var sh := Color(0, 0, 0, 0.18)
		# lying on their back, head at the top end: shadow, legs, arms, body
		_wc.draw_line(c + Vector2(-4, 4) + LIGHT * 2.0, c + Vector2(-5, 30) + LIGHT * 2.0, sh, 6.0)
		_wc.draw_line(c + Vector2(4, 4) + LIGHT * 2.0, c + Vector2(6, 30) + LIGHT * 2.0, sh, 6.0)
		for s: float in [-1.0, 1.0]:
			var foot := c + Vector2(s * (5.0 + float(i % 2)), 30.0)
			_wc.draw_line(c + Vector2(s * 4.0, 4.0), foot, skin, 5.5)
			_wc.draw_circle(foot, 2.8, skin)
			_wc.draw_line(c + Vector2(s * 8.0, -14.0), c + Vector2(s * 11.0, 2.0), skin.darkened(0.06), 3.6)
			_wc.draw_circle(c + Vector2(s * 11.0, 2.0), 2.2, skin.darkened(0.06))
		HumanAppearance.draw_torso(_wc, c + Vector2(0, -8), Vector2.UP, Vector2(9.0, 8.0), skin)
		# the swimsuit: trunks, or a one-piece
		if i % 2 == 0:
			_wc.draw_rect(Rect2(c.x - 6.0, c.y - 2.0, 12.0, 7.0), suit)
		else:
			_wc.draw_colored_polygon(PackedVector2Array([c + Vector2(-6, -15), c + Vector2(6, -15),
				c + Vector2(6, 5), c + Vector2(-6, 5)]), suit)
		var head := c + Vector2(0, -24)
		HumanAppearance.draw_head(_wc, head, Vector2.UP, 6.0, skin, TOWEL_HAIR[i % TOWEL_HAIR.size()],
			"long" if i % 2 == 1 else "short")
		# sunglasses on, eyes shut
		_wc.draw_line(head + Vector2(-4.0, -2.2), head + Vector2(4.0, -2.2), Color(0.08, 0.08, 0.10), 2.2)
	else:
		# what they left: flip-flops at the foot, the paperback and the sun cream
		for s: float in [-1.0, 1.0]:
			var ff := Vector2(c.x + s * 6.0, r.end.y - 22.0)
			_wc.draw_colored_polygon(HumanAppearance._disc_points(ff, Vector2(6.0, 3.0), Vector2.UP), Color(0.20, 0.62, 0.86))
			_wc.draw_line(ff + Vector2(0, -3), ff + Vector2(s * 2.0, 1.0), Color(0.96, 0.96, 0.94), 1.0)
		_wc.draw_rect(Rect2(c.x - 8.0, c.y - 18.0, 13.0, 9.0), Color(0.94, 0.90, 0.80))
		_wc.draw_line(Vector2(c.x - 1.5, c.y - 18.0), Vector2(c.x - 1.5, c.y - 9.0), Color(0.6, 0.55, 0.5), 1.0)
		_wc.draw_rect(Rect2(c.x + 7.0, c.y - 4.0, 5.0, 11.0), Color(0.98, 0.84, 0.30))
		_wc.draw_rect(Rect2(c.x + 7.5, c.y - 6.0, 4.0, 2.5), Color(0.90, 0.40, 0.20))


func _build_bypasser_blockers() -> void:
	LevelBuild.build_bypasser_blockers(self)


func _build_walls() -> void:
	LevelBuild.build_walls(self)


func _add_rect_body(at: Vector2, size: Vector2) -> void:
	LevelBuild.add_rect_body(self, at, size)


func _build_entities() -> void:
	LevelBuild.build_entities(self)


# each walk's goal list; defined in systems/goals.gd, aliased for level_check.gd
const LEVEL_GOAL_IDS := Goals.LEVEL_GOAL_IDS


func _goal_defs() -> Dictionary:
	# goals and scoring live in systems/goals.gd
	return Goals.defs(self)


func _build_quests() -> void:
	Goals.build_quests(self)


func _quest_text(q: Dictionary) -> String:
	return Goals.quest_text(q)


func _peek_goals() -> void:
	goals_peek = 3.0


func _credit_goal(q: Dictionary) -> void:
	Goals.credit(self, q)


func _check_goals() -> void:
	Goals.check(self)


func _spawn_cones() -> void:
	LevelBuild.spawn_cones(self)


func _spawn_junk(at: Vector2, kind: String) -> void:
	LevelBuild.spawn_junk(self, at, kind)


func on_junk_kicked(pos: Vector2, kind: String) -> void:
	# a light, kind-appropriate clatter; heavier things thud
	match kind:
		"can": Sfx.play("tangle", 1.9, -13.0)
		"bottle": Sfx.play("tangle", 1.6, -13.0)
		"ball": Sfx.play("snack", 0.7, -14.0)
		"sack", "crate": Sfx.play("crack", 0.6, -15.0)
		_: Sfx.play("tangle", 1.3, -14.0)


func _build_hud() -> void:
	# every card, label and bar, in draw order: hud/hud_build.gd
	HudBuild.build(self)


func _weather_tint() -> Color:
	var c := Color(0.5, 0.55, 0.78) if Game.night else Color.WHITE
	# La Neteja is at dawn: the light comes in low, pink and gold
	if lvl == "neteja" and not Game.night:
		c = Color(1.0, 0.86, 0.78)
	if Game.weather == "rain":
		c = c * Color(0.72, 0.76, 0.82)  # grey, overcast
	elif Game.weather == "wind":
		c = c * Color(0.92, 0.9, 0.82)  # dusty, warm-grey
	elif Game.weather == "snow":
		c = c * Color(0.9, 0.94, 1.02)  # cold, bright, blue-white
	return c


func _apply_menu_step() -> void:
	MenuFlow.apply_menu_step(self)


func _open_shop() -> void:
	MenuFlow.open_shop(self)


func _shop_data(kind: String, key: String) -> Dictionary:
	return MenuFlow.shop_data(self, kind, key)


func _equip(kind: String, key: String) -> void:
	MenuFlow.equip(self, kind, key)


func _shop_select() -> void:
	MenuFlow.shop_select(self)


func _refresh_shop() -> void:
	MenuFlow.refresh_shop(self)


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
	return MenuFlow.settings_keys(self)


func settings_rows() -> Array:
	return MenuFlow.settings_rows(self)


func pad_hints() -> bool:
	return MenuFlow.pad_hints(self)


func _check_settings_roundtrip() -> Array:
	return MenuFlow.check_settings_roundtrip(self)


func _open_settings_from_menu() -> void:
	MenuFlow.open_settings_from_menu(self)


func _open_settings() -> void:
	MenuFlow.open_settings(self)


func _close_settings() -> void:
	MenuFlow.close_settings(self)


func _settings_adjust(dir: int) -> void:
	MenuFlow.settings_adjust(self, dir)


func _tick_settings() -> void:
	MenuFlow.tick_settings(self)


# the moment the "drink" goal is met, wherever she was drinking: said once
func _praise_drink(at: Vector2) -> void:
	if drink_praised or drunk_amount < DRINK_ENOUGH:
		return
	drink_praised = true
	bones += 2
	combo.add("DRINK", 2)
	float_text(at, "a proper long drink! +2", Color(0.8, 0.92, 1.0))
	_update_hud()


# After fetch, the banner says what else there is to do here, a few seconds
# each, instead of only pointing home: the off-leash space is a break with
# things in it, and nothing else ever told her about digging or the water.
func _freedom_hint() -> String:
	var hints: Array[String] = []
	var digs_left := false
	var sniffs_left := false
	for pp in park_props:
		if pp.done:
			continue
		match String(pp.kind):
			"dig": digs_left = true
			"shrub", "post", "rock", "driftwood", "tyre", "planter", "log": sniffs_left = true
	if digs_left:
		hints.append("DIG FOR TREASURE WHERE IT SMELLS")
	if drunk_amount < DRINK_ENOUGH:
		hints.append("HAVE A LONG DRINK AT THE WATER")
	if sniffs_left:
		hints.append("SNIFF OUT WHAT'S LYING ABOUT")
	hints.append_array(FreedomGames.hints(self))
	hints.append("BACK OUT THROUGH THE GATE, THEN HOME")
	return hints[int(elapsed / 4.0) % hints.size()]


func _progress_rows() -> Array:
	return MenuFlow.progress_rows(self)


func _update_hud() -> void:
	hud_status = ""
	if phase == "freedom":
		var dp := dog.global_position
		if not romp_done and elapsed - freedom_at > 2.0 and dp.y > GATE_Y - 70.0 				and dp.x > gate_l and dp.x < gate_r and dog.velocity.y > 40.0:
			# heading back out with the round still on: say so before it is lost
			hud_status = "LEAVING ALREADY? FETCH ISN'T DONE"
		elif FreedomGames.banner(self) != "":
			hud_status = FreedomGames.banner(self)
		elif romp_done:
			hud_status = _freedom_hint()
		else:
			hud_status = "FETCH! BRING IT BACK  %d/%d   %ds" % [romp_catches, romp_target, int(ceil(romp_timer))]
	elif phase == "home":
		if chase_active and chase_sweeper != null:
			if chase_sweeper.jammed():
				hud_status = "IT'S STUCK! CATCH YOUR BREATH"
			elif chase_kind == "both":
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
		hud_status = Prompts.fill("NATURE CALLS! STAND STILL, HOLD {plant}")
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
		hud_status = "FULL TANK! GO MARK A SPOT"
	elif pee <= 0.02:
		hud_status = "THIRSTY! FIND A FOUNTAIN"
	# The one-line answer to "what is going on" lives in the feed banner,
	# centre screen near the dog, instead of as small text tucked under the
	# vitals card where it was never read. This call used to sit after a
	# return in _progress_text, so the banner was never set and none of the
	# lines above reached the screen (#29).
	# Only during a walk: on the title the status would sit over the chalked
	# name (the scrapyard's "GO SLOW" is set before you have set off).
	if feed != null:
		# a first-time tip takes the banner while it is up
		if tip_t > 0.0 and tip_text != "":
			hud_status = tip_text
		# the tutorial teaches one thing at a time: the lesson card is the only instruction
		feed.set_banner(hud_status if started and not tutorial_mode else "")
	goals_card.visible = started and not tutorial_mode


func goal_card_data() -> Dictionary:
	return Goals.card_data(self)


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
	feed.say("DARE: %d TRICKS, GO!" % target, EventFeed.Tone.LOUD)


func on_challenge_done(win: bool, target: int, count: int) -> void:
	Sfx.play("star" if win else "ui")
	if is_instance_valid(challenge_giver):
		challenge_giver.resolve(win)
	if win:
		var reward := 20 + target * 3
		bones += reward
		feed.say("DARE DONE!  +%d" % reward, EventFeed.Tone.GOOD)
		_slowmo()
	else:
		feed.say("DARE MISSED: %d OF %d" % [count, target], EventFeed.Tone.BAD)


# a first-time tip, from a script that has no Tips (human.gd)
func tip(id: String) -> void:
	Tips.show(self, id)


func _physics_process(delta: float) -> void:
	if frozen:
		return
	elapsed += delta
	# the telefèric ride is a short cinematic: the walk holds still round it
	if cable_riding:
		CableCar.tick_ride(self, delta)
		return
	_prof("")
	riders_cache = get_tree().get_nodes_in_group("bikes")
	critters_cache = get_tree().get_nodes_in_group("squirrels")
	birds_cache = get_tree().get_nodes_in_group("pigeons")
	# weather nudges: rain makes the pavement slick, wind shoves everyone
	# gently downwind (the owner, dead weight, catches more of it)
	dog.slick = Game.weather == "rain" and not sheltered(dog.global_position)
	if lvl == "rain":
		_tick_wet(delta)
	dog.ice = Game.weather == "snow"
	human.ice = Game.weather == "snow"
	if Game.weather == "wind":
		dog.velocity += Vector2(46.0, 0) * delta
		human.velocity += Vector2(70.0, 0) * delta
	if lvl == "montjuic":
		Montjuic.tick_wind(self, delta)
		CableCar.tick(self, delta)
	# the moving walkway (L'Estacio) and the escalators (Montjuic) move whoever
	# stands on them outright: a push on velocity is eased away by a dog or
	# human standing still
	if conveyor_zone.size.y > 0.0:
		var carry := conveyor_dir * CONV_SPEED
		if conveyor_zone.has_point(dog.global_position):
			dog.move_and_collide(carry * delta)
			# a ride counts from getting on near one end to off at the other
			if walkway_from == INF:
				walkway_from = dog.global_position.y
			elif walkway_from > conveyor_zone.end.y - 120.0 and dog.global_position.y < conveyor_zone.position.y + 40.0:
				walkway_rides += 1
				walkway_from = -INF
				combo.add("WALKWAY", 4)
				float_text(dog.global_position + Vector2(0, -26), "ALL THE WAY!", Color(0.8, 0.95, 1.0))
		else:
			walkway_from = INF
		if conveyor_zone.has_point(human.global_position):
			human.move_and_collide(carry * delta)
	if auto_walk:
		_auto_drive(delta)
		_watch_stall(delta)
	dog.tick(delta)
	human.tick(delta)
	_prof("dog, owner, drive")
	# the human owns the retractable leash: length changes on their whim
	# ("click!" event), never the dog's
	_tick_reel_length(delta)
	# Dynamic NPC-rope obstacles must be current before the player leash
	# solve; a post-solve feed left the hero rope one frame stale.
	_refresh_pair_obstacles()
	_prof("pair obstacles")
	_apply_leash(delta)
	_prof("leash solve")
	if phase != "freedom":
		_lanes(delta)
		_vlane(delta)
		_prof("lanes")
	_squirrels(delta)
	if rambla():
		_tick_rambla(delta)
	if crowded():
		_tick_crowd(delta)
	_prof("critters")
	_temptation(delta)
	_prof("temptation")
	_offpath(delta)
	_prof("offpath")
	_greetings()
	_prof("greetings")
	_pairs(delta)
	_prof("pairs")
	_hazards(delta)
	_prof("hazards")
	_pickups(delta)
	_prof("pickups")
	_bodily(delta)
	_prof("bodily")
	for i in range(bag_flights.size() - 1, -1, -1):
		var f: Dictionary = bag_flights[i]
		f.t += delta / 0.45
		if f.t >= 1.0:
			var to: Vector2 = f.to
			bag_flights.remove_at(i)
			on_business_bagged(to)
	_prof("bag flights")
	if not cameras.is_empty() or not lasers.is_empty():
		_stealth(delta)
		_prof("stealth")
	if phase == "freedom":
		_romp(delta)
		_neighbour_fetch()
		freedom_games_tick(delta)
	elif phase == "home" and chase_active:
		_chase(delta)
	_prof("romp, chase")
	_check_goals()
	_prof("goals")
	_progress(delta)
	_prof("progress")
	combo.tick(delta)
	challenge.tick(delta)
	Tips.tick(self, delta)
	_prof("combo, challenge")
	owner_news_cd = maxf(0.0, owner_news_cd - delta)
	# the banner shows live countdowns (slack left, fetch timer, chase), and
	# _update_hud is otherwise event-driven, so those would sit frozen
	if call_active or chase_active or phase == "freedom":
		_update_hud()
		_prof("hud")
	_tick_mood(delta)
	_prof("mood")
	_tick_teeter(delta)
	_prof("teeter")
	if tutorial_mode:
		_tick_tutorial(delta)
		_update_tut_card()
	if phase != "freedom":
		_tick_grind(delta)
		_tick_call(delta)
		_tick_vault(delta)
		_prof("grind, call, vault")
	_update_combo_hud()
	_update_challenge_hud()
	goals_peek = maxf(0.0, goals_peek - delta)
	vault_recent = maxf(0.0, vault_recent - delta)
	shake_t = maxf(0.0, shake_t - delta * 2.5)
	prize_glow += delta * 4.0
	_scent_cache_t = maxf(0.0, _scent_cache_t - delta)
	if freedomlayer != null:
		freedomlayer.tick(cam.position)
		_prof("rest")


func _prof(tag: String) -> void:
	if not _prof_on:
		return
	var now := Time.get_ticks_usec()
	if tag != "":
		prof_us[tag] = int(prof_us.get(tag, 0)) + (now - _prof_t)
	_prof_t = now


# The menu screens by name, for screenshots: each is left as pressing
# through the title would leave it.
func _shot_menu(which: String) -> void:
	match which:
		"walk", "details", "shop", "progress":
			menu_step = 2 if which == "details" else 1
			Game.menu_step = menu_step
			_apply_menu_step()
			if which == "shop":
				MenuFlow.open_shop(self)
			elif which == "progress":
				MenuFlow.open_progress(self)
		"pause":
			_skip_title()
			MenuFlow.open_pause(self)
		"walkcard":
			_skip_title()
			MenuFlow.open_pause(self)
			MenuFlow.open_walk_card(self)
		"confirm":
			_skip_title()
			MenuFlow.open_pause(self)
			MenuFlow.open_confirm(self, "exit")
		"first":
			# the title's first-walk question, as a new player sees it
			MenuFlow.open_confirm(self, "first")
		"basics":
			# the tutorial's halfway card (use with --level=tutorial)
			_skip_title()
			MenuFlow.open_basics(self)
		"notice":
			_skip_title()
			_death("OFF THE EDGE\n\nShe went over, and your human went with her.", "edge")


# Straight into the walk, as if SPACE had been pressed on the title. For the
# capture and soak modes, which exist to get past the menu.
func _skip_title() -> void:
	started = true
	frozen = false
	_apply_menu_step()


func _tick_soak() -> void:
	_soak_frames += 1
	if _soak_frames == 2:
		_skip_title()
		_soak_t0 = elapsed
		_soak_last_mood = mood.active
		return
	if _soak_t0 < 0.0:
		return
	var ran := elapsed - _soak_t0
	# frozen after the start means the walk ended on its own: a game-over or
	# the finish. Report what happened up to there rather than hang.
	var ended := ""
	if frozen:
		ended = "finish" if finished else ("phone" if phone_hp <= 0 else "gameover")
		if ended == "gameover" and msg_label != null:
			print("SOAK gameover: %s" % msg_label.text.get_slice("\n", 0))
	if ran < _soak_secs and ended == "":
		return
	var knocks := 0
	for k in _soak_knocks:
		knocks += int(_soak_knocks[k])
	var moods := 0
	for m in _soak_moods:
		moods += int(_soak_moods[m])
	var vs := get_viewport_rect().size
	print("SOAK level=%s size=%dx%d secs=%.1f knocks=%d moods=%d cracks=%d ended=%s by_cause=%s by_mood=%s" % [
		lvl, int(vs.x), int(vs.y), ran, knocks, moods, _soak_cracks, ended if ended != "" else "no",
		JSON.stringify(_soak_knocks), JSON.stringify(_soak_moods)])
	_soak_secs = 0.0
	get_tree().quit()


func _process(_delta: float) -> void:
	Sfx.music_tick(_music_cue(), _music_next(), started and paused, started and not frozen)
	if _soak_secs > 0.0:
		_tick_soak()
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
					"prompt": "press  {restart}  for another walk",
				}
				results_card.visible = true
				goals_card.visible = false
				panel.visible = false
				return
			if "--shot-settings" in OS.get_cmdline_user_args():
				_open_settings_from_menu()
				return
			# --shot-title leaves the menu up instead of skipping it, so the
			# walk-select screen and the name chalked on the pavement can be
			# reviewed. Everything else about --shot exists to get PAST this.
			if "--shot-title" in OS.get_cmdline_user_args():
				return
			# --shot-menu=walk|details|shop|progress|pause|walkcard|confirm|first|basics|notice opens that screen
			for a in OS.get_cmdline_user_args():
				if a.begins_with("--shot-menu="):
					_shot_menu(a.substr(12))
					return
			_skip_title()
			# --shot-y=N starts the pair at that point down the walk, so one
			# stretch of a level can be photographed without walking there
			for a in OS.get_cmdline_user_args():
				if a.begins_with("--shot-y="):
					var sy := float(a.substr(9))
					var se := walk_edges(sy)
					var scx := (se.x + se.y) * 0.5
					# --shot-x=N puts the pair at that x instead of mid-walk, to
					# frame something at the side of the path
					for a2 in OS.get_cmdline_user_args():
						if a2.begins_with("--shot-x="):
							scx = float(a2.substr(9))
					dog.global_position = Vector2(scx + 30.0, sy - 60.0)
					human.global_position = Vector2(scx - 20.0, sy + 40.0)
					leash.resnap()
					cam.position = dog.global_position
					# everything world-space is drawn for where the camera WAS:
					# redraw it all here, or the shot shows the start line's
					# ground under this stretch's props
					queue_redraw()
					edge_layer.queue_redraw()
					_edge_drawn_y = cam.position.y
					if verge_layer != null:
						verge_layer.queue_redraw()
						_verge_drawn_y = cam.position.y
			# --shot-zoom=Z magnifies the shot Z times, to judge how a prop or a
			# person is drawn: the play zoom is too far out to tell; and
			# --shot-cam=X,Y points the camera there instead of at the pair
			for a in OS.get_cmdline_user_args():
				if a.begins_with("--shot-zoom="):
					cam.zoom *= float(a.substr(12))
				elif a.begins_with("--shot-cam="):
					var xy := a.substr(11).split(",")
					shot_cam = Vector2(float(xy[0]), float(xy[1]))
					queue_redraw()
					edge_layer.queue_redraw()
					_edge_drawn_y = shot_cam.y
					if verge_layer != null:
						verge_layer.queue_redraw()
						_verge_drawn_y = shot_cam.y
			# --shot-home turns the pair for home there, so a chase can be
			# photographed without walking the whole way out first
			if "--shot-home" in OS.get_cmdline_user_args():
				dog.global_position.y = human.global_position.y + 100.0
				leash.resnap()
				_enter_home()
		if _shot_frames > _shot_at:
			_shot_done = true
			# --shot-out=PATH writes somewhere other than user://shot.png, so a
			# sweep can keep every shot; --shot-quit exits once the PNG is on
			# disk instead of leaning on --quit-after
			var out := "user://shot.png"
			for a in OS.get_cmdline_user_args():
				if a.begins_with("--shot-out="):
					out = a.substr(11)
			var img := get_viewport().get_texture().get_image()
			var err := img.save_png(out)
			if err != OK:
				push_error("SHOT failed to write %s (error %d)" % [out, err])
			else:
				print("SHOT saved to %s" % out)
			if "--shot-quit" in OS.get_cmdline_user_args():
				get_tree().quit(0 if err == OK else 1)
	# while the intro plays the title screen waits: the key that skips the
	# intro must not also start a walk, restart, or toggle the music
	if intro_playing:
		return
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
	if started and paused:
		MenuFlow.tick_pause(self)
		return
	if started and frozen:
		# a result, a game-over or the daily card: the walk has stopped
		if finished and Game.daily and not daily_copied and daily_share != "" and Input.is_action_just_pressed("share"):
			DisplayServer.clipboard_set(daily_share)
			daily_copied = true
			msg_label.text += "\nCopied. Paste it anywhere."
			return
		if MenuFlow.tick_end(self):
			return
	elif Input.is_action_just_pressed("restart"):
		# R mid-walk starts it again; on the title it just reloads
		if started:
			MenuFlow.restart_walk(self)
		else:
			get_tree().reload_current_scene()
		return
	if started and not frozen and Input.is_action_just_pressed("pause"):
		MenuFlow.open_pause(self)
		return
	if not started and MenuFlow.tick_title(self):
		return
	var target_y := (dog.global_position.y + human.global_position.y) / 2.0 - 60.0
	if phase == "freedom":
		target_y = dog.global_position.y  # owner is parked; follow the dog
	elif phase == "home" and chase_sweeper != null:
		target_y -= chase_lean
	var cx_want := _cam_x()
	if cam_x_now > 1e8:
		cam_x_now = cx_want
	cam_x_now = lerpf(cam_x_now, cx_want, 1.0 - exp(-CAM_X_EASE * get_process_delta_time()))
	cam.position = Vector2(cam_x_now, target_y)
	if shot_cam.x < INF:
		cam.position = shot_cam
		cam.reset_smoothing()
	if shake_t > 0.0:
		cam.offset = Vector2(_shake_rng.randf_range(-1, 1), _shake_rng.randf_range(-1, 1)) * 9.0 * shake_t
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
	# how the walk feeds her moods and where they go: systems/mood_wiring.gd
	MoodWiring.tick(self, delta)


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
	feed.flash(line)


func _apply_leash(delta: float) -> void:
	_leash_tug(delta)
	# The two ways an orbit ends, as one-shots, consumed once the tug above has
	# had its frame - on EVERY path through it, including the early ones (no
	# leash at all, a slack rope, degenerate tangents). A flag that survives the
	# frame it was raised on is paid out twice, or shields her from a tug she
	# should feel; a flag the early returns swallow is never paid out at all.
	if human.whirl_bailed:
		# an abandoned orbit is not a fling: no score, no sfx, just enough
		# slip left for her to stagger clear of the coil
		human.whirl_bailed = false
		if not leash.detached:
			leash.free_slip_t = maxf(float(leash.free_slip_t), WHIRL_SLIP_BAIL)
	if human.just_flung:
		human.just_flung = false
		flings_done += 1
		# the two moves now CHAIN: wind him up with a carve, then let go
		if vault_recent > 0.0:
			bones += 8
			combo.add("SLINGSHOT", 8)
			float_text(human.global_position + Vector2(0, -34), "slingshot! +8",
				Color(1.0, 0.86, 0.5))
			vault_recent = 0.0
		Sfx.play("fling")
		combo.add("FLING", 8)
		if not leash.detached:
			# a fresh fling must never be arrested by a residual wrap
			leash.free_slip_t = 1.2


func _leash_tug(delta: float) -> void:
	# The rope itself (leash.gd) is the constraint. Here: run the rope
	# physics, then turn its stretch into tug-of-war forces. One tension,
	# applied to each end inversely to effective mass along the rope's end
	# tangent - so a wound-up human is pulled around the pole in an arc.
	# The human is ~4x the dog, so raw pulls yank the DOG around; the dog
	# wins by bracing (plant), winding poles (the coil grips and shields
	# both ends from raw tension while geometry still constrains), timing.
	human.strain = false
	dog.dragged = false
	dog.drag_amt = 0.0
	_tick_signs(delta)
	if leash.detached:
		# off leash during the freedom romp. A window left standing here would
		# telegraph rings for an orbit that is not coming, and refuse her a
		# vault for as long as it stood.
		_disarm_whirl()
		return
	leash.tick(delta)
	# The whirl manages its own release (aimed at the dog); no early exit, or
	# the launch direction would be random. `whirling` means the owner's
	# motion is the orbit's to choreograph, and that includes the frame an
	# orbit is given up on. human.tick runs BEFORE this, so a timeout or a
	# pole that stopped being reachable has already put her in a stumble by
	# now: raw forces and the geometry cap must still skip her on that frame,
	# or the way out gets exactly the yank the orbit was shielding her from.
	var whirling: bool = human.is_whirling() or human.whirl_bailed
	if human.is_whirling():
		# the choreographed unwind must never be arrested by rope grip
		leash.free_slip_t = WHIRL_SLIP
		# There is no wrong-way correction: the direction was committed from
		# the rope's own human-end geometry at arming and an orbit in flight
		# cannot change it. What CAN go wrong is the orbit pole turning out
		# not to be a pole, and orbiting a cafe table unwinds nothing.
		if not leash.is_real_pole(human.whirl_pole):
			human.bail_whirl()
	var used: float = leash.used_length()
	var excess := used - leash_len
	leash.taut = excess > 0.0
	if excess <= 0.0:
		_disarm_whirl()
		return
	var h_dir: Vector2 = leash.human_pull_dir()
	var d_dir: Vector2 = leash.dog_pull_dir()
	if h_dir == Vector2.ZERO or d_dir == Vector2.ZERO:
		_disarm_whirl()
		return
	human.notify_strain()
	# the tug eases in over the leash's onset band: force, separation damping
	# and how much of the dog's control the leash takes all follow one amount
	var tight: float = leash.taut_amount(used / maxf(leash.rest_len, 1.0))
	dog.dragged = not dog.planted
	dog.drag_amt = tight if dog.dragged else 0.0
	# Only static wraps (poles/furniture) shield/anchor. Dynamic leash
	# tangles must not borrow pole-vault semantics.
	var shield := 1.0 / (1.0 + 0.3 * float(leash.static_contacts))
	var dog_m := DOG_MASS
	if dog.planted:
		dog_m *= PLANT_GRIP_ICE if dog.ice else (PLANT_GRIP_WET if dog.slick else PLANT_GRIP)
	elif dog.input_active:
		dog_m *= 2.0
	var human_m := HUMAN_MASS * (2.0 if human.is_fallen() else 1.0)
	var base_tension := minf(leash.tension_force(excess, LEASH_K), 1600.0)
	# pulley: with the rope wound and the dog working its end, the pole
	# redirects and amplifies the pull on the human continuously - not
	# only during the whirl. Wraps still shield the DOG from raw yanks.
	# turning round poles and furniture only: draped over another walker's
	# rope is a tangle, and a tangle does not get the pole's pulley
	var wind_turns := absf(leash.static_winding())
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
		# and what they make of it: led by a steady pull, worn down by a hard
		# one (human.gd, the leash conversation)
		human.feel_pull(h_dir, base_tension * tight)
	if not dog.planted:
		dog.velocity += d_dir * (base_tension * shield / dog_m) * delta
	# damp separating components so neither end bungees
	var sep_h := human.velocity.dot(-h_dir)
	if sep_h > 0.0 and not whirling:
		human.velocity += h_dir * sep_h * minf(5.0 * delta, 1.0) * tight
	var sep_d := dog.velocity.dot(-d_dir)
	if sep_d > 0.0 and not dog.planted:
		dog.velocity += d_dir * sep_d * minf(3.0 * delta, 1.0) * tight
	# hard cap: geometry always wins. Corrections follow the rope tangents
	# (unshielded), which is what whips a wound human along the arc.
	var cap := leash_len * (LEASH_STRETCH_CAP - 1.0)
	if excess > cap:
		var over := excess - cap
		var w_d := (1.0 / dog_m) / (1.0 / dog_m + 1.0 / human_m)
		var yank_speed := maxf(human.velocity.dot(-h_dir), 0.0)
		dog.move_and_collide(d_dir * over * w_d)
		if dog.planted:
			_skid(d_dir, over * w_d)
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
	# The condition must hold for WHIRL_ARM_T, and the direction is decided
	# over that same window.
	var armed := false
	if not whirling and not human.is_fallen() and excess > WHIRL_ARM_EXCESS:
		# WHIRL_ARM_WIND covers the 270-degree partial wind that used to jam
		# awkwardly without ever whirling
		if absf(leash.winding()) > WHIRL_ARM_WIND and absf(leash.human_end_winding()) > WHIRL_ARM_END_WIND:
			# the pole the rope is actually wound on at the owner's end - not
			# merely the nearest one - and a real pole: a café table or a
			# chair is not something anyone swings round, and orbiting the
			# wrong thing never unwinds the rope
			var wp := Vector2(INF, INF)
			if leash.human_contact_is_pole and leash.human_contact_pole.distance_to(human.global_position) < WHIRL_ARM_RANGE:
				wp = leash.human_contact_pole
			if wp.x < INF:
				armed = true
				whirl_arm += delta
				# The coil beside THIS pole at her end, signed, every frame of
				# the window - not the whole rope's winding, which reads the
				# dog's coil too and would size an orbit that keeps going after
				# hers is spent and winds it up the other way. Added up so that
				# no one frame of a rope mid-solve decides either how far she
				# goes round or which way; _commit_whirl settles both from the
				# average, once, for good.
				whirl_coil_acc += leash.coil_winding(wp)
				whirl_arm_n += 1
				if whirl_arm >= WHIRL_ARM_T:
					_commit_whirl(wp, whirl_coil_acc / float(maxi(whirl_arm_n, 1)))
					armed = false
	if not armed:
		_disarm_whirl()


# Which way round, and how far, from the coil averaged over the arming window:
# the rope's own probe, a tiny virtual step each way against that average, and
# then the same average for the length. A window that cancels has no opinion to
# give, and a direction is not picked out of the air: she keeps going the way she
# is already travelling round the pole, for the shortest orbit there is.
func _commit_whirl(pole: Vector2, coil: float) -> void:
	Tips.show(self, "whirl")
	var dir: float = leash.unwind_bias_of(coil)
	if dir == 0.0:
		dir = human.orbit_sense(human.global_position - pole, human.velocity)
	human.start_whirl(pole, dir, absf(coil) / TAU)


# Nothing held over from an arming window that came to nothing, or the next one
# decides its way round and its length partly from a rope that has moved on.
func _disarm_whirl() -> void:
	whirl_arm = 0.0
	whirl_coil_acc = 0.0
	whirl_arm_n = 0


# how far into the arming window a whirl is, 0 to 1: what the owner's
# anticipation is drawn from (entities/human.gd)
func whirl_arm_amount() -> float:
	return clampf(whirl_arm / WHIRL_ARM_T, 0.0, 1.0)


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
	b.set_script(load("res://entities/bike.gd"))
	b.position = Vector2(-250.0 if dir > 0 else 1530.0, y)
	b.z_index = 12
	add_child(b)
	b.setup(self, dog, human, Vector2(dir * randf_range(480.0, 640.0), 0.0), "bike")


func _vlane(delta: float) -> void:
	# the parallel bike lane: fast commuters hold their line, kids on
	# scooters weave - and sometimes ride on the sidewalk itself
	# only walks with a rider lane: anywhere else the match below has no case
	# and would spawn a motionless rider at x=0, off screen, every few seconds
	if not lvl in VLANE_LEVELS:
		return
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
			# strollers and the occasional delivery scooter, down one of the
			# hall's two aisles, between the wall stalls and the middle blocks
			kid = randf() < 0.75
			speed = randf_range(60.0, 105.0) if kid else randf_range(200.0, 300.0)
			var east := randf() < 0.5
			band_lo = 770.0 if east else 370.0
			band_hi = 910.0 if east else 510.0
			x = randf_range(band_lo, band_hi)
	var b := Node2D.new()
	b.set_script(load("res://entities/bike.gd"))
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
		c.set_script(load("res://entities/squirrel.gd"))
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
		var keets := lvl == "guell"
		var fe := walk_edges(fy)
		# only El Mosaic draws a side, so other walks keep their random sequence
		var west := keets and randf() < 0.5
		for i in range(6 if keets else 5):
			var p := Node2D.new()
			p.set_script(load("res://entities/pigeon.gd"))
			var fx := randf_range(480.0, 820.0)
			if gulls:
				fx = randf_range(120.0, 320.0) if randf() < 0.7 else randf_range(350.0, 470.0)
			elif keets:
				# parakeets feed along the foot of the terrace wall, under the palms
				fx = (fe.x + randf_range(14.0, 60.0)) if west else (fe.y - randf_range(14.0, 60.0))
			p.position = Vector2(fx, fy + randf_range(-40.0, 40.0))
			p.z_index = 8
			add_child(p)
			p.setup(self, dog, human, gulls)
			if keets:
				p.make_parakeet(-1.0 if west else 1.0)
	# El Bosc's boars come out of the trees as the stretch comes into view,
	# so the crossing happens on screen
	if lvl == "trail" and not boars_out and not tutorial_mode and cam.position.y < LevelBuild.TRAIL_BOAR_Y + 520.0:
		boars_out = true
		var be := walk_edges(LevelBuild.TRAIL_BOAR_Y)
		var bo := Node2D.new()
		bo.set_script(load("res://entities/boar.gd"))
		bo.z_index = 9
		add_child(bo)
		bo.setup(self, dog, human, LevelBuild.TRAIL_BOAR_Y,
			be.x - LevelBuild.TRAIL_WOOD_OUT + 10.0, be.y + LevelBuild.TRAIL_WOOD_OUT + 60.0)
		feed.say("WILD BOAR! GIVE THEM ROOM", EventFeed.Tone.LOUD)
	while duck_ys.size() > 0 and cam.position.y < duck_ys[0] + 650.0:
		var dy: float = duck_ys.pop_front()
		var ddir := 1.0 if randf() < 0.5 else -1.0
		var start_x := 310.0 if ddir > 0.0 else 970.0
		for i in range(5):
			var d := Node2D.new()
			d.set_script(load("res://entities/duckling.gd"))
			d.position = Vector2(start_x - ddir * i * 17.0, dy + sin(i * 1.7) * 4.0)
			d.z_index = 9
			add_child(d)
			d.setup(self, dog, ddir, i == 0)
	if tutorial_mode:
		return      # the tutorial has only the critters its lessons need
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
	elif lvl == "trail":
		# in the strip of forest floor either side, inside the wood line
		var te := walk_edges(y)
		var into := randf_range(24.0, LevelBuild.TRAIL_WOOD_OUT - 24.0)
		x = (te.x - into) if roll < 0.5 else (te.y + into)
	elif roll < 0.35:
		# open grass now that the dog can roam it
		x = randf_range(150.0, 290.0)
	elif roll < 0.65:
		x = randf_range(sw_r - 60.0, sw_r - 25.0) if lvl == "street" else randf_range(1000.0, 1140.0)
	else:
		# street: the far shoulder, live traffic between; park: far grass
		x = randf_range(BLANE_R + 8.0, SHOULDER_R - 8.0) if lvl == "street" else randf_range(150.0, 290.0)
	var s := Node2D.new()
	s.set_script(load("res://entities/squirrel.gd"))
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


func on_dog_hit(cause := "hit") -> void:
	dog_hits += 1
	if _soak_t0 >= 0.0:
		_soak_knocks[cause] = int(_soak_knocks.get(cause, 0)) + 1
		print("SOAK knock t=%.2f cause=%s dog=%s" % [elapsed - _soak_t0, cause, dog.global_position])
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
			if o.is_in_group("pairs"):
				_greet_pair(o)
			else:
				float_text(op + Vector2(0, -18), "sniff! hi", Color(0.8, 1.0, 0.85))


# what another walker's dog and its owner make of yours coming up to say hello
const GREET_LINES := ["aw, hello", "say hello!", "he loves other dogs", "hi, pup", "go on then"]
const GRUMPY_LINES := ["sorry, he's not keen", "leave it, Bruno", "sorry! he's grumpy", "not today, mate"]


func _greet_pair(pair: Node2D) -> void:
	pair.greet()
	var dp: Vector2 = pair.npc_dog.position
	var op: Vector2 = pair.npc_owner.position
	if bool(pair.grumpy):
		float_text(dp + Vector2(0, -18), "grrr", Color(1.0, 0.7, 0.55))
		float_text(op + Vector2(0, -30), String(GRUMPY_LINES[int(pair.seed_o * 1000.0) % GRUMPY_LINES.size()]), Color(1, 0.92, 0.85), POP_SAY)
	else:
		float_text(dp + Vector2(0, -18), "sniff! hi", Color(0.8, 1.0, 0.85))
		float_text(op + Vector2(0, -30), String(GREET_LINES[int(pair.seed_o * 1000.0) % GREET_LINES.size()]), Color(1, 0.95, 0.9), POP_SAY)


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
			"position": pair_park_spot(existing),
		}
	var occupied := pair_park_slots.values()
	for i in range(PAIR_PARK_SPOTS.size()):
		if i not in occupied:
			pair_park_slots[pair_id] = i
			return {
				"found": true,
				"slot_id": i,
				"position": pair_park_spot(i),
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
	pair.set_script(load("res://entities/otherpair.gd"))
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


# paw furrows a planted dog leaves as the leash hauls her: {"a", "b", "col",
# "w", "t"}, two per stretch, one for each front paw
var skids: Array[Dictionary] = []
var skid_from := Vector2(INF, INF)
var skid_snd_t := 0.0


func _skid(dir: Vector2, step: float) -> void:
	if step < SKID_MIN:
		return
	dog.skid = 1.0
	dog.skid_dir = dir
	# braced: facing the one hauling her, leaning back on the collar
	dog.facing = dog.facing.slerp(dir, 0.3).normalized()
	var at: Vector2 = dog.global_position
	if skid_from.x == INF or skid_from.distance_to(at) > 40.0:
		skid_from = at
	if skid_from.distance_to(at) >= 6.0:
		var look := _skid_look()
		if float(look[1]) > 0.0:
			var off := dir.orthogonal() * 5.0
			for sd: float in [-1.0, 1.0]:
				skids.append({"a": skid_from + off * sd, "b": at + off * sd, "col": look[0], "w": look[1], "t": elapsed})
			while skids.size() > SKID_MAX:
				skids.pop_front()
		skid_from = at
	if elapsed >= skid_snd_t:
		skid_snd_t = elapsed + 0.3
		Sfx.play("hiss", 0.55, -16.0)


# what her paws dig into: [colour, width]; water takes no marks
func _skid_look() -> Array:
	if dog.ice:
		return [Color(0.60, 0.66, 0.80, 0.6), 5.0]
	match dog.surface:
		Surfaces.S.SAND:
			return [Color(0.52, 0.40, 0.26, 0.45), 4.5]
		Surfaces.S.MUD:
			return [Color(0.22, 0.15, 0.10, 0.55), 5.0]
		Surfaces.S.GRASS:
			return [Color(0.38, 0.27, 0.16, 0.5), 4.0]
		Surfaces.S.WATER:
			return [Color(), 0.0]
	return [Color(0.08, 0.08, 0.08, 0.22), 2.5]


func _draw_skids(vt: float, vb: float) -> void:
	if skids.is_empty():
		return
	while not skids.is_empty() and elapsed - float(skids[0]["t"]) > SKID_LIFE:
		skids.pop_front()
	var b := ShapeBatch.new()
	for sk: Dictionary in skids:
		var a: Vector2 = sk["a"]
		if a.y < vt - 40.0 or a.y > vb + 40.0:
			continue
		var c: Color = sk["col"]
		c.a *= clampf(1.0 - (elapsed - float(sk["t"])) / SKID_LIFE, 0.0, 1.0)
		b.line(a, sk["b"], c, float(sk["w"]))
	b.flush(_wc)


func _refresh_pair_obstacles() -> void:
	# Called before the player leash solve. Clears stale dynamic contacts and
	# re-feeds from each visible pair whose rope bounds overlap ours.
	leash.dynamic_obstacles.clear()
	if tutorial_mode or not is_inside_tree():
		return
	# a seller on the move with the bundle snags the rope like another lead
	if rambla():
		for bl: Dictionary in blankets:
			if bundle_moving(bl):
				leash.dynamic_obstacles.append(seller_at(bl))
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
	# a pinned patch stands where it was put (a sandpit on the lawn); the rest
	# sit across the path wherever the path is at their height
	if pt.has("pin"):
		return pt["pin"]
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
		_wc.draw_circle(mid + Vector2(gv.x, gv.y) * Vector2(rx, ry), 1.5 + gv.z * 1.5,
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
	draw_patch(_wc, pt, Color(0.30, 0.28, 0.26, 0.95))
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
			_wc.draw_colored_polygon(
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
	_wc.draw_colored_polygon(poly, col)


# MUD THAT READS AS MUD: wet, rutted, holding water. Two ruts curving through
# it where wheels and boots have gone, little pools sitting in its hollows
# with the sky in them, a wet sheen on the lit side, and a few suction rings.
# One batch, a handful of shapes, and only for patches on screen.
func _draw_mud_detail(pt: Dictionary, base: Color) -> void:
	var b := ShapeBatch.new()
	var mid := patch_centre(pt)
	var rx := float(pt["rx"])
	var ry := float(pt["ry"])
	var sd := float(pt["seed"])
	var rut := Color(base.r * 0.55, base.g * 0.55, base.b * 0.55, 0.7)
	var ridge := Color(minf(base.r * 1.25, 1.0), minf(base.g * 1.22, 1.0), minf(base.b * 1.18, 1.0), 0.45)
	for side: float in [-1.0, 1.0]:
		var prev := Vector2(INF, INF)
		for k in range(7):
			var f := float(k) / 6.0
			var q := mid + Vector2(side * rx * 0.22 + sin(f * PI + sd) * rx * 0.08, lerpf(-ry * 0.82, ry * 0.82, f))
			if prev.x < INF:
				b.line(prev, q, rut, 4.5)
				b.line(prev + Vector2(-2.2, 0.0), q + Vector2(-2.2, 0.0), ridge, 1.2)
			prev = q
	# brown water standing in the hollows: flat, dark, a thin glint of sky on
	# the far edge (round grey discs read as stones)
	for i in range(3):
		var a := sd * 2.1 + float(i) * 2.3
		var pp := mid + Vector2(cos(a) * rx * 0.42, sin(a) * ry * 0.4)
		var pw := 9.0 + fmod(sd * 3.7 + float(i), 1.0) * 9.0
		var pool := PackedVector2Array()
		for k in range(12):
			var t := TAU * float(k) / 12.0
			pool.append(pp + Vector2(cos(t) * pw * (1.0 + 0.15 * sin(t * 3.0 + sd)), sin(t) * pw * 0.45))
		b.polygon(pool, Color(base.r * 0.62, base.g * 0.62, base.b * 0.66, 0.9))
		b.line(pp + Vector2(-pw * 0.5, -pw * 0.22), pp + Vector2(pw * 0.3, -pw * 0.3), Color(0.78, 0.84, 0.88, 0.40), 1.5)
	# the wet sheen on the side the light comes from
	b.circle(mid + LIGHT * rx * 0.35, minf(rx, ry) * 0.36, Color(1.0, 1.0, 1.0, 0.06))
	# suction rings where something sank in and came out again
	for i in range(2):
		var a2 := sd * 5.3 + float(i) * 3.1
		var sp := mid + Vector2(cos(a2) * rx * 0.6, sin(a2) * ry * 0.55)
		b.circle(sp, 4.5, Color(base.r * 0.6, base.g * 0.6, base.b * 0.6, 0.7))
		b.circle(sp, 2.6, base)
	b.flush(_wc)


func draw_patch(c: Object, pt: Dictionary, col: Color,
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
	if z.has("band"):
		return band_has_point(z["band"] as Dictionary, p)
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


func draw_band(c: Object, band: Dictionary, col: Color, step := 40.0) -> void:
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


# The strips either side of the walk on a built walk: grass, or a sidewalk
# with its paving joints, from the paving edge out to the building line.
# Sampled down the visible stretch, so they follow the path where it bends.
func _draw_strips(vt: float, vb: float, grass: Color) -> void:
	var y0 := maxf(vt - 60.0, GATE_Y - 40.0)
	var y1 := minf(vb + 60.0, START_Y + 560.0)
	for side: float in [-1.0, 1.0]:
		var kind := strip_kind_l if side < 0.0 else strip_kind_r
		if kind == "none":
			continue
		var col := grass if kind == "grass" else (COL_ROAD if kind == "road" else STRIP_SIDEWALK)
		var inner := PackedVector2Array()
		var outer := PackedVector2Array()
		var y := y0
		while true:
			var yy := minf(y, y1)
			var e := walk_edges(yy)
			var f := frontage(yy)
			inner.append(Vector2(e.x if side < 0.0 else e.y, yy))
			outer.append(Vector2(f.x if side < 0.0 else f.y, yy))
			if yy >= y1:
				break
			y += 40.0
		var poly := PackedVector2Array(inner)
		for i in range(outer.size() - 1, -1, -1):
			poly.append(outer[i])
		_wc.draw_colored_polygon(poly, col)
		if kind == "road":
			# a traffic lane with a narrow pavement along the building fronts:
			# the dashes down the lane, the kerb both sides of it
			var pave := PackedVector2Array()
			var lane_kerb := PackedVector2Array()
			for i in range(outer.size()):
				lane_kerb.append(outer[i] - Vector2(side * ROAD_PAVEMENT, 0.0))
			for q in lane_kerb:
				pave.append(q)
			for i in range(outer.size() - 1, -1, -1):
				pave.append(outer[i])
			_wc.draw_colored_polygon(pave, STRIP_SIDEWALK)
			for i in range(inner.size() - 1):
				_wc.draw_line(inner[i], inner[i + 1], STRIP_KERB, 3.0)
				_wc.draw_line(lane_kerb[i], lane_kerb[i + 1], STRIP_KERB, 3.0)
			var dy := floorf(y0 / 70.0) * 70.0
			while dy < y1:
				var mid := (walk_edges(dy).x + frontage(dy).x - ROAD_PAVEMENT) * 0.5 if side < 0.0 \
					else (walk_edges(dy).y + frontage(dy).y + ROAD_PAVEMENT) * 0.5
				_wc.draw_line(Vector2(mid, dy), Vector2(mid, dy + 30.0), COL_STRIPE, 2.0)
				dy += 70.0
		if kind == "sidewalk":
			# paving joints across the sidewalk, every slab
			var jy := floorf(y0 / 48.0) * 48.0
			while jy < y1:
				var e2 := walk_edges(jy)
				var f2 := frontage(jy)
				var a := Vector2(e2.x if side < 0.0 else e2.y, jy)
				var b := Vector2(f2.x if side < 0.0 else f2.y, jy)
				_wc.draw_line(a, b, STRIP_JOINT, 1.5)
				jy += 48.0
			# the kerb along the paving edge
			for i in range(inner.size() - 1):
				_wc.draw_line(inner[i], inner[i + 1], STRIP_KERB, 3.0)


func _on_grass_strip(p: Vector2) -> bool:
	if not built:
		return true
	var e := walk_edges(p.y)
	if p.x >= e.x and p.x <= e.y:
		return false
	var kind := strip_kind_l if p.x < e.x else strip_kind_r
	var f := frontage(p.y)
	return kind == "grass" and p.x > f.x and p.x < f.y


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
	_wc.draw_colored_polygon(poly, col)
	if lvl == "trail":
		_draw_trail_edges(left, right, col)
		return
	# the kerbs, following the same two edges the surface test uses
	for pts: PackedVector2Array in [left, right]:
		for i in range(pts.size() - 1):
			_wc.draw_line(pts[i], pts[i + 1], COL_SEAM, 3.0)


# A forest trail has no kerb: it frays into the floor. A darker trodden band
# just inside each edge, clods of loose dirt spilling outward, and now and
# then a root running across the edge. Everything is placed on a grid fixed
# in the world (never on the camera-relative samples the ribbon uses, which
# moved with every pixel of scrolling and re-rolled the whole edge), so the
# same trail frays the same way every frame. Clods are hexagons, not circles:
# one batch, a few hundred triangles at a typical view.
const TRAIL_FRAY_STEP := 48.0


func _draw_trail_edges(left: PackedVector2Array, right: PackedVector2Array, col: Color) -> void:
	if left.size() < 2:
		return
	var b := ShapeBatch.new()
	var worn := Color(col.r * 0.86, col.g * 0.86, col.b * 0.86, 0.6)
	var loose := Color(col.r * 0.92, col.g * 0.9, col.b * 0.86, 0.85)
	var root := Color(0.36, 0.26, 0.17)
	var top: float = left[0].y
	var bot: float = left[left.size() - 1].y
	var y := floorf(top / TRAIL_FRAY_STEP) * TRAIL_FRAY_STEP
	while y < bot:
		var e0 := walk_edges(y)
		var e1 := walk_edges(y + TRAIL_FRAY_STEP)
		for side in range(2):
			var out := -1.0 if side == 0 else 1.0
			var a := Vector2(e0.x if side == 0 else e0.y, y)
			var c := Vector2(e1.x if side == 0 else e1.y, y + TRAIL_FRAY_STEP)
			b.line(a + Vector2(-out * 7.0, 0.0), c + Vector2(-out * 7.0, 0.0), worn, 10.0)
			for k in range(2):
				var q := a.lerp(c, (float(k) + 0.5) / 2.0)
				var h := _cell01(q.y, float(side) * 31.0)
				var rr := 6.0 + h * 5.0
				var cq := q + Vector2(out * (2.0 + h * 6.0), 0.0)
				var hex := PackedVector2Array()
				for v in range(6):
					hex.append(cq + Vector2.from_angle(TAU * float(v) / 6.0 + h) * rr)
				b.polygon(hex, loose)
			var hr := _cell01(y, 7.0 + float(side))
			if hr < 0.22:
				# a root across the edge, from the wood into the path
				var rq := a.lerp(c, hr * 4.0)
				b.line(rq + Vector2(out * 26.0, -4.0), rq + Vector2(-out * 18.0, 3.0), root, 3.0)
				b.line(rq + Vector2(out * 6.0, -1.0), rq + Vector2(-out * 6.0, 9.0), root, 2.0)
		y += TRAIL_FRAY_STEP
	b.flush(_wc)


# Where the buildings start at this point down the walk: x = left building
# line, y = right. Follows the path where it bends. Only meaningful when built.
func frontage(y: float) -> Vector2:
	var e := walk_edges(y)
	return Vector2(e.x - strip_l, e.y + strip_r)


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
				# a mess to carry around, not ground that slows you
				"paint", "fish", "oil", "confetti", "icecream", "puddle": continue
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
	# Only La Rambla has the bike lane; the other walks built on its
	# cross-section have their own strips now (#65).
	if lvl == "street" and p.x >= BLANE_L - 10.0 and p.x <= SHOULDER_R:
		return Surfaces.S.PAVEMENT
	# a sidewalk strip is paving; a grass strip falls through to grass. Only
	# along the walk: the off-leash area past the gate keeps its own ground.
	if built and p.y > GATE_Y:
		var kind := strip_kind_l if p.x < e.x else strip_kind_r
		if kind != "grass":
			return Surfaces.S.PAVEMENT
	# anything else is the green either side, which is now somewhere worth
	# being rather than merely somewhere allowed
	return Surfaces.S.GRASS


# how long a pressed footprint takes to fill back in (s), and how many are kept
const DENT_LIFE := 40.0
const DENT_MAX := 240


func _takes_prints(p: Vector2) -> bool:
	if Game.weather == "snow" and p.y > GATE_Y:
		return true
	if lvl != "beach":
		# a sandpit, wet cement, mud: soft ground takes a print anywhere
		var soft := surface_at(p)
		return soft == Surfaces.S.SAND or soft == Surfaces.S.MUD
	var s := surface_at(p)
	# past the gate is the dog beach, sand from the fence to the water
	if p.y < GATE_Y:
		return s != Surfaces.S.WATER
	return s == Surfaces.S.SAND


func _ground_marks() -> void:
	var dp: Vector2 = dog.global_position
	var s: int = dog.surface
	var speed: float = dog.velocity.length()
	# stepping into water: a ring, whatever the speed
	if s == Surfaces.S.WATER and mark_surface != Surfaces.S.WATER and mark_surface != -1:
		_add_mark({"kind": "ring", "pos": dp, "t": elapsed})
	# into mud at a run: a squelch; into grass, a rustle; onto sand, grit.
	# Quiet, and not more than one a second between them
	if s != mark_surface and mark_surface != -1 and speed > 80.0 and elapsed >= squelch_t:
		match s:
			Surfaces.S.MUD:
				squelch_t = elapsed + 1.0
				Sfx.play("squelch", 1.0, -12.0)
			Surfaces.S.GRASS:
				squelch_t = elapsed + 1.0
				Sfx.play("rustle", 1.0, -18.0)
			Surfaces.S.SAND:
				squelch_t = elapsed + 1.0
				Sfx.play("grit", 1.0, -16.0)
	mark_surface = s
	if speed < 70.0:
		return
	var gap := 22.0 if s == Surfaces.S.GRASS else 18.0
	if mark_last.x < INF and mark_last.distance_to(dp) < gap:
		return
	mark_last = dp
	var ang: float = dog.velocity.angle()
	match s:
		Surfaces.S.GRASS:
			_add_mark({"kind": "flat", "pos": dp, "t": elapsed, "ang": ang})
		Surfaces.S.MUD:
			if speed > 140.0:
				_add_mark({"kind": "splat", "pos": dp, "t": elapsed, "ang": ang})
		Surfaces.S.SAND:
			if speed > 120.0:
				_add_mark({"kind": "grains", "pos": dp, "t": elapsed, "ang": ang})


func _add_mark(m: Dictionary) -> void:
	ground_marks.append(m)
	while ground_marks.size() > MARKS_MAX:
		ground_marks.remove_at(0)


func _draw_ground_marks(vt: float, vb: float) -> void:
	if ground_marks.is_empty():
		return
	var b := ShapeBatch.new()
	var i := 0
	while i < ground_marks.size():
		var m: Dictionary = ground_marks[i]
		var age := elapsed - float(m["t"])
		var life: float = FLAT_LIFE if m["kind"] == "flat" else (RING_LIFE if m["kind"] == "ring" else SPLAT_LIFE)
		if age > life:
			ground_marks.remove_at(i)
			continue
		i += 1
		var p: Vector2 = m["pos"]
		if p.y < vt - 30.0 or p.y > vb + 30.0:
			continue
		var f := 1.0 - age / life
		match String(m["kind"]):
			"flat":
				# two lighter streaks where the blades are pressed flat
				var fwd := Vector2.from_angle(float(m["ang"]))
				var sd := fwd.orthogonal() * 4.0
				for k: float in [-1.0, 1.0]:
					b.line(p + sd * k - fwd * 5.0, p + sd * k + fwd * 5.0, Color(0.70, 0.80, 0.52, 0.30 * f), 3.0)
			"splat":
				# drops thrown out sideways and behind
				var fwd2 := Vector2.from_angle(float(m["ang"]))
				var sd2 := fwd2.orthogonal()
				var spread := 6.0 + (1.0 - f) * 10.0
				for k in range(3):
					var o := sd2 * (float(k) - 1.0) * spread - fwd2 * (4.0 + float(k) * 2.0)
					b.circle(p + o, 2.4, Color(0.30, 0.22, 0.14, 0.8 * f))
			"grains":
				# sand kicked up behind her: no purchase
				var fwd3 := Vector2.from_angle(float(m["ang"]))
				var sd3 := fwd3.orthogonal()
				var fly := 4.0 + (1.0 - f) * 14.0
				for k in range(4):
					var o3 := -fwd3 * (fly + float(k) * 2.5) + sd3 * (float(k) - 1.5) * 3.0 * (1.0 + (1.0 - f))
					b.circle(p + o3, 1.5, Color(0.86, 0.76, 0.54, 0.85 * f))
			"ring":
				var r := 6.0 + (1.0 - f) * 26.0
				var pts := 18
				var prev := p + Vector2(r, 0.0)
				for k in range(1, pts + 1):
					var q := p + Vector2.from_angle(TAU * float(k) / float(pts)) * r
					b.line(prev, q, Color(0.90, 0.95, 1.0, 0.5 * f), 2.0)
					prev = q
	b.flush(_wc)


func _press_dents() -> void:
	if _takes_prints(dog.global_position) and dent_last_dog.distance_to(dog.global_position) > 20.0:
		dent_last_dog = dog.global_position
		var side: Vector2 = dog.facing.orthogonal() * (4.5 if dents.size() % 2 == 0 else -4.5)
		dents.append({"pos": dog.global_position + side, "t": elapsed, "ang": dog.facing.angle()})
	if _takes_prints(human.global_position) and dent_last_human.distance_to(human.global_position) > 32.0:
		dent_last_human = human.global_position
		var hside: Vector2 = human.face_dir.orthogonal() * (7.0 if dents.size() % 2 == 0 else -7.0)
		dents.append({"pos": human.global_position + hside, "t": elapsed, "ang": human.face_dir.angle(), "boot": true})
	while dents.size() > DENT_MAX or (not dents.is_empty() and elapsed - float(dents[0]["t"]) > DENT_LIFE):
		dents.remove_at(0)


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
	_press_dents()
	_ground_marks()
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
			# said first, hauled a moment later, like every owner event
			nag_haul_t = NAG_WARN
	else:
		offpath_t = maxf(0.0, offpath_t - delta)
	if nag_haul_t > 0.0:
		nag_haul_t -= delta
		if nag_haul_t <= 0.0:
			set_leash_target(180.0, true)


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
		"plant": return tut_plant_t >= 1.0
		"pee": return marks.size() >= 1
		"sniff": return sniffs_done >= 1
		"nose": return kebabs_eaten >= 1
		"dig": return digs_done >= 1
		"fling": return flings_done >= 1
		"teeter": return tut_teetered and not teeter.active
		"bag": return poop_state == 2 and not bag_pending
		"bark": return barks_done >= 1
		"turbo": return dog.turbo_active and dog.energy < 0.94
		"grind": return grinds_landed >= 1
		"vault": return vaults_landed >= 1
		"done": return false   # the last card just sees you off
	return false


# Where the owner waits for lesson i: y short of the station, and x by the
# path's edge when the lesson gives a "stand" (INF when it does not, so the
# owner keeps their own place in the weave).
func tut_hold_point(i: int) -> Vector2:
	var st: Dictionary = TutorialSteps.step(i)
	if not bool(st.get("hold", false)):
		return Vector2(INF, -INF)
	var y := float(st["at"]) + TUT_HOLD_BACK
	var side := int(st.get("stand", 0))
	if side == 0:
		return Vector2(INF, y)
	var e := walk_edges(y)
	return Vector2((e.x + TUT_STAND_IN) if side < 0 else (e.y - TUT_STAND_IN), y)


func _tick_tutorial(delta: float) -> void:
	tut_flash = maxf(0.0, tut_flash - delta)
	var st: Dictionary = TutorialSteps.step(tut_step)
	var id := String(st.id)
	hud_point = String(st.get("meter", ""))
	# the owner waits at a lesson that wants them still, just short of it
	var hp := tut_hold_point(tut_step)
	human.tut_hold_y = hp.y
	human.tut_hold_x = hp.x
	# a waiting owner leaves the reel alone at full length: a lesson's target
	# is laid out for the whole leash, and a click to 170 would put it out of reach
	if bool(st.get("hold", false)) and leash_target < LEASH_LENGTH:
		set_leash_target(LEASH_LENGTH)
	if id == "plant" and dog.planted and leash.taut:
		tut_plant_t += delta
	if teeter.active:
		tut_teetered = true
	if id == "":
		return
	# the end, in the dog park: no walk home with nothing left to learn
	if id == "done":
		tut_done_t += delta
		if tut_done_t > 2.5 and not finished:
			_finish_tutorial_walk()
		return
	# skippable, always: a tutorial that traps a player who cannot do the
	# thing is worse than no tutorial at all
	if Input.is_action_just_pressed("share") and id != "done":
		_tut_advance(false)
		return
	if _tut_step_done(id):
		_tut_advance(true)


func _tut_advance(earned: bool) -> void:
	var was := String(TutorialSteps.step(tut_step).id)
	tut_step += 1
	# the basics done: a card offering the first real walk now, or the tricks
	if was == "bag" and not tut_basics_seen:
		MenuFlow.open_basics(self)
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
		body += "        ({skip} to move on)"
	tut_hint.text = Prompts.fill(body)
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


func on_rival_drop(at: Vector2, what: String, msg: String, earned: bool, prop: Dictionary = {}) -> void:
	if what == "":
		return
	if what == "ball" and phase == "freedom" and not romp_done and not is_instance_valid(ball):
		# whatever became of that one, your human has another
		_spawn_romp_ball()
		float_text(human.global_position + Vector2(0, -34), "here, another one!", Color(1, 0.92, 0.8), POP_SAY)
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
	if what == "bone" and not prop.is_empty():
		prop["looted"] = false
		prop["kept"] = true
	else:
		for pp in park_props:
			if String(pp.kind) == "dig" and pp.get("looted", false):
				pp["looted"] = false
				pp["kept"] = true
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
			feed.say("BUSY DOG! %d THINGS  +%d" % [call_haul, bonus], EventFeed.Tone.GOOD)
			_update_hud()
		else:
			feed.say("THE CALL'S OVER", EventFeed.Tone.BAD)


func _tick_grind(delta: float) -> void:
	# A grind is a trick on something built to be ridden (systems/rails.gd):
	# run onto it along its length with the zoomies on and she is up, held to
	# its line; left and right work the balance; it pays by the second and
	# lands when she runs off its end or slows. Bailing costs the trick and
	# the combo but nothing else, because this is a thing you go looking for.
	grind_cd = maxf(0.0, grind_cd - delta)
	if grind.active:
		var r: Dictionary = rails[grind_rail]
		var n: Dictionary = Rails.nearest(r, dog.global_position)
		var dir: Vector2 = n["dir"]
		var along := dog.velocity.dot(dir)
		# held to the rail: only her speed along it is her own
		dog.global_position = n["q"]
		dog.velocity = dir * along
		# Counter-steering, deliberately literal: the stick tilts the balance,
		# so you hold it up by leaning the other way
		var counter: float = -dog.input_dir.dot(Rails.side(dir))
		var res: String = grind.tick(delta, counter)
		var at_end := float(n["s"]) <= 1.0 or float(n["s"]) >= float(n["len"]) - 1.0
		if res == "bailed":
			grind_cd = 0.9
			combo.bail()
			Sfx.play("crack", 1.2, -10.0)
			feed.say("FELL OFF!", EventFeed.Tone.BAD)
			dog.stumble()
		elif at_end or absf(along) < GRIND_SPEED:
			var pts := int(grind.land())
			grind_cd = 0.5
			if pts > 0:
				var trick := String(r["name"])
				bones += int(pts / 4)
				grinds_landed += 1
				combo.add(trick, pts)
				Sfx.play("star", 1.2)
				feed.say("%s!  %d" % [trick, pts], EventFeed.Tone.LOUD)
				_update_hud()
		return
	if grind_cd > 0.0 or dog.is_tumbling() or teeter.active or not dog.turbo_active:
		return
	if dog.velocity.length() < GRIND_SPEED:
		return
	var ri: int = Rails.mountable(self, dog.global_position, dog.velocity)
	if ri < 0:
		return
	grind_rail = ri
	grind.begin()
	Sfx.play("save", 1.35, -10.0)
	feed.say("%s!" % String(rails[ri]["name"]), EventFeed.Tone.LOUD)


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
	Tips.show(self, "teeter")
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
				_death(teeter_msg, "dog_hole")
			else:
				dog.fall_in(teeter_at)


# A lost walk: the card (systems/losses.gd adds how to avoid it next time).
func _death(msg: String, cause := "") -> void:
	MenuFlow.show_notice(self, Losses.card(self, msg, cause))


func _hazards(delta: float) -> void:
	for tw in towels:
		tw.cd = maxf(0.0, float(tw.cd) - delta)
		if tw.cd <= 0.0 and (tw.rect as Rect2).has_point(human.global_position):
			tw.cd = 4.0
			human.bumped((human.global_position - (tw.rect as Rect2).get_center()).normalized())
			float_text(human.global_position, "hey! my towel!", Color(1, 0.85, 0.7), POP_SAY)
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
			float_text(human.global_position, "no no no-", Color(0.7, 0.85, 1.0), POP_SAY)
	# open holes are the TOP tier of danger: falling in ends the walk,
	# full stop. Bumps hurt a little; holes hurt completely.
	# (auto_walk is a test/attract traversal - it is not allowed to die)
	if auto_walk:
		return
	for m in manholes:
		if human.global_position.distance_to(m) < 18.0 and not human.is_fallen():
			_death("YOUR HUMAN WENT DOWN THE MANHOLE\n\nThe phone gets a signal down there.\nThe walk does not.", "manhole")
			return
		# the dog gets a teeter first: a brink is a skill moment, not an
		# instant punishment
		if dog.global_position.distance_to(m) < 22.0:
			_start_teeter("hole", m, "MILLIE WENT DOWN THE MANHOLE\n\nShe is fine. The walk is very over.")
			return
	for c in cellars:
		if c.has_point(human.global_position):
			_death("YOUR HUMAN FELL IN THE CELLAR\n\nRight onto the delivery. You did warn them,\nin the only language you have.", "cellar")
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
				"shrub", "post", "rock", "driftwood", "tyre", "planter", "log":
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
						# the sound of a dog drinking, and a word when she has
						# had a proper one (it was silent, so nobody knew)
						lap_t -= delta
						if lap_t <= 0.0:
							lap_t = 0.32
							Sfx.play("squelch", 1.9, -18.0)
						_praise_drink(pp.pos)
	# the candy you should not have: chocolate is poison to dogs, so
	# wolfing it costs you (and your clean-tummy goal)
	for c in candy:
		if not c.eaten and dog.global_position.distance_to(c.pos) < 26.0:
			c.eaten = true
			candy_eaten += 1
			bones = maxi(0, bones - 3)
			shake_t = maxf(shake_t, 0.4)
			Sfx.play("tangle", 0.7)
			float_text(c.pos, "bleh, not for dogs -3", Color(1, 0.5, 0.45))
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
			_praise_drink(f)
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
	float_text(pos, "bagged, responsibly +2", Color(0.8, 1.0, 0.8))
	_update_hud()


# The off-leash space at the top of the walk. Every level ended in the same
# fenced municipal dog park, which is a big part of why the walks still felt
# like one walk redressed - you always finished in the same field. The beach
# gets a DOG BEACH instead: sand, and a sea you can actually swim in.
const FREEDOM_KINDS := {
	"beach": "beach", "trail": "clearing", "site": "lot", "scrap": "lot",
	"guell": "clearing",
	# the town walks end in a square, the way their gates say
	"market": "placa", "oldtown": "placa", "spook": "placa", "neteja": "placa",
	# the castle's esplanade at the top of the hill
	"montjuic": "placa",
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


const MARKABLE_PARK_KINDS := ["post", "shrub", "log", "rock", "driftwood", "tyre", "planter"]


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
	# the bot has no collision, so round an island (L'Estacio's train, El
	# Parc's lake) it keeps to the owner's side, as human._walk does: aimed
	# at the middle it would walk into the train and wind the rope through
	# the wrap points along its sides
	var dp := dog.global_position
	for isl: Dictionary in islands:
		var ir: Rect2 = isl["rect"]
		if dp.y > ir.position.y - human.ISLAND_LEAD and dp.y < ir.end.y + human.ISLAND_LEAD:
			var here := walk_edges(dp.y)
			var side_x: float = (ir.end.x + here.y) * 0.5 if float(isl["side"]) > 0.0 else (here.x + ir.position.x) * 0.5
			weave = clampf((side_x - dp.x) / 60.0, -1.0, 1.0)
	# L'Estacio's moving walkway carries up the middle: going home the bot
	# walks down beside it, on its human's side, not against it
	if phase == "home" and conveyor_zone.size.y > 0.0 and conveyor_dir.y < 0.0 			and dp.y > conveyor_zone.position.y - 80.0 and dp.y < conveyor_zone.end.y + 40.0:
		var beside_x: float = conveyor_zone.end.x + 70.0 if human.global_position.x >= conveyor_zone.get_center().x 			else conveyor_zone.position.x - 70.0
		weave = clampf((beside_x - dp.x) / 60.0, -1.0, 1.0)
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
	freedom_at = elapsed
	_spawn_romp_ball()
	# other dogs to romp and say hi to (on the sand, not out in the sea)
	var fd_x0 := BEACH_SEA_R + 60.0 if freedom_kind == "beach" else 200.0
	for i in range(3):
		var fd := Node2D.new()
		fd.set_script(load("res://entities/freedog.gd"))
		fd.position = Vector2(randf_range(fd_x0, 1080.0), randf_range(freedom_lo + 40.0, GATE_Y - 60.0))
		fd.z_index = 9
		add_child(fd)
		fd.setup(self, dog, freedom_lo, GATE_Y - 30.0)
	# BRUTUS, the park thief: he turns up on some walks to help himself to
	# whatever you have just earned. Not in the tutorial - a first walk is no
	# place to meet him.
	if not tutorial_mode and randf() < 0.5:
		var rv := Node2D.new()
		rv.set_script(load("res://entities/rival.gd"))
		var rb := _pair_park_bounds()
		rv.position = Vector2(maxf(rb.position.x + 60.0, _dry_x0()), rb.get_center().y)
		rival = rv
		rv.z_index = 9
		add_child(rv)
		rv.setup(self, dog, rb)
		float_text(rv.position, "...oh no. Brutus.", Color(1, 0.85, 0.75), POP_SAY)
	FreedomGames.begin(self)
	feed.say("OFF THE LEASH! GO FETCH", EventFeed.Tone.LOUD)


# The owner's ball. Thrown at the start, and thrown again whenever one is lost
# (Brutus ran off with it, or got it taken back off him: either way he dropped
# it out of play), so a stolen ball never ends fetch for the rest of the visit.
func _spawn_romp_ball() -> void:
	ball = Node2D.new()
	ball.set_script(load("res://entities/ball.gd"))
	ball.z_index = 10
	ball.position = human.global_position
	add_child(ball)
	if freedom_kind == "beach":
		# into the surf, not across a field - window before the first throw
		ball.setup(self, dog, human, freedom_lo, GATE_Y - 30.0, -90.0, BEACH_SEA_R + 240.0)
	else:
		ball.setup(self, dog, human, freedom_lo, GATE_Y - 30.0)


# where dry ground starts across the off-leash space: on the dog beach the
# west of it is sea, and nobody parks, sits or spawns in that
func _dry_x0() -> float:
	return BEACH_SEA_R + 60.0 if freedom_kind == "beach" else 0.0


# a parked pair's spot, moved onto the sand on the dog beach (two of the three
# stood in the sea there)
func pair_park_spot(i: int) -> Vector2:
	if lvl == "beach":
		return BEACH_PAIR_SPOTS[i]
	return PAIR_PARK_SPOTS[i].position


# the dog beach's three: on dry sand, clear of the benches, the owner's bench
# and the shower's trough
const BEACH_PAIR_SPOTS := [Vector2(780.0, GATE_Y - 100.0), Vector2(600.0, GATE_Y - 320.0), Vector2(1040.0, GATE_Y - 120.0)]


func _spawn_wallcats() -> void:
	# perched temptations up both alley walls (El Gotic). They bolt away
	# from the centre when barked at.
	for spot in wallcat_spots:
		var wc := Node2D.new()
		wc.set_script(load("res://entities/wallcat.gd"))
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
		gd.set_script(load("res://entities/guarddog.gd"))
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
	float_text(pos + Vector2(0, -26), "woof woof woof -2", Color(1, 0.5, 0.4))
	_update_hud()


func on_phone_noise(pos: Vector2) -> void:
	# the owner's phone going off: the world's worst stealth partner
	for g in get_tree().get_nodes_in_group("guards"):
		g.hear_noise(pos, 250.0)


func _stealth(delta: float) -> void:
	# sweeping cameras: a vision cone that pans back and forth. On game time,
	# since the sweep decides detection
	var t := elapsed
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
	giver.set_script(load("res://entities/challenger.gd"))
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
			npc_ball.set_script(load("res://entities/ball.gd"))
			npc_ball.z_index = 10
			npc_ball.position = pair.npc_owner.global_position
			add_child(npc_ball)
			npc_ball.setup(self, dog, pair.npc_owner, freedom_lo, GATE_Y - 30.0)
			npc_ball_pair = pair
			float_text(pair.npc_owner.global_position + Vector2(0, -20), "fancy a game?", Color(0.85, 0.95, 1.0), POP_SAY)
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
	float_text(pos, "Tofu's coming home! +15", Color(1, 0.85, 0.7))
	_slowmo()


func freedom_games_tick(delta: float) -> void:
	FreedomGames.tick(self, delta)


# the slope under your human and the dog: 1.0 everywhere but Montjuic
func slope_mult(y: float, fwd_y: float) -> float:
	return Montjuic.slope_mult(self, y, fwd_y)


func dog_slope_mult(y: float, vel_y: float) -> float:
	return Montjuic.dog_slope_mult(self, y, vel_y)


func on_frisbee_caught(air: bool) -> void:
	FreedomGames.on_frisbee_caught(self, air)


func on_frisbee_returned(left: int) -> void:
	FreedomGames.on_frisbee_returned(self, left)


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
	FreedomGames.end(self)
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
	# Brutus too: left behind, he went on stealing bones off-screen all the
	# way home
	if is_instance_valid(rival):
		rival.queue_free()
	rival = null
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
		tf.set_script(load("res://entities/tofu.gd"))
		tf.z_index = 9
		add_child(tf)
		tf.setup(self, dog, spots)
		float_text(spots[0], "Tofu!? she got out again - get her home!", Color(1, 0.85, 0.7), POP_SAY)
	if chase_active:
		HomeChase.begin(self)
	else:
		feed.say("LET'S GO HOME", EventFeed.Tone.PLAIN)


func _chase(delta: float) -> void:
	HomeChase.tick(self, delta)


func _finish_walk() -> void:
	Goals.finish_walk(self)


func complete_tutorial() -> bool:
	return Goals.complete_tutorial(self)


func _finish_tutorial_walk() -> void:
	Goals.finish_tutorial_walk(self)


func _results_rows() -> Array:
	return Goals.results_rows(self)


func results_data() -> Dictionary:
	return results


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
	# the shell game packs up at a bark
	if rambla() and not shell_game.is_empty() and not bool(shell_game["done"]) \
			and (shell_game["pos"] as Vector2).distance_to(pos) < 130.0:
		_bust_shells("a bark")
	# a pickpocket who is only sizing someone up thinks better of it
	for pp in get_tree().get_nodes_in_group("pickpockets"):
		if pp.global_position.distance_to(pos) < pp.BARK_R:
			pp.scare()
	# barking at a boar is a bad idea
	for bo in get_tree().get_nodes_in_group("boars"):
		if bo.global_position.distance_to(pos) < bo.BARK_R:
			bo.provoke()
	# in the scrapyard, YOUR bark is noise too
	for g in get_tree().get_nodes_in_group("guards"):
		g.hear_noise(pos, 230.0)


# A retractable reel winds slack in briskly; against a taut rope its spring
# only draws in gently, so a "click!" never yanks the dog, yet a dog being
# towed along is still slowly brought in (with no give at all the leash only
# ever lengthened, and an idle dog trailed out into the bike lanes). A
# deliberate haul (the nag) pulls a taut rope in at full speed.
const REEL_RATE := 150.0
const REEL_TAUT_RATE := 45.0


func _tick_reel_length(delta: float) -> void:
	var rate := REEL_RATE
	if leash_target < leash_len and not leash_haul and leash.used_length() >= leash_len:
		rate = REEL_TAUT_RATE
	leash_len = move_toward(leash_len, leash_target, rate * delta)
	if is_equal_approx(leash_len, leash_target):
		leash_haul = false
	leash.rest_len = leash_len


func set_leash_target(v: float, haul := false) -> void:
	leash_target = clampf(v, 150.0, 440.0)
	leash_haul = haul


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


# your human ran out of patience and hauled her in: a step back and a short
# leash (human.gd/_correct)
func on_correction(pos: Vector2) -> void:
	Sfx.play("tangle", 0.8, -8.0)
	float_text(pos + Vector2(0, -30), "HEEL", Color(1, 0.85, 0.75))


# ...but she was dug in for it, and it is him that lurches
func on_correction_braced(pos: Vector2) -> void:
	Sfx.play("crack", 0.9, -8.0)
	bones += 3
	combo.add("BRACED", 4)
	float_text(pos + Vector2(0, -30), "held firm! +3", Color(0.7, 1.0, 0.75))
	_update_hud()


func on_stumble_save(pos: Vector2) -> void:
	for b in get_tree().get_nodes_in_group("bikes"):
		if b.global_position.distance_to(pos) < 170.0:
			streak += 1
			saves_done += 1
			bones += streak
			Sfx.play("save", 1.0 + 0.06 * streak)
			combo.add("SAVE", 5)
			float_text(pos + Vector2(0, -30), "nice save +%d" % streak, Color(0.7, 1.0, 0.75))
			_slowmo()
			_update_hud()
			return


func _slowmo() -> void:
	Engine.time_scale = SLOWMO_SCALE
	# 0.35s of real time, measured in scaled game time rather than on the wall
	# clock: a real-time timer let a slow machine spend more game frames in
	# slow motion than a fast one, so the same walk played out differently (#6)
	var t := get_tree().create_timer(SLOWMO_SECS * SLOWMO_SCALE, true, false, false)
	t.timeout.connect(func() -> void: Engine.time_scale = 1.0)


func crack_phone(pos: Vector2) -> void:
	if auto_walk:
		return  # the attract/CI bot carries an unbreakable phone
	Sfx.play("crack", 1.0, -2.0)
	phone_hp -= 1
	if _soak_t0 >= 0.0:
		_soak_cracks += 1
		print("SOAK crack t=%.2f phone_hp=%d" % [elapsed - _soak_t0, phone_hp])
	streak = 0
	shake_t = 1.0
	_update_hud()
	float_text(pos, "PHONE CRACKED", Color(1, 0.45, 0.4))
	if phone_hp > 0:
		Tips.show(self, "crack")
	if phone_hp <= 0:
		_death("PHONE SMASHED\n\nThree cracks and it is gone. Your human is inconsolable,\nand blaming the one member of the household who cannot answer back.", "phone")


func close_call(pos: Vector2) -> void:
	bones += 1
	close_calls += 1
	Sfx.play("save", 1.15)
	combo.add("CLOSE", 2)
	float_text(pos, "close call +1", Color(0.75, 0.9, 1.0))
	_update_hud()


# a world label rises this far (world px) over its life
const FLOAT_RISE := 44.0


var pops: Node2D


# What the world says, at the place it said it: a speech bubble when `kind`
# is POP_SAY, a score chip when the text ends in +N or -N, otherwise a sound
# (world/pops_layer.gd).
func float_text(pos: Vector2, text: String, color: Color = Color.WHITE, kind := -1) -> void:
	if pops == null:
		pops = PopsLayer.new()
		add_child(pops)
	var k: int = kind if kind >= 0 else PopsLayer.classify(text)
	var sz := Vector2(font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x + 30.0, 30.0)
	var at := clear_of_feed(pos + Vector2(-sz.x * 0.5, -40.0), sz) + Vector2(sz.x * 0.5, 30.0)
	pops.add(at, text, color, k)


# A world label at the owner or the dog sits near the middle of the screen,
# which is where the feed is (#66). If the label, over its whole rise, would
# cross a line the feed is showing, it goes up above that line instead.
# at: the label's top-left in world space; size: its size in world px.
func clear_of_feed(at: Vector2, size: Vector2) -> Vector2:
	if feed == null:
		return at
	var xf := get_viewport().get_canvas_transform()
	var zoom := xf.get_scale().y
	var vs := get_viewport_rect().size
	var p := at
	# the lines are stacked downward, so rising above one can land on the one
	# above it: check again until clear
	for _pass in range(4):
		var s := xf * p
		var span := Rect2(s.x, s.y - FLOAT_RISE * zoom, size.x * zoom, (size.y + FLOAT_RISE) * zoom)
		var hit := false
		for r: Rect2 in feed.ink_rects(vs):
			if span.intersects(r):
				p.y -= (span.end.y - r.position.y) / zoom + 4.0
				hit = true
				break
		if not hit:
			break
	return p


# the stand-in canvas for main's own drawing, made fresh each _draw
var _wc: ShapeBatch


func _draw() -> void:
	# --drawcost prints what the world costs to draw. Smooth beats pretty, and
	# every visual pass since v1.31 has been signed off with this number rather
	# than a guess - guessing is how the edge treatment quietly grew to over
	# half the frame.
	var _t0 := Time.get_ticks_usec() if _draw_cost_on else 0
	# Every draw call on main goes through one ShapeBatch standing in for the
	# canvas: runs of shapes become one draw call, same pixels
	# (systems/shape_batch.gd), and anything else passes straight through.
	_wc = ShapeBatch.new(self)
	_draw_world()
	_wc.flush()
	if _draw_cost_on:
		last_draw_us = Time.get_ticks_usec() - _t0
		_draw_us += last_draw_us
		_draw_n += 1
		if _draw_n >= 60:
			print("DRAWCOST %s %dus avg over %d draws" % [lvl, _draw_us / _draw_n, _draw_n])
			_draw_us = 0
			_draw_n = 0


func _draw_world() -> void:
	var top := GATE_Y - 800.0
	# The ground runs well past the start line: the south wall stops the dog
	# at about START_Y + 110, and the camera on her there sees 280 px further
	# down at 1280x720 (375 at 1280x960). Stopping at START_Y + 320 left a
	# strip of bare background along the bottom of the finish (#67).
	var bottom := START_Y + 560.0
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
		_wc.draw_rect(Rect2(-400, ctop, 630, bottom - ctop), Color(0.13, 0.47, 0.60))
		_wc.draw_rect(Rect2(120, ctop, 110, bottom - ctop), Color(0.26, 0.66, 0.70))
		var wt := AnimClock.msec() / 1000.0
		var fy := top + 40.0
		while fy < bottom:
			if fy > vt and fy < vb:
				_wc.draw_line(Vector2(72 + sin(fy * 0.011 + wt * 1.5) * 9.0, fy), Vector2(84 + sin(fy * 0.013 + wt * 1.5) * 9.0, fy + 70.0), Color(1, 1, 1, 0.25), 3.0)
			fy += 150.0
		_wc.draw_rect(Rect2(230, ctop, 150, bottom - ctop), Color(0.88, 0.81, 0.64))
		# THE TIMBER DECK, nearest the sand. These two strips were the wrong way
		# round: the game had pale planks against the beach and a dark red strip
		# inland, where the promenade actually runs a dark reddish-brown WOODEN
		# deck along the sand edge and a pale concrete path with a dashed line
		# behind it. Swapped, so the boardwalk reads as boards.
		_wc.draw_rect(Rect2(380, ctop, 110, bottom - ctop), Color(0.46, 0.26, 0.21))
		# start at the top of the visible window, not the top of the level
		var py := minf(START_Y + 200.0, vb + 22.0 - fmod(vb, 22.0))
		while py > GATE_Y and py > vt - 22.0:
			if py < vb and py > vt:
				# plank ends, running across the walk the way decking is laid
				_wc.draw_line(Vector2(380, py), Vector2(490, py), Color(0.34, 0.19, 0.15), 2.0)
			py -= 22.0
		# the pale concrete path, with the dashed line down the middle of it
		_wc.draw_rect(Rect2(490, ctop, 80, bottom - ctop), Color(0.82, 0.79, 0.73))
		var ddy := minf(START_Y + 200.0, vb + 64.0 - fmod(vb, 64.0))
		while ddy > GATE_Y and ddy > vt - 64.0:
			if ddy < vb and ddy > vt:
				_wc.draw_line(Vector2(530, ddy), Vector2(530, ddy - 26.0), Color(0.97, 0.96, 0.93, 0.8), 3.0)
			ddy -= 64.0
		_wc.draw_rect(Rect2(570, ctop, 410, bottom - ctop), Color(0.79, 0.76, 0.7))
		var sy := minf(START_Y + 200.0, vb + 150.0 - fmod(vb, 150.0))
		while sy > GATE_Y and sy > vt - 150.0:
			if sy < vb and sy > vt:
				_wc.draw_line(Vector2(560, sy), Vector2(980, sy), Color(0.71, 0.68, 0.62), 2.0)
			sy -= 150.0
		_wc.draw_rect(Rect2(980, ctop, 200, bottom - ctop), Color(0.76, 0.72, 0.65))
		# The building strip was at x>=1180, and the camera never sees past
		# x=1140 (zoom 1.28 on a fixed x=640) - so the whole landward side of
		# this walk was being drawn where nobody could look at it. Brought
		# inside the frame.
		_wc.draw_rect(Rect2(1120, ctop, 580, bottom - ctop), Color(0.35, 0.33, 0.31))
		_draw_seafront_works(vt, vb)
		# SQUARE CUT-OUTS in the paving, one under each palm. The promenade's
		# trees are not planted in a verge, they are set into the concrete in
		# orderly openings with a kerb round them, and that grid of squares
		# down the walk is a good part of what the place looks like.
		for ps: Vector2 in palm_spots:
			if ps.y < vt - 60.0 or ps.y > vb + 60.0:
				continue
			var cut := Rect2(ps.x - 27.0, ps.y - 27.0, 54.0, 54.0)
			_wc.draw_rect(cut, Color(0.62, 0.58, 0.50))          # the kerb
			_wc.draw_rect(cut.grow(-5.0), Color(0.40, 0.34, 0.26))  # the soil in it
			_wc.draw_rect(cut, Color(0.34, 0.31, 0.27, 0.55), false, 2.0)
		_wc.draw_line(Vector2(380, bottom), Vector2(380, GATE_Y), Color(0.55, 0.45, 0.32), 3.0)
		_wc.draw_line(Vector2(490, bottom), Vector2(490, GATE_Y), COL_SEAM, 2.0)
		_wc.draw_line(Vector2(570, bottom), Vector2(570, GATE_Y), COL_SEAM, 2.0)
		_wc.draw_line(Vector2(980, bottom), Vector2(980, GATE_Y), COL_SEAM, 2.0)
		for t in tufts:
			if t.y > vt and t.y < vb and t.x > 110.0 and (t.x < 330.0 or t.x > 1000.0) and t.x < 1170.0:
				_wc.draw_circle(t, 4.0, Color(0.78, 0.7, 0.54))
		for ti in range(towels.size()):
			if (towels[ti].rect as Rect2).end.y > vt - 40.0 and (towels[ti].rect as Rect2).position.y < vb + 40.0:
				_draw_towel(towels[ti], ti)
	else:
		var grass := COL_GRASS if lvl == "street" else Color(0.3, 0.45, 0.28)
		var walkway := Color(0.62, 0.55, 0.42)
		if lvl == "street":
			walkway = COL_SIDEWALK
		elif lvl == "market":
			grass = COL_GRASS
			walkway = Color(0.76, 0.73, 0.66)
		elif lvl == "neteja":
			walkway = Color(0.52, 0.50, 0.50)   # a back street's grey setts, still wet
		elif lvl == "guell":
			walkway = Color(0.80, 0.72, 0.56)   # sandy gravel, the park's own ground
		elif lvl == "trail":
			grass = TRAIL_FLOOR
			walkway = TRAIL_DIRT
		elif lvl == "park" or lvl == "barri":
			walkway = Color(0.74, 0.67, 0.53)   # sandy gravel, as the city's parks are
		elif lvl == "scrap":
			grass = Color(0.36, 0.37, 0.25)     # dusty weeds up to the fence
		elif lvl == "montjuic":
			grass = Montjuic.HILL
			walkway = Montjuic.SAULO
		if lvl == "montjuic":
			# the hill only, between its rims: past them, the city below
			Montjuic.draw_hill(self, _wc, vt, vb)
		elif built:
			# only the strips between the paving and the building line: beyond
			# it the edge layer's buildings show (they sit behind the world, so
			# a full-width lawn here hid every one of them, #65)
			_draw_strips(vt, vb, grass)
		else:
			_wc.draw_rect(Rect2(-400, ctop, 2100, bottom - ctop), grass)
		# leaf litter on the forest floor, grass tufts everywhere else
		var tuft_cols: Array = TRAIL_LITTER if lvl == "trail" else [COL_GRASS_DARK]
		for ti in range(tufts.size()):
			var t: Vector2 = tufts[ti]
			if t.y > vt and t.y < vb and _on_grass_strip(t):
				_wc.draw_circle(t, 5.0, tuft_cols[ti % tuft_cols.size()])
		# the walkway: sidewalk downtown, packed dirt in the park
		if edge_nodes.is_empty():
			# A straight corridor, which is every level until one is authored a
			# bend: one rect and two lines, exactly as before. Kept as its own
			# branch rather than folded into the ribbon so that straight levels
			# pay nothing at all for the ability to curve.
			_wc.draw_rect(Rect2(sw_l, GATE_Y - 40.0, sw_r - sw_l, bottom - GATE_Y), walkway)
			_draw_paving(maxf(vt, GATE_Y - 30.0), vb, walkway)
			_wc.draw_line(Vector2(sw_l, bottom), Vector2(sw_l, GATE_Y), COL_SEAM, 3.0)
			_wc.draw_line(Vector2(sw_r, bottom), Vector2(sw_r, GATE_Y), COL_SEAM, 3.0)
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
		_wc.draw_rect(Rect2(BLANE_L, GATE_Y - 40.0, BLANE_R - BLANE_L, bottom - GATE_Y), Color(0.4, 0.31, 0.29))
		_wc.draw_rect(Rect2(BLANE_R, GATE_Y - 40.0, SHOULDER_R - BLANE_R, bottom - GATE_Y), COL_SIDEWALK)
		var dy := minf(START_Y + 200.0, vb + 64.0 - fmod(vb, 64.0))
		while dy > GATE_Y and dy > vt - 64.0:
			if dy < vb and dy > vt:
				_wc.draw_line(Vector2((BLANE_L + BLANE_R) / 2.0, dy), Vector2((BLANE_L + BLANE_R) / 2.0, dy - 26.0), Color(0.85, 0.82, 0.75, 0.5), 2.0)
			dy -= 64.0
		var gy := START_Y - 100.0
		while gy > GATE_Y:
			if gy < vb and gy > vt:
				var cxx := (BLANE_L + BLANE_R) / 2.0 - 14.0
				_wc.draw_circle(Vector2(cxx - 7, gy), 4.0, Color(1, 1, 1, 0.3))
				_wc.draw_circle(Vector2(cxx + 7, gy), 4.0, Color(1, 1, 1, 0.3))
				_wc.draw_line(Vector2(cxx - 7, gy), Vector2(cxx + 7, gy - 6), Color(1, 1, 1, 0.3), 2.0)
			gy -= 600.0
		_wc.draw_line(Vector2(BLANE_L, bottom), Vector2(BLANE_L, GATE_Y), COL_SEAM, 3.0)
		_wc.draw_line(Vector2(BLANE_R, bottom), Vector2(BLANE_R, GATE_Y), COL_SEAM, 2.0)
		_wc.draw_line(Vector2(SHOULDER_R, bottom), Vector2(SHOULDER_R, GATE_Y), COL_SEAM, 3.0)
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
		var wt := AnimClock.msec() / 1000.0
		for i in range(4):
			var wy := pond.position.y + 70.0 + i * 105.0
			_wc.draw_arc(Vector2(pc.x + sin(wt * 0.7 + i) * 40.0, wy), 26.0, PI * 0.15, PI * 0.85, 10, Color(1, 1, 1, 0.14), 2.0)
		# a rowing boat for hire, drifting round the lake
		var bt := AnimClock.msec() / 1000.0
		var bpos := pc + Vector2(sin(bt * 0.11) * pond.size.x * 0.24, cos(bt * 0.08) * pond.size.y * 0.28)
		var bang := Vector2(cos(bt * 0.11) * 0.11, -sin(bt * 0.08) * 0.08).angle()
		_wc.draw_set_transform(bpos, bang + PI / 2.0, Vector2.ONE)
		_wc.draw_colored_polygon(PackedVector2Array([Vector2(0, -24), Vector2(10, -8), Vector2(10, 16),
			Vector2(-10, 16), Vector2(-10, -8)]), Color(0.55, 0.30, 0.22))
		_wc.draw_colored_polygon(PackedVector2Array([Vector2(0, -19), Vector2(7, -7), Vector2(7, 13),
			Vector2(-7, 13), Vector2(-7, -7)]), Color(0.78, 0.66, 0.50))
		_wc.draw_line(Vector2(-18, 2), Vector2(18, 2), Color(0.45, 0.33, 0.22), 2.0)
		_wc.draw_circle(Vector2(0, 4), 5.0, Color(0.30, 0.42, 0.62))
		_wc.draw_circle(Vector2(0, 3), 3.2, Color(0.80, 0.62, 0.48))
		_wc.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# each walk's own ground stops at the gate: past it is the off-leash
	# space, which freedomlayer draws
	var wvt := maxf(vt, GATE_Y - 30.0)
	if lvl == "park":
		_draw_parc(wvt, vb)
	if lvl == "montjuic":
		Montjuic.draw_on_hill(self, _wc, wvt, vb)
		Montjuic.draw_kites(self, _wc, vt, vb)
	if lvl == "barri" and not tutorial_mode:
		_draw_barri(wvt, vb)
	if lvl == "rain":
		_draw_diluvi(wvt, vb)
	if lvl == "station":
		_draw_estacio(wvt, vb)
	if lvl == "scrap":
		_draw_crane(wvt, vb)
		_draw_kennels(wvt, vb)
	if lvl == "oldtown":
		_draw_gotic(wvt, vb)
	if lvl == "market":
		_draw_mercat(wvt, vb)
	if lvl == "spook":
		_draw_castanyada(wvt, vb)
	if lvl == "neteja":
		_draw_neteja(wvt, vb)
	if lvl == "guell":
		_draw_mosaic(wvt, vb)
	if tutorial_mode:
		_draw_tutorial_pond()
		_draw_tutorial_ledge(wvt, vb)
	if rambla():
		_draw_rambla(vt, vb)
	if lvl == "trail":
		_draw_wood(vt, vb)
		_draw_trail_stream(vt, vb)
		for lr: Rect2 in LevelBuild.trail_logs(self):
			if lr.position.y > vt - 60.0 and lr.position.y < vb + 60.0:
				_draw_fallen_log(lr)
	# bike lanes crossing the sidewalk
	for i in range(lane_ys.size()):
		var ly: float = lane_ys[i]
		_wc.draw_rect(Rect2(-400, ly - LANE_HALF, 2100, LANE_HALF * 2.0), COL_ROAD)
		var x := -380.0
		while x < 1700.0:
			_wc.draw_line(Vector2(x, ly), Vector2(x + 30.0, ly), COL_STRIPE, 3.0)
			x += 70.0
		_wc.draw_line(Vector2(-400, ly - LANE_HALF), Vector2(1700, ly - LANE_HALF), COL_STRIPE, 2.0)
		_wc.draw_line(Vector2(-400, ly + LANE_HALF), Vector2(1700, ly + LANE_HALF), COL_STRIPE, 2.0)
		var ls: Dictionary = lane_state[i]
		if ls.phase == 1 and fmod(AnimClock.msec() / 150.0, 2.0) < 1.0:
			var wx := 40.0 if ls.dir > 0 else 1240.0
			_wc.draw_circle(Vector2(wx, ly), 16.0, Color(0.95, 0.8, 0.25))
			_wc.draw_rect(Rect2(wx - 2.0, ly - 9.0, 4.0, 10.0), Color(0.15, 0.15, 0.15))
			_wc.draw_circle(Vector2(wx, ly + 6.0), 2.2, Color(0.15, 0.15, 0.15))
	# manholes - open for street work; the cones are real nodes now.
	# This one has to read as A HOLE from a glance at speed, because falling
	# in ends the walk: hence the lifted cover leaning beside it, the lit
	# near rim, and the shaft going properly dark toward the far side.
	for m in manholes:
		if m.y < vt - 50.0 or m.y > vb + 50.0:
			continue
		# the cover, lifted off and propped against the kerb side
		var cv := m + LIGHT * 30.0
		contact_shadow(_wc, cv, 15.0, 5.0, 0.22)
		_wc.draw_circle(cv, 14.0, Color(0.30, 0.30, 0.33))
		_wc.draw_circle(cv, 11.0, Color(0.37, 0.37, 0.40))
		for gi in range(3):
			_wc.draw_line(cv + Vector2(-9.0, -6.0 + float(gi) * 6.0), cv + Vector2(9.0, -6.0 + float(gi) * 6.0),
				Color(0.26, 0.26, 0.29), 1.6)
		# the collar of brickwork it is set into
		_wc.draw_circle(m, 25.0, Color(0.34, 0.32, 0.31))
		_wc.draw_circle(m, 22.0, Color(0.24, 0.23, 0.23))
		# the shaft: dark, and darker away from the light
		_wc.draw_circle(m, 19.0, Color(0.10, 0.10, 0.12))
		_wc.draw_circle(m + LIGHT * 5.0, 15.0, Color(0.05, 0.05, 0.07))
		# the lit rim on the light side, which is what makes it a hole and
		# not a disc
		_wc.draw_arc(m, 19.5, PI * 0.95, PI * 1.95, 16, Color(0.55, 0.53, 0.50), 2.4)
		_wc.draw_arc(m, 19.5, PI * 0.0, PI * 0.6, 12, Color(0.16, 0.16, 0.18), 2.0)
		# rungs going down, just visible
		for ri in range(2):
			_wc.draw_line(m + Vector2(-6.0, 2.0 + float(ri) * 7.0), m + Vector2(6.0, 2.0 + float(ri) * 7.0),
				Color(0.22, 0.21, 0.20), 2.0)
	# hydrants: cast iron, and the most important object in the world if you
	# are a dog. Base flange, barrel, bonnet, two side outlets and a chain -
	# it was two flat circles and read as a red dot.
	for h in hydrants:
		var hp: Vector2 = h.pos
		if hp.y < vt - 40.0 or hp.y > vb + 40.0:
			continue
		if lvl == "trail":
			_draw_waymarker(_wc, h)
			continue
		if lvl == "oldtown":
			# a terracotta pot of geraniums by a door
			contact_shadow(_wc, hp, 12.0, 5.0, 0.22)
			_wc.draw_circle(hp, 11.0, Color(0.70, 0.38, 0.24) if not h.done else Color(0.52, 0.34, 0.26))
			_wc.draw_circle(hp, 8.0, Color(0.30, 0.44, 0.22))
			for k in range(4):
				_wc.draw_circle(hp + Vector2.from_angle(TAU * float(k) / 4.0 + 0.5) * 5.0, 3.0, Color(0.88, 0.18, 0.22))
			if not h.done and h.progress > 0.0:
				_wc.draw_arc(hp, 17.0, -PI / 2.0, -PI / 2.0 + TAU * h.progress / 0.8, 20, Color(1, 0.95, 0.7), 3.0)
			continue
		if lvl == "guell":
			# a rubble-stone planter with an agave in it
			contact_shadow(_wc, hp, 15.0, 6.0, 0.22)
			_wc.draw_circle(hp, 15.0, Color(0.56, 0.48, 0.38) if not h.done else Color(0.48, 0.42, 0.34))
			_wc.draw_circle(hp, 11.0, Color(0.34, 0.28, 0.22))
			for f in range(7):
				_wc.draw_line(hp, hp + Vector2.from_angle(float(f) * TAU / 7.0) * 15.0, Color(0.44, 0.60, 0.54), 3.5)
			if not h.done and h.progress > 0.0:
				_wc.draw_arc(hp, 21.0, -PI / 2.0, -PI / 2.0 + TAU * h.progress / 0.8, 20, Color(1, 0.95, 0.7), 3.0)
			continue
		if lvl == "spook":
			# a hessian sack of chestnuts, top rolled down, some spilt
			contact_shadow(_wc, hp, 14.0, 6.0, 0.22)
			var sk := Color(0.66, 0.54, 0.36) if not h.done else Color(0.54, 0.46, 0.34)
			_wc.draw_circle(hp, 13.0, sk)
			_wc.draw_circle(hp + Vector2(0, -2), 9.0, sk.darkened(0.15))
			for k in range(5):
				_wc.draw_circle(hp + Vector2.from_angle(float(k) * 1.3) * 5.0 + Vector2(0, -2), 3.0, Color(0.40, 0.20, 0.10))
			if not h.done and h.progress > 0.0:
				_wc.draw_arc(hp, 19.0, -PI / 2.0, -PI / 2.0 + TAU * h.progress / 0.8, 20, Color(1, 0.95, 0.7), 3.0)
			continue
		if lvl == "market":
			# a stack of orange crates by the wall: what gets marked in a hall
			contact_shadow(_wc, hp, 15.0, 6.0, 0.22)
			var cc := Color(0.66, 0.50, 0.32) if not h.done else Color(0.52, 0.42, 0.30)
			_wc.draw_rect(Rect2(hp.x - 14.0, hp.y - 12.0, 28.0, 22.0), cc)
			_wc.draw_rect(Rect2(hp.x - 12.0, hp.y - 18.0, 24.0, 12.0), cc.darkened(0.12))
			for k in range(4):
				_wc.draw_circle(hp + Vector2(-8.0 + float(k) * 5.5, -13.0), 3.2, Color(0.96, 0.56, 0.12))
			if not h.done and h.progress > 0.0:
				_wc.draw_arc(hp, 19.0, -PI / 2.0, -PI / 2.0 + TAU * h.progress / 0.8, 20, Color(1, 0.95, 0.7), 3.0)
			continue
		if lvl == "scrap":
			# a stack of old tyres, the scrapyard's stand-in for a hydrant
			contact_shadow(_wc, hp, 15.0, 6.0, 0.22)
			for k in range(3):
				var tp := hp + Vector2(float(k % 2) * 3.0 - 1.5, -float(k) * 4.0)
				_wc.draw_circle(tp, 14.0, Color(0.10, 0.10, 0.11) if not h.done else Color(0.20, 0.19, 0.18))
				_wc.draw_circle(tp, 6.0, Color(0.26, 0.24, 0.22))
			if not h.done and h.progress > 0.0:
				_wc.draw_arc(hp, 19.0, -PI / 2.0, -PI / 2.0 + TAU * h.progress / 0.8, 20, Color(1, 0.95, 0.7), 3.0)
			continue
		if lvl == "station":
			# a planter with a potted palm, the station's stand-in for a hydrant
			contact_shadow(_wc, hp, 13.0, 5.0, 0.2)
			_wc.draw_circle(hp, 12.0, Color(0.36, 0.32, 0.30) if not h.done else Color(0.30, 0.28, 0.27))
			_wc.draw_circle(hp, 9.0, Color(0.30, 0.24, 0.18))
			for k in range(5):
				var fa := TAU * float(k) / 5.0 + 0.4
				_wc.draw_line(hp, hp + Vector2.from_angle(fa) * 16.0, Color(0.26, 0.48, 0.26), 4.0)
			if not h.done and h.progress > 0.0:
				_wc.draw_arc(hp, 17.0, -PI / 2.0, -PI / 2.0 + TAU * h.progress / 0.8, 20, Color(1, 0.95, 0.7), 3.0)
			continue
		if String(h.get("kind", "")) == "mammoth":
			if not h.done and h.progress > 0.0:
				_wc.draw_arc(hp, 17.0, -PI / 2.0, -PI / 2.0 + TAU * h.progress / 0.8, 20, Color(1, 0.95, 0.7), 3.0)
			continue     # the foot of the statue, drawn with it
		var c := Color(0.45, 0.4, 0.38) if h.done else Color(0.68, 0.23, 0.18)
		cast_shadow(_wc, hp, 8.0, 26.0)
		# the flange it is bolted down with
		_wc.draw_circle(hp + Vector2(0, 3), 12.0, c.darkened(0.45))
		_wc.draw_circle(hp + Vector2(0, 3), 9.5, c.darkened(0.3))
		# side outlets, one either side, with their caps
		for so: float in [-1.0, 1.0]:
			var op := hp + Vector2(10.0 * so, -1.0)
			_wc.draw_line(hp, op, c.darkened(0.15), 5.0)
			_wc.draw_circle(op, 3.6, c.lightened(0.08))
			_wc.draw_circle(op, 1.8, c.darkened(0.35))
		# the barrel, lit from the upper left
		_wc.draw_circle(hp, 8.5, c)
		_wc.draw_circle(hp + Vector2(-2.5, -2.5), 5.0, c.lightened(0.16))
		# the bonnet on top, and its little cap nut
		_wc.draw_circle(hp + Vector2(0, -7), 5.6, c.darkened(0.12))
		_wc.draw_circle(hp + Vector2(-1.5, -8.5), 3.0, c.lightened(0.22))
		_wc.draw_circle(hp + Vector2(0, -11), 2.0, Color(0.85, 0.8, 0.7, 0.9))
		# the chain, hanging off to one side
		for ci in range(3):
			_wc.draw_circle(hp + Vector2(7.0 + float(ci) * 2.6, 6.0 + float(ci) * 1.6), 1.5,
				Color(0.62, 0.6, 0.58))
		if not h.done and h.progress > 0.0:
			_wc.draw_arc(hp, 17.0, -PI / 2.0, -PI / 2.0 + TAU * h.progress / 0.8, 20, Color(1, 0.95, 0.7), 3.0)
	# the dropped snack. A brown circle could have been anything; this is a
	# half-eaten kebab lying in its paper, which is unmistakably Barcelona
	# pavement and unmistakably worth eating off it.
	for k in kebabs:
		if k.eaten or k.pos.y < vt - 30.0 or k.pos.y > vb + 30.0:
			continue
		var kp: Vector2 = k.pos
		if lvl == "trail":
			_draw_bocadillo(_wc, kp)
			continue
		contact_shadow(_wc, kp, 9.0, 4.0, 0.20)
		# the paper wrapper, screwed open
		_wc.draw_colored_polygon(
			PackedVector2Array([
				kp + Vector2(-11, 3), kp + Vector2(-6, -8), kp + Vector2(7, -7),
				kp + Vector2(11, 5), kp + Vector2(0, 9),
			]), Color(0.90, 0.87, 0.79))
		_wc.draw_colored_polygon(
			PackedVector2Array([
				kp + Vector2(-7, 2), kp + Vector2(-3, -5), kp + Vector2(5, -4),
				kp + Vector2(7, 3), kp + Vector2(0, 6),
			]), Color(0.80, 0.77, 0.70))
		# the meat, and a sad shred of salad nobody wants
		_wc.draw_circle(kp + Vector2(-1, -1), 5.2, Color(0.62, 0.40, 0.22))
		_wc.draw_circle(kp + Vector2(-2.5, -2.5), 3.0, Color(0.74, 0.50, 0.28))
		_wc.draw_circle(kp + Vector2(3, 2), 2.4, Color(0.55, 0.34, 0.19))
		_wc.draw_line(kp + Vector2(-5, 4), kp + Vector2(1, 5), Color(0.45, 0.62, 0.32), 2.0)
	# candy: shiny wrapped sweets - tempting, forbidden, faintly glinting
	var candy_cols := [Color(0.85, 0.25, 0.35), Color(0.3, 0.5, 0.85), Color(0.55, 0.35, 0.7)]
	for ci in range(candy.size()):
		var c: Dictionary = candy[ci]
		if c.eaten or c.pos.y < vt - 20.0 or c.pos.y > vb + 20.0:
			continue
		var cc: Color = candy_cols[ci % candy_cols.size()]
		var gl := 0.6 + 0.4 * sin(prize_glow + ci)
		_wc.draw_circle(c.pos, 6.0, cc)
		_wc.draw_line(c.pos + Vector2(-6, -3), c.pos + Vector2(-9, -5), cc, 2.0)  # wrapper twists
		_wc.draw_line(c.pos + Vector2(-6, 3), c.pos + Vector2(-9, 5), cc, 2.0)
		_wc.draw_line(c.pos + Vector2(6, -3), c.pos + Vector2(9, -5), cc, 2.0)
		_wc.draw_line(c.pos + Vector2(6, 3), c.pos + Vector2(9, 5), cc, 2.0)
		_wc.draw_circle(c.pos + Vector2(-2, -2), 1.6, Color(1, 1, 1, 0.4 + gl * 0.4))
	# the hazardous prize: a glinting collectible with a beckoning ring
	if not prize_taken and prize_pos.x < INF and prize_pos.y > vt - 40.0 and prize_pos.y < vb + 40.0:
		var pg := 0.5 + 0.5 * sin(prize_glow)
		_wc.draw_arc(prize_pos, 16.0 + pg * 5.0, 0, TAU, 20, Color(1.0, 0.85, 0.3, 0.35 + pg * 0.3), 2.0)
		_wc.draw_circle(prize_pos, 7.0, Color(0.95, 0.8, 0.35))
		_wc.draw_circle(prize_pos + Vector2(-2, -2), 2.5, Color(1, 0.97, 0.85))
		_wc.draw_string(font, prize_pos + Vector2(-30, -22), "!", HORIZONTAL_ALIGNMENT_CENTER, 60, 18, Color(1, 0.9, 0.5))
	# carry mission: the parcel where it waits, the drop-off marker, and
	# the parcel riding in Millie's mouth while she totes it
	if carry_pickup.x < INF and carry_state < 2:
		if carry_state == 0:
			_wc.draw_rect(Rect2(carry_pickup.x - 8.0, carry_pickup.y - 5.0, 16.0, 10.0), Color(0.7, 0.6, 0.4))
			_wc.draw_line(carry_pickup + Vector2(-8, -1), carry_pickup + Vector2(8, -1), Color(0.4, 0.32, 0.2), 1.0)
		# the drop-off: a doormat with a downward chevron
		var dp := 0.5 + 0.5 * sin(prize_glow)
		_wc.draw_rect(Rect2(carry_drop.x - 16.0, carry_drop.y - 10.0, 32.0, 20.0), Color(0.35, 0.4, 0.5, 0.4 + dp * 0.25))
		_wc.draw_rect(Rect2(carry_drop.x - 16.0, carry_drop.y - 10.0, 32.0, 20.0), Color(0.7, 0.8, 0.95, 0.5), false, 2.0)
		_wc.draw_string(font, carry_drop + Vector2(-40, -16), "DROP", HORIZONTAL_ALIGNMENT_CENTER, 80, 13, Color(0.8, 0.9, 1.0, 0.8))
	if carry_state == 1:
		var mp: Vector2 = dog.global_position + dog.facing * 20.0
		_wc.draw_rect(Rect2(mp.x - 7.0, mp.y - 4.0, 14.0, 8.0), Color(0.7, 0.6, 0.4))
	# lampposts downtown, trees in the park, palms by the sea
	# (same physics, different soul)
	# night lighting: warm pools spilling from the lampposts. Layered
	# concentric alpha fakes a falloff gradient cheaply, and because the
	# lamps never move the 30fps world redraw is plenty.
	if Game.night:
		var lamp_t := AnimClock.msec() / 1000.0
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
				_wc.draw_circle(lp + Vector2(0, 16), rr, Color(1.0, 0.86, 0.55, aa))
			_wc.draw_circle(lp + Vector2(0, -22), 7.0, Color(1.0, 0.94, 0.72, 0.9 * flick))
	for i in range(deco_pole_count):
		var p := poles[i]
		if p.y < vt - 60.0 or p.y > vb + 60.0:
			continue
		if tutorial_mode:
			_draw_lamppost(p)       # the lesson posts are lampposts, as the cards say
		elif lvl == "scrap":
			_draw_lamppost(p)       # floodlight masts over the yard
		elif lvl == "station":
			if absf(p.y - LevelBuild.ESTACIO_BARRIER_Y) < 1.0:
				continue      # a barrier cabinet, drawn with the barriers
			cast_shadow(_wc, p, 18.0, 36.0, 0.2)
			_wc.draw_rect(Rect2(p.x - 17.0, p.y - 17.0, 34.0, 34.0), Color(0.70, 0.70, 0.72))
			_wc.draw_rect(Rect2(p.x - 17.0, p.y - 17.0, 10.0, 34.0), Color(0.80, 0.80, 0.82))
			_wc.draw_rect(Rect2(p.x - 17.0, p.y - 17.0, 34.0, 34.0), Color(0.52, 0.52, 0.55), false, 2.0)
		elif lvl == "rain" and p.x < walk_cx:
			# the arcade's pillars: square stone, lit on one face
			cast_shadow(_wc, p, 12.0, 30.0, 0.2)
			_wc.draw_rect(Rect2(p.x - 11.0, p.y - 11.0, 22.0, 22.0), Color(0.55, 0.50, 0.45))
			_wc.draw_rect(Rect2(p.x - 11.0, p.y - 11.0, 8.0, 22.0), Color(0.64, 0.59, 0.53))
		elif lvl == "guell":
			if p.y > LevelBuild.MOSAIC_HALL_Y1 - 50.0 and p.y < LevelBuild.MOSAIC_HALL_Y0 + 50.0:
				# a fat Doric column of the hypostyle hall, from above: the
				# round capital, its ring, a trencadis medallion on top
				cast_shadow(_wc, p, 20.0, 50.0, 0.22)
				_wc.draw_circle(p, 24.0, Color(0.78, 0.74, 0.66))
				_wc.draw_circle(p, 19.0, Color(0.86, 0.83, 0.76))
				_trencadis_disc(_wc, p, 11.0, int(absf(p.x + p.y)))
			else:
				# a viaduct column: rubble stone, leaning into the hill like a
				# palm trunk, its lean read from the long shadow
				_wc.draw_colored_polygon(PackedVector2Array([p + Vector2(-14, 10), p + Vector2(14, 10),
					p + Vector2(40, 60), p + Vector2(18, 64)]), Color(SHADOW_COL.r, SHADOW_COL.g, SHADOW_COL.b, 0.22))
				_wc.draw_circle(p, 17.0, Color(0.50, 0.42, 0.34))
				_wc.draw_circle(p + Vector2(-6, -10), 14.0, Color(0.58, 0.49, 0.39))
				for k in range(5):
					_wc.draw_circle(p + Vector2(-6, -10) + Vector2.from_angle(float(k) * 1.4) * 8.0, 3.0, Color(0.44, 0.37, 0.30))
		elif lvl == "market":
			# the hall's cast-iron columns, painted green, on a flared foot
			cast_shadow(_wc, p, 10.0, 40.0, 0.2)
			_wc.draw_circle(p, 13.0, Color(0.16, 0.26, 0.22))
			_wc.draw_circle(p, 9.0, Color(0.22, 0.36, 0.30))
			_wc.draw_circle(p + Vector2(-2.5, -2.5), 4.0, Color(0.36, 0.52, 0.44))
		elif lvl == "park" or lvl == "barri" or lvl == "spook":
			_draw_broadleaf(_wc, p, 1.0)
		elif lvl == "trail":
			_draw_forest_tree(_wc, p, i)
		elif lvl == "beach":
			_draw_palm(_wc, p)
		elif (p.x > sw_l + 60.0 and p.x < sw_r - 60.0) \
				or (rambla() and int(absf(p.y) / LevelBuild.RAMBLA_TREE_STEP) % 4 != 1):
			# mid-walkway poles are street trees in grates, and so is La
			# Rambla's row of plane trees down each edge (every fourth one a
			# lamp standard instead) - that is WHY
			# they stand in the middle of a sidewalk
			cast_shadow(_wc, p, 20.0, 40.0, 0.16)
			_wc.draw_circle(p, 19.0, Color(0.26, 0.24, 0.22))          # the pit
			_wc.draw_rect(Rect2(p.x - 16, p.y - 16, 32, 32), Color(0.34, 0.34, 0.37))
			for gi in range(4):
				var gy := p.y - 12.0 + float(gi) * 8.0
				_wc.draw_line(Vector2(p.x - 15, gy), Vector2(p.x + 15, gy), Color(0.2, 0.2, 0.22), 2.0)
			_wc.draw_rect(Rect2(p.x - 16, p.y - 16, 32, 32), Color(0.44, 0.44, 0.47), false, 2.0)
			_draw_broadleaf(_wc, p, 0.72)
		else:
			_draw_lamppost(p)
	# trash bins: green, lidded, with a visible mouth - the ONLY thing
	# the owner will throw a bag into
	for bn in bins:
		if bn.y < vt - 40.0 or bn.y > vb + 40.0:
			continue
		cast_shadow(_wc, bn, 11.0, 24.0)
		# the drum, on its post, with a lit rim and a genuinely dark mouth
		_wc.draw_circle(bn, 13.0, Color(0.18, 0.25, 0.20))
		_wc.draw_circle(bn, 11.0, Color(0.26, 0.36, 0.28))
		_wc.draw_circle(bn + Vector2(-3, -3), 7.0, Color(0.32, 0.44, 0.33))
		_wc.draw_arc(bn, 11.0, PI * 1.05, PI * 1.95, 14, Color(0.42, 0.55, 0.42), 2.0)
		# the hinged lid, tipped open toward the light
		_wc.draw_circle(bn + Vector2(1, 2), 8.6, Color(0.10, 0.14, 0.11))
		_wc.draw_arc(bn + Vector2(1, 2), 8.6, PI * 0.1, PI * 0.9, 12, Color(0.20, 0.28, 0.22), 3.0)
		# a bag someone has knotted round the handle, as always
		_wc.draw_circle(bn + Vector2(12, 6), 4.0, Color(0.78, 0.78, 0.74, 0.85))
		_wc.draw_line(bn + Vector2(10, 2), bn + Vector2(12, 5), Color(0.7, 0.7, 0.66), 1.5)
	# cafe tables with a little service on them
	for tb in tables:
		if tb.y < vt - 40.0 or tb.y > vb + 40.0:
			continue
		contact_shadow(_wc, tb, 14.0, 9.0, 0.20)
		# a bistro table: a pale marble top in a dark metal rim, its lit edge on
		# the upper-left. (A grey top the colour of the paving, with a round
		# cup and a highlight disc on it, read as a face looking up at you.)
		_wc.draw_circle(tb + Vector2(0.6, 0.8), 14.0, Color(0.20, 0.20, 0.22))
		_wc.draw_circle(tb + Vector2(-0.3, -0.3), 12.4, Color(0.90, 0.88, 0.84))
		_wc.draw_arc(tb + Vector2(-0.3, -0.3), 12.4, PI * 0.1, PI * 0.9, 8, Color(0.74, 0.72, 0.68), 2.0)
		_wc.draw_line(tb + Vector2(-6, -2), tb + Vector2(2, 5), Color(0.78, 0.76, 0.74, 0.7), 1.0)
		# a coffee in a small cup on its saucer, the handle out to the side
		var cup := tb + Vector2(4.5, -4)
		_wc.draw_circle(cup, 3.6, Color(0.76, 0.74, 0.70))
		_wc.draw_circle(cup, 2.3, Color(0.36, 0.22, 0.12))
		_wc.draw_line(cup + Vector2(2.4, 0.8), cup + Vector2(4.6, 1.8), Color(0.76, 0.74, 0.70), 1.6)
		# then whatever else they ordered: a croissant, or a glass of water
		if int(absf(tb.x * 0.13 + tb.y * 0.07)) % 2 == 0:
			var cr := tb + Vector2(-4.0, 4.0)
			_wc.draw_arc(cr, 3.2, PI * 0.1, PI * 1.1, 7, Color(0.70, 0.44, 0.16), 3.6)
			_wc.draw_arc(cr, 3.2, PI * 0.3, PI * 0.9, 5, Color(0.90, 0.66, 0.30), 1.6)
		else:
			var gl := tb + Vector2(-4.0, 4.5)
			_wc.draw_circle(gl, 2.8, Color(0.60, 0.76, 0.84, 0.8))
			_wc.draw_arc(gl, 2.8, PI * 1.1, PI * 1.6, 5, Color(1, 1, 1, 0.9), 1.0)
		_wc.draw_rect(Rect2(tb.x - 8.0, tb.y - 6.0, 5.0, 3.0), Color(0.92, 0.82, 0.56))
	# canopies over the beach terraces: out by day, furled at night
	for cn in canopies:
		if Game.night:
			_wc.draw_rect(Rect2(cn.position.x, cn.position.y, cn.size.x, 10), Color(0.72, 0.67, 0.57))
			_wc.draw_rect(Rect2(cn.position.x, cn.position.y, cn.size.x, 10), Color(0.5, 0.46, 0.38), false, 1.5)
		else:
			_wc.draw_rect(cn, Color(0.93, 0.9, 0.8, 0.45))
			_wc.draw_rect(cn, Color(0.6, 0.55, 0.45, 0.6), false, 2.0)
			_wc.draw_line(Vector2(cn.get_center().x, cn.position.y), Vector2(cn.get_center().x, cn.end.y), Color(0.6, 0.55, 0.45, 0.4), 1.5)
	# umbrellas: wide, OVER the tables by day; furled spikes at night
	var pcols := [Color(0.85, 0.45, 0.35, 0.7), Color(0.4, 0.6, 0.75, 0.7), Color(0.9, 0.8, 0.4, 0.7)]
	for i in range(parasols.size()):
		var pa := parasols[i]
		if Game.night:
			_wc.draw_line(pa + Vector2(-3, 24), pa + Vector2(3, -28), Color(0.45, 0.4, 0.35), 5.0)
			_wc.draw_circle(pa + Vector2(3, -28), 4.0, pcols[i % 3])
		else:
			_draw_parasol(pa, pcols[i % 3], float(i))
	# benches
	# benches: three slats on cast-iron ends, each slat a soft plank lit on
	# its upper-left, and the shadow of something knee high
	for b in benches:
		if b.y < vt - 60.0 or b.y > vb + 60.0:
			continue
		var bseat := Rect2(b.x - 8.0, b.y - 24.0, 16.0, 48.0)
		box_shadow(_wc, bseat, 4.0, 7.0)
		for ey: float in [-21.0, 17.0]:
			_wc.draw_colored_polygon(round_rect_pts(Rect2(b.x - 10.0, b.y + ey, 20.0, 4.0), 2.0), Color(0.16, 0.16, 0.17))
		for si in range(3):
			var sl := Rect2(b.x - 8.0 + float(si) * 5.5, b.y - 24.0, 5.0, 48.0)
			var wc := Color(0.56, 0.41, 0.27).lightened(0.10 if si == 0 else 0.0).darkened(0.12 if si == 2 else 0.0)
			_wc.draw_colored_polygon(round_rect_pts(sl, 2.2), wc.darkened(0.30))
			_wc.draw_colored_polygon(round_rect_pts(Rect2(sl.position, sl.size - Vector2(1.2, 1.2)), 2.0), wc)
			_wc.draw_line(sl.position + Vector2(1.2, 3.0), sl.position + Vector2(1.2, 20.0), wc.lightened(0.25), 1.2)
		for ey: float in [-19.0, 19.0]:
			for bx: float in [-5.5, 0.0, 5.5]:
				_wc.draw_circle(Vector2(b.x + bx, b.y + ey), 0.9, Color(0.20, 0.18, 0.16))
	# terrace chairs: round seats, four legs, a hint of backrest
	for ch in chairs:
		for lg in [Vector2(-5, -5), Vector2(5, -5), Vector2(-5, 5), Vector2(5, 5)]:
			_wc.draw_circle(ch + lg, 1.5, Color(0.35, 0.27, 0.18))
		_wc.draw_circle(ch, 6.5, Color(0.58, 0.44, 0.3))
		_wc.draw_arc(ch, 6.5, PI * 1.15, PI * 1.85, 8, Color(0.4, 0.3, 0.2), 3.0)
	# fountains: where the tank refills
	for f in fountains:
		if lvl == "trail":
			break     # El Bosc drinks from the stream, which draws itself
		if rambla():
			_draw_canaletes(f)
			continue
		if lvl == "oldtown":
			continue      # the plaça's fountain draws with the plaça
		if f.y < vt - 40.0 or f.y > vb + 40.0:
			continue
		# a drinking fountain: a stone bowl on a post, water in it, the
		# spout, and the wet patch it always leaves on the paving
		_wc.draw_circle(f + Vector2(14, 8), 6.0, Color(0.45, 0.6, 0.7, 0.45))
		_wc.draw_circle(f + Vector2(19, 12), 3.5, Color(0.45, 0.6, 0.7, 0.35))
		contact_shadow(_wc, f, 12.0, 8.0, 0.22)
		_wc.draw_circle(f + Vector2(0.8, 1.0), 12.5, Color(0.40, 0.44, 0.46))
		_wc.draw_circle(f + Vector2(-0.4, -0.4), 11.4, Color(0.60, 0.64, 0.66))
		_wc.draw_circle(f + Vector2(-3.5, -3.5), 5.0, Color(0.72, 0.76, 0.78))
		_wc.draw_circle(f + Vector2(0.6, 0.6), 7.8, Color(0.26, 0.40, 0.50))
		_wc.draw_circle(f, 7.0, Color(0.38, 0.58, 0.70))
		_wc.draw_circle(f + Vector2(-2.4, -2.0), 2.4, Color(0.80, 0.92, 0.98, 0.85))
		_wc.draw_line(f + Vector2(0, -12), f + Vector2(0, -5), Color(0.30, 0.32, 0.34), 3.0)
		_wc.draw_circle(f + Vector2(0, -4.5), 1.6, Color(0.75, 0.88, 0.95))
	# market stalls: awnings, crates, produce
	for i in range(stalls.size()):
		var st := stalls[i]
		if i < stall_kinds.size() and stall_kinds[i] == "pingpong":
			_draw_pingpong(st)
			continue
		if i < stall_kinds.size() and stall_kinds[i] != "":
			_draw_rambla_stall(st, stall_kinds[i], i)
			continue
		if st.y < vt - 90.0 or st.y > vb + 90.0:
			continue
		var sr := Rect2(st.x - 48, st.y - 28, 96, 56)
		box_shadow(_wc, sr, 5.0, 12.0)
		clay_slab(_wc, sr, 5.0, Color(0.55, 0.42, 0.3), 3.0)
		# the striped awning along the back, each stripe rounded at its hem
		var acol := Color(0.75, 0.3, 0.28) if i % 2 == 0 else Color(0.32, 0.5, 0.42)
		_wc.draw_rect(Rect2(st.x - 48, st.y - 37, 96, 4), acol.darkened(0.3))
		for s2 in range(6):
			_wc.draw_colored_polygon(round_rect_pts(Rect2(st.x - 48 + s2 * 16.0, st.y - 37, 8, 11), 3.0), acol)
			_wc.draw_colored_polygon(round_rect_pts(Rect2(st.x - 40 + s2 * 16.0, st.y - 37, 8, 11), 3.0), Color(0.94, 0.92, 0.86))
		clay_slab(_wc, Rect2(st.x - 40, st.y - 18, 24, 16), 3.0, Color(0.7, 0.55, 0.35), 2.0)
		for fr: Array in [[Vector2(18, -2), 5.0, Color(0.85, 0.45, 0.3)], [Vector2(30, 6), 5.0, Color(0.9, 0.7, 0.3)],
				[Vector2(6, 10), 4.0, Color(0.5, 0.65, 0.35)]]:
			var fc: Color = fr[2]
			_wc.draw_circle(st + (fr[0] as Vector2) + Vector2(0.6, 0.6), float(fr[1]), fc.darkened(0.3))
			_wc.draw_circle(st + (fr[0] as Vector2), float(fr[1]) - 0.6, fc)
			_wc.draw_circle(st + (fr[0] as Vector2) + Vector2(-1.5, -1.5), float(fr[1]) * 0.35, fc.lightened(0.35))
	# parked service vans, half on the walkway, hazards blinking in spirit
	# The service van: the biggest object in the game and, until now, a white
	# rectangle with four black tabs. A van seen from above is a roof - so it
	# gets a roof: ribs across it, a vent, roof bars, the windscreen raked
	# under the front edge, mirrors sticking out past the body, and the long
	# shadow a two-metre box actually throws.
	for v in vans:
		if v.y < vt - 140.0 or v.y > vb + 140.0:
			continue
		if lvl == "site":
			_draw_digger(v)
			continue
		if lvl == "station":
			_draw_trolleys(v)
			continue
		if lvl == "scrap":
			_draw_wreck_stack(v)
			continue
		_draw_service_van(v)
	if furgoneta.x < INF and furgoneta.y > vt - 150.0 and furgoneta.y < vb + 150.0:
		_draw_furgoneta(furgoneta)

	# L'Estacio: the moving walkway - a metal band with chevrons scrolling
	# in the carry direction
	if lvl == "montjuic":
		# Montjuic's conveyor is its escalators, drawn as such
		Montjuic.draw_escalator(self, _wc, vt, vb)
	elif conveyor_zone.size.y > 0.0 and conveyor_zone.end.y > vt and conveyor_zone.position.y < vb:
		_wc.draw_rect(conveyor_zone, Color(0.32, 0.34, 0.38))
		_wc.draw_rect(conveyor_zone, Color(0.55, 0.58, 0.62), false, 2.0)
		var scroll := fmod(AnimClock.msec() / 1000.0 * 90.0, 60.0) * conveyor_dir.y
		var cy := conveyor_zone.position.y + fmod(scroll, 60.0)
		while cy < conveyor_zone.end.y + 60.0:
			if cy > vt - 20.0 and cy < vb + 20.0:
				var cx := conveyor_zone.get_center().x
				_wc.draw_line(Vector2(cx - 30.0, cy + 10.0), Vector2(cx, cy), Color(0.6, 0.63, 0.68), 3.0)
				_wc.draw_line(Vector2(cx + 30.0, cy + 10.0), Vector2(cx, cy), Color(0.6, 0.63, 0.68), 3.0)
			cy += 60.0
	_draw_ground_detail(vt, vb)
	_draw_ground_marks(vt, vb)
	# the paw trail, in whatever she stood in
	# footprints pressed into sand or snow: a shadowed hollow with a lit lip on
	# the far side (the one light is up-left), fading as it fills back in
	var snow := Game.weather == "snow"
	var hollow := Color(0.55, 0.60, 0.72) if snow else Color(0.58, 0.49, 0.33)
	var lip := Color(1.0, 1.0, 1.0) if snow else Color(0.93, 0.87, 0.70)
	for d in dents:
		var dp: Vector2 = d.pos
		if dp.y < vt - 20.0 or dp.y > vb + 20.0:
			continue
		var fade: float = clampf(1.0 - (elapsed - float(d.t)) / DENT_LIFE, 0.0, 1.0)
		if bool(d.get("boot", false)):
			_wc.draw_set_transform(dp, float(d.ang), Vector2(1.0, 0.6))
			_wc.draw_circle(Vector2(0.8, 0.8), 6.8, Color(lip.r, lip.g, lip.b, 0.35 * fade))
			_wc.draw_circle(Vector2.ZERO, 6.4, Color(hollow.r, hollow.g, hollow.b, 0.55 * fade))
			_wc.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			continue
		_wc.draw_circle(dp + Vector2(0.7, 0.7), 3.4, Color(lip.r, lip.g, lip.b, 0.35 * fade))
		_wc.draw_circle(dp, 3.2, Color(hollow.r, hollow.g, hollow.b, 0.6 * fade))
		var fwd := Vector2.from_angle(float(d.ang))
		var sd := fwd.orthogonal()
		_wc.draw_circle(dp + fwd * 4.0 + sd * 2.4, 1.4, Color(hollow.r, hollow.g, hollow.b, 0.55 * fade))
		_wc.draw_circle(dp + fwd * 4.0 - sd * 2.4, 1.4, Color(hollow.r, hollow.g, hollow.b, 0.55 * fade))
	for pr in paw_prints:
		var pp: Vector2 = pr.pos
		if pp.y < vt - 20.0 or pp.y > vb + 20.0:
			continue
		var pc: Color = SUBSTANCES[String(pr.kind)].col
		if bool(pr.get("boot", false)):
			# a sole: an oval pointing the way he was walking, so his trail
			# reads as a person's and hers reads as a dog's
			_wc.draw_set_transform(pp, float(pr.get("ang", 0.0)), Vector2(1.0, 0.62))
			_wc.draw_circle(Vector2.ZERO, 6.4, Color(pc.r, pc.g, pc.b, 0.62))
			_wc.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			continue
		_wc.draw_circle(pp, 3.2, Color(pc.r, pc.g, pc.b, 0.78))
		_wc.draw_circle(pp + Vector2(-2.5, -3.0), 1.4, Color(pc.r, pc.g, pc.b, 0.72))
		_wc.draw_circle(pp + Vector2(2.5, -3.0), 1.4, Color(pc.r, pc.g, pc.b, 0.72))
	# the substance patches themselves
	for sz in substance_zones:
		var zr: Rect2 = sz.rect
		if zr.end.y < vt - 40.0 or zr.position.y > vb + 40.0:
			continue
		if String(sz.kind) == "mud" or String(sz.kind) == "cement":
			continue  # those two draw themselves with their own level dressing
		if sz.has("zebra"):
			continue  # Les Obres' crossing draws itself as painted bars
		if sz.has("patch"):
			# a patch already drew itself as an organic blob (draw_patch), and
			# painting its bounding RECTANGLE over the top put a visible tinted
			# box round every sand drift on the promenade
			continue
		var zc: Color = SUBSTANCES[String(sz.kind)].col
		if sz.has("band"):
			# only the stretch on screen: a band can run the length of the walk
			var bd: Dictionary = (sz["band"] as Dictionary).duplicate()
			var y0: float = maxf(float(bd["y"]), vt - 40.0)
			var y1: float = minf(float(bd["y"]) + float(bd["h"]), vb + 40.0)
			if y1 > y0:
				bd["y"] = y0
				bd["h"] = y1 - y0
				draw_band(_wc, bd, Color(zc.r, zc.g, zc.b, 0.55))
			continue
		_wc.draw_rect(zr, Color(zc.r, zc.g, zc.b, 0.55))
		_wc.draw_rect(zr, Color(zc.r, zc.g, zc.b, 0.85), false, 2.0)
	_draw_scents()
	# the grind: the rail lights up under her and a CENTRED balance bar shows
	# which way she is tipping, with the running score beside it
	# with the zoomies on, the grindables near her show themselves faintly
	if dog.turbo_active and not grind.active:
		for gr: Dictionary in rails:
			if float(Rails.nearest(gr, dog.global_position)["d"]) < 160.0:
				_draw_rail(gr, vt, vb, Color(1.0, 0.92, 0.6, 0.30), 3.0)
	if grind.active:
		_draw_rail(rails[grind_rail], vt, vb, Color(1.0, 0.88, 0.45, 0.55), 4.0)
		var gp: Vector2 = dog.global_position + Vector2(0.0, -42.0)
		var gw := 74.0
		_wc.draw_rect(Rect2(gp.x - gw * 0.5, gp.y - 5.0, gw, 10.0), Color(0.06, 0.05, 0.08, 0.72))
		# centre mark, then the needle: middle is balanced, edges are a bail
		_wc.draw_line(Vector2(gp.x, gp.y - 5.0), Vector2(gp.x, gp.y + 5.0), Color(0.6, 0.62, 0.6, 0.8), 1.5)
		var nf: float = grind.fraction()
		var nx: float = gp.x - gw * 0.5 + gw * nf
		var tipping: float = absf(nf - 0.5) * 2.0
		_wc.draw_rect(Rect2(nx - 3.0, gp.y - 6.0, 6.0, 12.0),
			Color(0.6, 1.0, 0.6).lerp(Color(1.0, 0.4, 0.3), tipping))
		_wc.draw_string(font, gp + Vector2(-18.0, -12.0), "GRIND %d" % grind.points(),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(1, 0.95, 0.65))
	# the teeter meter: a tipping bar over the dog, filling toward the brink,
	# plus an arrow showing which way to scramble. Drawn in the world rather
	# than on the HUD so your eyes never leave her.
	if teeter.active:
		var f: float = teeter.fraction()
		var bp: Vector2 = dog.global_position + Vector2(0.0, -40.0)
		var bw := 66.0
		_wc.draw_rect(Rect2(bp.x - bw * 0.5, bp.y - 5.0, bw, 10.0), Color(0.06, 0.05, 0.08, 0.72))
		var danger := Color(1.0, 0.86, 0.35).lerp(Color(1.0, 0.32, 0.25), f)
		_wc.draw_rect(Rect2(bp.x - bw * 0.5 + 2.0, bp.y - 3.0, (bw - 4.0) * f, 6.0), danger)
		_wc.draw_rect(Rect2(bp.x - bw * 0.5, bp.y - 5.0, bw, 10.0), Color(0.9, 0.9, 0.85, 0.5), false, 1.5)
		# which way to fight: away from the brink
		var away: Vector2 = (dog.global_position - teeter_at).normalized()
		var ap: Vector2 = bp + Vector2(0.0, -16.0)
		var tip: Vector2 = ap + away * 17.0
		_wc.draw_line(ap, tip, Color(0.85, 1.0, 0.85, 0.95), 3.0)
		_wc.draw_line(tip, tip - away.rotated(0.5) * 7.0, Color(0.85, 1.0, 0.85, 0.95), 3.0)
		_wc.draw_line(tip, tip - away.rotated(-0.5) * 7.0, Color(0.85, 1.0, 0.85, 0.95), 3.0)
	# El Desguas: sweeping camera cones and laser tripwires
	if lvl == "scrap":
		var st := AnimClock.msec() / 1000.0
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
			_wc.draw_colored_polygon(pts, cone)
			# the unit itself: pole, housing, blinking eye
			_wc.draw_rect(Rect2(cp.x - 2.0, cp.y, 4.0, 26.0), Color(0.35, 0.35, 0.38))
			_wc.draw_rect(Rect2(cp.x - 9.0, cp.y - 10.0, 18.0, 12.0), Color(0.25, 0.26, 0.3))
			_wc.draw_circle(cp + Vector2.from_angle(ang) * 8.0, 2.5, Color(1, 0.3, 0.25) if fmod(st, 1.0) < 0.5 else Color(0.5, 0.15, 0.12))
		for lz in lasers:
			var by := lerpf(float(lz.y_lo), float(lz.y_hi), 0.5 + 0.5 * sin(st * float(lz.speed)))
			if by < vt - 20.0 or by > vb + 20.0:
				continue
			_wc.draw_line(Vector2(float(lz.x0), by), Vector2(float(lz.x1), by), Color(1.0, 0.2, 0.2, 0.75), 2.0)
			_wc.draw_line(Vector2(float(lz.x0), by), Vector2(float(lz.x1), by), Color(1.0, 0.5, 0.4, 0.25), 6.0)
			_wc.draw_rect(Rect2(float(lz.x0) - 8.0, by - 6.0, 8.0, 12.0), Color(0.3, 0.3, 0.34))
			_wc.draw_rect(Rect2(float(lz.x1), by - 6.0, 8.0, 12.0), Color(0.3, 0.3, 0.34))
	# Les Obres: wet cement patches, and the paw-print trail they take
	if lvl == "site":
		_draw_obres(vt, vb)
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
		draw_patch(_wc, pt, Color(base.r, base.g, base.b, 0.88),
			Color(base.r * 0.6, base.g * 0.6, base.b * 0.6, 0.45))
		if sk == "mud":
			_draw_mud_detail(pt, base)
			continue
		# a few darker flecks, so a big patch is not one flat colour
		var mid := patch_centre(pt)
		for i in range(5):
			var a := float(i) * 1.31 + float(pt["seed"])
			var rr := 0.34 + 0.4 * fmod(float(i) * 0.37, 1.0)
			_wc.draw_circle(mid + Vector2(cos(a) * float(pt["rx"]) * rr,
				sin(a) * float(pt["ry"]) * rr), 5.0,
				Color(base.r * 0.7, base.g * 0.7, base.b * 0.7, 0.6))
	# El Gotic: laundry strung across the alley overhead, a lantern or two
	if lvl == "oldtown" or lvl == "neteja":
		var lt := AnimClock.msec() / 1000.0
		var wash := [Color(0.8, 0.3, 0.35), Color(0.3, 0.5, 0.7), Color(0.9, 0.85, 0.6), Color(0.4, 0.65, 0.5)]
		for i in range(laundry_lines.size()):
			var ly: float = laundry_lines[i]
			var le := walk_edges(ly)
			_wc.draw_line(Vector2(le.x - 20.0, ly), Vector2(le.y + 20.0, ly - 8.0), Color(0.2, 0.18, 0.16), 1.5)
			for j in range(5):
				var hx := lerpf(le.x + 20.0, le.y - 20.0, float(j) / 4.0)
				var sway := sin(lt * 1.2 + j + i) * 2.0
				_wc.draw_rect(Rect2(hx - 9.0, ly - 6.0, 18.0, 26.0 + sway), wash[(i + j) % wash.size()])
		# lanterns down one wall
		for i in range(laundry_lines.size()):
			var lyy: float = laundry_lines[i] + 380.0
			var glow := 0.6 + 0.25 * sin(lt * 3.0 + i)
			_wc.draw_circle(Vector2(walk_edges(lyy).x + 6.0, lyy), 6.0, Color(1.0, 0.8, 0.4, glow))
	# street performers: a hat, some coins, music in the air. In the rain
	# they are an umbrella crowd instead - hunched under canopies, no busking.
	var pt := AnimClock.msec() / 1000.0
	var raining := Game.weather == "rain"
	var brolly_cols := [Color(0.75, 0.2, 0.25), Color(0.2, 0.35, 0.6), Color(0.25, 0.5, 0.35), Color(0.35, 0.3, 0.4)]
	for idx in range(performers.size()):
		var pf: Vector2 = performers[idx]
		if lvl == "barri":
			# an old man at the petanca, flat cap, hands behind his back
			contact_shadow(_wc, pf, 12.0, 5.0, 0.2)
			_wc.draw_circle(pf, 12.0, [Color(0.42, 0.40, 0.36), Color(0.30, 0.34, 0.42), Color(0.50, 0.44, 0.34)][idx % 3])
			_wc.draw_circle(pf + Vector2(0, -4), 6.5, Color(0.84, 0.68, 0.56))
			_wc.draw_circle(pf + Vector2(0, -5), 6.8, Color(0.30, 0.28, 0.26))
			_wc.draw_rect(Rect2(pf.x - 5.0, pf.y - 14.0, 10.0, 4.0), Color(0.26, 0.24, 0.22))
			continue
		if lvl == "guell" and idx == 1 and not raining:
			# a fan seller: a tray of paper fans opened out to show, one open
			# in hand, waving
			contact_shadow(_wc, pf, 12.0, 5.0, 0.2)
			var fcols := [Color(0.90, 0.24, 0.30), Color(0.20, 0.50, 0.80), Color(0.98, 0.80, 0.26), Color(0.30, 0.66, 0.40), Color(0.86, 0.46, 0.70)]
			_wc.draw_rect(Rect2(pf.x + 14.0, pf.y - 16.0, 34.0, 40.0), Color(0.46, 0.34, 0.24))
			for k in range(4):
				var fc: Vector2 = pf + Vector2(22.0 + float(k % 2) * 16.0, -6.0 + float(k / 2) * 20.0)
				_wc.draw_colored_polygon(PackedVector2Array([fc, fc + Vector2(-8, -9), fc + Vector2(0, -12), fc + Vector2(8, -9)]), fcols[(k + 1) % 5])
			_wc.draw_circle(pf, 12.0, Color(0.30, 0.30, 0.36))
			_wc.draw_circle(pf + Vector2(0, -4), 7.0, Color(0.72, 0.54, 0.40))
			var wave := sin(pt * 5.0) * 0.5
			var fh: Vector2 = pf + Vector2(-12, -8)
			var fpts := PackedVector2Array([fh])
			for k in range(7):
				fpts.append(fh + Vector2.from_angle(-PI * 0.5 + wave + (float(k) / 6.0 - 0.5) * 2.0) * 16.0)
			_wc.draw_colored_polygon(fpts, fcols[idx % 5])
			continue
		if lvl == "site":
			# a worker in hi-vis and a hard hat, leaning on a shovel
			contact_shadow(_wc, pf, 12.0, 5.0, 0.2)
			_wc.draw_circle(pf, 12.0, Color(0.96, 0.62, 0.12))
			_wc.draw_line(pf + Vector2(-10, -2), pf + Vector2(10, -2), Color(0.85, 0.88, 0.80), 3.0)
			_wc.draw_circle(pf + Vector2(0, -4), 7.5, Color(0.98, 0.86, 0.20))
			_wc.draw_line(pf + Vector2(10, 2), pf + Vector2(22, 20), Color(0.40, 0.30, 0.20), 2.5)
			_wc.draw_rect(Rect2(pf.x + 19.0, pf.y + 18.0, 8.0, 8.0), Color(0.45, 0.46, 0.48))
			continue
		if pf.y < vt - 60.0 or pf.y > vb + 60.0:
			continue
		# a busker with a guitar and its open case; in the rain, an umbrella
		# crowd instead, hunched under canopies, no busking
		if not raining:
			_draw_busker(pf, idx, pt)
			continue
		_wc.draw_circle(pf, 12.0, Color(0.5, 0.35, 0.5))
		_wc.draw_circle(pf + Vector2(0, -4), 7.0, Color(0.85, 0.72, 0.58))
		# a wide domed umbrella over the head, on its stick
		var bc: Color = brolly_cols[idx % brolly_cols.size()]
		_wc.draw_line(pf + Vector2(0, -8), pf + Vector2(0, -30), Color(0.15, 0.14, 0.16), 2.0)
		_wc.draw_arc(pf + Vector2(0, -30), 26.0, PI, TAU, 20, bc, 7.0)
		for r in range(2):
			var rx := fmod(pt * 120.0 + idx * 30.0 + r * 60.0, 120.0)
			_wc.draw_line(pf + Vector2(-24 + rx * 0.4, -28), pf + Vector2(-24 + rx * 0.4, 12), Color(0.6, 0.7, 0.85, 0.4), 1.0)
	# cellar doors, propped open for a delivery: a stone kerb round the
	# hatch, the two steel leaves folded back flat either side (tread plate,
	# hinges), the stair going down into the dark, and the crates waiting on
	# a sack truck beside it
	# (Les Obres keeps its trench in `cellars` too, and draws it itself)
	for c in cellars:
		if lvl == "site" or c.end.y < vt - 40.0 or c.position.y > vb + 40.0:
			continue
		_draw_cellar(c)
	_draw_skids(vt, vb)
	# marked spots, stray puddles and, discreetly, the business
	var pud := Color(0.93, 0.85, 0.4, 0.4)
	# the other dogs' marks: a small damp patch with a faint bloom, in their
	# own colour so you can tell who from across the park
	for nm in npc_marks:
		var nmp: Vector2 = nm.pos
		if nmp.y < vt - 30.0 or nmp.y > vb + 30.0:
			continue
		var nc: Color = nm.col
		_wc.draw_circle(nmp + Vector2(0, 6), 7.0, Color(0.82, 0.78, 0.32, 0.20))
		_wc.draw_circle(nmp + Vector2(0, 6), 3.4, Color(nc.r, nc.g, nc.b, 0.35))
		if not bool(nm.sniffed):
			var np := 0.5 + 0.5 * sin(prize_glow * 0.7 + nmp.x * 0.05)
			_wc.draw_arc(nmp + Vector2(0, 6), 11.0 + np * 3.0, 0, TAU, 14,
				Color(0.9, 0.92, 0.5, 0.12 + np * 0.10), 1.5)
	for mk in marks:
		_wc.draw_circle(mk + Vector2(6, 10), 6.0, pud)
		_wc.draw_circle(mk + Vector2(11, 13), 3.5, pud)
		_wc.draw_circle(mk + Vector2(7, 9), 3.0, Color(0.95, 0.88, 0.5, 0.7))
	for pd in puddles:
		var pr: float = pd.r
		_wc.draw_circle(pd.pos, pr, pud)
		_wc.draw_circle((pd.pos as Vector2) + Vector2(pr * 0.7, pr * 0.4), pr * 0.6, pud)
	if business_spot.x < INF:
		# soft-serve, cartoon rules, nothing gross
		var pcol := Color(0.36, 0.26, 0.16)
		_wc.draw_circle(business_spot, 4.5, pcol)
		_wc.draw_circle(business_spot + Vector2(0, -3), 3.2, pcol.lightened(0.08))
		_wc.draw_circle(business_spot + Vector2(1, -5.5), 1.8, pcol.lightened(0.16))
	for f in bag_flights:
		var e: float = f.t
		var bp: Vector2 = f.from.lerp(f.to, e) + (f.to - f.from).orthogonal().normalized() * sin(e * PI) * 26.0
		_wc.draw_circle(bp, 4.0 + sin(e * PI) * 2.0, Color(0.92, 0.92, 0.95))
	if mark_target.x < INF and mark_progress > 0.0:
		_wc.draw_arc(mark_target, 17.0, -PI / 2.0, -PI / 2.0 + TAU * mark_progress / 0.7, 20, Color(1, 0.95, 0.6), 3.0)
	# the off-leash freedom yard beyond the gate: a proper fenced dog
	# park - grass, chain-link fence with posts, human benches, and a
	# labelled entrance gate
	if vt < GATE_Y + 60.0 and freedom_kind == "beach":
		# only the water moves; the sand and everything on it is on the layer
		_draw_beach_water()
	# the gate between the walk and the off-leash space, when it is in view
	if vt < GATE_Y + 100.0 and vb > GATE_Y - 120.0:
		_draw_gate()
	# centred on the gate mouth, not nudged left by an eyeballed 40px; a walk
	# with a material spells it in pieces instead (build_signs)
	if _sign_mat() == "":
		_wc.draw_string(font, Vector2(gate_l, GATE_Y - 66), gate_text, HORIZONTAL_ALIGNMENT_CENTER,
			gate_r - gate_l, 26, Color(0.9, 0.88, 0.8))
		# the place in Catalan, and what it means under it
		_wc.draw_string(font, Vector2(gate_l, GATE_Y - 46), "OFF LEASH", HORIZONTAL_ALIGNMENT_CENTER,
			gate_r - gate_l, 14, Color(0.9, 0.88, 0.8, 0.75))
	# HOME, at the bottom, where the walk both begins and ends
	if vb > START_Y + 30.0:
		_wc.draw_rect(Rect2(gate_l - 14, HOME_Y + 40.0, gate_r - gate_l + 28, 14), Color(0.4, 0.32, 0.3))
		if signs.is_empty() and started:
			_wc.draw_string(font, Vector2(gate_l, HOME_Y + 78.0), "HOME", HORIZONTAL_ALIGNMENT_CENTER,
				gate_r - gate_l, 24, Color(0.9, 0.85, 0.7))
	# not under the settings panel, the wardrobe or the progress table: the
	# dim only halves it, so the chalked name read straight through (#10)
	var menu_over := in_settings or in_shop or in_progress_view
	if not menu_over and vb > START_Y - 260.0 and (not started or gloss_a > 0.01 or _sign_mat() == ""):
		_draw_ground_title()
	# the signs are the last thing in the world pass, so their canvas sits
	# directly above this one and is told what this pass would have drawn
	var show_signs := not (menu_over and not started)
	if sign_layer != null:
		sign_layer.refresh(vt, vb, show_signs)
	elif show_signs:
		_draw_signs(vt, vb)
