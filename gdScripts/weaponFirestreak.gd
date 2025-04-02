extends RigidBody2D

@onready var armingDelay: Timer = $armingDelay
@onready var boosterStageTimer: Timer = $boosterStageTimer
@onready var cruiseStageTimer: Timer = $cruiseStageTimer
@onready var proximityFuzeRadii: Area2D = $proximityFuzeRadii
@onready var explosionRadii: Area2D = $explosionRadii
@onready var IRDetectionRadii: Area2D = $IRDetectionRadii
@onready var sprite2D: Sprite2D = $sprite2d
@onready var collisionPolygon2D: CollisionPolygon2D = $CollisionPolygon2D
@onready var gpup2D1: GPUParticles2D = $GPUParticles2D1
@onready var gpup2D2: GPUParticles2D = $GPUParticles2D2
@onready var gpup2D3: GPUParticles2D = $GPUParticles2D3
@onready var gpup2D4: GPUParticles2D = $GPUParticles2D4
@onready var queueFreeDelay: Timer = $queueFreeDelay
@onready var tip: Polygon2D = $tip
@onready var finB: Polygon2D = $finB
@onready var finT: Polygon2D = $finT

var HP = 5 # The current amount of hit points the missile has
var player # The player that fired the weapon
var targetAngle: float # The prograde vector (radians)
var dragCoefficient: float = 0.02 # Amount of drag, reduce for less drag
var exploded: bool = false # Bool to track whether or not the missile has detonated
var angleDifference: float # In radians, the difference between the current and target rotation
var target # Missiles targeted player

func _process(delta: float) -> void:
	if target and HP > 0:
		var distanceToTarget = global_position.distance_to(target.global_position) # The distance to the target
		var eta = distanceToTarget / linear_velocity.length() # In seconds, how long it will take to get to the target
		var intercept = target.global_position + target.velocity * eta # Vector2 coordinates on where the missile will intercept the target
		var direction = intercept - position # Vector2 representing which way the interception point is located
		angleDifference = fmod(direction.angle() - rotation + PI, 2 * PI) - PI
		if not is_instance_valid(armingDelay): 
			var torqueGain = 128.0
			var torque = angleDifference * torqueGain
			if abs(angular_velocity) < 1.2:
				if gpup2D1.emitting:
					apply_torque_impulse(clamp(torque / 2, -128, 128))
				else:
					apply_torque_impulse(clamp(torque / 2, -384, 384))
			if rad_to_deg(abs(angleDifference)) > 20 * abs(angular_velocity):
				apply_torque_impulse(-angular_velocity / 32)
	targetAngle = linear_velocity.normalized().angle()
	var lift: float = sin(2 * (rotation - targetAngle)) # Amount of lift, ranges from 1 to -1 depending on the missiles rotation
	var liftMultiplier: float = 0.015 # How much lift should affect the missile
	if HP <= 0 and not exploded:
		explode()
	apply_central_force(Vector2.from_angle(targetAngle + PI) * abs(sin(rotation - targetAngle)) * linear_velocity.length_squared() * dragCoefficient)
	apply_central_force(Vector2.from_angle(targetAngle + PI/2) * lift * linear_velocity.length_squared() * liftMultiplier)
	if HP > 0 and not exploded:
		if is_instance_valid(boosterStageTimer):
			constant_force = Vector2.from_angle(rotation) * 50000 + Vector2(0, 9800)
			gpup2D2.amount = 512
			gpup2D2.lifetime = 0.08
		elif is_instance_valid(cruiseStageTimer):
			constant_force = Vector2.from_angle(rotation) * 30000 + Vector2(0, 9800)
			gpup2D2.amount = 256
			gpup2D2.lifetime = 0.05
			gpup2D1.emitting = true
			gpup2D2.emitting = true
		if target and angleDifference > 1.5:
			constant_force = Vector2(0, 9800)
			gpup2D1.emitting = false
			gpup2D2.emitting = false

func _onArmingDelayTimeout() -> void:
	IRDetectionRadii.monitoring = true
	armingDelay.queue_free()


func _onCruiseStageTimerTimeout() -> void:
	cruiseStageTimer.queue_free()

func _onBoosterStageTimerTimeout() -> void:
	boosterStageTimer.queue_free()


func _onDetectionRadiiBodyEntered(body: Node2D) -> void:
	if not is_instance_valid(armingDelay) and not exploded and body is CharacterBody2D:
		print("Body entered firestreak proxy: ", body)
		explode()

func explode():
	exploded = true
	queueFreeDelay.start()
	sprite2D.hide()
	collisionPolygon2D.disabled = true
	collisionPolygon2D.hide()
	proximityFuzeRadii.monitoring = false
	tip.hide()
	finB.hide()
	finT.hide()
	gpup2D1.emitting = false
	gpup2D2.emitting = false
	gpup2D3.emitting = true
	gpup2D4.emitting = true
	for body in explosionRadii.get_overlapping_bodies():
		var newRaycast = RayCast2D.new()
		add_child(newRaycast)
		newRaycast.global_position = global_position
		newRaycast.target_position = to_local(body.global_position)
		newRaycast.force_raycast_update()
		if newRaycast.is_colliding():
			if newRaycast.get_collider() == body:
				newRaycast.queue_free()
				if body != self and "HP" in body:
					var relativePos = to_local(body.global_position)
					var distance = sqrt(relativePos.x * relativePos.x + relativePos.y * relativePos.y)
					var damage = 16000 / (distance + 1) * pow(distance / (distance + 12), 6)
					body.HP -= damage
					player.attackDamageF(damage, false)
			else:
				print("Target(",body,") obstructed")
	player.attackDamageF(0, true)


func _onQueueFreeDelayTimeout() -> void:
	queue_free()


func _onIrDetectionRadiiBodyEntered(body: Node2D) -> void:
	if "HP" in body and body is CharacterBody2D and not target:
		target = body
		tip.color = Color(1, 0, 0, 1)
		finB.color = Color(1, 0, 0, 1)
		finT.color = Color(1, 0, 0, 1)


func _onBodyCollided(body: Node) -> void:
	if not exploded:
		explode()
