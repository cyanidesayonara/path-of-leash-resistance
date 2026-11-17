extends SceneTree

# The website's colours are generated from the game's palette
# (tools/site_palette.gd from hud/ui_kit.gd). The committed site/palette.css
# must be what the tool writes now, and site/style.css must take every colour
# from it rather than spell one out.

const SitePalette := preload("res://tools/site_palette.gd")

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	var have := FileAccess.get_file_as_string("res://site/palette.css")
	_check(have == SitePalette.css(),
		"site/palette.css is stale: run tools/site_palette.gd and commit it")
	var style := FileAccess.get_file_as_string("res://site/style.css")
	_check(not style.is_empty(), "site/style.css reads")
	var hex := RegEx.create_from_string("#[0-9a-fA-F]{3,8}\\b")
	var found := hex.search_all(style)
	var spelled: Array[String] = []
	for m in found:
		spelled.append(m.get_string())
	_check(spelled.is_empty(), "site/style.css spells colours out: %s" % [spelled])
	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_site_palette: OK")
		quit(0)
	else:
		quit(1)
