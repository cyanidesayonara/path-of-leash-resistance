extends SceneTree

# main.gd calls a walk module's hooks by name (walk_mod.has_method), so any
# function in a module that happens to share a hook's name is called as that
# hook. El Mosaic's own scenery helper was once named draw_scenery, as El
# Bosc's hook is, and El Mosaic's world draw then failed on an argument
# count. Every hook main calls is read from main.gd, and every module
# function with that name must take that many arguments.
#
# A helper that collides with a hook at the same argument count passes the
# arity check and silently replaces main's own pass: Les Obres' footway
# drawer was draw_ground(m, b, vt, vb) until #348 renamed it. So each walk
# also declares the hooks its module means to answer, and a hook-named
# function outside that list fails. A new hook in a module is a new entry
# here, made on purpose.
const HOOKS := {
	"montjuic": ["build_layer", "draw_bollard", "draw_conveyor", "draw_edge_layer", "draw_freedom", "draw_ground", "draw_live", "grass_blocked", "tick"],
	"guell": ["draw_bollard", "draw_clearing", "draw_column", "draw_live", "tick_crowd"],
	"scrap": ["draw_bollard", "draw_column", "draw_grove", "draw_live", "draw_log_prop", "draw_overhead", "draw_top", "draw_van", "draw_verge", "draw_yard", "idle_status"],
	"trail": ["draw_bollard", "draw_path_edges", "draw_scenery", "draw_snack", "draw_trough_prop", "grass_blocked"],
	"station": ["draw_bollard", "draw_column", "draw_freedom_beyond", "draw_freedom_ground", "draw_live", "draw_log_prop", "draw_van"],
	"barri": ["draw_edge_layer", "draw_fountain", "draw_freedom_ground", "draw_gate_fence", "draw_live", "draw_performer", "grass_blocked", "surface"],
	"oldtown": ["build_layer", "draw_column", "draw_fountain", "draw_freedom", "draw_live", "draw_overhead", "tick"],
	"partit": ["draw_bollard", "draw_edge_layer", "draw_freedom", "draw_live", "draw_overhead", "draw_van"],
	"port": ["draw_bollard", "draw_edge_layer", "draw_freedom", "draw_live", "draw_overhead", "on_bark", "surface", "tick"],
	"reial": ["draw_edge_layer", "draw_overhead", "surface", "tick"],
	"vet": ["draw_edge_layer", "draw_overhead", "on_bark", "surface", "tick"],
	"tibidabo": ["build_layer", "draw_edge_layer", "draw_overhead", "surface", "tick"],
	"beach": ["draw_bin", "draw_cross_section", "draw_edge_layer", "draw_freedom", "draw_overhead", "surface", "takes_prints"],
	"rain": ["draw_column", "draw_freedom_beyond", "draw_freedom_ground", "draw_live", "draw_over_walkway"],
	"market": ["draw_column", "draw_live", "draw_overhead", "draw_van"],
	"site": ["draw_log_prop", "draw_performer", "draw_top", "draw_van"],
	"besos": ["draw_bollard", "draw_over_walkway"],
	"park": ["draw_live", "grass_blocked"],
	"neteja": ["draw_live"],
	"spook": ["draw_live", "draw_overhead", "draw_yard"],
	"aigues": ["draw_bollard", "draw_cross_section", "draw_edge_layer", "draw_fountain", "draw_live", "draw_snack", "rider_lane", "tick", "tree_kind"],
	"horta": ["draw_bollard", "draw_cross_section", "draw_edge_layer", "draw_fountain", "draw_live", "draw_snack", "tick", "tree_kind"],
	"llevant": ["draw_bin", "draw_cross_section", "draw_edge_layer", "draw_overhead", "rider_lane", "surface", "takes_prints"],
}

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
	var src := FileAccess.get_file_as_string("res://main.gd")
	var hooks := {}
	var re := RegEx.new()
	re.compile("walk_mod\\.(\\w+)\\(([^()]*)\\)")
	for mt: RegExMatch in re.search_all(src):
		var name := mt.get_string(1)
		if name == "has_method":
			continue
		var args := mt.get_string(2).strip_edges()
		var n := 0 if args.is_empty() else args.split(",").size()
		_check(not hooks.has(name) or int(hooks[name]) == n,
			"main calls %s with one argument count (%d and %d)" % [name, int(hooks.get(name, n)), n])
		hooks[name] = n
	_check(hooks.size() >= 20, "main's hooks are found (%d)" % hooks.size())
	var main_script: GDScript = load("res://main.gd")
	var mods: Dictionary = main_script.get_script_constant_map()["WALK_MODULES"]
	_check(mods.size() == HOOKS.size(), "every walk module declares its hooks here (%d modules, %d declared)" % [mods.size(), HOOKS.size()])
	for walk: String in mods:
		var mod: GDScript = mods[walk]
		var meant: Array = HOOKS.get(walk, [])
		var found := {}
		for meth: Dictionary in mod.get_script_method_list():
			var name: String = meth["name"]
			if not hooks.has(name):
				continue
			found[name] = true
			_check(meant.has(name),
				"%s's %s is named like a hook main calls but is not declared as one" % [walk, name])
			var total: int = (meth["args"] as Array).size()
			var optional: int = (meth["default_args"] as Array).size()
			var want: int = hooks[name]
			_check(total - optional <= want and want <= total,
				"%s's %s takes %d argument(s) as a hook (it takes %d-%d)" % [walk, name, want, total - optional, total])
		for name: String in meant:
			_check(found.has(name), "%s declares %s, but main calls no such hook or its module lacks it" % [walk, name])
	print("test_walk_hooks: %d checks, %s" % [checks, "OK" if failures.is_empty() else "%d FAILED" % failures.size()])
	quit(1 if not failures.is_empty() else 0)
