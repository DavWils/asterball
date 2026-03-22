extends Control

var session_id: int

func _ready() -> void:
	$Panel/MarginContainer/HBoxContainer/VBoxContainer/SessionNameLabel.text = Steam.getLobbyData(session_id, "lobby_name")
	$Panel/MarginContainer/HBoxContainer/VBoxContainer/SessionContextLabel.text = str(Steam.getNumLobbyMembers(session_id)) + "/" + str(Steam.getLobbyMemberLimit(session_id))
	var session_level_resource: LevelResource = load("res://resources/levels/" + Steam.getLobbyData(session_id, "level") + ".tres")
	
	if session_level_resource:
		$Panel/MarginContainer/HBoxContainer/SessionLevelThumbnailRect.texture = session_level_resource.thumbnail
		$Panel/MarginContainer/HBoxContainer/SessionLevelThumbnailRect.tooltip_text = session_level_resource.level_name
