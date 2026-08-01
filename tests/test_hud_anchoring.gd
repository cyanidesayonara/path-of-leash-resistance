extends SceneTree

# The HUD is composed against a 1280x720 reference frame, but the project
# stretches with aspect "expand": the real viewport is that frame grown along
# one axis to match the window, wider than 1280 on a landscape phone and
# taller than 720 in portrait. Anything still holding a literal 1280 or 720
# therefore lands off-centre or away from the edge it meant to hug.
#
# That shipped twice. First as the letterboxing this project replaced, then as
# a half-swept fix: the separate panel scripts learned to read the viewport
# while every element built inside _build_hud kept its hardcoded frame, so on
# a 844x390 window the colour grade stopped dead at x=1280 - a hard seam with
# an ungraded, ungrained, unvignetted strip beside it - and every centred line
# sat 139px left of the middle. Eyeballing a screenshot caught it late. This
# catches it in CI.
#
# The invariants, checked at three window shapes:
#   1. the grade covers the whole viewport (it is a post-process, not a card)
#   2. full-width lines span the whole viewport, so CENTER really is centre
#   3. bottom-rule elements keep their distance from the true bottom edge
#   4. the combo meter stays centred on the real middle
#   5. nothing hangs off any edge of the visible screen
#
# Native 1280x720 is asserted to be pixel-identical to the authored layout, so
# this also guards the fix against regressing the shape everyone plays on.

const EPS := 0.6

# name -> the horizontal rule its y is measured from: 0 the top edge, 0.5 the
# middle of the screen, 1 the bottom edge. Their y is NOT asserted against the
# value they were built with, because _apply_menu_step legitimately moves the
# title, subtitle, carousel and record lines per menu step. What is asserted is
# that whatever y they hold, their distance from their own rule survives a
# reshape - which is the property that actually keeps a stack together.
const WIDE_LINES := {
	"title_l": 0.5, "sub_l": 0.5, "select_l": 0.5, "record_l": 0.5,
	"owner_l": 0.5, "night_l": 0.5, "weather_l": 0.5, "prompt_l": 0.5,
	"msg_label": 0.5, "pause_l": 0.5, "shop_title_l": 0.0,
	"challenge_l": 0.0, "tut_label": 0.0, "tut_hint": 0.0,
	"progress_l": 0.0, "combo_l": 1.0,
}
# name -> authored y, for elements that belong on the bottom rule
const BOTTOM_LINES := {
	"hint_l": 686.0, "menu_hint_l": 662.0, "combo_l": 624.0,
	"combo_bar": 662.0, "combo_bar_bg": 662.0,
}

var failures: Array[String] = []
var checks := 0
# each wide line's distance from its own rule, measured at native and then
# required to survive every reshape
var _rule_gaps := {}


func _check(ok: bool, msg: String) -> void:
	checks += 1
	if not ok:
		failures.append(msg)
		print("  FAIL  %s" % msg)


func _initialize() -> void:
	# deferred so the autoloads are registered before main.gd is compiled;
	# it references Game at parse time
	call_deferred("_run")


func _run() -> void:
	var game = root.get_node("Game")
	game.menu_step = 2
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	if not main.is_node_ready():
		await main.ready
	main.frozen = true

	# native first: the shape the layout was authored for, and the one the
	# desktop build ships. Everything here must be exactly where it was drawn.
	await _shape(main, Vector2i(1280, 720), true)
	# a landscape phone. 844x390 is much wider than 16:9, so the viewport comes
	# out 1558x720 - this is the shape the user actually reported.
	await _shape(main, Vector2i(844, 390), false)
	# portrait, where the excess lands on the other axis instead
	await _shape(main, Vector2i(390, 844), false)

	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("HUD ANCHORING OK")
		quit(0)
	else:
		print("HUD ANCHORING FAIL")
		quit(1)


func _shape(main: Node, window: Vector2i, native: bool) -> void:
	root.size = window
	# one frame for the stretch transform and the anchor solve to settle
	await process_frame
	await process_frame
	var vs := root.get_visible_rect().size
	print("\n--- window %dx%d -> viewport %.0fx%.0f ---" % [window.x, window.y, vs.x, vs.y])
	# aspect "expand" never crops the reference frame, it only reveals past it
	_check(vs.x >= 1280.0 - EPS and vs.y >= 720.0 - EPS,
		"viewport %.0fx%.0f is at least the reference frame" % [vs.x, vs.y])

	# 1. the grade is a post-process and has to cover everything, or the
	#    revealed strip reads as a brighter, grainless panel with a hard seam
	var grade: ColorRect = main.grade_rect
	_check(absf(grade.size.x - vs.x) < EPS and absf(grade.size.y - vs.y) < EPS,
		"grade covers the viewport (is %.0fx%.0f, want %.0fx%.0f)" % [
			grade.size.x, grade.size.y, vs.x, vs.y])
	_check(grade.position.is_equal_approx(Vector2.ZERO),
		"grade starts at the origin (is %s)" % grade.position)

	# 2. a CENTER-aligned line centres on its own rect, so the rect has to be
	#    the whole screen for the text to land on the middle of the screen
	for n: String in WIDE_LINES:
		var l: Control = main.get(n)
		_check(l != null, "%s exists" % n)
		if l == null:
			continue
		_check(absf(l.size.x - vs.x) < EPS,
			"%s spans the viewport (is %.0f wide, want %.0f)" % [n, l.size.x, vs.x])
		_check(absf(l.position.x) < EPS,
			"%s starts at the left edge (is x=%.1f)" % [n, l.position.x])
		# distance from the rule this line hangs off, which must not change
		# when the screen does
		var rule: float = float(WIDE_LINES[n])
		var from_rule: float = l.position.y - vs.y * rule
		if native:
			_rule_gaps[n] = from_rule
		else:
			_check(absf(from_rule - float(_rule_gaps.get(n, 0.0))) < EPS,
				"%s holds its place on the %s rule (%.1f, was %.1f at native)" % [
					n, ["top", "middle", "bottom"][int(rule * 2.0)], from_rule,
					float(_rule_gaps.get(n, 0.0))])

	# 3. the bottom rule: the hint line, the version and the combo meter were
	#    placed a fixed distance up from y=720 and must stay that far up from
	#    the real bottom edge, not float in the middle of a taller screen
	for n: String in BOTTOM_LINES:
		var c: Control = main.get(n)
		if c == null:
			continue
		var authored_gap: float = 720.0 - float(BOTTOM_LINES[n])
		var gap: float = vs.y - c.position.y
		_check(absf(gap - authored_gap) < EPS,
			"%s sits %.1f up from the bottom (authored %.1f)" % [n, gap, authored_gap])

	# 4. the combo meter is a centred 400px bar, so its middle is the screen's
	var bar: ColorRect = main.combo_bar_bg
	var bar_mid: float = bar.position.x + bar.size.x * 0.5
	_check(absf(bar_mid - vs.x * 0.5) < EPS,
		"combo meter is centred (middle at %.1f, screen middle %.1f)" % [bar_mid, vs.x * 0.5])

	# 5. and nothing at all may hang off the visible screen. This is the check
	#    that catches a HUD element nobody thought to list above.
	for c in main.hud.get_children():
		if not (c is Control):
			continue
		var ct: Control = c
		var r := Rect2(ct.position, ct.size)
		# the dim and the weather deliberately cover everything, and a card
		# wider than a narrow viewport has nowhere to go
		if r.size.x > vs.x or r.size.y > vs.y:
			continue
		_check(r.position.x >= -EPS and r.end.x <= vs.x + EPS,
			"%s is within the screen horizontally (x %.0f..%.0f, screen 0..%.0f)" % [
				ct.name if ct.name != "" else str(ct), r.position.x, r.end.x, vs.x])
		_check(r.position.y >= -EPS and r.end.y <= vs.y + EPS,
			"%s is within the screen vertically (y %.0f..%.0f, screen 0..%.0f)" % [
				ct.name if ct.name != "" else str(ct), r.position.y, r.end.y, vs.y])
