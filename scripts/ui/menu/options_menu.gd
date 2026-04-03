extends Control

@export var player_ui: PlayerUI
@export var main_menu_ui: MainMenuUI
@onready var main_scene: MainScene = get_tree().current_scene

@onready var volume_slider_box := $AudioPanel/ScrollContainer/MarginContainer/VolumeSliderContainer

@onready var controls_box := $ControlsPanel/ScrollContainer/MarginContainer/ControlsBox

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$VBoxContainer/ApplyButton.pressed.connect(_on_apply_pressed)
	$VBoxContainer/ReturnButton.pressed.connect(_on_return_pressed)
	
	# Load the volume slider box.
	var slider_ui := load("res://scenes/ui/menu/options_menu/volume_slider.tscn")
	for bus in AudioServer.bus_count:
		var current_slider: Control = slider_ui.instantiate()
		current_slider.idx = bus
		volume_slider_box.add_child(current_slider)
		
	# Load the controls box
	for map in InputMap.get_actions():
		var input_name := map
		if input_name.substr(0, 3) == "ui_": continue
		# Capitalize first letter.
		input_name = input_name.substr(0, 1).capitalize() + input_name.substr(1)
		# Replace underscore with space and capitalize subsequent letters.
		for i in range(0, input_name.length()):
			var current_char = input_name.substr(i, 1)
			if current_char == "_":
				var next_char = input_name.substr(i+1, 1)
				input_name = input_name.substr(0, i) + " " + next_char.capitalize() + input_name.substr(i+2)
		print(input_name)
		var input_map := InputMap.action_get_events(map)[0]
		if input_map is InputEventKey:
			print(input_map.as_text_physical_keycode())
		else:
			print(input_map.as_text())

func _on_apply_pressed() -> void:
	var save_dict: Dictionary = {}
	
	# Save audio settings
	save_dict["audio"] = {}
	for bus in AudioServer.bus_count:
		print("Options UI saving bus ", bus)
		var linear_vol: float = volume_slider_box.get_child(bus).get_linear_vol()
		save_dict["audio"][str(bus)] = linear_vol
	
	# Display settings.
	save_dict["display"] = {}
	save_dict["display"]["camera_shake"] = $DisplayPanel/ScrollContainer/MarginContainer/DisplayOptionsContaienr/CameraShakeBox/MarginContainer/CameraShakeSlider.value
	# Send dict to main.
	main_scene.apply_options(save_dict)


func _on_return_pressed() -> void:
	if player_ui:
		player_ui.pause_menu.return_to_pause_home()
	elif main_menu_ui:
		main_menu_ui.to_title_screen()
