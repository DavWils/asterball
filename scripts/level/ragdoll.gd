## Script for character ragdolls.

extends Node3D

class_name Ragdoll

## Character owning this ragdoll.
var character: Character

@onready var simulator = $Armature/Skeleton3D/PhysicalBoneSimulator3D

## The amount of times registry dictionary must be made before it actually sends something, necessary so no lag.
const REG_TICK_QUOTA: int = 1
## Tick count for registry.
var reg_tick_count: int = 0

func _init():
	position = Vector3(0,-1000,0)

func _ready():
	if character:
		if character.network_manager.is_in_lobby(): print("Ragdoll spawned for ", character.owning_player_id)
	else:
		simulator.physical_bones_start_simulation()
		simulator.get_child(0).apply_central_impulse(Vector3.UP*5.0)

func _physics_process(_delta: float) -> void:
	if character.network_manager.is_host():
		if character:
			if character.is_tackled():
				if not character.level.is_in_bounds(simulator.get_child(0).global_position):
					character.kill()


func start_ragdoll(force: Vector3):
	position = character.position
	simulator.physical_bones_start_simulation()
	for child in $Armature/Skeleton3D/PhysicalBoneSimulator3D.get_children():
		if child is PhysicalBone3D:
			child.apply_central_impulse(force/3.0)

func stop_ragdoll():
	simulator.physical_bones_stop_simulation()
	position = Vector3(0,-1000,0)

func from_reg_dict(data: Dictionary) -> void:
	if data.is_empty():
		return

	const LERP_FACTOR := 0.35

	var root := simulator.get_child(0)

	var true_pos: Vector3 = data["p"]
	var true_rot: Quaternion = data["r"]

	var new_transform: Transform3D = root.global_transform
	new_transform.origin = root.global_transform.origin.lerp(true_pos, LERP_FACTOR)
	new_transform.basis = Basis(true_rot)

	root.global_transform = new_transform
	root.linear_velocity = root.linear_velocity.lerp(data["v"], 0.25)

func to_reg_dict() -> Dictionary:
	if not character.is_tackled():
		return {}

	if reg_tick_count < REG_TICK_QUOTA:
		reg_tick_count += 1
		return {}

	reg_tick_count = 0

	var root := simulator.get_child(0)

	return {
		"p": root.global_transform.origin,
		"r": root.global_transform.basis.get_rotation_quaternion(),
		"v": root.linear_velocity
	}

func get_ragdoll_position() -> Vector3:
	return simulator.get_child(0).global_position

func get_ragdoll_velocity() -> Vector3:
	return simulator.get_child(0).linear_velocity
