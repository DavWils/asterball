## Script for player match menu.

extends Control

## Reference to match state.
@onready var match_state: MatchState = get_tree().current_scene.get_node("Level").get_node("MatchState")
## Reference to network manager.
@onready var network_manager = get_tree().current_scene.network_manager


func _ready() -> void:
	load_team_columns()
	match_state.time_set.connect(_on_time_set)

func load_team_columns() -> void:
	for child in $TeamContainer.get_children():
		child.queue_free()
	
	var team_column_resource = load("res://scenes/ui/player/match_menu/team_column.tscn")
	for team_id in match_state.get_team_ids():
		var team_column = team_column_resource.instantiate()
		team_column.team_id = team_id
		$TeamContainer.add_child(team_column)

func _on_time_set(_time: int):
	$TimerContainer/TimerLabel.text = match_state.get_time_text()
