extends RigidBody2D

@onready var gpup2D1: GPUParticles2D = $GPUParticles2D1
@onready var gpup2D2: GPUParticles2D = $GPUParticles2D2
@onready var APDSCore: Sprite2D = $APDSCore
@onready var queueFreeDelay: Timer = $queueFreeDelay

var player
var attackDmgS = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if global_position.x >= 1930:
		linear_velocity = Vector2(0, 0)
		APDSCore.hide()
		global_position.x = 1929
		if not attackDmgS:
			player.attackDamageF(0.0, true)
			attackDmgS = true
	elif global_position.y >= 1090:
		linear_velocity = Vector2(0, 0)
		APDSCore.hide()
		global_position.y = 1089
		if not attackDmgS:
			player.attackDamageF(0.0, true)
			attackDmgS = true

func _on_area_2d_body_entered(body: Node2D) -> void:
	hit()
	if "HP" in body:
		body.HP -= 120
		player.attackDamageF(120, false)
	
func hit():
	gpup2D1.emitting = true
	gpup2D2.emitting = true
