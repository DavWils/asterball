@tool

## Node for preloading all frequently spawned scenes.

extends Node

class_name AssetLoader

## Whether or not asset loading is complete.
var assets_loaded: bool = true

## Called when all assets are loaded
signal load_complete
## Called when an asset has started loading.
signal asset_started(asset_name: String)

var assets: Dictionary[String, PackedScene]

const directories: Dictionary[String, String] = {
	"character": "res://scenes/level/characters/",
	"equipment": "res://scenes/level/character/equipment/",
	"projectiles": "res://scenes/level/projectiles/",
	"explosions": "res://scenes/level/misc/explosions/",
}

## Files to be loaded.
@export var files: Array[String]

func _ready() -> void:
	if Engine.is_editor_hint():
		files.clear()
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
						files.append(dir_string + "/" + current_filename)
						print("Appended ", dir_string + "/" + current_filename)
				current_filename = cur_dir.get_next()
	else:
		get_parent().get_node("InitialLoadUI").get_node("AssetLabel").text = "Awaiting " + str(files.size()) + " files."

func load_assets() -> void:
	assets_loaded = false
	assets.clear()
	
	for file in files:
		asset_started.emit(file)
		var cur_scene := load(file)
		assets[file.get_basename()] = cur_scene
		
	assets_loaded = true
	load_complete.emit()
