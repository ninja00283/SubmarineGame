extends RigidBody2D

func _process(delta: float) -> void:
	linear_velocity = linear_velocity * 0.99965
	angular_velocity += angular_velocity * -0.01 * (60 * delta)
	
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

func _on_area_2d_body_entered() -> void:
	queue_free()
