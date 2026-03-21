@tool

extends PhysicalBoneSimulator3D

## Total mass of the ragdoll.
@export var total_mass: float

@export var calculate: bool = false:
	set(value):
		calculate = value
		if value: 
			calculate_mass()
			calculate = false


func calculate_mass() -> void:
	print("Calculating mass for ragdoll.")
	var mass_dict: Dictionary[int, float] = {}
	var total_volume: float = 0.0
	for bone in get_children():
		if bone is PhysicalBone3D:
			var accumulated_size: float = 0.0
			var shape = bone.get_child(0) as CollisionShape3D
			if shape.shape is BoxShape3D:
				accumulated_size = shape.shape.size.x * shape.shape.size.y * shape.shape.size.z
			elif shape.shape is SphereShape3D:
				accumulated_size = (4.0/3.0) * PI * (shape.shape.radius**3)
			elif shape.shape is CapsuleShape3D:
				accumulated_size = ((4.0/3.0) * PI * (shape.shape.radius**3)) + (PI * (shape.shape.radius**2)*shape.shape.height)
			mass_dict[bone.get_index()] = accumulated_size
			total_volume += accumulated_size
	for bone in get_children():
		if bone is PhysicalBone3D:
			var bone_idx := bone.get_index()
			print(bone.name, " has a size of ", mass_dict[bone_idx], ". Which is ", 100.0 * mass_dict[bone_idx]/total_volume, "%")
			bone.mass = total_mass * (mass_dict[bone_idx]/total_volume)
