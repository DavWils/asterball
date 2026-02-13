## Main scene.

extends Node

class_name MainScene
## Network manager.
@onready var network_manager: NetworkManager = $NetworkManager
## Loaded scene for the main menu.
@onready var main_menu_resource := load("res://scenes/main/main_menu/main_menu.tscn")

var found_lobbies: Array

## Loads into session's level.
func load_level(level_path: String):
	if $MainMenu:
		$MainMenu.queue_free()
	var new_level = load(level_path).instantiate()
	add_child(new_level)

func _ready() -> void:
	Steam.lobby_match_list.connect(_on_lobby_match_list)
	Steam.requestLobbyList()

func _on_lobby_match_list(lobbies):
	found_lobbies = lobbies

## Hosts a game.
func host_game():
	print("Hosting lobby")
	network_manager.create_lobby()
	await Steam.lobby_joined
	load_level("res://scenes/main/levels/starfield.tscn")

## Joins a game with the given lobby id.
func join_game(lobby_id: int):
	print("Joining lobby ", lobby_id, "...")
	network_manager.join_lobby(lobby_id)
	await Steam.lobby_joined
	print("Successfully joined lobby! Loading now.")
	load_level("res://scenes/main/levels/starfield.tscn")
	await get_tree().create_timer(1).timeout
	network_manager.send_p2p_packet(network_manager.get_host_id(), {"m": network_manager.Message.CLIENT_REQUEST_GAME})

## Leave game and return to menu.
func return_to_menu():
	# If in lobby, leave before returning.
	if network_manager.is_in_lobby():
		network_manager.leave_lobby()
	$Level.queue_free()
	add_child(main_menu_resource.instantiate())

## Finds an optimal session and joins it.
func quick_find_game():
	Steam.requestLobbyList()
	await Steam.lobby_match_list
	var best_lobby = find_most_optimal_lobby()
	if best_lobby:
		print("Joining lobby ", best_lobby)
		join_game(best_lobby)
	else:
		print("No lobby found.")
	found_lobbies = []

## Given array of lobbies, finds the most optimal one.
func find_most_optimal_lobby():
	if found_lobbies.is_empty():
		return null
	
	return found_lobbies[0]
