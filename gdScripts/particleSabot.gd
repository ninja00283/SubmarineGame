extends RigidBody2D

func _process(delta: float) -> void:
	linear_velocity.y += 980 * delta
	angular_velocity += angular_velocity * -0.01 * (60 * delta)

	# Code block to rotate the sabot petal perpendicularly to velocity (faster rotation the closer to the normal angle)
	if cos(rotation) > 0.1 + linear_velocity.normalized().angle():
		if sin(rotation) > 0.1 + linear_velocity.normalized().angle():
			angular_velocity -= 0.05 * (linear_velocity.length() / 6144) * (60 * delta)
	if cos(rotation) < -0.1 + linear_velocity.normalized().angle():
		if sin(rotation) < -0.1 + linear_velocity.normalized().angle():
			angular_velocity -= 0.05 * (linear_velocity.length() / 6144) * (60 * delta)
	if cos(rotation) > 0.1 + linear_velocity.normalized().angle():
		if sin(rotation) < -0.1 + linear_velocity.normalized().angle():
			angular_velocity += 0.05 * (linear_velocity.length() / 6144) * (60 * delta)
	if cos(rotation) < -0.1 + linear_velocity.normalized().angle():
		if sin(rotation) > 0.1 + linear_velocity.normalized().angle():
			angular_velocity += 0.05 * (linear_velocity.length() / 6144) * (60 * delta)
