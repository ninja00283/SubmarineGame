extends Node2D

@export var shakeScale: float = 10.0
@export var shakeRotateScale: float = 1.0
@export var timerDur: float 
@onready var explosionRadii: Area2D = $explosionRadii
@onready var bombSprite: Sprite2D = $WeaponBomb
@onready var animPl: AnimationPlayer = $AnimationPlayer
@onready var impactFuse: Area2D = $impactFuse
@onready var timer: Timer = $Timer
@onready var flashAnim: AnimationPlayer = $flashAnim
@onready var queueFreeDelay: Timer = $queueFreeDelay
@onready var attackDamageFDelay: Timer = $attackDamageFDelay
@onready var armingDelay: Timer = $armingDelay

var player
var timePassed: float
var hasPlayed = false
var HP = 25.0
var originalPosition: Vector2
var originalRotation
var shaking: bool = false

func _ready() -> void:
	armingDelay.start()
	animPl.stop()
	flashAnim.stop()

func _process(delta):
	timePassed += delta
	if timePassed >= timerDur:
		timePassed -= timerDur
		if is_instance_valid(flashAnim) and animPl.current_animation == "timerStarted":
			flashAnim.play("flashAnim")
	if HP <= 0:
		impact()
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
	attackDamageFDelay.start()
	hide()
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
	pass # add kaboom vfx code here, was too tired to do when this func was made

func _on_queue_free_delay_timeout() -> void:
	queue_free()


func _on_attack_damage_f_delay_timeout() -> void:
	player.attackDamageF(0, true)


func _on_arming_delay_timeout() -> void:
	armingDelay.queue_free()
