extends Control

## Reference to level
@onready var level: Level = get_tree().current_scene.get_node("Level")
## Reference to match state.
@onready var match_state: MatchState = level.get_node("MatchState")

func set_message(sender_id: int, message: String, channel: int):
	if not is_node_ready(): await ready
	var hex_color := (match_state.get_team_state(match_state.get_player_team_id(sender_id)).team_resource.primary_color).to_html(false)
	$RichTextLabel.text = "[b]" + "[color=" + hex_color + "]" + Steam.getFriendPersonaName(sender_id) + "[/color]" + ":[/b] " + (message if channel == 0 else ("[i]" + message + "[/i]"))
