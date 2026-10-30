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
# Artsy Detours (systems/detour.gd): hidden-in-plain-sight side rooms
var detour_door_pos := Vector2.ZERO
var detour_return_pos := Vector2.ZERO
var detour_active := false
var detour_kind := ""
var detour_entered := false
var somni_bone_taken := false
var detour_layer: Node2D = null
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
# Dia de Partit's river, and El Diluvi's two-way stroll (systems/crowd_river.gd).
# Null on every other walk. The push is px/s along the flow from people held
# on a taut cross-leash. The canopy layer is the umbrellas, above the leash.
var match_crowd: CrowdRiver
var match_crowd_layer: Node2D
var match_canopy_layer: Node2D
var match_crowd_push := Vector2.ZERO
# the kick-off clock (systems/match_day.gd). Null on every other walk.
var match_day: MatchDay
# the away column (systems/march.gd). Null on every other walk.
var march: March
var _match_roar := 0.0
var _goal_in := -1.0
var _match_flash := 0.0
var _flare_t := 0.0
var _flare_at := Vector2.ZERO
var terrace_kick := 0.0
var _final_blasts := 0
var _final_gap := 0.0
var _fan_dogs := false
var _out_noise := false
var _out_arrived := false
var _chant_in := 0.0
var kickabout: Kickabout
var lost_scarf: LostScarf
var _tout_said := false
var _fan_pairs := false
var _partit_mark: Node2D
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
# how much heavier a tutorial owner waiting at a lesson is in the tug of war
const TUT_BRACE := 8.0
# Round the pole, not into it: with the rope over a pole beside the owner, the
# pull at their end points almost straight at the pole, and a body pulled into
# a pole just pins there. Within POLE_STEP_R of it, the part of the pull aimed
# into the pole becomes a step round it, the way that unwinds the rope.
const POLE_STEP_R := 48.0
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
const SkyLook := preload("res://systems/sky.gd")
const Arrival := preload("res://systems/arrival.gd")
const HomeChase := preload("res://systems/home_chase.gd")
const CurrentFlow := preload("res://systems/current_flow.gd")
const RunEvents := preload("res://systems/run_events.gd")
const Goals := preload("res://systems/goals.gd")
const TonyHawk := preload("res://systems/tony_hawk.gd")
const TofuRoute := preload("res://systems/tofu_route.gd")
const HudBuild := preload("res://hud/hud_build.gd")
const MenuFlow := preload("res://hud/menu_flow.gd")
const Rails := preload("res://systems/rails.gd")
const Saves := preload("res://systems/saves.gd")
const CableCar := preload("res://systems/cable_car.gd")
const Detour := preload("res://systems/detour.gd")
const Gotic := preload("res://world/gotic.gd")
const Neteja := preload("res://systems/neteja.gd")
const Besos := preload("res://systems/besos.gd")
const Parc := preload("res://systems/parc.gd")
const UiScale := preload("res://hud/ui_scale.gd")
const LevelBuild := preload("res://world/level_build.gd")
const WorldSign := preload("res://world/world_sign.gd")
const PopsLayer := preload("res://world/pops_layer.gd")
const Rambla := preload("res://world/rambla.gd")
# float_text(..., POP_SAY) draws a speech bubble rather than a sound or a score
const POP_SAY := 0
const POLE_RADIUS := 10.0
const TREE_RADIUS := 13.0  # a trunk is stouter than a lamppost
const HYDRANT_RADIUS := 9.0
const FOUNTAIN_RADIUS := 12.0
const PERFORMER_RADIUS := 12.0
const MANHOLE_RADIUS := 24.0
# The dog and your human are on layers that do not collide, so the leash owns
# every pull between them. _part_bodies keeps her from standing inside them:
# each frame it removes this share of the overlap of their two bodies (14 and
# 15 px), and she, the lighter, takes this share of the push while she is on the
# move. They take the rest and what a wall stops her taking, as a step back and
# aside round her; a dog standing still or dug in is not pushed at all.
const BODY_REACH := 29.0
const BODY_PART_RATE := 0.5
const BODY_PART_DOG := 0.75
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
var rope_radii := PackedFloat32Array()
var rope_soft: Array[Vector2] = []
# Solid outlines the strap must go around: stalls, vans, benches, the train.
var rope_rects: Array[Rect2] = []
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
var lvl := "street":
	set(v):
		lvl = v
		walk_mod = WALK_MODULES.get(v)
		walk_surface = walk_mod != null and walk_mod.has_method("surface")
# The walks laid out in their own module (systems/*.gd). Main calls their
# hooks through walk_mod by what the module defines, not by the walk's name:
# build_layer, draw_edge_layer, draw_ground, draw_overhead, draw_freedom,
# draw_live (given the whole view: a module clamps to the gate itself),
# draw_bollard, draw_conveyor, draw_column, draw_clearing, tick, tick_crowd,
# on_bark, surface and grass_blocked; and the scrapyard's draw_verge,
# draw_grove, draw_yard, draw_log_prop, draw_van, draw_top and idle_status;
# El Bosc's draw_scenery, draw_path_edges, draw_snack and draw_trough_prop;
# L'Estacio's draw_freedom_beyond and draw_freedom_ground; and El Barri's
# draw_gate_fence, draw_fountain and draw_performer; and Passeig Maritim's
# draw_cross_section, takes_prints and draw_bin. El Diluvi's arcade pillars
# are draw_column, its panots draw_over_walkway, and El Porxo is
# draw_freedom_beyond and draw_freedom_ground.
# El Mercat's hall is draw_live, its arches draw_overhead, its cast-iron
# columns draw_column, and its greengrocer's van draw_van. La Castanyada's
# street is draw_live, its lights draw_overhead and its festival yard on the
# plaça draw_yard. El Gòtic's module is the El Somni detour, which forwards
# draw_live, draw_overhead, draw_freedom, draw_column and draw_fountain to
# world/gotic.gd. La Neteja and El Parc are draw_live (El Parc's lawns also
# grass_blocked); El Besòs's river is draw_over_walkway and its waymarkers
# draw_bollard. Les Obres (world/obres.gd) is draw_top, draw_van,
# draw_performer and draw_log_prop. La Carretera de les Aigües draws its track
# as draw_cross_section and the slope and city as draw_edge_layer, says its
# margin pines are forest trees with tree_kind, and sends its mountain bikes
# down the middle of the track with rider_lane. El Laberint d'Horta draws its
# gravel, hedges and Eros as draw_cross_section, the gardens round the maze
# as draw_edge_layer, and the gardener's barrow as draw_live.
# The tutorial is laid out on El Barri (lvl "barri"), so El Barri's hooks run
# in it too. tests/test_walk_hooks.gd holds each walk's declared hooks: a new
# hook in a module, or a helper named like one, fails there until declared.
const WALK_MODULES := {
	"montjuic": preload("res://systems/montjuic.gd"),
	"guell": preload("res://systems/mosaic.gd"),
	"scrap": preload("res://world/ferralla.gd"),
	"trail": preload("res://systems/bosc.gd"),
	"station": preload("res://systems/estacio.gd"),
	"barri": preload("res://systems/barri.gd"),
	"oldtown": preload("res://systems/detour.gd"),
	"partit": preload("res://systems/partit.gd"),
	"port": preload("res://systems/port.gd"),
	"reial": preload("res://systems/reial.gd"),
	"vet": preload("res://systems/vet.gd"),
	"tibidabo": preload("res://systems/tibidabo.gd"),
	"aigues": preload("res://systems/aigues.gd"),
	"horta": preload("res://systems/horta.gd"),
	"llevant": preload("res://systems/llevant.gd"),
	"beach": preload("res://systems/passeig.gd"),
	"rain": preload("res://systems/diluvi.gd"),
	"market": preload("res://world/mercat.gd"),
	"site": preload("res://world/obres.gd"),
	"besos": preload("res://systems/besos.gd"),
	"park": preload("res://systems/parc.gd"),
	"neteja": preload("res://systems/neteja.gd"),
	"spook": preload("res://systems/castanyada.gd"),
}
var walk_mod: GDScript = null
var walk_surface := false
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
# solid things against the path's edges (El Mercat's wall stalls and what
# stands between them) that the owner steers wide of before he meets them;
# see human._walk
var owner_keepouts: Array[Rect2] = []
# El Gotic and La Neteja's parked scooters: light enough to topple
var scooters: Array[Vector2] = []
var scooter_falls: Dictionary = {}
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
# street furniture: chair backs catch; A-stands and scooters topple; vans use
# a close outline; performers are people, never rope anchors
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
var mosaic_bays_out := false
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
# the weather's and the hour's changes to the grade (systems/sky.gd)
var sky_mod: Dictionary = SkyLook.NONE
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
# the lesson up can be skipped: event_feed draws its prompt bar
var tut_skippable := false
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
# GOLDEN ZOOMIES: tricks refill the zoomies, and filling them that way turns
# them golden for GOLDEN_S - tricks score double and the grind steadies
const GOLDEN_S := 6.0
const ZOOM_REFILL_PER_PT := 1.0 / 110.0
const ZOOM_REFILL := Vector2(0.05, 0.35)   # the least and most one trick refills
const GOLDEN_EASE := 0.6
var golden_t := 0.0
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
var vault_elapsed := 0.0
var vault_speed_sum := 0.0
# the last swing, for the figure eight: {"pole", "sense"} while it counts
var last_swing: Dictionary = {}
var last_swing_t := 0.0
var needles_done := 0
var needle_cd := 0.0
var needle_prev := Vector2(INF, INF)
var _needle_people: Array[Vector2] = []
var _needle_owner: Array[int] = []
var port_gulls_startled := 0
var port_bollard_wrapped := false
var reial_gaudi_wrapped := false
var reial_fountain_drank := false
var reial_busker_barked := false
var vet_scale_weighed := false
var tibidabo_viewfinder_gazed := false
var tibidabo_funicular_seen := false
# the pole she last vaulted, and whether she has since cleared it. Without
# this she can sit in one pole's orbit re-triggering forever: the autowalk
# stall watchdog caught it, and it would also have been a score exploit
# (unlimited combo points from one lamppost).
var vault_done_pole := Vector2(INF, INF)
const VAULT_TRIGGER_SPEED := 200.0
const VAULT_MIN_SPEED := 210.0
const VAULT_MAX_SPEED := 430.0
const VAULT_LAUNCH := 470.0
# the swing takes the zoomies to start, so it is never an accident; holding
# them keeps it going (its clock runs at VAULT_HELD speed) up to VAULT_MAX_T,
# and a fast swing pays up to VAULT_SPEED_PAY times more
const VAULT_HELD := 0.35
const VAULT_MAX_T := 2.4
const VAULT_SPEED_PAY := 1.6
# FIGURE EIGHT: two swings, opposite ways round two posts at least
# FIG8_APART apart, the second ending within FIG8_WINDOW of the first
const FIG8_WINDOW := 3.0
const FIG8_APART := 40.0
const FIG8_PTS := 60
# THREAD THE NEEDLE: a dash between two people standing NEEDLE_GAP apart
const NEEDLE_GAP := Vector2(26.0, 96.0)
const NEEDLE_SPEED := 250.0
const NEEDLE_PTS := 25
const NEEDLE_CD := 1.5
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
# the profile HomeChase.begin started this chase with; empty until it begins
var chase_profile: Dictionary = {}
# the closest the machine has come to the dog or the human this chase (px);
# INF until it starts. The "outrun" goal reads it.
var chase_min_gap := INF
# seconds left of the catch beat: the machine rolls over whoever it caught
# before the card comes up (systems/home_chase.gd)
var chase_catch_t := 0.0
var chase_catch_msg := ""
var chase_catch_first := ""
var chase_catch_elapsed := 0.0
# how far the camera leans back up the street to keep the machine in shot
var chase_lean := 0.0
# the arrival home (systems/arrival.gd): the walk freezes at the threshold
# and the pair is played into the door before the card
var arriving := false
var arrival_t := 0.0
var depart_open := 0.0
var depart_hold := 0.0
var arrival_at := Vector2(INF, INF)
var arrival_prints := PackedVector2Array()
var arrival_print_n := 0
# the brooms have come within a whisker; getting clear again is a CLOSE SHAVE
var chase_shave_armed := false
# where the walk home is (systems/home_chase.gd): "" until it begins, then
# "warning", "head_start", "chase", or "hold" after a midpoint continue; and
# the seconds left of a held phase
var chase_phase := ""
var chase_phase_t := 0.0
# the latest checkpoint's snapshot (systems/chase_checkpoint.gd), run-local
# and never saved
var chase_checkpoint: Dictionary = {}
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
	"stinky":  {"col": Color(0.28, 0.22, 0.12), "life": 2.4, "quip": "STINKY PAWS!"},
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
const SPRAY_LIFE := 0.6
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
# Tony Hawk quests: spell a word, secret tape, beat-the-clock
var spell_word := ""
var word_letters: Array = []
var word_letters_collected := 0
var jamon_pos := Vector2(INF, INF)
var jamon_found := false
var clock_target := 75
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
var epilogue_stage: Node2D
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
# the gloss under the name is menu text: it fades as the walk begins, however
# it began (the menus, a command line, a test), over GLOSS_FADE seconds
var gloss_a := 1.0
const GLOSS_FADE := 1.2
# a walk's name on the ground: its cap height, and the bottom of the name as
# laid out (one line or two), which the gloss sits under
const NAME_H := 52.0
# its baseline: high enough that a full-width name clears the top of the GET
# READY panel and the walk select's plaque, low enough to miss the header
const NAME_Y := START_Y - 227.0
const NAME_MARGIN := 60.0
# and no wider than this, however wide the walk: a wide avenue's name breaks
# onto two lines rather than spanning its sidewalks
const NAME_MAX_W := 400.0
# on GET READY the panel covers the screen's left: the gloss keeps this far
# from the screen's left edge (screen px at zoom 1)
const GLOSS_CLEAR_X := 476.0
var _name_baseline := 0.0
# the gloss's cap line sits this far under the name's last baseline, the same
# on every walk whatever size the name came out
const GLOSS_GAP := 34.0
var details_idx := 0
var pause_idx := 0
# the main menu's cursor, and the first-time question's (hud/menu_flow.gd)
var main_idx := 0
var first_idx := 0
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
# what a dare pays (start_challenge): a base and a bit a trick, so the
# harder dares up the giver's ladder pay more, and a dare tried again pays
# what it paid the first time
const DARE_BASE := 20
const DARE_PER_TRICK := 3
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
var run_seed := 0
var bosc_high_stream := false
var stream_find: Node2D
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
	if "--free-play" in OS.get_cmdline_user_args():
		Game.free_play = true
	_shake_rng.seed = SHAKE_SEED
	if Game.is_tutorial(Game.level_id):
		# THE FIRST WALK: El Barri laid out as one station per lesson, calm and
		# safe by construction - no traffic to dodge, no chase, no other
		# walkers, and a bright clear day. Nothing here can end your walk.
		tutorial_mode = true
		lvl = "barri"
	else:
		# Recorded for the rainy-stream hash. A normal launch keeps the engine
		# RNG: reseeding from the clock here changes every later randf, and
		# the park-traffic regression depends on that sequence.
		run_seed = int(Time.get_ticks_usec() & 0x7fffffff)
		if autowalk_requested:
			# The named call stays here: the route regression reads this source.
			run_seed = AUTOWALK_SEED
			seed(AUTOWALK_SEED)
		lvl = Game.level_id
	# --seed=N pins every random layout and spawn, so a soak or a bug report
	# can be replayed exactly, and a screenshot of any walk, the tutorial's
	# too, comes out the same every time. It wins over the autowalk seed.
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--seed="):
			run_seed = int(a.substr(7))
			seed(run_seed)
	Game.apply_walk_sky(Game.level_id)
	bosc_high_stream = RunEvents.chosen(run_seed, lvl, "high_stream", Game.weather, 20)
	_setup_input()
	_build_level_data()
	_build_bypasser_blockers()
	_build_walls()
	Rails.build(self)
	_build_entities()
	if walk_mod != null and walk_mod.has_method("build_layer"):
		walk_mod.build_layer(self)
	_spawn_cones()
	_spawn_stream_find()
	TonyHawk.setup_walk(self)
	_build_quests()
	UiScale.apply(self)
	get_tree().root.size_changed.connect(_on_window_resized)
	_build_hud()
	_pops_layer().add_speaker(human, _human_speech)
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
	apply_sky()
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
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--goal-in="):
			_goal_in = maxf(0.0, float(a.trim_prefix("--goal-in=")))
	if match_day != null and _goal_in >= 0.0:
		match_day.force_in = _goal_in
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
	# the apartment door is open behind them; headless runs are already in the
	# walk, so it starts to shut on the next frames
	begin_departure()
	# "try again" and "start again" come straight back into the walk
	if Game.quick_start:
		Game.quick_start = false
		MenuFlow.start_walk(self)
	# --at-freedom drops her straight into the off-leash space. Walking there
	# takes half a minute of real time per look, which is no way to iterate on
	# how the dog beach or the clearing is drawn.
	if "--at-home" in OS.get_cmdline_user_args():
		start_at_home()
	elif "--at-freedom" in OS.get_cmdline_user_args():
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


# --at-home: the selected walk started already turned for home, south of the
# gate, whatever the star gate says, so a locked walk's chase can be played.
# Nothing from it reaches the save. On a chase walk the destination
# checkpoint, the warning and the head start follow as they would anyway.
func start_at_home() -> void:
	Game.persist = false
	MenuFlow.start_walk(self)
	var hy := GATE_Y + 700.0
	var he := walk_edges(hy)
	var hx := (he.x + he.y) * 0.5
	dog.global_position = Vector2(hx + 30.0, hy - 60.0)
	human.global_position = Vector2(hx - 20.0, hy + 40.0)
	cam.position = dog.global_position
	leash.resnap()
	depart_open = 0.0
	_enter_home()


# a small screen gets a bigger interface, the same walk (hud/ui_scale.gd)
func _on_window_resized() -> void:
	UiScale.apply(self)


# the soundtrack: the loop that belongs on screen now (see Sfx.music_tick)
func _music_cue() -> String:
	if intro_playing:
		return "intro"
	if not started:
		return "title"
	if finished:
		return "won"
	# frozen and not paused, mid-walk: a card the walk ended on
	if frozen and not paused:
		return "lost"
	if phase == "freedom":
		return "freedom"
	# a dare: quiet while she gets ready (the count-in), then the giver's own
	# tune while the clock runs
	if challenge != null and is_instance_valid(challenge_giver):
		if challenge.phase == "offer" and not challenge.waiting:
			return ""
		if challenge.phase == "live":
			return "dare_" + String(challenge_giver.who)
	return Music.walk_style(lvl)


# how much faster a dare's tune plays: 1 until its last HURRY_S, then up to
# DARE_HURRY by the end of the clock
const HURRY_S := 5.0
const DARE_HURRY := 1.12


func _dare_tempo() -> float:
	if challenge == null or challenge.phase != "live":
		return 1.0
	return lerpf(1.0, DARE_HURRY, clampf(1.0 - float(challenge.timer) / HURRY_S, 0.0, 1.0))


# ...and the one to have ready for when it changes
func _music_next() -> String:
	# the phrase is playing and the full title theme is the one being built
	if intro_playing:
		return "title"
	if not started:
		return Music.walk_style(lvl)
	if phase == "freedom":
		return Music.walk_style(lvl)
	# a dare on offer: its tune, ready for when she takes it
	if challenge != null and challenge.phase == "offer" and is_instance_valid(challenge_giver):
		return "dare_" + String(challenge_giver.who)
	return "freedom" if phase != "home" else ""


func _input(event: InputEvent) -> void:
	# the prompts follow whichever device the player last used; text set once
	# (the pause menu, a death card) is re-filled, and the title's is rebuilt
	if Prompts.note(event):
		Prompts.refresh()
	if in_settings and Game.rebind_step >= 0:
		MenuFlow.rebind_input(self, event)


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
		"pee": [KEY_Q, JOY_BUTTON_X], "poop": [KEY_F, JOY_BUTTON_Y],
		"pickup": [KEY_G, JOY_BUTTON_LEFT_SHOULDER],
		"turbo": [KEY_SHIFT, JOY_BUTTON_RIGHT_SHOULDER],
		"restart": [KEY_R, JOY_BUTTON_START], "share": [KEY_C, JOY_BUTTON_DPAD_RIGHT],
		"pause": [KEY_ESCAPE, JOY_BUTTON_BACK], "mute_music": [KEY_M, JOY_BUTTON_DPAD_DOWN],
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
	Game.apply_control_layout()


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
		"rain":
			# laid square under El Diluvi's panots, two to a slab each way, so
			# the slabs' tone and the tiles' joints agree (Diluvi.PANOT)
			sw = 80.0
			sh = 80.0
			stagger = 0.0
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
	if walk_mod != null and walk_mod.has_method("draw_edge_layer"):
		# the walk's own ground, sidewalks and blocks, in its module
		walk_mod.draw_edge_layer(self, c, vt, vb)
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
		# El Gòtic's slices end exactly at the plaça's edge, so the last one
		# does not paint masonry over the square's bottom row of paving
		var phase := fposmod(GATE_Y - 30.0, slice) if lvl == "oldtown" or lvl == "neteja" else 0.0
		var sy := floorf((vt - 320.0 - phase) / slice) * slice + phase
		while sy < vb + 320.0:
			# past the gate the off-leash space draws its own surroundings:
			# the street's buildings stop at the gate, not halfway across it
			if sy + slice <= GATE_Y - 30.0:
				sy += slice
				continue
			var f := frontage(sy + slice * 0.5)
			var fl := f.x
			var fr := f.y
			var has_r := lvl != "besos"
			c.draw_rect(Rect2(fl - far, sy, far, slice), base)
			if has_r:
				c.draw_rect(Rect2(fr, sy, far, slice), base)
			# Les Obres' line is a fence, not a building: no wall face, no cast
			if lvl == "site":
				sy += slice
				continue
			# Seen from directly overhead you do not see a facade at all - you
			# see the ROOF. The roof is inset from its footprint and the gap
			# becomes a visible WALL FACE, angled toward the viewer: dark at the
			# base, lighter up the wall, with a bright cap along the roof edge.
			for i in range(7):
				var t := float(i) / 6.0
				c.draw_rect(Rect2(fl - face + face * t, sy, face / 6.0 + 1.0, slice), base.darkened(0.52 - t * 0.34))
				if has_r:
					c.draw_rect(Rect2(fr + face - face * t - face / 6.0 - 1.0, sy, face / 6.0 + 1.0, slice), base.darkened(0.56 - t * 0.34))
			c.draw_rect(Rect2(fl - face - 5.0, sy, 5.0, slice), base.lightened(0.30))
			if has_r:
				c.draw_rect(Rect2(fr + face, sy, 5.0, slice), base.lightened(0.24))
			# the light is up-and-left, so the LEFT block throws a shadow out
			# across the ground; the right block throws its own away from us
			for i in range(6):
				var t := float(i) / 5.0
				c.draw_rect(Rect2(fl, sy, cast * (1.0 - t * 0.82), slice), Color(0.05, 0.04, 0.07, 0.055))
			if has_r:
				for i in range(3):
					var g := float(i) / 2.0
					c.draw_rect(Rect2(fr - 11.0 * (1.0 - g), sy, 11.0 * (1.0 - g), slice), Color(0.05, 0.04, 0.07, 0.05))
			sy += slice
	if lvl == "oldtown" or lvl == "neteja":
		Gotic.draw_roofs(self, c, vt, vb)
	# the roof sits BACK from the kerb by the depth of the wall face drawn
	# above, otherwise the roof clutter would be painted over the wall
	var inset := 27.0 if built else 0.0
	var y := floorf((vt - mod) / mod) * mod
	while y < vb + mod:
		if y + mod * 0.5 < GATE_Y:
			y += mod
			continue
		for side in [-1.0, 1.0]:
			if lvl == "besos" and side > 0.0:
				continue
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
		"neteja": return Color(0.40, 0.32, 0.28)             # warm stone, dawn
		"besos": return Color(0.58, 0.56, 0.52)              # the concrete flood wall
		"station": return Color(0.48, 0.48, 0.52)            # tiled interior
		"site": return Obres.YARD                            # the works compound
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


# La Neteja's open shops (systems/neteja.gd); tests ask main
func _neteja_open_shop(y: float, side: float) -> bool:
	return Neteja.open_shop(y, side)


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
		"besos":
			Besos.draw_wall_module(self, c, r, k, inner_x)
		"neteja":
			Neteja.draw_module(self, c, r, side, k, inner_x)
		"guell":
			# beyond the terrace wall, the park's garden on the hillside: dry
			# ground, stone pines and carobs, agaves, all of it out to the frame
			var gx: float = r.position.x - 440.0 if side < 0.0 else r.end.x
			c.draw_rect(Rect2(gx, r.position.y, 440.0, r.size.y), Mosaic.HILL_SCRUB)
			for gi in range(9):
				var gh := fmod(absf(sin(float(k * 11 + gi) * 12.9898) * 43758.5453), 1.0)
				var gp := Vector2(gx + 30.0 + fmod(float(gi) * 97.0 + gh * 60.0, 380.0), r.position.y + fmod(float(gi) * 61.0 + gh * 40.0, r.size.y))
				if gi % 3 == 2:
					for f in range(7):
						c.draw_line(gp, gp + Vector2.from_angle(float(f) * TAU / 7.0 + gh) * 15.0, Color(0.44, 0.58, 0.54), 4.0)
					continue
				var gr := 26.0 + gh * 18.0
				c.draw_circle(gp + LIGHT * 10.0, gr, Color(0.12, 0.14, 0.08, 0.45))
				c.draw_circle(gp, gr, Color(0.22, 0.34, 0.18) if gi % 3 == 0 else Color(0.30, 0.40, 0.20))
				c.draw_circle(gp - LIGHT * gr * 0.3, gr * 0.45, Color(0.34, 0.46, 0.24))
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
			# the works compound behind the Heras fence (world/obres.gd)
			Obres.draw_yard_module(self, c, r, side, k)
		"rain":
			_draw_diluvi_roofs(c, r, side, k, inner_x)
			_draw_edge_awning(c, r, side, k, inner_x)
			_draw_doorway(c, inner_x, side, r.position.y + 168.0, Color(0.48, 0.30, 0.22))
		"scrap":
			# corrugated shed roofs, rusting, with junk heaps between them
			var iron := Color(0.40, 0.38, 0.35).lightened(lit * 0.09)
			c.draw_rect(r, iron)
			var rib := r.position.x
			while rib < r.end.x:
				c.draw_line(Vector2(rib, r.position.y), Vector2(rib, r.end.y), iron.darkened(0.22), 2.0)
				c.draw_line(Vector2(rib + 4.0, r.position.y), Vector2(rib + 4.0, r.end.y), iron.lightened(0.16), 1.5)
				rib += 11.0
			# rust streaking down from the ridge, every roof its own
			Ferralla.draw_roof_rust(c, r, inner_x, side, k)
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
			_draw_edge_awning(c, r, side, k, inner_x)
			_draw_doorway(c, inner_x, side, r.position.y + 168.0, felt)


# the awning: projects over the pavement, so it reads correctly from
# overhead, and throws a shadow onto the paving below it
func _draw_edge_awning(c: Object, r: Rect2, side: float, k: int, inner_x: float) -> void:
	if k % 2 != 0:
		return
	var ac := Color(0.72, 0.3, 0.28) if k % 4 == 0 else Color(0.28, 0.42, 0.55)
	var aw_x: float = inner_x if side < 0.0 else inner_x - 34.0
	c.draw_rect(Rect2(aw_x, r.position.y + 44.0, 34.0, 76.0), Color(0.05, 0.04, 0.07, 0.16))
	c.draw_rect(Rect2(aw_x, r.position.y + 40.0, 30.0, 72.0), ac)
	for st in range(4):
		c.draw_line(Vector2(aw_x + 7.0 * float(st), r.position.y + 40.0),
			Vector2(aw_x + 7.0 * float(st), r.position.y + 112.0), ac.lightened(0.30), 3.0)


# EL DILUVI's roofs, wet: from the gutter at the street out to the edge of the
# view, a pitched pantile roof or a flat terrat (tiled, parapeted, a water
# tank or two on it, rain standing in the low corner), then the next block
# behind it. The gutters along the eaves run with water; the downpipes come
# down at the party walls.
func _draw_diluvi_roofs(c: Object, r: Rect2, side: float, k: int, inner_x: float) -> void:
	var out := side                  # away from the street
	var lit := fmod(float(k) * 0.37, 1.0)
	var y0 := r.position.y
	var h := r.size.y
	# the front block and the one behind it: alternate kinds, so a pantile
	# roof never sits beside another of the same lot
	var front_pitched := (k % 3) != 1
	_diluvi_roof_lot(c, _diluvi_span(inner_x, out, 0.0, 150.0, y0, h), out, k, lit, front_pitched, true)
	_diluvi_roof_lot(c, _diluvi_span(inner_x, out, 150.0, 420.0, y0, h), out, k + 5, lit * 0.7, not front_pitched, false)
	# the party wall between this module and the next: a low brick coping
	var pw := _diluvi_span(inner_x, out, 0.0, 420.0, y0, h)
	c.draw_rect(Rect2(pw.position.x, y0 - 3.0, pw.size.x, 6.0), Color(0.46, 0.34, 0.28))
	c.draw_rect(Rect2(pw.position.x, y0 - 3.0, pw.size.x, 2.0), Color(0.58, 0.46, 0.38))
	c.draw_rect(Rect2(pw.position.x, y0 + 3.0, pw.size.x, 5.0), Color(SHADOW_COL.r, SHADOW_COL.g, SHADOW_COL.b, 0.22))
	# the street gutter along the eave, brimming, and its downpipe at the
	# party wall
	var gx := inner_x + out * 4.0
	c.draw_rect(Rect2(gx - 4.0, y0, 8.0, h), Color(0.50, 0.53, 0.56))
	c.draw_rect(Rect2(gx - 2.5, y0, 5.0, h), Color(0.40, 0.52, 0.64))
	var wy := y0 + fmod(float(k) * 17.0, 30.0)
	while wy < y0 + h - 12.0:
		c.draw_line(Vector2(gx, wy), Vector2(gx, wy + 10.0), Color(0.78, 0.86, 0.94, 0.7), 1.5)
		wy += 26.0
	c.draw_circle(Vector2(gx, y0 + 8.0), 5.0, Color(0.56, 0.58, 0.60))
	c.draw_circle(Vector2(gx, y0 + 8.0), 3.0, Color(0.22, 0.26, 0.30))


# the strip of a roof module from d0 to d1 out from the street
static func _diluvi_span(inner_x: float, out: float, d0: float, d1: float, y0: float, h: float) -> Rect2:
	var a := inner_x + out * d0
	var z := inner_x + out * d1
	return Rect2(minf(a, z), y0, absf(z - a), h)


# one roof lot of El Diluvi's blocks: `out` points away from the street
func _diluvi_roof_lot(c: Object, lot: Rect2, out: float, k: int, lit: float, pitched: bool, front: bool) -> void:
	if pitched:
		# pantiles, wet and dark, the courses running down the slope to the
		# eave each side of the ridge, a sheen where the rain sheets off
		var tile: Color = [Color(0.50, 0.28, 0.20), Color(0.56, 0.32, 0.22), Color(0.46, 0.27, 0.21)][k % 3]
		tile = tile.lightened(lit * 0.06)
		c.draw_rect(lot, tile)
		var ridge := lot.get_center().x
		# the slope facing away from the light is the darker one
		c.draw_rect(Rect2(ridge, lot.position.y, lot.end.x - ridge, lot.size.y), tile.darkened(0.12))
		var ty := lot.position.y + 4.0
		while ty < lot.end.y:
			c.draw_line(Vector2(lot.position.x + 2.0, ty), Vector2(lot.end.x - 2.0, ty), tile.darkened(0.30), 2.0)
			c.draw_line(Vector2(lot.position.x + 2.0, ty + 3.0), Vector2(lot.end.x - 2.0, ty + 3.0), tile.lightened(0.12), 1.0)
			ty += 9.0
		c.draw_rect(Rect2(ridge - 4.0, lot.position.y, 8.0, lot.size.y), tile.lightened(0.16))
		c.draw_rect(Rect2(ridge - 1.0, lot.position.y, 2.0, lot.size.y), tile.darkened(0.20))
		for si in range(3):
			var sy := lot.position.y + 30.0 + float((k * 7 + si * 61) % int(maxf(lot.size.y - 60.0, 1.0)))
			c.draw_rect(Rect2(lot.position.x + 6.0, sy, lot.size.x - 12.0, 3.0), Color(0.80, 0.86, 0.94, 0.12))
		# a chimney, or a skylight let into the slope
		if k % 2 == 0:
			var cp := Vector2(ridge + out * 22.0, lot.position.y + 60.0 + float(k % 4) * 24.0)
			c.draw_rect(Rect2(cp + Vector2(-9.0, -9.0) + LIGHT * 8.0, Vector2(18, 18)), Color(SHADOW_COL.r, SHADOW_COL.g, SHADOW_COL.b, 0.3))
			c.draw_rect(Rect2(cp - Vector2(9, 9), Vector2(18, 18)), Color(0.58, 0.44, 0.36))
			c.draw_rect(Rect2(cp - Vector2(9, 9), Vector2(18, 4)), Color(0.68, 0.56, 0.48))
			c.draw_circle(cp, 4.0, Color(0.16, 0.14, 0.14))
		elif front:
			var sk := Rect2(ridge - out * 44.0 - 13.0, lot.position.y + 120.0, 26.0, 36.0)
			c.draw_rect(sk.grow(3.0), tile.darkened(0.35))
			c.draw_rect(sk, Color(0.88, 0.83, 0.52, 0.85) if Game.night else Color(0.46, 0.56, 0.64))
			c.draw_rect(Rect2(sk.position.x + 3.0, sk.position.y + 3.0, 6.0, sk.size.y - 6.0), Color(1, 1, 1, 0.16))
		return
	# a terrat: pale tiles inside a parapet, puddled after the rain
	var flag := Color(0.62, 0.56, 0.50).lightened(lit * 0.05)
	c.draw_rect(lot, flag.darkened(0.35))
	var floor_r := lot.grow(-6.0)
	c.draw_rect(floor_r, flag)
	var gx := floor_r.position.x + 18.0
	while gx < floor_r.end.x:
		c.draw_line(Vector2(gx, floor_r.position.y), Vector2(gx, floor_r.end.y), flag.darkened(0.12), 1.0)
		gx += 18.0
	var gy := floor_r.position.y + 18.0
	while gy < floor_r.end.y:
		c.draw_line(Vector2(floor_r.position.x, gy), Vector2(floor_r.end.x, gy), flag.darkened(0.12), 1.0)
		gy += 18.0
	# the parapet's shadow on the light side
	c.draw_rect(Rect2(floor_r.position.x, floor_r.position.y, floor_r.size.x, 8.0), Color(SHADOW_COL.r, SHADOW_COL.g, SHADOW_COL.b, 0.16))
	c.draw_rect(Rect2(floor_r.position.x, floor_r.position.y, 8.0, floor_r.size.y), Color(SHADOW_COL.r, SHADOW_COL.g, SHADOW_COL.b, 0.14))
	# rain standing round the roof drain in the low corner
	var low := Vector2(floor_r.end.x - 34.0 if out > 0.0 else floor_r.position.x + 34.0, floor_r.end.y - 34.0)
	c.draw_colored_polygon(ellipse_pts(low, 30.0, 18.0, 12), Color(0.40, 0.50, 0.60, 0.55))
	c.draw_colored_polygon(ellipse_pts(low + Vector2(-6.0, -4.0), 12.0, 6.0, 8), Color(0.80, 0.88, 0.96, 0.25))
	c.draw_circle(low, 3.0, Color(0.20, 0.20, 0.22))
	# the water tanks: drums on a frame, lids on
	var tanks := 2 if front else 1 + k % 2
	for ti in range(tanks):
		var tp := Vector2(lot.get_center().x + (float(ti) - float(tanks - 1) * 0.5) * 40.0,
			lot.position.y + 46.0 + float((k * 29) % 50))
		c.draw_circle(tp + LIGHT * 10.0, 16.0, Color(SHADOW_COL.r, SHADOW_COL.g, SHADOW_COL.b, 0.30))
		c.draw_rect(Rect2(tp - Vector2(17, 17), Vector2(34, 34)), Color(0.36, 0.34, 0.32))
		c.draw_circle(tp, 15.0, Color(0.80, 0.80, 0.78))
		c.draw_circle(tp - LIGHT * 3.0, 11.0, Color(0.90, 0.90, 0.88))
		c.draw_circle(tp, 6.0, Color(0.56, 0.58, 0.60))
		c.draw_circle(tp - LIGHT * 1.0, 4.0, Color(0.70, 0.72, 0.74))
	# the stair head: a little hut with its door onto the roof
	if front and k % 2 == 1:
		var sh := Rect2(lot.get_center().x - 18.0, lot.end.y - 70.0, 36.0, 44.0)
		c.draw_rect(Rect2(sh.position + LIGHT * 9.0, sh.size), Color(SHADOW_COL.r, SHADOW_COL.g, SHADOW_COL.b, 0.28))
		c.draw_rect(sh, Color(0.70, 0.64, 0.56))
		c.draw_rect(Rect2(sh.position.x, sh.position.y, sh.size.x, 5.0), Color(0.80, 0.75, 0.68))


func _build_verge() -> void:
	LevelBuild.build_verge(self)


func draw_verge_onto(c: Object, vt: float, vb: float) -> void:
	# On the cached edge canvas, NOT the per-frame world draw. A lawn does not
	# move, and the edge treatment was already more than half the frame once
	# before it was moved off it (see edgelayer.gd) - putting picnics into the
	# 30-times-a-second draw is exactly how a walk starts to stutter.
	_draw_grass_detail(c, vt, vb)
	# Les Obres' Heras fence stands on the building line, so it goes on this
	# canvas, above the sidewalk its feet and shadow lie on
	if lvl == "site":
		Obres.draw_fence(self, c, vt, vb)
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
	if walk_mod != null and walk_mod.has_method("grass_blocked") and walk_mod.grass_blocked(self, p):
		return true
	# the tutorial's lessons sit on El Barri's square, whatever walk is loaded
	if tutorial_mode and Barri.grass_blocked(self, p):
		return true
	for r: Rect2 in solid_rects:
		if r.grow(6.0).has_point(p):
			return true
	# the brink lesson's pond is water, banks included: no grass grows on it
	if tutorial_mode and LevelBuild.tutorial_pond(self).grow(14.0).has_point(p):
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
				if walk_mod != null and walk_mod.has_method("draw_verge"):
					# the scrapyard: oily gravel along the fences, the odd weed, never a lawn
					walk_mod.draw_verge(self, c, p, h)
					x += GRASS_STEP
					continue
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
	if not jamon_found and jamon_pos.x < INF:
		out.append({"pos": jamon_pos, "col": Color(1.0, 0.78, 0.28)})
	for l: Dictionary in word_letters:
		if not bool(l.collected):
			out.append({"pos": l.pos, "col": Color(1.0, 0.88, 0.28)})
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


const BROADLEAF_LOBES: Array[Vector2] = [
	Vector2(-0.42, -0.30), Vector2(0.40, -0.34), Vector2(0.46, 0.32),
	Vector2(-0.38, 0.40), Vector2(0.02, -0.06),
]


func _draw_broadleaf(c: Object, p: Vector2, scale: float) -> void:
	# A tree from above is a canopy, and a canopy is not one flat circle: it
	# is clustered lobes with light on the top-left of each one, a trunk you
	# can see through the gaps, and a shadow the same shape as the crown. The
	# old version was two translucent discs.
	_broadleaf_ground(c, p, scale)
	var crown := ShapeBatch.new()
	_broadleaf_crown(crown, p, scale)
	crown.flush(c)


# what of a broadleaf lies on the ground: the crown's shadow, thrown clear of
# the trunk so the tree stands up
func _broadleaf_ground(c: Object, p: Vector2, scale: float) -> void:
	var r := 34.0 * scale
	c.draw_set_transform(p + LIGHT * (46.0 * scale), 0.0, Vector2(1.1, 0.55))
	c.draw_circle(Vector2.ZERO, r * 1.02, Color(SHADOW_COL.r, SHADOW_COL.g, SHADOW_COL.b, 0.17))
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# the trunk: on the ground pass too, so a faded crown still stands on solid wood
func _broadleaf_trunk(b: Object, p: Vector2, scale: float) -> void:
	b.circle(p, 6.5 * scale, Color(0.22, 0.16, 0.11))
	b.circle(p + Vector2(-1, -1) * scale, 4.4 * scale, Color(0.36, 0.27, 0.18))


# a broadleaf's crown, into a batch (the canopy layer draws it over everyone);
# `trunk` false for a faded crown, whose trunk shows from the ground pass
func _broadleaf_crown(crown: ShapeBatch, p: Vector2, scale: float, trunk := true) -> void:
	var r := 34.0 * scale
	var dark := Color(0.15, 0.27, 0.16)
	var mid := Color(0.21, 0.36, 0.20)
	var lit := Color(0.31, 0.48, 0.26)
	# The underside, then a solid crown, then lobes only on the lit side. Lobes
	# ringed evenly around the centre left a dark hole in the middle and the
	# canopy read as a doughnut.
	crown.circle(p + Vector2(2, 3) * scale, r, dark)
	crown.circle(p - LIGHT * r * 0.10, r * 0.86, mid)
	for lv: Vector2 in BROADLEAF_LOBES:
		crown.circle(p + lv * r, r * 0.50, mid)
	# the light falls on the upper-left of the crown, so only those lobes catch
	for lv: Vector2 in BROADLEAF_LOBES:
		if lv.dot(LIGHT) > 0.10:
			continue          # this lobe is on the shaded side
		crown.circle(p + lv * r - LIGHT * r * 0.14, r * 0.34, lit)
	crown.circle(p - LIGHT * r * 0.42, r * 0.30, lit.lightened(0.08))
	# the trunk, visible in the middle where the canopy parts
	if trunk:
		_broadleaf_trunk(crown, p, scale)
	# a few leaf tips breaking the outline, so it is not a perfect circle
	for i in range(7):
		var a := TAU * float(i) / 7.0 + p.x * 0.013
		crown.circle(p + Vector2.from_angle(a) * r * 0.95, r * 0.17, mid)


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
	_forest_ground(c, p, i)
	var crown := ShapeBatch.new()
	_forest_crown(crown, p, i)
	crown.flush(c)


# what of a forest tree lies on the ground: roots out across the trail from a
# trunk at its edge, and the crown's shadow
func _forest_ground(c: Object, p: Vector2, i: int) -> void:
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
		_broadleaf_ground(c, p, 0.85)   # holm oak
		return
	c.draw_set_transform(p + LIGHT * 52.0, 0.0, Vector2(1.15, 0.55))
	c.draw_circle(Vector2.ZERO, 40.0, Color(SHADOW_COL.r, SHADOW_COL.g, SHADOW_COL.b, 0.18))
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# a forest tree's crown: a holm oak, or a stone pine's umbrella of needles on
# its red trunk
func _forest_crown(crown: ShapeBatch, p: Vector2, i: int, trunk := true) -> void:
	if i % 3 == 1:
		_broadleaf_crown(crown, p, 0.85, trunk)
		return
	var r := 40.0
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
	if trunk:
		_pine_trunk(crown, p)


func _pine_trunk(b: Object, p: Vector2) -> void:
	b.circle(p, 6.0, Color(0.42, 0.22, 0.14))
	b.circle(p + Vector2(-1, -1), 3.6, Color(0.58, 0.33, 0.20))


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


# parked scooters, El Gotic's and La Neteja's: Vespas, nose up the alley.
# From above a Vespa is its bodywork: the round rear cowls wider than the
# saddle, a narrow floorboard, the curved leg shield, the mudguard over the
# front wheel and the handlebars with the headlamp in them.
const VESPA_COLS: Array[Color] = [Color(0.72, 0.16, 0.14), Color(0.90, 0.87, 0.78), Color(0.56, 0.76, 0.72)]


func _draw_scooters(b: ShapeBatch, vt: float, vb: float) -> void:
	for sc: Vector2 in scooters:
		if sc.y < vt - 60.0 or sc.y > vb + 60.0:
			continue
		var tipped: Vector2 = scooter_falls.get(sc, Vector2.ZERO)
		if tipped != Vector2.ZERO:
			var scale := Vector2(1.5, 0.88)
			b.draw_set_transform(sc + tipped * 8.0 - sc * scale, 0.0, scale)
		var c: Color = VESPA_COLS[int(absf(sc.y)) % 3]
		var lo := c.darkened(0.24)
		var hi := c.lightened(0.24)
		var tyre := Color(0.10, 0.10, 0.11)
		var chrome := Color(0.80, 0.82, 0.84)
		b.polygon(oval_pts(sc + Vector2(5.0, 8.0), 13.0, 29.0), Color(0, 0, 0, 0.2))
		# the wheels, showing only fore and aft of the bodywork
		b.rect(Rect2(sc.x - 3.0, sc.y - 32.0, 6.0, 12.0), tyre)
		b.rect(Rect2(sc.x - 3.0, sc.y + 18.0, 6.0, 10.0), tyre)
		# the rear: two side cowls, bulging past the saddle, lit on the left
		b.polygon(oval_pts(sc + Vector2(0.0, 11.0), 11.5, 14.5), lo)
		b.polygon(oval_pts(sc + Vector2(-0.8, 10.4), 10.4, 13.4), c)
		b.polygon(oval_pts(sc + Vector2(-6.0, 9.0), 3.0, 8.0), hi)
		# the floorboard and its rubber strips
		b.rect(Rect2(sc.x - 6.5, sc.y - 13.0, 13.0, 13.0), Color(0.30, 0.30, 0.32))
		for k in range(3):
			var fy := sc.y - 10.5 + float(k) * 4.0
			b.line(Vector2(sc.x - 5.0, fy), Vector2(sc.x + 5.0, fy), Color(0.16, 0.16, 0.18), 1.4)
		# the leg shield, curved across the front
		b.polygon(PackedVector2Array([sc + Vector2(-11.5, -11.0), sc + Vector2(-10.0, -16.5),
			sc + Vector2(-5.0, -19.5), sc + Vector2(5.0, -19.5), sc + Vector2(10.0, -16.5),
			sc + Vector2(11.5, -11.0), sc + Vector2(8.0, -12.5), sc + Vector2(-8.0, -12.5)]), c)
		b.line(sc + Vector2(-10.0, -16.5), sc + Vector2(-5.0, -19.5), hi, 1.6)
		b.line(sc + Vector2(-5.0, -19.5), sc + Vector2(5.0, -19.5), hi, 1.6)
		# the mudguard over the front wheel
		b.polygon(oval_pts(sc + Vector2(0.0, -23.0), 4.6, 6.5), c)
		b.polygon(oval_pts(sc + Vector2(-1.2, -24.0), 2.0, 3.8), hi)
		# the saddle, long and dark, and the chrome rack behind it
		b.polygon(oval_pts(sc + Vector2(0.0, 6.5), 5.6, 11.5), Color(0.15, 0.12, 0.10))
		b.line(sc + Vector2(-2.2, -1.0), sc + Vector2(-2.2, 12.0), Color(0.30, 0.25, 0.22), 1.4)
		b.line(sc + Vector2(-4.5, 19.0), sc + Vector2(4.5, 19.0), chrome, 1.4)
		b.line(sc + Vector2(-4.5, 19.0), sc + Vector2(-4.5, 23.0), chrome, 1.4)
		b.line(sc + Vector2(4.5, 19.0), sc + Vector2(4.5, 23.0), chrome, 1.4)
		b.rect(Rect2(sc.x - 2.5, sc.y + 24.5, 5.0, 2.5), Color(0.82, 0.16, 0.12))
		# the handlebars: grips, mirrors, the headset with its lamp
		b.line(sc + Vector2(-12.0, -17.0), sc + Vector2(12.0, -17.0), lo, 2.6)
		b.line(sc + Vector2(-13.5, -17.0), sc + Vector2(-9.5, -17.0), tyre, 3.0)
		b.line(sc + Vector2(9.5, -17.0), sc + Vector2(13.5, -17.0), tyre, 3.0)
		b.circle(sc + Vector2(-9.0, -21.0), 2.2, chrome)
		b.circle(sc + Vector2(9.0, -21.0), 2.2, chrome)
		b.polygon(round_rect_pts(Rect2(sc.x - 5.0, sc.y - 21.0, 10.0, 7.0), 3.0), c)
		b.circle(sc + Vector2(0.0, -20.5), 2.6, Color(1.0, 0.95, 0.76))
		if tipped != Vector2.ZERO:
			b.draw_set_transform(Vector2.ZERO)


# an ellipse as a polygon, for the batch
static func oval_pts(at: Vector2, rx: float, ry: float, n := 16) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(n):
		var a := TAU * float(i) / float(n)
		pts.append(at + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


# El Gotic's alley posts: cast-iron bollards with a domed top
func _draw_bollard(p: Vector2) -> void:
	cast_shadow(_wc, p, 9.0, 30.0, 0.22)
	_wc.circle(p, 9.5, Color(0.12, 0.11, 0.11))
	_wc.circle(p - LIGHT * 0.8, 8.2, Color(0.34, 0.32, 0.30))
	_wc.circle(p, 6.4, Color(0.17, 0.16, 0.16))
	_wc.circle(p - LIGHT * 1.4, 4.6, Color(0.26, 0.25, 0.24))
	_wc.circle(p - LIGHT * 2.8, 1.8, Color(0.56, 0.55, 0.53))


# a street tree's pit, square in the paving: a stone kerb, earth, and the
# iron grate over it, wide enough to show round the crown
# Which of the walk's posts are trees, and what kind: the one place that says,
# for the ground pass and the canopy layer alike. Order matters: it is the
# post-drawing chain's order (a post in La Rambla's row that is not a tree is
# a lamp standard; the tutorial's posts are all lampposts).
const TREE_NONE := 0
const TREE_OAK := 1        # a broadleaf in the open
const TREE_FOREST := 2     # El Bosc: holm oak or stone pine
const TREE_PALM := 3
const TREE_STREET := 4     # a street tree in its grate
const TREE_PIT := 5        # El Gotic's plaça tree in its stone pit

func pole_tree(i: int) -> int:
	var p := poles[i]
	if tutorial_mode or lvl == "scrap" or lvl == "station" or lvl == "guell" or lvl == "market" or lvl == "neteja":
		return TREE_NONE
	if walk_mod != null and walk_mod.has_method("tree_kind"):
		return walk_mod.tree_kind(self, p)
	if lvl == "rain" and p.x < walk_cx:
		return TREE_NONE
	if lvl == "park" or lvl == "barri" or lvl == "spook":
		return TREE_OAK
	if lvl == "trail":
		return TREE_FOREST
	if lvl == "partit":
		return TREE_STREET if Partit.is_street_tree(p) else TREE_NONE
	if lvl == "beach" or lvl == "llevant":
		return TREE_PALM
	if lvl == "oldtown":
		return TREE_PIT if p.distance_to(LevelBuild.GOTIC_PLACA) < 260.0 else TREE_NONE
	if (p.x > sw_l + 60.0 and p.x < sw_r - 60.0) \
			or (rambla() and int(absf(p.y) / LevelBuild.RAMBLA_TREE_STEP) % 4 != 1):
		# mid-walkway poles are street trees in grates, and so is La Rambla's
		# row of plane trees down each edge (every fourth one a lamp standard
		# instead) - that is WHY they stand in the middle of a sidewalk
		return TREE_STREET
	return TREE_NONE


# what of a tree lies on the ground: its pit or grate, the crown's shadow, roots
func _draw_tree_ground(c: Object, p: Vector2, i: int, kind: int) -> void:
	_draw_tree_ground_only(c, p, i, kind)
	var b := ShapeBatch.new()
	_tree_trunk(b, p, i, kind)
	b.flush(c)


func _tree_trunk(b: ShapeBatch, p: Vector2, i: int, kind: int) -> void:
	match kind:
		TREE_OAK: _broadleaf_trunk(b, p, 1.0)
		TREE_FOREST:
			if i % 3 == 1:
				_broadleaf_trunk(b, p, 0.85)
			else:
				_pine_trunk(b, p)
		TREE_PALM: _palm_trunk(b, p)
		TREE_STREET: _broadleaf_trunk(b, p, 0.72)
		TREE_PIT: _broadleaf_trunk(b, p, 0.8)


func _draw_tree_ground_only(c: Object, p: Vector2, i: int, kind: int) -> void:
	match kind:
		TREE_OAK:
			_broadleaf_ground(c, p, 1.0)
		TREE_FOREST:
			_forest_ground(c, p, i)
		TREE_PALM:
			_palm_ground(c, p)
		TREE_PIT:
			_draw_tree_pit(p)
			_broadleaf_ground(c, p, 0.8)
		TREE_STREET:
			cast_shadow(c, p, 20.0, 40.0, 0.16)
			c.draw_circle(p, 19.0, Color(0.26, 0.24, 0.22))          # the pit
			c.draw_rect(Rect2(p.x - 16, p.y - 16, 32, 32), Color(0.34, 0.34, 0.37))
			for gi in range(4):
				var gy := p.y - 12.0 + float(gi) * 8.0
				c.draw_line(Vector2(p.x - 15, gy), Vector2(p.x + 15, gy), Color(0.2, 0.2, 0.22), 2.0)
			c.draw_rect(Rect2(p.x - 16, p.y - 16, 32, 32), Color(0.44, 0.44, 0.47), false, 2.0)
			_broadleaf_ground(c, p, 0.72)


# The crowns in view, for the canopy layer: the walk's tree posts and the
# off-leash grove. {"p", "kind", "i", "r" (the crown's radius), "id"}
var _canopy: Array[Dictionary] = []

func canopy_trees() -> Array[Dictionary]:
	_canopy.clear()
	var vt: float = cam.position.y - 500.0
	var vb: float = cam.position.y + 500.0
	for i in range(deco_pole_count):
		var p := poles[i]
		if p.y < vt or p.y > vb:
			continue
		var k := pole_tree(i)
		if k != TREE_NONE:
			_canopy.append({"p": p, "kind": k, "i": i, "r": _crown_r(k, i), "id": i})
	for gi in range(trees.size()):
		var t: Vector2 = trees[gi]
		if t.y < vt or t.y > vb:
			continue
		if lvl == "scrap":
			continue        # the scrapyard's grove is tyre stacks and drums: no crowns
		var gk := TREE_PALM if (freedom_kind == "beach" or lvl == "beach") else TREE_FOREST
		# El Barri's pipicà is shaded by the square's own plane trees
		if lvl == "barri":
			gk = TREE_OAK
		# the grove's broadleaves are holm-oak sized: drawn as TREE_FOREST's
		# oak (i % 3 == 1) so they keep the 0.85 they always had
		_canopy.append({"p": t, "kind": gk, "i": 1 if gk == TREE_FOREST else gi,
			"r": 34.0 if gk == TREE_OAK else 34.0 * 0.85, "id": 100000 + gi})
	return _canopy


func _crown_r(kind: int, i: int) -> float:
	match kind:
		TREE_OAK: return 34.0
		TREE_FOREST: return 34.0 * 0.85 if i % 3 == 1 else 40.0
		TREE_PALM: return 38.0
		TREE_STREET: return 34.0 * 0.72
		TREE_PIT: return 34.0 * 0.8
	return 0.0


# `faded`: the crown is drawn see-through (canopylayer.gd), so it leaves out
# the trunk, which the ground pass draws solid beneath it
func draw_tree_crown(b: ShapeBatch, t: Dictionary, faded := false) -> void:
	var p: Vector2 = t["p"]
	var trunk := not faded
	match int(t["kind"]):
		TREE_OAK: _broadleaf_crown(b, p, 1.0, trunk)
		TREE_FOREST: _forest_crown(b, p, int(t["i"]), trunk)
		TREE_PALM: _palm_crown(b, p, trunk)
		TREE_STREET: _broadleaf_crown(b, p, 0.72, trunk)
		TREE_PIT: _broadleaf_crown(b, p, 0.8, trunk)


# What else is over her head, drawn by the canopy layer with the crowns: above
# the dog, the owner, the rope, every NPC and the riders, and faded over the
# dog or the owner when either is under it. The ground pass keeps what lies on
# the ground (shadows, posts, plinths). Every piece is fixed in place, so the
# list is built once per walk and only culled to the view each redraw.
# {"over" (Over), "id", "i", "p", "top", "bot", and "r" (round: under within
# r of p) or "rect" (under inside it); "solid" if it never fades: a lamp head
# is too small to hide her, and she is always by a lamppost}
enum Over { PARASOL, PERGOLA, AWNING, ARCADE, LAUNDRY, WALL_LAMP, BOARD, BANDSTAND, LAMP,
	ICECREAM, BROLLY, BEACH_PARASOL, SHOP_AWNING }
# clear of the tree ids (pole index, and 100000 + grove index)
const OVER_ID := 200000
const PARASOL_R := 40.0
const BEACH_PARASOL_R := 36.0
const LAMP_HEAD_R := 21.0
const ICECREAM_BROLLY_R := 34.0
const PARASOL_COLS: Array[Color] = [Color(0.85, 0.45, 0.35, 0.7), Color(0.4, 0.6, 0.75, 0.7), Color(0.9, 0.8, 0.4, 0.7)]
const BROLLY_COLS: Array[Color] = [Color(0.75, 0.2, 0.25), Color(0.2, 0.35, 0.6), Color(0.25, 0.5, 0.35), Color(0.35, 0.3, 0.4)]
const BEACH_PARASOL_COLS: Array[Color] = [Color(0.85, 0.45, 0.35, 0.85), Color(0.4, 0.6, 0.75, 0.85), Color(0.9, 0.8, 0.4, 0.85)]
var _over_all: Array[Dictionary] = []
var _over_built := false
var _over: Array[Dictionary] = []


func _add_over(kind: Over, i: int, p: Vector2, r: float, rect := Rect2()) -> void:
	var t := {"over": kind, "id": OVER_ID + int(kind) * 1000 + i, "i": i, "p": p,
		"solid": kind == Over.LAMP or kind == Over.WALL_LAMP}
	if rect.size != Vector2.ZERO:
		t["rect"] = rect
		t["top"] = rect.position.y
		t["bot"] = rect.end.y
	else:
		t["r"] = r
		t["top"] = p.y - r
		t["bot"] = p.y + r
	_over_all.append(t)


func _build_overhead() -> void:
	_over_built = true
	_over_all.clear()
	for i in range(parasols.size()):
		_add_over(Over.PARASOL, i, parasols[i], PARASOL_R)
	for i in range(canopies.size()):
		_add_over(Over.PERGOLA, i, canopies[i].get_center(), 0.0, canopies[i])
	if lvl == "rain":
		for i in range(shelters.size()):
			_add_over(Over.ARCADE if i == 0 else Over.AWNING, i, shelters[i].get_center(), 0.0, shelters[i])
	if lvl == "oldtown" or lvl == "neteja":
		for i in range(laundry_lines.size()):
			var ly: float = laundry_lines[i]
			var le := walk_edges(ly)
			_add_over(Over.LAUNDRY, i, Vector2(walk_cx, ly), 0.0, Rect2(le.x - 20.0, ly - 16.0, le.y - le.x + 40.0, 64.0))
			var wy := ly + 380.0
			_add_over(Over.WALL_LAMP, i, Vector2(walk_edges(wy).x + 6.0, wy), 10.0)
	if lvl == "market":
		for i in range(Mercat.AWNINGS.size()):
			var ar := Mercat.awning_rect(self, i)
			_add_over(Over.SHOP_AWNING, i, ar.get_center(), 0.0, ar)
	if lvl == "station":
		var bd: Vector2 = LevelBuild.ESTACIO_BOARD
		_add_over(Over.BOARD, 0, bd, 0.0, Rect2(bd.x - 154.0, bd.y - 38.0, 308.0, 76.0))
	if lvl == "park":
		_add_over(Over.BANDSTAND, 0, LevelBuild.PARK_BANDSTAND, LevelBuild.BANDSTAND_R + 14.0)
	for i in range(deco_pole_count):
		if is_lamppost(i):
			_add_over(Over.LAMP, i, poles[i], LAMP_HEAD_R)
	for i in range(mini(stalls.size(), stall_kinds.size())):
		if stall_kinds[i] == "icecream":
			_add_over(Over.ICECREAM, i, stalls[i], ICECREAM_BROLLY_R)
	if lvl != "barri" and lvl != "site":
		for i in range(performers.size()):
			_add_over(Over.BROLLY, i, performers[i] + Vector2(0, -20), 30.0)
	if freedom_kind == "beach" and lvl != "montjuic" and lvl != "oldtown":
		var spots := beach_parasol_spots()
		for i in range(spots.size()):
			_add_over(Over.BEACH_PARASOL, i, spots[i], BEACH_PARASOL_R)


# what is overhead in view, for the canopy layer; a reused array
func overhead_pieces() -> Array[Dictionary]:
	if not _over_built:
		_build_overhead()
	_over.clear()
	# a detour gallery shares the street's y range, and the alley's washing
	# hangs between walk_edges at draw time: it would be strung across the room
	if detour_active:
		return _over
	var vt: float = cam.position.y - 500.0
	var vb: float = cam.position.y + 500.0
	var raining := Game.weather == "rain"
	for t: Dictionary in _over_all:
		if float(t["bot"]) < vt or float(t["top"]) > vb:
			continue
		# a performer only puts an umbrella up in the rain
		if int(t["over"]) == Over.BROLLY and not raining:
			continue
		_over.append(t)
	return _over


# the post chain's lampposts (_draw_world): their heads are overhead
func is_lamppost(i: int) -> bool:
	if pole_tree(i) != TREE_NONE:
		return false
	if tutorial_mode or lvl == "scrap":
		return true
	if lvl == "station" or lvl == "guell" or lvl == "market" or lvl == "oldtown":
		return false
	return not (lvl == "rain" and poles[i].x < walk_cx)


# What lights the walk at night, as (x, y, radius): every lamppost, and a lamp
# on the wall wherever the walk would otherwise go dark for longer than
# NIGHT_GAP. Built once; world/light_layer.gd draws the light.
const NIGHT_LAMP_R := 190.0
const NIGHT_WALL_R := 150.0
const NIGHT_GAP := 300.0
const NIGHT_WALL_STEP := 280.0
var _night_lights: Array[Vector3] = []
var _night_built := false


func night_lights() -> Array[Vector3]:
	if _night_built:
		return _night_lights
	_night_built = true
	_night_lights.clear()
	for i in range(deco_pole_count):
		if is_lamppost(i):
			_night_lights.append(Vector3(poles[i].x, poles[i].y + 16.0, NIGHT_LAMP_R))
	var side := -1.0
	var y := START_Y - 60.0
	while y > GATE_Y + 120.0:
		var e := walk_edges(y)
		var at := Vector2(e.x + 8.0 if side < 0.0 else e.y - 8.0, y)
		var near := false
		for l: Vector3 in _night_lights:
			if Vector2(l.x, l.y).distance_to(at) < NIGHT_GAP:
				near = true
				break
		if not near:
			_night_lights.append(Vector3(at.x, at.y, NIGHT_WALL_R))
		side = -side
		y -= NIGHT_WALL_STEP
	return _night_lights


# An umbrella from above: a filled canopy of eight panels, every other one in
# shade, the ribs running out to their tips, the ferrule in the middle and
# the rain running off the rim. It covers the person under it.
const BROLLY_R := 24.0


func _brolly_canopy(b: ShapeBatch, c: Vector2, col: Color, seed_f: float) -> void:
	var rot := seed_f * 0.37
	var tips := PackedVector2Array()
	for k in range(8):
		tips.append(c + Vector2.from_angle(rot + TAU * float(k) / 8.0) * BROLLY_R)
	b.circle(c + LIGHT * 7.0, BROLLY_R, Color(SHADOW_COL.r, SHADOW_COL.g, SHADOW_COL.b, 0.22))
	b.polygon(tips, col)
	for k in range(8):
		var a := tips[k]
		var z := tips[(k + 1) % 8]
		# the panels facing the light are lit, the far ones in shade
		var facing := (a + z - c * 2.0).normalized().dot(-LIGHT)
		if facing < 0.0:
			b.polygon(PackedVector2Array([c, a, z]), col.darkened(0.22 * -facing))
		else:
			b.polygon(PackedVector2Array([c, a, z]), col.lightened(0.18 * facing))
	for k in range(8):
		b.line(c, tips[k], col.darkened(0.38), 1.4)
		b.circle(tips[k], 1.6, Color(0.20, 0.18, 0.18))
	b.circle(c, 3.0, Color(0.18, 0.16, 0.16))
	b.circle(c - LIGHT * 1.0, 1.4, Color(0.75, 0.75, 0.78))
	# drops running off two of the tips
	var t := AnimClock.msec() / 1000.0
	for k in range(2):
		var tip := tips[(k * 4 + int(seed_f)) % 8]
		var fall := fmod(t * 1.6 + seed_f * 0.3 + float(k) * 0.5, 1.0)
		b.circle(tip + (tip - c).normalized() * (2.0 + fall * 5.0), 1.5 * (1.0 - fall * 0.5), Color(0.80, 0.88, 0.96, 0.8 * (1.0 - fall)))


# the dog beach's lifeguard tower, on the sand above the sea
func dog_beach_tower() -> Vector2:
	return Vector2(BEACH_SEA_R + 240.0, _freedom_rect().get_center().y)


# a dog beach parasol from above, overhead: panels radiating from a hub
func _beach_parasol_canopy(b: ShapeBatch, pa: Vector2, i: int) -> void:
	var pc: Color = BEACH_PARASOL_COLS[i % 3]
	b.circle(pa, BEACH_PARASOL_R, pc)
	for panel in range(8):
		var a0 := TAU * float(panel) / 8.0 + float(i) * 0.2
		b.line(pa, pa + Vector2.from_angle(a0) * BEACH_PARASOL_R, pc.darkened(0.22), 2.0)
		if panel % 2 == 0:
			b.polygon(PackedVector2Array([pa, pa + Vector2.from_angle(a0) * BEACH_PARASOL_R,
				pa + Vector2.from_angle(a0 + TAU / 8.0) * BEACH_PARASOL_R]), Color(1, 1, 1, 0.10))
	b.circle(pa - LIGHT * 10.0, 12.0, Color(1, 1, 1, 0.13))   # the lit side
	b.circle(pa, 5.0, Color(0.42, 0.38, 0.34))                # the pole
	b.circle(pa, 2.2, Color(0.62, 0.58, 0.52))


# the dog beach's parasols, round its agility lane
func beach_parasol_spots() -> Array[Vector2]:
	var r := _freedom_rect()
	var out: Array[Vector2] = []
	for dy: float in [150.0, 390.0, 600.0]:
		out.append(Vector2(r.end.x - 260.0, r.position.y + dy))
	return out


# One overhead piece into the canopy layer's batch. `b` stands in for that
# layer's canvas, so text and arcs pass straight through to it.
func draw_overhead_piece(b: ShapeBatch, t: Dictionary, _faded := false) -> void:
	var p: Vector2 = t["p"]
	var i: int = t["i"]
	match int(t["over"]):
		Over.PARASOL:
			# wide, over the tables by day; furled spikes at night
			if Game.night:
				b.line(p + Vector2(-3, 24), p + Vector2(3, -28), Color(0.45, 0.4, 0.35), 5.0)
				b.circle(p + Vector2(3, -28), 4.0, PARASOL_COLS[i % 3])
			else:
				_parasol_canopy(b, p, PARASOL_COLS[i % 3], float(i))
		Over.PERGOLA:
			# the beach terraces' canopies: out by day, furled at night
			var cn: Rect2 = t["rect"]
			if Game.night:
				b.draw_rect(Rect2(cn.position.x, cn.position.y, cn.size.x, 10), Color(0.72, 0.67, 0.57))
				b.draw_rect(Rect2(cn.position.x, cn.position.y, cn.size.x, 10), Color(0.5, 0.46, 0.38), false, 1.5)
			else:
				_draw_pergola(b, cn)
		Over.AWNING:
			_diluvi_awning(b, t["rect"], i)
		Over.ARCADE:
			_diluvi_arcade_roof(b, t["rect"])
		Over.LAUNDRY:
			_laundry_line(b, i, AnimClock.msec() / 1000.0)
		Over.WALL_LAMP:
			var glow := 0.6 + 0.25 * sin(AnimClock.msec() / 1000.0 * 3.0 + i)
			b.circle(p, 6.0, Color(1.0, 0.8, 0.4, glow))
		Over.BOARD:
			Estacio.departures_board(self, b, p)
		Over.BANDSTAND:
			_bandstand_roof(b, p)
		Over.LAMP:
			_lamp_head(b, p)
		Over.ICECREAM:
			_icecream_brolly(b, p)
		Over.BROLLY:
			_brolly_canopy(b, performers[i] + Vector2(0, -8), BROLLY_COLS[i % BROLLY_COLS.size()], float(i))
		Over.BEACH_PARASOL:
			_beach_parasol_canopy(b, p, i)
		Over.SHOP_AWNING:
			Mercat.draw_awning(self, b, i)


func _draw_tree_pit(p: Vector2) -> void:
	var b := ShapeBatch.new()
	var pit := Rect2(p - Vector2(38.0, 38.0), Vector2(76.0, 76.0))
	b.rect(pit, Color(0.64, 0.60, 0.54))
	b.rect(Rect2(pit.position.x, pit.end.y - 4.0, pit.size.x, 4.0), Color(0.52, 0.48, 0.43))
	var earth := pit.grow(-5.0)
	b.rect(earth, Color(0.32, 0.25, 0.18))
	var iron := Color(0.20, 0.20, 0.22)
	var gy := earth.position.y + 4.0
	while gy < earth.end.y - 2.0:
		b.line(Vector2(earth.position.x + 2.0, gy), Vector2(earth.end.x - 2.0, gy), iron, 2.2)
		gy += 7.0
	b.line(Vector2(earth.position.x + 2.0, earth.position.y + 2.0), Vector2(earth.position.x + 2.0, earth.end.y - 2.0), iron, 2.2)
	b.line(Vector2(earth.end.x - 2.0, earth.position.y + 2.0), Vector2(earth.end.x - 2.0, earth.end.y - 2.0), iron, 2.2)
	b.flush(_wc)


# Washing strung across the alley overhead, on a line that sags between the
# walls: shirts with their sleeves out, sheets folded over the line, trousers
# by the waistband, socks in pairs, every piece held by its pegs.
const WASH_COLS: Array[Color] = [Color(0.80, 0.30, 0.35), Color(0.30, 0.50, 0.70), Color(0.92, 0.88, 0.66),
	Color(0.40, 0.65, 0.50), Color(0.95, 0.94, 0.91), Color(0.86, 0.62, 0.30)]
const WASH_KINDS := ["shirt", "sheet", "trousers", "shirt", "socks", "towel", "shirt", "sheet"]
const WASH_W := {"shirt": 32.0, "sheet": 54.0, "trousers": 26.0, "socks": 22.0, "towel": 30.0}


func _laundry_y(a: Vector2, z: Vector2, x: float) -> float:
	var f := clampf((x - a.x) / maxf(z.x - a.x, 1.0), 0.0, 1.0)
	return lerpf(a.y, z.y, f) + 12.0 * 4.0 * f * (1.0 - f)


# one line of it, overhead (draw_overhead_piece): over the dog, the owner and
# the rope, not under them
func _laundry_line(b: ShapeBatch, i: int, lt: float) -> void:
	var cord := Color(0.20, 0.18, 0.16)
	var peg := Color(0.80, 0.68, 0.48)
	var ly: float = laundry_lines[i]
	var le := walk_edges(ly)
	var a := Vector2(le.x - 20.0, ly)
	var z := Vector2(le.y + 20.0, ly - 8.0)
	var prev := a
	for s in range(1, 9):
		var qx := lerpf(a.x, z.x, float(s) / 8.0)
		var q := Vector2(qx, _laundry_y(a, z, qx))
		b.line(prev, q, cord, 1.5)
		prev = q
	var x := le.x + 14.0
	var j := 0
	while true:
		var kind: String = WASH_KINDS[(i * 3 + j) % WASH_KINDS.size()]
		var w: float = WASH_W[kind]
		if x + w > le.y - 14.0:
			break
		var cx := x + w * 0.5
		var top := Vector2(cx, _laundry_y(a, z, cx))
		var col: Color = WASH_COLS[(i * 2 + j) % WASH_COLS.size()]
		var dx := sin(lt * 1.2 + float(j) + float(i)) * 2.0
		_draw_wash(b, kind, top, col, dx)
		for px: float in _wash_pegs(kind):
			var pp := Vector2(cx + px, _laundry_y(a, z, cx + px))
			b.rect(Rect2(pp.x - 1.4, pp.y - 3.5, 2.8, 7.0), peg)
		x += w + 4.0
		j += 1


func _wash_pegs(kind: String) -> Array[float]:
	match kind:
		"sheet": return [-22.0, 0.0, 22.0]
		"trousers": return [-8.0, 8.0]
		"socks": return [-6.0, 6.0]
		"towel": return [-10.0, 10.0]
	return [-7.0, 7.0]


func _draw_wash(b: ShapeBatch, kind: String, p: Vector2, col: Color, dx: float) -> void:
	var fold := col.darkened(0.20)
	var hem := col.darkened(0.30)
	match kind:
		"shirt":
			# the body, the sleeves out at an angle, the collar, the placket
			b.polygon(PackedVector2Array([p + Vector2(-8.5, 0.0), p + Vector2(8.5, 0.0),
				p + Vector2(8.5 + dx, 25.0), p + Vector2(-8.5 + dx, 25.0)]), col)
			b.polygon(PackedVector2Array([p + Vector2(-8.5, 0.5), p + Vector2(-16.0, 5.0),
				p + Vector2(-13.5 + dx * 0.4, 12.0), p + Vector2(-8.5, 8.5)]), col)
			b.polygon(PackedVector2Array([p + Vector2(8.5, 0.5), p + Vector2(16.0, 5.0),
				p + Vector2(13.5 + dx * 0.4, 12.0), p + Vector2(8.5, 8.5)]), col)
			b.line(p + Vector2(-8.5, 8.5), p + Vector2(-14.5 + dx * 0.4, 9.5), fold, 1.2)
			b.line(p + Vector2(8.5, 8.5), p + Vector2(14.5 + dx * 0.4, 9.5), fold, 1.2)
			b.polygon(PackedVector2Array([p + Vector2(-4.0, 0.0), p + Vector2(4.0, 0.0), p + Vector2(0.0, 5.0)]), hem)
			b.line(p + Vector2(0.0, 5.0), p + Vector2(dx, 24.5), fold, 1.2)
			b.line(p + Vector2(-8.5 + dx, 24.0), p + Vector2(8.5 + dx, 24.0), hem, 1.6)
		"sheet":
			# folded over the line, so a band of it hangs doubled at the top,
			# and the creases from the cupboard run down it
			var pale := col.lightened(0.55)
			b.polygon(PackedVector2Array([p + Vector2(-25.0, 0.0), p + Vector2(25.0, 0.0),
				p + Vector2(25.0 + dx, 34.0), p + Vector2(-25.0 + dx, 34.0)]), pale)
			b.rect(Rect2(p.x - 25.0, p.y, 50.0, 6.0), pale.lightened(0.25))
			b.line(Vector2(p.x - 25.0, p.y + 6.0), Vector2(p.x + 25.0, p.y + 6.0), pale.darkened(0.18), 1.2)
			b.line(p + Vector2(-8.0, 7.0), p + Vector2(-8.0 + dx * 0.7, 33.0), pale.darkened(0.12), 1.4)
			b.line(p + Vector2(9.0, 7.0), p + Vector2(9.0 + dx * 0.7, 33.0), pale.darkened(0.12), 1.4)
			b.line(p + Vector2(-25.0 + dx, 29.0), p + Vector2(25.0 + dx, 29.0), col, 2.4)
			b.line(p + Vector2(-25.0 + dx, 33.0), p + Vector2(25.0 + dx, 33.0), pale.darkened(0.22), 1.6)
		"trousers":
			# by the waistband: the seat, then two legs with a gap between
			var denim := Color(0.26, 0.34, 0.50) if col.v > 0.8 else col.darkened(0.15)
			b.rect(Rect2(p.x - 9.5, p.y, 19.0, 4.0), denim.darkened(0.20))
			b.polygon(PackedVector2Array([p + Vector2(-9.5, 4.0), p + Vector2(9.5, 4.0),
				p + Vector2(9.5 + dx * 0.3, 11.0), p + Vector2(-9.5 + dx * 0.3, 11.0)]), denim)
			b.polygon(PackedVector2Array([p + Vector2(-9.5, 10.0), p + Vector2(-0.8, 10.0),
				p + Vector2(-1.4 + dx, 30.0), p + Vector2(-9.0 + dx, 30.0)]), denim)
			b.polygon(PackedVector2Array([p + Vector2(0.8, 10.0), p + Vector2(9.5, 10.0),
				p + Vector2(9.0 + dx, 30.0), p + Vector2(1.4 + dx, 30.0)]), denim)
			b.line(p + Vector2(-5.0, 11.0), p + Vector2(-5.0 + dx, 29.0), denim.lightened(0.12), 1.0)
			b.line(p + Vector2(5.0, 11.0), p + Vector2(5.0 + dx, 29.0), denim.lightened(0.12), 1.0)
		"socks":
			for s: float in [-6.0, 6.0]:
				b.rect(Rect2(p.x + s - 2.0, p.y, 4.0, 11.0), col)
				b.polygon(PackedVector2Array([p + Vector2(s - 2.0 + dx * 0.4, 11.0), p + Vector2(s + 2.0 + dx * 0.4, 11.0),
					p + Vector2(s + 5.5 + dx * 0.4, 14.5), p + Vector2(s - 2.0 + dx * 0.4, 14.5)]), col)
				b.line(Vector2(p.x + s - 2.0, p.y + 2.0), Vector2(p.x + s + 2.0, p.y + 2.0), hem, 1.4)
		"towel":
			b.polygon(PackedVector2Array([p + Vector2(-12.0, 0.0), p + Vector2(12.0, 0.0),
				p + Vector2(12.0 + dx, 28.0), p + Vector2(-12.0 + dx, 28.0)]), col)
			b.line(p + Vector2(-12.0 + dx * 0.8, 21.0), p + Vector2(12.0 + dx * 0.8, 21.0), col.lightened(0.45), 2.0)
			b.line(p + Vector2(-12.0 + dx * 0.85, 24.0), p + Vector2(12.0 + dx * 0.85, 24.0), col.lightened(0.45), 1.2)
			b.line(p + Vector2(-12.0 + dx, 27.5), p + Vector2(12.0 + dx, 27.5), hem, 1.4)


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


# El Mosaic (systems/mosaic.gd); tests and the grind rails ask main
func on_mosaic_bench(y: float) -> bool:
	return Mosaic.on_bench(self, y)


func mosaic_bays() -> Array[Vector2]:
	return Mosaic.bays(self)


# One carved festival pumpkin (carbassa de Tots Sants) with candle glow
static func _draw_cast_pumpkin(b: ShapeBatch, p: Vector2, seed: float, t: float) -> void:
	var flk := 0.82 + 0.18 * sin(t * 11.0 + seed * 6.28)
	# warm candle light pool on the flagstones
	b.circle(p + Vector2(0.0, 3.0), 28.0, Color(1.0, 0.64, 0.18, 0.11 * flk))
	b.circle(p + Vector2(0.0, 3.0), 14.0, Color(1.0, 0.78, 0.32, 0.12 * flk))
	# drop shadow
	b.circle(p + LIGHT * 3.5, 9.5, Color(SHADOW_COL.r, SHADOW_COL.g, SHADOW_COL.b, 0.28))
	# ribbed pumpkin body
	var pcol := Color(0.92, 0.44, 0.10)
	var pshd := Color(0.80, 0.34, 0.06)
	b.circle(p + Vector2(-5.0, 0.0), 7.5, pshd)
	b.circle(p + Vector2(5.0, 0.0), 7.5, pshd)
	b.circle(p, 8.5, pcol)
	b.circle(p + Vector2(-1.5, -2.0), 3.0, pcol.lightened(0.2))
	# curled green stem
	b.line(p + Vector2(0.0, -7.0), p + Vector2(1.5, -11.0), Color(0.32, 0.46, 0.20), 2.2)
	# carved glowing face: triangular eyes and jagged grin
	var eye_col := Color(1.0, 0.92, 0.48, flk)
	b.polygon(PackedVector2Array([p + Vector2(-4.0, -1.0), p + Vector2(-2.0, -4.0), p + Vector2(-1.0, -1.0)]), eye_col)
	b.polygon(PackedVector2Array([p + Vector2(1.0, -1.0), p + Vector2(2.0, -4.0), p + Vector2(4.0, -1.0)]), eye_col)
	b.line(p + Vector2(-4.0, 2.5), p + Vector2(-1.0, 4.0), eye_col, 1.8)
	b.line(p + Vector2(-1.0, 4.0), p + Vector2(1.0, 2.5), eye_col, 1.8)
	b.line(p + Vector2(1.0, 2.5), p + Vector2(4.0, 4.0), eye_col, 1.8)


# Drifts of crisp autumn leaves (fulles seques) gathered in corners and gutters
static func _draw_autumn_leaves(b: ShapeBatch, at: Vector2, seed: float) -> void:
	var leaf_cols: Array[Color] = [
		Color(0.84, 0.58, 0.18, 0.85),
		Color(0.72, 0.32, 0.12, 0.85),
		Color(0.56, 0.24, 0.10, 0.85),
		Color(0.68, 0.54, 0.22, 0.85),
	]
	for i: int in range(6):
		var h := fmod(seed * 13.7 + float(i) * 0.41, 1.0)
		var ang := h * TAU
		var dist := 2.0 + fmod(seed * 7.3 + float(i) * 2.9, 8.0)
		var lp := at + Vector2(cos(ang), sin(ang)) * dist
		var col: Color = leaf_cols[(int(seed * 10.0) + i) % leaf_cols.size()]
		b.line(lp, lp + Vector2(cos(ang + 0.8) * 4.5, sin(ang + 0.8) * 3.0), col, 2.2)
		b.circle(lp, 1.0, col.darkened(0.2))


# the overhead layer's picture: El Gotic's bridge, carved stone, a
# pointed-arch window in its side, over the alley at GOTIC_BRIDGE_Y
func draw_overhead_onto(c: CanvasItem) -> void:
	if walk_mod != null and walk_mod.has_method("draw_overhead"):
		walk_mod.draw_overhead(self, c)
		return


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
		human.notice("I'm soaked!", 1.6)
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


# an El Diluvi awning: striped canvas over the pavement, dripping at the edge
const DILUVI_AWNING_COLS: Array[Color] = [Color(0.62, 0.20, 0.22), Color(0.20, 0.36, 0.30), Color(0.22, 0.30, 0.50)]


func _diluvi_awning(b: ShapeBatch, r: Rect2, i: int) -> void:
	var t := AnimClock.msec() / 1000.0
	var ac: Color = DILUVI_AWNING_COLS[i % 3]
	b.rect(r, ac)
	var sx := r.position.x + 6.0
	while sx < r.end.x:
		b.rect(Rect2(sx, r.position.y, 6.0, r.size.y), ac.lightened(0.25))
		sx += 14.0
	# rainwater cascading off the scalloped awning hem
	for k in range(5):
		var dy := fmod(t * 70.0 + float(k) * 11.0 + r.position.y, 28.0)
		var py := r.position.y + 8.0 + float(k) * (r.size.y - 16.0) / 4.0
		b.line(Vector2(r.position.x - 2.0, py), Vector2(r.position.x - 2.0, py + 4.0), Color(0.82, 0.90, 0.98, 0.75), 1.5)
		b.circle(Vector2(r.position.x - 3.0, py + dy * 0.25), 1.6, Color(0.85, 0.92, 0.98, 0.8))
		b.circle(Vector2(r.position.x - 6.0, py + 12.0), 3.0, Color(0.80, 0.88, 0.96, 0.3))


# the arcade's vaulted roof seen from above, only the stretch on screen
func _diluvi_arcade_roof(b: ShapeBatch, ar: Rect2) -> void:
	var vt: float = cam.position.y - 440.0
	var vb: float = cam.position.y + 440.0
	var y0 := maxf(ar.position.y, vt - 40.0)
	var y1 := minf(ar.end.y, vb + 40.0)
	if y1 <= y0:
		return
	# a lean-to of wet pantiles falling from the building to the pillars,
	# the courses running down the slope, a stone cornice over each pillar bay
	var tile := Color(0.50, 0.30, 0.22)
	b.rect(Rect2(ar.position.x, y0, ar.size.x, y1 - y0), tile)
	b.rect(Rect2(ar.position.x, y0, 8.0, y1 - y0), tile.lightened(0.14))
	var ty := floorf(y0 / 9.0) * 9.0
	while ty < y1:
		if ty >= y0:
			b.line(Vector2(ar.position.x + 8.0, ty), Vector2(ar.end.x - 10.0, ty), tile.darkened(0.30), 2.0)
			b.line(Vector2(ar.position.x + 8.0, ty + 3.0), Vector2(ar.end.x - 10.0, ty + 3.0), tile.lightened(0.10), 1.0)
		ty += 9.0
	var vy := floorf(y0 / 120.0) * 120.0 + 20.0
	while vy < y1:
		if vy >= y0:
			b.rect(Rect2(ar.position.x, vy - 2.5, ar.size.x - 10.0, 5.0), Color(0.62, 0.56, 0.50))
		vy += 120.0
	# the gutter along the eave over the pillars, running full
	b.rect(Rect2(ar.end.x - 10.0, y0, 10.0, y1 - y0), Color(0.50, 0.53, 0.56))
	b.rect(Rect2(ar.end.x - 8.0, y0, 6.0, y1 - y0), Color(0.40, 0.52, 0.64))
	var t := AnimClock.msec() / 1000.0
	var fy := y0 + fmod(t * 70.0, 30.0)
	while fy < y1 - 10.0:
		b.line(Vector2(ar.end.x - 5.0, fy), Vector2(ar.end.x - 5.0, fy + 10.0), Color(0.80, 0.88, 0.95, 0.7), 1.5)
		fy += 30.0


# L'Estacio's moving walkway, a steel travelator: grooved treads moving the
# carry way between black rubber handrails on glass balustrades, steel comb
# plates with a yellow edge at each end, and small arrows in the tread. Only
# the stretch on screen; one batch.
func _draw_travelator(vt: float, vb: float) -> void:
	var z := conveyor_zone
	var y0 := maxf(z.position.y, vt - 40.0)
	var y1 := minf(z.end.y, vb + 40.0)
	if y1 <= y0:
		return
	var b := ShapeBatch.new()
	var belt := Rect2(z.position.x + 16.0, y0, z.size.x - 32.0, y1 - y0)
	b.rect(Rect2(z.position.x, y0, z.size.x, y1 - y0), Color(0.62, 0.64, 0.66))
	b.rect(belt, Color(0.36, 0.38, 0.41))
	# the grooves run with the belt; the tread joints move along it
	var gx := belt.position.x + 5.0
	while gx < belt.end.x - 2.0:
		b.line(Vector2(gx, y0), Vector2(gx, y1), Color(0.28, 0.30, 0.33), 1.5)
		gx += 7.0
	var scroll := fmod(AnimClock.msec() / 1000.0 * 90.0, 40.0) * conveyor_dir.y
	var jy := floorf(y0 / 40.0) * 40.0 + fposmod(scroll, 40.0)
	while jy < y1:
		if jy > y0:
			b.line(Vector2(belt.position.x, jy), Vector2(belt.end.x, jy), Color(0.50, 0.52, 0.56), 1.5)
		jy += 40.0
	var ay := floorf(y0 / 160.0) * 160.0 + fposmod(scroll * 4.0, 160.0)
	while ay < y1:
		if ay > y0 + 12.0:
			var ac := Vector2(belt.get_center().x, ay)
			b.polygon(PackedVector2Array([ac + Vector2(0, 10.0 * conveyor_dir.y), ac + Vector2(12, -4.0 * conveyor_dir.y),
				ac + Vector2(-12, -4.0 * conveyor_dir.y)]), Color(0.95, 0.80, 0.20, 0.75))
		ay += 160.0
	# the balustrades: glass, a steel skirt, the black handrail on top
	for hx: float in [z.position.x + 2.0, z.end.x - 14.0]:
		b.rect(Rect2(hx, y0, 12.0, y1 - y0), Color(0.70, 0.82, 0.88, 0.45))
		b.rect(Rect2(hx + 3.0, y0, 6.0, y1 - y0), Color(0.10, 0.10, 0.11))
		b.rect(Rect2(hx + 3.0, y0, 2.0, y1 - y0), Color(0.30, 0.30, 0.32))
	# the comb plates and newel ends
	for ey: float in [z.position.y, z.end.y - 22.0]:
		if ey + 22.0 > y0 and ey < y1:
			b.rect(Rect2(z.position.x, ey, z.size.x, 22.0), Color(0.72, 0.74, 0.76))
			b.rect(Rect2(belt.position.x, ey + (18.0 if ey == z.position.y else 0.0), belt.size.x, 4.0), Color(0.95, 0.80, 0.20))
			for hx: float in [z.position.x + 8.0, z.end.x - 8.0]:
				b.circle(Vector2(hx, ey + 11.0), 8.0, Color(0.10, 0.10, 0.11))
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
			float_text(_seller_pos(r) + Vector2(0, -22), "Hey! HEY!", Color(1, 0.9, 0.75), POP_SAY)
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
	float_text(sp + Vector2(0, -30), "THE JIG IS UP!", Color(1, 0.9, 0.5))
	feed.say("SHELL GAME BUSTED +6", EventFeed.Tone.GOOD)
	for tw: Node2D in get_tree().get_nodes_in_group("tourists"):
		if tw.global_position.distance_to(sp) < 240.0:
			tw.cheer()
# La Castanyada's queue for the roaster, out once when the plaça comes near:
# people waiting their turn for a paper cone, facing the cart
var cast_queue_out := false


func _tick_castanyada_queue() -> void:
	if cast_queue_out or cam.position.y > LevelBuild.CAST_PLACA.y + 900.0:
		return
	cast_queue_out = true
	var qr := RandomNumberGenerator.new()
	qr.seed = 0xCA57
	for off: Vector2 in LevelBuild.CAST_QUEUE:
		var tw := Node2D.new()
		tw.set_script(load("res://entities/tourist.gd"))
		tw.z_index = 8
		add_child(tw)
		tw.setup(self, qr, LevelBuild.CAST_ROASTER_AT + off, -1.0)
		tw.stand("wait", LevelBuild.CAST_ROASTER_AT + Vector2(-26.0, 0.0))
		tw.look = "none"


# the crowd: this many tourists kept walking around the camera (El Mosaic's
# walkers are fewer; most of its tourists stand in the queue or at the
# salamander)
const CROWD_SIZE := 14
const MOSAIC_CROWD := 6


# La Rambla and El Mosaic have a crowd, and pickpockets working it. Dia de
# Partit has two of them before kick-off, and none of the tourist flock:
# the avenue is the river.
func crowded() -> bool:
	if lvl == "partit":
		return match_day != null and match_day.phase == MatchDay.Ph.PREMATCH and not tutorial_mode
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
	if walk_mod != null and walk_mod.has_method("tick_crowd"):
		walk_mod.tick_crowd(self)
	if lvl == "partit":
		_spawn_partit_thief(delta, cy)
		return
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


# Two thieves before kick-off. The second works a fan in the river, not the
# tourist flock this walk does not have.
func _spawn_partit_thief(delta: float, cy: float) -> void:
	if get_tree().get_nodes_in_group("pickpockets").size() > 0 or pp_spawned >= 2:
		return
	if cy > START_Y - 500.0 or cy < GATE_Y + 900.0:
		return
	pp_spawn_t -= delta
	if pp_spawn_t > 0.0:
		return
	pp_spawn_t = PP_EVERY
	var target: Node2D = human
	var is_owner := pp_spawned == 0
	if not is_owner:
		target = _fan_mark(cy)
		if target == null:
			return
	pp_spawned += 1
	var pe := walk_edges(cy - 260.0)
	var from := Vector2(pe.x + 50.0 if target.global_position.x > walk_cx else pe.y - 50.0, cy - 260.0)
	var pp := Node2D.new()
	pp.set_script(load("res://entities/pickpocket.gd"))
	pp.z_index = 9
	add_child(pp)
	pp.setup(self, from, target, is_owner, crowd_rng.randf() * 10.0)
	feed.say("PICKPOCKET! WATCH HIS HANDS", EventFeed.Tone.LOUD)


func _fan_mark(cy: float) -> Node2D:
	if is_instance_valid(_partit_mark) and _partit_mark.has_wallet:
		return _partit_mark
	var e := walk_edges(cy)
	_partit_mark = _spawn_tourist(Vector2(clampf(e.y - 120.0, e.x + 40.0, e.y - 40.0), cy + 80.0), -1.0)
	_partit_mark.stand("pose", _partit_mark.global_position + Vector2(0.0, -40.0))
	_partit_mark.col = Partit.HOME_BLUE
	return _partit_mark


func on_pickpocket_lift(at: Vector2, from_owner: bool) -> void:
	float_text(at + Vector2(0, -30), "Hey! My wallet!" if not from_owner else "!", Color(1, 0.6, 0.5), POP_SAY)
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
	Rambla.draw_pavement_waves(self, b, vt, vb)
	Rambla.draw_tree_leaf_drifts(self, b, vt, vb)
	# the round pavement mosaic in the square: Joan Miro's Pla de l'Os mosaic
	var mc: Vector2 = LevelBuild.RAMBLA_MOSAIC
	var mr: float = LevelBuild.RAMBLA_MOSAIC_R
	if mc.y > vt - 100.0 and mc.y < vb + 100.0:
		Rambla.draw_miro_mosaic(b, mc, mr)
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

		var bow := float(statue_bow.get(i, 0.0))
		Rambla.draw_statue_dressing(self, b, sp, i, paint, bow, t)
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
	Rambla.draw_canaletes(self, _wc, f)


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


# the ice cream cart's striped umbrella, overhead (draw_overhead_piece)
func _icecream_brolly(b: ShapeBatch, st: Vector2) -> void:
	for k in range(8):
		var a := TAU * float(k) / 8.0
		b.polygon(PackedVector2Array([st, st + Vector2.from_angle(a) * ICECREAM_BROLLY_R,
			st + Vector2.from_angle(a + TAU / 8.0) * ICECREAM_BROLLY_R]),
			Color(0.95, 0.45, 0.55, 0.85) if k % 2 == 0 else Color(0.98, 0.96, 0.92, 0.85))
	b.circle(st, 3.0, Color(0.4, 0.35, 0.3))


# the bandstand's octagonal roof over its eight iron posts, overhead
# (draw_overhead_piece): a ring of eight green copper panels round an open
# lantern, the post heads showing where they meet it
func _bandstand_roof(b: ShapeBatch, bs: Vector2) -> void:
	var r: float = LevelBuild.BANDSTAND_R
	for i in range(8):
		var a0 := TAU * float(i) / 8.0 + PI / 8.0
		var a1 := TAU * float(i + 1) / 8.0 + PI / 8.0
		var pan := PackedVector2Array([bs + Vector2.from_angle(a0) * (r + 14.0), bs + Vector2.from_angle(a1) * (r + 14.0),
			bs + Vector2.from_angle(a1) * (r - 12.0), bs + Vector2.from_angle(a0) * (r - 12.0)])
		b.polygon(pan, Color(0.30, 0.52, 0.46) if i % 2 == 0 else Color(0.26, 0.46, 0.41))
	b.circle(bs, 9.0, Color(0.36, 0.58, 0.51))
	for bp: Vector2 in park_posts:
		b.circle(bp, 5.0, Color(0.16, 0.17, 0.19))


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
	Rambla.draw_rambla_stall(self, b, st, kind, i)
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


# The benches the owner waits on at the quiet lessons (LevelBuild.
# tutorial_benches): slats across, cast-iron ends, the backrest on the south
# side so whoever sits there faces the lesson.
func _draw_tutorial_benches(vt: float, vb: float) -> void:
	var b := ShapeBatch.new()
	for r: Rect2 in LevelBuild.tutorial_benches(self):
		if r.end.y < vt - 40.0 or r.position.y > vb + 40.0:
			continue
		b.rect(Rect2(r.position + LIGHT * 7.0, r.size + Vector2(0, 6)), Color(SHADOW_COL.r, SHADOW_COL.g, SHADOW_COL.b, 0.22))
		for ex: float in [r.position.x + 3.0, r.end.x - 7.0]:
			b.rect(Rect2(ex, r.position.y - 1.0, 4.0, r.size.y + 8.0), Color(0.16, 0.16, 0.17))
		for si in range(3):
			var sl := Rect2(r.position.x, r.position.y + float(si) * 5.0, r.size.x, 4.2)
			var wc := Color(0.56, 0.41, 0.27).lightened(0.10 if si == 0 else 0.0)
			b.rect(sl, wc.darkened(0.25))
			b.rect(Rect2(sl.position, sl.size - Vector2(0.0, 1.2)), wc)
		var back := Rect2(r.position.x, r.end.y + 2.0, r.size.x, 5.0)
		b.rect(back, Color(0.46, 0.33, 0.21))
		b.rect(Rect2(back.position, Vector2(back.size.x, 1.5)), Color(0.66, 0.50, 0.34))
	b.flush(_wc)


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


# BAR LA PENYA leaves a bowl out by the door. Low, so the leash clears it.
func _draw_water_bowl(f: Vector2) -> void:
	contact_shadow(_wc, f, 9.0, 3.2, 0.22)
	_wc.draw_circle(f, 8.2, Color(0.74, 0.76, 0.78))
	_wc.draw_circle(f + Vector2(0.4, 0.6), 5.4, Color(0.28, 0.46, 0.60))
	_wc.draw_circle(f + Vector2(-1.8, -1.6), 1.5, Color(0.84, 0.93, 0.98, 0.9))


# the ping-pong table: concrete, a net across it, a white line round
func _draw_pingpong(st: Vector2) -> void:
	var r := Rect2(st.x - 44.0, st.y - 24.0, 88.0, 48.0)
	contact_shadow(_wc, st, 44.0, 8.0, 0.22)
	var b := ShapeBatch.new()
	b.rect(r, Color(0.36, 0.48, 0.44))
	b.rect(r.grow(-1.5), Color(0.92, 0.92, 0.88))
	b.rect(r.grow(-3.0), Color(0.42, 0.56, 0.50))
	# white doubles centerline dividing service boxes
	b.line(Vector2(r.position.x + 3.0, st.y), Vector2(r.end.x - 3.0, st.y), Color(0.94, 0.94, 0.90, 0.85), 1.2)
	# perforated stainless steel net plate (xarxa metallica Benito)
	b.line(Vector2(st.x, r.position.y - 4.0), Vector2(st.x, r.end.y + 4.0), Color(0.70, 0.72, 0.76), 3.2)
	b.line(Vector2(st.x + 1.0, r.position.y - 4.0), Vector2(st.x + 1.0, r.end.y + 4.0), Color(0.42, 0.44, 0.46), 1.0)
	for ny in range(7):
		var py := r.position.y + 4.0 + float(ny) * 6.0
		b.circle(Vector2(st.x, py), 1.0, Color(0.22, 0.24, 0.26))
	b.circle(Vector2(st.x, r.position.y - 4.0), 2.2, Color(0.35, 0.35, 0.38))
	b.circle(Vector2(st.x, r.end.y + 4.0), 2.2, Color(0.35, 0.35, 0.38))
	# two ping-pong paddles (pales) left on table corner
	# red paddle (face up)
	b.line(st + Vector2(33.0, -11.0), st + Vector2(39.0, -8.0), Color(0.68, 0.52, 0.36), 2.2)
	b.circle(st + Vector2(28.0, -14.0), 4.2, Color(0.85, 0.22, 0.18))
	# black paddle (underneath)
	b.line(st + Vector2(36.0, -19.0), st + Vector2(42.0, -21.0), Color(0.68, 0.52, 0.36), 2.0)
	b.circle(st + Vector2(32.0, -18.0), 4.0, Color(0.18, 0.18, 0.20))
	# white celluloid ball (pilota)
	b.circle(st + Vector2(-16.0, 10.0) + LIGHT * 1.0, 2.0, Color(0, 0, 0, 0.15))
	b.circle(st + Vector2(-16.0, 10.0), 2.0, Color(0.98, 0.98, 0.95))
	b.circle(st + Vector2(-16.5, 9.5), 0.8, Color(1, 1, 1))
	b.flush(_wc)


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


# El Parc's playground (systems/parc.gd); El Barri's square asks main
func _playground(b: ShapeBatch, pg: Rect2) -> void:
	Parc.playground(self, b, pg)


func _draw_palm(c: Object, p: Vector2) -> void:
	_palm_ground(c, p)
	var crown := ShapeBatch.new()
	_palm_crown(crown, p)
	crown.flush(c)


# a palm's shadow copies the frond pattern, which is what makes the beach read
# as glaring midday sun
func _palm_ground(c: Object, p: Vector2) -> void:
	var sh := p + LIGHT * 40.0
	for j in range(7):
		var sa := TAU * float(j) / 7.0 + p.x * 0.01 + p.y * 0.007
		c.draw_line(sh, sh + Vector2.from_angle(sa) * 34.0,
			Color(SHADOW_COL.r, SHADOW_COL.g, SHADOW_COL.b, 0.14), 7.0)


# a palm from above: a ring of long fronds, each with a spine and leaflets,
# radiating from a fat trunk
func _palm_crown(crown: ShapeBatch, p: Vector2, trunk := true) -> void:
	var t := AnimClock.msec() / 1000.0
	for j in range(7):
		var fa := TAU * float(j) / 7.0 + p.x * 0.01 + p.y * 0.007
		# the whole frond nods in the sea breeze
		fa += sin(t * 0.7 + float(j) * 1.3 + p.y * 0.01) * 0.05
		var dir := Vector2.from_angle(fa)
		var tip := p + dir * 38.0
		crown.line(p, tip, Color(0.20, 0.36, 0.19), 6.0)
		crown.line(p, tip, Color(0.29, 0.47, 0.24), 3.0)
		# leaflets down both sides of the spine
		var side := dir.orthogonal()
		for k in range(4):
			var f := 0.35 + float(k) * 0.2
			var at := p + dir * (38.0 * f)
			var ln := 9.0 * (1.0 - f * 0.5)
			crown.line(at, at + (side + dir * 0.5).normalized() * ln, Color(0.24, 0.41, 0.21), 2.5)
			crown.line(at, at - (side - dir * 0.5).normalized() * ln, Color(0.24, 0.41, 0.21), 2.5)
	# the trunk's top, and the coconuts nobody should be under
	if trunk:
		_palm_trunk(crown, p)


func _palm_trunk(b: Object, p: Vector2) -> void:
	b.circle(p, 9.0, Color(0.34, 0.26, 0.17))
	b.circle(p + Vector2(-2, -2), 6.0, Color(0.48, 0.38, 0.25))
	b.circle(p + Vector2(5, 4), 3.4, Color(0.28, 0.22, 0.14))
	b.circle(p + Vector2(-4, 5), 3.0, Color(0.28, 0.22, 0.14))


func _draw_lamppost(p: Vector2) -> void:
	# A lamppost seen from above is mostly a shadow: the column is directly
	# under the lantern, so the long shadow lying away from it is what tells
	# you it is three metres tall and not a manhole cover.
	cast_shadow(_wc, p, 6.0, 52.0, 0.18)
	if not Game.night:
		_wc.draw_circle(p, 62.0, Color(1.0, 0.9, 0.6, 0.08))
	# the base plinth it is bolted to
	_wc.draw_circle(p + Vector2(0, 2), POLE_RADIUS + 6.0, Color(0.24, 0.24, 0.27))
	_wc.draw_circle(p + Vector2(0, 1), POLE_RADIUS + 3.5, Color(0.33, 0.33, 0.36))
	# the fluted column, lit down one side
	_wc.draw_circle(p, POLE_RADIUS, Color(0.38, 0.38, 0.42))
	_wc.draw_circle(p + Vector2(-1.5, -1.5), POLE_RADIUS * 0.62, Color(0.52, 0.52, 0.57))
	# (its head, up top, is overhead: _lamp_head)


const LAMP_ARMS: Array[Vector2] = [Vector2(11, 0), Vector2(-11, 0), Vector2(0, 11), Vector2(0, -11)]


# a lamppost's head: four cross arms, each with a lantern on the end, glass and
# all. Overhead (draw_overhead_piece): the rope wound on the column runs under it.
func _lamp_head(b: ShapeBatch, p: Vector2) -> void:
	for bo: Vector2 in LAMP_ARMS:
		b.line(p, p + bo, Color(0.30, 0.30, 0.33), 3.5)
		b.line(p, p + bo, Color(0.46, 0.46, 0.5), 1.5)
		var lp := p + bo * 1.4
		b.circle(lp, 5.0, Color(0.26, 0.26, 0.29))
		if Game.night:
			b.circle(lp, 7.5, SkyLook.light(Color(1.0, 0.90, 0.62, 0.40), night_cm.color))
			b.circle(lp, 3.6, SkyLook.light(Color(1.0, 0.97, 0.86), night_cm.color))
		else:
			b.circle(lp, 3.6, Color(0.86, 0.88, 0.9))


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
	if lvl == "rain":
		surround = Color(0.38, 0.35, 0.37)
	if lvl == "montjuic":
		surround = Montjuic.RAMPART.darkened(0.2)
	elif lvl == "guell":
		surround = Mosaic.HILL_SCRUB
	# El Gòtic's roofscape runs on under the gate's last few feet, from the
	# edge layer: stop short of it rather than paint a grey band over it
	c.draw_rect(Rect2(-400.0, GATE_Y - 2400.0, 2100.0, 2370.0 if lvl == "oldtown" else 2400.0), surround)
	# Montjuic's off-leash space is a plaça in everything but its look: the
	# castle's esplanade
	if walk_mod != null and walk_mod.has_method("draw_freedom"):
		# Montjuic's castle esplanade, Dia de Partit's square beside the
		# stadium, El Port's Plaça del Far
		walk_mod.draw_freedom(self, c)
	else:
		if walk_mod != null and walk_mod.has_method("draw_freedom_beyond"):
			walk_mod.draw_freedom_beyond(self, c)
		else:
			_draw_freedom_beyond(c)
		match freedom_kind:
			"beach": _draw_dog_beach(c)
			"clearing": _draw_clearing(c)
			"lot": _draw_yard(c, true)
			"placa": _draw_placa(c)
			_:
				if walk_mod != null and walk_mod.has_method("draw_freedom_ground"):
					walk_mod.draw_freedom_ground(self, c)
				else:
					_draw_yard(c, false)
	# the grove stands in the off-leash area, so it is static too. It used to be
	# drawn every frame in the world, with its own near-duplicate tree
	# renderer: 16 trees at ~20 draw calls each, measured at over a
	# millisecond, for a picture that never changed.
	# The grove doubles as rope-wrap geometry, so it exists on every walk and
	# has to be drawn on every walk - but a broadleaf on a beach is nonsense,
	# so it wears whatever that place grows.
	# Its crowns are the canopy layer's (world/canopylayer.gd), above her.
	for ti in range(trees.size()):
		var t: Vector2 = trees[ti]
		if walk_mod != null and walk_mod.has_method("draw_grove"):
			walk_mod.draw_grove(self, c, t, ti)
		elif freedom_kind == "beach" or lvl == "beach":
			_draw_tree_ground(c, t, 0, TREE_PALM)
		elif lvl == "barri":
			_draw_tree_ground(c, t, 0, TREE_OAK)
		else:
			_draw_tree_ground(c, t, 1, TREE_FOREST)
	_draw_park_props(c, -1e9, 1e9)


# Off the leash the camera follows her sideways too. On the walk its x is
# fixed at 640 and the path fits the view; the off-leash space is wider than
# the view at play zoom (and far wider on a phone), so she could run off
# either side, and on the beach swim out of sight. It follows her, clamped so
# the view never shows past the space's walls.
func _cam_x() -> float:
	if detour_active:
		return Detour.cam_x(self)
	# off the leash, or on it again but still inside the space going home;
	# never on the way out, where the path fits the view
	var inside := dog.global_position.y < GATE_Y + 20.0
	if not (phase == "freedom" or (phase == "home" and inside)):
		return 640.0
	var hw := get_viewport_rect().size.x / (2.0 * cam.zoom.x)
	var lo := FREEDOM_WALL_W + 50.0 if (freedom_kind == "beach" or lvl == "beach") else _freedom_rect().position.x - 20.0
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
			# the wood goes on: canopy over canopy, darker the deeper in (on
			# El Mosaic's hilltop, the dusty olive of pine and holm oak)
			var dry := lvl == "guell"
			for row in range(4):
				var cy := top - 40.0 - float(row) * 95.0
				var cx := -380.0 + float(row % 2) * 60.0
				while cx < 1700.0:
					var rr := 54.0 + fmod(absf(cx) * 0.37 + float(row) * 13.0, 22.0)
					var dk := 0.06 * float(row)
					b.circle(Vector2(cx, cy) + LIGHT * 16.0, rr, Color(0.08, 0.12, 0.08, 0.3))
					if dry:
						b.circle(Vector2(cx, cy), rr, Color(0.30 - dk, 0.34 - dk, 0.20 - dk))
						b.circle(Vector2(cx, cy) - LIGHT * rr * 0.3, rr * 0.55, Color(0.38 - dk, 0.42 - dk, 0.25 - dk))
					else:
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
			b.rect(Rect2(-400.0, top - 2000.0, BEACH_SEA_R + 400.0, 1960.0), BEACH_SEA_DEEP)
			b.rect(Rect2(BEACH_SEA_R - BEACH_SHALLOW_W, top - 2000.0, BEACH_SHALLOW_W, 1960.0), BEACH_SEA_SHALLOW)
			b.rect(Rect2(BEACH_SEA_R, top - 2000.0, 70.0, 1960.0), BEACH_WET)
	b.flush(c)


# THE GATE, as the place would have it. It was a dark bar across the path
# over a dashed line, which read as a road to cross on every walk, the forest
# included. Now: timber posts and no sill on the walks that end in nature,
# stone gateposts and a stone sill in town, and an iron dog-park gate with its
# two leaves swung open everywhere else. Same mouth, gate_l to gate_r.
func _draw_gate() -> void:
	var b := ShapeBatch.new()
	var style := "iron"
	if lvl in ["trail", "guell", "park", "llevant"] and not tutorial_mode:
		style = "timber"
	elif freedom_kind == "placa" or lvl == "rain":
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
	if walk_mod != null and walk_mod.has_method("draw_gate_fence"):
		walk_mod.draw_gate_fence(self, b, gl, gr, gy)
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
	if walk_mod != null and walk_mod.has_method("draw_yard"):
		walk_mod.draw_yard(self, c, r)
	_draw_freedom_fence(c, r, gravel)
	_draw_freedom_benches(c, r, Color(0.5, 0.38, 0.26))
	_freedom_sign(c, r, gate_text, "the off-leash yard" if gravel else "the off-leash dog park")


# EL BARRI's PIPICÀ: the fenced dog area every neighbourhood park has. Raked
# sauló worn darker where the dogs run, a green steel mesh fence all round,
# the bag dispenser and a bin inside the gate, the benches for the owners.


# EL PORXO, El Diluvi's off-leash yard: a courtyard with a covered porch
# round three sides. The porch is dry terracotta tile in the shade of its
# roof, stone columns along its open edge; the court in the middle is wet
# sauló, puddled, the grove's trees growing out of it. Stone walls, not a
# chain-link fence; the porch roofs' pantiles go on past the walls.
const PORXO_W := 96.0              # the porch's depth, from the wall to the columns
const PORXO_BAY := 111.0           # column spacing


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
	# the house fronts along the top and both sides, each with its cornice,
	# its balconies (shutters either side of the window, an iron rail, a
	# stone slab, a pot of something), and its door in a stone surround
	var k := 0
	var fx := r.position.x
	while fx < r.end.x:
		var w := minf(150.0, r.end.x - fx)
		_draw_house_front(c, Vector2(fx, r.position.y - 46.0), Vector2.RIGHT, Vector2.DOWN, w, 46.0, k)
		fx += 150.0
		k += 1
	for sx: float in [r.position.x - 40.0, r.end.x]:
		var fy := r.position.y
		k = 1
		var west: bool = sx < r.position.x
		while fy < r.end.y - 60.0:
			# laid along the side wall, the street side toward the square
			var o := Vector2(sx, fy) if west else Vector2(sx + 40.0, fy)
			_draw_house_front(c, o, Vector2.DOWN, Vector2.RIGHT if west else Vector2.LEFT, 130.0, 40.0, k)
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
	if walk_mod != null and walk_mod.has_method("draw_yard"):
		walk_mod.draw_yard(self, c, r)
	_draw_freedom_benches(c, r, Color(0.36, 0.30, 0.24))
	_freedom_sign(c, r, "PLAÇA DELS GOSSOS", "the festival square, off leash" if lvl == "spook" else "the dogs' square, off leash")


const HOUSE_COLS: Array[Color] = [Color(0.62, 0.44, 0.34), Color(0.70, 0.58, 0.42), Color(0.56, 0.48, 0.44)]
const SHUTTER_COLS: Array[Color] = [Color(0.30, 0.50, 0.36), Color(0.52, 0.36, 0.22), Color(0.50, 0.62, 0.66)]


# One house front as the square sees it: o is its outer top corner, along the
# direction the front runs, inward toward the square; u runs along it and v
# from the cornice (0) to the pavement (depth).
func _draw_house_front(c: Object, o: Vector2, along: Vector2, inward: Vector2, length: float, depth: float, k: int) -> void:
	var col: Color = HOUSE_COLS[k % 3]
	var shutter: Color = SHUTTER_COLS[(k + 1) % 3]
	var stone := Color(0.74, 0.70, 0.62)
	var iron := Color(0.14, 0.14, 0.16)
	_front_rect(c, o, along, inward, 0.0, 0.0, length, depth, col)
	_front_rect(c, o, along, inward, 0.0, 0.0, length, 4.0, col.lightened(0.22))
	_front_rect(c, o, along, inward, 0.0, 4.0, length, 2.0, col.darkened(0.28))
	_front_rect(c, o, along, inward, 0.0, depth - 6.0, length, 6.0, col.darkened(0.3))
	if length >= 110.0:
		for u: float in [26.0, length - 26.0]:
			_front_rect(c, o, along, inward, u - 13.0, 9.0, 6.0, 15.0, shutter)
			_front_rect(c, o, along, inward, u + 7.0, 9.0, 6.0, 15.0, shutter)
			_front_rect(c, o, along, inward, u - 7.0, 9.0, 14.0, 15.0, Color(0.18, 0.20, 0.24))
			_front_rect(c, o, along, inward, u - 7.0, 9.0, 14.0, 3.0, Color(0.34, 0.38, 0.44))
			_front_rect(c, o, along, inward, u - 16.0, 25.0, 32.0, 3.0, stone)
			_front_rect(c, o, along, inward, u - 15.0, 19.0, 30.0, 1.6, iron)
			for bu: float in [-12.0, -6.0, 0.0, 6.0, 12.0]:
				_front_rect(c, o, along, inward, u + bu - 0.6, 19.0, 1.2, 6.0, iron)
			if (k + int(u)) % 2 == 0:
				_front_rect(c, o, along, inward, u + 9.0, 20.0, 5.0, 5.0, Color(0.62, 0.34, 0.22))
				_front_rect(c, o, along, inward, u + 9.0, 17.0, 5.0, 4.0, Color(0.30, 0.48, 0.24))
	var uc := length * 0.5
	_front_rect(c, o, along, inward, uc - 15.0, depth - 33.0, 30.0, 33.0, stone)
	_front_rect(c, o, along, inward, uc - 11.0, depth - 29.0, 22.0, 29.0, Color(0.30, 0.18, 0.12) if k % 2 == 0 else Color(0.18, 0.28, 0.24))
	_front_rect(c, o, along, inward, uc - 0.6, depth - 27.0, 1.2, 27.0, Color(0.10, 0.08, 0.07))
	_front_rect(c, o, along, inward, uc - 11.0, depth - 29.0, 22.0, 4.0, Color(0.12, 0.10, 0.09))
	_front_rect(c, o, along, inward, uc - 17.0, depth - 2.5, 34.0, 2.5, stone.lightened(0.12))


func _front_rect(c: Object, o: Vector2, along: Vector2, inward: Vector2, u: float, v: float, du: float, dv: float, col: Color) -> void:
	var a := o + along * u + inward * v
	var z := o + along * (u + du) + inward * (v + dv)
	c.draw_rect(Rect2(a, Vector2.ZERO).expand(z), col)


func _draw_clearing(c: Object) -> void:
	# a clearing in the woods: no fence, because nothing out here is fenced.
	# The trees ARE the boundary, drawn with the same renderer as the ones on
	# the trail so it reads as the same wood.
	var r := _freedom_rect()
	if walk_mod != null and walk_mod.has_method("draw_clearing"):
		walk_mod.draw_clearing(self, c, r)
		return
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
	c.draw_rect(r, BEACH_SAND)
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
	# The same sea as the walk's, band for band, so the two meet without a
	# seam at the gate line (#151): the shallows are as wide, and the wet
	# sand narrows to the walk's own strip of it on the way in.
	c.draw_colored_polygon(shore, BEACH_SEA_DEEP)
	var shallow := PackedVector2Array([
		Vector2(beach_shore_x(top_y) - BEACH_SHALLOW_W, top_y), Vector2(beach_shore_x(top_y), top_y),
		Vector2(beach_shore_x(bend_y), bend_y), Vector2(beach_shore_x(bot_y), bot_y),
		Vector2(beach_shore_x(bot_y) - BEACH_SHALLOW_W, bot_y),
		Vector2(beach_shore_x(bend_y) - BEACH_SHALLOW_W, bend_y),
	])
	c.draw_colored_polygon(shallow, BEACH_SEA_SHALLOW)
	var wet := PackedVector2Array([
		Vector2(beach_shore_x(top_y), top_y), Vector2(beach_shore_x(top_y) + 70.0, top_y),
		Vector2(beach_shore_x(bend_y) + 70.0, bend_y),
		Vector2(beach_shore_x(bot_y) + BEACH_WET_W, bot_y),
		Vector2(beach_shore_x(bot_y), bot_y), Vector2(beach_shore_x(bend_y), bend_y),
	])
	c.draw_colored_polygon(wet, BEACH_WET)
	# driftwood and tide drift line along the dog beach waterline
	var db := ShapeBatch.new()
	var dby := top_y + 30.0
	while dby < bot_y - 20.0:
		var dsx := beach_shore_x(dby) + BEACH_WET_W * 0.8
		var dpk := absi(int(dby * 0.17)) % 4
		if dpk == 0:
			db.circle(Vector2(dsx, dby) + LIGHT * 1.5, 2.5, Color(SHADOW_COL.r, SHADOW_COL.g, SHADOW_COL.b, 0.20))
			db.circle(Vector2(dsx, dby), 2.4, Color(0.50, 0.48, 0.44))
			db.circle(Vector2(dsx - 0.7, dby - 0.7), 1.2, Color(0.68, 0.66, 0.62))
		elif dpk == 1:
			db.polygon(PackedVector2Array([
				Vector2(dsx, dby - 2.0), Vector2(dsx + 4.0, dby),
				Vector2(dsx, dby + 2.0)
			]), Color(0.96, 0.93, 0.88))
		elif dpk == 2:
			# stranded smooth driftwood stick
			db.line(Vector2(dsx, dby), Vector2(dsx + 8.0, dby + 2.0), Color(0.42, 0.32, 0.22), 2.0)
		dby += 44.0
	db.flush(c)
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
	# (the walk has the same two, from the same drawing code)
	_draw_beach_shower(c, Vector2(BEACH_SEA_R + 150.0, r.position.y + 120.0))
	# the tower's legs and ladder; on the seafront walk its cabin is over
	# everyone (the overhead layer, draw_overhead_onto)
	_draw_lifeguard_tower(c, dog_beach_tower(), true, lvl != "beach" and lvl != "llevant")
	# the parasols, spaced round the agility lane (which runs between the
	# first two): here the shade each casts falling clear of it, and their
	# canopies overhead (draw_overhead_piece)
	for pa: Vector2 in beach_parasol_spots():
		contact_shadow(c, pa, BEACH_PARASOL_R, 30.0, 0.20)
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
	"beach": "sand", "llevant": "sand", "park": "dirt", "trail": "dirt", "barri": "dirt",
	"station": "board", "site": "board", "scrap": "board",
	"rain": "wet", "oldtown": "tile", "tutorial": "chalk",
}


# Light sign colour, undone against the night tint, so a chalk stroke or a
# lit board stays the colour it was painted. Dark strokes are left to the
# tint, which keeps them sitting in the ground instead of floating on it.
func _sign_ink(col: Color) -> Color:
	var lum := col.r * 0.30 + col.g * 0.59 + col.b * 0.11
	if lum < 0.55 or night_cm == null:
		return col
	return SkyLook.light(col, night_cm.color)


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
		_wc.draw_char(f, Vector2(-w * 0.5, 0.0), ch, px, _sign_ink(col))
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
			_wc.draw_rect(r, _sign_ink(Color(0.90, 0.88, 0.82)))
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
			_wc.draw_rect(br, _sign_ink(Color(0.40, 0.42, 0.44)), false, 3.0)
			_wc.draw_rect(Rect2(br.position.x + 4.0, br.position.y + 4.0, br.size.x - 8.0, 3.0),
				Color(1, 1, 1, 0.10))
			_hand_text(at, txt, px, Color(0.98, 0.78, 0.28, 0.95), 0.0, key)


# the tutorial walks another walk's ground, but it is still the First Walk
func _walk_name() -> String:
	return String(Game.LEVEL_NAMES["tutorial" if tutorial_mode else lvl])


func _sign_mat() -> String:
	return WorldSign.material_for("tutorial" if tutorial_mode else lvl, Game.weather)


# The name and the browse arrows, as loose pieces for a walk with a
# material. Built from what the title step says; the same step twice keeps
# the pieces where they are. The way in is the arrival (systems/arrival.gd),
# not a word on the ground.
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
	var born := AnimClock.msec() / 1000.0
	var bed: Color = WorldSign.BEDS.get("tutorial" if tutorial_mode else lvl, Color(0, 0, 0, 0))
	if Game.weather == "snow":
		bed = Color(0, 0, 0, 0)
	if menu_step == 0 and not started:
		signs.append(WorldSign.build("PATH OF", Vector2(mid, START_Y - 232.0), 44.0, mat, 1.0, room))
		signs.append(WorldSign.build("LEASH RESISTANCE", Vector2(mid, START_Y - 172.0), 44.0, mat, 2.0, room))
		for sg: Dictionary in signs:
			sg.born = born
			sg.bed = bed
	else:
		var name := _walk_name()
		# the name stays on the path, inside its edges where the letters lie: a
		# long one breaks onto two lines or, where it cannot, comes down in size
		var span := name_span()
		var nroom := minf(span.y - span.x - NAME_MARGIN, NAME_MAX_W)
		var nm := WorldSign.build_name(name, Vector2((span.x + span.y) * 0.5, NAME_Y), NAME_H, mat, 4.0, nroom, bed)
		nm.born = born
		signs.append(nm)
		_name_baseline = float(nm.baseline)
		# (the walk select's browse arrows are on its card, hud/menu_screen.gd,
		# so the name has its path to itself and one size on every screen)
	# over the gate, what is through it and what that means, in the same stuff
	var gm := (gate_l + gate_r) * 0.5
	var gw := maxf(160.0, gate_r - gate_l - 20.0)
	# traffic cones are fat pieces: small words in them are a pile of cones
	var gk := 1.8 if mat == "cones" else 1.0
	signs.append(WorldSign.build(gate_text, Vector2(gm, GATE_Y - 72.0 * gk), 36.0 * gk, mat, 11.0, gw))
	# and the small line no smaller than the cones can still spell
	var ok := 30.0 * gk if mat == "cones" else 24.0
	signs.append(WorldSign.build("OFF LEASH", Vector2(gm, GATE_Y - 124.0 * gk - 4.0), ok, mat, 12.0, gw))


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
	if menu_step != 0 or started:
		var ns := name_span()
		mid = (ns.x + ns.y) * 0.5
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
	# On the walk select the plaque says it, in type. Here it is the line
	# under the name as the walk begins, and it has to read on any ground.
	var gloss := Game.gloss("tutorial" if tutorial_mode else lvl)
	if gloss != "":
		_draw_gloss(Vector2(mid, gloss_baseline(y)), gloss)


# The stretch of path every row of a walk's name and its gloss lies on, as
# (left, right): the narrowest the path gets between the name's top and the
# gloss, so a name on a bend (Montjuïc) sits on the path, not the grass.
func name_span() -> Vector2:
	var lo := -INF
	var hi := INF
	var y := NAME_Y - NAME_H
	while y <= NAME_Y + NAME_H * 1.6 + GLOSS_GAP:
		var e := walk_edges(y)
		lo = maxf(lo, e.x)
		hi = minf(hi, e.y)
		y += 8.0
	return Vector2(lo, hi)


# where the gloss's baseline is: its cap line GLOSS_GAP under the name's
func gloss_baseline(fallback_y := START_Y - 190.0) -> float:
	var base := _name_baseline if _sign_mat() != "" else fallback_y
	return base + GLOSS_GAP + float(GLOSS_PX) * 0.72


# The line under the name, in the player's language. No box: cream type with a
# dark outline and a soft shadow, so it reads by brightness on sand, grass,
# snow, wet paving and a night street, whatever colours the reader can tell
# apart. Drawn so the night tint cannot grey it.
const GLOSS_PX := 28
func _draw_gloss(at: Vector2, txt: String) -> void:
	if gloss_a <= 0.01:
		return
	var f: Font = load("res://hud/ui_kit.gd").body()
	# on the path too: a long gloss on a narrow walk comes down in size
	var ge := walk_edges(at.y)
	var px := GLOSS_PX
	var w: float = f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
	if w > ge.y - ge.x - NAME_MARGIN:
		px = maxi(18, int(float(GLOSS_PX) * (ge.y - ge.x - NAME_MARGIN) / w))
		w = f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
	var x0 := at.x - w * 0.5
	if not started and menu_step == 2 and cam != null:
		var vw: float = get_viewport_rect().size.x / cam.zoom.x
		x0 = maxf(x0, cam.position.x - vw * 0.5 + GLOSS_CLEAR_X / cam.zoom.x)
	var o := Vector2(x0, at.y)
	var tint: Color = night_cm.color if night_cm != null else Color.WHITE
	_wc.draw_string_outline(f, o + Vector2(2.0, 3.0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, px, 10,
		SkyLook.light(Color(0.02, 0.02, 0.04, 0.35 * gloss_a), tint))
	_wc.draw_string_outline(f, o, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, px, 7,
		SkyLook.light(Color(0.08, 0.07, 0.10, 0.92 * gloss_a), tint))
	_wc.draw_string(f, o, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, px,
		SkyLook.light(Color(0.99, 0.96, 0.88, gloss_a), tint))


# An outdoor shower from above: a steel column on a slatted timber footplate,
# the rose over it and the drip below. The dog beach's (it refills the tank)
# and the two at the top of the sand on the walk.
func _draw_beach_shower(c: Object, sh: Vector2) -> void:
	var b := ShapeBatch.new()
	var plate := Rect2(sh.x - 15.0, sh.y - 13.0, 30.0, 30.0)
	b.rect(Rect2(plate.position + LIGHT * 3.0, plate.size), Color(SHADOW_COL.r, SHADOW_COL.g, SHADOW_COL.b, 0.16))
	b.rect(plate, Color(0.50, 0.38, 0.26))
	for k in range(5):
		var sx := plate.position.x + 1.0 + float(k) * 6.0
		b.rect(Rect2(sx, plate.position.y + 1.0, 4.0, plate.size.y - 2.0),
			Color(0.64, 0.50, 0.34))
		b.circle(Vector2(sx + 2.0, plate.position.y + 3.0), 0.8, Color(0.35, 0.25, 0.15))
		b.circle(Vector2(sx + 2.0, plate.end.y - 3.0), 0.8, Color(0.35, 0.25, 0.15))
	# the puddle it always leaves, darker sand round the plate
	b.circle(sh + Vector2(10.0, 16.0), 10.0, Color(0.55, 0.50, 0.40, 0.35))
	# stainless drainage grate set into the puddle
	var drain := Rect2(sh.x + 5.0, sh.y + 11.0, 10.0, 10.0)
	b.rect(drain, Color(0.60, 0.62, 0.64))
	b.rect(drain.grow(-1.5), Color(0.42, 0.44, 0.46))
	for dxi in range(3):
		var gx := drain.position.x + 2.5 + float(dxi) * 2.5
		b.line(Vector2(gx, drain.position.y + 2.0), Vector2(gx, drain.end.y - 2.0), Color(0.24, 0.25, 0.26), 1.0)
	# wet duckboard sheen
	b.circle(sh + Vector2(0.0, -8.0), 6.0, Color(0.40, 0.28, 0.18, 0.4))
	b.flush(c)
	cast_shadow(c, sh, 5.0, 34.0)
	c.draw_circle(sh, 7.0, Color(0.68, 0.70, 0.72))
	# upper shower column and rose
	c.draw_line(sh, sh + Vector2(0, -16.0), Color(0.76, 0.78, 0.80), 4.0)
	c.draw_circle(sh + Vector2(0, -18.0), 5.0, Color(0.82, 0.86, 0.88))
	# lower foot-wash tap (rentapeus)
	c.draw_line(sh, sh + Vector2(0.0, 8.0), Color(0.74, 0.76, 0.78), 3.0)
	c.draw_circle(sh + Vector2(0.0, 8.0), 2.6, Color(0.85, 0.88, 0.90))
	c.draw_line(sh + Vector2(-3.0, 7.5), sh + Vector2(3.0, 7.5), Color(0.60, 0.62, 0.65), 1.5)
	c.draw_circle(sh + Vector2(0.0, 12.0), 1.4, Color(0.7, 0.86, 0.95, 0.6))
	for di in range(4):
		c.draw_line(sh + Vector2(-6.0 + float(di) * 4.0, -14.0),
			sh + Vector2(-6.0 + float(di) * 4.0, -4.0), Color(0.7, 0.86, 0.95, 0.5), 1.5)


# A lifeguard tower from above, in two parts so the walk's can stand over her:
# the legs, ladder and long shadow on the sand, and the yellow cabin with its
# flag, which the walk draws on the overhead layer and the dog beach draws on
# its own canvas with the rest.
func _draw_lifeguard_tower(c: Object, lg: Vector2, legs: bool, cabin: bool) -> void:
	var b := ShapeBatch.new()
	if legs:
		var shade := Color(SHADOW_COL.r, SHADOW_COL.g, SHADOW_COL.b, 0.20)
		# a tall thing announces itself by its shadow: the cabin's, well clear
		b.rect(Rect2(lg + LIGHT * 46.0 - Vector2(15.0, 15.0), Vector2(30.0, 30.0)), shade)
		for lo: Vector2 in [Vector2(-20, -20), Vector2(20, -20), Vector2(-20, 20), Vector2(20, 20)]:
			b.line(lg + lo, lg + lo + LIGHT * 44.0, shade, 3.0)
			b.circle(lg + lo, 3.6, Color(0.30, 0.28, 0.24))
			b.circle(lg + lo + Vector2(-0.8, -0.8), 2.2, Color(0.92, 0.92, 0.88))
		# cross-bracing diagonal shadows on the sand
		b.line(lg + Vector2(-20, -20) + LIGHT * 22.0, lg + Vector2(20, 20) + LIGHT * 22.0, shade, 1.2)
		b.line(lg + Vector2(20, -20) + LIGHT * 22.0, lg + Vector2(-20, 20) + LIGHT * 22.0, shade, 1.2)
		# structural perimeter tie-beams between leg footings
		b.line(lg + Vector2(-20, -20), lg + Vector2(20, -20), Color(0.72, 0.70, 0.65), 1.5)
		b.line(lg + Vector2(-20, 20), lg + Vector2(20, 20), Color(0.72, 0.70, 0.65), 1.5)
		b.line(lg + Vector2(-20, -20), lg + Vector2(-20, 20), Color(0.72, 0.70, 0.65), 1.5)
		# hanging lifebuoy ring (salva-vides) on the seaward stanchion
		var bp := lg + Vector2(-19.0, 8.0)
		b.circle(bp + LIGHT * 10.0, 4.5, shade)
		b.circle(bp, 4.5, Color(0.96, 0.44, 0.14))
		b.circle(bp, 2.2, Color(0.85, 0.80, 0.68))
		b.rect(Rect2(bp.x - 1.0, bp.y - 4.5, 2.0, 9.0), Color(0.98, 0.98, 0.98))
		b.rect(Rect2(bp.x - 4.5, bp.y - 1.0, 9.0, 2.0), Color(0.98, 0.98, 0.98))
		b.circle(bp, 2.0, Color(0.85, 0.80, 0.68))
		# the ladder up the landward side
		var l0 := lg + Vector2(17.0, -6.0)
		for side: float in [0.0, 12.0]:
			b.line(l0 + Vector2(0.0, side), l0 + Vector2(26.0, side), Color(0.88, 0.86, 0.80), 2.0)
		for rung in range(5):
			var rx := l0.x + 4.0 + float(rung) * 5.0
			b.line(Vector2(rx, l0.y), Vector2(rx, l0.y + 12.0), Color(0.80, 0.78, 0.72), 1.5)
	if cabin:
		b.rect(Rect2(lg.x - 14.0, lg.y - 14.0, 30.0, 30.0), Color(SHADOW_COL.r, SHADOW_COL.g, SHADOW_COL.b, 0.25))
		b.rect(Rect2(lg.x - 17.0, lg.y - 17.0, 34.0, 34.0), Color(0.62, 0.56, 0.22))
		b.rect(Rect2(lg.x - 15.0, lg.y - 15.0, 30.0, 30.0), Color(0.86, 0.80, 0.34))
		b.rect(Rect2(lg.x - 9.0, lg.y - 9.0, 18.0, 18.0), Color(0.94, 0.90, 0.58))
		b.rect(Rect2(lg.x - 15.0, lg.y - 15.0, 30.0, 4.0), Color(0.80, 0.26, 0.20))
		# Salvament de Platges emblem: red cross on white square
		b.rect(Rect2(lg.x - 4.0, lg.y - 4.0, 8.0, 8.0), Color(0.98, 0.98, 0.96))
		b.rect(Rect2(lg.x - 1.0, lg.y - 3.0, 2.0, 6.0), Color(0.86, 0.18, 0.16))
		b.rect(Rect2(lg.x - 3.0, lg.y - 1.0, 6.0, 2.0), Color(0.86, 0.18, 0.16))
		# public announcement horn / speaker pointing seaward
		b.circle(lg + Vector2(-15.0, 12.0), 2.0, Color(0.35, 0.35, 0.38))
		b.polygon(PackedVector2Array([
			lg + Vector2(-15.0, 10.5), lg + Vector2(-22.0, 7.5),
			lg + Vector2(-22.0, 16.5), lg + Vector2(-15.0, 13.5)
		]), Color(0.84, 0.84, 0.82))
		b.line(lg + Vector2(-22.0, 7.5), lg + Vector2(-22.0, 16.5), Color(0.30, 0.30, 0.32), 1.5)
		# the flag on its pole at the seaward corner: green, swim away
		var fp := lg + Vector2(-17.0, -17.0)
		b.circle(fp, 2.4, Color(0.36, 0.36, 0.38))
		b.polygon(PackedVector2Array([fp + Vector2(-1.0, -1.0), fp + Vector2(-17.0, -6.0), fp + Vector2(-5.0, -12.0)]),
			Color(0.24, 0.62, 0.30))
	b.flush(c)


# the shade over a chiringuito's terrace: a timber pergola with reed matting
# laid across it, the tables showing through between the reeds. Overhead
# (draw_overhead_piece), into the canopy layer's batch.
func _draw_pergola(b: ShapeBatch, cn: Rect2) -> void:
	var ry := cn.position.y + 4.0
	var k := 0
	while ry < cn.end.y - 2.0:
		if k % 4 != 3:
			b.line(Vector2(cn.position.x + 2.0, ry), Vector2(cn.end.x - 2.0, ry), Color(0.84, 0.74, 0.50, 0.5), 3.0)
		ry += 5.0
		k += 1
	for bx: float in [cn.position.x + 3.0, cn.get_center().x, cn.end.x - 3.0]:
		b.line(Vector2(bx, cn.position.y), Vector2(bx, cn.end.y), Color(0.30, 0.20, 0.12, 0.35), 6.0)
		b.line(Vector2(bx, cn.position.y), Vector2(bx, cn.end.y), Color(0.52, 0.36, 0.22), 4.0)
	for corner: Vector2 in [cn.position, Vector2(cn.end.x, cn.position.y), Vector2(cn.position.x, cn.end.y), cn.end]:
		b.circle(corner, 5.0, Color(0.40, 0.28, 0.18))


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
			"log" when walk_mod != null and walk_mod.has_method("draw_log_prop"):
				walk_mod.draw_log_prop(self, c, p)
			"log":
				# a fallen log: bark, end grain, and a couple of knots
				var bark := Color(0.40, 0.30, 0.20)
				c.draw_rect(Rect2(p.x - 30.0, p.y - 9.0, 60.0, 18.0), bark)
				c.draw_rect(Rect2(p.x - 30.0, p.y - 9.0, 60.0, 5.0), bark.lightened(0.18))
				c.draw_circle(Vector2(p.x + 30.0, p.y), 9.0, Color(0.62, 0.50, 0.34))
				c.draw_arc(Vector2(p.x + 30.0, p.y), 5.0, 0, TAU, 10, Color(0.48, 0.38, 0.25), 1.5)
				c.draw_circle(Vector2(p.x - 8.0, p.y - 1.0), 3.0, bark.darkened(0.30))
			"driftwood":
				var pale := Color(0.72, 0.67, 0.58) if lvl == "besos" else Color(0.68, 0.63, 0.55)
				c.draw_rect(Rect2(p.x - 32.0, p.y - 6.0, 64.0, 12.0), pale)
				c.draw_line(p + Vector2(-32, -1), p + Vector2(32, -1), pale.darkened(0.22), 2.0)
				c.draw_line(p + Vector2(8, -6), p + Vector2(22, -16), pale, 5.0)
				if lvl == "besos":
					# flood-caught river reeds tangled against the upstream flank
					c.draw_line(p + Vector2(-18, 5), p + Vector2(6, 7), Color(0.56, 0.52, 0.34), 2.2)
					c.draw_circle(p + Vector2(-28, 0), 4.5, Color(0.46, 0.42, 0.34))
			"tyre":
				c.draw_circle(p, 17.0, Color(0.14, 0.14, 0.15))
				c.draw_circle(p, 9.0, Color(0.26, 0.30, 0.24))
				for i in range(10):
					var a := TAU * float(i) / 10.0
					c.draw_line(p + Vector2.from_angle(a) * 11.0, p + Vector2.from_angle(a) * 17.0, Color(0.24, 0.24, 0.26), 2.0)
			"rock" when lvl == "montjuic":
				# a pyramid of cast-iron fortress cannonballs on an ashlar plinth
				c.draw_rect(Rect2(p - Vector2(15, 13), Vector2(30, 26)), Color(0.66, 0.62, 0.54))
				c.draw_rect(Rect2(p - Vector2(15, 13), Vector2(30, 26)), Color(0.46, 0.43, 0.38), false, 1.5)
				for off: Vector2 in [Vector2(-6, -4), Vector2(6, -4), Vector2(-6, 5), Vector2(6, 5), Vector2(0, -1)]:
					c.draw_circle(p + off, 5.8, Color(0.16, 0.17, 0.19))
					c.draw_circle(p + off + Vector2(-1.8, -1.8), 2.0, Color(0.38, 0.40, 0.44))
			"rock" when lvl == "besos":
				# water-smoothed pale limestone river cobbles
				c.draw_circle(p + Vector2(-4, 1), 13.0, Color(0.68, 0.66, 0.60))
				c.draw_circle(p + Vector2(-6, -2), 8.5, Color(0.78, 0.76, 0.70))
				c.draw_circle(p + Vector2(9, 4), 8.0, Color(0.60, 0.58, 0.53))
				c.draw_circle(p + Vector2(7, 2), 4.5, Color(0.72, 0.70, 0.64))
			"rock":
				# faceted rather than round: a boulder is flat planes, and the
				# planes are what catch the light differently
				var rcol := Color(0.62, 0.48, 0.34) if lvl == "guell" else Color(0.46, 0.44, 0.42)
				var tcol := Color(0.76, 0.62, 0.46) if lvl == "guell" else Color(0.63, 0.61, 0.57)
				var rp := PackedVector2Array()
				for i in range(7):
					var a := TAU * float(i) / 7.0 + p.y * 0.01
					var rr := 13.0 + fmod(float(i) * 5.7 + p.x * 0.03, 4.0)
					rp.append(p + Vector2(cos(a) * rr, sin(a) * rr * 0.88))
				c.draw_colored_polygon(rp, rcol)
				var top := PackedVector2Array()
				for i in range(5):
					var a2 := TAU * float(i) / 5.0 + 0.4
					top.append(p - LIGHT * 4.0 + Vector2(cos(a2), sin(a2) * 0.9) * 8.0)
				c.draw_colored_polygon(top, tcol)
				c.draw_polyline(rp, rcol.darkened(0.25), 1.4)
			"post" when freedom_kind == "placa":
				# a cast-iron bollard, the barri's lamp-post for dogs
				c.draw_circle(p, 13.0, Color(0.52, 0.48, 0.42, 0.35))
				if lvl == "neteja":
					# a ring of white BCNeteja hose-down soap suds around the foot
					c.draw_arc(p, 11.5, 0, TAU, 14, Color(0.92, 0.96, 1.0, 0.55), 2.2)
				c.draw_circle(p, 7.0, Color(0.16, 0.17, 0.18))
				if lvl == "partit":
					c.draw_arc(p, 5.8, 0, PI, 8, Color(0.62, 0.12, 0.24), 2.0)
					c.draw_arc(p, 5.8, PI, TAU, 8, Color(0.12, 0.26, 0.58), 2.0)
				c.draw_circle(p + Vector2(-1.5, -1.5), 4.5, Color(0.28, 0.29, 0.31))
				c.draw_circle(p + Vector2(-2.0, -2.0), 1.6, Color(0.50, 0.52, 0.54))
			"planter":
				if lvl == "spook":
					# a castanyera's brazier: a steel drum on its legs, coals
					# glowing through the grille, sacks of chestnuts by it
					c.draw_circle(p, 48.0, Color(1.0, 0.60, 0.24, 0.10))
					contact_shadow(c, p, 18.0, 8.0, 0.25)
					c.draw_circle(p + Vector2(18, 14), 9.0, Color(0.62, 0.50, 0.34))
					c.draw_circle(p + Vector2(-17, 15), 8.0, Color(0.58, 0.47, 0.32))
					c.draw_circle(p, 17.0, Color(0.16, 0.15, 0.15))
					c.draw_circle(p, 13.0, Color(0.96, 0.44, 0.12))
					c.draw_circle(p, 8.0, Color(1.0, 0.78, 0.32))
					for g in range(3):
						c.draw_line(p + Vector2(-13.0, -6.0 + float(g) * 6.0), p + Vector2(13.0, -6.0 + float(g) * 6.0), Color(0.12, 0.10, 0.10), 1.5)
					continue
				if lvl == "market":
					# stacked wooden Boqueria fruit & produce crates outside the hall
					c.draw_rect(Rect2(p - Vector2(17, 15), Vector2(34, 30)), Color(0.68, 0.52, 0.32))
					c.draw_rect(Rect2(p - Vector2(17, 15), Vector2(34, 30)), Color(0.46, 0.34, 0.20), false, 2.0)
					c.draw_line(p + Vector2(-16, 0), p + Vector2(16, 0), Color(0.46, 0.34, 0.20), 2.0)
					for fo: Vector2 in [Vector2(-9, -7), Vector2(-2, -8), Vector2(7, -6)]:
						c.draw_circle(p + fo, 4.2, Color(0.92, 0.48, 0.14))
					for vo: Vector2 in [Vector2(-8, 7), Vector2(1, 6), Vector2(9, 7)]:
						c.draw_circle(p + vo, 4.2, Color(0.84, 0.22, 0.18))
					continue
				if lvl == "rain":
					# glazed terracotta Eixample interior-courtyard olive tub
					c.draw_circle(p, 17.0, Color(0.68, 0.36, 0.22))
					c.draw_circle(p, 13.5, Color(0.30, 0.22, 0.16))
					c.draw_circle(p, 11.5, Color(0.28, 0.42, 0.28))
					c.draw_circle(p - LIGHT * 3.5, 6.5, Color(0.42, 0.56, 0.38))
					continue
				# a stone planter with a clipped bush in it: solid, go round it
				c.draw_rect(Rect2(p - Vector2(17, 17), Vector2(34, 34)), Color(0.74, 0.70, 0.62))
				c.draw_rect(Rect2(p - Vector2(17, 17), Vector2(34, 34)), Color(0.56, 0.52, 0.46), false, 2.0)
				if lvl == "partit":
					c.draw_rect(Rect2(p.x - 16.0, p.y + 11.0, 16.0, 4.0), Color(0.12, 0.26, 0.58))
					c.draw_rect(Rect2(p.x, p.y + 11.0, 16.0, 4.0), Color(0.62, 0.12, 0.24))
				c.draw_circle(p, 12.0, Color(0.26, 0.42, 0.24))
				c.draw_circle(p - LIGHT * 4.0, 7.0, Color(0.34, 0.52, 0.30))
			"post" when lvl == "guell":
				# rough quarry-stone and trencadís mosaic cairn post
				c.draw_circle(p, 14.0, Color(0.58, 0.44, 0.28, 0.35))
				c.draw_circle(p, 9.5, Color(0.64, 0.50, 0.34))
				c.draw_circle(p + Vector2(0, -14), 8.0, Color(0.72, 0.58, 0.40))
				c.draw_circle(p + Vector2(-2, -23), 6.0, Color(0.18, 0.42, 0.76))
				c.draw_circle(p + Vector2(2, -24), 3.2, Color(0.94, 0.92, 0.86))
			"post":
				# A sniff post: a round timber post with a chamfered top, the
				# grain showing, and the bare patch every dog in the park has
				# worn round its foot.
				c.draw_circle(p, 15.0, Color(0.44, 0.40, 0.28, 0.40))
				var pcol := Color(0.28, 0.42, 0.26) if lvl in ["trail", "besos"] else Color(0.40, 0.29, 0.19)
				c.draw_rect(Rect2(p.x - 5.0, p.y - 26.0, 10.0, 30.0), pcol)
				c.draw_rect(Rect2(p.x - 5.0, p.y - 26.0, 4.0, 30.0), pcol.lightened(0.22))
				if lvl in ["trail", "besos"]:
					# white-and-green Parc Natural / Parc Fluvial waymarker band
					c.draw_rect(Rect2(p.x - 5.0, p.y - 18.0, 10.0, 3.0), Color(0.92, 0.92, 0.88))
				elif lvl == "site":
					# high-vis yellow/orange survey band near the top
					c.draw_rect(Rect2(p.x - 5.0, p.y - 22.0, 10.0, 5.0), Color(0.96, 0.54, 0.14))
				for gi in range(3):
					c.draw_line(Vector2(p.x - 2.0 + float(gi) * 2.5, p.y - 24.0),
						Vector2(p.x - 2.0 + float(gi) * 2.5, p.y + 2.0),
						pcol.darkened(0.18), 1.0)
				# the cut top, seen from above: end grain in rings
				c.draw_circle(p + Vector2(0.0, -27.0), 7.0, Color(0.60, 0.47, 0.30))
				c.draw_arc(p + Vector2(0.0, -27.0), 4.0, 0, TAU, 10, Color(0.48, 0.36, 0.23), 1.4)
				c.draw_arc(p + Vector2(0.0, -27.0), 6.5, 0, TAU, 12, Color(0.42, 0.31, 0.20), 1.2)
			"trough" when walk_mod != null and walk_mod.has_method("draw_trough_prop"):
				walk_mod.draw_trough_prop(self, c, p)
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
		# the concourse floor is polished terrazzo, indoors: grit and litter
		# on it, never a cracked or damp street slab
		if lvl == "station" and (int(d.kind) == 0 or int(d.kind) == 2):
			continue
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
# The canopy is overhead (draw_overhead_piece); the shade is the ground pass's.
func _parasol_canopy(b: ShapeBatch, pa: Vector2, col: Color, key: float) -> void:
	var R := PARASOL_R
	var turn := key * 0.37
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


func _spawn_stream_find() -> void:
	if not bosc_high_stream:
		return
	var sy: float = LevelBuild.TRAIL_STREAM_Y
	var e := walk_edges(sy)
	var kind := "branch" if RunEvents.bucket(run_seed, lvl, "high_stream_kind") < 50 else "ball"
	stream_find = Node2D.new()
	stream_find.set_script(load("res://entities/stream_find.gd"))
	stream_find.z_index = 4
	add_child(stream_find)
	stream_find.setup(self, kind, Vector2(e.x - 260.0, sy), e.x - 10.0, sy,
		LevelBuild.TRAIL_HIGH_STREAM_HALF)


func on_stream_find_returned(kind: String, at: Vector2) -> void:
	bones += 5
	Sfx.play("star")
	combo.add("RESCUE", 3)
	float_text(at, ("%s saved! +5" % kind) if kind == "ball" else "saved! +5",
		Color(0.78, 0.94, 0.84))
	_update_hud()


func on_stream_find_grabbed(_at: Vector2) -> void:
	if feed != null:
		feed.say("TO THE BANK!", EventFeed.Tone.PLAIN)


func _push_bosc_current(delta: float) -> void:
	if not bosc_high_stream:
		return
	var stream: Array[Rect2] = LevelBuild.trail_stream(self)
	for body: CharacterBody2D in [dog, human]:
		var active := false
		for r: Rect2 in stream:
			if r.has_point(body.global_position):
				active = true
				break
		CurrentFlow.shove_body(body, active, Vector2.RIGHT, 54.0, 8.0,
			body == dog and bool(dog.planted), delta)


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
	return SkyLook.tint(lvl, Game.weather, Game.night)


# the world's tint and the sky's grade, from the weather and the hour; again
# whenever either changes
func apply_sky() -> void:
	night_cm.color = _weather_tint()
	sky_mod = SkyLook.grade_mod(lvl, Game.weather, Game.night)
	if grade_rect != null:
		var g: Dictionary = mood.grade() if mood != null else {}
		SkyLook.apply(grade_rect.material, SkyLook.compose(Mood.GRADE[Mood.M.HAPPY] if g.is_empty() else g, sky_mod))
	if weather_fx != null:
		weather_fx.mode = Game.weather
		weather_fx.night = Game.night


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
	"music": "MUSIC", "fullscreen": "FULLSCREEN", "goals": "GOAL LIST", "language": "LANGUAGE",
	"controls": "CONTROLS",
	"free_play": "FREE PLAY (DEMO)",
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
	float_text(at, "a good long drink! +2", Color(0.8, 0.92, 1.0))
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
		hints.append("SNIFF OUT WHAT'S LYING AROUND")
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
			hud_status = HomeChase.banner(self)
		elif tofu_quest_active and not tofu_home:
			hud_status = "GET THE CAT HOME! FOLLOW HER"
		else:
			hud_status = "HEAD HOME"
	elif poop_state == 1:
		hud_status = Prompts.fill("NATURE CALLS! STAND STILL, HOLD {poop}")
	elif poop_state >= 3:
		hud_status = "UH OH..."
	elif carry_state == 0 and carry_pickup.x < INF and dog.global_position.distance_to(carry_pickup) < 45.0:
		hud_status = Prompts.fill("{pickup} PICK UP %s" % carry_item.to_upper())
	elif call_active:
		# NOT "they are on the phone": he is on the phone for the whole walk, so
		# saying so is never news. What is news is that he has stopped MOVING,
		# which is the part you can actually spend.
		hud_status = "LOOSE LEASH! %ds LEFT" % int(ceil(human.call_left()))
	elif walk_mod != null and walk_mod.has_method("idle_status"):
		hud_status = walk_mod.idle_status(self)
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
	if match_day != null and phase == "out" and poop_state == 0 and not call_active:
		if match_day.phase == MatchDay.Ph.RUSH:
			hud_status = "KICK-OFF SOON"
	if march != null and march.banner != "":
		hud_status = march.banner
	if match_day != null and match_day.phase == MatchDay.Ph.FULLTIME and not match_day.outflow_due():
		hud_status = "FULL TIME! THE CROWD IS COMING"
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
	# the card itself is drawn by the feed (hud/event_feed.gd) from challenge
	var up: bool = challenge.showing()
	challenge_l.visible = up
	if not up:
		return
	challenge_l.text = "DARE %s %d/%d" % [challenge.phase, challenge.count, challenge.target]
	match String(challenge.phase):
		"live":
			challenge_l.modulate = Color(1, 0.95, 0.6) if challenge.fraction() > 0.3 else Color(1, 0.55, 0.4)
		"end":
			challenge_l.modulate = Color(0.58, 0.90, 0.62) if challenge.succeeded else Color(1.0, 0.56, 0.48)
		_:
			challenge_l.modulate = Color(1, 0.95, 0.6)


# Every scored thing passes through here on its way into the combo
# (systems/combo.gd), which takes back the points it returns.
func on_scored(label: String, pts: int, trick: bool) -> int:
	# anything she gets up to during the call counts toward the payout
	if call_active:
		call_haul += 1
	if not trick:
		return pts
	challenge.add_trick()
	if golden_t > 0.0:
		pts *= 2
	else:
		_refill_zoomies(pts)
	return pts


# A trick refills the zoomies by how much it was worth; filling them that
# way turns them golden.
func _refill_zoomies(pts: int) -> void:
	var was: float = dog.energy
	dog.energy = minf(1.0, was + clampf(float(pts) * ZOOM_REFILL_PER_PT, ZOOM_REFILL.x, ZOOM_REFILL.y))
	if was < 1.0 and dog.energy >= 1.0:
		golden_t = GOLDEN_S
		Sfx.play("star", 1.4)
		feed.say("GOLDEN ZOOMIES!", EventFeed.Tone.LOUD)
		_update_hud()


# What a dare pays.
static func dare_reward(target: int) -> int:
	return DARE_BASE + target * DARE_PER_TRICK


# The giver has said the dare; the clock starts after the offer has been read
# (systems/challenge.gd). A follow-up is the giver's next dare once the last
# is over (entities/challenger.gd); `again` is the same dare after a loss.
func start_challenge(giver: Node2D, target: int, seconds: float, follow_up := false, again := false) -> void:
	if challenge.showing():
		return
	if challenge_offered and not follow_up:
		return
	challenge_offered = true
	challenge_giver = giver
	challenge.offer(target, seconds, dare_reward(target), again)
	Sfx.play("ui")


# the count-in while she gets ready: three, two, one, each a little higher
func on_dare_count(n: int) -> void:
	dare_counts += 1
	Sfx.play("count", 1.0 + 0.12 * float(3 - n), -4.0)


# count-in ticks heard this walk, for tests
var dare_counts := 0


func on_challenge_live() -> void:
	Sfx.play("go", 1.0, -3.0)
	shake_t = maxf(shake_t, 0.2)
	feed.say("GO! %d TRICKS!" % challenge.target, EventFeed.Tone.LOUD)


func on_challenge_done(win: bool, target: int, count: int) -> void:
	Sfx.play("dare_won" if win else "dare_lost", 1.0, -3.0)
	if is_instance_valid(challenge_giver):
		challenge_giver.resolve(win)
	if win:
		var reward: int = challenge.reward if challenge.reward > 0 else dare_reward(target)
		bones += reward
		feed.say("DARE WON! +%d" % reward, EventFeed.Tone.GOOD)
		_slowmo()
	else:
		feed.say("DARE LOST: %d OF %d" % [count, target], EventFeed.Tone.BAD)


# a first-time tip, from a script that has no Tips (human.gd)
func tip(id: String) -> void:
	Tips.show(self, id)


func _physics_process(delta: float) -> void:
	if arrival_at.x >= INF:
		arrival_at = Arrival.fit(self)
	if chase_catch_t > 0.0:
		HomeChase.tick_catch(self, delta)
		return
	if arriving:
		Arrival.tick(self, delta)
		return
	if frozen:
		return
	if not detour_active:
		elapsed += delta
	if depart_open > 0.0:
		Arrival.tick_depart(self, delta)
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
	dog.flooded = false
	if chase_sweeper != null and String(chase_phase) == "chase" and chase_sweeper.has_method("in_shallow"):
		if chase_sweeper.in_shallow(dog.global_position):
			# wet ground, and one sideways scale inside her tick
			dog.slick = true
			dog.flooded = true
	if lvl == "rain":
		_tick_wet(delta)
	dog.ice = Game.weather == "snow"
	human.ice = Game.weather == "snow"
	if Game.weather == "wind":
		dog.velocity += Vector2(46.0, 0) * delta
		human.velocity += Vector2(70.0, 0) * delta
	if walk_mod != null and walk_mod.has_method("tick"):
		walk_mod.tick(self, delta)
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
	_tick_match_crowd(delta)
	_tick_corners(delta)
	if march != null:
		march.tick(self, delta)
	dog.tick(delta)
	human.tick(delta)
	_part_bodies()
	_push_bosc_current(delta)
	if stream_find != null:
		stream_find.tick(delta)
	# the flood's shove lands before the leash, so the rope holds it this frame
	if phase == "home" and chase_active and String(chase_phase) == "chase" \
			and chase_sweeper != null and chase_sweeper.has_method("push_bodies"):
		chase_sweeper.push_bodies(self, delta)
	_prof("dog, owner, drive")
	# the human owns the retractable leash: length changes on their whim
	# ("click!" event), never the dog's
	_tick_reel_length(delta)
	# Dynamic NPC-rope obstacles must be current before the player leash
	# solve; a post-solve feed left the hero rope one frame stale.
	_refresh_pair_obstacles()
	_prof("pair obstacles")
	_apply_leash(delta)
	_shove_match_crowd(delta)
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
	if lvl == "spook" and not tutorial_mode:
		_tick_castanyada_queue()
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
		if chase_catch_t > 0.0:
			return
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
		"main":
			# the main menu is the title screen, as a launch leaves it
			menu_step = 0
			Game.menu_step = 0
			_apply_menu_step()
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
			# PLAY's first-walk question, as a new player sees it
			MenuFlow.open_first(self)
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
	Sfx.music_tempo(_dare_tempo())
	if started and gloss_a > 0.0:
		gloss_a = maxf(0.0, gloss_a - _delta / GLOSS_FADE)
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
			# --shot-title leaves the main menu up instead of skipping it, so
			# it and the name chalked on the pavement can be reviewed.
			# Everything else about --shot exists to get PAST this.
			if "--shot-title" in OS.get_cmdline_user_args():
				return
			# --shot-menu=main|walk|details|shop|progress|pause|walkcard|confirm|first|basics|notice opens that screen
			for a in OS.get_cmdline_user_args():
				if a.begins_with("--shot-menu="):
					_shot_menu(a.substr(12))
					return
			_skip_title()
			# --surface-map dots what surface_at() says over the shot;
			# --surface-map=dump prints it instead and leaves the shot clean
			# (tools/surface_map.sh, tools/surface_check.py)
			for a in OS.get_cmdline_user_args():
				if a == "--surface-map" or a == "--surface-map=dump":
					var ov: Node2D = load("res://tools/surface_overlay.gd").new()
					ov.m = self
					ov.dump = a.ends_with("=dump")
					ov.z_index = 4000
					add_child(ov)
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
			# --shot-cam=X,Y points the camera there instead of at the pair;
			# --shot-goals opens the goal list for the run (unsaved)
			if "--shot-goals" in OS.get_cmdline_user_args():
				Game.goals_expanded = true
			# --shot-say has your human and someone beside them talk at once, to
			# judge the speech bubbles and how two of them stack
			if "--shot-say" in OS.get_cmdline_user_args():
				human._show_bubble("Ugh, hold on.")
				float_text(human.global_position + Vector2(40.0, -20.0), "Excuse me, go ahead.", Color.WHITE, POP_SAY)
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
	if started and arriving:
		# confirm or back, once the opening beat has played
		if Arrival.can_skip(self) and (Input.is_action_just_pressed("plant") \
				or Input.is_action_just_pressed("bark") or Input.is_action_just_pressed("pause")):
			Arrival.skip(self)
	elif started and paused:
		MenuFlow.tick_pause(self)
		return
	elif started and frozen and chase_catch_t > 0.0:
		pass  # the catch beat takes no input; the card that follows does
	elif started and frozen and not arriving:
		# a result or a game-over: the walk has stopped
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
	var target_y := (dog.global_position.y + human.global_position.y) / 2.0 \
		+ HomeChase.CAMERA_PAIR_OFFSET_Y
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
	# keep the grade's surface texture pinned to world space, and give the
	# water's shimmer its clock. Three uniform writes a frame - negligible
	# next to a redraw.
	if grade_rect != null:
		var gm: ShaderMaterial = grade_rect.material
		# the view in world units: the ACTUAL viewport (a wide window sees past
		# the reference frame's edges) over the zoom. In screen pixels the
		# texture crept along at the zoom's excess as the camera moved.
		var view_w: Vector2 = get_viewport_rect().size / cam.zoom
		gm.set_shader_parameter("view_px", view_w)
		gm.set_shader_parameter("cam_off", cam.get_screen_center_position() - view_w * 0.5)
		gm.set_shader_parameter("world_t", AnimClock.msec() / 1000.0)


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


# A soft push apart, not a collision: no contact for the rope or the tug to
# read, and no push at all while an orbit owns their motion or she is off leash.
func _part_bodies() -> void:
	if leash.detached or human.is_whirling() or human.whirl_bailed:
		return
	var gap: Vector2 = dog.global_position - human.global_position
	var dist := gap.length()
	if dist >= BODY_REACH:
		return
	# dead on top of each other: part them across their way, not along it
	var n: Vector2 = gap / dist if dist > 0.01 else human.walk_intent.orthogonal().normalized()
	if n == Vector2.ZERO:
		n = Vector2.RIGHT
	var push := (BODY_REACH - dist) * BODY_PART_RATE
	# she gives way only while she is going somewhere: standing, or dug in,
	# she is where she means to be, and they walk round her
	var dog_share := BODY_PART_DOG if dog.input_active and not dog.planted else 0.0
	var held := _nudge(dog, n * push * dog_share)
	# their share, and whatever a wall refused her, goes back and to one side,
	# so they step round her: the side they were heading for, unless it is shut
	var give := push * (1.0 - dog_share) + held
	var side := n.orthogonal()
	if side.dot(human.walk_intent) < 0.0:
		side = -side
	if human.test_move(human.global_transform, side * maxf(give, 2.0)):
		side = -side
	_nudge(human, (side - n) * give)
	# walking into her where she will not give way (standing, dug in, or held
	# by a wall): they go round, not into her
	if (held > 0.01 or dog_share == 0.0) and human.walk_intent.dot(n) > 0.0:
		human.sidestep_round(side)


# moves a body by `by`, sliding once along whatever it meets; returns how much
# of the move was refused
func _nudge(body: CharacterBody2D, by: Vector2) -> float:
	var hit := body.move_and_collide(by)
	if hit == null:
		return 0.0
	var rest := hit.get_remainder()
	var slide := rest.slide(hit.get_normal())
	var hit2 := body.move_and_collide(slide)
	return rest.length() - slide.length() + (hit2.get_remainder().length() if hit2 != null else 0.0)


# The side street, the lost scarf and the tout. None of them touch the rope.
func _tick_corners(delta: float) -> void:
	if not started or paused:
		return
	if lvl != "partit" or kickabout == null or lost_scarf == null:
		return
	var kickoff := match_day != null and match_day.phase >= MatchDay.Ph.KICKOFF
	var face: Vector2 = dog.facing
	var tumbling: bool = dog.is_tumbling()
	var kc: Dictionary = kickabout.tick(delta, dog.global_position, face, tumbling, kickoff)
	if bool(kc["yell"]):
		float_text(Kickabout.KIDS[1] + Vector2(0.0, -28.0), "Kick it back!", Color(0.96, 0.94, 0.88), POP_SAY)
	if bool(kc["gol"]):
		bones += 5
		Sfx.play("star", 1.1, -4.0)
		float_text(Kickabout.MOUTH + Vector2(0.0, -30.0), "gol! +5", Color(1.0, 0.92, 0.45))
		_update_hud()
	if bool(kc["back"]):
		float_text(Kickabout.KIDS[1] + Vector2(0.0, -28.0), "Good dog!", Color(0.96, 0.94, 0.88), POP_SAY)
	lost_scarf.wind = Game.weather == "wind"
	var sc: Dictionary = lost_scarf.tick(delta, dog.global_position, face, tumbling, kickoff, Callable(self, "walk_edges"))
	if bool(sc["scarf"]) and lost_scarf.waiting():
		float_text(lost_scarf.at + Vector2(0.0, -36.0), "Hey, my lucky scarf!", Color(0.96, 0.94, 0.88), POP_SAY)
	if bool(sc["good"]):
		bones += 6
		Sfx.play("star", 0.95, -4.0)
		float_text(lost_scarf.at + Vector2(0.0, -36.0), "good dog! +6", Color(0.85, 1.0, 0.85))
		float_text(lost_scarf.at + Vector2(-28.0, -16.0), "Yay!", Color(0.96, 0.94, 0.88), POP_SAY)
		_update_hud()
	if phase == "out" and not _fan_pairs and dog.global_position.y < -1400.0:
		_fan_pairs = true
		_spawn_fan_pairs()
	if not _tout_said and dog.global_position.distance_to(Partit.TOUT) < 130.0:
		_tout_said = true
		float_text(Partit.TOUT + Vector2(0.0, -28.0), "Anyone selling tickets?", Color(0.96, 0.94, 0.88), POP_SAY)


# Fans on the way to the bar: home shirts, the other colour on the cap.
func _spawn_fan_pairs() -> void:
	var starts: Array[Vector2] = [Vector2(480.0, -2000.0), Vector2(760.0, -2120.0), Vector2(560.0, -1880.0)]
	var shirts: Array[Color] = [Partit.HOME_BLUE, Partit.HOME_CLARET, Partit.HOME_BLUE]
	var caps: Array[Color] = [Partit.HOME_CLARET, Partit.HOME_BLUE, Partit.HOME_CLARET]
	for i in starts.size():
		var pair := _make_pair(starts[i], Vector2(0.0, 1.0))
		if pair == null:
			continue
		pair.owner_appearance_profile["shirt_color"] = shirts[i]
		pair.owner_col = shirts[i]
		pair.owner_appearance_profile["headwear_style"] = "cap"
		pair.owner_appearance_profile["headwear_color"] = caps[i]


# The river reads the pair and the leash, then says how the pair should give.
# It never touches the rope. Carry is aim and pace (human.gd); the shove is a
# displacement along the flow, and only while the leash is taut across it.
func _tick_match_crowd(delta: float) -> void:
	if match_crowd == null:
		return
	if not started or paused:
		human.crowd_pace = 1.0
		human.crowd_shift = 0.0
		human.match_pace = 1.0
		human.match_on = false
		if human.score_bug != null:
			human.score_bug.visible = false
		match_crowd_push = Vector2.ZERO
		return
	_tick_match_day(delta)
	var dog_p: Vector2 = dog.global_position
	var human_p: Vector2 = human.global_position
	var mid_y := (dog_p.y + human_p.y) * 0.5
	var taut := 0.0
	var path := PackedVector2Array()
	if leash != null and leash.rest_len > 1.0:
		taut = leash.taut_amount(leash.used_length() / leash.rest_len)
		path = leash.visible_path()
	if match_crowd.flow_mode == CrowdRiver.MODE_OUT:
		match_crowd.out_wall = minf(dog_p.y, human_p.y)
	match_crowd_push = match_crowd.step(delta, mid_y, dog_p, human_p, path, taut, solid_rects, Callable(self, "walk_edges"))
	var give: Vector2 = match_crowd.carry(human_p.y, human.homeward)
	human.crowd_shift = give.x
	human.crowd_pace = give.y
	if match_crowd.flow_mode == CrowdRiver.MODE_OUT and _held_clear(human_p):
		human.crowd_shift = 0.0
		human.crowd_pace = 1.0
	if match_day != null and match_day.outflow_due():
		match_day.watch_home(dog_p.y, HOME_Y, match_crowd.any_south_of(dog_p.y))
	if match_crowd.hup_fresh:
		float_text(match_crowd.hup_at, "hup", Color(0.95, 0.93, 0.86))


# The clock, then what it asks of the crowd and of your human. The river's
# mode changes with the phase; the rope is not involved.
func _tick_match_day(delta: float) -> void:
	if match_day == null:
		return
	if _match_roar > 0.0:
		_match_roar -= delta
		if _match_roar <= 0.0:
			Sfx.play("roar", 0.9, -10.0)
	var pair_y := minf(dog.global_position.y, human.global_position.y)
	var was: int = match_day.phase
	var cue: Dictionary = match_day.advance(delta, pair_y, GATE_Y, phase == "home")
	if match_day.phase == MatchDay.Ph.RUSH or match_day.phase != was:
		_update_hud()
	if bool(cue["pa"]):
		var at := human.global_position + Vector2(0.0, -70.0)
		float_text(at, "Five minutes to kickoff!", Color(0.96, 0.94, 0.88), POP_SAY)
		float_text(at + Vector2(0.0, 22.0), "five minutes left", Color(0.85, 0.84, 0.78))
	if bool(cue["whistle"]):
		Sfx.play("whistle", 1.0, -2.0)
		_match_roar = 0.6
		for spot in MatchDay.LITTER:
			kebabs.append({"pos": spot, "eaten": false})
	if bool(cue["ooooh"]):
		Sfx.play("ooooh", 1.0, -8.0)
		_match_flash = MatchDay.SWELL_T
		float_text(human.global_position + Vector2(0.0, -78.0), "Ooooh!", Color(0.96, 0.94, 0.86), POP_SAY)
	if bool(cue["roar"]):
		Sfx.play("roar", 0.85, -6.0)
		_match_flash = 0.45
		_on_match_roar(String(match_day.roar_side))
	if String(cue["react"]) != "":
		var side := String(cue["react"])
		if side == "no":
			Sfx.play("groan", 1.0, -8.0)
		human.match_react(side)
	if bool(cue["flare"]):
		_arm_flare()
	if bool(cue["final"]):
		_final_blasts = 3
		_final_gap = 0.0
		_out_noise = false
		_out_arrived = false
		_fan_dogs = false
	if _final_blasts > 0:
		_final_gap -= delta
		if _final_gap <= 0.0:
			Sfx.play("whistle", 1.0, -6.0)
			_final_blasts -= 1
			_final_gap = 0.5
	if match_day.phase == MatchDay.Ph.FULLTIME and not _out_noise and match_day.phase_t >= 1.5:
		_out_noise = true
		Sfx.play("roar", 0.55, -16.0)
	_match_flash = maxf(0.0, _match_flash - delta)
	terrace_kick = maxf(0.0, terrace_kick - delta)
	if _flare_t > 0.0:
		_flare_t -= delta
		if _flare_t <= 0.0:
			Sfx.play("cracker", 1.0, -4.0)
			mood.bump(Mood.M.SCARED, 0.22)
	var watching: bool = match_day.on_the_match()
	human.match_on = watching
	human.match_pace = MatchDay.MATCH_PACE if watching else 1.0
	if human.score_bug != null:
		human.score_bug.visible = watching
		if match_day.result != "":
			human.score_bug.text = MatchDay.score_line(match_day.result)
	if match_crowd == null:
		return
	match match_day.phase:
		MatchDay.Ph.RUSH:
			match_crowd.flow_mode = CrowdRiver.MODE_JOG
		MatchDay.Ph.KICKOFF:
			match_crowd.flow_mode = CrowdRiver.MODE_DRAIN
		MatchDay.Ph.MATCH:
			match_crowd.flow_mode = CrowdRiver.MODE_LATE
		MatchDay.Ph.FULLTIME:
			if match_day.outflow_due():
				match_crowd.flow_mode = CrowdRiver.MODE_OUT
				match_crowd.out_rate = CrowdRiver.outflow_rate(match_day.result)
				if not _out_arrived:
					_out_arrived = true
					Sfx.play("roar", 0.8, -8.0)
					if match_day.result == "draw":
						Sfx.play("groan", 0.6, -10.0)
					_release_fan_dogs()
				if match_day.result == "home":
					_chant_in -= delta
					if _chant_in <= 0.0:
						_chant_in = 1.4
						Sfx.play("drum", 0.45, -12.0)
			else:
				match_crowd.flow_mode = CrowdRiver.MODE_LATE
		_:
			match_crowd.flow_mode = CrowdRiver.MODE_WALK


# A lamppost or the kerb barriers: the river can pass a human who is against one.
func _held_clear(at: Vector2) -> bool:
	if absf(at.x - 330.0) < 42.0 or absf(at.x - 950.0) < 42.0:
		return true
	if absf(at.x - 640.0) < 36.0:
		for y: float in Partit.MEDIAN_YS:
			if absf(at.y - y) < 52.0:
				return true
	return false


func _release_fan_dogs() -> void:
	if _fan_dogs:
		return
	_fan_dogs = true
	var y := minf(dog.global_position.y, human.global_position.y)
	_make_pair(Vector2(520.0, y - 420.0), Vector2(0.0, 1.0))
	_make_pair(Vector2(800.0, y - 560.0), Vector2(0.0, 1.0))


func _on_match_roar(side: String) -> void:
	var beside := dog.global_position.distance_to(human.global_position) <= MatchDay.BESIDE
	var bowl := Vector2(980.0, Partit.STADIUM_Y0)
	var hit := MatchDay.roar_mood(beside, dog.global_position.distance_to(bowl))
	if hit.y > 0.0:
		mood.bump(Mood.M.ZOOMIES, hit.y)
	if hit.x > 0.0:
		mood.bump(Mood.M.SCARED, hit.x)
	if phase == "freedom":
		for pup in get_tree().get_nodes_in_group("freedogs"):
			pup.hear_roar()
	_terrace_erupts()


func _terrace_erupts() -> void:
	terrace_kick = 0.7
	var c: Vector2 = Partit.DECK.get_center()
	for i in 4:
		kebabs.append({
			"pos": c + Vector2(48.0 + float(i) * 16.0, -24.0 + float(i) * 14.0),
			"eaten": false,
		})


func _arm_flare() -> void:
	var edge: Vector2 = walk_edges(Partit.STADIUM_Y0 + 160.0)
	_flare_at = Vector2(edge.y + 86.0, Partit.STADIUM_Y0 + 160.0)
	_flare_t = 0.8
	Sfx.play("hiss", 1.0, -10.0)


func _shove_match_crowd(delta: float) -> void:
	if match_crowd_push.length_squared() < 1.0:
		return
	var shove := match_crowd_push * delta
	if not dog.planted:
		dog.move_and_collide(shove * 0.5)
	human.move_and_collide(shove)


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
			combo.add("SLINGSHOT", 20)
			float_text(human.global_position + Vector2(0, -34), "slingshot! +8",
				Color(1.0, 0.86, 0.5))
			vault_recent = 0.0
		Sfx.play("fling")
		# the hardest thing on the leash, and paid like it
		bones += 6
		combo.add("FLING", 30)
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
	var dog_m: float = DOG_MASS
	if dog.planted:
		var base_grip: float = PLANT_GRIP_ICE if dog.ice else (PLANT_GRIP_WET if dog.slick else PLANT_GRIP)
		dog_m *= base_grip * (dog.plant_grip_mult() if dog.has_method("plant_grip_mult") else 1.0)
	else:
		dog_m *= (dog.mass_mult() if (dog != null and dog.has_method("mass_mult")) else 1.0)
		if dog.input_active:
			dog_m *= 2.0
	var human_m := HUMAN_MASS * (2.0 if human.is_fallen() else 1.0)
	# a tutorial owner waiting at a lesson plants their feet, as she does:
	# pulling ahead must not tow them past the lesson and out of the tutorial
	if human.tut_holding():
		human_m *= TUT_BRACE
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
		h_dir = round_pole_dir(h_dir)
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


# The pull on the owner, with the part aimed into the pole the rope is over
# beside them turned into a step round it (POLE_STEP_R): the way the rope's
# own probe says unwinds it, as the whirl goes, or with no opinion, the way
# that brings them toward the dog. Unchanged when there is no such pole or the
# pull is not into it.
func round_pole_dir(h_dir: Vector2) -> Vector2:
	if leash.static_contacts == 0 or not leash.human_contact_is_pole:
		return h_dir
	var pole: Vector2 = leash.human_contact_pole
	var to_pole: Vector2 = pole - human.global_position
	var d := to_pole.length()
	if d > POLE_STEP_R or d < 0.001:
		return h_dir
	var n := to_pole / d
	var into := h_dir.dot(n)
	if into <= 0.0:
		return h_dir
	var radial := -n
	var s: float = leash.unwind_bias_of(leash.coil_winding(pole))
	if s == 0.0:
		var to_dog: Vector2 = dog.global_position - human.global_position
		s = 1.0 if radial.rotated(PI / 2.0).dot(to_dog) >= 0.0 else -1.0
	var tangent := radial.rotated(signf(s) * PI / 2.0)
	return (h_dir - n * into + tangent * into).normalized()


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
	# and would spawn a motionless rider at x=0, off screen, every few seconds.
	# A walk module with rider_lane says where its own riders go.
	var mod_lane: bool = walk_mod != null and walk_mod.has_method("rider_lane")
	if not mod_lane and not lvl in VLANE_LEVELS:
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
		_:
			var rl: Dictionary = walk_mod.rider_lane(self, up)
			kid = bool(rl.kid)
			speed = float(rl.speed)
			x = float(rl.x)
			band_lo = float(rl.lo)
			band_hi = float(rl.hi)
	var r_kind := "bike"
	if kid:
		if lvl in ["beach", "llevant"] and fmod(absf(x * 13.7 + y * 0.31), 1.0) < 0.72:
			r_kind = "roller"
		elif lvl in ["street", "park"] and fmod(absf(x * 13.7 + y * 0.31), 1.0) < 0.45:
			r_kind = "roller"
		else:
			r_kind = "kid"
	var b := Node2D.new()
	b.set_script(load("res://entities/bike.gd"))
	b.position = Vector2(x, y)
	b.z_index = 12
	b.setup(self, dog, human, Vector2(0.0, -speed if up else speed), r_kind)
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
		if lvl == "beach" or lvl == "llevant":
			cat_x = 1010.0 if randf() < 0.5 else 462.0
		c.position = Vector2(cat_x, cat_y)
		c.z_index = 9
		add_child(c)
		c.setup(self, dog, "cat")
		cat_y = 0.0
	while flock_ys.size() > 0 and cam.position.y < flock_ys[0] + 650.0:
		var fy: float = flock_ys.pop_front()
		var gulls := lvl == "beach" or lvl == "llevant" or lvl == "port"
		var keets := lvl == "guell"
		var fe := walk_edges(fy)
		# only El Mosaic draws a side, so other walks keep their random sequence
		var west := keets and randf() < 0.5
		for i in range(6 if keets else 5):
			var p := Node2D.new()
			p.set_script(load("res://entities/pigeon.gd"))
			var fx := randf_range(480.0, 820.0)
			if lvl == "port":
				fx = randf_range(480.0, 880.0)
			elif gulls:
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
	if lvl == "beach" or lvl == "llevant":
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
	s.setup(self, dog, "rat" if (lvl == "beach" or lvl == "llevant") else "squirrel")


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
const GREET_LINES := ["Aw, hello there!", "Say hello!", "Don't worry, he's friendly!", "Hi there, pup!", "Go ahead."]
const GRUMPY_LINES := ["Sorry! He's not friendly.", "Bruno! Leave it.", "Sorry! He's grumpy.", "Not today, buddy."]


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
	furn.append_array(rope_soft)
	return furn


func add_rope_rect(r: Rect2, soft := true) -> void:
	LevelBuild.add_rope_rect(self, r, soft)
	if leash != null:
		leash.pole_radii = rope_radii
		leash.furniture_poles = _furniture_wrap_poles()
		leash.rope_rects = rope_rects


func _make_pair(start: Vector2, direction: Vector2, activate := true) -> Node2D:
	var pair := Node2D.new()
	pair.set_script(load("res://entities/otherpair.gd"))
	pair.setup(self, dog, poles, start, direction)
	pair.leash.pole_radii = rope_radii
	pair.leash.furniture_poles = _furniture_wrap_poles()
	pair.leash.rope_rects = rope_rects
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
	if walk_mod != null and walk_mod.has_method("draw_path_edges"):
		walk_mod.draw_path_edges(self, left, right, col)
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


# One Collserola Natural Park trail marker post (fita de sender) with PR blazes
static func _draw_trail_waymarker(b: ShapeBatch, p: Vector2, out: float) -> void:
	b.rect(Rect2(p + LIGHT * 4.0 - Vector2(4.5, 4.5), Vector2(9.0, 9.0)), Color(SHADOW_COL.r, SHADOW_COL.g, SHADOW_COL.b, 0.25))
	b.rect(Rect2(p - Vector2(4.5, 4.5), Vector2(9.0, 9.0)), Color(0.44, 0.32, 0.20))
	b.rect(Rect2(p - Vector2(3.5, 3.5), Vector2(7.0, 7.0)), Color(0.56, 0.42, 0.26))
	b.line(p - Vector2(3.5, 3.5), p + Vector2(3.5, -3.5), Color(0.72, 0.58, 0.38), 1.5)
	var sx := p.x - out * 1.5
	b.rect(Rect2(sx - 3.0, p.y - 1.5, 6.0, 2.0), Color(0.94, 0.94, 0.96))
	b.rect(Rect2(sx - 3.0, p.y + 1.0, 6.0, 2.0), Color(0.24, 0.58, 0.28))


# Where the buildings start at this point down the walk: x = left building
# line, y = right. Follows the path where it bends. Only meaningful when built.
func frontage(y: float) -> Vector2:
	var e := walk_edges(y)
	return Vector2(e.x - strip_l, e.y + strip_r)


func walk_edges(y: float) -> Vector2:
	if detour_active:
		return Detour.walk_edges(self, y)
	# (left_x, right_x) of the walkable path at this point down the level.
	# The single source of truth for where the path IS - the pavement is drawn
	# from it, the surface under her paws is decided by it, and props are
	# fitted to it, so a bend moves all three together.
	return EdgePath.edges(edge_nodes, y, walk_cx, walk_half)


func surface_at(p: Vector2) -> int:
	if detour_active:
		return Surfaces.S.SAND
	# The one place that decides what the ground is. Everything that cares -
	# how fast she goes, how well she can turn, how far she can smell - asks
	# this and then asks surfaces.gd, rather than each re-deriving it from a
	# different bit of geometry the way the old bools did.
	for w: Rect2 in water:
		if water_has_point(w, p):
			return Surfaces.S.WATER
	for pt: Dictionary in patches:
		if patch_has_point(pt, p):
			match String(pt["kind"]):
				"mud": return Surfaces.S.MUD
				"tile": return Surfaces.S.TILE
				# a mess to carry around, not ground that slows you
				"paint", "fish", "oil", "confetti", "icecream", "puddle": continue
				_: return Surfaces.S.SAND
	if walk_surface:
		var ws: int = walk_mod.surface(self, p)
		if ws >= 0:
			return ws
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
	if walk_mod != null and walk_mod.has_method("takes_prints"):
		return walk_mod.takes_prints(self, p)
	# a sandpit, wet cement, mud: soft ground takes a print anywhere
	var soft := surface_at(p)
	return soft == Surfaces.S.SAND or soft == Surfaces.S.MUD


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
		Surfaces.S.WATER:
			_add_mark({"kind": "ring", "pos": dp, "t": elapsed})
			if speed > 160.0:
				_add_mark({"kind": "spray", "pos": dp, "t": elapsed, "ang": ang})


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
		var life: float = FLAT_LIFE if m["kind"] == "flat" else (RING_LIFE if m["kind"] == "ring" else (SPRAY_LIFE if m["kind"] == "spray" else SPLAT_LIFE))
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
			"spray":
				# small water droplets kicked up sideways and behind at a run
				var fwd4 := Vector2.from_angle(float(m["ang"]))
				var sd4 := fwd4.orthogonal()
				var spread4 := 6.0 + (1.0 - f) * 12.0
				for k in range(3):
					var o4 := sd4 * (float(k) - 1.0) * spread4 - fwd4 * (4.0 + float(k) * 2.0)
					b.circle(p + o4, 1.8, Color(0.85, 0.94, 1.0, 0.65 * f))
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
	elif human.wading and maxf(human.velocity.length(), human.presentation_speed) > 15.0 and dent_last_human.distance_to(human.global_position) > 32.0:
		dent_last_human = human.global_position
		_add_mark({"kind": "ring", "pos": human.global_position + Vector2(0.0, 4.0), "t": elapsed})
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
			var muck_mult: float = dog.muck_mult() if dog != null else 1.0
			wet_paws = float(sd.life) * muck_mult
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
	var is_bruna: bool = dog != null and dog._dog_breed() == "gos d'atura"
	var smudge_dist := 30.0 if is_bruna else 26.0
	if wet_paws > 0.0 and dog.global_position.distance_to(human.global_position) < smudge_dist and smudge_cd <= 0.0:
		smudge_cd = 1.1
		var sdd: Dictionary = SUBSTANCES[paw_kind]
		owner_smudges.append({
			"off": (dog.global_position - human.global_position).limit_length(15.0),
			"kind": paw_kind,
		})
		if owner_smudges.size() > 10:
			owner_smudges.remove_at(0)
		smudges_left += 1
		var bonus_bones := 3 if is_bruna else 2
		bones += bonus_bones
		Sfx.play("snack", 0.8)
		combo.add("MESSY", 4 if is_bruna else 3)
		float_text(human.global_position + Vector2(0, -34), String(sdd.quip) + (" +%d" % bonus_bones), Color(sdd.col).lightened(0.35))
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
	last_swing_t = maxf(0.0, last_swing_t - delta)
	if last_swing_t <= 0.0:
		last_swing.clear()
	_tick_needle(delta)
	var pole: Vector2 = leash.contact_pole
	var wrapped: bool = pole.x < INF and leash.static_contacts > 0 and leash.contact_static
	if wrapped and lvl == "port" and not port_bollard_wrapped:
		if pole in Port.BOLLARDS:
			port_bollard_wrapped = true
	if wrapped and lvl == "reial" and not reial_gaudi_wrapped:
		if pole in Reial.GAUDI_POSTS:
			reial_gaudi_wrapped = true
			feed.say("GAUDÍ SLINGSHOT!", EventFeed.Tone.GOOD)
	if vault_t > 0.0:
		# held zoomies keep the swing going, up to its cap
		var held: bool = dog.turbo_active and vault_elapsed < VAULT_MAX_T
		vault_t -= delta * (VAULT_HELD if held else 1.0)
		vault_elapsed += delta
		vault_speed_sum += dog.velocity.length() * delta
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
	# the zoomies say she means it: a wrap at a trot is just a wrap
	if not dog.turbo_active:
		if leash.taut and dog.velocity.length() >= VAULT_TRIGGER_SPEED:
			tip("swing")
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
	vault_elapsed = 0.0
	vault_speed_sum = 0.0
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
		var s := SwingMath.sense(vault_pole, dog.global_position, dog.velocity)
		var tan := SwingMath.vault_tangent(vault_pole, dog.global_position, dog.velocity)
		dog.velocity = tan * VAULT_LAUNCH
		if dog.has_method("trigger_launch_stretch"):
			dog.trigger_launch_stretch(tan, 0.28)
		# paid for the turns and for the pace she carried round them
		var pace: float = vault_speed_sum / maxf(vault_elapsed, 0.01)
		var pay: float = clampf(pace / VAULT_MIN_SPEED, 1.0, VAULT_SPEED_PAY)
		var pts := int(round((14.0 + turns * 50.0) * pay))
		bones += int(pts / 4)
		vaults_landed += 1
		combo.add("POLE SWING", pts)
		Sfx.play("star", 1.15)
		if SwingMath.is_figure_eight(last_swing, vault_pole, s, FIG8_APART):
			bones += 8
			combo.add("FIGURE EIGHT", FIG8_PTS)
			feed.say("FIGURE EIGHT!  %d" % FIG8_PTS, EventFeed.Tone.LOUD)
			last_swing.clear()
		else:
			feed.say("POLE SWING!  %d" % pts, EventFeed.Tone.LOUD)
			last_swing = {"pole": vault_pole, "sense": s}
			last_swing_t = FIG8_WINDOW
		_slowmo()
		_update_hud()
	vault_arc = 0.0


# THREAD THE NEEDLE: a dash between two people walking close together. Not
# an owner and their own dog - between those is their leash, and that is a
# tangle, not a trick - so each pair's two share an id.
func _tick_needle(delta: float) -> void:
	needle_cd = maxf(0.0, needle_cd - delta)
	var p1: Vector2 = dog.global_position
	var p0: Vector2 = needle_prev
	needle_prev = p1
	if p0.x == INF or needle_cd > 0.0 or dog.is_tumbling() or grind.active:
		return
	if dog.velocity.length() < NEEDLE_SPEED:
		return
	_needle_people.clear()
	_needle_owner.clear()
	var near: float = NEEDLE_GAP.y + 30.0
	var id := 0
	for tw: Node2D in get_tree().get_nodes_in_group("tourists"):
		id += 1
		if tw.global_position.distance_to(p1) < near:
			_needle_people.append(tw.global_position)
			_needle_owner.append(id)
	for pr: Node2D in get_tree().get_nodes_in_group("pairs"):
		id += 1
		for who in [pr.get("npc_owner"), pr.get("npc_dog")]:
			if who is Node2D and is_instance_valid(who) and (who as Node2D).global_position.distance_to(p1) < near:
				_needle_people.append((who as Node2D).global_position)
				_needle_owner.append(id)
	var n := _needle_people.size()
	for i in range(n):
		for j in range(i + 1, n):
			if _needle_owner[i] == _needle_owner[j]:
				continue
			if SwingMath.crosses_gap(p0, p1, _needle_people[i], _needle_people[j], NEEDLE_GAP.x, NEEDLE_GAP.y):
				needle_cd = NEEDLE_CD
				needles_done += 1
				bones += 3
				combo.add("THREAD THE NEEDLE", NEEDLE_PTS)
				Sfx.play("star", 1.3, -6.0)
				feed.say("THREAD THE NEEDLE!", EventFeed.Tone.LOUD)
				return


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
		# a lesson with a bench seats them on it, mid-path
		return Vector2(walk_cx if bool(st.get("bench", false)) else INF, y)
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
	# the skip button is offered in the card's own prompt bar (event_feed.gd),
	# never written into the sentence
	tut_skippable = String(st.id) != "done"
	tut_hint.text = Prompts.fill(String(st.body))
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
		float_text(human.global_position + Vector2(0, -34), "Here, another one!", Color(1, 0.92, 0.8), POP_SAY)
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
	golden_t = maxf(0.0, golden_t - delta)
	grind.ease = GOLDEN_EASE if golden_t > 0.0 else 1.0
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
	if grind_cd > 0.0 or dog.is_tumbling() or teeter.active:
		return
	if dog.velocity.length() < GRIND_SPEED:
		return
	if not dog.turbo_active:
		# running along a grindable without them: say how, once
		if not Game.tips_seen.has("grind") and Rails.mountable(self, dog.global_position, dog.velocity) >= 0:
			tip("grind")
		return
	var ri: int = Rails.mountable(self, dog.global_position, dog.velocity)
	if ri < 0:
		return
	grind_rail = ri
	grind.begin()
	Sfx.play("save", 1.35, -10.0)
	feed.say("%s!" % String(rails[ri]["name"]), EventFeed.Tone.LOUD)


# The park's pond is drawn as a blob inside its Rect2 (_draw_world: the bank at
# 1.08 of this outline, the water at 0.94). Swimming follows the drawing out to
# the middle of the bank: still generous, but not the rect's corners, which
# are dry gravel on screen and had her paddling across them.
const POND_SWIM_GROW := 1.0


func pond_outline() -> Dictionary:
	return {"y": pond.get_center().y, "at": 0.5, "rx": pond.size.x * 0.5,
		"ry": pond.size.y * 0.5, "seed": 2.7}


# whether p is in this piece of water, `inset` px in from its edge
func water_has_point(w: Rect2, p: Vector2, inset := 0.0) -> bool:
	if pond.size.x > 0.0 and w == pond:
		var o := pond_outline()
		var d := p - pond.get_center()
		var nx := d.x / maxf(1.0, float(o["rx"]) - inset)
		var ny := d.y / maxf(1.0, float(o["ry"]) - inset)
		return sqrt(nx * nx + ny * ny) <= _patch_wobble(o, atan2(ny, nx)) * POND_SWIM_GROW
	return w.grow(-inset).has_point(p)


# distance from a point outside this water to its edge
func _dist_to_water_edge(w: Rect2, p: Vector2) -> float:
	if pond.size.x > 0.0 and w == pond:
		var o := pond_outline()
		var c := pond.get_center()
		var d := p - c
		var ang := atan2(d.y / float(o["ry"]), d.x / float(o["rx"]))
		var r := _patch_wobble(o, ang) * POND_SWIM_GROW
		return p.distance_to(c + Vector2(cos(ang) * float(o["rx"]) * r, sin(ang) * float(o["ry"]) * r))
	return _dist_to_rect_edge(w, p)


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
		bones += 2
		Sfx.play("star", 1.1)
		combo.add("BALANCE", 4)
		feed.say("SAVED IT!  +2", EventFeed.Tone.GOOD)
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
			float_text(human.global_position, "Hey! That's my towel!", Color(1, 0.85, 0.7), POP_SAY)
	# Millie LOVES the water. In she goes, paddling happily - and whatever is
	# on the other end of the leash comes too. The owner wades in reluctantly,
	# phone held high, and edges back to the bank. Nobody drowns; it is just
	# wet and a little undignified.
	if not water.is_empty():
		var dog_wet := false
		var hum_wet := false
		var bank_x: float = human.pond_bank_x
		for w: Rect2 in water:
			if water_has_point(w, dog.global_position, 4.0):
				dog_wet = true
			if water_has_point(w, human.global_position, 4.0):
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
				if _dist_to_water_edge(w, dog.global_position) < 26.0:
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
			float_text(human.global_position, "No no no-", Color(0.7, 0.85, 1.0), POP_SAY)
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
	TonyHawk.tick(self, delta)
	if not prize_taken and prize_pos.x < INF and dog.global_position.distance_to(prize_pos) < 28.0:
		prize_taken = true
		bones += 8
		Sfx.play("star", 0.9)
		float_text(prize_pos, "got it! +8", Color(1, 0.9, 0.5))
	# carry mission: grab it, then take it to the drop-off
	if carry_pickup.x < INF:
		if carry_state == 0 and not dog_carrying and dog.global_position.distance_to(carry_pickup) < 28.0:
			if auto_walk or Input.is_action_pressed("pickup") or Input.is_action_just_pressed("pickup"):
				carry_state = 1
				dog_carrying = true
				Sfx.play("pickup", 0.9)
				float_text(carry_pickup, "got %s!" % carry_item, Color(0.85, 1.0, 0.85))
				_update_hud()
		elif carry_state == 1 and dog.global_position.distance_to(carry_drop) < 34.0:
			carry_state = 2
			dog_carrying = false
			bones += 10
			Sfx.play("star")
			combo.add("DELIVER", 5)
			float_text(carry_drop, "delivered! +10", Color(0.8, 1.0, 0.8))
			_slowmo()
			_update_hud()
	var digging_now := false
	var sniffing_now := false
	var trough_drinking := false
	for h in hydrants:
		if h.done:
			continue
		if dog.global_position.distance_to(h.pos) < 55.0 and dog.velocity.length() < 60.0:
			sniffing_now = true
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
			dog.sniffing = maxf(dog.sniffing, 0.85)
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
			dog.sniffing = 1.0
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
						digging_now = true
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
						sniffing_now = true
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
						trough_drinking = true
						drunk_amount += 0.34 * delta
						pee = minf(1.0, pee + 0.3 * delta)
						# the sound of a dog drinking, and a word when she has
						# had a proper one (it was silent, so nobody knew)
						lap_t -= delta
						if lap_t <= 0.0:
							lap_t = 0.32
							Sfx.play("squelch", 1.9, -18.0)
						_praise_drink(pp.pos)
	dog.digging = move_toward(dog.digging, 1.0 if digging_now else 0.0, delta * (9.0 if digging_now else 6.0))
	dog.sniffing = move_toward(dog.sniffing, 1.0 if sniffing_now else 0.0, delta * (9.0 if sniffing_now else 5.0))
	if trough_drinking:
		dog.drinking = minf(1.0, dog.drinking + delta * 15.0)
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
	var fountain_drinking := false
	for f in fountains:
		var reach := Reial.FOUNTAIN_DRINK_R if lvl == "reial" else 34.0
		if dog.global_position.distance_to(f) < reach and dog.velocity.length() < 40.0:
			fountain_drinking = true
			pee = minf(1.0, pee + 0.3 * delta)
			drunk_amount += 0.3 * delta
			_praise_drink(f)
	if fountain_drinking:
		dog.drinking = move_toward(dog.drinking, 1.0, delta * 9.0)
	else:
		dog.drinking = move_toward(dog.drinking, 0.0, delta * 6.0)
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
			var squatting: bool = Input.is_action_pressed("poop") \
				and not dog.is_tumbling() and dog.velocity.length() < 90.0
			if squatting:
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
	if bins.is_empty():
		return pos
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
	"beach": "placa", "llevant": "beach", "trail": "clearing", "site": "lot", "scrap": "lot",
	"guell": "clearing",
	"besos": "clearing",
	# the town walks end in a square, the way their gates say
	"market": "placa", "oldtown": "placa", "spook": "placa", "neteja": "placa",
	# the castle's esplanade at the top of the hill
	"montjuic": "placa",
	# the square beside the stadium
	"partit": "placa",
	# the pier plaza overlooking the Mediterranean
	"port": "placa",
	# the arcaded royal square
	"reial": "placa",
	# the vet clinic recovery courtyard
	"vet": "yard",
	# the fairground summit plaza overlooking Barcelona
	"tibidabo": "placa",
	# the Font de la Budellera, in the wood above the track
	"aigues": "clearing",
	# the wood behind the garden's back gate
	"horta": "clearing",
}
const BEACH_SEA_R := 430.0
const BEACH_GATE_SHORE_X := 230.0
# one sea for the walk and the dog beach: a Mediterranean turquoise, paler in
# the shallows where the sand shows through, then wet sand, then dry
const BEACH_SEA_DEEP := Color(0.13, 0.47, 0.60)
const BEACH_SEA_SHALLOW := Color(0.26, 0.66, 0.70)
const BEACH_SHALLOW_W := 110.0
const BEACH_WET := Color(0.76, 0.69, 0.53)
const BEACH_WET_W := 22.0
const BEACH_SAND := Color(0.88, 0.81, 0.64)


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
			if march != null and march.holds_bot(dp):
				var toward := clampf((620.0 - dp.x) / 80.0, -1.0, 1.0)
				dog.auto_move = Vector2(toward, 0.0) if absf(dp.x - 620.0) > 24.0 else Vector2.ZERO
			else:
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
				dog.global_position.y > Arrival.line_y(self)
				and human.global_position.y > Arrival.line_y(self)
				and (not auto_walk or elapsed >= AUTOWALK_MIN_FINISH_TIME)
			):
				Arrival.begin(self)


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
	# other dogs to romp and say hi to (on the sand or plaza, not out in the sea)
	var fd_x0 := BEACH_SEA_R + 60.0 if (freedom_kind == "beach" or lvl == "beach") else 200.0
	var fd_y0 := (Passeig.HOTEL_RECT.end.y + 40.0) if lvl == "beach" else (freedom_lo + 40.0)
	for i in range(3):
		var fd := Node2D.new()
		fd.set_script(load("res://entities/freedog.gd"))
		fd.position = Vector2(randf_range(fd_x0, 1080.0), randf_range(fd_y0, GATE_Y - 60.0))
		fd.z_index = 9
		add_child(fd)
		var flo := (Passeig.HOTEL_RECT.end.y + 10.0) if lvl == "beach" else freedom_lo
		fd.setup(self, dog, flo, GATE_Y - 30.0)
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
		float_text(rv.position, "...Oh no. Brutus.", Color(1, 0.85, 0.75), POP_SAY)
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
	if freedom_kind == "beach" or lvl == "beach":
		# into the surf or across the seafront plaza - window before the first throw
		ball.setup(self, dog, human, freedom_lo, GATE_Y - 30.0, -90.0, BEACH_SEA_R + 240.0)
		if lvl == "beach":
			ball.lo = Passeig.HOTEL_RECT.end.y + 10.0
	else:
		ball.setup(self, dog, human, freedom_lo, GATE_Y - 30.0)


# where dry ground starts across the off-leash space: on the dog beach the
# west of it is sea, and nobody parks, sits or spawns in that
func _dry_x0() -> float:
	return BEACH_SEA_R + 60.0 if (freedom_kind == "beach" or lvl == "beach") else 0.0


# a parked pair's spot, moved onto the sand on the dog beach (two of the three
# stood in the sea there)
func pair_park_spot(i: int) -> Vector2:
	if lvl == "beach" or lvl == "llevant":
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
	# `what` already names it ("the laser"), so no second THE
	feed.say("%s SAW YOU!  -2" % what.to_upper(), EventFeed.Tone.BAD)
	# the racket wakes anyone dozing nearby
	for g in get_tree().get_nodes_in_group("guards"):
		g.hear_noise(dog.global_position, 200.0)
	_update_hud()


func _spawn_challenger() -> void:
	# one dare-giver per walk, on the out leg where you still have room and
	# energy to show off; who it is depends on the walk (challenger.gd WHO)
	if tutorial_mode:
		return
	var giver := Node2D.new()
	var script: GDScript = load("res://entities/challenger.gd")
	giver.set_script(script)
	var who: String = script.giver_for(lvl)
	if who == "monkey":
		# the bronze monkey on the Pont del Petroli's steps gives this walk's dares
		giver.position = LevelBuild.beach_monkey()
		giver.z_index = 6
		add_child(giver)
		giver.setup(self, dog, who)
		_pops_layer().add_speaker(giver, giver.speech)
		return
	var base := Vector2(walk_cx, -1600.0)
	for offset: Vector2 in [
		Vector2(170.0, 0.0), Vector2(-170.0, 0.0),
		Vector2(170.0, -100.0), Vector2(-170.0, -100.0),
		Vector2(170.0, 100.0), Vector2(-170.0, 100.0),
	]:
		var p := base + offset
		if lvl == "oldtown":
			var e := walk_edges(p.y)
			p.x = clampf(p.x, e.x + 22.0, e.y - 22.0)
		giver.position = p
		if _challenger_clear_of_trees(giver.position):
			break
	giver.z_index = 6
	add_child(giver)
	giver.setup(self, dog, who)
	_pops_layer().add_speaker(giver, giver.speech)


func _challenger_clear_of_trees(at: Vector2) -> bool:
	const PERSON_R := 24.0
	for i in range(deco_pole_count):
		var kind := pole_tree(i)
		if kind != TREE_NONE and at.distance_to(poles[i]) < _crown_r(kind, i) + PERSON_R:
			return false
	for i in range(trees.size()):
		if lvl == "scrap":
			break
		var kind := TREE_PALM if (freedom_kind == "beach" or lvl == "beach") else TREE_FOREST
		if lvl == "barri":
			kind = TREE_OAK
		var r := 34.0 if kind == TREE_OAK else 34.0 * 0.85
		if at.distance_to(trees[i]) < r + PERSON_R:
			return false
	return true


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
			float_text(pair.npc_owner.global_position + Vector2(0, -20), "Wanna play?", Color(0.85, 0.95, 1.0), POP_SAY)
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
	var route: Dictionary = TofuRoute.plan(self) if tofu_quest_active and not tofu_home else {}
	var spots: Array[Vector2] = route.get("spots", [] as Array[Vector2])
	if not spots.is_empty():
		var tf := Node2D.new()
		tf.set_script(load("res://entities/tofu.gd"))
		tf.z_index = 9
		add_child(tf)
		tf.setup(self, dog, spots, route["routes"])
		float_text(spots[0], "Tofu got out again! Can you bring her home?", Color(1, 0.85, 0.7), POP_SAY)
	if chase_active:
		HomeChase.begin(self)
	else:
		feed.say("LET'S GO HOME", EventFeed.Tone.PLAIN)


func _chase(delta: float) -> void:
	HomeChase.tick(self, delta)


func _finish_walk() -> void:
	Goals.finish_walk(self)


func begin_departure() -> void:
	Arrival.note_start(self)


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
	# a bark takes the dare on offer (systems/challenge.gd)
	if challenge != null and challenge.phase == "offer" and challenge.waiting:
		challenge.accept()
		feed.say("DARE ON! GET SET", EventFeed.Tone.LOUD)
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
	if walk_mod != null and walk_mod.has_method("on_bark"):
		walk_mod.on_bark(self, pos)


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
	if leash_target < leash_len and dog != null and dog.has_method("reel_mult"):
		rate *= dog.reel_mult()
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
	float_text(pos + Vector2(0, -30), "Heel!", Color(1, 0.85, 0.75))


# ...but she was dug in for it, and it is him that lurches
func on_correction_braced(pos: Vector2) -> void:
	Sfx.play("crack", 0.9, -8.0)
	bones += 3
	combo.add("BRACED", 4)
	float_text(pos + Vector2(0, -30), "held firm! +3", Color(0.7, 1.0, 0.75))
	_update_hud()


# She dug in and yanked your human back. A save only when it saved the phone:
# a bike or the road train was really coming at them (systems/saves.gd).
func on_stumble_save(pos: Vector2) -> void:
	if not stumble_saved_phone(pos):
		return
	streak += 1
	saves_done += 1
	bones += streak
	Sfx.play("save", 1.0 + 0.06 * streak)
	combo.add("SAVE", 5)
	float_text(pos + Vector2(0, -30), "nice save +%d" % streak, Color(0.7, 1.0, 0.75))
	_slowmo()
	_update_hud()


func stumble_saved_phone(pos: Vector2) -> bool:
	for b in get_tree().get_nodes_in_group("bikes"):
		# a kid on a scooter bumps him, it never costs the phone
		if String(b.get("kind")) != "bike" or bool(b.get("hit_done")):
			continue
		if Saves.threatens(b.global_position, b.get("vel"), pos, Saves.HORIZON, Saves.RADIUS):
			return true
	if has_meta("train"):
		var tr = get_meta("train")
		if is_instance_valid(tr) and not bool(tr.get("hit_done")):
			if Saves.train_threatens(tr.rect(), float(tr.dir), tr.SPEED, pos, Saves.HORIZON, 30.0):
				return true
	return false


# She brought your human's hat back (entities/sunhat.gd): it goes back on,
# and they are delighted with her.
func on_hat_returned(_pos: Vector2) -> void:
	human.hat_off = false
	human.patience = 1.0
	bones += 6
	combo.add("HAT", 5)
	Sfx.play("fetch", 1.1)
	float_text(human.global_position + Vector2(0, -34), "You found my hat! Good girl!", Color(1, 1, 1), POP_SAY)
	feed.say("HAT RETURNED!", EventFeed.Tone.GOOD)
	_update_hud()


# She pounced on a paper bag blowing along Montjuïc's path
# (entities/litter.gd).
func on_litter_caught(pos: Vector2) -> void:
	bones += 2
	combo.add("POUNCE", 2)
	Sfx.play("rustle", 0.8)
	float_text(pos + Vector2(0, -24), "got it! +2", Color(0.95, 0.88, 0.7))


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
	_pops_layer()
	var k: int = kind if kind >= 0 else PopsLayer.classify(text)
	var sz := Vector2(font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x + 30.0, 30.0)
	var at := clear_of_feed(pos + Vector2(-sz.x * 0.5, -40.0), sz) + Vector2(sz.x * 0.5, 30.0)
	pops.add(at, text, color, k)


func _pops_layer() -> Node2D:
	if pops == null:
		pops = PopsLayer.new()
		add_child(pops)
	return pops


# Your human's bubble (human.bubble holds the line and when it shows), drawn
# by the speech layer with everyone else's; the tail points at their head.
const HUMAN_SAY_Y := -30.0


func _human_speech() -> Dictionary:
	var b: Label = human.bubble
	if b == null or not b.visible or b.text == "":
		return {}
	return {"tip": pops.to_local(human.global_position + Vector2(0.0, HUMAN_SAY_Y)), "text": b.text}


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
# El Mosaic's scenery is static but expensive to tessellate. Retain its
# geometry while still appending it into the live world batch in exact order.
var _mosaic_cache: ShapeBatch
var _mosaic_cache_vt := 1.0e20
var _mosaic_cache_vb := 1.0e20


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


# El Besòs's waymarker posts (systems/besos.gd); tests ask main
func _draw_besos_post(c: Object, h: Dictionary) -> void:
	Besos.draw_post(self, c, h)


# El Besòs's river (systems/besos.gd); tests ask main
func _draw_besos(vt: float, vb: float) -> void:
	Besos.draw_river(self, vt, vb)


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
	if walk_mod != null and walk_mod.has_method("draw_cross_section"):
		walk_mod.draw_cross_section(self, _wc, top, bottom, ctop, vt, vb)
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
		elif lvl == "station":
			walkway = Estacio.TERRAZZO          # the concourse's polished terrazzo
		elif lvl == "guell":
			walkway = Color(0.80, 0.72, 0.56)   # sandy gravel, the park's own ground
		elif lvl == "trail":
			grass = TRAIL_FLOOR
			walkway = TRAIL_DIRT
		elif lvl == "park" or lvl == "barri":
			walkway = Color(0.74, 0.67, 0.53)   # sandy gravel, as the city's parks are
		elif lvl == "scrap":
			grass = Ferralla.GRAVEL             # oily gravel up to the fence
		elif lvl == "montjuic":
			grass = Montjuic.HILL
			walkway = Montjuic.SAULO
		elif lvl == "besos":
			walkway = Color(0.72, 0.68, 0.60)   # the paved river path, warm concrete
		if walk_mod != null and walk_mod.has_method("draw_ground"):
			# Montjuic: the hill only, between its rims; past them, the city below
			walk_mod.draw_ground(self, _wc, vt, vb)
		elif built:
			# only the strips between the paving and the building line: beyond
			# it the edge layer's buildings show (they sit behind the world, so
			# a full-width lawn here hid every one of them, #65)
			_draw_strips(vt, vb, grass)
		else:
			_wc.draw_rect(Rect2(-400, ctop, 2100, bottom - ctop), grass)
		# leaf litter on the forest floor, grass tufts everywhere else
		var tuft_cols: Array = TRAIL_LITTER if lvl == "trail" else [COL_GRASS_DARK]
		if lvl == "scrap":
			tuft_cols = [Color(0.16, 0.15, 0.14, 0.6)]    # oil dripped into the gravel
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
		elif lvl != "partit" and lvl != "port" and lvl != "reial" and lvl != "vet" and lvl != "tibidabo":
			# (Dia de Partit's asphalt and sidewalks are on the cached edge layer)
			_draw_walk_ribbon(vt, vb, bottom, walkway)
		if walk_mod != null and walk_mod.has_method("draw_over_walkway"):
			walk_mod.draw_over_walkway(self, _wc, vt, vb)
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
		# The Rect2 is kept for what asks about the pond in general - the
		# keep-out margins that stop props being placed in it, the prize in
		# the middle - because being generous about where the water is, is the
		# right way round for those. Swimming follows this outline
		# (water_has_point).
		var pc := pond.get_center()
		var bank := pond_outline()
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
	if walk_mod != null and walk_mod.has_method("draw_live"):
		walk_mod.draw_live(self, _wc, vt, vb)
	if lvl == "partit":
		if march != null:
			march.draw(_wc)
		if _match_flash > 0.0:
			var haze := Color(1.0, 0.92, 0.72, 0.10 * clampf(_match_flash, 0.0, 1.0))
			_wc.circle(Vector2(980.0, Partit.STADIUM_Y0 + 80.0), 70.0, haze)
			_wc.circle(Vector2(1040.0, Partit.STADIUM_Y0 - 40.0), 46.0, haze)
		if _flare_t > 0.0:
			var rise := (0.8 - _flare_t) / 0.8
			var tip := _flare_at + Vector2(8.0, -36.0 - rise * 90.0)
			_wc.line(_flare_at, tip, Color(1.0, 0.55, 0.22, 0.9), 2.2)
			_wc.circle(tip, 3.4, Color(1.0, 0.82, 0.4))
	if tutorial_mode:
		_draw_tutorial_pond()
		_draw_tutorial_ledge(wvt, vb)
		_draw_tutorial_benches(wvt, vb)
	if rambla():
		_draw_rambla(vt, vb)
	if walk_mod != null and walk_mod.has_method("draw_scenery"):
		walk_mod.draw_scenery(self, _wc, vt, vb)
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
		if walk_mod != null and walk_mod.has_method("draw_bollard"):
			walk_mod.draw_bollard(self, _wc, h)
			continue
		if lvl == "reial" or lvl == "vet" or lvl == "tibidabo":
			if not h.done and h.progress > 0.0:
				_wc.draw_arc(hp, 22.0, -PI / 2.0, -PI / 2.0 + TAU * h.progress / 0.8, 20, Color(1, 0.95, 0.7), 3.0)
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
		if walk_mod != null and walk_mod.has_method("draw_snack"):
			walk_mod.draw_snack(self, _wc, kp)
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
	TonyHawk.draw_world(self, _wc, font, vt, vb)
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
	# (same physics, different soul); at night their light is
	# world/light_layer.gd's
	for i in range(deco_pole_count):
		var p := poles[i]
		if p.y < vt - 60.0 or p.y > vb + 60.0:
			continue
		# a tree's crown is the canopy layer's (world/canopylayer.gd); here
		# only what lies on the ground
		var tk := pole_tree(i)
		if tk != TREE_NONE:
			_draw_tree_ground(_wc, p, i, tk)
			continue
		if tutorial_mode:
			_draw_lamppost(p)       # the lesson posts are lampposts, as the cards say
		elif walk_mod != null and walk_mod.has_method("draw_column"):
			walk_mod.draw_column(self, _wc, p)
		else:
			_draw_lamppost(p)
	# trash bins: green, lidded, with a visible mouth - the ONLY thing
	# the owner will throw a bag into (or Barcelona seaside selective recycling station)
	for bn in bins:
		if bn.y < vt - 40.0 or bn.y > vb + 40.0:
			continue
		if walk_mod != null and walk_mod.has_method("draw_bin"):
			walk_mod.draw_bin(self, _wc, bn)
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
	# the beach terraces' canopies and the parasols over the tables are
	# overhead (draw_overhead_piece); here only the shade a parasol casts
	if not Game.night:
		for pa in parasols:
			_wc.circle(pa + LIGHT * 16.0, PARASOL_R * 0.92, Color(SHADOW_COL.r, SHADOW_COL.g, SHADOW_COL.b, 0.16))
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
		var seat: Vector2 = ch
		if terrace_kick > 0.0 and lvl == "partit" and ch.distance_to(Partit.DECK.get_center()) < 220.0:
			seat += Vector2(-8.0 * sin(terrace_kick * 14.0), 0.0)
		for lg in [Vector2(-5, -5), Vector2(5, -5), Vector2(-5, 5), Vector2(5, 5)]:
			_wc.draw_circle(seat + lg, 1.5, Color(0.35, 0.27, 0.18))
		_wc.draw_circle(seat, 6.5, Color(0.58, 0.44, 0.3))
		_wc.draw_arc(seat, 6.5, PI * 1.15, PI * 1.85, 8, Color(0.4, 0.3, 0.2), 3.0)
	# fountains: where the tank refills
	for f in fountains:
		if lvl == "trail":
			break     # El Bosc drinks from the stream, which draws itself
		if rambla():
			_draw_canaletes(f)
			continue
		if lvl == "reial":
			continue      # the Three Graces fountain draws with Plaça Reial
		if f.y < vt - 40.0 or f.y > vb + 40.0:
			continue
		if walk_mod != null and walk_mod.has_method("draw_fountain"):
			walk_mod.draw_fountain(self, f)
			continue
		if lvl == "partit" and f.distance_to(Partit.BOWL) < 1.0:
			_draw_water_bowl(f)
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
		if walk_mod != null and walk_mod.has_method("draw_van"):
			walk_mod.draw_van(self, _wc, v)
			continue
		_draw_service_van(v)
	if furgoneta.x < INF and furgoneta.y > vt - 150.0 and furgoneta.y < vb + 150.0:
		_draw_furgoneta(furgoneta)

	# L'Estacio: the moving walkway - a metal band with chevrons scrolling
	# in the carry direction
	if walk_mod != null and walk_mod.has_method("draw_conveyor"):
		# Montjuic's conveyor is its escalators, drawn as such
		walk_mod.draw_conveyor(self, _wc, vt, vb)
	elif conveyor_zone.size.y > 0.0 and conveyor_zone.end.y > vt and conveyor_zone.position.y < vb:
		_draw_travelator(vt, vb)
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
		if sz.has("ground"):
			continue  # the seafront's sand is the ground itself, already drawn
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
	# El Desguas: sweeping camera cones and laser tripwires; Les Obres' works
	if walk_mod != null and walk_mod.has_method("draw_top"):
		walk_mod.draw_top(self, _wc, vt, vb)
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
	# (El Gotic's and La Neteja's laundry strung across the alley, and the
	# lanterns down one wall, are overhead: draw_overhead_piece)
	# street performers: a hat, some coins, music in the air. In the rain
	# they are an umbrella crowd instead - hunched under canopies, no busking.
	var pt := AnimClock.msec() / 1000.0
	var raining := Game.weather == "rain"
	for idx in range(performers.size()):
		var pf: Vector2 = performers[idx]
		if walk_mod != null and walk_mod.has_method("draw_performer"):
			walk_mod.draw_performer(self, _wc, pf, idx)
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
		if pf.y < vt - 60.0 or pf.y > vb + 60.0:
			continue
		# a busker with a guitar and its open case; in the rain, an umbrella
		# crowd instead, hunched under canopies, no busking
		if not raining:
			_draw_busker(pf, idx, pt)
			continue
		_wc.draw_circle(pf, 12.0, Color(0.5, 0.35, 0.5))
		_wc.draw_circle(pf + Vector2(0, -4), 7.0, Color(0.85, 0.72, 0.58))
		# (the wide domed umbrella over the head, on its stick, is overhead:
		# draw_overhead_piece)
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
	if vt < GATE_Y + 60.0 and (freedom_kind == "beach" or lvl == "beach"):
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
	# the way in, at the bottom, where the walk both begins and ends
	if vb > START_Y + 30.0:
		Arrival.draw(self, _wc)
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
