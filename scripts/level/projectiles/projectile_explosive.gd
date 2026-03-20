## Sub class of projectile that explodes.

extends Projectile

class_name ProjectileExplosive

## Whether or not to explode whne hitting a character.
@export var explode_on_overlap: bool = false
## Whether or not to explode when hitting a surface
@export var explode_on_collide: bool = false
## The scene to use for an explosion from this projectile.
@export var explosion_scene: PackedScene = null

## If true, despawn on explosion.
@export var despawn_on_explosion: bool

func character_overlap(character: Character):
	if network_manager.is_host():
		if explode_on_overlap and throwing_character:
			if explosion_scene:
				spawn_explosion()
	super.character_overlap(character)

func surface_collide(body: Node3D) -> void:
	if network_manager.is_host():
		if explode_on_collide and throwing_character:
			if explosion_scene:
				spawn_explosion()
	super.surface_collide(body)


func spawn_explosion() -> void:
	var explosion = explosion_scene.instantiate()
	explosion.position = position
	level.add_child(explosion)
	despawn_projectile()
