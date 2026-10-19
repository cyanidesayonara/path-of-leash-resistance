extends SceneTree

# Dia de Partit stays generic (docs/superpowers/specs/2026-10-17-dia-de-partit-design.md).
# The walk's scripts may not name a real club, its nicknames, its stadium,
# a shirt sponsor, a player, or the real motto. An invented line is fine.

const SOURCES := [
	"res://systems/partit.gd",
	"res://systems/march.gd",
	"res://systems/match_day.gd",
	"res://systems/kickabout.gd",
	"res://systems/lost_scarf.gd",
	"res://systems/crowd_river.gd",
]
const DENIED := [
	"barça", "fc barcelona", "camp nou", "spotify",
	"espanyol", "perico", "blaugrana", "culer", "culé",
	"més que un club", "mes que un club", "visca el bar",
	"rakuten", "qatar", "unicef",
	"messi", "yamal", "pedri", "lewandowski",
]

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	var planted := _hit("the stand sings mes que un club tonight")
	_check(planted != "", "a planted motto is caught (%s)" % planted)
	_check(_hit("FINS AL FINAL, and LES CORTS CANTA") == "", "the invented banners are allowed")
	for path: String in SOURCES:
		var text := FileAccess.get_file_as_string(path).to_lower()
		var hit := _hit(text)
		_check(hit == "", "%s names nothing real (%s)" % [path.get_file(), hit])
	print("test_partit_branding: %d checks, %d failures" % [checks, failures.size()])
	quit(1 if failures.size() > 0 else 0)


func _hit(text: String) -> String:
	var lower := text.to_lower()
	for phrase: String in DENIED:
		if phrase in lower:
			return phrase
	return ""
