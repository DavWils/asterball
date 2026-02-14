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

## Whether or not we can currently buy items. Local value and has nothing to do with host authority.
var can_buy: bool = false
## Array of all item buttons.
var item_buttons: Array[Button]


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
						var item_button = load("res://scenes/ui/player/buy_menu/item_listing_button.tscn").instantiate()
						item_button.item_resource = loaded_resource
						$ScrollContainer/VBoxContainer.get_child(loaded_resource.get_item_tier()).get_node("GridContainer").add_child(item_button)
						item_buttons.append(item_button)
		current_filename = res_dir.get_next()
	
	# Listen to signal of player team being assigned to know which areas to recognize.
	match_state.player_team_assigned.connect(_on_player_team_assigned)

func _on_player_team_assigned(player_id: int, team_id: int):
	if player_id == network_manager.player_id:
		for child in level.get_children():
			if child is BuyZone:
				if child.owning_team == team_id:
					print("Found a buy zone: ", child)
					child.area_entered.connect(_on_area_entered)
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
func set_can_buy(condition: bool) -> void:
	can_buy = condition
	for item_button in item_buttons:
		item_button.disabled = not can_buy

## Returns true if the parent of the area given is the locally possessed character.
func is_area_possessed_character(area: Area3D):
	var overlapper: Node3D = area.get_parent()
	if overlapper is Character:
		if overlapper.is_locally_possessed():
			return true
	return false
