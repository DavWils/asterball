## Script for an item listing box, a button that shows item details.

extends Button

## The item resource represented by this button.
@export var item_resource: ItemResource

## Reference to network manager.
@onready var network_manager: NetworkManager = get_tree().current_scene.get_node("NetworkManager")
## Reference to match director.
@onready var match_director: MatchDirector = get_tree().current_scene.get_node("Level").get_node("MatchDirector")
## Reference to player controller.
@onready var player_controller: PlayerController = get_tree().current_scene.get_node("Level").get_node("PlayerController")




func _ready() -> void:
	text = item_resource.item_name
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	if network_manager.is_host():
		match_director.purchase_item(player_controller.current_character, item_resource)
	else:
		network_manager.send_p2p_packet(network_manager.get_host_id(), {"m": network_manager.Message.CLIENT_PURCHASE_ITEM, "char_id": player_controller.current_character.registry_id, "item_path": item_resource.resource_path})
