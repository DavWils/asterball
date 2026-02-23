## Movement component of the character, handling walking/charging.

extends Node

class_name MovementComponent

## Owning character.
@onready var character: Character = self.get_parent()
## Network manager.
@onready var network_manager: NetworkManager = get_tree().current_scene.network_manager


## 2D vector representing local movement input.
var movement_input: Vector2
## Boolean value representing charge input.
var charging_input: bool

## Base walk speed of the character. (m/s)
@export var base_walk_speed: float = 6.0
## The base acceleration rate for the character when charging.
@export var base_charge_accel_rate: float = 2.0
## The base deceleration rate for the character when they stop charging and skid.
@export var base_charge_decel_rate: float = 2.0
## The base maximum charging speed of the character.
@export var base_max_charge_speed: float = 24.0



func _physics_process(delta: float) -> void:
	if network_manager.is_host() or character.is_locally_possessed():
		print("Movement input for ", Steam.getFriendPersonaName(character.owning_player_id), " at delta ", delta)
		print("Move: ", movement_input)
		print("Charge: ", charging_input)
		# Set character movement values based on input.
		if character.is_on_floor():
			character.velocity = get_walk_speed() * ((character.global_transform.basis.z * movement_input.y)+(character.global_transform.basis.x * movement_input.x))
			character.velocity.y = 0

## Returns the character's walk speed.
func get_walk_speed() -> float:
	return base_walk_speed
