#The director of the game that controls the flow of it via host. In other words it is a gamemode that uses the match state to control the game.

extends Node

class_name MatchDirector

@onready var network_manager: NetworkManager = get_tree().current_scene.get_node("NetworkManager")
@onready var level: Level = self.get_parent()
@onready var match_state: MatchState = level.get_node("MatchState")
@onready var match_timer: Timer = $MatchTimer


## The amount of time to wait before starting the game.
const PREGAME_DURATION := 5
## The amount of time in the match.
const MATCH_DURATION := 600
## The amount of time before the round actually starts, allowing players some time to shop and buy items.
const INTERMISSION_DURATION := 3
## The amount of time to wait after a score until the next round begins.
const CELEBRATION_DURATION := 10
## The amount of time spent in the endgame before loading to the next level.
const ENDGAME_DURATION := 30
## The number of teams.
const TEAM_COUNT := 2
## The final amount of points a team must get to win the game.
const WINNING_SCORE := 2
## The amount of points given to all players when a new round begins.
const NEW_ROUND_POINTS := 600
## The amount of points given to a player when their team wins a score.
const WIN_SUPPORT_POINTS := 500
## The extra amount of points given to the player who actually scores.
const WIN_SCORER_POINTS := 350

func _ready():
	print("Level is ", level, " and state is ", match_state)
	match_timer.timeout.connect(_on_match_timer_timeout)
	if network_manager.is_host():
		# Set teams:
		for i in range(0, TEAM_COUNT):
			match_state.team_states[i] = TeamState.new()
		# Home team
		match_state.team_states[0].team_resource = level.get_level_resource().home_team
		# Away Team
		# Get a random team.
		var valid_teams: Array[TeamResource] = [load("res://resources/teams/starstriders.tres"), load("res://resources/teams/warpions.tres"), load("res://resources/teams/accelites.tres")]
		valid_teams.erase(level.get_level_resource().home_team)
		match_state.team_states[1].team_resource = valid_teams.pick_random()
		print(match_state.team_states[0].team_resource.team_name, " vs ", match_state.team_states[1].team_resource.team_name)
		
		# Set time
		match_state.intermission_time = PREGAME_DURATION
		

## Start the game from pregame.
func start_game():
	print("Starting game.")
	match_state.set_match_time(MATCH_DURATION)
	next_round()

## Moves onto the next round
func next_round():
	clean_level()
	await get_tree().process_frame
	spawn_omnistrikers()
	spawn_ball()
	match_state.set_intermission_time(INTERMISSION_DURATION)
	match_state.set_state_of_match(match_state.StateOfMatch.PREPTIME)
	if network_manager.is_host():
		match_state.set_current_round()

func start_round():
	print("Starting round.")
	match_state.set_state_of_match(match_state.StateOfMatch.MATCH)

## Ends the current round, waiting for the score wait time until starting the next round.
func end_round():
	match_state.set_intermission_time(CELEBRATION_DURATION)
	match_state.set_state_of_match(match_state.StateOfMatch.CELEBRATION)

## Ends the game.
func end_game(scoring_team: int):
	print(match_state.team_states[scoring_team].team_resource.team_name, " wins the game.")
	match_state.set_intermission_time(ENDGAME_DURATION)
	match_state.set_state_of_match(match_state.StateOfMatch.ENDGAME)

func score(scoring_character: Character):
	print(Steam.getFriendPersonaName(scoring_character.owning_player_id), " has scored!")
	# Add a point to the player's team.
	match_state.set_team_score(match_state.player_states[scoring_character.owning_player_id].team_id)
	level.score_effect(scoring_character)
	# Give points to the winning players as well.
	for player_id in match_state.player_states.keys():
		var added_points: int = 0
		var scorer_state: PlayerState = match_state.get_player_state(scoring_character.owning_player_id)
		var current_state: PlayerState = match_state.get_player_state(player_id)
		# If on winning team, add points.
		if current_state.team_id == scorer_state.team_id:
			added_points += WIN_SUPPORT_POINTS
			# If scoring player, add more points.
			if player_id == scoring_character.owning_player_id:
				added_points += WIN_SCORER_POINTS
		
		# If non zero points, add them.
		if added_points != 0:
			add_player_points(player_id, added_points)
		
	# If team has reached winning score, end the game. Else just end round.
	if scoring_character.get_player_team_state().score >= WINNING_SCORE:
		end_game(scoring_character.get_player_team_id())
	else:
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
				# Find team with highest score.
				var winning_teams := match_state.get_winning_team_ids()
				if winning_teams.size() == 1:
					end_game(winning_teams[0])
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
	for i in range(0, TEAM_COUNT):
		team_sizes[i] = match_state.get_team_players(i).size()

	# Find the team with the lowest count.
	var current_count: int = 1 << 60
	var lowest_team: int
	for i in range(0, TEAM_COUNT):
		if team_sizes[i] < current_count:
			lowest_team = i
			current_count = team_sizes[i]
	
	print("Auto assigning ", Steam.getFriendPersonaName(player_id))
	match_state.assign_player_team(player_id, lowest_team)


## Spawns the ball in the level.
func spawn_ball():
	var ball_item_state = ItemState.new()
	ball_item_state.item_resource = load("res://resources/items/ball.tres")
	return level.spawn_pickup(ball_item_state, Vector3.UP*5)

## Spawns a character for each player.
func spawn_omnistrikers() -> void:
	var omnistriker_path := "res://scenes/level/characters/omnistriker.tscn"
	# An array of each team and their respective players. After getting this, we'll use the number of team players to place them in an even line.
	var teams_and_players: Dictionary[int, Array]
	for team_id in match_state.team_states:
		teams_and_players[team_id] = match_state.get_team_players(team_id)
	
	for team_id in teams_and_players:
		# Spawn zone of the team.
		var spawn_zone: SpawnZone = level.get_spawn_zone(team_id)
		
		# Iterate over all players in this team and spawn them in a line.
		for player_id in teams_and_players[team_id]:
			# Make sure they're actually in the game when spawning them.
			if network_manager.has_lobby_member(player_id):
				var spawn_position: Vector3 = spawn_zone.get_spawn_position(teams_and_players[team_id].find(player_id), teams_and_players[team_id].size())
				level.spawn_character(omnistriker_path, player_id, spawn_position)

## Cleans up the level, removing old stuff from registry.
func clean_level() -> void:
	for id in level.level_registry.keys():
		level.despawn_registry_object(id)

## Adds points to the given player.
func add_player_points(player_id: int, points: int) -> void:
	var player_state: PlayerState = match_state.get_player_state(player_id)
	var player_current: int = player_state.current_score
	var player_total: int = player_state.total_score
	match_state.set_player_score(player_id, player_current + points, player_total + points)

## Spends (removes) points from the given player.
func spend_player_points(player_id: int, points: int) -> void:
	var player_state: PlayerState = match_state.get_player_state(player_id)
	var player_current: int = player_state.current_score
	var player_total: int = player_state.total_score
	match_state.set_player_score(player_id, player_current - points, player_total)

## Has a player purchase a givne item.
func purchase_item(character: Character, item_resource: ItemResource) -> void:
	var buyer_id: int = character.owning_player_id
	var cost: int = item_resource.item_cost
	print(Steam.getFriendPersonaName(buyer_id), " wants to buy ", item_resource.item_name)
	if match_state.get_player_state(buyer_id).can_afford(cost):
		spend_player_points(buyer_id, cost)
		var new_item := ItemState.new()
		new_item.item_resource = item_resource
		character.pickup_item(new_item)
