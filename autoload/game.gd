extends Node

# Autoload: session state that must survive scene reloads.

const LEVELS: Array[String] = ["barri", "street", "park", "beach", "rain", "market", "oldtown", "sarria", "trail", "station", "besos", "site", "spook", "scrap", "guell", "neteja", "montjuic", "partit", "port", "reial", "vet", "tibidabo", "aigues", "horta", "llevant", "boars", "gracia", "carmel", "superilla", "metro", "forum", "espanya", "raval", "eixample", "angels", "poble", "ciutadella", "cremada", "aeroport", "montserrat", "diagonal", "blai", "molina", "santpau", "sitges", "ronda", "atraccions", "encants", "tarragona", "vic", "girona", "poblenou", "xemeneies", "llucia", "santacoloma"]
const LEVEL_NAMES := {
	"tutorial": "First Walk",
	# One scheme: a Catalan article plus one everyday noun for the place you
	# are walking through, spelled as in Catalan, accents and all (the game's
	# fonts carry them, and the HUD upper-cases everything). The tutorial
	# stays English on purpose - it names a mode, not a place.
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
	"oldtown": "El Gòtic", "trail": "El Bosc", "angels": "Els Àngels", "station": "L'Estació",
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
	"carmel": "Els Búnquers",
	"superilla": "La Superilla",
	# underground, from a rainy street down to the platforms and one stop on
	"metro": "El Metro",
	"forum": "El Fòrum",
	"espanya": "Plaça d'Espanya",
	"poble": "El Poble Espanyol", "ciutadella": "La Ciutadella", "cremada": "La Cremada",
	"aeroport": "L'Aeroport",
	"montserrat": "Montserrat",
	"molina": "La Molina",
	"raval": "Rambla del Raval",
	# Cerdà's grid round the basilica, named for the district
	"eixample": "L'Eixample",
	# the old village the city swallowed, named for itself
	"sarria": "Sarrià",
	"diagonal": "La Diagonal",
	# Poble-sec's pintxos street, named as its sign on the corner says
	"blai": "Carrer de Blai",
	# Domènech i Montaner's modernista hospital grounds
	"santpau": "Sant Pau",
	"sitges": "Sitges",
	"ronda": "Camí de Ronda",
	"atraccions": "Les Atraccions",
	"encants": "Els Encants",
	"tarragona": "Tarragona",
	"vic": "Vic",
	"girona": "Girona",
	"poblenou": "Rambla del Poblenou",
	"xemeneies": "Les Tres Xemeneies",
	"llucia": "Fira de Santa Llúcia",
	"santacoloma": "Santa Coloma",
}
# The Catalan name carries the character; this carries the meaning. The game
# ships in English, so a player who does not speak Catalan should never have to
# guess what a walk is - the name is the flavour, the gloss is the information.
# A sentence-case line that says what and where the walk is; it sits under
# the name chalked on the pavement, so keep it to one line there.
# A walk's gloss is a short line under its name: at most GLOSS_MAX
# characters in English and GLOSS_MAX_LONG in Catalan and Spanish, which run
# longer (tests/test_gloss_length.gd).
const GLOSS_MAX := 32
const GLOSS_MAX_LONG := 36
const LEVEL_SUBTITLES := {
	"tutorial": "Learn the leash, trick by trick",
	"barri": "The little park down your street",
	"street": "The crowded promenade",
	"park": "The city park and its duck pond",
	"beach": "The beachfront promenade",
	"rain": "A shopping street in a downpour",
	"market": "The market hall at opening time",
	"oldtown": "The old town alleys",
	"trail": "A winding woodland trail",
	"angels": "The skate plaza by the museum",
	"station": "Rush hour at the train station",
	"besos": "The river park that floods",
	"site": "A detour through the roadworks",
	"spook": "The chestnut festival",
	"scrap": "The junkyard after closing",
	"guell": "Mosaics and stone columns",
	"neteja": "The city's dawn clean-up",
	"montjuic": "The winding climb to the castle",
	"partit": "Match day at the stadium",
	"port": "The fish auction on the wharf",
	"reial": "The arcaded square off La Rambla",
	"vet": "A trip to the vet",
	"tibidabo": "The hilltop fairground",
	"aigues": "The old water road on the hill",
	"horta": "The cypress maze",
	"llevant": "The dog beach at the coast's end",
	"boars": "A wild Collserola downhill",
	"gracia": "A festival of decorated streets",
	"carmel": "The sunset lookout over the city",
	"superilla": "The car-free green superblock",
	"metro": "Rush hour, one stop on the metro",
	"forum": "The solar pergola by the sea",
	"espanya": "Magic fountains below the palace",
	"poble": "A walled village of copied towns",
	"ciutadella": "The old citadel and its mammoth",
	"cremada": "Badalona's devil-burning night",
	"aeroport": "Airport security on your tail",
	"montserrat": "Mountain paths and loose goats",
	"molina": "Ski slopes and a runaway groomer",
	"raval": "Where the big bronze cat sits",
	"eixample": "The grid of cut corners",
	"sarria": "The village the city swallowed",
	"diagonal": "The avenue that cuts the grid",
	"blai": "Pintxos, and food on the floor",
	"santpau": "The modernista hospital gardens",
	"sitges": "Whitewashed streets by the sea",
	"ronda": "The cliff path above the coves",
	"atraccions": "Coasters, queues and churros",
	"encants": "Flea-market junk under a mirror",
	"tarragona": "Roman walls above the dusk sea",
	"vic": "Fog, arcades and hanging fuet",
	"girona": "Onyar houses, steps and lioness",
	"poblenou": "Plane trees, horchata and breeze",
	"xemeneies": "Brick chimneys, murals and ramps",
	"llucia": "Christmas stalls and Caga Tió",
	"santacoloma": "Steep market, spices & dominoes",
}
# Tony Hawk-style gating: total stars earned so far unlocks the next
# walk. The first is always open; each subsequent walk asks a little more.
# The first few open quickly, so a new player is never stuck on one walk.
const STAR_GATE := {"barri": 0, "street": 1, "park": 2, "beach": 3, "neteja": 4, "oldtown": 7, "montjuic": 9, "market": 11, "rain": 13, "besos": 14, "ciutadella": 15, "llevant": 15, "eixample": 16, "poblenou": 17, "tibidabo": 17, "vet": 19, "sarria": 21, "trail": 21, "angels": 22, "spook": 23, "boars": 25, "guell": 27, "superilla": 29, "metro": 31, "xemeneies": 31, "carmel": 31, "cremada": 33, "station": 35, "reial": 36, "forum": 37, "aigues": 38, "aeroport": 39, "port": 39, "diagonal": 40, "blai": 41, "llucia": 42, "horta": 42, "molina": 43, "espanya": 45, "santpau": 46, "poble": 46, "sitges": 47, "atraccions": 47, "girona": 47, "site": 47, "ronda": 47, "santacoloma": 47, "partit": 47, "montserrat": 48, "encants": 49, "tarragona": 50, "vic": 50, "scrap": 50, "gracia": 52, "raval": 53}

# Keystone Chase milestone gates: each tier requires surviving the previous
# tier's chase level end-to-end to enter.
const CHASE_GATE := {
	"oldtown": "neteja",
	"montjuic": "neteja",
	"market": "neteja",
	"rain": "neteja",
	"besos": "neteja",
	"ciutadella": "besos",
	"llevant": "besos",
	"eixample": "besos",
	"poblenou": "besos",
	"tibidabo": "besos",
	"vet": "besos",
	"sarria": "vet",
	"trail": "vet",
	"angels": "vet",
	"spook": "vet",
	"boars": "vet",
	"guell": "boars",
	"superilla": "boars",
	"metro": "boars",
	"xemeneies": "boars",
	"carmel": "boars",
	"cremada": "boars",
	"station": "cremada",
	"reial": "cremada",
	"forum": "cremada",
	"aigues": "cremada",
	"aeroport": "cremada",
	"port": "aeroport",
	"diagonal": "aeroport",
	"blai": "aeroport",
	"llucia": "aeroport",
	"horta": "aeroport",
	"molina": "aeroport",
	"espanya": "molina",
	"santpau": "molina",
	"poble": "molina",
	"sitges": "molina",
	"atraccions": "molina",
	"girona": "atraccions",
	"site": "atraccions",
	"ronda": "atraccions",
	"santacoloma": "atraccions",
	"partit": "atraccions",
	"montserrat": "atraccions",
	"encants": "montserrat",
	"tarragona": "montserrat",
	"vic": "montserrat",
	"scrap": "montserrat",
	"gracia": "montserrat",
	"raval": "gracia",
}

# The four kinds of weather the rules read (Game.weather): who is out, slick
# paving, ice, puddles. Each sky the player can pick (SKIES) is one of these
# kinds at its own strength of rain, wind, fog and dust (SKY), which only the
# look and the wind's push read.
const WEATHERS: Array[String] = ["clear", "rain", "wind", "snow"]
# the skies, in the order WEATHER cycles them
const SKIES: Array[String] = ["clear", "breeze", "fog", "calima", "drizzle", "rain", "storm", "wind", "snow"]
const SKY := {
	"clear": {"kind": "clear", "rain": 0.0, "wind": 0.0, "fog": 0.0, "dust": 0.0},
	# sun and a fresh breeze off the sea: kites up, gusts now and then
	"breeze": {"kind": "clear", "rain": 0.0, "wind": 0.55, "fog": 0.0, "dust": 0.0},
	"fog": {"kind": "clear", "rain": 0.0, "wind": 0.0, "fog": 1.0, "dust": 0.0},
	# the calima: a light wind bringing the Sahara's dust over the city, an
	# orange-brown haze and a pale sun; a clear day to the rules, a bad-air one
	# to whoever was going to lie out in it
	"calima": {"kind": "clear", "rain": 0.0, "wind": 0.35, "fog": 0.0, "dust": 1.0},
	"drizzle": {"kind": "rain", "rain": 0.4, "wind": 0.1, "fog": 0.3, "dust": 0.0},
	"rain": {"kind": "rain", "rain": 1.0, "wind": 0.2, "fog": 0.0, "dust": 0.0},
	# a downpour driven sideways by a gale
	"storm": {"kind": "rain", "rain": 1.0, "wind": 1.0, "fog": 0.15, "dust": 0.0},
	# a dry gale: the tramuntana
	"wind": {"kind": "wind", "rain": 0.0, "wind": 1.0, "fog": 0.0, "dust": 0.0},
	"snow": {"kind": "snow", "rain": 0.0, "wind": 0.25, "fog": 0.15, "dust": 0.0},
}
const WEATHER_NAMES := {"clear": "CLEAR", "breeze": "BREEZE", "fog": "FOG", "calima": "SAHARA DUST", "drizzle": "DRIZZLE",
	"rain": "DOWNPOUR", "storm": "STORM", "wind": "GALE", "snow": "SNOW"}
# The hours the rules read (Game.hour), and the times a walk is walked at
# (TIMES), in the order TIME cycles them: morning is day to the rules, with
# a low sun of its own; evening, the blue hour, is night to them, lamps lit
# and everyone in, under a sky not yet dark.
const HOURS: Array[String] = ["dawn", "day", "dusk", "night"]
const TIMES: Array[String] = ["dawn", "morning", "day", "dusk", "evening", "night"]
const TIME_HOUR := {"dawn": "dawn", "morning": "day", "day": "day", "dusk": "dusk", "evening": "night", "night": "night"}
const HOUR_NAMES := {"dawn": "DAWN", "morning": "MORNING", "day": "DAY", "dusk": "DUSK", "evening": "EVENING",
	"night": "NIGHT"}

# Some walks bring their own sky: El Diluvi is always a downpour, La
# Castanyada always after dark, and the first walk a clear day. It holds for
# that walk only (apply_walk_sky), so browsing past one never carries its rain
# or its dark on to the walks after it.
const WALK_WEATHER := {"rain": "rain", "tutorial": "clear"}
const WALK_HOUR := {"spook": "night", "tutorial": "day"}
# The campaign's sky: each walk is walked at its own time and in its own
# weather, shown on the walk card, so a walk is the same walk for everyone
# the first time. Once a walk is finished, FREE WALK (GET READY) opens its
# time and weather to the player, and records nothing (is_free_walk,
# recording). The films agree: Festa de Gràcia and El Gat's are at night;
# La Neteja is the street cleaning at first light, Els Búnquers the sunset
# over the city. El Besòs floods in a storm, the fog sits on Tibidabo of a
# morning, and the maze at Horta drips. WALK_WEATHER and WALK_HOUR still win.
const CAMPAIGN_SKY := {
	"barri": ["clear", "day"], "street": ["clear", "day"], "park": ["clear", "day"],
	"beach": ["wind", "dawn"], "neteja": ["clear", "dawn"], "oldtown": ["clear", "day"],
	"montjuic": ["clear", "day"], "market": ["clear", "day"], "rain": ["rain", "day"],
	"besos": ["storm", "day"], "llevant": ["wind", "day"], "tibidabo": ["fog", "morning"],
	"vet": ["clear", "day"], "trail": ["clear", "day"], "angels": ["clear", "day"], "spook": ["clear", "night"],
	"boars": ["clear", "day"], "guell": ["clear", "day"], "superilla": ["clear", "morning"], "metro": ["rain", "day"],
	"station": ["clear", "day"], "carmel": ["clear", "dusk"], "reial": ["clear", "night"],
	"forum": ["wind", "day"], "aigues": ["clear", "day"], "horta": ["drizzle", "day"],
	"port": ["clear", "day"], "espanya": ["clear", "night"], "poble": ["clear", "day"], "ciutadella": ["clear", "day"], "cremada": ["clear", "night"], "aeroport": ["clear", "day"], "montserrat": ["clear", "day"], "site": ["clear", "day"],
	"partit": ["clear", "night"], "scrap": ["clear", "day"], "gracia": ["clear", "night"],
	"raval": ["clear", "night"], "eixample": ["clear", "day"], "diagonal": ["clear", "day"], "blai": ["clear", "night"],
	"santpau": ["clear", "dusk"],
	"sitges": ["wind", "day"],
	# the morning dog walk: shutters going up, bread crates out, first light
	"sarria": ["clear", "dawn"],
	# the first snow walk
	"molina": ["snow", "day"],
	# Costa Brava cliff path in the tramuntana
	"ronda": ["wind", "day"],
	"atraccions": ["clear", "day"],
	# flea market under the mirrored canopy at Glòries
	"encants": ["rain", "day"],
	# Roman stones above the Mediterranean at dusk
	"tarragona": ["clear", "dusk"],
	# inland market under fog
	"vic": ["fog", "morning"],
	# Onyar houses, Eiffel bridge and La Lleona in rain at dusk
	"girona": ["rain", "dusk"],
	# leafy rambla with sea breeze in the morning
	"poblenou": ["breeze", "morning"],
	# Paral·lel brick chimneys and skate concrete at dusk
	"xemeneies": ["clear", "dusk"],
	# cathedral Christmas fair in the evening blue hour under fairy lights
	"llucia": ["clear", "evening"],
	# steep hillside market and domino plazas across the Besòs
	"santacoloma": ["clear", "day"],
}

# the walk select: the first walk, then the campaign walks in order
const CAROUSEL: Array[String] = ["tutorial", "barri", "street", "park", "beach", "neteja", "oldtown", "montjuic", "market", "rain", "besos", "ciutadella", "llevant", "eixample", "poblenou", "tibidabo", "vet", "sarria", "trail", "angels", "spook", "boars", "guell", "superilla", "metro", "xemeneies", "carmel", "cremada", "station", "reial", "forum", "aigues", "aeroport", "port", "diagonal", "blai", "llucia", "horta", "molina", "espanya", "santpau", "poble", "sitges", "atraccions", "girona", "site", "ronda", "santacoloma", "partit", "montserrat", "encants", "tarragona", "vic", "scrap", "gracia", "raval"]

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
# your human's palettes (human_look): skin tones light to deep, hair colours,
# and clothes that read against every walk's ground
const HUMAN_SKINS := [Color(0.98, 0.84, 0.72), Color(0.95, 0.77, 0.62), Color(0.86, 0.66, 0.50),
	Color(0.72, 0.52, 0.36), Color(0.55, 0.38, 0.26), Color(0.40, 0.27, 0.19)]
const HUMAN_HAIRS := [Color(0.12, 0.10, 0.09), Color(0.28, 0.18, 0.11), Color(0.42, 0.25, 0.15),
	Color(0.62, 0.30, 0.14), Color(0.86, 0.70, 0.40), Color(0.70, 0.70, 0.72)]
const HIS_HAIR := ["short", "curly", "bald", "bun"]
const HER_HAIR := ["ponytail", "curly", "bob", "long"]
const HUMAN_SHIRTS := [Color(0.24, 0.45, 0.78), Color(0.80, 0.30, 0.26), Color(0.26, 0.56, 0.44),
	Color(0.92, 0.70, 0.22), Color(0.52, 0.34, 0.66), Color(0.90, 0.88, 0.84), Color(0.20, 0.22, 0.26),
	Color(0.94, 0.50, 0.32)]
const HUMAN_TROUSERS := [Color(0.25, 0.27, 0.36), Color(0.30, 0.28, 0.34), Color(0.18, 0.26, 0.44),
	Color(0.44, 0.38, 0.28), Color(0.15, 0.15, 0.17)]
const HUMAN_SHOES := [Color(0.95, 0.93, 0.88), Color(0.16, 0.16, 0.18), Color(0.72, 0.30, 0.24),
	Color(0.48, 0.34, 0.22)]

const DOGS := {
	"millie": {
		# training levels she is born with (Game.innate_stat)
		"innate": {"nose": 2},
		"quirk": "sniff",
		"bark": "bark",
		"name": "Millie",
		"breed": "Mongrel",
		"stars": 0,
		"trait": "Balanced",
		"desc": "Jack of all trades, master of sniffs",
		"speed_mult": 1.0,
		"accel_mult": 1.0,
		"plant_mult": 1.0,
		"nose_mult": 1.3,
	},
	"pipa": {
		# training levels she is born with (Game.innate_stat)
		"innate": {"speed": 2},
		"quirk": "stretch",
		"bark": "bark_pipa",
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
		# training levels she is born with (Game.innate_stat)
		"innate": {"plant": 2},
		"quirk": "sit",
		"bark": "bark_mochi",
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
		# training levels she is born with (Game.innate_stat)
		"innate": {"herd": 2},
		"quirk": "lie",
		"bark": "bark_bruna",
		"name": "Bruna",
		"breed": "Gos d'atura",
		"stars": 35,
		"trait": "Herds your human, collects muck",
		"desc": "A shaggy sheepdog who steers your human with ease",
		"speed_mult": 1.00,
		"accel_mult": 1.05,
		"plant_mult": 1.00,
		"herd_mult": 1.45,
		"muck_mult": 1.60,
	},
	"tito": {
		# training levels she is born with (Game.innate_stat)
		"innate": {"agility": 2},
		"quirk": "tremble",
		"bark": "bark_tito",
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
	# the ratonero bodeguero, the Andalusian ratter of the wine cellars:
	# small, square and busy, and digs anything up in no time
	"perla": {
		# training levels she is born with (Game.innate_stat)
		"innate": {"nose": 1, "agility": 1},
		"name": "Perla",
		"breed": "Ratonero bodeguero",
		"stars": 55,
		"trait": "Digs anything up, quick on her feet",
		"desc": "A tricolor ratter from the bodegas who digs faster than anyone",
		"speed_mult": 1.04,
		"accel_mult": 1.18,
		"plant_mult": 0.80,
		"mass_mult": 0.70,
		"gap_mult": 0.82,
		"nose_mult": 1.15,
		"dig_mult": 1.9,
		"quirk": "scrabble",
		"bark": "bark_perla",
	},
	# the podenco, the island hound: long legs, huge ears, and a standing
	# jump that clears a bench as if it were not there
	"duna": {
		# training levels she is born with (Game.innate_stat)
		"innate": {"speed": 1, "agility": 1},
		"name": "Duna",
		"breed": "Podenco",
		"stars": 65,
		"trait": "Leaps benches, long stride",
		"desc": "A red and white podenco who clears a bench from standing",
		"speed_mult": 1.12,
		"accel_mult": 1.06,
		"plant_mult": 0.72,
		"leaps": true,
		"quirk": "listen",
		"bark": "bark_duna",
	},
}
const DOG_KEYS: Array[String] = ["millie", "pipa", "mochi", "bruna", "tito", "perla", "duna"]
const DEFAULT_DOG := "millie"

const SAVE_PATH := "user://records.cfg"
# The save's version. A save from an older one starts the campaign again: its
# settings are kept and everything earned is not (_start_fresh). Version 2 is
# the finished 55-walk campaign; version 1 was the 51-walk campaign, and saves
# before it carry no version.
const SAVE_VERSION := 2
# settings kept in that section that belong to the old campaign, not the player
const FRESH_SETTINGS := ["ask_tutorial", "free_play"]
const DEFAULT_OWNED := {"collar:red": true, "bandana:none": true, "coat:millie": true}
const DEFAULT_COLLAR := "red"
const DEFAULT_BANDANA := "none"
const DEFAULT_COAT := "millie"
const DEFAULT_VOL_MASTER := 0.85
const DEFAULT_VOL_SFX := 0.9
const DEFAULT_VOL_MUSIC := 0.55

var save_path := SAVE_PATH
# This run's save is from before the campaign and has been set aside in memory.
# Nothing is written on load: the file is replaced, and the old one kept beside
# it (old_save_path), at the first real save. Until then the main menu says so.
var fresh_start := false
# false for the autowalk bot: it runs from a blank save and never writes one,
# so its walk does not depend on (or change) whoever last played here
var persist := true
var level_id := "barri"
# Your human's look, one for the walk (entities/human.gd, from above) and for
# every film (intro/human_side.gd, side on): who, skin, hair colour and
# style, shirt, trousers and shoes. NEW LOOK on GET READY rolls a fresh one;
# it is saved with the records. owner_id ("him" | "her") reads and sets who.
var human_look := default_human("him")
var owner_id: String:
	get:
		return "her" if bool(human_look.get("her", false)) else "him"
	set(v):
		if v != owner_id:
			toggle_owner()
# the time the walk is walked at (TIMES); `hour` is what it is to the rules
var time := "day"
var hour: String:
	get:
		return String(TIME_HOUR.get(time, "day"))
	set(v):
		time = v if TIME_HOUR.has(v) else "day"
# after dark: the lamps lit, the parasols furled, the phone a light
var night: bool:
	get:
		return hour == "night"
	set(v):
		time = "night" if v else "day"
# the sky the walk is walked under (SKIES); `weather` is its kind to the rules.
# Setting weather sets the sky, so "rain" is the downpour it always was.
var sky := "clear"
var weather: String:
	get:
		return String(SKY.get(sky, SKY.clear).kind)
	set(v):
		sky = v if SKY.has(v) else "clear"
# [weather, hour] as the player picked them, while a walk with its own sky
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
var language := "en":
	set(v):
		language = v
		I18n.set_language(v)
const REBIND_ACTIONS: Array[String] = [
	"move_up", "move_down", "move_left", "move_right",
	"plant", "bark", "pee", "poop", "pickup", "turbo",
	"goals", "restart", "share", "mute_music", "pause",
]
const REBIND_NAMES := {
	"move_up": "MOVE UP",
	"move_down": "MOVE DOWN",
	"move_left": "MOVE LEFT",
	"move_right": "MOVE RIGHT",
	"plant": "DIG IN",
	"bark": "BARK",
	"pee": "PEE",
	"poop": "POOP",
	"pickup": "PICK UP",
	"turbo": "ZOOMIES",
	"goals": "GOALS",
	"restart": "RESTART",
	"share": "SHARE",
	"mute_music": "MUTE MUSIC",
	"pause": "PAUSE",
}
var key_binds: Dictionary = {}
var pad_binds: Dictionary = {}
var rebind_step := -1
var rebind_wait_release := false
var screen_shake := true
var flashes := true
const TEXT_SIZES: Array[String] = ["normal", "large"]
var text_size := "normal"
const LEVEL_SUBTITLES_CA := {
	"tutorial": "Aprèn la corretja, truc a truc",
	"barri": "El parquet del final del teu carrer",
	"street": "El passeig ple de gent",
	"park": "El parc i el seu estany d'ànecs",
	"beach": "El passeig de la platja",
	"rain": "Un carrer de botigues sota el xàfec",
	"market": "El mercat cobert a primera hora",
	"oldtown": "Els carrerons del barri vell",
	"trail": "Un camí que serpenteja pel bosc",
	"angels": "La plaça dels patinadors",
	"station": "Hora punta a l'estació de tren",
	"besos": "El parc fluvial que s'inunda",
	"site": "Un desviament per les obres",
	"spook": "La festa de les castanyes",
	"scrap": "El desballestament ja tancat",
	"guell": "Trencadís i columnes de pedra",
	"neteja": "La ciutat neta a trenc d'alba",
	"montjuic": "La pujada serpentejant al castell",
	"partit": "Dia de partit a l'estadi",
	"port": "La subhasta de peix al moll",
	"reial": "La plaça porticada de la Rambla",
	"vet": "Una visita al veterinari",
	"tibidabo": "El cim i les seves atraccions",
	"aigues": "L'antic camí de l'aigua al turó",
	"horta": "El laberint de xiprers",
	"llevant": "La platja dels gossos de la costa",
	"boars": "La baixada salvatge per Collserola",
	"gracia": "La festa dels carrers guarnits",
	"carmel": "El mirador del capvespre",
	"superilla": "L'eix verd pacificat per a vianants",
	"metro": "Hora punta, una parada de metro",
	"forum": "La pèrgola solar vora el mar",
	"espanya": "Les fonts màgiques sota el palau",
	"poble": "Un poble emmurallat de còpies",
	"ciutadella": "L'antiga ciutadella i el seu mamut",
	"cremada": "La nit que Badalona crema el Dimoni",
	"aeroport": "La Terminal 1, amb seguretat darrere",
	"montserrat": "Camins de muntanya i cabres soltes",
	"molina": "La pista i la trepitjaneu desbocada",
	"raval": "On seu el gat gros de bronze",
	"eixample": "La quadrícula dels xamfrans",
	"sarria": "El poble que s'empassà la ciutat",
	"diagonal": "L'avinguda que talla la quadrícula",
	"blai": "Pintxos, i menjar per terra",
	"santpau": "Els jardins de l'hospital modernista",
	"sitges": "Carrers emblanquinats vora el mar",
	"ronda": "El camí de ronda sobre les cales",
	"atraccions": "Muntanyes russes, cues i xurros",
	"encants": "Parades d'andròmines sota el mirall",
	"tarragona": "Muralles romanes al capvespre",
	"vic": "Boira, porxos i fuets penjats",
	"girona": "Cases de l'Onyar, escales i lleona",
	"poblenou": "Plàtans, orxata i brisa de mar",
	"xemeneies": "Xemeneies, murals i rampes",
	"llucia": "Fira de Nadal i Caga Tió",
	"santacoloma": "Mercat en pujada, espècies i dòmino",
}
const LEVEL_SUBTITLES_ES := {
	"tutorial": "Aprende la correa, truco a truco",
	"barri": "El parquecito al final de tu calle",
	"street": "El paseo abarrotado",
	"park": "El parque y su estanque de patos",
	"beach": "El paseo de la playa",
	"rain": "Calle de tiendas bajo el chaparrón",
	"market": "El mercado cubierto al abrir",
	"oldtown": "Los callejones del casco antiguo",
	"trail": "Un sendero por el bosque",
	"angels": "La plaza de los patinadores",
	"station": "Hora punta en la estación de tren",
	"besos": "El parque fluvial que se inunda",
	"site": "Un desvío entre las obras",
	"spook": "La fiesta de las castañas",
	"scrap": "El desguace después de cerrar",
	"guell": "Mosaicos y columnas de piedra",
	"neteja": "La limpieza de la ciudad al amanecer",
	"montjuic": "La subida serpenteante al castillo",
	"partit": "Día de partido en el estadio",
	"port": "La lonja de pescado del muelle",
	"reial": "La plaza porticada junto a La Rambla",
	"vet": "Una visita al veterinario",
	"tibidabo": "La cima y sus atracciones",
	"aigues": "El viejo camino del agua en el monte",
	"horta": "El laberint de cipreses",
	"llevant": "La playa de perros de la costa",
	"boars": "El descenso salvaje por Collserola",
	"gracia": "La fiesta de las calles adornadas",
	"carmel": "El mirador del atardecer",
	"superilla": "El eje verde para peatones",
	"metro": "Hora punta, una parada de metro",
	"forum": "La pérgola solar junto al mar",
	"espanya": "Las fuentes mágicas bajo el palacio",
	"poble": "Un pueblo amurallado de copias",
	"ciutadella": "La vieja ciudadela y su mamut",
	"cremada": "Badalona quema a su Dimoni",
	"aeroport": "La Terminal 1, con seguridad detrás",
	"montserrat": "Senderos de montaña y cabras sueltas",
	"molina": "La pista y la pisanieves desbocada",
	"raval": "Donde se sienta el gato de bronce",
	"eixample": "La cuadrícula de chaflanes",
	"sarria": "El pueblo que se tragó la ciudad",
	"diagonal": "La avenida que corta la cuadrícula",
	"blai": "Pintxos, y comida por el suelo",
	"santpau": "Los jardines del hospital modernista",
	"sitges": "Calles encaladas junto al mar",
	"ronda": "El camino de ronda sobre las calas",
	"atraccions": "Montañas rusas, colas y churros",
	"encants": "Trastos y puestos bajo el espejo",
	"tarragona": "Murallas romanas al atardecer",
	"vic": "Niebla, porches y fuet colgado",
	"girona": "Casas del Onyar, escaleras y leona",
	"poblenou": "Plátanos, horchata y brisa marina",
	"xemeneies": "Chimeneas, murales y rampas",
	"llucia": "Feria de Navidad y Caga Tió",
	"santacoloma": "Cuestas, especias, mercado y dominó",
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
# GET READY's WALK row: free walk (true) or the campaign. For this session
# only, and only on a finished walk (is_free_walk).
var free_walk := false
# --weather=, --hour= or --night was given: that sky, on every walk, for the run
var sky_from_args := false
# The first walk (the tutorial): whether the title still offers it before the
# walks, and whether it has been walked to the end.
var ask_tutorial := true
# first-time tips already shown (systems/tips.gd): each shows once, ever
var tips_seen: Array[String] = []
var tutorial_done := false
# walks lost, ever (systems/losses.gd): the first loss gets a word of comfort
var walks_lost := 0
# in-game achievements unlocked on this save (systems/achievements.gd)
var achievements: Array[String] = []
var dogs_walked: Array[String] = []
var gallery_bones: Array[String] = []


func apply_walk_sky(lv: String) -> void:
	var own_weather := walk_sets_weather(lv)
	var own_hour := walk_sets_hour(lv)
	if own_weather or own_hour:
		if _held_sky.is_empty():
			_held_sky = [sky, time]
		weather = _walk_weather(lv) if own_weather else String(_held_sky[0])
		hour = _walk_hour(lv) if own_hour else String(_held_sky[1])
	elif not _held_sky.is_empty():
		weather = String(_held_sky[0])
		hour = String(_held_sky[1])
		_held_sky = []


# the campaign holds a walk's sky unless this is a free walk, or the sky was
# set on the command line (--weather, --hour, --night: CI and screenshots)
func _campaign_holds(lv: String) -> bool:
	return CAMPAIGN_SKY.has(lv) and not is_free_walk(lv) and not sky_from_args


func _walk_weather(lv: String) -> String:
	if WALK_WEATHER.has(lv):
		return String(WALK_WEATHER[lv])
	return String(CAMPAIGN_SKY[lv][0])


func _walk_hour(lv: String) -> String:
	if WALK_HOUR.has(lv):
		return String(WALK_HOUR[lv])
	return String(CAMPAIGN_SKY[lv][1])


func walk_sets_weather(lv: String) -> bool:
	return WALK_WEATHER.has(lv) or _campaign_holds(lv)


func walk_sets_hour(lv: String) -> bool:
	return WALK_HOUR.has(lv) or _campaign_holds(lv)


# FREE WALK: a finished walk at any time and in any weather, for the fun of
# it. Nothing it does is recorded (recording). Free play opens it everywhere.
func can_free_walk(lv: String) -> bool:
	return lv in LEVELS and (free_play or has_completed(lv))


func is_free_walk(lv: String) -> bool:
	return free_walk and can_free_walk(lv)


# whether this walk's goals, stars, style and best tallies are saved
func recording(lv: String) -> bool:
	return not free_play and not is_free_walk(lv) and lv != "tutorial" and lv in LEVELS


func cycle_hour(dir := 1) -> void:
	time = TIMES[wrapi(TIMES.find(time) + dir, 0, TIMES.size())]
	if not _held_sky.is_empty():
		_held_sky[1] = time


# How lit the street lamps are: full after dark, still on at first light and
# coming on at dusk, off by day.
func lamp_glow() -> float:
	var g := 0.0
	match time:
		"night": g = 1.0
		"evening": g = 0.75
		"dusk": g = 0.55
		"dawn": g = 0.45
	# a dark sky by day brings the lamps on early
	var gloom := maxf(fog_amount() * 0.5, rain_amount() * wind_amount() * 0.45)
	return maxf(g, gloom)


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


# what she does of her own accord after standing still a while (entities/dog.gd)
func dog_quirk(k := "") -> String:
	return String(dog_data(k).get("quirk", "sniff"))


# her own bark: a sound in Sfx's library
func dog_bark(k := "") -> String:
	return String(dog_data(k).get("bark", "bark"))


func dog_name(k := "") -> String:
	return String(dog_data(k).get("name", "Millie"))


func dog_breed(k := "") -> String:
	return String(dog_data(k).get("breed", "Mongrel")).to_lower()


func dog_trait(k := "") -> String:
	return String(dog_data(k).get("trait", "Balanced"))


func dog_desc(k := "") -> String:
	return String(dog_data(k).get("desc", ""))


# Training, as a skater's stats are: each dog has her own points to spend
# (training_points), earned by what she finds on the walks
# (systems/buried_finds.gd), and spends them on her own stats, a level at a
# time. Level n costs n points, so a maxed stat is 15 and a maxed dog 75.
# Each level is a small step: a maxed stat is about a fifth better, so a
# trained dog is clearly better and still her breed.
const MAX_STAT_POINTS := 5
const STAT_NAMES: Array[String] = ["speed", "plant", "herd", "agility", "nose"]

var dog_upgrades: Dictionary = {}
# training points not yet spent, per dog
var training: Dictionary = {}
# the buried finds each dog has dug up: dog -> walk -> [find index, ...]
var finds_found: Dictionary = {}
# the walks on which each dog has met her skill goal (systems/dog_skills.gd):
# dog -> [walk, ...]
var skills_done: Dictionary = {}


# A stat's level: the levels her breed gives her for free (DOGS "innate", a
# head start in what she is bred for) plus the levels she has trained, never
# past MAX_STAT_POINTS. Every level counts the same toward the stat's effect.
func get_dog_stat(d: String, stat: String) -> int:
	return mini(innate_stat(d, stat) + trained_stat(d, stat), MAX_STAT_POINTS)


func innate_stat(d: String, stat: String) -> int:
	var inn: Dictionary = dog_data(d).get("innate", {})
	return int(inn.get(stat, 0))


func trained_stat(d: String, stat: String) -> int:
	var du: Dictionary = dog_upgrades.get(d, {})
	return int(du.get(stat, 0))


func training_points(d := "") -> int:
	return int(training.get(d if d != "" else dog, 0))


# what the next level of a stat costs: the level it would reach
func stat_cost(d: String, stat: String) -> int:
	return get_dog_stat(d, stat) + 1


func can_upgrade_stat(d: String, stat: String) -> bool:
	if not is_dog_unlocked(d):
		return false
	return get_dog_stat(d, stat) < MAX_STAT_POINTS and training_points(d) >= stat_cost(d, stat)


func upgrade_dog_stat(d: String, stat: String) -> bool:
	if not can_upgrade_stat(d, stat):
		return false
	training[d] = training_points(d) - stat_cost(d, stat)
	if not dog_upgrades.has(d):
		dog_upgrades[d] = {}
	dog_upgrades[d][stat] = trained_stat(d, stat) + 1
	save_records()
	return true


# whether this dog has dug up this find on this walk
func find_found(lv: String, i: int, d := "") -> bool:
	var per: Dictionary = finds_found.get(d if d != "" else dog, {})
	return i in (per.get(lv, []) as Array)


# a find dug up for the first time by this dog: a training point for her.
# Says whether it was new.
func record_find(lv: String, i: int, d := "") -> bool:
	var key := d if d != "" else dog
	if find_found(lv, i, key):
		return false
	if not finds_found.has(key):
		finds_found[key] = {}
	var per: Dictionary = finds_found[key]
	if not per.has(lv):
		per[lv] = []
	(per[lv] as Array).append(i)
	training[key] = training_points(key) + 1
	save_records()
	return true


# whether this dog has met her skill goal on this walk
func skill_done(lv: String, d := "") -> bool:
	return lv in (skills_done.get(d if d != "" else dog, []) as Array)


# a skill goal met for the first time on this walk by this dog: a training
# point for her. Says whether it was new.
func record_skill(lv: String, d := "") -> bool:
	var key := d if d != "" else dog
	if skill_done(lv, key):
		return false
	if not skills_done.has(key):
		skills_done[key] = []
	(skills_done[key] as Array).append(lv)
	training[key] = training_points(key) + 1
	save_records()
	return true


func finds_count(d := "") -> int:
	var n := 0
	for lv: String in (finds_found.get(d if d != "" else dog, {}) as Dictionary):
		n += (finds_found[d if d != "" else dog][lv] as Array).size()
	return n


# how far her nose reaches, against the breed's: each level of NOSE a tenth
# how much faster than Millie she digs (buried finds, a yard's dig patches)
func dog_dig_mult(k := "") -> float:
	return float(dog_data(k).get("dig_mult", 1.0))


# whether she clears a bench in a standing jump (systems/dog_skills.gd)
func dog_leaps(k := "") -> bool:
	return bool(dog_data(k).get("leaps", false))


func dog_nose_mult(k := "") -> float:
	var key := k if k != "" else dog
	return float(dog_data(key).get("nose_mult", 1.0)) + float(get_dog_stat(key, "nose")) * 0.10


func dog_speed_mult(k := "") -> float:
	var key := k if k != "" else dog
	var base := float(dog_data(key).get("speed_mult", 1.0))
	var bonus := float(get_dog_stat(key, "speed")) * 0.05
	return base + bonus


func dog_accel_mult(k := "") -> float:
	var key := k if k != "" else dog
	var base := float(dog_data(key).get("accel_mult", 1.0))
	var bonus := float(get_dog_stat(key, "agility")) * 0.06
	return base + bonus


func dog_plant_mult(k := "") -> float:
	var key := k if k != "" else dog
	var base := float(dog_data(key).get("plant_mult", 1.0))
	var bonus := float(get_dog_stat(key, "plant")) * 0.10
	return base + bonus


func dog_herd_mult(k := "") -> float:
	var key := k if k != "" else dog
	var base := float(dog_data(key).get("herd_mult", 1.0))
	var bonus := float(get_dog_stat(key, "herd")) * 0.08
	return base + bonus


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
	# the same person, the other way round: the colours stay, the hair style
	# swaps for the matching one on the other side
	var her := not bool(human_look.get("her", false))
	var from: Array = HIS_HAIR if her else HER_HAIR
	var to: Array = HER_HAIR if her else HIS_HAIR
	var i := maxi(0, from.find(String(human_look.get("hair_style", ""))))
	human_look["her"] = her
	human_look["hair_style"] = to[i % to.size()]


# The look a new player starts with: him as the films first drew him, her in
# the walk's original colours.
static func default_human(who: String) -> Dictionary:
	if who == "her":
		return {"her": true, "skin": HUMAN_SKINS[1], "hair": HUMAN_HAIRS[2], "hair_style": "ponytail",
			"shirt": Color(0.72, 0.36, 0.44), "trousers": HUMAN_TROUSERS[1], "shoe": HUMAN_SHOES[0]}
	return {"her": false, "skin": HUMAN_SKINS[1], "hair": HUMAN_HAIRS[2], "hair_style": "short",
		"shirt": HUMAN_SHIRTS[0], "trousers": HUMAN_TROUSERS[0], "shoe": HUMAN_SHOES[0]}


# NEW LOOK: a different-looking person each time (never the same twice in a
# row), him or her
func randomize_human(rng: RandomNumberGenerator = null) -> void:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var was := human_look.duplicate()
	for _try in range(8):
		var her := rng.randf() < 0.5
		var styles: Array = HER_HAIR if her else HIS_HAIR
		human_look = {
			"her": her,
			"skin": HUMAN_SKINS[rng.randi() % HUMAN_SKINS.size()],
			"hair": HUMAN_HAIRS[rng.randi() % HUMAN_HAIRS.size()],
			"hair_style": styles[rng.randi() % styles.size()],
			"shirt": HUMAN_SHIRTS[rng.randi() % HUMAN_SHIRTS.size()],
			"trousers": HUMAN_TROUSERS[rng.randi() % HUMAN_TROUSERS.size()],
			"shoe": HUMAN_SHOES[rng.randi() % HUMAN_SHOES.size()],
		}
		if human_look != was:
			break


# a saved look, checked key by key: anything missing or malformed falls back
# to the default for that person
static func valid_human(v: Variant) -> Dictionary:
	if not (v is Dictionary):
		return default_human("him")
	var d: Dictionary = v
	var her := bool(d.get("her", false))
	var out := default_human("her" if her else "him")
	for k in ["skin", "hair", "shirt", "trousers", "shoe"]:
		if d.get(k) is Color:
			out[k] = d[k]
	var styles: Array = HER_HAIR if her else HIS_HAIR
	if String(d.get("hair_style", "")) in styles:
		out["hair_style"] = String(d["hair_style"])
	return out


func cycle_weather(dir: int) -> void:
	sky = SKIES[wrapi(SKIES.find(sky) + dir, 0, SKIES.size())]
	if not _held_sky.is_empty():
		_held_sky[0] = sky


# how hard it rains, how hard the wind blows, how thick the fog and the
# dust, 0 to 1
func rain_amount() -> float:
	return float(SKY.get(sky, SKY.clear).rain)


func wind_amount() -> float:
	return float(SKY.get(sky, SKY.clear).wind)


func fog_amount() -> float:
	return float(SKY.get(sky, SKY.clear).fog)


func dust_amount() -> float:
	return float(SKY.get(sky, SKY.clear).dust)


func apply_settings() -> void:
	# one place that pushes the saved settings at the engine, so the menu and
	# startup cannot drift apart
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(vol_master, 0.0001)))
	AudioServer.set_bus_mute(0, vol_master <= 0.001)
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	)
	apply_control_layout()
	if is_inside_tree():
		var tree := get_tree()
		var cur := tree.current_scene if tree != null else null
		if cur != null and cur.is_node_ready() and cur.has_method("_apply_ui_scale"):
			cur._apply_ui_scale()


func apply_control_layout() -> void:
	if not InputMap.has_action("plant"):
		Prompts.update_binds(key_binds, pad_binds)
		return
	for act: String in REBIND_ACTIONS:
		if InputMap.has_action(act):
			InputMap.action_erase_events(act)

	_add_pad_axis("move_left", JOY_AXIS_LEFT_X, -1.0)
	_add_pad_axis("move_right", JOY_AXIS_LEFT_X, 1.0)
	_add_pad_axis("move_up", JOY_AXIS_LEFT_Y, -1.0)
	_add_pad_axis("move_down", JOY_AXIS_LEFT_Y, 1.0)
	for act: String in ["move_left", "move_right", "move_up", "move_down"]:
		InputMap.action_set_deadzone(act, 0.25)

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
	_add_key_events("goals", [KEY_TAB])
	_add_key_events("restart", [KEY_R])
	_add_key_events("share", [KEY_C])
	_add_key_events("mute_music", [KEY_M])
	_add_key_events("pause", [KEY_ESCAPE])

	_add_pad_button("plant", JOY_BUTTON_A)
	_add_pad_button("bark", JOY_BUTTON_B)
	_add_pad_button("pee", JOY_BUTTON_X)
	_add_pad_button("poop", JOY_BUTTON_Y)
	_add_pad_button("pickup", JOY_BUTTON_LEFT_SHOULDER)
	_add_pad_axis("turbo", JOY_AXIS_TRIGGER_RIGHT, 1.0)
	InputMap.action_set_deadzone("turbo", 0.3)
	_add_pad_button("goals", JOY_BUTTON_DPAD_UP)
	_add_pad_button("restart", JOY_BUTTON_START)
	_add_pad_button("share", JOY_BUTTON_DPAD_RIGHT)
	_add_pad_button("mute_music", JOY_BUTTON_DPAD_DOWN)
	_add_pad_button("pause", JOY_BUTTON_BACK)

	for act: String in key_binds.keys():
		if InputMap.has_action(act):
			_replace_key_events(act, int(key_binds[act]))
	for act: String in pad_binds.keys():
		if InputMap.has_action(act) and valid_pad_bind(pad_binds[act]):
			_replace_pad_events(act, pad_binds[act])
	Prompts.update_binds(key_binds, pad_binds)


func _replace_key_events(action: String, code: int) -> void:
	var keep: Array = []
	for ev in InputMap.action_get_events(action):
		if not (ev is InputEventKey):
			keep.append(ev)
	InputMap.action_erase_events(action)
	for ev in keep:
		InputMap.action_add_event(action, ev)
	_add_key_events(action, [code])


func _replace_pad_events(action: String, bind: Variant) -> void:
	var keep: Array = []
	for ev in InputMap.action_get_events(action):
		if not (ev is InputEventJoypadButton or ev is InputEventJoypadMotion):
			keep.append(ev)
	InputMap.action_erase_events(action)
	for ev in keep:
		InputMap.action_add_event(action, ev)
	if bind is int:
		_add_pad_button(action, int(bind))
	elif bind is Dictionary and (bind as Dictionary).has("axis"):
		var d := bind as Dictionary
		var ax := int(d["axis"])
		var sg := 1.0 if int(d.get("sign", 1)) >= 0 else -1.0
		_add_pad_axis(action, ax, sg)
		if ax == JOY_AXIS_TRIGGER_LEFT or ax == JOY_AXIS_TRIGGER_RIGHT:
			InputMap.action_set_deadzone(action, 0.3)
		else:
			InputMap.action_set_deadzone(action, 0.25)


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


func bind_pad_axis(action: String, axis: int, axis_sign: int = 1) -> void:
	if not action in REBIND_ACTIONS:
		return
	pad_binds[action] = {"axis": axis, "sign": 1 if axis_sign >= 0 else -1}
	apply_control_layout()
	save_records()


static func valid_pad_bind(v: Variant) -> bool:
	if v is int:
		return int(v) >= 0
	if v is Dictionary:
		var d: Dictionary = v
		return d.has("axis") and int(d["axis"]) >= 0
	return false


func clear_rebinds() -> void:
	key_binds.clear()
	pad_binds.clear()
	apply_control_layout()
	save_records()


func _add_key_events(action: String, keys: Array) -> void:
	for k: int in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)


func _add_pad_button(action: String, btn: int) -> void:
	var ev := InputEventJoypadButton.new()
	ev.button_index = btn
	InputMap.action_add_event(action, ev)


func _add_pad_axis(action: String, axis: int, axis_sign: float) -> void:
	var ev := InputEventJoypadMotion.new()
	ev.axis = axis as JoyAxis
	ev.axis_value = axis_sign
	InputMap.action_add_event(action, ev)


# the redraws entities asked for during this frame's physics steps, made
# once (systems/redraw.gd); always, so a node that runs while paused draws too
func _process(_delta: float) -> void:
	Redraw.flush()


# How many physics steps one frame may run to catch up (the engine's default
# is 8). Each step costs time, so a slow frame that runs eight makes the next
# frame slower still, and a browser that dips never climbs back out. Four
# keeps full speed down to 15 fps; below that the walk runs a little slow
# rather than stalling. At 60 fps and in --fixed-fps runs it is one step.
const MAX_PHYSICS_STEPS := 4


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# The game's reading face, set before any Control exists. A Control looks
	# its font up in the engine's default theme, whose own default font
	# (Open Sans) comes before ThemeDB.fallback_font, so both are set: the
	# theme's for every Label and Button, the fallback for draw_string calls
	# that ask ThemeDB directly.
	var body := preload("res://hud/ui_kit.gd").body()
	ThemeDB.get_default_theme().default_font = body
	ThemeDB.fallback_font = body
	Engine.max_physics_steps_per_frame = MAX_PHYSICS_STEPS
	persist = not ("--autowalk" in OS.get_cmdline_user_args())
	load_records()
	# a screenshot shows this profile and never changes it, its --lang and the
	# like included (the window losing focus saves: main.on_app_paused)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shot"):
			persist = false
	# lets CI and local smoke tests exercise any level/weather:
	#   godot --headless --path . -- --level=park --weather=snow
	for arg in OS.get_cmdline_user_args():
		# --lang=ca|es|en: the glosses in that language for this run, unsaved
		if arg.begins_with("--lang=") and arg.substr(7) in LANGUAGES:
			language = arg.substr(7)
		# --text-size=normal|large: the UI scale preset for this run, unsaved
		if arg.begins_with("--text-size=") and arg.substr(12) in TEXT_SIZES:
			text_size = arg.substr(12)
		# --dog=NAME: walk that dog for this run, unsaved (screenshots, playtests)
		if arg.begins_with("--dog=") and arg.substr(6) in DOG_KEYS:
			dog = arg.substr(6)
		# --look=him|her|N: your human as the default him or her, or the NEW
		# LOOK the number seeds, for this run, unsaved (screenshots)
		if arg.begins_with("--look="):
			var lk := arg.substr(7)
			if lk == "him" or lk == "her":
				human_look = default_human(lk)
			elif lk.is_valid_int():
				var rng := RandomNumberGenerator.new()
				rng.seed = int(lk)
				randomize_human(rng)
		if arg.begins_with("--level="):
			var lv := arg.trim_prefix("--level=")
			# the tutorial too, so it can be shot and tested directly
			if lv in LEVELS or lv == "tutorial":
				level_id = lv
		elif arg.begins_with("--weather="):
			var w := arg.trim_prefix("--weather=")
			if w in SKIES:
				sky = w
				sky_from_args = true
		elif arg.begins_with("--hour="):
			var h := arg.trim_prefix("--hour=")
			if h in TIMES:
				time = h
				sky_from_args = true
		elif arg == "--night":
			# after dark, as the title's TIME toggle would set it - for
			# screenshots and the level review (#21)
			night = true
			sky_from_args = true
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
	key_binds = {}
	pad_binds = {}
	goals_expanded = false
	free_play = false
	screen_shake = true
	flashes = true
	text_size = "normal"
	ask_tutorial = true
	tutorial_done = false
	walks_lost = 0
	tips_seen = []
	agility_best = 0.0
	fresh_start = false
	dog_upgrades = {}
	training = {}
	finds_found = {}
	skills_done = {}
	achievements = []
	dogs_walked = []
	gallery_bones = []


func load_records() -> void:
	_reset_persisted_state()
	if not persist:
		return
	var cf := ConfigFile.new()
	if cf.load(save_path) != OK:
		return
	if int(cf.get_value("global", "save_version", 0)) < SAVE_VERSION:
		_start_fresh(cf)
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
	owned = {}
	for k in Array(cf.get_value("cosmetics", "owned", [])):
		owned[String(k)] = true
	# the freebies are always owned
	owned[ownership_id("collar", "red")] = true
	owned[ownership_id("bandana", "none")] = true
	owned[ownership_id("coat", "millie")] = true
	collar = cf.get_value("cosmetics", "collar", DEFAULT_COLLAR)
	bandana = cf.get_value("cosmetics", "bandana", DEFAULT_BANDANA)
	coat = cf.get_value("cosmetics", "coat", DEFAULT_COAT)
	dog = String(cf.get_value("player", "dog", DEFAULT_DOG))
	if not DOGS.has(dog):
		dog = DEFAULT_DOG
	dog_upgrades = Dictionary(cf.get_value("player", "dog_upgrades", {}))
	training = Dictionary(cf.get_value("player", "training", {}))
	finds_found = Dictionary(cf.get_value("player", "finds_found", {}))
	skills_done = Dictionary(cf.get_value("player", "skills_done", {}))
	human_look = valid_human(cf.get_value("player", "human", default_human("him")))
	vol_master = clampf(float(cf.get_value("settings", "vol_master", DEFAULT_VOL_MASTER)), 0.0, 1.0)
	vol_sfx = clampf(float(cf.get_value("settings", "vol_sfx", DEFAULT_VOL_SFX)), 0.0, 1.0)
	vol_music = clampf(float(cf.get_value("settings", "vol_music", DEFAULT_VOL_MUSIC)), 0.0, 1.0)
	fullscreen = bool(cf.get_value("settings", "fullscreen", false))
	language = String(cf.get_value("settings", "language", "en"))
	if not language in LANGUAGES:
		language = "en"
	var kb: Variant = cf.get_value("settings", "key_binds", {})
	key_binds = (kb as Dictionary).duplicate() if kb is Dictionary else {}
	var pb: Variant = cf.get_value("settings", "pad_binds", {})
	pad_binds = {}
	if pb is Dictionary:
		for k in (pb as Dictionary).keys():
			if String(k) in REBIND_ACTIONS and valid_pad_bind((pb as Dictionary)[k]):
				pad_binds[String(k)] = (pb as Dictionary)[k]
	goals_expanded = bool(cf.get_value("settings", "goals_expanded", false))
	free_play = bool(cf.get_value("settings", "free_play", false))
	screen_shake = bool(cf.get_value("settings", "screen_shake", true))
	flashes = bool(cf.get_value("settings", "flashes", true))
	text_size = String(cf.get_value("settings", "text_size", "normal"))
	if not text_size in TEXT_SIZES:
		text_size = "normal"
	ask_tutorial = bool(cf.get_value("settings", "ask_tutorial", true))
	tutorial_done = bool(cf.get_value("global", "tutorial_done", false))
	walks_lost = int(cf.get_value("global", "walks_lost", 0))
	tips_seen.assign(Array(cf.get_value("tips", "seen", PackedStringArray())))
	achievements.assign(Array(cf.get_value("achievements", "unlocked", PackedStringArray())))
	dogs_walked.assign(Array(cf.get_value("achievements", "dogs_walked", PackedStringArray())))
	gallery_bones.assign(Array(cf.get_value("achievements", "gallery_bones", PackedStringArray())))
	agility_best = maxf(0.0, float(cf.get_value("freedom", "agility_best", 0.0)))
	# a dog saved while only browsed (locked) is not the player's dog; checked
	# last, once the stars that unlock dogs are loaded
	if not is_dog_unlocked(dog):
		dog = DEFAULT_DOG
	for dk in dog_upgrades.keys():
		var ups = dog_upgrades[dk]
		if not ups is Dictionary:
			dog_upgrades.erase(dk)
			continue
		for st in (ups as Dictionary).keys():
			ups[st] = clampi(int(ups[st]), 0, MAX_STAT_POINTS - innate_stat(String(dk), String(st)))
	apply_control_layout()
	if is_inside_tree():
		var tree := get_tree()
		var cur := tree.current_scene if tree != null else null
		if cur != null and cur.is_node_ready() and cur.has_method("_apply_ui_scale"):
			cur._apply_ui_scale()


# What is left of a save from before the campaign: the player's settings, and
# nothing that was earned. A save with nothing in it but settings is no loss,
# so it says nothing.
func _start_fresh(cf: ConfigFile) -> void:
	for section: String in cf.get_sections():
		if section != "settings":
			fresh_start = fresh_start or section == "global" or LEVELS.has(section)
			cf.erase_section(section)
	for k: String in FRESH_SETTINGS:
		if cf.has_section_key("settings", k):
			cf.erase_section_key("settings", k)


# where a save set aside by _start_fresh is kept
func old_save_path() -> String:
	return save_path.get_basename() + "_before_campaign." + save_path.get_extension()


func save_records() -> void:
	if not persist:
		return
	if fresh_start:
		# the first save since: the old file is kept beside the new one, once
		if FileAccess.file_exists(save_path) and not FileAccess.file_exists(old_save_path()):
			DirAccess.copy_absolute(save_path, old_save_path())
		fresh_start = false
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
	cf.set_value("player", "dog_upgrades", dog_upgrades)
	cf.set_value("player", "training", training)
	cf.set_value("player", "finds_found", finds_found)
	cf.set_value("player", "skills_done", skills_done)
	cf.set_value("player", "human", human_look)
	cf.set_value("settings", "vol_master", vol_master)
	cf.set_value("settings", "vol_sfx", vol_sfx)
	cf.set_value("settings", "vol_music", vol_music)
	cf.set_value("settings", "fullscreen", fullscreen)
	cf.set_value("settings", "language", language)
	cf.set_value("settings", "key_binds", key_binds)
	cf.set_value("settings", "pad_binds", pad_binds)
	cf.set_value("settings", "goals_expanded", goals_expanded)
	cf.set_value("settings", "free_play", free_play)
	cf.set_value("settings", "screen_shake", screen_shake)
	cf.set_value("settings", "flashes", flashes)
	cf.set_value("settings", "text_size", text_size)
	cf.set_value("settings", "ask_tutorial", ask_tutorial)
	cf.set_value("global", "tutorial_done", tutorial_done)
	cf.set_value("global", "walks_lost", walks_lost)
	cf.set_value("tips", "seen", PackedStringArray(tips_seen))
	cf.set_value("achievements", "unlocked", PackedStringArray(achievements))
	cf.set_value("achievements", "dogs_walked", PackedStringArray(dogs_walked))
	cf.set_value("achievements", "gallery_bones", PackedStringArray(gallery_bones))
	cf.set_value("freedom", "agility_best", agility_best)
	cf.set_value("global", "save_version", SAVE_VERSION)
	cf.save(save_path)


func has_achievement(id: String) -> bool:
	return achievements.has(id)


# goals are the Tony Hawk-style per-level objective list: completing one
# on any run marks it done for that level forever. Three milestones of
# completed goals earn the three stars that gate the next walk.
const STAR_MILESTONES := [3, 6, 9]


func goal_done(lv: String, id: String) -> bool:
	return records.has(lv) and (records[lv].get("goals", []) as Array).has(id)


# Only goals the walk still has count: a save keeps the ids of goals a later
# version retired (El Barri's "hi" and the like), and those must not inflate
# the totals. Stars already banked from them stay banked (stars()).
func goals_count(lv: String) -> int:
	if not records.has(lv):
		return 0
	if _goal_ids.is_empty():
		_goal_ids = load("res://systems/goals.gd").LEVEL_GOAL_IDS
	var current: Array = _goal_ids.get(lv, [])
	var n := 0
	for id in records[lv].get("goals", []):
		if current.is_empty() or current.has(String(id)):
			n += 1
	return n


var _goal_ids: Dictionary = {}


func mark_goal(lv: String, id: String) -> bool:
	if not recording(lv):
		return false
	var record := _ensure_level_record(lv)
	var gl: Array = record.get("goals", [])
	if gl.has(id):
		return false
	gl.append(id)
	record["goals"] = gl
	# keep the stored star floor in step with the milestones reached
	record["stars"] = maxi(int(record.get("stars", 0)), _milestone_stars(goals_count(lv)))
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
	if not recording(lv) or style <= 0:
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
	if not recording(lv):
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
	return gate > prev_total and gate <= total_stars() and is_unlocked(lv)


func best_line(lv: String) -> String:
	var ch := chase_gate_needed(lv)
	if ch != "":
		return "locked - finish %s first" % LEVEL_NAMES.get(ch, ch)
	if not is_unlocked(lv):
		return "locked - earn %d stars to unlock" % int(STAR_GATE.get(lv, 0))
	if not records.has(lv) or int(records[lv].bones) <= 0:
		return "no record on this walk yet"
	var s := "best: %d bones in %ds   %s" % [int(records[lv].bones), int(records[lv].time), star_str(stars(lv))]
	return s


func star_str(n: int) -> String:
	return "*".repeat(n) + "-".repeat(maxi(0, 3 - n))


# The campaign's chapters, for the walk select: the carousel cut after each
# boss walk, so every chapter ends on a boss. Until every boss is in, the
# longest run between bosses is halved until there are CHAPTERS of them (the
# five chapter achievements), so adding a walk never makes a sixth chapter.
# Derived, so it follows the carousel's order.
const BOSS_WALKS: Array[String] = ["ciutadella", "guell", "port", "girona", "raval"]
const CHASE_WALKS: Array[String] = ["neteja", "besos", "vet", "boars", "gracia", "cremada", "aeroport", "molina",
	"atraccions", "montserrat"]
const CHAPTERS := 5
# the longest a chapter may run; a guard, held by tests/test_chapters.gd
const CHAPTER_MAX := 16


func chapters() -> Array:
	return chapters_of(CAROUSEL)


# the chapters a carousel in this order would make
func chapters_of(carousel: Array) -> Array:
	var out: Array = []
	var run: Array = []
	for lv: String in carousel:
		run.append(lv)
		if lv in BOSS_WALKS:
			out.append(run)
			run = []
	if not run.is_empty():
		out.append(run)
	while out.size() < CHAPTERS:
		var longest := 0
		for i in range(out.size()):
			if (out[i] as Array).size() > (out[longest] as Array).size():
				longest = i
		var whole: Array = out[longest]
		if whole.size() < 2:
			break
		var half := ceili(float(whole.size()) / 2.0)
		out[longest] = whole.slice(0, half)
		out.insert(longest + 1, whole.slice(half))
	return out


func chapter_index(lv: String) -> int:
	var chs := chapters()
	for i in range(chs.size()):
		if lv in (chs[i] as Array):
			return i
	return 0


# Jump the walk select to the next or previous chapter, landing on the
# furthest walk the player has open in it (where they are headed), or its
# first walk when none is open yet.
func cycle_chapter(dir: int) -> void:
	var chs := chapters()
	var walks: Array = chs[wrapi(chapter_index(level_id) + dir, 0, chs.size())]
	var pick: String = walks[0]
	for lv: String in walks:
		if is_unlocked(lv):
			pick = lv
	level_id = pick


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
