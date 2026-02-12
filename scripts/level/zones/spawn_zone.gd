extends Zone

class_name SpawnZone

## The minimum amount of space that must be inbetween players. If exceeding, will likely go into multiple rows.
const MIN_PLAYER_SPACE = 1.4
## The maximum amount of space that can be inbetween spawning players.
const MAX_PLAYER_SPACE = 3.0


## Gets the spawn position of a player given their index (Player number) out of all players in the given team.
func get_spawn_position(index: int, quantity: int) -> Vector3:
	var origin_position: Vector3 = position - (Vector3.UP * 0.5 * $CollisionShape3D.shape.size)
	
	# If true, the spawn zone is facing the origin of the map in z axis. otherwise x.
	var is_z_facing: bool = abs(position.z) >= abs(position.x)
	# The amount of space between players side by side.
	var side_space: float = (collision_shape.shape.size.x if is_z_facing else collision_shape.shape.size.z) / quantity
	
	# Clamp down to max space.
	if side_space > MAX_PLAYER_SPACE: side_space = MAX_PLAYER_SPACE
	
	
	# Get spawn position which is origin position with an offset
	var direction: Vector3 = Vector3.RIGHT if is_z_facing else Vector3.FORWARD
	@warning_ignore("integer_division")
	var spawn_position: Vector3 = origin_position + (
		direction * (side_space * (index - (quantity / 2))) +
		direction * (side_space / 2.0 if quantity % 2 == 0 else 0.0)
	)
	print("Spawn position for ", index, "/", quantity, " for team ", owning_team, " is ", spawn_position)
	return spawn_position
