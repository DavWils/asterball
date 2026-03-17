extends Control

@export var player_ui: PlayerUI
@export var main_menu_ui: MainMenuUI

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
	# Load Volume Sliders.
	for bus in AudioServer.bus_count:
		var linear_vol: float = volume_slider_box.get_child(bus).get_linear_vol()
		AudioServer.set_bus_volume_linear(bus, linear_vol)

func _on_return_pressed() -> void:
	if player_ui:
		player_ui.pause_menu.return_to_pause_home()
	elif main_menu_ui:
		main_menu_ui.to_title_screen()
