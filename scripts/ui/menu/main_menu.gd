extends Control

@onready var tab_container: TabContainer = $TabContainer

## Transitions to title screen.
func to_title_screen() -> void:
	tab_container.current_tab = 0

## Transitions to options menu.
func to_options() -> void:
	tab_container.current_tab = 1

## Transitions to credits.
func to_credits() -> void:
	tab_container.current_tab = 2
