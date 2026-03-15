@tool

extends Control

@export var bg_color: Color

var menu_items: Array[ItemResource]

var item_cards: Array[Button]

func load_menu_grid() -> void:
	var item_card_res := load("res://scenes/ui/player/buy_menu/buy_item_card.tscn")
	for item in menu_items:
		var item_card: Control = item_card_res.instantiate()
		item_card.item_resource = item
		$ScrollContainer/MarginContainer/GridContainer.add_child(item_card)
		item_cards.append(item_card)

func set_can_buy(can_buy: bool) -> void:
	for card in item_cards:
		card.disabled = not can_buy

func _ready() -> void:
	$ColorRect.color = bg_color
