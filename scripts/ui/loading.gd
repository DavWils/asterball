extends Control

enum LoadState {
	CREATING_LOBBY,
	JOINING_LOBBY,
	LOADING_LEVEL,
	RETRIEVING_GAME_INFO
}

var load_text: String

var process_seconds: float = 0.0
var period_count: int = 1
## The time it takes to put another period on ellipses or clear it.
const ELLIPSES_TIME: float = 1.0

func _process(delta: float) -> void:
	# When visible, add elipses to the loading status text
	if visible:
		process_seconds += delta
		if process_seconds >= ELLIPSES_TIME:
			period_count = (period_count % 3) + 1
			process_seconds = 0.0
		$LoadStatusLabel.text = load_text + ".".repeat(period_count)

func set_loading_level(level: LevelResource) -> void:
	$LevelNameLabel.text = level.level_name

func set_load_state(state: int) -> void:
	process_seconds = 0.0
	period_count = 0
	match state:
		LoadState.CREATING_LOBBY:
			load_text = "Creating session."
		LoadState.JOINING_LOBBY:
			load_text = "Joining session"
		LoadState.LOADING_LEVEL:
			load_text = "Loading level"
		LoadState.RETRIEVING_GAME_INFO:
			load_text = "Retrieving Game Info"
