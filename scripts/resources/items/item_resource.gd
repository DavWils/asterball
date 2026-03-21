extends Resource

class_name ItemResource

## The name of the item.
@export var item_name: String
## The point value of this item.
@export var item_cost: int = 0
## The category of this item.
@export var item_category: ItemCategory
## The texture icon of this item.
@export var item_icon: Texture2D
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
## Passive effect that this item puts on the player.
@export var passive_effect: EffectResource
## The type of attachment for this item on the omnistriker.
@export var attachment_type: PanoplyAttachment.AttachmentSlotType
## The positional offset to apply to this item in a panoply attachment.
@export var panoply_pos_offset: Vector3 = Vector3.ZERO
## The rotational offset to apply to this item in a panoply attachment.
@export var panoply_rot_offset: Vector3 = Vector3.ZERO


## Enum for item tiers.
enum ItemCategory {
	Throwables,
	Weapons,
	Utility,
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
