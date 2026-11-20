extends SceneTree

# The campaign's chapters (Game.chapters, the walk select and YOUR WALKS):
# they cover the carousel exactly once and in its order, every boss walk ends
# a chapter, there are always CHAPTERS of them, none runs longer than
# CHAPTER_MAX, and paging a chapter at
# a time comes back round to where it started.

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		printerr("FAIL: ", what)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game = root.get_node("Game")
	game.persist = false
	var chs: Array = game.chapters()
	var flat: Array = []
	for ch: Array in chs:
		flat.append_array(ch)
		_check(ch.size() <= game.CHAPTER_MAX, "a chapter of %d walks is no longer than %d" % [ch.size(), game.CHAPTER_MAX])
		_check(not ch.is_empty(), "no chapter is empty")
	_check(flat == Array(game.CAROUSEL), "the chapters are the carousel, once each, in order")
	for boss: String in game.BOSS_WALKS:
		if not boss in game.CAROUSEL:
			continue
		var i := game.chapter_index(boss) as int
		var ch: Array = chs[i]
		_check(String(ch[ch.size() - 1]) == boss, "%s ends its chapter" % boss)
	for lv: String in game.CHASE_WALKS:
		_check(lv in game.CAROUSEL, "chase walk %s is in the carousel" % lv)
	_check(chs.size() == game.CHAPTERS, "the campaign is %d chapters (%d)" % [game.CHAPTERS, chs.size()])
	# a walk added to the last run between bosses never makes a sixth chapter
	var more: Array = Array(game.CAROUSEL).duplicate()
	for extra in ["x1", "x2", "x3", "x4"]:
		more.insert(more.size() - 1, extra)
		_check(game.chapters_of(more).size() == game.CHAPTERS, "with %d walks, still %d chapters" % [more.size(), game.CHAPTERS])
	_check(game.chapters_of(Array(game.CAROUSEL)) == chs, "chapters() is chapters_of the carousel")
	# paging: down a chapter at a time all the way round lands back home
	game.level_id = "barri"
	var start := game.chapter_index("barri") as int
	var seen := {}
	for k in range(chs.size()):
		game.cycle_chapter(1)
		seen[game.chapter_index(game.level_id)] = true
	_check(game.chapter_index(game.level_id) == start, "paging through every chapter comes back to the first")
	_check(seen.size() == chs.size(), "paging visits every chapter")
	game.cycle_chapter(-1)
	_check(game.chapter_index(game.level_id) == wrapi(start - 1, 0, chs.size()), "paging back goes to the last chapter")

	print("test_chapters: %d checks, %d FAILED" % [checks, failures.size()])
	if failures.is_empty():
		print("OK")
	quit(0 if failures.is_empty() else 1)
