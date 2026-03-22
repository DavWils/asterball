## Resource for effect states.

extends Resource

class_name EffectState

## Resource used here.
var effect_resource: EffectResource
## The duration of this effect (seconds remaining).
var effect_duration: int
## The number of stacks of this effect.
var effect_stacks: int = 1


var time_interval: float = 0.0


func _init(resource: EffectResource = null, duration: int = 0):
	effect_resource = resource
	effect_duration = duration

## Ran from effects component every tick and is used to tick down the effect's duration.
func update_tick(delta: float) -> bool:
	if effect_resource.infinite_duration: return false
	time_interval += delta
	if time_interval >= 1.0:
		time_interval = 0.0
		return tick_effect_duration()
	return false

## Combines self with the given effect state.
func combine_effect(effect: EffectState) -> void:
	effect_duration = effect.effect_duration
	if effect_resource.max_stacks == -1:
		effect_stacks += effect.effect_stacks
	else:
		effect_stacks = min(effect_resource.max_stacks, effect_stacks + effect.effect_stacks)

## Converts dictionary to state.
func from_dict(data: Dictionary) -> void:
	effect_resource = load("res://resources/effects/" + data["effect_name"] + ".tres")
	
	effect_duration = data["duration"]

## Converts effect state to dictionary.
func to_dict() -> Dictionary:
	var data: Dictionary = {}
	data["effect_name"] = effect_resource.resource_path.get_file().get_basename()
	data["duration"] = effect_duration
	
	return data

## Ticks down the effect duration by one. Returns true if timer has run out.
func tick_effect_duration() -> bool:
	effect_duration -= 1
	return effect_duration <= 0
