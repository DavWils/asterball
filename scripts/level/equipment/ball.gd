## Script for the ball as an equipment item.

extends Equipment

func _ready() -> void:
	super._ready()
	var wielder_overlap_area: Area3D = wielder.get_node("OverlapArea3D")
	wielder_overlap_area.area_entered.connect(_on_area_entered)

func _on_area_entered(body: Node3D):
	if network_manager.is_host():
		# Return if it's not the right mode.
		if not level.match_state.state_of_match == level.match_state.StateOfMatch.MATCH: return
		
		if body is ScoreZone:
			if body.owning_team != wielder.get_player_team():
				print("Score!")
				level = get_tree().current_scene.get_node("Level")
				level.match_director.score(wielder)
