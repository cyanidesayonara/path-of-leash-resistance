extends SceneTree
func _initialize() -> void:
	for nm in ["rain", "guell", "title"]:
		var j := Music.job(nm)
		var cost := {}
		var cnt := {}
		var buf := PackedFloat32Array(); buf.resize(j.total)
		for e in j.events:
			var v := Music.Voice.make(int(e[0]), String(e[1]), e[2], 7)
			var k: String = e[1] if e[1] != "hit" else "hit_" + String(e[2][0])
			var t0 := Time.get_ticks_usec()
			v.render(buf, 0, j.total)
			cost[k] = cost.get(k, 0) + Time.get_ticks_usec() - t0
			cnt[k] = cnt.get(k, 0) + v.len
		var t1 := Time.get_ticks_usec()
		Music.Reverb.new(0.3).process(buf, 0, j.total)
		cost["reverb"] = Time.get_ticks_usec() - t1
		var s := ""
		for k in cost: s += "%s %dms (%.2fus/s)  " % [k, cost[k] / 1000, float(cost[k]) / maxf(cnt.get(k, j.total), 1)]
		print(nm, ": ", s)
	quit()
