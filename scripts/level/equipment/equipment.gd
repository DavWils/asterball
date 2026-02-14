extends Node3D

class_name Equipment

## The character holding the item.
@onready var wielder: Character = self.get_parent()
## Reference to the item resource of this item.
@onready var item_resource: ItemResource = get_item_state().item_resource.resource_path
## Reference to level
@onready var level = get_tree().current_scene.get_node("Level")
## Refernce to network manager.
@onready var network_manager = get_tree().current_scene.get_node("NetworkManager")

func _ready() -> void:
	print(item_resource.item_name, " has been equipped by ", Steam.getFriendPersonaName(wielder.owning_player_id))

func _process(_delta):
	print("Equipment says I am ", item_resource.item_name)

func _exit_tree() -> void:
	print(item_resource.item_name, " has been unequipped by ", Steam.getFriendPersonaName(wielder.owning_player_id))

func get_item_state():
	var wielder_inventory = wielder.get_node("InventoryComponent")
	return wielder_inventory.get_equipped_item()
