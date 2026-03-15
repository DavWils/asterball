extends AudioStreamPlayer

## Sound to play when hovering over button.
@export var hover_sound: AudioStream
## Sound to play when button is pressed.
@export var pressed_sound: AudioStream
## Alternative button pressing sound, such as when leaving opened menu.
@export var pressed_sound_alt: AudioStream
## Button sound when purchasing an item.
@export var purchased_sound: AudioStream
## Button sound when failing to purchase an item.
@export var fail_purchased_sound: AudioStream


func play_hover():
	stream = hover_sound
	play()

func play_pressed():
	stream = pressed_sound
	play()

func play_pressed_alt():
	stream = pressed_sound_alt
	play()

func play_purchased():
	stream = purchased_sound
	play()

func play_fail_purchased():
	stream = fail_purchased_sound
	play()
