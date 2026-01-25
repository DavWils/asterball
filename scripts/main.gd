extends Node

@onready var network_manager: NetworkManager = $NetworkManager

## Opens a level with the given string name.
func open_level(level_path: String):
	var new_level = load(level_path).instantiate()
	add_child(new_level)

func _ready() -> void:
	Steam.lobby_match_list.connect(_on_lobby_match_list)
	Steam.requestLobbyList()

func _on_lobby_match_list(lobbies):
	if lobbies.is_empty():
		print("Did not find a lobby. Hosting instead.")
		host_game()
	else:
		print("Found a lobby. Trying to join.")
		join_game(lobbies[0])

func host_game():
	print("Hosting lobby")
	network_manager.create_lobby()
	await Steam.lobby_joined
	open_level("res://scenes/main/levels/starfield.tscn")

func join_game(lobby_id: int):
	print("Joining lobby ", lobby_id, "...")
	network_manager.join_lobby(lobby_id)
	await Steam.lobby_joined
	print("Successfully joined lobby!")
	open_level("res://scenes/main/levels/starfield.tscn")
	await get_tree().create_timer(1).timeout
	network_manager.send_p2p_packet(network_manager.get_host_id(), {"m": network_manager.MSG_REQUEST_GAME_INFO})
