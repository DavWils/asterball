extends Node

var level: LevelResource
var host_ui: Control

func _ready() -> void:
	self.text = level.level_name
	self.pressed.connect(_on_pressed)
	

func _on_pressed() -> void:
	host_ui.select_level(level)
