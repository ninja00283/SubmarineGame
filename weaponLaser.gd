extends Node2D

@onready var rayCast2D: RayCast2D = $RayCast2D
@onready var line2D: Line2D = $Line2D
@onready var timer: Timer = $Timer
@onready var lineEdit: LineEdit = $LineEdit
@onready var animationPlayer: AnimationPlayer = $AnimationPlayer

var castPoint
var angle = 0
var currentHitObject = null
var damageTimer = 0.0
var damageRate = 1.5

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	animationPlayer.play("laserOn")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	rayCast2D.force_raycast_update()
	if rayCast2D.is_colliding():
		line2D.points[0] = rayCast2D.position
		var hitObject = rayCast2D.get_collider()
		if hitObject != null and "HP" in hitObject:
			currentHitObject = hitObject
		else:
			print("Target doesn't have hp value")
	else:
		castPoint = rayCast2D.target_position
		line2D.points[1] = castPoint
		currentHitObject = null
	line2D.points[1] = rayCast2D.to_local(rayCast2D.get_collision_point())
	rayCast2D.rotation = 0
	line2D.rotation = 0
	if currentHitObject != null:
		damageTimer += delta
		if damageTimer >= 0.02:
			currentHitObject.HP -= damageRate
			print(currentHitObject.get_class(), " HP: ", currentHitObject.HP)
			damageTimer = 0 # Reset timer
		
func laserOff():
	animationPlayer.stop()
	animationPlayer.play("laserOff")
