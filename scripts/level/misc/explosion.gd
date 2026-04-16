extends Node3D

class_name Explosion

## Reference to the game's network manager.
@onready var network_manager: NetworkManager = get_tree().current_scene.get_node("NetworkManager")
## Reference to player controller.
@onready var local_char: Character = get_tree().current_scene.get_node("Level").get_node("PlayerController").current_character

## Minimum score necessary to tackle.
const MIN_TACKLE_SCORE: float = 10.0

## Explosion intensity, meaning higher tackle scores.
@export var explosion_intensity: float = 1.0



func _ready() -> void:
	$ExplosionAudioPlayer.pitch_scale = randf_range(0.9,1.2)
	$ShockwaveAudioPlayer.pitch_scale = randf_range(0.9,1.2)
	$Timer.timeout.connect(_on_timeout)
	
	if network_manager.is_host():
		network_manager.send_p2p_packet(0, {"m": network_manager.Message.SPAWN_EXPLOSION, "pos": position, "path": scene_file_path})
	
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	explode()

func _on_timeout() -> void:
	queue_free()

func explode() -> void:
	print("Exploded with ", $Area3D.get_overlapping_bodies(), " bodies.")
	for player in [$ExplosionAudioPlayer, $ShockwaveAudioPlayer]:
		if player.stream:
			player.play()
	if has_node("AnimationPlayer"):
		$AnimationPlayer.play("explode")
	$Timer.start()
	if network_manager.is_host():
		for body in $Area3D.get_overlapping_bodies():
			if body is Projectile:
				body.apply_central_impulse(get_explosion_force(body.global_position))
			elif body is PhysicalBone3D:
				body.apply_central_impulse(get_explosion_force(body.global_position))
			elif body is Character:
				var score := get_tackle_score(body, get_explosion_force(body.global_position))
				if score >= MIN_TACKLE_SCORE:
					body.tackle(self, score)
				else:
					body.velocity += get_explosion_force(body.global_position) / body.get_total_mass()
	
	# Camera shake.
	if local_char:
		var dist := position.distance_to(local_char.position)
		var falloff: float = clamp(1.0 - ((dist / 10.0) / explosion_intensity), 0.0, 1.0)
		var force: float = explosion_intensity * falloff * 30.0
		local_char.get_node("CameraHandle").camera_shake(force)

## Returns the tackle score of this explosion towards the given character.
func get_tackle_score(character: Character, impulse: Vector3) -> float:
	
	var offset := character.position - global_position
	if offset.length_squared() == 0:
		offset = Vector3.UP
	
	var dir := offset.normalized()
	
	var explosion_score := impulse.dot(dir)
	
	var final_score = explosion_score - character.get_tackle_resistance()
	
	print("Explosion Tackle Calculation: ", explosion_score, " - ", character.get_tackle_resistance(), " = ", final_score)
	return final_score


func get_explosion_force(target_pos: Vector3) -> Vector3:
	var explosion_pos = global_position
	var dir = target_pos - explosion_pos
	var distance = max(dir.length(), 0.1)
	var radius = $Area3D/CollisionShape3D.shape.radius
	if distance > radius:
		return Vector3.ZERO
	
	if dir == Vector3.ZERO: dir = Vector3.UP
	distance = max(distance, 0.001)
	
	dir = dir.normalized()
	
	
	var falloff = pow(1.0 - (distance / radius), 2)
	var force = 1000.0 * explosion_intensity * falloff
	print(dir, " * ", force)
	
	return dir * force
