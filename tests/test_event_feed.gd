extends SceneTree

# The feed promises one line of text at one place (#59): the banner and up to
# two transient lines, each in its own slot. The first feed line used to sit
# 31px under the banner, then rise 17px and land 28% oversized, so its
# capitals climbed into the banner's. This lays the feed out with the banner
# and two lines at every pair of ages across their lives, and checks that no
# two lines' ink ever shares a row, and that it all stays on screen.

const EventFeed := preload("res://hud/event_feed.gd")

var checks := 0
var failures: Array[String] = []


func _check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures.append(what)
		print("FAIL: " + what)


func _initialize() -> void:
	var feed: Control = EventFeed.new()
	root.add_child(feed)
	var step := 0.05
	for vs: Vector2 in [Vector2(1280, 720), Vector2(1557, 720), Vector2(1280, 960)]:
		for with_banner in [true, false]:
			var worst := INF
			var t_old := 0.0
			while t_old < EventFeed.SHOW_S:
				var t_new := 0.0
				while t_new <= t_old:
					feed.banner = "GET THE CAT HOME! FOLLOW HER" if with_banner else ""
					feed.lines = Array([
						{"text": "HE'S FILMING! HE'S STOPPED", "tone": 0, "t": t_old},
						{"text": "YOU TANGLED THEM! +3", "tone": 1, "t": t_new},
					], TYPE_DICTIONARY, &"", null)
					var lay: Array[Dictionary] = feed.layout(vs)
					for i in range(lay.size() - 1):
						var a: Dictionary = lay[i]
						var b: Dictionary = lay[i + 1]
						var a_bottom: float = float(a.y) + feed.ink_below(int(a.size), int(a.outline), float(a.punch))
						var b_top: float = float(b.y) - feed.ink_above(int(b.size), int(b.outline), float(b.punch))
						worst = minf(worst, b_top - a_bottom)
					var last: Dictionary = lay[lay.size() - 1]
					var bottom: float = float(last.y) + feed.ink_below(int(last.size), int(last.outline), float(last.punch))
					if bottom > vs.y:
						_check(false, "%s banner=%s: the last line's ink ends at %.0f, past the bottom" % [vs, with_banner, bottom])
					t_new += step
				t_old += step
			_check(worst >= 0.0, "%s banner=%s: lines never share a row of ink (closest gap %.1f px)" % [vs, with_banner, worst])
	# the order still reads top to bottom: banner, then older, then newer
	feed.banner = "FETCH! BRING IT BACK 1/3 28S"
	feed.lines = Array([
		{"text": "OFF THE LEASH! GO FETCH", "tone": 3, "t": 0.0},
	], TYPE_DICTIONARY, &"", null)
	var lay2: Array[Dictionary] = feed.layout(Vector2(1280, 720))
	_check(lay2.size() == 2 and String(lay2[0].text).begins_with("FETCH") and float(lay2[1].y) > float(lay2[0].y),
		"the banner stays on top and the shout lands under it")
	# with no banner the first line keeps its old place
	feed.banner = ""
	var lay3: Array[Dictionary] = feed.layout(Vector2(1280, 720))
	_check(is_equal_approx(float(lay3[0].y), 720.0 * 0.63), "without a banner the feed starts where it always did")
	feed.free()
	print("\n%d checks, %d failures" % [checks, failures.size()])
	if failures.is_empty():
		print("test_event_feed: OK")
		quit(0)
	else:
		quit(1)
