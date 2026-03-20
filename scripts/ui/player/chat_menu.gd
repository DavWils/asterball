## Script for player chat menu.

extends Control

## Reference to level
@onready var level: Level = get_tree().current_scene.get_node("Level")
## Reference to match state.
@onready var match_state: MatchState = level.get_node("MatchState")
## Reference to network manager.
@onready var network_manager: NetworkManager = get_tree().current_scene.get_node("NetworkManager")
## Refernce to player controller
@onready var player_controller: PlayerController = level.get_node("PlayerController")
## Player UI
@onready var player_ui: PlayerUI = self.get_parent()

var current_channel: ChatChannel

@onready var message_control := load("res://scenes/ui/player/chat_menu/chat_message.tscn")

@export var message_box: VBoxContainer

enum ChatChannel {
	ALL,
	TEAM
}

func _ready() -> void:
	$ChatTextEdit.gui_input.connect(_on_gui_input)
	set_channel(ChatChannel.ALL)
	$VisibilityTimer.timeout.connect(_on_timeout)

func _on_timeout() -> void:
	$ChatScrollBox.visible = false

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventKey:
		# Example: consume the Enter key to prevent other nodes from using "ui_accept"
		if event.is_action_pressed("ui_accept"):
			var new_message: String = $ChatTextEdit.text
			if new_message == "": 
				get_viewport().set_input_as_handled()
				return
			send_message(network_manager.player_id, new_message, current_channel)
			close_chat()
			return
		elif event.is_action_pressed("pause_menu"):
			close_chat()
			get_viewport().set_input_as_handled()
		elif event.pressed and event.keycode == KEY_TAB:
			set_channel((((current_channel) + 1)%ChatChannel.size()) as ChatChannel)
			get_viewport().set_input_as_handled()

## Returns current channel as a string.
func get_channel_name() -> String:
	match current_channel:
		ChatChannel.ALL:
			return "ALL"
		ChatChannel.TEAM:
			return "TEAM"
	return ""


func set_channel(channel: ChatChannel) -> void:
	current_channel = channel
	print("Set Channel to ", channel)
	$ChannelPanel/Label.text = "[" + get_channel_name() + "]"

func open_chat() -> void:
	$ChatTextEdit.text = ""
	$ChatTextEdit.visible = true
	$ChannelPanel.visible = true
	$ColorRect.visible = true
	$VisibilityTimer.stop()
	$ChatScrollBox.visible = true
	
	await get_tree().process_frame
	$ChatTextEdit.grab_focus()

func close_chat() -> void:
	$ChatTextEdit.visible = false
	$ChannelPanel.visible = false
	$ColorRect.visible = false
	$VisibilityTimer.start()
	
	player_ui.close_chat()
	

## Returns true if the receiver can receive the given message given the chat channel.
func channel_filter(sender: int, receiver: int):
	match current_channel:
		ChatChannel.ALL:
			return true
		ChatChannel.TEAM:
			return match_state.get_player_team_id(sender) == match_state.get_player_team_id(receiver)

func receive_message(sender_id: int, message: String, channel: ChatChannel):
	print("[", channel, "]", Steam.getFriendPersonaName(sender_id), ": ", message)
	var new_message: Control = message_control.instantiate()

	new_message.set_message(sender_id, message, channel)
	message_box.add_child(new_message)
	await get_tree().process_frame
	$ChatScrollBox.scroll_vertical = 99999999 

func send_message(sender_id: int, message: String, channel: ChatChannel):
	if network_manager.is_host():
		for lobby_member in network_manager.lobby_members:
			if channel_filter(sender_id, lobby_member):
				if lobby_member != match_state.get_player_team_id(lobby_member):
					network_manager.send_p2p_packet(lobby_member, {"m": network_manager.Message.PLAYER_CHAT, "sender_id": sender_id, "message": message, "channel": channel})
				else:
					receive_message(sender_id, message, channel)
	else:
		network_manager.send_p2p_packet(network_manager.get_host_id(), {"m": network_manager.Message.CLIENT_REQUEST_CHAT, "sender_id": sender_id, "message": message, "channel": channel})
