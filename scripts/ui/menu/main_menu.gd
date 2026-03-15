extends Control

@onready var tab_container: TabContainer = $TabContainer

@onready var network_manager: NetworkManager = get_tree().current_scene.get_node("NetworkManager")

var fail_connect_tween: Tween

## Transitions to title screen.
func to_title_screen() -> void:
	tab_container.current_tab = 0

## Transitions to options menu.
func to_options() -> void:
	tab_container.current_tab = 1

## Transitions to credits.
func to_credits() -> void:
	tab_container.current_tab = 2

## Transition to host.
func to_host() -> void:
	$TabContainer/HostUI.set_default_session_name()
	tab_container.current_tab = 3

func _ready() -> void:
	network_manager.steam_initialized.connect(_on_steam_initialized)
	_on_steam_initialized(not network_manager.is_steam_initialized)
	await get_tree().process_frame
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	$NoConnectionButton.pressed.connect(_on_ncb_pressed)

func _on_ncb_pressed() -> void:
	$NoConnectionButton.disabled = true
	$NoConnectionButton/ConnectingProgressBar.visible = true
	await get_tree().create_timer(2).timeout
	network_manager.connect_to_steam()
	

func _on_steam_initialized(status: int) -> void:
	if status == 0:
		$NoConnectionButton.visible = false
	else:
		if fail_connect_tween:
			fail_connect_tween.kill()
		fail_connect_tween = create_tween()
		$NoConnectionButton.modulate = Color.RED
		fail_connect_tween.tween_property($NoConnectionButton, "modulate", Color.WHITE, 0.5)
	$NoConnectionButton.disabled = false
	$NoConnectionButton/ConnectingProgressBar.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_menu") and tab_container.current_tab != 0:
		to_title_screen()
