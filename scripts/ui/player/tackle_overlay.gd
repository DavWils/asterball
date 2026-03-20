extends Control

var current_code: Array[int]

## UI player.
@onready var audio_player: AudioStreamPlayer = get_tree().current_scene.get_node("UIAudioPlayer")

## Initial x position used for tweening.
@onready var initial_keybox_pos: Vector2 = $KeyBox.position
## The distance to move the widget's position per progress.
const MOVE_DIST: float = 68.0
## Time for the move tween.
const MOVE_TIME: float = 0.2
## TIme for the vignette effect.
const VIGNETTE_TIME: float = 0.2

var move_tween: Tween


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
	if move_tween:
		move_tween.kill()
	move_tween = create_tween()
	$KeyBox.position.x = initial_keybox_pos.x + (progress_distance * MOVE_DIST)
	move_tween.tween_property($KeyBox, "position", initial_keybox_pos, 0.1)
	# Show visual indicator based on progress shift.
	if progress_distance > 0:
		# Good progress, good indicator.
		audio_player.pitch_scale = 1.0 + (float(progress) / float(current_code.size()))
		audio_player.play_recovery_pass()
		$KeyBox/TextureRect.modulate = Color.GREEN
		move_tween.parallel().tween_property($KeyBox/TextureRect, "modulate", Color(0,0,0,0), MOVE_TIME)
		$VignetteRect.color = Color.GREEN
		move_tween.parallel().tween_property($VignetteRect, "color", Color(0,1,0,0), VIGNETTE_TIME)
	elif progress_distance == 0:
		# No Progress
		audio_player.play_recovery_fail()
		$VignetteRect.color = Color.GREEN
		move_tween.parallel().tween_property($VignetteRect, "color", Color(0,1,0,0), VIGNETTE_TIME)
	else:
		# Bad progress, bad indicator.
		audio_player.play_recovery_fail()
		# Then modulate on the previous node.
		$KeyBox/TextureRect3.modulate = Color.RED
		move_tween.parallel().tween_property($KeyBox/TextureRect3, "modulate", Color(1,1,1,0.5), MOVE_TIME)
		$VignetteRect.color = Color.RED
		move_tween.parallel().tween_property($VignetteRect, "color", Color(1,0,0,0), VIGNETTE_TIME)
