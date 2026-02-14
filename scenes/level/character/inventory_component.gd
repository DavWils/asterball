extends Node

class_name InventoryComponent

## Maximum inventory size
const DEFAULT_MAX_SIZE := 5

## Owning character
@onready var character: Character = self.get_parent()

## Array of inventory items
var inventory_items: Array[ItemState] = []

## The inventory index of the currently equipped item.
var equipment_index: int = -1 

## Maximum inventory size (can be modified per character)
var max_size: int = DEFAULT_MAX_SIZE

func _ready() -> void:
	# Defer equipment to next frame to ensure character is ready
	if equipment_index >= 0:
		call_deferred("_deferred_equip")

func _deferred_equip():
	if character and equipment_index >= 0:
		character.equip_item(equipment_index)

func set_equipment_index(value: int):
	equipment_index = value
	if character and character.network_manager and character.network_manager.is_host():
		# Log state change for debugging
		pass

## Check if inventory is full
func is_full() -> bool:
	return inventory_items.size() >= max_size

## Adds an item to the inventory. Returns new index or -1 if failed.
func add_item(item_state: ItemState) -> int:
	if not item_state:
		print("Attempted to add null item to inventory")
		return -1
		
	if is_full():
		print("Inventory full, cannot add item")
		return -1
	
	# Validate item state has required data
	if not item_state.item_resource:
		print("Item state has no resource")
		return -1
	
	inventory_items.append(item_state)
	var new_index = inventory_items.size() - 1
	print("Added ", item_state.item_resource.item_name, " to index ", new_index)
	
	if character and character.network_manager and character.network_manager.is_host():
		character.network_manager.send_p2p_packet(0, {
			"m": character.network_manager.Message.CHARACTER_ADDITEM, 
			"id": character.registry_id, 
			"item_state": item_state.to_dict(),
			"index": new_index
		})
	return new_index

## Removes an item from the inventory with validation.
func remove_item(index: int) -> bool:
	if index < 0 or index >= inventory_items.size():
		print("Attempted to remove invalid index: ", index)
		return false
	
	var removed_item = inventory_items[index]
	print("Removed ", removed_item.item_resource.item_name if removed_item.item_resource else "Unknown", " from index ", index)
	
	# Remove the item
	inventory_items.remove_at(index)
	
	# Update equipment index
	if equipment_index == index:
		equipment_index = -1
		if character and character.current_equipment:
			character.unequip_item(false)
	elif equipment_index > index:
		equipment_index -= 1
	
	# Replicate to network
	if character and character.network_manager and character.network_manager.is_host():
		character.network_manager.send_p2p_packet(0, {
			"m": character.network_manager.Message.CHARACTER_REMOVEITEM, 
			"id": character.registry_id, 
			"index": index
		})
	
	print("New equipment index is ", equipment_index, " after removal.")
	return true

## Returns item state at a given index with validation.
func get_item_at(index: int) -> ItemState:
	if index < 0 or index >= inventory_items.size():
		return null
	return inventory_items[index]

## Returns the currently equipped item state.
func get_equipped_item() -> ItemState:
	return get_item_at(equipment_index)

## Clears the entire inventory (useful for game reset)
func clear_inventory() -> void:
	inventory_items.clear()
	if equipment_index >= 0:
		equipment_index = -1
		if character and character.current_equipment:
			character.unequip_item(false)

## Sets inventory values from dictionary with validation.
func from_dict(data: Dictionary) -> void:
	# Clear existing inventory
	clear_inventory()
	
	# Load items from dictionary
	if data.has("items") and data["items"] is Array:
		for item_data in data["items"]:
			if item_data is Dictionary:
				var item_state = ItemState.new()
				item_state.from_dict(item_data)
				if item_state.item_resource:  # Only add if valid
					inventory_items.append(item_state)
				else:
					print("Warning: Invalid item data skipped")
	
	# Set equipment index
	if data.has("index"):
		equipment_index = data["index"]
		# Validate equipment index
		if equipment_index >= inventory_items.size():
			equipment_index = -1

## Converts inventory to dictionary with validation.
func to_dict() -> Dictionary:
	var data: Dictionary = {}
	
	# Items converted to dictionaries
	data["items"] = []
	for item in inventory_items:
		if item and item.item_resource:
			data["items"].append(item.to_dict())
	
	data["index"] = equipment_index if equipment_index < inventory_items.size() else -1
	data["max_size"] = max_size
	return data
