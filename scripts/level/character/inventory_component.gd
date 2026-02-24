extends Node

class_name InventoryComponent

## Owning character
@onready var character: Character = self.get_parent()
## Reference to network manager.
@onready var network_manager: NetworkManager = get_tree().current_scene.get_node("NetworkManager")

## Items in the inventory with their corresponding slot
var inventory_items: Dictionary[int, ItemState] = {}



## Adds an item to the inventory at given key. Returns key it was added to.
func add_item(item: ItemState, key: int = get_next_key(0, false) if inventory_items.has(0) else 0) -> int:
	inventory_items[key] = item
	if network_manager.is_host():
		network_manager.send_p2p_packet(0, {"m": network_manager.Message.CHARACTER_ADDITEM, "char_id": character.registry_id, "key": key, "item_state": item.to_dict()})
	return key

## Removes an item from inventory at the given key.
func remove_item(key: int) -> void:
	inventory_items.erase(key)
	if network_manager.is_host():
		network_manager.send_p2p_packet(0, {"m": network_manager.Message.CHARACTER_REMOVEITEM, "char_id": character.registry_id, "key": key})

## Gets the previous inventory slot from given key if one exists. If with is true, looks for slot WITH an item. Otherwise, look for empty.
func get_prev_key(start: int = character.equipped_key if character.equipped_key >= 0 else 0, with: bool = true) -> int:
	var capacity: int = character.get_inventory_capacity()
	for i in range(capacity-1, -1, -1):
		var prev_key: int = (start-i+capacity)%capacity
		if with == inventory_items.has(prev_key):
			print("prev > ", prev_key)
			return prev_key
	print("prev > ", start)
	return start

## Gets the next inventory slot from the given key if one exists. If with is true, looks for slot WITH an item. Otherwise, look for empty.
func get_next_key(start: int = character.equipped_key if character.equipped_key >= 0 else 0, with: bool = true) -> int:
	var capacity: int = character.get_inventory_capacity()
	for i in range(1, capacity):
		var next_key: int = ((start + i) % capacity + capacity) % capacity
		if with == inventory_items.has(next_key):
			print("next > ", next_key)
			return next_key
	print("next > ", start)
	return start

## Returns item state of the inventory item at given key.
func get_item_state(key: int) -> ItemState:
	if inventory_items.has(key):
		return inventory_items[key]
	else:
		return null

## Sets inventory values from dictionary with validation.
func from_dict(data: Dictionary) -> void:
	for key in data.keys():
		var current_item := ItemState.new()
		current_item.from_dict(data[key])
		inventory_items[key] = current_item

## Converts inventory to dictionary with validation.
func to_dict() -> Dictionary:
	var data: Dictionary = {}
	for key in inventory_items.keys():
		data[key] = inventory_items[key].to_dict()
	return data

## Returns an array of all inventory items
func get_all_items() -> Array:
	var item_array: Array
	for item_key in inventory_items.keys():
		item_array.append(inventory_items[item_key])
	
	return item_array
