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

func _ready():
	$MatchTimer.timeout.connect(_on_match_timer_timeout)
	if network_manager.is_host():
		match_state.intermission_time = pregame_duration

## Start the game from pregame.
func start_game():
	print("Starting game.")
	match_state.set_match_status(true)
	match_state.set_match_time(match_duration)
	next_round()

## Moves onto the next round
func next_round():
	level.clean_level()
	level.spawn_omnistrikers()
	match_state.set_round_status(false)
	match_state.set_intermission_time(intermission_duration)
	if network_manager.is_host():
		match_state.set_current_round()

func start_round():
	print("Starting round.")
	match_state.set_round_status(true)

## Ends the current round, waiting for the score wait time until starting the next round.
func end_round():
	pass

func score(scoring_character: Character):
	print(Steam.getFriendPersonaName(scoring_character.owning_player_id), " has scored!")

func _on_match_timer_timeout():
	if not network_manager.is_host(): return
	
	if match_state.is_round_ongoing:
		match_state.set_match_time()
		print("Match time tick: ", match_state.match_time)
	else:
		match_state.set_intermission_time()
		print("Intermission time tick: ", match_state.intermission_time)
		if match_state.intermission_time <= 0:
			if match_state.match_started:
				start_round()
			else:
				start_game()
