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

func _physics_process(delta: float) -> void:
	# Get input and either use it or send it to host.
	if current_character:
		# Create input dictionary
		var input_dictionary: Dictionary
		input_dictionary["mv"] = Input.get_vector("move_left", "move_right", "move_forward", "move_backward") # Movement input.
		input_dictionary["lk"] = look_input # Looking input.
		input_dictionary["ch"] = Input.is_action_pressed("charge") # Charging input.
		look_input = Vector2.ZERO
		
		# Use input.
		current_character.use_player_input(input_dictionary, delta)
		# If we're not the host, send the host our input as well.
		if not network_manager.is_host():
			network_manager.send_p2p_packet(
				network_manager.get_host_id(),
				{
					"m": network_manager.MSG_CLIENT_CHAR_INPUT, # Message. Player input.
					"id": current_character.registry_id, # Character id
					"d": delta,
					"in": input_dictionary # Input
				}
			)
