## Code for menu button, mainly for the dynamic color.


extends Button

@onready var audio_player: AudioStreamPlayer = get_tree().current_scene.get_node("UIAudioPlayer")
@onready var hover_style := get_theme_stylebox("hover")

## Whether or not to use the alternative button press sound.
@export var alt_press: bool

## Color of the button before hover.
const INIT_COLOR: Color = Color.WHITE
## Color of the button while hovered.
const HOVER_COLOR: Color = Color.PURPLE

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	pressed.connect(_on_pressed)
	
	# Make style unique.
	#hover_style = hover_style.duplicate()
	#add_theme_stylebox_override("hover", hover_style)

## The base color for the button.
var base_color: Color = INIT_COLOR

func _process(_delta: float) -> void:
	hover_style.bg_color = base_color + (base_color * 0.1 * sin(Time.get_ticks_msec()/600.0))

func _on_mouse_entered() -> void:
	audio_player.play_hover()
	create_tween().tween_property(
		self,
		"base_color",
		HOVER_COLOR,
		0.2
	)


func _on_mouse_exited() -> void:
	pass
	create_tween().tween_property(
		self,
		"base_color",
		INIT_COLOR,
		0.2
	)

func _on_pressed() -> void:
	if alt_press:
		audio_player.play_pressed_alt()
	else:
		audio_player.play_pressed()
