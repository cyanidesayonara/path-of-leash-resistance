extends Node

# Autoload: session state that must survive scene reloads.

const LEVELS: Array[String] = ["street", "park", "beach", "market"]
const LEVEL_NAMES := {
	"street": "The Boulevard", "park": "The Park",
	"beach": "Passeig Maritim", "market": "El Mercat",
}

const SAVE_PATH := "user://records.cfg"

var level_id := "street"
var owner_id := "him"  # "him" | "her"; a proper character creator can come later
var night := false
# which title-menu step to land on (survives the level-cycle reload;
# after a first run the splash is skipped straight to walk select)
var menu_step := 0
# local records per level + the lifetime wallet (the foundation that
# cosmetics, breeds and leaderboards will eventually stand on)
var records := {}
var total_bones := 0


func toggle_owner() -> void:
	owner_id = "her" if owner_id == "him" else "him"


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
		}
	total_bones = int(cf.get_value("global", "total_bones", 0))


func save_records() -> void:
	var cf := ConfigFile.new()
	for lv in records:
		cf.set_value(lv, "bones", records[lv].bones)
		cf.set_value(lv, "time", records[lv].time)
		cf.set_value(lv, "perfects", records[lv].perfects)
	cf.set_value("global", "total_bones", total_bones)
	cf.save(SAVE_PATH)


func record_result(lv: String, bones: int, time: float, perfect: bool) -> Dictionary:
	var r: Dictionary = records.get(lv, {"bones": 0, "time": 0.0, "perfects": 0})
	var out := {"bones_record": false, "time_record": false}
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


func best_line(lv: String) -> String:
	if not records.has(lv) or int(records[lv].bones) <= 0:
		return "no record on this walk yet"
	var s := "best: %d bones in %ds" % [int(records[lv].bones), int(records[lv].time)]
	if int(records[lv].perfects) > 0:
		s += "   perfect walks: %d" % int(records[lv].perfects)
	return s


func cycle_level(dir: int) -> void:
	var i := LEVELS.find(level_id)
	level_id = LEVELS[wrapi(i + dir, 0, LEVELS.size())]
