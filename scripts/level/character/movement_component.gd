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

## Whether or not character is charging.
var is_charging: bool = false
## Whether or not character is currently skidding.
var is_skidding: bool = false
## The peak velocity reached while moving. Reset on end charge. 
var peak_velocity: Vector3 = Vector3.ZERO

## Base walk speed of the character. (m/s)
@export var base_walk_speed: float = 6.0
## The base acceleration rate for the character when charging.
@export var base_charge_accel: float = 2.0
## The base deceleration rate for the character when they stop charging and skid.
@export var base_charge_decel: float = 22.5
## The base maximum charging speed of the character.
@export var base_max_charge_speed: float = 24.0



func _physics_process(delta: float) -> void:
	if network_manager.is_host() or character.is_locally_possessed():
		# Set character movement values based on input.
		if character.is_on_floor():
			if character.is_unlocked():
				# The character's movement input in global space.
				var global_movement_input: Vector3 = ((character.global_transform.basis.z * movement_input.y)+(character.global_transform.basis.x * movement_input.x))
				# Current velocity
				var current_velocity := character.velocity
				
				# First check if character is skidding, if so, decelerate
				if is_skidding:
					character.velocity = current_velocity.normalized() * max(current_velocity.length() - (delta*get_charge_deceleration()), 0.0)
					if current_velocity.length() <= get_walk_speed():
						is_skidding = false
				else: # Not skidding, basic movement.
					if is_charging:
						if charging_input and movement_input.y < 0:
							# Have player increase in velocity only forward
							var velocity_addition: float = -movement_input.y * delta * get_charge_acceleration()
							var new_velocity_length: float = min(current_velocity.length() + velocity_addition, get_max_charge_speed())
							
							var charging_velocity: Vector3 = -character.global_transform.basis.z * new_velocity_length
							character.velocity = charging_velocity
						else:
							# If character is moving too fast, start skidding.
							if current_velocity.length() > get_walk_speed()*2:
								is_skidding = true
							is_charging = false
					else:
						if charging_input:
							is_charging = true
						else:
							character.velocity = current_velocity.lerp(global_movement_input * get_walk_speed(), 0.4)
		else:
			character.velocity = character.velocity.lerp(Vector3(0,character.velocity.y,0), 0.4)


## Returns the character's walk speed.
func get_walk_speed() -> float:
	return base_walk_speed

## Returns the maximum charge speed character can attain.
func get_max_charge_speed() -> float:
	var max_speed := base_max_charge_speed - (base_max_charge_speed/2 if character.has_effect(load("res://resources/effects/ball_slow.tres")) else 0.0)
	return max(max_speed, get_walk_speed())

## Returns the acceleration to apply to the character when charging.
func get_charge_acceleration():
	var max_accel = base_charge_accel - (character.get_carry_mass() * 0.2)
	return max(max_accel, 0.2)

## Returns the deceleration to apply to the character when skidding after a charge.
func get_charge_deceleration():
	return base_charge_decel

## Converts this component's information to reg dict
func to_reg_dict() -> Dictionary:
	var data: Dictionary
	data["c"] = is_charging
	data["s"] = is_skidding
	
	return data

func from_reg_dict(data: Dictionary) -> void:
	is_charging = data["c"]
	is_skidding = data["s"]
