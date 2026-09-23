extends RefCounted

# Goals and scoring: each walk's fixed goal list (Tony Hawk style), crediting a
# goal the moment it completes, the goal card's contents, and the end of the
# walk (results card, records, unlocks, the daily card).
#
# Static functions over main's state. main.gd keeps same-name forwarders for
# everything other scripts and tests call (_goal_defs, _credit_goal,
# _finish_walk, goal_card_data, results_data, ...), and LEVEL_GOAL_IDS as an
# alias, so every existing path to them still works.

const EventFeed := preload("res://hud/event_feed.gd")
const UiIcons := preload("res://hud/ui_icons.gd")

const LEVEL_GOAL_IDS := {
	"street": ["mark", "sniff", "phone", "paws", "bag", "fetch", "tofu", "close", "fling", "carry", "combo", "prize"],
	"park": ["mark", "sniff", "phone", "paws", "bag", "fetch", "tofu", "hi", "drink", "combo", "prize"],
	"beach": ["mark", "sniff", "phone", "paws", "bag", "fetch", "tofu", "snack", "save", "combo", "prize"],
	"rain": ["mark", "sniff", "phone", "paws", "bag", "fetch", "tofu", "close", "drink", "combo", "prize"],
	"market": ["mark", "sniff", "phone", "paws", "bag", "fetch", "tofu", "snack", "zoom", "carry", "combo", "prize"],
	"oldtown": ["mark", "sniff", "phone", "paws", "bag", "fetch", "tofu", "cats", "snack", "combo", "prize"],
	"trail": ["mark", "sniff", "phone", "paws", "bag", "fetch", "tofu", "chase", "drink", "combo", "prize"],
	"station": ["mark", "sniff", "phone", "paws", "bag", "fetch", "tofu", "close", "snack", "combo", "prize"],
	"site": ["mark", "sniff", "phone", "paws", "bag", "fetch", "tofu", "close", "snack", "combo", "prize"],
	"spook": ["mark", "sniff", "phone", "paws", "bag", "fetch", "tofu", "tummy", "snack", "combo", "prize"],
	"scrap": ["mark", "sniff", "phone", "paws", "bag", "fetch", "tofu", "ghost", "unseen", "combo", "prize"],
	# El Parc leans on what the terraces are for: carving them (fling) and
	# riding the serpentine bench (combo), plus the park staples.
	"guell": ["mark", "sniff", "phone", "paws", "bag", "fetch", "tofu", "hi",
		"drink", "fling", "combo", "prize"],
}


static func defs(m: Node2D) -> Dictionary:
	# every goal the game knows, keyed by a stable id (persistence-facing)
	return {
		"mark": {"text": "claim %d spots", "target": 5, "fn": func() -> int: return m.marks.size()},
		"sniff": {"text": "%d proper sniffs", "target": 4, "fn": func() -> int: return m.sniffs_done},
		"phone": {"text": "get the phone home unscratched", "target": 1, "fn": func() -> int: return 1 if m.phone_hp == 3 else 0},
		"paws": {"text": "come home unscathed yourself", "target": 1, "fn": func() -> int: return 1 if m.dog_hits == 0 else 0},
		"bag": {"text": "have your business bagged", "target": 1, "fn": func() -> int: return 1 if m.poop_state == 2 and not m.bag_pending else 0},
		"fetch": {"text": "fetch %d balls back", "target": 3, "fn": func() -> int: return m.romp_catches},
		"tofu": {"text": "bring Tofu home", "target": 1, "fn": func() -> int: return 1 if m.tofu_home else 0},
		"hi": {"text": "greet %d other dogs", "target": 3, "fn": func() -> int: return m.dogs_greeted},
		"drink": {"text": "have a proper long drink", "target": 1, "fn": func() -> int: return 1 if m.drunk_amount >= 0.4 else 0},
		"zoom": {"text": "run the zoomies right out", "target": 1, "fn": func() -> int: return 1 if m.dog.energy <= 0.25 else 0},
		"chase": {"text": "see off %d critters", "target": 2, "fn": func() -> int: return m.squirrels_chased},
		"close": {"text": "%d near misses with traffic", "target": 3, "fn": func() -> int: return m.close_calls},
		"save": {"text": "haul the human clear %d times", "target": 2, "fn": func() -> int: return m.saves_done},
		"fling": {"text": "tetherball the human off a pole", "target": 1, "fn": func() -> int: return m.flings_done},
		"tangle": {"text": "tangle leashes with a stranger", "target": 1, "fn": func() -> int: return 1 if m.tangles >= 1 else 0},
		"snack": {"text": "hoover up %d dropped snacks", "target": 2, "fn": func() -> int: return m.kebabs_eaten},
		"cats": {"text": "see off %d wall cats", "target": 3, "fn": func() -> int: return m.wall_cats_spooked},
		"carry": {"text": m.carry_text, "target": 1, "fn": func() -> int: return 1 if m.carry_state >= 2 else 0},
		"combo": {"text": "land an x%d combo", "target": 5, "fn": func() -> int: return int(m.combo.best_mult) if m.combo != null else 0},
		"tummy": {"text": "walk past every chocolate", "target": 1, "fn": func() -> int: return 1 if m.candy_eaten == 0 else 0},
		"ghost": {"text": "cross the yard, wake nobody", "target": 1, "fn": func() -> int: return 1 if m.guards_woken == 0 else 0},
		"unseen": {"text": "never once be spotted", "target": 1, "fn": func() -> int: return 1 if m.times_spotted == 0 else 0},
		"prize": {"text": m.prize_text, "target": 1, "fn": func() -> int: return 1 if m.prize_taken else 0},
	}


static func build_quests(m: Node2D) -> void:
	# a fixed ~10-goal list per level (Tony Hawk style): completing a goal
	# on any run marks it done for that level forever. Repeating goals,
	# a couple of level flavours, and the unique hazardous prize.
	if m.tutorial_mode:
		m.active_quests.clear()
		m.tofu_quest_active = false
		return
	var all := defs(m)
	var ids: Array = LEVEL_GOAL_IDS.get(m.lvl, LEVEL_GOAL_IDS["street"])
	for id in ids:
		var d: Dictionary = all[id]
		m.active_quests.append({
			"id": id, "text": d.text, "target": int(d.target), "fn": d.fn,
			"was_true": int(d.fn.call()) >= int(d.target),
		})
	m.tofu_quest_active = ("tofu" in ids) and not Game.goal_done(m.lvl, "tofu")


static func quest_text(q: Dictionary) -> String:
	var s: String = q.text
	if "%d" in s:
		s = s % int(q.target)
	return s


static func credit(m: Node2D, q: Dictionary) -> void:
	# award + persist a goal the first time it completes this run
	if m.tutorial_mode:
		return
	var id: String = q.id
	if m.run_goals_hit.has(id):
		return
	m.run_goals_hit[id] = true
	m._peek_goals()
	m.bones += 5
	var newly: bool = Game.mark_goal(m.lvl, id) if not Game.daily else false
	var tag := "GOAL! " if (newly or Game.daily) else "goal (again) "
	m.feed.say(tag + quest_text(q), EventFeed.Tone.GOOD)


static func check(m: Node2D) -> void:
	# accumulate goals credit the moment they cross target; "maintain"
	# goals (true from the start, e.g. unscratched phone) are only judged
	# at the finish so they cannot auto-complete on frame one
	for q in m.active_quests:
		if q.was_true or m.run_goals_hit.has(q.id):
			continue
		if int(q.fn.call()) >= int(q.target):
			m._credit_goal(q)


static func card_data(m: Node2D) -> Dictionary:
	# The card draws whatever this returns. Open goals sort to the top so the
	# live ones are always on screen, and finished ones stay in the list
	# rather than vanishing - which is what made the row count wobble between
	# runs and the card jump about.
	var total: int = m.active_quests.size()
	var done_count: int = m.run_goals_hit.size() if Game.daily else Game.goals_count(m.lvl)
	done_count = mini(done_count, total)
	var open_rows: Array = []
	var done_rows: Array = []
	for q in m.active_quests:
		var persisted: bool = (not Game.daily) and Game.goal_done(m.lvl, q.id)
		var hit: bool = m.run_goals_hit.has(q.id)
		var target := int(q.target)
		if hit or persisted:
			done_rows.append({
				"text": quest_text(q), "target": target, "got": target,
				# banked this run reads brighter than banked on a past walk
				"state": UiIcons.Check.DONE_NOW if hit else UiIcons.Check.DONE_BEFORE,
			})
		else:
			var got: int = mini(int(q.fn.call()), target)
			open_rows.append({
				"text": quest_text(q), "target": target, "got": got,
				"state": UiIcons.Check.PARTIAL if got > 0 else UiIcons.Check.OPEN,
			})
	var rows: Array = open_rows + done_rows
	var shown: int = mini(rows.size(), m.GOALS_MAX_ROWS)
	var open: bool = Game.goals_expanded or m.goals_peek > 0.0
	return {
		"done": done_count, "total": total,
		"all_done": total > 0 and done_count >= total,
		"rows": rows.slice(0, shown) if open else [],
		"extra": (rows.size() - shown) if open else 0,
		"open": open, "peeking": m.goals_peek > 0.0 and not Game.goals_expanded,
		"key": m._kb_or_pad("TAB", "up"),
	}


static func finish_walk(m: Node2D) -> void:
	if m.dog.global_position.y > m.HOME_Y and m.human.global_position.y > m.HOME_Y:
		if m.tutorial_mode:
			m._finish_tutorial_walk()
			return
		m.finished = true
		if m.auto_walk:
			print("AUTOWALK FINISHED the whole walk at t=%.1f" % m.elapsed)
		m.frozen = true
		m.dim.visible = true
		m.msg_label.visible = true
		# credit any goal still satisfied at the finish (catches the
		# "maintain" goals like unscratched phone / clean paws)
		for q in m.active_quests:
			if not m.run_goals_hit.has(q.id) and int(q.fn.call()) >= int(q.target):
				m._credit_goal(q)
		var run_done: int = m.run_goals_hit.size()
		var total: int = m.active_quests.size()
		var rows: Array = m._results_rows()
		var lifetime: int = run_done if Game.daily else Game.goals_count(m.lvl)
		# total == 0 made this TRUE, which is how a walk with no goal list
		# banked a PERFECT for The Boulevard. The tutorial no longer reaches
		# this path at all, but the trap should not be left armed.
		var perfect := total > 0 and run_done >= total
		var rating := ""
		if run_done == 0:
			rating = "...well. A dog, anyway."
		elif perfect:
			rating = "PERFECT WALK - every goal in one go"
		var rec: Dictionary = Game.record_result("daily" if Game.daily else m.lvl, m.bones, m.elapsed, perfect)
		var lines: Array = []
		var star_gain: int = Game.stars(m.lvl) - m.run_pre_level_stars
		var head := ""
		if star_gain > 0 and not Game.daily:
			head += "+%d STAR%s   " % [star_gain, "" if star_gain == 1 else "S"]
		if rec.bones_record:
			head += "NEW BONES RECORD   "
		if rec.time_record:
			head += "BEST TIME"
		if head != "":
			lines.append(head.strip_edges())
		lines.append("%d/%d goals here    %d stars in all    %d bones banked"
			% [lifetime, total, Game.total_stars(), Game.total_bones])
		if m.combo.best_mult >= 2:
			lines.append("best combo x%d    style %d" % [m.combo.best_mult, m.combo.run_style])
		if m.overmarks > 0:
			lines.append("%d spot%s over-marked. They will know."
				% [m.overmarks, "" if m.overmarks == 1 else "s"])
		if not Game.daily:
			for other in Game.LEVELS:
				if Game.gate_crossed(m.run_pre_total_stars, other):
					lines.append("NEW WALK UNLOCKED: %s" % Game.LEVEL_NAMES[other])
		if Game.daily:
			_build_daily_card(m, run_done, total, rec)
		else:
			m.results = {
				"title": "VERY GOOD DOG." if perfect else "GOOD DOG.", "stars": Game.stars(m.lvl),
				"rating": rating,
				"rows": rows, "bones": m.bones, "phone": m.phone_hp, "time": int(m.elapsed),
				"goal_bones": run_done * 5, "lines": lines,
				"prompt": "press  %s  for another walk" % m._kb_or_pad("R", "Start"),
			}
			m.msg_label.visible = false
			m.results_card.visible = true
			# the in-walk HUD would otherwise sit on top of the card
			m.goals_card.visible = false
			m.panel.visible = false


static func finish_tutorial_walk(m: Node2D) -> void:
	m.finished = true
	m.frozen = true
	m.dim.visible = true
	m.msg_label.visible = false
	m.results = {
		"title": "GOOD DOG.",
		"stars": 0,
		"rating": "You know the ropes.",
		"rows": [],
		"bones": m.bones,
		"phone": m.phone_hp,
		"time": int(m.elapsed),
		"goal_bones": 0,
		"lines": [
			"%d practice bones - not banked" % m.bones,
			"Lessons complete. The real walks are waiting.",
		],
		"prompt": "press  %s  for walk select" % m._kb_or_pad("R", "Start"),
	}
	m.results_card.visible = true
	m.goals_card.visible = false
	m.panel.visible = false
	m.tut_label.visible = false
	m.tut_hint.visible = false


static func results_rows(m: Node2D) -> Array:
	var rows: Array = []
	for q in m.active_quests:
		var hit: bool = m.run_goals_hit.has(q.id)
		var had: bool = (not Game.daily) and Game.goal_done(m.lvl, q.id) and not hit
		var target := int(q.target)
		var got: int = mini(int(q.fn.call()), target)
		var st: int = UiIcons.Check.OPEN
		if hit:
			st = UiIcons.Check.DONE_NOW
		elif had:
			st = UiIcons.Check.DONE_BEFORE
		elif got > 0:
			st = UiIcons.Check.PARTIAL
		rows.append({"text": quest_text(q), "state": st, "got": got, "target": target})
	return rows


static func _build_daily_card(m: Node2D, run_done: int, total: int, rec: Dictionary) -> void:
	# a compact, screenshot-friendly summary of today's shared walk, with a
	# one-line share text the player can copy to the clipboard
	var d := Time.get_date_dict_from_system()
	var date_str := "%04d-%02d-%02d" % [d.year, d.month, d.day]
	var stars_n: int = Game._milestone_stars(run_done)
	var weather_bit: String = String(Game.WEATHER_NAMES[Game.weather]).to_lower()
	var when_bit := "night" if Game.night else "day"
	var combo_bit: String = "  combo x%d" % m.combo.best_mult if m.combo.best_mult >= 2 else ""
	m.daily_share = "Path of Leash Resistance - Daily %s\n%s, %s, %s\n%s  %d/%d goals  %d bones  %ds%s" % [
		date_str, Game.LEVEL_NAMES[m.lvl], weather_bit, when_bit,
		Game.star_str(stars_n), run_done, total, m.bones, int(m.elapsed), combo_bit]
	var best_line := "NEW DAILY BEST!\n\n" if rec.bones_record else ""
	m.daily_copied = false
	m.msg_label.text = "TODAY'S WALK\n\n%s\n\n%sPress %s to copy & share\nPress %s for another go" % [
		m.daily_share, best_line, m._kb_or_pad("C", "Y"), m._kb_or_pad("R", "Start")]
