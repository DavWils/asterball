extends AudioStreamPlayer3D

func play_step_sonud() -> void:
	pitch_scale = randf_range(0.9,1.2)
	play()
