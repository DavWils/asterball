extends AudioStreamPlayer3D

@onready var character: Character = self.get_parent().get_parent()

@export var footstep_wait_time: float

func _ready() -> void:
	$Timer.wait_time = footstep_wait_time

func play_step_sonud() -> void:
	if $Timer.is_stopped() or character.is_charging():
		pitch_scale = randf_range(0.9,1.2)
		play()
		$Timer.start()
