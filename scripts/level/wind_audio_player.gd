extends AudioStreamPlayer

@onready var player_controller: PlayerController = self.get_parent().get_node("PlayerController")

func _process(_delta: float) -> void:
	if playing and player_controller.current_character:
		var character = player_controller.current_character
		var current_velocity: float = character.get_body_velocity().length()
		var speed_ratio = max(current_velocity-8.0, 0.0) / 30.0
		var new_volume = pow(speed_ratio, 2.2)
		volume_db = lerp(volume_db, linear_to_db(clampf(new_volume * .3, 0.01, 1.0)), 0.4)
		pitch_scale = clampf(pitch_scale + (current_velocity if randi()%2 else -current_velocity)*0.0001, 0.9, 1.3)
	else:
		volume_db = linear_to_db(0.001)
