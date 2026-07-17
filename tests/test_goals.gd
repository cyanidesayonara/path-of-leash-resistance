extends SceneTree

# Regression for the per-level goal -> star progression math in game.gd:
#  - stars derive from completed-goal milestones (3/6/9)
#  - a legacy stored star value is never regressed below
#  - goal_done / goals_count read the persisted list
#  - gate_crossed detects passing a walk's unlock threshold
# Pure logic only: manipulates an isolated Game instance's `records`
# in memory and never calls save (no disk writes).

const GameScript := preload("res://game.gd")


func _initialize() -> void:
	var g = GameScript.new()
	var failures := 0

	g.records = {"street": {"goals": [], "stars": 0}}

	# milestones: 0,1,2,3 stars at 0-2 / 3-5 / 6-8 / 9+ goals
	var expect := {0: 0, 2: 0, 3: 1, 5: 1, 6: 2, 8: 2, 9: 3, 10: 3}
	for n in expect:
		g.records["street"]["goals"] = []
		for i in range(int(n)):
			g.records["street"]["goals"].append("g%d" % i)
		var s: int = g.stars("street")
		if s != int(expect[n]):
			print("FAIL: %d goals should give %d stars, got %d" % [n, int(expect[n]), s])
			failures += 1

	# a legacy stored star floor is honoured even with no goals recorded
	g.records["street"] = {"goals": [], "stars": 2}
	if g.stars("street") != 2:
		print("FAIL: legacy stored stars should not regress (got %d)" % g.stars("street"))
		failures += 1

	# goal_done / goals_count
	g.records["park"] = {"goals": ["mark", "tofu"], "stars": 0}
	if not g.goal_done("park", "tofu"):
		print("FAIL: tofu should read as done in park")
		failures += 1
	if g.goal_done("park", "prize"):
		print("FAIL: prize should not be done in park")
		failures += 1
	if g.goals_count("park") != 2:
		print("FAIL: park should count 2 goals, got %d" % g.goals_count("park"))
		failures += 1

	# gate_crossed: beach unlocks at 4 total stars
	# street 3 stars (9 goals) + park 1 star (3 goals) = 4 total
	g.records["street"] = {"goals": [], "stars": 0}
	for i in range(9):
		g.records["street"]["goals"].append("s%d" % i)
	g.records["park"] = {"goals": ["a", "b", "c"], "stars": 0}
	g.records["beach"] = {"goals": [], "stars": 0}
	g.records["market"] = {"goals": [], "stars": 0}
	if g.total_stars() != 4:
		print("FAIL: expected 4 total stars, got %d" % g.total_stars())
		failures += 1
	if not g.gate_crossed(3, "beach"):
		print("FAIL: going 3 -> 4 total stars should cross the beach gate (4)")
		failures += 1
	if g.gate_crossed(4, "beach"):
		print("FAIL: starting already at 4 should not re-cross the beach gate")
		failures += 1
	if not g.is_unlocked("beach"):
		print("FAIL: beach should be unlocked at 4 stars")
		failures += 1
	if g.is_unlocked("market"):
		print("FAIL: market (gate 7) should be locked at 4 stars")
		failures += 1

	g.free()
	if failures > 0:
		print("test_goals: %d FAILURES" % failures)
		quit(1)
	else:
		print("test_goals: OK")
		quit(0)
