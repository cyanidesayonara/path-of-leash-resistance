class_name CurrentFlow
extends RefCounted

# A directional velocity floor shared by floodwater and ordinary streams.
# Bodies keep any speed they already have with the flow; planting substitutes
# the gentler floor. Loose objects drift only while they are not being carried.


static func shove_body(
	body: CharacterBody2D,
	active: bool,
	direction: Vector2,
	speed: float,
	plant_speed: float,
	planted: bool,
	delta: float,
) -> void:
	if not active:
		return
	var flow := direction.normalized()
	var rate := plant_speed if planted else speed
	var extra := maxf(rate - body.velocity.dot(flow), 0.0)
	if extra > 0.0:
		body.move_and_collide(flow * extra * delta)


static func drift_loose(
	body: Node2D,
	active: bool,
	direction: Vector2,
	speed: float,
	delta: float,
	carried: bool,
) -> void:
	if active and not carried:
		body.position += direction.normalized() * speed * delta
