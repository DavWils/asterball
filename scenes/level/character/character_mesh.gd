## Script for the character mesh of this character.

extends Node3D

## Reference to the character.
@onready var character: Character = self.get_parent()
## Reference to the actual mesh root node.
@onready var mesh_root: Node3D = self.get_child(0)
## And animation tree
@onready var animation_tree: AnimationTree = mesh_root.get_node("AnimationTree")
## And animatio player
@onready var animation_player: AnimationPlayer = mesh_root.get_node("AnimationPlayer")

func _physics_process(_delta: float) -> void:
	update_animation()

	if animation_player:
		update_animation()

func update_animation():
	if character.is_tackled: return
	
	if not character.is_on_floor():
		animation_tree.set("parameters/MovementTransition/transition_request", "Fall")
	else:
		var horizontal_velocity: Vector3 = character.velocity * (Vector3(1,0,1))
		if horizontal_velocity.length() < 0.1:
			animation_tree.set("parameters/MovementTransition/transition_request", "Idle")
		else:
			# Running, calculate direction and run.
			var local_velocity = transform.basis.inverse() * horizontal_velocity
			var dir = Vector2(local_velocity.x, -local_velocity.z)
			dir = dir.normalized()
			var current_dir: Vector2 = animation_tree.get("parameters/RunBlendSpace2D/blend_position")
			animation_tree.set("parameters/RunBlendSpace2D/blend_position", current_dir.lerp(dir, 0.25))
			animation_tree.set("parameters/MovementTransition/transition_request", "Run")
			
			# Set speed scale. When running faster, animation plays faster.
			var speed_scale: float
			if horizontal_velocity.length() > character.walk_speed:
				speed_scale = horizontal_velocity.length()/character.walk_speed
			else:
				speed_scale = 1.0
			animation_tree.set("parameters/RunTimeScale/scale", speed_scale)
		
		# Rotate spine based on control pitch.
		var skeleton: Skeleton3D = mesh_root.get_node("Armature").get_node("Skeleton3D")
		skeleton.clear_bones_global_pose_override()
		var spine_idx: int = skeleton.find_bone("spine")
		var spine_pose: Transform3D = skeleton.get_bone_global_pose(spine_idx)
		var spine_basis: Basis = spine_pose.basis
		var spine_euler: Vector3 = spine_basis.get_euler()
		
		var current_velocity = absf(character.velocity.length() - character.walk_speed) if character.velocity.length()>0.1 else 0.0
		var added_pitch = clampf(character.control_pitch - clampf(current_velocity/10, 0, 0.8), -PI/2, PI/2)
		
		spine_euler.x += added_pitch
		spine_basis = Basis.from_euler(spine_euler)
		spine_pose.basis = spine_basis
		
		skeleton.set_bone_global_pose_override(spine_idx, spine_pose, 1.0, true)
