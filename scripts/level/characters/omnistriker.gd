extends Character

class_name Omnistriker

func _ready() -> void:
	super._ready()
	# When omnistriker spawns they are instantly possessed.
	if owning_player == network_manager.player_id:
		player_controller.possess_character(self)
