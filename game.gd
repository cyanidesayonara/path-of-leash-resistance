extends Node

# Autoload: session state that must survive scene reloads.

const LEVELS: Array[String] = ["street", "park", "beach", "rain", "market", "oldtown", "trail", "station", "site"]
const LEVEL_NAMES := {
	"daily": "Daily Walk",
	"street": "The Boulevard", "park": "The Park",
	"beach": "Passeig Maritim", "rain": "El Aguacero", "market": "El Mercat",
	"oldtown": "El Gotic", "trail": "El Bosc", "station": "L'Estacio", "site": "Les Obres",
}
# Tony Hawk-style gating: total stars earned so far unlocks the next
# walk. The first is always open; each subsequent walk asks a little more.
const STAR_GATE := {"street": 0, "park": 2, "beach": 4, "rain": 5, "market": 7, "oldtown": 9, "trail": 11, "station": 13, "site": 15}

const WEATHERS: Array[String] = ["clear", "rain", "wind", "snow"]
const WEATHER_NAMES := {"clear": "CLEAR", "rain": "RAIN", "wind": "WIND", "snow": "SNOW"}

# the carousel on the title: the daily walk first, then the campaign walks
const CAROUSEL: Array[String] = ["daily", "street", "park", "beach", "rain", "market", "oldtown", "trail", "station", "site"]

# cosmetics: collars (recolour Millie's collar/harness) and bandanas.
# "none" is free and always owned; the rest cost bones once, then equip.
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

const SAVE_PATH := "user://records.cfg"

var level_id := "street"
var owner_id := "him"  # "him" | "her"; a proper character creator can come later
var night := false
var weather := "clear"
var daily := false
# which title-menu step to land on (survives the level-cycle reload;
# after a first run the splash is skipped straight to walk select)
var menu_step := 0
# local records per level + the spendable bones wallet
var records := {}
var total_bones := 0
# cosmetics
var owned := {"red": true, "none": true}
var collar := "red"
var bandana := "none"


func daily_seed() -> int:
	var d := Time.get_date_dict_from_system()
	return int(d.year) * 1000 + int(d.month) * 40 + int(d.day)


func daily_level() -> String:
	return LEVELS[daily_seed() % LEVELS.size()]


func daily_weather() -> String:
	return WEATHERS[(daily_seed() / 3) % WEATHERS.size()]


func daily_night() -> bool:
	return (daily_seed() / 7) % 3 == 0


func collar_color() -> Color:
	return COLLARS[collar].col if COLLARS.has(collar) else COLLARS["red"].col


func buy(item: String) -> bool:
	var cost := _cost(item)
	if owned.get(item, false) or total_bones < cost:
		return false
	total_bones -= cost
	owned[item] = true
	save_records()
	return true


func _cost(item: String) -> int:
	if COLLARS.has(item):
		return int(COLLARS[item].cost)
	if BANDANAS.has(item):
		return int(BANDANAS[item].cost)
	return 0


func toggle_owner() -> void:
	owner_id = "her" if owner_id == "him" else "him"


func cycle_weather(dir: int) -> void:
	var i := WEATHERS.find(weather)
	weather = WEATHERS[wrapi(i + dir, 0, WEATHERS.size())]


func _ready() -> void:
	load_records()
	# the daily best is per-day: wipe it when the date rolls over
	if records.has("daily") and int(records["daily"].get("seed", 0)) != daily_seed():
		records.erase("daily")
	# lets CI and local smoke tests exercise any level/weather:
	#   godot --headless --path . -- --level=park --weather=snow [--daily]
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--level="):
			var lv := arg.trim_prefix("--level=")
			if lv in LEVELS:
				level_id = lv
		elif arg.begins_with("--weather="):
			var w := arg.trim_prefix("--weather=")
			if w in WEATHERS:
				weather = w
		elif arg == "--daily":
			level_id = "daily"


func load_records() -> void:
	var cf := ConfigFile.new()
	if cf.load(SAVE_PATH) != OK:
		return
	for lv in LEVELS:
		var gl: Array = cf.get_value(lv, "goals", [])
		records[lv] = {
			"bones": int(cf.get_value(lv, "bones", 0)),
			"time": float(cf.get_value(lv, "time", 0.0)),
			"perfects": int(cf.get_value(lv, "perfects", 0)),
			"stars": int(cf.get_value(lv, "stars", 0)),
			"goals": gl,
		}
	total_bones = int(cf.get_value("global", "total_bones", 0))
	if cf.has_section("daily"):
		records["daily"] = {"bones": int(cf.get_value("daily", "bones", 0)), "seed": int(cf.get_value("daily", "seed", 0))}
	var ol: Array = cf.get_value("cosmetics", "owned", ["red", "none"])
	owned = {}
	for k in ol:
		owned[k] = true
	owned["red"] = true
	owned["none"] = true
	collar = cf.get_value("cosmetics", "collar", "red")
	bandana = cf.get_value("cosmetics", "bandana", "none")


func save_records() -> void:
	var cf := ConfigFile.new()
	for lv in LEVELS:
		if not records.has(lv):
			continue
		cf.set_value(lv, "bones", records[lv].bones)
		cf.set_value(lv, "time", records[lv].time)
		cf.set_value(lv, "perfects", records[lv].perfects)
		cf.set_value(lv, "stars", records[lv].get("stars", 0))
		cf.set_value(lv, "goals", records[lv].get("goals", []))
	if records.has("daily"):
		cf.set_value("daily", "bones", records["daily"].bones)
		cf.set_value("daily", "seed", records["daily"].get("seed", 0))
	cf.set_value("global", "total_bones", total_bones)
	cf.set_value("cosmetics", "owned", owned.keys())
	cf.set_value("cosmetics", "collar", collar)
	cf.set_value("cosmetics", "bandana", bandana)
	cf.save(SAVE_PATH)


# goals are the Tony Hawk-style per-level objective list: completing one
# on any run marks it done for that level forever. Three milestones of
# completed goals earn the three stars that gate the next walk.
const STAR_MILESTONES := [3, 6, 9]


func goal_done(lv: String, id: String) -> bool:
	return records.has(lv) and (records[lv].get("goals", []) as Array).has(id)


func goals_count(lv: String) -> int:
	return (records[lv].get("goals", []) as Array).size() if records.has(lv) else 0


func mark_goal(lv: String, id: String) -> bool:
	if not records.has(lv) or lv == "daily":
		return false
	var gl: Array = records[lv].get("goals", [])
	if gl.has(id):
		return false
	gl.append(id)
	records[lv]["goals"] = gl
	# keep the stored star floor in step with the milestones reached
	records[lv]["stars"] = maxi(int(records[lv].get("stars", 0)), _milestone_stars(gl.size()))
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


func is_unlocked(lv: String) -> bool:
	if lv == "daily":
		return true  # the daily is always open
	return total_stars() >= int(STAR_GATE.get(lv, 0))


func record_result(lv: String, bones: int, time: float, perfect: bool) -> Dictionary:
	# stars/unlocks now come from goals (marked live during the run); this
	# only records the best-bones/time/perfect tallies and banks bones.
	var out := {"bones_record": false, "time_record": false}
	if lv == "daily":
		var dr: Dictionary = records.get("daily", {"bones": 0, "seed": daily_seed()})
		if bones > int(dr.bones):
			dr.bones = bones
			out.bones_record = true
		dr.seed = daily_seed()
		records["daily"] = dr
		total_bones += bones
		save_records()
		return out
	var r: Dictionary = records.get(lv, {"bones": 0, "time": 0.0, "perfects": 0, "stars": 0, "goals": []})
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
	if lv == "daily":
		var todays := "%s, %s%s" % [LEVEL_NAMES[daily_level()], WEATHER_NAMES[daily_weather()].to_lower(), ", night" if daily_night() else ""]
		if records.has("daily") and int(records["daily"].bones) > 0:
			return "today: %s   -   your best: %d bones" % [todays, int(records["daily"].bones)]
		return "today: %s   -   one shot, new each day" % todays
	if not is_unlocked(lv):
		return "locked - earn %d stars to unlock" % int(STAR_GATE.get(lv, 0))
	if not records.has(lv) or int(records[lv].bones) <= 0:
		return "no record on this walk yet"
	var s := "best: %d bones in %ds   %s" % [int(records[lv].bones), int(records[lv].time), star_str(stars(lv))]
	return s


func star_str(n: int) -> String:
	return "*".repeat(n) + "-".repeat(maxi(0, 3 - n))


func cycle_level(dir: int) -> void:
	# cycle the carousel (daily + campaign walks); locked ones show but
	# cannot be started
	var i := CAROUSEL.find(level_id)
	if i < 0:
		i = 1
	level_id = CAROUSEL[wrapi(i + dir, 0, CAROUSEL.size())]


func is_daily(lv: String) -> bool:
	return lv == "daily"
