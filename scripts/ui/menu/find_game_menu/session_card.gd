extends Control

var session_id: int

func _ready() -> void:
	$Panel/MarginContainer/HBoxContainer/VBoxContainer/SessionNameLabel.text = Steam.getLobbyData(session_id, "lobby_name")
	$Panel/MarginContainer/HBoxContainer/VBoxContainer/SessionContextLabel.text = str(Steam.getNumLobbyMembers(session_id)) + "/" + str(Steam.getLobbyMemberLimit(session_id))
