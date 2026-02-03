extends Resource
class_name PlayerState

## The current amount of points this player has after spending.
@export var current_score := 0
## The total amount of points this player has achieved.
@export var total_score := 0
## The current team of the character. Normally, -1 Spectator, 0 Home, 1 Away
@export var team: int = -1

func from_dict(data: Dictionary) -> void:
	current_score = data["current"]
	total_score = data["total"]
	team = data["team"]

func to_dict() -> Dictionary:
	var data: Dictionary = {}
	data["current"] = current_score
	data["total"] = total_score
	data["team"] = team
	
	return data
