## A small script for the overlap area of a character that copies the character's collision shape to its own overlap shape.
@tool

extends Area3D

func _ready():
	if Engine.is_editor_hint():
		var char_shape = self.get_parent().get_node("CollisionShape3D")
		$CollisionShape3D.shape = char_shape.shape
		self.position = char_shape.position
