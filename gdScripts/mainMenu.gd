extends Node2D

@onready var root = $".."
@onready var settings: Node2D = $Settings
@onready var misc: Node2D = $Misc
@onready var keybinds: Node2D = $Keybinds

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _onSettingsButtonPressed() -> void:
	settings.visible = !settings.visible
	misc.hide()
	keybinds.hide()

func _onMiscPressed() -> void:
	misc.visible = !misc.visible
	settings.hide()
	keybinds.hide()

func _onKeybindsPressed() -> void:
	keybinds.visible = !keybinds.visible
	misc.hide()
	settings.hide()

func _onAttackDamageFPressed() -> void:
	for player in root.players:
		player.attackDamageS = !player.attackDamageS
		if player.attackDamageS:
			$Misc/Variables/GridContainer/attackDamageF.text = str("Show attack damage: True")
		else:
			$Misc/Variables/GridContainer/attackDamageF.text = str("Show attack damage: False")

func _onShowMorsePressed() -> void:
	for player in root.players:
		player.showMorse = !player.showMorse
		if player.showMorse:
			$Misc/Variables/GridContainer/ShowMorse.text = str("Show morse: True")
		else:
			$Misc/Variables/GridContainer/ShowMorse.text = str("Show morse: False")
