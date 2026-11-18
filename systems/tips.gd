class_name Tips
extends RefCounted

# FIRST-TIME TIPS: the first time something non-obvious happens to a player -
# a cracked phone, a wobble at an edge, a "HEY!" from your human, a human
# wound round a post - the banner says what to do about it, once, for six
# seconds, and never again (Game.tips_seen, saved). Not in the tutorial,
# which teaches all of it one thing at a time, and not for the autowalk.
# Banner voice: capitals, an instruction, short. Keys only through tokens.

const SHOW_S := 6.0

# tests set this to exercise tips in a headless run
static var force_headless := false
# the tip on the banner now, so a change of language can re-fill it
static var showing := ""

# each tip's words are the I18n key "tip_" + its id
const IDS: Array[String] = ["start", "crack", "teeter", "correct", "whirl", "swing", "grind"]


# Show a tip if this player has never seen it. True when it was shown.
static func show(m: Node2D, id: String) -> bool:
	if m.tutorial_mode or m.auto_walk or not id in IDS or Game.tips_seen.has(id):
		return false
	# not for test and tool runs: they would spend the player's tips and
	# write their save, and screenshots want the walk's own banner
	if DisplayServer.get_name() == "headless" and not force_headless:
		return false
	if "--shot" in OS.get_cmdline_user_args():
		return false
	Game.tips_seen.append(id)
	Game.save_records()
	showing = id
	m.tip_text = Prompts.fill(I18n.t("tip_" + id))
	m.tip_t = SHOW_S
	m._update_hud()
	return true


static func refill(m: Node2D) -> void:
	if m.tip_t > 0.0 and showing != "":
		m.tip_text = Prompts.fill(I18n.t("tip_" + showing))


static func tick(m: Node2D, delta: float) -> void:
	if m.tip_t <= 0.0:
		return
	m.tip_t -= delta
	if m.tip_t <= 0.0:
		m.tip_text = ""
		showing = ""
		m._update_hud()
