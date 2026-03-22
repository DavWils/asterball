## Script for the ball as an equipment item.

extends Equipment

var shift_effect: EffectResource = load("res://resources/effects/heart_shifted.tres")

func use_start() -> void:
	super.use_start()
	var shift_count: int
	if wielder.effects_component.current_effects.has(shift_effect):
		shift_count = wielder.effects_component.current_effects[shift_effect].effect_stacks
	else:
		shift_count = 0
	print("New shift: ", shift_count)
	var new_pitch = 1.0 + (0.08 * float(shift_count))
	$AudioStreamPlayer3D.pitch_scale = new_pitch
	$AudioStreamPlayer3D.stop()
	$AudioStreamPlayer3D.play()
	
	$AnimationPlayer.stop()
	for particle in [$DebrisParticle, $FlashParticle]:
		(particle as GPUParticles3D).restart()
	$AnimationPlayer.play("shift")
	
	if network_manager.is_host():
		wielder.add_effect(EffectState.new(shift_effect, 300))
