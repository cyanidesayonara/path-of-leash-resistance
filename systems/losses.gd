class_name Losses
extends RefCounted

# The card a lost walk ends on: the joke first, then one plain line on how to
# keep it from happening next time, then what the walk kept (new goals stay
# ticked). A player's very first lost walk gets a word of comfort as well.
# Menu body text: plain sentences, no key names - the prompt bar offers
# "try again", one press away.

# each cause's hint, as an I18n key
const HINT := {
	"phone": "loss_hint_phone",
	"manhole": "loss_hint_manhole",
	"cellar": "loss_hint_cellar",
	"dog_hole": "loss_hint_dog_hole",
	"edge": "loss_hint_edge",
	"chase": "loss_hint_chase",
}

const COMFORT := "loss_comfort"


# The full card text for a loss: msg is the title and the joke, cause one of
# HINT's keys (or "" for no hint). Counts the loss in the save.
static func card(m: Node2D, msg: String, cause: String) -> String:
	var lines: Array[String] = [msg]
	if HINT.has(cause):
		lines.append("")
		lines.append(I18n.t(HINT[cause]))
	var kept := int(m.run_goals_new)
	if kept == 1:
		lines.append("")
		lines.append(I18n.t("loss_kept_one"))
	elif kept > 1:
		lines.append("")
		lines.append(I18n.t("loss_kept_many") % kept)
	if Game.walks_lost == 0:
		lines.append("")
		lines.append(I18n.t(COMFORT))
	# test and tool runs (headless) and screenshots never write the player's
	# save, nor spend their first loss
	var text := "\n".join(lines)
	if "--shot" in OS.get_cmdline_user_args():
		return text
	Game.walks_lost += 1
	if DisplayServer.get_name() != "headless":
		Game.save_records()
	return text
