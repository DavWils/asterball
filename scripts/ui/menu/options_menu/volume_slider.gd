extends Node

var idx: int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Label.text = AudioServer.get_bus_name(idx) + " Volume"
	$HSlider.value = AudioServer.get_bus_volume_linear(idx)

func get_linear_vol() -> float:
	return $HSlider.value
