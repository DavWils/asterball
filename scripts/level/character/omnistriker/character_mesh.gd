## Script for the character mesh of this character.

extends Node3D

## Reference to the character.
@onready var character: Character = self.get_parent()
## Reference to the actual mesh root node.
@onready var mesh_root: Node3D = self.get_child(0)
## And animation tree
@onready var animation_tree: AnimationTree = get_node("AnimationTree")
## And animatio player
@onready var animation_player: AnimationPlayer = get_node("AnimationPlayer")
## Skeleton
@onready var skeleton: Skeleton3D = get_node("Armature").get_node("Skeleton3D")
## Node to attach equipment to.
@export var equipment_attachment: Node3D

func _ready() -> void:
	if not character.is_node_ready(): await character.ready
	var mesh_mat: ShaderMaterial = $Armature/Skeleton3D/omnistriker.mesh.surface_get_material(0)
	mesh_mat.set_shader_parameter("primary_color", character.get_player_team_state().team_resource.primary_color)
	mesh_mat.set_shader_parameter("secondary_color", character.get_player_team_state().team_resource.secondary_color)
	(character.ragdoll.get_node("Armature/Skeleton3D/omnistriker").mesh as ArrayMesh).surface_set_material(0, mesh_mat)
	character.equipped.connect(_on_equipped)
	
func _physics_process(_delta: float) -> void:
	if is_node_ready() and animation_player:
		update_animation()

func update_animation():
	if character.is_tackled(): 
		animation_tree.set("parameters/MovementTransition/transition_request", "Idle")
		return
	if not character.is_on_floor():
		animation_tree.set("parameters/MovementTransition/transition_request", "Fall")
	else:
		var horizontal_velocity: Vector3 = character.velocity * (Vector3(1,0,1))
		if horizontal_velocity.length() < 0.1:
			animation_tree.set("parameters/MovementTransition/transition_request", "Idle")
		else:
			if character.is_charging():
				animation_tree.set("parameters/MovementTransition/transition_request", "Charge")
				# Set speed scale. When running faster, animation plays faster.
				var speed_scale: float
				if horizontal_velocity.length() > character.walk_speed:
					speed_scale = horizontal_velocity.length()/character.walk_speed
				else:
					speed_scale = 1.0
				animation_tree.set("parameters/RunTimeScale/scale", speed_scale)
			else:
				# Running, calculate direction and run.
				var local_velocity = character.transform.basis.inverse() * horizontal_velocity
				var dir = Vector2(local_velocity.x, -local_velocity.z)
				dir = dir.normalized()
				var current_dir: Vector2 = animation_tree.get("parameters/RunBlendSpace2D/blend_position")
				animation_tree.set("parameters/RunBlendSpace2D/blend_position", current_dir.lerp(dir, 0.9))
				animation_tree.set("parameters/MovementTransition/transition_request", "Run")
		
	# Now we do aiming animation
	if character.is_aiming() or animation_tree.get("parameters/ThrowOneShot/active"):
		if character.is_aiming():
			var current_blend: float = animation_tree.get("parameters/ThrowAimBlend/blend_amount")
			var new_blend = lerpf(current_blend, 1.0, .1)
			animation_tree.set("parameters/ThrowAimBlend/blend_amount", new_blend)
		# Rotate spine based on control pitch.
		skeleton.clear_bones_global_pose_override()
		var spine_idx: int = skeleton.find_bone("spine.001")
		var spine_pose: Transform3D = skeleton.get_bone_global_pose(spine_idx)
		var spine_basis: Basis = spine_pose.basis
		var spine_euler: Vector3 = spine_basis.get_euler()
		
		var added_pitch = clampf(character.control_pitch, -PI/2, PI/2)
		spine_euler.x -= added_pitch
		
		spine_euler.y = -PI
		
		
		spine_basis = Basis.from_euler(spine_euler)
		spine_pose.basis = spine_basis
		
		
		skeleton.set_bone_global_pose_override(spine_idx, spine_pose, 1.0, true)
	else:
		skeleton.clear_bones_global_pose_override()
		var current_blend: float = animation_tree.get("parameters/ThrowAimBlend/blend_amount")
		if current_blend >= 0.88 and not character.current_equipment:
			animation_tree.set("parameters/ThrowAimBlend/blend_amount", 0.0)
			animation_tree.set("parameters/ThrowOneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		else:
			animation_tree.set("parameters/ThrowAimBlend/blend_amount", lerpf(current_blend, 0.0, .1))

func _on_equipped() -> void:
	if not animation_tree.get("parameters/ThrowAimBlend/blend_amount"):
		animation_tree.set("parameters/EquipOneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		$EquipSoundPlayer.play_equip_sound()
