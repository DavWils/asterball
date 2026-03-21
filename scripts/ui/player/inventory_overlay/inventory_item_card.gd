extends Control

@onready var level: Level = get_tree().current_scene.get_node("Level")
@onready var player_controller: PlayerController = level.get_node("PlayerController")


## The inventory key represented by this card.
var inventory_key: int = -1

func _ready() -> void:
	if player_controller.current_character:
		set_equip_status(player_controller.current_character.equipped_key == inventory_key)
		var item_resource := player_controller.current_character.inventory_component.get_item_state(inventory_key).item_resource
		if item_resource.item_icon:
			$TextureRect.texture = item_resource.item_icon

func set_equip_status(equipped: bool) -> void:
	if equipped:
		modulate = Color.WHITE
	else:
		modulate = Color.GRAY
