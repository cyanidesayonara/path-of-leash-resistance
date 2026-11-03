class_name NearMiss
extends RefCounted

# A dodge is a near miss. `close` is true while the human is inside the
# hazard's reach. Coming close and then getting clear, without being hit,
# earns one dodge. Walking past without ever coming close earns nothing:
# the ordinary line of a walk is not a save.


static func consider(close: bool, hit: bool, threatened: bool, awarded: bool) -> Dictionary:
	if close and not hit and not awarded:
		threatened = true
	return {
		"threatened": threatened,
		"dodge": threatened and not hit and not awarded and not close,
	}
