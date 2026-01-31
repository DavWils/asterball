extends Resource
class_name PlayerState

## The current amount of points this player has after spending.
@export var current_score := 0
## The total amount of points this player has achieved.
@export var total_score := 0
## The current team of the character. Normally, 1 - Home, 2 - Away, 0 - Spectator
@export var team: int = 0
