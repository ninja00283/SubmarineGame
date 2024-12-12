extends Node2D

@onready var commandInput: LineEdit = $commandInput
@onready var characterBody2D: CharacterBody2D = $CharacterBody2D
@onready var torpedoScene = preload("res://torpedo.tscn")

var commands = ["move", "fire"]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	commandInput.grab_focus()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Submit"):
		commandInterpret()

func commandInterpret():
	var text = commandInput.text.to_lower()
	var parts = text.split(" ")
	if parts.size() > 0:
		var command = parts[0]
		if command in commands:
			match command:
				"move":
					moveCommand(parts)
				"fire":
					fireCommand(parts)
			commandInput.clear()
			return
	print("Unknown command: ", text)
	commandInput.clear()

func moveCommand(parts: Array):
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
			
			characterBody2D.velocity += Vector2(x, y)
			print(x, " ", y, " Velocity added")
		else:
			print("Invalid move command. Both angle and magnitude must be numeric values.")
	else:
		print("Invalid move command. Expected 2 values: angle and magnitude.")

func fireCommand(parts: Array):
	print("fireCommand()")
	
	var torpedo = torpedoScene.instantiate()
	
	var angleDegreesInput = 0
	var magnitudeInput = 256
	var angle = parts[1]
	
	if angle.is_valid_float():
		angleDegreesInput = angle.to_int()
	
	torpedo.rotation = deg_to_rad(angleDegreesInput)
	
	var direction = Vector2(cos(torpedo.rotation), sin(torpedo.rotation))
	var velocity = direction * magnitudeInput
	
	torpedo.linear_velocity = velocity
	
	var offset = direction * 100
	torpedo.position = characterBody2D.position + offset
	
	get_tree().root.add_child(torpedo)
