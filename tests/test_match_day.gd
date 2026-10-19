extends SceneTree

# The match clock (systems/match_day.gd): phases in order, kick-off on the
# clock or the gate whichever is first, the streets empty within the drain,
# and the bar's "ooh, the replay..." is a telegraph before your human drifts.

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _edges(_y: float) -> Vector2:
	return Vector2(80.0, 1200.0)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_clock()
	_drain()
	await _live()
	print("test_match_day: %d checks, %d failures" % [checks, failures.size()])
	quit(1 if failures.size() > 0 else 0)


func _clock() -> void:
	var gate := -5000.0
	var far := 100.0
	var day := MatchDay.new()
	# one long step lands in the rush, not past it
	var cue: Dictionary = day.advance(MatchDay.KICKOFF_T - MatchDay.RUSH_LEAD, far, gate, false)
	_check(day.phase == MatchDay.Ph.RUSH, "the last 25 seconds are the rush")
	_check(bool(cue["pa"]), "the PA speaks as the rush starts")
	_check(String(cue["banner"]) == "KICK-OFF SOON", "the banner is KICK-OFF SOON")
	cue = day.advance(MatchDay.RUSH_LEAD, far, gate, false)
	_check(day.phase == MatchDay.Ph.KICKOFF, "the clock reaches kick-off")
	_check(bool(cue["whistle"]), "the whistle sounds")
	for i in range(int(MatchDay.DRAIN_T) - 1):
		day.advance(1.0, far, gate, false)
	_check(day.phase == MatchDay.Ph.KICKOFF, "the streets are still emptying")
	day.advance(1.1, far, gate, false)
	_check(day.phase == MatchDay.Ph.MATCH, "then the match is on")

	# the gate, early: no rush, no PA
	var sprint := MatchDay.new()
	cue = sprint.advance(40.0, gate, gate, false)
	_check(sprint.phase == MatchDay.Ph.KICKOFF, "reaching the gate is kick-off")
	_check(not bool(cue["pa"]), "a fast walk does not get the five-minute call")
	_check(sprint.walk_t < MatchDay.KICKOFF_T - MatchDay.RUSH_LEAD, "the clock had not run down")

	# full time: not before a minute of the match, and not before the line
	var home := MatchDay.new()
	home.phase = MatchDay.Ph.MATCH
	home.match_t = MatchDay.FULLTIME_WAIT - 1.0
	home.advance(0.5, MatchDay.FULLTIME_Y + 50.0, gate, true)
	_check(home.phase == MatchDay.Ph.MATCH, "full time waits out the minute")
	home.match_t = MatchDay.FULLTIME_WAIT
	home.advance(0.1, MatchDay.FULLTIME_Y - 80.0, gate, true)
	_check(home.phase == MatchDay.Ph.MATCH, "full time waits until they pass -3000 going home")
	home.advance(0.1, MatchDay.FULLTIME_Y + 20.0, gate, true)
	_check(home.phase == MatchDay.Ph.FULLTIME, "passing -3000 on the way home is full time")
	_check(MatchDay.LITTER.size() == 6, "six bits of litter")


func _drain() -> void:
	var edges := Callable(self, "_edges")
	var river := CrowdRiver.new()
	river.setup(3, CrowdRiver.CAP)
	river.step(0.016, -2000.0, Vector2(640, -2000), Vector2(680, -1940), PackedVector2Array(), 0.0, [], edges)
	_check(river.active_count() > 100, "the avenue is full before the whistle (%d)" % river.active_count())
	river.flow_mode = CrowdRiver.MODE_DRAIN
	for i in range(int(MatchDay.DRAIN_T * 60.0)):
		river.step(1.0 / 60.0, -2000.0, Vector2(640, -2000), Vector2(680, -1940), PackedVector2Array(), 0.0, [], edges)
	_check(river.active_count() == 0, "the streets are empty within the drain (%d left)" % river.active_count())
	river.flow_mode = CrowdRiver.MODE_LATE
	river.step(0.016, -2000.0, Vector2(640, -2000), Vector2(680, -1940), PackedVector2Array(), 0.0, [], edges)
	_check(river.active_count() == CrowdRiver.LATE_N, "a few stragglers (%d)" % river.active_count())


func _live() -> void:
	var game = root.get_node("Game")
	game.persist = false
	root.get_node("Sfx").muted = true
	game.level_id = "partit"
	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	for k in range(3):
		await physics_frame
	m._skip_title()
	m.tip_t = 0.0
	for k in range(5):
		await physics_frame
	var snacks: int = m.kebabs.size()
	m.match_day.walk_t = MatchDay.KICKOFF_T - MatchDay.RUSH_LEAD - 0.2
	for k in range(20):
		await physics_frame
	m._update_hud()
	_check(m.match_day.phase == MatchDay.Ph.RUSH, "the walk enters the rush")
	_check(m.hud_status == "KICK-OFF SOON", "the banner says KICK-OFF SOON")
	m.match_day.walk_t = MatchDay.KICKOFF_T - 0.2
	for k in range(20):
		await physics_frame
	_check(m.match_day.phase == MatchDay.Ph.KICKOFF, "the whistle has gone")
	_check(m.kebabs.size() == snacks + MatchDay.LITTER.size(), "the avenue is strewn")
	_check(m.human.match_on and is_equal_approx(m.human.match_pace, MatchDay.MATCH_PACE),
		"the phone is the match, and they walk a little slower")

	# the bar, telegraphed, then the drift
	m.match_day.phase = MatchDay.Ph.MATCH
	m.human.match_on = true
	m.human.state = m.human.HState.WALK
	m.human.telegraph_t = 0.0
	m.human.bar_done = false
	m.human.bar_armed = false
	m.human.bar_watching = false
	m.human.mutter_t = 8.0
	m.human.global_position = Vector2(640.0, -1950.0)
	m.dog.global_position = Vector2(700.0, -1900.0)
	m.leash.resnap()
	var saw := false
	for k in range(70):
		await physics_frame
		if m.human.state == m.human.HState.WALK and m.human.telegraph_t > 0.0 and "replay" in m.human.bubble.text:
			saw = true
		if saw and m.human.state == m.human.HState.DRIFT:
			break
	_check(saw, "the replay is telegraphed before they move")
	_check(m.human.state == m.human.HState.DRIFT, "then they drift to the window")
