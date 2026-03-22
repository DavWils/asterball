extends Node3D

class_name WarpgatePortal

@onready var network_manager: NetworkManager = get_tree().current_scene.get_node("NetworkManager")


## The portal that an object walking in here teleports to.
@export var linked_portal: WarpgatePortal

func _ready() -> void:
	$Area3D.area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area3D) -> void:
	if area.get_parent():
		var parent_node: Node3D = area.get_parent()
		print("Portal: ", parent_node)
		if network_manager.is_host():
			parent_node.position = linked_portal.position + (3*-linked_portal.global_transform.basis.z)
