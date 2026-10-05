extends RefCounted

const EventFeed := preload("res://hud/event_feed.gd")

# MONTJUÏC's TELEFÈRIC, the hidden way up. A tourist has dropped a ticket out
# on a terrace, off the path; a dog who finds it and takes her human to the
# low station rides a cabin up the cable past the hardest switchbacks, and
# back down again on the way home. Riding it is a goal of its own. The price:
# everything on the stretch it flies over.
#
# Static functions over main's state (cable_*), like the other systems. The
# ride is a short cinematic: the pair sit in the cabin, the walk holds still
# round them, and the leash is laid straight again at the far station.

const RIDE_S := 6.5              # the ride, station to station
const BOARD_R := 70.0            # how near the station both must be to board
const TICKET_R := 28.0           # how near the ticket the dog must get
# where the cable runs: each station on the inside of a big bend, near the
# middle of the view (the camera holds x 640 on the walk), so the cable flies
# straight up over the zigzag between; the ticket out on a terrace
const LOW_Y := -1250.0
const TOP_Y := -3900.0
const TICKET_Y := -820.0
const STATION_OUT := 74.0        # a station's distance off the path's edge
const TICKET_OUT := 120.0


static func is_on(m: Node2D) -> bool:
	return m.lvl == "montjuic"


# The stations and the ticket, laid out against the path once it is built.
static func build(m: Node2D) -> void:
	var lo: Vector2 = m.walk_edges(LOW_Y)
	var hi: Vector2 = m.walk_edges(TOP_Y)
	var tk: Vector2 = m.walk_edges(TICKET_Y)
	m.cable_low = Vector2(lo.x - STATION_OUT, LOW_Y)
	m.cable_top = Vector2(hi.y + STATION_OUT, TOP_Y)
	m.cable_ticket_pos = Vector2(tk.x - TICKET_OUT, TICKET_Y)
	var layer := Node2D.new()
	layer.set_script(load("res://world/cable_layer.gd"))
	layer.z_index = 30
	m.add_child(layer)
	layer.setup(m)


static func tick(m: Node2D, delta: float) -> void:
	if not is_on(m) or m.frozen or m.auto_walk:
		return
	var dp: Vector2 = m.dog.global_position
	if not m.cable_ticket and not m.cable_ticket_taken and dp.distance_to(m.cable_ticket_pos) < TICKET_R:
		m.cable_ticket = true
		m.cable_ticket_taken = true
		Sfx.play("pickup", 1.1)
		m.feed.say("A TELEFÈRIC TICKET!", EventFeed.Tone.GOOD)
		m.float_text(dp + Vector2(0, -34), "the cable car is up the path", Color(1, 0.92, 0.8), m.POP_SAY)
		return
	if not m.cable_ticket:
		return
	# up from the low station on the way out, down from the top on the way home
	var from: Vector2 = m.cable_low if m.phase == "out" else m.cable_top
	var to: Vector2 = m.cable_top if m.phase == "out" else m.cable_low
	if m.phase == "freedom" or (m.phase == "out" and m.cable_up_done) or (m.phase == "home" and m.cable_down_done):
		return
	if dp.distance_to(from) < BOARD_R and m.human.global_position.distance_to(from) < BOARD_R + 60.0:
		_board(m, from, to)


static func _board(m: Node2D, from: Vector2, to: Vector2) -> void:
	m.cable_from = from
	m.cable_to = to
	m.cable_t = 0.0
	m.cable_riding = true
	if m.phase == "out":
		m.cable_up_done = true
	else:
		m.cable_down_done = true
	m.dog.velocity = Vector2.ZERO
	m.human.velocity = Vector2.ZERO
	m.dog.visible = false
	m.human.visible = false
	m.leash.visible = false
	Sfx.play("ui", 0.8)
	m.feed.say("ALL ABOARD!", EventFeed.Tone.LOUD)


# Where the cabin is now: eased out of one station and into the other, the
# cable sagging a little between them.
static func cabin_pos(m: Node2D) -> Vector2:
	var f := smoothstep(0.0, 1.0, clampf(m.cable_t / RIDE_S, 0.0, 1.0))
	var p: Vector2 = m.cable_from.lerp(m.cable_to, f)
	return p + Vector2(0.0, 40.0 * sin(PI * f))


# One frame of the ride, run instead of the walk's physics while it lasts.
static func tick_ride(m: Node2D, delta: float) -> void:
	m.cable_t += delta
	var c := cabin_pos(m)
	m.dog.global_position = c + Vector2(10.0, -4.0)
	m.human.global_position = c + Vector2(-10.0, 4.0)
	if m.cable_t >= RIDE_S:
		_arrive(m)


static func _arrive(m: Node2D) -> void:
	m.cable_riding = false
	m.cable_rides += 1
	# off the cabin and onto the path, the human a step behind
	var e: Vector2 = m.walk_edges(m.cable_to.y)
	var cx := (e.x + e.y) * 0.5
	var ahead := -1.0 if m.phase == "out" else 1.0
	m.dog.global_position = Vector2(lerpf(m.cable_to.x, cx, 0.7), m.cable_to.y + ahead * 30.0)
	m.human.global_position = Vector2(lerpf(m.cable_to.x, cx, 0.55), m.cable_to.y - ahead * 30.0)
	m.dog.velocity = Vector2.ZERO
	m.human.velocity = Vector2.ZERO
	m.dog.visible = true
	m.human.visible = true
	m.leash.visible = true
	m.leash.resnap()
	# Tofu, if she is following you home, rode with you
	if m.tofu_quest_active:
		for tf in m.get_tree().get_nodes_in_group("tofu"):
			tf.global_position = m.human.global_position + Vector2(-26.0, 10.0)
	m.bones += 5
	m.float_text(m.dog.global_position + Vector2(0, -34), "what a view! +5", Color(0.7, 1.0, 0.75))
	if m.phase == "home":
		# one ticket, there and back
		m.cable_ticket = false
	m._update_hud()
