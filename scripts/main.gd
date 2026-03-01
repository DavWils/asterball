## Main scene.

extends Node

class_name MainScene
## Network manager.
@onready var network_manager: NetworkManager = $NetworkManager
## Loaded scene for the main menu.
@onready var main_menu_resource := load("res://scenes/main/main_menu/main_menu.tscn")

var found_lobbies: Array

## Loads session into a new level.
func load_level(level_name: String = Steam.getLobbyData(network_manager.lobby_id, "level")):
	# Remove old main menu and level.
	if has_node("MainMenu"):
		$MainMenu.queue_free()
	if has_node("Level"):
		$Level.queue_free()
	# If host, update metadata and tell clients to load new level..
	if network_manager.is_host():
		Steam.setLobbyData(network_manager.lobby_id, "level", level_name)
		network_manager.send_p2p_packet(0, {"m": network_manager.Message.LOAD_LEVEL, "level_name": level_name})
	var level_path: String = "res://scenes/main/levels/"+ level_name + ".tscn"
	var new_level = load(level_path).instantiate()
	add_child(new_level)

func _ready() -> void:
	Steam.lobby_match_list.connect(_on_lobby_match_list)

## Update known lobby list.
func _on_lobby_match_list(lobbies):
	found_lobbies = lobbies


## Hosts a game.
func host_game(level_name: String):
	# Create the lobby.
	print("Hosting lobby")
	show_load_screen(load("res://resources/levels/" + level_name + ".tres"))
	set_load_state(0)
	network_manager.create_lobby()
	await Steam.lobby_joined
	# Set metadata for the current level
	# Load into session's level
	set_load_state(2)
	load_level(level_name)
	hide_load_scren()

## Joins a game with the given lobby id.
func join_game(lobby_id: int):
	print("Joining lobby ", lobby_id, "that's in map ", Steam.getLobbyData(lobby_id, "level"))
	show_load_screen(load("res://resources/levels/" + Steam.getLobbyData(lobby_id, "level") + ".tres"))
	set_load_state(1)
	network_manager.join_lobby(lobby_id)
	await Steam.lobby_joined
	print("Successfully joined lobby! Loading now.")
	set_load_state(2)
	load_level()
	set_load_state(3)
	await get_tree().create_timer(1).timeout
	
	network_manager.send_p2p_packet(network_manager.get_host_id(), {"m": network_manager.Message.CLIENT_REQUEST_GAME})
	await network_manager.game_info_retrieved
	hide_load_scren()

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
		join_game(best_lobby)
	else:
		print("No lobby found.")
	found_lobbies = []

## Given array of lobbies, finds the most optimal one.
func find_most_optimal_lobby():
	if found_lobbies.is_empty():
		return null
	
	return found_lobbies[0]

## Shows the loading screen with the given level resource.
func show_load_screen(loading_level: LevelResource) -> void:
	$LoadingUI.set_loading_level(loading_level)
	$LoadingUI.visible = true

func hide_load_scren() -> void:
	$LoadingUI.visible = false

func set_load_state(state: int) -> void:
	$LoadingUI.set_load_state(state)
