## Code for menu button, mainly for the dynamic color.

extends Button

@onready var hover_style := get_theme_stylebox("hover")

## Color of the button before hover.
const INIT_COLOR: Color = Color.WHITE
## Color of the button while hovered.
const HOVER_COLOR: Color = Color.PURPLE

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

## The base color for the button.
var base_color: Color = INIT_COLOR

func _process(_delta: float) -> void:
	hover_style.bg_color = base_color + (base_color * 0.1 * sin(Time.get_ticks_msec()/600.0))

func _on_mouse_entered() -> void:
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
