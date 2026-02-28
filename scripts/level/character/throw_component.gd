## Throw component controlling aiming and throwing.

extends Node

class_name ThrowComponent



## Owning character.
@onready var character: Character = self.get_parent()
## Network manager.
@onready var network_manager: NetworkManager = get_tree().current_scene.network_manager

## The base maximum throw force the character can throw items with.
@export var base_max_throw_force: float = 100.0
## The amount of throw force to be accumulated in a second.
@export var base_throw_speed: float = 35.0

## Whether or not character is currently aiming.
var is_aiming := false
## Whether or not the character is currently charging a throw.
var is_throwing := false
## The current amount of force charged to throw.
var throw_force := 0.0

## The max percentage of throw force that is too small to actually throw.
const MINIMUM_THROW_FORCE := 0.05

func _physics_process(delta: float) -> void:
	# If throwing, accumulate force.
	if is_throwing:
		print("T: ", throw_force)
		throw_force = clampf(throw_force + (get_throw_speed() * delta), 0, get_max_throw_force())


## Starts aiming with the given item.
func start_aim() -> void:
	if not character.is_unlocked(): return
	if character.current_equipment:
		print("Starting aim.")
		is_aiming = true
		if network_manager.is_host():
			network_manager.send_p2p_packet(0, {"m": network_manager.Message.CHARACTER_AIM_START, "char_id": character.registry_id})

## Ends aiming.
func end_aim() -> void:
	if is_aiming:
		print("Stopping aim.")
		is_aiming = false
		if is_throwing:
			throw_force = 0.0
		if network_manager.is_host():
			stop_throwing()
			network_manager.send_p2p_packet(0, {"m": network_manager.Message.CHARACTER_AIM_END, "char_id": character.registry_id})

func start_throwing() -> void:
	if not is_throwing and is_aiming:
		print("Charging throw.")
		throw_force = 0.0
		is_throwing = true
		if network_manager.is_host():
			network_manager.send_p2p_packet(0, {"m": network_manager.Message.CHARACTER_THROW_START, "char_id": character.registry_id})

func stop_throwing() -> void:
	if is_throwing:
		is_throwing = false
		end_aim()
		
		if network_manager.is_host():
			network_manager.send_p2p_packet(0, {"m": network_manager.Message.CHARACTER_THROW_END, "char_id": character.registry_id})
			
			# If enough throw force, throw the item.
			if throw_force > get_max_throw_force() * MINIMUM_THROW_FORCE:
				print("Throwing with ", throw_force, " force.")
				
				var throw_velocity = character.get_throw_velocity()
				var projectile: Projectile = character.drop_equipped_item()
				projectile.linear_velocity = throw_velocity
			else:
				print("Not throwing.")

func get_max_throw_force() -> float:
	return base_max_throw_force

func get_throw_speed() -> float:
	return base_throw_speed

func from_reg_dict(data: Dictionary) -> void:
	throw_force = data["tf"]

func to_reg_dict() -> Dictionary:
	var data: Dictionary
	data["tf"] = throw_force
	
	return data
