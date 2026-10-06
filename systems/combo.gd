extends Node

# The combo / multiplier meter (Tony Hawk style). A chain starts with a
# TRICK - a grind, a pole swing, a fling, a save, an air catch (TRICKS, plus
# every grindable's name) - and only tricks raise the multiplier. Dog
# business (a sniff, a mark, a hello) adds its points and keeps a chain that
# is already going alive, but never starts one or multiplies it: walking
# about is not a combo. Land another trick within WINDOW and the chain
# grows; when the window lapses it BANKS a style score of points x links,
# plus a bones bonus that scales with the multiplier. A bail drops it all.

const WINDOW := 4.0
# the tricks: everything else that scores is business
const TRICKS := ["POLE SWING", "FLING", "SLINGSHOT", "BALANCE", "SAVE", "BRACED", "AIR CATCH",
	"AGILITY", "CLOSE SHAVE", "WALKWAY",
	"LEDGE RUN", "HEDGE RUN", "BENCH GRIND", "WALL WALK", "HANDRAIL"]
const MAX_LABELS := 4  # trick names kept in the display string
const BONUS_CAP := 40

var main: Node2D
var links := 0
var points := 0
var timer := 0.0
var names: Array[String] = []
# run totals, read by the results screen
var best_mult := 0
var run_style := 0


func setup(m: Node2D) -> void:
	main = m


static func is_trick(label: String) -> bool:
	return label in TRICKS


func add(label: String, pts: int) -> void:
	var trick := is_trick(label)
	# the main game hears about everything (the phone call counts it all) and
	# tricks feed the zoomies and the dare; golden zoomies double a trick
	if main != null and main.has_method("on_scored"):
		pts = int(main.on_scored(label, pts, trick))
	if timer <= 0.0:
		# only a trick starts a chain
		if not trick:
			return
		links = 0
		points = 0
		names.clear()
	if trick:
		links += 1
	points += pts
	if names.is_empty() or names[names.size() - 1] != label:
		names.append(label)
	timer = WINDOW


func bail() -> void:
	# a mishap (the dog gets hit) drops the chain with nothing banked
	_reset()


func tick(delta: float) -> void:
	if timer <= 0.0:
		return
	timer -= delta
	if timer <= 0.0:
		_bank()


func active() -> bool:
	return timer > 0.0 and links > 0


func mult() -> int:
	return links


func fraction() -> float:
	return clampf(timer / WINDOW, 0.0, 1.0)


func label_text() -> String:
	var shown := names
	var prefix := ""
	if names.size() > MAX_LABELS:
		shown = names.slice(names.size() - MAX_LABELS)
		prefix = "... "
	return prefix + " + ".join(shown)


static func bonus_for(m: int) -> int:
	# only multi-trick chains pay; scales with the multiplier, capped
	return 0 if m < 2 else mini(m * (m - 1), BONUS_CAP)


func _bank() -> void:
	var m := links
	if m >= 2:
		var score := points * m
		run_style += score
		best_mult = maxi(best_mult, m)
		if main != null:
			main.on_combo_banked(score, m, bonus_for(m))
	_reset()


func _reset() -> void:
	links = 0
	points = 0
	timer = 0.0
	names.clear()
