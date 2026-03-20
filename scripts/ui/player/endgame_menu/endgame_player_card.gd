extends Node

@onready var network_manager: NetworkManager = get_tree().current_scene.get_node("NetworkManager")
@onready var match_state: MatchState = get_tree().current_scene.get_node("Level").get_node("MatchState")

var player_placement: int
var player_id: int
var player_score: int

func _ready() -> void:
	Steam.avatar_loaded.connect(_on_loaded_avatar)
	if network_manager.is_on_steam():
		Steam.getPlayerAvatar(Steam.AvatarSizes.AVATAR_SMALL, player_id)
		$PlacementLabel.text = str(player_placement) + get_ordinal(player_placement)
		$VBoxContainer/NameLabel.text = Steam.getFriendPersonaName(player_id)
		$VBoxContainer/ScoreLabel.text = get_score_text(player_score) + " pts"

## When avatar is received set this ui's image. 
func _on_loaded_avatar(user_id: int, avatar_size: int, avatar_buffer: PackedByteArray) -> void:
	if user_id == player_id:
		var avatar_image: Image = Image.create_from_data(avatar_size, avatar_size, false, Image.FORMAT_RGBA8, avatar_buffer)
		$TextureRect.texture = ImageTexture.create_from_image(avatar_image)


func get_ordinal(placement: int) -> String:
	if placement % 100 >= 11 and placement % 100 <= 13:
		return "th"
	
	match placement % 10:
		1:
			return "st"
		2:
			return "nd"
		3:
			return "rd"
		_:
			return "th"

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
