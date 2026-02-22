## Tackle component of the character.

extends Node

class_name TackleComponent

## Owning character.
@onready var character: Character = self.get_parent()
## Network manager.
@onready var network_manager: NetworkManager = get_tree().current_scene.network_manager

## The minimum speed a character must be going to tackle another.
const MINIMUM_TACKLE_SPEED := 5.0

## Whether or not the character is tackled and cannot move.
var is_tackled := false
## The current charge move speed of the character.
var current_charge_speed: float

## Called when self collides with another character.
func on_charge_collide(collider: Character, _collision: KinematicCollision3D):
	if not collider.is_tackled:
		print(Steam.getFriendPersonaName(character.owning_player_id), " has charged into ", Steam.getFriendPersonaName(collider.owning_player_id))
		var hit_direction := (collider.global_position-character.global_position).normalized() # The direction from self to collider.
		
		var self_velocity := character.velocity.dot(hit_direction)
		var collider_velocity := collider.velocity.dot(-hit_direction)
		
		if self_velocity > collider_velocity and self_velocity > MINIMUM_TACKLE_SPEED:
			print("Colliding with ", self_velocity, "+", collider_velocity)
			current_charge_speed = (current_charge_speed - 8.0) if current_charge_speed > 8.0 else 0.0
			collider.tackle(character, self_velocity + collider_velocity)

## Called when self is tackled by another node.
func tackle(tackler: Node3D, tackle_force: float) -> void:
	if not is_tackled:
		is_tackled = true
		character.get_node("CollisionShape3D").disabled = true
		print(Steam.getFriendPersonaName(character.owning_player_id), " has been tackled by ", Steam.getFriendPersonaName(tackler.owning_player_id), " with a force of ", tackle_force)
		# Shake camera.
		if character.is_locally_possessed():
			character.get_node("CameraHandle").tackle_shake(tackle_force)
		if network_manager.is_host():
			# Send packet
			network_manager.send_p2p_packet(0, {"m": network_manager.Message.CHARACTER_TACKLED, "id": character.registry_id, "tid": tackler.registry_id, "tf": tackle_force})
			# Drop all items.
			character.drop_all_items()
			
			# Reset movement.
			character.velocity.x = 0
			character.velocity.z = 0
			current_charge_speed = 0
			await get_tree().create_timer(4).timeout
			recover()
			

## Called when self recovers from being tackled.
func recover() -> void:
	if is_tackled:
		is_tackled = false
		character.get_node("CollisionShape3D").disabled = false
		print(Steam.getFriendPersonaName(character.owning_player_id), " has recovered from being tackled.")
		if network_manager.is_host():
			network_manager.send_p2p_packet(0, {"m": network_manager.Message.CHARACTER_RECOVERED, "id": character.registry_id})
			
