extends SceneTree

# Every chase threat speaks for itself (systems/home_chase.gd kind_behavior):
# a threat that is not a machine never falls back to the sweeper's words
# (VRRROOM, CLONK, IT'S JAMMED!, IT'S STILL STUCK!, SWEPT!), and every line
# keeps the game's voice: banners and shouts in capitals.

const KEYS := ["warning", "warning_banner", "freed", "caught_shout", "jammed", "jammed_shout", "jammed_banner",
	"run_banner", "hold_banner"]

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var HomeChase: GDScript = load("res://systems/home_chase.gd")
	for kind in ["vet", "boars", "correfoc"]:
		var b: Dictionary = HomeChase.kind_behavior(kind)
		for k in KEYS:
			_check(b.has(k), "%s says its own %s" % [kind, k])
			if b.has(k):
				var line := String(b[k]).replace("%d", "")
				_check(line == line.to_upper(), "%s %s is in capitals" % [kind, k])
		if b.has("hold_banner"):
			_check(String(b.hold_banner).contains("%d"), "%s hold banner counts down" % kind)
	var flood: Dictionary = HomeChase.kind_behavior("flood")
	_check(flood.has("warning_banner"), "the flood has its own warning banner")
	if failures.is_empty():
		print("test_chase_voice: %d checks, OK" % checks)
		quit(0)
	else:
		print("test_chase_voice: %d checks, %d FAILURES" % [checks, failures.size()])
		quit(1)
