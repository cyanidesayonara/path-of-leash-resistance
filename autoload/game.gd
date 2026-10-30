extends Node

# Autoload: session state that must survive scene reloads.

const LEVELS: Array[String] = ["barri", "street", "park", "beach", "rain", "market", "oldtown", "trail", "station", "besos", "site", "spook", "scrap", "guell", "neteja", "montjuic", "partit", "port", "reial", "vet", "tibidabo", "aigues", "horta", "llevant"]
const LEVEL_NAMES := {
	"tutorial": "First Walk",
	# One scheme: a Catalan article plus one everyday noun for the place you
	# are walking through, ASCII only (the web font has no accents, and the HUD
	# upper-cases everything). The tutorial stays English on purpose - it
	# names a mode, not a place.
	#
	# "La Rambla" is a real street, and naming a level after the street it
	# depicts is DESCRIPTIVE use, not trademark use - the same category as the
	# Passeig Marítim and El Gòtic already here. What would be a problem is an
	# attraction's brand name used as branding (which is why the mosaic walk is
	# "El Mosaic" and not the real site), or copying a protected work. A public
	# thoroughfare is neither.
	# the everyday walk: the little park at the end of the street, anywhere
	"barri": "El Barri",
	"street": "La Rambla", "park": "El Parc",
	"beach": "Passeig Marítim", "rain": "El Diluvi", "market": "El Mercat",
	"oldtown": "El Gòtic", "trail": "El Bosc", "station": "L'Estació",
	"besos": "El Besòs", "site": "Les Obres",
	"spook": "La Castanyada", "scrap": "La Ferralla",
	# invented, not the real site: the terraces are the STYLE reference, and
	# style is not anybody's property. No real landmark name ships here.
	"guell": "El Mosaic",
	# the hour the city washes itself, and the walk the sweeper chase lives on
	"neteja": "La Neteja",
	# the hill over the port, and the winding climb up it
	"montjuic": "Montjuïc",
	# match day in Les Corts: the streets to a stadium that is never named
	"partit": "Dia de Partit",
	# Port Vell and Barceloneta fishing docks
	"port": "El Port",
	"reial": "Plaça Reial",
	"vet": "El Veterinari",
	"tibidabo": "El Tibidabo",
	# the old water main's service road along Collserola
	"aigues": "La Carretera de les Aigües",
	# the 18th-century garden at the foot of Collserola, and its cypress maze
	"horta": "El Laberint d'Horta",
	# Barcelona's northernmost beach by the Fòrum, and the dog beach at its end
	"llevant": "Platja de Llevant",
	"boars": "Els Senglars",
	"gracia": "Festa de Gràcia",
	"raval": "Rambla del Raval",
}
# The Catalan name carries the character; this carries the meaning. The game
# ships in English, so a player who does not speak Catalan should never have to
# guess what a walk is - the name is the flavour, the gloss is the information.
# A sentence-case line that says what and where the walk is; it sits under
# the name chalked on the pavement, so keep it to one line there.
const LEVEL_SUBTITLES := {
	"tutorial": "Learn the leash, one trick at a time",
	"barri": "The little park at the end of your street",
	"street": "The crowded promenade",
	"park": "The city park",
	"beach": "The beachfront promenade",
	"rain": "A shopping street in a downpour",
	"market": "The market hall",
	"oldtown": "The old town alleys",
	"trail": "A winding trail through the woods",
	"station": "Rush hour at the train station",
	"besos": "The river park that floods when it rains",
	"site": "The work site",
	"spook": "The chestnut festival",
	"scrap": "The junkyard",
	"guell": "A hillside park of mosaics and stone columns",
	"neteja": "The city's dawn clean-up",
	"montjuic": "The winding climb up to the castle",
	"partit": "Match day at the stadium",
	"port": "The fishing wharf",
	"reial": "The arcaded square off La Rambla",
	"vet": "A trip to the vet",
	"tibidabo": "The city's highest hill and its old fairground",
	"aigues": "The hillside hike",
	"horta": "The cypress maze",
	"llevant": "The dog beach at the far end of the coast",
	"boars": "The wild Collserola downhill scramble",
	"gracia": "The decorated festival street run",
	"raval": "The Grand Finale — El Gat de Botero",
}
# Tony Hawk-style gating: total stars earned so far unlocks the next
# walk. The first is always open; each subsequent walk asks a little more.
# The first few open quickly, so a new player is never stuck on one walk.
const STAR_GATE := {"barri": 0, "street": 1, "park": 2, "beach": 3, "rain": 4, "market": 7, "oldtown": 9, "trail": 11, "station": 13, "besos": 14, "site": 15, "spook": 17, "scrap": 19, "guell": 21, "neteja": 23, "montjuic": 25, "partit": 27, "port": 29, "reial": 31, "vet": 33, "tibidabo": 35, "aigues": 37, "horta": 39, "llevant": 41}

# Keystone Chase milestone gates: each tier requires surviving the previous
# tier's chase level end-to-end to enter.
const CHASE_GATE := {
	# Tier 3 (Walks after El Besòs)
	"site": "besos",
	"spook": "besos",
	"scrap": "besos",
	"guell": "besos",
	"boars": "besos",
	# Tier 4 (Walks after La Neteja)
	"montjuic": "neteja",
	"partit": "neteja",
	"port": "neteja",
	"reial": "neteja",
	"vet": "neteja",
	# Tier 5 (Walks after El Veterinari)
	"tibidabo": "vet",
	"aigues": "vet",
	"horta": "vet",
	"llevant": "vet",
	"gracia": "vet",
	# The Grand Finale (Rambla del Raval - Boss Arena)
	"raval": "gracia",
}

const WEATHERS: Array[String] = ["clear", "rain", "wind", "snow"]
const WEATHER_NAMES := {"clear": "CLEAR", "rain": "RAIN", "wind": "WIND", "snow": "SNOW"}

# Some walks bring their own sky: El Diluvi is always a downpour, La
# Castanyada always after dark, and the first walk a clear day. It holds for
# that walk only (apply_walk_sky), so browsing past one never carries its rain
# or its dark on to the walks after it.
const WALK_WEATHER := {"rain": "rain", "tutorial": "clear"}
const WALK_NIGHT := {"spook": true, "tutorial": false}

# the walk select: the first walk, then the campaign walks in order
const CAROUSEL: Array[String] = ["tutorial", "barri", "street", "park", "beach", "rain", "market", "oldtown", "trail", "station", "besos", "site", "spook", "scrap", "guell", "neteja", "montjuic", "partit", "port", "reial", "vet", "tibidabo", "aigues", "horta", "llevant"]

# Cosmetics keep their catalog keys when equipped, but ownership is namespaced
# by category so identically named items remain separate purchases.
const COLLARS := {
	"red": {"name": "Red (classic)", "cost": 0, "col": Color(0.72, 0.16, 0.14)},
	"blue": {"name": "Blue", "cost": 40, "col": Color(0.2, 0.4, 0.7)},
	"pink": {"name": "Pink", "cost": 40, "col": Color(0.9, 0.45, 0.62)},
	"teal": {"name": "Teal", "cost": 60, "col": Color(0.15, 0.6, 0.58)},
	"gold": {"name": "Gold", "cost": 120, "col": Color(0.85, 0.68, 0.2)},
	"violet": {"name": "Violet", "cost": 150, "col": Color(0.55, 0.3, 0.72)},
	"rainbow": {"name": "Rainbow", "cost": 250, "col": Color(0.8, 0.3, 0.5)},
}
const BANDANAS := {
	"none": {"name": "No bandana", "cost": 0, "col": Color(0, 0, 0, 0)},
	"navy": {"name": "Navy bandana", "cost": 60, "col": Color(0.2, 0.28, 0.45)},
	"forest": {"name": "Forest bandana", "cost": 60, "col": Color(0.25, 0.42, 0.3)},
	"sunny": {"name": "Sunny bandana", "cost": 100, "col": Color(0.9, 0.72, 0.25)},
	"crimson": {"name": "Crimson bandana", "cost": 100, "col": Color(0.7, 0.15, 0.2)},
	"plum": {"name": "Plum bandana", "cost": 140, "col": Color(0.45, 0.22, 0.4)},
}

# Millie's coat, as DATA rather than colours hardcoded into her drawing.
# This is the first piece of the eventual dog creator: every look is a set
# of parameters (base fur, shaded underside, muzzle/chest markings, and how
# much grizzle shows), so adding a breed later means adding a row here, not
# editing the renderer. "millie" is the real dog and stays the default.
const COATS := {
	"millie": {"name": "Millie (black)", "cost": 0,
		"fur": Color(0.14, 0.13, 0.14), "dark": Color(0.08, 0.08, 0.09),
		"mark": Color(0.62, 0.60, 0.58), "grizzle": 1.0},
	"choc": {"name": "Chocolate", "cost": 90,
		"fur": Color(0.32, 0.20, 0.14), "dark": Color(0.21, 0.13, 0.09),
		"mark": Color(0.68, 0.52, 0.36), "grizzle": 0.5},
	"gold": {"name": "Golden", "cost": 90,
		"fur": Color(0.72, 0.55, 0.30), "dark": Color(0.55, 0.40, 0.21),
		"mark": Color(0.88, 0.78, 0.58), "grizzle": 0.4},
	"grey": {"name": "Gray (Weimaraner)", "cost": 130,
		"fur": Color(0.44, 0.42, 0.44), "dark": Color(0.31, 0.30, 0.32),
		"mark": Color(0.66, 0.64, 0.64), "grizzle": 0.3},
	"cream": {"name": "Cream", "cost": 130,
		"fur": Color(0.82, 0.74, 0.60), "dark": Color(0.64, 0.56, 0.44),
		"mark": Color(0.94, 0.90, 0.80), "grizzle": 0.2},
	"merle": {"name": "Blue merle", "cost": 220,
		"fur": Color(0.40, 0.44, 0.50), "dark": Color(0.24, 0.27, 0.32),
		"mark": Color(0.78, 0.80, 0.84), "grizzle": 1.4},
}

# The playable dogs: each changes one trait at one cost. Unlocked by stars,
# coats carry over. Millie is the balanced default; Pipa the Spanish galgo
# runs lightning fast but has a lightweight, fragile plant.
const DOGS := {
	"millie": {
		"name": "Millie",
		"breed": "Mongrel",
		"stars": 0,
		"trait": "Balanced",
		"desc": "Jack of all trades, master of sniffs",
		"speed_mult": 1.0,
		"accel_mult": 1.0,
		"plant_mult": 1.0,
	},
	"pipa": {
		"name": "Pipa",
		"breed": "Galgo",
		"stars": 15,
		"trait": "Fast, weak plant",
		"desc": "A lightning sighthound who hates digging in",
		"speed_mult": 1.20,
		"accel_mult": 1.20,
		"plant_mult": 0.55,
	},
	"mochi": {
		"name": "Mochi",
		"breed": "French bulldog",
		"stars": 25,
		"trait": "Plants hard, slow",
		"desc": "A stubborn little tank who refuses to budge",
		"speed_mult": 0.84,
		"accel_mult": 0.84,
		"plant_mult": 1.70,
	},
	"bruna": {
		"name": "Bruna",
		"breed": "Gos d'atura",
		"stars": 35,
		"trait": "Herds human, collects muck",
		"desc": "A shaggy sheepdog who steers the human with ease",
		"speed_mult": 1.00,
		"accel_mult": 1.05,
		"plant_mult": 1.00,
		"herd_mult": 1.45,
		"muck_mult": 1.60,
	},
	"tito": {
		"name": "Tito",
		"breed": "Chihuahua",
		"stars": 45,
		"trait": "Slips through gaps, easily reeled in",
		"desc": "A tiny chihuahua who slips between obstacles and reels in fast",
		"speed_mult": 1.10,
		"accel_mult": 1.25,
		"plant_mult": 0.35,
		"mass_mult": 0.45,
		"reel_mult": 1.65,
		"gap_mult": 0.57,
	},
}
const DOG_KEYS: Array[String] = ["millie", "pipa", "mochi", "bruna", "tito"]
const DEFAULT_DOG := "millie"

const SAVE_PATH := "user://records.cfg"
const DEFAULT_OWNED := {"collar:red": true, "bandana:none": true, "coat:millie": true}
const DEFAULT_COLLAR := "red"
const DEFAULT_BANDANA := "none"
const DEFAULT_COAT := "millie"
const DEFAULT_VOL_MASTER := 0.85
const DEFAULT_VOL_SFX := 0.9
const DEFAULT_VOL_MUSIC := 0.55

var save_path := SAVE_PATH
# false for the autowalk bot: it runs from a blank save and never writes one,
# so its walk does not depend on (or change) whoever last played here
var persist := true
var level_id := "barri"
var owner_id := "him"  # "him" | "her"; a proper character creator can come later
var night := false
var weather := "clear"
# [weather, night] as the player picked them, while a walk with its own sky
# has replaced them; empty otherwise
var _held_sky: Array = []
# which title-menu step to land on (survives the level-cycle reload;
# after a first run the splash is skipped straight to walk select)
var menu_step := 0
# set by "try again": the next scene load starts the same walk at once
var quick_start := false
# the intro has played this session (intro/intro_player.gd): once is plenty
var intro_seen := false
# local records per level + the spendable bones wallet
var records := {}
var total_bones := 0
# cosmetics
var owned := DEFAULT_OWNED.duplicate()
var collar := DEFAULT_COLLAR
var bandana := DEFAULT_BANDANA
var coat := DEFAULT_COAT
var dog := DEFAULT_DOG
# Player settings. A downloadable build is expected to let you turn the
# volume down and go fullscreen; muting the music with M was not enough.
var vol_master := DEFAULT_VOL_MASTER
var vol_sfx := DEFAULT_VOL_SFX
var vol_music := DEFAULT_VOL_MUSIC
var fullscreen := false
# The language the walks' glosses are written in (the line under each name);
# everything else is English for now.
const LANGUAGES: Array[String] = ["en", "ca", "es"]
const LANGUAGE_NAMES := {"en": "ENGLISH", "ca": "CATALÀ", "es": "ESPAÑOL"}
var language := "en"
const CONTROL_LAYOUTS: Array[String] = ["default", "arrows", "compact", "southpaw"]
const CONTROL_LAYOUT_NAMES := {
	"default": "DEFAULT",
	"arrows": "ARROWS",
	"compact": "COMPACT",
	"southpaw": "SOUTHPAW",
}
var control_layout := "default"
const REBIND_ACTIONS: Array[String] = ["plant", "pee", "poop", "bark", "pickup", "turbo"]
const REBIND_NAMES := {
	"plant": "DIG IN",
	"pee": "PEE",
	"poop": "POOP",
	"bark": "BARK",
	"pickup": "PICK UP",
	"turbo": "ZOOMIES",
}
var key_binds: Dictionary = {}
var pad_binds: Dictionary = {}
var rebind_step := -1
var rebind_wait_release := false
const LEVEL_SUBTITLES_CA := {
	"tutorial": "Aprèn la corretja, truc a truc",
	"barri": "El parquet del final del teu carrer",
	"street": "El passeig ple de gent",
	"park": "El parc de la ciutat",
	"beach": "El passeig de la platja",
	"rain": "Un carrer de botigues sota el xàfec",
	"market": "El mercat cobert",
	"oldtown": "Els carrerons del barri vell",
	"trail": "Un camí que serpenteja pel bosc",
	"station": "Hora punta a l'estació de tren",
	"besos": "El parc fluvial que s'inunda quan plou",
	"site": "El carrer en obres",
	"spook": "La festa de les castanyes",
	"scrap": "El desballestament",
	"guell": "Un parc de trencadís i columnes de pedra",
	"neteja": "La neteja de la ciutat a trenc d'alba",
	"montjuic": "La pujada que serpenteja fins al castell",
	"partit": "Dia de partit a l'estadi",
	"port": "El moll dels pescadors",
	"reial": "La plaça porticada de la Rambla",
	"vet": "Una visita al veterinari",
	"tibidabo": "El cim de la ciutat i les seves atraccions",
	"aigues": "La caminada pel vessant",
	"horta": "El laberint de xiprers",
	"llevant": "La platja dels gossos a l'extrem de la costa",
	"boars": "La baixada salvatge per Collserola",
	"gracia": "La festa dels carrers guarnits",
	"raval": "La gran final — El Gat de Botero",
}
const LEVEL_SUBTITLES_ES := {
	"tutorial": "Aprende la correa, truco a truco",
	"barri": "El parquecito al final de tu calle",
	"street": "El paseo abarrotado",
	"park": "El parque de la ciudad",
	"beach": "El paseo de la playa",
	"rain": "Una calle comercial bajo el chaparrón",
	"market": "El mercado cubierto",
	"oldtown": "Los callejones del casco antiguo",
	"trail": "Un sendero que serpentea por el bosque",
	"station": "Hora punta en la estación de tren",
	"besos": "El parque fluvial que se inunda cuando llueve",
	"site": "La calle en obras",
	"spook": "La fiesta de las castañas",
	"scrap": "El desguace",
	"guell": "Un parque de mosaicos y columnas de piedra",
	"neteja": "La limpieza de la ciudad al amanecer",
	"montjuic": "La subida serpenteante hasta el castillo",
	"partit": "Día de partido en el estadio",
	"port": "El muelle de los pescadores",
	"reial": "La plaza porticada junto a La Rambla",
	"vet": "Una visita al veterinario",
	"tibidabo": "La cima de la ciudad y sus atracciones",
	"aigues": "La caminata por la ladera",
	"horta": "El laberinto de cipreses",
	"llevant": "La playa para perros al final de la costa",
	"boars": "El descenso salvaje por Collserola",
	"gracia": "La fiesta de las calles adornadas",
	"raval": "La gran final — El Gat de Botero",
}
# the off-leash agility course's best time in seconds (0: never run). One
# record for all of them: it is the same course in every space.
var agility_best := 0.0
# The goal card is a big block of text in the corner of a game whose whole
# point is the mess in the middle. Collapsed it is one line; the player
# decides, and the choice sticks.
var goals_expanded := false
# Free play / demo mode: unlocks all walks freely for practice without
# recording career stars, goals, best bones, or time tallies to the save.
var free_play := false
# The first walk (the tutorial): whether the title still offers it before the
# walks, and whether it has been walked to the end.
var ask_tutorial := true
# first-time tips already shown (systems/tips.gd): each shows once, ever
var tips_seen: Array[String] = []
var tutorial_done := false
# walks lost, ever (systems/losses.gd): the first loss gets a word of comfort
var walks_lost := 0


func apply_walk_sky(lv: String) -> void:
	var own_weather := WALK_WEATHER.has(lv)
	var own_night := WALK_NIGHT.has(lv)
	if own_weather or own_night:
		if _held_sky.is_empty():
			_held_sky = [weather, night]
		weather = String(WALK_WEATHER[lv]) if own_weather else String(_held_sky[0])
		night = bool(WALK_NIGHT[lv]) if own_night else bool(_held_sky[1])
	elif not _held_sky.is_empty():
		weather = String(_held_sky[0])
		night = bool(_held_sky[1])
		_held_sky = []


func walk_sets_weather(lv: String) -> bool:
	return WALK_WEATHER.has(lv)


func walk_sets_night(lv: String) -> bool:
	return WALK_NIGHT.has(lv)


func toggle_night() -> void:
	night = not night
	if not _held_sky.is_empty():
		_held_sky[1] = night


func collar_color() -> Color:
	return COLLARS[collar].col if COLLARS.has(collar) else COLLARS["red"].col


func coat_data() -> Dictionary:
	return COATS[coat] if COATS.has(coat) else COATS["millie"]


func ownership_id(kind: String, key: String) -> String:
	return "%s:%s" % [kind, key]


func is_owned(kind: String, key: String) -> bool:
	return bool(owned.get(ownership_id(kind, key), false))


func buy(kind: String, key: String) -> bool:
	var cost := _cost(kind, key)
	if cost < 0 or is_owned(kind, key) or total_bones < cost:
		return false
	total_bones -= cost
	owned[ownership_id(kind, key)] = true
	save_records()
	return true


func equip(kind: String, key: String) -> bool:
	if not is_owned(kind, key):
		return false
	match kind:
		"collar":
			if not COLLARS.has(key):
				return false
			collar = key
		"bandana":
			if not BANDANAS.has(key):
				return false
			bandana = key
		"coat":
			if not COATS.has(key):
				return false
			coat = key
		_:
			return false
	return true


func _cost(kind: String, key: String) -> int:
	match kind:
		"collar":
			return int(COLLARS[key].cost) if COLLARS.has(key) else -1
		"bandana":
			return int(BANDANAS[key].cost) if BANDANAS.has(key) else -1
		"coat":
			return int(COATS[key].cost) if COATS.has(key) else -1
	return -1


func dog_data(k := "") -> Dictionary:
	var key := k if k != "" else dog
	return DOGS[key] if DOGS.has(key) else DOGS[DEFAULT_DOG]


func dog_name(k := "") -> String:
	return String(dog_data(k).get("name", "Millie"))


func dog_breed(k := "") -> String:
	return String(dog_data(k).get("breed", "Mongrel")).to_lower()


func dog_trait(k := "") -> String:
	return String(dog_data(k).get("trait", "Balanced"))


func dog_desc(k := "") -> String:
	return String(dog_data(k).get("desc", ""))


func dog_speed_mult(k := "") -> float:
	return float(dog_data(k).get("speed_mult", 1.0))


func dog_accel_mult(k := "") -> float:
	return float(dog_data(k).get("accel_mult", 1.0))


func dog_plant_mult(k := "") -> float:
	return float(dog_data(k).get("plant_mult", 1.0))


func dog_herd_mult(k := "") -> float:
	return float(dog_data(k).get("herd_mult", 1.0))


func dog_muck_mult(k := "") -> float:
	return float(dog_data(k).get("muck_mult", 1.0))

func dog_mass_mult(k := "") -> float:
	return float(dog_data(k).get("mass_mult", 1.0))


func dog_reel_mult(k := "") -> float:
	return float(dog_data(k).get("reel_mult", 1.0))


func dog_gap_mult(k := "") -> float:
	return float(dog_data(k).get("gap_mult", 1.0))


func is_dog_unlocked(k: String) -> bool:
	if free_play or k == "millie":
		return true
	if not DOGS.has(k):
		return false
	return total_stars() >= int(DOGS[k].get("stars", 0))


func cycle_dog(dir: int) -> void:
	var cur_idx := DOG_KEYS.find(dog)
	if cur_idx < 0:
		cur_idx = 0
	var next_idx := wrapi(cur_idx + dir, 0, DOG_KEYS.size())
	dog = DOG_KEYS[next_idx]
	if is_dog_unlocked(dog):
		save_records()


func toggle_owner() -> void:
	owner_id = "her" if owner_id == "him" else "him"


func cycle_weather(dir: int) -> void:
	var i := WEATHERS.find(weather)
	weather = WEATHERS[wrapi(i + dir, 0, WEATHERS.size())]
	if not _held_sky.is_empty():
		_held_sky[0] = weather


func apply_settings() -> void:
	# one place that pushes the saved settings at the engine, so the menu and
	# startup cannot drift apart
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(vol_master, 0.0001)))
	AudioServer.set_bus_mute(0, vol_master <= 0.001)
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	)
	apply_control_layout()


func apply_control_layout() -> void:
	Prompts.update_layout(control_layout, key_binds, pad_binds)
	if not InputMap.has_action("plant"):
		return
	var configurable := ["move_left", "move_right", "move_up", "move_down", "plant", "bark", "pee", "poop", "pickup", "turbo"]
	for act in configurable:
		InputMap.action_erase_events(act)

	var sticks: Dictionary = {
		"move_left": [JOY_AXIS_RIGHT_X if control_layout == "southpaw" else JOY_AXIS_LEFT_X, -1.0],
		"move_right": [JOY_AXIS_RIGHT_X if control_layout == "southpaw" else JOY_AXIS_LEFT_X, 1.0],
		"move_up": [JOY_AXIS_RIGHT_Y if control_layout == "southpaw" else JOY_AXIS_LEFT_Y, -1.0],
		"move_down": [JOY_AXIS_RIGHT_Y if control_layout == "southpaw" else JOY_AXIS_LEFT_Y, 1.0],
	}
	for act in sticks:
		var ev := InputEventJoypadMotion.new()
		ev.axis = sticks[act][0]
		ev.axis_value = sticks[act][1]
		InputMap.action_add_event(act, ev)

	match control_layout:
		"arrows":
			_add_key_events("move_left", [KEY_LEFT, KEY_A])
			_add_key_events("move_right", [KEY_RIGHT, KEY_D])
			_add_key_events("move_up", [KEY_UP, KEY_W])
			_add_key_events("move_down", [KEY_DOWN, KEY_S])
			_add_key_events("plant", [KEY_SPACE, KEY_ENTER])
			_add_key_events("bark", [KEY_CTRL, KEY_E])
			_add_key_events("pee", [KEY_DELETE, KEY_Q])
			_add_key_events("poop", [KEY_END, KEY_F])
			_add_key_events("pickup", [KEY_PAGEDOWN, KEY_G])
			_add_key_events("turbo", [KEY_SHIFT, KEY_BRACKETRIGHT])
			_add_pad_button("plant", JOY_BUTTON_A)
			_add_pad_button("bark", JOY_BUTTON_B)
			_add_pad_button("pee", JOY_BUTTON_X)
			_add_pad_button("poop", JOY_BUTTON_Y)
			_add_pad_button("pickup", JOY_BUTTON_LEFT_SHOULDER)
			_add_pad_button("turbo", JOY_BUTTON_RIGHT_SHOULDER)
		"compact":
			_add_key_events("move_left", [KEY_J, KEY_A])
			_add_key_events("move_right", [KEY_L, KEY_D])
			_add_key_events("move_up", [KEY_I, KEY_W])
			_add_key_events("move_down", [KEY_K, KEY_S])
			_add_key_events("plant", [KEY_SPACE])
			_add_key_events("bark", [KEY_O, KEY_E])
			_add_key_events("pee", [KEY_U, KEY_Q])
			_add_key_events("poop", [KEY_H, KEY_F])
			_add_key_events("pickup", [KEY_N, KEY_G])
			_add_key_events("turbo", [KEY_SEMICOLON, KEY_SHIFT])
			_add_pad_button("plant", JOY_BUTTON_A)
			_add_pad_button("bark", JOY_BUTTON_B)
			_add_pad_button("pee", JOY_BUTTON_X)
			_add_pad_button("poop", JOY_BUTTON_Y)
			_add_pad_button("pickup", JOY_BUTTON_LEFT_SHOULDER)
			_add_pad_button("turbo", JOY_BUTTON_RIGHT_SHOULDER)
		"southpaw":
			_add_key_events("move_left", [KEY_A, KEY_LEFT])
			_add_key_events("move_right", [KEY_D, KEY_RIGHT])
			_add_key_events("move_up", [KEY_W, KEY_UP])
			_add_key_events("move_down", [KEY_S, KEY_DOWN])
			_add_key_events("plant", [KEY_SPACE])
			_add_key_events("bark", [KEY_E])
			_add_key_events("pee", [KEY_Q])
			_add_key_events("poop", [KEY_F])
			_add_key_events("pickup", [KEY_G])
			_add_key_events("turbo", [KEY_SHIFT])
			_add_pad_button("plant", JOY_BUTTON_X)
			_add_pad_button("bark", JOY_BUTTON_A)
			_add_pad_button("pee", JOY_BUTTON_B)
			_add_pad_button("poop", JOY_BUTTON_Y)
			_add_pad_button("pickup", JOY_BUTTON_RIGHT_SHOULDER)
			_add_pad_button("turbo", JOY_BUTTON_LEFT_SHOULDER)
		_:
			_add_key_events("move_left", [KEY_A, KEY_LEFT])
			_add_key_events("move_right", [KEY_D, KEY_RIGHT])
			_add_key_events("move_up", [KEY_W, KEY_UP])
			_add_key_events("move_down", [KEY_S, KEY_DOWN])
			_add_key_events("plant", [KEY_SPACE])
			_add_key_events("bark", [KEY_E])
			_add_key_events("pee", [KEY_Q])
			_add_key_events("poop", [KEY_F])
			_add_key_events("pickup", [KEY_G])
			_add_key_events("turbo", [KEY_SHIFT])
			_add_pad_button("plant", JOY_BUTTON_A)
			_add_pad_button("bark", JOY_BUTTON_B)
			_add_pad_button("pee", JOY_BUTTON_X)
			_add_pad_button("poop", JOY_BUTTON_Y)
			_add_pad_button("pickup", JOY_BUTTON_LEFT_SHOULDER)
			_add_pad_button("turbo", JOY_BUTTON_RIGHT_SHOULDER)
	for act: String in key_binds.keys():
		if InputMap.has_action(act):
			_replace_key_events(act, int(key_binds[act]))
	for act: String in pad_binds.keys():
		if InputMap.has_action(act):
			_replace_pad_events(act, int(pad_binds[act]))
	Prompts.update_layout(control_layout, key_binds, pad_binds)


func _replace_key_events(action: String, code: int) -> void:
	var keep: Array = []
	for ev in InputMap.action_get_events(action):
		if not (ev is InputEventKey):
			keep.append(ev)
	InputMap.action_erase_events(action)
	for ev in keep:
		InputMap.action_add_event(action, ev)
	_add_key_events(action, [code])


func _replace_pad_events(action: String, btn: int) -> void:
	var keep: Array = []
	for ev in InputMap.action_get_events(action):
		if not (ev is InputEventJoypadButton):
			keep.append(ev)
	InputMap.action_erase_events(action)
	for ev in keep:
		InputMap.action_add_event(action, ev)
	_add_pad_button(action, btn)


func bind_key(action: String, code: int) -> void:
	if not action in REBIND_ACTIONS:
		return
	key_binds[action] = code
	apply_control_layout()
	save_records()


func bind_pad(action: String, btn: int) -> void:
	if not action in REBIND_ACTIONS:
		return
	pad_binds[action] = btn
	apply_control_layout()
	save_records()


func clear_rebinds() -> void:
	key_binds.clear()
	pad_binds.clear()
	apply_control_layout()


func _add_key_events(action: String, keys: Array) -> void:
	for k: int in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)


func _add_pad_button(action: String, btn: int) -> void:
	var ev := InputEventJoypadButton.new()
	ev.button_index = btn
	InputMap.action_add_event(action, ev)


func _ready() -> void:
	persist = not ("--autowalk" in OS.get_cmdline_user_args())
	load_records()
	# lets CI and local smoke tests exercise any level/weather:
	#   godot --headless --path . -- --level=park --weather=snow
	for arg in OS.get_cmdline_user_args():
		# --lang=ca|es|en: the glosses in that language for this run, unsaved
		if arg.begins_with("--lang=") and arg.substr(7) in LANGUAGES:
			language = arg.substr(7)
		if arg.begins_with("--level="):
			var lv := arg.trim_prefix("--level=")
			# the tutorial too, so it can be shot and tested directly
			if lv in LEVELS or lv == "tutorial":
				level_id = lv
		elif arg.begins_with("--weather="):
			var w := arg.trim_prefix("--weather=")
			if w in WEATHERS:
				weather = w
		elif arg == "--night":
			# after dark, as the title's TIME toggle would set it - for
			# screenshots and the level review (#21)
			night = true
		elif arg.begins_with("--dog="):
			var d := arg.trim_prefix("--dog=")
			if DOGS.has(d):
				dog = d
		elif arg == "--tutorial":
			level_id = "tutorial"
	if DisplayServer.get_name() != "headless":
		apply_settings()


func _default_level_record() -> Dictionary:
	return {"bones": 0, "time": 0.0, "perfects": 0, "stars": 0, "goals": [], "style": 0}


func _ensure_level_record(lv: String) -> Dictionary:
	var record := _default_level_record()
	if records.has(lv):
		for key in records[lv]:
			record[key] = records[lv][key]
	records[lv] = record
	return record


func _reset_persisted_state() -> void:
	records = {}
	for lv in LEVELS:
		records[lv] = _default_level_record()
	total_bones = 0
	owned = DEFAULT_OWNED.duplicate()
	collar = DEFAULT_COLLAR
	bandana = DEFAULT_BANDANA
	coat = DEFAULT_COAT
	dog = DEFAULT_DOG
	vol_master = DEFAULT_VOL_MASTER
	vol_sfx = DEFAULT_VOL_SFX
	vol_music = DEFAULT_VOL_MUSIC
	fullscreen = false
	language = "en"
	control_layout = "default"
	key_binds = {}
	pad_binds = {}
	goals_expanded = false
	free_play = false
	ask_tutorial = true
	tutorial_done = false
	walks_lost = 0
	tips_seen = []
	agility_best = 0.0


func load_records() -> void:
	_reset_persisted_state()
	if not persist:
		return
	var cf := ConfigFile.new()
	if cf.load(save_path) != OK:
		return
	for lv in LEVELS:
		var record := _default_level_record()
		var gl: Array = cf.get_value(lv, "goals", [])
		record.bones = int(cf.get_value(lv, "bones", 0))
		record.time = float(cf.get_value(lv, "time", 0.0))
		record.perfects = int(cf.get_value(lv, "perfects", 0))
		record.stars = int(cf.get_value(lv, "stars", 0))
		record.style = int(cf.get_value(lv, "style", 0))
		record.goals = gl
		records[lv] = record
	total_bones = int(cf.get_value("global", "total_bones", 0))
	var ol: Array = cf.get_value("cosmetics", "owned", ["red", "none"])
	owned = {}
	for k in ol:
		var legacy_key := String(k)
		if ":" in legacy_key:
			owned[legacy_key] = true
			continue
		var matched := false
		if COLLARS.has(legacy_key):
			owned[ownership_id("collar", legacy_key)] = true
			matched = true
		if BANDANAS.has(legacy_key):
			owned[ownership_id("bandana", legacy_key)] = true
			matched = true
		if COATS.has(legacy_key):
			owned[ownership_id("coat", legacy_key)] = true
			matched = true
		if not matched:
			owned[legacy_key] = true
	# the freebies are always owned, however old the save file is
	owned[ownership_id("collar", "red")] = true
	owned[ownership_id("bandana", "none")] = true
	owned[ownership_id("coat", "millie")] = true
	collar = cf.get_value("cosmetics", "collar", DEFAULT_COLLAR)
	bandana = cf.get_value("cosmetics", "bandana", DEFAULT_BANDANA)
	coat = cf.get_value("cosmetics", "coat", DEFAULT_COAT)
	dog = String(cf.get_value("player", "dog", DEFAULT_DOG))
	if not DOGS.has(dog):
		dog = DEFAULT_DOG
	vol_master = clampf(float(cf.get_value("settings", "vol_master", DEFAULT_VOL_MASTER)), 0.0, 1.0)
	vol_sfx = clampf(float(cf.get_value("settings", "vol_sfx", DEFAULT_VOL_SFX)), 0.0, 1.0)
	vol_music = clampf(float(cf.get_value("settings", "vol_music", DEFAULT_VOL_MUSIC)), 0.0, 1.0)
	fullscreen = bool(cf.get_value("settings", "fullscreen", false))
	language = String(cf.get_value("settings", "language", "en"))
	if not language in LANGUAGES:
		language = "en"
	control_layout = String(cf.get_value("settings", "control_layout", "default"))
	if not control_layout in CONTROL_LAYOUTS:
		control_layout = "default"
	var kb: Variant = cf.get_value("settings", "key_binds", {})
	key_binds = (kb as Dictionary).duplicate() if kb is Dictionary else {}
	var pb: Variant = cf.get_value("settings", "pad_binds", {})
	pad_binds = (pb as Dictionary).duplicate() if pb is Dictionary else {}
	goals_expanded = bool(cf.get_value("settings", "goals_expanded", false))
	free_play = bool(cf.get_value("settings", "free_play", false))
	ask_tutorial = bool(cf.get_value("settings", "ask_tutorial", true))
	tutorial_done = bool(cf.get_value("global", "tutorial_done", false))
	walks_lost = int(cf.get_value("global", "walks_lost", 0))
	tips_seen.assign(Array(cf.get_value("tips", "seen", PackedStringArray())))
	agility_best = maxf(0.0, float(cf.get_value("freedom", "agility_best", 0.0)))


func save_records() -> void:
	if not persist:
		return
	var cf := ConfigFile.new()
	for lv in LEVELS:
		if not records.has(lv):
			continue
		cf.set_value(lv, "bones", records[lv].bones)
		cf.set_value(lv, "time", records[lv].time)
		cf.set_value(lv, "perfects", records[lv].perfects)
		cf.set_value(lv, "style", records[lv].get("style", 0))
		cf.set_value(lv, "stars", records[lv].get("stars", 0))
		cf.set_value(lv, "goals", records[lv].get("goals", []))
	cf.set_value("global", "total_bones", total_bones)
	cf.set_value("cosmetics", "owned", owned.keys())
	cf.set_value("cosmetics", "collar", collar)
	cf.set_value("cosmetics", "bandana", bandana)
	cf.set_value("cosmetics", "coat", coat)
	cf.set_value("player", "dog", dog)
	cf.set_value("settings", "vol_master", vol_master)
	cf.set_value("settings", "vol_sfx", vol_sfx)
	cf.set_value("settings", "vol_music", vol_music)
	cf.set_value("settings", "fullscreen", fullscreen)
	cf.set_value("settings", "language", language)
	cf.set_value("settings", "control_layout", control_layout)
	cf.set_value("settings", "key_binds", key_binds)
	cf.set_value("settings", "pad_binds", pad_binds)
	cf.set_value("settings", "goals_expanded", goals_expanded)
	cf.set_value("settings", "free_play", free_play)
	cf.set_value("settings", "ask_tutorial", ask_tutorial)
	cf.set_value("global", "tutorial_done", tutorial_done)
	cf.set_value("global", "walks_lost", walks_lost)
	cf.set_value("tips", "seen", PackedStringArray(tips_seen))
	cf.set_value("freedom", "agility_best", agility_best)
	cf.save(save_path)


# goals are the Tony Hawk-style per-level objective list: completing one
# on any run marks it done for that level forever. Three milestones of
# completed goals earn the three stars that gate the next walk.
const STAR_MILESTONES := [3, 6, 9]


func goal_done(lv: String, id: String) -> bool:
	return records.has(lv) and (records[lv].get("goals", []) as Array).has(id)


func goals_count(lv: String) -> int:
	return (records[lv].get("goals", []) as Array).size() if records.has(lv) else 0


func mark_goal(lv: String, id: String) -> bool:
	if free_play or lv == "tutorial" or not lv in LEVELS:
		return false
	var record := _ensure_level_record(lv)
	var gl: Array = record.get("goals", [])
	if gl.has(id):
		return false
	gl.append(id)
	record["goals"] = gl
	# keep the stored star floor in step with the milestones reached
	record["stars"] = maxi(int(record.get("stars", 0)), _milestone_stars(gl.size()))
	save_records()
	return true


func _milestone_stars(n: int) -> int:
	var s := 0
	for m in STAR_MILESTONES:
		if n >= int(m):
			s += 1
	return s


func stars(lv: String) -> int:
	# derived from goals, but never below a legacy stored value
	var stored := int(records[lv].get("stars", 0)) if records.has(lv) else 0
	return maxi(stored, _milestone_stars(goals_count(lv)))


func total_stars() -> int:
	var s := 0
	for lv in LEVELS:
		s += stars(lv)
	return s


func has_completed(lv: String) -> bool:
	if free_play:
		return true
	if not records.has(lv):
		return false
	var r: Dictionary = records[lv]
	return int(r.get("bones", 0)) > 0 or float(r.get("time", 0.0)) > 0.0


func chase_gate_needed(lv: String) -> String:
	if free_play or lv == "tutorial" or not CHASE_GATE.has(lv):
		return ""
	var req: String = String(CHASE_GATE[lv])
	return "" if has_completed(req) else req


func is_unlocked(lv: String) -> bool:
	if free_play or lv == "tutorial":
		return true  # the tutorial is always open, and free play opens all walks
	if lv == "raval":
		return has_completed("gracia")
	if chase_gate_needed(lv) != "":
		return false
	return total_stars() >= int(STAR_GATE.get(lv, 0))


# A walk's style (its banked combos, summed): kept per walk as a record. True
# when it beat the old one.
func record_style(lv: String, style: int) -> bool:
	if free_play or not lv in LEVELS or style <= 0:
		return false
	var r := _ensure_level_record(lv)
	if style <= int(r.get("style", 0)):
		return false
	r.style = style
	records[lv] = r
	save_records()
	return true


func record_result(lv: String, bones: int, time: float, perfect: bool) -> Dictionary:
	# stars/unlocks now come from goals (marked live during the run); this
	# only records the best-bones/time/perfect tallies and banks bones.
	var out := {"bones_record": false, "time_record": false}
	if free_play or lv == "tutorial" or not lv in LEVELS:
		return out
	var r := _ensure_level_record(lv)
	if bones > int(r.bones):
		r.bones = bones
		out.bones_record = true
	if float(r.time) <= 0.0 or time < float(r.time):
		r.time = time
		out.time_record = true
	if perfect:
		r.perfects = int(r.perfects) + 1
	records[lv] = r
	total_bones += bones
	save_records()
	return out


func gate_crossed(prev_total: int, lv: String) -> bool:
	var gate := int(STAR_GATE.get(lv, 0))
	return gate > prev_total and gate <= total_stars()


func best_line(lv: String) -> String:
	var ch := chase_gate_needed(lv)
	if ch != "":
		return "locked - complete %s to enter" % LEVEL_NAMES.get(ch, ch)
	if not is_unlocked(lv):
		return "locked - earn %d stars to unlock" % int(STAR_GATE.get(lv, 0))
	if not records.has(lv) or int(records[lv].bones) <= 0:
		return "no record on this walk yet"
	var s := "best: %d bones in %ds   %s" % [int(records[lv].bones), int(records[lv].time), star_str(stars(lv))]
	return s


func star_str(n: int) -> String:
	return "*".repeat(n) + "-".repeat(maxi(0, 3 - n))


func cycle_level(dir: int) -> void:
	# cycle the walk select; locked walks show but cannot be started
	var i := CAROUSEL.find(level_id)
	if i < 0:
		i = 1
	level_id = CAROUSEL[wrapi(i + dir, 0, CAROUSEL.size())]


func is_tutorial(lv: String) -> bool:
	return lv == "tutorial"


# The line under a walk's name, in the player's language; English where a
# walk has no translation yet.
func gloss(lv: String) -> String:
	var en := String(LEVEL_SUBTITLES.get(lv, ""))
	match language:
		"ca": return String(LEVEL_SUBTITLES_CA.get(lv, en))
		"es": return String(LEVEL_SUBTITLES_ES.get(lv, en))
	return en
