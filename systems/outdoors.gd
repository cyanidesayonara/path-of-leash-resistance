extends RefCounted

# Who is out in this weather and at this hour. One rule per KIND of passer-by
# or prop, read where that kind is spawned or drawn, never a rule per walk: a
# beach at dawn, at noon, in the rain and under snow is four different walks
# because different people are on it.
#
# Pure functions of the weather and the hour (Game.weather, Game.hour), so a
# walk's sky decides its crowd. Nothing here draws from an RNG: a spawner
# makes its usual draws and then asks whether this kind is out, so a seeded
# walk in its own sky replays as it did.
#
# Kinds with no rule here (other dog walkers, commuters, stall keepers, a
# walk's own characters and live events) are out in every sky: people walk
# their dogs and go to work whatever the weather. Their clothes follow the
# weather already (HumanLook.outfit).

# How many of the usual crowd are out, by hour and by weather; multiplied.
# A clear day is the crowd each walk was built with.
const CROWD_HOUR := {"dawn": 0.35, "day": 1.0, "dusk": 0.85, "night": 0.6}
const CROWD_WEATHER := {"clear": 1.0, "wind": 0.85, "rain": 0.5, "snow": 0.45}
# How long between other dog walkers, as a factor on each walk's own gap.
# First light and late evening are the dog walkers' hours; a downpour keeps
# them short.
const PAIR_GAP_HOUR := {"dawn": 0.7, "day": 1.0, "dusk": 0.9, "night": 0.85}
const PAIR_GAP_WEATHER := {"clear": 1.0, "wind": 1.0, "rain": 1.3, "snow": 1.2}


# Dry, and the sun high enough to lie in. A fog (Game.fog_amount, the sky's
# strength beyond its kind) is no day for the beach either, and nor is a
# calima (Game.dust_amount): a bad-air day keeps them in as rain does.
static func fair(weather: String, hour: String) -> bool:
	return (weather == "clear" or weather == "wind") and (hour == "day" or hour == "dusk") \
		and Game.fog_amount() < 0.5 and Game.dust_amount() < 0.5


# Sunbathers and the towels they lie on, the beach parasols up over them,
# picnics on the grass, the ice-cream cart open, and kids out on scooters:
# fair weather by day.
static func sunbathers(weather: String, hour: String) -> bool:
	return fair(weather, hour)


static func picnics(weather: String, hour: String) -> bool:
	return fair(weather, hour)


static func icecream_open(weather: String, hour: String) -> bool:
	return fair(weather, hour)


static func kids_riding(weather: String, hour: String) -> bool:
	return fair(weather, hour)


# Rollerbladers are out for their exercise in the early light too, but not on
# a wet or frozen lane, and not in the dark.
static func skating(weather: String, hour: String) -> bool:
	return (weather == "clear" or weather == "wind") and hour != "night"


# Whether a rider of this kind ("bike", "roller", "kid") is out. Commuters
# ride in any sky.
static func riding(kind: String, weather: String, hour: String) -> bool:
	match kind:
		"roller": return skating(weather, hour)
		"kid": return kids_riding(weather, hour)
	return true


# Whether a rider of this kind and style (entities/bike.gd) is out. Couriers,
# city bikes and Bicing ride in any sky: deliveries go out in a downpour, and
# that is when there are most of them. Road cyclists and mountain bikers ride
# for the sport of it, so in the dry and the light; electric scooters stay in
# under snow; a parent takes the pram out by day.
static func rider_out(kind: String, style: String, weather: String, hour: String) -> bool:
	if not riding(kind, weather, hour):
		return false
	var dry := weather == "clear" or weather == "wind"
	match style:
		"road": return dry and hour != "night"
		"mtb": return weather != "snow" and hour != "night"
		"escooter": return weather != "snow"
		"pram": return hour != "night"
	return true


# A busker plays when it is dry; in rain or snow they stand it out under an
# umbrella instead.
static func busking(weather: String, _hour: String) -> bool:
	return weather == "clear" or weather == "wind"


# Underground (El Metro) the weather stops at the stairs. The busker in the
# passage plays in any weather, under cover, but has gone home after dark.
static func underground_busker(_weather: String, hour: String) -> bool:
	return hour != "night"


# People shaking out their umbrellas as they come down out of it, and the
# wet footprints they track in: only when it is raining or snowing.
static func umbrella_shakers(weather: String, _hour: String) -> bool:
	return weather == "rain" or weather == "snow"


static func tracks_wet(weather: String) -> bool:
	return weather == "rain" or weather == "snow"


# The metro's commuters: thinned by the hour like any crowd, but never by
# the weather, because rain drives people down into it. `n` is a day's
# crowd; at least two are always about.
static func underground_crowd(n: int, _weather: String, hour: String) -> int:
	return maxi(2, roundi(float(n) * float(CROWD_HOUR.get(hour, 1.0))))


# A traca or any other string of fireworks is hung out only when it is dry:
# nobody lights wet fuses.
static func fireworks(weather: String, _hour: String) -> bool:
	return weather == "clear" or weather == "wind"


# A street cafe parasol stays up in the rain (that is what it is for) but is
# furled at night and under snow.
static func terrace_parasols(weather: String, hour: String) -> bool:
	return hour != "night" and weather != "snow"


# Street sellers with wares on a sheet come out after dark, and only when it
# is dry.
static func street_sellers(weather: String, hour: String) -> bool:
	return (weather == "clear" or weather == "wind") and hour == "night"


# People sit out at a cafe or bar terrace at any hour it is dry; in rain or
# snow the tables stand empty.
static func terrace_patrons(weather: String, _hour: String) -> bool:
	return weather == "clear" or weather == "wind"


# A busker draws a little crowd when busking, though not at first light.
static func busker_onlookers(weather: String, hour: String) -> bool:
	return busking(weather, hour) and hour != "dawn"


# A pintxos street's terraces (Carrer de Blai): the share of the chairs out
# on the paving with someone in them. Full after dark, which is when the
# street lives; a lunchtime vermut by day; an early coffee or two at first
# light. Nobody sits out in rain or snow: the chairs stay, empty and wet.
const TERRACE_FILL := {"dawn": 0.15, "day": 0.45, "dusk": 0.8, "night": 1.0}


static func terrace_diners(weather: String, hour: String) -> float:
	if weather == "rain" or weather == "snow":
		return 0.0
	return float(TERRACE_FILL.get(hour, 0.5))


# The groups standing in the street with a drink: an evening thing, out
# from dusk in the dry. In rain or snow they stand it out in the bar
# doorways instead, at any hour (standers_in_doorways).
static func standers_out(weather: String, hour: String) -> bool:
	if weather == "rain" or weather == "snow":
		return true
	return hour == "dusk" or hour == "night"


static func standers_in_doorways(weather: String, _hour: String) -> bool:
	return weather == "rain" or weather == "snow"


# The share of a bar street's fronts with the shutter down: most of them
# first thing, about half through the day, none once the evening starts.
const SHUTTER_SHARE := {"dawn": 0.85, "day": 0.45, "dusk": 0.1, "night": 0.0}


static func bar_shutters(_weather: String, hour: String) -> float:
	return float(SHUTTER_SHARE.get(hour, 0.0))


# Kegs and crates stacked by a bar's door on a hand truck: the morning
# deliveries, rain or shine, and never after dark.
static func deliveries(_weather: String, hour: String) -> bool:
	return hour == "dawn" or hour == "day"


# The share of a walk's usual crowd (tourists, people browsing at a stall)
# that is out, against a clear day.
static func crowd_share(weather: String, hour: String) -> float:
	return float(CROWD_HOUR.get(hour, 1.0)) * float(CROWD_WEATHER.get(weather, 1.0))


# The share out on THIS walk: each walk's crowd was built for its own
# campaign sky (La Castanyada's market is busy after dark because that is
# when the festival is), so its own sky keeps the crowd it was built with
# and only another sky thins it. Never more than the built crowd.
static func walk_share(weather: String, hour: String, campaign: Array) -> float:
	var built := 1.0
	if campaign.size() >= 2:
		built = crowd_share(String(campaign[0]), String(campaign[1]))
	return minf(1.0, crowd_share(weather, hour) / maxf(built, 0.01))


# `n` of a walk's usual crowd, scaled by walk_share; at least `floor_n`.
static func crowd_count(n: int, weather: String, hour: String, campaign: Array, floor_n := 1) -> int:
	return maxi(floor_n, roundi(float(n) * walk_share(weather, hour, campaign)))


# crowd_count for the walk being played, in its current sky
static func crowd_here(n: int, floor_n := 1) -> int:
	return crowd_count(n, Game.weather, Game.hour, Game.CAMPAIGN_SKY.get(Game.level_id, []), floor_n)


static func pair_gap(weather: String, hour: String) -> float:
	return float(PAIR_GAP_HOUR.get(hour, 1.0)) * float(PAIR_GAP_WEATHER.get(weather, 1.0))


# A village street's mornings (Sarrià's, and any walk with the same people).
# The bakery is open and its bread crates are out from first light until it
# shuts for the night; in the rain they stand under the awning all the same.
static func bakery_open(_weather: String, hour: String) -> bool:
	return hour != "night"


# The shops roll their shutters up by day and keep them down at night, in
# any weather; so does the market.
static func shops_open(_weather: String, hour: String) -> bool:
	return hour != "night"


# The municipal sweepers work the early and the late shifts, rain or not.
static func street_sweeping(_weather: String, hour: String) -> bool:
	return hour == "dawn" or hour == "night"


# Joggers run in the dry and the light, from first light on.
static func jogging(weather: String, hour: String) -> bool:
	return (weather == "clear" or weather == "wind") and hour != "night"


# The balcony gardener is out on her balcony in the dry by daylight. In the
# rain or the snow she stays behind her balcony door, and at night behind
# her lit window; from either she still answers a dog's good morning.
static func gardener_on_balcony(weather: String, hour: String) -> bool:
	return (weather == "clear" or weather == "wind") and hour != "night"


# Balcony plants are watered in the cool of the morning or the evening, and
# never in the rain.
static func watering_plants(weather: String, hour: String) -> bool:
	return (weather == "clear" or weather == "wind") and (hour == "dawn" or hour == "dusk")


# Hospital garden benches (Sant Pau): visitors sitting out in dry weather,
# fullest at dusk and through the day; empty and wet in rain or snow.
const GARDEN_BENCH_FILL := {"dawn": 0.15, "day": 0.65, "dusk": 0.85, "night": 0.25}


static func garden_sitters(weather: String, hour: String) -> float:
	if weather == "rain" or weather == "snow":
		return 0.0
	return float(GARDEN_BENCH_FILL.get(hour, 0.5))


# Architecture sketchers and visitors admiring the pavilions: out in dry
# daylight and dusk, never in rain, snow, or after dark.
static func sketchers_out(weather: String, hour: String) -> bool:
	return (weather == "clear" or weather == "wind") and hour != "night"


# How hard the sea wind blows along an open promenade (Sitges): full gale in
# "wind", a light sea breeze on a clear day, gusts under rain.
const WIND_STRENGTH := {"wind": 1.0, "rain": 0.5, "clear": 0.3, "snow": 0.2}


static func wind_strength(weather: String) -> float:
	return float(WIND_STRENGTH.get(weather, 0.3))


# Seafront cafe and beach parasols stay open in fair calm weather, and are
# furled in strong wind so they do not blow away, as well as in rain, snow,
# a calima, at night, or at first light.
static func beach_parasols_open(weather: String, hour: String) -> bool:
	return weather == "clear" and (hour == "day" or hour == "dusk") and Game.wind_amount() < 0.5 \
		and Game.dust_amount() < 0.5


# Cafe napkins and loose papers lift and skitter across the promenade in wind.
static func blowing_napkins(weather: String, _hour: String) -> bool:
	return weather == "wind" or Game.wind_amount() >= 0.5


# Kitesurfing wings and wind banners are out on the sand in dry daylight.
static func kites_out(weather: String, hour: String) -> bool:
	return (weather == "wind" or weather == "clear") and hour != "night"


# Camí de Ronda: cove bathers only go down to the shingle on dry days or dusk;
# rain, snow and night keep the water empty.
static func coastal_bathers(weather: String, hour: String) -> bool:
	return (weather == "clear" or weather == "wind") and (hour == "day" or hour == "dusk")


# Coastal cliff-path hikers and lookout walkers (Camí de Ronda): steadier in
# clear daylight, fewer when the tramuntana blows hard, none in snow.
const COASTAL_HIKER_FILL := {"dawn": 0.25, "day": 0.75, "dusk": 0.55, "night": 0.15}


static func coastal_hikers(weather: String, hour: String) -> float:
	if weather == "rain" or weather == "snow":
		return 0.0
	var base := float(COASTAL_HIKER_FILL.get(hour, 0.4))
	return base * 0.65 if weather == "wind" else base


# Els Encants: flea-market browsers and sellers stay out under the canopy in
# rain (that is the point of the roof). Sunbathers and the ice-cream cart stay
# home; those rules already refuse rain. Fill is high by day, thinner at night.
const FLEA_BROWSER_FILL := {"dawn": 0.35, "day": 0.85, "dusk": 0.70, "night": 0.25}


static func flea_browsers(weather: String, hour: String) -> float:
	if weather == "snow":
		return 0.15
	return float(FLEA_BROWSER_FILL.get(hour, 0.5))


static func flea_sellers(_weather: String, hour: String) -> bool:
	return hour != "night"
# Town promenade benches at dusk (Tarragona Rambla): walkers sit out when dry.
const PROMENADE_SIT_FILL := {"dawn": 0.2, "day": 0.55, "dusk": 0.9, "night": 0.35}


static func promenade_sitters(weather: String, hour: String) -> float:
	if weather == "rain" or weather == "snow":
		return 0.0
	return float(PROMENADE_SIT_FILL.get(hour, 0.5))
