extends Node2D

@onready var preview: VBoxContainer = $preview
@onready var currentMorsePreview: Label = $preview/currentMorsePreview
@onready var currentTextPreview: Label = $preview/currentTextPreview
@onready var current: VBoxContainer = $current
@onready var currentMorse: Label = $current/currentMorse
@onready var currentText: Label = $current/currentText

func _process(delta: float) -> void:
	currentMorsePreview.text = "".join(MorseCodeInterpreter.currentMorsePreview)
	currentTextPreview.text = "".join(MorseCodeInterpreter.currentTextPreview)
	currentMorse.text = "".join(MorseCodeInterpreter.currentMorse)
	currentText.text = "".join(MorseCodeInterpreter.currentText)
