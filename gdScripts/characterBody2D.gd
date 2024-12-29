extends CharacterBody2D

@onready var deathDelay: Timer = $deathDelay
@onready var queueFreeDelay: Timer = $queueFreeDelay
@onready var gpup2D1: GPUParticles2D = $GPUParticles2D1
@onready var gpup2D2: GPUParticles2D = $GPUParticles2D2
@onready var gpup2D3: GPUParticles2D = $GPUParticles2D3
@onready var gpup2D4: GPUParticles2D = $GPUParticles2D4
@onready var gpup2D5: GPUParticles2D = $GPUParticles2D5
@onready var collider2D: CollisionShape2D = $CollisionShape2D
@onready var sprite2D: Sprite2D = $Sprite2D
@onready var meshIn2D: MeshInstance2D = $MeshInstance2D
@onready var commandInput: LineEdit = $Control/commandInput
@onready var torpedoScene = preload("res://scenes/weaponTorpedo.tscn")
@onready var laserScene = preload("res://scenes/weaponLaser.tscn")
@onready var railgunScene = preload("res://scenes/weaponRailgun.tscn")
@onready var sabotScene = preload("res://scenes/particleSabot.tscn")
@onready var bombScene = preload("res://scenes/weaponbomb.tscn")
@onready var explosionRadii: Area2D = $explosionRadii
@onready var explodeDelay: Timer = $explodeDelay
@onready var attackDamageLabel: Label = $attackDamageLabel
@onready var animPl: AnimationPlayer = $AnimationPlayer
@onready var deathShader: MeshInstance2D = $deathShader

var shaderMaterial = preload("res://assets/weaponBomb.tres")
var deathShaderShowDur = Time.get_ticks_msec()
var deathShaderRan = false
var commands = ["move", "fire", "damage"]
var ammo = ["torpedo", "laser", "railgun", "bomb"]
var xDrag = 0.02
var yDrag = 0.02
var HP = 100.0
var deathDelayValid = true
var attackDamage = 0.0
var shakeDur: float = INF
@export var shakeScale: float = 0.0
var amplitude: float = 1
var frequency: float = 15
var minBrightness: float = 0.85
var maxBrightness: float = 1.15
var originalPosition: Vector2
var shaking: bool = false
var root 

func _physics_process(delta: float) -> void:
	originalPosition = position
	if HP > 0:
		meshIn2D.set_self_modulate(Color(1+0.2-(HP/100),HP/100+0.2,0,1))
	var sineValue = amplitude*sin(frequency*Time.get_ticks_usec()/1000000.0)
	var brightness = lerp(minBrightness,maxBrightness,(sineValue+1)/2)
	gpup2D3.modulate = Color(brightness,brightness,brightness)
	if Input.is_action_just_pressed("Submit"):
		commandInterpret(commandInput, self)
	if HP <= 0 and deathDelayValid == true and deathDelay.is_stopped():
		attackDamageLabel.hide()
		collision_layer = 1 << 19
		collision_mask = 1 << 17
		animPl.stop()
		animPl.play("death")
		commandInput.hide()
		root.positionCamera(position)
		meshIn2D.set_self_modulate(Color(0,0,0,0.75))
		deathDelayValid = false
	velocity.x = velocity.x * (1 - xDrag)
	velocity.y = velocity.y * (1 - yDrag)
	if not is_on_floor():
		velocity += get_gravity() * delta

	move_and_slide()
	var colInfo = move_and_collide(velocity * delta)
	if colInfo:
		var collider = colInfo.get_collider()
		if collider is CharacterBody2D and "HP" in collider:
			var transferVelo = velocity * 0.5
			var remainingVelo = velocity * 0.5

			collider.HP -= velocity.length() * 0.08
			HP -= velocity.length() * 0.08
			collider.velocity += transferVelo
			velocity = remainingVelo.bounce(colInfo.get_normal())
		else:
			velocity = velocity.bounce(colInfo.get_normal()) * 0.9
			
		var velocityLen = velocity.length()
		var particleRatio = 1.0
		if velocityLen < 1600.0:
			particleRatio = velocityLen / 1600.0
		var newgpup2D4 = gpup2D4.duplicate() as GPUParticles2D
		var newgpup2D5 = gpup2D5.duplicate() as GPUParticles2D
		var colPos = colInfo.get_position()
		newgpup2D4.global_position = colPos
		newgpup2D4.rotation_degrees = rad_to_deg(colInfo.get_normal().angle()) - 90
		newgpup2D4.amount_ratio = particleRatio
		newgpup2D4.emitting = true
		newgpup2D5.global_position = colPos
		newgpup2D5.rotation_degrees = rad_to_deg(colInfo.get_normal().angle()) + 90
		newgpup2D5.amount_ratio = particleRatio
		newgpup2D5.emitting = true
		get_tree().root.add_child(newgpup2D4)
		get_tree().root.add_child(newgpup2D5)
		
	if shaking:
		position = originalPosition + Vector2(
			randf_range(-shakeScale, shakeScale), 
			randf_range(-shakeScale, shakeScale)
		)


func commandInterpret(input: LineEdit, characterBody: CharacterBody2D):
	var text = input.text.to_lower().strip_edges()
	var parts = text.split(" ")
	if parts.size() > 0:
		var command = parts[0]
		if command in commands:
			match command:
				"move":
					moveCommand(parts, characterBody)
				"fire":
					fireCommand(parts, characterBody)
				"damage":
					damageCommand(parts, characterBody)
			input.clear()
			return
	input.clear()

func moveCommand(parts: Array, characterBody: CharacterBody2D):
	if parts.size() == 3:
		var angleDegreesInput = 0
		var magnitudeInput = 0
		var angle = parts[1]
		var magnitude = parts[2]
		if angle.is_valid_float() and magnitude.is_valid_float():
			angleDegreesInput = angle.to_int()
			magnitudeInput = clampi(magnitude.to_int(), 0, 300)
			
			var angleRadians = deg_to_rad(angleDegreesInput)
			var x = magnitudeInput * cos(angleRadians)
			var y = magnitudeInput * sin(angleRadians)
			
			characterBody.velocity += Vector2(x*30, y*30)
			print(x, " ", y, " Velocity added")
		else:
			print("Invalid move command. Both angle and magnitude must be numeric values.")
	else:
		print("Invalid move command. Expected 2 values: angle and magnitude.")

func fireCommand(parts: Array, characterBody: CharacterBody2D):
	if parts.size() >= 3:
		var ammoType = parts[1].to_lower()
		var angle = parts[2]
		
		if angle.is_valid_float():
			var angleDegreesInput = angle.to_int()
			if ammoType.is_valid_float():
				var ammoIndex = ammoType.to_int()
				if ammoIndex > 0 and ammoIndex <= ammo.size():
					ammoType = ammo[ammoIndex - 1]
				else:
					print("Invalid ammo index. Must be within the range of available weapons.")
					return
			elif ammo.has(ammoType):
				pass
			else:
				print("Invalid ammo type. Must be either a valid index or a weapon name.")
				return
			if ammoType == "torpedo":
				var torpedo = torpedoScene.instantiate()
				torpedo.rotation = deg_to_rad(angleDegreesInput)
				var direction = Vector2(cos(torpedo.rotation), sin(torpedo.rotation))
				var velocity = direction * 324
				torpedo.linear_velocity = velocity
				var offset = direction * 100
				torpedo.position = characterBody.position + offset
				get_tree().root.add_child(torpedo)
				root.objects.append(torpedo)
				torpedo.player = self
				
			elif ammoType == "laser":
				var laser = laserScene.instantiate()
				laser.rotation = deg_to_rad(angleDegreesInput)
				var direction = Vector2(cos(laser.rotation), sin(laser.rotation))
				var offset = direction * 100
				laser.position = characterBody.position + offset
				get_tree().root.add_child(laser)
				laser.player = self
				laser.reparent(self)
				
			elif ammoType == "railgun":
				var sabotT = sabotScene.instantiate()
				var sabotB = sabotScene.instantiate()
				var railgun = railgunScene.instantiate()
				railgun.rotation = deg_to_rad(angleDegreesInput)
				var direction = Vector2(cos(railgun.rotation), sin(railgun.rotation))
				var offset = direction * 100
				var velocity = direction * 6144
				railgun.linear_velocity = velocity
				railgun.position = characterBody.position + offset
				sabotT.position = railgun.position - Vector2(3.84, 12.8)
				sabotT.linear_velocity = velocity + Vector2(-1200, 1600)
				sabotB.position = railgun.position - Vector2(3.84, -12.8)
				sabotB.linear_velocity = velocity + Vector2(-1200, -1600)
				get_tree().root.add_child(railgun)
				get_tree().root.add_child(sabotT)
				get_tree().root.add_child(sabotB)
				root.objects.append(railgun)
				root.objects.append(sabotT)
				root.objects.append(sabotB)
				railgun.player = self
			elif ammoType == "bomb":
				var bomb = bombScene.instantiate()
				bomb.rotation = deg_to_rad(angleDegreesInput)
				var direction = Vector2(cos(bomb.rotation), sin(bomb.rotation))
				var offset = direction * 150
				var velocity = direction * 1536
				bomb.linear_velocity = velocity
				bomb.position = characterBody.position + offset
				bomb.player = self
				get_tree().root.add_child(bomb)
				root.objects.append(bomb)
			print("Fired ", ammoType, " at angle ", angleDegreesInput)
		else:
			print("Invalid inputs for fire command. Angle must be numeric.")
	else:
		print("Needs 3 parts: command type, ammo type, and firing angle. Parts: ", parts.size())

func damageCommand(parts: Array, characterBody: CharacterBody2D):
	if parts.size() >= 2:
		var damage = parts[1]
		if damage.is_valid_float():
			characterBody.HP -= damage.to_float()
			print("characterBody.HP: ",characterBody.HP)
		else:
			print("Damage value must be numeric")
	else:
		print("Incorrect part count; expected command type and numeric damage value.")

func _on_death_delay_timeout() -> void:
	animPl.stop()
	animPl.play("postDeath")
	explodeDelay.start()
	velocity = Vector2(0, 0)
	commandInput.editable = false
	commandInput.hide()
	sprite2D.hide()
	meshIn2D.hide()
	gpup2D1.emitting = true
	gpup2D2.emitting = true
	gpup2D3.emitting = true
	queueFreeDelay.start()
	deathDelay.queue_free()

func _on_queue_free_delay_timeout() -> void:
	queue_free()

func _explodeDelayEnd() -> void:
	var bodies = explosionRadii.get_overlapping_bodies()
	var distances = []
	
	for body in bodies:
		if body != self and "HP" in body:
			var newRaycast = RayCast2D.new()
			add_child(newRaycast)
			newRaycast.global_position = global_position
			newRaycast.target_position = to_local(body.global_position)
			newRaycast.force_raycast_update()
			if newRaycast.is_colliding():
				if newRaycast.get_collider() == body:
					newRaycast.queue_free()
					var relativePos = to_local(body.global_position)
					var distance = sqrt(relativePos.x * relativePos.x + relativePos.y * relativePos.y)
					distances.append({"body": body, "distance": distance})
				else:
					print("Target obstructed: ", body)
			else:
				newRaycast.queue_free()
	
	distances.sort_custom(func(a, b):
		return a["distance"] < b["distance"]
	)
	
	var maxDamageBodies = min(2, distances.size())
	for i in range(maxDamageBodies):
		var target = distances[i]["body"]
		var distance = distances[i]["distance"]
		var damage = 24000 / (distance + 1) * pow(distance / (distance + 12), 6)
		target.HP -= damage
		print("Damaged:", target, "Damage:", damage, "Remaining HP:", target.HP, "Method: Death")

		
func attackDamageF(damage, reset):
	var attackDamageR = int(attackDamage)
	if not reset:
		attackDamage += damage
	else:
		attackDamageLabel.text = str("Attack damage: ", attackDamageR)
		print("Attack damage: ", attackDamage)
		attackDamage = 0.0

func startShake():
	shaking = true
	await get_tree().create_timer(shakeDur).timeout
	shaking = false

func deathShaderAnimS():
	get_viewport().use_hdr_2d = false
	deathShader.show()
	deathShaderRan = true
	get_tree().paused = true

func deathShaderAnimP():
	get_viewport().use_hdr_2d = true
	deathShader.hide()
	deathShaderRan = true
	get_tree().paused = false
