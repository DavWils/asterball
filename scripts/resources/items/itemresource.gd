extends Resource

class_name ItemResource

## The name of the item.
@export var item_name: String
## The point value of this item.
@export var item_cost: int = 0
## The mesh used for this item.
@export var item_mesh: Mesh
## The type of collision shape this item will use as a pickup.
@export var pickup_collision_shape: Shape3D
## Whether or not this item can be bought in the store.
@export var can_purchase: bool = item_cost>0
## Whether or not the character can hold this item in innventory without equippint it.
@export var can_pocket: bool = true

## Returns the loaded equipment scene resource.
func get_equipment_resource() -> PackedScene:
	return load("res://scenes/level/character/equipment/%s.tscn" % resource_path.get_file().get_basename())
