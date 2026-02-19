extends RigidBody3D

class_name Projectile

@onready var network_manager: NetworkManager = get_tree().current_scene.get_node("NetworkManager")
@onready var level: Level = get_tree().current_scene.get_node("Level")

## Item state
var item_state: ItemState
## Registry id
var registry_id: int
## Player id of the thrower.
var thrower_id: int
## The character who threw the item.
var throwing_character: Character

func _ready() -> void:
	# Set values to represent item state.
	$MeshInstance3D.mesh = item_state.item_resource.item_mesh
	$CollisionShape3D.shape = item_state.item_resource.pickup_collision_shape
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	projectile_collide(body)

## Called when projectile collides with another object.
func projectile_collide(body: Node3D):
	if network_manager.is_host():
		print(item_state.item_resource.item_name, " projectile has overlapped with ", body.get_parent().name)

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
