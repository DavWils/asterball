## Script for host menu.

extends Control

@onready var main_menu: Control = get_parent().get_parent()
@onready var main_scene: MainScene = get_tree().current_scene

## The currently selected level.
var selected_level: LevelResource

@onready var default_session_name: String = Steam.getFriendPersonaName(get_tree().current_scene.get_node("NetworkManager").player_id)+"'s Asterball Server"

func _ready() -> void:
	$HostButtonsContainer/StartButton.pressed.connect(_on_start_pressed)
	$HostButtonsContainer/ReturnButton.pressed.connect(_on_return_pressed)
	# Load level grid.
	var all_levels = main_scene.get_all_levels()
	
	for level in all_levels:
		var level_button: Button = load("res://scenes/ui/main_menu/level_button.tscn").instantiate()
		level_button.level = level
		level_button.host_ui = self
		$ScrollContainer/GridContainer.add_child(level_button)
		$SessionNameTextEdit.text = default_session_name
	
	
	# Select level by default.
	select_level(all_levels[0])

func _input(event:InputEvent):
	if ($SessionNameTextEdit.has_focus()
	and event is InputEventMouseButton
	and not $SessionNameTextEdit.get_global_rect().has_point(event.position)):
		$SessionNameTextEdit.release_focus()
		if $SessionNameTextEdit.text == "":
			$SessionNameTextEdit.text = default_session_name

func select_level(level: LevelResource) -> void:
	selected_level = level
	$SelectionLabel.text = level.level_name

func _on_start_pressed() -> void:
	main_scene.host_game(selected_level.resource_path.get_basename().get_file())

func _on_return_pressed() -> void:
	main_menu.to_title_screen()
