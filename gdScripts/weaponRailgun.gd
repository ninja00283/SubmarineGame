extends RigidBody2D

@onready var gpup2D1: GPUParticles2D = $GPUParticles2D1
@onready var gpup2D2: GPUParticles2D = $GPUParticles2D2
@onready var gpup2D3: GPUParticles2D = $GPUParticles2D3
@onready var gpup2D4: GPUParticles2D = $GPUParticles2D4
@onready var gpup2D5: GPUParticles2D = $GPUParticles2D5
@onready var area2D: Area2D = $Area2D
@onready var APDSCore: Sprite2D = $APDSCore
@onready var queueFreeDelay: Timer = $queueFreeDelay
@onready var APFSDSFins: Sprite2D = $APFSDSFins

var targetAngle: float = 0.0 # Floating point to track what angle (radians) the velocity is
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

func _ready() -> void:
	GlobalTrail.addNode(self, 64, Vector2(-24, 0))

# These functions are above _process() because "entry" is used in the process function and needs to be determined first
func _onRigidBody2dBodyEntered(body: Node) -> void:
	print("Col")
	collision = true
	entry = true
	var AoA = abs(linear_velocity.angle()) - abs(global_rotation)
	print("Vel angle: ", linear_velocity.angle())
	print("Rotation(Rad): ", rotation)
	print("Hit angle: ", AoA)
	if abs(AoA) < 0.6981:
		if "HP" in body:
			body.HP -= 150 * (linear_velocity.length() / 6144)
			player.attackDamageF(150 * (linear_velocity.length() / 6144), false)
	else:
		collision_mask = 1 << 4

func _onRigidBody2dBodyExited(_body: Node) -> void:
	if abs(rotation - linear_velocity.angle()) < 0.6981:
		APFSDSFins.hide()
		entry = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if queueFreeDelay.time_left <= 2.0:
		GlobalTrail.removeNode(self)
	if not collision:
		targetAngle = linear_velocity.normalized().angle()
	else:
		targetAngle = linear_velocity.normalized().angle() + PI / 2
	if linear_velocity.length() < 5121:
		gpup2D1.amount_ratio = linear_velocity.length() / 5120
		gpup2D2.amount_ratio = linear_velocity.length() / 5120
		gpup2D3.amount_ratio = linear_velocity.length() / 5120
		gpup2D4.amount_ratio = linear_velocity.length() / 5120
		gpup2D5.amount_ratio = linear_velocity.length() / 5120
	# Code block to rotate the core perpendicularly to velocity (faster rotation the closer to the normal angle)
	if cos(rotation) > 0.1 + targetAngle:
		if sin(rotation) > 0.1 + targetAngle:
			angular_velocity -= 0.02 * (linear_velocity.length() / 6144) * (60 * delta) * abs(sin(rotation - targetAngle))
	if cos(rotation) < -0.1 + targetAngle:
		if sin(rotation) < -0.1 + targetAngle:
			angular_velocity += 0.02 * (linear_velocity.length() / 6144) * (60 * delta) * (abs(cos(rotation - targetAngle)) + 1)
	if cos(rotation) > 0.1 + targetAngle:
		if sin(rotation) < -0.1 + targetAngle:
			angular_velocity += 0.02 * (linear_velocity.length() / 6144) * (60 * delta) * abs(sin(rotation - targetAngle))
	if cos(rotation) < -0.1 + targetAngle:
		if sin(rotation) > 0.1 + targetAngle:
			angular_velocity -= 0.02 * (linear_velocity.length() / 6144) * (60 * delta) * (abs(cos(rotation - targetAngle)) + 1)
	if collision:
		attempts += 1
	distanceTravelled = (global_position - previousPosition).length()
	distanceTravelledVec2 = global_position - previousPosition
	points.append(global_position)
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
					gpup2D3.position = point
					gpup2D4.position = point
					gpup2D5.position = point
					if not entry and not gpup2D2Emitted:
						gpup2D2.emitting = true
						gpup2D3.emitting = true
						gpup2D4.emitting = true
						gpup2D5.emitting = true
						gpup2D2Emitted = true
					if gpup2D2.get_parent() != get_tree().root:
						gpup2D2.reparent(get_tree().root)
						gpup2D3.reparent(get_tree().root)
						gpup2D4.reparent(get_tree().root)
						gpup2D5.reparent(get_tree().root)
			elif not previousCollided:
				gpup2D1.position = point
				if attempts > 3 and not gpup2D1Emitted:
					gpup2D1.emitting = true
					gpup2D1Emitted = true
				gpup2D1.reparent(get_tree().root)
			previousCollided = !get_world_2d().direct_space_state.intersect_point(query).is_empty()

	if global_position >= Vector2(2160, 3840) or global_position <= Vector2(-2160, -3840):
		GlobalTrail.removeNode(self)
		linear_velocity = Vector2(0, 0)
		APDSCore.hide()
		area2D.monitorable = false
		area2D.monitoring = false
		if not attackDmgS:
			player.attackDamageF(0.0, true)
			attackDmgS = true
	
	previousPosition = global_position

func _on_queue_free_delay_timeout() -> void:
	if not attackDmgS:
		player.attackDamageF(0.0, true)
		attackDmgS = true
	queue_free()
