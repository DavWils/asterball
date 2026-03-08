## A resource type for item state during the game.
extends Resource

class_name ItemState

## Resource of the item represented in this state.
var item_resource: ItemResource
## The current team id that the item acts in respect of. Usually the team of the last to pick it up.
var current_allegiance: int = -1

func from_dict(data: Dictionary) -> void:
	item_resource = load(data["item_resource"])
	current_allegiance = data["current_allegiance"]

func to_dict() -> Dictionary:
	var item_data := {}
	item_data["item_resource"] = item_resource.resource_path
	item_data["current_allegiance"] = current_allegiance
	return item_data

## Returns total mass of the item.
func get_item_mass() -> float:
	return item_resource.item_mass
