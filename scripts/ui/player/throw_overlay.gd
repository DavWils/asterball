extends Control

@onready var throw_bar: ProgressBar = $ProgressBar

@onready var player_ui: PlayerUI = self.get_parent()

func _process(_delta: float) -> void:
	if player_ui.player_controller.current_character:
		var character: Character = player_ui.player_controller.current_character
		var new_force = character.throw_component.throw_force / character.throw_component.get_max_throw_force()
		throw_bar.value = new_force
