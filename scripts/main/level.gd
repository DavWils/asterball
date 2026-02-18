### The base script for a level.

extends Node

class_name Level

@onready var network_manager: NetworkManager = get_tree().current_scene.get_node("NetworkManager")
@onready var match_state = $MatchState
@onready var match_director = $MatchDirector

## The furthest depth a character can go before they're killed.
@export var kill_depth := -100.0
## The standard acceleration of gravity on this map.
@export var gravity_acceleration := 10.0


var level_registry: Dictionary[int, Node3D] = {}

func _ready() -> void:
	print("Level has been loaded.")


func _physics_process(_delta: float) -> void:
	# Send registry info to clients
	if network_manager.is_host():
		var network_registry: Dictionary
		for id in level_registry:
			network_registry[id] = level_registry[id].to_reg_dict()
		network_manager.send_p2p_packet(0, {"m": network_manager.Message.REGISTRY_UPDATE, "r": network_registry}, Steam.P2P_SEND_UNRELIABLE)



## Spawns the given character and adds it to the character registry.
func spawn_character(character_path: String, owner_id := -1, character_position := Vector3.ZERO, registry_id := get_unused_registry_id()) -> Character:
	print("Spawning a new character with id ", registry_id)
	var character: Character = load(character_path).instantiate()
	character.registry_id = registry_id
	character.owning_player_id = owner_id
	character.position = character_position
	var is_x_greater: bool = abs(character.position.x) > abs(character.position.z)
	var look_at_vector := Vector3(0.0, character.position.y, 0.0)
	if is_x_greater:
		look_at_vector.z = character.position.z
	else:
		look_at_vector.x = character.position.x
	character.transform = character.transform.looking_at(look_at_vector)
	
	add_child(character)
	level_registry[registry_id] = character
	# If we're the host, let clients know to spawn the character.
	if network_manager.is_host():
		network_manager.send_p2p_packet(0, 
		{
			"m": network_manager.Message.SPAWN_CHAR,
			"char_path": character_path,
			"registry_id": registry_id,
			"owner_id": owner_id,
			"position": character_position
		}
		)
	return character

func spawn_pickup(item_state: ItemState, item_position := Vector3.ZERO, thrower_id: int = -1, registry_id := get_unused_registry_id()) -> Pickup:
	var pickup_node: Pickup = load("res://scenes/level/pickup.tscn").instantiate()
	pickup_node.position = item_position
	pickup_node.item_state = item_state
	pickup_node.registry_id = registry_id
	pickup_node.thrower_id = thrower_id
	
	level_registry[registry_id] = pickup_node
	add_child(pickup_node)
	# If we're hte host, let clients know to spanw the pickup.
	if network_manager.is_host():
		network_manager.send_p2p_packet(0, 
		{
			"m": network_manager.Message.SPAWN_PICKUP,
			"item_state": item_state.to_dict(),
			"position": item_position,
			"registry_id": registry_id,
			"thrower_id": thrower_id
		}
		)
	return pickup_node

func spawn_projectile(item_state: ItemState, start_position: Vector3, thrower_id: int, registry_id := get_unused_registry_id()):
	var projectile_node: Projectile = item_state.item_resource.get_projectile_scene().instantiate()
	projectile_node.position = start_position
	projectile_node.item_state = item_state
	projectile_node.registry_id = registry_id
	projectile_node.thrower_id = thrower_id
	
	level_registry[registry_id] = projectile_node
	add_child(projectile_node)
	
	# If we're the host, let clients know to spanw the projectile.
	if network_manager.is_host():
		network_manager.send_p2p_packet(0, 
		{
			"m": network_manager.Message.SPAWN_PROJECTILE,
			"item_state": item_state.to_dict(),
			"position": start_position,
			"registry_id": registry_id,
			"thrower_id": thrower_id
		}
		)
	return projectile_node



## Removes a scene from the registry and deletes it for host and clients.
func despawn_registry_object(registry_id: int):
	print("Despawning registry object at id ", registry_id)
	level_registry[registry_id].queue_free()
	level_registry.erase(registry_id)
	if network_manager.is_host():
		network_manager.send_p2p_packet(0, {"m": network_manager.Message.DESPAWN_OBJECT, "registry_id": registry_id})

## Returns a registry id thats not used.
func get_unused_registry_id() -> int:
	var new_id := 0
	while level_registry.has(new_id):
		new_id += 1
	return new_id

## Returns a spawn zone given a team.
func get_spawn_zone(team: int) -> SpawnZone: 
	var spawn_zones: Array[SpawnZone]
	for c in get_children():
		if c is SpawnZone:
			if c.owning_team == team:
				spawn_zones.append(c)
	return spawn_zones.pick_random()

func get_level_resource() -> LevelResource:
	var level_name: String = get_scene_file_path().get_basename().get_file()
	var resource_filepath: String = "res://resources/levels/"
	return load(resource_filepath + level_name + ".tres")

## Effect that's played when character scores.
func score_effect(scorer: Character) -> void:
	play_global_sound("res://sounds/level/touchdown_horn.wav")
	if network_manager.is_host():
		network_manager.send_p2p_packet(0, {"m": network_manager.Message.SCORE_EFFECT, "char_id": scorer.registry_id})

func play_global_sound(sound: String) -> void:
	$AudioStreamPlayer.stream = load(sound)
	$AudioStreamPlayer.play()
