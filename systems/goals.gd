extends RefCounted

# Goals and scoring: each walk's fixed goal list (Tony Hawk style), crediting a
# goal the moment it completes, the goal card's contents, and the end of the
# walk (results card, records, unlocks).
#
# Static functions over main's state. main.gd keeps same-name forwarders for
# everything other scripts and tests call (_goal_defs, _credit_goal,
# _finish_walk, goal_card_data, results_data, ...), and LEVEL_GOAL_IDS as an
# alias, so every existing path to them still works.

const EventFeed := preload("res://hud/event_feed.gd")
const UiIcons := preload("res://hud/ui_icons.gd")
const HomeChase := preload("res://systems/home_chase.gd")
const TonyHawk := preload("res://systems/tony_hawk.gd")
const Aigues := preload("res://systems/aigues.gd")
const Carmel := preload("res://systems/carmel.gd")
const Eixample := preload("res://systems/eixample.gd")
const Sarria := preload("res://systems/sarria.gd")
const Tarragona := preload("res://systems/tarragona.gd")
const Ach := preload("res://systems/achievements.gd")
const DogSkills := preload("res://systems/dog_skills.gd")
const LEVEL_GOAL_IDS := {
	# El Barri, the everyday walk: the staples and nothing exotic
	"barri": ["mark", "sniff", "phone", "paws", "bag", "fetch", "tofu", "hi", "drink", "snack", "combo", "prize", "spell", "jamon", "clock"],
	# La Rambla trades the traffic near-misses for its pickpockets
	"street": ["mark", "sniff", "phone", "paws", "bag", "fetch", "tofu", "thief", "wallet", "drac", "combo", "prize", "spell", "jamon", "clock"],
	"park": ["mark", "sniff", "phone", "paws", "bag", "fetch", "tofu", "hi", "drink", "snack", "combo", "prize", "spell", "jamon", "clock"],
	"beach": ["mark", "sniff", "phone", "paws", "bag", "fetch", "tofu", "drink", "snack", "save", "combo", "prize", "spell", "jamon", "clock"],
	# El Diluvi: keep your human out of the worst of it, splash the rest
	"rain": ["mark", "sniff", "phone", "paws", "bag", "fetch", "tofu", "dry", "splash", "snack", "combo", "prize", "spell", "jamon", "clock"],
	"market": ["mark", "sniff", "phone", "paws", "bag", "fetch", "tofu", "snack", "zoom", "carry", "combo", "prize", "spell", "jamon", "clock"],
	"oldtown": ["mark", "sniff", "phone", "paws", "bag", "fetch", "tofu", "cats", "snack", "somni", "combo", "prize", "spell", "jamon", "clock"],
	"trail": ["mark", "sniff", "phone", "paws", "bag", "fetch", "tofu", "chase", "drink", "snack", "combo", "prize", "spell", "jamon", "clock"],
	# L'Estacio: ride the walkway, squeeze through the barriers
	"station": ["mark", "sniff", "phone", "paws", "bag", "fetch", "tofu", "walkway", "drink", "snack", "combo", "prize", "spell", "jamon", "clock"],
	"site": ["mark", "sniff", "phone", "paws", "bag", "fetch", "tofu", "close", "drink", "snack", "combo", "prize", "spell", "jamon", "clock"],
	"spook": ["mark", "sniff", "phone", "paws", "bag", "fetch", "tofu", "tummy", "drink", "snack", "combo", "prize", "spell", "jamon", "clock"],
	"scrap": ["mark", "sniff", "phone", "paws", "bag", "fetch", "tofu", "ghost", "unseen", "snack", "combo", "prize", "spell", "jamon", "clock"],
	# El Parc leans on what the terraces are for: carving them (fling) and
	# riding the serpentine bench (combo), plus the park staples.
	"guell": ["mark", "sniff", "phone", "paws", "bag", "fetch",
		"drac_dodge", "drac_column", "drac_trip",
		"fling", "combo", "prize", "spell", "jamon", "clock"],
	# La Neteja: the chase is the walk home, so no Tofu (the two never share
	# a home leg) and a goal for doing the chase WELL rather than just
	# surviving it, which finishing already proves.
	"neteja": ["mark", "sniff", "phone", "paws", "bag", "fetch", "hi", "drink", "snack",
		"combo", "prize", "outrun", "spell", "jamon", "clock"],
	# El Besos: the way home is the flood. No Tofu, same as the other chase.
	"besos": ["mark", "sniff", "phone", "paws", "bag", "fetch", "shallows", "snack", "combo", "prize", "floodgap", "dry", "spell", "jamon", "clock"],
	# Montjuic: the climb, with the park staples
	"montjuic": ["mark", "sniff", "phone", "paws", "bag", "fetch", "tofu", "estel", "drink", "cable", "combo", "prize", "spell", "jamon", "clock"],
	# Dia de Partit. No Tofu: the way home belongs to the final whistle.
	# No hi and no combo: fifteen goals, and the fans' dogs are a greeting.
	"partit": ["mark", "sniff", "phone", "paws", "bag", "fetch", "snack", "march", "scarf", "kickabout", "fulltime", "prize", "spell", "jamon", "clock"],
	# El Port: harbor wharf, seagulls, fish scraps, iron bollards, and Els Lleons (statue boss)
	"port": ["mark", "sniff", "phone", "paws", "bag", "snack", "gulls", "lleons_pincer", "lleons_bump", "bollard", "combo", "prize", "spell", "jamon", "clock"],
	# Plaça Reial: palm trees, Gaudi lampposts, Three Graces fountain, guitar busker
	"reial": ["mark", "sniff", "phone", "colom", "bag", "fetch", "tofu", "snack", "gaudi", "fountain", "combo", "prize", "spell", "jamon", "clock"],
	# El Veterinari: clinic escape chase. No Tofu.
	"vet": ["mark", "sniff", "phone", "paws", "bag", "fetch", "hi", "snack", "scale", "cone", "combo", "prize", "spell", "jamon", "clock"],
	# El Tibidabo: the mountain funicular & panoramic overlook
	"tibidabo": ["mark", "sniff", "phone", "paws", "bag", "fetch", "tofu", "snack", "funicular", "viewfinder", "combo", "prize", "spell", "jamon", "clock"],
	# La Carretera de les Aigües: the bikes coming both ways, and the view
	"aigues": ["mark", "sniff", "phone", "paws", "bag", "fetch", "tofu", "drink", "bikes", "view", "combo", "prize", "spell", "jamon", "clock"],
	# El Laberint d'Horta: round Eros, and the hedges to tetherball your human round
	"horta": ["mark", "sniff", "phone", "paws", "bag", "fetch", "tofu", "drink", "fling", "eros", "combo", "prize", "spell", "jamon", "clock"],
	"llevant": ["mark", "sniff", "phone", "paws", "bag", "fetch", "tofu", "drink", "snack", "save", "combo", "prize", "spell", "jamon", "clock"],
	# Els Senglars: Collserola wild boar trail chase
	"boars": ["mark", "sniff", "phone", "paws", "bag", "fetch", "snack", "boar", "mud", "oaks", "combo", "prize", "spell", "jamon", "clock"],
	# Festa de Gràcia: decorated festival street run
	"gracia": ["mark", "sniff", "phone", "paws", "bag", "fetch", "snack", "correfoc", "churros", "decor", "combo", "prize", "spell", "jamon", "clock"],
	# Els Búnquers del Carmel: the summit battery, escalators, and sunset overlook
	"carmel": ["mark", "sniff", "phone", "paws", "bag", "fetch", "tofu", "snack", "escalator", "view", "bunker", "prize", "spell", "jamon", "clock"],
	# La Superilla: Poblenou superblock tactical circles, ping-pong tables, and cargo trike
	"superilla": ["mark", "sniff", "phone", "paws", "bag", "fetch", "snack", "cargo", "pingpong", "circles", "combo", "prize", "spell", "jamon", "clock"],
	"forum": ["mark", "sniff", "phone", "paws", "bag", "fetch", "snack", "skater", "pergola", "rails", "combo", "prize", "spell", "jamon", "clock"],
	# Plaça d'Espanya: the dancing magic fountain, bubble performer, and monumental columns
	"espanya": ["mark", "sniff", "phone", "paws", "bag", "fetch", "snack", "bubble", "magic_fountain", "columns", "combo", "prize", "spell", "jamon", "clock"],
	# L'Eixample: the cut corners, the tour group, Plaça de Gaudí's pond
	"eixample": ["mark", "sniff", "phone", "paws", "bag", "fetch", "snack", "corners", "tour", "pond", "combo", "prize", "spell", "jamon", "clock"],
	# El Metro: the turnstiles, the rush-hour surge, the car's doors
	"metro": ["mark", "sniff", "phone", "paws", "bag", "fetch", "snack", "turnstile", "surge", "doors_clean", "combo", "prize", "spell", "jamon", "clock"],
	"diagonal": ["mark", "sniff", "phone", "paws", "bag", "fetch", "snack", "tram_dodge", "tram_clean", "kiosk", "combo", "prize", "spell", "jamon", "clock"],
	# Carrer de Blai: leaving the floor food, the waiters' trays, the terraces
	# (no "snack": eating off the floor is what your human tells her not to do)
	"blai": ["mark", "sniff", "phone", "paws", "bag", "fetch", "drink", "leave_it", "tray", "beg", "combo", "prize", "spell", "jamon", "clock"],
	# Sant Pau: the clock tower chimes, the school tour group, the lavender garden beds
	"santpau": ["mark", "sniff", "phone", "paws", "bag", "fetch", "drink", "santpau_tour", "santpau_chime", "santpau_lavender", "combo", "prize", "spell", "jamon", "clock"],
	# Camí de Ronda: brace for the tramuntana gust, admire the coves, bark at the boats
	"ronda": ["mark", "sniff", "phone", "paws", "bag", "fetch", "snack", "ronda_gust", "ronda_coves", "ronda_boats", "combo", "prize", "spell", "jamon", "clock"],
	# Els Encants: hold clear of the stall spill, bark at the auction, steal a sock
	"encants": ["mark", "sniff", "phone", "paws", "bag", "fetch", "carry", "encants_spill", "encants_auction", "snack", "combo", "prize", "spell", "jamon", "clock"],
	"tarragona": ["mark", "sniff", "phone", "paws", "bag", "fetch", "snack", "tarragona_mark", "tarragona_castell", "tarragona_balco", "combo", "prize", "spell", "jamon", "clock"],
	"vic": ["mark", "sniff", "phone", "paws", "bag", "fetch", "vic_market", "vic_columns", "vic_fuet", "vic_fog", "combo", "prize", "spell", "jamon", "clock"],
	# Sarrià: the bells of Sant Vicenç, the two bakeries, the balcony gardener
	"sarria": ["mark", "sniff", "phone", "paws", "bag", "fetch", "snack", "bells", "bread", "gardener", "combo", "prize", "spell", "jamon", "clock"],
	# Els Àngels: the skate plaza outside the white museum
	"angels": ["mark", "sniff", "phone", "paws", "bag", "fetch", "snack", "ledge", "decks", "lamps", "combo", "prize", "spell", "jamon", "clock"],
	# El Poble Espanyol: Plaza Mayor arcade columns, craft workshops, and Andalusian watering cans
	"poble": ["mark", "sniff", "phone", "paws", "bag", "fetch", "snack", "columns_poble", "workshops", "watering", "combo", "prize", "spell", "jamon", "clock"],
	# Sitges: staying dry past the seawall wave, catching wind-blown napkins, ringing La Punta's bell
	"sitges": ["mark", "sniff", "phone", "paws", "bag", "fetch", "dry", "wave_dodge", "napkin", "punta_bark", "combo", "prize", "spell", "jamon", "clock"],
	# La Ciutadella: El Mamut, the first statue boss. Settling him is how the
	# fight ends, so it is not a goal; the ways of wearing him down are.
	"cremada": ["mark", "sniff", "phone", "paws", "bag", "fetch", "snack", "traca", "dimoni_dodge", "dimoni_clean", "combo", "prize", "spell", "jamon", "clock"],
	"aeroport": ["mark", "sniff", "phone", "paws", "bag", "walkway", "gate_rush", "luggage_dodge", "security_clean", "carousel_bark", "combo", "prize", "spell", "jamon", "clock"],
	"montserrat": ["mark", "sniff", "phone", "paws", "bag", "fetch", "funicular_dodge", "boulder_dodge", "goat_clean", "mato_bark", "combo", "prize", "spell", "jamon", "clock"],
	"molina": ["mark", "sniff", "phone", "paws", "bag", "fetch", "cannon_dodge", "snowball_dodge", "groomer_clean", "snowman_bark", "combo", "prize", "spell", "jamon", "clock"],
	# Les Atraccions: flume splash, churro beg, carousel bark, stay dry
	"atraccions": ["mark", "sniff", "phone", "paws", "bag", "fetch", "dry", "flume_dodge", "churro_bark", "ride_bark", "combo", "prize", "spell", "jamon", "clock"],
	"ciutadella": ["mark", "sniff", "phone", "paws", "bag", "snack", "mamut_dodge", "mamut_lake", "mamut_trip", "parakeets", "combo", "prize", "spell", "jamon", "clock"],
	# Rambla del Raval: the finale, El Gat. Tying him up is how the
	# walk ends, so it is not a goal; the ways of wearing him down are.
	"raval": ["mark", "sniff", "phone", "paws", "bag", "clothesline", "pigeons", "swat", "smash", "pummel", "combo", "prize", "spell", "jamon", "clock"],
}


static func defs(m: Node2D) -> Dictionary:
	# every goal the game knows, keyed by a stable id (persistence-facing)
	return {
		"mark": {"text": "Mark %d spots", "target": 5, "fn": func() -> int: return m.marks.size()},
		"sniff": {"text": "Have %d good long sniffs", "target": 4, "fn": func() -> int: return m.sniffs_done},
		"phone": {"text": "Get the phone home without a scratch", "target": 1, "fn": func() -> int: return 1 if m.phone_hp == 3 else 0},
		"paws": {"text": "Get yourself home without a bump", "target": 1, "fn": func() -> int: return 1 if m.dog_hits == 0 else 0},
		"bag": {"text": "Get your business bagged", "target": 1, "fn": func() -> int: return 1 if m.poop_state == 2 and not m.bag_pending else 0},
		"fetch": {"text": "Bring the ball back %d times", "target": 3, "fn": func() -> int: return m.romp_catches},
		"tofu": {"text": "Bring Tofu the cat home", "target": 1, "fn": func() -> int: return 1 if m.tofu_home else 0},
		"hi": {"text": "Say hello to %d dogs", "target": 3, "fn": func() -> int: return m.dogs_greeted},
		"drink": {"text": "Have a good long drink", "target": 1, "fn": func() -> int: return 1 if m.drunk_amount >= 0.4 else 0},
		"cable": {"text": "Find a ticket and ride the telefèric", "target": 1, "fn": func() -> int: return mini(int(m.cable_rides), 1)},
		"zoom": {"text": "Run yourself tired", "target": 1, "fn": func() -> int: return 1 if m.dog.energy <= 0.25 else 0},
		"chase": {"text": "Chase off %d critters", "target": 2, "fn": func() -> int: return m.squirrels_chased},
		"close": {"text": "Scrape past traffic %d times", "target": 3, "fn": func() -> int: return m.close_calls},
		"save": {"text": "Haul your human clear %d times", "target": 2, "fn": func() -> int: return m.saves_done},
		"fling": {"text": "Tetherball your human around a pole", "target": 1, "fn": func() -> int: return m.flings_done},
		"tangle": {"text": "Tangle leashes with a stranger", "target": 1, "fn": func() -> int: return 1 if m.tangles >= 1 else 0},
		"snack": {"text": "Scarf down %d dropped snacks", "target": 2, "fn": func() -> int: return m.kebabs_eaten},
		"cats": {"text": "Chase off %d cats on the walls", "target": 3, "fn": func() -> int: return m.wall_cats_spooked},
		"somni": {"text": "Claim the dream bone in El Somni", "target": 1, "fn": func() -> int: return 1 if m.somni_bone_taken else 0},
		"estel": {"text": "Claim the star bone in L'Estel", "target": 1, "fn": func() -> int: return 1 if m.estel_bone_taken else 0},
		"colom": {"text": "Claim the cubist bone in El Colom", "target": 1, "fn": func() -> int: return 1 if m.colom_bone_taken else 0},
		"drac": {"text": "Claim the dragon bone in El Drac", "target": 1, "fn": func() -> int: return 1 if m.drac_bone_taken else 0},
		"carry": {"text": m.carry_text, "target": 1, "fn": func() -> int: return 1 if m.carry_state >= 2 else 0},
		"combo": {"text": "Land an x%d trick combo", "target": 3, "fn": func() -> int: return int(m.combo.best_mult) if m.combo != null else 0},
		"tummy": {"text": "Walk past every chocolate without a bite", "target": 1, "fn": func() -> int: return 1 if m.candy_eaten == 0 else 0},
		"ghost": {"text": "Cross the yard without waking anyone", "target": 1, "fn": func() -> int: return 1 if m.guards_woken == 0 else 0},
		"outrun": {"text": "Stay a leash length ahead of the sweeper", "target": 1, "fn": func() -> int: return 1 if m.chase_min_gap >= HomeChase.OUTRUN_GAP else 0},
		"floodgap": {"text": "Stay a leash length ahead of the flood", "target": 1, "fn": func() -> int: return 1 if m.chase_min_gap >= HomeChase.OUTRUN_GAP else 0},
		"unseen": {"text": "Never get spotted", "target": 1, "fn": func() -> int: return 1 if m.times_spotted == 0 else 0},
		"walkway": {"text": "Ride the moving walkway end to end", "target": 1, "fn": func() -> int: return m.walkway_rides},
		"escalator": {"text": "Ride the outdoor escalators up the hill", "target": 1, "fn": func() -> int: return m.walkway_rides},
		"bunker": {"text": "Wrap the leash around an anti-aircraft gun", "target": 1, "fn": func() -> int: return 1 if bool(m.get("carmel_cannon_wrapped")) else 0},
		"dry": {"text": "Get your human home mostly dry", "target": 1, "fn": func() -> int: return 1 if m.human_soak < 0.5 else 0,
			"readout": func() -> Dictionary: return {"text": I18n.t("goal_wet") % int(round(m.human_soak * 100.0)), "bad": m.human_soak >= 0.5}},
		"splash": {"text": "Splash through %d puddles at speed", "target": 4, "fn": func() -> int: return m.splashes},
		"shallows": {"text": "Splash through the shallows %d times", "target": 4, "fn": func() -> int: return m.shallow_splashes},
		"thief": {"text": "Stop %d pickpockets", "target": 2, "fn": func() -> int: return m.thieves_stopped},
		"wallet": {"text": "Keep your human's wallet safe", "target": 1, "fn": func() -> int: return 0 if (m.owner_wallet_taken or m.owner_wallet_lost) else 1},
		"prize": {"text": m.prize_text, "target": 1, "fn": func() -> int: return 1 if m.prize_taken else 0},
		"fulltime": {"text": "Beat the crowd home", "target": 1, "fn": func() -> int: return 1 if m.match_day != null and m.match_day.beat else 0},
		"march": {"text": "Keep your human out of the away march", "target": 1, "fn": func() -> int: return 1 if m.march != null and m.march.passed and not m.march.caught else 0},
		"scarf": {"text": "Bring the lost scarf back", "target": 1, "fn": func() -> int: return 1 if m.lost_scarf != null and m.lost_scarf.back else 0},
		"kickabout": {"text": "Score a goal in the kids' street game", "target": 1, "fn": func() -> int: return 1 if m.kickabout != null and m.kickabout.scored else 0},
		"gulls": {"text": "Send %d harbor gulls flying", "target": 3, "fn": func() -> int: return m.port_gulls_startled},
		"lleons_pincer": {"text": "Steer clear of the lions' pincer charge", "target": 1, "fn": func() -> int: return 1 if m.lleons_pincer_dodges >= 1 else 0},
		"lleons_bump": {"text": "Trick the twin lions into colliding", "target": 1, "fn": func() -> int: return 1 if m.lleons_bumped else 0},
		"bollard": {"text": "Wrap the leash around an iron mooring bollard", "target": 1, "fn": func() -> int: return 1 if m.port_bollard_wrapped else 0},
		"gaudi": {"text": "Wrap the leash around a Gaudí dragon lamppost", "target": 1, "fn": func() -> int: return 1 if m.reial_gaudi_wrapped else 0},
		"fountain": {"text": "Drink fresh water from the Three Graces fountain", "target": 1, "fn": func() -> int: return 1 if m.reial_fountain_drank else 0},
		"scale": {"text": "Weigh in on the digital pet scale", "target": 1, "fn": func() -> int: return 1 if bool(m.get("vet_scale_weighed")) else 0},
		"cone": {"text": "Escape the vet without getting bumped", "target": 1, "fn": func() -> int: return 1 if bool(m.dog_hits == 0 and m.finished) else 0},
		"funicular": {"text": "Watch the vintage funicular climb the mountain", "target": 1, "fn": func() -> int: return 1 if m.tibidabo_funicular_seen else 0},
		"bikes": {"text": "Let %d bikes squeak past your human", "target": 3, "fn": func() -> int: return m.close_calls},
		"view": {"text": "Get your human to look up at the view", "target": 1, "fn": func() -> int: return 1 if (Carmel.view_taken(m) if m.lvl == "carmel" else Aigues.view_taken(m)) else 0},
		"eros": {"text": "Steer your human around Eros in the maze", "target": 1, "fn": func() -> int: return 1 if Horta.eros_lapped(m) else 0},
		"viewfinder": {"text": "Look through the cliffside viewfinder", "target": 1, "fn": func() -> int: return 1 if m.tibidabo_viewfinder_gazed else 0},
		"boar": {"text": "Stay a leash length ahead of the boars", "target": 1, "fn": func() -> int: return 1 if m.chase_min_gap >= HomeChase.OUTRUN_GAP else 0},
		"mud": {"text": "Charge through %d boar wallows", "target": 3, "fn": func() -> int: return m.boar_mud_splashes},
		"oaks": {"text": "Pole-swing around %d holm oaks", "target": 2, "fn": func() -> int: return m.boar_swings},
		"correfoc": {"text": "Stay a leash length ahead of the fire devils", "target": 1, "fn": func() -> int: return 1 if m.chase_min_gap >= HomeChase.OUTRUN_GAP else 0},
		"churros": {"text": "Sit pretty at the churro stand", "target": 1, "fn": func() -> int: return m.churros_eaten},
		"decor": {"text": "Zoom under %d festival arches", "target": 3, "fn": func() -> int: return m.gracia_arches_zoomed},
		"clothesline": {"text": "Catch pouncing El Gat in a taut leash", "target": 1, "fn": func() -> int: return 1 if m.gat_clotheslined else 0},
		"pummel": {"text": "Fling your human into El Gat", "target": 1, "fn": func() -> int: return 1 if m.gat_human_pummeled else 0},
		"smash": {"text": "Make El Gat land on a palm or a table", "target": 1, "fn": func() -> int: return 1 if m.gat_tree_smashed else 0},
		"pigeons": {"text": "Scatter %d pigeons", "target": 10, "fn": func() -> int: return m.raval_pigeons_scattered},
		"swat": {"text": "Dodge %d paw swats", "target": 3, "fn": func() -> int: return m.gat_swats_dodged},
		"cargo": {"text": "Dodge the family cargo trike safely", "target": 1, "fn": func() -> int: return 1 if (m.cargo != null and (m.cargo.dodged or (m.cargo.state == m.cargo.State.SETTLED and not m.cargo.human_hit))) else 0},
		"pingpong": {"text": "Slide under a concrete ping-pong table", "target": 1, "fn": func() -> int: return 1 if m.superilla_pingpong_slid else 0},
		"corners": {"text": "Mark the lamps on %d cut corners", "target": 3, "fn": func() -> int: return Eixample.corners_marked(m)},
		"tour": {"text": "Get photographed by a tour group", "target": 1, "fn": func() -> int: return 1 if m.eixample_tour != null and m.eixample_tour.photographed else 0},
		"tram_dodge": {"text": "Dodge the tram %d times", "target": 3, "fn": func() -> int: return m.diagonal_tram_dodges},
		"tram_clean": {"text": "Get home without the tram bumping you", "target": 1, "fn": func() -> int: return 1 if (bool(m.finished) and m.diagonal_tram_hits == 0) else 0},
		"turnstile": {"text": "Slip under a turnstile", "target": 1, "fn": func() -> int: return 1 if m.metro_turnstile_slipped else 0},
		"surge": {"text": "Dig in against the rush-hour crowd", "target": 1, "fn": func() -> int: return 1 if m.metro_surge_held else 0},
		"doors_clean": {"text": "Get home without the doors catching the leash", "target": 1, "fn": func() -> int: return 1 if (bool(m.finished) and m.metro_door_catches == 0) else 0},
		"kiosk": {"text": "Bark at the newspaper kiosk", "target": 1, "fn": func() -> int: return 1 if m.diagonal_kiosk_barked else 0},
		"leave_it": {"text": "Leave it %d times when told", "target": 3, "fn": func() -> int: return m.blai_leaves},
		"tray": {"text": "Catch a pintxo off a tipping tray", "target": 1, "fn": func() -> int: return m.blai_tray_catches},
		"beg": {"text": "Beg at a terrace or a group until someone shares", "target": 1, "fn": func() -> int: return m.blai_begged},
		"santpau_tour": {"text": "Bark hello to the school tour group", "target": 1, "fn": func() -> int: return 1 if m.santpau_tour != null and m.santpau_tour.cheered else 0},
		"santpau_chime": {"text": "Howl along with the clock tower's chime", "target": 1, "fn": func() -> int: return 1 if m.santpau_chime_howled else 0},
		"santpau_lavender": {"text": "Dash through %d lavender beds", "target": 3, "fn": func() -> int: return m.santpau_beds_visited.size()},
		"ronda_gust": {"text": "Keep to the landward side through a gust", "target": 1, "fn": func() -> int: return m.ronda_gust_held},
		"ronda_coves": {"text": "Sniff along the rail over %d coves", "target": 2, "fn": func() -> int: return m.ronda_coves_seen.size()},
		"ronda_boats": {"text": "Bark at %d fishing boats below", "target": 2, "fn": func() -> int: return m.ronda_boats_barked.size()},
		"encants_spill": {"text": "Plant and hold your human clear of a spill", "target": 1, "fn": func() -> int: return m.encants_spill_held},
		"encants_auction": {"text": "Bark at the auction", "target": 1, "fn": func() -> int: return 1 if m.encants_auction_barked else 0},
		"tarragona_mark": {"text": "Mark %d Roman stones", "target": 3, "fn": func() -> int: return Tarragona.stones_marked(m)},
		"tarragona_castell": {"text": "Steer clear for a casteller crowning", "target": 1, "fn": func() -> int: return Tarragona.castell_rewarded(m)},
		"tarragona_balco": {"text": "Share the Balcó view with your human", "target": 1, "fn": func() -> int: return 1 if Tarragona.view_taken(m) else 0},
		"vic_market": {"text": "Sniff %d market stalls", "target": 3, "fn": func() -> int: return m.vic_sniffs.size()},
		"vic_columns": {"text": "Mark %d arcade columns", "target": 4, "fn": func() -> int: return m.vic_cols_marked.size()},
		"vic_fuet": {"text": "Carry the fuet back to its stall", "target": 1, "fn": func() -> int: return m.vic_sausage_returned},
		"vic_fog": {"text": "Find your human in the fog", "target": 1, "fn": func() -> int: return m.vic_found_human},
		"bells": {"text": "Howl along with the church bells", "target": 1, "fn": func() -> int: return 1 if m.sarria != null and m.sarria.howled else 0},
		"bread": {"text": "Sniff the bread at %d bakeries", "target": 2, "fn": func() -> int: return Sarria.bread_sniffed(m)},
		"gardener": {"text": "Bark good morning to the balcony gardener", "target": 1, "fn": func() -> int: return 1 if m.sarria != null and m.sarria.greeted else 0},
		"pond": {"text": "Paddle in the pond by the basilica", "target": 1, "fn": func() -> int: return 1 if m.eixample_pond_paddled else 0},
		"circles": {"text": "Sprint through %d painted circles", "target": 3, "fn": func() -> int: return m.superilla_circles_sprinted},
		"skater": {"text": "Dodge the esplanade skater, or cheer him on", "target": 1, "fn": func() -> int: return 1 if (m.skater != null and (m.skater.dodge_done or m.skater.cheered or m.skater.booped)) else 0},
		"pergola": {"text": "Sprint under the pergola %d times", "target": 3, "fn": func() -> int: return m.forum_pergola_sprinted},
		"rails": {"text": "Grind skate rails for %d style points", "target": 6, "fn": func() -> int: return m.forum_rails_grinded},
		"bubble": {"text": "Pop giant soap bubbles from the street performer", "target": 1, "fn": func() -> int: return 1 if m.espanya_bubbles_popped >= 1 else 0},
		"magic_fountain": {"text": "Splash through the Magic Fountain basin", "target": 1, "fn": func() -> int: return 1 if m.espanya_fountain_splashed >= 1 else 0},
		"columns": {"text": "Wrap the leash around the Four Columns", "target": 1, "fn": func() -> int: return 1 if m.espanya_columns_wrapped >= 1 else 0},
		"ledge": {"text": "Grind a museum ledge", "target": 1, "fn": func() -> int: return 1 if m.angels_ledge_ground else 0},
		"decks": {"text": "Sniff %d skateboards on the ground", "target": 3, "fn": func() -> int: return m.angels_decks_sniffed},
		"lamps": {"text": "Wrap the leash around %d lamps", "target": 3, "fn": func() -> int: return m.angels_lamps_wrapped.size()},
		"columns_poble": {"text": "Wrap the leash around %d columns", "target": 4, "fn": func() -> int: return m.poble_columns_wrapped.size()},
		"workshops": {"text": "Sniff %d craft workshops", "target": 3, "fn": func() -> int: return m.poble_workshops_sniffed.size()},
		"mamut_dodge": {"text": "Dodge the mammoth %d times", "target": 4, "fn": func() -> int: return m.mamut_dodges},
		"mamut_lake": {"text": "Lead the mammoth's charge into the lake", "target": 1, "fn": func() -> int: return 1 if m.mamut_splashed else 0},
		"mamut_trip": {"text": "Trip the mammoth with the leash", "target": 1, "fn": func() -> int: return 1 if m.mamut_tripped else 0},
		"drac_dodge": {"text": "Dodge the dragon %d times", "target": 4, "fn": func() -> int: return m.drac_dodges},
		"drac_column": {"text": "Wind the dragon around a column", "target": 1, "fn": func() -> int: return 1 if m.drac_wound else 0},
		"drac_trip": {"text": "Trip the dragon with the leash", "target": 1, "fn": func() -> int: return 1 if m.drac_tripped else 0},
		"parakeets": {"text": "Shoo the parakeets off your human's croissant", "target": 1, "fn": func() -> int: return 1 if m.ciut_shooed else 0},
		"traca": {"text": "Pull your human clear of the traca", "target": 1, "fn": func() -> int: return 1 if m.cremada_traca_dodged else 0},
		"dimoni_dodge": {"text": "Dodge %d of the Dimoni's rockets", "target": 4, "fn": func() -> int: return m.cremada_dodges},
		"dimoni_clean": {"text": "Get home without a rocket hitting you", "target": 1, "fn": func() -> int: return 1 if (bool(m.finished) and m.cremada_hits == 0) else 0},
		"gate_rush": {"text": "Steer clear of the airport gate rush", "target": 1, "fn": func() -> int: return 1 if m.aeroport_rush_dodged else 0},
		"luggage_dodge": {"text": "Dodge %d tumbling suitcases", "target": 3, "fn": func() -> int: return m.aeroport_luggage_dodges},
		"security_clean": {"text": "Get home without a suitcase clipping you", "target": 1, "fn": func() -> int: return 1 if (bool(m.finished) and m.aeroport_cart_hits == 0) else 0},
		"carousel_bark": {"text": "Bark at the rotating baggage carousel", "target": 1, "fn": func() -> int: return 1 if m.aeroport_carousel_barked else 0},
		"funicular_dodge": {"text": "Cross the Sant Joan funicular track safely", "target": 1, "fn": func() -> int: return 1 if m.montserrat_funicular_dodged else 0},
		"boulder_dodge": {"text": "Dodge %d rolling boulders", "target": 3, "fn": func() -> int: return m.montserrat_boulder_dodges},
		"goat_clean": {"text": "Get home without getting rammed", "target": 1, "fn": func() -> int: return 1 if (bool(m.finished) and m.montserrat_goat_hits == 0) else 0},
		"cannon_dodge": {"text": "Keep clear of %d snow cannon blasts", "target": 2, "fn": func() -> int: return m.molina_cannon_dodges},
		"snowball_dodge": {"text": "Dodge %d rolling snowballs", "target": 3, "fn": func() -> int: return m.molina_snowball_dodges},
		"groomer_clean": {"text": "Get home without a snowball hitting you", "target": 1, "fn": func() -> int: return 1 if (bool(m.finished) and m.molina_snowball_hits == 0) else 0},
		"snowman_bark": {"text": "Bark the snowman's nose off", "target": 1, "fn": func() -> int: return 1 if m.molina_snowman_barked else 0},
		"mato_bark": {"text": "Bark at the mel i mató cheese stall", "target": 1, "fn": func() -> int: return 1 if m.montserrat_mato_barked else 0},
		"watering": {"text": "Get a shower from a watering can", "target": 1, "fn": func() -> int: return 1 if m.poble_shakes >= 1 else 0},
		"wave_dodge": {"text": "Pull your human clear of the breaking wave", "target": 1, "fn": func() -> int: return m.sitges_waves_dodged},
		"flume_dodge": {"text": "Pull your human clear of the flume splash", "target": 1, "fn": func() -> int: return m.atraccions_flume_dodges},
		"churro_bark": {"text": "Beg a churro from the cart", "target": 1, "fn": func() -> int: return 1 if m.atraccions_churro_barked else 0},
		"ride_bark": {"text": "Bark the carousel into a spin", "target": 1, "fn": func() -> int: return 1 if m.atraccions_carousel_spins >= 1 else 0},
		"napkin": {"text": "Catch %d flying napkins in the wind", "target": 3, "fn": func() -> int: return m.sitges_napkins_caught},
		"punta_bark": {"text": "Ring the bell at Sant Bartomeu", "target": 1, "fn": func() -> int: return 1 if m.sitges_church_barked else 0},
		"spell": {"text": "Spell LEASH", "target": 5, "fn": func() -> int: return int(m.get("word_letters_collected"))},
		"jamon": {"text": "Find the hidden pernil", "target": 1, "fn": func() -> int: return 1 if bool(m.get("jamon_found")) else 0},
		"clock": {"text": "Beat the clock (under %s)" % clock(float(m.clock_target)), "target": 1,
			"arg": clock(float(m.clock_target)),
			"fn": func() -> int: return 1 if (bool(m.finished) and float(m.elapsed) <= float(m.clock_target)) else 0,
			"readout": func() -> Dictionary: return {"text": clock(float(m.elapsed)), "bad": float(m.elapsed) > float(m.clock_target)}},
	}


static func build_quests(m: Node2D) -> void:
	# a fixed ~10-goal list per level (Tony Hawk style): completing a goal
	# on any run marks it done for that level forever. Repeating goals,
	# a couple of level flavours, and the unique hazardous prize.
	if m.tutorial_mode:
		m.active_quests.clear()
		m.tofu_quest_active = false
		return
	var all := defs(m)
	var ids: Array = LEVEL_GOAL_IDS.get(m.lvl, LEVEL_GOAL_IDS["street"])
	for id in ids:
		var d: Dictionary = all[id]
		m.active_quests.append({
			"id": id, "text": d.text, "target": int(d.target), "fn": d.fn, "readout": d.get("readout"),
			"arg": d.get("arg"),
			"was_true": int(d.fn.call()) >= int(d.target),
		})
	m.tofu_quest_active = ("tofu" in ids) and not Game.goal_done(m.lvl, "tofu")


# minutes and seconds, as the results card and the clock goal write a time
static func clock(secs: float) -> String:
	var s := int(round(secs))
	return "%d:%02d" % [s / 60, s % 60]


# What a goal's row shows beside its text while it is open: its live readout
# (the walk's time, how wet your human is), and for the spelling goal the
# word's letters, the ones found lit.
static func row_extras(m: Node2D, q: Dictionary, row: Dictionary) -> Dictionary:
	var rd = q.get("readout")
	if rd is Callable:
		var out: Dictionary = (rd as Callable).call()
		row["readout"] = String(out.get("text", ""))
		row["bad"] = bool(out.get("bad", false))
	if String(q.id) == "spell":
		var letters: Array = []
		for l: Dictionary in m.word_letters:
			letters.append({"ch": String(l.letter), "got": bool(l.collected)})
		row["letters"] = letters
	return row


static func quest_text(q: Dictionary) -> String:
	var s: String = q.text
	# the goal's words in the player's language: the clock goal carries its
	# time, every other goal (a walk's prize too) is found by its English
	if String(q.get("id", "")) == "clock" and q.get("arg") != null:
		s = I18n.t("goal_clock") % String(q.arg)
	else:
		s = I18n.of_english(s)
	if "%d" in s:
		s = s % int(q.target)
	# sentence case, whichever list the goal came from
	return s.substr(0, 1).to_upper() + s.substr(1)


static func credit(m: Node2D, q: Dictionary) -> void:
	# award + persist a goal the first time it completes this run
	if m.tutorial_mode:
		return
	var id: String = q.id
	if m.run_goals_hit.has(id):
		return
	m.run_goals_hit[id] = true
	m._peek_goals()
	m.bones += 5
	var newly: bool = Game.mark_goal(m.lvl, id)
	if newly:
		m.run_goals_new += 1
	# by the goal list, not in the middle of the screen: a first time is
	# gold, one already done on an earlier walk is quieter
	if not Game.recording(m.lvl):
		m.feed.toast("goal", I18n.t("toast_free_play" if Game.free_play else "toast_free_walk"), quest_text(q), Color(0.98, 0.80, 0.38))
	elif newly:
		m.feed.toast("goal", I18n.t("toast_goal"), quest_text(q), Color(0.98, 0.80, 0.38))
	else:
		m.feed.toast("goal", I18n.t("toast_goal_again"), quest_text(q), Color(0.58, 0.78, 0.62))
	Ach.on_goal_credited(m)


static func check(m: Node2D) -> void:
	# accumulate goals credit the moment they cross target; "maintain"
	# goals (true from the start, e.g. unscratched phone) are only judged
	# at the finish so they cannot auto-complete on frame one
	for q in m.active_quests:
		if q.was_true or m.run_goals_hit.has(q.id):
			continue
		if int(q.fn.call()) >= int(q.target):
			m._credit_goal(q)


# the goal list's rows on a peek when the interface is enlarged for a small screen
const GOALS_ROWS_SMALL := 4
# the opened card's tallest share of the screen, the height of its heading and
# padding, and its row heights (normal and tightened); hud/goals_card.gd draws
# with the same two row heights
const GOALS_MAX_H := 0.72
const GOALS_CARD_CHROME := 60.0
const GOALS_ROW_H := 21.0
const GOALS_ROW_COMPACT := 16.0


static func card_data(m: Node2D) -> Dictionary:
	# The card draws whatever this returns. Open goals sort to the top so the
	# live ones are always on screen, and finished ones stay in the list
	# rather than vanishing - which is what made the row count wobble between
	# runs and the card jump about.
	var total: int = m.active_quests.size()
	# only goals still on this walk's list count (one dropped from it may be
	# banked from before)
	var done_count := 0
	for q in m.active_quests:
		if Game.goal_done(m.lvl, q.id) or m.run_goals_hit.has(q.id):
			done_count += 1
	# open goals in three groups, each in the walk's own order: the ones
	# that count up (a meter and "0/5"), then the one-off finds and errands,
	# then the ones she keeps true to the end (the phone unscratched)
	var counting: Array = []
	var once: Array = []
	var keep: Array = []
	var done_rows: Array = []
	for q in m.active_quests:
		var persisted: bool = Game.goal_done(m.lvl, q.id)
		var hit: bool = m.run_goals_hit.has(q.id)
		var target := int(q.target)
		if hit or persisted:
			done_rows.append({
				"text": quest_text(q), "target": target, "got": target,
				# banked this run reads brighter than banked on a past walk
				"state": UiIcons.Check.DONE_NOW if hit else UiIcons.Check.DONE_BEFORE,
			})
		else:
			var got: int = mini(int(q.fn.call()), target)
			var group: Array = keep if bool(q.was_true) else (counting if target > 1 else once)
			group.append(row_extras(m, q, {
				"text": quest_text(q), "target": target, "got": got,
				"state": UiIcons.Check.PARTIAL if got > 0 else UiIcons.Check.OPEN,
			}))
	var open_rows: Array = counting + once + keep
	# the dog's skill goal (systems/dog_skills.gd): last of the open goals,
	# outside the walk's done/total
	var skill: Dictionary = DogSkills.card_row(m, UiIcons)
	if not skill.is_empty():
		open_rows.append(skill)
	var rows: Array = open_rows + done_rows
	var open: bool = Game.goals_expanded or m.goals_peek > 0.0
	# A peek (a goal just moved) is brief, so it keeps the short list: with a
	# phone's enlarged interface (hud/ui_scale.gd) a long one would cover a
	# third of the walk. Opened on purpose, the card lists every goal; rows
	# tighten to fit the screen and, only if even that is too tall, finished
	# goals fold into "+ N done" so an open goal is never hidden.
	var cap: int = m.GOALS_MAX_ROWS if float(m.ui_scale) <= 1.0 else GOALS_ROWS_SMALL
	var compact := false
	var folded_done := 0
	if Game.goals_expanded:
		var room: float = m.get_viewport().get_visible_rect().size.y * GOALS_MAX_H - GOALS_CARD_CHROME
		cap = rows.size()
		if float(rows.size()) * GOALS_ROW_H > room:
			compact = true
			var fit: int = maxi(open_rows.size(), int(room / GOALS_ROW_COMPACT))
			if rows.size() > fit:
				folded_done = rows.size() - fit
				cap = fit
	var shown: int = mini(rows.size(), cap)
	return {
		"done": done_count, "total": total,
		"all_done": total > 0 and done_count >= total,
		"rows": rows.slice(0, shown) if open else [],
		"extra": (rows.size() - shown) if open and folded_done == 0 else 0,
		"folded_done": folded_done if open else 0,
		"compact": compact and open,
		"open": open, "peeking": m.goals_peek > 0.0 and not Game.goals_expanded,
		"key": Prompts.key("goals"),
		"clock": _clock_line(m),
	}


# The walk's time against the clock goal, for the folded card, while that goal
# is still open on this walk ({} when it is not).
static func _clock_line(m: Node2D) -> Dictionary:
	for q in m.active_quests:
		if String(q.id) != "clock":
			continue
		if Game.goal_done(m.lvl, "clock") or m.run_goals_hit.has("clock"):
			return {}
		return {"text": "%s / %s" % [clock(float(m.elapsed)), clock(float(m.clock_target))],
			"bad": float(m.elapsed) > float(m.clock_target)}
	return {}


static func finish_walk(m: Node2D) -> void:
	if m.dog.global_position.y > m.HOME_Y and m.human.global_position.y > m.HOME_Y:
		if m.tutorial_mode:
			m._finish_tutorial_walk()
			return
		m.finished = true
		if m.auto_walk:
			print("AUTOWALK FINISHED the whole walk at t=%.1f" % m.elapsed)
		m.frozen = true
		# credit any goal still satisfied at the finish (catches the
		# "maintain" goals like unscratched phone / clean paws)
		for q in m.active_quests:
			if not m.run_goals_hit.has(q.id) and int(q.fn.call()) >= int(q.target):
				m._credit_goal(q)
		var run_done: int = m.run_goals_hit.size()
		var total: int = m.active_quests.size()
		var rows: Array = m._results_rows()
		var lifetime: int = Game.goals_count(m.lvl)
		# total == 0 made this TRUE, which is how a walk with no goal list
		# banked a PERFECT for The Boulevard. The tutorial no longer reaches
		# this path at all, but the trap should not be left armed.
		var perfect := total > 0 and run_done >= total
		var rating := ""
		if run_done == 0:
			rating = I18n.t("results_rating_none")
		elif perfect:
			rating = I18n.t("results_rating_perfect")
		var rec: Dictionary = Game.record_result(m.lvl, m.bones, m.elapsed, perfect)
		Ach.on_walk_finished(m, perfect)
		var lines: Array = []
		var star_gain: int = Game.stars(m.lvl) - m.run_pre_level_stars
		var head := ""
		if Game.free_play:
			head += I18n.t("results_free_play") + "   "
		elif Game.is_free_walk(m.lvl):
			head += I18n.t("results_free_walk") + "   "
		elif star_gain > 0:
			head += I18n.t("results_star_one" if star_gain == 1 else "results_star_other") % star_gain + "   "
		if rec.bones_record:
			head += I18n.t("results_bones_record") + "   "
		if rec.time_record:
			head += I18n.t("results_best_time")
		if head != "":
			lines.append(head.strip_edges())
		lines.append(I18n.t("results_tally")
			% [lifetime, total, Game.total_stars(), Game.total_bones])
		if m.lvl == "partit" and m.match_day != null and m.match_day.result != "":
			lines.append(I18n.t("results_phone_says") % MatchDay.score_line(m.match_day.result))
		if m.combo.best_mult >= 2:
			var best_style: bool = Game.record_style(m.lvl, int(m.combo.run_style))
			lines.append(I18n.t("results_best_combo") % [m.combo.best_mult, m.combo.run_style,
				("    " + I18n.t("results_best_style")) if best_style else ""])
		if m.overmarks > 0:
			lines.append(I18n.t("results_overmark_one" if m.overmarks == 1 else "results_overmark_other")
				% m.overmarks)
		# stars and the chase gates both open walks: announce what is open now
		# that was not when the walk began
		# (a walk begun without GET READY has no snapshot: stars only)
		for other in Game.LEVELS:
			var opened: bool = Game.gate_crossed(m.run_pre_total_stars, other) if m.run_pre_unlocked.is_empty() \
				else Game.is_unlocked(other) and not m.run_pre_unlocked.has(other)
			if opened:
				lines.append(I18n.t("results_unlocked") % Game.LEVEL_NAMES[other])
		m.results = {
			"title": I18n.t("results_very_good_dog" if perfect else "results_good_dog"), "stars": Game.stars(m.lvl),
			"rating": rating,
			"rows": rows, "bones": m.bones, "phone": m.phone_hp, "time": int(m.elapsed),
			"goal_bones": run_done * 5, "lines": lines,
		}
		m.msg_label.visible = false
		m.dim.visible = true
		if m.epilogue_stage != null:
			m.epilogue_stage.reset()
		m.results_card.visible = true
		# the in-walk HUD would otherwise sit on top of the card
		m.goals_card.visible = false
		m.panel.visible = false


# The first walk is done (at its end, or at the basics checkpoint): the title
# stops offering it first, and the bones earned learning are real ones - the
# first time only, or practising again would be a bone farm with no risk in
# it. True when they were banked.
static func complete_tutorial(m: Node2D) -> bool:
	var banked := not Game.tutorial_done
	if banked:
		Game.total_bones += m.bones
	Game.tutorial_done = true
	Game.save_records()
	return banked


static func finish_tutorial_walk(m: Node2D) -> void:
	var banked := complete_tutorial(m)
	# a dare still running in the practice yard ends with the walk
	m.challenge.phase = ""
	m.challenge.active = false
	m.challenge_l.visible = false
	# and so do the lesson card and its prompt bar
	m.tut_label.visible = false
	m.tut_hint.visible = false
	m.tut_skippable = false
	# the feed is not redrawn once the walk is frozen: clear its cards now
	if m.feed != null:
		m.feed.queue_redraw()
	m.finished = true
	m.frozen = true
	m.msg_label.visible = false
	m.dim.visible = true
	if m.epilogue_stage != null:
		m.epilogue_stage.reset()
	m.results = {
		"title": I18n.t("results_good_dog"),
		"stars": 0,
		"rating": I18n.t("results_tut_rating"),
		"rows": [],
		"bones": m.bones,
		"phone": m.phone_hp,
		"time": int(m.elapsed),
		"goal_bones": 0,
		"lines": [
			(I18n.t("results_tut_banked") % m.bones) if banked else (I18n.t("results_tut_banked_before") % m.bones),
			I18n.t("results_tut_goals"),
			I18n.t("results_tut_next"),
		],
	}
	m.results_card.visible = true
	m.goals_card.visible = false
	m.panel.visible = false
	m.tut_label.visible = false
	m.tut_hint.visible = false


static func results_rows(m: Node2D) -> Array:
	var rows: Array = []
	for q in m.active_quests:
		var hit: bool = m.run_goals_hit.has(q.id)
		var had: bool = Game.goal_done(m.lvl, q.id) and not hit
		var target := int(q.target)
		var got: int = mini(int(q.fn.call()), target)
		var st: int = UiIcons.Check.OPEN
		if hit:
			st = UiIcons.Check.DONE_NOW
		elif had:
			st = UiIcons.Check.DONE_BEFORE
		elif got > 0:
			st = UiIcons.Check.PARTIAL
		rows.append({"text": quest_text(q), "state": st, "got": got, "target": target})
	return rows
