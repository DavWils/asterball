## Resource for effect types.

extends Resource

class_name EffectResource

## Name of this effect.
@export var effect_name: String
## Brief description of the effect.
@export var effect_description: String
## Maximum number of stacks this effect can have. -1 means infinite.
@export var max_stacks: int = -1
## If true, effect is meant to last infinitely.
@export var infinite_duration: bool = false
## The modifiers this passive applies.
@export var modifiers: Array[Modifier]
