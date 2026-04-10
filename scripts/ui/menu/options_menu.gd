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
	load_controls_box()

func load_controls_box() -> void:
	# Load the controls box
	## The ui for each input mapping
	var option_card := load("res://scenes/ui/menu/options_menu/option_card.tscn")
	for child in controls_box.get_children():
		child.queue_free()
	
	for map in InputMap.get_actions():
		var input_name := map
		if input_name.substr(0, 3) == "ui_": continue
		
		var current_card: Control = option_card.instantiate()
		current_card.action_name = input_name
		controls_box.add_child(current_card)
		

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
	
	# Keybind settings
	save_dict["keybinds"] = {}
	for card in controls_box.get_children():
		save_dict["keybinds"][card.action_name] = card.new_key
	
	# Send dict to main.
	main_scene.apply_options(save_dict)
	_on_return_pressed()

func _on_return_pressed() -> void:
	if player_ui:
		player_ui.pause_menu.return_to_pause_home()
	elif main_menu_ui:
		main_menu_ui.to_title_screen()
	load_controls_box()
