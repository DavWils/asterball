## Script for the main menu UI

extends Control

@onready var main_scene: MainScene = get_tree().current_scene

func _ready() -> void:
	$MenuButtonsContainer/HostButton.pressed.connect(_on_host_button_pressed)
	$MenuButtonsContainer/QuickMatchButton.pressed.connect(_on_quick_match_button_pressed)
	$MenuButtonsContainer/OptionsButton.pressed.connect(_on_options_button_pressed)
	$MenuButtonsContainer/CreditsButton.pressed.connect(_on_credits_button_pressed)
	$MenuButtonsContainer/QuitButton.pressed.connect(_on_quit_button_pressed)


## Called when host button is pressed.
func _on_host_button_pressed():
	main_scene.host_game("starfield")

## Called when quick match button is pressed.
func _on_quick_match_button_pressed():
	main_scene.quick_find_game()

## Called when options button is pressed.
func _on_options_button_pressed():
	pass

## Called when credits button is pressed.
func _on_credits_button_pressed():
	pass

## Called when quit button is pressed.
func _on_quit_button_pressed():
	get_tree().quit()
