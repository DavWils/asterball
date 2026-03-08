extends Resource

class_name ItemResource

## The name of the item.
@export var item_name: String
## The point value of this item.
@export var item_cost: int = 0
## The file of the mesh.
@export var mesh_file: PackedScene
## Whether or not this item can be bought in the store.
@export var can_purchase: bool = item_cost>0
## Whether or not the character can hold this item in innventory without equippint it.
@export var equip_lock: bool = false
## Mass of the item, higher mass being harder to throw and more heavy on the players.
@export var item_mass: float = 1.0
## Whether or not the item is essential, meaning it cannot be destroyed/killed.
@export var is_essential: bool = false
## Whether or not this item should change its allegiance when picked up.
@export var allegiance_on_pickup: bool = true

## Enum for item tiers.
enum ItemTier {
	ONE,
	TWO,
	THREE,
	FOUR
}

## Returns the loaded equipment scene resource if one exists, otherwise returning the basic equipment scene.
func get_equipment_scene() -> PackedScene:
	var filepath: String = "res://scenes/level/character/equipment/%s.tscn" % resource_path.get_file().get_basename()
	if FileAccess.file_exists(filepath):
		return load(filepath)
	else:
		return load("res://scenes/level/character/baseequipment.tscn")

## Returns projectile scene if one exists. If not, a pickup should be used instead.
func get_projectile_scene() -> PackedScene:
	var filepath: String = "res://scenes/level/projectiles/%s.tscn" % resource_path.get_file().get_basename()
	if FileAccess.file_exists(filepath):
		return load(filepath)
	else:
		return load("res://scenes/level/baseprojectile.tscn")

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
