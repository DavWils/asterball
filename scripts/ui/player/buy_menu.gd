## Script for player buy menu.

extends Control

## Reference to level
@onready var level: Level = get_tree().current_scene.get_node("Level")
## Reference to match state.
@onready var match_state: MatchState = level.get_node("MatchState")
## Reference to network manager.
@onready var network_manager: NetworkManager = get_tree().current_scene.get_node("NetworkManager")
## Refernce to player controller
@onready var player_controller: PlayerController = level.get_node("PlayerController")

var buy_item_cards: Array[Button]

@onready var inv_card_resource := load("res://scenes/ui/player/inventory_overlay/inventory_item_card.tscn")


var hovered_item: ItemResource = null
var hover_mesh: Node3D = null

func _ready() -> void:
	# Iterate over all items and add them to menu.
	var res_dir = DirAccess.open("res://resources/items/")
	res_dir.list_dir_begin()
	
	var current_filename := res_dir.get_next()
	
	while current_filename != "":
		if not res_dir.current_is_dir():
			if current_filename.ends_with(".tres"):
				var loaded_resource = load("res://resources/items/"+current_filename)
				if loaded_resource is ItemResource:
					if loaded_resource.can_purchase:
						$MenuTabContainer.get_child(loaded_resource.item_category).menu_items.append(loaded_resource)
		current_filename = res_dir.get_next()
	
	for child in $MenuTabContainer.get_children():
		child.load_menu_grid()
	
	
	# Listen to signal of player team being assigned to know which areas to recognize.
	match_state.player_team_assigned.connect(_on_player_team_assigned)
	network_manager.game_info_retrieved.connect(_on_game_info_retrieved)
	
	player_controller.possessed.connect(_on_possessed)
	
	# Listen to when player state is added so we can be signalled of new point values.
	match_state.player_state_added.connect(_on_player_state_added)
	
	if not level.network_ready: await network_manager.game_info_retrieved
	if match_state.get_player_state(network_manager.player_id): _on_player_state_added(network_manager.player_id)

	

func _on_possessed(character: Character) -> void:
	character.inventory_component.inventory_changed.connect(_on_inventory_changed)
	character.equipped.connect(_on_equipped)

func _on_equipped(key: int) -> void:
	for child in $InventoryPanel/ScrollContainer/VBoxContainer.get_children():
		child.set_equip_status(child.inventory_key == key)

func _on_inventory_changed() -> void:
	for child in $InventoryPanel/ScrollContainer/VBoxContainer.get_children():
		child.queue_free()
	
	for key in player_controller.current_character.inventory_component.inventory_items.keys():
		var new_card = inv_card_resource.instantiate()
		new_card.inventory_key = key
		new_card.custom_minimum_size = Vector2(96.0,96.0)
		$InventoryPanel/ScrollContainer/VBoxContainer.add_child(new_card)

func _on_player_state_added(player_id: int):
	if player_id == network_manager.player_id:
		match_state.get_player_state(network_manager.player_id).scores_changed.connect(_on_scores_changed)

func _on_scores_changed(new_current: int, _new_total: int) -> void:
	$CurrentPointsLabel.text = str(new_current) + " points"

func set_hovered_item(item: ItemResource) -> void:
	hovered_item = item
	if hover_mesh:
		hover_mesh.queue_free()
	if item:
		$SelectedItemDisplay/VBoxContainer/SelectedItemNameLabel.text = item.item_name
		$SelectedItemDisplay/VBoxContainer/HBoxContainer/SelectedItemCostLabel.text = "Cost: " + str(item.item_cost)
		$SelectedItemDisplay/VBoxContainer/HBoxContainer/SelectedItemMassLabel.text = str(item.item_mass) + "kg"
		
		## Add labels for passives.
		for child in $SelectedItemDisplay/VBoxContainer/EffectsContainer.get_children():
			child.queue_free()
		if item.passive_effect:
			var passive: EffectResource = item.passive_effect
			for modifier in passive.modifiers:
				var new_label := Label.new()
				var is_mod_pos: bool = modifier.modifier_value > 0.0
				new_label.text = "%+.2f" % modifier.modifier_value + ("% " if modifier.is_percentage else " ") + modifier.mod_to_string()
				new_label.modulate = Color.GREEN if is_mod_pos else Color.RED
				new_label.add_theme_font_override("font", $SelectedItemDisplay/VBoxContainer/HBoxContainer/SelectedItemCostLabel.get_theme_font("font"))
				$SelectedItemDisplay/VBoxContainer/EffectsContainer.add_child(new_label)
		
		if item.mesh_file:
			hover_mesh = item.mesh_file.instantiate()
			hover_mesh.position = Vector3(0,-5000,-1)
			$SelectedItemDisplay/SubViewportContainer/SubViewport.add_child(hover_mesh)
		$SelectedItemDisplay.visible = true
	else:
		$SelectedItemDisplay.visible = false

func _process(delta: float) -> void:
	# Rotate hover mesh.
	if hover_mesh:
		hover_mesh.rotate(Vector3.UP, delta*2)

func _on_game_info_retrieved() -> void:
	_on_player_team_assigned(network_manager.player_id, match_state.get_player_state(network_manager.player_id).team_id)

func _on_player_team_assigned(player_id: int, team_id: int):
	if player_id == network_manager.player_id:
		for child in level.get_children():
			if child is BuyZone:
				if child.owning_team == team_id:
					print("Found a buy zone: ", child)
					if not child.area_entered.is_connected(_on_area_entered):
						child.area_entered.connect(_on_area_entered)
					if not child.area_exited.is_connected(_on_area_exited):
						child.area_exited.connect(_on_area_exited)
				else:
					if child.area_entered.is_connected(_on_area_entered):
						child.area_entered.disconnect(_on_area_entered)
					if child.area_exited.is_connected(_on_area_exited):
						child.area_exited.disconnect(_on_area_exited)

func _on_area_entered(area):
	if is_area_possessed_character(area):
		set_can_buy(true)

func _on_area_exited(area):
	if is_area_possessed_character(area):
		set_can_buy(false)

## Sets whether or not items can be bought
func set_can_buy(can_buy: bool) -> void:
	for child in $MenuTabContainer.get_children():
		child.set_can_buy(can_buy)

## Returns true if the parent of the area given is the locally possessed character.
func is_area_possessed_character(area: Area3D):
	var overlapper: Node3D = area.get_parent()
	if overlapper is Character:
		if overlapper.is_locally_possessed():
			return true
	return false
