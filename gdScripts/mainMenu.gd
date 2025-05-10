extends Node2D

@onready var root = $".."
@onready var settings: Node2D = $Settings
@onready var misc: Node2D = $Misc
@onready var keybinds: Node2D = $Keybinds

var generateCliffs: bool = true
var torpedoHEATDamage: float = 80.0
var torpedoExploDamage: float = 60.0
var torpedoHP: float = 5.0
var torpedoSpeed: float = 384.0
var laserDamage: float = 0.5
var laserDuration: float = 2.0
var laserDamageRate: float = 0.5
var firestreakDamage: float = 80.0
var firestreakHP: float = 5.0
var firestreakTurningRate: float = 0.3
var firestreakDetectionRangeMultiplier: float = 1.0
var firestreakExplosionRangeMultiplier: float = 1.0
var firestreakLiftMultiplier: float = 0.8
var firestreakThrustMultiplier: float = 1.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await root.players.size() > 0
	for player in root.players:
		$Misc/Variables/GridContainer/ShowMorse.text = str("Show morse: ", player.showMorse)
		$Misc/Variables/GridContainer/attackDamageF.text = str("Show attack damage: ", player.attackDamageS)


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
		$Misc/Variables/GridContainer/attackDamageF.text = str("Show attack damage: ", player.attackDamageS)

func _onShowMorsePressed() -> void:
	for player in root.players:
		player.showMorse = !player.showMorse
		$Misc/Variables/GridContainer/ShowMorse.text = str("Show morse: ", player.showMorse)


func _onBackPressed() -> void:
	misc.hide()
	keybinds.hide()
	settings.show()


func _onGenerateCliffsPressed() -> void:
	generateCliffs = !generateCliffs
	$Misc/Variables/GridContainer/generateCliffs.text = str("Generate cliffs: ", generateCliffs)
	root.reset()
	WorldBuilder.reset()
