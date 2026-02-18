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

func _ready() -> void:
	print(item_resource.item_name, " has been equipped by ", Steam.getFriendPersonaName(wielder.owning_player_id))

func _exit_tree() -> void:
	print(item_resource.item_name, " has been unequipped by ", Steam.getFriendPersonaName(wielder.owning_player_id))

func get_item_state():
	return wielder.get_equipped_item()

## Starts the equipment's use function, simulating a user press
func use_start() -> void:
	pass

## Finish the equipment use function if exists, simulating user release.
func use_finish() -> void:
	pass
