extends RigidBody2D

@onready var armingDelay: Timer = $armingDelay
@onready var detectionRadiiDelay: Timer = $detectionRadiiDelay
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
@onready var heat: Area2D = $HEAT

var damage
var weaponTorpedo = preload("res://assets/weaponTorpedo.tres")
var target = null
var distance = 0
var HP = 10
var gpup2D6C = false
var exploded = false
var HEATExploded = false

func _ready() -> void:
	armingDelay.start()

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("KillTorpedo"):
		HP = 0
	if HP <= 0:
		if gpup2D6C == false:
			hit()
			queueFreeDelay.start()
			gpup2D6C = true

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
	if not is_instance_valid(armingDelay):
		var relativePos = to_local(body.global_position)
		distance = sqrt(relativePos.x * relativePos.x + relativePos.y * relativePos.y)
		target = body
		detectionRadiiDelay.start()


func _on_detection_radii_delay_timeout() -> void:
	weaponTorpedo.spread = 180
	hit()
	queueFreeDelay.start()

func hit():
	linear_velocity = Vector2(0, 0)
	gpup2D4.emitting = true
	gpup2D5.emitting = true
	gpup2D6.emitting = true
	gpup2D1.emitting = false
	gpup2D2.emitting = false
	gpup2D3.emitting = false
	gpup2D6.amount_ratio = 0
	gpup2D7.amount_ratio = 0
	sprite2D.hide()
	if not exploded:
		explode()
		exploded = true
	if not HEATExploded:
		HEAT()
		HEATExploded = true
	collider2D2.position = Vector2(INF, INF)
	impactFuse.position = Vector2(INF, INF)
	heat.position = Vector2(INF, INF)
	detectionRadii.position = Vector2(INF, INF)
	explosionRadii.position = Vector2(INF, INF)
	queueFreeDelay.start()
	
	
func explode():
	var relativePos = to_local(target.global_position)
	distance = sqrt(relativePos.x * relativePos.x + relativePos.y * relativePos.y)
	for body in explosionRadii.get_overlapping_bodies():
		if body != self and "HP" in body:
			damage = 12000 / (distance + 1) * pow(distance / (distance + 12), 6)
			body.HP -= damage
			print("Damaged:", body, "Damage:", damage, "Remaining HP:", body.HP, "Method: Overpressure")
			print("Distance: ", distance)
			
func _on_arming_delay_timeout() -> void:
	armingDelay.queue_free()

func HEAT():
	if is_instance_valid(heat):
		for body in heat.get_overlapping_bodies():
			if body != self and "HP" in body:
				body.HP -= 200
				print("Damaged:", body, "Damage:", damage, "Remaining HP:", body.HP, "Method: HEAT")


func _queueFreeDelayTimeout() -> void:
	queue_free()
