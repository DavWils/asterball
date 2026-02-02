#The director of the game that controls the flow of it via host. In other words it is a gamemode as well.

extends Node

class_name MatchDirector

## The amount of time to wait before starting the game.
@export var pregame_wait_time := 10.0
## The amount of time in the match.
@export var match_wait_time := 600.0
## The amount of time before the round actually starts, allowing players some time to shop and buy items.
@export var intermission_wait_time := 10.0
## The amount of time to wait after a score until the next round begins.
@export var score_wait_time := 5.0
