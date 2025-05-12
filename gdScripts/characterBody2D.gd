extends CharacterBody2D

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
@onready var firestreakScene = preload("res://scenes/weaponFirestreak.tscn")
@onready var flamethrowerScene = preload("res://scenes/weaponFlamethrower.tscn")
@onready var M107Scene = preload("res://scenes/M107.tscn")
@onready var explosionRadii: Area2D = $explosionRadii
@onready var explodeDelay: Timer = $explodeDelay
@onready var attackDamageLabel: Label = $attackDamageLabel
@onready var animPl: AnimationPlayer = $AnimationPlayer
@onready var deathShader: MeshInstance2D = $deathShader
@onready var radarAltimeter: RayCast2D = $radarAltimeter
@onready var morseCodeInt: Node = $morseCodeInterpreter
@onready var morse: Label = $morse
@onready var morsePreview: Label = $morsePreview

@export var shaking: bool = false
@export var shakeScale: float = 0.0

var contra: bool = true # Linguistic contractions
var torpedoSpeed: float = 384.0
var attackDamageS: bool = true
var showMorse: bool = true
var deathShaderShowDur: float = Time.get_ticks_msec()
var deathShaderRan: bool = false
var commands: Array = ["move", "fire", "damage"]
var shortCommands: Array = ["m", "f", "d"]
var ammo: Array = ["torpedo", "laser", "railgun", "missile", "flamethrower", "m107"]
var xDrag: float = 0.01
var yDrag: float = 0.01
var HP: float = 100.0
var alive: bool = true
var attackDamage: float = 0.0
var amplitude: float = 1
var frequency: float = 15
var minBrightness: float = 0.85
var maxBrightness: float = 1.15
var index: int
var originalPosition: Vector2
var keybind: InputEvent
var interpreted: String
var command: String
var root

func _ready() -> void:
	morseCodeInt.player = self
	await get_tree().create_timer(0.1, false).timeout
	commandInput.show()

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("Escape"):
		commandInput.release_focus()
	if not showMorse:
		morse.hide()
		morsePreview.hide()
	morse.text = "".join(morseCodeInt.currentMorse)
	morsePreview.text = "".join(morseCodeInt.currentMorsePreview)
	xDrag = (0.2 + 0.8 * (1 - HP / 100.0)) * delta
	yDrag = (0.2 + 0.8 * (1 - HP / 100.0)) * delta
	if HP < 100.0:
		velocity.y += (20 * (1 - HP / 100.0)) * delta
	velocity.x = velocity.x * (1 - xDrag)
	velocity.y = velocity.y * (1 - yDrag)
	if not shaking:
		originalPosition = position
	if HP > 0:
		meshIn2D.set_self_modulate(Color(1+0.2-(HP/100),HP/100+0.2,0,1))
	var sineValue = amplitude*sin(frequency*Time.get_ticks_usec()/1000000.0)
	var brightness = lerp(minBrightness,maxBrightness,(sineValue+1)/2)
	gpup2D3.modulate = Color(brightness,brightness,brightness)
	if not root.debugging:
		if Input.is_action_just_pressed(str("P", index, "TextSubmit")):
			var event = InputEventKey.new()
			for ev in InputMap.action_get_events(str("P", index, "TextSubmit")):
				if ev is InputEventKey:
					event = ev
					break
			commandInterpret(commandInput, self, event)
	elif Input.is_action_just_pressed("Submit"):
		var event = InputEventKey.new()
		for ev in InputMap.action_get_events("Submit"):
			if ev is InputEventKey:
				event = ev
				break
		commandInterpret(commandInput, self, event)

	if HP <= 0 and alive == true:
		if root.players.find(self) != -1:
			InputMap.erase_action(str("P", root.players.find(self), "MorseInput"))
			root.players.remove_at(root.players.find(self))
		attackDamageLabel.hide()
		collision_layer = 1 << 19
		collision_mask = 1 << 17
		animPl.stop()
		animPl.play("death")
		commandInput.hide()
		root.positionCamera(position)
		meshIn2D.set_self_modulate(Color(0,0,0,0.75))
		alive = false
	if not is_on_floor():
		velocity += get_gravity() * delta

	var colInfo = move_and_collide(velocity * delta)
	if colInfo:
		var collider = colInfo.get_collider()
		if collider is CharacterBody2D:
			var transferVelo = velocity * 0.5 * (HP / 100)
			var remainingVelo = velocity * 0.5 * (HP / 100)

			collider.HP -= velocity.length() * 0.08 * (HP / 100)
			HP -= velocity.length() * 0.08 * (HP / 100)
			collider.velocity += transferVelo
			velocity = remainingVelo.bounce(colInfo.get_normal())
		elif velocity.length() > 20.0:
			velocity = velocity.bounce(colInfo.get_normal()) * 0.6 * (HP / 100)
			if colInfo.get_collider().name == "Border":
				root.borderHit(self)
		var velocityLen = velocity.length()
		var particleRatio = 1.0
		if velocityLen < 1600.0:
			particleRatio = (velocityLen / 1600.0) - 0.25
		var newgpup2D4 = gpup2D4.duplicate() as GPUParticles2D
		var newgpup2D5 = gpup2D5.duplicate() as GPUParticles2D
		var colPos = colInfo.get_position()
		newgpup2D4.global_position = colPos
		newgpup2D4.rotation = colInfo.get_normal().angle() - 90
		newgpup2D4.amount_ratio = particleRatio
		newgpup2D4.emitting = true
		newgpup2D5.global_position = colPos
		newgpup2D5.rotation = colInfo.get_normal().angle() + 90
		newgpup2D5.amount_ratio = particleRatio
		newgpup2D5.emitting = true
		get_tree().root.add_child(newgpup2D4)
		get_tree().root.add_child(newgpup2D5)

	if shaking:
		position = originalPosition + Vector2(
			randf_range(-shakeScale, shakeScale),
			randf_range(-shakeScale, shakeScale)
		)
	move_and_slide()

func commandInterpret(input, characterBody, event):
	var key = char(event.unicode)
	if str(input.text).ends_with(key) and key != "":
		input.text = str(input.text).erase(str(input.text).length()-1)
	var text = input.text.to_lower().strip_edges()
	var parts: Array = text.split(" ")
	for char in text.split(""):
		if char == "_":
			parts = text.split("_")
			break
	if parts.size() > 0:
		var command = parts[0]
		if command in commands or command in shortCommands:
			match command:
				"move":
					moveCommand(parts, characterBody)
				"fire":
					fireCommand(parts, characterBody)
				"damage":
					damageCommand(parts, characterBody)
			if contra:
				match command:
					"m":
						moveCommand(parts, characterBody)
					"f":
						fireCommand(parts, characterBody)
					"d":
						damageCommand(parts, characterBody)
			input.clear()
			return
	input.clear()
	interpreted = str("")

func moveCommand(parts: Array, characterBody: CharacterBody2D):
	if parts.size() == 3:
		var angleDegreesInput = 0
		var magnitudeInput = 0
		var angle = parts[1]
		var magnitude = parts[2]
		if angle.is_valid_float() and magnitude.is_valid_float():
			angleDegreesInput = angle.to_int()
			magnitudeInput = clampi(magnitude.to_int(), 0, 100)

			var angleRadians = deg_to_rad(angleDegreesInput)
			var x = magnitudeInput * cos(angleRadians)
			var y = magnitudeInput * sin(angleRadians)

			characterBody.velocity += Vector2(x*10, y*10)
			print(x * 10, " ", y * 10, " Velocity added")
		else:
			print("Invalid move command. Both angle and magnitude must be numeric values.")
	else:
		print("Invalid move command. Expected 2 values: angle and magnitude.")

func fireCommand(parts: Array, characterBody: CharacterBody2D):
	if parts.size() >= 3:
		var ammoType = parts[1].to_lower()
		var angle = parts[2]
		var fltAngle
		if parts.size() > 3:
			fltAngle = (parts[2] + "." + parts[3]).to_float()
		else:
			fltAngle = parts[2].to_float()

		var angleDegreesInput = fltAngle
		if ammoType.is_valid_float() and contra:
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
		if ammoType.to_lower() == "torpedo":
			var torpedo = torpedoScene.instantiate()
			torpedo.HEATDamage = root.mainMenu.torpedoHEATDamage
			torpedo.ExploDamage = root.mainMenu.torpedoExploDamage
			torpedo.HP = 5.0
			torpedo.armingDelay = root.mainMenu.torpedoArmingDelay
			var torpedoSpeed: float = root.mainMenu.torpedoSpeed
			torpedo.rotation_degrees = angleDegreesInput
			var direction = Vector2(cos(torpedo.rotation), sin(torpedo.rotation))
			var offset = direction * 100
			torpedo.velocity = direction * torpedoSpeed
			torpedo.position = characterBody.position + offset
			get_tree().root.add_child(torpedo)
			root.objects.append(torpedo)
			torpedo.player = self

		elif ammoType.to_lower() == "laser":
			var laser = laserScene.instantiate()
			laser.damage = root.mainMenu.laserDamage
			laser.laserDuration = root.mainMenu.laserDuration
			laser.damageRate = root.mainMenu.laserDamageRate
			var laserDamageRate: float = 0.5
			laser.rotation = deg_to_rad(angleDegreesInput)
			var direction = Vector2(cos(laser.rotation), sin(laser.rotation))
			var offset = direction * 100
			laser.position = characterBody.position + offset
			get_tree().root.add_child(laser)
			laser.player = self
			laser.reparent(self)
		elif ammoType.to_lower() == "railgun":
			var sabotT = sabotScene.instantiate()
			var sabotB = sabotScene.instantiate()
			var railgun = railgunScene.instantiate()
			railgun.rotation = deg_to_rad(angleDegreesInput)
			var direction = Vector2(cos(railgun.rotation), sin(railgun.rotation))
			var offset = direction * 100
			railgun.velocity = direction * 12228
			railgun.position = characterBody.position + offset

			var sabotOffsetT = Vector2(-3.84, 12.8).rotated(railgun.rotation)
			sabotT.position = railgun.position + sabotOffsetT
			sabotT.linear_velocity = railgun.velocity + Vector2(-2048, 1200).rotated(railgun.rotation)
			sabotT.rotation = railgun.rotation

			var sabotOffsetB = Vector2(-3.84, -12.8).rotated(railgun.rotation)
			sabotB.position = railgun.position + sabotOffsetB
			sabotB.linear_velocity = railgun.velocity + Vector2(-2048, -1200).rotated(railgun.rotation)
			sabotB.rotation = railgun.rotation

			get_tree().root.add_child(railgun)
			get_tree().root.add_child(sabotT)
			get_tree().root.add_child(sabotB)
			root.objects.append(railgun)
			root.objects.append(sabotT)
			root.objects.append(sabotB)
			railgun.player = self
		elif ammoType.to_lower() == "missile":
			var firestreak = firestreakScene.instantiate()
			firestreak.damage = root.mainMenu.firestreakDamage
			firestreak.HP = root.mainMenu.firestreakHP
			firestreak.turnRate = root.mainMenu.firestreakTurningRate
			firestreak.detectionRadiusMultiplier = root.mainMenu.firestreakDetectionRangeMultiplier
			firestreak.explosionRadiusMultiplier = root.mainMenu.firestreakExplosionRangeMultiplier
			firestreak.liftMultiplier = root.mainMenu.firestreakLiftMultiplier
			firestreak.thrustMultiplier = root.mainMenu.firestreakThrustMultiplier
			firestreak.rotation = deg_to_rad(angleDegreesInput)
			var direction = Vector2(cos(firestreak.rotation), sin(firestreak.rotation))
			var offset = direction * 150
			firestreak.position = characterBody.position + offset
			firestreak.player = self
			get_tree().root.add_child(firestreak)
			root.objects.append(firestreak)
		elif ammoType.to_lower() == "flamethrower":
			var flamethrower = flamethrowerScene.instantiate()
			flamethrower.rotation = deg_to_rad(angleDegreesInput)
			var direction = Vector2(cos(flamethrower.rotation), sin(flamethrower.rotation))
			var offset = direction * 100
			flamethrower.position = characterBody.position + offset
			get_tree().root.add_child(flamethrower)
			flamethrower.player = self
			flamethrower.reparent(self)
		elif ammoType.to_lower() == "m107":
			var M107 = M107Scene.instantiate()
			M107.rotation = deg_to_rad(angleDegreesInput)
			var spread = 0.02
			var direction = Vector2(cos(M107.rotation + randf_range(-spread, spread)), sin(M107.rotation + randf_range(-spread, spread)))
			var offset = direction * 125
			M107.position = characterBody.position + offset
			M107.velocity = direction * 2048
			M107.player = self
			get_tree().root.add_child(M107)
		print("Fired ", ammoType, " at angle ", angleDegreesInput)
	else:
		print("Needs 3 parts: command type, ammo type, and firing angle. Parts: ", parts.size())

func damageCommand(parts: Array, characterBody: CharacterBody2D):
	if root.debugging:
		if parts.size() >= 2:
			var damage = parts[1]
			if damage.is_valid_float():
				characterBody.HP -= damage.to_float()
				print("characterBody.HP: ",characterBody.HP)
			else:
				print("Damage value must be numeric")
		else:
			print("Incorrect part count; expected command type and numeric damage value.")
	else:
		print("The damage command is only available in debugging mode")

func postDeath() -> void:
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

func _on_queue_free_delay_timeout() -> void:
	queue_free()

func _explodeDelayEnd() -> void:
	var bodies = explosionRadii.get_overlapping_bodies()
	var rangeToTargets = []

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
					rangeToTargets.append({"body": body, "distance": distance})
				else:
					print("Target obstructed: ", body)
			else:
				newRaycast.queue_free()

	rangeToTargets.sort_custom(func(a, b):
		return a["distance"] < b["distance"]
	)

	var maxDamageBodies = min(2, rangeToTargets.size())
	for i in range(maxDamageBodies):
		var target = rangeToTargets[i]["body"]
		var distance = rangeToTargets[i]["distance"]
		var damage = 24000 / (distance + 1) * pow(distance / (distance + 12), 6)
		target.HP -= damage
		print("Damaged:", target, "Damage:", damage, "Remaining HP:", target.HP, "Method: Death")


func attackDamageF(damage, reset):
	if attackDamageS:
		if not reset:
			attackDamage += damage
		else:
			attackDamageLabel.text = str("Attack damage: ", int(attackDamage))
			print("Attack damage: ", attackDamage)
			attackDamage = 0.0

func deathShaderAnimS():
	get_viewport().use_hdr_2d = false
	deathShader.process_mode = Node.PROCESS_MODE_INHERIT
	deathShader.show()
	deathShaderRan = true
	get_tree().paused = true

func deathShaderAnimP():
	get_viewport().use_hdr_2d = true
	deathShader.hide()
	deathShader.process_mode = Node.PROCESS_MODE_DISABLED
	deathShaderRan = true
	get_tree().paused = false

func addChar(char: String):
	commandInput.text += char

func _onCommandInputTextChanged(new_text: String) -> void:
	var parts = new_text.split(" ")
	if contra:
		match str(new_text.split("")[0].to_lower()):
			"m":
				interpreted = str("Command: MOVE")
				if self == root.players[0]:
					root.fireCommand.hide()
					root.damageCommand.hide()
					root.moveCommand.text = interpreted
				else:
					root.fireCommand2.hide()
					root.damageCommand2.hide()
					root.moveCommand2.text = interpreted
			"f":
				if not contra:
					interpreted = str("Command: FIRE Weapon(string): ")
				else:
					interpreted = str("Command: FIRE Weapon(index/string): ")
				if self == root.players[0]:
					root.moveCommand.hide()
					root.damageCommand.hide()
					root.fireCommand.text = interpreted
				else:
					root.moveCommand2.hide()
					root.damageCommand2.hide()
					root.fire2Command.text = interpreted
				var ammoType
				if parts.size() > 1:
					ammoType = parts[1]
					if ammoType.is_valid_float() and contra:
						var ammoIndex = ammoType.to_int()
						if ammoIndex > 0 and ammoIndex <= ammo.size():
							ammoType = ammo[ammoIndex - 1]
					if str(ammoType).length() > 0:
						interpreted = str("Command: FIRE ","Weapon: ", str(ammoType).to_upper(), " Angle(float): ")
					if self == root.players[0]:
						root.fireCommand.text = interpreted
					else:
						root.fire2Command.text = interpreted
				var fltAngle
				if parts.size() > 3:
					fltAngle = (parts[2] + "." + parts[3]).to_float()
					interpreted = str("Command: FIRE ","Weapon: ", str(ammoType).to_upper(), " Angle: ", fltAngle)
				elif parts.size() > 2 and parts[2].length() > 0:
					fltAngle = parts[2].to_float()
					interpreted = str("Command: FIRE ","Weapon: ", str(ammoType).to_upper(), " Angle: ", fltAngle)
				if self == root.players[0]:
					root.fireCommand.text = interpreted
				else:
					root.fire2Command.text = interpreted
			"d":
				interpreted = str("Command: DAMAGE Damage: ")
				if self == root.players[0]:
					root.moveCommand.hide()
					root.fireCommand.hide()
					root.damageCommand.text = interpreted
				else:
					root.moveCommand2.hide()
					root.fireCommand2.hide()
					root.damageCommand2.text = interpreted
				if parts.size() > 1:
					interpreted = str("Command: DAMAGE Damage: ", str(parts[1]).to_float())
