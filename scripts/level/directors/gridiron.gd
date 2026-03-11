## Director for the gridiron gamemode.

extends MatchDirector

class_name GridironDirector


## Find the team with winning score.
func get_winning_team() -> int:
	var winning_teams := match_state.get_winning_team_ids()
	if winning_teams.size() > 1:
		return -1
	elif match_state.get_team_state(winning_teams[0]).score >= WINNING_SCORE:
		return winning_teams[0]
	else:
		return -1

func end_timer() -> void:
	match match_state.state_of_match:
		match_state.StateOfMatch.MATCH:
			var winning_team: int = get_winning_team()
			if winning_team < 0:
				# Do overtime match
				pass
			else:
				end_game(winning_team)
			return
		_:
			super.end_timer()

func next_round():
	super.next_round()
	await get_tree().process_frame
	spawn_omnistrikers()
	spawn_ball()

## Spawns the ball in the level.
func spawn_ball():
	var ball_item_state = ItemState.new()
	ball_item_state.item_resource = load("res://resources/items/ball.tres")
	return level.spawn_projectile(ball_item_state, level.default_item_spawn, null)

func score(scoring_character: Character):
	super.score(scoring_character)
	# Give points to the winning players as well.
	add_team_points(scoring_character.get_player_team_id(), WIN_SUPPORT_POINTS, {scoring_character.owning_player_id: WIN_SCORER_POINTS})
	
		
	# If team has reached winning score, end the game. Else just end round.
	if scoring_character.get_player_team_state().score >= WINNING_SCORE:
		end_game(scoring_character.get_player_team_id())
	else:
		end_round()

func is_unlocked_state() -> bool:
	return match_state.state_of_match == match_state.StateOfMatch.MATCH or match_state.state_of_match == match_state.StateOfMatch.CELEBRATION

func _on_char_terminated(_char: Node3D) -> void:
	if network_manager.is_host() and all_teams_dead() and match_state.is_match():
		end_round()
