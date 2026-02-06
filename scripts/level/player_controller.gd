extends Node

class_name PlayerController

## Reference to the game's network manager.
@onready var network_manager: NetworkManager = get_tree().current_scene.get_node("NetworkManager")

## The currently controlled character.
var current_character: Character
## Current camera player is spectating through. Unused when possessing a character.
@onready var current_camera: Camera3D = $Camera3D

## The current look delta that is saved until a movement input is calculated.
var look_input := Vector2.ZERO

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

func _unhandled_input(event: InputEvent) -> void:
	if current_character:
		# Interact input.
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
				current_character.drop_equipped_item()
			else:
				network_manager.send_p2p_packet(network_manager.get_host_id(), {"m": network_manager.Message.CLIENT_DROP})
		elif event.is_action_pressed("previous_equipment"):
			if current_character.get_inventory_count() > 0:
				var new_index = (current_character.get_node("InventoryComponent").equipment_index-1+current_character.get_inventory_count())%current_character.get_inventory_count()
				equip_by_index(new_index)
		elif event.is_action_pressed("next_equipment"):
			if current_character.get_inventory_count() > 0:
				var new_index = (current_character.get_node("InventoryComponent").equipment_index+1)%current_character.get_inventory_count()
				equip_by_index(new_index)
	
	if event is InputEventMouseMotion:
		look_input += event.relative

## Equips an item by index on character.
func equip_by_index(index: int):
	current_character.equip_item(index)

func _physics_process(delta: float) -> void:
	# Get input and either use it or send it to host.
	if current_character:
		# Create input dictionary
		var input_dictionary: Dictionary
		input_dictionary["mv"] = Input.get_vector("move_left", "move_right", "move_forward", "move_backward") # Movement input.
		input_dictionary["lk"] = look_input # Looking input.
		input_dictionary["ch"] = Input.is_action_pressed("charge") # Charging input.
		look_input = Vector2.ZERO
		
		# Use input.
		current_character.use_player_input(input_dictionary, delta)
		# If we're not the host, send the host our input as well.
		if not network_manager.is_host():
			network_manager.send_p2p_packet(
				network_manager.get_host_id(),
				{
					"m": network_manager.Message.CLIENT_CHAR_INPUT, # Message. Player input.
					"id": current_character.registry_id, # Character id
					"d": delta,
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
		#print("New most desired interactable is ", desired_interactable.name)
		if desired_interactable is Pickup:
			pass
			#print(desired_interactable, " is a pickup of item ", desired_interactable.item_state.item_resource.item_name)
	else:
		pass
		#print("No desired interactable now.")
