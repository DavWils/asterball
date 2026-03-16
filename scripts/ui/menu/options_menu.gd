extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$VBoxContainer/ApplyButton.pressed.connect(_on_apply_pressed)
	$VBoxContainer/ReturnButton.pressed.connect(_on_return_pressed)

func _on_apply_pressed() -> void:
	pass

func _on_return_pressed() -> void:
	if self.get_parent().get_parent().get_parent() is PlayerUI:
		self.get_parent().current_tab = 0
	else:
		self.get_parent().get_parent().to_title_screen()
