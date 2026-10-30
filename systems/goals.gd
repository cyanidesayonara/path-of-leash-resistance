extends RefCounted

# Goals and scoring: each walk's fixed goal list (Tony Hawk style), crediting a
# goal the moment it completes, the goal card's contents, and the end of the
# walk (results card, records, unlocks).
#
# Static functions over main's state. main.gd keeps same-name forwarders for
# everything other scripts and tests call (_goal_defs, _credit_goal,
# _finish_walk, goal_card_data, results_data, ...), and LEVEL_GOAL_IDS as an
# alias, so every existing path to them still works.

const EventFeed := preload("res://hud/event_feed.gd")
const UiIcons := preload("res://hud/ui_icons.gd")
const HomeChase := preload("res://systems/home_chase.gd")
const TonyHawk := preload("res://systems/tony_hawk.gd")
const LEVEL_GOAL_IDS := {
	# El Barri, the everyday walk: the staples and nothing exotic
	"barri": ["mark", "sniff", "phone", "paws", "bag", "fetch", "tofu", "hi", "drink", "combo", "prize", "spell", "tape", "clock"],
	# La Rambla trades the traffic near-misses for its pickpockets
	"street": ["mark", "sniff", "phone", "paws", "bag", "fetch", "tofu", "thief", "wallet", "fling", "carry", "combo", "prize", "spell", "tape", "clock"],
	"park": ["mark", "sniff", "phone", "paws", "bag", "fetch", "tofu", "hi", "drink", "combo", "prize", "spell", "tape", "clock"],
	"beach": ["mark", "sniff", "phone", "paws", "bag", "fetch", "tofu", "snack", "save", "combo", "prize", "spell", "tape", "clock"],
	# El Diluvi: keep your human out of the worst of it, splash the rest
	"rain": ["mark", "sniff", "phone", "paws", "bag", "fetch", "tofu", "dry", "splash", "combo", "prize", "spell", "tape", "clock"],
	"market": ["mark", "sniff", "phone", "paws", "bag", "fetch", "tofu", "snack", "zoom", "carry", "combo", "prize", "spell", "tape", "clock"],
	"oldtown": ["mark", "sniff", "phone", "paws", "bag", "fetch", "tofu", "cats", "snack", "somni", "combo", "prize", "spell", "tape", "clock"],
	"trail": ["mark", "sniff", "phone", "paws", "bag", "fetch", "tofu", "chase", "drink", "combo", "prize", "spell", "tape", "clock"],
	# L'Estacio: ride the walkway, squeeze through the barriers
	"station": ["mark", "sniff", "phone", "paws", "bag", "fetch", "tofu", "walkway", "snack", "combo", "prize", "spell", "tape", "clock"],
	"site": ["mark", "sniff", "phone", "paws", "bag", "fetch", "tofu", "close", "snack", "combo", "prize", "spell", "tape", "clock"],
	"spook": ["mark", "sniff", "phone", "paws", "bag", "fetch", "tofu", "tummy", "snack", "combo", "prize", "spell", "tape", "clock"],
	"scrap": ["mark", "sniff", "phone", "paws", "bag", "fetch", "tofu", "ghost", "unseen", "combo", "prize", "spell", "tape", "clock"],
	# El Parc leans on what the terraces are for: carving them (fling) and
	# riding the serpentine bench (combo), plus the park staples.
	"guell": ["mark", "sniff", "phone", "paws", "bag", "fetch", "tofu", "hi",
		"drink", "fling", "combo", "prize", "spell", "tape", "clock"],
	# La Neteja: the chase is the walk home, so no Tofu (the two never share
	# a home leg) and a goal for doing the chase WELL rather than just
	# surviving it, which finishing already proves.
	"neteja": ["mark", "sniff", "phone", "paws", "bag", "fetch", "hi", "snack",
		"combo", "prize", "outrun", "spell", "tape", "clock"],
	# El Besos: the way home is the flood. No Tofu, same as the other chase.
	"besos": ["mark", "sniff", "phone", "paws", "bag", "fetch", "combo", "prize", "floodgap", "dry", "spell", "tape", "clock"],
	# Montjuic: the climb, with the park staples
	"montjuic": ["mark", "sniff", "phone", "paws", "bag", "fetch", "tofu", "hi", "drink", "cable", "combo", "prize", "spell", "tape", "clock"],
	# Dia de Partit. No Tofu: the way home belongs to the final whistle.
	# No hi and no combo: twelve goals, and the fans' dogs are a greeting.
	"partit": ["mark", "sniff", "phone", "paws", "bag", "fetch", "snack", "march", "scarf", "kickabout", "fulltime", "prize", "spell", "tape", "clock"],
	# El Port: harbor wharf, seagulls, fish scraps, iron bollards
	"port": ["mark", "sniff", "phone", "paws", "bag", "fetch", "tofu", "snack", "gulls", "bollard", "combo", "prize", "spell", "tape", "clock"],
	# Plaça Reial: palm trees, Gaudi lampposts, Three Graces fountain, guitar busker
	"reial": ["mark", "sniff", "phone", "paws", "bag", "fetch", "tofu", "snack", "gaudi", "fountain", "combo", "prize", "spell", "tape", "clock"],
	# El Veterinari: clinic escape chase. No Tofu.
	"vet": ["mark", "sniff", "phone", "paws", "bag", "fetch", "hi", "snack", "scale", "cone", "combo", "prize", "spell", "tape", "clock"],
	# El Tibidabo: the mountain funicular & panoramic overlook
	"tibidabo": ["mark", "sniff", "phone", "paws", "bag", "fetch", "tofu", "snack", "funicular", "viewfinder", "combo", "prize", "spell", "tape", "clock"],
	# La Carretera de les Aigües: the bikes coming both ways, and the view
	"aigues": ["mark", "sniff", "phone", "paws", "bag", "fetch", "tofu", "hi", "drink", "bikes", "view", "combo", "prize", "spell", "tape", "clock"],
	# El Laberint d'Horta: round Eros, and the hedges to tetherball your human round
	"horta": ["mark", "sniff", "phone", "paws", "bag", "fetch", "tofu", "hi", "drink", "fling", "eros", "combo", "prize", "spell", "tape", "clock"],
	"llevant": ["mark", "sniff", "phone", "paws", "bag", "fetch", "tofu", "hi", "drink", "snack", "save", "combo", "prize", "spell", "tape", "clock"],
}


static func defs(m: Node2D) -> Dictionary:
	# every goal the game knows, keyed by a stable id (persistence-facing)
	return {
		"mark": {"text": "Mark %d spots", "target": 5, "fn": func() -> int: return m.marks.size()},
		"sniff": {"text": "Have %d good long sniffs", "target": 4, "fn": func() -> int: return m.sniffs_done},
		"phone": {"text": "Get the phone home without a scratch", "target": 1, "fn": func() -> int: return 1 if m.phone_hp == 3 else 0},
		"paws": {"text": "Get yourself home without a bump", "target": 1, "fn": func() -> int: return 1 if m.dog_hits == 0 else 0},
		"bag": {"text": "Get your business bagged", "target": 1, "fn": func() -> int: return 1 if m.poop_state == 2 and not m.bag_pending else 0},
		"fetch": {"text": "Bring the ball back %d times", "target": 3, "fn": func() -> int: return m.romp_catches},
		"tofu": {"text": "Bring Tofu the cat home", "target": 1, "fn": func() -> int: return 1 if m.tofu_home else 0},
		"hi": {"text": "Say hello to %d dogs", "target": 3, "fn": func() -> int: return m.dogs_greeted},
		"drink": {"text": "Have a good long drink", "target": 1, "fn": func() -> int: return 1 if m.drunk_amount >= 0.4 else 0},
		"cable": {"text": "Find a ticket and ride the telefèric", "target": 1, "fn": func() -> int: return mini(int(m.cable_rides), 1)},
		"zoom": {"text": "Run yourself tired", "target": 1, "fn": func() -> int: return 1 if m.dog.energy <= 0.25 else 0},
		"chase": {"text": "Chase off %d critters", "target": 2, "fn": func() -> int: return m.squirrels_chased},
		"close": {"text": "Scrape past traffic %d times", "target": 3, "fn": func() -> int: return m.close_calls},
		"save": {"text": "Haul your human out of trouble %d times", "target": 2, "fn": func() -> int: return m.saves_done},
		"fling": {"text": "Tetherball your human around a pole", "target": 1, "fn": func() -> int: return m.flings_done},
		"tangle": {"text": "Tangle leashes with a stranger", "target": 1, "fn": func() -> int: return 1 if m.tangles >= 1 else 0},
		"snack": {"text": "Scarf down %d dropped snacks", "target": 2, "fn": func() -> int: return m.kebabs_eaten},
		"cats": {"text": "Chase off %d cats on the walls", "target": 3, "fn": func() -> int: return m.wall_cats_spooked},
		"somni": {"text": "Visit El Somni gallery and claim the dream bone", "target": 1, "fn": func() -> int: return 1 if m.somni_bone_taken else 0},
		"carry": {"text": m.carry_text, "target": 1, "fn": func() -> int: return 1 if m.carry_state >= 2 else 0},
		"combo": {"text": "Land an x%d trick combo", "target": 3, "fn": func() -> int: return int(m.combo.best_mult) if m.combo != null else 0},
		"tummy": {"text": "Walk past every chocolate", "target": 1, "fn": func() -> int: return 1 if m.candy_eaten == 0 else 0},
		"ghost": {"text": "Cross the yard without waking anyone", "target": 1, "fn": func() -> int: return 1 if m.guards_woken == 0 else 0},
		"outrun": {"text": "Keep the sweeper a leash length away", "target": 1, "fn": func() -> int: return 1 if m.chase_min_gap >= HomeChase.OUTRUN_GAP else 0},
		"floodgap": {"text": "Keep the deep flood front a leash length away", "target": 1, "fn": func() -> int: return 1 if m.chase_min_gap >= HomeChase.OUTRUN_GAP else 0},
		"unseen": {"text": "Never get spotted", "target": 1, "fn": func() -> int: return 1 if m.times_spotted == 0 else 0},
		"walkway": {"text": "Ride the moving walkway end to end", "target": 1, "fn": func() -> int: return m.walkway_rides},
		"dry": {"text": "Get your human home less than half soaked", "target": 1, "fn": func() -> int: return 1 if m.human_soak < 0.5 else 0},
		"splash": {"text": "Splash through %d puddles at speed", "target": 4, "fn": func() -> int: return m.splashes},
		"thief": {"text": "Stop %d pickpockets", "target": 2, "fn": func() -> int: return m.thieves_stopped},
		"wallet": {"text": "Keep your human's wallet safe", "target": 1, "fn": func() -> int: return 0 if (m.owner_wallet_taken or m.owner_wallet_lost) else 1},
		"prize": {"text": m.prize_text, "target": 1, "fn": func() -> int: return 1 if m.prize_taken else 0},
		"fulltime": {"text": "Beat the crowd home", "target": 1, "fn": func() -> int: return 1 if m.match_day != null and m.match_day.beat else 0},
		"march": {"text": "Keep your human out of the away march", "target": 1, "fn": func() -> int: return 1 if m.march != null and m.march.passed and not m.march.caught else 0},
		"scarf": {"text": "Bring the lost scarf back", "target": 1, "fn": func() -> int: return 1 if m.lost_scarf != null and m.lost_scarf.back else 0},
		"kickabout": {"text": "Score a goal in the kids' street game", "target": 1, "fn": func() -> int: return 1 if m.kickabout != null and m.kickabout.scored else 0},
		"gulls": {"text": "Startle %d harbor seagulls into flight", "target": 3, "fn": func() -> int: return m.port_gulls_startled},
		"bollard": {"text": "Wrap the leash around an iron mooring bollard", "target": 1, "fn": func() -> int: return 1 if m.port_bollard_wrapped else 0},
		"gaudi": {"text": "Wrap the leash around a Gaudi dragon lamppost", "target": 1, "fn": func() -> int: return 1 if m.reial_gaudi_wrapped else 0},
		"fountain": {"text": "Drink fresh water from the Three Graces fountain", "target": 1, "fn": func() -> int: return 1 if m.reial_fountain_drank else 0},
		"scale": {"text": "Weigh in on the digital pet scale", "target": 1, "fn": func() -> int: return 1 if bool(m.get("vet_scale_weighed")) else 0},
		"cone": {"text": "Escape the vet without getting bumped", "target": 1, "fn": func() -> int: return 1 if bool(m.dog_hits == 0 and m.finished) else 0},
		"funicular": {"text": "Watch the vintage funicular climb the mountain", "target": 1, "fn": func() -> int: return 1 if m.tibidabo_funicular_seen else 0},
		"bikes": {"text": "Let %d mountain bikes squeak past your human", "target": 3, "fn": func() -> int: return m.close_calls},
		"view": {"text": "Get your human to look up at the view", "target": 1, "fn": func() -> int: return 1 if Aigues.view_taken(m) else 0},
		"eros": {"text": "Lead your human round Eros in the middle of the maze", "target": 1, "fn": func() -> int: return 1 if Horta.eros_lapped(m) else 0},
		"viewfinder": {"text": "Gaze through the panoramic cliffside viewfinder", "target": 1, "fn": func() -> int: return 1 if m.tibidabo_viewfinder_gazed else 0},
		"spell": {"text": "Spell %s" % (String(m.get("spell_word")) if String(m.get("spell_word")) != "" else TonyHawk.word_for(String(m.get("lvl")))), "target": String(m.get("spell_word")).length() if String(m.get("spell_word")) != "" else TonyHawk.word_for(String(m.get("lvl"))).length(), "fn": func() -> int: return int(m.get("word_letters_collected"))},
		"tape": {"text": "Find the secret tape", "target": 1, "fn": func() -> int: return 1 if bool(m.get("secret_tape_found")) else 0},
		"clock": {"text": "Beat the clock (under %ds)" % int(m.get("clock_target") if m.get("clock_target") != null else 75), "target": 1, "fn": func() -> int: return 1 if (bool(m.get("finished")) and float(m.get("elapsed")) <= float(m.get("clock_target") if m.get("clock_target") != null else 75)) else 0},
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
	# sentence case, whichever list the goal came from
	return s.substr(0, 1).to_upper() + s.substr(1)


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
	var newly: bool = Game.mark_goal(m.lvl, id)
	if newly:
		m.run_goals_new += 1
	# by the goal list, not in the middle of the screen: a first time is
	# gold, one already done on an earlier walk is quieter
	if Game.free_play:
		m.feed.toast("goal", "FREE PLAY  +5", quest_text(q), Color(0.98, 0.80, 0.38))
	elif newly:
		m.feed.toast("goal", "GOAL!  +5", quest_text(q), Color(0.98, 0.80, 0.38))
	else:
		m.feed.toast("goal", "DONE AGAIN  +5", quest_text(q), Color(0.58, 0.78, 0.62))


static func check(m: Node2D) -> void:
	# accumulate goals credit the moment they cross target; "maintain"
	# goals (true from the start, e.g. unscratched phone) are only judged
	# at the finish so they cannot auto-complete on frame one
	for q in m.active_quests:
		if q.was_true or m.run_goals_hit.has(q.id):
			continue
		if int(q.fn.call()) >= int(q.target):
			m._credit_goal(q)


# the goal list's rows on a peek when the interface is enlarged for a small screen
const GOALS_ROWS_SMALL := 4
# the opened card's tallest share of the screen, the height of its heading and
# padding, and its row heights (normal and tightened); hud/goals_card.gd draws
# with the same two row heights
const GOALS_MAX_H := 0.72
const GOALS_CARD_CHROME := 60.0
const GOALS_ROW_H := 21.0
const GOALS_ROW_COMPACT := 16.0


static func card_data(m: Node2D) -> Dictionary:
	# The card draws whatever this returns. Open goals sort to the top so the
	# live ones are always on screen, and finished ones stay in the list
	# rather than vanishing - which is what made the row count wobble between
	# runs and the card jump about.
	var total: int = m.active_quests.size()
	# only goals still on this walk's list count (one dropped from it may be
	# banked from before)
	var done_count := 0
	for q in m.active_quests:
		if Game.goal_done(m.lvl, q.id) or m.run_goals_hit.has(q.id):
			done_count += 1
	# open goals in three groups, each in the walk's own order: the ones
	# that count up (a meter and "0/5"), then the one-off finds and errands,
	# then the ones she keeps true to the end (the phone unscratched)
	var counting: Array = []
	var once: Array = []
	var keep: Array = []
	var done_rows: Array = []
	for q in m.active_quests:
		var persisted: bool = Game.goal_done(m.lvl, q.id)
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
			var group: Array = keep if bool(q.was_true) else (counting if target > 1 else once)
			group.append({
				"text": quest_text(q), "target": target, "got": got,
				"state": UiIcons.Check.PARTIAL if got > 0 else UiIcons.Check.OPEN,
			})
	var open_rows: Array = counting + once + keep
	var rows: Array = open_rows + done_rows
	var open: bool = Game.goals_expanded or m.goals_peek > 0.0
	# A peek (a goal just moved) is brief, so it keeps the short list: with a
	# phone's enlarged interface (hud/ui_scale.gd) a long one would cover a
	# third of the walk. Opened on purpose, the card lists every goal; rows
	# tighten to fit the screen and, only if even that is too tall, finished
	# goals fold into "+ N done" so an open goal is never hidden.
	var cap: int = m.GOALS_MAX_ROWS if float(m.ui_scale) <= 1.0 else GOALS_ROWS_SMALL
	var compact := false
	var folded_done := 0
	if Game.goals_expanded:
		var room: float = m.get_viewport().get_visible_rect().size.y * GOALS_MAX_H - GOALS_CARD_CHROME
		cap = rows.size()
		if float(rows.size()) * GOALS_ROW_H > room:
			compact = true
			var fit: int = maxi(open_rows.size(), int(room / GOALS_ROW_COMPACT))
			if rows.size() > fit:
				folded_done = rows.size() - fit
				cap = fit
	var shown: int = mini(rows.size(), cap)
	return {
		"done": done_count, "total": total,
		"all_done": total > 0 and done_count >= total,
		"rows": rows.slice(0, shown) if open else [],
		"extra": (rows.size() - shown) if open and folded_done == 0 else 0,
		"folded_done": folded_done if open else 0,
		"compact": compact and open,
		"open": open, "peeking": m.goals_peek > 0.0 and not Game.goals_expanded,
		"key": Prompts.key("goals"),
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
		# credit any goal still satisfied at the finish (catches the
		# "maintain" goals like unscratched phone / clean paws)
		for q in m.active_quests:
			if not m.run_goals_hit.has(q.id) and int(q.fn.call()) >= int(q.target):
				m._credit_goal(q)
		var run_done: int = m.run_goals_hit.size()
		var total: int = m.active_quests.size()
		var rows: Array = m._results_rows()
		var lifetime: int = Game.goals_count(m.lvl)
		# total == 0 made this TRUE, which is how a walk with no goal list
		# banked a PERFECT for The Boulevard. The tutorial no longer reaches
		# this path at all, but the trap should not be left armed.
		var perfect := total > 0 and run_done >= total
		var rating := ""
		if run_done == 0:
			rating = "...well. A dog, anyway."
		elif perfect:
			rating = "PERFECT WALK - every goal in one go"
		var rec: Dictionary = Game.record_result(m.lvl, m.bones, m.elapsed, perfect)
		var lines: Array = []
		var star_gain: int = Game.stars(m.lvl) - m.run_pre_level_stars
		var head := ""
		if Game.free_play:
			head += "FREE PLAY (PRACTICE)   "
		elif star_gain > 0:
			head += "+%d STAR%s   " % [star_gain, "" if star_gain == 1 else "S"]
		if rec.bones_record:
			head += "NEW BONES RECORD   "
		if rec.time_record:
			head += "BEST TIME"
		if head != "":
			lines.append(head.strip_edges())
		lines.append("%d/%d goals here    %d stars in all    %d bones banked"
			% [lifetime, total, Game.total_stars(), Game.total_bones])
		if m.lvl == "partit" and m.match_day != null and m.match_day.result != "":
			lines.append("the phone says %s" % MatchDay.score_line(m.match_day.result))
		if m.combo.best_mult >= 2:
			var best_style: bool = Game.record_style(m.lvl, int(m.combo.run_style))
			lines.append("best combo x%d    style %d%s" % [m.combo.best_mult, m.combo.run_style,
				"    BEST STYLE" if best_style else ""])
		if m.overmarks > 0:
			lines.append("%d spot%s over-marked. They will know."
				% [m.overmarks, "" if m.overmarks == 1 else "s"])
		for other in Game.LEVELS:
			if Game.gate_crossed(m.run_pre_total_stars, other):
				lines.append("NEW WALK UNLOCKED: %s" % Game.LEVEL_NAMES[other])
		m.results = {
			"title": "VERY GOOD DOG." if perfect else "GOOD DOG.", "stars": Game.stars(m.lvl),
			"rating": rating,
			"rows": rows, "bones": m.bones, "phone": m.phone_hp, "time": int(m.elapsed),
			"goal_bones": run_done * 5, "lines": lines,
		}
		m.msg_label.visible = false
		m.dim.visible = true
		if m.epilogue_stage != null:
			m.epilogue_stage.reset()
		m.results_card.visible = true
		# the in-walk HUD would otherwise sit on top of the card
		m.goals_card.visible = false
		m.panel.visible = false


# The first walk is done (at its end, or at the basics checkpoint): the title
# stops offering it first, and the bones earned learning are real ones - the
# first time only, or practising again would be a bone farm with no risk in
# it. True when they were banked.
static func complete_tutorial(m: Node2D) -> bool:
	var banked := not Game.tutorial_done
	if banked:
		Game.total_bones += m.bones
	Game.tutorial_done = true
	Game.save_records()
	return banked


static func finish_tutorial_walk(m: Node2D) -> void:
	var banked := complete_tutorial(m)
	m.finished = true
	m.frozen = true
	m.msg_label.visible = false
	m.dim.visible = true
	if m.epilogue_stage != null:
		m.epilogue_stage.reset()
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
			("%d bones banked" % m.bones) if banked else ("%d bones (banked the first time around)" % m.bones),
			"Next: El Barri, the everyday walk.",
		],
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
		var had: bool = Game.goal_done(m.lvl, q.id) and not hit
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
