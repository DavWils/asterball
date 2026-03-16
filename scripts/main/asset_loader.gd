## Node for preloading all frequently spawned scenes.

extends Node

class_name AssetLoader

signal assets_loaded

var assets: Dictionary[String, PackedScene]

const directories: Dictionary[String, String] = {
	"character": "res://scenes/level/characters/",
	"equipment": "res://scenes/level/character/equipment/",
	"projectiles": "res://scenes/level/projectiles/",
	"explosions": "res://scenes/level/misc/explosions/",
}

func load_assets() -> void:
	assets.clear()
	
	for dir in directories:
		var dir_string: String = directories[dir]
		var cur_dir = DirAccess.open(dir_string)
		if not cur_dir: 
			print("Could not find directory: ", dir_string)
			continue
		cur_dir.list_dir_begin()
		
		var current_filename := cur_dir.get_next()
		
		while current_filename != "":
			if not cur_dir.current_is_dir():
				if current_filename.ends_with(".tscn"):
					print("Loading ", dir, "/", current_filename)
					var scene_path: String = dir_string + current_filename
					var cur_scene := load(scene_path)
					assets[dir + "_" + current_filename.get_basename()]  = cur_scene
			current_filename = cur_dir.get_next()
	assets_loaded.emit()
