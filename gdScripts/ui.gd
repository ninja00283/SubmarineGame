extends Node2D

@onready var previewP1: VBoxContainer = $previewP1
@onready var currentMorsePreviewP1: Label = $previewP1/currentMorsePreview
@onready var currentTextPreviewP1: Label = $previewP1/currentTextPreview
@onready var currentP1: VBoxContainer = $currentP1
@onready var currentMorseP1: Label = $currentP1/currentMorse
@onready var currentTextP1: Label = $currentP1/currentText
@onready var previewP2: VBoxContainer = $previewP2
@onready var currentMorsePreviewP2: Label = $previewP2/currentMorsePreview
@onready var currentTextPreviewP2: Label = $previewP2/currentTextPreview
@onready var currentP2: VBoxContainer = $currentP2
@onready var currentMorseP2: Label = $currentP2/currentMorse
@onready var currentTextP2: Label = $currentP2/currentText


func _process(delta: float) -> void:
	currentMorsePreviewP1.text = "".join(MorseCodeInterpreter.players.values()[0]["currentMorsePreview"])
	currentTextPreviewP1.text = "".join(MorseCodeInterpreter.players.values()[0]["currentTextPreview"])
	currentMorseP1.text = "".join(MorseCodeInterpreter.players.values()[0]["currentMorse"])
	currentTextP1.text = "".join(MorseCodeInterpreter.players.values()[0]["currentText"])
	currentMorsePreviewP2.text = "".join(MorseCodeInterpreter.players.values()[1]["currentMorsePreview"])
	currentTextPreviewP2.text = "".join(MorseCodeInterpreter.players.values()[1]["currentTextPreview"])
	currentMorseP2.text = "".join(MorseCodeInterpreter.players.values()[1]["currentMorse"])
	currentTextP2.text = "".join(MorseCodeInterpreter.players.values()[1]["currentText"])

func morseClear():
	MorseCodeInterpreter.players.values()[0]["currentMorsePreview"].clear()
	MorseCodeInterpreter.players.values()[0]["currentMorse"].clear()
	MorseCodeInterpreter.players.values()[0]["currentTextPreview"].clear()
	MorseCodeInterpreter.players.values()[0]["currentText"].clear()
	MorseCodeInterpreter.players.values()[1]["currentMorsePreview"].clear()
	MorseCodeInterpreter.players.values()[1]["currentMorse"].clear()
	MorseCodeInterpreter.players.values()[1]["currentTextPreview"].clear()
	MorseCodeInterpreter.players.values()[1]["currentText"].clear()
