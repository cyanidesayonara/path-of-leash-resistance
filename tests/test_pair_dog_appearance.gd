extends SceneTree

const DogAppearanceScript := preload("res://dog_appearance.gd")
const PairScript := preload("res://otherpair.gd")
const DT := 1.0 / 60.0
const PARK_BOUNDS := Rect2(20.0, -260.0, 360.0, 230.0)
const PARK_SPOT := Vector2(300.0, -90.0)
const WALKING := 0
const ARRIVING := 1
const PARKED := 2
const RECALLING := 3
const DEPARTING := 4
const OWNER_COLORS := [
	Color(0.5, 0.45, 0.55),
	Color(0.45, 0.5, 0.42),
	Color(0.55, 0.48, 0.4),
]

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
	_check(
		bool(pair.configure_route(start.x, 20.0, 380.0, blockers)),
		"real pair route configures"
	)
	root.add_child(pair)
	pair.set_physics_process(false)
	fixtures.append(pair)
	main.cam.position = pair.npc_owner.position
	return pair


func _state(pair: Node2D) -> int:
	return int(pair.get_pair_state())


func _check_profile_identity(
	pair: Node2D,
	original_profile: Dictionary,
	original_id: String,
	label: String
) -> void:
	_check(
		is_same(pair.appearance_profile, original_profile),
		label + " keeps the same profile dictionary"
	)
	_check(
		String(pair.appearance_profile.get("id", "")) == original_id,
		label + " keeps the same profile ID"
	)


func _test_exact_setup_rng(main: FakeMain, player: Node2D) -> void:
	const RNG_SEED := 424242
	var direction := Vector2.UP
	seed(RNG_SEED)
	var expected_speed := randf_range(58.0, 82.0)
	var expected_seed_o := randf() * 10.0
	var owner_key := randi()
	var dog_key := randi()
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

	_check(pair.vel.is_equal_approx(direction * expected_speed), "velocity uses the first randf_range")
	_check(is_equal_approx(pair.seed_o, expected_seed_o), "seed_o uses the second randf")
	_check(pair.owner_col == OWNER_COLORS[owner_key % OWNER_COLORS.size()], "owner color uses the third randi")
	var expected_profile: Dictionary = DogAppearanceScript.profile_for_key(dog_key)
	_check(pair.appearance_profile == expected_profile, "raw fourth randi selects the dog profile")
	_check(pair.dog_col == expected_profile["base_color"], "compatibility dog_col follows the profile")
	_check(is_equal_approx(actual_next, expected_next), "pair setup preserves the following RNG value")

	var repeated := _make_pair(main, player, RNG_SEED)
	_check(repeated.appearance_profile == pair.appearance_profile, "equal seeds select equal pair profiles")
	_check(is_equal_approx(repeated.seed_o, pair.seed_o), "equal seeds select equal pair phases")

	var selected_ids := {}
	for seed_value in [11, 29, 47, 83, 131, 197]:
		var candidate := _make_pair(main, player, seed_value)
		selected_ids[String(candidate.appearance_profile["id"])] = true
	_check(selected_ids.size() > 1, "representative seeds select multiple profiles")


func _test_lifecycle_profile_persistence(main: FakeMain, player: Node2D) -> Node2D:
	var pair := _make_pair(main, player, 1707)
	pair.configure_park_area(0.0, PARK_BOUNDS)
	var profile: Dictionary = pair.appearance_profile
	var profile_id := String(profile["id"])
	var pair_id := pair.get_instance_id()
	var owner_id: int = pair.npc_owner.get_instance_id()
	var dog_id: int = pair.npc_dog.get_instance_id()
	var leash_id: int = pair.leash.get_instance_id()

	_check(_state(pair) == WALKING, "pair starts WALKING")
	_check_profile_identity(pair, profile, profile_id, "WALKING")
	_check(bool(pair.begin_park_arrival(7, PARK_SPOT)), "pair starts arrival")
	_check(_state(pair) == ARRIVING, "pair enters ARRIVING")
	_check_profile_identity(pair, profile, profile_id, "ARRIVING")

	pair._enter_parked(100.0)
	_check(_state(pair) == PARKED, "pair enters PARKED")
	_check_profile_identity(pair, profile, profile_id, "PARKED")
	_check(pair.leash.detached and not pair.leash.visible, "PARKED keeps the leash suspended")

	pair.begin_park_recall()
	_check(_state(pair) == RECALLING, "pair enters RECALLING")
	_check_profile_identity(pair, profile, profile_id, "RECALLING")
	pair.npc_dog.position = pair.park_spot
	pair._physics_process(0.0)
	_check(_state(pair) == DEPARTING, "close recall enters DEPARTING")
	_check_profile_identity(pair, profile, profile_id, "DEPARTING")
	_check(not pair.leash.detached and pair.leash.visible, "DEPARTING restores the real leash")

	pair.npc_owner.position = Vector2(pair.walking_lane_x, 80.0)
	pair._physics_process(0.0)
	_check(_state(pair) == WALKING, "gate clearance resumes WALKING")
	_check_profile_identity(pair, profile, profile_id, "resumed WALKING")
	_check(pair.get_instance_id() == pair_id, "pair identity persists")
	_check(pair.npc_owner.get_instance_id() == owner_id, "owner identity persists")
	_check(pair.npc_dog.get_instance_id() == dog_id, "dog identity persists")
	_check(pair.leash.get_instance_id() == leash_id, "leash identity persists")
	return pair


func _test_parked_departure_and_home_interrupt(main: FakeMain, player: Node2D) -> void:
	var departure := _make_pair(main, player, 2718)
	departure.configure_park_area(0.0, PARK_BOUNDS)
	var departure_profile: Dictionary = departure.appearance_profile
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
	_check_profile_identity(departure, departure_profile, departure_id, "initialized PARKED")

	var interrupted := _make_pair(main, player, 3141)
	interrupted.configure_park_area(0.0, PARK_BOUNDS)
	var interrupted_profile: Dictionary = interrupted.appearance_profile
	var interrupted_id := String(interrupted_profile["id"])
	_check(bool(interrupted.begin_park_arrival(10, PARK_SPOT)), "interrupt fixture enters ARRIVING")
	main.phase = "home"
	interrupted._physics_process(0.0)
	_check(_state(interrupted) == RECALLING, "home interrupts arrival into RECALLING")
	_check_profile_identity(interrupted, interrupted_profile, interrupted_id, "home-interrupted RECALLING")
	main.phase = "freedom"


func _test_render_smoke(pair: Node2D, player: Node2D) -> void:
	player.position = pair.npc_dog.position
	seed(98765)
	var expected_next := randf()
	seed(98765)
	for profile_id: String in DogAppearanceScript.profile_ids():
		pair.appearance_profile = DogAppearanceScript.get_profile(profile_id)
		pair.queue_redraw()
		await process_frame
	var actual_next := randf()
	_check(is_equal_approx(actual_next, expected_next), "pair drawing preserves global RNG")
	_check(true, "parent CanvasItem draws owner and every dog profile at zero forward")


func _cleanup() -> void:
	for index in range(fixtures.size() - 1, -1, -1):
		var fixture := fixtures[index]
		if is_instance_valid(fixture):
			fixture.free()
	fixtures.clear()


func _finish() -> void:
	_cleanup()
	if failures > 0:
		print("test_pair_dog_appearance: %d FAILURES" % failures)
		quit(1)
	else:
		print("test_pair_dog_appearance: OK")
		quit(0)


func _run() -> void:
	var probe := Node2D.new()
	probe.set_script(PairScript)
	var has_profile := _has_property(probe, "appearance_profile")
	_check(has_profile, "otherpair stores appearance_profile")
	probe.free()
	if not has_profile:
		_finish()
		return

	var main := _make_main()
	var player := _make_player()
	_test_exact_setup_rng(main, player)
	var lifecycle_pair := _test_lifecycle_profile_persistence(main, player)
	_test_parked_departure_and_home_interrupt(main, player)
	await _test_render_smoke(lifecycle_pair, player)
	_finish()


func _initialize() -> void:
	call_deferred("_run")
