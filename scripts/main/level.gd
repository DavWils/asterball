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
			network_registry[id] = level_registry[id].to_reg_dict()
		network_manager.send_p2p_packet(0, {"m": network_manager.MSG_REGISTRY_UPDATE, "r": network_registry}, Steam.P2P_SEND_UNRELIABLE)

## Starts the game.
func start_game() -> void:
	next_round()

## Transfers to the next round, allowing players to shop for a set time until the round actually starts.
func next_round() -> void:
	clean_level()
	spawn_omnistrikers()
	spawn_ball()
	await get_tree().create_timer(intermission_wait_time).timeout
	

func score(scoring_character: Node3D) -> void:
	print(scoring_character.name, " has scored!!!")
	
	# Wait some time, and if we're the host, then start the next game.
	await get_tree().create_timer(score_wait_time).timeout
	if network_manager.is_host():
		next_round()

## Cleans up the level, removing old stuff from registry.
func clean_level() -> void:
	for registry_child in level_registry:
		level_registry[registry_child].queue_free()
	level_registry.clear()

## Spawns a character for each player.
func spawn_omnistrikers() -> void:
	var omnistriker_path := "res://scenes/level/characters/omnistriker.tscn"
	for member in network_manager.lobby_members:
		var player_id = member["steam_id"]
		spawn_character(omnistriker_path, player_id, Vector3(player_id%12, 0, player_id%10))

## Spawns the given character and adds it to the character registry.
func spawn_character(character_path: String, owner_id := -1, character_position := Vector3.ZERO, registry_id := get_unused_registry_id()):
	print("Spawning a new character with id ", registry_id)
	
	var character: Character = load(character_path).instantiate()
	character.registry_id = registry_id
	character.owning_player_id = owner_id
	character.position = character_position
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
			"position": character_position
		}
		)

# Spawns the ball in the level.
func spawn_ball():
	spawn_pickup("res://resources/items/ball.tres", {}, Vector3.UP*5)

func spawn_pickup(resource_path: String, item_data: Dictionary, item_position := Vector3.ZERO, registry_id := get_unused_registry_id()):
	var pickup_node: Pickup = load("res://scenes/level/pickup.tscn").instantiate()
	pickup_node.position = item_position
	pickup_node.item_data = item_data
	pickup_node.item_resource = load(resource_path)
	pickup_node.registry_id = registry_id
	
	add_child(pickup_node)
	# If we're hte host, let clients know to spanw the pickup.
	if network_manager.is_host():
		network_manager.send_p2p_packet(0, 
		{
			"m": network_manager.MSG_SPAWN_PICKUP,
			"resource_path": resource_path,
			"item_data": item_data,
			"position": item_position,
			"registry_id": registry_id
		}
		)


## Returns a registry id thats not used.
func get_unused_registry_id() -> int:
	var new_id := 0
	while level_registry.has(new_id):
		new_id += 1
	return new_id
