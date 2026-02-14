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
@export var equip_lock: bool = false

## Enum for item tiers.
enum ItemTier {
	ONE,
	TWO,
	THREE,
	FOUR
}

## Returns the loaded equipment scene resource.
func get_equipment_resource() -> PackedScene:
	return load("res://scenes/level/character/equipment/%s.tscn" % resource_path.get_file().get_basename())

## Automatically calculates item tier based on set values.
func get_item_tier() -> ItemTier:
	if item_cost <= 450:
		return ItemTier.ONE
	elif item_cost <= 2500:
		return ItemTier.TWO
	elif item_cost <= 9000:
		return ItemTier.THREE
	else:
		return ItemTier.FOUR
