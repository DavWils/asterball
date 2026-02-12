extends Area3D

class_name Zone

## The team that owns this zone, such as being able to buy from it. Is on the defending side, and if a score zone, will need to be accessed by other team members to score.
@export var owning_team := 0

## Level.
@onready var level: Level = get_tree().current_scene.get_node("Level")
## Network manager.
@onready var network_manager: NetworkManager = get_tree().current_scene.get_node("NetworkManager")
## Child collision shaoe.
@onready var collision_shape: CollisionShape3D = get_children().filter(func(c): return c is CollisionShape3D).front()
