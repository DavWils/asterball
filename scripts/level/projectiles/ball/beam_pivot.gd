## Script that controls the beam's rotation/length based on ball velocity, as well as the color.

extends Node3D

@onready var ball: Projectile = self.get_parent()

@onready var beam_mesh: MeshInstance3D = $Beam

func _ready() -> void:
	if not ball.is_node_ready(): await ball.ready
	var beam_mat := beam_mesh.get_active_material(0) as ShaderMaterial
	var smoke_mat: StandardMaterial3D = $SmokeParticles.draw_pass_1.material
	var allegiance_team := ball.get_allegiance_team()
	if allegiance_team:
		beam_mat.set_shader_parameter("emission", ball.get_allegiance_team().team_resource.primary_color)
		smoke_mat.albedo_color = ball.get_allegiance_team().team_resource.primary_color
		smoke_mat.emission = ball.get_allegiance_team().team_resource.primary_color
	else:
		beam_mat.set_shader_parameter("emission", Color())
		beam_mat.set_shader_parameter("emission_energy", 0.0)
		smoke_mat.albedo_color = Color()
		smoke_mat.emission_enabled = false

func _process(delta: float) -> void:
	position = ball.position
	# Set rotation of the beam.
	var ball_velocity: Vector3 = ball.linear_velocity
	#print(ball_velocity.length())

	var current_dir: Vector3 = -transform.basis.z.normalized()
	var vel_dir: Vector3 = ball_velocity.normalized()

	if current_dir.cross(vel_dir).length() >= 0.0001:
		global_transform.basis = global_transform.basis.slerp(transform.looking_at(transform.origin + vel_dir, Vector3.FORWARD if abs(vel_dir.dot(Vector3.UP)) > 0.99 else Vector3.UP).basis, delta * 5.0)

	# Set the length of the beam.
	var new_beam_length = ball_velocity.length()/3.0
	var cur_beam_length = beam_mesh.mesh.height
	var beam_length: float = lerp(cur_beam_length, new_beam_length, delta*5.0)
	var half_length: float = beam_length/2.0
	beam_mesh.mesh.height = beam_length
	beam_mesh.position = Vector3(0,0,half_length)
	var beam_mat := beam_mesh.get_active_material(0) as ShaderMaterial
	beam_mat.set_shader_parameter("cylinder_half_height", half_length)
	beam_mat.set_shader_parameter("alpha_threshold", 1-clampf(ball_velocity.length(), 0.0, 1.0))
	
