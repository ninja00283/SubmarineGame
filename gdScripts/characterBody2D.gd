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
@onready var explosionRadii: Area2D = $explosionRadii
@onready var explodeDelay: Timer = $explodeDelay
@onready var attackDamageLabel: Label = $attackDamageLabel

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
var commands = ["move", "fire", "damage"]
var ammo = ["torpedo", "laser"]
var xDrag = 0.02
var yDrag = 0.02
var HP = 100.0
var deathDelayValid = true
var attackDamage = 0.0
@export var amplitude: float = 1
@export var frequency: float = 15
@export var minBrightness: float = 0.8
@export var maxBrightness: float = 1.2

func _physics_process(delta: float) -> void:
	if HP > 0:
		meshIn2D.set_self_modulate(Color(1+0.2-(HP/100),HP/100+0.2,0,1))
	var sineValue = amplitude*sin(frequency*Time.get_ticks_usec()/1000000.0)
	var brightness = lerp(minBrightness,maxBrightness,(sineValue+1)/2)
	gpup2D3.modulate = Color(brightness,brightness,brightness)
	if Input.is_action_just_pressed("Submit"):
		commandInterpret(commandInput, self)
	if HP <= 0 and deathDelayValid == true and deathDelay.is_stopped():
		deathDelayValid = false
		deathDelay.start()
		explodeDelay.start()
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
		if velocityLen < 800.0:
			particleRatio = velocityLen / 800.0

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
			magnitudeInput = magnitude.to_int()
			
			var angleRadians = deg_to_rad(angleDegreesInput)
			var x = magnitudeInput * cos(angleRadians) * 10
			var y = magnitudeInput * sin(angleRadians) * 10
			
			characterBody.velocity += Vector2(x*3, y*3)
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
			var magnitudeInput = 324
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
				var velocity = direction * magnitudeInput

				torpedo.linear_velocity = velocity

				var offset = direction * 100
				torpedo.position = characterBody.position + offset

				get_tree().root.add_child(torpedo)
				torpedo.player = self
			elif ammoType == "laser":
				var laser = laserScene.instantiate()
				laser.rotation = deg_to_rad(angleDegreesInput)

				var direction = Vector2(cos(laser.rotation), sin(laser.rotation))
				var velocity = direction * magnitudeInput

				var offset = direction * 100
				laser.position = characterBody.position + offset

				get_tree().root.add_child(laser)
				laser.player = self
				laser.reparent(self)
				if is_instance_valid(laser):
					print("Laser parent: ", laser.get_parent().get_class())

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
	collider2D.position = Vector2(INF, INF)
	velocity = Vector2(0, 0)
	commandInput.editable = false
	commandInput.hide()
	sprite2D.hide()
	meshIn2D.hide()
	collider2D.disabled = true
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
			var relativePos = to_local(body.global_position)
			var distance = sqrt(relativePos.x * relativePos.x + relativePos.y * relativePos.y)
			distances.append({"body": body, "distance": distance})
	
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
	var decimalPoints = 0
	var attackDamageR = int(attackDamage)
	if not reset:
		attackDamage += damage
	else:
		attackDamageLabel.text = str("Attack damage: ", attackDamageR)
		print("Attack damage: ", attackDamage)
		attackDamage = 0.0
