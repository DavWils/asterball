## A script for panoply, shows all the items a character holds.

extends Node3D

class_name Panoply

@onready var character: Omnistriker = self.get_parent().get_parent()

func _ready():
	if Engine.is_editor_hint(): return
	if not self.get_parent().get_parent().is_node_ready(): await self.get_parent().get_parent().ready
	character.equipped.connect(_on_equipped)
	character.inventory_component.inventory_changed.connect(_on_inventory_changed)


func _on_inventory_changed() -> void:
	reload_attachments()

func _on_equipped(_key: int) -> void:
	reload_attachments()

func reload_attachments() -> void:
	var attachments: Array[PanoplyAttachment]
	for child in get_children():
		if child is PanoplyAttachment:
			attachments.append(child)
			child.set_item(null)
	
	for key in character.inventory_component.inventory_items:
		if character.equipped_key == key: continue
		
		# Find a slot for this item.
		for slot in attachments.duplicate():
			if slot.attachment_type == character.inventory_component.inventory_items[key].item_resource.attachment_type:
				slot.set_item(character.inventory_component.inventory_items[key])
				attachments.erase(slot)
				break
