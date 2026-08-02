extends RefCounted

# WHAT THE GROUND FEELS LIKE UNDERFOOT.
#
# Before this, "surface" was four unrelated booleans on dog.gd - sand_slow,
# swimming, slick, ice - read by a single speed expression and set from three
# places that had nothing to do with each other: weather set two of them, a
# bare `x < 340.0` set beach sand, and Rect2 lists set mud and water. There
# was no such thing AS a surface, which is why "grass should feel different
# from pavement" had nowhere to live: there was no table to put it in.
#
# So: one entry per kind, and the whole game asks this table rather than
# hardcoding a multiplier at the point of use.
#
#   top    multiplies top speed. How fast this ground lets you go.
#   grip   multiplies acceleration. How well you can push off, start, stop
#          and change direction on it - which is a different question from
#          how fast, and keeping them apart is what lets a surface be a
#          TRADE rather than a debuff.
#   scent  multiplies how far the nose reads. Ground holds smell differently,
#          and this is a dog: it is not a detail, it is most of the point.
#   marks  whether it leaves something on the paws (see SUBSTANCES).
#   washes whether it takes what is already on them back OFF. Water does, and
#          that is the honest reason to go in beyond it being fun.
#   detour whether this is somewhere you CHOOSE to step rather than terrain
#          the level simply is. A detour has to pay for what it costs, or
#          nobody will ever take it; sand on a beach owes you nothing,
#          because the beach is not a detour from itself.
#
# GRASS IS THE WORKED EXAMPLE. It is slightly slower than pavement but grips
# BETTER and holds scent BETTER, so the verge is somewhere you go on purpose -
# to corner harder or to read more of the street - rather than somewhere the
# game merely permits. A surface that is only ever worse is a wall with extra
# steps.
#
# Weather is deliberately NOT in here. Rain and snow are a modifier ON
# whatever you are standing on, not a thing you stand on, so they stay a
# separate grip multiplier (dog.slick / dog.ice) and compose with these.

enum S { PAVEMENT, GRASS, SAND, MUD, WATER }

const FEEL := {
	# the default: smooth, fast, and it tells you almost nothing
	S.PAVEMENT: {
		"top": 1.00, "grip": 1.00, "scent": 1.00,
		"marks": false, "washes": false, "detour": false, "name": "pavement",
	},
	# soft going, but you can turn on it, and a whole day has soaked into it
	S.GRASS: {
		"top": 0.94, "grip": 1.08, "scent": 1.25,
		"marks": false, "washes": false, "detour": true, "name": "grass",
	},
	# heavy work, and nothing to push off against. The beach is not a detour
	# from itself, so it owes nothing back
	S.SAND: {
		"top": 0.80, "grip": 0.78, "scent": 0.85,
		"marks": true, "washes": false, "detour": false, "name": "sand",
	},
	# slow and sucking, and avoidable - but it holds a smell better than
	# anything else in the game, which is what makes wading in worth it
	S.MUD: {
		"top": 0.80, "grip": 0.88, "scent": 1.30,
		"marks": true, "washes": false, "detour": true, "name": "mud",
	},
	# A happy dog-paddle: no purchase, and smell simply stops at the surface.
	# What it pays is that it takes the mud, paint and fish back off her -
	# which is both true of dogs and the only way to undo a substance
	S.WATER: {
		"top": 0.62, "grip": 0.72, "scent": 0.40,
		"marks": false, "washes": true, "detour": false, "name": "water",
	},
}


static func feel(s: int) -> Dictionary:
	return FEEL.get(s, FEEL[S.PAVEMENT])


static func top_mult(s: int) -> float:
	return float(feel(s)["top"])


static func grip_mult(s: int) -> float:
	return float(feel(s)["grip"])


static func scent_mult(s: int) -> float:
	return float(feel(s)["scent"])


static func surface_name(s: int) -> String:
	return String(feel(s)["name"])
