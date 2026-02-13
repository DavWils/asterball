## Script for the main menu UI

extends Control

@onready var main_scene: MainScene = get_tree().current_scene

func _ready() -> void:
	$MenuButtonsContainer/HostButton.pressed.connect(_on_host_button_pressed)
	$MenuButtonsContainer/QuickMatchButton.pressed.connect(_on_quick_match_button_pressed)


## Called when host button is pressed.
func _on_host_button_pressed():
	main_scene.host_game()

## Called when quick match button is pressed.
func _on_quick_match_button_pressed():
	main_scene.quick_find_game()
