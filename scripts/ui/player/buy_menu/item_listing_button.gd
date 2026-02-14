## Script for an item listing box, a button that shows item details.

extends Button

## The item resource represented by this button.
@export var item_resource: ItemResource

func _ready() -> void:
	text = item_resource.item_name
