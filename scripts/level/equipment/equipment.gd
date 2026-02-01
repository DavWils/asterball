extends Node3D

class_name Equipment

## The character holding the item.
@onready var wielder: Character = self.get_parent()
## Reference to the item resource of this item.
@onready var item_resource: ItemResource = get_item_state().item_resource

func _ready() -> void:
	print(item_resource.item_name, " has been equipped by ", Steam.getFriendPersonaName(wielder.owning_player_id))
	

func _exit_tree() -> void:
	print(item_resource.item_name, " has been unequipped by ", Steam.getFriendPersonaName(wielder.owning_player_id))

func get_item_state():
	var wielder_inventory = wielder.get_node("InventoryComponent")
	return wielder_inventory.get_equipped_item()
