## A resource type for item state during the game.
extends Resource

class_name ItemState

var item_resource: ItemResource

func from_dict(data: Dictionary) -> void:
	item_resource = load(data["item_resource"])

func to_dict() -> Dictionary:
	var item_data := {}
	item_data["item_resource"] = item_resource.resource_path
	
	return item_data

## Returns total mass of the item.
func get_item_mass() -> float:
	return item_resource.item_mass
