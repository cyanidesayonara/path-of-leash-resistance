extends Node

# Autoload: session state that must survive scene reloads.

const LEVELS: Array[String] = ["street", "park", "beach", "market"]
const LEVEL_NAMES := {
	"street": "The Boulevard", "park": "The Park",
	"beach": "Passeig Maritim", "market": "El Mercat",
}
# Tony Hawk-style gating: total stars earned so far unlocks the next
# walk. The first is always open; each subsequent walk asks a little more.
const STAR_GATE := {"street": 0, "park": 2, "beach": 4, "market": 7}

const WEATHERS: Array[String] = ["clear", "rain", "wind"]
const WEATHER_NAMES := {"clear": "CLEAR", "rain": "RAIN", "wind": "WIND"}

const SAVE_PATH := "user://records.cfg"

var level_id := "street"
var owner_id := "him"  # "him" | "her"; a proper character creator can come later
var night := false
var weather := "clear"
# which title-menu step to land on (survives the level-cycle reload;
# after a first run the splash is skipped straight to walk select)
var menu_step := 0
# local records per level + the lifetime wallet (the foundation that
# cosmetics, breeds and leaderboards will eventually stand on)
var records := {}
var total_bones := 0


func toggle_owner() -> void:
	owner_id = "her" if owner_id == "him" else "him"


func cycle_weather(dir: int) -> void:
	var i := WEATHERS.find(weather)
	weather = WEATHERS[wrapi(i + dir, 0, WEATHERS.size())]


func _ready() -> void:
	load_records()
	# lets CI and local smoke tests exercise any level:
	#   godot --headless --path . -- --level=park
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--level="):
			var lv := arg.trim_prefix("--level=")
			if lv in LEVELS:
				level_id = lv


func load_records() -> void:
	var cf := ConfigFile.new()
	if cf.load(SAVE_PATH) != OK:
		return
	for lv in LEVELS:
		records[lv] = {
			"bones": int(cf.get_value(lv, "bones", 0)),
			"time": float(cf.get_value(lv, "time", 0.0)),
			"perfects": int(cf.get_value(lv, "perfects", 0)),
			"stars": int(cf.get_value(lv, "stars", 0)),
		}
	total_bones = int(cf.get_value("global", "total_bones", 0))


func save_records() -> void:
	var cf := ConfigFile.new()
	for lv in records:
		cf.set_value(lv, "bones", records[lv].bones)
		cf.set_value(lv, "time", records[lv].time)
		cf.set_value(lv, "perfects", records[lv].perfects)
		cf.set_value(lv, "stars", records[lv].get("stars", 0))
	cf.set_value("global", "total_bones", total_bones)
	cf.save(SAVE_PATH)


func stars(lv: String) -> int:
	return int(records[lv].get("stars", 0)) if records.has(lv) else 0


func total_stars() -> int:
	var s := 0
	for lv in LEVELS:
		s += stars(lv)
	return s


func is_unlocked(lv: String) -> bool:
	return total_stars() >= int(STAR_GATE.get(lv, 0))


func record_result(lv: String, bones: int, time: float, perfect: bool, earned_stars: int) -> Dictionary:
	var r: Dictionary = records.get(lv, {"bones": 0, "time": 0.0, "perfects": 0, "stars": 0})
	var out := {"bones_record": false, "time_record": false, "new_stars": 0, "unlocked": ""}
	if bones > int(r.bones):
		r.bones = bones
		out.bones_record = true
	if float(r.time) <= 0.0 or time < float(r.time):
		r.time = time
		out.time_record = true
	if perfect:
		r.perfects = int(r.perfects) + 1
	# stars are a high-water mark per walk, never lost
	var before_total := total_stars()
	if earned_stars > int(r.get("stars", 0)):
		out.new_stars = earned_stars - int(r.get("stars", 0))
		r.stars = earned_stars
	records[lv] = r
	total_bones += bones
	save_records()
	# did this push us past a gate?
	var after_total := total_stars()
	for other in LEVELS:
		var gate := int(STAR_GATE.get(other, 0))
		if gate > before_total and gate <= after_total:
			out.unlocked = other
	return out


func best_line(lv: String) -> String:
	if not is_unlocked(lv):
		return "locked - earn %d stars to unlock" % int(STAR_GATE.get(lv, 0))
	if not records.has(lv) or int(records[lv].bones) <= 0:
		return "no record on this walk yet"
	var s := "best: %d bones in %ds   %s" % [int(records[lv].bones), int(records[lv].time), star_str(stars(lv))]
	return s


func star_str(n: int) -> String:
	return "*".repeat(n) + "-".repeat(maxi(0, 3 - n))


func cycle_level(dir: int) -> void:
	# cycle through all walks; locked ones are shown but cannot be started
	var i := LEVELS.find(level_id)
	level_id = LEVELS[wrapi(i + dir, 0, LEVELS.size())]
