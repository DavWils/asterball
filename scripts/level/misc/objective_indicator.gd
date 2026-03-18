extends Node3D

@onready var level: Level = get_tree().current_scene.get_node("Level")
@onready var match_state: MatchState = get_tree().current_scene.get_node("Level").get_node("MatchState")
@onready var player_controller: PlayerController = get_tree().current_scene.get_node("Level").get_node("PlayerController")

@onready var ball_resource := load("res://resources/items/ball.tres")

var current_target_type: TargetType

enum TargetType {
	BALL,
	GOAL
}

## The alpha and radius of each target type.
const INDICATOR_PARAMS: Dictionary[int, Vector2] = {
	TargetType.BALL: Vector2(5.0, 10.0),
	TargetType.GOAL: Vector2(5.0, 50.0)
}

func _ready() -> void:
	set_target_type()
	match_state.player_team_assigned.connect(_on_player_team_assigned)
	player_controller.possessed.connect(_on_possessed)
	player_controller.unpossessed.connect(_on_unpossessed)

func _process(delta: float) -> void:
	self.position = position.lerp(get_target_pos(), delta * 8.0)


func _on_player_team_assigned(player_id: int, team_id: int) -> void:
	if player_id == player_controller.network_manager.player_id:
		# Set appropriate colors.
		var team_color: Color = match_state.get_team_state(team_id).team_resource.primary_color
		($MeshInstance3D.mesh.material as ShaderMaterial).set_shader_parameter("base_color", team_color * Color(1,1,1,INDICATOR_PARAMS[current_target_type][0]))
		$SpotLight3D.light_color = team_color
		$GPUParticles3D.draw_pass_1.material.albedo_color = team_color
		$GPUParticles3D.draw_pass_1.material.emission = team_color

func _on_possessed(character: Character):
	character.equipped.connect(_on_equipped)

func _on_unpossessed(character: Character):
	character.equipped.disconnect(_on_equipped)
	set_target_type(TargetType.BALL)

func _on_equipped(_key: int) -> void:
	if player_controller.current_character.get_equipped_item() and player_controller.current_character.get_equipped_item().item_resource == ball_resource:
		set_target_type(TargetType.GOAL)
	else:
		set_target_type(TargetType.BALL)

func set_target_type(target_type: TargetType = current_target_type):
	var _old_target_type = current_target_type
	current_target_type = target_type
	var cone_mesh: CylinderMesh = $MeshInstance3D.mesh
	var radius = INDICATOR_PARAMS[current_target_type][1]
	#cone_mesh.bottom_radius = radius
	var cone_tween := create_tween()
	cone_tween.tween_property($SpotLight3D, "spot_angle", rad_to_deg(atan2(radius, cone_mesh.height)), 0.15)
	cone_tween.parallel().tween_property(cone_mesh, "bottom_radius", radius, 0.15)
	#$SpotLight3D.spot_angle = rad_to_deg(atan2(cone_mesh.bottom_radius, cone_mesh.height))
	$GPUParticles3D.process_material.emission_sphere_radius = radius
	$GPUParticles3D.position = Vector3.UP * radius

func get_target_pos() -> Vector3:
	if current_target_type == TargetType.BALL:
		for child in level.get_children():
			if child is Character:
				if child.current_equipment and child.current_equipment.item_resource == ball_resource: return child.global_position * Vector3(1,0,1)
			elif child is Projectile:
				if child.item_state.item_resource == ball_resource: return child.global_position * Vector3(1,0,1)
	else:
		for child in level.get_children():
			if child is ScoreZone:
				if child.owning_team != player_controller.get_player_state().team_id: return child.global_position * Vector3(1,0,1)
	return Vector3.ZERO
