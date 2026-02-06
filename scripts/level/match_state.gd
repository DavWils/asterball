# Script representing the current state of the match, including scores, player teams, and so on.

extends Node

class_name MatchState

@onready var level: Level = self.get_parent()
@onready var network_manager: NetworkManager = get_tree().current_scene.get_node("NetworkManager")
@onready var match_director: MatchDirector = level.get_node("MatchDirector")

## Dictionary of all player states.
var player_states: Dictionary[int, PlayerState]
## Dictionary of team states (Key: Team, Value: Team)
var team_states: Dictionary[int, TeamState]
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
	# Team states.
	for team_id in team_states:
		state_dict["team_states"][team_id] = team_states[team_id].to_dict()
	
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
	
	for team_id in data["team_states"]:
		var new_state := TeamState.new()
		new_state.from_dict(data["team_states"][team_id].from_dict)
		team_states[team_id] = new_state
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
	if network_manager.is_host():
		network_manager.send_p2p_packet(0, {"m": network_manager.Message.ADD_PLAYER_STATE, "player_id": id})
	if not player_states.has(id):
		var new_player_state := PlayerState.new()
		player_states[id] = new_player_state
		match_director.auto_assign_player_team(id)


func _on_lobby_chat_update(_id: int, changed_id: int, _change_maker_id: int, _chat_state: int):
	if network_manager.is_host():
		add_player_state(changed_id)

## Sets the round number to a set value. Increases it by default.
func set_current_round(num: int = current_round + 1):
	current_round = num
	if network_manager.is_host():
		network_manager.send_p2p_packet(0, {"m": 0})

## Sets whether or not match is ongoing.
func set_state_of_match(state: StateOfMatch):
	state_of_match = state
	if network_manager.is_host():
		network_manager.send_p2p_packet(0, {"m": network_manager.Message.SET_STATE_OF_MATCH, "state": state_of_match})

## Sets the match time. Defaults to decrementing one.
func set_match_time(time: int = match_time-1):
	match_time = time
	if network_manager.is_host():
		network_manager.send_p2p_packet(0, {"m": network_manager.Message.SET_MATCH_TIME, "time": match_time})

## Sets the intermission time. Defaults to decrementing one.
func set_intermission_time(time: int = intermission_time - 1):
	intermission_time = time
	if network_manager.is_host():
		network_manager.send_p2p_packet(0, {"m": network_manager.Message.SET_INTERMISSION_TIME, "time": intermission_time})

## Assigns a player to a given team.
func assign_player_team(player_id: int, team_id: int):
	player_states[player_id].team_id = team_id
	if network_manager.is_host():
		network_manager.send_p2p_packet(0, {"m": network_manager.Message.SET_PLAYER_TEAM, "player_id": player_id, "team": team_id})

## Returns the players in a team.
func get_team_players(team_id: int):
	var players: Array[int]
	for player in player_states:
		if player_states[player].team_id == team_id:
			players.append(player)
	return players

func set_team_score(team_id: int, new_score: int = team_states[team_id].score + 1):
	team_states[team_id].score = new_score
	print(team_states[team_id].team_resource.team_name, "'s new score is ", new_score)
	if network_manager.is_host():
		network_manager.send_p2p_packet(0, {"m": network_manager.Message.SET_TEAM_SCORE, "team_id": team_id, "score": new_score})
