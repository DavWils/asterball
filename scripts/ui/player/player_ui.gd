## Main player UI in the game level.

extends CanvasLayer

class_name PlayerUI

@onready var pause_menu: Control = $PauseMenu
@onready var buy_menu: Control = $BuyMenu
@onready var match_menu: Control = $MatchMenu
@onready var player_controller: PlayerController = get_tree().current_scene.get_node("Level").get_node("PlayerController")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_menu"):
		if is_paused():
			close_pause_menu()
		else:
			open_pause_menu()
	elif event.is_action_pressed("buy_menu"): # Toggle buy menu on press.
		if not is_paused() and player_controller.current_character: 
			if buy_menu.visible:
				close_buy_menu()
			else:
				open_buy_menu()
	elif event.is_action_pressed("match_menu"): # Open match menu on press.
		if not is_paused(): open_match_menu()
	elif event.is_action_released("match_menu"): # Close match menu on release
		close_match_menu()

## Returns true if paused.
func is_paused() -> bool:
	return player_controller.paused

## Returns true if in any menu.
func is_in_menu() -> bool:
	for ui in [pause_menu, buy_menu, match_menu]:
		if ui.visible: return true
	return false

func open_pause_menu() -> void:
	close_buy_menu()
	close_match_menu()
	pause_menu.visible = true
	player_controller.paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func close_pause_menu() -> void:
	pause_menu.visible = false
	player_controller.paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func open_buy_menu() -> void:
	close_match_menu()
	buy_menu.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)

func close_buy_menu() -> void:
	buy_menu.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func open_match_menu() -> void:
	close_buy_menu()
	match_menu.visible = true
	#Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)

func close_match_menu() -> void:
	match_menu.visible = false
	#Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(_delta: float) -> void:
	if player_controller:
		if player_controller.current_character:
			$SpeedLabel.text = "%.2f" % player_controller.current_character.get_real_velocity().length()
