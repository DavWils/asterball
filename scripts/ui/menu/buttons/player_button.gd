## Script for the player button, resembles a player, and can click to open profile.

extends Button

@onready var network_manager: NetworkManager = get_tree().current_scene.get_node("NetworkManager")

## ID of the player.
var player_id: int

func _ready() -> void:
	Steam.avatar_loaded.connect(_on_loaded_avatar)
	if network_manager.is_on_steam():
		Steam.getPlayerAvatar(Steam.AvatarSizes.AVATAR_SMALL, player_id)

## When avatar is received set this ui's image. 
func _on_loaded_avatar(user_id: int, avatar_size: int, avatar_buffer: PackedByteArray) -> void:
	if user_id == player_id:
		var avatar_image: Image = Image.create_from_data(avatar_size, avatar_size, false, Image.FORMAT_RGBA8, avatar_buffer)
		$TextureRect.texture = ImageTexture.create_from_image(avatar_image)
