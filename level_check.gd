extends RefCounted

# Structural sanity checks for a built level. These need the real runtime
# (main.gd leans on the Game/Sfx autoloads, which do not exist under a bare
# `--script` test run), so main invokes this under the --selftest flag and
# CI sweeps every level through it. Pure inspection: it reads the level main
# just built and returns a list of problems, changing nothing.
#
# This is the check that catches content mistakes CI could not see before:
# props stranded off the pavement when a corridor width changes, a goal the
# level cannot actually satisfy, a malformed goal list.

static func check(m) -> Array:
	var p: Array = []
	var lv: String = m.lvl

	# --- corridor sanity ---
	if m.walk_half < 120.0 or m.walk_half > 520.0:
		p.append("implausible corridor half-width %.0f" % m.walk_half)
	# the beach's walkable strip sits off-centre by design (sea on one side,
	# cafe terraces on the other), so only the symmetric walks are checked
	if lv != "beach" and absf((m.sw_l + m.sw_r) / 2.0 - m.walk_cx) > 0.5:
		p.append("pavement not centred on walk_cx")
	if m.sw_l < 0.0 or m.sw_r > 1280.0:
		p.append("corridor %.0f..%.0f leaves the viewport" % [m.sw_l, m.sw_r])

	# --- the corridor's SHAPE, for walks whose path bends ---
	# A path is a curve now (edge_path.gd), which is a good way to make a
	# level stop looking blocky and an excellent way to author one that cannot
	# be walked. Caught here rather than discovered as a dog wedged in a wall.
	var EdgePathC = load("res://edge_path.gd")
	var shape: Dictionary = EdgePathC.valid(m.edge_nodes, 120.0)
	if not bool(shape["ok"]):
		p.append("corridor shape: %s" % String(shape["why"]))
	if not (m.edge_nodes as Array).is_empty():
		# a corridor that slides sideways faster than a dog can strafe is a
		# wall you cannot see coming
		var slope: float = EdgePathC.max_slope(m.edge_nodes)
		if slope > 0.85:
			p.append("corridor veers %.2fpx sideways per px south - too sharp to run" % slope)
		# and wherever it goes, it has to stay on screen and stay walkable
		var ny: float = float((m.edge_nodes[0] as Dictionary)["y"])
		var last_y: float = float((m.edge_nodes[(m.edge_nodes as Array).size() - 1] as Dictionary)["y"])
		while ny <= last_y:
			var e: Vector2 = m.walk_edges(ny)
			if e.x < 40.0 or e.y > 1240.0:
				p.append("corridor reaches %.0f..%.0f at y=%.0f, outside the level" % [e.x, e.y, ny])
				break
			ny += 120.0

	# --- patches on ground that could actually hold them ---
	# A mud puddle in the middle of a pond is not a puddle, and wet cement
	# poured over an open manhole is not a works - both are bugs that happen to
	# read as level design. Patches are hand-authored against a walk, so this
	# is the check that stops a plausible-looking number landing somewhere
	# absurd. It FAILS rather than quietly relocating: the author should see it.
	for pt in m.patches:
		var pb: Rect2 = m.patch_bounds(pt)
		var pc: Vector2 = m.patch_centre(pt)
		var what: String = String(pt["kind"])
		if m.pond.size.x > 0.0 and m.pond.intersects(pb):
			p.append("%s patch at (%.0f, %.0f) overlaps the pond" % [what, pc.x, pc.y])
		for w: Rect2 in m.water:
			if w.intersects(pb):
				p.append("%s patch at (%.0f, %.0f) is in water" % [what, pc.x, pc.y])
				break
		for mh: Vector2 in m.manholes:
			if pb.has_point(mh):
				p.append("%s patch at (%.0f, %.0f) covers a manhole" % [what, pc.x, pc.y])
				break
		for cl: Rect2 in m.cellars:
			if cl.intersects(pb):
				p.append("%s patch at (%.0f, %.0f) covers a cellar" % [what, pc.x, pc.y])
				break
		# and it has to be ON the walk, not out on the grass
		var pe: Vector2 = m.walk_edges(pc.y)
		if pc.x < pe.x or pc.x > pe.y:
			p.append("%s patch at (%.0f, %.0f) is off the path (%.0f..%.0f there)" % [
				what, pc.x, pc.y, pe.x, pe.y])

	# --- every prop on its own pavement ---
	# the beach is exempt: its sand / boardwalk / bike-path cross-section
	# deliberately places things outside the walkway
	if lv != "beach":
		var groups := {
			"stall": m.stalls, "bin": m.bins, "bench": m.benches,
			"a-stand": m.astands, "van": m.vans, "performer": m.performers,
			"cone": m.cone_spots, "manhole": m.manholes,
			"wallcat": m.wallcat_spots, "guard": m.guard_posts,
			"candy": m.candy_spots, "fountain": m.fountains,
		}
		# measured against the path AT EACH PROP'S OWN Y, so this keeps working
		# when a street bends instead of quietly condemning every prop on the
		# outside of a curve
		for name in groups:
			for v in groups[name]:
				var e: Vector2 = m.walk_edges(v.y)
				if v.x < e.x - 2.0 or v.x > e.y + 2.0:
					p.append("%s at (%.0f, %.0f) is off the pavement (%.0f..%.0f there)" % [
						name, v.x, v.y, e.x, e.y])
					break
		for d in m.hydrants:
			var he: Vector2 = m.walk_edges(d.pos.y)
			if d.pos.x < he.x - 2.0 or d.pos.x > he.y + 2.0:
				p.append("hydrant at x=%.0f is off the pavement" % d.pos.x)
				break
		for d in m.kebabs:
			var ke: Vector2 = m.walk_edges(d.pos.y)
			if d.pos.x < ke.x - 2.0 or d.pos.x > ke.y + 2.0:
				p.append("snack at x=%.0f is off the pavement" % d.pos.x)
				break

	# --- the walk has things to interact with ---
	# kickable junk and sniffable spots are the small joys that make a walk
	# feel inhabited, so a level that is short of either is a content bug
	var kickables: int = m.get_tree().get_nodes_in_group("cones").size()
	if kickables < 6:
		p.append("only %d kickable objects on the whole walk" % kickables)
	if m.hydrants.size() < 3:
		p.append("only %d sniffable spots" % m.hydrants.size())
	# the off-leash area is the one place the dog is free, so it must not be
	# a bare field: it needs things to dig, sniff, climb and drink from
	var props: Array = m.park_props
	if props.size() < 8:
		p.append("off-leash area has only %d props" % props.size())
	var diggable := 0
	var solid := 0
	for pp in props:
		var k := String(pp.kind)
		if k == "dig":
			diggable += 1
		elif k == "log" or k == "driftwood" or k == "tyre":
			solid += 1
	if diggable < 2:
		p.append("off-leash area has only %d dig patches" % diggable)
	if solid < 1:
		p.append("off-leash area has nothing solid to navigate round")

	# --- the goal list is well formed ---
	var ids: Array = m.LEVEL_GOAL_IDS.get(lv, [])
	if ids.is_empty():
		p.append("no goal list")
	elif ids.size() < 8 or ids.size() > 14:
		p.append("goal list length %d out of range" % ids.size())
	var seen := {}
	for id in ids:
		if seen.has(id):
			p.append("duplicate goal id '%s'" % id)
		seen[id] = true
	var defs: Dictionary = m._goal_defs()
	for id in ids:
		if not defs.has(id):
			p.append("goal id '%s' has no definition" % id)
	if not ids.is_empty() and m.active_quests.size() != ids.size():
		p.append("built %d quests for %d ids" % [m.active_quests.size(), ids.size()])

	# --- the level can actually satisfy what it asks for ---
	for q in m.active_quests:
		var need := int(q.target)
		match String(q.id):
			"sniff":
				if m.hydrants.size() < need:
					p.append("wants %d sniffs, has %d hydrants" % [need, m.hydrants.size()])
			"snack":
				if m.kebabs.size() < need:
					p.append("wants %d snacks, has %d" % [need, m.kebabs.size()])
			"cats":
				if m.wallcat_spots.size() < need:
					p.append("wants %d wall cats, has %d" % [need, m.wallcat_spots.size()])
			"drink":
				if m.fountains.is_empty():
					p.append("wants a drink, has no fountain")
			"tummy":
				if m.candy.is_empty():
					p.append("wants candy resisted, has no candy")
			"ghost":
				if m.guard_posts.is_empty():
					p.append("wants guards unwoken, has no guards")
			"unseen":
				if m.cameras.is_empty() and m.lasers.is_empty():
					p.append("wants cameras/lasers dodged, has neither")
			"carry":
				if m.carry_pickup.x >= INF or m.carry_drop.x >= INF:
					p.append("has a carry goal but no pickup/drop placed")
			"prize":
				if m.prize_pos.x >= INF:
					p.append("has a prize goal but no prize placed")

	# --- the off-leash area must have something to pee on ---
	# It had nothing: every hydrant and lamppost is out on the street, so the
	# one place the dog is free to mark was the one place she could not, and
	# the "mark 5 spots" goal quietly became unfinishable once you went
	# through the gate.
	var markable := 0
	for pp in m.park_props:
		if m.MARKABLE_PARK_KINDS.has(String(pp.kind)):
			markable += 1
	if markable < 3:
		p.append("off-leash area has %d markable props, wants 3+" % markable)

	# --- nothing sniffable floating out at sea ---
	# The off-leash spaces place their furniture with a random draw, and the
	# beach has open water in it, so driftwood and dig patches were landing
	# twenty metres offshore where no dog can reach them.
	for pp in m.park_props:
		for w: Rect2 in m.water:
			if w.has_point(pp.pos as Vector2):
				p.append("%s prop at %s is in the water" % [String(pp.kind), pp.pos])
	for t in m.trees:
		for w2: Rect2 in m.water:
			if w2.has_point(t as Vector2):
				p.append("a tree is standing in the water at %s" % t)
	# the corridor's furniture too: widening the seafront's water put towels
	# and parasols that were authored on the sand out in the sea
	var wet_groups := {
		"parasol": m.parasols, "bench": m.benches, "bin": m.bins, "table": m.tables,
		"a-stand": m.astands, "fountain": m.fountains, "cone": m.cone_spots,
	}
	for gname in wet_groups:
		for at: Vector2 in wet_groups[gname]:
			for w3: Rect2 in m.water:
				if w3.grow(-6.0).has_point(at):
					p.append("%s at %s is in the water" % [gname, at])
	for tw in m.towels:
		for w4: Rect2 in m.water:
			if w4.intersects((tw.rect as Rect2)):
				p.append("a towel is in the water at %s" % (tw.rect as Rect2).position)
	for kb in m.kebabs:
		for w5: Rect2 in m.water:
			if w5.has_point(kb.pos as Vector2):
				p.append("a snack is in the water at %s" % kb.pos)

	# --- the settings screen ---
	# The rows are drawn from settings_rows() but INDEXED with settings_keys(),
	# so a setting added to one and not the other reads or writes the wrong
	# row. Cheap to check here, impossible to notice by eye.
	var keys: Array = m.settings_keys()
	var rows: Array = m.settings_rows()
	if keys.size() != rows.size():
		p.append("settings: %d keys but %d rows" % [keys.size(), rows.size()])
	for k in keys:
		if not m.SETTING_NAMES.has(k):
			p.append("settings: key '%s' has no display name" % k)
	for row in rows:
		if String(row.kind) == "slider" and (float(row.v) < 0.0 or float(row.v) > 1.0):
			p.append("settings: %s is %.2f, outside 0..1" % [row.name, row.v])

	return p
