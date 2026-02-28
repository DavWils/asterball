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
	

func _process(_delta: float) -> void:
	if character.is_locally_possessed() and is_throwing:
		for i in self.multimesh.instance_count:
			var mesh_transform: Transform3D
			var initial_pos: Vector3 = character.get_throw_start()
			var initial_vel: Vector3 = character.get_throw_velocity()
			var cur_time: float = TIME_INTERVAL * i
			var acceleration: Vector3 = Vector3.DOWN * level.gravity_acceleration
			var final_pos: Vector3 = initial_pos + (initial_vel * cur_time) + (0.5*acceleration*cur_time*cur_time) 
			mesh_transform.origin = to_local(final_pos)
			multimesh.set_instance_transform(i, mesh_transform)

func _on_throw_start() -> void:
	if not character.is_locally_possessed(): return
	projectile_mass = character.get_equipped_item().get_item_mass()
	self.multimesh.visible_instance_count = -1
	is_throwing = true
	
func _on_aim_end() -> void:
	if not character.is_locally_possessed(): return
	self.multimesh.visible_instance_count = 0
	is_throwing = false
	
