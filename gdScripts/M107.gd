extends CharacterBody2D

@onready var gpup2D1: GPUParticles2D = $GPUParticles2D1
@onready var gpup2D2: GPUParticles2D = $GPUParticles2D2
@onready var gpup2D3: GPUParticles2D = $GPUParticles2D3
@onready var gpup2D4: GPUParticles2D = $GPUParticles2D4
@onready var proxyFuse: Area2D = $ProxyFuse


var gravity: float = 980.0 # Weapon gravity
var player: CharacterBody2D # The player that fired the weapon
var damage: float = 90.0 # The damage of the weapon
var HP: float = 12.0 # The projectile's hit points
var xDrag: float = 0.00006 # Drag on the x axis
var yDrag: float = 0.00003 # Drag on the y axis
var hit: bool = false # Whether or not the projectile has been triggered
var armingDelay: float = 0.25

func _ready() -> void:
	name = str("M107 ", randf())
	player.root.objects.append(self)
	$ArmingDelay.start(armingDelay)

func _physics_process(delta: float) -> void:
	if not hit:
		if global_position.y < -1080:
			gpup2D4.reparent(get_tree().root)
			gpup2D4.emitting = false
		else:
			gpup2D4.reparent(self)
			gpup2D4.global_position = global_position
			gpup2D4.emitting = true
	if global_position.y > 1080:
		global_position.y = 1080
		explode()
	if not hit:
		velocity.y += gravity * delta
	rotation = velocity.angle()
	var localVelocity = velocity.rotated(-rotation)

	var dragForce = Vector2(
		sign(localVelocity.x) * localVelocity.x * localVelocity.x * xDrag,
		sign(localVelocity.y) * localVelocity.y * localVelocity.y * yDrag
	)

	localVelocity -= dragForce * delta
	velocity = localVelocity.rotated(rotation)
	velocity *= 2
	if move_and_collide(velocity * delta):
		explode()
	velocity *= 0.5

func explode():
	gpup2D4.emitting = false
	if not hit:
		$Sprite2D.hide()
		gpup2D2.process_material.direction = Vector3(sin(rotation + PI / 2), cos(rotation + PI / 2), 0.0)
		gpup2D3.process_material.direction = Vector3(sin(rotation + PI / 2), cos(rotation + PI / 2), 0.0)
		gpup2D1.emitting = true
		gpup2D2.emitting = true
		gpup2D3.emitting = true
		hit = true
		velocity = Vector2(0.0, 0.0)
		for body in proxyFuse.get_overlapping_bodies():
			if body.is_in_group("Terrain"):
				$ProxyFuse/CollisionShape2D.scale *= 1.1
				body.get_parent().clip($ProxyFuse/CollisionShape2D)
				$ProxyFuse/CollisionShape2D.scale *= 0.90909090909090909
		for body in proxyFuse.get_overlapping_bodies():
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
						var aDamage: float
						aDamage = damage * 320 / (distance + 1) * pow(distance / (distance + 12), 6)
						body.HP -= aDamage
						player.attackDamageF(aDamage, false)
		await get_tree().create_timer(1.0).timeout
		if is_instance_valid(player):
			player.attackDamageF(0.0, true)
		queue_free()

func _onProxyFuseBodyEntered(body: Node2D) -> void:
	if $ArmingDelay.is_stopped():
		if not body.name == "Border" and not body.name.begins_with("M107"):
			explode()
			print(body)
