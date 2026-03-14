## Effects component of the character, controlling status effects.

extends Node

class_name EffectsComponent

## Character
@onready var character: Character = self.get_parent()

var current_effects: Dictionary[EffectResource, EffectState]

# Tick down all effects.
func _physics_process(delta: float) -> void:
	if not character.is_locally_possessed(): return
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

## Given a value and modifier type, returns that value based on modifiers from current effects.
func calculate_post_effects_value(base_value: float, modifier_type: Modifier.ModifierType) -> float:
	var post_value := base_value
	var percentage_sum := 0.0
	for effect in current_effects:
		for modifier in effect.modifiers:
			if modifier.modifier_type == modifier_type:
				if modifier.is_percentage:
					percentage_sum += modifier.modifier_value
				else:
					post_value += modifier.modifier_value
	
	var final_value := post_value * (1.0 + percentage_sum)
	#print("Final Value for ", modifier_type, " is ", final_value, " with post of ", post_value, " and percentage of ", percentage_sum)
	return final_value
