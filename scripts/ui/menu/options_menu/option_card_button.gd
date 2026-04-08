extends Button

var action_name: StringName

var original_string: String

var is_changing := false

func _gui_input(event: InputEvent) -> void:
	if not event.is_pressed(): return
	if not has_focus(): return
	if not is_changing:
		is_changing = true
		return
	# When the button is pressed, accept it and release.
	if event is InputEventKey:
		set_new_text(event.as_text_physical_keycode())
	elif event is InputEventMouseButton:
		set_new_text(event.as_text())
	else:
		return
	accept_event()
	release_focus()
	is_changing = false

func set_new_text(key_text: String = original_string):
	text = key_text
	var new_color: Color
	if text != original_string:
		new_color = Color.GOLD
	else:
		new_color = Color.WHITE
	
	self_modulate = new_color
	
