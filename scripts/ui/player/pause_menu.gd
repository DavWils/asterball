## Script for player pause menu.

extends Control

@onready var player_ui: PlayerUI = self.get_parent()

@onready var main_scene: MainScene = get_tree().current_scene

func _ready() -> void:
	$VBoxContainer/ResumeButton.pressed.connect(_on_resume_button_pressed)
	$VBoxContainer/OptionsButton.pressed.connect(_on_options_button_pressed)
	$VBoxContainer/QuitButton.pressed.connect(_on_quit_button_pressed)

func _on_resume_button_pressed() -> void:
	player_ui.close_pause_menu()

func _on_options_button_pressed() -> void:
	pass

func _on_quit_button_pressed() -> void:
	main_scene.return_to_menu()
