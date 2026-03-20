## Main player UI in the game level.

extends CanvasLayer

class_name PlayerUI

@onready var pause_menu: Control = $PauseMenu
@onready var buy_menu: Control = $BuyMenu
@onready var match_menu: Control = $MatchMenu
@onready var tackle_overlay: Control = $TackleOverlay
@onready var throw_overlay: Control = $ThrowOverlay
@onready var player_controller: PlayerController = self.get_parent().get_node("PlayerController")
@onready var endgame_menu: Control = $EndgameMenu
@onready var level: Level = self.get_parent()
@onready var match_state: MatchState = level.get_node("MatchState")
@onready var chat_menu: Control = $ChatMenu

func _ready() -> void:
	player_controller.possessed.connect(_on_possessed)
	player_controller.unpossessed.connect(_on_unpossessed)
	match_state.state_of_match_set.connect(_on_state_of_match_set)

func _on_possessed(character: Character) -> void:
	character.tackled.connect(_on_tackled)
	character.recovered.connect(_on_recovered)
	character.tackle_component.recovery_progressed.connect(_on_recovery_progressed)
	character.throw_start.connect(_on_throw_start)
	character.throw_end.connect(_on_throw_end)
	player_controller.interactable_found.connect(_on_interactable_found)

func _on_unpossessed(character: Character) -> void:
	if character:
		character.tackled.disconnect(_on_tackled)
		character.recovered.disconnect(_on_recovered)
		character.tackle_component.recovery_progressed.disconnect(_on_recovery_progressed)
		character.throw_start.disconnect(_on_throw_start)
		character.throw_end.disconnect(_on_throw_end)
		player_controller.interactable_found.disconnect(_on_interactable_found)
	_on_recovered()
	_on_throw_end()
	close_buy_menu()

func _on_tackled() -> void:
	# Close buy menu when tackled.
	if buy_menu.visible:
		close_buy_menu()
	tackle_overlay.set_recovery_code(player_controller.current_character.tackle_component.recovery_code)
	show_tackle_overlay()
	

func _on_recovered() -> void:
	hide_tackle_overlay()

func _on_throw_start() -> void:
	show_throw_overlay()

func _on_throw_end() -> void:
	hide_throw_overlay()

func _on_recovery_progressed(progress: int) -> void:
	tackle_overlay.set_recovery_progress(progress)

func _on_interactable_found(interactable: Node3D) -> void:
	$InteractOverlay.visible = (interactable != null)
	$InteractOverlay.set_interactable(interactable)

func show_tackle_overlay() -> void:
	tackle_overlay.set_recovery_code(player_controller.current_character.tackle_component.recovery_code)
	tackle_overlay.set_recovery_progress(player_controller.current_character.tackle_component.recovery_progress)
	tackle_overlay.visible = true
	

func hide_tackle_overlay() -> void:
	tackle_overlay.visible = false

func show_throw_overlay() -> void:
	throw_overlay.visible = true

func hide_throw_overlay() -> void:
	throw_overlay.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_menu"):
		if is_paused():
			close_pause_menu()
		else:
			if buy_menu.visible:
				close_buy_menu()
			else:
				open_pause_menu()
	elif event.is_action_pressed("buy_menu"): # Toggle buy menu on press.
		if not is_paused() and player_controller.current_character: 
			if not player_controller.current_character.is_tackled():
				if buy_menu.visible:
					close_buy_menu()
				else:
					open_buy_menu()
	elif event.is_action_pressed("match_menu"): # Open match menu on press.
		if not is_paused(): open_match_menu()
	elif event.is_action_released("match_menu"): # Close match menu on release
		close_match_menu()
	elif event.is_action_pressed("open_chat"):
		if (not is_paused()):
			if endgame_menu.visible:
				pass
			else:
				open_chat()

## Returns true if paused.
func is_paused() -> bool:
	return player_controller.paused

## Returns true if in any menu.
func is_in_menu() -> bool:
	for ui in [pause_menu, buy_menu, endgame_menu]:
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
	pause_menu.get_node("TabContainer").current_tab = 0
	if not is_in_menu():
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func open_buy_menu() -> void:
	if endgame_menu.visible: return
	close_match_menu()
	buy_menu.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)

func close_buy_menu() -> void:
	buy_menu.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func open_match_menu() -> void:
	if endgame_menu.visible: return
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

func open_endgame_menu() -> void:
	close_buy_menu()
	close_match_menu()
	chat_menu.close_chat()
	endgame_menu.load_endgame()
	endgame_menu.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_state_of_match_set(state: MatchState.StateOfMatch) -> void:
	if state == MatchState.StateOfMatch.ENDGAME:
		open_endgame_menu()

func open_chat() -> void:
	chat_menu.open_chat()
	player_controller.paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func close_chat() -> void:
	player_controller.paused = false
	if not is_in_menu():
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func send_chat(sender: int, message: String, channel: int):
	if level.network_manager.is_on_steam():
		chat_menu.send_message(sender, message, channel)

func receive_chat(sender: int, message: String, channel: int):
	if level.network_manager.is_on_steam():
		chat_menu.receive_message(sender, message, channel)
