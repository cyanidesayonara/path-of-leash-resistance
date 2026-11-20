extends SceneTree

# Each dog is born with training levels in what she is bred for (Game.DOGS
# "innate"): they count toward the stat and its effect, cost nothing, and sit
# under the same cap, so a specialist has fewer levels left to train there.

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	create_timer(10.0).timeout.connect(func():
		print("FAIL: test watchdog timeout")
		quit(1)
	)
	call_deferred("_run")


func _run() -> void:
	var game: Node = root.get_node("Game")
	var saved_persist: bool = game.persist
	var saved_upgrades: Dictionary = game.dog_upgrades.duplicate(true)
	var saved_training: Dictionary = game.training.duplicate(true)
	var saved_records: Dictionary = game.records.duplicate(true)
	var saved_free_play: bool = game.free_play
	game.persist = false
	game.free_play = true
	game.dog_upgrades = {}
	game.training = {}

	# every dog has a head start, and every head start is in a real stat
	for d: String in game.DOG_KEYS:
		var inn: Dictionary = game.DOGS[d].get("innate", {})
		_check(not inn.is_empty(), "%s has a head start" % d)
		var total := 0
		for st: String in inn.keys():
			_check(st in game.STAT_NAMES, "%s's head start %s is a stat" % [d, st])
			total += int(inn[st])
		_check(total == 2, "%s is born with two levels in all (%d)" % [d, total])
	# what each is bred for
	_check(game.innate_stat("pipa", "speed") == 2, "Pipa is born fast")
	_check(game.innate_stat("mochi", "plant") == 2, "Mochi is born planted")
	_check(game.innate_stat("bruna", "herd") == 2, "Bruna is born herding")
	_check(game.innate_stat("tito", "agility") == 2, "Tito is born nimble")
	_check(game.innate_stat("millie", "nose") == 2, "Millie is born with a nose")

	# the head start counts toward the level and its effect
	_check(game.get_dog_stat("pipa", "speed") == 2, "Pipa's speed starts at level 2")
	_check(game.get_dog_stat("pipa", "plant") == 0, "Pipa's plant starts at 0")
	var base := float(game.DOGS["pipa"].get("speed_mult", 1.0))
	_check(is_equal_approx(game.dog_speed_mult("pipa"), base + 2.0 * 0.05), "her head start adds to her speed")

	# training goes on from it: the next level costs the level it reaches,
	# and the cap counts her head start
	_check(game.is_dog_unlocked("pipa"), "free play opens Pipa")
	if game.is_dog_unlocked("pipa"):
		game.training["pipa"] = 100
		_check(game.stat_cost("pipa", "speed") == 3, "her third speed level costs 3")
		_check(game.upgrade_dog_stat("pipa", "speed"), "she can train speed")
		_check(game.trained_stat("pipa", "speed") == 1, "one trained level is saved, not three")
		_check(game.get_dog_stat("pipa", "speed") == 3, "speed is now level 3")
		game.upgrade_dog_stat("pipa", "speed")
		game.upgrade_dog_stat("pipa", "speed")
		_check(game.get_dog_stat("pipa", "speed") == game.MAX_STAT_POINTS, "speed reaches the cap")
		_check(not game.upgrade_dog_stat("pipa", "speed"), "and not past it")
		_check(game.trained_stat("pipa", "speed") == game.MAX_STAT_POINTS - 2, "after three trained levels")

	game.dog_upgrades = saved_upgrades
	game.training = saved_training
	game.records = saved_records
	game.free_play = saved_free_play
	game.persist = saved_persist
	print("test_dog_head_starts: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
