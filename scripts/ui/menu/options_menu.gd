extends Control

@export var player_ui: PlayerUI
@export var main_menu_ui: MainMenuUI

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$VBoxContainer/ApplyButton.pressed.connect(_on_apply_pressed)
	$VBoxContainer/ReturnButton.pressed.connect(_on_return_pressed)

func _on_apply_pressed() -> void:
	pass

func _on_return_pressed() -> void:
	if player_ui:
		player_ui.pause_menu.return_to_pause_home()
	elif main_menu_ui:
		main_menu_ui.to_title_screen()
