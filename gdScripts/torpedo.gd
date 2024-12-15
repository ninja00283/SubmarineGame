extends RigidBody2D

@onready var armingDelay: Timer = $armingDelay
@onready var fuzeDelay = $Timer
@onready var queueFree: Timer = $Timer2
@onready var impactFuse: Area2D = $Area2D
@onready var detectionRadii: Area2D = $detectionRadii
@onready var sprite2D: Sprite2D = $Sprite2D2
@onready var gpup2D1: GPUParticles2D = $GPUParticles2D1
@onready var gpup2D2: GPUParticles2D = $GPUParticles2D2
@onready var gpup2D3: GPUParticles2D = $GPUParticles2D3
@onready var gpup2D4: GPUParticles2D = $GPUParticles2D4
@onready var gpup2D5: GPUParticles2D = $GPUParticles2D5
@onready var gpup2D6: GPUParticles2D = $GPUParticles2D6
@onready var rayCast2D: RayCast2D = $RayCast2D
@onready var explosionRadii: Area2D = $explosionRadii
@onready var collider2D: CollisionPolygon2D = $Area2D/CollisionPolygon2D2
@onready var collider2D2: CollisionPolygon2D = $CollisionPolygon2D2
@onready var fuseCol: CollisionPolygon2D = $Area2D/CollisionPolygon2D2
@onready var heat: RayCast2D = $HEAT

var weaponTorpedo = preload("res://assets/weaponTorpedo.tres")
var target = null
var distance = 0
var HP = 10
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	armingDelay.start()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if HP <= 0:
		queueFree.start()
		hit()

func _on_area_2d_body_entered(body):
	if body != self:
		gpup2D4.emitting = true
		gpup2D5.emitting = true
		gpup2D6.emitting = true
		if heat.is_colliding():
			var collider = heat.get_collider()
			if collider.is_class("RigidBody2D") or collider.is_class("CharacterBody2D"):
				if "HP" in collider:
					collider.HP -= 200
					print("Collider HP: ", collider.HP)
		if rayCast2D.is_colliding():
			gpup2D4.global_rotation = rayCast2D.get_collision_normal().angle()
			gpup2D4.global_rotation_degrees -= 45
			gpup2D5.global_rotation = rayCast2D.get_collision_normal().angle()
		print(body)
		explode()
		hit()
		queueFree.start()

func _on_detection_radii_body_entered(body):
	target = body
	if not is_instance_valid(armingDelay):
		var relativePos = to_local(body.global_position)
		distance = sqrt(relativePos.x * relativePos.x + relativePos.y * relativePos.y)
		
		fuzeDelay.start()

func _on_timer_timeout():
	if target != null and distance <= 150:
		weaponTorpedo.spread = 180
		gpup2D4.emitting = true
		explode()
		hit()
		queueFree.start()

func _on_timer_2_timeout() -> void:
	queue_free()

func hit():
	collider2D2.position = Vector2(10000, 10000)
	linear_velocity = Vector2(0, 0)
	impactFuse.monitoring = false
	detectionRadii.monitoring = false
	gpup2D1.emitting = false
	gpup2D2.emitting = false
	gpup2D3.emitting = false
	sprite2D.hide()
	
func explode():
	for body in explosionRadii.get_overlapping_bodies():
		if body != self and "HP" in body:
			var damage = 12000 / (distance + 1) * pow(distance / (distance + 12), 6)
			body.HP -= damage
			print("Damaged:", body, "Damage:", damage, "Remaining HP:", body.HP)




func _on_arming_delay_timeout() -> void:
	armingDelay.queue_free()
