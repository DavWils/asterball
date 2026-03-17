extends Control

@export var player_ui: PlayerUI
@export var main_menu_ui: MainMenuUI
@onready var main_scene: MainScene = get_tree().current_scene

@onready var volume_slider_box := $AudioPanel/ScrollContainer/MarginContainer/VolumeSliderContainer

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

func _on_apply_pressed() -> void:
	var save_dict: Dictionary = {}
	
	# Save audio settings
	save_dict["audio"] = {}
	for bus in AudioServer.bus_count:
		var linear_vol: float = volume_slider_box.get_child(bus).get_linear_vol()
		save_dict["audio"][str(bus)] = linear_vol
	
	# Send dict to main.
	main_scene.apply_options(save_dict)


func _on_return_pressed() -> void:
	if player_ui:
		player_ui.pause_menu.return_to_pause_home()
	elif main_menu_ui:
		main_menu_ui.to_title_screen()
