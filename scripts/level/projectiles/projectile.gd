extends RigidBody3D

class_name Projectile

@onready var network_manager: NetworkManager = get_tree().current_scene.get_node("NetworkManager")
@onready var level: Level = get_tree().current_scene.get_node("Level")

## Whether or not to despawn when overlapping with a character.
@export var despawn_on_overlap: bool
## Whether or not to despawn on colliding with a surface.
@export var despawn_on_collide: bool

## When true, projectile will face the direction of it's velocity.
@export var javelin_throw: bool = false
## The forward vector of the javelin, the vector that faces towards velocity.
@export var javelin_forward: Vector3 = Vector3.FORWARD

## Whether or not we are currently in javelin throw.
var is_javelin = false

## Minimum momentum needed for projectile to cause a tackle.
const MIN_TACKLE_SCORE: float = 3.0

## Spawned item mesh.
var projectile_mesh: Node3D

## Item state
var item_state: ItemState = null
## Registry id
var registry_id: int
## Player id of the thrower.
var thrower_id: int = -1
## The character who threw the item.
var throwing_character: Character

## The time in which the projectile was first thrown.
var start_time: float

## If true, item is currently beign picked up.
var being_picked_up: bool = false

## Returns the team state of allegiance team.
func get_allegiance_team() -> TeamState:
	var match_state: MatchState = level.match_state
	return match_state.get_team_state(item_state.current_allegiance)

func _ready() -> void:
	# Set collide sound to item's basic sound.
	$CollideAudioPlayer.stream = item_state.item_resource.get_collision_sound()
	
	# Spawn item mesh, take the item mesh's collision shape and copy it to our own, disabling the original
	var item_mesh: Node3D = item_state.item_resource.mesh_file.instantiate()
	add_child(item_mesh)
	projectile_mesh = item_mesh
	for child in projectile_mesh.get_child(0).get_children():
		if child is StaticBody3D:
			var mesh_shape: CollisionShape3D = child.get_child(0)
			if $CollisionShape3D.shape is BoxShape3D:
				$CollisionShape3D.shape = mesh_shape.shape
				$Area3D/CollisionShape3D.shape = mesh_shape.shape
				$CollisionShape3D.set_deferred("disabled", false)
				$Area3D/CollisionShape3D.set_deferred("disabled", false)
			else:
				var new_shape := CollisionShape3D.new()
				new_shape.shape = mesh_shape.shape
				self.add_child(new_shape)
			mesh_shape.set_deferred("disabled", true)
	
	var mesh_instance = projectile_mesh.get_child(0)
	for i in mesh_instance.get_surface_override_material_count():
		var current_mat = mesh_instance.get_active_material(i)
		if current_mat:
			mesh_instance.set_surface_override_material(i, current_mat.duplicate())
	
	mass = item_state.get_item_mass()
	
	start_time = Time.get_ticks_msec()
	
	if level.level_registry.has(thrower_id):
		throwing_character = level.level_registry[thrower_id]
	
	# Set gravity scale to coincide with the level.
	gravity_scale = level.gravity_acceleration / 9.8
	
	print("Spawned projectile ", registry_id, " (", item_state.item_resource.item_name , ")")
	
	# If this is a javelin item, start as a javelin throw.
	if javelin_throw and throwing_character: 
		is_javelin = true
		angular_velocity = Vector3.ZERO
	
	$Area3D.body_entered.connect(_on_area_body_entered)
	body_entered.connect(_on_body_entered)


func _physics_process(_delta: float) -> void:
	if is_javelin and linear_velocity.length_squared() > 0.0001:
		var dir = linear_velocity.normalized()
		var up = Vector3.UP
		
		if abs(dir.dot(up)) > 0.99:
			up = Vector3.FORWARD
		
		var target = global_position + dir
		look_at(target, up)
		rotate_object_local(Vector3.LEFT, PI/2)
	
	# If out of bounds, kill or respawn.
	if network_manager.is_host():
		if not level.is_in_bounds(position):
			if item_state.item_resource.is_essential:
				var new_scene := load(scene_file_path)
				var init_dict := to_init_dict()
				level.spawn_projectile(new_scene, level.default_item_spawn, init_dict)
			despawn_projectile()


func _on_body_entered(body: Node3D) -> void:
	surface_collide(body)

func get_momentum() -> Vector3:
	return linear_velocity * item_state.get_item_mass()

func _on_area_body_entered(body: Node3D) -> void:
	if Time.get_ticks_msec() - start_time <= 100 and body == throwing_character: return
	if body is Character:
		character_overlap(body)

## Returns the tackle score of this projectile towards the given character.
func get_tackle_score(target: Character) -> float:
	if linear_velocity.length() <= 1.0: return 0.0
	var relative_velocity = self.linear_velocity - target.velocity
	var vel_normal = (target.position - self.position).normalized()
	
	var impact_speed = max(relative_velocity.dot(vel_normal), 0.0)
	
	var impulse = item_state.get_item_mass() * impact_speed * impact_speed * 0.14
	
	return impulse - target.get_tackle_resistance()

func character_overlap(character: Character):
	print("Score: ", get_tackle_score(character))
	var tackle_score = get_tackle_score(character)
	if tackle_score >= MIN_TACKLE_SCORE: 
		if network_manager.is_host(): character.tackle(self, tackle_score)
	else:
		var direction = (character.position - global_position).normalized()
		linear_velocity = linear_velocity.bounce(direction)
		play_surface_collide_sound()
	
	
	print(item_state.item_resource.item_name, " has collided with player ", character.owning_player_id)
	
	if network_manager.is_host():
		if despawn_on_overlap:
			despawn_projectile()


func play_surface_collide_sound() -> void:
	# Play a sound on collision
	var linear_vol: float = linear_velocity.length()/25.0
	$CollideAudioPlayer.volume_linear = clampf(linear_vol, 0.0, 1.0)
	$CollideAudioPlayer.pitch_scale = randf_range(0.9,1.1)
	$CollideAudioPlayer.play()

func surface_collide(_body: Node3D) -> void:
	#print(item_state.item_resource.item_name, " projectile has overlapped with ", body.name)
	is_javelin = false
	play_surface_collide_sound()
	if network_manager.is_host():
		if despawn_on_collide:
			despawn_projectile()

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
	if not item_state:
		item_state = ItemState.new()
		item_state.from_dict(data["item_state"])
	if data.has("thrower_id"):
		thrower_id = data["thrower_id"]

## Converts ongoing character values that need to be updated to players from host constantly, like position and such.
func to_reg_dict() -> Dictionary:
	var projectile_reg_data: Dictionary
	projectile_reg_data["p"] = position # Position
	projectile_reg_data["r"] = rotation # Rotation
	projectile_reg_data["lv"] = linear_velocity # Velocity
	projectile_reg_data["av"] = angular_velocity
	return projectile_reg_data

## Loads character registry info from dict.
func from_reg_dict(data: Dictionary) -> void:
	var new_pos: Vector3 = data["p"]
	var new_rot: Vector3 = data["r"]
	var new_vel: Vector3 = data["lv"]
	angular_velocity = data["av"]
	const PROJECTILE_LERP_FACTOR: float = 0.6
	
	position = position.lerp(new_pos, PROJECTILE_LERP_FACTOR)
	rotation = rotation.lerp(new_rot, PROJECTILE_LERP_FACTOR)
	linear_velocity = new_vel

## Called when interacted with.
func interact(interactor: Character) -> void:
	if being_picked_up: return
	being_picked_up = true
	if interactor.is_inventory_full(): interactor.drop_equipped_item()
	await get_tree().process_frame
	interactor.velocity += ((linear_velocity * item_state.get_item_mass()) / (item_state.get_item_mass() + interactor.get_total_mass()))
	level.despawn_registry_object(registry_id)
	interactor.pickup_item(item_state)

## Text to display to an interacting player.
func get_interact_text() -> String:
	return("Pickup " + item_state.item_resource.item_name)
