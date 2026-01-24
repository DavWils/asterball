extends Node

class_name Character

## The non charging speed of this character. (m/s)
@export var walk_speed := 6.0
## The maximum base charging speed of the character, not including any buffs.
@export var base_charge_speed := 24.0

## The id of the player currently controlling this character. Or -1 if it's AI controlled.
var owning_player := -1
