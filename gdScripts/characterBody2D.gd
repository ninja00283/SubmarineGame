extends CharacterBody2D

@onready var deathDelay: Timer = $deathDelay
@onready var queueFreeDelay: Timer = $queueFreeDelay
@onready var gpup2D1: GPUParticles2D = $GPUParticles2D1
@onready var gpup2D2: GPUParticles2D = $GPUParticles2D2
@onready var collider2D: CollisionShape2D = $CollisionShape2D
@onready var sprite2D: Sprite2D = $Sprite2D
@onready var meshIn2D: MeshInstance2D = $MeshInstance2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
var xDrag = 0.02
var yDrag = 0.02
var HP = 100
var deathDelayValid = true

func _physics_process(delta: float) -> void:
	if HP <= 0 and deathDelayValid == true and deathDelay.is_stopped():
		deathDelayValid = false
		deathDelay.start()
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


func _on_death_delay_timeout() -> void:
	sprite2D.hide()
	meshIn2D.hide()
	collider2D.disabled = true
	gpup2D1.emitting = true
	gpup2D2.emitting = true
	queueFreeDelay.start()
	deathDelay.queue_free()


func _on_queue_free_delay_timeout() -> void:
	queue_free()
