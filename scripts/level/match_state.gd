# Script representing the current state of the match, including scores, player teams, and so on.

extends Node

class_name MatchState

@onready var network_manager: NetworkManager = get_tree().current_scene.get_node("NetworkManager")

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
