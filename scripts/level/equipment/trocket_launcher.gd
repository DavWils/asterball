extends EquipmentLauncher

func _ready() -> void:
	super._ready()
	$Timer.timeout.connect(_on_timeout)

func _on_timeout() -> void:
	$ReadyAudioPlayer.play()
	$ReadyParticles.restart()

func use_start() -> void:
	super.use_start()
	$Timer.start()

func use_finish() -> void:
	super.use_finish()
	if $Timer.is_stopped():
		fire_projectile()
	else:
		$Timer.stop()
