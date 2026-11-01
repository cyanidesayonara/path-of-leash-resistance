extends SceneTree

# Your human's look (Game.human_look): the defaults, NEW LOOK giving a
# different person each time from the palettes, HIM / HER keeping the colours
# and swapping to the matching hair style, owner_id reading and setting who,
# a saved look surviving a reload and a malformed one falling back, and the
# films drawing your human in it (intro/kit.gd fills an uncoloured pose)
# while passers-by keep their own colours. GET READY offers NEW LOOK only on
# the YOUR HUMAN row.

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	create_timer(30.0).timeout.connect(func():
		print("FAIL: test watchdog timeout")
		quit(1)
	)
	call_deferred("_run")


func _run() -> void:
	var game: Node = root.get_node("Game")
	var keep_look: Dictionary = game.human_look.duplicate()
	var keep_path: String = game.save_path
	var keep_persist: bool = game.persist

	# the defaults
	var him: Dictionary = game.default_human("him")
	var her: Dictionary = game.default_human("her")
	_check(not bool(him.her) and bool(her.her), "default him and her are who they say")
	_check(String(him.hair_style) in game.HIS_HAIR, "his default style is one of his")
	_check(String(her.hair_style) in game.HER_HAIR, "her default style is one of hers")
	_check(him.shirt == HumanSide.SHIRT, "default him wears the films' blue shirt")

	# NEW LOOK: from the palettes, never the same twice in a row, both people
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	game.human_look = him.duplicate()
	var seen_her := false
	var seen_him := false
	var styles := {}
	for i in range(60):
		var was: Dictionary = game.human_look.duplicate()
		game.randomize_human(rng)
		var lk: Dictionary = game.human_look
		_check(lk != was, "new look %d differs from the last" % i)
		_check(lk.skin in game.HUMAN_SKINS and lk.hair in game.HUMAN_HAIRS and lk.shirt in game.HUMAN_SHIRTS
			and lk.trousers in game.HUMAN_TROUSERS and lk.shoe in game.HUMAN_SHOES, "new look %d from the palettes" % i)
		var mine: Array = game.HER_HAIR if bool(lk.her) else game.HIS_HAIR
		_check(String(lk.hair_style) in mine, "new look %d has a style that fits" % i)
		seen_her = seen_her or bool(lk.her)
		seen_him = seen_him or not bool(lk.her)
		styles[String(lk.hair_style)] = true
	_check(seen_her and seen_him, "new looks give both him and her")
	_check(styles.size() >= 6, "new looks give a spread of hair styles")

	# HIM / HER: the same colours, the matching style
	game.human_look = him.duplicate()
	game.human_look["shirt"] = game.HUMAN_SHIRTS[3]
	game.toggle_owner()
	_check(game.owner_id == "her", "toggling him gives her")
	_check(game.human_look.shirt == game.HUMAN_SHIRTS[3], "toggling keeps the shirt")
	_check(String(game.human_look.hair_style) in game.HER_HAIR, "toggling swaps to one of her styles")
	game.owner_id = "him"
	_check(game.owner_id == "him" and String(game.human_look.hair_style) in game.HIS_HAIR,
		"setting owner_id to him turns her back")
	game.owner_id = "him"
	_check(game.owner_id == "him", "setting the same owner changes nothing")

	# saved and loaded; a malformed save falls back key by key
	var path := "user://test_human_look.cfg"
	game.persist = true
	game.save_path = path
	rng.seed = 99
	game.randomize_human(rng)
	var saved: Dictionary = game.human_look.duplicate()
	game.save_records()
	game.human_look = him.duplicate()
	game.load_records()
	_check(game.human_look == saved, "a saved look loads back as it was")
	var cf := ConfigFile.new()
	cf.load(path)
	cf.set_value("player", "human", {"her": true, "skin": "pink", "hair_style": "mohawk"})
	cf.save(path)
	game.load_records()
	_check(bool(game.human_look.her), "a malformed look keeps who it was")
	_check(game.human_look.skin == her.skin, "a malformed colour falls back to the default")
	_check(String(game.human_look.hair_style) == String(her.hair_style), "an unknown style falls back")
	cf.set_value("player", "human", "nonsense")
	cf.save(path)
	game.load_records()
	_check(game.human_look == him, "a look that is not a dictionary loads as the default him")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	game.save_path = keep_path
	game.persist = keep_persist

	# the films draw your human in the look; a passer-by keeps their colours
	game.human_look = her.duplicate()
	var probe := Node2D.new()
	root.add_child(probe)
	var yours: Dictionary = IntroKit.dressed(probe, {"phone": 1.0})
	_check(yours.get("shirt") == her.shirt and yours.get("skin") == her.skin
		and yours.get("hair_style") == her.hair_style, "a film draws your human in the look")
	_check(bool(yours.get("lashes", false)), "her lashes are drawn")
	var passer := {"phone": 1.0, "shirt": Color(0.1, 0.2, 0.3)}
	var theirs: Dictionary = IntroKit.dressed(probe, passer)
	_check(theirs.get("shirt") == Color(0.1, 0.2, 0.3) and not theirs.has("hair_style"),
		"a passer-by keeps their own colours")
	probe.queue_free()

	# GET READY offers NEW LOOK on the YOUR HUMAN row only
	var MenuFlow: GDScript = load("res://hud/menu_flow.gd")
	var fm := FakeMenu.new()
	fm.details_idx = MenuFlow.DETAIL_ROWS.find("walker")
	var on_walker: Array = MenuFlow.prompts(fm, "details")
	fm.details_idx = MenuFlow.DETAIL_ROWS.find("dog")
	var on_dog: Array = MenuFlow.prompts(fm, "details")
	_check(on_walker.any(func(p): return p[0] == "pee" and p[1] == "new look"), "YOUR HUMAN offers new look")
	_check(not on_dog.any(func(p): return p[0] == "pee"), "YOUR DOG does not")
	fm.free()

	game.human_look = keep_look
	await process_frame
	if failures.is_empty():
		print("test_human_look: %d checks, OK" % checks)
		quit(0)
	else:
		print("test_human_look: %d checks, %d FAILURES" % [checks, failures.size()])
		quit(1)


class FakeMenu:
	extends Node2D
	var details_idx := 0

