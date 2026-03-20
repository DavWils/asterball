## Script for inventory overlay.

extends Control

@onready var level: Level = get_tree().current_scene.get_node("Level")
@onready var player_controller: PlayerController = level.get_node("PlayerController")
@onready var match_state: MatchState = level.get_node("MatchState")

@onready var card_resource := load("res://scenes/ui/player/inventory_overlay/inventory_item_card.tscn")

@export var item_box: HBoxContainer

func _ready() -> void:
	player_controller.possessed.connect(_on_possessed)
	player_controller.unpossessed.connect(_on_unpossessed)

func _on_possessed(character: Character) -> void:
	character.inventory_component.inventory_changed.connect(_on_inventory_changed)
	character.equipped.connect(_on_equipped)
	_on_inventory_changed()
	visible = true

func _on_unpossessed(_character: Character) -> void:
	visible = false

func _on_inventory_changed() -> void:
	var anchor_dist = min(0.8, float(player_controller.current_character.get_inventory_count())/20)
	#$Panel.anchor_left = 0.5 - (anchor_dist/2)
	#$Panel.anchor_right = 0.5 + (anchor_dist/2)
	var anchor_tween := create_tween()
	anchor_tween.tween_property($Panel, "anchor_left", 0.5 - (anchor_dist/2), 0.2)
	anchor_tween.parallel().tween_property($Panel, "anchor_right", 0.5 + (anchor_dist/2), 0.2)
	
	var current_keys: Array[int] = []
	for child in item_box.get_children():
		if player_controller.current_character.inventory_component.inventory_items.has(child.inventory_key):
			current_keys.append(child.inventory_key)
		else:
			child.queue_free()
	
	for key in player_controller.current_character.inventory_component.inventory_items.keys():
		if not current_keys.has(key):
			var new_card = card_resource.instantiate()
			new_card.inventory_key = key
			item_box.add_child(new_card)

func _on_equipped(key: int) -> void:
	for child in item_box.get_children():
		child.set_equip_status(child.inventory_key == key)
