extends Node3D

## The time it takes for the camera to make a full rotation
const CAMERA_ROT_RATE: float = -30.0

func _process(delta: float) -> void:
	$Camera3D.rotate(Vector3(0,1,0), delta*(360.0/CAMERA_ROT_RATE) * (PI/180))
