extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
var xDrag = 0.02
var yDrag = 0.02
var HP = 100

func _physics_process(delta: float) -> void:
	if HP <= 0:
		queue_free()
	velocity.x = velocity.x * (1 - xDrag)
	velocity.y = velocity.y * (1 - yDrag)
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	elif is_on_floor():
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
