extends HBoxContainer

## The steam id of the player represented here.
var player_id: int

## Reference to match state
@onready var match_state: MatchState = get_tree().current_scene.get_node("Level").get_node("MatchState")
## Reference to network manager.
@onready var network_manager = get_tree().current_scene.network_manager

func _ready() -> void:
	Steam.avatar_loaded.connect(_on_loaded_avatar)
	if network_manager.is_in_lobby(): 
		Steam.getPlayerAvatar(Steam.AvatarSizes.AVATAR_SMALL, player_id)
		$NameLabel.text = Steam.getFriendPersonaName(player_id)
	else:
		$NameLabel.text = "Player"
	var player_state = match_state.get_player_state(player_id)
	player_state.scores_changed.connect(_on_scores_changed)
	_on_scores_changed(player_state.current_score, player_state.total_score)


## When avatar is received set this ui's image. 
func _on_loaded_avatar(user_id: int, avatar_size: int, avatar_buffer: PackedByteArray) -> void:
	if user_id == player_id:
		var avatar_image: Image = Image.create_from_data(avatar_size, avatar_size, false, Image.FORMAT_RGBA8, avatar_buffer)
		$PlayerIcon.texture = ImageTexture.create_from_image(avatar_image)

## When player score changes.
func _on_scores_changed(current: int, total: int):
	$ScoreLabel.text = get_score_text(current)+"/"+get_score_text(total)

## Given a score number return it as a formatted string.
func get_score_text(score: int) -> String:
	if score > 10000000:
		# Over 10 million, return #m
		@warning_ignore("integer_division")
		return str(score/1000000)+"m"
	elif score >= 1000000:
		# Over 1 million, return #.#m
		@warning_ignore("integer_division")
		var millions = score/1000000
		@warning_ignore("integer_division")
		return str(millions)+"."+str((score-(millions*1000000))/100000)+"m"
	elif score >= 10000:
		# Over 10 thousand, return #k
		@warning_ignore("integer_division")
		return str(score/1000)+"k"
	elif score >= 1000:
		# Over 1000, return #.#k
		@warning_ignore("integer_division")
		var thousands = score/1000
		@warning_ignore("integer_division")
		return str(thousands)+"."+str((score-(thousands*1000))/100)+"k"
	else:
		# Under 1000, return #
		return str(score)
