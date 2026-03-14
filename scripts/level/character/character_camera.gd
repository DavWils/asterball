extends Node3D

@onready var character: Character = self.get_parent()

@onready var camera: Camera3D = $PlayerCamera

## Basic height of the camera
const BASE_HEIGHT := 1.8
## Basic camera distance from character.
const BASE_LENGTH := 2.0

## Height of camera while aiming
const AIM_HEIGHT := 2.2
## Distance from character while aiming
const AIM_LENGTH := 1.5
## Side offset while iaming
const AIM_OFFSET := 1.3

## Camera position offset caused by camera shake.
var shake_time := 0.0
var shake_duration := 0.0
var shake_strength := 0.0
var shake_offset := Vector3.ZERO

## Returns player's base fov.
func get_base_fov() -> float:
	return 75.0

## returns the camera offset to lerp to based on the character status. 0 is for the handle and 1 is for the camera.
func get_camera_offset() -> Array[Vector3]:
	var handle_offset: Vector3
	var cam_offset: Vector3
	
	# Get the base offsets.
	if character.is_tackled():
		handle_offset = Vector3(0,2,0)
		cam_offset = Vector3.ZERO
	if character.is_aiming():
		handle_offset = Vector3(0, AIM_HEIGHT, 0)
		cam_offset = Vector3(AIM_OFFSET, 0, AIM_LENGTH)
	else:
		handle_offset = Vector3(0, BASE_HEIGHT, 0)
		cam_offset = Vector3(0, 0, BASE_LENGTH)
	
	# Raycast to find out new cam transforms when blocked.
	
	var handle_global = character.global_transform * handle_offset
	var desired_cam_global = global_transform * (cam_offset)
	
	
	
	# Raycast
	var space_state := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(handle_global, desired_cam_global, 1)
	query.exclude = [character]
	
	var result = space_state.intersect_ray(query)
	
	if result:
		var new_cam_global = result.position + (handle_global-result.position).normalized()*0.6
		cam_offset = to_local(new_cam_global)

	return [handle_offset, cam_offset]



func _process(_delta: float) -> void:
	var cam_offset := get_camera_offset()
	self.position = self.position.lerp(cam_offset[0], 0.2)
	camera.position = camera.position.lerp(cam_offset[1], 0.2)
	
	# While tackled, focus on ragdoll.
	if character.is_tackled():
		var ragdoll_position = character.ragdoll.get_ragdoll_position()
		var target_transform = global_transform.looking_at(ragdoll_position, Vector3.UP)

		var current_q = global_transform.basis.get_rotation_quaternion()
		var target_q = target_transform.basis.get_rotation_quaternion()

		var new_q = current_q.slerp(target_q, 0.2)

		global_transform.basis = Basis(new_q)
		
		# Zoom camera on ragdoll.
		var ragdoll_distance = global_position.distance_to(ragdoll_position)
		var zoom_offset = (min(ragdoll_distance*4,50.0))
		camera.fov = lerp(camera.fov, get_base_fov() - zoom_offset, 0.2)
	else:
		self.rotation.x = lerp(self.rotation.x, character.control_pitch, .6)
		self.rotation.y = lerp(self.rotation.y, 0.0, 0.6)

		# While throwing, zoom forward.
		if character.is_throwing():
			camera.fov = lerp(camera.fov, get_base_fov() - ((character.throw_component.throw_force / character.throw_component.get_max_throw_force()) * 35), 0.4)
		else:
			camera.fov = lerp(camera.fov, get_base_fov(), 0.4)
	
	
	# Camera shake update
	if shake_time < shake_duration:
		shake_time += _delta
		
		var fade := 1.0 - (shake_time / shake_duration)
		var magnitude := shake_strength * fade
		
		shake_offset = Vector3(
			randf_range(-magnitude, magnitude),
			randf_range(-magnitude, magnitude),
			0.0
		)
	else:
		shake_offset = Vector3.ZERO

	self.position += shake_offset

## Shakes the camera based on the given force.
func camera_shake(force: float):
	shake_strength = force * 0.1
	shake_duration = clamp(log(force) * 0.2, 0.1, 0.6)
	shake_time = 0.0
