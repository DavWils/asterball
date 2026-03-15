## Script for the credits screen in main menu

extends Control

const CREDITS_FILE_PATH: String = "res://credits.txt"

@onready var main_menu: Control = get_parent().get_parent()
@onready var text_label: RichTextLabel = $Label
@onready var return_button: Button = $VBoxContainer/ReturnButton

func _ready():
	# Load credits text to label.
	if not FileAccess.file_exists(CREDITS_FILE_PATH):
		text_label.text = "credits.txt not found."
	else:
		var file: FileAccess = FileAccess.open(CREDITS_FILE_PATH, FileAccess.READ)
		text_label.text = file.get_as_text()
	
	# Connect button signal to return to title screen.
	return_button.pressed.connect(_on_return_button_pressed)

func _on_return_button_pressed() -> void:
	main_menu.to_title_screen()
