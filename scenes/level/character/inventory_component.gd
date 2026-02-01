extends Node

class_name InventoryComponent

## Owning character
@onready var character: Character = self.get_parent()

## Array of inventory items
var inventory_items: Array[ItemState] = []

## The inventory index of the currently equipped item.
var equipment_index: int = -1

func _ready() -> void:
	if equipment_index >= 0:
		character.equip_item(equipment_index)

## Adds an item to the inventory. Returns new index.
func add_item(item_state: ItemState):
	print("Added ", item_state.item_resource.item_name, " to index ", inventory_items.size())
	inventory_items.append(item_state)
	
	if character.network_manager.is_host():
		character.network_manager.send_p2p_packet(0, {"m": character.network_manager.MSG_CHARACTER_ADDITEM, "id": character.registry_id, "item": item_state})
	return inventory_items.size()-1

## Removes an item from the inventory.
func remove_item(index: int):
	print("Removed ", get_item_at(index).item_resource.item_name, " from index ", index)
	inventory_items.remove_at(index)
	if equipment_index == index:
		equipment_index = -1
	elif equipment_index > index:
		equipment_index -= 1
	if character.network_manager.is_host():
		pass
	if character.network_manager.is_host():
		character.network_manager.send_p2p_packet(0, {"m": character.network_manager.MSG_CHARACTER_ADDITEM, "id": character.registry_id, "index": index})

## Returns item state at a given index.
func get_item_at(index: int) -> ItemState:
	if index >= inventory_items.size() or index < 0: return null
	else: return inventory_items[index]

func get_equipped_item() -> ItemState:
	return get_item_at(equipment_index)

## Sets inventory values from dictionary.
func from_dict(data: Dictionary) -> void:
	inventory_items = data["items"]
	equipment_index = data["index"]
	pass

## Converts inventory to dictionary
func to_dict() -> Dictionary:
	var data: Dictionary = {}
	data["items"] = inventory_items
	data["index"] = equipment_index
	return data
