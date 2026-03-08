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

## Signal emitted when player state is added.
signal player_state_added(player_id: int)
## Signal emitted when player team is assigned.
signal player_team_assigned(player_id: int, team_id: int)
## Signal when time is set.
signal time_set(time: int)

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
	state_dict["player_states"] = {}
	state_dict["team_states"] = {}
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
		new_state.from_dict(data["player_states"][player_id])
		player_states[player_id] = new_state
	
	for team_id in data["team_states"]:
		var new_state := TeamState.new()
		new_state.from_dict(data["team_states"][team_id])
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
			add_player_state(member)

## Adds a new player state to the player state array.
func add_player_state(id: int) -> void:
	if network_manager.is_host():
		network_manager.send_p2p_packet(0, {"m": network_manager.Message.ADD_PLAYER_STATE, "player_id": id})
	if not player_states.has(id):
		var new_player_state := PlayerState.new()
		player_states[id] = new_player_state
		player_state_added.emit(id)
		if network_manager.is_host():
			match_director.auto_assign_player_team(id)


func _on_lobby_chat_update(_id: int, changed_id: int, _change_maker_id: int, chat_state: int):
	if network_manager.is_host():
		if chat_state & Steam.CHAT_MEMBER_STATE_CHANGE_ENTERED:
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
		network_manager.send_p2p_packet(0, {"m": network_manager.Message.SET_STATE_OF_MATCH, "state_of_match": state_of_match})

## Sets the match time. Defaults to decrementing one.
func set_match_time(time: int = match_time-1):
	match_time = time
	if network_manager.is_host():
		network_manager.send_p2p_packet(0, {"m": network_manager.Message.SET_MATCH_TIME, "time": match_time})
	else:
		match_director.match_timer.start()
	time_set.emit(time)

## Sets the intermission time. Defaults to decrementing one.
func set_intermission_time(time: int = intermission_time - 1):
	intermission_time = time
	if network_manager.is_host():
		network_manager.send_p2p_packet(0, {"m": network_manager.Message.SET_INTERMISSION_TIME, "time": intermission_time})
	else:
		match_director.match_timer.start()
	time_set.emit(time)

## Assigns a player to a given team.
func assign_player_team(player_id: int, team_id: int):
	if player_states.has(player_id) and team_states.has(team_id):
		player_states[player_id].team_id = team_id
		print(Steam.getFriendPersonaName(player_id), " has been assigned to the ", team_states[team_id].team_resource.team_name)
		player_team_assigned.emit(player_id, team_id)
		if network_manager.is_host():
			network_manager.send_p2p_packet(0, {"m": network_manager.Message.SET_PLAYER_TEAM, "player_id": player_id, "team_id": team_id})

## Returns the players in a team.
func get_team_players(team_id: int) -> Array[int]:
	var players: Array[int]
	for player in player_states:
		if player_states[player].team_id == team_id:
			players.append(player)
	return players

## Sets a score of the team of the given team id.
func set_team_score(team_id: int, new_score: int = team_states[team_id].score + 1):
	team_states[team_id].set_score(new_score)
	print(team_states[team_id].team_resource.team_name, "'s new score is ", new_score)
	if network_manager.is_host():
		network_manager.send_p2p_packet(0, {"m": network_manager.Message.SET_TEAM_SCORE, "team_id": team_id, "score": new_score})

## Returns the highest scoring team(s), returning multiple if there is a tie.
func get_winning_team_ids() -> Array[int]:
	var highest_teams: Array[int] = []
	for team_id in team_states.keys():
		if highest_teams.is_empty():
			highest_teams.append(team_id)
		else:
			var high_score: int = team_states[highest_teams[0]].score
			var current_score = team_states[team_id].score
			if current_score > high_score:
				highest_teams.clear()
				highest_teams.append(team_id)
			elif current_score == high_score:
				highest_teams.append(team_id)
	
	return highest_teams

## Returns the player state of the given player via id.
func get_player_state(player_id: int) -> PlayerState:
	return player_states[player_id]

## Returns the team state of the given team via id.
func get_team_state(team_id: int) -> TeamState:
	if team_states.has(team_id):
		return team_states[team_id]
	else:
		return null

func get_team_ids() -> Array[int]:
	return team_states.keys()

## Sets the score of the player with the given player id. Sets current score, as well as total score.
func set_player_score(player_id: int, current: int, total: int) -> void:
	player_states[player_id].set_score(current, total)
	print("Set ", Steam.getFriendPersonaName(player_id), "'s new scores to ", str(current), "/", str(total))
	if network_manager.is_host():
		network_manager.send_p2p_packet(0, {"m": network_manager.Message.SET_PLAYER_SCORE, "player_id": player_id, "current": current, "total": total})

## Returns time as a string
func get_time_text() -> String:
	var time: int = match_time if state_of_match == StateOfMatch.MATCH else intermission_time
	@warning_ignore("integer_division")
	var time_hr: int = time/3600
	@warning_ignore("integer_division")
	var time_min: int = time/60
	var time_sec: int = time%60
	if time_hr > 0:
		return str(time_hr).pad_zeros(2)+":"+str(time_min).pad_zeros(2)+":"+str(time_sec).pad_zeros(2)
	elif time_min > 0:
		return str(time_min).pad_zeros(2)+":"+str(time_sec).pad_zeros(2)
	else:
		return str(time_sec).pad_zeros(2)

## Returns true if match is active (i.e. if match timer should tick instead of intermission).
func is_match() -> bool:
	return state_of_match == StateOfMatch.MATCH
