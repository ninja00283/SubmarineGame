extends CharacterBody2D

@onready var gpup2D1: GPUParticles2D = $GPUParticles2D1
@onready var gpup2D2: GPUParticles2D = $GPUParticles2D2
@onready var gpup2D3: GPUParticles2D = $GPUParticles2D3
@onready var gpup2D4: GPUParticles2D = $GPUParticles2D4
@onready var gpup2D5: GPUParticles2D = $GPUParticles2D5
@onready var gpup2D6: GPUParticles2D = $GPUParticles2D6
@onready var area2D: Area2D = $Area2D
@onready var APDSCore: Sprite2D = $APDSCore
@onready var queueFreeDelay: Timer = $queueFreeDelay
@onready var APFSDSFins: Sprite2D = $APFSDSFins

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
var marked: bool = false # Whether or not debug markers are shown
var ended: bool = false #Whether or not the railgun has left the screen
var cooldown: bool = false # Whether or not the cooldown period has passed
var cooldownStarted: bool = false # Whether or not the cooldown period is running
var startingPoint: Vector2 # The position the weapon was fired at
var damage: float = 120.0 # The weapons damage point blank

func _ready() -> void:
	GlobalTrail.addNode(self, 16, Vector2(-24, 0), 0.2)
	startingPoint = global_position

# These functions are above _process() because "entry" is used in the process function and needs to be determined first
func _onRigidBody2dBodyExited(_body: Node) -> void:
	var query = PhysicsPointQueryParameters2D.new()
	query.position = global_position
	query.collide_with_bodies
	if get_world_2d().direct_space_state.intersect_point(query).is_empty():
		if abs(rotation - velocity.angle()) < 0.6981:
			APFSDSFins.hide()
			entry = false

func _onRigidBody2dBodyEntered(body: Node) -> void:
	var query = PhysicsPointQueryParameters2D.new()
	query.position = global_position
	query.collide_with_bodies
	if get_world_2d().direct_space_state.intersect_point(query).is_empty():
		collision = true
		entry = true
		var AoA = abs(velocity.angle()) - abs(global_rotation)
		print("Vel angle: ", velocity.angle())
		print("Rotation(Rad): ", rotation)
		print("Hit angle: ", AoA)
		if "HP" in body:
			body.HP -= damage * (velocity.length() / 6144)
			player.attackDamageF(damage * (velocity.length() / 6144), false)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	velocity.y += 1240 * delta
	rotation = velocity.angle()
	if queueFreeDelay.time_left <= 2.0:
		GlobalTrail.removeNode(self)
	if velocity.length() <= 5120:
		gpup2D1.amount_ratio = velocity.length() / 5120
		gpup2D2.amount_ratio = velocity.length() / 5120
		gpup2D3.amount_ratio = velocity.length() / 5120
		gpup2D4.amount_ratio = velocity.length() / 5120
		gpup2D5.amount_ratio = velocity.length() / 5120
	if collision:
		attempts += 1
	distanceTravelled = (global_position - previousPosition).length()
	distanceTravelledVec2 = global_position - previousPosition
	if not cooldownStarted:
		cooldownStarted = true
		await get_tree().process_frame
		await get_tree().process_frame
		await get_tree().process_frame
		cooldown = true
	if cooldown and not ended:
		points.append(global_position)
		for i in range(int(distanceTravelled / 32)):
			points.append(previousPosition + i * (distanceTravelledVec2 / (distanceTravelled / 32)))

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
			if entry and not gpup2D1Emitted:
				gpup2D1.emitting = true
				gpup2D1Emitted = true
			gpup2D1.reparent(get_tree().root)
		previousCollided = !get_world_2d().direct_space_state.intersect_point(query).is_empty()

	if global_position >= Vector2(2160, 3840) or global_position <= Vector2(-2160, -3840):
		ended = true
		gpup2D6.emitting = true
		global_position = Vector2(0, 0)
		GlobalTrail.removeNode(self)
		velocity = Vector2(0, 0)
		hide()
		area2D.monitorable = false
		area2D.monitoring = false
		if not attackDmgS:
			player.attackDamageF(0.0, true)
			attackDmgS = true
	previousPosition = global_position
	move_and_slide()

func _on_queue_free_delay_timeout() -> void:
	if not attackDmgS:
		player.attackDamageF(0.0, true)
		attackDmgS = true
	queue_free()

func mark(array):
	var markers: Dictionary = {}
	const marker = preload("res://scenes/Marker.tscn")
	for pos in array:
		if not pos in markers.values():
			var markerScene = marker.instantiate()
			markerScene.position = pos
			markers[markerScene] = pos
			get_tree().root.add_child(markerScene)


		#else:
			#markers.find_key(pos).queue_free()
			#markers.erase(markers.find_key(pos))
