extends SceneTree

# Collar, bandana, and coat ownership share catalog keys but not purchases.
# Legacy raw ownership entries are migrated without changing equipped keys.

const GameScript := preload("res://game.gd")
const PURCHASE_SAVE := "user://v153_cosmetic_purchase.cfg"
const LEGACY_SAVE := "user://v153_cosmetic_legacy.cfg"

var failures := 0


func _check(condition: bool, message: String) -> void:
	if not condition:
		print("FAIL: " + message)
		failures += 1


func _has_property(object: Object, property_name: String) -> bool:
	for property in object.get_property_list():
		if String(property.name) == property_name:
			return true
	return false


func _method_arg_count(object: Object, method_name: String) -> int:
	for method in object.get_method_list():
		if String(method.name) == method_name:
			return (method.args as Array).size()
	return -1


func _remove(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _cleanup() -> void:
	_remove(PURCHASE_SAVE)
	_remove(LEGACY_SAVE)


func _finish() -> void:
	_cleanup()
	if failures > 0:
		print("test_cosmetic_ownership: %d FAILURES" % failures)
		quit(1)
	else:
		print("test_cosmetic_ownership: OK")
		quit(0)


func _write_legacy_save() -> void:
	var config := ConfigFile.new()
	config.set_value("global", "total_bones", 400)
	config.set_value(
		"cosmetics",
		"owned",
		["red", "none", "millie", "gold", "navy", "choc", "teal", "future-keepsake"]
	)
	config.set_value("cosmetics", "collar", "teal")
	config.set_value("cosmetics", "bandana", "navy")
	config.set_value("cosmetics", "coat", "choc")
	config.save(LEGACY_SAVE)


func _initialize() -> void:
	_cleanup()
	var game = GameScript.new()
	var category_api := (
		_has_property(game, "save_path")
		and game.has_method("is_owned")
		and game.has_method("equip")
		and _method_arg_count(game, "buy") == 2
	)
	_check(category_api, "Game exposes category-aware ownership, purchase, equip, and save-path APIs")
	if not category_api:
		game.free()
		_finish()
		return

	game.set("save_path", PURCHASE_SAVE)
	game.load_records()
	game.total_bones = 500

	_check(bool(game.call("buy", "coat", "gold")), "the gold coat can be purchased independently")
	_check(game.total_bones == 410, "the gold coat charges its 90-bone catalog price")
	_check(bool(game.call("is_owned", "coat", "gold")), "buying gold grants coat ownership")
	_check(not bool(game.call("is_owned", "collar", "gold")), "buying gold coat does not grant gold collar")
	_check(bool(game.call("equip", "coat", "gold")), "an owned gold coat can be equipped")
	_check(game.coat == "gold", "equipped coat keeps the catalog key 'gold'")
	_check(game.collar == "red", "equipping the gold coat leaves the collar unchanged")

	_check(bool(game.call("buy", "collar", "gold")), "the gold collar can be purchased independently")
	_check(game.total_bones == 290, "the gold collar separately charges its 120-bone price")
	_check(bool(game.call("is_owned", "collar", "gold")), "buying gold grants collar ownership")
	_check(bool(game.call("is_owned", "coat", "gold")), "buying the collar preserves gold coat ownership")
	_check(bool(game.call("equip", "collar", "gold")), "an owned gold collar can be equipped")
	_check(game.collar == "gold", "equipped collar keeps the catalog key 'gold'")
	_check(game.coat == "gold", "equipping the collar leaves the coat unchanged")

	game.save_records()
	var reopened = GameScript.new()
	reopened.set("save_path", PURCHASE_SAVE)
	reopened.load_records()
	_check(bool(reopened.call("is_owned", "collar", "gold")), "gold collar ownership survives reload")
	_check(bool(reopened.call("is_owned", "coat", "gold")), "gold coat ownership survives reload")
	_check(reopened.collar == "gold" and reopened.coat == "gold", "equipped gold catalog keys survive reload")
	reopened.free()
	game.free()

	_write_legacy_save()
	var legacy = GameScript.new()
	legacy.set("save_path", LEGACY_SAVE)
	legacy.load_records()
	_check(bool(legacy.call("is_owned", "collar", "gold")), "legacy ambiguous gold grants the gold collar")
	_check(bool(legacy.call("is_owned", "coat", "gold")), "legacy ambiguous gold grants the gold coat")
	_check(bool(legacy.call("is_owned", "bandana", "navy")), "legacy unrelated bandana ownership is preserved")
	_check(bool(legacy.call("is_owned", "coat", "choc")), "legacy unrelated coat ownership is preserved")
	_check(bool(legacy.call("is_owned", "collar", "teal")), "legacy unrelated collar ownership is preserved")
	_check(bool(legacy.owned.get("future-keepsake", false)), "unknown legacy ownership is not discarded")
	_check(
		legacy.collar == "teal" and legacy.bandana == "navy" and legacy.coat == "choc",
		"legacy equipped catalog keys remain unchanged"
	)

	legacy.save_records()
	var migrated = GameScript.new()
	migrated.set("save_path", LEGACY_SAVE)
	migrated.load_records()
	_check(bool(migrated.call("is_owned", "collar", "gold")), "migrated gold collar remains owned after reload")
	_check(bool(migrated.call("is_owned", "coat", "gold")), "migrated gold coat remains owned after reload")
	_check(bool(migrated.owned.get("future-keepsake", false)), "unknown ownership survives migration save")
	_check(
		migrated.collar == "teal" and migrated.bandana == "navy" and migrated.coat == "choc",
		"unrelated equipped items survive migration save"
	)

	migrated.free()
	legacy.free()
	_finish()
