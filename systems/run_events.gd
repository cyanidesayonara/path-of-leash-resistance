class_name RunEvents
extends RefCounted

# Rare runs are selected without touching the global random sequence. The
# recorded run seed plus stable text bytes always produce the same bucket.


static func bucket(run_seed: int, level_id: String, event_id: String) -> int:
	var h := run_seed & 0x7fffffff
	for byte: int in ("%s|%s" % [level_id, event_id]).to_utf8_buffer():
		h = ((h ^ byte) * 16777619) & 0x7fffffff
	return h % 100


static func chosen(
	run_seed: int,
	level_id: String,
	event_id: String,
	weather: String,
	percent: int,
) -> bool:
	if event_id == "high_stream" and (level_id != "trail" or weather != "rain"):
		return false
	return bucket(run_seed, level_id, event_id) < percent
