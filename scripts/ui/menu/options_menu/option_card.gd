extends Control

## The name of this action.
var action_name: StringName

## The label displaying action's name.
@onready var name_label: Label = $MarginContainer/HBoxContainer/NameLabel

## The button displaying the key, pressing allows changing key.
@onready var key_button: Button = $MarginContainer/HBoxContainer/KeyButton

func _ready() -> void:
	key_button.action_name = action_name
	# Set the namelabel to the correct text.
	var input_name := action_name
	# Capitalize first letter.
	input_name = input_name.substr(0, 1).capitalize() + input_name.substr(1)
	# Replace underscore with space and capitalize subsequent letters.
	for i in range(0, input_name.length()):
		var current_char = input_name.substr(i, 1)
		if current_char == "_":
			var next_char = input_name.substr(i+1, 1)
			input_name = input_name.substr(0, i) + " " + next_char.capitalize() + input_name.substr(i+2)
	name_label.text = input_name
	var input_map := InputMap.action_get_events(action_name)[0]
	if input_map is InputEventKey:
		key_button.text = input_map.as_text_physical_keycode()
		key_button.original_string = input_map.as_text_physical_keycode()
	else:
		key_button.text = input_map.as_text()
		key_button.original_string = input_map.as_text()
	key_button.tooltip_text = name_label.text + ": " + key_button.text
