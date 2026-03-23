## Sub class of projectile that explodes.

extends ProjectileExplosive

@export var rocket_force: float = 10.0

func _ready() -> void:
	super._ready()
	if throwing_character:
		angular_velocity *= 0.0
		rotation = throwing_character.rotation
		rotation_degrees.x = throwing_character.control_pitch

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	apply_force(rocket_force * delta * -global_transform.basis.z)

func despawn_projectile():
	super.despawn_projectile()
