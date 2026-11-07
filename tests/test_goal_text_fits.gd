extends SceneTree

# Regression test: verify every goal's displayed text fits within its goal list row width.
# Font: ThemeDB.fallback_font
# Font size: GoalsCard.FONT_SIZE (15)
# Row width: GoalsCard.W - GoalsCard.TEXT_X - GoalsCard.PAD - side_w (accounting for meters, letters, readouts)

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	print("--- Running test_goal_text_fits ---")
	var game = root.get_node("Game")
	var keep_persist: bool = game.persist
	var keep_records: Dictionary = game.records.duplicate(true)
	var keep_level: String = game.level_id
	game.persist = false
	game.records = {}
	var sfx = root.get_node_or_null("Sfx")
	var keep_muted: bool = sfx.muted if sfx != null else false
	if sfx != null:
		sfx.muted = true

	var Goals: GDScript = load("res://systems/goals.gd")
	var GoalsCard: GDScript = load("res://hud/goals_card.gd")
	var main_scene: PackedScene = load("res://main.tscn")
	var f: Font = ThemeDB.fallback_font

	var checks := 0

	for lvl: String in game.LEVELS:
		game.level_id = lvl
		var inst: Node2D = main_scene.instantiate()
		root.add_child(inst)
		if not inst.is_node_ready():
			await inst.ready

		for q: Dictionary in inst.active_quests:
			checks += 1
			var txt: String = Goals.quest_text(q)
			var sz: float = f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, GoalsCard.FONT_SIZE).x

			var target: int = int(q.target)
			var row: Dictionary = Goals.row_extras(inst, q, {"text": txt, "target": target})
			var letters: Array = row.get("letters", [])
			var readout: String = String(row.get("readout", ""))
			var show_meter: bool = target > 1 and letters.is_empty()

			var side_w := 0.0
			if show_meter:
				side_w = GoalsCard.METER_W + 34.0
			elif not letters.is_empty():
				side_w = float(letters.size()) * (GoalsCard.TILE + GoalsCard.TILE_GAP) + 8.0
			elif readout != "":
				side_w = f.get_string_size(readout, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x + 12.0

			var row_w: float = GoalsCard.W - GoalsCard.TEXT_X - GoalsCard.PAD - side_w

			if sz > row_w:
				_failures += 1
				print("FAIL: %s: '%s' is %.0f px, the row holds %.0f px" % [lvl, txt, sz, row_w])

		inst.queue_free()

	if sfx != null:
		sfx.muted = keep_muted
	game.persist = keep_persist
	game.records = keep_records
	game.level_id = keep_level

	print("--- Finished test_goal_text_fits (%d checks, %d failures) ---" % [checks, _failures])
	quit(1 if _failures > 0 else 0)
