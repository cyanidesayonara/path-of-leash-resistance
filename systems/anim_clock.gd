class_name AnimClock
extends RefCounted

# The clock for cosmetic animation (tail wags, flicker, blinking prompts): the
# wall clock in play. In shot mode it is the frame count instead, so two
# photographs of one build match pixel for pixel (tools/shot_diff.py). Never
# read it for gameplay: that runs on main.elapsed.
#
# A class rather than a method on the Game autoload, because entity scripts
# loaded by a --script test cannot see autoloads.

static var frame_clock := "--shot" in OS.get_cmdline_user_args()


static func msec() -> int:
	if frame_clock:
		return Engine.get_process_frames() * 1000 / 60
	return Time.get_ticks_msec()
