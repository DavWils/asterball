extends Control

var session_id: int

@onready var main_scene: MainScene = get_tree().current_scene

func _ready() -> void:
	$Panel/MarginContainer/HBoxContainer/VBoxContainer/SessionNameLabel.text = Steam.getLobbyData(session_id, "lobby_name")
	$Panel/MarginContainer/HBoxContainer/VBoxContainer/SessionContextLabel.text = str(Steam.getNumLobbyMembers(session_id)) + "/" + str(Steam.getLobbyMemberLimit(session_id))
	var session_level_resource: LevelResource = load("res://resources/levels/" + Steam.getLobbyData(session_id, "level") + ".tres")
	
	if session_level_resource:
		$Panel/MarginContainer/HBoxContainer/SessionLevelThumbnailRect.texture = session_level_resource.thumbnail
		$Panel/MarginContainer/HBoxContainer/SessionLevelThumbnailRect.tooltip_text = session_level_resource.level_name
	
	$Panel/MarginContainer/HBoxContainer/JoinButton.pressed.connect(_on_join_pressed)

func _on_join_pressed() -> void:
	main_scene.join_game(session_id)
