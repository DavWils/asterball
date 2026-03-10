## A script for a light that sets its light energy based on a pulse, as well as affecting the item's shader emission.

extends Light3D

var shader_mat: ShaderMaterial

## The peak light energy.
@export var peak_light_energy: float = 1.0

func _ready() -> void:
	var item_scene = self.get_parent()
	if not item_scene.is_node_ready(): await item_scene.ready
	print("ready now")
	var mesh_node: Node3D
	if item_scene is Equipment:
		mesh_node = item_scene.equipment_mesh
	elif item_scene is Projectile:
		mesh_node = item_scene.projectile_mesh
	
	shader_mat = mesh_node.get_child(0).get_active_material(0)
	
func _process(_delta: float) -> void:
	var cur_time := Time.get_ticks_usec()
	var new_strength: float = 0.5*(sin(0.000005 * cur_time)+1.0)
	shader_mat.set_shader_parameter("emission_strength", new_strength)
	light_energy = peak_light_energy * new_strength
