extends MultiMeshInstance3D

## Owning character.
@onready var character: Character = self.get_parent()
## Whether or not character is throwing.
@onready var is_throwing: bool = false
## The mass of the current projectile being thrown.
@onready var projectile_mass: float
## Reference to the level.
@onready var level: Level = get_tree().current_scene.get_node("Level")

## The time interval in which we place meshes.
const TIME_INTERVAL: float = 0.05

func _ready() -> void:
	position = character.get_throw_start()
	character.throw_start.connect(_on_throw_start)
	character.aim_end.connect(_on_aim_end)
	
	# Create the multimesh
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = 100
	
	# Mesh
	var mm_mesh := SphereMesh.new()
	mm_mesh.radius = 0.1
	mm_mesh.height = 0.2
	mm.mesh = mm_mesh
	
	# Material
	var mesh_material = StandardMaterial3D.new()
	mesh_material.vertex_color_use_as_albedo = true
	mesh_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mm.mesh.material = mesh_material
	
	multimesh = mm


func _process(_delta: float) -> void:
	if character.is_locally_possessed() and is_throwing:
		var count := multimesh.instance_count
		var fade_start := int(count * 1.0)
		var initial_pos: Vector3 = character.get_throw_start()
		var initial_vel: Vector3 = character.get_throw_velocity()
		for i in range(count):
			var mesh_transform: Transform3D
			var cur_time: float = TIME_INTERVAL * i
			var acceleration: Vector3 = Vector3.DOWN * level.gravity_acceleration
			var final_pos: Vector3 = initial_pos + (initial_vel * cur_time) + (0.5*acceleration*cur_time*cur_time) 
			mesh_transform.origin = to_local(final_pos)
			
			# Scale based on distance.
			var alpha := 1.0
			if i >= fade_start:
				var fade_index := i - fade_start
				var fade_count := count - fade_start
				alpha = 1.0 - float(fade_index + 1) / float(fade_count)
			mesh_transform = mesh_transform.scaled(Vector3.ONE * alpha)
			multimesh.set_instance_transform(i, mesh_transform)

func _on_throw_start() -> void:
	if not character.is_locally_possessed(): return
	print("Showing trajectory for ", character.owning_player_id, ": ", character.is_locally_possessed())
	projectile_mass = character.get_equipped_item().get_item_mass()
	self.multimesh.visible_instance_count = -1
	is_throwing = true
	print("Trajectory start")
	
func _on_aim_end() -> void:
	if not character.is_locally_possessed(): return
	self.multimesh.visible_instance_count = 0
	is_throwing = false
