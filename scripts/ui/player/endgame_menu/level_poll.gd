extends Button

@onready var network_manager: NetworkManager = get_tree().current_scene.get_node("NetworkManager")
@onready var match_state: MatchState = get_tree().current_scene.get_node("Level").get_node("MatchState")

@export var voter_container: GridContainer

var poll_level: LevelResource

func _ready() -> void:
	$VBoxContainer/Label.text = poll_level.level_name
	pressed.connect(_on_pressed)
	match_state.player_voted.connect(_on_player_voted)

func _on_pressed() -> void:
	if network_manager.is_host():
		match_state.set_player_vote(network_manager.player_id, poll_level)
	else:
		network_manager.send_p2p_packet(network_manager.get_host_id(), {"m": NetworkManager.Message.CLIENT_REQUEST_VOTE, "player_id": network_manager.player_id, "vote": poll_level.get_level_filename()})

func _on_player_voted(_player_id: int, _level_resource: LevelResource) -> void:
	reload_voters()

func reload_voters() -> void:
	var found_players: Array[int] = []
	for child in voter_container.get_children():
		if match_state.player_votes[child.player_id] != poll_level:
			child.queue_free()
		else:
			found_players.append(child.player_id)
			
	
	for voter in match_state.player_votes:
		if not found_players.has(voter):
			if match_state.player_votes[voter] == poll_level:
				var new_button: Control = load("res://scenes/ui/menu/buttons/player_button.tscn").instantiate()
				new_button.player_id = voter
				voter_container.add_child(new_button)
				new_button.modulate = Color.TRANSPARENT
				var move_tween := create_tween()
				move_tween.tween_property(new_button, "modulate", Color.WHITE, 0.5)
			
