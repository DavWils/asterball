extends Control

var current_code: Array[int]

## Initial x position used for tweening.
@onready var initial_keybox_pos: Vector2 = $KeyBox.position
## The distance to move the widget's position per progress.
const MOVE_DIST: float = 68.0

var last_progress: int = -1

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
			
	var progress_distance = progress - last_progress
	last_progress = progress
	var move_tween := create_tween()
	$KeyBox.position.x = initial_keybox_pos.x + (progress_distance * MOVE_DIST)
	move_tween.tween_property($KeyBox, "position", initial_keybox_pos, 0.1)
