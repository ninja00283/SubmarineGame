extends CharacterBody2D

@onready var armDelay: Timer = $armingDelay
@onready var queueFreeDelay: Timer = $queueFreeDelay
@onready var impactFuse: Area2D = $Area2D
@onready var detectionRadii: Area2D = $detectionRadii
@onready var sprite2D: Sprite2D = $Sprite2D2
@onready var gpup2D1: GPUParticles2D = $GPUParticles2D1
@onready var gpup2D2: GPUParticles2D = $GPUParticles2D2
@onready var gpup2D3: GPUParticles2D = $GPUParticles2D3
@onready var gpup2D4: GPUParticles2D = $GPUParticles2D4
@onready var gpup2D5: GPUParticles2D = $GPUParticles2D5
@onready var gpup2D6: GPUParticles2D = $GPUParticles2D6
@onready var gpup2D7: GPUParticles2D = $GPUParticles2D7
@onready var rayCast2D: RayCast2D = $RayCast2D
@onready var explosionRadii: Area2D = $explosionRadii
@onready var collider2D: CollisionPolygon2D = $Area2D/CollisionPolygon2D2
@onready var collider2D2: CollisionPolygon2D = $CollisionPolygon2D2
@onready var fuseCol: CollisionPolygon2D = $Area2D/CollisionPolygon2D2
@onready var heatJet: Area2D = $HEAT
@onready var attackDamageDelay: Timer = $attackDamageDelay
@onready var inExplosionRadii: RayCast2D = $inExplosionRadii
@onready var mesh_instance_2d: MeshInstance2D = $meshInstance2d

var player
var damage
var armingDelay: float = 0.65
var HEATDamage: float = 80
var ExploDamage: float = 60
var weaponTorpedo = preload("res://assets/weaponTorpedo.tres")
var target = null
var rangeToTarget: float = 0
var HP: float = 5.0
var gpup2D6C: bool = false
var exploded: bool = false
var HEATExploded: bool = false
var targets: Array = []

func _ready() -> void:
	armDelay.start(armingDelay)
	name = "Torpedo"

func _process(delta: float) -> void:
	if HP <= 0:
		if gpup2D6C == false:
			hit()
			queueFreeDelay.start()
			gpup2D6C = true
	move_and_slide()

func _on_area_2d_body_entered(body):
	print("_on_area_2d_body_entered(body)")
	if body != self:
		target = body
		if rayCast2D.is_colliding():
			gpup2D4.global_rotation = rayCast2D.get_collision_normal().angle()
			gpup2D4.global_rotation_degrees -= 45
			gpup2D5.global_rotation = rayCast2D.get_collision_normal().angle()
		print(body)
		hit()
		queueFreeDelay.start()
	else:
		print("Body is self")

func _on_detection_radii_body_entered(body):
	if body != self and body.name != "Torpedo":
		if not is_instance_valid(armDelay):
			var relativePos = to_local(body.global_position)
			rangeToTarget = sqrt(relativePos.x * relativePos.x + relativePos.y * relativePos.y)
			target = body
			weaponTorpedo.spread = 180
			hit()
			queueFreeDelay.start()
		else:
			targets.append(body)

func _onDetectionRadiiBodyExited(body: Node2D) -> void:
	if body in targets:
		targets.erase(body)

func hit():
	velocity = Vector2(0, 0)
	gpup2D4.emitting = true
	gpup2D5.emitting = true
	gpup2D6.emitting = true
	gpup2D1.emitting = false
	gpup2D2.emitting = false
	gpup2D3.emitting = false
	sprite2D.hide()
	if not exploded:
		explode()
		exploded = true
	if not HEATExploded:
		HEAT()
		HEATExploded = true
	collider2D2.position = Vector2(8000, 8000)
	impactFuse.position = Vector2(8000, 8000)
	heatJet.position = Vector2(8000, 8000)
	detectionRadii.position = Vector2(8000, 8000)
	explosionRadii.position = Vector2(8000, 8000)
	queueFreeDelay.start()
	attackDamageDelay.start()

func explode():
	for body in $terrainExplosionRadii.get_overlapping_bodies():
		if body.is_in_group("Terrain"):
			body.get_parent().clip($terrainExplosionRadii/collisionShape2d)
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
					damage = ExploDamage * 60 / (distance + 1) * pow(distance / (distance + 12), 6)
					body.HP -= damage
					if damage <= 0:
						player.attackDamageF(0, true)
					else:
						player.attackDamageF(damage, false)
			else:
				print("Target(",body,") obstructed")

func _onArmingDelayTimeout() -> void:
	if targets.size() > 0:
		weaponTorpedo.spread = 180
		hit()
		queueFreeDelay.start()
	armDelay.queue_free()

func HEAT():
	if is_instance_valid(heatJet):
		for body in heatJet.get_overlapping_bodies():
			if body != self and "HP" in body:
				body.HP -= HEATDamage
				print("Damaged:", body, "Damage:", damage, "Remaining HP:", body.HP, "Method: HEAT")
				player.attackDamageF(HEATDamage, false)

func _queueFreeDelayTimeout() -> void:
	queue_free()

func _onAttackDamageDelayTimeout() -> void:
	player.attackDamageF(0, true)
