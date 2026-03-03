## Script for character ragdolls.

extends Node3D

class_name Ragdoll

## Character owning this ragdoll.
var character: Character

@onready var simulator = $Armature/Skeleton3D/PhysicalBoneSimulator3D

## The amount of times registry dictionary must be made before it actually sends something, necessary so no lag.
const REG_TICK_QUOTA: int = 10
## Tick count for registry.
var reg_tick_count: int = 0

func _init():
	position = Vector3(0,-1000,0)

func _ready():
	print("Ragdoll spawned for ", Steam.getFriendPersonaName(character.owning_player_id))

func start_ragdoll(velocity: Vector3):
	position = character.position
	simulator.physical_bones_start_simulation()
	for child in simulator.get_children():
		if child is PhysicalBone3D:
			child.linear_velocity = velocity

func stop_ragdoll():
	simulator.physical_bones_stop_simulation()
	position = Vector3(0,-1000,0)


func from_reg_dict(data: Dictionary) -> void:
	const LERP_FACTOR: float = 0.4 # The factor in which skeleton bones are lerped to their true value.
	
	if data == {}: return
	var bone_counter: int = 0
	for child in simulator.get_children():
		if child is PhysicalBone3D:
			var true_pos = data["p"][bone_counter]
			var true_rot = data["r"][bone_counter]
			
			var lerped_pos = child.global_transform.origin.lerp(true_pos, LERP_FACTOR)
			
			child.global_transform.origin = lerped_pos
			child.global_transform.basis = Basis(true_rot)
			
			bone_counter += 1

func to_reg_dict() -> Dictionary:
	if not character.is_tackled(): return {}
	if reg_tick_count < REG_TICK_QUOTA:
		reg_tick_count += 1
		return {}
	
	var data: Dictionary
	var pos_array: PackedVector3Array
	var rot_array: PackedVector3Array
	for child in simulator.get_children():
		if child is PhysicalBone3D:
			pos_array.append(child.global_transform.origin)
			rot_array.append(child.global_transform.basis.get_rotation_quaternion())
	data["p"] = pos_array
	data["r"] = rot_array
	return data

func get_ragdoll_position() -> Vector3:
	return simulator.get_child(0).global_position

func get_ragdoll_velocity() -> Vector3:
	return simulator.get_child(0).linear_velocity
