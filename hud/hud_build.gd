extends RefCounted

# Builds the HUD: the colour-grade layer, the HUD canvas layer and every card,
# label and bar on it, plus the logic nodes created alongside (combo,
# challenge, mood, teeter, grind). Draw order is creation order, so the body is
# kept in exactly the order it had in main.gd; the results card is lifted
# above the dim explicitly (see the note by the dim).
#
# Static functions over main's state: every node is still assigned to the same
# field on main, which the rest of the game and the tests read. main.gd's
# _build_hud calls build() and then connects the joypad signal itself (a lambda
# created in a static function would never be disconnected on scene reload).

const Mood := preload("res://systems/mood.gd")

# the frame the HUD was composed against; see pin_wide / pin_box
const REF_W := 1280.0
const REF_H := 720.0


static func build(m: Node2D) -> void:
	# the colour grade sits over the world but UNDER the HUD, so the
	# interface stays crisp and unvignetted while the world gets graded
	var grade_layer := CanvasLayer.new()
	grade_layer.layer = 1
	m.add_child(grade_layer)
	m.grade_rect = ColorRect.new()
	# the whole viewport, not the reference frame: a fixed 1280x720 rect left
	# the strip that aspect "expand" reveals on a wide window completely
	# ungraded - no vignette, no grain, and visibly brighter than the picture
	# beside it
	m.grade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	m.grade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var gmat := ShaderMaterial.new()
	gmat.shader = load("res://hud/grade.gdshader")
	m.grade_rect.material = gmat
	grade_layer.add_child(m.grade_rect)
	m.hud = CanvasLayer.new()
	m.hud.layer = 2
	m.add_child(m.hud)
	# weather sits behind the HUD text but over the world
	m.weather_fx = Control.new()
	m.weather_fx.set_script(load("res://hud/weather_overlay.gd"))
	m.weather_fx.mode = Game.weather
	m.hud.add_child(m.weather_fx)
	# one quiet card for the vitals, one quiet card for the quests -
	# the world is busy on purpose, the overlay is not
	m.panel = Control.new()
	m.panel.set_script(load("res://hud/hud_panel.gd"))
	m.panel.position = Vector2(16, 12)
	m.hud.add_child(m.panel)
	m.panel.setup(m)
	# the goal list draws itself: real ticks and meters instead of ASCII, and
	# a height that follows its contents
	m.goals_card = Control.new()
	m.goals_card.set_script(load("res://hud/goals_card.gd"))
	m.goals_card.position = Vector2(m.GOALS_X, 8)
	m.hud.add_child(m.goals_card)
	m.goals_card.setup(m)
	# the end-of-walk card lays itself out: a twelve-goal walk used to run
	# straight off the bottom of the screen
	m.results_card = Control.new()
	m.results_card.set_script(load("res://hud/results_panel.gd"))
	m.results_card.visible = false
	m.hud.add_child(m.results_card)
	m.results_card.setup(m)
	m.hint_l = hud_label(m, Vector2(24, 686), 15)
	pin_box(m.hint_l, 0.0, 0.0, 0.0, 1.0)
	m.hint_l.modulate.a = 0.75
	m.title_l = hud_label(m, Vector2(0, 240), 44)
	pin_wide(m.title_l, 52.0, 0.5)
	m.title_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	m.title_l.text = "PATH OF LEASH RESISTANCE"
	m.sub_l = hud_label(m, Vector2(0, 300), 18)
	pin_wide(m.sub_l, 30.0, 0.5)
	m.sub_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	m.sub_l.text = "You are the dog. Go and touch grass."
	m.select_l = hud_label(m, Vector2(0, 348), 22)
	pin_wide(m.select_l, 32.0, 0.5)
	m.select_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	m.select_l.text = "<   %s   >" % Game.LEVEL_NAMES[m.lvl]
	m.record_l = hud_label(m, Vector2(0, 300), 18)
	pin_wide(m.record_l, 26.0, 0.5)
	m.record_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	m.record_l.modulate.a = 0.85
	# stacked ABOVE the controls line, which occupies y=686 from step 2 on
	m.menu_hint_l = hud_label(m, Vector2(24, 662), 14)
	pin_box(m.menu_hint_l, 0.0, 0.0, 0.0, 1.0)
	m.menu_hint_l.modulate.a = 0.55
	m.menu_hint_l.visible = false
	var version_l: Label = hud_label(m, Vector2(1150, 686), 13)
	pin_box(version_l, 0.0, 0.0, 1.0, 1.0)
	version_l.text = build_label()
	version_l.modulate.a = 0.5
	m.owner_l = hud_label(m, Vector2(0, 296), 26)
	pin_wide(m.owner_l, 34.0, 0.5)
	m.owner_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	m.night_l = hud_label(m, Vector2(0, 340), 26)
	pin_wide(m.night_l, 34.0, 0.5)
	m.night_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	m.weather_l = hud_label(m, Vector2(0, 384), 26)
	pin_wide(m.weather_l, 34.0, 0.5)
	m.weather_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# below the dog, which stands at about y=460-530 on the title, and above the
	# walk's blurb chalked at y~580; at 470 it sat right across her (#8)
	m.prompt_l = hud_label(m, Vector2(0, 536), 22)
	pin_wide(m.prompt_l, 32.0, 0.5)
	m.prompt_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	m.shop_preview_bg = ColorRect.new()
	m.shop_preview_bg.position = Vector2(60.0, 190.0)
	pin_box(m.shop_preview_bg, 440.0, 390.0, 0.5, 0.5)
	m.shop_preview_bg.color = Color(0.05, 0.06, 0.07, 0.72)
	m.shop_preview_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.shop_preview_bg.visible = false
	m.hud.add_child(m.shop_preview_bg)
	var preview := CharacterBody2D.new()
	preview.set_script(load("res://entities/dog.gd"))
	preview.preview_mode = true
	# the preview never ticks, but it draws its contact shadow through main
	# like the real dog; without this every draw errored and stopped short (#33)
	preview.setup(m)
	preview.position = Vector2(280.0, 365.0)
	preview.scale = Vector2(3.0, 3.0)
	preview.visible = false
	m.hud.add_child(preview)
	preview.z_index = 1
	m.shop_preview = preview
	m.shop_title_l = hud_label(m, Vector2(0, 70), 30)
	pin_wide(m.shop_title_l, 40.0)
	m.shop_title_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	m.shop_title_l.visible = false
	m.shop_preview_l = hud_label(m, Vector2(60.0, 145.0), 18)
	pin_box(m.shop_preview_l, 440.0, 30.0, 0.5, 0.5)
	m.shop_preview_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	m.shop_preview_l.text = "HIGHLIGHTED LOOK"
	m.shop_preview_l.visible = false
	m.shop_l = hud_label(m, Vector2(430.0, 150.0), 20)
	pin_box(m.shop_l, 800.0, 460.0, 0.5, 0.5)
	m.shop_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	m.shop_l.visible = false
	for k in Game.COLLARS:
		m.shop_items.append({"kind": "collar", "key": k})
	for k in Game.BANDANAS:
		if k != "none":
			m.shop_items.append({"kind": "bandana", "key": k})
	m.shop_items.append({"kind": "bandana", "key": "none"})
	# coats last: the biggest change to how Millie looks, and the first
	# working piece of the dog creator
	for k in Game.COATS:
		m.shop_items.append({"kind": "coat", "key": k})
	m.prompt_tw = m.create_tween().set_loops()
	m.prompt_tw.tween_property(m.prompt_l, "modulate:a", 0.3, 0.7)
	m.prompt_tw.tween_property(m.prompt_l, "modulate:a", 1.0, 0.7)
	var touch := Control.new()
	touch.set_script(load("res://hud/touch_controls.gd"))
	m.hud.add_child(touch)
	# the combo meter: trick string + score/multiplier over a draining
	# window bar, bottom-centre, only visible while a chain is live
	m.combo = Node.new()
	m.combo.set_script(load("res://systems/combo.gd"))
	m.add_child(m.combo)
	m.combo.setup(m)
	m.combo_bar_bg = ColorRect.new()
	m.combo_bar_bg.position = Vector2(440, 662)
	pin_box(m.combo_bar_bg, 400.0, 8.0, 0.5, 1.0)
	m.combo_bar_bg.color = Color(0.05, 0.06, 0.07, 0.55)
	m.combo_bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.combo_bar_bg.visible = false
	m.hud.add_child(m.combo_bar_bg)
	m.combo_bar = ColorRect.new()
	m.combo_bar.position = Vector2(440, 662)
	pin_box(m.combo_bar, 400.0, 8.0, 0.5, 1.0)
	m.combo_bar.color = Color(1.0, 0.78, 0.32)
	m.combo_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.combo_bar.visible = false
	m.hud.add_child(m.combo_bar)
	m.combo_l = hud_label(m, Vector2(0, 624), 26)
	pin_wide(m.combo_l, 34.0, 1.0)
	m.combo_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	m.combo_l.visible = false
	# the combo challenge (Phase B): a bounded trick dare from a bystander
	m.challenge = Node.new()
	m.challenge.set_script(load("res://systems/challenge.gd"))
	m.add_child(m.challenge)
	m.challenge.setup(m)
	m.mood = Node.new()
	m.mood.set_script(load("res://systems/mood.gd"))
	m.add_child(m.mood)
	m.mood.setup(m)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--mood="):
			var want := a.substr(7).to_upper()
			var names := {"SCARED": Mood.M.SCARED, "BARKY": Mood.M.BARKY,
				"ZOOMIES": Mood.M.ZOOMIES, "TIRED": Mood.M.TIRED}
			m.mood_forced = int(names.get(want, -1))
	m.teeter = Node.new()
	m.teeter.set_script(load("res://systems/teeter.gd"))
	m.add_child(m.teeter)
	m.grind = Node.new()
	m.grind.set_script(load("res://systems/grind.gd"))
	m.add_child(m.grind)
	m.challenge_l = hud_label(m, Vector2(0, 70), 24)
	pin_wide(m.challenge_l, 30.0)
	m.challenge_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	m.challenge_l.visible = false
	m.dim = ColorRect.new()
	m.dim.color = Color(0, 0, 0, 0.55)
	m.dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	m.dim.visible = false
	m.hud.add_child(m.dim)
	# the results card is built earlier but is what the dim is FOR: it has to
	# sit above it, or the whole card comes out 55% darker than drawn
	m.hud.move_child(m.results_card, m.dim.get_index() + 1)
	m.msg_label = hud_label(m, Vector2(0, 200), 22)
	pin_wide(m.msg_label, 400.0, 0.5)
	m.msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	m.msg_label.visible = false
	m.pause_l = hud_label(m, Vector2(0, 300), 26)
	pin_wide(m.pause_l, 120.0, 0.5)
	m.pause_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	m.pause_l.visible = false
	m.tut_label = hud_label(m, Vector2(0, 96), 30)
	pin_wide(m.tut_label, 40.0)
	m.tut_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	m.tut_label.visible = false
	m.tut_hint = hud_label(m, Vector2(0, 136), 19)
	pin_wide(m.tut_hint, 60.0)
	m.tut_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	m.tut_hint.visible = false
	m.progress_l = hud_label(m, Vector2(0, 70), 19)
	pin_wide(m.progress_l, 560.0)
	m.progress_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	m.progress_l.visible = false
	# The single announcement channel. Added late so it draws over the other
	# HUD cards, and anchored to the live viewport like everything else.
	m.feed = Control.new()
	m.feed.set_script(load("res://hud/event_feed.gd"))
	m.hud.add_child(m.feed)
	m.feed.setup(m)
	m.settings_panel = Control.new()
	m.settings_panel.set_script(load("res://hud/settings_panel.gd"))
	m.settings_panel.visible = false
	m.hud.add_child(m.settings_panel)
	m.settings_panel.setup(m)
	# a portrait window gets a "turn your phone" prompt and a paused game (#5).
	# Its own layer, not under the HUD, so it covers everything
	m.rotate_prompt = CanvasLayer.new()
	m.rotate_prompt.set_script(load("res://hud/rotate_prompt.gd"))
	m.add_child(m.rotate_prompt)
	m._update_hud()


# The version shown on the title. tools/stamp_version.sh writes the build's
# tag and short commit into res://build_label.txt right before an export (the
# file is gitignored, and each preset's include_filter packs it). A plain
# editor or source run has no stamp and says "dev", so a screenshot can never
# claim a release it did not come from.
static func build_label() -> String:
	if FileAccess.file_exists("res://build_label.txt"):
		var s := FileAccess.get_file_as_string("res://build_label.txt").strip_edges()
		if s != "":
			return s
	return "dev"


static func hud_label(m: Node2D, pos: Vector2, size_px: int) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_font_size_override("font_size", size_px)
	m.hud.add_child(l)
	return l


# The HUD was composed against the 1280x720 reference frame, and stretch
# aspect "expand" makes the real viewport that frame grown along one axis:
# wider than 1280 on a landscape phone, taller than 720 in portrait. A label
# holding size.x = 1280 therefore centres its text on x=640 instead of on the
# middle of the screen, and a line placed at y=686 floats up the picture
# instead of sitting on the bottom edge.
#
# These pin an element to the live viewport with anchors, which re-solve on
# rotation with nothing listening for a resize. Anchors and then offsets are
# both written outright, in that order: assigning an anchor rewrites the
# offsets to preserve the current rect, so setting offsets afterwards is what
# makes the result independent of wherever the node was first placed.

static func pin_wide(c: Control, h: float, v_rule: float = 0.0) -> void:
	# full screen width, so CENTER-aligned text centres on the middle of the
	# screen instead of on x=640. v_rule picks which horizontal rule the
	# authored y is measured from: 0 the top edge, 0.5 the middle, 1 the
	# bottom. Everything sharing a rule shifts together, so a stack of lines
	# keeps the spacing it was composed with.
	var y := c.position.y - REF_H * v_rule
	c.anchor_left = 0.0
	c.anchor_right = 1.0
	c.anchor_top = v_rule
	c.anchor_bottom = v_rule
	c.offset_left = 0.0
	c.offset_right = 0.0
	c.offset_top = y
	c.offset_bottom = y + h


static func pin_box(c: Control, w: float, h: float, h_rule: float, v_rule: float) -> void:
	# a fixed-size element measured in from a chosen corner or rule: (0, 1) the
	# bottom-left, (1, 1) the bottom-right, (0.5, 0.5) the middle of the
	# screen. Elements composed as one cluster share a rule so they travel
	# together rather than each hugging a different edge and pulling apart.
	#
	# Pass w or h as 0 to leave that axis to the node: a Control never shrinks
	# below its own minimum size, so an auto-sized Label still fits its text.
	# Anchoring both sides to the same rule also keeps the rect offset-driven,
	# which is what lets the combo bar write size.x every frame as it drains.
	var p := c.position - Vector2(REF_W * h_rule, REF_H * v_rule)
	c.anchor_left = h_rule
	c.anchor_right = h_rule
	c.anchor_top = v_rule
	c.anchor_bottom = v_rule
	c.offset_left = p.x
	c.offset_right = p.x + w
	c.offset_top = p.y
	c.offset_bottom = p.y + h
