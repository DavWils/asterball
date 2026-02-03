#The director of the game that controls the flow of it via host. In other words it is a gamemode that uses the match state to control the game.

extends Node

class_name MatchDirector

@onready var network_manager: NetworkManager = get_tree().current_scene.get_node("NetworkManager")
@onready var level: Level = self.get_parent()
@onready var match_state: MatchState = level.get_node("MatchState")

## The amount of time to wait before starting the game.
@export var pregame_duration := 5
## The amount of time in the match.
@export var match_duration := 600
## The amount of time before the round actually starts, allowing players some time to shop and buy items.
@export var intermission_duration := 10
## The amount of time to wait after a score until the next round begins.
@export var celebration_duration := 5
## The number of teams.
@export var team_count := 2

func _ready():
	print("Level is ", level, " and state is ", match_state)
	$MatchTimer.timeout.connect(_on_match_timer_timeout)
	if network_manager.is_host():
		match_state.intermission_time = pregame_duration

## Start the game from pregame.
func start_game():
	print("Starting game.")
	match_state.set_match_time(match_duration)
	next_round()

## Moves onto the next round
func next_round():
	level.clean_level()
	level.spawn_omnistrikers()
	level.spawn_ball()
	match_state.set_intermission_time(intermission_duration)
	match_state.set_state_of_match(match_state.StateOfMatch.PREPTIME)
	if network_manager.is_host():
		match_state.set_current_round()

func start_round():
	print("Starting round.")
	match_state.set_state_of_match(match_state.StateOfMatch.MATCH)

## Ends the current round, waiting for the score wait time until starting the next round.
func end_round():
	match_state.set_intermission_time(celebration_duration)
	match_state.set_state_of_match(match_state.StateOfMatch.CELEBRATION)

## Ends the game.
func end_game():
	match_state.set_state_of_match(match_state.StateOfMatch.ENDGAME)

func score(scoring_character: Character):
	print(Steam.getFriendPersonaName(scoring_character.owning_player_id), " has scored!")
	end_round()

func _on_match_timer_timeout():
	if not network_manager.is_host(): return
	match match_state.state_of_match:
		match_state.StateOfMatch.PREGAME: # Pregame timer. Start the game when this runs out.
			match_state.set_intermission_time()
			print("Pregame tick: ", match_state.intermission_time)
			if match_state.intermission_time <= 0:
				start_game()
		match_state.StateOfMatch.PREPTIME: # Prep time pre round, starts the round after this.
			match_state.set_intermission_time()
			print("Prep time tick: ", match_state.intermission_time)
			if match_state.intermission_time <= 0:
				start_round()
		match_state.StateOfMatch.MATCH: # Main match timer. When this runs out, game ends.
			match_state.set_match_time()
			print("Match time tick: ", match_state.match_time)
			if match_state.match_time <= 0:
				end_game()
		match_state.StateOfMatch.CELEBRATION: # Celebration time after the end of a round. Starts next round after.
			match_state.set_intermission_time()
			print("Celebration time tick: ", match_state.intermission_time)
			if match_state.intermission_time <= 0:
				next_round()
		match_state.StateOfMatch.ENDGAME: # End of the game. Players will vote and the most voted map will be transitioned to.
			match_state.set_intermission_time()
			print("Endgame time tick: ", match_state.intermission_time)
			if match_state.intermission_time <= 0:
				pass

## Automatically assigns the player a team. By default, assigns to the lowest count team.
func auto_assign_player_team(player_id: int):
	# Initialize.
	var team_sizes: Dictionary
	for i in range(0, team_count):
		team_sizes[i] = match_state.get_team_players(i).size()

	# Find the team with the lowest count.
	var current_count: int = 1 << 60
	var lowest_team: int
	for i in range(0, team_count):
		if team_sizes[i] < current_count:
			lowest_team = i
			current_count = team_sizes[i]
	
	print("Auto assigning ", Steam.getFriendPersonaName(player_id), " to team ", lowest_team)
	match_state.assign_player_team(player_id, lowest_team)
