extends Resource
class_name TeamState

## This team's score.
@export var score: int = 0
## The resource of this team.
@export var team_resource: TeamResource

## Build team state from dictionary.
func from_dict(data: Dictionary) -> void:
	score = data["score"]
	team_resource = load(data["trpath"])

## Convert the team state to a dictionary.
func to_dict() -> Dictionary:
	var data: Dictionary = {}
	data["score"] = score
	data["trpath"] = team_resource.resource_path
	return data

func set_score(new_score: int):
	score = new_score
