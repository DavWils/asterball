extends Node

## Opens a level with the given string name.
func open_level(level: String):
	load("res://scenes/main/levels/"+level+".tscn")

func _ready():
	open_level("starfield")
