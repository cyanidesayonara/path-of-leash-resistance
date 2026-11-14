class_name CastellCycle
extends RefCounted

# The castell's crowning cycle, shared by Festa de Gràcia's practice stage
# (systems/gracia.gd) and the Castellers de Barcelona in El Gòtic
# (systems/gotic_castellers.gd). It runs on the walk's own clock
# (main.elapsed), never AnimClock: the bark window is gameplay, so the tower
# drawn and the window that pays must be the same moment, paused with the walk.

const LENGTH := 8.0       # one climb, crowning and descent
const CLIMB_END := 4.0    # pujant: the anxaneta climbs
const ALETA_END := 6.5    # l'aleta: crowned, arm raised; then the descent
const BARK_FROM := 3.8    # a cheer counts from just before the crown


static func phase(m: Object) -> float:
	return fmod(float(m.elapsed), LENGTH)


static func cheer_window(m: Object) -> bool:
	var p := phase(m)
	return p >= BARK_FROM and p <= ALETA_END
