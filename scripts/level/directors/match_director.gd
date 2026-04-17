#The director of the game that controls the flow of it via host. In other words it is a gamemode that uses the match state to control the game.

extends Node

class_name MatchDirector

@onready var network_manager: NetworkManager = get_tree().current_scene.get_node("NetworkManager")
@onready var level: Level = self.get_parent()
@onready var match_state: MatchState = level.get_node("MatchState")
@onready var match_timer: Timer = $MatchTimer

## Array of all buyable items.
@export var buyable_items: Array[ItemResource]
## Array of all ingame teams.
@export var teams: Array[TeamResource]

## The temporary memory of the inventory of player omnistrikers whewn level is cleared.
var inventory_memory: Dictionary[int, Dictionary]

## The amount of time to wait before starting the game.
const PREGAME_DURATION := 30
## The amount of time in the match.
const MATCH_DURATION := 600
## The amount of time before the round actually starts, allowing players some time to shop and buy items.
const INTERMISSION_DURATION := 10
## The amount of time to wait after a score until the next round begins.
const CELEBRATION_DURATION := 10
## The amount of time spent in the endgame before loading to the next level.
const ENDGAME_DURATION := 30
## The number of teams.
const TEAM_COUNT := 2
## The final amount of points a team must get to win the game.
const WINNING_SCORE := 7
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
		var valid_teams := get_all_teams(true)
		
		match_state.team_states[1].team_resource = valid_teams.pick_random()
		print(match_state.team_states[0].team_resource.team_name, " vs ", match_state.team_states[1].team_resource.team_name)
		
		# Set time
		match_state.intermission_time = PREGAME_DURATION
		
	# Track characters so that when they are terminated from the game (killed/despawned) the director will notice and act.
	level.registry_obj_spawned.connect(_on_registry_obj_spawned)
	
	for id in level.level_registry:
		if level.level_registry[id] is Character:
			_on_registry_obj_spawned(level.level_registry[id])

func _on_registry_obj_spawned(new_obj: Node3D):
	if new_obj is Character:
		new_obj.killed.connect(_on_char_terminated)
		new_obj.freed.connect(_on_char_terminated)
		print("Connecting ", new_obj.registry_id, " to termination")
	else:
		print("Not character, ", new_obj)

## Called when character is removed from the game.
func _on_char_terminated(_char: Node3D) -> void:
	pass

## Returns true if no team has a living character
func all_teams_dead() -> bool:
	var team_ids = match_state.get_team_ids()
	for id in level.level_registry:
		var registry_obj := level.level_registry[id]
		if registry_obj is Character:
			var team_id = registry_obj.get_player_team_id()
			if team_ids.has(team_id): 
				return false
	
	return true

## Return strue if all teams have a living character.
func all_teams_alive() -> bool:
	var team_ids = match_state.get_team_ids()
	var alive_ids: Array[int] = []
	for id in level.level_registry:
		var registry_obj := level.level_registry[id]
		if registry_obj is Character:
			var team_id = registry_obj.get_player_team_id()
			if not alive_ids.has(team_id):
				alive_ids.append(team_id)
	
	return team_ids.size() == alive_ids.size()

## Start the game from pregame.
func start_game():
	print("Starting game.")
	match_state.set_match_time(MATCH_DURATION)
	next_round()

## Moves onto the next round starting in the preptime phase.
func next_round():
	clean_level()
	await get_tree().process_frame
	match_state.set_intermission_time(INTERMISSION_DURATION)
	match_state.set_state_of_match(match_state.StateOfMatch.PREPTIME)
	if network_manager.is_host():
		match_state.set_current_round()

## Starts after preptime, actually, continuing into the match.
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
	print(scoring_character.owning_player_id, " has scored!")
	# Add a point to the player's team.
	match_state.set_team_score(match_state.player_states[scoring_character.owning_player_id].team_id)
	level.score_effect(scoring_character)


func _on_match_timer_timeout():
	if not network_manager.is_host(): return
	if match_state.is_match():
		match_state.set_match_time()
		if match_state.match_time <= 0: end_timer()
	else:
		match_state.set_intermission_time()
		if match_state.intermission_time <= 0: end_timer()


## Called when the timer counts down to 0.
func end_timer() -> void:
	match match_state.state_of_match:
		match_state.StateOfMatch.PREGAME: # Pregame timer. ran out, start game. This is the same for all gamemodes.
			start_game()
		match_state.StateOfMatch.PREPTIME: # Prep time pre round, starts the round after this.
			start_round()
		match_state.StateOfMatch.MATCH: # Main match timer. When this runs out, game ends. This logic should be done in sub gamemodes
			if get_winning_team() >= 0:
				end_game(get_winning_team())
		match_state.StateOfMatch.CELEBRATION: # Celebration time after the end of a round. Starts next round after.
			next_round()
		match_state.StateOfMatch.ENDGAME: # End of the game. Players will vote and the most voted map will be transitioned to. This is also the same per gamemode
			var main_scene: MainScene = get_tree().current_scene
			main_scene.load_level(match_state.get_winning_vote())

## If there is a team that wins here, return their team id. else, return -1
func get_winning_team() -> int:
	return -1

## Automatically assigns the player a team. By default, assigns to team with least players.
func auto_assign_player_team(player_id: int):
	if network_manager.is_in_lobby(): print("Auto assigning ", player_id)
	if match_state.get_team_ids().size() == 1:
		match_state.assign_player_team(player_id, 0)
		return
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
	
	match_state.assign_player_team(player_id, lowest_team)




## Spawns a character for each player.
func spawn_omnistrikers() -> void:
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
				var spawn_dict: Dictionary = {"owner_id": player_id}
				if inventory_memory.has(player_id):
					spawn_dict["inventory"] = inventory_memory[player_id]["inv"]
					#spawn_dict["equipped_key"] = inventory_memory[player_id]["omni_ek"]
				level.spawn_character(load("res://scenes/level/characters/omnistriker.tscn"), spawn_position, spawn_dict)

## Cleans up the level, removing old stuff from registry.
func clean_level() -> void:
	inventory_memory.clear()
	for id in level.level_registry.keys():
		var registry_obj: Node3D = level.level_registry[id]
		if registry_obj is Omnistriker:
			var omni_inventory: Dictionary = {}
			omni_inventory["inv"] = registry_obj.inventory_component.to_dict(true)
			omni_inventory["omni_ek"] = registry_obj.equipped_key
			inventory_memory[registry_obj.owning_player_id] = omni_inventory
		level.despawn_registry_object(id)
	
	## Clean ragdoll scenes as well.
	for child in level.get_children():
		if child is Ragdoll:
			child.queue_free()

## Adds points to the given player.
func add_player_points(player_id: int, points: int) -> void:
	var player_state: PlayerState = match_state.get_player_state(player_id)
	var player_current: int = player_state.current_score
	var player_total: int = player_state.total_score
	match_state.set_player_score(player_id, player_current + points, player_total + points)

## Awards points to players in the given team, distributing them evenly. Awards bonus points to keys in the bonus dictionary with value.
func add_team_points(team_id: int, points: int, bonus: Dictionary[int, int] = {}) -> void:
	var team_players := match_state.get_team_players(team_id)
	for player_id in team_players:
		@warning_ignore("integer_division")
		var award_points: int = points / team_players.size()
		if bonus.has(player_id):
			award_points += bonus[player_id]
		add_player_points(player_id, award_points)


## Spends (removes) points from the given player.
func spend_player_points(player_id: int, points: int) -> void:
	var player_state: PlayerState = match_state.get_player_state(player_id)
	var player_current: int = player_state.current_score
	var player_total: int = player_state.total_score
	match_state.set_player_score(player_id, player_current - points, player_total)

func can_player_afford(buyer_id: int, cost: int) -> bool:
	return match_state.get_player_state(buyer_id).can_afford(cost)

## Has a player purchase a givne item.
func purchase_item(character: Character, item_resource: ItemResource) -> void:
	var buyer_id: int = character.owning_player_id
	var cost: int = item_resource.item_cost
	print(buyer_id, " wants to buy ", item_resource.item_name)
	if can_player_afford(buyer_id, cost):
		spend_player_points(buyer_id, cost)
		var new_item := ItemState.new()
		new_item.item_resource = item_resource
		if character.is_inventory_full():
			character.drop_equipped_item()
			await get_tree().process_frame
		character.pickup_item(new_item)

## Returns true if this is a state of match where players can move.
func is_unlocked_state() -> bool:
	return match_state.state_of_match == match_state.StateOfMatch.MATCH

## Returns all team resources.
func get_all_teams(avoid_home: bool = false) -> Array[TeamResource]:
	var all_teams = teams
	if avoid_home: all_teams.erase(level.get_level_resource().home_team)
	return all_teams
