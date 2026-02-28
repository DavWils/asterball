extends Node3D

@onready var character: Character = self.get_parent()

@onready var camera: Camera3D = $PlayerCamera

## Basic height of the camera
const BASE_HEIGHT := 1.8
## Basic camera distance from character.
const BASE_LENGTH := 2.0

## Height of camera while aiming
const AIM_HEIGHT := 2.0
## Distance from character while aiming
const AIM_LENGTH := 0.8
## Side offset while iaming
const AIM_OFFSET := 1.0


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
		camera.fov = lerp(camera.fov, 75.0 - ((min(ragdoll_distance*1,50.0))), 0.2)
	else:
		self.rotation.x = lerp(self.rotation.x, character.control_pitch, .6)
		self.rotation.y = lerp(self.rotation.y, 0.0, 0.6)
		camera.fov = lerp(camera.fov, 75.0, 0.4)
		if character.is_aiming():
			self.position = self.position.lerp(Vector3(0, AIM_HEIGHT, 0), 0.2)
			camera.position = camera.position.lerp(Vector3(AIM_OFFSET, 0, AIM_LENGTH), 0.2)
		else:
			self.position = self.position.lerp(Vector3(0, BASE_HEIGHT, 0), 0.2)
			camera.position = camera.position.lerp(Vector3(0, 0, BASE_LENGTH), 0.2)

## Shakes the camera based on the given force.
func tackle_shake(_force: float):
	pass
#	var initial_transform = self.transform 
#	var elapsed_time = 0.0
#	var period = log(force)/3 # The length of the shake
#	var initial_magnitude = force/4 # The initial magnitude of the shake
#	while elapsed_time < period:
#		var magnitude: float = initial_magnitude*((period-elapsed_time)/period)
#		var offset = Vector3(
#			randf_range(-magnitude, magnitude),
#			randf_range(-magnitude, magnitude),
#			0.0
#		)
#	
#		self.transform.origin = initial_transform.origin + offset
#		elapsed_time += get_process_delta_time()
#		await get_tree().process_frame
#	
#	self.transform = initial_transform
