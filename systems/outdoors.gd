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


# Dry, and the sun high enough to lie in.
static func fair(weather: String, hour: String) -> bool:
	return (weather == "clear" or weather == "wind") and (hour == "day" or hour == "dusk")


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


# A busker plays when it is dry; in rain or snow they stand it out under an
# umbrella instead.
static func busking(weather: String, _hour: String) -> bool:
	return weather == "clear" or weather == "wind"


# A street cafe parasol stays up in the rain (that is what it is for) but is
# furled at night and under snow.
static func terrace_parasols(weather: String, hour: String) -> bool:
	return hour != "night" and weather != "snow"


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
