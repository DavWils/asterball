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

func _process(_delta: float) -> void:
	if character.is_tackled():
		self.position = self.position.lerp(Vector3.UP*2, 0.2)
		camera.position = camera.position.lerp(Vector3.ZERO, 0.2)
		
		var ragdoll_position = character.ragdoll.get_ragdoll_position()
		var target_transform = global_transform.looking_at(ragdoll_position, Vector3.UP)

		var current_q = global_transform.basis.get_rotation_quaternion()
		var target_q = target_transform.basis.get_rotation_quaternion()

		var new_q = current_q.slerp(target_q, 0.2)

		global_transform.basis = Basis(new_q)
		
		# Zoom camera on ragdoll.
		var ragdoll_distance = global_position.distance_to(ragdoll_position)
		camera.fov = lerp(camera.fov, get_base_fov() - ((min(ragdoll_distance*1,50.0))), 0.2)
	else:
		self.rotation.x = lerp(self.rotation.x, character.control_pitch, .6)
		self.rotation.y = lerp(self.rotation.y, 0.0, 0.6)
		if character.is_aiming():
			self.position = self.position.lerp(Vector3(0, AIM_HEIGHT, 0), 0.2)
			camera.position = camera.position.lerp(Vector3(AIM_OFFSET, 0, AIM_LENGTH), 0.2)
		else:
			self.position = self.position.lerp(Vector3(0, BASE_HEIGHT, 0), 0.2)
			camera.position = camera.position.lerp(Vector3(0, 0, BASE_LENGTH), 0.2)
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
