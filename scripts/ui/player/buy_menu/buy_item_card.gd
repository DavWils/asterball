extends Button

@export var item_resource: ItemResource

## Reference to network manager.
@onready var network_manager: NetworkManager = get_tree().current_scene.get_node("NetworkManager")
## Reference to match director.
@onready var match_director: MatchDirector = get_tree().current_scene.get_node("Level").get_node("MatchDirector")
## Reference to player controller.
@onready var player_controller: PlayerController = get_tree().current_scene.get_node("Level").get_node("PlayerController")
## Buy menu UI.
@onready var buy_menu: Control = get_tree().current_scene.get_node("Level").get_node("PlayerUI").get_node("BuyMenu")
## Audio player for buttons.
@onready var button_audio_player: AudioStreamPlayer = get_tree().current_scene.get_node("UIAudioPlayer")

var fail_tween: Tween

func _ready() -> void:
	$VBoxContainer/NameLabel.text = item_resource.item_name
	pressed.connect(_on_pressed)
	if item_resource.item_icon:
		$VBoxContainer/TextureRect.texture = item_resource.item_icon
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered() -> void:
	if not disabled:
		buy_menu.get_node("ClickAudioPlayer").play()
		buy_menu.set_hovered_item(item_resource)

func _on_mouse_exited() -> void:
	if not disabled:
		if buy_menu.hovered_item == item_resource:
			buy_menu.set_hovered_item(null)

func _on_pressed() -> void:
	if match_director.can_player_afford(network_manager.player_id, item_resource.item_cost):
		button_audio_player.play_purchased()
	else:
		button_audio_player.play_fail_purchased()
		$VBoxContainer/TextureRect.modulate = Color.RED
		$VBoxContainer/NameLabel.add_theme_color_override("font_color", Color.RED)
		if fail_tween:
			fail_tween.kill()
		fail_tween = create_tween()
		fail_tween.tween_property($VBoxContainer/TextureRect, "modulate", Color.WHITE, 0.5)
		fail_tween.parallel().tween_method(
		func(c): $VBoxContainer/NameLabel.add_theme_color_override("font_color", c),
		Color.RED,
		Color.WHITE,
		0.5
		)
	
	if network_manager.is_host():
		match_director.purchase_item(player_controller.current_character, item_resource)
	else:
		network_manager.send_p2p_packet(network_manager.get_host_id(), {"m": network_manager.Message.CLIENT_PURCHASE_ITEM, "char_id": player_controller.current_character.registry_id, "item_path": item_resource.resource_path})
