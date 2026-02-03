# Script representing the current state of the match, including scores, player teams, and so on.

extends Node

class_name MatchState

@onready var level: Level = self.get_parent()
@onready var network_manager: NetworkManager = get_tree().current_scene.get_node("NetworkManager")
@onready var match_director: MatchDirector = level.get_node("MatchDirector")

## Dictionary of all player states.
var player_states: Dictionary[int, PlayerState]
## Dictionary of team scores (Key: Team, Value: Score)
var team_scores: Dictionary[int, int]
## The current match time that ticks down during the game.
var match_time: int = 0
## The current time of intermissions, the temporary time used everywhere except the actual match time. 
var intermission_time: int = 0
## Current state of the match
var state_of_match: StateOfMatch = StateOfMatch.PREGAME
## The current round the match is on.
var current_round: int = 0

enum StateOfMatch {
	PREGAME,
	PREPTIME,
	MATCH,
	CELEBRATION,
	ENDGAME
}

## Converts the match state to a dictionary.
func to_dict() -> Dictionary:
	var state_dict := {}
	# Player states.
	for player_id in player_states:
		state_dict["player_states"][player_id] = player_states[player_id].to_dict()
	
	state_dict["team_scores"] = team_scores
	state_dict["match_time"] = match_time
	state_dict["intermission_time"] = intermission_time
	state_dict["state_of_match"] = state_of_match
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
	state_of_match = data["state_of_match"]
	current_round = data["current_round"]

func _ready() -> void:
	# When someone joins we want to add them.
	Steam.lobby_chat_update.connect(_on_lobby_chat_update)
	
	# Add a player state for each player.
	await get_tree().process_frame # Need to wait until match director recognizes us.
	if network_manager.is_host():
		for member in network_manager.lobby_members:
			add_player_state(member["steam_id"])

## Adds a new player state to the player state array.
func add_player_state(id: int) -> void:
	if not player_states.has(id):
		player_states[id] = PlayerState.new()
		match_director.auto_assign_player_team(id)

func _on_lobby_chat_update(_id: int, changed_id: int, _change_maker_id: int, _chat_state: int):
	if network_manager.is_host():
		add_player_state(changed_id)

## Sets the round number to a set value. Increases it by default.
func set_current_round(num: int = current_round + 1):
	current_round = num

## Sets whether or not match is ongoing.
func set_state_of_match(state: StateOfMatch):
	state_of_match = state

## Sets the match time. Defaults to decrementing one.
func set_match_time(time: int = match_time-1):
	match_time = time

## Sets the intermission time. Defaults to decrementing one.
func set_intermission_time(time: int = intermission_time - 1):
	intermission_time = time

## Assigns a player to a given team.
func assign_player_team(player_id: int, team: int):
	player_states[player_id].team = team

## Returns the players in a team.
func get_team_players(team: int):
	var players: Array[int]
	for player in player_states:
		if player_states[player].team == team:
			players.append(player)
	return players
