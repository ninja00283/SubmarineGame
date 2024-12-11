extends RigidBody2D

@onready var fuzeDelay = $Timer

var target = null
var distance = 0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_area_2d_body_entered(body):
	if body.get_parent() != self.get_parent():
		if body.is_class("RigidBody2D") or body.is_class("CharacterBody2D"):
			body.HP -= 200
		print(body)
		queue_free()

func _on_detection_radii_body_entered(body):
	target = body
	if body.is_class("CharacterBody2D") and body.get_parent() != self.get_parent():
		var relativePos = to_local(body.global_position)
		distance = sqrt(relativePos.x * relativePos.x + relativePos.y * relativePos.y)
		fuzeDelay.start()

func _on_timer_timeout():
	if target != null and distance <= 150:
		target.HP -= 2500 / distance
		print(distance)
		print(target.HP)
		queue_free()
