extends Node

class_name Character

@onready var network_manager: NetworkManager = get_tree().current_scene.get_node("NetworkManager")
@onready var player_controller: PlayerController = get_tree().current_scene.get_node("Level").get_node("PlayerController")

## The non charging speed of this character. (m/s)
@export var walk_speed := 6.0
## The maximum base charging speed of the character, not including any buffs.
@export var base_charge_speed := 24.0
## Whether or not this character can rotate on the x axis as opposed to being applied to control rotation.
@export var use_pitch_rotation: bool = false

## The id of the player currently controlling this character. Or -1 if it's AI controlled.
var owning_player_id := -1
## The id of this character in level registry.
var registry_id: int
## The current control rotation of the character.
var control_pitch := 0.0

func _ready() -> void:
	pass

## Sets whether or not the camera is currently being used.
func set_current_camera(current: bool) -> void:
	$CameraHandle/PlayerCamera.current = current

## Returns true if this character is locally controlled.
func is_locally_possessed() -> bool:
	return player_controller.current_character == self

func _exit_tree() -> void:
	if is_locally_possessed(): player_controller.unpossess_character()

# Makes the character move based on player input.
func use_player_input(input: Dictionary):
	print(registry_id, ": ", input)
	# Start with movement offset.
	var move_input: Vector2 = input["mv"]
	if not move_input.is_zero_approx():
		var world_offset: Vector3 = Vector3.ZERO + (self.transform.basis.x*move_input.x) + (self.transform.basis.z*move_input.y)
		print("world offset: ", world_offset)
		self.global_position += world_offset*1

	# Now look input
	var look_input: Vector2 = input["lk"]
	self.rotation.y -= look_input.x * .002
	if use_pitch_rotation:
		self.rotation.x -= look_input.y * .002
	else: 
		control_pitch -= look_input.y * .002
