extends Node3D

class_name Equipment

## The character holding the item.
var wielder: Character
#@onready var wielder: Character = self.get_parent().get_parent().get_parent().get_parent()
## Reference to the item resource of this item.
@onready var item_resource: ItemResource = get_item_state().item_resource
## Reference to level
@onready var level = get_tree().current_scene.get_node("Level")
## Refernce to network manager.
@onready var network_manager = get_tree().current_scene.get_node("NetworkManager")
## Whether or not to lock in this primary
@export var use_lock: bool = false
## The camera offset while in use.
@export var lock_camera_offsets: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]
## Whether or not currently in use.
var is_locked: bool = false
## Mesh of the equipment.
var equipment_mesh: Node3D
## Lock animation
@export var lock_animation: StringName

func _ready() -> void:
	# Spawn the item mesh and disable it's collision
	var item_mesh: Node3D = item_resource.mesh_file.instantiate()
	add_child(item_mesh)
	equipment_mesh = item_mesh
	for child in equipment_mesh.get_child(0).get_children():
		if child is StaticBody3D:
			child.find_child("CollisionShape3D").disabled = true
	
	var mesh_instance = equipment_mesh.get_child(0)
	for i in mesh_instance.get_surface_override_material_count():
		var current_mat = mesh_instance.get_active_material(i)
		if current_mat:
			mesh_instance.set_surface_override_material(i, current_mat.duplicate())
	
	print(item_resource.item_name, " has been equipped by ", wielder.owning_player_id)

func _exit_tree() -> void:
	print(item_resource.item_name, " has been unequipped by ", wielder.owning_player_id)

func get_item_state():
	return wielder.get_equipped_item()

## Starts the equipment's use function, simulating a user press
func use_start() -> void:
	is_locked = true

## Finish the equipment use function if exists, simulating user release.
func use_finish() -> void:
	is_locked = false

## Returns the team state of allegiance team.
func get_allegiance_team() -> TeamState:
	var match_state: MatchState = level.match_state
	return match_state.get_team_state(get_item_state().current_allegiance)
