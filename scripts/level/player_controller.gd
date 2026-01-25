extends Node

class_name PlayerController

## Reference to the game's network manager.
@onready var network_manager: NetworkManager = get_tree().current_scene.get_node("NetworkManager")

## The currently controlled character.
var current_character: Character

## The current look delta that is saved until a movement input is calculated.
var look_input := Vector2.ZERO

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

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and current_character:
		look_input += event.relative

func _physics_process(_delta: float) -> void:
	# Get input and either use it or send it to host.
	if current_character:
		# Create input dictionary
		var input_dictionary: Dictionary
		input_dictionary["mv"] = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
		input_dictionary["lk"] = look_input
		look_input = Vector2.ZERO
		
		# If host, use input. Else, send it to host.
		if network_manager.is_host():
			current_character.use_player_input(input_dictionary)
		else:
			network_manager.send_p2p_packet(
				network_manager.host_id,
				{
					"m": network_manager.MSG_CHAR_INPUT, # Message. Player input.
					"id": current_character.registry_id,
					"in": input_dictionary
				}
			)
