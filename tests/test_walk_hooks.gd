extends SceneTree

# main.gd calls a walk module's hooks by name (walk_mod.has_method), so any
# function in a module that happens to share a hook's name is called as that
# hook. El Mosaic's own scenery helper was once named draw_scenery, as El
# Bosc's hook is, and El Mosaic's world draw then failed on an argument
# count. Every hook main calls is read from main.gd, and every module
# function with that name must take that many arguments.

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
	for walk: String in mods:
		var mod: GDScript = mods[walk]
		for meth: Dictionary in mod.get_script_method_list():
			var name: String = meth["name"]
			if not hooks.has(name):
				continue
			var total: int = (meth["args"] as Array).size()
			var optional: int = (meth["default_args"] as Array).size()
			var want: int = hooks[name]
			_check(total - optional <= want and want <= total,
				"%s's %s takes %d argument(s) as a hook (it takes %d-%d)" % [walk, name, want, total - optional, total])
	print("test_walk_hooks: %d checks, %s" % [checks, "OK" if failures.is_empty() else "%d FAILED" % failures.size()])
	quit(1 if not failures.is_empty() else 0)
