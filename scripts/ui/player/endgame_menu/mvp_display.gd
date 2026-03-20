extends Control

@onready var network_manager: NetworkManager = get_tree().current_scene.get_node("NetworkManager")
@onready var match_state: MatchState = get_tree().current_scene.get_node("Level").get_node("MatchState")
@onready var level: Level = get_tree().current_scene.get_node("Level")

@export var mvp_name_label: Label
@export var mvp_points_label: Label
@export var viewport_camera: Camera3D

var mvp: Omnistriker = null

const CAM_FACTOR: float = 2.0

const CAM_LENGTH: float = 2.6
const CAM_HEIGHT: float = 1.3

var cam_time: float = 0.0

func _process(delta: float) -> void:
	if mvp:
		cam_time += delta * CAM_FACTOR
		
		var offset = Vector3(
			cos(cam_time) * CAM_LENGTH,
			CAM_HEIGHT-0.8,
			sin(cam_time) * CAM_LENGTH
		)
		
		
		
		viewport_camera.global_position = mvp.global_position + offset
		viewport_camera.look_at(mvp.global_position + Vector3.UP * CAM_HEIGHT, Vector3.UP)

func set_mvp(player_id: int) -> void:
	var mvp_omnistriker: Omnistriker = null
	for child in level.get_children():
		if child is Omnistriker:
			if child.owning_player_id == player_id:
				mvp_omnistriker = child
	
	if mvp_omnistriker:
		mvp = mvp_omnistriker

	if network_manager.is_on_steam():
		mvp_name_label.text = "MVP\n" + Steam.getFriendPersonaName(player_id)
		mvp_points_label.text = str(match_state.get_player_state(player_id).total_score) + " Points"
