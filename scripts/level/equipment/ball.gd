## Script for the ball as an equipment item.

extends Equipment

func _ready() -> void:
	super._ready()
	var wielder_overlap_area: Area3D = wielder.get_node("OverlapArea3D")
	wielder_overlap_area.area_entered.connect(_on_area_entered)
	for body in wielder_overlap_area.get_overlapping_areas():
		if body is ScoreZone:
			overlap_score_zone(body)
	
	add_slowdown()
	$SlowdownTimer.timeout.connect(_on_timeout)

func _exit_tree() -> void:
	super._exit_tree()
	wielder.remove_effect(load("res://resources/effects/ball_slow.tres"))

func _on_timeout() -> void:
	add_slowdown()

func add_slowdown() -> void:
	if network_manager.is_host():
		wielder.add_effect(EffectState.new(load("res://resources/effects/ball_slow.tres"), 15))

func _on_area_entered(body: Node3D):
	if network_manager.is_host():
		if body is ScoreZone:
			overlap_score_zone(body)


## Called when player overlaps with a scorezone
func overlap_score_zone(body: ScoreZone) -> void:
	if not level.match_state.state_of_match == level.match_state.StateOfMatch.MATCH: return
	if body.owning_team != wielder.get_player_team_id():
		print("Score!")
		level = get_tree().current_scene.get_node("Level")
		level.match_director.score(wielder)
