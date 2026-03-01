extends Projectile

func projectile_collide(body: Node3D):
	super.projectile_collide(body)
	if throwing_character:
		if network_manager.is_host() or thrower_id == network_manager.player_id:
			throwing_character.position = self.position
			if network_manager.is_host():
				despawn_projectile()
