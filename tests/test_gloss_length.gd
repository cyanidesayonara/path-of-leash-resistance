extends SceneTree

# A walk's gloss is a short line under its name, never a sentence that runs
# off the path: every walk has one in each language, at most Game.GLOSS_MAX
# characters in English and Game.GLOSS_MAX_LONG in Catalan and Spanish.

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game: Node = root.get_node("Game")
	var tables := {"en": [game.LEVEL_SUBTITLES, game.GLOSS_MAX], "ca": [game.LEVEL_SUBTITLES_CA, game.GLOSS_MAX_LONG],
		"es": [game.LEVEL_SUBTITLES_ES, game.GLOSS_MAX_LONG]}
	var walks: Array = Array(game.CAROUSEL)
	for lang: String in tables:
		var t: Dictionary = tables[lang][0]
		var cap: int = tables[lang][1]
		for lv: String in walks:
			var g := String(t.get(lv, ""))
			_check(g != "", "%s has a %s gloss" % [lv, lang])
			_check(g.length() <= cap, "%s's %s gloss fits in %d (%d): %s" % [lv, lang, cap, g.length(), g])
	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("OK")
	quit(0 if failures.is_empty() else 1)
