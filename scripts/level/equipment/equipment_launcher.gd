extends Equipment

class_name EquipmentLauncher

@export var launcher_projectile: ItemResource

@export var launch_velocity: float

@export var fire_on_start: bool = false

func use_start() -> void:
	super.use_start()
	if fire_on_start:
		fire_projectile()

func fire_projectile() -> void:
	var new_item_state := ItemState.new()
	new_item_state.item_resource = launcher_projectile
	var start_position = wielder.position + Vector3.UP*2.0 + -wielder.transform.basis.z
	var launched_projectile: Projectile = level.spawn_projectile(launcher_projectile.get_projectile_scene(), start_position, {"item_state": new_item_state.to_dict(), "thrower_id": wielder.registry_id})
	launched_projectile.linear_velocity = launch_velocity * -wielder.transform.basis.z
	if has_node("AnimationPlayer"):
		for child in get_children():
			if child is GPUParticles3D:
				child.restart()
		$AnimationPlayer.play("fire")
	if has_node("FireAudioPlayer"):
		$FireAudioPlayer.pitch_scale = randf_range(0.9,1.1)
		$FireAudioPlayer.play()
