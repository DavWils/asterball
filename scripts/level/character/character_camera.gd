extends Node

@onready var character: Character = self.get_parent()

func _process(_delta: float) -> void:
	self.rotation.x = lerp(self.rotation.x, character.control_pitch, .6)

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
