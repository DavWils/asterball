extends Resource
class_name PlayerState

## The current amount of points this player has after spending.
@export var current_score := 0
## The total amount of points this player has achieved.
@export var total_score := 0
## The current team of the character. Normally, -1 Spectator, 0 Home, 1 Away
@export var team_id: int = -1
## Signal emitted when scores change
signal scores_changed(new_current: int, new_total: int)

func from_dict(data: Dictionary) -> void:
	current_score = data["current"]
	total_score = data["total"]
	team_id = data["team_id"]

func to_dict() -> Dictionary:
	var data: Dictionary = {}
	data["current"] = current_score
	data["total"] = total_score
	data["team_id"] = team_id
	
	return data

## Sets total and current score of the player.
func set_score(current: int, total: int) -> void:
	current_score = current
	total_score = total
	scores_changed.emit(current, total)

## Returns true if player can afford a cost.
func can_afford(cost: int) -> bool:
	return current_score >= cost
