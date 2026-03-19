extends Control

## Whether or not to make this represent the winning team.
@export var winning_team: bool = false

func _ready():
	# If winning team representation, increase font size.
	if winning_team:
		for child in $MarginContainer/HBoxContainer.get_children():
			if child is Label:
				child.add_theme_font_size_override("font_size", child.get_theme_font_size("font_size") * 2)

func set_team_info(placement: int, team_state: TeamState) -> void:
	$MarginContainer/HBoxContainer/WinningTeamPlacement.text = str(placement)+get_ordinal(placement)
	$MarginContainer/HBoxContainer/WinningTeamName.text = str(team_state.team_resource.team_name)
	$MarginContainer/HBoxContainer/WinningTeamScore.text = str(team_state.score)

func get_ordinal(placement: int) -> String:
	if placement % 100 >= 11 and placement % 100 <= 13:
		return "th"
	
	match placement % 10:
		1:
			return "st"
		2:
			return "nd"
		3:
			return "rd"
		_:
			return "th"
