extends Area3D

@onready var character: Character = self.get_parent()

## Returns the most wanted interactable in the area.
func get_desired_interactable() -> Node3D:
	var bodies: Array[Node3D] = get_overlapping_bodies()
	## The desired interactable.
	var desired: Node3D = null
	for body in bodies:
		if body.is_queued_for_deletion():
			continue
		if body.has_method("interact"):
			if desired:
				# Find out if this item is more desired. For now just do distance, but later check if the player is looking more in its direction.
				if character.position.distance_to(desired.position) > character.position.distance_to(body.position):
					desired = body
			else:
				desired = body
	
	return desired
