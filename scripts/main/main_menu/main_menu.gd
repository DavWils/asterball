extends Node3D

## The time it takes for the camera to make a full rotation
@export var camera_rot_rate: float = -30.0

func _process(delta: float) -> void:
	$Camera3D.rotate(Vector3(0,1,0), delta*(360.0/camera_rot_rate) * (PI/180))
