extends Control

var current_code: Array[int]

@onready var key_textures: Dictionary[int, Texture2D] = {
	0: load("res://textures/ui/player/tackle_overlay/tackle_key_up.png"),
	1: load("res://textures/ui/player/tackle_overlay/tackle_key_left.png"),
	2: load("res://textures/ui/player/tackle_overlay/tackle_key_down.png"),
	3: load("res://textures/ui/player/tackle_overlay/tackle_key_right.png"),
}

func set_recovery_code(code: Array[int]) -> void:
	current_code = code

func set_recovery_progress(progress: int) -> void:
	for i in range(0,8):
		var current_child: TextureRect = $KeyBox.get_child(i)
		var current_index: int = i+progress
		if current_index >= 0 and current_index < current_code.size():
			current_child.texture = key_textures[current_code[current_index]]
			if i == 0:
				current_child.modulate = Color(1,1,1,0.5)
			elif i == 1:
				current_child.modulate = Color(0.87, 0.696, 0.0, 1.0)
			else:
				current_child.modulate = Color(1,1,1,0.5)
		else:
			current_child.texture = null
			current_child.modulate = Color.TRANSPARENT
