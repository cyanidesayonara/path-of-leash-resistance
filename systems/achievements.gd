class_name Achievements
extends RefCounted

# In-game feats, unlocked once per save from real gameplay events and shown in
# YOUR WALKS after the chapter tables. No platform SDK, and no per-frame polling:
# every feat traces back to an existing event hook.

const Kit := preload("res://hud/ui_kit.gd")

const BOSS_FEATS: Array[String] = ["boss_mamut", "boss_drac", "boss_lleons", "boss_lleona", "boss_gat"]
const GALLERY_BONES: Array[String] = ["somni", "estel", "colom", "drac"]

const FEATS: Array[Dictionary] = [
	{"id": "first_walk", "name": "ach_first_walk_name", "hint": "ach_first_walk_hint"},
	{"id": "chapter_1", "name": "ach_chapter_1_name", "hint": "ach_chapter_1_hint"},
	{"id": "chapter_2", "name": "ach_chapter_2_name", "hint": "ach_chapter_2_hint"},
	{"id": "chapter_3", "name": "ach_chapter_3_name", "hint": "ach_chapter_3_hint"},
	{"id": "chapter_4", "name": "ach_chapter_4_name", "hint": "ach_chapter_4_hint"},
	{"id": "chapter_5", "name": "ach_chapter_5_name", "hint": "ach_chapter_5_hint"},
	{"id": "boss_mamut", "name": "ach_boss_mamut_name", "hint": "ach_boss_mamut_hint"},
	{"id": "boss_drac", "name": "ach_boss_drac_name", "hint": "ach_boss_drac_hint"},
	{"id": "boss_lleons", "name": "ach_boss_lleons_name", "hint": "ach_boss_lleons_hint"},
	{"id": "boss_lleona", "name": "ach_boss_lleona_name", "hint": "ach_boss_lleona_hint"},
	{"id": "boss_gat", "name": "ach_boss_gat_name", "hint": "ach_boss_gat_hint"},
	{"id": "all_bosses", "name": "ach_all_bosses_name", "hint": "ach_all_bosses_hint"},
	{"id": "first_chase", "name": "ach_first_chase_name", "hint": "ach_first_chase_hint"},
	{"id": "chase_three_stars", "name": "ach_chase_three_stars_name", "hint": "ach_chase_three_stars_hint"},
	{"id": "all_chases", "name": "ach_all_chases_name", "hint": "ach_all_chases_hint"},
	{"id": "combo_5", "name": "ach_combo_5_name", "hint": "ach_combo_5_hint"},
	{"id": "combo_10", "name": "ach_combo_10_name", "hint": "ach_combo_10_hint"},
	{"id": "dare_win", "name": "ach_dare_win_name", "hint": "ach_dare_win_hint"},
	{"id": "dare_sweep", "name": "ach_dare_sweep_name", "hint": "ach_dare_sweep_hint"},
	{"id": "perfect_walk", "name": "ach_perfect_walk_name", "hint": "ach_perfect_walk_hint"},
	{"id": "stars_25", "name": "ach_stars_25_name", "hint": "ach_stars_25_hint"},
	{"id": "stars_50", "name": "ach_stars_50_name", "hint": "ach_stars_50_hint"},
	{"id": "all_dogs", "name": "ach_all_dogs_name", "hint": "ach_all_dogs_hint"},
	{"id": "wardrobe_set", "name": "ach_wardrobe_set_name", "hint": "ach_wardrobe_set_hint"},
	{"id": "all_gallery_bones", "name": "ach_all_gallery_bones_name", "hint": "ach_all_gallery_bones_hint"},
]


static func _game() -> Node:
	var ml: MainLoop = Engine.get_main_loop()
	if ml is SceneTree:
		return (ml as SceneTree).root.get_node_or_null("Game")
	return null


static func feat(id: String) -> Dictionary:
	for f: Dictionary in FEATS:
		if String(f.id) == id:
			return f
	return {}


static func has(id: String) -> bool:
	var g := _game()
	return g != null and g.achievements.has(id)


static func unlocked_count() -> int:
	var g := _game()
	if g == null:
		return 0
	var n := 0
	for f: Dictionary in FEATS:
		if g.achievements.has(String(f.id)):
			n += 1
	return n


static func grant(m: Node2D, id: String) -> bool:
	var g := _game()
	if g == null or bool(g.free_play):
		return false
	var f := feat(id)
	if f.is_empty() or g.achievements.has(id):
		return false
	g.achievements.append(id)
	g.save_records()
	if m != null:
		var feed_v: Variant = m.get("feed")
		if feed_v != null and feed_v.has_method("toast"):
			feed_v.toast("goal", I18n.t("toast_achievement"), I18n.t(String(f.name)), Kit.GOLD)
	return true


static func _flag(obj: Object, prop: String) -> bool:
	var v: Variant = obj.get(prop)
	return v != null and bool(v)


static func _eligible_walk(m: Node2D) -> bool:
	var g := _game()
	if m == null or g == null or bool(g.free_play):
		return false
	if _flag(m, "tutorial_mode") or _flag(m, "auto_walk"):
		return false
	var lv_v: Variant = m.get("lvl")
	if lv_v == null:
		return false
	return bool(g.recording(String(lv_v)))


static func _all_completed(g: Node, walks: Array) -> bool:
	if bool(g.free_play) or walks.is_empty():
		return false
	var saw_real := false
	for raw_lv in walks:
		var lv := String(raw_lv)
		if lv == "tutorial" or not (lv in g.LEVELS):
			continue
		saw_real = true
		if not g.has_completed(lv):
			return false
	return saw_real


static func _check_stars(m: Node2D, g: Node) -> void:
	if bool(g.free_play):
		return
	var total: int = g.total_stars()
	if total >= 25:
		grant(m, "stars_25")
	if total >= 50:
		grant(m, "stars_50")


static func _check_chapters(m: Node2D, g: Node) -> void:
	var chs: Array = g.chapters()
	for i in range(mini(5, chs.size())):
		var id := "chapter_%d" % (i + 1)
		if not has(id) and _all_completed(g, chs[i] as Array):
			grant(m, id)


static func _check_dogs(m: Node2D, g: Node) -> void:
	var d := String(g.dog)
	if d in g.DOG_KEYS and not g.dogs_walked.has(d):
		g.dogs_walked.append(d)
		g.save_records()
	for k: String in g.DOG_KEYS:
		if not g.dogs_walked.has(k):
			return
	grant(m, "all_dogs")


static func on_goal_credited(m: Node2D) -> void:
	if not _eligible_walk(m):
		return
	var g := _game()
	_check_stars(m, g)
	var lv := String(m.get("lvl"))
	if lv in g.CHASE_WALKS and int(g.stars(lv)) >= 3:
		grant(m, "chase_three_stars")


static func on_walk_finished(m: Node2D, perfect: bool) -> void:
	if not _eligible_walk(m):
		return
	var g := _game()
	var lv := String(m.get("lvl"))
	grant(m, "first_walk")
	if perfect:
		grant(m, "perfect_walk")
	if lv in g.CHASE_WALKS:
		grant(m, "first_chase")
		if int(g.stars(lv)) >= 3:
			grant(m, "chase_three_stars")
		if _all_completed(g, g.CHASE_WALKS):
			grant(m, "all_chases")
	_check_chapters(m, g)
	_check_stars(m, g)
	_check_dogs(m, g)


static func on_combo_banked(m: Node2D, mult: int) -> void:
	if not _eligible_walk(m):
		return
	if mult >= 5:
		grant(m, "combo_5")
	if mult >= 10:
		grant(m, "combo_10")


static func on_challenge_done(m: Node2D, win: bool) -> void:
	if not win or not _eligible_walk(m):
		return
	grant(m, "dare_win")
	var giver: Variant = m.get("challenge_giver")
	if is_instance_valid(giver):
		var count: int = int(giver.dare_count()) if giver.has_method("dare_count") else 3
		if int(giver.get("rung")) >= count:
			grant(m, "dare_sweep")


static func on_boss_settled(m: Node2D, feat_id: String) -> void:
	if not _eligible_walk(m):
		return
	if not (feat_id in BOSS_FEATS):
		return
	grant(m, feat_id)
	for bid: String in BOSS_FEATS:
		if not has(bid):
			return
	grant(m, "all_bosses")


static func _has_bought_cosmetic(g: Node, kind: String, catalog: Dictionary, default_key: String) -> bool:
	for k: String in catalog:
		if k != default_key and int(catalog[k].get("cost", 0)) > 0 and g.is_owned(kind, k):
			return true
	return false


static func on_wardrobe_bought(m: Node2D) -> void:
	var g := _game()
	if g == null or bool(g.free_play):
		return
	if _has_bought_cosmetic(g, "collar", g.COLLARS, g.DEFAULT_COLLAR) \
			and _has_bought_cosmetic(g, "bandana", g.BANDANAS, g.DEFAULT_BANDANA) \
			and _has_bought_cosmetic(g, "coat", g.COATS, g.DEFAULT_COAT):
		grant(m, "wardrobe_set")


static func on_gallery_bone(m: Node2D, kind: String) -> void:
	if not _eligible_walk(m) or not (kind in GALLERY_BONES):
		return
	var g := _game()
	if not g.gallery_bones.has(kind):
		g.gallery_bones.append(kind)
		g.save_records()
	for gk: String in GALLERY_BONES:
		if not g.gallery_bones.has(gk):
			return
	grant(m, "all_gallery_bones")
