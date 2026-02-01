extends Area3D

class_name Zone

## The team that owns this zone, such as being able to buy from it. Is on the defending side, and if a score zone, will need to be accessed by other team members to score.
@export var owning_team := 0

@onready var level: Level = get_tree().current_scene.get_node("Level")
@onready var network_manager: NetworkManager = get_tree().current_scene.get_node("NetworkManager")
