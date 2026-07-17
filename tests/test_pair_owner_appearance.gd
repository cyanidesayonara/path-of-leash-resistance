extends SceneTree

const HumanAppearanceScript := preload("res://human_appearance.gd")
const DogAppearanceScript := preload("res://dog_appearance.gd")
const PairScript := preload("res://otherpair.gd")
const PARK_BOUNDS := Rect2(20.0, -260.0, 360.0, 230.0)
const PARK_SPOT := Vector2(300.0, -90.0)
const WALKING := 0
const ARRIVING := 1
const PARKED := 2
const RECALLING := 3
const DEPARTING := 4

var failures := 0
var fixtures: Array[Node] = []


class FakeMain:
	extends Node2D

	var phase := "freedom"
	var frozen := false
	var cam := Camera2D.new()
	var released_pair_ids: Array[int] = []

	func _init() -> void:
		add_child(cam)

	func release_pair_park_spot(pair_instance_id: int) -> void:
		released_pair_ids.append(pair_instance_id)

	func float_text(_position: Vector2, _text: String, _color: Color) -> void:
		pass


func _check(condition: bool, message: String) -> void:
	if not condition:
		print("FAIL: " + message)
		failures += 1


func _has_property(object: Object, property_name: String) -> bool:
	for property: Dictionary in object.get_property_list():
		if String(property.get("name", "")) == property_name:
			return true
	return false


func _make_main() -> FakeMain:
	var main := FakeMain.new()
	main.visible = false
	root.add_child(main)
	fixtures.append(main)
	return main


func _make_player() -> Node2D:
	var player := Node2D.new()
	player.visible = false
	player.position = Vector2(1000.0, 1000.0)
	root.add_child(player)
	fixtures.append(player)
	return player


func _make_pair(
	main: FakeMain,
	player: Node2D,
	seed_value: int,
	start := Vector2(200.0, 120.0),
	direction := Vector2.UP
) -> Node2D:
	seed(seed_value)
	var pair := Node2D.new()
	pair.set_script(PairScript)
	var poles: Array[Vector2] = []
	pair.setup(main, player, poles, start, direction)
	var blockers: Array[Dictionary] = []
	_check(bool(pair.configure_route(start.x, 20.0, 380.0, blockers)), "real pair route configures")
	root.add_child(pair)
	pair.set_physics_process(false)
	fixtures.append(pair)
	main.cam.position = pair.npc_owner.position
	return pair


func _state(pair: Node2D) -> int:
	return int(pair.get_pair_state())


func _check_owner_identity(
	pair: Node2D,
	profile: Dictionary,
	profile_id: String,
	label: String
) -> void:
	_check(
		is_same(pair.owner_appearance_profile, profile),
		label + " keeps the same owner profile dictionary"
	)
	_check(
		String(pair.owner_appearance_profile.get("id", "")) == profile_id,
		label + " keeps the same owner profile ID"
	)


func _check_nodes_and_endpoints(
	pair: Node2D,
	pair_id: int,
	owner_id: int,
	dog_id: int,
	leash_id: int,
	label: String
) -> void:
	_check(pair.get_instance_id() == pair_id, label + " keeps pair identity")
	_check(pair.npc_owner.get_instance_id() == owner_id, label + " keeps owner identity")
	_check(pair.npc_dog.get_instance_id() == dog_id, label + " keeps dog identity")
	_check(pair.leash.get_instance_id() == leash_id, label + " keeps leash identity")
	_check(pair.leash.human == pair.npc_owner, label + " keeps owner leash endpoint")
	_check(pair.leash.dog == pair.npc_dog, label + " keeps dog leash endpoint")


func _test_exact_setup_rng(main: FakeMain, player: Node2D) -> void:
	const RNG_SEED := 424242
	var direction := Vector2.UP
	seed(RNG_SEED)
	var expected_speed := randf_range(58.0, 82.0)
	var expected_seed_o := randf() * 10.0
	var raw_owner_key := randi()
	var raw_dog_key := randi()
	var expected_next := randf()
	seed(RNG_SEED)
	var pair := Node2D.new()
	pair.set_script(PairScript)
	var poles: Array[Vector2] = []
	pair.setup(main, player, poles, Vector2(200.0, 120.0), direction)
	var actual_next := randf()
	root.add_child(pair)
	pair.set_physics_process(false)
	fixtures.append(pair)

	var expected_owner: Dictionary = HumanAppearanceScript.profile_for_key(raw_owner_key)
	var expected_dog: Dictionary = DogAppearanceScript.profile_for_key(raw_dog_key)
	_check(pair.vel.is_equal_approx(direction * expected_speed), "first draw sets velocity")
	_check(is_equal_approx(pair.seed_o, expected_seed_o), "second draw sets seed_o")
	_check(pair.owner_appearance_profile == expected_owner, "raw third draw selects owner profile")
	_check(pair.owner_col == expected_owner["shirt_color"], "owner_col derives from shirt_color")
	_check(pair.appearance_profile == expected_dog, "raw fourth draw still selects dog profile")
	_check(pair.dog_col == expected_dog["base_color"], "dog_col still derives from dog profile")
	_check(is_equal_approx(actual_next, expected_next), "setup preserves following global RNG value")

	var repeated := _make_pair(main, player, RNG_SEED)
	_check(
		repeated.owner_appearance_profile == pair.owner_appearance_profile,
		"equal seeds select equal owner profiles"
	)
	_check(repeated.appearance_profile == pair.appearance_profile, "equal seeds select equal dog profiles")
	_check(is_equal_approx(repeated.seed_o, pair.seed_o), "equal seeds select equal animation phases")
	var selected_owner_ids := {}
	for seed_value in [11, 29, 47, 83, 131, 197, 251, 307]:
		var candidate := _make_pair(main, player, seed_value)
		selected_owner_ids[String(candidate.owner_appearance_profile["id"])] = true
	_check(selected_owner_ids.size() > 1, "representative seeds select multiple owner profiles")


func _test_lifecycle_identity(main: FakeMain, player: Node2D) -> Node2D:
	var pair := _make_pair(main, player, 1707)
	pair.configure_park_area(0.0, PARK_BOUNDS)
	var owner_profile: Dictionary = pair.owner_appearance_profile
	var owner_profile_id := String(owner_profile["id"])
	var dog_profile: Dictionary = pair.appearance_profile
	var pair_id := pair.get_instance_id()
	var owner_id: int = pair.npc_owner.get_instance_id()
	var dog_id: int = pair.npc_dog.get_instance_id()
	var leash_id: int = pair.leash.get_instance_id()

	_check(_state(pair) == WALKING, "pair starts WALKING")
	_check_owner_identity(pair, owner_profile, owner_profile_id, "WALKING")
	_check_nodes_and_endpoints(pair, pair_id, owner_id, dog_id, leash_id, "WALKING")
	_check(bool(pair.begin_park_arrival(7, PARK_SPOT)), "pair begins arrival")
	_check(_state(pair) == ARRIVING, "pair enters ARRIVING")
	_check_owner_identity(pair, owner_profile, owner_profile_id, "ARRIVING")
	pair._enter_parked(100.0)
	_check(_state(pair) == PARKED, "pair enters PARKED")
	_check_owner_identity(pair, owner_profile, owner_profile_id, "PARKED")
	pair.begin_park_recall()
	_check(_state(pair) == RECALLING, "pair enters RECALLING")
	_check_owner_identity(pair, owner_profile, owner_profile_id, "RECALLING")
	pair.npc_dog.position = pair.park_spot
	pair._physics_process(0.0)
	_check(_state(pair) == DEPARTING, "close recall enters DEPARTING")
	_check_owner_identity(pair, owner_profile, owner_profile_id, "DEPARTING")
	pair.npc_owner.position = Vector2(pair.walking_lane_x, 80.0)
	pair._physics_process(0.0)
	_check(_state(pair) == WALKING, "gate clearance resumes WALKING")
	_check_owner_identity(pair, owner_profile, owner_profile_id, "resumed WALKING")
	_check(is_same(pair.appearance_profile, dog_profile), "dog profile dictionary also remains identical")
	_check_nodes_and_endpoints(pair, pair_id, owner_id, dog_id, leash_id, "resumed WALKING")
	return pair


func _test_initialization_and_interrupt(main: FakeMain, player: Node2D) -> void:
	var departure := _make_pair(main, player, 2718)
	departure.configure_park_area(0.0, PARK_BOUNDS)
	var departure_profile: Dictionary = departure.owner_appearance_profile
	var departure_id := String(departure_profile["id"])
	_check(
		bool(departure.initialize_parked_departure(
			9,
			PARK_SPOT,
			Vector2(80.0, -220.0),
			100.0
		)),
		"parked departure initializes"
	)
	_check_owner_identity(departure, departure_profile, departure_id, "initialized PARKED")

	var interrupted := _make_pair(main, player, 3141)
	interrupted.configure_park_area(0.0, PARK_BOUNDS)
	var interrupted_profile: Dictionary = interrupted.owner_appearance_profile
	var interrupted_id := String(interrupted_profile["id"])
	_check(bool(interrupted.begin_park_arrival(10, PARK_SPOT)), "interrupt fixture enters ARRIVING")
	main.phase = "home"
	interrupted._physics_process(0.0)
	_check(_state(interrupted) == RECALLING, "home interrupts arrival into RECALLING")
	_check_owner_identity(
		interrupted,
		interrupted_profile,
		interrupted_id,
		"home-interrupted RECALLING"
	)
	main.phase = "freedom"


func _region_has_rgb(image: Image, center: Vector2, expected: Color) -> bool:
	var left := maxi(0, floori(center.x - 52.0))
	var right := mini(image.get_width() - 1, ceili(center.x + 52.0))
	var top := maxi(0, floori(center.y - 52.0))
	var bottom := mini(image.get_height() - 1, ceili(center.y + 52.0))
	for y in range(top, bottom + 1):
		for x in range(left, right + 1):
			var actual := image.get_pixel(x, y)
			if (
				actual.a > 0.2
				and absf(actual.r - expected.r) <= 0.08
				and absf(actual.g - expected.g) <= 0.08
				and absf(actual.b - expected.b) <= 0.08
			):
				return true
	return false


func _region_has_screen_mix(
	image: Image,
	center: Vector2,
	body_color: Color,
	screen_color: Color
) -> bool:
	var left := maxi(0, floori(center.x - 52.0))
	var right := mini(image.get_width() - 1, ceili(center.x + 52.0))
	var top := maxi(0, floori(center.y - 52.0))
	var bottom := mini(image.get_height() - 1, ceili(center.y + 52.0))
	for y in range(top, bottom + 1):
		for x in range(left, right + 1):
			var actual := image.get_pixel(x, y)
			for weight in [0.35, 0.45, 0.55, 0.65, 0.75]:
				var expected := body_color.lerp(screen_color, weight)
				if (
					actual.a > 0.9
					and absf(actual.r - expected.r) <= 0.08
					and absf(actual.g - expected.g) <= 0.08
					and absf(actual.b - expected.b) <= 0.08
				):
					return true
	return false


func _test_parent_rendering(pair: Node2D, player: Node2D) -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(256, 256)
	viewport.transparent_bg = true
	viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	fixtures.append(viewport)
	pair.reparent(viewport)
	pair.position = Vector2.ZERO
	pair.npc_owner.position = Vector2(96.0, 96.0)
	pair.npc_dog.position = Vector2(170.0, 150.0)
	player.position = pair.npc_dog.global_position
	pair.vel = Vector2.ZERO
	seed(98765)
	var expected_next := randf()
	seed(98765)
	for state in [WALKING, ARRIVING, PARKED, RECALLING, DEPARTING]:
		pair.pair_state = state
		for profile_id: String in HumanAppearanceScript.profile_ids():
			pair.owner_appearance_profile = HumanAppearanceScript.get_profile(profile_id)
			pair.owner_col = pair.owner_appearance_profile["shirt_color"]
			pair.queue_redraw()
			await process_frame
			await process_frame
			var image := viewport.get_texture().get_image()
			_check(
				_region_has_rgb(
					image,
					pair.npc_owner.position,
					pair.owner_appearance_profile["phone_body_color"]
				),
				"%s state %d renders a phone body on the pair parent" % [profile_id, state]
			)
			_check(
				_region_has_screen_mix(
					image,
					pair.npc_owner.position,
					pair.owner_appearance_profile["phone_body_color"],
					pair.owner_appearance_profile["phone_screen_color"]
				),
				"%s state %d renders a phone screen on the pair parent" % [profile_id, state]
			)
	var actual_next := randf()
	_check(is_equal_approx(actual_next, expected_next), "pair drawing preserves global RNG")


func _cleanup() -> void:
	for index in range(fixtures.size() - 1, -1, -1):
		var fixture := fixtures[index]
		if is_instance_valid(fixture):
			fixture.free()
	fixtures.clear()


func _finish() -> void:
	_cleanup()
	if failures > 0:
		print("test_pair_owner_appearance: %d FAILURES" % failures)
		quit(1)
	else:
		print("test_pair_owner_appearance: OK")
		quit(0)


func _run() -> void:
	var probe := Node2D.new()
	probe.set_script(PairScript)
	var has_owner_profile := _has_property(probe, "owner_appearance_profile")
	_check(has_owner_profile, "otherpair stores owner_appearance_profile")
	probe.free()
	if not has_owner_profile:
		_finish()
		return
	var main := _make_main()
	var player := _make_player()
	_test_exact_setup_rng(main, player)
	var lifecycle_pair := _test_lifecycle_identity(main, player)
	_test_initialization_and_interrupt(main, player)
	await _test_parent_rendering(lifecycle_pair, player)
	_finish()


func _initialize() -> void:
	call_deferred("_run")
