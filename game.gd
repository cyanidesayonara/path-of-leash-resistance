extends Node

# Autoload: session state that must survive scene reloads.

const LEVELS: Array[String] = ["street", "park", "beach"]
const LEVEL_NAMES := {"street": "The Boulevard", "park": "The Park", "beach": "Passeig Maritim"}

var level_id := "street"
var owner_id := "him"  # "him" | "her"; a proper character creator can come later


func toggle_owner() -> void:
	owner_id = "her" if owner_id == "him" else "him"


func _ready() -> void:
	# lets CI and local smoke tests exercise any level:
	#   godot --headless --path . -- --level=park
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--level="):
			var lv := arg.trim_prefix("--level=")
			if lv in LEVELS:
				level_id = lv


func cycle_level(dir: int) -> void:
	var i := LEVELS.find(level_id)
	level_id = LEVELS[wrapi(i + dir, 0, LEVELS.size())]
