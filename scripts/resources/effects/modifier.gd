extends Resource

class_name Modifier

## The type of modifier
@export var modifier_type: ModifierType
## The value of the modifier.
@export var modifier_value: float
## Whether or not modifier_value is a percentage addition, as opposed to a flat value.
@export var is_percentage: bool = false

enum ModifierType {
	WALK_SPEED, ## Adds walk speed.
	AIR_CONTROL, ## Adds to air control.
	MAX_CHARGE, ## Adds to the maximum charge speed.
	CHARGE_ACCELERATION, ## Adds to charge acceleration.
	TACKLE_RESISTANCE, ## Adds to tackle resistance.
}
