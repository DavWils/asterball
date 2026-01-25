extends CharacterBody3D

class_name Character

@onready var network_manager: NetworkManager = get_tree().current_scene.get_node("NetworkManager")
@onready var player_controller: PlayerController = get_tree().current_scene.get_node("Level").get_node("PlayerController")
@onready var level: Level = get_tree().current_scene.get_node("Level")

## The non charging speed of this character. (m/s)
@export var walk_speed := 1
## The maximum base charging speed of the character, not including any buffs.
@export var base_charge_speed := 24.0
## Whether or not this character can rotate on the x axis as opposed to being applied to control rotation.
@export var use_pitch_rotation: bool = false

const gravity_acceleration := 9.8

## The id of the player currently controlling this character. Or -1 if it's AI controlled.
var owning_player_id := -1
## The id of this character in level registry.
var registry_id: int
## The current control rotation of the character.
var control_pitch := 0.0

func _ready() -> void:
	print("Spawning character owned by ", owning_player_id)
	pass

## Sets whether or not the camera is currently being used.
func set_current_camera(current: bool) -> void:
	$CameraHandle/PlayerCamera.current = current

## Returns true if this character is locally controlled.
func is_locally_possessed() -> bool:
	return player_controller.current_character == self

func _exit_tree() -> void:
	if is_locally_possessed(): player_controller.unpossess_character()
	level.level_registry.erase(registry_id)

func _physics_process(delta: float):
	# Gravity affects downward velocity.
	if not is_on_floor():
		velocity.y -= level.gravity_acceleration*delta
	else:
		velocity.y = 0

# Makes the character move based on player input.
func use_player_input(input: Dictionary, _delta: float) -> void:
	# Movement input.
	var move_input: Vector2 = input.get("mv", Vector2.ZERO)
	var direction := Vector3.ZERO

	if not move_input.is_zero_approx():
		direction = (
			transform.basis.x * move_input.x +
			transform.basis.z * move_input.y
		).normalized()

	velocity.x = direction.x * walk_speed
	velocity.z = direction.z * walk_speed

	# --- Move with collisions ---
	move_and_slide()
		
	# Look input.
	var look_input: Vector2 = input.get("lk", Vector2.ZERO)
		
	if not look_input.is_zero_approx():
		# Yaw (left/right)
		self.rotation.y -= look_input.x * 0.002
		
		# Pitch (up/down)
		if use_pitch_rotation:
			self.rotation.x = clamp(
				self.rotation.x - look_input.y * 0.002,
				-deg_to_rad(89.0),
				deg_to_rad(89.0)
			)
		else:
			control_pitch = clamp(
				control_pitch - look_input.y * 0.002,
				-deg_to_rad(89.0),
				deg_to_rad(89.0)
			)
