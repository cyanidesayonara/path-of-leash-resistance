class_name Losses
extends RefCounted

# The card a lost walk ends on: the joke first, then one plain line on how to
# keep it from happening next time, then what the walk kept (new goals stay
# ticked). A player's very first lost walk gets a word of comfort as well.
# Menu body text: plain sentences, no key names - the prompt bar offers
# "try again", one press away.

const HINT := {
	"phone": "Bikes knock your human over. Dig in at a crossing and keep\nthem out of the bike lane.",
	"manhole": "Steer your human round open manholes, or dig in until\nyou are both past.",
	"cellar": "Keep your human off the shop side where a cellar\nhatch stands open.",
	"dog_hole": "When she wobbles at the brink, steer away from the hole.",
	"edge": "When she wobbles at the brink, steer away from the edge.",
	"chase": "Run for home and pull steadily: your human speeds up when\nthe leash leads them.",
}

const COMFORT := "Everyone loses a walk now and then. It starts fresh every time."


# The full card text for a loss: msg is the title and the joke, cause one of
# HINT's keys (or "" for no hint). Counts the loss in the save.
static func card(m: Node2D, msg: String, cause: String) -> String:
	var lines: Array[String] = [msg]
	if HINT.has(cause):
		lines.append("")
		lines.append(String(HINT[cause]))
	var kept := int(m.run_goals_new)
	if kept == 1:
		lines.append("")
		lines.append("This walk ticked a new goal. It stays ticked.")
	elif kept > 1:
		lines.append("")
		lines.append("This walk ticked %d new goals. They stay ticked." % kept)
	if Game.walks_lost == 0:
		lines.append("")
		lines.append(COMFORT)
	# test and tool runs (headless) and screenshots never write the player's
	# save, nor spend their first loss
	var text := "\n".join(lines)
	if "--shot" in OS.get_cmdline_user_args():
		return text
	Game.walks_lost += 1
	if DisplayServer.get_name() != "headless":
		Game.save_records()
	return text
