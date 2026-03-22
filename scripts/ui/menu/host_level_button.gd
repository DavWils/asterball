extends Node

var level: LevelResource
var host_ui: Control

func _ready() -> void:
	$VBoxContainer/Label.text = level.level_name
	$VBoxContainer/TextureRect.texture = level.thumbnail
	self.pressed.connect(_on_pressed)
	

func _on_pressed() -> void:
	host_ui.select_level(level)
