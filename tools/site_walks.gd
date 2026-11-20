extends SceneTree

# Dumps the website's game-sourced data to JSON (default: res://tools/site_walks_data.json):
# chapters, walk names/glosses/skies/gates/goals, dogs, training and wardrobe
# metadata, plus tutorial station titles. Read by tools/site_walks.py so the
# website never drifts from the game.
#
#   godot --headless --path . --script res://tools/site_walks.gd [-- --out=PATH]

const DEFAULT_OUT := "res://tools/site_walks_data.json"


func _initialize() -> void:
	call_deferred("_run")


# a dog's skill goal as the walk card says it, its count filled in
func _skill_goal(dk: String, lang := "en") -> String:
	var g: Dictionary = load("res://systems/dog_skills.gd").GOALS.get(dk, {})
	if g.is_empty():
		return ""
	var text := String(g.text) if lang == "en" else _tr(String(g.id), lang)
	return text % int(g.target) if text.contains("%d") else text


# a game string in one language, "" where the game has none
func _tr(key: String, lang: String) -> String:
	var row: Dictionary = I18n.T.get(key, {})
	return String(row.get(lang, ""))


func _cap_first(s: String) -> String:
	if s.is_empty():
		return s
	return s.substr(0, 1).to_upper() + s.substr(1)


func _run() -> void:
	var out_path := DEFAULT_OUT
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_path = a.substr(6)

	var Goals: GDScript = load("res://systems/goals.gd")
	var HomeChase: GDScript = load("res://systems/home_chase.gd")
	var TutorialSteps: GDScript = load("res://systems/tutorial.gd")
	var WorldSign: GDScript = load("res://world/world_sign.gd")

	var game: Node = root.get_node("Game")
	game.persist = false
	game.free_play = false
	game.free_walk = false
	game.sky_from_args = false
	game.language = "en"
	var sfx := root.get_node_or_null("Sfx")
	if sfx != null:
		sfx.muted = true

	var chapters := []
	for ch: Array in game.chapters():
		var row: Array[String] = []
		for lv in ch:
			row.append(String(lv))
		chapters.append(row)

	# her stats as a new player has them: the breed and her head start, never
	# this machine's training
	var saved_upgrades: Dictionary = game.dog_upgrades
	game.dog_upgrades = {}
	var dogs := []
	for dk: String in game.DOG_KEYS:
		var d: Dictionary = game.DOGS[dk]
		dogs.append({
			"id": dk,
			"name": String(d.get("name", dk)),
			"breed": String(d.get("breed", "")),
			"stars": int(d.get("stars", 0)),
			"trait": String(d.get("trait", "")),
			"desc": String(d.get("desc", "")),
			"speed_mult": float(d.get("speed_mult", 1.0)),
			"accel_mult": float(d.get("accel_mult", 1.0)),
			"plant_mult": float(d.get("plant_mult", 1.0)),
			"herd_mult": float(d.get("herd_mult", 1.0)),
			"muck_mult": float(d.get("muck_mult", 1.0)),
			"mass_mult": float(d.get("mass_mult", 1.0)),
			"reel_mult": float(d.get("reel_mult", 1.0)),
			"gap_mult": float(d.get("gap_mult", 1.0)),
			"dig_mult": float(d.get("dig_mult", 1.0)),
			"nose_mult": float(d.get("nose_mult", 1.0)),
			"leaps": bool(d.get("leaps", false)),
			"skill": String(load("res://systems/dog_skills.gd").NAMES.get(dk, "")),
			"skill_goal": _skill_goal(dk),
			"skill_goal_ca": _skill_goal(dk, "ca"),
			"skill_goal_es": _skill_goal(dk, "es"),
			"trait_ca": _tr("dog_trait_" + dk, "ca"),
			"trait_es": _tr("dog_trait_" + dk, "es"),
			"innate": (d.get("innate", {}) as Dictionary).duplicate(),
			"stats": {
				"speed": game.dog_speed_mult(dk),
				"agility": game.dog_accel_mult(dk),
				"plant": game.dog_plant_mult(dk),
				"nose": game.dog_nose_mult(dk),
				"herd": game.dog_herd_mult(dk),
			},
		})
	game.dog_upgrades = saved_upgrades

	var collars := []
	for ck in game.COLLARS.keys():
		var c: Dictionary = game.COLLARS[ck]
		var col: Color = c["col"]
		collars.append({
			"id": String(ck),
			"name": String(c["name"]),
			"name_ca": _tr("collar_" + String(ck), "ca"),
			"name_es": _tr("collar_" + String(ck), "es"),
			"cost": int(c["cost"]),
			"color": "#" + col.to_html(false),
		})

	var bandanas := []
	for bk in game.BANDANAS.keys():
		var b: Dictionary = game.BANDANAS[bk]
		var col: Color = b["col"]
		bandanas.append({
			"id": String(bk),
			"name": String(b["name"]),
			"name_ca": _tr("bandana_" + String(bk), "ca"),
			"name_es": _tr("bandana_" + String(bk), "es"),
			"cost": int(b["cost"]),
			"color": ("#" + col.to_html(false)) if col.a > 0.0 else "",
		})

	var coats := []
	for ck in game.COATS.keys():
		var c: Dictionary = game.COATS[ck]
		coats.append({
			"id": String(ck),
			"name": String(c["name"]),
			"name_ca": _tr("coat_" + String(ck), "ca"),
			"name_es": _tr("coat_" + String(ck), "es"),
			"cost": int(c["cost"]),
			"fur": "#" + (c["fur"] as Color).to_html(false),
			"dark": "#" + (c["dark"] as Color).to_html(false),
			"mark": "#" + (c["mark"] as Color).to_html(false),
		})

	var walks := {}
	var main_scene: PackedScene = load("res://main.tscn")
	for lv: String in game.CAROUSEL:
		game.weather = "clear"
		game.hour = "day"
		game.level_id = lv
		var m: Node2D = main_scene.instantiate()
		root.add_child(m)
		if not m.is_node_ready():
			await m.ready

		var sky_arr: Array = game.CAMPAIGN_SKY.get(lv, ["clear", "day"])
		var w := String(game.WALK_WEATHER.get(lv, sky_arr[0]))
		var h := String(game.WALK_HOUR.get(lv, sky_arr[1]))
		var is_tut := lv == "tutorial"
		var is_boss: bool = lv in game.BOSS_WALKS
		var is_chase: bool = lv in game.CHASE_WALKS
		var kind := "walk"
		if is_tut:
			kind = "tutorial"
		elif is_boss:
			kind = "boss"
		elif is_chase:
			kind = "chase"

		var ch_gate := String(game.CHASE_GATE.get(lv, ""))
		var goals := []
		for q: Dictionary in m.active_quests:
			goals.append({
				"id": String(q.get("id", "")),
				"text": Goals.quest_text(q),
			})

		var lessons := []
		if is_tut:
			for st: Dictionary in TutorialSteps.STEPS:
				lessons.append({
					"id": String(st.get("id", "")),
					"title": String(st.get("title", "")),
					"free": bool(st.get("free", false)),
				})

		var has_carry := false
		for q: Dictionary in m.active_quests:
			if String(q.get("id", "")) == "carry":
				has_carry = true
				break

		var chase_warn := ""
		if is_chase:
			chase_warn = String(HomeChase.profile_for(lv).get("warning", ""))

		walks[lv] = {
			"id": lv,
			"name": String(game.LEVEL_NAMES.get(lv, lv)),
			"gloss": String(game.LEVEL_SUBTITLES.get(lv, "")),
			"gloss_ca": String(game.LEVEL_SUBTITLES_CA.get(lv, "")),
			"gloss_es": String(game.LEVEL_SUBTITLES_ES.get(lv, "")),
			"chapter": int(game.chapter_index(lv)) + 1,
			"kind": kind,
			"is_tutorial": is_tut,
			"is_boss": is_boss,
			"is_chase": is_chase,
			"star_gate": int(game.STAR_GATE.get(lv, 0)),
			"chase_gate": ch_gate,
			"chase_gate_name": String(game.LEVEL_NAMES.get(ch_gate, "")) if ch_gate != "" else "",
			"weather": w,
			"hour": h,
			"gate_text": String(m.gate_text),
			"freedom_kind": String(m.freedom_kind),
			"sign_material": String(WorldSign.MATERIALS.get(lv, "")),
			"clock_target": 0 if is_tut else int(m.clock_target),
			"clock_text": "" if is_tut else Goals.clock(float(m.clock_target)),
			"prize_text": "" if is_tut else _cap_first(String(m.prize_text)),
			"carry_text": _cap_first(String(m.carry_text)) if has_carry else "",
			"chase_warning": chase_warn,
			"goals": goals,
			"lessons": lessons,
		}

		m.queue_free()
		await process_frame

	var payload := {
		"count": game.LEVELS.size(),
		"carousel_count": game.CAROUSEL.size(),
		"chapters": chapters,
		"boss_walks": Array(game.BOSS_WALKS),
		"chase_walks": Array(game.CHASE_WALKS),
		"dogs": dogs,
		"training": {
			"max_points": int(game.MAX_STAT_POINTS),
			"stats": Array(game.STAT_NAMES),
		},
		"wardrobe": {
			"collars": collars,
			"bandanas": bandanas,
			"coats": coats,
			"new_look": {
				"skins": game.HUMAN_SKINS.size(),
				"hair_colors": game.HUMAN_HAIRS.size(),
				"his_styles": Array(game.HIS_HAIR),
				"her_styles": Array(game.HER_HAIR),
				"shirts": game.HUMAN_SHIRTS.size(),
				"trousers": game.HUMAN_TROUSERS.size(),
				"shoes": game.HUMAN_SHOES.size(),
			},
		},
		"walks": walks,
	}

	var f := FileAccess.open(out_path, FileAccess.WRITE)
	if f == null:
		push_error("cannot write " + out_path)
		quit(1)
		return
	f.store_string(JSON.stringify(payload, "  ") + "\n")
	f.close()
	print("wrote " + out_path)
	quit(0)
