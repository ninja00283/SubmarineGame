extends Node2D

@export var shakeScale: float = 10.0
@export var shakeRotateScale: float = 1.0
@export var timerDur: float 
@onready var explosionRadii: Area2D = $explosionRadii
@onready var bombSprite: Sprite2D = $WeaponBomb
@onready var bombTrajectory: Sprite2D = $BombTrajectory
@onready var animPl: AnimationPlayer = $AnimationPlayer
@onready var impactFuse: Area2D = $impactFuse
@onready var timer: Timer = $Timer
@onready var flashAnim: AnimationPlayer = $flashAnim
@onready var queueFreeDelay: Timer = $queueFreeDelay
@onready var armingDelay: Timer = $armingDelay
@onready var particleShrapnel = preload("res://scenes/particleShrapnel.tscn")
@onready var gpup2D1: GPUParticles2D = $GPUParticles2D1

var player
var timePassed: float
var hasPlayed = false
var HP = 25.0
var originalPosition: Vector2
var originalRotation
var shaking: bool = false
var shrapnelArray = []
var shrapnelAmount = 6
var attackDmgSubm = false

func _ready() -> void:
	animPl.stop()
	flashAnim.stop()

func _process(delta):
	if not attackDmgSubm and shrapnelAmount <= 0:
		attackDmgSubm = true
		player.attackDamageF(0.0, true)
			
	timePassed += delta
	if timePassed >= timerDur:
		timePassed -= timerDur
		if is_instance_valid(flashAnim) and animPl.current_animation == "timerStarted":
			flashAnim.play("flashAnim")
	if HP <= 0:
		impact()
		self.collision_layer = 1 << 21
		self.collision_mask = 1 << 21
	if shaking:
		position = originalPosition + Vector2(randf_range(-shakeScale, shakeScale), randf_range(-shakeScale, shakeScale))
		rotation_degrees = originalRotation + randf_range(-shakeRotateScale, shakeRotateScale)
	else:
		originalPosition = position
		originalRotation = rotation_degrees


func _onImpactFuseActivated(body: Node2D) -> void:
	if not is_instance_valid(armingDelay) and body != self:
		print("Body temp: ", body)
		timer.start()
		animPl.play("timerStarted")

func impact():
	for impactFuseHit in explosionRadii.get_overlapping_bodies():
		if not is_instance_valid(armingDelay) and impactFuseHit != self and not hasPlayed:
			hasPlayed = true
			animPl.stop()
			flashAnim.queue_free()
			animPl.play("explode")
			shaking = true
			impactFuse.monitoring = false

func explode():
	self.collision_layer = 1 << 21
	self.collision_mask = 1 << 21
	projectiles()
	bombSprite.hide()
	bombTrajectory.hide()
	explodeVFX()
	queueFreeDelay.start()
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
					var damage = 12000 / (distance + 1) * pow(distance / (distance + 12), 6)
					body.HP -= damage
					if damage <= 0:
						player.attackDamageF(0, true)
					else:
						player.attackDamageF(damage, false)
			else:
				print("Target obstructed")
		else:
			print("Body is equal to player")

func _on_timer_timeout() -> void:
	impact()

func explodeVFX():
	gpup2D1.emitting = true

func projectiles():
	var particleCount = 6
	var angleStep = 360.0 / particleCount
	var angle = 0.0
	for i in range(particleCount):
		var shrapnel = particleShrapnel.instantiate()
		shrapnel.bomb = self
		shrapnel.player = player
		shrapnel.rotation_degrees = angle
		angle += angleStep
		shrapnel.global_position = global_position
		var direction = Vector2(cos(shrapnel.rotation), sin(shrapnel.rotation))
		shrapnel.linear_velocity = direction.normalized() * 2048
		shrapnelArray.append(shrapnel)
		get_tree().root.add_child(shrapnel)

	
func _on_queue_free_delay_timeout() -> void:
	queue_free()

func _on_arming_delay_timeout() -> void:
	armingDelay.queue_free()
