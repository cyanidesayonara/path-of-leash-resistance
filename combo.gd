extends Node

# Passive combo / multiplier meter (Tony Hawk Phase A). Every scored bit
# of dog business - sniff, mark, say-hi, fling, boop, tangle, save - is a
# "trick". Land another within WINDOW seconds and the chain grows; the
# multiplier is the number of links. When the window lapses the chain
# BANKS: a style score of (summed points x links), plus a bones bonus
# that scales with the multiplier. A bail (the dog takes a hit) drops the
# whole thing. The per-event bones rewards elsewhere are untouched - this
# is a bonus on top for stringing them together, and the push-your-luck
# tension is bank-it-safe vs keep-the-chain-alive for a fatter multiplier.

const WINDOW := 3.2
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


func add(label: String, pts: int) -> void:
	# a fresh trick after the window lapsed starts a new chain
	if timer <= 0.0:
		links = 0
		points = 0
		names.clear()
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
