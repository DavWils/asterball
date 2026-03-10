extends AudioStreamPlayer3D

## Linear volume of the sound when equipped
const EQUIP_VOLUME: float = 0.2

## Linear volume of the sound as a projectile.
const PROJECTILE_VOLUME: float = 1.0


## The object we get velocity from.
var interest_node: Node3D
## Whether or not interest node is a character.
var is_character_interest: bool = false

func _ready() -> void:
	interest_node = self.get_parent()
	if interest_node is Equipment: 
		interest_node = interest_node.wielder
		is_character_interest = true
		volume_linear = PROJECTILE_VOLUME
	else:
		volume_linear = EQUIP_VOLUME

func _process(_delta) -> void:
	var new_pitch: float = clampf(1.0+(get_interest_velocity()/25.0), 1.0, 2.0)
	pitch_scale = lerp(pitch_scale, new_pitch, 0.2)
	volume_linear = lerp(volume_linear, EQUIP_VOLUME if is_character_interest else PROJECTILE_VOLUME, 0.2)

func get_interest_velocity() -> float:
	if is_character_interest:
		return (interest_node as Character).velocity.length()
	else:
		return (interest_node as Projectile).linear_velocity.length()
