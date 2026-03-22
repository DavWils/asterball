## A heart shift component that checks the user's velocity, if it's too low, explode.

extends Node3D

var character: Character
@onready var shift_effect: EffectResource = load("res://resources/effects/heart_shifted.tres")
@onready var fuse_timer: Timer = $Timer
@onready var warning_timer: Timer = $Timer2


@export var explosion: PackedScene

var item_mesh: MeshInstance3D

const FUSE_TIME: float = 2.0

var color: Color = Color.BLACK

func _ready() -> void:
	fuse_timer.wait_time = FUSE_TIME
	var parent_scene := get_parent()
	if not parent_scene.is_node_ready(): await parent_scene.ready
	if parent_scene is Equipment:
		character = parent_scene.wielder
	elif parent_scene is ActivePanoplyAttachment:
		character = parent_scene.character
	
	fuse_timer.timeout.connect(_on_fuse_timeout)
	warning_timer.timeout.connect(_on_warning_timeout)
	
	for child in self.get_parent().get_children():
		if child.get_child_count() > 0 and child.get_child(0) is MeshInstance3D:
			item_mesh = child.get_child(0)
			break
	


func _process(delta: float) -> void:
	if character:
		var current_vel: float = character.velocity.length()
		#print("Trigger tracks: ", current_vel)
		if current_vel < get_minimum_velocity():
			color = color.lerp(Color.BLACK, delta*5.0)
		else:
			var velocity_factor = min(50.0, current_vel)/50.0
			color = Color(velocity_factor, velocity_factor, velocity_factor)
		
		if item_mesh:
			(item_mesh.get_active_material(0) as ShaderMaterial).set_shader_parameter("emission_color", color)


func _physics_process(_delta: float) -> void:
	if character:
		var current_vel: float = character.velocity.length()
		#print("Trigger tracks: ", current_vel)
		if current_vel < get_minimum_velocity():
			#print("DANGER")
			warning_timer.wait_time = (fuse_timer.time_left + 0.0001) * (1.0/8.0)
			if fuse_timer.is_stopped():
				fuse_timer.start()
				warning_timer.start()
		else:
			if not fuse_timer.is_stopped():
				fuse_timer.stop()
				warning_timer.stop()
		

## Returns the minimum velocity that the character must maintain in order to not explode.
func get_minimum_velocity() -> float:
	var stack_count: int
	if character.has_effect(shift_effect):
		stack_count = character.effects_component.current_effects[shift_effect].effect_stacks
	else:
		stack_count = 0
	
	return float(stack_count) * 5.0

func _on_fuse_timeout() -> void:
	if character.network_manager.is_host():
		var explosion_scene := explosion.instantiate()
		explosion_scene.position = character.position + character.velocity.normalized()
		explosion_scene.explosion_intensity *= float(character.effects_component.current_effects[shift_effect].effect_stacks)
		get_tree().current_scene.get_node("Level").add_child(explosion_scene)
		await get_tree().process_frame
		if not character.is_tackled():
			var inv_items := character.inventory_component.inventory_items
			for item in inv_items:
				if inv_items[item].item_resource == load("res://resources/items/heart_shift.tres"):
					character.drop_item(item)

func _on_warning_timeout() -> void:
	$WarningAudioPlayer.pitch_scale = 1.75 - (0.75*(fuse_timer.time_left / FUSE_TIME))
	$WarningAudioPlayer.play()
	$GPUParticles3D.restart()
	$AnimationPlayer.stop()
	$AnimationPlayer.play("warning")
	color = Color.RED
	
