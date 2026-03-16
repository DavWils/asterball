## Script for player pause menu.

extends Control

@onready var player_ui: PlayerUI = self.get_parent()

@onready var main_scene: MainScene = get_tree().current_scene

func _ready() -> void:
	$TabContainer/PauseHome/VBoxContainer/ResumeButton.pressed.connect(_on_resume_button_pressed)
	$TabContainer/PauseHome/VBoxContainer/OptionsButton.pressed.connect(_on_options_button_pressed)
	$TabContainer/PauseHome/VBoxContainer/QuitButton.pressed.connect(_on_quit_button_pressed)

func _on_resume_button_pressed() -> void:
	player_ui.close_pause_menu()

func _on_options_button_pressed() -> void:
	$TabContainer.current_tab = 1

func _on_quit_button_pressed() -> void:
	main_scene.return_to_menu()

func return_to_pause_home() -> void:
	$TabContainer.current_tab = 0
