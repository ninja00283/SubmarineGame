extends Node2D

@onready var reloadScene: LineEdit = $Keybinds/VBoxContainer/reloadScene
@onready var spawnPlayerMMB: LineEdit = $Keybinds/VBoxContainer/spawnPlayerMMB
@onready var spawnPlayerY: LineEdit = $Keybinds/VBoxContainer/spawnPlayerY
@onready var submitText: LineEdit = $Keybinds/VBoxContainer/submitText
@onready var morseInput: LineEdit = $Keybinds/VBoxContainer/morseInput


@onready var lineEdits = [
	{"Node": reloadScene, "Keybind": "Reload"},
	{"Node": spawnPlayerMMB, "Keybind": "MMB"},
	{"Node": spawnPlayerY, "Keybind": "Spawn"},
	{"Node": submitText, "Keybind": "Submit"},
	{"Node": morseInput, "Keybind": "MorseInput"}
]

var listening = false
var key

func _input(event: InputEvent) -> void:
	if listening:
		if event.is_action_type() and event.is_pressed() and not event.is_echo():
			print(event)
			key = event.as_text()
			print(key)
			for lineEdit in lineEdits:
				if lineEdit["Node"].has_focus():
					lineEdit["Node"].release_focus()
					lineEdit["Node"].text = ""
					lineEdit["Node"].placeholder_text = key
					InputMap.action_erase_event(lineEdit["Keybind"], InputMap.action_get_events(lineEdit["Keybind"])[0])
					InputMap.action_add_event(lineEdit["Keybind"], event)
					listening = false
					break

func _ready() -> void:
	for lineEdit in lineEdits:
		var inputEvents = InputMap.action_get_events(lineEdit["Keybind"])
		if inputEvents.size() > 0:
			var keyText = inputEvents[0].as_text().split(" ")[0]
			lineEdit["Node"].placeholder_text = keyText
	for lineEdit in lineEdits:
		lineEdit["Node"].focus_entered.connect(Callable(_on_focus_entered).bind(lineEdit["Node"]))
	for lineEdit in lineEdits:
		lineEdit["Node"].focus_exited.connect(Callable(_on_focus_exited).bind(lineEdit["Node"]))

func _on_focus_entered(lineEdit):
	var prevKey = key
	lineEdit.text = "Press key..."
	listening = true
	if key != prevKey:
		print("changed")
		lineEdit.text = ""

func _on_focus_exited(lineEdit):
	lineEdit.text = ""
