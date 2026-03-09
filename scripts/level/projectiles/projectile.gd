extends RigidBody3D

class_name Projectile

@onready var network_manager: NetworkManager = get_tree().current_scene.get_node("NetworkManager")
@onready var level: Level = get_tree().current_scene.get_node("Level")

## Minimum momentum needed for projectile to cause a tackle.
const MIN_TACKLE_SCORE: float = 3.0

## Spawned item mesh.
var projectile_mesh: Node3D

## Item state
var item_state: ItemState
## Registry id
var registry_id: int
## Player id of the thrower.
var thrower_id: int
## The character who threw the item.
var throwing_character: Character

## The time in which the projectile was first thrown.
var start_time: float

## Returns the team state of allegiance team.
func get_allegiance_team() -> TeamState:
	var match_state: MatchState = level.match_state
	return match_state.get_team_state(item_state.current_allegiance)

func _ready() -> void:
	# Spawn item mesh, take the item mesh's collision shape and copy it to our own, disabling the original
	var item_mesh: Node3D = item_state.item_resource.mesh_file.instantiate()
	add_child(item_mesh)
	projectile_mesh = item_mesh
	var mesh_shape: CollisionShape3D = item_mesh.find_child("CollisionShape3D")
	$CollisionShape3D.shape = mesh_shape.shape
	mesh_shape.disabled = true
	$CollisionShape3D.disabled = false
	$Area3D/CollisionShape3D.shape = $CollisionShape3D.shape
	$Area3D/CollisionShape3D.disabled = false
	
	var mesh_instance = projectile_mesh.get_child(0)
	for i in mesh_instance.get_surface_override_material_count():
		var current_mat = mesh_instance.get_active_material(i)
		if current_mat:
			mesh_instance.set_surface_override_material(i, current_mat.duplicate())
	
	mass = item_state.get_item_mass()
	
	start_time = Time.get_ticks_msec()
	
	print("Spawned projectile ", registry_id)
	
	
	$Area3D.body_entered.connect(_on_area_body_entered)
	body_entered.connect(_on_body_entered)

func _physics_process(_delta: float) -> void:
	# If out of bounds, kill or respawn.
	if network_manager.is_host():
		if not level.is_in_bounds(position):
			if item_state.item_resource.is_essential:
				linear_velocity = Vector3.ZERO
				position = level.default_item_spawn
			else:
				despawn_projectile()


func _on_body_entered(body: Node3D) -> void:
	surface_collide(body)

func get_momentum() -> Vector3:
	return linear_velocity * item_state.get_item_mass()

func _on_area_body_entered(body: Node3D) -> void:
	if Time.get_ticks_msec() - start_time <= 1000: return
	if body is Character:
		character_overlap(body)

## Returns the tackle score of this projectile towards the given character.
func get_tackle_score(target: Character) -> float:
	var self_momentum := get_momentum()
	var target_momentum := target.get_momentum()
	
	var offset := target.position - position
	if offset.length_squared() == 0:
		return 0
	
	var dir := offset.normalized()
	
	var projectile_score := self_momentum.dot(dir)
	var target_score := -target_momentum.dot(dir)
	return projectile_score - target_score

func character_overlap(character: Character):
	print("Score: ", get_tackle_score(character))
	var tackle_score = get_tackle_score(character)
	if tackle_score >= MIN_TACKLE_SCORE: character.tackle(self, tackle_score)
	print(item_state.item_resource.item_name, " has collided with player ", Steam.getFriendPersonaName(character.owning_player_id))

func surface_collide(body: Node3D) -> void:
	print(item_state.item_resource.item_name, " projectile has overlapped with ", body.name)
	# Play a sound on collision
	var linear_vol: float = linear_velocity.length()/25.0
	$CollideAudioPlayer.volume_linear = clampf(linear_vol, 0.0, 1.0)
	$CollideAudioPlayer.pitch_scale = randf_range(0.9,1.1)
	$CollideAudioPlayer.play()

func despawn_projectile():
	level.despawn_registry_object(registry_id)

## Converts character information to a dictionary that can be loaded by players joining the game. Used for time-specific parts like held item, etc. Position isn't exactly needed as it's updated each physics process.
func to_init_dict() -> Dictionary:
	var pickup_data: Dictionary
	
	pickup_data["item_state"] = item_state.to_dict()
	pickup_data["thrower_id"] = thrower_id
	
	return pickup_data

## Loads character variables based on the given dictionary.
func from_init_dict(data: Dictionary) -> void:
	item_state = ItemState.new()
	item_state.from_dict(data["item_state"])

## Converts ongoing character values that need to be updated to players from host constantly, like position and such.
func to_reg_dict() -> Dictionary:
	var character_reg_data: Dictionary
	character_reg_data["p"] = position # Position
	character_reg_data["r"] = rotation # Rotation
	character_reg_data["v"] = linear_velocity # Velocity
	
	return character_reg_data

## Loads character registry info from dict.
func from_reg_dict(data: Dictionary) -> void:
	var new_pos: Vector3 = data["p"]
	var new_rot: Vector3 = data["r"]
	var new_vel: Vector3 = data["v"]
	
	const PROJECTILE_LERP_FACTOR: float = 0.6
	
	position = position.lerp(new_pos, PROJECTILE_LERP_FACTOR)
	rotation = rotation.lerp(new_rot, PROJECTILE_LERP_FACTOR)
	linear_velocity = new_vel

## Called when interacted with.
func interact(interactor: Character) -> void:
	if interactor.is_inventory_full(): interactor.drop_equipped_item()
	await get_tree().process_frame
	level.despawn_registry_object(registry_id)
	interactor.pickup_item(item_state)

## Text to display to an interacting player.
func get_interact_text() -> String:
	return("Pickup " + item_state.item_resource.item_name)
