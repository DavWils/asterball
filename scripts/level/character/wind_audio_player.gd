extends AudioStreamPlayer

@onready var character: Character = self.get_parent()

func _ready() -> void:
	character.possessed.connect(_on_possessed)
	character.unpossessed.connect(_on_unpossessed)

func _process(_delta: float) -> void:
	if playing:
		var current_velocity: float = character.velocity.length()
		var speed_ratio = max(current_velocity-8.0, 0.0) / 30.0
		var new_volume = pow(speed_ratio, 2.2)
		volume_db = lerp(volume_db, linear_to_db(clampf(new_volume * .2, 0.01, 1.0)), 0.4)
		pitch_scale = clampf(pitch_scale + (current_velocity if randi()%2 else -current_velocity)*0.001, 0.9, 1.3)

func _on_possessed() -> void:
	play()
	print("Wind Audio Playing")

func _on_unpossessed() -> void:
	stop()
	print("Wind Audio Stopped")
