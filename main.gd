extends Node2D

@onready var commandInputP1: LineEdit = $Control/commandInputP1
@onready var commandInputP2: LineEdit = $Control/commandInputP2
@onready var characterBody2DP1: CharacterBody2D = $CharacterBody2DP1
@onready var characterBody2DP2: CharacterBody2D = $CharacterBody2DP2
@onready var torpedoScene = preload("res://weaponTorpedo.tscn")
@onready var laserScene = preload("res://weaponLaser.tscn")

var commands = ["move", "fire"]
var ammo = ["torpedo", "laser"]

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_instance_valid(characterBody2DP1) and Input.is_action_just_pressed("Submit"):
		commandInterpret(commandInputP1, characterBody2DP1)
	if is_instance_valid(characterBody2DP2) and Input.is_action_just_pressed("Submit"):
		commandInterpret(commandInputP2, characterBody2DP2)

func commandInterpret(input: LineEdit, characterBody: CharacterBody2D):
	var text = input.text.to_lower()
	var parts = text.split(" ")
	if parts.size() > 0:
		var command = parts[0]
		if command in commands:
			match command:
				"move":
					moveCommand(parts, characterBody)
				"fire":
					fireCommand(parts, characterBody)
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
			var x = magnitudeInput * cos(angleRadians)
			var y = magnitudeInput * sin(angleRadians)
			
			characterBody.velocity += Vector2(x, y)
			print(x, " ", y, " Velocity added")
		else:
			print("Invalid move command. Both angle and magnitude must be numeric values.")
	else:
		print("Invalid move command. Expected 2 values: angle and magnitude.")

func fireCommand(parts: Array, characterBody: CharacterBody2D):
	if parts.size() >= 3:
		var ammoType = parts[1].to_lower()  # Get the ammo type from the command
		var angle = parts[2]
		
		if angle.is_valid_float():
			var angleDegreesInput = angle.to_int()
			var magnitudeInput = 256  # Fixed magnitude for now (you can adjust it as needed)
			
			# Check if ammoType is a valid index or a weapon name
			if ammoType.is_valid_float():
				var ammoIndex = ammoType.to_int()
				if ammoIndex > 0 and ammoIndex <= ammo.size():
					ammoType = ammo[ammoIndex - 1]
				else:
					print("Invalid ammo index. Must be within the range of available weapons.")
					return
			elif ammo.has(ammoType):
				# If ammoType is a valid weapon name
				pass
			else:
				print("Invalid ammo type. Must be either a valid index or a weapon name.")
				return

			# Instantiate the selected weapon
			if ammoType == "torpedo":
				var torpedo = torpedoScene.instantiate()
				torpedo.rotation = deg_to_rad(angleDegreesInput)

				var direction = Vector2(cos(torpedo.rotation), sin(torpedo.rotation))
				var velocity = direction * magnitudeInput

				torpedo.linear_velocity = velocity

				var offset = direction * 100
				torpedo.position = characterBody.position + offset

				get_tree().root.add_child(torpedo)
			elif ammoType == "laser":
				var laser = laserScene.instantiate()
				laser.rotation = deg_to_rad(angleDegreesInput)

				var direction = Vector2(cos(laser.rotation), sin(laser.rotation))
				var velocity = direction * magnitudeInput

				var offset = direction * 100
				laser.position = characterBody.position + offset

				get_tree().root.add_child(laser)

			print("Fired ", ammoType, " at angle ", angleDegreesInput)
		else:
			print("Invalid inputs for fire command. Angle must be numeric.")
	else:
		print("Needs 3 parts: command type, ammo type, and firing angle. Parts: ", parts.size())
