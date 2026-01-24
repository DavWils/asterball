# Script representing the current state of the match, including scores, player teams, and so on.

extends Node

class_name MatchState

var player_states: Dictionary[int, PlayerState]

## The current score of the home team.
var home_score := 0

## The current score of the away team.
var away_score := 0

## Converts the match state to a dictionary.
func to_dict() -> Dictionary:
	var data := {}
	for prop in get_property_list():
		if prop.usage & PROPERTY_USAGE_STORAGE:
			data[prop.name] = get(prop.name)
	return data

## Converts a dictionary to the match state.
func from_dict(data: Dictionary) -> void:
	for key in data:
		set(key, data[key])
