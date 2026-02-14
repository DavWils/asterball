## Script for team columns which list all the players in the team.

extends VBoxContainer

## The id of the team for this column..
var team_id: int

## Reference to match state.
@onready var match_state: MatchState = get_tree().current_scene.get_node("Level").get_node("MatchState")
## Reference to network manager.
@onready var network_manager = get_tree().current_scene.network_manager

func _ready() -> void:
	# Set up header.
	var team_state: TeamState = match_state.get_team_state(team_id)
	$HeaderRow/TeamNameText.text = team_state.team_resource.team_name
	team_state.score_changed.connect(_on_score_changed)
	_on_score_changed(team_state.score)
	load_player_column()
	# Listen to when new player states are added, so we can add player states to the list.
	match_state.player_state_added.connect(_on_player_state_added)
	match_state.player_team_assigned.connect(_on_player_team_assigned)


func load_player_column() -> void:
	# Clear old players.
	for child in $PlayerColumn.get_children():
		child.queue_free()
	
	# Add all players to the list.
	for player_id in match_state.get_team_players(team_id):
		add_player_row(player_id)

func add_player_row(player_id: int) -> void:
	var player_row_resource = load("res://scenes/ui/player/match_menu/team_player_row.tscn")
	var player_row = player_row_resource.instantiate()
	player_row.player_id = player_id
	$PlayerColumn.add_child(player_row)

## Called when team score is changed, updating here.
func _on_score_changed(new_score: int) -> void:
	$HeaderRow/TeamScoreText.text = str(new_score)

func _on_player_state_added(_player_id: int):
	load_player_column()

func _on_player_team_assigned(_player_id: int, _team_id: int):
	load_player_column()
