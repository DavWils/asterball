extends AudioStreamPlayer

@onready var player_controller: PlayerController = self.get_parent().get_node("PlayerController")

func _process(delta: float) -> void:
	if playing and player_controller.current_character:
		var character = player_controller.current_character
		var current_velocity: float = character.get_body_velocity().length()

		var min_speed := 6.0
		var max_speed := 24.0

		var speed_ratio := clampf((current_velocity - min_speed) / (max_speed - min_speed), 0.0, 1.0)

		var new_linear := pow(speed_ratio, 1.5) * 0.3
		var target_db := linear_to_db(clampf(new_linear, 0.01, 1.0))

		volume_db = lerp(volume_db, target_db, 6.0 * delta)
		pitch_scale = lerp(pitch_scale, 0.9 + (speed_ratio if randi()%2 else -speed_ratio) * 0.4, 5.0 * delta)

	else:
		volume_db = lerp(volume_db, linear_to_db(0.001), 6.0 * delta)
