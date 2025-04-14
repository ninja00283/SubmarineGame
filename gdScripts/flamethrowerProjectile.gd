extends CharacterBody2D

@onready var gpup2D1: GPUParticles2D = $GPUP2D1
@onready var gpup2D2: GPUParticles2D = $GPUP2D2
@onready var flamethrowerProjectile = preload("res://scenes/flamethrowerProjectile.tscn")
@onready var meshIn2D: MeshInstance2D = $meshInstance2d
@onready var lifetime: Timer = $lifetime
@onready var queueFreeDelay: Timer = $queueFreeDelay
@onready var arming: Timer = $arming

var generation: int = 0
var locked: bool = false
var positionWhenLocked: Vector2
var objectsInArea: Array = []
var HP = 0.1
var flamethrower
var bodyLocked
var bodyLockedPos
var ended = false

func _ready() -> void:
	if generation <= 1:
		lifetime.wait_time = (1.5 / float(generation + 1)) + randf_range(1.0 / float(-(generation + 1)), 1.0 / float(generation + 1))
	lifetime.start()

func _process(delta: float) -> void:
	if HP <= 0.0:
		end()
	for object in objectsInArea:
		if "HP" in object and not "generation" in object and arming.is_stopped():
			object.HP -= 200.0 / (global_position - object.global_position).length() / (generation + 1) * delta
			flamethrower.damage += 200.0 / (global_position - object.global_position).length() / (generation + 1) * delta
	if locked:
		velocity = Vector2(0.0, 0.0)
		if bodyLocked:
			global_position = bodyLocked.global_position - (bodyLockedPos - positionWhenLocked)
	velocity += Vector2(0.0, -340.0) * delta
	var colInfo = move_and_collide(velocity * delta)
	if colInfo:
		var collider = colInfo.get_collider()
		velocity = velocity.bounce(colInfo.get_normal()) * 0.2
	move_and_slide()

func nextGen():
	if not ended:
		if not locked:
			if generation == 0:
				if randf_range(0.0, 1.0) > 0.15:
					for i in range(randi_range(1, 3)):
						var projectile: CharacterBody2D = flamethrowerProjectile.instantiate()
						projectile.velocity = Vector2.from_angle(self.velocity.angle() + randf_range(-0.1, 0.1)) * (velocity.length() * randf_range(0.9, 1.1))
						projectile.global_position = global_position
						get_tree().root.add_child(projectile)
						projectile.flamethrower = flamethrower
						projectile.meshIn2D.scale = Vector2(12.0, 12.0)
						projectile.gpup2D1.amount = 24
						projectile.generation = generation + 1

func end():
	meshIn2D.hide()
	velocity = Vector2.ZERO
	gpup2D1.emitting = false
	queueFreeDelay.start()
	collision_layer = 0
	ended = true
	lifetime.stop()

func _onQueueFreeDelayTimeout() -> void:
	queue_free()

func _onLifetimeTimeout() -> void:
	nextGen()
	end()

func _onArea2dBodyEntered(body: Node2D) -> void:
	if randf_range(0.0, 1.0) > 0.05 and is_instance_valid(flamethrower.player):
		if arming.is_stopped():
			if randf_range(0.0, 1.0) > 0.5:
				locked = true
				bodyLocked = body
				bodyLockedPos = body.global_position
				positionWhenLocked = global_position
				velocity = Vector2(0.0, 0.0)
			elif randf_range(0.0, 1.0) > 0.95:
				if "HP" in body:
					body.HP -= 6 / (generation + 1)
					flamethrower.damage += 6 / (generation + 1)
				locked = true
				meshIn2D.hide()
				gpup2D1.emitting = false
				gpup2D2.emitting = true
				end()
	else:
		gpup2D2.emitting = true
		end()

func _onArea2d2BodyEntered(body: Node2D) -> void:
	if "HP" in body:
		if is_instance_valid(body):
			objectsInArea.append(body)
			flamethrower.hitObjects.append(body)

func _onArea2d2BodyExited(body: Node2D) -> void:
	if body in objectsInArea:
		objectsInArea.erase(body)
