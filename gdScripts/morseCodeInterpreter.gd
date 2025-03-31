extends Node

var lengthSMultiplier: float = 0.2
var dotLengthS: int = 1
var dashLengthS: int = 3
var characterLengthS: int = 3
var spaceLengthS: int = 10
var morseInputLength: float
var morseInputPressed: bool = false
var timeSinceMorse: float = 0.0
var timeSinceLastMorse: float = 0.0
var currentMorse: Array = []
var currentText: Array = []
var currentMorsePreview: Array = []
var currentTextPreview: Array = []
var morsePreviewAppended: bool = false
var textPreviewAppended: bool = false
var clearOnFullMorse: bool = true
var playerVars: Dictionary = {
	"lengthSMultiplier": 0.2,
	"dotLengthS": 1,
	"dashLengthS": 3,
	"characterLengthS": 3,
	"spaceLengthS": 10,
	"morseInputLength": 0.0,
	"morseInputPressed": false,
	"timeSinceMorse": 0.0,
	"timeSinceLastMorse": 0.0,
	"currentMorse": [],
	"currentText": [],
	"currentMorsePreview": [],
	"currentTextPreview": [],
	"morsePreviewAppended": false,
	"textPreviewAppended": false,
	"clearOnFullMorse": true,
}
var players: Dictionary = {}
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

func _unhandled_key_input(event: InputEvent) -> void:
	for i in range(clampi(players.size(), 0, 2)):
		if not InputMap.action_get_events(str("MorseInputP", i+1)).is_empty():
			if event.as_text() == InputMap.action_get_events(str("MorseInputP", i+1))[0].as_text().split(" ")[0]:
				if not event.is_echo():
					if event.is_pressed():
						players.values()[i]["morseInputPressed"] = true
						players.values()[i]["currentMorsePreview"].append(".")
						players.values()[i]["morsePreviewAppended"] = false
					else:
						players.values()[i]["morseInputPressed"] = false

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	for i in range(players.size()):
		if players.values()[i]["clearOnFullMorse"]:
			if players.values()[i]["currentMorse"].size() > 5:
				players.values()[i]["currentMorse"].clear()
				players.values()[i]["currentMorsePreview"].clear()
	for i in range(players.size()):
		if players.values()[i]["morseInputPressed"]:
			players.values()[i]["timeSinceMorse"] += delta
			players.values()[i]["timeSinceLastMorse"] = 0.0
		if players.values()[i]["currentMorse"].size() > 5:
			players.values()[i]["currentMorse"].resize(5)
		if players.values()[i]["currentMorsePreview"].size() > 5:
			players.values()[i]["currentMorsePreview"].resize(5)
		for char in morseCharacters.keys():
			var morseIsKey: bool = false
			if morseCharacters[char] == players.values()[i]["currentMorse"]:
				morseIsKey = true
			if morseIsKey:
				if players.values()[i]["timeSinceLastMorse"] > characterLengthS * players.values()[i]["lengthSMultiplier"] and not players.values()[i]["morseInputPressed"]:
					players.values()[i]["currentText"].append(char)
					print(players.values()[i]["currentText"])
					players.values()[i]["currentMorse"].clear()
					players.values()[i]["currentMorsePreview"].clear()
				if not players.values()[i]["textPreviewAppended"]:
					players.values()[i]["currentTextPreview"].append(char)
					players.values()[i]["textPreviewAppended"] = true
				break
		if players.values()[i]["timeSinceMorse"] > dashLengthS * players.values()[i]["lengthSMultiplier"]:
			if not players.values()[i]["morseInputPressed"]:
				players.values()[i]["textPreviewAppended"] = false
				if players.values()[i]["currentMorse"].size() > 0 and players.values()[i]["currentTextPreview"][players.values()[i]["currentTextPreview"].size() - 1] != " ":
					players.values()[i]["currentTextPreview"].resize(players.values()[i]["currentTextPreview"].size() - 1)
				players.values()[i]["currentMorse"].append("-")
				players.values()[i]["currentMorsePreview"].resize(players.values()[i]["currentMorsePreview"].size() - 1)
				players.values()[i]["currentMorsePreview"].append("-")
				print(players.values()[i]["currentMorse"])
			if not players.values()[i]["morsePreviewAppended"]:
				players.values()[i]["currentMorsePreview"].resize(players.values()[i]["currentMorsePreview"].size() - 1)
				players.values()[i]["currentMorsePreview"].append("-")
				players.values()[i]["morsePreviewAppended"] = true
		elif players.values()[i]["timeSinceMorse"] > 0.0:
			if not players.values()[i]["morseInputPressed"]:
				players.values()[i]["textPreviewAppended"] = false
				if players.values()[i]["currentMorse"].size() > 0 and players.values()[i]["currentTextPreview"].size() > 0:
					if players.values()[i]["currentTextPreview"][players.values()[i]["currentTextPreview"].size() - 1] != " ":
						players.values()[i]["currentTextPreview"].resize(players.values()[i]["currentTextPreview"].size() - 1)
				players.values()[i]["currentMorse"].append(".")
				print(players.values()[i]["currentMorse"])
		if players.values()[i]["timeSinceLastMorse"] > spaceLengthS * players.values()[i]["lengthSMultiplier"] and players.values()[i]["currentText"].size() > 0:
			if not players.values()[i]["currentText"][players.values()[i]["currentText"].size() - 1] == " ":
				players.values()[i]["currentText"].append(" ")
				players.values()[i]["currentTextPreview"].append(" ")
		if not players.values()[i]["morseInputPressed"]:
			players.values()[i]["timeSinceLastMorse"] += delta
			players.values()[i]["timeSinceMorse"] = 0.0

func addPlayer(player: CharacterBody2D, playerIndex: int):
	var newVars = playerVars.duplicate(true)
	newVars["keybind"] = "MorseInputP" + str(playerIndex)
	players[player] = newVars
