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

func mod_to_string() -> String:
	match modifier_type:
		ModifierType.WALK_SPEED: return "Walk Speed"
		ModifierType.AIR_CONTROL: return "Air Control"
		ModifierType.MAX_CHARGE: return "Max Charge Speed"
		ModifierType.CHARGE_ACCELERATION: return "Charge Acceleration"
		ModifierType.TACKLE_RESISTANCE: "Tackle Resistance"
	return "Modifier " + str(modifier_type)
