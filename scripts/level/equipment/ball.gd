## Script for the ball as an equipment item.

extends Equipment

func _ready() -> void:
	super._ready()
	var wielder_overlap_area: Area3D = wielder.get_node("OverlapArea3D")
	wielder_overlap_area.area_entered.connect(_on_area_entered)
	for body in wielder_overlap_area.get_overlapping_areas():
		if body is ScoreZone:
			overlap_score_zone(body)
	
	
	## Add color.
	var allegiance_team = get_allegiance_team()
	var mesh_material := equipment_mesh.get_child(0).get_active_material(0) as ShaderMaterial
	if allegiance_team:
		var color = get_allegiance_team().team_resource.primary_color
		$TeamLight.light_color = color
		mesh_material.set_shader_parameter("emission_color", color)
	else:
		mesh_material.set_shader_parameter("emission_color", Color())
		$TeamLight.queue_free()

func _exit_tree() -> void:
	super._exit_tree()
	wielder.remove_effect(load("res://resources/effects/ball_slow.tres"))

func _on_area_entered(body: Node3D):
	if network_manager.is_host():
		if body is ScoreZone:
			overlap_score_zone(body)


## Called when player overlaps with a scorezone
func overlap_score_zone(body: ScoreZone) -> void:
	if not level.match_state.state_of_match == level.match_state.StateOfMatch.MATCH: return
	if body.owning_team != wielder.get_player_team_id():
		print("Score!")
		level = get_tree().current_scene.get_node("Level")
		level.match_director.score(wielder)
