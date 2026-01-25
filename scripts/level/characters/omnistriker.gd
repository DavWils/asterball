extends Character

class_name Omnistriker

func _ready() -> void:
	super._ready()
	Steam.lobby_chat_update.connect(_on_lobby_chat_update)
	# When omnistriker spawns they are instantly possessed.
	if owning_player_id == network_manager.player_id:
		player_controller.possess_character(self)

func _on_lobby_chat_update(_id: int, changed_id: int, _change_maker_id: int, chat_state: int):
	if chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_LEFT and changed_id == owning_player_id:
		self.queue_free()
