extends Node

class_name PlayerController

## Reference to the game's network manager.
@onready var network_manager: NetworkManager = get_tree().current_scene.get_node("NetworkManager")

## The currently controlled character.
var current_character: Character

## Possesses the given character.
func possess_character(character: Character) -> void:
	if current_character:
		unpossess_character()
	current_character = character
	current_character.set_current_camera(true)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

## Unpossesses the currently controlled character.
func unpossess_character() -> void:
	current_character.set_current_camera(false)
	current_character = null
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
