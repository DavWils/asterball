extends Control

@onready var main_scene: MainScene = get_tree().current_scene
@onready var match_state: MatchState = get_tree().current_scene.get_node("Level").get_node("MatchState")
@onready var blur_rect: ColorRect = $BlurRect
@onready var color_rect: ColorRect = $ColorRect
@onready var player_ui: PlayerUI = self.get_parent()


@export var poll_container: GridContainer
@export var other_teams_box: BoxContainer
@export var mvp_display: Control
@export var leaderboard_box: VBoxContainer

## Time it takes to fade in the background of the endgame menu.
const FADE_TIME: float = 1.0

func _ready() -> void:
	if not player_ui.is_node_ready(): await player_ui.ready
	player_ui.chat_menu.message_received.connect(_on_message_received)

func _on_message_received(sender: int, message: String, channel: int):
	var new_message = player_ui.chat_menu.message_control.instantiate()
	new_message.set_message(sender, message, channel)
	$ChatScrollBox/VBoxContainer.add_child(new_message)

func load_endgame() -> void:
	# Load level votes.
	for new_level in main_scene.get_all_levels():
		var poll_scene: Control = load("res://scenes/ui/player/endgame_menu/level_poll.tscn").instantiate()
		poll_scene.poll_level = new_level
		poll_container.add_child(poll_scene)
	
	# Load MVP
	mvp_display.set_mvp(match_state.get_mvp_player())
	
	# Load leaderboard.
	var sorted_players = match_state.player_states.keys()
	sorted_players.sort_custom(player_sort)
	var current_placement := 1
	for player_id in sorted_players:
		var new_card: Control = load("res://scenes/ui/player/endgame_menu/endgame_player_card.tscn").instantiate()
		new_card.player_placement = current_placement
		current_placement += 1
		new_card.player_id = player_id
		new_card.player_score = match_state.get_player_state(player_id).total_score
		leaderboard_box.add_child(new_card)
	
	# Set teams.
	var winning_teams: Array[int] = match_state.get_winning_team_ids()
	var other_teams: Array[int] = match_state.get_team_ids()
	for id in winning_teams:
		other_teams.erase(id)
	other_teams.sort_custom(team_sort)
	
	# Load winning teams.
	for id in winning_teams:
		if id == winning_teams[0]: $WinningTeamStatsDisplay.set_team_info(1, match_state.get_team_state(id))
		else: load_other_team(id, 1)
			
	# And then load losing teams.
	var placement_counter: int = 2
	for id in other_teams:
		load_other_team(placement_counter, id)
		placement_counter += 1
	
	# Tween in the background color rects.
	var fade_tween = create_tween()
	var blur_end_color: Color = blur_rect.color
	var color_end_color: Color = color_rect.color
	blur_rect.color = Color(0,0,0,0)
	color_rect.color = Color(0,0,0,0)
	
	fade_tween.tween_property(blur_rect, "color", blur_end_color, FADE_TIME)
	fade_tween.parallel().tween_property(color_rect, "color", color_end_color, FADE_TIME)
	
	

func team_sort(team_a: int, team_b: int) -> bool:
	return match_state.get_team_state(team_a).score > match_state.get_team_state(team_b).score

func player_sort(player_a: int, player_b: int) -> bool:
	return match_state.get_player_state(player_a).total_score > match_state.get_player_state(player_b).total_score

func load_other_team(placement: int, team_id: int) -> void:
	var new_child: Control = load("res://scenes/ui/player/endgame_menu/team_stats_display.tscn").instantiate()
	new_child.set_team_info(placement, match_state.get_team_state(team_id))
	other_teams_box.add_child(new_child)
