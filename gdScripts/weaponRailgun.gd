extends RigidBody2D

@onready var gpup2D1: GPUParticles2D = $GPUParticles2D1
@onready var gpup2D2: GPUParticles2D = $GPUParticles2D2
@onready var area2D: Area2D = $Area2D
@onready var APDSCore: Sprite2D = $APDSCore
@onready var queueFreeDelay: Timer = $queueFreeDelay

var gpup2D1Emitted: bool = false # Bool to track whether or not gpup2D1 has emitted previously
var gpup2D2Emitted: bool = false # Bool to track whether or not gpup2D2 has emitted previously
var collision: bool = false # Bool to track whether or not the object has collided
var entry: bool = true # Bool to store whether or not the core is entering or exiting an object
var player: CharacterBody2D # The player that fired the weapon
var attempts: int = 0 # Counter to track how many attempts have been made to align the emitters (starts after colliding)
var attackDmgS: bool = false # Bool to stop resetting the "Attack damage: " readout and prevent constant position checks
var previousPosition: Vector2 # The global postion of the object in the previous frame
var previousCheckPosition: Vector2 # The Vector2 position the previous collision check occurred at
var distanceTravelled: float = 0.0 # Distance travelled between current and last frame
var distanceTravelledVec2: Vector2 # Distance travelled between current and last frame in Vector2 coordinates
var points: Array = [] # Stores all Vector2 positions that should be checked for collision
var previousCollided: bool # Stores whether or not the previous check resulted in a collision

# These functions are above _process() because "entry" is used in the process function and needs to be determined first
func _onRigidBody2dBodyEntered(body: Node) -> void:
	print("Collision")
	collision = true
	entry = true
	if "HP" in body:
		body.HP -= 120
		player.attackDamageF(120, false)


func _onRigidBody2dBodyExited(body: Node) -> void:
	entry = false
	print("Exit")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if collision:
		attempts += 1
	print("Attempt: ", attempts, " GPU1.pos: ", gpup2D1.position, " GPU2.pos: ", gpup2D2.position)
	distanceTravelled = (global_position - previousPosition).length()
	distanceTravelledVec2 = global_position - previousPosition
	for i in range(int(distanceTravelled / 4)):
		points.append(previousPosition + i * (distanceTravelledVec2 / (distanceTravelled / 4)))
	if collision:
		for point in points:
			var query = PhysicsPointQueryParameters2D.new()
			query.position = point
			query.collide_with_bodies = true
			if get_world_2d().direct_space_state.intersect_point(query).is_empty():
				if previousCollided:
					gpup2D2.position = point
					if not entry and not gpup2D2Emitted:
						gpup2D2.emitting = true
						gpup2D2Emitted = true
					gpup2D2.reparent(get_tree().root)
			elif not previousCollided:
				gpup2D1.position = point
				if attempts > 3 and not gpup2D1Emitted:
					gpup2D1.emitting = true
					gpup2D1Emitted = true
				gpup2D1.reparent(get_tree().root)
			previousCollided = !get_world_2d().direct_space_state.intersect_point(query).is_empty()

	if global_position >= Vector2(2160, 3840) or global_position <= Vector2(-2160, -3840):
		linear_velocity = Vector2(0, 0)
		APDSCore.hide()
		area2D.monitorable = false
		area2D.monitoring = false
		global_position = Vector2(0, 0)
		if not attackDmgS:
			player.attackDamageF(0.0, true)
			attackDmgS = true
	
	previousPosition = global_position

func _on_queue_free_delay_timeout() -> void:
	queue_free()
