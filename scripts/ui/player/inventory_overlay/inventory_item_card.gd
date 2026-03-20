extends Control

@onready var level: Level = get_tree().current_scene.get_node("Level")
@onready var player_controller: PlayerController = level.get_node("PlayerController")


## The inventory key represented by this card.
var inventory_key: int

func _ready() -> void:
	if player_controller.current_character:
		set_equip_status(player_controller.current_character.equipped_key == inventory_key)

func set_equip_status(equipped: bool) -> void:
	if equipped:
		modulate = Color.WHITE
	else:
		modulate = Color.GRAY
