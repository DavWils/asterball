extends Node

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
	self.rotation.x = lerp(self.rotation.x, character.control_pitch, .6)
	if character.is_aiming:
		self.position = self.position.lerp(Vector3(0, AIM_HEIGHT, 0), 0.2)
		camera.position = camera.position.lerp(Vector3(AIM_OFFSET, 0, AIM_LENGTH), 0.2)
	else:
		self.position = self.position.lerp(Vector3(0, BASE_HEIGHT, 0), 0.2)
		camera.position = camera.position.lerp(Vector3(0, 0, BASE_LENGTH), 0.2)

## Shakes the camera based on the given force.
func tackle_shake(force: float):
	print("SHAKE")
	var initial_transform = self.transform 
	var elapsed_time = 0.0
	var period = log(force)/3 # The length of the shake
	var initial_magnitude = force/4 # The initial magnitude of the shake
	while elapsed_time < period:
		var magnitude: float = initial_magnitude*((period-elapsed_time)/period)
		var offset = Vector3(
			randf_range(-magnitude, magnitude),
			randf_range(-magnitude, magnitude),
			0.0
		)
	
		self.transform.origin = initial_transform.origin + offset
		elapsed_time += get_process_delta_time()
		await get_tree().process_frame
	
	self.transform = initial_transform
