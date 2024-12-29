extends RigidBody2D

@onready var gpup2D1: GPUParticles2D = $GPUParticles2D1
@onready var gpup2D2: GPUParticles2D = $GPUParticles2D2
@onready var area2D: Area2D = $Area2D
@onready var APDSCore: Sprite2D = $APDSCore
@onready var queueFreeDelay: Timer = $queueFreeDelay

var player
var gpupEmitted = false
var attackDmgS = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if global_position >= Vector2(2160, 3840) or global_position <= Vector2(-2160, -3840):
		linear_velocity = Vector2(0, 0)
		APDSCore.hide()
		area2D.monitorable = false
		area2D.monitoring = false
		global_position = Vector2(0, 0)
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


func _on_queue_free_delay_timeout() -> void:
	queue_free()
