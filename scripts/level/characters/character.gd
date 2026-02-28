extends CharacterBody3D

class_name Character

@onready var network_manager: NetworkManager = get_tree().current_scene.get_node("NetworkManager")
@onready var player_controller: PlayerController = get_tree().current_scene.get_node("Level").get_node("PlayerController")
@onready var level: Level = get_tree().current_scene.get_node("Level")
@onready var inventory_component: InventoryComponent = $InventoryComponent
@onready var character_mesh: Node3D = $CharacterMesh
@onready var tackle_component: TackleComponent = $TackleComponent
@onready var movement_component: MovementComponent = $MovementComponent
@onready var effects_component: EffectsComponent = $EffectsComponent
@onready var throw_component: ThrowComponent = $ThrowComponent

## The non charging speed of this character. (m/s)
@export var walk_speed := 1
## Whether or not this character can rotate on the x axis as opposed to being applied to control rotation.
@export var use_pitch_rotation: bool = false
## The base carry capacity of the character.
@export var base_inventory_capacity: int = 3

## Signal called when throwing starts.
signal throw_start
## Signal called when throwing ends.
signal throw_end


## The id of the player currently controlling this character. Or -1 if it's AI controlled.
var owning_player_id := -1
## The id of this character in level registry.
var registry_id: int
## The current control rotation of the character.
var control_pitch: float = 0.0
## The current equipment the character is holding.
var current_equipment: Equipment
## The key of the currently equipped inventory item. -1 if nothing equipped.
var equipped_key: int = -1
## The velocity of the character in the previous frame
var previous_velocity: Vector3


func _ready() -> void:
	print("Spawned character ", registry_id, " owned by ", Steam.getFriendPersonaName(owning_player_id))

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
	# Increase in downward velocity due to gravity.
	if network_manager.is_host():
		if not is_on_floor():
			velocity.y -= level.gravity_acceleration*delta
		else:
			velocity.y = 0
	previous_velocity = velocity
	
	if not is_tackled():
		move_and_slide()
	


# Makes the character move based on player input.
func use_player_input(input: Dictionary) -> void:
	# Movement input.
	if is_unlocked():
		var move_input: Vector2 = input.get("mv", Vector2.ZERO)
		var charging: bool = input.get("ch", false) and (not is_aiming())
		
		movement_component.movement_input = move_input
		movement_component.charging_input = charging
		
	
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
	character_reg_data["mv"] = movement_component.to_reg_dict()
	character_reg_data["tc"] = throw_component.to_reg_dict()
	
	return character_reg_data

## Loads character registry info from dict.
func from_reg_dict(data: Dictionary) -> void:
	if not is_node_ready(): return
	var new_pos: Vector3 = data["p"]
	var new_rot: Vector3 = data["r"]
	var new_vel: Vector3 = data["v"]
	var new_con_pitch: float = data["cp"]
	throw_component.from_reg_dict(data["tc"])
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
	# Lastly update movement component
	movement_component.from_reg_dict(data["mv"])

## Called when self is tackled. Reroutes to tacklecomponent
func tackle(tackler: Node3D, tackle_force: float, tackle_seed: RandomNumberGenerator = RandomNumberGenerator.new()):
	tackle_component.tackle(tackler, tackle_force, tackle_seed)
	if is_locally_possessed():
			get_node("CameraHandle").tackle_shake(tackle_force)

## Called when self recovers from a tackle.
func recover() -> void:
	tackle_component.recover()

## Returns character carry capacity.
func get_inventory_capacity() -> int:
	return base_inventory_capacity

## Adds an item to the character's inventory with validation.
func pickup_item(item_state: ItemState):
	var new_key = inventory_component.add_item(item_state)
	if equipped_key == -1 or item_state.item_resource.equip_lock:
		equip_item(new_key)

## Drops the equipped item with validation.
func drop_equipped_item(automatic: bool = false) -> Projectile:
	return drop_item(equipped_key, automatic)

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


## Drops an item from the inventory with validation. Automatic flag means item was dropped automatically (i.e. equip locked item was unequipped). Returns the dropped pickup.
func drop_item(key: int, automatic: bool = false):
	if inventory_component.get_item_state(key) != null:
		var pickup: RigidBody3D = level.spawn_projectile(inventory_component.get_item_state(key), get_throw_start(), self)
		pickup.linear_velocity = (get_look_forward_vector() * 3) + velocity
		
		
		if key == equipped_key and not automatic:
			equip_item(-1, true)
		inventory_component.remove_item(key)
		
		return pickup

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
		current_equipment.wielder = self
		var bone_attachment = character_mesh.equipment_attachment
		bone_attachment.add_child(current_equipment)
	
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

## Returns true if character is not locked (i.e. in preparation or any other stage where they cannot move).
func is_unlocked() -> bool:
	return level.match_director.is_unlocked_state() and (not is_tackled()) and (not (is_locally_possessed() and player_controller.paused))


## Starts aiming with the given item.
func start_aim() -> void:
	throw_component.start_aim()

## Ends aiming.
func end_aim() -> void:
	throw_component.end_aim()

func start_throwing() -> void:
	throw_start.emit()
	throw_component.start_throwing()

func stop_throwing() -> void:
	throw_end.emit()
	throw_component.stop_throwing()

func is_aiming() -> bool:
	return throw_component.is_aiming

## Returns true if character is currently throwing.
func is_throwing() -> bool:
	return throw_component.is_throwing

## Returns starting position of a thrown item.
func get_throw_start() -> Vector3:
	return self.position + Vector3.UP*1.5 + get_look_forward_vector()

## Returns the initial velocity of the thrown item 
func get_throw_velocity() -> Vector3:
	if current_equipment:
		return get_look_forward_vector() * (throw_component.throw_force/current_equipment.get_item_state().item_resource.item_mass) + self.velocity
	else:
		return Vector3.ZERO

## Uses the equipment, simulating a press.
func use_equipment_start() -> void:
	current_equipment.use_start()
	if network_manager.is_host():
		network_manager.send_p2p_packet(0, {"m": network_manager.Message.CHARACTER_USE_START, "char_id": registry_id})

## Use the equipment, simulating a release.
func use_equipment_finish() -> void:
	current_equipment.use_finish()
	if network_manager.is_host():
		network_manager.send_p2p_packet(0, {"m": network_manager.Message.CHARACTER_USE_FINISH, "char_id": registry_id})

## Drops all character items.
func drop_all_items() -> void:
	while $InventoryComponent.get_item_state(0):
		drop_item(0)

## Returns true if tackled.
func is_tackled() -> bool:
	return tackle_component.is_tackled

## Enters recovery key to recover from being tackled.
func enter_recovery_key(key: int) -> void:
	tackle_component.enter_recovery_key(key)

## Returns true if currently charging.
func is_charging() -> bool:
	return movement_component.is_charging

## Returns the combined mass of all carried items.
func get_carry_mass() -> float:
	var total_mass: float = 0.0
	for item in inventory_component.get_all_items():
		total_mass += item.get_item_mass()
	return total_mass


func add_effect(effect: EffectState) -> void:
	print("Adding effect ", effect.effect_resource.effect_name, " to ", Steam.getFriendPersonaName(owning_player_id))
	effects_component.add_effect(effect)

func remove_effect(effect: EffectResource) -> void:
	print("Removing effect ", effect.effect_name, " from ", Steam.getFriendPersonaName(owning_player_id))
	effects_component.remove_effect(effect)

func has_effect(effect: EffectResource) -> bool:
	return effects_component.has_effect(effect)
