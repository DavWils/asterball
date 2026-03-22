## Script for the credits screen in main menu

extends Control

@onready var main_menu: Control = get_parent().get_parent()
@onready var main_scene: MainScene = get_tree().current_scene

## The box in which session cards will be added.
@export var session_box: VBoxContainer
## The session card control.
@onready var session_card_res := load("res://scenes/ui/main_menu/find_game_menu/session_card.tscn")

func _ready() -> void:
	$RefreshButton.pressed.connect(_on_refresh_pressed)
	$VBoxContainer/ReturnButton.pressed.connect(_on_return_pressed)
	$FilterNameTextEdit.text_changed.connect(_on_filter_name_text_changed)

func _on_filter_name_text_changed(new_text: String) -> void:
	show_filtered_sessions({"name": new_text})

func _on_refresh_pressed() -> void:
	load_sessions()

func _on_return_pressed() -> void:
	main_menu.to_title_screen()
	

func load_sessions() -> void:
	$FilterNameTextEdit.text = ""
	for child in session_box.get_children():
		child.queue_free()
	$Panel/LoadingBar.visible = true
	$SessionCountLabel.text = "Games: ..."
	
	Steam.requestLobbyList()
	await Steam.lobby_match_list
	show_filtered_sessions()
	$Panel/LoadingBar.visible = false

func show_filtered_sessions(filter: Dictionary = {}) -> void:
	# Remove old children
	for child in session_box.get_children():
		child.queue_free()
	
	var filtered_lobby_count: int = 0
	for lobby in main_scene.found_lobbies:
		var new_card: Control = session_card_res.instantiate()
		new_card.session_id = lobby
		var pass_filter := false
		if filter.has("name"):
			pass_filter = (Steam.getLobbyData(lobby, "lobby_name").to_lower()).contains(filter["name"].to_lower()) or filter["name"] == ""
		else:
			pass_filter = true 
		
		if pass_filter:
			filtered_lobby_count += 1
			session_box.add_child(new_card)
	
	if filtered_lobby_count == main_scene.found_lobbies.size():
		$SessionCountLabel.text = "Games: " + str(filtered_lobby_count)
	else:
		$SessionCountLabel.text = "Games: " + str(filtered_lobby_count) + "/" + str(main_scene.found_lobbies.size())
