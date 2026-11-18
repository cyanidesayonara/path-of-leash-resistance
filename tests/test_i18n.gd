extends SceneTree

# The menus and the walk HUD in English, Catalan and Spanish (hud/i18n.gd):
# every entry has all three, none is empty, and each translation keeps the
# English's format placeholders (in order) and Prompts tokens. Both faces
# draw every letter the translations use. A label set once re-fills when the
# language changes. Every goal, prize, delivery and chase line the game keeps
# in English has an entry. And no menu or HUD source passes an English
# literal straight to the screen: its words come from the table.

var checks := 0
var failures: Array[String] = []

const I := preload("res://hud/i18n.gd")
const Kit := preload("res://hud/ui_kit.gd")

# whole files whose every string literal is held to the rule, and single
# functions in files that also hold walk text (shouts and speech stay
# English for now)
const SCANNED := [
	"res://hud/menu_flow.gd", "res://hud/menu_screen.gd", "res://hud/settings_panel.gd",
	"res://hud/results_panel.gd", "res://hud/goals_card.gd", "res://hud/hud_panel.gd",
	"res://hud/rotate_prompt.gd", "res://hud/ui_kit.gd", "res://hud/event_feed.gd",
	"res://systems/losses.gd", "res://systems/tips.gd",
	"res://main.gd::_update_hud", "res://main.gd::_freedom_hint", "res://main.gd::dare_hint",
	"res://systems/goals.gd::quest_text", "res://systems/goals.gd::credit",
	"res://systems/goals.gd::finish_walk", "res://systems/goals.gd::finish_tutorial_walk",
	"res://systems/mood.gd::badge", "res://systems/mood.gd::take_onset",
	"res://systems/home_chase.gd::banner", "res://systems/freedom_games.gd::banner",
	"res://systems/freedom_games.gd::_next_name", "res://systems/freedom_games.gd::hints",
	"res://systems/squirrel_game.gd::banner", "res://systems/boss_gat.gd::status",
	"res://systems/boss_gat.gd::fight_status", "res://systems/boss_mamut.gd::status",
	"res://systems/boss_mamut.gd::fight_status", "res://systems/boss_drac.gd::status",
	"res://systems/boss_drac.gd::spout_hint", "res://systems/boss_lleons.gd::status",
	"res://systems/blai.gd::idle_status", "res://systems/metro.gd::idle_status",
	"res://systems/molina.gd::idle_status", "res://systems/diagonal.gd::idle_status",
	"res://systems/sarria.gd::idle_status", "res://systems/ciutadella.gd::urgent_status",
	"res://world/ferralla.gd::idle_status",
]
# literals in those that are not words for the player
const NOT_WORDS := ["HORIZONTAL_ALIGNMENT_LEFT", "TWEEN", "--shot", "font_size", "font_color"]
# THIS WALK's goal text room at 1280x720, scaled from its 16 px to 15 px
const GOAL_ROOM := 340.0
const GOAL_COUNT_ROOM := 49.0


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	_entries()
	_glyphs()
	_titles_fit()
	_bound_labels()
	_game_language()
	_coverage()
	_sources()
	I.set_language("en")
	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_i18n: OK")
		quit(0)
	else:
		quit(1)


func _placeholders(s: String) -> Array:
	var out := []
	for m in RegEx.create_from_string("%(\\.\\d+)?[dsf%]").search_all(s):
		out.append(m.get_string())
	return out


func _tokens(s: String) -> Array:
	var out := []
	for m in RegEx.create_from_string("\\{[a-z_]+\\}").search_all(s):
		out.append(m.get_string())
	out.sort()
	return out


func _entries() -> void:
	var key_ok := RegEx.create_from_string("^[a-z][a-z0-9_]*$")
	for k: String in I.T:
		_check(key_ok.search(k) != null, "'%s' is a snake_case key" % k)
		var e: Dictionary = I.T[k]
		for lang: String in I.LANGS:
			_check(e.has(lang) and String(e.get(lang, "")).strip_edges() != "", "'%s' has its %s" % [k, lang])
		var en := String(e.get("en", ""))
		for lang: String in ["ca", "es"]:
			var tr := String(e.get(lang, ""))
			_check(_placeholders(tr) == _placeholders(en),
				"'%s' (%s) keeps the placeholders %s in order (has %s)" % [k, lang, _placeholders(en), _placeholders(tr)])
			_check(_tokens(tr) == _tokens(en), "'%s' (%s) keeps the tokens %s" % [k, lang, _tokens(en)])
			_check(tr == tr.strip_edges() or en != en.strip_edges(), "'%s' (%s) has no stray spaces at its ends" % [k, lang])
			_check(tr.to_upper() == tr or en.to_upper() != en, "'%s' (%s) is in capitals like the English" % [k, lang])


func _glyphs() -> void:
	var faces := {"Bricolage Grotesque": load("res://fonts/BricolageGrotesque.ttf"), "Inter": load("res://fonts/Inter.ttf")}
	var seen := {}
	for k: String in I.T:
		for lang: String in ["ca", "es"]:
			for ch in String(I.T[k][lang]):
				seen[ch] = true
	for ch: String in seen:
		if ch == "\n":
			continue
		for face: String in faces:
			_check((faces[face] as Font).has_char(ch.unicode_at(0)), "%s draws '%s'" % [face, ch])


# A title is drawn as a heading that shrinks until it fits its card; no
# translation may need it smaller than the English does.
func _titles_fit() -> void:
	var titled := []
	for k: String in I.T:
		if k.begins_with("death_") or (k.begins_with("chase_") and (k.ends_with("_human") or k.ends_with("_dog"))):
			titled.append([k, 30, 660.0])
	for k in ["confirm_restart_title", "confirm_exit_title", "confirm_first_title", "confirm_basics_title"]:
		titled.append([k, 28, 460.0])
	for t: Array in titled:
		var en_title := String(I.T[t[0]].en).get_slice("\n", 0).replace("%s", "MOCHI")
		var en_px: int = Kit.heading_px(en_title, t[1], t[2])
		for lang: String in ["ca", "es"]:
			var title := String(I.T[t[0]][lang]).get_slice("\n", 0).replace("%s", "MOCHI")
			var px: int = Kit.heading_px(title, t[1], t[2])
			_check(px >= mini(en_px, t[1]), "'%s' (%s) fits its card at %d px like the English (%d px)" % [t[0], lang, px, en_px])
	# a goal's row on THIS WALK (two columns at 1280x720) clips, and does not
	# wrap: in 15 px terms it has GOAL_ROOM, less a count's room when the goal
	# counts, and a translation fits that even where the English does not
	var body: Font = load("res://fonts/Inter.ttf")
	for k: String in I.T:
		var row := k.begins_with("goal_") or k.begins_with("prize_") \
			or (k.begins_with("carry_") and not k.begins_with("carry_item_"))
		if not row:
			continue
		var limit := GOAL_ROOM - (GOAL_COUNT_ROOM if String(I.T[k].en).contains("%d") else 0.0)
		for lang: String in ["ca", "es"]:
			var w := _goal_w(body, String(I.T[k][lang]))
			_check(w <= limit + 0.5, "goal '%s' (%s) fits its row (%d > %d px): %s" % [k, lang, w, limit, I.T[k][lang]])


func _goal_w(f: Font, text: String) -> float:
	var s := text
	for ph in ["%d", "%s"]:
		s = s.replace(ph, "10")
	return f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x


func _bound_labels() -> void:
	I.set_language("en")
	var a := Label.new()
	var b := Label.new()
	I.set_text(a, "pause_title")
	I.set_text(b, "walk_goals", [2, 5])
	_check(a.text == "PAUSED" and b.text == "2 / 5 goals", "set_text writes the English (%s, %s)" % [a.text, b.text])
	I.set_language("ca")
	_check(a.text == "PAUSA" and b.text == "2 / 5 fites", "a change of language re-fills the label (%s, %s)" % [a.text, b.text])
	b.text = "something else"
	I.set_language("es")
	_check(a.text == "PAUSA" and b.text == "something else", "a label written to since keeps what it says")
	_check(I.t("no_such_key") == "no_such_key", "a missing key shows itself")
	a.free()
	b.free()
	I.refresh()
	_check(I._bound.is_empty(), "freed labels are forgotten")
	I.set_language("en")


func _game_language() -> void:
	var game: Node = root.get_node_or_null("Game")
	if game == null:
		return
	var keep: String = game.language
	game.language = "es"
	_check(I.language == "es" and I.t("menu_play") == "JUGAR", "the LANGUAGE setting moves the table")
	game.language = keep
	_check(I.language == keep, "and back")


func _english_set() -> Dictionary:
	var out := {}
	for k: String in I.T:
		out[String(I.T[k].en)] = k
	return out


func _coverage() -> void:
	var en := _english_set()
	# every goal's text in defs()
	var src := FileAccess.get_file_as_string("res://systems/goals.gd")
	var seg := src.substr(src.find("static func defs("), src.find("static func build_quests(") - src.find("static func defs("))
	var n := 0
	for m in RegEx.create_from_string("(?m)^\\t\\t\"([a-z_]+)\": \\{\"text\": \"((?:[^\"\\\\]|\\\\.)*)\"").search_all(seg):
		n += 1
		if m.get_string(1) == "clock":
			_check(en.has(m.get_string(2)) and en[m.get_string(2)] == "goal_clock", "the clock goal has an entry")
			continue
		_check(en.has(m.get_string(2)), "goal '%s' has an entry: %s" % [m.get_string(1), m.get_string(2)])
	_check(n > 100, "the goal list was read (%d goals)" % n)
	# every walk's prize and delivery, wherever it is set
	var setters := RegEx.create_from_string("(?:PRIZE_TEXT :=|prize_text =|prize_text :=|carry_text =|carry_text :=|carry_item =|carry_item :=) \"((?:[^\"\\\\]|\\\\.)*)\"")
	var files: Array[String] = ["res://main.gd", "res://world/level_build.gd"]
	for f in DirAccess.get_files_at("res://systems"):
		if f.ends_with(".gd"):
			files.append("res://systems/" + f)
	var prizes := 0
	for path in files:
		for m in setters.search_all(FileAccess.get_file_as_string(path)):
			prizes += 1
			_check(en.has(m.get_string(1)), "%s: '%s' has an entry" % [path, m.get_string(1)])
	_check(prizes > 40, "the prizes were read (%d)" % prizes)
	# every chase's banners and catch cards
	var HomeChase: GDScript = load("res://systems/home_chase.gd")
	for kind: String in ["sweeper", "bolt", "both", "boars", "correfoc", "dimoni", "security", "goat", "groomer", "vet", "flood"]:
		var b: Dictionary = HomeChase.kind_behavior(kind)
		for field: String in b:
			if field.ends_with("_banner") or field.begins_with("caught_human") or field.begins_with("caught_dog"):
				_check(en.has(String(b[field])), "chase %s %s has an entry" % [kind, field])
	I.set_language("ca")
	_check(I.of_english("THE SWEEPER GOT YOUR HUMAN\n\nThey never once looked up from the phone.\nYou did try to tell them.").begins_with("ESCOMBRADORA"),
		"of_english finds a catch card")
	_check(I.of_english("PROBE") == "PROBE", "of_english leaves unknown text alone")
	I.set_language("en")


func _scan_lines(spec: String) -> Array:
	var parts := spec.split("::")
	var lines := FileAccess.get_file_as_string(parts[0]).split("\n")
	if parts.size() == 1:
		return lines
	var out := []
	var inside := false
	var head := RegEx.create_from_string("^(static )?func %s\\(" % parts[1])
	for l: String in lines:
		if inside and (l.begins_with("func ") or l.begins_with("static func ") or l.begins_with("const ")):
			break
		if head.search(l) != null:
			inside = true
		if inside:
			out.append(l)
	_check(not out.is_empty(), "%s was found to scan" % spec)
	return out


func _sources() -> void:
	var literal := RegEx.create_from_string("\"((?:[^\"\\\\]|\\\\.)*)\"")
	# words for a player: two words with a space between, or a word in capitals
	var sentence := RegEx.create_from_string("[A-Za-z]{2,}[^\"]* [^\"]*[A-Za-z]{2,}")
	var caps := RegEx.create_from_string("^[^a-z]*[A-Z]{2,}[^a-z]*$")
	# and a lone lower-case word handed to a draw or a label
	var sink := RegEx.create_from_string("(draw_string|heading|_label|\\.text =|toast|set_text)\\(?")
	var lone := RegEx.create_from_string("^[a-z]{3,}$")
	for spec: String in SCANNED:
		var lines := _scan_lines(spec)
		for i in range(lines.size()):
			var line := String(lines[i]).strip_edges()
			# a tool's own report, a browser call: not the player's screen
			if line.begins_with("#") or line.begins_with("print(") or line.begins_with("push_") \
					or line.begins_with("p.append(") or line.contains("JavaScriptBridge") or line.begins_with("% ["):
				continue
			for m in literal.search_all(line):
				var s := m.get_string(1)
				if s in NOT_WORDS or I.has(s) or s.begins_with("res://") or s.begins_with("user://"):
					continue
				# a key, an accent's name, a dictionary key or a prompt's action
				if line.contains("I18n.t(\"%s\"" % s) or line.contains("I18n.has(\"%s\"" % s) \
						or line.contains("accent(\"%s\")" % s) or line.contains("\"%s\":" % s) \
						or line.contains("[\"%s\"," % s) or s.contains("screen.orientation"):
					continue
				var words := sentence.search(s) != null or caps.search(s) != null \
					or (sink.search(line) != null and lone.search(s) != null and s != "goal" and s != "mood")
				_check(not words, "%s: '%s' is English straight to the screen; use I18n" % [spec, s])
	_banner_sinks()


# Whatever file it is in, a literal handed to the banner, the owner's news or
# a toast is English on the HUD.
func _banner_sinks() -> void:
	var sinks := RegEx.create_from_string(
		"owner_news\\(\"|set_banner\\(\"[^\"]|\\.flash\\(\"|hud_status = \"[^\"]|"
		+ "_show_bubble\\(\"(?:[^\"\\\\]|\\\\.)*\",\\s*\"|\\.toast\\(\"\\w+\",\\s*\"")
	var files: Array[String] = []
	for dir: String in ["res://", "res://autoload", "res://entities", "res://systems", "res://hud", "res://world"]:
		for f in DirAccess.get_files_at(dir):
			if f.ends_with(".gd"):
				files.append(dir.path_join(f))
	_check(files.size() > 100, "the banner scan found the game's scripts (%d)" % files.size())
	for path in files:
		var lines := FileAccess.get_file_as_string(path).split("\n")
		var bad := ""
		for i in range(lines.size()):
			var line := String(lines[i]).strip_edges()
			if not line.begins_with("#") and sinks.search(line) != null:
				bad += "\n  %d: %s" % [i + 1, line]
		_check(bad == "", "%s hands the banner English:%s" % [path, bad])
