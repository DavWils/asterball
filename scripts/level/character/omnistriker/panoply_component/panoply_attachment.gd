## Child scene of the panoply which represents where items go.

@tool

extends BoneAttachment3D

class_name PanoplyAttachment

@onready var offset_node: Node3D = $OffsetNode

## Type of attachment to go here.
@export var attachment_type: AttachmentSlotType



enum AttachmentSlotType {
	HEAD,
	CHEST,
	BACK,
	HIP,
}


## Offset from self transform to put the attachment. Works in tool script.
@export var offset_position: Vector3:
	set(value):
		offset_position = value
		if Engine.is_editor_hint():
			offset_node.position = value

## Rotational offset.
@export var offset_rotation: Vector3:
	set(value):
		offset_rotation = value
		if Engine.is_editor_hint():
			offset_node.rotation = value

func _ready() -> void:
	$OffsetNode.position = offset_position
	$OffsetNode.rotation = offset_rotation

func set_item(item: ItemState) -> void:
	# Remove old item mesh.
	for child in offset_node.get_children():
		child.queue_free()
	
	if item:
		var item_mesh = item.item_resource.mesh_file.instantiate()
		item_mesh.position = item.item_resource.panoply_pos_offset
		for child in item_mesh.get_child(0).get_children():
			if child is StaticBody3D:
				(child.get_child(0) as CollisionShape3D).disabled = true
		offset_node.add_child(item_mesh)
