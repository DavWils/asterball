## Code for menu button, mainly for the dynamic color.


extends Button

@onready var audio_player: AudioStreamPlayer = get_tree().current_scene.get_node("UIAudioPlayer")
@onready var hover_style := get_theme_stylebox("hover")
@onready var pressed_style := get_theme_stylebox("pressed")

## Whether or not to use the alternative button press sound.
@export var alt_press: bool
## Whether or not to use a double sided fade instead of only right.
@export var double_fade: bool = false

## Color of the button before hover.
const INIT_COLOR: Color = Color.WHITE
## Color of the button while hovered.
const HOVER_COLOR: Color = Color.PURPLE

## The base color for the button.
var base_color: Color = INIT_COLOR

## Is pressed.
var is_pressed_visually: bool = false

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	pressed.connect(_on_pressed)

func _process(_delta: float) -> void:
	if is_hovered() and not is_pressed_visually:
		var new_color := base_color + (base_color * 0.1 * sin(Time.get_ticks_msec()/600.0))
		for i in range(0,4):
			var step_color := new_color
			if i==3 or (i==0 and double_fade): step_color *= Color(1,1,1,0)
			(hover_style.texture.gradient as Gradient).set_color(i, step_color)
	

func _on_mouse_entered() -> void:
	audio_player.play_hover()
	create_tween().tween_property(
		self,
		"base_color",
		HOVER_COLOR,
		0.2
	)


func _on_mouse_exited() -> void:
	create_tween().tween_property(
		self,
		"base_color",
		INIT_COLOR,
		0.2
	)

func _on_pressed() -> void:
	is_pressed_visually = true
	var new_color := Color.WHITE
	for i in range(0,4):
		var step_color := new_color
		if i==3 or (i==0 and double_fade): step_color *= Color(1,1,1,0)
		(hover_style.texture.gradient as Gradient).set_color(i, step_color)

	if alt_press:
		audio_player.play_pressed_alt()
	else:
		audio_player.play_pressed()
	await get_tree().create_timer(.05).timeout
	is_pressed_visually = false
