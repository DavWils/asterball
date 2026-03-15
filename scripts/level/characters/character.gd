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
## The mass of the character.
@export var character_mass: float

## Signal called when aiming starts.
signal aim_start
## Signal called when aiming ends.
signal aim_end
## Signal called when throwing starts.
signal throw_start
## Signal called when throwing ends.
signal throw_end
## Signal called when tackled.
signal tackled
## Signal called when recovered.
signal recovered
## Signal called when killed.
signal killed(char: Character)
## Signal called when queue_freed.
signal freed(char: Character)
## Signal called when equipping an item.
signal equipped

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
## The ragdoll of this character.
var ragdoll: Ragdoll
## Whether or not this character is alive and in the game.
var is_alive: bool = true

## Amount of friction force to apply to the ragdoll if it's sliding.
const RAGDOLL_FRICTION_MULTIPLIER: float = 0.9


func _ready() -> void:
	if network_manager.is_in_lobby(): print("Spawned character ", registry_id, " owned by ", owning_player_id)
	# Spawn ragdoll hidden from game.
	ragdoll = load("res://scenes/level/characters/" + scene_file_path.get_file().get_basename() + "/ragdoll.tscn").instantiate()
	ragdoll.character = self
	level.add_child(ragdoll)

## Sets whether or not the camera is currently being used.
func set_current_camera(current: bool) -> void:
	$CameraHandle/PlayerCamera.current = current

## Returns true if this character is locally controlled.
func is_locally_possessed() -> bool:
	if player_controller:
		if player_controller.current_character:
			return player_controller.current_character == self and network_manager.player_id == owning_player_id
	return false

func _exit_tree() -> void:
	if is_locally_possessed(): player_controller.unpossess_character()
	level.level_registry.erase(registry_id)
	freed.emit(self)
	
	# Remove ragdoll.
	ragdoll.queue_free()
	

func _physics_process(delta: float):
	# Increase in downward velocity due to gravity.
	if not is_on_floor():
		velocity.y -= level.gravity_acceleration*delta
	if network_manager.is_host():
		if not is_on_floor():
			pass
			#velocity.y -= level.gravity_acceleration*delta
		else:
			# Also, if tackled, apply friction
			if is_tackled():
				velocity.x -= velocity.x * RAGDOLL_FRICTION_MULTIPLIER * delta
				velocity.z -= velocity.z * RAGDOLL_FRICTION_MULTIPLIER * delta
		
	previous_velocity = velocity
	
	if not is_tackled(): move_and_slide()
	
	# Kill character if out of bounds.
	if network_manager.is_host():
		if not level.is_in_bounds(position):
			kill()


# Makes the character move based on player input.
func use_player_input(input: Dictionary) -> void:
	# Movement input.
	var move_input: Vector2
	var charging: bool
	if is_unlocked():
		move_input = input.get("mv", Vector2.ZERO)
		charging = input.get("ch", false) and (not is_aiming()) and move_input.y < 0
	else:
		move_input = Vector2.ZERO
		charging = false
		
	movement_component.movement_input = move_input
	movement_component.charging_input = charging
		
	
	# Look input.
	if is_camera_unlocked():
		var look_input: Vector2 = input.get("lk", Vector2.ZERO)
		
		
		self.rotation.y = look_input.y
		var rot_x = clampf(look_input.x, -deg_to_rad(89.0), deg_to_rad(89.0))
		if use_pitch_rotation:
			self.rotation.x = rot_x
		else:
			control_pitch = rot_x

## Returns true if player can move camera.
func is_camera_unlocked() -> bool:
	return not is_tackled()

## Converts character information to a dictionary that can be loaded by players joining the game. Used for time-specific parts like held item, etc. Position isn't exactly needed as it's updated each physics process.
func to_init_dict() -> Dictionary:
	var character_data: Dictionary
	
	character_data["owner_id"] = owning_player_id
	character_data["inventory"] = $InventoryComponent.to_dict()
	character_data["equipped_key"] = equipped_key
	
	# If aiming/throwing, check here.
	character_data["is_aiming"] = is_aiming()
	character_data["is_throwing"] = is_throwing()
	
	character_data["is_tackled"] = is_tackled()
	if is_tackled():
		character_data["t_c"] = tackle_component.recovery_code
		character_data["t_p"] = tackle_component.recovery_progress
	
	return character_data

## Loads character variables based on the given dictionary.
func from_init_dict(data: Dictionary) -> void:
	owning_player_id = data.get("owner_id", -1)
	if data.has("inventory"):
		$InventoryComponent.from_dict(data["inventory"])
	
	# Wait until ready to actually equip. 
	if not is_node_ready(): await ready
	if not network_manager.is_network_ready(): await network_manager.game_info_retrieved
	
	equip_item(data.get("equipped_key", -1), true)
	
	if data.get("is_aiming", false): 
		start_aim()
		if data["is_throwing"]:
			start_throwing()

	if data.get("is_tackled", false):
		tackle(self, 0.0, RandomNumberGenerator.new())
		tackle_component.recovery_code = data["t_c"]
		tackle_component.recovery_progress = data["t_p"]

## Converts ongoing character values that need to be updated to players from host constantly, like position and such.
func to_reg_dict() -> Dictionary:
	var character_reg_data: Dictionary
	if is_tackled():
		character_reg_data["t"] = true
		character_reg_data["rag"] = ragdoll.to_reg_dict()
		return character_reg_data
	else:
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
	if is_tackled() and data.has("t"):
		ragdoll.from_reg_dict(data["rag"])
		return
	elif is_tackled() != data.has("t"): return
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
		rotation.x = lerp_angle(rotation.x, new_rot.x, NONLOCAL_LERP_FACTOR)
		rotation.y = lerp_angle(rotation.y, new_rot.y, NONLOCAL_LERP_FACTOR)
		rotation.z = lerp_angle(rotation.z, new_rot.z, NONLOCAL_LERP_FACTOR)
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
	# Stop aiming.
	if network_manager.is_host():
		end_aim()
	tackle_component.tackle(tackler, tackle_force, tackle_seed)
	tackled.emit()
	# Shake camera
	if is_locally_possessed():
		$CameraHandle.camera_shake(3*log(tackle_force))
	# Spawn ragdoll and hide self.
	visible = false
	$CollisionShape3D.set_deferred("disabled", true)
	velocity = Vector3.ZERO
	
	if tackler:
		var hit_direction := (position-tackler.position).normalized()
		var ragdoll_velocity = velocity + (hit_direction * tackle_force) + (Vector3.UP * tackle_force * 0.4)
		ragdoll.start_ragdoll(ragdoll_velocity)
	else:
		ragdoll.start_ragdoll(Vector3.UP*5.0)

## Called when self recovers from a tackle.
func recover() -> void:
	visible = true
	if network_manager.is_host():
		position = ragdoll.get_ragdoll_position()
		velocity = ragdoll.get_ragdoll_velocity()
	$CollisionShape3D.set_deferred("disabled", false)
	ragdoll.stop_ragdoll()
	
	tackle_component.recover()
	recovered.emit()

## Adds an item to the character's inventory with validation.
func pickup_item(item_state: ItemState):
	var new_item_state = item_state
	if item_state.item_resource.allegiance_on_pickup:
		item_state.current_allegiance = get_player_team_id()
	var new_key = inventory_component.add_item(new_item_state)
	if item_state.item_resource.passive_effect:
		add_effect(EffectState.new(item_state.item_resource.passive_effect))
	if equipped_key == -1 or item_state.item_resource.equip_lock:
		equip_item(new_key)

## Drops the equipped item with validation.
func drop_equipped_item(automatic: bool = false, thrown: bool = false) -> Projectile:
	return drop_item(equipped_key, automatic, thrown)

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
func drop_item(key: int, automatic: bool = false, thrown: bool = false):
	if inventory_component.get_item_state(key) != null:
		var pickup_item_state: ItemState = inventory_component.get_item_state(key)
		# First remove passive effect if possible.
		if pickup_item_state.item_resource.passive_effect:
			if pickup_item_state.item_resource.passive_effect.infinite_duration:
				remove_effect(pickup_item_state.item_resource.passive_effect)
		
		# Construct dictionary.
		var pickup_dict: Dictionary
		pickup_dict["item_state"] = pickup_item_state.to_dict()
		if thrown: pickup_dict["thrower_id"] = registry_id
		
		var pickup: RigidBody3D = level.spawn_projectile(inventory_component.get_item_state(key).item_resource.get_projectile_scene(), get_throw_start(), pickup_dict)
		pickup.linear_velocity = (get_look_forward_vector() * 3) + velocity
		
		
		if key == equipped_key:
			stop_throwing()
			if not automatic:
				equip_item(-1, true)
		inventory_component.remove_item(key)
		
		return pickup

## Unequips current item if existing and equips the current item at the given inventory key. Use -1 as key to unequip.
func equip_item(key: int, automatic: bool = false):
	if key == equipped_key or is_aiming(): return
	
	# Unequip old equipment.
	if current_equipment:
		print("Unequipping item at key ", equipped_key)
		current_equipment.queue_free()
		
		# If this is an equip locked item, drop it.
		if network_manager.is_host():
			if not automatic and inventory_component.get_item_state(equipped_key).item_resource.equip_lock:
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
		equipped.emit()
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
	if is_aiming(): aim_start.emit()

## Ends aiming.
func end_aim() -> void:
	throw_component.end_aim()
	if not is_aiming(): aim_end.emit()

func start_throwing() -> void:
	throw_component.start_throwing()
	if is_throwing(): throw_start.emit()

func stop_throwing() -> void:
	throw_component.stop_throwing()
	if not is_throwing(): throw_end.emit()
	if not is_aiming(): aim_end.emit()

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

## Returns character total mass.
func get_total_mass() -> float:
	return get_carry_mass() + character_mass

## Returns the character's momentum as a vector.
func get_momentum() -> Vector3:
	return previous_velocity * (get_total_mass())


func add_effect(effect: EffectState) -> void:
	print("Adding effect ", effect.effect_resource.effect_name, " to ", owning_player_id)
	effects_component.add_effect(effect)

func remove_effect(effect: EffectResource) -> void:
	print("Removing effect ", effect.effect_name, " from ", owning_player_id)
	effects_component.remove_effect(effect)

func has_effect(effect: EffectResource) -> bool:
	return effects_component.has_effect(effect)

func is_inventory_full() -> bool:
	return inventory_component.get_all_items().size() >= inventory_component.get_inventory_capacity()

## Function called when character is locally possessed.
func possess() -> void:
	pass

## Function called when character is locally unpossessed.
func unpossess() -> void:
	pass

## Returns self's velocity if not tackled. Otherwise, returns regdoll's velocity.
func get_body_velocity() -> Vector3:
	if is_tackled():
		return ragdoll.get_ragdoll_velocity()
	else:
		return velocity

## Kills this character, making them irrelevant to the game.
func kill() -> void:
	if not is_alive: return
	if is_locally_possessed(): 
		player_controller.position = $CameraHandle/PlayerCamera.global_position
		player_controller.rotation = $CameraHandle.global_rotation
		player_controller.unpossess_character()
	visible = false
	set_deferred("disabled", true)
	if is_tackled():
		recover()
	if is_aiming():
		end_aim()
	ragdoll.start_ragdoll(velocity)
	is_alive = false
	level.level_registry.erase(registry_id)
	if network_manager.is_host():
		network_manager.send_p2p_packet(0, {"m": network_manager.Message.CHARACTER_KILL, "char_id": registry_id})
	if is_locally_possessed():
		player_controller.unpossess_character()
	killed.emit(self)

func can_possess() -> bool:
	if player_controller:
		if player_controller.current_character:
			return is_alive
	return false

func get_tackle_resistance() -> float:
	return tackle_component.get_tackle_resistance()
