## Tackle component of the character.

extends Node

class_name TackleComponent

## Owning character.
@onready var character: Character = self.get_parent()
## Network manager.
@onready var network_manager: NetworkManager = get_tree().current_scene.network_manager

## The minimum speed a character must be going to tackle another.
const MINIMUM_TACKLE_SCORE: float = 1000.0

## Whether or not the character is tackled and cannot move.
var is_tackled := false
## The code that the player must use to untackle themself
var recovery_code: Array[int]
## Completion marker for recovery, marking the index the player is currently at.
var recovery_progress: int

## Check for collisions
func _physics_process(_delta: float) -> void:
	if network_manager.is_host():
		for i in range(character.get_slide_collision_count()):
			var collision := character.get_slide_collision(i)
			var collider := collision.get_collider()
			if character.is_charging() and collider is Character:
				on_charge_collide(collider, collision)
				

## Returns the tackle score of this character towards another.
func get_tackle_score(target: Character) -> float:
	var self_momentum := character.get_momentum()
	var target_momentum := target.get_momentum()
	
	var offset := target.position - character.position
	if offset.length_squared() == 0:
		return 0
	
	var dir := offset.normalized()
	
	var self_score := self_momentum.dot(dir)
	var target_score := -target_momentum.dot(dir)
	return self_score - target_score

## Called when self collides with another character.
func on_charge_collide(collider: Character, _collision: KinematicCollision3D):
	if not collider.is_tackled():
		var tackle_score := get_tackle_score(collider)
		print(Steam.getFriendPersonaName(character.owning_player_id), " has charged into ", Steam.getFriendPersonaName(collider.owning_player_id), " with a score of ", tackle_score)
		
		if tackle_score >= MINIMUM_TACKLE_SCORE:
			collider.tackle(character, tackle_score)

## Called when self is tackled by another node.
func tackle(tackler: Node3D, tackle_score: float, tackle_seed: RandomNumberGenerator) -> void:
	if not is_tackled:
		is_tackled = true
		print(Steam.getFriendPersonaName(character.owning_player_id), " has been tackled by ", Steam.getFriendPersonaName(tackler.owning_player_id) if tackler is Character else tackler.item_state.item_resource.item_name, " with a force of ", tackle_score)
		$TackleAudioPlayer.play()
		
		# Generate the recovery code.
		var recovery_length: int = max(1, round(5*(log(tackle_score)/log(10))+2))
		print("Tackle score of ", tackle_score, " leads to a length of ", recovery_length)
		recovery_code.clear()
		recovery_progress = -1
		for i in recovery_length:
			recovery_code.append(tackle_seed.randi()%4)
		
		
		# Shake camera.
		if network_manager.is_host():
			# Send packet
			network_manager.send_p2p_packet(0, {"m": network_manager.Message.CHARACTER_TACKLED, "id": character.registry_id, "tid": tackler.registry_id, "ts": tackle_score, "seed": tackle_seed.seed})
			# Drop all items.
			character.drop_all_items()
			
			# Reset movement.
			character.velocity.x = 0
			character.velocity.z = 0

## Called when self recovers from being tackled.
func recover() -> void:
	if is_tackled:
		is_tackled = false
		print(Steam.getFriendPersonaName(character.owning_player_id), " has recovered from being tackled.")
		if network_manager.is_host():
			network_manager.send_p2p_packet(0, {"m": network_manager.Message.CHARACTER_RECOVERED, "id": character.registry_id})
			

## Enters a recovery key in hopes of reducing the code. Returns true if successful, and false if wrong key.
func enter_recovery_key(key: int) -> bool:
	if recovery_code[recovery_progress+1] == key:
		set_recovery_code_progress(recovery_progress+1)
		return true
	else:
		if recovery_progress >= 0:
			set_recovery_code_progress(recovery_progress-1)
		return false

## Offsets the recovery code by given value
func set_recovery_code_progress(progress: int) -> void:
	if progress == recovery_progress: return
	recovery_progress = progress if progress >= 0 else 0
	print("Recovery progress for "+ Steam.getFriendPersonaName(character.owning_player_id) +": ", recovery_progress)
	for key in recovery_code.size():
		var key_str: String
		match recovery_code[key]:
			0:
				key_str = "W"
			1:
				key_str = "A"
			2:
				key_str = "S"
			3:
				key_str = "D"
		if key == recovery_progress:
			print("["+str(key_str)+"]")
		elif key == recovery_progress+1:
			print(key_str, "<-")
		else:
			print(key_str)
	if network_manager.is_host():
		network_manager.send_p2p_packet(0, {"m": network_manager.Message.CHARACTER_RECOVERY_PROGRESS, "char_id": character.registry_id, "progress": recovery_progress})
		if recovery_code.size() <= recovery_progress+1:
			character.recover()
	elif character.is_locally_possessed():
		network_manager.send_p2p_packet(network_manager.get_host_id(), {"m": network_manager.Message.CLIENT_RECOVERY_PROGRESS, "char_id": character.registry_id, "progress": recovery_progress})
