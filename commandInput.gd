extends Node2D

@onready var commandInput: LineEdit = $CharacterBody2D/commandInput
@onready var characterBody2D: CharacterBody2D = $CharacterBody2D

var angleDegreesInput = 0
var magnitudeInput = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Submit"):
		if commandInput.text.to_lower().begins_with("move"):
			submitCommand()
		else:
			submit()

func submit():
	print(commandInput.text)
	commandInput.clear()

func submitCommand():
	var input_text = commandInput.text.strip_edges().to_lower()
	if input_text.begins_with("move"):
		var parts = input_text.split(" ")
		if parts.size() == 3:
			var angle = parts[1]
			var magnitude = parts[2]
			angleDegreesInput = angle.to_int()
			magnitudeInput = magnitude.to_int()

			if angle.is_valid_float() and magnitude.is_valid_float():
				print("Recognized command: move with values angle(degrees) =", angle, ", magnitude =", magnitude)
				
				var angleRadians = deg_to_rad(angleDegreesInput)
				var x = magnitudeInput * cos(angleRadians)
				var y = magnitudeInput * sin(angleRadians)

				characterBody2D.velocity = Vector2(x, y)
				print("Calculated x: ", x, " y: ", y)
			else:
				print("Invalid move command. Both angle and magnitude must be numeric values.")
		else:
			print("Invalid move command. Expected 2 values: angle and magnitude.")
	else:
		print("Unknown command:", input_text)
	commandInput.clear()
