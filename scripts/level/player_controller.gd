extends Node

class_name PlayerController

## Reference to the game's network manager.
@onready var network_manager: NetworkManager = get_tree().current_scene.get_node("NetworkManager")

## The currently controlled character.
var current_character: Character
## Current camera player is spectating through. Unused when possessing a character.
@onready var current_camera: Camera3D = $Camera3D
## Reference to player ui
@onready var player_ui = self.get_parent().get_node("PlayerUI")

## The current look delta that is saved until a movement input is calculated.
var look_input := Vector2.ZERO
## Whether or not player is currently paused. (in pause menu).
var paused: bool = false

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

## Sets the spectator camera. If null, disables it.
func set_spectator_camera(cam: Camera3D = null):
	if current_camera:
		current_camera.current = false
		current_camera = null
	if cam:
		cam.current = true
		current_camera = cam

## Possesses the given character.
func possess_character(character: Character) -> void:
	if current_character:
		unpossess_character()
	current_character = character
	current_character.set_current_camera(true)
	
	set_spectator_camera()
	
	# Bind signals
	# Interaction box signal.
	var interact_area: Area3D = current_character.get_node("InteractArea3D")
	interact_area.body_entered.connect(_on_interact_area_overlap)
	interact_area.body_exited.connect(_on_interact_area_overlap)

## Unpossesses the currently controlled character.
func unpossess_character() -> void:
	# Disable camera
	current_character.set_current_camera(false)
	# Disconnect signals.
	# Interaction box signal.
	var interact_area: Area3D = current_character.get_node("InteractArea3D")
	interact_area.body_entered.disconnect(_on_interact_area_overlap)
	interact_area.body_exited.disconnect(_on_interact_area_overlap)
	
	set_spectator_camera($Camera3D)
	
	# Forget character.
	current_character = null

## Enters input for a recovery key.
func enter_recovery_key_input(key: int) -> void:
	current_character.enter_recovery_key(key)


func _unhandled_input(event: InputEvent) -> void:
	if current_character:
		if player_ui.is_in_menu(): return
		# Tackle recovery input.
		if current_character.is_tackled():
			if event.is_action_pressed("move_forward"):
				enter_recovery_key_input(0)
			elif event.is_action_pressed("move_left"):
				enter_recovery_key_input(1)
			elif event.is_action_pressed("move_backward"):
				enter_recovery_key_input(2)
			elif event.is_action_pressed("move_right"):
				enter_recovery_key_input(3)
		# Interact input.
		if current_character.is_unlocked():
			if event.is_action_pressed("interact"):
				var interactable: Node3D = current_character.get_node("InteractArea3D").get_desired_interactable()
				if interactable:
					if interactable.has_method("interact"):
						print(interactable.get_interact_text())
						if network_manager.is_host():
							interactable.interact(current_character)
						else:
							network_manager.send_p2p_packet(network_manager.get_host_id(), {"m": network_manager.Message.CLIENT_INTERACT, "id": current_character.registry_id, "iid": interactable.registry_id})
			elif event.is_action_pressed("drop_equipment"):
				if network_manager.is_host():
					if not current_character.is_aiming():
						current_character.drop_equipped_item()
				else:
					network_manager.send_p2p_packet(network_manager.get_host_id(), {"m": network_manager.Message.CLIENT_DROP, "char_id": current_character.registry_id})
			elif event.is_action_pressed("previous_equipment"):
				if current_character.get_inventory_count() > 0:
					equip_by_key(current_character.inventory_component.get_prev_key())
			elif event.is_action_pressed("next_equipment"):
				if current_character.get_inventory_count() > 0:
					equip_by_key(current_character.inventory_component.get_next_key())
			elif event.is_action_pressed("aim_throw"):
				current_character.start_aim()
			elif event.is_action_released("aim_throw") or event.is_action_pressed("pause_menu"):
				if current_character.is_aiming():
					current_character.end_aim()
			elif event.is_action_pressed("use_item"):
				if current_character.is_aiming():
					current_character.start_throwing()
			elif event.is_action_released("use_item"):
				if current_character.is_aiming():
					current_character.stop_throwing()

	if event is InputEventMouseMotion:
		look_input += event.relative

## Has the character equip an inventory item by given key.
func equip_by_key(key: int) -> void:
	if network_manager.is_host():
		current_character.equip_item(key)
	else:
		network_manager.send_p2p_packet(network_manager.get_host_id(), {"m": network_manager.Message.CLIENT_REQUEST_EQUIP, "char_id": current_character.registry_id, "inventory_key": key})

func _physics_process(delta: float) -> void:
	# Get input and either use it or send it to host.
	if current_character:
		# Create input dictionary
		var input_dictionary: Dictionary
		# Move input.
		input_dictionary["mv"] = Input.get_vector("move_left", "move_right", "move_forward", "move_backward") # Movement input.
		# Look input, which is just the resulting rotation.
		var look_y = (current_character.rotation.y - (look_input.x*0.002))
		var look_x = (current_character.rotation.x if current_character.use_pitch_rotation else current_character.control_pitch) - (look_input.y*0.002)
		input_dictionary["lk"] = Vector2(look_x,look_y)
		look_input = Vector2.ZERO
		# Charge input.
		input_dictionary["ch"] = Input.is_action_pressed("charge") # Charging input.
		
		
		# Use input.
		current_character.use_player_input(input_dictionary)
		# If we're not the host, send the host our input as well.
		if not network_manager.is_host():
			network_manager.send_p2p_packet(
				network_manager.get_host_id(),
				{
					"m": network_manager.Message.CLIENT_CHAR_INPUT, # Message. Player input.
					"id": current_character.registry_id, # Character id
					"in": input_dictionary # Input
				}
			)
	else:
		# No current character. just moves the player controller around.
		var forward_vector: Vector3 = self.transform.basis.z
		var right_vector: Vector3 = self.transform.basis.x
		var move_input: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
		self.position += (forward_vector*move_input.y) + (right_vector*move_input.x)
		self.rotation.x = clampf(self.rotation.x - look_input.y * delta * 0.3, -PI/2, PI/2)
		self.rotation.y = self.rotation.y - (look_input.x * delta * 0.3)
		look_input = Vector2.ZERO

func _on_interact_area_overlap(_body: Node3D):
	var desired_interactable = current_character.get_node("InteractArea3D").get_desired_interactable()
	if desired_interactable:
		print("Current desired interactable is ", desired_interactable.name)
	else:
		print("No pickup")
