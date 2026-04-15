extends Control

class_name MainMenuUI

@onready var tab_container: TabContainer = $TabContainer

@onready var network_manager: NetworkManager = get_tree().current_scene.get_node("NetworkManager")

var fail_connect_tween: Tween
## Button to display when not connected to steam.
@export var no_connection_button: Button

## Transitions to title screen.
func to_title_screen() -> void:
	tab_container.current_tab = tab_container.get_tab_idx_from_control($TabContainer/TitleScreenUI)

func to_find_game() -> void:
	tab_container.current_tab = tab_container.get_tab_idx_from_control($TabContainer/FindGameUI)
	$TabContainer/FindGameUI.load_sessions()

## Transitions to options menu.
func to_options() -> void:
	tab_container.current_tab = tab_container.get_tab_idx_from_control($TabContainer/OptionsUI)

## Transitions to credits.
func to_credits() -> void:
	tab_container.current_tab = tab_container.get_tab_idx_from_control($TabContainer/CreditsUI)

## Transition to host.
func to_host() -> void:
	$TabContainer/HostUI.set_default_session_name()
	tab_container.current_tab = tab_container.get_tab_idx_from_control($TabContainer/HostUI)

func _ready() -> void:
	network_manager.steam_initialized.connect(_on_steam_initialized)
	_on_steam_initialized(not network_manager.is_on_steam())
	await get_tree().process_frame
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	no_connection_button.pressed.connect(_on_ncb_pressed)

func _input(event: InputEvent) -> void:
	if event is InputEventMouse and Input.get_mouse_mode() != Input.MOUSE_MODE_VISIBLE:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_ncb_pressed() -> void:
	if no_connection_button.disabled: return
	no_connection_button.disabled = true
	no_connection_button.get_node("ConnectingProgressBar").visible = true
	network_manager.connect_to_steam()
	

func _on_steam_initialized(status: int) -> void:
	if status == 0:
		ncb_success()
	else:
		ncb_fail()

## Play visual effect for when connection succeeds.
func ncb_success() -> void:
	if no_connection_button.visible:
		no_connection_button.visible = false
		get_tree().current_scene.get_node("UIAudioPlayer").play_pressed()
	no_connection_button.disabled = false
	no_connection_button.get_node("ConnectingProgressBar").visible = false


## Play visual effect for when connection fails.
func ncb_fail() -> void:
	if not no_connection_button.visible:
		no_connection_button.visible = true
	get_tree().current_scene.get_node("UIAudioPlayer").play_fail_purchased()
	if fail_connect_tween:
		fail_connect_tween.kill()
	fail_connect_tween = create_tween()
	no_connection_button.modulate = Color.RED
	fail_connect_tween.tween_property(no_connection_button, "modulate", Color.WHITE, 0.5)
	no_connection_button.disabled = false
	no_connection_button.get_node("ConnectingProgressBar").visible = false



func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_menu") and tab_container.current_tab != 0:
		to_title_screen()
