### The base script for a level.

extends Node

class_name Level

@onready var network_manager: NetworkManager = get_tree().current_scene.get_node("NetworkManager")

## The furthest depth a character can go before they're killed.
@export var kill_depth := -100.0
## The amount of timet o wait before starting the game.
@export var pregame_wait_time := 10.0
## The amount of time to wait after a score until the next round begins.
@export var score_wait_time := 5.0
## The amount of time before the round actually starts, allowing players some time to shop and buy items.
@export var intermission_wait_time := 10.0
## The standard acceleration of gravity on this map.
@export var gravity_acceleration := 10.0

var level_registry: Dictionary[int, Node3D]



func _ready() -> void:
	print("Level has been loaded.")
	await get_tree().create_timer(pregame_wait_time).timeout
	if network_manager.is_host():
		start_game()

func _physics_process(_delta: float) -> void:
	# Send registry info to clients
	if network_manager.is_host():
		var network_registry: Dictionary
		for id in level_registry:
			network_registry[id] = {}
			network_registry[id]["p"] = level_registry[id].position # Position
			network_registry[id]["r"] = level_registry[id].rotation # Rotation
			if level_registry[id] is Character:
				network_registry[id]["pcr"] = 0 # Pitch Control Rotation if its a character.
		network_manager.send_p2p_packet(0, {"m": network_manager.MSG_REGISTRY_UPDATE, "r": network_registry}, Steam.P2P_SEND_UNRELIABLE)

## Starts the game.
func start_game() -> void:
	next_round()

## Transfers to the next round, allowing players to shop for a set time until the round actually starts.
func next_round() -> void:
	clean_level()
	spawn_omnistrikers()
	await get_tree().create_timer(intermission_wait_time).timeout
	

func score(scoring_character: Node3D) -> void:
	print(scoring_character.name, " has scored!!!")
	
	# Wait some time, and if we're the host, then start the next game.
	await get_tree().create_timer(score_wait_time).timeout
	if network_manager.is_host():
		next_round()

## Cleans up the level, removing old items and characters.
func clean_level() -> void:
	for child in get_children():
		if child is Character:
			child.queue_free()

## Spawns a character for each player.
func spawn_omnistrikers() -> void:
	var omnistriker_path := "res://scenes/level/characters/omnistriker.tscn"
	for member in network_manager.lobby_members:
		var player_id = member["steam_id"]
		spawn_character(omnistriker_path, player_id, Vector3(player_id%12, 0, player_id%10))

## Spawns the given character and adds it to the character registry.
func spawn_character(character_path: String, owner_id := -1, position := Vector3.ZERO, registry_id := get_unused_registry_id()):
	print("Spawning a new character with id ", registry_id)
	
	var character: Character = load(character_path).instantiate()
	character.registry_id = registry_id
	character.owning_player_id = owner_id
	character.position = position
	character.transform = character.transform.looking_at(Vector3(0,character.position.y,0))
	
	level_registry[registry_id] = character
	add_child(character)
	
	# If we're the host, let clients know to spawn the character.
	if network_manager.is_host():
		network_manager.send_p2p_packet(0, 
		{
			"m": network_manager.MSG_SPAWN_CHAR,
			"char_path": character_path,
			"registry_id": registry_id,
			"owner_id": owner_id,
			"position": position
		}
		)

## Returns a registry id thats not used.
func get_unused_registry_id() -> int:
	var new_id := 0
	while level_registry.has(new_id):
		new_id += 1
	return new_id
