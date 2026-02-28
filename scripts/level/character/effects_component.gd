## Effects component of the character, controlling status effects.

extends Node

class_name EffectsComponent

## Character
@onready var character: Character = self.get_parent()

var current_effects: Dictionary[EffectResource, EffectState]

# Tick down all effects.
func _physics_process(delta: float) -> void:
	for effect in current_effects.keys():
		if current_effects[effect].update_tick(delta):
			character.remove_effect(effect)

## Adds an effect of given effect state, or stacks with a matching effect. For host, stacks, for clients, rewrites.
func add_effect(effect: EffectState) -> void:
	var effects_combined: bool = false
	# If host attempt to combine before just adding.
	if character.network_manager.is_host():
		for effect_resource in current_effects.keys():
			if effect_resource == effect.effect_resource:
				current_effects[effect_resource].combine_effect(effect)
				effects_combined = true
	
	if not effects_combined:
		current_effects[effect.effect_resource] = effect
	
	if character.network_manager.is_host():
		character.network_manager.send_p2p_packet(0, {"m": character.network_manager.Message.CHARACTER_ADD_EFFECT, "char_id": character.registry_id, "effect_state": current_effects[effect.effect_resource].to_dict()})

## Removes the effect with the given resource.
func remove_effect(effect: EffectResource) -> void:
	for effect_resource in current_effects.keys():
		if effect_resource == effect:
			current_effects.erase(effect_resource)
			break
	if character.network_manager.is_host():
		character.network_manager.send_p2p_packet(0, {"m": character.network_manager.Message.CHARACTER_REMOVE_EFFECT, "char_id": character.registry_id, "effect_name": effect.resource_path.get_file().get_basename()})

func has_effect(effect: EffectResource) -> bool:
	return current_effects.has(effect)
