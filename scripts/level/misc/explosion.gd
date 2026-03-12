extends Node3D

## Reference to the game's network manager.
@onready var network_manager: NetworkManager = get_tree().current_scene.get_node("NetworkManager")

## Minimum score necessary to tackle.
const MIN_TACKLE_SCORE: float = 10.0

## Explosion intensity, meaning larger radius and higher damage.
@export var explosion_intensity: float = 1.0

func _ready() -> void:
	while true:
		if network_manager.is_host():
			explode()
		await get_tree().create_timer(5).timeout

func explode() -> void:
	$Area3D/CollisionShape3D.shape.radius = 5*explosion_intensity
	print("Exploded with ", $Area3D.get_overlapping_bodies(), " bodies.")
	
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
					body.velocity += body.velocity/body.get_total_mass()

## Returns the tackle score of this explosion towards the given character.
func get_tackle_score(character: Character, impulse: Vector3) -> float:
	var target_momentum := character.get_momentum()
	
	var offset := character.global_position - global_position
	if offset.length_squared() == 0:
		return 0
	
	var dir := offset.normalized()
	
	var explosion_score := impulse.dot(dir)
	var target_score := -target_momentum.dot(dir)
	
	return (10*explosion_score) - target_score

func get_explosion_force(target_pos: Vector3) -> Vector3:
	var explosion_pos = global_position
	var dir = target_pos - explosion_pos
	var distance = dir.length()
	
	var radius = 5 * explosion_intensity
	if distance > radius:
		return Vector3.ZERO
	
	dir = dir.normalized()
	
	var falloff = pow(1.0 - (distance / radius), 2)
	var force = 50.0 * explosion_intensity * falloff
	
	return dir * force
