extends Node

class_name InventoryComponent

## Array of inventory items
var inventory_items: Array[ItemState]

## The inventory index of the currently equipped item.
var equipment_index: int

func _ready() -> void:
	pass

## Adds an item to the inventory. Returns new index.
func add_item(item_state: ItemState):
	inventory_items.append(item_state)
	return inventory_items.size()-1

## Removes an item from the inventory.
func remove_item(index: int):
	inventory_items.remove_at(index)

## Returns item state at a given index.
func get_item_at(index: int) -> ItemState:
	return inventory_items[index]

func get_equipped_item() -> ItemState:
	return get_item_at(equipment_index)
