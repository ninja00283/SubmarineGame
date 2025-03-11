extends Node

var lengthSMultiplier: float = 0.2 # By how much morse characters should be multiplied in time required to parse
var dotLengthS: int = 1 # Length in units (seconds * multiplier) the button needs to pressed for a dot(.) to parse
var dashLengthS: int = 3 # Length in units (seconds * multiplier) the button needs to pressed for a dash(-) to parse
var characterLengthS: int = 3 # Length in units (seconds * multiplier) the button should not be held for the correct morse code to translate
var spaceLengthS: int = 10 # Length in units (seconds * multiplier) the button should not be held down for a space( ) to parse
var morseInputLength: float # Amount of time the assinged key has been held down
var morseInputPressed: bool = false # Bool to track if the keybind used for entering morse code is held down
var timeSinceMorse: float = 0.0 # Floating point that stores how long morse code keybind has been held
var timeSinceLastMorse: float = 0.0 # Floating point that stores how long it has been since morse was last released
var currentMorse: Array = [] # Array that stores what morse is currently entered, cleared after 7 units
var currentText: Array = [] # Array that stores all translated characters, cleared when submit is pressed
var currentMorsePreview: Array = [] # Array that stores what morse is currently entered and what morse will be added if the user lets go
var currentTextPreview: Array = [] # Array that stores all translated characters and what character will be added if the user waited 7 units
var morsePreviewAppended: bool = false # Bool to track if an element has already been added to any morse preview array, this is to avoid appending excess elements
var textPreviewAppended: bool = false # Bool to track if an element has already been added to any text preview array, this is to avoid appending excess elements
var players: Dictionary = {}
# Below is a dictionary that stores all characters and their associated morse code
var morseCharacters: Dictionary = {
	"A": [".", "-"],
	"B": ["-", ".", ".", "."],
	"C": ["-", ".", "-", "."],
	"D": ["-", ".", "."],
	"E": ["."],
	"F": [".", ".", "-", "."],
	"G": ["-", "-", "."],
	"H": [".", ".", ".", "."],
	"I": [".", "."],
	"J": [".", "-", "-", "-"],
	"K": ["-", ".", "-"],
	"L": [".", "-", ".", "."],
	"M": ["-", "-"],
	"N": ["-", "."],
	"O": ["-", "-", "-"],
	"P": [".", "-", "-", "."],
	"Q": ["-", "-", ".", "-"],
	"R": [".", "-", "."],
	"S": [".", ".", "."],
	"T": ["-"],
	"U": [".", ".", "-"],
	"V": [".", ".", ".", "-"],
	"W": [".", "-", "-"],
	"X": ["-", ".", ".", "-"],
	"Y": ["-", ".", "-", "-"],
	"Z": ["-", "-", ".", "."],
	"1": [".", "-", "-", "-", "-"],
	"2": [".", ".", "-", "-", "-"],
	"3": [".", ".", ".", "-", "-"],
	"4": [".", ".", ".", ".", "-"],
	"5": [".", ".", ".", ".", "."],
	"6": ["-", ".", ".", ".", "."],
	"7": ["-", "-", ".", ".", "."],
	"8": ["-", "-", "-", ".", "."],
	"9": ["-", "-", "-", "-", "."],
	"0": ["-", "-", "-", "-", "-"],
}
# _unhandled_key_input() is above _process() because morseInputPressed needs to be updated before _process() is ran
func _unhandled_key_input(event: InputEvent) -> void:
	if event.as_text() == InputMap.action_get_events("MorseInput")[0].as_text().split(" ")[0]:
		if not event.is_echo():
			if event.is_pressed():
				morseInputPressed = true
				currentMorsePreview.append(".")
				morsePreviewAppended = false
			else:
				morseInputPressed = false

func _ready() -> void:
	pass
	
func _process(delta: float) -> void:
	if morseInputPressed:
		timeSinceMorse += delta
		timeSinceLastMorse = 0.0
	if currentMorse.size() > 5:
		currentMorse.resize(5)
	if currentMorsePreview.size() > 5:
		currentMorsePreview.resize(5)
	for char in morseCharacters.keys():
		var morseIsKey: bool = false # Bool to track if the current iteration is the translated character
		if morseCharacters[char] == currentMorse:
			morseIsKey = true
		if morseIsKey:
			if timeSinceLastMorse > characterLengthS * lengthSMultiplier and not morseInputPressed:
				currentText.append(char)
				print(currentText)
				currentMorse.clear()
				currentMorsePreview.clear()
			if not textPreviewAppended:
				currentTextPreview.append(char)
				textPreviewAppended = true
			break
	if timeSinceMorse > dashLengthS * lengthSMultiplier:
		if not morseInputPressed:
			textPreviewAppended = false
			if currentMorse.size() > 0 and currentTextPreview[currentTextPreview.size() - 1] != " ":
				currentTextPreview.resize(currentTextPreview.size() - 1)
			currentMorse.append("-")
			currentMorsePreview.resize(currentMorsePreview.size() - 1)
			currentMorsePreview.append("-")
			print(currentMorse)
		if not morsePreviewAppended:
			currentMorsePreview.resize(currentMorsePreview.size() - 1)
			currentMorsePreview.append("-")
			morsePreviewAppended = true
	elif timeSinceMorse > 0.0:
		if not morseInputPressed:
			textPreviewAppended = false
			if currentMorse.size() > 0 and currentTextPreview.size() > 0:
				if currentTextPreview[currentTextPreview.size() - 1] != " ":
					currentTextPreview.resize(currentTextPreview.size() - 1)
			currentMorse.append(".")
			print(currentMorse)
	if timeSinceLastMorse > spaceLengthS * lengthSMultiplier and currentText.size() > 0:
		if not currentText[currentText.size() - 1] == " ":
			currentText.append(" ")
			currentTextPreview.append(" ")
			print(currentText)
			print("curtextpre ", currentTextPreview)
	if not morseInputPressed:
		timeSinceLastMorse += delta
		timeSinceMorse = 0.0
