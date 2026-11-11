extends SceneTree

# Regression test for upgraded Fur-goneta (Mutt Cutts facelift & multi-walk presence).
# Tests placement across 4 walks (street, beach, superilla, park),
# absence in market hall, bypasser blockers, rope soft wrap, bark honk reaction & cooldown,
# discovery sniffing payout, style dare offer/resolution, and fresh coat grooming buff.

var checks := 0
var failures: Array[String] = []
var _current_m: Node2D = null


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	call_deferred("_run")


func _load_walk(level_id: String) -> Node2D:
	if _current_m != null and is_instance_valid(_current_m):
		_current_m.free()
		_current_m = null
	var game: Node = root.get_node("Game")
	game.level_id = level_id
	game.persist = false
	game.weather = "clear"
	game.night = false
	game.menu_step = 2
	if root.has_node("Sfx"):
		root.get_node("Sfx").muted = true

	var m: Node2D = load("res://main.tscn").instantiate()
	root.add_child(m)
	if not m.is_node_ready():
		await m.ready
	m.frozen = true
	_current_m = m
	return m


func _run() -> void:
	var FurgonetaMod: GDScript = load("res://systems/furgoneta.gd")

	# --- 1. Placement verification on all 4 walks ---
	var test_walks := ["street", "beach", "superilla", "park"]
	for wname: String in test_walks:
		var m: Node2D = await _load_walk(wname)
		_check(m.furgoneta.x < INF, "Fur-goneta is placed on %s" % wname)
		_check(m.furgoneta.y < 0.0, "Fur-goneta y is along walk on %s (got %.1f)" % [wname, m.furgoneta.y])

		# Verify bypasser blocker registration
		var found_blocker := false
		for b in m.bypasser_blockers:
			if String(b.get("id", "")) == "furgoneta":
				found_blocker = true
				var br: Rect2 = b.rect
				_check(br.get_center().distance_to(m.furgoneta) < 0.5,
					"blocker matches van center on %s" % wname)
				break
		_check(found_blocker, "registered bypasser blocker on %s" % wname)

		# Verify rope soft wrap points enclose the van
		var van_rect := Rect2(m.furgoneta - m.VAN_BODY_SIZE * 0.5, m.VAN_BODY_SIZE)
		var rope_count := 0
		for pt: Vector2 in m.rope_soft:
			if van_rect.grow(4.0).has_point(pt):
				rope_count += 1
		_check(rope_count >= 16, "Fur-goneta rope wrap points present on %s (found %d)" % [wname, rope_count])

	# --- 2. Absence verification on non-van walks (e.g. market) ---
	var m_market: Node2D = await _load_walk("market")
	_check(m_market.furgoneta.x >= INF, "no Fur-goneta inside market hall")

	# Reload street for gameplay interaction checks
	var m: Node2D = await _load_walk("street")
	var van_pos: Vector2 = m.furgoneta

	# --- 3. Honk on bark ---
	m.bones = 0
	m.furgoneta_honk_cd = 0.0
	m.furgoneta_flash_t = 0.0
	m.furgoneta_wiper_t = 0.0

	# Bark far away: no honk
	var far_pos := van_pos + Vector2(300.0, 0.0)
	var far_honked: bool = FurgonetaMod.on_bark(m, far_pos)
	_check(not far_honked, "bark outside 150px does not honk")
	_check(m.furgoneta_flash_t == 0.0, "headlamps do not flash on far bark")

	# Bark near the van: honks!
	var near_pos := van_pos + Vector2(40.0, 40.0)
	var honked: bool = FurgonetaMod.on_bark(m, near_pos)
	_check(honked, "bark within 150px triggers van honk")
	_check(m.furgoneta_flash_t > 0.30, "headlamps flash on honk")
	_check(m.furgoneta_wiper_t > 0.50, "eyebrow wipers wiggle on honk")
	_check(m.furgoneta_honk_cd > 0.8, "honk cooldown set")
	_check(m.bones == 2, "van honk awards 2 bones (got %d)" % m.bones)

	# Bark during cooldown: suppressed
	var honk_spam: bool = FurgonetaMod.on_bark(m, near_pos)
	_check(not honk_spam, "honk cooldown prevents spam")

	# Tick cooldown
	FurgonetaMod.tick(m, 1.5)
	_check(m.furgoneta_honk_cd == 0.0, "cooldown ticks down")
	_check(m.furgoneta_flash_t == 0.0, "flash timer ticks down")
	_check(m.furgoneta_wiper_t == 0.0, "wiper timer ticks down")

	# --- 4. Scent sniffing interaction ---
	_check(not m.furgoneta_sniffed, "van starts unsniffed")
	m.bones = 0
	var prev_bones: int = m.bones
	# Move dog close to van at low speed
	m.dog.global_position = van_pos + Vector2(20.0, 20.0)
	m.dog.velocity = Vector2(10.0, 0.0)
	m._pickups(1.0 / 60.0)
	_check(m.furgoneta_sniffed, "sniffing van marks furgoneta_sniffed")
	_check(m.bones == prev_bones + 12, "sniffing van awards +12 bones (got %d)" % m.bones)

	# --- 5. Style Dare & Fresh Coat Buff ---
	_check(not m.furgoneta_dare_offered, "style dare starts unoffered")
	_check(not m.furgoneta_dare_won, "style dare starts unwon")
	_check(m.fresh_coat_t == 0.0, "fresh coat buff starts at 0")

	# Move dog near van to trigger dare
	m.dog.global_position = van_pos + Vector2(30.0, 30.0)
	m.dog.velocity = Vector2.ZERO
	FurgonetaMod.tick(m, 1.0 / 60.0)
	_check(m.furgoneta_dare_offered, "mobile groomer offers style dare within 130px")
	_check(m.challenge.showing(), "dare challenge card is showing")
	_check(m.challenge.phase == "offer", "dare challenge phase is offer")

	# Test winning the dare
	FurgonetaMod.resolve_dare(m, true)
	_check(m.furgoneta_dare_won, "style dare marked won")
	_check(m.fresh_coat_t > 30.0, "fresh coat buff active (got %.1f s)" % m.fresh_coat_t)

	# Test Fresh Coat buff mechanics:
	# Bonus trick score:
	var base_pts: int = 2
	var scored_pts: int = m.on_scored("BARK", base_pts, true)
	_check(scored_pts == base_pts + 1, "fresh coat adds +1 bonus trick point (got %d)" % scored_pts)

	# Clean coat: clears wet paws/mud
	m.wet_paws = 2.0
	FurgonetaMod.tick(m, 1.0 / 60.0)
	_check(m.wet_paws == 0.0, "fresh coat immediately sheds mud / wet paws")

	# Fresh coat timer ticks down
	var coat_before: float = m.fresh_coat_t
	FurgonetaMod.tick(m, 5.0)
	_check(m.fresh_coat_t == coat_before - 5.0, "fresh coat timer ticks down")

	# --- 6. Visual draw verification ---
	FurgonetaMod.draw(m, van_pos)
	FurgonetaMod.draw_fresh_coat_sparkles(m)
	var b := ShapeBatch.new()
	FurgonetaMod.draw(m, van_pos, b)
	FurgonetaMod.draw_fresh_coat_sparkles(m, b)
	_check(true, "Fur-goneta draw and fresh coat sparkles execute without error")

	# Cleanup
	if _current_m != null and is_instance_valid(_current_m):
		_current_m.free()
		_current_m = null

	if failures.is_empty():
		print("test_furgoneta: %d checks, OK" % checks)
		quit(0)
	else:
		print("test_furgoneta: %d checks, %d FAILURES" % [checks, failures.size()])
		quit(1)
