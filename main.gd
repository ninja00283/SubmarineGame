extends Node2D

@onready var commandInputP1: LineEdit = $Control/commandInputP1
@onready var commandInputP2: LineEdit = $Control/commandInputP2
@onready var characterBody2DP1: CharacterBody2D = $CharacterBody2DP1
@onready var characterBody2DP2: CharacterBody2D = $CharacterBody2DP2
@onready var torpedoScene = preload("res://torpedo.tscn")

var commands = ["move", "fire"]
var ammo = ["torpedo"]

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Submit"):
		commandInterpret(commandInputP1, characterBody2DP1)
	if Input.is_action_just_pressed("Submit"):
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
	print("Unknown command: ", text)
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
		print("fireCommand()")
		
		var torpedo = torpedoScene.instantiate()
		
		var angleDegreesInput = 0
		var magnitudeInput = 256
		var ammo = parts[1]
		var angle = parts[2]
		
		if angle.is_valid_float():
			angleDegreesInput = angle.to_int()
		
		torpedo.rotation = deg_to_rad(angleDegreesInput)
		
		var direction = Vector2(cos(torpedo.rotation), sin(torpedo.rotation))
		var velocity = direction * magnitudeInput
		
		torpedo.linear_velocity = velocity
		
		var offset = direction * 100
		torpedo.position = characterBody.position + offset
	
		get_tree().root.add_child(torpedo)
	else:
		print("Needs 3 parts, parts: ", parts.size())
