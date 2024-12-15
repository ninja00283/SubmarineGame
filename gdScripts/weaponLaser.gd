extends Node2D

@onready var rayCast2D: RayCast2D = $RayCast2D
@onready var line2D: Line2D = $Line2D
@onready var timer: Timer = $Timer
@onready var lineEdit: LineEdit = $LineEdit
@onready var animationPlayer: AnimationPlayer = $AnimationPlayer
@onready var laserHit: Sprite2D = $laserHit
@onready var laserStart: Sprite2D = $laserStart
@onready var gpupHit: GPUParticles2D = $GPUPHit
@onready var gpupStart: GPUParticles2D = $GPUPStart
@onready var sprite2D: Sprite2D = $Sprite2D

@export var amplitude: float = 1
@export var frequency: float = 20
@export var minBrightness: float = 0.8
@export var maxBrightness: float = 1.2

var castPoint
var collisionPoint
var angle = 0
var currentHitObject = null
var damageTimer = 0.0
var damageRate = 1.5
var sineOffset: float = 0.0  # Optional offset for phase control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	animationPlayer.play("laserOn")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Sine wave brightness modulation
	var sineValue = amplitude * sin(frequency * Time.get_ticks_usec() / 1000000.0 + sineOffset)
	var brightness = lerp(minBrightness, maxBrightness, (sineValue + 1) / 2)  # Mapping sine to desired brightness range
	line2D.modulate = Color(brightness, brightness, brightness)  # Apply the brightness to Line2D

	# Raycast update and collision handling
	rayCast2D.force_raycast_update()
	line2D.points[0] = to_local(rayCast2D.global_position)
	if rayCast2D.is_colliding():
		var collisionPoint = rayCast2D.get_collision_point()
		laserHit.position = to_local(collisionPoint)
		line2D.points[1] = to_local(collisionPoint)

		# Check if the collider has HP.
		var hitObject = rayCast2D.get_collider()
		if hitObject != null and "HP" in hitObject:
			currentHitObject = hitObject
		else:
			print("Target doesn't have HP value")
			currentHitObject = null
	else:
		var targetPosition = rayCast2D.target_position
		gpupHit.position = to_local(targetPosition)
		laserHit.position = to_local(targetPosition)
		line2D.points[1] = to_local(rayCast2D.global_position + rayCast2D.get_global_transform().basis_xform(targetPosition))
		currentHitObject = null

	if currentHitObject != null:
		damageTimer += delta
		if damageTimer >= 0.02:
			currentHitObject.HP -= damageRate
			print(currentHitObject.get_class(), " HP: ", currentHitObject.HP)
			damageTimer = 0
	
	if rayCast2D.is_colliding():
		gpupHit.global_rotation = rayCast2D.get_collision_normal().angle()
		gpupHit.position = laserHit.position

func laserOff():
	animationPlayer.stop()
	animationPlayer.play("laserOff")
