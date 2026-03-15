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

## Mesh of the equipment.
var equipment_mesh: Node3D

func _ready() -> void:
	# Spawn the item mesh and disable it's collision
	var item_mesh: Node3D = item_resource.mesh_file.instantiate()
	add_child(item_mesh)
	equipment_mesh = item_mesh
	var mesh_shape: CollisionShape3D = item_mesh.find_child("CollisionShape3D")
	mesh_shape.disabled = true
	
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
	pass

## Finish the equipment use function if exists, simulating user release.
func use_finish() -> void:
	pass

## Returns the team state of allegiance team.
func get_allegiance_team() -> TeamState:
	var match_state: MatchState = level.match_state
	return match_state.get_team_state(get_item_state().current_allegiance)
