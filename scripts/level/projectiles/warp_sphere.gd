extends Projectile

func character_overlap(character: Character):
	super.character_overlap(character)
	# Hit another character, swap places.
	if throwing_character:
		if network_manager.is_host() or thrower_id == network_manager.player_id:
			teleport_character(character, throwing_character.position)
			teleport_character(throwing_character, self.position)
			if network_manager.is_host():
				despawn_projectile()


func surface_collide(body: Node3D) -> void:
	super.surface_collide(body)
	# Hit a surface, teleport character to surface.
	if throwing_character:
		if network_manager.is_host() or thrower_id == network_manager.player_id:
			teleport_character(throwing_character, self.global_position)
			if network_manager.is_host():
				despawn_projectile()



func teleport_character(character: Character, location: Vector3):
	character.position = location
