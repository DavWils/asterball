extends CharacterBody3D

class_name Character

@onready var network_manager: NetworkManager = get_tree().current_scene.get_node("NetworkManager")
@onready var player_controller: PlayerController = get_tree().current_scene.get_node("Level").get_node("PlayerController")
@onready var level: Level = get_tree().current_scene.get_node("Level")

## The minimum speed a character must be going to tackle another.
const MINIMUM_TACKLE_SPEED := 5.0

## The non charging speed of this character. (m/s)
@export var walk_speed := 1
## The maximum base charging speed of the character, not including any buffs.
@export var base_charge_speed := 24.0
## The base acceleration of the character when charging.(m/2^2)
@export var base_charge_acceleration := 2
## Whether or not this character can rotate on the x axis as opposed to being applied to control rotation.
@export var use_pitch_rotation: bool = false

## The id of the player currently controlling this character. Or -1 if it's AI controlled.
var owning_player_id := -1
## The id of this character in level registry.
var registry_id: int
## The current control rotation of the character.
var control_pitch: float = 0.0
## Server side current charge speed.
var current_charge_speed := 0.0
## Whether or not the character is tackled and cannot move.
var is_tackled := false
## The current equipment the character is holding.
var current_equipment: Equipment

func _ready() -> void:
	print("Spawning character owned by ", Steam.getFriendPersonaName(owning_player_id))

## Sets whether or not the camera is currently being used.
func set_current_camera(current: bool) -> void:
	$CameraHandle/PlayerCamera.current = current

## Returns true if this character is locally controlled.
func is_locally_possessed() -> bool:
	return player_controller.current_character == self

func _exit_tree() -> void:
	if is_locally_possessed(): player_controller.unpossess_character()
	level.level_registry.erase(registry_id)

func _physics_process(delta: float):
	# Gravity affects downward velocity.
	if not is_on_floor():
		velocity.y -= level.gravity_acceleration*delta
	else:
		velocity.y = 0
	if network_manager.is_host() or is_locally_possessed():
		if not is_tackled: move_and_slide()
	if network_manager.is_host() and is_locally_possessed():
		pass
		#print(current_charge_speed, "| ", velocity.length(), " m/s")

	# If we're not the host, calculate our charge speed here so if the host leaves we can still keep going.
	if not network_manager.is_host():
		current_charge_speed = self.velocity.length()

# Makes the character move based on player input.
func use_player_input(input: Dictionary, delta: float) -> void:
	if is_tackled: return
	# Movement input.
	var move_input: Vector2 = input.get("mv", Vector2.ZERO)
	var charging: bool = input.get("ch", false)

	var direction := Vector3.ZERO

	if charging:
		# Forward only (Z+ in Godot)
		direction = transform.basis.z

		# Ramp speed up over time
		current_charge_speed = min(
			current_charge_speed + delta * base_charge_acceleration,
			base_charge_speed
		)

		velocity.x = direction.x * -current_charge_speed
		velocity.z = direction.z * -current_charge_speed
	else:
		# Reset charge when not charging
		current_charge_speed = walk_speed

		if not move_input.is_zero_approx():
			direction = (
				transform.basis.x * move_input.x +
				transform.basis.z * move_input.y
			).normalized()

		velocity.x = direction.x * walk_speed
		velocity.z = direction.z * walk_speed
	
	# If colliding a character, charge into them.
	if network_manager.is_host():
		for i in range(get_slide_collision_count()):
			var collision := get_slide_collision(i)
			var collider := collision.get_collider()
			
			if charging and collider is Character:
				on_charge_collide(collider, collision)
	
		
	# Look input.
	var look_input: Vector2 = input.get("lk", Vector2.ZERO)
		
	if not look_input.is_zero_approx():
		# Yaw (left/right)
		self.rotation.y -= look_input.x * 0.002
		
		# Pitch (up/down)
		if use_pitch_rotation:
			self.rotation.x = clamp(
				self.rotation.x - look_input.y * 0.002,
				-deg_to_rad(89.0),
				deg_to_rad(89.0)
			)
		else:
			control_pitch = clamp(
				control_pitch - look_input.y * 0.002,
				-deg_to_rad(89.0),
				deg_to_rad(89.0)
			)

## Converts character information to a dictionary that can be loaded by players joining the game. Used for time-specific parts like held item, etc. Position isn't exactly needed as it's updated each physics process.
func to_init_dict() -> Dictionary:
	var character_data: Dictionary
	
	character_data["owner_id"] = owning_player_id
	
	return character_data

## Loads character variables based on the given dictionary.
func from_init_dict(data: Dictionary) -> void:
	owning_player_id = data["owner_id"]

## Converts ongoing character values that need to be updated to players from host constantly, like position and such.
func to_reg_dict() -> Dictionary:
	var character_reg_data: Dictionary
	character_reg_data["p"] = position # Position
	character_reg_data["r"] = rotation # Rotation
	character_reg_data["v"] = velocity # Velocity
	character_reg_data["cp"] = control_pitch
	
	return character_reg_data

## Loads character registry info from dict.
func from_reg_dict(data: Dictionary) -> void:
	var new_pos: Vector3 = data["p"]
	var new_rot: Vector3 = data["r"]
	var new_vel: Vector3 = data["v"]
	var new_con_pitch: float = data["cp"]
	
	if not is_locally_possessed():
		## The percentage to lerp from local position to updated position
		const NONLOCAL_LERP_FACTOR: float = 0.4
		position = position.lerp(new_pos, NONLOCAL_LERP_FACTOR)
		rotation = rotation.lerp(new_rot, NONLOCAL_LERP_FACTOR)
		velocity = new_vel
		control_pitch = new_con_pitch
	else:
		## Lerp factor for local character.
		const LOCAL_LERP_FACTOR: float = 0.2
		## Minimum difference in position before the serverside position must take over.
		const MIN_POS_DIFF: float = 1.2
		## Same as above but for rotation.
		const MIN_ROT_DIFF: float = 1.0
		## The lerp factor in which client side smoothes to server side.
		
		var pos_diff := position.distance_to(new_pos)
		var rot_diff := rotation.distance_to(new_rot)
		var cp_diff := absf(control_pitch - new_con_pitch)
		
		# Update position if need be.
		if pos_diff > MIN_POS_DIFF:
			position = position.lerp(new_pos, LOCAL_LERP_FACTOR)
		# Update rotation if need be.
		if rot_diff > MIN_ROT_DIFF:
			rotation = rotation.lerp(new_rot, LOCAL_LERP_FACTOR)
		if cp_diff > MIN_ROT_DIFF:
			control_pitch = lerp(control_pitch, new_con_pitch, LOCAL_LERP_FACTOR)
		velocity = new_vel

## Called when self collides with another character.
func on_charge_collide(collider: Character, _collision: KinematicCollision3D):
	if not collider.is_tackled:
		print(Steam.getFriendPersonaName(owning_player_id), " has charged into ", Steam.getFriendPersonaName(collider.owning_player_id))
		var hit_direction := (collider.global_position-global_position).normalized() # The direction from self to collider.
		
		var self_velocity := velocity.dot(hit_direction)
		var collider_velocity := collider.velocity.dot(-hit_direction)
		
		if self_velocity > collider_velocity and self_velocity > MINIMUM_TACKLE_SPEED:
			print("Colliding with ", self_velocity, "+", collider_velocity)
			current_charge_speed = (current_charge_speed - 8.0) if current_charge_speed > 8.0 else 0.0
			collider.tackle(self, self_velocity + collider_velocity)

## Called when self is tackled by another node.
func tackle(tackler: Node3D, tackle_force: float) -> void:
	if not is_tackled:
		is_tackled = true
		$CollisionShape3D.disabled = true
		print(Steam.getFriendPersonaName(owning_player_id), " has been tackled by ", Steam.getFriendPersonaName(tackler.owning_player_id), " with a force of ", tackle_force)
		if network_manager.is_host():
			# Send packet
			network_manager.send_p2p_packet(0, {"m": network_manager.MSG_CHARACTER_TACKLED, "id": registry_id, "tid": tackler.registry_id, "tf": tackle_force})
			# Reset movement.
			velocity.x = 0
			velocity.z = 0
			current_charge_speed = 0
			# Shake camera.
			if is_locally_possessed():
				$CameraHandle.tackle_shake(tackle_force)
			await get_tree().create_timer(4).timeout
			recover()
			

## Called when self recovers from being tackled.
func recover() -> void:
	if is_tackled:
		is_tackled = false
		$CollisionShape3D.disabled = false
		print(Steam.getFriendPersonaName(owning_player_id), " has recovered from being tackled.")
		if network_manager.is_host():
			network_manager.send_p2p_packet(0, {"m": network_manager.MSG_CHARACTER_RECOVERED, "id": registry_id})
			

## Adds an item to the character's inventory.
func pickup_item(item_state: ItemState):
	print("Player has picked up ", item_state.item_resource.item_name)
	var new_index: int = $InventoryComponent.add_item(item_state)
	
	if not current_equipment:
		equip_item(new_index)

## Drops an item from the inventory into the game space.
func drop_item(index: int):
	level.spawn_pickup($InventoryComponent.get_item_at(index), self.position + Vector3.UP)
	$InventoryComponent.remove_item(index)
	if index == $InventoryComponent.equipment_index:
		unequip_item()

## Drops the equipped item.
func drop_equipped_item() -> void:
	drop_item($InventoryComponent.equipment_index)

## Equips the current item at the given inventory index.
func equip_item(index: int):
	# Unequip item if one is currently held.
	if current_equipment: unequip_item()
	var equipment = $InventoryComponent.get_item_at(index).item_resource.get_equipment_resource().instantiate()
	
	add_child(equipment)
	current_equipment = equipment
	
	$InventoryComponent.equipment_index = index

## Unequips the currently equipped item if it exists.
func unequip_item():
	if not current_equipment:
		pass
	
	if $InventoryComponent.get_equipped_item().item_resource.equip_lock:
		drop_equipped_item()
	else:
		current_equipment.queue_free()
		current_equipment = null
		$InventoryComponent.equipment_index = -1
