extends Node3D

class_name ActivePanoplyAttachment

@onready var character = self.get_parent().get_parent().get_parent().character

func _ready() -> void:
	print("Active panoply spawned")
	for child in get_children():
		if child.get_child_count() > 0:
			if child.get_child(0) is MeshInstance3D:
				for sub_child in child.get_child(0).get_children():
					if sub_child is StaticBody3D:
						(sub_child.get_child(0) as CollisionShape3D).disabled = true
