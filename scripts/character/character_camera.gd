extends Node

@onready var character: Character = self.get_parent()

func _process(_delta: float) -> void:
	self.rotation.x = lerp(self.rotation.x, character.control_pitch, .6)
