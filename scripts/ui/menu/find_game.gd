## Script for the credits screen in main menu

extends Control

@onready var main_menu: Control = get_parent().get_parent()
@onready var main_scene: MainScene = get_tree().current_scene

## The box in which session cards will be added.
@export var session_box: VBoxContainer
## The session card control.
@onready var session_card_res := load("res://scenes/ui/main_menu/find_game_menu/session_card.tscn")

func load_sessions() -> void:
	for child in session_box.get_children():
		child.queue_free()
	
	Steam.requestLobbyList()
	await Steam.lobby_match_list
	show_filtered_session()

func show_filtered_session(filter: Dictionary = {}) -> void:
	for lobby in main_scene.found_lobbies:
		var new_card: Control = session_card_res.instantiate()
		new_card.session_id = lobby
		session_box.add_child(new_card)
