### The base script for a level.

extends Node

class_name Level

var network_manager: NetworkManager = get_tree().current_scene.get_node("NetworkManager")

## The furthest depth a character can go before they're killed.
@export var kill_depth := -100.0
## The amount of timet o wait before starting the game.
@export var pregame_wait_time := 60.0
## The amount of time to wait after a score until the next round begins.
@export var score_wait_time := 5.0
## The amount of time before the round actually starts, allowing players some time to shop and buy items.
@export var intermission_wait_time := 10.0

func _ready():
	await get_tree().create_timer(pregame_wait_time).timeout
	if network_manager.is_host():
		start_game()

## Starts the game.
func start_game():
	next_round()

## Transfers to the next round, allowing players to shop for a set time until the round actually starts.
func next_round():
	await get_tree().create_timer(intermission_wait_time).timeout
	

func score(scoring_character: Node3D):
	print(scoring_character.name, " has scored!!!")
	
	# Wait some time, and if we're the host, then start the next game.
	await get_tree().create_timer(score_wait_time).timeout
	if network_manager.is_host():
		next_round()
