extends SceneTree

# Verifies all 25 in-game achievements (systems/achievements.gd):
# - Every feat unlocks from the real event hook that owns it, once (never twice)
# - Tutorial mode, autowalk, free_play and free_walk never unlock achievements
# - Every unlock pushes one localized toast through EventFeed (no English literal)
# - achievements, dogs_walked and gallery_bones persist across save/load

var Ach: GDScript
var Flow: GDScript
var Goals: GDScript
var Detour: GDScript
var Challenger: GDScript

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	call_deferred("_run")


func _finish_walk(main: Node2D, lv: String, perfect := false) -> void:
	var game: Node = root.get_node("Game")
	main.lvl = lv
	main.tutorial_mode = false
	main.auto_walk = false
	main.finished = false
	main.frozen = false
	main.elapsed = 18.0
	main.bones = 20
	main.run_pre_total_stars = game.total_stars()
	main.run_pre_level_stars = game.stars(lv)
	main.run_pre_unlocked.clear()
	main.run_goals_hit.clear()
	if perfect:
		var q := {"id": "mark", "text": "mark", "target": 1, "fn": func() -> int: return 1}
		main.active_quests.assign([q])
		main.run_goals_hit["mark"] = true
	else:
		var q := {"id": "mark", "text": "mark", "target": 1, "fn": func() -> int: return 0}
		main.active_quests.assign([q])
	main.dog.global_position = Vector2(main.walk_cx, main.HOME_Y + 40.0)
	main.human.global_position = Vector2(main.walk_cx, main.HOME_Y + 40.0)
	Goals.finish_walk(main)
	main.results_card.visible = false
	main.dim.visible = false
	main.finished = false
	main.frozen = false


func _credit_goals(main: Node2D, lv: String, count: int) -> void:
	main.lvl = lv
	main.tutorial_mode = false
	main.auto_walk = false
	main.run_goals_hit.clear()
	var ids: Array = Goals.LEVEL_GOAL_IDS.get(lv, [])
	for i in range(mini(count, ids.size())):
		var gid := String(ids[i])
		var q := {"id": gid, "text": gid, "target": 1}
		Goals.credit(main, q)


func _run() -> void:
	Ach = load("res://systems/achievements.gd")
	Flow = load("res://hud/menu_flow.gd")
	Goals = load("res://systems/goals.gd")
	Detour = load("res://systems/detour.gd")
	Challenger = load("res://entities/challenger.gd")
	var game: Node = root.get_node("Game")
	var prev_persist: bool = game.persist
	var prev_save_path: String = game.save_path
	var tmp_path := "user://test_achievements_tmp.cfg"
	var abs_tmp := ProjectSettings.globalize_path(tmp_path)
	if FileAccess.file_exists(tmp_path):
		DirAccess.remove_absolute(abs_tmp)

	game.persist = true
	game.save_path = tmp_path
	game._reset_persisted_state()

	var main: Node2D = load("res://main.tscn").instantiate()
	root.add_child(main)
	if not main.is_node_ready():
		await main.ready
	main.started = true
	main.frozen = false
	main.tutorial_mode = false
	main.auto_walk = false
	main.feed.toasts.clear()

	# 1. Table & I18n coverage
	_check(Ach.FEATS.size() == 25, "25 achievements defined (%d)" % Ach.FEATS.size())
	var seen_ids := {}
	for f: Dictionary in Ach.FEATS:
		var id := String(f.id)
		_check(not seen_ids.has(id), "unique feat id '%s'" % id)
		seen_ids[id] = true
		_check(I18n.has(String(f.name)) and I18n.has(String(f.hint)), "i18n keys exist for '%s'" % id)

	# 2. Guards: tutorial, autowalk, free_play, free_walk must unlock nothing
	main.tutorial_mode = true
	main.lvl = "barri"
	main.on_combo_banked(500, 10, 20)
	main.on_challenge_done(true, 3, 3)
	Ach.on_boss_settled(main, "boss_mamut")
	Ach.on_gallery_bone(main, "drac")
	_check(game.achievements.is_empty(), "tutorial_mode unlocks no achievements")
	main.tutorial_mode = false

	main.auto_walk = true
	main.on_combo_banked(500, 10, 20)
	_finish_walk(main, "barri", true) if false else Ach.on_walk_finished(main, true)
	_check(game.achievements.is_empty(), "auto_walk unlocks no achievements")
	main.auto_walk = false

	game.free_play = true
	main.on_combo_banked(500, 10, 20)
	Ach.on_wardrobe_bought(main)
	_check(game.achievements.is_empty(), "free_play unlocks no achievements")
	game.free_play = false

	# Free walk on an already completed level (via simulated old completed record without using finish_walk)
	game.records["barri"].time = 10.0
	game.free_walk = true
	main.lvl = "barri"
	main.on_combo_banked(500, 10, 20)
	_check(game.achievements.is_empty(), "free_walk unlocks no achievements")
	game.free_walk = false
	game._reset_persisted_state()
	main.feed.toasts.clear()

	# 3. Combos: x5 then x10, plus toast verification and idempotence
	main.lvl = "barri"
	main.feed.toasts.clear()
	main.on_combo_banked(250, 5, 10)
	_check(Ach.has("combo_5") and not Ach.has("combo_10"), "x5 combo unlocks combo_5 only")
	_check(main.feed.toasts.size() == 1 and String(main.feed.toasts[0].title) == I18n.t("toast_achievement")
		and String(main.feed.toasts[0].text) == I18n.t("ach_combo_5_name"),
		"unlocking combo_5 displays its achievement toast")
	main.feed.toasts.clear()
	main.on_combo_banked(250, 5, 10)
	_check(main.feed.toasts.is_empty(), "re-landing x5 does not re-toast")
	main.on_combo_banked(900, 10, 25)
	_check(Ach.has("combo_10"), "x10 combo unlocks combo_10")
	_check(main.feed.toasts.size() == 1 and String(main.feed.toasts[0].text) == I18n.t("ach_combo_10_name"),
		"unlocking combo_10 displays its achievement toast")

	# 4. Dares: win one dare, then sweep all 3 from one giver
	var giver: Node2D = Challenger.new()
	main.add_child(giver)
	main.challenge_giver = giver
	main.on_challenge_done(true, 3, 3)
	_check(Ach.has("dare_win") and not Ach.has("dare_sweep"), "1 dare win unlocks dare_win only")
	main.on_challenge_done(true, 5, 5)
	_check(not Ach.has("dare_sweep"), "2 dare wins do not unlock dare_sweep yet")
	main.on_challenge_done(true, 7, 7)
	_check(Ach.has("dare_sweep"), "3 dare wins from one giver unlock dare_sweep")
	main.challenge_giver = null
	giver.free()

	# 5. Five statue bosses + all_bosses
	var BossMamutCls: GDScript = load("res://systems/boss_mamut.gd")
	var BossDracCls: GDScript = load("res://systems/boss_drac.gd")
	var BossLleonsCls: GDScript = load("res://systems/boss_lleons.gd")
	var BossLleonaCls: GDScript = load("res://systems/boss_lleona.gd")
	var BossGatCls: GDScript = load("res://systems/boss_gat.gd")

	var mamut = BossMamutCls.new()
	mamut.main = main
	mamut.win_film_shown = true
	main.lvl = "ciutadella"
	mamut.transition_to(BossMamutCls.State.CONTENT)
	_check(Ach.has("boss_mamut") and not Ach.has("all_bosses"), "settling El Mamut unlocks boss_mamut")

	var drac = BossDracCls.new()
	drac.main = main
	drac.win_film_shown = true
	main.lvl = "guell"
	drac.transition_to(BossDracCls.State.CONTENT)
	_check(Ach.has("boss_drac") and not Ach.has("all_bosses"), "settling El Drac unlocks boss_drac")

	var lleons = BossLleonsCls.new()
	lleons.main = main
	lleons.win_film_shown = true
	main.lvl = "port"
	lleons.transition_to(BossLleonsCls.State.CONTENT)
	_check(Ach.has("boss_lleons") and not Ach.has("all_bosses"), "settling Els Lleons unlocks boss_lleons")

	var lleona = BossLleonaCls.new()
	lleona.main = main
	lleona.win_film_shown = true
	main.lvl = "girona"
	lleona.transition_to(BossLleonaCls.State.CONTENT)
	_check(Ach.has("boss_lleona") and not Ach.has("all_bosses"), "settling La Lleona unlocks boss_lleona")

	var gat = BossGatCls.new()
	gat.main = main
	gat.plinth_film_shown = true
	main.lvl = "raval"
	gat.transition_to(BossGatCls.State.PURR)
	_check(Ach.has("boss_gat") and Ach.has("all_bosses"), "settling El Gat unlocks boss_gat and all_bosses")

	# 6. Four secret gallery bones via Detour.tick
	for spec: Array in [
		["street", "drac", "drac_bone_taken"],
		["reial", "colom", "colom_bone_taken"],
		["montjuic", "estel", "estel_bone_taken"],
		["oldtown", "", "somni_bone_taken"],
	]:
		main.lvl = String(spec[0])
		main.detour_kind = String(spec[1])
		main.detour_active = true
		main.set(String(spec[2]), false)
		main.dog.global_position = Detour.origin_for(main) + Detour.BONE_POS
		Detour.tick(main, 0.016)
	main.detour_active = false
	main.detour_kind = ""
	_check(game.gallery_bones.size() == 4 and Ach.has("all_gallery_bones"), "all 4 gallery bones unlock all_gallery_bones")

	# 7. Wardrobe full set via MenuFlow.shop_select
	main.started = false
	main.frozen = true
	game.total_bones = 2000
	Flow.open_shop(main)
	for want_kind: String in ["collar", "bandana", "coat"]:
		for idx in range(main.shop_items.size()):
			var it: Dictionary = main.shop_items[idx]
			if String(it.kind) == want_kind and not game.is_owned(want_kind, String(it.key)):
				main.shop_idx = idx
				Flow.shop_select(main)
				break
	Flow.close_shop(main)
	main.started = true
	main.frozen = false
	_check(Ach.has("wardrobe_set"), "buying collar + bandana + coat in wardrobe unlocks wardrobe_set")

	# 8. First walk + perfect walk + idempotence
	_finish_walk(main, "barri", true)
	_check(Ach.has("first_walk") and Ach.has("perfect_walk"), "finishing all-goals barri unlocks first_walk and perfect_walk")
	var cnt_after_perfect: int = game.achievements.size()
	_finish_walk(main, "barri", true)
	_check(game.achievements.size() == cnt_after_perfect, "repeating perfect walk unlocks nothing twice")

	# 9. Chase walk + 3 stars on a chase walk + stars_25 / stars_50 + all_chases
	_finish_walk(main, "neteja", false)
	_check(Ach.has("first_chase") and not Ach.has("chase_three_stars"), "finishing neteja unlocks first_chase only")
	_credit_goals(main, "neteja", 9)
	_check(Ach.has("chase_three_stars"), "earning 9 goals on chase walk unlocks chase_three_stars")

	for clv: String in game.CHASE_WALKS:
		_finish_walk(main, clv, false)
	_check(Ach.has("all_chases"), "finishing every chase walk unlocks all_chases")

	# 10. All 5 chapters + stars_25 + stars_50 + all 5 dogs
	var star_levels := ["barri", "street", "park", "beach", "oldtown", "montjuic", "market", "rain", "besos",
		"llevant", "eixample", "tibidabo", "vet", "sarria", "trail", "angels", "spook"]
	for slv: String in star_levels:
		_credit_goals(main, slv, 9)
	_check(Ach.has("stars_25") and Ach.has("stars_50"), "50 total stars unlock stars_25 and stars_50 (%d)" % game.total_stars())

	var chs: Array = game.chapters()
	for ci in range(chs.size()):
		for raw_lv in chs[ci]:
			var clv := String(raw_lv)
			if clv == "tutorial" or not (clv in game.LEVELS):
				continue
			if not game.has_completed(clv):
				_finish_walk(main, clv, false)
		_check(Ach.has("chapter_%d" % (ci + 1)), "finishing chapter %d unlocks chapter_%d" % [ci + 1, ci + 1])

	for dk: String in game.DOG_KEYS:
		game.dog = dk
		_finish_walk(main, "barri", false)
	_check(Ach.has("all_dogs") and game.dogs_walked.size() == game.DOG_KEYS.size(), "walking every dog unlocks all_dogs")

	# 11. Full count and final dog-pack toast check
	_check(Ach.unlocked_count() == 25 and game.achievements.size() == 25,
		"all 25 achievements unlocked (%d / %d)" % [Ach.unlocked_count(), game.achievements.size()])
	_check(not main.feed.toasts.is_empty() and String(main.feed.toasts[-1].title) == I18n.t("toast_achievement")
		and String(main.feed.toasts[-1].text) == I18n.t("ach_all_dogs_name"),
		"final achievement toast sits in EventFeed.toasts")

	# 12. Save / load persistence
	game.save_records()
	game._reset_persisted_state()
	_check(game.achievements.is_empty() and game.dogs_walked.is_empty() and game.gallery_bones.is_empty(),
		"_reset_persisted_state clears achievement arrays")
	game.load_records()
	_check(game.achievements.size() == 25 and game.dogs_walked.size() == game.DOG_KEYS.size() and game.gallery_bones.size() == 4,
		"save/load restores achievements (%d), dogs_walked (%d), gallery_bones (%d)" % [
			game.achievements.size(), game.dogs_walked.size(), game.gallery_bones.size()])

	# Cleanup
	if FileAccess.file_exists(tmp_path):
		DirAccess.remove_absolute(abs_tmp)
	game.save_path = prev_save_path
	game.persist = prev_persist
	game.load_records()

	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("TEST ACHIEVEMENTS OK")
		quit(0)
	else:
		print("TEST ACHIEVEMENTS FAIL")
		quit(1)
