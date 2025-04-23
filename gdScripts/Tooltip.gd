extends TextureRect

@onready var label: Label = $TooltipDisplay
@onready var tooltipDelay: Timer = $Timer

var hovering: bool = false # Whether or not the player is hovering over an icon
var tooltipDelayS: float = 0.3 # The amount of time in seconds it takes for the tooltip to show
var tooltipOffset: Vector2 = Vector2(20, 20) # By how many pixels the tooltip should be offset from the mouse
@export var displayText: String

func _input(event: InputEvent) -> void:
	if visible:
		if abs((global_position + size / 2 - get_global_mouse_position()).length()) < 64:
			label.text = displayText
			hovering = true
		else:
			hovering = false
			tooltipDelay.stop()
			label.hide()
		if hovering:
			if tooltipDelay.is_stopped():
				tooltipDelay.start(tooltipDelayS)
	label.global_position = get_global_mouse_position() + tooltipOffset


func _onTooltipDelayTimeout() -> void:
	label.show()
