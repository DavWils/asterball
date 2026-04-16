extends Control

@onready var level: Level = self.get_parent()
@onready var player_controller: PlayerController = self.get_parent().get_node("PlayerController")

func _process(delta: float) -> void:
	var local_char := player_controller.get_local_omnistriker()
	if local_char:
		var closest_dist: float = INF
		for child in level.get_children():
			if child is DarkExplosion:
				var dist: float = max(child.global_position.distance_to(local_char.global_position) - child.dark_radius, 0.0)
				if dist < closest_dist: closest_dist = dist
		print(closest_dist)
		modulate.a = lerpf(modulate.a, (1 - min(closest_dist, 1.0)), delta*15.0)
	else:
		modulate.a = 0.0
