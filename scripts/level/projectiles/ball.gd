extends Projectile

func _ready() -> void:
	super._ready()
	var allegiance_team = get_allegiance_team()
	var mesh_material := projectile_mesh.get_child(0).get_active_material(0) as ShaderMaterial
	if allegiance_team:
		var color = get_allegiance_team().team_resource.primary_color
		$TeamLight.light_color = color
		mesh_material.set_shader_parameter("emission_color", color)
	else:
		mesh_material.set_shader_parameter("emission_color", Color())
		$TeamLight.queue_free()
