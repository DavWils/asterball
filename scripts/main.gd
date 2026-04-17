## Main scene.

extends Node

class_name MainScene
## Network manager.
@onready var network_manager: NetworkManager = $NetworkManager
## Loaded scene for the main menu.
@onready var main_menu_resource := load("res://scenes/main/main_menu/main_menu.tscn")

@onready var asset_loader: AssetLoader = $AssetLoader

@onready var options_node: OptionsNode = $Options

@export var playable_levels: Array[LevelResource]

var found_lobbies: Array

## Filepath to the options file
const OPTIONS_FILE_PATH := "user://options.cfg"

## Loads session into a new level.
func load_level(level: LevelResource = load("res://resources/levels/" + Steam.getLobbyData(network_manager.lobby_id, "level") + ".tres")):
	set_load_state(2)
	# Remove old main menu and level.
	if has_node("MainMenu"):
		$MainMenu.queue_free()
	if has_node("Level"):
		print("Removing old level")
		$Level.queue_free()
	
	await get_tree().process_frame
	var new_level = level.get_level_scene().instantiate()
	add_child(new_level)
	if not new_level.is_node_ready(): await new_level.ready
	
	# If host, update metadata and tell clients to load new level..
	if network_manager.is_host():
		if network_manager.is_in_lobby():
			var level_name = level.get_level_filename()
			Steam.setLobbyData(network_manager.lobby_id, "level", level_name)
			network_manager.send_p2p_packet(0, {"m": network_manager.Message.LOAD_LEVEL, "level_name": level_name})
	else:
		set_load_state(3)
		network_manager.send_p2p_packet(network_manager.get_host_id(), {"m": network_manager.Message.CLIENT_REQUEST_GAME})
		await network_manager.game_info_retrieved
	
	hide_load_scren()

func _ready() -> void:
	asset_loader.load_complete.connect(_on_load_complete)
	asset_loader.asset_started.connect(_on_asset_started)
	load_options()
	Steam.lobby_match_list.connect(_on_lobby_match_list)
	await get_tree().process_frame
	asset_loader.load_assets()

func _on_load_complete() -> void:
	$InitialLoadUI.queue_free()
	add_child(load("res://scenes/main/main_menu/main_menu.tscn").instantiate())

func _on_asset_started(asset_name: String) -> void:
	print("Loading ", asset_name)
	$InitialLoadUI/AssetLabel.text = "Loading " + asset_name.get_file()

## Update known lobby list.
func _on_lobby_match_list(lobbies):
	found_lobbies = lobbies


## Hosts a game.
func host_game(level: LevelResource, session_name := "Asterball Session"):
	show_load_screen(level)
	if network_manager.is_steam_initialized:
		# Create the lobby.
		print("Hosting lobby")
	
		set_load_state(0)
		network_manager.create_lobby()
		await Steam.lobby_joined
		Steam.setLobbyData(network_manager.lobby_id, "lobby_name", session_name)
	# Load into session's level
	load_level(level)
	

## Joins a game with the given lobby id.
func join_game(lobby_id: int):
	print("Joining lobby ", lobby_id, "that's in map ", Steam.getLobbyData(lobby_id, "level"))
	show_load_screen(load("res://resources/levels/" + Steam.getLobbyData(lobby_id, "level") + ".tres"))
	set_load_state(1)
	network_manager.join_lobby(lobby_id)
	await Steam.lobby_joined
	print("Successfully joined lobby! Loading now.")
	load_level()
	
	

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

## Returns every level resource.
func get_all_levels() -> Array[LevelResource]:
	return playable_levels

func apply_options(options: Dictionary) -> void:
	var options_file = ConfigFile.new()
	
	for key in options:
		for sub_key in options[key]:
			options_file.set_value(key, sub_key, options[key][sub_key])
			print("Applied Option: ", key, ": ", sub_key, " = ", options[key][sub_key])

	var save_status := options_file.save(OPTIONS_FILE_PATH)
	if save_status == OK:
		print("Successfully saved options!")
	else:
		print("Failed to save options. [", str(save_status), "]")
	
	load_options()


func load_options() -> void:
	options_node.loaded_options.clear()
	
	var options_file := ConfigFile.new()
	var load_status = options_file.load(OPTIONS_FILE_PATH)
	if load_status == OK:
		print("Options Config loaded successfully!")
	else:
		print("Failed to find options config.")
		
		var temp_options = load("res://scenes/ui/menu/options_menu.tscn").instantiate()
		temp_options.visible = false
		add_child(temp_options)
		temp_options._on_apply_pressed()
		temp_options.queue_free()
		
		return
	
	if options_file.has_section("audio"):
		for bus in options_file.get_section_keys("audio"):
			AudioServer.set_bus_volume_linear(bus.to_int(), options_file.get_value("audio", bus))
	
	# Load Display Settings
	options_node.loaded_options["display"] = {}
	if options_file.has_section("display"):
		options_node.loaded_options["display"]["camera_shake"] = options_file.get_value("display", "camera_shake")
	else:
		options_node.loaded_options["display"]["camera_shake"] = 1.0
	
	# Load keybinds
	if options_file.has_section("keybinds"):
		for keybind in options_file.get_section_keys("keybinds"):
			InputMap.action_erase_events(keybind)
			InputMap.action_add_event(keybind, options_file.get_value("keybinds", keybind))
