extends CharacterBody3D

class_name Character

@onready var network_manager: NetworkManager = get_tree().current_scene.get_node("NetworkManager")
@onready var player_controller: PlayerController = get_tree().current_scene.get_node("Level").get_node("PlayerController")
@onready var level: Level = get_tree().current_scene.get_node("Level")
@onready var inventory_component: InventoryComponent = $InventoryComponent

## Animation player if we one.
@onready var animation_player: AnimationPlayer = $CharacterMesh.get_node_or_null("AnimationPlayer")
## Animation tree if we have a mesh.
@onready var animation_tree: AnimationTree = $CharacterMesh.get_node_or_null("AnimationTree")

## The minimum speed a character must be going to tackle another.
const MINIMUM_TACKLE_SPEED := 5.0
## The max percentage of throw force that is too small to actually throw.
const MINIMUM_THROW_FORCE := 0.05

## The non charging speed of this character. (m/s)
@export var walk_speed := 1
## The maximum base charging speed of the character, not including any buffs.
@export var base_charge_speed := 24.0
## The base acceleration of the character when charging.(m/2^2)
@export var base_charge_acceleration := 2
## Whether or not this character can rotate on the x axis as opposed to being applied to control rotation.
@export var use_pitch_rotation: bool = false
## The base carry capacity of the character.
@export var base_inventory_capacity: int = 3
## The base maximum throw force the character can throw items with.
@export var base_max_throw_force: float = 60.0
## The amount of throw force to be accumulated in a second.
@export var base_throw_speed: float = 5.0

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
## The key of the currently equipped inventory item. -1 if nothing equipped.
var equipped_key: int = -1
## Whether or not character is currently aiming.
var is_aiming := false
## Whether or not the character is currently charging a throw.
var is_throwing := false
## The current amount of force charged to throw.
var throw_force := 0.0


func _ready() -> void:
	print("Spawning character owned by ", Steam.getFriendPersonaName(owning_player_id))

## Sets whether or not the camera is currently being used.
func set_current_camera(current: bool) -> void:
	$CameraHandle/PlayerCamera.current = current

## Returns true if this character is locally controlled.
func is_locally_possessed() -> bool:
	if player_controller:
		if player_controller.current_character:
			return player_controller.current_character == self
	return false

func _exit_tree() -> void:
	if is_locally_possessed(): player_controller.unpossess_character()
	level.level_registry.erase(registry_id)

func _physics_process(delta: float):
	# If throwing, accumulate force.
	if is_throwing:
		print("T: ", throw_force)
		throw_force += clampf(get_throw_speed() * delta, 0, get_max_throw_force())
	
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
	
	if animation_player:
		update_animation()

func update_animation():
	if is_tackled: return
	
	if not is_on_floor():
		animation_tree.set("parameters/MovementTransition/transition_request", "Fall")
	else:
		var horizontal_velocity: Vector3 = velocity * (Vector3(1,0,1))
		if horizontal_velocity.length() < 0.1:
			animation_tree.set("parameters/MovementTransition/transition_request", "Idle")
		else:
			# Running, calculate direction and run.
			var local_velocity = transform.basis.inverse() * horizontal_velocity
			var dir = Vector2(local_velocity.x, -local_velocity.z)
			dir = dir.normalized()
			var current_dir: Vector2 = animation_tree.get("parameters/RunBlendSpace2D/blend_position")
			animation_tree.set("parameters/RunBlendSpace2D/blend_position", current_dir.lerp(dir, 0.25))
			animation_tree.set("parameters/MovementTransition/transition_request", "Run")
			
			# Set speed scale. When running faster, animation plays faster.
			var speed_scale: float
			if horizontal_velocity.length() > walk_speed:
				speed_scale = horizontal_velocity.length()/walk_speed
			else:
				speed_scale = 1.0
			animation_tree.set("parameters/RunTimeScale/scale", speed_scale)
		
		# Rotate spine based on control pitch.
		var skeleton: Skeleton3D = $CharacterMesh/Armature/Skeleton3D
		skeleton.clear_bones_global_pose_override()
		var spine_idx: int = skeleton.find_bone("spine")
		var spine_pose: Transform3D = skeleton.get_bone_global_pose(spine_idx)
		var spine_basis: Basis = spine_pose.basis
		var spine_euler: Vector3 = spine_basis.get_euler()
		
		var current_velocity = absf(velocity.length() - walk_speed) if velocity.length()>0.1 else 0.0
		var added_pitch = clampf(control_pitch - clampf(current_velocity/10, 0, 0.8), -PI/2, PI/2)
		
		spine_euler.x += added_pitch
		spine_basis = Basis.from_euler(spine_euler)
		spine_pose.basis = spine_basis
		
		skeleton.set_bone_global_pose_override(spine_idx, spine_pose, 1.0, true)

func get_max_charge_speed() -> float:
	return base_charge_speed

func get_charge_acceleration() -> float:
	return base_charge_acceleration


# Makes the character move based on player input.
func use_player_input(input: Dictionary, delta: float) -> void:
	if is_tackled: return
	# Movement input.
	if can_move():
		var move_input: Vector2 = input.get("mv", Vector2.ZERO)
		var charging: bool = input.get("ch", false) and (not is_aiming)
		
		var direction := Vector3.ZERO
		
		if charging and move_input.y < 0:
			# Forward only (Z+ in Godot)
			direction = transform.basis.z

			# Ramp speed up over time
			current_charge_speed = min(
				current_charge_speed + delta * get_charge_acceleration(),
				get_max_charge_speed()
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
	else:
		if is_on_floor(): # Slide to a stop if cant move.
			velocity = velocity.lerp(Vector3.ZERO, 0.2)
	
	# Look input.
	var look_input: Vector2 = input.get("lk", Vector2.ZERO)
		
	self.rotation.y = look_input.y
	var rot_x = clampf(look_input.x, -deg_to_rad(89.0), deg_to_rad(89.0))
	if use_pitch_rotation:
		self.rotation.x = rot_x
	else:
		control_pitch = rot_x

## Converts character information to a dictionary that can be loaded by players joining the game. Used for time-specific parts like held item, etc. Position isn't exactly needed as it's updated each physics process.
func to_init_dict() -> Dictionary:
	var character_data: Dictionary
	
	character_data["owner_id"] = owning_player_id
	character_data["inventory"] = $InventoryComponent.to_dict()
	character_data["equipped_key"] = equipped_key
	
	return character_data

## Loads character variables based on the given dictionary.
func from_init_dict(data: Dictionary) -> void:
	owning_player_id = data["owner_id"]
	$InventoryComponent.from_dict(data["inventory"])
	equip_item(data["equipped_key"], true)

## Converts ongoing character values that need to be updated to players from host constantly, like position and such.
func to_reg_dict() -> Dictionary:
	var character_reg_data: Dictionary
	character_reg_data["p"] = position # Position
	character_reg_data["r"] = rotation # Rotation
	character_reg_data["v"] = velocity # Velocity
	character_reg_data["cp"] = control_pitch
	character_reg_data["tf"] = throw_force
	
	return character_reg_data

## Loads character registry info from dict.
func from_reg_dict(data: Dictionary) -> void:
	var new_pos: Vector3 = data["p"]
	var new_rot: Vector3 = data["r"]
	var new_vel: Vector3 = data["v"]
	var new_con_pitch: float = data["cp"]
	throw_force = data["tf"]
	#print("Client ROT: ", self.rotation, "   |   SERVER ROT: ", new_rot, "   |   DIFF: ", self.rotation-new_rot)
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
		const MIN_ROT_DIFF: float = PI
		## The lerp factor in which client side smoothes to server side.
		
		var pos_diff := position.distance_to(new_pos)
		#var rot_diff := rotation.distance_to(new_rot)
		var rot_diff := absf(wrapf(rotation.y - new_rot.y, -PI, PI))
		var cp_diff := absf(control_pitch - new_con_pitch)
		
		# Update position if need be.
		if pos_diff > MIN_POS_DIFF:
			position = position.lerp(new_pos, LOCAL_LERP_FACTOR)
		# Update rotation if need be.
		if rot_diff > MIN_ROT_DIFF:
			#rotation = rotation.lerp(new_rot, LOCAL_LERP_FACTOR)
			rotation.y = lerp_angle(rotation.y, new_rot.y, LOCAL_LERP_FACTOR)
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
		# Shake camera.
		if is_locally_possessed():
			$CameraHandle.tackle_shake(tackle_force)
		if network_manager.is_host():
			# Send packet
			network_manager.send_p2p_packet(0, {"m": network_manager.Message.CHARACTER_TACKLED, "id": registry_id, "tid": tackler.registry_id, "tf": tackle_force})
			# Drop all items.
			while $InventoryComponent.get_item_at(0):
				drop_item(0)
			
			# Reset movement.
			velocity.x = 0
			velocity.z = 0
			current_charge_speed = 0
			await get_tree().create_timer(4).timeout
			recover()
			

## Called when self recovers from being tackled.
func recover() -> void:
	if is_tackled:
		is_tackled = false
		$CollisionShape3D.disabled = false
		print(Steam.getFriendPersonaName(owning_player_id), " has recovered from being tackled.")
		if network_manager.is_host():
			network_manager.send_p2p_packet(0, {"m": network_manager.Message.CHARACTER_RECOVERED, "id": registry_id})
			

## Returns character carry capacity.
func get_inventory_capacity() -> int:
	return base_inventory_capacity

## Adds an item to the character's inventory with validation.
func pickup_item(item_state: ItemState):
	var new_key = inventory_component.add_item(item_state)
	if equipped_key == -1 or item_state.item_resource.equip_lock:
		equip_item(new_key)

## Drops the equipped item with validation.
func drop_equipped_item() -> void:
	drop_item(equipped_key)

## Returns forward vector taking into account control pitch
func get_look_forward_vector() -> Vector3:
	var look_basis: Basis
	
	if use_pitch_rotation:
		# Character actually rotates on X, so just use full transform
		look_basis = global_transform.basis
	else:
		# Build a basis using yaw + control_pitch
		var yaw_basis = Basis(Vector3.UP, rotation.y)
		var pitch_basis = Basis(Vector3.RIGHT, control_pitch)
		look_basis = yaw_basis * pitch_basis
	
	var direction = -look_basis.z.normalized()
	return direction


## Drops an item from the inventory with validation. Automatic flag means item was dropped automatically (i.e. equip locked item was unequipped).
func drop_item(key: int, automatic: bool = false):
	if inventory_component.get_item_state(key) != null:
		var pickup: RigidBody3D = level.spawn_pickup(inventory_component.get_item_state(key), self.position+Vector3.UP*1.5)
		pickup.linear_velocity = (get_look_forward_vector() * 3) + velocity
		
		
		
		if key == equipped_key and not automatic:
			equip_item(-1, true)
		inventory_component.remove_item(key)

## Unequips current item if existing and equips the current item at the given inventory key. Use -1 as key to unequip.
func equip_item(key: int, automatic: bool = false):
	if key == equipped_key: return
	
	# Unequip old equipment.
	if current_equipment:
		print("Unequipping item at key ", equipped_key)
		current_equipment.queue_free()
		
		# If this is an equip locked item, drop it.
		if network_manager.is_host():
			if  not automatic and inventory_component.get_item_state(equipped_key).item_resource.equip_lock:
				drop_item(equipped_key, true)
	
	# Set new equipped value.
	print("Equipping item at key ", key)
	equipped_key = key
	
	# If there's an item at this key load it's equipment.
	var new_item_state: ItemState = inventory_component.get_item_state(key)
	if new_item_state:
		current_equipment = new_item_state.item_resource.get_equipment_scene().instantiate()
		add_child(current_equipment)
	
	if network_manager.is_host():
		network_manager.send_p2p_packet(0, {"m": network_manager.Message.CHARACTER_EQUIP, "char_id": registry_id, "key": key})

## Returns number of items held.
func get_inventory_count() -> int:
	return inventory_component.inventory_items.keys().size()

## Returns item state of the equipped item.
func get_equipped_item() -> ItemState:
	return inventory_component.get_item_state(equipped_key)

## Returns the character owner's team.
func get_player_team_id() -> int:
	var match_state = level.match_state as MatchState
	return match_state.player_states[owning_player_id].team_id

## Returns the character owner's team state.
func get_player_team_state() -> TeamState:
	var match_state = level.match_state as MatchState
	return match_state.team_states[get_player_team_id()]

## Returns true if character can move.
func can_move() -> bool:
	# Check state of match to see if its one we can move in..
	var state_of_match = level.match_state.state_of_match
	var state_enum = level.match_state.StateOfMatch
	var is_movable_state_of_match: bool = (state_of_match == state_enum.MATCH or state_of_match == state_enum.CELEBRATION)
	return is_movable_state_of_match and (not is_tackled) and (not (is_locally_possessed() and player_controller.paused))



## Starts aiming with the given item.
func start_aim() -> void:
	if current_equipment:
		print("Starting aim.")
		is_aiming = true

## Ends aiming.
func end_aim() -> void:
	if is_aiming:
		print("Stopping aim.")
		is_aiming = false
		if is_throwing:
			throw_force = 0.0
			stop_throwing()

func start_throwing() -> void:
	if not is_throwing and is_aiming:
		print("Charging throw.")
		throw_force = 0.0
		is_throwing = true
		
		

func stop_throwing() -> void:
	if is_throwing:
		is_throwing = false
		end_aim()
		
		# If enough throw force, throw the item.
		if throw_force > get_max_throw_force() * MINIMUM_THROW_FORCE:
			print("Throwing with ", throw_force, " force.")
			var projectile: RigidBody3D
			# Spawn a projectile, if a projectile scene exists spawn it, otherwise spawn pickup.
			var projectile_item_state: ItemState = current_equipment.get_item_state()
			var projectile_scene: PackedScene = projectile_item_state.item_resource.get_projectile_scene()
			var projectile_spawn_pos: Vector3 = self.position+Vector3.UP*1.5
			if projectile_scene:
				projectile = projectile_scene.instantiate()
				projectile.position = projectile_spawn_pos
				add_child(projectile)
			else:
				projectile = level.spawn_pickup(projectile_item_state, projectile_spawn_pos)
			# Set item's velocity.
			projectile.linear_velocity = get_look_forward_vector() * (throw_force/projectile_item_state.item_resource.item_mass)
			
			# Lastly, unequip the item and remove it from the inventory.
			inventory_component.remove_item(equipped_key)
			equip_item(-1, true)
		else:
			print("Not throwing.")
			


func get_throw_speed() -> float:
	return base_throw_speed

func get_max_throw_force() -> float:
	return base_max_throw_force
