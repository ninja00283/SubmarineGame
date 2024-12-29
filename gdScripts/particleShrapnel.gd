extends RigidBody2D

@onready var projectileSprite: Sprite2D = $ProjectileShrapnel
@onready var impactCollider: Area2D = $impactCollider
@onready var collider: CollisionPolygon2D = $CollisionPolygon2D
@onready var queueFreeDelay: Timer = $queueFreeDelay
@onready var gpup2D1: GPUParticles2D = $GPUParticles2D1

var player
var bomb
var HP = 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if HP <= 0:
		queueFree()
	if global_position >= Vector2(2160, 3840) or global_position <= Vector2(-2160, -3840):
		queueFree()


func _on_impact_collider_body_entered(body: Node2D) -> void:
	if "HP" in body:
		body.HP -= 30
		player.attackDamageF(30, false)
	queueFree()

func queueFree():
	gpup2D1.emitting = true
	queueFreeDelay.start()
	bomb.shrapnelAmount -= 1
	projectileSprite.hide()
	linear_velocity = Vector2(0, 0)
	self.collision_layer = 1 << 22
	self.collision_mask = 1 << 22

func _on_queue_free_delay_timeout() -> void:
	queue_free()
