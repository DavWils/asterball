extends Resource

class_name LevelResource

## The name of the level.
@export var level_name: String
## Thumbnail for this level.
@export var thumbnail: Texture2D
## The homefield team of this level.
@export var home_team: TeamResource

## Returns text name of the level.
func get_level_filename() -> String:
	return self.resource_path.get_file().get_basename()

## Returns the scene file of the level.
func get_level_scene() -> PackedScene:
	return load("res://scenes/main/levels/" + get_level_filename() + ".tscn")
