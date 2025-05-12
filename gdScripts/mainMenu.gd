extends Node2D

@onready var root = $".."
@onready var settings: Node2D = $Settings
@onready var misc: Node2D = $Misc
@onready var keybinds: Node2D = $Keybinds
@onready var weapons: Node2D = $Weapons
@onready var weaponVars: Node2D = $WeaponVariables
@onready var vTorpedo: HBoxContainer = $WeaponVariables/VTorpedo
@onready var vLaser: HBoxContainer = $WeaponVariables/VLaser
@onready var vMissile: HBoxContainer = $WeaponVariables/VMissile
@onready var wVarPanel: Panel = $WeaponVariables/Panel
@onready var wVars: Node2D = $WeaponVariables

var lineEdits: Array = []
var generateCliffs: bool = true
var showGuide: bool = true
var torpedoHEATDamage: float = 80.0
var torpedoExploDamage: float = 60.0
var torpedoHP: float = 5.0
var torpedoSpeed: float = 384.0
var torpedoArmingDelay: float = 0.65
var laserDamage: float = 0.5
var laserDuration: float = 2.0
var laserDamageRate: float = 0.01
var firestreakDamage: float = 80.0
var firestreakHP: float = 5.0
var firestreakTurningRate: float = 0.3
var firestreakDetectionRangeMultiplier: float = 1.0
var firestreakExplosionRangeMultiplier: float = 1.0
var firestreakLiftMultiplier: float = 0.8
var firestreakThrustMultiplier: float = 1.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	lineEdits.append_array($WeaponVariables/VTorpedo/LineEdits/VBoxContainer.get_children())
	lineEdits.append_array($WeaponVariables/VLaser/LineEdits/VBoxContainer.get_children())
	lineEdits.append_array($WeaponVariables/VMissile/LineEdits/VBoxContainer.get_children())
	await root.players.size() > 0
	for player in root.players:
		$Misc/Variables/GridContainer/ShowMorse.text = str("Show morse: ", player.showMorse)
		$Misc/Variables/GridContainer/attackDamageF.text = str("Show attack damage: ", player.attackDamageS)

func _input(event: InputEvent) -> void:
	if event.is_action("Submit") and not event.is_echo():
		for lineEdit in lineEdits:
			if lineEdit.text.to_float() != 0.0:
				match lineEdit.get_name():
					"TorpedoHEATDmg":
						torpedoHEATDamage = lineEdit.text.to_float()
						lineEdit.placeholder_text = lineEdit.text
						lineEdit.clear()
					"TorpedoExploDmg":
						torpedoExploDamage = lineEdit.text.to_float()
						lineEdit.placeholder_text = lineEdit.text
						lineEdit.clear()
					"TorpedoHP":
						torpedoHP = lineEdit.text.to_float()
						lineEdit.placeholder_text = lineEdit.text
						lineEdit.clear()
					"TorpedoSpeed":
						torpedoSpeed = lineEdit.text.to_float()
						lineEdit.placeholder_text = lineEdit.text
						lineEdit.clear()
					"TorpedoArmingDelay":
						torpedoArmingDelay = lineEdit.text.to_float()
						lineEdit.placeholder_text = lineEdit.text
						lineEdit.clear()
					"LaserDmg":
						laserDamage = lineEdit.text.to_float()
						lineEdit.placeholder_text = lineEdit.text
						lineEdit.clear()
					"LaserDur":
						laserDuration = lineEdit.text.to_float()
						lineEdit.placeholder_text = lineEdit.text
						lineEdit.clear()
					"LaserDmgRate":
						laserDamageRate = lineEdit.text.to_float()
						lineEdit.placeholder_text = lineEdit.text
						lineEdit.clear()
					"MisDmg":
						firestreakDamage = lineEdit.text.to_float()
						lineEdit.placeholder_text = lineEdit.text
						lineEdit.clear()
					"MisHP":
						firestreakHP = lineEdit.text.to_float()
						lineEdit.placeholder_text = lineEdit.text
						lineEdit.clear()
					"MisTurnRate":
						firestreakTurningRate = lineEdit.text.to_float()
						lineEdit.placeholder_text = lineEdit.text
						lineEdit.clear()
					"MisDetectRadius*":
						firestreakDetectionRangeMultiplier = lineEdit.text.to_float()
						lineEdit.placeholder_text = lineEdit.text
						lineEdit.clear()
					"MisExploRadius*":
						firestreakExplosionRangeMultiplier = lineEdit.text.to_float()
						lineEdit.placeholder_text = lineEdit.text
						lineEdit.clear()
					"MisLift*":
						firestreakLiftMultiplier = lineEdit.text.to_float()
						lineEdit.placeholder_text = lineEdit.text
						lineEdit.clear()
					"MisThrust*":
						firestreakThrustMultiplier = lineEdit.text.to_float()
						lineEdit.placeholder_text = lineEdit.text
						lineEdit.clear()


func _onSettingsButtonPressed() -> void:
	if not weaponVars.visible and not weapons.visible and not keybinds.visible and not misc.visible:
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
	weapons.hide()
	settings.show()

func _onBackPressedWeapon():
	$WeaponVariables/Back.hide()
	weapons.show()
	wVars.hide()
	vTorpedo.hide()
	vLaser.hide()
	vMissile.hide()

func _onGenerateCliffsPressed() -> void:
	generateCliffs = !generateCliffs
	$Misc/Variables/GridContainer/generateCliffs.text = str("Generate cliffs: ", generateCliffs)
	root.instance(false)

func _onWeaponsPressed() -> void:
	weapons.show()
	settings.hide()

func _onWTorpedoPressed() -> void:
	$WeaponVariables/Back.show()
	weapons.hide()
	wVars.show()
	vTorpedo.show()

func _onWLaserPressed() -> void:
	$WeaponVariables/Back.show()
	weapons.hide()
	wVars.show()
	vLaser.show()

func _onWMissilePressed() -> void:
	$WeaponVariables/Back.show()
	weapons.hide()
	wVars.show()
	vMissile.show()


func _onAllowContractionsPressed() -> void:
	for player in root.players:
		player.contra = !player.contra
		$Misc/Variables/GridContainer/allowContractions.text = str("Allow contractions: ", player.contra)


func _onShowGuidePressed() -> void:
	showGuide = !showGuide
	$Misc/Variables/GridContainer/showGuide.text = str("Show guide: ", showGuide)
