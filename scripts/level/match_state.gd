# Script representing the current state of the match, including scores, player teams, and so on.

extends Node

class_name MatchState

@onready var level: Level = self.get_parent()
@onready var network_manager: NetworkManager = get_tree().current_scene.get_node("NetworkManager")

## Dictionary of all player states.
var player_states: Dictionary[int, PlayerState]
## Dictionary of team scores (Key: Team, Value: Score)
var team_scores: Dictionary[int, int]
## The current match time that ticks down during the game.
var match_time: int = 0
## The current time of intermissions, such as pregame 
var intermission_time: int = 0
## Whether or not the match started.
var match_started: bool = false
## Whether or not the round is ongoing.
var is_round_ongoing: bool = false
## The current round the match is on.
var current_round: int = 0

## Converts the match state to a dictionary.
func to_dict() -> Dictionary:
	var state_dict := {}
	# Player states.
	for player_id in player_states:
		state_dict["player_states"][player_id] = player_states[player_id].to_dict()
	
	state_dict["team_scores"] = team_scores
	state_dict["match_time"] = match_time
	state_dict["intermission_time"] = intermission_time
	state_dict["match_started"] = match_started
	state_dict["is_round_ongoing"] = is_round_ongoing
	state_dict["current_round"] = current_round
	
	return state_dict

## Converts a dictionary to the match state.
func from_dict(data: Dictionary) -> void:
	# Player states.
	for player_id in data["player_states"]:
		var new_state := PlayerState.new()
		new_state.from_dict(data["player_states"][player_id].from_dict)
		player_states[player_id] = new_state
	
	team_scores = data["team_scores"]
	match_time = data["match_time"]
	intermission_time = data["intermission_time"]
	match_started = data["match_started"]
	is_round_ongoing = data["is_round_ongoing"]
	current_round = data["current_round"]

func _ready() -> void:
	# When someone joins we want to add them.
	Steam.lobby_chat_update.connect(_on_lobby_chat_update)
	
	# Add a player state for each player.
	if network_manager.is_host():
		for member in network_manager.lobby_members:
			add_player_state(member["steam_id"])

## Adds a new player state to the player state array.
func add_player_state(id: int) -> void:
	player_states[id] = PlayerState.new()

func _on_lobby_chat_update(_id: int, changed_id: int, _change_maker_id: int, _chat_state: int):
	if not player_states.has(changed_id):
		add_player_state(changed_id)

## Sets the round number to a set value. Increases it by default.
func set_current_round(num: int = current_round + 1):
	current_round = num

## Sets whether or not match is ongoing.
func set_match_status(status: bool):
	match_started = status

## Sets whether or not a round is in progress.
func set_round_status(status: bool):
	is_round_ongoing = status

## Sets the match time. Defaults to decrementing one.
func set_match_time(time: int = match_time-1):
	match_time = time

## Sets the intermission time. Defaults to decrementing one.
func set_intermission_time(time: int = intermission_time - 1):
	intermission_time = time
