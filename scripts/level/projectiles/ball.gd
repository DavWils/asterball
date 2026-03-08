extends Projectile

func _ready() -> void:
	super._ready()
	var allegiance_team = get_allegiance_team()
	if allegiance_team:
		var color = get_allegiance_team().team_resource.primary_color
		$TeamLight.light_color = color
	else:
		pass
		$TeamLight.queue_free()
