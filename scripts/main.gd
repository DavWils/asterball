extends Node

## Opens a level with the given string name.
func open_level(level: String):
	var new_level = load("res://scenes/main/levels/"+level+".tscn").instantiate()
	add_child(new_level)

func _ready() -> void:
	open_level("starfield")
